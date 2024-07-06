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

  // A list entry that stores an arbitrary IMemory<P> data (where P is a
  // pointer type). You can safely cast between IDoubleListEntry<P1> and
  // IDoubleListEntry<P2> when necessary.
  IDoubleListEntry<P> = interface
    ['{7F3EA2EB-08C8-4729-B645-E2418D9C9FE6}']
    function GetLinks: PListEntry;
    function GetContent: IMemory<P>;
    procedure SetContent(const Data: IMemory<P>);
    property Links: PListEntry read GetLinks;
    property Content: IMemory<P> read GetContent write SetContent;
  end;
  IDoubleListEntry = IDoubleListEntry<Pointer>;

  // A double linked list collection for arbitrary IMemory<P> data.
  // You can safely cast between IDoubleListEntry<P1> and IDoubleListEntry<P2>
  // when necessary.
  IDoubleList<P> = interface (IEnumerable<IDoubleListEntry<P>>)
    ['{66AE8FA4-19C9-425F-9905-6BBBC13C0450}']
    function GetIsEmpty: Boolean;
    function GetLinks: PListEntry;
    function GetCount: Integer;
    property IsEmpty: Boolean read GetIsEmpty;
    property Links: PListEntry read GetLinks;
    property Count: Integer read GetCount;
    function InsertTail(const Data: IMemory): IDoubleListEntry<P>;
    function InsertHead(const Data: IMemory): IDoubleListEntry<P>;
    function RemoveTail: IDoubleListEntry<P>;
    function RemoveHead: IDoubleListEntry<P>;
    procedure Remove(Entry: IDoubleListEntry<P>);
    procedure RemoveAll;
    function Iterate(Direction: TDoubleListDirection): IEnumerable<IDoubleListEntry<P>>;
    function ToEntryArray(Direction: TDoubleListDirection = ldForward): TArray<IDoubleListEntry<P>>;
    function ToContentArray(Direction: TDoubleListDirection = ldForward): TArray<IMemory<P>>;
  end;
  IDoubleList = IDoubleList<Pointer>;

// Create an empty double-linked list. To change the element pointer type,
// use a left-side cast, i.e.:
//    var List: IDoubleList<PMyType>;
//    IDoubleList(List) := NewDoubleList;
function CreateDoubleList: IDoubleList;

implementation

uses
  Ntapi.ntrtl;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TDoubleListEntry = class (TInterfacedObject, IDoubleListEntry)
  protected
    FLinks: TListEntry;
    FData: IMemory;
    function GetLinks: PListEntry;
    function GetContent: IMemory;
    procedure SetContent(const Value: IMemory);
    class function LinksToObject(Links: PListEntry): IDoubleListEntry; static;
    constructor Create(const Data: IMemory);
  end;

  TDoubleList = class (TInterfacedObject, IDoubleList)
  protected
    FLinks: TListEntry;
    function GetIsEmpty: Boolean;
    function GetLinks: PListEntry;
    function GetCount: Integer;
    function InsertTail(const Data: IMemory): IDoubleListEntry;
    function InsertHead(const Data: IMemory): IDoubleListEntry;
    function RemoveTail: IDoubleListEntry;
    function RemoveHead: IDoubleListEntry;
    procedure Remove(Entry: IDoubleListEntry);
    procedure RemoveAll;
    function Iterate(Direction: TDoubleListDirection): IEnumerable<IDoubleListEntry>;
    function ToEntryArray(Direction: TDoubleListDirection): TArray<IDoubleListEntry>;
    function ToContentArray(Direction: TDoubleListDirection = ldForward): TArray<IMemory>;
    function GetEnumerator: IEnumerator; // legacy
    function GetEnumeratorP: IEnumerator<IDoubleListEntry>;
    function IDoubleList.GetEnumerator = GetEnumeratorP;
    constructor Create;
    destructor Destroy; override;
  end;

  TDoubleListEnumerator = class (TInterfacedObject,
    IEnumerable<IDoubleListEntry>, IEnumerator<IDoubleListEntry>)
  protected
    FListHead: IDoubleList;
    FCurrent: PListEntry;
    FCurrentRef: IDoubleListEntry;
    FDirection: TDoubleListDirection;
    procedure Reset;
    function MoveNext: Boolean;
    function GetCurrent: TObject;
    function GetCurrentP: IDoubleListEntry;
    function IEnumerator<IDoubleListEntry>.GetCurrent = GetCurrentP;
    function GetEnumerator: IEnumerator; // legacy
    function GetEnumeratorP: IEnumerator<IDoubleListEntry>;
    function IEnumerable<IDoubleListEntry>.GetEnumerator = GetEnumeratorP;
    constructor Create(const List: IDoubleList; Direction: TDoubleListDirection);
  end;

