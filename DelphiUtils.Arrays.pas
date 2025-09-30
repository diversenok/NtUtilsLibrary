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

  TDuplicateHandling = (dhInsert, dhOverwrite, dhSkip);

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

  TConflictResolver<TData, TChanges> = reference to function (
    const Existing: TData;
    const New: TChanges
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
      Condition: TCondition<T>;
      Action: TFilterAction = ftKeep
    ): TArray<T>; static;

    // Filter an array on by-element basis
    class function FilterEx<T>(
      const Entries: TArray<T>;
      Condition: TConditionEx<T>;
      Action: TFilterAction = ftKeep
    ): TArray<T>; static;

    // Filter an array on by-element basis modifying the array
    class procedure FilterInline<T>(
      var Entries: TArray<T>;
      Condition: TCondition<T>;
      Action: TFilterAction = ftKeep
    ); static;

    // Filter an array on by-element basis modifying the array and its elements
    class procedure FilterInlineVar<T>(
      var Entries: TArray<T>;
      Condition: TVarCondition<T>;
      Action: TFilterAction = ftKeep
    ); static;

    // Filter an array on by-element basis modifying the array
    class procedure FilterInlineEx<T>(
      var Entries: TArray<T>;
      Condition: TConditionEx<T>;
      Action: TFilterAction = ftKeep
    ); static;

    // Sort an array using the Quick Sort algorithm
    class function Sort<T>(
      const Entries: TArray<T>;
      Comparer: TComparer<T> = nil
    ): TArray<T>; static;

    // Sort an array using Quick Sort
    class procedure SortInline<T>(
      var Entries: TArray<T>;
      Comparer: TComparer<T> = nil
    ); static;

    // Fast search for an element in a sorted array.
    //  - A non-negative result indicates an index.
    //  - A negative result indicates a location where to insert the new
    //    element by calling System.Insert(Value, Entries, -(Result + 1));
    // NOTE: do not use the default comparer with signed integer types
    class function BinarySearch<T>(
      const Entries: TArray<T>;
      const Element: T;
      Comparer: TComparer<T> = nil;
      ReversedOrder: Boolean = False
    ): Integer; static;

    // Insert an element into a sorted array preserving sorting. The return
    // value has the same semantic as the binary search.
    class function InsertSorted<T>(
      var Entries: TArray<T>;
      const Element: T;
      DuplicateHandling: TDuplicateHandling;
      Comparer: TComparer<T> = nil;
      ReversedOrder: Boolean = False
    ): Integer; static;

    // Fast search for an element in a sorted array.
    class function BinarySearchEx<T>(
      const Entries: TArray<T>;
      BinarySearcher: TBinaryCondition<T>
    ): Integer; static;

    // Check if the array contains a specific element
    class function Contains<T>(
      const Entries: TArray<T>;
      const Element: T;
      EqualityCheck: TEqualityCheck<T> = nil
    ): Boolean; static;

    // Check if any elements match
    class function ContainsMatch<T>(
      const Entries: TArray<T>;
      Condition: TCondition<T>
    ): Boolean; static;

    // Check if any elements match
    class function ContainsMatchEx<T>(
      const Entries: TArray<T>;
      Condition: TConditionEx<T>
    ): Boolean; static;

    // Count the number of elements that are equal to the specified
    class function Count<T>(
      var Entries: TArray<T>;
      const Element: T;
      EqualityCheck: TEqualityCheck<T> = nil
    ): Integer; static;

    // Count the number of elements that match a condition
    class function CountMatches<T>(
      var Entries: TArray<T>;
      Condition: TCondition<T>
    ): Integer; static;

    // Find the position of the first occurrence of an element
    class function IndexOf<T>(
      const Entries: TArray<T>;
      const Element: T;
      EqualityCheck: TEqualityCheck<T> = nil
    ): Integer; static;

    // Find the position of the first occurrence of an element that matches
    // a condition
    class function IndexOfMatch<T>(
      const Entries: TArray<T>;
      Condition: TCondition<T>
    ): Integer; static;

    // Find the first matching element or return a Default(T)
    class function FindFirst<T>(
      const Entries: TArray<T>;
      Condition: TCondition<T>
    ): T; static;

    // Find the first matching element or return the specified default
    class function FindFirstOrDefault<T>(
      const Entries: TArray<T>;
      Condition: TCondition<T>;
      const Default: T
    ): T; static;

    // Try to find the first matching element
    class function TryFindFirst<T>(
      const Entries: TArray<T>;
      Condition: TCondition<T>;
      out Element: T
    ): Boolean; static;

    // Search within an array and remove the second and subsequent duplicates
    class function RemoveDuplicates<T>(
      const Entries: TArray<T>;
      EqualityCheck: TEqualityCheck<T> = nil
    ): TArray<T>; static;

    { ------------------------ Conversional operations ----------------------- }

    // Convert each array element into a different type
    class function Map<T1, T2>(
      const Entries: TArray<T1>;
      Converter: TMapRoutine<T1, T2>
    ): TArray<T2>; static;

    // Convert each array element into a different type
    class function MapEx<T1, T2>(
      const Entries: TArray<T1>;
      ConverterEx: TMapRoutineEx<T1, T2>
    ): TArray<T2>; static;

    // Try to convert each array element
    class function Convert<T1, T2>(
      const Entries: TArray<T1>;
      Converter: TConvertRoutine<T1, T2>
    ): TArray<T2>; static;

    // Try to convert each array element
    class function ConvertEx<T1, T2>(
      const Entries: TArray<T1>;
      ConverterEx: TConvertRoutineEx<T1, T2>
    ): TArray<T2>; static;

    // Convert the first convertible entry or return Default(T2)
    class function ConvertFirst<T1, T2>(
      const Entries: TArray<T1>;
      Converter: TConvertRoutine<T1, T2>
    ): T2; static;

    // Convert the first convertible entry or return the specified default
    class function ConvertFirstOrDefault<T1, T2>(
      const Entries: TArray<T1>;
      Converter: TConvertRoutine<T1, T2>;
      const Default: T2
    ): T2; static;

    // Concatenate an array of arrays into a single array
    class function Flatten<T>(
      const Arrays: TArray<TArray<T>>
    ): TArray<T>; static;

    // Expand each element into an array and then concatenate them
    class function FlattenEx<T1, T2>(
      const Entries: TArray<T1>;
      Converter: TMapRoutine<T1, TArray<T2>>
    ): TArray<T2>; static;

    { --------------------------- Other operations --------------------------- }

    // Create an array from an iterator
    class function Collect<T>(
      const Iterator: IEnumerable<T>
    ): TArray<T>; static;

    // Reverse the order of the elements in an array
    class function Reverse<T>(
      const Entries: TArray<T>
    ): TArray<T>; static;

    // Execute a function for each element, potentially altering it
    class procedure ForAll<T>(
      var Entries: TArray<T>;
      Callback: TItemCallback<T>
    ); static;

    // Group array elements by different keys
    class function GroupBy<TElement, TKey>(
      const Entries: TArray<TElement>;
      LookupKey: TMapRoutine<TElement, TKey>;
      CompareKeys: TEqualityCheck<TKey> = nil
    ): TArray<TArrayGroup<TKey, TElement>>; static;

    // Construct an new array element-by-element
    class function Generate<T>(
      const Count: Integer;
      Generator: TGenerator<T>
    ): TArray<T>; static;

    // Combine pairs of elements until only one element is left.
    // Returns Default(T) for empty input.
    class function Aggregate<T>(
      const Entries: TArray<T>;
      Aggregator: TAggregator<T>
    ): T; static;

    // Combine pairs of elements until only one element is left.
    // Returns the specified default for empty input.
    class function AggregateOrDefault<T>(
      const Entries: TArray<T>;
      Aggregator: TAggregator<T>;
      const Default: T
    ): T; static;

    // Update existing items or add new ones into an ordered set by merging
    // changes and resolving conflicts.
    class function Merge<TData, TChanges>(
      const Data: TArray<TData>;
      const Changes: TArray<TChanges>;
      CheckForConflicts: TConflictChecker<TData, TChanges>;
      ResolveConflict: TConflictResolver<TData, TChanges>;
      ConvertChange: TConvertRoutine<TChanges, TData>
    ): TArray<TData>; static;

    // Find all parent-child relationships in an array
    class function BuildTree<T>(
      const Entries: TArray<T>;
      ParentChecker: TParentChecker<T>
    ): TArray<TTreeNode<T>>; static;

    { --------------------------- Helper functions --------------------------- }

    // A default function for checking equality of array elements
    class function DefaultEqualityCheck<T>(const A, B: T): Boolean; static;

    // A default function for ordering array elements.
    // NOTE: the functions treats integers as unsigned
    class function DefaultComparer<T>(const A, B: T): Integer; static;
  end;

