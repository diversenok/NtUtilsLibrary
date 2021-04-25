unit NtUtils.Processes;

{
  This module provides access to basic operations on processes via Native API.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, NtUtils, NtUtils.Objects;

const
  // Ntapi.ntpsapi
  NtCurrentProcess = THandle(-1);

  // For suspend/resume via state change
  PROCESS_CHANGE_STATE = PROCESS_SET_INFORMATION or PROCESS_SUSPEND_RESUME;

// Get a pseudo-handle to the current process
function NtxCurrentProcess: IHandle;

// Open a process (always succeeds for the current PID)
function NtxOpenProcess(
  out hxProcess: IHandle;
  PID: TProcessId;
  DesiredAccess: TProcessAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Reopen a handle to the current process with the specific access
function NtxOpenCurrentProcess(
  out hxProcess: IHandle;
  DesiredAccess: TProcessAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Iterate through accessible processes on the system
function NtxGetNextProcess(
  [opt] var hxProcess: IHandle; // use nil to start
  DesiredAccess: TProcessAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  ReverseOrder: Boolean = False
): TNtxStatus;

// Suspend/resume/terminate a process
function NtxSuspendProcess(hProcess: THandle): TNtxStatus;
function NtxResumeProcess(hProcess: THandle): TNtxStatus;
function NtxTerminateProcess(hProcess: THandle; ExitCode: NTSTATUS): TNtxStatus;

// Resume a process when the object goes out of scope
function NtxDelayedResumeProcess(
  const hxProcess: IHandle
): IAutoReleasable;

// Terminate a process when the object goes out of scope
function NtxDelayedTerminateProcess(
  const hxProcess: IHandle;
  ExitCode: NTSTATUS
): IAutoReleasable;

// Create a process state change object (requires Windows Insider)
function NtxCreateProcessState(
  out hxProcessState: IHandle;
  hProcess: THandle;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Suspend or resume a process via state change (requires Windows Insider)
function NtxChageStateProcess(
  hProcessState: THandle;
  hProcess: THandle;
  Action: TProcessStateChangeType
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, NtUtils.Ldr;

var
  NtxpCurrentProcess: IHandle;

function NtxCurrentProcess;
begin
  if not Assigned(NtxpCurrentProcess) then
  begin
    NtxpCurrentProcess := TAutoHandle.Capture(NtCurrentProcess);
    NtxpCurrentProcess.AutoRelease := False;
  end;

  Result := NtxpCurrentProcess;
end;

function NtxOpenProcess;
var
  hProcess: THandle;
  ClientId: TClientId;
  ObjAttr: TObjectAttributes;
begin
  if PID = NtCurrentProcessId then
  begin
    hxProcess := NtxCurrentProcess;
    Result.Status := STATUS_SUCCESS;
  end
  else
  begin
    InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);
    ClientId.Create(PID, 0);

    Result.Location := 'NtOpenProcess';
    Result.LastCall.AttachAccess(DesiredAccess);

    Result.Status := NtOpenProcess(hProcess, DesiredAccess, ObjAttr, ClientId);

    if Result.IsSuccess then
      hxProcess := TAutoHandle.Capture(hProcess);
  end;
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
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.Status := NtDuplicateObject(NtCurrentProcess, NtCurrentProcess,
    NtCurrentProcess, hProcess, DesiredAccess, HandleAttributes, Flags);

  if Result.IsSuccess then
    hxProcess := TAutoHandle.Capture(hProcess);
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
  Result.LastCall.AttachAccess(DesiredAccess);

  Result.Status := NtGetNextProcess(hProcess, DesiredAccess, HandleAttributes,
    FLAGS[ReverseOrder <> False], hNewProcess);

  if Result.IsSuccess then
    hxProcess := TAutoHandle.Capture(hNewProcess);
end;

function NtxSuspendProcess;
begin
  Result.Location := 'NtSuspendProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);
  Result.Status := NtSuspendProcess(hProcess);
end;

function NtxResumeProcess;
begin
  Result.Location := 'NtResumeProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);
  Result.Status := NtResumeProcess(hProcess);
end;

function NtxTerminateProcess;
begin
  Result.Location := 'NtTerminateProcesss';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_TERMINATE);
  Result.Status := NtTerminateProcess(hProcess, ExitCode);
end;

function NtxDelayedResumeProcess;
begin
  Result := TDelayedOperation.Delay(
    procedure
    begin
      NtxResumeProcess(hxProcess.Handle);
    end
  );
end;

function NtxDelayedTerminateProcess;
begin
  Result := TDelayedOperation.Delay(
    procedure
    begin
      NtxTerminateProcess(hxProcess.Handle, ExitCode);
    end
  );
end;

function NtxCreateProcessState;
var
  hProcessState: THandle;
begin
  Result := LdrxCheckNtDelayedImport('NtCreateProcessStateChange');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateProcessStateChange';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SET_INFORMATION);

  Result.Status := NtCreateProcessStateChange(
    hProcessState,
    AccessMaskOverride(PROCESS_STATE_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    hProcess,
    0
  );

  if Result.IsSuccess then
    hxProcessState := TAutoHandle.Capture(hProcessState);
end;

function NtxChageStateProcess;
begin
  Result := LdrxCheckNtDelayedImport('NtChangeProcessState');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtChangeProcessState';
  Result.LastCall.AttachInfoClass(Action);
  Result.LastCall.Expects<TProcessStateAccessMask>(PROCESS_STATE_CHANGE_STATE);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);

  Result.Status := NtChangeProcessState(hProcessState, hProcess, Action, nil,
    0, nil);
end;

end.
