unit Ntapi.ShellApi;

{
  This module includes some definitions for Shell API functions.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ProcessThreadsApi, Ntapi.WinUser, DelphiApi.Reflection,
  Ntapi.ntioapi, DelphiApi.DelayLoad;

const
  shell32 = 'shell32.dll';
  wdc = 'wdc.dll';
  cmutil = 'cmutil.dll';

var
  delayed_shell32: TDelayedLoadDll = (DllName: shell32);
  delayed_wdc: TDelayedLoadDll = (DllName: wdc);
  delayed_cmutil: TDelayedLoadDll = (DllName: cmutil);

const
  // SDK::shellapi.h
  SEE_MASK_DEFAULT = $00000000;
  SEE_MASK_NOCLOSEPROCESS = $00000040;
  SEE_MASK_NOASYNC = $00000100;
  SEE_MASK_FLAG_NO_UI = $00000400;
  SEE_MASK_UNICODE = $000004000;
  SEE_MASK_NO_CONSOLE = $00008000;
  SEE_MASK_NOZONECHECKS = $00800000;
  SEE_MASK_FLAG_HINST_IS_SITE = $08000000;

  // ReactOs::undocshell.h
  SECL_NO_UI = $02;
  SECL_LOG_USAGE = $08;
  SECL_USE_IDLIST = $10;
  SECL_ALLOW_NONEXE = $20;
  SECL_RUNAS = $40;

  // SDK::ShObjIdl_core.h - service ID for ICreatingProcess
  SID_ExecuteCreatingProcess: TGuid = '{C2B937A9-3110-4398-8A56-F34C6342D244}';

  // private
  CLSID_CmstpLua: TGuid = '{3E5FC7F9-9A51-4367-9063-A120244FBEC7}';
  CLSID_CMLuaUtil: TGuid = '{3E000D72-A845-4CD9-BD83-80C07C3B881F}';
  CLSID_HxHelpPaneServer: TGuid = '{8CEC58AE-07A1-11D9-B15E-000D56BFE6EE}';

type
  [FlagName(SEE_MASK_NOCLOSEPROCESS, 'Don''t Close Process')]
  [FlagName(SEE_MASK_NOASYNC, 'No Async')]
  [FlagName(SEE_MASK_FLAG_NO_UI, 'No UI')]
  [FlagName(SEE_MASK_UNICODE, 'Unicode')]
  [FlagName(SEE_MASK_NO_CONSOLE, 'No Console')]
  [FlagName(SEE_MASK_NOZONECHECKS, 'No Zone Checks')]
  [FlagName(SEE_MASK_FLAG_HINST_IS_SITE, 'HInst Is Site')]
  TShellExecuteMask = type Cardinal;

  // SDK::shellapi.h
  [SDKName('SHELLEXECUTEINFOW')]
  TShellExecuteInfoW = record
    [in, RecordSize] cbSize: Cardinal;
    [in] Mask: TShellExecuteMask;
    [in, opt] Wnd: THwnd;
    [in, opt] Verb: PWideChar;
    [in] FileName: PWideChar;
    [in, opt] Parameters: PWideChar;
    [in, opt] Directory: PWideChar;
    [in] Show: TShowMode32;
    [in, out, opt] hInstApp: HINST; // can also be IServiceProvider
    [in, opt] IDList: Pointer;
    [in, opt] &Class: PWideChar;
    [in, opt] hKeyClass: THandle;
    [in, opt] HotKey: Cardinal;
    [in, opt] hMonitor: THandle;
    [out, ReleaseWith('NtClose')] hProcess: THandle;
  end;

  [FlagName(SECL_NO_UI, 'No UI')]
  [FlagName(SECL_LOG_USAGE, 'Log Usage')]
  [FlagName(SECL_USE_IDLIST, 'Use IDList')]
  [FlagName(SECL_ALLOW_NONEXE, 'Allow Non-Exe')]
  [FlagName(SECL_RUNAS, 'Run As')]
  TSeclFlags = type Cardinal;

  // SDK::ShObjIdl_core.h
  ICreateProcessInputs = interface(IUnknown)
    ['{F6EF6140-E26F-4D82-BAC4-E9BA5FD239A8}']
    function GetCreateFlags(
      [out] out CreationFlags: TProcessCreateFlags
    ): HResult; stdcall;

    function SetCreateFlags(
      [in] CreationFlags: TProcessCreateFlags
    ): HResult; stdcall;

    function AddCreateFlags(
      [in] CreationFlags: TProcessCreateFlags
    ): HResult; stdcall;

    function SetHotKey(
      [in] wHotKey: Word
    ): HResult; stdcall;

    function AddStartupFlags(
      [in] StartupInfoFlags: TStartupFlags
    ): HResult; stdcall;

    function SetTitle(
      [in, opt] Title: PWideChar
    ): HResult; stdcall;

    function SetEnvironmentVariable(
        [in] Name: PWideChar;
        [in] Value: PWideChar
    ): HResult; stdcall;
  end;

  // SDK::ShObjIdl_core.h
  ICreatingProcess = interface(IUnknown)
    ['{C2B937A9-3110-4398-8A56-F34C6342D244}']
    function OnCreating(
      [in] const cpi: ICreateProcessInputs
    ): HResult; stdcall;
  end;

  // private
  ICMLuaUtil = interface (IUnknown)
    ['{6EDD6D74-C007-4E75-B76A-E5740995E24C}']

    function SetRasCredentials(
      [in] Phonebook: PWideChar;
      [in] Entry: PWideChar;
      [in] RasCredentials: PWideChar;
      [in] Delete: LongBool
    ): HResult; stdcall;

    function SetRasEntryProperties(
      [in] Phonebook: PWideChar;
      [in] Entry: PWideChar;
      [in] RasEntry: PPWideChar;
      [in] Size: Cardinal
    ): HResult; stdcall;

    function DeleteRasEntry(
      [in] Phonebook: PWideChar;
      [in] Entry: PWideChar
    ): HResult; stdcall;

    function LaunchInfSection(
      [in] InfFile: PWideChar;
      [in] InfSection: PWideChar;
      [in] Title: PWideChar;
      [in] Quiet: LongBool
    ): HResult; stdcall;

    function LaunchInfSectionEx(
      [in] InfFile: PWideChar;
      [in] InfSection: PWideChar;
      [in] Flags: Cardinal
    ): HResult; stdcall;

    function CreateLayerDirectory(
      [in] Path: PWideChar
    ): HResult; stdcall;

    function ShellExec(
      [in] Command: PWideChar;
      [in, opt] Params: PWideChar;
      [in, opt] Directory: PWideChar;
      [in] Mask: TShellExecuteMask;
      [in] Show: TShowMode32
    ): HResult; stdcall;

    function SetRegistryStringValue(
      hBaseKeyHKLM: LongBool;
      [in] KeyPath: PWideChar;
      [in] ValueName: PWideChar;
      [in, opt] ValueData: PWideChar
    ): HResult; stdcall;

    function DeleteRegistryStringValue(
      [in] hBaseKeyHKLM: LongBool;
      [in] KeyPath: PWideChar;
      [in, opt] ValueName: PWideChar
    ): HResult; stdcall;

    function DeleteRegKeysWithoutSubKeys(
      [in] hBaseKeyHKLM: LongBool;
      [in] KeyPath: PWideChar;
      [in] IgnoreValues: LongBool
    ): HResult; stdcall;

    function DeleteRegTree(
      [in] hBaseKeyHKLM: LongBool;
      [in] KeyPath: PWideChar
    ): HResult; stdcall;

    function ExitWindowsFunc(
    ): HResult; stdcall;

    function AllowAccessToTheWorld(
      [in] FilePath: PWideChar
    ): HResult; stdcall;

    function CreateFileAndClose(
      [in] FilePath: PWideChar;
      [in] Access: TFileAccessMask;
      [in] ShareMode: TFileShareMode;
      [in] CreationDisposition: Cardinal;
      [in] FlagsAndAttributes: TFileAttributes
      ): HResult; stdcall;

    function DeleteHiddenCmProfileFiles(
      [in] Profile: PWideChar
    ): HResult; stdcall;

    function CallCustomActionDll(
      [in] ModuleName: PWideChar;
      [in] FunctionName: PWideChar;
      [in, opt] Params: PWideChar;
      [in, opt] hWndDlg: PWideChar;
      [out, opt] CustomActionRetVal: PCardinal
    ): HResult; stdcall;

    function RunCustomActionExe(
      [in] ProgramPath: PWideChar;
      [in, opt] Params: PWideChar;
      [out, ReleaseWith('CmFree')] out hProcess: PWideChar
    ): HResult; stdcall;
  end;

  // private
  IHxHelpPaneServer = interface (IUnknown)
    ['{8CEC592C-07A1-11D9-B15E-000D56BFE6EE}']
    function DisplayTask(
      [in] const Url: WideString
    ): HResult; stdcall;

    function DisplayContents(
      [in] const Url: WideString
    ): HResult; stdcall;

    function DisplaySearchResults(
      [in] const SearchQuery: WideString
    ): HResult; stdcall;

    function Execute(
      [in] const Url: PWideChar
    ): TWin32Error; stdcall;
  end;

// SDK::shellapi.h
[SetsLastError]
[Result: NumberOfElements]
function ExtractIconExW(
  [in] FileName: PWideChar;
  [in] IconIndex: Integer;
  [out, opt] phIconLarge: PHIcon;
  [out, opt] phIconSmall: PHIcon;
  [in, NumberOfElements] Icons: Cardinal
): Cardinal; stdcall; external shell32;

// SDK::shellapi.h
[SetsLastError]
function ShellExecuteExW(
  [in, out, ReleaseWith('NtClose')] var ExecInfo: TShellExecuteInfoW
): LongBool; stdcall; external shell32;

// ReactOs::undocshell.h
function ShellExecCmdLine(
  [in] hwnd: THwnd;
  [in] CommandLine: PWideChar;
  [in, opt] StartDir: PWideChar;
  [in] Show: TShowMode32;
  [Reserved] Unused: Pointer;
  [in] SeclFlags: TSeclFlags
): HRESULT; stdcall; external shell32 index 265;

// SDK::shellapi.h
function SHEvaluateSystemCommandTemplate(
  [in] CmdTemplate: PWideChar;
  [out, ReleaseWith('CoTaskMemFree')] out Application: PWideChar;
  [out, opt, ReleaseWith('CoTaskMemFree')] out CommandLine: PWideChar;
  [out, opt, ReleaseWith('CoTaskMemFree')] out Parameters: PWideChar
): HResult; stdcall external shell32;

{ WDC }

// rev
function WdcRunTaskAsInteractiveUser(
  [in] CommandLine: PWideChar;
  [in, opt] CurrentDirectory: PWideChar;
  [in] SeclFlags: TSeclFlags
): HResult; stdcall; external wdc delayed;

var delayed_WdcRunTaskAsInteractiveUser: TDelayedLoadFunction = (
  Dll: @delayed_wdc;
  FunctionName: 'WdcRunTaskAsInteractiveUser';
);

// private
procedure CmFree(
  [in, opt] Ptr: Pointer
); stdcall; external cmutil delayed;

var delayed_CmFree: TDelayedLoadFunction = (
  Dll: @delayed_cmutil;
  FunctionName: 'CmFree';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
