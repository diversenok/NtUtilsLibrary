unit Ntapi.ntexapi;

{
  This file includes definitions for working with kernel synchronization objects
  and retrieving system information via Native API.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.Versions,
  DelphiApi.Reflection;

const
  // WDK::wdm.h - event access masks
  EVENT_QUERY_STATE = $0001;
  EVENT_MODIFY_STATE = $0002;
  EVENT_ALL_ACCESS = STANDARD_RIGHTS_ALL or $0003;

  // SDK::winnt.h - mutant access masks
  MUTANT_QUERY_STATE = $0001;
  MUTANT_ALL_ACCESS = STANDARD_RIGHTS_ALL or MUTANT_QUERY_STATE;

  // WDK::wdm.h - semaphore access masks
  SEMAPHORE_QUERY_STATE = $0001;
  SEMAPHORE_MODIFY_STATE = $0002;
  SEMAPHORE_ALL_ACCESS = STANDARD_RIGHTS_ALL or $0003;

  // SDK::winnt.h - timer access masks
  TIMER_QUERY_STATE = $0001;
  TIMER_MODIFY_STATE = $0002;
  TIMER_ALL_ACCESS = STANDARD_RIGHTS_ALL or $0003;

  // PHNT::ntexapi.h - profile access masks
  PROFILE_CONTROL = $0001;
  PROFILE_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or PROFILE_CONTROL;

  // PHNT::ntexapi.h - keyed event access masks
  KEYEDEVENT_WAIT = $0001;
  KEYEDEVENT_WAKE = $0002;
  KEYEDEVENT_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $03;

  // System

  // PHNT::ntexapi.h - flags for extended process information
  SYSTEM_PROCESS_HAS_STRONG_ID = $0001;
  SYSTEM_PROCESS_BACKGROUND_ACTIVITY_MODERATED = $0004;
  SYSTEM_PROCESS_VALID_MASK = $FFFFFFE1;

  // Global flags

  // PHNT::ntexapi.h - global flags
  FLG_MAINTAIN_OBJECT_TYPELIST = $4000; // kernel

type
  [FriendlyName('event'), ValidBits(EVENT_ALL_ACCESS)]
  [SubEnum(EVENT_ALL_ACCESS, EVENT_ALL_ACCESS, 'Full Access')]
  [FlagName(EVENT_QUERY_STATE, 'Query State')]
  [FlagName(EVENT_MODIFY_STATE, 'Modify State')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TEventAccessMask = type TAccessMask;

  [FriendlyName('mutex'), ValidBits(MUTANT_ALL_ACCESS)]
  [SubEnum(MUTANT_ALL_ACCESS, MUTANT_ALL_ACCESS, 'Full Access')]
  [FlagName(MUTANT_QUERY_STATE, 'Query State')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TMutantAccessMask = type TAccessMask;

  [FriendlyName('semaphore'), ValidBits(SEMAPHORE_ALL_ACCESS)]
  [SubEnum(SEMAPHORE_ALL_ACCESS, SEMAPHORE_ALL_ACCESS, 'Full Access')]
  [FlagName(SEMAPHORE_QUERY_STATE, 'Query State')]
  [FlagName(SEMAPHORE_MODIFY_STATE, 'Modify State')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TSemaphoreAccessMask = type TAccessMask;

  [FriendlyName('timer'), ValidBits(TIMER_ALL_ACCESS)]
  [SubEnum(TIMER_ALL_ACCESS, TIMER_ALL_ACCESS, 'Full Access')]
  [FlagName(TIMER_QUERY_STATE, 'Query State')]
  [FlagName(TIMER_MODIFY_STATE, 'Modify State')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TTimerAccessMask = type TAccessMask;

  [FriendlyName('profile'), ValidBits(PROFILE_ALL_ACCESS)]
  [SubEnum(PROFILE_ALL_ACCESS, PROFILE_ALL_ACCESS, 'Full Access')]
  [FlagName(PROFILE_CONTROL, 'Control')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TProfileAccessMask = type TAccessMask;

  [FriendlyName('keyed event'), ValidBits(KEYEDEVENT_ALL_ACCESS)]
  [SubEnum(KEYEDEVENT_ALL_ACCESS, KEYEDEVENT_ALL_ACCESS, 'Full Access')]
  [FlagName(KEYEDEVENT_WAIT, 'Wait')]
  [FlagName(KEYEDEVENT_WAKE, 'Wake')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TKeyedEventAccessMask = type TAccessMask;

  // Event

  // PHNT::ntexapi.h
  [SDKName('EVENT_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Event')]
  TEventInformationClass = (
    EventBasicInformation = 0 // q: TEventBasicInformation
  );

  // PHNT::ntexapi.h
  [SDKName('EVENT_BASIC_INFORMATION')]
  TEventBasicInformation = record
    EventType: TEventType;
    EventState: Integer;
  end;
  PEventBasicInformation = ^TEventBasicInformation;

  // Mutant

  // PHNT::ntexapi.h
  [SDKName('MUTANT_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Mutant')]
  TMutantInformationClass = (
    MutantBasicInformation = 0, // q: TMutantBasicInformation
    MutantOwnerInformation = 1  // q: TClientId
  );

  // PHNT::ntexapi.h
  [SDKName('MUTANT_BASIC_INFORMATION')]
  TMutantBasicInformation = record
    CurrentCount: Integer;
    OwnedByCaller: Boolean;
    AbandonedState: Boolean;
  end;
  PMutantBasicInformation = ^TMutantBasicInformation;

  // Semaphore

  // PHNT::ntexapi.h
  [SDKName('SEMAPHORE_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Semaphore')]
  TSemaphoreInformationClass = (
    SemaphoreBasicInformation = 0 // q: TSemaphoreBasicInformation
  );

  // PHNT::ntexapi.h
  [SDKName('SEMAPHORE_BASIC_INFORMATION')]
  TSemaphoreBasicInformation = record
    CurrentCount: Integer;
    MaximumCount: Integer;
  end;
  PSemaphoreBasicInformation = ^TSemaphoreBasicInformation;

  // Timer

  // PHNT::ntexapi.h
  [SDKName('TIMER_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Timer')]
  TTimerInformationClass = (
    TimerBasicInformation = 0 // q: TTimerBasicInformation
  );

  // PHNT::ntexapi.h
  [SDKName('TIMER_BASIC_INFORMATION')]
  TTimerBasicInformation = record
    RemainingTime: TLargeInteger;
    TimerState: Boolean;
  end;
  PTimerBasicInformation = ^TTimerBasicInformation;

  // WDK::ntddk.h
  [SDKName('PTIMER_APC_ROUTINE')]
  TTimerApcRoutine = procedure(
    [in] TimerContext: Pointer;
    [in] TimerLowValue: Cardinal;
    [in] TimerHighValue: Integer
  ); stdcall;

  // WDK::ntddk.h
  [SDKName('TIMER_SET_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Timer')]
  TTimerSetInformationClass = (
    TimerSetCoalescableTimer = 0 // s: TTimerSetCoalescableTimerInfo
  );

  // WDK::ntddk.h
  [SDKName('TIMER_SET_COALESCABLE_TIMER_INFO')]
  TTimerSetCoalescableTimerInfo = record
    [in] DueTime: TLargeInteger;
    [in, opt] TimerApcRoutine: TTimerApcRoutine;
    [in, opt] TimerContext: Pointer;
    [in, opt] WakeContext: Pointer;
    [in, opt] Period: Cardinal;
    [in] TolerableDelay: Cardinal;
    [out, opt] PreviousState: PBoolean;
  end;
  PTimerSetCoalescableTimerInfo = ^TTimerSetCoalescableTimerInfo;

  // System Information

  // PHNT::ntexapi & partially SDK::winternl.h
  [SDKName('SYSTEM_INFORMATION_CLASS')]
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

  // PHNT::ntexapi.h - info class 0
  [SDKName('SYSTEM_BASIC_INFORMATION')]
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

  // WDK::ksarm.h
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

  // WDK::wdm.h
  {$SCOPEDENUMS ON}
  [SDKName('KWAIT_REASON')]
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

  // PHNT::ntexapi.h
  [SDKName('SYSTEM_THREAD_INFORMATION')]
  TSystemThreadInformation = record
    KernelTime: TLargeInteger;
    UserTime: TLargeInteger;
    CreateTime: TLargeInteger;
    WaitTime: Cardinal;
    StartAddress: Pointer;
    ClientID: TClientId;
    Priority: TPriority;
    BasePriority: TPriority;
    ContextSwitches: Cardinal;
    ThreadState: TThreadState;
    WaitReason: TWaitReason;
  end;
  PSystemThreadInformation = ^TSystemThreadInformation;

  // PHNT::ntexapi.h
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

  // PHNT::ntexapi.h - info class 5
  [SDKName('SYSTEM_PROCESS_INFORMATION')]
  TSystemProcessInformation = record
    [Aggregate] Process: TSystemProcessInformationFixed;
    Threads: TAnysizeArray<TSystemThreadInformation>;
  end;
  PSystemProcessInformation = ^TSystemProcessInformation;

  // PHNT::ntexapi.h - info class 53
  [SDKName('SYSTEM_SESSION_PROCESS_INFORMATION')]
  TSystemSessionProcessInformation = record
    SessionId: TSessionId;
    [Bytes] SizeOfBuf: Cardinal;
    Buffer: PSystemProcessInformation;
  end;
  PSystemSessionProcessInformation = ^TSystemSessionProcessInformation;

  // PHNT::ntexapi.h
  TSystemThreadInformationExtension = record
    StackBase: Pointer;
    StackLimit: Pointer;
    Win32StartAddress: Pointer;
    [DontFollow] TebBase: PTeb;
  end;

  // PHNT::ntexapi.h
  [SDKName('SYSTEM_EXTENDED_THREAD_INFORMATION')]
  TSystemExtendedThreadInformation = record
    [Aggregate] ThreadInfo: TSystemThreadInformation;
    [Aggregate] Extension: TSystemThreadInformationExtension;
    [Unlisted] Reserved: array [0..2] of NativeUInt;
  end;
  PSystemExtendedThreadInformation = ^TSystemExtendedThreadInformation;

  // PHNT::ntexapi.h - info class 57
  TSystemExtendedProcessInformation = record
    [Aggregate] Process: TSystemProcessInformationFixed;
    Threads: TAnysizeArray<TSystemExtendedThreadInformation>;
  end;
  PSystemExtendedProcessInformation = ^TSystemExtendedProcessInformation;

  // PHNT::ntexapi.h
  [SDKName('PROCESS_DISK_COUNTERS')]
  TProcessDiskCounters = record
    [Bytes] BytesRead: UInt64;
    [Bytes] BytesWritten: UInt64;
    ReadOperationCount: UInt64;
    WriteOperationCount: UInt64;
    FlushOperationCount: UInt64;
  end;
  PProcessDiskCounters = ^TProcessDiskCounters;

  // PHNT::ntexapi.h
  [MinOSVersion(OsWin10RS2)] // The structure was different before RS2
  [SDKName('PROCESS_ENERGY_VALUES')]
  TProcessEnergyValues = record
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

  // PHNT::ntexapi.h
  {$MINENUMSIZE 1}
  [SDKName('SYSTEM_PROCESS_CLASSIFICATION')]
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

  // PHNT::ntexapi.h - info class 148
  [SDKName('SYSTEM_PROCESS_INFORMATION_EXTENSION')]
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

  // PHNT::ntexapi.h - info class 17
  [SDKName('SYSTEM_OBJECTTYPE_INFORMATION')]
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

  // PHNT::ntexapi.h - info class 17
  [SDKName('SYSTEM_OBJECT_INFORMATION')]
  TSystemObjectInformation = record
    [Hex, Unlisted] NextEntryOffset: Cardinal;
    ObjectAddress: Pointer;
    CreatorUniqueProcess: TProcessId;
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

  // PHNT::ntexapi.h
  [SDKName('SYSTEM_HANDLE_TABLE_ENTRY_INFO_EX')]
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

  // PHNT::ntexapi.h - info class 64
  [SDKName('SYSTEM_HANDLE_INFORMATION_EX')]
  TSystemHandleInformationEx = record
    [Counter] NumberOfHandles: NativeInt;
    [Reserved] Reserved: NativeUInt;
    Handles: TAnysizeArray<TSystemHandleTableEntryInfoEx>;
  end;
  PSystemHandleInformationEx = ^TSystemHandleInformationEx;

  // PHNT::ntexapi.h - info class 88
  [SDKName('SYSTEM_PROCESS_ID_INFORMATION')]
  TSystemProcessIdInformation = record
    [in] ProcessID: TProcessId;
    [in, out] ImageName: TNtUnicodeString;
  end;
  PSystemProcessIdInformation = ^TSystemProcessIdInformation;

// Thread execution

// PHNT::ntexapi.h
function NtDelayExecution(
  [in] Alertable: Boolean;
  [in] DelayInterval: PLargeInteger
): NTSTATUS; stdcall; external ntdll;

// Event

// WDK::ntifs.h
function NtCreateEvent(
  [out, ReleaseWith('NtClose')] out EventHandle: THandle;
  [in] DesiredAccess: TEventAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] EventType: TEventType;
  [in] InitialState: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtOpenEvent(
  [out, ReleaseWith('NtClose')] out EventHandle: THandle;
  [in] DesiredAccess: TEventAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtSetEvent(
  [in, Access(EVENT_MODIFY_STATE)] EventHandle: THandle;
  [out, opt] PreviousState: PLongBool
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtSetEventBoostPriority(
  [in, Access(EVENT_MODIFY_STATE)] EventHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtClearEvent(
  [in, Access(EVENT_MODIFY_STATE)] EventHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtResetEvent(
  [in, Access(EVENT_MODIFY_STATE)] EventHandle: THandle;
  [out, opt] PreviousState: PLongBool
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtPulseEvent(
  [in, Access(EVENT_MODIFY_STATE)] EventHandle: THandle;
  [out, opt] PreviousState: PLongBool
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtQueryEvent(
  [in, Access(EVENT_QUERY_STATE)] EventHandle: THandle;
  [in] EventInformationClass: TEventInformationClass;
  [out, WritesTo] EventInformation: Pointer;
  [in, NumberOfBytes] EventInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Mutant

// PHNT::ntexapi.h
function NtCreateMutant(
  [out, ReleaseWith('NtClose')] out MutantHandle: THandle;
  [in] DesiredAccess: TMutantAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] InitialOwner: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtOpenMutant(
  [out, ReleaseWith('NtClose')] out MutantHandle: THandle;
  [in] DesiredAccess: TMutantAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtReleaseMutant(
  [in, Access(0)] MutantHandle: THandle;
  [out, opt] PreviousCount: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtQueryMutant(
  [in, Access(MUTANT_QUERY_STATE)] MutantHandle: THandle;
  [in] MutantInformationClass: TMutantInformationClass;
  [out, WritesTo] MutantInformation: Pointer;
  [in, NumberOfBytes] MutantInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Semaphore

// PHNT::ntexapi.h
function NtCreateSemaphore(
  [out, ReleaseWith('NtClose')] out SemaphoreHandle: THandle;
  [in] DesiredAccess: TSemaphoreAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] InitialCount: Integer;
  [in] MaximumCount: Integer
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtOpenSemaphore(
  [out, ReleaseWith('NtClose')] out SemaphoreHandle: THandle;
  [in] DesiredAccess: TSemaphoreAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtReleaseSemaphore(
  [in, Access(SEMAPHORE_MODIFY_STATE)] SemaphoreHandle: THandle;
  [in] ReleaseCount: Cardinal;
  [out, opt] PreviousCount: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtQuerySemaphore(
  [in, Access(SEMAPHORE_QUERY_STATE)] SemaphoreHandle: THandle;
  [in] SemaphoreInformationClass: TSemaphoreInformationClass;
  [out, WritesTo] SemaphoreInformation: Pointer;
  [in, NumberOfBytes] SemaphoreInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Timer

// WDK::ntddk.h
function NtCreateTimer(
  [out, ReleaseWith('NtClose')] out TimerHandle: THandle;
  [in] DesiredAccess: TTimerAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] TimerType: TTimerType
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
function NtOpenTimer(
  [out, ReleaseWith('NtClose')] out TimerHandle: THandle;
  [in] DesiredAccess: TTimerAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
function NtSetTimer(
  [in, Access(TIMER_MODIFY_STATE)] TimerHandle: THandle;
  [in] const [ref] DueTime: TLargeInteger;
  [in, opt] TimerApcRoutine: TTimerApcRoutine;
  [in, opt] TimerContext: Pointer;
  [in] ResumeTimer: Boolean;
  [in, opt] Period: Integer;
  [out, opt] PreviousState: PBoolean
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
function NtSetTimerEx(
  [in, Access(TIMER_MODIFY_STATE)] TimerHandle: THandle;
  [in] TimerSetInformationClass: TTimerSetInformationClass;
  [in, ReadsFrom] TimerSetInformation: Pointer;
  [in, NumberOfBytes] TimerSetInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
function NtCancelTimer(
  [in, Access(TIMER_MODIFY_STATE)] TimerHandle: THandle;
  [out, opt] CurrentState: PBoolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtQueryTimer(
  [in, Access(TIMER_QUERY_STATE)] TimerHandle: THandle;
  [in] TimerInformationClass: TTimerInformationClass;
  [out, WritesTo] TimerInformation: Pointer;
  [in, NumberOfBytes] TimerInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Keyed Events

// PHNT::ntexapi.h
function NtCreateKeyedEvent(
  [out, ReleaseWith('NtClose')] out KeyedEventHandle: THandle;
  [in] DesiredAccess: TKeyedEventAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [Reserved] Flags: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtOpenKeyedEvent(
  [out, ReleaseWith('NtClose')] out KeyedEventHandle: THandle;
  [in] DesiredAccess: TKeyedEventAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtReleaseKeyedEvent(
  [in, Access(KEYEDEVENT_WAKE)] KeyedEventHandle: THandle;
  [in] KeyValue: NativeUInt;
  [in] Alertable: Boolean;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtWaitForKeyedEvent(
  [in, Access(KEYEDEVENT_WAIT)] KeyedEventHandle: THandle;
  [in] KeyValue: NativeUInt;
  [in] Alertable: Boolean;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll;

// Time

// SDK::winternl.h
function NtQueryTimerResolution(
  [out] out MaximumTime: Cardinal;
  [out] out MinimumTime: Cardinal;
  [out] out CurrentTime: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtSetTimerResolution(
  [in] DesiredTime: Cardinal;
  [in] SetResolution: Boolean;
  [out] out ActualTime: Cardinal
): NTSTATUS; stdcall; external ntdll;

// LUIDs

// WDK::ntddk.h
function NtAllocateLocallyUniqueId(
  [out] out Luid: TLuid
): NTSTATUS; stdcall; external ntdll;

// System Information

// PHNT::ntexapi.h
function NtQuerySystemInformation(
  [in] SystemInformationClass: TSystemInformationClass;
  [out, WritesTo] SystemInformation: Pointer;
  [in, NumberOfBytes] SystemInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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
    Result := String(PWideChar(UIntPtr(@Self) + PackageFullNameOffset))
  else
    Result := '';
end;

function TSystemProcessInformationExtension.UserSid;
begin
  Result := PSid(UIntPtr(@Self) + UserSidOffset);
end;

end.
