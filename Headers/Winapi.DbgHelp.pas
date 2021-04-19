unit Winapi.DbgHelp;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

const
  dbghelp = 'dbghelp.dll';

  // 1212
  SYMFLAG_VALUEPRESENT = $00000001;
  SYMFLAG_REGISTER = $00000008;
  SYMFLAG_REGREL = $00000010;
  SYMFLAG_FRAMEREL = $00000020;
  SYMFLAG_PARAMETER = $00000040;
  SYMFLAG_LOCAL = $00000080;
  SYMFLAG_CONSTANT = $00000100;
  SYMFLAG_EXPORT = $00000200;
  SYMFLAG_FORWARDER = $00000400;
  SYMFLAG_FUNCTION = $00000800;
  SYMFLAG_VIRTUAL = $00001000;
  SYMFLAG_THUNK = $00002000;
  SYMFLAG_TLSREL = $00004000;
  SYMFLAG_SLOT = $00008000;
  SYMFLAG_ILREL = $00010000;
  SYMFLAG_METADATA = $00020000;
  SYMFLAG_CLR_TOKEN = $00040000;
  SYMFLAG_NULL = $00080000;
  SYMFLAG_FUNC_NO_RETURN = $00100000;
  SYMFLAG_SYNTHETIC_ZEROBASE = $00200000;
  SYMFLAG_PUBLIC_CODE = $00400000;
  SYMFLAG_REGREL_ALIASINDIR = $00800000;

  // 1689
  SYMOPT_CASE_INSENSITIVE = $00000001;
  SYMOPT_UNDNAME = $00000002;
  SYMOPT_DEFERRED_LOADS = $00000004;
  SYMOPT_NO_CPP = $00000008;
  SYMOPT_LOAD_LINES = $00000010;
  SYMOPT_OMAP_FIND_NEAREST = $00000020;
  SYMOPT_LOAD_ANYTHING = $00000040;
  SYMOPT_IGNORE_CVREC = $00000080;
  SYMOPT_NO_UNQUALIFIED_LOADS = $00000100;
  SYMOPT_FAIL_CRITICAL_ERRORS = $00000200;
  SYMOPT_EXACT_SYMBOLS = $00000400;
  SYMOPT_ALLOW_ABSOLUTE_SYMBOLS = $00000800;
  SYMOPT_IGNORE_NT_SYMPATH = $00001000;
  SYMOPT_INCLUDE_32BIT_MODULES = $00002000;
  SYMOPT_PUBLICS_ONLY = $00004000;
  SYMOPT_NO_PUBLICS = $00008000;
  SYMOPT_AUTO_PUBLICS = $00010000;
  SYMOPT_NO_IMAGE_SEARCH = $00020000;
  SYMOPT_SECURE = $00040000;
  SYMOPT_NO_PROMPTS = $00080000;
  SYMOPT_OVERWRITE = $00100000;
  SYMOPT_IGNORE_IMAGEDIR = $00200000;
  SYMOPT_FLAT_DIRECTORY = $00400000;
  SYMOPT_FAVOR_COMPRESSED = $00800000;
  SYMOPT_ALLOW_ZERO_ADDRESS = $01000000;
  SYMOPT_DISABLE_SYMSRV_AUTODETECT = $02000000;
  SYMOPT_READONLY_CACHE = $04000000;
  SYMOPT_SYMPATH_LAST = $08000000;
  SYMOPT_DISABLE_FAST_SYMBOLS = $10000000;
  SYMOPT_DISABLE_SYMSRV_TIMEOUT = $20000000;
  SYMOPT_DISABLE_SRVSTAR_ON_STARTUP = $40000000;
  SYMOPT_DEBUG = $80000000;

  // 2548
  SLMFLAG_NO_SYMBOLS = $4;

