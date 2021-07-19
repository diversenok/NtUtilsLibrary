unit NtUtils.Console;

{
  This module includes some functions that can help buiding console applications
}

interface

uses
  DelphiApi.Reflection;

type
  [NamingStyle(nsCamelCase, 'ch')]
  TConsoleHostState = (
    chUnknown,
    chNone,
    chInterited,
    chCreated
  );

{ Input }

var
  // Use the command-line parameters instead of user input
  PreferParametersOverConsoleIO: Boolean = True;

// Read a string input from the console
function ReadString(AllowEmpty: Boolean = True): String;

// Read a boolean choice from the console
function ReadBoolean: Boolean;

// Read an unsigned integer from the console
function ReadCardinal(
  MinValue: Cardinal = 0;
  MaxValue: Cardinal = $FFFFFF
): Cardinal;

{ Console Host }

// Determine whether the current process inherited or created the console
function RtlxConsoleHostState: TConsoleHostState;

implementation

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils, NtUtils.SysUtils, NtUtils.Processes,
  NtUtils.Processes.Info;

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
  while not RtlxStrToInt(ReadString(False), Result) or (Result > MaxValue) or
    (Result < MinValue) do
  begin
    write(RETRY_MSG);
    PreferParametersOverConsoleIO := False; // Failed to parse, need user interaction
  end;
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

end.
