unit NtUtils.Sam;

{
  This module provides functions for interacting with Security Account Manager.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntsam, Ntapi.ntseapi, NtUtils,
  DelphiUtils.AutoObjects;

type
  ISamHandle = NtUtils.IHandle;

  TRidAndName = record
    RelativeID: Cardinal;
    Name: String;
  end;

  TRidAndUse = record
    RelativeID: Cardinal;
    NameUse: TSidNameUse;
  end;

  TSidAndUse = record
    SID: ISid;
    NameUse: TSidNameUse;
  end;

  TNameAndUse = record
    Name: String;
    NameUse: TSidNameUse;
  end;

  TGroupMembership = Ntapi.ntsam.TGroupMembership;

  TSamxLocalizableAccount = record
    Rid: Cardinal;
    NameUse: TSidNameUse;
    Name: String;
    AdminComment: String;
  end;

// Connect to Security Account Manager
function SamxConnect(
  out hxServer: ISamHandle;
  DesiredAccess: TSamAccessMask;
  [opt] const ServerName: String = ''
): TNtxStatus;

// Subscribe for notifications about changes in SAM/LSA; requires SYSTEM
function SamxNotifyChanges(
  ObjectType: TSecurityDbObjectType;
  const hxEvent: IHandle;
  out Registration: IAutoReleasable
): TNtxStatus;

{ --------------------------------- Domains -------------------------------- }

// Enumerate domains on a server
function SamxEnumerateDomains(
  out Names: TArray<String>;
  [opt, Access(SAM_SERVER_ENUMERATE_DOMAINS)] hxServer: ISamHandle = nil
): TNtxStatus;

// Lookup a domain by name
function SamxLookupDomain(
  const Name: String;
  out DomainSid: ISid;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] hxServer: ISamHandle = nil
): TNtxStatus;

// Open a domain by SID
function SamxOpenDomain(
  out hxDomain: ISamHandle;
  const DomainId: ISid;
  DesiredAccess: TDomainAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] hxServer: ISamHandle = nil
): TNtxStatus;

// Open a domain by name
function SamxOpenDomainByName(
  out hxDomain: ISamHandle;
  const Name: String;
  DesiredAccess: TDomainAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] hxServer: ISamHandle = nil
): TNtxStatus;

// Open a domain by an SID of an account within this domain
function SamxOpenParentDomain(
  out hxDomain: ISamHandle;
  const Sid: ISid;
  DesiredAccess: TDomainAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] const hxServer: ISamHandle = nil
): TNtxStatus;

// Query domain information
function SamxQueryDomain(
  [Access(DOMAIN_READ_OTHER_PARAMETERS or
    DOMAIN_READ_PASSWORD_PARAMETERS)] const hxDomain: ISamHandle;
  InfoClass: TDomainInformationClass;
  out xBuffer: IAutoPointer
): TNtxStatus;

