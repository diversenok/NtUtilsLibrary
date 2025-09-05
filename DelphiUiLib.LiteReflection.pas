unit DelphiUiLib.LiteReflection;

{
  This module provides lightweight reflection support for represnting various
  types.
}

interface

uses
  DelphiUtils.LiteRTTI.Extension;

{ Type-specific }

// Represent a Delphi enumeration type
function RttixFormatEnum(
  const EnumType: IRttixEnumType;
  const [ref] Instance
): String;

// Prepare a hint for a Delphi enumeration type representation
function RttixFormatEnumHint(
  const EnumType: IRttixEnumType;
  const [ref] Instance
): String;

// Represent a boolean type
function RttixFormatBool(
  const BoolType: IRttixBoolType;
  const [ref] Instance
): String;

// Represent a bit mask type
function RttixFormatBitwise(
  const BitwiseType: IRttixBitwiseType;
  const [ref] Instance
): String;

// Prepare a hint for a bit mask type representation
function RttixFormatBitwiseHint(
  const BitwiseType: IRttixBitwiseType;
  const [ref] Instance
): String;

// Represent a decimal/hexadecimal type
function RttixFormatDigits(
  const DigitsType: IRttixDigitsType;
  const [ref] Instance
): String;

// Prepare a hint for a decimal/hexadecimal type representation
function RttixFormatDigitsHint(
  const DigitsType: IRttixDigitsType;
  const [ref] Instance
): String;

// Represent a string type
function RttixFormatString(
  const StringType: IRttixStringType;
  const [ref] Instance
): String;

{ Common }

// Represent a known type
function RttixFormatText(
  const AType: IRttixType;
  const [ref] Instance
): String;

// Prepare a hint a known type representation
function RttixFormatHint(
  const AType: IRttixType;
  const [ref] Instance
): String;

// Represent a known type from raw type info
function RttixFormat(
  ATypeInfo: Pointer;
  const [ref] Instance
): String;

type
  Rttix = record
    // Represent a known type from a generic parameter
    class function Format<T>(const Instance: T): String; static;
  end;

implementation

uses
  DelphiApi.TypInfo, DelphiApi.Reflection, NtUtils.SysUtils,
  DelphiUiLib.Strings;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RttixFormatEnum;
var
  Value: Cardinal;
begin
  Value := EnumType.ReadInstance(Instance);

  if Value in EnumType.ValidValues then
  begin
    Result := EnumType.TypeInfo.EnumerationName(Integer(Value));

    case EnumType.NamingStyle of
      nsCamelCase:
        Result := PrettifyCamelCase(Result, EnumType.Prefix, EnumType.Suffix);
      nsSnakeCase:
        Result := PrettifySnakeCase(Result, EnumType.Prefix, EnumType.Suffix);
    end;
  end
  else
    Result := UiLibUIntToDec(Value) + ' (out of bound)';
end;

function RttixFormatEnumHint;
var
  Value: Cardinal;
begin
  Value := EnumType.ReadInstance(Instance);

  Result := BuildHint([
    THintSection.New('Value (decimal)', UiLibUIntToDec(Value)),
    THintSection.New('Value (hex)', UiLibUIntToHex(Value))
  ]);
end;

function RttixFormatBool;
begin
  Result := BooleanToString(BoolType.ReadInstance(Instance),
    BoolType.BooleanKind);
end;

function RttixFormatBitwise;
var
  Value, ExcludedMask: UInt64;
  Matched: TArray<String>;
  i, Count: Integer;
begin
  Value := BitwiseType.ReadInstance(Instance);

  // Record found bits
  SetLength(Matched, Length(BitwiseType.Flags) + 1);
  Count := 0;
  ExcludedMask := 0;

  for i := 0 to High(BitwiseType.Flags) do
    if (BitwiseType.Flags[i].Mask and ExcludedMask = 0) and
      (Value and BitwiseType.Flags[i].Mask = BitwiseType.Flags[i].Value) then
    begin
      Value := Value and not BitwiseType.Flags[i].Mask;
      ExcludedMask := ExcludedMask or BitwiseType.Flags[i].Mask;
      Matched[Count] := BitwiseType.Flags[i].Name;
      Inc(Count);
    end;

  // Record unknown bits
  if Value <> 0 then
  begin
    Matched[Count] := UiLibUIntToHex(Value, BitwiseType.MinDigits or
      NUMERIC_WIDTH_ROUND_TO_GROUP);
    Inc(Count);
  end;

  // Trim
  SetLength(Matched, Count);

  // Combine
  if Length(Matched) > 0 then
    Result := RtlxJoinStrings(Matched, ', ')
  else
    Result := '(none)';
end;

