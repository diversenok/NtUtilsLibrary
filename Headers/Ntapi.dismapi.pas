unit Ntapi.dismapi;

{
  This module provides definitions for Deployment Image Servicing and Management
  (DISM) API.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.WinBase, DelphiApi.Reflection,
  DelphiApi.DelayLoad;

const
  dismapi = 'dismapi.dll';

var
  delayed_dismapi: TDelayedLoadDll = (DllName: dismapi);

const
  // ADK::dismapi.h
  DISM_MOUNT_READWRITE = $00000000;
  DISM_MOUNT_READONLY = $00000001;
  DISM_MOUNT_OPTIMIZE = $00000002;
  DISM_MOUNT_CHECK_INTEGRITY = $00000004;
  DISM_MOUNT_SUPPORT_EA = $00000008; // Win MN+

  // ADK::dismapi.h
  DISM_ONLINE_IMAGE = 'DISM_{53BFAE52-B167-4E2F-A258-0A37B57FF845}';
  DISM_SESSION_DEFAULT = 0;

type
  // ADK::dismapi.h
  [SDKName('DismSession')]
  TDismSession = type Cardinal;

  // ADK::dismapi.h
  [SDKName('DISM_PROGRESS_CALLBACK')]
  TDismProgressCallback = procedure (
    [in] Current: Cardinal;
    [in] Total: Cardinal;
    [in, opt] UserData: Pointer
  ) stdcall;

  // ADK::dismapi.h
  [SDKName('DismLogLevel')]
  [NamingStyle(nsCamelCase, 'Dism')]
  TDismLogLevel = (
    DismLogErrors = 0,
    DismLogErrorsWarnings = 1,
    DismLogErrorsWarningsInfo = 2,
    DismLogErrorsWarningsInfoDebug = 3 // Win MN+
  );

  // ADK::dismapi.h
  [SDKName('DismImageIdentifier')]
  [NamingStyle(nsCamelCase, 'Dism')]
  TDismImageIdentifier = (
    DismImageIndex = 0,
    DismImageName = 1,
    DismImageNone = 2 // Win CU+
  );

  [SubEnum(DISM_MOUNT_READONLY, DISM_MOUNT_READWRITE, 'Read-write')]
  [SubEnum(DISM_MOUNT_READONLY, DISM_MOUNT_READONLY, 'Read-only')]
  [FlagName(DISM_MOUNT_OPTIMIZE, 'Optimize')]
  [FlagName(DISM_MOUNT_CHECK_INTEGRITY, 'Check Integrity')]
  [FlagName(DISM_MOUNT_SUPPORT_EA, 'Support EA')]
  TDismMountFlags = type Cardinal;

  // ADK::dismapi.h
  [NamingStyle(nsSnakeCase, 'DISM')]
  TDismUnmountFlags = (
    DISM_COMMIT_IMAGE = 0,
    DISM_DISCARD_IMAGE = 1
  );

  // ADK::dismapi.h
  [SDKName('DismString')]
  TDismString = record
    Value: PWideChar;
  end;
  PDismString = ^TDismString;
  TDismStringArray = TAnysizeArray<TDismString>;
  PDismStringArray = ^TDismStringArray;

  // ADK::dismapi.h
  [SDKName('DismImageType')]
  [NamingStyle(nsCamelCase, 'DismImageType')]
  TDismImageType = (
    DismImageTypeWim = 0,
    DismImageTypeVhd = 1
  );

  // ADK::dismapi.h
  [SDKName('DismImageBootable')]
  [NamingStyle(nsCamelCase, 'DismImageBootable')]
  TDismImageBootable = (
    DismImageBootableYes = 0,
    DismImageBootableNo = 1,
    DismImageBootableUnknown = 2
  );

  // ADK::dismapi.h
  [SDKName('DismImageInfo')]
  TDismImageInfo = packed record
    ImageType: TDismImageType;
    ImageIndex: Cardinal;
    ImageName: PWideChar;
    ImageDescription: PWideChar;
    [Bytes] ImageSize: UInt64;
    Architecture: TProcessorArchitecture32;
    ProductName: PWideChar;
    EditionId: PWideChar;
    InstallationType: PWideChar;
    Hal: PWideChar;
    ProductType: PWideChar;
    ProductSuite: PWideChar;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    Build: Cardinal;
    SpBuild: Cardinal;
    SpLevel: Cardinal;
    Bootable: TDismImageBootable;
    SystemRoot: PWideChar;
    Language: PDismStringArray;
    LanguageCount: Cardinal;
    DefaultLanguageIndex: Cardinal;
    CustomizedInfo: Pointer;
  end;
  PDismImageInfo = ^TDismImageInfo;
  TDismImageInfoArray = TAnysizeArray<TDismImageInfo>;
  PDismImageInfoArray = ^TDismImageInfoArray;

  // ADK::dismapi.h
  [SDKName('DismMountMode')]
  [NamingStyle(nsCamelCase, 'Dism')]
  TDismMountMode = (
    DismReadWrite = 0,
    DismReadOnly = 1
  );

  // ADK::dismapi.h
  [SDKName('DismMountMode')]
  [NamingStyle(nsCamelCase, 'DismMountStatus')]
  TDismMountStatus = (
    DismMountStatusOk = 0,
    DismMountStatusNeedsRemount = 1,
    DismMountStatusInvalid = 2
  );

  // ADK::dismapi.h
  [SDKName('DismMountedImageInfo')]
  TDismMountedImageInfo = packed record
    MountPath: PWideChar;
    ImageFilePath: PWideChar;
    ImageIndex: Cardinal;
    MountMode: TDismMountMode;
    MountStatus: TDismMountStatus;
  end;
  PDismMountedImageInfo = ^TDismMountedImageInfo;
  TDismMountedImageInfoArray = TAnysizeArray<TDismMountedImageInfo>;
  PDismMountedImageInfoArray = ^TDismMountedImageInfoArray;

  // ADK::dismapi.h
  [SDKName('DismImageHealthState')]
  [NamingStyle(nsCamelCase, 'DismImage')]
  TDismImageHealthState = (
    DismImageHealthy = 0,
    DismImageRepairable = 1,
    DismImageNonRepairable = 2
  );

  // ADK::dismapi.h
  [SDKName('DismPackageIdentifier')]
  [NamingStyle(nsCamelCase, 'DismPackage')]
  TDismPackageIdentifier = (
    DismPackageNone = 0,
    DismPackageName = 1,
    DismPackagePath = 2
  );

  // ADK::dismapi.h
  [SDKName('DismPackageFeatureState')]
  [NamingStyle(nsCamelCase, 'DismState')]
  TDismPackageFeatureState = (
    DismStateNotPresent = 0,
    DismStateUninstallPending = 1,
    DismStateStaged = 2,
    DismStateRemoved = 3,
    DismStateInstalled = 4,
    DismStateInstallPending = 5,
    DismStateSuperseded = 6,
    DismStatePartiallyInstalled = 7
  );

  // ADK::dismapi.h
  [SDKName('DismReleaseType')]
  [NamingStyle(nsCamelCase, 'DismReleaseType')]
  TDismReleaseType = (
    DismReleaseTypeCriticalUpdate = 0,
    DismReleaseTypeDriver = 1,
    DismReleaseTypeFeaturePack = 2,
    DismReleaseTypeHotfix = 3,
    DismReleaseTypeSecurityUpdate = 4,
    DismReleaseTypeSoftwareUpdate = 5,
    DismReleaseTypeUpdate = 6,
    DismReleaseTypeUpdateRollup = 7,
    DismReleaseTypeLanguagePack = 8,
    DismReleaseTypeFoundation = 9,
    DismReleaseTypeServicePack = 10,
    DismReleaseTypeProduct = 11,
    DismReleaseTypeLocalPack = 12,
    DismReleaseTypeOther = 13,
    DismReleaseTypeOnDemandPack = 14 // Windows 10 RS2+
  );

  // ADK::dismapi.h
  [SDKName('DismPackage')]
  TDismPackage = packed record
    PackageName: PWideChar;
    PackageState: TDismPackageFeatureState;
    ReleaseType: TDismReleaseType;
    InstallTime: TSystemTime;
  end;
  PDismPackage = ^TDismPackage;
  TDismPackageArray = TAnysizeArray<TDismPackage>;
  PDismPackageArray = ^TDismPackageArray;

  // ADK::dismapi.h
  [SDKName('DismRestartType')]
  [NamingStyle(nsCamelCase, 'DismRestart')]
  TDismRestartType = (
    DismRestartNo = 0,
    DismRestartPossible = 1,
    DismRestartRequired = 2
  );

  // ADK::dismapi.h
  [SDKName('DismFullyOfflineInstallableType')]
  [NamingStyle(nsCamelCase, 'Dism')]
  TDismFullyOfflineInstallableType = (
    DismFullyOfflineInstallable = 0,
    DismFullyOfflineNotInstallable = 1,
    DismFullyOfflineInstallableUndetermined = 2
  );

  // ADK::dismapi.h
  [SDKName('DismCustomProperty')]
  TDismCustomProperty = packed record
    Name: PWideChar;
    Value: PWideChar;
    Path: PWideChar;
  end;
  PDismCustomProperty = ^TDismCustomProperty;
  TDismCustomPropertyArray = TAnysizeArray<TDismCustomProperty>;
  PDismCustomPropertyArray = ^TDismCustomPropertyArray;

  // ADK::dismapi.h
  [SDKName('DismFeature')]
  TDismFeature = packed record
    FeatureName: PWideChar;
    State: TDismPackageFeatureState;
  end;
  PDismFeature = ^TDismFeature;
  TDismFeatureArray = TAnysizeArray<TDismFeature>;
  PDismFeatureArray = ^TDismFeatureArray;

  // ADK::dismapi.h
  [SDKName('DismPackageInfo')]
  TDismPackageInfo = packed record
    PackageName: PWideChar;
    PackageState: TDismPackageFeatureState;
    ReleaseType: TDismReleaseType;
    InstallTime: TSystemTime;
    Applicable: LongBool;
    Copyright: PWideChar;
    Company: PWideChar;
    CreationTime: TSystemTime;
    DisplayName: PWideChar;
    Description: PWideChar;
    InstallClient: PWideChar;
    InstallPackageName: PWideChar;
    LastUpdateTime: TSystemTime;
    ProductName: PWideChar;
    ProductVersion: PWideChar;
    RestartRequired: TDismRestartType;
    FullyOffline: TDismFullyOfflineInstallableType;
    SupportInformation: PWideChar;
    CustomProperty: PDismCustomPropertyArray;
    [NumberOfElements] CustomPropertyCount: Cardinal;
    Feature: PDismFeatureArray;
    [NumberOfElements] FeatureCount: Cardinal;
  end;
  PDismPackageInfo = ^TDismPackageInfo;

  // ADK::dismapi.h
  [SDKName('DismFeatureInfo')]
  TDismFeatureInfo = packed record
    FeatureName: PWideChar;
    FeatureState: TDismPackageFeatureState;
    DisplayName: PWideChar;
    Description: PWideChar;
    RestartRequired: TDismRestartType;
    CustomProperty: PDismCustomPropertyArray;
    [NumberOfElements] CustomPropertyCount: Cardinal;
  end;
  PDismFeatureInfo = ^TDismFeatureInfo;

  // ADK::dismapi.h
  [SDKName('DismDriverSignature')]
  [NamingStyle(nsCamelCase, 'DismDriverSignature')]
  TDismDriverSignature = (
    DismDriverSignatureUnknown = 0,
    DismDriverSignatureUnsigned = 1,
    DismDriverSignatureSigned = 2
  );

  // ADK::dismapi.h
  [SDKName('DismDriverPackage')]
  TDismDriverPackage = packed record
    PublishedName: PWideChar;
    OriginalFileName: PWideChar;
    InBox: LongBool;
    CatalogFile: PWideChar;
    ClassName: PWideChar;
    ClassGuid: PWideChar;
    ClassDescription: PWideChar;
    BootCritical: LongBool;
    DriverSignature: TDismDriverSignature;
    ProviderName: PWideChar;
    Date: TSystemTime;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    Build: Cardinal;
    Revision: Cardinal;
  end;
  PDismDriverPackage = ^TDismDriverPackage;
  TDismDriverPackageArray = TAnysizeArray<TDismDriverPackage>;
  PDismDriverPackageArray = TDismDriverPackageArray;

  // ADK::dismapi.h
  [SDKName('DismDriver')]
  TDismDriver = packed record
    ManufacturerName: PWideChar;
    HardwareDescription: PWideChar;
    HardwareId: PWideChar;
    Architecture: Cardinal;
    ServiceName: PWideChar;
    CompatibleIds: PWideChar;
    ExcludeIds: PWideChar;
  end;
  PDismDriver = ^TDismDriver;
  TDismDriverArray = TAnysizeArray<TDismDriver>;
  PDismDriverArray = TDismDriverArray;

  // ADK::dismapi.h
  [SDKName('DismCapability')]
  TDismCapability = packed record
    Name: PWideChar;
    State: TDismPackageFeatureState;
  end;
  PDismCapability = ^TDismCapability;
  TDismCapabilityArray = TAnysizeArray<TDismCapability>;
  PDismCapabilityArray = ^TDismCapabilityArray;

  // ADK::dismapi.h
  [SDKName('DismCapabilityInfo')]
  TDismCapabilityInfo = packed record
    Name: PWideChar;
    State: TDismPackageFeatureState;
    DisplayName: PWideChar;
    Description: PWideChar;
    [Bytes] DownloadSize: Cardinal;
    [Bytes] InstallSize: Cardinal;
  end;
  PDismCapabilityInfo = ^TDismCapabilityInfo;
  TDismCapabilityInfoArray = TAnysizeArray<TDismCapabilityInfo>;
  PDismCapabilityInfoArray = ^TDismCapabilityInfoArray;

  // ADK::dismapi.h
  [NamingStyle(nsSnakeCase, 'DISM_RESERVED_STORAGE')]
  TDismReserveedStorageState = (
    DISM_RESERVED_STORAGE_DISABLED = 0,
    DISM_RESERVED_STORAGE_ENABLED =  1
  );

  // ADK::dismapi.h
  [SDKName('DismAppxPackage')]
  TDismAppxPackage = packed record
    PackageName: PWideChar;
    DisplayName: PWideChar;
    PublisherId: PWideChar;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    Build: Cardinal;
    RevisionNumber: Cardinal;
    Architecture: Cardinal;
    ResourceId: PWideChar;
    InstallLocation: PWideChar;
    [MayReturnNil] Region: PWideChar;
  end;
  PDismAppxPackage = ^TDismAppxPackage;
  TDismAppxPackageArray = TAnysizeArray<TDismAppxPackage>;
  PDismAppxPackageArray = ^TDismAppxPackageArray;

const
  // ADK::dismapi.h
  DismImageTypeUnsupported = TDismImageType(-1);

  // ADK::dismapi.h
  DISMAPI_S_RELOAD_IMAGE_SESSION_REQUIRED = $00000001;
  DISMAPI_E_DISMAPI_NOT_INITIALIZED = $C0040001;
  DISMAPI_E_SHUTDOWN_IN_PROGRESS = $C0040002;
  DISMAPI_E_OPEN_SESSION_HANDLES = $C0040003;
  DISMAPI_E_INVALID_DISM_SESSION = $C0040004;
  DISMAPI_E_INVALID_IMAGE_INDEX = $C0040005;
  DISMAPI_E_INVALID_IMAGE_NAME = $C0040006;
  DISMAPI_E_UNABLE_TO_UNMOUNT_IMAGE_PATH = $C0040007;
  DISMAPI_E_LOGGING_DISABLED = $C0040009;
  DISMAPI_E_OPEN_HANDLES_UNABLE_TO_UNMOUNT_IMAGE_PATH = $C004000A;
  DISMAPI_E_OPEN_HANDLES_UNABLE_TO_MOUNT_IMAGE_PATH = $C004000B;
  DISMAPI_E_OPEN_HANDLES_UNABLE_TO_REMOUNT_IMAGE_PATH = $C004000C;
  DISMAPI_E_PARENT_FEATURE_DISABLED = $C004000D;
  DISMAPI_E_MUST_SPECIFY_ONLINE_IMAGE = $C004000E;
  DISMAPI_E_INVALID_PRODUCT_KEY = $C004000F;
  DISMAPI_E_MUST_SPECIFY_INDEX_OR_NAME = $C0040020;
  DISMAPI_E_NEEDS_REMOUNT = $C1510114;
  DISMAPI_E_UNKNOWN_FEATURE = $800f080c;
  DISMAPI_E_BUSY = $800f0902;

// ADK::dismapi.h
[RequiresAdmin]
[Result: ReleaseWith('DismShutdown')]
function DismInitialize(
  [in] LogLevel: TDismLogLevel;
  [in, opt] LogFilePath: PWideChar;
  [in, opt] ScratchDirectory: PWideChar
): HResult; stdcall; external dismapi delayed;

var delayed_DismInitialize: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismInitialize';
);

