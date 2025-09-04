unit DelphiUiLib.LiteReflection;

{
  This module provides lightweight reflection support for represnting various
  types.
}

interface

uses
  DelphiUtils.LiteRTTI.Extension;

// Represent a Delphi enumeration type
function RttixFormatEnum(
  const EnumType: IRttixEnumType;
  var Instance
): String;

// Represent a boolean type
function RttixFormatBool(
  const BoolType: IRttixBoolType;
  var Instance
): String;

// Represent a bit mask type
function RttixFormatBitwise(
  const BitwiseType: IRttixBitwiseType;
  var Instance
): String;

// Represent a decimal/hexadecimal enumeration type
function RttixFormatDigits(
  const DigitsType: IRttixDigitsType;
  var Instance
): String;

// Represent a known type
function RttixFormat(
  const AType: IRttixType;
  var Instance
): String;

implementation

uses
  DelphiApi.TypInfo, DelphiApi.Reflection, NtUtils.SysUtils,
  DelphiUiLib.Strings;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RttixFormatEnum;
var
  Value: Integer;
begin
  case EnumType.TypeInfo.OrdinalType of
    otSByte, otUByte: Value := Integer(Cardinal(Byte(Instance)));
    otSWord, otUWord: Value := Integer(Cardinal(Word(Instance)));
    otSLong, otULong: Value := Integer(Cardinal(Instance));
  else
    Value := 0;
    Error(reAssertionFailed);
  end;

  if Value in EnumType.ValidValues then
  begin
    Result := EnumType.TypeInfo.EnumerationName(Value);

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

function RttixFormatBool;
var
  Value: LongBool;
begin
  case BoolType.Size of
    SizeOf(ByteBool): Value := ByteBool(Instance);
    SizeOf(WordBool): Value := WordBool(Instance);
    SizeOf(LongBool): Value := LongBool(Instance);
  else
    Error(reAssertionFailed);
    Value := False;
  end;

  Result := BooleanToString(Value, BoolType.BooleanKind);
end;

function RttixFormatBitwise;
var
  Value, ExcludedMask: UInt64;
  Matched: TArray<String>;
  i, Count: Integer;
begin
  case BitwiseType.Size of
    SizeOf(Byte):     Value := Byte(Instance);
    SizeOf(Word):     Value := Word(Instance);
    SizeOf(Cardinal): Value := Cardinal(Instance);
    SizeOf(UInt64):   Value := UInt64(Instance);
  else
    Error(reAssertionFailed);
    Value := 0;
  end;

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

function RttixFormatDigits;
var
  Size: TIntegerSize;
  Sign: TIntegerSign;
  Value: UInt64;
  AsciiStr: AnsiString;
begin
  case DigitsType.Size of
    SizeOf(Byte):     Value := Byte(Instance);
    SizeOf(Word):     Value := Word(Instance);
    SizeOf(Cardinal): Value := Cardinal(Instance);
    SizeOf(UInt64):   Value := UInt64(Instance);
  else
    Error(reAssertionFailed);
    Value := 0;
  end;

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

function RttixFormat;
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
  else
    Result := '(' + AType.TypeInfo.Name + ')';
  end;
end;

end.
