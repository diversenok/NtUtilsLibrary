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

// Create a new process via NtCreateUserProcess
function NtxCreateUserProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Fork the current process.
// The function returns STATUS_PROCESS_CLONED in the cloned process.
function RtlxCloneCurrentProcess(
  out Info: TProcessInfo;
  ProcessFlags: TRtlProcessCloneFlags = RTL_CLONE_PROCESS_FLAGS_INHERIT_HANDLES;
  [opt, Access(DEBUG_PROCESS_ASSIGN)] DebugPort: THandle = 0;
  [in, opt] ProcessSecurity: PSecurityDescriptor = nil;
  [in, opt] ThreadSecurity: PSecurityDescriptor = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntseapi, Ntapi.ntdbg, Ntapi.ntstatus,
  NtUtils.Threads, Winapi.ProcessThreadsApi, NtUtils.Files, NtUtils.Objects,
  NtUtils.Ldr, NtUtils.Tokens;

{ Process Parameters & Attributes }

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
  ApplicationStr, CommandLineStr, CurrentDirStr, DesktopStr: TNtUnicodeString;
begin
  // Note: do not inline these since the compiler reuses hidden variables
  ApplicationStr := TNtUnicodeString.From(Options.ApplicationNative);
  CommandLineStr := TNtUnicodeString.From(Options.CommandLine);
  CurrentDirStr := TNtUnicodeString.From(Options.CurrentDirectory);
  DesktopStr := TNtUnicodeString.From(Options.Desktop);

  Result.Location := 'RtlCreateProcessParametersEx';
  Result.Status := RtlCreateProcessParametersEx(
    Buffer,
    ApplicationStr,
    nil, // DllPath
    RefNtStrOrNil(CurrentDirStr),
    @CommandLineStr,
    Auto.RefOrNil<PEnvironment>(Options.Environment),
    nil, // WindowTitile
    RefNtStrOrNil(DesktopStr),
    nil, // ShellInfo
    nil, // RuntimeData
    RTL_USER_PROC_PARAMS_NORMALIZED
  );

  if not Result.IsSuccess then
    Exit;

  IMemory(xMemory) := TAutoUserProcessParams.Capture(Buffer,
    Buffer.MaximumLength + Buffer.EnvironmentSize);

  // Adjust window mode flags
  if poUseWindowMode in Options.Flags then
  begin
    xMemory.Data.WindowFlags := xMemory.Data.WindowFlags or STARTF_USESHOWWINDOW;
    xMemory.Data.ShowWindowFlags := Cardinal(Options.WindowMode);
  end;
end;

type
  TPsAttributesRecord = record
  private
    Source: TPtAttributes;
    FImageName: String;
    FClientId: TClientId;
    FHandleList: TArray<THandle>;
    hxExpandedToken: IHandle;
    hJob: THandle;
    Buffer: IMemory<PPsAttributeList>;
    function GetData: PPsAttributeList;
  public
    function Create(const Options: TCreateProcessOptions): TNtxStatus;
    property ClientId: TClientId read FClientId;
    property Data: PPsAttributeList read GetData;
    property ImageName: String read FImageName;
  end;

{ TPsAttributesRecord }

function TPsAttributesRecord.Create;
var
  Count, i, j: Integer;
  TotalSize: Cardinal;
begin
  // Always use Image Name & Client ID
  Count := 2;

  if Assigned(Options.hxToken) then
    Inc(Count);

  if Assigned(Options.Attributes.hxParentProcess) then
    Inc(Count);

  if Length(Options.Attributes.HandleList) > 0 then
    Inc(Count);

  if Assigned(Options.Attributes.hxJob) then
    Inc(Count);

  Source := Options.Attributes;
  TotalSize := SizeOf(TPsAttributeList) + Pred(Count) * SizeOf(TPsAttribute);

  IMemory(Buffer) := Auto.AllocateDynamic(TotalSize);
  Data.TotalLength := TotalSize;

  FImageName := Options.ApplicationNative;
  Data.Attributes[0].Attribute := PS_ATTRIBUTE_IMAGE_NAME;
  Data.Attributes[0].Size := SizeOf(WideChar) * Length(FImageName);
  Pointer(Data.Attributes[0].Value) := PWideChar(FImageName);

  i := 1;
  Data.Attributes{$R-}[i]{$R+}.Attribute := PS_ATTRIBUTE_CLIENT_ID;
  Data.Attributes{$R-}[i]{$R+}.Size := SizeOf(TClientId);
  Pointer(Data.Attributes{$R-}[i]{$R+}.Value) := @FClientId;
  Inc(i);

  if Assigned(Options.hxToken) then
  begin
    // Allow use of pseudo-handles
    hxExpandedToken := Options.hxToken;
    Result := NtxExpandToken(hxExpandedToken, TOKEN_ASSIGN_PRIMARY);

    if not Result.IsSuccess then
      Exit;

    Data.Attributes{$R-}[i]{$R+}.Attribute := PS_ATTRIBUTE_TOKEN;
    Data.Attributes{$R-}[i]{$R+}.Size := SizeOf(THandle);
    Data.Attributes{$R-}[i]{$R+}.Value := hxExpandedToken.Handle;
    Inc(i);
  end;

  if Assigned(Source.hxParentProcess) then
  begin
    Data.Attributes{$R-}[i]{$R+}.Attribute := PS_ATTRIBUTE_PARENT_PROCESS;
    Data.Attributes{$R-}[i]{$R+}.Size := SizeOf(THandle);
    Data.Attributes{$R-}[i]{$R+}.Value := Source.hxParentProcess.Handle;
    Inc(i);
  end;

  if Length(Source.HandleList) > 0 then
  begin
    SetLength(FHandleList, Length(Source.HandleList));

    for j := 0 to High(FHandleList) do
      FHandleList[j] := Source.HandleList[j].Handle;

    Data.Attributes{$R-}[i]{$R+}.Attribute := PS_ATTRIBUTE_HANDLE_LIST;
    Data.Attributes{$R-}[i]{$R+}.Size := SizeOf(THandle) * Length(FHandleList);
    Pointer(Data.Attributes{$R-}[i]{$R+}.Value) := Pointer(FHandleList);
    Inc(i);
  end;

  if Assigned(Source.hxJob) then
  begin
    hJob := Source.hxJob.Handle;
    Data.Attributes{$R-}[i]{$R+}.Attribute := PS_ATTRIBUTE_JOB_LIST;
    Data.Attributes{$R-}[i]{$R+}.Size := SizeOf(THandle);
    Pointer(Data.Attributes{$R-}[i]{$R+}.Value) := @hJob;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function TPsAttributesRecord.GetData;
begin
  Result := Buffer.Data;
end;

{ Process Creation }

function RtlxCreateUserProcess;
var
  ProcessParams: IRtlUserProcessParamers;
  ProcessInfo: TRtlUserProcessInformation;
  hxExpandedToken: IHandle;
begin
  Result := RtlxCreateProcessParameters(Options, ProcessParams);

  if not Result.IsSuccess then
    Exit;

  // Allow use of pseudo-tokens
  hxExpandedToken := Options.hxToken;
  Result := NtxExpandToken(hxExpandedToken, TOKEN_ASSIGN_PRIMARY);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlCreateUserProcess';

  if Assigned(Options.Attributes.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if Assigned(Options.hxToken) then
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);

  Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
  Result.Status := RtlCreateUserProcess(
    TNtUnicodeString.From(Options.ApplicationNative),
    OBJ_CASE_INSENSITIVE,
    ProcessParams.Data,
    Auto.RefOrNil<PSecurityDescriptor>(Options.ProcessSecurity),
    Auto.RefOrNil<PSecurityDescriptor>(Options.ThreadSecurity),
    HandleOrDefault(Options.Attributes.hxParentProcess),
    poInheritHandles in Options.Flags,
    0,
    HandleOrDefault(hxExpandedToken),
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
  hxExpandedToken: IHandle;
begin
  Result := LdrxCheckNtDelayedImport('RtlCreateUserProcessEx');

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCreateProcessParameters(Options, ProcessParams);

  if not Result.IsSuccess then
    Exit;

  // Allow use of pseudo-tokens
  hxExpandedToken := Options.hxToken;
  Result := NtxExpandToken(hxExpandedToken, TOKEN_ASSIGN_PRIMARY);

  if not Result.IsSuccess then
    Exit;

  ParamsEx := Default(TRtlUserProcessExtendedParameters);
  ParamsEx.Version := RTL_USER_PROCESS_EXTENDED_PARAMETERS_VERSION;
  ParamsEx.ProcessSecurityDescriptor :=
    Auto.RefOrNil<PSecurityDescriptor>(Options.ProcessSecurity);
  ParamsEx.ThreadSecurityDescriptor :=
    Auto.RefOrNil<PSecurityDescriptor>(Options.ThreadSecurity);
  ParamsEx.ParentProcess := HandleOrDefault(Options.Attributes.hxParentProcess);
  ParamsEx.TokenHandle := HandleOrDefault(Options.hxToken);
  ParamsEx.JobHandle := HandleOrDefault(Options.Attributes.hxJob);

  Result.Location := 'RtlCreateUserProcessEx';

  if Assigned(Options.Attributes.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if Assigned(Options.hxToken) then
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);

  if Assigned(Options.Attributes.hxJob) then
    Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_ASSIGN_PROCESS);

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

function NtxCreateUserProcess;
var
  hProcess, hThread: THandle;
  ProcessObjectAttributes, ThreadObjectAttributes: IObjectAttributes;
  ProcessFlags: TProcessCreateFlags;
  ThreadFlags: TThreadCreateFlags;
  ProcessParams: IRtlUserProcessParamers;
  CreateInfo: TPsCreateInfo;
  Attributes: TPsAttributesRecord;
begin
  Result := RtlxCreateProcessParameters(Options, ProcessParams);

  if not Result.IsSuccess then
    Exit;

  // Prepare attributes
  Result := Attributes.Create(Options);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Options.ProcessSecurity) then
    ProcessObjectAttributes := AttributeBuilder.UseSecurity(
      Options.ProcessSecurity)
  else
    ProcessObjectAttributes := nil;

  if Assigned(Options.ThreadSecurity) then
    ThreadObjectAttributes := AttributeBuilder.UseSecurity(
      Options.ThreadSecurity)
  else
    ThreadObjectAttributes := nil;

  // Preapare flags
  ProcessFlags := 0;

  if poBreakawayFromJob in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_BREAKAWAY;

  if poInheritHandles in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_INHERIT_HANDLES;

  ThreadFlags := 0;

  if poSuspended in Options.Flags then
    ThreadFlags := ThreadFlags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED;

  CreateInfo := Default(TPsCreateInfo);
  CreateInfo.Size := SizeOf(TPsCreateInfo);

  Result.Location := 'NtCreateUserProcess';

  if Assigned(Options.Attributes.hxParentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if Assigned(Options.hxToken) then
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);

  if Assigned(Options.Attributes.hxJob) then
    Result.LastCall.Expects<TJobObjectAccessMask>(JOB_OBJECT_ASSIGN_PROCESS);

  Result.Status := NtCreateUserProcess(
    hProcess,
    hThread,
    MAXIMUM_ALLOWED,
    MAXIMUM_ALLOWED,
    AttributesRefOrNil(ProcessObjectAttributes),
    AttributesRefOrNil(ThreadObjectAttributes),
    ProcessFlags,
    ThreadFlags,
    ProcessParams.Data,
    CreateInfo,
    Attributes.Data
  );

  if Result.IsSuccess then
  begin
    Info.ClientId := Attributes.ClientId;
    Info.hxProcess := NtxObject.Capture(hProcess);
    Info.hxThread := NtxObject.Capture(hThread);
  end;
end;

function RtlxCloneCurrentProcess;
var
  RtlProcessInfo: TRtlUserProcessInformation;
begin
  Result.Location := 'RtlCloneUserProcess';

  if DebugPort <> 0 then
    Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_PROCESS_ASSIGN);

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
