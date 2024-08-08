unit NtUtils.Dism;

{
  This module provides support for using DISM (Deployment Image Servicing and
  Managemen) API.
}

interface

uses
  Ntapi.WinNt, Ntapi.dismapi, Ntapi.ntseapi, Ntapi.WinBase, Ntapi.Versions,
  NtUtils, DelphiApi.Reflection;

const
  // The online image pseudo-path for opening sessions
  DISM_ONLINE_IMAGE = Ntapi.dismapi.DISM_ONLINE_IMAGE;

type
  IDismSession = NtUtils.IHandle;

  // An anonymous callback for monitoring progress
  TDismxProgressCallback = reference to procedure (Current, Total: Cardinal);

  [MinOSVersion(OsWin8)]
  TDismxImageInfo = record
    ImageType: TDismImageType;
    ImageIndex: Cardinal;
    ImageName: String;
    ImageDescription: String;
    [Bytes] ImageSize: UInt64;
    Architecture: TProcessorArchitecture32;
    ProductName: String;
    EditionId: String;
    InstallationType: String;
    Hal: String;
    ProductType: String;
    ProductSuite: String;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    Build: Cardinal;
    SpBuild: Cardinal;
    SpLevel: Cardinal;
    Bootable: TDismImageBootable;
    SystemRoot: String;
    Language: TArray<String>;
    DefaultLanguageIndex: Cardinal;
  end;

  [MinOSVersion(OsWin8)]
  TDismxMountedImageInfo = record
    MountPath: String;
    ImageFilePath: String;
    ImageIndex: Cardinal;
    MountMode: TDismMountMode;
    MountStatus: TDismMountStatus;
  end;

  [MinOSVersion(OsWin8)]
  TDismxPackage = record
    PackageName: String;
    PackageState: TDismPackageFeatureState;
    ReleaseType: TDismReleaseType;
    InstallTime: TSystemTime;
  end;

  [MinOSVersion(OsWin8)]
  TDismxCustomProperty = record
    Name: String;
    Value: String;
    Path: String;
  end;

  [MinOSVersion(OsWin8)]
  TDismxFeature = record
    FeatureName: String;
    State: TDismPackageFeatureState;
  end;

  [MinOSVersion(OsWin8)]
  TDismxPackageInfo = record
    PackageName: String;
    PackageState: TDismPackageFeatureState;
    ReleaseType: TDismReleaseType;
    InstallTime: TSystemTime;
    Applicable: Boolean;
    Copyright: String;
    Company: String;
    CreationTime: TSystemTime;
    DisplayName: String;
    Description: String;
    InstallClient: String;
    InstallPackageName: String;
    LastUpdateTime: TSystemTime;
    ProductName: String;
    ProductVersion: String;
    RestartRequired: TDismRestartType;
    FullyOffline: TDismFullyOfflineInstallableType;
    SupportInformation: String;
    CustomProperties: TArray<TDismxCustomProperty>;
    Features: TArray<TDismxFeature>;
  end;

  [MinOSVersion(OsWin8)]
  TDismxFeatureInfo = record
    FeatureName: String;
    FeatureState: TDismPackageFeatureState;
    DisplayName: String;
    Description: String;
    RestartRequired: TDismRestartType;
    CustomProperties: TArray<TDismxCustomProperty>;
  end;

  [MinOSVersion(OsWin8)]
  TDismxDriverPackage = record
    PublishedName: String;
    OriginalFileName: String;
    InBox: Boolean;
    CatalogFile: String;
    ClassName: String;
    ClassGuid: String;
    ClassDescription: String;
    BootCritical: Boolean;
    DriverSignature: TDismDriverSignature;
    ProviderName: String;
    Date: TSystemTime;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    Build: Cardinal;
    Revision: Cardinal;
  end;
  PDismxDriverPackage = ^TDismxDriverPackage;

  [MinOSVersion(OsWin8)]
  TDismxDriver = record
    ManufacturerName: String;
    HardwareDescription: String;
    HardwareId: String;
    Architecture: TProcessorArchitecture32;
    ServiceName: String;
    CompatibleIds: String;
    ExcludeIds: String;
  end;

  [MinOSVersion(OsWin10TH1)]
  TDismxCapability = record
    Name: String;
    State: TDismPackageFeatureState;
  end;

  [MinOSVersion(OsWin10TH1)]
  TDismxCapabilityInfo = record
    Name: String;
    State: TDismPackageFeatureState;
    DisplayName: String;
    Description: String;
    [Bytes] DownloadSize: Cardinal;
    [Bytes] InstallSize: Cardinal;
  end;

  [MinOSVersion(OsWin81)]
  TDismxAppxPackage = record
    PackageName: String;
    DisplayName: String;
    PublisherId: String;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    Build: Cardinal;
    RevisionNumber: Cardinal;
    Architecture: TProcessorArchitecture32;
    ResourceId: String;
    InstallLocation: String;
    Region: String;
  end;

