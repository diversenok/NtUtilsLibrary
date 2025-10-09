unit DelphiUiLib.LiteReflection;

{
  This module provides lightweight reflection support for represnting various
  types.
}

interface

uses
  DelphiApi.Reflection, DelphiUtils.LiteRTTI;

type
  TRttixReflectionFormat = (rfText, rfHint);
  TRttixReflectionFormats = set of TRttixReflectionFormat;

  TRttixFieldReflectionOption = (
    frDoNotAggregate,  // Return only immediate fields; don't honor [Aggregate]
    frIncludeUntyped,  // Include fields without type information
    frIncludeUnlisted, // Include fields marked as [Unlisted]
    frIncludeInternal, // Include fields marked as [RecordSize] or [Offset]
    frIncludeNewerVersions // Include fields for newer OS version than the current
  );
  TRttixFieldReflectionOptions = set of TRttixFieldReflectionOption;

  TRttixFullReflection = record
    ValidFormats: TRttixReflectionFormats;
    Text: String;
    Hint: String;
  end;

  IRttixTypeFormatter = interface
    ['{DDB726E6-F711-46CB-943A-1C1EA0BE4C66}']
    function GetRttixType: IRttixType;
    function GetHasCustomFormatting: Boolean;

    property RttixType: IRttixType read GetRttixType;
    property HasCustomFormatting: Boolean read GetHasCustomFormatting;
    function FormatText(const [ref] Instance): String;
    function FormatHint(const [ref] Instance): String;
    function Format(const [ref] Instance;
      Formats: TRttixReflectionFormats): TRttixFullReflection;
  end;

  IRttixFieldFormatter = interface
    ['{457B9A50-E58B-4A23-8910-CD2E0F09E82E}']
    function GetScopingType: IRttixType;
    function GetRecordType: IRttixRecordType;
    function GetField: IRttixField;
    function GetFormatter: IRttixTypeFormatter;

    property ScopingType: IRttixType read GetScopingType;
    property RecordType: IRttixRecordType read GetRecordType;
    property Field: IRttixField read GetField;
    property Formatter: IRttixTypeFormatter read GetFormatter;
    function FormatText(const [ref] ScopingInstance): String;
    function FormatHint(const [ref] ScopingInstance): String;
    function Format(const [ref] ScopingInstance;
      Formats: TRttixReflectionFormats): TRttixFullReflection;
  end;

  TRttixFullFieldReflection = record
    Field: IRttixField;
    Reflection: TRttixFullReflection;
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

// Prepare a formatter for representing a specific type from its type info
function RttixMakeTypeFormatter(
  [opt] TypeInfo: PLiteRttiTypeInfo;
  const ExtraAttributes: TArray<PLiteRttiAttribute> = nil
): IRttixTypeFormatter;

// Prepare formatter for representing a specific type from its RTTI info
function RttixMakeTypeFormatterForType(
  [opt] const RttixType: IRttixType
): IRttixTypeFormatter;

// Prepare formatters for representing fields of a specific record type
// or a record pointer type
function RttixMakeFieldFormatters(
  TypeInfo: PLiteRttiTypeInfo;
  Options: TRttixFieldReflectionOptions = [];
  const ExtraAttributes: TArray<PLiteRttiAttribute> = nil
): TArray<IRttixFieldFormatter>;

// An attribute indicating that reflection should presetve enumeration names
function RttixPreserveEnumCase(
): TArray<PLiteRttiAttribute>;

// An attribute indicating that reflection should not follow pointers
function RttixDontFollowPointers(
): TArray<PLiteRttiAttribute>;

// Represent a type as text from raw type info
function RttixFormat(
  TypeInfo: PLiteRttiTypeInfo;
  const [ref] Instance;
  const ExtraAttributes: TArray<PLiteRttiAttribute> = nil
): String;

// Represent a type as text and hint from raw type info
function RttixFormatFull(
  TypeInfo: PLiteRttiTypeInfo;
  const [ref] Instance;
  const ExtraAttributes: TArray<PLiteRttiAttribute> = nil
): TRttixFullReflection;

// Represent fields of a record type as text/hint from raw type info
function RttixFormatFields(
  TypeInfo: PLiteRttiTypeInfo;
  const [ref] Instance;
  Formats: TRttixReflectionFormats;
  Options: TRttixFieldReflectionOptions = [];
  const ExtraAttributes: TArray<PLiteRttiAttribute> = nil
): TArray<TRttixFullFieldReflection>;

type
  Rttix = record
    // Represent a known type as text from a generic parameter
    class function Format<T>(
      const Instance: T;
      const ExtraAttributes: TArray<PLiteRttiAttribute> = nil
    ): String; static;

    // Represent a known type as text and hint from a generic parameter
    class function FormatFull<T>(
      const Instance: T;
      const ExtraAttributes: TArray<PLiteRttiAttribute> = nil
    ): TRttixFullReflection; static;

    // Represent fields of a known record or record pointer type as text/hint
    // from a generic parameter
    class function FormatFields<T>(
      const Instance: T;
      Formats: TRttixReflectionFormats;
      Options: TRttixFieldReflectionOptions = [];
      const ExtraAttributes: TArray<PLiteRttiAttribute> = nil
    ): TArray<TRttixFullFieldReflection>; static;
  end;

