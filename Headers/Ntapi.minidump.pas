unit Ntapi.minidump;

{
  This file includes definitions for creating and parsing memory minidumps.
}

interface

{$MINENUMSIZE 4}
{$ALIGN 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.DbgHelp, Ntapi.ntioapi, Ntapi.ntseapi,
  Ntapi.ntmmapi, DelphiApi.Reflection;

const
  // SDK::minidumpapiset.h
  MINIDUMP_SIGNATURE = $504D444D; // 'MDMP'
  MINIDUMP_VERSION = 42899;

  // SDK::minidumpapiset.h
  MiniDumpNormal = $00000000;
  MiniDumpWithDataSegs = $00000001;
  MiniDumpWithFullMemory = $00000002;
  MiniDumpWithHandleData = $00000004;
  MiniDumpFilterMemory = $00000008;
  MiniDumpScanMemory = $00000010;
  MiniDumpWithUnloadedModules = $00000020;
  MiniDumpWithIndirectlyReferencedMemory = $00000040;
  MiniDumpFilterModulePaths = $00000080;
  MiniDumpWithProcessThreadData = $00000100;
  MiniDumpWithPrivateReadWriteMemory = $00000200;
  MiniDumpWithoutOptionalData = $00000400;
  MiniDumpWithFullMemoryInfo = $00000800;
  MiniDumpWithThreadInfo = $00001000;
  MiniDumpWithCodeSegs = $00002000;
  MiniDumpWithoutAuxiliaryState = $00004000;
  MiniDumpWithFullAuxiliaryState = $00008000;
  MiniDumpWithPrivateWriteCopyMemory = $00010000;
  MiniDumpIgnoreInaccessibleMemory = $00020000;
  MiniDumpWithTokenInformation = $00040000;
  MiniDumpWithModuleHeaders = $00080000;
  MiniDumpFilterTriage = $00100000;
  MiniDumpWithAvxXStateContext = $00200000;
  MiniDumpWithIptTrace = $00400000;
  MiniDumpScanInaccessiblePartialPages = $00800000;
  MiniDumpFilterWriteCombinedMemory = $01000000;

  // SDK::avrfsdk.h
  AVRF_MAX_TRACES = 32;

  // SDK::minidumpapiset.h, misc info stream flags
  MINIDUMP_MISC1_PROCESS_ID = $00000001;
  MINIDUMP_MISC1_PROCESS_TIMES = $00000002;
  MINIDUMP_MISC1_PROCESSOR_POWER_INFO = $00000004;
  MINIDUMP_MISC3_PROCESS_INTEGRITY = $00000010;
  MINIDUMP_MISC3_PROCESS_EXECUTE_FLAGS = $00000020;
  MINIDUMP_MISC3_TIMEZONE = $00000040;
  MINIDUMP_MISC3_PROTECTED_PROCESS = $00000080;
  MINIDUMP_MISC4_BUILDSTRING = $00000100;
  MINIDUMP_MISC5_PROCESS_COOKIE = $00000200;

  // SDK::minidumpapiset.h, thread info flags
  MINIDUMP_THREAD_INFO_ERROR_THREAD = $00000001;
  MINIDUMP_THREAD_INFO_WRITING_THREAD = $00000002;
  MINIDUMP_THREAD_INFO_EXITED_THREAD = $00000004;
  MINIDUMP_THREAD_INFO_INVALID_INFO = $00000008;
  MINIDUMP_THREAD_INFO_INVALID_CONTEXT = $00000010;
  MINIDUMP_THREAD_INFO_INVALID_TEB = $00000020;

  // SDK::minidumpapiset.h, system information flags
  MINIDUMP_SYSMEMINFO1_FILECACHE_TRANSITIONREPURPOSECOUNT_FLAGS = $0001;
  MINIDUMP_SYSMEMINFO1_BASICPERF = $0002;
  MINIDUMP_SYSMEMINFO1_PERF_CCTOTALDIRTYPAGES_CCDIRTYPAGETHRESHOLD = $0004;
  MINIDUMP_SYSMEMINFO1_PERF_RESIDENTAVAILABLEPAGES_SHAREDCOMMITPAGES = $0008;

  // SDK::minidumpapiset.h, process VM counter flags
  MINIDUMP_PROCESS_VM_COUNTERS = $0001;
  MINIDUMP_PROCESS_VM_COUNTERS_VIRTUALSIZE = $0002;
  MINIDUMP_PROCESS_VM_COUNTERS_EX = $0004;
  MINIDUMP_PROCESS_VM_COUNTERS_EX2 = $0008;
  MINIDUMP_PROCESS_VM_COUNTERS_JOB = $0010;

  // SDK::minidumpapiset.h, thread write flags
  ThreadWriteThread = $0001;
  ThreadWriteStack = $0002;
  ThreadWriteContext = $0004;
  ThreadWriteBackingStore = $0008;
  ThreadWriteInstructionWindow = $0010;
  ThreadWriteThreadData = $0020;
  ThreadWriteThreadInfo = $0040;

  // SDK::minidumpapiset.h, module write flags
  ModuleWriteModule = $0001;
  ModuleWriteDataSeg = $0002;
  ModuleWriteMiscRecord = $0004;
  ModuleWriteCvRecord = $0008;
  ModuleReferencedByMemory = $0010;
  ModuleWriteTlsData = $0020;
  ModuleWriteCodeSegs = $0040;

  // SDK::minidumpapiset.h, secondary flags
  MiniSecondaryWithoutPowerInfo = $00000001;

type
  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_LOCATION_DESCRIPTOR')]
  TMiniDumpLocationDescriptor = record
    [Bytes] DataSize: Cardinal;
    [Hex] Rva: Cardinal;
  end;
  PMiniDumpLocationDescriptor = ^TMiniDumpLocationDescriptor;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_LOCATION_DESCRIPTOR64')]
  TMiniDumpLocationDescriptor64 = record
    [Bytes] DataSize: UInt64;
    [Hex] Rva: UInt64;
  end;
  PMiniDumpLocationDescriptor64 = ^TMiniDumpLocationDescriptor64;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_MEMORY_DESCRIPTOR')]
  TMiniDumpMemoryDescriptor = record
    [Hex] StartOfMemoryRange: UInt64;
    Memory: TMiniDumpLocationDescriptor;
  end;
  PMiniDumpMemoryDescriptor = ^TMiniDumpMemoryDescriptor;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_MEMORY_DESCRIPTOR64')]
  TMiniDumpMemoryDescriptor64 = record
    [Hex] StartOfMemoryRange: UInt64;
    [Bytes] DataSize: UInt64;
  end;
  PMiniDumpMemoryDescriptor64 = ^TMiniDumpMemoryDescriptor64;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_TYPE')]
  [FlagName(MiniDumpWithDataSegs, 'With Data Segments')]
  [FlagName(MiniDumpWithFullMemory, 'With Full Memory')]
  [FlagName(MiniDumpWithHandleData, 'With Handle Data')]
  [FlagName(MiniDumpFilterMemory, 'Filter Memory')]
  [FlagName(MiniDumpScanMemory, 'Scan Memory')]
  [FlagName(MiniDumpWithUnloadedModules, 'With Unloaded Modules')]
  [FlagName(MiniDumpWithIndirectlyReferencedMemory, 'With Indirectly Referenced Memory')]
  [FlagName(MiniDumpFilterModulePaths, 'Filter Module Paths')]
  [FlagName(MiniDumpWithProcessThreadData, 'With Process Thread Data')]
  [FlagName(MiniDumpWithPrivateReadWriteMemory, 'With Private RW Memory')]
  [FlagName(MiniDumpWithoutOptionalData, 'Without Optional Data')]
  [FlagName(MiniDumpWithFullMemoryInfo, 'With Full Memory Info')]
  [FlagName(MiniDumpWithThreadInfo, 'With Thread Info')]
  [FlagName(MiniDumpWithCodeSegs, 'With Code Segments')]
  [FlagName(MiniDumpWithoutAuxiliaryState, 'Without Auxiliary State')]
  [FlagName(MiniDumpWithFullAuxiliaryState, 'With Full Auxiliary State')]
  [FlagName(MiniDumpWithPrivateWriteCopyMemory, 'With Private WC Memory')]
  [FlagName(MiniDumpIgnoreInaccessibleMemory, 'Ignore Inaccessible Memory')]
  [FlagName(MiniDumpWithTokenInformation, 'With Token Information')]
  [FlagName(MiniDumpWithModuleHeaders, 'With Module Headers')]
  [FlagName(MiniDumpFilterTriage, 'Filter Triage')]
  [FlagName(MiniDumpWithAvxXStateContext, 'With AvxX State Context')]
  [FlagName(MiniDumpWithIptTrace, 'With IPT Trace')]
  [FlagName(MiniDumpScanInaccessiblePartialPages, 'Scan Inaccessible Partial Pages')]
  [FlagName(MiniDumpFilterWriteCombinedMemory, 'Filter Write Combined Memory')]
  TMiniDumpType = type Cardinal;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_HEADER')]
  TMiniDumpHeader = record
    [Reserved(MINIDUMP_SIGNATURE)] Signature: Cardinal;
    [Reserved(MINIDUMP_VERSION)] Version: Word;
    [Counter(ctElements)] NumberOfStreams: Cardinal;
    [Hex] StreamDirectoryRva: Cardinal; // to TAnysizeArray<TMiniDumpDirectory>
    [Hex] CheckSum: Cardinal;
    TimeDateStamp: TUnixTime;
    FlagsLow: TMiniDumpType;
    [Hex] FlagsHigh: Cardinal;
  end;
  PMiniDumpHeader = ^TMiniDumpHeader;

  // SDK::minidumpapiset.h
  {$SCOPEDENUMS ON}
  [SDKName('MINIDUMP_STREAM_TYPE')]
  [NamingStyle(nsCamelCase), ValidMask($1FFFFF9)]
  TMiniDumpStreamType = (
    UnusedStream = 0,
    ReservedStream0 = 1,
    ReservedStream1 = 2,
    ThreadListStream = 3,           // TMiniDumpThreadList
    ModuleListStream = 4,           // TMiniDumpModuleList
    MemoryListStream = 5,           // TMiniDumpMemoryList
    ExceptionStream = 6,            // TMiniDumpExceptionStream
    SystemInfoStream = 7,           // TMiniDumpSystemInfo
    ThreadExListStream = 8,         // TMiniDumpThreadExList
    Memory64ListStream = 9,         // TMiniDumpMemory64List
    CommentStreamA = 10,            // TAnysizeArray<AnsiChar>
    CommentStreamW = 11,            // TAnysizeArray<WideChar>
    HandleDataStream = 12,          // TMiniDumpHandleDataStream
    FunctionTableStream = 13,       // TMiniDumpFunctionTableStream
    UnloadedModuleListStream = 14,  // TMiniDumpUnloadedModuleList
    MiscInfoStream = 15,            // TMiniDumpMiscInfoN
    MemoryInfoListStream = 16,      // TMiniDumpMemoryInfoList
    ThreadInfoListStream = 17,      // TMiniDumpThreadInfoList
    HandleOperationListStream = 18, // TMiniDumpHandleOprtationList
    TokenStream = 19,               // TMiniDumpTokenInfoList
    JavaScriptDataStream = 20,
    SystemMemoryInfoStream = 21,    // TMiniDumpSystemMemoryInfoN
    ProcessVmCountersStream = 22,   // TMiniDumpProcessVmCounters*
    IptTraceStream = 23,
    ThreadNamesStream = 24          // TMiniDumpThreadNameList
  );
  {$SCOPEDENUMS OFF}

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_DIRECTORY')]
  TMiniDumpDirectory = record
    StreamType: TMiniDumpStreamType;
    Location: TMiniDumpLocationDescriptor;
  end;
  PMiniDumpDirectory = ^TMiniDumpDirectory;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_STRING')]
  TMiniDumpString = record
    [Counter(ctBytes)] Length: Cardinal;
    Buffer: TAnysizeArray<WideChar>;
  end;
  PMiniDumpString = ^TMiniDumpString;

  { Stream type 3 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_THREAD')]
  TMiniDumpThread = record
    ThreadId: TThreadId32;
    SuspendCount: Cardinal;
    PriorityClass: Cardinal;
    Priority: Cardinal;
    [Hex] Teb: UInt64;
    Stack: TMiniDumpMemoryDescriptor;
    ThreadContext: TMiniDumpLocationDescriptor;
  end;
  PMiniDumpThread = ^TMiniDumpThread;

  // SDK::minidumpapiset.h, stream type 3
  [SDKName('MINIDUMP_THREAD_LIST')]
  TMiniDumpThreadList = record
    [Counter(ctElements)] NumberOfThreads: Cardinal;
    Threads: TAnysizeArray<TMiniDumpThread>;
  end;
  PMiniDumpThreadList = ^TMiniDumpThreadList;

  { Stream type 4 }

  // SDK::verrsrc.h
  [SDKName('VS_FIXEDFILEINFO')]
  TVsFixedFileInfo = record
    [Hex] Signature: Cardinal;
    [Hex] StrucVersion: Cardinal;
    [Hex] FileVersionMS: Cardinal;
    [Hex] FileVersionLS: Cardinal;
    [Hex] ProductVersionMS: Cardinal;
    [Hex] ProductVersionLS: Cardinal;
    [Hex] FileFlagsMask: Cardinal;
    [Hex] FileFlags: Cardinal;
    [Hex] FileOS: Cardinal;
    [Hex] FileType: Cardinal;
    [Hex] FileSubtype: Cardinal;
    [Hex] FileDateMS: Cardinal;
    [Hex] FileDateLS: Cardinal;
  end;
  PVsFixedFileInfo = ^TVsFixedFileInfo;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_MODULE')]
  TMiniDumpModule = record
    [Hex] BaseOfImage: UInt64;
    [Bytes] SizeOfImage: Cardinal;
    [Hex] CheckSum: Cardinal;
    TimeDateStamp: TUnixTime;
    [Hex] ModuleNameRva: Cardinal;
    VersionInfo: TVsFixedFileInfo;
    CvRecord: TMiniDumpLocationDescriptor;
    MiscRecord: TMiniDumpLocationDescriptor;
    [Unlisted] Reserved0: UInt64;
    [Unlisted] Reserved1: UInt64;
  end;
  PMiniDumpModule = ^TMiniDumpModule;

  // SDK::minidumpapiset.h, stream type 4
  [SDKName('MINIDUMP_MODULE_LIST')]
  TMiniDumpModuleList = record
    [Counter(ctElements)] NumberOfModules: Cardinal;
    Modules: TAnysizeArray<TMiniDumpModule>;
  end;
  PMiniDumpModuleList = ^TMiniDumpModuleList;

  { Stream type 5 }

  // SDK::minidumpapiset.h, stream type 5
  [SDKName('MINIDUMP_MEMORY_LIST')]
  TMiniDumpMemoryList = record
    [Counter(ctElements)] NumberOfMemoryRanges: Cardinal;
    MemoryRanges: TAnysizeArray<TMiniDumpMemoryDescriptor>;
  end;
  PMiniDumpMemoryList = ^TMiniDumpMemoryList;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_EXCEPTION')]
  TMiniDumpException = record
    ExceptionCode: NTSTATUS;
    ExceptionFlags: TExceptionFlags;
    [Hex] ExceptionRecord: UInt64;
    ExceptionAddress: UInt64;
    NumberParameters: Cardinal;
    [Unlisted] __unusedAlignment: Cardinal;
    ExceptionInformation: array [0..EXCEPTION_MAXIMUM_PARAMETERS - 1] of UInt64;
  end;
  PMiniDumpException = ^TMiniDumpException;

  { Stream type 6 }

  // SDK::minidumpapiset.h, stream type 6
  [SDKName('MINIDUMP_EXCEPTION_STREAM')]
  TMiniDumpExceptionStream = record
    ThreadId: TThreadId32;
    [Unlisted] __alignment: Cardinal;
    ExceptionRecord: TMiniDumpException;
    ThreadContext: TMiniDumpLocationDescriptor;
  end;
  PMiniDumpExceptionStream = ^TMiniDumpExceptionStream;

  { Stream type 7 }

  // SDK::minidumpapiset.h
  [SDKName('CPU_INFORMATION')]
  TCpuInformation = record
  case Integer of
    86: (
      VendorId: array [0..2] of Cardinal;
      VersionInformation: Cardinal;
      FeatureInformation: Cardinal;
      AMDExtendedCpuFeatures: Cardinal;
    );

    0: (
      ProcessorFeatures: array [0..2] of UInt64;
    );
  end;
  PCpuInformation = ^TCpuInformation;

  // SDK::minidumpapiset.h, stream type 7
  [SDKName('MINIDUMP_SYSTEM_INFO')]
  TMiniDumpSystemInfo = record
    ProcessorArchitecture: Word;
    ProcessorLevel: Word;
    ProcessorRevision: Word;
    NumberOfProcessors: Byte;
    ProductType: Byte;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    BuildNumber: Cardinal;
    PlatformId: Cardinal;
    [Hex] CSDVersionRva: Cardinal;
    SuiteMask: Word;
    Reserved2: Word;
    Cpu: TCpuInformation;
  end;
  PMiniDumpSystemInfo = ^TMiniDumpSystemInfo;

  { Stream type 8 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_THREAD_EX')]
  TMiniDumpThreadEx = record
    [Aggregate] Basic: TMiniDumpThread;
    BackingStore: TMiniDumpMemoryDescriptor;
  end;
  PMiniDumpThreadEx = ^TMiniDumpThreadEx;

  // SDK::minidumpapiset.h, stream type 8
  [SDKName('MINIDUMP_THREAD_EX_LIST')]
  TMiniDumpThreadExList = record
    [Counter(ctElements)] NumberOfThreads: Cardinal;
    Threads: TAnysizeArray<TMiniDumpThreadEx>;
  end;
  PMiniDumpThreadExList = ^TMiniDumpThreadExList;

  { Stream type 9 }

  // SDK::minidumpapiset.h, stream type 9
  [SDKName('MINIDUMP_MEMORY64_LIST')]
  TMiniDumpMemory64List = record
    [Counter(ctElements)] NumberOfMemoryRanges: UInt64;
    [Hex] BaseRva: UInt64;
    MemoryRanges: TAnysizeArray<TMiniDumpMemoryDescriptor64>;
  end;
  PMiniDumpMemory64List = ^TMiniDumpMemory64List;

  { Stream type 12 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_HANDLE_DESCRIPTOR')]
  TMiniDumpHandleDescriptor = record
    Handle: UInt64;
    [Hex] TypeNameRva: Cardinal;   // to TMiniDumpString
    [Hex] ObjectNameRva: Cardinal; // to TMiniDumpString
    Attributes: TObjectAttributesFlags;
    GrantedAccess: TAccessMask;
    HandleCount: Cardinal;
    PointerCount: Cardinal;
  end;
  PMiniDumpHandleDescriptor = ^TMiniDumpHandleDescriptor;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_HANDLE_OBJECT_INFORMATION_TYPE')]
  [NamingStyle(nsCamelCase, 'Mini')]
  TMiniDumpHandleObjectInformationType = (
    MiniHandleObjectInformationNone = 0,
    MiniThreadInformation1 = 1,
    MiniMutantInformation1 = 2,
    MiniMutantInformation2 = 3,
    MiniProcessInformation1 = 4,
    MiniProcessInformation2 = 5,
    MiniEventInformation1 = 6,
    MiniSectionInformation1 = 7,
    MiniSemaphoreInformation1 = 8
  );

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_HANDLE_OBJECT_INFORMATION')]
  TMiniDumpHandleObjectInformation = record
    [Hex] NextInfoRva: Cardinal;
    InfoType: TMiniDumpHandleObjectInformationType;
    [Bytes] SizeOfInfo: Cardinal;
    RawInformation: TPlaceholder deprecated;
  end;
  PMiniDumpHandleObjectInformation = ^TMiniDumpHandleObjectInformation;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_HANDLE_DESCRIPTOR_2')]
  TMiniDumpHandleDescriptor2 = record
    [Aggregate] V1: TMiniDumpHandleDescriptor;
    [Hex] ObjectInfoRva: Cardinal; // to TMiniDumpHandleObjectInformation
    [Unlisted] Reserved0: Cardinal;
  end;
  PMiniDumpHandleDescriptor2 = ^TMiniDumpHandleDescriptor2;

  // SDK::minidumpapiset.h, stream type 12
  [SDKName('MINIDUMP_HANDLE_DATA_STREAM')]
  TMiniDumpHandleDataStream = record
    [Bytes] SizeOfHeader: Cardinal;
    [Bytes] SizeOfDescriptor: Cardinal;
    NumberOfDescriptors: Cardinal;
    [Unlisted] Reserved: Cardinal;
    RawInformation: TPlaceholder<TMiniDumpHandleDescriptor2> deprecated;
  end;
  PMiniDumpHandleDataStream = ^TMiniDumpHandleDataStream;

  { Stream type 13 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_FUNCTION_TABLE_DESCRIPTOR')]
  TMiniDumpFunctionTableDescriptor = record
    [Hex] MinimumAddress: UInt64;
    [Hex] MaximumAddress: UInt64;
    [Hex] BaseAddress: UInt64;
    EntryCount: Cardinal;
    [Bytes] SizeOfAlignPad: Cardinal;
  end;
  PMiniDumpFunctionTableDescriptor = ^TMiniDumpFunctionTableDescriptor;

  // SDK::minidumpapiset.h, stream type 13
  [SDKName('MINIDUMP_FUNCTION_TABLE_STREAM')]
  TMiniDumpFunctionTableStream = record
    [Bytes] SizeOfHeader: Cardinal;
    [Bytes] SizeOfDescriptor: Cardinal;
    [Bytes] SizeOfNativeDescriptor: Cardinal;
    [Bytes] SizeOfFunctionEntry: Cardinal;
    NumberOfDescriptors: Cardinal;
    [Bytes] SizeOfAlignPad: Cardinal;
    RawInformation: TPlaceholder<TMiniDumpFunctionTableDescriptor> deprecated;
  end;
  PMiniDumpFunctionTableStream = ^TMiniDumpFunctionTableStream;

  { Stream type 14 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_UNLOADED_MODULE')]
  TMiniDumpUnloadedModule = record
    [Hex] BaseOfImage: UInt64;
    [Bytes] SizeOfImage: Cardinal;
    [Hex] CheckSum: Cardinal;
    TimeDateStamp: TUnixTime;
    [Hex] ModuleNameRva: Cardinal; // to TMiniDumpString
  end;
  PMiniDumpUnloadedModule = ^TMiniDumpUnloadedModule;

  // SDK::minidumpapiset.h, stream type 14
  [SDKName('MINIDUMP_UNLOADED_MODULE_LIST')]
  TMiniDumpUnloadedModuleList = record
    [Bytes] SizeOfHeader: Cardinal;
    [Bytes] SizeOfEntry: Cardinal;
    NumberOfEntries: Cardinal;
    RawInformation: TPlaceholder<TMiniDumpUnloadedModule> deprecated;
  end;
  PMiniDumpUnloadedModuleList = ^TMiniDumpUnloadedModuleList;

  { Stream type 15 }

  // SDK::WTypesbase.h
  [SDKName('SYSTEMTIME')]
  TSystemTime = record
    Year: Word;
    Month: Word;
    DayOfWeek: Word;
    Day: Word;
    Hour: Word;
    Minute: Word;
    Second: Word;
    Milliseconds: Word;
  end;
  PSystemTime = ^TSystemTime;

  // SDK::timezoneapi.h
  [SDKName('TIME_ZONE_INFORMATION')]
  TTimeZoneInformation = record
    Bias: Integer;
    StandardName: array [0..31] of WideChar;
    StandardDate: TSystemTime;
    StandardBias: Integer;
    DaylightName: array [0..31] of WideChar;
    DaylightDate: TSystemTime;
    DaylightBias: Integer;
  end;
  PTimeZoneInformation = ^TTimeZoneInformation;

  [FlagName(MINIDUMP_MISC1_PROCESS_ID, 'Process ID')]
  [FlagName(MINIDUMP_MISC1_PROCESS_TIMES, 'Process Times')]
  [FlagName(MINIDUMP_MISC1_PROCESSOR_POWER_INFO, 'Processor Power Info')]
  [FlagName(MINIDUMP_MISC3_PROCESS_INTEGRITY, 'Process Integrity')]
  [FlagName(MINIDUMP_MISC3_PROCESS_EXECUTE_FLAGS, 'Process Execute Flags')]
  [FlagName(MINIDUMP_MISC3_TIMEZONE, 'Timezone')]
  [FlagName(MINIDUMP_MISC3_PROTECTED_PROCESS, 'Protected Process')]
  [FlagName(MINIDUMP_MISC4_BUILDSTRING, 'Build String')]
  [FlagName(MINIDUMP_MISC5_PROCESS_COOKIE, 'Process Cookie')]
  TMiniDumpMiscFlags = type Cardinal;

  // SDK::minidumpapiset.h, stream type 15
  [SDKName('MINIDUMP_MISC_INFO_4')]
  TMiniDumpMiscInfoN = record
    [Bytes] SizeOfInfo: Cardinal;
    Flags1: TMiniDumpMiscFlags;
    ProcessId: TProcessId32;
    ProcessCreateTime: TUnixTime;
    ProcessUserTime: TUnixTime;
    ProcessKernelTime: TUnixTime;
    ProcessorMaxMhz: Cardinal;
    ProcessorCurrentMhz: Cardinal;
    ProcessorMhzLimit: Cardinal;
    ProcessorMaxIdleState: Cardinal;
    ProcessorCurrentIdleState: Cardinal;
    ProcessIntegrityLevel: TIntegrityRid;
    [Hex] ProcessExecuteFlags: Cardinal;
    ProtectedProcess: Cardinal;
    TimeZoneId: Cardinal;
    TimeZone: TTimeZoneInformation;
    BuildString: array [MAX_PATH_ARRAY] of WideChar;
    DbgBldStr: array [0..39] of WideChar;
  end;
  PMiniDumpMiscInfoN = ^TMiniDumpMiscInfoN;

  { Stream type 16 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_MEMORY_INFO')]
  TMiniDumpMemoryInfo = record
    [Hex] BaseAddress: UInt64;
    [Hex] AllocationBase: UInt64;
    AllocationProtect: TMemoryProtection;
    [Unlisted] __alignment1: Cardinal;
    [Bytes] RegionSize: UInt64;
    State: TAllocationType;
    Protect: TMemoryProtection;
    MemoryType: TMemoryType;
    [Unlisted] __alignment2: Cardinal;
  end;
  PMiniDumpMemoryInfo = ^TMiniDumpMemoryInfo;

  // SDK::minidumpapiset.h, stream type 16
  [SDKName('MINIDUMP_MEMORY_INFO_LIST')]
  TMiniDumpMemoryInfoList = record
    [Bytes] SizeOfHeader: Cardinal;
    [Bytes] SizeOfEntry: Cardinal;
    NumberOfEntries: UInt64;
    RawInformation: TPlaceholder<TMiniDumpMemoryInfo> deprecated;
  end;
  PMiniDumpMemoryInfoList = ^TMiniDumpMemoryInfoList;

  { Stream type 17 }

  [FlagName(MINIDUMP_THREAD_INFO_ERROR_THREAD, 'Error')]
  [FlagName(MINIDUMP_THREAD_INFO_WRITING_THREAD, 'Writing')]
  [FlagName(MINIDUMP_THREAD_INFO_EXITED_THREAD, 'Existed')]
  [FlagName(MINIDUMP_THREAD_INFO_INVALID_INFO, 'Invalid Info')]
  [FlagName(MINIDUMP_THREAD_INFO_INVALID_CONTEXT, 'Invalud Context')]
  [FlagName(MINIDUMP_THREAD_INFO_INVALID_TEB, 'Invalid TEB')]
  TMiniDumpThreadInfoFlags = type Cardinal;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_THREAD_INFO')]
  TMiniDumpThreadInfo = record
    ThreadId: TThreadId32;
    DumpFlags: TMiniDumpThreadInfoFlags;
    DumpError: HRESULT;
    ExitStatus: NTSTATUS;
    CreateTime: TLargeInteger;
    ExitTime: TLargeInteger;
    KernelTime: TLargeInteger;
    UserTime: TLargeInteger;
    [Hex] StartAddress: UInt64;
    [Hex] Affinity: UInt64;
  end;
  PMiniDumpThreadInfo = ^TMiniDumpThreadInfo;

  // SDK::minidumpapiset.h, stream type 17
  [SDKName('MINIDUMP_THREAD_INFO_LIST')]
  TMiniDumpThreadInfoList = record
    [Bytes] SizeOfHeader: Cardinal;
    [Bytes] SizeOfEntry: Cardinal;
    NumberOfEntries: Cardinal;
    RawInformation: TPlaceholder<TMiniDumpThreadInfo> deprecated;
  end;
  PMiniDumpThreadInfoList = ^TMiniDumpThreadInfoList;

  { Stream type 18 }

  // SDK::avrfsdk.h
  [SDKName('AVRF_BACKTRACE_INFORMATION')]
  TAvrfBacktraceInformation = record
    Depth: Cardinal;
    Index: Cardinal;
    ReturnAddresses: array [0 .. AVRF_MAX_TRACES - 1] of UInt64;
  end;
  PAvrfBacktraceInformation = ^TAvrfBacktraceInformation;

  // SDK::avrfsdk.h
  [SDKName('eHANDLE_TRACE_OPERATIONS')]
  [NamingStyle(nsSnakeCase, 'OperationDb'), Range(1)]
  THandleTraceOperations = (
    OperationDbUnused = 0,
    OperationDbOpen = 1,
    OperationDbClose = 2,
    OperationDbBadRef = 3
  );

  // SDK::avrfsdk.h
  [SDKName('AVRF_HANDLE_OPERATION')]
  TAvrfHandleOperation = record
    Handle: UInt64;
    ProcessId: TProcessId32;
    ThreadId: TThreadId32;
    OperationType: THandleTraceOperations;
    [Unlisted] Spare0: Cardinal;
    BackTraceInformation: TAvrfBacktraceInformation;
  end;
  PAvrfHandleOperation = ^TAvrfHandleOperation;

  // SDK::minidumpapiset.h, stream type 18
  [SDKName('MINIDUMP_HANDLE_OPERATION_LIST')]
  TMiniDumpHandleOprtationList = record
    [Bytes] SizeOfHeader: Cardinal;
    [Bytes] SizeOfEntry: Cardinal;
    NumberOfEntries: Cardinal;
    [Unlisted] Reserved: Cardinal;
    RawInformation: TPlaceholder<TAvrfHandleOperation> deprecated;
  end;
  PMiniDumpHandleOprtationList = ^TMiniDumpHandleOprtationList;

  { Stream type 19 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_TOKEN_INFO_HEADER')]
  TMiniDumpTokenInfoHeader = record
    [Bytes] TokenSize: Cardinal;
    TokenId: Cardinal; // TProcessId32 or TThreadId32
    TokenHandle: UInt64;
  end;
  PMiniDumpTokenInfoHeader = ^TMiniDumpTokenInfoHeader;

  // SDK::minidumpapiset.h, stream type 19
  [SDKName('MINIDUMP_TOKEN_INFO_LIST')]
  TMiniDumpTokenInfoList = record
    [Bytes] TokenListSize: Cardinal;
    TokenListEntries: Cardinal;
    [Bytes] ListHeaderSize: Cardinal;
    [Bytes] ElementHeaderSize: Cardinal;
  end;
  PMiniDumpTokenInfoList = ^TMiniDumpTokenInfoList;

  { Stream type 21 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_SYSTEM_BASIC_INFORMATION')]
  TMiniDumpSystemBasicInformation = record
    TimerResolution: Cardinal;
    [Bytes] PageSize: Cardinal;
    NumberOfPhysicalPages: Cardinal;
    LowestPhysicalPageNumber: Cardinal;
    HighestPhysicalPageNumber: Cardinal;
    [Bytes] AllocationGranularity: Cardinal;
    [Hex] MinimumUserModeAddress: UInt64;
    [Hex] MaximumUserModeAddress: UInt64;
    [Hex] ActiveProcessorsAffinityMask: UInt64;
    NumberOfProcessors: Cardinal;
  end;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_SYSTEM_FILECACHE_INFORMATION')]
  TMiniDumpSystemFileCacheInformation = record
    [Bytes] CurrentSize: UInt64;
    [Bytes] PeakSize: UInt64;
    PageFaultCount: Cardinal;
    [Bytes] MinimumWorkingSet: UInt64;
    [Bytes] MaximumWorkingSet: UInt64;
    [Bytes] CurrentSizeIncludingTransitionInPages: UInt64;
    [Bytes] PeakSizeIncludingTransitionInPages: UInt64;
    TransitionRePurposeCount: Cardinal;
    [Hex] Flags: Cardinal;
  end;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_SYSTEM_BASIC_PERFORMANCE_INFORMATION')]
  TMiniDumpSystemBasicPerformanceInformation = record
    AvailablePages: UInt64;
    CommittedPages: UInt64;
    [Bytes] CommitLimit: UInt64;
    [Bytes] PeakCommitment: UInt64;
  end;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_SYSTEM_PERFORMANCE_INFORMATION')]
  TMiniDumpSystemPerformaceInformation = record
    IdleProcessTime: TLargeInteger;
    [Bytes] IoReadTransferCount: UInt64;
    [Bytes] IoWriteTransferCount: UInt64;
    [Bytes] IoOtherTransferCount: UInt64;
    IoReadOperationCount: Cardinal;
    IoWriteOperationCount: Cardinal;
    IoOtherOperationCount: Cardinal;
    AvailablePages: Cardinal;
    CommittedPages: Cardinal;
    [Bytes] CommitLimit: Cardinal;
    [Bytes] PeakCommitment: Cardinal;
    PageFaultCount: Cardinal;
    CopyOnWriteCount: Cardinal;
    TransitionCount: Cardinal;
    CacheTransitionCount: Cardinal;
    DemandZeroCount: Cardinal;
    PageReadCount: Cardinal;
    PageReadIoCount: Cardinal;
    CacheReadCount: Cardinal;
    CacheIoCount: Cardinal;
    DirtyPagesWriteCount: Cardinal;
    DirtyWriteIoCount: Cardinal;
    MappedPagesWriteCount: Cardinal;
    MappedWriteIoCount: Cardinal;
    PagedPoolPages: Cardinal;
    NonPagedPoolPages: Cardinal;
    PagedPoolAllocs: Cardinal;
    PagedPoolFrees: Cardinal;
    NonPagedPoolAllocs: Cardinal;
    NonPagedPoolFrees: Cardinal;
    FreeSystemPtes: Cardinal;
    ResidentSystemCodePage: Cardinal;
    TotalSystemDriverPages: Cardinal;
    TotalSystemCodePages: Cardinal;
    NonPagedPoolLookasideHits: Cardinal;
    PagedPoolLookasideHits: Cardinal;
    AvailablePagedPoolPages: Cardinal;
    ResidentSystemCachePage: Cardinal;
    ResidentPagedPoolPage: Cardinal;
    ResidentSystemDriverPage: Cardinal;
    CcFastReadNoWait: Cardinal;
    CcFastReadWait: Cardinal;
    CcFastReadResourceMiss: Cardinal;
    CcFastReadNotPossible: Cardinal;
    CcFastMdlReadNoWait: Cardinal;
    CcFastMdlReadWait: Cardinal;
    CcFastMdlReadResourceMiss: Cardinal;
    CcFastMdlReadNotPossible: Cardinal;
    CcMapDataNoWait: Cardinal;
    CcMapDataWait: Cardinal;
    CcMapDataNoWaitMiss: Cardinal;
    CcMapDataWaitMiss: Cardinal;
    CcPinMappedDataCount: Cardinal;
    CcPinReadNoWait: Cardinal;
    CcPinReadWait: Cardinal;
    CcPinReadNoWaitMiss: Cardinal;
    CcPinReadWaitMiss: Cardinal;
    CcCopyReadNoWait: Cardinal;
    CcCopyReadWait: Cardinal;
    CcCopyReadNoWaitMiss: Cardinal;
    CcCopyReadWaitMiss: Cardinal;
    CcMdlReadNoWait: Cardinal;
    CcMdlReadWait: Cardinal;
    CcMdlReadNoWaitMiss: Cardinal;
    CcMdlReadWaitMiss: Cardinal;
    CcReadAheadIos: Cardinal;
    CcLazyWriteIos: Cardinal;
    CcLazyWritePages: Cardinal;
    CcDataFlushes: Cardinal;
    CcDataPages: Cardinal;
    ContextSwitches: Cardinal;
    FirstLevelTbFills: Cardinal;
    SecondLevelTbFills: Cardinal;
    SystemCalls: Cardinal;
    CcTotalDirtyPages: UInt64;
    CcDirtyPageThreshold: UInt64;
    ResidentAvailablePages: Int64;
    SharedCommittedPages: UInt64;
  end;

  // SDK::minidumpapiset.h, stream type 21
  [SDKName('MINIDUMP_SYSTEM_MEMORY_INFO_1')]
  TMiniDumpSystemMemoryInfoN = record
    [Reserved(1)] Revision: Word;
    Flags: Word; // MINIDUMP_SYSMEMINFO1_*
    BasicInfo: TMiniDumpSystemBasicInformation;
    FileCacheInfo: TMiniDumpSystemFileCacheInformation;
    BasicPerfInfo: TMiniDumpSystemBasicPerformanceInformation;
    PerfInfo: TMiniDumpSystemPerformaceInformation;
  end;
  PMiniDumpSystemMemoryInfoN = ^TMiniDumpSystemMemoryInfoN;

  { Stream type 22 }

  // SDK::minidumpapiset.h
  [FlagName(MINIDUMP_PROCESS_VM_COUNTERS, 'VM Counters')]
  [FlagName(MINIDUMP_PROCESS_VM_COUNTERS_VIRTUALSIZE, 'Virtual Size')]
  [FlagName(MINIDUMP_PROCESS_VM_COUNTERS_EX, 'Ex')]
  [FlagName(MINIDUMP_PROCESS_VM_COUNTERS_EX2, 'Ex2')]
  [FlagName(MINIDUMP_PROCESS_VM_COUNTERS_JOB, 'Job')]
  TMiniDumpProcessVmCountersFlags = type Word;

  // SDK::minidumpapiset.h, stream type 22
  [SDKName('MINIDUMP_PROCESS_VM_COUNTERS_1')]
  TMiniDumpProcessVmCounters1 = record
    [Reserved(1)] Revision: Word;
    PageFaultCount: Cardinal;
    [Bytes] PeakWorkingSetSize: UInt64;
    [Bytes] WorkingSetSize: UInt64;
    [Bytes] QuotaPeakPagedPoolUsage: UInt64;
    [Bytes] QuotaPagedPoolUsage: UInt64;
    [Bytes] QuotaPeakNonPagedPoolUsage: UInt64;
    [Bytes] QuotaNonPagedPoolUsage: UInt64;
    [Bytes] PagefileUsage: UInt64;
    [Bytes] PeakPagefileUsage: UInt64;
    [Bytes] PrivateUsage: UInt64;
  end;
  PMiniDumpProcessVmCounters1 = ^TMiniDumpProcessVmCounters1;

  // SDK::minidumpapiset.h, stream type 22
  [SDKName('MINIDUMP_PROCESS_VM_COUNTERS_2')]
  TMiniDumpProcessVmCounters2 = record
    [Reserved(2)] Revision: Word;
    Flags: TMiniDumpProcessVmCountersFlags;
    PageFaultCount: Cardinal;
    [Bytes] PeakWorkingSetSize: UInt64;
    [Bytes] WorkingSetSize: UInt64;
    [Bytes] QuotaPeakPagedPoolUsage: UInt64;
    [Bytes] QuotaPagedPoolUsage: UInt64;
    [Bytes] QuotaPeakNonPagedPoolUsage: UInt64;
    [Bytes] QuotaNonPagedPoolUsage: UInt64;
    [Bytes] PagefileUsage: UInt64;
    [Bytes] PeakPagefileUsage: UInt64;
    [Bytes] PeakVirtualSize: UInt64;            // VIRTUALSIZE
    [Bytes] VirtualSize: UInt64;                // VIRTUALSIZE
    [Bytes] PrivateUsage: UInt64;               // EX+
    [Bytes] PrivateWorkingSetSize: UInt64;      // EX2+
    [Bytes] SharedCommitUsage: UInt64;          // EX2+
    [Bytes] JobSharedCommitUsage: UInt64;       // JOB+
    [Bytes] JobPrivateCommitUsage: UInt64;      // JOB+
    [Bytes] JobPeakPrivateCommitUsage: UInt64;  // JOB+
    [Bytes] JobPrivateCommitLimit: UInt64;      // JOB+
    [Bytes] JobTotalCommitLimit: UInt64;        // JOB+
  end;
  PMiniDumpProcessVmCounters2 = ^TMiniDumpProcessVmCounters2;

  { Stream type 24 }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_THREAD_NAME')]
  TMiniDumpThreadName = record
    ThreadId: TThreadId32;
    [Hex] RvaOfThreadName: UInt64;
  end;
  PMiniDumpThreadName = ^TMiniDumpThreadName;

  // SDK::minidumpapiset.h, stream tyoe 24
  [SDKName('MINIDUMP_THREAD_NAME_LIST')]
  TMiniDumpThreadNameList = record
    NumberOfThreadNames: Cardinal;
    ThreadNames: TAnysizeArray<TMiniDumpThreadName>;
  end;
  PMiniDumpThreadNameList = ^TMiniDumpThreadNameList;

  { End stream types }

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_EXCEPTION_INFORMATION')]
  TMiniDumpExceptionInformation = record
    ThreadId: TThreadId32;
    ExceptionPointers: PExceptionPointers;
    ClientPointers: LongBool;
  end;
  PMiniDumpExceptionInformation = ^TMiniDumpExceptionInformation;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_EXCEPTION_INFORMATION64')]
  TMiniDumpExceptionInformation64 = record
    ThreadId: TThreadId32;
    [Hex] ExceptionRecord: UInt64;
    [Hex] ContextRecord: UInt64;
    ClientPointers: LongBool;
  end;
  PMiniDumpExceptionInformation64 = ^TMiniDumpExceptionInformation64;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_USER_RECORD')]
  TMiniDumpUserRecord = record
    &Type: Cardinal;
    Memory: TMiniDumpLocationDescriptor;
  end;
  PMiniDumpUserRecord = ^TMiniDumpUserRecord;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_USER_STREAM')]
  TMiniDumpUserStream = record
    &Type: Cardinal;
    [Bytes] BufferSize: Cardinal;
    Buffer: Pointer;
  end;
  PMiniDumpUserStream = ^TMiniDumpUserStream;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_USER_STREAM_INFORMATION')]
  TMiniDumpUserStreamInformation = record
    [Counter(ctElements)] UserStreamCount: Cardinal;
    UserStreamArray: ^TAnySizeArray<TMiniDumpUserStream>;
  end;
  PMiniDumpUserStreamInformation = ^TMiniDumpUserStreamInformation;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_CALLBACK_TYPE')]
  [NamingStyle(nsCamelCase, '', 'Callback')]
  TMiniDumpCallbackType = (
    ModuleCallback = 0,
    ThreadCallback = 1,
    ThreadExCallback = 2,
    IncludeThreadCallback = 3,
    IncludeModuleCallback = 4,
    MemoryCallback = 5,
    CancelCallback = 6,
    WriteKernelMinidumpCallback = 7,
    KernelMinidumpStatusCallback = 8,
    RemoveMemoryCallback = 9,
    IncludeVmRegionCallback = 10,
    IoStartCallback = 11,
    IoWriteAllCallback = 12,
    IoFinishCallback = 13,
    ReadMemoryFailureCallback = 14,
    SecondaryFlagsCallback = 15,
    IsProcessSnapshotCallback = 16,
    VmStartCallback = 17,
    VmQueryCallback = 18,
    VmPreReadCallback = 19,
    VmPostReadCallback = 20
  );

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_THREAD_CALLBACK')]
  TMiniDumpThreadCallback = record
    ThreadId: TThreadId32;
    ThreadHandle: THandle;
    Context: PContext;
    [Bytes] SizeOfContext: Cardinal;
    [Hex] StackBase: UInt64;
    [Hex] StackEnd: UInt64;
  end;
  PMiniDumpThreadCallback = ^TMiniDumpThreadCallback;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_THREAD_CALLBACK_EX')]
  TMiniDumpThreadCallbackEx = record
    [Aggregate] Basic: TMiniDumpThreadCallback;
    [Hex] BackingStoreBase: UInt64;
    [Hex] BackingStoreEnd: UInt64;
  end;
  PMiniDumpThreadCallbackEx = ^TMiniDumpThreadCallbackEx;

  // SDK::minidumpapiset.h
  [SDKName('THREAD_WRITE_FLAGS')]
  [FlagName(ThreadWriteThread, 'Thread')]
  [FlagName(ThreadWriteStack, 'Stack')]
  [FlagName(ThreadWriteContext, 'Context')]
  [FlagName(ThreadWriteBackingStore, 'Backing Store')]
  [FlagName(ThreadWriteInstructionWindow, 'Instruction Window')]
  [FlagName(ThreadWriteThreadData, 'Thread Data')]
  [FlagName(ThreadWriteThreadInfo, 'Thread Info')]
  TMiniDumpThreadWriteFlags = type Cardinal;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_MODULE_CALLBACK')]
  TMiniDumpModuleCallback = record
    FullPath: PWideChar;
    [Hex] BaseOfImage: UInt64;
    [Bytes] SizeOfImage: Cardinal;
    [Hex] CheckSum: Cardinal;
    TimeDateStamp: TUnixTime;
    VersionInfo: TVsFixedFileInfo;
    CvRecord: Pointer;
    [Bytes] SizeOfCvRecord: Cardinal;
    MiscRecord: Pointer;
    [Bytes] SizeOfMiscRecord: Cardinal;
  end;
  PMiniDumpModuleCallback = ^TMiniDumpModuleCallback;

  // SDK::minidumpapiset.h
  [SDKName('MODULE_WRITE_FLAGS')]
  [FlagName(ModuleWriteModule, 'Module')]
  [FlagName(ModuleWriteDataSeg, 'Data Segment')]
  [FlagName(ModuleWriteMiscRecord, 'Misc Record')]
  [FlagName(ModuleWriteCvRecord, 'CV Record')]
  [FlagName(ModuleReferencedByMemory, 'Referenced By Memory')]
  [FlagName(ModuleWriteTlsData, 'TLS Data')]
  [FlagName(ModuleWriteCodeSegs, 'Code Segments')]
  TMiniDumpModuleWriteFlags = type Cardinal;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_IO_CALLBACK')]
  TMiniDumpIoCallback = record
    Handle: THandle;
    [Hex] Offset: UInt64;
    Buffer: Pointer;
    [Bytes] BufferBytes: Cardinal;
  end;
  PMiniDumpIoCallback = ^TMiniDumpIoCallback;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_READ_MEMORY_FAILURE_CALLBACK')]
  TMiniDumpReadMemoryFailureCallback = record
    [Hex] Offset: UInt64;
    [Bytes] Bytes: Cardinal;
    FailureStatus: HRESULT;
  end;
  PMiniDumpReadMemoryFailureCallback = ^TMiniDumpReadMemoryFailureCallback;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_VM_POST_READ_CALLBACK')]
  TMiniDumpVmPreReadCallback = record
    [Hex] Offset: UInt64;
    Buffer: Pointer;
    [Bytes] Size: Cardinal;
  end;
  PMiniDumpVmPreReadCallback = ^TMiniDumpVmPreReadCallback ;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_VM_POST_READ_CALLBACK')]
  TMiniDumpVmPostReadCallback = record
    [Hex] Offset: UInt64;
    Buffer: Pointer;
    [Bytes] Size: Cardinal;
    Completed: Cardinal;
    Status: HRESULT;
  end;
  PMiniDumpVmPostReadCallback = ^TMiniDumpVmPostReadCallback;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_SECONDARY_FLAGS')]
  [FlagName(MiniSecondaryWithoutPowerInfo, 'Without Power Info')]
  TMiniDumpSecondaryFlags = type Cardinal;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_CALLBACK_INPUT')]
  TMiniDumpCallbackInput = record
    ProcessId: TProcessId32;
    ProcessHandle: THandle;
    CallbackType: TMiniDumpCallbackType;
  case Integer of
    0: (Status: HRESULT);
    1: (Thread: TMiniDumpThreadCallback);
    2: (ThreadEx: TMiniDumpThreadCallbackEx);
    3: (Module: TMiniDumpModuleCallback);
    4: (IncludeThreadId: TThreadId32);
    5: (IncludeModuleBase: UInt64);
    6: (Io: TMiniDumpIoCallback);
    7: (ReadMemoryFailure: TMiniDumpReadMemoryFailureCallback);
    8: (SecondaryFlags: TMiniDumpSecondaryFlags);
    9: (VmQueryOffset: UInt64);
    10: (VmPreRead: TMiniDumpVmPreReadCallback);
    11: (VmPostRead: TMiniDumpVmPostReadCallback);
  end;
  PMiniDumpCallbackInput = ^TMiniDumpCallbackInput;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_CALLBACK_OUTPUT')]
  TMiniDumpCallbackOutput = record
  case Integer of
    0: (ModuleWriteFlags: TMiniDumpModuleWriteFlags);
    1: (ThreadWriteFlags: TMiniDumpThreadWriteFlags);
    2: (SecondaryFlags: TMiniDumpSecondaryFlags);
    3: (
      MemoryBase: UInt64;
      MemorySize: Cardinal;
    );
    4: (
      CheckCancel: LongBool;
      Cancel: LongBool;
    );
    5: (Handle: THandle);
    6: (
      VmRegion: TMiniDumpMemoryInfo;
      _Continue: LongBool;
    );
    7: (
      VmQueryStatus: HRESULT;
      VmQueryResult: TMiniDumpMemoryInfo;
    );
    8: (
      VmReadStatus: HRESULT;
      VmReadBytesCompleted: Cardinal;
    );
    9: (Status: HRESULT);
  end;
  PMiniDumpCallbackOutput = ^TMiniDumpCallbackOutput;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_CALLBACK_ROUTINE')]
  TMiniDumpCallackRoutine = function (
    [in, out, opt] CallbackParam: Pointer;
    [in] CallbackInput: PMiniDumpCallbackInput;
    [in, out] CallbackOutput: PMiniDumpCallbackOutput
  ): LongBool; stdcall;

  // SDK::minidumpapiset.h
  [SDKName('MINIDUMP_CALLBACK_INFORMATION')]
  TMiniDumpCallbackInformation = record
    CallbackRoutine: TMiniDumpCallackRoutine;
    [opt] CallbackParam: Pointer;
  end;
  PMiniDumpCallbackInformation = ^TMiniDumpCallbackInformation;

// SDK::minidumpapiset.h
function MiniDumpWriteDump(
  [Access(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ)] hProcess: THandle;
  [opt, Access(PROCESS_ALL_ACCESS)] ProcessId: TProcessId32;
  [Access(FILE_WRITE_DATA)] hFile: THandle;
  DumpType: TMiniDumpType;
  [in, opt] ExceptionParam: PMiniDumpExceptionInformation;
  [in, opt] UserStreamParam: PMiniDumpUserStreamInformation;
  [in, opt] CallbackParam: PMiniDumpCallbackInformation
): LongBool; external dbghelp;

// SDK::minidumpapiset.h
function MiniDumpReadDumpStream(
  [in] BaseOfDump: Pointer;
  StreamNumber: TMiniDumpStreamType;
  out Dir: PMiniDumpDirectory;
  out StreamPointer: Pointer;
  out StreamSize: Cardinal
): LongBool; external dbghelp;

implementation

end.
