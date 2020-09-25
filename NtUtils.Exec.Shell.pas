unit NtUtils.Exec.Shell;

interface

uses
  NtUtils, NtUtils.Exec;

type
  TExecShellExecute = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

implementation

uses
  Winapi.Shell, Winapi.WinUser, NtUtils.Exec.Win32, NtUtils.Objects,
  NtUtils.Processes.Create, NtUtils.Processes.Create.Shell;

{ TExecShellExecute }

class function TExecShellExecute.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  Options: TCreateProcessOptions;
  RunAsInvoker: IInterface;
begin
  Options := Default(TCreateProcessOptions);

  Options.Application := ParamSet.Application;

  if ParamSet.Provides(ppNewConsole) and ParamSet.NewConsole then
    Options.Flags := Options.Flags or PROCESS_OPTIONS_NEW_CONSOLE;

  if ParamSet.Provides(ppParameters) then
    Options.Parameters := PWideChar(ParamSet.Parameters);

  if ParamSet.Provides(ppCurrentDirectory) then
    Options.CurrentDirectory := PWideChar(ParamSet.CurrentDircetory);

  if ParamSet.Provides(ppRequireElevation) and ParamSet.RequireElevation then
    Options.Flags := Options.Flags or PROCESS_OPTION_REQUIRE_ELEVATION;

  if ParamSet.Provides(ppShowWindowMode) then
  begin
    Options.Flags := Options.Flags or PROCESS_OPTIONS_USE_WINDOW_MODE;
    Options.WindowMode := ParamSet.ShowWindowMode;
  end;

  // Set RunAsInvoker compatibility mode. It will be reverted
  // after exiting from the current function.
  if ParamSet.Provides(ppRunAsInvoker) then
    RunAsInvoker := TRunAsInvoker.SetCompatState(ParamSet.RunAsInvoker);

  Result := ShlxExecute(Options, Info);
end;

class function TExecShellExecute.Supports(Parameter: TExecParam): Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory, ppNewConsole, ppRequireElevation,
    ppShowWindowMode, ppRunAsInvoker:
      Result := True;
  else
    Result := False;
  end;
end;

end.
