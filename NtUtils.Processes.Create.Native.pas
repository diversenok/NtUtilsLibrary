unit NtUtils.Processes.Create.Native;

{
  The module provides support for process creation via Native API.
}

interface

uses
  Ntapi.ntrtl, Ntapi.ntseapi, NtUtils, NtUtils.Processes.Create,
  DelphiUtils.AutoObjects;

type
  IRtlUserProcessParamers = IMemory<PRtlUserProcessParameters>;

// Allocate user process parameters
function RtlxCreateProcessParameters(
  const Options: TCreateProcessOptions;
  out xMemory: IRtlUserProcessParamers
): TNtxStatus;

// Create a new process via RtlCreateUserProcess
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoJob)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function RtlxCreateUserProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via RtlCreateUserProcessEx
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoJob)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function RtlxCreateUserProcessEx(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via NtCreateUserProcess
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoForceBreakaway)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoJob)]
[SupportedOption(spoHandleList)]
[SupportedOption(spoChildPolicy)]
[SupportedOption(spoLPAC)]
[SupportedOption(spoAdditinalFileAccess)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtxCreateUserProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ProcessThreadsApi,
  Ntapi.ntioapi, Ntapi.ntpebteb, NtUtils.Threads, NtUtils.Files,
  NtUtils.Objects, NtUtils.Ldr, NtUtils.Tokens;

{ Process Parameters & Attributes }

type
  TAutoUserProcessParams = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

procedure TAutoUserProcessParams.Release;
begin
  RtlDestroyProcessParameters(FData);
  inherited;
end;

function RtlxCreateProcessParameters;
var
  Buffer: PRtlUserProcessParameters;
  ApplicationStr, CommandLineStr, CurrentDirStr, DesktopStr: TNtUnicodeString;
begin
  // Note: do not inline these since the compiler reuses hidden variables
  ApplicationStr := TNtUnicodeString.From(Options.ApplicationWin32);
  CommandLineStr := TNtUnicodeString.From(Options.CommandLine);
  CurrentDirStr := TNtUnicodeString.From(Options.CurrentDirectory);
  DesktopStr := TNtUnicodeString.From(Options.Desktop);

  Result.Location := 'RtlCreateProcessParametersEx';
  Result.Status := RtlCreateProcessParametersEx(
    Buffer,
    ApplicationStr,
    nil, // DllPath
    RefNtStrOrNil(CurrentDirStr),
    @CommandLineStr,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    nil, // WindowTitile
    RefNtStrOrNil(DesktopStr),
    nil, // ShellInfo
    nil, // RuntimeData
    RTL_USER_PROC_PARAMS_NORMALIZED
  );

  if not Result.IsSuccess then
    Exit;

  { TODO: there is something wrong string marshling within the process
    parameters block. NtCreateUserProcess parses it correctly and then
    allocates a correct reconstructed version within the target.
    NtCreateProcessEx, on the other hand, requires manually writing it, and with
    the block we get, the tager process often crashes during initialization.
    Manually zeroing out empty strings seems to at least mitigate the problem
    with console applcations. }
  Buffer.DLLPath := Default(TNtUnicodeString);
  Buffer.WindowTitle := Default(TNtUnicodeString);
  Buffer.ShellInfo := Default(TNtUnicodeString);
  Buffer.RuntimeData := Default(TNtUnicodeString);

  IMemory(xMemory) := TAutoUserProcessParams.Capture(Buffer,
    Buffer.MaximumLength + Buffer.EnvironmentSize);

  // Adjust window mode flags
  if poUseWindowMode in Options.Flags then
  begin
    xMemory.Data.WindowFlags := xMemory.Data.WindowFlags or STARTF_USESHOWWINDOW;
    xMemory.Data.ShowWindowFlags := Cardinal(Options.WindowMode);
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
    hxExpandedToken: IHandle;
    hJob: THandle;
    PackagePolicy: TProcessAllPackagesFlags;
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

  if Length(Options.HandleList) > 0 then
    Inc(Count);

  if Assigned(Options.hxJob) then
    Inc(Count);

  if HasAny(Options.ChildPolicy) then
    Inc(Count);

  if poLPAC in Options.Flags then
    Inc(Count);

  Source := Options;
  IMemory(Buffer) := Auto.AllocateDynamic(TPsAttributeList.SizeOfCount(Count));
  Data.TotalLength := Buffer.Size;
  Attribute := @Data.Attributes[0];

  // Image name
  FImageName := Options.ApplicationNative;
  Attribute.Attribute := PS_ATTRIBUTE_IMAGE_NAME;
  Attribute.Size := SizeOf(WideChar) * Length(FImageName);
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
  end;

  Result.Status := STATUS_SUCCESS;
end;

function TPsAttributesRecord.GetData;
begin
  Result := Buffer.Data;
end;

{ Process Creation }

function RtlxCreateUserProcess;
var
  ProcessParams: IRtlUserProcessParamers;
  ProcessInfo: TRtlUserProcessInformation;
  hxExpandedToken: IHandle;
begin
  Result := RtlxCreateProcessParameters(Options, ProcessParams);

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
    TNtUnicodeString.From(Options.ApplicationNative),
    OBJ_CASE_INSENSITIVE,
    ProcessParams.Data,
    Auto.RefOrNil<PSecurityDescriptor>(Options.ProcessSecurity),
    Auto.RefOrNil<PSecurityDescriptor>(Options.ThreadSecurity),
    HandleOrDefault(Options.hxParentProcess),
    poInheritHandles in Options.Flags,
    0,
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

  // Resume the process if necessary
  if not (poSuspended in Options.Flags) then
    NtxResumeThread(ProcessInfo.Thread);
end;

function RtlxCreateUserProcessEx;
var
  ProcessParams: IRtlUserProcessParamers;
  ProcessInfo: TRtlUserProcessInformation;
  ParamsEx: TRtlUserProcessExtendedParameters;
  hxExpandedToken: IHandle;
begin
  Result := LdrxCheckNtDelayedImport('RtlCreateUserProcessEx');

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCreateProcessParameters(Options, ProcessParams);

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
    Auto.RefOrNil<PSecurityDescriptor>(Options.ProcessSecurity);
  ParamsEx.ThreadSecurityDescriptor :=
    Auto.RefOrNil<PSecurityDescriptor>(Options.ThreadSecurity);
  ParamsEx.ParentProcess := HandleOrDefault(Options.hxParentProcess);
  ParamsEx.TokenHandle := HandleOrDefault(Options.hxToken);
  ParamsEx.JobHandle := HandleOrDefault(Options.hxJob);

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
    TNtUnicodeString.From(Options.ApplicationNative),
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

  // Resume the process if necessary
  if not (poSuspended in Options.Flags) then
    NtxResumeThread(ProcessInfo.Thread);
end;

function NtxCreateUserProcess;
var
  hProcess, hThread: THandle;
  ProcessObjectAttributes, ThreadObjectAttributes: IObjectAttributes;
  ProcessFlags: TProcessCreateFlags;
  ThreadFlags: TThreadCreateFlags;
  ProcessParams: IRtlUserProcessParamers;
  CreateInfo: TPsCreateInfo;
  Attributes: TPsAttributesRecord;
begin
  Info := Default(TProcessInfo);

  // Prepate Rtl parameters
  Result := RtlxCreateProcessParameters(Options, ProcessParams);

  if not Result.IsSuccess then
    Exit;

  // Prepare attributes
  Result := Attributes.Create(Options);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Options.ProcessSecurity) then
    ProcessObjectAttributes := AttributeBuilder.UseSecurity(
      Options.ProcessSecurity)
  else
    ProcessObjectAttributes := nil;

  if Assigned(Options.ThreadSecurity) then
    ThreadObjectAttributes := AttributeBuilder.UseSecurity(
      Options.ThreadSecurity)
  else
    ThreadObjectAttributes := nil;

  // Preapare flags
  ProcessFlags := 0;

  if poBreakawayFromJob in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_BREAKAWAY;

  if poForceBreakaway in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_FORCE_BREAKAWAY;

  if poInheritHandles in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_INHERIT_HANDLES;

  ThreadFlags := 0;

  if poSuspended in Options.Flags then
    ThreadFlags := ThreadFlags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED;

  // Ask for us as much info as possible
  CreateInfo := Default(TPsCreateInfo);
  CreateInfo.Size := SizeOf(TPsCreateInfo);
  CreateInfo.State := PsCreateInitialState;
  CreateInfo.AdditionalFileAccess := Options.AdditionalFileAccess;
  CreateInfo.InitFlags :=
    PS_CREATE_INTIAL_STATE_WRITE_OUTPUT_ON_EXIT or
    PS_CREATE_INTIAL_STATE_DETECT_MANIFEST or
    PS_CREATE_INTIAL_STATE_IFEO_SKIP_DEBUGGER;

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
    MAXIMUM_ALLOWED,
    MAXIMUM_ALLOWED,
    AttributesRefOrNil(ProcessObjectAttributes),
    AttributesRefOrNil(ThreadObjectAttributes),
    ProcessFlags,
    ThreadFlags,
    ProcessParams.Data,
    CreateInfo,
    Attributes.Data
  );

  // Attach the stage that failed as an info class
  if not (CreateInfo.State in [PsCreateInitialState, PsCreateSuccess]) then
    Result.LastCall.UsesInfoClass(CreateInfo.State, icPerform);

  if Result.IsSuccess then
  begin
    // Capture info about the process
    Info.ValidFields := [piProcessID, piThreadID, piProcessHandle,
      piThreadHandle, piTebAddress];

    Info.ClientId := Attributes.ClientId;
    Info.hxProcess := Auto.CaptureHandle(hProcess);
    Info.hxThread := Auto.CaptureHandle(hThread);
    Info.TebAddress := Attributes.TebAddress;
  end;

  // Make sure to either close or capture all handles
  case CreateInfo.State of
    PsCreateFailOnFileOpen:
      if CreateInfo.FileHandleFail <> 0 then
        NtxClose(CreateInfo.FileHandleFail);

    PsCreateFailExeName:
      if CreateInfo.IFEOKey <> 0 then
        NtxClose(CreateInfo.IFEOKey);

    PsCreateSuccess:
    begin
      // Capture more info about thr process
      Info.ValidFields := Info.ValidFields + [piFileHandle, piSectionHandle,
        piPebAddress, piUserProcessParameters, piUserProcessParametersFlags];
      Info.PebAddressNative := CreateInfo.PebAddressNative;
      Info.hxFile := Auto.CaptureHandle(CreateInfo.FileHandleSuccess);
      Info.hxSection := Auto.CaptureHandle(CreateInfo.SectionHandle);
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
        // TODO: suppress when IMAGE_DLLCHARACTERISTICS_NO_ISOLATION is set
        Include(Info.ValidFields, piManifest);
        Info.Manifest.Address := CreateInfo.ManifestAddress;
        Info.Manifest.Size := CreateInfo.ManifestSize;
      end;
    end;
  end;
end;

end.
