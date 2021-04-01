unit Ntapi.ntpebteb;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, NtUtils.Version,
  DelphiApi.Reflection;

const
  // PEB.BitField
  PEB_BITS_IMAGE_USES_LARGE_PAGES = $01;
  PEB_BITS_IS_PROTECTED_PROCESS = $02;
  PEB_BITS_IS_IMAGE_DYNAMICALLY_RELOCATED = $04;
  PEB_BITS_SKIP_PATCHING_USER32_FORWARDERS = $08;
  PEB_BITS_IS_PACKAGED_PROCESS = $10;
  PEB_BITS_IS_APP_CONTAINER = $20;
  PEB_BITS_IS_PROTECTED_PROCESS_LIGHT = $40;
  PEB_BITS_IS_LONG_PATH_AWARE_PROCESS = $80;

  // PEB.CrossProcessFlags
  PEB_CROSS_FLAGS_IN_JOB = $0001;
  PEB_CROSS_FLAGS_INITIALIZING = $0002;
  PEB_CROSS_FLAGS_USING_VEH = $0005;
  PEB_CROSS_FLAGS_USING_VCH = $0008;
  PEB_CROSS_FLAGS_USING_FTH = $0010;
  PEB_CROSS_FLAGS_PREVIOUSLY_THROTTLED = $0020;
  PEB_CROSS_FLAGS_CURRENTLY_THROTTLED = $0040;
  PEB_CROSS_FLAGS_IMAGES_HOT_PATCHED = $0080;

  // PEB.TracingFlags
  TRACING_FLAGS_HEAP_TRACING_ENABLED = $0001;
  TRACING_FLAGS_CRIT_SEC_TRACING_ENABLED = $0002;
  TRACING_FLAGS_LIB_LOADER_TRACING_ENABLED = $00004;

  // TEB.SameTebFlags
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
  TEB_SAME_FLAGS_SESSION_AWARE = $0800;
  TEB_SAME_FLAGS_LOAD_OWNER = $1000;
  TEB_SAME_FLAGS_LOADER_WORKER = $2000;
  TEB_SAME_FLAGS_SKIP_LOADER_INIT = $4000;

