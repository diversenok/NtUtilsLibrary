unit Ntapi.winrt;

{
  This module provides definitions for interoperating with Windows Runtime
  (WinRT) functions.
}

interface

{$MINENUMSIZE 4}
{$WARN SYMBOL_PLATFORM OFF}

uses
  Ntapi.WinNt, Ntapi.ObjBase, Ntapi.Versions, DelphiApi.Reflection,
  DelphiApi.DelayLoad;

const
  // private - WinRT string flags
  WRHF_NONE = $00000000;
  WRHF_STRING_REFERENCE = $00000001;
  WRHF_VALID_UNICODE_FORMAT_INFO = $00000002;
  WRHF_WELL_FORMED_UNICODE = $00000004;
  WRHF_HAS_EMBEDDED_NULLS = $00000008;
  WRHF_EMBEDDED_NULLS_COMPUTED = $00000010;
  WRHF_RESERVED_FOR_PREALLOCATED_STRING_BUFFER = $80000000;

type
  [SDKName('WINDOWS_RUNTIME_HSTRING_FLAGS')]
  [FlagName(WRHF_STRING_REFERENCE, 'String Reference')]
  [FlagName(WRHF_VALID_UNICODE_FORMAT_INFO, 'Valid Unicode Format Info')]
  [FlagName(WRHF_WELL_FORMED_UNICODE, 'Well-formed Unicode')]
  [FlagName(WRHF_HAS_EMBEDDED_NULLS, 'Has Embedded Nulls')]
  [FlagName(WRHF_EMBEDDED_NULLS_COMPUTED, 'Embedded Nulls Computed')]
  [FlagName(WRHF_RESERVED_FOR_PREALLOCATED_STRING_BUFFER, 'Reserved for Preallocated String Buffer')]
  TWindowsRuntimeHStringFlags = type Cardinal;

  // private
  [SDKName('HSTRING_HEADER_INTERNAL')]
  THStringHeader = record
    Flags: TWindowsRuntimeHStringFlags;
    Length: Cardinal;
    [Unlisted] Padding1: Cardinal;
    [Unlisted] Padding2: Cardinal;
    StringRef: PWideChar;
  end;
  PHStringHeader = ^THStringHeader;

  THStringInstance = record
    Header: THStringHeader;
    [volatile] ReferenceCount: Integer;
    Data: TAnysizeArray<WideChar>
  end;
  PHStringInstance = ^THStringInstance;
  THString = PHStringInstance;

  // Annotation for components requiring WinRT to be initialized
  RequiresWinRTAttribute = class (TCustomAttribute)
  end;

  // SDK::roapi.h
  [SDKName('RO_INIT_TYPE')]
  [NamingStyle(nsSnakeCase, 'RO_INIT')]
  TRoInitType = (
      RO_INIT_SINGLETHREADED = 0,
      RO_INIT_MULTITHREADED = 1
  );

  // SDK::inspectable.h
  [SDKName('TrustLevel')]
  [NamingStyle(nsCamelCase)]
  TRoTrustLevel = (
    BaseTrust = 0,
    PartialTrust = 1,
    FullTrust = 2
  );

  // SDK::inspectable.h
  IInspectable = interface (IUnknown)
    ['{AF86E2E0-B12D-4c6a-9C5A-D7AA65101E90}']

    function GetIids(
      [out] out iidCount: Cardinal;
      [out, ReleaseWith('CoTaskMemFree')] out iids: PGuid
    ): HResult; stdcall;

    function GetRuntimeClassName(
      [out, ReleaseWith('WindowsDeleteString')] out ClassName: THString
    ): HResult; stdcall;

    function GetTrustLevel(
      [out] out Trust: TRoTrustLevel
    ): HResult; stdcall;
  end;

  // SDK::activation.h
  IActivationFactory = interface (IInspectable)
    ['{00000035-0000-0000-C000-000000000046}']
    function ActivateInstance(
      [out] out instance: IInspectable
    ): HResult; stdcall;
  end;

  // RegisterActivationFactory/DllGetActivationFactory callback
  [SDKName('PFNGETACTIVATIONFACTORY')]
  TDllGetActivationFactory = function (
    [in] activatableClassId: THString;
    [out] out factory: IActivationFactory
  ): HResult; stdcall;

  // SDK::windows.foundation.collections.h
  [SDKName('Windows.Foundation.Collections.IIterator')]
  IIterator<T> = interface(IInspectable)
    function get_Current(
      [out] out current: T
    ): HResult; stdcall;

    function get_HasCurrent(
      [out] out hasCurrent: Boolean
    ): HResult; stdcall;

    function MoveNext(
      [out] out hasCurrent: Boolean
    ): HResult; stdcall;

    function GetMany(
      [in, NumberOfElements] capacity: Cardinal;
      [out, WritesTo] items: Pointer;
      [out] actual: PCardinal
    ): HResult; stdcall;
  end;

  // SDK::windows.foundation.collections.h
  [SDKName('Windows.Foundation.Collections.IIterable')]
  IIterable<T> = interface(IInspectable)
    function First(
      [out] out first: IIterator<T>
    ): HResult; safecall;
  end;

  // SDK::windows.foundation.collections.h
  [SDKName('Windows.Foundation.Collections.IVectorView')]
  IVectorView<T> = interface
    function GetAt(
      [in] index: Cardinal;
      [out] out item: T
    ): HResult; stdcall;

    function get_Size(
      [out] out size: Cardinal
    ): HResult; stdcall;

    function IndexOf(
      [in, opt] const [ref] value: T;
      [out] index: Cardinal;
      [out] found: LongBool
    ): HResult; stdcall;

    function GetMany(
      [in] startIndex: Cardinal;
      [in] capacity: Cardinal;
      [out, WritesTo] value: Pointer;
      [out] actual: Cardinal
    ): HResult; stdcall;
  end;

