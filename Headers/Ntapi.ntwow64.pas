unit Ntapi.ntwow64;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntldr;

type
  Wow64Pointer = Cardinal;

  // ntdef
  TClientId32 = record
    UniqueProcess: Cardinal;
    UniqueThread: Cardinal;
  end;
  PClientId32 = ^TClientId32;

  // ntdef
  UNICODE_STRING32 = record
    Length: Word;
    MaximumLength: Word;
    Buffer: Wow64Pointer;
  end;

  // WinNt.1159
  TListEntry32 = record
    Flink: Wow64Pointer;
    Blink: Wow64Pointer;
  end;
  PListEntry32 = ^TListEntry32;

  // WinNt.11459
  TNtTib32 = record
    ExceptionList: Wow64Pointer;
    StackBase: Wow64Pointer;
    StackLimit: Wow64Pointer;
    SubSystemTib: Wow64Pointer;
    FiberData: Wow64Pointer;
    ArbitraryUserPointer: Wow64Pointer;
    Self: Wow64Pointer;
  end;
  PNtTib32 = ^TNtTib32;

  TGdiTebBatch32 = record
    Offset: Cardinal;
    HDC: Wow64Pointer;
    Buffer: array [0..309] of Cardinal;
  end;

  TRtlBalancedNode32 = record
    Left: Wow64Pointer;
    Right: Wow64Pointer;
    ParentValue: Wow64Pointer;
  end;

  TPebLdrData32 = record
    Length: Cardinal;
    Initialized: Boolean;
    SsHandle: Wow64Pointer;
    InLoadOrderModuleList: TListEntry32;
    InMemoryOrderModuleList: TListEntry32;
    InInitializationOrderModuleList: TListEntry32;
    EntryInProgress: Wow64Pointer;
    ShutdownInProgress: Boolean;
    ShutdownThreadId: Wow64Pointer;
  end;
  PPebLdrData32 = ^TPebLdrData32;

  TLdrDataTableEntry32 = record
    InLoadOrderLinks: TListEntry32;
    InMemoryOrderLinks: TListEntry32;
    InInitializationOrderLinks: TListEntry32;
    DllBase: Wow64Pointer;
    EntryPoint: Wow64Pointer;
    SizeOfImage: Cardinal;
    FullDllName: UNICODE_STRING32;
    BaseDllName: UNICODE_STRING32;
    Flags: Cardinal; // LDRP_*
    ObsoleteLoadCount: Word;
    TlsIndex: Word;
    HashLinks: TListEntry32;
    TimeDateStamp: Cardinal;
    EntryPointActivationContext: Wow64Pointer;
    Lock: Wow64Pointer;
    DdagNode: Wow64Pointer; // PLDR_DDAG_NODE
    NodeModuleLink: TListEntry;
    LoadContext: Wow64Pointer;
    ParentDllBase: Wow64Pointer;
    SwitchBackContext: Wow64Pointer;
    BaseAddressIndexNode: TRtlBalancedNode32;
    MappingInfoIndexNode: TRtlBalancedNode32;
    OriginalBase: NativeUInt;
    LoadTime: TLargeInteger;

    // Win 8+ fields
    BaseNameHashValue: Cardinal;
    LoadReason: TLdrDllLoadReason;

    // Win 10+ fields
    ImplicitPathOptions: Cardinal;
    ReferenceCount: Cardinal;
    DependentLoadFlags: Cardinal;
    SigningLevel: Byte; // RS2+
  end;
  PLdrDataTableEntry32 = ^TLdrDataTableEntry32;

  TPeb32 = record
    InheritedAddressSpace: Boolean;
    ReadImageFileExecOptions: Boolean;
    BeingDebugged: Boolean;
    BitField: Boolean;
    Mutant: Wow64Pointer;
    ImageBaseAddress: Wow64Pointer;
    Ldr: Wow64Pointer; //PPebLdrData32
    ProcessParameters: Wow64Pointer; //PRtlUserProcessParameters32;
    SubSystemData: Wow64Pointer;
    ProcessHeap: Wow64Pointer;
    FastPebLock: Wow64Pointer; // WinNt.PRTL_CRITICAL_SECTION
    AtlThunkSListPtr: Wow64Pointer; // WinNt.PSLIST_HEADER
    IFEOKey: Wow64Pointer;
    CrossProcessFlags: Cardinal;
    UserSharedInfoPtr: Wow64Pointer;
    SystemReserved: Cardinal;
    AtlThunkSListPtr32: Cardinal;
    ApiSetMap: Wow64Pointer; // ntpebteb.PAPI_SET_NAMESPACE
    TlsExpansionCounter: Cardinal;
    TlsBitmap: Wow64Pointer;
    TlsBitmapBits: array [0..1] of Cardinal;

    ReadOnlySharedMemoryBase: Wow64Pointer;
    SharedData: Wow64Pointer; // HotpatchInformation
    ReadOnlyStaticServerData: Wow64Pointer;

    AnsiCodePageData: Wow64Pointer; // PCPTABLEINFO
    OemCodePageData: Wow64Pointer; // PCPTABLEINFO
    UnicodeCaseTableData: Wow64Pointer; // PNLSTABLEINFO

    NumberOfProcessors: Cardinal;
    NtGlobalFlag: Cardinal;

    CriticalSectionTimeout: TULargeInteger;
    HeapSegmentReserve: Cardinal;
    HeapSegmentCommit: Cardinal;
    HeapDeCommitTotalFreeThreshold: Cardinal;
    HeapDeCommitFreeBlockThreshold: Cardinal;

    NumberOfHeaps: Cardinal;
    MaximumNumberOfHeaps: Cardinal;
    ProcessHeaps: Wow64Pointer; // PHEAP

    GdiSharedHandleTable: Wow64Pointer;
    ProcessStarterHelper: Wow64Pointer;
    GdiDCAttributeList: Cardinal;

    LoaderLock: Wow64Pointer; // WinNt.PRTL_CRITICAL_SECTION

    OSMajorVersion: Cardinal;
    OSMinorVersion: Cardinal;
    OSBuildNumber: Word;
    OSCSDVersion: Word;
    OSPlatformId: Cardinal;
    ImageSubsystem: Cardinal;
    ImageSubsystemMajorVersion: Cardinal;
    ImageSubsystemMinorVersion: Cardinal;
    ActiveProcessAffinityMask: Cardinal;

    GdiHandleBuffer: array [0 .. 33] of Cardinal;
    PostProcessInitRoutine: Wow64Pointer;

    TlsExpansionBitmap: Wow64Pointer;
    TlsExpansionBitmapBits: array [0..31] of Cardinal;

    SessionId: Cardinal;

    AppCompatFlags: TULargeInteger;
    AppCompatFlagsUser: TULargeInteger;
    pShimData: Wow64Pointer;
    AppCompatInfo: Wow64Pointer; // APPCOMPAT_EXE_DATA

    CSDVersion: UNICODE_STRING32;

    ActivationContextData: Wow64Pointer; // ACTIVATION_CONTEXT_DATA
    ProcessAssemblyStorageMap: Wow64Pointer; // ASSEMBLY_STORAGE_MAP
    SystemDefaultActivationContextData: Wow64Pointer; // ACTIVATION_CONTEXT_DATA
    SystemAssemblyStorageMap: Wow64Pointer; // ASSEMBLY_STORAGE_MAP

    MinimumStackCommit: Cardinal;

    FlsCallback: Wow64Pointer;
    FlsListHead: TListEntry32;
    FlsBitmap: Wow64Pointer;
    FlsBitmapBits: array [0..3] of Cardinal;
    FlsHighIndex: Cardinal;

    WerRegistrationData: Wow64Pointer;
    WerShipAssertPtr: Wow64Pointer;
    pUnused: Wow64Pointer; // pContextData
    pImageHeaderHash: Wow64Pointer;
    TracingFlags: Cardinal;
    CsrServerReadOnlySharedMemoryBase: UInt64;
    TppWorkerpListLock: Wow64Pointer; // WinNt.PRTL_CRITICAL_SECTION
    TppWorkerpList: TListEntry32;
    WaitOnAddressHashTable: array [0..127] of Wow64Pointer;
    TelemetryCoverageHeader: Wow64Pointer; // REDSTONE3
    CloudFileFlags: Cardinal;
    CloudFileDiagFlags: Cardinal; // REDSTONE4
    PlaceholderCompatibilityMode: Byte;
    PlaceholderCompatibilityModeReserved: array [0..6] of Byte;
    LeapSecondData: Wow64Pointer; // *_LEAP_SECOND_DATA; // REDSTONE5
    LeapSecondFlags: Cardinal;
    NtGlobalFlag2: Cardinal;
  end;
  PPeb32 = ^TPeb32;

  TTeb32 = record
    NtTib: TNtTib32;

    EnvironmentPointer: Wow64Pointer;
    ClientId: TClientId32;
    ActiveRpcHandle: Wow64Pointer;
    ThreadLocalStoragePointer: Wow64Pointer;
    ProcessEnvironmentBlock: Wow64Pointer; // PPeb

    LastErrorValue: Cardinal;
    CountOfOwnedCriticalSections: Cardinal;
    CsrClientThread: Wow64Pointer;
    Win32ThreadInfo: Wow64Pointer;
    User32Reserved: array [0..25] of Cardinal;
    UserReserved: array [0..4] of Cardinal;
    WOW32Reserved: Wow64Pointer;
    CurrentLocale: Cardinal;
    FpSoftwareStatusRegister: Cardinal;
    ReservedForDebuggerInstrumentation: array [0..15] of Wow64Pointer;
    SystemReserved1: array [0..35] of Wow64Pointer;
    WorkingOnBehalfTicket: array [0..7] of Byte;
    ExceptionCode: NTSTATUS;

    ActivationContextStackPointer: Wow64Pointer;
    InstrumentationCallbackSp: Wow64Pointer;
    InstrumentationCallbackPreviousPc: Wow64Pointer;
    InstrumentationCallbackPreviousSp: Wow64Pointer;
    InstrumentationCallbackDisabled: Boolean;
    SpareBytes: array [0..22] of Byte;
    TxFsContext: Cardinal;

    GdiTebBatch: TGdiTebBatch32;
    RealClientId: TClientId32;
    GdiCachedProcessHandle: Wow64Pointer;
    GdiClientPID: Cardinal;
    GdiClientTID: Cardinal;
    GdiThreadLocalInfo: Wow64Pointer;
    Win32ClientInfo: array [0..61] of Wow64Pointer;
    glDispatchTable: array [0..232] of Wow64Pointer;
    glReserved1: array [0..28] of Wow64Pointer;
    glReserved2: Wow64Pointer;
    glSectionInfo: Wow64Pointer;
    glSection: Wow64Pointer;
    glTable: Wow64Pointer;
    glCurrentRC: Wow64Pointer;
    glContext: Wow64Pointer;

    LastStatusValue: NTSTATUS;
    StaticUnicodeString: UNICODE_STRING32;
    StaticUnicodeBuffer: array [0..260] of WideChar;

    DeallocationStack: Wow64Pointer;
    TlsSlots: array [0..63] of Wow64Pointer;
    TlsLinks: TListEntry32;

    Vdm: Wow64Pointer;
    ReservedForNtRpc: Wow64Pointer;
    DbgSsReserved: array [0..1] of Wow64Pointer;

    HardErrorMode: Cardinal;
    Instrumentation: array [0..8] of Wow64Pointer;
    ActivityId: TGuid;

    SubProcessTag: Wow64Pointer;
    PerflibData: Wow64Pointer;
    EtwTraceData: Wow64Pointer;
    WinSockData: Wow64Pointer;
    GdiBatchCount: Cardinal;
    IdealProcessorValue: Cardinal;
    GuaranteedStackBytes: Cardinal;
    ReservedForPerf: Wow64Pointer;
    ReservedForOle: Wow64Pointer;
    WaitingOnLoaderLock: Cardinal;
    SavedPriorityState: Wow64Pointer;
    ReservedForCodeCoverage: Wow64Pointer;
    ThreadPoolData: Wow64Pointer;
    TlsExpansionSlots: Wow64Pointer;

    MuiGeneration: Cardinal;
    IsImpersonating: Cardinal;
    NlsCache: Wow64Pointer;
    pShimData: Wow64Pointer;
    HeapVirtualAffinity: Word;
    LowFragHeapDataSlot: Word;
    CurrentTransactionHandle: Wow64Pointer;
    ActiveFrame: Wow64Pointer;
    FlsData: Wow64Pointer;

    PreferredLanguages: Wow64Pointer;
    UserPrefLanguages: Wow64Pointer;
    MergedPrefLanguages: Wow64Pointer;
    MuiImpersonation: Cardinal;
    CrossTebFlags: Word;
    SameTebFlags: Word;
    TxnScopeEnterCallback: Wow64Pointer;
    TxnScopeExitCallback: Wow64Pointer;
    TxnScopeContext: Wow64Pointer;
    LockCount: Cardinal;
    WowTebOffset: Integer;
    ResourceRetValue: Wow64Pointer;
    ReservedForWdf: Wow64Pointer;
    ReservedForCrt: UInt64;
    EffectiveContainerId: TGuid;
  end;
  PTeb32 = ^TTeb32;

implementation

end.
