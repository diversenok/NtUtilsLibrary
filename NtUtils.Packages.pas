unit NtUtils.Packages;

{
  This module provides functions for retrieving information about packaged
  applications.
}

interface

uses
  Ntapi.WinNt, Ntapi.appmodel, Ntapi.ntseapi, Ntapi.ntpebteb, Ntapi.Versions,
  DelphiApi.Reflection, DelphiUtils.AutoObjects, NtUtils;

(*
  Formats:
    {FullName} = {Name}_{Version}_{Architecture}_{ResourceId}_{PublusherId}
    {FamilyName} = {Name}_{PublusherId}
    {AppUserModeId} = {FamilyName}!{AppId}

  Examples:
   "Microsoft.MSIXPackagingTool_1.2023.319.0_x64__8wekyb3d8bbwe" - Full Name
   "Microsoft.MSIXPackagingTool_8wekyb3d8bbwe!Msix.App" - App user-mode ID
*)

type
  IPackageInfoReference = IAutoPointer;

  TPkgxPackageId = record
    ProcessorArchitecture: TProcessorArchitecture;
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

// Convert a pakage name and publisher from a family name
[MinOSVersion(OsWin8)]
function PkgxDeriveNameAndPublisherIdFromFamilyName(
  const FamilyName: String;
  out Name: String;
  out PulisherId: String
): TNtxStatus;

{ Querying by name }

