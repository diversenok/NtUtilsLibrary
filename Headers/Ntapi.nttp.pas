unit Ntapi.nttp;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, DelphiApi.Reflection;

const
  WORKER_FACTORY_RELEASE_WORKER = $0001;
  WORKER_FACTORY_WAIT = $0002;
  WORKER_FACTORY_SET_INFORMATION = $0004;
  WORKER_FACTORY_QUERY_INFORMATION = $0008;
  WORKER_FACTORY_READY_WORKER = $0010;
  WORKER_FACTORY_SHUTDOWN = $0020;

  WORKER_FACTORY_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

type
  [FriendlyName('worker factory')]
  [ValidMask(WORKER_FACTORY_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(WORKER_FACTORY_RELEASE_WORKER, 'Release Worker')]
  [FlagName(WORKER_FACTORY_WAIT, 'Wait')]
  [FlagName(WORKER_FACTORY_SET_INFORMATION, 'Set Information')]
  [FlagName(WORKER_FACTORY_QUERY_INFORMATION, 'Query Information')]
  [FlagName(WORKER_FACTORY_READY_WORKER, 'Ready Worker')]
  [FlagName(WORKER_FACTORY_SHUTDOWN, 'Shutdown')]
  TWorkerFactoryAccessMask = type TAccessMask;

  TWorkerFactoryRoutine = procedure (
    [in, opt] StartParameter: Pointer
  ); stdcall;

  [NamingStyle(nsCamelCase, 'WorkerFactory')]
  TWorkerFactoryInfoClass = (
    WorkerFactoryTimeout = 0,             //
    WorkerFactoryRetryTimeout = 1,        //
    WorkerFactoryIdleTimeout = 2,         // s: TLargeInteger
    WorkerFactoryBindingCount = 3,        // s: Cardinal
    WorkerFactoryThreadMinimum = 4,       // s: Cardinal
    WorkerFactoryThreadMaximum = 5,       // s: Cardinal
    WorkerFactoryPaused = 6,              //
    WorkerFactoryBasicInformation = 7,    // q: TWorkerFactoryBasicInformation
    WorkerFactoryAdjustThreadGoal = 8,    // s: Cardinal
    WorkerFactoryCallbackType = 9,        // s:
    WorkerFactoryStackInformation = 10,   // s:
    WorkerFactoryThreadBasePriority = 11, // s: TPriority
    WorkerFactoryTimeoutWaiters = 12,     // s: Cardinal, Win 10 TH1+
    WorkerFactoryFlags = 13,              // s: Cardinal
    WorkerFactoryThreadSoftMaximum = 14,  // s: Cardinal
    WorkerFactoryThreadCpuSets = 15       // s: ?, Win 10 RS5+
  );

  TWorkerFactoryBasicInformation = record
    Timeout: TLargeInteger;
    RetryTimeout: TLargeInteger;
    IdleTimeout: TLargeInteger;
    Paused: Boolean;
    TimerSet: Boolean;
    QueuedToExWorker: Boolean;
    MayCreate: Boolean;
    CreateInProgress: Boolean;
    InsertedIntoQueue: Boolean;
    Shutdown: Boolean;
    BindingCount: Cardinal;
    ThreadMinimum: Cardinal;
    ThreadMaximum: Cardinal;
    PendingWorkerCount: Cardinal;
    WaitingWorkerCount: Cardinal;
    TotalWorkerCount: Cardinal;
    ReleaseCount: Cardinal;
    InfiniteWaitGoal: Int64;
    StartRoutine: Pointer;
    StartParameter: Pointer;
    ProcessID: TProcessId;
    StackReserve: NativeUInt;
    StackCommit: NativeUInt;
    LastThreadCreationStatus: NTSTATUS;
  end;

// Worker Factory

function NtCreateWorkerFactory(
  out WorkerFactoryHandle: THandle;
  DesiredAccess: TWorkerFactoryAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  CompletionPortHandle: THandle;
  WorkerProcessHandle: THandle;
  StartRoutine: TWorkerFactoryRoutine;
  [in, opt] StartParameter: Pointer;
  MaxThreadCount: Cardinal;
  StackReserve: NativeUInt;
  StackCommit: NativeUInt
): NTSTATUS; stdcall; external ntdll;

function NtQueryInformationWorkerFactory(
  WorkerFactoryHandle: THandle;
  WorkerFactoryInformationClass: TWorkerFactoryInfoClass;
  [out] WorkerFactoryInformation: Pointer;
  WorkerFactoryInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

function NtSetInformationWorkerFactory(
  WorkerFactoryHandle: THandle;
  WorkerFactoryInformationClass: TWorkerFactoryInfoClass;
  [in] WorkerFactoryInformation: Pointer;
  WorkerFactoryInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtShutdownWorkerFactory(
  WorkerFactoryHandle: THandle;
  var PendingWorkerCount: Integer
): NTSTATUS; stdcall; external ntdll;

function NtReleaseWorkerFactoryWorker(
  WorkerFactoryHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtWorkerFactoryWorkerReady(
  WorkerFactoryHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtWaitForWorkViaWorkerFactory(
  WorkerFactoryHandle: THandle;
  out MiniPacket: TFileIoCompletionInformation
): NTSTATUS; stdcall; external ntdll;

implementation

end.
