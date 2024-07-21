unit NtUtils.Dism;

{
  This module provides support for using DISM (Deployment Image Servicing and
  Managemen) API.
}

interface

uses
  Ntapi.WinNt, Ntapi.dismapi, Ntapi.ntseapi, Ntapi.WinBase, NtUtils,
  DelphiApi.Reflection;

const
  // Forward the online image pseudo-path
  DISM_ONLINE_IMAGE = Ntapi.dismapi.DISM_ONLINE_IMAGE;

type
  IDismSession = NtUtils.IHandle;

  // An anonymous callback for monitoring progress
  TDismxProgressCallback = reference to procedure (Current, Total: Cardinal);

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

  TDismxMountedImageInfo = record
    MountPath: String;
    ImageFilePath: String;
    ImageIndex: Cardinal;
    MountMode: TDismMountMode;
    MountStatus: TDismMountStatus;
  end;

  TDismxPackage = record
    PackageName: String;
    PackageState: TDismPackageFeatureState;
    ReleaseType: TDismReleaseType;
    InstallTime: TSystemTime;
  end;

  TDismxCustomProperty = record
    Name: String;
    Value: String;
    Path: String;
  end;

  TDismxFeature = record
    FeatureName: String;
    State: TDismPackageFeatureState;
  end;

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

{ Initialization }

// Initialize DISM API
[RequiresAdmin]
[Result: ReleaseWith('DismxShutdown')]
function DismxInitialize(
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

// Uninitialize DISM API
function DismxShutdown(
): TNtxStatus;

// Initialize DISM API and uninitialize it later
[RequiresAdmin]
function DismxInitializeAuto(
  out Uninitializer: IAutoReleasable;
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

// Initialize DISM API once and uninitialize it on this unit finalizatoin
[RequiresAdmin]
function DismxInitializeOnce(
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

{ Images }

// Open a DISM session for the specified online/offline image path
function DismxOpenSession(
  out hxDismSession: IDismSession;
  const ImagePath: String;
  [opt] const WindowsDirectory: String = '';
  [opt] const SystemDrive: String = ''
): TNtxStatus;

// Query information about an image
function DismxGetImageInfo(
  const ImageFilePath: String;
  out ImageInfo: TArray<TDismxImageInfo>
): TNtxStatus;

// Mount a .wim or a .vhdx image to a given directory
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
function DismxUnmountImage(
  const MountPath: String;
  Flags: TDismUnmountFlags = DISM_DISCARD_IMAGE;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Remount a previously mounted image
function DismxRemountImage(
  const MountPath: String
): TNtxStatus;

// Save changes to a mounted image
function DismxCommitImage(
  const hxDismSession: IDismSession;
  [in] Flags: Cardinal;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Query information about a mounted image
function DismxGetMountedImageInfo(
  out ImageInfo: TArray<TDismxMountedImageInfo>
): TNtxStatus;

// Removes files from corrupted and invalid mount points
function DismxCleanupMountpoints(
): TNtxStatus;

// Verify the image or check if it has already been flagged as corrupted
function DismxCheckImageHealth(
  const hxDismSession: IDismSession;
  ScanImage: Boolean;
  out ImageHealth: TDismImageHealthState;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Repairs a corrupted image
function DismxRestoreImageHealth(
  const hxDismSession: IDismSession;
  [opt] const SourcePaths: TArray<PWideChar>;
  LimitAccess: Boolean;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

{ Packages }

// Add a .cab or a .msu to an image
function DismxAddPackage(
  const hxDismSession: IDismSession;
  const PackagePath: String;
  IgnoreCheck: Boolean;
  PreventPending: Boolean;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Add a .cab or a .msu from an image
function DismxRemovePackage(
  const hxDismSession: IDismSession;
  const Identifier: String;
  PackageIdentifier: TDismPackageIdentifier;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Enumerate .cab or .msu packages in an image
function DismxEnumeratePackages(
  const hxDismSession: IDismSession;
  out Packages: TArray<TDismxPackage>
): TNtxStatus;

// Query information about a .cab or a .msu package
function DismxQueryPackage(
  const hxDismSession: IDismSession;
  const Identifier: String;
  PackageIdentifier: TDismPackageIdentifier;
  out PackageInfo: TDismxPackageInfo
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
  if (FHandle <> 0) and LdrxCheckDelayedImport(delayed_dismapi,
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
  if Assigned(FData) and LdrxCheckDelayedImport(delayed_dismapi,
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
      if LdrxCheckDelayedImport(delayed_dismapi,
        delayed_DismDelete).IsSuccess then
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
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismInitialize);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismInitialize';
  Result.HResult := DismInitialize(LogLevel, RefStrOrNil(LogFilePath),
    RefStrOrNil(ScratchDirectory));
end;

function DismxShutdown;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismShutdown);

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
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismOpenSession);

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
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismGetImageInfo);

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
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismMountImage);

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
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismUnmountImage);

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
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismRemountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRemountImage';
  Result.HResult := DismRemountImage(PWideChar(MountPath));
end;

function DismxCommitImage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismCommitImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismCommitImage';
  Result.HResult := DismCommitImage(
    HandleOrDefault(hxDismSession),
    Flags,
    CancelEvent,
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
  Result := LdrxCheckDelayedImport(delayed_dismapi,
    delayed_DismGetMountedImageInfo);

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
  Result := LdrxCheckDelayedImport(delayed_dismapi,
    delayed_DismCleanupMountpoints);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismCleanupMountpoints';
  Result.HResult := DismCleanupMountpoints;
end;

function DismxCheckImageHealth;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi,
    delayed_DismCheckImageHealth);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismCheckImageHealth';
  Result.HResult := DismCheckImageHealth(
    HandleOrDefault(hxDismSession),
    ScanImage,
    CancelEvent,
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context,
    ImageHealth
  );
end;

function DismxRestoreImageHealth;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi,
    delayed_DismRestoreImageHealth);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRestoreImageHealth';
  Result.HResult := DismRestoreImageHealth(
    HandleOrDefault(hxDismSession),
    SourcePaths,
    Length(SourcePaths),
    LimitAccess,
    CancelEvent,
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

{ Packages }

function DismxAddPackage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismAddPackage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismAddPackage';
  Result.HResult := DismAddPackage(
    HandleOrDefault(hxDismSession),
    PWideChar(PackagePath),
    IgnoreCheck,
    PreventPending,
    CancelEvent,
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxRemovePackage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismRemovePackage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRemovePackage';
  Result.HResult := DismRemovePackage(
    HandleOrDefault(hxDismSession),
    PWideChar(Identifier),
    PackageIdentifier,
    CancelEvent,
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
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismGetPackages);

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
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismGetPackageInfo);

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

end.
