unit NtUiLib.HysteresisList;

{ This module provides a list with hysteresis which is useful for showing
  changes in snapshots of processes/handles/anything-else by highlighting
  additions and deletions for a specific duration (measured in iterations 
  of snapshotting). }

interface

uses
  System.SysUtils, System.Generics.Collections;

type 
  THysteresisItemState = (
    hisNew,
    hisExisting,
    hisDeleted
  );
  
  THysteresisItem<T> = class
  private
    TimeToLive: Integer;
    Found: Boolean;
    AddPending: Boolean;
    DeletePending: Boolean;
    FData: T;
    function GetState: THysteresisItemState;
    constructor Create(const NewData: T; TTL: Integer);
  public    
    property Data: T read FData;
    property State: THysteresisItemState read GetState;
  end;

  TComparer<T> = function (const A, B: T): Boolean;
  TItemEvent<T> = procedure (const Item: T; Index: Integer) of object;

  THysteresisList<T> = class(TEnumerable<THysteresisItem<T>>)
  private
    FItems: TList<THysteresisItem<T>>;
    Compare: TComparer<T>;
    TimeToLive: Integer;
    FOnAddStart, FOnAddFinish, FOnRemoveStart, FOnRemoveFinish: TItemEvent<T>;
    function GetItem(I: Integer): THysteresisItem<T>;
    function GetCount: Integer;
    procedure SetTimeToLive(Value: Integer);
  protected
    function DoGetEnumerator: TEnumerator<THysteresisItem<T>>; override;
  public
    constructor Create(Comparer: TComparer<T>; FadingInterval: Integer);
    destructor Destroy; override;
    procedure Update(const Snapshot: TArray<T>);
    property FadeInterval: Integer read TimeToLive write SetTimeToLive;
    property OnAddStart: TItemEvent<T> read FOnAddStart write FOnAddStart;
    property OnAddFinish: TItemEvent<T> read FOnAddFinish write FOnAddFinish;
    property OnRemoveStart: TItemEvent<T> read FOnRemoveStart write FOnRemoveStart;
    property OnRemoveFinish: TItemEvent<T> read FOnRemoveFinish write FOnRemoveFinish;
    property Count: Integer read GetCount;
    property Items[I: Integer]: THysteresisItem<T> read GetItem; default;
    function ToArray: TArray<THysteresisItem<T>>; override;
  end;

implementation

{ THysteresisItem<T> }

constructor THysteresisItem<T>.Create(const NewData: T; TTL: Integer);
begin
  TimeToLive := TTL;
  Found := True;
  AddPending := True;
  DeletePending := False;
  FData := NewData;
end;

function THysteresisItem<T>.GetState: THysteresisItemState;
begin
  if DeletePending then
    Result := hisDeleted
  else if AddPending then
    Result := hisNew
  else
    Result := hisExisting;
end;

{ THysteresisList<T> }

constructor THysteresisList<T>.Create(Comparer: TComparer<T>;
  FadingInterval: Integer);
begin
  if not Assigned(Comparer) then
    raise EArgumentNilException.Create('Hysteresis list requires a comparer.');

  Compare := Comparer;
  TimeToLive := FadingInterval;
  FItems := TList<THysteresisItem<T>>.Create;
end;

destructor THysteresisList<T>.Destroy;
var
  Item: THysteresisItem<T>;
begin
  for Item in FItems do
    Item.Free;

  FItems.Free;
  inherited;
end;

function THysteresisList<T>.DoGetEnumerator: TEnumerator<THysteresisItem<T>>;
begin
  Result := TList<THysteresisItem<T>>.TEnumerator.Create(FItems);
end;

function THysteresisList<T>.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function THysteresisList<T>.GetItem(I: Integer): THysteresisItem<T>;
begin
  Result := FItems[i];
end;

procedure THysteresisList<T>.SetTimeToLive(Value: Integer);
var
  Item: THysteresisItem<T>;
begin
  // Prolong/shorten fading for existing items
  for Item in FItems do
    Inc(Item.TimeToLive, Value - TimeToLive);

  TimeToLive := Value;
end;

function THysteresisList<T>.ToArray: TArray<THysteresisItem<T>>;
begin
  Result := FItems.ToArray;
end;

procedure THysteresisList<T>.Update(const Snapshot: TArray<T>);
var
  Item: THysteresisItem<T>;
  Found: Boolean;
  i, j: Integer;
begin
  // Mark all our items as unprocessed
  for Item in FItems do
    Item.Found := False;

  // Find additions
  for j := 0 to High(Snapshot) do
  begin
    // Search in our list excluding items marked for deletion since they
    // can't be revivied, only added again.
    Found := False;
    for i := 0 to FItems.Count - 1 do
      if not FItems[i].DeletePending and not FItems[i].Found
        and Compare(FItems[i].Data, Snapshot[j]) then
      begin
        Found := True;
        FItems[i].Found := True;
        Break;
      end;

    if not Found then
    begin
      // New data has arrived, add it
      FItems.Add(THysteresisItem<T>.Create(Snapshot[j], TimeToLive + 1));

      if Assigned(OnAddStart) then
        OnAddStart(Snapshot[j], i);
    end;
  end;

  // Find deletions (what's not in the snapshot anymore)
  for i := 0 to FItems.Count - 1 do
    if not FItems[i].DeletePending and not FItems[i].Found then
    begin
      FItems[i].DeletePending := True;
      FItems[i].TimeToLive := TimeToLive + 1;

      if Assigned(OnRemoveStart) then
        OnRemoveStart(FItems[i].Data, i);
    end;

  // Manage lifetime for alive items
  for Item in FItems do
    if Item.TimeToLive > 0 then
      Dec(Item.TimeToLive);

  // Complete item addition for those items that stay long enough
  for i := 0 to FItems.Count - 1 do
    if not FItems[i].DeletePending and FItems[i].AddPending and
      (FItems[i].TimeToLive <= 0) then
    begin
      FItems[i].AddPending := False;

      if Assigned(OnAddFinish) then
        OnAddFinish(FItems[i].Data, i);
    end;

  // Complete item deletion for those items that are gone for long enough
  for Item in FItems do
    if Item.DeletePending and (Item.TimeToLive <= 0) then
    begin
      if Assigned(OnRemoveFinish) then
        OnRemoveFinish(Item.Data, FItems.IndexOf(Item));

      Item.Free;
      FItems.Remove(Item);
    end;
end;

end.
