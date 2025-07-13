unit NtUtils.Packages;

{
  This module provides functions for retrieving information about packaged
  applications.
}

interface

uses
  Ntapi.WinNt, Ntapi.appmodel, Ntapi.Versions, DelphiApi.Reflection, NtUtils,
  DelphiUtils.AutoObjects;

(*
  Formats:
    {FullName} = {Name}_{Version}_{Architecture}_{ResourceId}_{PublisherId}
    {FamilyName} = {Name}_{PublisherId}
    {AppUserModelId} = {FamilyName}!{RelativeAppId}

  Examples:
   "Microsoft.MSIXPackagingTool_1.2023.319.0_x64__8wekyb3d8bbwe" - Full Name
   "Microsoft.MSIXPackagingTool_8wekyb3d8bbwe!Msix.App" - App user model ID
*)

type
  IPackageInfoReference = IPointer<PPackageInfoReference>;

  TPkgxPackageId = record
    ProcessorArchitecture: TProcessorArchitecture32;
    Version: TPackageVersion;
    Name: String;
    Publisher: String;
    ResourceID: String;
    PublisherID: String;
  end;

  TPkgxPackageNameAndProperties = record
    FullName: String;
    Properties: TPackageProperties;
  end;

  TPkgxPackageInfo = record
    Properties: TPackageProperties;
    Path: String;
    PackageFullName: String;
    PackageFamilyName: String;
    [Aggregate] ID: TPkgxPackageId;
  end;

{ Deriving/conversion }

// Construct full package name from its identification information
[MinOSVersion(OsWin8)]
function PkgxDeriveFullNameFromId(
  out FullName: String;
  const PackageId: TPkgxPackageId
): TNtxStatus;

// Construct package family name from its identification information
[MinOSVersion(OsWin8)]
function PkgxDeriveFamilyNameFromId(
  out FamilyName: String;
  const PackageId: TPkgxPackageId
): TNtxStatus;

// Convert a full package name to a family name
[MinOSVersion(OsWin8)]
function PkgxDeriveFamilyNameFromFullName(
  out FamilyName: String;
  const FullName: String
): TNtxStatus;

// Convert package family name and PRAID to application user model ID
function PkgxDeriveAppUserModelIdFromFamilyNameAndRelativeId(
  out ApplicationUserModelId: String;
  const PackageFamilyName: String;
  const PackageRelativeApplicationId: String
): TNtxStatus;

// Convert a package name and publisher from a family name
[MinOSVersion(OsWin8)]
function PkgxDeriveNameAndPublisherIdFromFamilyName(
  const FamilyName: String;
  out Name: String;
  out PublisherId: String
): TNtxStatus;

// Parse package AppUserModelId
[MinOSVersion(OsWin81)]
function PkgxDeriveFamilyNameFromAppUserModelId(
  const AppUserModelId: String;
  out FamilyName: String;
  out RelativeAppId: String
): TNtxStatus;

{ Querying by name }

// Query identification information of a package
[MinOSVersion(OsWin8)]
function PkgxQueryIdByFullName(
  out PackageId: TPkgxPackageId;
  const FullName: String;
  Flags: TPackageInformationFlags = PACKAGE_INFORMATION_FULL
): TNtxStatus;

// Determine package path
[MinOSVersion(OsWin81)]
function PkgxQueryPathByFullName(
  out Path: String;
  const FullName: String
): TNtxStatus;

// Determine (mutable) package path
[MinOSVersion(OsWin1019H1)]
function PkgxQueryPathByFullName2(
  out Path: String;
  const FullName: String;
  PackagePathType: TPackagePathType
): TNtxStatus;

// Determine (mutable) staged package path
[MinOSVersion(OsWin81)]
function PkgxQueryStagedPathByFullName(
  out Path: String;
  const FullName: String
): TNtxStatus;

// Determine (mutable) staged package path
[MinOSVersion(OsWin1019H1)]
function PkgxQueryStagedPathByFullName2(
  out Path: String;
  const FullName: String;
  PackagePathType: TPackagePathType
): TNtxStatus;

// Determine package origin
[MinOSVersion(OsWin81)]
function PkgxQueryOriginByFullName(
  out Origin: TPackageOrigin;
  const FullName: String
): TNtxStatus;

// Check is a package is a MSIX package
[MinOSVersion(OsWin1021H1)]
function PkgxQueryIsMsixByFullName(
  out IsMSIXPackage: LongBool;
  const FullName: String
): TNtxStatus;

// Query install time of a package
[MinOSVersion(OsWin81)]
function PkgxQueryInstallTimeByFullName(
  out InstallTime: TLargeInteger;
  const FullName: String
): TNtxStatus;

// Query a package SID
[MinOSVersion(OsWin10TH1)]
function PkgxQuerySidByPackageFamily(
  out Sid: ISid;
  const FamilyName: String
): TNtxStatus;

