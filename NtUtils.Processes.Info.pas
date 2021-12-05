unit NtUtils.Processes.Info;

{
  This module adds support for querying and setting various information about
  processes.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntpsapi, Ntapi.ntseapi, Ntapi.ntwow64, NtUtils,
  DelphiApi.Reflection, Ntapi.Versions;

const
  PROCESS_READ_PEB = PROCESS_QUERY_LIMITED_INFORMATION or PROCESS_VM_READ;

type
  [NamingStyle(nsCamelCase, 'PebString')]
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
    ImageTimeDateStamp: TUnixTime;
    UserSid: ISid;
    ImagePath: String;
    PackageName: String;
    RelativeAppName: String;
    CommandLine: String;
  end;

// Query variable-size information
function NtxQueryProcess(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  InfoClass: TProcessInfoClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Set variable-size information
[RequiredPrivilege(SE_INCREASE_QUOTA_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_INCREASE_BASE_PRIORITY_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpSometimes)]
function NtxSetProcess(
  [Access(PROCESS_SET_INFORMATION)] hProcess: THandle;
  InfoClass: TProcessInfoClass;
  [in] Buffer: Pointer;
  BufferSize: Cardinal
): TNtxStatus;

type
  NtxProcess = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
      InfoClass: TProcessInfoClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size information
    [RequiredPrivilege(SE_INCREASE_QUOTA_PRIVILEGE, rpSometimes)]
    [RequiredPrivilege(SE_INCREASE_BASE_PRIORITY_PRIVILEGE, rpSometimes)]
    [RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
    [RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
    [RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpSometimes)]
    class function &Set<T>(
      [Access(PROCESS_SET_INFORMATION)] hProcess: THandle;
      InfoClass: TProcessInfoClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Query image name of a process
function NtxQueryImageNameProcess(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] hProcess: THandle;
  out ImageName: String;
  Win32Format: Boolean = True
): TNtxStatus;

// Query image name (in NT format) using only a process ID
function NtxQueryImageNameProcessId(
  PID: TProcessId;
  out ImageName: String
): TNtxStatus;

// Query short name of a process by PID
function NtxQueryNameProcessId(
  PID: TProcessId;
  out ShortName: String
): TNtxStatus;

// Read a string from a process's PEB
function NtxQueryPebStringProcess(
  [Access(PROCESS_READ_PEB)] hProcess: THandle;
  InfoClass: TProcessPebString;
  out PebString: String
): TNtxStatus;

// Query command line of a process
function NtxQueryCommandLineProcess(
  [Access(PROCESS_READ_PEB)] hProcess: THandle;
  out CommandLine: String
): TNtxStatus;

// Enalble/disable handle tracing for a process. Set slot count to 0 to disable.
function NtxSetHandleTraceProcess(
  [Access(PROCESS_SET_INFORMATION)] hProcess: THandle;
  TotalSlots: Cardinal
): TNtxStatus;

// Query most recent handle traces for a process
function NtxQueryHandleTraceProcess(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  out Traces: TArray<TProcessHandleTracingEntry>
): TNtxStatus;

// Query process telemetry information
[MinOSVersion(OsWin10TH1)]
function NtxQueryTelemetryProcess(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] hProcess: THandle;
  out Telemetry: TProcessTelemetry
): TNtxStatus;

// Fail if the current process is running under WoW64
function RtlxAssertNotWoW64(out Status: TNtxStatus): Boolean;

// Query if a process runs under WoW64
function NtxQueryIsWoW64Process(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] hProcess: THandle;
  out WoW64: Boolean
): TNtxStatus;

// Check if the target if WoW64. Fail, if it isn't while we are.
function RtlxAssertWoW64Compatible(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] hProcess: THandle;
  out TargetIsWoW64: Boolean
): TNtxStatus;

function RtlxAssertWoW64CompatiblePeb(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] hProcess: THandle;
  out TargetWoW64Peb: PPeb32
): TNtxStatus;

implementation

uses
  Ntapi.ntpebteb, Ntapi.ntdef, Ntapi.ntexapi, Ntapi.ntrtl, Ntapi.ntstatus,
  Ntapi.ntobapi, Ntapi.ntioapi, NtUtils.Memory, NtUtils.Security.Sid,
  NtUtils.System, DelphiUtils.AutoObjects;

