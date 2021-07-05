unit NtUtils.Processes.Create.Native;

{
  The module provides support for process creation via Native API.
}

interface

uses
  Winapi.WinNt, Ntapi.ntrtl, NtUtils, NtUtils.Processes.Create,
  DelphiUtils.AutoObjects;

type
  IRtlUserProcessParamers = IMemory<PRtlUserProcessParameters>;

// Allocate user process parameters
function RtlxCreateProcessParameters(
  const Options: TCreateProcessOptions;
  out xMemory: IRtlUserProcessParamers
): TNtxStatus;

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
  NtUtils.Files, NtUtils.Objects, NtUtils.Threads, NtUtils.Ldr;

{ Process Parameters }

type
  TAutoUserProcessParams = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

procedure TAutoUserProcessParams.Release;
begin
  RtlDestroyProcessParameters(FData);
  inherited;
end;

function RtlxCreateProcessParameters;
var
  Buffer: PRtlUserProcessParameters;
begin
  Result.Location := 'RtlCreateProcessParametersEx';
  Result.Status := RtlCreateProcessParametersEx(
    Buffer,
    TNtUnicodeString.From(Options.ApplicationNative),
    nil, // DllPath
    RefNtStrOrNil(TNtUnicodeString.From(Options.CurrentDirectory)),
    RefNtStrOrNil(TNtUnicodeString.From(Options.CommandLine)),
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    nil, // WindowTitile
    RefNtStrOrNil(TNtUnicodeString.From(Options.Desktop)),
    nil, // ShellInfo
    nil, // RuntimeData
    RTL_USER_PROC_PARAMS_NORMALIZED
  );

  if not Result.IsSuccess then
    Exit;

  IMemory(xMemory) := TAutoUserProcessParams.Capture(Buffer, 0);

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
  ProcessParams: IRtlUserProcessParamers;
  ProcessInfo: TRtlUserProcessInformation;
begin
  Result := RtlxCreateProcessParameters(Options, ProcessParams);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlCreateUserProcess';
  Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
  Result.Status := RtlCreateUserProcess(
    TNtUnicodeString.From(Options.ApplicationNative),
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
  ProcessParams: IRtlUserProcessParamers;
  ProcessInfo: TRtlUserProcessInformation;
  ParamsEx: TRtlUserProcessExtendedParameters;
begin
  Result := LdrxCheckNtDelayedImport('RtlCreateUserProcessEx');

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCreateProcessParameters(Options, ProcessParams);

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
    TNtUnicodeString.From(Options.ApplicationNative),
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
