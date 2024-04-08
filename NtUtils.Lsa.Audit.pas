unit NtUtils.Lsa.Audit;

{
  This module provides function for working with global and per-user auditing
  policy, including token-based overrides.
}

interface

uses
  Ntapi.WinNt, Ntapi.NtSecApi, Ntapi.ntseapi, NtUtils, DelphiUtils.AutoObjects,
  DelphiApi.Reflection;

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
[Access(AUDIT_QUERY_SYSTEM_POLICY)]
[RequiredPrivilege(SE_AUDIT_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpForBypassingChecks)]
function LsaxQuerySystemAudit(
  out Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

// Set system-wide audit settings
[Access(AUDIT_SET_SYSTEM_POLICY)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpForBypassingChecks)]
function LsaxSetSystemAudit(
  const Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

// Query per-user audit override settings
[Access(AUDIT_QUERY_USER_POLICY)]
[RequiredPrivilege(SE_AUDIT_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpForBypassingChecks)]
function LsaxQueryUserAudit(
  const Sid: ISid;
  out Entries: TArray<TAuditPolicyEntry>
): TNtxStatus;

// Set per-user audit override settings
[Access(AUDIT_SET_USER_POLICY)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpForBypassingChecks)]
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

// Query the security descriptor that protects the audit policy
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function LsaxQueryAuditSecurity(
  [Reserved] const Unused: IHandle;
  Info: TSecurityInformation;
  out SD: ISecurityDescriptor
): TNtxStatus;

