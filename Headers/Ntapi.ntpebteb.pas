unit Ntapi.ntpebteb;

{
  The file defines the structure of structures Process/Thread Environment Block.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ImageHlp, Ntapi.Versions,
  DelphiApi.Reflection;

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
  [FlagName(PEB_BITS_IS_LONG_PATH_AWARE_PROCESS, 'Long-path Aware')]
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
    ActivationContextData: Pointer; // ACTIVATION_CONTEXT_DATA
    ProcessAssemblyStorageMap: Pointer; // ASSEMBLY_STORAGE_MAP
    SystemDefaultActivationContextData: Pointer; // ACTIVATION_CONTEXT_DATA
    SystemAssemblyStorageMap: Pointer; // ASSEMBLY_STORAGE_MAP
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
  [SDKName('ACTIVATION_CONTEXT_STACK')]
  TActivationContextStack = record
    ActiveFrame: Pointer;
    FrameListCache: TListEntry;
    [Hex] Flags: Cardinal;
    NextCookieSequenceNumber: Cardinal;
    StackId: Cardinal;
  end;
  PActivationContextStack = ^TActivationContextStack;

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

{ PEB }

// PHNT::ntpebteb.h
function RtlGetCurrentPeb(
): PPeb; stdcall; external ntdll;

// PHNT::ntpebteb.h
procedure RtlAcquirePebLock(
); stdcall; external ntdll;

// PHNT::ntpebteb.h
procedure RtlReleasePebLock(
); stdcall; external ntdll;

// PHNT::ntpebteb.h
function RtlTryAcquirePebLock(
): LongBool; stdcall; external ntdll;

{ TEB }

function NtCurrentTeb: PTeb;

function RtlIsWoW64: Boolean;

// PHNT::ntrtl.h
function RtlGetThreadErrorMode(
): TRtlErrorMode; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetThreadErrorMode(
  NewMode: TRtlErrorMode;
  [out, opt] OldMode: PRtlErrorMode
): NTSTATUS; stdcall; external ntdll;

implementation

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


end.
