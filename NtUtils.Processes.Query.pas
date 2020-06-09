unit NtUtils.Processes.Query;

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, Ntapi.ntwow64, NtUtils,
  DelphiApi.Reflection, NtUtils.Version;

const
  PROCESS_READ_PEB = PROCESS_QUERY_LIMITED_INFORMATION or PROCESS_VM_READ;

type
  TProcessPebString = (
    PebStringCurrentDirectory,
    PebStringDllPath,
    PebStringImageName,
    PebStringCommandLine,
    PebStringWindowTitle,
    PebStringDesktop,
    PebStringShellInfo,
    PebStringRuntimeData
  );

  [MinOSVersion(OsWin10TH1)]
  TProcessTelemetry = record
    ProcessID: TProcessId32;
    [Hex] ProcessStartKey: UInt64;
    CreateTime: TLargeInteger;
    CreateInterruptTime: TULargeInteger;
    CreateUnbiasedInterruptTime: TULargeInteger;
    ProcessSequenceNumber: UInt64;
    SessionCreateTime: TULargeInteger;
    SessionID: TSessionId;
    BootID: Cardinal;
    [Hex] ImageChecksum: Cardinal;
    [Hex] ImageTimeDateStamp: Cardinal;
    UserSid: ISid;
    ImagePath: String;
    PackageName: String;
    RelativeAppName: String;
    CommandLine: String;
  end;

// Query variable-size information
function NtxQueryProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil): TNtxStatus;

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

// Query image name of a process
function NtxQueryImageNameProcess(hProcess: THandle;
  out ImageName: String; Win32Format: Boolean = True): TNtxStatus;

// Query image name (in NT format) using only a process ID
function NtxQueryImageNameProcessId(PID: TProcessId;
  out ImageName: String): TNtxStatus;

// Read a string from a process's PEB
function NtxQueryPebStringProcess(hProcess: THandle; InfoClass:
  TProcessPebString; out PebString: String): TNtxStatus;

// Query command line of a process
function NtxQueryCommandLineProcess(hProcess: THandle;
  out CommandLine: String): TNtxStatus;

// Enalble/disable handle tracing for a process. Set slot count to 0 to disable.
function NtxSetHandleTraceProcess(hProcess: THandle; TotalSlots: Integer)
  : TNtxStatus;

// Query handle trasing for a process
function NtxQueryHandleTraceProcess(hProcess: THandle; out Traces:
  TArray<TProcessHandleTracingEntry>): TNtxStatus;

// Query process telemetry information
function NtxQueryTelemetryProcess(hProcess: THandle; out Telemetry:
  TProcessTelemetry): TNtxStatus;

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
  Ntapi.ntdef, Ntapi.ntexapi, Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.ntpebteb,
  NtUtils.Access.Expected, NtUtils.Processes, NtUtils.Processes.Memory,
  NtUtils.Security.Sid, NtUtils.System, DelphiUtils.AutoObject;

function NtxQueryProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  out xMemory: IMemory; InitialBuffer: Cardinal; GrowthMethod:
  TBufferGrowthMethod): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);
  RtlxComputeProcessQueryAccess(Result.LastCall, InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationProcess(hProcess, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxSetProcess(hProcess: THandle; InfoClass: TProcessInfoClass;
  Data: Pointer; DataSize: Cardinal): TNtxStatus;
begin
  Result.Location := 'NtSetInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);
  RtlxComputeProcessSetAccess(Result.LastCall, InfoClass);

  Result.Status := NtSetInformationProcess(hProcess, InfoClass, Data, DataSize);
end;

class function NtxProcess.Query<T>(hProcess: THandle;
  InfoClass: TProcessInfoClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationProcess';
  Result.LastCall.AttachInfoClass(InfoClass);
  RtlxComputeProcessQueryAccess(Result.LastCall, InfoClass);

  Result.Status := NtQueryInformationProcess(hProcess, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxProcess.SetInfo<T>(hProcess: THandle;
  InfoClass: TProcessInfoClass; const Buffer: T): TNtxStatus;
begin
  Result := NtxSetProcess(hProcess, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxQueryImageNameProcess(hProcess: THandle;
  out ImageName: String; Win32Format: Boolean): TNtxStatus;
var
  xMemory: IMemory<PNtUnicodeString>;
  InfoClass: TProcessInfoClass;
begin
  if Win32Format then
    InfoClass := ProcessImageFileNameWin32
  else
    InfoClass := ProcessImageFileName;

  Result := NtxQueryProcess(hProcess, InfoClass,
    IMemory(xMemory));

  if Result.IsSuccess then
    ImageName := xMemory.Data.ToString;
end;

function NtxQueryImageNameProcessId(PID: TProcessId;
  out ImageName: String): TNtxStatus;
var
  xMemory: IMemory;
  Data: TSystemProcessIdInformation;
begin
  // On input we specify PID and string buffer size
  Data.ProcessId := PID;
  Data.ImageName.Length := 0;
  Data.ImageName.MaximumLength := Word(-2);

  xMemory := TAutoMemory.Allocate(Data.ImageName.MaximumLength);
  Data.ImageName.Buffer := xMemory.Data;

  Result := NtxSystem.Query(SystemProcessIdInformation, Data);

  if Result.IsSuccess then
    ImageName := Data.ImageName.ToString;
end;

function NtxQueryPebStringProcess(hProcess: THandle; InfoClass:
  TProcessPebString; out PebString: String): TNtxStatus;
var
  WoW64Peb: PPeb32;
  BasicInfo: TProcessBasicInformation;
  ProcessParams: PRtlUserProcessParameters;
  Address: Pointer;
  StringData: TNtUnicodeString;
  xMemory: IMemory<PWideChar>;
{$IFDEF Win64}
  WowPointer: Wow64Pointer;
  ProcessParams32: PRtlUserProcessParameters32;
  StringData32: TNtUnicodeString32;
{$ENDIF}
begin
  Result := RtlxAssertWoW64Compatible(hProcess, WoW64Peb);

  if not Result.IsSuccess then
    Exit;

{$IFDEF Win64}
  if Assigned(WoW64Peb) then
  begin
    // Obtain a pointer to WoW64 process parameters
    Result := NtxMemory.Read(hProcess, @WoW64Peb.ProcessParameters, WowPointer);

    if not Result.IsSuccess then
      Exit;

    ProcessParams32 := Pointer(WowPointer);

    // Locate the UNICODE_STRING32 address
    case InfoClass of
      PebStringCurrentDirectory:
        Address := @ProcessParams32.CurrentDirectory.DosPath;

      PebStringDllPath:
        Address := @ProcessParams32.DLLPath;

      PebStringImageName:
        Address := @ProcessParams32.ImagePathName;

      PebStringCommandLine:
        Address := @ProcessParams32.CommandLine;

      PebStringWindowTitle:
        Address := @ProcessParams32.WindowTitle;

      PebStringDesktop:
        Address := @ProcessParams32.DesktopInfo;

      PebStringShellInfo:
         Address := @ProcessParams32.ShellInfo;

      PebStringRuntimeData:
        Address := @ProcessParams32.RuntimeData;
    else
      Result.Location := 'NtxQueryPebStringProcess';
      Result.Status := STATUS_INVALID_INFO_CLASS;
      Exit;
    end;

    // Read the UNICIDE_STRING32 structure
    Result := NtxMemory.Read(hProcess, Address, StringData32);

    if not Result.IsSuccess then
      Exit;

    if StringData32.Length > 0 then
    begin
      // Allocate a buffer
      IMemory(xMemory) := TAutoMemory(StringData32.Length);

      // Read the string content
      Result := NtxReadMemoryProcess(hProcess, Pointer(StringData32.Buffer),
        xMemory.Data, xMemory.Size);

      // Save the string content
      if Result.IsSuccess then
        SetString(PebString, xMemory.Data, xMemory.Size div SizeOf(WideChar));
    end
    else
      PebString := '';
  end
  else
{$ENDIF}
  begin
    // Find native PEB location
    Result := NtxProcess.Query(hProcess, ProcessBasicInformation, BasicInfo);

    if not Result.IsSuccess then
      Exit;

    // Obtain a pointer to process parameters
    Result := NtxMemory.Read(hProcess,
      @BasicInfo.PebBaseAddress.ProcessParameters, ProcessParams);

    if not Result.IsSuccess then
      Exit;

    // Locate the UNICODE_STRING's address
    case InfoClass of
      PebStringCurrentDirectory:
        Address := @ProcessParams.CurrentDirectory.DosPath;

      PebStringDllPath:
        Address := @ProcessParams.DLLPath;

      PebStringImageName:
        Address := @ProcessParams.ImagePathName;

      PebStringCommandLine:
        Address := @ProcessParams.CommandLine;

      PebStringWindowTitle:
        Address := @ProcessParams.WindowTitle;

      PebStringDesktop:
        Address := @ProcessParams.DesktopInfo;

      PebStringShellInfo:
         Address := @ProcessParams.ShellInfo;

      PebStringRuntimeData:
        Address := @ProcessParams.RuntimeData;
    else
      Result.Location := 'NtxQueryPebStringProcess';
      Result.Status := STATUS_INVALID_INFO_CLASS;
      Exit;
    end;

    // Read the UNICIDE_STRING structure
    Result := NtxMemory.Read(hProcess, Address, StringData);

    if not Result.IsSuccess then
      Exit;

    if StringData.Length > 0 then
    begin
      // Allocate a buffer
      IMemory(xMemory) := TAutoMemory.Allocate(StringData.Length);

      // Read the string content
      Result := NtxReadMemoryProcess(hProcess, StringData.Buffer, xMemory.Data,
        xMemory.Size);

      if Result.IsSuccess then
        SetString(PebString, xMemory.Data, xMemory.Size div SizeOf(WideChar));
    end
    else
      PebString := '';
  end;
end;

function NtxQueryCommandLineProcess(hProcess: THandle;
  out CommandLine: String): TNtxStatus;
var
  xMemory: IMemory<PNtUnicodeString>;
begin
  if RtlOsVersionAtLeast(OsWin81) then
  begin
    // Query it if the OS is to new enough
    Result := NtxQueryProcess(hProcess, ProcessCommandLineInformation,
      IMemory(xMemory));

    if Result.IsSuccess then
      CommandLine := xMemory.Data.ToString;
  end
  else
    // Read it from PEB
    Result := NtxQueryPebStringProcess(hProcess, PebStringCommandLine,
      CommandLine);
end;

function NtxSetHandleTraceProcess(hProcess: THandle; TotalSlots: Integer)
  : TNtxStatus;
var
  Data: TProcessHandleTracingEnableEx;
begin
  if TotalSlots = 0 then
    // Disable by setting zero-length data
    Result := NtxSetProcess(hProcess, ProcessHandleTracing, nil, 0)
  else
  begin
    Data.Flags := 0;
    Data.TotalSlots := TotalSlots;

    Result := NtxProcess.SetInfo(hProcess, ProcessHandleTracing, Data);
  end;
end;

function GrowHandleTrace(Memory: IMemory; Required: NativeUInt): NativeUInt;
var
  xMemory: IMemory<PProcessHandleTracingQuery> absolute Memory;
begin
  Result := SizeOf(TProcessHandleTracingQuery) +
    xMemory.Data.TotalTraces * SizeOf(TProcessHandleTracingEntry);

  Inc(Result, Result shr 3); // + 12%
end;

function NtxQueryHandleTraceProcess(hProcess: THandle; out Traces:
  TArray<TProcessHandleTracingEntry>): TNtxStatus;
var
  xMemory: IMemory<PProcessHandleTracingQuery>;
  i: Integer;
begin
  Result := NtxQueryProcess(hProcess, ProcessHandleTracing, IMemory(xMemory),
    SizeOf(TProcessHandleTracingQuery), GrowHandleTrace);

  if not Result.IsSuccess then
    Exit;

  SetLength(Traces, xMemory.Data.TotalTraces);

  for i := 0 to High(Traces) do
    Traces[i] := xMemory.Data.HandleTrace{$R-}[i]{$R+};
end;

function NtxQueryTelemetryProcess(hProcess: THandle; out Telemetry:
  TProcessTelemetry): TNtxStatus;
var
  xMemory: IMemory<PProcessTelemetryIdInformation>;
begin
  Result := NtxQueryProcess(hProcess, ProcessTelemetryIdInformation,
    IMemory(xMemory));

  if Result.IsSuccess then
    with Telemetry do
    begin
      ProcessID := xMemory.Data.ProcessID;
      ProcessStartKey := xMemory.Data.ProcessStartKey;
      CreateTime := xMemory.Data.CreateTime;
      CreateInterruptTime := xMemory.Data.CreateInterruptTime;
      CreateUnbiasedInterruptTime := xMemory.Data.CreateUnbiasedInterruptTime;
      ProcessSequenceNumber := xMemory.Data.ProcessSequenceNumber;
      SessionCreateTime := xMemory.Data.SessionCreateTime;
      SessionID := xMemory.Data.SessionID;
      BootID := xMemory.Data.BootID;
      ImageChecksum := xMemory.Data.ImageChecksum;
      ImageTimeDateStamp := xMemory.Data.ImageTimeDateStamp;

      if not RtlxCopySid(xMemory.Data.UserSid, UserSid).IsSuccess then
        UserSid := nil;

      ImagePath := String(xMemory.Data.ImagePath);
      PackageName := String(xMemory.Data.PackageName);
      RelativeAppName := String(xMemory.Data.RelativeAppName);
      CommandLine := String(xMemory.Data.CommandLine);
    end;
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
