unit DelphiUiLib.HysteresisTree;

{
  This unit provides a hysteresis tree, which is a data structure for storing a
  (flat or tree-like) collection of elements that has a short memory of its
  previous states and can identify recently added/removed entries.
}

interface

uses
  DelphiUtils.Arrays, DelphiApi.Reflection;

type
  // Typical node lifetime (time measures in the number of Tree.Update calls):
  //
  //   <-- New data entry appears in the snapshot given to Tree.Update -->
  //  1. NewlyAdded & RecentlyAdded - for one update
  //  2. RecentlyAdded - for TTL-1 updates
  //  3. Normal - for as long as the data exists in the snapshot
  //   <-- The data entry dissapears from the snapshot -->
  //  4. RecentlyRemoved - for TTL updates
  //  5. Deleted - for one update
  //
  // Notes:
  // - RecentlyAdded is suppressed (replaced by Normal) for nodes added on the
  //   very first tree update.
  // - Nodes can go directly from RecentlyAdded to RecentlyRemoved if the
  //   corresponding data entry dissapears from the snapshot befor the node has
  //   time to transition to Normal.

  [NamingStyle(nsCamelCase, 'hnt')]
  THysteresisNodeTransition = (
    hntNormal,
    hntRecentlyAdded,
    hntRecentlyRemoved
  );

  THysteresisNode = class abstract
  private
    FContext: Pointer;
    FParent: THysteresisNode;
    FPreviousSibling: THysteresisNode;
    FNextSibling: THysteresisNode;
    FFirstChild: THysteresisNode;
    FIndex: Integer;
    FTransitionTTL: Integer;
    FTransitionState: THysteresisNodeTransition;
    FNewlyAdded: Boolean;
    FDeleted: Boolean;
  protected
    function GetDataStart: Pointer; virtual; abstract;
    procedure UpdateData(Address: Pointer); virtual; abstract;
    property DataStart: Pointer read GetDataStart;
  public
    // A user-defined context to attach to this node. The value is migrated to
    // the node with an equivalent resource upon updates.
    property Context: Pointer read FContext write FContext;

    // Whether the node undergoes a transition (as recently added or removed)
    property TransitionState: THysteresisNodeTransition read FTransitionState;

    // The number of updates until the transition completes
    property TransitionTTL: Integer read FTransitionTTL;

    // Indicates that the node was added during the last update
    property NewlyAdded: Boolean read FNewlyAdded;

    // The node has been deleted from the tree on the last update. It now
    // belongs to the deleted list and offers the last chance to clean-up.
    property Deleted: Boolean read FDeleted;

    // The index of the current node in the global list returned by the tree
    property Index: Integer read FIndex;

    // Connected nodes in the hiearachy
    property Parent: THysteresisNode read FParent;
    property PreviousSibling: THysteresisNode read FPreviousSibling;
    property NextSibling: THysteresisNode read FNextSibling;
    property FirstChild: THysteresisNode read FFirstChild;
  end;

  THysteresisNodeClass = class of THysteresisNode;

  // An actual (generic) class for nodes in a hysteresis tree
  THysteresisNode<T> = class (THysteresisNode)
  private
    FData: T;
    function GetParent: THysteresisNode<T>;
    function GetPreviousSibling: THysteresisNode<T>;
    function GetNextSibling: THysteresisNode<T>;
    function GetFirstChild: THysteresisNode<T>;
  protected
    function GetDataStart: Pointer; override;
    procedure UpdateData(Address: Pointer); override;
  public
    // The underlying resource
    property Data: T read FData;

    // Connected nodes in the hiearachy
    property Parent: THysteresisNode<T> read GetParent;
    property PreviousSibling: THysteresisNode<T> read GetPreviousSibling;
    property NextSibling: THysteresisNode<T> read GetNextSibling;
    property FirstChild: THysteresisNode<T> read GetFirstChild;
  end;

  IHysteresisTree = interface
    ['{61D4C719-6821-4D0B-A97A-9119C08DABCF}']
    function GetFirstNode: THysteresisNode;
    function GetNodes: TArray<THysteresisNode>;
    function GetFirstDeletedNode: THysteresisNode;
    function GetDeletedNodes: TArray<THysteresisNode>;
    function GetTransitionTime: Integer;
    procedure SetTransitionTime(Value: Integer);

    // Refresh the tree with the new data snapshot
    procedure Update(const Data: TArray<Pointer>);

    // The top root node in the hierarchy
    property FirstNode: THysteresisNode read GetFirstNode;

    // The full tree node hierarchy
    property Nodes: TArray<THysteresisNode> read GetNodes;

    // The first node in the list of deleted on the last update. Use for cleanup
    property FirstDeletedNode: THysteresisNode read GetFirstDeletedNode;

    // All nodes deleted from the tree at the last update. Use for cleanup
    property DeletedNodes: TArray<THysteresisNode> read GetDeletedNodes;

    // The number of updates nodes remain "recent" when added or removed
    property TransitionTime: Integer read GetTransitionTime write SetTransitionTime;
  end;

  IHysteresisTree<T> = interface (IHysteresisTree)
    ['{FEB19DB8-8F3E-4FF1-AD4D-9ADAC723F164}']
    function GetFirstNode: THysteresisNode<T>;
    function GetNodes: TArray<THysteresisNode<T>>;
    function GetFirstDeletedNode: THysteresisNode<T>;
    function GetDeletedNodes: TArray<THysteresisNode<T>>;

    // Refresh the tree with the new data snapshot
    procedure Update(const Entries: TArray<T>);

    // The top root node in the hierarchy
    property FirstNode: THysteresisNode<T> read GetFirstNode;

    // The full tree node hierarchy
    property Nodes: TArray<THysteresisNode<T>> read GetNodes;

    // The first node in the list of deleted on the last update. Use for cleanup
    property FirstDeletedNode: THysteresisNode<T> read GetFirstDeletedNode;

    // All nodes deleted from the tree at the last update. Use for cleanup
    property DeletedNodes: TArray<THysteresisNode<T>> read GetDeletedNodes;
  end;

  THysteresisTree = class abstract (TInterfacedObject, IHysteresisTree)
  protected
    FNodeClass: THysteresisNodeClass;
    FNodes, FDeletedNodes: TArray<THysteresisNode>;
    FDefaultTTL: Integer;
    FFirstUpdateComplete: Boolean;
    FHasParentCheck: Boolean;
    function EffectiveTTL: Integer;
    function GetFirstNode: THysteresisNode;
    function GetNodes: TArray<THysteresisNode>;
    function GetFirstDeletedNode: THysteresisNode;
    function GetDeletedNodes: TArray<THysteresisNode>;
    function GetTransitionTime: Integer;
    procedure SetTransitionTime(Value: Integer);
    procedure Update(const Data: TArray<Pointer>);
    procedure Step1AdvanceTTL;
    procedure Step2aInsertAt(Node: THysteresisNode; Index: Integer);
    procedure Step2bEnsureMerged(Node: THysteresisNode);
    procedure Step2MergeData(const Data: TArray<Pointer>);
    procedure Step3ExtractDeleted;
    procedure Step4BuildTree;
    function EquivalencyCheck(Node: THysteresisNode; Data: Pointer): Boolean; virtual; abstract;
    function ParentCheck(const Parent, Child: THysteresisNode): Boolean; virtual; abstract;
    constructor Create(NodeClass: THysteresisNodeClass; HasParentCheck: Boolean; TTL: Integer);
  public
    destructor Destroy; override;
  end;

  THysteresisTree<T> = class sealed (THysteresisTree, IHysteresisTree<T>)
  protected
    FEquivalencyCheck: TEqualityCheck<T>;
    FParentCheck: TParentChecker<T>;
    function EquivalencyCheck(Node: THysteresisNode; Data: Pointer): Boolean; override;
    function ParentCheck(const Parent, Child: THysteresisNode): Boolean; override;
    function GetFirstNode: THysteresisNode<T>;
    function GetNodes: TArray<THysteresisNode<T>>;
    function GetFirstDeletedNode: THysteresisNode<T>;
    function GetDeletedNodes: TArray<THysteresisNode<T>>;
    procedure Update(const Entries: TArray<T>); reintroduce;
    constructor Create(
      const AEquivalencyCheck: TEqualityCheck<T>;
      [opt] const AParentCheck: TParentChecker<T>;
      [opt] TTL: Integer
    );
  public
    // Make an empty tree instance
    class function Initialize(
      EquivalencyCheck: TEqualityCheck<T>;
      [opt] ParentCheck: TParentChecker<T> = nil;
      [opt] TTL: Integer = 0
    ): IHysteresisTree<T>; static;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ THysteresisNode<T> }

