unit NtUtils.Processes.Create.Com;

{
  This module provides support for asking various user-mode OS components via
  COM to create processes on our behalf.
}

interface

uses
  Winapi.Shell, NtUtils, NtUtils.Processes.Create;

// Create a new process via WMI
function WmixCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Ask Explorer via IShellDispatch2 to create a process on our behalf
function ComxShellExecute(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via WDC
function WdcxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntstatus, Winapi.ProcessThreadsApi, Winapi.WinError,
  Winapi.ObjBase, Winapi.ObjIdl, NtUtils.Ldr, NtUtils.Com.Dispatch,
  NtUtils.Tokens.Impersonate, NtUtils.Threads;

{ ----------------------------------- WMI ----------------------------------- }

function WmixCreateProcess;
var
  CoInitReverter, ImpReverter: IAutoReleasable;
  Win32_Process, StartupInfo: IDispatch;
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
    ImpReverter := NtxBackupThreadToken(NtxCurrentThread);

    Result := NtxImpersonateAnyToken(Options.hxToken);

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
  if poSuspended in Options.Flags then
  begin
    // For some reason, when specifing Win32_ProcessStartup.CreateFlags,
    // processes would not start without CREATE_BREAKAWAY_FROM_JOB.
    Result := DispxPropertySet(
      StartupInfo,
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
      StartupInfo,
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
      StartupInfo,
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
      VarFromIDispatch(StartupInfo),
      VarFromIntegerRef(ProcessId)
    ],
    @ResultCode
  );

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'Win32_Process.Create';
  Result.Status := STATUS_UNSUCCESSFUL;

  // This method returns some nonsensical error codes, inspect them...
  if ResultCode.VType and varTypeMask = varInteger then
  case ResultCode.VInteger of
    0: Result.Status := STATUS_SUCCESS;
    2: Result.Win32Error := ERROR_ACCESS_DENIED;
    3: Result.Win32Error := ERROR_PRIVILEGE_NOT_HELD;
    9: Result.Win32Error := ERROR_PATH_NOT_FOUND;
    21: Result.Win32Error := ERROR_INVALID_PARAMETER;
  end;

  VariantClear(ResultCode);

  // Return the process ID to the caller
  if Result.IsSuccess then
  begin
    Info := Default(TProcessInfo);
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

  Result.Location := 'IDispatch::QueryInterface(IServiceProvider)';
  Result.HResult := Dispatch.QueryInterface(IServiceProvider, ServiceProvider);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IServiceProvider::QueryService';
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

  Result.Location := 'IDispatch::QueryInterface(IShellFolderViewDual)';
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

  Result.Location := 'IDispatch::QueryInterface(IShellDispatch2)';
  Result.HResult := Dispatch.QueryInterface(IShellDispatch2, ShellDispatch);
end;

function ComxShellExecute;
var
  UndoCoInit: IAutoReleasable;
  ShellDispatch: IShellDispatch2;
  vOperation, vShow: TVarData;
begin
  Result := ComxInitialize(UndoCoInit);

  if not Result.IsSuccess then
    Exit;

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

  // The method does not provide us with any information about the new process
  Info := Default(TProcessInfo);
end;

{ ----------------------------------- WDC ----------------------------------- }

function WdcxCreateProcess;
var
  SeclFlags: TSeclFlags;
  UndoCoInit: IAutoReleasable;
begin
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
  if Result.IsSuccess then
    Info := Default(TProcessInfo);
end;

end.
