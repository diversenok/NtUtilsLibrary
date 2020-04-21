unit NtUtils.Tokens.Query;

interface

{ NOTE: All query/set functions here support pseudo-handles on all OS versions }

uses
  Winapi.WinNt, Ntapi.ntseapi, NtUtils, NtUtils.Security.Sid,
  NtUtils.Security.Acl, NtUtils.Objects, NtUtils.Tokens;

type
  TSecurityAttribute = NtUtils.Tokens.TSecurityAttribute;

// Make sure pseudo-handles are supported for querying
function NtxpExpandPseudoTokenForQuery(out hxToken: IHandle; hToken: THandle;
  DesiredAccess: TAccessMask): TNtxStatus;

// Query variable-length token information without race conditions
function NtxQueryToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out xMemory: IMemory; StartBufferSize: Cardinal = 0): TNtxStatus;

// Set variable-length token information
function NtxSetToken(hToken: THandle; InfoClass: TTokenInformationClass;
  TokenInformation: Pointer; TokenInformationLength: Cardinal): TNtxStatus;

type
  NtxToken = class
    // Query fixed-size information
    class function Query<T>(hToken: THandle;
      InfoClass: TTokenInformationClass; out Buffer: T): TNtxStatus; static;

    // Set fixed-size information
    class function SetInfo<T>(hToken: THandle;
      InfoClass: TTokenInformationClass; const Buffer: T): TNtxStatus; static;
  end;

// Query a SID (Owner, Primary group, ...)
function NtxQuerySidToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Sid: ISid): TNtxStatus;

// Query a SID and attributes (User, Integrity, ...)
function NtxQueryGroupToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Group: TGroup): TNtxStatus;

// Query groups (Groups, RestrictingSIDs, LogonSIDs, ...)
function NtxQueryGroupsToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Groups: TArray<TGroup>): TNtxStatus;

// Query privileges
function NtxQueryPrivilegesToken(hToken: THandle;
  out Privileges: TArray<TPrivilege>): TNtxStatus;

// Query default DACL
function NtxQueryDefaultDaclToken(hToken: THandle; out DefaultDacl: IAcl):
  TNtxStatus;

// Set default DACL
function NtxSetDefaultDaclToken(hToken: THandle; DefaultDacl: IAcl): TNtxStatus;

// Query token flags
function NtxQueryFlagsToken(hToken: THandle; out Flags: Cardinal): TNtxStatus;

// Set integrity level of a token
function NtxSetIntegrityToken(hToken: THandle; IntegrityLevel: TIntegriyRid):
  TNtxStatus;

// Query all security attributes of a token
function NtxQueryAttributesToken(hToken: THandle; InfoClass:
  TTokenInformationClass; out Attributes: TArray<TSecurityAttribute>):
  TNtxStatus;

// Query security attributes of a token by names
function NtxQueryAttributesByNameToken(hToken: THandle; AttributeNames:
  TArray<String>; out Attributes: TArray<TSecurityAttribute>): TNtxStatus;

// Set or remove security attibutes of a token
function NtxSetAttributesToken(hToken: THandle; Attributes:
  TArray<TSecurityAttribute>; Operations: TArray<TTokenAttributeOperation> =
  nil): TNtxStatus;
  
// Check if a token is a Less Privileged AppContainer token
function NtxQueryLpacToken(hToken: THandle; out IsLPAC: Boolean): TNtxStatus;

// Set if an AppContainer token is a Less Privileged AppContainer
function NtxSetLpacToken(hToken: THandle; IsLPAC: Boolean): TNtxStatus;

// Query token claim attributes
function NtxQueryClaimsToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Claims: TArray<TSecurityAttribute>): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, NtUtils.Version, NtUtils.Access.Expected,
  NtUtils.Tokens.Misc, DelphiUtils.AutoObject;

function NtxpExpandPseudoTokenForQuery(out hxToken: IHandle; hToken: THandle;
  DesiredAccess: TAccessMask): TNtxStatus;
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

function NtxQueryToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out xMemory: IMemory; StartBufferSize: Cardinal = 0): TNtxStatus;
var
  hxToken: IHandle;
  Buffer: Pointer;
  BufferSize, Required: Cardinal;
