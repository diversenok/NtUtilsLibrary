unit Winapi.Shell;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinUser, DelphiApi.Reflection;

const
  shell32 = 'shell32.dll';
  wdc = 'wdc.dll';

  // shellapi.384
  SEE_MASK_DEFAULT = $00000000;
  SEE_MASK_NOCLOSEPROCESS = $00000040;
  SEE_MASK_NOASYNC = $00000100;
  SEE_MASK_FLAG_NO_UI = $00000400;
  SEE_MASK_UNICODE = $000004000;
  SEE_MASK_NO_CONSOLE = $00008000;
  SEE_MASK_NOZONECHECKS = $00800000;

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

  // shellapi.469
  TShellExecuteInfoW = record
    [Bytes, Unlisted] cbSize: Cardinal;
    Mask: TShellExecuteMask;
    [opt] Wnd: HWND;
    [opt] Verb: PWideChar;
    FileName: PWideChar;
    [opt] Parameters: PWideChar;
    [opt] Directory: PWideChar;
    nShow: Integer;
    [out] hInstApp: HINST;
    [opt] IDList: Pointer;
    [opt] &Class: PWideChar;
    [opt] hKeyClass: THandle;
    [opt] HotKey: Cardinal;
    [opt] hMonitor: THandle;
    [out] hProcess: THandle;
  end;

  [FlagName(SECL_NO_UI, 'No UI')]
  [FlagName(SECL_LOG_USAGE, 'Log Usage')]
  [FlagName(SECL_USE_IDLIST, 'Use IDList')]
  [FlagName(SECL_ALLOW_NONEXE, 'Allow Non-Exe')]
  [FlagName(SECL_RUNAS, 'Run As')]
  TSeclFlags = type Cardinal;

// shellapi.236
function ExtractIconExW(
  [in] FileName: PWideChar;
  IconIndex: Integer;
  [out, opt] phIconLarge: PHICON;
  [out, opt] phIconSmall: PHICON;
  Icons: Cardinal
): Cardinal; stdcall; external shell32;

// shellapi.502
function ShellExecuteExW(
  var ExecInfo: TShellExecuteInfoW
): LongBool; stdcall; external shell32;

function ShellExecCmdLine(
  hwnd: HWND;
  [in] CommandLine: PWideChar;
  [in, opt] StartDir: PWideChar;
  Show: Integer;
  [Reserved] Unused: Pointer;
  SeclFlags: TSeclFlags
): HRESULT; stdcall; external shell32 index 265;

{ WDC }

function WdcRunTaskAsInteractiveUser(
  [in] CommandLine: PWideChar;
  [in, opt] CurrentDirectory: PWideChar;
  SeclFlags: TSeclFlags
): HResult; stdcall; external wdc delayed;

implementation

end.
