unit DelphiUtils.Arrays;

interface

type
  // Search and filtration
  TFilterAction = (ftKeep, ftExclude);
  TCondition<T> = reference to function (const Entry: T): Boolean;
  TBinaryCondition<T> = reference to function (const Entry: T): Integer;

  // Conversion
  TItemCallback<T> = reference to procedure (var Item: T);

  TMapRoutine<T1, T2> = reference to function (const Entry: T1): T2;
  TMapRoutineEx<T1, T2> = reference to function (const Index: Integer;
    const Entry: T1): T2;

  TConvertRoutine<T1, T2> = reference to function (const Entry: T1;
    out ConvertedEntry: T2): Boolean;
  TConvertRoutineEx<T1, T2> = reference to function (const Index: Integer;
    const Entry: T1; out ConvertedEntry: T2): Boolean;

  // Other

  TGenerator<T> = reference to function(const Index: Integer): T;
  TAggregator<T> = reference to function(const A, B: T): T;

  TConflictChecker<TData, TChanges> = reference to function(const Data: TData;
    const Changes: TChanges): Boolean;
  TConflictResolver<TData, TChanegs> = reference to function(const Existing:
    TData; const New: TChanegs): TData;

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
    class function Filter<T>(const Entries: TArray<T>; Condition:
      TCondition<T>; Action: TFilterAction = ftKeep): TArray<T>; static;

    // Filter an array on by-element basis modifiying the array
    class procedure FilterInline<T>(var Entries: TArray<T>; Condition:
      TCondition<T>; Action: TFilterAction = ftKeep); static;

    // Count the amount of elements that match a condition
    class function Count<T>(var Entries: TArray<T>; Condition:
      TCondition<T>): Integer; static;

    // Find the first occurance of an entry that matches
    class function IndexOf<T>(const Entries: TArray<T>; Condition:
      TCondition<T>): Integer; static;

    // Fast search for an element in a sorted array
    class function BinarySearch<T>(const Entries: TArray<T>; BinarySearcher:
      TBinaryCondition<T>): Integer; static;

    // Check if any elements match
    class function Contains<T>(const Entries: TArray<T>; Condition:
      TCondition<T>): Boolean; static;

    // Find a matching entry or return a default value
    class function FindFirstOrDefault<T>(const Entries: TArray<T>; Condition:
      TCondition<T>; const Default: T): T; static;

    { ------------------------ Conversional operations ----------------------- }

    // Convert each array element into a different type
    class function Map<T1, T2>(const Entries: TArray<T1>;
      Converter: TMapRoutine<T1, T2>): TArray<T2>; static;

    // Convert each array element into a different type
    class function MapEx<T1, T2>(const Entries: TArray<T1>;
      ConverterEx: TMapRoutineEx<T1, T2>): TArray<T2>; static;

    // Try to convert each array element
    class function Convert<T1, T2>(const Entries: TArray<T1>;
      Converter: TConvertRoutine<T1, T2>): TArray<T2>; static;

    // Try to convert each array element
    class function ConvertEx<T1, T2>(const Entries: TArray<T1>;
      ConverterEx: TConvertRoutineEx<T1, T2>): TArray<T2>; static;

    // Execute a function for each element, potentially altering it
    class procedure ForAll<T>(var Entries: TArray<T>;
      Callback: TItemCallback<T>); static;

    { --------------------------- Other operations --------------------------- }

    // Construct an new array
    class function Generate<T>(const Count: Integer; Generator: TGenerator<T>)
      : TArray<T>; static;

    // Combine pairs of elements until only one element is left.
    // Requires at least one element.
    class function Aggregate<T>(const Entries: TArray<T>; Aggregator:
      TAggregator<T>): T; static;

    // Combine pairs of elements until only one element is left.
    class function AggregateOrDefault<T>(const Entries: TArray<T>; Aggregator:
      TAggregator<T>; const Default: T): T; static;

    // Upadate existing items or add new ones into an ordered set by merging
    // changes and resolving conflicts.
    class function Merge<TData, TChanges>(
      const Data: TArray<TData>; const Changes: TArray<TChanges>;
      CheckForConflicts: TConflictChecker<TData, TChanges>;
      ResolveConflict: TConflictResolver<TData, TChanges>;
      ConvertChange: TConvertRoutine<TChanges, TData>): TArray<TData>;

    // Find all parent-child relationships in an array
    class function BuildTree<T>(const Entries: TArray<T>;
      ParentChecker: TParentChecker<T>): TArray<TTreeNode<T>>; static;
  end;

