unit NtUtils.Threads.Worker;

{
  The module provides support for using worker factories (the type of kernel
  objects behind thread pools).
}

interface

uses
  Ntapi.nttp, Ntapi.ntioapi, Ntapi.ntrtl, NtUtils, NtUtils.Synchronization;

{ RTL thread pool}

// Queue an anonymous function to execute on the thread pool
function RtlxQueueWorkItem(
  Callback: TOperation;
  Flags: TRtlWorkerThreadFlags = 0
): TNtxStatus;

{ Worker factories }

// Create a worker factory object
function NtxCreateWorkerFactory(
  out hxWorkerFactory: IHandle;
  [Access(IO_COMPLETION_MODIFY_STATE)] const hxCompletionPort: IHandle;
  [in] StartRoutine: TWorkerFactoryRoutine;
  [in, opt] StartParameter: Pointer;
  MaxThreadCount: Cardinal = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  StackReserve: NativeUInt = 0;
  StackCommit: NativeUInt = 0
): TNtxStatus;

// Query basic information about a worker factory
function NtxQueryWorkerFactory(
  [Access(WORKER_FACTORY_QUERY_INFORMATION)] const hxWorkerFactory: IHandle;
  out Info: TWorkerFactoryBasicInformation
): TNtxStatus;

type
  NtxWorkerFactory = class abstract
    // Set fixed-size information for a worker factory
    class function &Set<T>(
      [Access(WORKER_FACTORY_SET_INFORMATION)] const hxWorkerFactory: IHandle;
      InfoClass: TWorkerFactoryInfoClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Shutdown a worker factory
function NtxShutdownWorkerFactory(
  [Access(WORKER_FACTORY_SHUTDOWN)] const hxWorkerFactory: IHandle;
  out PendingWorkerCount: Cardinal
): TNtxStatus;

// Release a worker from a worker factory
function NtxReleaseWorkerFactoryWorker(
  [Access(WORKER_FACTORY_RELEASE_WORKER)] const hxWorkerFactory: IHandle
): TNtxStatus;

// Mark a worker from a worker factory as being ready
function NtxWorkerFactoryWorkerReady(
  [Access(WORKER_FACTORY_READY_WORKER)] const hxWorkerFactory: IHandle
): TNtxStatus;

// Wait for a queued task on the I/O completion port of the worker factory
function NtxWaitForWorkViaWorkerFactory(
  [Access(WORKER_FACTORY_WAIT)] const hxWorkerFactory: IHandle;
  out MiniPacket: TIoCompletionPacket
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpsapi, NtUtils.Objects, DelphiUtils.AutoObjects,
  DelphiUtils.AutoEvents;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

procedure RtlxWorkerCallbackDispatcher(Context: Pointer); stdcall;
var
  Callback: TOperation;
begin
  if TInterfaceTable.Find(NativeUInt(Context), Callback, True) then
  try
    Callback;
  except
    on E: TObject do
      if not Assigned(AutoExceptionHanlder) or not AutoExceptionHanlder(E) then
        raise;
  end;
end;

function RtlxQueueWorkItem;
var
  CallbackIntf: IInterface absolute Callback;
  Cookie: NativeUInt;
begin
  Cookie := TInterfaceTable.Add(CallbackIntf);

  Result.Location := 'RtlQueueWorkItem';
  Result.Status := RtlQueueWorkItem(RtlxWorkerCallbackDispatcher,
    Pointer(Cookie), Flags);

  if not Result.IsSuccess then
    TInterfaceTable.Remove(Cookie);
end;

function NtxCreateWorkerFactory;
var
  ObjAttr: PObjectAttributes;
  hWorkerFactory: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateWorkerFactory';
  Result.LastCall.Expects<TIoCompletionAccessMask>(IO_COMPLETION_MODIFY_STATE);
  Result.Status := NtCreateWorkerFactory(
    hWorkerFactory,
    AccessMaskOverride(WORKER_FACTORY_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    HandleOrDefault(hxCompletionPort),
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

  Result.Status := NtQueryInformationWorkerFactory(
    HandleOrDefault(hxWorkerFactory),
    WorkerFactoryBasicInformation,
    @Info, SizeOf(Info), nil);
end;

class function NtxWorkerFactory.&Set<T>;
begin
  Result.Location := 'NtSetInformationWorkerFactory';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_SET_INFORMATION);

  Result.Status := NtSetInformationWorkerFactory(
    HandleOrDefault(hxWorkerFactory), InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxShutdownWorkerFactory;
begin
  PendingWorkerCount := 0;

  Result.Location := 'NtShutdownWorkerFactory';
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_SHUTDOWN);
  Result.Status := NtShutdownWorkerFactory(HandleOrDefault(hxWorkerFactory),
    Integer(PendingWorkerCount));
end;

function NtxReleaseWorkerFactoryWorker;
begin
  Result.Location := 'NtReleaseWorkerFactoryWorker';
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_RELEASE_WORKER);
  Result.Status := NtReleaseWorkerFactoryWorker(HandleOrDefault(hxWorkerFactory));
end;

function NtxWorkerFactoryWorkerReady;
begin
  Result.Location := 'NtWorkerFactoryWorkerReady';
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_READY_WORKER);
  Result.Status := NtWorkerFactoryWorkerReady(HandleOrDefault(hxWorkerFactory));
end;

function NtxWaitForWorkViaWorkerFactory;
begin
  Result.Location := 'NtWaitForWorkViaWorkerFactory';
  Result.LastCall.Expects<TWorkerFactoryAccessMask>(WORKER_FACTORY_WAIT);
  Result.Status := NtWaitForWorkViaWorkerFactory(
    HandleOrDefault(hxWorkerFactory), MiniPacket);
end;

end.
