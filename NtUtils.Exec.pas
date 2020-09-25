unit NtUtils.Exec;

interface

uses
  Winapi.WinUser, Winapi.ProcessThreadsApi, NtUtils,
  NtUtils.Processes.Create;

type
  TExecParam = (
    ppParameters, ppCurrentDirectory, ppDesktop, ppToken, ppParentProcess,
    ppLogonFlags, ppInheritHandles, ppCreateSuspended, ppBreakaway,
    ppNewConsole, ppRequireElevation, ppShowWindowMode, ppRunAsInvoker,
    ppEnvironment, ppAppContainer
  );

  IExecProvider = interface
    function Provides(Parameter: TExecParam): Boolean;
    function Application: String;
    function Parameters: String;
    function CurrentDircetory: String;
    function Desktop: String;
    function Token: IHandle;
    function ParentProcess: IHandle;
    function LogonFlags: TProcessLogonFlags;
    function InheritHandles: Boolean;
    function CreateSuspended: Boolean;
    function Breakaway: Boolean;
    function NewConsole: Boolean;
    function RequireElevation: Boolean;
    function ShowWindowMode: TShowMode;
    function RunAsInvoker: Boolean;
    function Environment: IEnvironment;
    function AppContainer: ISid;
  end;

  TProcessInfo = NtUtils.Processes.Create.TProcessInfo;

  TExecMethod = class
    class function Supports(Parameter: TExecParam): Boolean; virtual; abstract;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; virtual; abstract;
  end;
  TExecMethodClass = class of TExecMethod;

  TExecParamSet = set of TExecParam;

  TDefaultExecProvider = class(TInterfacedObject, IExecProvider)
  public
    UseParams: TExecParamSet;
    strApplication: String;
    strParameters: String;
    strCurrentDircetory: String;
    strDesktop: String;
    hxToken: IHandle;
    hxParentProcess: IHandle;
    dwLogonFlags: TProcessLogonFlags;
    bInheritHandles: Boolean;
    bCreateSuspended: Boolean;
    bBreakaway: Boolean;
    bNewConsole: Boolean;
    bRequireElevation: Boolean;
    wShowWindowMode: TShowMode;
    bRunAsInvoker: Boolean;
    objEnvironment: IEnvironment;
    pAppContainer: ISid;
  public
    function Provides(Parameter: TExecParam): Boolean; virtual;
    function Application: String; virtual;
    function Parameters: String; virtual;
    function CurrentDircetory: String; virtual;
    function Desktop: String; virtual;
    function Token: IHandle; virtual;
    function ParentProcess: IHandle; virtual;
    function LogonFlags: TProcessLogonFlags; virtual;
    function InheritHandles: Boolean; virtual;
    function CreateSuspended: Boolean; virtual;
    function Breakaway: Boolean; virtual;
    function NewConsole: Boolean; virtual;
    function RequireElevation: Boolean; virtual;
    function ShowWindowMode: TShowMode; virtual;
    function RunAsInvoker: Boolean; virtual;
    function Environment: IEnvironment; virtual;
    function AppContainer: ISid; virtual;
  end;

function PrepareCommandLine(ParamSet: IExecProvider): String;

implementation

uses
  NtUtils.Environment;

{ TDefaultExecProvider }

function TDefaultExecProvider.AppContainer: ISid;
begin
  Result := pAppContainer;
end;

function TDefaultExecProvider.Application: String;
begin
  Result := strApplication;
end;

function TDefaultExecProvider.Breakaway: Boolean;
begin
  if ppBreakaway in UseParams then
    Result := bBreakaway
  else
    Result := False;
end;

function TDefaultExecProvider.CreateSuspended: Boolean;
begin
  if ppCreateSuspended in UseParams then
    Result := bCreateSuspended
  else
    Result := False;
end;

function TDefaultExecProvider.CurrentDircetory: String;
begin
  if ppCurrentDirectory in UseParams then
    Result := strCurrentDircetory
  else
    Result := '';
end;

function TDefaultExecProvider.Desktop: String;
begin
  if ppDesktop in UseParams then
    Result := strDesktop
  else
    Result := '';
end;

function TDefaultExecProvider.Environment: IEnvironment;
begin
  if ppEnvironment in UseParams then
    Result := objEnvironment
  else
    Result := RtlxCurrentEnvironment;
end;

function TDefaultExecProvider.InheritHandles: Boolean;
begin
  if ppInheritHandles in UseParams then
    Result := bInheritHandles
  else
    Result := False;
end;

function TDefaultExecProvider.LogonFlags: TProcessLogonFlags;
begin
  if ppLogonFlags in UseParams then
    Result := dwLogonFlags
  else
    Result := 0;
end;

function TDefaultExecProvider.NewConsole: Boolean;
begin
  Result := bNewConsole;
end;

function TDefaultExecProvider.Parameters: String;
begin
  if ppParameters in UseParams then
    Result := strParameters
  else
    Result := '';
end;

function TDefaultExecProvider.ParentProcess: IHandle;
begin
  if ppParentProcess in UseParams then
    Result := hxParentProcess
  else
    Result := nil;
end;

function TDefaultExecProvider.Provides(Parameter: TExecParam): Boolean;
begin
  Result := Parameter in UseParams;
end;

function TDefaultExecProvider.RequireElevation: Boolean;
begin
  if ppRequireElevation in UseParams then
    Result := bRequireElevation
  else
    Result := False;
end;

function TDefaultExecProvider.RunAsInvoker: Boolean;
begin
  if ppRunAsInvoker in UseParams then
    Result := bRunAsInvoker
  else
    Result := False;
end;

function TDefaultExecProvider.ShowWindowMode: TShowMode;
begin
  if ppShowWindowMode in UseParams then
    Result := wShowWindowMode
  else
    Result := SW_SHOW_DEFAULT;
end;

function TDefaultExecProvider.Token: IHandle;
begin
  if ppToken in UseParams then
    Result := hxToken
  else
    Result := nil;
end;

{ Functions }

function PrepareCommandLine(ParamSet: IExecProvider): String;
begin
  Result := '"' + ParamSet.Application + '"';
  if ParamSet.Provides(ppParameters) and (ParamSet.Parameters <> '') then
    Result := Result + ' ' + ParamSet.Parameters;
end;

end.
