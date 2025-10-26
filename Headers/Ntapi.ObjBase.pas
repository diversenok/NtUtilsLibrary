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

  // SDK::rpcdce.h - authentication services
  RPC_C_AUTHN_NONE = 0;
  RPC_C_AUTHN_WINNT = 10;
  RPC_C_AUTHN_DEFAULT = $FFFFFFFF;

  // SDK::rpcdce.h - authorization services
  RPC_C_AUTHZ_NONE = 0;
  RPC_C_AUTHZ_DEFAULT = $FFFFFFFF;

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

  // SDK::oaidl.h - safe array features
  FADF_AUTO = $0001;
  FADF_STATIC = $0002;
  FADF_EMBEDDED = $0004;
  FADF_FIXEDSIZE = $0010;
  FADF_RECORD = $0020;
  FADF_HAVEIID = $0040;
  FADF_HAVEVARTYPE = $0080;
  FADF_BSTR = $0100;
  FADF_UNKNOWN = $0200;
  FADF_DISPATCH = $0400;
  FADF_VARIANT = $0800;

  // SDK::coguid.h
  GUID_NULL: TGuid = '{00000000-0000-0000-0000-000000000000}';

  // private
  CLSID_ComActivator: TGuid = '{0000033C-0000-0000-C000-000000000046}';

  // SDK::combaseapi.h
  COM_RIGHTS_EXECUTE = $0001;
  COM_RIGHTS_EXECUTE_LOCAL = $0002;
  COM_RIGHTS_EXECUTE_REMOTE = $0004;
  COM_RIGHTS_ACTIVATE_LOCAL = $0008;
  COM_RIGHTS_ACTIVATE_REMOTE = $0010;

  COM_RIGHTS_GENERIC_READ = 0;
  COM_RIGHTS_GENERIC_WRITE = 0;
  COM_RIGHTS_GENERIC_EXECUTE = $007F;

  // private
  MTA_HOST_USAGE_MTAINITIALIZED = $1;
  MTA_HOST_USAGE_ACTIVATORINITIALIZED = $2;
  MTA_HOST_USAGE_UNLOADCALLED = $4;

type
  // SDK::wtypes.h
  {$MINENUMSIZE 2}
  [SDKName('VARENUM')]
  [NamingStyle(nsSnakeCase, 'VT'), ValidValues([0..14, 16..27])]
  TVarEnum = (
    VT_EMPTY = 0,
    VT_NULL = 1,
    VT_I2 = 2,
    VT_I4 = 3,
    VT_R4 = 4,
    VT_R8 = 5,
    VT_CY = 6,
    VT_DATE = 7,
    VT_BSTR = 8,
    VT_DISPATCH = 9,
    VT_ERROR = 10,
    VT_BOOL = 11,
    VT_VARIANT = 12,
    VT_UNKNOWN = 13,
    VT_DECIMAL = 14,
    [Reserved] VT_15 = 15,
    VT_I1 = 16,
    VT_UI1 = 17,
    VT_UI2 = 18,
    VT_UI4 = 19,
    VT_I8 = 20,
    VT_UI8 = 21,
    VT_INT = 22,
    VT_UINT = 23,
    VT_VOID = 24,
    VT_HRESULT = 25,
    VT_PTR = 26,
    VT_SAFEARRAY = 27
  );
  {$MINENUMSIZE 4}

const
  // SDK::wtypes.h
  VT_ARRAY = TVarEnum($2000);
  VT_BYREF = TVarEnum($4000);

  // Custom Delphi variants types
  VT_PASCAL_STRING = TVarEnum($100);
  VT_PASCAL_UNICODE_STRING = TVarEnum($102);