// Query maximum tested OS version for a package
[MinOSVersion(OsWin81)]
function PkgxQueryOSMaxVersionTestedByFullName(
  out OSMaxVersionTested: TPackageVersion;
  const FullName: String
): TNtxStatus;

// Query if a package is in development mode
[MinOSVersion(OsWin81)]
function PkgxQueryDevelopmentModeByFullName(
  out DevelopmentMode: LongBool;
  const FullName: String
): TNtxStatus;

// Query package SID
[MinOSVersion(OsWin81)]
function PkgxQuerySidByFullName(
  out Sid: ISid;
  const FullName: String
): TNtxStatus;

// Query package capabilities
[MinOSVersion(OsWin81)]
function PkgxQueryCapabilitiesByFullName(
  const FullName: String;
  out IsFullTrust: LongBool;
  out Capabilities: TArray<TGroup>
): TNtxStatus;

{ Enumerating by name }

// Retrieve the list of packages in a family
[MinOSVersion(OsWin8)]
function PkgxEnumeratePackagesInFamilyByName(
  out FullNames: TArray<String>;
  const FamilyName: String
): TNtxStatus;

// Retrieve the list of packages in a family according to a filter
[MinOSVersion(OsWin81)]
function PkgxEnumeratePackagesInFamilyByNameEx(
  out Packages: TArray<TPkgxPackageNameAndProperties>;
  const FamilyName: String;
  Filter: TPackageFilters = MAX_UINT
): TNtxStatus;

{ Info reference open }

// Open information about a package
[MinOSVersion(OsWin8)]
function PkgxOpenPackageInfo(
  out InfoReference: IPackageInfoReference;
  const FullName: String
): TNtxStatus;

// Open information about a package of another user
[MinOSVersion(OsWin10TH1)]
function PkgxOpenPackageInfoForUser(
  out InfoReference: IPackageInfoReference;
  const FullName: String;
  [opt] const UserSid: ISid
): TNtxStatus;

{ Package contexts (internal use) }

// Get package context (internal use)
[MinOSVersion(OsWin81)]
function PkgxLocatePackageContext(
  out Context: PPackageContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package application context (internal use)
[MinOSVersion(OsWin81)]
function PkgxLocatePackageApplicationContext(
  out Context: PPackageApplicationContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package resources context (internal use)
[MinOSVersion(OsWin81)]
function PkgxLocatePackageResourcesContext(
  out Context: PPackageResourcesContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package application resources context (internal use)
[MinOSVersion(OsWin81)]
function PkgxLocatePackageApplicationResourcesContext(
  out Context: PPackageResourcesContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package security context (internal use)
[MinOSVersion(OsWin81)]
function PkgxLocatePackageSecurityContext(
  out Context: PPackageSecurityContextReference;
  const InfoReference: IPackageInfoReference
): TNtxStatus;

// Get package target platform context (internal use)
[MinOSVersion(OsWin10TH1)]
function PkgxLocatePackageTargetPlatformContext(
  out Context: PTargetPlatformContextReference;
  const InfoReference: IPackageInfoReference
): TNtxStatus;

// Get package globalization context (internal use)
[MinOSVersion(OsWin1020H1)]
function PkgxLocatePackageGlobalizationContext(
  out Context: PPackageGlobalizationContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

{ Querying by info reference }

// Query information about a package
[MinOSVersion(OsWin8)]
function PkgxQueryPackageInfo(
  out Info: TArray<TPkgxPackageInfo>;
  const InfoReference: IPackageInfoReference;
  Flags: TPackageFilters = MAX_UINT
): TNtxStatus;

// Query information about a package using a specific path type
[MinOSVersion(OsWin1019H1)]
function PkgxQueryPackageInfo2(
  out Info: TArray<TPkgxPackageInfo>;
  const InfoReference: IPackageInfoReference;
  PathType: TPackagePathType;
  Flags: TPackageFilters = MAX_UINT
): TNtxStatus;

// Query a string property of a package
[MinOSVersion(OsWin81)]
function PkgxQueryStringPropertyPackage(
  out Value: String;
  const InfoReference: IPackageInfoReference;
  PropertyId: TPackageProperty;
  DependencyIndex: Cardinal = 0
): TNtxStatus;

// Query max tested OS version for a package
[MinOSVersion(OsWin81)]
function PkgxQueryOSMaxVersionTestedPackage(
  out Version: TPackageVersion;
  const InfoReference: IPackageInfoReference;
  DependencyIndex: Cardinal = 0
): TNtxStatus;

// Query a string property of a package application
[MinOSVersion(OsWin81)]
function PkgxQueryStringPropertyApplicationPackage(
  out Value: String;
  const InfoReference: IPackageInfoReference;
  PropertyId: TPackageApplicationProperty;
  ApplicationIndex: Cardinal = 0
): TNtxStatus;

// Query a variable-size security property of a package
[MinOSVersion(OsWin81)]
function PkgxQuerySecurityPropertyPackage(
  out Buffer: IMemory;
  const InfoReference: IPackageInfoReference;
  PropertyId: TPackageSecurityProperty
): TNtxStatus;

type
  PkgxPackage = class abstract
    // Query fixed-size package property
    [MinOSVersion(OsWin81)]
    class function QueryProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      PropertyId: TPackageProperty;
      DependencyIndex: Cardinal = 0
    ): TNtxStatus; static;

    // Query fixed-size application package property
    [MinOSVersion(OsWin81)]
    class function QueryApplicationProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      PropertyId: TPackageApplicationProperty;
      ApplicationIndex: Cardinal = 0
    ): TNtxStatus; static;

    // Query fixed-size security property
    [MinOSVersion(OsWin81)]
    class function QuerySecurityProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      PropertyId: TPackageSecurityProperty
    ): TNtxStatus; static;

    // Query fixed-size target platform property
    [MinOSVersion(OsWin81)]
    class function QueryTargetPlatformProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      PropertyId: TTargetPlatformProperty
    ): TNtxStatus; static;

    // Query fixed-size globalization property
    [MinOSVersion(OsWin1020H1)]
    class function QueryGlobalizationProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      PropertyId: TPackageGlobalizationProperty;
      DependencyIndex: Cardinal = 0
    ): TNtxStatus; static;
  end;