// Set domain information
function SamxSetDomain(
  [Access(DOMAIN_WRITE_OTHER_PARAMETERS or
    DOMAIN_WRITE_PASSWORD_PARAMS)] const hxDomain: ISamHandle;
  InfoClass: TDomainInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

type
  SamxDomain = class abstract
    // Query fixed-size domain information
    class function Query<T>(
      [Access(DOMAIN_READ_OTHER_PARAMETERS or
        DOMAIN_READ_PASSWORD_PARAMETERS)] const hxDomain: ISamHandle;
      InfoClass: TDomainInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size domain information
    class function &Set<T>(
      [Access(DOMAIN_WRITE_OTHER_PARAMETERS or
        DOMAIN_WRITE_PASSWORD_PARAMS)] const hxDomain: ISamHandle;
      InfoClass: TDomainInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Query display information for accounts in a domain.
// The output contains an array of structures defined by the info class
// (i.e. IMemory<^TAnysizeArray<TDomainDisplayUser>> for DomainDisplayUser)
function SamxQueryDisplayDomain(
  [Access(DOMAIN_LIST_ACCOUNTS)] const hxDomain: ISamHandle;
  InfoClass: TDomainDisplayInformation;
  out xMemory: IMemory;
  out ReturnedEntryCount: Integer;
  StartIndex: Cardinal = 0;
  EntryCount: Cardinal = MAX_UINT;
  [out, opt] pTotalAvailable: PCardinal = nil
): TNtxStatus;

// Find an index of an account for use with SamxQueryDisplayDomain
function SamxGetDisplayIndex(
  [Access(DOMAIN_LIST_ACCOUNTS)] const hxDomain: ISamHandle;
  DisplayInformation: TDomainDisplayInformation;
  const Prefix: String;
  out Index: Cardinal
): TNtxStatus;

// Enumerate domain accounts that support localization
function SamxQueryLocalizableAccountsDomain(
  out Accounts: TArray<TSamxLocalizableAccount>;
  [Access(DOMAIN_READ_OTHER_PARAMETERS)] const hxDomain: ISamHandle;
  LanguageId: Cardinal = LANG_NEUTRAL
): TNtxStatus;

{ --------------------------------- Lookup --------------------------------- }

// Construct an SID with a specific RID within the same domain
function SamxRidToSid(
  [Access(0)] const hxAccountOrDomainHandle: ISamHandle;
  Rid: Cardinal;
  out Sid: ISid
): TNtxStatus;

// Construct multiple SIDs with a specific RIDs within the same domain
function SamxRidsToSids(
  [Access(0)] const hxAccountOrDomainHandle: ISamHandle;
  const Rids: TArray<Cardinal>;
  out Sids: TArray<ISid>
): TNtxStatus;

// Find an account by name and return its RID
function SamxNameToRid(
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  const Name: String;
  out Lookup: TRidAndUse
): TNtxStatus;

// Find many accounts by names and return their RIDs
function SamxNamesToRids(
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  const Names: TArray<String>;
  out Lookup: TArray<TRidAndUse>
): TNtxStatus;

// Find an account by name and return its SID
function SamxNameToSid(
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  const Name: String;
  out Lookup: TSidAndUse
): TNtxStatus;

// Find many accounts by names and return their SIDs
function SamxNamesToSids(
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  const Names: TArray<String>;
  out Lookup: TArray<TSidAndUse>
): TNtxStatus;

// Find an account by ID and return its name
function SamxRidToName(
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  RelativeId: Cardinal;
  out Lookup: TNameAndUse
): TNtxStatus;

// Find many accounts by IDs and return their names
function SamxRidsToNames(
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  RelativeIds: TArray<Cardinal>;
  out Lookup: TArray<TNameAndUse>
): TNtxStatus;

{ --------------------------------- Groups ---------------------------------- }

// Enumerate groups in a domain
function SamxEnumerateGroups(
  [Access(DOMAIN_LIST_ACCOUNTS)] const hxDomain: ISamHandle;
  out Groups: TArray<TRidAndName>
): TNtxStatus;

// Create a new group in a domain
function SamxCreateGroup(
  [Access(DOMAIN_CREATE_GROUP)] const hxDomain: ISamHandle;
  const Name: String;
  out hxGroup: ISamHandle;
  [out, opt] pRelativeId: PCardinal = nil;
  DesiredAccess: TGroupAccessMask = GROUP_ALL_ACCESS
): TNtxStatus;

// Open a group
function SamxOpenGroup(
  out hxGroup: ISamHandle;
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  GroupId: Cardinal;
  DesiredAccess: TGroupAccessMask
): TNtxStatus;

// Open a group by name
function SamxOpenGroupByName(
  out hxGroup: ISamHandle;
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  const Name: String;
  DesiredAccess: TGroupAccessMask
): TNtxStatus;

// Open a group by full name
function SamxOpenGroupByFullName(
  out hxGroup: ISamHandle;
  const DomainName: String;
  const GroupName: String;
  DesiredAccess: TGroupAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] const hxServer: ISamHandle = nil
): TNtxStatus;

// Open a group by a SID
function SamxOpenGroupBySid(
  out hxGroup: ISamHandle;
  const Sid: ISid;
  DesiredAccess: TGroupAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] const hxServer: ISamHandle = nil
): TNtxStatus;

// Enumerate group's members
function SamxEnumerateMembersGroup(
  [Access(GROUP_LIST_MEMBERS)] const hxGroup: ISamHandle;
  out Members: TArray<TGroupMembership>
): TNtxStatus;

// Add a member to a group
function SamxAddMemberGroup(
  [Access(GROUP_ADD_MEMBER)] const hxGroup: ISamHandle;
  MemberId: Cardinal;
  Attributes: TGroupAttributes
): TNtxStatus;

// Remove a member from a group
function SamxRemoveMemberGroup(
  [Access(GROUP_REMOVE_MEMBER)] const hxGroup: ISamHandle;
  MemberId: Cardinal
): TNtxStatus;

// Adjust attributes of a group member
function SamxSetAttributesGroup(
  [Access(GROUP_ADD_MEMBER)] const hxGroup: ISamHandle;
  MemberId: Cardinal;
  Attributes: TGroupAttributes
): TNtxStatus;

// Query group information
function SamxQueryGroup(
  [Access(GROUP_READ_INFORMATION)] const hxGroup: ISamHandle;
  InfoClass: TGroupInformationClass;
  out xBuffer: IAutoPointer
): TNtxStatus;

// Set group information
function SamxSetGroup(
  [Access(GROUP_WRITE_ACCOUNT)] const hxGroup: ISamHandle;
  InfoClass: TGroupInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

type
  SamxGroup = class abstract
    // Query fixed-size group information
    class function Query<T>(
      [Access(GROUP_READ_INFORMATION)] const hxGroup: ISamHandle;
      InfoClass: TGroupInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size group information
    class function &Set<T>(
      [Access(GROUP_WRITE_ACCOUNT)] const hxGroup: ISamHandle;
      InfoClass: TGroupInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Delete a group from a domain
function SamxDeleteGroup(
  [Access(_DELETE)] const hxGroup: ISamHandle
): TNtxStatus;

{ --------------------------------- Aliases --------------------------------- }

// Enumerate aliases in a domain
function SamxEnumerateAliases(
  [Access(DOMAIN_LIST_ACCOUNTS)] const hxDomain: ISamHandle;
  out Aliases: TArray<TRidAndName>
): TNtxStatus;

// Create a new alias in a domain
function SamxCreateAlias(
  [Access(DOMAIN_CREATE_ALIAS)] const hxDomain: ISamHandle;
  const Name: String;
  out hxAlias: ISamHandle;
  [out, opt] pRelativeId: PCardinal = nil;
  DesiredAccess: TAliasAccessMask = ALIAS_ALL_ACCESS
): TNtxStatus;

// Open an alias
function SamxOpenAlias(
  out hxAlias: ISamHandle;
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  AliasId: Cardinal;
  DesiredAccess: TAliasAccessMask
): TNtxStatus;

// Open an alias
function SamxOpenAliasByName(
  out hxAlias: ISamHandle;
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  const Name: String;
  DesiredAccess: TAliasAccessMask
): TNtxStatus;

// Open an alias by full name
function SamxOpenAliasByFullName(
  out hxAlias: ISamHandle;
  const DomainName: String;
  const AliasName: String;
  DesiredAccess: TAliasAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] const hxServer: ISamHandle = nil
): TNtxStatus;

// Open an alias by a SID
function SamxOpenAliasBySid(
  out hxAlias: ISamHandle;
  const Sid: ISid;
  DesiredAccess: TAliasAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] const hxServer: ISamHandle = nil
): TNtxStatus;

// Get alias members
function SamxEnumerateMembersAlias(
  [Access(ALIAS_LIST_MEMBERS)] const hxAlias: ISamHandle;
  out Members: TArray<ISid>
): TNtxStatus;

// Add a member to an alias
function SamxAddMemberAlias(
  [Access(ALIAS_ADD_MEMBER)] const hxAlias: ISamHandle;
  const MemberId: ISid
): TNtxStatus;

// Add multiple members to an alias
function SamxAddMembersAlias(
  [Access(ALIAS_ADD_MEMBER)] const hxAlias: ISamHandle;
  const MemberIds: TArray<ISid>
): TNtxStatus;

// Remove a member from an alias
function SamxRemoveMemberAlias(
  [Access(ALIAS_ADD_MEMBER)] const hxAlias: ISamHandle;
  const MemberId: ISid
): TNtxStatus;

// Remove multiple members from an alias
function SamxRemoveMembersAlias(
  [Access(ALIAS_ADD_MEMBER)] const hxAlias: ISamHandle;
  const MemberIds: TArray<ISid>
): TNtxStatus;

// Query alias information
function SamxQueryAlias(
  [Access(ALIAS_READ_INFORMATION)] const hxAlias: ISamHandle;
  InfoClass: TAliasInformationClass;
  out xBuffer: IAutoPointer
): TNtxStatus;

// Set alias information
function SamxSetAlias(
  [Access(ALIAS_WRITE_ACCOUNT)] const hxAlias: ISamHandle;
  InfoClass: TAliasInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

type
  SamxAlias = class abstract
    // Query fixed-size alias information
    class function Query<T>(
      [Access(ALIAS_READ_INFORMATION)] const hxAlias: ISamHandle;
      InfoClass: TAliasInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size alias information
    class function &Set<T>(
      [Access(ALIAS_WRITE_ACCOUNT)] const hxAlias: ISamHandle;
      InfoClass: TAliasInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Delete an alias from a domain
function SamxDeleteAlias(
  [Access(_DELETE)] const hxAlias: ISamHandle
): TNtxStatus;

// Find a union of all aliases in a domain that given SIDs are members of
function SamxGetAliasMembership(
  [Access(DOMAIN_GET_ALIAS_MEMBERSHIP)] const hxDomain: ISamHandle;
  const Sids: TArray<ISid>;
  out AliasIds: TArray<Cardinal>
): TNtxStatus;

// Remove an SID from all aliases in a domain
function SamxRemoveMemberFromForeignDomain(
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  const MemberId: ISid
): TNtxStatus;

{ ---------------------------------- Users ---------------------------------- }

// Enumerate users in domain
function SamxEnumerateUsers(
  [Access(DOMAIN_LIST_ACCOUNTS)] const hxDomain: ISamHandle;
  out Users: TArray<TRidAndName>;
  UserType: TUserAccountFlags = 0
): TNtxStatus;

// Create a new user in a domain
function SamxCreateUser(
  [Access(DOMAIN_CREATE_USER)] const hxDomain: ISamHandle;
  const Name: String;
  out hxUser: ISamHandle;
  [out, opt] pRelativeId: PCardinal = nil;
  AccountType: TUserAccountFlags = USER_NORMAL_ACCOUNT;
  DesiredAccess: TUserAccessMask = USER_ALL_ACCESS;
  [out, opt] pGrantedAccess: PUserAccessMask = nil
): TNtxStatus;

// Open a user
function SamxOpenUser(
  out hxUser: ISamHandle;
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  UserId: Cardinal;
  DesiredAccess: TUserAccessMask
): TNtxStatus;

// Open a user by name
function SamxOpenUserByName(
  out hxUser: ISamHandle;
  [Access(DOMAIN_LOOKUP)] const hxDomain: ISamHandle;
  const Name: String;
  DesiredAccess: TUserAccessMask
): TNtxStatus;

// Open a user by full name
function SamxOpenUserByFullName(
  out hxUser: ISamHandle;
  const DomainName: String;
  const UserName: String;
  DesiredAccess: TUserAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] const hxServer: ISamHandle = nil
): TNtxStatus;

// Open a user by a SID
function SamxOpenUserBySid(
  out hxUser: ISamHandle;
  const Sid: ISid;
  DesiredAccess: TUserAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] const hxServer: ISamHandle = nil
): TNtxStatus;

// Get groups for a user
function SamxEnumerateGroupsForUser(
  [Access(USER_LIST_GROUPS)] const hxUser: ISamHandle;
  out Groups: TArray<TGroupMembership>
): TNtxStatus;

// Query user information
function SamxQueryUser(
  [Access(USER_READ_GENERAL or USER_READ_PREFERENCES or
    USER_READ_LOGON or USER_READ_ACCOUNT)] const hxUser: ISamHandle;
  InfoClass: TUserInformationClass;
  out xBuffer: IAutoPointer
): TNtxStatus;

// Set user information
function SamxSetUser(
  [Access(USER_WRITE_ACCOUNT)] const hxUser: ISamHandle;
  InfoClass: TUserInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

type
  SamxUser = class abstract
    // Query fixed-size user information
    class function Query<T>(
      [Access(USER_READ_GENERAL or USER_READ_PREFERENCES or
        USER_READ_LOGON or USER_READ_ACCOUNT)] const hxUser: ISamHandle;
      InfoClass: TUserInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size user information
    class function &Set<T>(
      [Access(USER_WRITE_ACCOUNT)] const hxUser: ISamHandle;
      InfoClass: TUserInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Delete a user from a domain
function SamxDeleteUser(
  [Access(_DELETE)] const hxUser: ISamHandle
): TNtxStatus;

{ --------------------------------- Security ------------------------------- }

// Query security descriptor of a SAM object
function SamxQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] const SamHandle: ISamHandle;
  Info: TSecurityInformation;
  out SD: ISecurityDescriptor
): TNtxStatus;

// Set security descriptor on a SAM object
function SamxSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] const SamHandle: ISamHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntrtl, NtUtils.Security.Sid, NtUtils.Ldr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TSamAutoHandle = class(TCustomAutoHandle, ISamHandle, IAutoReleasable)
    procedure Release; override;
  end;

  TSamAutoPointer = class(TCustomAutoPointer, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

  TSamAutoMemory = class(TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

  TSamAutoNotification = class(TCustomAutoReleasable, IAutoReleasable)
    FType: TSecurityDbObjectType;
    FEvent: IHandle;
    procedure Release; override;
    constructor Create(
      OperationType: TSecurityDbObjectType;
      const hxEvent: IHandle
    );
  end;

{ Common & Server }

procedure TSamAutoHandle.Release;
begin
  if (FHandle <> 0) and LdrxCheckDelayedImport(
    delayed_SamCloseHandle).IsSuccess then
    SamCloseHandle(FHandle);

  FHandle := 0;
  inherited;
end;

procedure TSamAutoPointer.Release;
begin
  if Assigned(FData) and LdrxCheckDelayedImport(
    delayed_SamFreeMemory).IsSuccess then
    SamFreeMemory(FData);

  FData := nil;
  inherited;
end;

procedure TSamAutoMemory.Release;
begin
  if Assigned(FData) and LdrxCheckDelayedImport(
    delayed_SamFreeMemory).IsSuccess then
    SamFreeMemory(FData);

  FData := nil;
  inherited;
end;

constructor TSamAutoNotification.Create;
begin
  inherited Create;
  FEvent := hxEvent;
  FType := OperationType;
end;

procedure TSamAutoNotification.Release;
begin
  if Assigned(FEvent) and LdrxCheckDelayedImport(
    delayed_SamUnregisterObjectChangeNotification).IsSuccess then
    SamUnregisterObjectChangeNotification(FType, FEvent.Handle);

  FEvent := nil;
  inherited;
end;

function SamxDelayAutoFree(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      if LdrxCheckDelayedImport(
        delayed_SamFreeMemory).IsSuccess then
        SamFreeMemory(Buffer);
    end
  );
end;

function SamxConnect;
var
  ObjAttr: TObjectAttributes;
  ServerNameStr: TNtUnicodeString;
  hServer: TSamHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_SamConnect);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(ServerNameStr, ServerName);

  if not Result.IsSuccess then
    Exit;

  InitializeObjectAttributes(ObjAttr);

  Result.Location := 'SamConnect';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := SamConnect(ServerNameStr.RefOrNil, hServer, DesiredAccess,
    ObjAttr);

  if Result.IsSuccess then
    hxServer := TSamAutoHandle.Capture(hServer);
end;

function SamxpEnsureConnected(
  var hxServer: ISamHandle;
  DesiredAccess: TSamAccessMask
): TNtxStatus;
begin
  if not Assigned(hxServer) then
    Result := SamxConnect(hxServer, DesiredAccess)
  else
    Result := NtxSuccess;
end;

function SamxNotifyChanges;
begin
  Result := LdrxCheckDelayedImport(delayed_SamRegisterObjectChangeNotification);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamRegisterObjectChangeNotification';
  Result.Status := SamRegisterObjectChangeNotification(ObjectType,
    hxEvent.Handle);

  if Result.IsSuccess then
    Registration := TSamAutoNotification.Create(ObjectType, hxEvent);
end;

{ Domains }

function SamxEnumerateDomains;
var
  EnumContext: TSamEnumerationHandle;
  Buffer: PSamRidEnumerationArray;
  BufferDeallocator: IAutoReleasable;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamEnumerateDomainsInSamServer);

  if not Result.IsSuccess then
    Exit;

  Result := SamxpEnsureConnected(hxServer, SAM_SERVER_ENUMERATE_DOMAINS);

  if not Result.IsSuccess then
    Exit;

  EnumContext := 0;
  Result.Location := 'SamEnumerateDomainsInSamServer';
  Result.LastCall.Expects<TSamAccessMask>(SAM_SERVER_ENUMERATE_DOMAINS);

  Result.Status := SamEnumerateDomainsInSamServer(hxServer.Handle, EnumContext,
    Buffer, MAX_UINT, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  SetLength(Names, Count);

  // RelativeId is always zero for domains, but names are available
  for i := 0 to High(Names) do
    Names[i] := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name.ToString;
end;

function SamxLookupDomain;
var
  Buffer: PSid;
  BufferDeallocator: IAutoReleasable;
  NameStr: TNtUnicodeString;
begin
  Result := LdrxCheckDelayedImport(delayed_SamLookupDomainInSamServer);

  if not Result.IsSuccess then
    Exit;

  Result := SamxpEnsureConnected(hxServer, SAM_SERVER_LOOKUP_DOMAIN);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(NameStr, Name);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamLookupDomainInSamServer';
  Result.LastCall.Expects<TSamAccessMask>(SAM_SERVER_LOOKUP_DOMAIN);
  Result.Status := SamLookupDomainInSamServer(hxServer.Handle, NameStr, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  Result := RtlxCopySid(Buffer, DomainSid);
end;

function SamxOpenDomain;
var
  hDomain: TSamHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_SamOpenDomain);

  if not Result.IsSuccess then
    Exit;

  Result := SamxpEnsureConnected(hxServer, SAM_SERVER_LOOKUP_DOMAIN);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamOpenDomain';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TSamAccessMask>(SAM_SERVER_LOOKUP_DOMAIN);

  Result.Status := SamOpenDomain(hxServer.Handle, DesiredAccess, DomainId.Data,
    hDomain);

  if Result.IsSuccess then
    hxDomain := TSamAutoHandle.Capture(hDomain);
end;

function SamxOpenDomainByName;
var
  DomainSid: ISid;
begin
  Result := SamxpEnsureConnected(hxServer, SAM_SERVER_LOOKUP_DOMAIN);

  if not Result.IsSuccess then
    Exit;

  Result := SamxLookupDomain(Name, DomainSid, hxServer);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenDomain(hxDomain, DomainSid, DesiredAccess, hxServer);
end;

function SamxOpenParentDomain;
var
  ParentSid: ISid;
begin
  Result := RtlxMakeParentSid(ParentSid, SID);

  if Result.IsSuccess then
    Result := SamxOpenDomain(hxDomain, ParentSid, DOMAIN_LOOKUP, hxServer);
end;

function SamxQueryDomain;
var
  Buffer: Pointer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamQueryInformationDomain);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamQueryInformationDomain';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedDomainQueryAccess(InfoClass));
  Result.Status := SamQueryInformationDomain(HandleOrDefault(hxDomain),
    InfoClass, Buffer);

  if Result.IsSuccess then
    xBuffer := TSamAutoPointer.Capture(Buffer);
end;

function SamxSetDomain;
begin
  Result := LdrxCheckDelayedImport(delayed_SamSetInformationDomain);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamSetInformationDomain';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(ExpectedDomainSetAccess(InfoClass));
  Result.Status := SamSetInformationDomain(HandleOrDefault(hxDomain), InfoClass, Buffer);
end;

class function SamxDomain.Query<T>;
var
  xBuffer: IAutoPointer;
begin
  Result := SamxQueryDomain(hxDomain, InfoClass, xBuffer);

  if Result.IsSuccess then
    Buffer := T(xBuffer.Data^);
end;

class function SamxDomain.&Set<T>;
begin
  Result := SamxSetDomain(hxDomain, InfoClass, @Buffer);
end;

function SamxQueryDisplayDomain;
var
  TotalAvailable, TotalReturned: Cardinal;
  Buffer: Pointer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamQueryDisplayInformation);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamQueryDisplayInformation';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LIST_ACCOUNTS);
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  Result.Status := SamQueryDisplayInformation(HandleOrDefault(hxDomain),
    InfoClass, StartIndex, EntryCount, MAX_UINT, TotalAvailable, TotalReturned,
    Cardinal(ReturnedEntryCount), Buffer);

  if not Result.IsSuccess then
    Exit;

  xMemory := TSamAutoMemory.Capture(Buffer, TotalReturned);

  if Assigned(pTotalAvailable) then
    pTotalAvailable^ := TotalAvailable;
end;

function SamxGetDisplayIndex;
var
  PrefixStr: TNtUnicodeString;
begin
  Result := LdrxCheckDelayedImport(delayed_SamGetDisplayEnumerationIndex);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(PrefixStr, Prefix);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamGetDisplayEnumerationIndex';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LIST_ACCOUNTS);
  Result.Status := SamGetDisplayEnumerationIndex(HandleOrDefault(hxDomain),
    DisplayInformation, PrefixStr, Index);
end;

function SamxQueryLocalizableAccountsDomain;
var
  Buffer: PDomainLocalizableAccounts;
  BufferDeallocator: IAutoReleasable;
  Entry: PDomainLocalizableAccountsEntry;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamQueryLocalizableAccountsInDomain);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamQueryLocalizableAccountsInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_READ_OTHER_PARAMETERS);
  Result.LastCall.UsesInfoClass(DomainLocalizableAccountsBasic, icQuery);
  Result.Status := SamQueryLocalizableAccountsInDomain(
    HandleOrDefault(hxDomain), 0, LanguageId, DomainLocalizableAccountsBasic,
    Pointer(Buffer));

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  Entry := @Buffer.Entries[0];

  SetLength(Accounts, Buffer.Count);

  for i := 0 to High(Accounts) do
  begin
    Accounts[i].Rid := Entry.Rid;
    Accounts[i].NameUse := Entry.NameUse;
    Accounts[i].Name := Entry.Name.ToString;
    Accounts[i].AdminComment := Entry.AdminComment.ToString;
    Inc(Entry);
  end;
