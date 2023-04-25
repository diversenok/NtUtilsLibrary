unit NtUtils.Tokens.AppModel;

{
  This module provides support for querying token AppModel Policy.
}

interface

uses
  Ntapi.AppModel.Policy, Ntapi.ntseapi, NtUtils, Ntapi.Versions;

{ AppModel Policy }

// Retrieve the AppModel Policy for package by its access token
[MinOSVersion(OsWin10RS1)]
function PkgxQueryAppModelPolicy(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  PolicyType: TAppModelPolicyType;
  out Policy: TAppModelPolicyValue;
  ReturnValueOnly: Boolean = True // aka clear type bits of the policy
): TNtxStatus;

// Check if the current OS version supports the specified AppModel Policy type
function PkgxIsPolicyTypeSupported(
  PolicyType: TAppModelPolicyType
): Boolean;

// Find TypeInfo of the enumeration that corresponds to AppModel Policy type
function PkgxGetPolicyTypeInfo(
  PolicyType: TAppModelPolicyType
): Pointer;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, NtUtils.Ldr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ AppModel Policy }

var
  GetAppModelPolicy: function (
    [Access(TOKEN_QUERY)] hToken: THandle;
    PolicyType: TAppModelPolicyType;
    out Policy: TAppModelPolicyValue
  ): TWin32Error; stdcall;

function PkgxQueryAppModelPolicy;
const
{$IFDEF Win64}
  SEARCH_OFFSET = $19;
  SEARCH_VALUE = $E800000001BA3024;
  PROLOG_VALUE = $48EC8348;
{$ELSE}
  SEARCH_OFFSET = $18;
  SEARCH_VALUE = $E84250D233FC458D;
  PROLOG_VALUE = $8B55FF8B;
{$ENDIF}
var
  KernelBaseModule: TModuleEntry;
  pAsmCode, pPrefix, pRva, pFunction: Pointer;
begin
  // GetAppModelPolicy doesn't check if the policy type is supported on the
  // current OS version and can, thus, read out of bound. Fix it here.
  if not PkgxIsPolicyTypeSupported(PolicyType) then
  begin
    Result.Location := 'PkgxQueryAppModelPolicy';
    Result.Status := STATUS_INVALID_INFO_CLASS;
    Exit;
  end;

  try
    if not Assigned(GetAppModelPolicy) then
    begin
      // GetAppModelPolicy is an unexporetd function in kernelbase. To locate
      // it, we need to parse an exported function that uses it, such as
      // AppPolicyGetLifecycleManagement.

      Result := LdrxFindModule(KernelBaseModule, ByBaseName(kernelbase));

      if not Result.IsSuccess then
        Exit;

      Result := LdrxGetProcedureAddress(KernelBaseModule.DllBase,
        'AppPolicyGetLifecycleManagement', pAsmCode);

      if not Result.IsSuccess then
        Exit;

      // First, we check a few bytes before the call instruction to make sure
      // we recognize the code
      pPrefix := PByte(pAsmCode) + SEARCH_OFFSET;

      if PUInt64(pPrefix)^ <> SEARCH_VALUE then
      begin
        Result.Location := 'PkgxQueryAppModelPolicy';
        Result.Status := STATUS_ENTRYPOINT_NOT_FOUND;
        Exit;
      end;

      // Then, we find where the call instruction points
      pRva := PByte(pPrefix) + SizeOf(UInt64);
      pFunction := PByte(pRva) + PCardinal(pRva)^ + SizeOf(Cardinal);

      // Make sure we point to a function prolog inside the same module
      if not KernelBaseModule.IsInRange(pFunction) or
        (PCardinal(pFunction)^ <> PROLOG_VALUE) then
      begin
        Result.Location := 'PkgxQueryAppModelPolicy (#2)';
        Result.Status := STATUS_ENTRYPOINT_NOT_FOUND;
        Exit;
      end;

      // Everything seems correct, save the address
      @GetAppModelPolicy := pFunction;
    end;

    // Query the policy value
    Result.Location := 'GetAppModelPolicy';
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);
    Result.LastCall.UsesInfoClass(PolicyType, icQuery);
    Result.Win32ErrorOrSuccess := GetAppModelPolicy(hxToken.Handle, PolicyType,
      Policy);

    // Extract the value to simplify type casting
    if Result.IsSuccess and ReturnValueOnly then
      Policy := Policy and APP_MODEL_POLICY_VALUE_MASK;

  except
    Result.Location := 'PkgxQueryAppModelPolicy';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;
