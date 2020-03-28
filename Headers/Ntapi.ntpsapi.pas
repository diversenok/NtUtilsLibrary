unit Ntapi.ntpsapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntrtl, DelphiApi.Reflection;

const
  // Processes

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

  ProcessAccessMapping: array [0..13] of TFlagName = (
    (Value: PROCESS_TERMINATE;                 Name: 'Terminate'),
    (Value: PROCESS_CREATE_THREAD;             Name: 'Create threads'),
    (Value: PROCESS_SET_SESSIONID;             Name: 'Set session ID'),
    (Value: PROCESS_VM_OPERATION;              Name: 'Modify memory'),
    (Value: PROCESS_VM_READ;                   Name: 'Read memory'),
    (Value: PROCESS_VM_WRITE;                  Name: 'Write memory'),
    (Value: PROCESS_DUP_HANDLE;                Name: 'Duplicate handles'),
    (Value: PROCESS_CREATE_PROCESS;            Name: 'Create process'),
    (Value: PROCESS_SET_QUOTA;                 Name: 'Set quota'),
    (Value: PROCESS_SET_INFORMATION;           Name: 'Set information'),
    (Value: PROCESS_QUERY_INFORMATION;         Name: 'Query information'),
    (Value: PROCESS_SUSPEND_RESUME;            Name: 'Suspend/resume'),
    (Value: PROCESS_QUERY_LIMITED_INFORMATION; Name: 'Query limited information'),
    (Value: PROCESS_SET_LIMITED_INFORMATION;   Name: 'Set limited information')
  );

  ProcessAccessType: TAccessMaskType = (
    TypeName: 'process';
    FullAccess: PROCESS_ALL_ACCESS;
    Count: Length(ProcessAccessMapping);
    Mapping: PFlagNameRefs(@ProcessAccessMapping);
  );

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

  ThreadAccessMapping: array [0..12] of TFlagName = (
    (Value: THREAD_TERMINATE;                 Name: 'Terminate'),
    (Value: THREAD_SUSPEND_RESUME;            Name: 'Suspend/resume'),
    (Value: THREAD_ALERT;                     Name: 'Alert'),
    (Value: THREAD_GET_CONTEXT;               Name: 'Get context'),
    (Value: THREAD_SET_CONTEXT;               Name: 'Set context'),
    (Value: THREAD_SET_INFORMATION;           Name: 'Set information'),
    (Value: THREAD_QUERY_INFORMATION;         Name: 'Query information'),
    (Value: THREAD_SET_THREAD_TOKEN;          Name: 'Set token'),
    (Value: THREAD_IMPERSONATE;               Name: 'Impersonate'),
    (Value: THREAD_DIRECT_IMPERSONATION;      Name: 'Direct impersonation'),
    (Value: THREAD_SET_LIMITED_INFORMATION;   Name: 'Set limited information'),
    (Value: THREAD_QUERY_LIMITED_INFORMATION; Name: 'Query limited information'),
    (Value: THREAD_RESUME;                    Name: 'Resume')
  );

  ThreadAccessType: TAccessMaskType = (
    TypeName: 'thread';
    FullAccess: THREAD_ALL_ACCESS;
    Count: Length(ThreadAccessMapping);
    Mapping: PFlagNameRefs(@ThreadAccessMapping);
  );

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

  JobAccessMapping: array [0..5] of TFlagName = (
    (Value: JOB_OBJECT_ASSIGN_PROCESS;          Name: 'Assign process'),
    (Value: JOB_OBJECT_SET_ATTRIBUTES;          Name: 'Set attributes'),
    (Value: JOB_OBJECT_QUERY;                   Name: 'Query'),
    (Value: JOB_OBJECT_TERMINATE;               Name: 'Terminate'),
    (Value: JOB_OBJECT_SET_SECURITY_ATTRIBUTES; Name: 'Set security attributes'),
    (Value: JOB_OBJECT_IMPERSONATE;             Name: 'Impersonate')
  );

  JobAccessType: TAccessMaskType = (
    TypeName: 'job object';
    FullAccess: JOB_OBJECT_ALL_ACCESS;
    Count: Length(JobAccessMapping);
    Mapping: PFlagNameRefs(@JobAccessMapping);
  );

  JOB_OBJECT_UILIMIT_HANDLES = $00000001;
  JOB_OBJECT_UILIMIT_READCLIPBOARD = $00000002;
  JOB_OBJECT_UILIMIT_WRITECLIPBOARD = $00000004;
  JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS = $00000008;
  JOB_OBJECT_UILIMIT_DISPLAYSETTINGS = $00000010;
  JOB_OBJECT_UILIMIT_GLOBALATOMS = $00000020;
  JOB_OBJECT_UILIMIT_DESKTOP = $00000040;
  JOB_OBJECT_UILIMIT_EXITWINDOWS = $00000080;

  JOB_OBJECT_TERMINATE_AT_END_OF_JOB = 0;
  JOB_OBJECT_POST_AT_END_OF_JOB = 1;

  NtCurrentProcess: THandle = THandle(-1);
  NtCurrentThread: THandle = THandle(-2);

  // Not NT, but useful
  function NtCurrentProcessId: TProcessId;
  function NtCurrentThreadId: TThreadId;

