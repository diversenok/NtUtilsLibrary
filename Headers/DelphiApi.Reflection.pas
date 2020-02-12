unit DelphiApi.Reflection;

interface

type
  { Enumerations }

  TNamingStyle = (nsCamelCase, nsSnakeCase);

  // Specifies how to prettify an enumeration when converting it to a string
  NamingStyleAttribute = class(TCustomAttribute)
    NamingStyle: TNamingStyle;
    Prefix, Suffix: String;
    constructor Create(Style: TNamingStyle; PrefixString: String = '';
      SuffixString: String = '');
  end;

  // Override minimal/maximum values for enumerations
  RangeAttribute = class(TCustomAttribute)
    MinValue, MaxValue: Cardinal;
    function Check(Value: Cardinal): Boolean;
    constructor Create(Min: Cardinal; Max: Cardinal = Cardinal(-1));
  end;

  // Validity mask for enumerations
  ValidMaskAttribute = class(TCustomAttribute)
    ValidMask: UInt64;
    constructor Create(Mask: UInt64);
  end;

  { Bitwise types }

  TFlagName = record
    Value: UInt64;
    Name: String;
  end;

  TFlagNames = array of TFlagName;

  TCustomFlagProvider = class
  protected
    class function Capture(AFlags: array of TFlagName): TFlagNames;
  public
    class function Flags: TFlagNames; virtual; abstract;
  end;

  TFlagProvider = class of TCustomFlagProvider;

  // Marks a field as a bit map
  BitwiseAttribute = class(TCustomAttribute)
    Provider: TFlagProvider;
    constructor Create(FlagProvider: TFlagProvider);
  end;

  { Booleans }

  TBooleanKind = (bkTrueFalse, bkEnabledDisabled, bkAllowedDisallowed, bkYesNo);

  // Specifies how to represent a boolean value as a string
  BooleanKindAttribute = class(TCustomAttribute)
    Kind: TBooleanKind;
    constructor Create(BooleanKind: TBooleanKind);
  end;

  { Numeric values }

  // Display the underlying data as a hexadecimal value
  HexAttribute = class(TCustomAttribute)
    Digits: Integer;
    constructor Create(MinimalDigits: Integer = 0);
  end;

  // Display the underlying data as a size in bytes
  BytesAttribute = class(TCustomAttribute)
  end;

  { Records }

  // Aggregate a record field as it is a part of the structure
  AggregateAttribute = class(TCustomAttribute)
  end;

  // Skip this entry when performing enumeration
  UnlistedAttribute = class(TCustomAttribute)
  end;

  // Stop recursive traversing
  DontFollowAttribute = class(TCustomAttribute)
  end;

implementation

{ NamingStyleAttribute }

constructor NamingStyleAttribute.Create(Style: TNamingStyle; PrefixString,
  SuffixString: String);
begin
  NamingStyle := Style;
  Prefix := PrefixString;
  Suffix := SuffixString;
end;

{ RangeAttribute }

function RangeAttribute.Check(Value: Cardinal): Boolean;
begin
  Result := (Value >= MinValue) and (Value <= MaxValue);
end;

constructor RangeAttribute.Create(Min, Max: Cardinal);
begin
  MinValue := Min;
  MaxValue := Max;
end;

{ ValidMaskAttribute }

constructor ValidMaskAttribute.Create(Mask: UInt64);
begin
  ValidMask := Mask;
end;

{ TCustomFlagProvider }

class function TCustomFlagProvider.Capture(
  AFlags: array of TFlagName): TFlagNames;
var
  i: Integer;
begin
  SetLength(Result, Length(AFlags));
  for i := 0 to High(AFlags) do
    Result[i] := AFlags[i];
end;

{ BitwiseAttribute }

constructor BitwiseAttribute.Create(FlagProvider: TFlagProvider);
begin
  Provider := FlagProvider;
end;

{ BooleanKindAttribute }

constructor BooleanKindAttribute.Create(BooleanKind: TBooleanKind);
begin
  Kind := BooleanKind;
end;

{ HexAttribute }

constructor HexAttribute.Create(MinimalDigits: Integer);
begin
  Digits := MinimalDigits;
end;

end.
