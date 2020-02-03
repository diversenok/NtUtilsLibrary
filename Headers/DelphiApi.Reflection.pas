unit DelphiApi.Reflection;

interface

type
  TNamingStyle = (nsCamelCase, nsSnakeCase);

  // Naming scheme details help to improve conversion of enumerations to strings
  NamingStyleAttribute = class(TCustomAttribute)
    NamingStyle: TNamingStyle;
    Prefix, Suffix: String;
    constructor Create(Style: TNamingStyle; PrefixString: String = '';
      SuffixString: String = '');
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

end.
