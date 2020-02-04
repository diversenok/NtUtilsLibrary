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

  // Override minimal value for enumerations
  MinValueAttribute = class(TCustomAttribute)
    MinValue: Integer;
    constructor Create(Value: Integer);
  end;

  // Display the underlying data as a hexadecimal value
  HexAttribute = class(TCustomAttribute)
    Digits: Integer;
    constructor Create(MinimalDigits: Integer = 0);
  end;

  // Display the underlying data as a size in bytes
  BytesAttribute = class(TCustomAttribute)
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

{ MinValueAttribute }

constructor MinValueAttribute.Create(Value: Integer);
begin
  MinValue := Value;
end;

{ HexAttribute }

constructor HexAttribute.Create(MinimalDigits: Integer);
begin
  Digits := MinimalDigits;
end;

end.
