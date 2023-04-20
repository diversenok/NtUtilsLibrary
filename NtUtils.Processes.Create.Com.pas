unit NtUtils.Processes.Create.Com;

{
  This module provides support for asking various user-mode OS components via
  COM to create processes on our behalf.
}

interface

uses
  Ntapi.ShellApi, Ntapi.Versions, NtUtils, NtUtils.Processes.Create;

// Create a new process via WMI
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
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoWindowMode)]
function ComxShellExecute(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via WDC
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoRequireElevation)]
function WdcxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via IDesktopAppXActivator
[MinOSVersion(OsWin10RS1)]
[SupportedOption(spoCurrentDirectory, OsWin11)]
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcessId, OsWin10RS2)]
[SupportedOption(spoWindowMode, OsWin11)]
[SupportedOption(spoAppUserModeId, omRequired)]
[SupportedOption(spoPackageBreakaway)]
function AppxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ProcessThreadsApi, Ntapi.WinError,
  Ntapi.ObjBase, Ntapi.ObjIdl, Ntapi.appmodel, Ntapi.WinUser, NtUtils.Ldr,
  NtUtils.Com.Dispatch, NtUtils.Tokens.Impersonate, NtUtils.Threads,
  NtUtils.Objects, NtUtils.Errors;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ ----------------------------------- WMI ----------------------------------- }

function WmixCreateProcess;
var
  CoInitReverter, ImpersonationReverter: IAutoReleasable;
  Win32_ProcessStartup, Win32_Process: IDispatch;
  ProcessId: TProcessId32;
  ResultCode: TVarData;
begin
  Info := Default(TProcessInfo);

  // TODO: add support for providing environment variables

  // Accessing WMI requires COM
  Result := ComxInitialize(CoInitReverter);

  if not Result.IsSuccess then
    Exit;

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
    Result := DispxPropertySet(
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
    Result := DispxPropertySet(
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
    Result := DispxPropertySet(
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
  Result := DispxMethodCall(
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
  Result := ComxCreateInstance(
    CLSID_ShellWindows,
    IShellWindows,
    ShellWindows,
    CLSCTX_LOCAL_SERVER
  );

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

function ComxShellExecute;
var
  UndoCoInit: IAutoReleasable;
  ShellDispatch: IShellDispatch2;
  vOperation, vShow: TVarData;
begin
  Info := Default(TProcessInfo);

  Result := ComxInitialize(UndoCoInit);

  if not Result.IsSuccess then
    Exit;

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

function WdcxCreateProcess;
var
  SeclFlags: TSeclFlags;
  UndoCoInit: IAutoReleasable;
begin
  Info := Default(TProcessInfo);

  Result := LdrxCheckModuleDelayedImport(wdc, 'WdcRunTaskAsInteractiveUser');

  if not Result.IsSuccess then
    Exit;

  Result := ComxInitialize(UndoCoInit);

  if not Result.IsSuccess then
    Exit;

  if poRequireElevation in Options.Flags then
    SeclFlags := SECL_RUNAS
  else
    SeclFlags := 0;

  Result.Location := 'WdcRunTaskAsInteractiveUser';
  Result.HResult := WdcRunTaskAsInteractiveUser(
    PWideChar(Options.CommandLine),
    RefStrOrNil(Options.CurrentDirectory),
    SeclFlags
  );

  // This method does not provide any information about the new process
end;

{ ---------------------------------- AppX ----------------------------------- }

function AppxCreateProcess;
var
  ComUninitializer: IAutoReleasable;
  Activator: IUnknown;
  ActivatorV1: IDesktopAppXActivatorV1;
  ActivatorV2: IDesktopAppXActivatorV2;
  ActivatorV3: IDesktopAppXActivatorV3;
  Flags: TDesktopAppxActivateOptions;
  WindowMode: TShowMode32;
  ImpersonationReverter: IAutoReleasable;
  hProcess: THandle32;
begin
  Info := Default(TProcessInfo);

  Result := ComxInitialize(ComUninitializer);

  if not Result.IsSuccess then
    Exit;

  // Create the activator without asking for any specicific interfaces
  Result.Location := 'CoCreateInstance';
  Result.LastCall.Parameter := 'CLSID_DesktopAppXActivator';
  Result.HResult := CoCreateInstance(CLSID_DesktopAppXActivator, nil,
    CLSCTX_INPROC_SERVER, IUnknown, Activator);

  if not Result.IsSuccess then
    Exit;

  Flags := DAXAO_NONPACKAGED_EXE or DAXAO_NO_ERROR_UI;

  if poRequireElevation in Options.Flags then
    Flags := Flags or DAXAO_ELEVATE;

  if BitTest(Options.PackageBreaway and
    PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_DISABLE_PROCESS_TREE) then
    Flags := Flags or DAXAO_NONPACKAGED_EXE_PROCESS_TREE;

  // Pass the token via impersonation
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

  if Activator.QueryInterface(IDesktopAppXActivatorV3,
    ActivatorV3).IsSuccess then
  begin
    if poUseWindowMode in Options.Flags then
      WindowMode := Options.WindowMode
    else
      WindowMode := TShowMode32.SW_SHOW_NORMAL;

    // Use Win 11+ version
    Result.Location := 'IDesktopAppXActivator::ActivateWithOptionsArgsWorkingDirectoryShowWindow';
    Result.HResult := ActivatorV3.ActivateWithOptionsArgsWorkingDirectoryShowWindow(
      PWideChar(Options.AppUserModeId),
      PWideChar(Options.ApplicationWin32),
      PWideChar(Options.Parameters),
      Flags,
      Options.ParentProcessId,
      nil,
      NtUtils.RefStrOrNil(Options.CurrentDirectory),
      WindowMode,
      hProcess
    );
  end
  else if Activator.QueryInterface(IDesktopAppXActivatorV2,
    ActivatorV2).IsSuccess then
  begin
    // Use RS2+ version
    Result.Location := 'IDesktopAppXActivator::ActivateWithOptions';
    Result.HResult := ActivatorV2.ActivateWithOptions(
      PWideChar(Options.AppUserModeId),
      PWideChar(Options.ApplicationWin32),
      PWideChar(Options.Parameters),
      Flags,
      Options.ParentProcessId,
      hProcess
    );
  end
  else if Activator.QueryInterface(IDesktopAppXActivatorV1,
    ActivatorV1).IsSuccess then
  begin
    // Use RS1 version
    Result.Location := 'IDesktopAppXActivator::ActivateWithOptions';
    Result.HResult := ActivatorV1.ActivateWithOptions(
      PWideChar(Options.AppUserModeId),
      PWideChar(Options.ApplicationWin32),
      PWideChar(Options.Parameters),
      Flags,
      hProcess
    );
  end
  else
  begin
    // Unknown version
    Result.Location := 'AppxCreateProcess';
    Result.Status := STATUS_UNKNOWN_REVISION;
    Exit;
  end;

  if Result.IsSuccess then
  begin
    // We get a process handle in response
    Include(Info.ValidFields, piProcessHandle);
    Info.hxProcess := Auto.CaptureHandle(hProcess);
  end;
end;

end.
