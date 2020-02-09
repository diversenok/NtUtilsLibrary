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
    ValidMask: UInt64;
    constructor Create(Mask: UInt64);
  end;

  // Marks a field as a bit map that correspond to an enumeration
  BitwiseAttribute = class(TCustomAttribute)
    EnumType: Pointer;
    constructor Create(EnumTypeInfo: Pointer);
  end;

  TBooleanKind = (bkTrueFalse, bkEnabledDisabled, bkAllowedDisallowed, bkYesNo);

  // Specifies how to represent a boolean value as a string
  BooleanKindAttribute = class(TCustomAttribute)
    Kind: TBooleanKind;
    constructor Create(BooleanKind: TBooleanKind);
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

{ BitwiseAttribute }

constructor BitwiseAttribute.Create(EnumTypeInfo: Pointer);
begin
  { TODO -cInvestigate: For some reason I get a wrong pointer here, which is a
    pointer to a PTypeInfo, not the PTypeInfo itself. WTF?
    Althougt, it seems that the actual PTypeInfo is located just after it,
    I guess, it's better to derefence it anyway. I see that the compiler
    inlines all TypeInfo() calls as dereferences of an address right before the
    actual PTypeInfo location. We are going to do the same. }

  EnumType := PPointer(EnumTypeInfo)^;

  // Another hacky way that also works:
  // EnumType := PByte(EnumTypeInfo) + SizeOf(Pointer);
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
