unit Winapi.ConsoleApi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

type
  [NamingStyle(nsSnakeCase, '', 'EVENT')]
  TCtrlEvent = (
    CTRL_C_EVENT = 0,
    CTRL_BREAK_EVENT = 1,
    CTRL_CLOSE_EVENT = 2,
    CTRL_RESERVED3 = 3,
    CTRL_RESERVED4 = 4,
    CTRL_LOGOFF_EVENT = 5,
    CTRL_SHUTDOWN_EVENT = 6
  );

  THandlerRoutine = function (CtrlType: TCtrlEvent): LongBool; stdcall;

function AllocConsole: LongBool; stdcall; external kernel32;

function FreeConsole: LongBool; stdcall; external kernel32;

function AttachConsole(dwProcessId: Cardinal): LongBool; stdcall;
  external kernel32;

function SetConsoleCtrlHandler(HandlerRoutine: THandlerRoutine;
  Add: LongBool): LongBool; stdcall; external kernel32;

implementation

end.