function THysteresisNode<T>.GetDataStart;
begin
  Result := @FData;
end;

function THysteresisNode<T>.GetFirstChild;
begin
  Result := THysteresisNode<T>(FFirstChild);
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
  for Node in FNodes do
    Node.Free;

  for Node in FDeletedNodes do
    Node.Free;

  inherited;
end;

function THysteresisTree.EffectiveTTL;
begin
  if FFirstUpdateComplete then
    Result := FDefaultTTL
  else
    Result := 0; // Suppress recently added State on the first update
end;

function THysteresisTree.GetDeletedNodes;
begin
  Result := FDeletedNodes;
end;

function THysteresisTree.GetFirstDeletedNode;
begin
  if Length(FDeletedNodes) > 0 then
    Result := FDeletedNodes[0]
  else
    Result := nil;
end;

function THysteresisTree.GetFirstNode;
begin
  if Length(FNodes) > 0 then
    Result := FNodes[0]
  else
    Result := nil;
end;

function THysteresisTree.GetNodes;
begin
  Result := FNodes;
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

// Advance transition state for recently added and removed nodes
procedure THysteresisTree.Step1AdvanceTTL;
var
  Node: THysteresisNode;
begin
  for Node in FNodes do
  begin
    case Node.FTransitionState of
      hntRecentlyAdded:
      begin
        Dec(Node.FTransitionTTL);

        // Promote recently added nodes to normal after a timeout
        if Node.FTransitionTTL <= 0 then
          Node.FTransitionState := hntNormal;
      end;

      hntRecentlyRemoved:
      begin
        Dec(Node.FTransitionTTL);

        // Make recently removed nodes disappear after a timeout
        if Node.FTransitionTTL <= 0 then
          Node.FDeleted := True;
      end;
    end;

    // All existing nodes are old now
    Node.FNewlyAdded := False;
  end;