// Convert a list of zero-terminated strings into an array
function ParseMultiSz(Buffer: PWideChar; BufferLength: Cardinal)
  : TArray<String>;

implementation

{$R+}

{ TArray }

class function TArray.Aggregate<T>(const Entries: TArray<T>;
  Aggregator: TAggregator<T>): T;
var
  i: Integer;
begin
  Assert(Length(Entries) <> 0, 'Cannot aggregate an empty array.');

  Result := Entries[0];

  for i := 1 to High(Entries) do
    Result := Aggregator(Result, Entries[i]);
end;

class function TArray.AggregateOrDefault<T>(const Entries: TArray<T>;
  Aggregator: TAggregator<T>; const Default: T): T;
var
  i: Integer;
begin
  if Length(Entries) = 0 then
    Exit(Default);

  Result := Entries[0];

  for i := 1 to High(Entries) do
    Result := Aggregator(Result, Entries[i]);
end;

class function TArray.BinarySearch<T>(const Entries: TArray<T>;
  BinarySearcher: TBinaryCondition<T>): Integer;
var
  Start, Finish, Middle: Integer;
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

  // Start and Finish differ by one. Find which of them matches.
  if BinarySearcher(Entries[Start]) = 0 then
    Result := Start
  else if BinarySearcher(Entries[Finish]) = 0 then
    Result := Finish
  else
    Result := -1;
end;

class function TArray.BuildTree<T>(const Entries: TArray<T>;
  ParentChecker: TParentChecker<T>): TArray<TTreeNode<T>>;
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

class function TArray.Contains<T>(const Entries: TArray<T>;
  Condition: TCondition<T>): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(True);

  Result := False;
end;

class function TArray.Convert<T1, T2>(const Entries: TArray<T1>;
  Converter: TConvertRoutine<T1, T2>): TArray<T2>;
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

class function TArray.ConvertEx<T1, T2>(const Entries: TArray<T1>;
  ConverterEx: TConvertRoutineEx<T1, T2>): TArray<T2>;
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

class function TArray.Count<T>(var Entries: TArray<T>;
  Condition: TCondition<T>): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Inc(Result);
end;

class function TArray.Filter<T>(const Entries: TArray<T>;
  Condition: TCondition<T>; Action: TFilterAction): TArray<T>;
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

class procedure TArray.FilterInline<T>(var Entries: TArray<T>; Condition:
  TCondition<T>; Action: TFilterAction = ftKeep);
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

class function TArray.FindFirstOrDefault<T>(const Entries: TArray<T>;
  Condition: TCondition<T>; const Default: T): T;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(Entries[i]);

  Result := Default;
end;

class procedure TArray.ForAll<T>(var Entries: TArray<T>;
  Callback: TItemCallback<T>);
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    Callback(Entries[i]);
end;

class function TArray.Generate<T>(const Count: Integer;
  Generator: TGenerator<T>): TArray<T>;
var
  i: Integer;
begin
  SetLength(Result, Count);

  for i := 0 to High(Result) do
    Result[i] := Generator(i);
end;

class function TArray.IndexOf<T>(const Entries: TArray<T>;
  Condition: TCondition<T>): Integer;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Condition(Entries[i]) then
      Exit(i);

  Result := -1;
end;

class function TArray.Map<T1, T2>(const Entries: TArray<T1>;
  Converter: TMapRoutine<T1, T2>): TArray<T2>;
var
  i: Integer;
begin
  SetLength(Result, Length(Entries));

  for i := 0 to High(Entries) do
    Result[i] := Converter(Entries[i]);
end;

class function TArray.MapEx<T1, T2>(const Entries: TArray<T1>;
  ConverterEx: TMapRoutineEx<T1, T2>): TArray<T2>;
var
  i: Integer;
begin
  SetLength(Result, Length(Entries));

  for i := 0 to High(Entries) do
    Result[i] := ConverterEx(i, Entries[i]);
end;

class function TArray.Merge<TData, TChanges>(const Data: TArray<TData>;
  const Changes: TArray<TChanges>;
  CheckForConflicts: TConflictChecker<TData, TChanges>;
  ResolveConflict: TConflictResolver<TData, TChanges>;
  ConvertChange: TConvertRoutine<TChanges, TData>): TArray<TData>;
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

{ Functions }

function ParseMultiSz(Buffer: PWideChar; BufferLength: Cardinal)
  : TArray<String>;
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
