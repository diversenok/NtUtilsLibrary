unit NtUtils.Exec.Nt;

interface

uses
  NtUtils, NtUtils.Exec;

type
  TExecRtlCreateUserProcess = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

implementation

uses
  NtUtils.Processes.Create, NtUtils.Processes.Create.Native;

{ TExecRtlCreateUserProcess }

class function TExecRtlCreateUserProcess.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  Options: TCreateProcessOptions;
begin
  Options := Default(TCreateProcessOptions);

  Options.Application := ParamSet.Application;

  if ParamSet.Provides(ppParameters) then
    Options.Parameters := ParamSet.Parameters;

  if ParamSet.Provides(ppCurrentDirectory) then
    Options.CurrentDirectory := ParamSet.CurrentDircetory;

  if ParamSet.Provides(ppDesktop) then
    Options.Desktop := ParamSet.Desktop;

  if ParamSet.Provides(ppToken) then
    Options.hxToken := ParamSet.Token;

  if ParamSet.Provides(ppParentProcess) then
    Options.Attributes.hxParentProcess := ParamSet.ParentProcess;

  if ParamSet.Provides(ppInheritHandles) and ParamSet.InheritHandles then
    Options.Flags := Options.Flags or PROCESS_OPTIONS_INHERIT_HANDLES;

  if ParamSet.Provides(ppCreateSuspended) and ParamSet.CreateSuspended then
    Options.Flags := Options.Flags or PROCESS_OPTIONS_SUSPENDED;

  if ParamSet.Provides(ppShowWindowMode) then
  begin
    Options.Flags := Options.Flags or PROCESS_OPTIONS_USE_WINDOW_MODE;
    Options.WindowMode := ParamSet.ShowWindowMode;
  end;

  if ParamSet.Provides(ppEnvironment) then
    Options.Environment := ParamSet.Environment;

  Result := RtlxCreateUserProcess(Options, Info);
end;

class function TExecRtlCreateUserProcess.Supports(Parameter: TExecParam):
  Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory, ppDesktop, ppToken, ppParentProcess,
    ppInheritHandles, ppCreateSuspended, ppShowWindowMode, ppEnvironment:
      Result := True;
  else
    Result := False;
  end;
end;

end.