// ADK::dismapi.h
function DismShutdown(
): HResult; stdcall; external dismapi delayed;

var delayed_DismShutdown: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismShutdown';
);

// ADK::dismapi.h
function DismDelete(
  [in] DismStructure: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismDelete: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismDelete';
);

// ADK::dismapi.h
[Result: ReleaseWith('DismUnmountImage')]
function DismMountImage(
  [in] ImageFilePath: PWideChar;
  [in] MountPath: PWideChar;
  [in] ImageIndex: Cardinal;
  [in, opt] ImageName: PWideChar;
  [in] ImageIdentifier: TDismImageIdentifier;
  [in] Flags: TDismMountFlags;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismMountImage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismMountImage';
);

// ADK::dismapi.h
function DismUnmountImage(
  [in] MountPath: PWideChar;
  [in] Flags: TDismUnmountFlags;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismUnmountImage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismUnmountImage';
);

// ADK::dismapi.h
function DismOpenSession(
  [in] ImagePath: PWideChar;
  [in, opt] WindowsDirectory: PWideChar;
  [in, opt] SystemDrive: PWideChar;
  [out, ReleaseWith('DismCloseSession')] out Session: TDismSession
): HResult; stdcall; external dismapi delayed;

var delayed_DismOpenSession: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismOpenSession';
);

