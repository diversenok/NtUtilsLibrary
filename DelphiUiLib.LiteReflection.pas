unit DelphiUiLib.LiteReflection;

{
  This module provides lightweight reflection support for represnting various
  types.
}

interface

uses
  DelphiApi.Reflection, DelphiUtils.LiteRTTI, DelphiUtils.LiteRTTI.Extension;

type
  TRttixReflectionFormat = (rfText, rfHint);
  TRttixReflectionFormats = set of TRttixReflectionFormat;

  TRttixFullReflection = record
    ValidFormats: TRttixReflectionFormats;
    Text: String;
    Hint: String;
  end;

  IRttixTypeFormatter = interface
    ['{C5915174-2560-4C84-B51D-D257BBB2783D}']
    function GetRttixType: IRttixType;
    function GetHasCustomFormatting: Boolean;

    property RttixType: IRttixType read GetRttixType;
    property HasCustomFormatting: Boolean read GetHasCustomFormatting;
    function FormatText(const [ref] Instance): String;
    function FormatHint(const [ref] Instance): String;
    function FormatFull(const [ref] Instance): TRttixFullReflection;
  end;

  TRttixCustomTypeFormatter = function (
    const RttixType: IRttixType;
    const [ref] Instance;
    RequestedFormats: TRttixReflectionFormats
  ): TRttixFullReflection;

// Add a callback for formatting a custom type
procedure RttixRegisterCustomTypeFormatter(
  TypeInfo: PLiteRttiTypeInfo;
  Formatter: TRttixCustomTypeFormatter
);

// Prepare formatter for representing a specific type
function RttixMakeTypeFormatter(
  [opt] TypeInfo: PLiteRttiTypeInfo;
  const FieldAttributes: TArray<PLiteRttiAttribute> = nil
): IRttixTypeFormatter;

// An attribute indicating that reflection should presetve enumeration names
function RttixPreserveEnumCase(
): PLiteRttiAttribute;

// Represent a type as text from raw type info
function RttixFormat(
  TypeInfo: PLiteRttiTypeInfo;
  const [ref] Instance;
  const FieldAttributes: TArray<PLiteRttiAttribute> = nil
): String;

// Represent a type as text and hint from raw type info
function RttixFormatFull(
  TypeInfo: PLiteRttiTypeInfo;
  const [ref] Instance;
  const FieldAttributes: TArray<PLiteRttiAttribute> = nil
): TRttixFullReflection;

type
  Rttix = record
    // Represent a known type as text from a generic parameter
    class function Format<T>(
      const Instance: T;
      const FieldAttributes: TArray<PLiteRttiAttribute> = nil
    ): String; static;

    // Represent a known type as text and hint from a generic parameter
    class function FormatFull<T>(
      const Instance: T;
      const FieldAttributes: TArray<PLiteRttiAttribute> = nil
    ): TRttixFullReflection; static;
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
    Formatter: TRttixCustomTypeFormatter;
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
  Entry.Formatter := Formatter;
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
  Value: UInt64;
  Checkboxes: TArray<String>;
  i: Integer;
begin
  Value := BitwiseType.ReadInstance(Instance);

  SetLength(Checkboxes, Length(BitwiseType.Flags));

  for i := 0 to High(BitwiseType.Flags) do
    Checkboxes[i] := '  ' + CheckboxToString(Value and BitwiseType.Flags[i].Mask
      = BitwiseType.Flags[i].Value) + ' ' + BitwiseType.Flags[i].Name + '  ';

  Result := 'Flags:  '#$D#$A + RtlxJoinStrings(Checkboxes, #$D#$A) +
    #$D#$A'Value:  '#$D#$A'  ' + UiLibUIntToHex(Value, BitwiseType.MinDigits or
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
    FFormatter: TRttixCustomTypeFormatter;
    function GetRttixType: IRttixType;
    function GetHasCustomFormatting: Boolean;
    function FormatText(const [ref] Instance): String;
    function FormatHint(const [ref] Instance): String;
    function FormatFull(const [ref] Instance): TRttixFullReflection;
    function Format(Formats: TRttixReflectionFormats; const [ref] Instance): TRttixFullReflection;
    constructor Create(
      [opt] const RttixType: IRttixType;
      [opt] Formatter: TRttixCustomTypeFormatter
    );
  end;

constructor TRttixTypeFormatter.Create;
begin
  FRttixType := RttixType;
  FFormatter := Formatter;
