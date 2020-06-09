unit Winapi.NtSecApi;

{$MINENUMSIZE 4}

interface

uses
  Ntapi.ntdef, Winapi.WinNt, Ntapi.ntseapi, DelphiApi.Reflection;

const
  secur32 = 'secur32.dll';

  // 1601
  POLICY_AUDIT_EVENT_UNCHANGED = $0;
  POLICY_AUDIT_EVENT_SUCCESS = $1;
  POLICY_AUDIT_EVENT_FAILURE = $2;
  POLICY_AUDIT_EVENT_NONE = $4;

  // 2046
  PER_USER_POLICY_UNCHANGED = $00;
  PER_USER_AUDIT_SUCCESS_INCLUDE = $01;
  PER_USER_AUDIT_SUCCESS_EXCLUDE = $02;
  PER_USER_AUDIT_FAILURE_INCLUDE = $04;
  PER_USER_AUDIT_FAILURE_EXCLUDE = $08;
  PER_USER_AUDIT_NONE = $10;

  // 3690, values for UserFlags
  LOGON_GUEST = $01;
  LOGON_NOENCRYPTION = $02;
  LOGON_CACHED_ACCOUNT = $04;
  LOGON_USED_LM_PASSWORD = $08;
  LOGON_EXTRA_SIDS = $20;
  LOGON_SUBAUTH_SESSION_KEY = $40;
  LOGON_SERVER_TRUST_ACCOUNT = $80;
  LOGON_NTLMV2_ENABLED = $100;
  LOGON_RESOURCE_GROUPS = $200;
  LOGON_PROFILE_PATH_RETURNED = $400;
  LOGON_NT_V2 = $800;
  LOGON_LM_V2 = $1000;
  LOGON_NTLM_V2 = $2000;
  LOGON_OPTIMIZED = $4000;
  LOGON_WINLOGON = $8000;
  LOGON_PKINIT = $10000;
  LOGON_NO_OPTIMIZED = $20000;
  LOGON_NO_ELEVATION = $40000;
  LOGON_MANAGED_SERVICE = $80000;

  NEGOSSP_NAME_A = AnsiString('Negotiate');

  // 3403
  MSV1_0_PACKAGE_NAME = AnsiString('MICROSOFT_AUTHENTICATION_PACKAGE_V1_0');

  // 4306
  MICROSOFT_KERBEROS_NAME_A = AnsiString('Kerberos');