end;

{ Accounts }

function SamxRidToSid;
var
  Buffer: PSid;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_SamRidToSid);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamRidToSid';
  Result.Status := SamRidToSid(HandleOrDefault(hxAccountOrDomainHandle), Rid,
    Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
end;

function SamxRidsToSids;
var
  i: Integer;
  Sid0: ISid;
begin
  if Length(Rids) < 1 then
    Exit(NtxSuccess);

  // Ask SAM to convert the first entry
  Result := SamxRidToSid(hxAccountOrDomainHandle, Rids[0], Sid0);

  if not Result.IsSuccess then
    Exit;

  SetLength(Sids, Length(Rids));
  Sids[0] := Sid0;

  for i := 1 to High(Rids) do
  begin
    // Now that we know the desired domain, we can craft SIDs faster by hand
    Result := RtlxMakeSiblingSid(Sids[i], Sid0, Rids[i]);

    if not Result.IsSuccess then
      Break;
  end;
end;

function SamxNameToRid;
var
  MultiLookup: TArray<TRidAndUse>;
begin
  Result := SamxNamesToRids(hxDomain, [Name], MultiLookup);

  if Result.IsSuccess then
    Lookup := MultiLookup[0];
end;

function SamxNamesToRids;
var
  i: Integer;
  NtNames: TArray<TNtUnicodeString>;
  RelativeIDsBuffer: PCardinalArray;
  NameUseBuffer: PNameUseArray;
  RelativeIDsDeallocator, NameUseDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_SamLookupNamesInDomain);

  if not Result.IsSuccess then
    Exit;

  SetLength(NtNames, Length(Names));

  for i := 0 to High(Names) do
  begin
    Result := RtlxInitUnicodeString(NtNames[i], Names[i]);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'SamLookupNamesInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);
  Result.Status := SamLookupNamesInDomain(HandleOrDefault(hxDomain),
    Length(Names), NtNames, RelativeIDsBuffer, NameUseBuffer);

  if not Result.IsSuccess then
    Exit;

  RelativeIDsDeallocator := SamxDelayAutoFree(RelativeIDsBuffer);
  NameUseDeallocator := SamxDelayAutoFree(NameUseBuffer);
  SetLength(Lookup, Length(Names));

  for i := 0 to High(Lookup) do
  begin
    Lookup[i].RelativeID := RelativeIDsBuffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
    Lookup[i].NameUse := NameUseBuffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
  end;
