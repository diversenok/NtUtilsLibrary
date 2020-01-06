unit DelphiUtils.Arrays;

interface

type
  TFilterRoutine<T> =  function (const Entry: T; Parameter: NativeUInt)
    : Boolean;

  TFilterAction = (ftKeep, ftExclude);

  TConvertRoutine<T1, T2> =  function (const Entry: T1; out ConvertedEntry: T2)
    : Boolean;

  // Filter an array on by-element basis
  TArrayHelper = class
    class procedure Filter<T>(var Entries: TArray<T>;
      Matches: TFilterRoutine<T>; Parameter: NativeUInt;
      Action: TFilterAction = ftKeep);
    class procedure Convert<T1, T2>(const Entries: TArray<T1>;
      out MappedEntries: TArray<T2>; Converter: TConvertRoutine<T1, T2>);
  end;

// Convert a list of zero-terminated strings into an array
function ParseMultiSz(Buffer: PWideChar; BufferLength: Cardinal)
  : TArray<String>;

implementation

{ TArrayHelper }

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
