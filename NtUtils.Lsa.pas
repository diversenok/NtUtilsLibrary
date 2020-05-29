unit NtUtils.Lsa;

interface

uses
  Winapi.WinNt, Winapi.ntlsa, Ntapi.ntseapi, NtUtils, NtUtils.Security.Sid,
  DelphiUtils.AutoObject;

type
  TLsaHandle = Winapi.ntlsa.TLsaHandle;
  ILsaHandle = DelphiUtils.AutoObject.IHandle;

  TPrivilegeDefinition = record
    Name: String;
    LocalValue: TLuid;
  end;

  TLogonRightRec = record
    Value: Cardinal;
    IsAllowedType: Boolean;
    Name, Description: String;
  end;

{ --------------------------------- Policy ---------------------------------- }

// Open LSA for desired access
function LsaxOpenPolicy(out hxPolicy: ILsaHandle;
  DesiredAccess: TAccessMask; SystemName: String = ''): TNtxStatus;

// Make sure the policy handle is provided
function LsaxpEnsureConnected(var hxPolicy: ILsaHandle;
  DesiredAccess: TAccessMask): TNtxStatus;

// Query policy information
function LsaxQueryPolicy(hPolicy: TLsaHandle; InfoClass:
  TPolicyInformationClass; out xMemory: IMemory): TNtxStatus;

// Set policy information
function LsaxSetPolicy(hPolicy: TLsaHandle; InfoClass: TPolicyInformationClass;
  Data: Pointer): TNtxStatus;

{ --------------------------------- Accounts -------------------------------- }

// Open an account from LSA database
function LsaxOpenAccount(out hxAccount: ILsaHandle; AccountSid: PSid;
  DesiredAccess: TAccessMask; hxPolicy: ILsaHandle = nil): TNtxStatus;

// Add an account to LSA database
function LsaxCreateAccount(out hxAccount: ILsaHandle; AccountSid: PSid;
  DesiredAccess: TAccessMask; hxPolicy: ILsaHandle = nil): TNtxStatus;

// Delete account from LSA database
function LsaxDeleteAccount(hAccount: TLsaHandle): TNtxStatus;

// Enumerate account in the LSA database
function LsaxEnumerateAccounts(hPolicy: TLsaHandle; out Accounts: TArray<ISid>):
  TNtxStatus;

// Enumerate privileges assigned to an account
function LsaxEnumeratePrivilegesAccount(hAccount: TLsaHandle;
  out Privileges: TArray<TPrivilege>): TNtxStatus;

function LsaxEnumeratePrivilegesAccountBySid(AccountSid: PSid;
  out Privileges: TArray<TPrivilege>): TNtxStatus;

// Assign privileges to an account
function LsaxAddPrivilegesAccount(hAccount: TLsaHandle;
  Privileges: TArray<TPrivilege>): TNtxStatus;

// Revoke privileges to an account
function LsaxRemovePrivilegesAccount(hAccount: TLsaHandle; RemoveAll: Boolean;
  Privileges: TArray<TPrivilege>): TNtxStatus;

// Assign & revoke privileges to account in one operation
function LsaxManagePrivilegesAccount(AccountSid: PSid; RemoveAll: Boolean;
  Add, Remove: TArray<TPrivilege>): TNtxStatus;

// Query logon rights of an account
function LsaxQueryRightsAccount(hAccount: TLsaHandle;
  out SystemAccess: Cardinal): TNtxStatus;

function LsaxQueryRightsAccountBySid(AccountSid: PSid;
  out SystemAccess: Cardinal): TNtxStatus;

// Set logon rights of an account
function LsaxSetRightsAccount(hAccount: TLsaHandle; SystemAccess: Cardinal):
  TNtxStatus;

function LsaxSetRightsAccountBySid(AccountSid: PSid; SystemAccess: Cardinal):
  TNtxStatus;

{ -------------------------------- Privileges ------------------------------- }

// Enumerate all privileges on the system
function LsaxEnumeratePrivileges(hPolicy: TLsaHandle;
  out Privileges: TArray<TPrivilegeDefinition>): TNtxStatus;

function LsaxEnumeratePrivilegesLocal(
  out Privileges: TArray<TPrivilegeDefinition>): TNtxStatus;

