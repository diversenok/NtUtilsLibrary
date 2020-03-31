unit DelphiUtils.Reflection;

interface

uses
  System.TypInfo, DelphiApi.Reflection;

type
  TNumericKind = (nkBool, nkDec, nkDecSigned, nkBytes, nkHex, nkEnum, nkBitwise);

  TFlagReflection = record
    Presents: Boolean;
    Flag: TFlagName;
  end;

  TNumericReflection = record
    Kind: TNumericKind;
    Value: UInt64;
    Name: String;
    IsKnown: Boolean;                    // for enumerations
    KnownFlags: TArray<TFlagReflection>; // for bitwise
    UnknownBits: UInt64;                 // for bitwise
  end;

// Introspect a numeric value
function GetNumericReflection(AType: PTypeInfo; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute> = nil): TNumericReflection;

// Map bitwise flags using a flag provider
function MapFlagsByProvider(Value: UInt64; Provider: TFlagProvider): String;

// Map a state from bitwise flags using a flag provider
function MapStateByProvider(Value: UInt64; Provider: TFlagProvider): String;

// Map bitwise flags exculding state using a flag provider
function MapFlagsOnlyByProvider(Value: UInt64; Provider: TFlagProvider): String;

implementation

uses
  System.Rtti, System.SysUtils, DelphiUtils.Strings;

function IsBooleanType(AType: PTypeInfo): Boolean;
begin
  Result := (AType = TypeInfo(Boolean)) or (AType = TypeInfo(ByteBool)) or
    (AType = TypeInfo(WordBool)) or (AType = TypeInfo(LongBool));
end;

procedure FillBooleanReflection(var Reflection: TNumericReflection;
  Attributes: TArray<TCustomAttribute>);
var
  a: TCustomAttribute;
  BoolKind: TBooleanKind;
begin
  BoolKind := bkTrueFalse;

  // Find known attributes
  for a in Attributes do
    if a is BooleanKindAttribute then
      BoolKind := BooleanKindAttribute(a).Kind;

  Reflection.Kind := nkBool;

  // Select corresponding representation
  with Reflection do
    case BoolKind of
      bkEnabledDisabled:   Name := EnabledDisabledToString(Value <> 0);
      bkAllowedDisallowed: Name := AllowedDisallowedToString(Value <> 0);
      bkYesNo:             Name := YesNoToString(Value <> 0);
    else
      Name := TrueFalseToString(Value <> 0);
    end;
end;

function GetEnumNameEx(Enum: TRttiEnumerationType; Value: Cardinal;
  Naming: NamingStyleAttribute): String;
begin
  Result := GetEnumName(Enum.Handle, Integer(Value));

  // Prettify
  if Assigned(Naming) then
    case Naming.NamingStyle of
      nsCamelCase:
        Result := PrettifyCamelCase(Result, Naming.Prefix, Naming.Suffix);

      nsSnakeCase:
        Result := PrettifySnakeCase(Result, Naming.Prefix, Naming.Suffix);
    end;
end;

procedure FillEnumReflection(var Reflection: TNumericReflection;
  RttiEnum: TRttiEnumerationType; Attributes: TArray<TCustomAttribute>);
var
  a: TCustomAttribute;
  Naming: NamingStyleAttribute;
  Range: RangeAttribute;
  Mask: ValidMaskAttribute;
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
    else if a is ValidMaskAttribute then
      Mask := ValidMaskAttribute(a);

  with Reflection do
  begin
    // To emit RTTI, enumerations must start with 0.
    // We use a custom attribute to further restrict the range.

    Kind := nkEnum;
    IsKnown := (not Assigned(Range) or Range.Check(Cardinal(Value))) and
      (not Assigned(Mask) or Mask.Check(Cardinal(Value))) and
      (Value <= NativeUInt(Cardinal(RttiEnum.MaxValue)));

    if IsKnown then
      Name := GetEnumNameEx(RttiEnum, Cardinal(Value), Naming)
    else
      Name := IntToStr(Value) + ' (out of bound)';
  end;
