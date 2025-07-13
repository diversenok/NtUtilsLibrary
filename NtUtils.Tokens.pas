unit NtUtils.Tokens;

{
  The module provides support for various operations with tokens via Native API.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, NtUtils, NtUtils.Objects;

type
  TFbqnValue = record
    Version: UInt64;
    Name: String;

    constructor Create(
      const Version: UInt64;
      const Name: String
    );
  end;

  TSecurityAttribute = record
    Name: String;
    ValueType: TSecurityAttributeType;
    Flags: TSecurityAttributeFlags;
    ValuesUInt64: TArray<UInt64>;
    ValuesString: TArray<String>;
    ValuesFqbn: TArray<TFbqnValue>;
    ValuesOctet: TArray<IMemory>;

    constructor CreateUInt64(
      const Name: String;
      Flags: TSecurityAttributeFlags;
      const Values: TArray<UInt64>;
      ValueType: TSecurityAttributeType = SECURITY_ATTRIBUTE_TYPE_UINT64
    );

    constructor CreateString(
      const Name: String;
      Flags: TSecurityAttributeFlags;
      const Values: TArray<String>
    );

    constructor CreateFqbn(
      const Name: String;
      Flags: TSecurityAttributeFlags;
      const Values: TArray<TFbqnValue>
    );

    constructor CreateOctet(
      const Name: String;
      Flags: TSecurityAttributeFlags;
      const Values: TArray<IMemory>;
      ValueType: TSecurityAttributeType = SECURITY_ATTRIBUTE_TYPE_OCTET_STRING
    );
  end;

{ Pseudo-handles }

// Open a token of a process
function NtxOpenProcessToken(
  out hxToken: IHandle;
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] const hxProcess: IHandle;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Open a token of a process by ID
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenProcessTokenById(
  out hxToken: IHandle;
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] PID: TProcessId;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Open a token of a thread
function NtxOpenThreadToken(
  out hxToken: IHandle;
  [Access(THREAD_QUERY_LIMITED_INFORMATION)] const hxThread: IHandle;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  InvertOpenLogic: Boolean = False
): TNtxStatus;

// Open a token of a thread by ID
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenThreadTokenById(
  out hxToken: IHandle;
  [Access(THREAD_QUERY_LIMITED_INFORMATION)] TID: TThreadId;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  InvertOpenLogic: Boolean = False
): TNtxStatus;

// Open an effective token of a thread
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenEffectiveTokenById(
  out hxToken: IHandle;
  const ClientId: TClientId;
  DesiredAccess: TTokenAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  InvertOpenLogic: Boolean = False
): TNtxStatus;

// Make sure to convert a pseudo-handles to an actual token handle if necessary
function NtxExpandToken(
  [opt] var hxToken: IHandle;
  DesiredAccess: TTokenAccessMask
): TNtxStatus;

// Duplicate existing token
function NtxDuplicateToken(
  out hxToken: IHandle;
  [Access(TOKEN_DUPLICATE)] hxExistingToken: IHandle;
  TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Duplicate an existing token in-place
function NtxDuplicateTokenLocal(
  [Access(TOKEN_DUPLICATE)] var hxToken: IHandle;
  TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Filter a token
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtxFilterToken(
  out hxNewToken: IHandle;
  [Access(TOKEN_DUPLICATE)] hxToken: IHandle;
  Flags: TTokenFilterFlags;
  [opt] const SidsToDisable: TArray<ISid> = nil;
  [opt] const PrivilegesToDelete: TArray<TPrivilegeId> = nil;
  [opt] const SidsToRestrict: TArray<ISid> = nil
): TNtxStatus;

// Filter a token in place
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtxFilterTokenInline(
  var hxToken: IHandle;
  Flags: TTokenFilterFlags;
  [opt] const SidsToDisable: TArray<ISid> = nil;
  [opt] const PrivilegesToDelete: TArray<TPrivilegeId> = nil;
  [opt] const SidsToRestrict: TArray<ISid> = nil
): TNtxStatus;

// Create a new token from scratch. Requires SeCreateTokenPrivilege.
[RequiredPrivilege(SE_CREATE_TOKEN_PRIVILEGE, rpAlways)]
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
[RequiredPrivilege(SE_CREATE_TOKEN_PRIVILEGE, rpAlways)]
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
  [Access(TOKEN_DUPLICATE)] hxExistingToken: IHandle;
  const Package: ISid;
  [opt] const Capabilities: TArray<TGroup> = nil;
  [opt] const Handles: TArray<IHandle> = nil;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

{ --------------------------- Other operations ---------------------------- }

// Adjust a single privilege
function NtxAdjustPrivilege(
  [Access(TOKEN_ADJUST_PRIVILEGES)] const hxToken: IHandle;
  Privilege: TSeWellKnownPrivilege;
  NewAttribute: TPrivilegeAttributes;
  IgnoreMissing: Boolean = False
): TNtxStatus;

// Adjust multiple privileges
function NtxAdjustPrivileges(
  [Access(TOKEN_ADJUST_PRIVILEGES)] hxToken: IHandle;
  [opt] const Privileges: TArray<TSeWellKnownPrivilege>;
  NewAttribute: TPrivilegeAttributes;
  IgnoreMissing: Boolean = False
): TNtxStatus;

// Adjust groups
function NtxAdjustGroups(
  [Access(TOKEN_ADJUST_GROUPS)] hxToken: IHandle;
  const Sids: TArray<ISid>;
  NewAttribute: TGroupAttributes;
  ResetToDefault: Boolean
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.WinError, NtUtils.Tokens.Misc,
  NtUtils.Processes, NtUtils.Threads, NtUtils.Ldr, Ntapi.ntpebteb,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Creation }

function NtxOpenProcessToken;
var
  hToken: THandle;
begin
  Result.Location := 'NtOpenProcessTokenEx';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_LIMITED_INFORMATION);

  Result.Status := NtOpenProcessTokenEx(HandleOrDefault(hxProcess),
    DesiredAccess, HandleAttributes, hToken);

  if Result.IsSuccess then
    hxToken := Auto.CaptureHandle(hToken);
end;

function NtxOpenProcessTokenById;
var
  hxProcess: IHandle;
begin
  Result := NtxOpenProcess(hxProcess, PID, PROCESS_QUERY_LIMITED_INFORMATION);

  if Result.IsSuccess then
    Result := NtxOpenProcessToken(hxToken, hxProcess, DesiredAccess,
      HandleAttributes);
end;

function NtxOpenThreadToken;
var
  hToken: THandle;
begin
  Result.Location := 'NtOpenThreadTokenEx';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_QUERY_LIMITED_INFORMATION);

  // By default, when opening other thread's token use our effective (thread)
  // security context. When reading a token from the current thread use the
  // process' security context.

  Result.Status := NtOpenThreadTokenEx(HandleOrDefault(hxThread), DesiredAccess,
    (Assigned(hxThread) and (hxThread.Handle = NtCurrentThread)) xor
    InvertOpenLogic, HandleAttributes, hToken);

  if Result.IsSuccess then
    hxToken := Auto.CaptureHandle(hToken);
end;

function NtxOpenThreadTokenById;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_QUERY_LIMITED_INFORMATION);

  if Result.IsSuccess then
    Result := NtxOpenThreadToken(hxToken, hxThread, DesiredAccess,
      HandleAttributes, InvertOpenLogic);
