unit NtUtils.Debug;

{
  This module includes functions for user-mode debugging via Native API.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntdbg,
  NtUtils, NtUtils.Objects;

type
  TDbgxWaitState = Ntapi.ntdbg.TDbgUiWaitStateChange;

  TDbgxHandles = record
    hxThread, hxProcess, hxFile: IHandle;
  end;

{ -------------------------- Debug objects ----------------------------------- }

// Create a debug object
function NtxCreateDebugObject(
  out hxDebugObj: IHandle;
  KillOnClose: Boolean = False;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open existing debug object of a process
function NtxOpenDebugObjectProcess(
  out hxDebugObj: IHandle;
  hProcess: THandle
): TNtxStatus;

{ ------------------------ Debugging options --------------------------------- }

// Set whether the debugged process should be ternimated
// when the last handle to its debug port is closed
function NtxSetDebugKillOnExit(
  hDebugObject: THandle;
  KillOnExit: LongBool
): TNtxStatus;

// Query whether child processes should be debugged as well
function NtxQueryDebugInherit(
  hProcess: THandle;
  out InheritDebugging: LongBool
): TNtxStatus;

// Set whether child processes should be debugged as well
function NtxSetDebugInherit(
  hProcess: THandle;
  InheritDebugging: LongBool
): TNtxStatus;

{ --------------------------- Debugging -------------------------------------- }

// Assign a debug object to a process
function NtxDebugProcess(
  hProcess: THandle;
  hDebugObject: THandle
): TNtxStatus;

// Remove a debug object from a process
function NtxDebugProcessStop(
  hProcess: THandle;
  hDebugObject: THandle
): TNtxStatus;

// Wait for a debug event
function NtxDebugWait(
  hDebugObj: THandle;
  out WaitStateChange: TDbgUiWaitStateChange;
  out Handles: TDbgxHandles;
  const Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False
): TNtxStatus;

// Continue after a debug event
function NtxDebugContinue(
  hDebugObject: THandle;
  const ClientId: TClientId;
  Status: NTSTATUS = DBG_CONTINUE
): TNtxStatus;

{ ----------------------------- Breakin -------------------------------------- }

// Enable signle-step flag for a thread
// NOTE: make sure the thread is suspended before calling this function
function NtxSetTrapFlagThread(
  const hxThread: IHandle;
  Enabled: Boolean;
  AlreadySuspended: Boolean = False
): TNtxStatus;

// Perform a single step of a thread to start debugging it
function DbgxIssueThreadBreakin(
  const hxThread: IHandle
): TNtxStatus;

// Create a thread with a breakpoint inside a process
function DbgxIssueProcessBreakin(
  hProcess: THandle
): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, NtUtils.Threads, NtUtils.Processes.Query,
  DelphiUtils.AutoObject;

function NtxCreateDebugObject;
var
  hDebugObj: THandle;
  Flags: TDebugCreateFlags;
begin
  if KillOnClose then
    Flags := DEBUG_KILL_ON_CLOSE
  else
    Flags := 0;

  Result.Location := 'NtCreateDebugObject';
  Result.Status := NtCreateDebugObject(
    hDebugObj,
    AccessMaskOverride(DEBUG_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    Flags
  );

  if Result.IsSuccess then
    hxDebugObj := TAutoHandle.Capture(hDebugObj);
end;

function NtxOpenDebugObjectProcess;
var
  hDebugObj: THandle;
begin
  Result := NtxProcess.Query(hProcess, ProcessDebugObjectHandle, hDebugObj);

  if Result.IsSuccess then
    hxDebugObj := TAutoHandle.Capture(hDebugObj);
end;

function NtxSetDebugKillOnExit;
begin
  Result.Location := 'NtSetInformationDebugObject';
  Result.LastCall.AttachInfoClass(DebugObjectKillProcessOnExitInformation);
  Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_SET_INFORMATION);

  Result.Status := NtSetInformationDebugObject(hDebugObject,
    DebugObjectKillProcessOnExitInformation, @KillOnExit, SizeOf(KillOnExit),
    nil);
end;

function NtxQueryDebugInherit;
begin
  Result := NtxProcess.Query(hProcess, ProcessDebugFlags, InheritDebugging);
end;

function NtxSetDebugInherit;
begin
  Result := NtxProcess.&Set(hProcess, ProcessDebugFlags, InheritDebugging);
end;

function NtxDebugProcess;
begin
  Result.Location := 'NtDebugActiveProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);
  Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_PROCESS_ASSIGN);
  Result.Status := NtDebugActiveProcess(hProcess, hDebugObject);
end;

function NtxDebugProcessStop;
begin
  Result.Location := 'NtRemoveProcessDebug';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);
  Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_PROCESS_ASSIGN);
  Result.Status := NtRemoveProcessDebug(hProcess, hDebugObject);