// Enumerate application IDs in a package
[MinOSVersion(OsWin81)]
function PkgxEnumerateAppUserModelIds(
  out AppUserModelIds: TArray<String>;
  const InfoReference: IPackageInfoReference
): TNtxStatus;

{ Verification }

// Check if a string represents a valid package full name
[MinOSVersion(OsWin10TH1)]
function PkgxIsValidFullName(
  const PackageFullName: String
): Boolean;

// Check if a string represents a valid package family name
[MinOSVersion(OsWin10TH1)]
function PkgxIsValidFamilyName(
  const PackageFamilyName: String
): Boolean;

// Check if a string represents a valid package application user-mode ID
[MinOSVersion(OsWin10TH1)]
function PkgxIsValidAppUserModelId(
  const AppUserModelId: String
): Boolean;

{ PRI Resources }

// Resolve a "@{PackageFullName?ms-resource://ResourceName}" string
[MinOSVersion(OsWin8)]
function PkgxExpandResourceString(
  const ResourceDefinition: String;
  out ResourceValue: String
): TNtxStatus;

// Resolve a "@{PackageFullName?ms-resource://ResourceName}" string in place
[MinOSVersion(OsWin8)]
function PkgxExpandResourceStringVar(
  var Resource: String
): TNtxStatus;

implementation

uses
  Ntapi.WinError, Ntapi.ntseapi, NtUtils.Ldr, NtUtils.SysUtils,
  NtUtils.Security.Sid;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Helper functions }

type
  TAutoPackageInfoReference = class (TCustomAutoPointer)
    destructor Destroy; override;
  end;

destructor TAutoPackageInfoReference.Destroy;
begin
  if Assigned(FData) and not FDiscardOwnership and LdrxCheckDelayedImport(
    delayed_ClosePackageInfo).IsSuccess then
    ClosePackageInfo(FData);

  inherited;
end;

function PkgxpCapturePackageId(
  [in] Buffer: PPackageId;
  BufferEnd: Pointer
): TPkgxPackageId;
begin
  Result.ProcessorArchitecture := Buffer.ProcessorArchitecture;
  Result.Version := Buffer.Version;
  Result.Name := RtlxCaptureStringWithRange(Buffer.Name, BufferEnd);
  Result.Publisher := RtlxCaptureStringWithRange(Buffer.Publisher, BufferEnd);
  Result.ResourceID := RtlxCaptureStringWithRange(Buffer.ResourceID, BufferEnd);
  Result.PublisherID := RtlxCaptureStringWithRange(Buffer.PublisherID, BufferEnd);
end;

function PkgxpConvertPackageId(
  const PackageId: TPkgxPackageId
): TPackageId;
begin
  Result.Reserved := 0;
  Result.ProcessorArchitecture := PackageId.ProcessorArchitecture;
  Result.Version := PackageId.Version;
  Result.Name := PWideChar(PackageId.Name);
  Result.Publisher := PWideChar(PackageId.Publisher);
  Result.ResourceID := PWideChar(PackageId.ResourceID);
  Result.PublisherID := PWideChar(PackageId.PublisherID);
end;

