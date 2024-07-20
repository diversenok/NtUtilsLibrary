unit NtUiLib.Console;

{
  This module includes functions that help building console applications.
}

interface

uses
  NtUtils, DelphiApi.Reflection;

type
  [NamingStyle(nsCamelCase, 'ch')]
  TConsoleHostState = (
    chUnknown,
    chNone,
    chInherited,
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

  IAutoConsoleColor = interface (IAutoReleasable)
    ['{4D298AF8-60A5-4500-B7B0-1219E8EF0264}']
    // Public
    function GetForeground: TConsoleColor;
    function GetBackground: TConsoleColor;
    function GetLayerId: NativeUInt;
    property Foreground: TConsoleColor read GetForeground;
    property Background: TConsoleColor read GetBackground;
    property LayerId: NativeUInt read GetLayerId;
  end;

var
  // Allow using command-line parameters instead of user input
  PreferParametersOverConsoleIO: Boolean = True;

  // Do not immediately close the console if the app was invoked from GUI
  UseSmartCloseOnExit: Boolean = True;

  RETRY_MSG: String = 'Invalid input; try again: ';

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
): IAutoConsoleColor;

// Determine whether the current process inherited or created the console
function RtlxConsoleHostState: TConsoleHostState;

implementation

uses
  Ntapi.WinNt, Ntapi.ntpsapi, Ntapi.ConsoleApi, Ntapi.ntpebteb,
  NtUtils.SysUtils, NtUtils.Processes, NtUtils.Processes.Info,
  DelphiUtils.AutoObjects, DelphiUtils.AutoEvents;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Input }

var
  OverrideIndex: Integer = 1;

function ReadString;
begin
  // Apply I/O override
  if PreferParametersOverConsoleIO then
  begin
    Result := RtlxParamStr(OverrideIndex);
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

// Change console output color
function RtlxSetConsoleColorInternal(
  Foreground: TConsoleColor;
  Background: TConsoleColor;
  [out, opt] PreviousAttributes: PWord = nil
): TNtxStatus;
var
  Info: TConsoleScreenBufferInfo;
  NewAttributes: Word;
begin
  if (Foreground = ccUnchanged) and (Background = ccUnchanged) then
    Exit(NtxSuccess);

  Result.Location := 'GetConsoleScreenBufferInfo';
  Result.Win32Result := GetConsoleScreenBufferInfo(
    RtlGetCurrentPeb.ProcessParameters.StandardOutput, Info);

  if not Result.IsSuccess then
    Exit;

  NewAttributes := Info.Attributes;

  if Foreground <> ccUnchanged then
    NewAttributes := (NewAttributes and $FFF0) or (Word(Foreground) and $F);

  if Background <> ccUnchanged then
    NewAttributes := (NewAttributes and $FF0F) or
      ((Word(Background) and $F) shl 4);

  Result.Location := 'SetConsoleTextAttribute';
  Result.Win32Result := SetConsoleTextAttribute(
    RtlGetCurrentPeb.ProcessParameters.StandardOutput, NewAttributes);

  if not Result.IsSuccess then
    Exit;

  if Assigned(PreviousAttributes) then
    PreviousAttributes^ := Info.Attributes;
end;

type
  TAutoConsoleColor = class (TCustomAutoReleasable, IAutoConsoleColor)
  private
    FForeground: TConsoleColor;
    FBackground: TConsoleColor;
    FLayerId: NativeUInt;
    FApplied: Boolean;
    class var CurrentLayerId: NativeUInt;
    class var InitialStateCaptured: Boolean;
    class var InitialForeground: TConsoleColor;
    class var InitialBackground: TConsoleColor;
    class var ColorStack: TWeakArray<IAutoConsoleColor>;
    procedure Release; override;
    constructor Create(Foreground, Background: TConsoleColor);
  public
    function GetForeground: TConsoleColor;
    function GetBackground: TConsoleColor;
    function GetLayerId: NativeUInt;
    class function Apply(Foreground, Background: TConsoleColor):
      IAutoConsoleColor; static;
  end;