// Query identification information of a package
[MinOSVersion(OsWin8)]
function PkgxQueryIdByFullName(
  out PackageId: TPkgxPackageId;
  const FullName: String;
  Flags: TPackageInformationFlags = PACKAGE_INFORMATION_FULL
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

// Query maximum tested OS version for a package
[MinOSVersion(OsWin81)]
function PkgxQueryOSMaxVersionTestedByFullName(
  out OSMaxVersionTested: TPackageVersion;
  const FullName: String
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
function PkgxLocatePackageContext(
  out Context: PPackageContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package application context (internal use)
function PkgxLocatePackageApplicationContext(
  out Context: PPackageApplicationContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package resources context (internal use)
function PkgxLocatePackageResourcesContext(
  out Context: PPackageResourcesContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package application resources context (internal use)
function PkgxLocatePackageApplicationResourcesContext(
  out Context: PPackageResourcesContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package globalization context (internal use)
function PkgxLocatePackageGlobalizationContext(
  out Context: PPackageGlobalizationContextReference;
  const InfoReference: IPackageInfoReference;
  Index: Cardinal
): TNtxStatus;

// Get package security context (internal use)
function PkgxLocatePackageSecurityContext(
  out Context: PPackageSecurityContextReference;
  const InfoReference: IPackageInfoReference
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
  InfoClass: TPackageProperty;
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
  InfoClass: TPackageApplicationProperty;
  ApplicationIndex: Cardinal = 0
): TNtxStatus;

// Query a variable-size security property of a package
[MinOSVersion(OsWin81)]
function PkgxQuerySecurityPropertyPackage(
  out Buffer: IMemory;
  const InfoReference: IPackageInfoReference;
  InfoClass: TPackageSecurityProperty
): TNtxStatus;

type
  PkgxPackage = class abstract
    // Query fixed-size package property
    class function QueryProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      InfoClass: TPackageProperty;
      DependencyIndex: Cardinal = 0
    ): TNtxStatus; static;

    // Query fixed-size application package property
    class function QueryApplicationProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      InfoClass: TPackageApplicationProperty;
      ApplicationIndex: Cardinal = 0
    ): TNtxStatus; static;

    // Query fixed-size globalization property
    class function QueryGlobalizationProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      InfoClass: TPackageGlobalizationProperty;
      DependencyIndex: Cardinal = 0
    ): TNtxStatus; static;

    // Query fixed-size security property
    class function QuerySecurityProperty<T>(
      out Buffer: T;
      const InfoReference: IPackageInfoReference;
      InfoClass: TPackageSecurityProperty
    ): TNtxStatus; static;
  end;

// Enumerate application IDs in a package
[MinOSVersion(OsWin81)]
function PkgxEnumerateAppUserModeIds(
  out AppUserModeIds: TArray<String>;
  const InfoReference: IPackageInfoReference
): TNtxStatus;

{ AppModel Policy }

// Retrieve an app model policy for package by its access token
[MinOSVersion(OsWin10RS1)]
function PkgxQueryAppModelPolicy(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  PolicyType: TAppModelPolicyType;
  out Policy: TAppModelPolicyValue;
  ReturnValueOnly: Boolean = True // aka clear type bits of the policy
): TNtxStatus;

// Check if the current OS version supports the specified app model policy type
function PkgxIsPolicyTypeSupported(
  PolicyType: TAppModelPolicyType
): Boolean;

// Find TypeInfo of the enumeration that corresponds to an app model policy type
function PkgxGetPolicyTypeInfo(
  PolicyType: TAppModelPolicyType
): Pointer;

implementation

uses
  Ntapi.ntstatus, Ntapi.WinError, Ntapi.ntldr, NtUtils.Ldr, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Helper functions }

type
  TAutoPackageInfoReference = class(TCustomAutoPointer, IPackageInfoReference)
    procedure Release; override;
  end;

procedure TAutoPackageInfoReference.Release;
begin
  if Assigned(FData) and LdrxCheckModuleDelayedImport(kernelbase,
    'ClosePackageInfo').IsSuccess then
    ClosePackageInfo(FData);

  FData := nil;
  inherited;
end;

function PkgxpCapturePackageId(
  [in] Buffer: PPackageId
): TPkgxPackageId;
begin
  Result.ProcessorArchitecture := Buffer.ProcessorArchitecture;
  Result.Version := Buffer.Version;
  Result.Name := String(Buffer.Name);
  Result.Publisher := String(Buffer.Publisher);
  Result.ResourceID := String(Buffer.ResourceID);
  Result.PublisherID := String(Buffer.PublisherID);
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
  const Buffer: TPackageInfo
): TPkgxPackageInfo;
begin
  Result.Properties := Buffer.Flags;
  Result.Path := String(Buffer.Path);
  Result.PackageFullName := String(Buffer.PackageFullName);
  Result.PackageFamilyName := String(Buffer.PackageFamilyName);
  Result.ID := PkgxpCapturePackageId(@Buffer.PackageId);
end;

{ Deriving/conversion }

function PkgxDeriveFullNameFromId;
var
  Id: TPackageId;
  BufferLength: Cardinal;
  Buffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'PackageFullNameFromId');

  if not Result.IsSuccess then
    Exit;

  BufferLength := 0;
  Id := PkgxpConvertPackageId(PackageId);

  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(BufferLength * SizeOf(WideChar));

    Result.Location := 'PackageFullNameFromId';
    Result.Win32ErrorOrSuccess := PackageFullNameFromId(Id, BufferLength,
      Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

  if Result.IsSuccess then
    FullName := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxDeriveFamilyNameFromId;
var
  Id: TPackageId;
  BufferLength: Cardinal;
  Buffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'PackageFamilyNameFromId');

  if not Result.IsSuccess then
    Exit;

  BufferLength := 0;
  Id := PkgxpConvertPackageId(PackageId);

  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(BufferLength * SizeOf(WideChar));

    Result.Location := 'PackageFamilyNameFromId';
    Result.Win32ErrorOrSuccess := PackageFamilyNameFromId(Id, BufferLength,
      Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

  if Result.IsSuccess then
    FamilyName := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxDeriveFamilyNameFromFullName;
var
  BufferLength: Cardinal;
  Buffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'PackageFamilyNameFromFullName');

  if not Result.IsSuccess then
    Exit;

  BufferLength := 0;
  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(BufferLength * SizeOf(WideChar));

    Result.Location := 'PackageFamilyNameFromFullName';
    Result.Win32ErrorOrSuccess := PackageFamilyNameFromFullName(
      PWideChar(FullName), BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

  if Result.IsSuccess then
    FamilyName := RtlxCaptureString(Buffer.Data, BufferLength);
end;

function PkgxDeriveNameAndPublisherIdFromFamilyName;
var
  NameLength, PublisherIdLength: Cardinal;
  NameBuffer, PublisherBuffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'PackageNameAndPublisherIdFromFamilyName');

  if not Result.IsSuccess then
    Exit;

  NameLength := 0;
  PublisherIdLength := 0;

  repeat
    IMemory(NameBuffer) := Auto.AllocateDynamic(NameLength * SizeOf(WideChar));
    IMemory(PublisherBuffer) := Auto.AllocateDynamic(PublisherIdLength *
      SizeOf(WideChar));

    Result.Location := 'PackageNameAndPublisherIdFromFamilyName';
    Result.Win32ErrorOrSuccess := PackageNameAndPublisherIdFromFamilyName(
      PWideChar(FamilyName), NameLength, NameBuffer.Data, PublisherIdLength,
      PublisherBuffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(NameBuffer), NameLength *
    SizeOf(WideChar), nil) or not NtxExpandBufferEx(Result,
    IMemory(PublisherBuffer), PublisherIdLength * SizeOf(WideChar), nil);

  if Result.IsSuccess then
  begin
    Name := RtlxCaptureString(NameBuffer.Data, NameLength);
    PulisherId := RtlxCaptureString(PublisherBuffer.Data, PublisherIdLength);
  end;
