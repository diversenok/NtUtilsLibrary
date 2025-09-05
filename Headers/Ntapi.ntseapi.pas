unit Ntapi.ntseapi;

{
  This file provides definitions for working with access tokens and security
  contexts via Native API.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.Versions, DelphiApi.Reflection,
  DelphiApi.DelayLoad;

const
  // SDK::winnt.h - token access masks
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

  // SDK::winnt.h - group states
  SE_GROUP_DISABLED = $00000000;
  SE_GROUP_MANDATORY = $00000001;
  SE_GROUP_ENABLED_BY_DEFAULT = $00000002;
  SE_GROUP_ENABLED = $00000004;
  SE_GROUP_OWNER = $00000008;
  SE_GROUP_USE_FOR_DENY_ONLY = $00000010;
  SE_GROUP_INTEGRITY = $00000020;
  SE_GROUP_INTEGRITY_ENABLED = $00000040;
  SE_GROUP_RESOURCE = $20000000;
  SE_GROUP_LOGON_ID = $C0000000;

  SE_GROUP_STATE_MASK = SE_GROUP_ENABLED_BY_DEFAULT or SE_GROUP_ENABLED or
    SE_GROUP_INTEGRITY_ENABLED;

  // SDK::winnt.h - privilege states
  SE_PRIVILEGE_DISABLED = $00000000;
  SE_PRIVILEGE_ENABLED_BY_DEFAULT = $00000001;
  SE_PRIVILEGE_ENABLED = $00000002;
  SE_PRIVILEGE_REMOVED = $00000004;
  SE_PRIVILEGE_USED_FOR_ACCESS = Cardinal($80000000);

  SE_PRIVILEGE_STATE_MASK = SE_PRIVILEGE_ENABLED_BY_DEFAULT or
    SE_PRIVILEGE_ENABLED;

  // SDK::winnt.h - mandatory policy
  TOKEN_MANDATORY_POLICY_OFF = $0;
  TOKEN_MANDATORY_POLICY_NO_WRITE_UP = $1;
  TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN = $2;
  TOKEN_MANDATORY_POLICY_ALL = TOKEN_MANDATORY_POLICY_NO_WRITE_UP or
    TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN;

  // SDK::winnt.h
  TOKEN_SOURCE_LENGTH = 8;

  // WDK::ntifs.h - token flags
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
  TOKEN_PERMISSIVE_LEARNING_MODE = $400000;
  TOKEN_ENFORCE_REDIRECTION_TRUST = $800000;
  TOKEN_AUDIT_REDIRECTION_TRUST = $1000000;

  // SDK::winnt.h
  SECURITY_ATTRIBUTES_INFORMATION_VERSION_V1 = 1;

  // SDK::winnt.h - attribute flags
  SECURITY_ATTRIBUTE_NON_INHERITABLE = $0001;
  SECURITY_ATTRIBUTE_VALUE_CASE_SENSITIVE = $0002;
  SECURITY_ATTRIBUTE_USE_FOR_DENY_ONLY = $0004;
  SECURITY_ATTRIBUTE_DISABLED_BY_DEFAULT = $0008;
  SECURITY_ATTRIBUTE_DISABLED = $0010;
  SECURITY_ATTRIBUTE_MANDATORY = $0020;
  SECURITY_ATTRIBUTE_COMPARE_IGNORE = $0040;
  SECURITY_ATTRIBUTE_CUSTOM_FLAGS = $FFFF0000;
  SECURITY_ATTRIBUTE_STATE_MASK = SECURITY_ATTRIBUTE_DISABLED_BY_DEFAULT or
    SECURITY_ATTRIBUTE_DISABLED;

  // SDK::winnt.h - token filtration options
  DISABLE_MAX_PRIVILEGE = $1;
  SANDBOX_INERT = $2;
  LUA_TOKEN = $4;
  WRITE_RESTRICTED = $8;

  // rev - see PsAttributeSafeOpenPromptOriginClaim
  SE_ORIGIN_CLAIM_ATTRIBUTE_NAME = 'SMARTLOCKER://SMARTSCREENORIGINCLAIM';

  // Win 8+ pseudo-handles (query only)
  NtCurrentProcessToken = THandle(-4);
  NtCurrentThreadToken = THandle(-5);
  NtCurrentEffectiveToken = THandle(-6);

type
  [FriendlyName('token'), ValidMask(TOKEN_ALL_ACCESS)]
  [SubEnum(TOKEN_ALL_ACCESS, TOKEN_ALL_ACCESS, 'Full Access')]
  [FlagName(TOKEN_DUPLICATE, 'Duplicate')]
  [FlagName(TOKEN_QUERY, 'Query')]
  [FlagName(TOKEN_QUERY_SOURCE, 'Query Source')]
  [FlagName(TOKEN_IMPERSONATE, 'Impersonate')]
  [FlagName(TOKEN_ASSIGN_PRIMARY, 'Assign Primary')]
  [FlagName(TOKEN_ADJUST_DEFAULT, 'Adjust Defaults')]
  [FlagName(TOKEN_ADJUST_PRIVILEGES, 'Adjust Privileges')]
  [FlagName(TOKEN_ADJUST_GROUPS, 'Adjust Groups')]
  [FlagName(TOKEN_ADJUST_SESSIONID, 'Adjust Session ID')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TTokenAccessMask = type TAccessMask;

  [FlagName(DISABLE_MAX_PRIVILEGE, 'Disable Max Privileges')]
  [FlagName(SANDBOX_INERT, 'Sandbox Inert')]
  [FlagName(LUA_TOKEN, 'LUA Token')]
  [FlagName(WRITE_RESTRICTED, 'Write-only Restricted')]
  TTokenFilterFlags = type Cardinal;

  // WDK::wdm.h
  [NamingStyle(nsSnakeCase, 'SE'), MinValue(2)]
  TSeWellKnownPrivilege = (
    [Reserved] SE_RESERVED_LUID_0 = 0,
    [Reserved] SE_RESERVED_LUID_1 = 1,
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
    SE_TRUSTED_CRED_MAN_ACCESS_PRIVILEGE = 31,
    SE_RELABEL_PRIVILEGE = 32,
    SE_INCREASE_WORKING_SET_PRIVILEGE = 33,
    SE_TIME_ZONE_PRIVILEGE = 34,
    SE_CREATE_SYMBOLIC_LINK_PRIVILEGE = 35,
    SE_DELEGATE_SESSION_USER_IMPERSONATE_PRIVILEGE = 36
  );

  [FlagName(SE_PRIVILEGE_ENABLED_BY_DEFAULT, 'Enabled by Default')]
  [FlagName(SE_PRIVILEGE_ENABLED, 'Enabled')]
  [FlagName(SE_PRIVILEGE_REMOVED, 'Removed')]
  [FlagName(SE_PRIVILEGE_USED_FOR_ACCESS, 'Used For Access')]
  [FlagGroup(SE_PRIVILEGE_STATE_MASK, 'State')]
  [FlagGroup(MAX_UINT and not SE_PRIVILEGE_STATE_MASK, 'Flags')]
  TPrivilegeAttributes = type Cardinal;

  [InheritsFrom(System.TypeInfo(TPrivilegeAttributes))]
  [SubEnum(SE_PRIVILEGE_STATE_MASK, SE_PRIVILEGE_DISABLED, 'Disabled')]
  [SubEnum(SE_PRIVILEGE_STATE_MASK, SE_PRIVILEGE_ENABLED_BY_DEFAULT, 'Disabled (modified)')]
  [SubEnum(SE_PRIVILEGE_STATE_MASK, SE_PRIVILEGE_ENABLED, 'Enabled (modified)')]
  [SubEnum(SE_PRIVILEGE_STATE_MASK, SE_PRIVILEGE_STATE_MASK, 'Enabled')]
  TPrivilegeAttributesState = type TPrivilegeAttributes;

  TPrivilegeId = type TLuid;

  TRequiredPrivilegeMode = (
    rpAlways,                  // The function fails without the privilege
    rpWithExceptions,          // Mostly necessary, but there are exceptions
    rpSometimes,               // Required under some specific conditions
    rpForBypassingChecks,      // Required if normal access checks deny access
    rpForExtendedFunctionality // The privilege unlocks additional functionality
  );

  // An attribute to mark functions as requiring a specific privilege
  RequiredPrivilegeAttribute = class(TCustomAttribute)
    Privilege: TSeWellKnownPrivilege;
    Mode: TRequiredPrivilegeMode;
    constructor Create(
      Privilege: TSeWellKnownPrivilege;
      Mode: TRequiredPrivilegeMode
    );
  end;

  // An attribute for decorating functions that require admin permissions
  RequiresAdmin = class(TCustomAttribute)
  end;

  // SDK::winnt.h
  [SDKName('LUID_AND_ATTRIBUTES')]
  TLuidAndAttributes = packed record
    Luid: TPrivilegeId;
    Attributes: TPrivilegeAttributes;
  end;
  PLuidAndAttributes = ^TLuidAndAttributes;

  TPrivilege = TLuidAndAttributes;
  PPrivilege = PLuidAndAttributes;

  [FlagName(SE_GROUP_MANDATORY, 'Mandatory')]
  [FlagName(SE_GROUP_ENABLED_BY_DEFAULT, 'Enabled by Default')]
  [FlagName(SE_GROUP_ENABLED, 'Enabled')]
  [FlagName(SE_GROUP_OWNER, 'Owner')]
  [FlagName(SE_GROUP_USE_FOR_DENY_ONLY, 'Use For Deny Only')]
  [FlagName(SE_GROUP_INTEGRITY, 'Integrity')]
  [FlagName(SE_GROUP_INTEGRITY_ENABLED, 'Integrity Enabled')]
  [FlagName(SE_GROUP_RESOURCE, 'Resource')]
  [FlagName(SE_GROUP_LOGON_ID, 'Logon ID')]
  [FlagGroup(SE_GROUP_STATE_MASK, 'State')]
  [FlagGroup(MAX_UINT and not SE_GROUP_STATE_MASK, 'Flags')]
  TGroupAttributes = type Cardinal;

  [InheritsFrom(System.TypeInfo(TGroupAttributes))]
  [SubEnum(SE_GROUP_STATE_MASK, 0, 'Disabled')]
  [SubEnum(SE_GROUP_STATE_MASK, SE_GROUP_ENABLED_BY_DEFAULT, 'Disabled (modified)')]
  [SubEnum(SE_GROUP_STATE_MASK, SE_GROUP_ENABLED, 'Enabled (modified)')]
  [SubEnum(SE_GROUP_STATE_MASK, SE_GROUP_ENABLED_BY_DEFAULT or SE_GROUP_ENABLED, 'Enabled')]
  [SubEnum(SE_GROUP_STATE_MASK, SE_GROUP_INTEGRITY_ENABLED, 'Integrity Enabled')]
  [SubEnum(SE_GROUP_STATE_MASK, SE_GROUP_INTEGRITY_ENABLED or SE_GROUP_ENABLED_BY_DEFAULT, 'Integrity Enabled, Group Disabled (modified)')]
  [SubEnum(SE_GROUP_STATE_MASK, SE_GROUP_INTEGRITY_ENABLED or SE_GROUP_ENABLED, 'Integrity Enabled, Group Enabled (modified)')]
  [SubEnum(SE_GROUP_STATE_MASK, SE_GROUP_STATE_MASK, 'Integrity Enabled, Group Enabled')]
  TGroupAttributesState = type TGroupAttributes;

  // SDK::winnt.h
  [SDKName('SID_AND_ATTRIBUTES')]
  TSidAndAttributes = record
    SID: PSid;
    Attributes: TGroupAttributes;
  end;
  PSidAndAttributes = ^TSidAndAttributes;

  TSidAndAttributesArray = TAnysizeArray<TSidAndAttributes>;
  PSidAndAttributesArray = ^TSidAndAttributesArray;

  // SDK::winnt.h
  [SDKName('SID_AND_ATTRIBUTES_HASH')]
  TSidAndAttributesHash = record
    const SID_HASH_SIZE = 32;
  var
    SidCount: Cardinal;
    SidAttr: PSIDAndAttributes;
    Hash: array [0 .. SID_HASH_SIZE - 1] of NativeUInt;
  end;
  PSidAndAttributesHash = ^TSidAndAttributesHash;

  // SDK::winnt.h
  [SDKName('PRIVILEGE_SET')]
  TPrivilegeSet = record
    [Counter] PrivilegeCount: Cardinal;
    [Hex] Control: Cardinal;
    Privilege: TAnysizeArray<TLuidAndAttributes>;
  end;
  PPrivilegeSet = ^TPrivilegeSet;

  // SDK::winnt.h
  [SDKName('TOKEN_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Token'), MinValue(1)]
  TTokenInformationClass = (
    [Reserved] TokenReserved = 0,
    TokenUser = 1,                             // q: TSidAndAttributes
    TokenGroups = 2,                           // q: TTokenGroups
    TokenPrivileges = 3,                       // q: TTokenPrivileges
    TokenOwner = 4,                            // q, s: TTokenSidInformation
    TokenPrimaryGroup = 5,                     // q, s: TTokenSidInformation
    TokenDefaultDacl = 6,                      // q, s: TTokenDefaultDacl
    TokenSource = 7,                           // q: TTokenSource
    TokenType = 8,                             // q: TTokenType
    TokenImpersonationLevel = 9,               // q: TSecurityImpersonationLevel
    TokenStatistics = 10,                      // q: TTokenStatistics
    TokenRestrictedSids = 11,                  // q: TTokenGroups
    TokenSessionId = 12,                       // q, s: TSessionId
    TokenGroupsAndPrivileges = 13,             // q: TTokenGroupsAndPrivileges
    TokenSessionReference = 14,                // s: LongBool
    TokenSandBoxInert = 15,                    // q: LongBool
    TokenAuditPolicy = 16,                     // q, s: TTokenAuditPolicy
    TokenOrigin = 17,                          // q, s: TLogonId
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
    TokenIsAppContainer = 29,                  // q: LongBool, Win 8+
    TokenCapabilities = 30,                    // q: TTokenGroups
    TokenAppContainerSid = 31,                 // q: TTokenSidInformation
    TokenAppContainerNumber = 32,              // q: Cardinal
    TokenUserClaimAttributes = 33,             // q: TClaimSecurityAttributes
    TokenDeviceClaimAttributes = 34,           // q: TClaimSecurityAttributes
    TokenRestrictedUserClaimAttributes = 35,   // q: TClaimSecurityAttributes
    TokenRestrictedDeviceClaimAttributes = 36, // q: TClaimSecurityAttributes
    TokenDeviceGroups = 37,                    // q: TTokenGroups
    TokenRestrictedDeviceGroups = 38,          // q: TTokenGroups
    TokenSecurityAttributes = 39,              // q, s: TTokenSecurityAttributes[AndOperation]
    TokenIsRestricted = 40,                    // q: LongBool
    TokenProcessTrustLevel = 41,               // q: TTokenSidInformation, Win 8.1+
    TokenPrivateNameSpace = 42,                // q, s: LongBool, Win 10 TH1+
    TokenSingletonAttributes = 43,             // q: TTokenSecurityAttributes, Win 10 RS1+
    TokenBnoIsolation = 44,                    // q: TTokenBnoIsolationInformation, Win 10 RS2+
    TokenChildProcessFlags = 45,               // s: LongBool, Win 10 RS3+
    TokenIsLessPrivilegedAppContainer = 46,    // q: LongBool, Win 10 RS5+
    TokenIsSandboxed = 47,                     // q: LongBool, Win 10 19H1+
    TokenIsAppSilo = 48                        // q: LongBool, Win 11 22H2+
  );

  // SDK::winnt.h
  [SDKName('TOKEN_TYPE')]
  [NamingStyle(nsCamelCase, 'Token'), MinValue(1)]
  TTokenType = (
    [Reserved] TokenInvalid = 0,
    TokenPrimary = 1,
    TokenImpersonation = 2
  );

  // SDK::winnt.h
  [SDKName('TOKEN_ELEVATION_TYPE')]
  [NamingStyle(nsCamelCase, 'TokenElevationType'), MinValue(1)]
  TTokenElevationType = (
    [Reserved] TokenElevationInvalid = 0,
    TokenElevationTypeDefault = 1,
    TokenElevationTypeFull = 2,
    TokenElevationTypeLimited = 3
  );

  // SDK::winnt.h
  [SDKName('TOKEN_GROUPS')]
  TTokenGroups = record
    [Counter] GroupCount: Integer;
    Groups: TAnysizeArray<TSIDAndAttributes>;
  end;
  PTokenGroups = ^TTokenGroups;

  // SDK::winnt.h
  [SDKName('TOKEN_PRIVILEGES')]
  TTokenPrivileges = record
    [Counter] PrivilegeCount: Integer;
    Privileges: TAnysizeArray<TLuidAndAttributes>;
  end;
  PTokenPrivileges = ^TTokenPrivileges;

  // SDK::winnt.h
  [SDKName('TOKEN_SID_INFORMATION')]
  TTokenSidInformation = record
    Sid: PSid;
  end;
  PTokenSidInformation = ^TTokenSidInformation;

  // SDK::winnt.h
  [SDKName('TOKEN_DEFAULT_DACL')]
  TTokenDefaultDacl = record
    DefaultDacl: PAcl;
  end;
  PTokenDefaultDacl = ^TTokenDefaultDacl;

  // SDK::winnt.h
  [SDKName('TOKEN_GROUPS_AND_PRIVILEGES')]
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

  // SDK::winnt.h
  [SDKName('TOKEN_MANDATORY_POLICY')]
  [FlagName(TOKEN_MANDATORY_POLICY_NO_WRITE_UP, 'No Write Up')]
  [FlagName(TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN, 'New Process Min')]
  TTokenMandatoryPolicy = type Cardinal;

  [FlagName(TOKEN_WRITE_RESTRICTED, 'Write-only Restricted')]
  [FlagName(TOKEN_IS_RESTRICTED, 'Restricted')]
  [FlagName(TOKEN_SESSION_NOT_REFERENCED, 'Session Not Referenced')]
  [FlagName(TOKEN_SANDBOX_INERT, 'Sandbox Inert')]
  [FlagName(TOKEN_VIRTUALIZE_ALLOWED, 'Virtualization Allowed')]
  [FlagName(TOKEN_VIRTUALIZE_ENABLED, 'Virtualization Enabled')]
  [FlagName(TOKEN_IS_FILTERED, 'Filtered')]
  [FlagName(TOKEN_UIACCESS, 'UIAccess')]
  [FlagName(TOKEN_NOT_LOW, 'Not Low')]
  [FlagName(TOKEN_LOWBOX, 'Lowbox (AppContainer)')]
  [FlagName(TOKEN_HAS_OWN_CLAIM_ATTRIBUTES, 'Has Own Claims')]
  [FlagName(TOKEN_PRIVATE_NAMESPACE, 'Private Namespace')]
  [FlagName(TOKEN_DO_NOT_USE_GLOBAL_ATTRIBS_FOR_QUERY, 'Don''t Use Global Attributes For Query')]
  [FlagName(TOKEN_NO_CHILD_PROCESS, 'No Child Process')]
  [FlagName(TOKEN_NO_CHILD_PROCESS_UNLESS_SECURE, 'No Child Process Unless Secure')]
  [FlagName(TOKEN_AUDIT_NO_CHILD_PROCESS, 'Audit No Child Process')]
  [FlagName(TOKEN_PERMISSIVE_LEARNING_MODE, 'Permissive Learning Mode')]
  [FlagName(TOKEN_ENFORCE_REDIRECTION_TRUST, 'Enforce Redirection Trust')]
  [FlagName(TOKEN_AUDIT_REDIRECTION_TRUST, 'Audit Redirection Trust')]
  TTokenFlags = type Cardinal;

  // SDK::winnt.h
  [SDKName('TOKEN_ACCESS_INFORMATION')]
  TTokenAccessInformation = record
    SidHash: PSIDAndAttributesHash;
    RestrictedSidHash: PSIDAndAttributesHash;
    Privileges: PTokenPrivileges;
    AuthenticationId: TLogonId;
    TokenType: TTokenType;
    ImpersonationLevel: TSecurityImpersonationLevel;
    MandatoryPolicy: TTokenMandatoryPolicy;
    Flags: TTokenFlags;
    [MinOSVersion(OsWin8)] AppContainerNumber: Cardinal;
    [MinOSVersion(OsWin8)] PackageSid: PSid;
    [MinOSVersion(OsWin8)] CapabilitiesHash: PSIDAndAttributesHash;
    [MinOSVersion(OsWin81)] TrustLevelSid: PSid;
    [MinOSVersion(OsWin10TH1)] SecurityAttributes: Pointer;
  end;
  PTokenAccessInformation = ^TTokenAccessInformation;

  [SubEnum(MAX_UINT, SECURITY_MANDATORY_UNTRUSTED_RID, 'Untrusted')]
  [SubEnum(MAX_UINT, SECURITY_MANDATORY_LOW_RID, 'Low')]
  [SubEnum(MAX_UINT, SECURITY_MANDATORY_MEDIUM_RID, 'Medium')]
  [SubEnum(MAX_UINT, SECURITY_MANDATORY_MEDIUM_PLUS_RID, 'Medium +')]
  [SubEnum(MAX_UINT, SECURITY_MANDATORY_HIGH_RID, 'High')]
  [SubEnum(MAX_UINT, SECURITY_MANDATORY_SYSTEM_RID, 'System')]
  [SubEnum(MAX_UINT, SECURITY_MANDATORY_PROTECTED_PROCESS_RID, 'Protected')]
  [Hex(4)] TIntegrityRid = type Cardinal;

  // SDK::winnt.h
  [SDKName('TOKEN_AUDIT_POLICY')]
  TTokenAuditPolicy = record
    // The actual length depends on the count of SubCategories of auditing.
    // Each half of a byte is a set of Ntapi.NtSecApi.PER_USER_AUDIT_* flags.
    PerUserPolicy: TAnysizeArray<Byte>;
  end;
  PTokenAuditPolicy = ^TTokenAuditPolicy;

  TTokenSourceName = array[1 .. TOKEN_SOURCE_LENGTH] of AnsiChar;

  // SDK::winnt.h
  [SDKName('TOKEN_SOURCE')]
  TTokenSource = record
  private
    procedure SetName(const Value: String);
    function GetName: String;
  public
    SourceName: TTokenSourceName;
    SourceIdentifier: TLuid;
    property Name: String read GetName write SetName;
    class function New(Name: String = 'NtUtils'): TTokenSource; static;
  end;
  PTokenSource = ^TTokenSource;

  // SDK::winnt.h
  [SDKName('TOKEN_STATISTICS')]
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

  // SDK::winnt.h
  [SDKName('CLAIM_SECURITY_ATTRIBUTE_FQBN_VALUE')]
  TClaimSecurityAttributeFqbnValue = record
    Version: UInt64;
    Name: PWideChar;
  end;
  PClaimSecurityAttributeFqbnValue = ^TClaimSecurityAttributeFqbnValue;

  // SDK::winnt.h
  [SDKName('CLAIM_SECURITY_ATTRIBUTE_OCTET_STRING_VALUE')]
  TClaimSecurityAttributeOctetStringValue = record
    pValue: Pointer;
    [Bytes] ValueLength: Cardinal;
  end;
  PClaimSecurityAttributeOctetStringValue = ^TClaimSecurityAttributeOctetStringValue;

  // SDK::winnt.h
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'SECURITY_ATTRIBUTE_TYPE'), ValidValues([1..6, 16])]
  TSecurityAttributeType = (
    [Reserved] SECURITY_ATTRIBUTE_TYPE_INVALID = 0,
    SECURITY_ATTRIBUTE_TYPE_INT64 = 1,
    SECURITY_ATTRIBUTE_TYPE_UINT64 = 2,
    SECURITY_ATTRIBUTE_TYPE_STRING = 3,
    SECURITY_ATTRIBUTE_TYPE_FQBN = 4,
    SECURITY_ATTRIBUTE_TYPE_SID = 5,
    SECURITY_ATTRIBUTE_TYPE_BOOLEAN = 6,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_7,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_8,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_9,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_10,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_11,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_12,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_13,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_14,
    [Reserved] SECURITY_ATTRIBUTE_TYPE_15,
    SECURITY_ATTRIBUTE_TYPE_OCTET_STRING = 16
  );
  {$MINENUMSIZE 4}

  [FlagName(SECURITY_ATTRIBUTE_NON_INHERITABLE, 'Non-inheritable')]
  [FlagName(SECURITY_ATTRIBUTE_VALUE_CASE_SENSITIVE, 'Value Case-sensitive')]
  [FlagName(SECURITY_ATTRIBUTE_USE_FOR_DENY_ONLY, 'Use For Deny Only')]
  [FlagName(SECURITY_ATTRIBUTE_MANDATORY, 'Mandatory')]
  [FlagName(SECURITY_ATTRIBUTE_COMPARE_IGNORE, 'Compare-ignore')]
  [FlagGroup(SECURITY_ATTRIBUTE_STATE_MASK, 'State')]
  [FlagGroup(MAX_UINT and not SECURITY_ATTRIBUTE_STATE_MASK, 'Flags')]
  [SubEnum(SECURITY_ATTRIBUTE_STATE_MASK, 0, 'Enabled')]
  [SubEnum(SECURITY_ATTRIBUTE_STATE_MASK, SECURITY_ATTRIBUTE_DISABLED_BY_DEFAULT, 'Enabled (modified)')]
  [SubEnum(SECURITY_ATTRIBUTE_STATE_MASK, SECURITY_ATTRIBUTE_DISABLED, 'Disabled (modified)')]
  [SubEnum(SECURITY_ATTRIBUTE_STATE_MASK, SECURITY_ATTRIBUTE_STATE_MASK, 'Disabled')]
  TSecurityAttributeFlags = type Cardinal;

  // SDK::winnt.h
  [SDKName('CLAIM_SECURITY_ATTRIBUTE_V1')]
  TClaimSecurityAttributeV1 = record
    Name: PWideChar;
    ValueType: TSecurityAttributeType;
    [Unlisted] Reserved: Word;
    Flags: TSecurityAttributeFlags;
    ValueCount: Integer;
  case TSecurityAttributeType of
    SECURITY_ATTRIBUTE_TYPE_INVALID: (Values: Pointer);
    SECURITY_ATTRIBUTE_TYPE_INT64, SECURITY_ATTRIBUTE_TYPE_UINT64,
    SECURITY_ATTRIBUTE_TYPE_BOOLEAN:
      (ValuesUInt64: ^TAnysizeArray<UInt64>);
    SECURITY_ATTRIBUTE_TYPE_STRING:
      (ValuesString: ^TAnysizeArray<PWideChar>);
    SECURITY_ATTRIBUTE_TYPE_FQBN:
      (ValuesFQBN: ^TAnysizeArray<TClaimSecurityAttributeFqbnValue>);
    SECURITY_ATTRIBUTE_TYPE_SID, SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
      (ValuesOctet: ^TAnysizeArray<TClaimSecurityAttributeOctetStringValue>);
  end;
  PClaimSecurityAttributeV1 = ^TClaimSecurityAttributeV1;

  // SDK::winnt.h
  [SDKName('CLAIM_SECURITY_ATTRIBUTES_INFORMATION')]
  TClaimSecurityAttributes = record
    Version: Word;
    [Unlisted] Reserved: Word;
    [Counter] AttributeCount: Cardinal;
    AttributeV1: ^TAnysizeArray<TClaimSecurityAttributeV1>;
  end;
  PClaimSecurityAttributes = ^TClaimSecurityAttributes;

  // PHNT::ntseapi.h
  [SDKName('TOKEN_SECURITY_ATTRIBUTE_FQBN_VALUE')]
  TTokenSecurityAttributeFqbnValue = record
    Version: UInt64;
    Name: TNtUnicodeString;
  end;
  PTokenSecurityAttributeFqbnValue = ^TTokenSecurityAttributeFqbnValue;

  // PHNT::ntseapi.h
  [SDKName('TOKEN_SECURITY_ATTRIBUTE_OCTET_STRING_VALUE')]
  TTokenSecurityAttributeOctetStringValue = record
    pValue: Pointer;
    [Bytes] ValueLength: Cardinal;
  end;
  PTokenSecurityAttributeOctetStringValue = ^TTokenSecurityAttributeOctetStringValue;

  // PHNT::ntseapi.h
  [SDKName('TOKEN_SECURITY_ATTRIBUTE_V1')]
  TTokenSecurityAttributeV1 = record
    Name: TNtUnicodeString;
    ValueType: TSecurityAttributeType;
    [Unlisted] Reserved: Word;
    Flags: TSecurityAttributeFlags;
    ValueCount: Integer;
  case TSecurityAttributeType of
    SECURITY_ATTRIBUTE_TYPE_INVALID: (Values: Pointer);
    SECURITY_ATTRIBUTE_TYPE_INT64, SECURITY_ATTRIBUTE_TYPE_UINT64,
    SECURITY_ATTRIBUTE_TYPE_BOOLEAN:
      (ValuesUInt64: ^TAnysizeArray<UInt64>);
    SECURITY_ATTRIBUTE_TYPE_STRING:
      (ValuesString: ^TAnysizeArray<TNtUnicodeString>);
    SECURITY_ATTRIBUTE_TYPE_FQBN:
      (ValuesFQBN: ^TAnysizeArray<TTokenSecurityAttributeFqbnValue>);
    SECURITY_ATTRIBUTE_TYPE_SID, SECURITY_ATTRIBUTE_TYPE_OCTET_STRING:
      (ValuesOctet: ^TAnysizeArray<TTokenSecurityAttributeOctetStringValue>);
  end;
  PTokenSecurityAttributeV1 = ^TTokenSecurityAttributeV1;

  // PHNT::ntseapi.h
  [SDKName('TOKEN_SECURITY_ATTRIBUTES_INFORMATION')]
  TTokenSecurityAttributes = record
    Version: Word;
    [Unlisted] Reserved: Word;
    [Counter] AttributeCount: Integer;
    AttributeV1: ^TAnysizeArray<TTokenSecurityAttributeV1>;
  end;
  PTokenSecurityAttributes = ^TTokenSecurityAttributes;

  // PHNT::ntseapi.h
  [SDKName('TOKEN_SECURITY_ATTRIBUTE_OPERATION')]
  [NamingStyle(nsSnakeCase, 'TOKEN_SECURITY_ATTRIBUTE_OPERATION')]
  TTokenAttributeOperation = (
    TOKEN_SECURITY_ATTRIBUTE_OPERATION_NONE = 0,
    TOKEN_SECURITY_ATTRIBUTE_OPERATION_REPLACE_ALL = 1,
    TOKEN_SECURITY_ATTRIBUTE_OPERATION_ADD = 2,
    TOKEN_SECURITY_ATTRIBUTE_OPERATION_DELETE = 3,
    TOKEN_SECURITY_ATTRIBUTE_OPERATION_REPLACE = 4
  );

  // PHNT::ntseapi.h
  [SDKName('TOKEN_SECURITY_ATTRIBUTES_AND_OPERATION_INFORMATION')]
  TTokenSecurityAttributesAndOperation = record
    [Aggregate] Attributes: PTokenSecurityAttributes;
    Operations: ^TAnysizeArray<TTokenAttributeOperation>;
  end;
  PTokenSecurityAttributesAndOperation = ^TTokenSecurityAttributesAndOperation;

  // SDK::winnt.h
  [SDKName('TOKEN_BNO_ISOLATION_INFORMATION')]
  TTokenBnoIsolationInformation = record
    IsolationPrefix: PWideChar;
    IsolationEnabled: Boolean;
  end;
  PTokenBnoIsolationInformation = ^TTokenBnoIsolationInformation;

