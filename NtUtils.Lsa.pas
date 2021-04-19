unit NtUtils.Lsa;

{
  This module allows interoperation with Local Security Authority for managing
  privilege and logon rights assignment.
}

interface

uses
  Winapi.WinNt, Winapi.ntlsa, Ntapi.ntseapi, NtUtils, DelphiUtils.AutoObject;

type
  TLsaHandle = Winapi.ntlsa.TLsaHandle;
  ILsaHandle = DelphiUtils.AutoObject.IHandle;

  TPrivilegeDefinition = record
    Name: String;
    LocalValue: TLuid;
  end;

  TLogonRightRec = record
    Value: TSystemAccess;
    IsAllowedType: Boolean;
    Name, Description: String;
  end;

{ --------------------------------- Policy ---------------------------------- }

// Open LSA for desired access
function LsaxOpenPolicy(
  out hxPolicy: ILsaHandle;
  DesiredAccess: TLsaPolicyAccessMask;
  [opt] const SystemName: String = ''
): TNtxStatus;

// Make sure the policy handle is provided
function LsaxpEnsureConnected(
  var hxPolicy: ILsaHandle;
  DesiredAccess: TLsaPolicyAccessMask
): TNtxStatus;

// Query policy information
function LsaxQueryPolicy(
  hPolicy: TLsaHandle;
  InfoClass: TPolicyInformationClass;
  out xMemory: IMemory
): TNtxStatus;

// Set policy information
function LsaxSetPolicy(
  hPolicy: TLsaHandle;
  InfoClass: TPolicyInformationClass;
  [in] Buffer: Pointer
): TNtxStatus;

{ --------------------------------- Accounts -------------------------------- }

