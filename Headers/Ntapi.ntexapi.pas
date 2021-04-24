unit Ntapi.ntexapi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpebteb, NtUtils.Version,
  DelphiApi.Reflection;

const
  EVENT_QUERY_STATE = $0001;
  EVENT_MODIFY_STATE = $0002;
  EVENT_ALL_ACCESS = STANDARD_RIGHTS_ALL or $0003;

  MUTANT_QUERY_STATE = $0001;
  MUTANT_ALL_ACCESS = STANDARD_RIGHTS_ALL or MUTANT_QUERY_STATE;

  SEMAPHORE_QUERY_STATE = $0001;
  SEMAPHORE_MODIFY_STATE = $0002;
  SEMAPHORE_ALL_ACCESS = STANDARD_RIGHTS_ALL or $0003;

  TIMER_QUERY_STATE = $0001;
  TIMER_MODIFY_STATE = $0002;
  TIMER_ALL_ACCESS = STANDARD_RIGHTS_ALL or $0003;

  PROFILE_CONTROL = $0001;
  PROFILE_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or PROFILE_CONTROL;

  KEYEDEVENT_WAIT = $0001;
  KEYEDEVENT_WAKE = $0002;
  KEYEDEVENT_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $03;

  // System

  SYSTEM_PROCESS_HAS_STRONG_ID = $0001;
  SYSTEM_PROCESS_BACKGROUND_ACTIVITY_MODERATED = $0004;
  SYSTEM_PROCESS_VALID_MASK = $FFFFFFE1;

  // Global flags

  FLG_MAINTAIN_OBJECT_TYPELIST = $4000; // kernel

