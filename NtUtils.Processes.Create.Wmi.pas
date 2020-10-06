unit NtUtils.Processes.Create.Wmi;

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Create a new process via WMI
function WmixCreateProcess(const Options: TCreateProcessOptions;
  out Info: TProcessInfo): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, Winapi.ObjBase, Winapi.ProcessThreadsApi, Ntapi.ntstatus,
  Winapi.WinError, NtUtils.Com.Dispatch, NtUtils.Tokens.Impersonate,
  NtUtils.Files;

function WmixpCreateProcess(const Options: TCreateProcessOptions;
  out Info: TProcessInfo): TNtxStatus;
var
  Win32_Process, StartupInfo: IDispatch;
  CommandLine, CurrentDir: WideString;
  ProcessId: Cardinal;
  ResultCode: TVarData;
begin
  // Start preparing the startup info
  Result := DispxBindToObject('winmgmts:Win32_ProcessStartup', StartupInfo);

  if not Result.IsSuccess then
    Exit;

  // CreateFlags
  if Options.Flags and PROCESS_OPTION_SUSPENDED <> 0 then
  begin
    // For some reason, when specifing Win32_ProcessStartup.CreateFlags,
    // processes would not start without CREATE_BREAKAWAY_FROM_JOB.
    Result := DispxPropertySet(StartupInfo, 'CreateFlags',
      VarFromCardinal(CREATE_BREAKAWAY_FROM_JOB or CREATE_SUSPENDED));

    if not Result.IsSuccess then
      Exit;
  end;

  // Window Mode
  if Options.Flags and PROCESS_OPTION_USE_WINDOW_MODE <> 0 then
  begin
    Result := DispxPropertySet(StartupInfo, 'ShowWindow',
      VarFromWord(Word(Options.WindowMode)));

    if not Result.IsSuccess then
      Exit;
  end;

  // Desktop
  if Options.Desktop <> '' then
  begin
    Result := DispxPropertySet(StartupInfo, 'WinstationDesktop',
      VarFromWideString(Options.Desktop));

    if not Result.IsSuccess then
      Exit;
  end;

  // Command line
  if Options.Flags and PROCESS_OPTION_FORCE_COMMAND_LINE <> 0 then
    CommandLine := Options.Parameters
  else if Options.Parameters <> '' then
    CommandLine := '"' + Options.Application + '" ' + Options.Parameters
  else
    CommandLine := '"' + Options.Application + '"';

  // Current directory
  if Options.CurrentDirectory <> '' then
    CurrentDir := Options.CurrentDirectory
  else
    CurrentDir := RtlxGetCurrentPathPeb;

  // Prepare the process
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

  // The method returns some nonsensical error codes, inspect them...
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

function WmixCreateProcess(const Options: TCreateProcessOptions;
  out Info: TProcessInfo): TNtxStatus;
var
  RevertCoInit, RevertImpersonation: Boolean;
  hxBackupToken: IHandle;
begin
  Result := ComxInitialize(RevertCoInit);

  if not Result.IsSuccess then
    Exit;

  RevertImpersonation := False;
  try
    // Impersonate the passed token
    if Assigned(Options.hxToken) then
    begin
     hxBackupToken := NtxBackupImpersonation(NtCurrentThread);

     Result := NtxImpersonateAnyToken(Options.hxToken.Handle);

     if Result.IsSuccess then
       RevertImpersonation := True
     else
       Exit;
    end;

    // Do the rest under impersonation and initialized COM
    Result := WmixpCreateProcess(Options, Info);
  finally
    if RevertImpersonation then
      NtxRestoreImpersonation(NtCurrentThread, hxBackupToken);

    if RevertCoInit then
      CoUninitialize;
  end;
end;

end.
