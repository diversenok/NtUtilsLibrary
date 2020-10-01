unit NtUtils.Exec.Wmi;

interface

uses
  NtUtils, NtUtils.Exec;

type
  TExecCallWmi = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntstatus, Winapi.ProcessThreadsApi, NtUtils.Files,
  NtUtils.Tokens.Impersonate, NtUtils.Objects, NtUtils.Com.Dispatch,
  Winapi.WinError, Winapi.WinNt, Ntapi.ntdef, Winapi.ObjBase;

function PrepareProcessStartup(ParamSet: IExecProvider;
  out Dispatch: IDispatch): TNtxStatus;
var
  Flags: Cardinal;
begin
  Result := DispxBindToObject('winmgmts:Win32_ProcessStartup', Dispatch);

  if not Result.IsSuccess then
    Exit;

  // For some reason, when specifing Win32_ProcessStartup.CreateFlags,
  // processes would not start without CREATE_BREAKAWAY_FROM_JOB.
  Flags := CREATE_BREAKAWAY_FROM_JOB;

  if ParamSet.Provides(ppCreateSuspended) and ParamSet.CreateSuspended then
    Flags := Flags or CREATE_SUSPENDED;

  Result := DispxPropertySet(Dispatch, 'CreateFlags', VarFromCardinal(Flags));

  if not Result.IsSuccess then
    Exit;

  if ParamSet.Provides(ppShowWindowMode) then
    Result := DispxPropertySet(Dispatch, 'ShowWindow',
      VarFromWord(Word(ParamSet.ShowWindowMode)));
end;

function PrepareCurrentDir(ParamSet: IExecProvider): String;
begin
  if ParamSet.Provides(ppCurrentDirectory) then
    Result := ParamSet.CurrentDircetory
  else
    Result := RtlxGetCurrentPathPeb;
end;

{ TExecCallWmi }

class function TExecCallWmi.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  Startup, Process: IDispatch;
  hxOldToken: IHandle;
  ProcessId: Integer;
  CurrentDir, CommandLine: WideString;
  VarResult: TVarData;
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

  Result := PrepareProcessStartup(ParamSet, Startup);

  if Result.IsSuccess then
    Result := DispxBindToObject('winmgmts:Win32_Process', Process);

  if Result.IsSuccess then
  begin
    CurrentDir := PrepareCurrentDir(ParamSet);
    CommandLine := PrepareCommandLine(ParamSet);

    Result := DispxMethodCall(Process, 'Create', [
      VarFromWideString(CommandLine),
      VarFromWideString(CurrentDir),
      VarFromIDispatch(Startup),
      VarFromIntegerRef(ProcessId)],
      @VarResult);

    if Result.IsSuccess then
    begin
      Result.Location := 'Win32_Process.Create';
      Result.Status := STATUS_UNSUCCESSFUL;

      // This method returns some nonsensical error codes...
      if VarResult.VType and varTypeMask = varInteger then
      case VarResult.VInteger of
        0: Result.Status := STATUS_SUCCESS;
        2: Result.WinError := ERROR_ACCESS_DENIED;
        3: Result.WinError := ERROR_PRIVILEGE_NOT_HELD;
        9: Result.WinError := ERROR_PATH_NOT_FOUND;
        21: Result.WinError := ERROR_INVALID_PARAMETER;
      end;

      VariantClear(VarResult);
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
