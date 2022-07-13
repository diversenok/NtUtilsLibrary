unit Ntapi.ntwow64;

{
  This file defines 32-bit structures for using under WoW64.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntldr, Ntapi.ntpebteb, Ntapi.ntrtl,
  Ntapi.ImageHlp, Ntapi.Versions, DelphiApi.Reflection;

type
  // A wrapper for a 32-bit (WoW64) pointer
  Wow64Pointer<P> = record // P should be a pointer type
    Value: Cardinal;
    function Self: P;
    class operator Implicit(Source: Pointer): Wow64Pointer<P>;
    class operator Implicit(Source: Wow64Pointer<P>): P;
    class operator Implicit(Source: Wow64Pointer<P>): Pointer;
  end;

  // Untyped WoW64 pointer
  Wow64Pointer = Wow64Pointer<Pointer>;

  Wow64UInt = Cardinal;
  Wow64Handle = Cardinal;

  // PHNT::phnt_ntdef.h
  [SDKName('CLIENT_ID32')]
  TClientId32 = record
    UniqueProcess: TProcessId32;
    UniqueThread: TThreadId32;
  end;
  PClientId32 = ^TClientId32;

  // PHNT::phnt_ntdef.h
  PNtUnicodeString32 = ^TNtUnicodeString32;
  [SDKName('UNICODE_STRING32')]
  TNtUnicodeString32 = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: Wow64Pointer<PWideChar>;
    class function RequiredSize(const Source: String): NativeUInt; static;
    class function From(const Source: String): TNtUnicodeString32; static;
    class procedure Marshal(Source: String; Target: PNtUnicodeString32;
      VariablePart: PWideChar = nil); static;

    // Marshal a string to a buffer and adjust pointers for remote access
    class procedure MarshalEx(
      Source: String;
      LocalAddress: PNtUnicodeString32;
      RemoteAddress: Pointer = nil;
      VariableOffset: Cardinal = 0
    ); static;
  end;

  // PHNT::phnt_ntdef.h
  [SDKName('ANSI_STRING32')]
  TNtAnsiString32 = record
    [Bytes] Length: Word;
    [Bytes] MaximumLength: Word;
    Buffer: Wow64Pointer<PAnsiChar>;
  end;

  // SDK::winnt.h
  PListEntry32 = ^TListEntry32;
  [SDKName('LIST_ENTRY32')]
  TListEntry32 = record
    Flink: Wow64Pointer<PListEntry32>;
    Blink: Wow64Pointer<PListEntry32>;
  end;

  // SDK::winnt.h
  PNtTib32 = ^TNtTib32;
  [SDKName('NT_TIB32')]
  TNtTib32 = record
    ExceptionList: Wow64Pointer;
    StackBase: Wow64Pointer;
    StackLimit: Wow64Pointer;
    SubSystemTib: Wow64Pointer;
    FiberData: Wow64Pointer;
    ArbitraryUserPointer: Wow64Pointer;
    Self: Wow64Pointer<PNtTib32>;
  end;

  // PHNT::ntwow64.h
  [SDKName('GDI_TEB_BATCH32')]
  TGdiTebBatch32 = record
    Offset: Cardinal;
    HDC: Wow64UInt;
    Buffer: array [0..309] of Cardinal;
  end;

  // PHNT::ntwow64.h
  PRtlBalancedNode32 = ^TRtlBalancedNode32;
  [SDKName('RTL_BALANCED_NODE32')]
  TRtlBalancedNode32 = record
    Left: Wow64Pointer<PRtlBalancedNode32>;
    Right: Wow64Pointer<PRtlBalancedNode32>;
    ParentValue: Wow64UInt;
  end;

  // PHNT::ntwow64.h
  [SDKName('PEB_LDR_DATA32')]
  TPebLdrData32 = record
    Length: Cardinal;
    Initialized: Boolean;
    SsHandle: Wow64Handle;
    InLoadOrderModuleList: TListEntry32;
    InMemoryOrderModuleList: TListEntry32;
    InInitializationOrderModuleList: TListEntry32;
    EntryInProgress: Wow64Pointer;
    ShutdownInProgress: Boolean;
    ShutdownThreadId: Wow64UInt;
  end;
  PPebLdrData32 = ^TPebLdrData32;

  // PHNT::ntwow64.h
  [SDKName('LDR_DATA_TABLE_ENTRY32')]
  TLdrDataTableEntry32 = record
    InLoadOrderLinks: TListEntry32;
    InMemoryOrderLinks: TListEntry32;
    InInitializationOrderLinks: TListEntry32;
    DllBase: Wow64Pointer<PDllBase>;
    EntryPoint: Wow64Pointer;
    [Bytes] SizeOfImage: Cardinal;
    FullDllName: TNtUnicodeString32;
    BaseDllName: TNtUnicodeString32;
    [Hex] Flags: Cardinal; // LDRP_*
    ObsoleteLoadCount: Word;
    TlsIndex: Word;
    HashLinks: TListEntry32;
    TimeDateStamp: TUnixTime;
    EntryPointActivationContext: Wow64Pointer;
    Lock: Wow64Pointer;
    DdagNode: Wow64Pointer; // PLdrDdagNode32
    NodeModuleLink: TListEntry;
    LoadContext: Wow64Pointer;
    ParentDllBase: Wow64Pointer<PDllBase>;
    SwitchBackContext: Wow64Pointer;
    BaseAddressIndexNode: TRtlBalancedNode32;
    MappingInfoIndexNode: TRtlBalancedNode32;
    [Hex] OriginalBase: Wow64UInt;
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

  // PHNT::ntwow64.h
  [SDKName('CURDIR32')]
  TCurDir32 = record
    DosPath: TNtUnicodeString32;
    Handle: Wow64Handle;
  end;
  PCurDir32 = ^TCurDir32;

  // PHNT::ntwow64.h
  [SDKName('RTL_DRIVE_LETTER_CURDIR32')]
  TRtlDriveLetterCurDir32 = record
    [Hex] Flags: Word;
    [Bytes] Length: Word;
    TimeStamp: TUnixTime;
    DosPath: TNtAnsiString32;
  end;
  PRtlDriveLetterCurDir32 = ^TRtlDriveLetterCurDir32;

  TCurrentDirectories32 = array [0..RTL_MAX_DRIVE_LETTERS - 1] of
      TRtlDriveLetterCurDir32;

  // PHNT::ntwow64.h
  [SDKName('RTL_USER_PROCESS_PARAMETERS32')]
  TRtlUserProcessParameters32 = record
    [Bytes, Unlisted] MaximumLength: Cardinal;
    [Bytes, Unlisted] Length: Cardinal;

    Flags: TRtlUserProcessFlags;
    [Hex] DebugFlags: Cardinal;

    ConsoleHandle: Wow64Handle;
    [Hex] ConsoleFlags: Cardinal;
    StandardInput: Wow64Handle;
    StandardOutput: Wow64Handle;
    StandardError: Wow64Handle;

    CurrentDirectory: TCurDir32;
    DLLPath: TNtUnicodeString32;
    ImagePathName: TNtUnicodeString32;
    CommandLine: TNtUnicodeString32;
    [volatile] Environment: Wow64Pointer<PEnvironment>;

    StartingX: Cardinal;
    StartingY: Cardinal;
    CountX: Cardinal;
    CountY: Cardinal;
    CountCharsX: Cardinal;
    CountCharsY: Cardinal;
    FillAttribute: Cardinal; // ConsoleApi.TConsoleFill

    WindowFlags: Cardinal; // ProcessThreadsApi.TStarupFlags
    ShowWindowFlags: Cardinal; // WinUser.TShowMode
    WindowTitle: TNtUnicodeString32;
    DesktopInfo: TNtUnicodeString32;
    ShellInfo: TNtUnicodeString32;
    RuntimeData: TNtUnicodeString32;
    CurrentDirectories: TCurrentDirectories32;

    [Bytes, volatile] EnvironmentSize: Cardinal;
    EnvironmentVersion: Cardinal;
    [MinOSVersion(OsWin8)] PackageDependencyData: Wow64Pointer;
    [MinOSVersion(OsWin8)] ProcessGroupID: Cardinal;
    [MinOSVersion(OsWin10TH1)] LoaderThreads: Cardinal;

    [MinOSVersion(OsWin10RS5)] RedirectionDLLName: TNtUnicodeString32;
    [MinOSVersion(OsWin1019H1)] HeapPartitionName: TNtUnicodeString32;
    [MinOSVersion(OsWin1019H1)] DefaultThreadPoolCPUSetMasks: Cardinal;
    [MinOSVersion(OsWin1019H1)] DefaultThreadPoolCPUSetMaskCount: Cardinal;
  end;
  PRtlUserProcessParameters32 = ^TRtlUserProcessParameters32;

  // PHNT::ntwow64.h
  [SDKName('PEB32')]
  TPeb32 = record
    InheritedAddressSpace: Boolean;
    ReadImageFileExecOptions: Boolean;
    BeingDebugged: Boolean;
    [MinOSVersion(OsWin81)] BitField: TPebBitField;
    Mutant: Wow64Handle;
    ImageBaseAddress: Wow64Pointer;
    Ldr: Wow64Pointer<PPebLdrData32>;
    ProcessParameters: Wow64Pointer<PRtlUserProcessParameters32>;
    SubSystemData: Wow64Pointer;
    ProcessHeap: Wow64Pointer;
    FastPebLock: Wow64Pointer; // WinNt.PRTL_CRITICAL_SECTION
    [volatile] AtlThunkSListPtr: Wow64Pointer; // WinNt.PSLIST_HEADER
    IFEOKey: Wow64Pointer;
    CrossProcessFlags: TPebCrossFlags;
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
    ImageSubsystem: TImageSubsystem;
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

    CSDVersion: TNtUnicodeString32;

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
    TracingFlags: TPebTracingFlags;
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

  // PHNT::ntwow64.h
  [SDKName('TEB32')]
  TTeb32 = record
    NtTib: TNtTib32;

    EnvironmentPointer: Wow64Pointer;
    ClientID: TClientId32;
    ActiveRpcHandle: Wow64Pointer;
    ThreadLocalStoragePointer: Wow64Pointer;
    ProcessEnvironmentBlock: Wow64Pointer<PPeb32>;

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
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackSp: Wow64UInt;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousPc: Wow64UInt;
    [MinOSVersion(OsWin10TH1), Hex] InstrumentationCallbackPreviousSp: Wow64UInt;
    [MinOSVersion(OsWin10)] InstrumentationCallbackDisabled: Boolean;
    SpareBytes: array [0..22] of Byte;
    TxFsContext: Cardinal;

    GDITebBatch: TGdiTebBatch32;
    RealClientId: TClientId32;
    GDICachedProcessHandle: Wow64Pointer;
    GDIClientPID: TProcessId32;
    GDIClientTID: TThreadId32;
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
    StaticUnicodeString: TNtUnicodeString32;
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
    CurrentTransactionHandle: Wow64Handle;
    ActiveFrame: Wow64Pointer;
    FlsData: Wow64Pointer;

    PreferredLanguages: Wow64Pointer;
    UserPrefLanguages: Wow64Pointer;
    MergedPrefLanguages: Wow64Pointer;
    MUIImpersonation: Cardinal;
    [Hex] CrossTebFlags: Word;
    SameTebFlags: TTebSameTebFlags;
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

  TJobObjectBasicProcessIdList32 = record
    NumberOfAssignedProcesses: Cardinal;
    [Counter] NumberOfProcessIdsInList: Cardinal;
    ProcessIdList: TAnysizeArray<TProcessId32>;
  end;
  PJobObjectBasicProcessIdList32 = ^TJobObjectBasicProcessIdList32;

  TRtlUnloadEventTrace32 = record
    BaseAddress: Wow64Pointer;
    [Bytes] SizeOfImage: Wow64UInt;
    Sequence: Cardinal;
    TimeDateStamp: TUnixTime;
    [Hex] CheckSum: Cardinal;
    ImageName: TRtlUnloadEventImageName;
    Version: TRtlUnloadEventVersion;
  end;
  PRtlUnloadEventTrace32 = ^TRtlUnloadEventTrace32;
  PPRtlUnloadEventTrace32 = ^PRtlUnloadEventTrace32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Wow64Pointer<P> }

