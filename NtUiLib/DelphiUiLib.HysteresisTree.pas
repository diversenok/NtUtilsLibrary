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

  THysteresisNode<T> = class
  private
    FData: T;
    FParent: THysteresisNode<T>;
    FPreviousSibling: THysteresisNode<T>;
    FNextSibling: THysteresisNode<T>;
    FChildren: TArray<THysteresisNode<T>>;
    FRelatedNode: THysteresisNode<T>;
    FIndex: Integer;
    FTransitionTTL: Integer;
    FState: THysteresisNodeState;
    FDeleted: Boolean;
  public
    property Data: T read FData;
    property Parent: THysteresisNode<T> read FParent;
    property PreviousSibling: THysteresisNode<T> read FPreviousSibling;
    property NextSibling: THysteresisNode<T> read FNextSibling;
    property Children: TArray<THysteresisNode<T>> read FChildren;
    property Index: Integer read FIndex;
    property TransitionTTL: Integer read FTransitionTTL;
    property State: THysteresisNodeState read FState;
  end;

  IHystereisTree<T> = interface
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

  THystereisTree<T> = class (TInterfacedObject, IHystereisTree<T>)
  private
    FCurrentNodes, FNewNodes: TArray<THysteresisNode<T>>;
    FEqualityCheck: TEqualityCheck<T>;
    [opt] FParentCheck: TParentChecker<T>;
    FDefaultTTL: Integer;
    FFirstUpdateComplete: Boolean;
    function EffectiveTTL: Integer;
    function GetNodes: TArray<THysteresisNode<T>>;
    function GetTransitionTime: Integer;
    procedure SetTransitionTime(Value: Integer);
    procedure Update(const Entries: TArray<T>);
    procedure Step1AdvanceTTL;
    procedure Step2ConvertEntries(const Entries: TArray<T>);
    procedure Step3LinkRelatedNodes;
    procedure Step4aInsertAt(NewNode: THysteresisNode<T>; Index: Integer);
    procedure Step4bEnsureInserted(OldNode: THysteresisNode<T>);
    procedure Step4InsertRecentlyRemoved;
    procedure Step5CleanupAndSwapLists;
    procedure Step6BuildTree;
    constructor Create(
      const EqualityCheck: TEqualityCheck<T>;
      [opt] const ParentCheck: TParentChecker<T>;
      [opt] TTL: Integer
    );
  public
    destructor Destroy; override;

    // Make an empty tree instance
    class function Initialize(
      const EqualityCheck: TEqualityCheck<T>;
      [opt] const ParentCheck: TParentChecker<T> = nil;
      [opt] TTL: Integer = 0
    ): IHystereisTree<T>; static;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ THystereisTree<T> }

constructor THystereisTree<T>.Create;
begin
  inherited Create;

  if not Assigned(EqualityCheck) then
    Error(reInvalidPtr);

  FEqualityCheck := EqualityCheck;
  FParentCheck := ParentCheck;
  FDefaultTTL := TTL;
end;

destructor THystereisTree<T>.Destroy;
var
  Node: THysteresisNode<T>;
begin
  for Node in FCurrentNodes do
    Node.Free;

  FCurrentNodes := nil;
  inherited;
end;

function THystereisTree<T>.EffectiveTTL;
begin
  if FFirstUpdateComplete then
    Result := FDefaultTTL
  else
    Result := 0; // Suppress recently added state on the first update
end;

function THystereisTree<T>.GetNodes;
begin
  Result := FCurrentNodes;
end;

function THystereisTree<T>.GetTransitionTime;
begin
  Result := FDefaultTTL;
end;

class function THystereisTree<T>.Initialize;
begin
  Result := THystereisTree<T>.Create(EqualityCheck, ParentCheck, TTL);
end;

procedure THystereisTree<T>.SetTransitionTime;
begin
  if Value < 0 then
    FDefaultTTL := 0
  else
    FDefaultTTL := Value;
end;

// Advance state for recently added and removed nodes
procedure THystereisTree<T>.Step1AdvanceTTL;
var
  Node: THysteresisNode<T>;
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
procedure THystereisTree<T>.Step2ConvertEntries;
var
  i: Integer;
begin
  SetLength(FNewNodes, Length(Entries));

  for i := 0 to High(Entries) do
  begin
    // When TTL is enabled, assume all new entries as recently added until we
    // find them a match among the old ones.
    FNewNodes[i] := THysteresisNode<T>.Create;
    FNewNodes[i].FData := Entries[i];

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
procedure THystereisTree<T>.Step3LinkRelatedNodes;
var
  OldNode, NewNode: THysteresisNode<T>;
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
          FEqualityCheck(NewNode.FData, OldNode.FData) then
        begin
          // Link nodes and copy the state to the new node
          OldNode.FRelatedNode := NewNode;
          NewNode.FRelatedNode := OldNode;
          NewNode.FState := OldNode.FState;
          NewNode.FTransitionTTL := OldNode.FTransitionTTL;
          Break;
        end;
end;

// A helper for inserting a node at a specific location
procedure THystereisTree<T>.Step4aInsertAt;
var
  i: Integer;
begin
  System.Insert(NewNode, FNewNodes, Index);

  // Update cached indexes to keep them correct
  for i := Index to High(FNewNodes) do
    FNewNodes[i].FIndex := i;
end;

// Insert an old node into the new list if necessary
procedure THystereisTree<T>.Step4bEnsureInserted;
var
  NewNode: THysteresisNode<T>;
  Index: Integer;
begin
  // Already complete?
  if Assigned(OldNode.FRelatedNode) then
    Exit;

  // Prepare a new node. At this stage, only recently removed ones remain
  NewNode := THysteresisNode<T>.Create;
  NewNode.FData := OldNode.FData;
  NewNode.FState := hnsRecentlyRemoved;

  if OldNode.State = hnsRecentlyRemoved then
    NewNode.FTransitionTTL := OldNode.FTransitionTTL
  else
    NewNode.FTransitionTTL := EffectiveTTL;

  NewNode.FDeleted := OldNode.FDeleted or (NewNode.FTransitionTTL <= 0);

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
procedure THystereisTree<T>.Step4InsertRecentlyRemoved;
var
  OldNode: THysteresisNode<T>;
begin
  // Process all nodes that are not inserted yet
  for OldNode in FCurrentNodes do
    if not Assigned(OldNode.FRelatedNode) then
      Step4bEnsureInserted(OldNode);
end;

// Remove deleted nodes and clear links
procedure THystereisTree<T>.Step5CleanupAndSwapLists;
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
procedure THystereisTree<T>.Step6BuildTree;
var
  i, j, k, Count: Integer;
  Parent, Previous: THysteresisNode<T>;
begin
  if Assigned(FParentCheck) then
  begin
    // Fill parent references
    for i := 0 to High(FCurrentNodes) do
      for j := 0 to High(FCurrentNodes) do
        if (i <> j) and FParentCheck(FCurrentNodes[j].FData,
          FCurrentNodes[i].FData) then
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
          FCurrentNodes[i].FChildren[j].FPreviousSibling := FCurrentNodes[i].FChildren[j - 1];

        if j < High(FCurrentNodes[i].FChildren) then
          FCurrentNodes[i].FChildren[j].FNextSibling := FCurrentNodes[i].FChildren[j + 1];
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

procedure THystereisTree<T>.Update;
begin
  Step1AdvanceTTL;
  Step2ConvertEntries(Entries);
  Step3LinkRelatedNodes;
  Step4InsertRecentlyRemoved;
  Step5CleanupAndSwapLists;
  Step6BuildTree;
  FFirstUpdateComplete := True;
end;

end.
