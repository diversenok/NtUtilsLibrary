unit DelphiApi.Reflection;

interface

type
  { Enumerations }

  TNamingStyle = (nsCamelCase, nsSnakeCase);

  // Specifies how to prettify an enumeration when converting it to a string
  NamingStyleAttribute = class(TCustomAttribute)
    NamingStyle: TNamingStyle;
    Prefix, Suffix: String;
    constructor Create(
      Style: TNamingStyle;
      PrefixString: String = '';
      SuffixString: String = ''
    );
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
    function Check(Value: Cardinal): Boolean;
    constructor Create(const Mask: UInt64);
  end;

  { Bitwise types }

  TFlagName = record
    Value: UInt64;
    Name: String;
  end;

  TFlagNames = array of TFlagName;

  // Tags specific bits in a bit mask with a textual representation
  FlagNameAttribute = class (TCustomAttribute)
    Flag: TFlagName;
    constructor Create(const Value: UInt64; Name: String);
  end;

  // Specifies a textual representation of an enumeration entry that is embedded
  // into a bit mask.
  SubEnumAttribute = class (TCustomAttribute)
    Mask: UInt64;
    Flag: TFlagName;
    constructor Create(const BitMask, Value: UInt64; Name: String);
  end;

  // Do not include embedded enumerations into the reflection. Useful for
  // splitting the bit mask into state and flags.
  IgnoreSubEnumsAttribute = class (TCustomAttribute)
  end;

  // Do not include unnamed bits into the representation
  IgnoreUnnamedAttribute = class (TCustomAttribute)
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

  // The parameter or the field is reserved for future use
  ReservedAttribute = class(TCustomAttribute)
    constructor Create(const ExpectedValue: UInt64 = 0);
  end;

  // Skip this entry when performing enumeration
  UnlistedAttribute = ReservedAttribute;

  // Stop recursive traversing
  DontFollowAttribute = class(TCustomAttribute)
  end;

  { Parameters }

  // The parameter is used for reading input
  InAttribute = class(TCustomAttribute)
  end;

  // The parameter is used for writing output
  OutAttribute = class(TCustomAttribute)
  end;

  // The parameter is optional
  OptAttribute = class(TCustomAttribute)
  end;

  // The parameter recieves an address allocated by the library and requires
  // freeing with a corresponding function
  AllocatesAttribute = class(TCustomAttribute)
  end;

  { Arrays }

  TAnysizeCounterType = (ctElements, ctBytes);

  // Marks a provider of the number of elements in a TAnysizeArray.
  CounterAttribute = class (TCustomAttribute)
    CounterType: TAnysizeCounterType;
    constructor Create(Kind: TAnysizeCounterType = ctElements);
  end;

  { Other }

  // Assign a field/type a user-friendly name
  FriendlyNameAttribute = class(TCustomAttribute)
    Name: String;
    constructor Create(FriendlyName: String);
  end;

// Make sure a class is accessible through reflection
procedure CompileTimeInclude(MetaClass: TClass);

implementation

{ NamingStyleAttribute }

constructor NamingStyleAttribute.Create;
begin
  NamingStyle := Style;
  Prefix := PrefixString;
  Suffix := SuffixString;
end;

{ RangeAttribute }

function RangeAttribute.Check;
begin
  Result := (Value >= MinValue) and (Value <= MaxValue);
end;

constructor RangeAttribute.Create;
begin
  MinValue := Min;
  MaxValue := Max;
end;

{ ValidMaskAttribute }

function ValidMaskAttribute.Check;
begin
  Result := (1 shl Value) and ValidMask <> 0;
end;

constructor ValidMaskAttribute.Create;
begin
  ValidMask := Mask;
end;

{ FlagNameAttribute }

constructor FlagNameAttribute.Create;
begin
  Flag.Value := Value;
  Flag.Name := Name;
end;

{ SubEnumAttribute }

constructor SubEnumAttribute.Create;
begin
  Mask := BitMask;
  Flag.Value := Value;
  Flag.Name := Name;
end;

{ BooleanKindAttribute }

constructor BooleanKindAttribute.Create;
begin
  Kind := BooleanKind;
end;

{ HexAttribute }

constructor HexAttribute.Create;
begin
  Digits := MinimalDigits;
end;

{ ReservedAttribute }

constructor ReservedAttribute.Create;
begin

end;

{ CounterAttribute }

constructor CounterAttribute.Create;
begin
  CounterType := Kind;
end;

{ FriendlyNameAttribute }

constructor FriendlyNameAttribute.Create;
begin
  Name := FriendlyName;
end;

{ Functions }

procedure CompileTimeInclude;
begin
  // Nothing to do here, we just needed a reference to make sure the linker
  // won't remove this class entirely at compile time.
end;

end.
