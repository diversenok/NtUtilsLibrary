unit DelphiUiLib.HysteresisTree;

{
  This unit provides a hysteresis tree, which is a data structure for storing a
  (flat or tree-like) collection of elements that has a short memory of its
  previous states and can identify recently added/removed elements.
}

interface

uses
  DelphiUtils.Arrays, DelphiApi.Reflection;

type
  [NamingStyle(nsCamelCase, 'hns')]
  THysteresisNodeState = (
    hnsNormal,
    hnsRecentlyAdded,
    hnsRecentlyRemoved
  );

  THysteresisNode = class abstract
  private
    FContext: IUnknown;
    FParent: THysteresisNode;
    FPreviousSibling: THysteresisNode;
    FNextSibling: THysteresisNode;
    FChildren: TArray<THysteresisNode>;
    FRelatedNode: THysteresisNode;
    FIndex: Integer;
    FTransitionTTL: Integer;
    FState: THysteresisNodeState;
    FDeleted: Boolean;
  protected
    procedure UpdateData(Address: Pointer); virtual; abstract;
    procedure AssignData(Source: THysteresisNode); virtual; abstract;
  public
    // A user-defined context to attach to this node. The value is migrated to
    // the node with an equivalent resource upon updates.
    property Context: IUnknown read FContext write FContext;

    // Whether the node undergoes a transition (as recently added or removed)
    property State: THysteresisNodeState read FState;

    // The number of updates until the transition completes
    property TransitionTTL: Integer read FTransitionTTL;

    // The index of the current node in the global list returned by the tree
    property Index: Integer read FIndex;
  end;

  THysteresisNodeClass = class of THysteresisNode;

  // An actual (generic) class for nodes in a hysteresis tree
  THysteresisNode<T> = class (THysteresisNode)
  private
    FData: T;
    function GetParent: THysteresisNode<T>;
    function GetPreviousSibling: THysteresisNode<T>;
    function GetNextSibling: THysteresisNode<T>;
    function GetChildren: TArray<THysteresisNode<T>>;
  protected
    procedure UpdateData(Address: Pointer); override;
    procedure AssignData(Source: THysteresisNode); override;
  public
    // The underlying resource
    property Data: T read FData;

    // Connected nodes in the hiearachy
    property Parent: THysteresisNode<T> read GetParent;
    property PreviousSibling: THysteresisNode<T> read GetPreviousSibling;
    property NextSibling: THysteresisNode<T> read GetNextSibling;
    property Children: TArray<THysteresisNode<T>> read GetChildren;
  end;

  THysteresisTree = class abstract (TInterfacedObject)
  protected
    FNodeClass: THysteresisNodeClass;
    FCurrentNodes, FNewNodes: TArray<THysteresisNode>;
    FDefaultTTL: Integer;
    FFirstUpdateComplete: Boolean;
    FHasParentCheck: Boolean;
    function EffectiveTTL: Integer;
    function GetTransitionTime: Integer;
    procedure SetTransitionTime(Value: Integer);
    procedure Update(const Data: TArray<Pointer>);
    procedure Step1AdvanceTTL;
    procedure Step2ConvertEntries(const Data: TArray<Pointer>);
    procedure Step3LinkRelatedNodes;
    procedure Step4aInsertAt(NewNode: THysteresisNode; Index: Integer);
    procedure Step4bEnsureInserted(OldNode: THysteresisNode);
    procedure Step4InsertRecentlyRemoved;
    procedure Step5CleanupAndSwapLists;
    procedure Step6BuildTree;
    function EquivalencyCheck(const A, B: THysteresisNode): Boolean; virtual; abstract;
    function ParentCheck(const Parent, Child: THysteresisNode): Boolean; virtual; abstract;
    constructor Create(NodeClass: THysteresisNodeClass; HasParentCheck: Boolean; TTL: Integer);
  public
    destructor Destroy; override;
  end;

  IHysteresisTree<T> = interface
    ['{FEB19DB8-8F3E-4FF1-AD4D-9ADAC723F164}']
    function GetNodes: TArray<THysteresisNode<T>>;
    function GetTransitionTime: Integer;
    procedure SetTransitionTime(Value: Integer);

    // Refresh the tree with the new details
    procedure Update(const Entries: TArray<T>);

    // Inspect the tree nodes
    property Nodes: TArray<THysteresisNode<T>> read GetNodes;

    // The number of updates nodes remain "recent" when added or removed
    property TransitionTime: Integer read GetTransitionTime write SetTransitionTime;
  end;

  THysteresisTree<T> = class (THysteresisTree, IHysteresisTree<T>)
  protected
    FEquivalencyCheck: TEqualityCheck<T>;
    FParentCheck: TParentChecker<T>;
    function EquivalencyCheck(const A, B: THysteresisNode): Boolean; override;
    function ParentCheck(const Parent, Child: THysteresisNode): Boolean; override;
    function GetNodes: TArray<THysteresisNode<T>>;
    procedure Update(const Entries: TArray<T>); reintroduce;
    constructor Create(
      const AEquivalencyCheck: TEqualityCheck<T>;
      [opt] const AParentCheck: TParentChecker<T>;
      [opt] TTL: Integer
    );
  public
    // Make an empty tree instance
    class function Initialize(
      const EquivalencyCheck: TEqualityCheck<T>;
      [opt] const ParentCheck: TParentChecker<T> = nil;
      [opt] TTL: Integer = 0
    ): IHysteresisTree<T>; static;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ THysteresisNode<T> }

