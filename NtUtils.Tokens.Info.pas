unit NtUtils.Tokens.Info;

{
  This module allows querying and setting different information classes for
  token objects.
}

interface

{ NOTE: All query/set functions here support pseudo-handles on all OS versions }

uses
  Ntapi.WinNt, Ntapi.ntseapi, NtUtils, NtUtils.Tokens;

type
  TSecurityAttribute = NtUtils.Tokens.TSecurityAttribute;

  TBnoIsolation = record
    Enabled: Boolean;
    Prefix: String;
  end;

// Make sure pseudo-handles are supported for querying on all OS versions
function NtxpExpandTokenForQuery(
  var hxToken: IHandle;
  DesiredAccess: TTokenAccessMask = TOKEN_QUERY
): TNtxStatus;

// Query variable-length token information without race conditions
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpSometimes)]
function NtxQueryToken(
  [Access(TOKEN_QUERY)] hxToken: IHandle;
  InfoClass: TTokenInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Set variable-length token information
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_CREATE_TOKEN_PRIVILEGE, rpSometimes)]
function NtxSetToken(
  [Access(TOKEN_ADJUST_DEFAULT)] hxToken: IHandle;
  InfoClass: TTokenInformationClass;
  [in] TokenInformation: Pointer;
  TokenInformationLength: Cardinal
): TNtxStatus;

type
  NtxToken = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(TOKEN_QUERY or TOKEN_QUERY_SOURCE)] hxToken: IHandle;
      InfoClass: TTokenInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size information
    [RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
    [RequiredPrivilege(SE_CREATE_TOKEN_PRIVILEGE, rpSometimes)]
    class function &Set<T>(
      [Access(TOKEN_ADJUST_DEFAULT or
        TOKEN_ADJUST_SESSIONID)] const hxToken: IHandle;
      InfoClass: TTokenInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Query a SID (Owner, Primary group, ...)
function NtxQuerySidToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  InfoClass: TTokenInformationClass;
  out Sid: ISid
): TNtxStatus;

// Set a SID (Owner, Primary group)
function NtxSetSidToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  InfoClass: TTokenInformationClass;
  const Sid: ISid
): TNtxStatus;

// Query a SID and attributes (User, Integrity, ...)
function NtxQueryGroupToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  InfoClass: TTokenInformationClass;
  out Group: TGroup
): TNtxStatus;

// Query groups (Groups, RestrictingSIDs, LogonSIDs, ...)
function NtxQueryGroupsToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  InfoClass: TTokenInformationClass;
  out Groups: TArray<TGroup>
): TNtxStatus;

// Determine the SID of the user of the token
function NtxQueryUserSddlToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  out SDDL: String
): TNtxStatus;

// Query privileges
function NtxQueryPrivilegesToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  out Privileges: TArray<TPrivilege>
): TNtxStatus;

// Query default DACL
// NOTE: the function might return NULL
function NtxQueryDefaultDaclToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  out DefaultDacl: IAcl
): TNtxStatus;

// Set default DACL
function NtxSetDefaultDaclToken(
  [Access(TOKEN_ADJUST_DEFAULT)] const hxToken: IHandle;
  [opt] const DefaultDacl: IAcl
): TNtxStatus;

// Prepare a canonical default DACL for a user token
function NtxMakeDefaultDaclToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  out DefaultDacl: IAcl
): TNtxStatus;

// Query token flags
function NtxQueryFlagsToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  out Flags: TTokenFlags
): TNtxStatus;

// Query integrity level of a token. For integrity SID use NtxQueryGroupToken.
function NtxQueryIntegrityToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  out IntegrityLevel: TIntegrityRid
): TNtxStatus;

// Set integrity level of a token
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtxSetIntegrityToken(
  [Access(TOKEN_ADJUST_DEFAULT)] const hxToken: IHandle;
  IntegrityLevel: TIntegrityRid
): TNtxStatus;

// Query token Base Named Objects isolation
function NtxQueryBnoIsolationToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  out Isolation: TBnoIsolation
): TNtxStatus;

