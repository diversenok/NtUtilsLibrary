unit NtUtils.Exec.Nt;

interface

uses
  NtUtils, NtUtils.Exec;

type
  TExecRtlCreateUserProcess = class(TExecMethod)
    class function Supports(Parameter: TExecParam): Boolean; override;
    class function Execute(ParamSet: IExecProvider; out Info: TProcessInfo):
      TNtxStatus; override;
  end;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntpsapi, Ntapi.ntobapi,
  Winapi.ProcessThreadsApi, Ntapi.ntseapi, NtUtils.Objects;

function RefStr(const Str: TNtUnicodeString; Present: Boolean):
  PNtUnicodeString; inline;
begin
  if Present then
    Result := @Str
  else
    Result := nil;
end;

{ TExecRtlCreateUserProcess }

class function TExecRtlCreateUserProcess.Execute(ParamSet: IExecProvider;
  out Info: TProcessInfo): TNtxStatus;
var
  hToken, hParent: THandle;
  ProcessParams: PRtlUserProcessParameters;
  ProcessInfo: TRtlUserProcessInformation;
  NtImageName, CurrDir, CmdLine, Desktop: TNtUnicodeString;
begin
  // Convert the filename to native format
  Result.Location := 'RtlDosPathNameToNtPathName_U_WithStatus';
  Result.Status := RtlDosPathNameToNtPathName_U_WithStatus(
    PWideChar(ParamSet.Application), NtImageName, nil, nil);

  if not Result.IsSuccess then
    Exit;

  CmdLine := TNtUnicodeString.From(PrepareCommandLine(ParamSet));

  if ParamSet.Provides(ppCurrentDirectory) then
    CurrDir := TNtUnicodeString.From(ParamSet.CurrentDircetory);

  if ParamSet.Provides(ppDesktop) then
    Desktop := TNtUnicodeString.From(ParamSet.Desktop);

  // Construct parameters
  Result.Location := 'RtlCreateProcessParametersEx';
  Result.Status := RtlCreateProcessParametersEx(
    ProcessParams,
    NtImageName,
    nil,
    RefStr(CurrDir, ParamSet.Provides(ppCurrentDirectory)),
    @CmdLine,
    nil,
    nil,
    RefStr(Desktop, ParamSet.Provides(ppDesktop)),
    nil,
    nil,
    0
  );

  if not Result.IsSuccess then
  begin
    RtlFreeUnicodeString(NtImageName);
    Exit;
  end;

  if ParamSet.Provides(ppShowWindowMode) then
  begin
    ProcessParams.WindowFlags := STARTF_USESHOWWINDOW;
    ProcessParams.ShowWindowFlags := Cardinal(ParamSet.ShowWindowMode);
  end;

  if ParamSet.Provides(ppToken) and Assigned(ParamSet.Token) then
    hToken := ParamSet.Token.Handle
  else
    hToken := 0;

  if ParamSet.Provides(ppParentProcess) and Assigned(ParamSet.ParentProcess) then
    hParent := ParamSet.ParentProcess.Handle
  else
    hParent := 0;

  // Create the process
  Result.Location := 'RtlCreateUserProcess';
  Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;

  Result.Status := RtlCreateUserProcess(
    NtImageName,
    OBJ_CASE_INSENSITIVE,
    ProcessParams,
    nil,
    nil,
    hParent,
    ParamSet.Provides(ppInheritHandles) and ParamSet.InheritHandles,
    0,
    hToken,
    ProcessInfo
  );

  RtlDestroyProcessParameters(ProcessParams);
  RtlFreeUnicodeString(NtImageName);

  if not Result.IsSuccess then
    Exit;

  // The process was created in a suspended state.
  // Resume it unless the caller explicitly states it should stay suspended.
  if not ParamSet.Provides(ppCreateSuspended) or
    not ParamSet.CreateSuspended then
    NtResumeThread(ProcessInfo.Thread, nil);

  with Info do
  begin
    ClientId := ProcessInfo.ClientId;
    hxProcess := TAutoHandle.Capture(ProcessInfo.Process);
    hxThread := TAutoHandle.Capture(ProcessInfo.Thread);
  end;
end;

class function TExecRtlCreateUserProcess.Supports(Parameter: TExecParam):
  Boolean;
begin
  case Parameter of
    ppParameters, ppCurrentDirectory, ppDesktop, ppToken, ppParentProcess,
    ppInheritHandles, ppCreateSuspended, ppShowWindowMode:
      Result := True;
  else
    Result := False;
  end;
end;

end.