class operator Wow64Pointer<P>.Implicit(Source: Pointer): Wow64Pointer<P>;
begin
  Result.Value := Cardinal(Source);
end;

class operator Wow64Pointer<P>.Implicit(Source: Wow64Pointer<P>): P;
var
  ResultValue: Pointer absolute Result;
begin
  ResultValue := Pointer(Source.Value);
end;

class operator Wow64Pointer<P>.Implicit(Source: Wow64Pointer<P>): Pointer;
begin
  Result := Pointer(Source.Value);
end;

function Wow64Pointer<P>.Self;
var
  ResultValue: Pointer absolute Result;
begin
  ResultValue := Pointer(Value);
end;

{ TNtUnicodeString32 }

class function TNtUnicodeString32.From;
begin
  Result.Buffer := PWideChar(Source);
  Result.Length := System.Length(Source) * SizeOf(WideChar);
  Result.MaximumLength := Result.Length + SizeOf(WideChar);
end;

class procedure TNtUnicodeString32.Marshal;
begin
  Target.Length := System.Length(Source) * SizeOf(WideChar);
  Target.MaximumLength := Target.Length + SizeOf(WideChar);

  if not Assigned(VariablePart) then
    VariablePart := Pointer(UIntPtr(Target) + SizeOf(TNtUnicodeString32));

  Target.Buffer := VariablePart;
  Move(PWideChar(Source)^, VariablePart^, Target.MaximumLength);
end;

class procedure TNtUnicodeString32.MarshalEx;
begin
  if VariableOffset = 0 then
    VariableOffset := SizeOf(TNtUnicodeString32);

  LocalAddress.Length := System.Length(Source) * SizeOf(WideChar);
  LocalAddress.MaximumLength := LocalAddress.Length + SizeOf(WideChar);
  LocalAddress.Buffer := Pointer(UIntPtr(RemoteAddress) + VariableOffset);

  Move(PWideChar(Source)^, Pointer(UIntPtr(LocalAddress) + VariableOffset)^,
    LocalAddress.MaximumLength);
end;

class function TNtUnicodeString32.RequiredSize;
begin
  Result := SizeOf(TNtUnicodeString32) +
    Succ(System.Length(Source)) * SizeOf(WideChar);
end;

end.
