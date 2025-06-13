unit DelphiUtils.AutoEvents;

{
  This module add support for multi-subscriber events compatible with anonymous
  functions.
}

interface

uses
  DelphiUtils.AutoObjects, Ntapi.ntrtl, DelphiApi.Reflection;

var
  // A callback for handing exceptions that occur while delivering events.
  // The result indicates whether the exception was handled.
  AutoEventsExceptionHanlder: function (E: TObject): Boolean;

type
  IAutoReleasable = DelphiUtils.AutoObjects.IAutoReleasable;

  // A collection of weak interface references
  [ThreadSafe]
  TWeakArray<I : IInterface> = record
  private
    FEntries: TArray<Weak<I>>;
    FLock: TRtlSRWLock;
    function PreferredSizeMin(Count: Integer): Integer;
    function PreferredSizeMax(Count: Integer): Integer;
    [ThreadSafe(False)] function CompactWorker: Integer;
  public
    function Entries: TArray<I>;
    function Add(const Entry: I): IAutoReleasable;
    function HasAny: Boolean;
    procedure Compact;
  end;

  // A shared storage for interface references
  [ThreadSafe]
  TInterfaceTable = class abstract
  private
    type TInterfaceTableEntry = record
      Cookie: NativeUInt;
      Data: IInterface;
    end;
    class var FEntries: TArray<TInterfaceTableEntry>;
    class var FLock: TRtlSRWLock;
    class var FNextCookie: NativeUInt;
    class function FindIndexLocked(const Cookie: NativeUInt): Integer; static;
  public
    // Save an interface reference and return a cookie
    class function Add(
      const Obj: IInterface
    ): NativeUInt; static;

    // Locate an interface refernce
    class function Find(
      const Cookie: NativeUInt;
      const IID: TGuid;
      out Obj;
      Remove: Boolean = False
    ): Boolean; static;

    // Delete an interface refernce
    class function Remove(
      const Cookie: NativeUInt
    ): Boolean; static;
  end;

  TEventCallback = reference to procedure;

  TCustomInvoker = reference to procedure (
    Callback: TEventCallback
  );

  // An automatic multi-subscriber event with no parameters
  [ThreadSafe]
  TAutoEvent = record
  private
    FSubscribers: TWeakArray<TEventCallback>;
  public
    function Subscribe(Callback: TEventCallback): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke;
  end;

  TEventCallback<T> = reference to procedure (const Parameter: T);

  TCustomInvoker<T> = reference to procedure (
    Callback: TEventCallback<T>;
    const Parameter: T
  );

  // An automatic multi-subscriber event with one parameter
  [ThreadSafe]
  TAutoEvent<T> = record
  private
    FSubscribers: TWeakArray<TEventCallback<T>>;
  public
    function Subscribe(Callback: TEventCallback<T>): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke(const Parameter: T);
  end;

  TEventCallback<T1, T2> = reference to procedure (
    const Parameter1: T1;
    const Parameter2: T2
  );

  TCustomInvoker<T1, T2> = reference to procedure (
    Callback: TEventCallback<T1, T2>;
    const Parameter1: T1;
    const Parameter2: T2
  );

  // An automatic multi-subscriber event with two parameters
  [ThreadSafe]
  TAutoEvent<T1, T2> = record
  private
    FSubscribers: TWeakArray<TEventCallback<T1, T2>>;
  public
    function Subscribe(Callback: TEventCallback<T1, T2>): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke(const Parameter1: T1; const Parameter2: T2);
  end;

implementation

uses
  NtUtils.Synchronization;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TWeakArray<I> }

function TWeakArray<I>.Add;
var
  FirstEmptyIndex: Integer;
  LockReverter: IAutoReleasable;
begin
  LockReverter := RtlxAcquireSRWLockExclusive(@FLock);

  // Compact and locate the first empty slot
  FirstEmptyIndex := CompactWorker;

  // Expand if the new item doesn't fit
  if FirstEmptyIndex > High(FEntries) then
    SetLength(FEntries, PreferredSizeMin(Succ(FirstEmptyIndex)));

  // Save a weak reference and return a wrapper with a strong reference
  FEntries[FirstEmptyIndex] := Entry;
  Result := Auto.Copy<I>(Entry);
end;

procedure TWeakArray<I>.Compact;
var
  LockReverter: IAutoReleasable;
begin
  if RtlxTryAcquireSRWLockExclusive(@FLock, LockReverter) then
    CompactWorker;
end;

function TWeakArray<I>.CompactWorker;
var
  StrongRef: I;
  j: Integer;
begin
  // Move occupied slots into a continuous block preserving order
  Result := 0;
  for j := 0 to High(FEntries) do
    if FEntries[j].Upgrade(StrongRef) then
    begin
      if j <> Result then
        FEntries[Result] := StrongRef;

      Inc(Result);
    end;

  // Trim the array when there are too many empty slots
  if Length(FEntries) > PreferredSizeMax(Succ(Result)) then
    SetLength(FEntries, PreferredSizeMax(Succ(Result)));
end;

function TWeakArray<I>.Entries;
var
  i, Count: Integer;
  LockReverter: IAutoReleasable;