// Open an account from LSA database
function LsaxOpenAccount(
  out hxAccount: ILsaHandle;
  [in] AccountSid: PSid;
  DesiredAccess: TLsaAccountAccessMask;
  [opt] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Add an account to LSA database
function LsaxCreateAccount(
  out hxAccount: ILsaHandle;
  [in] AccountSid: PSid;
  [opt] hxPolicy: ILsaHandle = nil;
  DesiredAccess: TLsaAccountAccessMask = ACCOUNT_ALL_ACCESS
): TNtxStatus;

// Delete account from LSA database
function LsaxDeleteAccount(
  hAccount: TLsaHandle
): TNtxStatus;

// Enumerate account in the LSA database
function LsaxEnumerateAccounts(
  hPolicy: TLsaHandle;
  out Accounts: TArray<ISid>
): TNtxStatus;

// Enumerate privileges assigned to an account
function LsaxEnumeratePrivilegesAccount(
  hAccount: TLsaHandle;
  out Privileges: TArray<TPrivilege>
): TNtxStatus;

// Enumerate privileges assigned to an account using its SID
function LsaxEnumeratePrivilegesAccountBySid(
  [in] AccountSid: PSid;
  out Privileges: TArray<TPrivilege>
): TNtxStatus;

// Assign privileges to an account
function LsaxAddPrivilegesAccount(
  hAccount: TLsaHandle;
  const Privileges: TArray<TPrivilege>
): TNtxStatus;

// Revoke privileges to an account
function LsaxRemovePrivilegesAccount(
  hAccount: TLsaHandle;
  RemoveAll: Boolean;
  [opt] const Privileges: TArray<TPrivilege>
): TNtxStatus;

// Assign & revoke privileges to account in one operation
function LsaxManagePrivilegesAccount(
  [in] AccountSid: PSid;
  RemoveAll: Boolean;
  [opt] const Add: TArray<TPrivilege>;
  [opt] const Remove: TArray<TPrivilege>
): TNtxStatus;

// Query logon rights of an account
function LsaxQueryRightsAccount(
  hAccount: TLsaHandle;
  out SystemAccess: TSystemAccess
): TNtxStatus;

// Query logon rights of an account using its SID
function LsaxQueryRightsAccountBySid(
  [in] AccountSid: PSid;
  out SystemAccess: TSystemAccess
): TNtxStatus;

// Set logon rights of an account
function LsaxSetRightsAccount(
  hAccount: TLsaHandle;
  SystemAccess: TSystemAccess
): TNtxStatus;

function LsaxSetRightsAccountBySid(
  [in] AccountSid: PSid;
  SystemAccess: TSystemAccess
): TNtxStatus;

{ -------------------------------- Privileges ------------------------------- }

// Enumerate all privileges on the system
function LsaxEnumeratePrivileges(
  out Privileges: TArray<TPrivilegeDefinition>;
  [opt] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Convert a numerical privilege value to internal name
function LsaxQueryPrivilege(
  const Luid: TLuid;
  out Name: String;
  out DisplayName: String;
  [opt] hxPolicy: ILsaHandle = nil
): TNtxStatus;

// Get the minimal integrity level required to use a specific privilege
function LsaxQueryIntegrityPrivilege(
  const Luid: TLuid
): TIntegriyRid;

{ ------------------------------- Logon Process ----------------------------- }

// Establish a connection to LSA without verification
function LsaxConnectUntrusted(
  out hxLsaConnection: ILsaHandle
): TNtxStatus;

// Establish a connection to LSA with verification
function LsaxRegisterLogonProcess(
  out hxLsaConnection: ILsaHandle;
  const Name: AnsiString
): TNtxStatus;

// Find an authentication package by name
function LsaxLookupAuthPackage(
  out PackageId: Cardinal;
  const PackageName: AnsiString;
  [opt] hxLsaConnection: ILsaHandle = nil
): TNtxStatus;

{ --------------------------------- Security -------------------------------- }

// Query security descriptor of a LSA object
function LsaxQuerySecurityObject(
  LsaHandle: TLsaHandle;
  Info: TSecurityInformation;
  out SD: ISecDesc
): TNtxStatus;

// Set security descriptor on a LSA object
function LsaxSetSecurityObject(
  LsaHandle: TLsaHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Winapi.NtSecApi, NtUtils.Tokens.Misc,
  NtUtils.Security.Sid;

type
  TLsaAutoHandle = class(TCustomAutoHandle, ILsaHandle)
    procedure Release; override;
  end;

  TLsaAutoMemory = class(TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

{ Common & Policy }

procedure TLsaAutoHandle.Release;
begin
  LsaClose(FHandle);
  inherited;
end;

procedure TLsaAutoMemory.Release;
begin
  LsaFreeMemory(FAddress);
  inherited;
end;

function LsaxOpenPolicy;
var
  ObjAttr: TObjectAttributes;
  hPolicy: TLsaHandle;
begin
  InitializeObjectAttributes(ObjAttr);

  Result.Location := 'LsaOpenPolicy';
  Result.LastCall.AttachAccess(DesiredAccess);

  Result.Status := LsaOpenPolicy(TLsaUnicodeString.From(SystemName).RefOrNull,
    ObjAttr, DesiredAccess, hPolicy);

  if Result.IsSuccess then
    hxPolicy := TLsaAutoHandle.Capture(hPolicy);
end;

function LsaxpEnsureConnected;
begin
  if not Assigned(hxPolicy) then
    Result := LsaxOpenPolicy(hxPolicy, DesiredAccess)
  else
    Result.Status := STATUS_SUCCESS
end;

function LsaxQueryPolicy;
var
  Buffer: Pointer;
begin
  Result.Location := 'LsaQueryInformationPolicy';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedPolicyQueryAccess(InfoClass));
  Result.Status := LsaQueryInformationPolicy(hPolicy, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TLsaAutoMemory.Capture(Buffer, 0);
end;

function LsaxSetPolicy;
begin
  Result.Location := 'LsaSetInformationPolicy';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(ExpectedPolicySetAccess(InfoClass));
  Result.Status := LsaSetInformationPolicy(hPolicy, InfoClass, Buffer);
end;

{ Accounts }

function LsaxOpenAccount;
var
  hAccount: TLsaHandle;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_VIEW_LOCAL_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LsaOpenAccount';
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

  Result.Status := LsaOpenAccount(hxPolicy.Handle, AccountSid, DesiredAccess,
    hAccount);

  if Result.IsSuccess then
    hxAccount := TLsaAutoHandle.Capture(hAccount);
end;

function LsaxCreateAccount;
var
  hAccount: TLsaHandle;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_CREATE_ACCOUNT);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LsaCreateAccount';
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_CREATE_ACCOUNT);

  Result.Status := LsaCreateAccount(hxPolicy.Handle, AccountSid, DesiredAccess,
    hAccount);

  if Result.IsSuccess then
    hxAccount := TLsaAutoHandle.Capture(hAccount);
end;

function LsaxDeleteAccount;
begin
  Result.Location := 'LsaDelete';
  Result.LastCall.Expects<TLsaAccountAccessMask>(_DELETE);
  Result.Status := LsaDelete(hAccount);
end;

function LsaxEnumerateAccounts;
var
  EnumContext: TLsaEnumerationHandle;
  Buffer: PSidArray;
  Count, i: Integer;
begin
  EnumContext := 0;
  Result.Location := 'LsaEnumerateAccounts';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

  Result.Status := LsaEnumerateAccounts(hPolicy, EnumContext, Buffer,
    MAX_PREFERRED_LENGTH, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Accounts, Count);

  for i := 0 to High(Accounts) do
  begin
    Result := RtlxCopySid(Buffer{$R-}[i]{$R+}, Accounts[i]);

    if not Result.IsSuccess then
      Break;
  end;

  LsaFreeMemory(Buffer);
end;

function LsaxEnumeratePrivilegesAccount;
var
  PrivilegeSet: PPrivilegeSet;
  i: Integer;
begin
  Result.Location := 'LsaEnumeratePrivilegesOfAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_VIEW);

  Result.Status := LsaEnumeratePrivilegesOfAccount(hAccount, PrivilegeSet);

  if not Result.IsSuccess then
    Exit;

  SetLength(Privileges, PrivilegeSet.PrivilegeCount);

  for i := 0 to High(Privileges) do
    Privileges[i] := PrivilegeSet.Privilege{$R-}[i]{$R+};

  LsaFreeMemory(PrivilegeSet);
end;

function LsaxEnumeratePrivilegesAccountBySid;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid, ACCOUNT_VIEW);

  if Result.IsSuccess then
    Result := LsaxEnumeratePrivilegesAccount(hxAccount.Handle, Privileges);
end;

function LsaxAddPrivilegesAccount;
begin
  Result.Location := 'LsaAddPrivilegesToAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_PRIVILEGES);

  Result.Status := LsaAddPrivilegesToAccount(hAccount,
    NtxpAllocPrivilegeSet(Privileges).Data);
end;

function LsaxRemovePrivilegesAccount;
begin
  Result.Location := 'LsaRemovePrivilegesFromAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_PRIVILEGES);

  Result.Status := LsaRemovePrivilegesFromAccount(hAccount, RemoveAll,
    NtxpAllocPrivilegeSet(Privileges).Data);
end;

function LsaxManagePrivilegesAccount;
var
  hxAccount: ILsaHandle;
begin
  if (Length(Add) = 0) and (Length(Remove) = 0) and not RemoveAll then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Try to open the account
  Result := LsaxOpenAccount(hxAccount, AccountSid, ACCOUNT_ADJUST_PRIVILEGES);

  // If there is no such account
  if Result.Matches(STATUS_OBJECT_NAME_NOT_FOUND, 'LsaOpenAccount') then
  begin
    if Length(Add) = 0 then
    begin
      // No account - no privileges - nothing to remove
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    // We need to add the account to LSA database in order to assign privileges
    Result := LsaxCreateAccount(hxAccount, AccountSid, nil,
      ACCOUNT_ADJUST_PRIVILEGES);
  end;

  // Add privileges
  if Result.IsSuccess and (Length(Add) > 0) then
    Result := LsaxAddPrivilegesAccount(hxAccount.Handle, Add);

  // Remove privileges
  if Result.IsSuccess and (RemoveAll or (Length(Remove) > 0)) then
    Result := LsaxRemovePrivilegesAccount(hxAccount.Handle, RemoveAll, Remove);
end;

function LsaxQueryRightsAccount;
begin
  Result.Location := 'LsaGetSystemAccessAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_VIEW);

  Result.Status := LsaGetSystemAccessAccount(hAccount, SystemAccess);
end;

function LsaxQueryRightsAccountBySid;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid, ACCOUNT_VIEW);

  if Result.IsSuccess then
    Result := LsaxQueryRightsAccount(hxAccount.Handle, SystemAccess);