end;

function SamxNameToSid;
var
  MultiLookup: TArray<TSidAndUse>;
begin
  Result := SamxNamesToSids(hxDomain, [Name], MultiLookup);

  if Result.IsSuccess then
    Lookup := MultiLookup[0];
end;

function SamxNamesToSids;
var
  i: Integer;
  NtNames: TArray<TNtUnicodeString>;
  SidsBuffer: PSidArray;
  NameUseBuffer: PNameUseArray;
  SidsDeallocator, NameUseDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_SamLookupNamesInDomain2);

  if not Result.IsSuccess then
    Exit;

  SetLength(NtNames, Length(Names));

  for i := 0 to High(Names) do
  begin
    Result := RtlxInitUnicodeString(NtNames[i], Names[i]);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'SamLookupNamesInDomain2';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);
  Result.Status := SamLookupNamesInDomain2(HandleOrDefault(hxDomain),
    Length(Names), NtNames, SidsBuffer, NameUseBuffer);

  if not Result.IsSuccess then
    Exit;

  SidsDeallocator := SamxDelayAutoFree(SidsBuffer);
  NameUseDeallocator := SamxDelayAutoFree(NameUseBuffer);
  SetLength(Lookup, Length(Names));

  for i := 0 to High(Lookup) do
  begin
    Lookup[i].NameUse := NameUseBuffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
    Result := RtlxCopySid(SidsBuffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF},
      Lookup[i].SID);

    if not Result.IsSuccess then
      Exit;
  end;
