unit NtUtils.Com;

{
  This module allows working with variant types and IDispatch without
  relying on System.Variant.
}

interface

uses
  Ntapi.ObjBase, Ntapi.ObjIdl, DelphiApi.Reflection, NtUtils;

// Variant creation helpers
function VarEmpty: TVarData;
function VarFromWord(const Value: Word): TVarData;
function VarFromCardinal(const Value: Cardinal): TVarData;
function VarFromIntegerRef(const [ref] Value: Integer): TVarData;
function VarFromWideString(const [ref] Value: WideString): TVarData;
function VarFromIDispatch(const Value: IDispatch): TVarData;

// Bind to a COM IDispatch object by name
function DispxBindToObject(
  const ObjectName: String;
  out Dispatch: IDispatch
): TNtxStatus;

// Lookup an ID of an IDispatch name
function DispxGetNameId(
  const Dispatch: IDispatch;
  const Name: String;
  out DispId: TDispID
): TNtxStatus;

// Invoke IDispatch
function DispxInvoke(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  const Flags: Word;
  var Params: TDispParams;
  [out, opt] VarResult: Pointer
): TNtxStatus;

// Invoke IDispatch using a string name
function DispxInvokeByName(
  const Dispatch: IDispatch;
  const Name: String;
  const Flags: Word;
  var Params: TDispParams;
  [out, opt] VarResult: Pointer
): TNtxStatus;

// Retrieve a property via an IDispatch by ID
function DispxGetProperty(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  out Value: TVarData
): TNtxStatus;

// Retrieve a property via an IDispatch by name
function DispxGetPropertyByName(
  const Dispatch: IDispatch;
  const Name: String;
  out Value: TVarData
): TNtxStatus;

// Assign a property via an IDispatch by ID
function DispxSetProperty(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  const Value: TVarData
): TNtxStatus;

// Assign a property via an IDispatch by name
function DispxSetPropertyByName(
  const Dispatch: IDispatch;
  const Name: String;
  const Value: TVarData
): TNtxStatus;

// Call a method via IDispatch by ID
function DispxCallMethod(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  [opt] const Parameters: TArray<TVarData> = nil;
  [out, opt] VarResult: PVarData = nil
): TNtxStatus;

// Call a method via IDispatch by name
function DispxCallMethodByName(
  const Dispatch: IDispatch;
  const Name: String;
  [opt] const Parameters: TArray<TVarData> = nil;
  [out, opt] VarResult: PVarData = nil
): TNtxStatus;

// Initialize COM for the current process
[Result: ReleaseWith('CoUninitialize')]
function ComxInitializeEx(
  PreferredMode: TCoInitMode = COINIT_APARTMENTTHREADED
): TNtxStatus;

// Initialize COM for the process and uninitialize it later
function ComxInitializeExAuto(
  out Uninitializer: IAutoReleasable;
  PreferredMode: TCoInitMode = COINIT_APARTMENTTHREADED
): TNtxStatus;

// Create a COM object from a CLSID
[RequiresCOM]
function ComxCreateInstance(
  const Clsid: TClsid;
  const Iid: TIid;
  out pv;
  ClsContext: TClsCtx = CLSCTX_ALL
): TNtxStatus;

// Create an in-process COM object without using COM facilities
function RtlxComxCreateInstance(
  const DllName: String;
  const Clsid: TClsid;
  const Iid: TIid;
  out pv;
  [opt] const ClassNameHint: String = ''
): TNtxStatus;

// Create an in-process COM object via CoCreateInstance or fall back to loading
// it directly without using COM facilities
function ComxCreateInstanceWithFallback(
  const DllName: String;
  const Clsid: TClsid;
  const Iid: TIid;
  out pv;
  [opt] const ClassNameHint: String = '';
  ClsContext: TClsCtx = CLSCTX_ALL
): TNtxStatus;

implementation

uses
  Ntapi.WinError, NtUtils.Errors, DelphiUtils.Arrays, NtUtils.Ldr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

  Result.Location := 'MkParseDisplayName';
  Result.LastCall.Parameter := ObjectName;
  Result.HResult := MkParseDisplayName(BindCtx, StringToOleStr(ObjectName),
    chEaten, Moniker);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IMoniker::BindToObject';
  Result.LastCall.Parameter := ObjectName;
  Result.HResult := Moniker.BindToObject(BindCtx, nil, IDispatch, Dispatch);
end;

{ IDispatch invocation helpers }

function DispxGetNameId;
var
  WideName: WideString;
begin
  WideName := Name;

  Result.Location := 'IDispatch::GetIDsOfNames';
  Result.LastCall.Parameter := Name;
  Result.HResult := Dispatch.GetIDsOfNames(GUID_NULL, @WideName, 1, 0, @DispID);
end;

function DispxInvoke;
var
  ExceptInfo: TExcepInfo;
  ArgErr: Cardinal;
begin
  Result.Location := 'IDispatch::Invoke';
  Result.HResult := Dispatch.Invoke(DispID, GUID_NULL, 0, Flags, Params,
    VarResult, @ExceptInfo, @ArgErr);

  if Result.HResult = DISP_E_EXCEPTION then
  begin
    // Execute deferred exception fill-in if necessary
    if not Assigned(ExceptInfo.pfnDeferredFillIn) or
      ExceptInfo.pfnDeferredFillIn(@ExceptInfo).IsSuccess then
      Result.LastCall.Parameter := ExceptInfo.bstrSource;

    // Prefere more specific error codes
    if not ExceptInfo.scode.IsSuccess then
      Result.HResult := ExceptInfo.scode
    else if ExceptInfo.wCode <> ERROR_SUCCESS then
      Result.Win32Error := ExceptInfo.wCode;
  end;
