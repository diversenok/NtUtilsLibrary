unit NtUtils.Security.Sid;

interface

uses
  Winapi.WinNt, Ntapi.ntseapi, Winapi.securitybaseapi, NtUtils,
  DelphiUtils.AutoObject;

{ Construction }

// Allocate a new SID
function RtlxAllocateSid(out Sid: ISid; const IdentifyerAuthority:
  TSidIdentifierAuthority; SubAuthorities: Byte): TNtxStatus;

// Build a new SID
function RtlxNewSid(out Sid: ISid; const IdentifyerAuthority:
  TSidIdentifierAuthority; SubAuthouritiesArray: TArray<Cardinal> = nil)
  : TNtxStatus;

// Validate the intput buffer and capture a copy as a SID
function RtlxCopySid(SourceSid: PSid; out NewSid: ISid): TNtxStatus;

{ Information }

// Retrieve an array of sub-authorities of a SID
function RtlxSubAuthoritiesSid(Sid: PSid): TArray<Cardinal>;

// Retrieve the RID (the last sub-authority) of a SID
function RtlxRidSid(Sid: PSid): Cardinal;

// Construct a child SID
function RtlxChildSid(out ChildSid: ISid; ParentSid: ISid; Rid: Cardinal):
  TNtxStatus;

// Construct a parent SID
function RtlxParentSid(out ParentSid: ISid; ChildSid: ISid): TNtxStatus;

{ SDDL }

// Convert a SID to its SDDL representation
function RtlxSidToString(Sid: PSid): String;

// Convert SDDL string to a SID
function RtlxStringToSid(SDDL: String; out Sid: ISid): TNtxStatus;
function RtlxStringToSidConverter(const SDDL: String; out Sid: ISid): Boolean;

{ Well known SIDs }

// Derive a service SID from a service name
function RtlxCreateServiceSid(ServiceName: String; out Sid: ISid): TNtxStatus;

// Construct a well-known SID
function SddlxGetWellKnownSid(out Sid: ISid; WellKnownSidType:
  TWellKnownSidType): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntstatus, Winapi.WinBase, Winapi.Sddl,
  NtUtils.SysUtils;

 { Construction }

function RtlxAllocateSid(out Sid: ISid; const IdentifyerAuthority:
  TSidIdentifierAuthority; SubAuthorities: Byte): TNtxStatus;
begin
  IMemory(Sid) := TAutoMemory.Allocate(RtlLengthRequiredSid(SubAuthorities));

  Result.Location := 'RtlInitializeSid';
  Result.Status := RtlInitializeSid(Sid.Data, @IdentifyerAuthority,
    SubAuthorities);
end;

function RtlxNewSid(out Sid: ISid; const IdentifyerAuthority:
  TSidIdentifierAuthority; SubAuthouritiesArray: TArray<Cardinal>): TNtxStatus;
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

function RtlxCopySid(SourceSid: PSid; out NewSid: ISid): TNtxStatus;
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

function RtlxSubAuthoritiesSid(Sid: PSid): TArray<Cardinal>;
var
  i: Integer;
begin
  SetLength(Result, RtlSubAuthorityCountSid(Sid)^);

  for i := 0 to High(Result) do
    Result[i] := RtlSubAuthoritySid(Sid, i)^;
end;

function RtlxRidSid(Sid: PSid): Cardinal;
begin
  if RtlSubAuthorityCountSid(Sid)^ > 0 then
    Result := RtlSubAuthoritySid(Sid, RtlSubAuthorityCountSid(Sid)^ - 1)^
  else
    Result := 0;
end;

function RtlxChildSid(out ChildSid: ISid; ParentSid: ISid; Rid: Cardinal):
  TNtxStatus;
begin
  // Add a new sub authority at the end
  Result := RtlxNewSid(ChildSid, RtlIdentifierAuthoritySid(
    ParentSid.Data)^, Concat(RtlxSubAuthoritiesSid(ParentSid.Data), [Rid]));
end;

function RtlxParentSid(out ParentSid: ISid; ChildSid: ISid): TNtxStatus;
var
  SubAuthorities: TArray<Cardinal>;
begin
  // Retrieve existing sub authorities
  SubAuthorities := RtlxSubAuthoritiesSid(ParentSid.Data);

  if Length(SubAuthorities) > 0 then
  begin
    // Drop the last one
    Delete(SubAuthorities, High(SubAuthorities), 1);
    Result := RtlxNewSid(ParentSid, RtlIdentifierAuthoritySid(
      ChildSid.Data)^, SubAuthorities);
  end
  else
  begin
    // No parent SID available
    Result.Location := 'RtlxParentSid';
    Result.Status := STATUS_INVALID_SID;
  end;
end;

 { SDDL }

function RtlxpApplySddlOverrides(SID: PSid; var SDDL: String): Boolean;
begin
  Result := False;

  // We override convertion of some SIDs to strings for the sake of readability.
  // The result is still a parsable SDDL string.

  case RtlIdentifierAuthoritySid(SID).ToInt64 of

    // Integrity: S-1-16-x
    SECURITY_MANDATORY_LABEL_AUTHORITY_ID:
      if RtlSubAuthorityCountSid(SID)^ = 1 then
      begin
        SDDL := 'S-1-16-0x' + RtlxIntToStr(RtlSubAuthoritySid(SID, 0)^, 16, 4);
        Result := True;
      end;

  end;
end;

function RtlxSidToString(Sid: PSid): String;
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

function RtlxStringToSid(SDDL: String; out Sid: ISid): TNtxStatus;
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

function RtlxStringToSidConverter(const SDDL: String; out Sid: ISid): Boolean;
begin
  // Use this function with TArrayHelper.Convert<String, ISid>
  Result := RtlxStringToSid(SDDL, Sid).IsSuccess;
end;

 { Well-known SIDs }

function RtlxCreateServiceSid(ServiceName: String; out Sid: ISid): TNtxStatus;
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

function SddlxGetWellKnownSid(out Sid: ISid; WellKnownSidType:
  TWellKnownSidType): TNtxStatus;
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
