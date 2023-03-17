unit NtUtils.Security.Sid;

{
  The module adds support for common operations on Security Identifiers.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.WinBase, NtUtils;

{ Construction }

// Build a new SID
function RtlxCreateSid(
  out Sid: ISid;
  const IdentifyerAuthority: TSidIdentifierAuthority;
  [opt] const SubAuthouritiesArray: TArray<Cardinal> = nil
): TNtxStatus;

// Build a new SID without failing
function RtlxMakeSid(
  const IdentifyerAuthority: TSidIdentifierAuthority;
  [opt] const SubAuthouritiesArray: TArray<Cardinal> = nil
): ISid;

// Validate the intput buffer and capture a copy as a SID
function RtlxCopySid(
  [in] Buffer: PSid;
  out NewSid: ISid
): TNtxStatus;

// Validate the intput buffer and capture a copy as a SID
function RtlxCopySidEx(
  [in] Buffer: PSid;
  BufferSize: Cardinal;
  out NewSid: ISid
): TNtxStatus;

{ Information }

// Retrieve a copy of identifier authority of a SID as UIn64
function RtlxIdentifierAuthoritySid(
  const Sid: ISid
): UInt64;

// Retrieve the number of sub-authorities of a SID
function RtlxSubAuthoritiesCountSid(
  const Sid: ISid
): Cardinal;

// Retrieve an array of sub-authorities of a SID
function RtlxSubAuthoritiesSid(
  const Sid: ISid
): TArray<Cardinal>;

// Check if two SIDs are equal
function RtlxEqualSids(
  const Sid1: ISid;
  const Sid2: ISid
): Boolean;

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

// Sorting
function RtlxCompareSids(
  const SidA: ISid;
  const SidB: ISid
): Integer;

{ Custom SID Representation }

type
  // A prototype for registering custom recognizers that convert strings to SIDs
  TSidNameRecognizer = function (
    const SidString: String;
    out Sid: ISid
  ): Boolean;

  // A prototype for registering custom lookup providers
  TSidNameProvider = function (
    const Sid: ISid;
    out SidType: TSidNameUse;
    out SidDomain: String;
    out SidUser: String
  ): Boolean;

// Add a function for recognizing custom names for SIDs
procedure RtlxRegisterSidNameRecognizer(
  const Recognizer: TSidNameRecognizer
);

// Add a function for represnting SIDs under custom names
procedure RtlxRegisterSidNameProvider(
  const Provider: TSidNameProvider
);

// Convert a SID to a human readable form using custom (fake) name providers
function RtlxLookupSidInCustomProviders(
  const Sid: ISid;
  out SidType: TSidNameUse;
  out DomainName: String;
  out UserName: String
): Boolean;

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

// Derive a virtual account SID
function RtlxCreateVirtualAccountSid(
  const ServiceName: String;
  BaseSubAuthority: Cardinal;
  out Sid: ISid
): TNtxStatus;

// Construct a well-known SID
function SddlxCreateWellKnownSid(
  WellKnownSidType: TWellKnownSidType;
  out Sid: ISid
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntstatus, NtUtils.SysUtils, NtUtils.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

function RtlxMakeSid;
var
  i: Integer;
begin
  IMemory(Result) := Auto.AllocateDynamic(
    RtlLengthRequiredSid(Length(SubAuthouritiesArray)));

  if not RtlInitializeSid(Result.Data, @IdentifyerAuthority,
    Length(SubAuthouritiesArray)).IsSuccess then
  begin
    // Construct manually on failure
    Result.Data.Revision := SID_REVISION;
    Result.Data.SubAuthorityCount := Length(SubAuthouritiesArray);
    Result.Data.IdentifierAuthority := IdentifyerAuthority;
  end;

  // Fill in the sub authorities
  for i := 0 to High(SubAuthouritiesArray) do
    RtlSubAuthoritySid(Result.Data, i)^ := SubAuthouritiesArray[i];
end;

function RtlxCopySid;
begin
  if not RtlValidSid(Buffer) then
  begin
    Result.Location := 'RtlValidSid';
    Result.Status := STATUS_INVALID_SID;
    Exit;
  end;

  IMemory(NewSid) := Auto.AllocateDynamic(RtlLengthSid(Buffer));

  Result.Location := 'RtlCopySid';
  Result.Status := RtlCopySid(RtlLengthSid(Buffer), NewSid.Data, Buffer);
end;

function RtlxCopySidEx;
begin
  // Let RtlValidSid do the buffer probing for us; it won't read past the
  // header. Then we can check if the number of sub authorities fits.
  if (BufferSize < RtlLengthRequiredSid(0)) or not RtlValidSid(Buffer) or
    (BufferSize < RtlLengthRequiredSid(Buffer.SubAuthorityCount)) then
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

function RtlxSubAuthoritiesCountSid;
begin
  Result := RtlSubAuthorityCountSid(Sid.Data)^;
end;

function RtlxSubAuthoritiesSid;
var
  i: Integer;
begin
  SetLength(Result, RtlSubAuthorityCountSid(Sid.Data)^);

  for i := 0 to High(Result) do
    Result[i] := RtlSubAuthoritySid(Sid.Data, i)^;
end;

function RtlxEqualSids;
begin
  Result := RtlEqualSid(Sid1.Data, Sid2.Data);
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

function RtlxCompareSids;
var
  i: Integer;
  A, B: PSid;
begin
  A := SidA.Data;
  B := SidB.Data;

  // Compare identifier authorities
  if UInt64(RtlIdentifierAuthoritySid(A)^) <
    UInt64(RtlIdentifierAuthoritySid(B)^) then
    Exit(-1);

  if UInt64(RtlIdentifierAuthoritySid(A)^) >
    UInt64(RtlIdentifierAuthoritySid(B)^) then
    Exit(1);

  i := 0;
  Result := 0;

  // Compare sub authorities
  while (Result = 0) and (i < RtlSubAuthorityCountSid(A)^) and
    (i < RtlSubAuthorityCountSid(B)^) do
  begin
    if RtlSubAuthoritySid(A, i)^ < RtlSubAuthoritySid(B, i)^ then
      Exit(-1);

    if RtlSubAuthoritySid(A, i)^ > RtlSubAuthoritySid(B, i)^ then
      Exit(1);

    Inc(i);
  end;

  // The shorter SID goes first
  Result := Integer(RtlSubAuthorityCountSid(A)^) - RtlSubAuthorityCountSid(B)^;
end;

{ SID name parsing }

function TryStrToUInt64Ex(S: String; out Value: UInt64): Boolean;
var
  E: Integer;
begin
  if RtlxPrefixStripString('0x', S) then
    Insert('$', S, Low(S));

  Val(S, Value, E);
  Result := (E = 0);
end;

function RtlxZeroSubAuthorityStringToSid(
  const SDDL: String;
  out Sid: ISid
): Boolean;
var
  S: String;
  IdAuthority: UInt64;
begin
  // Despite RtlConvertSidToUnicodeString's ability to convert SIDs with
  // zero sub authorities to SDDL, ConvertStringSidToSidW cannot convert them
  // back. Fix this issue by parsing them manually.

  // Expected formats for an SID with 0 sub authorities:
  //        S-1-(\d+)     |     S-1-(0x[A-F\d]+)
  // where the value fits into a 6-byte (48-bit) buffer

  S := SDDL;
  Result := RtlxPrefixStripString('S-1-', S) and TryStrToUInt64Ex(S,
    IdAuthority) and (IdAuthority < UInt64(1) shl 48) and
    RtlxCreateSid(Sid, IdAuthority).IsSuccess;
end;

var
  CustomSidNameRecognizers: TArray<TSidNameRecognizer>;
  CustomSidNameProviders: TArray<TSidNameProvider>;

procedure RtlxRegisterSidNameRecognizer;
begin
  // Recognizers from other modules
  SetLength(CustomSidNameRecognizers, Length(CustomSidNameRecognizers) + 1);
  CustomSidNameRecognizers[High(CustomSidNameRecognizers)] := Recognizer;
end;

procedure RtlxRegisterSidNameProvider;
begin
  // Providers from other modules
  SetLength(CustomSidNameProviders, Length(CustomSidNameProviders) + 1);
  CustomSidNameProviders[High(CustomSidNameProviders)] := Provider;
end;

function RtlxLookupSidInCustomProviders;
var
  Provider: TSidNameProvider;
begin
  for Provider in CustomSidNameProviders do
    if Provider(Sid, SidType, DomainName, UserName) then
    begin
      Assert(SidType in VALID_SID_TYPES, 'Invalid SID type for custom provider');
      Exit(True);
    end;

  Result := False;
end;

 { SDDL }

function RtlxSidToString;
var
  SDDL: TNtUnicodeString;
  Buffer: array [0 .. SECURITY_MAX_SID_STRING_CHARACTERS - 1] of WideChar;
begin
  // Since SDDL permits hexadecimals, we can use them to represent some SIDs
  // in a more user-friendly way.

  case RtlxIdentifierAuthoritySid(SID) of

    // Integrity: S-1-16-X
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

function RtlxStringToSid;
var
  Buffer: PSid;
  BufferDeallocator: IAutoReleasable;
  Recognizer: TSidNameRecognizer;
begin
  // Apply the workaround for zero sub authoruty SID lookup
  if RtlxZeroSubAuthorityStringToSid(SDDL, Sid) then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Try other custom recognizers
  for Recognizer in CustomSidNameRecognizers do
    if Recognizer(SDDL, Sid) then
    begin
      Assert(Assigned(Sid), 'Custom SID recognizer returned nil.');
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

  // Usual SDDL conversion
  Result.Location := 'ConvertStringSidToSidW';
  Result.Win32Result := ConvertStringSidToSidW(PWideChar(SDDL), Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := AdvxDelayLocalFree(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
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

  SidLength := RtlLengthRequiredSid(SECURITY_SERVICE_ID_RID_COUNT);
  IMemory(Sid) := Auto.AllocateDynamic(SidLength);
  repeat
    Result.Status := RtlCreateServiceSid(TNtUnicodeString.From(ServiceName),
      Sid.Data, SidLength);
  until not NtxExpandBufferEx(Result, IMemory(Sid), SidLength, nil);
end;

function RtlxCreateVirtualAccountSid;
var
  SidLength: Cardinal;
begin
  Result.Location := 'RtlCreateVirtualAccountSid';

  SidLength := RtlLengthRequiredSid(SECURITY_VIRTUALACCOUNT_ID_RID_COUNT);
  IMemory(Sid) := Auto.AllocateDynamic(SidLength);
  repeat
    Result.Status := RtlCreateVirtualAccountSid(TNtUnicodeString.From(
      ServiceName), BaseSubAuthority, Sid.Data, SidLength);
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
