unit Ntapi.ntpebteb;

{
  The file defines the structure of structures Process/Thread Environment Block.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ImageHlp, Ntapi.actctx,
  Ntapi.Versions, DelphiApi.Reflection;

const
  // Extracted from bit union PEB.BitField
  // Note: don't use below 8.1 since the bits were shifted
  PEB_BITS_IMAGE_USES_LARGE_PAGES = $01;
  PEB_BITS_IS_PROTECTED_PROCESS = $02;
  PEB_BITS_IS_IMAGE_DYNAMICALLY_RELOCATED = $04;
  PEB_BITS_SKIP_PATCHING_USER32_FORWARDERS = $08;
  PEB_BITS_IS_PACKAGED_PROCESS = $10;        // Win 8+
  PEB_BITS_IS_APP_CONTAINER = $20;           // Win 8+
  PEB_BITS_IS_PROTECTED_PROCESS_LIGHT = $40; // Win 8.1+
  PEB_BITS_IS_LONG_PATH_AWARE_PROCESS = $80; // Win 10 RS1+

  // Extracted from bit union PEB.CrossProcessFlags
  PEB_CROSS_FLAGS_IN_JOB = $0001;
  PEB_CROSS_FLAGS_INITIALIZING = $0002;
  PEB_CROSS_FLAGS_USING_VEH = $0005;
  PEB_CROSS_FLAGS_USING_VCH = $0008;
  PEB_CROSS_FLAGS_USING_FTH = $0010;
  PEB_CROSS_FLAGS_PREVIOUSLY_THROTTLED = $0020; // Win 10 RS2+
  PEB_CROSS_FLAGS_CURRENTLY_THROTTLED = $0040;  // Win 10 RS2+
  PEB_CROSS_FLAGS_IMAGES_HOT_PATCHED = $0080;   // Win 10 RS5+

  // Extracted from bit union PEB.TracingFlags
  TRACING_FLAGS_HEAP_TRACING_ENABLED = $0001;
  TRACING_FLAGS_CRIT_SEC_TRACING_ENABLED = $0002;
  TRACING_FLAGS_LIB_LOADER_TRACING_ENABLED = $00004; // Win 8+

  // Extracted from bit union TEB.SameTebFlags
  TEB_SAME_FLAGS_SAFE_THUNK_CALL = $0001;
  TEB_SAME_FLAGS_IN_DEBUG_PRINT = $0002;
  TEB_SAME_FLAGS_HAS_FIBER_DATA = $0004;
  TEB_SAME_FLAGS_SKIP_THREAD_ATTACH = $0008;
  TEB_SAME_FLAGS_WER_IN_SHIP_ASSERT_CODE = $0010;
  TEB_SAME_FLAGS_RAN_PROCESS_INIT = $0020;
  TEB_SAME_FLAGS_CLONED_THREAD = $0040;
  TEB_SAME_FLAGS_SUPPRESS_DEBUG_MSG = $0080;
  TEB_SAME_FLAGS_DISABLE_USER_STACK_WALK = $0100;
  TEB_SAME_FLAGS_RTL_EXCEPTION_ATTACHED = $0200;
  TEB_SAME_FLAGS_INITIAL_THREAD = $0400;
  TEB_SAME_FLAGS_SESSION_AWARE = $0800;           // Win 8+
  TEB_SAME_FLAGS_LOAD_OWNER = $1000;              // Win 8.1+
  TEB_SAME_FLAGS_LOADER_WORKER = $2000;           // Win 8.1+
  TEB_SAME_FLAGS_SKIP_LOADER_INIT = $4000;        // Win 10 RS2+
  TEB_SAME_FLAGS_SKIP_FILE_API_BROKERING = $8000; // Win 11+

  // PHNT::ntrtl.h - error mode flags
  RTL_ERRORMODE_FAILCRITICALERRORS = $0010;
  RTL_ERRORMODE_NOGPFAULTERRORBOX = $0020;
  RTL_ERRORMODE_NOOPENFILEERRORBOX = $0040;

  SHARED_GLOBAL_FLAGS_ERROR_PORT = $00000001;
  SHARED_GLOBAL_FLAGS_ELEVATION_ENABLED = $00000002;
  SHARED_GLOBAL_FLAGS_VIRT_ENABLED = $00000004;
  SHARED_GLOBAL_FLAGS_INSTALLER_DETECT_ENABLED = $00000008;
  SHARED_GLOBAL_FLAGS_LKG_ENABLED = $00000010;               // Win 8+
  SHARED_GLOBAL_FLAGS_DYNAMIC_PROC_ENABLED = $00000020;
  SHARED_GLOBAL_FLAGS_CONSOLE_BROKER_ENABLED = $00000040;    // Win 8+
  SHARED_GLOBAL_FLAGS_SECURE_BOOT_ENABLED = $00000080;       // Win 8+
  SHARED_GLOBAL_FLAGS_MULTI_SESSION_SKU = $00000100;         // Win 10 TH1+
  SHARED_GLOBAL_FLAGS_MULTIUSERS_IN_SESSION_SKU = $00000200; // Win 10 RS1+
  SHARED_GLOBAL_FLAGS_STATE_SEPARATION_ENABLED = $00000400;  // Win 10 RS3+

type
  { PEB }

  [MinOSVersion(OsWin81)] // The bits were shifted below 8.1
  [FlagName(PEB_BITS_IMAGE_USES_LARGE_PAGES, 'Image Uses Large Pages')]
  [FlagName(PEB_BITS_IS_PROTECTED_PROCESS, 'Protected Process')]
  [FlagName(PEB_BITS_IS_IMAGE_DYNAMICALLY_RELOCATED, 'Image Dynamically Relocated')]
  [FlagName(PEB_BITS_SKIP_PATCHING_USER32_FORWARDERS, 'Skip Patching User32 Forwarders')]
  [FlagName(PEB_BITS_IS_PACKAGED_PROCESS, 'Packaged Process')]
  [FlagName(PEB_BITS_IS_APP_CONTAINER, 'AppContainer')]
  [FlagName(PEB_BITS_IS_PROTECTED_PROCESS_LIGHT, 'PPL')]
  [FlagName(PEB_BITS_IS_LONG_PATH_AWARE_PROCESS, 'Long Path Aware')]
  TPebBitField = type Byte;

  [FlagName(PEB_CROSS_FLAGS_IN_JOB, 'In Job')]
  [FlagName(PEB_CROSS_FLAGS_INITIALIZING, 'Initializing')]
  [FlagName(PEB_CROSS_FLAGS_USING_VEH, 'Using VEH')]
  [FlagName(PEB_CROSS_FLAGS_USING_VCH, 'Using VCH')]
  [FlagName(PEB_CROSS_FLAGS_USING_FTH, 'Using FTH')]
  [FlagName(PEB_CROSS_FLAGS_PREVIOUSLY_THROTTLED, 'Previously Throttled')]
  [FlagName(PEB_CROSS_FLAGS_CURRENTLY_THROTTLED, 'Currently Throttled')]
  [FlagName(PEB_CROSS_FLAGS_IMAGES_HOT_PATCHED, 'Images Hot-patched')]
  TPebCrossFlags = type Cardinal;

  // rev
  TKernelCallbackTable = array [0..129] of Pointer;
  PKernelCallbackTable = ^TKernelCallbackTable;

  {$IFDEF Win64}
  TGDIHandleBuffer = array [0..59] of Cardinal;
  {$ELSE}
  TGDIHandleBuffer = array [0..33] of Cardinal;
  {$ENDIF}

  [Hex] TTlsExpansionBitmapBits = array [0..31] of Cardinal;

  [FlagName(TRACING_FLAGS_HEAP_TRACING_ENABLED, 'Heap Tracing')]
  [FlagName(TRACING_FLAGS_CRIT_SEC_TRACING_ENABLED, 'Critical Section Tracing')]
  [FlagName(TRACING_FLAGS_LIB_LOADER_TRACING_ENABLED, 'Loader Tracing')]
  TPebTracingFlags = type Cardinal;

  // PHNT::ntpsapi.h
  [SDKName('PEB_LDR_DATA')]
  TPebLdrData = record
    [Bytes, Unlisted] Length: Cardinal;
    Initialized: Boolean;
    SsHandle: THandle;
    InLoadOrderModuleList: TListEntry;
    InMemoryOrderModuleList: TListEntry;
    InInitializationOrderModuleList: TListEntry;
    EntryInProgress: Pointer;
    ShutdownInProgress: Boolean;
    ShutdownThreadId: NativeUInt;
  end;
  PPebLdrData = ^TPebLdrData;

  // PHNT::ntpebteb.h
  [SDKName('PEB')]
  TPeb = record
    InheritedAddressSpace: Boolean;
    ReadImageFileExecOptions: Boolean;
    BeingDebugged: Boolean;
    [MinOSVersion(OsWin81)] BitField: TPebBitField; // bits were shifted before 8.1
    [Hex] Mutant: THandle;
    ImageBaseAddress: Pointer;
    Ldr: PPebLdrData;
    ProcessParameters: PRtlUserProcessParameters;
    SubSystemData: Pointer;
    ProcessHeap: Pointer;
    FastPebLock: PRtlCriticalSection;
    [volatile] AtlThunkSListPtr: Pointer; // WinNt.PSLIST_HEADER
    IFEOKey: Pointer;
    CrossProcessFlags: TPebCrossFlags;
    KernelCallbackTable: PKernelCallbackTable; // aka UserSharedInfoPtr
    [Hex] SystemReserved: Cardinal;
    [Hex] ATLThunkSListPtr32: Cardinal;
    APISetMap: Pointer; // ntpebteb.PAPI_SET_NAMESPACE
    TLSExpansionCounter: Cardinal;
    TLSBitmap: Pointer; // ntrtl.PRTL_BITMAP
    [Hex] TLSBitmapBits: UInt64;
    ReadOnlySharedMemoryBase: Pointer;
    [MinOSVersion(OsWin10RS2)] SharedData: Pointer;
    ReadOnlyStaticServerData: PPointer;
    AnsiCodePageData: Pointer; // PCPTABLEINFO
    OEMCodePageData: Pointer; // PCPTABLEINFO
    UnicodeCaseTableData: Pointer; // PNLSTABLEINFO
    NumberOfProcessors: Cardinal;
    [Hex] NTGlobalFlag: Cardinal; // TODO: global flags
    CriticalSectionTimeout: TULargeInteger;
    [Bytes] HeapSegmentReserve: NativeUInt;
    [Bytes] HeapSegmentCommit: NativeUInt;
    [Bytes] HeapDecommitTotalFreeThreshold: NativeUInt;
    [Bytes] HeapDecommitFreeBlockThreshold: NativeUInt;
    NumberOfHeaps: Cardinal;
    MaximumNumberOfHeaps: Cardinal;
    ProcessHeaps: PPointer; // PHEAP
    GDISharedHandleTable: Pointer;
    ProcessStarterHelper: Pointer;
    GdiDCAttributeList: Cardinal;
    LoaderLock: PRtlCriticalSection;
    OSMajorVersion: Cardinal;
    OSMinorVersion: Cardinal;
    OSBuildNumber: Word;
    OSCsdVersion: Word;
    OSPlatformID: Cardinal;
    ImageSubsystem: TImageSubsystem;
    ImageSubsystemMajorVersion: Cardinal;
    ImageSubsystemMinorVersion: Cardinal;
    [Hex] ActiveProcessAffinityMask: NativeUInt;
    GDIHandleBuffer: TGDIHandleBuffer;
    PostProcessInitRoutine: Pointer;
    TLSExpansionBitmap: Pointer;
    TLSExpansionBitmapBits: TTlsExpansionBitmapBits;
    SessionID: TSessionId;
    [Hex] AppCompatFlags: UInt64;
    [Hex] AppCompatFlagsUser: UInt64;
    pShimData: Pointer;
    AppCompatInfo: Pointer; // APPCOMPAT_EXE_DATA
    CSDVersion: TNtUnicodeString;
    ActivationContextData: PActivationContextData;
    ProcessAssemblyStorageMap: PAssemblyStorageMap;
    SystemDefaultActivationContextData: PActivationContextData;
    SystemAssemblyStorageMap: PAssemblyStorageMap;
    [Bytes] MinimumStackCommit: NativeUInt;
    [Unlisted] SparePointers: array [0..1] of Pointer;
    [MinOSVersion(OsWin11)] PatchLoaderData: Pointer;
    [MinOSVersion(OsWin11)] ChpeV2ProcessInfo: Pointer;
    [MinOSVersion(OsWin11), Hex] AppModelFeatureState: Cardinal;
    [Unlisted] SpareUlongs: array [0..1] of Cardinal;
    [MinOSVersion(OsWin11)] ActiveCodePage: Word;
    [MinOSVersion(OsWin11)] OEMCodePage: Word;
    [MinOSVersion(OsWin11)] UseCaseMapping: Word;
    WERRegistrationData: Pointer;
    WERShipAssertPtr: Pointer;
    [MinOSVersion(OsWin11)] EcCodeBitmap: Pointer;
    pImageHeaderHash: Pointer;
    TracingFlags: TPebTracingFlags;
    [MinOSVersion(OsWin8), Hex] CSRServerReadOnlySharedMemoryBase: UInt64;
    [MinOSVersion(OsWin10TH2)] TPPWorkerpListLock: PRtlCriticalSection;
    [MinOSVersion(OsWin10TH2)] TPPWorkerpList: TListEntry;
    [MinOSVersion(OsWin10TH2)] WaitOnAddressHashTable: array [0..127] of Pointer;
    [MinOSVersion(OsWin10RS3)] TelemetryCoverageHeader: Pointer;
    [MinOSVersion(OsWin10RS3), Hex] CloudFileFlags: Cardinal;
    [MinOSVersion(OsWin10RS4), Hex] CloudFileDiagFlags: Cardinal;
    [MinOSVersion(OsWin10RS4)] PlaceholderCompatibilityMode: Byte;
    [MinOSVersion(OsWin10RS4)] PlaceholderCompatibilityModeReserved: array [0..6] of Byte;
    [MinOSVersion(OsWin10RS5)] LeapSecondData: Pointer; // *_LEAP_SECOND_DATA
    [MinOSVersion(OsWin10RS5), Hex] LeapSecondFlags: Cardinal;
    [MinOSVersion(OsWin10RS5), Hex] NTGlobalFlag2: Cardinal;
    [MinOSVersion(OsWin11), Hex] ExtendedFeatureDisableMask: Cardinal;
  end;
  PPeb = ^TPeb;

  { TEB }

  [FlagName(TEB_SAME_FLAGS_SAFE_THUNK_CALL, 'Safe Thunk Call')]
  [FlagName(TEB_SAME_FLAGS_IN_DEBUG_PRINT, 'In Debug Print')]
  [FlagName(TEB_SAME_FLAGS_HAS_FIBER_DATA, 'Has Fiber Data')]
  [FlagName(TEB_SAME_FLAGS_SKIP_THREAD_ATTACH, 'Skip Thread Attach')]
  [FlagName(TEB_SAME_FLAGS_WER_IN_SHIP_ASSERT_CODE, 'WER In Ship Assert Code')]
  [FlagName(TEB_SAME_FLAGS_RAN_PROCESS_INIT, 'Ran Process Init')]
  [FlagName(TEB_SAME_FLAGS_CLONED_THREAD, 'Cloned Thread')]
  [FlagName(TEB_SAME_FLAGS_SUPPRESS_DEBUG_MSG, 'Suppress Debug Messages')]
  [FlagName(TEB_SAME_FLAGS_DISABLE_USER_STACK_WALK, 'Disable User Stack Walk')]
  [FlagName(TEB_SAME_FLAGS_RTL_EXCEPTION_ATTACHED, 'RTL Exception Attached')]
  [FlagName(TEB_SAME_FLAGS_INITIAL_THREAD, 'Initial Thread')]
  [FlagName(TEB_SAME_FLAGS_SESSION_AWARE, 'Session Aware')]
  [FlagName(TEB_SAME_FLAGS_LOAD_OWNER, 'Load Owner')]
  [FlagName(TEB_SAME_FLAGS_LOADER_WORKER, 'Load Worker')]
  [FlagName(TEB_SAME_FLAGS_SKIP_LOADER_INIT, 'Skip Loader Init')]
  [FlagName(TEB_SAME_FLAGS_SKIP_FILE_API_BROKERING, 'Skip File API Brokering')]
  TTebSameTebFlags = type Word;

  // PHNT::ntpebteb.h
  [SDKName('GDI_TEB_BATCH')]
  TGdiTebBatch = record
    Offset: Cardinal;
    HDC: NativeUInt;
    Buffer: array [0..309] of Cardinal;
  end;

  [FlagName(RTL_ERRORMODE_FAILCRITICALERRORS, 'Fail Critical Errors')]
  [FlagName(RTL_ERRORMODE_NOGPFAULTERRORBOX, 'No GP Fault Error Box')]
  [FlagName(RTL_ERRORMODE_NOOPENFILEERRORBOX, 'No OpenFile Error Box')]
  TRtlErrorMode = type Cardinal;
  PRtlErrorMode = ^TRtlErrorMode;

  // SDK::winnt.h
  PNtTib = ^TNtTib;
  [SDKName('NT_TIB')]
  TNtTib = record
    ExceptionList: Pointer;
    StackBase: Pointer;
    StackLimit: Pointer;
    SubSystemTib: Pointer;
    FiberData: Pointer;
    ArbitraryUserPointer: Pointer;
    Self: PNtTib;
  end;

  // PHNT::ntpebteb.h
  [SDKName('TEB')]
  TTeb = record
    NtTib: TNtTib;
    EnvironmentPointer: Pointer;
    ClientID: TClientId;
    ActiveRpcHandle: Pointer;
    ThreadLocalStoragePointer: Pointer;
    ProcessEnvironmentBlock: PPeb;
    LastErrorValue: TWin32Error;
    CountOfOwnedCriticalSections: Cardinal;
    CSRClientThread: Pointer;
    Win32ThreadInfo: Pointer;
    User32Reserved: array [0..25] of Cardinal;
    UserReserved: array [0..4] of Cardinal;
    WOW32Reserved: Pointer;
    CurrentLocale: Cardinal;
    FpSoftwareStatusRegister: Cardinal;
    [MinOSVersion(OsWin10TH1)] ReservedForDebuggerInstrumentation: array [0..15] of Pointer;
  {$IFDEF WIN64}
    [Unlisted] SystemReserved1: array [0..29] of Pointer;
  {$ELSE}
    [Unlisted] SystemReserved1: array [0..25] of Pointer;
  {$ENDIF}
    [MinOSVersion(OsWin10RS3)] PlaceholderCompatibilityMode: ShortInt;
    [MinOSVersion(OsWin10RS5)] PlaceholderHydrationAlwaysExplicit: Byte;
    [MinOSVersion(OsWin10RS5), Unlisted] PlaceholderReserved: array [0..9] of ShortInt;
    [MinOSVersion(OsWin10RS3)] ProxiedProcessID: TProcessId32;
    [MinOSVersion(OsWin10RS2)] ActivationStack: TActivationContextStack;
    [MinOSVersion(OsWin10RS1)] WorkingOnBehalfTicket: array [0..7] of Byte;
    ExceptionCode: Cardinal;
    ActivationContextStackPointer: PActivationContextStack;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackSp: NativeUInt;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousPc: NativeUInt;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousSp: NativeUInt;
  {$IFDEF WIN64}
    [Hex] TxFsContext: Cardinal;
    [MinOSVersion(OsWin10TH1)] InstrumentationCallbackDisabled: Boolean;
    [MinOSVersion(OsWin10RS5)] UnalignedLoadStoreExceptions: Boolean;
  {$ELSE}
    [MinOSVersion(OsWin10TH1)] InstrumentationCallbackDisabled: Boolean;
    [Unlisted] SpareBytes: array [0..22] of Byte;
    [Hex] TxFsContext: Cardinal;
  {$ENDIF}
    GDITebBatch: TGdiTebBatch;
    RealClientID: TClientId;
    GDICachedProcessHandle: THandle;
    GDIClientPID: TProcessId32;
    GDIClientTID: TThreadId32;
    GDIThreadLocalInfo: Pointer;
    Win32ClientInfo: array [0..61] of NativeUInt;
    glDispatchTable: array [0..232] of Pointer;
    glReserved1: array [0..28] of NativeUInt;
    glReserved2: Pointer;
    glSectionInfo: Pointer;
    glSection: Pointer;
    glTable: Pointer;
    glCurrentRC: Pointer;
    glContext: Pointer;
    LastStatusValue: NTSTATUS;
    StaticUnicodeString: TNtUnicodeString;
    StaticUnicodeBuffer: array [0..MAX_PATH] of WideChar;
    DeallocationStack: Pointer;
    TLSSlots: array [0..63] of Pointer;
    TLSLinks: TListEntry;
    VDM: Pointer;
    ReservedForNtRPC: Pointer;
    DbgSsReserved: array [0..1] of Pointer;
    HardErrorMode: TRtlErrorMode;
  {$IFDEF WIN64}
    Instrumentation: array [0..10] of Pointer;
  {$ELSE}
    Instrumentation: array [0..8] of Pointer;
  {$ENDIF}
    ActivityID: TGuid;
    SubProcessTag: Pointer;
    [MinOSVersion(OsWin8)] PerflibData: Pointer;
    ETWTraceData: Pointer;
    WinSockData: Pointer;
    GDIBatchCount: Cardinal;
    [Hex] IdealProcessorValue: Cardinal; // aka CurrentIdealProcessor
    GuaranteedStackBytes: Cardinal;
    ReservedForPerf: Pointer;
    ReservedForOLE: Pointer;
    WaitingOnLoaderLock: Cardinal;
    SavedPriorityState: Pointer;
    [MinOSVersion(OsWin8)] ReservedForCodeCoverage: NativeUInt;
    ThreadPoolData: Pointer;
    TLSExpansionSlots: PPointer;
  {$IFDEF WIN64}
    [MinOSVersion(OsWin11)] ChpeV2CpuAreaInfo: Pointer;
    [MinOSVersion(OsWin11), Unlisted] Unused: Pointer;
  {$ENDIF}
    MUIGeneration: Cardinal;
    IsImpersonating: LongBool;
    NlsCache: Pointer;
    pShimData: Pointer;
    [MinOSVersion(OsWin10RS5), Hex] HeapData: Cardinal;
    CurrentTransactionHandle: THandle;
    ActiveFrame: Pointer;
    FlsData: Pointer;
    PreferredLanguages: Pointer;
    UserPrefLanguages: Pointer;
    MergedPrefLanguages: Pointer;
    MUIImpersonation: Cardinal;
    [Hex, Reserved] CrossTebFlags: Word;
    SameTebFlags: TTebSameTebFlags;
    TxnScopeEnterCallback: Pointer;
    TxnScopeExitCallback: Pointer;
    TxnScopeContext: Pointer;
    LockCount: Cardinal;
    WowTebOffset: Integer;
    ResourceRetValue: Pointer;
    [MinOSVersion(OsWin8)] ReservedForWDF: Pointer;
    [MinOSVersion(OsWin10TH1)] ReservedForCRT: UInt64;
    [MinOSVersion(OsWin10TH1)] EffectiveContainerID: TGuid;
    [MinOSVersion(OsWin11)] LastSleepCounter: UInt64;
    [MinOSVersion(OsWin11)] SpinCallCount: Cardinal;
    [MinOSVersion(OsWin11), Hex] ExtendedFeatureDisableMask: Cardinal;
  end;
  PTeb = ^TTeb;

  { KUSER_SHARED_DATA }

  [FlagName(SHARED_GLOBAL_FLAGS_ERROR_PORT, 'Error Port')]
  [FlagName(SHARED_GLOBAL_FLAGS_ELEVATION_ENABLED, 'Elevation Enabled')]
  [FlagName(SHARED_GLOBAL_FLAGS_VIRT_ENABLED, 'Virtualization Enabled')]
  [FlagName(SHARED_GLOBAL_FLAGS_INSTALLER_DETECT_ENABLED, 'Installer Detect Enabled')]
  [FlagName(SHARED_GLOBAL_FLAGS_LKG_ENABLED, 'LKG Enabled')]
  [FlagName(SHARED_GLOBAL_FLAGS_DYNAMIC_PROC_ENABLED, 'Dynamic Processors Enabled')]
  [FlagName(SHARED_GLOBAL_FLAGS_CONSOLE_BROKER_ENABLED, 'Console Broker Enabled')]
  [FlagName(SHARED_GLOBAL_FLAGS_SECURE_BOOT_ENABLED, 'Secure Boot Enabled')]
  [FlagName(SHARED_GLOBAL_FLAGS_MULTI_SESSION_SKU, 'Multi-Session SKU')]
  [FlagName(SHARED_GLOBAL_FLAGS_MULTIUSERS_IN_SESSION_SKU, 'Multi-Users in Session SKU')]
  [FlagName(SHARED_GLOBAL_FLAGS_STATE_SEPARATION_ENABLED, 'State Separation Enabled')]
  TSharedGlobalFlags = type Cardinal;

  // WDK::wdm.h
  [SDKName('KSYSTEM_TIME')]
  KSystemTime = packed record
  case Boolean of
    True: (
     QuadPart: TLargeInteger
    );
    False: (
      LowPart: Cardinal;
      High1Time: Integer;
      High2Time: Integer;
    );
  end;

  // WDK::ntdef.h
  [SDKName('NT_PRODUCT_TYPE')]
  [NamingStyle(nsCamelCase, 'NtProduct'), Range(1)]
  TNtProductType = (
    NtProductUnknown = 0,
    NtProductWinNT = 1,
    NtProductLanManNT = 2,
    NtProductServer = 3
  );

  // WDK::ntddk.h
  [NamingStyle(nsSnakeCase, 'SYSTEM_CALL')]
  TSystemCall = (
    SYSTEM_CALL_SYSCALL = 0,
    SYSTEM_CALL_INT_2E = 1
  );

  TNtSystemRoot = array [MAX_PATH_ARRAY] of WideChar;

  // SDK::winnt.h
  [NamingStyle(nsSnakeCase, 'PF'), Range(0, 44)]
  TProcessorFeature = (
    PF_FLOATING_POINT_PRECISION_ERRATA = 0,
    PF_FLOATING_POINT_EMULATED = 1,
    PF_COMPARE_EXCHANGE_DOUBLE = 2,
    PF_MMX_INSTRUCTIONS_AVAILABLE = 3,
    PF_PPC_MOVEMEM_64BIT_OK = 4,
    PF_ALPHA_BYTE_INSTRUCTIONS = 5,
    PF_XMMI_INSTRUCTIONS_AVAILABLE = 6,
    PF_3DNOW_INSTRUCTIONS_AVAILABLE = 7,
    PF_RDTSC_INSTRUCTION_AVAILABLE = 8,
    PF_PAE_ENABLED = 9,
    PF_XMMI64_INSTRUCTIONS_AVAILABLE = 10,
    PF_SSE_DAZ_MODE_AVAILABLE = 11,
    PF_NX_ENABLED = 12,
    PF_SSE3_INSTRUCTIONS_AVAILABLE = 13,
    PF_COMPARE_EXCHANGE128 = 14,
    PF_COMPARE64_EXCHANGE128 = 15,
    PF_CHANNELS_ENABLED = 16,
    PF_XSAVE_ENABLED = 17,
    PF_ARM_VFP_32_REGISTERS_AVAILABLE = 18,
    PF_ARM_NEON_INSTRUCTIONS_AVAILABLE = 19,
    PF_SECOND_LEVEL_ADDRESS_TRANSLATION = 20,
    PF_VIRT_FIRMWARE_ENABLED = 21,
    PF_RDWRFSGSBASE_AVAILABLE = 22,
    PF_FASTFAIL_AVAILABLE = 23,
    PF_ARM_DIVIDE_INSTRUCTION_AVAILABLE = 24,
    PF_ARM_64BIT_LOADSTORE_ATOMIC = 25,
    PF_ARM_EXTERNAL_CACHE_AVAILABLE = 26,
    PF_ARM_FMAC_INSTRUCTIONS_AVAILABLE = 27,
    PF_RDRAND_INSTRUCTION_AVAILABLE = 28,
    PF_ARM_V8_INSTRUCTIONS_AVAILABLE = 29,
    PF_ARM_V8_CRYPTO_INSTRUCTIONS_AVAILABLE = 30,
    PF_ARM_V8_CRC32_INSTRUCTIONS_AVAILABLE = 31,
    PF_RDTSCP_INSTRUCTION_AVAILABLE = 32,
    PF_RDPID_INSTRUCTION_AVAILABLE = 33,
    PF_ARM_V81_ATOMIC_INSTRUCTIONS_AVAILABLE = 34,
    PF_MONITORX_INSTRUCTION_AVAILABLE = 35,
    PF_SSSE3_INSTRUCTIONS_AVAILABLE = 36,
    PF_SSE4_1_INSTRUCTIONS_AVAILABLE = 37,
    PF_SSE4_2_INSTRUCTIONS_AVAILABLE = 38,
    PF_AVX_INSTRUCTIONS_AVAILABLE = 39,
    PF_AVX2_INSTRUCTIONS_AVAILABLE = 40,
    PF_AVX512F_INSTRUCTIONS_AVAILABLE = 41,
    PF_ERMS_AVAILABLE = 42,
    PF_ARM_V82_DP_INSTRUCTIONS_AVAILABLE = 43,
    PF_ARM_V83_JSCVT_INSTRUCTIONS_AVAILABLE = 44,
    PF_RESERVED45, PF_RESERVED46, PF_RESERVED47, PF_RESERVED48, PF_RESERVED49,
    PF_RESERVED50, PF_RESERVED51, PF_RESERVED52, PF_RESERVED53, PF_RESERVED54,
    PF_RESERVED55, PF_RESERVED56, PF_RESERVED57, PF_RESERVED58, PF_RESERVED59,
    PF_RESERVED60, PF_RESERVED61, PF_RESERVED62, PF_RESERVED63
  );

  TProcessorFeatures = array [TProcessorFeature] of Boolean;

  // WDK::ntddk.h
  [SDKName('KUSER_SHARED_DATA')]
  KUSER_SHARED_DATA = packed record
    TickCountLowDeprecated: Cardinal;
    [Hex] TickCountMultiplier: Cardinal;
    [volatile] InterruptTime: KSystemTime;
    [volatile] SystemTime: KSystemTime;
    [volatile] TimeZoneBias: KSystemTime;
    [Hex] ImageNumberLow: Word;
    [Hex] ImageNumberHigh: Word;
    NtSystemRoot: TNtSystemRoot;
    MaxStackTraceDepth: Cardinal;
    [Hex] CryptoExponent: Cardinal;
    TimeZoneID: Cardinal;
    [Bytes] LargePageMinimum: Cardinal;
    [MinOSVersion(OsWin8)] AitSamplingValue: Cardinal;
    [MinOSVersion(OsWin8), Hex] AppCompatFlag: Cardinal;
    [MinOSVersion(OsWin8)] RNGSeedVersion: Int64;
    [MinOSVersion(OsWin8)] GlobalValidationRunlevel: Cardinal;
    [MinOSVersion(OsWin8)] TimeZoneBiasStamp: Integer;
    [MinOSVersion(OsWin10TH1)] NtBuildNumber: Cardinal;
    NtProductType: TNtProductType;
    ProductTypeIsValid: Boolean;
    [Unlisted] Reserved0: Byte;
    [MinOSVersion(OsWin8)] NativeProcessorArchitecture: TProcessorArchitecture;
    NtMajorVersion: Cardinal;
    NtMinorVersion: Cardinal;
    ProcessorFeatures: TProcessorFeatures;
    [Unlisted] Reserved1: Cardinal;
    [Unlisted] Reserved3: Cardinal;
    [volatile] TimeSlip: Cardinal;
    AlternativeArchitecture: Cardinal;
    [MinOSVersion(OsWin10TH1)] BootID: Cardinal;
    SystemExpirationDate: TLargeInteger;
    [Hex] SuiteMask: Cardinal;
    KdDebuggerEnabled: Boolean;
    [Hex] MitigationPolicies: Byte;
    [MinOSVersion(OsWin1019H1)] CyclesPerYield: Word;
    [volatile] ActiveConsoleId: TSessionId;
    [volatile] DismountCount: Cardinal;
    [BooleanKind(bkEnabledDisabled)] ComPlusPackage: LongBool;
    LastSystemRITEventTickCount: Cardinal;
    NumberOfPhysicalPages: Cardinal;
    [BooleanKind(bkYesNo)] SafeBootMode: Boolean;
    [MinOSVersion(OsWin10RS1), Hex] VirtualizationFlags: Byte;
    SharedDataFlags: TSharedGlobalFlags;
    [Unlisted] DataFlagsPad: array [0..0] of Cardinal;
    TestRetInstruction: Int64;
    QpcFrequency: Int64;
    [MinOSVersion(OsWin10TH2)] SystemCall: TSystemCall;
    [MinOSVersion(OsWin10TH2), Unlisted] SystemCallPad0: Cardinal;
    [Unlisted] SystemCallPad: array [0..1] of Int64;
    [volatile] TickCount: KSystemTime;
    [Unlisted] TickCountPad: array [0..0] of Cardinal;
    [Hex] Cookie: Cardinal;
    [Unlisted] CookiePad: array [0..0] of Cardinal;
    [volatile] ConsoleSessionForegroundProcessID: TProcessId;
    {$IFDEF Win32}[Unlisted] Padding: Cardinal;{$ENDIF}
    [MinOSVersion(OsWin81)] TimeUpdateLock: Int64;
    [MinOSVersion(OsWin8), volatile] BaselineSystemTimeQpc: TULargeInteger;
    [MinOSVersion(OsWin8), volatile] BaselineInterruptTimeQpc: TULargeInteger;
    [MinOSVersion(OsWin8), Hex] QpcSystemTimeIncrement: UInt64;
    [MinOSVersion(OsWin8), Hex] QpcInterruptTimeIncrement: UInt64;
    [MinOSVersion(OsWin10TH1)] QpcSystemTimeIncrementShift: Byte;
    [MinOSVersion(OsWin10TH1)] QpcInterruptTimeIncrementShift: Byte;
    [MinOSVersion(OsWin81)] UnparkedProcessorCount: Word;
    [MinOSVersion(OsWin10TH2)] EnclaveFeatureMask: array [0..3] of Cardinal;
    [MinOSVersion(OsWin10RS3)] TelemetryCoverageRound: Cardinal;
    UserModeGlobalLogger: array [0..15] of Word;
    [Hex] ImageFileExecutionOptions: Cardinal;
    LangGenerationCount: Cardinal;
    [Unlisted] Reserved4: Int64;
    [volatile] InterruptTimeBias: TULargeInteger;
    [volatile] QpcBias: TULargeInteger;
    [volatile] ActiveProcessorCount: Cardinal;
    [volatile] ActiveGroupCount: Byte;
    [Unlisted] Reserved9: Byte;
    [MinOSVersion(OsWin8)] QpcData: Word;
    [MinOSVersion(OsWin8)] TimeZoneBiasEffectiveStart: TLargeInteger;
    [MinOSVersion(OsWin8)] TimeZoneBiasEffectiveEnd: TLargeInteger;
    function GetTickCount: Cardinal;
  end;
  PKUSER_SHARED_DATA = ^KUSER_SHARED_DATA;

const
  USER_SHARED_DATA = PKUSER_SHARED_DATA($7ffe0000);

{ PEB }

// PHNT::ntpebteb.h
function RtlGetCurrentPeb(
): PPeb; stdcall; external ntdll;

// PHNT::ntpebteb.h
[Result: ReleaseWith('RtlReleasePebLock')]
procedure RtlAcquirePebLock(
); stdcall; external ntdll;

// PHNT::ntpebteb.h
procedure RtlReleasePebLock(
); stdcall; external ntdll;

// PHNT::ntpebteb.h
[Result: ReleaseWith('RtlReleasePebLock')]
function RtlTryAcquirePebLock(
): LongBool; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDllShutdownInProgress(
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetNtGlobalFlags(
): Cardinal; stdcall; external ntdll;

{ TEB }

function NtCurrentTeb: PTeb;

function RtlIsWoW64: Boolean;

// PHNT::ntrtl.h
function RtlGetThreadErrorMode(
): TRtlErrorMode; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetThreadErrorMode(
  [in] NewMode: TRtlErrorMode;
  [out, opt] OldMode: PRtlErrorMode
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlWow64EnableFsRedirection(
  [in] Wow64FsEnableRedirection: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlWow64EnableFsRedirectionEx(
  [in] Wow64FsEnableRedirection: NativeUInt;
  [out] out OldFsRedirectionLevel: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlIsThreadWithinLoaderCallout(
): Boolean; stdcall; external ntdll;

{ Time Helpers }

const
  DAYS_FROM_1601 = 109205; // difference between native & Delphi's zero time
  NATIVE_TIME_DAY = 864000000000; // 100ns in 1 day
  NATIVE_TIME_HOUR = 36000000000; // 100ns in 1 hour
  NATIVE_TIME_MINUTE = 600000000; // 100ns in 1 minute
  NATIVE_TIME_SECOND =  10000000; // 100ns in 1 sec
  NATIVE_TIME_MILLISEC =   10000; // 100ns in 1 millisec

  SECONDS_PER_DAY = 86400;
  MILLISEC_PER_DAY = 86400000;

  DAYS_FROM_1970 = 25569; // difference Unix & Delphi's zero time

// Native time
function DateTimeToLargeInteger([in] DateTime: TDateTime): TLargeInteger;
function LargeIntegerToDateTime([in] QuadPart: TLargeInteger): TDateTime;

// Unix time
function DateTimeToUnixTime([in] DateTime: TDateTime): TUnixTime;
function UnixTimeToDateTime([in] UnixTime: TUnixTime): TDateTime;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{$IFDEF WIN64}
function NtCurrentTeb;
asm
  mov rax, gs:TNtTib([0]).Self // gs:[30h]
end;
{$ENDIF}

{$IFDEF WIN32}
function NtCurrentTeb;
asm
  mov eax, fs:TNtTib([0]).Self // fs:[18h]
end;
{$ENDIF}

function RtlIsWoW64;
begin
{$IFDEF Win32}
  Result := NtCurrentTeb.WowTebOffset <> 0;
{$ELSE}
  Result := False;
{$ENDIF}
end;

{ Time Helpers }

function TimeZoneBias: TLargeInteger;
begin
  // Workaround "Internal Error X64TAB2051" in Delphi compiler by extracting
  // this expression from the functions below... wtf was that?
  Result := USER_SHARED_DATA.TimeZoneBias.QuadPart;
end;

function DateTimeToLargeInteger;
begin
  {$Q-}{$R-}
  Result := Trunc(NATIVE_TIME_DAY * (DAYS_FROM_1601 + DateTime)) + TimeZoneBias;
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
end;

function LargeIntegerToDateTime;
begin
  {$Q-}{$R-}
  Result := (QuadPart - TimeZoneBias) / NATIVE_TIME_DAY - DAYS_FROM_1601;
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
end;

function DateTimeToUnixTime;
begin
  {$Q-}{$R-}
  Result := Trunc((DateTime - DAYS_FROM_1970) * SECONDS_PER_DAY) +
    TimeZoneBias div NATIVE_TIME_SECOND;
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
end;

function UnixTimeToDateTime;
begin
  {$Q-}{$R-}
  Result := (UnixTime - TimeZoneBias / NATIVE_TIME_SECOND) / SECONDS_PER_DAY +
    DAYS_FROM_1970;
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
end;

{ KUSER_SHARED_DATA }

function KUSER_SHARED_DATA.GetTickCount;
begin
  {$Q-}{$R-}
  Result := UInt64(TickCount.LowPart) * TickCountMultiplier shr 24;
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
end;

initialization
  if RtlGetCurrentPeb.ImageBaseAddress <> @ImageBase then
    SysInit.ModuleIsLib := True;
end.
