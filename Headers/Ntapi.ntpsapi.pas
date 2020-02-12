unit Ntapi.ntpsapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntrtl, DelphiApi.Reflection;

const
  // Processes

  PROCESS_TERMINATE = $0001;
  PROCESS_CREATE_THREAD = $0002;
  PROCESS_SET_SESSIONID = $0004;
  PROCESS_VM_OPERATION = $0008;
  PROCESS_VM_READ = $0010;
  PROCESS_VM_WRITE = $0020;
  PROCESS_DUP_HANDLE = $0040;
  PROCESS_CREATE_PROCESS = $0080;
  PROCESS_SET_QUOTA = $0100;
  PROCESS_SET_INFORMATION = $0200;
  PROCESS_QUERY_INFORMATION = $0400;
  PROCESS_SUSPEND_RESUME = $0800;
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
  PROCESS_SET_LIMITED_INFORMATION = $2000;

  PROCESS_ALL_ACCESS = STANDARD_RIGHTS_ALL or SPECIFIC_RIGHTS_ALL;

  ProcessAccessMapping: array [0..13] of TFlagName = (
    (Value: PROCESS_TERMINATE;                 Name: 'Terminate'),
    (Value: PROCESS_CREATE_THREAD;             Name: 'Create threads'),
    (Value: PROCESS_SET_SESSIONID;             Name: 'Set session ID'),
    (Value: PROCESS_VM_OPERATION;              Name: 'Modify memory'),
    (Value: PROCESS_VM_READ;                   Name: 'Read memory'),
    (Value: PROCESS_VM_WRITE;                  Name: 'Write memory'),
    (Value: PROCESS_DUP_HANDLE;                Name: 'Duplicate handles'),
    (Value: PROCESS_CREATE_PROCESS;            Name: 'Create process'),
    (Value: PROCESS_SET_QUOTA;                 Name: 'Set quota'),
    (Value: PROCESS_SET_INFORMATION;           Name: 'Set information'),
    (Value: PROCESS_QUERY_INFORMATION;         Name: 'Query information'),
    (Value: PROCESS_SUSPEND_RESUME;            Name: 'Suspend/resume'),
    (Value: PROCESS_QUERY_LIMITED_INFORMATION; Name: 'Query limited information'),
    (Value: PROCESS_SET_LIMITED_INFORMATION;   Name: 'Set limited information')
  );

  ProcessAccessType: TAccessMaskType = (
    TypeName: 'process';
    FullAccess: PROCESS_ALL_ACCESS;
    Count: Length(ProcessAccessMapping);
    Mapping: PFlagNameRefs(@ProcessAccessMapping);
  );

  // Flags for NtCreateProcessEx and NtCreateUserProcess
  PROCESS_CREATE_FLAGS_BREAKAWAY = $00000001;
  PROCESS_CREATE_FLAGS_NO_DEBUG_INHERIT = $00000002;
  PROCESS_CREATE_FLAGS_INHERIT_HANDLES = $00000004;
  PROCESS_CREATE_FLAGS_OVERRIDE_ADDRESS_SPACE = $00000008;
  PROCESS_CREATE_FLAGS_LARGE_PAGES = $00000010;

  // ProcessFlags for NtCreateUserProcess
  PROCESS_CREATE_FLAGS_LARGE_PAGE_SYSTEM_DLL = $00000020;
  PROCESS_CREATE_FLAGS_PROTECTED_PROCESS = $00000040;
  PROCESS_CREATE_FLAGS_CREATE_SESSION = $00000080;
  PROCESS_CREATE_FLAGS_INHERIT_FROM_PARENT = $00000100;
  PROCESS_CREATE_FLAGS_SUSPENDED = $00000200;

  // Threads

  THREAD_TERMINATE = $0001;
  THREAD_SUSPEND_RESUME = $0002;
  THREAD_ALERT = $0004;
  THREAD_GET_CONTEXT = $0008;
  THREAD_SET_CONTEXT = $0010;
  THREAD_SET_INFORMATION = $0020;
  THREAD_QUERY_INFORMATION = $0040;
  THREAD_SET_THREAD_TOKEN = $0080;
  THREAD_IMPERSONATE = $0100;
  THREAD_DIRECT_IMPERSONATION = $0200;
  THREAD_SET_LIMITED_INFORMATION = $0400;
  THREAD_QUERY_LIMITED_INFORMATION = $0800;
  THREAD_RESUME = $1000;

  THREAD_ALL_ACCESS = STANDARD_RIGHTS_ALL or SPECIFIC_RIGHTS_ALL;

  ThreadAccessMapping: array [0..12] of TFlagName = (
    (Value: THREAD_TERMINATE;                 Name: 'Terminate'),
    (Value: THREAD_SUSPEND_RESUME;            Name: 'Suspend/resume'),
    (Value: THREAD_ALERT;                     Name: 'Alert'),
    (Value: THREAD_GET_CONTEXT;               Name: 'Get context'),
    (Value: THREAD_SET_CONTEXT;               Name: 'Set context'),
    (Value: THREAD_SET_INFORMATION;           Name: 'Set information'),
    (Value: THREAD_QUERY_INFORMATION;         Name: 'Query information'),
    (Value: THREAD_SET_THREAD_TOKEN;          Name: 'Set token'),
    (Value: THREAD_IMPERSONATE;               Name: 'Impersonate'),
    (Value: THREAD_DIRECT_IMPERSONATION;      Name: 'Direct impersonation'),
    (Value: THREAD_SET_LIMITED_INFORMATION;   Name: 'Set limited information'),
    (Value: THREAD_QUERY_LIMITED_INFORMATION; Name: 'Query limited information'),
    (Value: THREAD_RESUME;                    Name: 'Resume')
  );

  ThreadAccessType: TAccessMaskType = (
    TypeName: 'thread';
    FullAccess: THREAD_ALL_ACCESS;
    Count: Length(ThreadAccessMapping);
    Mapping: PFlagNameRefs(@ThreadAccessMapping);
  );

  // User processes and threads

  // CreateFlags for NtCreateThreadEx
  THREAD_CREATE_FLAGS_CREATE_SUSPENDED = $00000001;
  THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH = $00000002;
  THREAD_CREATE_FLAGS_HIDE_FROM_DEBUGGER = $00000004;
  THREAD_CREATE_FLAGS_HAS_SECURITY_DESCRIPTOR = $00000010;
  THREAD_CREATE_FLAGS_ACCESS_CHECK_IN_TARGET = $00000020;
  THREAD_CREATE_FLAGS_INITIAL_THREAD = $00000080;

  // Jobs

  JOB_OBJECT_ASSIGN_PROCESS = $0001;
  JOB_OBJECT_SET_ATTRIBUTES = $0002;
  JOB_OBJECT_QUERY = $0004;
  JOB_OBJECT_TERMINATE = $0008;
  JOB_OBJECT_SET_SECURITY_ATTRIBUTES = $0010;
  JOB_OBJECT_IMPERSONATE = $0020;

  JOB_OBJECT_ALL_ACCESS = STANDARD_RIGHTS_ALL or $3F;

  JobAccessMapping: array [0..5] of TFlagName = (
    (Value: JOB_OBJECT_ASSIGN_PROCESS;          Name: 'Assign process'),
    (Value: JOB_OBJECT_SET_ATTRIBUTES;          Name: 'Set attributes'),
    (Value: JOB_OBJECT_QUERY;                   Name: 'Query'),
    (Value: JOB_OBJECT_TERMINATE;               Name: 'Terminate'),
    (Value: JOB_OBJECT_SET_SECURITY_ATTRIBUTES; Name: 'Set security attributes'),
    (Value: JOB_OBJECT_IMPERSONATE;             Name: 'Impersonate')
  );

  JobAccessType: TAccessMaskType = (
    TypeName: 'job object';
    FullAccess: JOB_OBJECT_ALL_ACCESS;
    Count: Length(JobAccessMapping);
    Mapping: PFlagNameRefs(@JobAccessMapping);
  );

  JOB_OBJECT_UILIMIT_HANDLES = $00000001;
  JOB_OBJECT_UILIMIT_READCLIPBOARD = $00000002;
  JOB_OBJECT_UILIMIT_WRITECLIPBOARD = $00000004;
  JOB_OBJECT_UILIMIT_SYSTEMPARAMETERS = $00000008;
  JOB_OBJECT_UILIMIT_DISPLAYSETTINGS = $00000010;
  JOB_OBJECT_UILIMIT_GLOBALATOMS = $00000020;
  JOB_OBJECT_UILIMIT_DESKTOP = $00000040;
  JOB_OBJECT_UILIMIT_EXITWINDOWS = $00000080;

  JOB_OBJECT_TERMINATE_AT_END_OF_JOB = 0;
  JOB_OBJECT_POST_AT_END_OF_JOB = 1;

  NtCurrentProcess: THandle = THandle(-1);
  NtCurrentThread: THandle = THandle(-2);

  // Not NT, but useful
  function NtCurrentProcessId: TProcessId;
  function NtCurrentThreadId: TThreadId;

