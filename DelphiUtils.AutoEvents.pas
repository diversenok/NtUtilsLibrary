unit DelphiUtils.AutoEvents;

{
  This module add support for multi-subscriber events compatible with anonymous
  functions.
}

interface

uses
  DelphiUtils.AutoObjects;

type
  IAutoReleasable = DelphiUtils.AutoObjects.IAutoReleasable;

  // A collection of weak interface references
  TWeakArray<I : IInterface> = record
    Entries: TArray<Weak<I>>;
    function Add(const Entry: I): IAutoReleasable;
    procedure RemoveEmpty;
    function HasAny: Boolean;
  end;

  TEventCallback = reference to procedure;

  TCustomInvoker = reference to procedure (
    Callback: TEventCallback
  );

  // An automatic multi-subscriber event with no parameters
  TAutoEvent = record
  private
    FSubscribers: TWeakArray<TEventCallback>;
    FCustomInvoker: TCustomInvoker;
  public
    function Subscribe(Callback: TEventCallback): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke;
    procedure SetCustomInvoker(Invoker: TCustomInvoker);
  end;

  TEventCallback<T> = reference to procedure (const Parameter: T);

  TCustomInvoker<T> = reference to procedure (
    Callback: TEventCallback<T>;
    const Parameter: T
  );

  // An automatic multi-subscriber event with one parameter
  TAutoEvent<T> = record
  private
    FSubscribers: TWeakArray<TEventCallback<T>>;
    FCustomInvoker: TCustomInvoker<T>;
  public
    function Subscribe(Callback: TEventCallback<T>): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke(const Parameter: T);
    procedure SetCustomInvoker(Invoker: TCustomInvoker<T>);
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
  TAutoEvent<T1, T2> = record
  private
    FSubscribers: TWeakArray<TEventCallback<T1, T2>>;
    FCustomInvoker: TCustomInvoker<T1, T2>;
  public
    function Subscribe(Callback: TEventCallback<T1, T2>): IAutoReleasable;
    function HasSubscribers: Boolean;
    procedure Invoke(const Parameter1: T1; const Parameter2: T2);
    procedure SetCustomInvoker(Invoker: TCustomInvoker<T1, T2>);
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TWeakArray<I> }

function TWeakArray<I>.Add;
begin
  SetLength(Entries, Length(Entries) + 1);
  Entries[High(Entries)] := Entry;
  Result := Auto.Copy<I>(Entry);
end;

function TWeakArray<I>.HasAny;
var
  StrongRef: I;
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Entries[i].Upgrade(StrongRef) then
      Exit(True);

  Result := False;
end;

procedure TWeakArray<I>.RemoveEmpty;
var
  StrongRef: I;
  i, j: Integer;
begin
  j := 0;
  for i := 0 to High(Entries) do
    if Entries[i].Upgrade(StrongRef) then
    begin
      if i <> j then
        Entries[j] := StrongRef;

      Inc(j);
    end;

  SetLength(Entries, j);
end;

{ TAutoEvent }

function TAutoEvent.HasSubscribers;
begin
  Result := FSubscribers.HasAny;
end;

procedure TAutoEvent.Invoke;
var
  Callback: TEventCallback;
  i: Integer;
begin
  FSubscribers.RemoveEmpty;

  for i := 0 to High(FSubscribers.Entries) do
    if FSubscribers.Entries[i].Upgrade(Callback) then
      if Assigned(FCustomInvoker) then
        FCustomInvoker(Callback)
      else
        Callback;
end;

procedure TAutoEvent.SetCustomInvoker;
begin
  FCustomInvoker := Invoker;
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
  i: Integer;
begin
  FSubscribers.RemoveEmpty;

  for i := 0 to High(FSubscribers.Entries) do
    if FSubscribers.Entries[i].Upgrade(Callback) then
      if Assigned(FCustomInvoker) then
        FCustomInvoker(Callback, Parameter)
      else
        Callback(Parameter);
end;

procedure TAutoEvent<T>.SetCustomInvoker;
begin
  FCustomInvoker := Invoker;
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
  i: Integer;
begin
  FSubscribers.RemoveEmpty;

  for i := 0 to High(FSubscribers.Entries) do
    if FSubscribers.Entries[i].Upgrade(Callback) then
      if Assigned(FCustomInvoker) then
        FCustomInvoker(Callback, Parameter1, Parameter2)
      else
        Callback(Parameter1, Parameter2);
end;

procedure TAutoEvent<T1, T2>.SetCustomInvoker;
begin
  FCustomInvoker := Invoker;
end;

function TAutoEvent<T1, T2>.Subscribe;
begin
  Result := FSubscribers.Add(Callback);
end;

end.
