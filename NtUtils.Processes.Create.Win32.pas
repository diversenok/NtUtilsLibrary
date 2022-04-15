unit NtUtils.Processes.Create.Win32;

{
  The module provides support for process creation via a Win32 API.
}

interface

uses
  Ntapi.ntseapi, NtUtils, NtUtils.Processes.Create;

// Create a new process via CreateProcessAsUserW
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoNewConsole)]
[SupportedOption(spoRunAsInvoker)]
[SupportedOption(spoIgnoreElevation)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoJob)]
[SupportedOption(spoHandleList)]
[SupportedOption(spoMitigationPolicies)]
[SupportedOption(spoChildPolicy)]
[SupportedOption(spoLPAC)]
[SupportedOption(spoAppContainer)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
function AdvxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via CreateProcessWithTokenW
[SupportedOption(spoSuspended)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken, omRequired)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
function AdvxCreateProcessWithToken(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via CreateProcessWithLogonW
[SupportedOption(spoSuspended)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoCredentials, omRequired)]
function AdvxCreateProcessWithLogon(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.WinBase,
  Ntapi.ProcessThreadsApi, NtUtils.Objects, NtUtils.Tokens,
  DelphiUtils.AutoObjects;

 { Process-thread attributes }

type
  IPtAttributes = IMemory<PProcThreadAttributeList>;

  TPtAutoMemory = class (TAutoMemory, IMemory)
    Options: TCreateProcessOptions;
    hParent: THandle;
    HandleList: TArray<THandle>;
    Capabilities: TArray<TSidAndAttributes>;
    Security: TSecurityCapabilities;
    AllAppPackages: Cardinal;
    hJob: THandle;
    ExtendedFlags: TProcExtendedFlag;
    ChildPolicy: TProcessChildFlags;
    Initilalized: Boolean;
    procedure Release; override;
  end;

procedure TPtAutoMemory.Release;
begin
  if Initilalized then
    DeleteProcThreadAttributeList(FData);

  // Call inherited memory deallocation
  inherited;
end;

function RtlxpUpdateProcThreadAttribute(
  [in, out] AttributeList: PProcThreadAttributeList;
  Attribute: NativeUInt;
  const Value;
  Size: NativeUInt
): TNtxStatus;
begin
  Result.Location := 'UpdateProcThreadAttribute';
  Result.LastCall.UsesInfoClass(TProcThreadAttributeNum(Attribute and
    PROC_THREAD_ATTRIBUTE_NUMBER), icSet);
  Result.Win32Result := UpdateProcThreadAttribute(AttributeList, 0, Attribute,
    @Value, Size, nil, nil);
end;

function AllocPtAttributes(
  const Options: TCreateProcessOptions;
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

  if Assigned(Options.hxParentProcess) then
    Inc(Count);

  if (Options.Mitigations <> 0) or (Options.Mitigations2 <> 0) then
    Inc(Count);

  if HasAny(Options.ChildPolicy) then
    Inc(Count);

  if Length(Options.HandleList) > 0 then
    Inc(Count);

  if Assigned(Options.AppContainer) then
    Inc(Count);

  if Options.PackageName <> '' then
    Inc(Count);

  if poLPAC in Options.Flags then
    Inc(Count);

  if Assigned(Options.hxJob) then
    Inc(Count);

  if [poIgnoreElevation, poForceBreakaway] * Options.Flags <> [] then
    Inc(Count);

  if Count = 0 then
  begin
    xMemory := nil;
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

  // NOTE: Since ProcThreadAttributeList stores pointers istead of the actual
  // data, we need to make sure it does not go anywhere.

  if Result.IsSuccess then
    PtAttributes.Initilalized := True
  else
    Exit;

  // Prolong lifetime of the options
  PtAttributes.Options := Options;

  // Parent process
  if Assigned(Options.hxParentProcess) then
  begin
    PtAttributes.hParent := Options.hxParentProcess.Handle;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, PtAttributes.hParent,
      SizeOf(THandle));

    if not Result.IsSuccess then
      Exit;
  end;

  // Mitigation policies
  if (Options.Mitigations <> 0) or (Options.Mitigations2 <> 0) then
  begin
    // The size might be 32, 64, or 128 bits
    if Options.Mitigations2 = 0 then
    begin
      if Options.Mitigations and $FFFFFFFF00000000 <> 0 then
        Required := SizeOf(UInt64)
      else
        Required := SizeOf(Cardinal);
    end
    else
      Required := 2 * SizeOf(UInt64);

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_MITIGATION_POLICY,
      PtAttributes.Options.Mitigations, Required);

    if not Result.IsSuccess then
      Exit;
  end;

  // Child process policy
  if HasAny(Options.ChildPolicy) then
  begin
    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_CHILD_PROCESS_POLICY,
      PtAttributes.Options.ChildPolicy, SizeOf(Cardinal));

    if not Result.IsSuccess then
      Exit;
  end;

  // Inherited handle list
  if Length(Options.HandleList) > 0 then
  begin
    SetLength(PtAttributes.HandleList, Length(Options.HandleList));

    for i := 0 to High(Options.HandleList) do
      PtAttributes.HandleList[i] := Options.HandleList[i].Handle;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_HANDLE_LIST, PtAttributes.HandleList,
      SizeOf(THandle) * Length(Options.HandleList));

    if not Result.IsSuccess then
      Exit;
  end;

  // AppContainer
  if Assigned(Options.AppContainer) then
  begin
    with PtAttributes.Security do
    begin
      AppContainerSid := Options.AppContainer.Data;
      CapabilityCount := Length(Options.Capabilities);

      SetLength(PtAttributes.Capabilities, Length(Options.Capabilities));
      for i := 0 to High(Options.Capabilities) do
      begin
        PtAttributes.Capabilities[i].Sid := Options.Capabilities[i].Sid.Data;
        PtAttributes.Capabilities[i].Attributes := Options.Capabilities[i].
          Attributes;
      end;

      Capabilities := Pointer(@PtAttributes.Capabilities);
    end;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_SECURITY_CAPABILITIES, PtAttributes.Security,
      SizeOf(TSecurityCapabilities));

    if not Result.IsSuccess then
      Exit;
  end;

  // Low privileged AppContainer
  if poLPAC in Options.Flags then
  begin
    PtAttributes.AllAppPackages :=
      PROCESS_CREATION_ALL_APPLICATION_PACKAGES_OPT_OUT;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_ALL_APPLICATION_PACKAGES_POLICY,
      PtAttributes.AllAppPackages, SizeOf(Cardinal));

    if not Result.IsSuccess then
      Exit;
  end;

  // Package name
  if Options.PackageName <> '' then
  begin
    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_PACKAGE_NAME,
      PWideChar(PtAttributes.Options.PackageName)^,
      Length(PtAttributes.Options.PackageName) * SizeOf(WideChar));

    if not Result.IsSuccess then
      Exit;
  end;

  // Job list
  if Assigned(Options.hxJob) then
  begin
    PtAttributes.hJob := Options.hxJob.Handle;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_JOB_LIST, PtAttributes.hJob, SizeOf(THandle));

    if not Result.IsSuccess then
      Exit;
  end;

  // Extended attributes
  if [poIgnoreElevation, poForceBreakaway] * Options.Flags <> [] then
  begin
    PtAttributes.ExtendedFlags := 0;

    if poIgnoreElevation in Options.Flags then
      PtAttributes.ExtendedFlags := PtAttributes.ExtendedFlags or
        EXTENDED_PROCESS_CREATION_FLAG_FORCELUA;

    if poForceBreakaway in Options.Flags then
      PtAttributes.ExtendedFlags := PtAttributes.ExtendedFlags or
        EXTENDED_PROCESS_CREATION_FLAG_FORCE_BREAKAWAY;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_EXTENDED_FLAGS, PtAttributes.ExtendedFlags,
      SizeOf(TProcExtendedFlag));

    if not Result.IsSuccess then
      Exit;
  end;