end;

{ Querying by name }

function PkgxQueryIdByFullName;
var
  BufferSize: Cardinal;
  Buffer: IMemory<PPackageId>;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'PackageIdFromFullName');

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(TPackageId);
  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(BufferSize);

    Result.Location := 'PackageIdFromFullName';
    Result.Win32ErrorOrSuccess := PackageIdFromFullName(PWideChar(FullName),
      Flags, BufferSize, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferSize, nil);

  if Result.IsSuccess then
    PackageId := PkgxpCapturePackageId(Buffer.Data);
end;

function PkgxQueryOriginByFullName;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'GetStagedPackageOrigin');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetStagedPackageOrigin';
  Result.Win32ErrorOrSuccess := GetStagedPackageOrigin(PWideChar(FullName),
    Origin);
end;

function PkgxQueryIsMsixByFullName;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'CheckIsMSIXPackage');

  if Result.IsSuccess then
  begin
    Result.Location := 'CheckIsMSIXPackage';
    Result.HResult := CheckIsMSIXPackage(PWideChar(FullName), IsMSIXPackage);
  end;
end;

function PkgxQueryInstallTimeByFullName;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'GetPackageInstallTime');

  if Result.IsSuccess then
  begin
    Result.Location := 'GetPackageInstallTime';
    Result.HResult := GetPackageInstallTime(PWideChar(FullName), InstallTime);
  end;
end;

function PkgxQueryOSMaxVersionTestedByFullName;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'AppXGetOSMaxVersionTested');

  if Result.IsSuccess then
  begin
    Result.Location := 'AppXGetOSMaxVersionTested';
    Result.HResult := AppXGetOSMaxVersionTested(PWideChar(FullName),
      OSMaxVersionTested);
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
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackagesByPackageFamily');

  if not Result.IsSuccess then
    Exit;

  Count := 0;
  BufferLength := 0;

  repeat
    IMemory(Names) := Auto.AllocateDynamic(Count * SizeOf(PWideChar));
    IMemory(Buffer) := Auto.AllocateDynamic(BufferLength * SizeOf(WideChar));

    Result.Location := 'GetPackagesByPackageFamily';
    Result.Win32ErrorOrSuccess := GetPackagesByPackageFamily(
      PWideChar(FamilyName), Count, Names.Data, BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Names), Count * SizeOf(PWideChar),
    nil) or not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

  if not Result.IsSuccess then
    Exit;

  SetLength(FullNames, Count);

  for i := 0 to High(FullNames) do
    FullNames[i] := String(Names.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF});
end;