function PkgxpCapturePackageInfo(
  const Buffer: TPackageInfo;
  BufferEnd: Pointer
): TPkgxPackageInfo;
begin
  Result.Properties := Buffer.Flags;
  Result.Path := RtlxCaptureStringWithRange(Buffer.Path, BufferEnd);
  Result.PackageFullName := RtlxCaptureStringWithRange(Buffer.PackageFullName,
    BufferEnd);
  Result.PackageFamilyName := RtlxCaptureStringWithRange(
    Buffer.PackageFamilyName, BufferEnd);
  Result.ID := PkgxpCapturePackageId(@Buffer.PackageId, BufferEnd);
end;

{ Deriving/conversion }

function PkgxDeriveFullNameFromId;
var
  Id: TPackageId;
  BufferLength: Cardinal;
  Buffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckDelayedImport(delayed_PackageFullNameFromId);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Id := PkgxpConvertPackageId(PackageId);
  Result.Location := 'PackageFullNameFromId';

  repeat
    Result.Win32ErrorOrSuccess := PackageFullNameFromId(Id, BufferLength,
      Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if Result.IsSuccess then
    FullName := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxDeriveFamilyNameFromId;
var
  Id: TPackageId;
  BufferLength: Cardinal;
  Buffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckDelayedImport(delayed_PackageFamilyNameFromId);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Id := PkgxpConvertPackageId(PackageId);
  Result.Location := 'PackageFamilyNameFromId';

  repeat
    Result.Win32ErrorOrSuccess := PackageFamilyNameFromId(Id, BufferLength,
      Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if Result.IsSuccess then
    FamilyName := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxDeriveFamilyNameFromFullName;
var
  BufferLength: Cardinal;
  Buffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckDelayedImport(delayed_PackageFamilyNameFromFullName);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'PackageFamilyNameFromFullName';

  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := PackageFamilyNameFromFullName(
      PWideChar(FullName), BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if Result.IsSuccess then
    FamilyName := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxDeriveAppUserModelIdFromFamilyNameAndRelativeId;
var
  BufferLength: Cardinal;
  Buffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckDelayedImport(delayed_FormatApplicationUserModelId);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'FormatApplicationUserModelId';

  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := FormatApplicationUserModelId(
      PWideChar(PackageFamilyName), PWideChar(PackageFamilyName), BufferLength,
      Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if Result.IsSuccess then
    ApplicationUserModelId := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxDeriveNameAndPublisherIdFromFamilyName;
var
  NameLength, PublisherIdLength: Cardinal;
  NameBuffer, PublisherBuffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckDelayedImport(
    delayed_PackageNameAndPublisherIdFromFamilyName);

  if not Result.IsSuccess then
    Exit;

  IMemory(NameBuffer) := Auto.AllocateDynamic(0);
  IMemory(PublisherBuffer) := Auto.AllocateDynamic(0);
  Result.Location := 'PackageNameAndPublisherIdFromFamilyName';

  repeat
    NameLength := NameBuffer.Size div SizeOf(WideChar);
    PublisherIdLength := PublisherBuffer.Size div SizeOf(WideChar);

    Result.Win32ErrorOrSuccess := PackageNameAndPublisherIdFromFamilyName(
      PWideChar(FamilyName), NameLength, NameBuffer.Data, PublisherIdLength,
      PublisherBuffer.Data);

  until not NtxExpandBufferPair(Result, IMemory(NameBuffer), NameLength *
    SizeOf(WideChar), IMemory(PublisherBuffer), PublisherIdLength *
    SizeOf(WideChar));

  if Result.IsSuccess then
  begin
    Name := RtlxCaptureString(NameBuffer.Data, NameLength);
    PublisherId := RtlxCaptureString(PublisherBuffer.Data, PublisherIdLength);
  end;
end;

function PkgxDeriveFamilyNameFromAppUserModelId;
var
  FamilyNameLength, RelativeIdLength: Cardinal;
  FamilyNameBuffer, RelativeIdBuffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckDelayedImport(delayed_ParseApplicationUserModelId);

  if not Result.IsSuccess then
    Exit;

  IMemory(FamilyNameBuffer) := Auto.AllocateDynamic(0);
  IMemory(RelativeIdBuffer) := Auto.AllocateDynamic(0);
  Result.Location := 'ParseApplicationUserModelId';

  repeat
    FamilyNameLength := FamilyNameBuffer.Size div SizeOf(WideChar);
    RelativeIdLength := RelativeIdBuffer.Size div SizeOf(WideChar);

    Result.Win32ErrorOrSuccess := ParseApplicationUserModelId(
      PWideChar(AppUserModelId), FamilyNameLength, FamilyNameBuffer.Data,
      RelativeIdLength, RelativeIdBuffer.Data);

  until not NtxExpandBufferPair(Result, IMemory(FamilyNameBuffer),
    FamilyNameLength * SizeOf(WideChar), IMemory(RelativeIdBuffer),
    RelativeIdLength * SizeOf(WideChar));

  if Result.IsSuccess then
  begin
    FamilyName := RtlxCaptureString(FamilyNameBuffer.Data, FamilyNameLength);
    RelativeAppId := RtlxCaptureString(RelativeIdBuffer.Data, RelativeIdLength);
  end;
end;

{ Querying by name }

function PkgxQueryIdByFullName;
var
  BufferSize: Cardinal;
  Buffer: IMemory<PPackageId>;
begin
  Result := LdrxCheckDelayedImport(delayed_PackageIdFromFullName);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(BufferSize);
  Result.Location := 'PackageIdFromFullName';

  repeat
    BufferSize := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := PackageIdFromFullName(PWideChar(FullName),
      Flags, BufferSize, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferSize);

  if Result.IsSuccess then
    PackageId := PkgxpCapturePackageId(Buffer.Data, Buffer.Offset(Buffer.Size));
end;

function PkgxQueryPathByFullName;
var
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackagePathByFullName);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH);
  Result.Location := 'GetPackagePathByFullName';

  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := GetPackagePathByFullName(PWideChar(FullName),
      BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  if Result.IsSuccess then
    Path := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxQueryPathByFullName2;
var
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackagePathByFullName2);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH);
  Result.Location := 'GetPackagePathByFullName2';

  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := GetPackagePathByFullName2(PWideChar(FullName),
      PackagePathType, BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  if Result.IsSuccess then
    Path := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxQueryStagedPathByFullName;
var
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetStagedPackagePathByFullName);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH);
  Result.Location := 'GetStagedPackagePathByFullName';

  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := GetStagedPackagePathByFullName(
      PWideChar(FullName), BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  if Result.IsSuccess then
    Path := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxQueryStagedPathByFullName2;
var
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetStagedPackagePathByFullName2);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH);
  Result.Location := 'GetStagedPackagePathByFullName2';

  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := GetStagedPackagePathByFullName2(
      PWideChar(FullName), PackagePathType, BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  if Result.IsSuccess then
    Path := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxQueryOriginByFullName;
begin
  Result := LdrxCheckDelayedImport(delayed_GetStagedPackageOrigin);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetStagedPackageOrigin';
  Result.Win32ErrorOrSuccess := GetStagedPackageOrigin(PWideChar(FullName),
    Origin);
end;

function PkgxQueryIsMsixByFullName;
begin
  Result := LdrxCheckDelayedImport(delayed_CheckIsMSIXPackage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'CheckIsMSIXPackage';
  Result.HResult := CheckIsMSIXPackage(PWideChar(FullName), IsMSIXPackage);
end;

function PkgxQueryInstallTimeByFullName;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageInstallTime);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageInstallTime';
  Result.HResult := GetPackageInstallTime(PWideChar(FullName), InstallTime);
end;

function PkgxQuerySidByPackageFamily;
var
  Buffer: PSid;
  BufferDeallocator: IDeferredOperation;
begin
  Result := LdrxCheckDelayedImport(delayed_PackageSidFromFamilyName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'PackageSidFromFamilyName';
  Result.Win32ErrorOrSuccess := PackageSidFromFamilyName(PWideChar(FamilyName),
    Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferRtlFreeSid(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
end;

function PkgxQueryOSMaxVersionTestedByFullName;
begin
  Result := LdrxCheckDelayedImport(delayed_AppXGetOSMaxVersionTested);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'AppXGetOSMaxVersionTested';
  Result.HResult := AppXGetOSMaxVersionTested(PWideChar(FullName),
    OSMaxVersionTested);
end;

function PkgxQueryDevelopmentModeByFullName;
begin
  Result := LdrxCheckDelayedImport(delayed_AppXGetDevelopmentMode);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'AppXGetDevelopmentMode';
  Result.HResult := AppXGetDevelopmentMode(PWideChar(FullName),
    DevelopmentMode);
end;

function DeferAppXFreeMemory(
  [in] Buffer: Pointer
): IDeferredOperation;
begin
  Result := Auto.Defer(
    procedure
    begin
      if LdrxCheckDelayedImport(delayed_AppXFreeMemory).IsSuccess then
        AppXFreeMemory(Buffer);
    end
  );
end;

function PkgxQuerySidByFullName;
var
  Buffer: PSid;
  BufferDeallocator: IDeferredOperation;
begin
  Result := LdrxCheckDelayedImport(delayed_AppXGetPackageSid);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'AppXGetPackageSid';
  Result.HResult := AppXGetPackageSid(PWideChar(FullName), Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferAppXFreeMemory(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
end;

function PkgxQueryCapabilitiesByFullName;
var
  Buffer: PSidAndAttributesArray;
  BufferDeallocator: IDeferredOperation;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_AppXGetPackageCapabilities);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'AppXGetPackageCapabilities';
  Result.HResult := AppXGetPackageCapabilities(PWideChar(FullName),
    IsFullTrust, Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferAppXFreeMemory(Buffer);
  SetLength(Capabilities, Count);

  for i := 0 to High(Capabilities) do
  begin
    Capabilities[i].Attributes := Buffer[i].Attributes;
    Result := RtlxCopySid(Buffer[i].SID, Capabilities[i].Sid);

    if not Result.IsSuccess then
      Exit;
  end;
end;

{ Enumerating by name }

function PkgxEnumeratePackagesInFamilyByName;
var
  Count, BufferLength: Cardinal;
  Names: IMemory<PPackageFullNames>;
  Buffer: IMemory<PWideChar>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackagesByPackageFamily);

  if not Result.IsSuccess then
    Exit;

  IMemory(Names) := Auto.AllocateDynamic(0);
  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'GetPackagesByPackageFamily';

  repeat
    Count := Names.Size * SizeOf(PWideChar);
    BufferLength := Buffer.Size * SizeOf(WideChar);

    Result.Win32ErrorOrSuccess := GetPackagesByPackageFamily(
      PWideChar(FamilyName), Count, Names.Data, BufferLength, Buffer.Data);

  until not NtxExpandBufferPair(Result, IMemory(Names), Count *
    SizeOf(PWideChar), IMemory(Buffer), BufferLength * SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  SetLength(FullNames, Count);

  for i := 0 to High(FullNames) do
    FullNames[i] := RtlxCaptureStringWithRange(
      Names.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF},
      Buffer.Offset(Buffer.Size));
end;

function PkgxEnumeratePackagesInFamilyByNameEx;
var
  Count, BufferLength: Cardinal;
  Names: IMemory<PPackageFullNames>;
  Buffer: IMemory<PWideChar>;
  Properties: IMemory<PPackagePropertiesArray>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_FindPackagesByPackageFamily);

  if not Result.IsSuccess then
    Exit;

  IMemory(Names) := Auto.AllocateDynamic(0);
  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'FindPackagesByPackageFamily';

  repeat
    Count := Names.Size div SizeOf(PWideChar);
    BufferLength := Buffer.Size div SizeOf(WideChar);

    IMemory(Properties) := Auto.AllocateDynamic(Count *
      SizeOf(TPackageProperties));

    Result.Win32ErrorOrSuccess := FindPackagesByPackageFamily(
      PWideChar(FamilyName), Filter, Count, Names.Data, BufferLength,
      Buffer.Data, Properties.Data);

  until not NtxExpandBufferPair(Result, IMemory(Names), Count *
    SizeOf(PWideChar), IMemory(Buffer), BufferLength * SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  SetLength(Packages, Count);

  for i := 0 to High(Packages) do
  begin
    Packages[i].Properties := Properties.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
    Packages[i].FullName := RtlxCaptureStringWithRange(
      Names.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF},
      Buffer.Offset(Buffer.Size));
  end;
end;

{ Info reference open }

function PkgxOpenPackageInfo;
var
  PackageInfoReference: PPackageInfoReference;
begin
  Result := LdrxCheckDelayedImport(delayed_OpenPackageInfoByFullName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OpenPackageInfoByFullName';
  Result.Win32ErrorOrSuccess := OpenPackageInfoByFullName(PWideChar(FullName),
    0, PackageInfoReference);

  if Result.IsSuccess then
    IPointer(InfoReference) := TAutoPackageInfoReference.Capture(
      PackageInfoReference);
end;

function PkgxOpenPackageInfoForUser;
var
  PackageInfoReference: PPackageInfoReference;
begin
  Result := LdrxCheckDelayedImport(delayed_OpenPackageInfoByFullNameForUser);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OpenPackageInfoByFullNameForUser';
  Result.Win32ErrorOrSuccess := OpenPackageInfoByFullNameForUser(
    Auto.DataOrNil<PSid>(UserSid), PWideChar(FullName), 0,
    PackageInfoReference);

  if Result.IsSuccess then
    IPointer(InfoReference) := TAutoPackageInfoReference.Capture(
      PackageInfoReference);
end;

{ Contexts }

function PkgxLocatePackageContext;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageContext);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageContext';
  Result.Win32ErrorOrSuccess := GetPackageContext(InfoReference.Data, Index, 0,
    Context);
end;

function PkgxLocatePackageApplicationContext;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageApplicationContext);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageApplicationContext';
  Result.Win32ErrorOrSuccess := GetPackageApplicationContext(InfoReference.Data,
    Index, 0, Context);
end;

function PkgxLocatePackageResourcesContext;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageResourcesContext);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageResourcesContext';
  Result.Win32ErrorOrSuccess := GetPackageResourcesContext(InfoReference.Data,
    Index, 0, Context);
end;

function PkgxLocatePackageApplicationResourcesContext;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageApplicationResourcesContext);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageApplicationResourcesContext';
  Result.Win32ErrorOrSuccess := GetPackageApplicationResourcesContext(
    InfoReference.Data, Index, 0, Context);
end;

function PkgxLocatePackageSecurityContext;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageSecurityContext);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageSecurityContext';
  Result.Win32ErrorOrSuccess := GetPackageSecurityContext(
    InfoReference.Data, 0, Context);
