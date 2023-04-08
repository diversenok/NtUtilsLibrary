unit NtUtils.Processes.Create.Manual;

{
  The module provides support for completely manual process creation via
  NtCreateProcessEx.
}

interface

uses
  Ntapi.ntpsapi, Ntapi.ntseapi, Ntapi.ntmmapi, NtUtils,
  NtUtils.Processes.Create;

// Create a process object with no threads
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtxCreateProcessObject(
  out hxProcess: IHandle;
  Flags: TProcessCreateFlags;
  [opt, Access(SECTION_MAP_EXECUTE)] hSection: THandle;
  [Access(PROCESS_CREATE_PROCESS)] hParent: THandle = NtCurrentProcess;
  [opt, Access(TOKEN_ASSIGN_PRIMARY)] hToken: THandle = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  [opt, Access(DEBUG_PROCESS_ASSIGN)] hDebugObject: THandle = 0
): TNtxStatus;

// Prepare and write process parameters into a process
function RtlxSetProcessParameters(
  const Options: TCreateProcessOptions;
  [Access(PROCESS_VM_OPERATION or PROCESS_VM_WRITE or
    PROCESS_QUERY_LIMITED_INFORMATION)] var Info: TProcessInfo
): TNtxStatus;

// Create the first thread in a process
function RtlxCreateInitialThread(
  const Options: TCreateProcessOptions;
  [Access(SECTION_MAP_EXECUTE or SECTION_MAP_READ),
    Access(PROCESS_CREATE_THREAD)] var Info: TProcessInfo
): TNtxStatus;

