unit Ntapi.appmodel;

{
  This module includes definitions for inspecting packaged applocations.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, Ntapi.ntpebteb, Ntapi.Versions,
  Ntapi.WinUser, DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  MrmCoreR = 'MrmCoreR.dll';

var
  delayed_MrmCoreR: TDelayedLoadDll = (DllName: MrmCoreR);

const
  // SDK::appmodel.h - information flags
  PACKAGE_INFORMATION_BASIC = $00000000;
  PACKAGE_INFORMATION_FULL = $00000100;

  // SDK::appmodel.h - filter flags
  PACKAGE_FILTER_HEAD = $00000010;
  PACKAGE_FILTER_DIRECT = $00000020;
  PACKAGE_FILTER_RESOURCE = $00000040;
  PACKAGE_FILTER_BUNDLE = $00000080;
  PACKAGE_FILTER_OPTIONAL = $00020000;
  PACKAGE_FILTER_IS_IN_RELATED_SET = $00040000;
  PACKAGE_FILTER_STATIC = $00080000;
  PACKAGE_FILTER_DYNAMIC = $00100000;
  PACKAGE_FILTER_HOSTRUNTIME = $00200000; // Win 10 20H2+

  // SDK::appmodel.h - package properties
  PACKAGE_PROPERTY_FRAMEWORK = $00000001;
  PACKAGE_PROPERTY_RESOURCE = $00000002;
  PACKAGE_PROPERTY_BUNDLE = $00000004;
  PACKAGE_PROPERTY_OPTIONAL = $00000008;
  PACKAGE_PROPERTY_HEAD = $00000010;   // rev
  PACKAGE_PROPERTY_DIRECT = $00000020; // rev
  PACKAGE_PROPERTY_DEVELOPMENT_MODE = $00010000;
  PACKAGE_PROPERTY_IS_IN_RELATED_SET = $00040000;
  PACKAGE_PROPERTY_STATIC = $00080000;
  PACKAGE_PROPERTY_DYNAMIC = $00100000;
  PACKAGE_PROPERTY_HOSTRUNTIME = $00200000; // Win 10 20H2+

  // Windows Internals book - package claim flags
  PSM_ACTIVATION_TOKEN_PACKAGED_APPLICATION = $0001;
  PSM_ACTIVATION_TOKEN_SHARED_ENTITY = $0002;
  PSM_ACTIVATION_TOKEN_FULL_TRUST = $0004;
  PSM_ACTIVATION_TOKEN_NATIVE_SERVICE = $0008;
  PSM_ACTIVATION_TOKEN_DEVELOPMENT_APP = $0010;
  PSM_ACTIVATION_TOKEN_BREAKAWAY_INHIBITED = $0020;
  PSM_ACTIVATION_TOKEN_RUNTIME_BROKER = $0040; // rev
  PSM_ACTIVATION_TOKEN_UNIVERSAL_CONSOLE = $0200; // rev
  PSM_ACTIVATION_TOKEN_WIN32ALACARTE_PROCESS = $00010000; // rev

  // rev - attributes for RtlQueryPackageClaims
  PACKAGE_ATTRIBUTE_SYSAPPID_PRESENT = $0001;
  PACKAGE_ATTRIBUTE_PKG_CLAIM_PRESENT = $0002;
  PACKAGE_ATTRIBUTE_SKUID_PRESENT = $0004;
  PACKAGE_ATTRIBUTE_XBOX_LI_PRESENT = $0008;

  // Desktop AppX activation options
  DAXAO_ELEVATE = $00000001;
  DAXAO_NONPACKAGED_EXE = $00000002;
  DAXAO_NONPACKAGED_EXE_PROCESS_TREE = $00000004;   // Win 10 RS2+
  DAXAO_NO_ERROR_UI = $00000008;                    // Win 10 20H1+
  DAXAO_CHECK_FOR_APPINSTALLER_UPDATES = $00000010; // Win 10 20H1+ (was 0x40 in 19H1 & 19H2)
  DAXAO_CENTENNIAL_PROCESS = $00000020;             // Win 10 20H1+
  DAXAO_UNIVERSAL_PROCESS = $00000040;              // Win 10 20H1+
  DAXAO_WIN32ALACARTE_PROCESS = $00000080;          // Win 10 20H1+
  DAXAO_PARTIAL_TRUST = $00000100;                  // Win 10 20H1+
  DAXAO_UNIVERSAL_CONSOLE = $00000200;              // Win 10 20H1+

  CLSID_DesktopAppXActivator: TGuid = '{168EB462-775F-42AE-9111-D714B2306C2E}';

type
  // SDK::appmodel.h
  [MinOSVersion(OsWin8)]
  [SDKName('PACKAGE_VERSION')]
  TPackageVersion = record
    Revision: Word;
    Build: Word;
    Minor: Word;
    Major: Word;
  end;

  // SDK::appmodel.h
  [MinOSVersion(OsWin8)]
  [SDKName('PACKAGE_ID')]
  TPackageId = record
    [Unlisted] Reserved: Cardinal;
    ProcessorArchitecture: TProcessorArchitecture;
    [Unlisted] Padding: Word;
    Version: TPackageVersion;
    Name: PWideChar;
    Publisher: PWideChar;
    ResourceID: PWideChar;
    PublisherID: PWideChar;
  end;
  PPackageId = ^TPackageId;

  // SDK::appmodel.h
  [MinOSVersion(OsWin1019H1)]
  [SDKName('PackagePathType')]
  [NamingStyle(nsCamelCase, 'PackagePathType_')]
  TPackagePathType = (
    PackagePathType_Install = 0,
    PackagePathType_Mutable = 1,
    PackagePathType_Effective = 2,
    [MinOSVersion(OsWin1020H1)] PackagePathType_MachineExternal = 3,
    [MinOSVersion(OsWin1020H1)] PackagePathType_UserExternal = 4,
    [MinOSVersion(OsWin1020H1)] PackagePathType_EffectiveExternal = 5
  );

  [FlagName(PACKAGE_INFORMATION_BASIC, 'Basic')]
  [FlagName(PACKAGE_INFORMATION_FULL, 'Full')]
  TPackageInformationFlags = type Cardinal;

  TPackageFullNames = TAnysizeArray<PWideChar>;
  PPackageFullNames = ^TPackageFullNames;

  [FlagName(PACKAGE_FILTER_HEAD, 'Head Package')]
  [FlagName(PACKAGE_FILTER_DIRECT, 'Directly Dependent')]
  [FlagName(PACKAGE_FILTER_RESOURCE, 'Resource')]
  [FlagName(PACKAGE_FILTER_BUNDLE, 'Bundle')]
  [FlagName(PACKAGE_FILTER_OPTIONAL, 'Optional')]
  [FlagName(PACKAGE_FILTER_IS_IN_RELATED_SET, 'In Related Set')]
  [FlagName(PACKAGE_FILTER_STATIC, 'Static')]
  [FlagName(PACKAGE_FILTER_DYNAMIC, 'Dynamic')]
  [FlagName(PACKAGE_FILTER_HOSTRUNTIME, 'Host Runtime')]
  TPackageFilters = type Cardinal;

  [FlagName(PACKAGE_PROPERTY_FRAMEWORK, 'Framework')]
  [FlagName(PACKAGE_PROPERTY_RESOURCE, 'Resource')]
  [FlagName(PACKAGE_PROPERTY_BUNDLE, 'Bundle')]
  [FlagName(PACKAGE_PROPERTY_OPTIONAL, 'Optional')]
  [FlagName(PACKAGE_PROPERTY_HEAD, 'Head Package')]
  [FlagName(PACKAGE_PROPERTY_DIRECT, 'Directly Dependent')]
  [FlagName(PACKAGE_PROPERTY_DEVELOPMENT_MODE, 'Development Mode')]
  [FlagName(PACKAGE_PROPERTY_IS_IN_RELATED_SET, 'In Related Set')]
  [FlagName(PACKAGE_PROPERTY_STATIC, 'Static')]
  [FlagName(PACKAGE_PROPERTY_DYNAMIC, 'Dynamic')]
  [FlagName(PACKAGE_PROPERTY_HOSTRUNTIME, 'Host Runtime')]
  TPackageProperties = type Cardinal;

  TPackagePropertiesArray = TAnysizeArray<TPackageProperties>;
  PPackagePropertiesArray = ^TPackagePropertiesArray;

  // SDK::appmodel.h
  [SDKName('PackageOrigin')]
  [NamingStyle(nsCamelCase, 'PackageOrigin_')]
  TPackageOrigin = (
    PackageOrigin_Unknown = 0,
    PackageOrigin_Unsigned = 1,
    PackageOrigin_Inbox = 2,
    PackageOrigin_Store = 3,
    PackageOrigin_DeveloperUnsigned = 4,
    PackageOrigin_DeveloperSigned = 5,
    PackageOrigin_LineOfBusiness = 6
  );

  [FlagName(PSM_ACTIVATION_TOKEN_PACKAGED_APPLICATION, 'Packaged Application')]
  [FlagName(PSM_ACTIVATION_TOKEN_SHARED_ENTITY, 'Shared Entity')]
  [FlagName(PSM_ACTIVATION_TOKEN_FULL_TRUST, 'Full Trust')]
  [FlagName(PSM_ACTIVATION_TOKEN_NATIVE_SERVICE, 'Native Service')]
  [FlagName(PSM_ACTIVATION_TOKEN_DEVELOPMENT_APP, 'Development App')]
  [FlagName(PSM_ACTIVATION_TOKEN_BREAKAWAY_INHIBITED, 'Breakaway Inhibited')]
  [FlagName(PSM_ACTIVATION_TOKEN_RUNTIME_BROKER, 'Runtime Broker')]
  [FlagName(PSM_ACTIVATION_TOKEN_UNIVERSAL_CONSOLE, 'Universal Console')]
  [FlagName(PSM_ACTIVATION_TOKEN_WIN32ALACARTE_PROCESS, 'Win32 A-La-Carte Process')]
  TPackageClaimFlags = type Cardinal;

  // PHNT::ntrtl.h
  [SDKName('PS_PKG_CLAIM')]
  TPsPkgClaim = record
    Flags: TPackageClaimFlags;
    Origin: TPackageOrigin;
  end;
  PPsPkgClaim = ^TPsPkgClaim;

  [FlagName(PACKAGE_ATTRIBUTE_SYSAPPID_PRESENT, 'WIN://SYSAPPID')]
  [FlagName(PACKAGE_ATTRIBUTE_PKG_CLAIM_PRESENT, 'WIN://PKG')]
  [FlagName(PACKAGE_ATTRIBUTE_SKUID_PRESENT, 'WP://SKUID')]
  [FlagName(PACKAGE_ATTRIBUTE_XBOX_LI_PRESENT, 'XBOX://LI')]
  TPackagePresentAttributes = type UInt64;
  PPackagePresentAttributes = ^TPackagePresentAttributes;

  // SDK::appmodel.h
  [MinOSVersion(OsWin8)]
  [SDKName('PACKAGE_INFO')]
  TPackageInfo = record
    Reserved: Cardinal;
    Flags: TPackageProperties;
    Path: PWideChar;
    PackageFullName: PWideChar;
    PackageFamilyName: PWideChar;
    [Aggregate] PackageId: TPackageId;
  end;
  PPackageInfo = ^TPackageInfo;

  TPackageInfoArray = TAnysizeArray<TPackageInfo>;
  PPackageInfoArray = ^TPackageInfoArray;

  // SDK::appmodel.h
  [SDKName('PACKAGE_INFO_REFERENCE')]
  TPackageInfoReference = type Pointer;

  TAppIdArray = TAnysizeArray<PWideChar>;
  PAppIdArray = ^TAppIdArray;

  { Properties }

  // private
  [SDKName('PACKAGE_CONTEXT_REFERENCE')]
  TPackageContextReference = record end;
  PPackageContextReference = ^TPackageContextReference;

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('PackageProperty')]
  [NamingStyle(nsCamelCase, 'PackageProperty_'), Range(1)]
  TPackageProperty = (
    [Reserved] PackageProperty_Reserved = 0,
    PackageProperty_Name = 1,                  // q: PWideChar
    PackageProperty_Version = 2,               // q: TPackageVersion
    PackageProperty_Architecture = 3,          // q: Cardinal (TProcessorArchitecture)
    PackageProperty_ResourceId = 4,            // q: PWideChar
    PackageProperty_Publisher = 5,             // q: PWideChar
    PackageProperty_PublisherId = 6,           // q: PWideChar
    PackageProperty_FamilyName = 7,            // q: PWideChar
    PackageProperty_FullName = 8,              // q: PWideChar
    PackageProperty_Flags = 9,                 // q: Cardinal (maybe Windows::Internal::StateRepository::PackageFlags / StateRepository::Cache::CachePackageFlags?)
    PackageProperty_InstalledLocation = 10,    // q: PWideChar
    PackageProperty_DisplayName = 11,          // q: PWideChar
    PackageProperty_PublisherDisplayName = 12, // q: PWideChar
    PackageProperty_Description = 13,          // q: PWideChar
    PackageProperty_Logo = 14,                 // q: PWideChar
    PackageProperty_PackageOrigin = 15         // q: TPackageOrigin
  );

  // private
  [SDKName('PACKAGE_APPLICATION_CONTEXT_REFERENCE')]
  TPackageApplicationContextReference = record end;
  PPackageApplicationContextReference = ^TPackageApplicationContextReference;

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('PackageApplicationProperty')]
  [NamingStyle(nsCamelCase, 'PackageApplicationProperty_'), Range(1)]
  TPackageApplicationProperty = (
    [Reserved] PackageAppProperty_Reserved = 0,
    PackageApplicationProperty_Aumid = 1,                        // q: PWideChar
    PackageApplicationProperty_Praid = 2,                        // q: PWideChar
    PackageApplicationProperty_DisplayName = 3,                  // q: PWideChar
    PackageApplicationProperty_Description = 4,                  // q: PWideChar
    PackageApplicationProperty_Logo = 5,                         // q: PWideChar
    PackageApplicationProperty_SmallLogo = 6,                    // q: PWideChar
    PackageApplicationProperty_ForegroundText = 7,               // q: Cardinal
    PackageApplicationProperty_ForegroundTextString = 8,         // q: PWideChar
    PackageApplicationProperty_BackgroundColor = 9,              // q: Cardinal
    PackageApplicationProperty_StartPage = 10,                   // q: PWideChar
    PackageApplicationProperty_ContentURIRulesCount = 11,        // q: Cardinal
    PackageApplicationProperty_ContentURIRules = 12,             // q: PWideMultiSz
    PackageApplicationProperty_StaticContentURIRulesCount = 13,  // q: Cardinal
    PackageApplicationProperty_StaticContentURIRules = 14,       // q: PWideMultiSz
    PackageApplicationProperty_DynamicContentURIRulesCount = 15, // q: Cardinal
    PackageApplicationProperty_DynamicContentURIRules = 16       // q: PWideMultiSz
  );

  // private
  [SDKName('PACKAGE_RESOURCES_CONTEXT_REFERENCE')]
  TPackageResourcesContextReference = record end;
  PPackageResourcesContextReference = ^TPackageResourcesContextReference;

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('PackageResourcesProperty')]
  [NamingStyle(nsCamelCase, 'PackageResourcesProperty_'), Range(1)]
  TPackageResourcesProperty = (
    [Reserved] PackageResourceProperty_Reserved = 0,
    PackageResourcesProperty_DisplayName = 1,
    PackageResourcesProperty_PublisherDisplayName = 2,
    PackageResourcesProperty_Description = 3,
    PackageResourcesProperty_Logo = 4,
    PackageResourcesProperty_SmallLogo = 5,
    PackageResourcesProperty_StartPage = 6
  );

  // private
  [SDKName('PACKAGE_SECURITY_CONTEXT_REFERENCE')]
  TPackageSecurityContextReference = record end;
  PPackageSecurityContextReference = ^TPackageSecurityContextReference;

  // private
  [SDKName('PackageSecurityProperty')]
  [NamingStyle(nsCamelCase, 'PackageSecurityProperty_'), Range(1)]
  TPackageSecurityProperty = (
    [Reserved] PackageSecurityProperty_Reserved = 0,
    PackageSecurityProperty_SecurityFlags = 1,     // q: Cardinal
    PackageSecurityProperty_AppContainerSID = 2,   // q: PSid
    PackageSecurityProperty_CapabilitiesCount = 3, // q: Cardinal
    PackageSecurityProperty_Capabilities = 4       // q: PSid[]
  );

  // private
  [SDKName('TARGET_PLATFORM_CONTEXT_REFERENCE')]
  TTargetPlatformContextReference = record end;
  PTargetPlatformContextReference = ^TTargetPlatformContextReference;

  // private
  [MinOSVersion(OsWin10TH1)]
  [SDKName('TargetPlatformProperty')]
  [NamingStyle(nsCamelCase, 'TargetPlatformProperty_'), Range(1)]
  TTargetPlatformProperty = (
    [Reserved] TargetPlatformProperty_Reserved = 0,
    TargetPlatformProperty_Platform = 1,   // q: Cardinal
    TargetPlatformProperty_MinVersion = 2, // q: TPackageVersion
    TargetPlatformProperty_MaxVersion = 3  // q: TPackageVersion
  );

  // private
  [SDKName('PACKAGE_GLOBALIZATION_CONTEXT_REFERENCE')]
  TPackageGlobalizationContextReference = record end;
  PPackageGlobalizationContextReference = ^TPackageGlobalizationContextReference;

  // private
  [MinOSVersion(OsWin1020H1)]
  [SDKName('PackageGlobalizationProperty')]
  [NamingStyle(nsCamelCase, 'PackageGlobalizationProperty_'), Range(1)]
  TPackageGlobalizationProperty = (
    [Reserved] PackageGlobalizationProperty_Reserved = 0,
    PackageGlobalizationProperty_ForceUtf8 = 1,                // q: LongBool
    PackageGlobalizationProperty_UseWindowsDisplayLanguage = 2 // q: LongBool
  );

  { AppX Activation }

  [SDKName('DESKTOPAPPXACTIVATEOPTIONS')]
  [FlagName(DAXAO_ELEVATE, 'Elavate')]
  [FlagName(DAXAO_NONPACKAGED_EXE, 'Non-packaged EXE')]
  [FlagName(DAXAO_NONPACKAGED_EXE_PROCESS_TREE, 'Non-packaged EXE Process Tree')]
  [FlagName(DAXAO_NO_ERROR_UI, 'No Error UI')]
  [FlagName(DAXAO_CHECK_FOR_APPINSTALLER_UPDATES, 'Check For AppInstaller Updates')]
  [FlagName(DAXAO_CENTENNIAL_PROCESS, 'Centennial Process')]
  [FlagName(DAXAO_UNIVERSAL_PROCESS, 'Universal Process')]
  [FlagName(DAXAO_WIN32ALACARTE_PROCESS, 'Win32Alacarte Process')]
  [FlagName(DAXAO_PARTIAL_TRUST, 'Partial Trust')]
  [FlagName(DAXAO_UNIVERSAL_CONSOLE, 'Universal Console')]
  TDesktopAppxActivateOptions = type Cardinal;

  [MinOSVersion(OsWin10RS1)]
  [SDKName('IDesktopAppXActivator')]
  IDesktopAppXActivatorV1 = interface (IUnknown)
    ['{B81F98D4-6F57-401A-8FCC-B66014CA80BB}']

    function Activate(
      [in] applicationUserModelId: PWideChar;
      [in] packageRelativeExecutable: PWideChar;
      [in, opt] arguments: PWideChar;
      [out, ReleaseWith('NtClose')] out processHandle: THandle32
    ): HResult; stdcall;

    function ActivateWithOptions(
      [in] applicationUserModelId: PWideChar;
      [in] executable: PWideChar;
      [in, opt] arguments: PWideChar;
      [in] activationOptions: TDesktopAppxActivateOptions;
      [out, ReleaseWith('NtClose')] out processHandle: THandle32
    ): HResult; stdcall;
  end;

  [MinOSVersion(OsWin10RS2)]
  [SDKName('IDesktopAppXActivator')]
  IDesktopAppXActivatorV2 = interface (IUnknown)
    ['{72E3A5B0-8FEA-485C-9F8B-822B16DBA17F}']

    function Activate(
      [in] applicationUserModelId: PWideChar;
      [in] packageRelativeExecutable: PWideChar;
      [in, opt] arguments: PWideChar;
      [out, ReleaseWith('NtClose')] out processHandle: THandle32
    ): HResult; stdcall;

    function ActivateWithOptions(
      [in] applicationUserModelId: PWideChar;
      [in] executable: PWideChar;
      [in, opt] arguments: PWideChar;
      [in] activationOptions: TDesktopAppxActivateOptions;
      [in, opt] parentProcessId: TProcessId32;
      [out, ReleaseWith('NtClose')] out processHandle: THandle32
    ): HResult; stdcall;
  end;

  [MinOSVersion(OsWin11)]
  [SDKName('IDesktopAppXActivator')]
  IDesktopAppXActivatorV3 = interface (IUnknown)
    ['{F158268A-D5A5-45CE-99CF-00D6C3F3FC0A}']

    function Activate(
      [in] applicationUserModelId: PWideChar;
      [in] packageRelativeExecutable: PWideChar;
      [in, opt] arguments: PWideChar;
      [out, ReleaseWith('NtClose')] out processHandle: THandle32
    ): HResult; stdcall;

    function ActivateWithOptions(
      [in] applicationUserModelId: PWideChar;
      [in] executable: PWideChar;
      [in, opt] arguments: PWideChar;
      [in] activationOptions: TDesktopAppxActivateOptions;
      [in, opt] parentProcessId: TProcessId32;
      [out, ReleaseWith('NtClose')] out processHandle: THandle32
    ): HResult; stdcall;

    function ActivateWithOptionsAndArgs(
      [in] applicationUserModelId: PWideChar;
      [in] executable: PWideChar;
      [in, opt] arguments: PWideChar;
      [in] activationOptions: TDesktopAppxActivateOptions;
      [in, opt] parentProcessId: TProcessId32;
      [in, opt] activatedEventArgs: IInterface;
      [out, ReleaseWith('NtClose')] out processHandle: THandle32
    ): HResult; stdcall;

    function ActivateWithOptionsArgsWorkingDirectoryShowWindow(
      [in] applicationUserModelId: PWideChar;
      [in] executable: PWideChar;
      [in, opt] arguments: PWideChar;
      [in] activationOptions: TDesktopAppxActivateOptions;
      [in, opt] parentProcessId: TProcessId32;
      [in, opt] activatedEventArgs: IInterface;
      [in, opt] workingDirectory: PWideChar;
      [in] showWindow: TShowMode32;
      [out, ReleaseWith('NtClose')] out processHandle: THandle32
    ): HResult; stdcall;
  end;

