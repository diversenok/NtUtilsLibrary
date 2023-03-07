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

  // SDK::NTSecAPI.h
  S4U_LOGON_FLAG_CHECK_LOGONHOURS = $02; // MsV1_0, Kerb
  S4U_LOGON_FLAG_IDENTIFY = $08; // Kerb

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
  {$SCOPEDENUMS ON}
  [SDKName('SECURITY_LOGON_TYPE')]
  [NamingStyle(nsCamelCase, '', 'LogonType'), ValidBits([0, 2..13])]
  TSecurityLogonType = (
    UndefinedLogonType = 0,
    [Reserved] ReservedLogonType = 1,
    Interactive = 2,
    Network = 3,
    Batch = 4,
    Service = 5,
    Proxy = 6,
    Unlock = 7,
    NetworkCleartext = 8,
    NewCredentials = 9,
    RemoteInteractive = 10,
    CachedInteractive = 11,
    CachedRemoteInteractive = 12,
    CachedUnlock = 13
  );
  {$SCOPEDENUMS OFF}

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
  {$SCOPEDENUMS ON}
  [SDKName('MSV1_0_LOGON_SUBMIT_TYPE')]
  [SDKName('KERB_LOGON_SUBMIT_TYPE')]
  [NamingStyle(nsCamelCase), ValidBits([2..15, 82..84])]
  TLogonSubmitType = (
    Unused0, Unused1,
    InteractiveLogon = 2,        // MsV1_0, Kerb: TInteractiveLogon
    Lm20Logon = 3,               // MsV1_0
    NetworkLogon = 4,            // MsV1_0
    SubAuthLogon = 5,            // MsV1_0
    SmartCardLogon = 6,          // Kerb
    WorkstationUnlockLogon = 7,  // MsV1_0, Kerb: TInteractiveUnlockLogon
    SmartCardUnlockLogon = 8,    // Kerb
    ProxyLogon = 9,              // Kerb
    TicketLogon = 10,            // Kerb
    TicketUnlockLogon = 11,      // Kerb
    S4ULogon = 12,               // MsV1_0, Kerb: TS4ULogon
    CertificateLogon = 13,       // Kerb
    CertificateS4ULogon = 14,    // Kerb
    CertificateUnlockLogon = 15, // Kerb
    Unused16, Unused17, Unused18, Unused19, Unused20, Unused21, Unused22,
    Unused23, Unused24, Unused25, Unused26, Unused27, Unused28, Unused29,
    Unused30, Unused31, Unused32, Unused33, Unused34, Unused35, Unused36,
    Unused37, Unused38, Unused39, Unused40, Unused41, Unused42, Unused43,
    Unused44, Unused45, Unused46, Unused47, Unused48, Unused49, Unused50,
    Unused51, Unused52, Unused53, Unused54, Unused55, Unused56, Unused57,
    Unused58, Unused59, Unused60, Unused61, Unused62, Unused63, Unused64,
    Unused65, Unused66, Unused67, Unused68, Unused69, Unused70, Unused71,
    Unused72, Unused73, Unused74, Unused75, Unused76, Unused77, Unused78,
    Unused79, Unused80, Unused81,
    VirtualLogon = 82,           // Negotiate: TInteractiveLogon
    NoElevationLogon = 83,       // MsV1_0, Kerb: TInteractiveLogon?, Win 8+
    LuidLogon = 84               // MsV1_0, Kerb, Win 8.1+
  );
  {$SCOPEDENUMS OFF}

  // SDK::NTSecAPI.h - logon submit type 2
  [SDKName('MSV1_0_INTERACTIVE_LOGON')]
  [SDKName('KERB_INTERACTIVE_LOGON')]
  TInteractiveLogon = record
    MessageType: TLogonSubmitType;
    LogonDomainName: TNtUnicodeString;
    UserName: TNtUnicodeString;
    Password: TNtUnicodeString;
  end;
  PInteractiveLogon = ^TInteractiveLogon;

  // SDK::NTSecAPI.h - logon submit type 7
  [SDKName('KERB_INTERACTIVE_UNLOCK_LOGON')]
  TInteractiveUnlockLogon = record
    [Aggregate] Logon: TInteractiveLogon;
    LogonId: TLogonId;
  end;
  PInteractiveUnlockLogon = ^TInteractiveUnlockLogon;

  [FlagName(S4U_LOGON_FLAG_CHECK_LOGONHOURS, 'Check Logon Hours')]
  [FlagName(S4U_LOGON_FLAG_IDENTIFY, 'Identity')]
  TS4ULogonFlags = type Cardinal;

  // SDK::NTSecAPI.h - logon submit type 12
  [SDKName('MSV1_0_S4U_LOGON')]
  TS4ULogon = record
    MessageType: TLogonSubmitType;
    Flags: TS4ULogonFlags;
    UserPrincipalName: TNtUnicodeString; // aka ClientUpn
    DomainName: TNtUnicodeString;        // aka ClientRealm
  end;
  PS4ULogon = ^TS4ULogon;

  // SDK::NTSecAPI.h
  {$SCOPEDENUMS ON}
  [SDKName('MSV1_0_PROFILE_BUFFER_TYPE')]
  [SDKName('KERB_PROFILE_BUFFER_TYPE')]
  [NamingStyle(nsCamelCase), ValidBits([2..4, 6])]
  TLogonProfileBufferType = (
    [Reserved] Unused0,
    [Reserved] Unused1,
    InteractiveProfile = 2, // MsV1_0, Kerb: TInteractiveLogonProfile
    Lm20LogonProfile = 3,   // MsV1_0: TLm20LogonProfile
    SmartCardProfile = 4,   // MsV1_0, Kerb: TSmartCardLogonProfile
    [Reserved] Unused5,
    TicketProfile = 6       // Kerb
  );
  {$SCOPEDENUMS OFF}

  // SDK::NTSecAPI.h
  [SDKName('MSV1_0_INTERACTIVE_PROFILE')]
  [SDKName('KERB_INTERACTIVE_PROFILE')]
  TInteractiveLogonProfile = record
    MessageType: TLogonProfileBufferType;
    LogonCount: Word;
    BadPasswordCount: Word;
    LogonTime: TLargeInteger;
    LogoffTime: TLargeInteger;
    KickOffTime: TLargeInteger;
    PasswordLastSet: TLargeInteger;
    PasswordCanChange: TLargeInteger;
    PasswordMustChange: TLargeInteger;
    LogonScript: TNtUnicodeString;
    HomeDirectory: TNtUnicodeString;
    FullName: TNtUnicodeString;
    ProfilePath: TNtUnicodeString;
    HomeDirectoryDrive: TNtUnicodeString;
    LogonServer: TNtUnicodeString;
    UserFlags: TLogonFlags;
  end;
  PInteractiveLogonProfile = ^TInteractiveLogonProfile;

  // SDK::NTSecAPI.h
  [SDKName('MSV1_0_LM20_LOGON_PROFILE')]
  TLm20LogonProfile = record
    MessageType: TLogonProfileBufferType;
    KickOffTime: TLargeInteger;
    LogoffTime: TLargeInteger;
    UserFlags: TLogonFlags;
    UserSessionKey: TGuid;
    LogonDomainName: TNtUnicodeString;
    [Hex] LanmanSessionKey: UInt64;
    LogonServer: TNtUnicodeString;
    UserParameters: TNtUnicodeString;
  end;
  PLm20LogonProfile = ^TLm20LogonProfile;

  // SDK::NTSecAPI.h
  [SDKName('KERB_SMART_CARD_PROFILE')]
  TSmartCardLogonProfile = record
    [Aggregate] Profile: TInteractiveLogonProfile;
    [Bytes] CertificateSize: Cardinal;
    CertificateData: PByte;
  end;
  PSmartCardLogonProfile = ^TSmartCardLogonProfile;

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
  [in] const LogonProcessName: TLsaAnsiString;
  [out, ReleaseWith('LsaDeregisterLogonProcess')] out LsaHandle: TLsaHandle;
  [out] out SecurityMode: TLsaOperationalMode
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function LsaLogonUser(
  [in] LsaHandle: TLsaHandle;
  [in] const OriginName: TLsaAnsiString;
  [in] LogonType: TSecurityLogonType;
  [in] AuthenticationPackage: Cardinal;
  [in, ReadsFrom] AuthenticationInformation: Pointer;
  [in, NumberOfBytes] AuthenticationInformationLength: Cardinal;
  [in, opt] LocalGroups: PTokenGroups;
  [in] const SourceContext: TTokenSource;
  [out, ReleaseWith('LsaFreeReturnBuffer')] out ProfileBuffer: Pointer;
  [out] out ProfileBufferLength: Cardinal;
  [out] out LogonId: TLogonId;
  [out, ReleaseWith('NtClose')] out hToken: THandle;
  [out] out Quotas: TQuotaLimits;
  [out] out SubStatus: NTSTATUS
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaLookupAuthenticationPackage(
  [in] LsaHandle: TLsaHandle;
  [in] const PackageName: TLsaAnsiString;
  [out] out AuthenticationPackage: Cardinal
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaFreeReturnBuffer(
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaDeregisterLogonProcess(
  [in] LsaHandle: TLsaHandle
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaConnectUntrusted(
  [out, ReleaseWith('LsaDeregisterLogonProcess')] out LsaHandle: TLsaHandle
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaEnumerateLogonSessions(
  [out, NumberOfElements] out LogonSessionCount: Integer;
  [out, ReleaseWith('LsaFreeReturnBuffer')] out LogonSessionList: PLuidArray
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
function LsaGetLogonSessionData(
  [in] const [ref] LogonId: TLogonId;
  [out, ReleaseWith('LsaFreeReturnBuffer')] out LogonSessionData:
    PSecurityLogonSessionData
): NTSTATUS; stdcall; external secur32;

// SDK::NTSecAPI.h
[SetsLastError]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function AuditSetSystemPolicy(
  [in, ReadsFrom] const AuditPolicy: TArray<TAuditPolicyInformation>;
  [in, NumberOfElements] PolicyCount: Cardinal
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
function AuditSetPerUserPolicy(
  [in] Sid: PSid;
  [in, ReadsFrom] const AuditPolicy: TArray<TAuditPolicyInformation>;
  [in, NumberOfBytes] PolicyCount: Cardinal
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
function AuditQuerySystemPolicy(
  [in, ReadsFrom] const SubCategoryGuids: TArray<TGuid>;
  [in, NumberOfElements] PolicyCount: Cardinal;
  [out, ReleaseWith('AuditFree')] out AuditPolicy: PAuditPolicyInformationArray
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
function AuditQueryPerUserPolicy(
  [in] Sid: PSid;
  [in, ReadsFrom] const SubCategoryGuids: TArray<TGuid>;
  [in, NumberOfElements] PolicyCount: Cardinal;
  [out, ReleaseWith('AuditFree')] out AuditPolicy: PAuditPolicyInformationArray
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
function AuditEnumeratePerUserPolicy(
  [out, ReleaseWith('AuditFree')] out AuditSidArray: PPolicyAuditSidArray
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
function AuditEnumerateCategories(
  [out, ReleaseWith('AuditFree')] out AuditCategoriesArray: PGuidArray;
  out CountReturned: Cardinal
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
function AuditEnumerateSubCategories(
  [in, opt] AuditCategoryGuid: PGuid;
  [in] RetrieveAllSubCategories: Boolean;
  [out, ReleaseWith('AuditFree')] out AuditSubCategoriesArray: PGuidArray;
  [out, NumberOfElements] out CountReturned: Cardinal
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
function AuditLookupCategoryNameW(
  [in] const AuditCategoryGuid: TGuid;
  [out, ReleaseWith('AuditFree')] out CategoryName: PWideChar
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
function AuditLookupSubCategoryNameW(
  [in] const AuditSubCategoryGuid: TGuid;
  [out, ReleaseWith('AuditFree')] out SubCategoryName: PWideChar
): Boolean; stdcall; external advapi32;

// SDK::NTSecAPI.h
[SetsLastError]
procedure AuditFree(
  [in] Buffer: Pointer
); stdcall; external advapi32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