end;

function SamxRidToName;
var
  MultiLookup: TArray<TNameAndUse>;
begin
  Result := SamxRidsToNames(hxDomain, [RelativeId], MultiLookup);

  if Result.IsSuccess then
    Lookup := MultiLookup[0];
end;

function SamxRidsToNames;
var
  i: Integer;
  NamesBuffer: PNtUnicodeStringArray;
  NameUseBuffer: PNameUseArray;
  NamesDeallocator, NameUseDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_SamLookupIdsInDomain);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamLookupIdsInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);
  Result.Status := SamLookupIdsInDomain(HandleOrDefault(hxDomain),
    Length(RelativeIds), RelativeIds, NamesBuffer, NameUseBuffer);

  if not Result.IsSuccess then
    Exit;

  NamesDeallocator := SamxDelayAutoFree(NamesBuffer);
  NameUseDeallocator := SamxDelayAutoFree(NameUseBuffer);

  SetLength(Lookup, Length(RelativeIds));

  for i := 0 to High(Lookup) do
  begin
    Lookup[i].Name := NamesBuffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.ToString;
    Lookup[i].NameUse := NameUseBuffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};

    if not Result.IsSuccess then
      Exit;
  end;
end;

{ Groups }

function SamxEnumerateGroups;
var
  EnumContext: TSamEnumerationHandle;
  Buffer: PSamRidEnumerationArray;
  BufferDeallocator: IAutoReleasable;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamEnumerateGroupsInDomain);

  if not Result.IsSuccess then
    Exit;

  EnumContext := 0;
  Result.Location := 'SamEnumerateGroupsInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LIST_ACCOUNTS);

  Result.Status := SamEnumerateGroupsInDomain(HandleOrDefault(hxDomain),
    EnumContext, Buffer, MAX_UINT, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  SetLength(Groups, Count);

  for i := 0 to High(Groups) do
  begin
    Groups[i].RelativeId := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.RelativeId;
    Groups[i].Name := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name.ToString;
  end;
end;

function SamxCreateGroup;
var
  hGroup: TSamHandle;
  RelativeId: Cardinal;
  NameStr: TNtUnicodeString;
begin
  Result := LdrxCheckDelayedImport(delayed_SamCreateGroupInDomain);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(NameStr, Name);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamCreateGroupInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_CREATE_GROUP);
  Result.Status := SamCreateGroupInDomain(HandleOrDefault(hxDomain), NameStr,
    DesiredAccess, hGroup, RelativeId);

  if not Result.IsSuccess then
    Exit;

  hxGroup := TSamAutoHandle.Capture(hGroup);

  if Assigned(pRelativeId) then
    pRelativeId^ := RelativeId;