// SDK::appmodel.h
[MinOSVersion(OsWin81)]
function GetPackagePath(
  [in] const packageId: TPackageId;
  [Reserved] reserved: Cardinal;
  [in, out, NumberOfElements] var pathLength: Cardinal;
  [out, WritesTo] path: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackagePath: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackagePath';
);

// SDK::appmodel.h
[MinOSVersion(OsWin81)]
function GetPackagePathByFullName(
  [in] packageFullName: PWideChar;
  [in, out, NumberOfElements] var pathLength: Cardinal;
  [out, WritesTo] path: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackagePathByFullName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackagePathByFullName';
);

// SDK::appmodel.h
[MinOSVersion(OsWin81)]
function GetStagedPackagePathByFullName(
  [in] packageFullName: PWideChar;
  [in, out, NumberOfElements] var pathLength: Cardinal;
  [out, WritesTo] path: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetStagedPackagePathByFullName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetStagedPackagePathByFullName';
);

// SDK::appmodel.h
[MinOSVersion(OsWin1019H1)]
function GetPackagePathByFullName2(
  [in] packageFullName: PWideChar;
  [in] packagePathType: TPackagePathType;
  [in, out, NumberOfElements] var pathLength: Cardinal;
  [out, WritesTo] path: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackagePathByFullName2: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackagePathByFullName2';
);