{ Internal Use }

type
  // An anonymous callback for sorting. Internal use.
  TQsortContext = reference to function (
    KeyIndex: Integer;
    ElementIndex: Integer
  ): Integer;

// Index comparer for the legacy qsort. Internal use only.
threadvar
  SmartContextLegacy: TQsortContext;

// A CRT-compatible callback for sorting indexes on Win 7. Internal use.
function SortCallbackLegacy(
  key: Pointer;
  element: Pointer
): Integer; cdecl;

// A CRT-compatible callback for sorting indexes on Win 8+. Internal use.
function SortCallback(
  context: Pointer;
  key: Pointer;
  element: Pointer
): Integer; cdecl;

implementation

uses
  Ntapi.crt, Ntapi.ntdef, NtUtils, NtUtils.Ldr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TArray }

class function TArray.Aggregate<T>;
begin
  Result := AggregateOrDefault<T>(Entries, Aggregator, Default(T));
end;

class function TArray.AggregateOrDefault<T>;
var
  i: Integer;
begin
  if Length(Entries) <= 0 then
    Exit(Default);

  Result := Entries[0];

  for i := 1 to High(Entries) do
    Result := Aggregator(Result, Entries[i]);
end;

class function TArray.BinarySearch<T>;
begin
  if not Assigned(Comparer) then
    Comparer := DefaultComparer<T>;

  try
    Result := BinarySearchEx<T>(Entries,
      function (const Entry: T): Integer
      begin
        Result := Comparer(Entry, Element);

        if ReversedOrder then
          Result := -Result;
      end
    );
  finally
    // For some reason, the anonymous function from above doesn't want to
    // capture ownership over the default comparer. Explicitly release the
    // variable here as a workaround.
    Comparer := nil;
  end;
