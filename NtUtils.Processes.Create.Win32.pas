unit NtUtils.Processes.Create.Win32;

{
  The module provides support for process creation via a Win32 API.
}

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Create a new process via CreateProcessAsUserW
function AdvxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via CreateProcessWithTokenW
function AdvxCreateProcessWithToken(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via CreateProcessWithLogonW
function AdvxCreateProcessWithLogon(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntstatus, Ntapi.ntseapi, Winapi.WinBase,
  Winapi.ProcessThreadsApi, NtUtils.Objects, DelphiUtils.AutoObject,
  NtUtils.Files, NtUtils.SysUtils;

 { Process-thread attributes }

type
  IPtAttributes = IMemory<PProcThreadAttributeList>;

  TPtAutoMemory = class (TAutoMemory, IMemory)
    Data: TPtAttributes;
    hParent: THandle;
    HandleList: TArray<THandle>;
    Capabilities: TArray<TSidAndAttributes>;
    Security: TSecurityCapabilities;
    AllAppPackages: Cardinal;
    Initilalized: Boolean;
    procedure Release; override;
  end;

procedure TPtAutoMemory.Release;
begin
  if Initilalized then
    DeleteProcThreadAttributeList(FAddress);

  // Call inherited memory deallocation
  inherited;
end;

function AllocPtAttributes(
  const Attributes: TPtAttributes;
  out xMemory: IPtAttributes
): TNtxStatus;
var
  PtAttributes: TPtAutoMemory;
  Required: NativeUInt;
  Count: Integer;
  i: Integer;
begin
  // Count the applied attributes
  Count := 0;

  if Assigned(Attributes.hxParentProcess) then
    Inc(Count);

  if (Attributes.Mitigations <> 0) or (Attributes.Mitigations2 <> 0) then
    Inc(Count);

  if Attributes.ChildPolicy <> 0 then
    Inc(Count);

  if Length(Attributes.HandleList) > 0 then
    Inc(Count);

  if Assigned(Attributes.AppContainer) then
    Inc(Count);

  if Attributes.LPAC then
    Inc(Count);

  if Count = 0 then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Determine the required size
  Result.Location := 'InitializeProcThreadAttributeList';
  Result.Win32Result := InitializeProcThreadAttributeList(nil, Count, 0,
    Required);

  if Result.Status <> STATUS_BUFFER_TOO_SMALL then
    Exit;

  // Allocate and initialize
  PtAttributes := TPtAutoMemory.Allocate(Required);
  IMemory(xMemory) := PtAttributes;
  Result.Win32Result := InitializeProcThreadAttributeList(xMemory.Data, Count,
    0, Required);

  if Result.IsSuccess then
  begin
    // NOTE: Since ProcThreadAttributeList stores pointers istead of the actual
    // data, we need to make sure it does not go anywhere. Attach the attribute
    // data to prolong its lifetime.

    PtAttributes.Data := Attributes;
    PtAttributes.Initilalized := True;
  end
  else
    Exit;

  // Parent process
  if Assigned(Attributes.hxParentProcess) then
  begin
    PtAttributes.hParent := Attributes.hxParentProcess.Handle;

    Result.Location := 'UpdateProcThreadAttribute';
    Result.Win32Result := UpdateProcThreadAttribute(xMemory.Data, 0,
      PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, PtAttributes.hParent,
      SizeOf(THandle));

    if not Result.IsSuccess then
      Exit;
  end;

  // Mitigation policies
  if (Attributes.Mitigations <> 0) or (Attributes.Mitigations2 <> 0) then
  begin
    // The size might be 32, 64, or 128 bits
    if Attributes.Mitigations2 = 0 then
    begin
      if Attributes.Mitigations and $FFFFFFFF00000000 <> 0 then
        Required := SizeOf(UInt64)
      else
        Required := SizeOf(Cardinal);
    end
    else
      Required := 2 * SizeOf(UInt64);

    Result.Location := 'UpdateProcThreadAttribute';
    Result.Win32Result := UpdateProcThreadAttribute(xMemory.Data, 0,
      PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY, PtAttributes.Data.Mitigations,
      Required);

    if not Result.IsSuccess then
      Exit;
  end;

  // Child process policy
  if Attributes.ChildPolicy <> 0 then
  begin
    Result.Location := 'UpdateProcThreadAttribute';
    Result.Win32Result := UpdateProcThreadAttribute(xMemory.Data, 0,
      PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY, PtAttributes.Data.ChildPolicy,
      SizeOf(Cardinal));

    if not Result.IsSuccess then
      Exit;
  end;

  // Inherited handle list
  if Length(Attributes.HandleList) > 0 then
  begin
    SetLength(PtAttributes.HandleList, Length(Attributes.HandleList));

    for i := 0 to High(Attributes.HandleList) do
      PtAttributes.HandleList[i] := Attributes.HandleList[i].Handle;

    Result.Location := 'UpdateProcThreadAttribute';
    Result.Win32Result := UpdateProcThreadAttribute(xMemory.Data, 0,
      PROC_THREAD_ATTRIBUTE_HANDLE_LIST, PtAttributes.HandleList,
      SizeOf(THandle) * Length(Attributes.HandleList));

    if not Result.IsSuccess then
      Exit;
  end;

  // AppContainer
  if Assigned(Attributes.AppContainer) then
  begin
    with PtAttributes.Security do
    begin
      AppContainerSid := Attributes.AppContainer.Data;
      CapabilityCount := Length(Attributes.Capabilities);

      SetLength(PtAttributes.Capabilities, Length(Attributes.Capabilities));
      for i := 0 to High(Attributes.Capabilities) do
      begin
        PtAttributes.Capabilities[i].Sid := Attributes.Capabilities[i].Sid.Data;
        PtAttributes.Capabilities[i].Attributes := Attributes.Capabilities[i].
          Attributes;
      end;

      Capabilities := Pointer(@PtAttributes.Capabilities);
    end;

    Result.Location := 'UpdateProcThreadAttribute';
    Result.Win32Result := UpdateProcThreadAttribute(xMemory.Data, 0,
      PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES, PtAttributes.Security,
      SizeOf(TSecurityCapabilities));

    if not Result.IsSuccess then
      Exit;
  end;

  // Low privileged AppContainer
  if Attributes.LPAC then
  begin
    PtAttributes.AllAppPackages :=
      PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT;

    Result.Location := 'UpdateProcThreadAttribute';
    Result.Win32Result := UpdateProcThreadAttribute(xMemory.Data, 0,
      PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY,
      PtAttributes.AllAppPackages, SizeOf(Cardinal));

    if not Result.IsSuccess then
      Exit;
  end;
end;

{ Startup info preparation and supplimentary routines }

function RefStrOrNil(const S: String): PWideChar;
begin
  if S <> '' then
    Result := PWideChar(S)
  else
    Result := nil;
end;

function RefSA(var SA: TSecurityAttributes; SD: ISecDesc): PSecurityAttributes;
begin
  if Assigned(SD) then
  begin
    SA.Length := SizeOf(SA);
    SA.SecurityDescriptor := SD.Data;
    SA.InheritHandle := False;
    Result := @SA;
  end
  else
    Result := nil;
end;

function GetHandleOrZero(hxObject: IHandle): THandle;
begin
  if Assigned(hxObject) then
    Result := hxObject.Handle
  else
    Result := 0;
end;

procedure PrepareStartupInfo(
  out SI: TStartupInfoW;
  out CreationFlags: TProcessCreateFlags;
  const Options: TCreateProcessOptions
);
begin
  SI := Default(TStartupInfoW);
  SI.cb := SizeOf(SI);
  CreationFlags := 0;

  SI.Desktop := RefStrOrNil(Options.Desktop);

  // Suspended state
  if Options.Flags and PROCESS_OPTION_SUSPENDED <> 0 then
    CreationFlags := CreationFlags or CREATE_SUSPENDED;

  // Job escaping
  if Options.Flags and PROCESS_OPTION_BREAKAWAY_FROM_JOB <> 0 then
    CreationFlags := CreationFlags or CREATE_BREAKAWAY_FROM_JOB;

  // Console
  if Options.Flags and PROCESS_OPTION_NEW_CONSOLE <> 0 then
    CreationFlags := CreationFlags or CREATE_NEW_CONSOLE;

  // Environment
  if Assigned(Options.Environment) then
    CreationFlags := CreationFlags or CREATE_UNICODE_ENVIRONMENT;

  // Window show mode
  if Options.Flags and PROCESS_OPTION_USE_WINDOW_MODE <> 0 then
  begin
    SI.ShowWindow := Options.WindowMode;
    SI.Flags := SI.Flags or STARTF_USESHOWWINDOW;
  end;
end;

procedure PrepareCommandLine(
  out Application: String;
  out CommandLine: String;
  const Options: TCreateProcessOptions);
begin
  if Options.Flags and PROCESS_OPTION_NATIVE_PATH <> 0 then
    Application := RtlxNtPathToDosPath(Options.Application);

  // Either construct the command line or use the supplied one
  if Options.Flags and PROCESS_OPTION_FORCE_COMMAND_LINE <> 0 then
    CommandLine := Options.Parameters
  else
    CommandLine := '"' + Options.Application + '" ' + Options.Parameters;
end;

function CaptureResult(ProcessInfo: TProcessInformation): TProcessInfo;
begin
  with Result, ProcessInfo do
  begin
    hxProcess := TAutoHandle.Capture(hProcess);
    hxThread := TAutoHandle.Capture(hThread);
    ClientId.UniqueProcess := ProcessId;
    ClientId.UniqueThread := ThreadId;
  end;
end;

{ Public functions }

function AdvxCreateProcess;
var
  CreationFlags: TProcessCreateFlags;
  ProcessSA, ThreadSA: TSecurityAttributes;
  Application, CommandLine: String;
  SI: TStartupInfoExW;
  PTA: IPtAttributes;
  ProcessInfo: TProcessInformation;
  RunAsInvoker: IAutoReleasable;
begin
  PrepareStartupInfo(SI.StartupInfo, CreationFlags, Options);
  PrepareCommandLine(Application, CommandLine, Options);

  // Prepare process-thread attribute list
  Result := AllocPtAttributes(Options.Attributes, PTA);

  if not Result.IsSuccess then
    Exit;

  if Assigned(PTA) then
  begin
    // Use -Ex vertion and include attributes
    SI.StartupInfo.cb := SizeOf(TStartupInfoExW);
    SI.AttributeList := PTA.Data;
    CreationFlags := CreationFlags or EXTENDED_STARTUPINFO_PRESENT;
  end;

  // Allow running as invoker
  Result := RtlxApplyCompatLayer(Options, RunAsInvoker);

  if not Result.IsSuccess then
    Exit;

  // CreateProcess needs the command line to be in writable memory
  UniqueString(CommandLine);

  Result.Location := 'CreateProcessAsUserW';
  Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
  Result.Win32Result := CreateProcessAsUserW(
    GetHandleOrZero(Options.hxToken),
    RefStrOrNil(Application),
    RefStrOrNil(CommandLine),
    RefSA(ProcessSA, Options.ProcessSecurity),
    RefSA(ThreadSA, Options.ThreadSecurity),
    Options.Flags and PROCESS_OPTION_INHERIT_HANDLES <> 0,
    CreationFlags,
    IMem.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    SI,
    ProcessInfo
  );

  if Result.IsSuccess then
    Info := CaptureResult(ProcessInfo);
end;

function AdvxCreateProcessWithToken;
var
  CreationFlags: TProcessCreateFlags;
  Application, CommandLine: String;
  StartupInfo: TStartupInfoW;
  ProcessInfo: TProcessInformation;
begin
  PrepareStartupInfo(StartupInfo, CreationFlags, Options);
  PrepareCommandLine(Application, CommandLine, Options);

  Result.Location := 'CreateProcessWithTokenW';
  Result.LastCall.ExpectedPrivilege := SE_IMPERSONATE_PRIVILEGE;
  Result.Win32Result := CreateProcessWithTokenW(
    GetHandleOrZero(Options.hxToken),
    Options.LogonFlags,
    RefStrOrNil(Application),
    RefStrOrNil(CommandLine),
    CreationFlags,
    IMem.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    StartupInfo,
    ProcessInfo
  );

  if Result.IsSuccess then
    Info := CaptureResult(ProcessInfo);
end;

function AdvxCreateProcessWithLogon;
var
  CreationFlags: TProcessCreateFlags;
  Application, CommandLine: String;
  StartupInfo: TStartupInfoW;
  ProcessInfo: TProcessInformation;
begin
  PrepareStartupInfo(StartupInfo, CreationFlags, Options);
  PrepareCommandLine(Application, CommandLine, Options);

  Result.Location := 'CreateProcessWithLogonW';
  Result.Win32Result := CreateProcessWithLogonW(
    RefStrOrNil(Options.Username),
    RefStrOrNil(Options.Domain),
    RefStrOrNil(Options.Password),
    Options.LogonFlags,
    RefStrOrNil(Application),
    RefStrOrNil(CommandLine),
    CreationFlags,
    IMem.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    StartupInfo,
    ProcessInfo
  );

  if Result.IsSuccess then
    Info := CaptureResult(ProcessInfo);
end;

end.