begin
  // Make sure pseudo-handles are supported
  if InfoClass = TokenSource then
    Result := NtxpExpandPseudoTokenForQuery(hxToken, hToken, TOKEN_QUERY_SOURCE)
  else
    Result := NtxpExpandPseudoTokenForQuery(hxToken, hToken, TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryInformationToken';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTokenInformationClass);
  RtlxComputeTokenQueryAccess(Result.LastCall, InfoClass);

  BufferSize := StartBufferSize;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryInformationToken(hxToken.Handle, InfoClass, Buffer,
      BufferSize, Required);

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;

  until not NtxExpandBuffer(Result, BufferSize, Required);

  if Result.IsSuccess then
    xMemory := TAutoMemory.Capture(Buffer, BufferSize);
end;

function NtxSetToken(hToken: THandle; InfoClass: TTokenInformationClass;
  TokenInformation: Pointer; TokenInformationLength: Cardinal): TNtxStatus;
var
  hxToken: IHandle;
  DesiredAccess: TAccessMask;
begin
  case InfoClass of
    TokenSessionId:
      DesiredAccess := TOKEN_ADJUST_DEFAULT or TOKEN_ADJUST_SESSIONID;

    TokenLinkedToken:
      DesiredAccess := TOKEN_ADJUST_DEFAULT or TOKEN_QUERY
  else
    DesiredAccess := TOKEN_ADJUST_DEFAULT;
  end;

  // Always expand pseudo-tokens for setting information
  Result := NtxExpandPseudoToken(hxToken, hToken, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtSetInformationToken';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTokenInformationClass);
  RtlxComputeTokenSetAccess(Result.LastCall, InfoClass);

  Result.Status := NtSetInformationToken(hxToken.Handle, InfoClass,
    TokenInformation, TokenInformationLength);
end;

class function NtxToken.Query<T>(hToken: THandle;
  InfoClass: TTokenInformationClass; out Buffer: T): TNtxStatus;
var
  hxToken: IHandle;
  ReturnedBytes: Cardinal;
begin
  // Make sure pseudo-handles are supported
  if InfoClass = TokenSource then
    Result := NtxpExpandPseudoTokenForQuery(hxToken, hToken, TOKEN_QUERY_SOURCE)
  else
    Result := NtxpExpandPseudoTokenForQuery(hxToken, hToken, TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryInformationToken';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTokenInformationClass);
  RtlxComputeTokenQueryAccess(Result.LastCall, InfoClass);

  Result.Status := NtQueryInformationToken(hxToken.Handle, InfoClass, @Buffer,
    SizeOf(Buffer), ReturnedBytes);
end;

class function NtxToken.SetInfo<T>(hToken: THandle;
  InfoClass: TTokenInformationClass; const Buffer: T): TNtxStatus;
begin
  Result := NtxSetToken(hToken, InfoClass, @Buffer, SizeOf(Buffer));
end;

{ Typed queries }

function NtxQuerySidToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Sid: ISid): TNtxStatus;
var
  xMemory: IMemory;
begin
  Result := NtxQueryToken(hToken, InfoClass, xMemory, SECURITY_MAX_SID_SIZE);

  if Result.IsSuccess then
    Result := RtlxCaptureCopySid(PTokenSidInformation(xMemory.Data).Sid,
      Sid);
end;

function NtxQueryGroupToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Group: TGroup): TNtxStatus;
var
  xMemory: IMemory;
  Buffer: PSidAndAttributes;
begin
  Result := NtxQueryToken(hToken, InfoClass, xMemory, SECURITY_MAX_SID_SIZE +
    SizeOf(Cardinal));

  if Result.IsSuccess then
  begin
    Buffer := xMemory.Data;
    Group.Attributes := Buffer.Attributes;

    if Assigned(Buffer.Sid) then
      Result := RtlxCaptureCopySid(Buffer.Sid, Group.SecurityIdentifier)
    else
      Group.SecurityIdentifier := nil;
  end;
end;

function NtxQueryGroupsToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Groups: TArray<TGroup>): TNtxStatus;
var
  xMemory: IMemory;
  Buffer: PTokenGroups;
  i: Integer;
begin
  Result := NtxQueryToken(hToken, InfoClass, xMemory);

  if Result.IsSuccess then
  begin
    Buffer := xMemory.Data;
    SetLength(Groups, Buffer.GroupCount);

    for i := 0 to High(Groups) do
    begin
      Groups[i].Attributes := Buffer.Groups{$R-}[i]{$R+}.Attributes;

      Result := RtlxCaptureCopySid(Buffer.Groups{$R-}[i]{$R+}.Sid,
        Groups[i].SecurityIdentifier);

      if not Result.IsSuccess then
        Break;
    end;
  end;
end;

function NtxQueryPrivilegesToken(hToken: THandle; out Privileges:
  TArray<TPrivilege>): TNtxStatus;
var
  xMemory: IMemory;
  Buffer: PTokenPrivileges;
  i: Integer;
begin
  Result := NtxQueryToken(hToken, TokenPrivileges, xMemory, SizeOf(Integer) +
    SizeOf(TLuidAndAttributes) * SE_MAX_WELL_KNOWN_PRIVILEGE);

  if Result.IsSuccess then
  begin
    Buffer := xMemory.Data;
    SetLength(Privileges, Buffer.PrivilegeCount);

    for i := 0 to High(Privileges) do
      Privileges[i] := Buffer.Privileges{$R-}[i]{$R+};
  end;
