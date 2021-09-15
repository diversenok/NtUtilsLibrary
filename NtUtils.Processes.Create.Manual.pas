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
  Flags: TProcessCreateFlags;
  [opt, Access(SECTION_MAP_EXECUTE)] hSection: THandle;
  [Access(PROCESS_CREATE_PROCESS)] hParent: THandle = NtCurrentProcess;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  [opt, Access(DEBUG_PROCESS_ASSIGN)] hDebugObject: THandle = 0
): TNtxStatus;

// Prepare and write process parameters into a process
function RtlxSetProcessParameters(
  const Options: TCreateProcessOptions;
  const hxProcess: IHandle
): TNtxStatus;

// Create the first thread in a process
function RtlxCreateInitialThread(
  [Access(SECTION_MAP_EXECUTE)] const hxSection: IHandle;
  const Options: TCreateProcessOptions;
  var Info: TProcessInfo
): TNtxStatus;

// Start a new process via NtCreateProcessEx
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoSection)]
function NtxCreateProcessEx(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ntmmapi, Ntapi.ntioapi, Ntapi.ntdbg,
  Ntapi.ImageHlp, Ntapi.Versions, NtUtils.Processes, NtUtils.Objects,
  NtUtils.ImageHlp, NtUtils.Sections, NtUtils.Files, NtUtils.Threads,
  NtUtils.Memory, NtUtils.Processes.Info, NtUtils.Processes.Create.Native;

function NtxCreateProcessObject;
var
  hProcess: THandle;
begin
  Result.Location := 'NtCreateProcessEx';
  Result.LastCall.Expects<TSectionAccessMask>(SECTION_MAP_EXECUTE);

  if hParent <> NtCurrentProcess then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if hDebugObject <> 0 then
    Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_PROCESS_ASSIGN);

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

function RtlxSetProcessParameters;
var
  Params: IRtlUserProcessParamers;
  RemoteParameters: IMemory;
  BasicInfo: TProcessBasicInformation;
  Adjustment: UIntPtr;
  OsVersion: TWindowsVersion;
  i: Integer;
begin
  // Prepare process parameters locally
  Result := RtlxCreateProcessParameters(Options, Params);

  if not Result.IsSuccess then
    Exit;

  // Allocate an area within the remote process. Note that it does not need to
  // be on the heap (there is no heap yet!); the initialization code in ntdll
  // will do it for us.
  Result := NtxAllocateMemory(hxProcess, Params.Size, RemoteParameters);

  if not Result.IsSuccess then
    Exit;

  // We need to adjust the pointers to be valid remotely
  {$Q-}{$R-}
  Adjustment := UIntPtr(RemoteParameters.Data) - UIntPtr(Params.Data);
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
  Result := NtxWriteMemory(hxProcess.Handle, RemoteParameters.Data,
    Params.Region);

  if not Result.IsSuccess then
    Exit;

  // Determine its PEB address
  Result := NtxProcess.Query(hxProcess.Handle, ProcessBasicInformation,
    BasicInfo);

  if not Result.IsSuccess then
    Exit;

  // Adjust PEB's pointer to process parameters
  Result := NtxMemory.Write(hxProcess.Handle,
    @BasicInfo.PebBaseAddress.ProcessParameters, RemoteParameters.Data);

  // Transfer the ownership of the memory region to the target
  if Result.IsSuccess then
    RemoteParameters.AutoRelease := False;
end;

function RtlxCreateInitialThread;
var
  LocalMapping: IMemory;
  Header: PImageNtHeaders;
  ThreadFlags: TThreadCreateFlags;
  RemoteImageBase: UIntPtr;
  BasicInfo: TProcessBasicInformation;
begin
  ThreadFlags := 0;

  if poSuspended in Options.Flags then
    ThreadFlags := ThreadFlags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED;

  // Map the image locally do determine various thread parameters.
  // Use PAGE_EXECUTE to pass an access check only on SECTION_MAP_EXECUTE,
  // despite mapping as a readable image. This is the bare minimum since
  // NtCreateProcessEx requires it anyway.
  Result := NtxMapViewOfSection(LocalMapping, hxSection.Handle,
    NtxCurrentProcess, PAGE_EXECUTE);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxGetNtHeaderImage(LocalMapping.Data, LocalMapping.Size, Header);

  if not Result.IsSuccess then
    Exit;

  // Determine PEB address
  Result := NtxProcess.Query(Info.hxProcess.Handle, ProcessBasicInformation,
    BasicInfo);

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
  hxSection: IHandle;
  ProcessFlags: TProcessCreateFlags;
  TerminateOnFailure: IAutoReleasable;
begin
  if Assigned(Options.Attributes.hxSection) then
    hxSection := Options.Attributes.hxSection
  else
  begin
    // Create a section form the application file
    Result := RtlxCreateImageSection(hxSection, Options.ApplicationNative);

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
    ProcessFlags,
    hxSection.Handle,
    HandleOrDefault(Options.Attributes.hxParentProcess, NtCurrentProcess),
    PrepareObjectAttributes(Options.ProcessSecurity)
  );

  if not Result.IsSuccess then
    Exit;

  // Make sure to clean up if we fail on a later stage
  TerminateOnFailure := NtxDelayedTerminateProcess(Info.hxProcess,
    STATUS_CANCELLED);

  // Prepare and write process parameters
  Result := RtlxSetProcessParameters(Options, Info.hxProcess);

  if not Result.IsSuccess then
    Exit;

  // Create the initial thread
  Result := RtlxCreateInitialThread(hxSection, Options, Info);

  if not Result.IsSuccess then
    Exit;

  // Created successfully, cancel automatic clean-up
  TerminateOnFailure.AutoRelease := False;
end;

end.