// PHNT::ntseapi.h
[RequiredPrivilege(SE_CREATE_TOKEN_PRIVILEGE, rpAlways)]
function NtCreateToken(
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle;
  [in] DesiredAccess: TTokenAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] TokenType: TTokenType;
  [in] const [ref] AuthenticationId: TLuid;
  [in, opt] const [ref] ExpirationTime: TLargeInteger;
  [in] const [ref] User: TSidAndAttributes;
  [in, opt] Groups: PTokenGroups;
  [in, opt] Privileges: PTokenPrivileges;
  [in, opt] Owner: PTokenSidInformation;
  [in] const [ref] PrimaryGroup: TTokenSidInformation;
  [in, opt] DefaultDacl: PTokenDefaultDacl;
  [in] const [ref] Source: TTokenSource
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntseapi.h
[MinOSVersion(OsWin8)]
[RequiredPrivilege(SE_CREATE_TOKEN_PRIVILEGE, rpAlways)]
function NtCreateTokenEx(
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle;
  [in] DesiredAccess: TTokenAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] TokenType: TTokenType;
  [in] const [ref] AuthenticationId: TLuid;
  [in, opt] const [ref] ExpirationTime: TLargeInteger;
  [in] const [ref] User: TSidAndAttributes;
  [in, opt] Groups: PTokenGroups;
  [in, opt] Privileges: PTokenPrivileges;
  [in, opt] UserAttributes: PTokenSecurityAttributes;
  [in, opt] DeviceAttributes: PTokenSecurityAttributes;
  [in, opt] DeviceGroups: PTokenGroups;
  [in] const [ref] TokenMandatoryPolicy: TTokenMandatoryPolicy;
  [in, opt] Owner: PTokenSidInformation;
  [in] const [ref] PrimaryGroup: TTokenSidInformation;
  [in, opt] DefaultDacl: PTokenDefaultDacl;
  [in] const [ref] TokenSource: TTokenSource
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtCreateTokenEx: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtCreateTokenEx';
);

