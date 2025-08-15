unit DelphiUtils.LiteRTTI.Extension;

{
  This module provides lightweight RTTI support for commonly used custom
  attributes.
}

interface

uses
  DelphiApi.Reflection, Ntapi.Versions, DelphiUtils.LiteRTTI;

type
  TLiteRttiAttributeExtension = record helper for TLiteRttiAttribute
    // Read a [NamingStyle(...)] attribute
    function IsNamingStyleAttribute: Boolean;
    function ParseNamingStyleAttribute(
      out Style: TNamingStyle;
      out Prefix: String;
      out Suffix: String
    ): Boolean;

    // Read a [MinValue(...)] attribute
    function IsMinValueAttribute: Boolean;
    function ParseMinValueAttribute(
      out MinValue: Cardinal
    ): Boolean;

    // Read a [ValidValues(...)] attribute
    function IsValidValuesAttribute: Boolean;
    function ParseValidValuesAttribute(
      out Values: TValidValues
    ): Boolean;

    // Read a [ValidMask(...)] attribute
    function IsValidMaskAttribute: Boolean;
    function ParseValidMaskAttribute(
      out Mask: UInt64
    ): Boolean;

    // Read a [FlagName(...)] attribute
    function IsFlagNameAttribute: Boolean;
    function ParseFlagNameAttribute(
      out Value: UInt64;
      out Name: String
    ): Boolean;

    // Read a [FlagGroup(...)] attribute
    function IsFlagGroupAttribute: Boolean;
    function ParseFlagGroupAttribute(
      out Mask: UInt64;
      out Name: String
    ): Boolean;

    // Read a [SubEnum(...)] attribute
    function IsSubEnumAttribute: Boolean;
    function ParseSubEnumAttribute(
      out Mask: UInt64;
      out Value: UInt64;
      out Name: String
    ): Boolean;

    // Read a [BooleanKind(...)] attribute
    function IsBooleanKindAttribute: Boolean;
    function ParseBooleanKindAttribute(
      out Kind: TBooleanKind
    ): Boolean;

    // Read a [Hex(...)] attribute
    function IsHexAttribute: Boolean;
    function ParseHexAttribute(
      out MinimalDigits: Byte
    ): Boolean;

    // Read a [AsciiMagic] attribute
    function IsAsciiMagicAttribute: Boolean;

    // Read a [Bytes] attribute
    function IsBytesAttribute: Boolean;

    // Read a [Aggregate] attribute
    function IsAggregateAttribute: Boolean;

    // Read a [Unlisted] attribute
    function IsUnlistedAttribute: Boolean;

    // Read a [DontFollow] attribute
    function IsDontFollowAttribute: Boolean;

    // Read a [RecordSize] attribute
    function IsRecordSizeAttribute: Boolean;

    // Read an [Offset] attribute
    function IsOffsetAttribute: Boolean;

    // Read a [FriendlyName(...)] attribute
    function IsFriendlyNameAttribute: Boolean;
    function ParseFriendlyNameAttribute(
      out FriendlyName: String
    ): Boolean;

    // Read an [InheritsFrom(...)] attribute
    function IsInheritsFromAttribute: Boolean;
    function ParseInheritsFromAttribute(
      out BaseType: PLiteRttiTypeInfo
    ): Boolean;

    // Read an [SDKName(...)] attribute
    function IsSDKNameAttribute: Boolean;
    function ParseSDKNameAttribute(
      out SDKName: String
    ): Boolean;

    // Read a [MinOSVersion(...)] attribute
    function IsMinOSVersionAttribute: Boolean;
    function ParseMinOSVersionAttribute(
      out Version: TWindowsVersion
    ): Boolean;
  end;

  TLiteRttiTypeInfoExtension = record helper for TLiteRttiTypeInfo
    // Collect all attributes from the type, following priority:
    // 1. Explicit annotations
    // 2. Inherited via [InheritsFrom(...)] annotations (recursively)
    // 3. Parent type annotations (classes, interfaces, enums, pointers)
    function AllAttributes: TArray<PLiteRttiAttribute>;
  end;

  TRttixTypeKind = (
    rtkOther,
    rtkEnumeration,
    rtkBoolean,
    rtkBitwise,
    rtkNumeric
  );

  TRttixType = record
    TypeInfo: PLiteRttiTypeInfo;
    Attributes: TArray<PLiteRttiAttribute>;
    Kind: TRttixTypeKind;
    SDKName: String;
    FriendlyName: String;
  end;

  // rtkEnumeration types
  TRttixEnumType = record
    Common: TRttixType;
    ValidValues: TValidValues;
    NamingStyle: TNamingStyle;
    Prefix, Suffix: String;
  end;

  // rtkBoolean types
  TRttixBoolType = record
    Common: TRttixType;
    BooleanKind: TBooleanKind;
  end;

  TRttixBitwiseFlag = record
    Mask: UInt64;
    Value: UInt64;
    Name: String;
  end;

  // rtkBitwise types
  TRttixBitwiseType = record
    Common: TRttixType;
    MinDigits: Byte;
    ValidMask: UInt64;
    Flags: TArray<TRttixBitwiseFlag>;
    FlagGroups: TArray<TRttixBitwiseFlag>;
  end;

  TRttixNumericKind = (
    rokDecimal,
    rokHex,
    rokBytes,
    rokAscii
  );

  // rtkNumeric
  TRttixNumericType = record
    Common: TRttixType;
    Kind: TRttixNumericKind;
    MinHexDigits: Byte;
  end;

