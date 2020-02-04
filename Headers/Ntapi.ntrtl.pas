unit Ntapi.ntrtl;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntmmapi, DelphiApi.Reflection;

const
  RTL_MAX_DRIVE_LETTERS = 32;

  RTL_CLONE_PROCESS_FLAGS_CREATE_SUSPENDED = $00000001;
  RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES = $00000002;
  RTL_CLONE_PROCESS_FLAGS_NO_SYNCHRONIZE = $00000004;

  RTL_IMAGE_NT_HEADER_EX_FLAG_NO_RANGE_CHECK = $00000001;

type
  // Processes

  TCurDir = record
    DosPath: UNICODE_STRING;
    Handle: THandle;
  end;
  PCurDir = ^TCurDir;

  TRtlDriveLetterCurDir = record
    [Hex] Flags: Word;
    [Bytes] Length: Word;
    TimeStamp: Cardinal;
    DosPath: ANSI_STRING;
  end;
  PRtlDriveLetterCurDir = ^TRtlDriveLetterCurDir;

  TRtlUserProcessParameters = record
    [Bytes] MaximumLength: Cardinal;
    [Bytes] Length: Cardinal;

    [Hex] Flags: Cardinal;
    [Hex] DebugFlags: Cardinal;

    ConsoleHandle: THandle;
    [Hex] ConsoleFlags: Cardinal;
    StandardInput: THandle;
    StandardOutput: THandle;
    StandardError: THandle;

    CurrentDirectory: TCurDir;
    DllPath: UNICODE_STRING;
    ImagePathName: UNICODE_STRING;
    CommandLine: UNICODE_STRING;
    Environment: Pointer;

    StartingX: Cardinal;
    StartingY: Cardinal;
    CountX: Cardinal;
    CountY: Cardinal;
    CountCharsX: Cardinal;
    CountCharsY: Cardinal;
    FillAttribute: Cardinal;

    WindowFlags: Cardinal;
    ShowWindowFlags: Cardinal;
    WindowTitle: UNICODE_STRING;
    DesktopInfo: UNICODE_STRING;
    ShellInfo: UNICODE_STRING;
    RuntimeData: UNICODE_STRING;
    CurrentDirectories: array [0..RTL_MAX_DRIVE_LETTERS - 1] of
      TRtlDriveLetterCurDir;

    [Bytes] EnvironmentSize: NativeUInt;
    EnvironmentVersion: NativeUInt;
    PackageDependencyData: Pointer;
    ProcessGroupId: Cardinal;
    LoaderThreads: Cardinal;

    RedirectionDllName: UNICODE_STRING;
    HeapPartitionName: UNICODE_STRING;
    DefaultThreadpoolCpuSetMasks: NativeUInt;
    DefaultThreadpoolCpuSetMaskCount: Cardinal;
  end;
  PRtlUserProcessParameters = ^TRtlUserProcessParameters;

  TRtlUserProcessInformation = record
    [Bytes] Length: Cardinal;
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

  // Threads

  TUserThreadStartRoutine = function (ThreadParameter: Pointer): NTSTATUS;
    stdcall;

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

procedure RtlFreeUnicodeString(var UnicodeString: UNICODE_STRING); stdcall;
  external ntdll;

function RtlCompareUnicodeString(const String1: UNICODE_STRING;
  const String2: UNICODE_STRING; CaseInSensitive: Boolean): Integer; stdcall;
  external ntdll;

function RtlAppendUnicodeStringToString(var Destination: UNICODE_STRING;
  const Source: UNICODE_STRING): NTSTATUS; stdcall; external ntdll;

function RtlAppendUnicodeToString(var Destination: UNICODE_STRING;
  Source: PWideChar): NTSTATUS; stdcall; external ntdll;

function RtlUpcaseUnicodeString(var DestinationString: UNICODE_STRING;
  const SourceString: UNICODE_STRING; AllocateDestinationString: Boolean):
  NTSTATUS; stdcall; external ntdll;

function RtlDowncaseUnicodeString(var DestinationString: UNICODE_STRING;
  const SourceString: UNICODE_STRING; AllocateDestinationString: Boolean):
  NTSTATUS; stdcall; external ntdll;

// Processes

function RtlCreateProcessParametersEx(
  out pProcessParameters: PRtlUserProcessParameters;
  const ImagePathName: UNICODE_STRING; DllPath: PUNICODE_STRING;
  CurrentDirectory: PUNICODE_STRING; CommandLine: PUNICODE_STRING;
  Environment: Pointer; WindowTitle: PUNICODE_STRING;
  DesktopInfo: PUNICODE_STRING; ShellInfo: PUNICODE_STRING;
  RuntimeData: PUNICODE_STRING; Flags: Cardinal): NTSTATUS; stdcall;
  external ntdll;

