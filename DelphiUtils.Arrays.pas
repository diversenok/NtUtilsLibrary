unit DelphiUtils.Arrays;

interface

type
  TFilterRoutine<T> =  function (const Entry: T; Parameter: NativeUInt)
    : Boolean;

  TFilterAction = (ftKeep, ftExclude);

  TConvertRoutine<T1, T2> =  function (const Entry: T1; out ConvertedEntry: T2)
    : Boolean;

  TTreeNode<T> = record
    Entry: T;
    Index: Integer;
    Parent: ^TTreeNode<T>;
    Children: TArray<^TTreeNode<T>>;
  end;

  TParentChecker<T> = function (const Parent, Child: T): Boolean;

  TArrayHelper = class
    // Filter an array on by-element basis
    class procedure Filter<T>(var Entries: TArray<T>;
      Matches: TFilterRoutine<T>; Parameter: NativeUInt;
      Action: TFilterAction = ftKeep);

    // Convert (map) each array element
    class procedure Convert<T1, T2>(const Entries: TArray<T1>;
      out MappedEntries: TArray<T2>; Converter: TConvertRoutine<T1, T2>);

    // Find all parent-child relationships in an array
    class function BuildTree<T>(const Entries: TArray<T>;
      ParentChecker: TParentChecker<T>): TArray<TTreeNode<T>>;
  end;

// Convert a list of zero-terminated strings into an array
function ParseMultiSz(Buffer: PWideChar; BufferLength: Cardinal)
  : TArray<String>;

implementation

{ TArrayHelper }

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

class procedure TArrayHelper.Convert<T1, T2>(const Entries: TArray<T1>;
  out MappedEntries: TArray<T2>; Converter: TConvertRoutine<T1, T2>);
var
  i, j: Integer;
begin
  Assert(Assigned(Converter));
  SetLength(MappedEntries, Length(Entries));

  j := 0;
  for i := 0 to High(Entries) do
    if Converter(Entries[i], MappedEntries[j]) then
      Inc(j);

  SetLength(MappedEntries, j);
end;

class procedure TArrayHelper.Filter<T>(var Entries: TArray<T>;
  Matches: TFilterRoutine<T>; Parameter: NativeUInt; Action: TFilterAction);
var
  i, j: Integer;
begin
  Assert(Assigned(Matches));

  j := 0;
  for i := 0 to High(Entries) do
    if Matches(Entries[i], Parameter) xor (Action = ftExclude) then
    begin
      // j grows slower then i, move elements backwards overwriting ones that
      // don't match
      if i <> j then
        Entries[j] := Entries[i];

      Inc(j);
    end;

  SetLength(Entries, j);
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
