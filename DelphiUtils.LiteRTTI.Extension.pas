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

{ Known attribute parsing }

  TRttixTypeSubKind = (
    rtkOther,
    rtkEnumeration,
    rtkBoolean,
    rtkBitwise,
    rtkNumeric
  );

  // Base information for all type
  IRttixType = interface
    ['{A4D47FBD-7219-4009-9A50-D2315AED2B12}']
    function GetTypeInfo: PLiteRttiTypeInfo;
    function GetAttributes: TArray<PLiteRttiAttribute>;
    function GetSubKind: TRttixTypeSubKind;
    function GetSDKName: String;
    function GetFriendlyName: String;

    property TypeInfo: PLiteRttiTypeInfo read GetTypeInfo;
    property Attributes: TArray<PLiteRttiAttribute> read GetAttributes;
    property SubKind: TRttixTypeSubKind read GetSubKind;
    property SDKName: String read GetSDKName;
    property FriendlyName: String read GetFriendlyName;
  end;

  // Extra information for rtkEnumeration types
  IRttixEnumType = interface (IRttixType)
    ['{8D20A899-4CC6-4998-80CA-6378478A8659}']
    function GetSize: NativeUInt;
    function GetValidValues: TValidValues;
    function GetNamingStyle: TNamingStyle;
    function GetPrefix: String;
    function GetSuffix: String;

    property Size: NativeUInt read GetSize;
    property ValidValues: TValidValues read GetValidValues;
    property NamingStyle: TNamingStyle read GetNamingStyle;
    property Prefix: String read GetPrefix;
    property Suffix: String read GetSuffix;
  end;

  // Extra information for rtkBoolean types
  IRttixBoolType = interface (IRttixType)
    ['{4437C3BC-D1CF-4BAC-9619-2E68BA3BD5FE}']
    function GetSize: NativeUInt;
    function GetBooleanKind: TBooleanKind;

    property Size: NativeUInt read GetSize;
    property BooleanKind: TBooleanKind read GetBooleanKind;
  end;

  TRttixBitwiseFlag = record
    Mask: UInt64;
    Value: UInt64;
    Name: String;
  end;

  // Extra information for rtkBitwise types
  IRttixBitwiseType = interface (IRttixType)
    ['{3FB64124-3035-496B-8ED7-D5D34D1F5BD5}']
    function GetSize: NativeUInt;
    function GetMinDigits: Byte;
    function GetValidMask: UInt64;
    function GetFlags: TArray<TRttixBitwiseFlag>;
    function GetFlagGroups: TArray<TRttixBitwiseFlag>;

    property Size: NativeUInt read GetSize;
    property MinDigits: Byte read GetMinDigits;
    property ValidMask: UInt64 read GetValidMask;
    property Flags: TArray<TRttixBitwiseFlag> read GetFlags;
    property FlagGroups: TArray<TRttixBitwiseFlag> read GetFlagGroups;
  end;

  TRttixNumericKind = (
    rokDecimal,
    rokHex,
    rokBytes,
    rokAscii
  );

  // Extra information for rtkNumeric types
  IRttixNumericType = interface (IRttixType)
    ['{591A0998-9ACF-47B5-9B36-7BD907409805}']
    function GetSize: NativeUInt;
    function GetSigned: Boolean;
    function GetNumericKind: TRttixNumericKind;
    function GetMinHexDigits: Byte;

    property Size: NativeUInt read GetSize;
    property Signed: Boolean read GetSigned;
    property NumericKind: TRttixNumericKind read GetNumericKind;
    property MinHexDigits: Byte read GetMinHexDigits;
  end;

// Collect known attribute information for a type
function RttixTypeInfo(
  TypeInfo: PLiteRttiTypeInfo;
  const FieldAttributes: TArray<PLiteRttiAttribute> = nil
): IRttixType;

implementation

uses
  DelphiApi.TypInfo, DelphiUtils.AutoObjects;

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

  if Assigned(BaseType) and (BaseType <> @Self) then
    ParentAttributes := BaseType.AllAttributes
  else
    ParentAttributes := nil;

  // Combine
  Result := ExplicitAttributes + InheritedAttributes + ParentAttributes;
end;

{ Interfaces }

