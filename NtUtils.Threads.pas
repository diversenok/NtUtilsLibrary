unit NtUtils.Threads;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntrtl, NtUtils.Exceptions,
  NtUtils.Objects;

const
  // Ntapi.ntpsapi
  NtCurrentThread: THandle = THandle(-2);

// Open a thread (always succeeds for the current PID)
function NtxOpenThread(out hxThread: IHandle; TID: NativeUInt;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Reopen a handle to the current thread with the specific access
function NtxOpenCurrentThread(out hxThread: IHandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Query variable-size information
function NtxQueryThread(hThread: THandle; InfoClass: TThreadInfoClass;
  out Status: TNtxStatus): Pointer;

// Set variable-size information
function NtxSetThread(hThread: THandle; InfoClass: TThreadInfoClass;
  Data: Pointer; DataSize: Cardinal): TNtxStatus;

type
  NtxThread = class
    // Query fixed-size information
    class function Query<T>(hThread: THandle;
      InfoClass: TThreadInfoClass; out Buffer: T): TNtxStatus; static;

    // Set fixed-size information
    class function SetInfo<T>(hThread: THandle;
      InfoClass: TThreadInfoClass; const Buffer: T): TNtxStatus; static;
  end;

// Query exit status of a thread
function NtxQueryExitStatusThread(hThread: THandle; out ExitStatus: NTSTATUS)
  : TNtxStatus;

// Get thread context
// NOTE: On success free the memory with FreeMem
function NtxGetContextThread(hThread: THandle; FlagsToQuery: Cardinal;
  out Context: PContext): TNtxStatus;

// Set thread context
function NtxSetContextThread(hThread: THandle; Context: PContext):
  TNtxStatus;

// Suspend/resume a thread
function NtxSuspendThread(hThread: THandle): TNtxStatus;
function NtxResumeThread(hThread: THandle): TNtxStatus;

// Terminate a thread
function NtxTerminateThread(hThread: THandle; ExitStatus: NTSTATUS): TNtxStatus;

// Delay current thread's execution
function NtxSleep(Timeout: Int64; Alertable: Boolean = False): TNtxStatus;

// Create a thread in a process
function NtxCreateThread(out hxThread: IHandle; hProcess: THandle; StartRoutine:
  TUserThreadStartRoutine; Argument: Pointer; CreateFlags: Cardinal = 0;
  ZeroBits: NativeUInt = 0; StackSize: NativeUInt = 0; MaxStackSize:
  NativeUInt = 0; HandleAttributes: Cardinal = 0): TNtxStatus;

// Create a thread in a process
function RtlxCreateThread(out hxThread: IHandle; hProcess: THandle;
  StartRoutine: TUserThreadStartRoutine; Parameter: Pointer;
  CreateSuspended: Boolean = False): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, Ntapi.ntseapi, Ntapi.ntexapi,
  NtUtils.Access.Expected;

function NtxOpenThread(out hxThread: IHandle; TID: NativeUInt;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;
var
  hThread: THandle;
  ClientId: TClientId;
  ObjAttr: TObjectAttributes;
begin
  if TID = NtCurrentThreadId then
  begin
    hxThread := TAutoHandle.Capture(NtCurrentThread);
    Result.Status := STATUS_SUCCESS;
  end
  else
  begin
    InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);
    ClientId.Create(0, TID);

    Result.Location := 'NtOpenThread';
    Result.LastCall.CallType := lcOpenCall;
    Result.LastCall.AccessMask := DesiredAccess;
    Result.LastCall.AccessMaskType := @ThreadAccessType;

    Result.Status := NtOpenThread(hThread, DesiredAccess, ObjAttr, ClientId);

    if Result.IsSuccess then
      hxThread := TAutoHandle.Capture(hThread);
  end;
end;

function NtxOpenCurrentThread(out hxThread: IHandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal): TNtxStatus;
var
  hThread: THandle;
  Flags: Cardinal;
begin
  // Duplicating the pseudo-handle is more reliable then opening thread by TID

  if DesiredAccess and MAXIMUM_ALLOWED <> 0 then
  begin
    Flags := DUPLICATE_SAME_ACCESS;
    DesiredAccess := 0;
  end
  else
    Flags := 0;

  Result.Location := 'NtDuplicateObject';
  Result.Status := NtDuplicateObject(NtCurrentProcess, NtCurrentThread,
    NtCurrentProcess, hThread, DesiredAccess, HandleAttributes, Flags);

  if Result.IsSuccess then
    hxThread := TAutoHandle.Capture(hThread);
end;

function NtxQueryThread(hThread: THandle; InfoClass: TThreadInfoClass;
  out Status: TNtxStatus): Pointer;
var
  BufferSize, Required: Cardinal;
begin
  Status.Location := 'NtQueryInformationThread';
  Status.LastCall.CallType := lcQuerySetCall;
  Status.LastCall.InfoClass := Cardinal(InfoClass);
  Status.LastCall.InfoClassType := TypeInfo(TThreadInfoClass);
  RtlxComputeThreadQueryAccess(Status.LastCall, InfoClass);

  BufferSize := 0;
  repeat
    Result := AllocMem(BufferSize);

    Required := 0;
    Status.Status := NtQueryInformationThread(hThread, InfoClass, Result,
      BufferSize, @Required);

    if not Status.IsSuccess then
    begin
      FreeMem(Result);
      Result := nil;
    end;
  until not NtxExpandBuffer(Status, BufferSize, Required);
end;

function NtxSetThread(hThread: THandle; InfoClass: TThreadInfoClass;
  Data: Pointer; DataSize: Cardinal): TNtxStatus;
begin
  Result.Location := 'NtSetInformationThread';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TThreadInfoClass);
  RtlxComputeThreadSetAccess(Result.LastCall, InfoClass);

  Result.Status := NtSetInformationThread(hThread, InfoClass, Data, DataSize);
end;

class function NtxThread.Query<T>(hThread: THandle;
  InfoClass: TThreadInfoClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationThread';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TThreadInfoClass);
  RtlxComputeThreadQueryAccess(Result.LastCall, InfoClass);

  Result.Status := NtQueryInformationThread(hThread, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxThread.SetInfo<T>(hThread: THandle;
  InfoClass: TThreadInfoClass; const Buffer: T): TNtxStatus;
begin
  Result := NtxSetThread(hThread, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxQueryExitStatusThread(hThread: THandle; out ExitStatus: NTSTATUS)
  : TNtxStatus;
var
  Info: TThreadBasicInformation;
begin
  Result := NtxThread.Query(hThread, ThreadBasicInformation, Info);

  if Result.IsSuccess then
    ExitStatus := Info.ExitStatus;
end;

function NtxGetContextThread(hThread: THandle; FlagsToQuery: Cardinal;
  out Context: PContext): TNtxStatus;
begin
  Context := AllocMem(SizeOf(TContext));
  Context.ContextFlags := FlagsToQuery;

  Result.Location := 'NtGetContextThread';
  Result.LastCall.Expects(THREAD_GET_CONTEXT, @ThreadAccessType);
  Result.Status := NtGetContextThread(hThread, Context);

  if not Result.IsSuccess then
    FreeMem(Context);
end;

function NtxSetContextThread(hThread: THandle; Context: PContext):
  TNtxStatus;
begin
  Result.Location := 'NtSetContextThread';
  Result.LastCall.Expects(THREAD_SET_CONTEXT, @ThreadAccessType);
  Result.Status := NtSetContextThread(hThread, Context);
end;

function NtxSuspendThread(hThread: THandle): TNtxStatus;
begin
  Result.Location := 'NtSuspendThread';
  Result.LastCall.Expects(THREAD_SUSPEND_RESUME, @ThreadAccessType);
  Result.Status := NtSuspendThread(hThread);
end;

function NtxResumeThread(hThread: THandle): TNtxStatus;
begin
  Result.Location := 'NtResumeThread';
  Result.LastCall.Expects(THREAD_SUSPEND_RESUME, @ThreadAccessType);
  Result.Status := NtResumeThread(hThread);
end;

function NtxTerminateThread(hThread: THandle; ExitStatus: NTSTATUS): TNtxStatus;
begin
  Result.Location := 'NtTerminateThread';
  Result.LastCall.Expects(THREAD_TERMINATE, @ThreadAccessType);
  Result.Status := NtTerminateThread(hThread, ExitStatus);
end;

function NtxSleep(Timeout: Int64; Alertable: Boolean): TNtxStatus;
begin
  Result.Location := 'NtDelayExecution';
  Result.Status := NtDelayExecution(Alertable, Int64ToLargeInteger(Timeout));
end;

function NtxCreateThread(out hxThread: IHandle; hProcess: THandle; StartRoutine:
  TUserThreadStartRoutine; Argument: Pointer; CreateFlags: Cardinal; ZeroBits:
  NativeUInt; StackSize: NativeUInt; MaxStackSize: NativeUInt; HandleAttributes:
  Cardinal): TNtxStatus;
var
  hThread: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);

  Result.Location := 'NtCreateThreadEx';
  Result.LastCall.Expects(PROCESS_CREATE_THREAD, @ProcessAccessType);

  Result.Status := NtCreateThreadEx(hThread, THREAD_ALL_ACCESS, @ObjAttr,
    hProcess, StartRoutine, Argument, CreateFlags, ZeroBits, StackSize,
    MaxStackSize, nil);

  if Result.IsSuccess then
    hxThread := TAutoHandle.Capture(hThread);
end;

function RtlxCreateThread(out hxThread: IHandle; hProcess: THandle;
  StartRoutine: TUserThreadStartRoutine; Parameter: Pointer;
  CreateSuspended: Boolean): TNtxStatus;
var
  hThread: THandle;
begin
  Result.Location := 'RtlCreateUserThread';
  Result.LastCall.Expects(PROCESS_CREATE_THREAD, @ProcessAccessType);

  Result.Status := RtlCreateUserThread(hProcess, nil, CreateSuspended, 0, 0, 0,
    StartRoutine, Parameter, hThread, nil);

  if Result.IsSuccess then
    hxThread := TAutoHandle.Capture(hThread);
end;

end.
