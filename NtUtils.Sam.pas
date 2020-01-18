unit NtUtils.Sam;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntsam, NtUtils.Exceptions,
  NtUtils.Security.Sid, DelphiUtils.AutoObject;

type
  TSamHandle = Ntapi.ntsam.TSamHandle;
  ISamHandle = DelphiUtils.AutoObject.IHandle;

  TSamAutoHandle = class(TCustomAutoHandle, ISamHandle)
    // Close SAM auto-handle
    destructor Destroy; override;
  end;

  TSamAutoMemory = class(TCustomAutoMemory, IMemory)
    // Free SAM memory
    destructor Destroy; override;
  end;

  TRidAndName = record
    Name: String;
    RelativeId: Cardinal;
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

implementation

uses
  Ntapi.ntstatus, NtUtils.Access.Expected;

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
  NameStr: UNICODE_STRING;
  pNameStr: PUNICODE_STRING;
  hServer: TSamHandle;
begin
  InitializeObjectAttributes(ObjAttr);

  if ServerName <> '' then
  begin
    NameStr.FromString(ServerName);
    pNameStr := @NameStr;
  end
  else
    pNameStr := nil;

  Result.Location := 'SamConnect';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @SamAccessType;

  Result.Status := SamConnect(pNameStr, hServer, DesiredAccess, ObjAttr);

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
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @DomainAccessType;
  Result.LastCall.Expects(SAM_SERVER_LOOKUP_DOMAIN, @SamAccessType);

  Result.Status := SamOpenDomain(hxServer.Handle, DesiredAccess, DomainId,
    hDomain);

  if Result.IsSuccess then
    hxDomain := TSamAutoHandle.Capture(hDomain);
end;

function SamxOpenParentDomain(out hxDomain: ISamHandle; SID: ISid;
  DesiredAccess: TAccessMask): TNtxStatus;
begin
  if Sid.SubAuthorities = 0 then
  begin
    Result.Location := 'ISid.ParentSid';
    Result.Status := STATUS_INVALID_SID;
    Exit;
  end;

  Result := SamxOpenDomain(hxDomain, Sid.Parent.Sid, DOMAIN_LOOKUP);
end;

function SamxLookupDomain(hServer: TSamHandle; Name: String;
  out DomainId: ISid): TNtxStatus;
var
  NameStr: UNICODE_STRING;
  Buffer: PSid;
begin
  NameStr.FromString(Name);
  Result.Location := 'SamLookupDomainInSamServer';
  Result.LastCall.Expects(SAM_SERVER_LOOKUP_DOMAIN, @SamAccessType);

  Result.Status := SamLookupDomainInSamServer(hServer, NameStr, Buffer);

  if not Result.IsSuccess then
    Exit;

  DomainId := TSid.CreateCopy(Buffer);
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
  Result.LastCall.Expects(SAM_SERVER_ENUMERATE_DOMAINS, @SamAccessType);

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
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TDomainInformationClass);
  RtlxComputeDomainQueryAccess(Result.LastCall, InfoClass);

  Result.Status := SamQueryInformationDomain(hDomain, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetDomain(hDomain: TSamHandle; InfoClass: TDomainInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'SamSetInformationDomain';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TDomainInformationClass);
  RtlxComputeDomainSetAccess(Result.LastCall, InfoClass);

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
  Result.LastCall.Expects(DOMAIN_LIST_ACCOUNTS, @DomainAccessType);

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
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @GroupAccessType;
  Result.LastCall.Expects(DOMAIN_LOOKUP, @DomainAccessType);

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

  Result := SamxOpenGroup(hxGroup, hxDomain.Handle, Sid.Rid, DesiredAccess);
end;

function SamxGetMembersGroup(hGroup: TSamHandle;
  out Members: TArray<TGroupMembership>): TNtxStatus;
var
  BufferIDs, BufferAttributes: PCardinalArray;
  Count, i: Integer;
begin
  Result.Location := 'SamGetMembersInGroup';
  Result.LastCall.Expects(GROUP_LIST_MEMBERS, @GroupAccessType);

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
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TGroupInformationClass);
  Result.LastCall.Expects(GROUP_READ_INFORMATION, @GroupAccessType);

  Result.Status := SamQueryInformationGroup(hGroup, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetGroup(hGroup: TSamHandle; InfoClass: TGroupInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'SamSetInformationGroup';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TGroupInformationClass);
  Result.LastCall.Expects(GROUP_WRITE_ACCOUNT, @GroupAccessType);

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
  Result.LastCall.Expects(DOMAIN_LIST_ACCOUNTS, @DomainAccessType);

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
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @AliasAccessType;
  Result.LastCall.Expects(DOMAIN_LOOKUP, @DomainAccessType);

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

  Result := SamxOpenAlias(hxAlias, hxDomain.Handle, Sid.Rid, DesiredAccess);
end;

function SamxGetMembersAlias(hAlias: TSamHandle; out Members: TArray<ISid>):
  TNtxStatus;
var
  Buffer: PSidArray;
  Count, i: Integer;
begin
  Result.Location := 'SamGetMembersInAlias';
  Result.LastCall.Expects(ALIAS_LIST_MEMBERS, @AliasAccessType);

  Result.Status := SamGetMembersInAlias(hAlias, Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Members, Count);

  for i := 0 to High(Members) do
    Members[i] := TSid.CreateCopy(Buffer{$R-}[i]{$R+});

  SamFreeMemory(Buffer);
end;

function SamxQueryAlias(hAlias: TSamHandle; InfoClass: TAliasInformationClass;
  out xMemory: IMemory): TNtxStatus;
var
  Buffer: Pointer;
begin
  Result.Location := 'SamQueryInformationAlias';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TAliasInformationClass);
  Result.LastCall.Expects(ALIAS_READ_INFORMATION, @AliasAccessType);

  Result.Status := SamQueryInformationAlias(hAlias, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

function SamxSetAlias(hAlias: TSamHandle; InfoClass: TAliasInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'SamSetInformationAlias';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TAliasInformationClass);
  Result.LastCall.Expects(ALIAS_WRITE_ACCOUNT, @AliasAccessType);

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
  Result.LastCall.Expects(DOMAIN_LIST_ACCOUNTS, @DomainAccessType);

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
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @UserAccessType;
  Result.LastCall.Expects(DOMAIN_LOOKUP, @DomainAccessType);

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

  Result := SamxOpenUser(hxUser, hxDomain.Handle, Sid.Rid, DesiredAccess);
end;

function SamxGetGroupsForUser(hUser: TSamHandle;
  out Groups: TArray<TGroupMembership>): TNtxStatus;
var
  Buffer: PGroupMembershipArray;
  Count, i: Integer;
begin
  Result.Location := 'SamGetGroupsForUser';
  Result.LastCall.Expects(USER_LIST_GROUPS, @UserAccessType);

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
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TUserInformationClass);
  RtlxComputeUserQueryAccess(Result.LastCall, InfoClass);

  Result.Status := SamQueryInformationUser(hUser, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TSamAutoMemory.Capture(Buffer, 0);
end;

// Set user information
function SamxSetUser(hUser: TSamHandle; InfoClass: TUserInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'SamSetInformationUser';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TUserInformationClass);
  RtlxComputeUserSetAccess(Result.LastCall, InfoClass);

  Result.Status := SamSetInformationUser(hUser, InfoClass, Data);
end;

end.