end;

// A helper for inserting a node at a specific location
procedure THysteresisTree.Step2aInsertAt;
var
  i: Integer;
begin
  System.Insert(Node, FNodes, Index);

  // Update cached indexes to keep them correct
  for i := Index to High(FNodes) do
    FNodes[i].FIndex := i;
end;

// Insert a node at the best location for it, if necessary
procedure THysteresisTree.Step2bEnsureMerged;
var
  RelativeTo: THysteresisNode;
begin
  // Already in the new generation?
  if (Node.FIndex <= High(FNodes)) and (FNodes[Node.FIndex] = Node) then
    Exit;

  // We prefer being next the previous sibling or at least the parent
  if Assigned(Node.FPreviousSibling) then
    RelativeTo := Node.FPreviousSibling
  else if Assigned(Node.FParent) then
    RelativeTo := Node.FParent
  else
    RelativeTo := nil;

  if Assigned(RelativeTo) then
  begin
    // Recurse on the related node
    Step2bEnsureMerged(RelativeTo);

    // Insert next to it
    Step2aInsertAt(Node, RelativeTo.Index + 1);
  end
  else
    // We are the first node overall; remain such
    Step2aInsertAt(Node, 0);
end;

// Update and reshuffle nodes based on the data snapshot
procedure THysteresisTree.Step2MergeData;
var
  i, j: Integer;
  FOldGeneration: TArray<THysteresisNode>;
begin
  // Prepare for a new generation of nodes
  FOldGeneration := FNodes;
  FNodes := nil;
  SetLength(FNodes, Length(Data));

  for i := 0 to High(Data) do
  begin
    // Try to find a matching node from the previous generation. Note: recently
    // removed nodes cannot be revived, so we skip them here
    for j := 0 to High(FOldGeneration) do
      if Assigned(FOldGeneration[j]) and
        (FOldGeneration[j].FTransitionState <> hntRecentlyRemoved) and
        EquivalencyCheck(FOldGeneration[j], Data[i]) then
        begin
          // The node matches the data - move the node to the next generation
          // under the (new) data's index
          FNodes[i] := FOldGeneration[j];
          FOldGeneration[j] := nil;
          FNodes[i].FIndex := i;
          FNodes[i].UpdateData(Data[i]);
          Break;
        end;

    // If no match, create a new node
    if not Assigned(FNodes[i]) then
    begin
      FNodes[i] := FNodeClass.Create;
      FNodes[i].UpdateData(Data[i]);
      FNodes[i].FNewlyAdded := True;
      FNodes[i].FIndex := i;
      FNodes[i].FTransitionTTL := EffectiveTTL;

      if FNodes[i].FTransitionTTL > 0 then
        FNodes[i].FTransitionState := hntRecentlyAdded
      else
        FNodes[i].FTransitionState := hntNormal;
    end;
  end;

  // Nodes without a match become recently removed but still merge
  for j := 0 to High(FOldGeneration) do
    if Assigned(FOldGeneration[j]) then
    begin
      if FOldGeneration[j].FTransitionState <> hntRecentlyRemoved then
      begin
        FOldGeneration[j].FTransitionState := hntRecentlyRemoved;
        FOldGeneration[j].FTransitionTTL := EffectiveTTL;
        FOldGeneration[j].FDeleted := FOldGeneration[j].FTransitionTTL <= 0;
      end;

      Step2bEnsureMerged(FOldGeneration[j]);
      FOldGeneration[j] := nil; // transferred ownership
    end;

  // Erase links (to be rebuilt on the next steps)
  for i := 0 to High(FNodes) do
  begin
    FNodes[i].FParent := nil;
    FNodes[i].FPreviousSibling := nil;
    FNodes[i].FNextSibling := nil;
    FNodes[i].FFirstChild := nil;
  end;
