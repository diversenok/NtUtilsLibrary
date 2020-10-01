unit Winapi.ObjBase;

interface

uses
  Winapi.WinNt, Winapi.ObjIdl, DelphiApi.Reflection;

const
  ole32 = 'ole32.dll';
  oleaut32 = 'oleaut32.dll';

  // ObjBase.37
  COINIT_MULTITHREADED = 0;

  // OleAuto.1082
  DISPATCH_METHOD = $1;
  DISPATCH_PROPERTYGET = $2;
  DISPATCH_PROPERTYPUT = $4;
  DISPATCH_PROPERTYPUTREF = $8;

  // DispEx.202
  DISPATCH_CONSTRUCT = $4000;

  // OAIdl.2174
  DISPID_VALUE = 0;
  DISPID_UNKNOWN = Cardinal(-1);
  DISPID_PROPERTYPUT = Cardinal(-3);

  // coguid.29
  GUID_NULL: TGUID = '{00000000-0000-0000-0000-000000000000}';

type
  // OleAuto.1069
  [Hex] TDispID = type Cardinal;

  // OAIdl.757
  TDispParams = record
    rgvarg: ^TAnysizeArray<TVarData>;
    rgdispidNamedArgs: ^TAnysizeArray<TDispID>;
    cArgs: Cardinal;
    cNamedArgs: Cardinal;
  end;

  PExcepInfo = ^TExcepInfo;
  TFNDeferredFillIn = function(ExInfo: PExcepInfo): HResult stdcall;

  // OAIdl.784
  TExcepInfo = record
    wCode: Word;
    wReserved: Word;
    bstrSource: WideString;
    bstrDescription: WideString;
    bstrHelpFile: WideString;
    dwHelpContext: Longint;
    pvReserved: Pointer;
    pfnDeferredFillIn: TFNDeferredFillIn;
    scode: HResult;
  end;

// OleAuto.174
procedure VariantInit(var V: TVarData); stdcall; external oleaut32;

// OleAuto.175
function VariantClear(var V: TVarData): HResult; stdcall; external oleaut32;

// OleAuto.177
function VariantCopy(var Dest: TVarData; const Source: TVarData): HResult;
  stdcall; external oleaut32;

// OleAuto.179
function VariantCopyInd(var Dest: TVarData; const Source: TVarData): HResult;
  stdcall; external oleaut32;

// combaseapi.411
procedure CoUninitialize; stdcall; external ole32;

// combaseapi.438
function CoInitializeEx(pvReserved: Pointer; coInit: Cardinal): HResult;
  stdcall; external ole32;

// ObjBase.227
function MkParseDisplayName(bc: IBindCtx; szUserName: PWideChar; out chEaten:
  Cardinal; out mk: IMoniker): HResult; stdcall; external ole32;

// ObjBase.233
function CreateBindCtx(reserved: Longint; out bc: IBindCtx): HResult; stdcall;
  external ole32;

implementation

end.