type
  // Processes

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
    ProcessExceptionPort = 8,         // s: LPC port Handle
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
    ProcessDeviceMap = 23,               // q: ... s: Handle
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
    ProcessPagePriority = 39,            // q, s: Cardinal
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
    ProcessRevokeFileHandles = 56,         // s:
    ProcessWorkingSetControl = 57,         // s: 
    ProcessHandleTable = 58,               // q: Win 8.1+
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
    ProcessJobMemoryInformation = 69,      // q:
    ProcessInPrivate = 70,                 // q, s: Boolean, Win 10 TH2+
    ProcessRaiseUMExceptionOnInvalidHandleClose = 71, // q
    ProcessIumChallengeResponse = 72,      // q, s:
    ProcessChildProcessInformation = 73,   // q:
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
    ProcessUptimeInformation = 88,              // q:
    ProcessImageSection = 89,                   // q: Handle
    ProcessDebugAuthInformation = 90,           // s: Win 10 RS4+
    ProcessSystemResourceManagement = 91,       // s: 
    ProcessSequenceNumber = 92,                 // q: NativeUInt
    ProcessLoaderDetour = 93,                   // s: Win 10 RS5+
    ProcessSecurityDomainInformation = 94,      // q:
    ProcessCombineSecurityDomainsInformation = 95, // s: process Handle
    ProcessEnableLogging = 96,                  // q, s:
    ProcessLeapSecondInformation = 97,          // q, s: (self only)
    ProcessFiberShadowStackAllocation = 98,     // s: (self only), Win 10 19H1+
    ProcessFreeFiberShadowStackAllocation = 99  // s: (self only)
  );

  TProcessBasicInformation = record
    ExitStatus: NTSTATUS;
    [DontFollow] PebBaseAddress: PPeb;
    [Hex] AffinityMask: NativeUInt;
    BasePriority: KPRIORITY;
    UniqueProcessID: TProcessId;
    InheritedFromUniqueProcessID: TProcessId;
  end;
  PProcessBasicInformation = ^TProcessBasicInformation;

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

  TKernelUserTimes = record
    CreateTime: TLargeInteger;
    ExitTime: TLargeInteger;
    KernelTime: TULargeInteger;
    UserTime: TULargeInteger;
  end;
  PKernelUserTimes = ^TKernelUserTimes;

  TProcessAccessToken = record
    Token: THandle; // needs TOKEN_ASSIGN_PRIMARY
    Thread: THandle; // currently unused, was THREAD_QUERY_INFORMATION
  end;
  PProcessAccessToken = ^TProcessAccessToken;

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
    Forground: Boolean;
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

  TProcessHandleTracingEntry = record
    Handle: THandle;
    ClientId: TClientId;
    TraceType: THandleTraceType;
    Stacks: array [0 .. PROCESS_HANDLE_TRACING_MAX_STACKS - 1] of Pointer;
  end;

  TProcessHandleTracingQuery = record
    Handle: THandle;
    TotalTraces: Integer; // Max PROCESS_HANDLE_TRACING_MAX_SLOTS
    HandleTrace: array [ANYSIZE_ARRAY] of TProcessHandleTracingEntry;
  end;
  PProcessHandleTracingQuery = ^TProcessHandleTracingQuery;

  TProcessCycleTimeInformation = record
    AccumulatedCycles: UInt64;
    CurrentCycleCount: UInt64;
  end;
  PProcessCycleTimeInformation = TProcessCycleTimeInformation;

  TProcessWindowInformation = record
    WindowFlags: Cardinal;
    WindowTitleLength: Word;
    WindowTitle: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PProcessWindowInformation = ^TProcessWindowInformation;

  TProcessHandleTableEntryInfo = record
    HandleValue: THandle;
    HandleCount: NativeUInt;
    PointerCount: NativeUInt;
    GrantedAccess: TAccessMask;
    ObjectTypeIndex: Cardinal;
    [Hex] HandleAttributes: Cardinal;
    [Unlisted] Reserved: Cardinal;
  end;
  PProcessHandleTableEntryInfo = ^TProcessHandleTableEntryInfo;

  TProcessHandleSnapshotInformation = record
    NumberOfHandles: NativeUInt;
    [Unlisted] Reserved: NativeUInt;
    Handles: array [ANYSIZE_ARRAY] of TProcessHandleTableEntryInfo;
  end;
  PProcessHandleSnapshotInformation = ^TProcessHandleSnapshotInformation;

  // WinNt.11590, Win 8+
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

  TProcessMitigationPolicyInformation = record
    Policy: TProcessMitigationPolicy;
    [Hex] Flags: Cardinal;
  end;
  PProcessMitigationPolicyInformation = ^TProcessMitigationPolicyInformation;

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

  // Threads

  TInitialTeb = record
    OldStackBase: Pointer;
    OldStackLimit: Pointer;
    StackBase: Pointer;
    StackLimit: Pointer;
    StackAllocationBase: Pointer;
  end;
  PInitialTeb = ^TInitialTeb;

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
    ThreadPagePriority = 24,             // q, s: Cardinal
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
    ThreadContainerId = 37,              // q: GUID (self only)
    ThreadNameInformation = 38,          // q, s: UNICODE_STRING
    ThreadSelectedCpuSets = 39,          // q, s:
    ThreadSystemThreadInformation = 40,  // q: TSystemThreadInformation
    ThreadActualGroupAffinity = 41,      // q: Win 10 TH2+
    ThreadDynamicCodePolicyInfo = 42,    // q, s: LongBool (setter self only), Win 8+
    ThreadExplicitCaseSensitivity = 43,  // q, s: LongBool
    ThreadWorkOnBehalfTicket = 44,       // q, s: (self only)
    ThreadSubsystemInformation = 45,     // q: Win 10 RS2+
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

  TThreadLastSyscall = record
    FirstArgument: NativeUInt;
    SystemCallNumber: NativeUInt;
    WaitTime: UInt64;
  end;
  PThreadLastSyscall = ^TThreadLastSyscall;

  TThreadTebInformation = record
    TebInformation: Pointer;
    [Hex] TebOffset: Cardinal;
    [Bytes] BytesToRead: Cardinal;
  end;
  PThreadTebInformation = ^TThreadTebInformation;

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
    [Bytes] TotalLength: NativeUInt;
    Attributes: array [ANYSIZE_ARRAY] of TPsAttribute;
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

  [NamingStyle(nsCamelCase, 'JobObject'), Range(1)]
  TJobObjectInfoClass = (
    JobObjectReserved = 0,
    JobObjectBasicAccountingInformation = 1, // q: TJobBasicAccountingInfo
    JobObjectBasicLimitInformation = 2,      // q, s: TJobBasicLimitInfo
    JobObjectBasicProcessIdList = 3,         // q: TJobBasicProcessIdList
    JobObjectBasicUIRestrictions = 4,        // q, s: Cardinal (UI flags)
    JobObjectSecurityLimitInformation = 5,   // not supported
    JobObjectEndOfJobTimeInformation = 6,    // s: Cardinal (EndOfJobTimeAction)
    JobObjectAssociateCompletionPortInformation = 7, // s: TJobAssociateCompletionPort
    JobObjectBasicAndIoAccountingInformation = 8, // q: TJobBasicAndIoAccountingInfo
    JobObjectExtendedLimitInformation = 9,   // q, s: TJobExtendedLimitInfo
    JobObjectJobSetInformation = 10,         // q: Cardinal (MemberLevel)
    JobObjectGroupInformation = 11,          // q, s: Word
    JobObjectNotificationLimitInformation = 12, // q, s: TJobNotificationLimitInfo
    JobObjectLimitViolationInformation = 13, //
    JobObjectGroupInformationEx = 14,        // q, s:
    JobObjectCpuRateControlInformation = 15  // q, s: TJobCpuRateControlInfo
  );

  TJobBasicAccountingInfo = record
    TotalUserTime: TLargeInteger;
    TotalKernelTime: TLargeInteger;
    ThisPeriodTotalUserTime: TLargeInteger;
    ThisPeriodTotalKernelTime: TLargeInteger;
    TotalPageFaultCount: Cardinal;
    TotalProcesses: Cardinal;
    ActiveProcesses: Cardinal;
    TotalTerminatedProcesses: Cardinal;
  end;
  PJobBasicAccountingInfo = ^TJobBasicAccountingInfo;

  TJobBasicLimitInfo = record
    PerProcessUserTimeLimit: TLargeInteger;
    PerJobUserTimeLimit: TLargeInteger;
    [Hex] LimitFlags: Cardinal;
    [Bytes] MinimumWorkingSetSize: NativeUInt;
    [Bytes] MaximumWorkingSetSize: NativeUInt;
    ActiveProcessLimit: Cardinal;
    [Hex] Affinity: NativeUInt;
    PriorityClass: Cardinal;
    SchedulingClass: Cardinal;
  end;
  PJobBasicLimitInfo = ^TJobBasicLimitInfo;

  TJobBasicProcessIdList = record
    NumberOfAssignedProcesses: Cardinal;
    NumberOfProcessIdsInList: Cardinal;
    ProcessIdList: array [ANYSIZE_ARRAY] of NativeUInt;
  end;
  PJobBasicProcessIdList = ^TJobBasicProcessIdList;

  [NamingStyle(nsSnakeCase, 'JOB_OBJECT_MSG'), Range(1)]
  TJobObjectMsg = (
    JOB_OBJECT_MSG_RESERVED = 0,
    JOB_OBJECT_MSG_END_OF_JOB_TIME = 1,
    JOB_OBJECT_MSG_END_OF_PROCESS_TIME = 2,
    JOB_OBJECT_MSG_ACTIVE_PROCESS_LIMIT = 3,
    JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO = 4,
    JOB_OBJECT_MSG_NEW_PROCESS = 6,
    JOB_OBJECT_MSG_EXIT_PROCESS = 7,
    JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS = 8,
    JOB_OBJECT_MSG_PROCESS_MEMORY_LIMIT = 9,
    JOB_OBJECT_MSG_JOB_MEMORY_LIMIT = 10,
    JOB_OBJECT_MSG_NOTIFICATION_LIMIT = 11,
    JOB_OBJECT_MSG_JOB_CYCLE_TIME_LIMIT = 12,
    JOB_OBJECT_MSG_SILO_TERMINATED = 13
  );

  TJobAssociateCompletionPort = record
    CompletionKey: Pointer;
    CompletionPort: THandle;
  end;
  PJobAssociateCompletionPort = ^TJobAssociateCompletionPort;

  TJobBasicAndIoAccountingInfo = record
    BasicInfo: TJobBasicAccountingInfo;
    IoInfo: TIoCounters;
  end;
  PJobBasicAndIoAccountingInfo = ^TJobBasicAndIoAccountingInfo;

  TJobExtendedLimitInfo = record
    BasicLimitInformation: TJobBasicLimitInfo;
    IoInfo: TIoCounters;
    [Bytes] ProcessMemoryLimit: NativeUInt;
    [Bytes] JobMemoryLimit: NativeUInt;
    [Bytes] PeakProcessMemoryUsed: NativeUInt;
    [Bytes] PeakJobMemoryUsed: NativeUInt;
  end;
  PJobExtendedLimitInfo = ^TJobExtendedLimitInfo;

  [NamingStyle(nsCamelCase, 'Tolerance'), Range(1)]
  TJobRateControlTolerance = (
    ToleranceInvalid = 0,
    ToleranceLow = 1,
    ToleranceMedium = 2,
    ToleranceHigh = 3
  );

  [NamingStyle(nsCamelCase, 'ToleranceInterval'), Range(1)]
  TJobRateControlToleranceInterval = (
    ToleranceIntervalInvalid = 0,
    ToleranceIntervalShort = 1,
    ToleranceIntervalMedium = 2,
    ToleranceIntervalLong = 3
  );

  TJobNotificationLimitInfo = record
    [Bytes] IoReadBytesLimit: UInt64;
    [Bytes] IoWriteBytesLimit: UInt64;
    PerJobUserTimeLimit: TLargeInteger;
    [Bytes] JobMemoryLimit: UInt64;
    RateControlTolerance: TJobRateControlTolerance;
    RateControlToleranceInterval: TJobRateControlToleranceInterval;
    [Hex] LimitFlags: Cardinal;
  end;
  PJobNotificationLimitInfo = ^TJobNotificationLimitInfo;

  TJobCpuRateControlInfo = record
    [Hex] ControlFlags: Cardinal;
  case Integer of
    0: (CpuRate: Cardinal);
    1: (Weight: Cardinal);
    2: (MinRate: Word; MaxRate: Word);
  end;
  PJobCpuRateControlInfo = ^TJobCpuRateControlInfo;

