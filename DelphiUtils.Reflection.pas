unit DelphiUtils.Reflection;

interface

uses
  System.TypInfo;

type
  TNumericKind = (nkBool, nkDec, nkDecSigned, nkBytes, nkHex, nkEnum, nkBitwise);

  TBitReflection = record
    Bit: ShortInt;
    Presents: Boolean;
    Name: String;
  end;

  TNumericReflection = record
    Kind: TNumericKind;
    Value: UInt64;
    Name: String;
    IsKnown: Boolean;                  // for enumerations
    KnownBits: TArray<TBitReflection>; // for bitwise
    UnknownBits: Cardinal;             // for bitwise
  end;

// Introspect a numeric value
function GetNumericReflection(AType: PTypeInfo; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute>): TNumericReflection;

implementation

uses
  System.Rtti, System.SysUtils, DelphiApi.Reflection, DelphiUtils.Strings;

function IsBooleanType(AType: PTypeInfo): Boolean;
begin
  Result := (AType = TypeInfo(Boolean)) or (AType = TypeInfo(WordBool)) or
    (AType = TypeInfo(LongBool));
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
begin
  Naming := nil;
  Range := nil;

  // Find known attributes
  for a in Attributes  do
    if a is NamingStyleAttribute then
      Naming := NamingStyleAttribute(a)
    else if a is RangeAttribute then
      Range := RangeAttribute(a);

  with Reflection do
  begin
    // To emit RTTI, enumerations must start with 0.
    // We use a custom attribute to further restrict the range.

    Kind := nkEnum;
    IsKnown := (not Assigned(Range) or Range.Check(Cardinal(Value))) and
      (Value < NativeUInt(Cardinal(RttiEnum.MaxValue)));

    if IsKnown then
      Name := GetEnumNameEx(RttiEnum, Cardinal(Value), Naming)
    else
      Name := IntToStr(Value) + ' (out of bound)';
  end;
end;

procedure PrepareBitwiseName(var Reflection: TNumericReflection);
var
  Names: TArray<String>;
  i, j: Integer;
begin
  SetLength(Names, Length(Reflection.KnownBits) + 1);
  j := 0;

  for i := 0 to High(Reflection.KnownBits) do
    if Reflection.KnownBits[i].Presents then
    begin
      Names[j] := Reflection.KnownBits[i].Name;
      Inc(j);
    end;

  if Reflection.UnknownBits <> 0 then
  begin
    Names[j] := IntToHexEx(Reflection.UnknownBits);
    Inc(j);
  end;

  Reflection.Name := String.Join(', ', Names, 0, j);
end;

procedure FillBitwiseReflection(var Reflection: TNumericReflection;
  RttiEnum: TRttiEnumerationType);
var
  a: TCustomAttribute;
  Naming: NamingStyleAttribute;
  ValidMask, Mask: UInt64;
  i, j: Integer;
begin
  Naming := nil;
  ValidMask := UInt64(-1);

  // Find known attributes
  for a in RttiEnum.GetAttributes do
    if a is ValidMaskAttribute then
      ValidMask := ValidMaskAttribute(a).ValidMask
    else if a is NamingStyleAttribute then
      Naming := NamingStyleAttribute(a);

  Reflection.Kind := nkBitwise;
  Reflection.UnknownBits := 0;
  SetLength(Reflection.KnownBits, 64);
  j := 0;

  // Capture each bit information
  for i := 0 to 63 do
  begin
    Mask := UInt64(1) shl i;

    if (ValidMask and Mask <> 0) and (i < RttiEnum.MaxValue) then
      with Reflection.KnownBits[j] do
      begin
        // We save all known bits and mark those that present
        // in the speified mask

        Bit := ShortInt(i);
        Name := GetEnumNameEx(RttiEnum, Cardinal(i), Naming);
        Presents := (Reflection.Value and Mask <> 0);
        Inc(j);

        if Presents then
          Continue;
      end;

    // Collect unknown bits
    if Reflection.Value and Mask <> 0 then
      Reflection.UnknownBits := Reflection.UnknownBits or Mask;
  end;

  // Trim the array
  SetLength(Reflection.KnownBits, j);

  // Format the name
  PrepareBitwiseName(Reflection);
end;

procedure FillOrdinalReflection(var Reflection: TNumericReflection;
  Attributes: TArray<TCustomAttribute>);
var
  a: TCustomAttribute;
  Bytes: Boolean;
  Hex: HexAttribute;
  RttiContext: TRttiContext;
  BitwiseType: TRttiEnumerationType;
begin
  RttiContext := TRttiContext.Create;
  Hex := nil;
  Bytes := False;
  BitwiseType := nil;

  // Find known attributes
  for a in Attributes do
  begin
    Bytes := Bytes or (a is BytesAttribute);

    if a is HexAttribute then
      Hex := HexAttribute(a);

    if a is BitwiseAttribute then
      BitwiseType := RttiContext.GetType(BitwiseAttribute(a).EnumType) as
        TRttiEnumerationType;
  end;

  // Convert
  if Assigned(BitwiseType) then
  begin
    Reflection.Kind := nkBitwise;
    FillBitwiseReflection(Reflection, BitwiseType);
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
    Reflection.Name := IntToStr(Int64(Reflection.Value));
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

end.
