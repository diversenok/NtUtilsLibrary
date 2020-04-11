unit DelphiUiLib.Reflection;

interface

uses
  System.TypInfo, System.Rtti;

type
  TRepresentation = record
    Text: String;
    Hint: String;
  end;

  TRepresenter = function (Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;

  TFieldReflection = record
    FieldName: String;
    Offset: Integer;
    FiledTypeName: String;
    Reflection: TRepresentation;
  end;

  TFieldReflectionCallback = reference to procedure(
    const Field: TFieldReflection);

  TFieldReflectionOptions = set of (foIncludeUntyped, foIncludeUnlisted);

// Introspect a record type traversing its fields
procedure TraverseFields(AType: PTypeInfo; Instance: Pointer;
  Callback: TFieldReflectionCallback; Options: TFieldReflectionOptions = [];
  AggregationOffset: Integer = 0);

// Register a function that knows how to represent a specific type
procedure RegisterRepresenter(AType: PTypeInfo; Representer: TRepresenter);

// Obtain a textual representation of a type instance
function RepresentType(AType: PTypeInfo; const Instance; Attributes:
  TArray<TCustomAttribute> = nil): TRepresentation;

function RepresentRttiType(RttiType: TRttiType; Instance: Pointer;
  Attributes: TArray<TCustomAttribute> = nil): TRepresentation;

implementation

uses
  System.Generics.Collections, DelphiApi.Reflection, DelphiUtils.Reflection,
  NtUtils.Version, DelphiUtils.Strings, System.SysUtils;

procedure TraverseFields(AType: PTypeInfo; Instance: Pointer;
  Callback: TFieldReflectionCallback; Options: TFieldReflectionOptions = [];
  AggregationOffset: Integer = 0);
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiField: TRttiField;
  FieldInfo: TFieldReflection;
  FieldInstance: Pointer;
  Attributes: TArray<TCustomAttribute>;
  a: TCustomAttribute;
  Unlisted: Boolean;
  Aggregate: Boolean;
  OsVersion: TKnownOsVersion;
  MinVersion: MinOSVersionAttribute;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(AType);

  OsVersion := RtlOsVersion;

  for RttiField in RttiType.GetFields do
    begin
      FieldInfo.FieldName := RttiField.Name;
      FieldInfo.Offset := AggregationOffset + RttiField.Offset;
      FieldInfo.FiledTypeName := '';
      FieldInfo.Reflection.Text := '';
      FieldInfo.Reflection.Hint := '';

      Unlisted := False;
      Aggregate := False;
      MinVersion := nil;
      Attributes := RttiField.GetAttributes;

      // Find known field attributes
      for a in Attributes do
      begin
        Unlisted := Unlisted or (a is UnlistedAttribute);
        Aggregate := Aggregate or (a is AggregateAttribute);

        if a is MinOSVersionAttribute then
          MinVersion := MinOSVersionAttribute(a);
      end;

      // Skip unlisted
      if Unlisted and not (foIncludeUnlisted in Options) then
        Continue;

      // Skip fields that require a newer OS than we run on
      if Assigned(MinVersion) and not (MinVersion.Version <= OsVersion) then
        Continue;

      // Can't reflect on fields without a known type
      if not Assigned(RttiField.FieldType) then
      begin
        if foIncludeUntyped in Options then
          Callback(FieldInfo);
        Continue;
      end;

      FieldInstance := PByte(Instance) + RttiField.Offset;

      // Perform aggregation
      if Aggregate then
      begin
        TraverseFields(RttiField.FieldType.Handle, FieldInstance, Callback,
          Options, RttiField.Offset);
        Continue;
      end;

      FieldInfo.FiledTypeName := RttiType.Name;
      FieldInfo.Reflection := RepresentRttiType(RttiField.FieldType,
        FieldInstance, Attributes);

      Callback(FieldInfo);
    end;
end;

{ Representers }

var
  Representers: TDictionary<PTypeInfo,TRepresenter>;

procedure RegisterRepresenter(AType: PTypeInfo; Representer: TRepresenter);
begin
  Representers.AddOrSetValue(AType, Representer);
end;

function RepresentNumeric(RttiType: TRttiType; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute>): TRepresentation;
var
  NumReflection: TNumericReflection;
  BitFlags: array of String;
  i: Integer;
begin
  NumReflection := GetNumericReflection(RttiType.Handle, Instance,
      InstanceAttributes);

  Result.Text := NumReflection.Name;

  if NumReflection.Kind = nkBitwise then
  begin
    SetLength(BitFlags, Length(NumReflection.KnownFlags));

    for i := 0 to High(NumReflection.KnownFlags) do
      BitFlags[i] := CheckboxToString(NumReflection.KnownFlags[i].Presents) +
        ' ' + NumReflection.KnownFlags[i].Flag.Name;

    Result.Hint := String.Join(#$D#$A, BitFlags);
  end;
end;

function RepresentType(AType: PTypeInfo; const Instance; Attributes:
  TArray<TCustomAttribute> = nil): TRepresentation;
var
  RttiContext: TRttiContext;
begin
  RttiContext := TRttiContext.Create;
  Result := RepresentRttiType(RttiContext.GetType(AType), @Instance,
    Attributes);
end;

function RepresentRttiType(RttiType: TRttiType; Instance: Pointer;
  Attributes: TArray<TCustomAttribute>): TRepresentation;
var
  Value: TValue;
begin
  Result.Hint := '';

  if Representers.ContainsKey(RttiType.Handle) then
    Result := Representers[RttiType.Handle](Instance, Attributes)
  else if (RttiType is TRttiOrdinalType) or (RttiType is TRttiInt64Type) then
    Result := RepresentNumeric(RttiType, Instance, Attributes)
  else
  begin
    TValue.MakeWithoutCopy(Instance, RttiType.Handle, Value);
    Result.Text := Value.ToString;

    // Explicitly obtain a reference to interface types. When the variable will
    // go out of scope, the program will release it.
    if Value.Kind = tkInterface then
      Value.AsType<IUnknown>._AddRef;
  end;
end;

initialization
  Representers := TDictionary<PTypeInfo, TRepresenter>.Create;
finalization
  Representers.Free;
end.
