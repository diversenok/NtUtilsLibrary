unit NtUtils.Lsa.Sid;

{
  The module allows conversion between account names and SIDs and its management
}

interface

uses
  Ntapi.WinNt, Ntapi.ntlsa, Ntapi.ntseapi, NtUtils, NtUtils.Lsa;

type
  TTranslatedName = record
    SID: ISid;
    DomainName, UserName: String;
    SidType: TSidNameUse;
    IsFake: Boolean;
    function IsValid: Boolean;
    function FullName: String;
  end;

  TTranslatedGroup = record
    Name: TTranslatedName;
    Attributes: TGroupAttributes;
  end;

// Convert a SID to an account name
// NOTE: the function always returns valid output, but it might be only
// partially translated in case of failure.
function LsaxLookupSid(
  const Sid: ISid;
  out Name: TTranslatedName;
  [opt, Access(POLICY_LOOKUP_NAMES)] const hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert a SID with attributes to an account name
// NOTE: the function always returns valid output, but it might be only
// partially translated in case of failure.
function LsaxLookupGroup(
  const Group: TGroup;
  out TranslatedGroup: TTranslatedGroup;
  [opt, Access(POLICY_LOOKUP_NAMES)] const hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert multiple SIDs to a account names
// NOTE: the function always returns valid output, but it might be only
// partially translated in case of failure.
function LsaxLookupSids(
  const Sids: TArray<ISid>;
  out Names: TArray<TTranslatedName>;
  [opt, Access(POLICY_LOOKUP_NAMES)] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert multiple SIDs with attributes to a account names
// NOTE: the function always returns valid output, but it might be only
// partially translated in case of failure.
function LsaxLookupGroups(
  const Groups: TArray<TGroup>;
  out TranslatedGroups: TArray<TTranslatedGroup>;
  [opt, Access(POLICY_LOOKUP_NAMES)] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert a SID to full account name or at least to SDDL
function LsaxSidToString(
  const Sid: ISid;
  [opt, Access(POLICY_LOOKUP_NAMES)] const hxPolicy: ILsaHandle = nil
): String;

// Convert an account's name to a SID
function LsaxLookupName(
  AccountName: String;
  out Sid: ISid;
  [opt, Access(POLICY_LOOKUP_NAMES)] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert an account's name or an SDDL string to a SID
function LsaxLookupNameOrSddl(
  const AccountOrSddl: String;
  out Sid: ISid;
  [opt, Access(POLICY_LOOKUP_NAMES)] const hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Lookup an account's name and convert it to a canonical form
function LsaxCanonicalizeName(
  const AccountName: String;
  out CanonicalName: TTranslatedName;
  [opt, Access(POLICY_LOOKUP_NAMES)] hxPolicy: IHandle = nil
): TNtxStatus;

// Lookup an account's name and convert it to a canonical form in place
function LsaxCanonicalizeNameVar(
  var AccountName: String;
  [opt, Access(POLICY_LOOKUP_NAMES)] const hxPolicy: IHandle = nil
): TNtxStatus;

// Get current the name and the domain of the current user
function LsaxGetUserName(
  out Domain: String;
  out UserName: String
): TNtxStatus;

// Get the full name of the current user
function LsaxGetFullUserName(
  out FullName: String
): TNtxStatus;

// Assign a name to an SID
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function LsaxAddSidNameMapping(
  const Domain: String;
  const User: String;
  const Sid: ISid
): TNtxStatus;

// Revoke a name from an SID
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function LsaxRemoveSidNameMapping(
  const Domain: String;
  const User: String
): TNtxStatus;

implementation

uses
  Ntapi.NtSecApi, Ntapi.ntstatus, NtUtils.SysUtils, NtUtils.Security.Sid;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function LsaxDelayFreeMemory(
  [in] Buffer: Pointer
):  IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      LsaFreeMemory(Buffer);
    end
  );
end;

const
  // Fake domain name for S-1-18
  AUTHENTICATION_AUTHORITY_DOMAIN = 'Authentication Authority';

{ TTranslatedName }

function TTranslatedName.FullName;
begin
  if SidType = SidTypeDomain then
    Result := DomainName
  else if IsValid and (UserName <> '') and (DomainName <> '') then
    Result := DomainName + '\' + UserName
  else if IsValid and (UserName <> '') then
    Result := UserName
  else
    Result := RtlxSidToString(SID);
end;

function TTranslatedName.IsValid;
begin
  Result := not (SidType in INVALID_SID_TYPES);
end;

{ Functions }

function LsaxLookupSid;
var
  Sids: TArray<ISid>;
  Names: TArray<TTranslatedName>;
begin
  SetLength(Sids, 1);
  Sids[0] := Sid;

  Result := LsaxLookupSids(Sids, Names, hxPolicy);
  Name := Names[0]; // Lookup always outputs at least something
end;

function LsaxLookupGroup;
begin
  TranslatedGroup.Attributes := Group.Attributes;
  Result := LsaxLookupSid(Group.Sid, TranslatedGroup.Name, hxPolicy);
end;

function LsaxLookupSids;
var
  SidData: TArray<PSid>;
  BufferDomains: PLsaReferencedDomainList;
  BufferNames: PLsaTranslatedNameArray;
  DomainsDeallocator, NamesDeallocator: IAutoReleasable;
  i: Integer;
begin
  Names := nil;

  // If there is nothing to translate, we are done
  if Length(Sids) <= 0 then
    Exit(NtxSuccess);

  // Always output at least raw SIDs to allow converting them to SDDL
  SetLength(Names, Length(Sids));

  for i := 0 to High(Names) do
    Names[i].SID := Sids[i];

  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  SetLength(SidData, Length(Sids));

  for i := 0 to High(SidData) do
    SidData[i] := Sids[i].Data;

  // Request translation for all SIDs at once
  Result.Location := 'LsaLookupSids';
  Result.Status := LsaLookupSids(hxPolicy.Handle, Length(SidData), SidData,
    BufferDomains, BufferNames);

  // Even without mapping we get to know SID types
  if Result.Status = STATUS_NONE_MAPPED then
    Result.Status := STATUS_SOME_NOT_MAPPED;

  if not Result.IsSuccess then
    Exit;

  DomainsDeallocator := LsaxDelayFreeMemory(BufferDomains);
  NamesDeallocator := LsaxDelayFreeMemory(BufferNames);

  for i := 0 to High(Sids) do
  begin
    // If LSA cannot translate a name, ask our custom name providers
    if (BufferNames{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Use in INVALID_SID_TYPES)
      and RtlxLookupSidInCustomProviders(Sids[i], Names[i].SidType,
      Names[i].DomainName, Names[i].UserName) then
    begin
      Names[i].IsFake := True;
      Continue;
    end;

    // Note: for some SID types, LsaLookupSids might return SID's SDDL
    // representation in the Name field. In rare cases it might be empty.
    // According to [MS-LSAT] the name is valid unless the SID type is
    // SidTypeUnknown

    Names[i].SidType := BufferNames{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Use;
    Names[i].UserName := BufferNames{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.Name
      .ToString;

    // Negative DomainIndex means the SID does not reference a domain
    if (BufferNames{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.DomainIndex >= 0) and
      (BufferNames{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.DomainIndex <
      BufferDomains.Entries) then
      Names[i].DomainName := BufferDomains.Domains{$R-}[
        BufferNames[i].DomainIndex]{$IFDEF R+}{$R+}{$ENDIF}.Name.ToString
    else
      Names[i].DomainName := '';

    // Hack: when requesting bulk translation of SIDs one of which is S-1-5
    // (aka., NT Pseudo Domain), it can change other SIDs's domain from the
    // correct "NT AUTHORITY" to "NT Pseudo Domain". Fix it here.
    if Names[i].IsValid and (RtlxIdentifierAuthoritySid(Names[i].SID) =
      SECURITY_NT_AUTHORITY) and (RtlxSubAuthorityCountSid(Names[i].SID) > 0)
      and (Names[i].UserName <> '') and RtlxEqualStrings(Names[i].DomainName,
      'NT Pseudo Domain') then
      Names[i].DomainName := 'NT AUTHORITY';

    // Workaround missing domain for S-1-18-* SIDs
    if Names[i].IsValid and (RtlxIdentifierAuthoritySid(Names[i].SID) =
      SECURITY_AUTHENTICATION_AUTHORITY) and (Names[i].DomainName = '') then
      Names[i].DomainName := AUTHENTICATION_AUTHORITY_DOMAIN;
  end;
end;

function LsaxLookupGroups;
var
  Sids: TArray<ISid>;
  Names: TArray<TTranslatedName>;
  i: Integer;
begin
  SetLength(Sids, Length(Groups));
  SetLength(TranslatedGroups, Length(Groups));

  for i := 0 to High(Groups) do
  begin
    Sids[i] := Groups[i].Sid;
    TranslatedGroups[i].Attributes := Groups[i].Attributes;
  end;

  Result := LsaxLookupSids(Sids, Names, hxPolicy);

  for i := 0 to High(TranslatedGroups) do
    TranslatedGroups[i].Name := Names[i];
end;

function LsaxSidToString;
var
  AccountName: TTranslatedName;
begin
  LsaxLookupSid(Sid, AccountName, hxPolicy);
  Result := AccountName.FullName; // FullName falls back to SDDL on failure
end;

function LsaxLookupName;
const
  APP_PACKAGE_DOMAIN_PREFIX = 'APPLICATION PACKAGE AUTHORITY\';
  AUTHENTICATION_DOMAIN_PREFIX = AUTHENTICATION_AUTHORITY_DOMAIN + '\';
var
  BufferDomain: PLsaReferencedDomainList;
  BufferTranslatedSid: PLsaTranslatedSid2Array;
  DomainDeallocator, SidDeallocator: IAutoReleasable;
  AccountNameStr: TLsaUnicodeString;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(AccountNameStr, AccountName);

  if not Result.IsSuccess then
    Exit;

  // Fix LSA's lookup for package-related SIDs and fake authentication domain
  RtlxPrefixStripString(APP_PACKAGE_DOMAIN_PREFIX, AccountName);
  RtlxPrefixStripString(AUTHENTICATION_DOMAIN_PREFIX, AccountName);

  // Request translation of one name
  Result.Location := 'LsaLookupNames2';
  Result.Status := LsaLookupNames2(hxPolicy.Handle, 0, 1, [AccountNameStr],
    BufferDomain, BufferTranslatedSid);

  // LsaLookupNames2 allocates memory even on some errors
  if Result.IsSuccess or (Result.Status = STATUS_NONE_MAPPED) then
  begin
    DomainDeallocator := LsaxDelayFreeMemory(BufferDomain);
    SidDeallocator := LsaxDelayFreeMemory(BufferTranslatedSid);
  end;

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCopySid(BufferTranslatedSid[0].Sid, Sid);
end;

function LsaxLookupNameOrSddl;
begin
  // Try SDDL first because it's faster. Note that in addition to the S-1-*
  // strings we are also checking about ~50 double-letter abbreviations.
  // See [MS-DTYP] for details.
  Result := RtlxStringToSid(AccountOrSddl, Sid);

  // Lookup the account name in the LSA database
  if not Result.IsSuccess then
    Result := LsaxLookupName(AccountOrSddl, Sid, hxPolicy);
end;

function LsaxCanonicalizeName;
var
  Sid: ISid;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  // Convert the user-supplied name to a SID
  Result := LsaxLookupNameOrSddl(AccountName, Sid, hxPolicy);

  if not Result.IsSuccess then
    Exit;

  // Convert the SID back to an account name name
  Result := LsaxLookupSid(Sid, CanonicalName, hxPolicy);

  if not Result.IsSuccess then
    Exit;

  if not CanonicalName.IsValid then
  begin
    Result.Location := 'LsaxCanonicalizeName';
    Result.Status := STATUS_INVALID_ACCOUNT_NAME;
  end;
end;

function LsaxCanonicalizeNameVar;
var
  CanonicalName: TTranslatedName;
begin
  Result := LsaxCanonicalizeName(AccountName, CanonicalName, hxPolicy);

  if Result.IsSuccess then
    AccountName := CanonicalName.FullName;
end;

function LsaxGetUserName;
var
  BufferUser, BufferDomain: PLsaUnicodeString;
  UserDeallocator, DomainDeallocator: IAutoReleasable;
begin
  Result.Location := 'LsaGetUserName';
  Result.Status := LsaGetUserName(BufferUser, BufferDomain);

  if not Result.IsSuccess then
    Exit;

  UserDeallocator := LsaxDelayFreeMemory(BufferUser);
  DomainDeallocator := LsaxDelayFreeMemory(BufferDomain);

  Domain := BufferDomain.ToString;
  UserName := BufferUser.ToString;
end;

function LsaxGetFullUserName;
var
  Domain, UserName: String;
begin
  Result := LsaxGetUserName(Domain, UserName);

  if not Result.IsSuccess then
    Exit;

  if (Domain <> '') and (UserName <> '') then
    FullName := Domain + '\' + UserName
  else if Domain <> '' then
    FullName := Domain
  else if UserName <> '' then
    FullName := UserName
  else
  begin
    Result.Location := 'LsaxGetFullUserName';
    Result.Status := STATUS_NONE_MAPPED;
  end;
end;

[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function LsaxManageSidNameMapping(
  OperationType: TLsaSidNameMappingOperationType;
  Input: TLsaSidNameMappingOperation
): TNtxStatus;
var
  pOutput: PLsaSidNameMappingOperationGenericOutput;
  OutputDeallocator: IAutoReleasable;
begin
  pOutput := nil;

  Result.Location := 'LsaManageSidNameMapping';
  Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  Result.Status := LsaManageSidNameMapping(OperationType, Input, pOutput);

  // The function uses a custom way to report some errors
  if not Result.IsSuccess and Assigned(pOutput) then
  begin
    OutputDeallocator := LsaxDelayFreeMemory(pOutput);

    case pOutput.ErrorCode of
      LsaSidNameMappingOperation_NameCollision,
      LsaSidNameMappingOperation_SidCollision:
        Result.Status := STATUS_OBJECT_NAME_COLLISION;

      LsaSidNameMappingOperation_DomainNotFound:
        Result.Status := STATUS_NO_SUCH_DOMAIN;

      LsaSidNameMappingOperation_DomainSidPrefixMismatch:
        Result.Status := STATUS_INVALID_SID;

      LsaSidNameMappingOperation_MappingNotFound:
        Result.Status := STATUS_NOT_FOUND;
    end;
  end;
end;

function LsaxAddSidNameMapping;
var
  Input: TLsaSidNameMappingOperation;
begin
  // When creating a mapping for a domain, it can only be S-1-5-x
  // where x is in range [SECURITY_MIN_BASE_RID .. SECURITY_MAX_BASE_RID]

  Result := RtlxInitUnicodeString(Input.AddInput.DomainName, Domain);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(Input.AddInput.AccountName, User);

  if not Result.IsSuccess then
    Exit;

  Input.AddInput.Sid := Sid.Data;
  Input.AddInput.Flags := 0;

  Result := LsaxManageSidNameMapping(LsaSidNameMappingOperation_Add, Input);
end;

function LsaxRemoveSidNameMapping;
var
  Input: TLsaSidNameMappingOperation;
begin
  Result := RtlxInitUnicodeString(Input.RemoveInput.DomainName, Domain);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(Input.RemoveInput.AccountName, User);

  if not Result.IsSuccess then
    Exit;

  Result := LsaxManageSidNameMapping(LsaSidNameMappingOperation_Remove, Input);
end;

end.
