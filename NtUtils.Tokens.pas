unit NtUtils.Tokens;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, NtUtils.Exceptions, NtUtils.Objects,
  NtUtils.Security.Sid, NtUtils.Security.Acl;

{ ------------------------------ Creation ---------------------------------- }

const
  // Now supported everywhere on all OS versions
  NtCurrentProcessToken: THandle = THandle(-4);
  NtCurrentThreadToken: THandle = THandle(-5);
  NtCurrentEffectiveToken: THandle = THandle(-6);

// Open a token of a process
function NtxOpenProcessToken(out hxToken: IHandle; hProcess: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

function NtxOpenProcessTokenById(out hxToken: IHandle; PID: TProcessId;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Open a token of a thread
function NtxOpenThreadToken(out hxToken: IHandle; hThread: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0;
  InverseOpenLogic: Boolean = False): TNtxStatus;

function NtxOpenThreadTokenById(out hxToken: IHandle; TID: TThreadId;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0;
  InverseOpenLogic: Boolean = False): TNtxStatus;

// Open an effective token of a thread
function NtxOpenEffectiveTokenById(out hxToken: IHandle; const ClientId:
  TClientId; DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0;
  InverseOpenLogic: Boolean = False): TNtxStatus;

// Convert a pseudo-handle to an actual token handle
function NtxOpenPseudoToken(out hxToken: IHandle; Handle: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0;
  InverseOpenLogic: Boolean = False): TNtxStatus;

// Make sure to convert a pseudo-handle to an actual token handle if necessary
// NOTE: Do not save the handle returned from this function
function NtxExpandPseudoToken(out hxToken: IHandle; hToken: THandle;
  DesiredAccess: TAccessMask): TNtxStatus;

// Copy an effective security context of a thread via direct impersonation
function NtxDuplicateEffectiveToken(out hxToken: IHandle; hThread: THandle;
  ImpersonationLevel: TSecurityImpersonationLevel; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal = 0; EffectiveOnly: Boolean = False): TNtxStatus;

function NtxDuplicateEffectiveTokenById(out hxToken: IHandle; TID: TThreadId;
  ImpersonationLevel: TSecurityImpersonationLevel; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal = 0; EffectiveOnly: Boolean = False): TNtxStatus;

// Duplicate existing token
function NtxDuplicateToken(out hxToken: IHandle; hExistingToken: THandle;
  DesiredAccess: TAccessMask; TokenType: TTokenType; ImpersonationLevel:
  TSecurityImpersonationLevel = SecurityImpersonation;
  HandleAttributes: Cardinal = 0; EffectiveOnly: Boolean = False): TNtxStatus;

// Open anonymous token
function NtxOpenAnonymousToken(out hxToken: IHandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal = 0): TNtxStatus;

// Filter a token
function NtxFilterToken(out hxNewToken: IHandle; hToken: THandle; Flags:
  Cardinal; SidsToDisable: TArray<ISid> = nil; PrivilegesToDelete:
  TArray<TLuid> = nil; SidsToRestrict: TArray<ISid> = nil): TNtxStatus;

// Create a new token from scratch. Requires SeCreateTokenPrivilege.
function NtxCreateToken(out hxToken: IHandle; TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel; const TokenSource:
  TTokenSource; AuthenticationId: TLuid; User: TGroup; PrimaryGroup: ISid;
  Groups: TArray<TGroup> = nil; Privileges: TArray<TPrivilege> = nil;
  Owner: ISid = nil; DefaultDacl: IAcl = nil; ExpirationTime: TLargeInteger =
  INFINITE_FUTURE; HandleAttributes: Cardinal = 0): TNtxStatus;

// Create an AppContainer token, Win 8+
function NtxCreateLowBoxToken(out hxToken: IHandle; hExistingToken: THandle;
  Package: PSid; Capabilities: TArray<TGroup> = nil; Handles: TArray<THandle> =
  nil; HandleAttributes: Cardinal = 0): TNtxStatus;

{ --------------------------- Other operations ---------------------------- }

// Adjust privileges
function NtxAdjustPrivilege(hToken: THandle; Privilege: TSeWellKnownPrivilege;
  NewAttribute: Cardinal; IgnoreMissing: Boolean = False): TNtxStatus;

function NtxAdjustPrivileges(hToken: THandle; Privileges: TArray<TLuid>;
  NewAttribute: Cardinal; IgnoreMissing: Boolean): TNtxStatus;

// Adjust groups
function NtxAdjustGroups(hToken: THandle; Sids: TArray<ISid>;
  NewAttribute: Cardinal; ResetToDefault: Boolean): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpsapi, Winapi.WinError, NtUtils.Tokens.Misc,
  NtUtils.Processes, NtUtils.Tokens.Impersonate, NtUtils.Threads,
  NtUtils.Ldr, Ntapi.ntpebteb, DelphiUtils.AutoObject;

{ Creation }

function NtxOpenProcessToken(out hxToken: IHandle; hProcess: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal): TNtxStatus;
var
  hToken: THandle;
begin
  Result.Location := 'NtOpenProcessTokenEx';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @TokenAccessType;
  Result.LastCall.Expects(PROCESS_QUERY_LIMITED_INFORMATION, @ProcessAccessType);

  Result.Status := NtOpenProcessTokenEx(hProcess, DesiredAccess,
    HandleAttributes, hToken);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxOpenProcessTokenById(out hxToken: IHandle; PID: TProcessId;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal): TNtxStatus;
var
  hxProcess: IHandle;
begin
  Result := NtxOpenProcess(hxProcess, PID, PROCESS_QUERY_LIMITED_INFORMATION);

  if Result.IsSuccess then
    Result := NtxOpenProcessToken(hxToken, hxProcess.Handle, DesiredAccess,
      HandleAttributes);
end;

function NtxOpenThreadToken(out hxToken: IHandle; hThread: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal;
  InverseOpenLogic: Boolean): TNtxStatus;
var
  hToken: THandle;
begin
  Result.Location := 'NtOpenThreadTokenEx';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @TokenAccessType;
  Result.LastCall.Expects(THREAD_QUERY_LIMITED_INFORMATION, @ThreadAccessType);

  // By default, when opening other thread's token use our effective (thread)
  // security context. When reading a token from the current thread use the
  // process' security context.

  Result.Status := NtOpenThreadTokenEx(hThread, DesiredAccess,
    (hThread = NtCurrentThread) xor InverseOpenLogic, HandleAttributes, hToken);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxOpenThreadTokenById(out hxToken: IHandle; TID: TThreadId;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal; InverseOpenLogic:
  Boolean): TNtxStatus;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_QUERY_LIMITED_INFORMATION);

  if Result.IsSuccess then
    Result := NtxOpenThreadToken(hxToken, hxThread.Handle, DesiredAccess,
      HandleAttributes, InverseOpenLogic);
end;

function NtxOpenEffectiveTokenById(out hxToken: IHandle; const ClientId:
  TClientId; DesiredAccess: TAccessMask; HandleAttributes: Cardinal;
  InverseOpenLogic: Boolean): TNtxStatus;
begin
  // When querying effective token we read thread token first, and then fall
  // back to process token if it's not available.

  Result := NtxOpenThreadTokenById(hxToken, ClientId.UniqueThread,
    DesiredAccess, HandleAttributes, InverseOpenLogic);

  if Result.Status = STATUS_NO_TOKEN then
      Result := NtxOpenProcessTokenById(hxToken, ClientId.UniqueProcess,
        DesiredAccess, HandleAttributes);
end;

function NtxOpenPseudoToken(out hxToken: IHandle; Handle: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal;
  InverseOpenLogic: Boolean): TNtxStatus;
begin
  if Handle = NtCurrentProcessToken then
    Result := NtxOpenProcessToken(hxToken, NtCurrentProcess, DesiredAccess,
      HandleAttributes)

  else if Handle = NtCurrentThreadToken then
    Result := NtxOpenThreadToken(hxToken, NtCurrentThread, DesiredAccess,
      HandleAttributes, InverseOpenLogic)

  else if Handle = NtCurrentEffectiveToken then
    Result := NtxOpenEffectiveTokenById(hxToken, NtCurrentTeb.ClientId,
      DesiredAccess, HandleAttributes, InverseOpenLogic)

  else
  begin
    Result.Location := 'NtxOpenPseudoToken';
    Result.Status := STATUS_INVALID_HANDLE;
  end;
end;

function NtxExpandPseudoToken(out hxToken: IHandle; hToken: THandle;
  DesiredAccess: TAccessMask): TNtxStatus;
begin
  if hToken > MAX_HANDLE then
    Result := NtxOpenPseudoToken(hxToken, hToken, DesiredAccess)
  else
  begin
    // Not a pseudo-handle. Capture, but do not close automatically.
    // Do not save this handle outside of the function since we
    // don't maintain its lifetime.
    Result.Status := STATUS_SUCCESS;
    hxToken := TAutoHandle.Capture(hToken);
    hxToken.AutoRelease := False;
  end;
end;

function NtxDuplicateEffectiveToken(out hxToken: IHandle; hThread: THandle;
  ImpersonationLevel: TSecurityImpersonationLevel; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal; EffectiveOnly: Boolean): TNtxStatus;
var
  hxOldToken: IHandle;
  QoS: TSecurityQualityOfService;
begin
  // Backup our impersonation token
  hxOldToken := NtxBackupImpersonation(NtCurrentThread);

  InitializaQoS(QoS, ImpersonationLevel, EffectiveOnly);

  // Direct impersonation makes the server thread to impersonate the effective
  // security context of the client thread. We use our thead as a server and the
  // target thread as a client, and then read the token from our thread.

  Result.Location := 'NtImpersonateThread';
  Result.LastCall.Expects(THREAD_IMPERSONATE, @ThreadAccessType);          // Server
  Result.LastCall.Expects(THREAD_DIRECT_IMPERSONATION, @ThreadAccessType); // Client
  // No access checks are performed on the client's token, we obtain a copy

  Result.Status := NtImpersonateThread(NtCurrentThread, hThread, QoS);

  if not Result.IsSuccess then
    Exit;

  // Read it back from our thread
  Result := NtxOpenThreadToken(hxToken, NtCurrentThread, DesiredAccess,
    HandleAttributes);

  // Restore our previous impersonation
  NtxRestoreImpersonation(NtCurrentThread, hxOldToken);
end;

function NtxDuplicateEffectiveTokenById(out hxToken: IHandle; TID: TThreadId;
  ImpersonationLevel: TSecurityImpersonationLevel; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal; EffectiveOnly: Boolean): TNtxStatus;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_DIRECT_IMPERSONATION);

  if Result.IsSuccess then
    Result := NtxDuplicateEffectiveToken(hxToken, hxThread.Handle,
      ImpersonationLevel, DesiredAccess, HandleAttributes, EffectiveOnly);
