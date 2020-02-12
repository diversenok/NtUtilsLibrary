unit NtUtils.Processes;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, NtUtils.Exceptions, NtUtils.Objects;

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

// Query variable-size information
function NtxQueryProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  out xMemory: IMemory): TNtxStatus;

// Set variable-size information
function NtxSetProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  Data: Pointer; DataSize: Cardinal): TNtxStatus;

type
  NtxProcess = class
    // Query fixed-size information
    class function Query<T>(hProcess: THandle;
      InfoClass: TProcessInfoClass; out Buffer: T): TNtxStatus; static;

    // Set fixed-size information
    class function SetInfo<T>(hProcess: THandle;
      InfoClass: TProcessInfoClass; const Buffer: T): TNtxStatus; static;
  end;

// Query a string
function NtxQueryStringProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  out Str: String): TNtxStatus;

// Try to query image name in Win32 format
function NtxTryQueryImageProcessById(PID: NativeUInt): String;

// Suspend/resume a process
function NtxSuspendProcess(hProcess: THandle): TNtxStatus;
function NtxResumeProcess(hProcess: THandle): TNtxStatus;

// Terminate a process
function NtxTerminateProcess(hProcess: THandle; ExitCode: NTSTATUS): TNtxStatus;

{$IFDEF Win32}
// Fail if the current process is running under WoW64
// NOTE: you don't run under WoW64 if you are compiled as Win64
function RtlxAssertNotWoW64(out Status: TNtxStatus): Boolean;
{$ENDIF}

// Query if a process runs under WoW64
function NtxQueryIsWoW64Process(hProcess: THandle; out WoW64: Boolean):
  TNtxStatus;

// Check if the target if WoW64. Fail, if it isn't while we are.
function RtlxAssertWoW64Compatible(hProcess: THandle;
  out TargetIsWoW64: Boolean): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, Ntapi.ntseapi, Ntapi.ntpebteb,
  NtUtils.Access.Expected;

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
    Result.LastCall.CallType := lcOpenCall;
    Result.LastCall.AccessMask := DesiredAccess;
    Result.LastCall.AccessMaskType := @ProcessAccessType;

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

function NtxQueryProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  out xMemory: IMemory): TNtxStatus;
var
  Buffer: Pointer;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationProcess';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TProcessInfoClass);
  RtlxComputeProcessQueryAccess(Result.LastCall, InfoClass);

  BufferSize := 0;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryInformationProcess(hProcess, InfoClass, Buffer,
      BufferSize, @Required);

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, Required);

  if Result.IsSuccess then
    xMemory := TAutoMemory.Capture(Buffer, BufferSize);
end;

function NtxSetProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  Data: Pointer; DataSize: Cardinal): TNtxStatus;
begin
  Result.Location := 'NtSetInformationProcess';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TProcessInfoClass);
  RtlxComputeProcessSetAccess(Result.LastCall, InfoClass);

  Result.Status := NtSetInformationProcess(hProcess, InfoClass, Data, DataSize);
end;

class function NtxProcess.Query<T>(hProcess: THandle;
  InfoClass: TProcessInfoClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationProcess';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TProcessInfoClass);
  RtlxComputeProcessQueryAccess(Result.LastCall, InfoClass);

  Result.Status := NtQueryInformationProcess(hProcess, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxProcess.SetInfo<T>(hProcess: THandle;
  InfoClass: TProcessInfoClass; const Buffer: T): TNtxStatus;
begin
  Result := NtxSetProcess(hProcess, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxQueryStringProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  out Str: String): TNtxStatus;
var
  xMemory: IMemory;
begin
  case InfoClass of
    ProcessImageFileName, ProcessImageFileNameWin32,
    ProcessCommandLineInformation:
    begin
      Result := NtxQueryProcess(hProcess, InfoClass, xMemory);

      if Result.IsSuccess then
        Str := PUNICODE_STRING(xMemory.Address).ToString;
    end;
  else
    Result.Location := 'NtxQueryStringProcess';
    Result.Status := STATUS_INVALID_INFO_CLASS;
    Exit;
  end;
end;

function NtxTryQueryImageProcessById(PID: NativeUInt): String;
var
  hxProcess: IHandle;
begin
  Result := '';

  if not NtxOpenProcess(hxProcess, PID, PROCESS_QUERY_LIMITED_INFORMATION
    ).IsSuccess then
    Exit;

  NtxQueryStringProcess(hxProcess.Handle, ProcessImageFileNameWin32, Result);
end;

function NtxSuspendProcess(hProcess: THandle): TNtxStatus;
begin
  Result.Location := 'NtSuspendProcess';
  Result.LastCall.Expects(PROCESS_SUSPEND_RESUME, @ProcessAccessType);
  Result.Status := NtSuspendProcess(hProcess);
end;

function NtxResumeProcess(hProcess: THandle): TNtxStatus;
begin
  Result.Location := 'NtResumeProcess';
  Result.LastCall.Expects(PROCESS_SUSPEND_RESUME, @ProcessAccessType);
  Result.Status := NtResumeProcess(hProcess);
end;

function NtxTerminateProcess(hProcess: THandle; ExitCode: NTSTATUS): TNtxStatus;
begin
  Result.Location := 'NtResumeProcesNtTerminateProcesss';
  Result.LastCall.Expects(PROCESS_TERMINATE, @ProcessAccessType);
  Result.Status := NtTerminateProcess(hProcess, ExitCode);
end;

{$IFDEF Win32}
function RtlxAssertNotWoW64(out Status: TNtxStatus): Boolean;
begin
  Result := RtlIsWoW64;

  if Result then
  begin
    Status.Location := '[WoW64 check]';
    Status.Status := STATUS_ASSERTION_FAILURE;
  end;
end;
{$ENDIF}

function NtxQueryIsWoW64Process(hProcess: THandle; out WoW64: Boolean):
  TNtxStatus;
var
  WoW64Peb: Pointer;
begin
  Result := NtxProcess.Query(hProcess, ProcessWow64Information, WoW64Peb);

  if Result.IsSuccess then
    WoW64 := Assigned(WoW64Peb);
end;

function RtlxAssertWoW64Compatible(hProcess: THandle;
  out TargetIsWoW64: Boolean): TNtxStatus;
begin
  // Check if the target is a WoW64 process
  Result := NtxQueryIsWoW64Process(hProcess, TargetIsWoW64);

{$IFDEF Win32}
  // Prevent WoW64 -> Native access scenarious
  if Result.IsSuccess and not TargetIsWoW64  then
      RtlxAssertNotWoW64(Result);
{$ENDIF}
end;

end.
