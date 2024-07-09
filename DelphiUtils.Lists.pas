unit DelphiUtils.Lists;

{
  This module provides a generic double linked list.
}

interface

uses
  Ntapi.WinNt, DelphiUtils.AutoObjects;

type
  TDoubleListDirection = (
    ldForward,
    ldBackward
  );

  // A list entry that stores an arbitrary managed type as data.
  IDoubleListEntry<T> = interface
    ['{A7F33808-1B21-43F5-8455-D94B524CD6E3}']
    function GetLinks: PListEntry;
    function GetContent: T;
    procedure SetContent(const Data: T);
    property Links: PListEntry read GetLinks;
    property Content: T read GetContent write SetContent;
  end;

  // A double linked list collection for arbitrarily typed data entries.
  IDoubleList<T> = interface
    ['{F1DCB6B4-4761-42AA-9FE9-4047579ADF0B}']
    function GetIsEmpty: Boolean;
    function GetLinks: PListEntry;
    function GetCount: Integer;
    property IsEmpty: Boolean read GetIsEmpty;
    property Links: PListEntry read GetLinks;
    property Count: Integer read GetCount;
    function InsertTail(const Content: T): IDoubleListEntry<T>;
    function InsertHead(const Content: T): IDoubleListEntry<T>;
    function InsterAfter(const Entry: IDoubleListEntry<T>; const Content: T): IDoubleListEntry<T>;
    function InsterBefore(const Entry: IDoubleListEntry<T>; const Content: T): IDoubleListEntry<T>;
    function RemoveTail: IDoubleListEntry<T>;
    function RemoveHead: IDoubleListEntry<T>;
    procedure Remove(Entry: IDoubleListEntry<T>);
    procedure RemoveAll;
    function Iterate(Direction: TDoubleListDirection = ldForward): IEnumerable<IDoubleListEntry<T>>;
    function ToEntryArray(Direction: TDoubleListDirection = ldForward): TArray<IDoubleListEntry<T>>;
    function ToContentArray(Direction: TDoubleListDirection = ldForward): TArray<T>;
  end;

  DoubleList = class abstract
    // Create an empty double-linked list
    class function Create<T>: IDoubleList<T>; static;
  end;

  { Internal-use }

  TDoubleListEntry<T> = class (TInterfacedObject, IDoubleListEntry<T>)
  protected
    FLinks: TListEntry;
    FContent: T;
    function GetLinks: PListEntry;
    function GetContent: T;
    procedure SetContent(const Value: T);
    class function LinksToObject(Links: PListEntry): IDoubleListEntry<T>; static;
    constructor Create(const Content: T);
  end;

  TDoubleList<T> = class (TInterfacedObject, IDoubleList<T>)
  protected
    FLinks: TListEntry;
    function GetIsEmpty: Boolean;
    function GetLinks: PListEntry;
    function GetCount: Integer;
    function InsertTail(const Content: T): IDoubleListEntry<T>;
    function InsertHead(const Content: T): IDoubleListEntry<T>;
    function InsterAfter(const Entry: IDoubleListEntry<T>; const Content: T): IDoubleListEntry<T>;
    function InsterBefore(const Entry: IDoubleListEntry<T>; const Content: T): IDoubleListEntry<T>;
    function RemoveTail: IDoubleListEntry<T>;
    function RemoveHead: IDoubleListEntry<T>;
    procedure Remove(Entry: IDoubleListEntry<T>);
    procedure RemoveAll;
    function Iterate(Direction: TDoubleListDirection): IEnumerable<IDoubleListEntry<T>>;
    function ToEntryArray(Direction: TDoubleListDirection): TArray<IDoubleListEntry<T>>;
    function ToContentArray(Direction: TDoubleListDirection): TArray<T>;
    constructor Create;
  public
    destructor Destroy; override;
  end;

  TDoubleListEnumerator<T> = class (TInterfacedObject,
    IEnumerable<IDoubleListEntry<T>>, IEnumerator<IDoubleListEntry<T>>)
  protected
    FListHead: IDoubleList<T>;
    FCurrent: PListEntry;
    FCurrentRef: IDoubleListEntry<T>;
    FDirection: TDoubleListDirection;
    procedure Reset;
    function MoveNext: Boolean;
    function GetCurrent: TObject;
    function GetCurrentT: IDoubleListEntry<T>;
    function IEnumerator<IDoubleListEntry<T>>.GetCurrent = GetCurrentT;
    function GetEnumerator: IEnumerator; // legacy
    function GetEnumeratorT: IEnumerator<IDoubleListEntry<T>>;
    function IEnumerable<IDoubleListEntry<T>>.GetEnumerator = GetEnumeratorT;
    constructor Create(const List: IDoubleList<T>; Direction: TDoubleListDirection);
  end;

implementation

uses
  Ntapi.ntrtl;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TDoubleListEntry }

constructor TDoubleListEntry<T>.Create;
begin
  inherited Create;
  FContent := Content;
end;

function TDoubleListEntry<T>.GetContent;
begin
  Result := FContent;
end;

