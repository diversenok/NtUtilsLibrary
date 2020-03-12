unit NtUtils.Processes.Query;

interface

uses
  Ntapi.ntpsapi, Ntapi.ntwow64, NtUtils.Exceptions;

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
  out TargetIsWoW64: Boolean): TNtxStatus; overload;

function RtlxAssertWoW64Compatible(hProcess: THandle;
  out TargetWoW64Peb: PPeb32): TNtxStatus; overload;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Access.Expected, NtUtils.Processes;

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

function RtlxAssertWoW64Compatible(hProcess: THandle;
  out TargetWoW64Peb: PPeb32): TNtxStatus;
begin
  // Check if the target is a WoW64 process
  Result := NtxProcess.Query(hProcess, ProcessWow64Information, TargetWoW64Peb);

{$IFDEF Win32}
  // Prevent WoW64 -> Native access scenarious
  if Result.IsSuccess and not Assigned(TargetWoW64Peb)  then
      RtlxAssertNotWoW64(Result);
{$ENDIF}
end;

end.
