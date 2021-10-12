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

  // SDK::ntlsa.h - names for logon rights
  SE_INTERACTIVE_LOGON_NAME = 'SeInteractiveLogonRight';
  SE_NETWORK_LOGON_NAME = 'SeNetworkLogonRight';
  SE_BATCH_LOGON_NAME = 'SeBatchLogonRight';
  SE_SERVICE_LOGON_NAME = 'SeServiceLogonRight';
  SE_DENY_INTERACTIVE_LOGON_NAME = 'SeDenyInteractiveLogonRight';
  SE_DENY_NETWORK_LOGON_NAME = 'SeDenyNetworkLogonRight';
  SE_DENY_BATCH_LOGON_NAME = 'SeDenyBatchLogonRight';
  SE_DENY_SERVICE_LOGON_NAME = 'SeDenyServiceLogonRight';
  SE_REMOTE_INTERACTIVE_LOGON_NAME = 'SeRemoteInteractiveLogonRight';
  SE_DENY_REMOTE_INTERACTIVE_LOGON_NAME = 'SeDenyRemoteInteractiveLogonRight';

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

// SDK::ntlsa.h
function LsaFreeMemory(
  [in, opt] Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaClose(
  ObjectHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaDelete(
  [Access(_DELETE)] ObjectHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] ObjectHandle: TLsaHandle;
  SecurityInformation: TSecurityInformation;
  [allocates('LsaFreeMemory')] out SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external advapi32;

// 3031
function LsaSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] ObjectHandle: TLsaHandle;
  SecurityInformation: TSecurityInformation;
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaOpenPolicy(
  [in, opt] SystemName: PLsaUnicodeString;
  const ObjectAttributes: TObjectAttributes;
  DesiredAccess: TLsaPolicyAccessMask;
  out PolicyHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaQueryInformationPolicy(
  [Access(POLICY_VIEW_LOCAL_INFORMATION or
    POLICY_VIEW_AUDIT_INFORMATION)] PolicyHandle: TLsaHandle;
  InformationClass: TPolicyInformationClass;
  [allocates('LsaFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetInformationPolicy(
  [Access(POLICY_TRUST_ADMIN or POLICY_AUDIT_LOG_ADMIN or
    POLICY_SET_AUDIT_REQUIREMENTS or POLICY_SERVER_ADMIN or
    POLICY_SET_DEFAULT_QUOTA_LIMITS)] PolicyHandle: TLsaHandle;
  InformationClass: TPolicyInformationClass;
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaQueryDomainInformationPolicy(
  [Access(POLICY_VIEW_LOCAL_INFORMATION or
    POLICY_VIEW_AUDIT_INFORMATION)] PolicyHandle: TLsaHandle;
  InformationClass: TPolicyDomainInformationClass;
  [allocates('LsaFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetDomainInformationPolicy(
  [Access(POLICY_SERVER_ADMIN)] PolicyHandle: TLsaHandle;
  InformationClass: TPolicyDomainInformationClass;
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaRegisterPolicyChangeNotification(
  InformationClass: TPolicyNotificationInformationClass;
  NotificationEventHandle: THandle
): NTSTATUS; stdcall; external secur32;

// SDK::ntlsa.h
function LsaUnregisterPolicyChangeNotification(
  InformationClass: TPolicyNotificationInformationClass;
  NotificationEventHandle: THandle
): NTSTATUS; stdcall; external secur32;

// SDK::ntlsa.h
function LsaCreateAccount(
  [Access(POLICY_CREATE_ACCOUNT)] PolicyHandle: TLsaHandle;
  [in] AccountSid: PSid;
  DesiredAccess: TLsaAccountAccessMask;
  out AccountHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaEnumerateAccounts(
  [Access(POLICY_VIEW_LOCAL_INFORMATION)] PolicyHandle: TLsaHandle;
  var EnumerationContext: TLsaEnumerationHandle;
  [allocates('LsaFreeMemory')] out Buffer: PSidArray;
  PreferedMaximumLength: Integer;
  out CountReturned: Integer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaEnumeratePrivileges(
  [Access(POLICY_VIEW_LOCAL_INFORMATION)] PolicyHandle: TLsaHandle;
  var EnumerationContext: TLsaEnumerationHandle;
  [allocates('LsaFreeMemory')] out Buffer: PPolicyPrivilegeDefinitionArray;
  PreferedMaximumLength: Integer;
  out CountReturned: Integer
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupNames2(
  [Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  Flags: TLsaLookupNamesFlags;
  Count: Integer;
  const Name: TLsaUnicodeString;
  [allocates('LsaFreeMemory')] out ReferencedDomain: PLsaReferencedDomainList;
  [allocates('LsaFreeMemory')] out Sid: PLsaTranslatedSid2Array
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupSids(
  [Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  Count: Cardinal;
  Sids: TArray<PSid>;
  [allocates('LsaFreeMemory')] out ReferencedDomains: PLsaReferencedDomainList;
  [allocates('LsaFreeMemory')] out Names: PLsaTranslatedNameArray
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupSids2(
  [Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  LookupOptions: TLsaLookupSidsFlags;
  Count: Cardinal;
  [in] Sids: TArray<PSid>;
  [allocates('LsaFreeMemory')] out ReferencedDomains: PLsaReferencedDomainList;
  [allocates('LsaFreeMemory')] out Names: PLsaTranslatedNameArray
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaOpenAccount(
  [Access(POLICY_VIEW_LOCAL_INFORMATION)] PolicyHandle: TLsaHandle;
  [in] AccountSid: PSid;
  DesiredAccess: TLsaAccountAccessMask;
  out AccountHandle: TLsaHandle
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaEnumeratePrivilegesOfAccount(
  [Access(ACCOUNT_VIEW)] AccountHandle: TLsaHandle;
  [allocates('LsaFreeMemory')] out Privileges: PPrivilegeSet
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaAddPrivilegesToAccount(
  [Access(ACCOUNT_ADJUST_PRIVILEGES)] AccountHandle: TLsaHandle;
  [in] Privileges: PPrivilegeSet
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaRemovePrivilegesFromAccount(
  [Access(ACCOUNT_ADJUST_PRIVILEGES)] AccountHandle: TLsaHandle;
  AllPrivileges: Boolean;
  [in, opt] Privileges: PPrivilegeSet
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaGetQuotasForAccount(
  [Access(ACCOUNT_VIEW)] AccountHandle: TLsaHandle;
  out QuotaLimits: TQuotaLimits
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetQuotasForAccount(
  [Access(ACCOUNT_ADJUST_QUOTAS)] AccountHandle: TLsaHandle;
  const QuotaLimits: PQuotaLimits
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaGetSystemAccessAccount(
  [Access(ACCOUNT_VIEW)] AccountHandle: TLsaHandle;
  out SystemAccess: TSystemAccess
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaSetSystemAccessAccount(
  [Access(ACCOUNT_ADJUST_SYSTEM_ACCESS)] AccountHandle: TLsaHandle;
  SystemAccess: TSystemAccess
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupPrivilegeValue(
  [Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  const Name: TLsaUnicodeString;
  out Value: TLuid
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupPrivilegeName(
  [Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  const [ref] Value: TLuid;
  [allocates('LsaFreeMemory')] out Name: PLsaUnicodeString
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaLookupPrivilegeDisplayName(
  [Access(POLICY_LOOKUP_NAMES)] PolicyHandle: TLsaHandle;
  const Name: TLsaUnicodeString;
  [allocates('LsaFreeMemory')] out DisplayName: PLsaUnicodeString;
  out LanguageReturned: Smallint
): NTSTATUS; stdcall; external advapi32;

// SDK::ntlsa.h
function LsaGetUserName(
  [allocates('LsaFreeMemory')] out UserName: PLsaUnicodeString;
  [allocates('LsaFreeMemory')] out DomainName: PLsaUnicodeString
): NTSTATUS; stdcall; external advapi32;

// DDK::lsalookupi.h (aka LsaLookupManageSidNameMapping)
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function LsaManageSidNameMapping(
  OpType: TLsaSidNameMappingOperationType;
  const OpInput: TLsaSidNameMappingOperation;
  [allocates('LsaFreeMemory')] out OpOutput:
    PLsaSidNameMappingOperationGenericOutput
): NTSTATUS; stdcall; external advapi32;

{ Expected Access Masks }

function ExpectedPolicyQueryAccess(
  InfoClass: TPolicyInformationClass
): TLsaPolicyAccessMask;

function ExpectedPolicySetAccess(
  InfoClass: TPolicyInformationClass
): TLsaPolicyAccessMask;

implementation

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
