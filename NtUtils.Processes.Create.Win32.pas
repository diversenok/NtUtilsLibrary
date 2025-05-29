unit NtUtils.Processes.Create.Win32;

{
  The module provides support for process creation via a Win32 API.
}

interface

uses
  Ntapi.ntseapi, NtUtils, NtUtils.Processes.Create;

// Create a new process via CreateProcessAsUserW
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoForceBreakaway)]
[SupportedOption(spoInheritConsole)]
[SupportedOption(spoRunAsInvoker)]
[SupportedOption(spoIgnoreElevation)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoObjectInherit)]
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
[SupportedOption(spoPriorityClass)]
[SupportedOption(spoMitigations)]
[SupportedOption(spoChildPolicy)]
[SupportedOption(spoLPAC)]
[SupportedOption(spoAppContainer)]
[SupportedOption(spoPackage)]
[SupportedOption(spoPackageBreakaway)]
[SupportedOption(spoProtection)]
[SupportedOption(spoSafeOpenPromptOriginClaim)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function AdvxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via CreateProcessWithTokenW
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoWindowTitle)]
[SupportedOption(spoStdHandles)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoPriorityClass)]
[SupportedOption(spoLogonFlags)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
function AdvxCreateProcessWithToken(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via CreateProcessWithLogonW
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoWindowTitle)]
[SupportedOption(spoStdHandles)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoPriorityClass)]
[SupportedOption(spoLogonFlags)]
[SupportedOption(spoCredentials, omRequired)]
function AdvxCreateProcessWithLogon(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.ntpebteb, Ntapi.ntobapi,
  Ntapi.WinBase,Ntapi.WinUser, Ntapi.ProcessThreadsApi, Ntapi.ntdbg,
  Ntapi.ntldr, NtUtils.Objects, NtUtils.Tokens, NtUtils.Processes.Info,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

 { Process-thread attributes }

type
  IPtAttributes = IMemory<PProcThreadAttributeList>;

  TPtAutoMemory = class (TAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
    Options: TCreateProcessOptions;
    hParent: THandle;
    HandleList: TArray<THandle>;
    Capabilities: TArray<TSidAndAttributes>;
    Security: TSecurityCapabilities;
    AllAppPackages: TProcessAllPackagesFlags;
    hJob: THandle;
    ExtendedFlags: TProcExtendedFlag;
    MitigationValues: array [0..1] of UInt64;
    ChildPolicy: TProcessChildFlags;
    Protection: TProtectionLevel;
    SeSafePromptClaim: TSeSafeOpenPromptResults;
    Initialized: Boolean;
    procedure Release; override;
  end;

procedure TPtAutoMemory.Release;
begin
  if Assigned(FData) and Initialized then
    DeleteProcThreadAttributeList(FData);

  // Call the inherited memory deallocation
  inherited;
end;

function RtlxpUpdateProcThreadAttribute(
  [in, out] AttributeList: PProcThreadAttributeList;
  Attribute: NativeUInt;
  const Value;
  Size: NativeUInt
): TNtxStatus;
begin
  Result.Location := 'UpdateProcThreadAttribute';
  Result.LastCall.UsesInfoClass(TProcThreadAttributeNum(Attribute and
    PROC_THREAD_ATTRIBUTE_NUMBER), icSet);
  Result.Win32Result := UpdateProcThreadAttribute(AttributeList, 0, Attribute,
    @Value, Size, nil, nil);
end;

procedure ConvertMitigationPolicyToWin32(
  const Mitigations: TCreateProcessMitigations;
  out Value1: UInt64;
  out Value2: UInt64
);
begin
  Value1 := 0;
  Value2 := 0;

  // Value 1

  case Mitigations[PS_MITIGATION_OPTION_NX] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_DEP_ENABLE;
    PS_MITIGATION_OPTION_SPECIAL:
      Value1 := Value1 or MITIGATION_POLICY_DEP_ATL_THUNK_ENABLE;
  end;

  case Mitigations[PS_MITIGATION_OPTION_SEHOP] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_SEHOP_ENABLE;
  end;

  case Mitigations[PS_MITIGATION_OPTION_FORCE_RELOCATE_IMAGES] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value1 := Value1 or MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_ON_REQ_RELOCS;
  end;

  case Mitigations[PS_MITIGATION_OPTION_HEAP_TERMINATE] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_HEAP_TERMINATE_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_HEAP_TERMINATE_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_BOTTOM_UP_ASLR] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_BOTTOM_UP_ASLR_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_BOTTOM_UP_ASLR_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_HIGH_ENTROPY_ASLR] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_HIGH_ENTROPY_ASLR_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_HIGH_ENTROPY_ASLR_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_STRICT_HANDLE_CHECKS] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_STRICT_HANDLE_CHECKS_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_STRICT_HANDLE_CHECKS_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_WIN32K_SYSTEM_CALL_DISABLE] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_EXTENSION_POINT_DISABLE] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_EXTENSION_POINT_DISABLE_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_EXTENSION_POINT_DISABLE_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_PROHIBIT_DYNAMIC_CODE] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value1 := Value1 or MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON_ALLOW_OPT_OUT;
  end;

  case Mitigations[PS_MITIGATION_OPTION_CONTROL_FLOW_GUARD] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_CONTROL_FLOW_GUARD_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_CONTROL_FLOW_GUARD_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value1 := Value1 or MITIGATION_POLICY_CONTROL_FLOW_GUARD_EXPORT_SUPPRESSION;
  end;

  case Mitigations[PS_MITIGATION_OPTION_BLOCK_NON_MICROSOFT_BINARIES] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value1 := Value1 or MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALLOW_STORE;
  end;

  case Mitigations[PS_MITIGATION_OPTION_FONT_DISABLE] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_FONT_DISABLE_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_FONT_DISABLE_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_IMAGE_LOAD_NO_REMOTE] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_IMAGE_LOAD_NO_REMOTE_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_IMAGE_LOAD_NO_REMOTE_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_IMAGE_LOAD_NO_LOW_LABEL] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_IMAGE_LOAD_PREFER_SYSTEM32] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value1 := Value1 or MITIGATION_POLICY_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value1 := Value1 or MITIGATION_POLICY_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_OFF;
  end;

  // Value 2

  case Mitigations[PS_MITIGATION_OPTION_LOADER_INTEGRITY_CONTINUITY] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value2 := Value2 or MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_AUDIT;
  end;

  case Mitigations[PS_MITIGATION_OPTION_STRICT_CONTROL_FLOW_GUARD] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_STRICT_CONTROL_FLOW_GUARD_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_STRICT_CONTROL_FLOW_GUARD_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_MODULE_TAMPERING_PROTECTION] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value2 := Value2 or MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_NOINHERIT;
  end;

  case Mitigations[PS_MITIGATION_OPTION_RESTRICT_INDIRECT_BRANCH_PREDICTION] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_RESTRICT_INDIRECT_BRANCH_PREDICTION_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_RESTRICT_INDIRECT_BRANCH_PREDICTION_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_SPECULATIVE_STORE_BYPASS_DISABLE] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_SPECULATIVE_STORE_BYPASS_DISABLE_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_SPECULATIVE_STORE_BYPASS_DISABLE_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_CET_USER_SHADOW_STACKS] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_CET_USER_SHADOW_STACKS_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_CET_USER_SHADOW_STACKS_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value2 := Value2 or MITIGATION_POLICY2_CET_USER_SHADOW_STACKS_STRICT_MODE;
  end;

  case Mitigations[PS_MITIGATION_OPTION_USER_CET_SET_CONTEXT_IP_VALIDATION] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_USER_CET_SET_CONTEXT_IP_VALIDATION_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_USER_CET_SET_CONTEXT_IP_VALIDATION_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value2 := Value2 or MITIGATION_POLICY2_USER_CET_SET_CONTEXT_IP_VALIDATION_RELAXED_MODE;
  end;

  case Mitigations[PS_MITIGATION_OPTION_BLOCK_NON_CET_BINARIES] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_BLOCK_NON_CET_BINARIES_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_BLOCK_NON_CET_BINARIES_ALWAYS_OFF;
    PS_MITIGATION_OPTION_SPECIAL:
      Value2 := Value2 or MITIGATION_POLICY2_BLOCK_NON_CET_BINARIES_NON_EHCONT;
  end;

  case Mitigations[PS_MITIGATION_OPTION_XTENDED_CONTROL_FLOW_GUARD] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_XTENDED_CONTROL_FLOW_GUARD_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_XTENDED_CONTROL_FLOW_GUARD_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_CET_DYNAMIC_APIS_OUT_OF_PROC_ONLY] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_CET_DYNAMIC_APIS_OUT_OF_PROC_ONLY_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_CET_DYNAMIC_APIS_OUT_OF_PROC_ONLY_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_RESTRICT_CORE_SHARING] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_RESTRICT_CORE_SHARING_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_RESTRICT_CORE_SHARING_ALWAYS_OFF;
  end;

  case Mitigations[PS_MITIGATION_OPTION_FSCTL_SYSTEM_CALL_DISABLE] of
    PS_MITIGATION_OPTION_ALWAYS_ON:
      Value2 := Value2 or MITIGATION_POLICY2_FSCTL_SYSTEM_CALL_DISABLE_ALWAYS_ON;
    PS_MITIGATION_OPTION_ALWAYS_OFF:
      Value2 := Value2 or MITIGATION_POLICY2_FSCTL_SYSTEM_CALL_DISABLE_ALWAYS_OFF;
  end;