// Convert a numerical privilege value to internal name
function LsaxQueryNamePrivilege(hPolicy: TLsaHandle; Luid: TLuid;
  out Name: String): TNtxStatus;

// Convert an privilege's internal name to a description
function LsaxQueryDescriptionPrivilege(hPolicy: TLsaHandle; const Name: String;
  out DisplayName: String): TNtxStatus;

// Lookup multiple privilege names and descriptions at once
function LsaxLookupMultiplePrivileges(Luids: TArray<TLuid>;
  out Names, Descriptions: TArray<String>): TNtxStatus;

// Get the minimal integrity level required to use a specific privilege
function LsaxQueryIntegrityPrivilege(Luid: TLuid): Cardinal;

{ ------------------------------- Logon Rights ------------------------------ }

// Enumerate known logon rights
function LsaxEnumerateLogonRights: TArray<TLogonRightRec>;

{ ------------------------------- Logon Process ----------------------------- }

// Establish a connection to LSA without verification
function LsaxConnectUntrusted(out hxLsaConnection: ILsaHandle): TNtxStatus;

// Establish a connection to LSA with verification
function LsaxRegisterLogonProcess(out hxLsaConnection: ILsaHandle;
  Name: AnsiString): TNtxStatus;

// Find an authentication package by name
function LsaxLookupAuthPackage(out PackageId: Cardinal; PackageName: AnsiString;
  hxLsaConnection: ILsaHandle = nil): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Winapi.NtSecApi, NtUtils.Tokens.Misc,
  NtUtils.Access.Expected;

type
  TLsaAutoHandle = class(TCustomAutoHandle, ILsaHandle)
    destructor Destroy; override;
  end;

  TLsaAutoMemory = class(TCustomAutoMemory, IMemory)
    destructor Destroy; override;
  end;

{ Common & Policy }

destructor TLsaAutoHandle.Destroy;
begin
  if FAutoRelease then
    LsaClose(FHandle);
  inherited;
end;

destructor TLsaAutoMemory.Destroy;
begin
  if FAutoRelease then
    LsaFreeMemory(FAddress);
  inherited;
end;

function LsaxOpenPolicy(out hxPolicy: ILsaHandle;
  DesiredAccess: TAccessMask; SystemName: String = ''): TNtxStatus;
var
  ObjAttr: TObjectAttributes;
  hPolicy: TLsaHandle;
begin
  InitializeObjectAttributes(ObjAttr);

  Result.Location := 'LsaOpenPolicy';
  Result.LastCall.AttachAccess<TLsaPolicyAccessMask>(DesiredAccess);

  Result.Status := LsaOpenPolicy(TLsaUnicodeString.From(SystemName).RefOrNull,
    ObjAttr, DesiredAccess, hPolicy);

  if Result.IsSuccess then
    hxPolicy := TLsaAutoHandle.Capture(hPolicy);
end;

function LsaxpEnsureConnected(var hxPolicy: ILsaHandle;
  DesiredAccess: TAccessMask): TNtxStatus;
begin
  if not Assigned(hxPolicy) then
    Result := LsaxOpenPolicy(hxPolicy, DesiredAccess)
  else
    Result.Status := STATUS_SUCCESS
end;

function LsaxQueryPolicy(hPolicy: TLsaHandle; InfoClass:
  TPolicyInformationClass; out xMemory: IMemory): TNtxStatus;
var
  Buffer: Pointer;
begin
  Result.Location := 'LsaQueryInformationPolicy';
  Result.LastCall.AttachInfoClass(InfoClass);
  RtlxComputePolicyQueryAccess(Result.LastCall, InfoClass);

  Result.Status := LsaQueryInformationPolicy(hPolicy, InfoClass, Buffer);

  if Result.IsSuccess then
    xMemory := TLsaAutoMemory.Capture(Buffer, 0);
end;

function LsaxSetPolicy(hPolicy: TLsaHandle; InfoClass: TPolicyInformationClass;
  Data: Pointer): TNtxStatus;
begin
  Result.Location := 'LsaSetInformationPolicy';
  Result.LastCall.AttachInfoClass(InfoClass);
  RtlxComputePolicySetAccess(Result.LastCall, InfoClass);

  Result.Status := LsaSetInformationPolicy(hPolicy, InfoClass, Data);
end;

{ Accounts }