// ADK::dismapi.h
function DismCloseSession(
  [in] Session: TDismSession
): HResult; stdcall; external dismapi delayed;

var delayed_DismCloseSession: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismCloseSession';
);

// ADK::dismapi.h
function DismGetLastErrorMessage(
  [out, MayReturnNil, ReleaseWith('DismDelete')] out ErrorMessage: PDismString
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetLastErrorMessage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetLastErrorMessage';
);

// ADK::dismapi.h
function DismRemountImage(
  [in] MountPath: PWideChar
): HResult; stdcall; external dismapi delayed;

var delayed_DismRemountImage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismRemountImage';
);

// ADK::dismapi.h
function DismCommitImage(
  [in] Session: TDismSession;
  [in] Flags: Cardinal;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismCommitImage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismCommitImage';
);

// ADK::dismapi.h
function DismGetImageInfo(
  [in] ImageFilePath: PWideChar;
  [out, ReleaseWith('DismDelete')] out ImageInfo: PDismImageInfoArray;
  [out, NumberOfElements] out Count: Cardinal
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetImageInfo: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetImageInfo';
);

// ADK::dismapi.h
function DismGetMountedImageInfo(
  [out, ReleaseWith('DismDelete')] out MountedImageInfo:
    PDismMountedImageInfoArray;
  [out, NumberOfElements] out Count: Cardinal
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetMountedImageInfo: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetMountedImageInfo';
);