end;

function DispxInvokeByName;
var
  DispID: TDispID;
begin
  Result := DispxGetNameId(Dispatch, Name, DispID);

  if not Result.IsSuccess then
    Exit;

  Result := DispxInvoke(Dispatch, DispID, Flags, Params, VarResult);

  if Result.HResult <> DISP_E_EXCEPTION then
    Result.LastCall.Parameter := Name;
end;

function DispxGetProperty;
var
  Params: TDispParams;
begin
  Params := Default(TDispParams);
  VariantInit(Value);

  Result := DispxInvoke(Dispatch, DispId, DISPATCH_METHOD or
    DISPATCH_PROPERTYGET, Params, @Value);
end;

function DispxGetPropertyByName;
var
  Params: TDispParams;
begin
  Params := Default(TDispParams);
  VariantInit(Value);

  Result := DispxInvokeByName(Dispatch, Name, DISPATCH_METHOD or
    DISPATCH_PROPERTYGET, Params, @Value);
end;

function DispxSetProperty;
var
  Action: TDispID;
  Params: TDispParams;
begin
  Action := DISPID_PROPERTYPUT;

  // Prepare the parameters
  Params.rgvarg := Pointer(@Value);
  Params.rgdispidNamedArgs := Pointer(@Action);
  Params.cArgs := 1;
  Params.cNamedArgs := 1;

  Result := DispxInvoke(Dispatch, DispId, DISPATCH_PROPERTYPUT, Params, nil);
end;

function DispxSetPropertyByName;
var
  Action: TDispID;
  Params: TDispParams;
begin
  Action := DISPID_PROPERTYPUT;

  // Prepare the parameters
  Params.rgvarg := Pointer(@Value);
  Params.rgdispidNamedArgs := Pointer(@Action);
  Params.cArgs := 1;
  Params.cNamedArgs := 1;

  Result := DispxInvokeByName(Dispatch, Name, DISPATCH_PROPERTYPUT, Params, nil);
end;

function DispxCallMethod;
var
  Params: TDispParams;
begin
  // IDispatch expects method parameters to go from right to left
  Params.cArgs := Length(Parameters);
  Params.rgvarg := Pointer(TArray.Reverse<TVarData>(Parameters));
  Params.cNamedArgs := 0;
  Params.rgdispidNamedArgs := nil;

  if Assigned(VarResult) then
    VariantInit(VarResult^);

  Result := DispxInvoke(Dispatch, DispId, DISPATCH_METHOD, Params, VarResult);
end;

function DispxCallMethodByName;
var
  Params: TDispParams;
begin
  // IDispatch expects method parameters to go from right to left
  Params.cArgs := Length(Parameters);
  Params.rgvarg := Pointer(TArray.Reverse<TVarData>(Parameters));
  Params.cNamedArgs := 0;
  Params.rgdispidNamedArgs := nil;

  if Assigned(VarResult) then
    VariantInit(VarResult^);

  Result := DispxInvokeByName(Dispatch, Name, DISPATCH_METHOD, Params,
    VarResult);
end;

{ COM }

function ComxInitializeEx;
begin
  Result.Location := 'CoInitializeEx';
  Result.HResultAllowFalse := CoInitializeEx(nil, PreferredMode);

  // S_FALSE indicates that COM is already initialized; RPC_E_CHANGED_MODE means
  // that someone already initialized COM using a different mode. Use it, since
  // we still need to add a reference.

  if Result.HResult = RPC_E_CHANGED_MODE then
    Result.HResultAllowFalse := CoInitializeEx(nil, PreferredMode xor
      COINIT_APARTMENTTHREADED);
end;

function ComxInitializeExAuto;
begin
  Result := ComxInitializeEx(PreferredMode);

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

function RtlxComxCreateInstance(
  const DllName: String;
  const Clsid: TClsid;
  const Iid: TIid;
  out pv;
  const ClassNameHint: String = ''
): TNtxStatus;
var
  Dll: IAutoPointer;
  DllGetClassObject: TDllGetClassObject;
  ClassFactory: IClassFactory;
begin
  // Load the library containing the component
  Result := LdrxLoadDllAuto(DllName, Dll);

  if not Result.IsSuccess then
    Exit;

  // Locate the class factory export
  Result := LdrxGetProcedureAddress(Dll.Data, 'DllGetClassObject',
    Pointer(@DllGetClassObject));

  if not Result.IsSuccess then
    Exit;

  // Instantiate the class factory for the component
  Result.Location := 'DllGetClassObject';
  Result.LastCall.Parameter := ClassNameHint;
  Result.HResult := DllGetClassObject(Clsid, IClassFactory, ClassFactory);

  if not Result.IsSuccess then
    Exit;

  // Don't auto-unload while holding class factory references
  Dll.AutoRelease := False;

  Result.Location := 'IClassFactory::CreateInstance';
  Result.LastCall.Parameter := ClassNameHint;
  Result.HResult := ClassFactory.CreateInstance(nil, Iid, pv);

  if not Result.IsSuccess then
  begin
    // If failed, release the class factory and only then unload the DLL
    ClassFactory := nil;
    Dll.AutoRelease := True;
  end;
end;

function ComxCreateInstanceWithFallback;
begin
  Result := ComxCreateInstance(Clsid, Iid, pv, ClsContext);

  if not Result.IsSuccess then
    Result := RtlxComxCreateInstance(DllName, Clsid, Iid, pv, ClassNameHint);
end;

end.
