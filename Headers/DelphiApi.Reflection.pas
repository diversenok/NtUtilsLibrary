unit DelphiApi.Reflection;

{
  This module defines custom attributes for annotating types and function
  parameters in the headers and elsewhere within the library.
}

interface

{$MINENUMSIZE 4}

type
  TCustomAttributeClass = class of TCustomAttribute;

  { Enumerations }

  TNamingStyle = (nsPreserveCase, nsCamelCase, nsSnakeCase);

  // Specifies how to prettify an enumeration when converting it to a string
  NamingStyleAttribute = class(TCustomAttribute)
    Style: TNamingStyle;
    Prefix, Suffix: String;
    constructor Create(
      Style: TNamingStyle;
      const Prefix: String = '';
      const Suffix: String = ''
    );
  end;

  // Override the minimal value for enumerations
  MinValueAttribute = class(TCustomAttribute)
    MinValue: Cardinal;
    constructor Create(MinValue: Cardinal);
  end;

  TValidValues = set of Byte;

  // Limits the list of valid enumeration values
  ValidValuesAttribute = class(TCustomAttribute)
    Values: TValidValues;
    constructor Create(const Values: TValidValues);
  end;

  { Bitwise types }

  // Specifies the validity mask for bitwise types
  ValidMaskAttribute = class(TCustomAttribute)
    Mask: UInt64;
    constructor Create(const Mask: UInt64);
  end;

  // Tags specific bits in a bit mask with a textual representation
  FlagNameAttribute = class (TCustomAttribute)
    Name: String;
    Value: UInt64;
    constructor Create(
      const Value: UInt64;
      const Name: String
    );
  end;

  // Tags a set of bits to be grouped
  FlagGroupAttribute = class (TCustomAttribute)
    Name: String;
    Mask: UInt64;
    constructor Create(
      const Mask: UInt64;
      const Name: String
    );
  end;

  // Specifies a textual representation of an enumeration entry that is embedded
  // into a bit mask.
  SubEnumAttribute = class (TCustomAttribute)
    Name: String;
    Value: UInt64;
    Mask: UInt64;
    constructor Create(
      const Mask: UInt64;
      const Value: UInt64;
      const Name: String
    );
  end;

  { Booleans }

  TBooleanKind = (bkTrueFalse, bkEnabledDisabled, bkAllowedDisallowed, bkYesNo);

  // Specifies how to represent a boolean value as a string
  BooleanKindAttribute = class(TCustomAttribute)
    Kind: TBooleanKind;
    constructor Create(Kind: TBooleanKind);
  end;

  { Numeric values }

  // Display the underlying data as a hexadecimal value
  HexAttribute = class(TCustomAttribute)
    MinimalDigits: Integer;
    constructor Create(MinimalDigits: Integer = 0);
  end;

  // Display the underlying magic value as an ASCII string
  AsciiMagicAttribute = class(TCustomAttribute)
  end;

  // Display the underlying data as a size in bytes
  BytesAttribute = class(TCustomAttribute)
  end;

  { Records }

  // Aggregate a record field as it is a part of the structure
  AggregateAttribute = class(TCustomAttribute)
  end;

  // The parameter or the field is reserved and should have for a specific value
  ReservedAttribute = class(TCustomAttribute)
    constructor Create(const ExpectedValue: UInt64 = 0);
  end;

  // Skip this field when performing record traversing
  UnlistedAttribute = class(TCustomAttribute)
  end;

  // Stop recursive traversing
  DontFollowAttribute = class(TCustomAttribute)
  end;

  // The field indicates the size of the entire structure
  RecordSizeAttribute = class(TCustomAttribute)
  end;

  // The field indicates an offset value in bytes
  OffsetAttribute = class(TCustomAttribute)
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

  // The parameter indicates the number of bytes to read/write
  NumberOfBytesAttribute = class(TCustomAttribute)
  end;

  // The parameter indicates the elements of bytes to read/write
  NumberOfElementsAttribute = class(TCustomAttribute)
  end;

  // The parameter specifies an input buffer of a variable length as indicated
  // by another parameter
  ReadsFromAttribute = class(TCustomAttribute)
  end;

  // The parameter specifies an output buffer of a variable length as indicated
  // by another parameter
  WritesToAttribute = class(TCustomAttribute)
  end;

  // The function acquires or allocates a resource that requires a cleanup using
  // a dedicated routine
  ReleaseWithAttribute = class(TCustomAttribute)
    constructor Create(ReleaseRoutine: AnsiString);
  end;

  // The output pointer may be nil
  MayReturnNilAttribute = class(TCustomAttribute)
  end;

  // The function stores the error value in the TEB
  SetsLastErrorAttribute = class(TCustomAttribute)
  end;

  // The parameter requires a specific access to the resource
  AccessAttribute = class(TCustomAttribute)
    AccessMask: Cardinal;
    constructor Create(AccessMask: Cardinal);
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
  FriendlyNameAttribute = class (TCustomAttribute)
    FriendlyName: String;
    constructor Create(const FriendlyName: String);
  end;

  // An official or at leact commonly used name for the type
  SDKNameAttribute = class (TCustomAttribute)
    Name: String;
    constructor Create(const Name: String);
  end;

  // Allows a type to inherit some attributes of another type
  InheritsFromAttribute = class (TCustomAttribute)
    TypeInfo: Pointer;
    constructor Create(ATypeInfo: Pointer);
  end;

  // Annotates known thread safety state for a type or a function
  ThreadSafeAttribute = class (TCustomAttribute)
    IsThreadSafe: Boolean;
    constructor Create(IsThreadSafe: Boolean = True);
  end;