type
  // 524
  TModLoadData = record
    ssize: Cardinal;
    ssig: Cardinal;
    data: Pointer;
    size: Cardinal;
    flags: Cardinal;
  end;
  PModLoadData = ^TModLoadData;

  [FlagName(SYMFLAG_VALUEPRESENT, 'Value Present')]
  [FlagName(SYMFLAG_REGISTER, 'Register')]
  [FlagName(SYMFLAG_REGREL, 'Register-relative')]
  [FlagName(SYMFLAG_FRAMEREL, 'Frame-relative')]
  [FlagName(SYMFLAG_PARAMETER, 'Parameter')]
  [FlagName(SYMFLAG_LOCAL, 'Local')]
  [FlagName(SYMFLAG_CONSTANT, 'Constant')]
  [FlagName(SYMFLAG_EXPORT, 'Export')]
  [FlagName(SYMFLAG_FORWARDER, 'Forwarder')]
  [FlagName(SYMFLAG_FUNCTION, 'Function')]
  [FlagName(SYMFLAG_VIRTUAL, 'Virtual')]
  [FlagName(SYMFLAG_THUNK, 'Thunk')]
  [FlagName(SYMFLAG_TLSREL, 'TLS-relative')]
  [FlagName(SYMFLAG_SLOT, 'Slot')]
  [FlagName(SYMFLAG_ILREL, 'IL-relative')]
  [FlagName(SYMFLAG_METADATA, 'Metadata')]
  [FlagName(SYMFLAG_CLR_TOKEN, 'CLR Token')]
  [FlagName(SYMFLAG_NULL, 'NULL')]
  [FlagName(SYMFLAG_FUNC_NO_RETURN, 'Non-return function')]
  [FlagName(SYMFLAG_SYNTHETIC_ZEROBASE, 'Synthetic Zero-base')]
  [FlagName(SYMFLAG_PUBLIC_CODE, 'Public Code')]
  [FlagName(SYMFLAG_REGREL_ALIASINDIR, 'Register-relative Alias')]
  TSymbolFlags = type Cardinal;

  [FlagName(SYMOPT_CASE_INSENSITIVE, 'Case Insensitive')]
  [FlagName(SYMOPT_UNDNAME, 'Undecorate Name')]
  [FlagName(SYMOPT_DEFERRED_LOADS, 'Deferred Loads')]
  [FlagName(SYMOPT_NO_CPP, 'No C++')]
  [FlagName(SYMOPT_LOAD_LINES, 'Load Lines')]
  [FlagName(SYMOPT_OMAP_FIND_NEAREST, 'Find Nearest')]
  [FlagName(SYMOPT_LOAD_ANYTHING, 'Load Anything')]
  [FlagName(SYMOPT_IGNORE_CVREC, 'Ignore CVRec')]
  [FlagName(SYMOPT_NO_UNQUALIFIED_LOADS, 'No Unqualified Loads')]
  [FlagName(SYMOPT_FAIL_CRITICAL_ERRORS, 'Fail Critical Errors')]
  [FlagName(SYMOPT_EXACT_SYMBOLS, 'Exact Symbols')]
  [FlagName(SYMOPT_ALLOW_ABSOLUTE_SYMBOLS, 'Allow Absolute Sybmols')]
  [FlagName(SYMOPT_IGNORE_NT_SYMPATH, 'Ignore NT Symbol Path')]
  [FlagName(SYMOPT_INCLUDE_32BIT_MODULES, 'Include 32-bit Modules')]
  [FlagName(SYMOPT_PUBLICS_ONLY, 'Publics Only')]
  [FlagName(SYMOPT_NO_PUBLICS, 'No Publics')]
  [FlagName(SYMOPT_AUTO_PUBLICS, 'Auto Publics')]
  [FlagName(SYMOPT_NO_IMAGE_SEARCH, 'No Image Search')]
  [FlagName(SYMOPT_SECURE, 'Secure')]
  [FlagName(SYMOPT_NO_PROMPTS, 'No Prompts')]
  [FlagName(SYMOPT_OVERWRITE, 'Overwrite')]
  [FlagName(SYMOPT_IGNORE_IMAGEDIR, 'Ignore Image Dir')]
  [FlagName(SYMOPT_FLAT_DIRECTORY, 'Flat Directory')]
  [FlagName(SYMOPT_FAVOR_COMPRESSED, 'Favor Compressed')]
  [FlagName(SYMOPT_ALLOW_ZERO_ADDRESS, 'Allow Zero Address')]
  [FlagName(SYMOPT_DISABLE_SYMSRV_AUTODETECT, 'Disable SymSrv Autodetect')]
  [FlagName(SYMOPT_READONLY_CACHE, 'Readonly Cache')]
  [FlagName(SYMOPT_SYMPATH_LAST, 'SymPath Last')]
  [FlagName(SYMOPT_DISABLE_FAST_SYMBOLS, 'Disable Fast Symbols')]
  [FlagName(SYMOPT_DISABLE_SYMSRV_TIMEOUT, 'Disable SymSrv Timeout')]
  [FlagName(SYMOPT_DISABLE_SRVSTAR_ON_STARTUP, 'Disable Server Start on Startup')]
  [FlagName(SYMOPT_DEBUG, 'Debug')]
  TSymbolOptions = type Cardinal;
 
  [FlagName(SLMFLAG_NO_SYMBOLS, 'No Symbols')]
  TSymLoadFlags = type Cardinal;

  // 1161
  {$SCOPEDENUMS ON}
  TSymTagEnum = (
    SymTagNull,
    SymTagExe,
    SymTagCompiland,
    SymTagCompilandDetails,
    SymTagCompilandEnv,
    SymTagFunction,
    SymTagBlock,
    SymTagData,
    SymTagAnnotation,
    SymTagLabel,
    SymTagPublicSymbol,
    SymTagUDT,
    SymTagEnum,
    SymTagFunctionType,
    SymTagPointerType,
    SymTagArrayType,
    SymTagBaseType,
    SymTagTypedef,
    SymTagBaseClass,
    SymTagFriend,
    SymTagFunctionArgType,
    SymTagFuncDebugStart,
    SymTagFuncDebugEnd,
    SymTagUsingNamespace,
    SymTagVTableShape,
    SymTagVTable,
    SymTagCustom,
    SymTagThunk,
    SymTagCustomType,
    SymTagManagedType,
    SymTagDimension,
    SymTagCallSite,
    SymTagInlineSite,
    SymTagBaseInterface,
    SymTagVectorType,
    SymTagMatrixType,
    SymTagHLSLType,
    SymTagCaller,
    SymTagCallee,
    SymTagExport,
    SymTagHeapAllocationSite,
    SymTagCoffGroup,
    SymTagMax
  );
  {$SCOPEDENUMS OFF}

  // 2707
  TSymbolInfoW = record
   [Unlisted, Bytes] SizeOfStruct: Cardinal;
    TypeIndex: Cardinal;
    Reserved: array [0..1] of UInt64;
    Index: Cardinal;
    [Bytes] Size: Cardinal;
    ModBase: Pointer;
    Flags: TSymbolFlags;
    Value: UInt64;
    Address: Pointer;
    Register: Cardinal;
    Scope: Cardinal;
    Tag: TSymTagEnum;
    [Counter(ctElements)] NameLen: Cardinal;
    MaxNameLen: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;

  // 2929
  TSymEnumerateSymbolsCallbackW = function (
    const SymInfo: TSymbolInfoW;
    SymbolSize: Cardinal;
    var UserContext
  ): LongBool; stdcall;