type
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

  [FlagName(TRACING_FLAGS_HEAP_TRACING_ENABLED, 'Heap Tracing')]
  [FlagName(TRACING_FLAGS_CRIT_SEC_TRACING_ENABLED, 'Critical Section Tracing')]
  [FlagName(TRACING_FLAGS_LIB_LOADER_TRACING_ENABLED, 'Loader Tracing')]
  TPebTracingFlags = type Cardinal;

  [FlagName(TEB_SAME_FLAGS_SAFE_THUNK_CALL, 'Safe Thunk Call')]
  [FlagName(TEB_SAME_FLAGS_IN_DEBUG_PRINT, 'In Debug Pring')]
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
  TTebSameTebFlags = type Word;

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

  TPeb = record
    InheritedAddressSpace: Boolean;
    ReadImageFileExecOptions: Boolean;
    BeingDebugged: Boolean;
    [MinOSVersion(OsWin81)] BitField: TPebBitField;
    [Hex] Mutant: THandle;
    ImageBaseAddress: Pointer;
    Ldr: PPebLdrData;
    ProcessParameters: PRtlUserProcessParameters;
    SubSystemData: Pointer;
    ProcessHeap: Pointer;
    FastPebLock: Pointer; // WinNt.PRTL_CRITICAL_SECTION
    [volatile] AtlThunkSListPtr: Pointer; // WinNt.PSLIST_HEADER
    IFEOKey: Pointer;
    CrossProcessFlags: TPebCrossFlags;
    UserSharedInfoPtr: Pointer;
    SystemReserved: Cardinal;
    ATLThunkSListPtr32: Cardinal;
    APISetMap: Pointer; // ntpebteb.PAPI_SET_NAMESPACE
    TLSExpansionCounter: Cardinal;
    TLSBitmap: Pointer;
    TLSBitmapBits: array [0..1] of Cardinal;

    ReadOnlySharedMemoryBase: Pointer;
    SharedData: Pointer; // HotpatchInformation
    ReadOnlyStaticServerData: PPointer;

    AnsiCodePageData: Pointer; // PCPTABLEINFO
    OEMCodePageData: Pointer; // PCPTABLEINFO
    UnicodeCaseTableData: Pointer; // PNLSTABLEINFO

    NumberOfProcessors: Cardinal;
    [Hex] NTGlobalFlag: Cardinal;

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

    LoaderLock: Pointer; // WinNt.PRTL_CRITICAL_SECTION

    OSMajorVersion: Cardinal;
    OSMinorVersion: Cardinal;
    OSBuildNumber: Word;
    OSCsdVersion: Word;
    OSPlatformID: Cardinal;
    ImageSubsystem: TImageSubsystem;
    ImageSubsystemMajorVersion: Cardinal;
    ImageSubsystemMinorVersion: Cardinal;
    ActiveProcessAffinityMask: NativeUInt;

  {$IFNDEF WIN64}
    GDIHandleBuffer: array [0 .. 33] of Cardinal;
  {$ELSE}
    GDIHandleBuffer: array [0 .. 59] of Cardinal;
  {$ENDIF}

    PostProcessInitRoutine: Pointer;

    TLSExpansionBitmap: Pointer;
    TLSExpansionBitmapBits: array [0..31] of Cardinal;

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

    FlsCallback: PPointer;
    FlsListHead: TListEntry;
    FlsBitmap: Pointer;
    FlsBitmapBits: array [0..3] of Cardinal;
    FlsHighIndex: Cardinal;

    WERRegistrationData: Pointer;
    WERShipAssertPtr: Pointer;
    pUnused: Pointer; // pContextData
    pImageHeaderHash: Pointer;
    TracingFlags: TPebTracingFlags;
    [MinOSVersion(OsWin8), Hex] CSRServerReadOnlySharedMemoryBase: UInt64;
    [MinOSVersion(OsWin10TH2)] TPPWorkerpListLock: Pointer; // WinNt.PRTL_CRITICAL_SECTION
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
  end;
  PPeb = ^TPeb;

  TActivationContextStack = record
    ActiveFrame: Pointer;
    FrameListCache: TListEntry;
    [Hex] Flags: Cardinal;
    NextCookieSequenceNumber: Cardinal;
    StackId: Cardinal;
  end;
  PActivationContextStack = ^TActivationContextStack;

  TGdiTebBatch = record
    Offset: Cardinal;
    HDC: NativeUInt;
    Buffer: array [0..309] of Cardinal;
  end;

  PNtTib = ^TNtTib;
  TNtTib = record
    ExceptionList: Pointer;
    StackBase: Pointer;
    StackLimit: Pointer;
    SubSystemTib: Pointer;
    FiberData: Pointer;
    ArbitraryUserPointer: Pointer;
    Self: PNtTib;
  end;

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
     SystemReserved1: array [0..29] of Pointer;
   {$ELSE}
     SystemReserved1: array [0..25] of Pointer;
   {$ENDIF}

    [MinOSVersion(OsWin10RS3)] PlaceholderCompatibilityMode: ShortInt;
    [MinOSVersion(OsWin10RS5)] PlaceholderHydrationAlwaysExplicit: Byte;
    [MinOSVersion(OsWin10RS3)] PlaceholderReserved: array [0..9] of ShortInt;
    [MinOSVersion(OsWin10RS3)] ProxiedProcessID: TProcessId32;
    [MinOSVersion(OsWin10RS2)] ActivationStack: TActivationContextStack;
    [MinOSVersion(OsWin10RS2)] WorkingOnBehalfTicket: array [0..7] of Byte;
    ExceptionCode: Cardinal;
    ActivationContextStackPointer: PActivationContextStack;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackSp: NativeUInt;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousPc: NativeUInt;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousSp: NativeUInt;

    {$IFDEF WIN64}
    TXFContext: Cardinal;
    {$ENDIF}

    [MinOSVersion(OsWin10)] InstrumentationCallbackDisabled: Boolean;

    {$IFDEF WIN64}
    [MinOSVersion(OsWin10RS5)] UnalignedLoadStoreExceptions: Boolean;
    {$ELSE}
    SpareBytes: array [0..22] of Byte;
    TXFContext: Cardinal;
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
    StaticUnicodeBuffer: array [0..260] of WideChar;

    DealLocationStack: Pointer;
    TLSSlots: array [0..63] of Pointer;
    TLSLinks: TListEntry;

    VDM: Pointer;
    ReservedForNtRPC: Pointer;
    DbgSsReserved: array [0..1] of Pointer;

    HardErrorMode: Cardinal;

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

    [Hex] IdealProcessorValue: Cardinal;

    GuaranteedStackBytes: Cardinal;
    ReservedForPerf: Pointer;
    ReservedForOLE: Pointer;
    WaitingOnLoaderLock: Cardinal;
    SavedPriorityState: Pointer;
    [MinOSVersion(OsWin8)] ReservedForCodeCoverage: NativeUInt;
    ThreadPoolData: Pointer;
    TLSExpansionSlots: PPointer;

    {$IFDEF WIN64}
    DeallocationBStore: Pointer;
    BStoreLimit: Pointer;
    {$ENDIF}

    MUIGeneration: Cardinal;
    IsImpersonating: LongBool;
    NlsCache: Pointer;
    pShimData: Pointer;
    [Hex] HeapVirtualAffinity: Word;
    [MinOSVersion(OsWin8)] LowFragHeapDataSlot: Word;
    CurrentTransactionHandle: THandle;
    ActiveFrame: Pointer;
    FlsData: Pointer;

    PreferredLanguages: Pointer;
    UserPrefLanguages: Pointer;
    MergedPrefLanguages: Pointer;
    MUIImpersonation: Cardinal;
    [Hex] CrossTebFlags: Word;
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
  end;
  PTeb = ^TTeb;

function RtlGetCurrentPeb: PPeb; stdcall; external ntdll;

procedure RtlAcquirePebLock; stdcall; external ntdll;

procedure RtlReleasePebLock; stdcall; external ntdll;

function RtlTryAcquirePebLock: LongBool stdcall; external ntdll;

function NtCurrentTeb: PTeb;

{$IFDEF Win32}
function RtlIsWoW64: Boolean;
{$ENDIF}

implementation

{$IFDEF WIN64}
function NtCurrentTeb;
asm
  mov rax, gs:[$0030]
end;
{$ENDIF}

{$IFDEF WIN32}
function NtCurrentTeb;
asm
  mov eax, fs:[$0018]
end;
{$ENDIF}

{$IFDEF Win32}
function RtlIsWoW64;
begin
  Result := NtCurrentTeb.WowTebOffset <> 0;
end;
{$ENDIF}

end.
