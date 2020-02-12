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

  PebBitsNames: array [0..7] of TFlagName = (
    (Value: PEB_BITS_IMAGE_USES_LARGE_PAGES; Name: 'Image Uses Large Pages'),
    (Value: PEB_BITS_IS_PROTECTED_PROCESS; Name: 'Protected Process'),
    (Value: PEB_BITS_IS_IMAGE_DYNAMICALLY_RELOCATED; Name: 'Image Dynamically Relocated'),
    (Value: PEB_BITS_SKIP_PATCHING_USER32_FORWARDERS; Name: 'Skip Patching User32 Forwarders'),
    (Value: PEB_BITS_IS_PACKAGED_PROCESS; Name: 'Packaged Process'),
    (Value: PEB_BITS_IS_APP_CONTAINER; Name: 'App Container'),
    (Value: PEB_BITS_IS_PROTECTED_PROCESS_LIGHT; Name: 'Protected Process Light'),
    (Value: PEB_BITS_IS_LONG_PATH_AWARE_PROCESS; Name: 'Long Path Aware')
  );

  // PEB.CrossProcessFlags
  PEB_CROSS_FLAGS_IN_JOB = $0001;
  PEB_CROSS_FLAGS_INITIALIZING = $0002;
  PEB_CROSS_FLAGS_USING_VEH = $0005;
  PEB_CROSS_FLAGS_USING_VCH = $0008;
  PEB_CROSS_FLAGS_USING_FTH = $0010;
  PEB_CROSS_FLAGS_PREVIOUSLY_THROTTLED = $0020;
  PEB_CROSS_FLAGS_CURRENTLY_THROTTLED = $0040;
  PEB_CROSS_FLAGS_IMAGES_HOT_PATCHED = $0080;

  PebCrossFlagNames: array [0..7] of TFlagName = (
    (Value: PEB_CROSS_FLAGS_IN_JOB; Name: 'In Job'),
    (Value: PEB_CROSS_FLAGS_INITIALIZING; Name: 'Initializing'),
    (Value: PEB_CROSS_FLAGS_USING_VEH; Name: 'Using VEH'),
    (Value: PEB_CROSS_FLAGS_USING_VCH; Name: 'Using VCH'),
    (Value: PEB_CROSS_FLAGS_USING_FTH; Name: 'Using FTH'),
    (Value: PEB_CROSS_FLAGS_PREVIOUSLY_THROTTLED; Name: 'Previously Throttled'),
    (Value: PEB_CROSS_FLAGS_CURRENTLY_THROTTLED; Name: 'Currently Throttled'),
    (Value: PEB_CROSS_FLAGS_IMAGES_HOT_PATCHED; Name: 'Images Hot Patched')
  );

  // PEB.TracingFlags
  TRACING_FLAGS_HEAP_TRACING_ENABLED = $0001;
  TRACING_FLAGS_CRIT_SEC_TRACING_ENABLED = $0002;
  TRACING_FLAGS_LIB_LOADER_TRACING_ENABLED = $00004;

  TracingFlagNames: array [0..2] of TFlagName = (
    (Value: TRACING_FLAGS_HEAP_TRACING_ENABLED; Name: 'Heap Tracing'),
    (Value: TRACING_FLAGS_CRIT_SEC_TRACING_ENABLED; Name: 'Critical Section Tracing'),
    (Value: TRACING_FLAGS_LIB_LOADER_TRACING_ENABLED; Name: 'Lib Loader Tracing')
  );

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

  SameTebFlagNames: array [0..14] of TFlagName = (
    (Value: TEB_SAME_FLAGS_SAFE_THUNK_CALL; Name: 'Safe Thunk Call'),
    (Value: TEB_SAME_FLAGS_IN_DEBUG_PRINT; Name: 'In Debug Print'),
    (Value: TEB_SAME_FLAGS_HAS_FIBER_DATA; Name: 'Has Fiber Data'),
    (Value: TEB_SAME_FLAGS_SKIP_THREAD_ATTACH; Name: 'Skip Thread Attach'),
    (Value: TEB_SAME_FLAGS_WER_IN_SHIP_ASSERT_CODE; Name: 'In Ship Assert Code'),
    (Value: TEB_SAME_FLAGS_RAN_PROCESS_INIT; Name: 'Ran Process Init'),
    (Value: TEB_SAME_FLAGS_CLONED_THREAD; Name: 'Conled Thread'),
    (Value: TEB_SAME_FLAGS_SUPPRESS_DEBUG_MSG; Name: 'Suppress Debug Msg'),
    (Value: TEB_SAME_FLAGS_DISABLE_USER_STACK_WALK; Name: 'Disable User Stack Walk'),
    (Value: TEB_SAME_FLAGS_RTL_EXCEPTION_ATTACHED; Name: 'RTL Exception Attached'),
    (Value: TEB_SAME_FLAGS_INITIAL_THREAD; Name: 'Initial Thread'),
    (Value: TEB_SAME_FLAGS_SESSION_AWARE; Name: 'Session Aware'),
    (Value: TEB_SAME_FLAGS_LOAD_OWNER; Name: 'Load Owner'),
    (Value: TEB_SAME_FLAGS_LOADER_WORKER; Name: 'Loader Worker'),
    (Value: TEB_SAME_FLAGS_SKIP_LOADER_INIT; Name: 'Skip Loader Init')
  );

