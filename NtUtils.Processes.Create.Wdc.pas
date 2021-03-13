unit NtUtils.Processes.Create.Wdc;

{
  The module provides support for process creation via a WDC task.
}

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Run a task using WDC
function WdcxRunTaskAsInteractiveUser(
  const CommandLine: String;
  const CurrentDirectory: String = ''
): TNtxStatus;

// Create a new process via WDC
function WdcxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Winapi.Wdc, NtUtils.Ldr, NtUtils.Com.Dispatch;

function RefStrOrNil(const S: String): PWideChar;
begin
  if S <> '' then
    Result := PWideChar(S)
  else
    Result := nil;
end;

function WdcxRunTaskAsInteractiveUser;
var
  UndoCoInit: IAutoReleasable;
begin
  Result := LdrxCheckModuleDelayedImport(wdc, 'WdcRunTaskAsInteractiveUser');

  if not Result.IsSuccess then
    Exit;

  Result := ComxInitialize(UndoCoInit);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WdcRunTaskAsInteractiveUser';
  Result.HResult := WdcRunTaskAsInteractiveUser(PWideChar(CommandLine),
    RefStrOrNil(CurrentDirectory), 0);
end;

function WdcxCreateProcess;
var
  CommandLine: String;
begin
  if Options.Flags and PROCESS_OPTION_FORCE_COMMAND_LINE <> 0 then
    CommandLine := Options.Parameters
  else if Options.Parameters <> '' then
    CommandLine := '"' + Options.Application + '" ' + Options.Parameters
  else
    CommandLine := '"' + Options.Application + '"';

  Result := WdcxRunTaskAsInteractiveUser(CommandLine, Options.CurrentDirectory);

  // This method does not provide any information about the new process
  Info := Default(TProcessInfo);
end;

end.
