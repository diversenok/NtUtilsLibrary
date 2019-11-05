unit NtUtils.Tokens;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, NtUtils.Exceptions, NtUtils.Objects,
  NtUtils.Security.Sid, NtUtils.Security.Acl;

{ ------------------------------ Creation ---------------------------------- }

// Open a token of a process
function NtxOpenProcessToken(out hxToken: IHandle; hProcess: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

function NtxOpenProcessTokenById(out hxToken: IHandle; PID: NativeUInt;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0): TNtxStatus;

// Open a token of a thread
function NtxOpenThreadToken(out hxToken: IHandle; hThread: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0;
  InverseOpenLogic: Boolean = False): TNtxStatus;

function NtxOpenThreadTokenById(out hxToken: IHandle; TID: NativeUInt;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0;
  InverseOpenLogic: Boolean = False): TNtxStatus;

// Open an effective token of a thread
function NtxOpenEffectiveTokenById(out hxToken: IHandle; const ClientId:
  TClientId; DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0;
  InverseOpenLogic: Boolean = False): TNtxStatus;

// Convert a pseudo handle to an actual token handle
function NtxOpenPseudoToken(out hxToken: IHandle; Handle: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal = 0;
  InverseOpenLogic: Boolean = False): TNtxStatus;

// Copy an effective security context of a thread via direct impersonation
function NtxDuplicateEffectiveToken(out hxToken: IHandle; hThread: THandle;
  ImpersonationLevel: TSecurityImpersonationLevel; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal = 0; EffectiveOnly: Boolean = False): TNtxStatus;

function NtxDuplicateEffectiveTokenById(out hxToken: IHandle; TID: THandle;
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
function NtxFilterToken(out hxNewToken: IHandle; hToken: THandle;
  Flags: Cardinal; SidsToDisable: TArray<ISid>;
  PrivilegesToDelete: TArray<TLuid>; SidsToRestrict: TArray<ISid>): TNtxStatus;

// Create a new token from scratch. Requires SeCreateTokenPrivilege.
function NtxCreateToken(out hxToken: IHandle; TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel; AuthenticationId: TLuid;
  ExpirationTime: TLargeInteger; User: TGroup; Groups: TArray<TGroup>;
  Privileges: TArray<TPrivilege>; Owner: ISid; PrimaryGroup: ISid;
  DefaultDacl: IAcl; const TokenSource: TTokenSource;
  DesiredAccess: TAccessMask = TOKEN_ALL_ACCESS; HandleAttributes: Cardinal = 0)
  : TNtxStatus;

// Create an AppContainer token, Win 8+
function NtxCreateLowBoxToken(out hxToken: IHandle; ExistingToken: THandle;
  Package: PSid; Capabilities: TArray<TGroup> = nil; Handles: TArray<THandle> =
  nil; HandleAttributes: Cardinal = 0): TNtxStatus;

{ ------------------------- Query / set information ------------------------ }

type
  NtxToken = class
    // Query fixed-size information
    class function Query<T>(hToken: THandle;
      InfoClass: TTokenInformationClass; out Buffer: T): TNtxStatus; static;

    // Set fixed-size information
    class function SetInfo<T>(hToken: THandle;
      InfoClass: TTokenInformationClass; const Buffer: T): TNtxStatus; static;
  end;

// Query variable-length token information without race conditions
function NtxQueryBufferToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Status: TNtxStatus; ReturnedSize: PCardinal = nil): Pointer;

// Set variable-length token information
function NtxSetInformationToken(hToken: THandle;
  InfoClass: TTokenInformationClass; TokenInformation: Pointer;
  TokenInformationLength: Cardinal): TNtxStatus;

// Query an SID (Owner, Primary group, ...)
function NtxQuerySidToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Sid: ISid): TNtxStatus;

// Query SID and attributes (User, ...)
function NtxQueryGroupToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Group: TGroup): TNtxStatus;

// Query groups (Groups, RestrictingSIDs, LogonSIDs, ...)
function NtxQueryGroupsToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Groups: TArray<TGroup>): TNtxStatus;

// Query privileges
function NtxQueryPrivilegesToken(hToken: THandle;
  out Privileges: TArray<TPrivilege>): TNtxStatus;

// Query default DACL
function NtxQueryDefaultDaclToken(hToken: THandle; out DefaultDacl: IAcl):
  TNtxStatus;

