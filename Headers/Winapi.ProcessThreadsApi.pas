unit Winapi.ProcessThreadsApi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Winapi.WinBase, DelphiApi.Reflection, Winapi.ConsoleApi,
  Ntapi.ntseapi, Winapi.WinUser, NtUtils.Version;

const
  // WinBase.573
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

  // WinBase.3010
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

  // WinBase.3398
  PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = $20000;        // THandle
  PROC_THREAD_ATTRIBUTE_HANDLE_LIST = $20002;           // TArray<THandle>
  PROC_THREAD_ATTRIBUTE_GROUP_AFFINITY = $30003;        //
  PROC_THREAD_ATTRIBUTE_PREFERRED_NODE = $20004;        //
  PROC_THREAD_ATTRIBUTE_IDEAL_PROCESSOR = $30005;       //
  PROC_THREAD_ATTRIBUTE_UMS_THREAD = $30006;            //
  PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY = $20007;     // 32, 64, or 128 bit mask
  PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES = $20009; // TSecurityCapabilities, Win 8+
  PROC_THREAD_ATTRIBUTE_PROTECTION_LEVEL = $2000B;      // Win 8+
  PROC_THREAD_ATTRIBUTE_JOB_LIST = $2000D;              // Win 10 TH1+
  PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY = $2000E;  // Cardinal, Win 10 TH1+
  PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY = $2000F; // Cardinal, Win 10 TH1+
  PROC_THREAD_ATTRIBUTE_WIN32K_FILTER = $20010;         // Win 10 TH1+
  PROC_THREAD_ATTRIBUTE_DESKTOP_APP_POLICY = $20012;    // Cardinal, Win 10 RS2+
  PROC_THREAD_ATTRIBUTE_PSEUDOCONSOLE = $20016;         // Win RS5+

  // Mitigation policies

  // WinBase.3440, Win 7+
  MITIGATION_POLICY_DEP_ENABLE = $01;
  MITIGATION_POLICY_DEP_ATL_THUNK_ENABLE = $02;
  MITIGATION_POLICY_SEHOP_ENABLE = $04;

  // Win 8+
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

  // Win 8.1+
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON = UInt64($1) shl 36;
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_OFF = UInt64($2) shl 36;
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON_ALLOW_OPT_OUT = UInt64($3) shl 36;

  MITIGATION_POLICY_CONTROL_FLOW_GUARD_ALWAYS_ON = UInt64($1) shl 40;
  MITIGATION_POLICY_CONTROL_FLOW_GUARD_ALWAYS_OFF = UInt64($2) shl 40;
  MITIGATION_POLICY_CONTROL_FLOW_GUARD_EXPORT_SUPPRESSION = UInt64($3) shl 40;

  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_ON = UInt64($1) shl 44;
  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_OFF = UInt64($2) shl 44;
  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALLOW_STORE = UInt64($3) shl 44;

  // Win 10 TH+
  MITIGATION_POLICY_FONT_DISABLE_ALWAYS_ON  = UInt64($1) shl 48;
  MITIGATION_POLICY_FONT_DISABLE_ALWAYS_OFF = UInt64($2) shl 48;
  MITIGATION_POLICY_AUDIT_NONSYSTEM_FONTS   = UInt64($3) shl 48;

  MITIGATION_POLICY_IMAGE_LOAD_NO_REMOTE_ALWAYS_ON  = UInt64($1) shl 52;
  MITIGATION_POLICY_IMAGE_LOAD_NO_REMOTE_ALWAYS_OFF = UInt64($2) shl 52;

  MITIGATION_POLICY_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_ON  = UInt64($1) shl 56;
  MITIGATION_POLICY_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_OFF = UInt64($2) shl 56;

  MITIGATION_POLICY_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_ON  = UInt64($1) shl 60;
  MITIGATION_POLICY_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_OFF = UInt64($2) shl 60;

  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_ALWAYS_ON  = $1 shl 4;
  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_ALWAYS_OFF = $2 shl 4;
  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_AUDIT = $3 shl 4;

  MITIGATION_POLICY2_STRICT_CONTROL_FLOW_GUARD_ALWAYS_ON  = $1 shl 8;
  MITIGATION_POLICY2_STRICT_CONTROL_FLOW_GUARD_ALWAYS_OFF = $2 shl 8;

  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_ALWAYS_ON  = $1 shl 12;
  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_ALWAYS_OFF = $2 shl 12;
  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_NOINHERIT  = $3 shl 12;

  MITIGATION_POLICY2_RESTRICT_INDIRECT_BRANCH_PREDICTION_ALWAYS_ON  = $1 shl 16;
  MITIGATION_POLICY2_RESTRICT_INDIRECT_BRANCH_PREDICTION_ALWAYS_OFF = $2 shl 16;

  MITIGATION_POLICY2_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY_ALWAYS_ON  = $1 shl 20;
  MITIGATION_POLICY2_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY_ALWAYS_OFF = $2 shl 20;

  MITIGATION_POLICY2_SPECULATIVE_STORE_BYPASS_DISABLE_ALWAYS_ON  = $1 shl 24;
  MITIGATION_POLICY2_SPECULATIVE_STORE_BYPASS_DISABLE_ALWAYS_OFF = $2 shl 24;

  // Other process/thread attributes

  // WinBase.3690, Win 10 TH+
  PROCESS_CREATION_CHILD_PROCESS_RESTRICTED = $01;
  PROCESS_CREATION_CHILD_PROCESS_OVERRIDE = $02;
  PROCESS_CREATION_CHILD_PROCESS_RESTRICTED_UNLESS_SECURE = $04;

  // WinBase.3724, Win 10 RS1+
  PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT = $01;

  // 673
  PROC_THREAD_ATTRIBUTE_REPLACE_VALUE = $00000001;

  TOKEN_CREATE_PROCESS = TOKEN_ASSIGN_PRIMARY or TOKEN_QUERY or TOKEN_DUPLICATE;

  // WinBase.7268
  LOGON_WITH_PROFILE = $00000001;
  LOGON_NETCREDENTIALS_ONLY = $00000002;
  LOGON_ZERO_PASSWORD_BUFFER = $80000000;

