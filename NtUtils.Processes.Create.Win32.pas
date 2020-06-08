unit NtUtils.Processes.Create.Win32;

interface

uses
  Ntapi.ntdef, Winapi.ProcessThreadsApi, NtUtils, NtUtils.Environment,
  DelphiUtils.AutoObject;

type
  IPtAttributes = IMemory<PProcThreadAttributeList>;

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
    hxToken: IHandle;
    CreationFlags: Cardinal;
    InheritHandles: Boolean;
    CurrentDirectory: String;
    Environment: IEnvironment;
    ProcessSecurity, ThreadSecurity: ISecDesc;
    Desktop: String;
    Attributes: TPtAttributes;
  end;

// Create a new process
function AdvxCreateProcess(Application, CommandLine: String;
  var Options: TCreateProcessOptions; out Info: TProcessInfo):
  TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntseapi, Winapi.WinBase, NtUtils.Objects;

type
  TPtAutoMemory = class (TAutoMemory, IMemory)
    Data: TPtAttributes;
    hParent: THandle;
    HandleList: TArray<THandle>;
    Capabilities: TArray<TSidAndAttributes>;
    Security: TSecurityCapabilities;
    AllAppPackages: Cardinal;
    Initilalized: Boolean;
    destructor Destroy; override;
  end;

destructor TPtAutoMemory.Destroy;
begin
  if FAutoRelease and Initilalized then
    DeleteProcThreadAttributeList(FAddress);

  // Call inherited memory deallocation
  inherited;
end;

function AllocPtAttributes(const Attributes: TPtAttributes; out
  xMemory: IPtAttributes): TNtxStatus;
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
    Exit;

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
  if (Attributes.Mitigations <> 0) or (Attributes.Mitigations <> 0) then
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

function AdvxCreateProcess(Application, CommandLine: String;
  var Options: TCreateProcessOptions; out Info: TProcessInfo):
  TNtxStatus;
var
  ProcessSA, ThreadSA: TSecurityAttributes;
  SI: TStartupInfoExW;
  PTA: IPtAttributes;
  ProcessInfo: TProcessInformation;
begin
  with Options do
  begin
    // Prepare process-thread attribute list
    Result := AllocPtAttributes(Attributes, PTA);

    if not Result.IsSuccess then
      Exit;

    // Prepare startup info
    FillChar(SI, SizeOf(SI), 0);

    if Assigned(PTA) then
    begin
      // Use -Ex vertion and include attributes
      SI.StartupInfo.cb := SizeOf(TStartupInfoExW);
      SI.AttributeList := PTA.Data;
      CreationFlags := CreationFlags or EXTENDED_STARTUPINFO_PRESENT;
    end
    else
      SI.StartupInfo.cb := SizeOf(TStartupInfoW); // Use regular version

    SI.StartupInfo.Desktop := RefStrOrNil(Desktop);

    if Assigned(Environment) then
      CreationFlags := CreationFlags or CREATE_UNICODE_ENVIRONMENT;

    // CreateProcess needs the command line to be in writable memory
    UniqueString(CommandLine);

    Result.Location := 'CreateProcessAsUserW';
    Result.Win32Result := CreateProcessAsUserW(
      GetHandleOrZero(hxToken),
      RefStrOrNil(Application),
      RefStrOrNil(CommandLine),
      RefSA(ProcessSA, ProcessSecurity),
      RefSA(ThreadSA, ThreadSecurity),
      InheritHandles,
      CreationFlags,
      RefEnvOrNil(Environment),
      RefStrOrNil(CurrentDirectory),
      SI,
      ProcessInfo
    );

    if Result.IsSuccess then
      with Info, ProcessInfo do
      begin
        hxProcess := TAutoHandle.Capture(hProcess);
        hxThread := TAutoHandle.Capture(hThread);
        ClientId.UniqueProcess := ProcessId;
        ClientId.UniqueThread := ThreadId;
      end;
  end;
end;

end.
