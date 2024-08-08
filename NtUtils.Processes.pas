unit NtUtils.Processes;

{
  This module provides access to basic operations on processes via Native API.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntseapi, Ntapi.Versions,
  NtUtils, NtUtils.Objects;

const
  // For suspend/resume via state change
  PROCESS_CHANGE_STATE = PROCESS_SET_INFORMATION or PROCESS_SUSPEND_RESUME;

// Open a process (always succeeds for the current PID)
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenProcess(
  out hxProcess: IHandle;
  PID: TProcessId;
  DesiredAccess: TProcessAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Reopen a handle to the current process with the specific access
function NtxOpenCurrentProcess(
  out hxProcess: IHandle;
  DesiredAccess: TProcessAccessMask = MAXIMUM_ALLOWED;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Open the next accessible process on the system
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxGetNextProcess(
  [opt, Access(0)] var hxProcess: IHandle; // use nil to start
  DesiredAccess: TProcessAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  ReverseOrder: Boolean = False
): TNtxStatus;

// Make a for-in iterator for enumerating process via NtGetNextProcess.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function NtxIterateGetNextProcess(
  [out, opt] Status: PNtxStatus;
  DesiredAccess: TProcessAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  ReverseOrder: Boolean = False
): IEnumerable<IHandle>;

// Suspend all threads in a process
function NtxSuspendProcess(
  [Access(PROCESS_SUSPEND_RESUME)] const hxProcess: IHandle
): TNtxStatus;

// Resume all threads in a process
function NtxResumeProcess(
  [Access(PROCESS_SUSPEND_RESUME)] const hxProcess: IHandle
): TNtxStatus;

// Terminate a process
function NtxTerminateProcess(
  [opt, Access(PROCESS_TERMINATE)] const hxProcess: IHandle;
  ExitCode: NTSTATUS
): TNtxStatus;

// Resume a process when the object goes out of scope
function NtxDelayedResumeProcess(
  [Access(PROCESS_SUSPEND_RESUME)] const hxProcess: IHandle
): IAutoReleasable;

// Terminate a process when the object goes out of scope
function NtxDelayedTerminateProcess(
  [Access(PROCESS_SUSPEND_RESUME)] const hxProcess: IHandle;
  ExitCode: NTSTATUS
): IAutoReleasable;

// Create a process state change object
[MinOSVersion(OsWin11)]
function NtxCreateProcessState(
  out hxProcessState: IHandle;
  [Access(PROCESS_CHANGE_STATE)] const hxProcess: IHandle;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Suspend or resume a process via state change
[MinOSVersion(OsWin11)]
function NtxChangeStateProcess(
  [Access(PROCESS_STATE_CHANGE_STATE)] const hxProcessState: IHandle;
  [Access(PROCESS_CHANGE_STATE)] const hxProcess: IHandle;
  Action: TProcessStateChangeType
): TNtxStatus;

// Suspend a process using the best method and resume it automatically later
function NtxSuspendProcessAuto(
  [Access(PROCESS_CHANGE_STATE)] const hxProcess: IHandle;
  out Reverter: IAutoReleasable
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, NtUtils.Ldr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxOpenProcess;
var
  hProcess: THandle;
  ClientId: TClientId;
  ObjAttr: TObjectAttributes;
begin
  if (PID = NtCurrentProcessId) and
    not BitTest(DesiredAccess and ACCESS_SYSTEM_SECURITY) then
  begin
    hxProcess := NtxCurrentProcess;
    Exit(NtxSuccess);
  end;

  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);
  ClientId.Create(PID, 0);

  Result.Location := 'NtOpenProcess';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtOpenProcess(hProcess, DesiredAccess, ObjAttr, ClientId);

  if Result.IsSuccess then
    hxProcess := Auto.CaptureHandle(hProcess);
end;

function NtxOpenCurrentProcess;
var
  hProcess: THandle;
  Flags: TDuplicateOptions;
begin
  // Duplicating the pseudo-handle is more reliable then opening process by PID

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
  Result.Status := NtDuplicateObject(NtCurrentProcess, NtCurrentProcess,
    NtCurrentProcess, hProcess, DesiredAccess, HandleAttributes, Flags);

  if Result.IsSuccess then
    hxProcess := Auto.CaptureHandle(hProcess);
end;

function NtxGetNextProcess;
const
  FLAGS: array [Boolean] of TProcessNextFlags = (0, PROCESS_NEXT_REVERSE_ORDER);
var
  hProcess, hNewProcess: THandle;
begin
  if Assigned(hxProcess) then
    hProcess := hxProcess.Handle
  else
    hProcess := 0;

  Result.Location := 'NtGetNextProcess';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtGetNextProcess(hProcess, DesiredAccess, HandleAttributes,
    FLAGS[ReverseOrder <> False], hNewProcess);

  if Result.IsSuccess then
    hxProcess := Auto.CaptureHandle(hNewProcess);
end;

function NtxIterateGetNextProcess;
var
  hxProcess: IHandle;
begin
  hxProcess := nil;

  Result := NtxAuto.Iterate<IHandle>(Status,
    function (out Current: IHandle): TNtxStatus
    begin
      // Advance to the next process handle
      Result := NtxGetNextProcess(hxProcess, DesiredAccess, HandleAttributes,
        ReverseOrder);

      if not Result.IsSuccess then
        Exit;

      Current := hxProcess;
    end
  );
end;

function NtxSuspendProcess;
begin
  Result.Location := 'NtSuspendProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);
  Result.Status := NtSuspendProcess(HandleOrDefault(hxProcess));
end;

function NtxResumeProcess;
begin
  Result.Location := 'NtResumeProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);
  Result.Status := NtResumeProcess(HandleOrDefault(hxProcess));
end;

function NtxTerminateProcess;
begin
  Result.Location := 'NtTerminateProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_TERMINATE);
  Result.Status := NtTerminateProcess(HandleOrDefault(hxProcess), ExitCode);
end;

function NtxDelayedResumeProcess;
begin
  Result := Auto.Delay(
    procedure
    begin
      NtxResumeProcess(hxProcess);
    end
  );
end;

function NtxDelayedTerminateProcess;
begin
  Result := Auto.Delay(
    procedure
    begin
      NtxTerminateProcess(hxProcess, ExitCode);
    end
  );
end;

function NtxCreateProcessState;
var
  ObjAttr: PObjectAttributes;
  hProcessState: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtCreateProcessStateChange);

  if not Result.IsSuccess then
    Exit;

  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateProcessStateChange';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SET_INFORMATION);

  Result.Status := NtCreateProcessStateChange(
    hProcessState,
    AccessMaskOverride(PROCESS_STATE_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    HandleOrDefault(hxProcess),
    0
  );

  if Result.IsSuccess then
    hxProcessState := Auto.CaptureHandle(hProcessState);
end;

function NtxChangeStateProcess;
begin
  Result := LdrxCheckDelayedImport(delayed_NtChangeProcessState);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtChangeProcessState';
  Result.LastCall.UsesInfoClass(Action, icPerform);
  Result.LastCall.Expects<TProcessStateAccessMask>(PROCESS_STATE_CHANGE_STATE);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);

  Result.Status := NtChangeProcessState(HandleOrDefault(hxProcessState),
    HandleOrDefault(hxProcess), Action, nil, 0, 0);
end;

function NtxSuspendProcessAuto;
var
  hxProcessState: IHandle;
begin
  // Try state change-based suspension first
  Result := NtxCreateProcessState(hxProcessState, hxProcess);

  if Result.IsSuccess then
  begin
    Result := NtxChangeStateProcess(hxProcessState, hxProcess,
      ProcessStateChangeSuspend);

    if Result.IsSuccess then
    begin
      // Releasing the state change handle will resume the process
      Reverter := hxProcessState;
      Exit;
    end;
  end;

  // Fall back to classic suspension
  Result := NtxSuspendProcess(hxProcess);

  if Result.IsSuccess then
    Reverter := NtxDelayedResumeProcess(hxProcess);
end;

end.