// ADK::dismapi.h
function DismCleanupMountpoints(
): HResult; stdcall; external dismapi delayed;

var delayed_DismCleanupMountpoints: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismCleanupMountpoints';
);

// ADK::dismapi.h
function DismCheckImageHealth(
  [in] Session: TDismSession;
  [in] ScanImage: LongBool;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer;
  [out] out ImageHealth: TDismImageHealthState
): HResult; stdcall; external dismapi delayed;

var delayed_DismCheckImageHealth: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismCheckImageHealth';
);

// ADK::dismapi.h
function DismRestoreImageHealth(
  [in] Session: TDismSession;
  [in, opt] const SourcePaths: TArray<PWideChar>;
  [in, opt, NumberOfElements] SourcePathCount: Cardinal;
  [in] LimitAccess: LongBool;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismRestoreImageHealth: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismRestoreImageHealth';
);

// ADK::dismapi.h
function DismAddPackage(
  [in] Session: TDismSession;
  [in] PackagePath: PWideChar;
  [in] IgnoreCheck: LongBool;
  [in] PreventPending: LongBool;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismAddPackage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismAddPackage';
);

// ADK::dismapi.h
function DismRemovePackage(
  [in] Session: TDismSession;
  [in] Identifier: PWideChar;
  [in] PackageIdentifier: TDismPackageIdentifier;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismRemovePackage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismRemovePackage';
);