function RtlDestroyProcessParameters(
  ProcessParameters: PRtlUserProcessParameters): NTSTATUS; stdcall;
  external ntdll;

function RtlCreateUserProcess(const NtImagePathName: UNICODE_STRING;
  AttributesDeprecated: Cardinal; ProcessParameters: PRtlUserProcessParameters;
  ProcessSecurityDescriptor: PSecurityDescriptor;
  ThreadSecurityDescriptor: PSecurityDescriptor;
  ParentProcess: THandle; InheritHandles: Boolean; DebugPort:
  THandle; TokenHandle: THandle;
  out ProcessInformation: TRtlUserProcessInformation): NTSTATUS; stdcall;
  external ntdll;

function RtlCloneUserProcess(ProcessFlags: Cardinal;
  ProcessSecurityDescriptor: PSecurityDescriptor;
  ThreadSecurityDescriptor: PSecurityDescriptor; DebugPort: THandle;
  out ProcessInformation: TRtlUserProcessInformation): NTSTATUS; stdcall;
  external ntdll;

function RtlCreateProcessReflection(ProcessHandle: THandle; Flags: Cardinal;
  StartRoutine: Pointer; StartContext: Pointer; EventHandle: THandle;
  out ReflectionInformation: TRtlpProcessReflectionInformation): NTSTATUS;
  stdcall; external ntdll;

// Threads

function RtlCreateUserThread(Process: THandle; ThreadSecurityDescriptor:
  PSecurityDescriptor; CreateSuspended: Boolean; ZeroBits: Cardinal;
  MaximumStackSize: NativeUInt; CommittedStackSize: NativeUInt;
  StartAddress: TUserThreadStartRoutine; Parameter: Pointer; out Thread:
  THandle; ClientId: PClientId): NTSTATUS; stdcall; external ntdll;

// Extended thread context

{$IFDEF WIN64}
function RtlWow64GetThreadContext(ThreadHandle: THandle;
  var ThreadContext: TContext32): NTSTATUS; stdcall; external ntdll;
{$ENDIF}

{$IFDEF WIN64}
function RtlWow64SetThreadContext(ThreadHandle: THandle;
  var ThreadContext: TContext32): NTSTATUS; stdcall; external ntdll;
{$ENDIF}

function RtlRemoteCall(Process: THandle; Thread: THandle; CallSite: Pointer;
  ArgumentCount: Cardinal; Arguments: TArray<NativeUInt>; PassContext: Boolean;
  AlreadySuspended: Boolean): NTSTATUS; stdcall; external ntdll;

// Images

function RtlImageNtHeaderEx(Flags: Cardinal; BaseOfImage: Pointer; Size: UInt64;
  out OutHeaders: PImageNtHeaders): NTSTATUS; stdcall;
  external ntdll;

function RtlAddressInSectionTable(NtHeaders: PImageNtHeaders;
  BaseOfImage: Pointer; VirtualAddress: Cardinal): Pointer; stdcall;
  external ntdll;

function RtlSectionTableFromVirtualAddress(NtHeaders: PImageNtHeaders;
  BaseOfImage: Pointer; VirtualAddress: Cardinal): PImageSectionHeader;
  stdcall; external ntdll;

function RtlImageDirectoryEntryToData(BaseOfImage: Pointer; MappedAsImage:
  Boolean; DirectoryEntry: TImageDirectoryEntry; out Size: Cardinal): Pointer;
  stdcall; external ntdll;

function RtlImageRvaToSection(NtHeaders: PImageNtHeaders;
  BaseOfImage: Pointer; Rva: Cardinal): PImageSectionHeader; stdcall;
  external ntdll;

function RtlImageRvaToVa(NtHeaders: PImageNtHeaders; BaseOfImage: Pointer;
  Rva: Cardinal; LastRvaSection: PPImageSectionHeader): Pointer; stdcall;
  external ntdll;

// Memory

function RtlCompareMemory(Source1, Source2: Pointer; Length: NativeUInt):
  NativeUInt; stdcall; external ntdll;

function RtlCompareMemoryUlong(Source: Pointer; Length: NativeUInt;
  Pattern: Cardinal): NativeUInt; stdcall; external ntdll;

procedure RtlFillMemoryUlong(Destination: Pointer; Length: NativeUInt;
  Pattern: Cardinal); stdcall; external ntdll;

procedure RtlFillMemoryUlonglong(Destination: Pointer; Length: NativeUInt;
  Pattern: UInt64); stdcall; external ntdll;

