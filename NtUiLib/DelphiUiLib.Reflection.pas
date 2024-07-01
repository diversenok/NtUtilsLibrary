unit DelphiUiLib.Reflection;

{
  This module provides facilities for using Runtime Type Information to obtain
  textual representation of types. Each type requires a provider which you can
  register here as well.
}

interface

uses
  DelphiApi.Reflection, System.TypInfo, System.Rtti;

type
  TCustomAttributeArray = TArray<TCustomAttribute>;

  TRepresentation = record
    TypeName: String;
    Text: String;
    Hint: String;
  end;

  // An base class for type-specific representers
  TRepresenter = class abstract
    class function GetType: Pointer; virtual; abstract;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; virtual; abstract;
  end;
  TRepresenterClass = class of TRepresenter;

  // PWideChar representer
  TWideCharRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // PAnsiChar representer
  TAnsiCharRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TGuid representer
  TGuidRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

// Enumerate explicit and inherited attribute of a type
function RttixEnumerateAttributes(
  const RttiContext: TRttiContext;
  const RttiType: TRttiType
): TCustomAttributeArray;

// Collect attributes of a specific type
procedure RttixFilterAttributes(
  const Attributes: TCustomAttributeArray;
  const Filter: TCustomAttributeClass;
  out FilteredAttributes: TCustomAttributeArray
);

// Obtain a textual representation of a type via RTTI
function RepresentRttiType(
  const Context: TRttiContext;
  RttiType: TRttiType;
  const Instance;
  [opt] const Attributes: TArray<TCustomAttribute> = nil
): TRepresentation;

// Obtain a textual representation of a type via TypeInfo
function RepresentType(
  AType: Pointer;
  const Instance;
  [opt] const Attributes: TArray<TCustomAttribute> = nil
): TRepresentation;

type
  TType = class abstract
    // Obtain a textual representation of a type via generic call
    class function Represent<T>(
      const Instance: T;
      [opt] const Attributes: TArray<TCustomAttribute> = nil
    ): TRepresentation; static;
  end;

implementation

uses
  System.Generics.Collections, Ntapi.Versions, DelphiUiLib.Strings,
  System.SysUtils, DelphiUiLib.Reflection.Numeric,
  DelphiUiLib.Reflection.Strings, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TWideCharRepresenter }

class function TWideCharRepresenter.GetType;
begin
  Result := TypeInfo(PWideChar)
end;

class function TWideCharRepresenter.Represent;
var
  Value: PWideChar absolute Instance;
begin
  if not Assigned(Value) then
    Result.Text := ''
  else
    Result.Text := String(Value);
end;

{ TAnsiCharRepresenter }

class function TAnsiCharRepresenter.GetType;
begin
  Result := TypeInfo(PAnsiChar);
end;

class function TAnsiCharRepresenter.Represent;
var
  Value: PAnsiChar absolute Instance;
begin
  if not Assigned(Value) then
    Result.Text := ''
  else
    Result.Text := String(AnsiString(Value));
end;

{ TGuidRepresenter }

class function TGuidRepresenter.GetType;
begin
  Result := TypeInfo(TGuid);
end;

class function TGuidRepresenter.Represent;
var
  Guid: TGuid absolute Instance;
begin
  Result.Text := Guid.ToString;
end;

{ Representers }

function TryRepresentCharArray(
  var Representation: TRepresentation;
  RttiType: TRttiType;
  const Instance
): Boolean;
var
  ArrayType: TRttiArrayType;
begin
  Result := False;

  if not (RttiType is TRttiArrayType) then
    Exit;

  ArrayType := TRttiArrayType(RttiType);

  if Assigned(ArrayType.ElementType) and (ArrayType.ElementType.Handle =
    TypeInfo(WideChar)) and (ArrayType.DimensionCount = 1) then
  begin
    // Save type names
    Representation.TypeName := ArrayType.Name;

    // Copy into a string. We can't be sure that the array is zero-terminated
    SetString(Representation.Text, PWideChar(@Instance),
      ArrayType.TotalElementCount);

    // Trim on the first zero termination
    SetLength(Representation.Text, Length(PWideChar(Representation.Text)));

    Result := True;
  end;
end;

var
  // A mapping between PTypeInfo and a metaclass of a representer
  Representers: TDictionary<Pointer, TRepresenterClass>;

