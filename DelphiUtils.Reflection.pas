unit DelphiUtils.Reflection;

interface

uses
  System.TypInfo, System.Rtti, DelphiApi.Reflection;

type
  TOrdinalReflection = record
    Value: Cardinal;
    Known: Boolean; // for enumerations
    Name: String;
  end;

  TBitReflection = record
    Bit: Cardinal;
    Present: Boolean;
    Known: Boolean;
    Name: String;
  end;

  TBitiwseReflection = record
    Value: Cardinal;
    UnknownBits: Cardinal;
    Bits: array [0..31] of TBitReflection;
    FullName: String;
  end;

// Get a value of an ordinal
function CaptureOrdinal(Ordinal: TRttiOrdinalType; Instance: Pointer): Cardinal;

// Introspect an ordinal
function GetOrdinalReflection(OrdinalType: PTypeInfo; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute> = nil): TOrdinalReflection;

// Introspect a bitwise type
function GetBitwiseReflection(BitEnumType, ValueType: PTypeInfo;
  Instance: Pointer; InstanceAttributes: TArray<TCustomAttribute> = nil):
  TBitiwseReflection;

implementation

uses
  System.SysUtils, DelphiUtils.Strings;

function CaptureOrdinal(Ordinal: TRttiOrdinalType; Instance: Pointer): Cardinal;
begin
  // Get the instance's data
  case Ordinal.OrdType of
    otSByte, otUByte: Result := Byte(Instance^);
    otSWord, otUWord: Result := Word(Instance^);
    otSLong, otULong: Result := Cardinal(Instance^);
  else
    Result := 0;
  end;
end;

function IsBooleanType(AType: PTypeInfo): Boolean;
begin
  Result := (AType = TypeInfo(Boolean)) or (AType = TypeInfo(WordBool)) or
    (AType = TypeInfo(LongBool));
end;

function GetBoolReflection(RttiType: TRttiOrdinalType; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute>): TOrdinalReflection;
var
  a: TCustomAttribute;
  Kind: TBooleanKind;
begin
  Kind := bkTrueFalse;

  // Find known attributes
  for a in Concat(RttiType.GetAttributes, InstanceAttributes) do
    if a is BooleanKindAttribute then
      Kind := BooleanKindAttribute(a).Kind;

  // Boolean types are enumerations with weird range, handle them differently
  with Result do
  begin
    Result.Value := CaptureOrdinal(RttiType, Instance);
    Result.Known := True;

    case Kind of
      bkEnabledDisabled:   Name := EnabledDisabledToString(LongBool(Value));
      bkAllowedDisallowed: Name := AllowedDisallowedToString(LongBool(Value));
      bkYesNo:             Name := YesNoToString(LongBool(Value));
    else
      Name := TrueFalseToString(LongBool(Value));
    end;
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

function GetEnumReflection(RttiEnum: TRttiEnumerationType; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute>): TOrdinalReflection;
var
  a: TCustomAttribute;
  Naming: NamingStyleAttribute;
  Range: RangeAttribute;
begin
  Naming := nil;
  Range := nil;

  // Find known attributes
  for a in Concat(RttiEnum.GetAttributes, InstanceAttributes)  do
    if a is NamingStyleAttribute then
      Naming := NamingStyleAttribute(a)
    else if a is RangeAttribute then
      Range := RangeAttribute(a);

  with Result do
  begin
    // To emit RTTI, enumerations must start with 0.
    // We use a custom attribute to further restrict the range.

    Value := CaptureOrdinal(RttiEnum, Instance);
    Known := (not Assigned(Range) or Range.Check(Value)) and
      (Value < Cardinal(RttiEnum.MaxValue));

    if Known then
      Name := GetEnumNameEx(RttiEnum, Value, Naming)
    else
      Name := IntToStr(Value) + ' (out of bound)';
  end;
end;