end;

function NtxDuplicateToken(out hxToken: IHandle; hExistingToken: THandle;
  DesiredAccess: TAccessMask; TokenType: TTokenType; ImpersonationLevel:
  TSecurityImpersonationLevel; HandleAttributes: Cardinal;
  EffectiveOnly: Boolean): TNtxStatus;
var
  hxExistingToken: IHandle;
  hToken: THandle;
  ObjAttr: TObjectAttributes;
  QoS: TSecurityQualityOfService;
begin
  // Manage support for pseudo-handles
  Result := NtxExpandPseudoToken(hxExistingToken, hExistingToken,
    TOKEN_DUPLICATE);

  if not Result.IsSuccess then
    Exit;

  InitializaQoS(QoS, ImpersonationLevel, EffectiveOnly);
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes, 0, @QoS);

  Result.Location := 'NtDuplicateToken';
  Result.LastCall.Expects(TOKEN_DUPLICATE, @TokenAccessType);

  Result.Status := NtDuplicateToken(hxExistingToken.Handle, DesiredAccess,
    @ObjAttr, EffectiveOnly, TokenType, hToken);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxOpenAnonymousToken(out hxToken: IHandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal): TNtxStatus;
var
  hxOldToken: IHandle;
begin
  // Backup our impersonation context
  hxOldToken := NtxBackupImpersonation(NtCurrentThread);

  // Set our thread to impersonate anonymous token
  Result.Location := 'NtImpersonateAnonymousToken';
  Result.LastCall.Expects(THREAD_IMPERSONATE, @ThreadAccessType);

  Result.Status := NtImpersonateAnonymousToken(NtCurrentThread);

  // Read the token from the thread
  if Result.IsSuccess then
    Result := NtxOpenThreadToken(hxToken, NtCurrentThread, DesiredAccess,
      HandleAttributes);

  // Restore previous impersonation
  NtxRestoreImpersonation(NtCurrentThread, hxOldToken);
