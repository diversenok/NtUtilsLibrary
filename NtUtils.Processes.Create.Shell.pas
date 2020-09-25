unit NtUtils.Processes.Create.Shell;

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Create a new process via ShellExecuteExW
function ShlxExecute(const Options: TCreateProcessOptions;
  out Info: TProcessInfo): TNtxStatus;

implementation

uses
  Winapi.Shell, Winapi.WinUser, NtUtils.Objects;

function ShlxExecute(const Options: TCreateProcessOptions;
  out Info: TProcessInfo): TNtxStatus;
var
  ExecInfo: TShellExecuteInfoW;
begin
  ExecInfo := Default(TShellExecuteInfoW);

  ExecInfo.cbSize := SizeOf(TShellExecuteInfoW);
  ExecInfo.fMask := SEE_MASK_NOASYNC or SEE_MASK_UNICODE or
    SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;

  ExecInfo.FileName := PWideChar(Options.Application);
  ExecInfo.Parameters := PWideChar(Options.Parameters);
  ExecInfo.Directory := PWideChar(Options.CurrentDirectory);

  // Always set window mode to something
  if Options.Flags and PROCESS_OPTIONS_USE_WINDOW_MODE <> 0 then
    ExecInfo.nShow := Integer(Options.WindowMode)
  else
    ExecInfo.nShow := Integer(SW_SHOW_DEFAULT);

  // SEE_MASK_NO_CONSOLE is opposite to CREATE_NEW_CONSOLE
  if Options.Flags and PROCESS_OPTIONS_NEW_CONSOLE = 0 then
    ExecInfo.fMask := ExecInfo.fMask or SEE_MASK_NO_CONSOLE;

  if Options.Flags and PROCESS_OPTION_REQUIRE_ELEVATION <> 0 then
    ExecInfo.Verb := 'runas';

  Result.Location := 'ShellExecuteExW';
  Result.Win32Result := ShellExecuteExW(ExecInfo);

  // We only conditionally get a handle to the process.
  if Result.IsSuccess then
  begin
    Info := Default(TProcessInfo);

    if ExecInfo.hProcess <> 0 then
      Info.hxProcess := TAutoHandle.Capture(ExecInfo.hProcess);
  end;
end;

end.
