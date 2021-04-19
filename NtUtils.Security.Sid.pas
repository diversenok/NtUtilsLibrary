unit NtUtils.Security.Sid;

{
  The module adds support for common operations on Security Identifiers.
}

interface

uses
  Winapi.WinNt, Ntapi.ntseapi, Winapi.securitybaseapi, NtUtils,
  DelphiUtils.AutoObject;

{ Construction }

// Allocate a new SID
function RtlxAllocateSid(
  out Sid: ISid;
  const IdentifyerAuthority: TSidIdentifierAuthority;
  SubAuthorities: Byte
): TNtxStatus;

// Build a new SID
function RtlxNewSid(
  out Sid: ISid;
  const IdentifyerAuthority: TSidIdentifierAuthority;
  [opt] const SubAuthouritiesArray: TArray<Cardinal> = nil
): TNtxStatus;

// Validate the intput buffer and capture a copy as a SID
function RtlxCopySid(
  const SourceSid: PSid;
  out NewSid: ISid
): TNtxStatus;

{ Information }

// Retrieve an array of sub-authorities of a SID
function RtlxSubAuthoritiesSid(
  [in] Sid: PSid
): TArray<Cardinal>;

// Retrieve the RID (the last sub-authority) of a SID
function RtlxRidSid(
  [in] Sid: PSid;
  Default: Cardinal = 0
): Cardinal;

// Construct a child SID
function RtlxChildSid(
  out ChildSid: ISid;
  [in] ParentSid: PSid;
  Rid: Cardinal
): TNtxStatus;

// Construct a parent SID
function RtlxParentSid(
  out ParentSid: ISid;
  [in] ChildSid: PSid
): TNtxStatus;

{ SDDL }

