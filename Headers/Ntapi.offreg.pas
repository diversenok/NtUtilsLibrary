unit Ntapi.offreg;

{
  This module defines offline registry support functions.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntregapi, Ntapi.ntioapi, Ntapi.Versions,
  DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  offreg = 'offreg.dll';

var
  delayed_offreg: TDelayedLoadDll = (DllName: offreg);

type
  TORHandle = type THandle;

  TORHandleArray = TAnysizeArray<TORHandle>;
  PORHandleArray = ^TORHandleArray;

{ Hives }

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORCloseHive(
  [in] HiveHandle: TORHandle
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORCloseHive: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORCloseHive';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORCreateHive(
  [out, ReleaseWith('ORCloseHive')] out HiveHandle: TORHandle
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORCreateHive: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORCreateHive';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function OROpenHive(
  [in, Access(FILE_READ_DATA)] FilePath: PWideChar;
  [out, ReleaseWith('ORCloseHive')] out HiveHandle: TORHandle
): TWin32Error; stdcall; external offreg delayed;

var delayed_OROpenHive: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'OROpenHive';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function OROpenHiveByHandle(
  [in, Access(FILE_READ_DATA)] FileHandle: THandle;
  [out, ReleaseWith('ORCloseHive')] out HiveHandle: TORHandle
): TWin32Error; stdcall; external offreg delayed;

var delayed_OROpenHiveByHandle: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'OROpenHiveByHandle';
);

// WDK::offreg.h
[MinOSVersion(OsWin1020H1)]
function ORMergeHives (
  [in, ReadsFrom] HiveHandles: PORHandleArray;
  [in, NumberOfElements] HiveCount: Cardinal;
  [out, ReleaseWith('ORCloseHive')] out ResultHiveHandle: TORHandle
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORMergeHives: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORMergeHives';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORSaveHive(
  [in] HiveHandle: TORHandle;
  [in, Access(FILE_WRITE_DATA)] FilePath: PWideChar;
  [in] OsMajor: Cardinal;
  [in] OsMinor: Cardinal
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORSaveHive: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORSaveHive';
);

{ Keys }

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORCloseKey(
  [in] KeyHandle: TORHandle
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORCloseKey: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORCloseKey';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORCreateKey(
  [in] ParentHandle: TORHandle;
  [in] SubKeyName: PWideChar;
  [in, opt] ClassName: PWideChar;
  [in] Options: TRegOpenOptions;
  [in, opt] SecurityDescriptor: PSecurityDescriptor;
  [out, ReleaseWith('ORCloseKey')] out KeyHandle: TORHandle;
  [out, opt] Disposition: PRegDisposition
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORCreateKey: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORCreateKey';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function OROpenKey(
  [in] ParentHandle: TORHandle;
  [in, opt] SubKeyName: PWideChar;
  [out, ReleaseWith('ORCloseKey')] out SubkeyHandle: TORHandle
): TWin32Error; stdcall; external offreg delayed;

var delayed_OROpenKey: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'OROpenKey';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function OREnumKey(
  [in] Handle: TORHandle;
  [in] Index: Cardinal;
  [out, WritesTo] Name: PWideChar;
  [in, out, NumberOfElements] var NameCount: Cardinal;
  [out, opt, WritesTo] ClassName: PWideChar;
  [in, out, opt, NumberOfElements] ClassNameCount: PCardinal;
  [out, opt] LastWriteTime: PLargeInteger
): TWin32Error; stdcall; external offreg delayed;

var delayed_OREnumKey: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'OREnumKey';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORQueryInfoKey(
  [in] Handle: TORHandle;
  [out, opt, WritesTo] ClassName: PWideChar;
  [in, out, opt, NumberOfElements] ClassNameCount: PCardinal;
  [out, opt] SubKeys: PCardinal;
  [out, opt] MaxSubKeyLen: PCardinal;
  [out, opt] MaxClassLen: PCardinal;
  [out, opt] Values: PCardinal;
  [out, opt] MaxValueNameLen: PCardinal;
  [out, opt, Bytes] MaxValueLen: PCardinal;
  [out, opt, Bytes] SecurityDescriptor: PCardinal;
  [out, opt] LastWriteTime: PLargeInteger
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORQueryInfoKey: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORQueryInfoKey';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORGetVirtualFlags(
  [in] KeyHandle: TORHandle;
  [out] out Flags: TKeyControlFlags
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORGetVirtualFlags: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORGetVirtualFlags';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORSetVirtualFlags(
  [in] KeyHandle: TORHandle;
  [in] Flags: TKeyControlFlags
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORSetVirtualFlags: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORSetVirtualFlags';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORGetKeySecurity(
  [in] KeyHandle: TORHandle;
  [in] SecurityInformation: TSecurityInformation;
  [out, WritesTo] Buffer: PSecurityDescriptor;
  [in, out, NumberOfBytes] var BufferSize: Cardinal
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORGetKeySecurity: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORGetKeySecurity';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORSetKeySecurity(
  [in] KeyHandle: TORHandle;
  [in] SecurityInformation: TSecurityInformation;
  [in] Buffer: PSecurityDescriptor
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORSetKeySecurity: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORSetKeySecurity';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORDeleteKey(
  [in] KeyHandle: TORHandle;
  [in, opt] KeyName: PWideChar
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORDeleteKey: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORDeleteKey';
);

// WDK::offreg.h
[MinOSVersion(OsWin10RS2)]
function ORRenameKey(
  [in] KeyHandle: TORHandle;
  [in] KeyName: PWideChar
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORRenameKey: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORRenameKey';
);

{ Values }

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function OREnumValue(
  [in] KeyHandle: TORHandle;
  [in] Index: Cardinal;
  [out, WritesTo] ValueName: PWideChar;
  [in, out, NumberOfElements] var ValueNameCount: Cardinal;
  [out] out ValueType: TRegValueType;
  [out, opt, WritesTo] DataBuffer: Pointer;
  [in, out, opt] DataBufferSize: PCardinal
): TWin32Error; stdcall; external offreg delayed;

var delayed_OREnumValue: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'OREnumValue';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORGetValue(
  [in] KeyHandle: TORHandle;
  [in, opt] SubKey: PWideChar;
  [in, opt] ValueName: PWideChar;
  [out, opt] out ValueType: TRegValueType;
  [out, opt, WritesTo] DataBuffer: Pointer;
  [in, out, opt, NumberOfBytes] DataBufferSize: PCardinal
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORGetValue: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORGetValue';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORSetValue(
  [in] KeyHandle: TORHandle;
  [in, opt] ValueName: PWideChar;
  [in] ValueType: TRegValueType;
  [in, ReadsFrom] Data: Pointer;
  [in, NumberOfBytes] DataSize: Cardinal
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORSetValue: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORSetValue';
);

// WDK::offreg.h
[MinOSVersion(OsWin81)]
function ORDeleteValue(
  [in] KeyHandle: TORHandle;
  [in, opt] ValueName: PWideChar
): TWin32Error; stdcall; external offreg delayed;

var delayed_ORDeleteValue: TDelayedLoadFunction = (
  Dll: @delayed_offreg;
  FunctionName: 'ORDeleteValue';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
