unit DelphiUiLib.LiteReflection;

{
  This module provides lightweight reflection support for represnting various
  types.
}

interface

uses
  DelphiApi.Reflection, DelphiUtils.LiteRTTI, DelphiUtils.LiteRTTI.Extension;

type
  IRttixTypeFormatter = interface
    ['{C5915174-2560-4C84-B51D-D257BBB2783D}']
    function GetRttixType: IRttixType;
    function GetHasCustomFormatting: Boolean;

    property RttixType: IRttixType read GetRttixType;
    property HasCustomFormatting: Boolean read GetHasCustomFormatting;
    function FormatAsText(const [ref] Instance): String;
    function FormatAsHint(const [ref] Instance): String;
  end;

  TRttixCustomTypeFormatter = function (
    const RttixType: IRttixType;
    const [ref] Instance
  ): String;

// Add a callback for formatting a custom type
procedure RttixRegisterCustomTypeFormatter(
  TypeInfo: PLiteRttiTypeInfo;
  [opt] TextFormatter: TRttixCustomTypeFormatter;
  [opt] HintFormatter: TRttixCustomTypeFormatter
);

// Prepare formatter for representing a specific type
function RttixMakeTypeFormatter(
  [opt] TypeInfo: PLiteRttiTypeInfo;
  const FieldAttributes: TArray<PLiteRttiAttribute> = nil
): IRttixTypeFormatter;

// Represent a type from raw type info
function RttixFormat(
  TypeInfo: PLiteRttiTypeInfo;
  const [ref] Instance;
  const FieldAttributes: TArray<PLiteRttiAttribute> = nil
): String;

type
  Rttix = record
    // Represent a known type from a generic parameter
    class function Format<T>(
      const Instance: T;
      const FieldAttributes: TArray<PLiteRttiAttribute> = nil
    ): String; static;
  end;

implementation

uses
  DelphiApi.TypInfo, NtUtils.SysUtils, DelphiUtils.Arrays, DelphiUiLib.Strings,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Custom Formatters }

type
  TRttixFormatterEntry = record
    TypeInfo: PLiteRttiTypeInfo;
    TextFormatter: TRttixCustomTypeFormatter;
    HintFormatter: TRttixCustomTypeFormatter
  end;

var
  RttixKnownFormatters: TArray<TRttixFormatterEntry>;

function RttixFindTypeIndex(
  TypeInfo: PLiteRttiTypeInfo
): Integer;
begin
  Result := TArray.BinarySearchEx<TRttixFormatterEntry>(RttixKnownFormatters,
    function (const Entry: TRttixFormatterEntry): NativeInt
    begin
      {$Q-}{$R-}
      Result := NativeInt(Entry.TypeInfo) - NativeInt(TypeInfo);
      {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}
    end
  );
end;

procedure RttixRegisterCustomTypeFormatter;
var
  Index: Integer;
  Entry: TRttixFormatterEntry;
begin
  Entry.TypeInfo := TypeInfo;
  Entry.TextFormatter := TextFormatter;
  Entry.HintFormatter := HintFormatter;
  Index := RttixFindTypeIndex(TypeInfo);

  if Index < 0 then
    Insert(Entry, RttixKnownFormatters, -(Index + 1))
  else
    RttixKnownFormatters[Index] := Entry;
end;

{ Type sub-kind formatters }

function RttixFormatEnum(
  const EnumType: IRttixEnumType;
  const [ref] Instance
): String;
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

function RttixFormatEnumHint(
  const EnumType: IRttixEnumType;
  const [ref] Instance
): String;
var
  Value: Cardinal;
begin
  Value := EnumType.ReadInstance(Instance);

  Result := BuildHint([
    THintSection.New('Value (decimal)', UiLibUIntToDec(Value)),
    THintSection.New('Value (hex)', UiLibUIntToHex(Value))
  ]);
end;

function RttixFormatBool(
  const BoolType: IRttixBoolType;
  const [ref] Instance
): String;
begin
  Result := BooleanToString(BoolType.ReadInstance(Instance),
    BoolType.BooleanKind);
end;

function RttixFormatBitwise(
  const BitwiseType: IRttixBitwiseType;
  const [ref] Instance
): String;
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

function RttixFormatBitwiseHint(
  const BitwiseType: IRttixBitwiseType;
  const [ref] Instance
): String;
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