end;

function NtxFilterToken(out hxNewToken: IHandle; hToken: THandle; Flags:
  Cardinal; SidsToDisable: TArray<ISid>; PrivilegesToDelete: TArray<TLuid>;
  SidsToRestrict: TArray<ISid>): TNtxStatus;
var
  hxToken: IHandle;
  hNewToken: THandle;
  DisableSids, RestrictSids: IMemory<PTokenGroups>;
  DeletePrivileges: IMemory<PTokenPrivileges>;
begin
  // Manage pseudo-tokens
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_DUPLICATE);

  if not Result.IsSuccess then
    Exit;

  DisableSids := NtxpAllocGroups(SidsToDisable, 0);
  RestrictSids := NtxpAllocGroups(SidsToRestrict, 0);
  DeletePrivileges := NtxpAllocPrivileges(PrivilegesToDelete, 0);

  Result.Location := 'NtFilterToken';
  Result.LastCall.Expects(TOKEN_DUPLICATE, @TokenAccessType);

  Result.Status := NtFilterToken(hxToken.Handle, Flags, DisableSids.Data,
    DeletePrivileges.Data, RestrictSids.Data, hNewToken);

  if Result.IsSuccess then
    hxNewToken := TAutoHandle.Capture(hNewToken);
end;

function NtxCreateToken(out hxToken: IHandle; TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel; const TokenSource:
  TTokenSource; AuthenticationId: TLuid; User: TGroup; PrimaryGroup: ISid;
  Groups: TArray<TGroup>; Privileges: TArray<TPrivilege>; Owner: ISid;
  DefaultDacl: IAcl; ExpirationTime: TLargeInteger; HandleAttributes:
  Cardinal): TNtxStatus;
