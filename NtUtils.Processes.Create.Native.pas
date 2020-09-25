unit NtUtils.Processes.Create.Native;

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Create a new process via RtlCreateUserProcess
function RtlxCreateUserProcess(const Options: TCreateProcessOptions;
  out Info: TProcessInfo): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntrtl, Ntapi.ntdef, Ntapi.ntseapi, Ntapi.ntstatus,
  Winapi.ProcessThreadsApi, NtUtils.Files, DelphiUtils.AutoObject,
  NtUtils.Objects, NtUtils.Threads;

{ Process Parameters }

type
  IProcessParams = IMemory<PRtlUserProcessParameters>;

  TProcessParamAutoMemory = class (TCustomAutoMemory, IMemory)
    ImageName, CommandLine, CurrentDir, Desktop: String;
    ImageNameStr, CommandLineStr, CurrentDirStr, DesktopStr: TNtUnicodeString;
    Environment: IEnvironment;
    Initialized: Boolean;
    destructor Destroy; override;
  end;

destructor TProcessParamAutoMemory.Destroy;
begin
  // The external function allocates and initializes memory.
  // Free it only if it succeeded.
  if Initialized then
  begin
    RtlDestroyProcessParameters(FAddress);
    inherited;
  end;
end;

function RefStrOrNil(const [ref] S: TNtUnicodeString): PNtUnicodeString;
begin
  if S.Length <> 0 then
    Result := @S
  else
    Result := nil;
end;

function PrepareImageName(const Options: TCreateProcessOptions;
  out ImageName: String; out ImageNameStr: TNtUnicodeString): TNtxStatus;
begin
  ImageName := Options.Application;

  // TODO: reconstruct application name in case of forced command line

  if Options.Flags and PROCESS_OPTIONS_NATIVE_PATH = 0 then
  begin
    Result := RtlxDosPathToNtPathVar(ImageName);

    if not Result.IsSuccess then
      Exit;
  end
  else
    Result.Status := STATUS_SUCCESS;

  ImageNameStr := TNtUnicodeString.From(ImageName);
end;

function RtlxpCreateProcessParams(out xMemory: IProcessParams;
  const Options: TCreateProcessOptions): TNtxStatus;
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
  if Options.Flags and PROCESS_OPTIONS_FORCE_COMMAND_LINE = 0 then
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
    PRtlUserProcessParameters(Params.FAddress),
    Params.ImageNameStr,
    nil, // DllPath
    RefStrOrNil(Params.CurrentDirStr),
    RefStrOrNil(Params.CommandLineStr),
    Ptr.RefOrNil<PEnvironment>(Params.Environment),
    nil, // WindowTitile
    RefStrOrNil(Params.DesktopStr),
    nil, // ShellInfo
    nil, // RuntimeData
    0
  );

  if Result.IsSuccess then
    Params.Initialized := True;

  // Adjust window mode flags
  if Options.Flags and PROCESS_OPTIONS_USE_WINDOW_MODE <> 0 then
  begin
    xMemory.Data.WindowFlags := xMemory.Data.WindowFlags or STARTF_USESHOWWINDOW;
    xMemory.Data.ShowWindowFlags := Cardinal(Options.WindowMode);
  end;
end;

function GetHandleOrZero(hxObject: IHandle): THandle;
begin
  if Assigned(hxObject) then
    Result := hxObject.Handle
  else
    Result := 0;
end;

{ Process Creation }

function RtlxCreateUserProcess(const Options: TCreateProcessOptions;
  out Info: TProcessInfo): TNtxStatus;
var
  Application: String;
  ProcessParams: IProcessParams;
  NtImageName: TNtUnicodeString;
  ProcessInfo: TRtlUserProcessInformation;
begin
  Application := Options.Application;

  // Convert Win32 paths of necessary
  if Options.Flags and PROCESS_OPTIONS_NATIVE_PATH = 0 then
  begin
    Result := RtlxDosPathToNtPathVar(Application);

    if not Result.IsSuccess then
      Exit;
  end;

  NtImageName := TNtUnicodeString.From(Application);

  Result := RtlxpCreateProcessParams(ProcessParams, Options);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlCreateUserProcess';
  Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
  Result.Status := RtlCreateUserProcess(
    NtImageName,
    OBJ_CASE_INSENSITIVE,
    ProcessParams.Data,
    Ptr.RefOrNil<PSecurityDescriptor>(Options.ProcessSecurity),
    Ptr.RefOrNil<PSecurityDescriptor>(Options.ThreadSecurity),
    GetHandleOrZero(Options.Attributes.hxParentProcess),
    Options.Flags and PROCESS_OPTIONS_INHERIT_HANDLES <> 0,
    0,
    GetHandleOrZero(Options.hxToken),
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  // Capture the information about the new process
  Info.ClientId := ProcessInfo.ClientId;
  Info.hxProcess := TAutoHandle.Capture(ProcessInfo.Process);
  Info.hxThread := TAutoHandle.Capture(ProcessInfo.Thread);

  // Resume the process if necessary
  if Options.Flags and PROCESS_OPTIONS_SUSPENDED = 0 then
    NtxResumeThread(ProcessInfo.Thread);
end;

end.