end;

function PkgxIsPolicyTypeSupported(
  PolicyType: TAppModelPolicyType
): Boolean;
var
  RequiredVersion: TWindowsVersion;
begin
  case PolicyType of
    AppModelPolicy_Type_Unspecified..
      AppModelPolicy_Type_WinInetStoragePartitioning:
      RequiredVersion := OsWin10RS1;

    AppModelPolicy_Type_IndexerProtocolHandlerHost..
      AppModelPolicy_Type_PackageMayContainPrivateMapiProvider:
      RequiredVersion := OsWin10RS2;

    AppModelPolicy_Type_AdminProcessPackageClaims..
      AppModelPolicy_Type_GlobalSystemAppdataAccess:
      RequiredVersion := OsWin10RS3;

    AppModelPolicy_Type_ConsoleHandleInheritance..
      AppModelPolicy_Type_ConvertCallerTokenToUserTokenForDeployment:
      RequiredVersion := OsWin10RS4;

    AppModelPolicy_Type_ShellExecuteRetrieveIdentityFromCurrentProcess:
      RequiredVersion := OsWin10RS5;

    AppModelPolicy_Type_CodeIntegritySigning..AppModelPolicy_Type_PTCActivation:
      RequiredVersion := OsWin1019H1;


    AppModelPolicy_Type_COMIntraPackageRPCCall..
      AppModelPolicy_Type_PullPackageDependencyData:
      RequiredVersion := OsWin1020H1;

    AppModelPolicy_Type_AppInstancingErrorBehavior..
      AppModelPolicy_Type_ModsPowerNotifification:
      RequiredVersion := OsWin11;
  else
    Exit(False);
  end;

  Result := RtlOsVersionAtLeast(RequiredVersion);
end;