end;

function AllocPtAttributes(
  const Options: TCreateProcessOptions;
  out xMemory: IPtAttributes
): TNtxStatus;
var
  PtAttributes: TPtAutoMemory;
  Required: NativeUInt;
  MitigationValues: array [0..1] of UInt64;
  Count: Integer;
  i: Integer;
begin
  // Count the applied attributes
  Count := 0;

  if Assigned(Options.hxParentProcess) then
    Inc(Count);

  ConvertMitigationPolicyToWin32(Options.Mitigations, MitigationValues[0],
    MitigationValues[1]);

  if (MitigationValues[0] <> 0) or (MitigationValues[1] <> 0) then
    Inc(Count);

  if HasAny(Options.ChildPolicy) then
    Inc(Count);

  if Length(Options.HandleList) > 0 then
    Inc(Count);

  if Assigned(Options.AppContainer) then
    Inc(Count);

  if poLPAC in Options.Flags then
    Inc(Count);

  if Options.PackageName <> '' then
    Inc(Count);

  if HasAny(Options.PackageBreakaway) then
    Inc(Count);

  if Assigned(Options.hxJob) then
    Inc(Count);

  if [poIgnoreElevation, poForceBreakaway] * Options.Flags <> [] then
    Inc(Count);

  if poUseProtection in Options.Flags then
    Inc(Count);

  if poUseSafeOpenPromptOriginClaim in Options.Flags then
    Inc(Count);

  if Count = 0 then
  begin
    xMemory := nil;
    Exit(NtxSuccess);
  end;

  // Determine the required size
  Result.Location := 'InitializeProcThreadAttributeList';
  Result.Win32Result := InitializeProcThreadAttributeList(nil, Count, 0,
    Required);

  if Result.Status <> STATUS_BUFFER_TOO_SMALL then
    Exit;

  // Allocate and initialize
  PtAttributes := TPtAutoMemory.Allocate(Required);
  IMemory(xMemory) := PtAttributes;
  Result.Win32Result := InitializeProcThreadAttributeList(xMemory.Data, Count,
    0, Required);

  // NOTE: Since ProcThreadAttributeList stores pointers instead of the actual
  // data, we need to make sure it does not go anywhere.

  if Result.IsSuccess then
    PtAttributes.Initialized := True
  else
    Exit;

  // Prolong lifetime of the options
  PtAttributes.Options := Options;

  // Parent process
  if Assigned(Options.hxParentProcess) then
  begin
    PtAttributes.hParent := Options.hxParentProcess.Handle;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, PtAttributes.hParent,
      SizeOf(THandle));

    if not Result.IsSuccess then
      Exit;
  end;

  // Mitigation policies
  if (MitigationValues[0] <> 0) or (MitigationValues[1] <> 0) then
  begin
    PtAttributes.MitigationValues[0] := MitigationValues[0];
    PtAttributes.MitigationValues[1] := MitigationValues[1];

    // The size might be 32, 64, or 128 bits
    if MitigationValues[1] = 0 then
    begin
      if MitigationValues[0] and $FFFFFFFF00000000 <> 0 then
        Required := SizeOf(UInt64)
      else
        Required := SizeOf(Cardinal);
    end
    else
      Required := 2 * SizeOf(UInt64);

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY,
      PtAttributes.MitigationValues, Required);

    if not Result.IsSuccess then
      Exit;
  end;

  // Child process policy
  if HasAny(Options.ChildPolicy) then
  begin
    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY,
      PtAttributes.Options.ChildPolicy, SizeOf(Cardinal));

    if not Result.IsSuccess then
      Exit;
  end;

  // Inherited handle list
  if Length(Options.HandleList) > 0 then
  begin
    SetLength(PtAttributes.HandleList, Length(Options.HandleList));

    for i := 0 to High(Options.HandleList) do
      PtAttributes.HandleList[i] := Options.HandleList[i].Handle;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_HANDLE_LIST, PtAttributes.HandleList,
      SizeOf(THandle) * Length(Options.HandleList));

    if not Result.IsSuccess then
      Exit;
  end;

  // AppContainer
  if Assigned(Options.AppContainer) then
  begin
    with PtAttributes.Security do
    begin
      AppContainerSid := Options.AppContainer.Data;
      CapabilityCount := Length(Options.Capabilities);

      SetLength(PtAttributes.Capabilities, Length(Options.Capabilities));
      for i := 0 to High(Options.Capabilities) do
      begin
        PtAttributes.Capabilities[i].Sid := Options.Capabilities[i].Sid.Data;
        PtAttributes.Capabilities[i].Attributes := Options.Capabilities[i].
          Attributes;
      end;

      if Length(Options.Capabilities) > 0 then
        Capabilities := Pointer(@PtAttributes.Capabilities[0])
      else
        Capabilities := nil;
    end;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES, PtAttributes.Security,
      SizeOf(TSecurityCapabilities));

    if not Result.IsSuccess then
      Exit;
  end;

  // Low privileged AppContainer
  if poLPAC in Options.Flags then
  begin
    PtAttributes.AllAppPackages :=
      PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY,
      PtAttributes.AllAppPackages, SizeOf(TProcessAllPackagesFlags));

    if not Result.IsSuccess then
      Exit;
  end;

  // Package name
  if Options.PackageName <> '' then
  begin
    Result := RtlxpUpdateProcThreadAttribute(
      xMemory.Data,
      PROC_THREAD_ATTRIBUTE_PACKAGE_NAME,
      PWideChar(PtAttributes.Options.PackageName)^,
      StringSizeNoZero(PtAttributes.Options.PackageName)
    );

    if not Result.IsSuccess then
      Exit;
  end;

  // Package breakaway (aka Desktop App Policy)
  if HasAny(Options.PackageBreakaway) then
  begin
    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_DESKTOP_APP_POLICY,
      PtAttributes.Options.PackageBreakaway, SizeOf(TProcessDesktopAppFlags));

    if not Result.IsSuccess then
      Exit;
  end;

  // Job list
  if Assigned(Options.hxJob) then
  begin
    PtAttributes.hJob := Options.hxJob.Handle;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_JOB_LIST, PtAttributes.hJob, SizeOf(THandle));

    if not Result.IsSuccess then
      Exit;
  end;

  // Extended attributes
  if [poIgnoreElevation, poForceBreakaway] * Options.Flags <> [] then
  begin
    PtAttributes.ExtendedFlags := 0;

    if poIgnoreElevation in Options.Flags then
      PtAttributes.ExtendedFlags := PtAttributes.ExtendedFlags or
        EXTENDED_PROCESS_CREATION_FLAG_FORCELUA;

    if poForceBreakaway in Options.Flags then
      PtAttributes.ExtendedFlags := PtAttributes.ExtendedFlags or
        EXTENDED_PROCESS_CREATION_FLAG_FORCE_BREAKAWAY;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_EXTENDED_FLAGS, PtAttributes.ExtendedFlags,
      SizeOf(TProcExtendedFlag));

    if not Result.IsSuccess then
      Exit;
  end;

  // Protection
  if poUseProtection in Options.Flags then
  begin
    PtAttributes.Protection := Options.Protection;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_PROTECTION_LEVEL, PtAttributes.Protection,
      SizeOf(TProtectionLevel));

    if not Result.IsSuccess then
      Exit;
  end;

  // Safe open prompt origin claim
  if poUseSafeOpenPromptOriginClaim in Options.Flags then
  begin
    PtAttributes.SeSafePromptClaim.Results :=
      Options.SafeOpenPromptOriginClaimResult;
    PtAttributes.SeSafePromptClaim.SetPath(Options.SafeOpenPromptOriginClaimPath);

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_SAFE_OPEN_PROMPT_ORIGIN_CLAIM,
      PtAttributes.SeSafePromptClaim, SizeOf(TSeSafeOpenPromptResults));

    if not Result.IsSuccess then
      Exit;
  end;