end;

{ Startup info preparation and supplimentary routines }

function RefSA(
  out SA: TSecurityAttributes;
  const SD: ISecurityDescriptor
): PSecurityAttributes;
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
  if poSuspended in Options.Flags then
    CreationFlags := CreationFlags or CREATE_SUSPENDED;

  // Job escaping
  if poBreakawayFromJob in Options.Flags then
    CreationFlags := CreationFlags or CREATE_BREAKAWAY_FROM_JOB;

  // Console
  if poNewConsole in Options.Flags then
    CreationFlags := CreationFlags or CREATE_NEW_CONSOLE;

  // Environment
  if Assigned(Options.Environment) then
    CreationFlags := CreationFlags or CREATE_UNICODE_ENVIRONMENT;

  // Window show mode
  if poUseWindowMode in Options.Flags then
  begin
    SI.ShowWindow := Options.WindowMode;
    SI.Flags := SI.Flags or STARTF_USESHOWWINDOW;
  end;
end;

function CaptureResult(ProcessInfo: TProcessInformation): TProcessInfo;
begin
  with Result, ProcessInfo do
  begin
    hxProcess := Auto.CaptureHandle(hProcess);
    hxThread := Auto.CaptureHandle(hThread);
    ClientId.UniqueProcess := ProcessId;
    ClientId.UniqueThread := ThreadId;
  end;
