unit NtUtils.Exec.Wmi;

interface

uses
  NtUtils.Exec, NtUtils.Exceptions;

type
  TExecCallWmi = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

implementation

uses
  Winapi.ActiveX, System.SysUtils, Ntapi.ntpsapi, Ntapi.ntstatus,
  Winapi.ProcessThreadsApi, NtUtils.Exec.Win32, NtUtils.Tokens.Impersonate,
  NtUtils.Objects, NtUiLib.Exceptions;

function GetWMIObject(const objectName: String; out Status: TNtxStatus):
  IDispatch;
var
  chEaten: Integer;
  BindCtx: IBindCtx;
  Moniker: IMoniker;
begin
  Status.Location := 'CreateBindCtx';
  Status.HResult := CreateBindCtx(0, BindCtx);

  if not Status.IsSuccess then
    Exit;

  Status.Location := 'MkParseDisplayName';
  Status.HResult := MkParseDisplayName(BindCtx, StringToOleStr(objectName),
    chEaten, Moniker);

  if not Status.IsSuccess then
    Exit;

  Status.Location := 'Moniker.BindToObject';
  Status.HResult := Moniker.BindToObject(BindCtx, nil, IDispatch, Result);
end;

function PrepareProcessStartup(ParamSet: IExecProvider): OleVariant;
var
  Status: TNtxStatus;
  Flags: Cardinal;
begin
  Result := GetWMIObject('winmgmts:Win32_ProcessStartup', Status);
  Status.RaiseOnError;

  // For some reason when specifing Win32_ProcessStartup.CreateFlags
  // processes would not start without CREATE_BREAKAWAY_FROM_JOB.
  Flags := CREATE_BREAKAWAY_FROM_JOB;

  if ParamSet.Provides(ppCreateSuspended) and ParamSet.CreateSuspended then
    Flags := Flags or CREATE_SUSPENDED;

  Result.CreateFlags := Flags;

  if ParamSet.Provides(ppShowWindowMode) then
    Result.ShowWindow := ParamSet.ShowWindowMode;
end;

function PrepareCurrentDir(ParamSet: IExecProvider): String;
begin
  if ParamSet.Provides(ppCurrentDirectory) then
    Result := ParamSet.CurrentDircetory
  else
    Result := GetCurrentDir;
end;

{ TExecCallWmi }

class function TExecCallWmi.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  objProcess: OleVariant;
  hxOldToken: IHandle;
  ProcessId: Integer;
begin
  if ParamSet.Provides(ppToken) and Assigned(ParamSet.Token) then
  begin
    // Backup current impersonation
    hxOldToken := NtxBackupImpersonation(NtCurrentThread);

    // Impersonate the passed token
    Result := NtxImpersonateAnyToken(ParamSet.Token.Handle);

    if not Result.IsSuccess then
      Exit;
  end;

  objProcess := GetWMIObject('winmgmts:Win32_Process', Result);

  if Result.IsSuccess then
  try
    objProcess.Create(
      PrepareCommandLine(ParamSet),
      PrepareCurrentDir(ParamSet),
      PrepareProcessStartup(ParamSet),
      ProcessId
    );
  except
    on E: Exception do
    begin
      Result.Location := 'winmgmts:Win32_Process.Create';
      Result.Status := STATUS_UNSUCCESSFUL;
    end;
  end;

  // Revert impersonation
  if ParamSet.Provides(ppToken) then
    NtxRestoreImpersonation(NtCurrentThread, hxOldToken);

  // Only process ID is available to return to the caller
  if Result.IsSuccess then
    with Info do
    begin
      ClientId.UniqueProcess := ProcessId;
      ClientId.UniqueThread := 0;
      hxProcess := nil;
      hxThread := nil;
    end;
end;

class function TExecCallWmi.Supports(Parameter: TExecParam): Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory, ppToken, ppCreateSuspended,
    ppShowWindowMode:
      Result := True;
  else
    Result := False;
  end;
end;

end.