{ TDoubleListEntry }

constructor TDoubleListEntry.Create;
begin
  inherited Create;
  FData := Data;
end;

function TDoubleListEntry.GetContent;
begin
  Result := FData;
end;

function TDoubleListEntry.GetLinks;
begin
  Result := @FLinks;
end;

class function TDoubleListEntry.LinksToObject;
var
  Obj: TDoubleListEntry;
begin
  Obj := Pointer(UIntPtr(Links) - UIntPtr(@TDoubleListEntry(nil).FLinks));
  Result := IDoubleListEntry(Obj);
end;

procedure TDoubleListEntry.SetContent;
begin
  FData := Value;
end;

{ TDoubleList }

constructor TDoubleList.Create;
begin
  inherited Create;
  InitializeListHead(@FLinks);
end;

destructor TDoubleList.Destroy;
begin
  RemoveAll;
  inherited;
end;

function TDoubleList.GetCount;
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

function TDoubleList.GetEnumerator;
begin
  Assert(False, 'Legacy (untyped) IEnumerable.GetEnumerator not supported');
  Result := nil;
end;

function TDoubleList.GetEnumeratorP;
begin
  Result := TDoubleListEnumerator.Create(Self, ldForward);
end;

function TDoubleList.GetIsEmpty;
begin
  Result := IsListEmpty(@FLinks);
end;

function TDoubleList.GetLinks;
begin
  Result := @FLinks;
end;

function TDoubleList.InsertHead;
begin
  Result := TDoubleListEntry.Create(Data);
  InsertHeadList(@FLinks, Result.Links);
  Result._AddRef;
end;

function TDoubleList.InsertTail;
begin
  Result := TDoubleListEntry.Create(Data);
  InsertTailList(@FLinks, Result.Links);
  Result._AddRef;
end;

function TDoubleList.Iterate;
begin
  Result := TDoubleListEnumerator.Create(Self, Direction);
end;

procedure TDoubleList.Remove;
begin
  RemoveEntryList(Entry.GetLinks);
  Entry.Links^ := Default(TListEntry);
  Entry._Release;
end;

procedure TDoubleList.RemoveAll;
begin
  while not GetIsEmpty do
    RemoveTail;
end;

function TDoubleList.RemoveHead;
begin
  Result := TDoubleListEntry.LinksToObject(RemoveHeadList(@FLinks));
  Result.Links^ := Default(TListEntry);
  Result._Release;
end;

function TDoubleList.RemoveTail;
begin
  Result := TDoubleListEntry.LinksToObject(RemoveTailList(@FLinks));
  Result.Links^ := Default(TListEntry);
  Result._Release;
end;

function TDoubleList.ToContentArray;
var
  i: Integer;
  Entry: IDoubleListEntry;
begin
  SetLength(Result, GetCount);
  i := 0;

  for Entry in Iterate(Direction) do
  begin
    Result[i] := Entry.Content;
    Inc(i);
  end;
end;

function TDoubleList.ToEntryArray;
var
  i: Integer;
  Entry: IDoubleListEntry;
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

constructor TDoubleListEnumerator.Create;
begin
  inherited Create;
  FListHead := List;
  FDirection := Direction;
  Reset;
end;

function TDoubleListEnumerator.GetCurrent;
begin
  Assert(False, 'Legacy (untyped) IEnumerator.GetCurrent not supported');
  Result := nil;
end;

function TDoubleListEnumerator.GetCurrentP;
begin
  Result := FCurrentRef;
end;

function TDoubleListEnumerator.GetEnumerator;
begin
  Assert(False, 'Legacy (untyped) IEnumerable.GetEnumerator not supported');
  Result := nil;
end;

function TDoubleListEnumerator.GetEnumeratorP;
begin
  Result := Self;
end;

function TDoubleListEnumerator.MoveNext;
begin
  if FDirection = ldForward then
    FCurrent := FCurrent.Flink
  else
    FCurrent := FCurrent.Blink;

  Result := Assigned(FCurrent) and (FCurrent <> FListHead.Links);

  if Result then
    FCurrentRef := TDoubleListEntry.LinksToObject(FCurrent)
  else
    FCurrentRef := nil;
end;

procedure TDoubleListEnumerator.Reset;
begin
  FCurrent := FListHead.Links;
  FCurrentRef := nil;
end;

{ Functions }

function CreateDoubleList;
begin
  Result := TDoubleList.Create;
end;

end.
