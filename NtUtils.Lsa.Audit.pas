unit NtUtils.Lsa.Audit;

{
  This module provides function for working with global and per-user auditing
  policy, including token-based overrides.
}

interface

uses
  Ntapi.WinNt, Ntapi.NtSecApi, Ntapi.ntseapi, NtUtils,
  DelphiUtils.AutoObjects;

type
  TAuditCategoryMapping = record
    Category: TGuid;
    SubCategories: TArray<TGuid>;
  end;

  TAuditPolicyEntry = record
    Category: TGuid;
    SubCategory: TGuid;
  case Boolean of
    False: (Policy: TAuditEventPolicy);
    True: (PolicyOverride: TAuditEventPolicyOverride);
  end;

  TTokenAuditPolicyHelper = record helper for TTokenAuditPolicy
  private
    function GetSubCategory(Index: Integer): TAuditEventPolicyOverride;
    procedure SetSubCategory(Index: Integer; Value: TAuditEventPolicyOverride);
  public
    property SubCategory[Index: Integer]: TAuditEventPolicyOverride read GetSubCategory write SetSubCategory;
  end;

// Enumerate audit categories and their sub categories
function LsaxEnumerateAuditMapping(
  out Mapping: TArray<TAuditCategoryMapping>
): TNtxStatus;

// Get a friendly name for an audit category
function LsaxLookupAuditCategoryName(
  const Category: TGuid;
  out Name: String
): TNtxStatus;

// Get a friendly name for an audit sub category
function LsaxLookupAuditSubCategoryName(
  const SubCategory: TGuid;
  out Name: String
): TNtxStatus;

