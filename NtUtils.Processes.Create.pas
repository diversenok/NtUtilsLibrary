unit NtUtils.Processes.Create;

{
  Base definitions for various process creation techniques.
}

interface

uses
  Ntapi.ntdef, Winapi.WinUser, Winapi.ProcessThreadsApi, NtUtils;

type
  TProcessCreateFlags = set of (
    poNativePath,
    poForceCommandLine,
    poSuspended,
    poInheritHandles,
    poBreakawayFromJob,
    poNewConsole,
    poUseWindowMode,
    poRequireElevation,
    poRunAsInvokerOn,
    poRunAsInvokerOff
  );

  TProcessInfo = record
    ClientId: TClientId;
    hxProcess, hxThread: IHandle;
  end;

  TPtAttributes = record
    hxParentProcess: IHandle;
    HandleList: TArray<IHandle>;
    Mitigations: UInt64;
    Mitigations2: UInt64;         // Win 10 TH1+
    ChildPolicy: Cardinal;        // Win 10 TH1+
    AppContainer: ISid;           // Win 8+
    Capabilities: TArray<TGroup>; // Win 8+
    LPAC: Boolean;                // Win 10 TH1+
  end;

  TCreateProcessOptions = record
    Application, Parameters: String;
    Flags: TProcessCreateFlags;
    hxToken: IHandle;
    CurrentDirectory: String;
    Environment: IEnvironment;
    ProcessSecurity, ThreadSecurity: ISecDesc;
    Desktop: String;
    WindowMode: TShowMode;
    Attributes: TPtAttributes;
    LogonFlags: TProcessLogonFlags;
    Domain, Username, Password: String;
  end;

  // A prototype for process creation routines
  TCreateProcessMethod = function (
    const Options: TCreateProcessOptions;
    out Info: TProcessInfo
  ): TNtxStatus;

// Temporarily set pr remove a compatibility layer to control elevation requests
function RtlxApplyCompatLayer(
  ForceOn: Boolean;
  ForceOff: Boolean;
  out Reverter: IAutoReleasable
): TNtxStatus;

// Construct a command line from the process options
procedure PrepareCommandLine(
  out Application: String;
  out CommandLine: String;
  const Options: TCreateProcessOptions
);

implementation

uses
  NtUtils.Environment, NtUtils.SysUtils;

function RtlxSetRunAsInvoker(
  Enable: Boolean;
  out Reverter: IAutoReleasable
): TNtxStatus;
var
  OldEnvironment: IEnvironment;
  Layer: String;
begin
  // Backup the existing environment
  Result := RtlxCreateEnvironment(OldEnvironment, True);

  if not Result.IsSuccess then
    Exit;

  if Enable then
    Layer := 'RunAsInvoker'
  else
    Layer := '';

  // Overwrite the compatibility layer
  Result := RtlxSetVariableEnvironment(RtlxCurrentEnvironment, '__COMPAT_LAYER',
    Layer);

  // Revert to the old environment later
  if Result.IsSuccess then
    Reverter := TDelayedOperation.Delay(
      procedure
      begin
        RtlxSetCurrentEnvironment(OldEnvironment);
      end
    );
end;

function RtlxApplyCompatLayer;
begin
  if ForceOn then
    Result := RtlxSetRunAsInvoker(True, Reverter)
  else if ForceOff then
    Result := RtlxSetRunAsInvoker(False, Reverter)
  else
    Result.Status := STATUS_SUCCESS;
end;

procedure PrepareCommandLine;
begin
  if poNativePath in Options.Flags then
    Application := RtlxNtPathToDosPath(Options.Application);

  // Either construct the command line or use the supplied one
  if poForceCommandLine in Options.Flags then
    CommandLine := Options.Parameters
  else
    CommandLine := '"' + Options.Application + '" ' + Options.Parameters;
end;

end.
