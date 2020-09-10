unit NtUtils.Exec.Win32;

interface

uses
  NtUtils, NtUtils.Exec;

type
  TExecCreateProcessAsUser = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

  TExecCreateProcessWithToken = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

  TRunAsInvoker = class(TInterfacedObject, IInterface)
  private const
    COMPAT_NAME = '__COMPAT_LAYER';
    COMPAT_VALUE = 'RunAsInvoker';
  private var
    OldValue: String;
    OldValuePresent: Boolean;
  public
    constructor SetCompatState(Enabled: Boolean);
    destructor Destroy; override;
  end;

implementation

uses
  Winapi.ProcessThreadsApi, Ntapi.ntstatus, NtUtils.Environment,
  NtUtils.Processes.Create.Win32;

procedure PrepareOptions(var Options: TCreateProcessOptions;
  ParamSet: IExecProvider);
begin
  Options := Default(TCreateProcessOptions);

  if ParamSet.Provides(ppCurrentDirectory) then
    Options.CurrentDirectory := ParamSet.CurrentDircetory;

  if ParamSet.Provides(ppDesktop) then
    Options.Desktop := ParamSet.Desktop;

  if ParamSet.Provides(ppToken) then
    Options.hxToken := ParamSet.Token;

  if ParamSet.Provides(ppParentProcess) then
    Options.Attributes.hxParentProcess := ParamSet.ParentProcess;

  if ParamSet.Provides(ppLogonFlags) then
    Options.LogonFlags := ParamSet.LogonFlags;

  if ParamSet.Provides(ppInheritHandles) then
    Options.InheritHandles := ParamSet.InheritHandles;

  if ParamSet.Provides(ppCreateSuspended) and ParamSet.CreateSuspended then
    Options.CreationFlags := Options.CreationFlags or CREATE_SUSPENDED;

  if ParamSet.Provides(ppBreakaway) and ParamSet.Breakaway then
    Options.CreationFlags := Options.CreationFlags or CREATE_BREAKAWAY_FROM_JOB;

  if ParamSet.Provides(ppNewConsole) and ParamSet.NewConsole then
    Options.CreationFlags := Options.CreationFlags or CREATE_NEW_CONSOLE;

  if ParamSet.Provides(ppShowWindowMode) then
  begin
    Options.StartupInfo.ShowWindow := ParamSet.ShowWindowMode;
    Options.StartupInfo.Flags := Options.StartupInfo.Flags or
      STARTF_USESHOWWINDOW;
  end;

  if ParamSet.Provides(ppEnvironment) then
    Options.Environment := ParamSet.Environment;
end;

{ TExecCreateProcessAsUser }

class function TExecCreateProcessAsUser.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  Options: TCreateProcessOptions;
  RunAsInvoker: IInterface;
begin
  PrepareOptions(Options, ParamSet);

  // Set RunAsInvoker compatibility mode. It will be reverted
  // after exiting from the current function.
  if ParamSet.Provides(ppRunAsInvoker) then
    RunAsInvoker := TRunAsInvoker.SetCompatState(ParamSet.RunAsInvoker);

  Result := AdvxCreateProcess(ParamSet.Application,
    PrepareCommandLine(ParamSet), Options, Info);
end;

class function TExecCreateProcessAsUser.Supports(Parameter: TExecParam):
  Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory, ppDesktop, ppToken, ppParentProcess,
    ppInheritHandles, ppCreateSuspended, ppBreakaway, ppNewConsole,
    ppShowWindowMode, ppRunAsInvoker, ppEnvironment:
      Result := True;
  else
    Result := False;
  end;
end;

{ TExecCreateProcessWithToken }

class function TExecCreateProcessWithToken.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  Options: TCreateProcessOptions;
begin
  PrepareOptions(Options, ParamSet);

  Result := AdvxCreateProcessWithToken(ParamSet.Application,
    PWideChar(PrepareCommandLine(ParamSet)), Options, Info);
end;

class function TExecCreateProcessWithToken.Supports(Parameter: TExecParam):
  Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory, ppDesktop, ppToken, ppLogonFlags,
    ppCreateSuspended, ppBreakaway, ppShowWindowMode, ppEnvironment:
      Result := True;
  else
    Result := False;
  end;
end;

{ TRunAsInvoker }

destructor TRunAsInvoker.Destroy;
var
  Env: IEnvironment;
begin
  Env := RtlxCurrentEnvironment;

  if OldValuePresent then
    RtlxSetVariableEnvironment(Env, COMPAT_NAME, OldValue)
  else
    RtlxDeleteVariableEnvironment(Env, COMPAT_NAME);

  inherited;
end;

constructor TRunAsInvoker.SetCompatState(Enabled: Boolean);
var
  Env: IEnvironment;
  Status: TNtxStatus;
begin
  Env := RtlxCurrentEnvironment;

  // Save the current state
  Status := RtlxQueryVariableEnvironment(Env, COMPAT_NAME, OldValue);

  if Status.IsSuccess then
    OldValuePresent := True
  else if Status.Status = STATUS_VARIABLE_NOT_FOUND then
    OldValuePresent := False;

  // Set the new state
  if Enabled then
    RtlxSetVariableEnvironment(Env, COMPAT_NAME, COMPAT_VALUE)
  else if OldValuePresent then
    RtlxDeleteVariableEnvironment(Env, COMPAT_NAME);
end;

end.