{ Initialization }

// Initialize DISM API
[RequiresAdmin]
[MinOSVersion(OsWin8)]
[Result: ReleaseWith('DismxShutdown')]
function DismxInitialize(
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

// Uninitialize DISM API
[MinOSVersion(OsWin8)]
function DismxShutdown(
): TNtxStatus;

// Initialize DISM API and uninitialize it later
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxInitializeAuto(
  out Uninitializer: IAutoReleasable;
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

// Initialize DISM API once and uninitialize it on this unit finalizatoin
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxInitializeOnce(
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

{ Images }

// Open a DISM session for the specified online/offline image path
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxOpenSession(
  out hxDismSession: IDismSession;
  const ImagePath: String;
  [opt] const WindowsDirectory: String = '';
  [opt] const SystemDrive: String = ''
): TNtxStatus;

// Query information about an image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxGetImageInfo(
  const ImageFilePath: String;
  out ImageInfo: TArray<TDismxImageInfo>
): TNtxStatus;

// Mount a .wim or a .vhdx image to a given directory
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxMountImage(
  const ImageFilePath: String;
  const MountPath: String;
  [opt] ImageIndex: Cardinal;
  [opt] ImageName: String;
  ImageIdentifier: TDismImageIdentifier;
  Flags: TDismMountFlags = DISM_MOUNT_READONLY;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Unmount a previously mounted image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxUnmountImage(
  const MountPath: String;
  Flags: TDismUnmountFlags = DISM_DISCARD_IMAGE;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Remount a previously mounted image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxRemountImage(
  const MountPath: String
): TNtxStatus;

// Save changes to a mounted image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxCommitImage(
  const hxDismSession: IDismSession;
  [in] Flags: Cardinal;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

// Query information about a mounted image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxGetMountedImageInfo(
  out ImageInfo: TArray<TDismxMountedImageInfo>
): TNtxStatus;

// Removes files from corrupted and invalid mount points
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxCleanupMountpoints(
): TNtxStatus;

// Verify the image or check if it has already been flagged as corrupted
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxCheckImageHealth(
  const hxDismSession: IDismSession;
  ScanImage: Boolean;
  out ImageHealth: TDismImageHealthState;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

// Repairs a corrupted image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxRestoreImageHealth(
  const hxDismSession: IDismSession;
  LimitAccess: Boolean;
  [opt] const SourcePaths: TArray<String> = nil;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

{ Packages }

// Add a .cab or a .msu to an image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxAddPackage(
  const hxDismSession: IDismSession;
  const PackagePath: String;
  IgnoreCheck: Boolean;
  PreventPending: Boolean;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

// Add a .cab or a .msu from an image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxRemovePackage(
  const hxDismSession: IDismSession;
  const Identifier: String;
  PackageIdentifier: TDismPackageIdentifier;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

// Enumerate .cab or .msu packages in an image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxEnumeratePackages(
  const hxDismSession: IDismSession;
  out Packages: TArray<TDismxPackage>
): TNtxStatus;

// Query information about a .cab or a .msu package
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxQueryPackage(
  const hxDismSession: IDismSession;
  const Identifier: String;
  PackageIdentifier: TDismPackageIdentifier;
  out PackageInfo: TDismxPackageInfo
): TNtxStatus;

{ Features }

// Enumerate features in a a .cab or a .msu package
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxEnumerateFeatures(
  const hxDismSession: IDismSession;
  out Features: TArray<TDismxFeature>;
  [opt] const Identifier: String = '';
  [opt] PackageIdentifier: TDismPackageIdentifier = DismPackageNone
): TNtxStatus;

// Query information about a package feature
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxQueryFeature(
  const hxDismSession: IDismSession;
  const FeatureName: String;
  out FeatureInfo: TDismxFeatureInfo;
  [opt] const Identifier: String = '';
  [opt] PackageIdentifier: TDismPackageIdentifier = DismPackageNone
): TNtxStatus;

// Enable a package feature
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxEnableFeature(
  const hxDismSession: IDismSession;
  const FeatureName: String;
  LimitAccess: Boolean;
  EnableAll: Boolean;
  [opt] const Identifier: String = '';
  [opt] PackageIdentifier: TDismPackageIdentifier = DismPackageNone;
  [opt] const SourcePaths: TArray<String> = nil;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

// Disable a package feature
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxDisableFeature(
  const hxDismSession: IDismSession;
  const FeatureName: String;
  RemovePayload: Boolean;
  [opt] const PackageName: String = '';
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

// Enumerate dependencies of a package feature
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxEnumerateFeatureParents(
  const hxDismSession: IDismSession;
  const FeatureName: String;
  out Features: TArray<TDismxFeature>;
  [opt] const Identifier: String = '';
  [opt] PackageIdentifier: TDismPackageIdentifier = DismPackageNone
): TNtxStatus;

{ Unattend }

// Apply an unattend XML to the image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxApplyUnattend(
  const hxDismSession: IDismSession;
  const UnattendFile: String;
  SingleSession: Boolean = True
): TNtxStatus;

{ Drivers }

// Add a driver into an image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxAddDriver(
  const hxDismSession: IDismSession;
  const DriverPath: String;
  ForceUnsigned: Boolean = False
): TNtxStatus;

// Add a driver into an image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxRemoveDriver(
  const hxDismSession: IDismSession;
  const DriverPath: String
): TNtxStatus;

// Enumerate all or out-of-the-box only drivers in an image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxEnumerateDrivers(
  const hxDismSession: IDismSession;
  AllDrivers: Boolean;
  out DriverPackages: TArray<TDismxDriverPackage>
): TNtxStatus;

// Query driver information from an image
[RequiresAdmin]
[MinOSVersion(OsWin8)]
function DismxQueryDriver(
  const hxDismSession: IDismSession;
  const DriverPath: String;
  out Drivers: TArray<TDismxDriver>;
  [out, opt] DriverPackage: PDismxDriverPackage = nil
): TNtxStatus;

{ Capabilities }

// Enumerate capabilities in an image
[RequiresAdmin]
[MinOSVersion(OsWin10TH1)]
function DismxEnumerateCapabilities(
  const hxDismSession: IDismSession;
  out Capabilities: TArray<TDismxCapability>
): TNtxStatus;

// Query information about a capability in an image
[RequiresAdmin]
[MinOSVersion(OsWin10TH1)]
function DismxQueryCapability(
  const hxDismSession: IDismSession;
  const Name: String;
  out Info: TDismxCapabilityInfo
): TNtxStatus;

// Add a capability to an image
[RequiresAdmin]
[MinOSVersion(OsWin10TH1)]
function DismxAddCapability(
  const hxDismSession: IDismSession;
  const Name: String;
  LimitAccess: Boolean;
  [opt] const SourcePaths: TArray<String> = nil;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

// Remove a capability to an image
[RequiresAdmin]
[MinOSVersion(OsWin10TH1)]
function DismxRemoveCapability(
  const hxDismSession: IDismSession;
  const Name: String;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] const CancelEvent: IHandle = nil
): TNtxStatus;

{ Appx }

// Enumerate Appx packages in an image
[RequiresAdmin]
[MinOSVersion(OsWin81)]
function DismxEnumerateProvisionedAppxPackages(
  const hxDismSession: IDismSession;
  out Packages: TArray<TDismxAppxPackage>
): TNtxStatus;

// Register an Appx package in an image
[RequiresAdmin]
[MinOSVersion(OsWin81)]
function DismxAddProvisionedAppxPackage(
  const hxDismSession: IDismSession;
  const AppPath: String;
  SkipLicense: Boolean;
  [opt] const DependencyPackages: TArray<String> = nil;
  [opt] const OptionalPackages: TArray<String> = nil;
  [opt] const LicensePaths: TArray<String> = nil;
  [opt] const CustomDataPath: String = '';
  [opt] const Region: String = '';
  StubPackageOption: TDismStubPackageOption = DismStubPackageOptionNone
): TNtxStatus;

// Remove an Appx package from an image
[RequiresAdmin]
[MinOSVersion(OsWin81)]
function DismxRemoveProvisionedAppxPackage(
  const hxDismSession: IDismSession;
  const PackageName: String
): TNtxStatus;

implementation

uses
  NtUtils.Ldr, NtUtils.Synchronization, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Auto resources }