// ADK::dismapi.h
function DismEnableFeature(
  [in] Session: TDismSession;
  [in] FeatureName: PWideChar;
  [in, opt] Identifier: PWideChar;
  [in, opt] PackageIdentifier: TDismPackageIdentifier;
  [in] LimitAccess: LongBool;
  [in, opt] const SourcePaths: TArray<PWideChar>;
  [in, opt, NumberOfElements] SourcePathCount: Cardinal;
  [in] EnableAll: LongBool;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismEnableFeature: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismEnableFeature';
);

// ADK::dismapi.h
function DismDisableFeature(
  [in] Session: TDismSession;
  [in] FeatureName: PWideChar;
  [in, opt] PackageName: PWideChar;
  [in] RemovePayload: LongBool;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismDisableFeature: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismDisableFeature';
);

// ADK::dismapi.h
function DismGetPackages(
  [in] Session: TDismSession;
  [out, ReleaseWith('DismDelete')] out Package: PDismPackageArray;
  [out] out Count: Cardinal
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetPackages: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetPackages';
);

// ADK::dismapi.h
function DismGetPackageInfo(
  [in] Session: TDismSession;
  [in] Identifier: PWideChar;
  [in] PackageIdentifier: TDismPackageIdentifier;
  [out, ReleaseWith('DismDelete')] out PackageInfo: PDismPackageInfo
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetPackageInfo: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetPackageInfo';
);