// Environment

function RtlCreateEnvironment(CloneCurrentEnvironment: Boolean;
  out Environment: Pointer): NTSTATUS; stdcall; external ntdll;

function RtlDestroyEnvironment(Environment: Pointer): NTSTATUS; stdcall;
  external ntdll;

function RtlSetCurrentEnvironment(Environment: Pointer;
  PreviousEnvironment: PPointer): NTSTATUS; stdcall; external ntdll;

function RtlSetEnvironmentVariable(var Environment: Pointer;
  const Name: UNICODE_STRING; Value: PUNICODE_STRING): NTSTATUS; stdcall;
  external ntdll;

function RtlQueryEnvironmentVariable_U(Environment: Pointer;
  const Name: UNICODE_STRING; var Value: UNICODE_STRING): NTSTATUS; stdcall;
  external ntdll;

function RtlExpandEnvironmentStrings_U(Environment: Pointer;
  const Source: UNICODE_STRING; var Destination: UNICODE_STRING;
  ReturnedLength: PCardinal): NTSTATUS; stdcall; external ntdll;

// Paths

function RtlDetermineDosPathNameType_U(DosFileName: PWideChar): TRtlPathType;
  stdcall; external ntdll;

function RtlGetCurrentDirectory_U(BufferLength: Cardinal;
  Buffer: PWideChar): Cardinal; stdcall; external ntdll;

function RtlSetCurrentDirectory_U(const PathName: UNICODE_STRING): NTSTATUS;
  stdcall; external ntdll;

function RtlGetLongestNtPathLength: Cardinal; stdcall; external ntdll;

function RtlDosPathNameToNtPathName_U_WithStatus(DosFileName: PWideChar;
  out NtFileName: UNICODE_STRING; FilePart: PPWideChar;
  RelativeName: Pointer): NTSTATUS; stdcall; external ntdll;

function RtlIsThreadWithinLoaderCallout: Boolean; stdcall; external ntdll;

function RtlDllShutdownInProgress: Boolean; stdcall; external ntdll;

// Heaps

function RtlSizeHeap(HeapHandle: Pointer; Flags: Cardinal; BaseAddress: Pointer)
  : NativeUInt; stdcall; external ntdll;

// Transactions

function RtlGetCurrentTransaction: THandle; stdcall; external ntdll;

function RtlSetCurrentTransaction(TransactionHandle: THandle): LongBool;
  stdcall; external ntdll;

// Errors

function RtlNtStatusToDosError(Status: NTSTATUS): Cardinal; stdcall;
  external ntdll;

function RtlNtStatusToDosErrorNoTeb(Status: NTSTATUS): Cardinal; stdcall;
  external ntdll;

function RtlGetLastNtStatus: NTSTATUS; stdcall; external ntdll;

function RtlGetLastWin32Error: Cardinal; stdcall; external ntdll;

procedure RtlSetLastWin32ErrorAndNtStatusFromNtStatus(Status: NTSTATUS);
   stdcall; external ntdll;

procedure RtlSetLastWin32Error(Win32Error: Cardinal); stdcall; external ntdll;

// Random

function RtlUniform(var Seed: Cardinal): Cardinal; stdcall; external ntdll;

// Integers

function RtlIntegerToUnicodeString(Value: Cardinal; Base: Cardinal;
  var Str: UNICODE_STRING): NTSTATUS; stdcall; external ntdll;

function RtlInt64ToUnicodeString(Value: UInt64; Base: Cardinal;
  var Str: UNICODE_STRING): NTSTATUS; stdcall; external ntdll;

function RtlUnicodeStringToInteger(const Str: UNICODE_STRING; Base: Cardinal;
  out Value: Cardinal): NTSTATUS; stdcall; external ntdll;

// SIDs

function RtlValidSid(Sid: PSid): Boolean; stdcall; external ntdll;

function RtlEqualSid(Sid1: PSid; Sid2: PSid): Boolean; stdcall; external ntdll;

function RtlEqualPrefixSid(Sid1: PSid; Sid2: PSid): Boolean; stdcall;
  external ntdll;

function RtlLengthRequiredSid(SubAuthorityCount: Cardinal): Cardinal;
  stdcall; external ntdll;

procedure RtlFreeSid(Sid: PSid); stdcall; external ntdll;

function RtlAllocateAndInitializeSid(const IdentifierAuthority:
  TSidIdentifierAuthority; SubAuthorityCount: Cardinal; SubAuthority0: Cardinal;
  SubAuthority1: Cardinal; SubAuthority2: Cardinal; SubAuthority3: Cardinal;
  SubAuthority4: Cardinal; SubAuthority5: Cardinal; SubAuthority6: Cardinal;
  SubAuthority7: Cardinal; out Sid: PSid): NTSTATUS; stdcall;
  external ntdll;

