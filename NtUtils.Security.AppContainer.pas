unit NtUtils.Security.AppContainer;

{
  This module includes routines for working with AppContainer and capability
  SIDs.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.Versions, NtUtils;

{ Capabilities }

type
  TCapabilityType = (ctAppCapability, ctGroupCapability);

type
  TAppContainerInfo = record
    [opt] User: ISid;
    Sid: ISid;
    Moniker: String;
    DisplayName: String;
    IsChild: Boolean;
    ParentMoniker: String;
    function FullMoniker: String;
  end;

{ Capabilities }

// Convert a capability name to a SID
[MinOSVersion(OsWin10TH1)]
function RtlxDeriveCapabilitySid(
  out Sid: ISid;
  const Name: String;
  CapabilityType: TCapabilityType
): TNtxStatus;

// Convert a capability name to a pair of SIDs
[MinOSVersion(OsWin10TH1)]
function RtlxDeriveCapabilitySids(
  const Name: String;
  out CapGroupSid: ISid;
  out CapSid: ISid
): TNtxStatus;

{ AppContainer }

// Construct an AppContainer SID from a parent moniker
[MinOSVersion(OsWin8)]
function RtlxDeriveParentAppContainerSid(
  const ParentMoniker: String;
  out Sid: ISid
): TNtxStatus;

// Construct an AppContainer SID from a parent SID and child moniker
[MinOSVersion(OsWin81)]
function RtlxDeriveChildAppContainerSid(
  const ParentSid: ISid;
  const ChildMoniker: String;
  out ChildSid: ISid
): TNtxStatus;

// Construct an AppContainer SID from a full moniker
// (automatically selecting between parent/child)
[MinOSVersion(OsWin81)]
function RtlxDeriveFullAppContainerSid(
  const FullMoniker: String;
  out Sid: ISid;
  [out, opt] IsChild: PBoolean = nil
): TNtxStatus;

// Get type of an SID
function RtlxGetAppContainerType(
  const Sid: ISid
): TAppContainerSidType;

// Get a SID of a parent AppContainer
[MinOSVersion(OsWin81)]
function RtlxGetAppContainerParent(
  const AppContainerSid: ISid;
  out AppContainerParent: ISid
): TNtxStatus;

// Convert a SID to an AppContainer moniker via a mapping repository
[MinOSVersion(OsWin8)]
function RtlxQueryAppContainer(
  out Info: TAppContainerInfo;
  const Sid: ISid;
  [opt] User: ISid = nil;
  ResolveDisplayName: Boolean = True
): TNtxStatus;

// Collect known AppContainer SIDs from the mapping repository
[MinOSVersion(OsWin8)]
function RtlxEnumerateAppContainerSIDs(
  out Sids: TArray<ISid>;
  [opt] const ParentSid: ISid = nil;
  [opt] const User: ISid = nil
): TNtxStatus;

// Collect known AppContainer monikers from the storage repository
[MinOSVersion(OsWin8)]
function RtlxEnumerateAppContainerMonikers(
  out Monikers: TArray<String>;
  [opt] const ParentMoniker: String = '';
  [opt] const User: ISid = nil
): TNtxStatus;

{ AppPackage }

// Convert a Package Family name to a SID
[MinOSVersion(OsWin8)]
function RtlxDerivePackageFamilySid(
  const FamilyName: String;
  out Sid: ISid
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.UserEnv, Ntapi.ntstatus, Ntapi.WinError, Ntapi.ntseapi,
  Ntapi.ntregapi, NtUtils.Ldr, NtUtils.Security.Sid, NtUtils.Tokens,
  NtUtils.Tokens.Info, NtUtils.Registry, DelphiUtils.Arrays, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Capabilities }

function RtlxDeriveCapabilitySid;
var
  CapGroupSid: ISid;
  CapSid: ISid;
begin
  Result := RtlxDeriveCapabilitySids(Name, CapGroupSid, CapSid);

  if Result.IsSuccess then
    case CapabilityType of
      ctAppCapability:   Sid := CapSid;
      ctGroupCapability: Sid := CapGroupSid;
    else
      Result.Location := 'RtlxDeriveCapabilitySid';
      Result.Status := STATUS_INVALID_PARAMETER;
    end;
end;

function RtlxDeriveCapabilitySids;
begin
  Result := LdrxCheckDelayedImport(delayed_ntdll,
    delayed_RtlDeriveCapabilitySidsFromName);

  if not Result.IsSuccess then
    Exit;

  IMemory(CapGroupSid) := Auto.AllocateDynamic(RtlLengthRequiredSid(
    SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT));

  IMemory(CapSid) := Auto.AllocateDynamic(RtlLengthRequiredSid(
    SECURITY_INSTALLER_CAPABILITY_RID_COUNT));

  // Ask ntdll to hash the name into SIDs
  Result.Location := 'RtlDeriveCapabilitySidsFromName';
  Result.Status := RtlDeriveCapabilitySidsFromName(TNtUnicodeString.From(Name),
    CapGroupSid.Data, CapSid.Data);

  if not Result.IsSuccess then
    Exit;

  // Older OS versions are not aware of silo capabilities; fix it here
  if RtlxPrefixString('isolatedWin32-', Name) then
    CapSid.Data.SubAuthority[1] := SECURITY_CAPABILITY_APP_SILO_RID;
end;

{ AppContainer }

function RtlxDeriveParentAppContainerSid;
var
  Buffer: PSid;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_kernelbase,
    delayed_AppContainerDeriveSidFromMoniker);

  if not Result.IsSuccess then
    Exit;

  // Ask kernelbase to hash the moniker
  Result.Location := 'AppContainerDeriveSidFromMoniker';
  Result.HResult := AppContainerDeriveSidFromMoniker(PWideChar(ParentMoniker),
    Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := RtlxDelayFreeSid(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
end;

function RtlxDeriveChildAppContainerSid;
var
  PseudoChildSid: ISid;
begin
  // Partially reproducing
  // DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName

  // Construct a temporary SID using the child moniker as a parent moniker
  Result := RtlxDeriveParentAppContainerSid(ChildMoniker, PseudoChildSid);

  if not Result.IsSuccess then
    Exit;

  // Make a child SID by combining 8 parent and 4 child sub-authorities
  Result := RtlxCreateSid(ChildSid, SECURITY_APP_PACKAGE_AUTHORITY,
    RtlxSubAuthoritiesSid(ParentSid) +
    Copy(RtlxSubAuthoritiesSid(PseudoChildSid), 4, 4)
  );
end;

function RtlxDeriveFullAppContainerSid;
var
  ParentMoniker, ChildMoniker: String;
  ParentSid: ISid;
begin
  if RtlxSplitPath(FullMoniker, ParentMoniker, ChildMoniker) then
  begin
    // Construct parent SID first
    Result := RtlxDeriveParentAppContainerSid(ParentMoniker, ParentSid);

    if not Result.IsSuccess then
      Exit;

    // Construct a child under it
    Result := RtlxDeriveChildAppContainerSid(ParentSid, ChildMoniker, Sid);

    if Assigned(IsChild) then
      IsChild^ := True;
  end
  else
  begin
    // Juts parent
    Result := RtlxDeriveParentAppContainerSid(FullMoniker, Sid);

    if Assigned(IsChild) then
      IsChild^ := False;
  end;
end;

function RtlxGetAppContainerType;
begin
  // Reproduce RtlGetAppContainerSidType

  if RtlxIdentifierAuthoritySid(Sid) <> SECURITY_APP_PACKAGE_AUTHORITY then
    Exit(NotAppContainerSidType);

  if (RtlxSubAuthorityCountSid(Sid) < SECURITY_BUILTIN_APP_PACKAGE_RID_COUNT)
    or (RtlxSubAuthoritySid(Sid, 0) <> SECURITY_APP_PACKAGE_BASE_RID) then
    Exit(InvalidAppContainerSidType);

  case RtlxSubAuthorityCountSid(Sid) of
    SECURITY_PARENT_PACKAGE_RID_COUNT:
      Result := ParentAppContainerSidType;

    SECURITY_CHILD_PACKAGE_RID_COUNT:
      Result := ChildAppContainerSidType;
  else
    Result := InvalidAppContainerSidType;
  end;
end;

function RtlxGetAppContainerParent;
var
  Buffer: PSid;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_ntdll,
    delayed_RtlGetAppContainerParent);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlGetAppContainerParent';
  Result.Status := RtlGetAppContainerParent(AppContainerSid.Data, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := RtlxDelayFreeSid(Buffer);
  Result := RtlxCopySid(Buffer, AppContainerParent);
end;

{ AppContainer information }

function TAppContainerInfo.FullMoniker;
begin
  if IsChild then
    Result := ParentMoniker + '\' + Moniker
  else
    Result := Moniker;
end;

const
  // Definitions for the AppContainer repository in the registry
  APPCONTAINER_REPOSITORY = '\Software\Classes\Local Settings\Software\' +
    'Microsoft\Windows\CurrentVersion\AppContainer';
  APPCONTAINER_MAPPINGS = '\Mappings';
  APPCONTAINER_STORAGE = '\Storage';
  APPCONTAINER_MONIKER = 'Moniker';
  APPCONTAINER_PARENT_MONIKER = 'ParentMoniker';
  APPCONTAINER_DISPLAY_NAME = 'DisplayName';
  APPCONTAINER_CHILDREN = 'Children';

type
  TAppContainerRepositorySection = (
    arMappings,
    arStorage
  );

function RtlxEnsureUserSelected(
  var User: ISid
): TNtxStatus;
begin
  // Use the effective user by default
  if not Assigned(User) then
    Result := NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, User)
  else
    Result.Status := STATUS_SUCCESS;
end;

function RtlxOpenAppContainerRepository(
  out hxKey: IHandle;
  [opt] User: ISid;
  RepositorySection: TAppContainerRepositorySection;
  [opt] const Parent: String;
  OpenChildDirectory: Boolean;
  [opt] const Child: String;
  Access: TRegKeyAccessMask
): TNtxStatus;
var
  Path: String;
begin
  // Use the effective user profile if not specified
  Result := RtlxEnsureUserSelected(User);

  if not Result.IsSuccess then
    Exit;

  // Repository root
  Path := REG_PATH_USER + '\' + RtlxSidToString(User) + APPCONTAINER_REPOSITORY;

  // Repository section
  if RepositorySection = arStorage then
    Path := Path + APPCONTAINER_STORAGE
  else
    Path := Path + APPCONTAINER_MAPPINGS;

  // Parent AppContainer mapping/storage
  if Parent <> '' then
    Path := Path + '\' + Parent;

  if OpenChildDirectory then
  begin
    // Parent AppContainer children
    Path := Path + '\' + APPCONTAINER_CHILDREN;

    // Child AppContainer mapping
    if Child <> '' then
      Path := Path + '\' + Child;
  end;

  // Open the repository key
  Result := NtxOpenKey(hxKey, Path, Access);

  // Retry with backup intent if necessary
  if Result.Status = STATUS_ACCESS_DENIED then
    Result := NtxOpenKey(hxKey, Path, Access, REG_OPTION_BACKUP_RESTORE);
end;

function RtlxVerifyAppContainerMoniker(
  const Info: TAppContainerInfo
): TNtxStatus;
var
  ParentSid, DerivedSid: ISid;
begin
  // Construst the SID from the moniker
  if Info.IsChild then
  begin
    Result := RtlxDeriveParentAppContainerSid(Info.ParentMoniker, ParentSid);

    if not Result.IsSuccess then
      Exit;

    Result := RtlxDeriveChildAppContainerSid(ParentSid, Info.Moniker,
      DerivedSid)
  end
  else
    Result := RtlxDeriveParentAppContainerSid(Info.Moniker, DerivedSid);

  if not Result.IsSuccess then
    Exit;

  // The stored SID must match the derived one
  if not RtlxEqualSids(Info.Sid, DerivedSid) then
  begin
    Result.Location := 'RtlxVerifyAppContainerMoniker';
    Result.Win32Error := APPMODEL_ERROR_PACKAGE_IDENTITY_CORRUPT;
  end;
end;

function RtlxQueryAppContainer;
var
  hxKey: IHandle;
  AppContainerType: TAppContainerSidType;
  ParentSid: ISid;
begin
  Info := Default(TAppContainerInfo);
  Info.Sid := Sid;

  // Use the effective user if not specified
  Result := RtlxEnsureUserSelected(User);

  if not Result.IsSuccess then
    Exit;

  Info.User := User;

  // Partially reproduce AppContainerLookupMoniker by reading the AppContainer
  // repository from HKU\<user-SID>\...\<parent-SID>\Children\<child-SID>

  // Determine SID type
  AppContainerType := RtlxGetAppContainerType(Sid);

  if not (AppContainerType in [ParentAppContainerSidType,
    ChildAppContainerSidType]) then
  begin
    Result.Location := 'RtlxQueryAppContainer';
    Result.Status := STATUS_NOT_APPCONTAINER;
    Exit;
  end;

  Info.IsChild := AppContainerType = ChildAppContainerSidType;

  if Info.IsChild then
  begin
    // Child repository is nested in the parent's repository
    Result := RtlxGetAppContainerParent(Sid, ParentSid);

    if not Result.IsSuccess then
      Exit;

    // Open the mapping of the child SID
    Result := RtlxOpenAppContainerRepository(hxKey, User, arMappings,
      RtlxSidToString(ParentSid), True, RtlxSidToString(Sid), KEY_QUERY_VALUE);
  end
  else
  begin
    // Open the mapping of the SID as a parent
    Result := RtlxOpenAppContainerRepository(hxKey, User, arMappings,
      RtlxSidToString(Sid), False, '', KEY_QUERY_VALUE);
  end;

  if not Result.IsSuccess then
    Exit;

  // Read the moniker
  Result := NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_MONIKER,
    Info.Moniker);

  if not Result.IsSuccess then
    Exit;

  // Read the display name (optional)
  if ResolveDisplayName then
    NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_DISPLAY_NAME,
      Info.DisplayName);

  if Info.IsChild then
  begin
    // Read the parent moniker
    Result := NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_PARENT_MONIKER,
      Info.ParentMoniker);

    if not Result.IsSuccess then
      Exit;
  end;

  // Verify that the moniker corresponds to the SID
  Result := RtlxVerifyAppContainerMoniker(Info);
