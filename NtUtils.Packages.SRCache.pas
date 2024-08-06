unit NtUtils.Packages.SRCache;

{
  This module provides functions for retrieving information about packaged
  applications from State Repository Cache.
}

interface

uses
  Ntapi.appmodel, NtUtils;

type
  TSRCachePackageFamilyId = type Cardinal;
  TSRCachePackageId = type Cardinal;
  TSRCacheApplicationId = type Cardinal;

{ Package Families }

// Enumerate package family names
function PkgxSRCacheIteratePackageFamilyNames(
  [out, opt] Status: PNtxStatus
): IEnumerable<String>;

// Enumerate package family IDs
function PkgxSRCacheIteratePackageFamilyIds(
  [out, opt] Status: PNtxStatus
): IEnumerable<TSRCachePackageFamilyId>;

// Lookup package family identifier
function PkgxSRCacheLookupPackageFamilyId(
  const PackageFamilyName: String;
  out PackageFamilyId: TSRCachePackageFamilyId
): TNtxStatus;

// Open package family data key by ID
function PkgxSRCacheOpenPackageFamiliy(
  PackageFamilyId: TSRCachePackageFamilyId;
  out hxPackageFamilyKey: IHandle
): TNtxStatus;

// Open package family data key by name
function PkgxSRCacheOpenPackageFamiliyByName(
  const PackageFamilyName: String;
  out hxPackageFamilyKey: IHandle
): TNtxStatus;

// Query package family name from data key
function PkgxSRCacheQueryPackageFamilyName(
  const hxPackageFamilyKey: IHandle;
  out PackageFamilyName: String
): TNtxStatus;

// Query package family publisher from data key
function PkgxSRCacheQueryPackageFamilyPublisher(
  const hxPackageFamilyKey: IHandle;
  out Publisher: String
): TNtxStatus;

{ Packages }

// Enumerate package IDs beloning to a package family by ID
function PkgxSRCacheIteratePackageIDsInFamily(
  [out, opt] Status: PNtxStatus;
  PackageFamilyId: TSRCachePackageFamilyId
): IEnumerable<TSRCachePackageId>;

// Enumerate package IDs
function PkgxSRCacheIteratePackageIDs(
  [out, opt] Status: PNtxStatus
): IEnumerable<TSRCachePackageId>;

// Lookup package identifier
function PkgxSRCacheLookupPackageId(
  const PackageFullName: String;
  out PackageId: TSRCachePackageId
): TNtxStatus;

// Open package data key by ID
function PkgxSRCacheOpenPackage(
  PackageId: TSRCachePackageId;
  out hxPackageKey: IHandle
): TNtxStatus;

// Open package data key by name
function PkgxSRCacheOpenPackageByName(
  const PackageFullName: String;
  out hxPackageKey: IHandle
): TNtxStatus;

// Query package name from data key
function PkgxSRCacheQueryPackageName(
  const hxPackageKey: IHandle;
  out PackageFullName: String
): TNtxStatus;

// Query package family ID from data key
function PkgxSRCacheQueryPackageFamilyId(
  const hxPackageKey: IHandle;
  out PackageFamilyId: TSRCachePackageFamilyId
): TNtxStatus;

// Query package flags from data key
function PkgxSRCacheQueryPackageFlags(
  const hxPackageKey: IHandle;
  out Flags: TStateRepositoryPackageFlags
): TNtxStatus;

// Query package flags v2 from data key
function PkgxSRCacheQueryPackageFlags2(
  const hxPackageKey: IHandle;
  out Flags2: TStateRepositoryPackageFlags2
): TNtxStatus;

// Query package type from data key
function PkgxSRCacheQueryPackageType(
  const hxPackageKey: IHandle;
  out PackageType: TStateRepositoryPackageType
): TNtxStatus;

// Query package installed location from data key
function PkgxSRCacheQueryPackageLocation(
  const hxPackageKey: IHandle;
  out InstalledLocation: String
): TNtxStatus;

{ Applications }

