unit NtUtils.Processes.Create.Shell;

{
  The module provides support for process creation via Shell API
}

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Create a new process via ShellExecCmdLine
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoRunAsInvoker)]
[SupportedOption(spoWindowMode)]
function ShlxExecuteCmd(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via ShellExecuteExW
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoNewConsole)]
[SupportedOption(spoRequireElevation)]
[SupportedOption(spoRunAsInvoker)]
[SupportedOption(spoWindowMode)]
function ShlxExecute(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinError, Ntapi.ShellApi, Ntapi.WinUser, Ntapi.ObjIdl,
  Ntapi.ProcessThreadsApi, NtUtils.Objects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function ShlxExecuteCmd;
var
  ShowMode: TShowMode32;
  SeclFlags: TSeclFlags;
  RunAsInvoker: IAutoReleasable;
begin
  Info := Default(TProcessInfo);

  // Allow running as invoker
  Result := RtlxApplyCompatLayer(
    poRunAsInvokerOn in Options.Flags,
    poRunAsInvokerOff in Options.Flags,
    RunAsInvoker
  );

  if not Result.IsSuccess then
    Exit;

  // Always set window mode to something
  if poUseWindowMode in Options.Flags then
    ShowMode := Options.WindowMode
  else
    ShowMode := TShowMode32.SW_SHOW_DEFAULT;

  SeclFlags := SECL_NO_UI;

  // Request elevation
  if poRequireElevation in Options.Flags then
    SeclFlags := SeclFlags or SECL_RUNAS;

  Result.Location := 'ShellExecCmdLine';
  Result.HResult := ShellExecCmdLine(
    0,
    PWideChar(Options.CommandLine),
    PWideChar(Options.CurrentDirectory),
    ShowMode,
    nil,
    SeclFlags
  );

  // No information about the new process is available
end;

type
  TCreatingProcessCallback = reference to function (
    [in] const cpi: ICreateProcessInputs
  ): HResult;

  TCreatingProcess = class (TInterfacedObject, ICreatingProcess)
  private
    FCallback: TCreatingProcessCallback;
  public
    function OnCreating(
      [in] const cpi: ICreateProcessInputs
    ): HResult; stdcall;

    constructor Create(
      const Callback: TCreatingProcessCallback
    );
  end;

  TCreatingProcessProvider = class (TInterfacedObject, IServiceProvider)
  private
    FCallback: TCreatingProcessCallback;
  public
    function QueryService(
      [in] const guidService: TGuid;
      [in] const riid: TIid;
      [out] out vObject
    ): HResult; stdcall;

    constructor Create(
      const Callback: TCreatingProcessCallback
    );
  end;

constructor TCreatingProcess.Create;
begin
  inherited Create;
  FCallback := Callback;
end;

function TCreatingProcess.OnCreating;
begin
  if Assigned(cpi) and Assigned(FCallback) then
    Result := FCallback(cpi)
  else
    Result := E_INVALIDARG;
end;

constructor TCreatingProcessProvider.Create;
begin
  inherited Create;
  FCallback := Callback;
end;

function TCreatingProcessProvider.QueryService;
begin
  Result := E_NOINTERFACE;

  if (guidService = SID_ExecuteCreatingProcess) and
    (riid = ICreatingProcess) then
  begin
    // Notify ShellExecuteEx that we want to adjust process creation flags
    ICreatingProcess(vObject) := TCreatingProcess.Create(FCallback);
    Result := S_OK;
  end;
end;

function ShlxpMakeServiceProvider(
  const Flags: TNewProcessFlags
): IServiceProvider;
begin
  Result := TCreatingProcessProvider.Create(
    function (const cpi: ICreateProcessInputs): HResult
    var
      FlagsToAdd: TProcessCreateFlags;
    begin
      FlagsToAdd := 0;

      if poSuspended in Flags then
        FlagsToAdd := FlagsToAdd or CREATE_SUSPENDED;

      if poBreakawayFromJob in Flags then
        FlagsToAdd := FlagsToAdd or CREATE_BREAKAWAY_FROM_JOB;

      Result := cpi.AddCreateFlags(FlagsToAdd);
    end
  );
end;

function ShlxExecute;
var
  ExecInfo: TShellExecuteInfoW;
  RunAsInvoker: IAutoReleasable;
  CustomProvider: IServiceProvider;
begin
  Info := Default(TProcessInfo);
  ExecInfo := Default(TShellExecuteInfoW);

  ExecInfo.cbSize := SizeOf(TShellExecuteInfoW);
  ExecInfo.Mask := SEE_MASK_NOASYNC or SEE_MASK_UNICODE or
    SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;

  ExecInfo.FileName := PWideChar(Options.ApplicationWin32);
  ExecInfo.Parameters := PWideChar(Options.Parameters);
  ExecInfo.Directory := PWideChar(Options.CurrentDirectory);

  // Always set window mode to something
  if poUseWindowMode in Options.Flags then
    ExecInfo.Show := Options.WindowMode
  else
    ExecInfo.Show := TShowMode32.SW_SHOW_DEFAULT;

  // SEE_MASK_NO_CONSOLE is opposite to CREATE_NEW_CONSOLE
  if not (poNewConsole in Options.Flags) then
    ExecInfo.Mask := ExecInfo.Mask or SEE_MASK_NO_CONSOLE;

  if [poSuspended, poBreakawayFromJob] * Options.Flags <> [] then
  begin
    CustomProvider := ShlxpMakeServiceProvider(Options.Flags);
    ExecInfo.Mask := ExecInfo.Mask or SEE_MASK_FLAG_HINST_IS_SITE;
    ExecInfo.hInstApp := UIntPtr(CustomProvider);
  end;

  // Request elevation
  if poRequireElevation in Options.Flags then
    ExecInfo.Verb := 'runas';

  // Allow running as invoker
  Result := RtlxApplyCompatLayer(
    poRunAsInvokerOn in Options.Flags,
    poRunAsInvokerOff in Options.Flags,
    RunAsInvoker
  );

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ShellExecuteExW';
  Result.Win32Result := ShellExecuteExW(ExecInfo);

  if not Result.IsSuccess then
    Exit;

  // We only conditionally get a handle to the process.
  if ExecInfo.hProcess <> 0 then
  begin
    Include(Info.ValidFields, piProcessHandle);
    Info.hxProcess := Auto.CaptureHandle(ExecInfo.hProcess);
  end;
end;

end.
