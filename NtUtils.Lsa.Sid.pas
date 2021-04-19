unit NtUtils.Lsa.Sid;

{
  The module allows conversion between account names and SIDs and its management
}

interface

uses
  Winapi.WinNt, NtUtils, NtUtils.Lsa;

type
  TTranslatedName = record
    DomainName, UserName: String;
    SidType: TSidNameUse;
    function IsValid: Boolean;
    function FullName: String;
  end;

// Convert a SID to an account name
function LsaxLookupSid(
  [in] Sid: PSid;
  out Name: TTranslatedName;
  [opt] const hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert multiple SIDs to a account names
function LsaxLookupSids(
  const Sids: TArray<PSid>;
  out Names: TArray<TTranslatedName>;
  [opt] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert a SID to full account name or at least to SDDL
function LsaxSidToString(
  [in] Sid: PSid;
  [opt] hxPolicy: ILsaHandle = nil
): String;

// Convert an account's name to a SID
function LsaxLookupName(
  const AccountName: String;
  out Sid: ISid;
  [opt] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert an account's name or an SDDL string to a SID
function LsaxLookupNameOrSddl(
  const AccountOrSddl: String;
  out Sid: ISid;
  [opt] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Lookup an account's name and convert it to a canonical form
function LsaxCanonicalizeName(
  const AccountName: String;
  out CanonicalName: TTranslatedName;
  [opt] hxPolicy: IHandle = nil
): TNtxStatus;

// Lookup an account's name and convert it to a canonical form in place
function LsaxCanonicalizeNameVar(
  var AccountName: String;
  [opt] hxPolicy: IHandle = nil
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
function LsaxAddSidNameMapping(
  const Domain: String;
  const User: String;
  [in] Sid: PSid
): TNtxStatus;

// Revoke a name from an SID
function LsaxRemoveSidNameMapping(
  const Domain: String;
  const User: String
): TNtxStatus;

implementation

uses
  Winapi.ntlsa, Winapi.NtSecApi, Ntapi.ntstatus, Ntapi.ntseapi,
  NtUtils.SysUtils, NtUtils.Security.Sid;

{ TTranslatedName }

function TTranslatedName.FullName;
begin
  if SidType = SidTypeDomain then
    Result := DomainName
  else if (UserName <> '') and (DomainName <> '') then
    Result := DomainName + '\' + UserName
  else if (UserName <> '') then
    Result := UserName
  else
    Result := '';
end;

function TTranslatedName.IsValid: Boolean;
begin
  Result := not (SidType in INVALID_SID_TYPES);
end;

{ Functions }

function LsaxLookupSid;
var
  Sids: TArray<PSid>;
  Names: TArray<TTranslatedName>;
begin
  SetLength(Sids, 1);
  Sids[0] := Sid;

  Result := LsaxLookupSids(Sids, Names, hxPolicy);

  if Result.IsSuccess then
    Name := Names[0];
end;

function LsaxLookupSids;
var
  BufferDomains: PLsaReferencedDomainList;
  BufferNames: PLsaTranslatedNameArray;
  i: Integer;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  // Request translation for all SIDs at once
  Result.Location := 'LsaLookupSids';
  Result.Status := LsaLookupSids(hxPolicy.Handle, Length(Sids), Sids,
    BufferDomains, BufferNames);

  // Even without mapping we get to know SID types
  if Result.Status = STATUS_NONE_MAPPED then
    Result.Status := STATUS_SOME_NOT_MAPPED;

  if not Result.IsSuccess then
    Exit;

  SetLength(Names, Length(SIDs));

  for i := 0 to High(Sids) do
  begin
    Names[i].SidType := BufferNames{$R-}[i]{$R+}.Use;

    // Note: for some SID types LsaLookupSids might return SID's SDDL
    // representation in the Name field. In rare cases it might be empty.
    // According to [MS-LSAT] the name is valid unless the SID type is
    // SidTypeUnknown

    Names[i].UserName := BufferNames{$R-}[i]{$R+}.Name.ToString;

    // Negative DomainIndex means the SID does not reference a domain
    if (BufferNames{$R-}[i]{$R+}.DomainIndex >= 0) and
      (BufferNames{$R-}[i]{$R+}.DomainIndex < BufferDomains.Entries) then
      Names[i].DomainName := BufferDomains.Domains{$R-}[
        BufferNames[i].DomainIndex]{$R+}.Name.ToString
    else
      Names[i].DomainName := '';
  end;

  LsaFreeMemory(BufferDomains);
  LsaFreeMemory(BufferNames);
end;

function LsaxSidToString;
var
  AccountName: TTranslatedName;
begin
  if LsaxLookupSid(Sid, AccountName, hxPolicy).IsSuccess and
    AccountName.IsValid then
    Result := AccountName.FullName
  else
    Result := RtlxSidToString(Sid);
end;

function LsaxLookupName;
var
  BufferDomain: PLsaReferencedDomainList;
  BufferTranslatedSid: PLsaTranslatedSid2;
  NeedsFreeMemory: Boolean;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  // Request translation of one name
  Result.Location := 'LsaLookupNames2';
  Result.Status := LsaLookupNames2(hxPolicy.Handle, 0, 1,
    TLsaUnicodeString.From(AccountName), BufferDomain, BufferTranslatedSid);

  // LsaLookupNames2 allocates memory even on some errors
  NeedsFreeMemory := Result.IsSuccess or (Result.Status = STATUS_NONE_MAPPED);

  if Result.IsSuccess then
    Result := RtlxCopySid(BufferTranslatedSid.Sid, Sid);

  if NeedsFreeMemory then
  begin
    LsaFreeMemory(BufferDomain);
    LsaFreeMemory(BufferTranslatedSid);
  end;
end;

function LsaxLookupNameOrSddl;
begin
  // Lookup the account name first since someone might create one with a name
  // that is also a valid SDDL.
  Result := LsaxLookupName(AccountOrSddl, Sid, hxPolicy);

  // Try SDDL on failure. Note that in addition to the S-1-* strings we are also
  // checking about ~40 double-letter abbreviations. See [MS-DTYP] for details.
  if not Result.IsSuccess and RtlxStringToSid(AccountOrSddl, Sid).IsSuccess then
    Result.Status := STATUS_SOME_NOT_MAPPED; // A successful code
end;

function LsaxCanonicalizeName;
var
  Sid: ISid;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  // Convert the user-supplied name to a SID
  Result := LsaxLookupName(AccountName, Sid, hxPolicy);

  if not Result.IsSuccess then
    Exit;

  // Convert the SID back to an account name name
  Result := LsaxLookupSid(Sid.Data, CanonicalName, hxPolicy);

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
begin
  Result.Location := 'LsaGetUserName';
  Result.Status := LsaGetUserName(BufferUser, BufferDomain);

  if Result.IsSuccess then
  begin
    Domain := BufferDomain.ToString;
    UserName := BufferUser.ToString;

    LsaFreeMemory(BufferUser);
    LsaFreeMemory(BufferDomain);
  end;
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

function LsaxManageSidNameMapping(
  OperationType: TLsaSidNameMappingOperationType;
  Input: TLsaSidNameMappingOperation
): TNtxStatus;
var
  pOutput: PLsaSidNameMappingOperationGenericOutput;
begin
  pOutput := nil;

  Result.Location := 'LsaManageSidNameMapping';
  Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  Result.Status := LsaManageSidNameMapping(OperationType, Input, pOutput);

  // The function uses a custom way to report some errors
  if not Result.IsSuccess and Assigned(pOutput) then
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

  if Assigned(pOutput) then
    LsaFreeMemory(pOutput);
end;

function LsaxAddSidNameMapping;
var
  Input: TLsaSidNameMappingOperation;
begin
  // When creating a mapping for a domain, it can only be S-1-5-x
  // where x is in range [SECURITY_MIN_BASE_RID .. SECURITY_MAX_BASE_RID]

  Input.AddInput.DomainName := TLsaUnicodeString.From(Domain);
  Input.AddInput.AccountName := TLsaUnicodeString.From(User);
  Input.AddInput.Sid := Sid;
  Input.AddInput.Flags := 0;

  Result := LsaxManageSidNameMapping(LsaSidNameMappingOperation_Add, Input);
end;

function LsaxRemoveSidNameMapping;
var
  Input: TLsaSidNameMappingOperation;
begin
  Input.RemoveInput.DomainName := TLsaUnicodeString.From(Domain);
  Input.RemoveInput.AccountName := TLsaUnicodeString.From(User);

  Result := LsaxManageSidNameMapping(LsaSidNameMappingOperation_Remove, Input);
end;

end.
