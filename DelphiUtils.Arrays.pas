unit DelphiUtils.Arrays;

interface

type
  TFilterAction = (ftKeep, ftExclude);

  TFilterRoutine<T> = reference to function (const Entry: T): Boolean;
  TBinarySearcher<T> = reference to function (const Entry: T): Integer;
  TProcedure<T> = reference to procedure (const Entry: T);
  TAggregator<T> = reference to function(const A, B: T): T;
  TMapRoutine<T1, T2> = reference to function (const Entry: T1): T2;
  TConvertRoutine<T1, T2> = reference to function (const Entry: T1;
    out ConvertedEntry: T2): Boolean;

  TTreeNode<T> = record
    Entry: T;
    Index: Integer;
    Parent: ^TTreeNode<T>;
    Children: TArray<^TTreeNode<T>>;
  end;

  TParentChecker<T> = reference to function (const Parent, Child: T): Boolean;

  TArrayHelper = class
    // Filter an array on by-element basis
    class procedure Filter<T>(var Entries: TArray<T>; FilterRoutine:
      TFilterRoutine<T>; Action: TFilterAction = ftKeep);

    // Find the first occurance of an entry that matches
    class function IndexOf<T>(const Entries: TArray<T>; Finder:
      TFilterRoutine<T>): Integer;

    // Fast search for an element in a sorted array
    class function BinarySearch<T>(const Entries: TArray<T>; BinarySearcher:
      TBinarySearcher<T>): Integer;

    // Check if any elements match
    class function Contains<T>(const Entries: TArray<T>; Finder:
      TFilterRoutine<T>): Boolean;

    // Find a matching entry or return a default value
    class function FindFirstOrDefault<T>(const Entries: TArray<T>; Finder:
      TFilterRoutine<T>; const Default: T): T;

    // Convert each array element into a different type
    class function Map<T1, T2>(const Entries: TArray<T1>;
      Converter: TMapRoutine<T1, T2>): TArray<T2>;

    // Try to convert each array element
    class function Convert<T1, T2>(const Entries: TArray<T1>;
      Converter: TConvertRoutine<T1, T2>): TArray<T2>;

    // Execute a function for each element
    class procedure ForAll<T>(const Entries: TArray<T>;
      Payload: TProcedure<T>);

    // Combine pairs of elements until only one element is left.
    // Requires at least one element.
    class function Aggregate<T>(const Entries: TArray<T>; Aggregator:
      TAggregator<T>): T;

    // Combine pairs of elements until only one element is left.
    class function AggregateOrDefault<T>(const Entries: TArray<T>; Aggregator:
      TAggregator<T>; const Default: T): T;

    // Find all parent-child relationships in an array
    class function BuildTree<T>(const Entries: TArray<T>;
      ParentChecker: TParentChecker<T>): TArray<TTreeNode<T>>;
  end;

// Convert a list of zero-terminated strings into an array
function ParseMultiSz(Buffer: PWideChar; BufferLength: Cardinal)
  : TArray<String>;

implementation

{$R+}

{ TArrayHelper }

class function TArrayHelper.Aggregate<T>(const Entries: TArray<T>;
  Aggregator: TAggregator<T>): T;
var
  i: Integer;
begin
  Assert(Length(Entries) <> 0, 'Cannot aggregate an empty array.');

  Result := Entries[0];

  for i := 1 to High(Entries) do
    Result := Aggregator(Result, Entries[i]);
end;

class function TArrayHelper.AggregateOrDefault<T>(const Entries: TArray<T>;
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

class function TArrayHelper.BinarySearch<T>(const Entries: TArray<T>;
  BinarySearcher: TBinarySearcher<T>): Integer;
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

class function TArrayHelper.BuildTree<T>(const Entries: TArray<T>;
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

class function TArrayHelper.Contains<T>(const Entries: TArray<T>;
  Finder: TFilterRoutine<T>): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Finder(Entries[i]) then
      Exit(True);

  Result := False;
end;

class function TArrayHelper.Convert<T1, T2>(const Entries: TArray<T1>;
  Converter: TConvertRoutine<T1, T2>): TArray<T2>;
var
  i, j: Integer;
begin
  Assert(Assigned(Converter));
  SetLength(Result, Length(Entries));

  j := 0;
  for i := 0 to High(Entries) do
    if Converter(Entries[i], Result[j]) then
      Inc(j);

  SetLength(Result, j);
end;

class procedure TArrayHelper.Filter<T>(var Entries: TArray<T>; FilterRoutine:
      TFilterRoutine<T>; Action: TFilterAction = ftKeep);
var
  i, j: Integer;
begin
  Assert(Assigned(FilterRoutine));

  j := 0;
  for i := 0 to High(Entries) do
    if FilterRoutine(Entries[i]) xor (Action = ftExclude) then
    begin
      // j grows slower then i, move elements backwards overwriting ones that
      // don't match
      if i <> j then
        Entries[j] := Entries[i];

      Inc(j);
    end;

  SetLength(Entries, j);
end;

class function TArrayHelper.FindFirstOrDefault<T>(const Entries: TArray<T>;
  Finder: TFilterRoutine<T>; const Default: T): T;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Finder(Entries[i]) then
      Exit(Entries[i]);

  Result := Default;
end;

class procedure TArrayHelper.ForAll<T>(const Entries: TArray<T>;
  Payload: TProcedure<T>);
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    Payload(Entries[i]);
end;

class function TArrayHelper.IndexOf<T>(const Entries: TArray<T>;
  Finder: TFilterRoutine<T>): Integer;
var
  i: Integer;
begin
  for i := 0 to High(Entries) do
    if Finder(Entries[i]) then
      Exit(i);

  Result := -1;
end;

class function TArrayHelper.Map<T1, T2>(const Entries: TArray<T1>;
  Converter: TMapRoutine<T1, T2>): TArray<T2>;
var
  i: Integer;
begin
  SetLength(Result, Length(Entries));

  for i := 0 to High(Entries) do
    Result[i] := Converter(Entries[i]);
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
