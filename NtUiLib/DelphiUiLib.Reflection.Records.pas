unit DelphiUiLib.Reflection.Records;

interface

uses
  DelphiUiLib.Reflection;

type
  TFieldReflection = record
    FieldName: String;
    Offset: Integer;
    FiledTypeName: String;
    Reflection: TRepresentation;
  end;

  TFieldReflectionCallback = reference to procedure(
    const Field: TFieldReflection);

  TFieldReflectionOptions = set of (foIncludeUntyped, foIncludeUnlisted);

// Introspect a record type traversing its fields via TypeInfo
procedure TraverseFields(AType: Pointer; const Instance;
  Callback: TFieldReflectionCallback; Options: TFieldReflectionOptions = []);

type
  TRecord = class abstract
    // Introspect a record type traversing its fields via geneirc method
    class procedure Traverse<T>(const Instance: T; Callback:
      TFieldReflectionCallback; Options: TFieldReflectionOptions = []); static;
  end;

implementation

uses
  System.Rtti, DelphiApi.Reflection, NtUtils.Version;

procedure TraverseRttiFields(RttiType: TRttiType; const Instance;
  Callback: TFieldReflectionCallback; Options: TFieldReflectionOptions;
  AggregationOffset: Integer);
var
  RttiField: TRttiField;
  FieldInfo: TFieldReflection;
  pField: Pointer;
  Attributes: TArray<TCustomAttribute>;
  a: TCustomAttribute;
  Unlisted: Boolean;
  Aggregate: Boolean;
  OsVersion: TKnownOsVersion;
  MinVersion: MinOSVersionAttribute;
begin
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

    pField := PByte(@Instance) + RttiField.Offset;

    // Perform aggregation
    if Aggregate then
    begin
      TraverseRttiFields(RttiField.FieldType, pField^, Callback,
        Options, RttiField.Offset);
      Continue;
    end;

    FieldInfo.FiledTypeName := RttiField.FieldType.Name;
    FieldInfo.Reflection := RepresentRttiType(RttiField.FieldType, pField^,
      Attributes);

    Callback(FieldInfo);
  end;
end;

procedure TraverseFields(AType: Pointer; const Instance;
  Callback: TFieldReflectionCallback; Options: TFieldReflectionOptions);
var
  RttiContext: TRttiContext;
begin
  RttiContext := TRttiContext.Create;

  TraverseRttiFields(RttiContext.GetType(AType), Instance, Callback,
    Options, 0);
end;

{ TRecord }

class procedure TRecord.Traverse<T>(const Instance: T;
  Callback: TFieldReflectionCallback; Options: TFieldReflectionOptions);
begin
  TraverseFields(TypeInfo(T), Instance, Callback, Options);
end;

end.