function TDoubleListEntry<T>.GetLinks;
begin
  Result := @FLinks;
end;

class function TDoubleListEntry<T>.LinksToObject;
var
  Obj: TDoubleListEntry<T>;
begin
  Obj := Pointer(UIntPtr(Links) - UIntPtr(@TDoubleListEntry<T>(nil).FLinks));
  Result := IDoubleListEntry<T>(Obj);
end;

procedure TDoubleListEntry<T>.SetContent;
begin
  FContent := Value;
end;

{ TDoubleList }

constructor TDoubleList<T>.Create;
begin
  inherited Create;
  InitializeListHead(@FLinks);
end;

destructor TDoubleList<T>.Destroy;
begin
  RemoveAll;
  inherited;
end;

function TDoubleList<T>.GetCount;
var
  FCurrent: PListEntry;
begin
  Result := 0;
  FCurrent := FLinks.Flink;

  while FCurrent <> @FLinks do
  begin
    FCurrent := FCurrent.Flink;
    Inc(Result);
  end;
end;

function TDoubleList<T>.GetIsEmpty;
begin
  Result := IsListEmpty(@FLinks);
end;

function TDoubleList<T>.GetLinks;
begin
  Result := @FLinks;
end;

function TDoubleList<T>.InsertHead;
begin
  Result := TDoubleListEntry<T>.Create(Content);
  InsertHeadList(@FLinks, Result.Links);
  Result._AddRef;
end;

function TDoubleList<T>.InsertTail;
begin
  Result := TDoubleListEntry<T>.Create(Content);
  InsertTailList(@FLinks, Result.Links);
  Result._AddRef;
end;

function TDoubleList<T>.InsterAfter;
begin
  Result := TDoubleListEntry<T>.Create(Content);
  InsertHeadList(Entry.Links, Result.Links);
  Result._AddRef;
end;

function TDoubleList<T>.InsterBefore;
begin
  Result := TDoubleListEntry<T>.Create(Content);
  InsertTailList(Entry.Links, Result.Links);
  Result._AddRef;
end;

function TDoubleList<T>.Iterate;
begin
  Result := TDoubleListEnumerator<T>.Create(Self, Direction);
end;

procedure TDoubleList<T>.Remove;
begin
  RemoveEntryList(Entry.GetLinks);
  Entry.Links^ := Default(TListEntry);
  Entry._Release;
end;

procedure TDoubleList<T>.RemoveAll;
begin
  while not GetIsEmpty do
    RemoveTail;
end;

function TDoubleList<T>.RemoveHead;
begin
  Result := TDoubleListEntry<T>.LinksToObject(RemoveHeadList(@FLinks));
  Result.Links^ := Default(TListEntry);
  Result._Release;
end;

function TDoubleList<T>.RemoveTail;
begin
  Result := TDoubleListEntry<T>.LinksToObject(RemoveTailList(@FLinks));
  Result.Links^ := Default(TListEntry);
  Result._Release;
end;

function TDoubleList<T>.ToContentArray;
var
  i: Integer;
  Entry: IDoubleListEntry<T>;
begin
  SetLength(Result, GetCount);
  i := 0;

  for Entry in Iterate(Direction) do
  begin
    Result[i] := Entry.Content;
    Inc(i);
  end;
end;

function TDoubleList<T>.ToEntryArray;
var
  i: Integer;
  Entry: IDoubleListEntry<T>;
begin
  SetLength(Result, GetCount);
  i := 0;

  for Entry in Iterate(Direction) do
  begin
    Result[i] := Entry;
    Inc(i);
  end;
end;

{ TDoubleListEnumerator }

constructor TDoubleListEnumerator<T>.Create;
begin
  inherited Create;
  FListHead := List;
  FDirection := Direction;
  Reset;
end;

function TDoubleListEnumerator<T>.GetCurrent;
begin
  Assert(False, 'Legacy (untyped) IEnumerator.GetCurrent not supported');
  Result := nil;
end;

function TDoubleListEnumerator<T>.GetCurrentT;
begin
  Result := FCurrentRef;
end;

function TDoubleListEnumerator<T>.GetEnumerator;
begin
  Assert(False, 'Legacy (untyped) IEnumerable.GetEnumerator not supported');
  Result := nil;
end;

function TDoubleListEnumerator<T>.GetEnumeratorT;
begin
  Result := Self;
end;

function TDoubleListEnumerator<T>.MoveNext;
begin
  if FDirection = ldForward then
    FCurrent := FCurrent.Flink
  else
    FCurrent := FCurrent.Blink;

  Result := Assigned(FCurrent) and (FCurrent <> FListHead.Links);

  if Result then
    FCurrentRef := TDoubleListEntry<T>.LinksToObject(FCurrent)
  else
    FCurrentRef := nil;
end;

procedure TDoubleListEnumerator<T>.Reset;
begin
  FCurrent := FListHead.Links;
  FCurrentRef := nil;
end;

{ DoubleList }

class function DoubleList.Create<T>;
begin
  Result := TDoubleList<T>.Create;
end;

end.
