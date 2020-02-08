unit DelphiApi.Reflection;

interface

type
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

  // Validity mask for enumerations that represent bit masks
  ValidMaskAttribute = class(TCustomAttribute)
    ValidMask: Cardinal;
    constructor Create(Mask: Cardinal);
  end;

  // Marks a field as a bit map that correspond to an enumeration
  BitwiseAttribute = class(TCustomAttribute)
    EnumType: Pointer;
    constructor Create(EnumTypeInfo: Pointer);
  end;

  // Display the underlying data as a hexadecimal value
  HexAttribute = class(TCustomAttribute)
    Digits: Integer;
    constructor Create(MinimalDigits: Integer = 0);
  end;

  // Display the underlying data as a size in bytes
  BytesAttribute = class(TCustomAttribute)
  end;

  // Aggregate a record field as it is a part of the structure
  AggregateAttribute = class(TCustomAttribute)
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

constructor ValidMaskAttribute.Create(Mask: Cardinal);
begin
  ValidMask := Mask;
end;

{ BitwiseAttribute }

constructor BitwiseAttribute.Create(EnumTypeInfo: Pointer);
begin
  EnumType := EnumTypeInfo;
end;

{ HexAttribute }

constructor HexAttribute.Create(MinimalDigits: Integer);
begin
  Digits := MinimalDigits;
end;

end.