function RttixFormatDigits(
  const DigitsType: IRttixDigitsType;
  const [ref] Instance
): String;
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

function RttixFormatDigitsHint(
  const DigitsType: IRttixDigitsType;
  const [ref] Instance
): String;
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

function RttixFormatString(
  const StringType: IRttixStringType;
  const [ref] Instance
): String;
begin
  Result := StringType.ReadInstance(Instance);
end;

{ Formatters }

type
  TRttixTypeFormatter = class (TAutoInterfacedObject, IRttixTypeFormatter)
    FRttixType: IRttixType;
    FTextFormatter: TRttixCustomTypeFormatter;
    FHintFormatter: TRttixCustomTypeFormatter;
    function GetRttixType: IRttixType;
    function GetHasCustomFormatting: Boolean;
    function FormatAsText(const [ref] Instance): String;
    function FormatAsHint(const [ref] Instance): String;
    constructor Create(
      [opt] const RttixType: IRttixType;
      [opt] TextFormatter: TRttixCustomTypeFormatter;
      [opt] HintFormatter: TRttixCustomTypeFormatter
    );
  end;

constructor TRttixTypeFormatter.Create;
begin
  FRttixType := RttixType;
  FTextFormatter := TextFormatter;
  FHintFormatter := HintFormatter;
end;

function TRttixTypeFormatter.FormatAsText;
begin
  if Assigned(FTextFormatter) then
    Result := FTextFormatter(FRttixType, Instance)
  else if Assigned(FRttixType) then
    case FRttixType.SubKind of
      rtkEnumeration:
        Result := RttixFormatEnum(FRttixType as IRttixEnumType, Instance);
      rtkBoolean:
        Result := RttixFormatBool(FRttixType as IRttixBoolType, Instance);
      rtkBitwise:
        Result := RttixFormatBitwise(FRttixType as IRttixBitwiseType, Instance);
      rtkDigits:
        Result := RttixFormatDigits(FRttixType as IRttixDigitsType, Instance);
      rtkString:
        Result := RttixFormatString(FRttixType as IRttixStringType, Instance);
    else
      Result := '(' + FRttixType.TypeInfo.Name + ')';
    end
  else
    Result := '(no type info)';
end;

function TRttixTypeFormatter.FormatAsHint;
begin
  if Assigned(FHintFormatter) then
    Result := FHintFormatter(FRttixType, Instance)
  else if Assigned(FRttixType) then
    case FRttixType.SubKind of
      rtkEnumeration:
        Result := RttixFormatEnumHint(FRttixType as IRttixEnumType, Instance);
      rtkBitwise:
        Result := RttixFormatBitwiseHint(FRttixType as IRttixBitwiseType, Instance);
      rtkDigits:
        Result := RttixFormatDigitsHint(FRttixType as IRttixDigitsType, Instance);
    else
      Result := '';
    end
  else
    Result := '';
end;

function TRttixTypeFormatter.GetHasCustomFormatting;
begin
  Result := Assigned(FTextFormatter) or Assigned(FHintFormatter);
end;

function TRttixTypeFormatter.GetRttixType;
begin
  Result := FRttixType;
end;

function RttixMakeTypeFormatter;
var
  Index: Integer;
  RttixType: IRttixType;
  TextFormatter, HintFormatter: TRttixCustomTypeFormatter;
begin
  TextFormatter := nil;
  HintFormatter := nil;

  if Assigned(TypeInfo) then
  begin
    RttixType := RttixTypeInfo(TypeInfo, FieldAttributes);
    Index := RttixFindTypeIndex(TypeInfo);

    if Index >= 0 then
    begin
      TextFormatter := RttixKnownFormatters[Index].TextFormatter;
      HintFormatter := RttixKnownFormatters[Index].HintFormatter;
    end;
  end
  else
    RttixType := nil;

  Result := TRttixTypeFormatter.Create(RttixType, TextFormatter, HintFormatter);
end;

{ Common }

function RttixFormat;
var
  Formatter: IRttixTypeFormatter;
begin
  Formatter := RttixMakeTypeFormatter(TypeInfo, FieldAttributes);
  Result := Formatter.FormatAsText(Instance);
end;

class function Rttix.Format<T>;
var
  Formatter: IRttixTypeFormatter;
begin
  Formatter := RttixMakeTypeFormatter(TypeInfo(T), FieldAttributes);
  Result := Formatter.FormatAsText(Instance);
end;

end.