type
  TIid = TGuid;
  TClsid = TGuid;
  PClsid = ^TClsid;
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

  // SDK::rpcdce.h
  [NamingStyle(nsSnakeCase, 'SEC_WINNT_AUTH_IDENTITY'), MinValue(1)]
  TCoAuthIdentityFlags = (
    [Reserved] SEC_WINNT_AUTH_IDENTITY_UNUSED = 0,
    SEC_WINNT_AUTH_IDENTITY_ANSI = 1,
    SEC_WINNT_AUTH_IDENTITY_UNICODE = 2
  );

  // SDK::WTypesbase.h
  [SDKName('COAUTHIDENTITY')]
  TCoAuthIdentity = record
    User: PWideChar;
    [NumberOfElements] UserLength: Cardinal;
    Domain: PWideChar;
    [NumberOfElements] DomainLength: Cardinal;
    Password: PWideChar;
    [NumberOfElements] PasswordLength: Cardinal;
    Flags: TCoAuthIdentityFlags;
  end;
  PCoAuthIdentity = ^TCoAuthIdentity;

  [SubEnum(MAX_UINT, RPC_C_AUTHN_NONE, 'None')]
  [SubEnum(MAX_UINT, RPC_C_AUTHN_WINNT, 'WinNT')]
  [SubEnum(MAX_UINT, RPC_C_AUTHN_DEFAULT, 'Default')]
  TRpcAuthnService = type Cardinal;

  [SubEnum(MAX_UINT, RPC_C_AUTHZ_NONE, 'None')]
  [SubEnum(MAX_UINT, RPC_C_AUTHZ_DEFAULT, 'Default')]
  TRpcAuthzService = type Cardinal;

  // SDK::rpcdce.h
  [NamingStyle(nsSnakeCase, 'RPC_C_AUTHN_LEVEL')]
  TRpcAuthnLevel = (
    RPC_C_AUTHN_LEVEL_DEFAULT = 0,
    RPC_C_AUTHN_LEVEL_NONE = 1,
    RPC_C_AUTHN_LEVEL_CONNECT = 2,
    RPC_C_AUTHN_LEVEL_CALL = 3,
    RPC_C_AUTHN_LEVEL_PKT = 4,
    RPC_C_AUTHN_LEVEL_PKT_INTEGRITY = 5,
    RPC_C_AUTHN_LEVEL_PKT_PRIVACY = 6
  );

  // SDK::rpcdce.h
  [NamingStyle(nsSnakeCase, 'RPC_C_IMP')]
  TRpcImpLevel = (
    RPC_C_IMP_LEVEL_DEFAULT = 0,
    RPC_C_IMP_LEVEL_ANONYMOUS = 1,
    RPC_C_IMP_LEVEL_IDENTIFY = 2,
    RPC_C_IMP_LEVEL_IMPERSONATE = 3,
    RPC_C_IMP_LEVEL_DELEGATE = 4
  );

  // SDK::WTypesbase.h
  [SDKName('COAUTHINFO')]
  TCoAuthInfo = record
    AuthnSvc: TRpcAuthnService;
    AuthzSvc: TRpcAuthzService;
    ServerPrincName: PWideChar;
    AuthnLevel: TRpcAuthnLevel;
    ImpersonationLevel: TRpcImpLevel;
    AuthIdentityData: PCoAuthIdentity;
    [Hex] Capabilities: Cardinal;
  end;
  PCoAuthInfo = ^TCoAuthInfo;

  // SDK::objidlbase.h
  [SDKName('COSERVERINFO')]
  TCoServerInfo = record
    [Reserved] Reserved1: Cardinal;
    Name: PWideChar;
    AuthInfo: PCoAuthInfo;
    [Reserved] Reserved2: Cardinal;
  end;
  PCoServerInfo = ^TCoServerInfo;

  // SDK::objidl.h
  [SDKName('MULTI_QI')]
  TMultiQI = record
    [in] IID: TIid;
    [out] Itf: IUnknown;
    [out] hr: HResult;
  end;
  PMultiQI = ^TMultiQI;

  // private
  IStandardActivator = interface (IUnknown)
    ['{000001B8-0000-0000-C000-000000000046}']
    function StandardGetClassObject(
      [in] const clsid: TClsid;
      [in] ClsCtx: TClsCtx;
      [in, opt] ServerInfo: PCoServerInfo;
      [in] const iid: TIid;
      [out] out ppv
    ): HResult; stdcall;

    function StandardCreateInstance(
      [in] const clsid: TClsid;
      [in, opt] const unkOuter: IUnknown;
      [in] ClsCtx: TClsCtx;
      [in, opt] ServerInfo: PCoServerInfo;
      [in, NumberOfElements] Count: Integer;
      [in, out] Results: PMultiQI
    ): HResult; stdcall;

    function StandardGetInstanceFromFile(
      [in, opt] ServerInfo: PCoServerInfo;
      [in, opt] clsidOverride: PClsid;
      [in, opt] const unkOuter: IUnknown;
      [in] ClsCtx: TClsCtx;
      [in] Mode: Cardinal; // Ntapi.ObjIdl.TStgm
      [in] Name: PWideChar;
      [in, NumberOfElements] Count: Integer;
      [in, out] Results: PMultiQI
    ): HResult; stdcall;

    function StandardGetInstanceFromIStorage(
      [in, opt] ServerInfo: PCoServerInfo;
      [in, opt] clsidOverride: PClsid;
      [in, opt] const unkOuter: IUnknown;
      [in] ClsCtx: TClsCtx;
      [in] const pstg: IUnknown; // IStorage
      [in, NumberOfElements] Count: Integer;
      [in, out] Results: PMultiQI
    ): HResult; stdcall;

    function Reset(
    ): HResult; stdcall;
  end;

  // private
  [SDKName('PRT')]
  [NamingStyle(nsSnakeCase, 'PRT')]
  TProcessRequestType = (
    PRT_IGNORE = 0,
    PRT_CREATE_NEW = 1,
    PRT_USE_THIS = 2,
    PRT_USE_THIS_ONLY = 3
  );

  // private
  [SDKName('RUNLEVEL')]
  [NamingStyle(nsSnakeCase, 'RUNLEVEL')]
  TRunLevel = (
    RUNLEVEL_LUA = 0,
    RUNLEVEL_HIGHEST = 1,
    RUNLEVEL_ADMIN = 2,
    RUNLEVEL_MAX_NON_UIA = 3,
    RUNLEVEL_LUA_UIA = $10,
    RUNLEVEL_HIGHEST_UIA = $11,
    RUNLEVEL_ADMIN_UIA = $12,
    RUNLEVEL_MAX = $13
  );

  // private
  ISpecialSystemProperties = interface (IUnknown)
    ['{000001B9-0000-0000-C000-000000000046}']
    function SetSessionId(
      [in] SessionId: TSessionId;
      [in] UseConsole: LongBool;
      [in] RemoteThisSessionId: LongBool
    ): HResult; stdcall;

    function GetSessionId(
      [out] out SessionId: TSessionId;
      [out] out UseConsole: LongBool
    ): HResult; stdcall;

    function GetSessionId2(
      [out] out SessionId: TSessionId;
      [out] out UseConsole: LongBool;
      [out] out RemoteThisSessionId: LongBool
    ): HResult; stdcall;

    function SetClientImpersonating(
      [in] ClientImpersonating: LongBool
    ): HResult; stdcall;

    function GetClientImpersonating(
      [out] out ClientImpersonating: LongBool
    ): HResult; stdcall;

    function SetPartitionId(
      [in] const guidPartiton: TGuid
    ): HResult; stdcall;

    function GetPartitionId(
      [out] out guidPartiton: TGuid
    ): HResult; stdcall;

    function SetProcessRequestType(
      [in] PRT: TProcessRequestType
    ): HResult; stdcall;

    function GetProcessRequestType(
      [out] out PRT: TProcessRequestType
    ): HResult; stdcall;

    function SetOrigClsctx(
      [in] ClsCtx: TClsCtx
    ): HResult; stdcall;

    function GetOrigClsctx(
      [out] out ClsCtx: TClsCtx
    ): HResult; stdcall;

    function GetDefaultAuthenticationLevel(
      [out] out AuthnLevel: TRpcAuthnLevel
    ): HResult; stdcall;

    function SetDefaultAuthenticationLevel(
      [in] AuthnLevel: TRpcAuthnLevel
    ): HResult; stdcall;

    function GetLUARunLevel(
      [out] out LUARunLevel: TRunLevel;
      [out] out wnd: THwnd
    ): HResult; stdcall;

    function SetLUARunLevel(
      [in] LUARunLevel: TRunLevel;
      [in] wnd: THwnd
    ): HResult; stdcall;

    function FlagQuery(
      [in] FlagToQuery: Cardinal
    ): HResult; stdcall;

    function FlagSet(
      [in] FlagToSet: Cardinal
    ): HResult; stdcall;

    function FlagClear(
      [in] FlagToClear: Cardinal
    ): HResult; stdcall;

    [MinOSVersion(OsWin8)]
    function SetServiceId(
      [in] ServiceId: Cardinal
    ): HResult; stdcall;

    [MinOSVersion(OsWin8)]
    function GetServiceId(
      [out] out ServiceId: Cardinal
    ): HResult; stdcall;
  end;

  [FriendlyName('COM')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  [FlagName(COM_RIGHTS_EXECUTE, 'Execute')]
  [FlagName(COM_RIGHTS_EXECUTE_LOCAL, 'Execute Local')]
  [FlagName(COM_RIGHTS_EXECUTE_REMOTE, 'Execute Remote')]
  [FlagName(COM_RIGHTS_ACTIVATE_LOCAL, 'Activate Local')]
  [FlagName(COM_RIGHTS_ACTIVATE_REMOTE, 'Activate Remote')]
  TComAccessMask = type TAccessMask;

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

  [FlagName(FADF_AUTO, 'Auto')]
  [FlagName(FADF_STATIC, 'Static')]
  [FlagName(FADF_EMBEDDED, 'Embedded')]
  [FlagName(FADF_FIXEDSIZE, 'Fixed Size')]
  [FlagName(FADF_RECORD, 'Record')]
  [FlagName(FADF_HAVEIID, 'Has IID')]
  [FlagName(FADF_HAVEVARTYPE, 'Has Variant')]
  [FlagName(FADF_BSTR, 'BSTR Array')]
  [FlagName(FADF_UNKNOWN, 'IUnknown Array')]
  [FlagName(FADF_DISPATCH, 'IDispatch Array')]
  [FlagName(FADF_VARIANT, 'Variant Array')]
  TSafeArrayFeatures = type Word;

  // SDK::oaidl.h
  [SDKName('SAFEARRAYBOUND')]
  TSafeArrayBound = record
    Elements: Cardinal;
    Lbound: Integer;
  end;
  PSafeArrayBound = ^TSafeArrayBound;

  // SDK::oaidl.h
  [SDKName('SAFEARRAY')]
  TSafeArray = record
    Dims: Word;
    Features: TSafeArrayFeatures;
    [Bytes] Elements: Cardinal;
    Locks: Cardinal;
    Data: Pointer;
    Bound: TAnysizeArray<TSafeArrayBound>;
  end;
  PSafeArray = ^TSafeArray;

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

  // SDK::objbase.h
  [SDKName('COMSD')]
  TComSD = (
    SD_LAUNCHPERMISSIONS = 0,
    SD_ACCESSPERMISSIONS = 1,
    SD_LAUNCHRESTRICTIONS = 2,
    SD_ACCESSRESTRICTIONS = 3
  );

  // private
  [SDKName('MTA_HOST_USAGE_FLAGS')]
  [FlagName(MTA_HOST_USAGE_MTAINITIALIZED, 'MTA Initialized')]
  [FlagName(MTA_HOST_USAGE_ACTIVATORINITIALIZED, 'Activator Initialized')]
  [FlagName(MTA_HOST_USAGE_UNLOADCALLED, 'Unload Called')]
  TMtaHostUsageFlags = type Cardinal;
  PMtaHostUsageFlags = ^TMtaHostUsageFlags;

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('MTA_USAGE_GLOBALS')]
  TMtaUsageGlobals = record
    [Reserved] dwStackCapture: Cardinal;
    p_cMTAInits: PCardinal;
    p_cMTAIncInits: PCardinal;
    p_cMTAWaiters: PCardinal;
    p_cMTAIncrementorSize: PCardinal;
    dwCompletionTimeOut: Cardinal;
    [Reserved] ListEntryHeadMTAUsageIncrementor: PListEntry;
    [Reserved] p_posMTAIncrementorCompleted: PCardinal;
    [Reserved] ppMTAUsageCompletedIncrementorHead: Pointer;
    [MinOSVersion(OsWin10TH1)] p_fMTAHostUsageFlags: PMtaHostUsageFlags;
  end;
  PMtaUsageGlobals = ^TMtaUsageGlobals;

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
): Pointer; stdcall; external oleaut32;

