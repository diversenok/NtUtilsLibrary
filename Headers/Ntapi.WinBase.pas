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

  // SDK::WinNls.h - time format flags
  TIME_NOMINUTESORSECONDS = $00000001;
  TIME_NOSECONDS = $00000002;
  TIME_NOTIMEMARKER = $00000004;
  TIME_FORCE24HOURFORMAT = $00000008;

  // SDK::WinNls.h - date format flags
  DATE_SHORTDATE = $00000001;
  DATE_LONGDATE = $00000002;
  DATE_USE_ALT_CALENDAR = $00000004;
  DATE_YEARMONTH = $00000008;
  DATE_LTRREADING = $00000010;
  DATE_RTLREADING = $00000020;
  DATE_AUTOLAYOUT = $00000040;
  DATE_MONTHDAY = $00000080; // Windows 10 TH1+

  // SDK::WinBase.h - application restart flags
  RESTART_NO_CRASH = $1;
  RESTART_NO_HANG = $2;
  RESTART_NO_PATCH = $4;
  RESTART_NO_REBOOT = $8;

  // SDK::WinBase.h - application restart maximum command line length
  RESTART_MAX_CMD_LINE = 1024;

type
  [SubEnum(VOLUME_NAME_MASK, VOLUME_NAME_DOS, 'DOS Volume Name')]
  [SubEnum(VOLUME_NAME_MASK, VOLUME_NAME_GUID, 'GUID Volume Name')]
  [SubEnum(VOLUME_NAME_MASK, VOLUME_NAME_NT, 'NT Volume Name')]
  [SubEnum(VOLUME_NAME_MASK, VOLUME_NAME_NONE, 'No Volume Name')]
  [SubEnum(FILE_NAME_MASK, FILE_NAME_NORMALIZED, 'Normalized')]
  [SubEnum(FILE_NAME_MASK, FILE_NAME_OPENED, 'Opened')]
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

  // SDK::WTypesbase.h
  [SDKName('SYSTEMTIME')]
  TSystemTime = record
    Year: Word;
    Month: Word;
    DayOfWeek: Word;
    Day: Word;
    Hour: Word;
    Minute: Word;
    Second: Word;
    Milliseconds: Word;
  end;
  PSystemTime = ^TSystemTime;

  TSystemTimeArray = TAnysizeArray<TSystemTime>;
  PSystemTimeArray = ^TSystemTimeArray;

  [FlagName(TIME_NOMINUTESORSECONDS, 'No Minutes Or Seconds')]
  [FlagName(TIME_NOSECONDS, 'No Seconds')]
  [FlagName(TIME_NOTIMEMARKER, 'No Time Marker')]
  [FlagName(TIME_FORCE24HOURFORMAT, 'Force 24-hour Format')]
  TTimeFormatFlags = type Cardinal;

  [FlagName(DATE_SHORTDATE, 'Short Date')]
  [FlagName(DATE_LONGDATE, 'Long Date')]
  [FlagName(DATE_USE_ALT_CALENDAR, 'Use Alternative Calendar')]
  [FlagName(DATE_YEARMONTH, 'Year-Month Format')]
  [FlagName(DATE_LTRREADING, 'LTR Reading')]
  [FlagName(DATE_RTLREADING, 'RTL Reading')]
  [FlagName(DATE_AUTOLAYOUT, 'Auto Layout')]
  [FlagName(DATE_MONTHDAY, 'Month-Day Format')]
  TDateFormatFlags = type Cardinal;

  [FlagName(RESTART_NO_CRASH, 'No Crash')]
  [FlagName(RESTART_NO_HANG, 'No Hang')]
  [FlagName(RESTART_NO_PATCH, 'No Patch')]
  [FlagName(RESTART_NO_REBOOT, 'No Reboot')]
  TApplicationRestartFlags = type Cardinal;
  PApplicationRestartFlags = ^TApplicationRestartFlags;

  // SDK::WinBase.h
  [Result: Reserved(0)]
  [SDKName('APPLICATION_RECOVERY_CALLBACK')]
  TApplicationRecoveryCallback = function (
    [in] Parameter: Pointer
  ): Cardinal; stdcall;

// SDK::WinBase.h
function LocalFree(
  [in, opt] hMem: Pointer
): Pointer; stdcall; external kernel32;

// SDK::debugapi.h
procedure OutputDebugStringW(
  [in, opt] OutputString: PWideChar
); stdcall; external kernel32;

// SDK::datetimeapi.h
[Result: NumberOfElements]
function GetTimeFormatEx(
  [in, opt] LocaleName: PWideChar;
  [in] Flags: TTimeFormatFlags;
  [in, opt] Time: PSystemTime;
  [in, opt] Format: PWideChar;
  [out, WritesTo] TimeStr: PWideChar;
  [in, NumberOfElements] cchTime: Integer
): Integer; stdcall; external kernel32;

// SDK::datetimeapi.h
[Result: NumberOfElements]
function GetDateFormatEx(
  [in, opt] LocaleName: PWideChar;
  [in] Flags: TDateFormatFlags;
  [in, opt] Date: PSystemTime;
  [in, opt] Format: PWideChar;
  [out, WritesTo] DateStr: PWideChar;
  [in, NumberOfElements] cchDate: Integer;
  [Reserved] Calendar: Pointer
): Integer; stdcall; external kernel32;

