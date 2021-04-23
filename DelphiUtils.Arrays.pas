unit DelphiUtils.Arrays;

{
  A collection of helper functions for working with arrays.
  Includes operations such as filtration, conversion, search, and grouping.
}

interface

type
  // Search and filtration

  TFilterAction = (ftKeep, ftExclude);

  TCondition<T> = reference to function (const Entry: T): Boolean;
  TVarCondition<T> = reference to function (var Entry: T): Boolean;

  TConditionEx<T> = reference to function (
    const Index: Integer;
    const Entry: T
  ): Boolean;

  TEqualityCheck<T> = reference to function (const A, B: T): Boolean;

  TComparer<T> = reference to function (const A, B: T): Integer;
  TBinaryCondition<T> = reference to function (const Entry: T): Integer;

  // Conversion

  TItemCallback<T> = reference to procedure (var Item: T);

  TMapRoutine<T1, T2> = reference to function (const Entry: T1): T2;

  TMapRoutineEx<T1, T2> = reference to function (
    const Index: Integer;
    const Entry: T1
  ): T2;

  TConvertRoutine<T1, T2> = reference to function (
    const Entry: T1;
    out ConvertedEntry: T2
  ): Boolean;

  TConvertRoutineEx<T1, T2> = reference to function (
    const Index: Integer;
    const Entry: T1;
    out ConvertedEntry: T2
  ): Boolean;

  // Grouping

  TArrayGroup<TKey, TValue> = record
    Key: TKey;
    Values: TArray<TValue>;
  end;

  // Other

  TGenerator<T> = reference to function (const Index: Integer): T;
  TAggregator<T> = reference to function (const A, B: T): T;

  TConflictChecker<TData, TChanges> = reference to function (
    const Data: TData;
    const Changes: TChanges
  ): Boolean;

  TConflictResolver<TData, TChanegs> = reference to function (
    const Existing: TData;
    const New: TChanegs
  ): TData;

  TTreeNode<T> = record
    Entry: T;
    Index: Integer;
    Parent: ^TTreeNode<T>;
    Children: TArray<^TTreeNode<T>>;
  end;

  TParentChecker<T> = reference to function (const Parent, Child: T): Boolean;

  TArray = class abstract
    { ------------------------ Conditional operations ------------------------ }

    // Filter an array on by-element basis
    class function Filter<T>(
      const Entries: TArray<T>;
      const Condition: TCondition<T>;
      Action: TFilterAction = ftKeep
    ): TArray<T>; static;

    // Filter an array on by-element basis
    class function FilterEx<T>(
      const Entries: TArray<T>;
      const Condition: TConditionEx<T>;
      Action: TFilterAction = ftKeep
    ): TArray<T>; static;

    // Filter an array on by-element basis modifiying the array
    class procedure FilterInline<T>(
      var Entries: TArray<T>;
      const Condition: TCondition<T>;
      Action: TFilterAction = ftKeep
    ); static;

    // Filter an array on by-element basis modifiying the array and its elements
    class procedure FilterInlineVar<T>(
      var Entries: TArray<T>;
      const Condition: TVarCondition<T>;
      Action: TFilterAction = ftKeep
    ); static;

    // Filter an array on by-element basis modifiying the array
    class procedure FilterInlineEx<T>(
      var Entries: TArray<T>;
      const Condition: TConditionEx<T>;
      Action: TFilterAction = ftKeep
    ); static;

    // Check if there is an element that matches a condition
    class function Any<T>(
      var Entries: TArray<T>;
      const Condition: TCondition<T>
    ): Boolean; static;

    // Count the amount of elements that match a condition
    class function Count<T>(
      var Entries: TArray<T>;
      const Condition: TCondition<T>
    ): Integer; static;

    // Find the first occurance of an entry that matches
    class function IndexOf<T>(
      const Entries: TArray<T>;
      const Condition: TCondition<T>
    ): Integer; static;

    // Sort an array using the Quick Sort algorithm
    class function Sort<T>(
      const Entries: TArray<T>;
      const Comparer: TComparer<T>
    ): TArray<T>; static;

    // Sort an array using Quick Sort
    class procedure SortInline<T>(
      var Entries: TArray<T>;
      const Comparer: TComparer<T>
    ); static;

    // Fast search for an element in a sorted array.
    //  - A non-negative result indicates an index.
    //  - A negative result indicates a location where to insert the new
    //    element by calling System.Insert(Value, Entries, -(Result + 1));
    class function BinarySearch<T>(
      const Entries: TArray<T>;
      const BinarySearcher: TBinaryCondition<T>
    ): Integer; static;

    // Check if any elements match
    class function Contains<T>(
      const Entries: TArray<T>;
      const Condition: TCondition<T>
    ): Boolean; static;

    // Check if any elements match
    class function ContainsEx<T>(
      const Entries: TArray<T>;
      const Condition: TConditionEx<T>
    ): Boolean; static;

    // Find the first matching entry or return a default value
    class function FindFirstOrDefault<T>(
      const Entries: TArray<T>;
      const Condition: TCondition<T>;
      const Default: T
    ): T; static;

    // Search within an array an remove second and later duplicates
    class function RemoveDuplicates<T>(
      const Entries: TArray<T>;
      const EqualityCheck: TEqualityCheck<T>
    ): TArray<T>; static;

    { ------------------------ Conversional operations ----------------------- }

    // Convert each array element into a different type
    class function Map<T1, T2>(
      const Entries: TArray<T1>;
      const Converter: TMapRoutine<T1, T2>
    ): TArray<T2>; static;

    // Convert each array element into a different type
    class function MapEx<T1, T2>(
      const Entries: TArray<T1>;
      const ConverterEx: TMapRoutineEx<T1, T2>
    ): TArray<T2>; static;

    // Try to convert each array element
    class function Convert<T1, T2>(
      const Entries: TArray<T1>;
      const Converter: TConvertRoutine<T1, T2>
    ): TArray<T2>; static;

    // Try to convert each array element
    class function ConvertEx<T1, T2>(
      const Entries: TArray<T1>;
      const ConverterEx: TConvertRoutineEx<T1, T2>
    ): TArray<T2>; static;

    // Convert the first convertable entry or return a default value
    class function ConvertFirstOrDefault<T1, T2>(
      const Entries: TArray<T1>;
      const Converter: TConvertRoutine<T1, T2>;
      const Default: T2
    ): T2; static;

    // Expand each element into an array and then concatenate them
    class function Flatten<T1, T2>(
      const Entries: TArray<T1>;
      const Converter: TMapRoutine<T1, TArray<T2>>
    ): TArray<T2>; static;

    { --------------------------- Other operations --------------------------- }

    // Reverse the order of the elements in an array
    class function Reverse<T>(
      const Entries: TArray<T>
    ): TArray<T>; static;

    // Execute a function for each element, potentially altering it
    class procedure ForAll<T>(
      var Entries: TArray<T>;
      const Callback: TItemCallback<T>
    ); static;

    // Group array elements by different keys
    class function GroupBy<TElement, TKey>(
      const Entries: TArray<TElement>;
      const LookupKey: TMapRoutine<TElement, TKey>;
      const CompareKeys: TEqualityCheck<TKey>
    ): TArray<TArrayGroup<TKey, TElement>>; static;

    // Construct an new array
    class function Generate<T>(
      const Count: Integer;
      const Generator: TGenerator<T>
    ): TArray<T>; static;

    // Combine pairs of elements until only one element is left.
    // Requires at least one element.
    class function Aggregate<T>(
      const Entries: TArray<T>;
      const Aggregator: TAggregator<T>
    ): T; static;

    // Combine pairs of elements until only one element is left.
    class function AggregateOrDefault<T>(
      const Entries: TArray<T>;
      const Aggregator: TAggregator<T>;
      const Default: T
    ): T; static;

    // Upadate existing items or add new ones into an ordered set by merging
    // changes and resolving conflicts.
    class function Merge<TData, TChanges>(
      const Data: TArray<TData>;
      const Changes: TArray<TChanges>;
      const CheckForConflicts: TConflictChecker<TData, TChanges>;
      const ResolveConflict: TConflictResolver<TData, TChanges>;
      const ConvertChange: TConvertRoutine<TChanges, TData>
    ): TArray<TData>; static;

    // Find all parent-child relationships in an array
    class function BuildTree<T>(
      const Entries: TArray<T>;
      const ParentChecker: TParentChecker<T>
    ): TArray<TTreeNode<T>>; static;
  end;