type
  TRttixType = class (TAutoInterfacedObject, IRttixType)
    FTypeInfo: PLiteRttiTypeInfo;
    FAttributes: TArray<PLiteRttiAttribute>;
    FSubKind: TRttixTypeSubKind;
    FSDKName: String;
    FFriendlyName: String;
    function GetTypeInfo: PLiteRttiTypeInfo;
    function GetAttributes: TArray<PLiteRttiAttribute>;
    function GetSubKind: TRttixTypeSubKind;
    function GetSDKName: String;
    function GetFriendlyName: String;
    constructor Create(
      TypeInfo: PLiteRttiTypeInfo;
      SubKind: TRttixTypeSubKind;
      const Attributes: TArray<PLiteRttiAttribute>
    );
  end;

  TRttixEnumType = class (TRttixType, IRttixEnumType)
    FSize: NativeUint;
    FValidValues: TValidValues;
    FNamingStyle: TNamingStyle;
    FPrefix: String;
    FSuffix: String;
    function GetSize: NativeUInt;
    function GetValidValues: TValidValues;
    function GetNamingStyle: TNamingStyle;
    function GetPrefix: String;
    function GetSuffix: String;
    constructor Create(
      TypeInfo: PLiteRttiTypeInfo;
      const Attributes: TArray<PLiteRttiAttribute>
    );
  end;

  TRttixBoolType = class (TRttixType, IRttixBoolType)
    FSize: NativeUint;
    FBooleanKind: TBooleanKind;
    function GetSize: NativeUInt;
    function GetBooleanKind: TBooleanKind;
    constructor Create(
      TypeInfo: PLiteRttiTypeInfo;
      const Attributes: TArray<PLiteRttiAttribute>
    );
  end;

  TRttixBitwiseType = class (TRttixType, IRttixBitwiseType)
    FSize: NativeUint;
    FMinDigits: Byte;
    FValidMask: UInt64;
    FFlags: TArray<TRttixBitwiseFlag>;
    FFlagGroups: TArray<TRttixBitwiseFlag>;
    function GetSize: NativeUInt;
    function GetMinDigits: Byte;
    function GetValidMask: UInt64;
    function GetFlags: TArray<TRttixBitwiseFlag>;
    function GetFlagGroups: TArray<TRttixBitwiseFlag>;
    constructor Create(
      TypeInfo: PLiteRttiTypeInfo;
      const Attributes: TArray<PLiteRttiAttribute>
    );
  end;

  TRttixNumericType = class (TRttixType, IRttixNumericType)
    FSize: NativeUint;
    FSigned: Boolean;
    FNumericKind: TRttixNumericKind;
    FMinHexDigits: Byte;
    function GetSize: NativeUInt;
    function GetSigned: Boolean;
    function GetNumericKind: TRttixNumericKind;
    function GetMinHexDigits: Byte;
    constructor Create(
      TypeInfo: PLiteRttiTypeInfo;
      const Attributes: TArray<PLiteRttiAttribute>
    );
  end;

constructor TRttixType.Create;
var
  Attribute: PLiteRttiAttribute;
begin
  inherited Create;

  FTypeInfo := TypeInfo;
  FAttributes := Attributes;
  FSubKind := SubKind;

  // Apply [SDKNameAttribute(...)]
  for Attribute in Attributes do
    if Attribute.ParseSDKNameAttribute(FSDKName) then
      Break;

  // Apply [FriendlyName(...)]
  for Attribute in Attributes do
    if Attribute.ParseFriendlyNameAttribute(FFriendlyName) then
      Break;
end;

function TRttixType.GetAttributes;
begin
  Result := FAttributes;
end;

function TRttixType.GetFriendlyName;
begin
  Result := FFriendlyName;
end;

function TRttixType.GetSDKName;
begin
  Result := FSDKName;
end;

function TRttixType.GetSubKind;
begin
  Result := FSubKind;
end;

function TRttixType.GetTypeInfo;
begin
  Result := FTypeInfo;
end;

constructor TRttixEnumType.Create;
var
  Attribute: PLiteRttiAttribute;
  MinValueOverride: Cardinal;
  ValidValuesOverride: TValidValues;