// Collect common attribute information for all types
function RttixTypeInfo(
  TypeInfo: PLiteRttiTypeInfo;
  const FieldAttributes: TArray<PLiteRttiAttribute>
): TRttixType;

// Collect attribute information for an enumeration type
function RttixTypeInfoEnum(
  const CommonTypeInfo: TRttixType
): TRttixEnumType;

// Collect attribute information for a boolean type
function RttixTypeInfoBool(
  const CommonTypeInfo: TRttixType
): TRttixBoolType;

// Collect attribute information for a bitwise type
function RttixTypeInfoBitwise(
  const CommonTypeInfo: TRttixType
): TRttixBitwiseType;

// Collect attribute information for a numeric type
function RttixTypeInfoNumeric(
  const CommonTypeInfo: TRttixType
): TRttixNumericType;

implementation

uses
  DelphiApi.TypInfo;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Helpers }

function ReadUTF8String(Cursor: Pointer): String;
var
  RawLength: Word;
  ActualLength: Integer;
begin
  // The first two bytes are the length of the following UTF-8 buffer
  RawLength := Word(Cursor^);

  // A UTF-16 string is at most as long in characters as UTF-8
  SetLength(Result, RawLength);

  // Unpack UTF-8 into UTF-16. Note: the destination max chars includes the zero
  // terminator but the source does not.
  ActualLength := Utf8ToUnicode(PWideChar(Result), RawLength + 1,
    Pointer(PByte(Cursor) + SizeOf(Word)), RawLength);

  if ActualLength > 0 then
    SetLength(Result, ActualLength - 1)
  else
    Result := '';
end;

function UTF8StringTail(Cursor: Pointer): Pointer;
begin
  Result := PByte(Cursor) + Word(Cursor^);
end;

{ TLiteRttiAttributeExtension }

function TLiteRttiAttributeExtension.IsAggregateAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(AggregateAttribute);
end;

function TLiteRttiAttributeExtension.IsAsciiMagicAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(AsciiMagicAttribute);
end;

function TLiteRttiAttributeExtension.IsBooleanKindAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(BooleanKindAttribute);
end;

function TLiteRttiAttributeExtension.IsBytesAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(BytesAttribute);
end;

function TLiteRttiAttributeExtension.IsDontFollowAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(DontFollowAttribute);
end;

function TLiteRttiAttributeExtension.IsFlagGroupAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(FlagGroupAttribute);
end;

function TLiteRttiAttributeExtension.IsFlagNameAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(FlagNameAttribute);
end;

function TLiteRttiAttributeExtension.IsFriendlyNameAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(FriendlyNameAttribute);
end;

function TLiteRttiAttributeExtension.IsHexAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(HexAttribute);
end;