end;

function NtxOpenEffectiveTokenById;
begin
  // When querying effective token, we read thread token first, and then fall
  // back to process token if it's not available.

  Result := NtxOpenThreadTokenById(hxToken, ClientId.UniqueThread,
    DesiredAccess, HandleAttributes, InvertOpenLogic);

  if Result.Status = STATUS_NO_TOKEN then
    Result := NtxOpenProcessTokenById(hxToken, ClientId.UniqueProcess,
      DesiredAccess, HandleAttributes);
end;

function NtxExpandToken;
begin
  if not Assigned(hxToken) then
    Result := NtxSuccess

  else if hxToken.Handle = NtCurrentProcessToken then
    Result := NtxOpenProcessToken(hxToken, NtxCurrentProcess, DesiredAccess)

  else if hxToken.Handle = NtCurrentThreadToken then
    Result := NtxOpenThreadToken(hxToken, NtxCurrentThread, DesiredAccess)

  else if hxToken.Handle = NtCurrentEffectiveToken then
    Result := NtxOpenEffectiveTokenById(hxToken, NtCurrentTeb.ClientId,
      DesiredAccess)

  else
    Result := NtxSuccess
end;

function NtxDuplicateToken;
var
  ObjAttr: PObjectAttributes;
  hToken: THandle;
