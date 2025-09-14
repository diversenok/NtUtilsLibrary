unit DelphiUiLib.Reflection.Records;

{
  This module allows traversing fields in records and representing each of them
  as a string using Runtime Type Information.
}

interface

type
  TRepresentation = record
    TypeName: String;
    Text: String;
    Hint: String;
  end;

  TFieldReflection = record
    FieldName: String;
    Offset: IntPtr;
    Reflection: TRepresentation;
  end;

  TFieldReflectionCallback = reference to procedure (
    const Field: TFieldReflection
  );

  TFieldReflectionOptions = set of (
    foIncludeUntyped,
    foIncludeUnlisted,
    foIncludeInternal // i.e., offets and record size fields
  );

// Introspect a record type traversing its fields via TypeInfo
procedure TraverseFields(
  AType: Pointer;
  const Instance;
  Callback: TFieldReflectionCallback;
  Options: TFieldReflectionOptions = []
);

type
  TRecord = class abstract
    // Introspect a record type traversing its fields via generic method
    class procedure Traverse<T>(
      const Instance: T;
      Callback: TFieldReflectionCallback;
      Options: TFieldReflectionOptions = []
    ); static;
  end;

implementation

uses
  System.Rtti, DelphiApi.Reflection, Ntapi.Versions, DelphiUiLib.LiteReflection,
  System.TypInfo;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

procedure ExtractReferredType(
  var RttiType: TRttiType;
  var pInstance: Pointer
);
begin
  // Use the underlying type for pointer types
  if (RttiType is TRttiPointerType) and
    Assigned(TRttiPointerType(RttiType).ReferredType) then
  begin
    RttiType := TRttiPointerType(RttiType).ReferredType;

    if Assigned(pInstance) then
      pInstance := Pointer(pInstance^);
  end;
end;

procedure TraverseRttiFields(
  RttiType: TRttiType;
  pInstance: Pointer;
  const Callback: TFieldReflectionCallback;
  Options: TFieldReflectionOptions;
  AggregationOffset: IntPtr
);
var
  RttiField: TRttiField;
  FieldInfo: TFieldReflection;
  pField: Pointer;
  Attributes: TArray<TCustomAttribute>;
  a: TCustomAttribute;
  Unlisted, Internal, Aggregate: Boolean;
  OsVersion: TWindowsVersion;
  MinVersion: MinOSVersionAttribute;
  LiteReflection: TRttixFullReflection;
begin
  // Pointers to records do not have any fields. If the passed type is PRecord,
  // dereference it, and use TRecord to access the fields
  ExtractReferredType(RttiType, pInstance);

  OsVersion := RtlOsVersion;

  for RttiField in RttiType.GetFields do
  begin
    FieldInfo.FieldName := RttiField.Name;
    FieldInfo.Offset := AggregationOffset + RttiField.Offset;
    FieldInfo.Reflection.Text := '';
    FieldInfo.Reflection.Hint := '';

    Internal := False;
    Unlisted := False;
    Aggregate := False;
    MinVersion := nil;
    Attributes := RttiField.GetAttributes;

    // Find known field attributes
    for a in Attributes do
    begin
      Unlisted := Unlisted or (a is UnlistedAttribute);
      Internal := Internal or (a is RecordSizeAttribute) or
        (a is OffsetAttribute);
      Aggregate := Aggregate or (a is AggregateAttribute);

      if a is MinOSVersionAttribute then
        MinVersion := MinOSVersionAttribute(a);
    end;

    // Skip unlisted
    if Unlisted and not (foIncludeUnlisted in Options) then
      Continue;

    // Skip internal
    if Internal and not (foIncludeInternal in Options) then
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

    if Assigned(pInstance) then
      pField := PByte(pInstance) + RttiField.Offset
    else
      pField := nil; // In case we traverse without an instance

    // Perform aggregation
    if Aggregate then
    begin
      TraverseRttiFields(RttiField.FieldType, pField, Callback,
        Options, RttiField.Offset);
      Continue;
    end;

    if Assigned(pField) then
    begin
      FieldInfo.Reflection.TypeName := RttiField.FieldType.Name;
      LiteReflection := RttixFormatFull(Pointer(RttiField.FieldType.Handle), pField^);
      FieldInfo.Reflection.Text := LiteReflection.Text;
      FieldInfo.Reflection.Hint := LiteReflection.Hint;
    end
    else
      FieldInfo.Reflection.Text := 'Unknown';

    Callback(FieldInfo);
  end;
end;

procedure TraverseFields;
var
  RttiContext: TRttiContext;
begin
  RttiContext := TRttiContext.Create;

  TraverseRttiFields(RttiContext.GetType(AType), @Instance, Callback, Options,
    0);
end;

{ TRecord }

class procedure TRecord.Traverse<T>;
begin
  TraverseFields(TypeInfo(T), Instance, Callback, Options);
end;

end.
