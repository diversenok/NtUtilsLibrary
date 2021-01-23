unit NtUtils.Processes.Create;

interface

uses
  Ntapi.ntdef, Winapi.WinUser, Winapi.ProcessThreadsApi, NtUtils;

const
  PROCESS_OPTION_NATIVE_PATH = $0001;
  PROCESS_OPTION_FORCE_COMMAND_LINE = $0002;
  PROCESS_OPTION_SUSPENDED = $0004;
  PROCESS_OPTION_INHERIT_HANDLES = $0008;
  PROCESS_OPTION_BREAKAWAY_FROM_JOB = $00010;
  PROCESS_OPTION_NEW_CONSOLE = $0020;
  PROCESS_OPTION_USE_WINDOW_MODE = $0040;
  PROCESS_OPTION_REQUIRE_ELEVATION = $0080;
  PROCESS_OPTION_RUN_AS_INVOKER_ON = $0100;
  PROCESS_OPTION_RUN_AS_INVOKER_OFF = $0200;

type
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
    Flags: Cardinal; // PROCESS_OPTIONS_*
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
  TCreateProcessMethod = function (const Options: TCreateProcessOptions;
    out Info: TProcessInfo): TNtxStatus;

// Temporarily set pr remove a compatibility layer to control elevation requests
function RtlxApplyCompatLayer(const Options: TCreateProcessOptions;
  out Reverter: IAutoReleasable): TNtxStatus;

implementation

uses
  NtUtils.Environment;

function RtlxSetRunAsInvoker(Enable: Boolean; out Reverter: IAutoReleasable):
  TNtxStatus;
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
    Reverter := TDelayedOperation.Create(
      procedure
      begin
        RtlxSetCurrentEnvironment(OldEnvironment);
      end
    );
end;

function RtlxApplyCompatLayer(const Options: TCreateProcessOptions;
  out Reverter: IAutoReleasable): TNtxStatus;
begin
  if Options.Flags and PROCESS_OPTION_RUN_AS_INVOKER_ON <> 0 then
    Result := RtlxSetRunAsInvoker(True, Reverter)
  else if Options.Flags and PROCESS_OPTION_RUN_AS_INVOKER_OFF <> 0 then
    Result := RtlxSetRunAsInvoker(False, Reverter)
  else
    Result.Status := STATUS_SUCCESS;
end;

end.
