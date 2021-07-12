unit NtUtils.Processes.Create.Manual;

{
  The module provides support for completely manual process creation via
  NtCreateProcessEx.
}

interface

uses
  Ntapi.ntpsapi, NtUtils, NtUtils.Processes.Create;

// Create a process object with no threads
function NtxCreateProcessObject(
  out hxProcess: IHandle;
  hSection: THandle;
  Flags: TProcessCreateFlags;
  hParent: THandle = NtCurrentProcess;
  const ObjectAttributes: IObjectAttributes = nil;
  hDebugObject: THandle = 0
): TNtxStatus;

// Prepare and write process parameters into a process
function RtlxWriteProcessParameters(
  const Options: TCreateProcessOptions;
  const hxProcess: IHandle;
  out RemoteParamaters: IMemory
): TNtxStatus;

// Create the first thread in a process
function RtlxCreateInitialThread(
  const hxSection: IHandle;
  const Options: TCreateProcessOptions;
  const BasicInfo: TProcessBasicInformation;
  var Info: TProcessInfo
): TNtxStatus;

// Start a new process via NtCreateProcessEx
function NtxCreateProcessEx(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntstatus, Ntapi.ntmmapi, Ntapi.ntioapi, Ntapi.ntdbg,
  NtUtils.Version, NtUtils.Processes, NtUtils.Objects, NtUtils.ImageHlp,
  NtUtils.Sections, NtUtils.Files, NtUtils.Threads, NtUtils.Processes.Memory,
  NtUtils.Processes.Query, NtUtils.Processes.Create.Native;

function NtxCreateProcessObject;
var
  hProcess: THandle;
begin
  Result.Location := 'NtCreateProcessEx';
  Result.LastCall.AttachAccess<TSectionAccessMask>(SECTION_MAP_EXECUTE);

  if hParent <> NtCurrentProcess then
    Result.LastCall.AttachAccess<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if hDebugObject <> 0 then
    Result.LastCall.AttachAccess<TDebugObjectAccessMask>(DEBUG_PROCESS_ASSIGN);

  Result.Status := NtCreateProcessEx(
    hProcess,
    AccessMaskOverride(PROCESS_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    hParent,
    Flags,
    hSection,
    hDebugObject,
    0,
    0
  );

  if Result.IsSuccess then
    hxProcess := NtxObject.Capture(hProcess);
end;

function PrepareObjectAttributes(
  const Security: ISecDesc
): IObjectAttributes;
begin
  if Assigned(Security) then
    Result := AttributeBuilder.UseSecurity(Security)
  else
    Result := nil;
end;

function RtlxWriteProcessParameters;
var
  Params: IRtlUserProcessParamers;
  Adjustment: UIntPtr;
  OsVersion: TKnownOsVersion;
  i: Integer;
begin
  // Prepare process parameters locally
  Result := RtlxCreateProcessParameters(Options, Params);

  if not Result.IsSuccess then
    Exit;

  // Allocate an area within the remote process. Note that it does not need to
  // be on the heap (there is no heap yet!); the initialization code in ntdll
  // will do it for us.
  Result := NtxAllocateMemoryProcess(hxProcess, Params.Size, RemoteParamaters);

  if not Result.IsSuccess then
    Exit;

  // We need to adjust the pointers to be valid remotely
  {$Q-}{$R-}
  Adjustment := UIntPtr(RemoteParamaters.Data) - UIntPtr(Params.Data);
  {$R+}{$Q+}

  if Params.Data.CurrentDirectory.DosPath.Length > 0 then
    Inc(PByte(Params.Data.CurrentDirectory.DosPath.Buffer), Adjustment);

  if Params.Data.DLLPath.Length > 0 then
    Inc(PByte(Params.Data.DLLPath.Buffer), Adjustment);

  if Params.Data.ImagePathName.Length > 0 then
    Inc(PByte(Params.Data.ImagePathName.Buffer), Adjustment);

  if Params.Data.CommandLine.Length > 0 then
    Inc(PByte(Params.Data.CommandLine.Buffer), Adjustment);

  if Assigned(Params.Data.Environment) then
    Inc(PByte(Params.Data.Environment), Adjustment);

  if Params.Data.WindowTitle.Length > 0 then
    Inc(PByte(Params.Data.WindowTitle.Buffer), Adjustment);

  if Params.Data.DesktopInfo.Length > 0 then
    Inc(PByte(Params.Data.DesktopInfo.Buffer), Adjustment);

  if Params.Data.ShellInfo.Length > 0 then
    Inc(PByte(Params.Data.ShellInfo.Buffer), Adjustment);

  if Params.Data.RuntimeData.Length > 0 then
    Inc(PByte(Params.Data.RuntimeData.Buffer), Adjustment);

  for i := Low(Params.Data.CurrentDirectories) to
    High(Params.Data.CurrentDirectories) do
    if Params.Data.CurrentDirectories[i].Length > 0 then
      Inc(PByte(Params.Data.CurrentDirectories[i].DosPath.Buffer), Adjustment);

  OsVersion := RtlOsVersion;

  if (OsVersion >= OsWin8) and Assigned(Params.Data.PackageDependencyData) then
    Inc(PByte(Params.Data.PackageDependencyData), Adjustment);

  if (OsVersion >= OsWin10RS5) and
    (Params.Data.RedirectionDLLName.Length > 0) then
    Inc(PByte(Params.Data.RedirectionDLLName.Buffer), Adjustment);

  if (OsVersion >= OsWin1019H1) and
    (Params.Data.HeapPartitionName.Length > 0) then
    Inc(PByte(Params.Data.HeapPartitionName.Buffer), Adjustment);

  // Write the parameters to the target
  Result := NtxWriteMemoryProcess(hxProcess.Handle, RemoteParamaters.Data,
    Params.Region);
end;

function RtlxCreateInitialThread;
var
  LocalMapping: IMemory;
  Header: PImageNtHeaders;
  ThreadFlags: TThreadCreateFlags;
  RemoteImageBase: UIntPtr;
begin
  ThreadFlags := 0;

  if poSuspended in Options.Flags then
    ThreadFlags := ThreadFlags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED;

  // Map the image locally do determine various thread parameters
  Result := NtxMapViewOfSection(LocalMapping, hxSection.Handle,
    NtxCurrentProcess);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxGetNtHeaderImage(LocalMapping.Data, LocalMapping.Size, Header);

  if not Result.IsSuccess then
    Exit;

  // Determine the image base
  Result := NtxMemory.Read(Info.hxProcess.Handle,
    @BasicInfo.PebBaseAddress.ImageBaseAddress, RemoteImageBase);

  if not Result.IsSuccess then
    Exit;

  // Create the initial thread
  Result := NtxCreateThread(
    Info.hxThread,
    Info.hxProcess.Handle,
    Pointer(UIntPtr(RemoteImageBase) +
      Header.OptionalHeader.AddressOfEntryPoint),
    BasicInfo.PebBaseAddress,
    ThreadFlags,
    0,
    Header.OptionalHeader.SizeOfStackCommit,
    Header.OptionalHeader.SizeOfStackReserve,
    PrepareObjectAttributes(Options.ThreadSecurity)
  );
end;

function NtxCreateProcessEx;
var
  hxFile: IHandle;
  hxSection: IHandle;
  ProcessFlags: TProcessCreateFlags;
  TerminateOnFailure: IAutoReleasable;
  BasicInfo: TProcessBasicInformation;
  RemoteParameters: IMemory;
begin
  if Assigned(Options.Attributes.hxSection) then
    hxSection := Options.Attributes.hxSection
  else
  begin
    // Create a section form the application file
    Result := NtxOpenFile(hxFile, FILE_READ_ACCESS or FILE_EXECUTE,
      Options.ApplicationNative);

    if not Result.IsSuccess then
      Exit;

    Result := NtxCreateSection(hxSection, 0, PAGE_READONLY, SEC_IMAGE, nil,
      hxFile.Handle);

    if not Result.IsSuccess then
      Exit;
  end;

  ProcessFlags := 0;

  if poBreakawayFromJob in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_BREAKAWAY;

  if poInheritHandles in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_INHERIT_HANDLES;

  // Create a process object with no threads
  Result := NtxCreateProcessObject(
    Info.hxProcess,
    hxSection.Handle,
    ProcessFlags,
    HandleOrDefault(Options.Attributes.hxParentProcess, NtCurrentProcess),
    PrepareObjectAttributes(Options.ProcessSecurity)
  );

  if not Result.IsSuccess then
    Exit;

  // Make sure to clean up if we fail on a later stage
  TerminateOnFailure := NtxDelayedTerminateProcess(Info.hxProcess,
    STATUS_CANCELLED);

  // Determine its PEB address
  Result := NtxProcess.Query(Info.hxProcess.Handle, ProcessBasicInformation,
    BasicInfo);

  if not Result.IsSuccess then
    Exit;

  // Prepare and write process parameters
  Result := RtlxWriteProcessParameters(Options, Info.hxProcess,
    RemoteParameters);

  if not Result.IsSuccess then
    Exit;

  // Transfer the ownership of the memory region to the target
  RemoteParameters.AutoRelease := False;

  // Adjust PEB's pointer to process parameters
  Result := NtxMemory.Write(Info.hxProcess.Handle,
    @BasicInfo.PebBaseAddress.ProcessParameters, RemoteParameters.Data);

  if not Result.IsSuccess then
    Exit;

  // Create the initial thread
  Result := RtlxCreateInitialThread(hxSection, Options, BasicInfo, Info);

  if not Result.IsSuccess then
    Exit;

  // Created successfully, cancel automatic clean-up
  TerminateOnFailure.AutoRelease := False;
end;

end.