var
  hToken: THandle;
  QoS: TSecurityQualityOfService;
  ObjAttr: TObjectAttributes;
  TokenUser: TSidAndAttributes;
  TokenGroups: IMemory<PTokenGroups>;
  TokenPrivileges: IMemory<PTokenPrivileges>;
  TokenOwner: TTokenSidInformation;
  TokenOwnerRef: PTokenSidInformation;
  TokenPrimaryGroup: TTokenSidInformation;
  TokenDefaultDacl: TTokenDefaultDacl;
  TokenDefaultDaclRef: PTokenDefaultDacl;
begin
  InitializaQoS(QoS, ImpersonationLevel);
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes, 0, @QoS);

  // Prepare user
  Assert(Assigned(User.SecurityIdentifier), 'User SID cannot be null');
  TokenUser.Sid := User.SecurityIdentifier.Sid;
  TokenUser.Attributes := User.Attributes;

  // Prepare groups and privileges
  TokenGroups := NtxpAllocGroups2(Groups);
  TokenPrivileges:= NtxpAllocPrivileges2(Privileges);

  // Owner is optional
  if Assigned(Owner) then
  begin
    TokenOwner.Sid := Owner.Sid;
    TokenOwnerRef := @TokenOwner;
  end
  else
    TokenOwnerRef := nil;

  // Prepare primary group
  Assert(Assigned(PrimaryGroup), 'Primary group cannot be null');
  TokenPrimaryGroup.Sid := PrimaryGroup.Sid;

  // Default DACL is optional
  if Assigned(DefaultDacl) then
  begin
    TokenDefaultDacl.DefaultDacl := DefaultDacl.Acl;
    TokenDefaultDaclRef := @TokenDefaultDacl;
  end
  else
    TokenDefaultDaclRef := nil;

  Result.Location := 'NtCreateToken';
  Result.LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;

  Result.Status := NtCreateToken(hToken, TOKEN_ALL_ACCESS, @ObjAttr, TokenType,
    AuthenticationId, ExpirationTime, TokenUser, TokenGroups.Data,
    TokenPrivileges.Data, TokenOwnerRef, TokenPrimaryGroup,
    TokenDefaultDaclRef, TokenSource);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxCreateLowBoxToken(out hxToken: IHandle; hExistingToken: THandle;
  Package: PSid; Capabilities: TArray<TGroup>; Handles: TArray<THandle>;
  HandleAttributes: Cardinal): TNtxStatus;
