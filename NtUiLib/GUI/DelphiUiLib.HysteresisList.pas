unit DelphiUiLib.HysteresisList;

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

  THysteresisDelta = (
    hdAddStart,
    hdAddFinish,
    hdRemoveStart,
    hdRemoveFinish
  );

  THysteresisDeltas = set of THysteresisDelta;
  
  THysteresisItem<T> = class
  private
    TimeToLive: Integer;
    Found: Boolean;
    AddPending: Boolean;
    DeletePending: Boolean;
    FData: T;
    Delta: THysteresisDeltas;
    function GetState: THysteresisItemState;
    constructor Create(const NewData: T; TTL: Integer);
  public    
    property Data: T read FData;
    property State: THysteresisItemState read GetState;
    property BelongsToDelta: THysteresisDeltas read Delta;
  end;

  TComparer<T> = function (const A, B: T): Boolean;
  TItemEvent<T> = procedure (const Item: T; Index: Integer) of object;

  THysteresisList<T> = class(TEnumerable<THysteresisItem<T>>)
  private
    FItems: TList<THysteresisItem<T>>;
    Compare, FullCompare: TComparer<T>;
    TimeToLive: Integer;
    FOnUpdateStart, FOnUpdateFinish: TProc;
    FOnAddStart, FOnAddFinish, FOnRemoveStart, FOnRemoveFinish, FItemModified: TItemEvent<T>;
    FAddStartDelta, FAddFinishDelta, FRemoveStartDelta, FRemoveFinishDelta: Integer;
    function GetItem(I: Integer): THysteresisItem<T>;
    function GetCount: Integer;
    procedure SetTimeToLive(Value: Integer);
  protected
    function DoGetEnumerator: TEnumerator<THysteresisItem<T>>; override;
  public
    constructor Create(Comparer: TComparer<T>; FadingInterval: Integer;
      FullComparer: TComparer<T> = nil);
    destructor Destroy; override;
    procedure Update(const Snapshot: TArray<T>);
    property FadeInterval: Integer read TimeToLive write SetTimeToLive;
    property OnUpdateStart: TProc read FOnUpdateStart write FOnUpdateStart;
    property OnUpdateFinish: TProc read FOnUpdateFinish write FOnUpdateFinish;
    property OnAddStart: TItemEvent<T> read FOnAddStart write FOnAddStart;
    property OnAddFinish: TItemEvent<T> read FOnAddFinish write FOnAddFinish;
    property OnRemoveStart: TItemEvent<T> read FOnRemoveStart write FOnRemoveStart;
    property OnRemoveFinish: TItemEvent<T> read FOnRemoveFinish write FOnRemoveFinish;
    property OnItemModified: TItemEvent<T> read FItemModified write FItemModified;
    property AddStartDelta: Integer read FAddStartDelta;
    property AddFinishDelta: Integer read FAddFinishDelta;
    property RemoveStartDelta: Integer read FRemoveStartDelta;
    property RemoveFinishDelta: Integer read FRemoveFinishDelta;
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
  Delta := [hdAddStart];
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
  FadingInterval: Integer; FullComparer: TComparer<T>);
begin
  if not Assigned(Comparer) then
    raise EArgumentNilException.Create('Hysteresis list requires a comparer.');

  Compare := Comparer;
  FullCompare := FullComparer;
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
  Found, Modified: Boolean;
  i, j: Integer;
begin
  if Assigned(OnUpdateStart) then
    OnUpdateStart;

  FAddStartDelta := 0;
  FAddFinishDelta := 0;
  FRemoveStartDelta := 0;
  FRemoveFinishDelta := 0;

  // Mark all our items as unprocessed
  for Item in FItems do
  begin
    Item.Found := False;
    Item.Delta := [];
  end;

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

        // If necessary, perform full comparison to find slight modifications
        Modified := Assigned(OnItemModified) and Assigned(FullCompare) and
          not FullCompare(FItems[i].Data, Snapshot[j]);

        // Make sure the data up-to-date
        FItems[i].FData := Snapshot[j];

        // Invoke the modification event if necessary
        if Modified then
          OnItemModified(FItems[i].Data, i);

        Break;
      end;

    if not Found then
    begin
      // New data has arrived, add it
      FItems.Add(THysteresisItem<T>.Create(Snapshot[j], TimeToLive + 1));
      Inc(FAddStartDelta);

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

      Inc(FRemoveStartDelta);
      Include(FItems[i].Delta, hdRemoveStart);

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

      Inc(FAddFinishDelta);
      Include(FItems[i].Delta, hdAddFinish);

      if Assigned(OnAddFinish) then
        OnAddFinish(FItems[i].Data, i);
    end;

  // Complete item deletion for those items that are gone for long enough
  for Item in FItems do
    if Item.DeletePending and (Item.TimeToLive <= 0) then
    begin
      Inc(FRemoveFinishDelta);
      Include(Item.Delta, hdRemoveFinish);

      if Assigned(OnRemoveFinish) then
        OnRemoveFinish(Item.Data, FItems.IndexOf(Item));

      Item.Free;
      FItems.Remove(Item);
    end;

  if Assigned(OnUpdateFinish) then
    OnUpdateFinish;
end;

end.
