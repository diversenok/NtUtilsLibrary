unit NtUtils.Processes.Create.Native;

{
  The module provides support for process creation via Native API.
}

interface

uses
  Ntapi.ntrtl, Ntapi.ntseapi, Ntapi.Versions, NtUtils, NtUtils.Processes.Create,
  DelphiUtils.AutoObjects;

type
  IRtlUserProcessParameters = IMemory<PRtlUserProcessParameters>;

// Allocate user process parameters
function RtlxCreateProcessParameters(
  const Options: TCreateProcessOptions;
  out xMemory: IRtlUserProcessParameters
): TNtxStatus;

// Create a new process via RtlCreateUserProcess
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoWindowTitle)]
[SupportedOption(spoStdHandles)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoDebugPort)]
[SupportedOption(spoDetectManifest)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function RtlxCreateUserProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via RtlCreateUserProcessEx
[MinOSVersion(OsWin10RS2)]
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoWindowTitle)]
[SupportedOption(spoStdHandles)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoJob)]
[SupportedOption(spoDebugPort)]
[SupportedOption(spoDetectManifest)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function RtlxCreateUserProcessEx(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via NtCreateUserProcess
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoForceBreakaway)]
[SupportedOption(spoInheritConsole)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoObjectInherit)]
[SupportedOption(spoDesiredAccess)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoWindowTitle)]
[SupportedOption(spoStdHandles)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoJob)]
[SupportedOption(spoDebugPort)]
[SupportedOption(spoHandleList)]
[SupportedOption(spoChildPolicy)]
[SupportedOption(spoLPAC)]
[SupportedOption(spoPackageBreakaway)]
[SupportedOption(spoProtection)]
[SupportedOption(spoSafeOpenPromptOriginClaim)]
[SupportedOption(spoAdditionalFileAccess)]
[SupportedOption(spoDetectManifest)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtxCreateUserProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntstatus, Ntapi.ntioapi,
  Ntapi.ntpebteb, Ntapi.ProcessThreadsApi, Ntapi.ConsoleApi, NtUtils.Threads,
  NtUtils.Files, NtUtils.Objects, NtUtils.Ldr, NtUtils.Tokens,
  NtUtils.Processes.Info, NtUtils.Files.Open, NtUtils.Manifests;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Process Parameters & Attributes }