// Set default DACL
function NtxSetDefaultDaclToken(hToken: THandle; DefaultDacl: IAcl): TNtxStatus;

// Query token flags
function NtxQueryFlagsToken(hToken: THandle; out Flags: Cardinal): TNtxStatus;

// Query integrity level of a token
function NtxQueryIntegrityToken(hToken: THandle; out  IntegrityLevel: Cardinal):
  TNtxStatus;

// Set integrity level of a token
function NtxSetIntegrityToken(hToken: THandle; IntegrityLevel: Cardinal):
  TNtxStatus;

{ --------------------------- Other operations ---------------------------- }

// Adjust privileges
function NtxAdjustPrivileges(hToken: THandle; Privileges: TArray<TLuid>;
  NewAttribute: Cardinal): TNtxStatus;
function NtxAdjustPrivilege(hToken: THandle; Privilege: TLuid;
  NewAttribute: Cardinal): TNtxStatus;

// Adjust groups
function NtxAdjustGroups(hToken: THandle; Sids: TArray<ISid>;
  NewAttribute: Cardinal; ResetToDefault: Boolean): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, Ntapi.ntpsapi, NtUtils.Tokens.Misc,
  NtUtils.Processes, NtUtils.Tokens.Impersonate, NtUtils.Threads,
  NtUtils.Access.Expected, NtUtils.Ldr, Ntapi.ntpebteb;

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

function NtxOpenProcessTokenById(out hxToken: IHandle; PID: NativeUInt;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal): TNtxStatus;
var
  hxProcess: IHandle;
begin
  Result := NtxOpenProcess(hxProcess, PID, PROCESS_QUERY_LIMITED_INFORMATION);

  if Result.IsSuccess then
    Result := NtxOpenProcessToken(hxToken, hxProcess.Value, DesiredAccess,
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

function NtxOpenThreadTokenById(out hxToken: IHandle; TID: NativeUInt;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal; InverseOpenLogic:
  Boolean): TNtxStatus;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_QUERY_LIMITED_INFORMATION);

  if Result.IsSuccess then
    Result := NtxOpenThreadToken(hxToken, hxThread.Value, DesiredAccess,
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

function NtxDuplicateEffectiveTokenById(out hxToken: IHandle; TID: THandle;
  ImpersonationLevel: TSecurityImpersonationLevel; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal; EffectiveOnly: Boolean): TNtxStatus;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_DIRECT_IMPERSONATION);

  if Result.IsSuccess then
    Result := NtxDuplicateEffectiveToken(hxToken, hxThread.Value, ImpersonationLevel,
      DesiredAccess, HandleAttributes, EffectiveOnly);
end;

function NtxDuplicateToken(out hxToken: IHandle; hExistingToken: THandle;
  DesiredAccess: TAccessMask; TokenType: TTokenType; ImpersonationLevel:
  TSecurityImpersonationLevel; HandleAttributes: Cardinal;
  EffectiveOnly: Boolean): TNtxStatus;
var
  hToken: THandle;
  ObjAttr: TObjectAttributes;
  QoS: TSecurityQualityOfService;
begin
  InitializaQoS(QoS, ImpersonationLevel, EffectiveOnly);
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes, 0, @QoS);

  Result.Location := 'NtDuplicateToken';
  Result.LastCall.Expects(TOKEN_DUPLICATE, @TokenAccessType);

  Result.Status := NtDuplicateToken(hExistingToken, DesiredAccess, @ObjAttr,
    EffectiveOnly, TokenType, hToken);

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

function NtxFilterToken(out hxNewToken: IHandle; hToken: THandle;
  Flags: Cardinal; SidsToDisable: TArray<ISid>;
  PrivilegesToDelete: TArray<TLuid>; SidsToRestrict: TArray<ISid>): TNtxStatus;
var
  hNewToken: THandle;
  DisableSids, RestrictSids: PTokenGroups;
  DeletePrivileges: PTokenPrivileges;
