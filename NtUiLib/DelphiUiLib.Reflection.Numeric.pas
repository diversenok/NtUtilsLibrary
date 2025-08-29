unit DelphiUiLib.Reflection.Numeric;

{
  This module provides facilities for representing numeric types
  (such as enumerations and bit masks) as user-friendly text.
}

interface

uses
  DelphiApi.Reflection, System.Rtti, DelphiUiLib.Reflection;

type
  TNumericKind = (nkBool, nkDec, nkDecSigned, nkBytes, nkHex, nkEnum, nkBitwise);

  TFlagRepresentation = record
    Included: Boolean;
    Present: Boolean;
    Name: String;
    Value: UInt64;
  end;

  TSubEnumRepresentation = record
    Included: Boolean;
    Present: Boolean;
    Name: String;
    Value: UInt64;
    Mask: UInt64;
  end;

  TNumericRepresentation = record
    Basic: TRepresentation;
    Value: UInt64;
    Kind: TNumericKind;
    IsKnown: Boolean;                         // for enumerations
    KnownFlags: TArray<TFlagRepresentation>;  // for bitwise
    SubEnums: TArray<TSubEnumRepresentation>; // for bitwise
    UnknownBits: UInt64;                      // for bitwise
  end;

  // Do not include embedded enumerations into the reflection. Useful for
  // splitting the bit mask into state and flags.
  IgnoreSubEnumsAttribute = class (TCustomAttribute)
  end;

  // Do not include unnamed bits into the representation
  IgnoreUnnamedAttribute = class (TCustomAttribute)
  end;

  // Add a numeric prefix when representing a bitwise values
  AddPrefixAttribute = class (TCustomAttribute)
  end;

// Lookup a name for an value of an enumeration type
function RttixGetEnumName(
  [in] ATypeInfo: Pointer;
  Value: Cardinal;
  [opt] NamingStyle: NamingStyleAttribute = nil
): String;

// Internal use
procedure FillOrdinalReflection(
  const Context: TRttiContext;
  var Reflection: TNumericRepresentation;
  [opt] const Attributes: TArray<TCustomAttribute>
);

// Represent a numeric value by RTTI type
function GetNumericReflectionRtti(
  const Context: TRttiContext;
  RttiType: TRttiType;
  const Instance;
  [opt] const InstanceAttributes: TArray<TCustomAttribute> = nil
): TNumericRepresentation;

// Represent a numeric value by TypeInfo
function GetNumericReflection(
  AType: Pointer;
  const Instance; InstanceAttributes: TArray<TCustomAttribute> = nil
): TNumericRepresentation;

type
  TNumeric = class abstract
    // Represent a numeric value via a generic method
    class function Represent<T>(
      const Instance: T;
      [opt] const InstanceAttributes: TArray<TCustomAttribute> = nil
    ): TNumericRepresentation; static;
  end;

implementation

uses
  NtUtils.SysUtils, System.TypInfo, System.SysUtils, DelphiUiLib.Strings,
  DelphiUiLib.Reflection.Strings;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function IsBooleanType(AType: Pointer): Boolean;
begin
  Result := (AType = TypeInfo(Boolean)) or (AType = TypeInfo(ByteBool)) or
    (AType = TypeInfo(WordBool)) or (AType = TypeInfo(LongBool));
end;

procedure FillBooleanReflection(
  var Reflection: TNumericRepresentation;
  [opt] const Attributes: TArray<TCustomAttribute>
);
var
  a: TCustomAttribute;
  BoolKind: TBooleanKind;
begin
  BoolKind := bkTrueFalse;

  // Find known attributes
  for a in Attributes do
    if a is BooleanKindAttribute then
    begin
      BoolKind := BooleanKindAttribute(a).Kind;
      Break;
    end;

  Reflection.Kind := nkBool;
  Reflection.Basic.Text := BooleanToString(Reflection.Value <> 0, BoolKind);
end;

function RttixGetEnumName;
begin
  Result := GetEnumName(ATypeInfo, Integer(Value));

  // Prettify
  if Assigned(NamingStyle) then
    case NamingStyle.Style of
      nsPreserveCase:
        begin
          RtlxPrefixStripString(NamingStyle.Prefix, Result, True);
          RtlxSuffixStripString(NamingStyle.Suffix, Result, True);
        end;

      nsCamelCase:
        Result := PrettifyCamelCase(Result, NamingStyle.Prefix,
          NamingStyle.Suffix);

      nsSnakeCase:
        Result := PrettifySnakeCase(Result, NamingStyle.Prefix,
          NamingStyle.Suffix);
    end;
end;

