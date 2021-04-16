unit NtUtils.Synchronization;

{
  This module provides function for working with synchronization objects such
  as events, semaphors, and mutexes.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntexapi, Ntapi.ntobapi, NtUtils;

{ ---------------------------------- Waits ---------------------------------- }

// Wait for an object to enter signaled state
function NtxWaitForSingleObject(
  hObject: THandle;
  Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False
): TNtxStatus;

// Wait for any/all objects to enter a signaled state
function NtxWaitForMultipleObjects(
  Objects: TArray<THandle>;
  WaitType: TWaitType;
  Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False): TNtxStatus;

// Delay current thread's execution for a period of time
function NtxDelayExecution(
  Timeout: Int64;
  Alertable: Boolean = False
): TNtxStatus;

{ ---------------------------------- Event ---------------------------------- }

// Create a new event object
function NtxCreateEvent(
  out hxEvent: IHandle;
  EventType: TEventType;
  InitialState: Boolean;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an existing event object
function NtxOpenEvent(
  out hxEvent: IHandle;
  DesiredAccess: TEventAccessMask;
  ObjectName: String;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Transition an event object to an alerted state
function NtxSetEvent(
  hEvent: THandle;
  PreviousState: PLongBool = nil
): TNtxStatus;

// Make an event object alerted and boost priority of the waiting thread
function NtxSetEventBoostPriority(
  hEvent:  THandle
): TNtxStatus;

// Transition an event object to an non-alerted state
function NtxResetEvent(
  hEvent: THandle;
  PreviousState: PLongBool = nil
): TNtxStatus;

// Release one waiting thread without changing the state of the event
function NtxPulseEvent(
  hEvent: THandle;
  PreviousState: PLongBool = nil
): TNtxStatus;

// Query basic information about an event object
function NtxQueryEvent(
  hEvent: THandle;
  out BasicInfo: TEventBasicInformation
): TNtxStatus;

{ --------------------------------- Mutant ---------------------------------- }

// Create a new mutex
function NtxCreateMutant(
  out hxMutant: IHandle;
  InitialOwner: Boolean;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an existing mutex
function NtxOpenMutant(
  out hxMutant: IHandle;
  DesiredAccess: TMutantAccessMask;
  ObjectName: String;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Release ownership over a mutex
function NtxReleaseMutant(
  hMutant: THandle;
  PreviousCount: PCardinal = nil
): TNtxStatus;

// Query a state of a mutex
function NtxQueryStateMutant(
  hMutant: THandle;
  out BasicInfo: TMutantBasicInformation
): TNtxStatus;

// Query the owner of a mutex
function NtxQueryOwnerMutant(
  hMutant: THandle;
  out Owner: TClientId
): TNtxStatus;

{ -------------------------------- Semaphore -------------------------------- }

// Create a new semaphore object
function NtxCreateSemaphore(
  out hxSemaphore: IHandle;
  InitialCount: Integer;
  MaximumCount: Integer;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an existing semaphore object
function NtxOpenSemaphore(
  out hxSemaphore: IHandle;
  DesiredAccess: TSemaphoreAccessMask;
  ObjectName: String;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Release a sepamphore by a count
function NtxReleaseSemaphore(
  hSemaphore: THandle;
  ReleaseCount: Cardinal = 1;
  PreviousCount: PCardinal = nil
): TNtxStatus;

// Query basic information about a semaphore
function NtxQuerySemaphore(
  hSemaphore: THandle;
  out BasicInfo: TSemaphoreBasicInformation
): TNtxStatus;

{ ---------------------------------- Timer ---------------------------------- }

// Create a timer object
function NtxCreateTimer(
  out hxTimer: IHandle;
  TimerType: TTimerType;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an existing timer object
function NtxOpenTimer(
  out hxTimer: IHandle;
  DesiredAccess: TTimerAccessMask;
  ObjectName: String;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Cancel a timer
function NtxCancelTimer(
  hTimer: THandle;
  CurrentState: PBoolean
): TNtxStatus;

// Query basic information about a timer
function NtxQueryTimer(
  hTimer: THandle;
  out BasicInfo: TTimerBasicInformation
): TNtxStatus;

// Chenge timer coalescing settings
function NtxSetCoalesceTimer(
  hTimer: THandle;
  const Info: TTimerSetCoalescableTimerInfo
): TNtxStatus;


implementation

uses
  NtUtils.Objects;

{ Waits }

function NtxWaitForSingleObject;
begin
  Result.Location := 'NtWaitForSingleObject';
  Result.LastCall.Expects<TAccessMask>(SYNCHRONIZE);
  Result.Status := NtWaitForSingleObject(hObject, Alertable,
    TimeoutToLargeInteger(Timeout));
end;

function NtxWaitForMultipleObjects;
begin
  Result.Location := 'NtWaitForMultipleObjects';
  Result.LastCall.Expects<TAccessMask>(SYNCHRONIZE);
  Result.Status := NtWaitForMultipleObjects(Length(Objects), Objects,
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
    hxEvent := TAutoHandle.Capture(hEvent);
end;

function NtxOpenEvent;
var
  hEvent: THandle;
begin
  Result.Location := 'NtOpenEvent';
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.Status := NtOpenEvent(
    hEvent,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxEvent := TAutoHandle.Capture(hEvent);
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
  Result.LastCall.AttachInfoClass(EventBasicInformation);
  Result.Status := NtQueryEvent(hEvent, EventBasicInformation, @BasicInfo,
    SizeOf(BasicInfo), nil);
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
    hxMutant := TAutoHandle.Capture(hMutant);
end;

function NtxOpenMutant;
var
  hMutant: THandle;
begin
  Result.Location := 'NtOpenMutant';
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.Status := NtOpenMutant(
    hMutant,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
     hxMutant := TAutoHandle.Capture(hMutant);
end;

function NtxReleaseMutant;
begin
  Result.Location := 'NtReleaseMutant';
  Result.LastCall.Expects<TMutantAccessMask>(MUTANT_QUERY_STATE);
  Result.Status := NtReleaseMutant(hMutant, PreviousCount)
end;

function NtxQueryStateMutant;
begin
  Result.Location := 'NtQueryMutant';
  Result.LastCall.Expects<TMutantAccessMask>(MUTANT_QUERY_STATE);
  Result.LastCall.AttachInfoClass(MutantBasicInformation);
  Result.Status := NtQueryMutant(hMutant, MutantBasicInformation, @BasicInfo,
    SizeOf(BasicInfo), nil);
end;

function NtxQueryOwnerMutant;
begin
  Result.Location := 'NtQueryMutant';
  Result.LastCall.Expects<TMutantAccessMask>(MUTANT_QUERY_STATE);
  Result.LastCall.AttachInfoClass(MutantOwnerInformation);
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
    hxSemaphore := TAutoHandle.Capture(hSemaphore);
end;

function NtxOpenSemaphore;
var
  hSemaphore: THandle;
begin
  Result.Location := 'NtOpenSemaphore';
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.Status := NtOpenSemaphore(
    hSemaphore,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxSemaphore := TAutoHandle.Capture(hSemaphore);
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
  Result.LastCall.AttachInfoClass(SemaphoreBasicInformation);
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
    hxTimer := TAutoHandle.Capture(hTimer);
end;

function NtxOpenTimer;
var
  hTimer: THandle;
begin
  Result.Location := 'NtOpenTimer';
  Result.LastCall.AttachAccess(DesiredAccess);
  Result.Status := NtOpenTimer(
    hTimer,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxTimer := TAutoHandle.Capture(hTimer);
end;

function NtxSetCoalesceTimer;
begin
  Result.Location := 'NtSetTimerEx';
  Result.LastCall.Expects<TTimerAccessMask>(TIMER_MODIFY_STATE);
  Result.LastCall.AttachInfoClass(TimerSetCoalescableTimer);
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
  Result.LastCall.AttachInfoClass(TimerBasicInformation);
  Result.Status := NtQueryTimer(hTimer, TimerBasicInformation, @BasicInfo,
    SizeOf(BasicInfo), nil)
end;

end.