end;

class function TArray.BinarySearchEx<T>;
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

class function TArray.Collect<T>;
var
  Element: T;
begin
  Result := nil;

  for Element in Iterator do
  begin
    SetLength(Result, Succ(Length(Result)));
    Result[High(Result)] := Element;
  end;
end;

class function TArray.Contains<T>;
var
  i: Integer;
begin
  if not Assigned(EqualityCheck) then
    EqualityCheck := DefaultEqualityCheck<T>;

  for i := 0 to High(Entries) do
    if EqualityCheck(Entries[i], Element) then
      Exit(True);

  Result := False;
end;

class function TArray.ContainsMatch<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(True);

  Result := False;
end;

class function TArray.ContainsMatchEx<T>;
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

  // Trim failed conversions
  if Length(Result) <> j then
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

  // Trim failed conversions
  if Length(Result) <> j then
    SetLength(Result, j);
end;

class function TArray.ConvertFirst<T1, T2>;
begin
  Result := ConvertFirstOrDefault<T1, T2>(Entries, Converter, Default(T2));
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
  if not Assigned(EqualityCheck) then
    EqualityCheck := DefaultEqualityCheck<T>;

  Result := 0;
  for i := 0 to High(Entries) do
    if EqualityCheck(Entries[i], Element) then
      Inc(Result);
end;