var
  hxExistingToken: IHandle;
  hToken: THandle;
  ObjAttr: TObjectAttributes;
  CapArray: TArray<TSidAndAttributes>;
  i: Integer;
begin
  Result := LdrxCheckNtDelayedImport('NtCreateLowBoxToken');

  if not Result.IsSuccess then
    Exit;

  // Manage pseudo-handles on input
  Result := NtxExpandPseudoToken(hxExistingToken, hExistingToken,
    TOKEN_DUPLICATE);

  if not Result.IsSuccess then
    Exit;

  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);

  // Prepare capabilities
  SetLength(CapArray, Length(Capabilities));
  for i := 0 to High(CapArray) do
  begin
    CapArray[i].Sid := Capabilities[i].SecurityIdentifier.Sid;
    CapArray[i].Attributes := Capabilities[i].Attributes;
  end;

  Result.Location := 'NtCreateLowBoxToken';
  Result.LastCall.Expects(TOKEN_DUPLICATE, @TokenAccessType);

  Result.Status := NtCreateLowBoxToken(hToken, hxExistingToken.Handle,
    TOKEN_ALL_ACCESS, @ObjAttr, Package, Length(CapArray), CapArray,
    Length(Handles), Handles);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

{ Other operations }

function NtxAdjustPrivileges(hToken: THandle; Privileges: TArray<TLuid>;
  NewAttribute: Cardinal; IgnoreMissing: Boolean): TNtxStatus;
var
  hxToken: IHandle;
  TokenPrivileges: IMemory<PTokenPrivileges>;
begin
  // Manage working with pseudo-handles
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_ADJUST_PRIVILEGES);

  if not Result.IsSuccess then
    Exit;

  TokenPrivileges := NtxpAllocPrivileges(Privileges, NewAttribute);

  Result.Location := 'NtAdjustPrivilegesToken';
  Result.LastCall.Expects(TOKEN_ADJUST_PRIVILEGES, @TokenAccessType);
  Result.Status := NtAdjustPrivilegesToken(hxToken.Handle, False,
    TokenPrivileges.Data, 0, nil, nil);

  if not IgnoreMissing and (Result.Status = STATUS_NOT_ALL_ASSIGNED) then
    Result.Status := NTSTATUS_FROM_WIN32(ERROR_NOT_ALL_ASSIGNED);
end;

function NtxAdjustPrivilege(hToken: THandle; Privilege: TSeWellKnownPrivilege;
  NewAttribute: Cardinal; IgnoreMissing: Boolean = False): TNtxStatus;
var
  Privileges: TArray<TLuid>;
begin
  SetLength(Privileges, 1);
  Privileges[0] := TLuid(Privilege);
  Result := NtxAdjustPrivileges(hToken, Privileges, NewAttribute,
    IgnoreMissing);
end;

function NtxAdjustGroups(hToken: THandle; Sids: TArray<ISid>;
  NewAttribute: Cardinal; ResetToDefault: Boolean): TNtxStatus;
var
  hxToken: IHandle;
  TokenGroups: IMemory<PTokenGroups>;
begin
  // Manage working with pseudo-handles
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_ADJUST_GROUPS);

  if not Result.IsSuccess then
    Exit;

  TokenGroups := NtxpAllocGroups(Sids, NewAttribute);

  Result.Location := 'NtAdjustGroupsToken';
  Result.LastCall.Expects(TOKEN_ADJUST_GROUPS, @TokenAccessType);
  Result.Status := NtAdjustGroupsToken(hxToken.Handle, ResetToDefault,
    TokenGroups.Data, 0, nil, nil);
end;

end.