// Convert a SID to its SDDL representation
function RtlxSidToString(
  [in] Sid: PSid
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
function SddlxGetWellKnownSid(
  out Sid: ISid;
  WellKnownSidType: TWellKnownSidType
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntstatus, Winapi.WinBase, Winapi.Sddl,
  NtUtils.SysUtils;

 { Construction }

function RtlxAllocateSid;
begin
  IMemory(Sid) := TAutoMemory.Allocate(RtlLengthRequiredSid(SubAuthorities));

  Result.Location := 'RtlInitializeSid';
  Result.Status := RtlInitializeSid(Sid.Data, @IdentifyerAuthority,
    SubAuthorities);
end;

function RtlxNewSid;
var
  i: Integer;
begin
  IMemory(Sid) := TAutoMemory.Allocate(
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
  if not Assigned(SourceSid) or not RtlValidSid(SourceSid) then
  begin
    Result.Location := 'RtlValidSid';
    Result.Status := STATUS_INVALID_SID;
    Exit;
  end;

  IMemory(NewSid) := TAutoMemory.Allocate(RtlLengthSid(SourceSid));

  Result.Location := 'RtlCopySid';
  Result.Status := RtlCopySid(RtlLengthSid(SourceSid), NewSid.Data, SourceSid);
end;

 { Information }

function RtlxSubAuthoritiesSid;
var
  i: Integer;
begin
  SetLength(Result, RtlSubAuthorityCountSid(Sid)^);

  for i := 0 to High(Result) do
    Result[i] := RtlSubAuthoritySid(Sid, i)^;
end;

function RtlxRidSid;
begin
  if RtlSubAuthorityCountSid(Sid)^ > 0 then
    Result := RtlSubAuthoritySid(Sid, RtlSubAuthorityCountSid(Sid)^ - 1)^
  else
    Result := Default;
end;

function RtlxChildSid;
begin
  // Add a new sub authority at the end
  Result := RtlxNewSid(ChildSid, RtlIdentifierAuthoritySid(ParentSid)^,
    Concat(RtlxSubAuthoritiesSid(ParentSid), [Rid]));
end;

function RtlxParentSid;
var
  SubAuthorities: TArray<Cardinal>;
begin
  // Retrieve existing sub authorities
  SubAuthorities := RtlxSubAuthoritiesSid(ChildSid);

  if Length(SubAuthorities) > 0 then
  begin
    // Drop the last one
    Delete(SubAuthorities, High(SubAuthorities), 1);
    Result := RtlxNewSid(ParentSid, RtlIdentifierAuthoritySid(ChildSid)^,
      SubAuthorities);
  end
  else
  begin
    // No parent SID available
    Result.Location := 'RtlxParentSid';
    Result.Status := STATUS_INVALID_SID;
  end;
end;

 { SDDL }

function RtlxpApplySddlOverrides([in] Sid: PSid; var SDDL: String): Boolean;
begin
  Result := False;

  // We override convertion of some SIDs to strings for the sake of readability.
  // The results are still valid SDDLs.

  case RtlIdentifierAuthoritySid(SID).ToInt64 of

    // Integrity: S-1-16-x
    SECURITY_MANDATORY_LABEL_AUTHORITY_ID:
      if RtlSubAuthorityCountSid(SID)^ = 1 then
      begin
        SDDL := 'S-1-16-' + RtlxIntToStr(RtlSubAuthoritySid(SID, 0)^, 16, 4);
        Result := True;
      end;

  end;
end;

function RtlxSidToString;
var
  SDDL: TNtUnicodeString;
  Buffer: array [0 .. SECURITY_MAX_SID_STRING_CHARACTERS - 1] of WideChar;
begin
  Result := '';

  if RtlxpApplySddlOverrides(SID, Result) then
    Exit;

  SDDL.Length := 0;
  SDDL.MaximumLength := SizeOf(Buffer);
  SDDL.Buffer := Buffer;

  if NT_SUCCESS(RtlConvertSidToUnicodeString(SDDL, Sid, False)) then
    Result := SDDL.ToString
  else
    Result := '(invalid SID)';
end;

function TryStrToUInt64Ex(S: String; out Value: UInt64): Boolean;
var
  E: Integer;
begin
  if RtlxPrefixString('0x', S, True) then
  begin
    Delete(S, Low(S), 2);
    Insert('$', S, Low(S));
  end;

  Val(S, Value, E);
  Result := (E = 0);
end;

function RtlxStringToSid;
var
  Buffer: PSid;
  IdAuthorityUInt64: UInt64;
  IdAuthority: TSidIdentifierAuthority;
begin
  // Despite the fact that RtlConvertSidToUnicodeString can convert SIDs with
  // zero sub authorities to SDDL, ConvertStringSidToSidW (for some reason)
  // can't convert them back. Fix this behaviour by parsing them manually.

  // Expected formats for an SID with 0 sub authorities:
  //        S-1-(\d+)     |     S-1-(0x[A-F\d]+)
  // where the value fits into a 6-byte (48-bit) buffer

  if RtlxPrefixString('S-1-', SDDL, True) and
    TryStrToUInt64Ex(Copy(SDDL, Length('S-1-') + 1, Length(SDDL)),
    IdAuthorityUInt64) and (IdAuthorityUInt64 < UInt64(1) shl 48) then
  begin
    IdAuthority.FromInt64(IdAuthorityUInt64);
    Result := RtlxNewSid(Sid, IdAuthority);
  end
  else
  begin
    // Usual SDDL conversion
    Result.Location := 'ConvertStringSidToSidW';
    Result.Win32Result := ConvertStringSidToSidW(PWideChar(SDDL), Buffer);

    if Result.IsSuccess then
    begin
      Result := RtlxCopySid(Buffer, Sid);
      LocalFree(Buffer);
    end;
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
  IMemory(Sid) := TAutoMemory.Allocate(SidLength);
  repeat
    Result.Status := RtlCreateServiceSid(TNtUnicodeString.From(ServiceName),
      Sid.Data, SidLength);
  until not NtxExpandBufferEx(Result, IMemory(Sid), SidLength, nil);
end;

function SddlxGetWellKnownSid;
var
  Required: Cardinal;
begin
  Result.Location := 'CreateWellKnownSid';

  IMemory(Sid) := TAutoMemory.Allocate(0);
  repeat
    Required := Sid.Size;
    Result.Win32Result := CreateWellKnownSid(WellKnownSidType, nil, Sid.Data,
      Required);
  until not NtxExpandBufferEx(Result, IMemory(Sid), Required, nil);
end;

end.