type
  TDismSessionAutoHandle = class (TCustomAutoHandle, IDismSession)
    procedure Release; override;
  end;

procedure TDismSessionAutoHandle.Release;
begin
  if (FHandle <> 0) and LdrxCheckDelayedImport(
    delayed_DismCloseSession).IsSuccess then
    DismCloseSession(FHandle);

  FHandle := 0;
  inherited;
end;

type
  TDismAutoMemory = class (TCustomAutoPointer, IAutoPointer)
    procedure Release; override;
  end;

procedure TDismAutoMemory.Release;
begin
  if Assigned(FData) and LdrxCheckDelayedImport(
    delayed_DismDelete).IsSuccess then
    DismDelete(FData);

  FData := nil;
  inherited;
end;

function DismxDelayedFree(
  Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      if LdrxCheckDelayedImport(delayed_DismDelete).IsSuccess then
        DismDelete(Buffer);
    end
  );
end;

{ Callback support }

procedure DismxpCallbackDispatcher(
  [in] Current: Cardinal;
  [in] Total: Cardinal;
  [in] UserData: Pointer
); stdcall;
var
  Callback: TDismxProgressCallback absolute UserData;
begin
  if Assigned(Callback) then
    Callback(Current, Total);
end;

[Result: MayReturnNil]
function DismxpGetCallbackDispatcher(
  [opt] const Callback: TDismxProgressCallback
): TDismProgressCallback;
begin
  if Assigned(Callback) then
    Result := DismxpCallbackDispatcher
  else
    Result := nil;
