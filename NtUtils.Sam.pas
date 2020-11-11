unit NtUtils.Sam;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntsam, NtUtils,
  DelphiUtils.AutoObject;

type
  TSamHandle = Ntapi.ntsam.TSamHandle;
  ISamHandle = DelphiUtils.AutoObject.IHandle;

  TRidAndName = record
    Name: String;
    RelativeID: Cardinal;
  end;

  TGroupMembership = Ntapi.ntsam.TGroupMembership;

// Connect to a SAM server
function SamxConnect(out hxServer: ISamHandle; DesiredAccess: TAccessMask;
  ServerName: String = ''): TNtxStatus;

{ --------------------------------- Domains -------------------------------- }

// Open a domain
function SamxOpenDomain(out hxDomain: ISamHandle; DomainId: PSid;
  DesiredAccess: TAccessMask; hxServer: ISamHandle = nil): TNtxStatus;

// Open the parent of the SID as a domain
function SamxOpenParentDomain(out hxDomain: ISamHandle; SID: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;

// Lookup a domain
function SamxLookupDomain(hServer: TSamHandle; Name: String;
  out DomainId: ISid): TNtxStatus;

// Enumerate domains
function SamxEnumerateDomains(hServer: TSamHandle; out Names: TArray<String>):
  TNtxStatus;

// Query domain information
function SamxQueryDomain(hDomain: TSamHandle; InfoClass:
  TDomainInformationClass; out xMemory: IMemory): TNtxStatus;

// Set domain information
function SamxSetDomain(hDomain: TSamHandle; InfoClass: TDomainInformationClass;
  Data: Pointer): TNtxStatus;

{ --------------------------------- Groups ---------------------------------- }

// Enumerate groups
function SamxEnumerateGroups(hDomain: TSamHandle;
  out Groups: TArray<TRidAndName>): TNtxStatus;

// Open a group
function SamxOpenGroup(out hxGroup: ISamHandle; hDomain: TSamHandle;
  GroupId: Cardinal; DesiredAccess: TAccessMask): TNtxStatus;

// Open a group by SID
function SamxOpenGroupBySid(out hxGroup: ISamHandle; Sid: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;

// Get groups members
function SamxGetMembersGroup(hGroup: TSamHandle;
  out Members: TArray<TGroupMembership>): TNtxStatus;

// Query group information
function SamxQueryGroup(hGroup: TSamHandle; InfoClass: TGroupInformationClass;
  out xMemory: IMemory): TNtxStatus;

// Set group information
function SamxSetGroup(hGroup: TSamHandle; InfoClass: TGroupInformationClass;
  Data: Pointer): TNtxStatus;

{ --------------------------------- Aliases --------------------------------- }

// Enumerate aliases in domain
function SamxEnumerateAliases(hDomain: TSamHandle;
  out Aliases: TArray<TRidAndName>): TNtxStatus;

// Open an alias
function SamxOpenAlias(out hxAlias: ISamHandle; hDomain: TSamHandle;
  AliasId: Cardinal; DesiredAccess: TAccessMask): TNtxStatus;

// Open an alias by SID
function SamxOpenAliasBySid(out hxAlias: ISamHandle; Sid: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;

// Get alias members
function SamxGetMembersAlias(hAlias: TSamHandle; out Members: TArray<ISid>):
  TNtxStatus;

// Query alias information
function SamxQueryAlias(hAlias: TSamHandle; InfoClass: TAliasInformationClass;
  out xMemory: IMemory): TNtxStatus;

// Set alias information
function SamxSetAlias(hAlias: TSamHandle; InfoClass: TAliasInformationClass;
  Data: Pointer): TNtxStatus;

{ ---------------------------------- Users ---------------------------------- }

// Enumerate users in domain
function SamxEnumerateUsers(hDomain: TSamHandle; UserType: Cardinal;
  out Users: TArray<TRidAndName>): TNtxStatus;

// Open a user
function SamxOpenUser(out hxUser: ISamHandle; hDomain: TSamHandle;
  UserId: Cardinal; DesiredAccess: TAccessMask): TNtxStatus;

// Open a user by SID
function SamxOpenUserBySid(out hxUser: ISamHandle; Sid: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;

// Get groups for a user
function SamxGetGroupsForUser(hUser: TSamHandle;
  out Groups: TArray<TGroupMembership>): TNtxStatus;

// Query user information
function SamxQueryUser(hUser: TSamHandle; InfoClass: TUserInformationClass;
  out xMemory: IMemory): TNtxStatus;

// Set user information
function SamxSetUser(hUser: TSamHandle; InfoClass: TUserInformationClass;
  Data: Pointer): TNtxStatus;

{ -------------------------------- Security --------------------------------- }

// Query security descriptor of a SAM object
function SamxQuerySecurityObject(SamHandle: TSamHandle; Info:
  TSecurityInformation; out SD: ISecDesc): TNtxStatus;

// Set security descriptor on a SAM object
function SamxSetSecurityObject(SamHandle: TSamHandle; Info:
  TSecurityInformation; SD: PSecurityDescriptor): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.Security.Sid;

type
  TSamAutoHandle = class(TCustomAutoHandle, ISamHandle)
    // Close SAM auto-handle
    destructor Destroy; override;
  end;

  TSamAutoMemory = class(TCustomAutoMemory, IMemory)
    // Free SAM memory
    destructor Destroy; override;
  end;

{ Common & Server }

destructor TSamAutoHandle.Destroy;
begin
  if FAutoRelease then
    SamCloseHandle(FHandle);
  inherited;
end;

destructor TSamAutoMemory.Destroy;
begin
  if FAutoRelease then
    SamFreeMemory(FAddress);
  inherited;
end;

function SamxConnect(out hxServer: ISamHandle; DesiredAccess: TAccessMask;
  ServerName: String = ''): TNtxStatus;
var
  ObjAttr: TObjectAttributes;
  hServer: TSamHandle;
begin
  InitializeObjectAttributes(ObjAttr);

  Result.Location := 'SamConnect';
  Result.LastCall.AttachAccess<TSamAccessMask>(DesiredAccess);

  Result.Status := SamConnect(TNtUnicodeString.From(ServerName).RefOrNull,
    hServer, DesiredAccess, ObjAttr);

  if Result.IsSuccess then
    hxServer := TSamAutoHandle.Capture(hServer);
end;

function SamxpEnsureConnected(var hxServer: ISamHandle;
  DesiredAccess: TAccessMask): TNtxStatus;
begin
  if not Assigned(hxServer) then
    Result := SamxConnect(hxServer, DesiredAccess)
  else
    Result.Status := STATUS_SUCCESS
end;

{ Domains }

function SamxOpenDomain(out hxDomain: ISamHandle; DomainId: PSid;
  DesiredAccess: TAccessMask; hxServer: ISamHandle = nil): TNtxStatus;
var
  hDomain: TSamHandle;
begin
  Result := SamxpEnsureConnected(hxServer, SAM_SERVER_LOOKUP_DOMAIN);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'SamOpenDomain';
  Result.LastCall.AttachAccess<TDomainAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TSamAccessMask>(SAM_SERVER_LOOKUP_DOMAIN);

  Result.Status := SamOpenDomain(hxServer.Handle, DesiredAccess, DomainId,
    hDomain);

  if Result.IsSuccess then
    hxDomain := TSamAutoHandle.Capture(hDomain);
end;

function SamxOpenParentDomain(out hxDomain: ISamHandle; SID: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;
var
  ParentSid: ISid;
begin
  Result := RtlxParentSid(ParentSid, SID);

  if Result.IsSuccess then
    Result := SamxOpenDomain(hxDomain, ParentSid.Data, DOMAIN_LOOKUP);
end;

function SamxLookupDomain(hServer: TSamHandle; Name: String;
  out DomainId: ISid): TNtxStatus;
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

function SamxEnumerateDomains(hServer: TSamHandle; out Names: TArray<String>):
  TNtxStatus;
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

function SamxQueryDomain(hDomain: TSamHandle; InfoClass:
  TDomainInformationClass; out xMemory: IMemory): TNtxStatus;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationDomain';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedDomainQueryAccess(InfoClass));

  Result.Status := SamQueryInformationDomain(hDomain, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetDomain(hDomain: TSamHandle; InfoClass: TDomainInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'SamSetInformationDomain';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedDomainSetAccess(InfoClass));
  Result.Status := SamSetInformationDomain(hDomain, InfoClass, Data);
end;

{ Groups }

function SamxEnumerateGroups(hDomain: TSamHandle;
  out Groups: TArray<TRidAndName>): TNtxStatus;
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

function SamxOpenGroup(out hxGroup: ISamHandle; hDomain: TSamHandle;
  GroupId: Cardinal; DesiredAccess: TAccessMask): TNtxStatus;
var
  hGroup: TSamHandle;
begin
  Result.Location := 'SamOpenGroup';
  Result.LastCall.AttachAccess<TGroupAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenGroup(hDomain, DesiredAccess, GroupId, hGroup);

  if Result.IsSuccess then
    hxGroup := TSamAutoHandle.Capture(hGroup);
end;

function SamxOpenGroupBySid(out hxGroup: ISamHandle; Sid: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenGroup(hxGroup, hxDomain.Handle, RtlxRidSid(Sid.Data),
    DesiredAccess);
end;

function SamxGetMembersGroup(hGroup: TSamHandle;
  out Members: TArray<TGroupMembership>): TNtxStatus;
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

function SamxQueryGroup(hGroup: TSamHandle; InfoClass: TGroupInformationClass;
  out xMemory: IMemory): TNtxStatus;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationGroup';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_READ_INFORMATION);

  Result.Status := SamQueryInformationGroup(hGroup, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetGroup(hGroup: TSamHandle; InfoClass: TGroupInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'SamSetInformationGroup';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TGroupAccessMask>(GROUP_WRITE_ACCOUNT);

  Result.Status := SamSetInformationGroup(hGroup, InfoClass, Data);
end;

{ Aliases }

function SamxEnumerateAliases(hDomain: TSamHandle;
  out Aliases: TArray<TRidAndName>): TNtxStatus;
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

function SamxOpenAlias(out hxAlias: ISamHandle; hDomain: TSamHandle;
  AliasId: Cardinal; DesiredAccess: TAccessMask): TNtxStatus;
var
  hAlias: TSamHandle;
begin
  Result.Location := 'SamOpenAlias';
  Result.LastCall.AttachAccess<TAliasAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenAlias(hDomain, DesiredAccess, AliasId, hAlias);

  if Result.IsSuccess then
    hxAlias := TSamAutoHandle.Capture(hAlias);
end;

function SamxOpenAliasBySid(out hxAlias: ISamHandle; Sid: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenAlias(hxAlias, hxDomain.Handle, RtlxRidSid(Sid.Data),
    DesiredAccess);
end;

function SamxGetMembersAlias(hAlias: TSamHandle; out Members: TArray<ISid>):
  TNtxStatus;
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

function SamxQueryAlias(hAlias: TSamHandle; InfoClass: TAliasInformationClass;
  out xMemory: IMemory): TNtxStatus;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationAlias';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_READ_INFORMATION);

  Result.Status := SamQueryInformationAlias(hAlias, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetAlias(hAlias: TSamHandle; InfoClass: TAliasInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'SamSetInformationAlias';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TAliasAccessMask>(ALIAS_WRITE_ACCOUNT);

  Result.Status := SamSetInformationAlias(hAlias, InfoClass, Data);
end;

{ Users }

function SamxEnumerateUsers(hDomain: TSamHandle; UserType: Cardinal;
  out Users: TArray<TRidAndName>): TNtxStatus;
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

function SamxOpenUser(out hxUser: ISamHandle; hDomain: TSamHandle;
  UserId: Cardinal; DesiredAccess: TAccessMask): TNtxStatus;
var
  hUser: TSamHandle;
begin
  Result.Location := 'SamOpenUser';
  Result.LastCall.AttachAccess<TUserAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TDomainAccessMask>(DOMAIN_LOOKUP);

  Result.Status := SamOpenUser(hDomain, DesiredAccess, UserId, hUser);

  if Result.IsSuccess then
    hxUser := TSamAutoHandle.Capture(hUser);
end;

// Open a user by SID
function SamxOpenUserBySid(out hxUser: ISamHandle; Sid: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;
var
  hxDomain: ISamHandle;
begin
  Result := SamxOpenParentDomain(hxDomain, Sid, DOMAIN_LOOKUP);

  if not Result.IsSuccess then
    Exit;

  Result := SamxOpenUser(hxUser, hxDomain.Handle, RtlxRidSid(Sid.Data),
    DesiredAccess);
end;

function SamxGetGroupsForUser(hUser: TSamHandle;
  out Groups: TArray<TGroupMembership>): TNtxStatus;
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

  SamFreeMemory(Buffer);
end;

function SamxQueryUser(hUser: TSamHandle; InfoClass: TUserInformationClass;
  out xMemory: IMemory): TNtxStatus;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationUser';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedUserQueryAccess(InfoClass));

  Result.Status := SamQueryInformationUser(hUser, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

// Set user information
function SamxSetUser(hUser: TSamHandle; InfoClass: TUserInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'SamSetInformationUser';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedUserSetAccess(InfoClass));
  Result.Status := SamSetInformationUser(hUser, InfoClass, Data);
end;

function SamxQuerySecurityObject(SamHandle: TSamHandle; Info:
  TSecurityInformation; out SD: ISecDesc): TNtxStatus;
var
  Buffer: PSecurityDescriptor;
begin
  Result.Location := 'SamQuerySecurityObject';
  Result.LastCall.AttachAccess<TAccessMask>(SecurityReadAccess(Info));
  Result.Status := SamQuerySecurityObject(SamHandle, Info, Buffer);

  if Result.IsSuccess then
    IMemory(SD) := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetSecurityObject(SamHandle: TSamHandle; Info:
  TSecurityInformation; SD: PSecurityDescriptor): TNtxStatus;
begin
  Result.Location := 'SamSetSecurityObject';
  Result.LastCall.AttachAccess<TAccessMask>(SecurityWriteAccess(Info));
  Result.Status := SamSetSecurityObject(SamHandle, Info, SD);
end;

end.
