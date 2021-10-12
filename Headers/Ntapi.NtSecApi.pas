unit Ntapi.NtSecApi;

{
  This module defines types and functions for working with auditing policies and
  logon sessions.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.ntdef, Ntapi.WinNt, Ntapi.ntseapi, DelphiApi.Reflection;

const
  secur32 = 'secur32.dll';

  // SDK::NTSecAPI.h - auditing options
  POLICY_AUDIT_EVENT_UNCHANGED = $0;
  POLICY_AUDIT_EVENT_SUCCESS = $1;
  POLICY_AUDIT_EVENT_FAILURE = $2;
  POLICY_AUDIT_EVENT_NONE = $4;

  // SDK::NTSecAPI.h - user audit overrides
  PER_USER_POLICY_UNCHANGED = $00;
  PER_USER_AUDIT_SUCCESS_INCLUDE = $01;
  PER_USER_AUDIT_SUCCESS_EXCLUDE = $02;
  PER_USER_AUDIT_FAILURE_INCLUDE = $04;
  PER_USER_AUDIT_FAILURE_EXCLUDE = $08;
  PER_USER_AUDIT_NONE = $10;

  // SDK::NTSecAPI.h - logon flags
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

  // SDK::NTSecAPI.h
  MSV1_0_PACKAGE_NAME = AnsiString('MICROSOFT_AUTHENTICATION_PACKAGE_V1_0');

  // SDK::NTSecAPI.h
  MICROSOFT_KERBEROS_NAME_A = AnsiString('Kerberos');

type
  TLsaHandle = THandle;
  TLsaOperationalMode = Cardinal;

  [SDKName('LSA_STRING')]
  TLsaAnsiString = TNtAnsiString;
  PLsaAnsiString = PNtAnsiString;

  [SDKName('LSA_UNICODE_STRING')]
  TLsaUnicodeString = TNtUnicodeString;
  PLsaUnicodeString = PNtUnicodeString;

  TLuidArray = TAnysizeArray<TLuid>;
  PLuidArray = ^TLuidArray;

  TGuidArray = TAnysizeArray<TGuid>;
  PGuidArray = ^TGuidArray;

  [SubEnum($7, POLICY_AUDIT_EVENT_UNCHANGED, 'Unchanged')]
  [FlagName(POLICY_AUDIT_EVENT_SUCCESS, 'Success')]
  [FlagName(POLICY_AUDIT_EVENT_FAILURE, 'Failure')]
  [FlagName(POLICY_AUDIT_EVENT_NONE, 'None')]
  TAuditEventPolicy = type Cardinal;

  [SubEnum($1F, PER_USER_POLICY_UNCHANGED, 'Unchanged')]
  [FlagName(PER_USER_AUDIT_SUCCESS_INCLUDE, 'Include Success')]
  [FlagName(PER_USER_AUDIT_SUCCESS_EXCLUDE, 'Exclude Success')]
  [FlagName(PER_USER_AUDIT_FAILURE_INCLUDE, 'Include Failure')]
  [FlagName(PER_USER_AUDIT_FAILURE_EXCLUDE, 'Exclude Failure')]
  [FlagName(PER_USER_AUDIT_NONE, 'None')]
  TAuditEventPolicyOverride = type Cardinal;

  // SDK::NTSecAPI.h
  [SDKName('SECURITY_LOGON_TYPE')]
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

  // SDK::NTSecAPI.h
  [SDKName('LSA_LAST_INTER_LOGON_INFO')]
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

  // SDK::NTSecAPI.h
  [SDKName('SECURITY_LOGON_SESSION_DATA')]
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

  // SDK::NTSecAPI.h
  [SDKName('KERB_LOGON_SUBMIT_TYPE')]
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

  // SDK::NTSecAPI.h
  [SDKName('KERB_S4U_LOGON')]
  TKerbS4ULogon = record
    MessageType: TKerbLogonSubmitType;
    [Hex] Flags: Cardinal;
    ClientUPN: TLsaUnicodeString;
    ClientRealm: TLsaUnicodeString;
  end;
  PKerbS4ULogon = ^TKerbS4ULogon;

  TSidArray = TAnysizeArray<PSid>;
  PSidArray = ^TSidArray;

  // SDK::NTSecAPI.h
  [SDKName('POLICY_AUDIT_SID_ARRAY')]
  TPolicyAuditSidArray = record
    [Counter] UsersCount: Cardinal;
    UserSIDArray: PSidArray;
  end;
  PPolicyAuditSidArray = ^TPolicyAuditSidArray;

  // SDK::NTSecAPI.h
  [SDKName('AUDIT_POLICY_INFORMATION')]
  TAuditPolicyInformation = record
    AuditSubcategoryGUID: TGuid;
    AuditingInformation: Cardinal;
    AuditCategoryGUID: TGuid;
  end;
  PAuditPolicyInformation = ^TAuditPolicyInformation;

  TAuditPolicyInformationArray = TAnysizeArray<TAuditPolicyInformation>;
  PAuditPolicyInformationArray = ^TAuditPolicyInformationArray;

// SDK::NTSecAPI.h
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function LsaRegisterLogonProcess(
  const LogonProcessName: TLsaAnsiString;
  out LsaHandle: TLsaHandle;
  out SecurityMode: TLsaOperationalMode
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function LsaLogonUser(
  LsaHandle: TLsaHandle;
  const OriginName: TLsaAnsiString;
  LogonType: TSecurityLogonType;
  AuthenticationPackage: Cardinal;
  [in] AuthenticationInformation: Pointer;
  AuthenticationInformationLength: Cardinal;
  [in, opt] LocalGroups: PTokenGroups;
  const SourceContext: TTokenSource;
  [allocates('LsaFreeReturnBuffer')] out ProfileBuffer: Pointer;
  out ProfileBufferLength: Cardinal;
  out LogonId: TLogonId;
  out hToken: THandle;
  out Quotas: TQuotaLimits;
  out SubStatus: NTSTATUS
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaLookupAuthenticationPackage(
  LsaHandle: TLsaHandle;
  const PackageName: TLsaAnsiString;
  out AuthenticationPackage: Cardinal
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaFreeReturnBuffer(
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaDeregisterLogonProcess(
  LsaHandle: TLsaHandle
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaConnectUntrusted(
  out LsaHandle: TLsaHandle
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaEnumerateLogonSessions(
  out LogonSessionCount: Integer;
  [allocates('LsaFreeReturnBuffer')] out LogonSessionList: PLuidArray
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaGetLogonSessionData(
  const [ref] LogonId: TLogonId;
  [allocates('LsaFreeReturnBuffer')] out LogonSessionData:
    PSecurityLogonSessionData
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function AuditSetSystemPolicy(
  [in] AuditPolicy: TArray<TAuditPolicyInformation>;
  PolicyCount: Cardinal
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function AuditSetPerUserPolicy(
  [in] Sid: PSid;
  [in] AuditPolicy: TArray<TAuditPolicyInformation>;
  PolicyCount: Cardinal
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
function AuditQuerySystemPolicy(
  [in] SubCategoryGuids: TArray<TGuid>;
  PolicyCount: Cardinal;
  [allocates('AuditFree')] out AuditPolicy: PAuditPolicyInformationArray
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
function AuditQueryPerUserPolicy(
  [in] Sid: PSid;
  [in] SubCategoryGuids: TArray<TGuid>;
  PolicyCount: Cardinal;
  [allocates('AuditFree')] out AuditPolicy: PAuditPolicyInformationArray
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
function AuditEnumeratePerUserPolicy(
  [allocates('AuditFree')] out AuditSidArray: PPolicyAuditSidArray
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
function AuditEnumerateCategories(
  [allocates('AuditFree')] out AuditCategoriesArray: PGuidArray;
  out CountReturned: Cardinal
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
function AuditEnumerateSubCategories(
  [in, opt] AuditCategoryGuid: PGuid;
  bRetrieveAllSubCategories: Boolean;
  [allocates('AuditFree')] out AuditSubCategoriesArray: PGuidArray;
  out CountReturned: Cardinal
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
function AuditLookupCategoryNameW(
  const AuditCategoryGuid: TGuid;
  [allocates('AuditFree')] out CategoryName: PWideChar
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
function AuditLookupSubCategoryNameW(
  const AuditSubCategoryGuid: TGuid;
  [allocates('AuditFree')] out SubCategoryName: PWideChar
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
procedure AuditFree(
  [in] Buffer: Pointer
); stdcall; external advapi32;

implementation

end.