// SDK::oleauto.h
[Result: ReleaseWith('SysFreeString')]
function SysAllocStringLen(
  [in, ReadsFrom] Buffer: PWideChar;
  [in, NumberOfElements] Length: Cardinal
): Pointer; stdcall; external oleaut32;

// SDK::oleauto.h
procedure SysAddRefString(
  [in, opt] Buffer: WideString
); stdcall; external oleaut32;

// SDK::oleauto.h
procedure SysReleaseString(
  [in, opt] Buffer: WideString
); stdcall; external oleaut32;

// SDK::oleauto.h
procedure SysFreeString(
  [in, opt] Buffer: WideString
); stdcall; external oleaut32;

// SDK::oleauto.h
[Result: NumberOfElements]
function SysStringLen(
  [in, opt] Buffer: WideString
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

// private
[MinOSVersion(OsWin8)]
[Result: MayReturnNil, ReleaseWith('CoTaskMemFree')] // release since TH2 only
function CoGetMTAUsageInfo(
): PMtaUsageGlobals; stdcall external combase index 70 delayed;

var delayed_CoGetMTAUsageInfo: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: MAKEINTRESOURCEA(70);
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

// SDK::objbase.h
function CoGetSystemSecurityPermissions(
  [in] ComSDType: TComSD;
  [out, ReleaseWith('LocalFree')] out SD: PSecurityDescriptor
): HResult; stdcall; external ole32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
