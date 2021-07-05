unit NtUtils.Processes.Create.Native;

{
  The module provides support for process creation via Native API.
}

interface

uses
  Winapi.WinNt, Ntapi.ntrtl, NtUtils, NtUtils.Processes.Create;

// Create a new process via RtlCreateUserProcess
function RtlxCreateUserProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via RtlCreateUserProcessEx
function RtlxCreateUserProcessEx(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Fork the current process.
// The function returns STATUS_PROCESS_CLONED in the cloned process.
function RtlxCloneCurrentProcess(
  out Info: TProcessInfo;
  ProcessFlags: TRtlProcessCloneFlags = RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES;
  [opt] DebugPort: THandle = 0;
  [in, opt] ProcessSecurity: PSecurityDescriptor = nil;
  [in, opt] ThreadSecurity: PSecurityDescriptor = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntseapi, Ntapi.ntstatus, Winapi.ProcessThreadsApi,
  NtUtils.Files, DelphiUtils.AutoObjects, NtUtils.Objects, NtUtils.Threads,
  NtUtils.Ldr;

{ Process Parameters }

type
  IProcessParams = IMemory<PRtlUserProcessParameters>;

  TProcessParamAutoMemory = class (TCustomAutoMemory, IMemory)
    ImageName, CommandLine, CurrentDir, Desktop: String;
    ImageNameStr, CommandLineStr, CurrentDirStr, DesktopStr: TNtUnicodeString;
    Environment: IEnvironment;
    Initialized: Boolean;
    procedure Release; override;
  end;

procedure TProcessParamAutoMemory.Release;
begin
  // The external function allocates and initializes memory.
  // Free it only if it succeeded.
  if Initialized then
    RtlDestroyProcessParameters(FData);

  inherited;
end;

function PrepareImageName(
  const Options: TCreateProcessOptions;
  out ImageName: String;
  out ImageNameStr: TNtUnicodeString
): TNtxStatus;
begin
  ImageName := Options.Application;

  // TODO: reconstruct application name in case of forced command line

  if not (poNativePath in Options.Flags) then
  begin
    Result := RtlxDosPathToNtPathVar(ImageName);

    if not Result.IsSuccess then
      Exit;
  end
  else
    Result.Status := STATUS_SUCCESS;

  ImageNameStr := TNtUnicodeString.From(ImageName);
end;

function RtlxpCreateProcessParams(
  out xMemory: IProcessParams;
  const Options: TCreateProcessOptions
): TNtxStatus;
var
  Params: TProcessParamAutoMemory;
begin
  Params := TProcessParamAutoMemory.Create;
  IMemory(xMemory) := Params;

  // Application
  Result := PrepareImageName(Options, Params.ImageName, Params.ImageNameStr);

  if not Result.IsSuccess then
    Exit;

  // Command line
  if poForceCommandLine in Options.Flags then
    Params.CommandLine := Options.Parameters
  else
    Params.CommandLine := '"' + Options.Application + '" ' + Options.Parameters;

  // Other strings
  Params.CommandLine := Options.Parameters;
  Params.CommandLineStr := TNtUnicodeString.From(Params.CommandLine);
  Params.CurrentDir := Options.CurrentDirectory;
  Params.CurrentDirStr := TNtUnicodeString.From(Params.CurrentDir);
  Params.Desktop := Options.Desktop;
  Params.DesktopStr := TNtUnicodeString.From(Params.Desktop);

  // Allocate and prepare parameters
  Result.Location := 'RtlCreateProcessParametersEx';
  Result.Status := RtlCreateProcessParametersEx(
    PRtlUserProcessParameters(Params.FData),
    Params.ImageNameStr,
    nil, // DllPath
    RefNtStrOrNil(Params.CurrentDirStr),
    RefNtStrOrNil(Params.CommandLineStr),
    Auto.RefOrNil<PEnvironment>(Params.Environment),
    nil, // WindowTitile
    RefNtStrOrNil(Params.DesktopStr),
    nil, // ShellInfo
    nil, // RuntimeData
    0
  );

  if Result.IsSuccess then
    Params.Initialized := True;

  // Adjust window mode flags
  if poUseWindowMode in Options.Flags then
  begin
    xMemory.Data.WindowFlags := xMemory.Data.WindowFlags or STARTF_USESHOWWINDOW;
    xMemory.Data.ShowWindowFlags := Cardinal(Options.WindowMode);
  end;
end;

{ Process Creation }

function RtlxCreateUserProcess;
var
  Application: String;
  ProcessParams: IProcessParams;
  ProcessInfo: TRtlUserProcessInformation;
begin
  Application := Options.Application;

  // Convert Win32 paths of necessary
  if not (poNativePath in Options.Flags) then
  begin
    Result := RtlxDosPathToNtPathVar(Application);

    if not Result.IsSuccess then
      Exit;
  end;

  Result := RtlxpCreateProcessParams(ProcessParams, Options);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlCreateUserProcess';
  Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
  Result.Status := RtlCreateUserProcess(
    TNtUnicodeString.From(Application),
    OBJ_CASE_INSENSITIVE,
    ProcessParams.Data,
    Auto.RefOrNil<PSecurityDescriptor>(Options.ProcessSecurity),
    Auto.RefOrNil<PSecurityDescriptor>(Options.ThreadSecurity),
    HandleOrZero(Options.Attributes.hxParentProcess),
    poInheritHandles in Options.Flags,
    0,
    HandleOrZero(Options.hxToken),
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  // Capture the information about the new process
  Info.ClientId := ProcessInfo.ClientId;
  Info.hxProcess := NtxObject.Capture(ProcessInfo.Process);
  Info.hxThread := NtxObject.Capture(ProcessInfo.Thread);

  // Resume the process if necessary
  if not (poSuspended in Options.Flags) then
    NtxResumeThread(ProcessInfo.Thread);
end;

function RtlxCreateUserProcessEx;
var
  Application: String;
  ProcessParams: IProcessParams;
  ProcessInfo: TRtlUserProcessInformation;
  ParamsEx: TRtlUserProcessExtendedParameters;
begin
  Result := LdrxCheckNtDelayedImport('RtlCreateUserProcessEx');

  if not Result.IsSuccess then
    Exit;

  Application := Options.Application;

  // Convert Win32 paths of necessary
  if not (poNativePath in Options.Flags) then
  begin
    Result := RtlxDosPathToNtPathVar(Application);

    if not Result.IsSuccess then
      Exit;
  end;

  Result := RtlxpCreateProcessParams(ProcessParams, Options);

  if not Result.IsSuccess then
    Exit;

  ParamsEx := Default(TRtlUserProcessExtendedParameters);
  ParamsEx.Version := RTL_USER_PROCESS_EXTENDED_PARAMETERS_VERSION;
  ParamsEx.ProcessSecurityDescriptor :=
    Auto.RefOrNil<PSecurityDescriptor>(Options.ProcessSecurity);
  ParamsEx.ThreadSecurityDescriptor :=
    Auto.RefOrNil<PSecurityDescriptor>(Options.ThreadSecurity);
  ParamsEx.ParentProcess := HandleOrZero(Options.Attributes.hxParentProcess);
  ParamsEx.TokenHandle := HandleOrZero(Options.hxToken);
  ParamsEx.JobHandle := HandleOrZero(Options.Attributes.hxJob);

  Result.Location := 'RtlCreateUserProcessEx';
  Result.Status := RtlCreateUserProcessEx(
    TNtUnicodeString.From(Application),
    ProcessParams.Data,
    poInheritHandles in Options.Flags,
    @ParamsEx,
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  // Capture the information about the new process
  Info.ClientId := ProcessInfo.ClientId;
  Info.hxProcess := NtxObject.Capture(ProcessInfo.Process);
  Info.hxThread := NtxObject.Capture(ProcessInfo.Thread);

  // Resume the process if necessary
  if not (poSuspended in Options.Flags) then
    NtxResumeThread(ProcessInfo.Thread);
end;

function RtlxCloneCurrentProcess;
var
  RtlProcessInfo: TRtlUserProcessInformation;
begin
  Result.Location := 'RtlCloneUserProcess';
  Result.Status := RtlCloneUserProcess(ProcessFlags, ProcessSecurity,
    ThreadSecurity, DebugPort, RtlProcessInfo);

  if Result.IsSuccess and (Result.Status <> STATUS_PROCESS_CLONED) then
  begin
    Info.ClientId := RtlProcessInfo.ClientId;
    Info.hxProcess := NtxObject.Capture(RtlProcessInfo.Process);
    Info.hxThread := NtxObject.Capture(RtlProcessInfo.Thread);
  end;
end;

end.
