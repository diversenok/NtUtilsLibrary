unit Ntapi.ntrtl;

{
  This file defines prototypes for supplementary functions of the
  Run-Time Library from ntdll.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntmmapi, Ntapi.ntseapi, Ntapi.ImageHlp,
  Ntapi.ntobapi, Ntapi.Versions, DelphiApi.Reflection;

const
  // Processes

  // PHNT::ntrtl.h
  RTL_MAX_DRIVE_LETTERS = 32;

  // PHNT::ntrtl.h - user process parameter flags
  RTL_USER_PROC_PARAMS_NORMALIZED = $00000001;
  RTL_USER_PROC_PROFILE_USER = $00000002;
  RTL_USER_PROC_PROFILE_KERNEL = $00000004;
  RTL_USER_PROC_PROFILE_SERVER = $00000008;
  RTL_USER_PROC_RESERVE_1MB = $00000020;
  RTL_USER_PROC_RESERVE_16MB = $00000040;
  RTL_USER_PROC_CASE_SENSITIVE = $00000080;
  RTL_USER_PROC_DISABLE_HEAP_DECOMMIT = $00000100;
  RTL_USER_PROC_DLL_REDIRECTION_LOCAL = $00001000;
  RTL_USER_PROC_APP_MANIFEST_PRESENT = $00002000;
  RTL_USER_PROC_IMAGE_KEY_MISSING = $00004000;
  RTL_USER_PROC_OPTIN_PROCESS = $00020000;

  // PHNT::ntrtl.h - process cloning flags
  RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED = $00000001;
  RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES = $00000002;
  RTL_CLONE_PROCESS_FLAGS_NO_SYNCHRONIZE = $00000004;

  // PHNT::ntrtl.h
  RTL_IMAGE_NT_HEADER_EX_FLAG_NO_RANGE_CHECK = $00000001;

  // PHNT::ntrtl.h
  RTL_USER_PROCESS_EXTENDED_PARAMETERS_VERSION = 1;

  // Re-declare for annottations
  JOB_OBJECT_ASSIGN_PROCESS = $0001; // Ntapi.ntpsapi
  DEBUG_PROCESS_ASSIGN = $0002; // Ntapi.ntdbg

  PROCESS_CREATE_REFLECTION = PROCESS_VM_OPERATION or PROCESS_CREATE_THREAD or
    PROCESS_DUP_HANDLE;

  // Heaps

  // SDK::winnt.h - heap flags
  HEAP_NO_SERIALIZE = $00000001;
  HEAP_GROWABLE = $00000002;
  HEAP_GENERATE_EXCEPTIONS = $00000004;
  HEAP_ZERO_MEMORY = $00000008;
  HEAP_REALLOC_IN_PLACE_ONLY = $00000010;
  HEAP_TAIL_CHECKING_ENABLED = $00000020;
  HEAP_FREE_CHECKING_ENABLED = $00000040;
  HEAP_DISABLE_COALESCE_ON_FREE = $00000080;
  HEAP_CREATE_SEGMENT_HEAP = $00000100;
  HEAP_CREATE_HARDENED = $00000200;
  HEAP_CREATE_ALIGN_16 = $00010000;
  HEAP_CREATE_ENABLE_TRACING = $00020000;
  HEAP_CREATE_ENABLE_EXECUTE = $00040000;

  // Exceptions

  // SDK::winnt.h
  UNW_FLAG_NHANDLER = $0;
  UNW_FLAG_EHANDLER = $1;
  UNW_FLAG_UHANDLER = $2;
  UNW_FLAG_CHAININFO = $4;
  UNW_FLAG_NO_EPILOGUE = $80000000;

  // SDK::rtlsupportapi.h
  UNWIND_HISTORY_TABLE_SIZE = 12;

  // rev
  RTL_UNLOAD_EVENT_TRACE_NUMBER = 16;

  // Messages

  // SDK::WinUser.h - message table id for RtlFindMessage
  RT_MESSAGETABLE = 11;

  // SDK::winnt.h
  MESSAGE_RESOURCE_ANSI = $0000;
  MESSAGE_RESOURCE_UNICODE = $0001;
  MESSAGE_RESOURCE_UTF8 = $0002;

  MESSAGE_RESOURCE_ENCODING_MASK = $0003;

type
  PPEnvironment = ^PEnvironment;

  // Strings

  // WDK::wdm.h
  [NamingStyle(nsSnakeCase, 'HASH_STRING_ALGORITHM')]
  THashStringAlgorithm = (
    HASH_STRING_ALGORITHM_DEFAULT = 0,
    HASH_STRING_ALGORITHM_X65599 = 1
  );

  // Processes

  // PHNT::ntrtl.h
  [SDKName('CURDIR')]
  TCurDir = record
    DosPath: TNtUnicodeString;
    Handle: THandle;
  end;
  PCurDir = ^TCurDir;

  // PHNT::ntrtl.h
  [SDKName('RTL_DRIVE_LETTER_CURDIR')]
  TRtlDriveLetterCurDir = record
    [Hex] Flags: Word;
    [Bytes] Length: Word;
    TimeStamp: TUnixTime;
    DosPath: TNtAnsiString;
  end;
  PRtlDriveLetterCurDir = ^TRtlDriveLetterCurDir;

  // PHNT::ntrtl.h
  TCurrentDirectories = array [0..RTL_MAX_DRIVE_LETTERS - 1] of
    TRtlDriveLetterCurDir;

  [FlagName(RTL_USER_PROC_PARAMS_NORMALIZED, 'Normalized')]
  [FlagName(RTL_USER_PROC_PROFILE_USER, 'Profile User')]
  [FlagName(RTL_USER_PROC_PROFILE_KERNEL, 'Profile Kernel')]
  [FlagName(RTL_USER_PROC_PROFILE_SERVER, 'Profile Server')]
  [FlagName(RTL_USER_PROC_RESERVE_1MB, 'Reserve 1MB')]
  [FlagName(RTL_USER_PROC_RESERVE_16MB, 'Reserve 16MB')]
  [FlagName(RTL_USER_PROC_CASE_SENSITIVE, 'Case-sensitive')]
  [FlagName(RTL_USER_PROC_DISABLE_HEAP_DECOMMIT, 'Disable Heap Decommit')]
  [FlagName(RTL_USER_PROC_DLL_REDIRECTION_LOCAL, 'DLL Redirection Local')]
  [FlagName(RTL_USER_PROC_APP_MANIFEST_PRESENT, 'App Manifest Present')]
  [FlagName(RTL_USER_PROC_IMAGE_KEY_MISSING, 'Image Key Missing')]
  [FlagName(RTL_USER_PROC_OPTIN_PROCESS, 'Opt-in Process')]
  TRtlUserProcessFlags = type Cardinal;

  [FlagName(RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED, 'Create Suspended')]
  [FlagName(RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES, 'Inherit Handles')]
  [FlagName(RTL_CLONE_PROCESS_FLAGS_NO_SYNCHRONIZE, 'No Synchronize')]
  TRtlProcessCloneFlags = type Cardinal;

  // PHNT::ntrtl.h
  [SDKName('RTL_USER_PROCESS_PARAMETERS')]
  TRtlUserProcessParameters = record
    [Bytes, Unlisted] MaximumLength: Cardinal;
    [Bytes, Unlisted] Length: Cardinal;

    Flags: TRtlUserProcessFlags;
    [Hex] DebugFlags: Cardinal;

    ConsoleHandle: THandle;
    [Hex] ConsoleFlags: Cardinal;
    StandardInput: THandle;
    StandardOutput: THandle;
    StandardError: THandle;

    CurrentDirectory: TCurDir;
    DLLPath: TNtUnicodeString;
    ImagePathName: TNtUnicodeString;
    CommandLine: TNtUnicodeString;
    [volatile] Environment: PEnvironment;

    StartingX: Cardinal;
    StartingY: Cardinal;
    CountX: Cardinal;
    CountY: Cardinal;
    CountCharsX: Cardinal;
    CountCharsY: Cardinal;
    FillAttribute: Cardinal; // ConsoleApi.TConsoleFill

    WindowFlags: Cardinal; // ProcessThreadsApi.TStarupFlags
    ShowWindowFlags: Cardinal; // WinUser.TShowMode
    WindowTitle: TNtUnicodeString;
    DesktopInfo: TNtUnicodeString;
    ShellInfo: TNtUnicodeString;
    RuntimeData: TNtUnicodeString;
    CurrentDirectories: TCurrentDirectories;

    [Bytes, volatile] EnvironmentSize: NativeUInt;
    EnvironmentVersion: NativeUInt;
    [MinOSVersion(OsWin8)] PackageDependencyData: Pointer;
    [MinOSVersion(OsWin8)] ProcessGroupID: Cardinal;
    [MinOSVersion(OsWin10TH1)] LoaderThreads: Cardinal;

    [MinOSVersion(OsWin10RS5)] RedirectionDLLName: TNtUnicodeString;
    [MinOSVersion(OsWin1019H1)] HeapPartitionName: TNtUnicodeString;
    [MinOSVersion(OsWin1019H1)] DefaultThreadPoolCPUSetMasks: NativeUInt;
    [MinOSVersion(OsWin1019H1)] DefaultThreadPoolCPUSetMaskCount: Cardinal;
  end;
  PRtlUserProcessParameters = ^TRtlUserProcessParameters;

  // PHNT::ntrtl.h
  [SDKName('RTL_USER_PROCESS_EXTENDED_PARAMETERS')]
  TRtlUserProcessExtendedParameters = record
    [Reserved(RTL_USER_PROCESS_EXTENDED_PARAMETERS_VERSION)] Version: Word;
    NodeNumber: Word;
    ProcessSecurityDescriptor: PSecurityDescriptor;
    ThreadSecurityDescriptor: PSecurityDescriptor;
    [Access(PROCESS_CREATE_PROCESS)] ParentProcess: THandle;
    [Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle;
    [Access(TOKEN_ASSIGN_PRIMARY)] TokenHandle: THandle;
    [Access(JOB_OBJECT_ASSIGN_PROCESS)] JobHandle: THandle;
  end;
  PRtlUserProcessExtendedParameters = ^TRtlUserProcessExtendedParameters;

  // PHNT::ntrtl.h
  [SDKName('RTL_USER_PROCESS_INFORMATION')]
  TRtlUserProcessInformation = record
    [Bytes, Unlisted] Length: Cardinal;
    Process: THandle;
    Thread: THandle;
    ClientId: TClientId;
    ImageInformation: TSectionImageInformation;
  end;
  PRtlUserProcessInformation = ^TRtlUserProcessInformation;

  // PHNT::ntrtl.h
  [SDKName('RTLP_PROCESS_REFLECTION_REFLECTION_INFORMATION')]
  TRtlpProcessReflectionInformation = record
    ReflectionProcessHandle: THandle;
    ReflectionThreadHandle: THandle;
    ReflectionClientId: TClientId;
  end;
  PRtlpProcessReflectionInformation = ^TRtlpProcessReflectionInformation;

  // Heaps

  [FlagName(HEAP_NO_SERIALIZE, 'No Serialize')]
  [FlagName(HEAP_GROWABLE, 'Growable')]
  [FlagName(HEAP_GENERATE_EXCEPTIONS, 'Generate Exceptions')]
  [FlagName(HEAP_ZERO_MEMORY, 'Zero Memory')]
  [FlagName(HEAP_REALLOC_IN_PLACE_ONLY, 'Realloc In-Place Only')]
  [FlagName(HEAP_TAIL_CHECKING_ENABLED, 'Trail Checking')]
  [FlagName(HEAP_FREE_CHECKING_ENABLED, 'Free Checking')]
  [FlagName(HEAP_DISABLE_COALESCE_ON_FREE, 'Disable Coalesce')]
  [FlagName(HEAP_CREATE_SEGMENT_HEAP, 'Segment Heap')]
  [FlagName(HEAP_CREATE_HARDENED, 'Hardened')]
  [FlagName(HEAP_CREATE_ALIGN_16, 'Align 16')]
  [FlagName(HEAP_CREATE_ENABLE_TRACING, 'Enable Tracing')]
  [FlagName(HEAP_CREATE_ENABLE_EXECUTE, 'Enable Execute')]
  THeapFlags = type Cardinal;

  // Exceptions

  [SubEnum($3, UNW_FLAG_NHANDLER, 'No Handler')]
  [SubEnum($3, UNW_FLAG_NHANDLER, 'Exception Handler')]
  [SubEnum($3, UNW_FLAG_NHANDLER, 'Unwind Handler')]
  [FlagName(UNW_FLAG_CHAININFO, 'Chain Info')]
  [FlagName(UNW_FLAG_NO_EPILOGUE, 'No Epilogue')]
  TUnwindFlags = type Cardinal;

  // SDK::rtlsupportapi.h
  [SDKName('UNWIND_HISTORY_TABLE')]
  TUnwindHistoryTableEntry = record
    ImageBase: UIntPtr;
    FunctionEntry: PRuntimeFunction;
  end;

  // SDK::rtlsupportapi.h
  [SDKName('UNWIND_HISTORY_TABLE')]
  TUnwindHistoryTable = record
    Count: Cardinal;
    LocalHint: Byte;
    GlobalHint: Byte;
    Search: Byte;
    Once: Byte;
    LowAddress: UIntPtr;
    HighAddress: UIntPtr;
    Entry: array [0 .. UNWIND_HISTORY_TABLE_SIZE - 1] of TUnwindHistoryTableEntry;
  end;
  PUnwindHistoryTable = ^TUnwindHistoryTable;

  // SDK::winnt.h
  [SDKName('KNONVOLATILE_CONTEXT_POINTERS')]
  TKNonVolatileContextPointer = record
    FloatingContext: array [0..15] of PM128A;
    IntegerContext: array [0..15] of PUInt64;
  end;
  PKNonVolatileContextPointer = ^TKNonVolatileContextPointer;

  // WDK::crt/excpt.h
  [SDKName('EXCEPTION_DISPOSITION')]
  [NamingStyle(nsCamelCase, 'Exception')]
  TExceptionDisposition = (
    ExceptionContinueExecution = 0,
    ExceptionContinueSearch = 1,
    ExceptionNestedException = 2,
    ExceptionCollidedUnwind = 3
  );

  // WDK::ntdef.h
  [SDKName('EXCEPTION_ROUTINE')]
  TExceptionRoutine = function (
    var ExceptionRecord: TExceptionRecord;
    [in] EstablisherFrame: Pointer;
    [in, out] ContextRecord: PContext;
    [in] DispatcherContext: Pointer
  ): TExceptionDisposition; stdcall;

  // Unloaded modules

  TRtlUnloadEventImageName = array [0..31] of WideChar;

  // rev
  TRtlUnloadEventVersion = record
    Minor: Word;
    Major: Word;
    Build: Word;
    Release: Word;
  end;

  // MSDocs::win32/desktop-src/DevNotes/RtlGetUnloadEventTraceEx.md & PHNT::ntrtl.h
  [SDKName('RTL_UNLOAD_EVENT_TRACE')]
  TRtlUnloadEventTrace = record
    BaseAddress: Pointer;
    [Bytes] SizeOfImage: NativeUInt;
    Sequence: Cardinal;
    TimeDateStamp: TUnixTime;
    [Hex] CheckSum: Cardinal;
    ImageName: TRtlUnloadEventImageName;
    Version: TRtlUnloadEventVersion;
  end;
  PRtlUnloadEventTrace = ^TRtlUnloadEventTrace;
  PPRtlUnloadEventTrace = ^PRtlUnloadEventTrace;

  TRtlUnloadEventTraceArray = array [0 .. RTL_UNLOAD_EVENT_TRACE_NUMBER] of
    TRtlUnloadEventTrace;
  PRtlUnloadEventTraceArray = ^TRtlUnloadEventTraceArray;

  // Threads

  // PHNT::ntrtl.h
  [SDKName('PUSER_THREAD_START_ROUTINE')]
  TUserThreadStartRoutine = function (ThreadParameter: Pointer): NTSTATUS;
    stdcall;

  // Modules

  // PHNT::ntldr.h
  [SDKName('RTL_PROCESS_MODULE_INFORMATION')]
  TRtlProcessModuleInformation = record
    Section: THandle;
    MappedBase: Pointer;
    ImageBase: Pointer;
    [Bytes] ImageSize: Cardinal;
    [Hex] Flags: Cardinal;
    LoadOrderIndex: Word;
    InitOrderIndex: Word;
    LoadCount: Word;
    [Unlisted] OffsetToFileName: Word;
    FullPathName: array [Byte] of AnsiChar;
  end;
  PRtlProcessModuleInformation = ^TRtlProcessModuleInformation;

  // PHNT::ntldr.h - system info class 11
  [SDKName('RTL_PROCESS_MODULES')]
  TRtlProcessModules = record
    NumberOfModules: Cardinal;
    Modules: TAnysizeArray<TRtlProcessModuleInformation>;
  end;
  PRtlProcessModules = ^TRtlProcessModules;

  // PHNT::ntldr.h - system info class 77
  [SDKName('RTL_PROCESS_MODULE_INFORMATION_EX')]
  TRtlProcessModuleInformationEx = record
    [Unlisted] NextOffset: Word;
    [Aggregate] BaseInfo: TRtlProcessModuleInformation;
    ImageChecksum: Cardinal;
    TimeDateStamp: TUnixTime;
    DefaultBase: Pointer;
  end;
  PRtlProcessModuleInformationEx = ^TRtlProcessModuleInformationEx;

  // Paths

  // PHNT::ntrtl.h
  [SDKName('RtlPathTypeUncAbsolute')]
  [NamingStyle(nsCamelCase, 'RtlPathType')]
  TRtlPathType = (
    RtlPathTypeUnknown = 0,
    RtlPathTypeUncAbsolute = 1,
    RtlPathTypeDriveAbsolute = 2,
    RtlPathTypeDriveRelative = 3,
    RtlPathTypeRooted = 4,
    RtlPathTypeRelative = 5,
    RtlPathTypeLocalDevice = 6,
    RtlPathTypeRootLocalDevice = 7
  );

  // Messages

  [SubEnum(MESSAGE_RESOURCE_ENCODING_MASK, MESSAGE_RESOURCE_ANSI, 'ANSI')]
  [SubEnum(MESSAGE_RESOURCE_ENCODING_MASK, MESSAGE_RESOURCE_UNICODE, 'Unicode')]
  [SubEnum(MESSAGE_RESOURCE_ENCODING_MASK, MESSAGE_RESOURCE_UTF8, 'UTF8')]
  TMessageResourceFlags = type Word;

  // SDK::winnt.h
  [SDKName('MESSAGE_RESOURCE_ENTRY')]
  TMessageResourceEntry = record
    Length: Word;
    Flags: TMessageResourceFlags;
    Text: TAnysizeArray<Byte>;
  end;
  PMessageResourceEntry = ^TMessageResourceEntry;

  // Time

  // PHNT::ntrtl.h
  [SDKName('TIME_FIELDS')]
  TTimeFields = record
    Year: SmallInt;
    Month: SmallInt;
    Day: SmallInt;
    Hour: SmallInt;
    Minute: SmallInt;
    Second: SmallInt;
    Milliseconds: SmallInt;
    Weekday: SmallInt;
  end;

  // PHNT::ntrtl.h
  [SDKName('RTL_TIME_ZONE_INFORMATION')]
  TRtlTimeZoneInformation = record
    Bias: Integer;
    StandardName: array [0..31] of WideChar;
    StandardStart: TTimeFields;
    StandardBias: Cardinal;
    DaylightName: array [0..31] of WideChar;
    DaylightStart: TTimeFields;
    DaylightBias: Integer;
  end;
  PTRtlTimeZoneInformation = ^TRtlTimeZoneInformation;

  // Appcontainer

  // PHNT::ntrtl.h
  [SDKName('APPCONTAINER_SID_TYPE')]
  [NamingStyle(nsCamelCase, '', 'SidType')]
  TAppContainerSidType = (
    NotAppContainerSidType = 0,
    ChildAppContainerSidType = 1,
    ParentAppContainerSidType = 2,
    InvalidAppContainerSidType = 3
  );

// Strings

// WDK::wdm.h
procedure RtlFreeUnicodeString(
  var UnicodeString: TNtUnicodeString
); stdcall; external ntdll;

// WDK::wdm.h
function RtlCompareString(
  const String1: TNtAnsiString;
  const String2: TNtAnsiString;
  CaseInSensitive: Boolean
): Integer; stdcall; external ntdll;

// WDK::ntddk.h
function RtlEqualString(
  const String1: TNtAnsiString;
  const String2: TNtAnsiString;
  CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

// WDK::wdm.h
function RtlCompareUnicodeString(
  const String1: TNtUnicodeString;
  const String2: TNtUnicodeString;
  CaseInSensitive: Boolean
): Integer; stdcall; external ntdll;

// WDK::wdm.h
function RtlEqualUnicodeString(
  const String1: TNtUnicodeString;
  const String2: TNtUnicodeString;
  CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

// WDK::ntifs.h
function RtlPrefixString(
  const String1: TNtAnsiString;
  const String2: TNtAnsiString;
  CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

// WDK::wdm.h
function RtlHashUnicodeString(
  const Str: TNtUnicodeString;
  CaseInSensitive: Boolean;
  HashAlgorithm: THashStringAlgorithm;
  out HashValue: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlPrefixUnicodeString(
  const String1: TNtUnicodeString;
  const String2: TNtUnicodeString;
  CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

// WDK::wdm.h
function RtlAppendUnicodeStringToString(
  var Destination: TNtUnicodeString;
  const Source: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlAppendUnicodeToString(
  var Destination: TNtUnicodeString;
  [in] Source: PWideChar
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlUpcaseUnicodeString(
  var DestinationString: TNtUnicodeString;
  const SourceString: TNtUnicodeString;
  AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlDowncaseUnicodeString(
  var DestinationString: TNtUnicodeString;
  const SourceString: TNtUnicodeString;
  AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlStringFromGUID(
  const Guid: TGuid;
  out GuidString: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGUIDFromString(
  const GuidString: TNtUnicodeString;
  out Guid: TGuid
): NTSTATUS; stdcall; external ntdll;

// Processes

// PHNT::ntrtl.h
function RtlCreateProcessParametersEx(
  [allocates('RtlDestroyProcessParameters')] out ProcessParameters:
    PRtlUserProcessParameters;
  const ImagePathName: TNtUnicodeString;
  [in, opt] DllPath: PNtUnicodeString;
  [in, opt] CurrentDirectory: PNtUnicodeString;
  [in, opt] CommandLine: PNtUnicodeString;
  [in, opt] Environment: PEnvironment;
  [in, opt] WindowTitle: PNtUnicodeString;
  [in, opt] DesktopInfo: PNtUnicodeString;
  [in, opt] ShellInfo: PNtUnicodeString;
  [in, opt] RuntimeData: PNtUnicodeString;
  Flags: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDestroyProcessParameters(
  [in] ProcessParameters: PRtlUserProcessParameters
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlNormalizeProcessParams(
  [in] ProcessParameters: PRtlUserProcessParameters
): PRtlUserProcessParameters; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDeNormalizeProcessParams(
  [in] ProcessParameters: PRtlUserProcessParameters
): PRtlUserProcessParameters; stdcall; external ntdll;

// PHNT::ntrtl.h
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function RtlCreateUserProcess(
  const NtImagePathName: TNtUnicodeString;
  AttributesDeprecated: Cardinal;
  [in] ProcessParameters: PRtlUserProcessParameters;
  [in, opt] ProcessSecurityDescriptor: PSecurityDescriptor;
  [in, opt] ThreadSecurityDescriptor: PSecurityDescriptor;
  [opt, Access(PROCESS_CREATE_PROCESS)] ParentProcess: THandle;
  InheritHandles: Boolean;
  [opt, Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle;
  [opt, Access(TOKEN_ASSIGN_PRIMARY)] TokenHandle: THandle;
  out ProcessInformation: TRtlUserProcessInformation
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[MinOSVersion(OsWin10RS2)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function RtlCreateUserProcessEx(
  const NtImagePathName: TNtUnicodeString;
  [in] ProcessParameters: PRtlUserProcessParameters;
  InheritHandles: Boolean;
  [in, opt] ExtendedParameters: PRtlUserProcessExtendedParameters;
  out ProcessInformation: TRtlUserProcessInformation
): NTSTATUS; stdcall; external ntdll delayed;

// PHNT::ntrtl.h
procedure RtlExitUserProcess(
  ExitStatus: NTSTATUS
); stdcall external ntdll;

// PHNT::ntrtl.h
function RtlCloneUserProcess(
  ProcessFlags: TRtlProcessCloneFlags;
  [in, opt] ProcessSecurityDescriptor: PSecurityDescriptor;
  [in, opt] ThreadSecurityDescriptor: PSecurityDescriptor;
  [opt, Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle;
  out ProcessInformation: TRtlUserProcessInformation
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlCreateProcessReflection(
  [Access(PROCESS_CREATE_REFLECTION)] ProcessHandle: THandle;
  Flags: Cardinal;
  [in, opt] StartRoutine: Pointer;
  [in, opt] StartContext: Pointer;
  [opt] EventHandle: THandle;
  out ReflectionInformation: TRtlpProcessReflectionInformation
): NTSTATUS; stdcall; external ntdll;

// Threads

// PHNT::ntrtl.h
function RtlCreateUserThread(
  [Access(PROCESS_CREATE_THREAD)] Process: THandle;
  [in, opt] ThreadSecurityDescriptor: PSecurityDescriptor;
  CreateSuspended: Boolean;
  ZeroBits: Cardinal;
  MaximumStackSize: NativeUInt;
  CommittedStackSize: NativeUInt;
  StartAddress: TUserThreadStartRoutine;
  [in, opt] Parameter: Pointer;
  out Thread: THandle;
  [out, opt] ClientId: PClientId
): NTSTATUS; stdcall; external ntdll;

// Extended thread context

{$IFDEF WIN64}
// PHNT::ntrtl.h
function RtlWow64GetThreadContext(
  [Access(THREAD_GET_CONTEXT)] ThreadHandle: THandle;
  [in, out] ThreadContext: PContext32
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlWow64SetThreadContext(
  [Access(THREAD_SET_INFORMATION)] ThreadHandle: THandle;
  [in, out] ThreadContext: PContext32
): NTSTATUS; stdcall; external ntdll;
{$ENDIF}

// PHNT::ntrtl.h
function RtlRemoteCall(
  [Access(PROCESS_VM_WRITE)] Process: THandle;
  [Access(THREAD_SUSPEND_RESUME or THREAD_GET_CONTEXT)] Thread: THandle;
  [in] CallSite: Pointer;
  ArgumentCount: Cardinal;
  Arguments: TArray<NativeUInt>;
  PassContext: Boolean;
  AlreadySuspended: Boolean
): NTSTATUS; stdcall; external ntdll;

// Images

// PHNT::ntrtl.h
function RtlImageNtHeaderEx(
  Flags: Cardinal;
  [in] BaseOfImage: Pointer;
  Size: UInt64;
  out OutHeaders: PImageNtHeaders
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddressInSectionTable(
  [in] NtHeaders: PImageNtHeaders;
  [in] BaseOfImage: Pointer;
  VirtualAddress: Cardinal
): Pointer; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSectionTableFromVirtualAddress(
  [in] NtHeaders: PImageNtHeaders;
  [in] BaseOfImage: Pointer;
  VirtualAddress: Cardinal
): PImageSectionHeader; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlImageDirectoryEntryToData(
  [in] BaseOfImage: Pointer;
  MappedAsImage: Boolean;
  DirectoryEntry: TImageDirectoryEntry;
  out Size: Cardinal
): Pointer; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlImageRvaToSection(
  [in] NtHeaders: PImageNtHeaders;
  [in] BaseOfImage: Pointer;
  Rva: Cardinal
): PImageSectionHeader; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlImageRvaToVa(
  [in] NtHeaders: PImageNtHeaders;
  [in] BaseOfImage: Pointer;
  Rva: Cardinal;
  [in, out, opt] LastRvaSection: PPImageSectionHeader
): Pointer; stdcall; external ntdll;

// Memory

// SDK::winnt.h
function RtlCompareMemory(
  [in] Source1: Pointer;
  [in] Source2: Pointer;
  Length: NativeUInt
): NativeUInt; stdcall; external ntdll;

// WDK::ntifs.h
function RtlCompareMemoryUlong(
  [in] Source: Pointer;
  Length: NativeUInt;
  Pattern: Cardinal
): NativeUInt; stdcall; external ntdll;

// WDK::ntifs.h
procedure RtlFillMemoryUlong(
  [in] Destination: Pointer;
  Length: NativeUInt;
  Pattern: Cardinal
); stdcall; external ntdll;

// WDK::ntifs.h
procedure RtlFillMemoryUlonglong(
  [in] Destination: Pointer;
  Length: NativeUInt;
  Pattern: UInt64
); stdcall; external ntdll;

// Environment

// PHNT::ntrtl.h
function RtlCreateEnvironment(
  CloneCurrentEnvironment: Boolean;
  [allocates('RtlDestroyEnvironment')] out Environment: PEnvironment
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDestroyEnvironment(
  [in] Environment: PEnvironment
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetCurrentEnvironment(
  [in] Environment: PEnvironment;
  [out, opt] PreviousEnvironment: PPEnvironment
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetEnvironmentVariable(
  [in, out, opt] var Environment: PEnvironment;
  const Name: TNtUnicodeString;
  [in, opt] Value: PNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlQueryEnvironmentVariable_U(
  [in, opt] Environment: PEnvironment;
  const Name: TNtUnicodeString;
  var Value: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlExpandEnvironmentStrings_U(
  [in, opt] Environment: PEnvironment;
  const Source: TNtUnicodeString;
  var Destination: TNtUnicodeString;
  [out, opt] ReturnedLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Paths

// PHNT::ntrtl.h
function RtlDetermineDosPathNameType_U(
  [in] DosFileName: PWideChar
): TRtlPathType; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDosPathNameToNtPathName_U_WithStatus(
  [in] DosFileName: PWideChar;
  out NtFileName: TNtUnicodeString;
  [out, opt] FilePart: PPWideChar;
  [out, opt] RelativeName: Pointer
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[Result: Counter(ctBytes)]
function RtlGetCurrentDirectory_U(
  BufferLength: Cardinal;
  [out] Buffer: PWideChar
): Cardinal; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetCurrentDirectory_U(
  const PathName: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[Result: Counter(ctBytes)]
function RtlGetFullPathName_U(
  [in] FileName: PWideChar;
  BufferLength: Cardinal;
  [out] Buffer: PWideChar;
  [out, opt] FilePart: PPWideChar
): Cardinal; stdcall; external ntdll;

// rev
function RtlGetFullPathName_Ustr(
  const FileName: TNtUnicodeString;
  BufferLength: Cardinal;
  [out] Buffer: PWideChar;
  [out, opt] FilePart: PPWideChar;
  [out, opt] NameInvalid: PBoolean;
  [out, opt] BytesRequired: PCardinal
): Cardinal; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetLongestNtPathLength: Cardinal; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlIsThreadWithinLoaderCallout: Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDllShutdownInProgress: Boolean; stdcall; external ntdll;

// Heaps

// WDK::ntifs.h
function RtlAllocateHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  Size: NativeUInt
): Pointer; stdcall; external ntdll;

// WDK::ntifs.h
function RtlFreeHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSizeHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  [in] BaseAddress: Pointer
): NativeUInt; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlZeroHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlLockHeap(
  [in] HeapHandle: Pointer
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlUnlockHeap(
  [in] HeapHandle: Pointer
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlReAllocateHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer;
  Size: NativeUInt
): Pointer; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlCompactHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags
): NativeUInt; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlValidateHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer
): Boolean; stdcall; external ntdll;

// Messages

// PHNT::ntrtl.h
function RtlFindMessage(
  [in] DllBase: Pointer;
  MessageTableId: Cardinal;
  MessageLanguageId: Cardinal;
  MessageId: Cardinal;
  out MessageEntry: PMessageResourceEntry
): NTSTATUS; stdcall; external ntdll;

// Errors

// WDK::ntifs.h
function RtlNtStatusToDosError(
  Status: NTSTATUS
): TWin32Error; stdcall; external ntdll;

// WDK::ntifs.h
function RtlNtStatusToDosErrorNoTeb(
  Status: NTSTATUS
): TWin32Error; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetLastNtStatus: NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetLastWin32Error: TWin32Error; stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlSetLastWin32ErrorAndNtStatusFromNtStatus(
  Status: NTSTATUS
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlSetLastWin32Error(
  Win32Error: TWin32Error
); stdcall; external ntdll;

// Exceptions

// SDK::winnt.h
procedure RtlRaiseException(
  const ExceptionRecord: TExceptionRecord
); stdcall; external ntdll;

{$IFDEF Win64}
// SDK::rtlsupportapi.h
function RtlLookupFunctionEntry(
  ControlPc: UIntPtr;
  out ImageBase: UIntPtr;
  [in, out, opt] HistoryTable: PUnwindHistoryTable
): PRuntimeFunction; stdcall; external ntdll;
{$ENDIF}

{$IFDEF Win64}
// SDK::winnth.h
function RtlVirtualUnwind(
  HandlerType: TUnwindFlags;
  ImageBase: UIntPtr;
  ControlPc: UIntPtr;
  [in] FunctionEntry: PRuntimeFunction;
  [in, out] ContextRecord: PContext;
  out HandlerData: Pointer;
  out EstablisherFrame: UIntPtr;
  [in, out, opt] ContextPointers: PKNonVolatileContextPointer
): TExceptionRoutine; stdcall; external ntdll;
{$ENDIF}

// Random

// SDK::winternl.h
function RtlUniform(
  var Seed: Cardinal
): Cardinal; stdcall; external ntdll;

// Integers

// WDK::wdm.h
function RtlIntegerToUnicodeString(
  Value: Cardinal;
  Base: Cardinal;
  var Str: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlInt64ToUnicodeString(
  Value: UInt64;
  Base: Cardinal;
  var Str: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlUnicodeStringToInteger(
  const Str: TNtUnicodeString;
  Base: Cardinal;
  out Value: Cardinal
): NTSTATUS; stdcall; external ntdll;

// SIDs

// WDK::ntifs.h
function RtlValidSid(
  [in] Sid: PSid
): Boolean; stdcall; external ntdll;

// WDK::ntifs.h
function RtlEqualSid(
  [in] Sid1: PSid;
  [in] Sid2: PSid
): Boolean; stdcall; external ntdll;

// WDK::ntifs.h
function RtlEqualPrefixSid(
  [in] Sid1: PSid;
  [in] Sid2: PSid
): Boolean; stdcall; external ntdll;

// WDK::ntifs.h
function RtlLengthRequiredSid(
  SubAuthorityCount: Cardinal
): Cardinal; stdcall; external ntdll;

// WDK::ntifs.h
procedure RtlFreeSid(
  [in] Sid: PSid
); stdcall; external ntdll;

// WDK::ntifs.h
function RtlAllocateAndInitializeSid(
  const IdentifierAuthority: TSidIdentifierAuthority;
  SubAuthorityCount: Cardinal;
  SubAuthority0: Cardinal;
  SubAuthority1: Cardinal;
  SubAuthority2: Cardinal;
  SubAuthority3: Cardinal;
  SubAuthority4: Cardinal;
  SubAuthority5: Cardinal;
  SubAuthority6: Cardinal;
  SubAuthority7: Cardinal;
  [allocates('RtlFreeSid')] out Sid: PSid
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlInitializeSid(
  [out] Sid: PSid;
  [in] IdentifierAuthority: PSidIdentifierAuthority;
  SubAuthorityCount: Byte
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlIdentifierAuthoritySid(
  [in] Sid: PSid
): PSidIdentifierAuthority; stdcall; external ntdll;

// WDK::ntifs.h
function RtlSubAuthoritySid(
  [in] Sid: PSid;
  SubAuthority: Integer
): PCardinal; stdcall; external ntdll;

// WDK::ntifs.h
function RtlSubAuthorityCountSid(
  [in] Sid: PSid
): PByte; stdcall; external ntdll;

// WDK::ntifs.h
function RtlLengthSid(
  [in] Sid: PSid
): Cardinal; stdcall; external ntdll;

// WDK::ntifs.h
function RtlCopySid(
  DestinationSidLength: Cardinal;
  [out] DestinationSid: PSid;
  [in] SourceSid: PSid
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlCreateServiceSid(
  const ServiceName: TNtUnicodeString;
  [out] ServiceSid: PSid;
  var ServiceSidLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlLengthSidAsUnicodeString(
  [in] Sid: PSid;
  out StringLength: Integer
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlConvertSidToUnicodeString(
  var UnicodeString: TNtUnicodeString;
  [in] Sid: PSid;
  AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSidDominates(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  out Dominates: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSidEqualLevel(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  out EqualLevel: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSidIsHigherLevel(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  out HigherLevel: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[MinOSVersion(OsWin10RS2)]
function RtlDeriveCapabilitySidsFromName(
  const CapabilityName: TNtUnicodeString;
  [out] CapabilityGroupSid: PSid;
  [out] CapabilitySid: PSid
): NTSTATUS; stdcall; external ntdll delayed;

// Security Descriptors

// WDK::wdm.h
function RtlCreateSecurityDescriptor(
  [out] SecurityDescriptor: PSecurityDescriptor;
  Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlValidSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor
): Boolean; stdcall; external ntdll;

// WDK::wdm.h
function RtlLengthSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetControlSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out Control: TSecurityDescriptorControl;
  out Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetControlSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  ControlBitsOfInterest: TSecurityDescriptorControl;
  ControlBitsToSet: TSecurityDescriptorControl
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetAttributesSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  Control: TSecurityDescriptorControl;
  out Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlSetDaclSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  DaclPresent: Boolean;
  [in, opt] Dacl: PAcl;
  DaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGetDaclSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out DaclPresent: Boolean;
  out Dacl: PAcl;
  out DaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetSaclSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  SaclPresent: Boolean;
  [in, opt] Sacl: PAcl;
  SaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGetSaclSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out SaclPresent: Boolean;
  out Sacl: PAcl;
  out SaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlSetOwnerSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  [in, opt] Owner: PSid;
  OwnerDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGetOwnerSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out Owner: PSid;
  out OwnerDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlSetGroupSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  [in, opt] Group: PSid;
  GroupDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGetGroupSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out Group: PSid;
  out GroupDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlMakeSelfRelativeSD(
  [in] AbsoluteSecurityDescriptor: PSecurityDescriptor;
  [out] SelfRelativeSecurityDescriptor: PSecurityDescriptor;
  var BufferLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// Access masks

// WDK::ntddk.h
procedure RtlMapGenericMask(
  var AccessMask: TAccessMask;
  const GenericMapping: TGenericMapping
); stdcall; external ntdll;

// ACLs

// WDK::ntifs.h
function RtlCreateAcl(
  [out] Acl: PAcl;
  AclLength: Cardinal;
  AclRevision: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlValidAcl(
  [in] Acl: PAcl
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlQueryInformationAcl(
  [in] Acl: PAcl;
  [out] AclInformation: Pointer;
  AclInformationLength: Cardinal;
  AclInformationClass: TAclInformationClass
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlAddAce(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  StartingAceIndex: Integer;
  [in] AceList: Pointer;
  AceListLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlDeleteAce(
  [in] Acl: Pacl;
  AceIndex: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlGetAce(
  [in] Acl: PAcl;
  AceIndex: Integer;
  out Ace: PAce
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlAddAccessAllowedAceEx(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  AceFlags: Cardinal;
  AccessMask: TAccessMask;
  [in] Sid: PSid
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddAccessDeniedAceEx(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  AceFlags: Cardinal;
  AccessMask: TAccessMask;
  [in] Sid: PSid
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddAuditAccessAceEx(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  AceFlags: Cardinal;
  AccessMask: TAccessMask;
  [in] Sid: PSid;
  AuditSuccess: Boolean;
  AuditFailure: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddMandatoryAce(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  AceFlags: Cardinal;
  [in] Sid: PSid;
  AceType: Byte;
  AccessMask: TAccessMask
): NTSTATUS; stdcall; external ntdll;

// Misc security

// PHNT::ntrtl.h
function RtlAdjustPrivilege(
  Privilege: TSeWellKnownPrivilege;
  Enable: Boolean;
  Client: Boolean;
  out WasEnabled: Boolean
): NTSTATUS; stdcall; external ntdll;

// Private namespace

// PHNT::ntrtl.h
[Result: allocates('RtlDeleteBoundaryDescriptor')]
function RtlCreateBoundaryDescriptor(
  const Name: TNtUnicodeString;
  Flags: TBoundaryDescriptorFlags
): PObjectBoundaryDescriptor; stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlDeleteBoundaryDescriptor(
  [in] BoundaryDescriptor: PObjectBoundaryDescriptor
); stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddSIDToBoundaryDescriptor(
  var BoundaryDescriptor: PObjectBoundaryDescriptor;
  [in] RequiredSid: PSid
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddIntegrityLabelToBoundaryDescriptor(
  var BoundaryDescriptor: PObjectBoundaryDescriptor;
  [in] IntegrityLabel: PSid
): NTSTATUS; stdcall; external ntdll;

// System information

// PHNT::ntrtl.h
function RtlGetNtGlobalFlags: Cardinal; stdcall; external ntdll;

// User threads

// PHNT::ntrtl.h
procedure RtlUserThreadStart(
  [in] Func: TUserThreadStartRoutine;
  [in, opt] Parameter: Pointer
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlExitUserThread(
  ExitStatus: NTSTATUS
); stdcall; external ntdll;

// Stack support

// SDK::winnt.h
function RtlCaptureStackBackTrace(
  FramesToSkip: Cardinal;
  FramesToCapture: Cardinal;
  [out] BackTrace: Pointer;
  [out, opt] BackTraceHash: PCardinal
): Word; stdcall; external ntdll;

// WDK::ntddk.h
procedure RtlGetCallersAddress(
  out CallersAddress: Pointer;
  out CallersCaller: Pointer
); stdcall; external ntdll;

// SDK::rtlsupportapi.h
procedure RtlCaptureContext(
  [out] ContextRecord: PContext
); stdcall; external ntdll;

// SDK::rtlsupportapi.h
procedure RtlRestoreContext(
  [in] ContextRecord: PContext;
  [in, opt] ExceptionRecord: PExceptionRecord
); cdecl; external ntdll;

// MSDocs::win32/desktop-src/DevNotes/RtlGetUnloadEventTrace.md & PHNT::ntrtl.h
function RtlGetUnloadEventTrace
: PRtlUnloadEventTrace; stdcall; external ntdll;

// MSDocs::win32/desktop-src/DevNotes/RtlGetUnloadEventTraceEx.md & PHNT::ntrtl.h
procedure RtlGetUnloadEventTraceEx(
  out RtlpUnloadEventTraceExSize: PCardinal;
  out RtlpUnloadEventTraceExNumber: PCardinal;
  out RtlpUnloadEventTraceEx: PPRtlUnloadEventTrace
); stdcall; external ntdll;

// Appcontainer

// PHNT::ntrtl.h
[MinOSVersion(OsWin8)]
function RtlGetTokenNamedObjectPath(
  [Access(TOKEN_QUERY)] Token: THandle;
  [in, opt] Sid: PSid;
  [allocates('RtlFreeUnicodeString')] var ObjectPath: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll delayed;

// PHNT::ntrtl.h
[MinOSVersion(OsWin8)]
function RtlGetAppContainerParent(
  [in] AppContainerSid: PSid;
  [allocates('RtlFreeSid')] out AppContainerSidParent: PSid
): NTSTATUS; stdcall; external ntdll delayed;

// PHNT::ntrtl.h
[MinOSVersion(OsWin8)]
function RtlGetAppContainerSidType(
  [in] AppContainerSid: PSid;
  out AppContainerSidType: TAppContainerSidType
): NTSTATUS; stdcall; external ntdll delayed;

implementation

end.
