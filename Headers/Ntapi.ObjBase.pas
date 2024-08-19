unit Ntapi.ObjBase;

{
  This file includes basic types for COM interaction.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection, DelphiApi.DelayLoad, Ntapi.Versions;

const
  ole32 = 'ole32.dll';
  oleaut32 = 'oleaut32.dll';
  combase = 'combase.dll';

var
  delayed_ole32: TDelayedLoadDll = (DllName: ole32);
  delayed_oleaut32: TDelayedLoadDll = (DllName: oleaut32);
  delayed_combase: TDelayedLoadDll = (DllName: combase);

const
  // SDK::objbase.h - COM initialization mode
  COINIT_MULTITHREADED = $0;
  COINIT_APARTMENTTHREADED = $2;
  COINIT_DISABLE_OLE1DDE = $4;
  COINIT_SPEED_OVER_MEMORY = $8;
  COINIT_BRIDGE_STA = $20000000; // rev
  COINIT_APPLICATION_STA = $40000000; // rev
  COINIT_WINRT = $80000000; // rev

  // SDK::WTypesbase.h - COM context flags
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
  CLSCTX_ALLOW_LOWER_TRUST_REGISTRATION	= $4000000;
  CLSCTX_PS_DLL = $80000000;

  CLSCTX_ALL = CLSCTX_INPROC_SERVER or CLSCTX_INPROC_HANDLER or
    CLSCTX_LOCAL_SERVER;

  // SDK::oleauto.h
  DISPATCH_METHOD = $1;
  DISPATCH_PROPERTYGET = $2;
  DISPATCH_PROPERTYPUT = $4;
  DISPATCH_PROPERTYPUTREF = $8;

  // SDK::DispEx.h
  DISPATCH_CONSTRUCT = $4000;

  // SDK::oaidl.h
  DISPID_VALUE = 0;
  DISPID_UNKNOWN = Cardinal(-1);
  DISPID_PROPERTYPUT = Cardinal(-3);

  // SDK::coguid.h
  GUID_NULL: TGUID = '{00000000-0000-0000-0000-000000000000}';

type
  TIid = TGuid;
  TClsid = TGuid;
  TVariantBool = type SmallInt;

  // SDK::oleauto.h
  [Hex] TDispID = type Cardinal;

  [FlagName(COINIT_MULTITHREADED, 'Multi-threaded')]
  [FlagName(COINIT_APARTMENTTHREADED, 'Apartment-threaded')]
  [FlagName(COINIT_DISABLE_OLE1DDE, 'Disable OLE1DDE')]
  [FlagName(COINIT_SPEED_OVER_MEMORY, 'Speed-over-memory')]
  [FlagName(COINIT_BRIDGE_STA, 'Bridge STA')]
  [FlagName(COINIT_APPLICATION_STA, 'Application STA')]
  [FlagName(COINIT_WINRT, 'WinRT')]
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
  [FlagName(CLSCTX_ALLOW_LOWER_TRUST_REGISTRATION, 'Allow Lower Trust Registration')]
  [FlagName(CLSCTX_PS_DLL, 'PS DLL')]
  TClsCtx = type Cardinal;

  // SDK::objidlbase.h
  [SDKName('APTTYPE')]
  [NamingStyle(nsSnakeCase, 'APTTYPE')]
  TAptType = (
    APTTYPE_STA = 0,
    APTTYPE_MTA = 1,
    APTTYPE_NA = 2,
    APTTYPE_MAINSTA = 3
  );

  // SDK::objidlbase.h
  [SDKName('APTTYPEQUALIFIER')]
  [NamingStyle(nsSnakeCase, 'APTTYPEQUALIFIER')]
  TAptTypeQualifier = (
    APTTYPEQUALIFIER_NONE = 0,
    APTTYPEQUALIFIER_IMPLICIT_MTA = 1,
    APTTYPEQUALIFIER_NA_ON_MTA = 2,
    APTTYPEQUALIFIER_NA_ON_STA = 3,
    APTTYPEQUALIFIER_NA_ON_IMPLICIT_MTA = 4,
    APTTYPEQUALIFIER_NA_ON_MAINSTA = 5,
    APTTYPEQUALIFIER_APPLICATION_STA = 6
  );

  // SDK::combaseapi.h
  [SDKName('CO_MTA_USAGE_COOKIE')]
  TCoMtaUsageCookie = type THandle;
  PCoMtaUsageCookie = ^TCoMtaUsageCookie;

  // Annotation for components requiring COM to be initialized
  RequiresCOMAttribute = class (TCustomAttribute)
  end;

  // SDK::oaidl.h
  [SDKName('DISPPARAMS')]
  TDispParams = record
    rgvarg: ^TAnysizeArray<TVarData>;
    rgdispidNamedArgs: ^TAnysizeArray<TDispID>;
    cArgs: Cardinal;
    cNamedArgs: Cardinal;
  end;

  PExcepInfo = ^TExcepInfo;
  TFNDeferredFillIn = function([out] ExInfo: PExcepInfo): HResult stdcall;

  // SDK::oaidl.h
  [SDKName('EXCEPINFO')]
  TExcepInfo = record
    wCode: Word;
    [Unlisted] wReserved: Word;
    bstrSource: WideString;
    bstrDescription: WideString;
    bstrHelpFile: WideString;
    dwHelpContext: Longint;
    [Unlisted] pvReserved: Pointer;
    pfnDeferredFillIn: TFNDeferredFillIn;
    scode: HResult;
  end;

  // SDK::combaseapi.h
  TDllGetClassObject = function (
    [in] const clsid: TClsid;
    [in] const iid: TIid;
    out pv
  ): HResult; stdcall;

  // SDK::combaseapi.h
  TDllCanUnloadNow = function (
  ): HResult; stdcall;

  // SDK::Unknwnbase.h
  IClassFactory = interface (IUnknown)
    ['{00000001-0000-0000-C000-000000000046}']
    function CreateInstance(
      [in, opt] const UnkOuter: IUnknown;
      [in] const riid: TIid;
      [out] out pvObject
    ): HResult; stdcall;

    function LockServer(
      [in] Lock: LongBool
    ): HResult; stdcall;
  end;

  // WMI's Win32_Process.Create return codes
  [NamingStyle(nsSnakeCase, 'Process_')]
  TWmiWin32ProcessCreateStatus = (
    Process_STATUS_SUCCESS = 0,
    Process_STATUS_NOT_SUPPORTED = 1,
    Process_STATUS_ACCESS_DENIED = 2,
    Process_STATUS_INSUFFICIENT_PRIVILEGE = 3,
    Process_STATUS_UNKNOWN_FAILURE = 8,
    Process_STATUS_PATH_NOT_FOUND = 9,
    Process_STATUS_INVALID_PARAMETER = 21
  );

const
  APTTYPE_CURRENT = TAptType(-1);

// SDK::oleauto.h
[Result: ReleaseWith('SysFreeString')]
function SysAllocString(
  [in, opt] Buffer: PWideChar
): PWideChar; stdcall; external oleaut32;

// SDK::oleauto.h
procedure SysAddRefString(
  [in, opt] Buffer: PWideChar
); stdcall; external oleaut32;

// SDK::oleauto.h
procedure SysReleaseString(
  [in, opt] Buffer: PWideChar
); stdcall; external oleaut32;

// SDK::oleauto.h
procedure SysFreeString(
  [in, opt] Buffer: PWideChar
); stdcall; external oleaut32;

// SDK::oleauto.h
[Result: NumberOfElements]
function SysStringLen(
  [in, opt] Buffer: PWideChar
): Cardinal; stdcall; external oleaut32;

// SDK::oleauto.h
procedure VariantInit(
  [in, out] var V: TVarData
); stdcall; external oleaut32;

// SDK::oleauto.h
function VariantClear(
  [in, out] var V: TVarData
): HResult; stdcall; external oleaut32;

// SDK::oleauto.h
function VariantCopy(
  [in, out] var Dest: TVarData;
  [in] const Source: TVarData
): HResult; stdcall; external oleaut32;

// SDK::oleauto.h
function VariantCopyInd(
  [in, out] var Dest: TVarData;
  [in] const Source: TVarData
): HResult; stdcall; external oleaut32;

// SDK::combaseapi.h
[Result: ReleaseWith('CoTaskMemFree')]
function CoTaskMemAlloc(
  [in, NumberOfBytes] cb: NativeUInt
): Pointer; stdcall; external ole32;

// SDK::combaseapi.h
[Result: MayReturnNil]
function CoTaskMemRealloc(
  [in, opt] pv: Pointer;
  [in, NumberOfBytes] cb: NativeUInt
): Pointer; stdcall; external ole32;

// SDK::combaseapi.h
procedure CoTaskMemFree(
  [in, opt] pv: Pointer
); stdcall; external ole32;

// SDK::combaseapi.h
function CoGetCurrentProcess(
): Cardinal; stdcall; external ole32;

// SDK::combaseapi.h
procedure CoUninitialize(
); stdcall; external ole32;

// SDK::combaseapi.h
[Result: ReleaseWith('CoUninitialize')]
function CoInitializeEx(
  [Reserved] pvReserved: Pointer;
  [in] coInit: TCoInitMode
): HResult; stdcall; external ole32;

// SDK::combaseapi.h
function CoGetApartmentType(
  [out] out AptType: TAptType;
  [out] out AptQualifier: TAptTypeQualifier
): HResult; stdcall external ole32;

// SDK::combaseapi.h
[MinOSVersion(OsWin8)]
function CoDecrementMTAUsage(
  [in] Cookie: TCoMtaUsageCookie
): HResult; stdcall external ole32 delayed;

var delayed_CoDecrementMTAUsage: TDelayedLoadFunction = (
  Dll: @delayed_ole32;
  FunctionName: 'CoDecrementMTAUsage';
);

// SDK::combaseapi.h
[MinOSVersion(OsWin8)]
function CoIncrementMTAUsage(
  [out, ReleaseWith('CoDecrementMTAUsage')] out Cookie: TCoMtaUsageCookie
): HResult; stdcall external ole32 delayed;

var delayed_CoIncrementMTAUsage: TDelayedLoadFunction = (
  Dll: @delayed_ole32;
  FunctionName: 'CoIncrementMTAUsage';
);

// SDK::combaseapi.h
[RequiresCOM]
function CoCreateInstance(
  [in] const Clsid: TClsid;
  [in, opt] unkOuter: IUnknown;
  [in] ClsContext: TClsCtx;
  [in] const iid: TIID;
  [out] out pv
): HResult; stdcall; external ole32;

// SDK::combaseapi.h
[RequiresCOM]
function CoGetClassObject(
  [in] const Clsid: TClsid;
  [in] ClsContext: TClsCtx;
  [in, opt] ComputerName: Pointer;
  [in] const iid: TIID;
  [out] out pv
): HResult; stdcall; external ole32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
