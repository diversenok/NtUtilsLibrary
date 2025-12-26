unit Ntapi.ConsoleApi;

{
  This file contains declarations for using in console applications.
}

interface

{$MINENUMSIZE 4}
{$WARN SYMBOL_PLATFORM OFF}

uses
  Ntapi.WinNt, DelphiApi.Reflection, Ntapi.WinUser, DelphiApi.DelayLoad,
  Ntapi.Versions;

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

  // Special flag for AttachConsole
  ATTACH_PARENT_PROCESS = TProcessId32(-1);

  // rev - driver paths and sub-paths
  CONDRV_DRIVER_PATH = '\Device\ConDrv';
  CONDRV_SERVER_NAME = '\Server';
  CONDRV_REFERENCE_NAME = '\Reference';
  CONDRV_CONNECT_NAME = '\Connect';
  CONDRV_INPUT_NAME = '\Input';
  CONDRV_OUTPUT_NAME = '\Output';

  // rev - command line template for new conhost instances
  CONDRV_SERVER_LAUNCH_APPLICATION = '\??\C:\Windows\system32\conhost.exe';
  CONDRV_SERVER_LAUNCH_ARGUMENTS = ' 0xffffffff -ForceV1';

  // rev - extended attributes for connection handles
  CONDRV_SERVER_EA_NAME = 'server'; // in: TConsoleServerMsg
  CONDRV_ATTACH_EA_NAME = 'attach'; // in: TCdAttachInformation

  // rev - IOCTLs
  IOCTL_CONDRV_CONNECTION_QUERY_SERVER_PID = $500023; // q: TProcessId
  IOCTL_CONDRV_SERVER_LAUNCH = $500037; // s: TRtlUserProcessParameters

type
  [FlagName(FOREGROUND_BLUE, 'Foreground Blue')]
  [FlagName(FOREGROUND_GREEN, 'Foreground Green')]
  [FlagName(FOREGROUND_RED, 'Foreground Red')]
  [FlagName(FOREGROUND_INTENSITY, 'Foreground Intensity')]
  [FlagName(BACKGROUND_BLUE, 'Background Blue')]
  [FlagName(BACKGROUND_GREEN, 'Background Green')]
  [FlagName(BACKGROUND_RED, 'Background Red')]
  [FlagName(BACKGROUND_INTENSITY, 'Background Intensity')]
  TConsoleFill32 = type Cardinal;

  [InheritsFrom(System.TypeInfo(TConsoleFill32))]
  TConsoleFill16 = type Word;

  // SDK::WinBase.h
  [NamingStyle(nsSnakeCase, 'STD')]
  TStdHandle = (
    STD_INPUT_HANDLE = -10,
    STD_OUTPUT_HANDLE = -11,
    STD_ERROR_HANDLE = -12
  );

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
  THandlerRoutine = function (
    [in] CtrlType: TCtrlEvent
  ): LongBool; stdcall;

  // SDK::wincontypes.h
  [SDKName('COORD')]
  TCoord = record
    X: Int16;
    Y: Int16;
  end;

  // SDK::wincontypes.h
  [SDKName('SMALL_RECT')]
  TSmallRect = record
    Left: Int16;
    Top: Int16;
    Right: Int16;
    Bottom: Int16;
  end;

  // SDK::consoleapi2.h
  [SDKName('CONSOLE_SCREEN_BUFFER_INFO')]
  TConsoleScreenBufferInfo = record
    Size: TCoord;
    CursorPosition: TCoord;
    Attributes: Word;
    Window: TSmallRect;
    MaximumWindowSize: TCoord;
  end;

  // private
  [SDKName('CONSOLE_SERVER_MSG')]
  TConsoleServerMsg = record
    IconId: Cardinal;
    HotKey: Cardinal;
    StartupFlags: Cardinal;
    FillAttribute: TConsoleFill16;
    ShowWindow: TShowMode16;
    ScreenBufferSize: TCoord;
    WindowSize: TCoord;
    WindowOrigin: TCoord;
    ProcessGroupId: Cardinal;
    ConsoleApp: Boolean;
    WindowVisible: Boolean;
    TitleLength: Word;
    Title: array [0..260] of WideChar;
    ApplicationNameLength: Word;
    ApplicationName: array [0..127] of WideChar;
    CurrentDirectoryLength: Word;
    CurrentDirectory: array [0..260] of WideChar;
  end;
  PConsoleServerMsg = ^TConsoleServerMsg;

  // private
  [SDKName('CD_ATTACH_INFORMATION')]
  TCdAttachInformation = record
    ProcessId: TProcessId;
  end;
  PCdAttachInformation = ^TCdAttachInformation;

// SDK::processenv.h
[SetsLastError]
function GetStdHandle(
  [in] StdHandle: TStdHandle
): THandle; stdcall; external kernel32;

// SDK::consoleapi.h
[SetsLastError]
[Result: ReleaseWith('FreeConsole')]
function AllocConsole(
): LongBool; stdcall; external kernel32;

// SDK::consoleapi.h
[SetsLastError]
function FreeConsole(
): LongBool; stdcall; external kernel32;

// SDK::consoleapi.h
[SetsLastError]
function AttachConsole(
  [in] ProcessId: TProcessId32
): LongBool; stdcall; external kernel32;

// SDK::consoleapi.h
[SetsLastError]
function SetConsoleCtrlHandler(
  [in] HandlerRoutine: THandlerRoutine;
  [in] Add: LongBool
): LongBool; stdcall; external kernel32;

// SDK::consoleapi2.h
[SetsLastError]
function GetConsoleScreenBufferInfo(
  [in] hConsoleOutput: THandle;
  [out] out ConsoleScreenBufferInfo: TConsoleScreenBufferInfo
): LongBool; stdcall; external kernel32;

// SDK::consoleapi2.h
[SetsLastError]
function SetConsoleTextAttribute(
  [in] hConsoleOutput: THandle;
  [in] Attributes: Word
): LongBool; stdcall; external kernel32;

// SDK::consoleapi3.h
[SetsLastError]
function GetConsoleWindow(
): THwnd; stdcall; external kernel32;

// SDK::consoleapi3.h
[SetsLastError]
[Result: NumberOfElements]
function GetConsoleProcessList(
  [out] ProcessList: PProcessId32;
  [in, NumberOfElements] ProcessCount: Integer
): Integer; stdcall; external kernel32;

// rev
[MinOSVersion(OsWin10RS3)]
function BaseGetConsoleReference(
): THandle; stdcall; external kernelbase delayed;

var delayed_BaseGetConsoleReference: TDelayedLoadFunction = (
  Dll: @delayed_kernelbase;
  FunctionName: 'BaseGetConsoleReference';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
