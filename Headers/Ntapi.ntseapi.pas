unit Ntapi.ntseapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, NtUtils.Version, DelphiApi.Reflection;

const
  TOKEN_ASSIGN_PRIMARY = $0001;
  TOKEN_DUPLICATE = $0002;
  TOKEN_IMPERSONATE = $0004;
  TOKEN_QUERY = $0008;
  TOKEN_QUERY_SOURCE = $0010;
  TOKEN_ADJUST_PRIVILEGES = $0020;
  TOKEN_ADJUST_GROUPS = $0040;
  TOKEN_ADJUST_DEFAULT = $0080;
  TOKEN_ADJUST_SESSIONID = $0100;

  TOKEN_ALL_ACCESS_P = STANDARD_RIGHTS_REQUIRED  or
    TOKEN_ASSIGN_PRIMARY or TOKEN_DUPLICATE or TOKEN_IMPERSONATE or
    TOKEN_QUERY or TOKEN_QUERY_SOURCE or TOKEN_ADJUST_PRIVILEGES or
    TOKEN_ADJUST_GROUPS or TOKEN_ADJUST_DEFAULT;

  TOKEN_ALL_ACCESS = TOKEN_ALL_ACCESS_P or TOKEN_ADJUST_SESSIONID;

  TokenAccessMapping: array [0..8] of TFlagName = (
    (Value: TOKEN_DUPLICATE;         Name: 'Duplicate'),
    (Value: TOKEN_QUERY;             Name: 'Query'),
    (Value: TOKEN_QUERY_SOURCE;      Name: 'Query source'),
    (Value: TOKEN_IMPERSONATE;       Name: 'Impersonate'),
    (Value: TOKEN_ASSIGN_PRIMARY;    Name: 'Assign primary'),
    (Value: TOKEN_ADJUST_DEFAULT;    Name: 'Adjust defaults'),
    (Value: TOKEN_ADJUST_PRIVILEGES; Name: 'Adjust privileges'),
    (Value: TOKEN_ADJUST_GROUPS;     Name: 'Adjust groups'),
    (Value: TOKEN_ADJUST_SESSIONID;  Name: 'Adjust session ID')
  );

  TokenAccessType: TAccessMaskType = (
    TypeName: 'token';
    FullAccess: TOKEN_ALL_ACCESS;
    Count: Length(TokenAccessMapping);
    Mapping: PFlagNameRefs(@TokenAccessMapping);
  );

  // WinNt.9690
  SE_GROUP_MANDATORY = $00000001;
  SE_GROUP_ENABLED_BY_DEFAULT = $00000002;
  SE_GROUP_ENABLED = $00000004;
  SE_GROUP_OWNER = $00000008;
  SE_GROUP_USE_FOR_DENY_ONLY = $00000010;
  SE_GROUP_INTEGRITY = $00000020;
  SE_GROUP_INTEGRITY_ENABLED = $00000040;
  SE_GROUP_RESOURCE = $20000000;
  SE_GROUP_LOGON_ID = $C0000000;

  // WinNt.10398
  SE_PRIVILEGE_ENABLED_BY_DEFAULT = $00000001;
  SE_PRIVILEGE_ENABLED = $00000002;
  SE_PRIVILEGE_REMOVED = $00000004;
  SE_PRIVILEGE_USED_FOR_ACCESS = Cardinal($80000000);

  // WinNt.10887
  TOKEN_MANDATORY_POLICY_OFF = $0;
  TOKEN_MANDATORY_POLICY_NO_WRITE_UP = $1;
  TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN = $2;

  TokenPolicyNames: array [0..1] of TFlagName = (
    (Value: TOKEN_MANDATORY_POLICY_NO_WRITE_UP; Name: 'No Write-up'),
    (Value: TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN; Name: 'New Process Min')
  );

  // WinNt.10930
  TOKEN_SOURCE_LENGTH = 8;

  // ntifs.15977
  TOKEN_WRITE_RESTRICTED = $0008;
  TOKEN_IS_RESTRICTED = $0010;
  TOKEN_SESSION_NOT_REFERENCED = $0020;
  TOKEN_SANDBOX_INERT = $0040;
  TOKEN_VIRTUALIZE_ALLOWED = $0200;
  TOKEN_VIRTUALIZE_ENABLED = $0400;
  TOKEN_IS_FILTERED = $0800;
  TOKEN_UIACCESS = $1000;
  TOKEN_NOT_LOW = $2000;
  TOKEN_LOWBOX = $4000;
  TOKEN_HAS_OWN_CLAIM_ATTRIBUTES = $8000;
  TOKEN_PRIVATE_NAMESPACE = $10000;
  TOKEN_DO_NOT_USE_GLOBAL_ATTRIBS_FOR_QUERY = $20000;
  TOKEN_NO_CHILD_PROCESS = $80000;
  TOKEN_NO_CHILD_PROCESS_UNLESS_SECURE = $100000;
  TOKEN_AUDIT_NO_CHILD_PROCESS = $200000;

  TokenFlagNames: array [0..15] of TFlagName = (
    (Value: TOKEN_WRITE_RESTRICTED; Name: 'Write-only Restricted'),
    (Value: TOKEN_IS_RESTRICTED; Name: 'Restricted'),
    (Value: TOKEN_SESSION_NOT_REFERENCED; Name: 'Session Not Referenced'),
    (Value: TOKEN_SANDBOX_INERT; Name: 'Sandbox Inert'),
    (Value: TOKEN_VIRTUALIZE_ALLOWED; Name: 'Virtualization Allowed'),
    (Value: TOKEN_VIRTUALIZE_ENABLED; Name: 'Virtualization Enabled'),
    (Value: TOKEN_IS_FILTERED; Name: 'Filtered'),
    (Value: TOKEN_UIACCESS; Name: 'UIAccess'),
    (Value: TOKEN_NOT_LOW; Name: 'Not Low'),
    (Value: TOKEN_LOWBOX; Name: 'Lowbox'),
    (Value: TOKEN_HAS_OWN_CLAIM_ATTRIBUTES; Name: 'Has Own Claim Attributes'),
    (Value: TOKEN_PRIVATE_NAMESPACE; Name: 'Private Namespace'),
    (Value: TOKEN_DO_NOT_USE_GLOBAL_ATTRIBS_FOR_QUERY; Name: 'Don''t Use Global Attributes For Query'),
    (Value: TOKEN_NO_CHILD_PROCESS; Name: 'No Child Process'),
    (Value: TOKEN_NO_CHILD_PROCESS_UNLESS_SECURE; Name: 'No Child Process Unless Secure'),
    (Value: TOKEN_AUDIT_NO_CHILD_PROCESS; Name: 'Audit No Child Process')
  );

  // WinNt.11004
  CLAIM_SECURITY_ATTRIBUTE_TYPE_INVALID = $00;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_INT64 = $01;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_UINT64 = $02;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_STRING = $03;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_FQBN = $04;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_SID = $05;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_BOOLEAN = $06;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_OCTET_STRING = $10;

  // WinNt.11049
  CLAIM_SECURITY_ATTRIBUTE_NON_INHERITABLE = $0001;
  CLAIM_SECURITY_ATTRIBUTE_VALUE_CASE_SENSITIVE = $0002;
  CLAIM_SECURITY_ATTRIBUTE_USE_FOR_DENY_ONLY = $0004;
  CLAIM_SECURITY_ATTRIBUTE_DISABLED_BY_DEFAULT = $0008;
  CLAIM_SECURITY_ATTRIBUTE_DISABLED = $0010;
  CLAIM_SECURITY_ATTRIBUTE_MANDATORY = $0020;
  CLAIM_SECURITY_ATTRIBUTE_CUSTOM_FLAGS = $FFFF0000;

  ClaimAttributeNames: array [0..5] of TFlagName = (
    (Value: CLAIM_SECURITY_ATTRIBUTE_NON_INHERITABLE; Name: 'Non-inheritable'),
    (Value: CLAIM_SECURITY_ATTRIBUTE_VALUE_CASE_SENSITIVE; Name: 'Value Case-sesitive'),
    (Value: CLAIM_SECURITY_ATTRIBUTE_USE_FOR_DENY_ONLY; Name: 'Use For Deny Only'),
    (Value: CLAIM_SECURITY_ATTRIBUTE_DISABLED_BY_DEFAULT; Name: 'Disabled By Default'),
    (Value: CLAIM_SECURITY_ATTRIBUTE_DISABLED; Name: 'Disabled'),
    (Value: CLAIM_SECURITY_ATTRIBUTE_MANDATORY; Name: 'Mandatory')
  );

  // Filtration flags
  DISABLE_MAX_PRIVILEGE = $1;
  SANDBOX_INERT = $2;
  LUA_TOKEN = $4;
  WRITE_RESTRICTED = $8;

  SE_MIN_WELL_KNOWN_PRIVILEGE = 2;
  SE_MAX_WELL_KNOWN_PRIVILEGE = 36;

  // Win 8+
  NtCurrentProcessToken: THandle = THandle(-4);
  NtCurrentThreadToken: THandle = THandle(-5);
  NtCurrentEffectiveToken: THandle = THandle(-6);