// SDK::appmodel.h
[MinOSVersion(OsWin1019H1)]
function GetStagedPackagePathByFullName2(
  [in] packageFullName: PWideChar;
  [in] packagePathType: TPackagePathType;
  [in, out, NumberOfElements] var pathLength: Cardinal;
  [out, WritesTo] path: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetStagedPackagePathByFullName2: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetStagedPackagePathByFullName2';
);

// SDK::appmodel.h
[MinOSVersion(OsWin10TH1)]
function GetApplicationUserModelIdFromToken(
  [in, Access(TOKEN_QUERY)] token: THandle;
  [in, out, NumberOfElements] var applicationUserModelIdLength: Cardinal;
  [out, WritesTo] applicationUserModelId: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetApplicationUserModelIdFromToken: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetApplicationUserModelIdFromToken';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function PackageIdFromFullName(
  [in] packageFullName: PWideChar;
  [in] flags: TPackageInformationFlags;
  [in, out, NumberOfBytes] var bufferLength: Cardinal;
  [out, WritesTo] buffer: PPackageId
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_PackageIdFromFullName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'PackageIdFromFullName';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function PackageFullNameFromId(
  [in] const packageId: TPackageId;
  [in, out, NumberOfElements] var packageFullNameLength: Cardinal;
  [out, WritesTo] packageFullName: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_PackageFullNameFromId: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'PackageFullNameFromId';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function PackageFamilyNameFromId(
  [in] const packageId: TPackageId;
  [in, out, NumberOfElements] var packageFamilyNameLength: Cardinal;
  [out, WritesTo] packageFamilyName: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_PackageFamilyNameFromId: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'PackageFamilyNameFromId';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function PackageFamilyNameFromFullName(
  [in] packageFullName: PWideChar;
  [in, out, NumberOfElements] var packageFamilyNameLength: Cardinal;
  [out, WritesTo] packageFamilyName: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_PackageFamilyNameFromFullName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'PackageFamilyNameFromFullName';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function PackageNameAndPublisherIdFromFamilyName(
  [in] packageFamilyName: PWideChar;
  [in, out, NumberOfElements] var packageNameLength: Cardinal;
  [out, WritesTo] packageName: PWideChar;
  [in, out, NumberOfElements] var packagePublisherIdLength: Cardinal;
  [out, WritesTo] packagePublisherId: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_PackageNameAndPublisherIdFromFamilyName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'PackageNameAndPublisherIdFromFamilyName';
);

// SDK::appmodel.h
[MinOSVersion(OsWin81)]
function FormatApplicationUserModelId(
  [in] packageFamilyName: PWideChar;
  [in] packageRelativeApplicationId: PWideChar;
  [in, out, NumberOfElements] var applicationUserModelIdLength: Cardinal;
  [out, WritesTo] applicationUserModelId: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_FormatApplicationUserModelId: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'FormatApplicationUserModelId';
);

// SDK::appmodel.h
[MinOSVersion(OsWin81)]
function ParseApplicationUserModelId(
  [in] applicationUserModelId: PWideChar;
  [in, out, NumberOfElements] var packageFamilyNameLength: Cardinal;
  [out, WritesTo] packageFamilyName: PWideChar;
  [in, out, NumberOfElements] var packageRelativeApplicationIdLength: Cardinal;
  [out, WritesTo] packageRelativeApplicationId: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_ParseApplicationUserModelId: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'ParseApplicationUserModelId';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function GetPackagesByPackageFamily(
  [in] packageFamilyName: PWideChar;
  [in, out, NumberOfElements] var count: Cardinal;
  [out, WritesTo] packageFullNames: PPackageFullNames;
  [in, out, NumberOfElements] var bufferLength: Cardinal;
  [out, WritesTo] buffer: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackagesByPackageFamily: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackagesByPackageFamily';
);

// SDK::appmodel.h
[MinOSVersion(OsWin81)]
function FindPackagesByPackageFamily(
  [in] packageFamilyName: PWideChar;
  [in] packageFilters: TPackageFilters;
  [in, out, NumberOfElements] var count: Cardinal;
  [out, WritesTo] packageFullNames: PPackageFullNames;
  [in, out, NumberOfElements] var bufferLength: Cardinal;
  [out, WritesTo] buffer: PWideChar;
  [out, WritesTo] packageProperties: PPackagePropertiesArray
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_FindPackagesByPackageFamily: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'FindPackagesByPackageFamily';
);

// PHNT::ntrtl.h
[MinOSVersion(OsWin10TH1)]
function RtlQueryPackageClaims(
  [in, Access(TOKEN_QUERY)] TokenHandle: THandle;
  [out, opt, WritesTo] PackageFullName: PWideChar;
  [in, out, opt, NumberOfBytes] PackageSize: PNativeUInt;
  [out, opt, WritesTo] AppId: PWideChar;
  [in, out, opt, NumberOfBytes] AppIdSize: PNativeUInt;
  [out, opt] DynamicId: PGuid;
  [out, opt] PkgClaim: PPsPkgClaim;
  [out, opt] AttributesPresent: PPackagePresentAttributes
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_RtlQueryPackageClaims: TDelayedLoadFunction = (
  DllName: ntdll;
  FunctionName: 'RtlQueryPackageClaims';
);

// SDK::appmodel.h
[MinOSVersion(OsWin81)]
function GetStagedPackageOrigin(
  [in] packageFullName: PWideChar;
  [out] out origin: TPackageOrigin
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetStagedPackageOrigin: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetStagedPackageOrigin';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function OpenPackageInfoByFullName(
  [in] packageFullName: PWideChar;
  [Reserved] reserved: Cardinal;
  [out, ReleaseWith('ClosePackageInfo')]
    out packageInfoReference: TPackageInfoReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_OpenPackageInfoByFullName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'OpenPackageInfoByFullName';
);

// SDK::appmodel.h
[MinOSVersion(OsWin10TH1)]
function OpenPackageInfoByFullNameForUser(
  [in, opt] userSid: PSid;
  [in] packageFullName: PWideChar;
  [Reserved] reserved: Cardinal;
  [out, ReleaseWith('ClosePackageInfo')]
    out packageInfoReference: TPackageInfoReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_OpenPackageInfoByFullNameForUser: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'OpenPackageInfoByFullNameForUser';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function ClosePackageInfo(
  [in] packageInfoReference: TPackageInfoReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_ClosePackageInfo: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'ClosePackageInfo';
);

// SDK::appmodel.h
[MinOSVersion(OsWin8)]
function GetPackageInfo(
  [in] packageInfoReference: TPackageInfoReference;
  [in] flags: TPackageFilters;
  [in, out, NumberOfBytes] var bufferLength: Cardinal;
  [out, opt, WritesTo] buffer: PPackageInfoArray;
  [out, opt] count: PCardinal
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageInfo: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageInfo';
);

// SDK::appmodel.h
[MinOSVersion(OsWin1019H1)]
function GetPackageInfo2(
  [in] packageInfoReference: TPackageInfoReference;
  [in] flags: TPackageFilters;
  [in] packagePathType: TPackagePathType;
  [in, out, NumberOfBytes] var bufferLength: Cardinal;
  [out, opt, WritesTo] buffer: PPackageInfoArray;
  [out, opt] count: PCardinal
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageInfo2: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageInfo2';
);

// SDK::appmodel.h
[MinOSVersion(OsWin81)]
function GetPackageApplicationIds(
  [in] packageInfoReference: TPackageInfoReference;
  [in, out] var bufferLength: Cardinal;
  [out, WritesTo] buffer: PAppIdArray;
  [out, opt] count: PCardinal
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageApplicationIds: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageApplicationIds';
);

// SDK::appmodel.h
[MinOSVersion(OsWin1021H1)]
function CheckIsMSIXPackage(
  [in] packageFullName: PWideChar;
  [out] out isMSIXPackage: LongBool
): HRESULT; stdcall; external kernelbase delayed;

var delayed_CheckIsMSIXPackage: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'CheckIsMSIXPackage';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageInstallTime(
  [in] packageFullName: PWideChar;
  [out] out InstallTime: TLargeInteger
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageInstallTime: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageInstallTime';
);

// rev
[MinOSVersion(OsWin1020H1)]
function PublisherFromPackageFullName(
  [in] FullName: PWideChar;
  [in, out, NumberOfElements] var BufferSize: Cardinal;
  [out, WritesTo] Buffer: PWideChar
): HResult; stdcall; external kernelbase delayed;

var delayed_PublisherFromPackageFullName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'PublisherFromPackageFullName';
);

// rev
[MinOSVersion(OsWin10TH1)]
function PackageSidFromFamilyName(
  [in] FamilyName: PWideChar;
  [out, ReleaseWith('RtlFreeSid')] out Sid: PSid
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_PackageSidFromFamilyName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'PackageSidFromFamilyName';
);

// rev
[MinOSVersion(OsWin10TH1)]
function PackageSidFromProductId(
  [in] PackageInfoReference: TPackageInfoReference;
  [out, ReleaseWith('RtlFreeSid')] out Sid: PSid
): HResult; stdcall; external kernelbase delayed;

var delayed_PackageSidFromProductId: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'PackageSidFromProductId';
);

// Verification

// SDK::appmodel.h
[MinOSVersion(OsWin10TH1)]
function VerifyPackageFullName(
  [in] packageFullName: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_VerifyPackageFullName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'VerifyPackageFullName';
);

// SDK::appmodel.h
[MinOSVersion(OsWin10TH1)]
function VerifyPackageFamilyName(
  [in] packageFamilyName: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_VerifyPackageFamilyName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'VerifyPackageFamilyName';
);

// SDK::appmodel.h
[MinOSVersion(OsWin10TH1)]
function VerifyPackageId(
  [in] const packageId: TPackageId
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_VerifyPackageId: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'VerifyPackageId';
);

// SDK::appmodel.h
[MinOSVersion(OsWin10TH1)]
function VerifyApplicationUserModelId(
  [in] applicationUserModelId: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_VerifyApplicationUserModelId: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'VerifyApplicationUserModelId';
);

// SDK::appmodel.h
[MinOSVersion(OsWin10TH1)]
function VerifyPackageRelativeApplicationId(
  [in] packageRelativeApplicationId: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_VerifyPackageRelativeApplicationId: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'VerifyPackageRelativeApplicationId';
);

// Appx functions

// rev
[MinOSVersion(OsWin81)]
procedure AppXFreeMemory(
  [in] Buffer: Pointer
); stdcall; external kernelbase delayed;

var delayed_AppXFreeMemory: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'AppXFreeMemory';
);

// rev
[MinOSVersion(OsWin81)]
function AppXGetOSMaxVersionTested(
  [in] PackageFullName: PWideChar;
  [out] out OSMaxVersionTested: TPackageVersion
): HRESULT; stdcall; external kernelbase delayed;

var delayed_AppXGetOSMaxVersionTested: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'AppXGetOSMaxVersionTested';
);

// rev
[MinOSVersion(OsWin81)]
function AppXGetDevelopmentMode(
  [in] PackageFullName: PWideChar;
  [out] out DevelopmentMode: LongBool
): HRESULT; stdcall; external kernelbase delayed;

var delayed_AppXGetDevelopmentMode: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'AppXGetDevelopmentMode';
);

// rev
[MinOSVersion(OsWin81)]
function AppXGetPackageSid(
  [in] PackageFullName: PWideChar;
  [out, ReleaseWith('AppXFreeMemory')] out Sid: PSid
): HRESULT; stdcall; external kernelbase delayed;

var delayed_AppXGetPackageSid: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'AppXGetPackageSid';
);

// rev
[MinOSVersion(OsWin81)]
function AppXGetPackageCapabilities(
  [in] PackageFullName: PWideChar;
  [out] out IsFullTrust: LongBool;
  [out, ReleaseWith('AppXFreeMemory')] out Capabilities: PSidAndAttributesArray;
  [out] out Count: Cardinal
): HRESULT; stdcall; external kernelbase delayed;

var delayed_AppXGetPackageCapabilities: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'AppXGetPackageCapabilities';
);

