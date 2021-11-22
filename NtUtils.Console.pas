unit NtUtils.Console;

{
  This module includes some functions that can help buiding console applications
}

interface

uses
  NtUtils, DelphiApi.Reflection;

type
  [NamingStyle(nsCamelCase, 'ch')]
  TConsoleHostState = (
    chUnknown,
    chNone,
    chInterited,
    chCreated
  );

  [NamingStyle(nsCamelCase, 'cc')]
  TConsoleColor = (
    ccBlack,
    ccDarkBlue,
    ccDarkGreen,
    ccDarkCyan,
    ccDarkRed,
    ccDarkMagenta,
    ccDarkYellow,
    ccGray,
    ccDarkGray,
    ccBlue,
    ccGreen,
    ccCyan,
    ccRed,
    ccMagenta,
    ccYellow,
    ccWhite,
    ccUnchanged
  );

var
  // Allow using command-line parameters instead of user input
  PreferParametersOverConsoleIO: Boolean = True;

  // Do not immediately close the console if the app was invoked from GUI
  UseSmartCloseOnExit: Boolean = True;

// Read a string input from the console
function ReadString(AllowEmpty: Boolean = True): String;

// Read a boolean choice from the console
function ReadBoolean: Boolean;

// Read an unsigned integer from the console
function ReadCardinal(
  MinValue: Cardinal = 0;
  MaxValue: Cardinal = Cardinal(-1)
): Cardinal;

// Change console output color and revert it back later
function RtlxSetConsoleColor(
  Foreground: TConsoleColor;
  Background: TConsoleColor = ccUnchanged
): IAutoReleasable;

// Determine whether the current process inherited or created the console
function RtlxConsoleHostState: TConsoleHostState;

implementation

uses
  Ntapi.WinNt, Ntapi.ntpsapi, Ntapi.ConsoleApi, NtUtils.SysUtils,
  NtUtils.Processes, NtUtils.Processes.Info;

const
  RETRY_MSG = 'Invalid input; try again: ';

{ Input }

var
  OverrideIndex: Integer = 1;

function ReadString;
begin
  // Apply I/O override
  if PreferParametersOverConsoleIO then
  begin
    Result := ParamStr(OverrideIndex);
    Inc(OverrideIndex);

    if Result <> '' then
    begin
      writeln(Result);
      Exit;
    end
    else
      PreferParametersOverConsoleIO := False;
  end;

  repeat
    readln(Result);

    if not AllowEmpty and (Result = '') then
      write(RETRY_MSG)
    else
      Break;
  until False;
end;

function ReadBoolean;
begin
  Result := RtlxCompareStrings(ReadString, 'y') = 0;
end;

function ReadCardinal;
begin
  while not RtlxStrToUInt(ReadString(False), Result) or (Result > MaxValue) or
    (Result < MinValue) do
  begin
    write(RETRY_MSG);
    PreferParametersOverConsoleIO := False; // Failed to parse, need user interaction
  end;
end;

{ Output }

function RtlxSetConsoleColor;
var
  Info: TConsoleScreenBufferInfo;
  hConsole: THandle;
  NewAttributes: Word;
begin
  if (Foreground = ccUnchanged) and (Background = ccUnchanged) then
    Exit(nil);

  hConsole := GetStdHandle(STD_OUTPUT_HANDLE);

  if hConsole = INVALID_HANDLE_VALUE then
    Exit(nil);

  if not GetConsoleScreenBufferInfo(hConsole, Info) then
    Exit(nil);

  NewAttributes := Info.Attributes;

  if Foreground <> ccUnchanged then
    NewAttributes := (NewAttributes and $FFF0) or (Word(Foreground) and $F);

  if Background <> ccUnchanged then
    NewAttributes := (NewAttributes and $FF0F) or
      ((Word(Background) and $F) shl 4);

  if not SetConsoleTextAttribute(hConsole, NewAttributes) then
    Exit(nil);

  Result := Auto.Delay(
    procedure
    var
      hConsole: THandle;
    begin
      hConsole := GetStdHandle(STD_OUTPUT_HANDLE);

      if hConsole <> INVALID_HANDLE_VALUE then
        SetConsoleTextAttribute(hConsole, Info.Attributes);
    end
  );
end;

{ Console Host }

function RtlxConsoleHostState;
var
  PID: TProcessId;
  hxProcess: IHandle;
  ConhostInfo, OurInfo: TKernelUserTimes;
begin
  Result := chUnknown;

  // Determine conhost's PID
  if not NtxProcess.Query(NtCurrentProcess, ProcessConsoleHostProcess, PID)
    .IsSuccess then
    Exit;

  if PID = 0 then
    Exit(chNone);

  // Query its and our creation time
  if NtxOpenProcess(hxProcess, PID, PROCESS_QUERY_LIMITED_INFORMATION).IsSuccess
    and NtxProcess.Query(hxProcess.Handle, ProcessTimes, ConhostInfo).IsSuccess
    and NtxProcess.Query(NtCurrentProcess, ProcessTimes, OurInfo).IsSuccess then
  begin
    // Compare them
    if ConhostInfo.CreateTime > OurInfo.CreateTime then
      Result := chCreated
    else
      Result := chInterited;
  end;
end;

initialization

finalization
  {$IFDEF Console}
    if UseSmartCloseOnExit and (RtlxConsoleHostState = chCreated) then
    begin
      write(#$D#$A'Press enter to exit...');
      readln;
    end;
  {$ENDIF}
end.