function NtxQueryProcess;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationProcess';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedProcessQueryAccess(InfoClass));

  // Additional expected access
  case InfoClass of
    ProcessImageFileMapping:
      Result.LastCall.Expects<TIoFileAccessMask>(FILE_EXECUTE or SYNCHRONIZE);
  end;

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationProcess(hProcess, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxSetProcess;
begin
  Result.Location := 'NtSetInformationProcess';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(ExpectedProcessSetAccess(InfoClass));
  Result.LastCall.ExpectedPrivilege := ExpectedProcessSetPrivilege(InfoClass);

  // Additional expected access
  case InfoClass of
    ProcessAccessToken:
      Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);

    ProcessDeviceMap:
      Result.LastCall.Expects<TDirectoryAccessMask>(DIRECTORY_TRAVERSE);

    ProcessCombineSecurityDomainsInformation:
      Result.LastCall.Expects<TProcessAccessMask>(
        PROCESS_QUERY_LIMITED_INFORMATION);
  end;

  Result.Status := NtSetInformationProcess(hProcess, InfoClass, Buffer,
    BufferSize);
end;

class function NtxProcess.Query<T>;
begin
  Result.Location := 'NtQueryInformationProcess';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedProcessQueryAccess(InfoClass));

  // Additional expected access
  case InfoClass of
    ProcessImageFileMapping:
      Result.LastCall.Expects<TIoFileAccessMask>(FILE_EXECUTE or SYNCHRONIZE);
  end;

  Result.Status := NtQueryInformationProcess(hProcess, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

class function NtxProcess.&Set<T>;
begin
  Result := NtxSetProcess(hProcess, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxQueryImageNameProcess;
var
  xMemory: INtUnicodeString;
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

function NtxQueryImageNameProcessId;
var
  xMemory: IMemory;
  Data: TSystemProcessIdInformation;
begin
  // On input, specify the PID and the buffer for the string
  Data.ProcessId := PID;
  Data.ImageName.Length := 0;
  Data.ImageName.MaximumLength := $100;

  repeat
    xMemory := Auto.AllocateDynamic(Data.ImageName.MaximumLength);
    Data.ImageName.Buffer := xMemory.Data;

    Result := NtxSystem.Query(SystemProcessIdInformation, Data);

    // If necessary, repeat using the correct value the system put into
    // MaximumLength
  until Result.Status <> STATUS_INFO_LENGTH_MISMATCH;

  if Result.IsSuccess then
    ImageName := Data.ImageName.ToString;
end;

function NtxQueryNameProcessId;
var
  i: Integer;
begin
  Result.Status := STATUS_SUCCESS;

  case PID of
    SYSTEM_IDLE_PID: ShortName := 'System Idle Process';
    SYSTEM_PID:      ShortName := 'System';
  else
    // Query full NT path
    Result := NtxQueryImageNameProcessId(PID, ShortName);

    if not Result.IsSuccess then
      Exit;

    // Extract name only
    for i := High(ShortName) downto Low(String) do
      if ShortName[i] = '\' then
      begin
        Delete(ShortName, 1, i);
        Break;
      end;
  end;
end;

function NtxQueryPebStringProcess;
var
  WoW64Peb: PPeb32;
  BasicInfo: TProcessBasicInformation;
  ProcessParams: PRtlUserProcessParameters;
  Address: Pointer;
  StringData: TNtUnicodeString;
  Buffer: IWideChar;
{$IFDEF Win64}
  ProcessParams32: Wow64Pointer<PRtlUserProcessParameters32>;
  StringData32: TNtUnicodeString32;
{$ENDIF}
begin
  Result := RtlxAssertWoW64CompatiblePeb(hProcess, WoW64Peb);

  if not Result.IsSuccess then
    Exit;

{$IFDEF Win64}
  if Assigned(WoW64Peb) then
  begin
    // Obtain a pointer to WoW64 process parameters
    Result := NtxMemory.Read(hProcess, @WoW64Peb.ProcessParameters,
      ProcessParams32);

    if not Result.IsSuccess then
      Exit;

    // Locate the UNICODE_STRING32 address
    case InfoClass of
      PebStringCurrentDirectory:
        Address := @ProcessParams32.Self.CurrentDirectory.DosPath;

      PebStringDllPath:
        Address := @ProcessParams32.Self.DLLPath;

      PebStringImageName:
        Address := @ProcessParams32.Self.ImagePathName;

      PebStringCommandLine:
        Address := @ProcessParams32.Self.CommandLine;

      PebStringWindowTitle:
        Address := @ProcessParams32.Self.WindowTitle;

      PebStringDesktop:
        Address := @ProcessParams32.Self.DesktopInfo;

      PebStringShellInfo:
         Address := @ProcessParams32.Self.ShellInfo;

      PebStringRuntimeData:
        Address := @ProcessParams32.Self.RuntimeData;
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
      // Read the string content
      Result := NtxReadMemoryAuto(hProcess, Pointer(StringData32.Buffer),
        StringData32.Length, IMemory(Buffer));

      // Save the string content
      if Result.IsSuccess then
        SetString(PebString, Buffer.Data, Buffer.Size div SizeOf(WideChar));
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
      // Read the string content
      Result := NtxReadMemoryAuto(hProcess, StringData.Buffer,
        StringData.Length, IMemory(Buffer));

      if Result.IsSuccess then
        SetString(PebString, Buffer.Data, Buffer.Size div SizeOf(WideChar));
    end
    else
      PebString := '';
  end;
end;

function NtxQueryCommandLineProcess;
var
  Buffer: INtUnicodeString;
begin
  if RtlOsVersionAtLeast(OsWin81) then
  begin
    // Query it if the OS is to new enough
    Result := NtxQueryProcess(hProcess, ProcessCommandLineInformation,
      IMemory(Buffer));

    if Result.IsSuccess then
      CommandLine := Buffer.Data.ToString;
  end
  else
    // Read it from PEB
    Result := NtxQueryPebStringProcess(hProcess, PebStringCommandLine,
      CommandLine);
end;

function NtxSetHandleTraceProcess;
var
  Data: TProcessHandleTracingEnableEx;
begin
  if TotalSlots = 0 then
    // Disable by setting zero-length data
    Result := NtxSetProcess(hProcess, ProcessHandleTracing, nil, 0)
  else
  begin
    // Note that the number of slots will be rounded up to a power of two
    // between 128 and 131072. This will also clear the buffer.
    Data.Flags := 0;
    Data.TotalSlots := TotalSlots;

    Result := NtxProcess.Set(hProcess, ProcessHandleTracing, Data);
  end;
end;

function GrowHandleTrace(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
var
  Buffer: IMemory<PProcessHandleTracingQuery> absolute Memory;
begin
  Result := SizeOf(TProcessHandleTracingQuery) +
    Buffer.Data.TotalTraces * SizeOf(TProcessHandleTracingEntry);

  Inc(Result, Result shr 3); // + 12%
end;

function NtxQueryHandleTraceProcess;
var
  Buffer: IMemory<PProcessHandleTracingQuery>;
  i: Integer;
begin
  Result := NtxQueryProcess(hProcess, ProcessHandleTracing, IMemory(Buffer),
    SizeOf(TProcessHandleTracingQuery), GrowHandleTrace);

  if not Result.IsSuccess then
    Exit;

  SetLength(Traces, Buffer.Data.TotalTraces);

  for i := 0 to High(Traces) do
    Traces[i] := Buffer.Data.HandleTrace{$R-}[i]{$R+};
end;

function NtxQueryTelemetryProcess;
var
  Buffer: IMemory<PProcessTelemetryIdInformation>;
begin
  Result := NtxQueryProcess(hProcess, ProcessTelemetryIdInformation,
    IMemory(Buffer));

  if Result.IsSuccess then
    with Telemetry do
    begin
      ProcessID := Buffer.Data.ProcessID;
      ProcessStartKey := Buffer.Data.ProcessStartKey;
      CreateTime := Buffer.Data.CreateTime;
      CreateInterruptTime := Buffer.Data.CreateInterruptTime;
      CreateUnbiasedInterruptTime := Buffer.Data.CreateUnbiasedInterruptTime;
      ProcessSequenceNumber := Buffer.Data.ProcessSequenceNumber;
      SessionCreateTime := Buffer.Data.SessionCreateTime;
      SessionID := Buffer.Data.SessionID;
      BootID := Buffer.Data.BootID;
      ImageChecksum := Buffer.Data.ImageChecksum;
      ImageTimeDateStamp := Buffer.Data.ImageTimeDateStamp;

      if not RtlxCopySid(Buffer.Data.UserSid, UserSid).IsSuccess then
        UserSid := nil;

      ImagePath := String(Buffer.Data.ImagePath);
      PackageName := String(Buffer.Data.PackageName);
      RelativeAppName := String(Buffer.Data.RelativeAppName);
      CommandLine := String(Buffer.Data.CommandLine);
    end;
end;

function RtlxAssertNotWoW64;
begin
  Result := RtlIsWoW64;

  if Result then
  begin
    Status.Location := '[WoW64 check]';
    Status.Status := STATUS_ASSERTION_FAILURE;
  end;
end;

function NtxQueryIsWoW64Process;
var
  WoW64Peb: Pointer;
begin
  Result := NtxProcess.Query(hProcess, ProcessWow64Information, WoW64Peb);

  if Result.IsSuccess then
    WoW64 := Assigned(WoW64Peb);
end;

function RtlxAssertWoW64Compatible;
begin
  // Check if the target is a WoW64 process
  Result := NtxQueryIsWoW64Process(hProcess, TargetIsWoW64);

{$IFDEF Win32}
  // Prevent WoW64 -> Native access scenarious
  if Result.IsSuccess and not TargetIsWoW64  then
    RtlxAssertNotWoW64(Result);
{$ENDIF}
end;

function RtlxAssertWoW64CompatiblePeb;
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
