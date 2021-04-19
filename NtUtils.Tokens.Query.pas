unit NtUtils.Tokens.Query;

{
  This module allows querying and setting different information classes for
  token objects.
}

interface

{ NOTE: All query/set functions here support pseudo-handles on all OS versions }

uses
  Winapi.WinNt, Ntapi.ntseapi, NtUtils, NtUtils.Tokens;

type
  TSecurityAttribute = NtUtils.Tokens.TSecurityAttribute;

// Make sure pseudo-handles are supported for querying
function NtxpExpandPseudoTokenForQuery(
  out hxToken: IHandle;
  hToken: THandle;
  DesiredAccess: TTokenAccessMask
): TNtxStatus;

// Query variable-length token information without race conditions
function NtxQueryToken(
  hToken: THandle;
  InfoClass: TTokenInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Set variable-length token information
function NtxSetToken(
  hToken: THandle;
  InfoClass: TTokenInformationClass;
  [in] TokenInformation: Pointer;
  TokenInformationLength: Cardinal
): TNtxStatus;

type
  NtxToken = class abstract
    // Query fixed-size information
    class function Query<T>(
      hToken: THandle;
      InfoClass: TTokenInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size information
    class function &Set<T>(
      hToken: THandle;
      InfoClass: TTokenInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Query a SID (Owner, Primary group, ...)
function NtxQuerySidToken(
  hToken: THandle;
  InfoClass: TTokenInformationClass;
  out Sid: ISid
): TNtxStatus;

// Query a SID and attributes (User, Integrity, ...)
function NtxQueryGroupToken(
  hToken: THandle;
  InfoClass: TTokenInformationClass;
  out Group: TGroup
): TNtxStatus;

// Query groups (Groups, RestrictingSIDs, LogonSIDs, ...)
function NtxQueryGroupsToken(
  hToken: THandle;
  InfoClass: TTokenInformationClass;
  out Groups: TArray<TGroup>
): TNtxStatus;

// Determine the SID of the user of the token
function NtxQueryUserSddlToken(
  hToken: THandle;
  out SDDL: String
): TNtxStatus;

// Query privileges
function NtxQueryPrivilegesToken(
  hToken: THandle;
  out Privileges: TArray<TPrivilege>
): TNtxStatus;

// Query default DACL
function NtxQueryDefaultDaclToken(
  hToken: THandle;
  out DefaultDacl: IAcl
): TNtxStatus;

// Set default DACL
function NtxSetDefaultDaclToken(
  hToken: THandle;
  [opt] const DefaultDacl: IAcl
): TNtxStatus;

// Query token flags
function NtxQueryFlagsToken(
  hToken: THandle;
  out Flags: TTokenFlags
): TNtxStatus;

// Query integrity level of a token. For integrity SID use NtxQueryGroupToken.
function NtxQueryIntegrityToken(
  hToken: THandle;
  out IntegrityLevel: TIntegriyRid
): TNtxStatus;

// Set integrity level of a token
function NtxSetIntegrityToken(
  hToken: THandle;
  IntegrityLevel: TIntegriyRid
): TNtxStatus;

// Query all security attributes of a token
function NtxQueryAttributesToken(
  hToken: THandle;
  InfoClass: TTokenInformationClass;
  out Attributes: TArray<TSecurityAttribute>
): TNtxStatus;

// Query security attributes of a token by names
function NtxQueryAttributesByNameToken(
  hToken: THandle;
  const AttributeNames: TArray<String>;
  out Attributes: TArray<TSecurityAttribute>
): TNtxStatus;

// Set or remove security attibutes of a token
function NtxSetAttributesToken(
  hToken: THandle;
  const Attributes: TArray<TSecurityAttribute>;
  [opt] Operations: TArray<TTokenAttributeOperation> = nil
): TNtxStatus;

// Check if a token is a Less Privileged AppContainer token
function NtxQueryLpacToken(
  hToken: THandle;
  out IsLPAC: Boolean
): TNtxStatus;

// Set if an AppContainer token is a Less Privileged AppContainer
function NtxSetLpacToken(
  hToken: THandle;
  IsLPAC: Boolean
): TNtxStatus;

// Query token claim attributes
function NtxQueryClaimsToken(
  hToken: THandle;
  InfoClass: TTokenInformationClass;
  out Claims: TArray<TSecurityAttribute>
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, NtUtils.Version, NtUtils.Security.Acl,
  NtUtils.Objects, NtUtils.Tokens.Misc, NtUtils.Security.Sid,
  DelphiUtils.AutoObject, DelphiUtils.Arrays, NtUtils.Lsa.Sid;

function NtxpExpandPseudoTokenForQuery;
begin
  // Pseudo-handles are supported only starting from Win 8
  // and only for query operations

  if (hToken <= MAX_HANDLE) or RtlOsVersionAtLeast(OsWin8) then
  begin
    // Not a pseudo-handle or they are supported.
    // Capture, but do not close automatically.
    Result.Status := STATUS_SUCCESS;
    hxToken := TAutoHandle.Capture(hToken);
    hxToken.AutoRelease := False;
  end
  else
  begin
    // This is a pseudo-handle, and they are not supported, open a real one
    Result := NtxOpenPseudoToken(hxToken, hToken, DesiredAccess);
  end;
end;

function NtxQueryToken;
var
  hxToken: IHandle;
  DesiredAccess: TTokenAccessMask;
  Required: Cardinal;
begin
  DesiredAccess := ExpectedTokenQueryAccess(InfoClass);

  // Make sure pseudo-handles are supported
  Result := NtxpExpandPseudoTokenForQuery(hxToken, hToken, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryInformationToken';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(DesiredAccess);
  Result.LastCall.ExpectedPrivilege := ExpectedTokenQueryPrivilege(InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationToken(hxToken.Handle, InfoClass,
      xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxSetToken;
var
  hxToken: IHandle;
  DesiredAccess: TTokenAccessMask;
begin
  DesiredAccess := ExpectedTokenSetAccess(InfoClass);

  // Always expand pseudo-tokens for setting information
  Result := NtxExpandPseudoToken(hxToken, hToken, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtSetInformationToken';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(DesiredAccess);
  Result.LastCall.ExpectedPrivilege := ExpectedTokenSetPrivilege(InfoClass);

  Result.Status := NtSetInformationToken(hxToken.Handle, InfoClass,
    TokenInformation, TokenInformationLength);
end;

class function NtxToken.Query<T>;
var
  hxToken: IHandle;
  DesiredAccess: TTokenAccessMask;
  ReturnedBytes: Cardinal;
begin
  DesiredAccess := ExpectedTokenQueryAccess(InfoClass);

  // Make sure pseudo-handles are supported
  Result := NtxpExpandPseudoTokenForQuery(hxToken, hToken, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryInformationToken';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(DesiredAccess);
  Result.LastCall.ExpectedPrivilege := ExpectedTokenQueryPrivilege(InfoClass);

  Result.Status := NtQueryInformationToken(hxToken.Handle, InfoClass, @Buffer,
    SizeOf(Buffer), ReturnedBytes);
end;

class function NtxToken.&Set<T>;
begin
  Result := NtxSetToken(hToken, InfoClass, @Buffer, SizeOf(Buffer));
end;

{ Typed queries }

function NtxQuerySidToken;
var
  xMemory: IMemory<PTokenSidInformation>;
begin
  Result := NtxQueryToken(hToken, InfoClass, IMemory(xMemory),
    SECURITY_MAX_SID_SIZE);

  if Result.IsSuccess and Assigned(xMemory.Data.Sid) then
    Result := RtlxCopySid(xMemory.Data.Sid, Sid);
end;

function NtxQueryGroupToken;
var
  xMemory: IMemory<PSidAndAttributes>;
begin
  Result := NtxQueryToken(hToken, InfoClass, IMemory(xMemory),
    SECURITY_MAX_SID_SIZE + SizeOf(Cardinal));

  if Result.IsSuccess then
  begin
    Group.Attributes := xMemory.Data.Attributes;

    if Assigned(xMemory.Data.Sid) then
      Result := RtlxCopySid(xMemory.Data.Sid, Group.Sid)
    else
      Group.Sid := nil;
  end;
end;

function NtxQueryGroupsToken;
var
  xMemory: IMemory<PTokenGroups>;
  i: Integer;
begin
  Result := NtxQueryToken(hToken, InfoClass, IMemory(xMemory));

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
  Result := NtxQuerySidToken(hToken, TokenUser, User);

  if Result.IsSuccess then
    SDDL := RtlxSidToString(User.Data)

  // Ask LSA for help if we can't open our token
  else if (hToken = NtCurrentEffectiveToken) and
    LsaxGetFullUserName(UserName).IsSuccess and
    LsaxLookupName(UserName, User).IsSuccess then
  begin
    SDDL := RtlxSidToString(User.Data);
    Result.Status := STATUS_SUCCESS;
  end;
end;

function NtxQueryPrivilegesToken;
var
  xMemory: IMemory<PTokenPrivileges>;
  i: Integer;
begin
  Result := NtxQueryToken(hToken, TokenPrivileges, IMemory(xMemory),
    SizeOf(Integer) + SizeOf(TPrivilege) * SE_MAX_WELL_KNOWN_PRIVILEGE);

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
  Result := NtxQueryToken(hToken, TokenDefaultDacl, IMemory(xMemory));

  if Result.IsSuccess and Assigned(xMemory.Data.DefaultDacl) then
    Result := RtlxCopyAcl(xMemory.Data.DefaultDacl, DefaultDacl)
  else
    DefaultDacl := nil;
end;

function NtxSetDefaultDaclToken;
var
  Dacl: TTokenDefaultDacl;
begin
  if Assigned(DefaultDacl) then
    Dacl.DefaultDacl := DefaultDacl.Data
  else
    Dacl.DefaultDacl := nil;

  Result := NtxToken.&Set(hToken, TokenDefaultDacl, Dacl);
end;

function NtxQueryFlagsToken;
var
  xMemory: IMemory<PTokenAccessInformation>;
begin
  Result := NtxQueryToken(hToken, TokenAccessInformation, IMemory(xMemory));

  if Result.IsSuccess then
    Flags := xMemory.Data.Flags;
end;

function NtxQueryIntegrityToken;
var
  IntegritySid: TGroup;
begin
  Result := NtxQueryGroupToken(hToken, TokenIntegrityLevel, IntegritySid);

  if not Result.IsSuccess then
    Exit;

  // The last sub-authority is the level
  if Assigned(IntegritySid.Sid) then
    IntegrityLevel := RtlxRidSid(IntegritySid.Sid.Data,
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
  Result := RtlxNewSid(LabelSid, SECURITY_MANDATORY_LABEL_AUTHORITY,
    [IntegrityLevel]);

  if not Result.IsSuccess then
    Exit;

  MandatoryLabel.Sid := LabelSid.Data;
  MandatoryLabel.Attributes := SE_GROUP_INTEGRITY_ENABLED;

  Result := NtxToken.&Set(hToken, TokenIntegrityLevel, MandatoryLabel);
end;

function NtxQueryAttributesToken;
var
  xMemory: IMemory<PTokenSecurityAttributes>;
begin
  Result := NtxQueryToken(hToken, InfoClass, IMemory(xMemory));

  if Result.IsSuccess then
    Attributes := NtxpParseSecurityAttributes(xMemory.Data);
end;

function NtxQueryAttributesByNameToken;
var
  hxToken: IHandle;
  NameStrings: TArray<TNtUnicodeString>;
  xMemory: IMemory<PTokenSecurityAttributes>;
  Required: Cardinal;
begin
  // Windows 7 supports this function, but can't handle pseudo-tokens yet
  Result := NtxpExpandPseudoTokenForQuery(hxToken, hToken, TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQuerySecurityAttributesToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);

  // Convert attribute names to UNICODE_STRINGs
  NameStrings := TArray.Map<String, TNtUnicodeString>(AttributeNames,
    TNtUnicodeString.From);

  IMemory(xMemory) := TAutoMemory.Allocate(0);
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
      Operations[i] := TokenAttributeReplace;
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

  Result := NtxToken.&Set(hToken, TokenSecurityAttributes, Buffer);
end;

function NtxQueryLpacToken;
var
  Attributes: TArray<TSecurityAttribute>;
begin
  // This security attribute indicates Less Privileged AppContainer
  Result := NtxQueryAttributesByNameToken(hToken, ['WIN://NOALLAPPPKG'],
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
    Operation := TokenAttributeReplace
  else
    Operation := TokenAttributeDelete;

  Result := NtxSetAttributesToken(hToken, [Attribute], [Operation]);

  // Suceed if it is already a non-LPAC token
  if not IsLPAC and (Result.Status = STATUS_NOT_FOUND) then
    Result.Status := STATUS_SUCCESS;  
end;

function NtxQueryClaimsToken;
var
  xMemory: IMemory<PClaimSecurityAttributes>;
begin
  Result := NtxQueryToken(hToken, InfoClass, IMemory(xMemory));

  if Result.IsSuccess then
    Claims := NtxpParseClaimAttributes(xMemory.Data);
end;

end.