function TLiteRttiAttributeExtension.IsInheritsFromAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(InheritsFromAttribute);
end;

function TLiteRttiAttributeExtension.IsMinOSVersionAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(MinOSVersionAttribute);
end;

function TLiteRttiAttributeExtension.IsMinValueAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(MinValueAttribute);
end;

function TLiteRttiAttributeExtension.IsNamingStyleAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(NamingStyleAttribute);
end;

function TLiteRttiAttributeExtension.IsOffsetAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(OffsetAttribute);
end;

function TLiteRttiAttributeExtension.IsRecordSizeAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(RecordSizeAttribute);
end;

function TLiteRttiAttributeExtension.IsSDKNameAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(SDKNameAttribute);
end;

function TLiteRttiAttributeExtension.IsSubEnumAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(SubEnumAttribute);
end;

function TLiteRttiAttributeExtension.IsUnlistedAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(UnlistedAttribute);
end;

function TLiteRttiAttributeExtension.IsValidMaskAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(ValidMaskAttribute);
end;

function TLiteRttiAttributeExtension.IsValidValuesAttribute;
begin
  Result := Self.AttrubuteType = System.TypeInfo(ValidValuesAttribute);
end;

function TLiteRttiAttributeExtension.ParseBooleanKindAttribute;
begin
  Result := IsBooleanKindAttribute;

  if Result then
    Kind := TBooleanKind(Self.Arguments^);
end;

function TLiteRttiAttributeExtension.ParseFlagGroupAttribute;
var
  Cursor: Pointer;
begin
  Result := IsFlagGroupAttribute;

  if Result then
  begin
    Cursor := Self.Arguments;
    Mask := UInt64(Cursor^);
    Inc(PByte(Cursor), SizeOf(UInt64));
    Name := ReadUTF8String(Cursor)
  end;
end;

function TLiteRttiAttributeExtension.ParseFlagNameAttribute;
var
  Cursor: Pointer;
begin
  Result := IsFlagNameAttribute;

  if Result then
  begin
    Cursor := Self.Arguments;
    Value := UInt64(Cursor^);
    Inc(PByte(Cursor), SizeOf(UInt64));
    Name := ReadUTF8String(Cursor)
  end;
end;

function TLiteRttiAttributeExtension.ParseFriendlyNameAttribute;
begin
  Result := IsFriendlyNameAttribute;

  if Result then
    FriendlyName := ReadUTF8String(Self.Arguments);
end;

function TLiteRttiAttributeExtension.ParseHexAttribute;
begin
  Result := IsHexAttribute;

  if Result then
    MinimalDigits := Byte(Self.Arguments^);
end;

function TLiteRttiAttributeExtension.ParseInheritsFromAttribute;
var
  Cursor: PPPTypeInfo;
begin
  Result := IsInheritsFromAttribute;

  if Result then
  begin
    Cursor := Self.Arguments;

    if Assigned(Cursor) then
      BaseType := TLiteRttiTypeInfo.FromTypeInfoRef(Cursor^)
    else
      BaseType := nil;

    Result := Assigned(BaseType);
  end;
end;

function TLiteRttiAttributeExtension.ParseMinOSVersionAttribute;
begin
  Result := IsMinOSVersionAttribute;

  if Result then
    Version := TWindowsVersion(Self.Arguments^);
end;

function TLiteRttiAttributeExtension.ParseMinValueAttribute;
begin
  Result := IsMinValueAttribute;

  if Result then
    MinValue := Cardinal(Self.Arguments^);
end;

function TLiteRttiAttributeExtension.ParseNamingStyleAttribute;
var
  Cursor: Pointer;
begin
  Result := IsNamingStyleAttribute;

  if Result then
  begin
    Cursor := Self.Arguments;
    Style := TNamingStyle(Cursor^);
    Inc(PByte(Cursor), SizeOf(TNamingStyle));
    Prefix := ReadUTF8String(Cursor);
    Cursor := UTF8StringTail(Cursor);
    Suffix := ReadUTF8String(Cursor);
  end;
end;

