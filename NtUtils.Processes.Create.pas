unit NtUtils.Processes.Create;

interface

uses
  Ntapi.ntdef, Winapi.WinUser, Winapi.ProcessThreadsApi, NtUtils;

const
  PROCESS_OPTIONS_NATIVE_PATH = $0001;
  PROCESS_OPTIONS_FORCE_COMMAND_LINE = $0002;
  PROCESS_OPTIONS_SUSPENDED = $0004;
  PROCESS_OPTIONS_INHERIT_HANDLES = $0008;
  PROCESS_OPTIONS_BREAKAWAY_FROM_JOB = $00010;
  PROCESS_OPTIONS_NEW_CONSOLE = $0020;
  PROCESS_OPTIONS_USE_WINDOW_MODE = $0040;
  PROCESS_OPTION_REQUIRE_ELEVATION = $0080;
  PROCESS_OPTIONS_RUN_AS_INVOKER = $0100; // TODO, maybe inherit option?

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

implementation

end.
