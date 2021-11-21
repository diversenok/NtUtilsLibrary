unit NtUtils.Security.Sid;

{
  The module adds support for common operations on Security Identifiers.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.securitybaseapi, NtUtils;

{ Construction }

// Build a new SID
function RtlxCreateSid(
  out Sid: ISid;
  const IdentifyerAuthority: TSidIdentifierAuthority;
  [opt] const SubAuthouritiesArray: TArray<Cardinal> = nil
): TNtxStatus;

// Validate the intput buffer and capture a copy as a SID
function RtlxCopySid(
  [in] Buffer: PSid;
  out NewSid: ISid
): TNtxStatus;

{ Information }

// Retrieve a copy of identifier authority of a SID as UIn64
function RtlxIdentifierAuthoritySid(
  const Sid: ISid
): UInt64;

// Retrieve an array of sub-authorities of a SID
function RtlxSubAuthoritiesSid(
  const Sid: ISid
): TArray<Cardinal>;

// Retrieve the RID (the last sub-authority) of a SID
function RtlxRidSid(
  const Sid: ISid;
  Default: Cardinal = 0
): Cardinal;

// Construct a child SID (add a sub authority)
function RtlxMakeChildSid(
  out ChildSid: ISid;
  const ParentSid: ISid;
  Rid: Cardinal
): TNtxStatus;

// Construct a parent SID (remove the last sub authority)
function RtlxMakeParentSid(
  out ParentSid: ISid;
  const ChildSid: ISid
): TNtxStatus;

// Construct a sibling SID (change the last sub authority)
function RtlxMakeSiblingSid(
  out SiblingSid: ISid;
  const SourceSid: ISid;
  Rid: Cardinal
): TNtxStatus;

{ SDDL }

// Convert a SID to its SDDL representation
function RtlxSidToString(
  const Sid: ISid
): String;

// Convert SDDL string to a SID
function RtlxStringToSid(
  const SDDL: String;
  out Sid: ISid
): TNtxStatus;

// A converter from SDDL string to a SID for use with array conversion
function RtlxStringToSidConverter(
  const SDDL: String;
  out Sid: ISid
): Boolean;

{ Well known SIDs }

// Derive a service SID from a service name
function RtlxCreateServiceSid(
  const ServiceName: String;
  out Sid: ISid
): TNtxStatus;

// Construct a well-known SID
function SddlxCreateWellKnownSid(
  WellKnownSidType: TWellKnownSidType;
  out Sid: ISid
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.WinBase, Ntapi.Sddl,
  NtUtils.SysUtils;

 { Construction }

function RtlxCreateSid;
var
  i: Integer;
begin
  IMemory(Sid) := Auto.AllocateDynamic(
    RtlLengthRequiredSid(Length(SubAuthouritiesArray)));

  Result.Location := 'RtlInitializeSid';
  Result.Status := RtlInitializeSid(Sid.Data, @IdentifyerAuthority,
    Length(SubAuthouritiesArray));

  // Fill in the sub authorities
  if Result.IsSuccess then
    for i := 0 to High(SubAuthouritiesArray) do
      RtlSubAuthoritySid(Sid.Data, i)^ := SubAuthouritiesArray[i];
end;

function RtlxCopySid;
begin
  if not Assigned(Buffer) or not RtlValidSid(Buffer) then
  begin
    Result.Location := 'RtlValidSid';
    Result.Status := STATUS_INVALID_SID;
    Exit;
  end;

  IMemory(NewSid) := Auto.AllocateDynamic(RtlLengthSid(Buffer));

  Result.Location := 'RtlCopySid';
  Result.Status := RtlCopySid(RtlLengthSid(Buffer), NewSid.Data, Buffer);
end;

 { Information }

function RtlxIdentifierAuthoritySid;
begin
  Result := RtlIdentifierAuthoritySid(Sid.Data)^;
end;

function RtlxSubAuthoritiesSid;
var
  i: Integer;
begin
  SetLength(Result, RtlSubAuthorityCountSid(Sid.Data)^);

  for i := 0 to High(Result) do
    Result[i] := RtlSubAuthoritySid(Sid.Data, i)^;
end;

function RtlxRidSid;
begin
  if RtlSubAuthorityCountSid(Sid.Data)^ > 0 then
    Result := RtlSubAuthoritySid(Sid.Data,
      RtlSubAuthorityCountSid(Sid.Data)^ - 1)^
  else
    Result := Default;
end;

function RtlxMakeChildSid;
begin
  // Add a new sub authority at the end
  Result := RtlxCreateSid(ChildSid, RtlIdentifierAuthoritySid(ParentSid.Data)^,
    Concat(RtlxSubAuthoritiesSid(ParentSid), [Rid]));
end;

function RtlxMakeParentSid;
var
  SubAuthorities: TArray<Cardinal>;
begin
  // Retrieve existing sub authorities
  SubAuthorities := RtlxSubAuthoritiesSid(ChildSid);

  if Length(SubAuthorities) > 0 then
  begin
    // Drop the last one
    Delete(SubAuthorities, High(SubAuthorities), 1);
    Result := RtlxCreateSid(ParentSid,
      RtlIdentifierAuthoritySid(ChildSid.Data)^, SubAuthorities);
  end
  else
  begin
    // No parent SID available
    Result.Location := 'RtlxMakeParentSid';
    Result.Status := STATUS_INVALID_SID;
  end;
end;

function RtlxMakeSiblingSid;
var
  SubAuthorities: TArray<Cardinal>;
begin
  SubAuthorities := RtlxSubAuthoritiesSid(SourceSid);

  if Length(SubAuthorities) > 0 then
  begin
    // Replace the RID
    SubAuthorities[High(SubAuthorities)] := Rid;
    Result := RtlxCreateSid(SiblingSid,
      RtlIdentifierAuthoritySid(SourceSid.Data)^, SubAuthorities);
  end
  else
  begin
    // No RID present
    Result.Location := 'RtlxMakeSiblingSid';
    Result.Status := STATUS_INVALID_SID;
  end;
end;

 { SDDL }

function RtlxSidToString;
var
  SDDL: TNtUnicodeString;
  Buffer: array [0 .. SECURITY_MAX_SID_STRING_CHARACTERS - 1] of WideChar;
begin
  case RtlxIdentifierAuthoritySid(SID) of

    // Integrity: S-1-16-x
    SECURITY_MANDATORY_LABEL_AUTHORITY:
      if RtlSubAuthorityCountSid(SID.Data)^ = 1 then
        Exit('S-1-16-' + RtlxUIntToStr(RtlSubAuthoritySid(SID.Data, 0)^,
          16, 4));

    // Trust: S-1-19-X-X
    SECURITY_PROCESS_TRUST_AUTHORITY:
      if RtlSubAuthorityCountSid(SID.Data)^ = 2 then
        Exit('S-1-19-' + RtlxUIntToStr(RtlSubAuthoritySid(SID.Data, 0)^,
          16, 3) + '-' + RtlxUIntToStr(RtlSubAuthoritySid(SID.Data, 1)^, 16, 4));
  end;

  SDDL.Length := 0;
  SDDL.MaximumLength := SizeOf(Buffer);
  SDDL.Buffer := Buffer;

  if NT_SUCCESS(RtlConvertSidToUnicodeString(SDDL, Sid.Data, False)) then
    Result := SDDL.ToString
  else
    Result := '(invalid SID)';
end;

function TryStrToUInt64Ex(S: String; out Value: UInt64): Boolean;
var
  E: Integer;
begin
  if RtlxPrefixString('0x', S) then
  begin
    Delete(S, Low(S), 2);
    Insert('$', S, Low(S));
  end;

  Val(S, Value, E);
  Result := (E = 0);
end;

function TryParseLogonIDs(
  StringSid: String;
  out Sid: ISid
): Boolean;
const
  FULL_PREFIX = 'NT AUTHORITY\LogonSessionId_';
  SHORT_PREFIX = 'LogonSessionId_';
var
  SplitIndex: Integer;
  LogonIdHighString, LogonIdLowString: String;
  LogonIdHigh, LogonIdLow: Cardinal;
  i: Integer;
begin
  // Check if the string has the logon SID prefix and strip it
  if RtlxPrefixString(FULL_PREFIX, StringSid) then
    StringSid := Copy(StringSid, Length(FULL_PREFIX) + 1, Length(StringSid))
  else if RtlxPrefixString(SHORT_PREFIX, StringSid) then
    StringSid := Copy(StringSid, Length(SHORT_PREFIX) + 1, Length(StringSid))
  else
    Exit(False);

  // Find the underscore between high and low parts
  SplitIndex := -1;

  for i := Low(StringSid) to High(StringSid) do
    if StringSid[i] = '_' then
    begin
      SplitIndex := i;
      Break;
    end;

  if SplitIndex < 0 then
    Exit(False);

  // Split the string
  LogonIdHighString := Copy(StringSid, 1, SplitIndex - Low(String));
  LogonIdLowString := Copy(StringSid, SplitIndex - Low(String) + 2,
    Length(StringSid) - SplitIndex + Low(String));

  // Parse and construct the SID
  Result :=
    (Length(LogonIdHighString) > 0) and
    (Length(LogonIdLowString) > 0) and
    RtlxStrToUInt(LogonIdHighString, LogonIdHigh) and
    RtlxStrToUInt(LogonIdLowString, LogonIdLow) and
    RtlxCreateSid(Sid, SECURITY_NT_AUTHORITY,
      [SECURITY_LOGON_IDS_RID, LogonIdHigh, LogonIdLow]).IsSuccess;
end;

function RtlxStringToSid;
var
  Buffer: PSid;
  IdAuthority: UInt64;
begin
  // Despite the fact that RtlConvertSidToUnicodeString can convert SIDs with
  // zero sub authorities to SDDL, ConvertStringSidToSidW (for some reason)
  // can't convert them back. Fix this behaviour by parsing them manually.

  // Expected formats for an SID with 0 sub authorities:
  //        S-1-(\d+)     |     S-1-(0x[A-F\d]+)
  // where the value fits into a 6-byte (48-bit) buffer

  if RtlxPrefixString('S-1-', SDDL) and
    TryStrToUInt64Ex(Copy(SDDL, Length('S-1-') + 1, Length(SDDL)), IdAuthority)
    and (IdAuthority < UInt64(1) shl 48) then
  begin
    Result := RtlxCreateSid(Sid, IdAuthority);
    Exit;
  end;

  // LSA lookup functions automatically convert S-1-5-5-X-Y to
  // NT AUTHORITY\LogonSessionId_X_Y and then refuse to parse it back.
  // While this issue is not technically related to SDDL, we fix it here
  // since that's the place where we already use similar parsing logic.

  if TryParseLogonIDs(SDDL, Sid) then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Usual SDDL conversion
  Result.Location := 'ConvertStringSidToSidW';
  Result.Win32Result := ConvertStringSidToSidW(PWideChar(SDDL), Buffer);

  if Result.IsSuccess then
  begin
    Result := RtlxCopySid(Buffer, Sid);
    LocalFree(Buffer);
  end;
end;

function RtlxStringToSidConverter;
begin
  // Use this function with TArrayHelper.Convert<String, ISid>
  Result := RtlxStringToSid(SDDL, Sid).IsSuccess;
end;

 { Well-known SIDs }

function RtlxCreateServiceSid;
var
  SidLength: Cardinal;
begin
  Result.Location := 'RtlCreateServiceSid';

  SidLength := 0;
  IMemory(Sid) := Auto.AllocateDynamic(SidLength);
  repeat
    Result.Status := RtlCreateServiceSid(TNtUnicodeString.From(ServiceName),
      Sid.Data, SidLength);
  until not NtxExpandBufferEx(Result, IMemory(Sid), SidLength, nil);
end;

function SddlxCreateWellKnownSid;
var
  Required: Cardinal;
begin
  Result.Location := 'CreateWellKnownSid';

  IMemory(Sid) := Auto.AllocateDynamic(0);
  repeat
    Required := Sid.Size;
    Result.Win32Result := CreateWellKnownSid(WellKnownSidType, nil, Sid.Data,
      Required);
  until not NtxExpandBufferEx(Result, IMemory(Sid), Required, nil);
end;

end.
