unit Ntapi.ConsoleApi;

{
  This file contains declarations for using in console applications.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection;

const
  // SDK::consoleapi2.h
  FOREGROUND_BLUE = $0001;
  FOREGROUND_GREEN = $0002;
  FOREGROUND_RED = $0004;
  FOREGROUND_INTENSITY = $0008;
  BACKGROUND_BLUE = $0010;
  BACKGROUND_GREEN = $0020;
  BACKGROUND_RED = $0040;
  BACKGROUND_INTENSITY = $0080;

type
  [FlagName(FOREGROUND_BLUE, 'Foreground Blue')]
  [FlagName(FOREGROUND_GREEN, 'Foreground Green')]
  [FlagName(FOREGROUND_RED, 'Foreground Red')]
  [FlagName(FOREGROUND_INTENSITY, 'Foreground Intensity')]
  [FlagName(BACKGROUND_BLUE, 'Background Blue')]
  [FlagName(BACKGROUND_GREEN, 'Background Green')]
  [FlagName(BACKGROUND_RED, 'Background Red')]
  [FlagName(BACKGROUND_INTENSITY, 'Background Intensity')]
  TConsoleFill = type Cardinal;

  // SDK::consoleapi.h
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

  // SDK::consoleapi.h
  [SDKName('PHANDLER_ROUTINE')]
  THandlerRoutine = function (CtrlType: TCtrlEvent): LongBool; stdcall;

// SDK::consoleapi.h
function AllocConsole: LongBool; stdcall; external kernel32;

// SDK::consoleapi.h
function FreeConsole: LongBool; stdcall; external kernel32;

// SDK::consoleapi.h
function AttachConsole(
  ProcessId: TProcessId32
): LongBool; stdcall; external kernel32;

// SDK::consoleapi.h
function SetConsoleCtrlHandler(
  HandlerRoutine: THandlerRoutine;
  Add: LongBool
): LongBool; stdcall; external kernel32;

implementation

end.