end;

function PkgxLocatePackageTargetPlatformContext;
begin
   Result := LdrxCheckDelayedImport(delayed_GetTargetPlatformContext);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetTargetPlatformContext';
  Result.Win32ErrorOrSuccess := GetTargetPlatformContext(
    InfoReference.Data, 0, Context);
end;

function PkgxLocatePackageGlobalizationContext;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageGlobalizationContext);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageGlobalizationContext';
  Result.Win32ErrorOrSuccess := GetPackageGlobalizationContext(
    InfoReference.Data, Index, 0, Context);
end;

{ Querying by info reference }

function PkgxQueryPackageInfo;
var
  BufferSize: Cardinal;
  Buffer: IMemory<PPackageInfoArray>;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageInfo);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'GetPackageInfo';

  repeat
    BufferSize := Buffer.Size;;
    Result.Win32ErrorOrSuccess := GetPackageInfo(InfoReference.Data, Flags,
      BufferSize, Buffer.Data, @Count);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferSize);

  if not Result.IsSuccess then
    Exit;

  SetLength(Info, Count);

  for i := 0 to High(Info) do
    Info[i] := PkgxpCapturePackageInfo(Buffer
      .Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}, Buffer.Offset(Buffer.Size));
end;

function PkgxQueryPackageInfo2;
var
  BufferSize: Cardinal;
  Buffer: IMemory<PPackageInfoArray>;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageInfo2);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'GetPackageInfo2';

  repeat
    BufferSize := Buffer.Size;
    Result.Win32ErrorOrSuccess := GetPackageInfo2(InfoReference.Data, Flags,
      PathType, BufferSize, Buffer.Data, @Count);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferSize);

  if not Result.IsSuccess then
    Exit;

  SetLength(Info, Count);

  for i := 0 to High(Info) do
    Info[i] := PkgxpCapturePackageInfo(Buffer
      .Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}, Buffer.Offset(Buffer.Size));