function PkgxEnumeratePackagesInFamilyByNameEx;
var
  Count, BufferLength: Cardinal;
  Names: IMemory<PPackageFullNames>;
  Buffer: IMemory<PWideChar>;
  Properties: IMemory<PPackagePropertiesArray>;
  i: Integer;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'FindPackagesByPackageFamily');

  if not Result.IsSuccess then
    Exit;

  Count := 0;
  BufferLength := 0;

  repeat
    IMemory(Names) := Auto.AllocateDynamic(Count * SizeOf(PWideChar));
    IMemory(Properties) := Auto.AllocateDynamic(Count *
      SizeOf(TPackageProperties));
    IMemory(Buffer) := Auto.AllocateDynamic(BufferLength *
      SizeOf(WideChar));

    Result.Location := 'FindPackagesByPackageFamily';
    Result.Win32ErrorOrSuccess := FindPackagesByPackageFamily(
      PWideChar(FamilyName), Filter, Count, Names.Data, BufferLength,
      Buffer.Data, Properties.Data);

  until not NtxExpandBufferEx(Result, IMemory(Names), Count *
    SizeOf(PWideChar), nil) or not NtxExpandBufferEx(Result,
    IMemory(Buffer), BufferLength * SizeOf(WideChar), nil);

  if not Result.IsSuccess then
    Exit;

  SetLength(Packages, Count);

  for i := 0 to High(Packages) do
  begin
    Packages[i].FullName := String(Names.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF});
    Packages[i].Properties := Properties.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
  end;
end;

{ Info reference open }

function PkgxOpenPackageInfo;
var
  PackageInfoReference: TPackageInfoReference;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'OpenPackageInfoByFullName');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OpenPackageInfoByFullName';
  Result.Win32ErrorOrSuccess := OpenPackageInfoByFullName(PWideChar(FullName),
    0, PackageInfoReference);

  if Result.IsSuccess then
    InfoReference := TAutoPackageInfoReference.Capture(PackageInfoReference);
end;

function PkgxOpenPackageInfoForUser;
var
  PackageInfoReference: TPackageInfoReference;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'OpenPackageInfoByFullNameForUser');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OpenPackageInfoByFullNameForUser';
  Result.Win32ErrorOrSuccess := OpenPackageInfoByFullNameForUser(
    Auto.RefOrNil<PSid>(UserSid), PWideChar(FullName), 0,
    PackageInfoReference);

  if Result.IsSuccess then
    InfoReference := TAutoPackageInfoReference.Capture(PackageInfoReference);
end;

{ Contexts }

function PkgxLocatePackageContext;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'GetPackageContext');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageContext';
  Result.Win32ErrorOrSuccess := GetPackageContext(InfoReference.Data, Index, 0,
    Context);
end;

function PkgxLocatePackageApplicationContext;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageApplicationContext');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageApplicationContext';
  Result.Win32ErrorOrSuccess := GetPackageApplicationContext(InfoReference.Data,
    Index, 0, Context);
end;

function PkgxLocatePackageResourcesContext;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageResourcesContext');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageResourcesContext';
  Result.Win32ErrorOrSuccess := GetPackageResourcesContext(InfoReference.Data,
    Index, 0, Context);
end;

function PkgxLocatePackageApplicationResourcesContext;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageApplicationResourcesContext');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageApplicationResourcesContext';
  Result.Win32ErrorOrSuccess := GetPackageApplicationResourcesContext(
    InfoReference.Data, Index, 0, Context);
end;

function PkgxLocatePackageGlobalizationContext;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageGlobalizationContext');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageGlobalizationContext';
  Result.Win32ErrorOrSuccess := GetPackageGlobalizationContext(
    InfoReference.Data, Index, 0, Context);
end;

function PkgxLocatePackageSecurityContext;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageSecurityContext');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageSecurityContext';
  Result.Win32ErrorOrSuccess := GetPackageSecurityContext(
    InfoReference.Data, 0, Context);
end;

{ Querying by info reference }

function PkgxQueryPackageInfo;
var
  BufferSize: Cardinal;
  Buffer: IMemory<PPackageInfoArray>;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'GetPackageInfo');

  if not Result.IsSuccess then
    Exit;

  BufferSize := 0;

  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(BufferSize);

    Result.Location := 'GetPackageInfo';
    Result.Win32ErrorOrSuccess := GetPackageInfo(InfoReference.Data, Flags,
      BufferSize, Buffer.Data, @Count);
  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferSize, nil);

  if not Result.IsSuccess then
    Exit;

  SetLength(Info, Count);

  for i := 0 to High(Info) do
    Info[i] := PkgxpCapturePackageInfo(Buffer
      .Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF})
end;