begin
  // Manage support for pseudo-handles
  Result := NtxExpandToken(hxExistingToken, TOKEN_DUPLICATE);

  if not Result.IsSuccess then
    Exit;

  Result := AttributeBuilder(ObjectAttributes)
    .UseImpersonation(ImpersonationLevel).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtDuplicateToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE);

  Result.Status := NtDuplicateToken(
    hxExistingToken.Handle,
    AccessMaskOverride(TOKEN_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    Assigned(ObjectAttributes) and ObjectAttributes.EffectiveOnly,
    TokenType,
    hToken
  );

  if Result.IsSuccess then
    hxToken := Auto.CaptureHandle(hToken);
end;

function NtxDuplicateTokenLocal;
var
  hxNewToken: IHandle;
begin
  Result := NtxDuplicateToken(hxNewToken, hxToken, TokenType,
    ImpersonationLevel, ObjectAttributes);

  if Result.IsSuccess then
    hxToken := hxNewToken;
end;

function NtxFilterToken;
var
  hNewToken: THandle;
begin
  // Manage pseudo-tokens. While the Duplicate access is the only strictly
  // required, we asks for as much as possible since NtFilterToken copies it.
  Result := NtxExpandToken(hxToken, TOKEN_DUPLICATE or MAXIMUM_ALLOWED);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtFilterToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE);

  Result.Status := NtFilterToken(
    hxToken.Handle,
    Flags,
    NtxpAllocGroups(SidsToDisable, 0).Data,
    NtxpAllocPrivileges(PrivilegesToDelete, 0).Data,
    NtxpAllocGroups(SidsToRestrict, 0).Data,
    hNewToken
  );

  if Result.IsSuccess then
    hxNewToken := Auto.CaptureHandle(hNewToken);
end;

function NtxFilterTokenInline;
var
  hxNewToken: IHandle;
begin
  Result := NtxFilterToken(hxNewToken, hxToken, Flags, SidsToDisable,
    PrivilegesToDelete, SidsToRestrict);

  if Result.IsSuccess then
    hxToken := hxNewToken;
end;

function NtxCreateToken;
var
  ObjAttr: PObjectAttributes;
  hToken: THandle;
  TokenUser: TSidAndAttributes;
  TokenPrimaryGroup: TTokenSidInformation;
  OwnerSid: PSid;
  DefaultAcl: PAcl;