procedure FillEnumReflection(
  var Reflection: TNumericRepresentation;
  RttiEnum: TRttiEnumerationType;
  [opt] const Attributes: TArray<TCustomAttribute>
);
var
  a: TCustomAttribute;
  Naming: NamingStyleAttribute;
  MinValue: MinValueAttribute;
  ValidValues: ValidValuesAttribute;
begin
  Naming := nil;
  MinValue := nil;
  ValidValues := nil;

  // Find known attributes
  for a in Attributes  do
    if a is NamingStyleAttribute then
      Naming := NamingStyleAttribute(a)
    else if a is MinValueAttribute then
      MinValue := MinValueAttribute(a)
    else if a is ValidValuesAttribute then
      ValidValues := ValidValuesAttribute(a);

  // To emit RTTI, enumerations must start with 0.
  // We use a custom attribute to further restrict the range.

  Reflection.Kind := nkEnum;
  Reflection.IsKnown := (not Assigned(MinValue) or
    (Cardinal(Reflection.Value) >= MinValue.MinValue)) and
    (not Assigned(ValidValues) or (Reflection.Value in ValidValues.Values)) and
    (Reflection.Value <= NativeUInt(Cardinal(RttiEnum.MaxValue)));

  if Reflection.IsKnown then
    Reflection.Basic.Text := RttixGetEnumName(RttiEnum.Handle,
      Cardinal(Reflection.Value), Naming)
  else
    Reflection.Basic.Text := IntToStr(Reflection.Value) + ' (out of bound)';

  Reflection.Basic.Hint := BuildHint('Value', IntToStr(Reflection.Value));
end;

procedure CollectBitwiseAttributes(
  const Context: TRttiContext;
  Attributes: TArray<TCustomAttribute>;
  out SubEnums: TArray<SubEnumAttribute>;
  out Flags: TArray<FlagNameAttribute>;
  out IgnoreUnnamed: Boolean;
  out IgnoreSubEnums: Boolean;
  out AddPrefix: Boolean;
  out HexDigits: Integer;
  out ValidMask: UInt64
);
var
  a: TCustomAttribute;
  ParentType: Pointer;
begin
  ParentType := nil;

  // Check if we should inherit attributes from the parent type
  for a in Attributes do
    if a is InheritsFromAttribute then
    begin
      ParentType := InheritsFromAttribute(a).TypeInfo;
      Break;
    end;

  // Merge attributes with the parent type
  if Assigned(ParentType) then
    Attributes := Concat(Attributes, Context.GetType(ParentType).GetAttributes);

  // Collect flags and sub-enums
  RttixFilterAttributes(Attributes, SubEnumAttribute,
    TCustomAttributeArray(SubEnums));
  RttixFilterAttributes(Attributes, FlagNameAttribute,
    TCustomAttributeArray(Flags));

  IgnoreSubEnums := False;
  IgnoreSubEnums := False;
  AddPrefix := False;
  HexDigits := 0;
  ValidMask := UInt64(-1);

  // Collect other known attributes
  for a in Attributes do
    if a is IgnoreUnnamedAttribute then
      IgnoreUnnamed := True
    else if a is IgnoreSubEnumsAttribute then
      IgnoreSubEnums := True
    else if a is AddPrefixAttribute then
      AddPrefix := True
    else if a is HexAttribute then
      HexDigits := HexAttribute(a).MinimalDigits
    else if a is ValidMaskAttribute then
      ValidMask := ValidMaskAttribute(a).Mask;
end;

procedure FillBitwiseReflection(
  const Context: TRttiContext;
  var Reflection: TNumericRepresentation;
  [opt] const Attributes: TArray<TCustomAttribute>
);
var
  Flags: TArray<FlagNameAttribute>;
  SubEnums: TArray<SubEnumAttribute>;
  IgnoreSubEnums, IgnoreUnnamed, AddPrefix: Boolean;
  HexDigits: Integer;
  ValidMask: UInt64;
  Strings: TArray<String>;
  i, Count: Integer;