function PkgxQueryPackageInfo2;
var
  BufferSize: Cardinal;
  Buffer: IMemory<PPackageInfoArray>;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'GetPackageInfo2');

  if not Result.IsSuccess then
    Exit;

  BufferSize := 0;

  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(BufferSize);

    Result.Location := 'GetPackageInfo2';
    Result.Win32ErrorOrSuccess := GetPackageInfo2(InfoReference.Data, Flags,
      PathType, BufferSize, Buffer.Data, @Count);
  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferSize, nil);

  if not Result.IsSuccess then
    Exit;

  SetLength(Info, Count);

  for i := 0 to High(Info) do
    Info[i] := PkgxpCapturePackageInfo(Buffer
      .Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF})
end;

function PkgxQueryStringPropertyPackage;
var
  Context: PPackageContextReference;
  Buffer: IWideChar;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'GetPackagePropertyString');

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageContext(Context, InfoReference, DependencyIndex);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackagePropertyString';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);

    Result.Win32ErrorOrSuccess := GetPackagePropertyString(Context, InfoClass,
      BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

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
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageOSMaxVersionTested');

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
  Buffer: IWideChar;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageApplicationPropertyString');

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified application index
  Result := PkgxLocatePackageApplicationContext(Context, InfoReference,
    ApplicationIndex);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageApplicationPropertyString';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);

    Result.Win32ErrorOrSuccess := GetPackageApplicationPropertyString(Context,
      InfoClass, BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

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
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageSecurityProperty');

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified application index
  Result := PkgxLocatePackageSecurityContext(Context, InfoReference);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageSecurityProperty';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  IMemory(Buffer) := Auto.AllocateDynamic(0);
  repeat
    BufferLength := Buffer.Size;

    Result.Win32ErrorOrSuccess := GetPackageSecurityProperty(Context,
      InfoClass, BufferLength, Buffer.Data);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength, nil);
end;

class function PkgxPackage.QueryProperty<T>;
var
  Context: PPackageContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'GetPackageProperty');

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageContext(Context, InfoReference, DependencyIndex);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageProperty';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageProperty(Context, InfoClass,
    BufferSize, @Buffer);
end;

class function PkgxPackage.QueryApplicationProperty<T>;
var
  Context: PPackageApplicationContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageApplicationProperty');

  if not Result.IsSuccess then
    Exit;

  // Retrieve a application context for the specified index
  Result := PkgxLocatePackageApplicationContext(Context, InfoReference,
    ApplicationIndex);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageApplicationProperty';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageApplicationProperty(Context,
    InfoClass, BufferSize, @Buffer)
end;

class function PkgxPackage.QueryGlobalizationProperty<T>;
var
  Context: PPackageGlobalizationContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageGlobalizationProperty');

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageGlobalizationContext(Context, InfoReference,
    DependencyIndex);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageGlobalizationProperty';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageGlobalizationProperty(Context,
    InfoClass, BufferSize, @Buffer);
end;

class function PkgxPackage.QuerySecurityProperty<T>;
var
  Context: PPackageSecurityContextReference;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'GetPackageSecurityProperty');

  if not Result.IsSuccess then
    Exit;

  // Retrieve a context for the specified index
  Result := PkgxLocatePackageSecurityContext(Context, InfoReference);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);

  Result.Location := 'GetPackageSecurityProperty';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.Win32ErrorOrSuccess := GetPackageSecurityProperty(Context, InfoClass,
    BufferSize, @Buffer);
end;

function PkgxEnumerateAppUserModeIds;
var
  Buffer: IMemory<PAppIdArray>;
  BufferSize, Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase, 'GetPackageApplicationIds');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetPackageApplicationIds';
  IMemory(Buffer) := Auto.AllocateDynamic(0);

  repeat
    BufferSize := Buffer.Size;

    Result.Win32ErrorOrSuccess := GetPackageApplicationIds(InfoReference.Data,
      BufferSize, Buffer.Data, @Count);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferSize, nil);

  // Check for spacial error that indicates no entries
  if Result.Win32Error = APPMODEL_ERROR_NO_APPLICATION then
  begin
    AppUserModeIds := nil;
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  if not Result.IsSuccess then
    Exit;

  SetLength(AppUserModeIds, Count);

  for i := 0 to High(AppUserModeIds) do
    AppUserModeIds[i] := String(Buffer.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF});
end;

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