// Start a new process via NtCreateProcessEx
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoForceBreakaway)]
[SupportedOption(spoEnvironment)]
[SupportedOption(spoSecurity)]
[SupportedOption(spoWindowMode)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoToken)]
[SupportedOption(spoParentProcess)]
[SupportedOption(spoSection)]
[SupportedOption(spoAdditinalFileAccess)]
[SupportedOption(spoDetectManifest)]
[RequiredPrivilege(SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE, rpSometimes)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function NtxCreateProcessEx(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ntioapi, Ntapi.ntrtl, Ntapi.ntdbg,
  Ntapi.ImageHlp, NtUtils.Processes, NtUtils.Objects, NtUtils.ImageHlp,
  NtUtils.Sections, NtUtils.Files.Open, NtUtils.Threads, NtUtils.Memory,
  NtUtils.Processes.Info, NtUtils.Processes.Create.Native, NtUtils.Manifests,
  DelphiUtils.RangeChecks;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxCreateProcessObject;
var
  hProcess: THandle;
begin
  Result.Location := 'NtCreateProcessEx';
  Result.LastCall.Expects<TSectionAccessMask>(SECTION_MAP_EXECUTE);

  if hParent <> NtCurrentProcess then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_CREATE_PROCESS);

  if hToken <> 0 then
  begin
    Result.LastCall.ExpectedPrivilege := SE_ASSIGN_PRIMARY_TOKEN_PRIVILEGE;
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_ASSIGN_PRIMARY);
  end;

  if hDebugObject <> 0 then
    Result.LastCall.Expects<TDebugObjectAccessMask>(DEBUG_PROCESS_ASSIGN);

  if BitTest(Flags and PROCESS_CREATE_FLAGS_FORCE_BREAKAWAY) then
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  Result.Status := NtCreateProcessEx(
    hProcess,
    AccessMaskOverride(PROCESS_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    hParent,
    Flags,
    hSection,
    hDebugObject,
    hToken,
    0
  );

  if Result.IsSuccess then
    hxProcess := Auto.CaptureHandle(hProcess);
end;

function PrepareObjectAttributes(
  const Security: ISecurityDescriptor
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
begin
  // Prepare process parameters locally
  Result := RtlxCreateProcessParameters(Options, Params);

  if not Result.IsSuccess then
    Exit;

  // Since we are copying parameters to a different address,
  // switch to offsets instead of absolute pointers.
  RtlDeNormalizeProcessParams(Params.Data);

  Include(Info.ValidFields, piUserProcessParametersFlags);
  Info.UserProcessParametersFlags := Params.Data.Flags;

  // Allocate an area within the remote process. Note that it does not need to
  // be on the heap (there is no heap yet!); the initialization code in ntdll
  // will copy it into the heap for us.
  Result := NtxAllocateMemory(Info.hxProcess, Params.Size, RemoteParameters,
    PAGE_READWRITE);

  if not Result.IsSuccess then
    Exit;

  // Unfortunately, denormalization doesn't make the environment pointer
  // relative; Fix it by manually changing it to the remote address.
  {$Q-}{$R-}
  UIntPtr(Params.Data.Environment) := UIntPtr(Params.Data.Environment) -
    UIntPtr(Params.Data) + UIntPtr(RemoteParameters.Data);
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

  // Write the parameters to the target
  Result := NtxWriteMemory(Info.hxProcess.Handle, RemoteParameters.Data,
    Params.Region);

  if not Result.IsSuccess then
    Exit;

  // Determine the PEB address
  Result := NtxProcess.Query(Info.hxProcess.Handle, ProcessBasicInformation,
    BasicInfo);

  if not Result.IsSuccess then
    Exit;

  // Adjust PEB's pointer to process parameters
  Result := NtxMemory.Write(Info.hxProcess.Handle,
    @BasicInfo.PebBaseAddress.ProcessParameters, RemoteParameters.Data);

  if not Result.IsSuccess then
    Exit;

  Include(Info.ValidFields, piUserProcessParameters);
  Info.UserProcessParameters := RemoteParameters.Data;

  // Transfer the ownership of the memory region to the target
  RemoteParameters.AutoRelease := False;
end;

function RtlxGetInitialThreadParameters(
  const Image: TMemory;
  out EntryPointRva: Cardinal;
  out StackCommit: Cardinal;
  out StackReserve: Cardinal
): TNtxStatus;
var
  Header: PImageNtHeaders;
  Bitness: TImageBitness;
begin
  try
    Result := RtlxGetNtHeaderImage(Header, Image);

    if not Result.IsSuccess then
      Exit;

    Result := RtlxGetImageBitness(Bitness, Image, Header);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'RtlxGetInitialThreadParameters';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;

    case Bitness of
      ib32Bit:
        if not CheckStruct(Image, Header, UIntPtr(@PImageNtHeaders(nil)
          .OptionalHeader32.SizeOfStackCommit) + SizeOf(Cardinal)) then
          Exit;

      ib64Bit:
        if not CheckStruct(Image, Header, UIntPtr(@PImageNtHeaders(nil)
          .OptionalHeader64.SizeOfStackCommit) + SizeOf(UInt64)) then
          Exit;
    end;

    EntryPointRva := Header.OptionalHeader.AddressOfEntryPoint;
    StackCommit := Header.OptionalHeader.SizeOfStackCommit;
    StackReserve := Header.OptionalHeader.SizeOfStackReserve;
    Result.Status := STATUS_SUCCESS;
  except
    Result.Location := 'RtlxGetInitialThreadParameters';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxCreateInitialThread;
var
  LocalMapping: IMemory;
  ThreadFlags: TThreadCreateFlags;
  RemoteImageBase: Pointer;
  BasicInfo: TProcessBasicInformation;
  ThreadInfo: TThreadInfo;
  ManifestRva: TMemory;
  EntryPointRva: Cardinal;
  StackCommit: Cardinal;
  StackReserve: Cardinal;
begin
  ThreadFlags := 0;

  if poSuspended in Options.Flags then
    ThreadFlags := ThreadFlags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED;

  // Map the image locally do determine various thread parameters.
  // Use PAGE_EXECUTE to pass an access check only on SECTION_MAP_EXECUTE,
  // despite mapping as a readable image. This is the bare minimum since
  // NtCreateProcessEx requires it anyway.
  Result := NtxMapViewOfSection(LocalMapping, Info.hxSection.Handle,
    NtxCurrentProcess, PAGE_EXECUTE);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxGetInitialThreadParameters(LocalMapping.Region, EntryPointRva,
    StackCommit, StackReserve);

  if not Result.IsSuccess then
    Exit;

  // Determine PEB address
  Result := NtxProcess.Query(Info.hxProcess.Handle, ProcessBasicInformation,
    BasicInfo);

  if not Result.IsSuccess then
    Exit;

  Include(Info.ValidFields, piPebAddress);
  Info.PebAddressNative := BasicInfo.PebBaseAddress;

  // Determine the remote image base
  Result := NtxMemory.Read(Info.hxProcess.Handle,
    @BasicInfo.PebBaseAddress.ImageBaseAddress, RemoteImageBase);

  if not Result.IsSuccess then
    Exit;

  Include(Info.ValidFields, piImageBase);
  Info.ImageBaseAddress := RemoteImageBase;

  // Find embedded manifest if required
  if poDetectManifest in Options.Flags then
    if RtlxFindManifestInSection(Info.hxSection.Handle,
      ManifestRva).IsSuccess then
    begin
      Inc(PByte(ManifestRva.Address), UIntPtr(RemoteImageBase));
      Include(Info.ValidFields, piManifest);
      Info.Manifest := ManifestRva;
    end;

  // Create the initial thread
  Result := NtxCreateThreadEx(
    Info.hxThread,
    Info.hxProcess.Handle,
    Pointer(UIntPtr(RemoteImageBase) + EntryPointRva),
    BasicInfo.PebBaseAddress,
    ThreadFlags,
    0,
    StackCommit,
    StackReserve,
    PrepareObjectAttributes(Options.ThreadSecurity),
    @ThreadInfo
  );

  if not Result.IsSuccess then
    Exit;

  Info.ValidFields := Info.ValidFields + [piProcessID, piThreadID,
    piThreadHandle, piTebAddress];
  Info.ClientId := ThreadInfo.ClientID;
  Info.TebAddress := ThreadInfo.TebAddress;
end;

function NtxCreateProcessEx;
var
  ProcessFlags: TProcessCreateFlags;
  TerminateOnFailure: IAutoReleasable;
begin
  Info := Default(TProcessInfo);

  if Assigned(Options.hxSection) then
    Info.hxSection := Options.hxSection
  else
  begin
    // Open the executable file. Note that as long as we don't specify execute
    // protection for the section, we don't even need FILE_EXECUTE.
    Result := NtxOpenFile(Info.hxFile, FileParameters
      .UseOptions(FILE_NON_DIRECTORY_FILE)
      .UseAccess(FILE_READ_DATA or Options.AdditionalFileAccess)
      .UseFileName(Options.ApplicationNative)
    );

    if not Result.IsSuccess then
      Exit;

    Include(Info.ValidFields, piFileHandle);

    // Create an image section from the file. Note that the call uses
    // PAGE_READONLY only for access checks on the file, not the page protection
    Result := NtxCreateFileSection(Info.hxSection, Info.hxFile.Handle,
      PAGE_READONLY, SEC_IMAGE);

    if not Result.IsSuccess then
      Exit;
  end;

  Include(Info.ValidFields, piSectionHandle);
  ProcessFlags := 0;

  if poBreakawayFromJob in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_BREAKAWAY;

  if poForceBreakaway in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_FORCE_BREAKAWAY;

  if poInheritHandles in Options.Flags then
    ProcessFlags := ProcessFlags or PROCESS_CREATE_FLAGS_INHERIT_HANDLES;

  // Create a process object with no threads
  Result := NtxCreateProcessObject(
    Info.hxProcess,
    ProcessFlags,
    Info.hxSection.Handle,
    HandleOrDefault(Options.hxParentProcess, NtCurrentProcess),
    HandleOrDefault(Options.hxToken),
    PrepareObjectAttributes(Options.ProcessSecurity)
  );

  if not Result.IsSuccess then
    Exit;

  Include(Info.ValidFields, piProcessHandle);

  // Make sure to clean up if we fail on a later stage
  TerminateOnFailure := NtxDelayedTerminateProcess(Info.hxProcess,
    STATUS_CANCELLED);

  // Prepare and write process parameters
  Result := RtlxSetProcessParameters(Options, Info);

  if not Result.IsSuccess then
    Exit;

  // Create the initial thread
  Result := RtlxCreateInitialThread(Options, Info);

  if not Result.IsSuccess then
    Exit;

  // Created successfully, cancel automatic clean-up
  TerminateOnFailure.AutoRelease := False;
end;

end.