implementation

uses
  DelphiApi.TypInfo, NtUtils.SysUtils, DelphiUtils.Arrays, DelphiUiLib.Strings,
  DelphiUtils.AutoObjects, Ntapi.Versions;

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
    function (const Entry: TRttixFormatterEntry): Integer
    var
      Difference: IntPtr;
    begin
      {$Q-}{$R-}
      Difference := IntPtr(Entry.TypeInfo) - IntPtr(TypeInfo);
      {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

      if Difference > 0 then
        Result := 1
      else if Difference < 0 then
        Result := -1
      else
        Result := 0;
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
      Result := UiLibAsciiMagicToString(Value);
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

function RttixFormatPointer(
  const PointerType: IRttixPointerType;
  const [ref] Instance
): String;
var
  Value: Pointer absolute Instance;
begin
  if Assigned(Value) then
    Result := '(' + UiLibUIntToHex(UIntPtr(Value)) + ' as ' +
      PointerType.TypeInfo.Name + ')'
  else
    Result := '(nil)';
end;

{ Formatters }

type
  TRttixTypeFormatter = class (TAutoInterfacedObject, IRttixTypeFormatter)
    FRttixType: IRttixType;
    FFormatter: TRttixCustomTypeFormatter;
    FInner: IRttixTypeFormatter;
    function GetRttixType: IRttixType;
    function GetHasCustomFormatting: Boolean;
    function FormatText(const [ref] Instance): String;
    function FormatHint(const [ref] Instance): String;
    function Format(const [ref] Instance;
      Formats: TRttixReflectionFormats): TRttixFullReflection;
    constructor Create(
      [opt] const RttixType: IRttixType;
      [opt] Formatter: TRttixCustomTypeFormatter
    );
  end;

constructor TRttixTypeFormatter.Create;
var
  PointerType: IRttixPointerType;
begin
  FRttixType := RttixType;
  FFormatter := Formatter;

  // Pointer types delegate formatting to the referenced type
  if not Assigned(FFormatter) and Assigned(FRttixType) and
    (FRttixType.SubKind = rtkPointer) then
  begin
    PointerType := FRttixType as IRttixPointerType;

    if not PointerType.DontFollow and Assigned(PointerType.ReferncedType) then
      FInner := RttixMakeTypeFormatterForType(PointerType.ReferncedType);
  end;
end;

function TRttixTypeFormatter.Format;
begin
  // Use the custom formatter first, then delegate pointer formatting
  if Assigned(FFormatter) then
    Result := FFormatter(FRttixType, Instance, Formats)
  else if Assigned(FInner) and Assigned(Pointer(Instance)) then
    Result := FInner.Format(Pointer(Instance)^, Formats)
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
        rtkPointer:
          Result.Text := RttixFormatPointer(FRttixType as IRttixPointerType,
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

function TRttixTypeFormatter.FormatHint;
begin
  Result := Format(Instance, [rfHint]).Hint;
end;

function TRttixTypeFormatter.FormatText;
begin
  Result := Format(Instance, [rfText]).Text;
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
    RttixType := RttixTypeInfo(TypeInfo, ExtraAttributes);
    Index := RttixFindTypeIndex(TypeInfo);

    if Index >= 0 then
      Formatter := RttixKnownFormatters[Index].Formatter;
  end
  else
    RttixType := nil;

  Result := TRttixTypeFormatter.Create(RttixType, Formatter);
end;

function RttixMakeTypeFormatterForType;
var
  Index: Integer;
  Formatter: TRttixCustomTypeFormatter;
begin
  Formatter := nil;

  if Assigned(RttixType) then
  begin
    Index := RttixFindTypeIndex(RttixType.TypeInfo);

    if Index >= 0 then
      Formatter := RttixKnownFormatters[Index].Formatter;
  end;

  Result := TRttixTypeFormatter.Create(RttixType, Formatter);
end;

type
  TRttixFieldFormatter = class (TAutoInterfacedObject, IRttixFieldFormatter)
    FScopingType: IRttixType;
    FRecordType: IRttixRecordType;
    FPointerDepth: Integer;
    FField: IRttixField;
    FFormatter: IRttixTypeFormatter;
    function GetScopingType: IRttixType;
    function GetRecordType: IRttixRecordType;
    function GetField: IRttixField;
    function GetFormatter: IRttixTypeFormatter;
    function FormatText(const [ref] ScopingInstance): String;
    function FormatHint(const [ref] ScopingInstance): String;
    function Format(const [ref] ScopingInstance;
      Formats: TRttixReflectionFormats): TRttixFullReflection;
    constructor Create(
      const ScopingType: IRttixType;
      const RecordType: IRttixRecordType;
      PointerDepth: Integer;
      const Field: IRttixField
    );
  end;

constructor TRttixFieldFormatter.Create;
begin
  inherited Create;
  FScopingType := ScopingType;
  FRecordType := RecordType;
  FPointerDepth := PointerDepth;
  FField := Field;
  FFormatter := RttixMakeTypeFormatterForType(FField.FieldType);
end;

function TRttixFieldFormatter.Format;
var
  RecordStart: PByte;
  i: Integer;
begin
  // Follow pointers until we find the record start
  RecordStart := @ScopingInstance;

  for i := 0 to Pred(FPointerDepth) do
    RecordStart := PPointer(RecordStart)^;

  // Locate the field and use its formatter
  Result := FFormatter.Format((RecordStart + FField.Offset)^, Formats);
end;

function TRttixFieldFormatter.FormatHint;
begin
  Result := Format(ScopingInstance, [rfHint]).Hint;
end;

function TRttixFieldFormatter.FormatText;
begin
  Result := Format(ScopingInstance, [rfText]).Text;
end;

function TRttixFieldFormatter.GetField;
begin
  Result := FField;
end;

function TRttixFieldFormatter.GetFormatter;
begin
  Result := FFormatter;
end;

function TRttixFieldFormatter.GetRecordType;
begin
  Result := FRecordType;
end;

function TRttixFieldFormatter.GetScopingType;
begin
  Result := FScopingType;
end;

function RttixFieldFilter(
  Options: TRttixFieldReflectionOptions
): TCondition<IRttixField>;
var
  CurrentVersion: TWindowsVersion;
begin
  CurrentVersion := RtlOsVersion;

  Result := function (const Field: IRttixField): Boolean
    begin
      Result := (Assigned(Field.FieldType) or (frIncludeUntyped in Options)) and
        (not Field.Unlisted or (frIncludeUnlisted in Options)) and
        (not (Field.IsRecordSize or Field.IsOffset) or (frIncludeInternal in Options)) and
        ((Field.MinOsVersion <= CurrentVersion) or (frIncludeNewerVersions in Options));
    end;
end;

function RttixMakeFieldFormatters;
var
  ScopingType, NestedType: IRttixType;
  RecordType: IRttixRecordType;
  PointerDepth: Integer;
  Fields: TArray<IRttixField>;
  i: Integer;
begin
  ScopingType := RttixTypeInfo(TypeInfo, ExtraAttributes);
  PointerDepth := 0;

  // Determine the pointer depth and extract the nested record type
  NestedType := ScopingType;
  while Assigned(NestedType) and (NestedType.SubKind = rtkPointer) do
  begin
    NestedType := (NestedType as IRttixPointerType).ReferncedType;
    Inc(PointerDepth);
  end;

  if not Assigned(NestedType) or (NestedType.SubKind <> rtkRecord) then
    Exit(nil);

  RecordType := NestedType as IRttixRecordType;

  // Collect fields
  if frDoNotAggregate in Options then
    Fields := RecordType.ImmediateFields
  else
    Fields := RecordType.EffectiveFields;

  // Remove uninteresting fields
  TArray.FilterInline<IRttixField>(Fields, RttixFieldFilter(Options));

  // Prepare formatters
  SetLength(Result, Length(Fields));

  for i := 0 to High(Fields) do
    Result[i] := TRttixFieldFormatter.Create(ScopingType, RecordType,
      PointerDepth, Fields[i]);
end;

function RttixPreserveEnumCase;
type
  [NamingStyle(nsPreserveCase)]
  PreserveCase = type Pointer;
begin
  Result := RttixTypeInfo(TypeInfo(PreserveCase)).Attributes;
end;

function RttixDontFollowPointers;
type
  [DontFollow]
  DontFollowPointers = type Pointer;
begin
  Result := RttixTypeInfo(TypeInfo(DontFollowPointers)).Attributes;
end;

{ Common }

function RttixFormat;
var
  Formatter: IRttixTypeFormatter;
begin
  Formatter := RttixMakeTypeFormatter(TypeInfo, ExtraAttributes);
  Result := Formatter.FormatText(Instance);
end;

function RttixFormatFull;
var
  Formatter: IRttixTypeFormatter;
begin
  Formatter := RttixMakeTypeFormatter(TypeInfo, ExtraAttributes);
  Result := Formatter.Format(Instance, [rfText, rfHint]);
end;

function RttixFormatFields;
var
  Formatters: TArray<IRttixFieldFormatter>;
  i: Integer;
begin
  Formatters := RttixMakeFieldFormatters(TypeInfo, Options, ExtraAttributes);
  SetLength(Result, Length(Formatters));

  for i := 0 to High(Result) do
  begin
    Result[i].Field := Formatters[i].Field;
    Result[i].Reflection := Formatters[i].Format(Instance, Formats);
  end;
end;

class function Rttix.Format<T>;
begin
  Result := RttixFormat(TypeInfo(T), Instance, ExtraAttributes);
end;

class function Rttix.FormatFields<T>;
begin
  Result := RttixFormatFields(TypeInfo(T), Instance, Formats, Options,
    ExtraAttributes);
end;

class function Rttix.FormatFull<T>;
begin
  Result := RttixFormatFull(TypeInfo(T), Instance, ExtraAttributes);
end;

end.
