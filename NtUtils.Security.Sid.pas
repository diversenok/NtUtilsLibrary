unit NtUtils.Security.Sid;

interface

uses
  Winapi.WinNt, Ntapi.ntseapi, Winapi.securitybaseapi, NtUtils.Exceptions,
  DelphiApi.Reflection;

type
  ISid = interface
    function Sid: PSid;
    function EqualsTo(Sid2: PSid): Boolean;
    function Parent: ISid;
    function Child(Rid: Cardinal): ISid;
    function SDDL: String;
    function IdentifyerAuthority: PSidIdentifierAuthority;
    function Rid: Cardinal;
    function SubAuthorities: Byte;
    function SubAuthority(Index: Integer): Cardinal;
  end;

  TSid = class(TInterfacedObject, ISid)
  protected
    FSid: PSid;
    constructor CreateOwned(OwnedSid: PSid; Dummy: Integer = 0);
  public
    constructor Create(const IdentifyerAuthority: TSidIdentifierAuthority;
      SubAuthouritiesArray: TArray<Cardinal> = nil);
    constructor CreateCopy(SourceSid: PSid);
    constructor CreateNew(const IdentifyerAuthority: TSidIdentifierAuthority;
      SubAuthorities: Byte; SubAuthourity0: Cardinal = 0;
      SubAuthourity1: Cardinal = 0; SubAuthourity2: Cardinal = 0;
      SubAuthourity3: Cardinal = 0; SubAuthourity4: Cardinal = 0);
    destructor Destroy; override;
    function Sid: PSid;
    function EqualsTo(Sid2: PSid): Boolean;
    function Parent: ISid;
    function Child(Rid: Cardinal): ISid;
    function SDDL: String;
    function IdentifyerAuthority: PSidIdentifierAuthority;
    function Rid: Cardinal;
    function SubAuthorities: Byte;
    function SubAuthority(Index: Integer): Cardinal;
  end;

  TGroup = record
    SecurityIdentifier: ISid;
    [Bitwise(TGroupFlagProvider)] Attributes: Cardinal;
  end;

// Validate the buffer and capture a copy as an ISid
function RtlxCaptureCopySid(Buffer: PSid; out Sid: ISid): TNtxStatus;

// Convert a SID to its SDDL representation
function RtlxConvertSidToString(Sid: PSid): String;

// Convert SDDL string to SID
function RtlxConvertStringToSid(SDDL: String; out Sid: ISid): TNtxStatus;
function RtlxStringToSidConverter(const SDDL: String; out Sid: ISid): Boolean;

// Construct a well-known SID
function SddlxGetWellKnownSid(WellKnownSidType: TWellKnownSidType;
  out Sid: ISid): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntstatus, Winapi.WinBase, Winapi.Sddl,
  DelphiUtils.Strings, System.SysUtils;

{ TSid }

function TSid.Child(Rid: Cardinal): ISid;
var
  Buffer: PSid;
  Status: NTSTATUS;
  i: Integer;
begin
  Buffer := AllocMem(RtlLengthRequiredSid(SubAuthorities + 1));

  // Copy identifier authority
  Status := RtlInitializeSid(Buffer, RtlIdentifierAuthoritySid(FSid),
    SubAuthorities + 1);

  if not NT_SUCCESS(Status) then
  begin
    FreeMem(Buffer);
    NtxAssert(Status, 'RtlInitializeSid');
  end;

  // Copy existing sub authorities
  for i := 0 to SubAuthorities - 1 do
    RtlSubAuthoritySid(Buffer, i)^ := RtlSubAuthoritySid(FSid, i)^;

  // Set the last sub authority to the RID
  RtlSubAuthoritySid(Buffer, SubAuthorities)^ := Rid;

  Result := TSid.CreateOwned(Buffer);
end;

constructor TSid.Create(const IdentifyerAuthority: TSidIdentifierAuthority;
  SubAuthouritiesArray: TArray<Cardinal>);
var
  Status: NTSTATUS;
  i: Integer;
begin
  FSid := AllocMem(RtlLengthRequiredSid(Length(SubAuthouritiesArray)));
  Status := RtlInitializeSid(FSid, @IdentifyerAuthority,
    Length(SubAuthouritiesArray));

  if not NT_SUCCESS(Status) then
  begin
    FreeMem(FSid);
    NtxAssert(Status, 'RtlInitializeSid');
  end;

  for i := 0 to High(SubAuthouritiesArray) do
    RtlSubAuthoritySid(FSid, i)^ := SubAuthouritiesArray[i];
end;

constructor TSid.CreateCopy(SourceSid: PSid);
var
  Status: NTSTATUS;
begin
  if not RtlValidSid(SourceSid) then
    NtxAssert(STATUS_INVALID_SID, 'RtlValidSid');

  FSid := AllocMem(RtlLengthSid(SourceSid));
  Status := RtlCopySid(RtlLengthSid(SourceSid), FSid, SourceSid);

  if not NT_SUCCESS(Status) then
  begin
    FreeMem(FSid);
    NtxAssert(Status, 'RtlCopySid');
  end;
end;

constructor TSid.CreateNew(const IdentifyerAuthority: TSidIdentifierAuthority;
  SubAuthorities: Byte; SubAuthourity0, SubAuthourity1, SubAuthourity2,
  SubAuthourity3, SubAuthourity4: Cardinal);
var
  Status: NTSTATUS;