// Convert a list of zero-terminated strings into an array
function ParseMultiSz(
  Buffer: PWideChar;
  BufferLength: Cardinal
): TArray<String>;

{ Internal Use }

type
  // An anonymous callback for sorting. Internal use.
  TQsortContext = reference to function (
    KeyIndex: Integer;
    ElementIndex: Integer
  ): Integer;

// A CRT-compatible callback for sorting indexes. Internal use.
function SortCallback(
  context: Pointer;
  key: Pointer;
  element: Pointer
): Integer; cdecl;

implementation

uses
  Ntapi.crt;

{$R+}

{ TArray }

class function TArray.Aggregate<T>;
var
  i: Integer;
begin
  Assert(Length(Entries) <> 0, 'Cannot aggregate an empty array.');

  Result := Entries[0];

  for i := 1 to High(Entries) do
    Result := Aggregator(Result, Entries[i]);
end;

class function TArray.AggregateOrDefault<T>;
var
  i: Integer;
begin
  if Length(Entries) = 0 then
    Exit(Default);

  Result := Entries[0];

  for i := 1 to High(Entries) do
    Result := Aggregator(Result, Entries[i]);
end;

class function TArray.Any<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(True);

  Result := False;
end;

class function TArray.BinarySearch<T>;
var
  Start, Finish, Middle: Integer;
  AtStart, AtFinish: Integer;
