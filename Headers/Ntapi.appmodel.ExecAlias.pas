unit Ntapi.appmodel.ExecAlias;

{
  This module provides definitions for working with app execution aliases.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.ntdef, Ntapi.ntseapi, Ntapi.ntioapi, Ntapi.ObjBase, Ntapi.Versions,
  DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  AppExecAliasHost = 'ApiSetHost.AppExecutionAlias.dll';

  TOKEN_LOAD_ALIAS = TOKEN_QUERY or TOKEN_DUPLICATE or TOKEN_IMPERSONATE or
    TOKEN_ADJUST_DEFAULT;

var
  delayed_AppExecAliasHost: TDelayedLoadDll = (DllName: AppExecAliasHost);

type
  TAppExecAliasData = record end;
  PAppExecAliasData = ^TAppExecAliasData;

  // rev
  [SDKName('AppExecutionAliasType')]
  [NamingStyle(nsCamelCase, 'AppExecAlias')]
  TAppExecutionAliasType = (
    AppExecAliasDesktop = 0,
    AppExecAliasUWPSingleInstance = 1,
    AppExecAliasUWPMultiInstance = 2,
    AppExecAliasUWPConsole = 3
  );

  // private
  [SDKName('APPEXECUTIONALIASINFO')]
  TAppExecutionAliasInfo = record
    PackageFullName: PWideChar;
    ApplicationPath: PWideChar;
    ActivationToken: THandle;
  end;
  PAppExecutionAliasInfo = ^TAppExecutionAliasInfo;

// rev
[MinOSVersion(OsWin10RS3)]
procedure FreeAppExecutionAliasInfoEx(
  [in] ExecutionAliasInfo: PAppExecutionAliasInfo
); stdcall external AppExecAliasHost delayed;

var delayed_FreeAppExecutionAliasInfoEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'FreeAppExecutionAliasInfoEx';
);

// rev
[MinOSVersion(OsWin10RS3)]
function LoadAppExecutionAliasInfoEx(
  [in] ApplicationPath: PWideChar;
  [in, opt, Access(TOKEN_LOAD_ALIAS)] hIncomingToken: THandle;
  [out, ReleaseWith('FreeAppExecutionAliasInfoEx')] out ExecutionAliasInfo:
    PAppExecutionAliasInfo
): NTSTATUS; stdcall external AppExecAliasHost delayed;

var delayed_LoadAppExecutionAliasInfoEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'LoadAppExecutionAliasInfoEx';
);

// rev
[MinOSVersion(OsWin10RS3)]
procedure CloseAppExecutionAliasEx(
  [in] Alias: PAppExecAliasData
); stdcall external AppExecAliasHost delayed;

var delayed_CloseAppExecutionAliasEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'CloseAppExecutionAliasEx';
);

// rev
[MinOSVersion(OsWin10RS3)]
function OpenAppExecutionAliasForUserEx(
  [in] Path: PWideChar;
  [in, opt, Access(TOKEN_QUERY)] Token: THandle;
  [out, ReleaseWith('CloseAppExecutionAliasEx')] out Alias: PAppExecAliasData
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_OpenAppExecutionAliasForUserEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'OpenAppExecutionAliasForUserEx';
);

// rev
[MinOSVersion(OsWin10RS4)]
function CreateAppExecutionAliasEx2(
  [in] PackageFamilyName: PWideChar;
  [in] ApplicationUserModelId: PWideChar;
  [in] PackageRelativeExecutable: PWideChar;
  [in] AliasType: TAppExecutionAliasType;
  [out, ReleaseWith('CloseAppExecutionAliasEx')] out Alias: PAppExecAliasData
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_CreateAppExecutionAliasEx2: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'CreateAppExecutionAliasEx2';
);

// rev
[MinOSVersion(OsWin10RS3)]
function PersistAppExecutionAliasToFileEx(
  [in] Alias: PAppExecAliasData;
  [in] Path: PWideChar
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_PersistAppExecutionAliasToFileEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'PersistAppExecutionAliasToFileEx';
);

// rev
[MinOSVersion(OsWin1019H2)]
function PersistAppExecutionAliasToFileHandleEx(
  [in] Alias: PAppExecAliasData;
  [in, Access(FILE_WRITE_DATA or FILE_WRITE_ATTRIBUTES)] FileHandle: THandle
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_PersistAppExecutionAliasToFileHandleEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'PersistAppExecutionAliasToFileHandleEx';
);

// rev
[MinOSVersion(OsWin11)]
function CreateAndPersistAppExecutionAliasEx(
  [in] PackageFamilyName: PWideChar;
  [in] ApplicationUserModelId: PWideChar;
  [in] PackageRelativeExecutable: PWideChar;
  [in] AliasType: TAppExecutionAliasType;
  [in] FileName: PWideChar
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_CreateAndPersistAppExecutionAliasEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'CreateAndPersistAppExecutionAliasEx';
);

// rev
[MinOSVersion(OsWin10RS3)]
function GetAppExecutionAliasExecutableEx(
  [in] Alias: PAppExecAliasData;
  [out, WritesTo] Executable: PWideChar;
  [in, out, NumberOfElements] var PathCch: Cardinal
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_GetAppExecutionAliasExecutableEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'GetAppExecutionAliasExecutableEx';
);

// rev
[MinOSVersion(OsWin10RS3)]
function GetAppExecutionAliasApplicationUserModelIdEx(
  [in] Alias: PAppExecAliasData;
  [out, WritesTo] Aumid: PWideChar;
  [in, out, NumberOfElements] var PathCch: Cardinal
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_GetAppExecutionAliasApplicationUserModelIdEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'GetAppExecutionAliasApplicationUserModelIdEx';
);
// rev
[RequiresCOM]
[MinOSVersion(OsWin10RS3)]
function GetAppExecutionAliasPackageFullNameEx(
  [in] Alias: PAppExecAliasData;
  [out, WritesTo] PackageFullName: PWideChar;
  [in, out, NumberOfElements] var PathCch: Cardinal
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_GetAppExecutionAliasPackageFullNameEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'GetAppExecutionAliasPackageFullNameEx';
);

// rev
[MinOSVersion(OsWin10RS3)]
function GetAppExecutionAliasPackageFamilyNameEx(
  [in] Alias: PAppExecAliasData;
  [out, WritesTo] PackageFamilyName: PWideChar;
  [in, out, NumberOfElements] var PathCch: Cardinal
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_GetAppExecutionAliasPackageFamilyNameEx: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'GetAppExecutionAliasPackageFamilyNameEx';
);

// rev
[MinOSVersion(OsWin10RS4)]
function GetAppExecutionAliasApplicationType(
  [in] Alias: PAppExecAliasData;
  [out] out AliasType: TAppExecutionAliasType
): HResult; stdcall external AppExecAliasHost delayed;

var delayed_GetAppExecutionAliasApplicationType: TDelayedLoadFunction = (
  Dll: @delayed_AppExecAliasHost;
  FunctionName: 'GetAppExecutionAliasApplicationType';
);

implementation

end.