end;

{ Startup info preparation and supplementary routines }

procedure PrepareStartupInfo(
  out SI: TStartupInfoW;
  out CreationFlags: TProcessCreateFlags;
  const Options: TCreateProcessOptions
);
begin
  SI := Default(TStartupInfoW);
  SI.cb := SizeOf(SI);
  CreationFlags := 0;

  SI.Desktop := RefStrOrNil(Options.Desktop);

  // Suspended state
  if poSuspended in Options.Flags then
    CreationFlags := CreationFlags or CREATE_SUSPENDED;

  // Job escaping
  if poBreakawayFromJob in Options.Flags then
    CreationFlags := CreationFlags or CREATE_BREAKAWAY_FROM_JOB;

  // Console
  if not (poInheritConsole in Options.Flags) then
    CreationFlags := CreationFlags or CREATE_NEW_CONSOLE;

  // Environment
  if Assigned(Options.Environment) then
    CreationFlags := CreationFlags or CREATE_UNICODE_ENVIRONMENT;

  // Window show mode
  if poUseWindowMode in Options.Flags then
  begin
    SI.ShowWindow := TShowMode16(Word(Options.WindowMode));
    SI.Flags := SI.Flags or STARTF_USESHOWWINDOW;
  end;

  // Window title
  if (poForceWindowTitle in Options.Flags) or (Options.WindowTitle <> '') then
    SI.Title := PWideChar(Options.WindowTitle);

  // Standard I/O handles
  if poUseStdHandles in Options.Flags then
  begin
    SI.Flags := SI.Flags or STARTF_USESTDHANDLES;
    SI.hStdInput := HandleOrDefault(Options.hxStdInput);
    SI.hStdOutput := HandleOrDefault(Options.hxStdOutput);
    SI.hStdError := HandleOrDefault(Options.hxStdError);
  end;

  // Process protection
  if poUseProtection in Options.Flags then
    CreationFlags := CreationFlags or CREATE_PROTECTED_PROCESS;

  // Priority class
  case Options.PriorityClass of
    PROCESS_PRIORITY_CLASS_IDLE:
      CreationFlags := CreationFlags or IDLE_PRIORITY_CLASS;
    PROCESS_PRIORITY_CLASS_NORMAL:
      CreationFlags := CreationFlags or NORMAL_PRIORITY_CLASS;
    PROCESS_PRIORITY_CLASS_HIGH:
      CreationFlags := CreationFlags or HIGH_PRIORITY_CLASS;
    PROCESS_PRIORITY_CLASS_REALTIME:
      CreationFlags := CreationFlags or REALTIME_PRIORITY_CLASS;
    PROCESS_PRIORITY_CLASS_BELOW_NORMAL:
      CreationFlags := CreationFlags or BELOW_NORMAL_PRIORITY_CLASS;
    PROCESS_PRIORITY_CLASS_ABOVE_NORMAL:
      CreationFlags := CreationFlags or ABOVE_NORMAL_PRIORITY_CLASS;
  end;
