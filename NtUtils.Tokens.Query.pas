unit NtUtils.Tokens.Query;

interface

{ NOTE: All query/set functions here support pseudo-handles on all OS versions }

uses
  Winapi.WinNt, Ntapi.ntseapi, NtUtils.Exceptions, NtUtils.Security.Sid,
  NtUtils.Security.Acl, NtUtils.Objects;

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
function NtxSetIntegrityToken(hToken: THandle; IntegrityLevel: Cardinal):
  TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.Access.Expected, Ntapi.ntpebteb, NtUtils.Tokens;

function NtxpExpandPseudoTokenForQuery(out hxToken: IHandle; hToken: THandle;
  DesiredAccess: TAccessMask): TNtxStatus;
begin
  // Pseudo-handles are supported only starting from Win 8 (OS version is 6.2)
  // and only for query operations

  if (hToken <= MAX_HANDLE) or (RtlGetCurrentPeb.OSMajorVersion > 6) or
    ((RtlGetCurrentPeb.OSMajorVersion = 6) and
     (RtlGetCurrentPeb.OSMinorVersion >= 2)) then
  begin
    // Not a pseudo-handle or they are supported.
    // Capture, but do not close automatically.
    Result.Status := STATUS_SUCCESS;
    hxToken := TAutoHandle.Capture(hToken);
    hxToken.AutoClose := False;
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
    Result.Status := NtQueryInformationToken(hxToken.Value, InfoClass, Buffer,
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
  // Always expand pseudo-tokens, they are no good for setting information

  if hToken > MAX_HANDLE then
  begin
    DesiredAccess := TOKEN_ADJUST_DEFAULT;

    if InfoClass = TokenSessionId then
      DesiredAccess := DesiredAccess or TOKEN_ADJUST_SESSIONID;

    // Open a real token
    Result := NtxOpenPseudoToken(hxToken, hToken, DesiredAccess);

    if not Result.IsSuccess then
      Exit;
  end
  else
  begin
    // Not a pseudo-handle. Capture, but do not close.
    hxToken := TAutoHandle.Capture(hToken);
    hxToken.AutoClose := False;
  end;

  Result.Location := 'NtSetInformationToken';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTokenInformationClass);
  RtlxComputeTokenSetAccess(Result.LastCall, InfoClass);

  Result.Status := NtSetInformationToken(hxToken.Value, InfoClass,
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

  Result.Status := NtQueryInformationToken(hxToken.Value, InfoClass, @Buffer,
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
    Result := RtlxCaptureCopySid(PTokenOwner(xMemory).Owner, Sid);
end;

function NtxQueryGroupToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Group: TGroup): TNtxStatus;
var
  xMemory: IMemory;
  Buffer: PSidAndAttributes; // aka PTokenUser
begin
  Result := NtxQueryToken(hToken, InfoClass, xMemory, SECURITY_MAX_SID_SIZE +
    SizeOf(Cardinal));

  if Result.IsSuccess then
  begin
    Buffer := xMemory.Address;
    Group.Attributes := Buffer.Attributes;
    Result := RtlxCaptureCopySid(Buffer.Sid, Group.SecurityIdentifier);
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
    Buffer := xMemory.Address;
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
    Buffer := xMemory.Address;
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
    Buffer := xMemory.Address;
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
    Flags := PTokenAccessInformation(xMemory.Address).Flags;
end;

function NtxSetIntegrityToken(hToken: THandle; IntegrityLevel: Cardinal):
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

end.
