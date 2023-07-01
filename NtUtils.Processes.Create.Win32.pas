unit NtUtils.Processes.Create.Win32;

{
  The module provides support for process creation via a Win32 API.
}

interface

uses
  Ntapi.ntseapi, NtUtils, NtUtils.Processes.Create;

// Create a new process via CreateProcessAsUserW
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoForceBreakaway)]
[SupportedOption(spoInheritConsole)]
[SupportedOption(spoRunAsInvoker)]
[SupportedOption(spoIgnoreElevation)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoObjectInherit)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoWindowTitle)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoJob)]
[SupportedOption(spoDebugPort)]
[SupportedOption(spoHandleList)]
[SupportedOption(spoMitigationPolicies)]
[SupportedOption(spoChildPolicy)]
[SupportedOption(spoLPAC)]
[SupportedOption(spoAppContainer)]
[SupportedOption(spoPackage)]
[SupportedOption(spoPackageBreakaway)]
[SupportedOption(spoProtection)]
[SupportedOption(spoSafeOpenPromptOriginClaim)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function AdvxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via CreateProcessWithTokenW
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoWindowTitle)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoLogonFlags)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
function AdvxCreateProcessWithToken(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via CreateProcessWithLogonW
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoWindowTitle)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoLogonFlags)]
[SupportedOption(spoCredentials, omRequired)]
function AdvxCreateProcessWithLogon(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.ntpebteb, Ntapi.ntobapi,
  Ntapi.WinBase,Ntapi.WinUser, Ntapi.ProcessThreadsApi, Ntapi.ntdbg,
  NtUtils.Objects, NtUtils.Tokens, NtUtils.Processes.Info,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

 { Process-thread attributes }

type
  IPtAttributes = IMemory<PProcThreadAttributeList>;

  TPtAutoMemory = class (TAutoMemory, IMemory)
    Options: TCreateProcessOptions;
    hParent: THandle;
    HandleList: TArray<THandle>;
    Capabilities: TArray<TSidAndAttributes>;
    Security: TSecurityCapabilities;
    AllAppPackages: TProcessAllPackagesFlags;
    hJob: THandle;
    ExtendedFlags: TProcExtendedFlag;
    ChildPolicy: TProcessChildFlags;
    Protection: TProtectionLevel;
    SeSafePromtClaim: TSeSafeOpenPromptResults;
    Initilalized: Boolean;
    procedure Release; override;
  end;

procedure TPtAutoMemory.Release;
begin
  if Assigned(FData) and Initilalized then
    DeleteProcThreadAttributeList(FData);

  // Call the inherited memory deallocation
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

  if poLPAC in Options.Flags then
    Inc(Count);

  if Options.PackageName <> '' then
    Inc(Count);

  if HasAny(Options.PackageBreaway) then
    Inc(Count);

  if Assigned(Options.hxJob) then
    Inc(Count);

  if [poIgnoreElevation, poForceBreakaway] * Options.Flags <> [] then
    Inc(Count);

  if poUseProtection in Options.Flags then
    Inc(Count);

  if poUseSafeOpenPromptOriginClaim in Options.Flags then
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

      if Length(Options.Capabilities) > 0 then
        Capabilities := Pointer(@PtAttributes.Capabilities[0])
      else
        Capabilities := nil;
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
      PtAttributes.AllAppPackages, SizeOf(TProcessAllPackagesFlags));

    if not Result.IsSuccess then
      Exit;
  end;

  // Package name
  if Options.PackageName <> '' then
  begin
    Result := RtlxpUpdateProcThreadAttribute(
      xMemory.Data,
      PROC_THREAD_ATTRIBUTE_PACKAGE_NAME,
      PWideChar(PtAttributes.Options.PackageName)^,
      StringSizeNoZero(PtAttributes.Options.PackageName)
    );

    if not Result.IsSuccess then
      Exit;
  end;

  // Package breakaway (aka Desktop App Policy)
  if HasAny(Options.PackageBreaway) then
  begin
    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_DESKTOP_APP_POLICY,
      PtAttributes.Options.PackageBreaway, SizeOf(TProcessDesktopAppFlags));

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

  // Protection
  if poUseProtection in Options.Flags then
  begin
    PtAttributes.Protection := Options.Protection;

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_PROTECTION_LEVEL, PtAttributes.Protection,
      SizeOf(TProtectionLevel));

    if not Result.IsSuccess then
      Exit;
  end;

  // Safe open prompt origin claim
  if poUseSafeOpenPromptOriginClaim in Options.Flags then
  begin
    PtAttributes.SeSafePromtClaim.Results :=
      Options.SafeOpenPromptOriginClaimResult;
    PtAttributes.SeSafePromtClaim.SetPath(Options.SafeOpenPromptOriginClaimPath);

    Result := RtlxpUpdateProcThreadAttribute(xMemory.Data,
      PROC_THREAD_ATTRIBUTE_SAFE_OPEN_PROMPT_ORIGIN_CLAIM,
      PtAttributes.SeSafePromtClaim, SizeOf(TSeSafeOpenPromptResults));

    if not Result.IsSuccess then
      Exit;
  end;
