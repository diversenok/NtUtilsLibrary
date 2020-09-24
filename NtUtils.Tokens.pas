unit NtUtils.Tokens;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, NtUtils, NtUtils.Objects,
  DelphiApi.Reflection;

const
  // Now supported everywhere on all OS versions
  NtCurrentProcessToken: THandle = THandle(-4);
  NtCurrentThreadToken: THandle = THandle(-5);
  NtCurrentEffectiveToken: THandle = THandle(-6);

type
  TFbqnValue = record
    Version: UInt64;
    Name: String;
  end;

  TSecurityAttribute = record
    Name: String;
    ValueType: TSecurityAttributeType;
    Flags: TSecurityAttributeFlags;
    ValuesUInt64: TArray<UInt64>;
    ValuesString: TArray<String>;
    ValuesFqbn: TArray<TFbqnValue>;
    ValuesSid: TArray<ISid>;
    ValuesOctet: TArray<IMemory>;
  end;

{ ------------------------------ Creation ---------------------------------- }

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
  TokenType: TTokenType; ImpersonationLevel: TSecurityImpersonationLevel =
  SecurityImpersonation; EffectiveOnly: Boolean = False; DesiredAccess:
  TAccessMask = TOKEN_ALL_ACCESS; HandleAttributes: Cardinal = 0): TNtxStatus;

// Duplicate existine token in-place
function NtxDuplicateTokenLocal(var hxToken: IHandle; TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  EffectiveOnly: Boolean = False; DesiredAccess: TAccessMask = TOKEN_ALL_ACCESS;
  HandleAttributes: Cardinal = 0): TNtxStatus;

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

// Create a new token from scratch. Requires SeCreateTokenPrivilege & Win 8+
function NtxCreateTokenEx(out hxToken: IHandle; TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel; const TokenSource:
  TTokenSource; AuthenticationId: TLuid; User: TGroup; PrimaryGroup: ISid;
  Groups: TArray<TGroup> = nil; Privileges: TArray<TPrivilege> = nil;
  UserAttributes: TArray<TSecurityAttribute> = nil; DeviceAttributes:
  TArray<TSecurityAttribute> = nil; DeviceGroups: TArray<TGroup> = nil; Owner:
  ISid = nil; DefaultDacl: IAcl = nil; MandatoryPolicy: Cardinal =
  TOKEN_MANDATORY_POLICY_ALL; ExpirationTime: TLargeInteger = INFINITE_FUTURE;
  HandleAttributes: Cardinal = 0): TNtxStatus;

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
  Result.LastCall.AttachAccess<TProcessAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_LIMITED_INFORMATION);

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
  Result.LastCall.AttachAccess<TThreadAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_QUERY_LIMITED_INFORMATION);

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
begin
  // Backup our impersonation token
  hxOldToken := NtxBackupImpersonation(NtCurrentThread);

  // Use direct impersonation to make us impersonate a copy of an effective
  // security context of the target thread.
  Result := NtxImpersonateThread(NtCurrentThread, hThread, ImpersonationLevel,
    EffectiveOnly);

  if not Result.IsSuccess then
    Exit;

  // Read the token from our thread
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
  TokenType: TTokenType; ImpersonationLevel: TSecurityImpersonationLevel;
  EffectiveOnly: Boolean; DesiredAccess: TAccessMask; HandleAttributes:
  Cardinal): TNtxStatus;
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
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE);

  Result.Status := NtDuplicateToken(hxExistingToken.Handle, DesiredAccess,
    @ObjAttr, EffectiveOnly, TokenType, hToken);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxDuplicateTokenLocal(var hxToken: IHandle; TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel; EffectiveOnly: Boolean;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal): TNtxStatus;
var
  hxOriginalToken: IHandle;
begin
  hxOriginalToken := hxToken;

  Result := NtxDuplicateToken(hxToken, hxOriginalToken.Handle, TokenType,
    ImpersonationLevel, EffectiveOnly, DesiredAccess, HandleAttributes);
end;

function NtxOpenAnonymousToken(out hxToken: IHandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal): TNtxStatus;
var
  hxOldToken: IHandle;
begin
  hxOldToken := NtxBackupImpersonation(NtCurrentThread);

  Result := NtxImpersonateAnonymousToken(NtCurrentThread);

  if not Result.IsSuccess then
    Exit;

  Result := NtxOpenThreadToken(hxToken, NtCurrentThread, DesiredAccess,
    HandleAttributes);

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
  // Manage pseudo-tokens. We need as much access as possible since
  // NtFilterToken copies the access mask. However, only Duplicate is a must.
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_DUPLICATE or
    MAXIMUM_ALLOWED);

  if not Result.IsSuccess then
    Exit;

  DisableSids := NtxpAllocGroups(SidsToDisable, 0);
  RestrictSids := NtxpAllocGroups(SidsToRestrict, 0);
  DeletePrivileges := NtxpAllocPrivileges(PrivilegesToDelete, 0);

  Result.Location := 'NtFilterToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE);

  Result.Status := NtFilterToken(hxToken.Handle, Flags, DisableSids.Data,
    DeletePrivileges.Data, RestrictSids.Data, hNewToken);

  if Result.IsSuccess then
    hxNewToken := TAutoHandle.Capture(hNewToken);