end;

function RtlxEnumerateAppContainerSIDs;
var
  hxKey: IHandle;
  SubKeys: TArray<String>;
  ParentSddl: String;
  ExpectedType: TAppContainerSidType;
begin
  if Assigned(ParentSid) then
  begin
    ParentSddl := RtlxSidToString(ParentSid);
    ExpectedType := ChildAppContainerSidType;
  end
  else
  begin
    ParentSddl := '';
    ExpectedType := ParentAppContainerSidType;
  end;

  // Open the AppContainer mapping repository
  Result := RtlxOpenAppContainerRepository(hxKey, User, arMappings,
    ParentSddl, Assigned(ParentSid), '', KEY_ENUMERATE_SUB_KEYS);

  if not Result.IsSuccess then
    Exit;

  // Sub key names are AppContainer SIDs
  Result := NtxEnumerateSubKeys(hxKey.Handle, SubKeys);

  if not Result.IsSuccess then
    Exit;

  // Filter and convert
  SIDs := TArray.Convert<String, ISid>(SubKeys,
    function (
      const SDDL: String;
      out Sid: ISid
    ): Boolean
    begin
      Result := RtlxStringToSidConverter(SDDL, Sid) and
        (RtlxGetAppContainerType(Sid) = ExpectedType);
    end
  );
end;

function RtlxEnumerateAppContainerMonikers;
var
  hxKey: IHandle;
begin
  // Open the AppContainer storage repository
  Result := RtlxOpenAppContainerRepository(hxKey, User, arStorage,
    ParentMoniker, ParentMoniker <> '', '', KEY_ENUMERATE_SUB_KEYS);

  if not Result.IsSuccess then
    Exit;

  // Key names are AppContainer monikers
  Result := NtxEnumerateSubKeys(hxKey.Handle, Monikers);
end;

{ Packages }

function RtlxDerivePackageFamilySid;
begin
  // Package SIDs use the same algorithm as parent AppContainer SIDs but belong
  // to a different sub-authority.

  Result := RtlxDeriveParentAppContainerSid(FamilyName, Sid);

  if Result.IsSuccess then
    RtlSubAuthoritySid(Sid.Data, 0)^ := SECURITY_CAPABILITY_BASE_RID;
end;

end.