end;

function LsaxSetRightsAccount;
begin
  Result.Location := 'LsaSetSystemAccessAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_SYSTEM_ACCESS);

  Result.Status := LsaSetSystemAccessAccount(hAccount, SystemAccess);
end;

function LsaxSetRightsAccountBySid;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid,
    ACCOUNT_ADJUST_SYSTEM_ACCESS);

  // Add the account to the LSA database if necessary
  if Result.Matches(STATUS_OBJECT_NAME_NOT_FOUND, 'LsaOpenAccount') then
    Result := LsaxCreateAccount(hxAccount, AccountSid, nil,
      ACCOUNT_ADJUST_SYSTEM_ACCESS);

  if Result.IsSuccess then
    Result := LsaxSetRightsAccount(hxAccount.Handle, SystemAccess);
end;

{ Privileges }

function LsaxEnumeratePrivileges;
var
  EnumContext: TLsaEnumerationHandle;
  Count, i: Integer;
  Buffer: PPolicyPrivilegeDefinitionArray;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_VIEW_LOCAL_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  EnumContext := 0;
  Result.Location := 'LsaEnumeratePrivileges';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

  Result.Status := LsaEnumeratePrivileges(hxPolicy.Handle, EnumContext, Buffer,
    MAX_PREFERRED_LENGTH, Count);

  if not Result.IsSuccess then
    Exit;

  SetLength(Privileges, Count);

  for i := 0 to High(Privileges) do
  begin
    Privileges[i].Name := Buffer{$R-}[i]{$R+}.Name.ToString;
    Privileges[i].LocalValue := Buffer{$R-}[i]{$R+}.LocalValue;
  end;

  LsaFreeMemory(Buffer);