// Enumerate applications in a package
function PkgxSRCacheIterateApplicationIDsInPackage(
  [out, opt] Status: PNtxStatus;
  PackageId: TSRCachePackageId
): IEnumerable<TSRCacheApplicationId>;

// Enumerate applications in all packages
function PkgxSRCacheIterateApplicationIDs(
  [out, opt] Status: PNtxStatus
): IEnumerable<TSRCacheApplicationId>;

// Lookup application identifier
function PkgxSRCacheLookupApplicationId(
  out ApplicationId: TSRCacheApplicationId;
  PackageId: TSRCachePackageId;
  const RelativeName: String
): TNtxStatus;

// Open application data key by ID
function PkgxSRCacheOpenApplication(
  ApplicationId: TSRCacheApplicationId;
  out hxApplicationKey: IHandle
): TNtxStatus;

// Query full application name from data key
function PkgxSRCacheQueryApplicationAumid(
  const hxApplicationKey: IHandle;
  out Aumid: String
): TNtxStatus;

// Query relative application name from data key
function PkgxSRCacheQueryApplicationPraid(
  const hxApplicationKey: IHandle;
  out RelativeName: String
): TNtxStatus;

// Query full application name from data key
function PkgxSRCacheQueryApplicationPackageID(
  const hxApplicationKey: IHandle;
  out PackageId: TSRCachePackageId
): TNtxStatus;

// Query full application flags from data key
function PkgxSRCacheQueryApplicationFlags(
  const hxApplicationKey: IHandle;
  out Flags: TStateRepositoryApplicationFlags
): TNtxStatus;

// Query full application entrypoint from data key
function PkgxSRCacheQueryApplicationEntrypoint(
  const hxApplicationKey: IHandle;
  out Entrypoint: String
): TNtxStatus;

// Query full application entrypoint from data key
function PkgxSRCacheQueryApplicationExecutable(
  const hxApplicationKey: IHandle;
  out Executable: String
): TNtxStatus;

// Query full application entrypoint from data key
function PkgxSRCacheQueryApplicationStartPage(
  const hxApplicationKey: IHandle;
  out StartPage: String
): TNtxStatus;

implementation

uses
  Ntapi.ntregapi, Ntapi.WinError, NtUtils.Registry, NtUtils.Packages,
  NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

const
  SR_CACHE_ROOT = REG_PATH_MACHINE + '\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModel\StateRepository\Cache';
  SR_CACHE_PACKAGE_FAMILY_INDEX = SR_CACHE_ROOT + '\PackageFamily\Index\PackageFamilyName';
  SR_CACHE_PACKAGE_FAMILY_DATA = SR_CACHE_ROOT + '\PackageFamily\Data';
  SR_CACHE_PACKAGE_INDEX = SR_CACHE_ROOT + '\Package\Index\PackageFullName';
  SR_CACHE_PACKAGE_INDEX_FAMILY = SR_CACHE_ROOT + '\Package\Index\PackageFamily';
  SR_CACHE_PACKAGE_DATA = SR_CACHE_ROOT + '\Package\Data';
  SR_CACHE_APPLICATION_INDEX = SR_CACHE_ROOT + '\Application\Index\Package';
  SR_CACHE_APPLICATION_INDEX_PRAID = SR_CACHE_ROOT + '\Application\Index\PackageAndPackageRelativeApplicationId';
  SR_CACHE_APPLICATION_DATA = SR_CACHE_ROOT + '\Application\Data';

{ Common }

function PkgxUIntToStr(Id: Cardinal): String;
begin
  Result := RtlxUIntToStr(Id, nsHexadecimal, 0, []);
end;

function PkgxStrToUInt(const S: String; out Id: Cardinal): Boolean;
begin
  Result := RtlxStrToUInt(S, Id, nsHexadecimal, []);
end;

{ Package Families }

function PkgxSRCacheIteratePackageFamilyNames;
var
  hxIndexKey: IHandle;
  Index: Integer;
