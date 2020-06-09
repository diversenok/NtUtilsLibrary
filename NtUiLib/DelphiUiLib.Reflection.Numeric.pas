unit DelphiUiLib.Reflection.Numeric;

interface

uses
  DelphiApi.Reflection, System.Rtti;

type
  TNumericKind = (nkBool, nkDec, nkDecSigned, nkBytes, nkHex, nkEnum, nkBitwise);

  TFlagReflection = record
    Presents: Boolean;
    Flag: TFlagName;
  end;

  TNumericReflection = record
    Kind: TNumericKind;
    Value: UInt64;
    Text: String;
    IsKnown: Boolean;                    // for enumerations
    KnownFlags: TArray<TFlagReflection>; // for bitwise
    SubEnums: TArray<String>;            // for bitwise
    UnknownBits: UInt64;                 // for bitwise
  end;

// Internal use
procedure FillOrdinalReflection(var Reflection: TNumericReflection;
  Attributes: TArray<TCustomAttribute>);

// Represent a numeric value by RTTI type
function GetNumericReflectionRtti(RttiType: TRttiType; const Instance;
  InstanceAttributes: TArray<TCustomAttribute> = nil): TNumericReflection;

// Represent a numeric value by TypeInfo
function GetNumericReflection(AType: Pointer; const Instance;
  InstanceAttributes: TArray<TCustomAttribute> = nil): TNumericReflection;

type
  TNumeric = class abstract
    // Represent a numeric value via a generic metod
    class function Represent<T>(const Instance: T; InstanceAttributes:
      TArray<TCustomAttribute> = nil): TNumericReflection; static;
  end;

implementation

uses
  System.TypInfo, System.SysUtils, DelphiUiLib.Strings;

function IsBooleanType(AType: Pointer): Boolean;
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
      bkEnabledDisabled:   Text := EnabledDisabledToString(Value <> 0);
      bkAllowedDisallowed: Text := AllowedDisallowedToString(Value <> 0);
      bkYesNo:             Text := YesNoToString(Value <> 0);
    else
      Text := TrueFalseToString(Value <> 0);
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
      Text := GetEnumNameEx(RttiEnum, Cardinal(Value), Naming)
    else
      Text := IntToStr(Value) + ' (out of bound)';
  end;
end;

procedure FillBitwiseReflection(var Reflection: TNumericReflection;
  Attributes: TArray<TCustomAttribute>);
var
  a: TCustomAttribute;
  SubEnum: SubEnumAttribute;
  IgnoreUnnamed: Boolean;
  HexDigits: Integer;
  Strings: array of String;
  i, Count: Integer;
begin
  Reflection.Kind := nkBitwise;
  Reflection.UnknownBits := Reflection.Value;
  Reflection.KnownFlags := nil;
  Reflection.SubEnums := nil;
  IgnoreUnnamed := False;
  HexDigits := 0;

  for a in Attributes do
  begin
    // Process bit flag names
    if a is FlagNameAttribute then
    begin
      SetLength(Reflection.KnownFlags, Length(Reflection.KnownFlags) + 1);

      with Reflection.KnownFlags[High(Reflection.KnownFlags)] do
      begin
        Flag := FlagNameAttribute(a).Flag;
        Presents := (Reflection.Value and Flag.Value) = Flag.Value;
        Reflection.UnknownBits := Reflection.UnknownBits and not Flag.Value;
      end;
    end
    else

    // Process sub-enumeration that are embedded into bit masks
    if a is SubEnumAttribute then
    begin
      SubEnum := SubEnumAttribute(a);

      if (Reflection.Value and SubEnum.Mask) = SubEnum.Flag.Value then
      begin
        SetLength(Reflection.SubEnums, Length(Reflection.SubEnums) + 1);
        Reflection.SubEnums[High(Reflection.SubEnums)] := SubEnum.Flag.Name;

        // Exclude the whole sub-enum mask
        Reflection.UnknownBits := Reflection.UnknownBits and not SubEnum.Mask;
      end;
    end
    else if a is IgnoreUnnamedAttribute then
      IgnoreUnnamed := True
    else if a is HexAttribute then
      HexDigits := HexAttribute(a).Digits;
  end;

  Count := 0;
  SetLength(Strings, Length(Reflection.KnownFlags) +
    Length(Reflection.SubEnums) + 1);

  // Collect present flags
  for i := 0 to High(Reflection.KnownFlags) do
    if Reflection.KnownFlags[i].Presents then
    begin
      Strings[Count] := Reflection.KnownFlags[i].Flag.Name;
      Inc(Count);
    end;

  // Collect sub-enumerations
  for i := 0 to High(Reflection.SubEnums) do
  begin
    Strings[Count] := Reflection.SubEnums[i];
    Inc(Count);
  end;

  // Include unknown bits
  if not IgnoreUnnamed and (Reflection.UnknownBits <> 0) then
  begin
    Strings[Count] := IntToHexEx(Reflection.UnknownBits, HexDigits);
    Inc(Count);
  end;

  if Count = 0 then
    Reflection.Text := '(none)'
  else
    Reflection.Text := String.Join(', ', Strings, 0, Count);
end;

procedure FillOrdinalReflection(var Reflection: TNumericReflection;
  Attributes: TArray<TCustomAttribute>);
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
    FillBitwiseReflection(Reflection, Attributes);
  end
  else if Assigned(Hex) then
  begin
    Reflection.Kind := nkHex;
    Reflection.Text := IntToHexEx(Reflection.Value, Hex.Digits);
  end
  else if Bytes then
  begin
    Reflection.Kind := nkBytes;
    Reflection.Text := BytesToString(Reflection.Value);
  end
  else
  begin
    Reflection.Kind := nkDec;
    Reflection.Text := IntToStrEx(Reflection.Value);
  end;
end;

function GetNumericReflectionRtti(RttiType: TRttiType; const Instance;
  InstanceAttributes: TArray<TCustomAttribute> = nil): TNumericReflection;
var
  Attributes: TArray<TCustomAttribute>;
begin
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
    FillOrdinalReflection(Result, Attributes);
end;

function GetNumericReflection(AType: Pointer; const Instance;
  InstanceAttributes: TArray<TCustomAttribute>): TNumericReflection;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(AType);

  Result := GetNumericReflectionRtti(RttiType, Instance, InstanceAttributes);
end;

class function TNumeric.Represent<T>(const Instance: T;
  InstanceAttributes: TArray<TCustomAttribute>): TNumericReflection;
var
  AsByte: Byte absolute Instance;
  AsWord: Word absolute Instance;
  AsCardinal: Cardinal absolute Instance;
  AsUInt64: UInt64 absolute Instance;
begin
  if not Assigned(TypeInfo(T)) then
  begin
    // Handle enumerations with no TypeInfo
    case SizeOf(T) of
      SizeOf(Byte): Result.Value := AsByte;
      SizeOf(Word): Result.Value := AsWord;
      SizeOf(Cardinal): Result.Value := AsCardinal;
      SizeOf(UInt64): Result.Value := AsUInt64;
    else
      Assert(False, 'Not a numeric type');
    end;

    FillOrdinalReflection(Result, InstanceAttributes);
  end
  else
    Result := GetNumericReflection(TypeInfo(T), Instance, InstanceAttributes);
end;

end.
