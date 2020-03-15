unit Ntapi.ntwow64;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntldr, Ntapi.ntpebteb, Ntapi.ntrtl,
  NtUtils.Version, DelphiApi.Reflection;

type
  [Hex] Wow64Pointer = type Cardinal;

  // ntdef
  TClientId32 = record
    UniqueProcess: TProcessId32;
    UniqueThread: TThreadId32;
  end;
  PClientId32 = ^TClientId32;

  // ntdef
  UNICODE_STRING32 = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: Wow64Pointer;
  end;
  ANSI_STRING32 = UNICODE_STRING32;

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
    [Bytes] SizeOfImage: Cardinal;
    FullDllName: UNICODE_STRING32;
    BaseDllName: UNICODE_STRING32;
    [Hex] Flags: Cardinal; // LDRP_*
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
    [Hex] OriginalBase: Wow64Pointer;
    LoadTime: TLargeInteger;

    // Win 8+ fields
    BaseNameHashValue: Cardinal;
    LoadReason: TLdrDllLoadReason;

    // Win 10+ fields
    ImplicitPathOptions: Cardinal;
    ReferenceCount: Cardinal;
    [Hex] DependentLoadFlags: Cardinal;
    SigningLevel: Byte; // RS2+
  end;
  PLdrDataTableEntry32 = ^TLdrDataTableEntry32;

  TCurDir32 = record
    DosPath: UNICODE_STRING32;
    Handle: Wow64Pointer;
  end;
  PCurDir32 = ^TCurDir32;

  TRtlDriveLetterCurDir32 = record
    [Hex] Flags: Word;
    [Bytes] Length: Word;
    TimeStamp: Cardinal;
    DosPath: ANSI_STRING32;
  end;
  PRtlDriveLetterCurDir32 = ^TRtlDriveLetterCurDir32;

  TCurrentDirectories32 = array [0..RTL_MAX_DRIVE_LETTERS - 1] of
      TRtlDriveLetterCurDir32;

  TRtlUserProcessParameters32 = record
    [Bytes, Unlisted] MaximumLength: Cardinal;
    [Bytes, Unlisted] Length: Cardinal;

    [Bitwise(TUserProcessFlagProvider)] Flags: Cardinal;
    [Hex] DebugFlags: Cardinal;

    ConsoleHandle: Wow64Pointer;
    [Hex] ConsoleFlags: Cardinal;
    StandardInput: Wow64Pointer;
    StandardOutput: Wow64Pointer;
    StandardError: Wow64Pointer;

    CurrentDirectory: TCurDir32;
    DLLPath: UNICODE_STRING32;
    ImagePathName: UNICODE_STRING32;
    CommandLine: UNICODE_STRING32;
    [volatile] Environment: Wow64Pointer;

    StartingX: Cardinal;
    StartingY: Cardinal;
    CountX: Cardinal;
    CountY: Cardinal;
    CountCharsX: Cardinal;
    CountCharsY: Cardinal;
    FillAttribute: Cardinal;

    WindowFlags: Cardinal;
    ShowWindowFlags: Cardinal;
    WindowTitle: UNICODE_STRING32;
    DesktopInfo: UNICODE_STRING32;
    ShellInfo: UNICODE_STRING32;
    RuntimeData: UNICODE_STRING32;
    CurrentDirectories: TCurrentDirectories32;

    [Bytes, volatile] EnvironmentSize: Cardinal;
    EnvironmentVersion: Cardinal;
    [MinOSVersion(OsWin8)] PackageDependencyData: Wow64Pointer;
    [MinOSVersion(OsWin8)] ProcessGroupID: Cardinal;
    [MinOSVersion(OsWin10TH1)] LoaderThreads: Cardinal;

    [MinOSVersion(OsWin10RS5)] RedirectionDLLName: UNICODE_STRING32;
    [MinOSVersion(OsWin1019H1)] HeapPartitionName: UNICODE_STRING32;
    [MinOSVersion(OsWin1019H1)] DefaultThreadPoolCPUSetMasks: Cardinal;
    [MinOSVersion(OsWin1019H1)] DefaultThreadPoolCPUSetMaskCount: Cardinal;
  end;
  PRtlUserProcessParameters32 = ^TRtlUserProcessParameters32;

  TPeb32 = record
    InheritedAddressSpace: Boolean;
    ReadImageFileExecOptions: Boolean;
    BeingDebugged: Boolean;
    [MinOSVersion(OsWin81), Bitwise(TBitFieldFlagProvider)] BitField: Byte;
    Mutant: Wow64Pointer;
    ImageBaseAddress: Wow64Pointer;
    Ldr: Wow64Pointer; //PPebLdrData32
    ProcessParameters: Wow64Pointer; //PRtlUserProcessParameters32;
    SubSystemData: Wow64Pointer;
    ProcessHeap: Wow64Pointer;
    FastPebLock: Wow64Pointer; // WinNt.PRTL_CRITICAL_SECTION
    [volatile] AtlThunkSListPtr: Wow64Pointer; // WinNt.PSLIST_HEADER
    IFEOKey: Wow64Pointer;
    [Bitwise(TCrossPebFlagProvider)] CrossProcessFlags: Cardinal;
    UserSharedInfoPtr: Wow64Pointer;
    SystemReserved: Cardinal;
    ATLThunkSListPtr32: Cardinal;
    APISetMap: Wow64Pointer; // ntpebteb.PAPI_SET_NAMESPACE
    TLSExpansionCounter: Cardinal;
    TLSBitmap: Wow64Pointer;
    TLSBitmapBits: array [0..1] of Cardinal;

    ReadOnlySharedMemoryBase: Wow64Pointer;
    SharedData: Wow64Pointer; // HotpatchInformation
    ReadOnlyStaticServerData: Wow64Pointer;

    AnsiCodePageData: Wow64Pointer; // PCPTABLEINFO
    OEMCodePageData: Wow64Pointer; // PCPTABLEINFO
    UnicodeCaseTableData: Wow64Pointer; // PNLSTABLEINFO

    NumberOfProcessors: Cardinal;
    [Hex] NTGlobalFlag: Cardinal;

    CriticalSectionTimeout: TULargeInteger;
    HeapSegmentReserve: Cardinal;
    HeapSegmentCommit: Cardinal;
    HeapDecommitTotalFreeThreshold: Cardinal;
    HeapDecommitFreeBlockThreshold: Cardinal;

    NumberOfHeaps: Cardinal;
    MaximumNumberOfHeaps: Cardinal;
    ProcessHeaps: Wow64Pointer; // PHEAP

    GDISharedHandleTable: Wow64Pointer;
    ProcessStarterHelper: Wow64Pointer;
    GdiDCAttributeList: Cardinal;

    LoaderLock: Wow64Pointer; // WinNt.PRTL_CRITICAL_SECTION

    OSMajorVersion: Cardinal;
    OSMinorVersion: Cardinal;
    OSBuildNumber: Word;
    OSCsdVersion: Word;
    OSPlatformID: Cardinal;
    [Hex] ImageSubsystem: Cardinal;
    ImageSubsystemMajorVersion: Cardinal;
    ImageSubsystemMinorVersion: Cardinal;
    ActiveProcessAffinityMask: Cardinal;

    GDIHandleBuffer: array [0 .. 33] of Cardinal;
    PostProcessInitRoutine: Wow64Pointer;

    TLSExpansionBitmap: Wow64Pointer;
    TLSExpansionBitmapBits: array [0..31] of Cardinal;

    SessionID: TSessionId;

    [Hex] AppCompatFlags: UInt64;
    [Hex] AppCompatFlagsUser: UInt64;
    pShimData: Wow64Pointer;
    AppCompatInfo: Wow64Pointer; // APPCOMPAT_EXE_DATA

    CSDVersion: UNICODE_STRING32;

    ActivationContextData: Wow64Pointer; // ACTIVATION_CONTEXT_DATA
    ProcessAssemblyStorageMap: Wow64Pointer; // ASSEMBLY_STORAGE_MAP
    SystemDefaultActivationContextData: Wow64Pointer; // ACTIVATION_CONTEXT_DATA
    SystemAssemblyStorageMap: Wow64Pointer; // ASSEMBLY_STORAGE_MAP

    [Bytes] MinimumStackCommit: Cardinal;

    FlsCallback: Wow64Pointer;
    FlsListHead: TListEntry32;
    FlsBitmap: Wow64Pointer;
    FlsBitmapBits: array [0..3] of Cardinal;
    FlsHighIndex: Cardinal;

    WERRegistrationData: Wow64Pointer;
    WERShipAssertPtr: Wow64Pointer;
    pUnused: Wow64Pointer; // pContextData
    pImageHeaderHash: Wow64Pointer;
    [Bitwise(TTracingFlagProvider)] TracingFlags: Cardinal;
    [MinOSVersion(OsWin8), Hex] CSRServerReadOnlySharedMemoryBase: UInt64;
    [MinOSVersion(OsWin10TH2)] TPPWorkerpListLock: Wow64Pointer; // WinNt.PRTL_CRITICAL_SECTION
    [MinOSVersion(OsWin10TH2)] TPPWorkerpList: TListEntry32;
    [MinOSVersion(OsWin10TH2)] WaitOnAddressHashTable: array [0..127] of Wow64Pointer;
    [MinOSVersion(OsWin10RS3)] TelemetryCoverageHeader: Wow64Pointer;
    [MinOSVersion(OsWin10RS3), Hex] CloudFileFlags: Cardinal;
    [MinOSVersion(OsWin10RS4), Hex] CloudFileDiagFlags: Cardinal;
    [MinOSVersion(OsWin10RS4)] PlaceholderCompatibilityMode: Byte;
    [MinOSVersion(OsWin10RS4)] PlaceholderCompatibilityModeReserved: array [0..6] of Byte;
    [MinOSVersion(OsWin10RS5)] LeapSecondData: Wow64Pointer; // *_LEAP_SECOND_DATA
    [MinOSVersion(OsWin10RS5), Hex] LeapSecondFlags: Cardinal;
    [MinOSVersion(OsWin10RS5), Hex] NTGlobalFlag2: Cardinal;
  end;
  PPeb32 = ^TPeb32;

  TTeb32 = record
    NtTib: TNtTib32;

    EnvironmentPointer: Wow64Pointer;
    ClientID: TClientId32;
    ActiveRpcHandle: Wow64Pointer;
    ThreadLocalStoragePointer: Wow64Pointer;
    ProcessEnvironmentBlock: Wow64Pointer; // PPeb

    LastErrorValue: TWin32Error;
    CountOfOwnedCriticalSections: Cardinal;
    CSRClientThread: Wow64Pointer;
    Win32ThreadInfo: Wow64Pointer;
    User32Reserved: array [0..25] of Cardinal;
    UserReserved: array [0..4] of Cardinal;
    WOW32Reserved: Wow64Pointer;
    CurrentLocale: Cardinal;
    FpSoftwareStatusRegister: Cardinal;
    [MinOSVersion(OsWin10TH1)] ReservedForDebuggerInstrumentation: array [0..15] of Wow64Pointer;
    SystemReserved1: array [0..35] of Wow64Pointer;
    [MinOSVersion(OsWin10RS2)] WorkingOnBehalfTicket: array [0..7] of Byte;
    ExceptionCode: Cardinal;

    ActivationContextStackPointer: Wow64Pointer;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackSp: Wow64Pointer;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousPc: Wow64Pointer;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousSp: Wow64Pointer;
    [MinOSVersion(OsWin10)] InstrumentationCallbackDisabled: Boolean;
    SpareBytes: array [0..22] of Byte;
    TxFsContext: Cardinal;

    GDITebBatch: TGdiTebBatch32;
    RealClientId: TClientId32;
    GDICachedProcessHandle: Wow64Pointer;
    GDIClientPID: Cardinal;
    GDIClientTID: Cardinal;
    GDIThreadLocalInfo: Wow64Pointer;
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

    DealLocationStack: Wow64Pointer;
    TLSSlots: array [0..63] of Wow64Pointer;
    TLSLinks: TListEntry32;

    VDM: Wow64Pointer;
    ReservedForNtRPC: Wow64Pointer;
    DbgSsReserved: array [0..1] of Wow64Pointer;

    HardErrorMode: Cardinal;
    Instrumentation: array [0..8] of Wow64Pointer;
    ActivityID: TGuid;

    SubProcessTag: Wow64Pointer;
    [MinOSVersion(OsWin8)] PerflibData: Wow64Pointer;
    ETWTraceData: Wow64Pointer;
    WinSockData: Wow64Pointer;
    GDIBatchCount: Cardinal;
    IdealProcessorValue: Cardinal;
    GuaranteedStackBytes: Cardinal;
    ReservedForPerf: Wow64Pointer;
    ReservedForOLE: Wow64Pointer;
    WaitingOnLoaderLock: Cardinal;
    SavedPriorityState: Wow64Pointer;
    [MinOSVersion(OsWin8)] ReservedForCodeCoverage: Wow64Pointer;
    ThreadPoolData: Wow64Pointer;
    TLSExpansionSlots: Wow64Pointer;

    MUIGeneration: Cardinal;
    IsImpersonating: LongBool;
    NlsCache: Wow64Pointer;
    pShimData: Wow64Pointer;
    [Hex] HeapVirtualAffinity: Word;
    [MinOSVersion(OsWin8)] LowFragHeapDataSlot: Word;
    CurrentTransactionHandle: Wow64Pointer;
    ActiveFrame: Wow64Pointer;
    FlsData: Wow64Pointer;

    PreferredLanguages: Wow64Pointer;
    UserPrefLanguages: Wow64Pointer;
    MergedPrefLanguages: Wow64Pointer;
    MUIImpersonation: Cardinal;
    [Hex] CrossTebFlags: Word;
    [Bitwise(TSameTebFlagProvider)] SameTebFlags: Word;
    TxnScopeEnterCallback: Wow64Pointer;
    TxnScopeExitCallback: Wow64Pointer;
    TxnScopeContext: Wow64Pointer;
    LockCount: Cardinal;
    WowTebOffset: Integer;
    ResourceRetValue: Wow64Pointer;
    [MinOSVersion(OsWin8)] ReservedForWDF: Wow64Pointer;
    [MinOSVersion(OsWin10TH1)] ReservedForCRT: UInt64;
    [MinOSVersion(OsWin10TH1)] EffectiveContainerID: TGuid;
  end;
  PTeb32 = ^TTeb32;

implementation

end.