function TLiteRttiAttributeExtension.ParseSDKNameAttribute;
begin
  Result := IsSDKNameAttribute;

  if Result then
    SDKName := ReadUTF8String(Self.Arguments);
end;

function TLiteRttiAttributeExtension.ParseSubEnumAttribute;
var
  Cursor: Pointer;
begin
  Result := IsSubEnumAttribute;

  if Result then
  begin
    Cursor := Self.Arguments;
    Mask := UInt64(Cursor^);
    Inc(PByte(Cursor), SizeOf(UInt64));
    Value := UInt64(Cursor^);
    Inc(PByte(Cursor), SizeOf(UInt64));
    Name := ReadUTF8String(Cursor)
  end;
end;

function TLiteRttiAttributeExtension.ParseValidMaskAttribute;
begin
  Result := IsValidMaskAttribute;

  if Result then
    Mask := UInt64(Self.Arguments^);
end;

function TLiteRttiAttributeExtension.ParseValidValuesAttribute;
begin
  Result := IsValidValuesAttribute;

  if Result then
    Values := TValidValues(Self.Arguments^);
end;

{ TLiteRttiTypeInfoExtension }

function TLiteRttiTypeInfoExtension.AllAttributes;
var
  ExplicitAttributes: TArray<PLiteRttiAttribute>;
  InheritedAttributes: TArray<PLiteRttiAttribute>;
  ParentAttributes: TArray<PLiteRttiAttribute>;
  Attribute: PLiteRttiAttribute;
  BaseType: PLiteRttiTypeInfo;
begin
  // Priority 1: explicit
  ExplicitAttributes := Self.Attributes;

  // Priority 2: inherited
  InheritedAttributes := nil;

  for Attribute in ExplicitAttributes do
    if Attribute.ParseInheritsFromAttribute(BaseType) then
      InheritedAttributes := InheritedAttributes + BaseType.AllAttributes;

  // Priority 3: parent
  BaseType := nil;

  case Self.Kind of
    tkEnumeration: BaseType := Self.EnumerationBaseType;
    tkClass:       BaseType := Self.ClassParentType;
    tkInterface:   BaseType := Self.InterfaceParent;
    tkPointer:     BaseType := Self.PointerRefType;
  end;

  if Assigned(BaseType) then
    ParentAttributes := BaseType.AllAttributes
  else
    ParentAttributes := nil;

  // Combine
  Result := ExplicitAttributes + InheritedAttributes + ParentAttributes;
end;

{ Functions }

function RttixTypeInfo;
var
  Attribute: PLiteRttiAttribute;
begin
  if not Assigned(TypeInfo) then
    Error(reInvalidPtr);

  Result.TypeInfo := TypeInfo;
  Result.Attributes := FieldAttributes + TypeInfo.AllAttributes;

  // SDK name
  for Attribute in Result.Attributes do
    if Attribute.ParseSDKNameAttribute(Result.SDKName) then
      Break;

  // Friendly name
  for Attribute in Result.Attributes do
    if Attribute.ParseFriendlyNameAttribute(Result.FriendlyName) then
      Break;

  // Determine custom type kind
  case TypeInfo.Kind of
    tkEnumeration:
      if TypeInfo.EnumerationIsBoolean then
        Result.Kind := rtkBoolean
      else
        Result.Kind := rtkEnumeration;

    tkInteger, tkInt64:
    begin
      Result.Kind := rtkNumeric;

      for Attribute in Result.Attributes do
        if Attribute.IsFlagNameAttribute or Attribute.IsSubEnumAttribute then
        begin
          Result.Kind := rtkBitwise;
          Break;
        end;
    end;
  else
    Result.Kind := rtkOther;
  end;
end;

function RttixTypeInfoEnum;
var
  Attribute: PLiteRttiAttribute;
  MinValueOverride: Cardinal;
  ValidValuesOverride: TValidValues;
