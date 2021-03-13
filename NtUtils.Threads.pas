unit NtUtils.Threads;

{
  This module provides functions for working with threads via Native API.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntrtl, NtUtils,
  NtUtils.Objects, DelphiUtils.AutoObject;

const
  // Ntapi.ntpsapi
  NtCurrentThread = THandle(-2);

  THREAD_READ_TEB = THREAD_GET_CONTEXT or THREAD_SET_CONTEXT;

type
  IContext = IMemory<PContext>;

// Get a pseudo-handle to the current thread
function NtxCurrentThread: IHandle;

// Open a thread (always succeeds for the current PID)
function NtxOpenThread(
  out hxThread: IHandle;
  TID: TThreadId;
  DesiredAccess: TThreadAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Reopen a handle to the current thread with the specific access
function NtxOpenCurrentThread(
  out hxThread: IHandle;
  DesiredAccess: TThreadAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Query variable-size information
function NtxQueryThread(
  hThread: THandle;
  InfoClass: TThreadInfoClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Set variable-size information
function NtxSetThread(
  hThread: THandle;
  InfoClass: TThreadInfoClass;
  Buffer: Pointer;
  BufferSize: Cardinal
): TNtxStatus;

type
  NtxThread = class abstract
    // Query fixed-size information
    class function Query<T>(
      hThread: THandle;
      InfoClass: TThreadInfoClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size information
    class function &Set<T>(
      hThread: THandle;
      InfoClass: TThreadInfoClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Assign a thread a name
function NtxSetNameThread(
  hThread: THandle;
  Name: String
): TNtxStatus;

// Read content of thread's TEB
function NtxReadTebThread(
  hThread: THandle;
  Offset: Cardinal;
  Size: Cardinal;
  out Memory: IMemory
): TNtxStatus;

// Query last syscall issued by a thread
function NtxQueyLastSyscallThread(
  hThread: THandle;
  out LastSyscall: TThreadLastSyscall
): TNtxStatus;

// Query exit status of a thread
function NtxQueryExitStatusThread(
  hThread: THandle;
  out ExitStatus: NTSTATUS
): TNtxStatus;

// Queue user APC to a thread
function NtxQueueApcThread(
  hThread: THandle;
  Routine: TPsApcRoutine;
  Argument1: Pointer = nil;
  Argument2: Pointer = nil;
  Argument3: Pointer = nil
): TNtxStatus;

// Get thread context
function NtxGetContextThread(
  hThread: THandle;
  FlagsToQuery: TContextFlags;
  out Context: IContext
): TNtxStatus;

// Set thread context
function NtxSetContextThread(
  hThread: THandle;
  const Context: TContext
): TNtxStatus;

// Suspend/resume/terminate a thread
function NtxSuspendThread(hThread: THandle): TNtxStatus;
function NtxResumeThread(hThread: THandle): TNtxStatus;
function NtxTerminateThread(hThread: THandle; ExitStatus: NTSTATUS): TNtxStatus;

// Resume a thread when the object goes out of scope
function NtxDelayedResumeThread(hxThread: IHandle): IAutoReleasable;

// Terminate a thread when the object goes out of scope
function NtxDelayedTerminateThread(
  hxThread: IHandle;
  ExitStatus: NTSTATUS
): IAutoReleasable;

// Delay current thread's execution
function NtxDelayExecution(
  Timeout: Int64;
  Alertable: Boolean = False
): TNtxStatus;

// Create a thread in a process
function NtxCreateThread(
  out hxThread: IHandle;
  hProcess: THandle;
  StartRoutine: TUserThreadStartRoutine;
  Argument: Pointer;
  CreateFlags: TThreadCreateFlags = 0;
  ZeroBits: NativeUInt = 0;
  StackSize: NativeUInt = 0;
  MaxStackSize: NativeUInt = 0;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Create a thread in a process
function RtlxCreateThread(
  out hxThread: IHandle;
  hProcess: THandle;
  StartRoutine: TUserThreadStartRoutine;
  Parameter: Pointer;
  CreateSuspended: Boolean = False
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, Ntapi.ntseapi, Ntapi.ntexapi, Ntapi.ntmmapi,
  NtUtils.Version;

var
  NtxpCurrentThread: IHandle;

function NtxCurrentThread;
begin
  if not Assigned(NtxpCurrentThread) then
  begin
    NtxpCurrentThread := TAutoHandle.Capture(NtCurrentThread);
    NtxpCurrentThread.AutoRelease := False;
  end;

  Result := NtxpCurrentThread;
end;

function NtxOpenThread;
var
  hThread: THandle;
  ClientId: TClientId;
  ObjAttr: TObjectAttributes;
begin
  if TID = NtCurrentThreadId then
  begin
    // Always succeed on the current thread
    hxThread := NtxCurrentThread;
    Result.Status := STATUS_SUCCESS;
  end
  else
  begin
    InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);
    ClientId.Create(0, TID);

    Result.Location := 'NtOpenThread';
    Result.LastCall.AttachAccess(DesiredAccess);

    Result.Status := NtOpenThread(hThread, DesiredAccess, ObjAttr, ClientId);

    if Result.IsSuccess then
      hxThread := TAutoHandle.Capture(hThread);
  end;
end;

function NtxOpenCurrentThread;
var
  hThread: THandle;
  Flags: TDuplicateOptions;
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
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.Status := NtDuplicateObject(NtCurrentProcess, NtCurrentThread,
    NtCurrentProcess, hThread, DesiredAccess, HandleAttributes, Flags);

  if Result.IsSuccess then
    hxThread := TAutoHandle.Capture(hThread);
end;

function NtxQueryThread;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedThreadQueryAccess(InfoClass));

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationThread(hThread, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxSetThread;
begin
  Result.Location := 'NtSetInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedThreadSetAccess(InfoClass));
  Result.LastCall.ExpectedPrivilege := ExpectedThreadSetPrivilege(InfoClass);

  // Additional expected access
  case InfoClass of
    ThreadImpersonationToken:
      Result.LastCall.Expects<TTokenAccessMask>(TOKEN_IMPERSONATE);

    ThreadCpuAccountingInformation:
      Result.LastCall.Expects<TSessionAccessMask>(SESSION_MODIFY_ACCESS);

    ThreadAttachContainer:
      Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_IMPERSONATE);
  end;

  Result.Status := NtSetInformationThread(hThread, InfoClass, Buffer,
    BufferSize);
end;

class function NtxThread.Query<T>;
begin
  Result.Location := 'NtQueryInformationThread';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedThreadQueryAccess(InfoClass));

  Result.Status := NtQueryInformationThread(hThread, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxThread.&Set<T>;
begin
  Result := NtxSetThread(hThread, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxSetNameThread;
begin
  NtxThread.&Set(hThread, ThreadNameInformation, TNtUnicodeString.From(Name));
end;

function NtxReadTebThread;
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

function NtxQueyLastSyscallThread;
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

function NtxQueryExitStatusThread;
var
  Info: TThreadBasicInformation;
begin
  Result := NtxThread.Query(hThread, ThreadBasicInformation, Info);

  if Result.IsSuccess then
    ExitStatus := Info.ExitStatus;
end;

function NtxQueueApcThread;
begin
  Result.Location := 'NtQueueApcThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SET_CONTEXT);

  Result.Status := NtQueueApcThread(hThread, Routine, Argument1, Argument2,
    Argument3);
end;

function NtxGetContextThread;
begin
  IMemory(Context) := TAutoMemory.Allocate(SizeOf(TContext));
  Context.Data.ContextFlags := FlagsToQuery;

  Result.Location := 'NtGetContextThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_GET_CONTEXT);
  Result.Status := NtGetContextThread(hThread, Context.Data^);
end;

function NtxSetContextThread;
begin
  Result.Location := 'NtSetContextThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SET_CONTEXT);
  Result.Status := NtSetContextThread(hThread, Context);
end;

function NtxSuspendThread;
begin
  Result.Location := 'NtSuspendThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SUSPEND_RESUME);
  Result.Status := NtSuspendThread(hThread);
end;

function NtxResumeThread;
begin
  Result.Location := 'NtResumeThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SUSPEND_RESUME);
  Result.Status := NtResumeThread(hThread);
end;

function NtxTerminateThread;
begin
  Result.Location := 'NtTerminateThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_TERMINATE);
  Result.Status := NtTerminateThread(hThread, ExitStatus);
end;

function NtxDelayedResumeThread;
begin
  Result := TDelayedOperation.Create(
    procedure
    begin
      NtxResumeThread(hxThread.Handle);
    end
  );
end;

function NtxDelayedTerminateThread;
begin
  Result := TDelayedOperation.Create(
    procedure
    begin
      NtxTerminateThread(hxThread.Handle, ExitStatus);
    end
  );
end;

function NtxDelayExecution;
begin
  Result.Location := 'NtDelayExecution';
  Result.Status := NtDelayExecution(Alertable, PLargeInteger(@Timeout));
end;

function NtxCreateThread;
var
  hThread: THandle;
begin
  Result.Location := 'NtCreateThreadEx';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_THREAD);

  Result.Status := NtCreateThreadEx(hThread, THREAD_ALL_ACCESS,
    AttributesRefOrNil(ObjectAttributes), hProcess, StartRoutine, Argument,
    CreateFlags, ZeroBits, StackSize, MaxStackSize, nil);

  if Result.IsSuccess then
    hxThread := TAutoHandle.Capture(hThread);
end;

function RtlxCreateThread;
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