function RtlInitializeSid(Sid: PSid; IdentifierAuthority:
  PSidIdentifierAuthority; SubAuthorityCount: Byte): NTSTATUS; stdcall;
  external ntdll;

function RtlIdentifierAuthoritySid(Sid: PSid): PSidIdentifierAuthority; stdcall;
  external ntdll;

function RtlSubAuthoritySid(Sid: PSid; SubAuthority: Integer): PCardinal;
  stdcall; external ntdll;

function RtlSubAuthorityCountSid(Sid: PSid): PByte; stdcall; external ntdll;

function RtlLengthSid(Sid: PSid): Cardinal; stdcall; external ntdll;

function RtlCopySid(DestinationSidLength: Cardinal; DestinationSid: PSid;
  SourceSid: PSid): NTSTATUS; stdcall; external ntdll;

function RtlCreateServiceSid(const ServiceName: UNICODE_STRING;
  ServiceSid: PSid; var ServiceSidLength: Cardinal): NTSTATUS; stdcall;
  external ntdll;

function RtlLengthSidAsUnicodeString(Sid: PSid; out StringLength: Integer):
  NTSTATUS; stdcall; external ntdll;

function RtlConvertSidToUnicodeString(var UnicodeString: UNICODE_STRING;
  Sid: PSid; AllocateDestinationString: Boolean): NTSTATUS; stdcall;
  external ntdll;

function RtlSidDominates(Sid1: PSid; Sid2: PSid; out Dominates: Boolean):
  NTSTATUS; stdcall; external ntdll;

function RtlSidEqualLevel(Sid1: PSid; Sid2: PSid; out EqualLevel: Boolean):
  NTSTATUS; stdcall; external ntdll;

function RtlSidIsHigherLevel(Sid1: PSid; Sid2: PSid; out HigherLevel: Boolean):
  NTSTATUS; stdcall; external ntdll;

// Win 10 RS2+
function RtlDeriveCapabilitySidsFromName(const CapabilityName: UNICODE_STRING;
  CapabilityGroupSid: PSid; CapabilitySid: PSid): NTSTATUS; stdcall;
  external ntdll delayed;

// Security Descriptors

function RtlCreateSecurityDescriptor(var SecurityDescriptor:
  TSecurityDescriptor; Revision: Cardinal): NTSTATUS; stdcall; external ntdll;

function RtlValidSecurityDescriptor(SecurityDescriptor: PSecurityDescriptor):
  Boolean; stdcall; external ntdll;

function RtlLengthSecurityDescriptor(SecurityDescriptor: PSecurityDescriptor):
  NTSTATUS; stdcall; external ntdll;

function RtlGetControlSecurityDescriptor(SecurityDescriptor:
  PSecurityDescriptor; out Control: TSecurityDescriptorControl;
  out Revision: Cardinal): NTSTATUS; stdcall; external ntdll;

function RtlSetControlSecurityDescriptor(SecurityDescriptor:
  PSecurityDescriptor; ControlBitsOfInterest: TSecurityDescriptorControl;
  ControlBitsToSet: TSecurityDescriptorControl): NTSTATUS; stdcall;
  external ntdll;

function RtlSetAttributesSecurityDescriptor(SecurityDescriptor:
  PSecurityDescriptor; Control: TSecurityDescriptorControl;
  out Revision: Cardinal): NTSTATUS; stdcall; external ntdll;

function RtlSetDaclSecurityDescriptor(const SecurityDescriptor:
  TSecurityDescriptor; DaclPresent: Boolean; Dacl: PAcl; DaclDefaulted: Boolean)
  : NTSTATUS; stdcall; external ntdll;

function RtlGetDaclSecurityDescriptor(SecurityDescriptor:
  PSecurityDescriptor; out DaclPresent: Boolean; out Dacl: PAcl;
  out DaclDefaulted: Boolean): NTSTATUS; stdcall; external ntdll;

function RtlSetSaclSecurityDescriptor(const SecurityDescriptor:
  TSecurityDescriptor; SaclPresent: Boolean; Sacl: PAcl; SaclDefaulted: Boolean)
  : NTSTATUS; stdcall; external ntdll;

function RtlGetSaclSecurityDescriptor(SecurityDescriptor:
  PSecurityDescriptor; out SaclPresent: Boolean; out Sacl: PAcl;
  out SaclDefaulted: Boolean): NTSTATUS; stdcall; external ntdll;

