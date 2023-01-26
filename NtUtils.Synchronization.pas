unit NtUtils.Synchronization;

{
  This module provides function for working with synchronization objects such
  as events, semaphors, and mutexes.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntexapi, Ntapi.ntobapi, Ntapi.ntioapi,
  NtUtils;

const
  // Infinite timeout for native wait functions
  NT_INFINITE = Ntapi.WinNt.NT_INFINITE;

type
  TIoCompletionPacket = Ntapi.ntioapi.TFileIoCompletionInformation;

{ ---------------------------------- Waits ---------------------------------- }

// Wait for an object to enter signaled state
function NtxWaitForSingleObject(
  [Access(SYNCHRONIZE)] hObject: THandle;
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

// Delay current thread's execution for a period of time
function NtxDelayExecution(
  const Timeout: Int64;
  Alertable: Boolean = False
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
  const ObjectName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Transition an event object to an alerted state
function NtxSetEvent(
  [Access(EVENT_MODIFY_STATE)] hEvent: THandle;
  [out, opt] PreviousState: PLongBool = nil
): TNtxStatus;

// Make an event object alerted and boost priority of the waiting thread
function NtxSetEventBoostPriority(
  [Access(EVENT_MODIFY_STATE)] hEvent: THandle
): TNtxStatus;

// Transition an event object to an non-alerted state
function NtxResetEvent(
  [Access(EVENT_MODIFY_STATE)] hEvent: THandle;
  [out, opt] PreviousState: PLongBool = nil
): TNtxStatus;

// Release one waiting thread without changing the state of the event
function NtxPulseEvent(
  [Access(EVENT_MODIFY_STATE)] hEvent: THandle;
  [out, opt] PreviousState: PLongBool = nil
): TNtxStatus;

// Query basic information about an event object
function NtxQueryEvent(
  [Access(EVENT_QUERY_STATE)] hEvent: THandle;
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
  const ObjectName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Wake a thread waiting on a keyed event
function NtxReleaseKeyedEvent(
  [opt, Access(KEYEDEVENT_WAKE)] hKeyedEvent: THandle;
  KeyValue: NativeUInt;
  const Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False
): TNtxStatus;

// Wait on a keyed event
function NtxWaitForKeyedEvent(
  [opt, Access(KEYEDEVENT_WAIT)] hKeyedEvent: THandle;
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
  const ObjectName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Release ownership over a mutex
function NtxReleaseMutant(
  [Access(0)] hMutant: THandle;
  [out, opt] PreviousCount: PCardinal = nil
): TNtxStatus;

// Query a state of a mutex
function NtxQueryStateMutant(
  [Access(MUTANT_QUERY_STATE)] hMutant: THandle;
  out BasicInfo: TMutantBasicInformation
): TNtxStatus;

// Query the owner of a mutex
function NtxQueryOwnerMutant(
  [Access(MUTANT_QUERY_STATE)] hMutant: THandle;
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
  const ObjectName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Release a sepamphore by a count
function NtxReleaseSemaphore(
  [Access(SEMAPHORE_MODIFY_STATE)] hSemaphore: THandle;
  ReleaseCount: Cardinal = 1;
  [out, opt] PreviousCount: PCardinal = nil
): TNtxStatus;

// Query basic information about a semaphore
function NtxQuerySemaphore(
  [Access(SEMAPHORE_QUERY_STATE)] hSemaphore: THandle;
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
  const ObjectName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Cancel a timer
function NtxCancelTimer(
  [Access(TIMER_MODIFY_STATE)] hTimer: THandle;
  [out, opt] CurrentState: PBoolean
): TNtxStatus;

// Query basic information about a timer
function NtxQueryTimer(
  [Access(TIMER_QUERY_STATE)] hTimer: THandle;
  out BasicInfo: TTimerBasicInformation
): TNtxStatus;

// Chenge timer coalescing settings
function NtxSetCoalesceTimer(
  [Access(TIMER_MODIFY_STATE)] hTimer: THandle;
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
  const ObjectName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Queue an I/O completion packet
function NtxSetIoCompletion(
  [Access(IO_COMPLETION_MODIFY_STATE)] hIoCompletion: THandle;
  [in, opt] KeyContext: Pointer;
  [in, opt] ApcContext: Pointer;
  IoStatus: NTSTATUS;
  IoStatusInformation: NativeUInt
): TNtxStatus;

// Wait for an I/O completion packet
function NtxRemoveIoCompletion(
  [Access(IO_COMPLETION_MODIFY_STATE)] hIoCompletion: THandle;
  out Packet: TIoCompletionPacket;
  const Timeout: Int64 = NT_INFINITE
): TNtxStatus;

implementation

uses
  NtUtils.Objects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Waits }

function NtxWaitForSingleObject;
begin
  Result.Location := 'NtWaitForSingleObject';
  Result.LastCall.Expects<TAccessMask>(SYNCHRONIZE);
  Result.Status := NtWaitForSingleObject(hObject, Alertable,
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

{ Events }

function NtxCreateEvent;
var
  hEvent: THandle;
begin
  Result.Location := 'NtCreateEvent';
  Result.Status := NtCreateEvent(
    hEvent,
    AccessMaskOverride(EVENT_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    EventType,
    InitialState
  );

  if Result.IsSuccess then
    hxEvent := Auto.CaptureHandle(hEvent);
end;

function NtxOpenEvent;
var
  hEvent: THandle;
begin
  Result.Location := 'NtOpenEvent';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenEvent(
    hEvent,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxEvent := Auto.CaptureHandle(hEvent);
end;

function NtxSetEvent;
begin
  Result.Location := 'NtSetEvent';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_MODIFY_STATE);
  Result.Status := NtSetEvent(hEvent, PreviousState);
end;

function NtxSetEventBoostPriority;
begin
  Result.Location := 'NtSetEventBoostPriority';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_MODIFY_STATE);
  Result.Status := NtSetEventBoostPriority(hEvent)
end;

function NtxResetEvent;
begin
  Result.Location := 'NtResetEvent';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_MODIFY_STATE);
  Result.Status := NtResetEvent(hEvent, PreviousState);
end;

function NtxPulseEvent;
begin
  Result.Location := 'NtPulseEvent';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_MODIFY_STATE);
  Result.Status := NtPulseEvent(hEvent, PreviousState);
end;

function NtxQueryEvent;
begin
  Result.Location := 'NtQueryEvent';
  Result.LastCall.Expects<TEventAccessMask>(EVENT_QUERY_STATE);
  Result.LastCall.UsesInfoClass(EventBasicInformation, icQuery);
  Result.Status := NtQueryEvent(hEvent, EventBasicInformation, @BasicInfo,
    SizeOf(BasicInfo), nil);
end;

{ Keyed events }

function NtxCreateKeyedEvent;
var
  hKeyedEvent: THandle;
begin
  Result.Location := 'NtCreateKeyedEvent';
  Result.Status := NtCreateKeyedEvent(
    hKeyedEvent,
    AccessMaskOverride(KEYEDEVENT_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    0
  );

  if Result.IsSuccess then
    hxKeyedEvent := Auto.CaptureHandle(hKeyedEvent);
end;

function NtxOpenKeyedEvent;
var
  hKeyedEvent: THandle;
begin
  Result.Location := 'NtOpenKeyedEvent';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenKeyedEvent(
    hKeyedEvent,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
     hxKeyedEvent := Auto.CaptureHandle(hKeyedEvent);
end;

function NtxReleaseKeyedEvent;
begin
  Result.Location := 'NtReleaseKeyedEvent';
  Result.LastCall.Expects<TKeyedEventAccessMask>(KEYEDEVENT_WAKE);
  Result.Status := NtReleaseKeyedEvent(hKeyedEvent, KeyValue, Alertable,
    TimeoutToLargeInteger(Timeout));
end;

function NtxWaitForKeyedEvent;
begin
  Result.Location := 'NtWaitForKeyedEvent';
  Result.LastCall.Expects<TKeyedEventAccessMask>(KEYEDEVENT_WAIT);
  Result.Status := NtWaitForKeyedEvent(hKeyedEvent, KeyValue, Alertable,
    TimeoutToLargeInteger(Timeout));
end;

{ Mutants }

function NtxCreateMutant;
var
  hMutant: THandle;
begin
  Result.Location := 'NtCreateMutant';
  Result.Status := NtCreateMutant(
    hMutant,
    AccessMaskOverride(MUTANT_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    InitialOwner
  );

  if Result.IsSuccess then
    hxMutant := Auto.CaptureHandle(hMutant);
end;

function NtxOpenMutant;
var
  hMutant: THandle;
begin
  Result.Location := 'NtOpenMutant';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenMutant(
    hMutant,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
     hxMutant := Auto.CaptureHandle(hMutant);
end;

function NtxReleaseMutant;
begin
  Result.Location := 'NtReleaseMutant';
  Result.Status := NtReleaseMutant(hMutant, PreviousCount);
end;

function NtxQueryStateMutant;
begin
  Result.Location := 'NtQueryMutant';
  Result.LastCall.Expects<TMutantAccessMask>(MUTANT_QUERY_STATE);
  Result.LastCall.UsesInfoClass(MutantBasicInformation, icQuery);
  Result.Status := NtQueryMutant(hMutant, MutantBasicInformation, @BasicInfo,
    SizeOf(BasicInfo), nil);
end;

function NtxQueryOwnerMutant;
begin
  Result.Location := 'NtQueryMutant';
  Result.LastCall.Expects<TMutantAccessMask>(MUTANT_QUERY_STATE);
  Result.LastCall.UsesInfoClass(MutantOwnerInformation, icQuery);
  Result.Status := NtQueryMutant(hMutant, MutantOwnerInformation, @Owner,
    SizeOf(Owner), nil);
end;

{ Semaphores }

function NtxCreateSemaphore;
var
  hSemaphore: THandle;
begin
  Result.Location := 'NtCreateSemaphore';
  Result.Status := NtCreateSemaphore(
    hSemaphore,
    AccessMaskOverride(SEMAPHORE_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    InitialCount,
    MaximumCount
  );

  if Result.IsSuccess then
    hxSemaphore := Auto.CaptureHandle(hSemaphore);
end;

function NtxOpenSemaphore;
var
  hSemaphore: THandle;
begin
  Result.Location := 'NtOpenSemaphore';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenSemaphore(
    hSemaphore,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxSemaphore := Auto.CaptureHandle(hSemaphore);
end;

function NtxReleaseSemaphore;
begin
  Result.Location := 'NtReleaseSemaphore';
  Result.LastCall.Expects<TSemaphoreAccessMask>(SEMAPHORE_MODIFY_STATE);
  Result.Status := NtReleaseSemaphore(hSemaphore, ReleaseCount, PreviousCount);
end;

function NtxQuerySemaphore;
begin
  Result.Location := 'NtQuerySemaphore';
  Result.LastCall.Expects<TSemaphoreAccessMask>(SEMAPHORE_QUERY_STATE);
  Result.LastCall.UsesInfoClass(SemaphoreBasicInformation, icQuery);
  Result.Status := NtQuerySemaphore(hSemaphore, SemaphoreBasicInformation,
    @BasicInfo, SizeOf(BasicInfo), nil);
end;

{ Timers }

function NtxCreateTimer;
var
  hTimer: THandle;
begin
  Result.Location := 'NtCreateTimer';
  Result.Status := NtCreateTimer(
    hTimer,
    AccessMaskOverride(TIMER_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    TimerType
  );

  if Result.IsSuccess then
    hxTimer := Auto.CaptureHandle(hTimer);
end;

function NtxOpenTimer;
var
  hTimer: THandle;
begin
  Result.Location := 'NtOpenTimer';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenTimer(
    hTimer,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxTimer := Auto.CaptureHandle(hTimer);
end;

function NtxSetCoalesceTimer;
begin
  Result.Location := 'NtSetTimerEx';
  Result.LastCall.Expects<TTimerAccessMask>(TIMER_MODIFY_STATE);
  Result.LastCall.UsesInfoClass(TimerSetCoalescableTimer, icSet);
  Result.Status := NtSetTimerEx(hTimer, TimerSetCoalescableTimer, @Info,
    SizeOf(Info));
end;

function NtxCancelTimer;
begin
  Result.Location := 'NtCancelTimer';
  Result.LastCall.Expects<TTimerAccessMask>(TIMER_MODIFY_STATE);
  Result.Status := NtCancelTimer(hTimer, CurrentState);
end;

function NtxQueryTimer;
begin
  Result.Location := 'NtQueryTimer';
  Result.LastCall.Expects<TTimerAccessMask>(TIMER_QUERY_STATE);
  Result.LastCall.UsesInfoClass(TimerBasicInformation, icQuery);
  Result.Status := NtQueryTimer(hTimer, TimerBasicInformation, @BasicInfo,
    SizeOf(BasicInfo), nil)
end;

{ I/O Completion }

function NtxCreateIoCompletion;
var
  hIoCompletion: THandle;
begin
  Result.Location := 'NtCreateIoCompletion';
  Result.Status := NtCreateIoCompletion(
    hIoCompletion,
    AccessMaskOverride(IO_COMPLETION_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    Count
  );

  if Result.IsSuccess then
    hxIoCompletion := Auto.CaptureHandle(hIoCompletion);
end;

function NtxOpenIoCompletion;
var
  hIoCompletion: THandle;
begin
  Result.Location := 'NtOpenIoCompletion';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenIoCompletion(
    hIoCompletion,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxIoCompletion := Auto.CaptureHandle(hIoCompletion);
end;

function NtxSetIoCompletion;
begin
  Result.Location := 'NtSetIoCompletion';
  Result.LastCall.Expects<TIoCompletionAccessMask>(IO_COMPLETION_MODIFY_STATE);
  Result.Status := NtSetIoCompletion(
    hIoCompletion,
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
    hIoCompletion,
    Packet.KeyContext,
    Packet.ApcContext,
    Packet.IoStatusBlock,
    TimeoutToLargeInteger(Timeout)
  );
end;

end.