end;

function SamxOpenGroup;
var
  hGroup: TSamHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_SamOpenGroup);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamOpenGroup';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenGroup(HandleOrDefault(hxDomain), DesiredAccess,
    GroupId, hGroup);

  if Result.IsSuccess then
    hxGroup := TSamAutoHandle.Capture(hGroup);
end;

function SamxOpenGroupByName;
var
  Lookup: TRidAndUse;
begin
  Result := SamxNameToRid(hxDomain, Name, Lookup);

  if Result.IsSuccess then
    Result := SamxOpenGroup(hxGroup, hxDomain, Lookup.RelativeID, DesiredAccess);
end;

function SamxOpenGroupByFullName;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenDomainByName(hxDomain, DomainName, DOMAIN_LOOKUP, hxServer);

  if Result.IsSuccess then
    Result := SamxOpenGroupByName(hxGroup, hxDomain, GroupName,
      DesiredAccess)
end;

function SamxOpenGroupBySid;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP, hxServer);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenGroup(hxGroup, hxDomain, RtlxRidSid(Sid),
    DesiredAccess);
end;

function SamxEnumerateMembersGroup;
var
  BufferIDs, BufferAttributes: PCardinalArray;
  IDsDeallocator, AttributesDeallocator: IAutoReleasable;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamGetMembersInGroup);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamGetMembersInGroup';
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_LIST_MEMBERS);

  Result.Status := SamGetMembersInGroup(HandleOrDefault(hxGroup), BufferIDs,
    BufferAttributes, Count);

  if not Result.IsSuccess then
    Exit;

  IDsDeallocator := SamxDelayAutoFree(BufferIDs);
  AttributesDeallocator := SamxDelayAutoFree(BufferAttributes);
  SetLength(Members, Count);

  for i := 0 to High(Members) do
  begin
    Members[i].RelativeId := BufferIDs{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
    Members[i].Attributes := BufferAttributes{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
  end;
end;

function SamxAddMemberGroup;
begin
  Result := LdrxCheckDelayedImport(delayed_SamAddMemberToGroup);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamAddMemberToGroup';
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_ADD_MEMBER);
  Result.Status := SamAddMemberToGroup(HandleOrDefault(hxGroup), MemberId,
    Attributes);
end;

function SamxRemoveMemberGroup;
begin
  Result := LdrxCheckDelayedImport(delayed_SamRemoveMemberFromGroup);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamRemoveMemberFromGroup';
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_REMOVE_MEMBER);
  Result.Status := SamRemoveMemberFromGroup(HandleOrDefault(hxGroup), MemberId);
end;

function SamxSetAttributesGroup;
begin
  Result := LdrxCheckDelayedImport(delayed_SamSetMemberAttributesOfGroup);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamSetMemberAttributesOfGroup';
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_ADD_MEMBER);
  Result.Status := SamSetMemberAttributesOfGroup(HandleOrDefault(hxGroup),
    MemberId, Attributes);
end;

function SamxQueryGroup;
var
  Buffer: Pointer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamQueryInformationGroup);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamQueryInformationGroup';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_READ_INFORMATION);

  Result.Status := SamQueryInformationGroup(HandleOrDefault(hxGroup), InfoClass,
    Buffer);

  if Result.IsSuccess then
    xBuffer := TSamAutoPointer.Capture(Buffer);
end;

function SamxSetGroup;
begin
  Result := LdrxCheckDelayedImport(delayed_SamSetInformationGroup);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamSetInformationGroup';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_WRITE_ACCOUNT);

  Result.Status := SamSetInformationGroup(HandleOrDefault(hxGroup), InfoClass,
    Buffer);
end;

class function SamxGroup.Query<T>;
var
  xBuffer: IAutoPointer;
begin
  Result := SamxQueryGroup(hxGroup, InfoClass, xBuffer);

  if Result.IsSuccess then
    Buffer := T(xBuffer.Data^);
end;

class function SamxGroup.&Set<T>;
begin
  Result := SamxSetGroup(hxGroup, InfoClass, @Buffer);
end;

function SamxDeleteGroup;
begin
  Result := LdrxCheckDelayedImport(delayed_SamDeleteGroup);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamDeleteGroup';
  Result.LastCall.Expects<TGroupAccessMask>(_DELETE);
  Result.Status := SamDeleteGroup(HandleOrDefault(hxGroup));
end;

{ Aliases }

