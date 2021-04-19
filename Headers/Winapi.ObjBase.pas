unit Winapi.ObjBase;

interface

uses
  Winapi.WinNt, Winapi.ObjIdl, DelphiApi.Reflection;

const
  ole32 = 'ole32.dll';
  oleaut32 = 'oleaut32.dll';

  // ObjBase.37
  COINIT_MULTITHREADED = $0;
  COINIT_APARTMENTTHREADED = $2;

  // WTypesbase.360
  CLSCTX_INPROC_SERVER = $1;
  CLSCTX_INPROC_HANDLER = $2;
  CLSCTX_LOCAL_SERVER = $4;
  CLSCTX_INPROC_SERVER16 = $8;
  CLSCTX_REMOTE_SERVER = $10;
  CLSCTX_INPROC_HANDLER16 = $20;
  CLSCTX_NO_CODE_DOWNLOAD = $400;
  CLSCTX_NO_CUSTOM_MARSHAL = $1000;
  CLSCTX_ENABLE_CODE_DOWNLOAD = $2000;
  CLSCTX_NO_FAILURE_LOG = $4000;
  CLSCTX_DISABLE_AAA = $8000;
  CLSCTX_ENABLE_AAA = $10000;
  CLSCTX_FROM_DEFAULT_CONTEXT = $20000;
  CLSCTX_ACTIVATE_X86_SERVER = $40000;
  CLSCTX_ACTIVATE_64_BIT_SERVER = $80000;
  CLSCTX_ENABLE_CLOAKING = $100000;
  CLSCTX_APPCONTAINER = $400000;
  CLSCTX_ACTIVATE_AAA_AS_IU = $800000;
  CLSCTX_ACTIVATE_ARM32_SERVER = $2000000;
  CLSCTX_PS_DLL = $80000000;

  CLSCTX_ALL = CLSCTX_INPROC_SERVER or CLSCTX_INPROC_HANDLER or
    CLSCTX_LOCAL_SERVER;

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

  [FlagName(COINIT_MULTITHREADED, 'Multi-threaded')]
  [FlagName(COINIT_APARTMENTTHREADED, 'Apartment-threaded')]
  TCoInitMode = type Cardinal;

  [FlagName(CLSCTX_INPROC_SERVER, 'In-proc Server')]
  [FlagName(CLSCTX_INPROC_HANDLER, 'In-proc Handler')]
  [FlagName(CLSCTX_LOCAL_SERVER, 'Local Server')]
  [FlagName(CLSCTX_INPROC_SERVER16, 'In-proc Server 16')]
  [FlagName(CLSCTX_REMOTE_SERVER, 'Remote Server')]
  [FlagName(CLSCTX_INPROC_HANDLER16, 'In-proc Handler 16')]
  [FlagName(CLSCTX_NO_CODE_DOWNLOAD, 'No Code Download')]
  [FlagName(CLSCTX_NO_CUSTOM_MARSHAL, 'No Custom Marshal')]
  [FlagName(CLSCTX_ENABLE_CODE_DOWNLOAD, 'Enable Code Download')]
  [FlagName(CLSCTX_NO_FAILURE_LOG, 'No Failure Log')]
  [FlagName(CLSCTX_DISABLE_AAA, 'Disable AAA')]
  [FlagName(CLSCTX_ENABLE_AAA, 'Enable AAA')]
  [FlagName(CLSCTX_FROM_DEFAULT_CONTEXT, 'From Default Context')]
  [FlagName(CLSCTX_ACTIVATE_X86_SERVER, 'Activate 32-bit Server')]
  [FlagName(CLSCTX_ACTIVATE_64_BIT_SERVER, 'Activate 64-bit Server')]
  [FlagName(CLSCTX_ENABLE_CLOAKING, 'Enable Cloaking')]
  [FlagName(CLSCTX_APPCONTAINER, 'AppContainer')]
  [FlagName(CLSCTX_ACTIVATE_AAA_AS_IU, 'Activate AAA as IU')]
  [FlagName(CLSCTX_ACTIVATE_ARM32_SERVER, 'Activate ARM32 Server')]
  [FlagName(CLSCTX_PS_DLL, 'PS DLL')]
  TClsCtx = type Cardinal;

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

// OleAuto.74
function SysAllocString(
  [in, opt] Buffer: PWideChar
): PWideChar; stdcall; external oleaut32;

// OleAuto.80
procedure SysFreeString(
  [in, opt] Buffer: PWideChar
); stdcall; external oleaut32;

// OleAuto.174
procedure VariantInit(
  var V: TVarData
); stdcall; external oleaut32;

// OleAuto.175
function VariantClear(
  var V: TVarData
): HResult; stdcall; external oleaut32;

// OleAuto.177
function VariantCopy(
  var Dest: TVarData;
  const Source: TVarData
): HResult; stdcall; external oleaut32;

// OleAuto.179
function VariantCopyInd(
  var Dest: TVarData;
  const Source: TVarData
): HResult; stdcall; external oleaut32;

// combaseapi.411
procedure CoUninitialize; stdcall; external ole32;

// combaseapi.438
function CoInitializeEx(
  [Reserved] pvReserved: Pointer;
  coInit: TCoInitMode
): HResult; stdcall; external ole32;

// combaseapi.1046
function CoCreateInstance(
  const clsid: TCLSID;
  [opt] unkOuter: IUnknown;
  ClsContext: TClsCtx;
  const iid: TIID;
  out pv
): HResult; stdcall; external ole32;

// ObjBase.227
function MkParseDisplayName(
  bc: IBindCtx;
  [in] UserName: PWideChar;
  out chEaten: Cardinal;
  out mk: IMoniker
): HResult; stdcall; external ole32;

// ObjBase.233
function CreateBindCtx(
  [Reserved] reserved: Longint;
  out bc: IBindCtx
): HResult; stdcall; external ole32;

implementation

end.