begin
  DisableSids := NtxpAllocGroups(SidsToDisable, 0);
  RestrictSids := NtxpAllocGroups(SidsToRestrict, 0);
  DeletePrivileges := NtxpAllocPrivileges(PrivilegesToDelete, 0);

  Result.Location := 'NtFilterToken';
  Result.LastCall.Expects(TOKEN_DUPLICATE, @TokenAccessType);

  Result.Status := NtFilterToken(hToken, Flags, DisableSids, DeletePrivileges,
    RestrictSids, hNewToken);

  if Result.IsSuccess then
    hxNewToken := TAutoHandle.Capture(hNewToken);

  FreeMem(DisableSids);
  FreeMem(RestrictSids);
  FreeMem(DeletePrivileges);
end;

function NtxCreateToken(out hxToken: IHandle; TokenType: TTokenType;
  ImpersonationLevel: TSecurityImpersonationLevel; AuthenticationId: TLuid;
  ExpirationTime: TLargeInteger; User: TGroup; Groups: TArray<TGroup>;
  Privileges: TArray<TPrivilege>; Owner: ISid; PrimaryGroup: ISid;
  DefaultDacl: IAcl; const TokenSource: TTokenSource;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal): TNtxStatus;
var
  hToken: THandle;
  QoS: TSecurityQualityOfService;
  ObjAttr: TObjectAttributes;
  TokenUser: TSidAndAttributes;
  TokenGroups: PTokenGroups;
  TokenPrivileges: PTokenPrivileges;
  TokenOwner: TTokenOwner;
  pTokenOwnerRef: PTokenOwner;
  TokenPrimaryGroup: TTokenPrimaryGroup;
  TokenDefaultDacl: TTokenDefaultDacl;
  pTokenDefaultDaclRef: PTokenDefaultDacl;
begin
  InitializaQoS(QoS, ImpersonationLevel);
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes, 0, @QoS);

  // Prepare user
  Assert(Assigned(User.SecurityIdentifier));
  TokenUser.Sid := User.SecurityIdentifier.Sid;
  TokenUser.Attributes := User.Attributes;

  // Prepare groups and privileges
  TokenGroups := NtxpAllocGroups2(Groups);
  TokenPrivileges:= NtxpAllocPrivileges2(Privileges);

  // Owner is optional
  if Assigned(Owner) then
  begin
    TokenOwner.Owner := Owner.Sid;
    pTokenOwnerRef := @TokenOwner;
  end
  else
    pTokenOwnerRef := nil;

  // Prepare primary group
  Assert(Assigned(PrimaryGroup));
  TokenPrimaryGroup.PrimaryGroup := PrimaryGroup.Sid;

  // Default Dacl is optional
  if Assigned(DefaultDacl) then
  begin
    TokenDefaultDacl.DefaultDacl := DefaultDacl.Acl;
    pTokenDefaultDaclRef := @TokenDefaultDacl;
  end
  else
    pTokenDefaultDaclRef := nil;

  Result.Location := 'NtCreateToken';
  Result.LastCall.ExpectedPrivilege := SE_CREATE_TOKEN_PRIVILEGE;

  Result.Status := NtCreateToken(hToken, DesiredAccess, @ObjAttr, TokenType,
    AuthenticationId, ExpirationTime, TokenUser, TokenGroups, TokenPrivileges,
    pTokenOwnerRef, TokenPrimaryGroup, pTokenDefaultDaclRef, TokenSource);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);

  // Clean up
  FreeMem(TokenGroups);
  FreeMem(TokenPrivileges);
end;

function NtxCreateLowBoxToken(out hxToken: IHandle; ExistingToken: THandle;
  Package: PSid; Capabilities: TArray<TGroup>; Handles: TArray<THandle>;
  HandleAttributes: Cardinal): TNtxStatus;
var
  hToken: THandle;
  ObjAttr: TObjectAttributes;
  CapArray: TArray<TSidAndAttributes>;
  i: Integer;
begin
  Result := LdrxCheckNtDelayedImport('NtCreateLowBoxToken');

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

  Result.Status := NtCreateLowBoxToken(hToken, ExistingToken, TOKEN_ALL_ACCESS,
    @ObjAttr, Package, Length(CapArray), CapArray, Length(Handles), Handles);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);
end;

{ Query / set operations }

class function NtxToken.Query<T>(hToken: THandle;
  InfoClass: TTokenInformationClass; out Buffer: T): TNtxStatus;
var
  ReturnedBytes: Cardinal;
