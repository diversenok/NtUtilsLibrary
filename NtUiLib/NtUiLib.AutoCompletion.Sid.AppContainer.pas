unit NtUiLib.AutoCompletion.Sid.AppContainer;

{
  This module adds support for representing and recognizing AppContainer and
  Package Family SIDs.

  Adding the module as a dependency enhances the following functions:
   - RtlxStringToSid
   - RtlxLookupSidInCustomProviders
   - LsaxLookupSids
}

interface

uses
  Ntapi.ObjBase, NtUtils;

const
  // Custom domain names for AppContainer and Package Family SIDs
  APP_CONTAINER_DOMAIN = 'APP CONTAINER';
  APP_PACKAGE_DOMAIN = 'APP PACKAGE';

type
  TAppContainerFilter = set of (
    afParentAppContainer,
    afChildAppContainer,
    afPackage
  );

// Remember a SID-name mapping for an AppContainer or a Package Family
function RtlxRememberAppContainer(
  const FullMoniker: String
): TNtxStatus;

// Enumerate and remember AppContainers of a user
function RtlxCollectAppContainersForUser(
  [opt] const ParentMoniker: String = '';
  [opt] const UserSid: ISid = nil
): TNtxStatus;

// Enumerate and remember Package Families of a user
[RequiresCOM]
function RtlxCollectPackageFamiliesForUser(
  AllUsers: Boolean;
  [opt] const UserSid: ISid = nil
): TNtxStatus;

// Enumerate all accessible AppContainer and Package Family SIDs
procedure RtlxCollectAllAppContainersAndPackages(
  [opt] const ParentMoniker: String = ''
);

// Retrieve the list of remembered AppContainer names
function RtlxEnumerateRememberedAppContainers(
  Filter: TAppContainerFilter;
  const AddPrefix: String = ''
): TArray<String>;

implementation

uses
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.Versions, NtUtils.SysUtils,
  DelphiUtils.Arrays, NtUtils.Security.Sid, NtUtils.Security.AppContainer,
  NtUtils.Packages, NtUtils.Packages.WinRT, NtUtils.Profiles;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TAppContainerEntry = record
    Sid: ISid;
    Name: String;
    IsPackage: Boolean;
    IsChild: Boolean;
  end;

function RtlxCompareAppContainers(const A, B: TAppContainerEntry): Integer;
begin
   Result := RtlxCompareSids(A.Sid, B.Sid);
end;

var
  // Cache of known AppContainer/Pacakage SIDs
  AppContainers: TArray<TAppContainerEntry>;

function RtlxDeriveAndRememberAppContainer(
  const FullMoniker: String;
  out Entry: TAppContainerEntry
): TNtxStatus;
begin
  Entry.Name := FullMoniker;

  // Construct the SID
  Result := RtlxDeriveFullAppContainerSid(FullMoniker, Entry.Sid,
   @Entry.IsChild);

  if not Result.IsSuccess then
    Exit;

  Entry.IsPackage := not Entry.IsChild and PkgxIsValidFamilyName(FullMoniker);

  // Remember the mapping
  TArray.InsertSorted<TAppContainerEntry>(AppContainers, Entry, dhSkip,
    RtlxCompareAppContainers);
end;

function RtlxRememberAppContainer;
var
  Dummy: TAppContainerEntry;
begin
  Result := RtlxDeriveAndRememberAppContainer(FullMoniker, Dummy);
end;

function RtlxCollectAppContainersForUser;
var
  Monikers: TArray<String>;
  i: Integer;