function LsaxOpenAccount(out hxAccount: ILsaHandle; AccountSid: PSid;
  DesiredAccess: TAccessMask; hxPolicy: ILsaHandle = nil): TNtxStatus;
var
  hAccount: TLsaHandle;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_VIEW_LOCAL_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LsaOpenAccount';
  Result.LastCall.AttachInfoClass<TLsaAccountAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

  Result.Status := LsaOpenAccount(hxPolicy.Handle, AccountSid, DesiredAccess,
    hAccount);

  if Result.IsSuccess then
    hxAccount := TLsaAutoHandle.Capture(hAccount);
end;

function LsaxCreateAccount(out hxAccount: ILsaHandle; AccountSid: PSid;
  DesiredAccess: TAccessMask; hxPolicy: ILsaHandle = nil): TNtxStatus;
var
  hAccount: TLsaHandle;
begin
  Result := LsaxpEnsureConnected(hxPolicy, POLICY_CREATE_ACCOUNT);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LsaCreateAccount';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_CREATE_ACCOUNT);

  Result.Status := LsaCreateAccount(hxPolicy.Handle, AccountSid, DesiredAccess,
    hAccount);

  if Result.IsSuccess then
    hxAccount := TLsaAutoHandle.Capture(hAccount);
end;

function LsaxDeleteAccount(hAccount: TLsaHandle): TNtxStatus;
begin
  Result.Location := 'LsaDelete';
  Result.LastCall.Expects<TLsaAccountAccessMask>(_DELETE);
  Result.Status := LsaDelete(hAccount);
end;

function LsaxEnumerateAccounts(hPolicy: TLsaHandle; out Accounts: TArray<ISid>):
  TNtxStatus;
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
    Accounts[i] := TSid.CreateCopy(Buffer{$R-}[i]{$R+});

  LsaFreeMemory(Buffer);
end;

function LsaxEnumeratePrivilegesAccount(hAccount: TLsaHandle;
  out Privileges: TArray<TPrivilege>): TNtxStatus;
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

function LsaxEnumeratePrivilegesAccountBySid(AccountSid: PSid;
  out Privileges: TArray<TPrivilege>): TNtxStatus;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid, ACCOUNT_VIEW);

  if Result.IsSuccess then
    Result := LsaxEnumeratePrivilegesAccount(hxAccount.Handle, Privileges);
end;

function LsaxAddPrivilegesAccount(hAccount: TLsaHandle;
  Privileges: TArray<TPrivilege>): TNtxStatus;
begin
  Result.Location := 'LsaAddPrivilegesToAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_PRIVILEGES);

  Result.Status := LsaAddPrivilegesToAccount(hAccount,
    NtxpAllocPrivilegeSet(Privileges).Data);
end;

function LsaxRemovePrivilegesAccount(hAccount: TLsaHandle; RemoveAll: Boolean;
  Privileges: TArray<TPrivilege>): TNtxStatus;
begin
  Result.Location := 'LsaRemovePrivilegesFromAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_PRIVILEGES);

  Result.Status := LsaRemovePrivilegesFromAccount(hAccount, RemoveAll,
    NtxpAllocPrivilegeSet(Privileges).Data);
end;

function LsaxManagePrivilegesAccount(AccountSid: PSid; RemoveAll: Boolean;
  Add, Remove: TArray<TPrivilege>): TNtxStatus;
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
    Result := LsaxCreateAccount(hxAccount, AccountSid,
      ACCOUNT_ADJUST_PRIVILEGES);
  end;

  // Add privileges
  if Result.IsSuccess and (Length(Add) > 0) then
    Result := LsaxAddPrivilegesAccount(hxAccount.Handle, Add);

  // Remove privileges
  if Result.IsSuccess and (RemoveAll or (Length(Remove) > 0)) then
    Result := LsaxRemovePrivilegesAccount(hxAccount.Handle, RemoveAll, Remove);
end;

function LsaxQueryRightsAccount(hAccount: TLsaHandle;
  out SystemAccess: Cardinal): TNtxStatus;
begin
  Result.Location := 'LsaGetSystemAccessAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_VIEW);

  Result.Status := LsaGetSystemAccessAccount(hAccount, SystemAccess);
end;

function LsaxQueryRightsAccountBySid(AccountSid: PSid;
  out SystemAccess: Cardinal): TNtxStatus;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid, ACCOUNT_VIEW);

  if Result.IsSuccess then
    Result := LsaxQueryRightsAccount(hxAccount.Handle, SystemAccess);
