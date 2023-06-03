unit Ntapi.ProcessThreadsApi;

{
  This module includes functions for creating processes via Win32 API.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.WinBase, DelphiApi.Reflection, Ntapi.ConsoleApi,
  Ntapi.ntseapi, Ntapi.WinUser, Ntapi.Versions;

const
  // SDK::WinBase.h - process creation flags
  DEBUG_PROCESS = $00000001;
  DEBUG_ONLY_THIS_PROCESS = $00000002;
  CREATE_SUSPENDED = $00000004;
  DETACHED_PROCESS = $00000008;
  CREATE_NEW_CONSOLE = $00000010;
  CREATE_NEW_PROCESS_GROUP = $00000200;
  CREATE_UNICODE_ENVIRONMENT = $00000400;
  CREATE_PROTECTED_PROCESS = $00040000;
  EXTENDED_STARTUPINFO_PRESENT = $00080000;
  CREATE_SECURE_PROCESS = $00400000;
  CREATE_BREAKAWAY_FROM_JOB = $01000000;
  CREATE_DEFAULT_ERROR_MODE = $04000000;
  CREATE_NO_WINDOW = $08000000;
  PROFILE_USER = $10000000;
  PROFILE_KERNEL = $20000000;
  PROFILE_SERVER = $40000000;
  CREATE_IGNORE_SYSTEM_DEFAULT = $80000000;

  // SDK::WinBase.h - startup info flags
  STARTF_USESHOWWINDOW = $00000001;
  STARTF_USESIZE = $00000002;
  STARTF_USEPOSITION = $00000004;
  STARTF_USECOUNTCHARS = $00000008;
  STARTF_USEFILLATTRIBUTE = $00000010;
  STARTF_RUNFULLSCREEN = $00000020;
  STARTF_FORCEONFEEDBACK = $00000040;
  STARTF_FORCEOFFFEEDBACK = $00000080;
  STARTF_USESTDHANDLES = $00000100;
  STARTF_USEHOTKEY = $00000200;
  STARTF_TITLEISLINKNAME = $00000800;
  STARTF_TITLEISAPPID = $00001000;
  STARTF_PREVENTPINNING = $00002000;
  STARTF_UNTRUSTEDSOURCE = $00008000;

  // Process/thread attributes

  // SDK::winbasep.h - attribute 1
  EXTENDED_PROCESS_CREATION_FLAG_ELEVATION_HANDLED = $00000001;
  EXTENDED_PROCESS_CREATION_FLAG_FORCELUA = $00000002;
  EXTENDED_PROCESS_CREATION_FLAG_FORCE_BREAKAWAY = $00000004; // Win 8.1+, requires SeTcb

  // SDK::WinBase.h, attribute 14, Win 10 TH2+
  PROCESS_CREATION_CHILD_PROCESS_RESTRICTED = $01;
  PROCESS_CREATION_CHILD_PROCESS_OVERRIDE = $02;
  PROCESS_CREATION_CHILD_PROCESS_RESTRICTED_UNLESS_SECURE = $04;

  // SDK::WinBase.h, attribute 18, Win 10 RS2+
  PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_ENABLE_PROCESS_TREE = $01;
  PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_DISABLE_PROCESS_TREE = $02;
  PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_OVERRIDE = $04;

  // Mitigation policies

  // SDK::WinBase.h
  MITIGATION_POLICY_DEP_ENABLE = $01;
  MITIGATION_POLICY_DEP_ATL_THUNK_ENABLE = $02;
  MITIGATION_POLICY_SEHOP_ENABLE = $04;

  // SDK::WinBase.h, Win 8+
  MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_ON  = $1 shl 8;
  MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_OFF = $2 shl 8;
  MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_ON_REQ_RELOCS = $3 shl 8;

  MITIGATION_POLICY_HEAP_TERMINATE_ALWAYS_ON  = $1 shl 12;
  MITIGATION_POLICY_HEAP_TERMINATE_ALWAYS_OFF = $2 shl 12;

  MITIGATION_POLICY_BOTTOM_UP_ASLR_ALWAYS_ON  = $1 shl 16;
  MITIGATION_POLICY_BOTTOM_UP_ASLR_ALWAYS_OFF = $2 shl 16;

  MITIGATION_POLICY_HIGH_ENTROPY_ASLR_ALWAYS_ON  = $1 shl 20;
  MITIGATION_POLICY_HIGH_ENTROPY_ASLR_ALWAYS_OFF = $2 shl 20;

  MITIGATION_POLICY_STRICT_HANDLE_CHECKS_ALWAYS_ON  = $1 shl 24;
  MITIGATION_POLICY_STRICT_HANDLE_CHECKS_ALWAYS_OFF = $2 shl 24;

  MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_ON = $1 shl 28;
  MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_OFF = $2 shl 28;

  MITIGATION_POLICY_EXTENSION_POINT_DISABLE_ALWAYS_ON = UInt64($1) shl 32;
  MITIGATION_POLICY_EXTENSION_POINT_DISABLE_ALWAYS_OFF = UInt64($2) shl 32;
  MITIGATION_POLICY_EXTENSION_POINT_DISABLE_RESERVED = UInt64($3) shl 32;

  // SDK::WinBase.h, Win 8.1+
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON = UInt64($1) shl 36;
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_OFF = UInt64($2) shl 36;
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON_ALLOW_OPT_OUT = UInt64($3) shl 36;

  MITIGATION_POLICY_CONTROL_FLOW_GUARD_ALWAYS_ON = UInt64($1) shl 40;
  MITIGATION_POLICY_CONTROL_FLOW_GUARD_ALWAYS_OFF = UInt64($2) shl 40;
  MITIGATION_POLICY_CONTROL_FLOW_GUARD_EXPORT_SUPPRESSION = UInt64($3) shl 40;

  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_ON = UInt64($1) shl 44;
  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_OFF = UInt64($2) shl 44;
  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALLOW_STORE = UInt64($3) shl 44;

  // SDK::WinBase.h, Win 10 TH1+
  MITIGATION_POLICY_FONT_DISABLE_ALWAYS_ON  = UInt64($1) shl 48;
  MITIGATION_POLICY_FONT_DISABLE_ALWAYS_OFF = UInt64($2) shl 48;
  MITIGATION_POLICY_AUDIT_NONSYSTEM_FONTS   = UInt64($3) shl 48;

  // SDK::WinBase.h, Win 10 TH2+
  MITIGATION_POLICY_IMAGE_LOAD_NO_REMOTE_ALWAYS_ON  = UInt64($1) shl 52;
  MITIGATION_POLICY_IMAGE_LOAD_NO_REMOTE_ALWAYS_OFF = UInt64($2) shl 52;

  MITIGATION_POLICY_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_ON  = UInt64($1) shl 56;
  MITIGATION_POLICY_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_OFF = UInt64($2) shl 56;

  // SDK::WinBase.h, Win 10 RS1+
  MITIGATION_POLICY_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_ON  = UInt64($1) shl 60;
  MITIGATION_POLICY_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_OFF = UInt64($2) shl 60;

  // SDK::WinBase.h, Win 10 RS2+
  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_ALWAYS_ON  = $1 shl 4;
  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_ALWAYS_OFF = $2 shl 4;
  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_AUDIT = $3 shl 4;

  MITIGATION_POLICY2_STRICT_CONTROL_FLOW_GUARD_ALWAYS_ON  = $1 shl 8;
  MITIGATION_POLICY2_STRICT_CONTROL_FLOW_GUARD_ALWAYS_OFF = $2 shl 8;

  // SDK::WinBase.h, Win 10 RS3+
  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_ALWAYS_ON  = $1 shl 12;
  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_ALWAYS_OFF = $2 shl 12;
  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_NOINHERIT  = $3 shl 12;

 // SDK::WinBase.h, Win 10 RS4+
  MITIGATION_POLICY2_RESTRICT_INDIRECT_BRANCH_PREDICTION_ALWAYS_ON  = $1 shl 16;
  MITIGATION_POLICY2_RESTRICT_INDIRECT_BRANCH_PREDICTION_ALWAYS_OFF = $2 shl 16;

  // SDK::WinBase.h, Win 10 RS5+
  MITIGATION_POLICY2_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY_ALWAYS_ON  = $1 shl 20;
  MITIGATION_POLICY2_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY_ALWAYS_OFF = $2 shl 20;

  MITIGATION_POLICY2_SPECULATIVE_STORE_BYPASS_DISABLE_ALWAYS_ON  = $1 shl 24;
  MITIGATION_POLICY2_SPECULATIVE_STORE_BYPASS_DISABLE_ALWAYS_OFF = $2 shl 24;

  // SDK::WinBase.h, Win 10 20H1+
  MITIGATION_POLICY2_CET_USER_SHADOW_STACKS_ALWAYS_ON   = $1 shl 28;
  MITIGATION_POLICY2_CET_USER_SHADOW_STACKS_ALWAYS_OFF  = $2 shl 28;
  MITIGATION_POLICY2_CET_USER_SHADOW_STACKS_STRICT_MODE = $3 shl 28;

  // SDK::WinBase.h, Win 10 21H1+
  MITIGATION_POLICY2_USER_CET_SET_CONTEXT_IP_VALIDATION_ALWAYS_ON    = UInt64($1) shl 32;
  MITIGATION_POLICY2_USER_CET_SET_CONTEXT_IP_VALIDATION_ALWAYS_OFF   = UInt64($2) shl 32;
  MITIGATION_POLICY2_USER_CET_SET_CONTEXT_IP_VALIDATION_RELAXED_MODE = UInt64($3) shl 32;

  MITIGATION_POLICY2_BLOCK_NON_CET_BINARIES_ALWAYS_ON  = UInt64($1) shl 36;
  MITIGATION_POLICY2_BLOCK_NON_CET_BINARIES_ALWAYS_OFF = UInt64($2) shl 36;
  MITIGATION_POLICY2_BLOCK_NON_CET_BINARIES_NON_EHCONT = UInt64($3) shl 36;

  MITIGATION_POLICY2_XTENDED_CONTROL_FLOW_GUARD_ALWAYS_ON  = UInt64($1) shl 40;
  MITIGATION_POLICY2_XTENDED_CONTROL_FLOW_GUARD_ALWAYS_OFF = UInt64($2) shl 40;

  MITIGATION_POLICY2_CET_DYNAMIC_APIS_OUT_OF_PROC_ONLY_ALWAYS_ON  = UInt64($1) shl 48;
  MITIGATION_POLICY2_CET_DYNAMIC_APIS_OUT_OF_PROC_ONLY_ALWAYS_OFF = UInt64($2) shl 48;

  // Other process/thread attributes

  // SDK::WinBase.h, Win 10 RS1+
  PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT = $01;

  // SDK::WinBase.h
  PROC_THREAD_ATTRIBUTE_REPLACE_VALUE = $00000001;

  // For annotations
  TOKEN_CREATE_PROCESS = TOKEN_ASSIGN_PRIMARY or TOKEN_QUERY;
  TOKEN_CREATE_PROCESS_EX = TOKEN_DUPLICATE or TOKEN_IMPERSONATE or TOKEN_QUERY
    or TOKEN_ASSIGN_PRIMARY or TOKEN_ADJUST_DEFAULT or TOKEN_ADJUST_SESSIONID;

  // SDK::WinBase.h
  LOGON_WITH_PROFILE = $00000001;
  LOGON_NETCREDENTIALS_ONLY = $00000002;
  LOGON_ZERO_PASSWORD_BUFFER = $80000000;

type
  // SDK::processthreadsapi.h
  [SDKName('PROCESS_INFORMATION')]
  TProcessInformation = record
    hProcess: THandle;
    hThread: THandle;
    ProcessId: TProcessId32;
    ThreadId: TThreadId32;
  end;
  PProcessInformation = ^TProcessInformation;

  [FlagName(DEBUG_PROCESS, 'Debug')]
  [FlagName(DEBUG_ONLY_THIS_PROCESS, 'Debug Only This')]
  [FlagName(CREATE_SUSPENDED, 'Suspended')]
  [FlagName(DETACHED_PROCESS, 'Detached')]
  [FlagName(CREATE_NEW_CONSOLE, 'New Console')]
  [FlagName(CREATE_NEW_PROCESS_GROUP, 'New Process Group')]
  [FlagName(CREATE_UNICODE_ENVIRONMENT, 'Unicode Environment')]
  [FlagName(CREATE_PROTECTED_PROCESS, 'Protected')]
  [FlagName(EXTENDED_STARTUPINFO_PRESENT, 'Extended Startup Info')]
  [FlagName(CREATE_SECURE_PROCESS, 'Secure')]
  [FlagName(CREATE_BREAKAWAY_FROM_JOB, 'Breakaway From Job')]
  [FlagName(CREATE_DEFAULT_ERROR_MODE, 'Default Error Mode')]
  [FlagName(CREATE_NO_WINDOW, 'No Window')]
  [FlagName(PROFILE_USER, 'Profile User')]
  [FlagName(PROFILE_KERNEL, 'Profile Kernel')]
  [FlagName(PROFILE_SERVER, 'Profile Server')]
  [FlagName(CREATE_IGNORE_SYSTEM_DEFAULT, 'Ignore System Default')]
  TProcessCreateFlags = type Cardinal;

  [FlagName(STARTF_USESHOWWINDOW, 'Use Show Window')]
  [FlagName(STARTF_USESIZE, 'Use Size')]
  [FlagName(STARTF_USEPOSITION, 'Use Position')]
  [FlagName(STARTF_USECOUNTCHARS, 'Use Count Chars')]
  [FlagName(STARTF_USEFILLATTRIBUTE, 'Use Fill Attribute')]
  [FlagName(STARTF_RUNFULLSCREEN, 'Run Fullscreen')]
  [FlagName(STARTF_FORCEONFEEDBACK, 'Force ON Feedback')]
  [FlagName(STARTF_FORCEOFFFEEDBACK, 'Force OFF Feedback')]
  [FlagName(STARTF_USESTDHANDLES, 'Use STD Handles')]
  [FlagName(STARTF_USEHOTKEY, 'Use Hotkey')]
  [FlagName(STARTF_TITLEISLINKNAME, 'Title Is Link Name')]
  [FlagName(STARTF_TITLEISAPPID, 'Title Is AppID')]
  [FlagName(STARTF_PREVENTPINNING, 'Prevent Pinning')]
  [FlagName(STARTF_UNTRUSTEDSOURCE, 'Untrusted Source')]
  TStarupFlags = type Cardinal;

  // SDK::processthreadsapi.h
  [SDKName('STARTUPINFOW')]
  TStartupInfoW = record
    [Bytes, Unlisted] cb: Cardinal;
    [Unlisted] Reserved: PWideChar;
    Desktop: PWideChar;
    Title: PWideChar;
    X: Cardinal;
    Y: Cardinal;
    XSize: Cardinal;
    YSize: Cardinal;
    XCountChars: Cardinal;
    YCountChars: Cardinal;
    FillAttribute: TConsoleFill;
    Flags: TStarupFlags;
    ShowWindow: TShowMode16;
    [Unlisted] cbReserved2: Word;
    [Unlisted] lpReserved2: PByte;
    hStdInput: THandle;
    hStdOutput: THandle;
    hStdError: THandle;
  end;
  PStartupInfoW = ^TStartupInfoW;

  // PHNT::ntpsapi.h
  [SDKName('PROC_THREAD_ATTRIBUTE_NUM')]
  [NamingStyle(nsCamelCase, 'ProcThreadAttribute'), ValidBits([0..19, 22..28])]
  TProcThreadAttributeNum = (
    ProcThreadAttributeParentProcess = $0,        // THandle with PROCESS_CREATE_PROCESS
    ProcThreadAttributeExtendedFlags = $1,        // TProcExtendedFlag
    ProcThreadAttributeHandleList = $2,           // TAnysizeArray<THandle>
    ProcThreadAttributeGroupAffinity = $3,        // TGroupAffinity
    ProcThreadAttributePreferredNode = $4,        // Word
    ProcThreadAttributeIdealProcessor = $5,
    ProcThreadAttributeUmsThread = $6,
    ProcThreadAttributeMitigationPolicy = $7,     // 32, 64, or 128 bits
    ProcThreadAttributePackageName = $8,          // PWideChar, Win 8+
    ProcThreadAttributeSecurityCapabilities = $9, // TSecurityCapabilities
    ProcThreadAttributeConsoleReference = $A,
    ProcThreadAttributeProtectionLevel = $B,      // TProtectionLevel, Win 8.1+
    ProcThreadAttributeOsMaxVersionTested = $C,   // TMaxVersionTestedInfo, Win 10 TH1+
    ProcThreadAttributeJobList = $D,              // TAnysizeArray<THandle>
    ProcThreadAttributeChildProcessPolicy = $E,   // TProcessChildFlags, Win 10 TH2+
    ProcThreadAttributeAllApplicationPackagesPolicy = $F, // TProcessAllPackagesFlags, Win 10 RS1+
    ProcThreadAttributeWin32kFilter = $10,
    ProcThreadAttributeSafeOpenPromptOriginClaim = $11, // TSeSafeOpenPromptResults
    ProcThreadAttributeDesktopAppPolicy = $12,    // TProcessDesktopAppFlags, Win 10 RS2+
    ProcThreadAttributeBnoIsolation = $13,        // TProcThreadBnoIsolationAttribute
    ProcThreadAttribute20 = $14,                  // PWideChar, Win 10 19H2+ (out of order)
    ProcThreadAttribute21 = $15,                  // Win 10 19H2+ (out of order)
    ProcThreadAttributePseudoConsole = $16,       // THandle, Win 10 RS5+
    ProcThreadAttributeIsolationManifestProperties = $17, // Win 10 19H2+
    ProcThreadAttributeMitigationAuditPolicy = $18, // Win 10 21H1+
    ProcThreadAttributeMachineType = $19,           // Word, Win 11+ (out-of-order) or Win 10 21H2+?
    ProcThreadAttributeComponentFilter = $1A,       // Win 10 21H2+
    ProcThreadAttributeEnableOptionalXStateFeatures = $1B, // Win 11+
    ProcThreadAttributeCreateStore = $1C,           // LongBool // rev
    ProcThreadAttributeTrustedApp = $1D
  );

const
  // SDK::WinBase.h - mask for extracting TProcThreadAttributeNum
  PROC_THREAD_ATTRIBUTE_NUMBER = $0000FFFF;

  // SDK::WinBase.h & PHNT::ntpsapi.h - processess & thread attribute values
  PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = $20000;
  PROC_THREAD_ATTRIBUTE_EXTENDED_FLAGS = $60001;
  PROC_THREAD_ATTRIBUTE_HANDLE_LIST = $20002;
  PROC_THREAD_ATTRIBUTE_GROUP_AFFINITY = $30003;
  PROC_THREAD_ATTRIBUTE_PREFERRED_NODE = $20004;
  PROC_THREAD_ATTRIBUTE_IDEAL_PROCESSOR = $30005;
  PROC_THREAD_ATTRIBUTE_UMS_THREAD = $30006;
  PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY = $20007;
  PROC_THREAD_ATTRIBUTE_PACKAGE_NAME = $20008;
  PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES = $20009;
  PROC_THREAD_ATTRIBUTE_CONSOLE_REFERENCE = $2000A;
  PROC_THREAD_ATTRIBUTE_PROTECTION_LEVEL = $2000B;
  PROC_THREAD_ATTRIBUTE_OS_MAX_VERSION_TESTED = $2000C;
  PROC_THREAD_ATTRIBUTE_JOB_LIST = $2000D;
  PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY = $2000E;
  PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY = $2000F;
  PROC_THREAD_ATTRIBUTE_WIN32K_FILTER = $20010;
  PROC_THREAD_ATTRIBUTE_SAFE_OPEN_PROMPT_ORIGIN_CLAIM = $20011;
  PROC_THREAD_ATTRIBUTE_DESKTOP_APP_POLICY = $20012;
  PROC_THREAD_ATTRIBUTE_BNO_ISOLATION = $20013;
  PROC_THREAD_ATTRIBUTE_20 = $20014;
  PROC_THREAD_ATTRIBUTE_21 = $20015;
  PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE = $20016;
  PROC_THREAD_ATTRIBUTE_ISOLATION_MANIFEST = $20017;
  PROC_THREAD_ATTRIBUTE_MITIGATION_AUDIT_POLICY = $20018;
  PROC_THREAD_ATTRIBUTE_MACHINE_TYPE = $20019;
  PROC_THREAD_ATTRIBUTE_COMPONENT_FILTER = $2001A;
  PROC_THREAD_ATTRIBUTE_ENABLE_OPTIONAL_XSTATE_FEATURES = $3001B;
  PROC_THREAD_ATTRIBUTE_CREATE_STORE = $2001C;
  PROC_THREAD_ATTRIBUTE_TRUSTED_APP = $2001D;

type
  // Attribute 1
  [FlagName(EXTENDED_PROCESS_CREATION_FLAG_ELEVATION_HANDLED, 'Elevation Handled')]
  [FlagName(EXTENDED_PROCESS_CREATION_FLAG_FORCELUA, 'Force LUA')]
  [FlagName(EXTENDED_PROCESS_CREATION_FLAG_FORCE_BREAKAWAY, 'Force Breakaway')]
  TProcExtendedFlag = type Cardinal;

  // SDK::winnt.h - attribute 9
  [MinOSVersion(OsWin8)]
  [SDKName('SECURITY_CAPABILITIES')]
  TSecurityCapabilities = record
    AppContainerSid: PSid;
    Capabilities: PSidAndAttributesArray;
    [Counter] CapabilityCount: Cardinal;
    [Unlisted] Reserved: Cardinal;
  end;
  PSecurityCapabilities = ^TSecurityCapabilities;

  // SDK::winbase.h - attribute $B
  [MinOSVersion(OsWin81)]
  [NamingStyle(nsSnakeCase, 'PROTECTION_LEVEL')]
  TProtectionLevel = (
    PROTECTION_LEVEL_WINTCB_LIGHT = 0,
    PROTECTION_LEVEL_WINDOWS = 1,
    PROTECTION_LEVEL_WINDOWS_LIGHT = 2,
    PROTECTION_LEVEL_ANTIMALWARE_LIGHT = 3,
    PROTECTION_LEVEL_LSA_LIGHT = 4,
    PROTECTION_LEVEL_WINTCB = 5,
    PROTECTION_LEVEL_CODEGEN_LIGHT = 6,
    PROTECTION_LEVEL_AUTHENTICODE = 7,
    PROTECTION_LEVEL_PPL_APP = 8
  );

  // SDK::winnt.h - attribute $C
  [MinOSVersion(OsWin10TH1)]
  [SDKName('MAXVERSIONTESTED_INFO')]
  TMaxVersionTestedInfo = type UInt64;

  // Attribute $E
  [MinOSVersion(OsWin10TH2)]
  [FlagName(PROCESS_CREATION_CHILD_PROCESS_RESTRICTED, 'Restricted')]
  [FlagName(PROCESS_CREATION_CHILD_PROCESS_OVERRIDE, 'Override')]
  [FlagName(PROCESS_CREATION_CHILD_PROCESS_RESTRICTED_UNLESS_SECURE, 'Restricted Unless Secure')]
  TProcessChildFlags = type Cardinal;

  // Attribute $F
  [MinOSVersion(OsWin10RS1)]
  [FlagName(PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT, 'Opt Out')]
  TProcessAllPackagesFlags = type Cardinal;

  // Attribute $12
  [MinOSVersion(OsWin10RS2)]
  [FlagName(PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_ENABLE_PROCESS_TREE, 'Breakaway Enable')]
  [FlagName(PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_DISABLE_PROCESS_TREE, 'Breakaway Disable')]
  [FlagName(PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_OVERRIDE, 'Breakaway Override')]
  TProcessDesktopAppFlags = type Cardinal;

  // Attribute $13
  [MinOSVersion(OsWin10RS2)]
  [SDKName('PROC_THREAD_BNOISOLATION_ATTRIBUTE')]
  TProcThreadBnoIsolationAttribute = record
    IsolationEnabled: LongBool;
    IsolationPrefix: array [0..135] of WideChar;
  end;
  PProcThreadBnoIsolationAttribute = ^TProcThreadBnoIsolationAttribute;

  // SDK::winbasep.h
  [SDKName('PROC_THREAD_ATTRIBUTE')]
  TProcThreadAttribute = record
    Attribute: NativeUInt;
    Size: NativeUInt;
    Value: UIntPtr;
  end;
  PProcThreadAttribute = ^TProcThreadAttribute;

  // SDK::winbasep.h
  [SDKName('PROC_THREAD_ATTRIBUTE_LIST')]
  TProcThreadAttributeList = record
    PresentFlags: Cardinal;
    AttributeCount: Cardinal;
    LastAttribute: Cardinal;
    ExtendedFlagsAttribute: PProcThreadAttribute;
    Attributes: TAnysizeArray<TProcThreadAttribute>;
  end;
  PProcThreadAttributeList = ^TProcThreadAttributeList;

  // SDK::WinBase.h
  [SDKName('STARTUPINFOEXW')]
  TStartupInfoExW = record
    StartupInfo: TStartupInfoW;
    AttributeList: PProcThreadAttributeList;
  end;
  PStartupInfoExW = ^TStartupInfoExW;

  [FlagName(LOGON_WITH_PROFILE, 'Logon With Profile')]
  [FlagName(LOGON_NETCREDENTIALS_ONLY, 'Network Credentials Only')]
  [FlagName(LOGON_ZERO_PASSWORD_BUFFER, 'Zero Password Buffer')]
  TProcessLogonFlags = type Cardinal;

const
  PROTECTION_LEVEL_SAME = TProtectionLevel(-1);

// SDK::processthreadsapi.h
[SetsLastError]
function CreateProcessW(
  [in, opt] ApplicationName: PWideChar;
  [in, out, opt] CommandLine: PWideChar;
  [in, opt] ProcessAttributes: PSecurityAttributes;
  [in, opt] ThreadAttributes: PSecurityAttributes;
  [in] InheritHandles: LongBool;
  [in] CreationFlags: TProcessCreateFlags;
  [in, opt] Environment: PEnvironment;
  [in, opt] CurrentDirectory: PWideChar;
  [in] const StartupInfo: TStartupInfoExW;
  [out, ReleaseWith('NtClose')] out ProcessInformation: TProcessInformation
): LongBool; stdcall; external kernel32;

// SDK::processthreadsapi.h
procedure GetStartupInfoW(
  [out] out StartupInfo: TStartupInfoW
); stdcall; external kernel32;

// SDK::processthreadsapi.h
[SetsLastError]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function CreateProcessAsUserW(
  [in, opt, Access(TOKEN_CREATE_PROCESS)] hToken: THandle;
  [in, opt] ApplicationName: PWideChar;
  [in, out, opt] CommandLine: PWideChar;
  [in, opt] ProcessAttributes: PSecurityAttributes;
  [in, opt] ThreadAttributes: PSecurityAttributes;
  [in] InheritHandles: LongBool;
  [in] CreationFlags: TProcessCreateFlags;
  [in, opt] Environment: PEnvironment;
  [in, opt] CurrentDirectory: PWideChar;
  [in] const StartupInfo: TStartupInfoExW;
  [out, ReleaseWith('NtClose')] out ProcessInformation: TProcessInformation
): LongBool; stdcall; external advapi32;

// SDK::processthreadsapi.h
[SetsLastError]
function InitializeProcThreadAttributeList(
  [out, WritesTo] AttributeList: PProcThreadAttributeList;
  [in, NumberOfElements] AttributeCount: Integer;
  [Reserved] Flags: Cardinal;
  [in, out, NumberOfBytes] var Size: NativeUInt
): LongBool; stdcall; external kernel32;

// SDK::processthreadsapi.h
procedure DeleteProcThreadAttributeList(
  [in, out] AttributeList: PProcThreadAttributeList
); stdcall; external kernel32;

// SDK::processthreadsapi.h
[SetsLastError]
function UpdateProcThreadAttribute(
  [in, out] AttributeList: PProcThreadAttributeList;
  [Reserved] Flags: Cardinal;
  [in] Attribute: NativeUInt;
  [in] Value: Pointer;
  [in, NumberOfBytes] Size: NativeUInt;
  [out, opt] PreviousValue: Pointer;
  [out, opt, NumberOfBytes] ReturnSize: PNativeUInt
): LongBool; stdcall; external kernel32;

// SDK::WinBase.h
[SetsLastError]
function CreateProcessWithLogonW(
  [in] Username: PWideChar;
  [in, opt] Domain: PWideChar;
  [in] Password: PWideChar;
  [in] LogonFlags: TProcessLogonFlags;
  [in, opt] ApplicationName: PWideChar;
  [in, out, opt] CommandLine: PWideChar;
  [in] CreationFlags: TProcessCreateFlags;
  [in, opt] Environment: PEnvironment;
  [in, opt] CurrentDirectory: PWideChar;
  [in] const StartupInfo: TStartupInfoW;
  [out, ReleaseWith('NtClose')] out ProcessInformation: TProcessInformation
): LongBool; stdcall; external advapi32;

// SDK::WinBase.h
[SetsLastError]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
function CreateProcessWithTokenW(
  [in, Access(TOKEN_CREATE_PROCESS_EX)] hToken: THandle;
  [in] LogonFlags: TProcessLogonFlags;
  [in, opt] ApplicationName: PWideChar;
  [in, out, opt] CommandLine: PWideChar;
  [in] CreationFlags: TProcessCreateFlags;
  [in, opt] Environment: PEnvironment;
  [in, opt] CurrentDirectory: PWideChar;
  [in] const StartupInfo: TStartupInfoW;
  [out, ReleaseWith('NtClose')] out ProcessInformation: TProcessInformation
): LongBool; stdcall; external advapi32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
