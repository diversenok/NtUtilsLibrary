unit DelphiUiLib.Strings;

{
  This module includes functions for preparing text for showing it to users.
}

interface

uses
  DelphiApi.Reflection;

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

// Convert an integer to a readable decimal representation (as 12 345 678)
function IntToStrEx(const Value: Int64; Width: Byte = 0): String;
function UIntToStrEx(const Value: UInt64; Width: Byte = 0): String;

// Convert an integer to a readable hexadecimal representation (as 0x0FFE FFF0)
function UIntToHexEx(const Value: UInt64; Digits: Byte = 0): String;

// Convert a pointer to a readable hexadecimal representation (as 0x0FFE FFF0)
function PtrToHexEx(Value: Pointer; Digits: Integer = 8): String;

{ Booleans }

function BooleanToString(
  Value: LongBool;
  Kind: TBooleanKind = bkTrueFalse
): String;

function CheckboxToString(Value: LongBool): String;

implementation

uses
  NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function PrettifyCamelCase;
var
  i: Integer;
begin
  // Convert a string with from CamelCase to a spaced string removing a
  // prefix/suffix: '[Prefix]MyExampleIDTest[Suffix]' => 'My Example ID Test'

  Result := CamelCaseText;

  // Remove prefix & suffix
  RtlxPrefixStripString(Prefix, Result, True);
  RtlxSuffixStripString(Suffix, Result, True);

  // Add a space before a capital that has a non-capital on either side of it

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
  // Convert a string with from capitals with underscores to a spaced string
  // removing a prefix/suffix, ex.: 'ERROR_ACCESS_DENIED' => 'Access Denied'

  Result := CapsText;

  // Remove prefix & suffix
  RtlxPrefixStripString(Prefix, Result, True);
  RtlxSuffixStripString(Suffix, Result, True);
  RtlxPrefixStripString('_', Result, True);
  RtlxSuffixStripString('_', Result, True);

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

{ Integers }

function IntToStrEx;
var
  ShortResult: ShortString;
  i: Integer;
begin
  if Value >= 0 then
    Exit(UIntToStrEx(UInt64(Value), Width));

  Str(Value, ShortResult);

  // Split digits into groups of three
  i := Length(ShortResult) - 3 ;
  while i > 1 do
  begin
    Insert(' ', ShortResult, i + 1);
    Dec(i, 3);
  end;

  // Add padding
  while Width > Length(ShortResult) do
    Insert(' ', ShortResult, 0);

  Result := String(ShortResult);
end;

function UIntToStrEx;
var
  ShortResult: ShortString;
  i: Integer;
begin
  Str(Value, ShortResult);

  // Split digits into groups of three
  i := Length(ShortResult) - 3 ;
  while i > 0 do
  begin
    Insert(' ', ShortResult, i + 1);
    Dec(i, 3);
  end;

  // Add padding
  while Width > Length(ShortResult) do
    Insert(' ', ShortResult, 0);

  Result := String(ShortResult);
end;

function UIntToHexEx;
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

  Result := RtlxUInt64ToStr(Value, nsHexadecimal, Digits);

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

function PtrToHexEx;
begin
  Result := UIntToHexEx(UIntPtr(Value), Digits);
end;

{ Booleans }

function BooleanToString;
const
  NAMES: array [TBooleanKind] of array [Boolean] of String = (
    ('False', 'True'),
    ('Disabled', 'Enabled'),
    ('Disallowed', 'Allowed'),
    ('No', 'Yes')
  );
begin
  if Kind > bkYesNo then
    Kind := bkTrueFalse;

  Result := Names[Kind][Value <> False];
end;

function CheckboxToString;
begin
  if Value then
    Result := '☑'
  else
    Result := '☐';
end;

end.
