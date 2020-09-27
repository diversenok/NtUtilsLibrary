unit NtUtils.Com.Dispatch;

interface

uses
  NtUtils, Winapi.ActiveX;

// TODO: Move definitions from built-in Winapi.ActiveX to headers
// TODO: TNtxStatus misinterprets some HRESULTs

// Convert Delphi types to variant arguments
function VarArgFromWord(const Value: Word): TVariantArg;
function VarArgFromCardinal(const Value: Cardinal): TVariantArg;

// Bind to a COM object using a name
function DispxBindToObject(const ObjectName: String; out Dispatch: IDispatch):
  TNtxStatus;

// Set a property on an object pointed by IDispatch
function DispxPropertySet(Dispatch: IDispatch; const Name: String;
  const Value: TVariantArg): TNtxStatus;

implementation

{ Variant argument preparation }

function VarArgFromWord(const Value: Word): TVariantArg;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.vt := VT_UI2;
  Result.uiVal := Value;
end;

function VarArgFromCardinal(const Value: Cardinal): TVariantArg;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.vt := VT_UI4;
  Result.ulVal := Value;
end;

{ Binding helpers }

function DispxBindToObject(const ObjectName: String; out Dispatch: IDispatch):
  TNtxStatus;
var
  BindCtx: IBindCtx;
  Moniker: IMoniker;
  chEaten: Integer;
begin
  Result.Location := 'CreateBindCtx';
  Result.HResult := CreateBindCtx(0, BindCtx);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'MkParseDisplayName("' + ObjectName + '")';
  Result.HResult := MkParseDisplayName(BindCtx, StringToOleStr(ObjectName),
    chEaten, Moniker);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'Moniker.BindToObject("' + ObjectName + '")';
  Result.HResult := Moniker.BindToObject(BindCtx, nil, IDispatch, Dispatch);
end;

{ IDispatch invocation helpers }

function DispxPropertySet(Dispatch: IDispatch; const Name: String;
  const Value: TVariantArg): TNtxStatus;
var
  WideName: WideString;
  DispID, Action: TDispID;
  DispParams: TDispParams;
  ExceptInfo: TExcepInfo;
begin
  WideName := Name;

  // Determine the DispID of the property
  Result.Location := 'IDispatch.GetIDsOfNames("' + Name + '")';
  Result.HResult := Dispatch.GetIDsOfNames(GUID_NULL, @WideName, 1, 0, @DispID);

  if not Result.IsSuccess then
    Exit;

  Action := DISPID_PROPERTYPUT;

  // Prepare the parameters
  DispParams.rgvarg := Pointer(@Value);
  DispParams.rgdispidNamedArgs := Pointer(@Action);
  DispParams.cArgs := 1;
  DispParams.cNamedArgs := 1;

  // Invoke property assignment
  Result.Location := 'IDispatch.Invoke';
  Result.HResult := Dispatch.Invoke(DispID, GUID_NULL, 0,
    DISPATCH_PROPERTYPUT, DispParams, nil, @ExceptInfo, nil)

  // TODO: Handle DISP_E_EXCEPTION
end;

end.