function SamxEnumerateAliases;
var
  EnumContext: TSamEnumerationHandle;
  Buffer: PSamRidEnumerationArray;
  BufferDeallocator: IAutoReleasable;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamEnumerateAliasesInDomain);

  if not Result.IsSuccess then
    Exit;

  EnumContext := 0;
  Result.Location := 'SamEnumerateAliasesInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LIST_ACCOUNTS);

  Result.Status := SamEnumerateAliasesInDomain(HandleOrDefault(hxDomain),
    EnumContext, Buffer, MAX_UINT, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  SetLength(Aliases, Count);

  for i := 0 to High(Aliases) do
  begin
    Aliases[i].RelativeId := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.RelativeId;
    Aliases[i].Name := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name.ToString;
  end;
end;

function SamxCreateAlias;
var
  hAlias: TSamHandle;
  RelativeId: Cardinal;
  NameStr: TNtUnicodeString;
begin
  Result := LdrxCheckDelayedImport(delayed_SamCreateAliasInDomain);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(NameStr, Name);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamCreateAliasInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_CREATE_ALIAS);
  Result.Status := SamCreateAliasInDomain(HandleOrDefault(hxDomain), NameStr,
    DesiredAccess, hAlias, RelativeId);

  if not Result.IsSuccess then
    Exit;

  hxAlias := TSamAutoHandle.Capture(hAlias);

  if Assigned(pRelativeId) then
    pRelativeId^ := RelativeId;
end;

function SamxOpenAlias;
var
  hAlias: TSamHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_SamOpenAlias);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamOpenAlias';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenAlias(HandleOrDefault(hxDomain), DesiredAccess,
    AliasId, hAlias);

  if Result.IsSuccess then
    hxAlias := TSamAutoHandle.Capture(hAlias);
end;

function SamxOpenAliasByName;
var
  Lookup: TRidAndUse;
begin
  Result := SamxNameToRid(hxDomain, Name, Lookup);

  if Result.IsSuccess then
    Result := SamxOpenAlias(hxAlias, hxDomain, Lookup.RelativeID, DesiredAccess);
end;

function SamxOpenAliasByFullName;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenDomainByName(hxDomain, DomainName, DOMAIN_LOOKUP, hxServer);

  if Result.IsSuccess then
    Result := SamxOpenAliasByName(hxAlias, hxDomain, AliasName,
      DesiredAccess);
end;

function SamxOpenAliasBySid;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP, hxServer);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenAlias(hxAlias, hxDomain, RtlxRidSid(Sid),
    DesiredAccess);
end;

function SamxEnumerateMembersAlias;
var
  Buffer: PSidArray;
  BufferDeallocator: IAutoReleasable;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamGetMembersInAlias);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamGetMembersInAlias';
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_LIST_MEMBERS);

  Result.Status := SamGetMembersInAlias(HandleOrDefault(hxAlias), Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  SetLength(Members, Count);

  for i := 0 to High(Members) do
  begin
    Result := RtlxCopySid(Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}, Members[i]);

    if not Result.IsSuccess then
      Break;
  end;
end;

function SamxAddMemberAlias;
begin
  Result := LdrxCheckDelayedImport(delayed_SamAddMemberToAlias);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamAddMemberToAlias';
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_ADD_MEMBER);
  Result.Status := SamAddMemberToAlias(HandleOrDefault(hxAlias), MemberId.Data);
end;

function SamxAddMembersAlias;
var
  Members: TArray<PSid>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamAddMultipleMembersToAlias);

  if not Result.IsSuccess then
    Exit;

  SetLength(Members, Length(MemberIds));

  for i := 0 to High(MemberIds) do
    Members[i] := MemberIds[i].Data;

  Result.Location := 'SamAddMultipleMembersToAlias';
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_ADD_MEMBER);
  Result.Status := SamAddMultipleMembersToAlias(HandleOrDefault(hxAlias),
    Members, Length(Members));
end;

function SamxRemoveMemberAlias;
begin
  Result := LdrxCheckDelayedImport(delayed_SamRemoveMemberFromAlias);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamRemoveMemberFromAlias';
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_REMOVE_MEMBER);
  Result.Status := SamRemoveMemberFromAlias(HandleOrDefault(hxAlias),
    MemberId.Data);
end;

function SamxRemoveMembersAlias;
var
  Members: TArray<PSid>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamRemoveMultipleMembersFromAlias);

  if not Result.IsSuccess then
    Exit;

  SetLength(Members, Length(MemberIds));

  for i := 0 to High(MemberIds) do
    Members[i] := MemberIds[i].Data;

  Result.Location := 'SamRemoveMultipleMembersFromAlias';
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_REMOVE_MEMBER);
  Result.Status := SamRemoveMultipleMembersFromAlias(HandleOrDefault(hxAlias),
    Members, Length(Members));
end;

function SamxQueryAlias;
var
  Buffer: Pointer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamQueryInformationAlias);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamQueryInformationAlias';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_READ_INFORMATION);

  Result.Status := SamQueryInformationAlias(HandleOrDefault(hxAlias), InfoClass,
    Buffer);

  if Result.IsSuccess then
    xBuffer := TSamAutoPointer.Capture(Buffer);
end;

function SamxSetAlias;
begin
  Result := LdrxCheckDelayedImport(delayed_SamSetInformationAlias);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamSetInformationAlias';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_WRITE_ACCOUNT);
  Result.Status := SamSetInformationAlias(HandleOrDefault(hxAlias), InfoClass, Buffer);
end;

class function SamxAlias.Query<T>;
var
  xBuffer: IAutoPointer;
begin
  Result := SamxQueryAlias(hxAlias, InfoClass, xBuffer);

  if Result.IsSuccess then
    Buffer := T(xBuffer.Data^);
end;

class function SamxAlias.&Set<T>;
begin
  Result := SamxSetAlias(hxAlias, InfoClass, @Buffer);
end;

function SamxDeleteAlias;
begin
  Result := LdrxCheckDelayedImport(delayed_SamDeleteAlias);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamDeleteAlias';
  Result.LastCall.Expects<TAliasAccessMask>(_DELETE);
  Result.Status := SamDeleteAlias(HandleOrDefault(hxAlias));
end;

