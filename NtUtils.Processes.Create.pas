unit NtUtils.Processes.Create;

{
  Base definitions for various process creation techniques.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.Ntpsapi, Ntapi.ntseapi, Ntapi.ntmmapi,
  Ntapi.ntpebteb, Ntapi.ntrtl, Ntapi.ntioapi, Ntapi.WinUser, Ntapi.ntwow64,
  Ntapi.ntldr, Ntapi.ProcessThreadsApi, Ntapi.Versions, DelphiApi.Reflection,
  NtUtils;

type
  TNewProcessFlags = set of (
    poNativePath,
    poForceCommandLine,
    poSuspended,
    poInheritHandles,
    poBreakawayFromJob,
    poForceBreakaway, // Win 8.1+
    poInheritConsole,
    poUseWindowMode,
    poForceWindowTitle,
    poUseStdHandles,
    poRequireElevation,
    poRunAsInvokerOn,
    poRunAsInvokerOff,
    poIgnoreElevation,
    poLPAC, // Win 10 TH1+
    poUseProtection, // Win 8.1+
    poUseSessionId,
    poUseSafeOpenPromptOriginClaim, // Win 10 RS1+
    poDetectManifest
  );

  TProcessInfoFields = set of (
    piProcessID,
    piThreadID,
    piProcessHandle,
    piThreadHandle,
    piFileHandle,
    piSectionHandle,
    piImageInformation,
    piImageBase,
    piPebAddress,
    piPebAddressWoW64,
    piTebAddress,
    piUserProcessParameters,
    piUserProcessParametersFlags,
    piManifest
  );

  TProcessInfo = record
    ValidFields: TProcessInfoFields;
    ClientId: TClientId;
    hxProcess: IHandle;
    hxThread: IHandle;
    hxFile: IHandle;
    hxSection: IHandle;
    ImageInformation: TSectionImageInformation;
    [DontFollow] ImageBaseAddress: Pointer;
    [DontFollow] PebAddressNative: PPeb;
    [DontFollow] PebAddressWoW64: PPeb32;
    [DontFollow] TebAddress: PTeb;
    [DontFollow] UserProcessParameters: PRtlUserProcessParameters;
    UserProcessParametersFlags: TRtlUserProcessFlags;
    Manifest: TMemory;
  end;

  TCreateProcessMitigations = array [TPsMitigationOption] of
    TPsMitigationOptionState;

  TCreateProcessOptions = record
    Application, Parameters: String;
    Flags: TNewProcessFlags;
    CurrentDirectory: String;
    Desktop: String;
    Environment: IEnvironment;
    ProcessAttributes: IObjectAttributes;
    ThreadAttributes: IObjectAttributes;
    WindowMode: TShowMode32;
    WindowTitle: String;
    hxStdInput: IHandle;
    hxStdOutput: IHandle;
    hxStdError: IHandle;
    HandleList: TArray<IHandle>;
    [Access(TOKEN_CREATE_PROCESS or TOKEN_CREATE_PROCESS_EX)] hxToken: IHandle;
    [Access(PROCESS_CREATE_PROCESS)] hxParentProcess: IHandle;
    [Access(JOB_OBJECT_ASSIGN_PROCESS)] hxJob: IHandle;
    [Access(SECTION_MAP_EXECUTE)] hxSection: IHandle;
    [Access(DEBUG_PROCESS_ASSIGN)] hxDebugPort: IHandle;
    MemoryReserve: TArray<TPsMemoryReserve>;
    PriorityClass: TProcessPriorityClassValue;
    Mitigations: TCreateProcessMitigations;
    MitigationsAudit: TCreateProcessMitigations;
    ChildPolicy: TProcessChildFlags;   // Win 10 TH1+
    AppContainer: ISid;                // Win 8+
    Capabilities: TArray<TGroup>;      // Win 8+
    Protection: TProtectionLevel;      // Win 8.1+
    PackageName: String;               // Win 8.1+
    AppUserModeId: String;             // {PackageFamilyName}!{AppId}, Win 10 RS1+
    PackageBreakaway: TProcessDesktopAppFlags; // Win 10 RS2+
    LogonFlags: TProcessLogonFlags;
    Timeout: Int64;
    AdditionalFileAccess: TIoFileAccessMask;
    Domain, Username, Password: String;
    SessionId: TSessionId;
    SafeOpenPromptOriginClaimResult: TSeSafeOpenPromptExperienceResults;
    SafeOpenPromptOriginClaimPath: String;
    function ApplicationWin32: String;
    function ApplicationNative: String;
    function CommandLine: String;
  end;

  // A prototype for process creation routines
  TCreateProcessMethod = function (
    const Options: TCreateProcessOptions;
    out Info: TProcessInfo
  ): TNtxStatus;

  TSupportedCreateProcessOptions = (
    spoCurrentDirectory,
    spoSuspended,
    spoInheritHandles,
    spoBreakawayFromJob,
    spoForceBreakaway,
    spoInheritConsole,
    spoRequireElevation,
    spoRunAsInvoker,
    spoIgnoreElevation,
    spoEnvironment,
    spoObjectInherit,
    spoDesiredAccess,
    spoSecurity,
    spoWindowMode,
    spoWindowTitle,
    spoStdHandles,
    spoDesktop,
    spoToken,
    spoParentProcess,
    spoJob,
    spoSection,
    spoDebugPort,
    spoHandleList,
    spoMemoryReserve,
    spoPriorityClass,
    spoMitigations,
    spoChildPolicy,
    spoLPAC,
    spoAppContainer,
    spoPackage,
    spoPackageBreakaway,
    spoAppUserModeId,
    spoProtection,
    spoLogonFlags,
    spoCredentials,
    spoSessionId,
    spoSafeOpenPromptOriginClaim,
    spoTimeout,
    spoAdditionalFileAccess,
    spoDetectManifest
  );

  TCreateProcessOptionMode = (
    omOptional,
    omRequired
  );

  // Annotation for indicating supported options for a process creation routine
  SupportedOptionAttribute = class (TCustomAttribute)
    Option: TSupportedCreateProcessOptions;
    Mode: TCreateProcessOptionMode;
    constructor Create(
      Option: TSupportedCreateProcessOptions;
      Mode: TCreateProcessOptionMode = omOptional
    ); overload;

    constructor Create(
      Option: TSupportedCreateProcessOptions;
      MinimalVersion: TWindowsVersion
    ); overload;
  end;

// Temporarily set or remove a compatibility layer to control elevation requests
function RtlxApplyCompatLayer(
  ForceOn: Boolean;
  ForceOff: Boolean;
  out Reverter: IAutoReleasable
): TNtxStatus;

// Register process creation with CSR and SxS using the embedded manifest.
// Note: use with the poDetectManifest flag; otherwise, the process will be
// registered without a manifest.
function CsrxRegisterProcessCreation(
  const Options: TCreateProcessOptions;
  const Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ImageHlp, Ntapi.ntcsrapi, NtUtils.Environment,
  NtUtils.SysUtils, NtUtils.Files, NtUtils.Csr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TCreateProcessOptions }

function TCreateProcessOptions.ApplicationNative;
begin
  if poNativePath in Flags then
    Result := Application
  else
    Result := RtlxDosPathToNativePath(Application);
end;

function TCreateProcessOptions.ApplicationWin32;
begin
  if poNativePath in Flags then
    Result := RtlxNativePathToDosPath(Application)
  else
    Result := Application;
end;

function TCreateProcessOptions.CommandLine;
begin
  if poForceCommandLine in Flags then
    Result := Parameters
  else
  begin
    Result := '"' + ApplicationWin32 + '"';

    if Parameters <> '' then
      Result := Result + ' ' + Parameters;
  end;
end;

{ SupportedOptionAttribute }

constructor SupportedOptionAttribute.Create(
  Option: TSupportedCreateProcessOptions;
  Mode: TCreateProcessOptionMode = omOptional
);
begin
  Self.Option := Option;
  Self.Mode := Mode;
end;

constructor SupportedOptionAttribute.Create(
  Option: TSupportedCreateProcessOptions;
  MinimalVersion: TWindowsVersion
);
begin
  Self.Option := Option;
  Self.Mode := omOptional;
end;

{ Functions }

function RtlxSetRunAsInvoker(
  Enable: Boolean;
  out Reverter: IAutoReleasable
): TNtxStatus;
var
  OldEnvironment: IEnvironment;
  Layer: String;
begin
  // Backup the existing environment
  Result := RtlxCreateEnvironment(OldEnvironment, True);

  if not Result.IsSuccess then
    Exit;

  if Enable then
    Layer := 'RunAsInvoker'
  else
    Layer := '';

  // Overwrite the compatibility layer
  Result := RtlxSetVariableEnvironment('__COMPAT_LAYER', Layer);

  // Revert to the old environment later
  if Result.IsSuccess then
    Reverter := Auto.Delay(
      procedure
      begin
        RtlxSetCurrentEnvironment(OldEnvironment);
      end
    );
end;

function RtlxApplyCompatLayer;
begin
  if ForceOn then
    Result := RtlxSetRunAsInvoker(True, Reverter)
  else if ForceOff then
    Result := RtlxSetRunAsInvoker(False, Reverter)
  else
    Result := NtxSuccess;
end;

function CsrxRegisterProcessCreation;
var
  RequiredFields: TProcessInfoFields;
  Manifest: TMemory;
begin
  RequiredFields := [piProcessHandle, piThreadHandle, piProcessID,
    piThreadID];

  if RtlOsVersionAtLeast(OsWin81) then
    Exclude(RequiredFields, piThreadHandle);

  if RequiredFields * Info.ValidFields <> RequiredFields then
  begin
    Result.Location := 'CsrxRegisterProcessCreation';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Use embedded manifest when found
  if piManifest in Info.ValidFields then
    Manifest := Info.Manifest
  else
    Manifest := Default(TMemory);

  // But allow the image to opt-out due to characteristics
  if (piImageInformation in Info.ValidFields) and
    BitTest(Info.ImageInformation.DllCharacteristics and
    IMAGE_DLLCHARACTERISTICS_NO_ISOLATION) then
    Manifest := Default(TMemory);

  // Send a message to CSR
  Result := CsrxRegisterProcessManifest(Info.hxProcess, Info.hxThread,
    Info.ClientId, Info.hxProcess, BASE_MSG_HANDLETYPE_PROCESS, Manifest,
    Options.ApplicationWin32);
end;

end.
