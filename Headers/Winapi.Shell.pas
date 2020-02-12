unit Winapi.Shell;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinUser, DelphiApi.Reflection;

const
  shell32 = 'shell32.dll';

  SEE_MASK_DEFAULT = $00000000;
  SEE_MASK_NOCLOSEPROCESS = $00000040;
  SEE_MASK_NOASYNC = $00000100;
  SEE_MASK_FLAG_NO_UI = $00000400;
  SEE_MASK_UNICODE = $000004000;
  SEE_MASK_NO_CONSOLE = $00008000;
  SEE_MASK_NOZONECHECKS = $00800000;

type
  TShellExecuteInfoW = record
    [Bytes, Unlisted] cbSize: Cardinal;
    [Hex] fMask: Cardinal;
    Wnd: HWND;
    Verb: PWideChar;
    FileName: PWideChar;
    Parameters: PWideChar;
    Directory: PWideChar;
    nShow: Integer;
    hInstApp: HINST;
    IDList: Pointer;
    lpClass: PWideChar;
    hkeyClass: THandle;
    HotKey: Cardinal;
    hMonitor: THandle;
    hProcess: THandle;
  end;

function ShellExecuteExW(var ExecInfo: TShellExecuteInfoW): LongBool; stdcall;
  external shell32;

function ExtractIconExW(FileName: PWideChar; IconIndex: Integer;
  var hIconLarge, hIconSmall: HICON; Icons: Cardinal): Cardinal; stdcall;
  external shell32;

implementation

end.