end;

function NtxDebugWait;
begin
  Result.Location := 'NtWaitForDebugEvent';
  Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_READ_EVENT);

  Result.Status := NtWaitForDebugEvent(hDebugObj, Alertable,
    TimeoutToLargeInteger(Timeout), WaitStateChange);

  // Capture opened handles to prevent resource leaks
  if Result.IsSuccess and (Result.Status <> STATUS_TIMEOUT) then
    with WaitStateChange do
      case NewState of

        // A handles to a thread was opened
        DbgCreateThreadStateChange:
          Handles.hxThread := TAutoHandle.Capture(CreateThread.HandleToThread);

        // A handle to a dll file was opened
        DbgLoadDllStateChange:
          Handles.hxThread := TAutoHandle.Capture(LoadDll.FileHandle);

        // 3 new handles were opened: a process, a thread, and an image file
        DbgCreateProcessStateChange:
          begin
            Handles.hxProcess := TAutoHandle.Capture(
              CreateProcessInfo.HandleToProcess);

            Handles.hxThread := TAutoHandle.Capture(
              CreateProcessInfo.HandleToThread);

            Handles.hxFile := TAutoHandle.Capture(
              CreateProcessInfo.NewProcess.FileHandle);
          end;
      end;
end;

function NtxDebugContinue;
begin
  Result.Location := 'NtDebugContinue';
  Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_READ_EVENT);
  Result.Status := NtDebugContinue(hDebugObject, ClientId, Status);
end;

function NtxSetTrapFlagThread;
var
  Context: IContext;
begin
  // We are going to change the thread's context, so make sure it is suspended
  if not AlreadySuspended then
  begin
    Result := NtxSuspendThread(hxThread.Handle);

    if not Result.IsSuccess then
      Exit;

    // Resume later
    NtxDelayedResumeThread(hxThread);
  end;

  // Get thread's control registers
  Result := NtxGetContextThread(hxThread.Handle, CONTEXT_CONTROL, Context);

  if not Result.IsSuccess then
    Exit;

  if Enabled then
  begin
    // Skip if already enabled
    if BitTest(Context.Data.EFlags and EFLAGS_TF) then
      Exit;

    Context.Data.EFlags := Context.Data.EFlags or EFLAGS_TF;
  end
  else
  begin
    // Skip if already cleared
    if not BitTest(Context.Data.EFlags and EFLAGS_TF) then
      Exit;

    Context.Data.EFlags := Context.Data.EFlags and not EFLAGS_TF;
  end;

  // Apply the changes
  Result := NtxSetContextThread(hxThread.Handle, Context.Data^);
end;

function DbgxIssueThreadBreakin;
begin
  // Enable single stepping for the thread. The system will clear this flag and
  // notify the debugger on the next instruction executed by the target thread.
  Result := NtxSetTrapFlagThread(hxThread, True);
end;

function DbgxIssueProcessBreakin;
begin
  Result.Location := 'DbgUiIssueRemoteBreakin';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_THREAD);
  Result.Status := DbgUiIssueRemoteBreakin(hProcess);
end;

end.
