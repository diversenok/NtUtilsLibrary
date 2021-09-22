unit NtUtils.Processes.Create.Shell;

{
  The module provides support for process creation via Shell API
}

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Create a new process via ShellExecCmdLine
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoRunAsInvoker)]
[SupportedOption(spoWindowMode)]
function ShlxExecuteCmd(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via ShellExecuteExW
[SupportedOption(spoNewConsole)]
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoRunAsInvoker)]
[SupportedOption(spoWindowMode)]
function ShlxExecute(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.ShellApi, Ntapi.WinUser, NtUtils.Objects;

function ShlxExecuteCmd;
var
  ShowMode: Integer;
  SeclFlags: TSeclFlags;
  RunAsInvoker: IAutoReleasable;
begin
  // Allow running as invoker
  Result := RtlxApplyCompatLayer(
    poRunAsInvokerOn in Options.Flags,
    poRunAsInvokerOff in Options.Flags,
    RunAsInvoker
  );

  if not Result.IsSuccess then
    Exit;

  // Always set window mode to something
  if poUseWindowMode in Options.Flags then
    ShowMode := Integer(Options.WindowMode)
  else
    ShowMode := Integer(SW_SHOW_DEFAULT);

  SeclFlags := SECL_NO_UI;

  // Request elevation
  if poRequireElevation in Options.Flags then
    SeclFlags := SeclFlags or SECL_RUNAS;

  Result.Location := 'ShellExecCmdLine';
  Result.HResult := ShellExecCmdLine(
    0,
    PWideChar(Options.CommandLine),
    PWideChar(Options.CurrentDirectory),
    ShowMode,
    nil,
    SeclFlags
  );

  // Unfortunately, no information about the new process
  if Result.IsSuccess then
    Info := Default(TProcessInfo);
end;

function ShlxExecute;
var
  ExecInfo: TShellExecuteInfoW;
  RunAsInvoker: IAutoReleasable;
begin
  ExecInfo := Default(TShellExecuteInfoW);

  ExecInfo.cbSize := SizeOf(TShellExecuteInfoW);
  ExecInfo.Mask := SEE_MASK_NOASYNC or SEE_MASK_UNICODE or
    SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;

  ExecInfo.FileName := PWideChar(Options.ApplicationWin32);
  ExecInfo.Parameters := PWideChar(Options.Parameters);
  ExecInfo.Directory := PWideChar(Options.CurrentDirectory);

  // Always set window mode to something
  if poUseWindowMode in Options.Flags then
    ExecInfo.nShow := Integer(Options.WindowMode)
  else
    ExecInfo.nShow := Integer(SW_SHOW_DEFAULT);

  // SEE_MASK_NO_CONSOLE is opposite to CREATE_NEW_CONSOLE
  if not (poNewConsole in Options.Flags) then
    ExecInfo.Mask := ExecInfo.Mask or SEE_MASK_NO_CONSOLE;

  // Request elevation
  if poRequireElevation in Options.Flags then
    ExecInfo.Verb := 'runas';

  // Allow running as invoker
  Result := RtlxApplyCompatLayer(
    poRunAsInvokerOn in Options.Flags,
    poRunAsInvokerOff in Options.Flags,
    RunAsInvoker
  );

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ShellExecuteExW';
  Result.Win32Result := ShellExecuteExW(ExecInfo);

  // We only conditionally get a handle to the process.
  if Result.IsSuccess then
  begin
    Info := Default(TProcessInfo);

    if ExecInfo.hProcess <> 0 then
      Info.hxProcess := NtxObject.Capture(ExecInfo.hProcess);
  end;
end;

end.