type
  TLsaHandle = THandle;
  TLsaOperationalMode = Cardinal;

  TLsaAnsiString = TNtAnsiString;
  PLsaAnsiString = PNtAnsiString;

  TLsaUnicodeString = TNtUnicodeString;
  PLsaUnicodeString = PNtUnicodeString;

  TLuidArray = TAnysizeArray<TLuid>;
  PLuidArray = ^TLuidArray;

  TGuidArray = TAnysizeArray<TGuid>;
  PGuidArray = ^TGuidArray;

  // 948
  [NamingStyle(nsCamelCase, 'LogonType')]
  TSecurityLogonType = (
    LogonTypeSystem = 0,
    LogonTypeReserved = 1,
    LogonTypeInteractive = 2,
    LogonTypeNetwork = 3,
    LogonTypeBatch = 4,
    LogonTypeService = 5,
    LogonTypeProxy = 6,
    LogonTypeUnlock = 7,
    LogonTypeNetworkCleartext = 8,
    LogonTypeNewCredentials = 9,
    LogonTypeRemoteInteractive = 10,
    LogonTypeCachedInteractive = 11,
    LogonTypeCachedRemoteInteractive = 12,
    LogonTypeCachedUnlock = 13
  );

  // 2760
  TLsaLastInterLogonInfo = record
    LastSuccessfulLogon: TLargeInteger;
    LastFailedLogon: TLargeInteger;
    FailedAttemptsSinceLastSuccessfulLogon: Cardinal;
  end;
  PLsaLastInterLogonInfo = ^TLsaLastInterLogonInfo;

  [FlagName(LOGON_GUEST, 'Guest')]
  [FlagName(LOGON_NOENCRYPTION, 'No Encryption')]
  [FlagName(LOGON_CACHED_ACCOUNT, 'Cached Account')]
  [FlagName(LOGON_USED_LM_PASSWORD, 'Used LM Password')]
  [FlagName(LOGON_EXTRA_SIDS, 'Extra SIDs')]
  [FlagName(LOGON_SUBAUTH_SESSION_KEY, 'Sub-auth Session Key')]
  [FlagName(LOGON_SERVER_TRUST_ACCOUNT, 'Server Trust Account')]
  [FlagName(LOGON_NTLMV2_ENABLED, 'NTLMv2 Enabled')]
  [FlagName(LOGON_RESOURCE_GROUPS, 'Resource Groups')]
  [FlagName(LOGON_PROFILE_PATH_RETURNED, 'Profile Path Returned')]
  [FlagName(LOGON_NT_V2, 'NTv2')]
  [FlagName(LOGON_LM_V2, 'LMv2')]
  [FlagName(LOGON_NTLM_V2, 'NTLMv2')]
  [FlagName(LOGON_OPTIMIZED, 'Optimized')]
  [FlagName(LOGON_WINLOGON, 'Winlogon')]
  [FlagName(LOGON_PKINIT, 'PKINIT')]
  [FlagName(LOGON_NO_OPTIMIZED, 'Not Optimized')]
  [FlagName(LOGON_NO_ELEVATION, 'No Elevation')]
  [FlagName(LOGON_MANAGED_SERVICE, 'Managed Service')]
  TLogonFlags = type Cardinal;

  // 2769
  TSecurityLogonSessionData = record
    [Bytes, Unlisted] Size: Cardinal;
    LogonID: TLuid;
    UserName: TLsaUnicodeString;
    LogonDomain: TLsaUnicodeString;
    AuthenticationPackage: TLsaUnicodeString;
    LogonType: TSecurityLogonType;
    Session: TSessionId;
    SID: PSid;
    LogonTime: TLargeInteger;
    LogonServer: TLsaUnicodeString;
    DNSDomainName: TLsaUnicodeString;
    UPN: TLsaUnicodeString;
    UserFlags: TLogonFlags;
    [Aggregate] LastLogonInfo: TLsaLastInterLogonInfo;
    LogonScript: TLsaUnicodeString;
    ProfilePath: TLsaUnicodeString;
    HomeDirectory: TLsaUnicodeString;
    HomeDirectoryDrive: TLsaUnicodeString;
    LogoffTime: TLargeInteger;
    KickoffTime: TLargeInteger;
    PasswordLastSet: TLargeInteger;
    PasswordCanChange: TLargeInteger;
    PasswordMustChange: TLargeInteger;
  end;
  PSecurityLogonSessionData = ^TSecurityLogonSessionData;

  // 4335
  [NamingStyle(nsCamelCase, 'Kerb'), Range(2)]
  TKerbLogonSubmitType = (
    KerbInvalid = 0,
    KerbReserved = 1,
    KerbInteractiveLogon = 2,
    KerbSmartCardLogon = 6,
    KerbWorkstationUnlockLogon = 7,
    KerbSmartCardUnlockLogon = 8,
    KerbProxyLogon = 9,
    KerbTicketLogon = 10,
    KerbTicketUnlockLogon = 11,
    KerbS4ULogon = 12,
    KerbCertificateLogon = 13,
    KerbCertificateS4ULogon = 14,
    KerbCertificateUnlockLogon = 15
  );

  // 4469
  KERB_S4U_LOGON = record
    MessageType: TKerbLogonSubmitType;
    [Hex] Flags: Cardinal;
    ClientUPN: TLsaUnicodeString;
    ClientRealm: TLsaUnicodeString;
  end;
  PKERB_S4U_LOGON = ^KERB_S4U_LOGON;

  TSidArray = TAnysizeArray<PSid>;
  PSidArray = ^TSidArray;

  // 5194
  TPolicyAuditSidArray = record
    [Counter] UsersCount: Cardinal;
    UserSIDArray: PSidArray;
  end;
  PPolicyAuditSidArray = ^TPolicyAuditSidArray;

  // 5205
  TAuditPolicyInformation = record
    AuditSubcategoryGUID: TGuid;
    AuditingInformation: Cardinal;
    AuditCategoryGUID: TGuid;
  end;
  PAuditPolicyInformation = ^TAuditPolicyInformation;

  TAuditPolicyInformationArray = TAnysizeArray<TAuditPolicyInformation>;
  PAuditPolicyInformationArray = ^TAuditPolicyInformationArray;

// 1648
function LsaRegisterLogonProcess(const LogonProcessName: TLsaAnsiString;
  out LsaHandle: TLsaHandle; out SecurityMode: TLsaOperationalMode): NTSTATUS;
  stdcall; external secur32;

