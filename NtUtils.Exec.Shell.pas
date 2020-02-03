unit NtUtils.Exec.Shell;

interface

uses
  NtUtils.Exec, NtUtils.Exceptions;

type
  TExecShellExecute = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

implementation

uses
  Winapi.Shell, Winapi.WinUser, NtUtils.Exec.Win32, NtUtils.Objects;

{ TExecShellExecute }

class function TExecShellExecute.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  ShellExecInfo: TShellExecuteInfoW;
  RunAsInvoker: IInterface;
begin
  FillChar(ShellExecInfo, SizeOf(ShellExecInfo), 0);
  ShellExecInfo.cbSize := SizeOf(ShellExecInfo);
  ShellExecInfo.fMask := SEE_MASK_NOASYNC or SEE_MASK_UNICODE or
    SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;

  // SEE_MASK_NO_CONSOLE is opposite to CREATE_NEW_CONSOLE
  if ParamSet.Provides(ppNewConsole) and not ParamSet.NewConsole then
    ShellExecInfo.fMask := ShellExecInfo.fMask or SEE_MASK_NO_CONSOLE;

  ShellExecInfo.lpFile := PWideChar(ParamSet.Application);

  if ParamSet.Provides(ppParameters) then
    ShellExecInfo.lpParameters := PWideChar(ParamSet.Parameters);

  if ParamSet.Provides(ppCurrentDirectory) then
    ShellExecInfo.lpDirectory := PWideChar(ParamSet.CurrentDircetory);

  if ParamSet.Provides(ppRequireElevation) and ParamSet.RequireElevation then
    ShellExecInfo.lpVerb := 'runas';

  if ParamSet.Provides(ppShowWindowMode) then
    ShellExecInfo.nShow := ParamSet.ShowWindowMode
  else
    ShellExecInfo.nShow := Integer(SW_SHOW_NORMAL);

  // Set RunAsInvoker compatibility mode. It will be reverted
  // after exiting from the current function.
  if ParamSet.Provides(ppRunAsInvoker) then
    RunAsInvoker := TRunAsInvoker.SetCompatState(ParamSet.RunAsInvoker);

  Result.Location := 'ShellExecuteExW';
  Result.Win32Result := ShellExecuteExW(ShellExecInfo);

  if Result.IsSuccess then
    with Info do
    begin
      FillChar(ClientId, SizeOf(ClientId), 0);

      // We use SEE_MASK_NOCLOSEPROCESS to get a handle to the process.
      hxProcess := TAutoHandle.Capture(ShellExecInfo.hProcess);
      hxThread := nil;
    end;
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