procedure THysteresisNode<T>.AssignData;
begin
  FData := THysteresisNode<T>(Source).Data;
end;

function THysteresisNode<T>.GetChildren;
var
  i: Integer;
begin
  SetLength(Result, Length(FChildren));

  for i := 0 to High(Result) do
    Result[i] := THysteresisNode<T>(FChildren[i]);
end;

function THysteresisNode<T>.GetNextSibling;
begin
  Result := THysteresisNode<T>(FNextSibling);
end;

function THysteresisNode<T>.GetParent;
begin
  Result := THysteresisNode<T>(FParent);
end;

function THysteresisNode<T>.GetPreviousSibling;
begin
  Result := THysteresisNode<T>(FPreviousSibling);
end;

procedure THysteresisNode<T>.UpdateData;
begin
  FData := T(Address^);
end;

{ THysteresisTree }

constructor THysteresisTree.Create;
begin
  inherited Create;
  FNodeClass := NodeClass;
  FDefaultTTL := TTL;
  FHasParentCheck := HasParentCheck;
end;

destructor THysteresisTree.Destroy;
var
  Node: THysteresisNode;
begin
  for Node in FCurrentNodes do
    Node.Free;

  FCurrentNodes := nil;
  inherited;
end;

function THysteresisTree.EffectiveTTL;
begin
  if FFirstUpdateComplete then
    Result := FDefaultTTL
  else
    Result := 0; // Suppress recently added state on the first update
end;

function THysteresisTree.GetTransitionTime;
begin
  Result := FDefaultTTL;
end;

procedure THysteresisTree.SetTransitionTime;
begin
  if Value < 0 then
    FDefaultTTL := 0
  else
    FDefaultTTL := Value;
end;

// Advance state for recently added and removed nodes
procedure THysteresisTree.Step1AdvanceTTL;
var
  Node: THysteresisNode;
begin
  for Node in FCurrentNodes do
    case Node.FState of
      hnsRecentlyAdded:
      begin
        Dec(Node.FTransitionTTL);

        // Promote recently added nodes to normal after a timeout
        if Node.FTransitionTTL <= 0 then
          Node.FState := hnsNormal;
      end;

      hnsRecentlyRemoved:
      begin
        Dec(Node.FTransitionTTL);

        // Make recently removed nodes disappear after a timeout
        if Node.FTransitionTTL <= 0 then
          Node.FDeleted := True;
      end;
    end;
end;

// Convert entries into node placeholders
procedure THysteresisTree.Step2ConvertEntries;
var
  i: Integer;
begin
  SetLength(FNewNodes, Length(Data));

  for i := 0 to High(Data) do
  begin
    // When TTL is enabled, assume all new entries as recently added until we
    // find them a match among the old ones.
    FNewNodes[i] := FNodeClass.Create;
    FNewNodes[i].UpdateData(Data[i]);

    if EffectiveTTL > 0 then
    begin
      FNewNodes[i].FState := hnsRecentlyAdded;
      FNewNodes[i].FTransitionTTL := EffectiveTTL;
    end
    else
      FNewNodes[i].FState := hnsNormal;

    FNewNodes[i].FIndex := i;
  end;
end;

// Link old and new nodes that refer to the same underlying resource
procedure THysteresisTree.Step3LinkRelatedNodes;
var
  OldNode, NewNode: THysteresisNode;