// 1742
function SymSetOptions(
  SymOptions: TSymbolOptions
): TSymbolOptions; stdcall; external dbghelp;

// 1748
function SymGetOptions: TSymbolOptions; stdcall; external dbghelp;

// 1760
function SymCleanup(
  hProcess: THandle
): LongBool; stdcall; external dbghelp;

// 2486
function SymInitializeW(
  hProcess: THandle;
  [in, opt] UserSearchPath: PWideChar;
  fInvadeProcess: LongBool
): LongBool; stdcall; external dbghelp;

// 2571
function SymLoadModuleExW(
  hProcess: THandle;
  [opt] hFile: THandle;
  [in, opt] ImageName: PWideChar;
  [in, opt] ModuleName: PWideChar;
  [in] BaseOfDll: Pointer;
  DllSize: Cardinal;
  [in, opt] Data: PModLoadData;
  Flags: TSymLoadFlags
): Pointer; stdcall; external dbghelp;

// 2590
function SymUnloadModule64(
  hProcess: THandle;
  [in] BaseOfDll: Pointer
): LongBool; stdcall; external dbghelp;

// 2937
function SymEnumSymbolsW(
  hProcess: THandle;
  BaseOfDll: Pointer;
  [in, opt] Mask: PWideChar;
  EnumSymbolsCallback: TSymEnumerateSymbolsCallbackW;
  [in, opt] var UserContext
): LongBool; stdcall; external dbghelp;

implementation

end.