end;

function PkgxQueryStringPropertyPackage;
var
  Context: PPackageContextReference;
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackagePropertyString);

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageContext(Context, InfoReference, DependencyIndex);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'GetPackagePropertyString';
  Result.LastCall.UsesInfoClass(PropertyId, icQuery);

  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := GetPackagePropertyString(Context, PropertyId,
      BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  // Strip the terminating zero
  if BufferLength > 0 then
    Dec(BufferLength);

  SetString(Value, Buffer.Data, BufferLength);
end;

function PkgxQueryOSMaxVersionTestedPackage;
var
  Context: PPackageContextReference;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageOSMaxVersionTested);

  if not Result.IsSuccess then
    Exit;

  Result := PkgxLocatePackageContext(Context, InfoReference, DependencyIndex);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageOSMaxVersionTested';
  Result.Win32ErrorOrSuccess := GetPackageOSMaxVersionTested(Context, Version);
end;

function PkgxQueryStringPropertyApplicationPackage;
var
  Context: PPackageApplicationContextReference;
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageApplicationPropertyString);

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified application index
  Result := PkgxLocatePackageApplicationContext(Context, InfoReference,
    ApplicationIndex);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'GetPackageApplicationPropertyString';
  Result.LastCall.UsesInfoClass(PropertyId, icQuery);

  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32ErrorOrSuccess := GetPackageApplicationPropertyString(Context,
      PropertyId, BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  // Strip the terminating zero
  if BufferLength > 0 then
    Dec(BufferLength);

  SetString(Value, Buffer.Data, BufferLength);
end;

function PkgxQuerySecurityPropertyPackage;
var
  Context: PPackageSecurityContextReference;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageSecurityProperty);

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified application index
  Result := PkgxLocatePackageSecurityContext(Context, InfoReference);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'GetPackageSecurityProperty';
  Result.LastCall.UsesInfoClass(PropertyId, icQuery);

  repeat
    BufferLength := Buffer.Size;
    Result.Win32ErrorOrSuccess := GetPackageSecurityProperty(Context,
      PropertyId, BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength);