function SamxGetAliasMembership;
var
  SidData: TArray<PSid>;
  MembershipCount: Cardinal;
  Buffer: PCardinalArray;
  BufferDeallocator: IAutoReleasable;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamGetAliasMembership);

  if not Result.IsSuccess then
    Exit;

  SetLength(SidData, Length(Sids));

  for i := 0 to High(SidData) do
    SidData[i] := Sids[i].Data;

  Result.Location := 'SamGetAliasMembership';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_GET_ALIAS_MEMBERSHIP);
  Result.Status := SamGetAliasMembership(HandleOrDefault(hxDomain),
    Length(SidData), SidData, MembershipCount, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  SetLength(AliasIds, MembershipCount);

  for i := 0 to High(AliasIds) do
    AliasIds[i] := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

function SamxRemoveMemberFromForeignDomain;
begin
  Result := LdrxCheckDelayedImport(delayed_SamRemoveMemberFromForeignDomain);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamRemoveMemberFromForeignDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);
  Result.Status := SamRemoveMemberFromForeignDomain(HandleOrDefault(hxDomain),
    MemberId.Data);
end;

{ Users }

function SamxEnumerateUsers;
var
  EnumContext: TSamEnumerationHandle;
  Buffer: PSamRidEnumerationArray;
  BufferDeallocator: IAutoReleasable;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamEnumerateUsersInDomain);

  if not Result.IsSuccess then
    Exit;

  EnumContext := 0;
  Result.Location := 'SamEnumerateUsersInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LIST_ACCOUNTS);

  Result.Status := SamEnumerateUsersInDomain(HandleOrDefault(hxDomain),
    EnumContext, UserType, Buffer, MAX_UINT, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  SetLength(Users, Count);

  for i := 0 to High(Users) do
  begin
    Users[i].RelativeId := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.RelativeId;
    Users[i].Name := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name.ToString;
  end;
end;

function SamxCreateUser;
var
  hUser: TSamHandle;
  GrantedAccess: TUserAccessMask;
  RelativeId: Cardinal;
  NameStr: TNtUnicodeString;
begin
  Result := LdrxCheckDelayedImport(delayed_SamCreateUser2InDomain);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(NameStr, Name);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamCreateUser2InDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_CREATE_USER);
  Result.Status := SamCreateUser2InDomain(HandleOrDefault(hxDomain), NameStr,
    AccountType, DesiredAccess, hUser, GrantedAccess, RelativeId);

  if not Result.IsSuccess then
    Exit;

  hxUser := TSamAutoHandle.Capture(hUser);

  if Assigned(pGrantedAccess) then
    pGrantedAccess^ := GrantedAccess;

  if Assigned(pRelativeId) then
    pRelativeId^ := RelativeId;
end;

function SamxOpenUser;
var
  hUser: TSamHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_SamOpenUser);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamOpenUser';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenUser(HandleOrDefault(hxDomain), DesiredAccess, UserId,
    hUser);

  if Result.IsSuccess then
    hxUser := TSamAutoHandle.Capture(hUser);
end;

function SamxOpenUserByName;
var
  Lookup: TRidAndUse;
begin
  Result := SamxNameToRid(hxDomain, Name, Lookup);

  if Result.IsSuccess then
    Result := SamxOpenUser(hxUser, hxDomain, Lookup.RelativeID, DesiredAccess);
end;

function SamxOpenUserByFullName;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenDomainByName(hxDomain, DomainName, DOMAIN_LOOKUP, hxServer);

  if Result.IsSuccess then
    Result := SamxOpenUserByName(hxUser, hxDomain, UserName,
      DesiredAccess);
end;

function SamxOpenUserBySid;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP, hxServer);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenUser(hxUser, hxDomain, RtlxRidSid(Sid),
    DesiredAccess);
end;

function SamxEnumerateGroupsForUser;
var
  Buffer: PGroupMembershipArray;
  BufferDeallocator: IAutoReleasable;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamGetGroupsForUser);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamGetGroupsForUser';
  Result.LastCall.Expects<TUserAccessMask>(USER_LIST_GROUPS);

  Result.Status := SamGetGroupsForUser(HandleOrDefault(hxUser), Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := SamxDelayAutoFree(Buffer);
  SetLength(Groups, Count);

  for i := 0 to High(Groups) do
    Groups[i] := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

function SamxQueryUser;
var
  Buffer: Pointer;
begin
  Result := LdrxCheckDelayedImport(delayed_SamQueryInformationUser);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamQueryInformationUser';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedUserQueryAccess(InfoClass));

  Result.Status := SamQueryInformationUser(HandleOrDefault(hxUser), InfoClass,
    Buffer);

  if Result.IsSuccess then
    xBuffer := TSamAutoPointer.Capture(Buffer);
end;

function SamxSetUser;
begin
  Result := LdrxCheckDelayedImport(delayed_SamSetInformationUser);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamSetInformationUser';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(ExpectedUserSetAccess(InfoClass));
  Result.Status := SamSetInformationUser(HandleOrDefault(hxUser), InfoClass,
    Buffer);
end;

class function SamxUser.Query<T>;
var
  xBuffer: IAutoPointer;
begin
  Result := SamxQueryUser(hxUser, InfoClass, xBuffer);

  if Result.IsSuccess then
    Buffer := T(xBuffer.Data^);
end;

class function SamxUser.&Set<T>;
begin
  Result := SamxSetUser(hxUser, InfoClass, @Buffer);
end;

function SamxDeleteUser;
begin
  Result := LdrxCheckDelayedImport(delayed_SamDeleteUser);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamDeleteUser';
  Result.LastCall.Expects<TUserAccessMask>(_DELETE);
  Result.Status := SamDeleteUser(HandleOrDefault(hxUser));
end;

function SamxQuerySecurityObject;
var
  Buffer: PSecurityDescriptor;
begin
  Result := LdrxCheckDelayedImport(delayed_SamQuerySecurityObject);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamQuerySecurityObject';
  Result.LastCall.Expects(SecurityReadAccess(Info));
  Result.Status := SamQuerySecurityObject(HandleOrDefault(SamHandle), Info,
    Buffer);

  if Result.IsSuccess then
    IMemory(SD) := TSamAutoMemory.Capture(Buffer,
      RtlLengthSecurityDescriptor(Buffer));
end;

function SamxSetSecurityObject;
begin
  Result := LdrxCheckDelayedImport(delayed_SamSetSecurityObject);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamSetSecurityObject';
  Result.LastCall.Expects(SecurityWriteAccess(Info));
  Result.Status := SamSetSecurityObject(HandleOrDefault(SamHandle), Info, SD);
end;

end.
