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
    Flag: TFlagName;
  end;

  TSubEnumRepresentation = record
    Included: Boolean;
    Present: Boolean;
    Flag: TFlagName;
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
  System.TypInfo, System.SysUtils, DelphiUiLib.Reflection.Strings,
  DelphiUiLib.Strings;

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

  // Select corresponding representation
  case BoolKind of
    bkEnabledDisabled:
      Reflection.Basic.Text := EnabledDisabledToString(
        LongBool(Reflection.Value));

    bkAllowedDisallowed:
      Reflection.Basic.Text := AllowedDisallowedToString(
        LongBool(Reflection.Value));

    bkYesNo:
      Reflection.Basic.Text := YesNoToString(LongBool(
        Reflection.Value));

  else
    Reflection.Basic.Text := TrueFalseToString(LongBool(Reflection.Value));
  end;
end;

function RttixGetEnumName;
begin
  Result := GetEnumName(ATypeInfo, Integer(Value));

  // Prettify
  if Assigned(NamingStyle) then
    case NamingStyle.NamingStyle of
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
  Range: RangeAttribute;
  Mask: ValidBitsAttribute;
begin
  Naming := nil;
  Range := nil;
  Mask := nil;

  // Find known attributes
  for a in Attributes  do
    if a is NamingStyleAttribute then
      Naming := NamingStyleAttribute(a)
    else if a is RangeAttribute then
      Range := RangeAttribute(a)
    else if a is ValidBitsAttribute then
      Mask := ValidBitsAttribute(a);

  // To emit RTTI, enumerations must start with 0.
  // We use a custom attribute to further restrict the range.

  Reflection.Kind := nkEnum;
  Reflection.IsKnown := (not Assigned(Range) or
    Range.Check(Cardinal(Reflection.Value))) and
    (not Assigned(Mask) or Mask.Check(Cardinal(Reflection.Value))) and
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
      HexDigits := HexAttribute(a).Digits
    else if a is ValidBitsAttribute then
      ValidMask := ValidBitsAttribute(a).ValidMask;
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
    Reflection.SubEnums[i].Flag := SubEnums[i].Flag;
    Reflection.SubEnums[i].Mask := SubEnums[i].Mask;
    Reflection.SubEnums[i].Present :=
      (Reflection.Value and SubEnums[i].Mask) = SubEnums[i].Flag.Value;
    Reflection.SubEnums[i].Included :=
      (Reflection.UnknownBits and SubEnums[i].Mask) = SubEnums[i].Flag.Value;

    if not IgnoreSubEnums and Reflection.SubEnums[i].Included then
      Reflection.UnknownBits := Reflection.UnknownBits and not SubEnums[i].Mask;
  end;

  // Collect bit flags
  SetLength(Reflection.KnownFlags, Length(Flags));

  for i := 0 to High(Flags) do
  begin
    Reflection.KnownFlags[i].Flag := Flags[i].Flag;
    Reflection.KnownFlags[i].Present :=
      (Reflection.Value and Flags[i].Flag.Value) = Flags[i].Flag.Value;
    Reflection.KnownFlags[i].Included :=
      (Reflection.UnknownBits and Flags[i].Flag.Value) = Flags[i].Flag.Value;

    if Reflection.KnownFlags[i].Included then
      Reflection.UnknownBits := Reflection.UnknownBits and not Flags[i].Flag.Value;
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
        Strings[Count] := Reflection.SubEnums[i].Flag.Name;
        Inc(Count);
      end;

  for i := 0 to High(Reflection.KnownFlags) do
    if Reflection.KnownFlags[i].Included then
    begin
      Strings[Count] := Reflection.KnownFlags[i].Flag.Name;
      Inc(Count);
    end;

  if not IgnoreUnnamed and (Reflection.UnknownBits <> 0) then
  begin
    Strings[Count] := IntToHexEx(Reflection.UnknownBits, HexDigits);
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
    Reflection.Basic.Text := IntToHexEx(Reflection.Value, HexDigits) + ' (' +
      Reflection.Basic.Text + ')';

  // Count number of flags to show in the hint
  Count := 0;

  for i := 0 to High(Reflection.KnownFlags) do
    if Reflection.KnownFlags[i].Flag.Value and ValidMask =
      Reflection.KnownFlags[i].Flag.Value then
      Inc(Count);

  // Prepare flag checkboxes
  Strings := nil;
  SetLength(Strings, Count);
  Count := 0;

  for i := 0 to High(Reflection.KnownFlags) do
    if Reflection.KnownFlags[i].Flag.Value and ValidMask =
      Reflection.KnownFlags[i].Flag.Value then
    begin
      Strings[Count] := Format('  %s %s', [
        CheckboxToString(Reflection.KnownFlags[i].Present),
        Reflection.KnownFlags[i].Flag.Name
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
        Reflection.SubEnums[i].Flag.Name
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
    Reflection.Basic.Text := IntToHexEx(Reflection.Value, Hex.Digits);
    Reflection.Basic.Hint := 'Value (decimal):'#$D#$A'  ' +
      IntToStrEx(Reflection.Value);
  end
  else if Bytes then
  begin
    Reflection.Kind := nkBytes;
    Reflection.Basic.Text := BytesToString(Reflection.Value);
    Reflection.Basic.Hint := 'Bytes:'#$D#$A'  ' + IntToStrEx(Reflection.Value);
  end
  else
  begin
    Reflection.Kind := nkDec;
    Reflection.Basic.Text := IntToStrEx(Reflection.Value);
    Reflection.Basic.Hint := 'Value (hex):'#$D#$A'  ' +
      IntToHexEx(Reflection.Value);
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