// rev
[MinOSVersion(OsWin81)]
function AppXLookupDisplayName(
  [in] PackageSid: PSid;
  [out, ReleaseWith('AppXFreeMemory')] out DisplayName: PWideChar
): HRESULT; stdcall; external kernelbase delayed;

var delayed_AppXLookupDisplayName: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'AppXLookupDisplayName';
);

// rev
[MinOSVersion(OsWin81)]
function AppXLookupMoniker(
  [in] PackageSid: PSid;
  [out, ReleaseWith('AppXFreeMemory')] out Moniker: PWideChar
): HRESULT; stdcall; external kernelbase delayed;

var delayed_AppXLookupMoniker: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'AppXLookupMoniker';
);

// Package Properties

// rev
[MinOSVersion(OsWin81)]
function GetCurrentPackageContext(
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageContext: PPackageContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetCurrentPackageContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetCurrentPackageContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageContext(
  [in] PackageInfoReference: TPackageInfoReference;
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageContext: PPackageContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageProperty(
  [in] PackageContext: PPackageContextReference;
  [in] PropertyId: TPackageProperty;
  [in, out, NumberOfBytes] var BufferLength: Cardinal;
  [out, WritesTo] Buffer: Pointer
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageProperty: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageProperty';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackagePropertyString(
  [in] PackageContext: PPackageContextReference;
  [in] PropertyId: TPackageProperty;
  [in, out, NumberOfElements] var BufferLength: Cardinal;
  [out, WritesTo] Buffer: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackagePropertyString: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackagePropertyString';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageOSMaxVersionTested(
  [in] PackageContext: PPackageContextReference;
  [out] out OSMaxVersionTested: TPackageVersion
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageOSMaxVersionTested: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageOSMaxVersionTested';
);

// Package Application Properties

// rev
[MinOSVersion(OsWin81)]
function GetCurrentPackageApplicationContext(
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageApplicationContext: PPackageApplicationContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetCurrentPackageApplicationContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetCurrentPackageApplicationContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageApplicationContext(
  [in] PackageInfoReference: TPackageInfoReference;
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageApplicationContext: PPackageApplicationContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageApplicationContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageApplicationContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageApplicationProperty(
  [in] PackageApplicationContext: PPackageApplicationContextReference;
  [in] PropertyId: TPackageApplicationProperty;
  [in, out, NumberOfBytes] var BufferLength: Cardinal;
  [out, WritesTo] Buffer: Pointer
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageApplicationProperty: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageApplicationProperty';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageApplicationPropertyString(
  [in] PackageApplicationContext: PPackageApplicationContextReference;
  [in] PropertyId: TPackageApplicationProperty;
  [in, out, NumberOfElements] var BufferLength: Cardinal;
  [out, WritesTo] Buffer: PWideChar
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageApplicationPropertyString: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageApplicationPropertyString';
);

// Package Resource Properties

// rev
[MinOSVersion(OsWin81)]
function GetCurrentPackageResourcesContext(
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageResourcesContext: PPackageResourcesContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetCurrentPackageResourcesContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetCurrentPackageResourcesContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageResourcesContext(
  [in] PackageInfoReference: TPackageInfoReference;
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageResourcesContext: PPackageResourcesContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageResourcesContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageResourcesContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetCurrentPackageApplicationResourcesContext(
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageResourcesContext: PPackageResourcesContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetCurrentPackageApplicationResourcesContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetCurrentPackageApplicationResourcesContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageApplicationResourcesContext(
  [in] PackageInfoReference: TPackageInfoReference;
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageResourcesContext: PPackageResourcesContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageApplicationResourcesContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageApplicationResourcesContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageResourcesProperty(
  [in] PackageResourcesContext: PPackageResourcesContextReference;
  [in] PropertyId: TPackageResourcesProperty;
  [in, out, NumberOfBytes] var BufferLength: Cardinal;
  [out, WritesTo] Buffer: Pointer
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageResourcesProperty: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageResourcesProperty';
);

// Package Security Properties

// rev
[MinOSVersion(OsWin81)]
function GetCurrentPackageSecurityContext(
  [Reserved] Unused: NativeUInt;
  [out] out PackageSecurityContext: PPackageSecurityContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetCurrentPackageSecurityContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetCurrentPackageSecurityContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageSecurityContext(
  [in] PackageInfoReference: TPackageInfoReference;
  [Reserved] Unused: NativeUInt;
  [out] out PackageSecurityContext: PPackageSecurityContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageSecurityContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageSecurityContext';
);

// rev
[MinOSVersion(OsWin81)]
function GetPackageSecurityProperty(
  [in] PackageSecurityContext: PPackageSecurityContextReference;
  [in] PropertyId: TPackageSecurityProperty;
  [in, out, NumberOfBytes] var BufferLength: Cardinal;
  [out, WritesTo] Buffer: Pointer
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageSecurityProperty: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageSecurityProperty';
);

// Target Platform Properties

// rev
[MinOSVersion(OsWin10TH1)]
function GetCurrentTargetPlatformContext(
  [Reserved] Unused: NativeUInt;
  [out] out TargetPlatformContext: PTargetPlatformContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetCurrentTargetPlatformContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetCurrentTargetPlatformContext';
);

[MinOSVersion(OsWin10TH1)]
function GetTargetPlatformContext(
  [in] PackageInfoReference: TPackageInfoReference;
  [Reserved] Unused: NativeUInt;
  [out] out TargetPlatformContext: PTargetPlatformContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetTargetPlatformContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetTargetPlatformContext';
);

// rev
[MinOSVersion(OsWin10TH1)]
function GetPackageTargetPlatformProperty(
  [in] TargetPlatformContext: PTargetPlatformContextReference;
  [in] PropertyId: TTargetPlatformProperty;
  [in, out, NumberOfBytes] var BufferLength: Cardinal;
  [out, WritesTo] Buffer: Pointer
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageTargetPlatformProperty: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageTargetPlatformProperty';
);

// Package Globalization Properties

// rev
[MinOSVersion(OsWin1020H1)]
function GetCurrentPackageGlobalizationContext(
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageGlobalizationContext: PPackageGlobalizationContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetCurrentPackageGlobalizationContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetCurrentPackageGlobalizationContext';
);

// rev
[MinOSVersion(OsWin1020H1)]
function GetPackageGlobalizationContext(
  [in] PackageInfoReference: TPackageInfoReference;
  [in] Index: Cardinal;
  [Reserved] Unused: NativeUInt;
  [out] out PackageGlobalizationContext: PPackageGlobalizationContextReference
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageGlobalizationContext: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageGlobalizationContext';
);

// rev
[MinOSVersion(OsWin1020H1)]
function GetPackageGlobalizationProperty(
  [in] PackageGlobalizationContext: PPackageGlobalizationContextReference;
  [in] PropertyId: TPackageGlobalizationProperty;
  [in, out, NumberOfBytes] var BufferLength: Cardinal;
  [out, WritesTo] Buffer: Pointer
): TWin32Error; stdcall; external kernelbase delayed;

var delayed_GetPackageGlobalizationProperty: TDelayedLoadFunction = (
  DllName: kernelbase;
  FunctionName: 'GetPackageGlobalizationProperty';
);

// PRI

// rev
[MinOSVersion(OsWin8)]
function ResourceManagerQueueIsResourceReference(
  [in] Source: PWideChar
): HResult; stdcall; external MrmCoreR delayed;

var delayed_ResourceManagerQueueIsResourceReference: TDelayedLoadFunction = (
  DllName: MrmCoreR;
  FunctionName: 'ResourceManagerQueueIsResourceReference';
);

// rev
[MinOSVersion(OsWin8)]
function ResourceManagerQueueGetString(
  [in] Source: PWideChar;
  [in, opt] ParameterKey: PWideChar;
  [in, opt] ParameterValue: PWideChar;
  [out, WritesTo] Buffer: PWideChar;
  [in, NumberOfElements] BufferLength: NativeUInt;
  [out, opt, NumberOfElements] RequiredLength: PNativeUInt
): HResult; stdcall; external MrmCoreR delayed;

var delayed_ResourceManagerQueueGetString: TDelayedLoadFunction = (
  DllName: MrmCoreR;
  FunctionName: 'ResourceManagerQueueGetString';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