end;

// Move deleted nodes from the current generation to a dedicated array
procedure THysteresisTree.Step3ExtractDeleted;
var
  i, j, k: Integer;
  Previous: THysteresisNode;
begin
  // Free deleted nodes from the previous generation
  for k := 0 to High(FDeletedNodes) do
    FDeletedNodes[k].Free;

  // Count new deleted nodes
  k := 0;
  for i := 0 to High(FNodes) do
    if FNodes[i].FDeleted then
      Inc(k);

  // Extract them
  SetLength(FDeletedNodes, k);

  j := 0;
  k := 0;
  for i := 0 to High(FNodes) do
    if FNodes[i].FDeleted then
    begin
      // Move to the deleted list
      FDeletedNodes[k] := FNodes[i];
      FDeletedNodes[k].FIndex := k;
      Inc(k);
    end
    else
    begin
      // Compact non-deleted nodes and adjust indexes
      if i <> j then
      begin
        FNodes[j] := FNodes[i];
        FNodes[j].FIndex := j;
      end;

      Inc(j);
    end;

  // Trim after compaction
  SetLength(FNodes, j);

  // Link deleted nodes with each other
  Previous := nil;

  for k := 0 to High(FDeletedNodes) do
  begin
    FDeletedNodes[k].FPreviousSibling := Previous;

    if Assigned(Previous) then
      Previous.FNextSibling := FDeletedNodes[k];

    Previous := FDeletedNodes[k];
  end;
end;

// Link nodes based on parent-child relationships
procedure THysteresisTree.Step4BuildTree;
var
  i, j: Integer;
  Parent, Previous: THysteresisNode;
begin
  if FHasParentCheck then
  begin
    // Fill parent references
    for i := 0 to High(FNodes) do
      for j := 0 to High(FNodes) do
        if (i <> j) and ParentCheck(FNodes[j], FNodes[i]) then
        begin
          FNodes[i].FParent := FNodes[j];
          Break;
        end;

    // Verify there are no cycles
    for i := 0 to High(FNodes) do
    begin
      j := 0;
      Parent := FNodes[i].FParent;

      // Try to find the root which must be at most High(FNodes) away
      while Assigned(Parent) and (j <= High(FNodes)) do
      begin
        Parent := Parent.FParent;
        Inc(j);
      end;

      // A cycle detected; detach the parent to resolve it
      if Assigned(Parent) then
        FNodes[i].FParent := nil;
    end;

    // Fill the first child and sibling references for parented nodes
    for i := 0 to High(FNodes) do
    begin
      Previous := nil;

      for j := 0 to High(FNodes) do
        if FNodes[j].FParent = FNodes[i] then
        begin
          if not Assigned(FNodes[i].FFirstChild) then
            FNodes[i].FFirstChild := FNodes[j];

          FNodes[j].FPreviousSibling := Previous;

          if Assigned(Previous) then
            Previous.FNextSibling := FNodes[j];

          Previous := FNodes[j];
        end;
    end;
  end;

  // Fill sibling references for root nodes
  Previous := nil;

  for i := 0 to High(FNodes) do
    if not Assigned(FNodes[i].FParent) then
    begin
      FNodes[i].FPreviousSibling := Previous;

      if Assigned(Previous) then
        Previous.FNextSibling := FNodes[i];

      Previous := FNodes[i];
    end;
end;

procedure THysteresisTree.Update;
begin
  Step1AdvanceTTL;
  Step2MergeData(Data);
  Step3ExtractDeleted;
  Step4BuildTree;
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
  Result := FEquivalencyCheck(THysteresisNode<T>(Node).FData, T(Data^));
end;

function THysteresisTree<T>.GetDeletedNodes;
begin
  Result := TArray<THysteresisNode<T>>(FDeletedNodes);
end;

function THysteresisTree<T>.GetFirstDeletedNode;
begin
  if Length(FDeletedNodes) > 0 then
    Result := THysteresisNode<T>(FDeletedNodes[0])
  else
    Result := nil;
end;

function THysteresisTree<T>.GetFirstNode;
begin
  if Length(FNodes) > 0 then
    Result := THysteresisNode<T>(FNodes[0])
  else
    Result := nil;
end;

function THysteresisTree<T>.GetNodes;
begin
  Result := TArray<THysteresisNode<T>>(FNodes);
end;

class function THysteresisTree<T>.Initialize;
begin
  if not Assigned(EquivalencyCheck) then
    Error(reInvalidPtr);

  Result := THysteresisTree<T>.Create(EquivalencyCheck, ParentCheck, TTL);
end;

function THysteresisTree<T>.ParentCheck;
begin
  Result := FParentCheck(
    THysteresisNode<T>(Parent).FData,
    Parent.Index,
    THysteresisNode<T>(Child).FData,
    Child.Index
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