begin
  if Length(Entries) = 0 then
    Exit(-1);

  // Start with full range
  Start := Low(Entries);
  Finish := High(Entries);

  while Start <> Finish do
  begin
    Middle := (Start + Finish) shr 1;

    // Prevent infinite loops
    if Middle = Start then
      Break;

    // Move one boundary into the middle on each iteration
    if BinarySearcher(Entries[Middle]) < 0 then
      Start := Middle
    else
      Finish := Middle;
  end;

  // Compare to the start
  AtStart := BinarySearcher(Entries[Start]);

  // Found at start
  if AtStart = 0 then
    Exit(Start);

  // Compare to the finish
  AtFinish := BinarySearcher(Entries[Finish]);

  // Found at finish
  if AtFinish = 0 then
    Exit(Finish);

  // Insert between start and finish
  if (AtStart < 0) xor (AtFinish < 0) then
    Exit(-Start - 2);

  // Insert after finish
  if AtFinish < 0 then
    Exit(-Finish - 2);

  // Insert before start
  Exit(-1);
end;

class function TArray.BuildTree<T>;
var
  i, j, k, Count: Integer;
begin
  SetLength(Result, Length(Entries));

  // Copy entries
  for i := 0 to High(Entries) do
  begin
    Result[i].Entry := Entries[i];
    Result[i].Index := i;
  end;

  // Fill parents as references to array elements
  for i := 0 to High(Entries) do
    for j := 0 to High(Entries) do
      if (i <> j) and ParentChecker(Entries[j], Entries[i]) then
      begin
        Result[i].Parent := @Result[j];
        Break;
      end;

  // Fill children, also as references
  for i := 0 to High(Entries) do
  begin
    Count := 0;
    for j := 0 to High(Entries) do
      if Result[j].Parent = @Result[i] then
        Inc(Count);

    SetLength(Result[i].Children, Count);

    k := 0;
    for j := 0 to High(Entries) do
      if Result[j].Parent = @Result[i] then
      begin
        Result[i].Children[k] := @Result[j];
        Inc(k);
      end;
  end;
end;

class function TArray.Contains<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(True);

  Result := False;
end;

class function TArray.ContainsEx<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(i, Entries[i]) then
      Exit(True);

  Result := False;
end;

class function TArray.Convert<T1, T2>;
var
  i, j: Integer;
begin
  SetLength(Result, Length(Entries));

  j := 0;
  for i := 0 to High(Entries) do
    if Converter(Entries[i], Result[j]) then
      Inc(j);

  SetLength(Result, j);
end;

class function TArray.ConvertEx<T1, T2>;
var
  i, j: Integer;
begin
  SetLength(Result, Length(Entries));

  j := 0;
  for i := 0 to High(Entries) do
    if ConverterEx(i, Entries[i], Result[j]) then
      Inc(j);

  SetLength(Result, j);
end;

class function TArray.ConvertFirstOrDefault<T1, T2>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Converter(Entries[i], Result) then
      Exit;

  Result := Default;
end;

class function TArray.Count<T>;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Inc(Result);
end;

class function TArray.Filter<T>;
var
  i, Count: Integer;
begin
  SetLength(Result, Length(Entries));

  Count := 0;
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) xor (Action = ftExclude) then
    begin
      Result[Count] := Entries[i];
      Inc(Count);
    end;

  SetLength(Result, Count);
end;

class function TArray.FilterEx<T>;
var
  i, Count: Integer;
begin
  SetLength(Result, Length(Entries));

  Count := 0;
  for i := 0 to High(Entries) do
    if Condition(i, Entries[i]) xor (Action = ftExclude) then
    begin
      Result[Count] := Entries[i];
      Inc(Count);
    end;

  SetLength(Result, Count);
end;

class procedure TArray.FilterInline<T>;
var
  i, j: Integer;