begin
  Result := Default(TRttixEnumType);
  Result.Common := CommonTypeInfo;

  if Result.Common.Kind <> rtkEnumeration then
    Error(reAssertionFailed);

  // Assume the entire range as valid by default
  Result.ValidValues := [Result.Common.TypeInfo.OrdinalMinValue ..
    Result.Common.TypeInfo.OrdinalMaxValue];

  // Apply [MinValue(...)] overrides
  for Attribute in Result.Common.Attributes do
    if Attribute.ParseMinValueAttribute(MinValueOverride) then
    begin
      if MinValueOverride > 0 then
        Result.ValidValues := Result.ValidValues - [0 .. MinValueOverride - 1];
      Break;
    end;

  // Apply [ValidValues(...)] overrides
  for Attribute in Result.Common.Attributes do
    if Attribute.ParseValidValuesAttribute(ValidValuesOverride) then
      Result.ValidValues := Result.ValidValues * ValidValuesOverride;

  // Apply [NamingStyle(...)]
  for Attribute in Result.Common.Attributes do
    if Attribute.ParseNamingStyleAttribute(Result.NamingStyle, Result.Prefix,
      Result.Suffix) then
      Break;
end;

function RttixTypeInfoBool;
var
  Attribute: PLiteRttiAttribute;
begin
  Result.Common := CommonTypeInfo;
  Result.BooleanKind := bkTrueFalse;

  if Result.Common.Kind <> rtkBoolean then
    Error(reAssertionFailed);

  for Attribute in Result.Common.Attributes do
    if Attribute.ParseBooleanKindAttribute(Result.BooleanKind) then
      Break;
end;

function RttixTypeInfoBitwise;
var
  Attribute: PLiteRttiAttribute;
  Count, i: Integer;
begin
  Result := Default(TRttixBitwiseType);
  Result.Common := CommonTypeInfo;
  Result.ValidMask := UInt64(-1);

  if Result.Common.Kind <> rtkBitwise then
    Error(reAssertionFailed);

  // Apply [Hex(...)]
  for Attribute in Result.Common.Attributes do
    if Attribute.ParseHexAttribute(Result.MinDigits) then
      Break;

  // Apply [ValidMask(...)]
  for Attribute in Result.Common.Attributes do
    if Attribute.ParseValidMaskAttribute(Result.ValidMask) then
      Break;

  // Apply [FlagName(...)] and [SubEnum(...)]
  Count := 0;
  for Attribute in Result.Common.Attributes do
    if Attribute.IsFlagNameAttribute or Attribute.IsSubEnumAttribute then
      Inc(Count);

  SetLength(Result.Flags, Count);
  i := 0;
  for Attribute in Result.Common.Attributes do
    if Attribute.ParseFlagNameAttribute(Result.Flags[i].Value,
      Result.Flags[i].Name) then
    begin
      Result.Flags[i].Mask := Result.Flags[i].Value;
      Inc(i);
    end
    else if Attribute.ParseSubEnumAttribute(Result.Flags[i].Mask,
      Result.Flags[i].Value, Result.Flags[i].Name) then
      Inc(i);

  // Apply [FlagGroup(...)]
  Count := 0;
  for Attribute in Result.Common.Attributes do
    if Attribute.IsFlagGroupAttribute then
      Inc(Count);

  SetLength(Result.FlagGroups, Count);
  i := 0;
  for Attribute in Result.Common.Attributes do
    if Attribute.ParseFlagGroupAttribute(Result.Flags[i].Mask,
      Result.Flags[i].Name) then
    begin
      Result.Flags[i].Value := Result.Flags[i].Mask;
      Inc(i);
    end;
end;

function RttixTypeInfoNumeric;
var
  Attribute: PLiteRttiAttribute;
begin
  Result := Default(TRttixNumericType);
  Result.Common := CommonTypeInfo;

  if Result.Common.Kind <> rtkNumeric then
    Error(reAssertionFailed);

  // Identify formatting kind
  Result.Kind := rokDecimal;

  for Attribute in Result.Common.Attributes do
  begin
    if Attribute.IsAsciiMagicAttribute then
      Result.Kind := rokAscii
    else if Attribute.IsBytesAttribute then
      Result.Kind := rokBytes
    else if Attribute.ParseHexAttribute(Result.MinHexDigits) then
      Result.Kind := rokHex
    else
      Continue;

    Break;
  end;

end;

end.
