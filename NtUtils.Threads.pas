unit NtUtils.Threads;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntrtl, NtUtils,
  NtUtils.Objects, DelphiUtils.AutoObject;

const
  // Ntapi.ntpsapi
  NtCurrentThread: THandle = THandle(-2);

  THREAD_READ_TEB = THREAD_GET_CONTEXT or THREAD_SET_CONTEXT;

type
  IContext = IMemory<PContext>;

// Open a thread (always succeeds for the current PID)
function NtxOpenThread(out hxThread: IHandle; TID: TThreadId;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Reopen a handle to the current thread with the specific access
function NtxOpenCurrentThread(out hxThread: IHandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Query variable-size information
function NtxQueryThread(hThread: THandle; InfoClass: TThreadInfoClass;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil): TNtxStatus;

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

// Assign a thread a name
function NtxSetNameThread(hThread: THandle; Name: String): TNtxStatus;

// Read content of thread's TEB
function NtxReadTebThread(hThread: THandle; Offset: Cardinal; Size: Cardinal;
  out Memory: IMemory): TNtxStatus;

// Query last syscall issued by a thread
function NtxQueyLastSyscallThread(hThread: THandle; out LastSyscall:
  TThreadLastSyscall): TNtxStatus;

// Query exit status of a thread
function NtxQueryExitStatusThread(hThread: THandle; out ExitStatus: NTSTATUS)
  : TNtxStatus;

// Queue user APC to a thread
function NtxQueueApcThread(hThread: THandle; Routine: TPsApcRoutine;
  Argument1: Pointer = nil; Argument2: Pointer = nil; Argument3: Pointer = nil)
  : TNtxStatus;

// Get thread context
function NtxGetContextThread(hThread: THandle; FlagsToQuery: Cardinal;
  out Context: IContext): TNtxStatus;

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
  NtUtils.Access.Expected, NtUtils.Version;

function NtxOpenThread(out hxThread: IHandle; TID: TThreadId;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;
var
  hThread: THandle;
  ClientId: TClientId;
  ObjAttr: TObjectAttributes;
begin
  if TID = NtCurrentThreadId then
  begin
    hxThread := TAutoHandle.Capture(NtCurrentThread);
    hxThread.AutoRelease := False;
    Result.Status := STATUS_SUCCESS;
  end
  else
  begin
    InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);
    ClientId.Create(0, TID);

    Result.Location := 'NtOpenThread';
    Result.LastCall.AttachAccess<TThreadAccessMask>(DesiredAccess);

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
  out xMemory: IMemory; InitialBuffer: Cardinal; GrowthMethod:
  TBufferGrowthMethod): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  RtlxComputeThreadQueryAccess(Result.LastCall, InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationThread(hThread, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxSetThread(hThread: THandle; InfoClass: TThreadInfoClass;
  Data: Pointer; DataSize: Cardinal): TNtxStatus;
begin
  Result.Location := 'NtSetInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  RtlxComputeThreadSetAccess(Result.LastCall, InfoClass);

  Result.Status := NtSetInformationThread(hThread, InfoClass, Data, DataSize);
end;

class function NtxThread.Query<T>(hThread: THandle;
  InfoClass: TThreadInfoClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  RtlxComputeThreadQueryAccess(Result.LastCall, InfoClass);

  Result.Status := NtQueryInformationThread(hThread, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxThread.SetInfo<T>(hThread: THandle;
  InfoClass: TThreadInfoClass; const Buffer: T): TNtxStatus;
begin
  Result := NtxSetThread(hThread, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxSetNameThread(hThread: THandle; Name: String): TNtxStatus;
begin
  NtxThread.SetInfo(hThread, ThreadNameInformation, TNtUnicodeString.From(Name));
end;

function NtxReadTebThread(hThread: THandle; Offset: Cardinal; Size: Cardinal;
  out Memory: IMemory): TNtxStatus;
var
  TebInfo: TThreadTebInformation;
begin
  Memory := TAutoMemory.Allocate(Size);

  // Describe the read request
  TebInfo.TebInformation := Memory.Data;
  TebInfo.TebOffset := Offset;
  TebInfo.BytesToRead := Size;

  // Query TEB content
  Result := NtxThread.Query(hThread, ThreadTebInformation, TebInfo);

  if not Result.IsSuccess then
    Memory := nil;
end;

function NtxQueyLastSyscallThread(hThread: THandle; out LastSyscall:
  TThreadLastSyscall): TNtxStatus;
var
  LastSyscallWin7: TThreadLastSyscallWin7;
begin
  if RtlOsVersionAtLeast(OsWin8) then
  begin
    FillChar(LastSyscall, SizeOf(LastSyscall), 0);
    Result := NtxThread.Query(hThread, ThreadLastSystemCall, LastSyscall);
  end
  else
  begin
    FillChar(LastSyscallWin7, SizeOf(LastSyscallWin7), 0);
    Result := NtxThread.Query(hThread, ThreadLastSystemCall, LastSyscallWin7);

    if Result.IsSuccess then
    begin
      LastSyscall.FirstArgument := LastSyscallWin7.FirstArgument;
      LastSyscall.SystemCallNumber := LastSyscallWin7.SystemCallNumber;
      LastSyscall.WaitTime := 0;
    end;
  end;
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

function NtxQueueApcThread(hThread: THandle; Routine: TPsApcRoutine;
  Argument1: Pointer; Argument2: Pointer; Argument3: Pointer): TNtxStatus;
begin
  Result.Location := 'NtQueueApcThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SET_CONTEXT);

  Result.Status := NtQueueApcThread(hThread, Routine, Argument1, Argument2,
    Argument3);
end;

function NtxGetContextThread(hThread: THandle; FlagsToQuery: Cardinal;
  out Context: IContext): TNtxStatus;
begin
  IMemory(Context) := TAutoMemory.Allocate(SizeOf(TContext));
  Context.Data.ContextFlags := FlagsToQuery;

  Result.Location := 'NtGetContextThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_GET_CONTEXT);
  Result.Status := NtGetContextThread(hThread, Context.Data);
end;

function NtxSetContextThread(hThread: THandle; Context: PContext):
  TNtxStatus;
begin
  Result.Location := 'NtSetContextThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SET_CONTEXT);
  Result.Status := NtSetContextThread(hThread, Context);
end;

function NtxSuspendThread(hThread: THandle): TNtxStatus;
begin
  Result.Location := 'NtSuspendThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SUSPEND_RESUME);
  Result.Status := NtSuspendThread(hThread);
end;

function NtxResumeThread(hThread: THandle): TNtxStatus;
begin
  Result.Location := 'NtResumeThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SUSPEND_RESUME);
  Result.Status := NtResumeThread(hThread);
end;

function NtxTerminateThread(hThread: THandle; ExitStatus: NTSTATUS): TNtxStatus;
begin
  Result.Location := 'NtTerminateThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_TERMINATE);
  Result.Status := NtTerminateThread(hThread, ExitStatus);
end;

function NtxSleep(Timeout: Int64; Alertable: Boolean): TNtxStatus;
begin
  Result.Location := 'NtDelayExecution';
  Result.Status := NtDelayExecution(Alertable, PLargeInteger(@Timeout));
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
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_THREAD);

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
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_THREAD);

  Result.Status := RtlCreateUserThread(hProcess, nil, CreateSuspended, 0, 0, 0,
    StartRoutine, Parameter, hThread, nil);

  if Result.IsSuccess then
    hxThread := TAutoHandle.Capture(hThread);
end;

end.