begin
  j := 0;
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) xor (Action = ftExclude) then
    begin
      // j grows slower then i, move elements backwards overwriting ones that
      // don't match
      if i <> j then
        Entries[j] := Entries[i];

      Inc(j);
    end;

  SetLength(Entries, j);
end;

class procedure TArray.FilterInlineEx<T>;
var
  i, j: Integer;
begin
  j := 0;
  for i := 0 to High(Entries) do
    if Condition(i, Entries[i]) xor (Action = ftExclude) then
    begin
      // j grows slower then i, move elements backwards overwriting ones that
      // don't match
      if i <> j then
        Entries[j] := Entries[i];

      Inc(j);
    end;

  SetLength(Entries, j);
end;

class procedure TArray.FilterInlineVar<T>;
var
  i, j: Integer;
begin
  j := 0;
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) xor (Action = ftExclude) then
    begin
      // j grows slower then i, move elements backwards overwriting ones that
      // don't match
      if i <> j then
        Entries[j] := Entries[i];

      Inc(j);
    end;

  SetLength(Entries, j);
end;

class function TArray.FindFirstOrDefault<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(Entries[i]);

  Result := Default;
end;

class function TArray.Flatten<T1, T2>;
var
  Expanded: TArray<TArray<T2>>;
  i, j, Count: Integer;
begin
  // Convert each element into an array
  Expanded := TArray.Map<T1, TArray<T2>>(Entries, Converter);

  // Count total elements
  Count := 0;
  for i := 0 to High(Expanded) do
    Inc(Count, Length(Expanded[i]));

  SetLength(Result, Count);

  // Flatten them into one array
  Count := 0;
  for i := 0 to High(Expanded) do
    for j := 0 to High(Expanded[i]) do
    begin
      Result[Count] := Expanded[i, j];
      Inc(Count);
    end;
end;

class procedure TArray.ForAll<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    Callback(Entries[i]);
end;

class function TArray.Generate<T>;
var
  i: Integer;
begin
  SetLength(Result, Count);

  for i := 0 to High(Result) do
    Result[i] := Generator(i);
end;

class function TArray.GroupBy<TElement, TKey>;
var
  i, j, Count: Integer;
  KeyIndexes: TArray<Integer>;
  Found: Boolean;
  Key: TKey;
begin
  SetLength(KeyIndexes, Length(Entries));
  SetLength(Result, Length(Entries));
  Count := 0;

  for i := 0 to High(Entries) do
  begin
    Key := LookupKey(Entries[i]);
    Found := False;

    // Check if we already encountered this key
    for j := Pred(Count) downto 0 do
      if CompareKeys(Key, Result[j].Key) then
      begin
        // Attach the entry to this bucket
        KeyIndexes[i] := j;
        Found := True;
        Break;
      end;

    if not Found then
    begin
      // Create a new bucket for this key
      Result[Count].Key := Key;
      KeyIndexes[i] := Count;
      Inc(Count);
    end;
  end;

  // Trim the array of groups
  SetLength(Result, Count);

  for j := 0 to High(Result) do
  begin
    Count := 0;

    // Count the amount of elements that belong to this key
    for i := 0 to High(KeyIndexes) do
      if KeyIndexes[i] = j then
        Inc(Count);

    SetLength(Result[j].Values, Count);
    Count := 0;

    // Copy entries for the key
    for i := 0 to High(KeyIndexes) do
      if KeyIndexes[i] = j then
      begin
        Result[j].Values[Count] := Entries[i];
        Inc(Count);
      end;
  end;
end;

class function TArray.IndexOf<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(i);

  Result := -1;
end;

class function TArray.Map<T1, T2>;
var
  i: Integer;
begin
  SetLength(Result, Length(Entries));

  for i := 0 to High(Entries) do
    Result[i] := Converter(Entries[i]);
end;

class function TArray.MapEx<T1, T2>;
var
  i: Integer;
begin
  SetLength(Result, Length(Entries));

  for i := 0 to High(Entries) do
    Result[i] := ConverterEx(i, Entries[i]);
end;

class function TArray.Merge<TData, TChanges>;
var
  ConflictIndexes: TArray<Integer>;
  NewEntries: TArray<TData>;
  i, j: Integer;