// SDK::winstring.h
[MinOSVersion(OsWin8)]
function WindowsDeleteString(
  [in, opt] Str: THString
): HResult; stdcall; external combase delayed;

var delayed_WindowsDeleteString: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'WindowsDeleteString';
);

// SDK::winstring.h
[MinOSVersion(OsWin8)]
function WindowsCreateString(
  [in, opt, ReadsFrom] SourceString: PWideChar;
  [in, NumberOfElements] Length: Cardinal;
  [out, MayReturnNil, ReleaseWith('WindowsDeleteString')] out Str: THString
): HResult; stdcall; external combase delayed;

var delayed_WindowsCreateString: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'WindowsCreateString';
);

// SDK::winstring.h
[MinOSVersion(OsWin8)]
function WindowsCreateStringReference(
  [in, opt, ReadsFrom] SourceString: PWideChar;
  [in, NumberOfElements] Length: Cardinal;
  [out] out StringHeader: THStringHeader;
  [out, MayReturnNil] Str: THString
): HResult; stdcall; external combase delayed;

var delayed_WindowsCreateStringReference: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'WindowsCreateStringReference';
);

// SDK::winstring.h
[MinOSVersion(OsWin8)]
[Result: NumberOfElements]
function WindowsGetStringLen(
  [in, opt] Str: THString
): Cardinal; stdcall; external combase delayed;

var delayed_WindowsGetStringLen: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'WindowsGetStringLen';
);

// SDK::winstring.h
[MinOSVersion(OsWin8)]
function WindowsGetStringRawBuffer(
  [in, opt] Str: THString;
  [out, opt, NumberOfElements] Length: PCardinal
): PWideChar; stdcall; external combase delayed;

var delayed_WindowsGetStringRawBuffer: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'WindowsGetStringRawBuffer';
);

// SDK::winstring.h
[MinOSVersion(OsWin8)]
function WindowsIsStringEmpty(
  [in, opt] Str: THString
): LongBool; stdcall; external combase delayed;

var delayed_WindowsIsStringEmpty: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'WindowsIsStringEmpty';
);

// SDK::winstring.h
[MinOSVersion(OsWin8)]
function WindowsStringHasEmbeddedNull(
  [in, opt] Str: THString;
  [out] out HasEmbedNull: LongBool
): HResult; stdcall; external combase delayed;

var delayed_WindowsStringHasEmbeddedNull: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'WindowsStringHasEmbeddedNull';
);

// SDK::roapi.h
[MinOSVersion(OsWin8)]
[Result: ReleaseWith('RoUninitialize')]
function RoInitialize(
  [in] InitType: TRoInitType
): HResult; stdcall; external combase delayed;

var delayed_RoInitialize: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'RoInitialize';
);

// SDK::roapi.h
[MinOSVersion(OsWin8)]
procedure RoUninitialize(
); stdcall; external combase delayed;

var delayed_RoUninitialize: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'RoUninitialize';
);

// SDK::roapi.h
[MinOSVersion(OsWin8)]
function RoGetActivationFactory(
  [in] activatableClassId: THString;
  [in] const iid: TIid;
  [out] out factory
): HResult; stdcall; external combase delayed;

var delayed_RoGetActivationFactory: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'RoGetActivationFactory';
);

// SDK::roapi.h
[RequiresWinRT]
[MinOSVersion(OsWin8)]
function RoActivateInstance(
  [in] ActivatableClassId: THString;
  [out] out Instance: IInspectable
): HResult; stdcall; external combase delayed;

var delayed_RoActivateInstance: TDelayedLoadFunction = (
  Dll: @delayed_combase;
  FunctionName: 'RoActivateInstance';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