end;

function LsaxQueryPrivilege;
var
  Buffer: PLsaUnicodeString;
  LangId: SmallInt;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  // Get name based on LUID
  Result.Location := 'LsaLookupPrivilegeName';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_LOOKUP_NAMES);
  Result.Status := LsaLookupPrivilegeName(hxPolicy.Handle, Luid, Buffer);

  if Result.IsSuccess then
  begin
    Name := Buffer.ToString;
    LsaFreeMemory(Buffer);

    // Get description based on name
    Result.Location := 'LsaLookupPrivilegeDisplayName';
    Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_LOOKUP_NAMES);

    Result.Status := LsaLookupPrivilegeDisplayName(hxPolicy.Handle,
      TLsaUnicodeString.From(Name), Buffer, LangId);

    if Result.IsSuccess then
    begin
      DisplayName := Buffer.ToString;
      LsaFreeMemory(Buffer);
    end;
  end;
end;

function LsaxQueryIntegrityPrivilege;
begin
  // Some privileges require a specific integrity level to be enabled.
  // The ones that require more than Medium also trigger UAC to split logon
  // sessions. The following data is gathered by experimenting and should be
  // maintained in sync with Windows behavior when new privileges are
  // introduced.

  case TSeWellKnownPrivilege(Luid) of
    // Ten of them require High
    SE_CREATE_TOKEN_PRIVILEGE,
    SE_TCB_PRIVILEGE,
    SE_TAKE_OWNERSHIP_PRIVILEGE,
    SE_LOAD_DRIVER_PRIVILEGE,
    SE_BACKUP_PRIVILEGE,
    SE_RESTORE_PRIVILEGE,
    SE_DEBUG_PRIVILEGE,
    SE_IMPERSONATE_PRIVILEGE,
    SE_RELABEL_PRIVILEGE,
    SE_DELEGATE_SESSION_USER_IMPERSONATE_PRIVILEGE:
      Result := SECURITY_MANDATORY_HIGH_RID;

    // Three of them does not require anything
    SE_CHANGE_NOTIFY_PRIVILEGE,
    SE_UNDOCK_PRIVILEGE,
    SE_INCREASE_WORKING_SET_PRIVILEGE:
      Result := SECURITY_MANDATORY_UNTRUSTED_RID;

  else
    // All other require Medium
    Result := SECURITY_MANDATORY_MEDIUM_RID;
  end;
end;

{ Logon process }

type
  TLsaAutoConnection = class(TCustomAutoHandle, ILsaHandle)
    procedure Release; override;
  end;

procedure TLsaAutoConnection.Release;
begin
  LsaDeregisterLogonProcess(FHandle);
  inherited;
end;

function LsaxConnectUntrusted;
var
  hLsaConnection: TLsaHandle;
begin
  Result.Location := 'LsaConnectUntrusted';
  Result.Status := LsaConnectUntrusted(hLsaConnection);

  if Result.IsSuccess then
    hxLsaConnection := TLsaAutoConnection.Capture(hLsaConnection);
end;

function LsaxRegisterLogonProcess;
var
  hLsaConnection: TLsaHandle;
  Reserved: Cardinal;
begin
  Result.Location := 'LsaRegisterLogonProcess';
  Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  Result.Status := LsaRegisterLogonProcess(TLsaAnsiString.From(Name),
    hLsaConnection, Reserved);

  if Result.IsSuccess then
    hxLsaConnection := TLsaAutoConnection.Capture(hLsaConnection);
end;

function LsaxLookupAuthPackage;
begin
  if not Assigned(hxLsaConnection) then
  begin
    Result := LsaxConnectUntrusted(hxLsaConnection);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'LsaLookupAuthenticationPackage';
  Result.Status := LsaLookupAuthenticationPackage(hxLsaConnection.Handle,
    TLsaAnsiString.From(NEGOSSP_NAME_A), PackageId);
end;

function LsaxQuerySecurityObject;
var
  Buffer: PSecurityDescriptor;
begin
  Result.Location := 'LsaQuerySecurityObject';
  Result.LastCall.Expects(SecurityReadAccess(Info));
  Result.Status := LsaQuerySecurityObject(LsaHandle, Info, Buffer);

  if Result.IsSuccess then
    IMemory(SD) := TLsaAutoMemory.Capture(Buffer, 0);
end;

function LsaxSetSecurityObject;
begin
  Result.Location := 'LsaSetSecurityObject';
  Result.LastCall.Expects(SecurityWriteAccess(Info));
  Result.Status := LsaSetSecurityObject(LsaHandle, Info, SD);
end;

end.
