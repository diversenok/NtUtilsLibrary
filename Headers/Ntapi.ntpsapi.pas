unit Ntapi.ntpsapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntrtl, DelphiApi.Reflection,
  Ntapi.ntseapi, NtUtils.Version, Ntapi.ntexapi;

const
  // Processes

  SYSTEM_IDLE_PID = 0;
  SYSTEM_PID = 4;

  PROCESS_TERMINATE = $0001;
  PROCESS_CREATE_THREAD = $0002;
  PROCESS_SET_SESSIONID = $0004;
  PROCESS_VM_OPERATION = $0008;
  PROCESS_VM_READ = $0010;
  PROCESS_VM_WRITE = $0020;
  PROCESS_DUP_HANDLE = $0040;
  PROCESS_CREATE_PROCESS = $0080;
  PROCESS_SET_QUOTA = $0100;
  PROCESS_SET_INFORMATION = $0200;
  PROCESS_QUERY_INFORMATION = $0400;
  PROCESS_SUSPEND_RESUME = $0800;
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
  PROCESS_SET_LIMITED_INFORMATION = $2000;

  PROCESS_ALL_ACCESS = STANDARD_RIGHTS_ALL or SPECIFIC_RIGHTS_ALL;

  // rev, flags for NtGetNextProcess
  PROCESS_NEXT_REVERSE_ORDER = $01;

  // WinNt.11614, some flags for mitigation policies
  PROCESS_MITIGATION_STRICT_HANDLE_CHECKS_ENABLE = $0001;
  PROCESS_MITIGATION_STRICT_HANDLE_CHECKS_HANDLE_PERMNENTLY = $0002;
  PROCESS_MITIGATION_EXTENSION_POINTS_DISABLE = $0001;
  PROCESS_MITIGATION_DYNAMIC_CODE_PROHIBIT = $0001;
  PROCESS_MITIGATION_SYSTEM_CALL_WIN32_DISABLE = $0001;
  PROCESS_MITIGATION_CHILD_PROCESSES_DISALLOW = $0001;

  // Process uptime flags
  PROCESS_UPTIME_CRASHED = $100;
  PROCESS_UPTIME_TERMINATED = $200;

  // Flags for NtCreateProcessEx and NtCreateUserProcess
  PROCESS_CREATE_FLAGS_BREAKAWAY = $00000001;
  PROCESS_CREATE_FLAGS_NO_DEBUG_INHERIT = $00000002;
  PROCESS_CREATE_FLAGS_INHERIT_HANDLES = $00000004;
  PROCESS_CREATE_FLAGS_OVERRIDE_ADDRESS_SPACE = $00000008;
  PROCESS_CREATE_FLAGS_LARGE_PAGES = $00000010;

  // ProcessFlags for NtCreateUserProcess
  PROCESS_CREATE_FLAGS_LARGE_PAGE_SYSTEM_DLL = $00000020;
  PROCESS_CREATE_FLAGS_PROTECTED_PROCESS = $00000040;
  PROCESS_CREATE_FLAGS_CREATE_SESSION = $00000080;
  PROCESS_CREATE_FLAGS_INHERIT_FROM_PARENT = $00000100;
  PROCESS_CREATE_FLAGS_SUSPENDED = $00000200;

  // ntddk.5333
  PROCESS_HANDLE_TRACING_MAX_STACKS = 16;
  PROCESS_HANDLE_TRACING_MAX_SLOTS = $20000;

  // Threads

  THREAD_TERMINATE = $0001;
  THREAD_SUSPEND_RESUME = $0002;
  THREAD_ALERT = $0004;
  THREAD_GET_CONTEXT = $0008;
  THREAD_SET_CONTEXT = $0010;
  THREAD_SET_INFORMATION = $0020;
  THREAD_QUERY_INFORMATION = $0040;
  THREAD_SET_THREAD_TOKEN = $0080;
  THREAD_IMPERSONATE = $0100;
  THREAD_DIRECT_IMPERSONATION = $0200;
  THREAD_SET_LIMITED_INFORMATION = $0400;
  THREAD_QUERY_LIMITED_INFORMATION = $0800;
  THREAD_RESUME = $1000;

  THREAD_ALL_ACCESS = STANDARD_RIGHTS_ALL or SPECIFIC_RIGHTS_ALL;

  // User processes and threads

  // CreateFlags for NtCreateThreadEx
  THREAD_CREATE_FLAGS_CREATE_SUSPENDED = $00000001;
  THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH = $00000002;
  THREAD_CREATE_FLAGS_HIDE_FROM_DEBUGGER = $00000004;
  THREAD_CREATE_FLAGS_HAS_SECURITY_DESCRIPTOR = $00000010;
  THREAD_CREATE_FLAGS_ACCESS_CHECK_IN_TARGET = $00000020;
  THREAD_CREATE_FLAGS_INITIAL_THREAD = $00000080;

  // Jobs

  JOB_OBJECT_ASSIGN_PROCESS = $0001;
  JOB_OBJECT_SET_ATTRIBUTES = $0002;
  JOB_OBJECT_QUERY = $0004;
  JOB_OBJECT_TERMINATE = $0008;
  JOB_OBJECT_SET_SECURITY_ATTRIBUTES = $0010;
  JOB_OBJECT_IMPERSONATE = $0020;

  JOB_OBJECT_ALL_ACCESS = STANDARD_RIGHTS_ALL or $3F;

  // WinNt.12183, basic limits
  JOB_OBJECT_LIMIT_WORKINGSET = $00000001;
  JOB_OBJECT_LIMIT_PROCESS_TIME = $00000002;
  JOB_OBJECT_LIMIT_JOB_TIME = $00000004;
  JOB_OBJECT_LIMIT_ACTIVE_PROCESS = $00000008;
  JOB_OBJECT_LIMIT_AFFINITY = $00000010;
  JOB_OBJECT_LIMIT_PRIORITY_CLASS = $00000020;
  JOB_OBJECT_LIMIT_PRESERVE_JOB_TIME = $00000040;
  JOB_OBJECT_LIMIT_SCHEDULING_CLASS = $00000080;

  // WinNt.12195, extended limits
  JOB_OBJECT_LIMIT_PROCESS_MEMORY = $00000100;
  JOB_OBJECT_LIMIT_JOB_MEMORY = $00000200;
  JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION = $00000400;
  JOB_OBJECT_LIMIT_BREAKAWAY_OK = $00000800;
  JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK = $00001000;
  JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = $00002000;
  JOB_OBJECT_LIMIT_SUBSET_AFFINITY = $00004000;
  JOB_OBJECT_LIMIT_JOB_MEMORY_LOW = $00008000;

  // WinNt.12209, notification limits
  JOB_OBJECT_LIMIT_JOB_READ_BYTES = $00010000;
  JOB_OBJECT_LIMIT_JOB_WRITE_BYTES = $00020000;
  JOB_OBJECT_LIMIT_CPU_RATE_CONTROL = $00040000;
  JOB_OBJECT_LIMIT_IO_RATE_CONTROL = $00080000;
  JOB_OBJECT_LIMIT_NET_RATE_CONTROL = $00100000;

  // rev, among with die-on-unhandled-exceptions is required to create a silo,
  // use with extended limits v2
  JOB_OBJECT_LIMIT_SILO_READY = $00400000;

  // WinNt.12241, UI restrictions
  JOB_OBJECT_UILIMIT_HANDLES = $00000001;
  JOB_OBJECT_UILIMIT_READCLIPBOARD = $00000002;
  JOB_OBJECT_UILIMIT_WRITECLIPBOARD = $00000004;
  JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS = $00000008;
  JOB_OBJECT_UILIMIT_DISPLAYSETTINGS = $00000010;
  JOB_OBJECT_UILIMIT_GLOBALATOMS = $00000020;
  JOB_OBJECT_UILIMIT_DESKTOP = $00000040;
  JOB_OBJECT_UILIMIT_EXITWINDOWS = $00000080;

  // WinNt.12265, CPU rate control flags, Win 8+
  JOB_OBJECT_CPU_RATE_CONTROL_ENABLE = $01;
  JOB_OBJECT_CPU_RATE_CONTROL_WEIGHT_BASED = $02;
  JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP = $04;
  JOB_OBJECT_CPU_RATE_CONTROL_NOTIFY = $08;
  JOB_OBJECT_CPU_RATE_CONTROL_MIN_MAX_RATE = $10; // Win 10 TH1+

  // Freeze flags
  JOB_OBJECT_OPERATION_FREEZE = $01;
  JOB_OBJECT_OPERATION_FILTER = $02;
  JOB_OBJECT_OPERATION_SWAP = $04;

  // WinNt.12054
  JOB_OBJECT_IO_RATE_CONTROL_ENABLE = $01; // Win 10 TH1+
  JOB_OBJECT_IO_RATE_CONTROL_STANDALONE_VOLUME = $02; // Win 10 RS1+
  JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ALL = $04; // Win 10 RS4+
  JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ON_SOFT_CAP = $08; // Win 10 RS4+

  // WinNt.12021
  JOB_OBJECT_NET_RATE_CONTROL_ENABLE = $01;
  JOB_OBJECT_NET_RATE_CONTROL_MAX_BANDWIDTH = $02;
  JOB_OBJECT_NET_RATE_CONTROL_DSCP_TAG = $04;

  // wdm.7752
  NtCurrentProcess = THandle(-1);
  NtCurrentThread = THandle(-2);

  function NtCurrentProcessId: TProcessId;
  function NtCurrentThreadId: TThreadId;

