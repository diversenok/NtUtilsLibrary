unit NtUtils.Processes.Info;

{
  This module adds support for querying and setting various information about
  processes.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntpsapi, Ntapi.ntseapi, Ntapi.ntpebteb, Ntapi.ntwow64,
  NtUtils, DelphiApi.Reflection, Ntapi.Versions;

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

  TProcessAddresses = record
    ProcessID: TProcessId;
    ParentPID: TProcessId;
    PebAddressNative: PPeb;
    PebAddressWoW64: PPeb32;
    ImageBase: Pointer;
  end;

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

// Query PEBs and image base address for a process
function NtxQueryAddressesProcess(
  [Access(PROCESS_READ_PEB)] hProcess: THandle;
  out Info: TProcessAddresses
): TNtxStatus;

// Query image name or command line of a process
function NtxQueryStringProcess(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] hProcess: THandle;
  InfoClass: TProcessInfoClass;
  out ProcessString: String
): TNtxStatus;

// Query image name (in NT format) without opening the process
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
function NtxReadPebStringProcess(
  [Access(PROCESS_READ_PEB)] hProcess: THandle;
  InfoClass: TProcessPebString;
  out PebString: String
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
  Ntapi.ntdef, Ntapi.ntexapi, Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.ntobapi,
  Ntapi.ntioapi, NtUtils.Memory, NtUtils.Security.Sid, NtUtils.System,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

function NtxQueryAddressesProcess;
var
  BasicInfo: TProcessBasicInformation;
begin
  Info := Default(TProcessAddresses);

  // Get WoW64 PEB address and fail WoW64 -> Native queries
  Result := RtlxAssertWoW64CompatiblePeb(hProcess, Info.PebAddressWoW64);

  if not Result.IsSuccess then
    Exit;

  // Get native PEB address and IDs
  Result := NtxProcess.Query(hProcess, ProcessBasicInformation, BasicInfo);

  if not Result.IsSuccess then
    Exit;

  Info.ProcessID := BasicInfo.UniqueProcessID;
  Info.ParentPID := BasicInfo.InheritedFromUniqueProcessID;

  // Querying info under WOW64 reuturns a WoW64 PEB instead of a native one
  if not RtlIsWoW64 then
    Info.PebAddressNative := BasicInfo.PebBaseAddress;

  // Read image base from either of the PEBs
  Result := NtxMemory.Read(hProcess, @BasicInfo.PebBaseAddress.ImageBaseAddress,
    Info.ImageBase);
end;

function NtxQueryStringProcess;
var
  xMemory: INtUnicodeString;
begin
  case InfoClass of
    ProcessImageFileNameWin32, ProcessImageFileName,
    ProcessCommandLineInformation:
      ; // Allowed
  else
    Result.Location := 'NtxQueryStringProcess';
    Result.Status := STATUS_INVALID_INFO_CLASS;
    Exit;
  end;

  Result := NtxQueryProcess(hProcess, InfoClass,
    IMemory(xMemory));

  if Result.IsSuccess then
    ProcessString := xMemory.Data.ToString;
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

function NtxReadPebStringProcess;
var
  WoW64Peb: PPeb32;
  BasicInfo: TProcessBasicInformation;
  ProcessParams: PRtlUserProcessParameters;
  Address: Pointer;
  StringData: TNtUnicodeString;
  Buffer: IWideChar;
  Flags: TRtlUserProcessFlags;
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

    // Read the flags to determine whether the parameters are normalized
    Result := NtxMemory.Read(hProcess, @ProcessParams32.Self.Flags, Flags);

    if not Result.IsSuccess then
      Exit;

    // The pointers are actually offsets; normalize them
    {$Q-}{$R-}
    if not BitTest(Flags and RTL_USER_PROC_PARAMS_NORMALIZED) then
      Inc(StringData32.Buffer.Value, ProcessParams32.Value);
    {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

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

    // Read the flags to determine whether the parameters are normalized
    Result := NtxMemory.Read(hProcess, @ProcessParams.Flags, Flags);

    if not Result.IsSuccess then
      Exit;

    // The pointers are actually offsets; make them absolute
    {$Q-}{$R-}
    if not BitTest(Flags and RTL_USER_PROC_PARAMS_NORMALIZED) then
      Inc(UIntPtr(StringData.Buffer), UIntPtr(ProcessParams));
    {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

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
    Traces[i] := Buffer.Data.HandleTrace{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
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
