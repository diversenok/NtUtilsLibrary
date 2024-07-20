unit NtUtils.Processes.Create.Package;

{
  The module provides support for creating processes with package identity.
}

interface

uses
  Ntapi.WinNt, Ntapi.ObjBase, Ntapi.appmodel, Ntapi.Versions, NtUtils,
  NtUtils.Processes.Create;

// Create a new process in a package context via IDesktopAppXActivator
[RequiresCOM]
[MinOSVersion(OsWin10RS1)]
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess, OsWin10RS2)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoAppUserModeId, omRequired)]
[SupportedOption(spoPackageBreakaway)]
function PkgxCreateProcessInPackage(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Activate a Windows Store application
[RequiresCOM]
[MinOSVersion(OsWin8)]
function PkgxActivateApplication(
  const AppUserModelId: String;
  [opt] const Arguments: String = '';
  Options: TActivateOptions = 0;
  [out, opt] pProcessId: PProcessId32 = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntobapi, Ntapi.ShellApi, Ntapi.ObjIdl,
  Ntapi.WinUser, Ntapi.ProcessThreadsApi, Ntapi.ntstatus, NtUtils.Errors,
  NtUtils.Com, NtUtils.Tokens.Impersonate, NtUtils.Threads, NtUtils.Objects,
  NtUtils.Processes.Create.Shell, NtUtils.Processes.Info, NtUtils.AntiHooking,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TAppxActivatorHookContext = record
    CurrentThreadId: TThreadId;
    TargetProcessId: TProcessId;
    Options: TCreateProcessOptions;
    ShellExecHookReverter: IAutoReleasable;
    OpenProcessHookReverter: IAutoReleasable;
  end;
  PAppxActivatorHookContext = ^TAppxActivatorHookContext;
  IAppxActivatorHookContext = IMemory<PAppxActivatorHookContext>;

var
  // A variable to pass info to the hooks we install
  AppxActivatorHookContext: Weak<IAppxActivatorHookContext>;

function HookedNtOpenProcess(
  out ProcessHandle: THandle;
  DesiredAccess: TProcessAccessMask;
  const ObjectAttributes: TObjectAttributes;
  const ClientId: TClientId
): NTSTATUS; stdcall;
var
  ShouldHandle: Boolean;
  Context: IAppxActivatorHookContext;
begin
  // Verify that we are on the right thread processing the right request
  ShouldHandle := AppxActivatorHookContext.Upgrade(Context) and
    (Context.Data.CurrentThreadId = NtCurrentThreadId) and
    (ClientId.UniqueProcess = Context.Data.TargetProcessId) and
    Assigned(Context.Data.Options.hxParentProcess);

  if ShouldHandle then
    // Reuse the existing handle
    Result := NtDuplicateObject(NtCurrentProcess,
      Context.Data.Options.hxParentProcess.Handle, NtCurrentProcess,
      ProcessHandle, 0, 0, DUPLICATE_SAME_ACCESS)
  else
    // Forward the request further
    Result := NtOpenProcess(ProcessHandle, DesiredAccess, ObjectAttributes,
      ClientId);
end;

function HookedShellExecuteExW(
  var ExecInfo: TShellExecuteInfoW
): LongBool; stdcall;
var
  ShouldHandle: Boolean;
  Context: IAppxActivatorHookContext;
  PassedProvider, HookedProvider: IServiceProvider;
  PassedDirectory: PWideChar;
begin
  PassedDirectory := nil;

  // Verify that we are on the right thread processing the right request
  ShouldHandle := AppxActivatorHookContext.Upgrade(Context) and
    (Context.Data.CurrentThreadId = NtCurrentThreadId) and
    BitTest(ExecInfo.Mask and SEE_MASK_FLAG_HINST_IS_SITE) and
    IUnknown(ExecInfo.hInstApp).QueryInterface(IServiceProvider,
    PassedProvider).IsSuccess;

  if ShouldHandle then
  begin
    PassedDirectory := ExecInfo.Directory;
    ExecInfo.Directory := PWideChar(Context.Data.Options.CurrentDirectory);

    if poUseWindowMode in Context.Data.Options.Flags then
      ExecInfo.Show := Context.Data.Options.WindowMode;

    if poSuspended in Context.Data.Options.Flags then
    begin
      // Create our extended service provider
      HookedProvider := ShlxMakeCreatingProcessProvider(
        Context.Data.Options.Flags, PassedProvider);

      ExecInfo.hInstApp := UIntPtr(HookedProvider);
    end;
  end;

  // Invoke the unhooked API
  Result := ShellExecuteExW(ExecInfo);

  if ShouldHandle then
  begin
    // Restore pointers in case the caller depends on them
    ExecInfo.Directory := PassedDirectory;
    ExecInfo.hInstApp := UIntPtr(PassedProvider);
  end;
end;

function RtlxAppxActivatorHost: String;
begin
  if RtlOsVersionAtLeast(OsWin11) then
    Result := 'twinui.appcore.dll'
  else
    Result := 'twinui.dll';
end;

function PkgxCreateProcessInPackage;
var
  Activator: IUnknown;
  ActivatorV1: IDesktopAppXActivatorV1;
  ActivatorV2: IDesktopAppXActivatorV2;
  ActivatorV3: IDesktopAppXActivatorV3;
  Flags: TDesktopAppxActivateOptions;
  WindowMode: TShowMode32;
  ImpersonationReverter: IAutoReleasable;
  ParentInfo: TProcessBasicInformation;
  HookContext: IAppxActivatorHookContext;
  hProcess: THandle;
begin
  Info := Default(TProcessInfo);

  // Create the activator without asking for any specific interface
  Result := ComxCreateInstanceWithFallback(RtlxAppxActivatorHost,
    CLSID_DesktopAppXActivator, IUnknown, Activator,
    'CLSID_DesktopAppXActivator');

  if not Result.IsSuccess then
    Exit;

  // Prepare parameters
  Flags := DAXAO_NONPACKAGED_EXE or DAXAO_NO_ERROR_UI;

  if poRequireElevation in Options.Flags then
    Flags := Flags or DAXAO_ELEVATE;

  if BitTest(Options.PackageBreakaway and
    PROCESS_CREATION_DESKTOP_APP_BREAKAWAY_DISABLE_PROCESS_TREE) then
    Flags := Flags or DAXAO_NONPACKAGED_EXE_PROCESS_TREE;

  // Determine the PID of the parent
  if Assigned(Options.hxParentProcess) then
  begin
    Result := NtxProcess.Query(Options.hxParentProcess, ProcessBasicInformation,
      ParentInfo);

    if not Result.IsSuccess then
      Exit;
  end
  else
    ParentInfo.UniqueProcessID := 0;

  // Extend the functionality via hooking
  if Assigned(Options.hxParentProcess) or (Options.CurrentDirectory <> '') or
    ([poUseWindowMode, poSuspended] * Options.Flags <> []) then
  begin
    // Allocate the hook context
    IMemory(HookContext) := Auto.Allocate<TAppxActivatorHookContext>;
    HookContext.Data.CurrentThreadId := NtCurrentThreadId;
    HookContext.Data.Options := Options;

    // Make a global weak reference
    AppxActivatorHookContext := HookContext;

    if (Options.CurrentDirectory <> '') or
      ([poUseWindowMode, poSuspended] * Options.Flags <> []) then
    begin
      // Install the hook on ShellExecuteExW to add parameters
      Result := RtlxInstallIATHook(HookContext.Data.ShellExecHookReverter,
        RtlxAppxActivatorHost, shell32, 'ShellExecuteExW',
        @HookedShellExecuteExW);

      if not Result.IsSuccess then
        Exit;
    end;

    if Assigned(Options.hxParentProcess) then
    begin
      HookContext.Data.TargetProcessId := ParentInfo.UniqueProcessID;

      // Install the hook on NtOpenProcess to provide the parent handle
      Result := RtlxInstallIATHook(HookContext.Data.OpenProcessHookReverter,
        kernelbase, ntdll, 'NtOpenProcess', @HookedNtOpenProcess);

      if not Result.IsSuccess then
        Exit;
    end;
  end;

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
      ParentInfo.UniqueProcessID,
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
      ParentInfo.UniqueProcessID,
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

  if not Result.IsSuccess then
    Exit;

  if hProcess <> 0 then
  begin
    // We get a process handle in response
    Include(Info.ValidFields, piProcessHandle);
    Info.hxProcess := Auto.CaptureHandle(hProcess);
  end;
end;

function PkgxActivateApplication;
const
  DLL_NAME: array [Boolean] of String = ('twinui.dll', 'twinui.appcore.dll');
var
  ActivationManager: IApplicationActivationManager;
  ProcessId: TProcessId32;
begin
  Result := ComxCreateInstanceWithFallback(
    DLL_NAME[RtlOsVersionAtLeast(OsWin81)],
    CLSID_ApplicationActivationManager,
    IApplicationActivationManager,
    ActivationManager
  );

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IApplicationActivationManager.ActivateApplication';
  Result.HResult := ActivationManager.ActivateApplication(
    PWideChar(AppUserModelId), RefStrOrNil(Arguments), Options, ProcessId);

  if Result.IsSuccess and Assigned(pProcessId) then
    pProcessId^ := ProcessId;
end;


end.