function PkgxGetPolicyTypeInfo;
begin
  case PolicyType of
    AppModelPolicy_Type_LifecycleManager:
      Result := TypeInfo(TAppModelPolicy_LifecycleManager);

    AppModelPolicy_Type_AppdataAccess:
      Result := TypeInfo(TAppModelPolicy_AppdataAccess);

    AppModelPolicy_Type_WindowingModel:
      Result := TypeInfo(TAppModelPolicy_WindowingModel);

    AppModelPolicy_Type_DLLSearchOrder:
      Result := TypeInfo(TAppModelPolicy_DLLSearchOrder);

    AppModelPolicy_Type_Fusion:
      Result := TypeInfo(TAppModelPolicy_Fusion);

    AppModelPolicy_Type_NonWindowsCodecLoading:
      Result := TypeInfo(TAppModelPolicy_NonWindowsCodecLoading);

    AppModelPolicy_Type_ProcessEnd:
      Result := TypeInfo(TAppModelPolicy_ProcessEnd);

    AppModelPolicy_Type_BeginThreadInit:
      Result := TypeInfo(TAppModelPolicy_BeginThreadInit);

    AppModelPolicy_Type_DeveloperInformation:
      Result := TypeInfo(TAppModelPolicy_DeveloperInformation);

    AppModelPolicy_Type_CreateFileAccess:
      Result := TypeInfo(TAppModelPolicy_CreateFileAccess);

    AppModelPolicy_Type_ImplicitPackageBreakaway:
      Result := TypeInfo(TAppModelPolicy_ImplicitPackageBreakaway);

    AppModelPolicy_Type_ProcessActivationShim:
      Result := TypeInfo(TAppModelPolicy_ProcessActivationShim);

    AppModelPolicy_Type_AppKnownToStateRepository:
      Result := TypeInfo(TAppModelPolicy_AppKnownToStateRepository);

    AppModelPolicy_Type_AudioManagement:
      Result := TypeInfo(TAppModelPolicy_AudioManagement);

    AppModelPolicy_Type_PackageMayContainPublicCOMRegistrations:
      Result := TypeInfo(TAppModelPolicy_PackageMayContainPublicCOMRegistrations);

    AppModelPolicy_Type_PackageMayContainPrivateCOMRegistrations:
      Result := TypeInfo(TAppModelPolicy_PackageMayContainPrivateCOMRegistrations);

    AppModelPolicy_Type_LaunchCreateprocessExtensions:
      Result := TypeInfo(TAppModelPolicy_LaunchCreateprocessExtensions);

    AppModelPolicy_Type_CLRCompat:
      Result := TypeInfo(TAppModelPolicy_CLRCompat);

    AppModelPolicy_Type_LoaderIgnoreAlteredSearchForRelativePath:
      Result := TypeInfo(TAppModelPolicy_LoaderIgnoreAlteredSearchForRelativePath);

    AppModelPolicy_Type_ImplicitlyActivateClassicAAAServersAsIU:
      Result := TypeInfo(TAppModelPolicy_ImplicitlyActivateClassicAAAServersAsIU);

    AppModelPolicy_Type_COMClassicCatalog:
      Result := TypeInfo(TAppModelPolicy_COMClassicCatalog);

    AppModelPolicy_Type_COMUnmarshaling:
      Result := TypeInfo(TAppModelPolicy_COMUnmarshaling);

    AppModelPolicy_Type_COMAppLaunchPerfEnhancements:
      Result := TypeInfo(TAppModelPolicy_COMAppLaunchPerfEnhancements);

    AppModelPolicy_Type_COMSecurityInitialization:
      Result := TypeInfo(TAppModelPolicy_COMSecurityInitialization);

    AppModelPolicy_Type_ROInitializeSingleThreadedBehavior:
      Result := TypeInfo(TAppModelPolicy_ROInitializeSingleThreadedBehavior);

    AppModelPolicy_Type_COMDefaultExceptionHandling:
      Result := TypeInfo(TAppModelPolicy_COMDefaultExceptionHandling);

    AppModelPolicy_Type_COMOopProxyAgility:
      Result := TypeInfo(TAppModelPolicy_COMOopProxyAgility);

    AppModelPolicy_Type_AppServiceLifetime:
      Result := TypeInfo(TAppModelPolicy_AppServiceLifetime);

    AppModelPolicy_Type_WebPlatform:
      Result := TypeInfo(TAppModelPolicy_WebPlatform);

    AppModelPolicy_Type_WinInetStoragePartitioning:
      Result := TypeInfo(TAppModelPolicy_WinInetStoragePartitioning);

    AppModelPolicy_Type_IndexerProtocolHandlerHost:
      Result := TypeInfo(TAppModelPolicy_IndexerProtocolHandlerHost);

    AppModelPolicy_Type_LoaderIncludeUserDirectories:
      Result := TypeInfo(TAppModelPolicy_LoaderIncludeUserDirectories);

    AppModelPolicy_Type_ConvertAppcontainerToRestrictedAppcontainer:
      Result := TypeInfo(TAppModelPolicy_ConvertAppcontainerToRestrictedAppcontainer);

    AppModelPolicy_Type_PackageMayContainPrivateMapiProvider:
      Result := TypeInfo(TAppModelPolicy_PackageMayContainPrivateMapiProvider);

    AppModelPolicy_Type_AdminProcessPackageClaims:
      Result := TypeInfo(TAppModelPolicy_AdminProcessPackageClaims);

    AppModelPolicy_Type_RegistryRedirectionBehavior:
      Result := TypeInfo(TAppModelPolicy_RegistryRedirectionBehavior);

    AppModelPolicy_Type_BypassCreateprocessAppxExtension:
      Result := TypeInfo(TAppModelPolicy_BypassCreateprocessAppxExtension);

    AppModelPolicy_Type_KnownFolderRedirection:
      Result := TypeInfo(TAppModelPolicy_KnownFolderRedirection);

    AppModelPolicy_Type_PrivateActivateAsPackageWinrtClasses:
      Result := TypeInfo(TAppModelPolicy_PrivateActivateAsPackageWinrtClasses);

    AppModelPolicy_Type_AppPrivateFolderRedirection:
      Result := TypeInfo(TAppModelPolicy_AppPrivateFolderRedirection);

    AppModelPolicy_Type_GlobalSystemAppdataAccess:
      Result := TypeInfo(TAppModelPolicy_GlobalSystemAppdataAccess);

    AppModelPolicy_Type_ConsoleHandleInheritance:
      Result := TypeInfo(TAppModelPolicy_ConsoleHandleInheritance);

    AppModelPolicy_Type_ConsoleBufferAccess:
      Result := TypeInfo(TAppModelPolicy_ConsoleBufferAccess);

    AppModelPolicy_Type_ConvertCallerTokenToUserTokenForDeployment:
      Result := TypeInfo(TAppModelPolicy_ConvertCallerTokenToUserTokenForDeployment);

    AppModelPolicy_Type_ShellexecuteRetrieveIdentityFromCurrentProcess:
      Result := TypeInfo(TAppModelPolicy_ShellexecuteRetrieveIdentityFromCurrentProcess);

    AppModelPolicy_Type_CodeIntegritySigning:
      Result := TypeInfo(TAppModelPolicy_CodeIntegritySigning);

    AppModelPolicy_Type_PTCActivation:
      Result := TypeInfo(TAppModelPolicy_PTCActivation);

    AppModelPolicy_Type_COMIntraPackageRPCCall:
      Result := TypeInfo(TAppModelPolicy_COMIntraPackageRPCCall);

    AppModelPolicy_Type_LoadUser32ShimOnWindowsCoreOS:
      Result := TypeInfo(TAppModelPolicy_LoadUser32ShimOnWindowsCoreOS);

    AppModelPolicy_Type_SecurityCapabilitiesOverride:
      Result := TypeInfo(TAppModelPolicy_SecurityCapabilitiesOverride);

    AppModelPolicy_Type_CurrentDirectoryOverride:
      Result := TypeInfo(TAppModelPolicy_CurrentDirectoryOverride);

    AppModelPolicy_Type_COMTokenMatchingForAAAServers:
      Result := TypeInfo(TAppModelPolicy_COMTokenMatchingForAAAServers);

    AppModelPolicy_Type_UseOriginalFileNameInTokenFQBNAttribute:
      Result := TypeInfo(TAppModelPolicy_UseOriginalFileNameInTokenFQBNAttribute);

    AppModelPolicy_Type_LoaderIncludeAlternateForwarders:
      Result := TypeInfo(TAppModelPolicy_LoaderIncludeAlternateForwarders);

    AppModelPolicy_Type_PullPackageDependencyData:
      Result := TypeInfo(TAppModelPolicy_PullPackageDependencyData);

    AppModelPolicy_Type_AppInstancingErrorBehavior:
      Result := TypeInfo(TAppModelPolicy_AppInstancingErrorBehavior);

    AppModelPolicy_Type_BackgroundTaskRegistrationType:
      Result := TypeInfo(TAppModelPolicy_BackgroundTaskRegistrationType);

    AppModelPolicy_Type_ModsPowerNotifification:
      Result := TypeInfo(TAppModelPolicy_ModsPowerNotifification);
  else
    Result := nil;
  end;
end;

end.
