unit DelphiUiLib.Reflection;

interface

uses
  System.TypInfo, System.Rtti;

type
  TRepresenter = function (Instance: Pointer): String;

  TFieldReflection = record
    FieldName: String;
    Offset: Integer;
    FiledTypeName: String;
    Reflection: String;
    Hint: String;
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
function Represent(RttiType: TRttiType; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute> = nil): String;

implementation

uses
  System.Generics.Collections, DelphiApi.Reflection, DelphiUtils.Reflection,
  NtUtils.Version;

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
      FieldInfo.Reflection := '';
      FieldInfo.Hint := '';

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
      FieldInfo.Reflection := Represent(RttiField.FieldType, FieldInstance,
        Attributes);

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

function Represent(RttiType: TRttiType; Instance: Pointer;
  InstanceAttributes: TArray<TCustomAttribute>): String;
var
  Value: TValue;
begin
  if Representers.ContainsKey(RttiType.Handle) then
    Result := Representers[RttiType.Handle](Instance)
  else if (RttiType is TRttiOrdinalType) or (RttiType is TRttiInt64Type) then
    Result := GetNumericReflection(RttiType.Handle, Instance,
      InstanceAttributes).Name
  else
  begin
    TValue.MakeWithoutCopy(Instance, RttiType.Handle, Value);
    Result := Value.ToString;
  end;
end;

initialization
  Representers := TDictionary<PTypeInfo, TRepresenter>.Create;
finalization
  Representers.Free;
end.