end;

class function PkgxPackage.QueryProperty<T>;
var
  Context: PPackageContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageProperty);

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageContext(Context, InfoReference, DependencyIndex);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageProperty';
  Result.LastCall.UsesInfoClass(PropertyId, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageProperty(Context, PropertyId,
    BufferSize, @Buffer);
end;

class function PkgxPackage.QueryApplicationProperty<T>;
var
  Context: PPackageApplicationContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageApplicationProperty);

  if not Result.IsSuccess then
    Exit;

  // Retrieve a application context for the specified index
  Result := PkgxLocatePackageApplicationContext(Context, InfoReference,
    ApplicationIndex);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageApplicationProperty';
  Result.LastCall.UsesInfoClass(PropertyId, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageApplicationProperty(Context,
    PropertyId, BufferSize, @Buffer)
end;

class function PkgxPackage.QuerySecurityProperty<T>;
var
  Context: PPackageSecurityContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageSecurityProperty);

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageSecurityContext(Context, InfoReference);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageSecurityProperty';
  Result.LastCall.UsesInfoClass(PropertyId, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageSecurityProperty(Context, PropertyId,
    BufferSize, @Buffer);
end;

class function PkgxPackage.QueryTargetPlatformProperty<T>;
var
  Context: PTargetPlatformContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageTargetPlatformProperty);

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageTargetPlatformContext(Context, InfoReference);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageTargetPlatformProperty';
  Result.LastCall.UsesInfoClass(PropertyId, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageTargetPlatformProperty(Context,
    PropertyId, BufferSize, @Buffer);
end;

class function PkgxPackage.QueryGlobalizationProperty<T>;
var
  Context: PPackageGlobalizationContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageGlobalizationProperty);

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageGlobalizationContext(Context, InfoReference,
    DependencyIndex);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageGlobalizationProperty';
  Result.LastCall.UsesInfoClass(PropertyId, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageGlobalizationProperty(Context,
    PropertyId, BufferSize, @Buffer);
end;

function PkgxEnumerateAppUserModelIds;
var
  Buffer: IMemory<PAppIdArray>;
  BufferSize, Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_GetPackageApplicationIds);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  Result.Location := 'GetPackageApplicationIds';

  repeat
    BufferSize := Buffer.Size;
    Result.Win32ErrorOrSuccess := GetPackageApplicationIds(InfoReference.Data,
      BufferSize, Buffer.Data, @Count);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferSize);

  // Check for spacial error that indicates no entries
  if Result.Win32Error = APPMODEL_ERROR_NO_APPLICATION then
  begin
    AppUserModelIds := nil;
    Exit(NtxSuccess);
  end;

  if not Result.IsSuccess then
    Exit;

  SetLength(AppUserModelIds, Count);

  for i := 0 to High(AppUserModelIds) do
    AppUserModelIds[i] := RtlxCaptureStringWithRange(
      Buffer.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF},
      Buffer.Offset(Buffer.Size));
