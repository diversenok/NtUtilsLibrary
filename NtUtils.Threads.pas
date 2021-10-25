unit NtUtils.Threads;

{
  This module provides functions for working with threads via Native API.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntrtl, Ntapi.ntseapi, NtUtils;

const
  // Ntapi.ntpsapi
  NtCurrentProcess = THandle(-1);
  NtCurrentThread = THandle(-2);

  THREAD_READ_TEB = THREAD_GET_CONTEXT or THREAD_SET_CONTEXT;

  // For suspend/resume via state change
  THREAD_CHANGE_STATE = THREAD_SET_INFORMATION or THREAD_SUSPEND_RESUME;

type
  TThreadApcOptions = set of (
    apcForceSignal, // Use special user APCs when possible (Win 10 RS5+)
    apcWoW64        // Queue a WoW64 APC
  );

{ Opening }

// Get a pseudo-handle to the current thread
function NtxCurrentThread: IHandle;

// Open a thread (always succeeds for the current PID)
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenThread(
  out hxThread: IHandle;
  TID: TThreadId;
  DesiredAccess: TThreadAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Reopen a handle to the current thread with the specific access
function NtxOpenCurrentThread(
  out hxThread: IHandle;
  DesiredAccess: TThreadAccessMask = MAXIMUM_ALLOWED;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Iterate through accessible threads in a process
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxGetNextThread(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  [opt] var hxThread: IHandle; // use nil to start
  DesiredAccess: TThreadAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Open a process containing a thread
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenProcessByThreadId(
  out hxProcess: IHandle;
  TID: TThreadId;
  DesiredAccess: TProcessAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

{ Querying/Setting }

// Query variable-size information
function NtxQueryThread(
  [Access(THREAD_QUERY_INFORMATION)] hThread: THandle;
  InfoClass: TThreadInfoClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Set variable-size information
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_INCREASE_BASE_PRIORITY_PRIVILEGE, rpSometimes)]
function NtxSetThread(
  [Access(THREAD_SET_INFORMATION)] hThread: THandle;
  InfoClass: TThreadInfoClass;
  [in] Buffer: Pointer;
  BufferSize: Cardinal
): TNtxStatus;

type
  NtxThread = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(THREAD_QUERY_INFORMATION)] hThread: THandle;
      InfoClass: TThreadInfoClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size information
    [RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpSometimes)]
    [RequiredPrivilege(SE_INCREASE_BASE_PRIORITY_PRIVILEGE, rpSometimes)]
    class function &Set<T>(
      [Access(THREAD_SET_INFORMATION)] hThread: THandle;
      InfoClass: TThreadInfoClass;
      const Buffer: T
    ): TNtxStatus; static;

    // Read a portion of thread's TEB
    class function ReadTeb<T>(
      [Access(THREAD_READ_TEB)] hThread: THandle;
      out Buffer: T;
      Offset: Cardinal = 0
    ): TNtxStatus; static;
  end;

// Assign a thread a name
function NtxQueryNameThread(
  [Access(THREAD_QUERY_LIMITED_INFORMATION)] hThread: THandle;
  out Name: String
): TNtxStatus;

// Assign a thread a name
function NtxSetNameThread(
  [Access(THREAD_SET_LIMITED_INFORMATION)] hThread: THandle;
  const Name: String
): TNtxStatus;

// Read content of thread's TEB
function NtxReadTebThread(
  [Access(THREAD_READ_TEB)] hThread: THandle;
  Offset: Cardinal;
  Size: Cardinal;
  out Memory: IMemory
): TNtxStatus;

// Query last syscall issued by a thread
function NtxQueyLastSyscallThread(
  [Access(THREAD_GET_CONTEXT)] hThread: THandle;
  out LastSyscall: TThreadLastSyscall
): TNtxStatus;

// Query exit status of a thread
function NtxQueryExitStatusThread(
  [Access(THREAD_QUERY_LIMITED_INFORMATION)] hThread: THandle;
  out ExitStatus: NTSTATUS
): TNtxStatus;

{ Manipulation }

// Queue user APC to a thread
function NtxQueueApcThreadEx(
  [Access(THREAD_SET_CONTEXT)] hThread: THandle;
  Routine: TPsApcRoutine;
  [in, opt] Argument1: Pointer = nil;
  [in, opt] Argument2: Pointer = nil;
  [in, opt] Argument3: Pointer = nil;
  Options: TThreadApcOptions = []
): TNtxStatus;

// Get thread context
function NtxGetContextThread(
  [Access(THREAD_GET_CONTEXT)] hThread: THandle;
  FlagsToQuery: TContextFlags;
  out Context: IContext
): TNtxStatus;

// Set thread context
function NtxSetContextThread(
  [Access(THREAD_SET_CONTEXT)] hThread: THandle;
  [in] Context: PContext
): TNtxStatus;

// Suspend a thread
function NtxSuspendThread(
  [Access(THREAD_SUSPEND_RESUME)] hThread: THandle;
  [out, opt] PreviousSuspendCount: PCardinal = nil
): TNtxStatus;

// Resume a thread
function NtxResumeThread(
  [Access(THREAD_SUSPEND_RESUME)] hThread: THandle;
  [out, opt] PreviousSuspendCount: PCardinal = nil
): TNtxStatus;

// Terminate a thread
function NtxTerminateThread(
  [Access(THREAD_TERMINATE)] hThread: THandle;
  ExitStatus: NTSTATUS
): TNtxStatus;

// Resume a thread when the object goes out of scope
function NtxDelayedResumeThread(
  [Access(THREAD_SUSPEND_RESUME)] const hxThread: IHandle
): IAutoReleasable;

// Terminate a thread when the object goes out of scope
function NtxDelayedTerminateThread(
  [Access(THREAD_TERMINATE)] const hxThread: IHandle;
  ExitStatus: NTSTATUS
): IAutoReleasable;

// Create a thread state change object (requires Windows Insider)
function NtxCreateThreadState(
  out hxThreadState: IHandle;
  [Access(THREAD_CHANGE_STATE)] hThread: THandle;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Suspend or resume a thread via state change (requires Windows Insider)
function NtxChageStateThread(
  [Access(THREAD_STATE_CHANGE_STATE)] hThreadState: THandle;
  [Access(THREAD_CHANGE_STATE)] hThread: THandle;
  Action: TThreadStateChangeType
): TNtxStatus;

{ Creation }

// Create a thread in a process
function NtxCreateThread(
  out hxThread: IHandle;
  [Access(PROCESS_CREATE_THREAD)] hProcess: THandle;
  StartRoutine: TUserThreadStartRoutine;
  [in, opt] Argument: Pointer;
  CreateFlags: TThreadCreateFlags = 0;
  ZeroBits: NativeUInt = 0;
  StackSize: NativeUInt = 0;
  MaxStackSize: NativeUInt = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Create a thread in a process
function RtlxCreateThread(
  out hxThread: IHandle;
  [Access(PROCESS_CREATE_THREAD)] hProcess: THandle;
  StartRoutine: TUserThreadStartRoutine;
  [in, opt] Parameter: Pointer;
  CreateSuspended: Boolean = False
): TNtxStatus;

implementation

uses
  Ntapi.ntobapi, Ntapi.ntmmapi, Ntapi.Versions, NtUtils.Objects, NtUtils.Ldr,
  NtUtils.Processes;

var
  NtxpCurrentThread: IHandle;

function NtxCurrentThread;
begin
  if not Assigned(NtxpCurrentThread) then
  begin
    NtxpCurrentThread := NtxObject.Capture(NtCurrentThread);
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
  if (TID = NtCurrentThreadId) and
    not BitTest(DesiredAccess and ACCESS_SYSTEM_SECURITY) then
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
    Result.LastCall.OpensForAccess(DesiredAccess);

    Result.Status := NtOpenThread(hThread, DesiredAccess, ObjAttr, ClientId);

    if Result.IsSuccess then
      hxThread := NtxObject.Capture(hThread);
  end;
end;

function NtxOpenCurrentThread;
var
  hThread: THandle;
  Flags: TDuplicateOptions;
begin
  // Duplicating the pseudo-handle is more reliable then opening thread by TID

  if BitTest(DesiredAccess and MAXIMUM_ALLOWED) and
    not BitTest(DesiredAccess and ACCESS_SYSTEM_SECURITY) then
  begin
    Flags := DUPLICATE_SAME_ACCESS;
    DesiredAccess := 0;
  end
  else
    Flags := 0;

  Result.Location := 'NtDuplicateObject';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtDuplicateObject(NtCurrentProcess, NtCurrentThread,
    NtCurrentProcess, hThread, DesiredAccess, HandleAttributes, Flags);

  if Result.IsSuccess then
    hxThread := NtxObject.Capture(hThread);
end;

function NtxGetNextThread;
var
  hThread, hNewThread: THandle;
begin
  if Assigned(hxThread) then
    hThread := hxThread.Handle
  else
    hThread := 0;

  Result.Location := 'NtGetNextThread';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION);
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtGetNextThread(hProcess, hThread, DesiredAccess,
    HandleAttributes, 0, hNewThread);

  if Result.IsSuccess then
    hxThread := NtxObject.Capture(hNewThread);
end;

function NtxOpenProcessByThreadId;
var
  hxThread: IHandle;
  Info: TThreadBasicInformation;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_QUERY_LIMITED_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  Result := NtxThread.Query(hxThread.Handle, ThreadBasicInformation, Info);

  if not Result.IsSuccess then
    Exit;

  Result := NtxOpenProcess(hxProcess, Info.ClientId.UniqueProcess,
    DesiredAccess, HandleAttributes);
end;

function NtxQueryThread;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationThread';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedThreadQueryAccess(InfoClass));

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationThread(hThread, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxSetThread;
begin
  Result.Location := 'NtSetInformationThread';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
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
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedThreadQueryAccess(InfoClass));

  Result.Status := NtQueryInformationThread(hThread, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxThread.ReadTeb<T>;
var
  TebInfo: TThreadTebInformation;
begin
  TebInfo.TebInformation := @Buffer;
  TebInfo.TebOffset := Offset;
  TebInfo.BytesToRead := SizeOf(Buffer);

  Result := NtxThread.Query(hThread, ThreadTebInformation, TebInfo);
end;

class function NtxThread.&Set<T>;
begin
  Result := NtxSetThread(hThread, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxQueryNameThread;
var
  Buffer: INtUnicodeString;
begin
  Result := NtxQueryThread(hThread, ThreadNameInformation, IMemory(Buffer));

  if Result.IsSuccess then
    Name := Buffer.Data.ToString;
end;

function NtxSetNameThread;
begin
  Result := NtxThread.Set(hThread, ThreadNameInformation,
    TNtUnicodeString.From(Name));
end;

function NtxReadTebThread;
var
  TebInfo: TThreadTebInformation;
begin
  Memory := Auto.AllocateDynamic(Size);

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

function NtxQueueApcThreadEx;
var
  Flags: THandle;
begin
  if (apcForceSignal in Options) and RtlOsVersionAtLeast(OsWin10RS5) then
    Flags := APC_FORCE_THREAD_SIGNAL
  else
    Flags := 0;

  // Encode the pointer the same way RtlQueueApcWow64Thread does
  if apcWoW64 in Options then
    UIntPtr(@Routine) := UIntPtr(-IntPtr(@Routine)) shl 2;

  Result.Location := 'NtQueueApcThreadEx';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SET_CONTEXT);

  Result.Status := NtQueueApcThreadEx(hThread, Flags, Routine, Argument1,
    Argument2, Argument3);
end;

function NtxGetContextThread;
begin
  IMemory(Context) := Auto.AllocateDynamic(SizeOf(TContext));
  Context.Data.ContextFlags := FlagsToQuery;

  Result.Location := 'NtGetContextThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_GET_CONTEXT);
  Result.Status := NtGetContextThread(hThread, Context.Data);
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
  Result.Status := NtSuspendThread(hThread, PreviousSuspendCount);
end;

function NtxResumeThread;
begin
  Result.Location := 'NtResumeThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SUSPEND_RESUME);
  Result.Status := NtResumeThread(hThread, PreviousSuspendCount);
end;

function NtxTerminateThread;
begin
  Result.Location := 'NtTerminateThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_TERMINATE);
  Result.Status := NtTerminateThread(hThread, ExitStatus);
end;

function NtxDelayedResumeThread;
begin
  Result := Auto.Delay(
    procedure
    begin
      NtxResumeThread(hxThread.Handle);
    end
  );
end;

function NtxDelayedTerminateThread;
begin
  Result := Auto.Delay(
    procedure
    begin
      NtxTerminateThread(hxThread.Handle, ExitStatus);
    end
  );
end;

function NtxCreateThreadState;
var
  hThreadState: THandle;
begin
  Result := LdrxCheckNtDelayedImport('NtCreateThreadStateChange');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateThreadStateChange';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SET_INFORMATION);

  Result.Status := NtCreateThreadStateChange(
    hThreadState,
    AccessMaskOverride(THREAD_STATE_CHANGE_STATE, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    hThread,
    0
  );

  if Result.IsSuccess then
    hxThreadState := NtxObject.Capture(hThreadState);
end;

function NtxChageStateThread;
begin
  Result := LdrxCheckNtDelayedImport('NtChangeThreadState');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtChangeThreadState';
  Result.LastCall.UsesInfoClass(Action, icPerform);
  Result.LastCall.Expects<TThreadStateAccessMask>(THREAD_STATE_CHANGE_STATE);
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_SUSPEND_RESUME);

  Result.Status := NtChangeThreadState(hThreadState, hThread, Action, nil,
    0, 0);
end;

function NtxCreateThread;
var
  hThread: THandle;
begin
  Result.Location := 'NtCreateThreadEx';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_THREAD);

  Result.Status := NtCreateThreadEx(
    hThread,
    AccessMaskOverride(THREAD_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    hProcess,
    StartRoutine,
    Argument,
    CreateFlags,
    ZeroBits,
    StackSize,
    MaxStackSize,
    nil
  );

  if Result.IsSuccess then
    hxThread := NtxObject.Capture(hThread);
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
    hxThread := NtxObject.Capture(hThread);
end;

end.