type
  // Processes

  [NamingStyle(nsCamelCase, 'Process')]
  TProcessInfoClass = (
    ProcessBasicInformation = 0,       // q: TProcessBasinInformation
    ProcessQuotaLimits = 1,            // q, s: TQuotaLimits
    ProcessIoCounters = 2,             // q: TIoCounters
    ProcessVmCounters = 3,
    ProcessTimes = 4,
    ProcessBasePriority = 5,           // s: KPRIORITY
    ProcessRaisePriority = 6,
    ProcessDebugPort = 7,
    ProcessExceptionPort = 8,
    ProcessAccessToken = 9,            // s: TProcessAccessToken
    ProcessLdtInformation = 10,
    ProcessLdtSize = 11,
    ProcessDefaultHardErrorMode = 12,
    ProcessIoPortHandlers = 13,
    ProcessPooledUsageAndLimits = 14,
    ProcessWorkingSetWatch = 15,
    ProcessUserModeIOPL = 16,
    ProcessEnableAlignmentFaultFixup = 17,
    ProcessPriorityClass = 18,
    ProcessWx86Information = 19,
    ProcessHandleCount = 20,           // q: Cardinal
    ProcessAffinityMask = 21,
    ProcessPriorityBoost = 22,
    ProcessDeviceMap = 23,
    ProcessSessionInformation = 24,    // q: Cardinal
    ProcessForegroundInformation = 25,
    ProcessWow64Information = 26,      // q: PPeb32
    ProcessImageFileName = 27,         // q: UNICODE_STRING
    ProcessLUIDDeviceMapsEnabled = 28,
    ProcessBreakOnTermination = 29,
    ProcessDebugObjectHandle = 30,     // q: THandle
    ProcessDebugFlags = 31,            // q, s: TProcessDebugFlags
    ProcessHandleTracing = 32,
    ProcessIoPriority = 33,
    ProcessExecuteFlags = 34,
    ProcessResourceManagement = 35,
    ProcessCookie = 36,
    ProcessImageInformation = 37,       // q: TSectionImageInformation
    ProcessCycleTime = 38,
    ProcessPagePriority = 39,
    ProcessInstrumentationCallback = 40,
    ProcessThreadStackAllocation = 41,
    ProcessWorkingSetWatchEx = 42,
    ProcessImageFileNameWin32 = 43,     // q: UNICODE_STRING
    ProcessImageFileMapping = 44,
    ProcessAffinityUpdateMode = 45,
    ProcessMemoryAllocationMode = 46,
    ProcessGroupInformation = 47,
    ProcessTokenVirtualizationEnabled = 48,
    ProcessConsoleHostProcess = 49,
    ProcessWindowInformation = 50,
    ProcessHandleInformation = 51,   // q: TProcessHandleSnapshotInformation
    ProcessMitigationPolicy = 52,
    ProcessDynamicFunctionTableInformation = 53,
    ProcessHandleCheckingMode = 54,
    ProcessKeepAliveCount = 55,
    ProcessRevokeFileHandles = 56,
    ProcessWorkingSetControl = 57,
    ProcessHandleTable = 58,
    ProcessCheckStackExtentsMode = 59,
    ProcessCommandLineInformation = 60 // q: UNICODE_STRING
  );

  TProcessBasicInformation = record
    ExitStatus: NTSTATUS;
    [DontFollow] PebBaseAddress: PPeb;
    [Hex] AffinityMask: NativeUInt;
    BasePriority: KPRIORITY;
    UniqueProcessId: NativeUInt;
    InheritedFromUniqueProcessId: NativeUInt;
  end;
  PProcessBasicInformation = ^TProcessBasicInformation;

  TProcessAccessToken = record
    Token: THandle; // needs TOKEN_ASSIGN_PRIMARY
    Thread: THandle; // currently unused, was THREAD_QUERY_INFORMATION
  end;

  [NamingStyle(nsSnakeCase, 'PROCESS_DEBUG')]
  TProcessDebugFlags = (
    PROCESS_DEBUG_INHERIT = 1
  );

  TProcessHandleTableEntryInfo = record
    HandleValue: THandle;
    HandleCount: NativeUInt;
    PointerCount: NativeUInt;
    GrantedAccess: TAccessMask;
    ObjectTypeIndex: Cardinal;
    [Hex] HandleAttributes: Cardinal;
    [Unlisted] Reserved: Cardinal;
  end;
  PProcessHandleTableEntryInfo = ^TProcessHandleTableEntryInfo;

  TProcessHandleSnapshotInformation = record
    NumberOfHandles: NativeUInt;
    [Unlisted] Reserved: NativeUInt;
    Handles: array [ANYSIZE_ARRAY] of TProcessHandleTableEntryInfo;
  end;
  PProcessHandleSnapshotInformation = ^TProcessHandleSnapshotInformation;

  // Threads

  TInitialTeb = record
    OldStackBase: Pointer;
    OldStackLimit: Pointer;
    StackBase: Pointer;
    StackLimit: Pointer;
    StackAllocationBase: Pointer;
  end;
  PInitialTeb = ^TInitialTeb;

  [NamingStyle(nsCamelCase, 'Thread')]
  TThreadInfoClass = (
    ThreadBasicInformation = 0,    // q: TThreadBasicInformation
    ThreadTimes = 1,
    ThreadPriority = 2,
    ThreadBasePriority = 3,
    ThreadAffinityMask = 4,
    ThreadImpersonationToken = 5,  // s: THandle
    ThreadDescriptorTableEntry = 6,
    ThreadEnableAlignmentFaultFixup = 7,
    ThreadEventPair = 8,
    ThreadQuerySetWin32StartAddress = 9,
    ThreadZeroTlsCell = 10,
    ThreadPerformanceCount = 11,
    ThreadAmILastThread = 12,
    ThreadIdealProcessor = 13,
    ThreadPriorityBoost = 14,
    ThreadSetTlsArrayAddress = 15,
    ThreadIsIoPending = 16,
    ThreadHideFromDebugger = 17,
    ThreadBreakOnTermination = 18,
    ThreadSwitchLegacyState = 19,
    ThreadIsTerminated = 20,       // q: LongBool
    ThreadLastSystemCall = 21,
    ThreadIoPriority = 22,
    ThreadCycleTime = 23,
    ThreadPagePriority = 24,
    ThreadActualBasePriority = 25,
    ThreadTebInformation = 26,      // q: TThreadTebInformation
    ThreadCSwitchMon = 27,
    ThreadCSwitchPmu = 28,
    ThreadWow64Context = 29,
    ThreadGroupInformation = 30,
    ThreadUmsInformation = 31,
    ThreadCounterProfiling = 32,
    ThreadIdealProcessorEx = 33
  );

  TThreadBasicInformation = record
    ExitStatus: NTSTATUS;
    [DontFollow] TebBaseAddress: PTeb;
    ClientId: TClientId;
    [Hex] AffinityMask: NativeUInt;
    Priority: KPRIORITY;
    BasePriority: Integer;
  end;
  PThreadBasicInformation = ^TThreadBasicInformation;

  TThreadTebInformation = record
    TebInformation: Pointer;
    [Hex] TebOffset: Cardinal;
    [Bytes] BytesToRead: Cardinal;
  end;
  PThreadTebInformation = ^TThreadTebInformation;

  TPsApcRoutine = procedure (ApcArgument1, ApcArgument2, ApcArgument3: Pointer);
    stdcall;

  // User processes and threads

  TPsAttribute = record
    [Hex] Attribute: NativeUInt;
    [Bytes] Size: NativeUInt;
    Value: NativeUInt;
    ReturnLength: PNativeUInt;
  end;
  PPsAttribute = ^TPsAttribute;

  TPsAttributeList = record
    [Bytes] TotalLength: NativeUInt;
    Attributes: array [ANYSIZE_ARRAY] of TPsAttribute;
  end;
  PPsAttributeList = ^TPsAttributeList;

  [NamingStyle(nsCamelCase, 'PsCreate')]
  TPsCreateState = (
    PsCreateInitialState = 0,
    PsCreateFailOnFileOpen = 1,
    PsCreateFailOnSectionCreate = 2,
    PsCreateFailExeFormat = 3,
    PsCreateFailMachineMismatch = 4,
    PsCreateFailExeName = 5,
    PsCreateSuccess = 6
  );

  TPsCreateInfo = record
    [Bytes] Size: NativeUInt;
  case State: TPsCreateState of
    PsCreateInitialState: (
      InitFlags: Cardinal;
      AdditionalFileAccess: TAccessMask;
    );

    PsCreateFailOnSectionCreate: (
      FileHandleFail: THandle;
    );

    PsCreateFailExeFormat: (
      DllCharacteristics: Word;
    );

    PsCreateFailExeName: (
      IFEOKey: THandle;
    );

    PsCreateSuccess: (
      OutputFlags: Cardinal;
      FileHandleSuccess: THandle;
      SectionHandle: THandle;
      UserProcessParametersNative: UInt64;
      UserProcessParametersWow64: Cardinal;
      CurrentParameterFlags: Cardinal;
      PebAddressNative: UInt64;
      PebAddressWow64: Cardinal;
      ManifestAddress: UInt64;
      ManifestSize: Cardinal;
    );
  end;

  // Jobs

  [NamingStyle(nsCamelCase, 'JobObject'), Range(1)]
  TJobObjectInfoClass = (
    JobObjectReserved = 0,
    JobObjectBasicAccountingInformation = 1, // q: TJobBasicAccountingInfo
    JobObjectBasicLimitInformation = 2,      // q, s: TJobBasicLimitInfo
    JobObjectBasicProcessIdList = 3,         // q: TJobBasicProcessIdList
    JobObjectBasicUIRestrictions = 4,        // q, s: Cardinal (UI flags)
    JobObjectSecurityLimitInformation = 5,   // not supported
    JobObjectEndOfJobTimeInformation = 6,    // s: Cardinal (EndOfJobTimeAction)
    JobObjectAssociateCompletionPortInformation = 7, // s: TJobAssociateCompletionPort
    JobObjectBasicAndIoAccountingInformation = 8, // q: TJobBasicAndIoAccountingInfo
    JobObjectExtendedLimitInformation = 9,   // q, s: TJobExtendedLimitInfo
    JobObjectJobSetInformation = 10,         // q: Cardinal (MemberLevel)
    JobObjectGroupInformation = 11,          // q, s: Word
    JobObjectNotificationLimitInformation = 12, // q, s: TJobNotificationLimitInfo
    JobObjectLimitViolationInformation = 13, //
    JobObjectGroupInformationEx = 14,        // q, s:
    JobObjectCpuRateControlInformation = 15  // q, s: TJobCpuRateControlInfo
  );

  TJobBasicAccountingInfo = record
    TotalUserTime: TLargeInteger;
    TotalKernelTime: TLargeInteger;
    ThisPeriodTotalUserTime: TLargeInteger;
    ThisPeriodTotalKernelTime: TLargeInteger;
    TotalPageFaultCount: Cardinal;
    TotalProcesses: Cardinal;
    ActiveProcesses: Cardinal;
    TotalTerminatedProcesses: Cardinal;
  end;
  PJobBasicAccountingInfo = ^TJobBasicAccountingInfo;

  TJobBasicLimitInfo = record
    PerProcessUserTimeLimit: TLargeInteger;
    PerJobUserTimeLimit: TLargeInteger;
    [Hex] LimitFlags: Cardinal;
    [Bytes] MinimumWorkingSetSize: NativeUInt;
    [Bytes] MaximumWorkingSetSize: NativeUInt;
    ActiveProcessLimit: Cardinal;
    [Hex] Affinity: NativeUInt;
    PriorityClass: Cardinal;
    SchedulingClass: Cardinal;
  end;
  PJobBasicLimitInfo = ^TJobBasicLimitInfo;

  TJobBasicProcessIdList = record
    NumberOfAssignedProcesses: Cardinal;
    NumberOfProcessIdsInList: Cardinal;
    ProcessIdList: array [ANYSIZE_ARRAY] of NativeUInt;
  end;
  PJobBasicProcessIdList = ^TJobBasicProcessIdList;

  [NamingStyle(nsSnakeCase, 'JOB_OBJECT_MSG'), Range(1)]
  TJobObjectMsg = (
    JOB_OBJECT_MSG_RESERVED = 0,
    JOB_OBJECT_MSG_END_OF_JOB_TIME = 1,
    JOB_OBJECT_MSG_END_OF_PROCESS_TIME = 2,
    JOB_OBJECT_MSG_ACTIVE_PROCESS_LIMIT = 3,
    JOB_OBJECT_MSG_ACTIVE_PROCESS_ZERO = 4,
    JOB_OBJECT_MSG_NEW_PROCESS = 6,
    JOB_OBJECT_MSG_EXIT_PROCESS = 7,
    JOB_OBJECT_MSG_ABNORMAL_EXIT_PROCESS = 8,
    JOB_OBJECT_MSG_PROCESS_MEMORY_LIMIT = 9,
    JOB_OBJECT_MSG_JOB_MEMORY_LIMIT = 10,
    JOB_OBJECT_MSG_NOTIFICATION_LIMIT = 11,
    JOB_OBJECT_MSG_JOB_CYCLE_TIME_LIMIT = 12,
    JOB_OBJECT_MSG_SILO_TERMINATED = 13
  );

  TJobAssociateCompletionPort = record
    CompletionKey: Pointer;
    CompletionPort: THandle;
  end;
  PJobAssociateCompletionPort = ^TJobAssociateCompletionPort;

  TJobBasicAndIoAccountingInfo = record
    BasicInfo: TJobBasicAccountingInfo;
    IoInfo: TIoCounters;
  end;
  PJobBasicAndIoAccountingInfo = ^TJobBasicAndIoAccountingInfo;

  TJobExtendedLimitInfo = record
    BasicLimitInformation: TJobBasicLimitInfo;
    IoInfo: TIoCounters;
    [Bytes] ProcessMemoryLimit: NativeUInt;
    [Bytes] JobMemoryLimit: NativeUInt;
    [Bytes] PeakProcessMemoryUsed: NativeUInt;
    [Bytes] PeakJobMemoryUsed: NativeUInt;
  end;
  PJobExtendedLimitInfo = ^TJobExtendedLimitInfo;

  [NamingStyle(nsCamelCase, 'Tolerance'), Range(1)]
  TJobRateControlTolerance = (
    ToleranceInvalid = 0,
    ToleranceLow = 1,
    ToleranceMedium = 2,
    ToleranceHigh = 3
  );

  [NamingStyle(nsCamelCase, 'ToleranceInterval'), Range(1)]
  TJobRateControlToleranceInterval = (
    ToleranceIntervalInvalid = 0,
    ToleranceIntervalShort = 1,
    ToleranceIntervalMedium = 2,
    ToleranceIntervalLong = 3
  );

  TJobNotificationLimitInfo = record
    [Bytes] IoReadBytesLimit: UInt64;
    [Bytes] IoWriteBytesLimit: UInt64;
    PerJobUserTimeLimit: TLargeInteger;
    [Bytes] JobMemoryLimit: UInt64;
    RateControlTolerance: TJobRateControlTolerance;
    RateControlToleranceInterval: TJobRateControlToleranceInterval;
    [Hex] LimitFlags: Cardinal;
  end;
  PJobNotificationLimitInfo = ^TJobNotificationLimitInfo;

  TJobCpuRateControlInfo = record
    [Hex] ControlFlags: Cardinal;
  case Integer of
    0: (CpuRate: Cardinal);
    1: (Weight: Cardinal);
    2: (MinRate: Word; MaxRate: Word);
  end;
  PJobCpuRateControlInfo = ^TJobCpuRateControlInfo;

