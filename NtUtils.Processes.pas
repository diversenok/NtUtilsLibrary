unit NtUtils.Processes;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, NtUtils, NtUtils.Objects;

const
  // Ntapi.ntpsapi
  NtCurrentProcess = THandle(-1);

type
  TProcessHandleEntry = Ntapi.ntpsapi.TProcessHandleTableEntryInfo;

// Get a pseudo-handle to the current process
function NtxCurrentProcess: IHandle;

// Open a process (always succeeds for the current PID)
function NtxOpenProcess(out hxProcess: IHandle; PID: TProcessId;
  DesiredAccess: TAccessMask; HandleAttributes: TObjectAttributesFlags = 0):
  TNtxStatus;

// Reopen a handle to the current process with the specific access
function NtxOpenCurrentProcess(out hxProcess: IHandle;
  DesiredAccess: TAccessMask; HandleAttributes: TObjectAttributesFlags = 0):
  TNtxStatus;

// Suspend/resume/terminate a process
function NtxSuspendProcess(hProcess: THandle): TNtxStatus;
function NtxResumeProcess(hProcess: THandle): TNtxStatus;
function NtxTerminateProcess(hProcess: THandle; ExitCode: NTSTATUS): TNtxStatus;

// Resume/terminate a process when the object goes out of scope
function NtxDelayedResumeProcess(hxProcess: IHandle): IAutoReleasable;
function NtxDelayedTerminateProcess(hxProcess: IHandle; ExitCode: NTSTATUS):
  IAutoReleasable;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi;

var
  NtxpCurrentProcess: IHandle;

function NtxCurrentProcess: IHandle;
begin
  if not Assigned(NtxpCurrentProcess) then
  begin
    NtxpCurrentProcess := TAutoHandle.Capture(NtCurrentProcess);
    NtxpCurrentProcess.AutoRelease := False;
  end;

  Result := NtxpCurrentProcess;
end;

function NtxOpenProcess(out hxProcess: IHandle; PID: TProcessId;
  DesiredAccess: TAccessMask; HandleAttributes: TObjectAttributesFlags = 0):
  TNtxStatus;
var
  hProcess: THandle;
  ClientId: TClientId;
  ObjAttr: TObjectAttributes;
begin
  if PID = NtCurrentProcessId then
  begin
    hxProcess := TAutoHandle.Capture(NtCurrentProcess);
    hxProcess.AutoRelease := False;
    Result.Status := STATUS_SUCCESS;
  end
  else
  begin
    InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);
    ClientId.Create(PID, 0);

    Result.Location := 'NtOpenProcess';
    Result.LastCall.AttachAccess<TProcessAccessMask>(DesiredAccess);

    Result.Status := NtOpenProcess(hProcess, DesiredAccess, ObjAttr, ClientId);

    if Result.IsSuccess then
      hxProcess := TAutoHandle.Capture(hProcess);
  end;
end;

function NtxOpenCurrentProcess(out hxProcess: IHandle;
  DesiredAccess: TAccessMask; HandleAttributes: TObjectAttributesFlags):
  TNtxStatus;
var
  hProcess: THandle;
  Flags: Cardinal;
begin
  // Duplicating the pseudo-handle is more reliable then opening process by PID

  if DesiredAccess and MAXIMUM_ALLOWED <> 0 then
  begin
    Flags := DUPLICATE_SAME_ACCESS;
    DesiredAccess := 0;
  end
  else
    Flags := 0;

  Result.Location := 'NtDuplicateObject';
  Result.Status := NtDuplicateObject(NtCurrentProcess, NtCurrentProcess,
    NtCurrentProcess, hProcess, DesiredAccess, HandleAttributes, Flags);

  if Result.IsSuccess then
    hxProcess := TAutoHandle.Capture(hProcess);
end;

function NtxSuspendProcess(hProcess: THandle): TNtxStatus;
begin
  Result.Location := 'NtSuspendProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);
  Result.Status := NtSuspendProcess(hProcess);
end;

function NtxResumeProcess(hProcess: THandle): TNtxStatus;
begin
  Result.Location := 'NtResumeProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_SUSPEND_RESUME);
  Result.Status := NtResumeProcess(hProcess);
end;

function NtxTerminateProcess(hProcess: THandle; ExitCode: NTSTATUS): TNtxStatus;
begin
  Result.Location := 'NtTerminateProcesss';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_TERMINATE);
  Result.Status := NtTerminateProcess(hProcess, ExitCode);
end;

function NtxDelayedResumeProcess(hxProcess: IHandle): IAutoReleasable;
begin
  Result := TDelayedOperation.Create(
    procedure
    begin
      NtxResumeProcess(hxProcess.Handle);
    end
  );
end;

function NtxDelayedTerminateProcess(hxProcess: IHandle; ExitCode: NTSTATUS):
  IAutoReleasable;
begin
  Result := TDelayedOperation.Create(
    procedure
    begin
      NtxTerminateProcess(hxProcess.Handle, ExitCode);
    end
  );
end;

end.
