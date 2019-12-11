unit NtUtils.Lsa.Sid;

interface

uses
  Winapi.WinNt, NtUtils.Exceptions, NtUtils.Security.Sid, NtUtils.Lsa;

type
  TTranslatedName = record
    DomainName, UserName: String;
    SidType: TSidNameUse;
    function FullName: String;
  end;

// Convert SIDs to account names
function LsaxLookupSid(Sid: PSid; out Name: TTranslatedName; hxPolicy:
  ILsaHandle = nil): TNtxStatus;
function LsaxLookupSids(Sids: TArray<PSid>; out Names: TArray<TTranslatedName>;
  hxPolicy: ILsaHandle = nil): TNtxStatus;

// Convert SID to full account name or at least to SDDL
function LsaxSidToString(Sid: PSid): String;

// Convert an account name / SDDL string to a SID
function LsaxLookupName(AccountName: String; out Sid: ISid;  hxPolicy:
  ILsaHandle = nil): TNtxStatus;
function LsaxLookupNameOrSddl(AccountOrSddl: String; out Sid: ISid; hxPolicy:
  ILsaHandle = nil): TNtxStatus;

// Get current user name and domain
function LsaxGetUserName(out Domain, UserName: String): TNtxStatus; overload;
function LsaxGetUserName(out FullName: String): TNtxStatus; overload;

implementation

uses
  Winapi.ntlsa, Winapi.NtSecApi, Ntapi.ntstatus, System.SysUtils;

{ TTranslatedName }

function TTranslatedName.FullName: String;
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

{ Functions }

function LsaxLookupSid(Sid: PSid; out Name: TTranslatedName;
  hxPolicy: ILsaHandle): TNtxStatus;
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

function LsaxLookupSids(Sids: TArray<PSid>; out Names: TArray<TTranslatedName>;
  hxPolicy: ILsaHandle = nil): TNtxStatus;
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
  Result.Status := LsaLookupSids(hxPolicy.Value, Length(Sids), Sids,
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
      Names[i].DomainName := BufferDomains.Domains[
        BufferNames{$R-}[i]{$R+}.DomainIndex].Name.ToString
    else
      Names[i].DomainName := '';
  end;

  LsaFreeMemory(BufferDomains);
  LsaFreeMemory(BufferNames);
end;

function LsaxSidToString(Sid: PSid): String;
var
  AccountName: TTranslatedName;
begin
  if LsaxLookupSid(Sid, AccountName).IsSuccess and not (AccountName.SidType in
    [SidTypeUndefined, SidTypeInvalid, SidTypeUnknown]) then
    Result := AccountName.FullName
  else
    Result := RtlxConvertSidToString(Sid);
end;

function LsaxLookupName(AccountName: String; out Sid: ISid; hxPolicy:
  ILsaHandle): TNtxStatus;
var
  Name: TLsaUnicodeString;
  BufferDomain: PLsaReferencedDomainList;
  BufferTranslatedSid: PLsaTranslatedSid2;
  NeedsFreeMemory: Boolean;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  Name.FromString(AccountName);

  // Request translation of one name
  Result.Location := 'LsaLookupNames2';
  Result.Status := LsaLookupNames2(hxPolicy.Value, 0, 1, Name, BufferDomain,
    BufferTranslatedSid);

  // LsaLookupNames2 allocates memory even on some errors
  NeedsFreeMemory := Result.IsSuccess or (Result.Status = STATUS_NONE_MAPPED);

  if Result.IsSuccess then
    Result := RtlxCaptureCopySid(BufferTranslatedSid.Sid, Sid);

  if NeedsFreeMemory then
  begin
    LsaFreeMemory(BufferDomain);
    LsaFreeMemory(BufferTranslatedSid);
  end;
end;

function LsaxLookupNameOrSddl(AccountOrSddl: String; out Sid: ISid; hxPolicy:
  ILsaHandle): TNtxStatus;
var
  Status: TNtxStatus;
begin
  // Since someone might create an account which name is a valid SDDL string,
  // lookup the account name first. Parse it as SDDL only if this lookup failed.
  Result := LsaxLookupName(AccountOrSddl, Sid, hxPolicy);

  if Result.IsSuccess then
    Exit;

  // The string can start with "S-1-" and represent an arbitrary SID or can be
  // one of ~40 double-letter abbreviations. See [MS-DTYP] for SDDL definition.
  if (Length(AccountOrSddl) = 2) or AccountOrSddl.StartsWith('S-1-', True) then
  begin
    Status := RtlxConvertStringToSid(AccountOrSddl, Sid);

    if Status.IsSuccess then
      Result := Status;
  end;
end;

function LsaxGetUserName(out Domain, UserName: String): TNtxStatus;
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

function LsaxGetUserName(out FullName: String): TNtxStatus;
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
    Result.Location := 'LsaxGetUserName';
    Result.Status := STATUS_UNSUCCESSFUL;
  end;
end;

end.
