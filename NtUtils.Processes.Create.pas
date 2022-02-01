unit NtUtils.Processes.Create;

{
  Base definitions for various process creation techniques.
}

interface

uses
  Ntapi.ntdef, Ntapi.Ntpsapi, Ntapi.ntseapi, Ntapi.WinUser,
  Ntapi.ProcessThreadsApi, NtUtils;

type
  TNewProcessFlags = set of (
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
    hxProcess: IHandle;
    hxThread: IHandle;
  end;

  TPtAttributes = record
    [Access(PROCESS_CREATE_PROCESS)] hxParentProcess: IHandle;
    [Access(JOB_OBJECT_ASSIGN_PROCESS)] hxJob: IHandle;
    [Access(SECTION_MAP_EXECUTE)] hxSection: IHandle;
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
    Flags: TNewProcessFlags;
    [Access(TOKEN_CREATE_PROCESS)] hxToken: IHandle;
    CurrentDirectory: String;
    Environment: IEnvironment;
    ProcessSecurity, ThreadSecurity: ISecurityDescriptor;
    Desktop: String;
    WindowMode: TShowMode;
    Attributes: TPtAttributes;
    LogonFlags: TProcessLogonFlags;
    Domain, Username, Password: String;
    function ApplicationWin32: String;
    function ApplicationNative: String;
    function CommandLine: String;
  end;

  // A prototype for process creation routines
  TCreateProcessMethod = function (
    const Options: TCreateProcessOptions;
    out Info: TProcessInfo
  ): TNtxStatus;

  TSupportedCreateProcessOptions = (
    spoSuspended,
    spoInheritHandles,
    spoBreakawayFromJob,
    spoNewConsole,
    spoRequireElevation,
    spoRunAsInvoker,
    spoEnvironment,
    spoSecurity,
    spoWindowMode,
    spoDesktop,
    spoToken,
    spoParentProcess,
    spoJob,
    spoSection,
    spoHandleList,
    spoMitigationPolicies,
    spoAppContainer,
    spoCredentials
  );

  TCreateProcessOptionMode = (
    omOptional,
    omRequired
  );

  // Annotation for indicating supported options for a process creation routine
  SupportedOptionAttribute = class (TCustomAttribute)
    Option: TSupportedCreateProcessOptions;
    Mode: TCreateProcessOptionMode;
    constructor Create(
      Option: TSupportedCreateProcessOptions;
      Mode: TCreateProcessOptionMode = omOptional
    );
  end;

// Temporarily set or remove a compatibility layer to control elevation requests
function RtlxApplyCompatLayer(
  ForceOn: Boolean;
  ForceOff: Boolean;
  out Reverter: IAutoReleasable
): TNtxStatus;

implementation

uses
  NtUtils.Environment, NtUtils.SysUtils, NtUtils.Files;

{ TCreateProcessOptions }

function TCreateProcessOptions.ApplicationNative;
begin
  if poNativePath in Flags then
    Result := Application
  else
    Result := RtlxDosPathToNativePath(Application);
end;

function TCreateProcessOptions.ApplicationWin32;
begin
  if poNativePath in Flags then
    Result := RtlxNativePathToDosPath(Application)
  else
    Result := Application;
end;

function TCreateProcessOptions.CommandLine;
begin
  if poForceCommandLine in Flags then
    Result := Parameters
  else
  begin
    Result := '"' + ApplicationWin32 + '"';

    if Parameters <> '' then
      Result := Result + ' ' + Parameters;
  end;
end;

{ SupportedOptionAttribute }

constructor SupportedOptionAttribute.Create;
begin
  Self.Option := Option;
  Self.Mode := Mode;
end;

{ Functions }

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
    Reverter := Auto.Delay(
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

end.
