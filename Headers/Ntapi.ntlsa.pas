unit Ntapi.ntlsa;

{
  This module provides definitions for accessing Local Security Authority's
  policies and SID name resolution functionality.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.NtSecApi, Ntapi.ntseapi,
  DelphiApi.Reflection;

const
  MAX_PREFERRED_LENGTH = MaxInt;

  // SDK::ntlsa.h - logon rights (aka system access)
  SECURITY_ACCESS_INTERACTIVE_LOGON = $00000001;
  SECURITY_ACCESS_NETWORK_LOGON = $00000002;
  SECURITY_ACCESS_BATCH_LOGON = $00000004;
  SECURITY_ACCESS_SERVICE_LOGON = $00000010;
  SECURITY_ACCESS_DENY_INTERACTIVE_LOGON = $00000040;
  SECURITY_ACCESS_DENY_NETWORK_LOGON = $00000080;
  SECURITY_ACCESS_DENY_BATCH_LOGON = $00000100;
  SECURITY_ACCESS_DENY_SERVICE_LOGON = $00000200;
  SECURITY_ACCESS_REMOTE_INTERACTIVE_LOGON = $00000400;
  SECURITY_ACCESS_DENY_REMOTE_INTERACTIVE_LOGON = $00000800;

  SECURITY_ACCESS_ALLOWED_MASK = $00000417;
  SECURITY_ACCESS_DENIED_MASK = $00000BC0;

  // SDK::ntlsa.h - policy access masks
  POLICY_VIEW_LOCAL_INFORMATION = $00000001;
  POLICY_VIEW_AUDIT_INFORMATION = $00000002;
  POLICY_GET_PRIVATE_INFORMATION = $00000004;
  POLICY_TRUST_ADMIN = $00000008;
  POLICY_CREATE_ACCOUNT = $00000010;
  POLICY_CREATE_SECRET = $00000020;
  POLICY_CREATE_PRIVILEGE = $00000040;
  POLICY_SET_DEFAULT_QUOTA_LIMITS = $00000080;
  POLICY_SET_AUDIT_REQUIREMENTS = $00000100;
  POLICY_AUDIT_LOG_ADMIN = $00000200;
  POLICY_SERVER_ADMIN = $00000400;
  POLICY_LOOKUP_NAMES = $00000800;
  POLICY_NOTIFICATION = $00001000;

  POLICY_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $0FFF;

  // SDK::ntlsa.h - name lookup flags
  LSA_LOOKUP_ISOLATED_AS_LOCAL = $80000000;

  // SDK::ntlsa.h - SID lookup flags
  LSA_LOOKUP_DISALLOW_CONNECTED_ACCOUNT_INTERNET_SID = $80000000;
  LSA_LOOKUP_PREFER_INTERNET_NAMES = $40000000;

  // SDK::ntlsa.h - domain QoS
  POLICY_QOS_SCHANNEL_REQUIRED = $00000001;
  POLICY_QOS_OUTBOUND_INTEGRITY = $00000002;
  POLICY_QOS_OUTBOUND_CONFIDENTIALITY = $00000004;
  POLICY_QOS_INBOUND_INTEGRITY = $00000008;
  POLICY_QOS_INBOUND_CONFIDENTIALITY = $00000010;
  POLICY_QOS_ALLOW_LOCAL_ROOT_CERT_STORE = $00000020;
  POLICY_QOS_RAS_SERVER_ALLOWED = $00000040;
  POLICY_QOS_DHCP_SERVER_ALLOWED = $00000080;

  // SDK::ntlsa.h - kerberos options
  POLICY_KERBEROS_VALIDATE_CLIENT = $00000080;

  // SDK::ntlsa.h - account access masks
  ACCOUNT_VIEW = $00000001;
  ACCOUNT_ADJUST_PRIVILEGES = $00000002;
  ACCOUNT_ADJUST_QUOTAS = $00000004;
  ACCOUNT_ADJUST_SYSTEM_ACCESS = $00000008;

  ACCOUNT_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $000F;

  // DDK::lsalookupi.h
  LSA_MAXIMUM_NUMBER_OF_MAPPINGS_IN_ADD_MULTIPLE_INPUT = $1000;

type
  TLsaHandle = Ntapi.NtSecApi.TLsaHandle;
  TLsaEnumerationHandle = Cardinal;

  [FriendlyName('policy'), ValidMask(POLICY_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(POLICY_VIEW_LOCAL_INFORMATION, 'View Local Information')]
  [FlagName(POLICY_VIEW_AUDIT_INFORMATION, 'View Audit Information')]
  [FlagName(POLICY_GET_PRIVATE_INFORMATION, 'Get Private Information')]
  [FlagName(POLICY_TRUST_ADMIN, 'Trust Admin')]
  [FlagName(POLICY_CREATE_ACCOUNT, 'Create Account')]
  [FlagName(POLICY_CREATE_SECRET, 'Create Secret')]
  [FlagName(POLICY_CREATE_PRIVILEGE, 'Create Privilege')]
  [FlagName(POLICY_SET_DEFAULT_QUOTA_LIMITS, 'Set Default Quota')]
  [FlagName(POLICY_SET_AUDIT_REQUIREMENTS, 'Set Audit Requirements')]
  [FlagName(POLICY_AUDIT_LOG_ADMIN, 'Audit Log Admin')]
  [FlagName(POLICY_SERVER_ADMIN, 'Server Admin')]
  [FlagName(POLICY_LOOKUP_NAMES, 'Lookup Names')]
  [FlagName(POLICY_NOTIFICATION, 'Notification')]
  TLsaPolicyAccessMask = type TAccessMask;

  [FriendlyName('account'), ValidMask(ACCOUNT_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(ACCOUNT_VIEW, 'View')]
  [FlagName(ACCOUNT_ADJUST_PRIVILEGES, 'Adjust Privileges')]
  [FlagName(ACCOUNT_ADJUST_QUOTAS, 'Adjust Quotas')]
  [FlagName(ACCOUNT_ADJUST_SYSTEM_ACCESS, 'Adjust System Access')]
  TLsaAccountAccessMask = type TAccessMask;

  [FlagName(SECURITY_ACCESS_INTERACTIVE_LOGON, 'Allow Interactive Logon')]
  [FlagName(SECURITY_ACCESS_NETWORK_LOGON, 'Allow Network Logon')]
  [FlagName(SECURITY_ACCESS_BATCH_LOGON, 'Allow Batch Logon')]
  [FlagName(SECURITY_ACCESS_SERVICE_LOGON, 'Allow Service Logon')]
  [FlagName(SECURITY_ACCESS_REMOTE_INTERACTIVE_LOGON, 'Allow RDP Logon')]
  [FlagName(SECURITY_ACCESS_DENY_INTERACTIVE_LOGON, 'Deny Interactive Logon')]
  [FlagName(SECURITY_ACCESS_DENY_NETWORK_LOGON, 'Deny Network Logon')]
  [FlagName(SECURITY_ACCESS_DENY_BATCH_LOGON, 'Deny Batch Logon')]
  [FlagName(SECURITY_ACCESS_DENY_SERVICE_LOGON, 'Deny Service Logon')]
  [FlagName(SECURITY_ACCESS_DENY_REMOTE_INTERACTIVE_LOGON, 'Deny RDP Logon')]
  TSystemAccess = type Cardinal;

  // Bit numbers for SECURITY_ACCESS_* constants
  [NamingStyle(nsCamelCase, 'Se'), ValidMask($0FD7)]
  TSystemAccessIndex = (
    SeAllowInteractiveLogon = 0,
    SeAllowNetworkLogon = 1,
    SeAccessAllowBatchLogon = 2,
    [Reserved] SecurityAccessReserved3 = 3,
    SeAllowServiceLogon = 4,
    [Reserved] SecurityAccessReserved5 = 5,
    SeDenyInteractiveLogon = 6,
    SeDenyNetworkLogon = 7,
    SeDenyBatchLogon = 8,
    SeDenyServiceLogon = 9,
    SeAllowRemoteInteractiveLogon = 10,
    SeDenyRemoteInteractiveLogon = 11
  );

  // SDK::ntlsa.h - policy info class 6
  [SDKName('POLICY_LSA_SERVER_ROLE')]
  [NamingStyle(nsCamelCase, 'PolicyServer'), Range(2)]
  TPolicyLsaServerRole = (
    PolicyServerRoleInvalid0 = 0,
    PolicyServerRoleInvalid1 = 1,
    PolicyServerRoleBackup = 2,
    PolicyServerRolePrimary = 3
  );

  // SDK::ntlsa.h
  [SDKName('POLICY_PRIVILEGE_DEFINITION')]
  TPolicyPrivilegeDefinition = record
    Name: TLsaUnicodeString;
    LocalValue: TLuid;
  end;
  PPolicyPrivilegeDefinition = ^TPolicyPrivilegeDefinition;

  TPolicyPrivilegeDefinitionArray = TAnysizeArray<TPolicyPrivilegeDefinition>;
  PPolicyPrivilegeDefinitionArray = ^TPolicyPrivilegeDefinitionArray;

  // SDK::ntlsa.h
  [SDKName('POLICY_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Policy'), Range(1)]
  TPolicyInformationClass = (
    PolicyReserved = 0,
    PolicyAuditLogInformation = 1,      // q:
    PolicyAuditEventsInformation = 2,   // q, s:
    PolicyPrimaryDomainInformation = 3, // q, s: TPolicyPrimaryDomainInfo
    PolicyPdAccountInformation = 4,     // q: TLsaUnicodeString
    PolicyAccountDomainInformation = 5, // q, s:
    PolicyLsaServerRoleInformation = 6, // q, s: TPolicyLsaServerRole
    PolicyReplicaSourceInformation = 7, // q, s: TPolicyReplicaSourceInfo
    PolicyDefaultQuotaInformation = 8,  // q, s: TQuotaLimits
    PolicyModificationInformation = 9,  // q: TPolicyModificationInfo
    PolicyAuditFullSetInformation = 10,
    PolicyAuditFullQueryInformation = 11,
    PolicyDnsDomainInformation = 12,    // q, s:
    PolicyDnsDomainInformationInt = 13,
    PolicyLocalAccountDomainInformation = 14, // q, s:
    PolicyMachineAccountInformation = 15 // q: TPolicyMachineAcctInfo
  );

  // SDK::ntlsa.h - policy info class 3
  [SDKName('POLICY_PRIMARY_DOMAIN_INFO')]
  TPolicyPrimaryDomainInfo = record
    Name: TLsaUnicodeString;
    Sid: PSid;
  end;
  PPolicyPrimaryDomainInfo = ^TPolicyPrimaryDomainInfo;

  // SDK::ntlsa.h - policy info class 7
  [SDKName('POLICY_REPLICA_SOURCE_INFO')]
  TPolicyReplicaSourceInfo = record
    ReplicaSource: TLsaUnicodeString;
    ReplicaAccountName: TLsaUnicodeString;
  end;
  PPolicyReplicaSourceInfo = ^TPolicyReplicaSourceInfo;

  // SDK::ntlsa.h - policy info class 9
  [SDKName('POLICY_MODIFICATION_INFO')]
  TPolicyModificationInfo = record
    ModifiedId: TLargeInteger;
    DatabaseCreationTime: TLargeInteger;
  end;
  PPolicyModificationInfo = ^TPolicyModificationInfo;

  // SDK::ntlsa.h - policy info class 15
  [SDKName('POLICY_MACHINE_ACCT_INFO')]
  TPolicyMachineAcctInfo = record
    Rid: Cardinal;
    Sid: PSid;
  end;
  PPolicyMachineAcctInfo = ^TPolicyMachineAcctInfo;

  // SDK::ntlsa.h
  [SDKName('POLICY_DOMAIN_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'PolicyDomain'), Range(1)]
  TPolicyDomainInformationClass = (
    PolicyDomainReserved = 0,
    PolicyDomainQualityOfServiceInformation = 1, // TPolicyDomainQoS
    PolicyDomainEfsInformation = 2,              // TPolicyDomainEfsInfo
    PolicyDomainKerberosTicketInformation = 3    // TPolicyDomainKerberosTicketInfo
  );

  // SDK::ntlsa.h - policy domain info class 1
  [SDKName('POLICY_DOMAIN_QUALITY_OF_SERVICE_INFO')]
  [FlagName(POLICY_QOS_SCHANNEL_REQUIRED, 'SChannel Required')]
  [FlagName(POLICY_QOS_OUTBOUND_INTEGRITY, 'Outbound Integrity')]
  [FlagName(POLICY_QOS_OUTBOUND_CONFIDENTIALITY, 'Outbound Confidentiality')]
  [FlagName(POLICY_QOS_INBOUND_INTEGRITY, 'Inbound Integrity')]
  [FlagName(POLICY_QOS_INBOUND_CONFIDENTIALITY, 'Inbound Confidentiality')]
  [FlagName(POLICY_QOS_ALLOW_LOCAL_ROOT_CERT_STORE, 'Allow Local Root Certificate Srore')]
  [FlagName(POLICY_QOS_RAS_SERVER_ALLOWED, 'RAS Server Allowed')]
  [FlagName(POLICY_QOS_DHCP_SERVER_ALLOWED, 'DHCP Server Allowed')]
  TPolicyDomainQoS = type Cardinal;

  // SDK::ntlsa.h - policy domain info class 2
  [SDKName('POLICY_DOMAIN_EFS_INFO')]
  TPolicyDomainEfsInfo = record
    [Bytes] InfoLength: Cardinal;
    EfsBlob: Pointer;
  end;

  [FlagName(POLICY_KERBEROS_VALIDATE_CLIENT, 'Validate Client')]
  TPolicyKerberosOptions = type Cardinal;

  // SDK::ntlsa.h - policy domain info class 3
  [SDKName('POLICY_DOMAIN_KERBEROS_TICKET_INFO')]
  TPolicyDomainKerberosTicketInfo = record
    AuthenticationOptions: TPolicyKerberosOptions;
    MaxServiceTicketAge: TLargeInteger;
    MaxTicketAge: TLargeInteger;
    MaxRenewAge: TLargeInteger;
    MaxClockSkew: TLargeInteger;
    Reserved: TLargeInteger;
  end;
  PPolicyDomainKerberosTicketInfo = ^TPolicyDomainKerberosTicketInfo;

  // SDK::ntlsa.h
  [SDKName('POLICY_NOTIFICATION_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'PolicyNotify'), Range(1)]
  TPolicyNotificationInformationClass = (
    PolicyNotifyReserved = 0,
    PolicyNotifyAuditEventsInformation = 1,
    PolicyNotifyAccountDomainInformation = 2,
    PolicyNotifyServerRoleInformation = 3,
    PolicyNotifyDnsDomainInformation = 4,
    PolicyNotifyDomainEfsInformation = 5,
    PolicyNotifyDomainKerberosTicketInformation = 6,
    PolicyNotifyMachineAccountPasswordInformation = 7,
    PolicyNotifyGlobalSaclInformation = 8
  );

  [FlagName(LSA_LOOKUP_ISOLATED_AS_LOCAL, 'Lookup Isolated as Local')]
  TLsaLookupNamesFlags = type Cardinal;

  [FlagName(LSA_LOOKUP_DISALLOW_CONNECTED_ACCOUNT_INTERNET_SID, 'Dissallow Connected Account Internet SID')]
  [FlagName(LSA_LOOKUP_PREFER_INTERNET_NAMES, 'Prefer Internet Names')]
  TLsaLookupSidsFlags = type Cardinal;

  // SDK::LsaLookup.h
  [SDKName('LSA_TRUST_INFORMATION')]
  TLsaTrustInformation = record
    Name: TLsaUnicodeString;
    Sid: PSid;
  end;
  PLsaTrustInformation = ^TLsaTrustInformation;

  // SDK::LsaLookup.h
  [SDKName('LSA_REFERENCED_DOMAIN_LIST')]
  TLsaReferencedDomainList = record
    [Counter] Entries: Integer;
    Domains: ^TAnysizeArray<TLsaTrustInformation>;
  end;
  PLsaReferencedDomainList = ^TLsaReferencedDomainList;

  // SDK::LsaLookup.h
  [SDKName('LSA_TRANSLATED_SID2')]
  TLsaTranslatedSid2 = record
    Use: TSidNameUse;
    Sid: PSid;
    DomainIndex: Integer;
    [Hex] Flags: Cardinal;
  end;
  PLsaTranslatedSid2 = ^TLsaTranslatedSid2;

  TLsaTranslatedSid2Array = TAnysizeArray<TLsaTranslatedSid2>;
  PLsaTranslatedSid2Array = ^TLsaTranslatedSid2Array;

  // SDK::LsaLookup.h
  [SDKName('LSA_TRANSLATED_NAME')]
  TLsaTranslatedName = record
    Use: TSidNameUse;
    Name: TLsaUnicodeString;
    DomainIndex: Integer;
  end;
  PLsaTranslatedName = ^TLsaTranslatedName;

  TLsaTranslatedNameArray = TAnysizeArray<TLsaTranslatedName>;
  PLsaTranslatedNameArray = ^TLsaTranslatedNameArray;

  // SDK::ntlsa.h
  [SDKName('LSA_ENUMERATION_INFORMATION')]
  TLsaEnumerationInformation = TAnysizeArray<PSid>;
  PLsaEnumerationInformation = ^TLsaEnumerationInformation;

  TLsaUnicodeStringArray = TAnysizeArray<TLsaUnicodeString>;
  PLsaUnicodeStringArray = ^TLsaUnicodeStringArray;

  // DDK::lsalookupi.h
  [SDKName('LSA_SID_NAME_MAPPING_OPERATION_TYPE')]
  [NamingStyle(nsCamelCase, 'LsaSidNameMappingOperation_'), Range(1)]
  TLsaSidNameMappingOperationType = (
    LsaSidNameMappingOperation_Add = 0,
    LsaSidNameMappingOperation_Remove = 1,
    LsaSidNameMappingOperation_AddMultiple = 2
  );

  // DDK::lsalookupi.h
  [SDKName('LSA_SID_NAME_MAPPING_OPERATION_ADD_INPUT')]
  TLsaSidNameMappingOperationAddInput = record
    DomainName: TLsaUnicodeString;
    AccountName: TLsaUnicodeString;
    Sid: PSid;
    Flags: Cardinal;
  end;

  // DDK::lsalookupi.h
  [SDKName('LSA_SID_NAME_MAPPING_OPERATION_REMOVE_INPUT')]
  TLsaSidNameMappingOperationRemoveInput = record
    DomainName: TLsaUnicodeString;
    AccountName: TLsaUnicodeString;
  end;

  // DDK::lsalookupi.h
  [SDKName('LSA_SID_NAME_MAPPING_OPERATION_ADD_MULTIPLE_INPUT')]
  TLsaSidNameMappingOperationAddMultipleInput = record
    [Counter] Count: Cardinal;
    Mappings: ^TAnysizeArray<TLsaSidNameMappingOperationRemoveInput>;
  end;

  // DDK::lsalookupi.h
  [SDKName('LSA_SID_NAME_MAPPING_OPERATION_INPUT')]
  TLsaSidNameMappingOperation = record
  case TLsaSidNameMappingOperationType of
    LsaSidNameMappingOperation_Add:
      (AddInput: TLsaSidNameMappingOperationAddInput);
    LsaSidNameMappingOperation_Remove:
      (RemoveInput: TLsaSidNameMappingOperationRemoveInput);
    LsaSidNameMappingOperation_AddMultiple:
      (AddMultipleInput: TLsaSidNameMappingOperationAddMultipleInput);
  end;

  // DDK::lsalookupi.h
  [SDKName('LSA_SID_NAME_MAPPING_OPERATION_ERROR')]
  [NamingStyle(nsCamelCase, 'LsaSidNameMappingOperation_')]
  TLsaSidNameMappingOperationError = (
    LsaSidNameMappingOperation_Success = 0,
    LsaSidNameMappingOperation_NonMappingError = 1,
    LsaSidNameMappingOperation_NameCollision = 2,
    LsaSidNameMappingOperation_SidCollision = 3,
    LsaSidNameMappingOperation_DomainNotFound = 4,
    LsaSidNameMappingOperation_DomainSidPrefixMismatch = 5,
    LsaSidNameMappingOperation_MappingNotFound = 6
  );

  // DDK::lsalookupi.h
  [SDKName('LSA_SID_NAME_MAPPING_OPERATION_GENERIC_OUTPUT')]
  TLsaSidNameMappingOperationGenericOutput = record
    ErrorCode: TLsaSidNameMappingOperationError;
  end;
  PLsaSidNameMappingOperationGenericOutput = ^TLsaSidNameMappingOperationGenericOutput;

const
  VALID_SYSTEM_ACCESS = [SeAllowInteractiveLogon..SeAccessAllowBatchLogon,
    SeAllowServiceLogon, SeDenyInteractiveLogon..SeDenyRemoteInteractiveLogon];

  // SDK::ntlsa.h - names for logon rights
  SE_SECURITY_ACCESS_NAMES: array [TSystemAccessIndex] of String = (
    'SeInteractiveLogonRight',
    'SeNetworkLogonRight',
    'SeBatchLogonRight',
    '', // Reserved 3
    'SeServiceLogonRight',
    '', // Reserved 5
    'SeDenyInteractiveLogonRight',
    'SeDenyNetworkLogonRight',
    'SeDenyBatchLogonRight',
    'SeDenyServiceLogonRight',
    'SeRemoteInteractiveLogonRight',
    'SeDenyRemoteInteractiveLogonRight'
  );

  // SDK::winnt.h - privilege constants
  SE_PRIVILEGE_NAMES: array [TSeWellKnownPrivilege] of String = (
    '', // Reserved 0
    '', // Reserved 1
    'SeCreateTokenPrivilege',
    'SeAssignPrimaryTokenPrivilege',
    'SeLockMemoryPrivilege',
    'SeIncreaseQuotaPrivilege',
    'SeMachineAccountPrivilege',
    'SeTcbPrivilege',
    'SeSecurityPrivilege',
    'SeTakeOwnershipPrivilege',
    'SeLoadDriverPrivilege',
    'SeSystemProfilePrivilege',
    'SeSystemtimePrivilege',
    'SeProfileSingleProcessPrivilege',
    'SeIncreaseBasePriorityPrivilege',
    'SeCreatePagefilePrivilege',
    'SeCreatePermanentPrivilege',
    'SeBackupPrivilege',
    'SeRestorePrivilege',
    'SeShutdownPrivilege',
    'SeDebugPrivilege',
    'SeAuditPrivilege',
    'SeSystemEnvironmentPrivilege',
    'SeChangeNotifyPrivilege',
    'SeRemoteShutdownPrivilege',
    'SeUndockPrivilege',
    'SeSyncAgentPrivilege',
    'SeEnableDelegationPrivilege',
    'SeManageVolumePrivilege',
    'SeImpersonatePrivilege',
    'SeCreateGlobalPrivilege',
    'SeTrustedCredManAccessPrivilege',
    'SeRelabelPrivilege',
    'SeIncreaseWorkingSetPrivilege',
    'SeTimeZonePrivilege',
    'SeCreateSymbolicLinkPrivilege',
    'SeDelegateSessionUserImpersonatePrivilege'
  );

// SDK::ntlsa.h
function LsaFreeMemory(
  [in, opt] Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaClose(
  [in] ObjectHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaDelete(
  [in, Access(_DELETE)] ObjectHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaQuerySecurityObject(
  [in, Access(OBJECT_READ_SECURITY)] ObjectHandle: TLsaHandle;
  [in] SecurityInformation: TSecurityInformation;
  [out, ReleaseWith('LsaFreeMemory')] out SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetSecurityObject(
  [in, Access(OBJECT_WRITE_SECURITY)] ObjectHandle: TLsaHandle;
  [in] SecurityInformation: TSecurityInformation;
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaOpenPolicy(
  [in, opt] SystemName: PLsaUnicodeString;
  [in] const ObjectAttributes: TObjectAttributes;
  [in] DesiredAccess: TLsaPolicyAccessMask;
  [out, ReleaseWith('LsaClose')] out PolicyHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaQueryInformationPolicy(
  [in, Access(POLICY_VIEW_LOCAL_INFORMATION or
    POLICY_VIEW_AUDIT_INFORMATION)] PolicyHandle: TLsaHandle;
  [in] InformationClass: TPolicyInformationClass;
  [out, ReleaseWith('LsaFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetInformationPolicy(
  [in, Access(POLICY_TRUST_ADMIN or POLICY_AUDIT_LOG_ADMIN or
    POLICY_SET_AUDIT_REQUIREMENTS or POLICY_SERVER_ADMIN or
    POLICY_SET_DEFAULT_QUOTA_LIMITS)] PolicyHandle: TLsaHandle;
  [in] InformationClass: TPolicyInformationClass;
  [in, ReadsFrom] Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaQueryDomainInformationPolicy(
  [in, Access(POLICY_VIEW_LOCAL_INFORMATION or
    POLICY_VIEW_AUDIT_INFORMATION)] PolicyHandle: TLsaHandle;
  [in] InformationClass: TPolicyDomainInformationClass;
  [out, ReleaseWith('LsaFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetDomainInformationPolicy(
  [in, Access(POLICY_SERVER_ADMIN)] PolicyHandle: TLsaHandle;
  [in] InformationClass: TPolicyDomainInformationClass;
  [in, ReadsFrom] Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
[Result: ReleaseWith('LsaUnregisterPolicyChangeNotification')]
function LsaRegisterPolicyChangeNotification(
  [in] InformationClass: TPolicyNotificationInformationClass;
  [in] NotificationEventHandle: TLsaHandle
): NTSTATUS; stdcall; external secur32;

// SDK::ntlsa.h
function LsaUnregisterPolicyChangeNotification(
  [in] InformationClass: TPolicyNotificationInformationClass;
  [in] NotificationEventHandle: TLsaHandle
): NTSTATUS; stdcall; external secur32;

// SDK::ntlsa.h
function LsaCreateAccount(
  [in, Access(POLICY_CREATE_ACCOUNT)] PolicyHandle: TLsaHandle;
  [in] AccountSid: PSid;
  [in] DesiredAccess: TLsaAccountAccessMask;
  [out, ReleaseWith('LsaClose')] out AccountHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaEnumerateAccounts(
  [in, Access(POLICY_VIEW_LOCAL_INFORMATION)] PolicyHandle: TLsaHandle;
  [in, out] var EnumerationContext: TLsaEnumerationHandle;
  [out, ReleaseWith('LsaFreeMemory')] out Buffer: PSidArray;
  [in, NumberOfElements] PreferedMaximumLength: Integer;
  [out, NumberOfElements] out CountReturned: Integer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaEnumeratePrivileges(
  [in, Access(POLICY_VIEW_LOCAL_INFORMATION)] PolicyHandle: TLsaHandle;
  [in, out] var EnumerationContext: TLsaEnumerationHandle;
  [out, ReleaseWith('LsaFreeMemory')] out Buffer: PPolicyPrivilegeDefinitionArray;
  [in, NumberOfElements] PreferedMaximumLength: Integer;
  [out, NumberOfElements] out CountReturned: Integer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupNames2(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in] Flags: TLsaLookupNamesFlags;
  [in, NumberOfElements] Count: Integer;
  [in, ReadsFrom] const Name: TArray<TLsaUnicodeString>;
  [out, ReleaseWith('LsaFreeMemory')] out ReferencedDomain: PLsaReferencedDomainList;
  [out, ReleaseWith('LsaFreeMemory')] out Sid: PLsaTranslatedSid2Array
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupSids(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in, NumberOfElements] Count: Cardinal;
  [in, ReadsFrom] const Sids: TArray<PSid>;
  [out, ReleaseWith('LsaFreeMemory')] out ReferencedDomains: PLsaReferencedDomainList;
  [out, ReleaseWith('LsaFreeMemory')] out Names: PLsaTranslatedNameArray
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupSids2(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in] LookupOptions: TLsaLookupSidsFlags;
  [in, NumberOfElements] Count: Cardinal;
  [in, ReadsFrom] const Sids: TArray<PSid>;
  [out, ReleaseWith('LsaFreeMemory')] out ReferencedDomains: PLsaReferencedDomainList;
  [out, ReleaseWith('LsaFreeMemory')] out Names: PLsaTranslatedNameArray
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaOpenAccount(
  [in, Access(POLICY_VIEW_LOCAL_INFORMATION)] PolicyHandle: TLsaHandle;
  [in] AccountSid: PSid;
  [in] DesiredAccess: TLsaAccountAccessMask;
  [out, ReleaseWith('LsaClose')] out AccountHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaEnumeratePrivilegesOfAccount(
  [in, Access(ACCOUNT_VIEW)] AccountHandle: TLsaHandle;
  [out, ReleaseWith('LsaFreeMemory')] out Privileges: PPrivilegeSet
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaAddPrivilegesToAccount(
  [in, Access(ACCOUNT_ADJUST_PRIVILEGES)] AccountHandle: TLsaHandle;
  [in] Privileges: PPrivilegeSet
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaRemovePrivilegesFromAccount(
  [in, Access(ACCOUNT_ADJUST_PRIVILEGES)] AccountHandle: TLsaHandle;
  [in] AllPrivileges: Boolean;
  [in, opt] Privileges: PPrivilegeSet
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaGetQuotasForAccount(
  [in, Access(ACCOUNT_VIEW)] AccountHandle: TLsaHandle;
  [out] out QuotaLimits: TQuotaLimits
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetQuotasForAccount(
  [in, Access(ACCOUNT_ADJUST_QUOTAS)] AccountHandle: TLsaHandle;
  [in] const QuotaLimits: TQuotaLimits
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaGetSystemAccessAccount(
  [in, Access(ACCOUNT_VIEW)] AccountHandle: TLsaHandle;
  [out] out SystemAccess: TSystemAccess
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetSystemAccessAccount(
  [in, Access(ACCOUNT_ADJUST_SYSTEM_ACCESS)] AccountHandle: TLsaHandle;
  [in] SystemAccess: TSystemAccess
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupPrivilegeValue(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in] const Name: TLsaUnicodeString;
  [out] out Value: TLuid
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupPrivilegeName(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in] const [ref] Value: TLuid;
  [out, ReleaseWith('LsaFreeMemory')] out Name: PLsaUnicodeString
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupPrivilegeDisplayName(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in] const Name: TLsaUnicodeString;
  [out, ReleaseWith('LsaFreeMemory')] out DisplayName: PLsaUnicodeString;
  [out] out LanguageReturned: SmallInt
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
[RequiresAdmin]
function LsaEnumerateAccountsWithUserRight(
  [in, Access(POLICY_LOOKUP_NAMES or POLICY_VIEW_LOCAL_INFORMATION)]
    PolicyHandle: TLsaHandle;
  [in] const UserRight: TLsaUnicodeString;
  [out, ReleaseWith('LsaFreeMemory')] out Buffer: PLsaEnumerationInformation;
  [out] out CountReturned: Cardinal
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaEnumerateAccountRights(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in, Access(ACCOUNT_VIEW)] AccountSid: PSid;
  [out, ReleaseWith('LsaFreeMemory')] out UserRights: PLsaUnicodeStringArray;
  [out] out CountOfRights: Cardinal
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaAddAccountRights(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in, Access(ACCOUNT_VIEW or ACCOUNT_ADJUST_PRIVILEGES or
    ACCOUNT_ADJUST_SYSTEM_ACCESS)] AccountSid: PSid;
  [in, opt, ReadsFrom] const UserRights: TArray<TLsaUnicodeString>;
  [in, opt, NumberOfElements] CountOfRights: Cardinal
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaRemoveAccountRights(
  [in, Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  [in, Access(ACCOUNT_VIEW or ACCOUNT_ADJUST_PRIVILEGES or
    ACCOUNT_ADJUST_SYSTEM_ACCESS or _DELETE)] AccountSid: PSid;
  [in] AllRights: Boolean;
  [in, opt, ReadsFrom] const UserRights: TArray<TLsaUnicodeString>;
  [in, opt, NumberOfElements] CountOfRights: Cardinal
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaGetUserName(
  [out, ReleaseWith('LsaFreeMemory')] out UserName: PLsaUnicodeString;
  [out, ReleaseWith('LsaFreeMemory')] out DomainName: PLsaUnicodeString
): NTSTATUS; stdcall; external advapi32;

// DDK::lsalookupi.h (aka LsaLookupManageSidNameMapping)
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function LsaManageSidNameMapping(
  [in] OpType: TLsaSidNameMappingOperationType;
  [in] const OpInput: TLsaSidNameMappingOperation;
  [out, ReleaseWith('LsaFreeMemory')] out OpOutput:
    PLsaSidNameMappingOperationGenericOutput
): NTSTATUS; stdcall; external advapi32;

{ Expected Access Masks }

function ExpectedPolicyQueryAccess(
  [in] InfoClass: TPolicyInformationClass
): TLsaPolicyAccessMask;

function ExpectedPolicySetAccess(
  [in] InfoClass: TPolicyInformationClass
): TLsaPolicyAccessMask;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function ExpectedPolicyQueryAccess;
begin
  // See [MS-LSAD] & LsapDbRequiredAccessQueryPolicy
  case InfoClass of
    PolicyAuditLogInformation, PolicyAuditEventsInformation,
    PolicyAuditFullQueryInformation:
      Result := POLICY_VIEW_AUDIT_INFORMATION;

    PolicyPrimaryDomainInformation, PolicyAccountDomainInformation,
    PolicyLsaServerRoleInformation, PolicyReplicaSourceInformation,
    PolicyDefaultQuotaInformation, PolicyDnsDomainInformation,
    PolicyDnsDomainInformationInt, PolicyLocalAccountDomainInformation:
      Result := POLICY_VIEW_LOCAL_INFORMATION;

    PolicyPdAccountInformation:
      Result := POLICY_GET_PRIVATE_INFORMATION;
  else
    Result := 0;
  end;
end;

function ExpectedPolicySetAccess;
begin
  // See [MS-LSAD] & LsapDbRequiredAccessSetPolicy
  case InfoClass of
    PolicyPrimaryDomainInformation, PolicyAccountDomainInformation,
    PolicyDnsDomainInformation, PolicyDnsDomainInformationInt,
    PolicyLocalAccountDomainInformation:
      Result := POLICY_TRUST_ADMIN;

    PolicyAuditLogInformation, PolicyAuditFullSetInformation:
      Result := POLICY_AUDIT_LOG_ADMIN;

    PolicyAuditEventsInformation:
      Result := POLICY_SET_AUDIT_REQUIREMENTS;

    PolicyLsaServerRoleInformation, PolicyReplicaSourceInformation:
      Result := POLICY_SERVER_ADMIN;

    PolicyDefaultQuotaInformation:
      Result := POLICY_SET_DEFAULT_QUOTA_LIMITS;
  else
    Result := 0;
  end;
end;

end.
