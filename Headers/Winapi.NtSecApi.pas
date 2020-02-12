unit Winapi.NtSecApi;

{$MINENUMSIZE 4}

interface

uses
  Ntapi.ntdef, Winapi.WinNt, DelphiApi.Reflection;

const
  secur32 = 'secur32.dll';

  NEGOSSP_NAME_A: AnsiString = 'Negotiate';

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

  LogonFlagNames: array [0..18] of TFlagName = (
    (Value: LOGON_GUEST; Name: 'Guest'),
    (Value: LOGON_NOENCRYPTION; Name: 'No Encryption'),
    (Value: LOGON_CACHED_ACCOUNT; Name: 'Cached Account'),
    (Value: LOGON_USED_LM_PASSWORD; Name: 'Used LM Password'),
    (Value: LOGON_EXTRA_SIDS; Name: 'Extra SIDs'),
    (Value: LOGON_SUBAUTH_SESSION_KEY; Name: 'Subauth Session Key'),
    (Value: LOGON_SERVER_TRUST_ACCOUNT; Name: 'Server Trust Account'),
    (Value: LOGON_NTLMV2_ENABLED; Name: 'NTLMv2 Enabled'),
    (Value: LOGON_RESOURCE_GROUPS; Name: 'Resource Groups'),
    (Value: LOGON_PROFILE_PATH_RETURNED; Name: 'Profile Path Returned'),
    (Value: LOGON_NT_V2; Name: 'NTv2'),
    (Value: LOGON_LM_V2; Name: 'LMv2'),
    (Value: LOGON_NTLM_V2; Name: 'NTLMv2'),
    (Value: LOGON_OPTIMIZED; Name: 'Optimized'),
    (Value: LOGON_WINLOGON; Name: 'Winlogon'),
    (Value: LOGON_PKINIT; Name: 'PKINIT'),
    (Value: LOGON_NO_OPTIMIZED; Name: 'Not Optimized'),
    (Value: LOGON_NO_ELEVATION; Name: 'No Elevation'),
    (Value: LOGON_MANAGED_SERVICE; Name: 'Managed Service')
  );

type
  TLsaHandle = THandle;

  TLsaString = ANSI_STRING;
  PLsaString = ^TLsaString;

  TLsaUnicodeString = UNICODE_STRING;
  PLsaUnicodeString = ^TLsaUnicodeString;

  TLsaOperationalMode = Cardinal;

  TGuidArray = array [ANYSIZE_ARRAY] of TGUID;
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

  TLogonFlagProvider = class (TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

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
    [Bitwise(TLogonFlagProvider)] UserFlags: Cardinal;
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
    ClientUPN: UNICODE_STRING;
    ClientRealm: UNICODE_STRING;
  end;
  PKERB_S4U_LOGON = ^KERB_S4U_LOGON;

  // 5194
  TPolicyAuditSidArray = record
    UsersCount: Cardinal;
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

  TAuditPolicyInformationArray = array [ANYSIZE_ARRAY] of TAuditPolicyInformation;
  PAuditPolicyInformationArray = ^TAuditPolicyInformationArray;

// 1648
function LsaRegisterLogonProcess(const LogonProcessName: TLsaString;
  out LsaHandle: TLsaHandle; out SecurityMode: TLsaOperationalMode): NTSTATUS;
  stdcall; external secur32;

// 1663
function LsaLogonUser(LsaHandle: TLsaHandle; const OriginName: TLsaString;
  LogonType: TSecurityLogonType; AuthenticationPackage: Cardinal;
  AuthenticationInformation: Pointer; AuthenticationInformationLength: Cardinal;
  LocalGroups: PTokenGroups; const SourceContext: TTokenSource;
  out ProfileBuffer: Pointer; out ProfileBufferLength: Cardinal;
  out LogonId: TLogonId; out hToken: THandle; out Quotas: TQuotaLimits;
  out SubStatus: NTSTATUS): NTSTATUS; stdcall; external secur32;

// 1686
function LsaLookupAuthenticationPackage(LsaHandle: TLsaHandle;
  const PackageName: TLsaString; out AuthenticationPackage: Cardinal): NTSTATUS;
  stdcall; external secur32;

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

class function TLogonFlagProvider.Flags: TFlagNames;
begin
  Result := Capture(LogonFlagNames);
end;

end.
