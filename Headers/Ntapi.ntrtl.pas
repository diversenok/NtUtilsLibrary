unit Ntapi.ntrtl;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntmmapi, Ntapi.ntseapi, NtUtils.Version,
  DelphiApi.Reflection;

const
  // Processes

  RTL_MAX_DRIVE_LETTERS = 32;

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

  RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED = $00000001;
  RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES = $00000002;
  RTL_CLONE_PROCESS_FLAGS_NO_SYNCHRONIZE = $00000004;

  RTL_IMAGE_NT_HEADER_EX_FLAG_NO_RANGE_CHECK = $00000001;

  // Heaps

  // WinNt.19920
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

  // WinUser.258, table id for RtlFindMessage
  RT_MESSAGETABLE = 11;

  MESSAGE_RESOURCE_UNICODE = $0001;
  MESSAGE_RESOURCE_UTF8 = $0002;

type
  PPEnvironment = ^PEnvironment;

  // Processes

  TCurDir = record
    DosPath: TNtUnicodeString;
    Handle: THandle;
  end;
  PCurDir = ^TCurDir;

  TRtlDriveLetterCurDir = record
    [Hex] Flags: Word;
    [Bytes] Length: Word;
    TimeStamp: TUnixTime;
    DosPath: TNtAnsiString;
  end;
  PRtlDriveLetterCurDir = ^TRtlDriveLetterCurDir;

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
    FillAttribute: Cardinal; // Winapi.ConsoleApi.TConsoleFill

    WindowFlags: Cardinal; // Winapi.ProcessThreadsApi.TStarupFlags
    ShowWindowFlags: Cardinal; // Winapi.WinUser.TShowMode
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

  TRtlUserProcessInformation = record
    [Bytes, Unlisted] Length: Cardinal;
    Process: THandle;
    Thread: THandle;
    ClientId: TClientId;
    ImageInformation: TSectionImageInformation;
  end;
  PRtlUserProcessInformation = ^TRtlUserProcessInformation;

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

  // Threads

  TUserThreadStartRoutine = function (ThreadParameter: Pointer): NTSTATUS;
    stdcall;

  // Modules

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

  // system info class 11
  TRtlProcessModules = record
    NumberOfModules: Cardinal;
    Modules: TAnysizeArray<TRtlProcessModuleInformation>;
  end;
  PRtlProcessModules = ^TRtlProcessModules;

  // system info class 77
  TRtlProcessModuleInformationEx = record
    [Unlisted] NextOffset: Word;
    [Aggregate] BaseInfo: TRtlProcessModuleInformation;
    ImageChecksum: Cardinal;
    TimeDateStamp: TUnixTime;
    DefaultBase: Pointer;
  end;
  PRtlProcessModuleInformationEx = ^TRtlProcessModuleInformationEx;

  // Paths

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

  TMessageResourceEntry = record
    Length: Word;
    Flags: Word; // MESSAGE_RESOURCE_*
    Text: TAnysizeArray<Byte>;
  end;
  PMessageResourceEntry = ^TMessageResourceEntry;

  // Time

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

  [NamingStyle(nsCamelCase, '', 'SidType')]
  TAppContainerSidType = (
    NotAppContainerSidType = 0,
    ChildAppContainerSidType = 1,
    ParentAppContainerSidType = 2,
    InvalidAppContainerSidType = 3
  );

// Strings

procedure RtlFreeUnicodeString(
  var UnicodeString: TNtUnicodeString
); stdcall; external ntdll;

function RtlCompareUnicodeString(
  const String1: TNtUnicodeString;
  const String2: TNtUnicodeString;
  CaseInSensitive: Boolean
): Integer; stdcall; external ntdll;

function RtlPrefixUnicodeString(
  const String1: TNtUnicodeString;
  const String2: TNtUnicodeString;
  CaseInSensitive: Boolean
): Boolean; stdcall; external ntdll;

