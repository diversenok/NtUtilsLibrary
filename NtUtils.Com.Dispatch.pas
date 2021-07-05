unit NtUtils.Com.Dispatch;

{
  This module allows working with variant types and IDispatch without
  relying on System.Variant.
}

interface

uses
  Winapi.ObjBase, Winapi.ObjIdl, NtUtils;

// Variant creation helpers
function VarEmpty: TVarData;
function VarFromWord(const Value: Word): TVarData;
function VarFromCardinal(const Value: Cardinal): TVarData;
function VarFromIntegerRef(const [ref] Value: Integer): TVarData;
function VarFromWideString(const [ref] Value: WideString): TVarData;
function VarFromIDispatch(const Value: IDispatch): TVarData;

// Bind to a COM object using a name
function DispxBindToObject(
  const ObjectName: String;
  out Dispatch: IDispatch
): TNtxStatus;

// Retrieve a property on an object referenced by IDispatch
function DispxPropertyGet(
  const Dispatch: IDispatch;
  const Name: String;
  out Value: TVarData
): TNtxStatus;

// Assign a property on an object pointed by IDispatch
function DispxPropertySet(
  const Dispatch: IDispatch;
  const Name: String;
  const Value: TVarData
): TNtxStatus;

// Call a method on an object pointer by IDispatch
function DispxMethodCall(
  const Dispatch: IDispatch;
  const Name: String;
  [opt] const Parameters: TArray<TVarData> = nil;
  [out, opt] VarResult: PVarData = nil
): TNtxStatus;

// Initialize COM for the process
function ComxInitialize(
  out Uninitializer: IAutoReleasable;
  PreferredMode: TCoInitMode = COINIT_MULTITHREADED
): TNtxStatus;

// Create a COM object from a CLSID
function ComxCreateInstance(
  const clsid: TCLSID;
  const iid: TIID;
  out pv;
  ClsContext: TClsCtx = CLSCTX_ALL
): TNtxStatus;

implementation

uses
  Winapi.WinError, DelphiUtils.Arrays;

{ Variant helpers }

function VarEmpty;
begin
  VariantInit(Result);
end;

function VarFromWord;
begin
  VariantInit(Result);
  Result.VType := varWord;
  Result.VWord := Value;
end;

function VarFromCardinal;
begin
  VariantInit(Result);
{$IF CompilerVersion >= 32}
  Result.VType := varUInt32;
  Result.VUInt32 := Value;
{$ELSE}
  Result.VType := varLongWord;
  Result.VLongWord := Value;
{$ENDIF}
end;

function VarFromIntegerRef;
begin
  VariantInit(Result);
  Result.VType := varInteger or varByRef;
  Result.VPointer := @Value;
end;

function VarFromWideString;
begin
  VariantInit(Result);
  if Value <> '' then
  begin
    Result.VType := varOleStr;
    Result.VOleStr := PWideChar(Value);
  end;
end;

function VarFromIDispatch;
begin
  VariantInit(Result);
  Result.VType := varDispatch;
  Result.VDispatch := Pointer(Value);
end;

{ Binding helpers }

function DispxBindToObject;
var
  BindCtx: IBindCtx;
  Moniker: IMoniker;
  chEaten: Cardinal;
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

  Result.Location := 'IMoniker::BindToObject("' + ObjectName + '")';
  Result.HResult := Moniker.BindToObject(BindCtx, nil, IDispatch, Dispatch);
end;

{ IDispatch invocation helpers }

function DispxGetNameId(
  const Dispatch: IDispatch;
  const Name: String;
  out DispId: TDispID
): TNtxStatus;
var
  WideName: WideString;
begin
  WideName := Name;

  Result.Location := 'IDispatch::GetIDsOfNames("' + Name + '")';
  Result.HResult := Dispatch.GetIDsOfNames(GUID_NULL, @WideName, 1, 0, @DispID);
end;

function DispxInvoke(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  const Flags: Word;
  var Params: TDispParams;
  [out, opt] VarResult: Pointer
): TNtxStatus;
var
  ExceptInfo: TExcepInfo;
  ArgErr: Cardinal;
  Code: HRESULT;
begin
  Code := Dispatch.Invoke(DispID, GUID_NULL, 0, Flags, Params, VarResult,
    @ExceptInfo, @ArgErr);

  if Code = DISP_E_EXCEPTION then
  begin
    // Prefere more specific error codes
    Result.Location := ExceptInfo.bstrSource;
    Result.HResult := ExceptInfo.scode;
  end
  else
  begin
    Result.Location := 'IDispatch::Invoke';
    Result.HResult := Code;
  end;
end;

function DispxPropertyGet;
var
  DispID: TDispID;
  Params: TDispParams;
begin
  // Determine the DispID of the property
  Result := DispxGetNameId(Dispatch, Name, DispID);

  if not Result.IsSuccess then
    Exit;

  // Prepare the parameters
  FillChar(Params, SizeOf(Params), 0);

  VariantInit(Value);

  Result := DispxInvoke(Dispatch, DispID, DISPATCH_METHOD or
    DISPATCH_PROPERTYGET, Params, @Value);
end;

function DispxPropertySet;
var
  DispID, Action: TDispID;
  Params: TDispParams;
begin
  // Determine the DispID of the property
  Result := DispxGetNameId(Dispatch, Name, DispID);

  if not Result.IsSuccess then
    Exit;

  Action := DISPID_PROPERTYPUT;

  // Prepare the parameters
  Params.rgvarg := Pointer(@Value);
  Params.rgdispidNamedArgs := Pointer(@Action);
  Params.cArgs := 1;
  Params.cNamedArgs := 1;

  Result := DispxInvoke(Dispatch, DispID, DISPATCH_PROPERTYPUT, Params, nil);
end;

function DispxMethodCall;
var
  DispID: TDispID;
  Params: TDispParams;
begin
  // Determine the DispID of the property
  Result := DispxGetNameId(Dispatch, Name, DispID);

  if not Result.IsSuccess then
    Exit;

  // IDispatch expects method parameters to go from right to left
  Params.cArgs := Length(Parameters);
  Params.rgvarg := Pointer(TArray.Reverse<TVarData>(Parameters));
  Params.cNamedArgs := 0;
  Params.rgdispidNamedArgs := nil;

  if Assigned(VarResult) then
    VariantInit(VarResult^);

  Result := DispxInvoke(Dispatch, DispID, DISPATCH_METHOD, Params, VarResult);
end;

function ComxInitialize;
begin
  // Try the preferred mode first
  Result.Location := 'CoInitializeEx';
  Result.HResultAllowFalse := CoInitializeEx(nil, PreferredMode);

  // S_FALSE indicates that COM is already initialized. Make sure we return
  // success and provide the caller with uninitializer that will decrement the
  // reference we just added.

  // If someone already initialized COM using a different mode, use it, since
  // we still need to add a reference.
  if Result.HResult = RPC_E_CHANGED_MODE then
    Result.HResultAllowFalse := CoInitializeEx(nil, PreferredMode xor
      COINIT_APARTMENTTHREADED);

  if Result.IsSuccess then
    Uninitializer := Auto.Delay(
      procedure
      begin
        CoUninitialize;
      end
    );
end;

function ComxCreateInstance;
begin
  Result.Location := 'CoCreateInstance';
  Result.HResult := CoCreateInstance(clsid, nil, ClsContext, iid, pv);
end;

end.