begin
  SetLength(ConflictIndexes, Length(Changes));

  // Find indexes of data entires with wich we have conflicts
  for i := 0 to High(Changes) do
  begin
    ConflictIndexes[i] := -1;

    for j := 0 to High(Data) do
      if CheckForConflicts(Data[j], Changes[i]) then
      begin
        ConflictIndexes[i] := j;
        Break;
      end;
  end;

  Result := Copy(Data, 0, Length(Data));

  // Overwrite each data entry that is conflicting by using a conflict resolver
  for i := 0 to High(ConflictIndexes) do
    if ConflictIndexes[i] >= 0 then
      Result[ConflictIndexes[i]] := ResolveConflict(Data[ConflictIndexes[i]],
        Changes[i]);

  // Count non-conflicting changes
  j := 0;
  for i := 0 to High(ConflictIndexes) do
    if ConflictIndexes[i] < 0 then
      Inc(j);

  // We need to convert the changes and add them to the result
  if j > 0 then
  begin
    SetLength(NewEntries, j);

    // Convert
    j := 0;
    for i := 0 to High(ConflictIndexes) do
    if ConflictIndexes[i] < 0 then
      if ConvertChange(Changes[i], NewEntries[j]) then
        Inc(j);

    // Combine
    SetLength(NewEntries, j);
    Result := Concat(Result, NewEntries);
  end;
end;

class function TArray.RemoveDuplicates<T>;
var
  Including: TArray<Boolean>;
begin
  // If we decided to exclude an item, we should not compare it anymore
  SetLength(Including, Length(Entries));

  Result := TArray.FilterEx<T>(Entries,
    function (const Index: Integer; const Entry: T): Boolean
    var
      i: Integer;
    begin
      Result := True;

      // Check if already included items contain a similar one
      for i := Pred(Index) downto 0 do
        if Including[i] and EqualityCheck(Entries[i], Entry) then
        begin
          Result := False;
          Break;
        end;

      Including[Index] := Result;
    end
  );
end;

class function TArray.Reverse<T>;
var
  i: Integer;
begin
  SetLength(Result, Length(Entries));

  for i := 0 to High(Entries) do
    Result[High(Entries) - i] := Entries[i];
end;

// A CRT-compatible callback for sorting
function SortCallback;
var
  SmartContext: TQsortContext absolute context;
begin
  Result := SmartContext(Integer(Key^), Integer(Element^));
end;

class function TArray.Sort<T>;
var
  Indexes: TArray<Integer>;
  i: Integer;
  IndexComparer: TQsortContext;
  Context: Pointer absolute IndexComparer;
begin
  // Instead of implementing the algorithm ourselves (which can be error prone
  // and result in an inefficient code), delegate the sorting to the CRT
  // function from ntdll. However, since it is not aware of Delphi's data types,
  // we cannot use it directly on the array (because it can potentially contain
  // weak interface references which must be moved only using the built-in
  // Delphi mechanisms). As a solution, sort an array of element indexes
  // instead, comparing the elements on each index. Then construct the result
  // using the new order.

  // Generate the intial index list
  SetLength(Indexes, Length(Entries));

  for i := 0 to High(Indexes) do
    Indexes[i] := i;

  // Prepare the anonymous function for comparing indexes via elements
  IndexComparer := function (
      KeyIndex: Integer;
      ElementIndex: Integer
    ): Integer
    begin
      Result := Comparer(Entries[KeyIndex], Entries[ElementIndex]);
    end;

  // Sort the indexes
  qsort_s(Pointer(Indexes), Length(Indexes), SizeOf(Integer), SortCallback,
    Context);

  // Construct the sorted array
  SetLength(Result, Length(Entries));

  for i := 0 to High(Result) do
    Result[i] := Entries[Indexes[i]];
end;

class procedure TArray.SortInline<T>;
begin
  Entries := TArray.Sort<T>(Entries, Comparer);
end;

{ Functions }

function ParseMultiSz;
var
  Count, j: Integer;
  pCurrentChar, pItemStart, pBlockEnd: PWideChar;
begin
  // Save where the buffer ends to make sure we don't pass this point
  pBlockEnd := Buffer + BufferLength;

  // Count strings
  Count := 0;
  pCurrentChar := Buffer;

  while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
  begin
    // Skip one zero-terminated string
    while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
      Inc(pCurrentChar);

    Inc(Count);
    Inc(pCurrentChar);
  end;

  SetLength(Result, Count);

  // Save the content
  j := 0;
  pCurrentChar := Buffer;

  while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
  begin
    // Parse one string
    Count := 0;
    pItemStart := pCurrentChar;

    while (pCurrentChar < pBlockEnd) and (pCurrentChar^ <> #0) do
    begin
      Inc(pCurrentChar);
      Inc(Count);
    end;

    // Save it
    SetString(Result[j], pItemStart, Count);

    Inc(j);
    Inc(pCurrentChar);
  end;
end;

end.