begin
  // Collect known monikers
  Result := RtlxEnumerateAppContainerMonikers(Monikers, ParentMoniker, UserSid);

  if not Result.IsSuccess then
    Exit;

  // Remember them
  for i := 0 to High(Monikers) do
    if ParentMoniker <> '' then
      RtlxRememberAppContainer(ParentMoniker + '\' + Monikers[i])
    else
      RtlxRememberAppContainer(Monikers[i])
end;

function RtlxCollectPackageFamiliesForUser;
var
  FamilyNames: TArray<String>;
  i: Integer;
begin
  // Collect known package families
  Result := RoxEnumeratePackageFamilyNames(FamilyNames, AllUsers, UserSid);

  if not Result.IsSuccess then
    Exit;

  // Remember them
  for i := 0 to High(FamilyNames) do
    RtlxRememberAppContainer(FamilyNames[i]);
end;

procedure RtlxCollectAllAppContainersAndPackages;
var
  Users: TArray<ISid>;
  i: Integer;
begin
  // AppContainer profiles are per-user; collect all users
  if not UnvxEnumerateProfiles(Users).IsSuccess then
    Users := [nil]; // Or at least the current effective user

  // Package SIDs don't have parent/child hierarchy
  if ParentMoniker = '' then
  begin
    // Try enumerating all packages; otherwise, collect them from accessible users
    if not RtlxCollectPackageFamiliesForUser(True).IsSuccess then
      for i := 0 to High(Users) do
        RtlxCollectPackageFamiliesForUser(False, Users[i]);
  end;

  // Collect AppContaier profiles from accessible users
  for i := 0 to High(Users) do
    RtlxCollectAppContainersForUser(ParentMoniker, Users[i]);
end;

function RtlxRecognizeAppContainerSIDs(
  const StringSid: String;
  out Sid: ISid
): Boolean;
const
  APP_CONTAINER_PREFIX = APP_CONTAINER_DOMAIN + '\';
  APP_PACKAGE_PREFIX = APP_PACKAGE_DOMAIN + '\';
var
  Name: String;
  MakePackageSid: Boolean;
  Entry: TAppContainerEntry;
begin
  Result := False;
  Name := StringSid;

  // We accept all AppContainer names but only valid package family names
  if RtlxPrefixStripString(APP_CONTAINER_PREFIX, Name) then
    MakePackageSid := False
  else if RtlxPrefixStripString(APP_PACKAGE_PREFIX, Name) and
    PkgxIsValidFamilyName(Name) then
    MakePackageSid := True
  else
    Exit;

  // Derive the SID and remember the result
  Result := RtlxDeriveAndRememberAppContainer(Name, Entry).IsSuccess;

  if not Result then
    Exit;

  if MakePackageSid then
  begin
    // Make a copy of the SID before modifying it
    Result := RtlxCopySid(Entry.Sid.Data, Sid).IsSuccess;

    if not Result then
      Exit;

    // Package SIDs use the same algorithm, but a different sub authority
    RtlSubAuthoritySid(Sid.Data, 0)^ := SECURITY_CAPABILITY_BASE_RID;
  end
  else
    Sid := Entry.Sid;
end;

function RtlxProvideAppContainerSIDs(
  const Sid: ISid;
  out SidType: TSidNameUse;
  out SidDomain: String;
  out SidUser: String
): Boolean;
var
  Index: Integer;
  SidCopy: ISid;
begin
  Result := False;
  SidType := SidTypeWellKnownGroup;

  if RtlxIdentifierAuthoritySid(Sid) <> SECURITY_APP_PACKAGE_AUTHORITY then
    Exit;

  if (RtlxSubAuthorityCountSid(Sid) in
    [SECURITY_PARENT_PACKAGE_RID_COUNT, SECURITY_CHILD_PACKAGE_RID_COUNT])
    and (RtlxSubAuthoritySid(Sid, 0) = SECURITY_APP_PACKAGE_BASE_RID) then
  begin
    // Use AppContainer SIDs as is
    SidDomain := APP_CONTAINER_DOMAIN;
    SidCopy := Sid;
  end
  else if (RtlxSubAuthorityCountSid(Sid) = SECURITY_APP_PACKAGE_RID_COUNT) and
    (RtlxSubAuthoritySid(Sid, 0) = SECURITY_CAPABILITY_BASE_RID) then
  begin
    SidDomain := APP_PACKAGE_DOMAIN;

    // Duplicate Package SIDs to adjust the structure
    Result := RtlxCopySid(Sid.Data, SidCopy).IsSuccess;

    if not Result then
      Exit;

    // Swap the root sub-authority to match the cache structure
    RtlSubAuthoritySid(SidCopy.Data, 0)^ := SECURITY_APP_PACKAGE_BASE_RID;
  end
  else
    Exit;

  // Find the matching SID
  Index := TArray.BinarySearchEx<TAppContainerEntry>(AppContainers,
    function (const Entry: TAppContainerEntry): Integer
    begin
      Result := RtlxCompareSids(Entry.Sid, SidCopy);
    end
  );

  Result := Index >= 0;

  if Result then
    SidUser := AppContainers[Index].Name;
end;

function RtlxEnumerateRememberedAppContainers;
begin
  Result := TArray.Convert<TAppContainerEntry, String>(
    AppContainers,
    function (const Entry: TAppContainerEntry; out Name: String): Boolean
    begin
      Result :=
        ((afParentAppContainer in Filter) and not Entry.IsChild) or
        ((afChildAppContainer in Filter) and Entry.IsChild) or
        ((afPackage in Filter) and Entry.IsPackage)
      ;

      if not Result then
        Exit;

      if AddPrefix <> '' then
        Name := AddPrefix + Entry.Name
      else
        Name := Entry.Name;
    end
  );
end;

initialization
  if RtlOsVersionAtLeast(OsWin8) then
  begin
    RtlxRegisterSidNameRecognizer(RtlxRecognizeAppContainerSIDs);
    RtlxRegisterSidNameProvider(RtlxProvideAppContainerSIDs);
  end;
end.