end;

{ Public functions }

function AdvxCreateProcess;
var
  CreationFlags: TProcessCreateFlags;
  ProcessSA, ThreadSA: TSecurityAttributes;
  hxExpandedToken: IHandle;
  CommandLine: String;
  SI: TStartupInfoExW;
  PTA: IPtAttributes;
  ProcessInfo: TProcessInformation;
  RunAsInvoker: IAutoReleasable;
begin
  PrepareStartupInfo(SI.StartupInfo, CreationFlags, Options);

  // Prepare process-thread attribute list
  Result := AllocPtAttributes(Options, PTA);

  if not Result.IsSuccess then
    Exit;

  if Assigned(PTA) then
  begin
    // Use -Ex vertion and include attributes
    SI.StartupInfo.cb := SizeOf(TStartupInfoExW);
    SI.AttributeList := PTA.Data;
    CreationFlags := CreationFlags or EXTENDED_STARTUPINFO_PRESENT;
  end;

  // Allow using pseudo-tokens
  hxExpandedToken := Options.hxToken;
  Result := NtxExpandToken(hxExpandedToken, TOKEN_CREATE_PROCESS);

  if not Result.IsSuccess then
    Exit;

  // Allow running as invoker
  Result := RtlxApplyCompatLayer(poRunAsInvokerOn in Options.Flags,
    poRunAsInvokerOff in Options.Flags, RunAsInvoker);

  if not Result.IsSuccess then
    Exit;

  // CreateProcess needs the command line to be in writable memory
  CommandLine := Options.CommandLine;
  UniqueString(CommandLine);

  Result.Location := 'CreateProcessAsUserW';

  if Assigned(Options.hxToken) then
  begin
    Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_CREATE_PROCESS);
  end;

  if Assigned(Options.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if Assigned(Options.hxJob) then
    Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_ASSIGN_PROCESS);

  Result.Win32Result := CreateProcessAsUserW(
    HandleOrDefault(hxExpandedToken),
    RefStrOrNil(Options.ApplicationWin32),
    RefStrOrNil(CommandLine),
    RefSA(ProcessSA, Options.ProcessSecurity),
    RefSA(ThreadSA, Options.ThreadSecurity),
    poInheritHandles in Options.Flags,
    CreationFlags,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    SI,
    ProcessInfo
  );

  if Result.IsSuccess then
    Info := CaptureResult(ProcessInfo);
end;

function AdvxCreateProcessWithToken;
var
  hxExpandedToken: IHandle;
  CreationFlags: TProcessCreateFlags;
  StartupInfo: TStartupInfoW;
  ProcessInfo: TProcessInformation;
begin
  PrepareStartupInfo(StartupInfo, CreationFlags, Options);

  hxExpandedToken := Options.hxToken;

  if Assigned(hxExpandedToken) then
  begin
    // Allow using pseudo-handles
    Result := NtxExpandToken(hxExpandedToken, TOKEN_CREATE_PROCESS);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'CreateProcessWithTokenW';
  Result.LastCall.ExpectedPrivilege := SE_IMPERSONATE_PRIVILEGE;

  if Assigned(Options.hxToken) then
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_CREATE_PROCESS);

  Result.Win32Result := CreateProcessWithTokenW(
    HandleOrDefault(hxExpandedToken),
    Options.LogonFlags,
    RefStrOrNil(Options.ApplicationWin32),
    RefStrOrNil(Options.CommandLine),
    CreationFlags,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
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
  StartupInfo: TStartupInfoW;
  ProcessInfo: TProcessInformation;
begin
  PrepareStartupInfo(StartupInfo, CreationFlags, Options);

  Result.Location := 'CreateProcessWithLogonW';
  Result.Win32Result := CreateProcessWithLogonW(
    RefStrOrNil(Options.Username),
    RefStrOrNil(Options.Domain),
    RefStrOrNil(Options.Password),
    Options.LogonFlags,
    RefStrOrNil(Options.ApplicationWin32),
    RefStrOrNil(Options.CommandLine),
    CreationFlags,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    StartupInfo,
    ProcessInfo
  );

  if Result.IsSuccess then
    Info := CaptureResult(ProcessInfo);
end;

end.
