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
  Winapi.Wdc, Winapi.WinError, NtUtils.Ldr;

{ TExecCallWdc }

class function TExecCallWdc.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  CommandLine: String;
  CurrentDir: PWideChar;
begin
  CommandLine := PrepareCommandLine(ParamSet);

  if ParamSet.Provides(ppCurrentDirectory) then
    CurrentDir := PWideChar(ParamSet.CurrentDircetory)
  else
    CurrentDir := nil;

  Result := LdrxCheckModuleDelayedImport(wdc, 'WdcRunTaskAsInteractiveUser');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WdcRunTaskAsInteractiveUser';
  Result.HResult := WdcRunTaskAsInteractiveUser(PWideChar(CommandLine),
    CurrentDir, 0);

  if Result.IsSuccess then
    with Info do
    begin
      // The method does not provide any information about the process
      FillChar(ClientId, SizeOf(ClientId), 0);
      hxProcess := nil;
      hxThread := nil;
    end;
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
