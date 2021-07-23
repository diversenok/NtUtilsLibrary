unit NtUtils.Sam;

{
  This module provides functions for interacting with Security Account Manager.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntsam, NtUtils;

type
  TSamHandle = Ntapi.ntsam.TSamHandle;
  ISamHandle = NtUtils.IHandle;

  TRidAndName = record
    Name: String;
    RelativeID: Cardinal;
  end;

  TGroupMembership = Ntapi.ntsam.TGroupMembership;

// Connect to a SAM server
function SamxConnect(
  out hxServer: ISamHandle;
  DesiredAccess: TSamAccessMask;
  [opt] const ServerName: String = ''
): TNtxStatus;

{ --------------------------------- Domains -------------------------------- }

// Open a domain
function SamxOpenDomain(
  out hxDomain: ISamHandle;
  [in] DomainId: PSid;
  DesiredAccess: TDomainAccessMask;
  [opt, Access(SAM_SERVER_LOOKUP_DOMAIN)] hxServer: ISamHandle = nil
): TNtxStatus;

// Open the parent of the SID as a domain
function SamxOpenParentDomain(
  out hxDomain: ISamHandle;
  [in] Sid: PSid;
  DesiredAccess: TDomainAccessMask
): TNtxStatus;

// Lookup a domain
function SamxLookupDomain(
  [Access(SAM_SERVER_LOOKUP_DOMAIN)] hServer: TSamHandle;
  const Name: String;
  out DomainId: ISid
): TNtxStatus;

// Enumerate domains
function SamxEnumerateDomains(
  [Access(SAM_SERVER_ENUMERATE_DOMAINS)] hServer: TSamHandle;
  out Names: TArray<String>
): TNtxStatus;

// Query domain information
function SamxQueryDomain(
  [Access(DOMAIN_READ_OTHER_PARAMETERS or
    DOMAIN_READ_PASSWORD_PARAMETERS)] hDomain: TSamHandle;
  InfoClass: TDomainInformationClass;
  out xMemory: IMemory
): TNtxStatus;

// Set domain information
function SamxSetDomain(
  [Access(DOMAIN_WRITE_OTHER_PARAMETERS or
    DOMAIN_WRITE_PASSWORD_PARAMS)] hDomain: TSamHandle;
  InfoClass: TDomainInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

{ --------------------------------- Groups ---------------------------------- }

// Enumerate groups
function SamxEnumerateGroups(
  [Access(DOMAIN_LIST_ACCOUNTS)] hDomain: TSamHandle;
  out Groups: TArray<TRidAndName>
): TNtxStatus;

// Open a group
function SamxOpenGroup(
  out hxGroup: ISamHandle;
  [Access(DOMAIN_LOOKUP)] hDomain: TSamHandle;
  GroupId: Cardinal;
  DesiredAccess: TGroupAccessMask
): TNtxStatus;

// Open a group by SID
function SamxOpenGroupBySid(
  out hxGroup: ISamHandle;
  [in] Sid: PSid;
  DesiredAccess: TGroupAccessMask
): TNtxStatus;

// Get groups members
function SamxGetMembersGroup(
  [Access(GROUP_LIST_MEMBERS)] hGroup: TSamHandle;
  out Members: TArray<TGroupMembership>
): TNtxStatus;

// Query group information
function SamxQueryGroup(
  [Access(GROUP_READ_INFORMATION)] hGroup: TSamHandle;
  InfoClass: TGroupInformationClass;
  out xMemory: IMemory
): TNtxStatus;

// Set group information
function SamxSetGroup(
  [Access(GROUP_WRITE_ACCOUNT)] hGroup: TSamHandle;
  InfoClass: TGroupInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

{ --------------------------------- Aliases --------------------------------- }

// Enumerate aliases in domain
function SamxEnumerateAliases(
  [Access(DOMAIN_LIST_ACCOUNTS)] hDomain: TSamHandle;
  out Aliases: TArray<TRidAndName>
): TNtxStatus;

// Open an alias
function SamxOpenAlias(
  out hxAlias: ISamHandle;
  [Access(DOMAIN_LOOKUP)] hDomain: TSamHandle;
  AliasId: Cardinal;
  DesiredAccess: TAliasAccessMask
): TNtxStatus;

// Open an alias by SID
function SamxOpenAliasBySid(
  out hxAlias: ISamHandle;
  [in] Sid: PSid;
  DesiredAccess: TAliasAccessMask
): TNtxStatus;

// Get alias members
function SamxGetMembersAlias(
  [Access(ALIAS_LIST_MEMBERS)] hAlias: TSamHandle;
  out Members: TArray<ISid>
): TNtxStatus;

// Query alias information
function SamxQueryAlias(
  [Access(ALIAS_READ_INFORMATION)] hAlias: TSamHandle;
  InfoClass: TAliasInformationClass;
  out xMemory: IMemory
): TNtxStatus;

// Set alias information
function SamxSetAlias(
  [Access(ALIAS_WRITE_ACCOUNT)] hAlias: TSamHandle;
  InfoClass: TAliasInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

{ ---------------------------------- Users ---------------------------------- }

// Enumerate users in domain
function SamxEnumerateUsers(
  [Access(DOMAIN_LIST_ACCOUNTS)] hDomain: TSamHandle;
  UserType: Cardinal;
  out Users: TArray<TRidAndName>
): TNtxStatus;

// Open a user
function SamxOpenUser(
  out hxUser: ISamHandle;
  [Access(DOMAIN_LOOKUP)] hDomain: TSamHandle;
  UserId: Cardinal;
  DesiredAccess: TUserAccessMask
): TNtxStatus;

// Open a user by SID
function SamxOpenUserBySid(
  out hxUser: ISamHandle;
  [in] Sid: PSid;
  DesiredAccess: TUserAccessMask
): TNtxStatus;

// Get groups for a user
function SamxGetGroupsForUser(
  [Access(USER_LIST_GROUPS)] hUser: TSamHandle;
  out Groups: TArray<TGroupMembership>
): TNtxStatus;

// Query user information
function SamxQueryUser(
  [Access(USER_READ_GENERAL or USER_READ_PREFERENCES or
    USER_READ_LOGON or USER_READ_ACCOUNT)] hUser: TSamHandle;
  InfoClass: TUserInformationClass;
  out xMemory: IMemory
): TNtxStatus;

// Set user information
function SamxSetUser(
  [Access(USER_WRITE_ACCOUNT)] hUser: TSamHandle;
  InfoClass: TUserInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

{ -------------------------------- Security --------------------------------- }

// Query security descriptor of a SAM object
function SamxQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] SamHandle: TSamHandle;
  Info: TSecurityInformation;
  out SD: ISecDesc
): TNtxStatus;

// Set security descriptor on a SAM object
function SamxSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)]  SamHandle: TSamHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.Security.Sid, DelphiUtils.AutoObjects;

type
  TSamAutoHandle = class(TCustomAutoHandle, ISamHandle)
    procedure Release; override;
  end;

  TSamAutoMemory = class(TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

{ Common & Server }

procedure TSamAutoHandle.Release;
begin
  SamCloseHandle(FHandle);
  inherited;
end;

procedure TSamAutoMemory.Release;
begin
  SamFreeMemory(FData);
  inherited;
end;

function SamxConnect;
var
  ObjAttr: TObjectAttributes;
  hServer: TSamHandle;
begin
  InitializeObjectAttributes(ObjAttr);

  Result.Location := 'SamConnect';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := SamConnect(TNtUnicodeString.From(ServerName).RefOrNull,
    hServer, DesiredAccess, ObjAttr);

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
    Result.Status := STATUS_SUCCESS
end;

{ Domains }

function SamxOpenDomain;
var
  hDomain: TSamHandle;
begin
  Result := SamxpEnsureConnected(hxServer, SAM_SERVER_LOOKUP_DOMAIN);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamOpenDomain';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TSamAccessMask>(SAM_SERVER_LOOKUP_DOMAIN);

  Result.Status := SamOpenDomain(hxServer.Handle, DesiredAccess, DomainId,
    hDomain);

  if Result.IsSuccess then
    hxDomain := TSamAutoHandle.Capture(hDomain);
end;

function SamxOpenParentDomain;
var
  ParentSid: ISid;
begin
  Result := RtlxParentSid(ParentSid, SID);

  if Result.IsSuccess then
    Result := SamxOpenDomain(hxDomain, ParentSid.Data, DOMAIN_LOOKUP);
end;

function SamxLookupDomain;
var
  Buffer: PSid;
begin
  Result.Location := 'SamLookupDomainInSamServer';
  Result.LastCall.Expects<TSamAccessMask>(SAM_SERVER_LOOKUP_DOMAIN);

  Result.Status := SamLookupDomainInSamServer(hServer,
    TNtUnicodeString.From(Name), Buffer);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCopySid(Buffer, DomainId);
  SamFreeMemory(Buffer);
end;

function SamxEnumerateDomains;
var
  EnumContext: TSamEnumerationHandle;
  Buffer: PSamRidEnumerationArray;
  Count, i: Integer;
begin
  EnumContext := 0;
  Result.Location := 'SamEnumerateDomainsInSamServer';
  Result.LastCall.Expects<TSamAccessMask>(SAM_SERVER_ENUMERATE_DOMAINS);

  Result.Status := SamEnumerateDomainsInSamServer(hServer, EnumContext, Buffer,
    MAX_PREFERRED_LENGTH, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Names, Count);

  // RelativeId is always zero for domains, but names are available
  for i := 0 to High(Names) do
    Names[i] := Buffer{$R-}[i]{$R+}.Name.ToString;

  SamFreeMemory(Buffer);
end;

function SamxQueryDomain;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationDomain';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedDomainQueryAccess(InfoClass));

  Result.Status := SamQueryInformationDomain(hDomain, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetDomain;
begin
  Result.Location := 'SamSetInformationDomain';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(ExpectedDomainSetAccess(InfoClass));
  Result.Status := SamSetInformationDomain(hDomain, InfoClass, Buffer);
end;

{ Groups }

function SamxEnumerateGroups;
var
  EnumContext: TSamEnumerationHandle;
  Buffer: PSamRidEnumerationArray;
  Count, i: Integer;
begin
  EnumContext := 0;
  Result.Location := 'SamEnumerateGroupsInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LIST_ACCOUNTS);

  Result.Status := SamEnumerateGroupsInDomain(hDomain, EnumContext, Buffer,
    MAX_PREFERRED_LENGTH, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Groups, Count);

  for i := 0 to High(Groups) do
  begin
    Groups[i].RelativeId := Buffer{$R-}[i]{$R+}.RelativeId;
    Groups[i].Name := Buffer{$R-}[i]{$R+}.Name.ToString;
  end;

  SamFreeMemory(Buffer);
end;

function SamxOpenGroup;
var
  hGroup: TSamHandle;
begin
  Result.Location := 'SamOpenGroup';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenGroup(hDomain, DesiredAccess, GroupId, hGroup);

  if Result.IsSuccess then
    hxGroup := TSamAutoHandle.Capture(hGroup);
end;

function SamxOpenGroupBySid;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenGroup(hxGroup, hxDomain.Handle, RtlxRidSid(Sid),
    DesiredAccess);
end;

function SamxGetMembersGroup;
var
  BufferIDs, BufferAttributes: PCardinalArray;
  Count, i: Integer;
begin
  Result.Location := 'SamGetMembersInGroup';
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_LIST_MEMBERS);

  Result.Status := SamGetMembersInGroup(hGroup, BufferIDs, BufferAttributes,
    Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Members, Count);

  for i := 0 to High(Members) do
  begin
    Members[i].RelativeId := BufferIDs{$R-}[i]{$R+};
    Members[i].Attributes := BufferAttributes{$R-}[i]{$R+};
  end;

  SamFreeMemory(BufferIDs);
  SamFreeMemory(BufferAttributes);
end;

function SamxQueryGroup;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationGroup';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_READ_INFORMATION);

  Result.Status := SamQueryInformationGroup(hGroup, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetGroup;
begin
  Result.Location := 'SamSetInformationGroup';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_WRITE_ACCOUNT);

  Result.Status := SamSetInformationGroup(hGroup, InfoClass, Buffer);
end;

{ Aliases }

function SamxEnumerateAliases;
var
  EnumContext: TSamEnumerationHandle;
  Buffer: PSamRidEnumerationArray;
  Count, i: Integer;
begin
  EnumContext := 0;
  Result.Location := 'SamEnumerateAliasesInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LIST_ACCOUNTS);

  Result.Status := SamEnumerateAliasesInDomain(hDomain, EnumContext,
    Buffer, MAX_PREFERRED_LENGTH, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Aliases, Count);

  for i := 0 to High(Aliases) do
  begin
    Aliases[i].RelativeId := Buffer{$R-}[i]{$R+}.RelativeId;
    Aliases[i].Name := Buffer{$R-}[i]{$R+}.Name.ToString;
  end;

  SamFreeMemory(Buffer);
end;

function SamxOpenAlias;
var
  hAlias: TSamHandle;
begin
  Result.Location := 'SamOpenAlias';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenAlias(hDomain, DesiredAccess, AliasId, hAlias);

  if Result.IsSuccess then
    hxAlias := TSamAutoHandle.Capture(hAlias);
end;

function SamxOpenAliasBySid;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenAlias(hxAlias, hxDomain.Handle, RtlxRidSid(Sid),
    DesiredAccess);
end;

function SamxGetMembersAlias;
var
  Buffer: PSidArray;
  Count, i: Integer;
begin
  Result.Location := 'SamGetMembersInAlias';
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_LIST_MEMBERS);

  Result.Status := SamGetMembersInAlias(hAlias, Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Members, Count);

  for i := 0 to High(Members) do
  begin
    Result := RtlxCopySid(Buffer{$R-}[i]{$R+}, Members[i]);

    if not Result.IsSuccess then
      Break;
  end;

  SamFreeMemory(Buffer);
end;

function SamxQueryAlias;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationAlias';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_READ_INFORMATION);

  Result.Status := SamQueryInformationAlias(hAlias, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetAlias;
begin
  Result.Location := 'SamSetInformationAlias';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_WRITE_ACCOUNT);

  Result.Status := SamSetInformationAlias(hAlias, InfoClass, Buffer);
end;

{ Users }

function SamxEnumerateUsers;
var
  EnumContext: TSamEnumerationHandle;
  Buffer: PSamRidEnumerationArray;
  Count, i: Integer;
begin
  EnumContext := 0;
  Result.Location := 'SamEnumerateUsersInDomain';
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LIST_ACCOUNTS);

  Result.Status := SamEnumerateUsersInDomain(hDomain, EnumContext,
    UserType, Buffer, MAX_PREFERRED_LENGTH, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Users, Count);

  for i := 0 to High(Users) do
  begin
    Users[i].RelativeId := Buffer{$R-}[i]{$R+}.RelativeId;
    Users[i].Name := Buffer{$R-}[i]{$R+}.Name.ToString;
  end;

  SamFreeMemory(Buffer);
