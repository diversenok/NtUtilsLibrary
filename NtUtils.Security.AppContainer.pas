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

// Convert an AppContainer moniker to a SID
[MinOSVersion(OsWin8)]
function RtlxDeriveAppContainerSid(
  const Moniker: String;
  out Sid: ISid
): TNtxStatus;

// Make a child AppContainer SID based on a pair of monikers
[MinOSVersion(OsWin81)]
function RtlxDeriveChildAppContainerSid(
  const ParentMoniker: String;
  const ChildMoniker: String;
  out ChildSid: ISid
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
  [opt] const User: ISid = nil;
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

implementation

uses
  Ntapi.ntdef, Ntapi.UserEnv, Ntapi.ntstatus, Ntapi.WinError, Ntapi.ntseapi,
  Ntapi.ntregapi, NtUtils.Ldr, NtUtils.Security.Sid, NtUtils.Tokens,
  NtUtils.Tokens.Info, NtUtils.Registry, DelphiUtils.Arrays;

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
end;

{ AppContainer }

function RtlxDeriveAppContainerSid;
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
  Result.HResult := AppContainerDeriveSidFromMoniker(PWideChar(Moniker),
    Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := RtlxDelayFreeSid(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
end;

function RtlxDeriveChildAppContainerSid;
var
  ParentSid, PseudoChildSid: ISid;
begin
  // Partially reproducing
  // DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName

  // Construct the parent SID
  Result := RtlxDeriveAppContainerSid(ParentMoniker, ParentSid);

  if not Result.IsSuccess then
    Exit;

  // Construct a temporary SID using the child moniker as a parent moniker
  Result := RtlxDeriveAppContainerSid(ChildMoniker, PseudoChildSid);

  if not Result.IsSuccess then
    Exit;

  // Make a child SID by combining 8 parent and 4 child sub-authorities
  Result := RtlxCreateSid(ChildSid, SECURITY_APP_PACKAGE_AUTHORITY,
    RtlxSubAuthoritiesSid(ParentSid) +
    Copy(RtlxSubAuthoritiesSid(PseudoChildSid), 4, 4)
  );
end;

function RtlxGetAppContainerType;
begin
  // Reproduce RtlGetAppContainerSidType

  if RtlxIdentifierAuthoritySid(Sid) <> SECURITY_APP_PACKAGE_AUTHORITY then
    Exit(NotAppContainerSidType);

  if (RtlxSubAuthorityCountSid(Sid) < SECURITY_BUILTIN_APP_PACKAGE_RID_COUNT)
    or (RtlSubAuthoritySid(Sid.Data, 0)^ <> SECURITY_APP_PACKAGE_BASE_RID) then
    Exit(InvalidAppContainerSidType);

  case RtlxSubAuthorityCountSid(Sid) of
    SECURITY_APP_PACKAGE_RID_COUNT:
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
  if not Assigned(User) then
  begin
    // Use effective user by default
    Result := NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, User);

    if not Result.IsSuccess then
      Exit;
  end;

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
  DerivedSid: ISid;
begin
  // Construst the SID from the moniker
  if Info.IsChild then
    Result := RtlxDeriveChildAppContainerSid(Info.ParentMoniker, Info.Moniker,
      DerivedSid)
  else
    Result := RtlxDeriveAppContainerSid(Info.Moniker, DerivedSid);

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

end.