begin
  LockReverter := RtlxAcquireSRWLockShared(@FLock);
  SetLength(Result, Length(FEntries));
  Count := 0;

  // Make strong reference copies
  for i := 0 to High(Result) do
    if FEntries[i].Upgrade(Result[Count]) then
      Inc(Count);

  // Truncate the result if necessary
  if Length(Result) <> Count then
  begin
    SetLength(Result, Count);

    // If there are too many empty slots, release our lock and try to compact
    if Length(FEntries) > PreferredSizeMax(Count) then
    begin
      LockReverter := nil;
      Compact;
    end;
  end;
end;

function TWeakArray<I>.HasAny;
var
  StrongRef: I;
  i: Integer;
  LockReverter: IAutoReleasable;
begin
  LockReverter := RtlxAcquireSRWLockShared(@FLock);

  for i := 0 to High(FEntries) do
    if FEntries[i].Upgrade(StrongRef) then
      Exit(True);

  Result := False;
end;

function TWeakArray<I>.PreferredSizeMax;
begin
  Result := Count + Count div 3 + 6;
end;

function TWeakArray<I>.PreferredSizeMin;
begin
  Result := Count + Count div 8 + 1;
end;

{ TInterfaceTable }

class function TInterfaceTable.Add;
begin
  RtlAcquireSRWLockExclusive(@FLock);
  try
    Inc(FNextCookie);
    Result := FNextCookie;
    SetLength(FEntries, Succ(Length(FEntries)));
    FEntries[High(FEntries)].Cookie := Result;
    FEntries[High(FEntries)].Data := Obj;
  finally
    RtlReleaseSRWLockExclusive(@FLock);
  end;
end;

class function TInterfaceTable.Find;
var
  Index: Integer;
  Entry: IInterface;
begin
  if Remove then
    RtlAcquireSRWLockExclusive(@FLock)
  else
    RtlAcquireSRWLockShared(@FLock);

  try
    Index := FindIndexLocked(Cookie);

    if Index >= 0 then
    begin
      Entry := FEntries[Index].Data;

      if Remove then
        Delete(FEntries, Index, 1);
    end;
  finally
    if Remove then
      RtlReleaseSRWLockExclusive(@FLock)
    else
      RtlReleaseSRWLockShared(@FLock);
  end;

  Result := Assigned(Entry) and (Entry.QueryInterface(IID, Obj) = 0);
end;

class function TInterfaceTable.FindIndexLocked;
var
  MinIndex, MaxIndex: Integer;
begin
  if Length(FEntries) <= 0 then
    Exit(-1);

  MinIndex := 0;
  MaxIndex := High(FEntries);

  repeat
    Result := (MaxIndex + MinIndex) div 2;

    if Cookie > FEntries[Result].Cookie then
      MinIndex := Result + 1
    else if Cookie < FEntries[Result].Cookie then
      MaxIndex := Result - 1
    else
      Exit;

    if MinIndex > MaxIndex then
      Exit(-1);

  until False;
end;

class function TInterfaceTable.Remove;
var
  Index: Integer;
begin
  RtlAcquireSRWLockExclusive(@FLock);
  try
    Index := FindIndexLocked(Cookie);
    Result := Index >= 0;

    if Result then
      Delete(FEntries, Index, 1);
  finally
    RtlReleaseSRWLockExclusive(@FLock);
  end;
end;

{ TAutoEvent }

function TAutoEvent.HasSubscribers;
begin
  Result := FSubscribers.HasAny;
end;

procedure TAutoEvent.Invoke;
var
  Callback: TEventCallback;
begin
  for Callback in FSubscribers.Entries do
    try
      Callback;
    except
      on E: TObject do
        if not Assigned(AutoEventsExceptionHanlder) or not
          AutoEventsExceptionHanlder(E) then
          raise;
    end;
end;

function TAutoEvent.Subscribe;
begin
  Result := FSubscribers.Add(Callback);
end;

{ TAutoEvent<T> }

function TAutoEvent<T>.HasSubscribers;
begin
  Result := FSubscribers.HasAny;
end;

procedure TAutoEvent<T>.Invoke;
var
  Callback: TEventCallback<T>;
begin
  for Callback in FSubscribers.Entries do
    try
      Callback(Parameter);
    except
      on E: TObject do
        if not Assigned(AutoEventsExceptionHanlder) or not
          AutoEventsExceptionHanlder(E) then
          raise;
    end;
end;

function TAutoEvent<T>.Subscribe;
begin
  Result := FSubscribers.Add(Callback);
end;

{ TAutoEvent<T1, T2> }

function TAutoEvent<T1, T2>.HasSubscribers;
begin
  Result := FSubscribers.HasAny;
end;

procedure TAutoEvent<T1, T2>.Invoke;
var
  Callback: TEventCallback<T1, T2>;
begin
  for Callback in FSubscribers.Entries do
    try
      Callback(Parameter1, Parameter2);
    except
      on E: TObject do
        if not Assigned(AutoEventsExceptionHanlder) or not
          AutoEventsExceptionHanlder(E) then
          raise;
    end;
end;

function TAutoEvent<T1, T2>.Subscribe;
begin
  Result := FSubscribers.Add(Callback);
end;

end.