begin
  // Note 1: recently removed nodes cannot be resurrected, so they are skipped
  // during matching. Even if there is a match, it should be treated
  // independently as a recently added node.

  // Note 2: the equality check can potentially match more than one node. We
  // reserve the first new node for the first old node and so on.

  for OldNode in FCurrentNodes do
    Assert(not Assigned(OldNode.FRelatedNode), 'Stale reference on old node');

  for NewNode in FNewNodes do
    Assert(not Assigned(NewNode.FRelatedNode), 'Stale reference on new node');

  for OldNode in FCurrentNodes do
    if OldNode.FState <> hnsRecentlyRemoved then
      for NewNode in FNewNodes do
        if not Assigned(NewNode.FRelatedNode) and
          EquivalencyCheck(NewNode, OldNode) then
        begin
          // Link equivalent nodes and copy the state to the new node
          OldNode.FRelatedNode := NewNode;
          NewNode.FRelatedNode := OldNode;
          NewNode.FState := OldNode.FState;
          NewNode.FTransitionTTL := OldNode.FTransitionTTL;
          NewNode.FContext := OldNode.FContext;
          Break;
        end;
end;

// A helper for inserting a node at a specific location
procedure THysteresisTree.Step4aInsertAt;
var
  i: Integer;
begin
  System.Insert(NewNode, FNewNodes, Index);

  // Update cached indexes to keep them correct
  for i := Index to High(FNewNodes) do
    FNewNodes[i].FIndex := i;
end;

// Insert an old node into the new list if necessary
procedure THysteresisTree.Step4bEnsureInserted;
var
  NewNode: THysteresisNode;
  Index: Integer;
begin
  // Already complete?
  if Assigned(OldNode.FRelatedNode) then
    Exit;

  // Prepare a new node. At this stage, only recently removed ones remain
  NewNode := FNodeClass.Create;
  NewNode.AssignData(OldNode);
  NewNode.FState := hnsRecentlyRemoved;

  if OldNode.FState = hnsRecentlyRemoved then
    NewNode.FTransitionTTL := OldNode.FTransitionTTL
  else
    NewNode.FTransitionTTL := EffectiveTTL;

  NewNode.FDeleted := OldNode.FDeleted or (NewNode.FTransitionTTL <= 0);
  NewNode.FContext := OldNode.FContext;

  if Assigned(OldNode.FPreviousSibling) then
  begin
    if not Assigned(OldNode.FPreviousSibling.FRelatedNode) then
      Step4bEnsureInserted(OldNode.FPreviousSibling);

    // Insert right after the previous sibling
    Index := OldNode.FPreviousSibling.FRelatedNode.FIndex + 1;
  end
  else if Assigned(OldNode.FParent) then
  begin
    if not Assigned(OldNode.FParent.FRelatedNode) then
      Step4bEnsureInserted(OldNode.FParent);

    // Insert right after the parent
    Index := OldNode.FParent.FRelatedNode.FIndex + 1;
  end
  else
  begin
    // We are the first node overall, remain such
    Index := 0;
  end;

  // Insert at the preferred location
  Step4aInsertAt(NewNode, Index);

  // Link old <--> new
  NewNode.FRelatedNode := OldNode;
  OldNode.FRelatedNode := NewNode;
end;

// Insert all remaining old nodes as recently removed
procedure THysteresisTree.Step4InsertRecentlyRemoved;
var
  OldNode: THysteresisNode;
begin
  // Process all nodes that are not inserted yet
  for OldNode in FCurrentNodes do
    if not Assigned(OldNode.FRelatedNode) then
      Step4bEnsureInserted(OldNode);
end;

// Remove deleted nodes and clear links
procedure THysteresisTree.Step5CleanupAndSwapLists;
var
  i, j: Integer;
begin
  // Cleanup links for the old nodes
  for i := 0 to High(FCurrentNodes) do
    FCurrentNodes[i].FRelatedNode := nil;

  // Cleanup links for the new nodes
  for i := 0 to High(FNewNodes) do
    FNewNodes[i].FRelatedNode := nil;

  // Remove deleted entries from the new nodes. We don't need them anymore since
  // they have already impacted the ordering of other nodes.
  j := 0;
  for i := 0 to High(FNewNodes) do
    if not FNewNodes[i].FDeleted then
    begin
      // Compact non-deleted nodes and adjust indexes
      if i <> j then
      begin
        FNewNodes[j].Free;
        FNewNodes[j] := FNewNodes[i];
        FNewNodes[j].FIndex := j;
        FNewNodes[i] := nil; // We have transferred owenrship
      end;

      Inc(j);
    end;

  // Free trailing deleted nodes
  for i := j to High(FNewNodes) do
    FNewNodes[i].Free;

  // Trim after compaction
  SetLength(FNewNodes, j);

  // Free the old nodes
  for i := 0 to High(FCurrentNodes) do
    FCurrentNodes[i].Free;

  // The new can finally become the current
  FCurrentNodes := FNewNodes;
  FNewNodes := nil;
