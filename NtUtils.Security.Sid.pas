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

{ Information }

// Retrieve a copy of identifier authority of a SID as UIn64
function RtlxIdentifierAuthoritySid(
  const Sid: ISid
): UInt64;

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
  if RtlxPrefixString('0x', S) then
  begin
    Delete(S, Low(S), 2);
    Insert('$', S, Low(S));
  end;

  Val(S, Value, E);
  Result := (E = 0);
end;

function RtlxZeroSubAuthorityStringToSid(
  const SDDL: String;
  out Sid: ISid
): Boolean;
var
  IdAuthority: UInt64;
begin
  // Despite RtlConvertSidToUnicodeString's ability to convert SIDs with
  // zero sub authorities to SDDL, ConvertStringSidToSidW cannot convert them
  // back. Fix this issue by parsing them manually.

  // Expected formats for an SID with 0 sub authorities:
  //        S-1-(\d+)     |     S-1-(0x[A-F\d]+)
  // where the value fits into a 6-byte (48-bit) buffer

  Result := RtlxPrefixString('S-1-', SDDL) and TryStrToUInt64Ex(Copy(SDDL,
    Length('S-1-') + 1, Length(SDDL)), IdAuthority) and (IdAuthority <
    UInt64(1) shl 48) and RtlxCreateSid(Sid, IdAuthority).IsSuccess;
end;

function RtlxLogonStringToSid(
  const StringSid: String;
  out Sid: ISid
): Boolean;
const
  FULL_PREFIX = 'NT AUTHORITY\LogonSessionId_';
  SHORT_PREFIX = 'LogonSessionId_';
var
  LogonIdStr: String;
  SplitIndex: Integer;
  LogonIdHighString, LogonIdLowString: String;
  LogonIdHigh, LogonIdLow: Cardinal;
  i: Integer;
begin
  // LSA lookup functions automatically convert S-1-5-5-X-Y to
  // NT AUTHORITY\LogonSessionId_X_Y and then refuse to parse them back.
  // Fix this issue by parsing such strings manually.

  // Check if the string has the logon SID prefix and strip it
  if RtlxPrefixString(FULL_PREFIX, StringSid) then
    LogonIdStr := Copy(StringSid, Length(FULL_PREFIX) + 1, Length(StringSid))
  else if RtlxPrefixString(SHORT_PREFIX, StringSid) then
    LogonIdStr := Copy(StringSid, Length(SHORT_PREFIX) + 1, Length(StringSid))
  else
    Exit(False);

  // Find the underscore between high and low parts
  SplitIndex := -1;

  for i := Low(LogonIdStr) to High(LogonIdStr) do
    if LogonIdStr[i] = '_' then
    begin
      SplitIndex := i;
      Break;
    end;

  if SplitIndex < 0 then
    Exit(False);

  // Split the string
  LogonIdHighString := Copy(LogonIdStr, 1, SplitIndex - Low(String));
  LogonIdLowString := Copy(LogonIdStr, SplitIndex - Low(String) + 2,
    Length(LogonIdStr) - SplitIndex + Low(String));

  // Parse and construct the SID
  Result :=
    (Length(LogonIdHighString) > 0) and
    (Length(LogonIdLowString) > 0) and
    RtlxStrToUInt(LogonIdHighString, LogonIdHigh) and
    RtlxStrToUInt(LogonIdLowString, LogonIdLow) and
    RtlxCreateSid(Sid, SECURITY_NT_AUTHORITY,
      [SECURITY_LOGON_IDS_RID, LogonIdHigh, LogonIdLow]).IsSuccess;
end;

function RtlxServiceNameToSid(
  const StringSid: String;
  out Sid: ISid
): Boolean;
const
  PREFIX = 'NT SERVICE\';
  ALL_SERVICES = PREFIX + 'ALL SERVICES';
begin
  // Service SIDs are determenistically derived from the service name.
  // We can parse them even without the help of LSA.

  Result := False;

  if not RtlxPrefixString(PREFIX, StringSid) then
    Exit;

  // NT SERVICE\ALL SERVICES is a reserved name
  if RtlxEqualStrings(ALL_SERVICES, StringSid) then
    Result := RtlxCreateSid(Sid, SECURITY_NT_AUTHORITY,
      [SECURITY_SERVICE_ID_BASE_RID, SECURITY_SERVICE_ID_GROUP_RID]).IsSuccess
  else
    Result := RtlxCreateServiceSid(Copy(StringSid, Length(PREFIX) + 1,
      Length(StringSid)), Sid).IsSuccess;
end;

function RtlxTaskNameToSid(
  const StringSid: String;
  out Sid: ISid
): Boolean;
const
  PREFIX = 'NT TASK\';
begin
  // Task SIDs are determenistically derived from the task path name.
  // We can parse them even without the help of LSA.

  Result := RtlxPrefixString(PREFIX, StringSid) and
    RtlxCreateVirtualAccountSid(Copy(StringSid, Length(PREFIX) + 1,
    Length(StringSid)), SECURITY_TASK_ID_BASE_RID, Sid).IsSuccess;
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
  Recognizer: TSidNameRecognizer;
begin
  // Try well-known name recognizers defined in this module
  if RtlxZeroSubAuthorityStringToSid(SDDL, Sid) or
    RtlxLogonStringToSid(SDDL, Sid) or
    RtlxServiceNameToSid(SDDL, Sid) or
    RtlxTaskNameToSid(SDDL, Sid) then
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