function GetOrdinalReflection(OrdinalType: PTypeInfo; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute>): TOrdinalReflection;
var
  RttContext: TRttiContext;
  RttiType: TRttiOrdinalType;
  a: TCustomAttribute;
  Bytes: Boolean;
  Hex: HexAttribute;
begin
  RttContext := TRttiContext.Create;
  RttiType := RttContext.GetType(OrdinalType) as TRttiOrdinalType;

  // Booleans
  if IsBooleanType(RttiType.Handle) then
    Exit(GetBoolReflection(RttiType, Instance, InstanceAttributes));

  // Enumerations
  if RttiType is TRttiEnumerationType then
    Exit(GetEnumReflection(TRttiEnumerationType(RttiType), Instance,
      InstanceAttributes));

  Hex := nil;
  Bytes := False;

  // Find known attributes
  for a in Concat(RttiType.GetAttributes, InstanceAttributes) do
  begin
    Bytes := Bytes or (a is BytesAttribute);

    if a is HexAttribute then
      Hex := HexAttribute(a);
  end;

  // Capture
  Result.Value := CaptureOrdinal(RttiType, Instance);
  Result.Known := True;

  // Convert
  if Assigned(Hex) then
    Result.Name := IntToHexEx(Result.Value, Hex.Digits)
  else if Bytes then
    Result.Name := BytesToString(Result.Value)
  else
    Result.Name := IntToStr(Result.Value);
end;

procedure PrepareBitwiseFullName(var Reflection: TBitiwseReflection);
var
  Names: TArray<String>;
  i, Count: Integer;
begin
  SetLength(Names, 33);
  Count := 0;

  for i := 0 to 31 do
    if Reflection.Bits[i].Present and Reflection.Bits[i].Known then
    begin
      Names[Count] := Reflection.Bits[i].Name;
      Inc(Count);
    end;

  if Reflection.UnknownBits <> 0 then
  begin
    Names[Count] := IntToHexEx(Reflection.UnknownBits);
    Inc(Count);
  end;

  Reflection.FullName := String.Join(', ', Names, 0, Count);
end;

function GetBitwiseReflection(BitEnumType, ValueType: PTypeInfo;
  Instance: Pointer; InstanceAttributes: TArray<TCustomAttribute>)
  : TBitiwseReflection;
var
  RttContext: TRttiContext;
  RttiEnum: TRttiEnumerationType;
  RttiValue: TRttiOrdinalType;
  a: TCustomAttribute;
  Naming: NamingStyleAttribute;
  ValidMask: Cardinal;
  i: Integer;
begin
  RttContext := TRttiContext.Create;
  RttiEnum := RttContext.GetType(BitEnumType) as TRttiEnumerationType;
  RttiValue := RttContext.GetType(ValueType) as TRttiOrdinalType;

  Naming := nil;
  ValidMask := Cardinal(-1);

  // Find known attributes
  for a in Concat(RttiEnum.GetAttributes, InstanceAttributes) do
    if a is ValidMaskAttribute then
      ValidMask := ValidMaskAttribute(a).ValidMask
    else if a is NamingStyleAttribute then
      Naming := NamingStyleAttribute(a);

  // Get ordinal value
  Result.Value := CaptureOrdinal(RttiValue, Instance);
  Result.UnknownBits := 0;

  // Capture each bit information
  for i := 0 to 31 do
    with Result.Bits[i] do
    begin
      Bit := 1 shl i;
      Present := (Result.Value and Bit <> 0);
      Known := (ValidMask and Bit <> 0) and (i < RttiEnum.MaxValue);

      if Known then
        Name := GetEnumNameEx(RttiEnum, Cardinal(i), Naming)
      else if Present then
      begin
        Name := IntToHexEx(Bit) + ' (unknown)';
        Result.UnknownBits := Result.UnknownBits or Bit;
      end;
    end;

  PrepareBitwiseFullName(Result);
end;

end.
