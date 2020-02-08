unit NtUiLib.Reflection;

interface

uses
  System.TypInfo, System.Rtti;

type
  TRepresenter = function (Instance: Pointer): String;

// Register a function that knows how to represent a specific type
procedure RegisterRepresenter(AType: PTypeInfo; Representer: TRepresenter);

// Obtain a textual representation of a type instance
function Represent(RttiType: TRttiType; Instance: Pointer): String;

implementation

uses
  System.Generics.Collections;

var
  Representers: TDictionary<PTypeInfo,TRepresenter>;

procedure RegisterRepresenter(AType: PTypeInfo; Representer: TRepresenter);
begin
  Representers.AddOrSetValue(AType, Representer);
end;

function Represent(RttiType: TRttiType; Instance: Pointer): String;
var
  Value: TValue;
begin
  if Representers.ContainsKey(RttiType.Handle) then
    Result := Representers[RttiType.Handle](Instance)
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
