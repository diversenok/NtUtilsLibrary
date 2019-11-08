unit DelphiUtils.Arrays;

interface

type
  TFilterRoutine<T> =  function (const Entry: T; Parameter: NativeUInt)
    : Boolean;

  TFilterAction = (ftKeep, ftExclude);

  // Filter an array on by-element basis
  TArrayFilter = class
    class procedure Filter<T>(var Entries: TArray<T>;
      Matches: TFilterRoutine<T>; Parameter: NativeUInt;
      Action: TFilterAction = ftKeep);
  end;

implementation

{ TArrayFilter }

class procedure TArrayFilter.Filter<T>(var Entries: TArray<T>;
  Matches: TFilterRoutine<T>; Parameter: NativeUInt; Action: TFilterAction);
var
  FilteredEntries: TArray<T>;
  Count, i, j: Integer;
begin
  Assert(Assigned(Matches));

  Count := 0;
  for i := 0 to High(Entries) do
    if Matches(Entries[i], Parameter) xor (Action = ftExclude) then
      Inc(Count);

  SetLength(FilteredEntries, Count);

  j := 0;
  for i := 0 to High(Entries) do
    if Matches(Entries[i], Parameter) xor (Action = ftExclude) then
    begin
      FilteredEntries[j] := Entries[i];
      Inc(j);
    end;

  Entries := FilteredEntries;
end;

end.
