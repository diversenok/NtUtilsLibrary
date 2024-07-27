unit NtUtils.Synchronization;

{
  This module provides function for working with synchronization objects such
  as events, semaphores, and mutexes.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntexapi, Ntapi.ntobapi, Ntapi.ntioapi,
  Ntapi.ntrtl, NtUtils;

const
  // Infinite timeout for native wait functions
  NT_INFINITE = Ntapi.WinNt.NT_INFINITE;

type
  TRtlCriticalSection = Ntapi.ntrtl.TRtlCriticalSection;
  TRtlResource = Ntapi.ntrtl.TRtlResource;
  TRtlSRWLock = Ntapi.ntrtl.TRtlSRWLock;
  TRtlRunOnce = Ntapi.ntrtl.TRtlRunOnce;
  TIoCompletionPacket = Ntapi.ntioapi.TFileIoCompletionInformation;

  // Represents an acquired RunOnce lock. By default, releasing this interface
  // will release the lock as unsuccessful. Calling Complete releases the lock
  // as successful.
  IAcquiredRunOnce = interface (IAutoReleasable)
    procedure Complete([in, opt] Context: Pointer = nil);
  end;

{ ------------------------ User-mode synchronization ------------------------ }

// Enter a critical section and automatically exit it later
[Result: MayReturnNil]
function RtlxEnterCriticalSection(
  [in, out] CriticalSection: PRtlCriticalSection
): IAutoReleasable;

// Try to enter a critical section and automatically exit it later
function RtlxTryEnterCriticalSection(
  [in, out] CriticalSection: PRtlCriticalSection;
  out Reverter: IAutoReleasable
): Boolean;

// Acquire a resource for shared (read) access and release it later
[Result: MayReturnNil]
function RtlxAcquireResourceShared(
  [in, out] Resource: PRtlResource
): IAutoReleasable;

// Try to acquire a resource for shared (read) access and release it later
function RtlxTryAcquireResourceShared(
  [in, out] Resource: PRtlResource;
  out Reverter: IAutoReleasable
): Boolean;

// Acquire a resource for exclusive (write) access and release it later
[Result: MayReturnNil]
function RtlxAcquireResourceExclusive(
  [in, out] Resource: PRtlResource
): IAutoReleasable;

// Try to acquire a resource for exclusive (write) access and release it later
function RtlxTryAcquireResourceExclusive(
  [in, out] Resource: PRtlResource;
  out Reverter: IAutoReleasable
): Boolean;

// Acquire an SRW lock for shared (read) access and release it later
function RtlxAcquireSRWLockShared(
  [in, out] SRWLock: PRtlSRWLock
): IAutoReleasable;

// Try to acquire an SRW lock for shared (read) access and release it later
function RtlxTryAcquireSRWLockShared(
  [in, out] SRWLock: PRtlSRWLock;
  out Reverter: IAutoReleasable
): Boolean;

// Acquire an SRW lock for exclusive (write) access and release it later
function RtlxAcquireSRWLockExclusive(
  [in, out] SRWLock: PRtlSRWLock
): IAutoReleasable;

// Try to acquire an SRW lock for exclusive (write) access and release it later
function RtlxTryAcquireSRWLockExclusive(
  [in, out] SRWLock: PRtlSRWLock;
  out Reverter: IAutoReleasable
): Boolean;

// Synchronize a one-time initialization. Possible results:
// - True: the caller is responsible for performing the initialization. To
//   indicate success, call Complete on the returned object. Releasing the
//   object without calling Complete indicates a failure. Either operation
//   unlocks other waiting threads.
// - False: the initialization has already happened and the caller can use the
//   resource. The optional Context parameter provides the value previously
//   passed to Complete.
function RtlxRunOnceBegin(
  [in, out] RunOnce: PRtlRunOnce;
  out AcquiredState: IAcquiredRunOnce;
  [out, opt, MayReturnNil] Context: PPointer = nil
): Boolean;

{ ---------------------------------- Waits ---------------------------------- }

// Wait for an object to enter signaled state
function NtxWaitForSingleObject(
  [Access(SYNCHRONIZE)] const hxObject: IHandle;
  const Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False
): TNtxStatus;

// Wait for any/all objects to enter a signaled state
function NtxWaitForMultipleObjects(
  [Access(SYNCHRONIZE)] const Objects: TArray<IHandle>;
  WaitType: TWaitType;
  const Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False
): TNtxStatus;

// Delay current thread's execution until a timeout or an APC/alert
function NtxDelayExecution(
  const Timeout: Int64;
  Alertable: Boolean = False
): TNtxStatus;

// Delay current thread's execution while processing APCs.
// This function supports absolute and relative timeouts and re-enters alertable
// wait after each APC, all while transparently preserving the total wait time.
// If the content of the BreakCondition variable becomes true after an APC,
// the function exits prematurely.
function NtxMultiDelayExecution(
  const Timeout: Int64;
  [in, opt, volatile] BreakCondition: PLongBool = nil
): TNtxStatus;

{ ---------------------------------- Event ---------------------------------- }

// Create a new event object
function NtxCreateEvent(
  out hxEvent: IHandle;
  EventType: TEventType;
  InitialState: Boolean;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an existing event object
function NtxOpenEvent(
  out hxEvent: IHandle;
  DesiredAccess: TEventAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Transition an event object to an alerted state
function NtxSetEvent(
  [Access(EVENT_MODIFY_STATE)] const hxEvent: IHandle;
  [out, opt] PreviousState: PLongBool = nil
): TNtxStatus;

// Make an event object alerted and boost priority of the waiting thread
function NtxSetEventBoostPriority(
  [Access(EVENT_MODIFY_STATE)] const hxEvent: IHandle
): TNtxStatus;

// Transition an event object to an non-alerted state
function NtxResetEvent(
  [Access(EVENT_MODIFY_STATE)] const hxEvent: IHandle;
  [out, opt] PreviousState: PLongBool = nil
): TNtxStatus;

// Release one waiting thread without changing the state of the event
function NtxPulseEvent(
  [Access(EVENT_MODIFY_STATE)] const hxEvent: IHandle;
  [out, opt] PreviousState: PLongBool = nil
): TNtxStatus;

// Query basic information about an event object
function NtxQueryEvent(
  [Access(EVENT_QUERY_STATE)] const hxEvent: IHandle;
  out BasicInfo: TEventBasicInformation
): TNtxStatus;

{ ------------------------------- Keyed Event ------------------------------- }

// Create a new keyed event object
function NtxCreateKeyedEvent(
  out hxKeyedEvent: IHandle;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open a keyed event object
function NtxOpenKeyedEvent(
  out hxKeyedEvent: IHandle;
  DesiredAccess: TKeyedEventAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Wake a thread waiting on a keyed event
function NtxReleaseKeyedEvent(
  [opt, Access(KEYEDEVENT_WAKE)] const hxKeyedEvent: IHandle;
  KeyValue: NativeUInt;
  const Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False
): TNtxStatus;

// Wait on a keyed event
function NtxWaitForKeyedEvent(
  [opt, Access(KEYEDEVENT_WAIT)] const hxKeyedEvent: IHandle;
  KeyValue: NativeUInt;
  const Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False
): TNtxStatus;

{ --------------------------------- Mutant ---------------------------------- }

// Create a new mutex
function NtxCreateMutant(
  out hxMutant: IHandle;
  InitialOwner: Boolean;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an existing mutex
function NtxOpenMutant(
  out hxMutant: IHandle;
  DesiredAccess: TMutantAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Release ownership over a mutex
function NtxReleaseMutant(
  [Access(0)] const hxMutant: IHandle;
  [out, opt] PreviousCount: PCardinal = nil
): TNtxStatus;

// Query a state of a mutex
function NtxQueryStateMutant(
  [Access(MUTANT_QUERY_STATE)] const hxMutant: IHandle;
  out BasicInfo: TMutantBasicInformation
): TNtxStatus;

// Query the owner of a mutex
function NtxQueryOwnerMutant(
  [Access(MUTANT_QUERY_STATE)] const hxMutant: IHandle;
  out Owner: TClientId
): TNtxStatus;

{ -------------------------------- Semaphore -------------------------------- }

// Create a new semaphore object
function NtxCreateSemaphore(
  out hxSemaphore: IHandle;
  InitialCount: Integer;
  MaximumCount: Integer;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an existing semaphore object
function NtxOpenSemaphore(
  out hxSemaphore: IHandle;
  DesiredAccess: TSemaphoreAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Release a semaphore by a count
function NtxReleaseSemaphore(
  [Access(SEMAPHORE_MODIFY_STATE)] const hxSemaphore: IHandle;
  ReleaseCount: Cardinal = 1;
  [out, opt] PreviousCount: PCardinal = nil
): TNtxStatus;

// Query basic information about a semaphore
function NtxQuerySemaphore(
  [Access(SEMAPHORE_QUERY_STATE)] const hxSemaphore: IHandle;
  out BasicInfo: TSemaphoreBasicInformation
): TNtxStatus;

{ ---------------------------------- Timer ---------------------------------- }

// Create a timer object
function NtxCreateTimer(
  out hxTimer: IHandle;
  TimerType: TTimerType;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an existing timer object
function NtxOpenTimer(
  out hxTimer: IHandle;
  DesiredAccess: TTimerAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Cancel a timer
function NtxCancelTimer(
  [Access(TIMER_MODIFY_STATE)] const hxTimer: IHandle;
  [out, opt] CurrentState: PBoolean
): TNtxStatus;

// Query basic information about a timer
function NtxQueryTimer(
  [Access(TIMER_QUERY_STATE)] const hxTimer: IHandle;
  out BasicInfo: TTimerBasicInformation
): TNtxStatus;

// Change timer coalescing settings
function NtxSetCoalesceTimer(
  [Access(TIMER_MODIFY_STATE)] const hxTimer: IHandle;
  const Info: TTimerSetCoalescableTimerInfo
): TNtxStatus;

{ ------------------------------ I/O Completion ------------------------------}

// Create an I/O completion object
function NtxCreateIoCompletion(
  out hxIoCompletion: IHandle;
  Count: Cardinal = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an I/O completion object by name
function NtxOpenIoCompletion(
  out hxIoCompletion: IHandle;
  DesiredAccess: TIoCompletionAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Queue an I/O completion packet
function NtxSetIoCompletion(
  [Access(IO_COMPLETION_MODIFY_STATE)] const hxIoCompletion: IHandle;
  [in, opt] KeyContext: Pointer;
  [in, opt] ApcContext: Pointer;
  IoStatus: NTSTATUS;
  IoStatusInformation: NativeUInt
): TNtxStatus;

// Wait for an I/O completion packet
function NtxRemoveIoCompletion(
  [Access(IO_COMPLETION_MODIFY_STATE)] const hxIoCompletion: IHandle;
  out Packet: TIoCompletionPacket;
  const Timeout: Int64 = NT_INFINITE
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpebteb, NtUtils.Errors, NtUtils.Objects,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ User-mode }

function RtlxEnterCriticalSection;
begin
  if not RtlEnterCriticalSection(CriticalSection).IsSuccess then
    Exit(nil);

  Result := Auto.Delay(
    procedure
    begin
      RtlLeaveCriticalSection(CriticalSection);
    end
  );
end;

function RtlxTryEnterCriticalSection;
begin
  Result := RtlTryEnterCriticalSection(CriticalSection);

  if not Result then
    Exit;

  Reverter := Auto.Delay(
    procedure
    begin
      RtlLeaveCriticalSection(CriticalSection);
    end
  );
end;

function RtlxAcquireResourceShared;
begin
  if not RtlAcquireResourceShared(Resource, True) then
    Exit(nil);

  Result := Auto.Delay(
    procedure
    begin
      RtlReleaseResource(Resource);
    end
  );
end;

function RtlxTryAcquireResourceShared;
begin
  Result := RtlAcquireResourceShared(Resource, False);

  if not Result then
    Exit;

  Reverter := Auto.Delay(
    procedure
    begin
      RtlReleaseResource(Resource);
    end
  );
end;

function RtlxAcquireResourceExclusive;
begin
  if not RtlAcquireResourceExclusive(Resource, True) then
    Exit(nil);

  Result := Auto.Delay(
    procedure
    begin
      RtlReleaseResource(Resource);
    end
  );
end;

function RtlxTryAcquireResourceExclusive;
begin
  Result := RtlAcquireResourceExclusive(Resource, False);

  if not Result then
    Exit;

  Reverter := Auto.Delay(
    procedure
    begin
      RtlReleaseResource(Resource);
    end
  );
end;

function RtlxAcquireSRWLockShared;
begin
  RtlAcquireSRWLockShared(SRWLock);

  Result := Auto.Delay(
    procedure
    begin
      RtlReleaseSRWLockShared(SRWLock);
    end
  );
end;

function RtlxTryAcquireSRWLockShared;
begin
  Result := RtlTryAcquireSRWLockShared(SRWLock);

  if not Result then
    Exit;

  Reverter := Auto.Delay(
    procedure
    begin
      RtlReleaseSRWLockShared(SRWLock);
    end
  );
end;

function RtlxAcquireSRWLockExclusive;
begin
  RtlAcquireSRWLockExclusive(SRWLock);

  Result := Auto.Delay(
    procedure
    begin
      RtlReleaseSRWLockExclusive(SRWLock);
    end
  );
end;

function RtlxTryAcquireSRWLockExclusive;
begin
  Result := RtlTryAcquireSRWLockExclusive(SRWLock);

  if not Result then
    Exit;

  Reverter := Auto.Delay(
    procedure
    begin
      RtlReleaseSRWLockExclusive(SRWLock);
    end
  );
end;

type
  TAcquiredRunOnce = class (TCustomAutoReleasable, IAcquiredRunOnce)
  private
    FRunOnce: PRtlRunOnce;
    FCompleted: Boolean;
  public
    procedure Complete(Context: Pointer);
    procedure Release; override;
    constructor Create(RunOnce: PRtlRunOnce);
  end;

procedure TAcquiredRunOnce.Complete;
begin
  Assert((NativeUInt(Context) and $3) = 0, 'Reserved bits in RunOnce context');
  FCompleted := RtlRunOnceComplete(FRunOnce, 0, Context).IsSuccess;
end;

constructor TAcquiredRunOnce.Create;
begin
  FRunOnce := RunOnce;
end;

procedure TAcquiredRunOnce.Release;
begin
  if not FCompleted then
    RtlRunOnceComplete(FRunOnce, RTL_RUN_ONCE_INIT_FAILED, nil);

  inherited;
end;

function RtlxRunOnceBegin;
begin
  Result := RtlRunOnceBeginInitialize(RunOnce, 0, Context) = STATUS_PENDING;

  if Result then
    AcquiredState := TAcquiredRunOnce.Create(RunOnce);
end;

{ Waits }

function NtxWaitForSingleObject;
begin
  Result.Location := 'NtWaitForSingleObject';
  Result.LastCall.Expects<TAccessMask>(SYNCHRONIZE);
  Result.Status := NtWaitForSingleObject(HandleOrDefault(hxObject), Alertable,
    TimeoutToLargeInteger(Timeout));
end;

function NtxWaitForMultipleObjects;
var
  HandleValues: TArray<THandle>;
  i: Integer;
begin
  SetLength(HandleValues, Length(Objects));

  for i := 0 to High(HandleValues) do
    HandleValues[i] := Objects[i].Handle;

  Result.Location := 'NtWaitForMultipleObjects';
  Result.LastCall.Expects<TAccessMask>(SYNCHRONIZE);
  Result.Status := NtWaitForMultipleObjects(Length(HandleValues), HandleValues,
    WaitType, Alertable, TimeoutToLargeInteger(Timeout));
end;

function NtxDelayExecution;
begin
  Result.Location := 'NtDelayExecution';
  Result.Status := NtDelayExecution(Alertable, PLargeInteger(@Timeout));
end;

function NtxMultiDelayExecution;
var
  EndInterruptTime: TLargeInteger;
  RemainingTimeout: Int64;
begin
  RemainingTimeout := Timeout;

  // Use the interrupt time to check for relative wait completion
  if (Timeout < 0) and (Timeout <> NT_INFINITE) then
    {$Q-}
    EndInterruptTime := USER_SHARED_DATA.InterruptTime.QuadPart - Timeout
    {$IFOPT Q+}{$DEFINE Q+}{$ENDIF}
  else
    EndInterruptTime := 0;

  while NtxDelayExecution(RemainingTimeout, True).SaveTo(Result).IsSuccess do
    case Result.Status of
      STATUS_USER_APC, STATUS_ALERTED:
      begin
        // Allow external conditions to break wait loops
        if Assigned(BreakCondition) and BreakCondition^ then
          Break;

        if (Timeout < 0) and (Timeout <> NT_INFINITE) then
        begin
          // Calculate the remaining relative wait time
          {$Q-}
          RemainingTimeout := USER_SHARED_DATA.InterruptTime.QuadPart -
            EndInterruptTime;
          {$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

          // Make sure we don't overflow into absolute waits
          if RemainingTimeout >= 0 then
            Break;
        end;

        Continue;
      end;
    else
      Break;
    end;
end;

{ Events }

function NtxCreateEvent;
var
  ObjAttr: PObjectAttributes;
  hEvent: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateEvent';
  Result.Status := NtCreateEvent(
    hEvent,
    AccessMaskOverride(EVENT_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    EventType,
    InitialState
  );

  if Result.IsSuccess then
    hxEvent := Auto.CaptureHandle(hEvent);
end;

function NtxOpenEvent;
var
  ObjAttr: PObjectAttributes;
  hEvent: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenEvent';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenEvent(hEvent, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxEvent := Auto.CaptureHandle(hEvent);
end;

function NtxSetEvent;
begin
  Result.Location := 'NtSetEvent';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_MODIFY_STATE);
  Result.Status := NtSetEvent(HandleOrDefault(hxEvent), PreviousState);
end;

function NtxSetEventBoostPriority;
begin
  Result.Location := 'NtSetEventBoostPriority';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_MODIFY_STATE);
  Result.Status := NtSetEventBoostPriority(HandleOrDefault(hxEvent))
end;

function NtxResetEvent;
begin
  Result.Location := 'NtResetEvent';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_MODIFY_STATE);
  Result.Status := NtResetEvent(HandleOrDefault(hxEvent), PreviousState);
end;

function NtxPulseEvent;
begin
  Result.Location := 'NtPulseEvent';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_MODIFY_STATE);
  Result.Status := NtPulseEvent(HandleOrDefault(hxEvent), PreviousState);
end;

function NtxQueryEvent;
begin
  Result.Location := 'NtQueryEvent';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_QUERY_STATE);
  Result.LastCall.UsesInfoClass(EventBasicInformation, icQuery);
  Result.Status := NtQueryEvent(HandleOrDefault(hxEvent), EventBasicInformation, @BasicInfo,
    SizeOf(BasicInfo), nil);
end;

{ Keyed events }

function NtxCreateKeyedEvent;
var
  ObjAttr: PObjectAttributes;
  hKeyedEvent: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateKeyedEvent';
  Result.Status := NtCreateKeyedEvent(
    hKeyedEvent,
    AccessMaskOverride(KEYEDEVENT_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    0
  );

  if Result.IsSuccess then
    hxKeyedEvent := Auto.CaptureHandle(hKeyedEvent);
end;

function NtxOpenKeyedEvent;
var
  ObjAttr: PObjectAttributes;
  hKeyedEvent: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenKeyedEvent';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenKeyedEvent(hKeyedEvent, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
     hxKeyedEvent := Auto.CaptureHandle(hKeyedEvent);
end;

function NtxReleaseKeyedEvent;
begin
  Result.Location := 'NtReleaseKeyedEvent';
  Result.LastCall.Expects<TKeyedEventAccessMask>(KEYEDEVENT_WAKE);
  Result.Status := NtReleaseKeyedEvent(HandleOrDefault(hxKeyedEvent), KeyValue,
    Alertable, TimeoutToLargeInteger(Timeout));
end;

function NtxWaitForKeyedEvent;
begin
  Result.Location := 'NtWaitForKeyedEvent';
  Result.LastCall.Expects<TKeyedEventAccessMask>(KEYEDEVENT_WAIT);
  Result.Status := NtWaitForKeyedEvent(HandleOrDefault(hxKeyedEvent), KeyValue,
    Alertable, TimeoutToLargeInteger(Timeout));
end;

{ Mutants }

function NtxCreateMutant;
var
  ObjAttr: PObjectAttributes;
  hMutant: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateMutant';
  Result.Status := NtCreateMutant(
    hMutant,
    AccessMaskOverride(MUTANT_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    InitialOwner
  );

  if Result.IsSuccess then
    hxMutant := Auto.CaptureHandle(hMutant);
end;

function NtxOpenMutant;
var
  ObjAttr: PObjectAttributes;
  hMutant: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenMutant';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenMutant(hMutant, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
     hxMutant := Auto.CaptureHandle(hMutant);
end;

function NtxReleaseMutant;
begin
  Result.Location := 'NtReleaseMutant';
  Result.Status := NtReleaseMutant(HandleOrDefault(hxMutant), PreviousCount);
end;

function NtxQueryStateMutant;
begin
  Result.Location := 'NtQueryMutant';
  Result.LastCall.Expects<TMutantAccessMask>(MUTANT_QUERY_STATE);
  Result.LastCall.UsesInfoClass(MutantBasicInformation, icQuery);
  Result.Status := NtQueryMutant(HandleOrDefault(hxMutant),
    MutantBasicInformation, @BasicInfo, SizeOf(BasicInfo), nil);
end;

function NtxQueryOwnerMutant;
begin
  Result.Location := 'NtQueryMutant';
  Result.LastCall.Expects<TMutantAccessMask>(MUTANT_QUERY_STATE);
  Result.LastCall.UsesInfoClass(MutantOwnerInformation, icQuery);
  Result.Status := NtQueryMutant(HandleOrDefault(hxMutant),
    MutantOwnerInformation, @Owner, SizeOf(Owner), nil);
end;

{ Semaphores }

function NtxCreateSemaphore;
var
  ObjAttr: PObjectAttributes;
  hSemaphore: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateSemaphore';
  Result.Status := NtCreateSemaphore(
    hSemaphore,
    AccessMaskOverride(SEMAPHORE_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    InitialCount,
    MaximumCount
  );

  if Result.IsSuccess then
    hxSemaphore := Auto.CaptureHandle(hSemaphore);
end;

function NtxOpenSemaphore;
var
  ObjAttr: PObjectAttributes;
  hSemaphore: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenSemaphore';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenSemaphore(hSemaphore, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxSemaphore := Auto.CaptureHandle(hSemaphore);
end;

function NtxReleaseSemaphore;
begin
  Result.Location := 'NtReleaseSemaphore';
  Result.LastCall.Expects<TSemaphoreAccessMask>(SEMAPHORE_MODIFY_STATE);
  Result.Status := NtReleaseSemaphore(HandleOrDefault(hxSemaphore),
    ReleaseCount, PreviousCount);
end;

function NtxQuerySemaphore;
begin
  Result.Location := 'NtQuerySemaphore';
  Result.LastCall.Expects<TSemaphoreAccessMask>(SEMAPHORE_QUERY_STATE);
  Result.LastCall.UsesInfoClass(SemaphoreBasicInformation, icQuery);
  Result.Status := NtQuerySemaphore(HandleOrDefault(hxSemaphore),
    SemaphoreBasicInformation, @BasicInfo, SizeOf(BasicInfo), nil);
end;

{ Timers }

function NtxCreateTimer;
var
  ObjAttr: PObjectAttributes;
  hTimer: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateTimer';
  Result.Status := NtCreateTimer(
    hTimer,
    AccessMaskOverride(TIMER_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    TimerType
  );

  if Result.IsSuccess then
    hxTimer := Auto.CaptureHandle(hTimer);
end;

function NtxOpenTimer;
var
  ObjAttr: PObjectAttributes;
  hTimer: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenTimer';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenTimer(hTimer, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxTimer := Auto.CaptureHandle(hTimer);
end;

function NtxSetCoalesceTimer;
begin
  Result.Location := 'NtSetTimerEx';
  Result.LastCall.Expects<TTimerAccessMask>(TIMER_MODIFY_STATE);
  Result.LastCall.UsesInfoClass(TimerSetCoalescableTimer, icSet);
  Result.Status := NtSetTimerEx(HandleOrDefault(hxTimer),
    TimerSetCoalescableTimer, @Info, SizeOf(Info));
end;

function NtxCancelTimer;
begin
  Result.Location := 'NtCancelTimer';
  Result.LastCall.Expects<TTimerAccessMask>(TIMER_MODIFY_STATE);
  Result.Status := NtCancelTimer(HandleOrDefault(hxTimer), CurrentState);
end;

function NtxQueryTimer;
begin
  Result.Location := 'NtQueryTimer';
  Result.LastCall.Expects<TTimerAccessMask>(TIMER_QUERY_STATE);
  Result.LastCall.UsesInfoClass(TimerBasicInformation, icQuery);
  Result.Status := NtQueryTimer(HandleOrDefault(hxTimer), TimerBasicInformation,
    @BasicInfo, SizeOf(BasicInfo), nil)
end;

{ I/O Completion }

function NtxCreateIoCompletion;
var
  ObjAttr: PObjectAttributes;
  hIoCompletion: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateIoCompletion';
  Result.Status := NtCreateIoCompletion(
    hIoCompletion,
    AccessMaskOverride(IO_COMPLETION_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    Count
  );

  if Result.IsSuccess then
    hxIoCompletion := Auto.CaptureHandle(hIoCompletion);
end;

function NtxOpenIoCompletion;
var
  ObjAttr: PObjectAttributes;
  hIoCompletion: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenIoCompletion';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenIoCompletion(hIoCompletion, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxIoCompletion := Auto.CaptureHandle(hIoCompletion);
end;

function NtxSetIoCompletion;
begin
  Result.Location := 'NtSetIoCompletion';
  Result.LastCall.Expects<TIoCompletionAccessMask>(IO_COMPLETION_MODIFY_STATE);
  Result.Status := NtSetIoCompletion(
    HandleOrDefault(hxIoCompletion),
    KeyContext,
    ApcContext,
    IoStatus,
    IoStatusInformation
  );
end;

function NtxRemoveIoCompletion;
begin
  Result.Location := 'NtRemoveIoCompletion';
  Result.LastCall.Expects<TIoCompletionAccessMask>(IO_COMPLETION_MODIFY_STATE);
  Result.Status := NtRemoveIoCompletion(
    HandleOrDefault(hxIoCompletion),
    Packet.KeyContext,
    Packet.ApcContext,
    Packet.IoStatusBlock,
    TimeoutToLargeInteger(Timeout)
  );
end;

end.