end;

{ Startup info preparation and supplimentary routines }

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
  if not (poInheritConsole in Options.Flags) then
    CreationFlags := CreationFlags or CREATE_NEW_CONSOLE;

  // Environment
  if Assigned(Options.Environment) then
    CreationFlags := CreationFlags or CREATE_UNICODE_ENVIRONMENT;

  // Window show mode
  if poUseWindowMode in Options.Flags then
  begin
    SI.ShowWindow := TShowMode16(Word(Options.WindowMode));
    SI.Flags := SI.Flags or STARTF_USESHOWWINDOW;
  end;

  // Window title
  if (poForceWindowTitle in Options.Flags) or (Options.WindowTitle <> '') then
    SI.Title := PWideChar(Options.WindowTitle);

  // Process protection
  if poUseProtection in Options.Flags then
    CreationFlags := CreationFlags or CREATE_PROTECTED_PROCESS;
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
  RunAsInvokerReverter, DebugPortReverter: IAutoReleasable;
  hOldDebugPort: THandle;
begin
  Info := Default(TProcessInfo);
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
    poRunAsInvokerOff in Options.Flags, RunAsInvokerReverter);

  if not Result.IsSuccess then
    Exit;

  // Select the debug object
  if Assigned(Options.hxDebugPort) then
  begin
    CreationFlags := CreationFlags or DEBUG_PROCESS;
    hOldDebugPort := DbgUiGetThreadDebugObject;
    DbgUiSetThreadDebugObject(Options.hxDebugPort.Handle);

    DebugPortReverter := Auto.Delay(
      procedure
      begin
        // Revert the change later
        DbgUiSetThreadDebugObject(hOldDebugPort);
      end
    );
  end
  else
    hOldDebugPort := 0;

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

  if poForceBreakaway in Options.Flags then
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  Result.Win32Result := CreateProcessAsUserW(
    HandleOrDefault(hxExpandedToken),
    RefStrOrNil(Options.ApplicationWin32),
    RefStrOrNil(CommandLine),
    ReferenceSecurityAttributes(ProcessSA, Options.ProcessAttributes),
    ReferenceSecurityAttributes(ThreadSA, Options.ThreadAttributes),
    poInheritHandles in Options.Flags,
    CreationFlags,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    SI,
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  Info.ValidFields := Info.ValidFields + [piProcessId, piThreadId,
    piProcessHandle, piThreadHandle];
  Info.ClientId.UniqueProcess := ProcessInfo.ProcessId;
  Info.ClientId.UniqueThread := ProcessInfo.ThreadId;
  Info.hxProcess := Auto.CaptureHandle(ProcessInfo.hProcess);
  Info.hxThread := Auto.CaptureHandle(ProcessInfo.hThread);
end;

function RtlxpAdjustProcessId(
  out Reverter: IAutoReleasable;
  hTargetProcess: THandle
): TNtxStatus;
var
  Info: TProcessBasicInformation;
  OldPid: TProcessId;
begin
  Reverter := nil;
  Result := NtxProcess.Query(hTargetProcess, ProcessBasicInformation, Info);

  if not Result.IsSuccess then
    Exit;

  if Info.UniqueProcessID = NtCurrentTeb.ClientID.UniqueProcess then
    Exit;

  // Swap the value in TEB
  OldPid := NtCurrentTeb.ClientID.UniqueProcess;
  NtCurrentTeb.ClientID.UniqueProcess := Info.UniqueProcessID;

  Reverter := Auto.Delay(
    procedure
    begin
      // Restore it back later
      NtCurrentTeb.ClientID.UniqueProcess := OldPid;
    end
  );
end;

procedure RtlxpCaptureReparentedHandles(
  const hxParentProcess: IHandle;
  var ProcessInfo: TProcessInformation;
  var Info: TProcessInfo
);
begin
  if not Assigned(hxParentProcess) then
  begin
    Info.ValidFields := Info.ValidFields + [piProcessHandle, piThreadHandle];
    Info.hxProcess := Auto.CaptureHandle(ProcessInfo.hProcess);
    Info.hxThread := Auto.CaptureHandle(ProcessInfo.hThread);
    Exit;
  end;

  // Duplicate process handle from the new parent
  if NtxDuplicateHandleFrom(hxParentProcess.Handle,
    ProcessInfo.hProcess, Info.hxProcess, DUPLICATE_SAME_ACCESS or
      DUPLICATE_CLOSE_SOURCE).IsSuccess then
    Include(Info.ValidFields, piProcessHandle);

  // Duplicate thread handle from the parent
  if NtxDuplicateHandleFrom(hxParentProcess.Handle,
    ProcessInfo.hThread, Info.hxThread, DUPLICATE_SAME_ACCESS or
      DUPLICATE_CLOSE_SOURCE).IsSuccess then
    Include(Info.ValidFields, piThreadHandle);
end;

function AdvxCreateProcessWithToken;
var
  hxExpandedToken, hxRemoteExpandedToken: IHandle;
  CreationFlags: TProcessCreateFlags;
  StartupInfo: TStartupInfoW;
  ProcessInfo: TProcessInformation;
  ProcessIdReverter: IAutoReleasable;
begin
  Info := Default(TProcessInfo);
  PrepareStartupInfo(StartupInfo, CreationFlags, Options);

  hxExpandedToken := Options.hxToken;

  // Note: the token parameter is mandatory and the function doesn't accept
  // tokens that are already in use because it always adjusts the session ID.

  if Assigned(hxExpandedToken) then
    Result := NtxExpandToken(hxExpandedToken, TOKEN_CREATE_PROCESS_EX)
  else
    Result := NtxDuplicateToken(hxExpandedToken, NtxCurrentProcessToken,
      TokenPrimary);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Options.hxParentProcess) then
  begin
    // Temporarily adjust the process ID in TEB to allow re-parenting
    Result := RtlxpAdjustProcessId(ProcessIdReverter,
      Options.hxParentProcess.Handle);

    if not Result.IsSuccess then
      Exit;

    // Send the token to the new parent (since seclogon reads it from there)
    Result := NtxDuplicateHandleToAuto(Options.hxParentProcess,
      hxExpandedToken.Handle, hxRemoteExpandedToken);

    if not Result.IsSuccess then
      Exit;
  end
  else
    hxRemoteExpandedToken := hxExpandedToken;

  Result.Location := 'CreateProcessWithTokenW';
  Result.LastCall.ExpectedPrivilege := SE_IMPERSONATE_PRIVILEGE;
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_CREATE_PROCESS_EX);

  if Assigned(Options.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION or
      PROCESS_CREATE_PROCESS or PROCESS_DUP_HANDLE);

  Result.Win32Result := CreateProcessWithTokenW(
    hxRemoteExpandedToken.Handle,
    Options.LogonFlags,
    RefStrOrNil(Options.ApplicationWin32),
    RefStrOrNil(Options.CommandLine),
    CreationFlags,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    RefStrOrNil(Options.CurrentDirectory),
    StartupInfo,
    ProcessInfo
  );

  if not Result.IsSuccess then
    Exit;

  Info.ValidFields := Info.ValidFields + [piProcessId, piThreadId];
  Info.ClientId.UniqueProcess := ProcessInfo.ProcessId;
  Info.ClientId.UniqueThread := ProcessInfo.ThreadId;
  RtlxpCaptureReparentedHandles(Options.hxParentProcess, ProcessInfo, Info);
end;

function AdvxCreateProcessWithLogon;
var
  CreationFlags: TProcessCreateFlags;
  StartupInfo: TStartupInfoW;
  ProcessInfo: TProcessInformation;
  ProcessIdReverter: IAutoReleasable;
begin
  Info := Default(TProcessInfo);
  PrepareStartupInfo(StartupInfo, CreationFlags, Options);

  if Assigned(Options.hxParentProcess) then
  begin
    // Temporarily adjust the process ID in TEB to allow re-parenting
    Result := RtlxpAdjustProcessId(ProcessIdReverter,
      Options.hxParentProcess.Handle);

    if not Result.IsSuccess then
      Exit;
  end;

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

  if not Result.IsSuccess then
    Exit;

  Info.ValidFields := Info.ValidFields + [piProcessId, piThreadId];
  Info.ClientId.UniqueProcess := ProcessInfo.ProcessId;
  Info.ClientId.UniqueThread := ProcessInfo.ThreadId;
  RtlxpCaptureReparentedHandles(Options.hxParentProcess, ProcessInfo, Info);
end;

end.