begin
  Result.Location := 'NtQueryInformationToken';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTokenInformationClass);
  RtlxComputeTokenQueryAccess(Result.LastCall, InfoClass);

  Result.Status := NtQueryInformationToken(hToken, InfoClass, @Buffer,
    SizeOf(Buffer), ReturnedBytes);
end;

class function NtxToken.SetInfo<T>(hToken: THandle;
  InfoClass: TTokenInformationClass; const Buffer: T): TNtxStatus;
begin
  Result := NtxSetInformationToken(hToken, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxQueryBufferToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Status: TNtxStatus; ReturnedSize: PCardinal): Pointer;
var
  BufferSize, Required: Cardinal;
begin
  Status.Location := 'NtQueryInformationToken';
  Status.LastCall.CallType := lcQuerySetCall;
  Status.LastCall.InfoClass := Cardinal(InfoClass);
  Status.LastCall.InfoClassType := TypeInfo(TTokenInformationClass);
  RtlxComputeTokenQueryAccess(Status.LastCall, InfoClass);

  BufferSize := 0;
  repeat
    Result := AllocMem(BufferSize);

    Required := 0;
    Status.Status := NtQueryInformationToken(hToken, InfoClass, Result,
      BufferSize, Required);

    if not Status.IsSuccess then
    begin
      FreeMem(Result);
      Result := nil;
    end;

  until not NtxExpandBuffer(Status, BufferSize, Required);

  if Status.IsSuccess and Assigned(ReturnedSize) then
    ReturnedSize^ := BufferSize;
end;

function NtxSetInformationToken(hToken: THandle;
  InfoClass: TTokenInformationClass; TokenInformation: Pointer;
  TokenInformationLength: Cardinal): TNtxStatus;
begin
  Result.Location := 'NtSetInformationToken';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTokenInformationClass);
  RtlxComputeTokenSetAccess(Result.LastCall, InfoClass);

  Result.Status := NtSetInformationToken(hToken, InfoClass, TokenInformation,
    TokenInformationLength);
end;

function NtxQuerySidToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Sid: ISid): TNtxStatus;
var
  Buffer: PTokenOwner; // aka PTokenPrimaryGroup and ^PSid
begin
  Buffer := NtxQueryBufferToken(hToken, InfoClass, Result);

  if not Result.IsSuccess then
    Exit;

  try
    Sid := TSid.CreateCopy(Buffer.Owner);
  finally
    FreeMem(Buffer);
  end;
end;

function NtxQueryGroupToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Group: TGroup): TNtxStatus;
var
  Buffer: PSidAndAttributes; // aka PTokenUser
begin
  Buffer := NtxQueryBufferToken(hToken, InfoClass, Result);

  if not Result.IsSuccess then
    Exit;

  try
    Group.SecurityIdentifier := TSid.CreateCopy(Buffer.Sid);
    Group.Attributes := Buffer.Attributes;
  finally
    FreeMem(Buffer);
  end;
end;

function NtxQueryGroupsToken(hToken: THandle; InfoClass: TTokenInformationClass;
  out Groups: TArray<TGroup>): TNtxStatus;
var
  Buffer: PTokenGroups;
  i: Integer;
begin
  Buffer := NtxQueryBufferToken(hToken, InfoClass, Result);

  if not Result.IsSuccess then
    Exit;

  try
    SetLength(Groups, Buffer.GroupCount);
    for i := 0 to High(Groups) do
    begin
      Groups[i].SecurityIdentifier :=
        TSid.CreateCopy(Buffer.Groups{$R-}[i]{$R+}.Sid);
      Groups[i].Attributes := Buffer.Groups{$R-}[i]{$R+}.Attributes;
    end;
  finally
    FreeMem(Buffer);
  end;
end;

function NtxQueryPrivilegesToken(hToken: THandle;
  out Privileges: TArray<TPrivilege>): TNtxStatus;
var
  Buffer: PTokenPrivileges;
  i: Integer;
begin
  Buffer := NtxQueryBufferToken(hToken, TokenPrivileges, Result);

  if not Result.IsSuccess then
    Exit;

  SetLength(Privileges, Buffer.PrivilegeCount);

  for i := 0 to High(Privileges) do
    Privileges[i] := Buffer.Privileges{$R-}[i]{$R+};

  FreeMem(Buffer);
end;

function NtxQueryDefaultDaclToken(hToken: THandle; out DefaultDacl: IAcl):
  TNtxStatus;