begin
  Result := AttributeBuilder(ObjectAttributes)
    .UseImpersonation(ImpersonationLevel).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  // Prepare the user
  TokenUser.Sid := User.Sid.Data;
  TokenUser.Attributes := User.Attributes;

  // Prepare the rest
  OwnerSid := Auto.DataOrNil<PSid>(Owner);
  DefaultAcl := Auto.DataOrNil<PAcl>(DefaultDacl);
  TokenPrimaryGroup.Sid := PrimaryGroup.Data;

  Result.Location := 'NtCreateToken';
  Result.LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;

  Result.Status := NtCreateToken(
    hToken,
    AccessMaskOverride(TOKEN_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    TokenType,
    AuthenticationId,
    ExpirationTime,
    TokenUser,
    NtxpAllocGroups2(Groups).Data,
    NtxpAllocPrivileges2(Privileges).Data,
    SidInfoRefOrNil(OwnerSid),
    TokenPrimaryGroup,
    DefaultDaclRefOrNil(DefaultAcl),
    TokenSource
  );

  if Result.IsSuccess then
    hxToken := Auto.CaptureHandle(hToken);
end;

function NtxCreateTokenEx;
var
  ObjAttr: PObjectAttributes;
  hToken: THandle;
  TokenUser: TSidAndAttributes;
  TokenPrimaryGroup: TTokenSidInformation;
  OwnerSid: PSid;
  DefaultAcl: PAcl;
  UserAttr, DeviceAttr: IMemory<PTokenSecurityAttributes>;
begin
  // Check required function
  Result := LdrxCheckDelayedImport(delayed_NtCreateTokenEx);

  if not Result.IsSuccess then
    Exit;

  Result := AttributeBuilder(ObjectAttributes)
    .UseImpersonation(ImpersonationLevel).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result := NtxpAllocSecurityAttributes(UserAttr, UserAttributes);

  if not Result.IsSuccess then
    Exit;

  Result := NtxpAllocSecurityAttributes(DeviceAttr, DeviceAttributes);

  if not Result.IsSuccess then
    Exit;

  // Prepare the user
  TokenUser.Sid := User.Sid.Data;
  TokenUser.Attributes := User.Attributes;

  // Prepare the rest
  OwnerSid := Auto.DataOrNil<PSid>(Owner);
  DefaultAcl := Auto.DataOrNil<PAcl>(DefaultDacl);
  TokenPrimaryGroup.Sid := PrimaryGroup.Data;

  Result.Location := 'NtCreateTokenEx';
  Result.LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;

  Result.Status := NtCreateTokenEx(
    hToken,
    AccessMaskOverride(TOKEN_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    TokenType,
    AuthenticationId,
    ExpirationTime,
    TokenUser,
    NtxpAllocGroups2(Groups).Data,
    NtxpAllocPrivileges2(Privileges).Data,
    UserAttr.Data,
    DeviceAttr.Data,
    NtxpAllocGroups2(DeviceGroups).Data,
    MandatoryPolicy,
    SidInfoRefOrNil(OwnerSid),
    TokenPrimaryGroup,
    DefaultDaclRefOrNil(DefaultAcl),
    TokenSource
  );

  if Result.IsSuccess then
    hxToken := Auto.CaptureHandle(hToken);
end;

function NtxCreateLowBoxToken;
var
  ObjAttr: PObjectAttributes;
  hToken: THandle;
  HandleValues: TArray<THandle>;
  CapArray: TArray<TSidAndAttributes>;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_NtCreateLowBoxToken);

  if not Result.IsSuccess then
    Exit;

  // Manage pseudo-handles on input
  Result := NtxExpandToken(hxExistingToken, TOKEN_DUPLICATE);

  if not Result.IsSuccess then
    Exit;

  SetLength(HandleValues, Length(Handles));

  for i := 0 to High(HandleValues) do
    HandleValues[i] := Handles[i].Handle;

  // Prepare capabilities
  SetLength(CapArray, Length(Capabilities));
  for i := 0 to High(CapArray) do
  begin
    CapArray[i].Sid := Capabilities[i].Sid.Data;
    CapArray[i].Attributes := Capabilities[i].Attributes;
  end;

  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateLowBoxToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_DUPLICATE);

  Result.Status := NtCreateLowBoxToken(
    hToken,
    hxExistingToken.Handle,
    AccessMaskOverride(TOKEN_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    Package.Data,
    Length(CapArray),
    CapArray,
    Length(HandleValues),
    HandleValues
  );

  if Result.IsSuccess then
    hxToken := Auto.CaptureHandle(hToken);
end;

{ Other operations }

function NtxAdjustPrivileges;
begin
  // Manage working with pseudo-handles
  Result := NtxExpandToken(hxToken, TOKEN_ADJUST_PRIVILEGES);

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
  Result := NtxAdjustPrivileges(hxToken, [Privilege], NewAttribute,
    IgnoreMissing);
end;

function NtxAdjustGroups;
var
  TokenGroups: IMemory<PTokenGroups>;
begin
  // Manage working with pseudo-handles
  Result := NtxExpandToken(hxToken, TOKEN_ADJUST_GROUPS);

  if not Result.IsSuccess then
    Exit;

  TokenGroups := NtxpAllocGroups(Sids, NewAttribute);

  Result.Location := 'NtAdjustGroupsToken';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ADJUST_GROUPS);
  Result.Status := NtAdjustGroupsToken(hxToken.Handle, ResetToDefault,
    TokenGroups.Data, 0, nil, nil);
end;

{ TFbqnValue }

constructor TFbqnValue.Create;
begin
  Self.Version := Version;
  Self.Name := Name;
end;

{ TSecurityAttribute }

constructor TSecurityAttribute.CreateFqbn;
begin
  Self.Name := Name;
  Self.ValueType := SECURITY_ATTRIBUTE_TYPE_FQBN;
  Self.Flags := Flags;
  Self.ValuesFqbn := Values;
end;

constructor TSecurityAttribute.CreateOctet;
begin
  Self.Name := Name;
  Self.ValueType := ValueType;
  Self.Flags := Flags;
  Self.ValuesOctet := Values;
end;

constructor TSecurityAttribute.CreateString;
begin
  Self.Name := Name;
  Self.ValueType := SECURITY_ATTRIBUTE_TYPE_STRING;
  Self.Flags := Flags;
  Self.ValuesString := Values;
end;

constructor TSecurityAttribute.CreateUInt64;
begin
  Self.Name := Name;
  Self.ValueType := ValueType;
  Self.Flags := Flags;
  Self.ValuesUInt64 := Values;
end;

end.
