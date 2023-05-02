unit NtUtils.Processes.Create.Clone;

{
  This module provides support for cloning (aka forking) the current process.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.ntdbg, Ntapi.ntseapi, NtUtils,
  NtUtils.Processes.Create;

{ Helper functions (parent) }

// Make as many handles inheritable as possible
function RtlxInheritAllHandles(
  out Reverter: IAutoReleasable
): TNtxStatus;

// Map a shared memory region to talk to the clone
function RtlxMapSharableMemory(
  Size: NativeUInt;
  out Memory: IMemory
): TNtxStatus;

{ Helper functions (clone) }

// Attach the clone to parent's console
function RtlxAttachToParentConsole: TNtxStatus;

{ Cloning }

// Clone the current process.
// The function returns STATUS_PROCESS_CLONED in the cloned process.
function RtlxCloneCurrentProcess(
  out Info: TProcessInfo;
  Flags: TRtlProcessCloneFlags = RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES;
  [opt, Access(TOKEN_ASSIGN_PRIMARY)] PrimaryToken: IHandle = nil;
  [opt, Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle = 0;
  [in, opt] ProcessSecurity: PSecurityDescriptor = nil;
  [in, opt] ThreadSecurity: PSecurityDescriptor = nil
): TNtxStatus;

// Clone the current process and execute an anonymous function inside of it.
// Consider calling RtlxInheritAllHandles beforhand if necessary.
function RtlxExecuteInClone(
  const Payload: TNtxOperation;
  const Timeout: Int64 = NT_INFINITE;
  [opt, Access(TOKEN_ASSIGN_PRIMARY)] hxToken: IHandle = nil;
  Flags: TRtlProcessCloneFlags = RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ConsoleApi, NtUtils.Threads,
  NtUtils.Objects, NtUtils.Objects.Snapshots, NtUtils.Synchronization,
  NtUtils.Sections, NtUtils.Processes, NtUtils.SysUtils, NtUtils.Jobs,
  NtUtils.Tokens.Impersonate, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxInheritAllHandles;
var
  Handles: TArray<TProcessHandleEntry>;
  i: Integer;
begin
  // Snapshot all our handles
  Result := NtxEnumerateHandlesProcess(NtCurrentProcess, Handles);

  if not Result.IsSuccess then
    Exit;

  // Mark them inheritable
  for i := 0 to High(Handles) do
    NtxSetFlagsHandle(Handles[i].HandleValue, True,
      BitTest(Handles[i].HandleAttributes and OBJ_PROTECT_CLOSE));

  Reverter := Auto.Delay(
    procedure
    var
      i: Integer;
    begin
      // Restore handle attributes
      for i := 0 to High(Handles) do
        NtxSetFlagsHandle(
          Handles[i].HandleValue,
          BitTest(Handles[i].HandleAttributes and OBJ_INHERIT),
          BitTest(Handles[i].HandleAttributes and OBJ_PROTECT_CLOSE)
        );
    end
  );
end;

function RtlxMapSharableMemory;
var
  hxSection: IHandle;
begin
  Result := NtxCreateSection(hxSection, Size);

  if Result.IsSuccess then
    Result := NtxMapViewOfSection(Memory, hxSection.Handle, NtxCurrentProcess);
end;

function RtlxAttachToParentConsole;
begin
  Result.Location := 'FreeConsole';
  Result.Win32Result := FreeConsole;

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'AttachConsole';
  Result.Win32Result := AttachConsole(ATTACH_PARENT_PROCESS);
end;

function RtlxCloneCurrentProcess;
var
  RtlProcessInfo: TRtlUserProcessInformation;
  ModifiedFlags: TRtlProcessCloneFlags;
begin
  Info := Default(TProcessInfo);
  ModifiedFlags := Flags;

  // Suspend the clone whenever swapping the primary token
  if Assigned(PrimaryToken) then
    ModifiedFlags := ModifiedFlags or RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED;

  Result.Location := 'RtlCloneUserProcess';

  if DebugPort <> 0 then
    Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_PROCESS_ASSIGN);

  Result.Status := RtlCloneUserProcess(ModifiedFlags, ProcessSecurity,
    ThreadSecurity, DebugPort, RtlProcessInfo);

  if Result.IsSuccess and (Result.Status <> STATUS_PROCESS_CLONED) then
  begin
    Info.ValidFields := [piProcessID, piThreadID, piProcessHandle,
      piThreadHandle, piImageInformation];
    Info.ClientId := RtlProcessInfo.ClientId;
    Info.hxProcess := Auto.CaptureHandle(RtlProcessInfo.Process);
    Info.hxThread := Auto.CaptureHandle(RtlProcessInfo.Thread);
    Info.ImageInformation := RtlProcessInfo.ImageInformation;

    if Assigned(PrimaryToken) then
    begin
      // Swap the primary token while the clone is suspended
      Result := NtxAssignPrimaryToken(Info.hxProcess.Handle, PrimaryToken);

      if not Result.IsSuccess then
      begin
        // Fail and cleanup
        NtxTerminateProcess(Info.hxProcess.Handle, STATUS_CANCELLED);
        Exit;
      end;

      // Resume when necessary
      if not BitTest(Flags and RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED) then
        NtxResumeThread(Info.hxThread.Handle);
    end;
  end;
end;

function RtlxpPrepateJobForClone(
  out hxJob: IHandle
): TNtxStatus;
var
  Info: TJobObjectExtendedLimitInformation;
begin
  Result := NtxCreateJob(hxJob);

  if not Result.IsSuccess then
    Exit;

  // Terminate the clone on unexpected errors
  Info := Default(TJobObjectExtendedLimitInformation);
  Info.BasicLimitInformation.LimitFlags :=
    JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION or
    JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE or
    JOB_OBJECT_LIMIT_BREAKAWAY_OK;

  Result := NtxJob.Set(hxJob.Handle, JobObjectExtendedLimitInformation, Info);
end;

const
  CLONE_MAX_STACK_TRACE_DEPTH = 254;
  CLONE_MAX_STRING_LENGTH = 1024;

type
  TCloneSharedData = record
    Status: NTSTATUS;
    StackTraceLength: Cardinal;
    Location: PWideChar;
    StackTrace: array [0 .. CLONE_MAX_STACK_TRACE_DEPTH - 1] of Pointer;
    LocationBuffer: array [0 .. CLONE_MAX_STRING_LENGTH - 1] of WideChar
  end;
  PCloneSharedData = ^TCloneSharedData;

function RtlxExecuteInClone;
var
  SharedMemory: IMemory<PCloneSharedData>;
  hxJob: IHandle;
  Info: TProcessInfo;
  Completed: Boolean;
begin
  Result := RtlxpPrepateJobForClone(hxJob);

  if not Result.IsSuccess then
    Exit;

  // Map shared memory for getting TNtxStatus back from the clone
  Result := RtlxMapSharableMemory(SizeOf(TCloneSharedData),
    IMemory(SharedMemory));

  if not Result.IsSuccess then
    Exit;

  SharedMemory.Data.Location := 'Clone';
  SharedMemory.Data.Status := STATUS_UNSUCCESSFUL;

  // Clone the process
  Result := RtlxCloneCurrentProcess(Info, Flags or
    RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED, hxToken);

  if not Result.IsSuccess then
    Exit;

  if Result.Status = STATUS_PROCESS_CLONED then
  try
    // Executing in the clone
    Completed := False;

    try
      // Run the payload and save the result
      Result := Payload();
      SharedMemory.Data.Status := Result.Status;

      // Constant strings appear at the same shared address
      if StringRefCount(Result.Location) <= 0 then
        SharedMemory.Data.Location := PWideChar(Result.Location)

      // Dynamic strings require marshling
      else if Length(Result.Location) < CLONE_MAX_STRING_LENGTH then
      begin
        MarshalString(Result.Location, @SharedMemory.Data.LocationBuffer);
        SharedMemory.Data.Location := @SharedMemory.Data.LocationBuffer[0];
      end;

      // Save the stack trace
      if CaptureStackTraces and (Length(Result.LastCall.StackTrace) > 0) and
        (Length(Result.LastCall.StackTrace) <= CLONE_MAX_STACK_TRACE_DEPTH) then
      begin
        Move(Result.LastCall.StackTrace[0], SharedMemory.Data.StackTrace,
          Length(Result.LastCall.StackTrace) * SizeOf(Pointer));
        SharedMemory.Data.StackTraceLength := Length(Result.LastCall.StackTrace);
      end;

      Completed := True;
    finally
      if not Completed then
      begin
        // Report unhandled exceptions
        SharedMemory.Data.Location := 'Clone';
        SharedMemory.Data.Status := STATUS_UNHANDLED_EXCEPTION;

        // Provide a stack trace of the exception when possible
        if CaptureStackTraces then
          SharedMemory.Data.StackTraceLength := RtlCaptureStackBackTrace(0,
            CLONE_MAX_STACK_TRACE_DEPTH, @SharedMemory.Data.StackTrace, nil);
      end;
    end;
  finally
    // Do not try to clean up
    NtxTerminateProcess(NtCurrentProcess, STATUS_PROCESS_CLONED);
  end;

  // Put the clone into the job, but don't fail if we can not
  NtxAssignProcessToJob(Info.hxProcess.Handle, hxJob.Handle);

  // Let the clone execute
  Result := NtxResumeThread(Info.hxThread.Handle);

  if not Result.IsSuccess then
    Exit;

  // Wait for clone's completion
  Result := NtxWaitForSingleObject(Info.hxProcess.Handle, Timeout);

  if not Result.IsSuccess then
    Exit;

  if Result.Status = STATUS_TIMEOUT then
  begin
    Result.Status := STATUS_WAIT_TIMEOUT;
    NtxTerminateProcess(Info.hxProcess.Handle, STATUS_WAIT_TIMEOUT);
    Exit;
  end;

  // Forward the result
  if SharedMemory.Data.Location = @SharedMemory.Data.LocationBuffer[0] then
    Result.Location := RtlxCaptureString(SharedMemory.Data.Location,
      CLONE_MAX_STRING_LENGTH)
  else
    Result.Location := String(SharedMemory.Data.Location);

  Result.Status := SharedMemory.Data.Status;

  if CaptureStackTraces then
  begin
    // Suppress a stack trace from the current process
    Result.LastCall.StackTrace := nil;

    // Get a stack trace from the clone
    if (SharedMemory.Data.StackTraceLength > 0) and
      (SharedMemory.Data.StackTraceLength <= CLONE_MAX_STACK_TRACE_DEPTH) then
    begin
      Result.LastCall.StackTrace := nil;
      SetLength(Result.LastCall.StackTrace, SharedMemory.Data.StackTraceLength);
      Move(SharedMemory.Data.StackTrace, Result.LastCall.StackTrace[0],
        Length(Result.LastCall.StackTrace) * SizeOf(Pointer));
    end;
  end;
end;

end.