end;

function TRttixTypeFormatter.Format;
begin
  // Use the custom formatter first
  if Assigned(FFormatter) then
    Result := FFormatter(FRttixType, Instance, Formats)
  else
    Result.ValidFormats := [];

  // Fall back to generic text formatting
  if (rfText in Formats) and not (rfText in Result.ValidFormats) then
  begin
    if Assigned(FRttixType) then
      case FRttixType.SubKind of
        rtkEnumeration:
          Result.Text := RttixFormatEnum(FRttixType as IRttixEnumType,
            Instance);
        rtkBoolean:
          Result.Text := RttixFormatBool(FRttixType as IRttixBoolType,
            Instance);
        rtkBitwise:
          Result.Text := RttixFormatBitwise(FRttixType as IRttixBitwiseType,
            Instance);
        rtkDigits:
          Result.Text := RttixFormatDigits(FRttixType as IRttixDigitsType,
            Instance);
        rtkString:
          Result.Text := RttixFormatString(FRttixType as IRttixStringType,
            Instance);
      else
        Result.Text := '(' + FRttixType.TypeInfo.Name + ')';
      end
    else
      Result.Text := '(no type info)';

    Include(Result.ValidFormats, rfText);
  end;

  // Fall back to generic hint formatting
  if (rfHint in Formats) and not (rfHint in Result.ValidFormats) then
  begin
    if Assigned(FRttixType) then
      case FRttixType.SubKind of
        rtkEnumeration:
          Result.Hint := RttixFormatEnumHint(FRttixType as IRttixEnumType,
            Instance);
        rtkBitwise:
          Result.Hint := RttixFormatBitwiseHint(FRttixType as IRttixBitwiseType,
            Instance);
        rtkDigits:
          Result.Hint := RttixFormatDigitsHint(FRttixType as IRttixDigitsType,
            Instance);
      else
        Result.Hint := '';
      end
    else
      Result.Hint := '';

    Include(Result.ValidFormats, rfHint);
  end;
end;

function TRttixTypeFormatter.FormatFull;
begin
  Result := Format([rfText, rfHint], Instance);
end;

function TRttixTypeFormatter.FormatHint;
begin
  Result := Format([rfHint], Instance).Hint;
end;

function TRttixTypeFormatter.FormatText;
begin
  Result := Format([rfText], Instance).Text;
end;

function TRttixTypeFormatter.GetHasCustomFormatting;
begin
  Result := Assigned(FFormatter);
end;

function TRttixTypeFormatter.GetRttixType;
begin
  Result := FRttixType;
end;

function RttixMakeTypeFormatter;
var
  Index: Integer;
  RttixType: IRttixType;
  Formatter: TRttixCustomTypeFormatter;
begin
  Formatter := nil;

  if Assigned(TypeInfo) then
  begin
    RttixType := RttixTypeInfo(TypeInfo, FieldAttributes);
    Index := RttixFindTypeIndex(TypeInfo);

    if Index >= 0 then
      Formatter := RttixKnownFormatters[Index].Formatter;
  end
  else
    RttixType := nil;

  Result := TRttixTypeFormatter.Create(RttixType, Formatter);
end;

function RttixPreserveEnumCase;
type
  [NamingStyle(nsPreserveCase)]
  PreserveCase = type Pointer;
begin
  Result := RttixTypeInfo(TypeInfo(PreserveCase)).Attributes[0];
end;

{ Common }

function RttixFormat;
var
  Formatter: IRttixTypeFormatter;
begin
  Formatter := RttixMakeTypeFormatter(TypeInfo, FieldAttributes);
  Result := Formatter.FormatText(Instance);
end;

function RttixFormatFull;
var
  Formatter: IRttixTypeFormatter;
begin
  Formatter := RttixMakeTypeFormatter(TypeInfo, FieldAttributes);
  Result := Formatter.FormatFull(Instance);
end;

class function Rttix.Format<T>;
var
  Formatter: IRttixTypeFormatter;
begin
  Formatter := RttixMakeTypeFormatter(TypeInfo(T), FieldAttributes);
  Result := Formatter.FormatText(Instance);
end;

class function Rttix.FormatFull<T>;
var
  Formatter: IRttixTypeFormatter;
begin
  Formatter := RttixMakeTypeFormatter(TypeInfo(T), FieldAttributes);
  Result := Formatter.FormatFull(Instance);
end;

end.