// Set the security descriptor that protects the audit policy
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function LsaxSetAuditSecurity(
  [Reserved] const Unused: IHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

// Query the global SACL for a specific object types such as "File" and "Key"
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function LsaxQueryGlobalSacl(
  out Acl: IAcl;
  const ObjectTypeName: String
): TNtxStatus;

// Query the global SACL for a specific object types such as "File" and "Key"
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function LsaxSetGlobalSacl(
  const ObjectTypeName: String;
  [in, opt] Acl: PAcl
): TNtxStatus;

implementation

uses
   Ntapi.ntrtl, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TAuditAutoMemory = class(TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

procedure TAuditAutoMemory.Release;
begin
  if Assigned(FData) then
    AuditFree(FData);

  FData := nil;
  inherited;
end;

function LsaxDelayAuditFree(
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
  GuidsDeallocator, SubGuidsDeallocator: IAutoReleasable;
  Count, SubCount: Cardinal;
  TempGuid: TGuid;
  i, j, k: Integer;
begin
  // Enumerate categories first
  Result.Location := 'AuditEnumerateCategories';
  Result.Win32Result := AuditEnumerateCategories(Guids, Count);

  if not Result.IsSuccess then
    Exit;

  GuidsDeallocator := LsaxDelayAuditFree(Guids);
  SetLength(Mapping, Count);

  for i := 0 to High(Mapping) do
    Mapping[i].Category := Guids{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};

  for i := 0 to High(Mapping) do
  begin
    // Enumerate subcategories per category
    Result.Location := 'AuditEnumerateSubCategories';
    Result.Win32Result := AuditEnumerateSubCategories(@Mapping[i].Category,
      False, SubGuids, SubCount);

    if not Result.IsSuccess then
      Exit;

    SubGuidsDeallocator := LsaxDelayAuditFree(SubGuids);
    SetLength(Mapping[i].SubCategories, SubCount);

    for j := 0 to High(Mapping[i].SubCategories) do
      Mapping[i].SubCategories[j] := SubGuids{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF};
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
  BufferDeallocator: IAutoReleasable;
begin
  Result.Location := 'AuditLookupCategoryNameW';
  Result.Win32Result := AuditLookupCategoryNameW(Category, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := LsaxDelayAuditFree(Buffer);
  Name := String(Buffer);
end;

function LsaxLookupAuditSubCategoryName;
var
  Buffer: PWideChar;
  BufferDeallocator: IAutoReleasable;
begin
  Result.Location := 'AuditLookupSubCategoryNameW';
  Result.Win32Result := AuditLookupSubCategoryNameW(SubCategory, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := LsaxDelayAuditFree(Buffer);
  Name := String(Buffer);
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
  BufferDeallocator: IAutoReleasable;
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
  Result.LastCall.Expects<TAuditAccessMask>(AUDIT_QUERY_SYSTEM_POLICY);
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditQuerySystemPolicy(SubCategories,
    Length(SubCategories), Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := LsaxDelayAuditFree(Buffer);
  SetLength(Entries, Length(SubCategories));

  for i := 0 to High(Entries) do
  begin
    Entries[i].SubCategory := SubCategories[i];
    Entries[i].Policy := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .AuditingInformation;
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
  Result.LastCall.Expects<TAuditAccessMask>(AUDIT_SET_SYSTEM_POLICY);
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditSetSystemPolicy(Audit, Length(Audit));
end;

function LsaxQueryUserAudit;
var
  SubCategories: TArray<TGuid>;
  Buffer: PAuditPolicyInformationArray;
  BufferDeallocator: IAutoReleasable;
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
  Result.LastCall.Expects<TAuditAccessMask>(AUDIT_QUERY_USER_POLICY);
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditQueryPerUserPolicy(Sid.Data, SubCategories,
    Length(SubCategories), Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := LsaxDelayAuditFree(Buffer);
  SetLength(Entries, Length(SubCategories));

  for i := 0 to High(Entries) do
  begin
    Entries[i].SubCategory := SubCategories[i];
    Entries[i].PolicyOverride := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}
      .AuditingInformation;
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
  Result.LastCall.Expects<TAuditAccessMask>(AUDIT_SET_USER_POLICY);
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditSetPerUserPolicy(Sid.Data, Audit, Length(Audit));
end;

function TTokenAuditPolicyHelper.GetSubCategory;
begin
  // TTokenAuditPolicy stores two sub-categories in each byte
  // Extract required half of the byte
  if Index and 1 = 0 then
    Result := PerUserPolicy{$R-}[Index shr 1]{$IFDEF R+}{$R+}{$ENDIF} and $0F
  else
    Result := PerUserPolicy{$R-}[Index shr 1]{$IFDEF R+}{$R+}{$ENDIF} shr 4;
end;

procedure TTokenAuditPolicyHelper.SetSubCategory;
var
  PolicyByte: Byte;
begin
  // PER_USER_AUDIT_NONE encodes as zero, other flags remain
  Value := Value and $0F;
  PolicyByte := PerUserPolicy{$R-}[Index shr 1]{$IFDEF R+}{$R+}{$ENDIF};

  // Since each byte stores policies for two sub-categories, we should modify
  // only one of them, preserving the other.
  if Index and 1 = 0 then
    PolicyByte := (PolicyByte and $F0) or Value
  else
    PolicyByte := (PolicyByte and $0F) or (Value shl 4);

  PerUserPolicy{$R-}[Index shr 1]{$IFDEF R+}{$R+}{$ENDIF} := PolicyByte;
end;

function LsaxUserAuditToTokenAudit;
var
  i: Integer;
begin
  // Compute the size according to Winapi's definition
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

function LsaxQueryAuditSecurity;
var
  Buffer: PSecurityDescriptor;
begin
  Result.Location := 'AuditQuerySecurity';
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditQuerySecurity(Info, Buffer);

  if Result.IsSuccess then
    IMemory(SD) := TAuditAutoMemory.Capture(Buffer,
      RtlLengthSecurityDescriptor(Buffer));
end;

function LsaxSetAuditSecurity;
begin
  Result.Location := 'AuditSetSecurity';
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditSetSecurity(Info, SD);
end;

function LsaxQueryGlobalSacl;
var
  Buffer: PAcl;
  AclInfo: TAclSizeInformation;
begin
  Result.Location := 'AuditQueryGlobalSaclW';
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditQueryGlobalSaclW(PWideChar(ObjectTypeName), Buffer);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlQueryInformationAcl';
  Result.LastCall.UsesInfoClass(AclSizeInformation, icQuery);
  Result.Status := RtlQueryInformationAcl(Buffer, @AclInfo, SizeOf(AclInfo),
    AclSizeInformation);

  if Result.IsSuccess then
    IMemory(Acl) := TAuditAutoMemory.Capture(Buffer, AclInfo.AclBytesTotal);
end;

function LsaxSetGlobalSacl;
begin
  Result.Location := 'AuditSetGlobalSaclW';
  Result.LastCall.ExpectedPrivilege := SE_SECURITY_PRIVILEGE;
  Result.Win32Result := AuditSetGlobalSaclW(PWideChar(ObjectTypeName), Acl);
end;

end.
