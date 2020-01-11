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
function NtxOpenProcess(out hxProcess: IHandle; PID: NativeUInt;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Reopen a handle to the current process with the specific access
function NtxOpenCurrentProcess(out hxProcess: IHandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Query variable-size information
function NtxQueryProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  out Status: TNtxStatus): Pointer;

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

// Enumerate handles of a process
function NtxEnumerateHandlesProcess(hProcess: THandle; out Handles:
  TArray<TProcessHandleEntry>): TNtxStatus;

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

// Fail if the current process is running under WoW64
function NtxAssertNotWoW64: TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, Ntapi.ntseapi, Ntapi.ntpebteb,
  NtUtils.Access.Expected;

function NtxOpenProcess(out hxProcess: IHandle; PID: NativeUInt;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;
var
  hProcess: THandle;
  ClientId: TClientId;
  ObjAttr: TObjectAttributes;
begin
  if PID = NtCurrentProcessId then
  begin
    hxProcess := TAutoHandle.Capture(NtCurrentProcess);
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
  out Status: TNtxStatus): Pointer;
var
  BufferSize, Required: Cardinal;
begin
  Status.Location := 'NtQueryInformationProcess';
  Status.LastCall.CallType := lcQuerySetCall;
  Status.LastCall.InfoClass := Cardinal(InfoClass);
  Status.LastCall.InfoClassType := TypeInfo(TProcessInfoClass);
  RtlxComputeProcessQueryAccess(Status.LastCall, InfoClass);

  BufferSize := 0;
  repeat
    Result := AllocMem(BufferSize);

    Required := 0;
    Status.Status := NtQueryInformationProcess(hProcess, InfoClass, Result,
      BufferSize, @Required);

    if not Status.IsSuccess then
    begin
      FreeMem(Result);
      Result := nil;
    end;
  until not NtxExpandBuffer(Status, BufferSize, Required);
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

function NtxEnumerateHandlesProcess(hProcess: THandle; out Handles:
  TArray<TProcessHandleEntry>): TNtxStatus;
var
  Buffer: PProcessHandleSnapshotInformation;
  i: Integer;
begin
  Buffer := NtxQueryProcess(hProcess, ProcessHandleInformation, Result);

  if Result.IsSuccess then
  begin
    SetLength(Handles, Buffer.NumberOfHandles);

    for i := 0 to High(Handles) do
      Handles[i] := Buffer.Handles{$R-}[i]{$R+};

    FreeMem(Buffer);
  end;
end;

function NtxQueryStringProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  out Str: String): TNtxStatus;
var
  Buffer: PUNICODE_STRING;
begin
  case InfoClass of
    ProcessImageFileName, ProcessImageFileNameWin32,
    ProcessCommandLineInformation:
    begin
      Buffer := NtxQueryProcess(hProcess, InfoClass, Result);

      if Result.IsSuccess then
      begin
        Str := Buffer.ToString;
        FreeMem(Buffer);
      end;
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

  NtxQueryStringProcess(hxProcess.Value, ProcessImageFileNameWin32, Result);
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

function NtxAssertNotWoW64: TNtxStatus;
begin
  if RtlIsWoW64 then
  begin
    Result.Location := '[WoW64 assertion]';
    Result.Status := STATUS_ASSERTION_FAILURE;
  end
  else
    Result.Status := STATUS_SUCCESS;
end;

end.