begin
  Index := 0;

  Result := NtxAuto.IterateEx<String>(
    Status,
    function : TNtxStatus
    begin
      // Open the package families index
      Result := NtxOpenKey(hxIndexKey, SR_CACHE_PACKAGE_FAMILY_INDEX,
        KEY_ENUMERATE_SUB_KEYS);
    end,
    function (out Current: String): TNtxStatus
    var
      KeyInfo: TNtxRegKey;
    begin
      // Retrieve a sub-key
      Result := NtxEnumerateKey(hxIndexKey, Index, KeyInfo);

      if not Result.IsSuccess then
        Exit;

      // Parse the name into an ID
      if not PkgxIsValidFamilyName(KeyInfo.Name) then
      begin
        Result.Location := 'PkgxSRCacheIteratePackageFamilyNames';
        Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
        Exit;
      end
      else
        Current := KeyInfo.Name;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function PkgxSRCacheIteratePackageFamilyIds;
var
  hxDataKey: IHandle;
  Index: Integer;
begin
  Index := 0;

  Result := NtxAuto.IterateEx<TSRCachePackageFamilyId>(
    Status,
    function : TNtxStatus
    begin
      // Open the package families index
      Result := NtxOpenKey(hxDataKey, SR_CACHE_PACKAGE_FAMILY_DATA,
        KEY_ENUMERATE_SUB_KEYS);
    end,
    function (out Current: TSRCachePackageFamilyId): TNtxStatus
    var
      KeyInfo: TNtxRegKey;
    begin
      // Retrieve a sub-key
      Result := NtxEnumerateKey(hxDataKey, Index, KeyInfo);

      if not Result.IsSuccess then
        Exit;

      // Parse the name into an ID
      if not PkgxStrToUInt(KeyInfo.Name, Cardinal(Current)) then
      begin
        Result.Location := 'PkgxSRCacheIteratePackageFamilyIds';
        Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
        Exit;
      end;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function PkgxSRCacheLookupPackageFamilyId;
var
  IndexInfo: TNtxRegKey;
  hxIndexKey: IHandle;
begin
  // Open the index key
  Result := NtxOpenKey(
    hxIndexKey,
    RtlxCombinePaths(SR_CACHE_PACKAGE_FAMILY_INDEX, PackageFamilyName),
    KEY_ENUMERATE_SUB_KEYS
  );

  if not Result.IsSuccess then
    Exit;

  // Query the first sub-key
  Result := NtxEnumerateKey(hxIndexKey, 0, IndexInfo);

  if not Result.IsSuccess then
    Exit;

  // Convert the sub-key name to an ID
  if not PkgxStrToUInt(IndexInfo.Name, Cardinal(PackageFamilyId)) then
  begin
    Result.Location := 'PkgxSRCacheLookupPackageFamilyId';
    Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
  end;
end;

function PkgxSRCacheOpenPackageFamiliy;
begin
  Result := NtxOpenKey(
    hxPackageFamilyKey,
    RtlxCombinePaths(SR_CACHE_PACKAGE_FAMILY_DATA,
      PkgxUIntToStr(PackageFamilyId)),
    KEY_QUERY_VALUE
  );
end;

function PkgxSRCacheOpenPackageFamiliyByName;
var
  FamilyId: TSRCachePackageFamilyId;
begin
  // Convert the name into ID
  Result := PkgxSRCacheLookupPackageFamilyId(PackageFamilyName, FamilyId);

  if not Result.IsSuccess then
    Exit;

  // Open by ID
  Result := PkgxSRCacheOpenPackageFamiliy(FamilyId, hxPackageFamilyKey);
end;

function PkgxSRCacheQueryPackageFamilyName;
begin
  Result := NtxQueryValueKeyString(hxPackageFamilyKey, 'PackageFamilyName',
    PackageFamilyName);
end;

function PkgxSRCacheQueryPackageFamilyPublisher;
begin
  Result := NtxQueryValueKeyString(hxPackageFamilyKey, 'Publisher', Publisher);
end;

{ Packages }

function PkgxSRCacheIteratePackageIDsInFamily;
var
  hxKey: IHandle;
  Index: Integer;
begin
  hxKey := nil;
  Index := 0;

  Result := NtxAuto.IterateEx<TSRCachePackageId>(
    Status,
    function : TNtxStatus
    begin
      // Open the package full name list in the state repository cache
      Result := NtxOpenKey(
        hxKey,
        RtlxCombinePaths(SR_CACHE_PACKAGE_INDEX_FAMILY,
          PkgxUIntToStr(PackageFamilyId)),
        KEY_ENUMERATE_SUB_KEYS
        );
    end,
    function (out Current: TSRCachePackageId): TNtxStatus
    var
      KeyInfo: TNtxRegKey;
    begin
      // Retrieve a sub-key
      Result := NtxEnumerateKey(hxKey, Index, KeyInfo);

      if not Result.IsSuccess then
        Exit;

      // Parse the name into an ID
      if not PkgxStrToUInt(KeyInfo.Name, Cardinal(Current)) then
      begin
        Result.Location := 'PkgxSRCacheIteratePackageIDsInFamily';
        Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
        Exit;
      end;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function PkgxSRCacheIteratePackageIDs;
begin
end;

function PkgxSRCacheLookupPackageId;
var
  IndexInfo: TNtxRegKey;
  hxIndexKey: IHandle;
begin
  // Open the index key
  Result := NtxOpenKey(
    hxIndexKey,
    RtlxCombinePaths(SR_CACHE_PACKAGE_INDEX, PackageFullName),
    KEY_ENUMERATE_SUB_KEYS
  );

  if not Result.IsSuccess then
    Exit;

  // Query the first sub-key
  Result := NtxEnumerateKey(hxIndexKey, 0, IndexInfo);

  if not Result.IsSuccess then
    Exit;

  // Convert the sub-key name to an ID
  if not RtlxStrToUInt(IndexInfo.Name, Cardinal(PackageId),
    nsHexadecimal, []) then
  begin
    Result.Location := 'PkgxSRCacheLookupPackageId';
    Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
  end;
end;

function PkgxSRCacheOpenPackage;
begin
  Result := NtxOpenKey(
    hxPackageKey,
    RtlxCombinePaths(SR_CACHE_PACKAGE_DATA, PkgxUIntToStr(PackageId)),
    KEY_QUERY_VALUE
  );
end;

function PkgxSRCacheOpenPackageByName;
var
  PackageId: TSRCachePackageId;
begin
  // Convert the name to ID
  Result := PkgxSRCacheLookupPackageId(PackageFullName, PackageId);

  if not Result.IsSuccess then
    Exit;

  // Open by ID
  Result := PkgxSRCacheOpenPackage(PackageId, hxPackageKey);
end;

function PkgxSRCacheQueryPackageName;
begin
  Result := NtxQueryValueKeyString(hxPackageKey, 'PackageFullName',
    PackageFullName);
end;

function PkgxSRCacheQueryPackageFamilyId;
begin
  Result := NtxQueryValueKeyUInt32(hxPackageKey, 'PackageFamily',
    Cardinal(PackageFamilyId));
end;

function PkgxSRCacheQueryPackageFlags;
begin
  Result := NtxQueryValueKeyUInt32(hxPackageKey, 'Flags', Cardinal(Flags));
end;

function PkgxSRCacheQueryPackageFlags2;
begin
  Result := NtxQueryValueKeyUInt32(hxPackageKey, 'Flags2', Cardinal(Flags2));
end;

function PkgxSRCacheQueryPackageType;
begin
  Result := NtxQueryValueKeyUInt32(hxPackageKey, 'PackageType',
    Cardinal(PackageType));
end;

function PkgxSRCacheQueryPackageLocation;
begin
  Result := NtxQueryValueKeyString(hxPackageKey, 'InstalledLocation',
    InstalledLocation);
end;

{ Applications }

function PkgxSRCacheIterateApplicationIDsInPackage;
var
  hxIndexKey: IHandle;
  Index: Integer;
begin
  Index := 0;

  Result := NtxAuto.IterateEx<TSRCacheApplicationId>(
    Status,
    function : TNtxStatus
    begin
      Result := NtxOpenKey(hxIndexKey,
        RtlxCombinePaths(SR_CACHE_APPLICATION_INDEX, PkgxUIntToStr(PackageId)),
        KEY_ENUMERATE_SUB_KEYS);
    end,
    function (out Current: TSRCacheApplicationId): TNtxStatus
    var
      IndexInfo: TNtxRegKey;
    begin
      // Query the sub-key
      Result := NtxEnumerateKey(hxIndexKey, Index, IndexInfo);

      if not Result.IsSuccess then
        Exit;

      // Convert the sub-key name to an ID
      if not PkgxStrToUInt(IndexInfo.Name, Cardinal(Current)) then
      begin
        Result.Location := 'PkgxSRCacheIterateApplicationIDsInPackage';
        Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
        Exit;
      end;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function PkgxSRCacheIterateApplicationIDs;
var
  hxDataKey: IHandle;
  Index: Integer;
begin
  Index := 0;

  Result := NtxAuto.IterateEx<TSRCacheApplicationId>(
    Status,
    function : TNtxStatus
    begin
      Result := NtxOpenKey(hxDataKey, SR_CACHE_APPLICATION_DATA,
        KEY_ENUMERATE_SUB_KEYS);
    end,
    function (out Current: TSRCacheApplicationId): TNtxStatus
    var
      IndexInfo: TNtxRegKey;
    begin
      // Query the sub-key
      Result := NtxEnumerateKey(hxDataKey, Index, IndexInfo);

      if not Result.IsSuccess then
        Exit;

      // Convert the sub-key name to an ID
      if not PkgxStrToUInt(IndexInfo.Name, Cardinal(Current)) then
      begin
        Result.Location := 'PkgxSRCacheIterateApplicationIDs';
        Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
        Exit;
      end;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function PkgxSRCacheLookupApplicationId;
var
  hxIndexKey: IHandle;
  IndexInfo: TNtxRegKey;
begin
  // Open the index key
  Result := NtxOpenKey(
    hxIndexKey,
    RtlxCombinePaths(SR_CACHE_APPLICATION_INDEX_PRAID,
      PkgxUIntToStr(PackageId) + '^' + RelativeName),
    KEY_ENUMERATE_SUB_KEYS
  );

  if not Result.IsSuccess then
    Exit;

  // Query the first sub-key
  Result := NtxEnumerateKey(hxIndexKey, 0, IndexInfo);

  if not Result.IsSuccess then
    Exit;

  // Convert the sub-key name to an ID
  if not PkgxStrToUInt(IndexInfo.Name, Cardinal(ApplicationId)) then
  begin
    Result.Location := 'PkgxSRCacheLookupApplicationId';
    Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
  end;
end;

function PkgxSRCacheOpenApplication;
begin
  Result := NtxOpenKey(hxApplicationKey, RtlxCombinePaths(
    SR_CACHE_APPLICATION_DATA, PkgxUIntToStr(ApplicationId)), KEY_QUERY_VALUE);
end;

function PkgxSRCacheQueryApplicationAumid;
begin
  Result := NtxQueryValueKeyString(hxApplicationKey, 'ApplicationUserModelId',
    Aumid);
end;

function PkgxSRCacheQueryApplicationPraid;
begin
  Result := NtxQueryValueKeyString(hxApplicationKey,
    'PackageRelativeApplicationId', RelativeName);
end;

function PkgxSRCacheQueryApplicationPackageID;
begin
  Result := NtxQueryValueKeyUInt32(hxApplicationKey, 'Package',
    Cardinal(PackageId));
end;

function PkgxSRCacheQueryApplicationFlags;
begin
  Result := NtxQueryValueKeyUInt32(hxApplicationKey, 'Flags',
    Cardinal(Flags));
end;

function PkgxSRCacheQueryApplicationEntrypoint;
begin
  Result := NtxQueryValueKeyString(hxApplicationKey, 'Entrypoint',
    Entrypoint);
end;

function PkgxSRCacheQueryApplicationExecutable;
begin
  Result := NtxQueryValueKeyString(hxApplicationKey, 'Executable',
    Executable);
end;

function PkgxSRCacheQueryApplicationStartPage;
begin
  Result := NtxQueryValueKeyString(hxApplicationKey, 'StartPage', StartPage);
end;

end.