begin
  inherited Create(TypeInfo, rtkEnumeration, Attributes);

  if not TypeInfo.IsOrdinal then
    Error(reAssertionFailed);

  // Determine the size
  case TypeInfo.OrdinalType of
    otSByte, otUByte: FSize := SizeOf(Byte);
    otSWord, otUWord: FSize := SizeOf(Word);
    otSLong, otULong: FSize := SizeOf(Cardinal);
  else
    Error(reAssertionFailed);
  end;

  // Assume the entire range as valid by default
  FValidValues := [TypeInfo.OrdinalMinValue .. TypeInfo.OrdinalMaxValue];

  // Apply [MinValue(...)] overrides
  for Attribute in Attributes do
    if Attribute.ParseMinValueAttribute(MinValueOverride) then
    begin
      if MinValueOverride > 0 then
        FValidValues := FValidValues - [0 .. MinValueOverride - 1];
      Break;
    end;

  // Apply [ValidValues(...)] overrides
  for Attribute in Attributes do
    if Attribute.ParseValidValuesAttribute(ValidValuesOverride) then
      FValidValues := FValidValues * ValidValuesOverride;

  // Apply [NamingStyle(...)]
  for Attribute in Attributes do
    if Attribute.ParseNamingStyleAttribute(FNamingStyle, FPrefix, FSuffix) then
      Break;
end;

function TRttixEnumType.GetNamingStyle;
begin
  Result := FNamingStyle;
end;

function TRttixEnumType.GetPrefix;
begin
  Result := FPrefix;
end;

function TRttixEnumType.GetSize;
begin
  Result := FSize;
end;

function TRttixEnumType.GetSuffix;
begin
  Result := FSuffix;
end;

function TRttixEnumType.GetValidValues;
begin
  Result := FValidValues;
end;

constructor TRttixBoolType.Create;
var
  Attribute: PLiteRttiAttribute;
begin
  inherited Create(TypeInfo, rtkBoolean, Attributes);

  if not TypeInfo.IsOrdinal then
    Error(reAssertionFailed);

  // Determine the size
  case TypeInfo.OrdinalType of
    otSByte, otUByte: FSize := SizeOf(Byte);
    otSWord, otUWord: FSize := SizeOf(Word);
    otSLong, otULong: FSize := SizeOf(Cardinal);
  else
    Error(reAssertionFailed);
  end;

  // Apply [BooleanKind(...)]
  for Attribute in Attributes do
    if Attribute.ParseBooleanKindAttribute(FBooleanKind) then
      Break;
end;

function TRttixBoolType.GetBooleanKind;
begin
  Result := FBooleanKind;
end;

function TRttixBoolType.GetSize;
begin
  Result := FSize;
end;

constructor TRttixBitwiseType.Create;
var
  Attribute: PLiteRttiAttribute;
  Count, i: Integer;
  Value, Mask: UInt64;
  Name: String;
begin
  inherited Create(TypeInfo, rtkBitwise, Attributes);

  // Determine the size
  if TypeInfo.IsOrdinal then
    case TypeInfo.OrdinalType of
      otSByte, otUByte: FSize := SizeOf(Byte);
      otSWord, otUWord: FSize := SizeOf(Word);
      otSLong, otULong: FSize := SizeOf(Cardinal);
    else
      Error(reAssertionFailed);
    end
  else if TypeInfo.Kind = tkInt64 then
    FSize := SizeOf(Int64)
  else
    Error(reAssertionFailed);

  // Apply [Hex(...)]
  for Attribute in Attributes do
    if Attribute.ParseHexAttribute(FMinDigits) then
      Break;

  // Apply [ValidMask(...)]
  FValidMask := UInt64(-1);
  for Attribute in FAttributes do
    if Attribute.ParseValidMaskAttribute(FValidMask) then
      Break;

  // Apply [FlagName(...)] and [SubEnum(...)]
  Count := 0;
  for Attribute in FAttributes do
    if Attribute.IsFlagNameAttribute or Attribute.IsSubEnumAttribute then
      Inc(Count);

  SetLength(FFlags, Count);

  i := 0;
  for Attribute in Attributes do
    if Attribute.ParseFlagNameAttribute(Value, Name) then
    begin
      FFlags[i].Value := Value;
      FFlags[i].Mask := Value;
      FFlags[i].Name := Name;
      Inc(i);
    end
    else if Attribute.ParseSubEnumAttribute(FFlags[i].Mask, FFlags[i].Value,
      FFlags[i].Name) then
      Inc(i);

  // Apply [FlagGroup(...)]
  Count := 0;
  for Attribute in Attributes do
    if Attribute.IsFlagGroupAttribute then
      Inc(Count);

  SetLength(FFlagGroups, Count);
  i := 0;
  for Attribute in Attributes do
    if Attribute.ParseFlagGroupAttribute(Mask, Name) then
    begin
      FFlagGroups[i].Value := Mask;
      FFlagGroups[i].Mask := Mask;
      FFlagGroups[i].Name := Name;
      Inc(i);
    end;