end;

{ Public functions }

function AdvxCreateProcess;
var
  CreationFlags: TProcessCreateFlags;
  ProcessSA, ThreadSA: TSecurityAttributes;
  hxExpandedToken: IHandle;
  CommandLine: String;
  SI: TStartupInfoExW;
  PTA: IPtAttributes;
  ProcessInfo: TProcessInformation;
  RunAsInvokerReverter, DebugPortReverter: IAutoReleasable;
  hOldDebugPort: THandle;
begin
  Info := Default(TProcessInfo);
  PrepareStartupInfo(SI.StartupInfo, CreationFlags, Options);

  // Prepare process-thread attribute list
  Result := AllocPtAttributes(Options, PTA);

  if not Result.IsSuccess then
    Exit;

  if Assigned(PTA) then
  begin
    // Use the -Ex version to include attributes
    SI.StartupInfo.cb := SizeOf(TStartupInfoExW);
    SI.AttributeList := PTA.Data;
    CreationFlags := CreationFlags or EXTENDED_STARTUPINFO_PRESENT;
  end;

  // Allow using pseudo-tokens
  hxExpandedToken := Options.hxToken;
  Result := NtxExpandToken(hxExpandedToken, TOKEN_CREATE_PROCESS);

  if not Result.IsSuccess then
    Exit;

  // Allow running as invoker
  Result := RtlxApplyCompatLayer(poRunAsInvokerOn in Options.Flags,
    poRunAsInvokerOff in Options.Flags, RunAsInvokerReverter);

  if not Result.IsSuccess then
    Exit;

  // Select the debug object
  if Assigned(Options.hxDebugPort) then
  begin
    CreationFlags := CreationFlags or DEBUG_PROCESS;
    hOldDebugPort := DbgUiGetThreadDebugObject;
    DbgUiSetThreadDebugObject(Options.hxDebugPort.Handle);

    DebugPortReverter := Auto.Delay(
      procedure
      begin
        // Revert the change later
        DbgUiSetThreadDebugObject(hOldDebugPort);
      end
    );
  end
  else
    hOldDebugPort := 0;

  // CreateProcess needs the command line to be in writable memory
  CommandLine := Options.CommandLine;
  UniqueString(CommandLine);

  Result.Location := 'CreateProcessAsUserW';

  if Assigned(Options.hxToken) then
  begin
    Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_CREATE_PROCESS);
  end;

  if Assigned(Options.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if Assigned(Options.hxJob) then
    Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_ASSIGN_PROCESS);

  if poForceBreakaway in Options.Flags then
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  Result.Win32Result := CreateProcessAsUserW(
    HandleOrDefault(hxExpandedToken),
    RefStrOrNil(Options.ApplicationWin32),
    RefStrOrNil(CommandLine),
    ReferenceSecurityAttributes(ProcessSA, Options.ProcessAttributes),
    ReferenceSecurityAttributes(ThreadSA, Options.ThreadAttributes),
    poInheritHandles in Options.Flags,
    CreationFlags,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    SI,
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  Info.ValidFields := Info.ValidFields + [piProcessId, piThreadId,
    piProcessHandle, piThreadHandle];
  Info.ClientId.UniqueProcess := ProcessInfo.ProcessId;
  Info.ClientId.UniqueThread := ProcessInfo.ThreadId;
  Info.hxProcess := Auto.CaptureHandle(ProcessInfo.hProcess);
  Info.hxThread := Auto.CaptureHandle(ProcessInfo.hThread);
end;

function RtlxpAdjustProcessId(
  out Reverter: IAutoReleasable;
  const hxTargetProcess: IHandle
): TNtxStatus;
var
  Info: TProcessBasicInformation;
  OldPid: TProcessId;
begin
  Reverter := nil;
  Result := NtxProcess.Query(hxTargetProcess, ProcessBasicInformation, Info);

  if not Result.IsSuccess then
    Exit;

  if Info.UniqueProcessID = NtCurrentTeb.ClientID.UniqueProcess then
    Exit;

  // Swap the value in TEB
  OldPid := NtCurrentTeb.ClientID.UniqueProcess;
  NtCurrentTeb.ClientID.UniqueProcess := Info.UniqueProcessID;

  Reverter := Auto.Delay(
    procedure
    begin
      // Restore it back later
      NtCurrentTeb.ClientID.UniqueProcess := OldPid;
    end
  );
end;

procedure RtlxpCaptureReparentedHandles(
  const hxParentProcess: IHandle;
  var ProcessInfo: TProcessInformation;
  var Info: TProcessInfo
);
begin
  if not Assigned(hxParentProcess) then
  begin
    Info.ValidFields := Info.ValidFields + [piProcessHandle, piThreadHandle];
    Info.hxProcess := Auto.CaptureHandle(ProcessInfo.hProcess);
    Info.hxThread := Auto.CaptureHandle(ProcessInfo.hThread);
    Exit;
  end;

  // Duplicate process handle from the new parent
  if NtxDuplicateHandleFrom(hxParentProcess, ProcessInfo.hProcess,Info.hxProcess,
    0, 0, DUPLICATE_SAME_ACCESS or DUPLICATE_CLOSE_SOURCE).IsSuccess then
    Include(Info.ValidFields, piProcessHandle);

  // Duplicate thread handle from the parent
  if NtxDuplicateHandleFrom(hxParentProcess, ProcessInfo.hThread, Info.hxThread,
    0, 0, DUPLICATE_SAME_ACCESS or DUPLICATE_CLOSE_SOURCE).IsSuccess then
    Include(Info.ValidFields, piThreadHandle);
end;

function AdvxCreateProcessWithToken;
var
  hxExpandedToken, hxRemoteExpandedToken: IHandle;
  CreationFlags: TProcessCreateFlags;
  StartupInfo: TStartupInfoW;
  ProcessInfo: TProcessInformation;
  ProcessIdReverter: IAutoReleasable;
begin
  Info := Default(TProcessInfo);
  PrepareStartupInfo(StartupInfo, CreationFlags, Options);

  hxExpandedToken := Options.hxToken;

  // Note: the token parameter is mandatory and the function doesn't accept
  // tokens that are already in use because it always adjusts the session ID.

  if Assigned(hxExpandedToken) then
    Result := NtxExpandToken(hxExpandedToken, TOKEN_CREATE_PROCESS_EX)
  else
    Result := NtxDuplicateToken(hxExpandedToken, NtxCurrentProcessToken,
      TokenPrimary);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Options.hxParentProcess) then
  begin
    // Temporarily adjust the process ID in TEB to allow re-parenting
    Result := RtlxpAdjustProcessId(ProcessIdReverter, Options.hxParentProcess);

    if not Result.IsSuccess then
      Exit;

    // Send the token to the new parent (since seclogon reads it from there)
    Result := NtxDuplicateHandleToAuto(Options.hxParentProcess,
      hxExpandedToken, hxRemoteExpandedToken);

    if not Result.IsSuccess then
      Exit;
  end
  else
    hxRemoteExpandedToken := hxExpandedToken;

  Result.Location := 'CreateProcessWithTokenW';
  Result.LastCall.ExpectedPrivilege := SE_IMPERSONATE_PRIVILEGE;
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_CREATE_PROCESS_EX);

  if Assigned(Options.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION or
      PROCESS_CREATE_PROCESS or PROCESS_DUP_HANDLE);

  Result.Win32Result := CreateProcessWithTokenW(
    hxRemoteExpandedToken.Handle,
    Options.LogonFlags,
    RefStrOrNil(Options.ApplicationWin32),
    RefStrOrNil(Options.CommandLine),
    CreationFlags,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    StartupInfo,
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  Info.ValidFields := Info.ValidFields + [piProcessId, piThreadId];
  Info.ClientId.UniqueProcess := ProcessInfo.ProcessId;
  Info.ClientId.UniqueThread := ProcessInfo.ThreadId;
  RtlxpCaptureReparentedHandles(Options.hxParentProcess, ProcessInfo, Info);
end;

function AdvxCreateProcessWithLogon;
var
  CreationFlags: TProcessCreateFlags;
  StartupInfo: TStartupInfoW;
  ProcessInfo: TProcessInformation;
  ProcessIdReverter: IAutoReleasable;
begin
  Info := Default(TProcessInfo);
  PrepareStartupInfo(StartupInfo, CreationFlags, Options);

  if Assigned(Options.hxParentProcess) then
  begin
    // Temporarily adjust the process ID in TEB to allow re-parenting
    Result := RtlxpAdjustProcessId(ProcessIdReverter, Options.hxParentProcess);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'CreateProcessWithLogonW';
  Result.Win32Result := CreateProcessWithLogonW(
    RefStrOrNil(Options.Username),
    RefStrOrNil(Options.Domain),
    RefStrOrNil(Options.Password),
    Options.LogonFlags,
    RefStrOrNil(Options.ApplicationWin32),
    RefStrOrNil(Options.CommandLine),
    CreationFlags,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    StartupInfo,
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  Info.ValidFields := Info.ValidFields + [piProcessId, piThreadId];
  Info.ClientId.UniqueProcess := ProcessInfo.ProcessId;
  Info.ClientId.UniqueThread := ProcessInfo.ThreadId;
  RtlxpCaptureReparentedHandles(Options.hxParentProcess, ProcessInfo, Info);
end;

end.