type
  TAutoUserProcessParams = class (TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

procedure TAutoUserProcessParams.Release;
begin
  if Assigned(FData) then
    RtlDestroyProcessParameters(FData);

  FData := nil;
  inherited;
end;

function RtlxCreateProcessParameters;
var
  Buffer: PRtlUserProcessParameters;
  ApplicationWin32: String;
  ApplicationWin32Str, CommandLineStr, CurrentDirStr, DesktopStr,
  WindowTitleStr: TNtUnicodeString;
  WindowTitleStrRef: PNtUnicodeString;
begin
  // Keep the string from the Options.ApplicationWin32() call alive
  ApplicationWin32 := Options.ApplicationWin32;
  Result := RtlxInitUnicodeString(ApplicationWin32Str, ApplicationWin32);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(CommandLineStr, Options.CommandLine);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(CurrentDirStr, Options.CurrentDirectory);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(DesktopStr, Options.Desktop);

  if not Result.IsSuccess then
    Exit;

  if (poForceWindowTitle in Options.Flags) or (Options.WindowTitle <> '') then
  begin
    Result := RtlxInitUnicodeString(WindowTitleStr, Options.WindowTitle);

    if not Result.IsSuccess then
      Exit;

    WindowTitleStrRef := @WindowTitleStr
  end
  else
    WindowTitleStrRef := nil;

  Result.Location := 'RtlCreateProcessParametersEx';
  Result.Status := RtlCreateProcessParametersEx(
    Buffer,
    ApplicationWin32Str,
    nil, // DllPath
    CurrentDirStr.RefOrNil,
    @CommandLineStr,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    WindowTitleStrRef,
    DesktopStr.RefOrNil,
    nil, // ShellInfo
    nil, // RuntimeData
    RTL_USER_PROC_PARAMS_NORMALIZED
  );

  if not Result.IsSuccess then
    Exit;

  // Make sure zero-length strings use null pointers
  Buffer.DLLPath := Default(TNtUnicodeString);
  Buffer.ShellInfo := Default(TNtUnicodeString);
  Buffer.RuntimeData := Default(TNtUnicodeString);

  if Buffer.WindowTitle.Length = 0 then
    Buffer.WindowTitle := Default(TNtUnicodeString);

  IMemory(xMemory) := TAutoUserProcessParams.Capture(Buffer,
    Buffer.MaximumLength + Buffer.EnvironmentSize);

  // Adjust window mode flags
  if poUseWindowMode in Options.Flags then
  begin
    xMemory.Data.WindowFlags := xMemory.Data.WindowFlags or STARTF_USESHOWWINDOW;
    xMemory.Data.ShowWindowFlags := Options.WindowMode;
  end;

  // Standard I/O handles
  if poUseStdHandles in Options.Flags then
  begin
    xMemory.Data.WindowFlags := xMemory.Data.WindowFlags or STARTF_USESTDHANDLES;
    xMemory.Data.StandardInput := HandleOrDefault(Options.hxStdInput);
    xMemory.Data.StandardOutput := HandleOrDefault(Options.hxStdOutput);
    xMemory.Data.StandardError := HandleOrDefault(Options.hxStdError);
  end;
end;

type
  TPsAttributesRecord = record
  private
    Source: TCreateProcessOptions;
    FImageName: String;
    FClientId: TClientId;
    FTebAddress: PTeb;
    FHandleList: TArray<THandle>;
    FStdHandleInfo: TPsStdHandleInfo;
    hxExpandedToken: IHandle;
    hJob: THandle;
    PackagePolicy: TProcessAllPackagesFlags;
    PsProtection: TPsProtection;
    SeSafePromptClaim: TSeSafeOpenPromptResults;
    Buffer: IMemory<PPsAttributeList>;
    function GetData: PPsAttributeList;
  public
    function Create(const Options: TCreateProcessOptions): TNtxStatus;
    property Data: PPsAttributeList read GetData;
    property ClientId: TClientId read FClientId;
    property ImageName: String read FImageName;
    property TebAddress: PTeb read FTebAddress;
  end;

{ TPsAttributesRecord }

function RtlxWin32ToNativeProtection(
  Win32Protection: TProtectionLevel;
  out NativeProtection: TPsProtection
): TNtxStatus;
const
  PROTECTION_TYPE: array [TProtectionLevel] of TPsProtectionType = (
    PsProtectedTypeProtectedLight, PsProtectedTypeProtected,
    PsProtectedTypeProtectedLight, PsProtectedTypeProtectedLight,
    PsProtectedTypeProtectedLight, PsProtectedTypeProtected,
    PsProtectedTypeProtectedLight, PsProtectedTypeProtected,
    PsProtectedTypeProtectedLight
  );
  PROTECTION_SIGNER: array [TProtectionLevel] of TPsProtectionSigner = (
    PsProtectedSignerWinTcb, PsProtectedSignerWindows, PsProtectedSignerWindows,
    PsProtectedSignerAntimalware, PsProtectedSignerLsa, PsProtectedSignerWinTcb,
    PsProtectedSignerCodeGen, PsProtectedSignerAuthenticode,
    PsProtectedSignerApp
  );
begin
  if (Win32Protection >= Low(TProtectionLevel)) and
    (Win32Protection <= High(TProtectionLevel)) then
  begin
    Result := NtxSuccess;
    NativeProtection :=  Byte(PROTECTION_TYPE[Win32Protection]) or
      (Byte(PROTECTION_SIGNER[Win32Protection]) shl PS_PROTECTED_SIGNER_SHIFT);
  end
  else if Win32Protection = PROTECTION_LEVEL_SAME then
    Result := NtxProcess.Query(NtxCurrentProcess, ProcessProtectionInformation,
      NativeProtection)
  else
  begin
    Result.Location := 'RtlxWin32ToNativeProtection';
    Result.Status := STATUS_INVALID_PARAMETER;
  end;
end;

function TPsAttributesRecord.Create;
var
  Count, j: Integer;
  Attribute: PPsAttribute;
begin
  // Always use Image Name, Client ID, and TEB address
  Count := 3;

  if Assigned(Options.hxToken) then
    Inc(Count);

  if Assigned(Options.hxParentProcess) then
    Inc(Count);

  if Assigned(Options.hxDebugPort) then
    Inc(Count);

  if Length(Options.HandleList) > 0 then
    Inc(Count);

  if Assigned(Options.hxJob) then
    Inc(Count);

  if HasAny(Options.ChildPolicy) then
    Inc(Count);

  if poLPAC in Options.Flags then
    Inc(Count);

  if HasAny(Options.PackageBreakaway) then
    Inc(Count);

  if poUseProtection in Options.Flags then
    Inc(Count);

  if poInheritConsole in Options.Flags then
    Inc(Count);

  if poUseSafeOpenPromptOriginClaim in Options.Flags then
    Inc(Count);

  Source := Options;
  IMemory(Buffer) := Auto.AllocateDynamic(TPsAttributeList.SizeOfCount(Count));
  Data.TotalLength := Buffer.Size;
  Attribute := @Data.Attributes[0];

  // Image name
  FImageName := Options.ApplicationNative;
  Attribute.Attribute := PS_ATTRIBUTE_IMAGE_NAME;
  Attribute.Size := StringSizeNoZero(FImageName);
  Pointer(Attribute.Value) := PWideChar(FImageName);
  Inc(Attribute);

  // Client ID
  Attribute.Attribute := PS_ATTRIBUTE_CLIENT_ID;
  Attribute.Size := SizeOf(TClientId);
  Pointer(Attribute.Value) := @FClientId;
  Inc(Attribute);

  // TEB address
  Attribute.Attribute := PS_ATTRIBUTE_TEB_ADDRESS;
  Attribute.Size := SizeOf(PTeb);
  Pointer(Attribute.Value) := @FTebAddress;
  Inc(Attribute);

  // Token
  if Assigned(Source.hxToken) then
  begin
    // Allow use of pseudo-handles
    hxExpandedToken := Options.hxToken;
    Result := NtxExpandToken(hxExpandedToken, TOKEN_ASSIGN_PRIMARY);

    if not Result.IsSuccess then
      Exit;

    Attribute.Attribute := PS_ATTRIBUTE_TOKEN;
    Attribute.Size := SizeOf(THandle);
    Attribute.Value := hxExpandedToken.Handle;
    Inc(Attribute);
  end;

  // Parent process
  if Assigned(Source.hxParentProcess) then
  begin
    Attribute.Attribute := PS_ATTRIBUTE_PARENT_PROCESS;
    Attribute.Size := SizeOf(THandle);
    Attribute.Value := Source.hxParentProcess.Handle;
    Inc(Attribute);
  end;

  // Debug port
  if Assigned(Source.hxDebugPort) then
  begin
    Attribute.Attribute := PS_ATTRIBUTE_DEBUG_PORT;
    Attribute.Size := SizeOf(THandle);
    Attribute.Value := Source.hxDebugPort.Handle;
    Inc(Attribute);
  end;

  // Handle list
  if Length(Source.HandleList) > 0 then
  begin
    SetLength(FHandleList, Length(Source.HandleList));

    for j := 0 to High(FHandleList) do
      FHandleList[j] := Source.HandleList[j].Handle;

    Attribute.Attribute := PS_ATTRIBUTE_HANDLE_LIST;
    Attribute.Size := SizeOf(THandle) * Length(FHandleList);
    Pointer(Attribute.Value) := Pointer(FHandleList);
    Inc(Attribute);
  end;

  // Job object
  if Assigned(Source.hxJob) then
  begin
    hJob := Source.hxJob.Handle;
    Attribute.Attribute := PS_ATTRIBUTE_JOB_LIST;
    Attribute.Size := SizeOf(THandle);
    Pointer(Attribute.Value) := @hJob;
    Inc(Attribute);
  end;

  // Child process policy
  if HasAny(Source.ChildPolicy) then
  begin
    Attribute.Attribute := PS_ATTRIBUTE_CHILD_PROCESS_POLICY;
    Attribute.Size := SizeOf(TProcessChildFlags);
    Pointer(Attribute.Value) := @Source.ChildPolicy;
    Inc(Attribute);
  end;

  // Low-privileged AppContainer
  if poLPAC in Options.Flags then
  begin
    PackagePolicy := PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT;
    Attribute.Attribute := PS_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY;
    Attribute.Size := SizeOf(TProcessAllPackagesFlags);
    Pointer(Attribute.Value) := @PackagePolicy;
    Inc(Attribute);
  end;

  // Package breakaway (aka Desktop App Policy
  if HasAny(Options.ChildPolicy) then
  begin
    Attribute.Attribute := PS_ATTRIBUTE_DESKTOP_APP_POLICY;
    Attribute.Size := SizeOf(TProcessDesktopAppFlags);
    Pointer(Attribute.Value) := @Options.PackageBreakaway;
    Inc(Attribute);
  end;

  // Process protection
  if poUseProtection in Options.Flags then
  begin
    Result := RtlxWin32ToNativeProtection(Options.Protection, PsProtection);

    if not Result.IsSuccess then
      Exit;

    Attribute.Attribute := PS_ATTRIBUTE_PROTECTION_LEVEL;
    Attribute.Size := SizeOf(TPsProtection);
    Attribute.Value := PsProtection;
    Inc(Attribute);
  end;

  // Std handle info
  if poInheritConsole in Options.Flags then
  begin
    if poUseStdHandles in Options.Flags then
      FStdHandleInfo.Flags := PS_STD_STATE_NEVER_DUPLICATE
    else
      FStdHandleInfo.Flags := PS_STD_STATE_REQUEST_DUPLICATE;

    FStdHandleInfo.StdHandleSubsystemType := IMAGE_SUBSYSTEM_WINDOWS_CUI;
    Attribute.Attribute := PS_ATTRIBUTE_STD_HANDLE_INFO;
    Attribute.Size := SizeOf(TPsStdHandleInfo);
    Pointer(Attribute.Value) := @FStdHandleInfo;
    Inc(Attribute);
  end;

  // Safe open prompt origin claim
  if poUseSafeOpenPromptOriginClaim in Options.Flags then
  begin
    SeSafePromptClaim := Default(TSeSafeOpenPromptResults);
    SeSafePromptClaim.Results := Options.SafeOpenPromptOriginClaimResult;
    SeSafePromptClaim.SetPath(Options.SafeOpenPromptOriginClaimPath);
    Attribute.Attribute := PS_ATTRIBUTE_SAFE_OPEN_PROMPT_ORIGIN_CLAIM;
    Attribute.Size := SizeOf(TSeSafeOpenPromptResults);
    Pointer(Attribute.Value) := @SeSafePromptClaim;
  end;

  Result := NtxSuccess;
end;

function TPsAttributesRecord.GetData;
begin
  Result := Buffer.Data;
end;

function RtlxDetectManifestAndSaveAddresses(
  const Options: TCreateProcessOptions;
  var Info: TProcessInfo
): TNtxStatus;
var
  Addresses: TProcessAddresses;
  hxSection: IHandle;
  ManifestRva: TMemory;
begin
  Result := NtxQueryAddressesProcess(Info.hxProcess, Addresses);

  if not Result.IsSuccess then
    Exit;

  // Save PEB
  if Assigned(Addresses.PebAddressNative) then
  begin
    Include(Info.ValidFields, piPebAddress);
    Info.PebAddressNative := Addresses.PebAddressNative;
  end;

  // Save WoW64 PEB
  if Assigned(Addresses.PebAddressWoW64) then
  begin
    Include(Info.ValidFields, piPebAddressWoW64);
    Info.PebAddressWoW64 := Addresses.PebAddressWoW64;
  end;

  // Save Image Base
  Include(Info.ValidFields, piImageBase);
  Info.ImageBaseAddress := Addresses.ImageBase;

  hxSection := nil;

  // Parse the file trying to locate the embedded manifest
  Result := RtlxFindManifestInFile(FileParameters.UseFileName(
    Options.ApplicationNative), ManifestRva);

  if Result.IsSuccess then
  begin
    // Convert RVA to VA and save the result
    Inc(PByte(ManifestRva.Address), UIntPtr(Info.ImageBaseAddress));
    Include(Info.ValidFields, piManifest);
    Info.Manifest := ManifestRva;
  end;
end;

{ Process Creation }

function ReferenceSecurityDescriptor(
  const ObjectAttributes: IObjectAttributes
): PSecurityDescriptor;
begin
  if Assigned(ObjectAttributes) and Assigned(ObjectAttributes.Security) then
    Result := ObjectAttributes.Security.Data
  else
    Result := nil;
end;

function RtlxCreateUserProcess;
var
  ProcessParams: IRtlUserProcessParameters;
  ProcessInfo: TRtlUserProcessInformation;
  ApplicationNative: String;
  ApplicationNativeStr: TNtUnicodeString;
  hxExpandedToken: IHandle;
begin
  Result := RtlxCreateProcessParameters(Options, ProcessParams);

  if not Result.IsSuccess then
    Exit;

  // Keep the string from the Options.ApplicationNative() call alive
  ApplicationNative := Options.ApplicationNative;
  Result := RtlxInitUnicodeString(ApplicationNativeStr, ApplicationNative);

  if not Result.IsSuccess then
    Exit;

  // Allow use of pseudo-tokens
  hxExpandedToken := Options.hxToken;
  Result := NtxExpandToken(hxExpandedToken, TOKEN_ASSIGN_PRIMARY);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlCreateUserProcess';

  if Assigned(Options.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if Assigned(Options.hxToken) then
  begin
    Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);
  end;

  Result.Status := RtlCreateUserProcess(
    ApplicationNativeStr,
    0, // Deprecated attributes
    ProcessParams.Data,
    ReferenceSecurityDescriptor(Options.ProcessAttributes),
    ReferenceSecurityDescriptor(Options.ThreadAttributes),
    HandleOrDefault(Options.hxParentProcess),
    poInheritHandles in Options.Flags,
    HandleOrDefault(Options.hxDebugPort),
    HandleOrDefault(hxExpandedToken),
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  // Capture the information about the new process
  Info.ValidFields := [piProcessID, piThreadID, piProcessHandle, piThreadHandle,
    piImageInformation];
  Info.ClientId := ProcessInfo.ClientId;
  Info.hxProcess := Auto.CaptureHandle(ProcessInfo.Process);
  Info.hxThread := Auto.CaptureHandle(ProcessInfo.Thread);
  Info.ImageInformation := ProcessInfo.ImageInformation;

  if (poDetectManifest in Options.Flags) then
    RtlxDetectManifestAndSaveAddresses(Options, Info);

  // Resume the process if necessary
  if not (poSuspended in Options.Flags) then
    NtxResumeThread(Info.hxThread);
end;

function RtlxCreateUserProcessEx;
var
  ProcessParams: IRtlUserProcessParameters;
  ProcessInfo: TRtlUserProcessInformation;
  ParamsEx: TRtlUserProcessExtendedParameters;
  ApplicationNative: String;
  ApplicationNativeStr: TNtUnicodeString;
  hxExpandedToken: IHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_RtlCreateUserProcessEx);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCreateProcessParameters(Options, ProcessParams);

  if not Result.IsSuccess then
    Exit;

  // Keep the string from the Options.ApplicationNative() call alive
  ApplicationNative := Options.ApplicationNative;
  Result := RtlxInitUnicodeString(ApplicationNativeStr, ApplicationNative);

  if not Result.IsSuccess then
    Exit;

  // Allow use of pseudo-tokens
  hxExpandedToken := Options.hxToken;
  Result := NtxExpandToken(hxExpandedToken, TOKEN_ASSIGN_PRIMARY);

  if not Result.IsSuccess then
    Exit;

  ParamsEx := Default(TRtlUserProcessExtendedParameters);
  ParamsEx.Version := RTL_USER_PROCESS_EXTENDED_PARAMETERS_VERSION;
  ParamsEx.ProcessSecurityDescriptor :=
    ReferenceSecurityDescriptor(Options.ProcessAttributes);
  ParamsEx.ThreadSecurityDescriptor :=
    ReferenceSecurityDescriptor(Options.ThreadAttributes);
  ParamsEx.ParentProcess := HandleOrDefault(Options.hxParentProcess);
  ParamsEx.TokenHandle := HandleOrDefault(Options.hxToken);
  ParamsEx.JobHandle := HandleOrDefault(Options.hxJob);
  ParamsEx.DebugPort := HandleOrDefault(Options.hxDebugPort);

  Result.Location := 'RtlCreateUserProcessEx';

  if Assigned(Options.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if Assigned(Options.hxToken) then
  begin
    Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);
  end;

  if Assigned(Options.hxJob) then
    Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_ASSIGN_PROCESS);

  Result.Status := RtlCreateUserProcessEx(
    ApplicationNativeStr,
    ProcessParams.Data,
    poInheritHandles in Options.Flags,
    @ParamsEx,
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  // Capture the information about the new process
  Info.ValidFields := [piProcessID, piThreadID, piProcessHandle, piThreadHandle,
    piImageInformation];
  Info.ClientId := ProcessInfo.ClientId;
  Info.hxProcess := Auto.CaptureHandle(ProcessInfo.Process);
  Info.hxThread := Auto.CaptureHandle(ProcessInfo.Thread);
  Info.ImageInformation := ProcessInfo.ImageInformation;

  if (poDetectManifest in Options.Flags) then
    RtlxDetectManifestAndSaveAddresses(Options, Info);

  // Resume the process if necessary
  if not (poSuspended in Options.Flags) then
    NtxResumeThread(Info.hxThread);
end;

function NtxCreateUserProcess;
var
  hProcess, hThread: THandle;
  ProcessFlags: TProcessCreateFlags;
  ThreadFlags: TThreadCreateFlags;
  ProcessParams: IRtlUserProcessParameters;
  CreateInfo: TPsCreateInfo;
  Attributes: TPsAttributesRecord;
  ProcessObjAttr, ThreadObjAttr: PObjectAttributes;
begin
  Info := Default(TProcessInfo);

  // Prepare Rtl parameters
  Result := RtlxCreateProcessParameters(Options, ProcessParams);

  if not Result.IsSuccess then
    Exit;

  // Prepare process object attributes
  Result := AttributesRefOrNil(ProcessObjAttr, Options.ProcessAttributes);

  if not Result.IsSuccess then
    Exit;

  // Prepare thread object attributes
  Result := AttributesRefOrNil(ThreadObjAttr, Options.ThreadAttributes);

  if not Result.IsSuccess then
    Exit;

  // Prepare PS attributes
  Result := Attributes.Create(Options);

  if not Result.IsSuccess then
    Exit;

  // Prepare flags
  ProcessFlags := 0;

  if poBreakawayFromJob in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_BREAKAWAY;

  if poForceBreakaway in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_FORCE_BREAKAWAY;

  if poInheritHandles in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_INHERIT_HANDLES;

  if poUseProtection in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_PROTECTED_PROCESS;

  ThreadFlags := 0;

  if poSuspended in Options.Flags then
    ThreadFlags := ThreadFlags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED;

  // Console inheritance
  if poInheritConsole in Options.Flags then
  begin
    if LdrxCheckDelayedImport(delayed_BaseGetConsoleReference).IsSuccess then
      ProcessParams.Data.ConsoleHandle := BaseGetConsoleReference
    else
      ProcessParams.Data.ConsoleHandle :=
        RtlGetCurrentPeb.ProcessParameters.ConsoleHandle;

    ProcessParams.Data.ProcessGroupID :=
      RtlGetCurrentPeb.ProcessParameters.ProcessGroupID;
  end;

  // Ask for us as much info as possible
  CreateInfo := Default(TPsCreateInfo);
  CreateInfo.Size := SizeOf(TPsCreateInfo);
  CreateInfo.State := PsCreateInitialState;
  CreateInfo.AdditionalFileAccess := Options.AdditionalFileAccess;
  CreateInfo.InitFlags :=
    PS_CREATE_INITIAL_STATE_WRITE_OUTPUT_ON_EXIT or
    PS_CREATE_INITIAL_STATE_IFEO_SKIP_DEBUGGER;

  if poDetectManifest in Options.Flags then
    CreateInfo.InitFlags := CreateInfo.InitFlags or
      PS_CREATE_INITIAL_STATE_DETECT_MANIFEST;

  Result.Location := 'NtCreateUserProcess';

  if Assigned(Options.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if Assigned(Options.hxToken) then
  begin
    Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);
  end;

  if Assigned(Options.hxJob) then
    Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_ASSIGN_PROCESS);

  if poForceBreakaway in Options.Flags then
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  Result.Status := NtCreateUserProcess(
    hProcess,
    hThread,
    AccessMaskOverride(MAXIMUM_ALLOWED, Options.ProcessAttributes),
    AccessMaskOverride(MAXIMUM_ALLOWED, Options.ThreadAttributes),
    ProcessObjAttr,
    ThreadObjAttr,
    ProcessFlags,
    ThreadFlags,
    ProcessParams.Data,
    CreateInfo,
    Attributes.Data
  );

  // Attach the stage that failed as an info class
  Result.LastCall.UsesInfoClass(CreateInfo.State, icPerform);

  if Result.IsSuccess then
  begin
    // Capture info about the process
    Info.ValidFields := Info.ValidFields + [piProcessID, piThreadID,
      piTebAddress];
    Info.ClientId := Attributes.ClientId;
    Info.TebAddress := Attributes.TebAddress;

    if hProcess <> 0 then
    begin
      Include(Info.ValidFields, piProcessHandle);
      Info.hxProcess := Auto.CaptureHandle(hProcess);
    end;

    if hThread <> 0 then
    begin
      Include(Info.ValidFields, piThreadHandle);
      Info.hxThread := Auto.CaptureHandle(hThread);
    end;
  end;

  // Make sure to either close or capture all handles
  case CreateInfo.State of
    PsCreateFailOnSectionCreate:
      if CreateInfo.FileHandleFail <> 0 then
      begin
        Include(Info.ValidFields, piFileHandle);
        Info.hxFile := Auto.CaptureHandle(CreateInfo.FileHandleFail);
      end;

    PsCreateFailExeName:
      if CreateInfo.IFEOKey <> 0 then
        NtxClose(CreateInfo.IFEOKey);

    PsCreateSuccess:
    begin
      // Capture more info about the process
      Info.ValidFields := Info.ValidFields + [piPebAddress,
        piUserProcessParameters, piUserProcessParametersFlags];
      Info.PebAddressNative := CreateInfo.PebAddressNative;
      Info.UserProcessParameters := CreateInfo.UserProcessParametersNative;
      Info.UserProcessParametersFlags := CreateInfo.CurrentParameterFlags;

      if CreateInfo.PebAddressWow64.Value <> 0 then
      begin
        Include(Info.ValidFields, piPebAddressWoW64);
        Info.PebAddressWoW64 := CreateInfo.PebAddressWow64;
      end;

      if BitTest(CreateInfo.OutputFlags and
        PS_CREATE_SUCCESS_MANIFEST_DETECTED) then
      begin
        Include(Info.ValidFields, piManifest);
        Info.Manifest.Address := CreateInfo.ManifestAddress;
        Info.Manifest.Size := CreateInfo.ManifestSize;
      end;

      if CreateInfo.FileHandleSuccess <> 0 then
      begin
        Include(Info.ValidFields, piFileHandle);
        Info.hxFile := Auto.CaptureHandle(CreateInfo.FileHandleSuccess);
      end;

      if CreateInfo.SectionHandle <> 0 then
      begin
        Include(Info.ValidFields, piSectionHandle);
        Info.hxSection := Auto.CaptureHandle(CreateInfo.SectionHandle);
      end;
    end;
  end;
end;

end.