class function TAutoConsoleColor.Apply;
var
  Obj: TAutoConsoleColor;
begin
  Obj := TAutoConsoleColor.Create(Foreground, Background);
  Result := Obj;

  // Register ourselves on the (weak reference) stack
  if Obj.FApplied then
    TAutoConsoleColor.ColorStack.Add(Result);
end;

constructor TAutoConsoleColor.Create;
var
  PreviousAttributes: Word;
begin
  FForeground := Foreground;
  FBackground := Background;
  FLayerId := AtomicIncrement(CurrentLayerId);

  // Try to apply the changes
  FApplied := RtlxSetConsoleColorInternal(Foreground, Background,
    @PreviousAttributes).IsSuccess;

  // Save initial attributes
  if FApplied and not TAutoConsoleColor.InitialStateCaptured then
  begin
    TAutoConsoleColor.InitialForeground :=
      TConsoleColor(PreviousAttributes and $0F);

    TAutoConsoleColor.InitialBackground :=
      TConsoleColor((PreviousAttributes and $F0) shr 4);

    TAutoConsoleColor.InitialStateCaptured := True;
  end;
end;

function TAutoConsoleColor.GetBackground;
begin
  Result := FBackground;
end;

function TAutoConsoleColor.GetForeground;
begin
  Result := FForeground;
end;

function TAutoConsoleColor.GetLayerId;
begin
  Result := FLayerId;
end;

procedure TAutoConsoleColor.Release;
var
  Entry: IAutoConsoleColor;
  LowerBackground, LowerForeground: TConsoleColor;
  HigherBackground, HigherForeground: TConsoleColor;
  NewBackground, NewForeground: TConsoleColor;
begin
  inherited;

  if not FApplied then
    Exit;

  LowerForeground := TAutoConsoleColor.InitialForeground;
  LowerBackground := TAutoConsoleColor.InitialBackground;
  HigherForeground := ccUnchanged;
  HigherBackground := ccUnchanged;

  // Determine the underlying/overlaying colors
  for Entry in TAutoConsoleColor.ColorStack.Entries do
    if Entry.LayerId < FLayerId then
    begin
      if Entry.Foreground <> ccUnchanged then
        LowerForeground := Entry.Foreground;

      if Entry.Background <> ccUnchanged then
        LowerBackground := Entry.Background;
    end
    else if Entry.LayerId > FLayerId then
    begin
      if Entry.Foreground <> ccUnchanged then
        HigherForeground := Entry.Foreground;

      if Entry.Background <> ccUnchanged then
        HigherBackground := Entry.Background;
    end;

  // Choose the new foreground
  if HigherForeground = ccUnchanged then
    NewForeground := LowerForeground
  else
    NewForeground := HigherForeground;

  // Choose the new background
  if HigherBackground = ccUnchanged then
    NewBackground := LowerBackground
  else
    NewBackground := HigherBackground;

  // Set the colors
  RtlxSetConsoleColorInternal(NewForeground, NewBackground);
end;

function RtlxSetConsoleColor;
begin
  Result := TAutoConsoleColor.Apply(Foreground, Background);
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
  if not NtxProcess.Query(NtxCurrentProcess, ProcessConsoleHostProcess, PID)
    .IsSuccess then
    Exit;

  if PID = 0 then
    Exit(chNone);

  // Query its and our creation time
  if NtxOpenProcess(hxProcess, PID, PROCESS_QUERY_LIMITED_INFORMATION).IsSuccess
    and NtxProcess.Query(hxProcess, ProcessTimes, ConhostInfo).IsSuccess
    and NtxProcess.Query(NtxCurrentProcess, ProcessTimes, OurInfo).IsSuccess then
  begin
    // Compare them
    if ConhostInfo.CreateTime > OurInfo.CreateTime then
      Result := chCreated
    else
      Result := chInherited;
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