function RtlAppendUnicodeStringToString(
  var Destination: TNtUnicodeString;
  const Source: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function RtlAppendUnicodeToString(
  var Destination: TNtUnicodeString;
  [in] Source: PWideChar
): NTSTATUS; stdcall; external ntdll;

function RtlUpcaseUnicodeString(
  var DestinationString: TNtUnicodeString;
  const SourceString: TNtUnicodeString;
  AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlDowncaseUnicodeString(
  var DestinationString: TNtUnicodeString;
  const SourceString: TNtUnicodeString;
  AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlStringFromGUID(
  const Guid: TGuid;
  out GuidString: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function RtlGUIDFromString(
  const GuidString: TNtUnicodeString;
  out Guid: TGuid
): NTSTATUS; stdcall; external ntdll;

// Processes

function RtlCreateProcessParametersEx(
  out pProcessParameters: PRtlUserProcessParameters;
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

function RtlDestroyProcessParameters(
  [in] ProcessParameters: PRtlUserProcessParameters
): NTSTATUS; stdcall; external ntdll;

function RtlCreateUserProcess(
  const NtImagePathName: TNtUnicodeString;
  AttributesDeprecated: Cardinal;
  [in] ProcessParameters: PRtlUserProcessParameters;
  [in, opt] ProcessSecurityDescriptor: PSecurityDescriptor;
  [in, opt] ThreadSecurityDescriptor: PSecurityDescriptor;
  [opt] ParentProcess: THandle;
  InheritHandles: Boolean;
  [opt] DebugPort: THandle;
  [opt] TokenHandle: THandle;
  out ProcessInformation: TRtlUserProcessInformation
): NTSTATUS; stdcall; external ntdll;

procedure RtlExitUserProcess(
  ExitStatus: NTSTATUS
); stdcall external ntdll;

function RtlCloneUserProcess(
  ProcessFlags: TRtlProcessCloneFlags;
  [in, opt] ProcessSecurityDescriptor: PSecurityDescriptor;
  [in, opt] ThreadSecurityDescriptor: PSecurityDescriptor;
  [opt] DebugPort: THandle;
  out ProcessInformation: TRtlUserProcessInformation
): NTSTATUS; stdcall; external ntdll;

function RtlCreateProcessReflection(
  ProcessHandle: THandle;
  Flags: Cardinal;
  [in, opt] StartRoutine: Pointer;
  [in, opt] StartContext: Pointer;
  [opt] EventHandle: THandle;
  out ReflectionInformation: TRtlpProcessReflectionInformation
): NTSTATUS; stdcall; external ntdll;

// Threads

function RtlCreateUserThread(
  Process: THandle;
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
function RtlWow64GetThreadContext(
  ThreadHandle: THandle;
  var ThreadContext: TContext32
): NTSTATUS; stdcall; external ntdll;

function RtlWow64SetThreadContext(
  ThreadHandle: THandle;
  var ThreadContext: TContext32
): NTSTATUS; stdcall; external ntdll;
{$ENDIF}

function RtlRemoteCall(
  Process: THandle;
  Thread: THandle;
  [in] CallSite: Pointer;
  ArgumentCount: Cardinal;
  Arguments: TArray<NativeUInt>;
  PassContext: Boolean;
  AlreadySuspended: Boolean
): NTSTATUS; stdcall; external ntdll;

// Images

function RtlImageNtHeaderEx(
  Flags: Cardinal;
  [in] BaseOfImage: Pointer;
  Size: UInt64;
  out OutHeaders: PImageNtHeaders
): NTSTATUS; stdcall; external ntdll;

function RtlAddressInSectionTable(
  [in] NtHeaders: PImageNtHeaders;
  [in] BaseOfImage: Pointer;
  VirtualAddress: Cardinal
): Pointer; stdcall; external ntdll;

function RtlSectionTableFromVirtualAddress(
  [in] NtHeaders: PImageNtHeaders;
  [in] BaseOfImage: Pointer;
  VirtualAddress: Cardinal
): PImageSectionHeader; stdcall; external ntdll;

function RtlImageDirectoryEntryToData(
  [in] BaseOfImage: Pointer;
  MappedAsImage: Boolean;
  DirectoryEntry: TImageDirectoryEntry;
  out Size: Cardinal
): Pointer; stdcall; external ntdll;

function RtlImageRvaToSection(
  [in] NtHeaders: PImageNtHeaders;
  [in] BaseOfImage: Pointer;
  Rva: Cardinal
): PImageSectionHeader; stdcall; external ntdll;

function RtlImageRvaToVa(
  [in] NtHeaders: PImageNtHeaders;
  [in] BaseOfImage: Pointer;
  Rva: Cardinal;
  [in, out, opt] LastRvaSection: PPImageSectionHeader
): Pointer; stdcall; external ntdll;

// Memory

function RtlCompareMemory(
  [in] Source1: Pointer;
  [in] Source2: Pointer;
  Length: NativeUInt
): NativeUInt; stdcall; external ntdll;

function RtlCompareMemoryUlong(
  [in] Source: Pointer;
  Length: NativeUInt;
  Pattern: Cardinal
): NativeUInt; stdcall; external ntdll;

procedure RtlFillMemoryUlong(
  [in] Destination: Pointer;
  Length: NativeUInt;
  Pattern: Cardinal
); stdcall; external ntdll;

procedure RtlFillMemoryUlonglong(
  [in] Destination: Pointer;
  Length: NativeUInt;
  Pattern: UInt64
); stdcall; external ntdll;

// Environment

function RtlCreateEnvironment(
  CloneCurrentEnvironment: Boolean;
  out Environment: PEnvironment
): NTSTATUS; stdcall; external ntdll;

function RtlDestroyEnvironment(
  [in] Environment: PEnvironment
): NTSTATUS; stdcall; external ntdll;

function RtlSetCurrentEnvironment(
  [in] Environment: PEnvironment;
  [out, opt] PreviousEnvironment: PPEnvironment
): NTSTATUS; stdcall; external ntdll;

function RtlSetEnvironmentVariable(
  [in, out, opt] var Environment: PEnvironment;
  const Name: TNtUnicodeString;
  [in, opt] Value: PNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function RtlQueryEnvironmentVariable_U(
  [in, opt] Environment: PEnvironment;
  const Name: TNtUnicodeString;
  var Value: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function RtlExpandEnvironmentStrings_U(
  [in, opt] Environment: PEnvironment;
  const Source: TNtUnicodeString;
  var Destination: TNtUnicodeString;
  [out, opt] ReturnedLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Paths

function RtlDetermineDosPathNameType_U(
  [in] DosFileName: PWideChar
): TRtlPathType; stdcall; external ntdll;

function RtlGetCurrentDirectory_U(
  BufferLength: Cardinal;
  [out] Buffer: PWideChar
): Cardinal; stdcall; external ntdll;

function RtlSetCurrentDirectory_U(
  const PathName: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function RtlGetLongestNtPathLength: Cardinal; stdcall; external ntdll;

function RtlDosPathNameToNtPathName_U_WithStatus(
  [in] DosFileName: PWideChar;
  out NtFileName: TNtUnicodeString;
  [out, opt] FilePart: PPWideChar;
  [out, opt] RelativeName: Pointer
): NTSTATUS; stdcall; external ntdll;

function RtlIsThreadWithinLoaderCallout: Boolean; stdcall; external ntdll;

function RtlDllShutdownInProgress: Boolean; stdcall; external ntdll;

// Heaps

function RtlAllocateHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  Size: NativeUInt
): Pointer; stdcall; external ntdll;

function RtlFreeHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer
): Boolean; stdcall; external ntdll;

function RtlSizeHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  [in] BaseAddress: Pointer
): NativeUInt; stdcall; external ntdll;

function RtlZeroHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags
): NTSTATUS; stdcall; external ntdll;

function RtlLockHeap(
  [in] HeapHandle: Pointer
): Boolean; stdcall; external ntdll;

function RtlUnlockHeap(
  [in] HeapHandle: Pointer
): Boolean; stdcall; external ntdll;

function RtlReAllocateHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer;
  Size: NativeUInt
): Pointer; stdcall; external ntdll;

function RtlCompactHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags
): NativeUInt; stdcall; external ntdll;

function RtlValidateHeap(
  [in] HeapHandle: Pointer;
  Flags: THeapFlags;
  [in, opt] BaseAddress: Pointer
): Boolean; stdcall; external ntdll;

// Transactions

function RtlGetCurrentTransaction: THandle; stdcall; external ntdll;

function RtlSetCurrentTransaction(
  TransactionHandle: THandle
): LongBool; stdcall; external ntdll;

// Messages

function RtlFindMessage(
  DllHandle: HMODULE;
  MessageTableId: Cardinal;
  MessageLanguageId: Cardinal;
  MessageId: Cardinal;
  out MessageEntry: PMessageResourceEntry
): NTSTATUS; stdcall; external ntdll;

// Errors

function RtlNtStatusToDosError(
  Status: NTSTATUS
): TWin32Error; stdcall; external ntdll;

function RtlNtStatusToDosErrorNoTeb(
  Status: NTSTATUS
): TWin32Error; stdcall; external ntdll;

function RtlGetLastNtStatus: NTSTATUS; stdcall; external ntdll;

function RtlGetLastWin32Error: TWin32Error; stdcall; external ntdll;

procedure RtlSetLastWin32ErrorAndNtStatusFromNtStatus(
  Status: NTSTATUS
); stdcall; external ntdll;

procedure RtlSetLastWin32Error(
  Win32Error: TWin32Error
); stdcall; external ntdll;

// Random

function RtlUniform(
  var Seed: Cardinal
): Cardinal; stdcall; external ntdll;

// Integers

function RtlIntegerToUnicodeString(
  Value: Cardinal;
  Base: Cardinal;
  var Str: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function RtlInt64ToUnicodeString(
  Value: UInt64;
  Base: Cardinal;
  var Str: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function RtlUnicodeStringToInteger(
  const Str: TNtUnicodeString;
  Base: Cardinal;
  out Value: Cardinal
): NTSTATUS; stdcall; external ntdll;

// SIDs

function RtlValidSid(
  [in] Sid: PSid
): Boolean; stdcall; external ntdll;

function RtlEqualSid(
  [in] Sid1: PSid;
  [in] Sid2: PSid
): Boolean; stdcall; external ntdll;

function RtlEqualPrefixSid(
  [in] Sid1: PSid;
  [in] Sid2: PSid
): Boolean; stdcall; external ntdll;

function RtlLengthRequiredSid(
  SubAuthorityCount: Cardinal
): Cardinal; stdcall; external ntdll;

procedure RtlFreeSid(
  [in] Sid: PSid
); stdcall; external ntdll;

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
  [allocates] out Sid: PSid
): NTSTATUS; stdcall; external ntdll;

function RtlInitializeSid(
  [out] Sid: PSid;
  [in] IdentifierAuthority: PSidIdentifierAuthority;
  SubAuthorityCount: Byte
): NTSTATUS; stdcall; external ntdll;

function RtlIdentifierAuthoritySid(
  [in] Sid: PSid
): PSidIdentifierAuthority; stdcall; external ntdll;

function RtlSubAuthoritySid(
  [in] Sid: PSid;
  SubAuthority: Integer
): PCardinal; stdcall; external ntdll;

function RtlSubAuthorityCountSid(
  [in] Sid: PSid
): PByte; stdcall; external ntdll;

function RtlLengthSid(
  [in] Sid: PSid
): Cardinal; stdcall; external ntdll;

function RtlCopySid(
  DestinationSidLength: Cardinal;
  [out] DestinationSid: PSid;
  [in] SourceSid: PSid
): NTSTATUS; stdcall; external ntdll;

function RtlCreateServiceSid(
  const ServiceName: TNtUnicodeString;
  [out] ServiceSid: PSid;
  var ServiceSidLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function RtlLengthSidAsUnicodeString(
  [in] Sid: PSid;
  out StringLength: Integer
): NTSTATUS; stdcall; external ntdll;

function RtlConvertSidToUnicodeString(
  var UnicodeString: TNtUnicodeString;
  [in] Sid: PSid;
  AllocateDestinationString: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlSidDominates(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  out Dominates: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlSidEqualLevel(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  out EqualLevel: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlSidIsHigherLevel(
  [in] Sid1: PSid;
  [in] Sid2: PSid;
  out HigherLevel: Boolean
): NTSTATUS; stdcall; external ntdll;

// Win 10 RS2+
function RtlDeriveCapabilitySidsFromName(
  const CapabilityName: TNtUnicodeString;
  [out] CapabilityGroupSid: PSid;
  [out] CapabilitySid: PSid
): NTSTATUS; stdcall; external ntdll delayed;

// Security Descriptors

function RtlCreateSecurityDescriptor(
  [out] SecurityDescriptor: PSecurityDescriptor;
  Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

function RtlValidSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor
): Boolean; stdcall; external ntdll;

function RtlLengthSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external ntdll;

function RtlGetControlSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out Control: TSecurityDescriptorControl;
  out Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

function RtlSetControlSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  ControlBitsOfInterest: TSecurityDescriptorControl;
  ControlBitsToSet: TSecurityDescriptorControl
): NTSTATUS; stdcall; external ntdll;

function RtlSetAttributesSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  Control: TSecurityDescriptorControl;
  out Revision: Cardinal
): NTSTATUS; stdcall; external ntdll;

function RtlSetDaclSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  DaclPresent: Boolean;
  [in, opt] Dacl: PAcl;
  DaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlGetDaclSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out DaclPresent: Boolean;
  out Dacl: PAcl;
  out DaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlSetSaclSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  SaclPresent: Boolean;
  [in, opt] Sacl: PAcl;
  SaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlGetSaclSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out SaclPresent: Boolean;
  out Sacl: PAcl;
  out SaclDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlSetOwnerSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  [in, opt] Owner: PSid;
  OwnerDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlGetOwnerSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out Owner: PSid;
  out OwnerDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlSetGroupSecurityDescriptor(
  [in, out] SecurityDescriptor: PSecurityDescriptor;
  [in, opt] Group: PSid;
  GroupDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlGetGroupSecurityDescriptor(
  [in] SecurityDescriptor: PSecurityDescriptor;
  out Group: PSid;
  out GroupDefaulted: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlMakeSelfRelativeSD(
  [in] AbsoluteSecurityDescriptor: PSecurityDescriptor;
  [out] SelfRelativeSecurityDescriptor: PSecurityDescriptor;
  var BufferLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// Access masks

procedure RtlMapGenericMask(
  var AccessMask: TAccessMask;
  const GenericMapping: TGenericMapping
); stdcall; external ntdll;

// ACLs

function RtlCreateAcl(
  [out] Acl: PAcl;
  AclLength: Cardinal;
  AclRevision: Cardinal
): NTSTATUS; stdcall; external ntdll;

function RtlValidAcl(
  [in] Acl: PAcl
): Boolean; stdcall; external ntdll;

function RtlQueryInformationAcl(
  [in] Acl: PAcl;
  out AclInformation: TAclRevisionInformation;
  AclInformationLength: Cardinal = SizeOf(TAclRevisionInformation);
  AclInformationClass: TAclInformationClass = AclRevisionInformation
): NTSTATUS; stdcall; external ntdll; overload;

function RtlQueryInformationAcl(
  [in] Acl: PAcl;
  out AclInformation: TAclSizeInformation;
  AclInformationLength: Cardinal = SizeOf(TAclSizeInformation);
  AclInformationClass: TAclInformationClass = AclSizeInformation
): NTSTATUS; stdcall; external ntdll; overload;

function RtlAddAce(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  StartingAceIndex: Integer;
  [in] AceList: Pointer;
  AceListLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function RtlDeleteAce(
  [in] Acl: Pacl;
  AceIndex: Cardinal
): NTSTATUS; stdcall; external ntdll;

function RtlGetAce(
  [in] Acl: PAcl;
  AceIndex: Integer;
  out Ace: PAce
): NTSTATUS; stdcall; external ntdll;

function RtlAddAccessAllowedAceEx(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  AceFlags: Cardinal;
  AccessMask: TAccessMask;
  [in] Sid: PSid
): NTSTATUS; stdcall; external ntdll;

function RtlAddAccessDeniedAceEx(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  AceFlags: Cardinal;
  AccessMask: TAccessMask;
  [in] Sid: PSid
): NTSTATUS; stdcall; external ntdll;

function RtlAddAuditAccessAceEx(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  AceFlags: Cardinal;
  AccessMask: TAccessMask;
  [in] Sid: PSid;
  AuditSuccess: Boolean;
  AuditFailure: Boolean
): NTSTATUS; stdcall; external ntdll;

function RtlAddMandatoryAce(
  [in] Acl: PAcl;
  AceRevision: Cardinal;
  AceFlags: Cardinal;
  [in] Sid: PSid;
  AceType: Byte;
  AccessMask: TAccessMask
): NTSTATUS; stdcall; external ntdll;

// Misc security

function RtlAdjustPrivilege(
  Privilege: TSeWellKnownPrivilege;
  Enable: Boolean;
  Client: Boolean;
  out WasEnabled: Boolean
): NTSTATUS; stdcall; external ntdll;

// System information

function RtlGetNtGlobalFlags: Cardinal; stdcall; external ntdll;

// Stack support

function RtlCaptureStackBackTrace(
  FramesToSkip: Cardinal;
  FramesToCapture: Cardinal;
  [out] BackTrace: Pointer;
  [out, opt] BackTraceHash: PCardinal
): Word; stdcall; external ntdll;

procedure RtlGetCallersAddress(
  out CallersAddress: Pointer;
  out CallersCaller: Pointer
); stdcall; external ntdll;

// Appcontainer

// Win 8+, free with RtlFreeUnicodeString
function RtlGetTokenNamedObjectPath(
  Token: THandle;
  [in, opt] Sid: PSid;
  [allocates] var ObjectPath: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll delayed;

// Win 8+, free with RtlFreeSid
function RtlGetAppContainerParent(
  [in] AppContainerSid: PSid;
  [allocates] out AppContainerSidParent: PSid
): NTSTATUS; stdcall; external ntdll delayed;

// Win 8+
function RtlGetAppContainerSidType(
  [in] AppContainerSid: PSid;
  [allocates] out AppContainerSidType: TAppContainerSidType
): NTSTATUS; stdcall; external ntdll delayed;

implementation

end.
