unit NtUtils.Processes.Create.Com;

{
  This module provides support for asking various user-mode OS components via
  COM to create processes on our behalf.
}

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Ask Explorer to create a process on our behalf
function ComxShellExecute(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Winapi.ObjBase, Winapi.ObjIdl, NtUtils.Com.Dispatch;

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

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IShellWindows.FindWindowSW';
  Result.HResult := ShellWindows.FindWindowSW(VarFromCardinal(CSIDL_DESKTOP),
    VarEmpty, SWC_DESKTOP, wnd, SWFO_NEEDDISPATCH, Dispatch);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDispatch.QueryInterface';
  Result.HResult := Dispatch.QueryInterface(IServiceProvider, ServiceProvider);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IServiceProvider.QueryService';
  Result.HResult := ServiceProvider.QueryService(SID_STopLevelBrowser,
    IShellBrowser, ShellBrowser);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IShellBrowser.QueryActiveShellView';
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

  Result.Location := 'IShellView.GetItemObject';
  Result.HResult := ShellView.GetItemObject(SVGIO_BACKGROUND, IDispatch,
   Dispatch);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDispatch.QueryInterface';
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

  Result.Location := 'IShellFolderViewDual.get_Application';
  Result.HResult := FolderView.get_Application(Dispatch);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IDispatch.QueryInterface';
  Result.HResult := Dispatch.QueryInterface(IShellDispatch2, ShellDispatch);
end;

function ComxShellExecute;
var
  ShellDispatch: IShellDispatch2;
  vOperation, vShow: TVarData;
begin
  Result := ComxGetShellDispatch(ShellDispatch);

  if not Result.IsSuccess then
    Exit;

  // Prepare the verb
  if LongBool(Options.Flags and PROCESS_OPTION_REQUIRE_ELEVATION) then
    vOperation := VarFromWideString('runas')
  else
    vOperation := VarEmpty;

  // Prepare the window mode
  if LongBool(Options.Flags and PROCESS_OPTION_USE_WINDOW_MODE) then
    vShow := VarFromWord(Word(Options.WindowMode))
  else
    vShow := VarEmpty;

  Result.Location := 'IShellDispatch2.ShellExecute';
  Result.HResult := ShellDispatch.ShellExecute(
    WideString(Options.Application),
    VarFromWideString(WideString(Options.Parameters)),
    VarFromWideString(WideString(Options.CurrentDirectory)),
    vOperation,
    vShow
  );
end;

end.
