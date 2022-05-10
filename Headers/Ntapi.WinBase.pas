unit Ntapi.WinBase;

{
  This file includes some miscellaneous definitions.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.NtSecApi, Ntapi.ntseapi, DelphiApi.Reflection;

const
  // SDK::WinBase.h, flags for GetFinalPathNameByHandle
  VOLUME_NAME_DOS = $0000;
  VOLUME_NAME_GUID = $0001;
  VOLUME_NAME_NT = $00002;
  VOLUME_NAME_NONE = $0004;
  VOLUME_NAME_MASK = VOLUME_NAME_GUID or VOLUME_NAME_NT or VOLUME_NAME_NONE;

  FILE_NAME_NORMALIZED = $0000;
  FILE_NAME_OPENED = $0008;
  FILE_NAME_MASK = FILE_NAME_OPENED;

type
  [SubEnum($7, VOLUME_NAME_DOS, 'DOS Volume Name')]
  [FlagName(VOLUME_NAME_GUID, 'GUID Volume Name')]
  [FlagName(VOLUME_NAME_NT, 'NT Volume Name')]
  [FlagName(VOLUME_NAME_NONE, 'No Volume Name')]
  [SubEnum($8, FILE_NAME_NORMALIZED, 'Normalized')]
  [SubEnum($8, FILE_NAME_OPENED, 'Opened')]
  TFileFinalNameFlags = type Cardinal;

  // SDK::winnt.h
  {$SCOPEDENUMS ON}
  [SDKName('WELL_KNOWN_SID_TYPE')]
  [NamingStyle(nsCamelCase, 'Win')]
  TWellKnownSidType = (
    WinNullSid = 0,
    WinWorldSid = 1,
    WinLocalSid = 2,
    WinCreatorOwnerSid = 3,
    WinCreatorGroupSid = 4,
    WinCreatorOwnerServerSid = 5,
    WinCreatorGroupServerSid = 6,
    WinNtAuthoritySid = 7,
    WinDialupSid = 8,
    WinNetworkSid = 9,
    WinBatchSid = 10,
    WinInteractiveSid = 11,
    WinServiceSid = 12,
    WinAnonymousSid = 13,
    WinProxySid = 14,
    WinEnterpriseControllersSid = 15,
    WinSelfSid = 16,
    WinAuthenticatedUserSid = 17,
    WinRestrictedCodeSid = 18,
    WinTerminalServerSid = 19,
    WinRemoteLogonIdSid = 20,
    WinLogonIdsSid = 21,
    WinLocalSystemSid = 22,
    WinLocalServiceSid = 23,
    WinNetworkServiceSid = 24,
    WinBuiltinDomainSid = 25,
    WinBuiltinAdministratorsSid = 26,
    WinBuiltinUsersSid = 27,
    WinBuiltinGuestsSid = 28,
    WinBuiltinPowerUsersSid = 29,
    WinBuiltinAccountOperatorsSid = 30,
    WinBuiltinSystemOperatorsSid = 31,
    WinBuiltinPrintOperatorsSid = 32,
    WinBuiltinBackupOperatorsSid = 33,
    WinBuiltinReplicatorSid = 34,
    WinBuiltinPreWindows2000CompatibleAccessSid = 35,
    WinBuiltinRemoteDesktopUsersSid = 36,
    WinBuiltinNetworkConfigurationOperatorsSid = 37,
    WinAccountAdministratorSid = 38,
    WinAccountGuestSid = 39,
    WinAccountKrbtgtSid = 40,
    WinAccountDomainAdminsSid = 41,
    WinAccountDomainUsersSid = 42,
    WinAccountDomainGuestsSid = 43,
    WinAccountComputersSid = 44,
    WinAccountControllersSid = 45,
    WinAccountCertAdminsSid = 46,
    WinAccountSchemaAdminsSid = 47,
    WinAccountEnterpriseAdminsSid = 48,
    WinAccountPolicyAdminsSid = 49,
    WinAccountRasAndIasServersSid = 50,
    WinNTLMAuthenticationSid = 51,
    WinDigestAuthenticationSid = 52,
    WinSChannelAuthenticationSid = 53,
    WinThisOrganizationSid = 54,
    WinOtherOrganizationSid = 55,
    WinBuiltinIncomingForestTrustBuildersSid = 56,
    WinBuiltinPerfMonitoringUsersSid = 57,
    WinBuiltinPerfLoggingUsersSid = 58,
    WinBuiltinAuthorizationAccessSid = 59,
    WinBuiltinTerminalServerLicenseServersSid = 60,
    WinBuiltinDCOMUsersSid = 61,
    WinBuiltinIUsersSid = 62,
    WinIUserSid = 63,
    WinBuiltinCryptoOperatorsSid = 64,
    WinUntrustedLabelSid = 65,
    WinLowLabelSid = 66,
    WinMediumLabelSid = 67,
    WinHighLabelSid = 68,
    WinSystemLabelSid = 69,
    WinWriteRestrictedCodeSid = 70,
    WinCreatorOwnerRightsSid = 71,
    WinCacheablePrincipalsGroupSid = 72,
    WinNonCacheablePrincipalsGroupSid = 73,
    WinEnterpriseReadonlyControllersSid = 74,
    WinAccountReadonlyControllersSid = 75,
    WinBuiltinEventLogReadersGroup = 76,
    WinNewEnterpriseReadonlyControllersSid = 77,
    WinBuiltinCertSvcDComAccessGroup = 78,
    WinMediumPlusLabelSid = 79,
    WinLocalLogonSid = 80,
    WinConsoleLogonSid = 81,
    WinThisOrganizationCertificateSid = 82,
    WinApplicationPackageAuthoritySid = 83,
    WinBuiltinAnyPackageSid = 84,
    WinCapabilityInternetClientSid = 85,
    WinCapabilityInternetClientServerSid = 86,
    WinCapabilityPrivateNetworkClientServerSid = 87,
    WinCapabilityPicturesLibrarySid = 88,
    WinCapabilityVideosLibrarySid = 89,
    WinCapabilityMusicLibrarySid = 90,
    WinCapabilityDocumentsLibrarySid = 91,
    WinCapabilitySharedUserCertificatesSid = 92,
    WinCapabilityEnterpriseAuthenticationSid = 93,
    WinCapabilityRemovableStorageSid = 94,
    WinBuiltinRDSRemoteAccessServersSid = 95,
    WinBuiltinRDSEndpointServersSid = 96,
    WinBuiltinRDSManagementServersSid = 97,
    WinUserModeDriversSid = 98,
    WinBuiltinHyperVAdminsSid = 99,
    WinAccountCloneableControllersSid = 100,
    WinBuiltinAccessControlAssistanceOperatorsSid = 101,
    WinBuiltinRemoteManagementUsersSid = 102,
    WinAuthenticationAuthorityAssertedSid = 103,
    WinAuthenticationServiceAssertedSid = 104,
    WinLocalAccountSid = 105,
    WinLocalAccountAndAdministratorSid = 106,
    WinAccountProtectedUsersSid = 107,
    WinCapabilityAppointmentsSid = 108,
    WinCapabilityContactsSid = 109,
    WinAccountDefaultSystemManagedSid = 110,
    WinBuiltinDefaultSystemManagedGroupSid = 111,
    WinBuiltinStorageReplicaAdminsSid = 112,
    WinAccountKeyAdminsSid = 113,
    WinAccountEnterpriseKeyAdminsSid = 114,
    WinAuthenticationKeyTrustSid = 115,
    WinAuthenticationKeyPropertyMFASid = 116,
    WinAuthenticationKeyPropertyAttestationSid = 117,
    WinAuthenticationFreshKeyAuthSid = 118,
    WinBuiltinDeviceOwnersSid = 119
  );
  {$SCOPEDENUMS OFF}

  // SDK::WinBase.h
  [NamingStyle(nsSnakeCase, 'LOGON32_PROVIDER')]
  TLogonProvider = (
    LOGON32_PROVIDER_DEFAULT = 0,
    LOGON32_PROVIDER_WINNT35 = 1,
    LOGON32_PROVIDER_WINNT40 = 2,
    LOGON32_PROVIDER_WINNT50 = 3,
    LOGON32_PROVIDER_VIRTUAL = 4
  );

  PPSid = ^PSid;

  // SDK::minwinbase.h
  [SDKName('SECURITY_ATTRIBUTES')]
  TSecurityAttributes = record
    [Bytes, Unlisted] Length: Cardinal;
    SecurityDescriptor: PSecurityDescriptor;
    InheritHandle: LongBool;
  end;
  PSecurityAttributes = ^TSecurityAttributes;

// SDK::WinBase.h
function LocalFree(
  [in, opt] hMem: Pointer
): Pointer; stdcall; external kernel32;

// SDK::debugapi.h
procedure OutputDebugStringW(
  [in, opt] OutputString: PWideChar
); stdcall; external kernel32;

// SDK::securitybaseapi.h
function CreateWellKnownSid(
  WellKnownSidType: TWellKnownSidType;
  [in, opt] DomainSid: PSid;
  [out, opt] Sid: PSid;
  var cbSid: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::WinBase.h
function LogonUserW(
  [in] Username: PWideChar;
  [in, opt] Domain: PWideChar;
  [in, opt] Password: PWideChar;
  LogonType: TSecurityLogonType;
  LogonProvider: TLogonProvider;
  out hToken: THandle
): LongBool; stdcall; external advapi32;

// MSDocs::desktop-src/SecAuthN/LogonUserExExW.md
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function LogonUserExExW(
  [in] Username: PWideChar;
  [in, opt] Domain: PWideChar;
  [in, opt] Password: PWideChar;
  LogonType: TSecurityLogonType;
  LogonProvider: TLogonProvider;
  [in, opt] TokenGroups: PTokenGroups;
  out hToken: THandle;
  [out, opt, allocates('LocalFree')] ppLogonSid: PPSid;
  [out, opt, allocates('LocalFree')] pProfileBuffer: PPointer;
  [out, opt] pProfileLength: PCardinal;
  [out, opt] QuotaLimits: PQuotaLimits
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertSidToStringSidW(
  [in] Sid: PSid;
  [allocates('LocalFree')] out StringSid: PWideChar
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertStringSidToSidW(
  [in] StringSid: PWideChar;
  [allocates('LocalFree')] out Sid: PSid
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertSecurityDescriptorToStringSecurityDescriptorW(
  [in] SecurityDescriptor: PSecurityDescriptor;
  RequestedStringSDRevision: Cardinal;
  SecurityInformation: TSecurityInformation;
  [allocates('LocalFree')] out StringSecurityDescriptor: PWideChar;
  [out, opt] StringSecurityDescriptorLen: PCardinal
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
function ConvertStringSecurityDescriptorToSecurityDescriptorW(
  [in] StringSecurityDescriptor: PWideChar;
  StringSDRevision: Cardinal;
  [allocates('LocalFree')] out SecurityDescriptor: PSecurityDescriptor;
  [out, opt] SecurityDescriptorSize: PCardinal
): LongBool; stdcall; external advapi32;

// SDK::fileapi.h
[Result: Counter(ctElements)]
function GetFinalPathNameByHandleW(
  hFile: THandle;
  [in] FilePath: PWideChar;
  [Counter(ctElements)] ccbFilePath: Cardinal;
  Flags: TFileFinalNameFlags
): Cardinal; stdcall; external kernel32;

implementation

end.
