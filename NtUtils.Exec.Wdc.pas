unit NtUtils.Exec.Wdc;

interface

uses
  NtUtils, NtUtils.Exec;

type
  TExecCallWdc = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

implementation

uses
  NtUtils.Processes.Create, NtUtils.Processes.Create.Wdc;

{ TExecCallWdc }

class function TExecCallWdc.Execute(ParamSet: IExecProvider;
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

  Result := WdcxCreateProcess(Options, Info);
end;

class function TExecCallWdc.Supports(Parameter: TExecParam): Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory:
      Result := True;
  else
    Result := False;
  end;
end;

end.
