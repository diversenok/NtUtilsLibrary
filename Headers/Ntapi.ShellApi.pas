unit Ntapi.ShellApi;

{
  This module includes some definitions for Shell API functions.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinUser, DelphiApi.Reflection;

const
  shell32 = 'shell32.dll';
  wdc = 'wdc.dll';

  // SDK::shellapi.h
  SEE_MASK_DEFAULT = $00000000;
  SEE_MASK_NOCLOSEPROCESS = $00000040;
  SEE_MASK_NOASYNC = $00000100;
  SEE_MASK_FLAG_NO_UI = $00000400;
  SEE_MASK_UNICODE = $000004000;
  SEE_MASK_NO_CONSOLE = $00008000;
  SEE_MASK_NOZONECHECKS = $00800000;

  // ReactOs::undocshell.h
  SECL_NO_UI = $02;
  SECL_LOG_USAGE = $08;
  SECL_USE_IDLIST = $10;
  SECL_ALLOW_NONEXE = $20;
  SECL_RUNAS = $40;

type
  [FlagName(SEE_MASK_NOCLOSEPROCESS, 'Don''t Close Process')]
  [FlagName(SEE_MASK_NOASYNC, 'No Async')]
  [FlagName(SEE_MASK_FLAG_NO_UI, 'No UI')]
  [FlagName(SEE_MASK_UNICODE, 'Unicode')]
  [FlagName(SEE_MASK_NO_CONSOLE, 'No Console')]
  [FlagName(SEE_MASK_NOZONECHECKS, 'No Zone Checks')]
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
    [out] hInstApp: HINST;
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

{ WDC }

// rev
function WdcRunTaskAsInteractiveUser(
  [in] CommandLine: PWideChar;
  [in, opt] CurrentDirectory: PWideChar;
  [in] SeclFlags: TSeclFlags
): HResult; stdcall; external wdc delayed;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