function RttixFormatBitwiseHint;
var
  Value, ExcludedMask: UInt64;
  Checkboxes: TArray<String>;
  i: Integer;
  Matched: Boolean;
begin
  Value := BitwiseType.ReadInstance(Instance);

  SetLength(Checkboxes, Length(BitwiseType.Flags));
  ExcludedMask := 0;

  for i := 0 to High(BitwiseType.Flags) do
  begin
    if (BitwiseType.Flags[i].Mask and ExcludedMask = 0) and
      (Value and BitwiseType.Flags[i].Mask = BitwiseType.Flags[i].Value) then
    begin
      Matched := True;
      Value := Value and not BitwiseType.Flags[i].Mask;
      ExcludedMask := ExcludedMask or BitwiseType.Flags[i].Mask;
    end
    else
      Matched := False;

    Checkboxes[i] := '  ' + CheckboxToString(Matched) + ' ' +
      BitwiseType.Flags[i].Name + '  ';
  end;

  Result := 'Flags:  '#$D#$A + RtlxJoinStrings(Checkboxes, #$D#$A) +
    #$D#$A'Value:  ' + UiLibUIntToHex(Value, BitwiseType.MinDigits or
    NUMERIC_WIDTH_ROUND_TO_GROUP) + '  ';
end;

function RttixFormatDigits;
var
  Size: TIntegerSize;
  Sign: TIntegerSign;
  Value: UInt64;
  AsciiStr: AnsiString;
begin
  Value := DigitsType.ReadInstance(Instance);

  case DigitsType.Size of
    SizeOf(Byte):     Size := isByte;
    SizeOf(Word):     Size := isWord;
    SizeOf(Cardinal): Size := isCardinal;
  else
    Size := isUInt64;
  end;

  if DigitsType.Signed then
    Sign := isSigned
  else
    Sign := isUnsigned;

  case DigitsType.DigitsKind of
    rokDecimal:
      Result := RtlxIntToDec(Value, Size, Sign, 0, npSpace);

    rokHex:
      Result := RtlxIntToHex(Value, DigitsType.MinHexDigits or
        NUMERIC_WIDTH_ROUND_TO_GROUP, True, npSpace);

    rokBytes:
      Result := UiLibBytesToString(Value);

    rokAscii:
    begin
      SetLength(AsciiStr, DigitsType.Size * 2);
      Move(Value, AsciiStr[Low(AsciiStr)], DigitsType.Size * 2);
      Result := String(AsciiStr);
    end
  else
    Error(reAssertionFailed);
  end;
end;

function RttixFormatDigitsHint;
var
  Value: UInt64;
begin
  Value := DigitsType.ReadInstance(Instance);

  case DigitsType.DigitsKind of
    rokDecimal, rokAscii:
      Result := BuildHint('Value (hex)', UiLibUIntToHex(Value));

    rokHex:
      Result := BuildHint('Value (decimal)', UiLibUIntToDec(Value));

    rokBytes:
      Result := BuildHint([
        THintSection.New('Value (decimal)', UiLibUIntToDec(Value)),
        THintSection.New('Value (hex)', UiLibUIntToHex(Value))
      ]);
  end;
end;

function RttixFormatString;
begin
  Result := StringType.ReadInstance(Instance);
end;

{ Common }

function RttixFormatText;
begin
  case AType.SubKind of
    rtkEnumeration:
      Result := RttixFormatEnum(AType as IRttixEnumType, Instance);
    rtkBoolean:
      Result := RttixFormatBool(AType as IRttixBoolType, Instance);
    rtkBitwise:
      Result := RttixFormatBitwise(AType as IRttixBitwiseType, Instance);
    rtkDigits:
      Result := RttixFormatDigits(AType as IRttixDigitsType, Instance);
    rtkString:
      Result := RttixFormatString(AType as IRttixStringType, Instance);
  else
    Result := '(' + AType.TypeInfo.Name + ')';
  end;
end;

function RttixFormatHint;
begin
  case AType.SubKind of
    rtkEnumeration:
      Result := RttixFormatEnumHint(AType as IRttixEnumType, Instance);

    rtkBitwise:
      Result := RttixFormatBitwiseHint(AType as IRttixBitwiseType, Instance);

    rtkDigits:
      Result := RttixFormatDigitsHint(AType as IRttixDigitsType, Instance);
  else
    Result := '';
  end;
end;

function RttixFormat;
begin
  if Assigned(ATypeInfo) then
    Result := RttixFormatText(RttixTypeInfo(ATypeInfo), Instance)
  else
    Result := '(unknown type)';
end;

class function Rttix.Format<T>;
begin
  Result := RttixFormat(TypeInfo(T), Instance);
end;

end.
