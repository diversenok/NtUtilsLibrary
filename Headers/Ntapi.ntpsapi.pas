unit Ntapi.ntpsapi;

{
  This module provides declarations for interacting with processes, threads, and
  job objects via Native API.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntrtl, Ntapi.ntseapi,
  Ntapi.ntexapi, DelphiApi.Reflection, Ntapi.Versions;

const
  // Processes

  // Known proces IDs
  SYSTEM_IDLE_PID = 0;
  SYSTEM_PID = 4;

  // SDK::winnt.h - process access masks
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

  // rev - process state change access masks
  PROCESS_STATE_CHANGE_STATE = $0001;
  PROCESS_STATE_ALL_ACCESS = STANDARD_RIGHTS_ALL or PROCESS_STATE_CHANGE_STATE;

  // rev, flag for NtGetNextProcess
  PROCESS_NEXT_REVERSE_ORDER = $0001;

  // rev, debug flag
  PROCESS_INHERIT_DEBUGGING = $0001;

  // Process uptime flags
  PROCESS_UPTIME_CRASHED = $100;
  PROCESS_UPTIME_TERMINATED = $200;

  // PHNT::ntpsapi.h - flags for NtCreateProcessEx and NtCreateUserProcess
  PROCESS_CREATE_FLAGS_BREAKAWAY = $00000001;              // both
  PROCESS_CREATE_FLAGS_NO_DEBUG_INHERIT = $00000002;       // both
  PROCESS_CREATE_FLAGS_INHERIT_HANDLES = $00000004;        // both
  PROCESS_CREATE_FLAGS_OVERRIDE_ADDRESS_SPACE = $00000008; // NtCreateProcessEx
  PROCESS_CREATE_FLAGS_LARGE_PAGES = $00000010;            // NtCreateProcessEx, SeLockMemory
  PROCESS_CREATE_FLAGS_LARGE_PAGE_SYSTEM_DLL = $00000020;  // NtCreateProcessEx, SeLockMemory
  PROCESS_CREATE_FLAGS_PROTECTED_PROCESS = $00000040;      // NtCreateUserProcess
  PROCESS_CREATE_FLAGS_CREATE_SESSION = $00000080;         // both, SeLoadDriver
  PROCESS_CREATE_FLAGS_INHERIT_FROM_PARENT = $00000100;    // both
  PROCESS_CREATE_FLAGS_SUSPENDED = $00000200;              // both
  PROCESS_CREATE_FLAGS_FORCE_BREAKAWAY = $00000400;        // both, SeTcb
  PROCESS_CREATE_FLAGS_MINIMAL_PROCESS = $00000800;        // NtCreateProcessEx
  PROCESS_CREATE_FLAGS_RELEASE_SECTION = $00001000;        // both
  PROCESS_CREATE_FLAGS_AUXILIARY_PROCESS = $00008000;      // both, SeTcb
  PROCESS_CREATE_FLAGS_STORE_PROCESS = $00020000;          // both

  // Extracted from bit union TPsCreateInfo.PsCreateInitialState
  PS_CREATE_INTIAL_STATE_WRITE_OUTPUT_ON_EXIT = $0001;
  PS_CREATE_INTIAL_STATE_DETECT_MANIFEST = $0002;
  PS_CREATE_INTIAL_STATE_IFEO_SKIP_DEBUGGER = $0004;
  PS_CREATE_INTIAL_STATE_IFEO_DONT_PROPAGATE_KEY_STATE = $0008;

  // Extracted from bit union TPsCreateInfo.PsCreateInitialState
  PS_CREATE_INTIAL_STATE_PROHIBITED_IMAGE_CHARACTERISTICS_SHIFT = 16;
  PS_CREATE_INTIAL_STATE_PROHIBITED_IMAGE_CHARACTERISTICS_MASK = $FFFF0000;

  // Extracted from bit union TPsCreateInfo.PsCreateSuccess
  PS_CREATE_SUCCESS_PROTECTED_PROCESS = $0001;
  PS_CREATE_SUCCESS_ADDRESS_SPACE_OVERRIDE = $0002;
  PS_CREATE_SUCCESS_IFEO_DEV_OVERRIDE_ENABLED = $0004;
  PS_CREATE_SUCCESS_MANIFEST_DETECTED = $0008;
  PS_CREATE_SUCCESS_PROTECTED_PROCESS_LIGHT = $0010;

  // Extracted from bit union of TProcessBasicInformationEx
  PROCESS_BASIC_FLAG_PROTECTED = $0001;
  PROCESS_BASIC_FLAG_WOW64 = $0002;
  PROCESS_BASIC_FLAG_DELETING = $0004;
  PROCESS_BASIC_FLAG_CROSS_SESSION_CREATE = $0008;
  PROCESS_BASIC_FLAG_FROZEN = $0010;
  PROCESS_BASIC_FLAG_BACKGROUND = $0020;
  PROCESS_BASIC_FLAG_STRONGLY_NAMED = $0040;
  PROCESS_BASIC_FLAG_SECURE = $0080;
  PROCESS_BASIC_FLAG_SUBSYSTEM = $0100;

  // WDK::ntddk.h - handle tracing flags
  PROCESS_HANDLE_TRACING_MAX_STACKS = 16;
  PROCESS_HANDLE_TRACING_MAX_SLOTS = $20000;

  // Other

  // Re-declare for annotations
  SECTION_MAP_EXECUTE = $0008;  // Ntapi.ntmmapi
  DEBUG_PROCESS_ASSIGN = $0002; // Ntapi.ntdbg
  PORT_CONNECT = $0001; // Ntapi.ntlpcapi

  // Threads

  // SDK::winnt.h - thread access masks
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

  // rev, thread state change flags
  THREAD_STATE_CHANGE_STATE = $0001;
  THREAD_STATE_ALL_ACCESS = STANDARD_RIGHTS_ALL or THREAD_STATE_CHANGE_STATE;

  // Special ReserveHandle for NtQueueApcThreadEx, Win 10 RS5+
  APC_FORCE_THREAD_SIGNAL = THandle(1);

  // User processes and threads

  // PHNT::ntpsapi.h - creation flags for NtCreateThreadEx & NtCreateUserProcess
  THREAD_CREATE_FLAGS_CREATE_SUSPENDED = $00000001;      // both
  THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH = $00000002;    // NtCreateThreadEx
  THREAD_CREATE_FLAGS_HIDE_FROM_DEBUGGER = $00000004;    // NtCreateThreadEx
  THREAD_CREATE_FLAGS_LOADER_WORKER = $00000010;         // NtCreateThreadEx
  THREAD_CREATE_FLAGS_SKIP_LOADER_INIT = $00000020;      // NtCreateThreadEx
  THREAD_CREATE_FLAGS_BYPASS_PROCESS_FREEZE = $00000040; // NtCreateThreadEx
  THREAD_CREATE_FLAGS_INITIAL_THREAD = $00000080;        // ?

  // Jobs

  // SDK::winnt.h - job access masks
  JOB_OBJECT_ASSIGN_PROCESS = $0001;
  JOB_OBJECT_SET_ATTRIBUTES = $0002;
  JOB_OBJECT_QUERY = $0004;
  JOB_OBJECT_TERMINATE = $0008;
  JOB_OBJECT_SET_SECURITY_ATTRIBUTES = $0010;
  JOB_OBJECT_IMPERSONATE = $0020;

  JOB_OBJECT_ALL_ACCESS = STANDARD_RIGHTS_ALL or $3F;

  // SDK::winnt.h - basic limits
  JOB_OBJECT_LIMIT_WORKINGSET = $00000001;
  JOB_OBJECT_LIMIT_PROCESS_TIME = $00000002;
  JOB_OBJECT_LIMIT_JOB_TIME = $00000004;
  JOB_OBJECT_LIMIT_ACTIVE_PROCESS = $00000008;
  JOB_OBJECT_LIMIT_AFFINITY = $00000010;
  JOB_OBJECT_LIMIT_PRIORITY_CLASS = $00000020;
  JOB_OBJECT_LIMIT_PRESERVE_JOB_TIME = $00000040;
  JOB_OBJECT_LIMIT_SCHEDULING_CLASS = $00000080;

  // SDK::winnt.h - extended limits
  JOB_OBJECT_LIMIT_PROCESS_MEMORY = $00000100;
  JOB_OBJECT_LIMIT_JOB_MEMORY = $00000200;
  JOB_OBJECT_LIMIT_DIE_ON_UNHANDLED_EXCEPTION = $00000400;
  JOB_OBJECT_LIMIT_BREAKAWAY_OK = $00000800;
  JOB_OBJECT_LIMIT_SILENT_BREAKAWAY_OK = $00001000;
  JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = $00002000;
  JOB_OBJECT_LIMIT_SUBSET_AFFINITY = $00004000;
  JOB_OBJECT_LIMIT_JOB_MEMORY_LOW = $00008000;

  // SDK::winnt.h - notification limits
  JOB_OBJECT_LIMIT_JOB_READ_BYTES = $00010000;
  JOB_OBJECT_LIMIT_JOB_WRITE_BYTES = $00020000;
  JOB_OBJECT_LIMIT_CPU_RATE_CONTROL = $00040000;
  JOB_OBJECT_LIMIT_IO_RATE_CONTROL = $00080000;
  JOB_OBJECT_LIMIT_NET_RATE_CONTROL = $00100000;

  // rev, among with die-on-unhandled-exceptions is required to create a silo,
  // use with extended limits v2
  JOB_OBJECT_LIMIT_SILO_READY = $00400000;

  // SDK::winnt.h - UI restrictions
  JOB_OBJECT_UILIMIT_HANDLES = $00000001;
  JOB_OBJECT_UILIMIT_READCLIPBOARD = $00000002;
  JOB_OBJECT_UILIMIT_WRITECLIPBOARD = $00000004;
  JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS = $00000008;
  JOB_OBJECT_UILIMIT_DISPLAYSETTINGS = $00000010;
  JOB_OBJECT_UILIMIT_GLOBALATOMS = $00000020;
  JOB_OBJECT_UILIMIT_DESKTOP = $00000040;
  JOB_OBJECT_UILIMIT_EXITWINDOWS = $00000080;

  // SDK::winnt.h - CPU rate control flags, Win 8+
  JOB_OBJECT_CPU_RATE_CONTROL_ENABLE = $01;
  JOB_OBJECT_CPU_RATE_CONTROL_WEIGHT_BASED = $02;
  JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP = $04;
  JOB_OBJECT_CPU_RATE_CONTROL_NOTIFY = $08;
  JOB_OBJECT_CPU_RATE_CONTROL_MIN_MAX_RATE = $10; // Win 10 TH1+

  // PHNT::ntpsapi.h - freeze flags
  JOB_OBJECT_OPERATION_FREEZE = $01;
  JOB_OBJECT_OPERATION_FILTER = $02;
  JOB_OBJECT_OPERATION_SWAP = $04;

  // SDK::winnt.h - I/O control flags
  JOB_OBJECT_IO_RATE_CONTROL_ENABLE = $01; // Win 10 TH1+
  JOB_OBJECT_IO_RATE_CONTROL_STANDALONE_VOLUME = $02; // Win 10 RS1+
  JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ALL = $04; // Win 10 RS4+
  JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ON_SOFT_CAP = $08; // Win 10 RS4+

  // SDK::winnt.h - netwoek control flags
  JOB_OBJECT_NET_RATE_CONTROL_ENABLE = $01;
  JOB_OBJECT_NET_RATE_CONTROL_MAX_BANDWIDTH = $02;
  JOB_OBJECT_NET_RATE_CONTROL_DSCP_TAG = $04;

  // WDK::wdm.h - pseudo-handles
  NtCurrentProcess = THandle(-1);
  NtCurrentThread = THandle(-2);

  // PHNT::ntpsapi.h
  function NtCurrentProcessId: TProcessId;
  function NtCurrentThreadId: TThreadId;

type
  // Processes

  [FriendlyName('process'), ValidMask(PROCESS_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(PROCESS_TERMINATE, 'Terminate')]
  [FlagName(PROCESS_CREATE_THREAD, 'Create Threads')]
  [FlagName(PROCESS_SET_SESSIONID, 'Set Session ID')]
  [FlagName(PROCESS_VM_OPERATION, 'Memory Operations')]
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

  [FriendlyName('process state'), ValidMask(PROCESS_STATE_ALL_ACCESS)]
  [FlagName(PROCESS_STATE_CHANGE_STATE, 'Change State')]
  TProcessStateAccessMask = type TAccessMask;

  [FlagName(PROCESS_NEXT_REVERSE_ORDER, 'Reverse Order')]
  TProcessNextFlags = type Cardinal;

  [FlagName(PROCESS_CREATE_FLAGS_BREAKAWAY, 'Breakaway')]
  [FlagName(PROCESS_CREATE_FLAGS_NO_DEBUG_INHERIT, 'No Debug Inherit')]
  [FlagName(PROCESS_CREATE_FLAGS_INHERIT_HANDLES, 'Inherit Handles')]
  [FlagName(PROCESS_CREATE_FLAGS_OVERRIDE_ADDRESS_SPACE, 'Override Address Space')]
  [FlagName(PROCESS_CREATE_FLAGS_LARGE_PAGES, 'Large Pages')]
  [FlagName(PROCESS_CREATE_FLAGS_LARGE_PAGE_SYSTEM_DLL, 'Large Pages Ntdll')]
  [FlagName(PROCESS_CREATE_FLAGS_PROTECTED_PROCESS, 'Protected')]
  [FlagName(PROCESS_CREATE_FLAGS_CREATE_SESSION, 'Create Session')]
  [FlagName(PROCESS_CREATE_FLAGS_INHERIT_FROM_PARENT, 'Inherit From Parent')]
  [FlagName(PROCESS_CREATE_FLAGS_SUSPENDED, 'Suspended')]
  [FlagName(PROCESS_CREATE_FLAGS_FORCE_BREAKAWAY, 'Force Breakaway')]
  [FlagName(PROCESS_CREATE_FLAGS_MINIMAL_PROCESS, 'Minimal Process')]
  [FlagName(PROCESS_CREATE_FLAGS_RELEASE_SECTION, 'Release Section')]
  [FlagName(PROCESS_CREATE_FLAGS_AUXILIARY_PROCESS, 'Auxiliary Process')]
  TProcessCreateFlags = type Cardinal;

  // PHNT::ntpsapi.h & WDK::ntddk.h
  [SDKName('PROCESSINFOCLASS')]
  [NamingStyle(nsCamelCase, 'Process')]
  TProcessInfoClass = (
    ProcessBasicInformation = 0,      // q: TProcessBasicInformation[Ex]
    ProcessQuotaLimits = 1,           // q, s: TQuotaLimits
    ProcessIoCounters = 2,            // q: TIoCounters
    ProcessVmCounters = 3,            // q: TVmCounters
    ProcessTimes = 4,                 // q: TKernelUserTimes
    ProcessBasePriority = 5,          // s: TPriority
    ProcessRaisePriority = 6,         // s:
    ProcessDebugPort = 7,             // q: NativeUInt
    ProcessExceptionPort = 8,         // s: THandle (LPC port)
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
    ProcessImageFileName = 27,           // q: TNtUnicodeString
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
    ProcessInstrumentationCallback = 40, // s: Pointer or TProcessInstrumentationCallback
    ProcessThreadStackAllocation = 41,   // s: (self only)
    ProcessWorkingSetWatchEx = 42,       // q, s:
    ProcessImageFileNameWin32 = 43,      // q: TNtUnicodeString
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
    ProcessRevokeFileHandles = 56,         // s: TNtUnicodeString (Path)
    ProcessWorkingSetControl = 57,         // s: 
    ProcessHandleTable = 58,               // q: Cardinal[] Win 8.1+
    ProcessCheckStackExtentsMode = 59,     // q, s:
    ProcessCommandLineInformation = 60,    // q TNtUnicodeString, Win 8.1 +
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

  // WDK::ntddk.h - info class 0
  [SDKName('PROCESS_BASIC_INFORMATION')]
  TProcessBasicInformation = record
    ExitStatus: NTSTATUS;
    [DontFollow] PebBaseAddress: PPeb;
    [Hex] AffinityMask: NativeUInt;
    BasePriority: TPriority;
    UniqueProcessID: TProcessId;
    InheritedFromUniqueProcessID: TProcessId;
  end;

  [FlagName(PROCESS_BASIC_FLAG_PROTECTED, 'Protected')]
  [FlagName(PROCESS_BASIC_FLAG_WOW64, 'WoW64')]
  [FlagName(PROCESS_BASIC_FLAG_DELETING, 'Deleting')]
  [FlagName(PROCESS_BASIC_FLAG_CROSS_SESSION_CREATE, 'Cross-session Create')]
  [FlagName(PROCESS_BASIC_FLAG_FROZEN, 'Frozen')]
  [FlagName(PROCESS_BASIC_FLAG_BACKGROUND, 'Background')]
  [FlagName(PROCESS_BASIC_FLAG_STRONGLY_NAMED, 'Strongly Named')]
  [FlagName(PROCESS_BASIC_FLAG_SECURE, 'Secure')]
  [FlagName(PROCESS_BASIC_FLAG_SUBSYSTEM, 'Subsystem')]
  TProcessExtendedFlags = type Cardinal;

  // PHNT::ntpsapi.h - info class 0
  [MinOSVersion(OsWin8)]
  [SDKName('PROCESS_EXTENDED_BASIC_INFORMATION')]
  TProcessBasicInformationEx = record
    [Counter(ctBytes)] Size: NativeUInt;
    BasicInfo: TProcessBasicInformation;
    Flags: TProcessExtendedFlags;
  end;

  // WDK::ntddk.h - info class 3
  [SDKName('VM_COUNTERS')]
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

  // WDK::ntddk.h - info class 4
  [SDKName('KERNEL_USER_TIMES')]
  TKernelUserTimes = record
    CreateTime: TLargeInteger;
    ExitTime: TLargeInteger;
    KernelTime: TULargeInteger;
    UserTime: TULargeInteger;
  end;

  // WDK::ntddk.h - info class 9
  [SDKName('PROCESS_ACCESS_TOKEN')]
  TProcessAccessToken = record
    [Access(TOKEN_ASSIGN_PRIMARY)] Token: THandle;
    [Reserved] Thread: THandle;
  end;

  // WDK::ntddk.h - info class 14
  [SDKName('POOLED_USAGE_AND_LIMITS')]
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

  // PHNT::ntpsapi.h
  {$MINENUMSIZE 1}
  [NamingStyle(nsSnakeCase, 'PROCESS_PRIORITY_CLASS')]
  TProcessPriorityClassValue = (
    PROCESS_PRIORITY_CLASS_UNKNOWN = 0,
    PROCESS_PRIORITY_CLASS_IDLE = 1,
    PROCESS_PRIORITY_CLASS_NORMAL = 2,
    PROCESS_PRIORITY_CLASS_HIGH = 3,
    PROCESS_PRIORITY_CLASS_REALTIME = 4,
    PROCESS_PRIORITY_CLASS_BELOW_NORMAL = 5,
    PROCESS_PRIORITY_CLASS_ABOVE_NORMAL = 6
  );
  {$MINENUMSIZE 4}

  // PHNT::ntpsapi.h - info class 18
  [SDKName('PROCESS_PRIORITY_CLASS')]
  TProcessPriorityClass = record
    Foreground: Boolean;
    PriorityClass: TProcessPriorityClassValue;
  end;

  // PHNT::ntpsapi.h - info class 20
  [SDKName('PROCESS_HANDLE_INFORMATION')]
  TProcessHandleInformation = record
    HandleCount: Cardinal;
    HandleCountHighWatermark: Cardinal;
  end;

  [FlagName(PROCESS_INHERIT_DEBUGGING, 'Inherit Debugging')]
  TProcessDebugFlags = type Cardinal;

  // WDK::ntddk.h - info class 32 (set)
  // To enable, use this structure; to disable use zero input length
  [SDKName('PROCESS_HANDLE_TRACING_ENABLE_EX')]
  TProcessHandleTracingEnableEx = record
    [Reserved(0)] Flags: Cardinal;
    TotalSlots: Cardinal;
  end;

  [NamingStyle(nsSnakeCase, 'PROCESS_HANDLE_TRACE_TYPE'), Range(1)]
  TProcessHandleTracingType = (
    PROCESS_HANDLE_TRACE_TYPE_RESERVED = 0,
    PROCESS_HANDLE_TRACE_TYPE_OPEN = 1,
    PROCESS_HANDLE_TRACE_TYPE_CLOSE = 2,
    PROCESS_HANDLE_TRACE_TYPE_BADREF = 3
  );

  TProcessHandleTracingStacks = array [0 .. PROCESS_HANDLE_TRACING_MAX_STACKS - 1] of Pointer;

  // WDK::ntddk.h
  [SDKName('PROCESS_HANDLE_TRACING_ENTRY')]
  TProcessHandleTracingEntry = record
    Handle: THandle;
    ClientId: TClientId;
    TraceType: TProcessHandleTracingType;
    Stacks: TProcessHandleTracingStacks;
    function StackTrace: TArray<Pointer>;
  end;

  // WDK::ntddk.h - info class 32 (query)
  [SDKName('PROCESS_HANDLE_TRACING_QUERY')]
  TProcessHandleTracingQuery = record
    Handle: THandle;
    [Counter] TotalTraces: Integer; // Max PROCESS_HANDLE_TRACING_MAX_SLOTS
    HandleTrace: TAnysizeArray<TProcessHandleTracingEntry>;
  end;
  PProcessHandleTracingQuery = ^TProcessHandleTracingQuery;

  // PHNT::ntpsapi.h - info class 38
  [SDKName('PROCESS_CYCLE_TIME_INFORMATION')]
  TProcessCycleTimeInformation = record
    AccumulatedCycles: UInt64;
    CurrentCycleCount: UInt64;
  end;

  // PHNT::ntpsapi.h - info class 40
  [SDKName('PROCESS_INSTRUMENTATION_CALLBACK_INFORMATION')]
  TProcessInstrumentationCallback = record
    [Reserved(0)] Version: Cardinal;
    [Reserved(0)] Reserved: Cardinal;
    Callback: Pointer;
  end;

  // PHNT::ntpsapi.h - info class 50
  [SDKName('PROCESS_WINDOW_INFORMATION')]
  TProcessWindowInformation = record
    WindowFlags: Cardinal; // TStarupFlags
    [Counter(ctBytes)] WindowTitleLength: Word;
    WindowTitle: TAnysizeArray<WideChar>;
  end;
  PProcessWindowInformation = ^TProcessWindowInformation;

  // PHNT::ntpsapi.h
  [MinOSVersion(OsWin8)]
  [SDKName('PROCESS_HANDLE_TABLE_ENTRY_INFO')]
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

  // PHNT::ntpsapi.h - info class 51
  [MinOSVersion(OsWin8)]
  [SDKName('PROCESS_HANDLE_SNAPSHOT_INFORMATION')]
  TProcessHandleSnapshotInformation = record
    [Counter] NumberOfHandles: NativeUInt;
    [Unlisted] Reserved: NativeUInt;
    Handles: TAnysizeArray<TProcessHandleTableEntryInfo>;
  end;
  PProcessHandleSnapshotInformation = ^TProcessHandleSnapshotInformation;

  // SDK::winnt.h
  [MinOSVersion(OsWin8)]
  [SDKName('PROCESS_MITIGATION_POLICY')]
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

  // PHNT::ntpsapi.h - info class 52
  [MinOSVersion(OsWin8)]
  [SDKName('PROCESS_MITIGATION_POLICY_INFORMATION')]
  TProcessMitigationPolicyInformation = record
    Policy: TProcessMitigationPolicy;
    [Hex] Flags: Cardinal;
  end;

  // PHNT::ntpsapi.h - info class 64
  [MinOSVersion(OsWin10TH1)]
  [SDKName('PROCESS_TELEMETRY_ID_INFORMATION')]
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

  // PHNT::ntpsapi.h - info class 69
  [MinOSVersion(OsWin10TH1)]
  [SDKName('PROCESS_JOB_MEMORY_INFO')]
  TProcessJobMemoryInfo = record
    [Bytes] SharedCommitUsage: UInt64;
    [Bytes] PrivateCommitUsage: UInt64;
    [Bytes] PeakPrivateCommitUsage: UInt64;
    [Bytes] PrivateCommitLimit: UInt64;
    [Bytes] TotalCommitLimit: UInt64;
  end;

  // PHNT::ntpsapi.h - info class 73
  [MinOSVersion(OsWin10TH2)]
  [SDKName('PROCESS_CHILD_PROCESS_INFORMATION')]
  TProcessChildProcessInformation = record
    ProhibitChildProcesses: Boolean;
    [MinOSVersion(OsWin10RS3)] AlwaysAllowSecureChildProcess: Boolean;
    AuditProhibitChildProcesses: Boolean;
  end;

  // PHNT::ntpsapi.h - info class 88
  [MinOSVersion(OsWin10RS3)]
  [SDKName('PROCESS_UPTIME_INFORMATION')]
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

  // rev
  [NamingStyle(nsCamelCase, 'ProcessStateChange')]
  TProcessStateChangeType = (
    ProcessStateChangeSuspend = 0,
    ProcessStateChangeResume = 1
  );

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

  [FriendlyName('thread state'), ValidMask(THREAD_STATE_ALL_ACCESS)]
  [FlagName(THREAD_STATE_CHANGE_STATE, 'Change State')]
  TThreadStateAccessMask = type TAccessMask;

  [FlagName(THREAD_CREATE_FLAGS_CREATE_SUSPENDED, 'Create Suspended')]
  [FlagName(THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH, 'Skip Thread Attach')]
  [FlagName(THREAD_CREATE_FLAGS_HIDE_FROM_DEBUGGER, 'Hide From Debugger')]
  [FlagName(THREAD_CREATE_FLAGS_LOADER_WORKER, 'Loader Worker')]
  [FlagName(THREAD_CREATE_FLAGS_SKIP_LOADER_INIT, 'Skip Loader Init')]
  [FlagName(THREAD_CREATE_FLAGS_BYPASS_PROCESS_FREEZE, 'Bypass Process Freeze')]
  [FlagName(THREAD_CREATE_FLAGS_INITIAL_THREAD, 'Initial Thread')]
  TThreadCreateFlags = type Cardinal;

  // PHNT::ntpsapi.h
  [SDKName('INITIAL_TEB')]
  TInitialTeb = record
    OldStackBase: Pointer;
    OldStackLimit: Pointer;
    StackBase: Pointer;
    StackLimit: Pointer;
    StackAllocationBase: Pointer;
  end;
  PInitialTeb = ^TInitialTeb;

  // PHNT::ntpsapi.h & WDK::ntddk.h
  [SDKName('THREADINFOCLASS')]
  [NamingStyle(nsCamelCase, 'Thread')]
  TThreadInfoClass = (
    ThreadBasicInformation = 0,          // q: TThreadBasicInformation
    ThreadTimes = 1,                     // q: TKernelUserTimes
    ThreadPriority = 2,                  // s: TPriority
    ThreadBasePriority = 3,              // s: TPriority
    ThreadAffinityMask = 4,              // s: UInt64
    ThreadImpersonationToken = 5,        // s: THandle with TOKEN_IMPERSONATE
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
    ThreadAttachContainer = 47,          // s: THandle (Job object)
    ThreadManageWritesToExecutableMemory = 48, // Win 10 RS3+
    ThreadPowerThrottlingState = 49,     // s: Win 10 RS3+
    ThreadWorkloadClass = 50             // s: Win 10 RS5+
  );

  // PHNT::ntpsapi.h - info class 0
  [SDKName('THREAD_BASIC_INFORMATION')]
  TThreadBasicInformation = record
    ExitStatus: NTSTATUS;
    [DontFollow] TebBaseAddress: PTeb;
    ClientId: TClientId;
    [Hex] AffinityMask: NativeUInt;
    Priority: TPriority;
    BasePriority: TPriority;
  end;
  PThreadBasicInformation = ^TThreadBasicInformation;

  // PHNT::ntpsapi.h - info class 21
  TThreadLastSyscallWin7 = record
    FirstArgument: NativeUInt;
    SystemCallNumber: NativeUInt;
  end;

  // PHNT::ntpsapi.h - info class 21
  [SDKName('THREAD_LAST_SYSCALL_INFORMATION')]
  TThreadLastSyscall = record
    FirstArgument: NativeUInt;
    SystemCallNumber: NativeUInt;
    [MinOSVersion(OsWin8)] WaitTime: UInt64;
  end;
  PThreadLastSyscall = ^TThreadLastSyscall;

  // PHNT::ntpsapi.h - info class 26
  [SDKName('THREAD_TEB_INFORMATION')]
  TThreadTebInformation = record
    TebInformation: Pointer;
    [Hex] TebOffset: Cardinal;
    [Bytes] BytesToRead: Cardinal;
  end;
  PThreadTebInformation = ^TThreadTebInformation;

  // SDK::winnt.h - info class 30
  [SDKName('GROUP_AFFINITY')]
  TGroupAffinity = record
    [Hex] Mask: Cardinal;
    Group: Word;
    [Unlisted] Reserved: array [0..2] of Word;
  end;

  // WDK::ntddk.h - info class 45
  [MinOSVersion(OsWin10RS2)]
  [SDKName('SUBSYSTEM_INFORMATION_TYPE')]
  [NamingStyle(nsCamelCase, 'SubsystemInformationType')]
  TSubsystemInformationType = (
    SubsystemInformationTypeWin32 = 0,
    SubsystemInformationTypeWSL = 1
  );

  // PHNT::ntpsapi.h
  [SDKName('PPS_APC_ROUTINE')]
  TPsApcRoutine = procedure (ApcArgument1, ApcArgument2, ApcArgument3: Pointer);
    stdcall;

  // rev
  [NamingStyle(nsCamelCase, 'ThreadStateChange')]
  TThreadStateChangeType = (
    ThreadStateChangeSuspend = 0,
    ThreadStateChangeResume = 1
  );

  // User processes and threads

  // PHNT::ntpsapi.h
  [SDKName('PS_ATTRIBUTE_NUM')]
  [NamingStyle(nsCamelCase, 'PsAttribute')]
  TPsAttributeNum = (
    PsAttributeParentProcess = $0,       // in: THandle with PROCESS_CREATE_PROCESS
    PsAttributeDebugObject = $1,         // in: THandle with DEBUG_PROCESS_ASSIGN
    PsAttributeToken = $2,               // in: THandle with TOKEN_ASSIGN_PRIMARY
    PsAttributeClientId = $3,            // out: TClientID
    PsAttributeTebAddress = $4,          // out: PTeb
    PsAttributeImageName = $5,           // in: PWideChar
    PsAttributeImageInfo = $6,           // out: PSectionImageInformation
    PsAttributeMemoryReserve = $7,       // in: TPsMemoryReserve
    PsAttributePriorityClass = $8,       // in: Byte
    PsAttributeErrorMode = $9,           // in: Cardinal
    PsAttributeStdHandleInfo = $A,
    PsAttributeHandleList = $B,          // in: TAnysizeArray<THandle>
    PsAttributeGroupAffinity = $C,       // in: TGroupAffinity
    PsAttributePreferredNode = $D,       // in: Word
    PsAttributeIdealProcessor = $E,
    PsAttributeUmsThread = $F,
    PsAttributeMitigationOptions = $10,  // in: TPsMitigationOptionsMap, Win 8+
    PsAttributeProtectionLevel = $11,    // Win 8.1+
    PsAttributeSecureProcess = $12,      // Win 10 TH1+
    PsAttributeJobList = $13,            // in: TAnysizeArray<THandle> with JOB_OBJECT_ASSIGN_PROCESS
    PsAttributeChildProcessPolicy = $14, // Win 10 TH2+
    PsAttributeAllApplicationPackagesPolicy = $15, // Win 10 RS1+
    PsAttributeWin32kFilter = $16,                 // in: TWin32kSyscallFilter
    PsAttributeSafeOpenPromptOriginClaim = $17,    //
    PsAttributeBnoIsolation = $18,                 // Win 10 RS2+
    PsAttributeDesktopAppPolicy = $19,             //
    PsAttributeChpe = $1A,                         // in: Boolean, Win 10 RS3+
    PsAttributeMitigationAuditOptions = $1B,       // Win 10 21H1+
    PsAttributeMachineType = $1C,                  // Win 10 21H2+
    PsAttributeComponentFilter = $1D,              //
    PsAttributeEnableOptionalXStateFeatures = $1E  // Win 11+
  );

const
  // SDK::winbasep.h - mask for extracting TPsAttributeNum
  PS_ATTRIBUTE_NUMBER_MASK = $0000ffff;

  // PHNT::ntpsapi.h - process attributes
  PS_ATTRIBUTE_PARENT_PROCESS = $60000;
  PS_ATTRIBUTE_DEBUG_PORT = $60001;
  PS_ATTRIBUTE_TOKEN = $60002;
  PS_ATTRIBUTE_CLIENT_ID = $10003;
  PS_ATTRIBUTE_TEB_ADDRESS = $10004;
  PS_ATTRIBUTE_IMAGE_NAME = $20005;
  PS_ATTRIBUTE_IMAGE_INFO = $00006;
  PS_ATTRIBUTE_MEMORY_RESERVE = $20007;
  PS_ATTRIBUTE_PRIORITY_CLASS = $20008;
  PS_ATTRIBUTE_ERROR_MODE = $20009;
  PS_ATTRIBUTE_STD_HANDLE_INFO = $2000A;
  PS_ATTRIBUTE_HANDLE_LIST = $2000B;
  PS_ATTRIBUTE_GROUP_AFFINITY = $3000C;
  PS_ATTRIBUTE_PREFERRED_NODE = $2000D;
  PS_ATTRIBUTE_IDEAL_PROCESSOR = $3000E;
  PS_ATTRIBUTE_UMS_THREAD = $3000F;
  PS_ATTRIBUTE_MITIGATION_OPTIONS = $20010;
  PS_ATTRIBUTE_PROTECTION_LEVEL = $60011;
  PS_ATTRIBUTE_SECURE_PROCESS = $20012;
  PS_ATTRIBUTE_JOB_LIST = $20013;
  PS_ATTRIBUTE_CHILD_PROCESS_POLICY = $20014;
  PS_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY = $20015;
  PS_ATTRIBUTE_WIN32K_FILTER = $20016;
  PS_ATTRIBUTE_SAFE_OPEN_PROMPT_ORIGIN_CLAIM = $20017;
  PS_ATTRIBUTE_BNO_ISOLATION = $20018;
  PS_ATTRIBUTE_DESKTOP_APP_POLICY = $20019;
  PS_ATTRIBUTE_CHPE = $6001A;
  PS_ATTRIBUTE_MITIGATION_AUDIT_OPTIONS = $2001B;
  PS_ATTRIBUTE_MACHINE_TYPE = $6001C;
  PS_ATTRIBUTE_COMPONENT_FILTER = $2001D;
  PS_ATTRIBUTE_ENABLE_OPTIONAL_XSTATE_FEATURES = $3001E;

type
  // PHNT::ntpsapi.h
  [SDKName('PS_ATTRIBUTE')]
  TPsAttribute = record
    [Hex] Attribute: NativeUInt;
    [Bytes] Size: NativeUInt;
    Value: UIntPtr;
    [out, opt] ReturnLength: PNativeUInt;
  end;
  PPsAttribute = ^TPsAttribute;

  // PHNT::ntpsapi.h
  [SDKName('PS_ATTRIBUTE_LIST')]
  TPsAttributeList = record
    [Counter(ctBytes)] TotalLength: NativeUInt;
    Attributes: TAnysizeArray<TPsAttribute>;
  end;
  PPsAttributeList = ^TPsAttributeList;

  // PHNT::ntpsapi.h, attribute 7
  [SDKName('PS_MEMORY_RESERVE')]
  TPsMemoryReserve = record
    ReserveAddress: Pointer;
    ReserveSize: NativeUInt;
  end;

  // PHNT::ntpsapi.h, attribute $10
  [MinOSVersion(OsWin8)]
  [SDKName('PS_MITIGATION_OPTIONS_MAP')]
  TPsMitigationOptionsMap = record
    Map: array [0..5] of Cardinal;
  end;

  // attribute $16
  [MinOSVersion(OsWin10RS1)]
  [SDKName('WIN32K_SYSCALL_FILTER')]
  TWin32kSyscallFilter = record
    FilterState: Cardinal;
    FilterSet: Cardinal;
  end;

  // PHNT::ntpsapi.h, attribute $1B
  [MinOSVersion(OsWin1021H1)]
  [SDKName('PS_MITIGATION_AUDIT_OPTIONS_MAP')]
  TPsMitigationAuditOptionsMap = type TPsMitigationOptionsMap;

  // PHNT::ntpsapi.h
  [SDKName('PS_CREATE_STATE')]
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

  [FlagName(PS_CREATE_INTIAL_STATE_WRITE_OUTPUT_ON_EXIT, 'Write Output On Exit')]
  [FlagName(PS_CREATE_INTIAL_STATE_DETECT_MANIFEST, 'Detect Manifest')]
  [FlagName(PS_CREATE_INTIAL_STATE_IFEO_SKIP_DEBUGGER, 'Skip IFEO Debugger')]
  [FlagName(PS_CREATE_INTIAL_STATE_IFEO_DONT_PROPAGATE_KEY_STATE, 'Don''t Propagate IFEO Key State')]
  [SubEnum(PS_CREATE_INTIAL_STATE_PROHIBITED_IMAGE_CHARACTERISTICS_MASK, 0, 'Allow Any Image Characteristics')]
  TPsCreateInitialFlags = type Cardinal;

  [FlagName(PS_CREATE_SUCCESS_PROTECTED_PROCESS, 'Protected Process')]
  [FlagName(PS_CREATE_SUCCESS_ADDRESS_SPACE_OVERRIDE, 'Address Space Override')]
  [FlagName(PS_CREATE_SUCCESS_IFEO_DEV_OVERRIDE_ENABLED, 'IFEO Dev Override Enabled')]
  [FlagName(PS_CREATE_SUCCESS_MANIFEST_DETECTED, 'Manifest Detected')]
  [FlagName(PS_CREATE_SUCCESS_PROTECTED_PROCESS_LIGHT, 'PPL')]
  TPsCreateSuccessFlags = type Cardinal;

  // PHNT::ntpsapi.h
  [SDKName('PS_CREATE_INFO')]
  TPsCreateInfo = record
    [Bytes] Size: NativeUInt;
  case State: TPsCreateState of
    PsCreateInitialState: (
      InitFlags: TPsCreateInitialFlags;
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
      OutputFlags: TPsCreateSuccessFlags;
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

  // PHNT::ntpsapi.h & partially SDK::winnt.h
  [SDKName('JOBOBJECTINFOCLASS')]
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
    JobObjectContainerId = 30,               // q: TGuid on Win 10 TH1+ & TJobObjectContainerIdentifierV2 on Win 10 RS2+
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

  // SDK::winnt.h - info class 1
  [SDKName('JOBOBJECT_BASIC_ACCOUNTING_INFORMATION')]
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

  // SDK::winnt.h - info class 2
  [SDKName('JOBOBJECT_BASIC_LIMIT_INFORMATION')]
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

  // SDK::winnt.h - info class 3
  [SDKName('JOBOBJECT_BASIC_PROCESS_ID_LIST')]
  TJobObjectBasicProcessIdList = record
    NumberOfAssignedProcesses: Cardinal;
    [Counter] NumberOfProcessIdsInList: Cardinal;
    ProcessIdList: TAnysizeArray<TProcessId>;
  end;
  PJobObjectBasicProcessIdList = ^TJobObjectBasicProcessIdList;

  // SDK::winnt.h - info class 4
  [FlagName(JOB_OBJECT_UILIMIT_HANDLES, 'Handles')]
  [FlagName(JOB_OBJECT_UILIMIT_READCLIPBOARD, 'Read Clibboard')]
  [FlagName(JOB_OBJECT_UILIMIT_WRITECLIPBOARD, 'Write Clipboard')]
  [FlagName(JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS, 'System Parameters')]
  [FlagName(JOB_OBJECT_UILIMIT_DISPLAYSETTINGS, 'Display Settings')]
  [FlagName(JOB_OBJECT_UILIMIT_GLOBALATOMS, 'Global Atoms')]
  [FlagName(JOB_OBJECT_UILIMIT_DESKTOP, 'Desktop')]
  [FlagName(JOB_OBJECT_UILIMIT_EXITWINDOWS, 'Exit Windows')]
  TJobUiLimits = type Cardinal;

  // SDK::winnt.h - info class 6
  [NamingStyle(nsSnakeCase, 'JOB_OBJECT', 'AT_END_OF_JOB')]
  TJobObjectEndOfJobTimeInformation = (
    JOB_OBJECT_TERMINATE_AT_END_OF_JOB = 0,
    JOB_OBJECT_POST_AT_END_OF_JOB = 1
  );

  // SDK::winnt.h
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

  // SDK::winnt.h - info class 7
  [SDKName('JOBOBJECT_ASSOCIATE_COMPLETION_PORT')]
  TJobObjectAssociateCompletionPort = record
    CompletionKey: Pointer;
    [opt] CompletionPort: THandle; // Can be 0 for Win 8+
  end;
  PJobObjectAssociateCompletionPort = ^TJobObjectAssociateCompletionPort;

  // SDK::winnt.h - info class 8
  [SDKName('JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION')]
  TJobObjectBasicAndIoAccountingInformation = record
    [Aggregate] BasicInfo: TJobObjectBasicAccountingInformation;
    [Aggregate] IoInfo: TIoCounters;
  end;
  PJobObjectBasicAndIoAccountingInformation = ^TJobObjectBasicAndIoAccountingInformation;

  // SDK::winnt.h - info class 9
  [SDKName('JOBOBJECT_EXTENDED_LIMIT_INFORMATION')]
  TJobObjectExtendedLimitInformation = record
    [Aggregate] BasicLimitInformation: TJobObjectBasicLimitInformation;
    [Aggregate] IoInfo: TIoCounters;
    [Bytes] ProcessMemoryLimit: NativeUInt;
    [Bytes] JobMemoryLimit: NativeUInt;
    [Bytes] PeakProcessMemoryUsed: NativeUInt;
    [Bytes] PeakJobMemoryUsed: NativeUInt;
  end;
  PJobObjectExtendedLimitInformation = ^TJobObjectExtendedLimitInformation;

  // NtApiDotNet::NtJobNative.cs - info class 9
  [MinOSVersion(OsWin10TH1)] // approx.
  TJobObjectExtendedLimitInformationV2 = record
    [Aggregate] V1: TJobObjectExtendedLimitInformation;
    [Bytes] JobTotalMemoryLimit: NativeUInt;
  end;
  PJobObjectExtendedLimitInformationV2 = ^TJobObjectExtendedLimitInformationV2;

  // SDK::winnt.h
  [SDKName('JOBOBJECT_RATE_CONTROL_TOLERANCE')]
  [NamingStyle(nsCamelCase, 'Tolerance')]
  TJobObjectRateControlTolerance = (
    ToleranceNone = 0,
    ToleranceLow = 1,    // 20%
    ToleranceMedium = 2, // 40%
    ToleranceHigh = 3    // 60%
  );

  // SDK::winnt.h
  [SDKName('JOBOBJECT_RATE_CONTROL_TOLERANCE_INTERVAL')]
  [NamingStyle(nsCamelCase, 'ToleranceInterval')]
  TJobObjectRateControlToleranceInterval = (
    ToleranceIntervalNone = 0,
    ToleranceIntervalShort = 1,  // 10 sec
    ToleranceIntervalMedium = 2, // 1 min
    ToleranceIntervalLong = 3    // 10 min
  );

  // SDK::winnt.h - info class 12
  [MinOSVersion(OsWin8)]
  [SDKName('JOBOBJECT_NOTIFICATION_LIMIT_INFORMATION')]
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

  // SDK::winnt.h - info class 13
  [MinOSVersion(OsWin8)]
  [SDKName('JOBOBJECT_LIMIT_VIOLATION_INFORMATION')]
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

  // SDK::winnt.h - info class 15
  [MinOSVersion(OsWin8)]
  [SDKName('JOBOBJECT_CPU_RATE_CONTROL_INFORMATION')]
  TJobObjectCpuRateControlInformation = record
  case ControlFlags: TJobRateControlFlags of
    0: (CpuRate: Cardinal); // 0..10000 (corresponds to 0..100%)
    1: (Weight: Cardinal);  // 1..9
    2: (MinRate: Word; MaxRate: Word); // 0..10000 each, Win 10 TH1+
  end;
  PJobObjectCpuRateControlInformation = ^TJobObjectCpuRateControlInformation;

  // PHNT::ntpsapi.h
  [MinOSVersion(OsWin8)]
  [SDKName('JOBOBJECT_WAKE_FILTER')]
  TJobObjectWakeFilter = record
    HighEdgeFilter: Cardinal;
    LowEdgeFilter: Cardinal;
  end;

  [FlagName(JOB_OBJECT_OPERATION_FREEZE, 'Freeze')]
  [FlagName(JOB_OBJECT_OPERATION_FILTER, 'Filter')]
  [FlagName(JOB_OBJECT_OPERATION_SWAP, 'Swap')]
  TJobFreezeFlags = type Cardinal;

  // PHNT::ntpsapi.h - info class 18
  [MinOSVersion(OsWin8)]
  [SDKName('JOBOBJECT_FREEZE_INFORMATION')]
  TJobObjectFreezeInformation = record
    Flags: TJobFreezeFlags;
    Freeze: Boolean;
    Swap: Boolean;
    WakeFilter: TJobObjectWakeFilter;
  end;
  PJobObjectFreezeInformation = ^TJobObjectFreezeInformation;

  // PHNT::ntpsapi.h - info class 19
  [MinOSVersion(OsWin8)]
  [SDKName('JOBOBJECT_EXTENDED_ACCOUNTING_INFORMATION')]
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

  // PHNT::ntpsapi.h - info class 28
  [MinOSVersion(OsWin10TH1)]
  [SDKName('JOBOBJECT_MEMORY_USAGE_INFORMATION')]
  TJobObjectMemoryUsageInformation = record
    [Bytes] JobMemory: UInt64;
    [Bytes] PeakJobMemoryUsed: UInt64;
  end;
  PJobObjectMemoryUsageInformation = ^TJobObjectMemoryUsageInformation;

  // PHNT::ntpsapi.h - info class 28
  [MinOSVersion(OsWin10TH1)]
  [SDKName('JOBOBJECT_MEMORY_USAGE_INFORMATION_V2')]
  TJobObjectMemoryUsageInformationV2 = record
    [Aggregate] V1: TJobObjectMemoryUsageInformation;
    [Bytes] JobSharedMemory: UInt64;
    Reserved: array [0..1] of UInt64;
  end;
  PJobObjectMemoryUsageInformationV2 = ^TJobObjectMemoryUsageInformationV2;

  // NtApiDotNet::NtJobNative.cs - info class 30
  [MinOSVersion(OsWin10RS2)]
  [SDKName('JOBOBJECT_CONTAINER_IDENTIFIER_V2')]
  TJobObjectContainerIdentifierV2 = record
    ContainerID: TGuid;
    ContainerTelemetryID: TGuid;
    JobID: Cardinal;
  end;
  PJobObjectContainerIdentifierV2 = ^TJobObjectContainerIdentifierV2;

  [FlagName(JOB_OBJECT_IO_RATE_CONTROL_ENABLE, 'Enabled')]
  [FlagName(JOB_OBJECT_IO_RATE_CONTROL_STANDALONE_VOLUME, 'Standalone Volume')]
  [FlagName(JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ALL, 'Force Unit Access All')]
  [FlagName(JOB_OBJECT_IO_RATE_CONTROL_FORCE_UNIT_ACCESS_ON_SOFT_CAP, 'Force Unit Access On Soft Cap')]
  TJobIoRateControlFlags = type Cardinal;

  // SDK::winnt.h - info class 31
  [MinOSVersion(OsWin10TH1)]
  [SDKName('JOBOBJECT_IO_RATE_CONTROL_INFORMATION_NATIVE')]
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

  // SDK::winnt.h - info class 31
  [MinOSVersion(OsWin10RS1)]
  [SDKName('JOBOBJECT_IO_RATE_CONTROL_INFORMATION_NATIVE_V2')]
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

  // SDK::winnt.h - info class 31
  [MinOSVersion(OsWin10RS2)]
  [SDKName('JOBOBJECT_IO_RATE_CONTROL_INFORMATION_NATIVE_V3')]
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

  // SDK::winnt.h - info class 32
  [MinOSVersion(OsWin10TH1)]
  [SDKName('JOBOBJECT_NET_RATE_CONTROL_INFORMATION')]
  TJobObjectNetRateControlInformation = record
    [Bytes] MaxBandwidth: UInt64;
    ControlFlags: TJobNetControlFlags;
    [Hex] DscpTag: Byte; // 0x00..0x3F
  end;
  PJobObjectNetRateControlInformation = ^TJobObjectNetRateControlInformation;

  // SDK::winnt.h - info class 33
  [MinOSVersion(OsWin10TH1)]
  [SDKName('JOBOBJECT_NOTIFICATION_LIMIT_INFORMATION_2')]
  TJobObjectNotificationLimitInformation2 = record
    [Aggregate] v1: TJobObjectNotificationLimitInformation;
    IoRateControlTolerance: TJobObjectRateControlTolerance;
    [Bytes] JobLowMemoryLimit: UInt64;
    IoRateControlToleranceInterval: TJobObjectRateControlToleranceInterval;
    NetRateControlTolerance: TJobObjectRateControlTolerance;
    NetRateControlToleranceInterval: TJobObjectRateControlToleranceInterval;
  end;
  PJobObjectNotificationLimitInformation2 = ^TJobObjectNotificationLimitInformation2;

  // SDK::winnt.h - info class 34
  [MinOSVersion(OsWin10TH1)]
  [SDKName('JOBOBJECT_LIMIT_VIOLATION_INFORMATION_2')]
  TJobObjectLimitViolationInformation2 = record
    [Aggregate] v1: TJobObjectLimitViolationInformation;
    [Bytes] JobLowMemoryLimit: UInt64;
    IoRateControlTolerance: TJobObjectRateControlTolerance;
    IoRateControlToleranceLimit: TJobObjectRateControlTolerance;
    NetRateControlTolerance: TJobObjectRateControlTolerance;
    NetRateControlToleranceLimit: TJobObjectRateControlTolerance;
  end;
  PJobObjectLimitViolationInformation2 = ^TJobObjectLimitViolationInformation2;

  // SDK::winnt.h - info class 36
  [MinOSVersion(OsWin10TH1)]
  [SDKName('SILOOBJECT_BASIC_INFORMATION')]
  TSiloObjectBasicInformation = record
    SiloID: Cardinal;
    SiloParentID: Cardinal;
    NumberOfProcesses: Cardinal;
    IsInServerSilo: Boolean;
    Reserved: array [0..2] of Byte;
  end;
  PSiloObjectBasicInformation = ^TSiloObjectBasicInformation;

// Processes

// PHNT::ntpsapi.h
function NtCreateProcess(
  out ProcessHandle: THandle;
  DesiredAccess: TProcessAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [Access(PROCESS_CREATE_PROCESS)] ParentProcess: THandle;
  InheritObjectTable: Boolean;
  [opt, Access(SECTION_MAP_EXECUTE)] SectionHandle: THandle;
  [opt, Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle;
  [opt, Access(TOKEN_ASSIGN_PRIMARY)] PrimaryToken: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtCreateProcessEx(
  out ProcessHandle: THandle;
  DesiredAccess: TProcessAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [Access(PROCESS_CREATE_PROCESS)] ParentProcess: THandle;
  Flags: TProcessCreateFlags;
  [opt, Access(SECTION_MAP_EXECUTE)] SectionHandle: THandle;
  [opt, Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle;
  [opt, Access(TOKEN_ASSIGN_PRIMARY)] PrimaryToken: THandle;
  [opt] JobMemberLevel: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtOpenProcess(
  out ProcessHandle: THandle;
  DesiredAccess: TProcessAccessMask;
  const ObjectAttributes: TObjectAttributes;
  const ClientId: TClientId
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
function NtTerminateProcess(
  [Access(PROCESS_TERMINATE)] ProcessHandle: THandle;
  ExitStatus: NTSTATUS
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtSuspendProcess(
  [Access(PROCESS_SUSPEND_RESUME)] ProcessHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtResumeProcess(
  [Access(PROCESS_SUSPEND_RESUME)] ProcessHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// SDK::winternl.h
function NtQueryInformationProcess(
  [Access(PROCESS_QUERY_INFORMATION)] ProcessHandle: THandle;
  ProcessInformationClass: TProcessInfoClass;
  [out] ProcessInformation: Pointer;
  ProcessInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
[RequiredPrivilege(SE_INCREASE_QUOTA_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_INCREASE_BASE_PRIORITY_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpSometimes)]
function NtSetInformationProcess(
  [Access(PROCESS_SET_INFORMATION)]  ProcessHandle: THandle;
  ProcessInformationClass: TProcessInfoClass;
  [in] ProcessInformation: Pointer;
  ProcessInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtGetNextProcess(
  [opt, Access(0)] ProcessHandle: THandle;
  DesiredAccess: TProcessAccessMask;
  HandleAttributes: TObjectAttributesFlags;
  Flags: TProcessNextFlags;
  out NewProcessHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtGetNextThread(
  [Access(PROCESS_QUERY_INFORMATION)] ProcessHandle: THandle;
  [opt, Access(0)] ThreadHandle: THandle;
  DesiredAccess: TThreadAccessMask;
  HandleAttributes: TObjectAttributesFlags;
  [Reserved] Flags: Cardinal;
  out NewThreadHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// Process State

// rev, Windows Insider 20190+
function NtCreateProcessStateChange(
  out StateChangeHandle: THandle;
  DesiredAccess: TProcessStateAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [Access(PROCESS_SET_INFORMATION)] ProcessHandle: THandle;
  [Reserved] Reserved: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// rev, Windows Insider 20190+
function NtChangeProcessState(
  [Access(PROCESS_STATE_CHANGE_STATE)] StateChangeHandle: THandle;
  [Access(PROCESS_SUSPEND_RESUME)] ProcessHandle: THandle;
  Action: TProcessStateChangeType;
  [in, opt] ExtendedInformation: Pointer;
  ExtendedInformationLength: Cardinal;
  [Reserved] Reserved: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// Threads

// PHNT::ntpsapi.h
function NtCreateThread(
  out ThreadHandle: THandle;
  DesiredAccess: TThreadAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [Access(PROCESS_CREATE_THREAD)] ProcessHandle: THandle;
  out ClientId: TClientId;
  const ThreadContext: TContext;
  const InitialTeb: TInitialTeb;
  CreateSuspended: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtOpenThread(
  out ThreadHandle: THandle;
  DesiredAccess: TThreadAccessMask;
  const ObjectAttributes: TObjectAttributes;
  const ClientId: TClientId
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtTerminateThread(
  [opt, Access(THREAD_TERMINATE)] ThreadHandle: THandle;
  ExitStatus: NTSTATUS
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtSuspendThread(
  [Access(THREAD_SUSPEND_RESUME)] ThreadHandle: THandle;
  PreviousSuspendCount: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtResumeThread(
  [Access(THREAD_SUSPEND_RESUME)] ThreadHandle: THandle;
  PreviousSuspendCount: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtGetCurrentProcessorNumber: Cardinal; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtGetContextThread(
  [Access(THREAD_GET_CONTEXT)] ThreadHandle: THandle;
  [in, out] ThreadContext: PContext
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtSetContextThread(
  [Access(THREAD_SET_CONTEXT)] ThreadHandle: THandle;
  [in] ThreadContext: PContext
): NTSTATUS; stdcall; external ntdll;

// SDK::winternl.h
function NtQueryInformationThread(
  [Access(THREAD_QUERY_INFORMATION)] ThreadHandle: THandle;
  ThreadInformationClass: TThreadInfoClass;
  [out] ThreadInformation: Pointer;
  ThreadInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_INCREASE_BASE_PRIORITY_PRIVILEGE, rpSometimes)]
function NtSetInformationThread(
  [Access(THREAD_SET_INFORMATION)] ThreadHandle: THandle;
  ThreadInformationClass: TThreadInfoClass;
  [in] ThreadInformation: Pointer;
  ThreadInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtAlertThread(
  [Access(THREAD_ALERT)] ThreadHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtAlertResumeThread(
  [Access(THREAD_SUSPEND_RESUME)] ThreadHandle: THandle;
  [out, opt] PreviousSuspendCount: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtTestAlert: NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtImpersonateThread(
  [Access(THREAD_IMPERSONATE)] ServerThreadHandle: THandle;
  [Access(THREAD_DIRECT_IMPERSONATION)] ClientThreadHandle: THandle;
  const SecurityQos: TSecurityQualityOfService
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtRegisterThreadTerminatePort(
  [Access(PORT_CONNECT)] PortHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtQueueApcThread(
  [Access(THREAD_SET_CONTEXT)] ThreadHandle: THandle;
  ApcRoutine: TPsApcRoutine;
  [in, opt] ApcArgument1: Pointer;
  [in, opt] ApcArgument2: Pointer;
  [in, opt] ApcArgument3: Pointer
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtQueueApcThreadEx(
  ThreadHandle: THandle;
  [opt] ReserveHandle: THandle;
  [in] ApcRoutine: TPsApcRoutine;
  [in, opt] ApcArgument1: Pointer;
  [in, opt] ApcArgument2: Pointer;
  [in, opt] ApcArgument3: Pointer
): NTSTATUS; stdcall; external ntdll;

// Thread State

// rev, Windows Insider 20226+
function NtCreateThreadStateChange(
  out StateChangeHandle: THandle;
  DesiredAccess: TThreadStateAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [Access(THREAD_SET_INFORMATION)] ThreadHandle: THandle;
  [Reserved] Reserved: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// rev, Windows Insider 20226+
function NtChangeThreadState(
  [Access(THREAD_STATE_CHANGE_STATE)] StateChangeHandle: THandle;
  [Access(THREAD_SUSPEND_RESUME)] ThreadHandle: THandle;
  Action: TThreadStateChangeType;
  [in, opt] ExtendedInformation: Pointer;
  ExtendedInformationLength: Cardinal;
  [Reserved] Reserved: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// User processes and threads

// PHNT::ntpsapi.h
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function NtCreateUserProcess(
  out ProcessHandle: THandle;
  out ThreadHandle: THandle;
  ProcessDesiredAccess: TProcessAccessMask;
  ThreadDesiredAccess: TThreadAccessMask;
  [in, opt] ProcessObjectAttributes: PObjectAttributes;
  [in, opt] ThreadObjectAttributes: PObjectAttributes;
  ProcessFlags: TProcessCreateFlags;
  ThreadFlags: TThreadCreateFlags;
  [in, opt] ProcessParameters: PRtlUserProcessParameters;
  var CreateInfo: TPsCreateInfo;
  [in, opt] AttributeList: PPsAttributeList
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtCreateThreadEx(
  out ThreadHandle: THandle;
  DesiredAccess: TThreadAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [Access(PROCESS_CREATE_THREAD)] ProcessHandle: THandle;
  StartRoutine: TUserThreadStartRoutine;
  [in, opt] Argument: Pointer;
  CreateFlags: TThreadCreateFlags;
  ZeroBits: NativeUInt;
  StackSize: NativeUInt;
  MaximumStackSize: NativeUInt;
  [in, opt] AttributeList: PPsAttributeList
): NTSTATUS; stdcall; external ntdll;

// Job objects

// PHNT::ntpsapi.h
function NtCreateJobObject(
  out JobHandle: THandle;
  DesiredAccess: TJobObjectAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtOpenJobObject(
  out JobHandle: THandle;
  DesiredAccess: TJobObjectAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtAssignProcessToJobObject(
  [Access(JOB_OBJECT_ASSIGN_PROCESS)] JobHandle: THandle;
  [Access(PROCESS_SET_QUOTA or PROCESS_TERMINATE)] ProcessHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtTerminateJobObject(
  [Access(JOB_OBJECT_TERMINATE)] JobHandle: THandle;
  ExitStatus: NTSTATUS
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtIsProcessInJob(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] ProcessHandle: THandle;
  [opt, Access(JOB_OBJECT_QUERY)] JobHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
function NtQueryInformationJobObject(
  [Access(JOB_OBJECT_QUERY)] JobHandle: THandle;
  JobObjectInformationClass: TJobObjectInfoClass;
  [out] JobObjectInformation: Pointer;
  JobObjectInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntpsapi.h
[RequiredPrivilege(SE_INCREASE_QUOTA_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtSetInformationJobObject(
  [Access(JOB_OBJECT_SET_ATTRIBUTES)] JobHandle: THandle;
  JobObjectInformationClass: TJobObjectInfoClass;
  [in] JobObjectInformation: Pointer;
  JobObjectInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

{ Expected Access / Privileges }

function ExpectedProcessQueryAccess(
  InfoClass: TProcessInfoClass
): TProcessAccessMask;

function ExpectedProcessSetPrivilege(
  InfoClass: TProcessInfoClass
): TSeWellKnownPrivilege;

function ExpectedProcessSetAccess(
  InfoClass: TProcessInfoClass
): TProcessAccessMask;

function ExpectedThreadQueryAccess(
  InfoClass: TThreadInfoClass
): TThreadAccessMask;

function ExpectedThreadSetPrivilege(
  InfoClass: TThreadInfoClass
): TSeWellKnownPrivilege;

function ExpectedThreadSetAccess(
  InfoClass: TThreadInfoClass
):  TThreadAccessMask;

implementation

function NtCurrentProcessId;
begin
  Result := NtCurrentTeb.ClientId.UniqueProcess;
end;

function NtCurrentThreadId;
begin
  Result := NtCurrentTeb.ClientId.UniqueThread;
end;

{ TProcessHandleTracingEntry }

function TProcessHandleTracingEntry.StackTrace;
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

function TProcessTelemetryIdInformation.CommandLine;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).CommandLineOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + CommandLineOffset)
  else
    Result := nil;
end;

function TProcessTelemetryIdInformation.ImagePath;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).ImagePathOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + ImagePathOffset)
  else
    Result := nil;
end;

function TProcessTelemetryIdInformation.PackageName;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).PackageNameOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + PackageNameOffset)
  else
    Result := nil;
end;

function TProcessTelemetryIdInformation.RelativeAppName;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).RelativeAppNameOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + RelativeAppNameOffset)
  else
    Result := nil;
end;

function TProcessTelemetryIdInformation.UserSid;
begin
  if UIntPtr(@PProcessTelemetryIdInformation(nil).UserSidOffset) <
    HeaderSize then
    Result := Pointer(UIntPtr(@Self) + UserSidOffset)
  else
    Result := nil;
end;

{ TProcessUptimeInformation }

function TProcessUptimeInformation.GhostCount;
begin
  Result := (Flags and $F0) shr 4;
end;

function TProcessUptimeInformation.HangCount;
begin
  Result := Flags and $F;
end;

{ Expected Access }

function ExpectedProcessQueryAccess;
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

function ExpectedProcessSetPrivilege;
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

function ExpectedProcessSetAccess;
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

function ExpectedThreadQueryAccess;
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

function ExpectedThreadSetPrivilege;
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

function ExpectedThreadSetAccess;
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