class function TArray.CountMatches<T>;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Inc(Result);
end;

class function TArray.DefaultComparer<T>;
var
  StringA: String absolute A;
  StringB: String absolute B;
  AnsiStringA: AnsiString absolute A;
  AnsiStringB: AnsiString absolute B;
begin
  if TypeInfo(T) = TypeInfo(String) then
    Result := wcscmp(PWideChar(StringA), PWideChar(StringB))
  else if TypeInfo(T) = TypeInfo(AnsiString) then
    Result := strcmp(PAnsiChar(AnsiStringA), PAnsiChar(AnsiStringB))
  else
    Result := memcmp(@A, @B, SizeOf(T));

end;

class function TArray.DefaultEqualityCheck<T>;
var
  StringA: String absolute A;
  StringB: String absolute B;
  AnsiStringA: AnsiString absolute A;
  AnsiStringB: AnsiString absolute B;
begin
  if TypeInfo(T) = TypeInfo(String) then
    Result := StringA = StringB
  else if TypeInfo(T) = TypeInfo(AnsiString) then
    Result := AnsiStringA = AnsiStringB
  else
    Result := memcmp(@A, @B, SizeOf(T)) = 0;
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

  // Trim unused slots
  if Length(Result) <> Count then
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

  // Trim unused slots
  if Length(Result) <> Count then
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
      // j grows slower then i; move elements backwards overwriting ones that
      // don't match
      if i <> j then
        Entries[j] := Entries[i];

      Inc(j);
    end;

  // Trim released slots
  if Length(Entries) <> j then
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
      // j grows slower then i; move elements backwards overwriting ones that
      // don't match
      if i <> j then
        Entries[j] := Entries[i];

      Inc(j);
    end;

  // Trim released slots
  if Length(Entries) <> j then
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
      // j grows slower then i; move elements backwards overwriting ones that
      // don't match
      if i <> j then
        Entries[j] := Entries[i];

      Inc(j);
    end;

  // Trim released slots
  if Length(Entries) <> j then
    SetLength(Entries, j);
end;

class function TArray.FindFirst<T>;
begin
  Result := FindFirstOrDefault<T>(Entries, Condition, Default(T));
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

class function TArray.Flatten<T>;
var
  Count, i, j: Integer;
begin
  // No need to copy when provided with a single array
  if Length(Arrays) = 1 then
    Exit(Arrays[0]);

  // Compute the total number of elements
  Count := 0;
  for i := 0 to High(Arrays) do
    Inc(Count, Length(Arrays[i]));

  SetLength(Result, Count);

  // Fill them preserving order
  Count := 0;
  for i := 0 to High(Arrays) do
    for j := 0 to High(Arrays[i]) do
    begin
      Result[Count] := Arrays[i][j];
      Inc(Count);
    end;
end;

class function TArray.FlattenEx<T1, T2>;
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
  if not Assigned(CompareKeys) then
    CompareKeys := DefaultEqualityCheck<TKey>;

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

  // Trim unused buckets
  if Length(Result) <> Count then
    SetLength(Result, Count);

  for j := 0 to High(Result) do
  begin
    Count := 0;

    // Count the number of elements that belong to this key
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
  if not Assigned(EqualityCheck) then
    EqualityCheck := DefaultEqualityCheck<T>;

  for i := 0 to High(Entries) do
    if EqualityCheck(Entries[i], Element) then
      Exit(i);

  Result := -1;
end;

class function TArray.IndexOfMatch<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(i);

  Result := -1;
end;

class function TArray.InsertSorted<T>;
begin
  Result := BinarySearch<T>(Entries, Element, Comparer, ReversedOrder);

  if Result < 0 then
    System.Insert(Element, Entries, -(Result + 1)) // No collisions; insert
  else if DuplicateHandling = dhInsert then
    System.Insert(Element, Entries, Result) // Collision; insert anyway
  else if DuplicateHandling = dhOverwrite then
    Entries[Result] := Element // Collision; overwrite
  else if DuplicateHandling = dhSkip then
    ; // Collision; skip
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

  // Find indexes of data entries with which we have conflicts
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

    // Trim if necessary
    if Length(NewEntries) <> j then
      SetLength(NewEntries, j);

    // Combine
    Result := Concat(Result, NewEntries);
  end;
