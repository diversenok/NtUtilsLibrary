unit NtUtils.Exec.Wmi;

interface

uses
  NtUtils, NtUtils.Exec;

type
  TExecCallWmi = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

implementation

uses
  NtUtils.Processes.Create, NtUtils.Processes.Create.Wmi;

{ TExecCallWmi }

class function TExecCallWmi.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  Options: TCreateProcessOptions;
begin
  Options := Default(TCreateProcessOptions);

  Options.Application := ParamSet.Application;

  if ParamSet.Provides(ppParameters) then
    Options.Parameters := ParamSet.Parameters;

  if ParamSet.Provides(ppToken) then
    Options.hxToken := ParamSet.Token;

  if ParamSet.Provides(ppCurrentDirectory) then
    Options.CurrentDirectory := ParamSet.CurrentDircetory;

  if ParamSet.Provides(ppCreateSuspended) and ParamSet.CreateSuspended then
    Options.Flags := Options.Flags or PROCESS_OPTIONS_SUSPENDED;

  if ParamSet.Provides(ppShowWindowMode) then
  begin
    Options.Flags := Options.Flags or PROCESS_OPTIONS_USE_WINDOW_MODE;
    Options.WindowMode := ParamSet.ShowWindowMode;
  end;

  Result := WmixCreateProcess(Options, Info);
end;

class function TExecCallWmi.Supports(Parameter: TExecParam): Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory, ppDesktop, ppToken, ppCreateSuspended,
    ppShowWindowMode:
      Result := True;
  else
    Result := False;
  end;
end;

end.