end;

{ Initialization }

function DismxInitialize;
begin
  Result := LdrxCheckDelayedImport(delayed_DismInitialize);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismInitialize';
  Result.HResult := DismInitialize(LogLevel, RefStrOrNil(LogFilePath),
    RefStrOrNil(ScratchDirectory));
end;

function DismxShutdown;
begin
  Result := LdrxCheckDelayedImport(delayed_DismShutdown);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismShutdown';
  Result.HResult := DismShutdown;
end;

function DismxInitializeAuto;
begin
  Result := DismxInitialize(LogLevel, LogFilePath, ScratchDirectory);

  if not Result.IsSuccess then
    Exit;

  Uninitializer := Auto.Delay(
    procedure
    begin
      DismxShutdown;
    end
  );
end;

var
  DismxInitialized: TRtlRunOnce;
  DismxUnitinitializer: IAutoReleasable;

function DismxInitializeOnce;
var
  InitState: IAcquiredRunOnce;
begin
  if RtlxRunOnceBegin(@DismxInitialized, InitState) then
  begin
    // Put uninitializer into a global variable to trigger cleaup on unit unload
    Result := DismxInitializeAuto(DismxUnitinitializer, LogLevel, LogFilePath,
      ScratchDirectory);

    if not Result.IsSuccess then
      Exit;

    InitState.Complete;
  end
  else
    Result := NtxSuccess;
end;

{ Images }

function DismxOpenSession;
var
  hSession: TDismSession;
begin
  Result := LdrxCheckDelayedImport(delayed_DismOpenSession);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismOpenSession';
  Result.HResult := DismOpenSession(PWideChar(ImagePath),
    RefStrOrNil(WindowsDirectory), RefStrOrNil(SystemDrive), hSession);

  if Result.IsSuccess then
    hxDismSession := TDismSessionAutoHandle.Capture(hSession);
end;