// PHNT::ntseapi.h
[MinOSVersion(OsWin8)]
function NtCreateLowBoxToken(
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle;
  [in, Access(TOKEN_DUPLICATE)] ExistingTokenHandle: THandle;
  [in] DesiredAccess: TTokenAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] PackageSid: PSid;
  [in, opt, NumberOfElements] CapabilityCount: Cardinal;
  [in, opt, ReadsFrom] const Capabilities: TArray<TSidAndAttributes>;
  [in, opt, NumberOfElements] HandleCount: Cardinal;
  [in, opt, ReadsFrom] const Handles: TArray<THandle>
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtCreateLowBoxToken: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtCreateLowBoxToken';
);

// WDK::ntifs.h
function NtOpenProcessToken(
  [in, Access(PROCESS_QUERY_LIMITED_INFORMATION)] ProcessHandle: THandle;
  [in] DesiredAccess: TTokenAccessMask;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtOpenProcessTokenEx(
  [in, Access(PROCESS_QUERY_LIMITED_INFORMATION)] ProcessHandle: THandle;
  [in] DesiredAccess: TTokenAccessMask;
  [in] HandleAttributes: TObjectAttributesFlags;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtOpenThreadToken(
  [in, Access(THREAD_QUERY_LIMITED_INFORMATION)] ThreadHandle: THandle;
  [in] DesiredAccess: TTokenAccessMask;
  [in] OpenAsSelf: Boolean;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtOpenThreadTokenEx(
  [in, Access(THREAD_QUERY_LIMITED_INFORMATION)] ThreadHandle: THandle;
  [in] DesiredAccess: TTokenAccessMask;
  [in] OpenAsSelf: Boolean;
  [in] HandleAttributes: TObjectAttributesFlags;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtDuplicateToken(
  [in, Access(TOKEN_DUPLICATE)] ExistingTokenHandle: THandle;
  [in] DesiredAccess: TTokenAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] EffectiveOnly: LongBool;
  [in] TokenType: TTokenType;
  [out, ReleaseWith('NtClose')] out NewTokenHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpSometimes)]
function NtQueryInformationToken(
  [in, Access(TOKEN_QUERY or TOKEN_QUERY_SOURCE)] TokenHandle: THandle;
  [in] TokenInformationClass: TTokenInformationClass;
  [out, WritesTo] TokenInformation: Pointer;
  [in, NumberOfBytes] TokenInformationLength: Cardinal;
  [out, NumberOfBytes] out ReturnLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_CREATE_TOKEN_PRIVILEGE, rpSometimes)]
function NtSetInformationToken(
  [in, Access(TOKEN_ADJUST_DEFAULT or TOKEN_ADJUST_SESSIONID)] TokenHandle: THandle;
  [in] TokenInformationClass: TTokenInformationClass;
  [in, ReadsFrom] TokenInformation: Pointer;
  [in, NumberOfBytes] TokenInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtAdjustPrivilegesToken(
  [in, Access(TOKEN_ADJUST_PRIVILEGES)] TokenHandle: THandle;
  [in] DisableAllPrivileges: Boolean;
  [in, opt] NewState: PTokenPrivileges;
  [in, opt, NumberOfBytes] BufferLength: Cardinal;
  [out, opt, WritesTo] PreviousState: PTokenPrivileges;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtAdjustGroupsToken(
  [in, Access(TOKEN_ADJUST_GROUPS)] TokenHandle: THandle;
  [in] ResetToDefault: Boolean;
  [in, opt] NewState: PTokenGroups;
  [in, opt, NumberOfBytes] BufferLength: Cardinal;
  [out, opt, WritesTo] PreviousState: PTokenPrivileges;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtFilterToken(
  [in, Access(TOKEN_DUPLICATE)] ExistingTokenHandle: THandle;
  [in] Flags: TTokenFilterFlags;
  [in, opt] SidsToDisable: PTokenGroups;
  [in, opt] PrivilegesToDelete: PTokenPrivileges;
  [in, opt] RestrictedSids: PTokenGroups;
  [out, ReleaseWith('NtClose')] out NewTokenHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntseapi.h
function NtCompareTokens(
  [in, Access(TOKEN_QUERY)] FirstTokenHandle: THandle;
  [in, Access(TOKEN_QUERY)] SecondTokenHandle: THandle;
  [out] out Equal: LongBool
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtImpersonateAnonymousToken(
  [in, Access(THREAD_IMPERSONATE)] ThreadHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntseapi.h
function NtQuerySecurityAttributesToken(
  [in, Access(TOKEN_QUERY)] TokenHandle: THandle;
  [in, ReadsFrom] const Attributes: TArray<TNtUnicodeString>;
  [in, NumberOfElements] NumberOfAttributes: Integer;
  [out, WritesTo] Buffer: PTokenSecurityAttributes;
  [in, NumberOfBytes] Length: Cardinal;
  [out, NumberOfBytes] out ReturnLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtPrivilegeCheck(
  [in, Access(TOKEN_QUERY)] ClientToken: THandle;
  [in, out] var RequiredPrivileges: TPrivilegeSet;
  [out] out Result: Boolean
): NTSTATUS; stdcall; external ntdll;

{ Expected Access / Privileges }

function ExpectedTokenQueryPrivilege(
  [in] InfoClass: TTokenInformationClass
): TSeWellKnownPrivilege;

function ExpectedTokenQueryAccess(
  [in] InfoClass: TTokenInformationClass
): TTokenAccessMask;

function ExpectedTokenSetPrivilege(
  [in] InfoClass: TTokenInformationClass
): TSeWellKnownPrivilege;

function ExpectedTokenSetAccess(
  [in] InfoClass: TTokenInformationClass
): TTokenAccessMask;

implementation

uses
  Ntapi.ntexapi;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ RequiredPrivilegeAttribute }

constructor RequiredPrivilegeAttribute.Create;
begin
  Self.Privilege := Privilege;
  Self.Mode := Mode;
end;

{ TTokenSource }

class function TTokenSource.New;
begin
  Result.SetName(Name);
  NtAllocateLocallyUniqueId(Result.SourceIdentifier);
end;

procedure TTokenSource.SetName;
var
  i, Count: integer;
begin
  FillChar(Self, SizeOf(Self), 0);

  Count := Length(Value);
  if Count > 8 then
    Count := 8;

  for i := 1 to Count do
    sourcename[i] := AnsiChar(Value[Low(String) + i - 1]);
end;

function TTokenSource.GetName;
begin
  // sourcename field may or may not contain a zero-termination byte
  Result := String(PAnsiChar(AnsiString(sourcename)));
end;

{ Functions }

function ExpectedTokenQueryPrivilege;
begin
  if InfoClass = TokenAuditPolicy then
    Result := SE_SECURITY_PRIVILEGE
  else
    Result := Default(TSeWellKnownPrivilege);
end;

function ExpectedTokenQueryAccess;
begin
  if InfoClass = TokenSource then
    Result := TOKEN_QUERY_SOURCE
  else
    Result := TOKEN_QUERY;
end;

function ExpectedTokenSetPrivilege;
begin
  case InfoClass of
    TokenSessionId, TokenSessionReference, TokenAuditPolicy, TokenOrigin,
    TokenIntegrityLevel, TokenUIAccess, TokenMandatoryPolicy,
    TokenSecurityAttributes, TokenPrivateNameSpace, TokenChildProcessFlags:
      Result := SE_TCB_PRIVILEGE;

    TokenLinkedToken, TokenVirtualizationAllowed:
      Result := SE_CREATE_TOKEN_PRIVILEGE;
  else
    Result := Default(TSeWellKnownPrivilege);
  end;
end;

function ExpectedTokenSetAccess;
begin
  case InfoClass of
    TokenSessionId:
      Result := TOKEN_ADJUST_DEFAULT or TOKEN_ADJUST_SESSIONID;

    TokenLinkedToken:
      Result := TOKEN_ADJUST_DEFAULT or TOKEN_QUERY;
  else
    Result := TOKEN_ADJUST_DEFAULT;
  end;
end;

end.