begin
  FSid := AllocMem(RtlLengthRequiredSid(SubAuthorities));
  Status := RtlInitializeSid(FSid, @IdentifyerAuthority, SubAuthorities);

  if not NT_SUCCESS(Status) then
  begin
    FreeMem(FSid);
    NtxAssert(Status, 'RtlInitializeSid');
  end;

  if SubAuthorities > 0 then
    RtlSubAuthoritySid(FSid, 0)^ := SubAuthourity0;

  if SubAuthorities > 1 then
    RtlSubAuthoritySid(FSid, 1)^ := SubAuthourity1;

  if SubAuthorities > 2 then
    RtlSubAuthoritySid(FSid, 2)^ := SubAuthourity2;

  if SubAuthorities > 3 then
    RtlSubAuthoritySid(FSid, 3)^ := SubAuthourity3;

  if SubAuthorities > 4 then
    RtlSubAuthoritySid(FSid, 4)^ := SubAuthourity4;
end;

constructor TSid.CreateOwned(OwnedSid: PSid; Dummy: Integer);
begin
  FSid := OwnedSid;
end;

destructor TSid.Destroy;
begin
  FreeMem(FSid);
  inherited;
end;

function TSid.EqualsTo(Sid2: PSid): Boolean;
begin
  Result := RtlEqualSid(FSid, Sid2);
end;

function TSid.IdentifyerAuthority: PSidIdentifierAuthority;
begin
  Result := RtlIdentifierAuthoritySid(FSid);
end;

function TSid.Parent: ISid;
var
  Status: NTSTATUS;
  Buffer: PSid;
  i: Integer;
begin
  // The rule is simple: we drop the last sub-authority and create a new SID.

  Assert(SubAuthorities > 0);

  Buffer := AllocMem(RtlLengthRequiredSid(SubAuthorities - 1));

  // Copy identifier authority
  Status := RtlInitializeSid(Buffer, RtlIdentifierAuthoritySid(FSid),
    SubAuthorities - 1);

  if not NT_SUCCESS(Status) then
  begin
    FreeMem(Buffer);
    NtxAssert(Status, 'RtlInitializeSid');
  end;

  // Copy sub authorities
  for i := 0 to RtlSubAuthorityCountSid(Buffer)^ - 1 do
    RtlSubAuthoritySid(Buffer, i)^ := RtlSubAuthoritySid(FSid, i)^;

  Result := TSid.CreateOwned(Buffer);
end;

function TSid.Rid: Cardinal;
begin
  if SubAuthorities > 0 then
    Result := SubAuthority(SubAuthorities - 1)
  else
    Result := 0;
end;

function TSid.SDDL: String;
begin
  Result := RtlxConvertSidToString(FSid);
end;

function TSid.Sid: PSid;
begin
  Result := FSid;
end;

function TSid.SubAuthorities: Byte;
begin
  Result := RtlSubAuthorityCountSid(FSid)^;
end;

function TSid.SubAuthority(Index: Integer): Cardinal;
begin
  if (Index >= 0) and (Index < SubAuthorities) then
    Result := RtlSubAuthoritySid(FSid, Index)^
  else
    Result := 0;
end;

{ Functions }

function RtlxCaptureCopySid(Buffer: PSid; out Sid: ISid): TNtxStatus;
begin
  if Assigned(Buffer) and RtlValidSid(Buffer) then
  begin
    Sid := TSid.CreateCopy(Buffer);
    Result.Status := STATUS_SUCCESS;
  end
  else
  begin
    Result.Location := 'RtlValidSid';
    Result.Status := STATUS_INVALID_SID;
  end;
end;

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
        SDDL := 'S-1-16-' + IntToHexEx(RtlSubAuthoritySid(SID, 0)^, 4);
        Result := True;
      end;

  end;
end;

function RtlxConvertSidToString(Sid: PSid): String;
var
  SDDL: UNICODE_STRING;
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
    Result := '';
end;

function RtlxConvertStringToSid(SDDL: String; out Sid: ISid): TNtxStatus;
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

  if SDDL.StartsWith('S-1-', True) and
    TryStrToUInt64Ex(Copy(SDDL, Length('S-1-') + 1, Length(SDDL)),
    IdAuthorityUInt64) and (IdAuthorityUInt64 < UInt64(1) shl 48) then
  begin
    IdAuthority.FromInt64(IdAuthorityUInt64);
    Sid := TSid.CreateNew(IdAuthority, 0);
  end
  else
  begin
    // Usual SDDL conversion
    Result.Location := 'ConvertStringSidToSidW';
    Result.Win32Result := ConvertStringSidToSidW(PWideChar(SDDL), Buffer);

    if Result.IsSuccess then
    begin
      Result := RtlxCaptureCopySid(Buffer, Sid);
      LocalFree(Buffer);
    end;
  end;
end;

function RtlxStringToSidConverter(const SDDL: String; out Sid: ISid): Boolean;
begin
  // Use this function with TArrayHelper.Convert<String, ISID>
  Result := RtlxConvertStringToSid(SDDL, Sid).IsSuccess;
end;

function SddlxGetWellKnownSid(WellKnownSidType: TWellKnownSidType;
  out Sid: ISid): TNtxStatus;
var
  Buffer: PSid;
  BufferSize: Cardinal;
begin
  BufferSize := 0;

  Result.Location := 'CreateWellKnownSid';
  Result.Win32Result := CreateWellKnownSid(WellKnownSidType, nil, nil,
    BufferSize);

  if not NtxTryCheckBuffer(Result.Status, BufferSize) then
    Exit;

  Buffer := AllocMem(BufferSize);

  Result.Win32Result := CreateWellKnownSid(WellKnownSidType, nil, Buffer,
    BufferSize);

  if Result.IsSuccess then
    Sid := TSid.CreateOwned(Buffer)
  else
    FreeMem(Buffer);
end;

end.