end;

function SamxOpenUser;
var
  hUser: TSamHandle;
begin
  Result.Location := 'SamOpenUser';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenUser(hDomain, DesiredAccess, UserId, hUser);

  if Result.IsSuccess then
    hxUser := TSamAutoHandle.Capture(hUser);
end;

// Open a user by SID
function SamxOpenUserBySid;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenUser(hxUser, hxDomain.Handle, RtlxRidSid(Sid),
    DesiredAccess);
end;

function SamxGetGroupsForUser;
var
  Buffer: PGroupMembershipArray;
  Count, i: Integer;
begin
  Result.Location := 'SamGetGroupsForUser';
  Result.LastCall.Expects<TUserAccessMask>(USER_LIST_GROUPS);

  Result.Status := SamGetGroupsForUser(hUser, Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Groups, Count);

  for i := 0 to High(Groups) do
    Groups[i] := Buffer{$R-}[i]{$R+}^;

  SamFreeMemory(Pointer(Buffer));
end;

function SamxQueryUser;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationUser';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedUserQueryAccess(InfoClass));

  Result.Status := SamQueryInformationUser(hUser, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

// Set user information
function SamxSetUser;
begin
  Result.Location := 'SamSetInformationUser';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(ExpectedUserSetAccess(InfoClass));
  Result.Status := SamSetInformationUser(hUser, InfoClass, Buffer);
end;

function SamxQuerySecurityObject;
var
  Buffer: PSecurityDescriptor;
begin
  Result.Location := 'SamQuerySecurityObject';
  Result.LastCall.Expects(SecurityReadAccess(Info));
  Result.Status := SamQuerySecurityObject(SamHandle, Info, Buffer);

  if Result.IsSuccess then
    IMemory(SD) := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetSecurityObject;
begin
  Result.Location := 'SamSetSecurityObject';
  Result.LastCall.Expects(SecurityWriteAccess(Info));
  Result.Status := SamSetSecurityObject(SamHandle, Info, SD);
end;

end.
