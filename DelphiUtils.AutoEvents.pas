unit DelphiUtils.AutoEvents;

{
  This module add support for multi-subscriber events compatible with anonymous
  functions.
}

interface

uses
  DelphiUtils.AutoObjects, Ntapi.ntrtl, DelphiApi.Reflection;

type
  // A collection of weak interface references
  [ThreadSafe]
  TWeakArray<I : IInterface> = record
  private
    FEntries: TArray<Weak<IStrong<I>>>;
    FLock: TRtlSRWLock;
    function PreferredSizeMin(Count: Integer): Integer;
    function PreferredSizeMax(Count: Integer): Integer;
    [ThreadSafe(False)] function CompactLocked: Integer;
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
    [ThreadSafe(False)] class function FindIndexLocked(
      const Cookie: NativeUInt): Integer; static;
    class constructor Create;
  public
    // Save an interface reference and return a cookie
    class function Add(
       Obj: IInterface
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

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TWeakArray<I> }

function TWeakArray<I>.Add;
var
  FirstEmptyIndex: Integer;
  ResultAsIStrong: IStrong<I> absolute Result;
begin
  RtlAcquireSRWLockExclusive(@FLock);
  try
    // Compact and locate the first empty slot
    FirstEmptyIndex := CompactLocked;

    // Expand if the new item doesn't fit
    if FirstEmptyIndex > High(FEntries) then
      SetLength(FEntries, PreferredSizeMin(Succ(FirstEmptyIndex)));

    // Wrap the entry into a weak-safe strong reference, then save and return it
    ResultAsIStrong := Auto.RefStrong<I>(Entry);
    FEntries[FirstEmptyIndex] := ResultAsIStrong;
  finally
    RtlReleaseSRWLockExclusive(@FLock);
  end;
end;

procedure TWeakArray<I>.Compact;
begin
  if RtlTryAcquireSRWLockExclusive(@FLock) then
  try
    CompactLocked;
  finally
    RtlReleaseSRWLockExclusive(@FLock);
  end;
end;

function TWeakArray<I>.CompactLocked;
var
  StrongRef: IStrong<I>;
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
  StrongRef: IStrong<I>;
  i, Count: Integer;
  NeedsCompact: Boolean;
begin
  NeedsCompact := False;
  RtlAcquireSRWLockShared(@FLock);
  try
    SetLength(Result, Length(FEntries));
    Count := 0;

    // Make strong reference copies
    for i := 0 to High(Result) do
      if FEntries[i].Upgrade(StrongRef) then
      begin
        Result[Count] := StrongRef.Reference;
        Inc(Count);
      end;

    // Truncate the result if necessary
    if Length(Result) <> Count then
    begin
      SetLength(Result, Count);

      // If there are too many empty slots, try to compact
      // after releasing the lock
      NeedsCompact := Length(FEntries) > PreferredSizeMax(Count);
    end;
  finally
    RtlReleaseSRWLockShared(@FLock);
  end;

  if NeedsCompact then
    Compact;
end;

function TWeakArray<I>.HasAny;
var
  StrongRef: IStrong<I>;
  i: Integer;
begin
  Result := False;
  RtlAcquireSRWLockShared(@FLock);
  try
    for i := 0 to High(FEntries) do
      if FEntries[i].Upgrade(StrongRef) then
      begin
        Result := True;
        Break;
      end;
  finally
    RtlReleaseSRWLockShared(@FLock);
  end;
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

class constructor TInterfaceTable.Create;
begin
  // Use a magic starting number to lower the chance of collisions with
  // uninitialized data
  FNextCookie := $00DE1781;
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
        if not Assigned(AutoExceptionHanlder) or not
          AutoExceptionHanlder(E) then
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
        if not Assigned(AutoExceptionHanlder) or not
          AutoExceptionHanlder(E) then
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
        if not Assigned(AutoExceptionHanlder) or not
          AutoExceptionHanlder(E) then
          raise;
    end;
end;

function TAutoEvent<T1, T2>.Subscribe;
begin
  Result := FSubscribers.Add(Callback);
end;

end.