type
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

  TBitFieldFlagProvider = class (TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

  TCrossPebFlagProvider = class (TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

  TTracingFlagProvider = class (TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

  TPeb = record
    InheritedAddressSpace: Boolean;
    ReadImageFileExecOptions: Boolean;
    BeingDebugged: Boolean;
    [MinOSVersion(OsWin81), Bitwise(TBitFieldFlagProvider)] BitField: Byte;
    Mutant: THandle;
    ImageBaseAddress: Pointer;
    Ldr: PPebLdrData;
    ProcessParameters: PRtlUserProcessParameters;
    SubSystemData: Pointer;
    ProcessHeap: Pointer;
    FastPebLock: Pointer; // WinNt.PRTL_CRITICAL_SECTION
    [volatile] AtlThunkSListPtr: Pointer; // WinNt.PSLIST_HEADER
    IFEOKey: Pointer;
    [Bitwise(TCrossPebFlagProvider)] CrossProcessFlags: Cardinal;
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
    HeapSegmentReserve: NativeUInt;
    HeapSegmentCommit: NativeUInt;
    HeapDecommitTotalFreeThreshold: NativeUInt;
    HeapDecommitFreeBlockThreshold: NativeUInt;

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
    [Hex] ImageSubsystem: Cardinal;
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

    [Hex] AppCompatFlags: TULargeInteger;
    [Hex] AppCompatFlagsUser: TULargeInteger;
    pShimData: Pointer;
    AppCompatInfo: Pointer; // APPCOMPAT_EXE_DATA

    CSDVersion: UNICODE_STRING;

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
    [Bitwise(TTracingFlagProvider)] TracingFlags: Cardinal;
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

  TSameTebFlagProvider = class (TCustomFlagProvider)
    class function Flags: TFlagNames; override;
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
    [MinOSVersion(OsWin10RS3)] ProxiedProcessID: Cardinal;
    [MinOSVersion(OsWin10RS2)] ActivationStack: TActivationContextStack;
    [MinOSVersion(OsWin10RS2)] WorkingOnBehalfTicket: array [0..7] of Byte;
    ExceptionCode: Cardinal;
    ActivationContextStackPointer: PActivationContextStack;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackSp: NativeUInt;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousPc: NativeUInt;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousSp: NativeUInt;

 	{$IFDEF WIN64}
    TxFsContext: Cardinal;
	{$ENDIF}

    [MinOSVersion(OsWin10)] InstrumentationCallbackDisabled: Boolean;

  {$IFDEF WIN64}
    [MinOSVersion(OsWin10RS5)] UnalignedLoadStoreExceptions: Boolean;
	{$ELSE}
    SpareBytes: array [0..22] of Byte;
    TxFsContext: Cardinal;
	{$ENDIF}

    GDITebBatch: TGdiTebBatch;
    RealClientId: TClientId;
    GDICachedProcessHandle: THandle;
    GDIClientPID: Cardinal;
    GDIClientTID: Cardinal;
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
    StaticUnicodeString: UNICODE_STRING;
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

    IdealProcessorValue: Cardinal;

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
    [Bitwise(TSameTebFlagProvider)] SameTebFlags: Word;
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

class function TBitFieldFlagProvider.Flags: TFlagNames;
begin
  Result := Capture(PebBitsNames);
end;

class function TCrossPebFlagProvider.Flags: TFlagNames;
begin
  Result := Capture(PebCrossFlagNames);
end;

class function TTracingFlagProvider.Flags: TFlagNames;
begin
  Result := Capture(TracingFlagNames);
end;

class function TSameTebFlagProvider.Flags: TFlagNames;
begin
  Result := Capture(SameTebFlagNames);
end;

{$IFDEF WIN64}
function NtCurrentTeb: PTeb;
asm
  mov rax, gs:[$0030]
end;
{$ENDIF}

{$IFDEF WIN32}
function NtCurrentTeb: PTeb;
asm
  mov eax, fs:[$0018]
end;
{$ENDIF}

{$IFDEF Win32}
function RtlIsWoW64: Boolean;
begin
  Result := NtCurrentTeb.WowTebOffset <> 0;
end;
{$ENDIF}

end.
