unit NtUtils.Processes.Create.Wmi;

{
  The module provides support for process creation via a WMI.
}

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Create a new process via WMI
function WmixCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntpsapi, Winapi.ObjBase, Winapi.ProcessThreadsApi,
  Ntapi.ntstatus, Winapi.WinError, NtUtils.Com.Dispatch,
  NtUtils.Tokens.Impersonate, NtUtils.Files, NtUtils.Threads;

function WmixCreateProcess;
var
  CoInitReverter, ImpReverter: IAutoReleasable;
  Win32_Process, StartupInfo: IDispatch;
  CommandLine, CurrentDir: WideString;
  ProcessId: TProcessId32;
  ResultCode: TVarData;
begin
  // Accessing WMI requires COM
  Result := ComxInitialize(CoInitReverter);

  if not Result.IsSuccess then
    Exit;

  // We pass the token to WMI by impersonating it
  if Assigned(Options.hxToken) then
  begin
    // Revert to the original one when we are done.
    ImpReverter := NtxBackupImpersonation(NtxCurrentThread);

    Result := NtxImpersonateAnyToken(Options.hxToken.Handle);

    if not Result.IsSuccess then
    begin
      // No need to revert impersonation if we did not change it.
      ImpReverter.AutoRelease := False;
      Exit;
    end;
  end;

  // Start preparing the startup info
  Result := DispxBindToObject('winmgmts:Win32_ProcessStartup', StartupInfo);

  if not Result.IsSuccess then
    Exit;

  // Fill-in CreateFlags
  if Options.Flags and PROCESS_OPTION_SUSPENDED <> 0 then
  begin
    // For some reason, when specifing Win32_ProcessStartup.CreateFlags,
    // processes would not start without CREATE_BREAKAWAY_FROM_JOB.
    Result := DispxPropertySet(StartupInfo, 'CreateFlags',
      VarFromCardinal(CREATE_BREAKAWAY_FROM_JOB or CREATE_SUSPENDED));

    if not Result.IsSuccess then
      Exit;
  end;

  // Fill-in the Window Mode
  if Options.Flags and PROCESS_OPTION_USE_WINDOW_MODE <> 0 then
  begin
    Result := DispxPropertySet(StartupInfo, 'ShowWindow',
      VarFromWord(Word(Options.WindowMode)));

    if not Result.IsSuccess then
      Exit;
  end;

  // Fill-in the desktop
  if Options.Desktop <> '' then
  begin
    Result := DispxPropertySet(StartupInfo, 'WinstationDesktop',
      VarFromWideString(Options.Desktop));

    if not Result.IsSuccess then
      Exit;
  end;

  // Prepare the command line
  if Options.Flags and PROCESS_OPTION_FORCE_COMMAND_LINE <> 0 then
    CommandLine := Options.Parameters
  else if Options.Parameters <> '' then
    CommandLine := '"' + Options.Application + '" ' + Options.Parameters
  else
    CommandLine := '"' + Options.Application + '"';

  // We always need to supply something as a current directory.
  if Options.CurrentDirectory <> '' then
    CurrentDir := Options.CurrentDirectory
  else
    CurrentDir := RtlxGetCurrentPathPeb;

  // Prepare the process object
  Result := DispxBindToObject('winmgmts:Win32_Process', Win32_Process);

  if not Result.IsSuccess then
    Exit;

  ProcessId := 0;

  // Create the process
  Result := DispxMethodCall(Win32_Process, 'Create', [
    VarFromWideString(CommandLine),
    VarFromWideString(CurrentDir),
    VarFromIDispatch(StartupInfo),
    VarFromIntegerRef(ProcessId)],
    @ResultCode);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'Win32_Process.Create';
  Result.Status := STATUS_UNSUCCESSFUL;

  // This method returns some nonsensical error codes, inspect them...
  if ResultCode.VType and varTypeMask = varInteger then
  case ResultCode.VInteger of
    0: Result.Status := STATUS_SUCCESS;
    2: Result.WinError := ERROR_ACCESS_DENIED;
    3: Result.WinError := ERROR_PRIVILEGE_NOT_HELD;
    9: Result.WinError := ERROR_PATH_NOT_FOUND;
    21: Result.WinError := ERROR_INVALID_PARAMETER;
  end;

  VariantClear(ResultCode);

  // Return the process ID to the caller
  if Result.IsSuccess then
  begin
    Info.ClientId.UniqueProcess := ProcessId;
    Info.ClientId.UniqueThread := 0;
    Info.hxProcess := nil;
    Info.hxThread := nil;
  end;
end;

end.