end;

function NtxQueryDefaultDaclToken(hToken: THandle; out DefaultDacl: IAcl):
  TNtxStatus;
var
  xMemory: IMemory;
  Buffer: PTokenDefaultDacl;
begin
  Result := NtxQueryToken(hToken, TokenDefaultDacl, xMemory);

  if Result.IsSuccess then
  begin
    Buffer := xMemory.Data;
    if Assigned(Buffer.DefaultDacl) then
      DefaultDacl := TAcl.CreateCopy(Buffer.DefaultDacl)
    else
      DefaultDacl := nil;
  end;
end;

function NtxSetDefaultDaclToken(hToken: THandle; DefaultDacl: IAcl): TNtxStatus;
var
  Dacl: TTokenDefaultDacl;
begin
  Dacl.DefaultDacl := DefaultDacl.Acl;
  Result := NtxToken.SetInfo(hToken, TokenDefaultDacl, Dacl);
end;

function NtxQueryFlagsToken(hToken: THandle; out Flags: Cardinal): TNtxStatus;
var
  xMemory: IMemory;
begin
  Result := NtxQueryToken(hToken, TokenAccessInformation, xMemory);

  if Result.IsSuccess then
    Flags := PTokenAccessInformation(xMemory.Data).Flags;
end;

function NtxSetIntegrityToken(hToken: THandle; IntegrityLevel: TIntegriyRid):
  TNtxStatus;
var
  LabelSid: ISid;
  MandatoryLabel: TSidAndAttributes;
begin
  // Prepare SID for integrity level with 1 sub authority: S-1-16-X.

  LabelSid := TSid.CreateNew(SECURITY_MANDATORY_LABEL_AUTHORITY, 1,
    IntegrityLevel);

  MandatoryLabel.Sid := LabelSid.Sid;
  MandatoryLabel.Attributes := SE_GROUP_INTEGRITY_ENABLED;

  Result := NtxToken.SetInfo(hToken, TokenIntegrityLevel, MandatoryLabel);
end;

function NtxQueryAttributesToken(hToken: THandle; InfoClass:
  TTokenInformationClass; out Attributes: TArray<TSecurityAttribute>):
  TNtxStatus;
var
  xMemory: IMemory;
begin
  Result := NtxQueryToken(hToken, InfoClass, xMemory);

  if Result.IsSuccess then
    Attributes := NtxpParseSecurityAttributes(xMemory.Data);
end;

function NtxQueryAttributesByNameToken(hToken: THandle; AttributeNames:
  TArray<String>; out Attributes: TArray<TSecurityAttribute>): TNtxStatus;
var
  hxToken: IHandle;
  NameStrings: TArray<UNICODE_STRING>;
  Buffer: PTokenSecurityAttributes;
  BufferSize, Required: Cardinal;
  i: Integer;
begin
  // Windows 7 supports this function, but can't handle pseudo-tokens yet
  Result := NtxpExpandPseudoTokenForQuery(hxToken, hToken, TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQuerySecurityAttributesToken';
  Result.LastCall.Expects(TOKEN_QUERY, @TokenAccessType);

  // Convert attribute names to UNICODE_STRINGs
  SetLength(NameStrings, Length(AttributeNames));
  for i := 0 to High(NameStrings) do
    NameStrings[i].FromString(AttributeNames[i]);

  BufferSize := 0;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQuerySecurityAttributesToken(hxToken.Handle, NameStrings,
      Length(NameStrings), Buffer, BufferSize, Required);

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, Required);

  if Result.IsSuccess then
  try
    // Parse the attributes
    Attributes := NtxpParseSecurityAttributes(Buffer);
  finally
    FreeMem(Buffer);
  end;
end;

function NtxSetAttributesToken(hToken: THandle; Attributes:
  TArray<TSecurityAttribute>; Operations: TArray<TTokenAttributeOperation>)
  : TNtxStatus;
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

  Result := NtxToken.SetInfo(hToken, TokenSecurityAttributes, Buffer);
end;

function NtxQueryLpacToken(hToken: THandle; out IsLPAC: Boolean): TNtxStatus;
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

function NtxSetLpacToken(hToken: THandle; IsLPAC: Boolean): TNtxStatus;
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

function NtxQueryClaimsToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Claims: TArray<TSecurityAttribute>): TNtxStatus;
var
  xMemory: IMemory;
begin
  Result := NtxQueryToken(hToken, InfoClass, xMemory);

  if Result.IsSuccess then
    Claims := NtxpParseClaimAttributes(xMemory.Data);
end;

end.