// Processes

function NtCreateProcess(out ProcessHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; ParentProcess: THandle;
  InheritObjectTable: Boolean; SectionHandle: THandle; DebugPort: THandle;
  ExceptionPort: THandle): NTSTATUS; stdcall; external ntdll;

function NtCreateProcessEx(out ProcessHandle: THandle; DesiredAccess:
  TAccessMask; ObjectAttributes: PObjectAttributes; ParentProcess: THandle;
  Flags: Cardinal; SectionHandle: THandle; DebugPort: THandle; ExceptionPort:
  THandle; JobMemberLevel: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtOpenProcess(out ProcessHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; const ClientId: TClientId):
  NTSTATUS; stdcall; external ntdll;

function NtTerminateProcess(ProcessHandle: THandle; ExitStatus: NTSTATUS):
  NTSTATUS; stdcall; external ntdll;

function NtSuspendProcess(ProcessHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtResumeProcess(ProcessHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtQueryInformationProcess(ProcessHandle: THandle;
  ProcessInformationClass: TProcessInfoClass; ProcessInformation: Pointer;
  ProcessInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS;
  stdcall; external ntdll;

// Absent in ReactOS
function NtGetNextProcess(ProcessHandle: THandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal; Flags: Cardinal; out NewProcessHandle: THandle):
  NTSTATUS; stdcall; external ntdll delayed;

// Absent in ReactOS
function NtGetNextThread(ProcessHandle: THandle; ThreadHandle: THandle;
  DesiredAccess: TAccessMask; HandleAttributes: Cardinal; Flags: Cardinal;
  out NewThreadHandle: THandle): NTSTATUS; stdcall; external ntdll delayed;

function NtSetInformationProcess(ProcessHandle: THandle;
  ProcessInformationClass: TProcessInfoClass; ProcessInformation: Pointer;
  ProcessInformationLength: Cardinal): NTSTATUS; stdcall; external ntdll;

// Threads

function NtCreateThread(out ThreadHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; ProcessHandle: THandle; out ClientId:
  TClientId; const ThreadContext: TContext; const InitialTeb: TInitialTeb;
  CreateSuspended: Boolean): NTSTATUS; stdcall; external ntdll;

function NtOpenThread(out ThreadHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; const ClientId: TClientId):
  NTSTATUS; stdcall; external ntdll;

function NtTerminateThread(ThreadHandle: THandle; ExitStatus: NTSTATUS):
  NTSTATUS; stdcall; external ntdll;

function NtSuspendThread(ThreadHandle: THandle; PreviousSuspendCount:
  PCardinal = nil): NTSTATUS; stdcall; external ntdll;

function NtResumeThread(ThreadHandle: THandle; PreviousSuspendCount:
  PCardinal = nil): NTSTATUS; stdcall; external ntdll;

function NtGetCurrentProcessorNumber: Cardinal; stdcall; external ntdll;

function NtGetContextThread(ThreadHandle: THandle; ThreadContext: PContext):
  NTSTATUS; stdcall; external ntdll;

function NtSetContextThread(ThreadHandle: THandle; ThreadContext: PContext):
  NTSTATUS; stdcall; external ntdll;

function NtQueryInformationThread(ThreadHandle: THandle;
  ThreadInformationClass: TThreadInfoClass; ThreadInformation: Pointer;
  ThreadInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS;
  stdcall; external ntdll;

function NtSetInformationThread(ThreadHandle: THandle;
  ThreadInformationClass: TThreadInfoClass; ThreadInformation: Pointer;
  ThreadInformationLength: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtAlertThread(ThreadHandle: THandle): NTSTATUS; stdcall;
  external ntdll;

function NtAlertResumeThread(ThreadHandle: THandle; PreviousSuspendCount:
  PCardinal): NTSTATUS; stdcall; external ntdll;

function NtImpersonateThread(ServerThreadHandle: THandle;
  ClientThreadHandle: THandle; const SecurityQos: TSecurityQualityOfService):
  NTSTATUS; stdcall; external ntdll;

function NtQueueApcThread(ThreadHandle: THandle; ApcRoutine: TPsApcRoutine;
  ApcArgument1, ApcArgument2, ApcArgument3: Pointer): NTSTATUS; stdcall;
  external ntdll;

// User processes and threads

function NtCreateUserProcess(out ProcessHandle: THandle; out ThreadHandle:
  THandle; ProcessDesiredAccess: TAccessMask; ThreadDesiredAccess: TAccessMask;
  ProcessObjectAttributes: PObjectAttributes; ThreadObjectAttributes:
  PObjectAttributes; ProcessFlags: Cardinal; ThreadFlags: Cardinal;
  ProcessParameters: PRtlUserProcessParameters; var CreateInfo: TPsCreateInfo;
  AttributeList: PPsAttributeList): NTSTATUS; stdcall; external ntdll;

function NtCreateThreadEx(out ThreadHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; ProcessHandle: THandle; StartRoutine:
  TUserThreadStartRoutine; Argument: Pointer; CreateFlags: Cardinal; ZeroBits:
  NativeUInt; StackSize: NativeUInt; MaximumStackSize: NativeUInt;
  AttributeList: PPsAttributeList): NTSTATUS; stdcall; external ntdll;

// Job objects

function NtCreateJobObject(out JobHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes): NTSTATUS; stdcall; external ntdll;

function NtOpenJobObject(out JobHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes): NTSTATUS; stdcall; external ntdll;

function NtAssignProcessToJobObject(JobHandle: THandle; ProcessHandle: THandle):
  NTSTATUS; stdcall; external ntdll;

function NtTerminateJobObject(JobHandle: THandle; ExitStatus: NTSTATUS):
  NTSTATUS; stdcall; external ntdll;

function NtIsProcessInJob(ProcessHandle: THandle;
  JobHandle: THandle): NTSTATUS; stdcall; external ntdll;

function NtQueryInformationJobObject(JobHandle: THandle;
  JobObjectInformationClass: TJobObjectInfoClass; JobObjectInformation: Pointer;
  JobObjectInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS;
  stdcall; external ntdll;

function NtSetInformationJobObject(JobHandle: THandle;
  JobObjectInformationClass: TJobObjectInfoClass; JobObjectInformation: Pointer;
  JobObjectInformationLength: Cardinal): NTSTATUS; stdcall; external ntdll;

implementation

function NtCurrentProcessId: TProcessId;
begin
  Result := NtCurrentTeb.ClientId.UniqueProcess;
end;

function NtCurrentThreadId: TThreadId;
begin
  Result := NtCurrentTeb.ClientId.UniqueThread;
end;

end.