end;

procedure FillBitwiseReflection(var Reflection: TNumericReflection;
  FlagProvider: TFlagProvider);
var
  i: Integer;
  Flags: TFlagNames;
begin
  Reflection.Kind := nkBitwise;

  if Reflection.Value = 0 then
  begin
    Reflection.Name := '(none)';
    Exit;
  end;

  Reflection.UnknownBits := Reflection.Value;
  Flags := FlagProvider.Flags;
  SetLength(Reflection.KnownFlags, Length(Flags));

  // Capture each flag information
  for i := 0 to High(Flags) do
    with Reflection.KnownFlags[i] do
    begin
      Flag := Flags[i];
      Presents := Reflection.Value and Flag.Value <> 0;
      Reflection.UnknownBits := Reflection.UnknownBits and not Flag.Value;
    end;

  // Format the name
  Reflection.Name := MapFlags(Reflection.Value, Flags, True,
    FlagProvider.Default, FlagProvider.StateMask);
end;

procedure FillOrdinalReflection(var Reflection: TNumericReflection;
  Attributes: TArray<TCustomAttribute>);
var
  a: TCustomAttribute;
  Bytes: Boolean;
  Hex: HexAttribute;
  RttiContext: TRttiContext;
  Bitwise: TFlagProvider;
begin
  RttiContext := TRttiContext.Create;
  Hex := nil;
  Bytes := False;
  Bitwise:= nil;

  // Find known attributes
  for a in Attributes do
  begin
    Bytes := Bytes or (a is BytesAttribute);

    if a is HexAttribute then
      Hex := HexAttribute(a);

    if a is BitwiseAttribute then
      Bitwise := BitwiseAttribute(a).Provider;
  end;

  // Convert
  if Assigned(Bitwise) then
  begin
    Reflection.Kind := nkBitwise;
    FillBitwiseReflection(Reflection, Bitwise);
  end
  else if Assigned(Hex) then
  begin
    Reflection.Kind := nkHex;
    Reflection.Name := IntToHexEx(Reflection.Value, Hex.Digits);
  end
  else if Bytes then
  begin
    Reflection.Kind := nkBytes;
    Reflection.Name := BytesToString(Reflection.Value);
  end
  else
  begin
    Reflection.Kind := nkDec;
    Reflection.Name := IntToStrEx(Reflection.Value);
  end;
end;

function GetNumericReflection(AType: PTypeInfo; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute>): TNumericReflection;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  Attributes: TArray<TCustomAttribute>;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(AType);

  // Capture the data
  if RttiType is TRttiInt64Type then
    Result.Value := UInt64(Instance^)
  else case (RttiType as TRttiOrdinalType).OrdType of
    otSLong, otULong: Result.Value := Cardinal(Instance^);
    otSWord, otUWord: Result.Value := Word(Instance^);
    otSByte, otUByte: Result.Value := Byte(Instance^);
  end;

  // Combine available attributes
  Attributes := Concat(RttiType.GetAttributes, InstanceAttributes);

  // Fill information according to the type
  if IsBooleanType(AType) then
    FillBooleanReflection(Result, Attributes)
  else if RttiType is TRttiEnumerationType then
    FillEnumReflection(Result, RttiType as TRttiEnumerationType, Attributes)
  else
    FillOrdinalReflection(Result, Attributes);
end;

function MapFlagsByProvider(Value: UInt64; Provider: TFlagProvider): String;
begin
  Result := MapFlags(Value, Provider.Flags, True, Provider.Default,
    Provider.StateMask);
end;

function MapStateByProvider(Value: UInt64; Provider: TFlagProvider): String;
begin
  Result := MapFlags(Value and Provider.StateMask, Provider.Flags, False,
    Provider.Default, Provider.StateMask);
end;

function MapFlagsOnlyByProvider(Value: UInt64; Provider: TFlagProvider): String;
begin
  Result := MapFlags(Value and not Provider.StateMask, Provider.Flags, True,
    Provider.Default, Provider.StateMask);
end;

end.