// SDK::securitybaseapi.h
[SetsLastError]
function CreateWellKnownSid(
  [in] WellKnownSidType: TWellKnownSidType;
  [in, opt] DomainSid: PSid;
  [out, WritesTo] Sid: PSid;
  [in, out, NumberOfBytes] var cbSid: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::WinBase.h
[SetsLastError]
function LogonUserW(
  [in] Username: PWideChar;
  [in, opt] Domain: PWideChar;
  [in, opt] Password: PWideChar;
  [in] LogonType: TSecurityLogonType;
  [in] LogonProvider: TLogonProvider;
  [out, ReleaseWith('NtClose')] out hToken: THandle
): LongBool; stdcall; external advapi32;

// MSDocs::desktop-src/SecAuthN/LogonUserExExW.md
[SetsLastError]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function LogonUserExExW(
  [in] Username: PWideChar;
  [in, opt] Domain: PWideChar;
  [in, opt] Password: PWideChar;
  [in] LogonType: TSecurityLogonType;
  [in] LogonProvider: TLogonProvider;
  [in, opt] TokenGroups: PTokenGroups;
  [out, ReleaseWith('NtClose')] out hToken: THandle;
  [out, opt, ReleaseWith('LocalFree')] ppLogonSid: PPSid;
  [out, opt, ReleaseWith('LocalFree')] pProfileBuffer: PPointer;
  [out, opt, NumberOfBytes] pProfileLength: PCardinal;
  [out, opt] QuotaLimits: PQuotaLimits
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
[SetsLastError]
function ConvertSidToStringSidW(
  [in] Sid: PSid;
  [out, ReleaseWith('LocalFree')] out StringSid: PWideChar
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
[SetsLastError]
function ConvertStringSidToSidW(
  [in] StringSid: PWideChar;
  [out, ReleaseWith('LocalFree')] out Sid: PSid
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
[SetsLastError]
function ConvertSecurityDescriptorToStringSecurityDescriptorW(
  [in] SecurityDescriptor: PSecurityDescriptor;
  [in] RequestedStringSDRevision: Cardinal;
  [in] SecurityInformation: TSecurityInformation;
  [out, ReleaseWith('LocalFree')] out StringSecurityDescriptor: PWideChar;
  [out, opt] StringSecurityDescriptorLen: PCardinal
): LongBool; stdcall; external advapi32;

// SDK::sddl.h
[SetsLastError]
function ConvertStringSecurityDescriptorToSecurityDescriptorW(
  [in] StringSecurityDescriptor: PWideChar;
  [in] StringSDRevision: Cardinal;
  [out, ReleaseWith('LocalFree')] out SecurityDescriptor: PSecurityDescriptor;
  [out, opt] SecurityDescriptorSize: PCardinal
): LongBool; stdcall; external advapi32;

// SDK::fileapi.h
[SetsLastError]
[Result: NumberOfElements]
function GetFinalPathNameByHandleW(
  [in] hFile: THandle;
  [out, WritesTo] FilePath: PWideChar;
  [in, NumberOfElements] cchFilePath: Cardinal;
  [in] Flags: TFileFinalNameFlags
): Cardinal; stdcall; external kernel32;

// SDK::WinBase.h
[Result: ReleaseWith('UnregisterApplicationRestart')]
function RegisterApplicationRestart(
  [in, opt] Commandline: PWideChar;
  [in] Flags: TApplicationRestartFlags
): HResult; stdcall; external kernel32;

// SDK::WinBase.h
function UnregisterApplicationRestart(
): HResult; stdcall; external kernel32;

// SDK::WinBase.h
function GetApplicationRestartSettings(
  [in, Access(PROCESS_VM_READ)] hProcess: THandle;
  [out, WritesTo] Commandline: PWideChar;
  [in, out, NumberOfElements] var Size: Cardinal;
  [out, opt] Flags: PApplicationRestartFlags
): HResult; stdcall; external kernel32;

// SDK::WinBase.h
[Result: ReleaseWith('UnregisterApplicationRecoveryCallback')]
function RegisterApplicationRecoveryCallback(
  [in] RecoveryCallback: TApplicationRecoveryCallback;
  [in, opt] Parameter: Pointer;
  [in] PingInterval: Cardinal;
  [Reserved] Flags: Cardinal
): HResult; stdcall; external kernel32;

// SDK::WinBase.h
function UnregisterApplicationRecoveryCallback(
): HResult; stdcall; external kernel32;

// SDK::WinBase.h
function ApplicationRecoveryInProgress(
  out Cancelled: LongBool
): HResult; stdcall; external kernel32;

// SDK::WinBase.h
procedure ApplicationRecoveryFinished(
  Success: LongBool
); stdcall; external kernel32;

// SDK::WinBase.h
function GetApplicationRecoveryCallback(
  [in, Access(PROCESS_VM_READ)] hProcess: THandle;
  [out] out RecoveryCallback: TApplicationRecoveryCallback;
  [out] out Parameter: Pointer;
  [out, opt] PingInterval: PCardinal;
  [out, opt] Flags: PCardinal
): HResult; stdcall; external kernel32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