// Processes

function NtCreateProcess(out ProcessHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; ParentProcess: THandle;
  InheritObjectTable: Boolean; SectionHandle: THandle; DebugPort: THandle;
  ExceptionPort: THandle): NTSTATUS; stdcall; external ntdll;

function NtCreateProcessEx(out ProcessHandle: THandle; DesiredAccess:
  TAccessMask; ObjectAttributes: PObjectAttributes; ParentProcess: THandle;
  Flags: Cardinal; SectionHandle: THandle; DebugPort: THandle; ExceptionPort:
  THandle; JobMemberLevel: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtOpenProcess(out ProcessHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; const ClientId: TClientId):
  NTSTATUS; stdcall; external ntdll;

function NtTerminateProcess(ProcessHandle: THandle; ExitStatus: NTSTATUS):
  NTSTATUS; stdcall; external ntdll;

function NtSuspendProcess(ProcessHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtResumeProcess(ProcessHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtQueryInformationProcess(ProcessHandle: THandle;
  ProcessInformationClass: TProcessInfoClass; ProcessInformation: Pointer;
  ProcessInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS;
  stdcall; external ntdll;

// Absent in ReactOS
function NtGetNextProcess(ProcessHandle: THandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal; Flags: Cardinal; out NewProcessHandle: THandle):
  NTSTATUS; stdcall; external ntdll delayed;

// Absent in ReactOS
function NtGetNextThread(ProcessHandle: THandle; ThreadHandle: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal; Flags: Cardinal;
  out NewThreadHandle: THandle): NTSTATUS; stdcall; external ntdll delayed;

function NtSetInformationProcess(ProcessHandle: THandle;
  ProcessInformationClass: TProcessInfoClass; ProcessInformation: Pointer;
  ProcessInformationLength: Cardinal): NTSTATUS; stdcall; external ntdll;

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

function NtQueryInformationThread(ThreadHandle: THandle;
  ThreadInformationClass: TThreadInfoClass; ThreadInformation: Pointer;
  ThreadInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS;
  stdcall; external ntdll;

function NtSetInformationThread(ThreadHandle: THandle;
  ThreadInformationClass: TThreadInfoClass; ThreadInformation: Pointer;
  ThreadInformationLength: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtAlertThread(ThreadHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtAlertResumeThread(ThreadHandle: THandle; PreviousSuspendCount:
  PCardinal): NTSTATUS; stdcall; external ntdll;

function NtImpersonateThread(ServerThreadHandle: THandle;
  ClientThreadHandle: THandle; const SecurityQos: TSecurityQualityOfService):
  NTSTATUS; stdcall; external ntdll;

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
  const ObjectAttributes: TObjectAttributes): NTSTATUS; stdcall; external ntdll;

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

implementation

function NtCurrentProcessId: TProcessId;
begin
  Result := NtCurrentTeb.ClientId.UniqueProcess;
end;

function NtCurrentThreadId: TThreadId;
begin
  Result := NtCurrentTeb.ClientId.UniqueThread;
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

end.
