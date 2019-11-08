unit Ntapi.ntwow64;

interface

uses
  Ntapi.ntdef;

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