begin
  Reflection.Kind := nkBitwise;
  Reflection.UnknownBits := Reflection.Value;
  Reflection.KnownFlags := nil;
  Reflection.SubEnums := nil;

  // Retrieve known attributes
  CollectBitwiseAttributes(Context, Attributes, SubEnums, Flags, IgnoreUnnamed,
    IgnoreSubEnums, AddPrefix, HexDigits, ValidMask);

  // Collect sub-enums
  SetLength(Reflection.SubEnums, Length(SubEnums));

  for i := 0 to High(SubEnums) do
  begin
    Reflection.SubEnums[i].Name := SubEnums[i].Name;
    Reflection.SubEnums[i].Value := SubEnums[i].Value;
    Reflection.SubEnums[i].Mask := SubEnums[i].Mask;
    Reflection.SubEnums[i].Present :=
      (Reflection.Value and SubEnums[i].Mask) = SubEnums[i].Value;
    Reflection.SubEnums[i].Included :=
      (Reflection.UnknownBits and SubEnums[i].Mask) = SubEnums[i].Value;

    if not IgnoreSubEnums and Reflection.SubEnums[i].Included then
      Reflection.UnknownBits := Reflection.UnknownBits and not SubEnums[i].Mask;
  end;

  // Collect bit flags
  SetLength(Reflection.KnownFlags, Length(Flags));

  for i := 0 to High(Flags) do
  begin
    Reflection.KnownFlags[i].Name := Flags[i].Name;
    Reflection.KnownFlags[i].Value := Flags[i].Value;
    Reflection.KnownFlags[i].Present :=
      (Reflection.Value and Flags[i].Value) = Flags[i].Value;
    Reflection.KnownFlags[i].Included :=
      (Reflection.UnknownBits and Flags[i].Value) = Flags[i].Value;

    if Reflection.KnownFlags[i].Included then
      Reflection.UnknownBits := Reflection.UnknownBits and not Flags[i].Value;
  end;

  // Count number of strings to combine
  Count := 0;

  if not IgnoreSubEnums then
    for i := 0 to High(Reflection.SubEnums) do
      if Reflection.SubEnums[i].Included then
        Inc(Count);

  for i := 0 to High(Reflection.KnownFlags) do
    if Reflection.KnownFlags[i].Included then
      Inc(Count);

  if not IgnoreUnnamed and (Reflection.UnknownBits <> 0) then
    Inc(Count);

  // Collect strings to combine
  SetLength(Strings, Count);

  Count := 0;

  if not IgnoreSubEnums then
    for i := 0 to High(Reflection.SubEnums) do
      if Reflection.SubEnums[i].Included then
      begin
        Strings[Count] := Reflection.SubEnums[i].Name;
        Inc(Count);
      end;

  for i := 0 to High(Reflection.KnownFlags) do
    if Reflection.KnownFlags[i].Included then
    begin
      Strings[Count] := Reflection.KnownFlags[i].Name;
      Inc(Count);
    end;

  if not IgnoreUnnamed and (Reflection.UnknownBits <> 0) then
  begin
    Strings[Count] := UiLibUIntToHex(Reflection.UnknownBits, HexDigits or
      NUMERIC_WIDTH_ROUND_TO_GROUP);
    Inc(Count);
  end;

  // Prepare the final text
  if Count = 0 then
  begin
    if AddPrefix then
      Reflection.Basic.Text := 'none'
    else
      Reflection.Basic.Text := '(none)';
  end
  else
    Reflection.Basic.Text := String.Join(', ', Strings, 0, Count);

  if AddPrefix then
    Reflection.Basic.Text := UiLibUIntToHex(Reflection.Value, HexDigits or
      NUMERIC_WIDTH_ROUND_TO_GROUP) + ' (' +
      Reflection.Basic.Text + ')';

  // Count number of flags to show in the hint
  Count := 0;

  for i := 0 to High(Reflection.KnownFlags) do
    if Reflection.KnownFlags[i].Value and ValidMask =
      Reflection.KnownFlags[i].Value then
      Inc(Count);

  // Prepare flag checkboxes
  Strings := nil;
  SetLength(Strings, Count);
  Count := 0;

  for i := 0 to High(Reflection.KnownFlags) do
    if Reflection.KnownFlags[i].Value and ValidMask =
      Reflection.KnownFlags[i].Value then
    begin
      Strings[Count] := Format('  %s %s', [
        CheckboxToString(Reflection.KnownFlags[i].Present),
        Reflection.KnownFlags[i].Name
      ]);
      Inc(Count);
    end;

  // Combine flag checkboxes
  if Length(Strings) > 0 then
    Reflection.Basic.Hint := 'Flags:'#$D#$A + String.Join(#$D#$A, Strings, 0,
      Count)
  else
    Reflection.Basic.Hint := '';

  // Count number of sub-enums to show in the hint
  Count := 0;

  for i := 0 to High(Reflection.SubEnums) do
    if Reflection.SubEnums[i].Mask and ValidMask =
      Reflection.SubEnums[i].Mask then
      Inc(Count);

  // Prepare options checkboxes
  Strings := nil;
  SetLength(Strings, Count);
  Count := 0;

  for i := 0 to High(Reflection.SubEnums) do
    if Reflection.SubEnums[i].Mask and ValidMask =
      Reflection.SubEnums[i].Mask then
    begin
      Strings[Count] := Format('  %s %s', [
        CheckboxToString(Reflection.SubEnums[i].Present),
        Reflection.SubEnums[i].Name
      ]);
      Inc(Count);
    end;

  // Combine sub-enum checkboxes
  if Length(Strings) > 0 then
  begin
    if Reflection.Basic.Hint <> '' then
      Reflection.Basic.Hint := Reflection.Basic.Hint + #$D#$A;

    Reflection.Basic.Hint := Reflection.Basic.Hint +
      'Options:'#$D#$A + String.Join(#$D#$A, Strings, 0, Count);
  end;