type
  {$MINENUMSIZE 1}
  [NamingStyle(nsSnakeCase, 'SE'), Range(2)]
  TSeWellKnownPrivilege = (
    SE_RESERVED_LUID_0 = 0,
    SE_RESERVED_LUID_1 = 1,
    SE_CREATE_TOKEN_PRIVILEGE = 2,
    SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE = 3,
    SE_LOCK_MEMORY_PRIVILEGE = 4,
    SE_INCREASE_QUOTA_PRIVILEGE = 5,
    SE_MACHINE_ACCOUNT_PRIVILEGE = 6,
    SE_TCB_PRIVILEGE = 7,
    SE_SECURITY_PRIVILEGE = 8,
    SE_TAKE_OWNERSHIP_PRIVILEGE = 9,
    SE_LOAD_DRIVER_PRIVILEGE = 10,
    SE_SYSTEM_PROFILE_PRIVILEGE = 11,
    SE_SYSTEMTIME_PRIVILEGE = 12,
    SE_PROFILE_SINGLE_PROCESS_PRIVILEGE = 13,
    SE_INCREASE_BASE_PRIORITY_PRIVILEGE = 14,
    SE_CREATE_PAGEFILE_PRIVILEGE = 15,
    SE_CREATE_PERMANENT_PRIVILEGE = 16,
    SE_BACKUP_PRIVILEGE = 17,
    SE_RESTORE_PRIVILEGE = 18,
    SE_SHUTDOWN_PRIVILEGE = 19,
    SE_DEBUG_PRIVILEGE = 20,
    SE_AUDIT_PRIVILEGE = 21,
    SE_SYSTEM_ENVIRONMENT_PRIVILEGE = 22,
    SE_CHANGE_NOTIFY_PRIVILEGE = 23,
    SE_REMOTE_SHUTDOWN_PRIVILEGE = 24,
    SE_UNDOCK_PRIVILEGE = 25,
    SE_SYNC_AGENT_PRIVILEGE = 26,
    SE_ENABLE_DELEGATION_PRIVILEGE = 27,
    SE_MANAGE_VOLUME_PRIVILEGE = 28,
    SE_IMPERSONATE_PRIVILEGE = 29,
    SE_CREATE_GLOBAL_PRIVILEGE = 30,
    SE_TRUSTED_CREDMAN_ACCESS_PRIVILEGE = 31,
    SE_RELABEL_PRIVILEGE = 32,
    SE_INCREASE_WORKING_SET_PRIVILEGE = 33,
    SE_TIME_ZONE_PRIVILEGE = 34,
    SE_CREATE_SYMBOLIC_LINK_PRIVILEGE = 35,
    SE_DELEGATE_SESSION_USER_IMPERSONATE_PRIVILEGE = 36
  );
  {$MINENUMSIZE 4}

  // WinNt.10661
  [NamingStyle(nsCamelCase, 'Token'), Range(1)]
  TTokenInformationClass = (
    TokenReserved = 0,
    TokenUser = 1,                             // q: TSidAndAttributes
    TokenGroups = 2,                           // q: TTokenGroups
    TokenPrivileges = 3,                       // q: TTokenPrivileges
    TokenOwner = 4,                            // q, s: TTokenOwner
    TokenPrimaryGroup = 5,                     // q, s: TTokenPrimaryGroup
    TokenDefaultDacl = 6,                      // q, s: TTokenDefaultDacl
    TokenSource = 7,                           // q: TTokenSource
    TokenType = 8,                             // q: TTokenType
    TokenImpersonationLevel = 9,               // q: TSecurityImpersonationLevel
    TokenStatistics = 10,                      // q: TTokenStatistics
    TokenRestrictedSids = 11,                  // q: TTokenGroups
    TokenSessionId = 12,                       // q, s: Cardinal
    TokenGroupsAndPrivileges = 13,             // q: TTokenGroupsAndPrivileges
    TokenSessionReference = 14,                // s: LongBool
    TokenSandBoxInert = 15,                    // q: LongBool
    TokenAuditPolicy = 16,                     // q, s: TTokenAuditPolicy
    TokenOrigin = 17,                          // q, s: TLuid
    TokenElevationType = 18,                   // q: TTokenElevationType
    TokenLinkedToken = 19,                     // q, s: THandle
    TokenElevation = 20,                       // q: LongBool
    TokenHasRestrictions = 21,                 // q: LongBool
    TokenAccessInformation = 22,               // q: TTokenAccessInformation
    TokenVirtualizationAllowed = 23,           // q, s: LongBool
    TokenVirtualizationEnabled = 24,           // q, s: LongBool
    TokenIntegrityLevel = 25,                  // q, s: TSidAndAttributes
    TokenUIAccess = 26,                        // q, s: LongBool
    TokenMandatoryPolicy = 27,                 // q, s: TTokenMandatoryPolicy
    TokenLogonSid = 28,                        // q: TTokenGroups
    TokenIsAppContainer = 29,                  // q: LongBool
    TokenCapabilities = 30,                    // q: TTokenGroups
    TokenAppContainerSid = 31,                 // q: TTokenAppContainer
    TokenAppContainerNumber = 32,              // q: Cardinal
    TokenUserClaimAttributes = 33,             // q: TClaimSecurityAttributes
    TokenDeviceClaimAttributes = 34,           // q: TClaimSecurityAttributes
    TokenRestrictedUserClaimAttributes = 35,   // q:
    TokenRestrictedDeviceClaimAttributes = 36, // q:
    TokenDeviceGroups = 37,                    // q: TTokenGroups
    TokenRestrictedDeviceGroups = 38,          // q: TTokenGroups
    TokenSecurityAttributes = 39,              // q, s:
    TokenIsRestricted = 40,                    // q: LongBool
    TokenProcessTrustLevel = 41,               // q:
    TokenPrivateNameSpace = 42,                // q, s: LongBool
    TokenSingletonAttributes = 43,             // q:
    TokenBnoIsolation = 44,                    // q:
    TokenChildProcessFlags = 45,               // q, s: LongBool
    TokenIsLessPrivilegedAppContainer = 46     // q:
  );

  // WinNt.10729
  [NamingStyle(nsCamelCase, 'Token'), Range(1)]
  TTokenType = (
    TokenInvalid = 0,
    TokenPrimary = 1,
    TokenImpersonation = 2
  );

  // WinNt.10731
  [NamingStyle(nsCamelCase, 'TokenElevation'), Range(1)]
  TTokenElevationType = (
    TokenElevationInvalid = 0,
    TokenElevationTypeDefault = 1,
    TokenElevationTypeFull = 2,
    TokenElevationTypeLimited = 3
  );

  // WinNt.10822
  TTokenGroups = record
    GroupCount: Integer;
    Groups: array [ANYSIZE_ARRAY] of TSIDAndAttributes;
  end;
  PTokenGroups = ^TTokenGroups;

  // WinNt.10831
  TTokenPrivileges = record
    PrivilegeCount: Integer;
    Privileges: array [ANYSIZE_ARRAY] of TLUIDAndAttributes;
  end;
  PTokenPrivileges = ^TTokenPrivileges;

  // WinNt.10837
  TTokenOwner = record
    Owner: PSid;
  end;
  PTokenOwner = ^TTokenOwner;

  // WinNt.10846
  TTokenPrimaryGroup = record
    PrimaryGroup: PSid;
  end;
  PTokenPrimaryGroup = ^TTokenPrimaryGroup;

  // WinNt.10850
  TTokenDefaultDacl = record
    DefaultDacl: PAcl;
  end;
  PTokenDefaultDacl = ^TTokenDefaultDacl;

  // WinNt.10862
  TTokenGroupsAndPrivileges = record
    SidCount: Cardinal;
    [Bytes] SidLength: Cardinal;
    Sids: PSidAndAttributes;
    RestrictedSidCount: Cardinal;
    [Bytes] RestrictedSidLength: Cardinal;
    RestrictedSids: PSidAndAttributes;
    PrivilegeCount: Cardinal;
    [Bytes] PrivilegeLength: Cardinal;
    Privileges: PLuidAndAttributes;
    AuthenticationId: TLogonId;
  end;
  PTokenGroupsAndPrivileges = ^TTokenGroupsAndPrivileges;

  TTokenPolicyNameProvider = class (TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

  // WinNt.10898
  [Bitwise(TTokenPolicyNameProvider)]
  TTokenMandatoryPolicy = type Cardinal;

  TTokenFlagNameProvider = class (TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

  // WinNt.10904
  TTokenAccessInformation = record
    SidHash: PSIDAndAttributesHash;
    RestrictedSidHash: PSIDAndAttributesHash;
    Privileges: PTokenPrivileges;
    AuthenticationId: TLogonId;
    TokenType: TTokenType;
    ImpersonationLevel: TSecurityImpersonationLevel;
    [Bitwise(TTokenPolicyNameProvider)] MandatoryPolicy: Cardinal;
    [Bitwise(TTokenFlagNameProvider)] Flags: Cardinal;
    [MinOSVersion(OsWin8)] AppContainerNumber: Cardinal;
    [MinOSVersion(OsWin8)] PackageSid: PSid;
    [MinOSVersion(OsWin8)] CapabilitiesHash: PSIDAndAttributesHash;
    [MinOSVersion(OsWin81)] TrustLevelSid: PSid;
    [MinOSVersion(OsWin10TH1)] SecurityAttributes: Pointer;
  end;
  PTokenAccessInformation = ^TTokenAccessInformation;

  // WinNt.10926
  TTokenAuditPolicy = record
    // The actual length depends on the count of SubCategories of auditing.
    // Each half of a byte is a set of Winapi.NtSecApi.PER_USER_AUDIT_* flags.
    PerUserPolicy: array [ANYSIZE_ARRAY] of Byte;
  end;
  PTokenAuditPolicy = ^TTokenAuditPolicy;

  TTokenSourceName = array[1 .. TOKEN_SOURCE_LENGTH] of AnsiChar;

  // WinNt.10932
  TTokenSource = record
    SourceName: TTokenSourceName;
    SourceIdentifier: TLuid;
    procedure FromString(Name: String);
    function ToString: String;
  end;
  PTokenSource = ^TTokenSource;

  // WinNt.10938
  TTokenStatistics = record
    TokenId: TLuid;
    AuthenticationId: TLuid;
    ExpirationTime: TLargeInteger;
    TokenType: TTokenType;
    ImpersonationLevel: TSecurityImpersonationLevel;
    [Bytes] DynamicCharged: Cardinal;
    [Bytes] DynamicAvailable: Cardinal;
    GroupCount: Cardinal;
    PrivilegeCount: Cardinal;
    ModifiedId: TLuid;
  end;
  PTokenStatistics = ^TTokenStatistics;

  // WinNt.10975
  TTokenAppContainer = record
    TokenAppContainer: PSid;
  end;
  PTokenAppContainer = ^TTokenAppContainer;

  TClaimAttributeNameProvider = class(TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

  // WinNt.11105
  TClaimSecurityAttributeV1 = record
    Name: PWideChar;
    ValueType: Word;
    Reserved: Word;
    [Bitwise(TClaimAttributeNameProvider)] Flags: Cardinal;
    ValueCount: Integer;
    Values: Pointer;
  end;
  PClaimSecurityAttributeV1 = ^TClaimSecurityAttributeV1;

  // WinNt.11224
  TClaimSecurityAttributes = record
    Version: Word;
    [Unlisted] Reserved: Word;
    AttributeCount: Cardinal;
    Attribute: PClaimSecurityAttributeV1;
  end;
  PClaimSecurityAttributes = ^TClaimSecurityAttributes;

function NtCreateToken(out TokenHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; TokenType: TTokenType;
  var AuthenticationId: TLuid; var ExpirationTime: TLargeInteger;
  const User: TSidAndAttributes; Groups: PTokenGroups;
  Privileges: PTokenPrivileges; Owner: PTokenOwner;
  var PrimaryGroup: TTokenPrimaryGroup; DefaultDacl: PTokenDefaultDacl;
  const Source: TTokenSource): NTSTATUS; stdcall; external ntdll;

// Win 8+
function NtCreateLowBoxToken(out TokenHandle: THandle;
  ExistingTokenHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; PackageSid: PSID;
  CapabilityCount: Cardinal; Capabilities: TArray<TSidAndAttributes>;
  HandleCount: Cardinal; Handles: TArray<THandle>): NTSTATUS; stdcall;
  external ntdll delayed;

function NtOpenProcessTokenEx(ProcessHandle: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal;
  out TokenHandle: THandle): NTSTATUS; stdcall; external ntdll;

function NtOpenThreadTokenEx(ThreadHandle: THandle;
  DesiredAccess: TAccessMask; OpenAsSelf: Boolean; HandleAttributes: Cardinal;
  out TokenHandle: THandle): NTSTATUS; stdcall; external ntdll;

function NtDuplicateToken(ExistingTokenHandle: THandle;
  DesiredAccess: TAccessMask; ObjectAttributes: PObjectAttributes;
  EffectiveOnly: LongBool; TokenType: TTokenType; out NewTokenHandle: THandle)
  : NTSTATUS; stdcall; external ntdll;

function NtQueryInformationToken(TokenHandle: THandle;
  TokenInformationClass: TTokenInformationClass; TokenInformation: Pointer;
  TokenInformationLength: Cardinal; out ReturnLength: Cardinal): NTSTATUS;
  stdcall; external ntdll;

function NtSetInformationToken(TokenHandle: THandle;
  TokenInformationClass: TTokenInformationClass;
  TokenInformation: Pointer; TokenInformationLength: Cardinal): NTSTATUS;
  stdcall; external ntdll;

function NtAdjustPrivilegesToken(TokenHandle: THandle;
  DisableAllPrivileges: Boolean; NewState: PTokenPrivileges;
  BufferLength: Cardinal; PreviousState: PTokenPrivileges;
  ReturnLength: PCardinal): NTSTATUS; stdcall; external ntdll;

function NtAdjustGroupsToken(TokenHandle: THandle; ResetToDefault: Boolean;
  NewState: PTokenGroups; BufferLength: Cardinal; PreviousState:
  PTokenPrivileges; ReturnLength: PCardinal): NTSTATUS; stdcall; external ntdll;

function NtFilterToken(ExistingTokenHandle: THandle; Flags: Cardinal;
  SidsToDisable: PTokenGroups; PrivilegesToDelete: PTokenPrivileges;
  RestrictedSids: PTokenGroups; out NewTokenHandle: THandle): NTSTATUS;
  stdcall; external ntdll;

function NtCompareTokens(FirstTokenHandle: THandle; SecondTokenHandle: THandle;
  out Equal: LongBool): NTSTATUS; stdcall; external ntdll;

function NtImpersonateAnonymousToken(ThreadHandle: THandle): NTSTATUS;
  stdcall; external ntdll;

implementation

class function TTokenPolicyNameProvider.Flags: TFlagNames;
begin
  Result := Capture(TokenPolicyNames);
end;

class function TTokenFlagNameProvider.Flags: TFlagNames;
begin
  Result := Capture(TokenFlagNames);
end;

class function TClaimAttributeNameProvider.Flags: TFlagNames;
begin
  Result := Capture(ClaimAttributeNames);
end;

{ TTokenSource }

procedure TTokenSource.FromString(Name: String);
var
  i, Count: integer;
begin
  FillChar(sourcename, SizeOf(sourcename), 0);

  Count := Length(Name);
  if Count > 8 then
    Count := 8;

  for i := 1 to Count do
    sourcename[i] := AnsiChar(Name[Low(String) + i - 1]);
end;

function TTokenSource.ToString: String;
begin
  // sourcename field may or may not contain a zero-termination byte
  Result := String(PAnsiChar(AnsiString(sourcename)));
end;

end.
