unit NtUtils.Threads.Worker;

{
  The module provides support for using worker factories (the type of kernel
  objects behind thread pools).
}

interface

uses
  Ntapi.nttp, Ntapi.ntioapi, NtUtils, NtUtils.Synchronization;

// Create a worker factory object
function NtxCreateWorkerFactory(
  out hxWorkerFactory: IHandle;
  [Access(IO_COMPLETION_MODIFY_STATE)] hCompletionPort: THandle;
  [in] StartRoutine: TWorkerFactoryRoutine;
  [in, opt] StartParameter: Pointer;
  MaxThreadCount: Cardinal = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  StackReserve: NativeUInt = 0;
  StackCommit: NativeUInt = 0
): TNtxStatus;

// Query basic information about a worker factory
function NtxQueryWorkerFactory(
  [Access(WORKER_FACTORY_QUERY_INFORMATION)] hWorkerFactory: THandle;
  out Info: TWorkerFactoryBasicInformation
): TNtxStatus;

type
  NtxWorkerFactory = class abstract
    // Set fixed-size information for a worker factory
    class function &Set<T>(
      [Access(WORKER_FACTORY_SET_INFORMATION)] hWorkerFactory: THandle;
      InfoClass: TWorkerFactoryInfoClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Shutdown a worker factory
function NtxShutdownWorkerFactory(
  [Access(WORKER_FACTORY_SHUTDOWN)] hWorkerFactory: THandle;
  out PendingWorkerCount: Cardinal
): TNtxStatus;

// Release a worker from a worker factory
function NtxReleaseWorkerFactoryWorker(
  [Access(WORKER_FACTORY_RELEASE_WORKER)] hWorkerFactory: THandle
): TNtxStatus;

// Mark a worker from a worker factory as being ready
function NtxWorkerFactoryWorkerReady(
  [Access(WORKER_FACTORY_READY_WORKER)] hWorkerFactory: THandle
): TNtxStatus;

// Wait for a queued task on the I/O completion port of the worker factory
function NtxWaitForWorkViaWorkerFactory(
  [Access(WORKER_FACTORY_WAIT)] hWorkerFactory: THandle;
  out MiniPacket: TIoCompletionPacket
): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, NtUtils.Objects;

function NtxCreateWorkerFactory;
var
  hWorkerFactory: THandle;
begin
  Result.Location := 'NtCreateWorkerFactory';
  Result.LastCall.Expects<TIoCompeletionAccessMask>(IO_COMPLETION_MODIFY_STATE);
  Result.Status := NtCreateWorkerFactory(
    hWorkerFactory,
    AccessMaskOverride(WORKER_FACTORY_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    hCompletionPort,
    NtCurrentProcess,
    StartRoutine,
    StartParameter,
    MaxThreadCount,
    StackReserve,
    StackCommit
  );

  if Result.IsSuccess then
    hxWorkerFactory := Auto.CaptureHandle(hWorkerFactory);
end;

function NtxQueryWorkerFactory;
begin
  Result.Location := 'NtQueryInformationWorkerFactory';
  Result.LastCall.UsesInfoClass(WorkerFactoryBasicInformation, icQuery);
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_QUERY_INFORMATION);

  Result.Status := NtQueryInformationWorkerFactory(hWorkerFactory,
    WorkerFactoryBasicInformation,
    @Info, SizeOf(Info), nil);
end;

class function NtxWorkerFactory.&Set<T>;
begin
  Result.Location := 'NtSetInformationWorkerFactory';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_SET_INFORMATION);

  Result.Status := NtSetInformationWorkerFactory(hWorkerFactory, InfoClass,
    @Buffer, SizeOf(Buffer));
end;

function NtxShutdownWorkerFactory;
begin
  PendingWorkerCount := 0;

  Result.Location := 'NtShutdownWorkerFactory';
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_SHUTDOWN);
  Result.Status := NtShutdownWorkerFactory(hWorkerFactory,
    Integer(PendingWorkerCount));
end;

function NtxReleaseWorkerFactoryWorker;
begin
  Result.Location := 'NtReleaseWorkerFactoryWorker';
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_RELEASE_WORKER);
  Result.Status := NtReleaseWorkerFactoryWorker(hWorkerFactory);
end;

function NtxWorkerFactoryWorkerReady;
begin
  Result.Location := 'NtWorkerFactoryWorkerReady';
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_READY_WORKER);
  Result.Status := NtWorkerFactoryWorkerReady(hWorkerFactory);
end;

function NtxWaitForWorkViaWorkerFactory;
begin
  Result.Location := 'NtWaitForWorkViaWorkerFactory';
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_WAIT);
  Result.Status := NtWaitForWorkViaWorkerFactory(hWorkerFactory, MiniPacket);
end;

end.
