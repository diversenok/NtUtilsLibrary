unit Winapi.ProcessThreadsApi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Winapi.WinBase, DelphiApi.Reflection, Winapi.ConsoleApi,
  Winapi.WinUser;

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

  StartFlagNames: array [0..13] of TFlagName = (
    (Value: STARTF_USESHOWWINDOW; Name: 'Use Show Window'),
    (Value: STARTF_USESIZE; Name: 'Use Size'),
    (Value: STARTF_USEPOSITION; Name: 'Use Position'),
    (Value: STARTF_USECOUNTCHARS; Name: 'Use Count Chars'),
    (Value: STARTF_USEFILLATTRIBUTE; Name: 'Use Fill Attributes'),
    (Value: STARTF_RUNFULLSCREEN; Name: 'Run Fullscreen'),
    (Value: STARTF_FORCEONFEEDBACK; Name: 'Force Feedback On'),
    (Value: STARTF_FORCEOFFFEEDBACK; Name: 'Force Feedback Off'),
    (Value: STARTF_USESTDHANDLES; Name: 'Use Std Handles'),
    (Value: STARTF_USEHOTKEY; Name: 'STARTF_USEHOTKEY'),
    (Value: STARTF_TITLEISLINKNAME; Name: 'Title Is Link Name'),
    (Value: STARTF_TITLEISAPPID; Name: 'Title Is AppID'),
    (Value: STARTF_PREVENTPINNING; Name: 'Prevent Pinning'),
    (Value: STARTF_UNTRUSTEDSOURCE; Name: 'Untrusted Source')
  );

  // WinBase.3398
  PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = $20000;
  PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY = $70000;
  PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY = $E0000;

  // WinBase.3440, Win 7+
  MITIGATION_POLICY_DEP_ENABLE = $01;
  MITIGATION_POLICY_DEP_ATL_THUNK_ENABLE = $02;
  MITIGATION_POLICY_SEHOP_ENABLE = $04;

  // Win 8+
  MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_ON  = $100;
  MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_OFF = $200;
  MITIGATION_POLICY_FORCE_RELOCATE_IMAGES_ALWAYS_ON_REQ_RELOCS = $300;

  MITIGATION_POLICY_HEAP_TERMINATE_ALWAYS_ON  = $1000;
  MITIGATION_POLICY_HEAP_TERMINATE_ALWAYS_OFF = $2000;

  MITIGATION_POLICY_BOTTOM_UP_ASLR_ALWAYS_ON  = $10000;
  MITIGATION_POLICY_BOTTOM_UP_ASLR_ALWAYS_OFF = $20000;

  MITIGATION_POLICY_HIGH_ENTROPY_ASLR_ALWAYS_ON  = $100000;
  MITIGATION_POLICY_HIGH_ENTROPY_ASLR_ALWAYS_OFF = $200000;

  MITIGATION_POLICY_STRICT_HANDLE_CHECKS_ALWAYS_ON  = $1000000;
  MITIGATION_POLICY_STRICT_HANDLE_CHECKS_ALWAYS_OFF = $2000000;

  MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_ON = $10000000;
  MITIGATION_POLICY_WIN32K_SYSTEM_CALL_DISABLE_ALWAYS_OFF = $20000000;

  MITIGATION_POLICY_EXTENSION_POINT_DISABLE_ALWAYS_ON  = $100000000;
  MITIGATION_POLICY_EXTENSION_POINT_DISABLE_ALWAYS_OFF = $200000000;
  MITIGATION_POLICY_EXTENSION_POINT_DISABLE_RESERVED   = $300000000;

  // WinBlue+
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON = $1000000000;
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_OFF = $2000000000;
  MITIGATION_POLICY_PROHIBIT_DYNAMIC_CODE_ALWAYS_ON_ALLOW_OPT_OUT = $3000000000;

  MITIGATION_POLICY_CONTROL_FLOW_GUARD_ALWAYS_ON = $10000000000;
  MITIGATION_POLICY_CONTROL_FLOW_GUARD_ALWAYS_OFF = $20000000000;
  MITIGATION_POLICY_CONTROL_FLOW_GUARD_EXPORT_SUPPRESSION = $30000000000;

  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_ON = $100000000000;
  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALWAYS_OFF = $200000000000;
  MITIGATION_POLICY_BLOCK_NON_MICROSOFT_BINARIES_ALLOW_STORE = $300000000000;

  // Win 10 TH+
  MITIGATION_POLICY_FONT_DISABLE_ALWAYS_ON  = $1000000000000;
  MITIGATION_POLICY_FONT_DISABLE_ALWAYS_OFF = $2000000000000;
  MITIGATION_POLICY_AUDIT_NONSYSTEM_FONTS   = $3000000000000;

  MITIGATION_POLICY_IMAGE_LOAD_NO_REMOTE_ALWAYS_ON  = $10000000000000;
  MITIGATION_POLICY_IMAGE_LOAD_NO_REMOTE_ALWAYS_OFF = $20000000000000;

  MITIGATION_POLICY_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_ON  = $100000000000000;
  MITIGATION_POLICY_IMAGE_LOAD_NO_LOW_LABEL_ALWAYS_OFF = $200000000000000;

  MITIGATION_POLICY_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_ON  = $1000000000000000;
  MITIGATION_POLICY_IMAGE_LOAD_PREFER_SYSTEM32_ALWAYS_OFF = $2000000000000000;

  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_ALWAYS_ON  = $10;
  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_ALWAYS_OFF = $20;
  MITIGATION_POLICY2_LOADER_INTEGRITY_CONTINUITY_AUDIT = $30;

  MITIGATION_POLICY2_STRICT_CONTROL_FLOW_GUARD_ALWAYS_ON  = $100;
  MITIGATION_POLICY2_STRICT_CONTROL_FLOW_GUARD_ALWAYS_OFF = $200;

  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_ALWAYS_ON  = $1000;
  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_ALWAYS_OFF = $2000;
  MITIGATION_POLICY2_MODULE_TAMPERING_PROTECTION_NOINHERIT  = $3000;

  MITIGATION_POLICY2_RESTRICT_INDIRECT_BRANCH_PREDICTION_ALWAYS_ON  = $10000;
  MITIGATION_POLICY2_RESTRICT_INDIRECT_BRANCH_PREDICTION_ALWAYS_OFF = $20000;

  MITIGATION_POLICY2_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY_ALWAYS_ON  = $100000;
  MITIGATION_POLICY2_ALLOW_DOWNGRADE_DYNAMIC_CODE_POLICY_ALWAYS_OFF = $200000;

  MITIGATION_POLICY2_SPECULATIVE_STORE_BYPASS_DISABLE_ALWAYS_ON  = $1000000;
  MITIGATION_POLICY2_SPECULATIVE_STORE_BYPASS_DISABLE_ALWAYS_OFF = $2000000;

  // WinBase.3690, Win 10 TH+
  PROCESS_CREATION_CHILD_PROCESS_RESTRICTED = $01;
  PROCESS_CREATION_CHILD_PROCESS_OVERRIDE = $02;
  PROCESS_CREATION_CHILD_PROCESS_RESTRICTED_UNLESS_SECURE = $04;

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

  TStartupFlagProvider = class (TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

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
    [Bitwise(TConsoleFlagProvider)] FillAttribute: Cardinal;
    [Bitwise(TStartupFlagProvider)] Flags: Cardinal;
    ShowWindow: TShowMode;
    [Unlisted] cbReserved2: Word;
    [Unlisted] lpReserved2: PByte;
    hStdInput: THandle;
    hStdOutput: THandle;
    hStdError: THandle;
  end;
  PStartupInfoW = ^TStartupInfoW;

  // 573
  PProcThreadAttributeList = Pointer;

  // WinBase.3038
  TStartupInfoExW = record
    StartupInfo: TStartupInfoW;
    lpAttributeList: PProcThreadAttributeList;
  end;
  PStartupInfoExW = ^TStartupInfoExW;

// 377
function CreateProcessW(ApplicationName: PWideChar; CommandLine: PWideChar;
  ProcessAttributes: PSecurityAttributes; ThreadAttributes: PSecurityAttributes;
  InheritHandles: LongBool; CreationFlags: Cardinal; Environment: Pointer;
  CurrentDirectory: PWideChar; const StartupInfo: TStartupInfoExW;
  out ProcessInformation: TProcessInformation): LongBool; stdcall;
  external kernel32;

// 422
procedure GetStartupInfoW(out StartupInfo: TStartupInfoW); stdcall;
  external kernel32;

// 433
function CreateProcessAsUserW(hToken: THandle; ApplicationName: PWideChar;
  CommandLine: PWideChar; ProcessAttributes: PSecurityAttributes;
  ThreadAttributes: PSecurityAttributes; InheritHandles: LongBool;
  CreationFlags: Cardinal; Environment: Pointer; CurrentDirectory: PWideChar;
  StartupInfo: PStartupInfoExW; out ProcessInformation: TProcessInformation):
  LongBool; stdcall; external advapi32;

// 637
function InitializeProcThreadAttributeList(AttributeList:
  PProcThreadAttributeList; AttributeCount: Integer; Flags: Cardinal;
  var Size: NativeUInt): LongBool; stdcall; external kernel32;

// 648
procedure DeleteProcThreadAttributeList(AttributeList:
  PProcThreadAttributeList); stdcall; external kernel32;

// 678
function UpdateProcThreadAttribute(AttributeList: PProcThreadAttributeList;
  Flags: Cardinal; Attribute: NativeUInt; Value: Pointer; Size: NativeUInt;
  PreviousValue: Pointer = nil; ReturnSize: PNativeUInt = nil): LongBool;
  stdcall; external kernel32;

// WinBase.7276
function CreateProcessWithLogonW(Username: PWideChar; Domain: PWideChar;
  Password: PWideChar; LogonFlags: Cardinal; ApplicationName: PWideChar;
  CommandLine: PWideChar; CreationFlags: Cardinal; Environment: Pointer;
  CurrentDirectory: PWideChar; StartupInfo: PStartupInfoExW;
  out ProcessInformation: TProcessInformation): LongBool; stdcall;
  external advapi32;

// WinBase.7293
function CreateProcessWithTokenW(hToken: THandle; LogonFlags: Cardinal;
  ApplicationName: PWideChar; CommandLine: PWideChar; CreationFlags: Cardinal;
  Environment: Pointer; CurrentDirectory: PWideChar; StartupInfo:
  PStartupInfoExW; out ProcessInformation: TProcessInformation): LongBool;
  stdcall; external advapi32;

implementation

class function TStartupFlagProvider.Flags: TFlagNames;
begin
  Result := Capture(StartFlagNames);
end;

end.
