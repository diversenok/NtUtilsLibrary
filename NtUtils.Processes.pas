unit NtUtils.Processes;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, NtUtils, NtUtils.Objects;

const
  // Ntapi.ntpsapi
  NtCurrentProcess: THandle = THandle(-1);

type
  TProcessHandleEntry = Ntapi.ntpsapi.TProcessHandleTableEntryInfo;

// Open a process (always succeeds for the current PID)
function NtxOpenProcess(out hxProcess: IHandle; PID: TProcessId;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Reopen a handle to the current process with the specific access
function NtxOpenCurrentProcess(out hxProcess: IHandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Suspend/resume a process
function NtxSuspendProcess(hProcess: THandle): TNtxStatus;
function NtxResumeProcess(hProcess: THandle): TNtxStatus;

// Terminate a process
function NtxTerminateProcess(hProcess: THandle; ExitCode: NTSTATUS): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi;

function NtxOpenProcess(out hxProcess: IHandle; PID: TProcessId;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;
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
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal): TNtxStatus;
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
  Result.Location := 'NtResumeProcesNtTerminateProcesss';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_TERMINATE);
  Result.Status := NtTerminateProcess(hProcess, ExitCode);
end;

end.