type
  // Processes

  [FriendlyName('process'), ValidMask(PROCESS_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(PROCESS_TERMINATE, 'Terminate')]
  [FlagName(PROCESS_CREATE_THREAD, 'Create Threads')]
  [FlagName(PROCESS_SET_SESSIONID, 'Set Session ID')]
  [FlagName(PROCESS_VM_OPERATION, 'Modify Memory')]
  [FlagName(PROCESS_VM_READ, 'Read Memory')]
  [FlagName(PROCESS_VM_WRITE, 'Write Memory')]
  [FlagName(PROCESS_DUP_HANDLE, 'Duplicate Handles')]
  [FlagName(PROCESS_CREATE_PROCESS, 'Create Process')]
  [FlagName(PROCESS_SET_QUOTA, 'Set Quota')]
  [FlagName(PROCESS_SET_INFORMATION, 'Set Information')]
  [FlagName(PROCESS_QUERY_INFORMATION, 'Query Information')]
  [FlagName(PROCESS_SUSPEND_RESUME, 'Suspend/Resume')]
  [FlagName(PROCESS_QUERY_LIMITED_INFORMATION, 'Query Limited Information')]
  [FlagName(PROCESS_SET_LIMITED_INFORMATION, 'Set Limited Information')]
  TProcessAccessMask = type TAccessMask;

  // ntddk.5070
  [NamingStyle(nsCamelCase, 'Process')]
  TProcessInfoClass = (
    ProcessBasicInformation = 0,      // q: TProcessBasicInformation
    ProcessQuotaLimits = 1,           // q, s: TQuotaLimits
    ProcessIoCounters = 2,            // q: TIoCounters
    ProcessVmCounters = 3,            // q: TVmCounters
    ProcessTimes = 4,                 // q: TKernelUserTimes
    ProcessBasePriority = 5,          // s: KPRIORITY
    ProcessRaisePriority = 6,         // s:
    ProcessDebugPort = 7,             // q: NativeUInt
    ProcessExceptionPort = 8,         // s: LPC port THandle
    ProcessAccessToken = 9,           // s: TProcessAccessToken
    ProcessLdtInformation = 10,       // q, s:
    ProcessLdtSize = 11,              // s:
    ProcessDefaultHardErrorMode = 12, // q, s: Cardinal
    ProcessIoPortHandlers = 13,       // s:
    ProcessPooledUsageAndLimits = 14, // q: TPooledUsageAndLimits
    ProcessWorkingSetWatch = 15,      // q, s:
    ProcessUserModeIOPL = 16,         // s: 
    ProcessEnableAlignmentFaultFixup = 17, // s: Boolean
    ProcessPriorityClass = 18,           // q, s: TProcessPriorityClass
    ProcessWx86Information = 19,         // q, s: Cardinal
    ProcessHandleCount = 20,             // q: Cardinal or TProcessHandleInformation
    ProcessAffinityMask = 21,            // q, s:
    ProcessPriorityBoost = 22,           // q, s:
    ProcessDeviceMap = 23,               // q: ... s: directory THandle
    ProcessSessionInformation = 24,      // q, s: Cardinal
    ProcessForegroundInformation = 25,   // s: Boolean
    ProcessWow64Information = 26,        // q: PPeb32
    ProcessImageFileName = 27,           // q: UNICODE_STRING
    ProcessLUIDDeviceMapsEnabled = 28,   // q: LongBool
    ProcessBreakOnTermination = 29,      // q, s: LongBool
    ProcessDebugObjectHandle = 30,       // q: THandle
    ProcessDebugFlags = 31,              // q, s: TProcessDebugFlags
    ProcessHandleTracing = 32,           // q, s: TProcessHandleTracing*
    ProcessIoPriority = 33,              // q, s: TIoPriorityHint
    ProcessExecuteFlags = 34,            // q, s: Cardinal (setter self only)
    ProcessResourceManagement = 35,      // s: (self only)
    ProcessCookie = 36,                  // q:
    ProcessImageInformation = 37,        // q: TSectionImageInformation
    ProcessCycleTime = 38,               // q: TProcessCycleTimeInformation
    ProcessPagePriority = 39,            // q, s: TMemoryPriority
    ProcessInstrumentationCallback = 40, // s:
    ProcessThreadStackAllocation = 41,   // s: (self only)
    ProcessWorkingSetWatchEx = 42,       // q, s:
    ProcessImageFileNameWin32 = 43,      // q: UNICODE_STRING
    ProcessImageFileMapping = 44,
    ProcessAffinityUpdateMode = 45,      // q, s: (self only)
    ProcessMemoryAllocationMode = 46,    // q, s:
    ProcessGroupInformation = 47,        // q:
    ProcessTokenVirtualizationEnabled = 48, // s: LongBool
    ProcessConsoleHostProcess = 49,      // q, s: TProcessId (setter self only)
    ProcessWindowInformation = 50,       // q: TProcessWindowInformation
    ProcessHandleInformation = 51,       // q: TProcessHandleSnapshotInformation, Win 8+
    ProcessMitigationPolicy = 52,        // q, s: TProcessMitigationPolicyInformation, Win 8+
    ProcessDynamicFunctionTableInformation = 53, // s: (self only)
    ProcessHandleCheckingMode = 54,        // q, s: LongBool
    ProcessKeepAliveCount = 55,            // q:
    ProcessRevokeFileHandles = 56,         // s: UNICODE_STRING (Path)
    ProcessWorkingSetControl = 57,         // s: 
    ProcessHandleTable = 58,               // q: Cardinal[] Win 8.1+
    ProcessCheckStackExtentsMode = 59,     // q, s:
    ProcessCommandLineInformation = 60,    // q UNICODE_STRING, Win 8.1 +
    ProcessProtectionInformation = 61,
    ProcessMemoryExhaustion = 62,          // s: Win 10 TH1+
    ProcessFaultInformation = 63,          // s: 
    ProcessTelemetryIdInformation = 64,    // q: TProcessTelemetryIdInformation
    ProcessCommitReleaseInformation = 65,  // q, s:
    ProcessDefaultCpuSetsInformation = 66, // q, s:
    ProcessAllowedCpuSetsInformation = 67, // q, s:
    ProcessSubsystemProcess = 68,          // s: 
    ProcessJobMemoryInformation = 69,      // q: TProcessJobMemoryInfo
    ProcessInPrivate = 70,                 // q, s: Boolean, Win 10 TH2+
    ProcessRaiseUMExceptionOnInvalidHandleClose = 71, // q
    ProcessIumChallengeResponse = 72,      // q, s:
    ProcessChildProcessInformation = 73,   // q: TProcessChildProcessInformation
    ProcessHighGraphicsPriorityInformation = 74, // q, s: Boolean
    ProcessSubsystemInformation = 75,      // q: Cardinal, Win 10 RS2+
    ProcessEnergyValues = 76,              // q:
    ProcessActivityThrottleState = 77,     // q:
    ProcessActivityThrottlePolicy = 78,
    ProcessWin32kSyscallFilterInformation = 79, // q:
    ProcessDisableSystemAllowedCpuSets = 80,    // s:
    ProcessWakeInformation = 81,                // q:
    ProcessEnergyTrackingState = 82,            // q, s:
    ProcessManageWritesToExecutableMemory = 83, // s: (self only), Win 10 RS3+
    ProcessCaptureTrustletLiveDump = 84,        // q:
    ProcessTelemetryCoverage = 85,              // q, s:
    ProcessEnclaveInformation = 86,
    ProcessEnableReadWriteVmLogging = 87,       // q, s: 
    ProcessUptimeInformation = 88,              // q: TProcessUptimeInformation
    ProcessImageSection = 89,                   // q: THandle
    ProcessDebugAuthInformation = 90,           // s: Win 10 RS4+
    ProcessSystemResourceManagement = 91,       // s: Cardinal
    ProcessSequenceNumber = 92,                 // q: NativeUInt
    ProcessLoaderDetour = 93,                   // s: Win 10 RS5+
    ProcessSecurityDomainInformation = 94,      // q: UInt64
    ProcessCombineSecurityDomainsInformation = 95, // s: process THandle
    ProcessEnableLogging = 96,                  // q, s:
    ProcessLeapSecondInformation = 97,          // q, s: (self only)
    ProcessFiberShadowStackAllocation = 98,     // s: (self only), Win 10 19H1+
    ProcessFreeFiberShadowStackAllocation = 99  // s: (self only)
  );

  // ntddk.5244
  TProcessBasicInformation = record
    ExitStatus: NTSTATUS;
    [DontFollow] PebBaseAddress: PPeb;
    [Hex] AffinityMask: NativeUInt;
    BasePriority: KPRIORITY;
    UniqueProcessID: TProcessId;
    InheritedFromUniqueProcessID: TProcessId;
  end;
  PProcessBasicInformation = ^TProcessBasicInformation;

  // ntddk.5420
  TVmCounters = record
    [Bytes] PeakVirtualSize: NativeUInt;
    [Bytes] VirtualSize: NativeUInt;
    PageFaultCount: Cardinal;
    [Bytes] PeakWorkingSetSize: NativeUInt;
    [Bytes] WorkingSetSize: NativeUInt;
    [Bytes] QuotaPeakPagedPoolUsage: NativeUInt;
    [Bytes] QuotaPagedPoolUsage: NativeUInt;
    [Bytes] QuotaPeakNonPagedPoolUsage: NativeUInt;
    [Bytes] QuotaNonPagedPoolUsage: NativeUInt;
    [Bytes] PagefileUsage: NativeUInt;
    [Bytes] PeakPagefileUsage: NativeUInt;
  end;
  PVmCounters = ^TVmCounters;

  // ntddk.5819
  TKernelUserTimes = record
    CreateTime: TLargeInteger;
    ExitTime: TLargeInteger;
    KernelTime: TULargeInteger;
    UserTime: TULargeInteger;
  end;
  PKernelUserTimes = ^TKernelUserTimes;

  // ntddk.5765
  TProcessAccessToken = record
    Token: THandle;  // needs TOKEN_ASSIGN_PRIMARY
    Thread: THandle; // currently unused, was THREAD_QUERY_INFORMATION
  end;
  PProcessAccessToken = ^TProcessAccessToken;

  // ntddk.5745
  TPooledUsageAndLimits = record
    [Bytes] PeakPagedPoolUsage: NativeUInt;
    [Bytes] PagedPoolUsage: NativeUInt;
    [Bytes] PagedPoolLimit: NativeUInt;
    [Bytes] PeakNonPagedPoolUsage: NativeUInt;
    [Bytes] NonPagedPoolUsage: NativeUInt;
    [Bytes] NonPagedPoolLimit: NativeUInt;
    [Bytes] PeakPagefileUsage: NativeUInt;
    [Bytes] PagefileUsage: NativeUInt;
    [Bytes] PagefileLimit: NativeUInt;
  end;
  PPooledUsageAndLimits = ^TPooledUsageAndLimits;

  {$MINENUMSIZE 1}
  [NamingStyle(nsCamelCase, 'ProcessPriorityClass')]
  TProcessPriorityClassValue = (
    ProcessPriorityClassUnknown = 0,
    ProcessPriorityClassIdle = 1,
    ProcessPriorityClassNormal = 2,
    ProcessPriorityClassHigh = 3,
    ProcessPriorityClassRealtime = 4,
    ProcessPriorityClassBelowNormal = 5,
    ProcessPriorityClassAboveNormal = 6
  );
  {$MINENUMSIZE 4}

  TProcessPriorityClass = record
    Foreground: Boolean;
    PriorityClass: TProcessPriorityClassValue;
  end;

  TProcessHandleInformation = record
    HandleCount: Cardinal;
    HandleCountHighWatermark: Cardinal;
  end;
  PProcessHandleInformation = ^TProcessHandleInformation;

  [NamingStyle(nsSnakeCase, 'PROCESS_DEBUG')]
  TProcessDebugFlags = (
    PROCESS_DEBUG_INHERIT = 1
  );

  // ntddk.5323
  // To enable, use this structure; to disable use zero input length
  TProcessHandleTracingEnableEx = record
    Flags: Cardinal; // always zero
    TotalSlots: Integer;
  end;

  [NamingStyle(nsCamelCase, 'HandleTraceType'), Range(1)]
  THandleTraceType = (
    HandleTraceTypeReserved = 0,
    HandleTraceTypeOpen = 1,
    HandleTraceTypeClose = 2,
    HandleTraceTypeBadRef = 3
  );

  // ntddk.5335
  TProcessHandleTracingEntry = record
    Handle: THandle;
    ClientId: TClientId;
    TraceType: THandleTraceType;
    Stacks: array [0 .. PROCESS_HANDLE_TRACING_MAX_STACKS - 1] of Pointer;
    function StackTrace: TArray<Pointer>;
  end;

  // ntddk.5342
  TProcessHandleTracingQuery = record
    Handle: THandle;
    [Counter] TotalTraces: Integer; // Max PROCESS_HANDLE_TRACING_MAX_SLOTS
    HandleTrace: TAnysizeArray<TProcessHandleTracingEntry>;
  end;
  PProcessHandleTracingQuery = ^TProcessHandleTracingQuery;

  TProcessCycleTimeInformation = record
    AccumulatedCycles: UInt64;
    CurrentCycleCount: UInt64;
  end;
  PProcessCycleTimeInformation = TProcessCycleTimeInformation;

  TProcessWindowInformation = record
    WindowFlags: Cardinal;
    [Counter(ctBytes)] WindowTitleLength: Word;
    WindowTitle: TAnysizeArray<WideChar>;
  end;
  PProcessWindowInformation = ^TProcessWindowInformation;

  TProcessHandleTableEntryInfo = record
    HandleValue: THandle;
    HandleCount: NativeUInt;
    PointerCount: NativeUInt;
    GrantedAccess: TAccessMask;
    ObjectTypeIndex: Cardinal;
    HandleAttributes: TObjectAttributesFlags;
    [Unlisted] Reserved: Cardinal;
  end;
  PProcessHandleTableEntryInfo = ^TProcessHandleTableEntryInfo;

  [MinOSVersion(OsWin8)]
  TProcessHandleSnapshotInformation = record
    [Counter] NumberOfHandles: NativeUInt;
    [Unlisted] Reserved: NativeUInt;
    Handles: TAnysizeArray<TProcessHandleTableEntryInfo>;
  end;
  PProcessHandleSnapshotInformation = ^TProcessHandleSnapshotInformation;

  // WinNt.11590
  [MinOSVersion(OsWin8)]
  [NamingStyle(nsCamelCase, 'Process', 'Policy')]
  TProcessMitigationPolicy = (
    ProcessDEPPolicy = 0,
    ProcessASLRPolicy = 1,
    ProcessDynamicCodePolicy = 2,
    ProcessStrictHandleCheckPolicy = 3,
    ProcessSystemCallDisablePolicy = 4,
    ProcessMitigationOptionsMask = 5,
    ProcessExtensionPointDisablePolicy = 6,
    ProcessControlFlowGuardPolicy = 7,      // Win 8.1+
    ProcessSignaturePolicy = 8,             // Win 8.1+
    ProcessFontDisablePolicy = 9,           // Win 10 TH1+
    ProcessImageLoadPolicy = 10,            // Win 10 TH2+
    ProcessSystemCallFilterPolicy = 11,     // Win 10 RS3+
    ProcessPayloadRestrictionPolicy = 12,   // Win 10 RS3+
    ProcessChildProcessPolicy = 13,         // Win 10 RS3+
    ProcessSideChannelIsolationPolicy = 14  // Win 10 RS4+
  );

  [MinOSVersion(OsWin8)]
  TProcessMitigationPolicyInformation = record
    Policy: TProcessMitigationPolicy;
    [Hex] Flags: Cardinal;
  end;
  PProcessMitigationPolicyInformation = ^TProcessMitigationPolicyInformation;

  [MinOSVersion(OsWin10TH1)]
  TProcessTelemetryIdInformation = record
    [Unlisted, Bytes] HeaderSize: Cardinal;
    ProcessID: TProcessId32;
    [Hex] ProcessStartKey: UInt64;
    CreateTime: TLargeInteger;
    CreateInterruptTime: TULargeInteger;
    CreateUnbiasedInterruptTime: TULargeInteger;
    ProcessSequenceNumber: UInt64;
    SessionCreateTime: TULargeInteger;
    SessionID: TSessionId;
    BootID: Cardinal;
    [Hex] ImageChecksum: Cardinal;
    [Hex] ImageTimeDateStamp: Cardinal;
    [Unlisted] UserSidOffset: Cardinal;
    [Unlisted] ImagePathOffset: Cardinal;
    [Unlisted] PackageNameOffset: Cardinal;
    [Unlisted] RelativeAppNameOffset: Cardinal;
    [Unlisted] CommandLineOffset: Cardinal;
    function UserSid: PSid;
    function ImagePath: PWideChar;
    function PackageName: PWideChar;
    function RelativeAppName: PWideChar;
    function CommandLine: PWideChar;
  end;
  PProcessTelemetryIdInformation = ^TProcessTelemetryIdInformation;

  [MinOSVersion(OsWin10TH1)]
  TProcessJobMemoryInfo = record
    [Bytes] SharedCommitUsage: UInt64;
    [Bytes] PrivateCommitUsage: UInt64;
    [Bytes] PeakPrivateCommitUsage: UInt64;
    [Bytes] PrivateCommitLimit: UInt64;
    [Bytes] TotalCommitLimit: UInt64;
  end;
  PProcessJobMemoryInfo = ^TProcessJobMemoryInfo;

  [MinOSVersion(OsWin10TH2)]
  TProcessChildProcessInformation = record
    ProhibitChildProcesses: Boolean;
    AlwaysAllowSecureChildProcess: Boolean;
    AuditProhibitChildProcesses: Boolean;
  end;
  PTProcessChildProcessInformation = ^TProcessChildProcessInformation;

  [MinOSVersion(OsWin10RS3)]
  TProcessUptimeInformation = record
    QueryInterruptTime: TULargeInteger;
    QueryUnbiasedTime: TULargeInteger;
    EndInterruptTime: TULargeInteger;
    TimeSinceCreation: TULargeInteger;
    Uptime: TULargeInteger;
    SuspendedTime: TULargeInteger;
    [Hex] Flags: Cardinal; // PROCESS_UPTIME_*
    function HangCount: Cardinal;
    function GhostCount: Cardinal;
  end;
  PProcessUptimeInformation = ^TProcessUptimeInformation;

  // Threads

  [FriendlyName('thread'), ValidMask(THREAD_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(THREAD_TERMINATE, 'Terminate')]
  [FlagName(THREAD_SUSPEND_RESUME, 'Suspend/Resume')]
  [FlagName(THREAD_ALERT, 'Alert')]
  [FlagName(THREAD_GET_CONTEXT, 'Get Context')]
  [FlagName(THREAD_SET_CONTEXT, 'Set Context')]
  [FlagName(THREAD_SET_INFORMATION, 'Set Information')]
  [FlagName(THREAD_QUERY_INFORMATION, 'Query Information')]
  [FlagName(THREAD_SET_THREAD_TOKEN, 'Set Token')]
  [FlagName(THREAD_IMPERSONATE, 'Impersonate')]
  [FlagName(THREAD_DIRECT_IMPERSONATION, 'Direct Impersonation')]
  [FlagName(THREAD_SET_LIMITED_INFORMATION, 'Set Limited Information')]
  [FlagName(THREAD_QUERY_LIMITED_INFORMATION, 'Query Limited Information')]
  [FlagName(THREAD_RESUME, 'Resume')]
  TThreadAccessMask = type TAccessMask;

  TInitialTeb = record
    OldStackBase: Pointer;
    OldStackLimit: Pointer;
    StackBase: Pointer;
    StackLimit: Pointer;
    StackAllocationBase: Pointer;
  end;
  PInitialTeb = ^TInitialTeb;

  // ntddk.5153
  [NamingStyle(nsCamelCase, 'Thread')]
  TThreadInfoClass = (
    ThreadBasicInformation = 0,          // q: TThreadBasicInformation
    ThreadTimes = 1,                     // q: TKernelUserTimes
    ThreadPriority = 2,                  // s: Cardinal
    ThreadBasePriority = 3,              // s: Cardinal
    ThreadAffinityMask = 4,              // s: UInt64
    ThreadImpersonationToken = 5,        // s: THandle
    ThreadDescriptorTableEntry = 6,      // q:
    ThreadEnableAlignmentFaultFixup = 7, // s: Boolean
    ThreadEventPair = 8,
    ThreadQuerySetWin32StartAddress = 9, // q: Pointer
    ThreadZeroTlsCell = 10,              // s: Cardinal
    ThreadPerformanceCount = 11,         // q: UInt64
    ThreadAmILastThread = 12,            // q: LongBool (always for self)
    ThreadIdealProcessor = 13,           // s: Cardinal
    ThreadPriorityBoost = 14,            // q, s: LongBool
    ThreadSetTlsArrayAddress = 15,
    ThreadIsIoPending = 16,              // q: LongBool
    ThreadHideFromDebugger = 17,         // q: Boolean, s: zero-length data
    ThreadBreakOnTermination = 18,       // q, s: LongBool
    ThreadSwitchLegacyState = 19,        // s: (self-only)
    ThreadIsTerminated = 20,             // q: LongBool
    ThreadLastSystemCall = 21,           // q TThreadLastSyscall
    ThreadIoPriority = 22,               // q, s: Cardinal
    ThreadCycleTime = 23,                // q:
    ThreadPagePriority = 24,             // q, s: TMemoryPriority
    ThreadActualBasePriority = 25,       // q, s: Cardinal
    ThreadTebInformation = 26,           // q: TThreadTebInformation
    ThreadCSwitchMon = 27,
    ThreadCSwitchPmu = 28,
    ThreadWow64Context = 29,             // q, s:
    ThreadGroupInformation = 30,         // q, s: TGroupAffinity
    ThreadUmsInformation = 31,           // q, s:
    ThreadCounterProfiling = 32,         // q: Boolean, s:
    ThreadIdealProcessorEx = 33,         // q, s: Cardinal
    ThreadCpuAccountingInformation = 34, // q: Boolean, s: session Handle (self only), Win 8+
    ThreadSuspendCount = 35,             // q: Cardinal, Win 8.1+
    ThreadHeterogeneousCpuPolicy = 36,   // s: Win 10 TH1+
    ThreadContainerId = 37,              // q: TGuid (self only)
    ThreadNameInformation = 38,          // q, s: UNICODE_STRING
    ThreadSelectedCpuSets = 39,          // q, s:
    ThreadSystemThreadInformation = 40,  // q: TSystemThreadInformation
    ThreadActualGroupAffinity = 41,      // q: Win 10 TH2+
    ThreadDynamicCodePolicyInfo = 42,    // q, s: LongBool (setter self only), Win 8+
    ThreadExplicitCaseSensitivity = 43,  // q, s: LongBool
    ThreadWorkOnBehalfTicket = 44,       // q, s: (self only)
    ThreadSubsystemInformation = 45,     // q: TSubsystemInformationType, Win 10 RS2+
    ThreadDbgkWerReportActive = 46,      // s:
    ThreadAttachContainer = 47,          // s: job Handle
    ThreadManageWritesToExecutableMemory = 48, // Win 10 RS3+
    ThreadPowerThrottlingState = 49,     // s: Win 10 RS3+
    ThreadWorkloadClass = 50             // s: Win 10 RS5+
  );

  TThreadBasicInformation = record
    ExitStatus: NTSTATUS;
    [DontFollow] TebBaseAddress: PTeb;
    ClientId: TClientId;
    [Hex] AffinityMask: NativeUInt;
    Priority: KPRIORITY;
    BasePriority: Integer;
  end;
  PThreadBasicInformation = ^TThreadBasicInformation;

  TThreadLastSyscallWin7 = record
    FirstArgument: NativeUInt;
    SystemCallNumber: NativeUInt;
  end;

  TThreadLastSyscall = record
    FirstArgument: NativeUInt;
    SystemCallNumber: NativeUInt;
    [MinOSVersion(OsWin8)] WaitTime: UInt64;
  end;
  PThreadLastSyscall = ^TThreadLastSyscall;

  TThreadTebInformation = record
    TebInformation: Pointer;
    [Hex] TebOffset: Cardinal;
    [Bytes] BytesToRead: Cardinal;
  end;
  PThreadTebInformation = ^TThreadTebInformation;

  // WinNt.627
  TGroupAffinity = record
    [Hex] Mask: Cardinal;
    Group: Word;
    [Unlisted] Reserved: array [0..2] of Word;
  end;

  // ntddk.5833
  [MinOSVersion(OsWin10RS2)]
  [NamingStyle(nsCamelCase, 'SubsystemInformationType')]
  TSubsystemInformationType = (
    SubsystemInformationTypeWin32 = 0,
    SubsystemInformationTypeWSL = 1
  );

  TPsApcRoutine = procedure (ApcArgument1, ApcArgument2, ApcArgument3: Pointer);
    stdcall;

  // User processes and threads

  TPsAttribute = record
    [Hex] Attribute: NativeUInt;
    [Bytes] Size: NativeUInt;
    Value: NativeUInt;
    ReturnLength: PNativeUInt;
  end;
  PPsAttribute = ^TPsAttribute;

  TPsAttributeList = record
    [Counter(ctBytes)] TotalLength: NativeUInt;
    Attributes: TAnysizeArray<TPsAttribute>;
  end;
  PPsAttributeList = ^TPsAttributeList;

  [NamingStyle(nsCamelCase, 'PsCreate')]
  TPsCreateState = (
    PsCreateInitialState = 0,
    PsCreateFailOnFileOpen = 1,
    PsCreateFailOnSectionCreate = 2,
    PsCreateFailExeFormat = 3,
    PsCreateFailMachineMismatch = 4,
    PsCreateFailExeName = 5,
    PsCreateSuccess = 6
  );

  TPsCreateInfo = record
    [Bytes] Size: NativeUInt;
  case State: TPsCreateState of
    PsCreateInitialState: (
      InitFlags: Cardinal;
      AdditionalFileAccess: TAccessMask;
    );

    PsCreateFailOnSectionCreate: (
      FileHandleFail: THandle;
    );

    PsCreateFailExeFormat: (
      DllCharacteristics: Word;
    );

    PsCreateFailExeName: (
      IFEOKey: THandle;
    );

    PsCreateSuccess: (
      OutputFlags: Cardinal;
      FileHandleSuccess: THandle;
      SectionHandle: THandle;
      UserProcessParametersNative: UInt64;
      UserProcessParametersWow64: Cardinal;
      CurrentParameterFlags: Cardinal;
      PebAddressNative: UInt64;
      PebAddressWow64: Cardinal;
      ManifestAddress: UInt64;
      ManifestSize: Cardinal;
    );
  end;

  // Jobs
  [FriendlyName('job object'), ValidMask(JOB_OBJECT_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(JOB_OBJECT_ASSIGN_PROCESS, 'Assign Process')]
  [FlagName(JOB_OBJECT_SET_ATTRIBUTES, 'Set Attributes')]
  [FlagName(JOB_OBJECT_QUERY, 'Query')]
  [FlagName(JOB_OBJECT_TERMINATE, 'Terminate')]
  [FlagName(JOB_OBJECT_SET_SECURITY_ATTRIBUTES, 'Set Security Attributes')]
  [FlagName(JOB_OBJECT_IMPERSONATE, 'Impersonate')]
  TJobObjectAccessMask = type TAccessMask;

  [NamingStyle(nsCamelCase, 'JobObject'), Range(1)]
  TJobObjectInfoClass = (
    JobObjectReserved = 0,
    JobObjectBasicAccountingInformation = 1, // q: TJobObjectBasicAccountingInformation
    JobObjectBasicLimitInformation = 2,      // q, s: TJobObjectBasicLimitInformation
    JobObjectBasicProcessIdList = 3,         // q: TJobObjectBasicProcessIdList
    JobObjectBasicUIRestrictions = 4,        // q, s: TJobUiLimits
    JobObjectSecurityLimitInformation = 5,   // not supported
    JobObjectEndOfJobTimeInformation = 6,    // q, s: TJobObjectEndOfJobTimeInformation
    JobObjectAssociateCompletionPortInformation = 7, // s: TJobObjectAssociateCompletionPort
    JobObjectBasicAndIoAccountingInformation = 8, // q: TJobObjectBasicAndIoAccountingInformation
    JobObjectExtendedLimitInformation = 9,   // q, s: TJobObjectExtendedLimitInformation[V2]
    JobObjectJobSetInformation = 10,         // q: Cardinal (MemberLevel)
    JobObjectGroupInformation = 11,          // q, s: Word
    JobObjectNotificationLimitInformation = 12, // q, s: TJobObjectNotificationLimitInformation, Win 8+
    JobObjectLimitViolationInformation = 13, // q: TJobObjectLimitViolationInformation
    JobObjectGroupInformationEx = 14,        // q, s: TGroupAffinity[]
    JobObjectCpuRateControlInformation = 15, // q, s: TJobObjectCpuRateControlInformation
    JobObjectCompletionFilter = 16,          // q: Bit-mask out of TJobObjectMsg
    JobObjectCompletionCounter = 17,
    JobObjectFreezeInformation = 18,         // q, s: TJobObjectFreezeInformation
    JobObjectExtendedAccountingInformation = 19,  // q: TJobObjectExtendedAccountingInformation
    JobObjectWakeInformation = 20,                // q:
    JobObjectBackgroundInformation = 21,          // q, s: Boolean, Win 8+
    JobObjectSchedulingRankBiasInformation = 22,  // s: Boolean, Win 8+
    JobObjectTimerVirtualizationInformation = 23, // s: Boolean, Win 8+
    JobObjectCycleTimeNotification = 24,
    JobObjectClearEvent = 25,                // s: zero-length, Win 8+
    JobObjectInterferenceInformation = 26,   // q: UInt64 (Count), Win 8.1+
    JobObjectClearPeakJobMemoryUsed = 27,    // s: zero-length
    JobObjectMemoryUsageInformation = 28,    // q: TJobObjectMemoryUsageInformation[V2]
    JobObjectSharedCommit = 29,              // q: NativeUInt (SharedCommitCharge), Win 10 TH1+
    JobObjectContainerId = 30,               // q: TJobObjectContainerIdInformation[V2]
    JobObjectIoRateControlInformation = 31,  // s: TJobObjectIoRateControlInformationNative[V2/V3]
    JobObjectNetRateControlInformation = 32, // q, s: TJobObjectNetRateControlInformation
    JobObjectNotificationLimitInformation2 = 33, // q, s: TJobObjectNotificationLimitInformation2
    JobObjectLimitViolationInformation2 = 34, // q, TJobObjectLimitViolationInformation2
    JobObjectCreateSilo = 35,                 // s: zero-size
    JobObjectSiloBasicInformation = 36,       // q: TSiloObjectBasicInformation
    JobObjectSiloRootDirectory = 37,          // q, s:
    JobObjectServerSiloBasicInformation = 38,
    JobObjectServerSiloUserSharedData = 39,
    JobObjectServerSiloInitialize = 40,       // s: THandle (event), Win 10 TH1+
    JobObjectServerSiloRunningState = 41,
    JobObjectIoAttribution = 42,
    JobObjectMemoryPartitionInformation = 43, // q: Boolean, s: Handle, Win 10 RS2+
    JobObjectContainerTelemetryId = 44,       // q, s: TGuid, Win 10 RS2+
    JobObjectSiloSystemRoot = 45,
    JobObjectEnergyTrackingState = 46,
    JobObjectThreadImpersonationInformation = 47 // s: Boolean (Disallow), Win 10 RS2+
  );

  // WinNt.11831, info class 1
  TJobObjectBasicAccountingInformation = record
    TotalUserTime: TULargeInteger;
    TotalKernelTime: TULargeInteger;
    ThisPeriodTotalUserTime: TULargeInteger;
    ThisPeriodTotalKernelTime: TULargeInteger;
    TotalPageFaultCount: Cardinal;
    TotalProcesses: Cardinal;
    ActiveProcesses: Cardinal;
    TotalTerminatedProcesses: Cardinal;
  end;
  PJobObjectBasicAccountingInformation = ^TJobObjectBasicAccountingInformation;

  [FlagName(JOB_OBJECT_LIMIT_WORKINGSET, 'Working Set')]
  [FlagName(JOB_OBJECT_LIMIT_PROCESS_TIME, 'Process Time')]
  [FlagName(JOB_OBJECT_LIMIT_JOB_TIME, 'Job Time')]
  [FlagName(JOB_OBJECT_LIMIT_ACTIVE_PROCESS, 'Active Prcesses')]
  [FlagName(JOB_OBJECT_LIMIT_AFFINITY, 'Affinity')]
  [FlagName(JOB_OBJECT_LIMIT_PRIORITY_CLASS, 'Priority')]
  [FlagName(JOB_OBJECT_LIMIT_PRESERVE_JOB_TIME, 'Preserve Job Time')]
  [FlagName(JOB_OBJECT_LIMIT_SCHEDULING_CLASS, 'Scheduling Class')]
  [FlagName(JOB_OBJECT_LIMIT_PROCESS_MEMORY, 'Per-process Memory')]
  [FlagName(JOB_OBJECT_LIMIT_JOB_MEMORY, 'Job Memory')]
  [FlagName(JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION, 'Die On Unhandled Exceptions')]
  [FlagName(JOB_OBJECT_LIMIT_BREAKAWAY_OK, 'Breakaway OK')]
  [FlagName(JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK, 'Silent Breakaway')]
  [FlagName(JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE, 'Kill On Job Close')]
  [FlagName(JOB_OBJECT_LIMIT_SUBSET_AFFINITY, 'Subset Affinity')]
  [FlagName(JOB_OBJECT_LIMIT_JOB_MEMORY_LOW, 'Job Memory Low')]
  [FlagName(JOB_OBJECT_LIMIT_JOB_READ_BYTES, 'Job Read Bytes')]
  [FlagName(JOB_OBJECT_LIMIT_JOB_WRITE_BYTES, 'Job Write Bytes')]
  [FlagName(JOB_OBJECT_LIMIT_CPU_RATE_CONTROL, 'CPU Rate Control')]
  [FlagName(JOB_OBJECT_LIMIT_IO_RATE_CONTROL, 'I/O Rate Control')]
  [FlagName(JOB_OBJECT_LIMIT_NET_RATE_CONTROL, 'Net Rate Control')]
  [FlagName(JOB_OBJECT_LIMIT_SILO_READY, 'Silo-ready')]
  TJobLimits = type Cardinal;

  // WinNt.11842, info class 2
  TJobObjectBasicLimitInformation = record
    PerProcessUserTimeLimit: TULargeInteger;
    PerJobUserTimeLimit: TULargeInteger;
    LimitFlags: TJobLimits;
    [Bytes] MinimumWorkingSetSize: NativeUInt;
    [Bytes] MaximumWorkingSetSize: NativeUInt;
    ActiveProcessLimit: Cardinal;
    [Hex] Affinity: NativeUInt;
    PriorityClass: Cardinal;
    SchedulingClass: Cardinal; // 0..9
  end;
  PJobObjectBasicLimitInformation = ^TJobObjectBasicLimitInformation;

  // WinNt.11865, info class 3
  TJobObjectBasicProcessIdList = record
    NumberOfAssignedProcesses: Cardinal;
    [Counter] NumberOfProcessIdsInList: Cardinal;
    ProcessIdList: TAnysizeArray<TProcessId>;
  end;
  PJobObjectBasicProcessIdList = ^TJobObjectBasicProcessIdList;

  // WinNt.12241, info class 4
  [FlagName(JOB_OBJECT_UILIMIT_HANDLES, 'Handles')]
  [FlagName(JOB_OBJECT_UILIMIT_READCLIPBOARD, 'Read Clibboard')]
  [FlagName(JOB_OBJECT_UILIMIT_WRITECLIPBOARD, 'Write Clipboard')]
  [FlagName(JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS, 'System Parameters')]
  [FlagName(JOB_OBJECT_UILIMIT_DISPLAYSETTINGS, 'Display Settings')]
  [FlagName(JOB_OBJECT_UILIMIT_GLOBALATOMS, 'Global Atoms')]
  [FlagName(JOB_OBJECT_UILIMIT_DESKTOP, 'Desktop')]
  [FlagName(JOB_OBJECT_UILIMIT_EXITWINDOWS, 'Exit Windows')]
  TJobUiLimits = type Cardinal;

  // WinNt.12147, info class 6
  [NamingStyle(nsSnakeCase, 'JOB_OBJECT', 'AT_END_OF_JOB')]
  TJobObjectEndOfJobTimeInformation = (
    JOB_OBJECT_TERMINATE_AT_END_OF_JOB = 0,
    JOB_OBJECT_POST_AT_END_OF_JOB = 1
  );

  // WinNt.12156
  [NamingStyle(nsSnakeCase, 'JOB_OBJECT_MSG'), ValidMask($3FDE)]
  TJobObjectMsg = (
    JOB_OBJECT_MSG_RESERVED0 = 0,
    JOB_OBJECT_MSG_END_OF_JOB_TIME = 1,
    JOB_OBJECT_MSG_END_OF_PROCESS_TIME = 2,
    JOB_OBJECT_MSG_ACTIVE_PROCESS_LIMIT = 3,
    JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO = 4,
    JOB_OBJECT_MSG_RESERVED5 = 5,
    JOB_OBJECT_MSG_NEW_PROCESS = 6,
    JOB_OBJECT_MSG_EXIT_PROCESS = 7,
    JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS = 8,
    JOB_OBJECT_MSG_PROCESS_MEMORY_LIMIT = 9,
    JOB_OBJECT_MSG_JOB_MEMORY_LIMIT = 10,
    JOB_OBJECT_MSG_NOTIFICATION_LIMIT = 11,
    JOB_OBJECT_MSG_JOB_CYCLE_TIME_LIMIT = 12,
    JOB_OBJECT_MSG_SILO_TERMINATED = 13
  );

  // WinNt.11891, info class 7
  TJobObjectAssociateCompletionPort = record
    CompletionKey: Pointer;
    CompletionPort: THandle; // Can be 0 for Win 8+
  end;
  PJobObjectAssociateCompletionPort = ^TJobObjectAssociateCompletionPort;

  // WinNt.11896, info class 8
  TJobObjectBasicAndIoAccountingInformation = record
    [Aggregate] BasicInfo: TJobObjectBasicAccountingInformation;
    [Aggregate] IoInfo: TIoCounters;
  end;
  PJobObjectBasicAndIoAccountingInformation = ^TJobObjectBasicAndIoAccountingInformation;

  // WinNt.11854, info class 9
  TJobObjectExtendedLimitInformation = record
    [Aggregate] BasicLimitInformation: TJobObjectBasicLimitInformation;
    [Aggregate] IoInfo: TIoCounters;
    [Bytes] ProcessMemoryLimit: NativeUInt;
    [Bytes] JobMemoryLimit: NativeUInt;
    [Bytes] PeakProcessMemoryUsed: NativeUInt;
    [Bytes] PeakJobMemoryUsed: NativeUInt;
  end;
  PJobObjectExtendedLimitInformation = ^TJobObjectExtendedLimitInformation;

  // Info class 9
  [MinOSVersion(OsWin10TH1)] // approx.
  TJobObjectExtendedLimitInformationV2 = record
    [Aggregate] V1: TJobObjectExtendedLimitInformation;
    [Bytes] JobTotalMemoryLimit: NativeUInt;
  end;
  PJobObjectExtendedLimitInformationV2 = ^TJobObjectExtendedLimitInformationV2;

  // WinNt.11905
  [NamingStyle(nsCamelCase, 'Tolerance')]
  TJobObjectRateControlTolerance = (
    ToleranceNone = 0,
    ToleranceLow = 1,    // 20%
    ToleranceMedium = 2, // 40%
    ToleranceHigh = 3    // 60%
  );

  // WinNt.11911
  [NamingStyle(nsCamelCase, 'ToleranceInterval')]
  TJobObjectRateControlToleranceInterval = (
    ToleranceIntervalNone = 0,
    ToleranceIntervalShort = 1,  // 10 sec
    ToleranceIntervalMedium = 2, // 1 min
    ToleranceIntervalLong = 3    // 10 min
  );

  // WinNt.11918, info class 12
  [MinOSVersion(OsWin8)]
  TJobObjectNotificationLimitInformation = record
    [Bytes] IoReadBytesLimit: UInt64;
    [Bytes] IoWriteBytesLimit: UInt64;
    PerJobUserTimeLimit: TULargeInteger;
    [Bytes] JobMemoryLimit: UInt64;
    RateControlTolerance: TJobObjectRateControlTolerance;
    RateControlToleranceInterval: TJobObjectRateControlToleranceInterval;
    LimitFlags: TJobLimits;
  end;
  PJobObjectNotificationLimitInformation = ^TJobObjectNotificationLimitInformation;

  // WinNt.11957, info class 13
  [MinOSVersion(OsWin8)]
  TJobObjectLimitViolationInformation = record
    LimitFlags: TJobLimits;
    ViolationLimitFlags: TJobLimits;
    [Bytes] IoReadBytes: UInt64;
    [Bytes] IoReadBytesLimit: UInt64;
    [Bytes] IoWriteBytes: UInt64;
    [Bytes] IoWriteBytesLimit: UInt64;
    PerJobUserTime: TULargeInteger;
    PerJobUserTimeLimit: TULargeInteger;
    [Bytes] JobMemory: UInt64;
    [Bytes] JobMemoryLimit: UInt64;
    RateControlTolerance: TJobObjectRateControlTolerance;
    RateControlToleranceLimit: TJobObjectRateControlTolerance;
  end;
  PJobObjectLimitViolationInformation = ^TJobObjectLimitViolationInformation;

  [FlagName(JOB_OBJECT_CPU_RATE_CONTROL_ENABLE, 'Enabled')]
  [FlagName(JOB_OBJECT_CPU_RATE_CONTROL_WEIGHT_BASED, 'Weight-based')]
  [FlagName(JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP, 'Hard Cap')]
  [FlagName(JOB_OBJECT_CPU_RATE_CONTROL_NOTIFY, 'Notify')]
  [FlagName(JOB_OBJECT_CPU_RATE_CONTROL_MIN_MAX_RATE, 'Min/Max Rate')]
  TJobRateControlFlags = type Cardinal;

  // WinNt.12005, info class 15
  [MinOSVersion(OsWin8)]
  TJobObjectCpuRateControlInformation = record
  case ControlFlags: TJobRateControlFlags of
    0: (CpuRate: Cardinal); // 0..10000 (corresponds to 0..100%)
    1: (Weight: Cardinal);  // 1..9
    2: (MinRate: Word; MaxRate: Word); // 0..10000 each, Win 10 TH1+
  end;
  PJobObjectCpuRateControlInformation = ^TJobObjectCpuRateControlInformation;

  [MinOSVersion(OsWin8)]
  TJobObjectWakeFilter = record
    HighEdgeFilter: Cardinal;
    LowEdgeFilter: Cardinal;
  end;

  // info class 18
  [MinOSVersion(OsWin8)]
  TJobObjectFreezeInformation = record
    [Hex] Flags: Cardinal; // JOB_OBJECT_OPERATION_*
    Freeze: Boolean;
    Swap: Boolean;
    Reserved0: Word;
    WakeFilter: TJobObjectWakeFilter;
  end;
  PJobObjectFreezeInformation = ^TJobObjectFreezeInformation;

  // info class 19
  [MinOSVersion(OsWin8)]
  TJobObjectExtendedAccountingInformation = record
    [Aggregate] BasicInfo: TJobObjectBasicAccountingInformation;
    [Aggregate] IoInfo: TIoCounters;
    [Aggregate] DiskIoInfo: TProcessDiskCounters;
    ContextSwitches: UInt64;
    TotalCycleTime: UInt64;
    ReadyTime: TULargeInteger;
    [Aggregate, MinOSVersion(OsWin10RS2)] EnergyValues: TProcessEnergyValues;
  end;
  PJobObjectExtendedAccountingInformation = ^TJobObjectExtendedAccountingInformation;

  // info class 28
  [MinOSVersion(OsWin10TH1)]
  TJobObjectMemoryUsageInformation = record
    [Bytes] JobMemory: UInt64;
    [Bytes] PeakJobMemoryUsed: UInt64;
  end;
  PJobObjectMemoryUsageInformation = ^TJobObjectMemoryUsageInformation;

  // info class 28
  [MinOSVersion(OsWin10TH1)]
  TJobObjectMemoryUsageInformationV2 = record
    [Aggregate] V1: TJobObjectMemoryUsageInformation;
    [Bytes] JobSharedMemory: UInt64;
    [Unlisted] Reserved: array [0..1] of UInt64;
  end;
  PJobObjectMemoryUsageInformationV2 = ^TJobObjectMemoryUsageInformationV2;

  // info class 30
  [MinOSVersion(OsWin10TH1)]
  TJobObjectContainerIdInformation = type TGuid;

  // info class 30
  [MinOSVersion(OsWin10RS2)]
  TJobObjectContainerIdInformationV2 = record
    ContainerID: TGuid;
    ContainerTelemetryID: TGuid;
    JobID: Cardinal;
  end;
  PJobObjectContainerIdInformationV2 = ^TJobObjectContainerIdInformationV2;

  [FlagName(JOB_OBJECT_IO_RATE_CONTROL_ENABLE, 'Enabled')]
  [FlagName(JOB_OBJECT_IO_RATE_CONTROL_STANDALONE_VOLUME, 'Standalone Volume')]
  [FlagName(JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ALL, 'Force Unit Access All')]
  [FlagName(JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ON_SOFT_CAP, 'Force Unit Access On Soft Cap')]
  TJobIoRateControlFlags = type Cardinal;

  // WinNt.12070, info class 31
  [MinOSVersion(OsWin10TH1)]
  TJobObjectIoRateControlInformationNative = record
    MaxIops: UInt64;
    MaxBandwidth: UInt64;
    ReservationIops: UInt64;
    VolumeName: PWideChar;
    [Bytes] BaseIoSize: Cardinal;
    ControlFlags: TJobIoRateControlFlags;
    VolumeNameLength: Word;
  end;
  PJobObjectIoRateControlInformationNative = ^TJobObjectIoRateControlInformationNative;

  // WinNt.12083, info class 31
  [MinOSVersion(OsWin10RS1)]
  TJobObjectIoRateControlInformationNativeV2 = record
    V1: TJobObjectIoRateControlInformationNative;
    CriticalReservationIops: UInt64;
    ReservationBandwidth: UInt64;
    CriticalReservationBandwidth: UInt64;
    MaxTimePercent: UInt64;
    ReservationTimePercent: UInt64;
    CriticalReservationTimePercent: UInt64;
  end;
  PJobObjectIoRateControlInformationNativeV2 = ^TJobObjectIoRateControlInformationNativeV2;

  // WinNt.12099, info class 31
  [MinOSVersion(OsWin10RS2)]
  TJobObjectIoRateControlInformationNativeV3 = record
    V2: TJobObjectIoRateControlInformationNativeV2;
    SoftMaxIops: UInt64;
    SoftMaxBandwidth: UInt64;
    SoftMaxTimePercent: UInt64;
    LimitExcessNotifyIops: UInt64;
    LimitExcessNotifyBandwidth: UInt64;
    LimitExcessNotifyTimePercent: UInt64;
  end;
  PJobObjectIoRateControlInformationNativeV3 = ^TJobObjectIoRateControlInformationNativeV3;

  [FlagName(JOB_OBJECT_NET_RATE_CONTROL_ENABLE, 'Enabled')]
  [FlagName(JOB_OBJECT_NET_RATE_CONTROL_MAX_BANDWIDTH, 'Max Bandwidth')]
  [FlagName(JOB_OBJECT_NET_RATE_CONTROL_DSCP_TAG, 'DSCP Tag')]
  TJobNetControlFlags = type Cardinal;

  // info class 32
  [MinOSVersion(OsWin10TH1)]
  TJobObjectNetRateControlInformation = record
    [Bytes] MaxBandwidth: UInt64;
    ControlFlags: TJobNetControlFlags;
    [Hex] DscpTag: Byte; // 0x00..0x3F
  end;
  PJobObjectNetRateControlInformation = ^TJobObjectNetRateControlInformation;

  // WinNt.11928, info class 33
  [MinOSVersion(OsWin10TH1)]
  TJobObjectNotificationLimitInformation2 = record
    [Aggregate] v1: TJobObjectNotificationLimitInformation;
    IoRateControlTolerance: TJobObjectRateControlTolerance;
    [Bytes] JobLowMemoryLimit: UInt64;
    IoRateControlToleranceInterval: TJobObjectRateControlToleranceInterval;
    NetRateControlTolerance: TJobObjectRateControlTolerance;
    NetRateControlToleranceInterval: TJobObjectRateControlToleranceInterval;
  end;
  PJobObjectNotificationLimitInformation2 = ^TJobObjectNotificationLimitInformation2;

  // WinNt.11928, info class 34
  [MinOSVersion(OsWin10TH1)]
  TJobObjectLimitViolationInformation2 = record
    [Aggregate] v1: TJobObjectLimitViolationInformation;
    [Bytes] JobLowMemoryLimit: UInt64;
    IoRateControlTolerance: TJobObjectRateControlTolerance;
    IoRateControlToleranceLimit: TJobObjectRateControlTolerance;
    NetRateControlTolerance: TJobObjectRateControlTolerance;
    NetRateControlToleranceLimit: TJobObjectRateControlTolerance;
  end;
  PJobObjectLimitViolationInformation2 = ^TJobObjectLimitViolationInformation2;

  // WinNt.12327, info class 36
  [MinOSVersion(OsWin10TH1)]
  TSiloObjectBasicInformation = record
    SiloID: Cardinal;
    SiloParentID: Cardinal;
    NumberOfProcesses: Cardinal;
    IsInServerSilo: Boolean;
    Reserved: array [0..2] of Byte;
  end;
  PSiloObjectBasicInformation = ^TSiloObjectBasicInformation;

  TJobSetArray = record
    JobHandle: THandle;
    MemberLevel: Cardinal;
    [Unlisted] Flags: Cardinal;
  end;

// Processes

function NtCreateProcess(out ProcessHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; ParentProcess: THandle;
  InheritObjectTable: Boolean; SectionHandle: THandle; DebugPort: THandle;
  ExceptionPort: THandle): NTSTATUS; stdcall; external ntdll;

function NtCreateProcessEx(out ProcessHandle: THandle; DesiredAccess:
  TAccessMask; ObjectAttributes: PObjectAttributes; ParentProcess: THandle;
  Flags: Cardinal; SectionHandle: THandle; DebugPort: THandle; ExceptionPort:
  THandle; JobMemberLevel: Cardinal): NTSTATUS; stdcall; external ntdll;

// ntddk.5875
function NtOpenProcess(out ProcessHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; const ClientId: TClientId):
  NTSTATUS; stdcall; external ntdll;

// ntddk.15688
function NtTerminateProcess(ProcessHandle: THandle; ExitStatus: NTSTATUS):
  NTSTATUS; stdcall; external ntdll;

function NtSuspendProcess(ProcessHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtResumeProcess(ProcessHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

// winternl.626
function NtQueryInformationProcess(ProcessHandle: THandle;
  ProcessInformationClass: TProcessInfoClass; ProcessInformation: Pointer;
  ProcessInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS;
  stdcall; external ntdll;

function NtSetInformationProcess(ProcessHandle: THandle;
  ProcessInformationClass: TProcessInfoClass; ProcessInformation: Pointer;
  ProcessInformationLength: Cardinal): NTSTATUS; stdcall; external ntdll;

// Absent in ReactOS
function NtGetNextProcess(ProcessHandle: THandle; DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags; Flags: Cardinal;
  out NewProcessHandle: THandle): NTSTATUS; stdcall; external ntdll delayed;

// Absent in ReactOS
function NtGetNextThread(ProcessHandle: THandle; ThreadHandle: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: TObjectAttributesFlags;
  Flags: Cardinal; out NewThreadHandle: THandle): NTSTATUS; stdcall;
  external ntdll delayed;

// Threads

function NtCreateThread(out ThreadHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; ProcessHandle: THandle; out ClientId:
  TClientId; const ThreadContext: TContext; const InitialTeb: TInitialTeb;
  CreateSuspended: Boolean): NTSTATUS; stdcall; external ntdll;

function NtOpenThread(out ThreadHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; const ClientId: TClientId):
  NTSTATUS; stdcall; external ntdll;

function NtTerminateThread(ThreadHandle: THandle; ExitStatus: NTSTATUS):
  NTSTATUS; stdcall; external ntdll;

function NtSuspendThread(ThreadHandle: THandle; PreviousSuspendCount:
  PCardinal = nil): NTSTATUS; stdcall; external ntdll;

function NtResumeThread(ThreadHandle: THandle; PreviousSuspendCount:
  PCardinal = nil): NTSTATUS; stdcall; external ntdll;

function NtGetCurrentProcessorNumber: Cardinal; stdcall; external ntdll;

function NtGetContextThread(ThreadHandle: THandle; ThreadContext: PContext):
  NTSTATUS; stdcall; external ntdll;

function NtSetContextThread(ThreadHandle: THandle; ThreadContext: PContext):
  NTSTATUS; stdcall; external ntdll;

// winternl.640
function NtQueryInformationThread(ThreadHandle: THandle;
  ThreadInformationClass: TThreadInfoClass; ThreadInformation: Pointer;
  ThreadInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS;
  stdcall; external ntdll;

// ntddk.15553
function NtSetInformationThread(ThreadHandle: THandle;
  ThreadInformationClass: TThreadInfoClass; ThreadInformation: Pointer;
  ThreadInformationLength: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtAlertThread(ThreadHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtAlertResumeThread(ThreadHandle: THandle; PreviousSuspendCount:
  PCardinal): NTSTATUS; stdcall; external ntdll;

function NtTestAlert: NTSTATUS; stdcall; external ntdll;

function NtImpersonateThread(ServerThreadHandle: THandle;
  ClientThreadHandle: THandle; const SecurityQos: TSecurityQualityOfService):
  NTSTATUS; stdcall; external ntdll;

function NtRegisterThreadTerminatePort(PortHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtQueueApcThread(ThreadHandle: THandle; ApcRoutine: TPsApcRoutine;
  ApcArgument1, ApcArgument2, ApcArgument3: Pointer): NTSTATUS; stdcall;
  external ntdll;

// User processes and threads

function NtCreateUserProcess(out ProcessHandle: THandle; out ThreadHandle:
  THandle; ProcessDesiredAccess: TAccessMask; ThreadDesiredAccess: TAccessMask;
  ProcessObjectAttributes: PObjectAttributes; ThreadObjectAttributes:
  PObjectAttributes; ProcessFlags: Cardinal; ThreadFlags: Cardinal;
  ProcessParameters: PRtlUserProcessParameters; var CreateInfo: TPsCreateInfo;
  AttributeList: PPsAttributeList): NTSTATUS; stdcall; external ntdll;

function NtCreateThreadEx(out ThreadHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; ProcessHandle: THandle; StartRoutine:
  TUserThreadStartRoutine; Argument: Pointer; CreateFlags: Cardinal; ZeroBits:
  NativeUInt; StackSize: NativeUInt; MaximumStackSize: NativeUInt;
  AttributeList: PPsAttributeList): NTSTATUS; stdcall; external ntdll;

// Job objects

function NtCreateJobObject(out JobHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes): NTSTATUS; stdcall; external ntdll;

function NtOpenJobObject(out JobHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes): NTSTATUS; stdcall; external ntdll;

function NtAssignProcessToJobObject(JobHandle: THandle; ProcessHandle: THandle):
  NTSTATUS; stdcall; external ntdll;

function NtTerminateJobObject(JobHandle: THandle; ExitStatus: NTSTATUS):
  NTSTATUS; stdcall; external ntdll;

function NtIsProcessInJob(ProcessHandle: THandle;
  JobHandle: THandle): NTSTATUS; stdcall; external ntdll;

function NtQueryInformationJobObject(JobHandle: THandle;
  JobObjectInformationClass: TJobObjectInfoClass; JobObjectInformation: Pointer;
  JobObjectInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS;
  stdcall; external ntdll;

function NtSetInformationJobObject(JobHandle: THandle;
  JobObjectInformationClass: TJobObjectInfoClass; JobObjectInformation: Pointer;
  JobObjectInformationLength: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtCreateJobSet(NumJob: Cardinal; UserJobSet: TArray<TJobSetArray>;
  Flags: Cardinal): NTSTATUS; stdcall; external ntdll;

{ Expected Access / Privileges }

function ExpectedProcessQueryAccess(InfoClass: TProcessInfoClass):
  TProcessAccessMask;

function ExpectedProcessSetPrivilege(InfoClass: TProcessInfoClass):
  TSeWellKnownPrivilege;

function ExpectedProcessSetAccess(InfoClass: TProcessInfoClass):
  TProcessAccessMask;

function ExpectedThreadQueryAccess(InfoClass: TThreadInfoClass):
  TThreadAccessMask;

function ExpectedThreadSetPrivilege(InfoClass: TThreadInfoClass):
  TSeWellKnownPrivilege;

function ExpectedThreadSetAccess(InfoClass: TThreadInfoClass):
  TThreadAccessMask;

implementation

function NtCurrentProcessId: TProcessId;
begin
  Result := NtCurrentTeb.ClientId.UniqueProcess;
end;

function NtCurrentThreadId: TThreadId;
begin
  Result := NtCurrentTeb.ClientId.UniqueThread;
end;

{ TProcessHandleTracingEntry }

function TProcessHandleTracingEntry.StackTrace: TArray<Pointer>;
var
  Count: Integer;
begin
  Count := 0;

  // Determine the amount for entries in the stack trace
  while (Count <= High(Stacks)) and Assigned(Stacks[Count]) do
    Inc(Count);

  SetLength(Result, Count);
  Move(Stacks, Pointer(Result)^, Count * SizeOf(Pointer));
end;

{ TProcessTelemetryIdInformation }

function TProcessTelemetryIdInformation.CommandLine: PWideChar;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).CommandLineOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + CommandLineOffset)
  else
    Result := nil;
end;

function TProcessTelemetryIdInformation.ImagePath: PWideChar;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).ImagePathOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + ImagePathOffset)
  else
    Result := nil;
end;

function TProcessTelemetryIdInformation.PackageName: PWideChar;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).PackageNameOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + PackageNameOffset)
  else
    Result := nil;
end;

function TProcessTelemetryIdInformation.RelativeAppName: PWideChar;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).RelativeAppNameOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + RelativeAppNameOffset)
  else
    Result := nil;
end;

function TProcessTelemetryIdInformation.UserSid: PSid;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).UserSidOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + UserSidOffset)
  else
    Result := nil;
end;

{ TProcessUptimeInformation }

function TProcessUptimeInformation.GhostCount: Cardinal;
begin
  Result := (Flags and $F0) shr 4;
end;

function TProcessUptimeInformation.HangCount: Cardinal;
begin
  Result := Flags and $F;
end;

{ Expected Access }

function ExpectedProcessQueryAccess(InfoClass: TProcessInfoClass):
  TProcessAccessMask;
begin
  case InfoClass of
    ProcessBasicInformation, ProcessQuotaLimits, ProcessIoCounters,
    ProcessVmCounters, ProcessTimes, ProcessDefaultHardErrorMode,
    ProcessPooledUsageAndLimits, ProcessAffinityMask, ProcessPriorityClass,
    ProcessHandleCount, ProcessPriorityBoost, ProcessSessionInformation,
    ProcessWow64Information, ProcessImageFileName, ProcessLUIDDeviceMapsEnabled,
    ProcessIoPriority, ProcessImageInformation, ProcessCycleTime,
    ProcessPagePriority, ProcessImageFileNameWin32, ProcessAffinityUpdateMode,
    ProcessMemoryAllocationMode, ProcessGroupInformation,
    ProcessConsoleHostProcess, ProcessWindowInformation,
    ProcessCommandLineInformation, ProcessTelemetryIdInformation,
    ProcessCommitReleaseInformation, ProcessDefaultCpuSetsInformation,
    ProcessAllowedCpuSetsInformation, ProcessJobMemoryInformation,
    ProcessInPrivate, ProcessRaiseUMExceptionOnInvalidHandleClose,
    ProcessIumChallengeResponse, ProcessHighGraphicsPriorityInformation,
    ProcessSubsystemInformation, ProcessEnergyValues,
    ProcessActivityThrottleState, ProcessWakeInformation,
    ProcessEnergyTrackingState, ProcessTelemetryCoverage,
    ProcessEnableReadWriteVmLogging, ProcessUptimeInformation,
    ProcessSequenceNumber, ProcessSecurityDomainInformation,
    ProcessEnableLogging:
      Result := PROCESS_QUERY_LIMITED_INFORMATION;

    ProcessDebugPort, ProcessWorkingSetWatch, ProcessWx86Information,
    ProcessDeviceMap, ProcessBreakOnTermination, ProcessDebugObjectHandle,
    ProcessDebugFlags, ProcessHandleTracing, ProcessExecuteFlags,
    ProcessWorkingSetWatchEx, ProcessImageFileMapping, ProcessHandleInformation,
    ProcessMitigationPolicy, ProcessHandleCheckingMode, ProcessKeepAliveCount,
    ProcessCheckStackExtentsMode, ProcessChildProcessInformation,
    ProcessWin32kSyscallFilterInformation:
      Result := PROCESS_QUERY_INFORMATION;

    ProcessCookie:
      Result := PROCESS_VM_WRITE;

    ProcessLdtInformation:
      Result := PROCESS_QUERY_INFORMATION or PROCESS_VM_READ;

    ProcessHandleTable:
      Result := PROCESS_QUERY_INFORMATION or PROCESS_DUP_HANDLE;

    ProcessCaptureTrustletLiveDump:
      Result := PROCESS_QUERY_INFORMATION or PROCESS_VM_READ or
        PROCESS_VM_OPERATION;
  else
    Result := 0;
  end;
end;

function ExpectedProcessSetPrivilege(InfoClass: TProcessInfoClass):
  TSeWellKnownPrivilege;
begin
  case InfoClass of
    ProcessQuotaLimits:
      Result := SE_INCREASE_QUOTA_PRIVILEGE;

    ProcessBasePriority, ProcessIoPriority:
      Result := SE_INCREASE_BASE_PRIORITY_PRIVILEGE;

    ProcessExceptionPort, ProcessUserModeIOPL, ProcessWx86Information,
    ProcessSessionInformation, ProcessHighGraphicsPriorityInformation,
    ProcessEnableReadWriteVmLogging, ProcessSystemResourceManagement,
    ProcessEnableLogging:
      Result := SE_TCB_PRIVILEGE;

    ProcessAccessToken:
      Result := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;

    ProcessBreakOnTermination, ProcessInstrumentationCallback,
    ProcessCheckStackExtentsMode, ProcessActivityThrottleState:
      Result := SE_DEBUG_PRIVILEGE;
  else
    Result := Default(TSeWellKnownPrivilege);
  end;
end;

function ExpectedProcessSetAccess(InfoClass: TProcessInfoClass):
  TProcessAccessMask;
begin
  case InfoClass of
    ProcessBasePriority, ProcessRaisePriority, ProcessAccessToken,
    ProcessDefaultHardErrorMode, ProcessIoPortHandlers, ProcessWorkingSetWatch,
    ProcessUserModeIOPL, ProcessEnableAlignmentFaultFixup, ProcessPriorityClass,
    ProcessWx86Information, ProcessAffinityMask, ProcessPriorityBoost,
    ProcessDeviceMap, ProcessForegroundInformation, ProcessBreakOnTermination,
    ProcessDebugFlags, ProcessHandleTracing, ProcessIoPriority,
    ProcessPagePriority, ProcessInstrumentationCallback,
    ProcessWorkingSetWatchEx, ProcessMemoryAllocationMode,
    ProcessTokenVirtualizationEnabled, ProcessHandleCheckingMode,
    ProcessCheckStackExtentsMode, ProcessMemoryExhaustion,
    ProcessFaultInformation, ProcessSubsystemProcess, ProcessInPrivate,
    ProcessRaiseUMExceptionOnInvalidHandleClose, ProcessEnergyTrackingState:
      Result := PROCESS_SET_INFORMATION;

    ProcessRevokeFileHandles, ProcessWorkingSetControl,
    ProcessDefaultCpuSetsInformation, ProcessIumChallengeResponse,
    ProcessHighGraphicsPriorityInformation, ProcessActivityThrottleState,
    ProcessDisableSystemAllowedCpuSets, ProcessEnableReadWriteVmLogging,
    ProcessSystemResourceManagement, ProcessLoaderDetour,
    ProcessCombineSecurityDomainsInformation, ProcessEnableLogging:
      Result := PROCESS_SET_LIMITED_INFORMATION;

    ProcessExceptionPort:
      Result := PROCESS_SUSPEND_RESUME;

    ProcessQuotaLimits:
      Result := PROCESS_SET_QUOTA;

    ProcessSessionInformation:
      Result := PROCESS_SET_INFORMATION or PROCESS_SET_SESSIONID;

    ProcessLdtInformation, ProcessLdtSize, ProcessTelemetryCoverage:
      Result := PROCESS_SET_INFORMATION or PROCESS_VM_WRITE;
  else
    Result := 0;
  end;
end;

function ExpectedThreadQueryAccess(InfoClass: TThreadInfoClass):
  TThreadAccessMask;
begin
  case InfoClass of
    ThreadBasicInformation, ThreadTimes, ThreadAmILastThread,
    ThreadPriorityBoost, ThreadIsTerminated, ThreadIoPriority, ThreadCycleTime,
    ThreadPagePriority, ThreadGroupInformation, ThreadIdealProcessorEx,
    ThreadSuspendCount, ThreadNameInformation, ThreadSelectedCpuSets,
    ThreadSystemThreadInformation, ThreadActualGroupAffinity,
    ThreadDynamicCodePolicyInfo, ThreadExplicitCaseSensitivity,
    ThreadSubsystemInformation:
      Result := THREAD_QUERY_LIMITED_INFORMATION;

    ThreadDescriptorTableEntry, ThreadQuerySetWin32StartAddress,
    ThreadPerformanceCount, ThreadIsIoPending, ThreadHideFromDebugger,
    ThreadBreakOnTermination, ThreadUmsInformation, ThreadCounterProfiling,
    ThreadCpuAccountingInformation:
      Result := THREAD_QUERY_INFORMATION;

    ThreadLastSystemCall, ThreadWow64Context:
      Result := THREAD_GET_CONTEXT;

    ThreadTebInformation:
      Result := THREAD_GET_CONTEXT or THREAD_SET_CONTEXT;
  else
    Result := 0;
  end;
end;

function ExpectedThreadSetPrivilege(InfoClass: TThreadInfoClass):
  TSeWellKnownPrivilege;
begin
  case InfoClass of
    ThreadBreakOnTermination, ThreadExplicitCaseSensitivity:
      Result := SE_DEBUG_PRIVILEGE;

    ThreadPriority, ThreadIoPriority, ThreadActualBasePriority:
      Result := SE_INCREASE_BASE_PRIORITY_PRIVILEGE;
  else
    Result := Default(TSeWellKnownPrivilege);
  end;
end;

function ExpectedThreadSetAccess(InfoClass: TThreadInfoClass):
  TThreadAccessMask;
begin
  case InfoClass of
    ThreadPriority, ThreadBasePriority, ThreadAffinityMask, ThreadPriorityBoost,
    ThreadActualBasePriority, ThreadHeterogeneousCpuPolicy,
    ThreadNameInformation, ThreadSelectedCpuSets:
      Result := THREAD_SET_LIMITED_INFORMATION;

    ThreadEnableAlignmentFaultFixup, ThreadZeroTlsCell,
    ThreadIdealProcessor, ThreadHideFromDebugger, ThreadBreakOnTermination,
    ThreadIoPriority, ThreadPagePriority, ThreadGroupInformation,
    ThreadCounterProfiling, ThreadIdealProcessorEx,
    ThreadExplicitCaseSensitivity, ThreadDbgkWerReportActive,
    ThreadPowerThrottlingState:
      Result := THREAD_SET_INFORMATION;

    ThreadWow64Context:
      Result := THREAD_SET_CONTEXT;

    ThreadImpersonationToken:
      Result := THREAD_SET_THREAD_TOKEN;
  else
    Result := 0;
  end;
end;

end.