end;

class function TArray.RemoveDuplicates<T>;
var
  Including: TArray<Boolean>;
begin
  if not Assigned(EqualityCheck) then
    EqualityCheck := DefaultEqualityCheck<T>;

  try
    // Exclude item from comparison after we exclude it from the result
    SetLength(Including, Length(Entries));

    Result := TArray.FilterEx<T>(Entries,
      function (const Index: Integer; const Entry: T): Boolean
      var
        i: Integer;
      begin
        Result := True;

        // Check if we already included a similar element
        for i := Pred(Index) downto 0 do
          if Including[i] and EqualityCheck(Entries[i], Entry) then
          begin
            Result := False;
            Break;
          end;

        Including[Index] := Result;
      end
    );
  finally
    // For some reason, the anonymous function from above doesn't want to
    // capture ownership over the default equality checker. Explicitly release
    // the variable here as a workaround.
    EqualityCheck := nil;
  end;
end;

class function TArray.Reverse<T>;
var
  i: Integer;
begin
  SetLength(Result, Length(Entries));

  for i := 0 to High(Entries) do
    Result[High(Entries) - i] := Entries[i];
end;

function SortCallbackLegacy;
begin
  Assert(Assigned(SmartContextLegacy), 'Invalid qsort callback');
  Result := SmartContextLegacy(Integer(Key^), Integer(Element^));
end;

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
  if not Assigned(Comparer) then
    Comparer := DefaultComparer<T>;

  // Instead of implementing the algorithm ourselves (which can be error prone
  // and result in an inefficient code), delegate the sorting to the CRT
  // function from ntdll. However, since it is not aware of Delphi's data types,
  // we cannot use it directly on the array (because it can potentially contain
  // weak interface references which must be moved only using the built-in
  // Delphi mechanisms). As a solution, sort an array of element indexes
  // instead, comparing the elements on each index. Then construct the result
  // using the new order.

  // Generate the initial index list
  SetLength(Indexes, Length(Entries));

  for i := 0 to High(Indexes) do
    Indexes[i] := i;

  try
    // Prepare the anonymous function for comparing indexes via elements
    IndexComparer := function (
        KeyIndex: Integer;
        ElementIndex: Integer
      ): Integer
      begin
        Result := Comparer(Entries[KeyIndex], Entries[ElementIndex]);
      end;

    // Use the newer qsort_s when possible
    if LdrxCheckDelayedImport(delayed_qsort_s).IsSuccess then
    begin
      // Sort the indexes passing the index comparer as a context parameter
      qsort_s(Pointer(Indexes), Length(Indexes), SizeOf(Integer), SortCallback,
        Context);
    end
    else
    try
      // Windows 7 doesn't support qsort_s, so we're forced to use the legacy
      // qsort. However, it doesn't have the context parameter, so we need
      // to pass the index comparer via a thread-local variable.
      SmartContextLegacy := IndexComparer;

      qsort(Pointer(Indexes), Length(Indexes), SizeOf(Integer),
        SortCallbackLegacy);
    finally
      // Clean-up the anonymous function reference
      SmartContextLegacy := nil;
    end;

    // Construct the sorted array
    SetLength(Result, Length(Entries));

    for i := 0 to High(Result) do
      Result[i] := Entries[Indexes[i]];

  finally
    // For some reason, the anonymous function (IndexComparer) doesn't want to
    // capture ownership over the default comparer. Explicitly release the
    // variable here as a workaround.
    Comparer := nil;
  end;
end;

class procedure TArray.SortInline<T>;
begin
  Entries := TArray.Sort<T>(Entries, Comparer);
end;

class function TArray.TryFindFirst<T>;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
    begin
      Element := Entries[i];
      Result := True;
      Exit;
    end;

  Result := False;
end;

end.