// Query all security attributes of a token
function NtxQueryAttributesToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  InfoClass: TTokenInformationClass;
  out Attributes: TArray<TSecurityAttribute>
): TNtxStatus;

// Query security attributes of a token by names
function NtxQueryAttributesByNameToken(
  [Access(TOKEN_QUERY)] hxToken: IHandle;
  const AttributeNames: TArray<String>;
  out Attributes: TArray<TSecurityAttribute>
): TNtxStatus;

// Set or remove security attibutes of a token
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function NtxSetAttributesToken(
  [Access(TOKEN_ADJUST_DEFAULT)] const hxToken: IHandle;
  const Attributes: TArray<TSecurityAttribute>;
  [opt] Operations: TArray<TTokenAttributeOperation> = nil
): TNtxStatus;

// Check if a token is a Less Privileged AppContainer token
function NtxQueryLpacToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  out IsLPAC: Boolean
): TNtxStatus;

// Set if an AppContainer token is a Less Privileged AppContainer
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function NtxSetLpacToken(
  [Access(TOKEN_ADJUST_DEFAULT)] const hxToken: IHandle;
  IsLPAC: Boolean
): TNtxStatus;

// Query token claim attributes
function NtxQueryClaimsToken(
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  InfoClass: TTokenInformationClass;
  out Claims: TArray<TSecurityAttribute>
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, Ntapi.Versions, NtUtils.Security.Acl,
  NtUtils.Objects, NtUtils.Tokens.Misc, NtUtils.Security.Sid,
  DelphiUtils.AutoObjects, DelphiUtils.Arrays, NtUtils.Lsa.Sid;

function NtxpExpandTokenForQuery;
begin
  // Pseudo-handles are supported for querying starting from Win 8

  if (hxToken.Handle > MAX_HANDLE) and not RtlOsVersionAtLeast(OsWin8) then
    Result := NtxExpandToken(hxToken, DesiredAccess)
  else
    Result.Status := STATUS_SUCCESS;
end;

function NtxQueryToken;
var
  DesiredAccess: TTokenAccessMask;
  Required: Cardinal;
begin
  DesiredAccess := ExpectedTokenQueryAccess(InfoClass);

  // Make sure pseudo-handles are supported
  Result := NtxpExpandTokenForQuery(hxToken, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryInformationToken';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(DesiredAccess);
  Result.LastCall.ExpectedPrivilege := ExpectedTokenQueryPrivilege(InfoClass);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationToken(hxToken.Handle, InfoClass,
      xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxSetToken;
var
  DesiredAccess: TTokenAccessMask;
begin
  DesiredAccess := ExpectedTokenSetAccess(InfoClass);

  // Always expand pseudo-tokens for setting information
  Result := NtxExpandToken(hxToken, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtSetInformationToken';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(DesiredAccess);
  Result.LastCall.ExpectedPrivilege := ExpectedTokenSetPrivilege(InfoClass);

  Result.Status := NtSetInformationToken(hxToken.Handle, InfoClass,
    TokenInformation, TokenInformationLength);
end;

class function NtxToken.Query<T>;
var
  DesiredAccess: TTokenAccessMask;
  ReturnedBytes: Cardinal;
begin
  DesiredAccess := ExpectedTokenQueryAccess(InfoClass);

  // Make sure pseudo-handles are supported
  Result := NtxpExpandTokenForQuery(hxToken, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryInformationToken';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(DesiredAccess);
  Result.LastCall.ExpectedPrivilege := ExpectedTokenQueryPrivilege(InfoClass);

  Result.Status := NtQueryInformationToken(hxToken.Handle, InfoClass, @Buffer,
    SizeOf(Buffer), ReturnedBytes);
end;

class function NtxToken.&Set<T>;
begin
  Result := NtxSetToken(hxToken, InfoClass, @Buffer, SizeOf(Buffer));
end;

{ Typed queries }

function NtxQuerySidToken;
var
  xMemory: IMemory<PTokenSidInformation>;
begin
  Result := NtxQueryToken(hxToken, InfoClass, IMemory(xMemory),
    SECURITY_MAX_SID_SIZE);

  if Result.IsSuccess and Assigned(xMemory.Data.Sid) then
    Result := RtlxCopySid(xMemory.Data.Sid, Sid);
end;

function NtxSetSidToken;
var
  Buffer: TTokenSidInformation;
begin
  Buffer.Sid := Sid.Data;
  Result := NtxToken.Set(hxToken, InfoClass, Buffer);
end;

function NtxQueryGroupToken;
var
  xMemory: IMemory<PSidAndAttributes>;
begin
  Result := NtxQueryToken(hxToken, InfoClass, IMemory(xMemory),
    SECURITY_MAX_SID_SIZE + SizeOf(Cardinal));

  if Result.IsSuccess then
  begin
    Group.Attributes := xMemory.Data.Attributes;
    Result := RtlxCopySid(xMemory.Data.Sid, Group.Sid);
  end;
end;

function NtxQueryGroupsToken;
var
  xMemory: IMemory<PTokenGroups>;
  i: Integer;
begin
  Result := NtxQueryToken(hxToken, InfoClass, IMemory(xMemory));

  if Result.IsSuccess then
  begin
    SetLength(Groups, xMemory.Data.GroupCount);

    for i := 0 to High(Groups) do
    begin
      Groups[i].Attributes := xMemory.Data.Groups{$R-}[i]{$R+}.Attributes;

      Result := RtlxCopySid(xMemory.Data.Groups{$R-}[i]{$R+}.Sid,
        Groups[i].Sid);

      if not Result.IsSuccess then
        Break;
    end;
  end;
end;

function NtxQueryUserSddlToken;
var
  User: ISid;
  UserName: String;
begin
  Result := NtxQuerySidToken(hxToken, TokenUser, User);

  if Result.IsSuccess then
    SDDL := RtlxSidToString(User)

  // Ask LSA for help if we can't open our token
  else if (hxToken.Handle = NtCurrentEffectiveToken) and
    LsaxGetFullUserName(UserName).IsSuccess and
    LsaxLookupName(UserName, User).IsSuccess then
  begin
    SDDL := RtlxSidToString(User);
    Result.Status := STATUS_SUCCESS;
  end;
end;

function NtxQueryPrivilegesToken;
var
  xMemory: IMemory<PTokenPrivileges>;
  i: Integer;
begin
  Result := NtxQueryToken(hxToken, TokenPrivileges, IMemory(xMemory),
    SizeOf(Integer) + SizeOf(TPrivilege) * Cardinal(High(TSeWellKnownPrivilege)));

  if Result.IsSuccess then
  begin
    SetLength(Privileges, xMemory.Data.PrivilegeCount);

    for i := 0 to High(Privileges) do
      Privileges[i] := xMemory.Data.Privileges{$R-}[i]{$R+};
  end;
end;

function NtxQueryDefaultDaclToken;
var
  xMemory: IMemory<PTokenDefaultDacl>;
begin
  Result := NtxQueryToken(hxToken, TokenDefaultDacl, IMemory(xMemory));

  if Result.IsSuccess and Assigned(xMemory.Data.DefaultDacl) then
    Result := RtlxCopyAcl(DefaultDacl, xMemory.Data.DefaultDacl)
  else
    DefaultDacl := nil;
end;

function NtxSetDefaultDaclToken;
var
  Dacl: TTokenDefaultDacl;
begin
  Dacl.DefaultDacl := Auto.RefOrNil<PAcl>(DefaultDacl);
  Result := NtxToken.Set(hxToken, TokenDefaultDacl, Dacl);
end;

function NtxMakeDefaultDaclToken;
var
  Owner: TGroup;
  LogonSids: TArray<TGroup>;
  Aces: TArray<TAceData>;
begin
  Result := NtxQueryGroupToken(hxToken, TokenOwner, Owner);

  if not Result.IsSuccess then
    Exit;

  // Add GENERIC_ALL for the owner and SYSTEM
  Aces := [
    TAceData.New(ACCESS_ALLOWED_ACE_TYPE, 0, GENERIC_ALL, Owner.Sid),
    TAceData.New(ACCESS_ALLOWED_ACE_TYPE, 0, GENERIC_ALL,
      RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_LOCAL_SYSTEM_RID]))
  ];

  // Add GR + GE for the logon SID
  if NtxQueryGroupsToken(hxToken, TokenLogonSid, LogonSids).IsSuccess and
    (Length(LogonSids) > 0) then
    Aces := Aces + [TAceData.New(ACCESS_ALLOWED_ACE_TYPE, 0, GENERIC_READ or
      GENERIC_EXECUTE, LogonSids[0].Sid)];

  Result := RtlxBuildAcl(DefaultDacl, Aces);
end;

function NtxQueryFlagsToken;
var
  xMemory: IMemory<PTokenAccessInformation>;
begin
  Result := NtxQueryToken(hxToken, TokenAccessInformation, IMemory(xMemory));

  if Result.IsSuccess then
    Flags := xMemory.Data.Flags;
end;

function NtxQueryIntegrityToken;
var
  IntegritySid: TGroup;
begin
  Result := NtxQueryGroupToken(hxToken, TokenIntegrityLevel, IntegritySid);

  if not Result.IsSuccess then
    Exit;

  // The last sub-authority is the level
  if Assigned(IntegritySid.Sid) then
    IntegrityLevel := RtlxRidSid(IntegritySid.Sid,
      SECURITY_MANDATORY_UNTRUSTED_RID)
  else
    IntegrityLevel := SECURITY_MANDATORY_UNTRUSTED_RID;
end;

function NtxSetIntegrityToken;
var
  LabelSid: ISid;
  MandatoryLabel: TSidAndAttributes;
begin
  // Prepare SID for integrity level with 1 sub authority: S-1-16-X.
  Result := RtlxCreateSid(LabelSid, SECURITY_MANDATORY_LABEL_AUTHORITY,
    [IntegrityLevel]);

  if not Result.IsSuccess then
    Exit;

  MandatoryLabel.Sid := LabelSid.Data;
  MandatoryLabel.Attributes := SE_GROUP_INTEGRITY_ENABLED;

  Result := NtxToken.Set(hxToken, TokenIntegrityLevel, MandatoryLabel);
end;

function NtxQueryBnoIsolationToken;
var
  Buffer: IMemory<PTokenBnoIsolationInformation>;
begin
  Result := NtxQueryToken(hxToken, TokenBnoIsolation, IMemory(Buffer));

  if Result.IsSuccess then
  begin
    Isolation.Enabled := Buffer.Data.IsolationEnabled;
    Isolation.Prefix := String(Buffer.Data.IsolationPrefix);
  end;
end;

function NtxQueryAttributesToken;
var
  xMemory: IMemory<PTokenSecurityAttributes>;
begin
  Result := NtxQueryToken(hxToken, InfoClass, IMemory(xMemory));

  if Result.IsSuccess then
    Attributes := NtxpParseSecurityAttributes(xMemory.Data);
end;

function NtxQueryAttributesByNameToken;
var
  NameStrings: TArray<TNtUnicodeString>;
  xMemory: IMemory<PTokenSecurityAttributes>;
  Required: Cardinal;
begin
  // Windows 7 supports this function, but can't handle pseudo-tokens yet
  Result := NtxpExpandTokenForQuery(hxToken, TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQuerySecurityAttributesToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);

  // Convert attribute names to UNICODE_STRINGs
  NameStrings := TArray.Map<String, TNtUnicodeString>(AttributeNames,
    TNtUnicodeString.From);

  IMemory(xMemory) := Auto.AllocateDynamic(0);
  repeat
    Required := 0;
    Result.Status := NtQuerySecurityAttributesToken(hxToken.Handle, NameStrings,
      Length(NameStrings), xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), Required, nil);

  if Result.IsSuccess then
    Attributes := NtxpParseSecurityAttributes(xMemory.Data);
end;

function NtxSetAttributesToken;
var
  AttributeBuffer: IMemory<PTokenSecurityAttributes>;
  Buffer: TTokenSecurityAttributesAndOperation;
  i: Integer;
begin
  if Length(Operations) = 0 then
  begin  
    SetLength(Operations, Length(Attributes));

    // Overwrite existing attributes by default
    for i := 0 to High(Operations) do
      Operations[i] := TOKEN_SECURITY_ATTRIBUTE_OPERATION_REPLACE;
  end
  else if Length(Attributes) <> Length(Operations) then
  begin
    // The amounts must match, fail
    Result.Location := 'NtxSetAttributesToken';
    Result.Status := STATUS_INFO_LENGTH_MISMATCH;
    Exit;
  end;       

  AttributeBuffer := NtxpAllocSecurityAttributes(Attributes);
  Buffer.Attributes := AttributeBuffer.Data;
  Buffer.Operations := Pointer(Operations);

  Result := NtxToken.Set(hxToken, TokenSecurityAttributes, Buffer);
end;

function NtxQueryLpacToken;
var
  Attributes: TArray<TSecurityAttribute>;
begin
  // This security attribute indicates Less Privileged AppContainer
  Result := NtxQueryAttributesByNameToken(hxToken, ['WIN://NOALLAPPPKG'],
    Attributes);

  IsLPAC := False;

  // The system looks up the first element being nonzero as an unsigied integer
  // without actually checkign the type of the attribute...

  if Result.IsSuccess and (Length(Attributes) > 0) then
    case Attributes[0].ValueType of
      // By default we expect UINT64
      SECURITY_ATTRIBUTE_TYPE_INT64, SECURITY_ATTRIBUTE_TYPE_UINT64,
      SECURITY_ATTRIBUTE_TYPE_BOOLEAN:
        IsLPAC := Attributes[0].ValuesUInt64[0] <> 0;

      // HACK: these types always imply that the first couple of bytes contain
      // a non-zero value. Since the OS does not check the type of the attribute
      // it always considers them as an enabled LPAC.
      SECURITY_ATTRIBUTE_TYPE_STRING, SECURITY_ATTRIBUTE_TYPE_SID,
      SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
        IsLPAC := True;

      // The first 8 bytes of FQBN are a version, check it.
      SECURITY_ATTRIBUTE_TYPE_FQBN:
        IsLPAC := Attributes[0].ValuesFqbn[0].Version <> 0;
    end
  else if Result.Status = STATUS_NOT_FOUND then
    Result.Status := STATUS_SUCCESS // not an LPAC
end;

function NtxSetLpacToken;
var
  Attribute: TSecurityAttribute;
  Operation: TTokenAttributeOperation;
begin
  // To enable LPAC we need to add an UINT64 attribute with the first element
  // set to a non-zero value. Actually, from the OS's perspective, the type does
  // not matter, but let's mimic the default behavior anyway and use UINT64.
  Attribute.Name := 'WIN://NOALLAPPPKG';
  Attribute.ValueType := SECURITY_ATTRIBUTE_TYPE_UINT64;
  Attribute.ValuesUInt64 := [1];

  if IsLPAC then
    Operation := TOKEN_SECURITY_ATTRIBUTE_OPERATION_REPLACE
  else
    Operation := TOKEN_SECURITY_ATTRIBUTE_OPERATION_DELETE;

  Result := NtxSetAttributesToken(hxToken, [Attribute], [Operation]);

  // Suceed if it is already a non-LPAC token
  if not IsLPAC and (Result.Status = STATUS_NOT_FOUND) then
    Result.Status := STATUS_SUCCESS;  
end;

function NtxQueryClaimsToken;
var
  xMemory: IMemory<PClaimSecurityAttributes>;
begin
  Result := NtxQueryToken(hxToken, InfoClass, IMemory(xMemory));

  if Result.IsSuccess then
    Claims := NtxpParseClaimAttributes(xMemory.Data);
end;

end.
