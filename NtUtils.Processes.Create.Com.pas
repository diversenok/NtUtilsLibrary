unit NtUtils.Processes.Create.Com;

{
  This module provides support for asking various user-mode OS components via
  COM to create processes on our behalf.
}

interface

uses
  Ntapi.ShellApi, Ntapi.ObjBase, NtUtils, NtUtils.Processes.Create;

// Create a new process via WMI
[RequiresCOM]
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
function WmixCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Ask Explorer via IShellDispatch2 to create a process on our behalf
[RequiresCOM]
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoWindowMode)]
function ComxShellDispatchExecute(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via WDC
[RequiresCOM]
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoRequireElevation)]
function WdcxRunAsInteractive(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via Task Scheduler using Task Manager's interactive task
[RequiresCOM]
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoSessionId)]
function SchxRunAsInteractive(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via a BITS job trigger
[RequiresCOM]
function ComxCreateProcessBITS(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ProcessThreadsApi, Ntapi.WinError,
  Ntapi.ObjIdl, Ntapi.taskschd, Ntapi.ntpebteb, Ntapi.winsta, Ntapi.Bits,
  NtUtils.Ldr, NtUtils.Com, NtUtils.Threads, NtUtils.Tokens.Impersonate,
  NtUtils.WinStation, NtUtils.SysUtils, NtUtils.Synchronization;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ ----------------------------------- WMI ----------------------------------- }

function WmixCreateProcess;
var
  ImpersonationReverter: IAutoReleasable;
  Win32_ProcessStartup, Win32_Process: IDispatch;
  ProcessId: TProcessId32;
  ResultCode: TVarData;
begin
  Info := Default(TProcessInfo);

  // TODO: add support for providing environment variables

  // We pass the token to WMI by impersonating it
  if Assigned(Options.hxToken) then
  begin
    // Revert to the original one when we are done.
    ImpersonationReverter := NtxBackupThreadToken(NtxCurrentThread);

    Result := NtxImpersonateAnyToken(Options.hxToken);

    if not Result.IsSuccess then
    begin
      // No need to revert impersonation if we did not change it.
      ImpersonationReverter.AutoRelease := False;
      Exit;
    end;
  end;

  // Start preparing the startup info
  Result := DispxBindToObject('winmgmts:Win32_ProcessStartup',
    Win32_ProcessStartup);

  if not Result.IsSuccess then
    Exit;

  // Fill-in CreateFlags
  if poSuspended in Options.Flags then
  begin
    // For some reason, when specifing Win32_ProcessStartup.CreateFlags,
    // processes would not start without CREATE_BREAKAWAY_FROM_JOB.
    Result := DispxSetPropertyByName(
      Win32_ProcessStartup,
      'CreateFlags',
      VarFromCardinal(CREATE_BREAKAWAY_FROM_JOB or CREATE_SUSPENDED)
    );

    if not Result.IsSuccess then
      Exit;
  end;

  // Fill-in the Window Mode
  if poUseWindowMode in Options.Flags then
  begin
    Result := DispxSetPropertyByName(
      Win32_ProcessStartup,
      'ShowWindow',
      VarFromWord(Word(Options.WindowMode))
    );

    if not Result.IsSuccess then
      Exit;
  end;

  // Fill-in the desktop
  if Options.Desktop <> '' then
  begin
    Result := DispxSetPropertyByName(
      Win32_ProcessStartup,
      'WinstationDesktop',
      VarFromWideString(Options.Desktop)
    );

    if not Result.IsSuccess then
      Exit;
  end;

  // Prepare the process object
  Result := DispxBindToObject('winmgmts:Win32_Process', Win32_Process);

  if not Result.IsSuccess then
    Exit;

  ProcessId := 0;

  // Create the process
  Result := DispxCallMethodByName(
    Win32_Process,
    'Create',
    [
      VarFromWideString(WideString(Options.CommandLine)),
      VarFromWideString(WideString(Options.CurrentDirectory)),
      VarFromIDispatch(Win32_ProcessStartup),
      VarFromIntegerRef(ProcessId)
    ],
    @ResultCode
  );

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'Win32_Process::Create';
  Result.Status := STATUS_UNSUCCESSFUL;

  // This method returns custom status codes; convert them
  if ResultCode.VType and varTypeMask = varInteger then
  case TWmiWin32ProcessCreateStatus(ResultCode.VInteger) of
    Process_STATUS_SUCCESS:
      Result.Status := STATUS_SUCCESS;

    Process_STATUS_NOT_SUPPORTED:
      Result.Status := STATUS_NOT_SUPPORTED;

    Process_STATUS_ACCESS_DENIED:
      Result.Status := STATUS_ACCESS_DENIED;

    Process_STATUS_INSUFFICIENT_PRIVILEGE:
      Result.Status := STATUS_PRIVILEGE_NOT_HELD;

    Process_STATUS_UNKNOWN_FAILURE:
      Result.Status := STATUS_UNSUCCESSFUL;

    Process_STATUS_PATH_NOT_FOUND:
      Result.Status := STATUS_OBJECT_NAME_NOT_FOUND;

    Process_STATUS_INVALID_PARAMETER:
      Result.Status := STATUS_INVALID_PARAMETER;
  end;

  VariantClear(ResultCode);

  // Return the process ID to the caller
  if Result.IsSuccess then
  begin
    Include(Info.ValidFields, piProcessID);
    Info.ClientId.UniqueProcess := ProcessId;
  end;
end;

{ ----------------------------- IShellDispatch2 ----------------------------- }

// Rertieve the shell view for the desktop
function ComxFindDesktopFolderView(
  out ShellView: IShellView
): TNtxStatus;
var
  ShellWindows: IShellWindows;
  wnd: Integer;
  Dispatch: IDispatch;
  ServiceProvider: IServiceProvider;
  ShellBrowser: IShellBrowser;
begin
  Result := ComxCreateInstance(CLSID_ShellWindows, IShellWindows, ShellWindows,
    CLSCTX_LOCAL_SERVER);
  Result.LastCall.Parameter := 'CLSID_ShellWindows';

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IShellWindows::FindWindowSW';
  Result.HResultAllowFalse := ShellWindows.FindWindowSW(
    VarFromCardinal(CSIDL_DESKTOP),
    VarEmpty,
    SWC_DESKTOP,
    wnd,
    SWFO_NEEDDISPATCH,
    Dispatch
  );

  // S_FALSE indicates that the the function did not find the window.
  // We cannot proceed in this case, so fail the function with a meaningful code
  if Result.HResult = S_FALSE then
    Result.Status := STATUS_NOT_FOUND;

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDispatch::QueryInterface';
  Result.LastCall.Parameter := 'IServiceProvider';
  Result.HResult := Dispatch.QueryInterface(IServiceProvider, ServiceProvider);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IServiceProvider::QueryService';
  Result.LastCall.Parameter := 'SID_STopLevelBrowser';
  Result.HResult := ServiceProvider.QueryService(SID_STopLevelBrowser,
    IShellBrowser, ShellBrowser);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IShellBrowser::QueryActiveShellView';
  Result.HResult := ShellBrowser.QueryActiveShellView(ShellView);
end;

// Locate the desktop folder view object
function ComxGetDesktopAutomationObject(
  out FolderView: IShellFolderViewDual
): TNtxStatus;
var
  ShellView: IShellView;
  Dispatch: IDispatch;
begin
  Result := ComxFindDesktopFolderView(ShellView);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IShellView::GetItemObject';
  Result.HResult := ShellView.GetItemObject(SVGIO_BACKGROUND, IDispatch,
   Dispatch);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDispatch::QueryInterface';
  Result.LastCall.Parameter := 'IShellFolderViewDual';
  Result.HResult := Dispatch.QueryInterface(IShellFolderViewDual, FolderView);
end;

// Access the shell dispatch object
function ComxGetShellDispatch(
  out ShellDispatch: IShellDispatch2
): TNtxStatus;
var
  FolderView: IShellFolderViewDual;
  Dispatch: IDispatch;
begin
  Result := ComxGetDesktopAutomationObject(FolderView);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IShellFolderViewDual::get_Application';
  Result.HResult := FolderView.get_Application(Dispatch);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDispatch::QueryInterface';
  Result.LastCall.Parameter := 'IShellDispatch2';
  Result.HResult := Dispatch.QueryInterface(IShellDispatch2, ShellDispatch);
end;

function ComxShellDispatchExecute;
var
  ShellDispatch: IShellDispatch2;
  vOperation, vShow: TVarData;
begin
  Info := Default(TProcessInfo);

  // Retrieve the Shell Dispatch object
  Result := ComxGetShellDispatch(ShellDispatch);

  if not Result.IsSuccess then
    Exit;

  // Prepare the verb
  if poRequireElevation in Options.Flags then
    vOperation := VarFromWideString('runas')
  else
    vOperation := VarEmpty;

  // Prepare the window mode
  if poUseWindowMode in Options.Flags then
    vShow := VarFromWord(Word(Options.WindowMode))
  else
    vShow := VarEmpty;

  Result.Location := 'IShellDispatch2::ShellExecute';
  Result.HResult := ShellDispatch.ShellExecute(
    WideString(Options.ApplicationWin32),
    VarFromWideString(WideString(Options.Parameters)),
    VarFromWideString(WideString(Options.CurrentDirectory)),
    vOperation,
    vShow
  );

  // This method does not provide any information about the new process
end;

{ ----------------------------------- WDC ----------------------------------- }

function WdcxRunAsInteractive;
var
  SeclFlags: TSeclFlags;
begin
  Info := Default(TProcessInfo);

  Result := LdrxCheckDelayedImport(delayed_wdc,
    delayed_WdcRunTaskAsInteractiveUser);

  if not Result.IsSuccess then
    Exit;

  SeclFlags := SECL_NO_UI or SECL_ALLOW_NONEXE;

  if poRequireElevation in Options.Flags then
    SeclFlags := SeclFlags or SECL_RUNAS;

  Result.Location := 'WdcRunTaskAsInteractiveUser';
  Result.HResult := WdcRunTaskAsInteractiveUser(
    PWideChar(Options.CommandLine),
    RefStrOrNil(Options.CurrentDirectory),
    SeclFlags
  );

  // This method does not provide any information about the new process
end;

function SchxRunAsInteractive;
const
  TIMEOUT_DELAY = 64 * MILLISEC;
  TIMEOUT_CHECK_COUNT = (5000 * MILLISEC) div TIMEOUT_DELAY;
var
  TaskService: ITaskService;
  TaskFolder: ITaskFolder;
  Task: IRegisteredTask;
  RunningTask: IRunningTask;
  SeclFlags: TSeclFlags;
  SessionId: TSessionId;
  SessionInfo: TWinStationInformation;
  Domain, User: String;
  ParameterStr: WideString;
  RemainingTimeoutChecks: NativeInt;
  State: TTaskState;
  LastResult: HResult;
begin
  // This method does not provide any information about the new process
  Info := Default(TProcessInfo);

  Result := ComxCreateInstanceWithFallback('taskschd.dll', CLSID_TaskScheduler,
    ITaskService, TaskService, 'CLSID_TaskScheduler');

  if not Result.IsSuccess then
    Exit;

  // Connect to the local Task Scheduler
  Result.Location := 'ITaskService::Connect';
  Result.HResult := TaskService.Connect(VarEmpty, VarEmpty, VarEmpty, VarEmpty);

  if not Result.IsSuccess then
    Exit;

  // Find Task Manager's task folder
  Result.Location := 'ITaskService::GetFolder';
  Result.LastCall.Parameter := TASK_MANAGER_TASK_FOLDER;
  Result.HResult := TaskService.GetFolder(TASK_MANAGER_TASK_FOLDER, TaskFolder);

  if not Result.IsSuccess then
    Exit;

  // Find the task
  Result.Location := 'ITaskFolder::GetTask';
  Result.LastCall.Parameter := TASK_MANAGER_TASK_PATH;
  Result.HResult := TaskFolder.GetTask(TASK_MANAGER_TASK_NAME, Task);

  if not Result.IsSuccess then
    Exit;

  SeclFlags := SECL_NO_UI or SECL_ALLOW_NONEXE;

  // Prepare the parameters
  if poRequireElevation in Options.Flags then
    SeclFlags := SeclFlags or SECL_RUNAS;

  if poUseSessionId in Options.Flags then
    SessionId := Options.SessionId
  else
    SessionId := RtlGetCurrentPeb.SessionID;

  if (Options.Domain <> '') and (Options.Username <> '') then
  begin
    // Use the provided account name to avoid querying it
    Domain := Options.Domain;
    User := Options.Username;
  end
  else
  begin
    // Query the username of the specified session
    Result := WsxWinStation.Query(SessionId, WinStationInformation, SessionInfo);

    if not Result.IsSuccess then
      Exit;

    Domain := String(SessionInfo.Domain);
    User := String(SessionInfo.UserName);
  end;

  // Pack the parameters
  ParameterStr := RtlxFormatString('%08x|%s\%s|%s|%s', [
    SeclFlags,
    Domain,
    User,
    Options.CurrentDirectory,
    Options.CommandLine
  ]);

  // Invoke the task
  Result.Location := 'IRegisteredTask::RunEx';
  Result.LastCall.Parameter := TASK_MANAGER_TASK_PATH;
  Result.HResult := Task.RunEx(
    VarFromWideString(ParameterStr),
    TASK_RUN_IGNORE_CONSTRAINTS or TASK_RUN_USE_SESSION_ID,
    SessionId,
    '',
    RunningTask
  );

  if not Result.IsSuccess then
    Exit;

  RemainingTimeoutChecks := TIMEOUT_CHECK_COUNT;

  repeat
    // Check if the task completed
    Result.Location := 'IRegisteredTask::get_State';
    Result.HResult := Task.get_State(State);

    if not Result.IsSuccess then
      Exit;

    if State <> TASK_STATE_RUNNING then
      Break;

    if RemainingTimeoutChecks >= 0 then
    begin
      // Wait before checking again
      Result := NtxDelayExecution(TIMEOUT_DELAY);

      if not Result.IsSuccess then
        Exit;
    end
    else
    begin
      // Waited too many times
      Result.Location := 'SchxRunAsInteractive';
      Result.Win32Error := ERROR_TIMEOUT;
      Exit;
    end;

    Dec(RemainingTimeoutChecks);
  until False;

  // Forward the result
  Result.Location := 'IRegisteredTask::get_LastTaskResult';
  Result.HResult := Task.get_LastTaskResult(LastResult);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WdcRunTask::Start';
  Result.HResult := LastResult;
end;

{ ----------------------------------- BITS -----------------------------------}

function ComxCreateProcessBITS(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;
const
  TIMEOUT_DELAY = 64 * MILLISEC;
  TIMEOUT_CHECK_COUNT = (5000 * MILLISEC) div TIMEOUT_DELAY;
var
  BackgroundCopyManager: IBackgroundCopyManager;
  JobId: TGuid;
  BackgroundCopyJob: IBackgroundCopyJob;
  BackgroundCopyJob2: IBackgroundCopyJob2;
  AutoCancel: IAutoReleasable;
  JobState: TBgJobState;
  RemainingTimeoutChecks: NativeInt;
begin
  // No info about the new process on output
  Info := Default(TProcessInfo);

  // Connect to BITS
  Result := ComxCreateInstance(CLSID_BackgroundCopyManager,
    IBackgroundCopyManager, BackgroundCopyManager);
  Result.LastCall.Parameter := 'CLSID_BackgroundCopyManager';

  if not Result.IsSuccess then
    Exit;

  // Create a temporary transfer job
  Result.Location := 'IBackgroundCopyManager::CreateJob';
  Result.HResult := BackgroundCopyManager.CreateJob('Program Start Task',
    BG_JOB_TYPE_UPLOAD, JobId, BackgroundCopyJob);

  if not Result.IsSuccess then
    Exit;

  // Make sure to delete it once finished/failed
  AutoCancel := Auto.Delay(
    procedure
    begin
      BackgroundCopyJob.Cancel;
    end
  );

  // Upgrade the interface to v2
  Result.Location := 'IBackgroundCopyJob::QueryInterface';
  Result.LastCall.Parameter := 'IBackgroundCopyJob2';
  Result.HResult := BackgroundCopyJob.QueryInterface(IBackgroundCopyJob2,
    BackgroundCopyJob2);

  if not Result.IsSuccess then
    Exit;

  // Use the error notifications as our trigger
  Result.Location := 'IBackgroundCopyJob::SetNotifyFlags';
  Result.HResult := BackgroundCopyJob.SetNotifyFlags(BG_NOTIFY_JOB_ERROR);

  if not Result.IsSuccess then
    Exit;

  // Disable retries
  Result.Location := 'IBackgroundCopyJob::SetNoProgressTimeout';
  Result.HResult := BackgroundCopyJob.SetNoProgressTimeout(0);

  if not Result.IsSuccess then
    Exit;

  // Use an upload request that is guaranteed to fail. We still need to provide
  // something as a remote location and a valid readable file on input.
  Result.Location := 'IBackgroundCopyJob::AddFile';
  Result.HResult := BackgroundCopyJob.AddFile('\\?\NUL',
    '\\?\BootPartition\Windows\system32\kernel32.dll');

  if not Result.IsSuccess then
    Exit;

  // Configure process creation on error
  Result.Location := 'IBackgroundCopyJob2::SetNotifyCmdLine';
  Result.HResult := BackgroundCopyJob2.SetNotifyCmdLine(
    PWideChar(Options.ApplicationWin32), PWideChar(Options.Parameters));

  if not Result.IsSuccess then
    Exit;

  // Let the task run and fail
  Result.Location := 'IBackgroundCopyJob::Resume';
  Result.HResult := BackgroundCopyJob.Resume;

  if not Result.IsSuccess then
    Exit;

  RemainingTimeoutChecks := TIMEOUT_CHECK_COUNT;

  repeat
    Result.Location := 'IBackgroundCopyJob::GetState';
    Result.HResult := BackgroundCopyJob.GetState(JobState);

    if not Result.IsSuccess then
      Exit;

    if JobState > BG_JOB_STATE_SUSPENDED then
      Break;

    if RemainingTimeoutChecks >= 0 then
    begin
      // Wait before checking again
      Result := NtxDelayExecution(TIMEOUT_DELAY);

      if not Result.IsSuccess then
        Exit;
    end
    else
    begin
      // Waited for too many times
      Result.Location := 'ComxCreateProcessBITS';
      Result.Win32Error := ERROR_TIMEOUT;
      Exit;
    end;

    Dec(RemainingTimeoutChecks);
  until False;
end;

end.