type
  // 28
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
  [FlagName(CREATE_DEFAULT_ERROR_MODE, 'Defaule Error Mode')]
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

  // 55
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
    ShowWindow: TShowMode;
    [Unlisted] cbReserved2: Word;
    [Unlisted] lpReserved2: PByte;
    hStdInput: THandle;
    hStdOutput: THandle;
    hStdError: THandle;
  end;
  PStartupInfoW = ^TStartupInfoW;

  TSidAndAttributesArray = TAnysizeArray<TSidAndAttributes>;
  PSidAndAttributesArray = ^TSidAndAttributesArray;

  // winnt.11356
  [MinOSVersion(OsWin8)]
  TSecurityCapabilities = record
    AppContainerSid: PSid;
    Capabilities: PSidAndAttributesArray;
    [Counter] CapabilityCount: Cardinal;
    [Unlisted] Reserved: Cardinal;
  end;
  PSecurityCapabilities = ^TSecurityCapabilities;

  // 573
  PProcThreadAttributeList = Pointer;

  // WinBase.3038
  TStartupInfoExW = record
    StartupInfo: TStartupInfoW;
    AttributeList: PProcThreadAttributeList;
  end;
  PStartupInfoExW = ^TStartupInfoExW;

  [FlagName(LOGON_WITH_PROFILE, 'Logon With Profile')]
  [FlagName(LOGON_NETCREDENTIALS_ONLY, 'Network Credentials Only')]
  [FlagName(LOGON_ZERO_PASSWORD_BUFFER, 'Zero Password Buffer')]
  TProcessLogonFlags = type Cardinal;

// 377
function CreateProcessW(
  [in, opt] ApplicationName: PWideChar;
  [in, out, opt] CommandLine: PWideChar;
  [in, opt] ProcessAttributes: PSecurityAttributes;
  [in, opt] ThreadAttributes: PSecurityAttributes;
  InheritHandles: LongBool;
  CreationFlags: TProcessCreateFlags;
  [in, opt] Environment: PEnvironment;
  [in, opt] CurrentDirectory: PWideChar;
  const StartupInfo: TStartupInfoExW;
  out ProcessInformation: TProcessInformation
): LongBool; stdcall; external kernel32;

// 422
procedure GetStartupInfoW(
  out StartupInfo: TStartupInfoW
); stdcall; external kernel32;

// 433
function CreateProcessAsUserW(
  [opt, Access(TOKEN_CREATE_PROCESS)] hToken: THandle;
  [in, opt] ApplicationName: PWideChar;
  [in, out, opt] CommandLine: PWideChar;
  [in, opt] ProcessAttributes: PSecurityAttributes;
  [in, opt] ThreadAttributes: PSecurityAttributes;
  InheritHandles: LongBool;
  CreationFlags: TProcessCreateFlags;
  [in, opt] Environment: PEnvironment;
  [in, opt] CurrentDirectory: PWideChar;
  const StartupInfo: TStartupInfoExW;
  out ProcessInformation: TProcessInformation
): LongBool; stdcall; external advapi32;

// 637
function InitializeProcThreadAttributeList(
  [out, opt] AttributeList: PProcThreadAttributeList;
  AttributeCount: Integer;
  [Reserved] Flags: Cardinal;
  var Size: NativeUInt
): LongBool; stdcall; external kernel32;

// 648
procedure DeleteProcThreadAttributeList(
  [in, out] AttributeList: PProcThreadAttributeList
); stdcall; external kernel32;

// 678
function UpdateProcThreadAttribute(
  [in, out] AttributeList: PProcThreadAttributeList;
  [Reserved] Flags: Cardinal;
  Attribute: NativeUInt;
  [in, opt] Value: Pointer;
  Size: NativeUInt;
  [out, opt] PreviousValue: Pointer;
  [out, opt] ReturnSize: PNativeUInt
): LongBool; stdcall; external kernel32;

// WinBase.7276
function CreateProcessWithLogonW(
  [in] Username: PWideChar;
  [in, opt] Domain: PWideChar;
  [in] Password: PWideChar;
  LogonFlags: TProcessLogonFlags;
  [in, opt] ApplicationName: PWideChar;
  [in, out, opt] CommandLine: PWideChar;
  CreationFlags: TProcessCreateFlags;
  [in, opt] Environment: PEnvironment;
  [in, opt] CurrentDirectory: PWideChar;
  const StartupInfo: TStartupInfoW;
  out ProcessInformation: TProcessInformation
): LongBool; stdcall; external advapi32;

// WinBase.7293
function CreateProcessWithTokenW(
  [Access(TOKEN_CREATE_PROCESS)] hToken: THandle;
  LogonFlags: TProcessLogonFlags;
  [in, opt] ApplicationName: PWideChar;
  [in, out, opt] CommandLine: PWideChar;
  CreationFlags: TProcessCreateFlags;
  [in, opt] Environment: PEnvironment;
  [in, opt] CurrentDirectory: PWideChar;
  const StartupInfo: TStartupInfoW;
  out ProcessInformation: TProcessInformation
): LongBool; stdcall; external advapi32;

implementation

end.