// ADK::dismapi.h
function DismGetFeatures(
  [in] Session: TDismSession;
  [in, opt] Identifier: PWideChar;
  [in, opt] PackageIdentifier: TDismPackageIdentifier;
  [out, ReleaseWith('DismDelete')] out Feature: PDismFeatureArray;
  [out, NumberOfElements] out Count: Cardinal
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetFeatures: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetFeatures';
);

// ADK::dismapi.h
function DismGetFeatureInfo(
  [in] Session: TDismSession;
  [in] FeatureName: PWideChar;
  [in, opt] Identifier: PWideChar;
  [in, opt] PackageIdentifier: TDismPackageIdentifier;
  [out, ReleaseWith('DismDelete')] out FeatureInfo: PDismFeatureInfo
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetFeatureInfo: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetFeatureInfo';
);

// ADK::dismapi.h
function DismGetFeatureParent(
  [in] Session: TDismSession;
  [in] FeatureName: PWideChar;
  [in, opt] Identifier: PWideChar;
  [in, opt] PackageIdentifier: TDismPackageIdentifier;
  [out, ReleaseWith('DismDelete')] out Feature: PDismFeatureArray;
  [out, NumberOfElements] out Count: Cardinal
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetFeatureParent: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetFeatureParent';
);

// ADK::dismapi.h
function DismApplyUnattend(
  [in] Session: TDismSession;
  [in] UnattendFile: PWideChar;
  [in] SingleSession: LongBool
): HResult; stdcall; external dismapi delayed;

var delayed_DismApplyUnattend: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismApplyUnattend';
);

// ADK::dismapi.h
function DismAddDriver(
  [in] Session: TDismSession;
  [in] DriverPath: PWideChar;
  [in] ForceUnsigned: LongBool
): HResult; stdcall; external dismapi delayed;

var delayed_DismAddDriver: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismAddDriver';
);

// ADK::dismapi.h
function DismRemoveDriver(
  [in] Session: TDismSession;
  [in] DriverPath: PWideChar
): HResult; stdcall; external dismapi delayed;

var delayed_DismRemoveDriver: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismRemoveDriver';
);