end;

function TRttixBitwiseType.GetFlagGroups;
begin
  Result := FFlagGroups;
end;

function TRttixBitwiseType.GetFlags;
begin
  Result := FFlags;
end;

function TRttixBitwiseType.GetMinDigits;
begin
  Result := FMinDigits;
end;

function TRttixBitwiseType.GetSize;
begin
  Result := FSize;
end;

function TRttixBitwiseType.GetValidMask;
begin
  Result := FValidMask;
end;

constructor TRttixNumericType.Create;
var
  Attribute: PLiteRttiAttribute;
begin
  inherited Create(TypeInfo, rtkNumeric, Attributes);

  // Determine the size
  if TypeInfo.IsOrdinal then
    case TypeInfo.OrdinalType of
      otSByte, otUByte: FSize := SizeOf(Byte);
      otSWord, otUWord: FSize := SizeOf(Word);
      otSLong, otULong: FSize := SizeOf(Cardinal);
    else
      Error(reAssertionFailed);
    end
  else if TypeInfo.Kind = tkInt64 then
    FSize := SizeOf(Int64)
  else
    Error(reAssertionFailed);

  // Determine the sign
  if TypeInfo.IsOrdinal then
    case TypeInfo.OrdinalType of
      otSByte, otSWord, otSLong: FSigned := True;
      otUByte, otUWord, otULong: FSigned := False;
    else
      Error(reAssertionFailed);
    end
  else if TypeInfo.Kind = tkInt64 then
    FSigned := Int64(TypeInfo.Int64MinValue) < 0
  else
    Error(reAssertionFailed);

  // Identify formatting kind
  FNumericKind := rokDecimal;

  for Attribute in Attributes do
  begin
    if Attribute.IsAsciiMagicAttribute then
      FNumericKind := rokAscii
    else if Attribute.IsBytesAttribute then
      FNumericKind := rokBytes
    else if Attribute.ParseHexAttribute(FMinHexDigits) then
      FNumericKind := rokHex
    else
      Continue;

    Break;
  end;
end;

function TRttixNumericType.GetMinHexDigits;
begin
  Result := FMinHexDigits;
end;

function TRttixNumericType.GetNumericKind;
begin
  Result := FNumericKind;
end;

function TRttixNumericType.GetSigned;
begin
  Result := FSigned;
end;

function TRttixNumericType.GetSize;
begin
  Result := FSize;
end;

function RttixTypeInfo;
var
  Attributes: TArray<PLiteRttiAttribute>;
  Attribute: PLiteRttiAttribute;
  SubKind: TRttixTypeSubKind;
begin
  if not Assigned(TypeInfo) then
    Error(reInvalidPtr);

  Attributes := FieldAttributes + TypeInfo.AllAttributes;

  // Determine type sub-kind
  case TypeInfo.Kind of
    tkEnumeration:
      if TypeInfo.EnumerationIsBoolean then
        SubKind := rtkBoolean
      else
        SubKind := rtkEnumeration;

    tkInteger, tkInt64:
    begin
      SubKind := rtkNumeric;

      for Attribute in Attributes do
        if Attribute.IsFlagNameAttribute or Attribute.IsSubEnumAttribute then
        begin
          SubKind := rtkBitwise;
          Break;
        end;
    end;
  else
    SubKind := rtkOther;
  end;

  case SubKind of
    rtkEnumeration:
      Result := TRttixEnumType.Create(TypeInfo, Attributes);
    rtkBoolean:
      Result := TRttixBoolType.Create(TypeInfo, Attributes);
    rtkBitwise:
      Result := TRttixBitwiseType.Create(TypeInfo, Attributes);
    rtkNumeric:
      Result := TRttixNumericType.Create(TypeInfo, Attributes);
  else
    Result := TRttixType.Create(TypeInfo, SubKind, Attributes);
  end;
end;

end.
