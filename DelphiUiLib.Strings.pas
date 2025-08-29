unit DelphiUiLib.Strings;

{
  This module includes functions for preparing text for showing it to users.
}

interface

uses
  DelphiApi.Reflection, NtUtils.SysUtils;

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

// Convert an unsigned integer to a decimal string, grouping digits: 123 456 789
function UiLibUIntToDec(const Value: UInt64): String;

const
  NUMERIC_WIDTH_ROUND_TO_GROUP = NtUtils.SysUtils.NUMERIC_WIDTH_ROUND_TO_GROUP;
  NUMERIC_WIDTH_ROUND_TO_BYTE = NtUtils.SysUtils.NUMERIC_WIDTH_ROUND_TO_BYTE;

// Convert an unsigned integer to a hex string, grouping digits: 0x001F FFFF
function UiLibUIntToHex(
  const Value: UInt64;
  Width: Byte = NUMERIC_WIDTH_ROUND_TO_GROUP
): String;

// Convert a string to an integer. Supports dec, hex, and spaces between digits
function UiLibStringToUInt64(const S: String; out Value: UInt64;
  AllowMinusSign: Boolean = False): Boolean;
function UiLibStringToUIntPtr(const S: String; out Value: UIntPtr;
  AllowMinusSign: Boolean = False): Boolean;
function UiLibStringToUInt(const S: String; out Value: Cardinal;
  AllowMinusSign: Boolean = False): Boolean;

{ Booleans }

function BooleanToString(
  Value: LongBool;
  Kind: TBooleanKind = bkTrueFalse
): String;

function CheckboxToString(Value: LongBool): String;

implementation

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

function UiLibUIntToDec;
begin
  Result := RtlxIntToDec(Value, isUInt64, isUnsigned, npSpace);
end;

function UiLibUIntToHex;
begin
  Result := RtlxIntToHex(Value, Width, True, npSpace);
end;

function UiLibStringToUInt64;
begin
  Result := RtlxStrToUInt64(S, Value, nsDecimal, [nsHexadecimal],
    AllowMinusSign, [npSpace]);
end;

function UiLibStringToUIntPtr;
begin
  Result := RtlxStrToUIntPtr(S, Value, nsDecimal, [nsHexadecimal],
    AllowMinusSign, [npSpace]);
end;

function UiLibStringToUInt;
begin
  Result := RtlxStrToUInt(S, Value, nsDecimal, [nsHexadecimal],
    AllowMinusSign, [npSpace]);
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