function RtlSetOwnerSecurityDescriptor(const SecurityDescriptor:
  TSecurityDescriptor; Owner: PSid; OwnerDefaulted: Boolean): NTSTATUS; stdcall;
  external ntdll;

function RtlGetOwnerSecurityDescriptor(SecurityDescriptor:
  PSecurityDescriptor; out Owner: PSid; out OwnerDefaulted: Boolean): NTSTATUS;
  stdcall; external ntdll;

function RtlSetGroupSecurityDescriptor(const SecurityDescriptor:
  TSecurityDescriptor; Group: PSid; GroupDefaulted: Boolean): NTSTATUS; stdcall;
  external ntdll;

function RtlGetGroupSecurityDescriptor(SecurityDescriptor:
  PSecurityDescriptor; out Group: PSid; out GroupDefaulted: Boolean): NTSTATUS;
  stdcall; external ntdll;

// Access masks

procedure RtlMapGenericMask(var AccessMask: TAccessMask; const GenericMapping:
  TGenericMapping); stdcall; external ntdll;

// ACLs

function RtlCreateAcl(Acl: PAcl; AclLength: Cardinal;
  AclRevision: Cardinal): NTSTATUS; stdcall; external ntdll;

function RtlValidAcl(Acl: PAcl): Boolean; stdcall; external ntdll;

function RtlQueryInformationAcl(Acl: PAcl;
  out AclInformation: TAclRevisionInformation;
  AclInformationLength: Cardinal = SizeOf(TAclRevisionInformation);
  AclInformationClass: TAclInformationClass = AclRevisionInformation):
  NTSTATUS; stdcall; external ntdll; overload;

function RtlQueryInformationAcl(Acl: PAcl;
  out AclInformation: TAclSizeInformation;
  AclInformationLength: Cardinal = SizeOf(TAclSizeInformation);
  AclInformationClass: TAclInformationClass = AclSizeInformation):
  NTSTATUS; stdcall; external ntdll; overload;

function RtlAddAce(Acl: PAcl; AceRevision: Cardinal;
  StartingAceIndex: Integer; AceList: Pointer; AceListLength: Cardinal):
  NTSTATUS; stdcall; external ntdll;

function RtlDeleteAce(Acl: Pacl; AceIndex: Cardinal): NTSTATUS; stdcall;
  external ntdll;

function RtlGetAce(Acl: PAcl; AceIndex: Integer; out Ace: PAce): NTSTATUS;
  stdcall; external ntdll;

function RtlAddAccessAllowedAceEx(Acl: PAcl; AceRevision: Cardinal;
  AceFlags: Cardinal; AccessMask: TAccessMask; Sid: PSid): NTSTATUS; stdcall;
  external ntdll;

function RtlAddAccessDeniedAceEx(Acl: PAcl; AceRevision: Cardinal;
  AceFlags: Cardinal; AccessMask: TAccessMask; Sid: PSid): NTSTATUS; stdcall;
  external ntdll;

function RtlAddAuditAccessAceEx(Acl: PAcl; AceRevision: Cardinal;
  AceFlags: Cardinal; AccessMask: TAccessMask; Sid: PSid;
  AuditSuccess: Boolean; AuditFailure: Boolean): NTSTATUS; stdcall;
  external ntdll;

function RtlAddMandatoryAce(Acl: PAcl; AceRevision: Cardinal;
  AceFlags: Cardinal; Sid: PSid; AceType: Byte; AccessMask: TAccessMask):
  NTSTATUS; stdcall; external ntdll;

// System information

function RtlGetNtGlobalFlags: Cardinal; stdcall; external ntdll;

// Stack support

function RtlCaptureStackBackTrace(FramesToSkip: Cardinal; FramesToCapture:
  Cardinal; BackTrace: Pointer; BackTraceHash: PCardinal): Word; stdcall;
  external ntdll;

procedure RtlGetCallersAddress(out CallersAddress: Pointer;
  out CallersCaller: Pointer); stdcall; external ntdll;

// Appcontainer

// Win 8+, free with RtlFreeUnicodeString
function RtlGetTokenNamedObjectPath(Token: THandle; Sid: PSid;
  var ObjectPath: UNICODE_STRING): NTSTATUS; stdcall; external ntdll delayed;

// Win 8+, free with RtlFreeSid
function RtlGetAppContainerParent(AppContainerSid: PSid;
  out AppContainerSidParent: PSid): NTSTATUS; stdcall; external ntdll delayed;

// Win 8+
function RtlGetAppContainerSidType(AppContainerSid: PSid;
  out AppContainerSidType: TAppContainerSidType): NTSTATUS; stdcall;
  external ntdll delayed;


implementation

end.