end;

{ Verification }

function PkgxIsValidFullName;
begin
  Result := LdrxCheckDelayedImport(delayed_VerifyPackageFullName).IsSuccess and
    (VerifyPackageFullName(PWideChar(PackageFullName)) = ERROR_SUCCESS);
end;

function PkgxIsValidFamilyName;
begin
  Result := LdrxCheckDelayedImport(delayed_VerifyPackageFamilyName).IsSuccess and
    (VerifyPackageFamilyName(PWideChar(PackageFamilyName)) = ERROR_SUCCESS);
end;

function PkgxIsValidAppUserModelId;
begin
  Result := LdrxCheckDelayedImport(delayed_VerifyApplicationUserModelId).IsSuccess and
    (VerifyApplicationUserModelId(PWideChar(AppUserModelId)) = ERROR_SUCCESS);
end;

{ PRI }

function PkgxExpandResourceString;
var
  Buffer: IMemory<PWideChar>;
  RequiredLength: NativeUInt;
begin
  Result := LdrxCheckDelayedImport(delayed_ResourceManagerQueueGetString);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(WideChar));
  Result.Location := 'ResourceManagerQueueGetString';

  repeat
    RequiredLength := 0;
    Result.HResult := ResourceManagerQueueGetString(
      PWideChar(ResourceDefinition), nil, nil, Buffer.Data,
      Buffer.Size div SizeOf(WideChar), @RequiredLength);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), RequiredLength *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  ResourceValue := RtlxCaptureString(Buffer.Data,
    Buffer.Size div SizeOf(WideChar));
end;

function PkgxExpandResourceStringVar;
var
  Expanded: String;
begin
  Result := PkgxExpandResourceString(Resource, Expanded);

  if Result.IsSuccess then
    Resource := Expanded;
end;

end.