end;

// Connect nodes based on parent-child relationships
procedure THysteresisTree.Step6BuildTree;
var
  i, j, k, Count: Integer;
  Parent, Previous: THysteresisNode;
begin
  if FHasParentCheck then
  begin
    // Fill parent references
    for i := 0 to High(FCurrentNodes) do
      for j := 0 to High(FCurrentNodes) do
        if (i <> j) and ParentCheck(FCurrentNodes[j],
          FCurrentNodes[i]) then
        begin
          FCurrentNodes[i].FParent := FCurrentNodes[j];
          Break;
        end;

    // Verify there are no cycles
    for i := 0 to High(FCurrentNodes) do
    begin
      j := 0;
      Parent := FCurrentNodes[i].FParent;

      // Try to find the root which must be at most High(FCurrentNodes) away
      while Assigned(Parent) and (j <= High(FCurrentNodes)) do
      begin
        Parent := Parent.FParent;
        Inc(j);
      end;

      // A cycle detected; detach the parent to resolve it
      if Assigned(Parent) then
        FCurrentNodes[i].FParent := nil;
    end;

    // Fill child references
    for i := 0 to High(FCurrentNodes) do
    begin
      Count := 0;
      for j := 0 to High(FCurrentNodes) do
        if FCurrentNodes[j].FParent = FCurrentNodes[i] then
          Inc(Count);

      SetLength(FCurrentNodes[i].FChildren, Count);

      k := 0;
      for j := 0 to High(FCurrentNodes) do
        if FCurrentNodes[j].FParent = FCurrentNodes[i] then
        begin
          FCurrentNodes[i].FChildren[k] := FCurrentNodes[j];
          Inc(k);
        end;
    end;

    // Fill sibling references for parented nodes
    for i := 0 to High(FCurrentNodes) do
      for j := 0 to High(FCurrentNodes[i].FChildren) do
      begin
        if j > 0 then
          FCurrentNodes[i].FChildren[j].FPreviousSibling :=
            FCurrentNodes[i].FChildren[j - 1];

        if j < High(FCurrentNodes[i].FChildren) then
          FCurrentNodes[i].FChildren[j].FNextSibling :=
            FCurrentNodes[i].FChildren[j + 1];
      end;
  end;

  // Fill sibling references for root nodes
  Previous := nil;

  for i := 0 to High(FCurrentNodes) do
    if not Assigned(FCurrentNodes[i].FParent) then
    begin
      FCurrentNodes[i].FPreviousSibling := Previous;

      if Assigned(Previous) then
        Previous.FNextSibling := FCurrentNodes[i];

      Previous := FCurrentNodes[i];
    end;
end;

procedure THysteresisTree.Update;
begin
  Step1AdvanceTTL;
  Step2ConvertEntries(Data);
  Step3LinkRelatedNodes;
  Step4InsertRecentlyRemoved;
  Step5CleanupAndSwapLists;
  Step6BuildTree;
  FFirstUpdateComplete := True;
end;

{ THysteresisTree<T> }

constructor THysteresisTree<T>.Create;
begin
  inherited Create(THysteresisNode<T>, Assigned(AParentCheck), TTL);
  FEquivalencyCheck := AEquivalencyCheck;
  FParentCheck := AParentCheck;
end;

function THysteresisTree<T>.EquivalencyCheck;
begin
  Result := FEquivalencyCheck(
    THysteresisNode<T>(A).FData,
    THysteresisNode<T>(B).FData
  );
end;

function THysteresisTree<T>.GetNodes;
begin
  Result := TArray<THysteresisNode<T>>(FCurrentNodes);
end;

class function THysteresisTree<T>.Initialize;
begin
  if not Assigned(EquivalencyCheck) then
    Error(reInvalidPtr);

  Result := THysteresisTree<T>.Create(EquivalencyCheck, ParentCheck, TTL);
end;

function THysteresisTree<T>.ParentCheck;
begin
  Result := Assigned(FParentCheck) and FParentCheck(
    THysteresisNode<T>(Parent).FData,
    THysteresisNode<T>(Child).FData
  );
end;

procedure THysteresisTree<T>.Update;
var
  Data: TArray<Pointer>;
  i: Integer;
begin
  SetLength(Data, Length(Entries));

  for i := 0 to High(Data) do
    Data[i] := @Entries[i];

  inherited Update(Data);
end;

end.
