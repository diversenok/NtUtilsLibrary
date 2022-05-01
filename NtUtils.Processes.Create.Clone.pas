unit NtUtils.Processes.Create.Clone;

{
  This module provides support for cloning (aka forking) the current process.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.ntdbg, Ntapi.ntseapi, DelphiApi.Reflection,
  NtUtils, NtUtils.Processes.Create;

type
  TNtxOperation = reference to function : TNtxStatus;

{ Helper functions (parent) }

// Make as many handles inheritable as possible
function RtlxInheritAllHandles: TNtxStatus;

// Map a shared memory region to talk to the clone
function RtlxMapSharedMemory(
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
  Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.ntdef, Ntapi.ConsoleApi, NtUtils.Threads,
  NtUtils.Objects, NtUtils.Objects.Snapshots, NtUtils.Synchronization,
  NtUtils.Sections, NtUtils.Processes, NtUtils.Processes.Info,
  NtUtils.Tokens.Impersonate, DelphiUtils.AutoObjects;

function RtlxInheritAllHandles;
var
  AutoSuspended: TArray<IAutoReleasable>;
  hxThread: IHandle;
  Info: TThreadBasicInformation;
  Handles: TArray<TProcessHandleEntry>;
  Handle: TProcessHandleEntry;
begin
  AutoSuspended := nil;

  Info := Default(TThreadBasicInformation);

  // Suspend all other threads to mitigate race conditions
  while NtxGetNextThread(NtCurrentProcess, hxThread, THREAD_SUSPEND_RESUME or
    THREAD_QUERY_LIMITED_INFORMATION).IsSuccess do
    if NtxThread.Query(hxThread.Handle, ThreadBasicInformation, Info).IsSuccess
      and (Info.ClientId.UniqueThread <> NtCurrentThreadId) and
      NtxSuspendThread(hxThread.Handle).IsSuccess then
    begin
      SetLength(AutoSuspended, Length(AutoSuspended) + 1);
      AutoSuspended[High(AutoSuspended)] := NtxDelayedResumeThread(hxThread);
    end;

  // Snapshot all our handles
  Result := NtxEnumerateHandlesProcess(NtCurrentProcess, Handles);

  if not Result.IsSuccess then
    Exit;

  // Mark them inheritable
  for Handle in Handles do
    NtxSetFlagsHandle(Handle.HandleValue, True,
      BitTest(Handle.HandleAttributes and OBJ_PROTECT_CLOSE));
end;

function RtlxMapSharedMemory;
var
  hxSection: IHandle;
begin
  Result := NtxCreateSection(hxSection, Size);

  if Result.IsSuccess then
    Result := NtxMapViewOfSection(Memory, hxSection.Handle, NtxCurrentProcess);
end;

function RtlxAttachToParentConsole;
var
  Info: TProcessBasicInformation;
begin
  Result.Location := 'FreeConsole';
  Result.Win32Result := FreeConsole;

  if not Result.IsSuccess then
    Exit;

  Result := NtxProcess.Query(NtCurrentProcess, ProcessBasicInformation, Info);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'AttachConsole';
  Result.Win32Result := AttachConsole(Info.InheritedFromUniqueProcessID);
end;

function RtlxCloneCurrentProcess;
var
  RtlProcessInfo: TRtlUserProcessInformation;
  ModifiedFlags: TRtlProcessCloneFlags;
begin
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
    Info.ClientId := RtlProcessInfo.ClientId;
    Info.hxProcess := Auto.CaptureHandle(RtlProcessInfo.Process);
    Info.hxThread := Auto.CaptureHandle(RtlProcessInfo.Thread);

    if Assigned(PrimaryToken) then
    begin
      // Swap the primary token while the clone is suspended
      Result := NtxAssignPrimaryToken(Info.hxProcess.Handle, PrimaryToken);

      if not Result.IsSuccess then
      begin
        // Fail and cleanup
        NtxTerminateProcess(Info.hxProcess.Handle, STATUS_CANCELLED);
        Info := Default(TProcessInfo);
        Exit;
      end;

      // Resume when necessary
      if not BitTest(Flags and RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED) then
        NtxResumeThread(Info.hxThread.Handle);
    end;
  end;
end;

type
  TCloneSharedData = record
    Status: NTSTATUS;
    Location: PWideChar;
    StackTraceLength: Cardinal;
    StackTrace: array [0 .. MAX_STACK_TRACE_DEPTH - 1] of Pointer;
    LocationBuffer: TAnysizeArray<WideChar>;
  end;
  PCloneSharedData = ^TCloneSharedData;

function RtlxExecuteInClone;
var
  SharedMemory: IMemory<PCloneSharedData>;
  Info: TProcessInfo;
  Completed: Boolean;
begin
  // Map shared memory for getting TNtxStatus back from the clone
  Result := RtlxMapSharedMemory(SizeOf(TCloneSharedData),
    IMemory(SharedMemory));

  if not Result.IsSuccess then
    Exit;

  SharedMemory.Data.Location := 'Clone';
  SharedMemory.Data.Status := STATUS_UNSUCCESSFUL;

  // Clone the process
  Result := RtlxCloneCurrentProcess(Info, Flags, hxToken);

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
      else if Cardinal(Length(Result.Location)) * SizeOf(WideChar) <
        SharedMemory.Size - SizeOf(TCloneSharedData) then
      begin
        Move(PWideChar(Result.Location)^, SharedMemory.Data.LocationBuffer,
          Length(Result.Location) * SizeOf(WideChar));

        SharedMemory.Data.Location := Pointer(@SharedMemory.Data.LocationBuffer);
      end;

      // Save the stack trace
      if CaptureStackTraces and (Length(Result.LastCall.StackTrace) > 0) then
      begin
        SharedMemory.Data.StackTraceLength := Length(Result.LastCall.StackTrace);

        Move(Result.LastCall.StackTrace[0], SharedMemory.Data.StackTrace,
          Length(Result.LastCall.StackTrace) * SizeOf(Pointer));
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
            MAX_STACK_TRACE_DEPTH, @SharedMemory.Data.StackTrace, nil);
      end;
    end;
  finally
    // Do not try to clean-up
    NtxTerminateProcess(NtCurrentProcess, STATUS_PROCESS_CLONED);
  end;

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
  Result.Location := String(SharedMemory.Data.Location);
  Result.Status := SharedMemory.Data.Status;

  if CaptureStackTraces then
  begin
    // Suppress a stack trace from the current process
    Result.LastCall.StackTrace := nil;

    // Get a stack trace from the clone
    if SharedMemory.Data.StackTraceLength > 0 then
    begin
      Result.LastCall.StackTrace := nil;
      SetLength(Result.LastCall.StackTrace, SharedMemory.Data.StackTraceLength);
      Move(SharedMemory.Data.StackTrace, Result.LastCall.StackTrace[0],
        Length(Result.LastCall.StackTrace) * SizeOf(Pointer));
    end;
  end;
end;

end.