function DismxGetImageInfo;
var
  Buffer: PDismImageInfoArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismImageInfo;
  Count: Cardinal;
  i, j: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetImageInfo);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetImageInfo';
  Result.HResult := DismGetImageInfo(PWideChar(ImageFilePath), Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(ImageInfo, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(ImageInfo) do
  begin
    ImageInfo[i].ImageType := Cursor.ImageType;
    ImageInfo[i].ImageIndex := Cursor.ImageIndex;
    ImageInfo[i].ImageName := Cursor.ImageName;
    ImageInfo[i].ImageDescription := Cursor.ImageDescription;
    ImageInfo[i].ImageSize := Cursor.ImageSize;
    ImageInfo[i].Architecture := Cursor.Architecture;
    ImageInfo[i].ProductName := Cursor.ProductName;
    ImageInfo[i].EditionId := Cursor.EditionId;
    ImageInfo[i].InstallationType := Cursor.InstallationType;
    ImageInfo[i].Hal := Cursor.Hal;
    ImageInfo[i].ProductType := Cursor.ProductType;
    ImageInfo[i].ProductSuite := Cursor.ProductSuite;
    ImageInfo[i].MajorVersion := Cursor.MajorVersion;
    ImageInfo[i].MinorVersion := Cursor.MinorVersion;
    ImageInfo[i].Build := Cursor.Build;
    ImageInfo[i].SpBuild := Cursor.SpBuild;
    ImageInfo[i].SpLevel := Cursor.SpLevel;
    ImageInfo[i].Bootable := Cursor.Bootable;
    ImageInfo[i].SystemRoot := Cursor.SystemRoot;
    SetLength(ImageInfo[i].Language, Cursor.LanguageCount);

    for j := 0 to High(ImageInfo[i].Language) do
      ImageInfo[i].Language[j] := Cursor
        .Language{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF}.Value;

    ImageInfo[i].DefaultLanguageIndex := Cursor.DefaultLanguageIndex;
    Inc(Cursor);
  end;
end;

function DismxMountImage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_DismMountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismMountImage';
  Result.HResult := DismMountImage(
    PWideChar(ImageFilePath),
    PWideChar(MountPath),
    ImageIndex,
    RefStrOrNil(ImageName),
    ImageIdentifier,
    Flags,
    CancelEvent,
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxUnmountImage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_DismUnmountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismUnmountImage';
  Result.HResult := DismUnmountImage(
    PWideChar(MountPath),
    Flags,
    CancelEvent,
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxRemountImage;
begin
  Result := LdrxCheckDelayedImport(delayed_DismRemountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRemountImage';
  Result.HResult := DismRemountImage(PWideChar(MountPath));
end;

function DismxCommitImage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_DismCommitImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismCommitImage';
  Result.HResult := DismCommitImage(
    HandleOrDefault(hxDismSession),
    Flags,
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxGetMountedImageInfo;
var
  Buffer: PDismMountedImageInfoArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismMountedImageInfo;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetMountedImageInfo);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetMountedImageInfo';
  Result.HResult := DismGetMountedImageInfo(Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(ImageInfo, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(ImageInfo) do
  begin
    ImageInfo[i].MountPath := Cursor.MountPath;
    ImageInfo[i].ImageFilePath := Cursor.ImageFilePath;
    ImageInfo[i].ImageIndex := Cursor.ImageIndex;
    ImageInfo[i].MountMode := Cursor.MountMode;
    ImageInfo[i].MountStatus := Cursor.MountStatus;
    Inc(Cursor);
  end;
end;

function DismxCleanupMountpoints;
begin
  Result := LdrxCheckDelayedImport(delayed_DismCleanupMountpoints);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismCleanupMountpoints';
  Result.HResult := DismCleanupMountpoints;
end;

function DismxCheckImageHealth;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_DismCheckImageHealth);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismCheckImageHealth';
  Result.HResult := DismCheckImageHealth(
    HandleOrDefault(hxDismSession),
    ScanImage,
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context,
    ImageHealth
  );
end;

function DismxRestoreImageHealth;
var
  Context: Pointer absolute ProgressCallback;
  SourcePathRefs: TArray<PWideChar>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismRestoreImageHealth);

  if not Result.IsSuccess then
    Exit;

  SetLength(SourcePathRefs, Length(SourcePaths));

  for i := 0 to High(SourcePathRefs) do
    SourcePathRefs[i] := PWideChar(SourcePaths[i]);

  Result.Location := 'DismRestoreImageHealth';
  Result.HResult := DismRestoreImageHealth(
    HandleOrDefault(hxDismSession),
    SourcePathRefs,
    Length(SourcePathRefs),
    LimitAccess,
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

{ Packages }

function DismxAddPackage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_DismAddPackage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismAddPackage';
  Result.HResult := DismAddPackage(
    HandleOrDefault(hxDismSession),
    PWideChar(PackagePath),
    IgnoreCheck,
    PreventPending,
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxRemovePackage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_DismRemovePackage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRemovePackage';
  Result.HResult := DismRemovePackage(
    HandleOrDefault(hxDismSession),
    PWideChar(Identifier),
    PackageIdentifier,
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxEnumeratePackages;
var
  Buffer: PDismPackageArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismPackage;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetPackages);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetPackages';
  Result.HResult := DismGetPackages(
    HandleOrDefault(hxDismSession),
    Buffer,
    Count
  );

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(Packages, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(Packages) do
  begin
    Packages[i].PackageName := Cursor.PackageName;
    Packages[i].PackageState := Cursor.PackageState;
    Packages[i].ReleaseType := Cursor.ReleaseType;
    Packages[i].InstallTime := Cursor.InstallTime;
    Inc(Cursor);
  end;
end;

function DismxQueryPackage;
var
  Buffer: PDismPackageInfo;
  BufferDeallocator: IAutoReleasable;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetPackageInfo);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetPackageInfo';
  Result.HResult := DismGetPackageInfo(
    HandleOrDefault(hxDismSession),
    PWideChar(Identifier),
    PackageIdentifier,
    Buffer
  );

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  PackageInfo.PackageName := Buffer.PackageName;
  PackageInfo.PackageState := Buffer.PackageState;
  PackageInfo.ReleaseType := Buffer.ReleaseType;
  PackageInfo.InstallTime := Buffer.InstallTime;
  PackageInfo.Applicable := Buffer.Applicable;
  PackageInfo.Copyright := Buffer.Copyright;
  PackageInfo.Company := Buffer.Company;
  PackageInfo.CreationTime := Buffer.CreationTime;
  PackageInfo.DisplayName := Buffer.DisplayName;
  PackageInfo.Description := Buffer.Description;
  PackageInfo.InstallClient := Buffer.InstallClient;
  PackageInfo.InstallPackageName := Buffer.InstallPackageName;
  PackageInfo.LastUpdateTime := Buffer.LastUpdateTime;
  PackageInfo.ProductName := Buffer.ProductName;
  PackageInfo.ProductVersion := Buffer.ProductVersion;
  PackageInfo.RestartRequired := Buffer.RestartRequired;
  PackageInfo.FullyOffline := Buffer.FullyOffline;
  PackageInfo.SupportInformation := Buffer.SupportInformation;

  SetLength(PackageInfo.CustomProperties, Buffer.CustomPropertyCount);

  for i := 0 to High(PackageInfo.CustomProperties) do
  begin
    PackageInfo.CustomProperties[i].Name := Buffer
      .CustomProperty{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name;
    PackageInfo.CustomProperties[i].Value := Buffer
      .CustomProperty{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name;
    PackageInfo.CustomProperties[i].Path := Buffer
    .CustomProperty{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name;
  end;

  SetLength(PackageInfo.Features, Buffer.FeatureCount);

  for i := 0 to High(PackageInfo.Features) do
  begin
    PackageInfo.Features[i].FeatureName := Buffer
      .Feature{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.FeatureName;
    PackageInfo.Features[i].State := Buffer
      .Feature{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.State;
  end;
end;

{ Features }

function DismxEnumerateFeatures;
var
  Buffer: PDismFeatureArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismFeature;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetFeatures);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetFeatures';
  Result.HResult := DismGetFeatures(
    HandleOrDefault(hxDismSession),
    RefStrOrNil(Identifier),
    PackageIdentifier,
    Buffer,
    Count
  );

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(Features, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(Features) do
  begin
    Features[i].FeatureName := Cursor.FeatureName;
    Features[i].State := Cursor.State;
    Inc(Cursor);
  end;
end;

function DismxQueryFeature;
var
  Buffer: PDismFeatureInfo;
  BufferDeallocator: IAutoReleasable;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetFeatureInfo);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetFeatureInfo';
  Result.HResult := DismGetFeatureInfo(
    HandleOrDefault(hxDismSession),
    PWideChar(FeatureName),
    RefStrOrNil(Identifier),
    PackageIdentifier,
    Buffer
  );

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  FeatureInfo.FeatureName := Buffer.FeatureName;
  FeatureInfo.FeatureState := Buffer.FeatureState;
  FeatureInfo.DisplayName := Buffer.DisplayName;
  FeatureInfo.Description := Buffer.Description;
  FeatureInfo.RestartRequired := Buffer.RestartRequired;

  SetLength(FeatureInfo.CustomProperties, Buffer.CustomPropertyCount);

  for i := 0 to High(FeatureInfo.CustomProperties) do
  begin
    FeatureInfo.CustomProperties[i].Name := Buffer
      .CustomProperty{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name;
    FeatureInfo.CustomProperties[i].Value := Buffer
      .CustomProperty{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Value;
    FeatureInfo.CustomProperties[i].Path := Buffer
      .CustomProperty{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Path;
  end;
end;

function DismxEnableFeature;
var
  Context: Pointer absolute ProgressCallback;
  SourcePathRefs: TArray<PWideChar>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismEnableFeature);

  if not Result.IsSuccess then
    Exit;

  SetLength(SourcePathRefs, Length(SourcePaths));

  for i := 0 to High(SourcePathRefs) do
    SourcePathRefs[i] := PWideChar(SourcePaths[i]);

  // The function can return DISMAPI_S_RELOAD_IMAGE_SESSION_REQUIRED which
  // equals S_FALSE

  Result.Location := 'DismEnableFeature';
  Result.HResultAllowFalse := DismEnableFeature(
    HandleOrDefault(hxDismSession),
    PWideChar(FeatureName),
    RefStrOrNil(Identifier),
    PackageIdentifier,
    LimitAccess,
    SourcePathRefs,
    Length(SourcePathRefs),
    EnableAll,
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxDisableFeature;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_DismDisableFeature);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismDisableFeature';
  Result.HResultAllowFalse := DismDisableFeature(
    HandleOrDefault(hxDismSession),
    PWideChar(FeatureName),
    RefStrOrNil(PackageName),
    RemovePayload,
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxEnumerateFeatureParents;
var
  Buffer: PDismFeatureArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismFeature;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetFeatureParent);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetFeatureParent';
  Result.HResult := DismGetFeatureParent(
    HandleOrDefault(hxDismSession),
    PWideChar(FeatureName),
    RefStrOrNil(Identifier),
    PackageIdentifier,
    Buffer,
    Count
  );

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(Features, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(Features) do
  begin
    Features[i].FeatureName := Cursor.FeatureName;
    Features[i].State := Cursor.State;
    Inc(Cursor);
  end;
end;

{ Unattend }

function DismxApplyUnattend;
begin
  Result := LdrxCheckDelayedImport(delayed_DismApplyUnattend);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismApplyUnattend';
  Result.HResult := DismApplyUnattend(
    HandleOrDefault(hxDismSession),
    PWideChar(UnattendFile),
    SingleSession
  );
end;

{ Drivers }

function DismxAddDriver;
begin
  Result := LdrxCheckDelayedImport(delayed_DismAddDriver);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismAddDriver';
  Result.HResult := DismAddDriver(HandleOrDefault(hxDismSession),
    PWideChar(DriverPath), ForceUnsigned);
end;

function DismxRemoveDriver;
begin
  Result := LdrxCheckDelayedImport(delayed_DismRemoveDriver);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRemoveDriver';
  Result.HResult := DismRemoveDriver(HandleOrDefault(hxDismSession),
    PWideChar(DriverPath));
end;

procedure DismxpCaptureDriverPackage(
  [in] Cursor: PDismDriverPackage;
  out Info: TDismxDriverPackage
);
begin
  Info.PublishedName := Cursor.PublishedName;
  Info.OriginalFileName := Cursor.OriginalFileName;
  Info.InBox := Cursor.InBox;
  Info.CatalogFile := Cursor.CatalogFile;
  Info.ClassName := Cursor.ClassName;
  Info.ClassGuid := Cursor.ClassGuid;
  Info.ClassDescription := Cursor.ClassDescription;
  Info.BootCritical := Cursor.BootCritical;
  Info.DriverSignature := Cursor.DriverSignature;
  Info.ProviderName := Cursor.ProviderName;
  Info.Date := Cursor.Date;
  Info.MajorVersion := Cursor.MajorVersion;
  Info.MinorVersion := Cursor.MinorVersion;
  Info.Build := Cursor.Build;
  Info.Revision := Cursor.Revision;
end;

function DismxEnumerateDrivers;
var
  Buffer: PDismDriverPackageArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismDriverPackage;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetDrivers);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetDrivers';
  Result.HResult := DismGetDrivers(HandleOrDefault(hxDismSession),
    AllDrivers, Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(DriverPackages, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(DriverPackages) do
  begin
    DismxpCaptureDriverPackage(Cursor, DriverPackages[i]);
    Inc(Cursor);
  end;
end;

function DismxQueryDriver;
var
  Buffer: PDismDriverArray;
  BufferPackage: PDismDriverPackage;
  BufferPackageRef: PPDismDriverPackage;
  BufferDeallocator, BufferPackageDeallocator: IAutoReleasable;
  Cursor: PDismDriver;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetDriverInfo);

  if not Result.IsSuccess then
    Exit;

  // Prepare optional parameter
  if Assigned(DriverPackage) then
    BufferPackageRef := @BufferPackage
  else
    BufferPackageRef := nil;

  Result.Location := 'DismGetDriverInfo';
  Result.HResult := DismGetDriverInfo(
    HandleOrDefault(hxDismSession),
    PWideChar(DriverPath),
    Buffer,
    Count,
    BufferPackageRef
  );

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);

  // Capture the optional driver package info
  if Assigned(DriverPackage) then
  begin
    BufferPackageDeallocator := DismxDelayedFree(BufferPackage);
    DismxpCaptureDriverPackage(BufferPackage, DriverPackage^);
  end;

  // Capture the drivers
  SetLength(Drivers, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(Drivers) do
  begin
    Drivers[i].ManufacturerName := Cursor.ManufacturerName;
    Drivers[i].HardwareDescription := Cursor.HardwareDescription;
    Drivers[i].HardwareId := Cursor.HardwareId;
    Drivers[i].Architecture := Cursor.Architecture;
    Drivers[i].ServiceName := Cursor.ServiceName;
    Drivers[i].CompatibleIds := Cursor.CompatibleIds;
    Drivers[i].ExcludeIds := Cursor.ExcludeIds;
    Inc(Cursor);
  end;
end;

{ Capabilities }

function DismxEnumerateCapabilities;
var
  Buffer: PDismCapabilityArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismCapability;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetCapabilities);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetCapabilities';
  Result.HResult := DismGetCapabilities(HandleOrDefault(hxDismSession), Buffer,
    Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(Capabilities, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(Capabilities) do
  begin
    Capabilities[i].Name := Cursor.Name;
    Capabilities[i].State := Cursor.State;
    Inc(Cursor);
  end;
end;

function DismxQueryCapability;
var
  Buffer: PDismCapabilityInfo;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetCapabilityInfo);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetCapabilityInfo';
  Result.HResult := DismGetCapabilityInfo(
    HandleOrDefault(hxDismSession),
    PWideChar(Name),
    Buffer
  );

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  Info.Name := Buffer.Name;
  Info.State := Buffer.State;
  Info.DisplayName := Buffer.DisplayName;
  Info.Description := Buffer.Description;
  Info.DownloadSize := Buffer.DownloadSize;
  Info.InstallSize := Buffer.InstallSize;
end;

function DismxAddCapability;
var
  Context: Pointer absolute ProgressCallback;
  SourcePathRefs: TArray<PWideChar>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismAddCapability);

  if not Result.IsSuccess then
    Exit;

  SetLength(SourcePathRefs, Length(SourcePaths));

  for i := 0 to High(SourcePathRefs) do
    SourcePathRefs[i] := PWideChar(SourcePaths[i]);

  Result.Location := 'DismAddCapability';
  Result.HResult := DismAddCapability(
    HandleOrDefault(hxDismSession),
    PWideChar(Name),
    LimitAccess,
    SourcePathRefs,
    Length(SourcePathRefs),
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxRemoveCapability;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_DismRemoveCapability);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRemoveCapability';
  Result.HResult := DismRemoveCapability(
    HandleOrDefault(hxDismSession),
    PWideChar(Name),
    HandleOrDefault(CancelEvent),
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

{ Appx }

function DismxEnumerateProvisionedAppxPackages;
var
  Buffer: PDismAppxPackageArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismAppxPackage;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismGetProvisionedAppxPackages);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetProvisionedAppxPackages';
  Result.HResult := DismGetProvisionedAppxPackages(
    HandleOrDefault(hxDismSession),
    Buffer,
    Count
  );

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(Packages, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(Packages) do
  begin
    Packages[i].PackageName := Cursor.PackageName;
    Packages[i].DisplayName := Cursor.DisplayName;
    Packages[i].PublisherId := Cursor.PublisherId;
    Packages[i].MajorVersion := Cursor.MajorVersion;
    Packages[i].MinorVersion := Cursor.MinorVersion;
    Packages[i].Build := Cursor.Build;
    Packages[i].RevisionNumber := Cursor.RevisionNumber;
    Packages[i].Architecture := Cursor.Architecture;
    Packages[i].ResourceId := Cursor.ResourceId;
    Packages[i].InstallLocation := Cursor.InstallLocation;
    Packages[i].Region := Cursor.Region;
    Inc(Cursor);
  end;
end;

function DismxAddProvisionedAppxPackage;
var
  DependencyPackageRefs, OptionalPackageRefs, LicensePathRefss: TArray<PWideChar>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_DismAddProvisionedAppxPackage);

  if not Result.IsSuccess then
    Exit;

  // Prepare string references
  SetLength(DependencyPackageRefs, Length(DependencyPackages));
  SetLength(OptionalPackageRefs, Length(OptionalPackages));
  SetLength(LicensePathRefss, Length(LicensePaths));

  for i := 0 to High(DependencyPackageRefs) do
    DependencyPackageRefs[i] := PWideChar(DependencyPackages[i]);

  for i := 0 to High(OptionalPackageRefs) do
    OptionalPackageRefs[i] := PWideChar(OptionalPackages[i]);

  for i := 0 to High(LicensePathRefss) do
    LicensePathRefss[i] := PWideChar(LicensePaths[i]);

  Result.Location := 'DismAddProvisionedAppxPackage';
  Result.HResult := DismAddProvisionedAppxPackage(
    HandleOrDefault(hxDismSession),
    PWideChar(AppPath),
    DependencyPackageRefs,
    Length(DependencyPackageRefs),
    OptionalPackageRefs,
    Length(OptionalPackageRefs),
    LicensePathRefss,
    Length(LicensePathRefss),
    SkipLicense,
    RefStrOrNil(CustomDataPath),
    RefStrOrNil(Region),
    StubPackageOption
  );
end;

function DismxRemoveProvisionedAppxPackage;
begin
  Result := LdrxCheckDelayedImport(delayed_DismRemoveProvisionedAppxPackage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRemoveProvisionedAppxPackage';
  Result.HResult := DismRemoveProvisionedAppxPackage(
    HandleOrDefault(hxDismSession), PWideChar(PackageName));
end;

end.