type
  [FriendlyName('event'), ValidMask(EVENT_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(EVENT_QUERY_STATE, 'Query State')]
  [FlagName(EVENT_MODIFY_STATE, 'Modify State')]
  TEventAccessMask = type TAccessMask;

  [FriendlyName('mutex'), ValidMask(MUTANT_ALL_ACCESS)]
  [FlagName(MUTANT_QUERY_STATE, 'Query State')]
  TMutantAccessMask = type TAccessMask;

  [FriendlyName('semaphore'), ValidMask(SEMAPHORE_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SEMAPHORE_QUERY_STATE, 'Query State')]
  [FlagName(SEMAPHORE_MODIFY_STATE, 'Modify State')]
  TSemaphoreAccessMask = type TAccessMask;

  [FriendlyName('timer'), ValidMask(TIMER_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(TIMER_QUERY_STATE, 'Query State')]
  [FlagName(TIMER_MODIFY_STATE, 'Modify State')]
  TTimerAccessMask = type TAccessMask;

  [FriendlyName('profile'), ValidMask(PROFILE_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(PROFILE_CONTROL, 'Control')]
  TProfileAccessMask = type TAccessMask;

  [FriendlyName('keyed event')]
  [ValidMask(KEYEDEVENT_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(KEYEDEVENT_WAIT, 'Wait')]
  [FlagName(KEYEDEVENT_WAKE, 'Wake')]
  TKeyedEventAccessMask = type TAccessMask;

  // Event

  [NamingStyle(nsCamelCase, 'Event')]
  TEventInformationClass = (
    EventBasicInformation = 0 // q: TEventBasicInformation
  );

  TEventBasicInformation = record
    EventType: TEventType;
    EventState: Integer;
  end;
  PEventBasicInformation = ^TEventBasicInformation;

  // Mutant

  [NamingStyle(nsCamelCase, 'Mutant')]
  TMutantInformationClass = (
    MutantBasicInformation = 0, // q: TMutantBasicInformation
    MutantOwnerInformation = 1  // q: TClientId
  );

  TMutantBasicInformation = record
    CurrentCount: Integer;
    OwnedByCaller: Boolean;
    AbandonedState: Boolean;
  end;
  PMutantBasicInformation = ^TMutantBasicInformation;

  // Semaphore

  [NamingStyle(nsCamelCase, 'Semaphore')]
  TSemaphoreInformationClass = (
    SemaphoreBasicInformation = 0 // q: TSemaphoreBasicInformation
  );

  TSemaphoreBasicInformation = record
    CurrentCount: Integer;
    MaximumCount: Integer;
  end;
  PSemaphoreBasicInformation = ^TSemaphoreBasicInformation;

  // Timer

  [NamingStyle(nsCamelCase, 'Timer')]
  TTimerInformationClass = (
    TimerBasicInformation = 0 // q: TTimerBasicInformation
  );

  TTimerBasicInformation = record
    RemainingTime: TLargeInteger;
    TimerState: Boolean;
  end;
  PTimerBasicInformation = ^TTimerBasicInformation;

  TTimerApcRoutine = procedure(
    TimerContext: Pointer;
    TimerLowValue: Cardinal;
    TimerHighValue: Integer
  ); stdcall;

  [NamingStyle(nsCamelCase, 'Timer')]
  TTimerSetInformationClass = (
    TimerSetCoalescableTimer = 0 // s: TTimerSetCoalescableTimerInfo
  );

  TTimerSetCoalescableTimerInfo = record
    DueTime: TLargeInteger;            // in
    TimerApcRoutine: TTimerApcRoutine; // in opt
    TimerContext: Pointer;             // in opt
    WakeContext: Pointer;              // in opt
    Period: Cardinal;                  // in opt
    TolerableDelay: Cardinal;          // in
    PreviousState: PBoolean;           // out opt
  end;
  PTimerSetCoalescableTimerInfo = ^TTimerSetCoalescableTimerInfo;

  // System Information

  [NamingStyle(nsCamelCase, 'System')]
  TSystemInformationClass = (
    SystemBasicInformation = 0, // q: TSystemBasicInformation
    SystemProcessorInformation = 1,
    SystemPerformanceInformation = 2,
    SystemTimeOfDayInformation = 3,
    SystemPathInformation = 4,
    SystemProcessInformation = 5, // q: TSystemProcessInformation
    SystemCallCountInformation = 6,
    SystemDeviceInformation = 7,
    SystemProcessorPerformanceInformation = 8,
    SystemFlagsInformation = 9,
    SystemCallTimeInformation = 10,
    SystemModuleInformation = 11, // q: TRtlProcessModules
    SystemLocksInformation = 12,
    SystemStackTraceInformation = 13,
    SystemPagedPoolInformation = 14,
    SystemNonPagedPoolInformation = 15,
    SystemHandleInformation = 16,
    SystemObjectInformation = 17, // q: TSystemObjectTypeInformation mixed with TSystemObjectInformation
    SystemPageFileInformation = 18,
    SystemVdmInstemulInformation = 19,
    SystemVdmBopInformation = 20,
    SystemFileCacheInformation = 21,
    SystemPoolTagInformation = 22,
    SystemInterruptInformation = 23,
    SystemDpcBehaviorInformation = 24,
    SystemFullMemoryInformation = 25,
    SystemLoadGdiDriverInformation = 26,
    SystemUnloadGdiDriverInformation = 27,
    SystemTimeAdjustmentInformation = 28,
    SystemSummaryMemoryInformation = 29,
    SystemMirrorMemoryInformation = 30,
    SystemPerformanceTraceInformation = 31,
    SystemObsolete0 = 32,
    SystemExceptionInformation = 33,
    SystemCrashDumpStateInformation = 34,
    SystemKernelDebuggerInformation = 35,
    SystemContextSwitchInformation = 36,
    SystemRegistryQuotaInformation = 37,
    SystemExtendServiceTableInformation = 38,
    SystemPrioritySeperation = 39,
    SystemVerifierAddDriverInformation = 40,
    SystemVerifierRemoveDriverInformation = 41,
    SystemProcessorIdleInformation = 42,
    SystemLegacyDriverInformation = 43,
    SystemCurrentTimeZoneInformation = 44, // q, s: TRtlTimeZoneInformation
    SystemLookasideInformation = 45,
    SystemTimeSlipNotification = 46,
    SystemSessionCreate = 47,
    SystemSessionDetach = 48,
    SystemSessionInformation = 49,
    SystemRangeStartInformation = 50,
    SystemVerifierInformation = 51,
    SystemVerifierThunkExtend = 52,
    SystemSessionProcessInformation = 53, // q: TSystemSessionProcessInformation
    SystemLoadGdiDriverInSystemSpace = 54,
    SystemNumaProcessorMap = 55,
    SystemPrefetcherInformation = 56,
    SystemExtendedProcessInformation = 57, // q: TSystemExtendedProcessInformation
    SystemRecommendedSharedDataAlignment = 58,
    SystemComPlusPackage = 59,
    SystemNumaAvailableMemory = 60,
    SystemProcessorPowerInformation = 61,
    SystemEmulationBasicInformation = 62,
    SystemEmulationProcessorInformation = 63,
    SystemExtendedHandleInformation = 64, // q: TSystemHandleInformationEx
    SystemLostDelayedWriteInformation = 65,
    SystemBigPoolInformation = 66,
    SystemSessionPoolTagInformation = 67,
    SystemSessionMappedViewInformation = 68,
    SystemHotpatchInformation = 69,
    SystemObjectSecurityMode = 70,
    SystemWatchdogTimerHandler = 71,
    SystemWatchdogTimerInformation = 72,
    SystemLogicalProcessorInformation = 73,
    SystemWow64SharedInformationObsolete = 74,
    SystemRegisterFirmwareTableInformationHandler = 75,
    SystemFirmwareTableInformation = 76,
    SystemModuleInformationEx = 77, // q: TRtlProcessModuleInformationEx
    SystemVerifierTriageInformation = 78,
    SystemSuperfetchInformation = 79,
    SystemMemoryListInformation = 80,
    SystemFileCacheInformationEx = 81,
    SystemThreadPriorityClientIdInformation = 82,
    SystemProcessorIdleCycleTimeInformation = 83,
    SystemVerifierCancellationInformation = 84,
    SystemProcessorPowerInformationEx = 85,
    SystemRefTraceInformation = 86,
    SystemSpecialPoolInformation = 87,
    SystemProcessIdInformation = 88, // q: TSystemProcessIdInformation
    SystemErrorPortInformation = 89,
    SystemBootEnvironmentInformation = 90,
    SystemHypervisorInformation = 91,
    SystemVerifierInformationEx = 92,
    SystemTimeZoneInformation = 93,
    SystemImageFileExecutionOptionsInformation = 94,
    SystemCoverageInformation = 95,
    SystemPrefetchPatchInformation = 96,
    SystemVerifierFaultsInformation = 97,
    SystemSystemPartitionInformation = 98,
    SystemSystemDiskInformation = 99,
    SystemProcessorPerformanceDistribution = 100,
    SystemNumaProximityNodeInformation = 101,
    SystemDynamicTimeZoneInformation = 102,
    SystemCodeIntegrityInformation = 103,
    SystemProcessorMicrocodeUpdateInformation = 104,
    SystemProcessorBrandString = 105,
    SystemVirtualAddressInformation = 106,
    SystemLogicalProcessorAndGroupInformation = 107,
    SystemProcessorCycleTimeInformation = 108,
    SystemStoreInformation = 109,
    SystemRegistryAppendString = 110,
    SystemAitSamplingValue = 111,
    SystemVhdBootInformation = 112,
    SystemCpuQuotaInformation = 113,
    SystemNativeBasicInformation = 114,
    SystemSpare1 = 115,
    SystemLowPriorityIoInformation = 116,
    SystemTpmBootEntropyInformation = 117,
    SystemVerifierCountersInformation = 118,
    SystemPagedPoolInformationEx = 119,
    SystemSystemPtesInformationEx = 120,
    SystemNodeDistanceInformation = 121,
    SystemAcpiAuditInformation = 122,
    SystemBasicPerformanceInformation = 123,
    SystemQueryPerformanceCounterInformation = 124,
    SystemSessionBigPoolInformation = 125,
    SystemBootGraphicsInformation = 126,
    SystemScrubPhysicalMemoryInformation = 127,
    SystemBadPageInformation = 128,
    SystemProcessorProfileControlArea = 129,
    SystemCombinePhysicalMemoryInformation = 130,
    SystemEntropyInterruptTimingCallback = 131,
    SystemConsoleInformation = 132,
    SystemPlatformBinaryInformation = 133,
    SystemThrottleNotificationInformation = 134,
    SystemHypervisorProcessorCountInformation = 135,
    SystemDeviceDataInformation = 136,
    SystemDeviceDataEnumerationInformation = 137,
    SystemMemoryTopologyInformation = 138,
    SystemMemoryChannelInformation = 139,
    SystemBootLogoInformation = 140,
    SystemProcessorPerformanceInformationEx = 141,
    SystemSpare0 = 142,
    SystemSecureBootPolicyInformation = 143,
    SystemPageFileInformationEx = 144,
    SystemSecureBootInformation = 145,
    SystemEntropyInterruptTimingRawInformation = 146,
    SystemPortableWorkspaceEfiLauncherInformation = 147,
    SystemFullProcessInformation = 148 // q: TSystemExtendedProcessInformation + TSystemProcessInformationExtension
  );

  // info class 0
  TSystemBasicInformation = record
    [Reserved] Reserved: Cardinal;
    TimerResolution: Cardinal;
    [Bytes] PageSize: Cardinal;
    NumberOfPhysicalPages: Cardinal;
    LowestPhysicalPageNumber: Cardinal;
    HighestPhysicalPageNumber: Cardinal;
    [Bytes] AllocationGranularity: Cardinal;
    MinimumUserModeAddress: Pointer;
    MaximumUserModeAddress: Pointer;
    [Hex] ActiveProcessorsAffinityMask: NativeUInt;
    NumberOfProcessors: Byte;
  end;

  // ksarm.h, 978
  {$SCOPEDENUMS ON}
  [NamingStyle(nsCamelCase)]
  TThreadState = (
    Initialized = 0,
    Ready = 1,
    Running = 2,
    Standby = 3,
    Terminated = 4,
    Waiting = 5,
    Transition = 6,
    DeferredReady = 7,
    GateWaitObsolete = 8,
    WaitingForProcessInSwap = 9
  );
  {$SCOPEDENUMS OFF}

  // wdm.20556
  {$SCOPEDENUMS ON}
  [NamingStyle(nsCamelCase, 'Wr')]
  TWaitReason = (
    Executive = 0,
    FreePage = 1,
    PageIn = 2,
    PoolAllocation = 3,
    DelayExecution = 4,
    Suspended = 5,
    UserRequest = 6,
    WrExecutive = 7,
    WrFreePage = 8,
    WrPageIn = 9,
    WrPoolAllocation = 10,
    WrDelayExecution = 11,
    WrSuspended = 12,
    WrUserRequest = 13,
    WrEventPair = 14,
    WrQueue = 15,
    WrLpcReceive = 16,
    WrLpcReply = 17,
    WrVirtualMemory = 18,
    WrPageOut = 19,
    WrRendezvous = 20,
    WrKeyedEvent = 21,
    WrTerminated = 22,
    WrProcessInSwap = 23,
    WrCpuRateControl = 24,
    WrCalloutStack = 25,
    WrKernel = 26,
    WrResource = 27,
    WrPushLock = 28,
    WrMutex = 29,
    WrQuantumEnd = 30,
    WrDispatchInt = 31,
    WrPreempted = 32,
    WrYieldExecution = 33,
    WrFastMutex = 34,
    WrGuardedMutex = 35,
    WrRundown = 36,
    WrAlertByThreadId = 37,
    WrDeferredPreempt = 38
  );
  {$SCOPEDENUMS OFF}

  TSystemThreadInformation = record
    KernelTime: TLargeInteger;
    UserTime: TLargeInteger;
    CreateTime: TLargeInteger;
    WaitTime: Cardinal;
    StartAddress: Pointer;
    ClientID: TClientId;
    Priority: TPriority;
    BasePriority: Integer;
    ContextSwitches: Cardinal;
    ThreadState: TThreadState;
    WaitReason: TWaitReason;
  end;
  PSystemThreadInformation = ^TSystemThreadInformation;

  TSystemProcessInformationFixed = record
    [Hex, Unlisted] NextEntryOffset: Cardinal;
    [Counter] NumberOfThreads: Cardinal;
    [Bytes] WorkingSetPrivateSize: UInt64;
    HardFaultCount: Cardinal;
    NumberOfThreadsHighWatermark: Cardinal;
    CycleTime: UInt64;
    CreateTime: TLargeInteger;
    UserTime: UInt64;
    KernelTime: UInt64;
    ImageName: TNtUnicodeString;
    BasePriority: Cardinal;
    ProcessID: TProcessId;
    InheritedFromProcessId: TProcessId;
    HandleCount: Cardinal;
    SessionID: TSessionId;
    UniqueProcessKey: NativeUInt; // SystemExtendedProcessInformation
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
    PrivatePageCount: NativeUInt;
    ReadOperationCount: UInt64;
    WriteOperationCount: UInt64;
    OtherOperationCount: UInt64;
    ReadTransferCount: UInt64;
    WriteTransferCount: UInt64;
    OtherTransferCount: UInt64;
    function GetImageName: String;
  end;
  PSystemProcessInformationFixed = ^TSystemProcessInformationFixed;

  // TSystemProcessInformation
  TSystemProcessInformation = record
    [Aggregate] Process: TSystemProcessInformationFixed;
    Threads: TAnysizeArray<TSystemThreadInformation>;
  end;
  PSystemProcessInformation = ^TSystemProcessInformation;

  // SystemSessionProcessInformation
  TSystemSessionProcessInformation = record
    SessionId: TSessionId;
    [Bytes] SizeOfBuf: Cardinal;
    Buffer: PSystemProcessInformation;
  end;
  PSystemSessionProcessInformation = ^TSystemSessionProcessInformation;

  TSystemThreadInformationExtension = record
    StackBase: Pointer;
    StackLimit: Pointer;
    Win32StartAddress: Pointer;
    [DontFollow] TebBase: PTeb;
  end;

  TSystemExtendedThreadInformation = record
    [Aggregate] ThreadInfo: TSystemThreadInformation;
    [Aggregate] Extension: TSystemThreadInformationExtension;
    [Unlisted] Reserved: array [0..2] of NativeUInt;
  end;
  PSystemExtendedThreadInformation = ^TSystemExtendedThreadInformation;

  // SystemExtendedProcessInformation
  TSystemExtendedProcessInformation = record
    [Aggregate] Process: TSystemProcessInformationFixed;
    Threads: TAnysizeArray<TSystemExtendedThreadInformation>;
  end;
  PSystemExtendedProcessInformation = ^TSystemExtendedProcessInformation;

  TProcessDiskCounters = record
    [Bytes] BytesRead: UInt64;
    [Bytes] BytesWritten: UInt64;
    ReadOperationCount: UInt64;
    WriteOperationCount: UInt64;
    FlushOperationCount: UInt64;
  end;
  PProcessDiskCounters = ^TProcessDiskCounters;

  TProcessEnergyValues = record
    // Note: The structure was different before RS2
    Cycles: array [0..3, 0..1] of UInt64;
    DiskEnergy: UInt64;
    NetworkTailEnergy: UInt64;
    MBBTailEnergy: UInt64;
    [Bytes] NetworkTxRxBytes: UInt64;
    MBBTxRxBytes: UInt64;
    ForegroundDuration: UInt64;
    DesktopVisibleDuration: UInt64;
    PSMForegroundDuration: UInt64;
    CompositionRendered: Cardinal;
    CompositionDirtyGenerated: Cardinal;
    CompositionDirtyPropagated: Cardinal;
    [Reserved] Reserved1: Cardinal;
    AttributedCycles: array [0..3, 0..1] of UInt64;
    WorkOnBehalfCycles: array [0..3, 0..1] of UInt64;
  end;
  PProcessEnergyValues = ^TProcessEnergyValues;

  {$MINENUMSIZE 1}
  [NamingStyle(nsCamelCase, 'SystemProcessClassification')]
  TSystemProcessClassification = (
    SystemProcessClassificationNormal = 0,
    SystemProcessClassificationSystem = 1,
    SystemProcessClassificationSecureSystem = 2,
    SystemProcessClassificationMemCompression = 3,
    SystemProcessClassificationRegistry = 4
  );
  {$MINENUMSIZE 4}

  [FlagName(SYSTEM_PROCESS_HAS_STRONG_ID, 'Has Strong ID')]
  [FlagName(SYSTEM_PROCESS_BACKGROUND_ACTIVITY_MODERATED, 'Background Activity Moderated')]
  TProcessExtFlags = type Cardinal;

  TSystemProcessInformationExtension = record
    DiskCounters: TProcessDiskCounters;
    ContextSwitches: UInt64;
    Flags: TProcessExtFlags;
    [Hex] UserSidOffset: Cardinal;

    [MinOSVersion(OsWin10RS2)] PackageFullNameOffset: Cardinal;
    [MinOSVersion(OsWin10RS2)] EnergyValues: TProcessEnergyValues;
    [MinOSVersion(OsWin10RS2)] AppIDOffset: Cardinal;
    [MinOSVersion(OsWin10RS2)] SharedCommitCharge: NativeUInt;
    [MinOSVersion(OsWin10RS2)] JobObjectID: Cardinal;
    [MinOSVersion(OsWin10RS2), Unlisted] SpareUlong: Cardinal;
    [MinOSVersion(OsWin10RS2)] ProcessSequenceNumber: UInt64;
    function Classification: TSystemProcessClassification;
    function UserSid: PSid;
    function PackageFullName: String;
    function AppId: String;
  end;
  PSystemProcessInformationExtension = ^TSystemProcessInformationExtension;

  TSystemObjectTypeInformation = record
    [Hex, Unlisted] NextEntryOffset: Cardinal;
    NumberOfObjects: Cardinal;
    NumberOfHandles: Cardinal;
    TypeIndex: Cardinal;
    InvalidAttributes: TObjectAttributesFlags;
    GenericMapping: TGenericMapping;
    ValidAccessMask: TAccessMask;
    PoolType: Cardinal;
    SecurityRequired: Boolean;
    WaitableObject: Boolean;
    TypeName: TNtUnicodeString;
  end;
  PSystemObjectTypeInformation = ^TSystemObjectTypeInformation;

  TSystemObjectInformation = record
    [Hex, Unlisted] NextEntryOffset: Cardinal;
    ObjectAddress: Pointer;
    CreatorUniqueProcess: THandle;
    CreatorBackTraceIndex: Word;
    [Hex] Flags: Word;
    PointerCount: Integer;
    HandleCount: Integer;
    [Bytes] PagedPoolCharge: Cardinal;
    [Bytes] NonPagedPoolCharge: Cardinal;
    ExclusiveProcessId: TProcessId;
    SecurityDescriptor: Pointer;
    NameInfo: TNtUnicodeString;
  end;
  PSystemObjectInformation = ^TSystemObjectInformation;

  TSystemHandleTableEntryInfoEx = record
    PObject: Pointer;
    UniqueProcessId: TProcessId;
    HandleValue: NativeUInt;
    GrantedAccess: TAccessMask;
    CreatorBackTraceIndex: Word;
    ObjectTypeIndex: Word;
    HandleAttributes: TObjectAttributesFlags;
    [Reserved] Reserved: Cardinal;
  end;
  PSystemHandleTableEntryInfoEx = ^TSystemHandleTableEntryInfoEx;

  TSystemHandleInformationEx = record
    [Counter] NumberOfHandles: NativeInt;
    [Reserved] Reserved: NativeUInt;
    Handles: TAnysizeArray<TSystemHandleTableEntryInfoEx>;
  end;
  PSystemHandleInformationEx = ^TSystemHandleInformationEx;

  // SystemProcessIdInformation
  TSystemProcessIdInformation = record
    ProcessID: TProcessId;     // in
    ImageName: TNtUnicodeString; // inout
  end;
  PSystemProcessIdInformation = ^TSystemProcessIdInformation;

// Thread execution

function NtDelayExecution(
  Alertable: Boolean;
  [in, opt] DelayInterval: PLargeInteger
): NTSTATUS; stdcall; external ntdll;

// Event

function NtCreateEvent(
  out EventHandle: THandle;
  DesiredAccess: TEventAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  EventType: TEventType;
  InitialState: Boolean
): NTSTATUS; stdcall; external ntdll;

function NtOpenEvent(
  out EventHandle: THandle;
  DesiredAccess: TEventAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

function NtSetEvent(
  EventHandle: THandle;
  [out, opt] PreviousState: PLongBool
): NTSTATUS; stdcall; external ntdll;

function  NtSetEventBoostPriority(
  EventHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtClearEvent(
  EventHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtResetEvent(
  EventHandle: THandle;
  [out, opt] PreviousState: PLongBool
): NTSTATUS; stdcall; external ntdll;

function NtPulseEvent(
  EventHandle: THandle;
  [out, opt] PreviousState: PLongBool
): NTSTATUS; stdcall; external ntdll;

function NtQueryEvent(
  EventHandle: THandle;
  EventInformationClass: TEventInformationClass;
  [out] EventInformation: Pointer;
  EventInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Mutant

function NtCreateMutant(
  out MutantHandle: THandle;
  DesiredAccess: TMutantAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  InitialOwner: Boolean
): NTSTATUS; stdcall; external ntdll;

function NtOpenMutant(
  out MutantHandle: THandle;
  DesiredAccess: TMutantAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

function NtReleaseMutant(
  MutantHandle: THandle;
  [out, opt] PreviousCount: PCardinal
): NTSTATUS; stdcall; external ntdll;

function NtQueryMutant(
  MutantHandle: THandle;
  MutantInformationClass: TMutantInformationClass;
  [out] MutantInformation: Pointer;
  MutantInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Semaphore

function NtCreateSemaphore(
  out SemaphoreHandle: THandle;
  DesiredAccess: TSemaphoreAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  InitialCount: Integer;
  MaximumCount: Integer
): NTSTATUS; stdcall; external ntdll;

function NtOpenSemaphore(
  out SemaphoreHandle: THandle;
  DesiredAccess: TSemaphoreAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

function NtReleaseSemaphore(
  SemaphoreHandle: THandle;
  ReleaseCount: Cardinal;
  [out, opt] PreviousCount: PCardinal
): NTSTATUS; stdcall; external ntdll;

function NtQuerySemaphore(
  SemaphoreHandle: THandle;
  SemaphoreInformationClass: TSemaphoreInformationClass;
  [out] SemaphoreInformation: Pointer;
  SemaphoreInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Timer

// ntddk.15565
function NtCreateTimer(
  out TimerHandle: THandle;
  DesiredAccess: TTimerAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  TimerType: TTimerType
): NTSTATUS; stdcall; external ntdll;

// ntddk.15576
function NtOpenTimer(
  out TimerHandle: THandle;
  DesiredAccess: TTimerAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// ntddk.15595
function NtSetTimer(
  TimerHandle: THandle;
  DueTime: PLargeInteger;
  [in, opt] TimerApcRoutine: TTimerApcRoutine;
  [in, opt] TimerContext: Pointer;
  ResumeTimer: Boolean;
  Period: Integer;
  [out, opt] PreviousState: PBoolean
): NTSTATUS; stdcall; external ntdll;

// ntddk.15609
function NtSetTimerEx(
  TimerHandle: THandle;
  TimerSetInformationClass: TTimerSetInformationClass;
  [in] TimerSetInformation: Pointer;
  TimerSetInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// ntddk.15586
function NtCancelTimer(
  TimerHandle: THandle;
  [out, opt] CurrentState: PBoolean
): NTSTATUS; stdcall; external ntdll;

function NtQueryTimer(
  TimerHandle: THandle;
  TimerInformationClass: TTimerInformationClass;
  [out] TimerInformation: Pointer;
  TimerInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Time

function NtQueryTimerResolution(
  out MaximumTime: Cardinal;
  out MinimumTime: Cardinal;
  out CurrentTime: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtSetTimerResolution(
  DesiredTime: Cardinal;
  SetResolution: Boolean;
  out ActualTime: Cardinal
): NTSTATUS; stdcall; external ntdll;

// LUIDs

// ntddk.15678
function NtAllocateLocallyUniqueId(
  out Luid: TLuid
): NTSTATUS; stdcall; external ntdll;

// System Information

function NtQuerySystemInformation(
  SystemInformationClass: TSystemInformationClass;
  [out] SystemInformation: Pointer;
  SystemInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

implementation

{ TSystemProcessInformationFixed }

function TSystemProcessInformationFixed.GetImageName;
begin
  if not Assigned(@Self) then
    Result := 'Unknown process'
  else
  begin
    Result := ImageName.ToString;
    if Result = '' then
      Result := 'System Idle Process';
  end;
end;

{ TSyetemProcessInformationExtension }

function TSystemProcessInformationExtension.AppId;
begin
  if AppIdOffset <> 0 then
    Result := String(PWideChar(NativeUInt(@Self) + AppIdOffset))
  else
    Result := '';
end;

function TSystemProcessInformationExtension.Classification;
begin
  Result := TSystemProcessClassification((Flags shr 1) and $0F);
end;

function TSystemProcessInformationExtension.PackageFullName;
begin
  if PackageFullNameOffset <> 0 then
    Result := String(PWideChar(NativeUInt(@Self) + PackageFullNameOffset))
  else
    Result := '';
end;

function TSystemProcessInformationExtension.UserSid;
begin
  Result := PSid(NativeUInt(@Self) + UserSidOffset);
end;

end.