end;

function LsaxSetRightsAccount(hAccount: TLsaHandle; SystemAccess: Cardinal)
  : TNtxStatus;
begin
  Result.Location := 'LsaSetSystemAccessAccount';
  Result.LastCall.Expects<TLsaAccountAccessMask>(ACCOUNT_ADJUST_SYSTEM_ACCESS);

  Result.Status := LsaSetSystemAccessAccount(hAccount, SystemAccess);
end;

function LsaxSetRightsAccountBySid(AccountSid: PSid; SystemAccess: Cardinal):
  TNtxStatus;
var
  hxAccount: ILsaHandle;
begin
  Result := LsaxOpenAccount(hxAccount, AccountSid,
    ACCOUNT_ADJUST_SYSTEM_ACCESS);

  // Add the account to the LSA database if necessary
  if Result.Matches(STATUS_OBJECT_NAME_NOT_FOUND, 'LsaOpenAccount') then
    Result := LsaxCreateAccount(hxAccount, AccountSid,
      ACCOUNT_ADJUST_SYSTEM_ACCESS);

  if Result.IsSuccess then
    Result := LsaxSetRightsAccount(hxAccount.Handle, SystemAccess);
end;

{ Privileges }

function LsaxEnumeratePrivileges(hPolicy: TLsaHandle;
  out Privileges: TArray<TPrivilegeDefinition>): TNtxStatus;
var
  EnumContext: TLsaEnumerationHandle;
  Count, i: Integer;
  Buffer: PPolicyPrivilegeDefinitionArray;
begin
  EnumContext := 0;
  Result.Location := 'LsaEnumeratePrivileges';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_VIEW_LOCAL_INFORMATION);

  Result.Status := LsaEnumeratePrivileges(hPolicy, EnumContext, Buffer,
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

function LsaxEnumeratePrivilegesLocal(
  out Privileges: TArray<TPrivilegeDefinition>): TNtxStatus;
var
  hxPolicy: ILsaHandle;
begin
  Result := LsaxOpenPolicy(hxPolicy, POLICY_VIEW_LOCAL_INFORMATION);

  if Result.IsSuccess then
    Result := LsaxEnumeratePrivileges(hxPolicy.Handle, Privileges);
end;

function LsaxQueryNamePrivilege(hPolicy: TLsaHandle; Luid: TLuid;
  out Name: String): TNtxStatus;
var
  Buffer: PLsaUnicodeString;
begin
  Result.Location := 'LsaLookupPrivilegeName';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_LOOKUP_NAMES);
  Result.Status := LsaLookupPrivilegeName(hPolicy, Luid, Buffer);

  if Result.IsSuccess then
  begin
    Name := Buffer.ToString;
    LsaFreeMemory(Buffer);
  end;
end;

function LsaxQueryDescriptionPrivilege(hPolicy: TLsaHandle; const Name: String;
  out DisplayName: String): TNtxStatus;
var
  BufferDisplayName: PLsaUnicodeString;
  LangId: SmallInt;
begin
  Result.Location := 'LsaLookupPrivilegeDisplayName';
  Result.LastCall.Expects<TLsaPolicyAccessMask>(POLICY_LOOKUP_NAMES);

  Result.Status := LsaLookupPrivilegeDisplayName(hPolicy,
    TLsaUnicodeString.From(Name), BufferDisplayName, LangId);

  if Result.IsSuccess then
  begin
    DisplayName := BufferDisplayName.ToString;
    LsaFreeMemory(BufferDisplayName);
  end;
end;

function LsaxLookupMultiplePrivileges(Luids: TArray<TLuid>;
  out Names, Descriptions: TArray<String>): TNtxStatus;
var
  hxPolicy: ILsaHandle;
  i: Integer;
begin
  Result := LsaxOpenPolicy(hxPolicy, POLICY_LOOKUP_NAMES);

  if not Result.IsSuccess then
    Exit;

  SetLength(Names, Length(Luids));
  SetLength(Descriptions, Length(Luids));

  for i := 0 to High(Luids) do
    if not LsaxQueryNamePrivilege(hxPolicy.Handle, Luids[i], Names[i]).IsSuccess
      or not LsaxQueryDescriptionPrivilege(hxPolicy.Handle, Names[i],
        Descriptions[i]).IsSuccess then
    begin
      Result.Location := 'LsaxQueryNamesPrivileges';
      Result.Status := STATUS_SOME_NOT_MAPPED;
    end;