end;

procedure FillOrdinalReflection;
var
  a: TCustomAttribute;
  Bytes: Boolean;
  Hex: HexAttribute;
  BitwiseType: Boolean;
begin
  Hex := nil;
  Bytes := False;
  BitwiseType := False;

  // Find known attributes
  for a in Attributes do
  begin
    if (a is FlagNameAttribute) or (a is SubEnumAttribute) then
    begin
      BitwiseType := True;
      Break;
    end;

    Bytes := Bytes or (a is BytesAttribute);

    if a is HexAttribute then
      Hex := HexAttribute(a);
  end;

  // Convert
  if BitwiseType then
  begin
    Reflection.Kind := nkBitwise;
    FillBitwiseReflection(Context, Reflection, Attributes);
  end
  else if Assigned(Hex) then
  begin
    Reflection.Kind := nkHex;
    Reflection.Basic.Text := UiLibUIntToHex(Reflection.Value,
      Hex.MinimalDigits or NUMERIC_WIDTH_ROUND_TO_GROUP);
    Reflection.Basic.Hint := 'Value (decimal):'#$D#$A'  ' + UiLibUIntToDec(
      Reflection.Value);
  end
  else if Bytes then
  begin
    Reflection.Kind := nkBytes;
    Reflection.Basic.Text := BytesToString(Reflection.Value);
    Reflection.Basic.Hint := 'Bytes:'#$D#$A'  ' + UiLibUIntToDec(
      Reflection.Value);
  end
  else
  begin
    Reflection.Kind := nkDec;
    Reflection.Basic.Text := UiLibUIntToDec(Reflection.Value);
    Reflection.Basic.Hint := 'Value (hex):'#$D#$A'  ' + UiLibUIntToHex(
      Reflection.Value);
  end;
end;

function GetNumericReflectionRtti;
var
  Attributes: TArray<TCustomAttribute>;
begin
  Result := Default(TNumericRepresentation);
  Result.Basic.TypeName := RttiType.Name;

  // Capture the data
  if RttiType is TRttiInt64Type then
    Result.Value := UInt64(Instance)
  else if RttiType is TRttiOrdinalType then
  case TRttiOrdinalType(RttiType).OrdType of
    otSLong, otULong: Result.Value := Cardinal(Instance);
    otSWord, otUWord: Result.Value := Word(Instance);
    otSByte, otUByte: Result.Value := Byte(Instance);
  end
  else
    Assert(False, 'Not a numeric type');

  // Combine available attributes
  Attributes := Concat(RttiType.GetAttributes, InstanceAttributes);

  // Fill information according to the type
  if IsBooleanType(RttiType.Handle) then
    FillBooleanReflection(Result, Attributes)
  else if RttiType is TRttiEnumerationType then
    FillEnumReflection(Result, RttiType as TRttiEnumerationType, Attributes)
  else
    FillOrdinalReflection(Context, Result, Attributes);
end;

function GetNumericReflection;
var
  Context: TRttiContext;
begin
  Context := TRttiContext.Create;
  Result := GetNumericReflectionRtti(Context, Context.GetType(AType), Instance,
    InstanceAttributes);
end;

class function TNumeric.Represent<T>;
var
  AsByte: Byte absolute Instance;
  AsWord: Word absolute Instance;
  AsCardinal: Cardinal absolute Instance;
  AsUInt64: UInt64 absolute Instance;
begin
  if not Assigned(TypeInfo(T)) then
  begin
    Result := Default(TNumericRepresentation);

    // Handle enumerations with no TypeInfo
    case SizeOf(T) of
      SizeOf(Byte): Result.Value := AsByte;
      SizeOf(Word): Result.Value := AsWord;
      SizeOf(Cardinal): Result.Value := AsCardinal;
      SizeOf(UInt64): Result.Value := AsUInt64;
    else
      Assert(False, 'Not a numeric type');
      Exit;
    end;

    FillOrdinalReflection(TRttiContext.Create, Result, InstanceAttributes);
  end
  else
    Result := GetNumericReflection(TypeInfo(T), Instance, InstanceAttributes);
end;

end.