// ADK::dismapi.h
function DismGetDrivers(
  [in] Session: TDismSession;
  [in] AllDrivers: LongBool;
  [out, ReleaseWith('DismDelete')] out DriverPackage: PDismDriverPackageArray;
  [out, NumberOfElements] out Count: Cardinal
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetDrivers: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetDrivers';
);

// ADK::dismapi.h
function DismGetDriverInfo(
  [in] Session: TDismSession;
  [in] DriverPath: PWideChar;
  [out, ReleaseWith('DismDelete')] out Driver: PDismDriverArray;
  [out, NumberOfElements] out Count: Cardinal;
  [out, opt, ReleaseWith('DismDelete')] out DriverPackage: PDismDriverPackage
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetDriverInfo: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetDriverInfo';
);

// ADK::dismapi.h, Windows 10 ?+
function DismGetCapabilities(
  [in] Session: TDismSession;
  [out, ReleaseWith('DismDelete')] out Capability: PDismCapabilityArray;
  [out, NumberOfElements] out Count: Cardinal
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetCapabilities: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetCapabilities';
);

// ADK::dismapi.h, Windows 10 ?+
function DismGetCapabilityInfo(
  [in] Session: TDismSession;
  [in] Name: PWideChar;
  [out, ReleaseWith('DismDelete')] out Info: PDismCapabilityInfo
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetCapabilityInfo: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetCapabilityInfo';
);

// ADK::dismapi.h, Windows 10 ?+
function DismAddCapability(
  [in] Session: TDismSession;
  [in] Name: PWideChar;
  [in] LimitAccess: LongBool;
  [in, opt] const SourcePaths: TArray<PWideChar>;
  [in, opt, NumberOfElements] SourcePathCount: Cardinal;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismAddCapability: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismAddCapability';
);

// ADK::dismapi.h, Windows 10 ?+
function DismRemoveCapability(
  [in] Session: TDismSession;
  [in] Name: PWideChar;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismRemoveCapability: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismRemoveCapability';
);

// ADK::dismapi.h
function DismGetReservedStorageState(
  [in] Session: TDismSession;
  [out] out State: TDismReserveedStorageState
): HResult; stdcall; external dismapi delayed;

var delayed_DismGetReservedStorageState: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismGetReservedStorageState';
);

// ADK::dismapi.h
function DismSetReservedStorageState(
  [in] Session: TDismSession;
  [in] State: TDismReserveedStorageState
): HResult; stdcall; external dismapi delayed;

var delayed_DismSetReservedStorageState: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismSetReservedStorageState';
);

// ADK::dismapi.h
function DismGetProvisionedAppxPackages(
  [in] Session: TDismSession;
  [out, ReleaseWith('DismDelete')] Package: PDismAppxPackageArray;
  [out, NumberOfElements] out Count: Cardinal
): HResult; stdcall; external dismapi delayed name '_DismGetProvisionedAppxPackages';

var delayed_DismGetProvisionedAppxPackages: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: '_DismGetProvisionedAppxPackages';
);

// ADK::dismapi.h
function DismRemoveProvisionedAppxPackage(
  [in] Session: TDismSession;
  [in] PackageName: PWideChar
): HResult; stdcall; external dismapi delayed name '_DismRemoveProvisionedAppxPackage';

var delayed_DismRemoveProvisionedAppxPackage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: '_DismRemoveProvisionedAppxPackage';
);

// ADK::dismapi.h
function DismAddLanguage(
  [in] Session: TDismSession;
  [in] LanguageName: PWideChar;
  [in] PreventPending: LongBool;
  [in] LimitAccess: LongBool;
  [in, opt] const SourcePaths: TArray<PWideChar>;
  [in, opt, NumberOfElements] SourcePathCount: Cardinal;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismAddLanguage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismAddLanguage';
);

// ADK::dismapi.h
function DismRemoveLanguage(
  [in] Session: TDismSession;
  [in] LanguageName: PWideChar;
  [in, opt] CancelEvent: THandle;
  [in, opt] Progress: TDismProgressCallback;
  [in, opt] UserData: Pointer
): HResult; stdcall; external dismapi delayed;

var delayed_DismRemoveLanguage: TDelayedLoadFunction = (
  DllName: dismapi;
  FunctionName: 'DismRemoveLanguage';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