end;

function SidInfoRefOrNil(const [ref] Sid: PSid): PTokenSidInformation;
begin
  if Assigned(Sid) then
    Result := PTokenSidInformation(@Sid)
  else
    Result := nil;
end;

function DefaultDaclRefOrNil(const [ref] Acl: PAcl): PTokenDefaultDacl;
begin
  if Assigned(Acl) then
    Result := PTokenDefaultDacl(@Acl)
  else
    Result := nil;
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
  TokenPrimaryGroup: TTokenSidInformation;
  OwnerSid: PSid;
  DefaultAcl: PAcl;
begin
  InitializaQoS(QoS, ImpersonationLevel);
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes, 0, @QoS);

  // Prepare the user
  TokenUser.Sid := User.Sid.Data;
  TokenUser.Attributes := User.Attributes;

  // Allocate groups and privileges
  TokenGroups := NtxpAllocGroups2(Groups);
  TokenPrivileges:= NtxpAllocPrivileges2(Privileges);

  // Prepare the rest
  OwnerSid := Ptr.RefOrNil<PSid>(Owner);
  DefaultAcl := Ptr.RefOrNil<PAcl>(DefaultDacl);
  TokenPrimaryGroup.Sid := PrimaryGroup.Data;

  Result.Location := 'NtCreateToken';
  Result.LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;

  Result.Status := NtCreateToken(hToken, TOKEN_ALL_ACCESS, @ObjAttr, TokenType,
    AuthenticationId, ExpirationTime, TokenUser, TokenGroups.Data,
    TokenPrivileges.Data, SidInfoRefOrNil(OwnerSid), TokenPrimaryGroup,
    DefaultDaclRefOrNil(DefaultAcl), TokenSource);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxCreateTokenEx(out hxToken: IHandle; TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel; const TokenSource:
  TTokenSource; AuthenticationId: TLuid; User: TGroup; PrimaryGroup: ISid;
  Groups: TArray<TGroup>; Privileges: TArray<TPrivilege>; UserAttributes:
  TArray<TSecurityAttribute>; DeviceAttributes: TArray<TSecurityAttribute>;
  DeviceGroups: TArray<TGroup>; Owner: ISid; DefaultDacl: IAcl; MandatoryPolicy:
  Cardinal; ExpirationTime: TLargeInteger; HandleAttributes: Cardinal):
  TNtxStatus;
var
  hToken: THandle;
  QoS: TSecurityQualityOfService;
  ObjAttr: TObjectAttributes;
  TokenUser: TSidAndAttributes;
  TokenGroups, TokenDevGroups: IMemory<PTokenGroups>;
  TokenPrivileges: IMemory<PTokenPrivileges>;
  TokenUserAttr, TokenDeviceAttr: IMemory<PTokenSecurityAttributes>;
  TokenPrimaryGroup: TTokenSidInformation;
  OwnerSid: PSid;
  DefaultAcl: PAcl;
begin
  // Check required function
  Result := LdrxCheckNtDelayedImport('NtCreateTokenEx');

  if not Result.IsSuccess then
    Exit;

  InitializaQoS(QoS, ImpersonationLevel);
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes, 0, @QoS);

  // Prepare the user
  TokenUser.Sid := User.Sid.Data;
  TokenUser.Attributes := User.Attributes;

  // Allocate groups, privileges, and attributes
  TokenGroups := NtxpAllocGroups2(Groups);
  TokenPrivileges:= NtxpAllocPrivileges2(Privileges);
  TokenUserAttr := NtxpAllocSecurityAttributes(UserAttributes);
  TokenDeviceAttr := NtxpAllocSecurityAttributes(DeviceAttributes);
  TokenDevGroups := NtxpAllocGroups2(DeviceGroups);

  // Prepare the rest
  OwnerSid := Ptr.RefOrNil<PSid>(Owner);
  DefaultAcl := Ptr.RefOrNil<PAcl>(DefaultDacl);
  TokenPrimaryGroup.Sid := PrimaryGroup.Data;

  Result.Location := 'NtCreateTokenEx';
  Result.LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;

  Result.Status := NtCreateTokenEx(hToken, TOKEN_ALL_ACCESS, @ObjAttr,
    TokenType, AuthenticationId, ExpirationTime, TokenUser, TokenGroups.Data,
    TokenPrivileges.Data, TokenUserAttr.Data, TokenDeviceAttr.Data,
    TokenDevGroups.Data, MandatoryPolicy, SidInfoRefOrNil(OwnerSid),
    TokenPrimaryGroup, DefaultDaclRefOrNil(DefaultAcl), TokenSource);

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
    CapArray[i].Sid := Capabilities[i].Sid.Data;
    CapArray[i].Attributes := Capabilities[i].Attributes;
  end;

  Result.Location := 'NtCreateLowBoxToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE);

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
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ADJUST_PRIVILEGES);
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
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ADJUST_GROUPS);
  Result.Status := NtAdjustGroupsToken(hxToken.Handle, ResetToDefault,
    TokenGroups.Data, 0, nil, nil);
end;

end.