// Make sure a class is accessible through reflection
procedure CompileTimeInclude(MetaClass: TClass);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ NamingStyleAttribute }

constructor NamingStyleAttribute.Create;
begin
  Self.Style := Style;
  Self.Prefix := Prefix;
  Self.Suffix := Suffix;
end;

{ MinValueAttribute }

constructor MinValueAttribute.Create;
begin
  Self.MinValue := MinValue;
end;

{ ValidValuesAttribute }

constructor ValidValuesAttribute.Create;
begin
  Self.Values := Values;
end;

{ ValidMaskAttribute }

constructor ValidMaskAttribute.Create;
begin
  Self.Mask := Mask;
end;

{ FlagNameAttribute }

constructor FlagNameAttribute.Create;
begin
  Self.Value := Value;
  Self.Name := Name;
end;

{ FlagGroupAttribute }

constructor FlagGroupAttribute.Create;
begin
  Self.Mask := Mask;
  Self.Name := Name;
end;

{ SubEnumAttribute }

constructor SubEnumAttribute.Create;
begin
  Self.Mask := Mask;
  Self.Value := Value;
  Self.Name := Name;
end;

{ BooleanKindAttribute }

constructor BooleanKindAttribute.Create;
begin
  Self.Kind := Self.Kind;
end;

{ HexAttribute }

constructor HexAttribute.Create;
begin
  Self.MinimalDigits := MinimalDigits;
end;

{ ReservedAttribute }

constructor ReservedAttribute.Create;
begin

end;

{ ReleaseWithAttribute }

constructor ReleaseWithAttribute.Create;
begin

end;

{ AccessAttribute }

constructor AccessAttribute.Create;
begin
  Self.AccessMask := AccessMask;
end;

{ CounterAttribute }

constructor CounterAttribute.Create;
begin
  CounterType := Kind;
end;

{ FriendlyNameAttribute }

constructor FriendlyNameAttribute.Create;
begin
  Self.FriendlyName := FriendlyName;
end;

{ SDKNameAttribute }

constructor SDKNameAttribute.Create;
begin
  Self.Name := Name;
end;

{ InheritsFromAttribute }

constructor InheritsFromAttribute.Create;
var
  TypeInfoPtr: PPointer absolute ATypeInfo;
begin
  // For some reason, Delphi gives us an indirect pointer that we need to
  // dereference.

  if Assigned(TypeInfoPtr) then
    Self.TypeInfo := TypeInfoPtr^;
end;

{ ThreadSafeAttribute }

constructor ThreadSafeAttribute.Create;
begin
  Self.IsThreadSafe := IsThreadSafe;
end;

{ Functions }

procedure CompileTimeInclude;
begin
  // Nothing to do here, we just needed a reference to make sure the linker
  // won't remove this class entirely at compile time.
end;

end.
