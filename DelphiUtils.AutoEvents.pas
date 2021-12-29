unit DelphiUtils.AutoEvents;

{
  This module add support for multi-subscriber events compatible with anonymous
  functions.
}

interface

uses
  DelphiUtils.AutoObjects;

type
  // A collection of weak interface references
  TWeakArray<I : IInterface> = record
    Entries: TArray<Weak<I>>;
    function Add(const Entry: I): IAutoReleasable;
    procedure RemoveEmpty;
    function HasAny: Boolean;
  end;

  TEventCallback = reference to procedure;

  // An automatic multi-subscriber event with no parameters
  TAutoEvent = record
  private
    Subscribers: TWeakArray<TEventCallback>;
  public
    function Subscribe(const Callback: TEventCallback): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke;
  end;

  TEventCallback<T> = reference to procedure (const Param: T);

  // An automatic multi-subscriber event with one parameter
  TAutoEvent<T> = record
  private
    Subscribers: TWeakArray<TEventCallback<T>>;
  public
    function Subscribe(const Callback: TEventCallback<T>): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke(const Parameter: T);
  end;

  TEventCallback<T1, T2> = reference to procedure (const A: T1; const B: T2);

  // An automatic multi-subscriber event with two parameters
  TAutoEvent<T1, T2> = record
  private
    Subscribers: TWeakArray<TEventCallback<T1, T2>>;
  public
    function Subscribe(const Callback: TEventCallback<T1, T2>): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke(const Parameter1: T1; const Parameter2: T2);
  end;

implementation

{ TWeakArray<I> }

function TWeakArray<I>.Add;
begin
  SetLength(Entries, Length(Entries) + 1);
  Entries[High(Entries)] := Entry;
  Result := Auto.Copy<I>(Entry);
end;

function TWeakArray<I>.HasAny;
var
  StongRef: I;
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Entries[i].Upgrade(StongRef) then
      Exit(True);

  Result := False;
end;

procedure TWeakArray<I>.RemoveEmpty;
var
  StongRef: I;
  i, j: Integer;
begin
  j := 0;
  for i := 0 to High(Entries) do
    if Entries[i].Upgrade(StongRef) then
    begin
      if i <> j then
        Entries[j] := StongRef;

      Inc(j);
    end;

  SetLength(Entries, j);
end;

{ TAutoEvent }

function TAutoEvent.HasSubscribers;
begin
  Result := Subscribers.HasAny;
end;

procedure TAutoEvent.Invoke;
var
  Callback: TEventCallback;
  i: Integer;
begin
  Subscribers.RemoveEmpty;

  for i := 0 to High(Subscribers.Entries) do
    if Subscribers.Entries[i].Upgrade(Callback) then
      Callback;
end;

function TAutoEvent.Subscribe;
begin
  Result := Subscribers.Add(Callback);
end;

{ TAutoEvent<T> }

function TAutoEvent<T>.HasSubscribers;
begin
  Result := Subscribers.HasAny;
end;

procedure TAutoEvent<T>.Invoke;
var
  Callback: TEventCallback<T>;
  i: Integer;
begin
  Subscribers.RemoveEmpty;

  for i := 0 to High(Subscribers.Entries) do
    if Subscribers.Entries[i].Upgrade(Callback) then
      Callback(Parameter);
end;

function TAutoEvent<T>.Subscribe;
begin
  Result := Subscribers.Add(Callback);
end;

{ TAutoEvent<T1, T2> }

function TAutoEvent<T1, T2>.HasSubscribers;
begin
  Result := Subscribers.HasAny;
end;

procedure TAutoEvent<T1, T2>.Invoke;
var
  Callback: TEventCallback<T1, T2>;
  i: Integer;
begin
  Subscribers.RemoveEmpty;

  for i := 0 to High(Subscribers.Entries) do
    if Subscribers.Entries[i].Upgrade(Callback) then
      Callback(Parameter1, Parameter2);
end;

function TAutoEvent<T1, T2>.Subscribe;
begin
  Result := Subscribers.Add(Callback);
end;

end.
