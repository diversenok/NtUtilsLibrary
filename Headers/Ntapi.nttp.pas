unit Ntapi.nttp;

{
  This module provides functions for using Worker Factories (aka Thread Pool).
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, DelphiApi.Reflection;

const
  // PHNT::ntexapi.h
  WORKER_FACTORY_RELEASE_WORKER = $0001;
  WORKER_FACTORY_WAIT = $0002;
  WORKER_FACTORY_SET_INFORMATION = $0004;
  WORKER_FACTORY_QUERY_INFORMATION = $0008;
  WORKER_FACTORY_READY_WORKER = $0010;
  WORKER_FACTORY_SHUTDOWN = $0020;

  WORKER_FACTORY_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

type
  [FriendlyName('worker factory'), ValidBits(WORKER_FACTORY_ALL_ACCESS)]
  [SubEnum(WORKER_FACTORY_ALL_ACCESS, WORKER_FACTORY_ALL_ACCESS, 'Full Access')]
  [FlagName(WORKER_FACTORY_RELEASE_WORKER, 'Release Worker')]
  [FlagName(WORKER_FACTORY_WAIT, 'Wait')]
  [FlagName(WORKER_FACTORY_SET_INFORMATION, 'Set Information')]
  [FlagName(WORKER_FACTORY_QUERY_INFORMATION, 'Query Information')]
  [FlagName(WORKER_FACTORY_READY_WORKER, 'Ready Worker')]
  [FlagName(WORKER_FACTORY_SHUTDOWN, 'Shutdown')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TWorkerFactoryAccessMask = type TAccessMask;

  TWorkerFactoryRoutine = procedure (
    [in, opt] StartParameter: Pointer
  ); stdcall;

  // PHNT::ntexapi.h
  [SDKName('WORKERFACTORYINFOCLASS')]
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

  // PHNT::ntexapi.h
  [SDKName('WORKER_FACTORY_BASIC_INFORMATION')]
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

// PHNT::ntexapi.h
function NtCreateWorkerFactory(
  [out, ReleaseWith('NtClose')] out WorkerFactoryHandle: THandle;
  [in] DesiredAccess: TWorkerFactoryAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in, Access(IO_COMPLETION_MODIFY_STATE)] CompletionPortHandle: THandle;
  [in, Access(PROCESS_CREATE_THREAD or PROCESS_VM_OPERATION or
    PROCESS_VM_WRITE)] WorkerProcessHandle: THandle; // Current process only
  [in] StartRoutine: TWorkerFactoryRoutine;
  [in, opt] StartParameter: Pointer;
  [in] MaxThreadCount: Cardinal;
  [in, opt] StackReserve: NativeUInt;
  [in, opt] StackCommit: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtQueryInformationWorkerFactory(
  [in, Access(WORKER_FACTORY_QUERY_INFORMATION)] WorkerFactoryHandle: THandle;
  [in] WorkerFactoryInformationClass: TWorkerFactoryInfoClass;
  [out, WritesTo] WorkerFactoryInformation: Pointer;
  [in, NumberOfBytes] WorkerFactoryInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtSetInformationWorkerFactory(
  [in, Access(WORKER_FACTORY_SET_INFORMATION)] WorkerFactoryHandle: THandle;
  [in] WorkerFactoryInformationClass: TWorkerFactoryInfoClass;
  [in, ReadsFrom] WorkerFactoryInformation: Pointer;
  [in, NumberOfBytes] WorkerFactoryInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtShutdownWorkerFactory(
  [in, Access(WORKER_FACTORY_SHUTDOWN)] WorkerFactoryHandle: THandle;
  [in, out] var PendingWorkerCount: Integer
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtReleaseWorkerFactoryWorker(
  [in, Access(WORKER_FACTORY_RELEASE_WORKER)] WorkerFactoryHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtWorkerFactoryWorkerReady(
  [in, Access(WORKER_FACTORY_READY_WORKER)] WorkerFactoryHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h
function NtWaitForWorkViaWorkerFactory(
  [in, Access(WORKER_FACTORY_WAIT)] WorkerFactoryHandle: THandle;
  [out] out MiniPacket: TFileIoCompletionInformation
): NTSTATUS; stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