// Create an array of empty audit settings
function LsaxCreateEmptyAudit(
  out Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

// Query system-wide audit settings
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
function LsaxQuerySystemAudit(
  out Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

// Set system-wide audit settings
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function LsaxSetSystemAudit(
  const Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

// Query per-user audit override settins
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
function LsaxQueryUserAudit(
  const Sid: ISid;
  out Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

// Set per-user audit override settins
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function LsaxSetUserAudit(
  const Sid: ISid;
  const Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

// Convert per-user audit settings to token audit settings
// Note: the entries must include all sub categories in order returned by
// LsaxCreateEmptyAudit
function LsaxUserAuditToTokenAudit(
  const Entries: TArray<TAuditPolicyEntry>
): IMemory<PTokenAuditPolicy>;

// Convert token audit settings to per-user audit settings
function LsaxTokenAuditToUserAudit(
  [in] Buffer: PTokenAuditPolicy;
  out Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

implementation

uses
   DelphiUtils.Arrays;

function LsaxpDelayAutoFree(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      AuditFree(Buffer);
    end
  );
end;

function LsaxEnumerateAuditMapping;
const
  // See comments below
  FIXUP_ID: array [0..1] of Cardinal = ($0CCE921B, $0CCE9227);
  FIXUP_SHIFT: array [0..1] of Integer = (-2, -6);
var
  Guids, SubGuids: PGuidArray;
  Count, SubCount: Cardinal;
  TempGuid: TGuid;
  i, j, k: Integer;
begin
  // Enumerate categories first
  Result.Location := 'AuditEnumerateCategories';
  Result.Win32Result := AuditEnumerateCategories(Guids, Count);

  if not Result.IsSuccess then
    Exit;

  LsaxpDelayAutoFree(Guids);
  SetLength(Mapping, Count);

  for i := 0 to High(Mapping) do
    Mapping[i].Category := Guids{$R-}[i]{$R+};

  for i := 0 to High(Mapping) do
  begin
    // Enumerate subcategories per category
    Result.Location := 'AuditEnumerateSubCategories';
    Result.Win32Result := AuditEnumerateSubCategories(@Mapping[i].Category,
      False, SubGuids, SubCount);

    if not Result.IsSuccess then
      Exit;

    LsaxpDelayAutoFree(SubGuids);
    SetLength(Mapping[i].SubCategories, SubCount);

    for j := 0 to High(Mapping[i].SubCategories) do
      Mapping[i].SubCategories[j] := SubGuids{$R-}[j]{$R+};
  end;

  // The system stores per-user audit overrides in tokens in compact form (see
  // Ntapi.ntseapi.TTokenAuditPolicy) where each byte represents the policy for
  // two sub-categories. These sub-categories are grouped by their category,
  // but, for unknown reason, their order differs slightly from what you would
  // get by flattening the arrays we are about to return. It appears that two
  // sub-categories ("Special Logon" and "Other Object Access Events") are
  // misplaced by 2 and 6, respectively; the rest matches precisely. Fix the
  // order manually here, making the output compatible with TTokenAuditPolicy.

  for i := 0 to High(Mapping) do
    for j := 0 to High(Mapping[i].SubCategories) do
      for k := 0 to High(FIXUP_ID) do
        if Mapping[i].SubCategories[j].D1 = FIXUP_ID[k] then
        begin
          TempGuid := Mapping[i].SubCategories[j];
          Delete(Mapping[i].SubCategories, j, 1);
          Insert(TempGuid, Mapping[i].SubCategories, j + FIXUP_SHIFT[k]);
        end;
end;

function LsaxLookupAuditCategoryName;
var
  Buffer: PWideChar;
begin
  Result.Location := 'AuditLookupCategoryNameW';
  Result.Win32Result := AuditLookupCategoryNameW(Category, Buffer);

  if Result.IsSuccess then
  begin
    LsaxpDelayAutoFree(Buffer);
    Name := String(Buffer);
  end;
end;

function LsaxLookupAuditSubCategoryName;
var
  Buffer: PWideChar;
begin
  Result.Location := 'AuditLookupSubCategoryNameW';
  Result.Win32Result := AuditLookupSubCategoryNameW(SubCategory, Buffer);

  if Result.IsSuccess then
  begin
    LsaxpDelayAutoFree(Buffer);
    Name := String(Buffer);
  end;
end;

function LsaxCreateEmptyAudit;
var
  Mapping: TArray<TAuditCategoryMapping>;
begin
  Result := LsaxEnumerateAuditMapping(Mapping);

  if not Result.IsSuccess then
    Exit;

  // Expand all sub-categories and concatenate them, converting in the process
  Entries := TArray.FlattenEx<TAuditCategoryMapping, TAuditPolicyEntry>(
    Mapping,
    function (const Entry: TAuditCategoryMapping): TArray<TAuditPolicyEntry>
    var
      i: Integer;
    begin
      SetLength(Result, Length(Entry.SubCategories));

      for i := 0 to High(Result) do
      begin
        Result[i].Category := Entry.Category;
        Result[i].SubCategory := Entry.SubCategories[i];
        Result[i].Policy := POLICY_AUDIT_EVENT_UNCHANGED;
      end;
    end
  );
end;

function LsaxQuerySystemAudit;
var
  SubCategories: TArray<TGuid>;
  Buffer: PAuditPolicyInformationArray;
  i: Integer;
begin
  // Retrieve all sub-categories
  Result := LsaxCreateEmptyAudit(Entries);

  if not Result.IsSuccess then
    Exit;

  SetLength(SubCategories, Length(Entries));

  for i := 0 to High(SubCategories) do
    SubCategories[i] := Entries[i].SubCategory;

  // Query settings for all of them at once
  Result.Location := 'AuditQuerySystemPolicy';
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditQuerySystemPolicy(SubCategories,
    Length(SubCategories), Buffer);

  if not Result.IsSuccess then
    Exit;

  LsaxpDelayAutoFree(Buffer);
  SetLength(Entries, Length(SubCategories));

  for i := 0 to High(Entries) do
  begin
    Entries[i].SubCategory := SubCategories[i];
    Entries[i].Policy := Buffer{$R-}[i]{$R+}.AuditingInformation;
  end;
end;

function LsaxSetSystemAudit;
var
  Audit: TArray<TAuditPolicyInformation>;
  i: Integer;
begin
  SetLength(Audit, Length(Entries));

  for i := 0 to High(Audit) do
  begin
    Audit[i].AuditSubCategoryGuid := Entries[i].SubCategory;
    Audit[i].AuditingInformation := Entries[i].Policy;

    // Explicitly convert unchanged to none
    if Audit[i].AuditingInformation = POLICY_AUDIT_EVENT_UNCHANGED then
      Audit[i].AuditingInformation := POLICY_AUDIT_EVENT_NONE;
  end;

  Result.Location := 'AuditSetSystemPolicy';
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditSetSystemPolicy(Audit, Length(Audit));
end;

function LsaxQueryUserAudit;
var
  SubCategories: TArray<TGuid>;
  Buffer: PAuditPolicyInformationArray;
  i: Integer;
begin
  // Retrieve all sub-categories
  Result := LsaxCreateEmptyAudit(Entries);

  if not Result.IsSuccess then
    Exit;

  SetLength(SubCategories, Length(Entries));

  for i := 0 to High(SubCategories) do
    SubCategories[i] := Entries[i].SubCategory;

  // Query settings for all of them at once
  Result.Location := 'AuditQueryPerUserPolicy';
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditQueryPerUserPolicy(Sid.Data, SubCategories,
    Length(SubCategories), Buffer);

  if not Result.IsSuccess then
    Exit;

  LsaxpDelayAutoFree(Buffer);
  SetLength(Entries, Length(SubCategories));

  for i := 0 to High(Entries) do
  begin
    Entries[i].SubCategory := SubCategories[i];
    Entries[i].PolicyOverride := Buffer{$R-}[i]{$R+}.AuditingInformation;
  end;
end;

function LsaxSetUserAudit;
var
  i: Integer;
  Audit: TArray<TAuditPolicyInformation>;
begin
  SetLength(Audit, Length(Entries));

  for i := 0 to High(Audit) do
  begin
    Audit[i].AuditSubcategoryGUID := Entries[i].SubCategory;
    Audit[i].AuditingInformation := Entries[i].PolicyOverride;

    // Although on read Unchanged means that the audit is disabled, we need to
    // explicitly convert it to None on write.
    if Audit[i].AuditingInformation = PER_USER_POLICY_UNCHANGED then
      Audit[i].AuditingInformation := PER_USER_AUDIT_NONE;
  end;

  Result.Location := 'AuditSetPerUserPolicy';
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditSetPerUserPolicy(Sid.Data, Audit, Length(Audit));
end;

function TTokenAuditPolicyHelper.GetSubCategory;
begin
  // TTokenAuditPolicy stores two sub-categories in each byte
  // Extract required half of the byte
  if Index and 1 = 0 then
    Result := PerUserPolicy{$R-}[Index shr 1]{$R+} and $0F
  else
    Result := PerUserPolicy{$R-}[Index shr 1]{$R+} shr 4;
end;

procedure TTokenAuditPolicyHelper.SetSubCategory;
var
  PolicyByte: Byte;
begin
  // PER_USER_AUDIT_NONE encodes as zero, other flags remain
  Value := Value and $0F;
  PolicyByte := PerUserPolicy{$R-}[Index shr 1]{$R+};

  // Since each byte stores policies for two sub-categories, we should modify
  // only one of them, preserving the other.
  if Index and 1 = 0 then
    PolicyByte := (PolicyByte and $F0) or Value
  else
    PolicyByte := (PolicyByte and $0F) or (Value shl 4);

  PerUserPolicy{$R-}[Index shr 1]{$R+} := PolicyByte;
end;

function LsaxUserAuditToTokenAudit;
var
  i: Integer;
begin
  // Compute the size accordaning to Winapi's definition
  IMemory(Result) := Auto.AllocateDynamic((Length(Entries) shr 1) + 1);

  for i := 0 to High(Entries) do
    Result.Data.SubCategory[i] := Entries[i].PolicyOverride;
end;

function LsaxTokenAuditToUserAudit;
var
  i: Integer;
begin
  Result := LsaxCreateEmptyAudit(Entries);

  if not Result.IsSuccess then
    Exit;

  for i := 0 to High(Entries) do
    Entries[i].PolicyOverride := Buffer.SubCategory[i];
end;

end.