function IsRepresenter(
  const RttiType: TRttiType;
  out MetaClass: TRepresenterClass
): Boolean;
begin
  // All representers derive from TRepresenter, check if this type does
  Result := (RttiType is TRttiInstanceType) and
    (RttiType.Handle <> TypeInfo(TRepresenter)) and
    TRttiInstanceType(RttiType).MetaclassType.InheritsFrom(TRepresenter);

  if Result then
    MetaClass := TRepresenterClass(TRttiInstanceType(RttiType).MetaclassType);
end;

procedure InitRepresenters;
var
  RttiContext: TRttiContext;
  MetaClasses: TArray<TRepresenterClass>;
  i: Integer;
begin
  // Init once only
  if Assigned(Representers) then
    Exit;

  RttiContext := RttiContext.Create;

  // Enumerate all registered types and find which one of know how to represent
  // other types. This will give us an array of representer's metaclasses.
  MetaClasses := TArray.Convert<TRttiType, TRepresenterClass>(
    RttiContext.GetTypes, IsRepresenter);

  // Initialize the mapping
  Representers := TDictionary<Pointer, TRepresenterClass>.Create;

  // Each representer reports a type it wants to represent, save them
  for i := 0 to High(MetaClasses) do
    Representers.Add(MetaClasses[i].GetType, MetaClasses[i]);
end;

{ Helpers }

function RttixEnumerateAttributes;
var
  a: TCustomAttribute;
begin
  Result := RttiType.GetAttributes;

  for a in Result do
    if a is InheritsFromAttribute then
    begin
      // Recursively collect inherited attributes
      Result := Result + RttixEnumerateAttributes(RttiContext,
        RttiContext.GetType(InheritsFromAttribute(a).TypeInfo));

      Break;
    end;
end;

procedure RttixFilterAttributes(
  const Attributes: TCustomAttributeArray;
  const Filter: TCustomAttributeClass;
  out FilteredAttributes: TCustomAttributeArray
);
var
  a: TCustomAttribute;
  Count: Cardinal;
begin
  Count := 0;

  for a in Attributes do
    if a is Filter then
      Inc(Count);

  SetLength(FilteredAttributes, Count);

  Count := 0;
  for a in Attributes do
    if a is Filter then
    begin
      FilteredAttributes[Count] := a;
      Inc(Count);
    end;
end;

{ TType }

function RepresentRttiType;
var
  Value: TValue;
begin
  Result.Hint := '';

  // Register all type representers
  InitRepresenters;

  // Try to use a specific representer first
  if Representers.ContainsKey(RttiType.Handle) then
    Result := Representers[RttiType.Handle].Represent(Instance, Attributes)

  // Use numeric reflection when appropriate
  else if (RttiType is TRttiOrdinalType) or (RttiType is TRttiInt64Type) then
    Result := GetNumericReflection(RttiType.Handle, Instance, Attributes).Basic

  // Represent arrays of characters as strings
  else if TryRepresentCharArray(Result, RttiType, Instance) then
    { Nothing to do here }

  // Fallback to default representation
  else
  begin
    TValue.MakeWithoutCopy(@Instance, RttiType.Handle, Value);
    Result.Text := Value.ToString;

    // Explicitly obtain a reference to interface types. The epilogue will
    // release it.
    if (Value.Kind = tkInterface) and not Value.IsEmpty then
      Value.AsType<IUnknown>._AddRef;
  end;

  // Save type names
  Result.TypeName := RttiType.Name;
end;

function RepresentType;
var
  RttiContext: TRttiContext;
begin
  RttiContext := TRttiContext.Create;
  Result := RepresentRttiType(RttiContext, RttiContext.GetType(AType), Instance,
    Attributes);
end;

{ TType }

class function TType.Represent<T>;
begin
  if Assigned(TypeInfo(T)) then
    Result := RepresentType(TypeInfo(T), Instance, Attributes)
  else
  case SizeOf(T) of
    SizeOf(Byte), SizeOf(Word), SizeOf(Cardinal), SizeOf(UInt64):
      Result := TNumeric.Represent<T>(Instance, Attributes).Basic;
  else
    Result.Text := '(unknown type)';
  end;
end;

initialization
  CompileTimeInclude(TWideCharRepresenter);
  CompileTimeInclude(TAnsiCharRepresenter);
  CompileTimeInclude(TGuidRepresenter);
finalization
  if Assigned(Representers) then
    Representers.Free;
end.
