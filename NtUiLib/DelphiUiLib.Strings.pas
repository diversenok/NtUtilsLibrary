unit DelphiUiLib.Strings;

{
  This module includes functions for preparing text for showing it to users.
}

interface

{ String helpers }

// Check if a string starts with a prefix
function StringStartsWith(
  const Str: String;
  const Prefix: String
): Boolean;

// Check if a string ends with a suffix
function StringEndsWith(
  const Str: String;
  const Suffix: String
): Boolean;

{ Text prettification }

// Insert spaces into CamelCase strings and remove a prefix/suffix
function PrettifyCamelCase(
  const CamelCaseText: String;
  const Prefix: String = '';
  const Suffix: String = ''
): String;

// Convert CamelCase to SNAKE_CASE string
function CamelCaseToSnakeCase(
  const Text: String
): string;

// Adjust capitalization and add spaces to SNAKE_CASE strings
function PrettifySnakeCase(
  const CapsText: String;
  const Prefix: String = '';
  const Suffix: String = ''
): String;

{ Integers }

// Convert an integer to a redable decimal representation (as 12 345 678)
function IntToStrEx(Value: UInt64): String;

// Convert an integer to a readable hexadecimal represenation (as 0x0FFE FFF0)
function IntToHexEx(Value: UInt64; Digits: Integer = 0): String;

// Convert a pointer to a readable hexadecimal represenation (as 0x0FFE FFF0)
function PtrToHexEx(Value: Pointer): String;

implementation

uses
  NtUtils.SysUtils;

function StringStartsWith;
var
  i: Integer;
begin
  if Length(Prefix) > Length(Str) then
    Exit(False);

  for i := Low(Prefix) to High(Prefix) do
    if Prefix[i] <> Str[i] then
      Exit(False);

  Result := True;
end;

function StringEndsWith;
var
  i: Integer;
begin
  if Length(Suffix) > Length(Str) then
    Exit(False);

  for i := Low(Suffix) to High(Suffix) do
    if Suffix[i] <> Str[i - High(Suffix) + High(Str)] then
      Exit(False);

  Result := True;
end;

function PrettifyCamelCase;
var
  i: Integer;
begin
  // Convert a string with from CamelCase to a spaced string removing a
  // prefix/suffix: '[Prefix]MyExampleIDTest[Suffix]' => 'My Example ID Test'

  Result := CamelCaseText;

  // Remove prefix
  if StringStartsWith(Result, Prefix) then
    Delete(Result, Low(Result), Length(Prefix));

  // Remove suffix
  if StringEndsWith(Result, Suffix) then
    Delete(Result, Length(Result) - Length(Suffix) + 1, Length(Suffix));

  // Add a space before a capital that has a non-captial on either side of it

  i := Low(Result);

  // Skip leading lower-case word
  while (i <= High(Result)) and (AnsiChar(Result[i]) in ['a'..'z']) do
    Inc(i);

  Inc(i);
  while i <= High(Result) do
  begin
    if (AnsiChar(Result[i]) in ['A'..'Z', '0'..'9']) and
      (not (AnsiChar(Result[i - 1]) in ['A'..'Z', '0'..'9']) or
      ((i < High(Result)) and not (AnsiChar(Result[i + 1]) in
      ['A'..'Z', '0'..'9']))) then
    begin
      Insert(' ', Result, i);
      Inc(i);
    end;
    Inc(i);
  end;
end;

function CamelCaseToSnakeCase;
var
  i: Integer;
begin
  Result := PrettifyCamelCase(Text);

  for i := Low(Result) to High(Result) do
    if AnsiChar(Result[i]) in ['a'..'z'] then
      Result[i] := Chr(Ord('A') + Ord(Result[i]) - Ord('a'))
    else if Result[i] = ' ' then
      Result[i] := '_';
end;

function PrettifySnakeCase;
var
  i: Integer;
begin
  // Convert a string with from capitals with undescores to a spaced string
  // removing a prefix/suffix, ex.: 'ERROR_ACCESS_DENIED' => 'Acces Denied'

  Result := CapsText;

  if StringStartsWith(Result, Prefix) then
    Delete(Result, Low(Result), Length(Prefix));

  if StringEndsWith(Result, Suffix) then
    Delete(Result, Length(Result) - Length(Suffix) + 1, Length(Suffix));

  if StringStartsWith(Result, '_') then
    Delete(Result, Low(Result), 1);

  if StringEndsWith(Result, '_') then
    Delete(Result, High(Result), 1);

  i := Succ(Low(Result));
  while i <= High(Result) do
  begin
    case Result[i] of
      'A'..'Z':
        Result[i] := Chr(Ord('a') + Ord(Result[i]) - Ord('A'));
      '_':
        begin
          Result[i] := ' ';
          Inc(i); // Skip the next letter
        end;
    end;
    Inc(i);
  end;
end;

function IntToStrEx;
var
  ShortResult: ShortString;
  i: Integer;
begin
  Str(Value, ShortResult);
  Result := String(ShortResult);

  i := High(Result) - 2;

  while i > Low(Result) do
  begin
    Insert(' ', Result, i);
    Dec(i, 3);
  end;
end;

function IntToHexEx;
var
  i: Integer;
begin
  if Digits <= 0 then
  begin
    // Add leading zeros
    if Value > $FFFFFFFFFFFF then
      Digits := 16
    else if Value > $FFFFFFFF then
      Digits := 12
    else if Value > $FFFF then
      Digits := 8
    else if Value > $FF then
      Digits := 4
    else
      Digits := 2;
  end;

  Result := RtlxInt64ToStr(Value, 16, Digits);

  if Length(Result) > 6 then
  begin
    // Split digits into groups of four
    i := High(Result) - 3;
    while i > Low(Result) + 3 do
    begin
      Insert(' ', Result, i);
      Dec(i, 4)
    end;
  end;
end;

function PtrToHexEx(Value: Pointer): String;
begin
  Result := IntToHexEx(UIntPtr(Value));
end;

end.