// 1663
function LsaLogonUser(LsaHandle: TLsaHandle; const OriginName: TLsaAnsiString;
  LogonType: TSecurityLogonType; AuthenticationPackage: Cardinal;
  AuthenticationInformation: Pointer; AuthenticationInformationLength: Cardinal;
  LocalGroups: PTokenGroups; const SourceContext: TTokenSource;
  out ProfileBuffer: Pointer; out ProfileBufferLength: Cardinal;
  out LogonId: TLogonId; out hToken: THandle; out Quotas: TQuotaLimits;
  out SubStatus: NTSTATUS): NTSTATUS; stdcall; external secur32;

// 1686
function LsaLookupAuthenticationPackage(LsaHandle: TLsaHandle;
  const PackageName: TLsaAnsiString; out AuthenticationPackage: Cardinal):
  NTSTATUS; stdcall; external secur32;

// 1697
function LsaFreeReturnBuffer(Buffer: Pointer): NTSTATUS; stdcall;
  external secur32;

// 1721
function LsaDeregisterLogonProcess(LsaHandle: TLsaHandle): NTSTATUS; stdcall;
  external secur32;

// 1729
function LsaConnectUntrusted(out LsaHandle: TLsaHandle): NTSTATUS; stdcall;
  external secur32;

// 2813
function LsaEnumerateLogonSessions(out LogonSessionCount: Integer;
  out LogonSessionList: PLuidArray): NTSTATUS; stdcall; external secur32;

// 2820
function LsaGetLogonSessionData(var LogonId: TLogonId;
  out pLogonSessionData: PSecurityLogonSessionData): NTSTATUS; stdcall;
  external secur32;

// 5248
function AuditSetSystemPolicy(AuditPolicy: TArray<TAuditPolicyInformation>;
  dwPolicyCount: Cardinal): Boolean; stdcall; external advapi32; overload;

function AuditSetSystemPolicy(AuditPolicy: PAuditPolicyInformationArray;
  dwPolicyCount: Cardinal): Boolean; stdcall; external advapi32; overload;

// 5255
function AuditSetPerUserPolicy(Sid: PSid; AuditPolicy:
  TArray<TAuditPolicyInformation>; dwPolicyCount: Cardinal): Boolean; stdcall;
  external advapi32; overload;

function AuditSetPerUserPolicy(Sid: PSid; AuditPolicy:
  PAuditPolicyInformationArray; dwPolicyCount: Cardinal): Boolean; stdcall;
  external advapi32; overload;

// 5264
function AuditQuerySystemPolicy(pSubCategoryGuids: TArray<TGuid>;
  dwPolicyCount: Cardinal; out pAuditPolicy: PAuditPolicyInformationArray):
  Boolean; stdcall; external advapi32;

// 5274
function AuditQueryPerUserPolicy(pSid: PSid; SubCategoryGuids: TArray<TGuid>;
  dwPolicyCount: Cardinal; out pAuditPolicy: PAuditPolicyInformationArray):
  Boolean; stdcall; external advapi32;

// 5285
function AuditEnumeratePerUserPolicy(out pAuditSidArray: PPolicyAuditSidArray):
  Boolean; stdcall; external advapi32;

// 5314
function AuditEnumerateCategories(out pAuditCategoriesArray: PGuidArray;
  out dwCountReturned: Cardinal): Boolean; stdcall; external advapi32;

// 5323
function AuditEnumerateSubCategories(const AuditCategoryGuid: TGuid;
  bRetrieveAllSubCategories: Boolean; out pAuditSubCategoriesArray: PGuidArray;
  out dwCountReturned: Cardinal): Boolean; stdcall; external advapi32; overload;

function AuditEnumerateSubCategories(AuditCategoryGuid: PGuid;
  bRetrieveAllSubCategories: Boolean; out pAuditSubCategoriesArray: PGuidArray;
  out dwCountReturned: Integer): Boolean; stdcall; external advapi32; overload;

// 5334
function AuditLookupCategoryNameW(const AuditCategoryGuid: TGuid;
  out pszCategoryName: PWideChar): Boolean; stdcall; external advapi32;

// 5356
function AuditLookupSubCategoryNameW(const AuditSubCategoryGuid: TGuid;
  out pszSubCategoryName: PWideChar): Boolean; stdcall; external advapi32;

// 5448
procedure AuditFree(Buffer: Pointer); stdcall; external advapi32;

implementation

end.
