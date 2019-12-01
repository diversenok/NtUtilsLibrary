unit NtUtils.Debug;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntdbg,
  NtUtils.Exceptions, NtUtils.Objects;

type
  TDbgxHandles = record
    hxThread, hxProcess, hxFile: IHandle;
  end;

// Create a debug object
function NtxCreateDebugObject(out hxDebugObj: IHandle; KillOnClose: Boolean;
  Attributes: Cardinal = 0): TNtxStatus;

// Set whether the debugged process should be ternimated
// when the last handle to its debug port is closed
function NtxSetDebugKillOnExit(hDebugObject: THandle; KillOnExit: LongBool)
  : TNtxStatus;

// Assign a debug object to a process
function NtxDebugProcess(hProcess: THandle; hDebugObject: THandle): TNtxStatus;

// Remove a debug object from a process
function NtxDebugProcessStop(hProcess: THandle; hDebugObject: THandle)
  : TNtxStatus;

// Wait for a debug event
function NtxDebugWait(hDebugObj: THandle; out WaitStateChange:
  TDbgUiWaitStateChange; out Handles: TDbgxHandles; Timeout: Int64 =
  NT_INFINITE; Alertable: Boolean = False): TNtxStatus;

// Continue after a debug event
function NtxDebugContinue(hDebugObject: THandle; const ClientId: TClientId;
  Status: NTSTATUS = DBG_CONTINUE): TNtxStatus;

// Enable signle-step flag for a thread
// NOTE: make sure the thread is suspended before calling this function
function NtxSetTrapFlagThread(hThread: THandle; Enabled: Boolean;
  AlreadySuspended: Boolean = False): TNtxStatus;

// Perform a single step of a thread to start debugging it
function DbgxIssueThreadBreakin(hThread: THandle): TNtxStatus;

// Create a thread with a breakpoint inside a process
function DbgxIssueProcessBreakin(hProcess: THandle): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, NtUtils.Threads;

function NtxCreateDebugObject(out hxDebugObj: IHandle; KillOnClose: Boolean;
  Attributes: Cardinal): TNtxStatus;
var
  hDebugObj: THandle;
  ObjAttr: TObjectAttributes;
  Flags: Cardinal;
begin
  InitializeObjectAttributes(ObjAttr, nil, Attributes);

  if KillOnClose then
    Flags := DEBUG_KILL_ON_CLOSE
  else
    Flags := 0;

  Result.Location := 'NtCreateDebugObject';
  Result.Status := NtCreateDebugObject(hDebugObj, DEBUG_ALL_ACCESS, ObjAttr,
    Flags);

  if Result.IsSuccess then
    hxDebugObj := TAutoHandle.Capture(hDebugObj);
end;

function NtxSetDebugKillOnExit(hDebugObject: THandle; KillOnExit: LongBool)
  : TNtxStatus;
begin
  Result.Location := 'NtSetInformationDebugObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(DebugObjectKillProcessOnExitInformation);
  Result.LastCall.InfoClassType := TypeInfo(TDebugObjectInfoClass);
  Result.LastCall.Expects(DEBUG_SET_INFORMATION, @DebugObjAccessType);

  Result.Status := NtSetInformationDebugObject(hDebugObject,
    DebugObjectKillProcessOnExitInformation, @KillOnExit, SizeOf(KillOnExit),
    nil);
end;

function NtxDebugProcess(hProcess: THandle; hDebugObject: THandle): TNtxStatus;
begin
  Result.Location := 'NtDebugActiveProcess';
  Result.LastCall.Expects(PROCESS_SUSPEND_RESUME, @ProcessAccessType);
  Result.LastCall.Expects(DEBUG_PROCESS_ASSIGN, @DebugObjAccessType);
  Result.Status := NtDebugActiveProcess(hProcess, hDebugObject);
end;

function NtxDebugProcessStop(hProcess: THandle; hDebugObject: THandle)
  : TNtxStatus;
begin
  Result.Location := 'NtRemoveProcessDebug';
  Result.LastCall.Expects(PROCESS_SUSPEND_RESUME, @ProcessAccessType);
  Result.LastCall.Expects(DEBUG_PROCESS_ASSIGN, @DebugObjAccessType);
  Result.Status := NtRemoveProcessDebug(hProcess, hDebugObject);
end;

function NtxDebugWait(hDebugObj: THandle; out WaitStateChange:
  TDbgUiWaitStateChange; out Handles: TDbgxHandles; Timeout: Int64;
  Alertable: Boolean): TNtxStatus;
begin
  Result.Location := 'NtWaitForDebugEvent';
  Result.LastCall.Expects(DEBUG_READ_EVENT, @DebugObjAccessType);

  Result.Status := NtWaitForDebugEvent(hDebugObj, Alertable,
    Int64ToLargeInteger(Timeout), WaitStateChange);

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

function NtxDebugContinue(hDebugObject: THandle; const ClientId: TClientId;
  Status: NTSTATUS): TNtxStatus;
begin
  Result.Location := 'NtDebugContinue';
  Result.LastCall.Expects(DEBUG_READ_EVENT, @DebugObjAccessType);
  Result.Status := NtDebugContinue(hDebugObject, ClientId, Status);
end;

function NtxSetTrapFlagThread(hThread: THandle; Enabled: Boolean;
  AlreadySuspended: Boolean): TNtxStatus;
var
  Context: PContext;
label
  Cleanup;
begin
  // We are going to change the thread's context, so make sure it is suspended
  if not AlreadySuspended then
  begin
    Result := NtxSuspendThread(hThread);

    if not Result.IsSuccess then
      Exit;
  end;

  // Get thread's control registers
  Result := NtxGetContextThread(hThread, CONTEXT_CONTROL, Context);

  if not Result.IsSuccess then
    Exit;

  if Enabled then
  begin
    // Skip if already enabled
    if Context.EFlags and EFLAGS_TF <> 0 then
      goto Cleanup;

    Context.EFlags := Context.EFlags or EFLAGS_TF;
  end
  else
  begin
    // Skip if already cleared
    if Context.EFlags and EFLAGS_TF = 0 then
      goto Cleanup;

    Context.EFlags := Context.EFlags and not EFLAGS_TF;
  end;

  // Apply the changes
  Result := NtxSetContextThread(hThread, Context);

Cleanup:
  FreeMem(Context);

  // Resume it back
  if not AlreadySuspended then
    NtxResumeThread(hThread);
end;

function DbgxIssueThreadBreakin(hThread: THandle): TNtxStatus;
begin
  // Enable single stepping for the thread. The system will clear this flag and
  // notify the debugger on the next instruction executed by the target thread.
  Result := NtxSetTrapFlagThread(hThread, True);
end;

function DbgxIssueProcessBreakin(hProcess: THandle): TNtxStatus;
begin
  Result.Location := 'DbgUiIssueRemoteBreakin';
  Result.LastCall.Expects(PROCESS_CREATE_THREAD, @ProcessAccessType);
  Result.Status := DbgUiIssueRemoteBreakin(hProcess);
end;

end.