end;

function LsaxQueryIntegrityPrivilege(Luid: TLuid): Cardinal;
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

{ Logon rights }

function LsaxEnumerateLogonRights: TArray<TLogonRightRec>;
begin
  // If someone knows a system function to enumerate logon rights on the system
  // you are welcome to use it here.

  SetLength(Result, 10);

  Result[0].Value := SECURITY_ACCESS_INTERACTIVE_LOGON;
  Result[0].IsAllowedType := True;
  Result[0].Name := SE_INTERACTIVE_LOGON_NAME;
  Result[0].Description := 'Allow interactive logon';

  Result[1].Value := SECURITY_ACCESS_NETWORK_LOGON;
  Result[1].IsAllowedType := True;
  Result[1].Name := SE_NETWORK_LOGON_NAME;
  Result[1].Description := 'Allow network logon';

  Result[2].Value := SECURITY_ACCESS_BATCH_LOGON;
  Result[2].IsAllowedType := True;
  Result[2].Name := SE_BATCH_LOGON_NAME;
  Result[2].Description := 'Allow batch job logon';

  Result[3].Value := SECURITY_ACCESS_SERVICE_LOGON;
  Result[3].IsAllowedType := True;
  Result[3].Name := SE_SERVICE_LOGON_NAME;
  Result[3].Description := 'Allow service logon';

  Result[4].Value := SECURITY_ACCESS_REMOTE_INTERACTIVE_LOGON;
  Result[4].IsAllowedType := True;
  Result[4].Name := SE_REMOTE_INTERACTIVE_LOGON_NAME;
  Result[4].Description := 'Allow Remote Desktop Services logon';

  Result[5].Value := SECURITY_ACCESS_DENY_INTERACTIVE_LOGON;
  Result[5].IsAllowedType := False;
  Result[5].Name := SE_DENY_INTERACTIVE_LOGON_NAME;
  Result[5].Description := 'Deny interactive logon';

  Result[6].Value := SECURITY_ACCESS_DENY_NETWORK_LOGON;
  Result[6].IsAllowedType := False;
  Result[6].Name := SE_DENY_NETWORK_LOGON_NAME;
  Result[6].Description := 'Deny network logon';

  Result[7].Value := SECURITY_ACCESS_DENY_BATCH_LOGON;
  Result[7].IsAllowedType := False;
  Result[7].Name := SE_DENY_BATCH_LOGON_NAME;
  Result[7].Description := 'Deny batch job logon';

  Result[8].Value := SECURITY_ACCESS_DENY_SERVICE_LOGON;
  Result[8].IsAllowedType := False;
  Result[8].Name := SE_DENY_SERVICE_LOGON_NAME;
  Result[8].Description := 'Deny service logon';

  Result[9].Value := SECURITY_ACCESS_DENY_REMOTE_INTERACTIVE_LOGON;
  Result[9].IsAllowedType := False;
  Result[9].Name := SE_DENY_REMOTE_INTERACTIVE_LOGON_NAME;
  Result[9].Description := 'Deny Remote Desktop Services logon';
end;

{ Logon process }

type
  TLsaAutoConnection = class(TCustomAutoHandle, ILsaHandle)
    destructor Destroy; override;
  end;

destructor TLsaAutoConnection.Destroy;
begin
  if FAutoRelease then
    LsaDeregisterLogonProcess(FHandle);
  inherited;
end;

function LsaxConnectUntrusted(out hxLsaConnection: ILsaHandle): TNtxStatus;
var
  hLsaConnection: TLsaHandle;
begin
  Result.Location := 'LsaConnectUntrusted';
  Result.Status := LsaConnectUntrusted(hLsaConnection);

  if Result.IsSuccess then
    hxLsaConnection := TLsaAutoConnection.Capture(hLsaConnection);
end;

function LsaxRegisterLogonProcess(out hxLsaConnection: ILsaHandle;
  Name: AnsiString): TNtxStatus;
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

function LsaxLookupAuthPackage(out PackageId: Cardinal; PackageName: AnsiString;
  hxLsaConnection: ILsaHandle): TNtxStatus;
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

end.