var
  Buffer: PTokenDefaultDacl;
begin
  Buffer := NtxQueryBufferToken(hToken, TokenDefaultDacl, Result);

  if not Result.IsSuccess then
    Exit;

  try
    if Assigned(Buffer.DefaultDacl) then
      DefaultDacl := TAcl.CreateCopy(Buffer.DefaultDacl)
    else
      DefaultDacl := nil;
  finally
    FreeMem(Buffer);
  end;
end;

function NtxSetDefaultDaclToken(hToken: THandle; DefaultDacl: IAcl): TNtxStatus;
var
  Dacl: TTokenDefaultDacl;
begin
  Dacl.DefaultDacl := DefaultDacl.Acl;
  Result := NtxToken.SetInfo<TTokenDefaultDacl>(hToken, TokenDefaultDacl, Dacl);
end;

function NtxQueryFlagsToken(hToken: THandle; out Flags: Cardinal): TNtxStatus;
var
  Buffer: PTokenAccessInformation;
begin
  Buffer := NtxQueryBufferToken(hToken, TokenAccessInformation, Result);

  // TODO: Return more access information
  if Result.IsSuccess then
  begin
    Flags := Buffer.Flags;
    FreeMem(Buffer);
  end;
end;

function NtxQueryIntegrityToken(hToken: THandle; out IntegrityLevel: Cardinal):
  TNtxStatus;
var
  Integrity: TGroup;
begin
  Result := NtxQueryGroupToken(hToken, TokenIntegrityLevel, Integrity);

  if not Result.IsSuccess then
    Exit;

  // Integrity level is the last sub-authority (RID) of the integrity SID
  with Integrity.SecurityIdentifier do
    if SubAuthorities > 0 then
      IntegrityLevel := Rid
    else
      IntegrityLevel := SECURITY_MANDATORY_UNTRUSTED_RID
end;

function NtxSetIntegrityToken(hToken: THandle; IntegrityLevel: Cardinal):
  TNtxStatus;
var
  LabelSid: ISid;
  MandatoryLabel: TSidAndAttributes;
begin
  // Prepare SID for integrity level with 1 sub authority: S-1-16-X.

  LabelSid := TSid.CreateNew(SECURITY_MANDATORY_LABEL_AUTHORITY, 1,
    IntegrityLevel);

  MandatoryLabel.Sid := LabelSid.Sid;
  MandatoryLabel.Attributes := SE_GROUP_INTEGRITY_ENABLED;

  Result := NtxToken.SetInfo<TSidAndAttributes>(hToken, TokenIntegrityLevel,
    MandatoryLabel);
end;

{ Other opeations }

function NtxAdjustPrivileges(hToken: THandle; Privileges: TArray<TLuid>;
  NewAttribute: Cardinal): TNtxStatus;
var
  Buffer: PTokenPrivileges;
begin
  Buffer := NtxpAllocPrivileges(Privileges, NewAttribute);

  Result.Location := 'NtAdjustPrivilegesToken';
  Result.LastCall.Expects(TOKEN_ADJUST_PRIVILEGES, @TokenAccessType);

  Result.Status := NtAdjustPrivilegesToken(hToken, False, Buffer, 0, nil, nil);
  FreeMem(Buffer);
end;

function NtxAdjustPrivilege(hToken: THandle; Privilege: TLuid;
  NewAttribute: Cardinal): TNtxStatus;
var
  Privileges: TArray<TLuid>;
begin
  SetLength(Privileges, 1);
  Privileges[0] := Privilege;
  Result := NtxAdjustPrivileges(hToken, Privileges, NewAttribute);
end;

function NtxAdjustGroups(hToken: THandle; Sids: TArray<ISid>;
  NewAttribute: Cardinal; ResetToDefault: Boolean): TNtxStatus;
var
  Buffer: PTokenGroups;
begin
  Buffer := NtxpAllocGroups(Sids, NewAttribute);

  Result.Location := 'NtAdjustGroupsToken';
  Result.LastCall.Expects(TOKEN_ADJUST_GROUPS, @TokenAccessType);

  Result.Status := NtAdjustGroupsToken(hToken, ResetToDefault, Buffer, 0, nil,
    nil);
  FreeMem(Buffer);
end;

end.
