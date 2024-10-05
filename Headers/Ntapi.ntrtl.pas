unit Ntapi.ntrtl;

{
  This file defines prototypes for supplementary functions of the
  Run-Time Library from ntdll.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntmmapi, Ntapi.ntseapi, Ntapi.Versions,
  Ntapi.WinUser, DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  // Critical sections

  // SDK::winnt.h
  RTL_CRITICAL_SECTION_FLAG_NO_DEBUG_INFO = $01000000;
  RTL_CRITICAL_SECTION_FLAG_DYNAMIC_SPIN = $02000000;
  RTL_CRITICAL_SECTION_FLAG_STATIC_INIT = $04000000;
  RTL_CRITICAL_SECTION_FLAG_RESOURCE_TYPE = $08000000;
  RTL_CRITICAL_SECTION_FLAG_FORCE_DEBUG_INFO = $10000000;

  // Resources

  // PHNT::ntrtl.h
  RTL_RESOURCE_FLAG_LONG_TERM = $00000001;

  // Condition Variables

  // SDK::winnt.h
  RTL_CONDITION_VARIABLE_LOCKMODE_SHARED = $00000001;

  // Run Once

  // SDK::winnt.h
  RTL_RUN_ONCE_CHECK_ONLY = $00000001;
  RTL_RUN_ONCE_ASYNC = $00000002;
  RTL_RUN_ONCE_INIT_FAILED = $00000004;

  // SDK::winnt.h
  RTL_RUN_ONCE_CTX_RESERVED_BITS = 2;

  // SDK::ntstatus.h
  STATUS_PENDING = $00000103;

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
  RTL_USER_PROC_DEV_OVERRIDE_ENABLED = $00008000; // rev
  RTL_USER_PROC_OPTIN_PROCESS = $00020000;
  RTL_USER_PROC_SESSION_OWNER = $00040000; // rev
  RTL_USER_PROC_HANDLE_USER_CALLBACK_EXCEPTIONS = $00080000; // rev
  RTL_USER_PROC_PROTECTED_PROCESS = $00400000; // rev
  RTL_USER_PROC_SECURE_PROCESS = $80000000; // rev

  // PHNT::ntrtl.h - process cloning flags
  RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED = $00000001;
  RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES = $00000002;
  RTL_CLONE_PROCESS_FLAGS_NO_SYNCHRONIZE = $00000004;

  // rev
  RTL_PROCESS_REFLECTION_FLAGS_INHERIT_HANDLES = $0002;
  RTL_PROCESS_REFLECTION_FLAGS_NO_SUSPEND = $0004;
  RTL_PROCESS_REFLECTION_FLAGS_NO_SYNCHRONIZE = $0008;
  RTL_PROCESS_REFLECTION_FLAGS_NO_CLOSE_EVENT = $0010;

  // PHNT::ntrtl.h
  RTL_IMAGE_NT_HEADER_EX_FLAG_NO_RANGE_CHECK = $00000001;

  // PHNT::ntrtl.h
  RTL_USER_PROCESS_EXTENDED_PARAMETERS_VERSION = 1;

  // Re-declare for annotations
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

  // Critical Sections

  [FlagName(RTL_CRITICAL_SECTION_FLAG_NO_DEBUG_INFO, 'No Debug Info')]
  [FlagName(RTL_CRITICAL_SECTION_FLAG_DYNAMIC_SPIN, 'Dynamic Spin')]
  [FlagName(RTL_CRITICAL_SECTION_FLAG_STATIC_INIT, 'Static Init')]
  [FlagName(RTL_CRITICAL_SECTION_FLAG_RESOURCE_TYPE, 'Resource Type')]
  [FlagName(RTL_CRITICAL_SECTION_FLAG_FORCE_DEBUG_INFO, 'Force Debug Info')]
  TRtlCriticalSectionFlags = type Cardinal;

  // SDK::winnt.h
  [SDKName('RTL_CRITICAL_SECTION_DEBUG')]
  TRtlCriticalSectionDebug = record
    &Type: Word;
    CreatorBackTraceIndex: Word;
    CriticalSection: Pointer; // PRtlCriticalSection
    ProcessLocksList: TListEntry;
    EntryCount: Cardinal;
    ContentionCount: Cardinal;
    Flags: TRtlCriticalSectionFlags;
    CreatorBackTraceIndexHigh: Word;
    Identifier: Word;
  end;
  PRtlCriticalSectionDebug = ^TRtlCriticalSectionDebug;

  // SDK::winnt.h
  [SDKName('RTL_CRITICAL_SECTION')]
  TRtlCriticalSection = record
    DebugInfo: PRtlCriticalSectionDebug;
    LockCount: Integer;
    RecursionCount: Integer;
    OwningThread: TThreadId;
    LockSemaphore: THandle;
    SpinCount: TNativeUIntArray;
  end align 8;
  PRtlCriticalSection = ^TRtlCriticalSection;

  [SDKName('RTL_RESOURCE_DEBUG')]
  TRtlResourceDebug = type TRtlCriticalSectionDebug;
  PRtlResourceDebug = ^TRtlResourceDebug;

  // Resources

  [FlagName(RTL_RESOURCE_FLAG_LONG_TERM, 'Long-term')]
  TRtlResourceFlags = type Cardinal;

  // PHNT::ntrtl.h
  [SDKName('RTL_RESOURCE')]
  TRtlResource = record
    CriticalSection: TRtlCriticalSection;
    SharedSemaphore: THandle;
    [volatile] NumberOfWaitingShared: Cardinal;
    ExclusiveSemaphore: THandle;
    [volatile] NumberOfWaitingExclusive: Cardinal;
    [volatile] NumberOfActive: Integer;
    ExclusiveOwnerThread: TThreadId;
    Flags: TRtlResourceFlags;
    DebugInfo: PRtlResourceDebug;
  end;
  PRtlResource = ^TRtlResource;

  // SRW Locks

  // SDK::winnt.h
  [SDKName('RTL_SRWLOCK')]
  TRtlSRWLock = record
    Ptr: Pointer;
  end;
  PRtlSRWLock = ^TRtlSRWLock;

  // Condition Variables

  [FlagName(RTL_CONDITION_VARIABLE_LOCKMODE_SHARED, 'Lock Mode Shared')]
  TRtlConditionVariableFlags = type Cardinal;

  // SDK::winnt.h
  [SDKName('RTL_CONDITION_VARIABLE')]
  TRtlConditionVariable = record
    Ptr: Pointer;
  end;
  PRtlConditionVariable  = ^TRtlConditionVariable;

  // RunOnce

  [FlagName(RTL_RUN_ONCE_CHECK_ONLY, 'Check-only')]
  [FlagName(RTL_RUN_ONCE_ASYNC, 'Async')]
  [FlagName(RTL_RUN_ONCE_INIT_FAILED, 'Init Failed')]
  TRtlRunOnceFlags = type Cardinal;

  // SDK::winnt.h
  [SDKName('RTL_RUN_ONCE')]
  TRtlRunOnce = record
    Ptr: Pointer;
  end;
  PRtlRunOnce = ^TRtlRunOnce;

  // WDK::ntddk.h
  [SDKName('RTL_RUN_ONCE_INIT_FN')]
  TRtlRunOnceInitFn = function (
    [in, out] var RunOnce: TRtlRunOnce;
    [in, out, opt] Parameter: Pointer;
    [in, out, opt] Context: PPointer
  ): LongBool; stdcall;

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
  [FlagName(RTL_USER_PROC_SESSION_OWNER, 'Session Owner')]
  [FlagName(RTL_USER_PROC_HANDLE_USER_CALLBACK_EXCEPTIONS, 'Handle User Callback Exceptions')]
  [FlagName(RTL_USER_PROC_PROTECTED_PROCESS, 'Protected Process')]
  [FlagName(RTL_USER_PROC_SECURE_PROCESS, 'Secure Process')]
  TRtlUserProcessFlags = type Cardinal;

  [FlagName(RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED, 'Create Suspended')]
  [FlagName(RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES, 'Inherit Handles')]
  [FlagName(RTL_CLONE_PROCESS_FLAGS_NO_SYNCHRONIZE, 'No Synchronize')]
  TRtlProcessCloneFlags = type Cardinal;

  [FlagName(RTL_PROCESS_REFLECTION_FLAGS_INHERIT_HANDLES, 'Inherit Handles')]
  [FlagName(RTL_PROCESS_REFLECTION_FLAGS_NO_SUSPEND, 'No Suspend')]
  [FlagName(RTL_PROCESS_REFLECTION_FLAGS_NO_SYNCHRONIZE, 'No Synchronize')]
  [FlagName(RTL_PROCESS_REFLECTION_FLAGS_NO_CLOSE_EVENT, 'No Close Event')]
  TRtlProcessReflectionFlags = type Cardinal;

  [Hex]
  TRtlUserProcessParametersDebugFlags = type Cardinal;

  // PHNT::ntrtl.h
  [SDKName('RTL_USER_PROCESS_PARAMETERS')]
  TRtlUserProcessParameters = record
    [Bytes, Unlisted] MaximumLength: Cardinal;
    [RecordSize] Length: Cardinal;

    Flags: TRtlUserProcessFlags;
    DebugFlags: TRtlUserProcessParametersDebugFlags;

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

    WindowFlags: Cardinal; // ProcessThreadsApi.TStartupFlags
    ShowWindowFlags: TShowMode32;
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
    [RecordSize] Length: Cardinal;
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
  TUserThreadStartRoutine = function (
    [in, opt] ThreadParameter: Pointer
  ): NTSTATUS; stdcall;

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
    [Offset] OffsetToFileName: Word;
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
    [Offset] NextOffset: Word;
    [Aggregate] BaseInfo: TRtlProcessModuleInformation;
    ImageChecksum: Cardinal;
    TimeDateStamp: TUnixTime;
    DefaultBase: Pointer;
  end;
  PRtlProcessModuleInformationEx = ^TRtlProcessModuleInformationEx;

  // Paths

  // PHNT::ntrtl.h
  [SDKName('RTL_PATH_TYPE')]
  [NamingStyle(nsCamelCase, 'RtlPathType')]
  TRtlPathType = (
    RtlPathTypeUnknown = 0,
    RtlPathTypeUncAbsolute = 1,    // \\Share\Path
    RtlPathTypeDriveAbsolute = 2,  // C:\Path
    RtlPathTypeDriveRelative = 3,  // C:Path
    RtlPathTypeRooted = 4,         // \Path
    RtlPathTypeRelative = 5,       // Path
    RtlPathTypeLocalDevice = 6,    // \\?\Path or \\.\Path
    RtlPathTypeRootLocalDevice = 7 // \\? or \\.
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

const
  // SDK::winnt.h
  RTL_SRWLOCK_INIT: TRtlSRWLock = (Ptr: nil);
  RTL_CONDITION_VARIABLE_INIT: TRtlConditionVariable = (Ptr: nil);
  RTL_RUN_ONCE_INIT: TRtlRunOnce = (Ptr: nil);

// Critical sections

// PHNT::ntrtl.h
function RtlInitializeCriticalSection(
  [out, ReleaseWith('RtlDeleteCriticalSection')]
    out CriticalSection: TRtlCriticalSection
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlInitializeCriticalSectionAndSpinCount(
  [out, ReleaseWith('RtlDeleteCriticalSection')]
    out CriticalSection: TRtlCriticalSection;
  [in] SpinCount: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlInitializeCriticalSectionEx(
  [out, ReleaseWith('RtlDeleteCriticalSection')]
    out CriticalSection: TRtlCriticalSection;
  [in] SpinCount: Cardinal;
  [in] Flags: TRtlCriticalSectionFlags
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDeleteCriticalSection(
  [in, out] CriticalSection: PRtlCriticalSection
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlEnterCriticalSection(
  [in, out] CriticalSection: PRtlCriticalSection
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlLeaveCriticalSection(
  [in, out] CriticalSection: PRtlCriticalSection
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlTryEnterCriticalSection(
  [in, out] CriticalSection: PRtlCriticalSection
): LongBool; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlIsCriticalSectionLocked(
  [in] CriticalSection: PRtlCriticalSection
): LongBool; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlIsCriticalSectionLockedByThread(
  [in] CriticalSection: PRtlCriticalSection
): LongBool; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetCriticalSectionRecursionCount(
  [in] CriticalSection: PRtlCriticalSection
): Cardinal; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetCriticalSectionSpinCount(
  [in, out] CriticalSection: PRtlCriticalSection;
  [in] SpinCount: Cardinal
): Cardinal; stdcall; external ntdll;

// Resources

// PHNT::ntrtl.h
procedure RtlInitializeResource(
  [out, ReleaseWith('RtlDeleteResource')] out Resource: TRtlResource
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlDeleteResource(
  [in, out] Resource: PRtlResource
); stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAcquireResourceShared(
  [in, out] Resource: PRtlResource;
  [in] Wait: Boolean
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAcquireResourceExclusive(
  [in, out] Resource: PRtlResource;
  [in] Wait: Boolean
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlReleaseResource(
  [in, out] Resource: PRtlResource
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlConvertSharedToExclusive(
  [in, out] Resource: PRtlResource
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlConvertExclusiveToShared(
  [in, out] Resource: PRtlResource
); stdcall; external ntdll;

// SRW Locks

// PHNT::ntrtl.h
procedure RtlAcquireSRWLockExclusive(
  [in, out] SRWLock: PRtlSRWLock
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlAcquireSRWLockShared(
  [in, out] SRWLock: PRtlSRWLock
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlReleaseSRWLockExclusive(
  [in, out] SRWLock: PRtlSRWLock
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlReleaseSRWLockShared(
  [in, out] SRWLock: PRtlSRWLock
); stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlTryAcquireSRWLockExclusive(
  [in, out] SRWLock: PRtlSRWLock
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlTryAcquireSRWLockShared(
  [in, out] SRWLock: PRtlSRWLock
): Boolean; stdcall; external ntdll;

// Condition Variables

// PHNT::ntrtl.h
function RtlSleepConditionVariableCS(
  [in, out] ConditionVariable: PRtlConditionVariable;
  [in, out] CriticalSection: PRtlCriticalSection;
  [in, opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSleepConditionVariableSRW(
  [in, out] ConditionVariable: PRtlConditionVariable;
  [in, out] SRWLock: PRtlSRWLock;
  [in, opt] Timeout: PLargeInteger;
  [in] Flags: TRtlConditionVariableFlags
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlWakeConditionVariable(
  [in, out] ConditionVariable: PRtlConditionVariable
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlWakeAllConditionVariable(
  [in, out] ConditionVariable: PRtlConditionVariable
); stdcall; external ntdll;

// Run Once

// WDK::ntddk.h
function RtlRunOnceExecuteOnce(
  [in, out] RunOnce: PRtlRunOnce;
  [in] InitFn: TRtlRunOnceInitFn;
  [in, out, opt] Parameter: Pointer;
  [out, opt, MayReturnNil] Context: PPointer
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
function RtlRunOnceBeginInitialize(
  [in, out] RunOnce: PRtlRunOnce;
  [in] Flags: TRtlRunOnceFlags;
  [out, opt, MayReturnNil] Context: PPointer
): NTSTATUS; stdcall; external ntdll;

// WDK::ntddk.h
function RtlRunOnceComplete(
  [in, out] RunOnce: PRtlRunOnce;
  [in] Flags: TRtlRunOnceFlags;
  [in, opt] Context: Pointer
): NTSTATUS; stdcall; external ntdll;

// Strings

// WDK::wdm.h
procedure RtlFreeUnicodeString(
  [in, out] UnicodeString: PNtUnicodeString
); stdcall; external ntdll;

// WDK::wdm.h
function RtlCompareString(
  [in] const String1: TNtAnsiString;
  [in] const String2: TNtAnsiString;
  [in] CaseInSensitive: Boolean
): Integer; stdcall; external ntdll;

// WDK::ntddk.h
function RtlEqualString(
  [in] const String1: TNtAnsiString;
  [in] const String2: TNtAnsiString;
  [in] CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

// WDK::wdm.h
function RtlCompareUnicodeString(
  [in] const String1: TNtUnicodeString;
  [in] const String2: TNtUnicodeString;
  [in] CaseInSensitive: Boolean
): Integer; stdcall; external ntdll;

// WDK::wdm.h
function RtlEqualUnicodeString(
  [in] const String1: TNtUnicodeString;
  [in] const String2: TNtUnicodeString;
  [in] CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

// WDK::ntifs.h
function RtlPrefixString(
  [in] const String1: TNtAnsiString;
  [in] const String2: TNtAnsiString;
  [in] CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

// WDK::wdm.h
function RtlHashUnicodeString(
  [in] const Str: TNtUnicodeString;
  [in] CaseInSensitive: Boolean;
  [in] HashAlgorithm: THashStringAlgorithm;
  [out] out HashValue: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlPrefixUnicodeString(
  [in] const String1: TNtUnicodeString;
  [in] const String2: TNtUnicodeString;
  [in] CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

// WDK::wdm.h
function RtlAppendUnicodeStringToString(
  [in, out] var Destination: TNtUnicodeString;
  [in] const Source: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlAppendUnicodeToString(
  [in, out] var Destination: TNtUnicodeString;
  [in] Source: PWideChar
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlUpcaseUnicodeChar(
  [in] SourceCharacter: WideChar
): WideChar; stdcall; external ntdll;

// WDK::wdm.h
function RtlUpcaseUnicodeString(
  [in, out] var DestinationString: TNtUnicodeString;
  [in] const SourceString: TNtUnicodeString;
  [in] AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlDowncaseUnicodeChar(
  [in] SourceCharacter: WideChar
): WideChar; stdcall; external ntdll;

// WDK::wdm.h
function RtlDowncaseUnicodeString(
  [in, out] var DestinationString: TNtUnicodeString;
  [in] const SourceString: TNtUnicodeString;
  [in] AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlStringFromGUID(
  [in] const Guid: TGuid;
  [out, ReleaseWith('RtlFreeUnicodeString')] out GuidString: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGUIDFromString(
  [in] const GuidString: TNtUnicodeString;
  [out] out Guid: TGuid
): NTSTATUS; stdcall; external ntdll;

// Processes

// PHNT::ntrtl.h
function RtlCreateProcessParametersEx(
  [out, ReleaseWith('RtlDestroyProcessParameters')] out ProcessParameters:
    PRtlUserProcessParameters;
  [in] const ImagePathName: TNtUnicodeString;
  [in, opt] DllPath: PNtUnicodeString;
  [in, opt] CurrentDirectory: PNtUnicodeString;
  [in, opt] CommandLine: PNtUnicodeString;
  [in, opt] Environment: PEnvironment;
  [in, opt] WindowTitle: PNtUnicodeString;
  [in, opt] DesktopInfo: PNtUnicodeString;
  [in, opt] ShellInfo: PNtUnicodeString;
  [in, opt] RuntimeData: PNtUnicodeString;
  [in] Flags: TRtlUserProcessFlags
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDestroyProcessParameters(
  [in] ProcessParameters: PRtlUserProcessParameters
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlNormalizeProcessParams(
  [in, out] ProcessParameters: PRtlUserProcessParameters
): PRtlUserProcessParameters; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDeNormalizeProcessParams(
  [in, out] ProcessParameters: PRtlUserProcessParameters
): PRtlUserProcessParameters; stdcall; external ntdll;

// PHNT::ntrtl.h
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function RtlCreateUserProcess(
  [in] const NtImagePathName: TNtUnicodeString;
  [in] AttributesDeprecated: Cardinal;
  [in] ProcessParameters: PRtlUserProcessParameters;
  [in, opt] ProcessSecurityDescriptor: PSecurityDescriptor;
  [in, opt] ThreadSecurityDescriptor: PSecurityDescriptor;
  [in, opt, Access(PROCESS_CREATE_PROCESS)] ParentProcess: THandle;
  [in] InheritHandles: Boolean;
  [in, opt, Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle;
  [in, opt, Access(TOKEN_ASSIGN_PRIMARY)] TokenHandle: THandle;
  [out, ReleaseWith('NtClose')] out ProcessInformation:
    TRtlUserProcessInformation
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[MinOSVersion(OsWin10RS2)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function RtlCreateUserProcessEx(
  [in] const NtImagePathName: TNtUnicodeString;
  [in] ProcessParameters: PRtlUserProcessParameters;
  [in] InheritHandles: Boolean;
  [in, opt] ExtendedParameters: PRtlUserProcessExtendedParameters;
  [out, ReleaseWith('NtClose')] out ProcessInformation:
    TRtlUserProcessInformation
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_RtlCreateUserProcessEx: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'RtlCreateUserProcessEx';
);

// PHNT::ntrtl.h
procedure RtlExitUserProcess(
  [in] ExitStatus: NTSTATUS
); stdcall external ntdll;

// PHNT::ntrtl.h
function RtlCloneUserProcess(
  [in] ProcessFlags: TRtlProcessCloneFlags;
  [in, opt] ProcessSecurityDescriptor: PSecurityDescriptor;
  [in, opt] ThreadSecurityDescriptor: PSecurityDescriptor;
  [in, opt, Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle;
  [out, ReleaseWith('NtClose')] out ProcessInformation:
    TRtlUserProcessInformation
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlCreateProcessReflection(
  [in, Access(PROCESS_CREATE_REFLECTION)] ProcessHandle: THandle;
  [in] Flags: TRtlProcessReflectionFlags;
  [in, opt] StartRoutine: Pointer;
  [in, opt] StartContext: Pointer;
  [in, opt] EventHandle: THandle;
  [out, ReleaseWith('NtClose')] out ReflectionInformation:
    TRtlpProcessReflectionInformation
): NTSTATUS; stdcall; external ntdll;

// Threads

// PHNT::ntrtl.h
function RtlCreateUserThread(
  [in, Access(PROCESS_CREATE_THREAD)] Process: THandle;
  [in, opt] ThreadSecurityDescriptor: PSecurityDescriptor;
  [in] CreateSuspended: Boolean;
  [in, opt] ZeroBits: Cardinal;
  [in, opt] MaximumStackSize: NativeUInt;
  [in, opt] CommittedStackSize: NativeUInt;
  [in] StartAddress: TUserThreadStartRoutine;
  [in, opt] Parameter: Pointer;
  [out, ReleaseWith('NtClose')] out Thread: THandle;
  [out, opt] ClientId: PClientId
): NTSTATUS; stdcall; external ntdll;

// Extended thread context

{$IFDEF WIN64}
// PHNT::ntrtl.h
function RtlWow64GetThreadContext(
  [in, Access(THREAD_GET_CONTEXT)] ThreadHandle: THandle;
  [in, out] ThreadContext: PContext32
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlWow64SetThreadContext(
  [in, Access(THREAD_SET_INFORMATION)] ThreadHandle: THandle;
  [in, out] ThreadContext: PContext32
): NTSTATUS; stdcall; external ntdll;
{$ENDIF}

// PHNT::ntrtl.h
function RtlRemoteCall(
  [in, Access(PROCESS_VM_WRITE)] Process: THandle;
  [in, Access(THREAD_SUSPEND_RESUME or THREAD_GET_CONTEXT)] Thread: THandle;
  [in] CallSite: Pointer;
  [in, NumberOfElements] ArgumentCount: Cardinal;
  [in, ReadsFrom] const Arguments: TArray<NativeUInt>;
  [in] PassContext: Boolean;
  [in] AlreadySuspended: Boolean
): NTSTATUS; stdcall; external ntdll;

// Memory

// SDK::winnt.h
function RtlCompareMemory(
  [in, ReadsFrom] Source1: Pointer;
  [in, ReadsFrom] Source2: Pointer;
  [in, NumberOfBytes] Length: NativeUInt
): NativeUInt; stdcall; external ntdll;

// WDK::ntifs.h
function RtlCompareMemoryUlong(
  [in, ReadsFrom] Source: Pointer;
  [in, NumberOfBytes] Length: NativeUInt;
  [in] Pattern: Cardinal
): NativeUInt; stdcall; external ntdll;

// WDK::ntifs.h
procedure RtlFillMemoryUlong(
  [out, WritesTo] Destination: Pointer;
  [in, NumberOfBytes] Length: NativeUInt;
  [in] Pattern: Cardinal
); stdcall; external ntdll;

// WDK::ntifs.h
procedure RtlFillMemoryUlonglong(
  [out, WritesTo] Destination: Pointer;
  [in, NumberOfBytes] Length: NativeUInt;
  [in] Pattern: UInt64
); stdcall; external ntdll;

// Environment

// PHNT::ntrtl.h
function RtlCreateEnvironment(
  [in] CloneCurrentEnvironment: Boolean;
  [out, ReleaseWith('RtlDestroyEnvironment')] out Environment: PEnvironment
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
  [in] const Name: TNtUnicodeString;
  [in, opt] Value: PNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlQueryEnvironmentVariable_U(
  [in, opt] Environment: PEnvironment;
  [in] const Name: TNtUnicodeString;
  [in, out] var Value: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlExpandEnvironmentStrings_U(
  [in, opt] Environment: PEnvironment;
  [in] const Source: TNtUnicodeString;
  [in, out] var Destination: TNtUnicodeString;
  [out, opt, NumberOfBytes] ReturnedLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Paths

// PHNT::ntrtl.h
function RtlDetermineDosPathNameType_U(
  [in] DosFileName: PWideChar
): TRtlPathType; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlDosPathNameToNtPathName_U_WithStatus(
  [in] DosFileName: PWideChar;
  [out, ReleaseWith('RtlFreeUnicodeString')] out NtFileName: TNtUnicodeString;
  [out, opt] FilePart: PPWideChar;
  [out, opt] RelativeName: Pointer
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[Result: NumberOfBytes]
function RtlGetCurrentDirectory_U(
  [in, NumberOfBytes] BufferLength: Cardinal;
  [out, WritesTo] Buffer: PWideChar
): Cardinal; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetCurrentDirectory_U(
  [in] const PathName: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[Result: NumberOfBytes]
function RtlGetFullPathName_U(
  [in] FileName: PWideChar;
  [in, NumberOfBytes] BufferLength: Cardinal;
  [out, WritesTo] Buffer: PWideChar;
  [out, opt] FilePart: PPWideChar
): Cardinal; stdcall; external ntdll;

// PHNT::ntrtl.h
[Result: NumberOfElements]
function RtlGetLongestNtPathLength(
): Cardinal; stdcall; external ntdll;

// Heaps

// WDK::ntifs.h
[Result: MayReturnNil]
[Result: ReleaseWith('RtlFreeHeap')]
function RtlAllocateHeap(
  [in] HeapHandle: Pointer;
  [in] Flags: THeapFlags;
  [in] Size: NativeUInt
): Pointer; stdcall; external ntdll;

// WDK::ntifs.h
function RtlFreeHeap(
  [in] HeapHandle: Pointer;
  [in] Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
[Result: NumberOfBytes]
function RtlSizeHeap(
  [in] HeapHandle: Pointer;
  [in] Flags: THeapFlags;
  [in] BaseAddress: Pointer
): NativeUInt; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlZeroHeap(
  [in] HeapHandle: Pointer;
  [in] Flags: THeapFlags
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[Result: ReleaseWith('RtlUnlockHeap')]
function RtlLockHeap(
  [in] HeapHandle: Pointer
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlUnlockHeap(
  [in] HeapHandle: Pointer
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
[Result: MayReturnNil]
function RtlReAllocateHeap(
  [in] HeapHandle: Pointer;
  [in] Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer;
  [in] Size: NativeUInt
): Pointer; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlCompactHeap(
  [in] HeapHandle: Pointer;
  [in] Flags: THeapFlags
): NativeUInt; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlValidateHeap(
  [in] HeapHandle: Pointer;
  [in] Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer
): Boolean; stdcall; external ntdll;

// Messages

// PHNT::ntrtl.h
function RtlFindMessage(
  [in] DllBase: Pointer;
  [in] MessageTableId: Cardinal;
  [in] MessageLanguageId: Cardinal;
  [in] MessageId: Cardinal;
  [out] out MessageEntry: PMessageResourceEntry
): NTSTATUS; stdcall; external ntdll;

// rev
function RtlLoadString(
  [in] DllHandle: Pointer;
  [in] StringId: Cardinal;
  [in] StringLanguage: PWideChar;
  [in] Flags: Cardinal;
  [out] out ReturnString: PWideChar;
  [out, opt, NumberOfBytes] out ReturnStringLen: Word;
  [out, opt, WritesTo] ReturnLanguageName: PWideChar;
  [in, out, opt] ReturnLanguageLen: PCardinal
): NTSTATUS; stdcall external ntdll;

// Errors

// WDK::ntifs.h
function RtlNtStatusToDosError(
  [in] Status: NTSTATUS
): TWin32Error; stdcall; external ntdll;

// WDK::ntifs.h
function RtlNtStatusToDosErrorNoTeb(
  [in] Status: NTSTATUS
): TWin32Error; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetLastNtStatus(
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetLastWin32Error(
): TWin32Error; stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlSetLastWin32ErrorAndNtStatusFromNtStatus(
  [in] Status: NTSTATUS
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlSetLastWin32Error(
  [in] Win32Error: TWin32Error
); stdcall; external ntdll;

// Exceptions

// SDK::winnt.h
procedure RtlRaiseException(
  [in] const ExceptionRecord: TExceptionRecord
); stdcall; external ntdll;

// Random

// SDK::winternl.h
function RtlUniform(
  [in, out] var Seed: Cardinal
): Cardinal; stdcall; external ntdll;

// Integers

// WDK::wdm.h
function RtlIntegerToUnicodeString(
  [in] Value: Cardinal;
  [in] Base: Cardinal;
  [in, out] var Str: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlInt64ToUnicodeString(
  [in] Value: UInt64;
  [in] Base: Cardinal;
  [in, out] var Str: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlUnicodeStringToInteger(
  [in] const Str: TNtUnicodeString;
  [in] Base: Cardinal;
  [out] out Value: Cardinal
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
[Result: NumberOfBytes]
function RtlLengthRequiredSid(
  [in] SubAuthorityCount: Cardinal
): Cardinal; stdcall; external ntdll;

// WDK::ntifs.h
procedure RtlFreeSid(
  [in] Sid: PSid
); stdcall; external ntdll;

// WDK::ntifs.h
function RtlAllocateAndInitializeSid(
  [in] const IdentifierAuthority: TSidIdentifierAuthority;
  [in] SubAuthorityCount: Cardinal;
  [in] SubAuthority0: Cardinal;
  [in] SubAuthority1: Cardinal;
  [in] SubAuthority2: Cardinal;
  [in] SubAuthority3: Cardinal;
  [in] SubAuthority4: Cardinal;
  [in] SubAuthority5: Cardinal;
  [in] SubAuthority6: Cardinal;
  [in] SubAuthority7: Cardinal;
  [out, ReleaseWith('RtlFreeSid')] out Sid: PSid
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlInitializeSid(
  [out, WritesTo] Sid: PSid;
  [in] IdentifierAuthority: PSidIdentifierAuthority;
  [in] SubAuthorityCount: Byte
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlIdentifierAuthoritySid(
  [in] Sid: PSid
): PSidIdentifierAuthority; stdcall; external ntdll;

// WDK::ntifs.h
function RtlSubAuthoritySid(
  [in] Sid: PSid;
  [in] SubAuthority: Integer
): PCardinal; stdcall; external ntdll;

// WDK::ntifs.h
function RtlSubAuthorityCountSid(
  [in] Sid: PSid
): PByte; stdcall; external ntdll;

// WDK::ntifs.h
[Result: NumberOfBytes]
function RtlLengthSid(
  [in] Sid: PSid
): Cardinal; stdcall; external ntdll;

// WDK::ntifs.h
function RtlCopySid(
  [in, NumberOfBytes] DestinationSidLength: Cardinal;
  [out, WritesTo] DestinationSid: PSid;
  [in] SourceSid: PSid
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlCreateServiceSid(
  [in] const ServiceName: TNtUnicodeString;
  [out, WritesTo] ServiceSid: PSid;
  [in, out, NumberOfBytes] var ServiceSidLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlCreateVirtualAccountSid(
  [in] const Name: TNtUnicodeString;
  [in] BaseSubAuthority: Cardinal;
  [out, WritesTo] ServiceSid: PSid;
  [in, out, NumberOfBytes] var ServiceSidLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlLengthSidAsUnicodeString(
  [in] Sid: PSid;
  [out, NumberOfBytes] out StringLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlConvertSidToUnicodeString(
  [in, out, ReleaseWith('RtlFreeUnicodeString')]
    var UnicodeString: TNtUnicodeString;
  [in] Sid: PSid;
  [in] AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSidDominates(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  [out] out Dominates: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSidEqualLevel(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  [out] out EqualLevel: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSidIsHigherLevel(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  [out] out HigherLevel: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
[MinOSVersion(OsWin10TH1)]
function RtlDeriveCapabilitySidsFromName(
  [in] const CapabilityName: TNtUnicodeString;
  [out, WritesTo] CapabilityGroupSid: PSid;
  [out, WritesTo] CapabilitySid: PSid
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_RtlDeriveCapabilitySidsFromName: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'RtlDeriveCapabilitySidsFromName';
);

// Security Descriptors

// WDK::wdm.h
function RtlCreateSecurityDescriptor(
  [out, WritesTo] SecurityDescriptor: PSecurityDescriptor;
  [in] Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlValidSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor
): Boolean; stdcall; external ntdll;

// WDK::wdm.h
[Result: NumberOfBytes]
function RtlLengthSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor
): Cardinal; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlGetControlSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  [out] out Control: TSecurityDescriptorControl;
  [out] out Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetControlSecurityDescriptor(
  [in, out, WritesTo] SecurityDescriptor: PSecurityDescriptor;
  [in] ControlBitsOfInterest: TSecurityDescriptorControl;
  [in] ControlBitsToSet: TSecurityDescriptorControl
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetAttributesSecurityDescriptor(
  [in, out, WritesTo] SecurityDescriptor: PSecurityDescriptor;
  [in] Control: TSecurityDescriptorControl;
  [out] out Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlSetDaclSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  [in] DaclPresent: Boolean;
  [in, opt] Dacl: PAcl;
  [in] DaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGetDaclSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  [out] out DaclPresent: Boolean;
  [out] out Dacl: PAcl;
  [out] out DaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetSaclSecurityDescriptor(
  [in, out, WritesTo] SecurityDescriptor: PSecurityDescriptor;
  [in] SaclPresent: Boolean;
  [in, opt] Sacl: PAcl;
  [in] SaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGetSaclSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  [out] out SaclPresent: Boolean;
  [out] out Sacl: PAcl;
  [out] out SaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlSetOwnerSecurityDescriptor(
  [in, out, WritesTo] SecurityDescriptor: PSecurityDescriptor;
  [in, opt] Owner: PSid;
  [in] OwnerDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGetOwnerSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  [out] out Owner: PSid;
  [out] out OwnerDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlSetGroupSecurityDescriptor(
  [in, out, WritesTo] SecurityDescriptor: PSecurityDescriptor;
  [in, opt] Group: PSid;
  [in] GroupDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function RtlGetGroupSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  [out] out Group: PSid;
  [out] out GroupDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlMakeSelfRelativeSD(
  [in] AbsoluteSecurityDescriptor: PSecurityDescriptor;
  [out, WritesTo] SelfRelativeSecurityDescriptor: PSecurityDescriptor;
  [in, out, NumberOfBytes] var BufferLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// Access masks

// WDK::ntddk.h
procedure RtlMapGenericMask(
  [in, out] var AccessMask: TAccessMask;
  [in] const GenericMapping: TGenericMapping
); stdcall; external ntdll;

// ACLs

// WDK::ntifs.h
function RtlCreateAcl(
  [out, WritesTo] Acl: PAcl;
  [in, NumberOfBytes] AclLength: Cardinal;
  [in] AclRevision: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlValidAcl(
  [in] Acl: PAcl
): Boolean; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlQueryInformationAcl(
  [in] Acl: PAcl;
  [out, WritesTo] AclInformation: Pointer;
  [in, NumberOfBytes] AclInformationLength: Cardinal;
  [in] AclInformationClass: TAclInformationClass
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlAddAce(
  [in, out] Acl: PAcl;
  [in] AceRevision: Cardinal;
  [in] StartingAceIndex: Integer;
  [in, ReadsFrom] AceList: Pointer;
  [in, NumberOfBytes] AceListLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlDeleteAce(
  [in, out] Acl: Pacl;
  [in] AceIndex: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlGetAce(
  [in] Acl: PAcl;
  [in] AceIndex: Integer;
  [out] out Ace: PAce
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function RtlAddAccessAllowedAceEx(
  [in, out] Acl: PAcl;
  [in] AceRevision: Cardinal;
  [in] AceFlags: Cardinal;
  [in] AccessMask: TAccessMask;
  [in] Sid: PSid
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddAccessDeniedAceEx(
  [in, out] Acl: PAcl;
  [in] AceRevision: Cardinal;
  [in] AceFlags: Cardinal;
  [in] AccessMask: TAccessMask;
  [in] Sid: PSid
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddAuditAccessAceEx(
  [in] Acl: PAcl;
  [in] AceRevision: Cardinal;
  [in] AceFlags: Cardinal;
  [in] AccessMask: TAccessMask;
  [in] Sid: PSid;
  [in] AuditSuccess: Boolean;
  [in] AuditFailure: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlAddMandatoryAce(
  [in, out] Acl: PAcl;
  [in] AceRevision: Cardinal;
  [in] AceFlags: Cardinal;
  [in] Sid: PSid;
  [in] AceType: Byte;
  [in] AccessMask: TAccessMask
): NTSTATUS; stdcall; external ntdll;

// Misc security

// PHNT::ntrtl.h
function RtlAdjustPrivilege(
  [in] Privilege: TSeWellKnownPrivilege;
  [in] Enable: Boolean;
  [in] Client: Boolean;
  [out] out WasEnabled: Boolean
): NTSTATUS; stdcall; external ntdll;

// User threads

// PHNT::ntrtl.h
procedure RtlUserThreadStart(
  [in] Func: TUserThreadStartRoutine;
  [in, opt] Parameter: Pointer
); stdcall; external ntdll;

// PHNT::ntrtl.h
procedure RtlExitUserThread(
  [in] ExitStatus: NTSTATUS
); stdcall; external ntdll;

// Stack support

// SDK::winnt.h
function RtlCaptureStackBackTrace(
  [in] FramesToSkip: Cardinal;
  [in, NumberOfElements] FramesToCapture: Cardinal;
  [out, WritesTo] BackTrace: Pointer;
  [out, opt] BackTraceHash: PCardinal
): Word; stdcall; external ntdll;

// WDK::ntddk.h
procedure RtlGetCallersAddress(
  [out] out CallersAddress: Pointer;
  [out] out CallersCaller: Pointer
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
  [out] out RtlpUnloadEventTraceExSize: PCardinal;
  [out] out RtlpUnloadEventTraceExNumber: PCardinal;
  [out] out RtlpUnloadEventTraceEx: PPRtlUnloadEventTrace
); stdcall; external ntdll;

// Appcontainer

// PHNT::ntrtl.h
[MinOSVersion(OsWin10RS2)]
function RtlGetTokenNamedObjectPath(
  [in, Access(TOKEN_QUERY)] Token: THandle;
  [in, opt] Sid: PSid;
  [in, out, ReleaseWith('RtlFreeUnicodeString')] var ObjectPath: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_RtlGetTokenNamedObjectPath: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'RtlGetTokenNamedObjectPath';
);

// PHNT::ntrtl.h
[MinOSVersion(OsWin81)]
function RtlGetAppContainerParent(
  [in] AppContainerSid: PSid;
  [out, ReleaseWith('RtlFreeSid')] out AppContainerSidParent: PSid
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_RtlGetAppContainerParent: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'RtlGetAppContainerParent';
);

// PHNT::ntrtl.h
[MinOSVersion(OsWin8)]
function RtlIsCapabilitySid(
  [in] Sid: PSid
): Boolean; stdcall; external ntdll delayed;

var delayed_RtlIsCapabilitySid: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'RtlIsCapabilitySid';
);

// PHNT::ntrtl.h
[MinOSVersion(OsWin81)]
function RtlGetAppContainerSidType(
  [in] AppContainerSid: PSid;
  [out] out AppContainerSidType: TAppContainerSidType
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_RtlGetAppContainerSidType: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'RtlGetAppContainerSidType';
);

{ Linked list macros }

// WDK::wdm.h
procedure InitializeListHead(
  [out] ListHead: PListEntry
);

// WDK::wdm.h
function IsListEmpty(
  [in] ListHead: PListEntry
): Boolean;

// WDK::wdm.h
function RemoveEntryList(
  [in] Entry: PListEntry
): Boolean;

// WDK::wdm.h
function RemoveHeadList(
  [in, out] ListHead: PListEntry
): PListEntry;

// WDK::wdm.h
function RemoveTailList(
  [in, out] ListHead: PListEntry
): PListEntry;

// WDK::wdm.h
procedure InsertTailList(
  [in, out] ListHead: PListEntry;
  [in, out] Entry: PListEntry
);

// WDK::wdm.h
procedure InsertHeadList(
  [in, out] ListHead: PListEntry;
  [in, out] Entry: PListEntry
);

// WDK::wdm.h
procedure AppendTailList(
  [in, out] ListHead: PListEntry;
  [in, out] ListToAppend: PListEntry
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

procedure InitializeListHead;
begin
  ListHead.Flink := ListHead;
  ListHead.Blink := ListHead;
end;

function IsListEmpty;
begin
  Result := ListHead.Flink = ListHead;
end;

function RemoveEntryList;
var
  Blink, Flink: PListEntry;
begin
  Flink := Entry.Flink;
  Blink := Entry.Blink;
  Blink.Flink := Flink;
  Flink.Blink := Blink;
  Result := Flink = Blink;
end;

function RemoveHeadList;
var
  Flink: PListEntry;
begin
  Result := ListHead.Flink;
  Flink := Result.Flink;
  ListHead.Flink := Flink;
  Flink.Blink := ListHead;
end;

function RemoveTailList;
var
  Blink: PListEntry;
begin
  Result := ListHead.Blink;
  Blink := Result.Blink;
  ListHead.Blink := Blink;
  Blink.Flink := ListHead;
end;

procedure InsertTailList;
var
  Blink: PListEntry;
begin
  Blink := ListHead.Blink;
  Entry.Flink := ListHead;
  Entry.Blink := Blink;
  Blink.Flink := Entry;
  ListHead.Blink := Entry;
end;

procedure InsertHeadList;
var
  Flink: PListEntry;
begin
  Flink := ListHead.Flink;
  Entry.Flink := Flink;
  Entry.Blink := ListHead;
  Flink.Blink := Entry;
  ListHead.Flink := Entry;
end;

procedure AppendTailList;
var
  ListEnd: PListEntry;
begin
  ListEnd := ListHead.Blink;
  ListHead.Blink.Flink := ListToAppend;
  ListHead.Blink := ListToAppend.Blink;
  ListToAppend.Blink.Flink := ListHead;
  ListToAppend.Blink := ListEnd;
end;

end.
