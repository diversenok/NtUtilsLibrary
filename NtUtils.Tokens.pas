unit NtUtils.Tokens;

{
  The module provides support for various operations with tokens via Native API.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, NtUtils, NtUtils.Objects,
  DelphiApi.Reflection;

const
  // Now supported everywhere on all OS versions
  NtCurrentProcessToken = THandle(-4);
  NtCurrentThreadToken = THandle(-5);
  NtCurrentEffectiveToken = THandle(-6);

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

{ Pseudo-handles }

function NtxCurrentProcessToken: IHandle;
function NtxCurrentThreadToken: IHandle;
function NtxCurrentEffectiveToken: IHandle;

{ ------------------------------ Creation ---------------------------------- }

// Open a token of a process
function NtxOpenProcessToken(
  out hxToken: IHandle;
  hProcess: THandle;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

function NtxOpenProcessTokenById(
  out hxToken: IHandle;
  PID: TProcessId;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Open a token of a thread
function NtxOpenThreadToken(
  out hxToken: IHandle;
  hThread: THandle;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  InverseOpenLogic: Boolean = False
): TNtxStatus;

function NtxOpenThreadTokenById(
  out hxToken: IHandle;
  TID: TThreadId;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  InverseOpenLogic: Boolean = False
): TNtxStatus;

// Open an effective token of a thread
function NtxOpenEffectiveTokenById(
  out hxToken: IHandle;
  const ClientId: TClientId;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  InverseOpenLogic: Boolean = False
): TNtxStatus;

// Convert a pseudo-handle to an actual token handle
function NtxOpenPseudoToken(
  out hxToken: IHandle;
  Handle: THandle;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  InverseOpenLogic: Boolean = False
): TNtxStatus;

// Make sure to convert a pseudo-handle to an actual token handle if necessary
// NOTE: Do not save the handle returned from this function
function NtxExpandPseudoToken(
  out hxToken: IHandle;
  hToken: THandle;
  DesiredAccess: TTokenAccessMask
): TNtxStatus;

// Copy an effective security context of a thread via direct impersonation
function NtxDuplicateEffectiveToken(
  out hxToken: IHandle;
  hThread: THandle;
  ImpersonationLevel: TSecurityImpersonationLevel;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  EffectiveOnly: Boolean = False
): TNtxStatus;

function NtxDuplicateEffectiveTokenById(
  out hxToken: IHandle;
  TID: TThreadId;
  ImpersonationLevel: TSecurityImpersonationLevel;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  EffectiveOnly: Boolean = False
): TNtxStatus;

// Duplicate existing token
function NtxDuplicateToken(
  out hxToken: IHandle;
  hExistingToken: THandle;
  TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Duplicate existine token in-place
function NtxDuplicateTokenLocal(
  var hxToken: IHandle;
  TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open anonymous token
function NtxOpenAnonymousToken(
  out hxToken: IHandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Filter a token
function NtxFilterToken(
  out hxNewToken: IHandle;
  hToken: THandle;
  Flags: TTokenFilterFlags;
  [opt] const SidsToDisable: TArray<ISid> = nil;
  [opt] const PrivilegesToDelete: TArray<TLuid> = nil;
  [opt] const SidsToRestrict: TArray<ISid> = nil
): TNtxStatus;

// Create a new token from scratch. Requires SeCreateTokenPrivilege.
function NtxCreateToken(
  out hxToken: IHandle;
  TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel;
  const TokenSource: TTokenSource;
  const AuthenticationId: TLuid;
  const User: TGroup;
  const PrimaryGroup: ISid;
  [opt] const Groups: TArray<TGroup> = nil;
  [opt] const Privileges: TArray<TPrivilege> = nil;
  [opt] const Owner: ISid = nil;
  [opt] const DefaultDacl: IAcl = nil;
  const ExpirationTime: TLargeInteger = INFINITE_FUTURE;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Create a new token from scratch. Requires SeCreateTokenPrivilege & Win 8+
function NtxCreateTokenEx(
  out hxToken: IHandle;
  TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel;
  const TokenSource: TTokenSource;
  const AuthenticationId: TLuid;
  const User: TGroup;
  const PrimaryGroup: ISid;
  [opt] const Groups: TArray<TGroup> = nil;
  [opt] const Privileges: TArray<TPrivilege> = nil;
  [opt] const UserAttributes: TArray<TSecurityAttribute> = nil;
  [opt] const DeviceAttributes: TArray<TSecurityAttribute> = nil;
  [opt] const DeviceGroups: TArray<TGroup> = nil;
  [opt] const Owner: ISid = nil;
  [opt] const DefaultDacl: IAcl = nil;
  MandatoryPolicy: TTokenMandatoryPolicy = TOKEN_MANDATORY_POLICY_ALL;
  const ExpirationTime: TLargeInteger = INFINITE_FUTURE;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Create an AppContainer token, Win 8+
function NtxCreateLowBoxToken(
  out hxToken: IHandle;
  hExistingToken: THandle;
  [in] Package: PSid;
  [opt] const Capabilities: TArray<TGroup> = nil;
  [opt] const Handles: TArray<THandle> = nil;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

{ --------------------------- Other operations ---------------------------- }

// Adjust a single privilege
function NtxAdjustPrivilege(
  hToken: THandle;
  Privilege: TSeWellKnownPrivilege;
  NewAttribute: TPrivilegeAttributes;
  IgnoreMissing: Boolean = False
): TNtxStatus;

// Adjust multiple privileges
function NtxAdjustPrivileges(
  hToken: THandle;
  [opt] const Privileges: TArray<TSeWellKnownPrivilege>;
  NewAttribute: TPrivilegeAttributes;
  IgnoreMissing: Boolean = False
): TNtxStatus;

// Adjust groups
function NtxAdjustGroups(
  hToken: THandle;
  const Sids: TArray<ISid>;
  NewAttribute: TGroupAttributes;
  ResetToDefault: Boolean
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpsapi, Winapi.WinError, NtUtils.Tokens.Misc,
  NtUtils.Processes, NtUtils.Tokens.Impersonate, NtUtils.Threads,
  NtUtils.Ldr, Ntapi.ntpebteb, DelphiUtils.AutoObject;

{ Pseudo-handles }

function NtxCurrentProcessToken;
begin
  Result := TAutoHandle.Capture(NtCurrentProcessToken);
  Result.AutoRelease := False;
end;

function NtxCurrentThreadToken;
begin
  Result := TAutoHandle.Capture(NtCurrentThreadToken);
  Result.AutoRelease := False;
end;

function NtxCurrentEffectiveToken;
begin
  Result := TAutoHandle.Capture(NtCurrentEffectiveToken);
  Result.AutoRelease := False;
end;

{ Creation }

function NtxOpenProcessToken;
var
  hToken: THandle;
begin
  Result.Location := 'NtOpenProcessTokenEx';
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_LIMITED_INFORMATION);

  Result.Status := NtOpenProcessTokenEx(hProcess, DesiredAccess,
    HandleAttributes, hToken);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxOpenProcessTokenById;
var
  hxProcess: IHandle;
begin
  Result := NtxOpenProcess(hxProcess, PID, PROCESS_QUERY_LIMITED_INFORMATION);

  if Result.IsSuccess then
    Result := NtxOpenProcessToken(hxToken, hxProcess.Handle, DesiredAccess,
      HandleAttributes);
end;

function NtxOpenThreadToken;
var
  hToken: THandle;
begin
  Result.Location := 'NtOpenThreadTokenEx';
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_QUERY_LIMITED_INFORMATION);

  // By default, when opening other thread's token use our effective (thread)
  // security context. When reading a token from the current thread use the
  // process' security context.

  Result.Status := NtOpenThreadTokenEx(hThread, DesiredAccess,
    (hThread = NtCurrentThread) xor InverseOpenLogic, HandleAttributes, hToken);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxOpenThreadTokenById;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_QUERY_LIMITED_INFORMATION);

  if Result.IsSuccess then
    Result := NtxOpenThreadToken(hxToken, hxThread.Handle, DesiredAccess,
      HandleAttributes, InverseOpenLogic);
end;

function NtxOpenEffectiveTokenById;
begin
  // When querying effective token we read thread token first, and then fall
  // back to process token if it's not available.

  Result := NtxOpenThreadTokenById(hxToken, ClientId.UniqueThread,
    DesiredAccess, HandleAttributes, InverseOpenLogic);

  if Result.Status = STATUS_NO_TOKEN then
    Result := NtxOpenProcessTokenById(hxToken, ClientId.UniqueProcess,
      DesiredAccess, HandleAttributes);
end;

function NtxOpenPseudoToken;
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

function NtxExpandPseudoToken;
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

function NtxDuplicateEffectiveToken;
var
  StateBackup: IAutoReleasable;
begin
  // Backup our impersonation. IAutoReleasable will revert it
  // when we exit this function.
  StateBackup := NtxBackupImpersonation(NtxCurrentThread);

  // Use direct impersonation to make us impersonate a copy of an effective
  // security context of the target thread.
  Result := NtxImpersonateThread(NtCurrentThread, hThread, ImpersonationLevel,
    EffectiveOnly);

  if not Result.IsSuccess then
  begin
    // No need to revert impersonation if we did not alter it.
    StateBackup.AutoRelease := False;
    Exit;
  end;

  // Read the token from our thread
  Result := NtxOpenThreadToken(hxToken, NtCurrentThread, DesiredAccess,
    HandleAttributes);
end;

function NtxDuplicateEffectiveTokenById;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_DIRECT_IMPERSONATION);

  if Result.IsSuccess then
    Result := NtxDuplicateEffectiveToken(hxToken, hxThread.Handle,
      ImpersonationLevel, DesiredAccess, HandleAttributes, EffectiveOnly);
end;

function NtxDuplicateToken;
var
  hxExistingToken: IHandle;
  hToken: THandle;
begin
  // Manage support for pseudo-handles
  Result := NtxExpandPseudoToken(hxExistingToken, hExistingToken,
    TOKEN_DUPLICATE);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtDuplicateToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE);

  Result.Status := NtDuplicateToken(
    hxExistingToken.Handle,
    AccessMaskOverride(TOKEN_ALL_ACCESS, ObjectAttributes),
    AttributeBuilder(ObjectAttributes)
      .UseImpersonation(ImpersonationLevel)
      .ToNative,
    Assigned(ObjectAttributes) and ObjectAttributes.EffectiveOnly,
    TokenType,
    hToken
  );

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxDuplicateTokenLocal;
var
  hxNewToken: IHandle;
begin
  Result := NtxDuplicateToken(hxNewToken, hxToken.Handle, TokenType,
    ImpersonationLevel, ObjectAttributes);

  if Result.IsSuccess then
    hxToken := hxNewToken;
end;

function NtxOpenAnonymousToken;
var
  StateBackup: IAutoReleasable;
begin
  // Revert our impersonation when we exit this function.
  StateBackup := NtxBackupImpersonation(NtxCurrentThread);

  Result := NtxImpersonateAnonymousToken(NtCurrentThread);

  if not Result.IsSuccess then
  begin
    // No need to revert impersonation if we did not alter it.
    StateBackup.AutoRelease := False;
    Exit;
  end;

  Result := NtxOpenThreadToken(hxToken, NtCurrentThread, DesiredAccess,
    HandleAttributes);
end;

function NtxFilterToken;
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

function NtxCreateToken;
var
  hToken: THandle;
  TokenUser: TSidAndAttributes;
  TokenGroups: IMemory<PTokenGroups>;
  TokenPrivileges: IMemory<PTokenPrivileges>;
  TokenPrimaryGroup: TTokenSidInformation;
  OwnerSid: PSid;
  DefaultAcl: PAcl;
begin
  // Prepare the user
  TokenUser.Sid := User.Sid.Data;
  TokenUser.Attributes := User.Attributes;

  // Allocate groups and privileges
  TokenGroups := NtxpAllocGroups2(Groups);
  TokenPrivileges:= NtxpAllocPrivileges2(Privileges);

  // Prepare the rest
  OwnerSid := IMem.RefOrNil<PSid>(Owner);
  DefaultAcl := IMem.RefOrNil<PAcl>(DefaultDacl);
  TokenPrimaryGroup.Sid := PrimaryGroup.Data;

  Result.Location := 'NtCreateToken';
  Result.LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;

  Result.Status := NtCreateToken(hToken, TOKEN_ALL_ACCESS, AttributeBuilder(
    ObjectAttributes).UseImpersonation(ImpersonationLevel).ToNative, TokenType,
    AuthenticationId, ExpirationTime, TokenUser, TokenGroups.Data,
    TokenPrivileges.Data, SidInfoRefOrNil(OwnerSid), TokenPrimaryGroup,
    DefaultDaclRefOrNil(DefaultAcl), TokenSource);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxCreateTokenEx;
var
  hToken: THandle;
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
  OwnerSid := IMem.RefOrNil<PSid>(Owner);
  DefaultAcl := IMem.RefOrNil<PAcl>(DefaultDacl);
  TokenPrimaryGroup.Sid := PrimaryGroup.Data;

  Result.Location := 'NtCreateTokenEx';
  Result.LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;

  Result.Status := NtCreateTokenEx(
    hToken,
    AccessMaskOverride(TOKEN_ALL_ACCESS, ObjectAttributes),
    AttributeBuilder(ObjectAttributes)
      .UseImpersonation(ImpersonationLevel)
      .ToNative,
    TokenType,
    AuthenticationId,
    ExpirationTime,
    TokenUser,
    TokenGroups.Data,
    TokenPrivileges.Data,
    TokenUserAttr.Data,
    TokenDeviceAttr.Data,
    TokenDevGroups.Data,
    MandatoryPolicy,
    SidInfoRefOrNil(OwnerSid),
    TokenPrimaryGroup,
    DefaultDaclRefOrNil(DefaultAcl),
    TokenSource
  );

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

function NtxCreateLowBoxToken;
var
  hxExistingToken: IHandle;
  hToken: THandle;
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

  // Prepare capabilities
  SetLength(CapArray, Length(Capabilities));
  for i := 0 to High(CapArray) do
  begin
    CapArray[i].Sid := Capabilities[i].Sid.Data;
    CapArray[i].Attributes := Capabilities[i].Attributes;
  end;

  Result.Location := 'NtCreateLowBoxToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE);

  Result.Status := NtCreateLowBoxToken(
    hToken,
    hxExistingToken.Handle,
    AccessMaskOverride(TOKEN_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    Package,
    Length(CapArray),
    CapArray,
    Length(Handles),
    Handles
  );

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

{ Other operations }

function NtxAdjustPrivileges;
var
  hxToken: IHandle;
begin
  // Manage working with pseudo-handles
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_ADJUST_PRIVILEGES);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtAdjustPrivilegesToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ADJUST_PRIVILEGES);
  Result.Status := NtAdjustPrivilegesToken(
    hxToken.Handle,
    False,
    NtxpAllocWellKnownPrivileges(Privileges, NewAttribute).Data,
    0,
    nil,
    nil
  );

  // If we need to fail the function when some privileges are missing,
  // STATUS_NOT_ALL_ASSIGNED won't work because it is a successful code.
  // Use something else.

  if (Result.Status = STATUS_NOT_ALL_ASSIGNED) and not IgnoreMissing then
  begin
    Result.Location := 'NtxAdjustPrivileges';

    if Length(Privileges) = 1 then
      Result.Status := STATUS_PRIVILEGE_NOT_HELD
    else
      Result.Win32Error := ERROR_NOT_ALL_ASSIGNED;
  end;

  // Forward a single privilege
  if Length(Privileges) = 1 then
    Result.LastCall.ExpectedPrivilege := Privileges[0];
end;

function NtxAdjustPrivilege;
begin
  Result := NtxAdjustPrivileges(hToken, [Privilege], NewAttribute,
    IgnoreMissing);
end;

function NtxAdjustGroups;
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
