unit NtUtils.Shellcode.Exe;

{
  This module provides support for injecting EXE files into existing
  processes so that a single process can host multiple programs.
}

interface

uses
  Ntapi.ntpsapi, DelphiApi.Reflection, NtUtils, NtUtils.Shellcode,
  NtUtils.Shellcode.Dll;

const
  PROCESS_INJECT_EXE = PROCESS_SUSPEND_RESUME or PROCESS_INJECT_DLL or
    PROCESS_VM_WRITE;

// Load and start an EXE in a context of an existing process
function RtlxInjectExeProcess(
  [Access(PROCESS_INJECT_EXE)] hxProcess: IHandle;
  const FileName: String;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT;
  ThreadFlags: TThreadCreateFlags = 0
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.WinError, Ntapi.ntdef, Ntapi.ntmmapi,
  Ntapi.ntwow64, Ntapi.ImageHlp, Ntapi.ntdbg, Ntapi.Versions, NtUtils.Errors,
  NtUtils.Debug, NtUtils.Synchronization, NtUtils.Threads, NtUtils.Sections,
  NtUtils.ImageHlp, NtUtils.Processes, NtUtils.Processes.Info, NtUtils.Memory;

// Adjust image headers to make an EXE appear as a DLL
function RtlxpConvertMappedExeToDll(
  const hxProcess: IHandle;
  const hxFile: IHandle;
  [in] RemoteBase: Pointer;
  out Entrypoint: Pointer;
  out StackSize: Cardinal;
  out MaxStackSize: Cardinal;
  out RequiresConsole: Boolean
): TNtxStatus;
var
  Attributes: TAllocationAttributes;
  hxSection: IHandle;
  LocalMapping: IMemory;
  Headers: PImageNtHeaders;
  Reverter: IAutoReleasable;
  pCharacteristics: PWord;
  pEntrypointAddress: PCardinal;
  NewCharacteristics: TImageCharacteristics;
begin
  if not Assigned(hxFile) then
  begin
    // Got a phantom image; not our EXE
    Result.Location := 'RtlxpConvertMappedExeToDll';
    Result.Status := STATUS_RETRY;
    Exit;
  end;

  if RtlOsVersionAtLeast(OsWin8) then
    Attributes := SEC_IMAGE_NO_EXECUTE
  else
    Attributes := SEC_IMAGE;

  // Prepare an image section from the file
  Result := NtxCreateFileSection(hxSection, hxFile.Handle, PAGE_READONLY,
    Attributes);

  if not Result.IsSuccess then
    Exit;

  // Map the section for parsing
  Result := NtxMapViewOfSection(LocalMapping, hxSection.Handle,
    NtxCurrentProcess, PAGE_READONLY);

  if not Result.IsSuccess then
    Exit;

  // Locate the headers
  Result := RtlxGetNtHeaderImage(LocalMapping.Data, LocalMapping.Size, Headers);

  if not Result.IsSuccess then
    Exit;

  if BitTest(Headers.FileHeader.Characteristics and IMAGE_FILE_DLL) then
  begin
    // The file is not an EXE
    Result.Location := 'RtlxpConvertMappedExeToDll';
    Result.Status := STATUS_RETRY;
    Exit;
  end;

  StackSize := Headers.OptionalHeader.SizeOfStackCommit;
  MaxStackSize := Headers.OptionalHeader.SizeOfStackReserve;
  RequiresConsole := (Headers.OptionalHeader.Subsystem =
    IMAGE_SUBSYSTEM_WINDOWS_CUI);

  // Set the DLL flag
  NewCharacteristics := Headers.FileHeader.Characteristics or IMAGE_FILE_DLL;

  UIntPtr(pCharacteristics) := UIntPtr(RemoteBase) + (
    UIntPtr(@Headers.FileHeader.Characteristics) - UIntPtr(LocalMapping.Data));

  // Save the original entrypoint
  if Headers.OptionalHeader.AddressOfEntryPoint <> 0 then
    Entrypoint := PByte(RemoteBase) + Headers.OptionalHeader.AddressOfEntryPoint
  else
    Entrypoint := nil;

  UIntPtr(pEntrypointAddress) := UIntPtr(RemoteBase) +
    (UIntPtr(@Headers.OptionalHeader.AddressOfEntryPoint) -
    UIntPtr(LocalMapping.Data));

  // Make both fields writable
  Result := NtxProtectMemoryAuto(hxProcess, pCharacteristics,
    UIntPtr(pEntrypointAddress) - UIntPtr(pCharacteristics), PAGE_READWRITE,
    Reverter);

  if not Result.IsSuccess then
    Exit;

  // Update image characteristics
  Result := NtxMemory.Write(hxProcess.Handle, pCharacteristics,
    NewCharacteristics);

  if not Result.IsSuccess then
    Exit;

  // Clear the entrypoint address
  Result := NtxMemory.Write<Cardinal>(hxProcess.Handle, pEntrypointAddress, 0);
end;

function RtlxInjectExeProcess;
var
  hxDebugObject: IHandle;
  Entrypoint: Pointer;
  StackSize: Cardinal;
  MaxStackSize: Cardinal;
  RequiresConsole: Boolean;
  AlreadyDetached: Boolean;
  hxThread: IHandle;
  BasicInfo: TProcessBasicInformation;
  WoW64Peb: PPeb32;
  CreateFlags: TThreadCreateFlags;
  AllocConsole: Pointer;
  ApcOptions: TThreadApcOptions;
begin
  // We want to inject an EXE by re-using the DLL injection mechanism.
  // However, while LdrLoadDll does allow loading EXEs, it won't resolve their
  // imports. As a workaround, we perform injection under debugging, so we
  // can patch the Characteristics fields of the provided image to make it
  // appear as a DLL. At the same time, we clear (and save for later)
  // the entrypoint address in the headers to make sure that Ldr doesn't invoke
  // it (the prototypes for DLL and EXE entrypoints differ). The patching
  // happens on the image load event, i.e., after the target maps the EXE but
  // before it starts parsing it. Then, after a successful loading, we detach
  // and start a new thread to execute EXE's entrypoint.

  // Prevent WoW64 -> Native injection
  Result := RtlxAssertWoW64CompatiblePeb(hxProcess.Handle, WoW64Peb);

  if not Result.IsSuccess then
    Exit;

  Entrypoint := nil;
  AlreadyDetached := False;

  // Create a debug object for attaching to the target
  Result := NtxCreateDebugObject(hxDebugObject);

  if not Result.IsSuccess then
    Exit;

  // Start debugging the process
  Result := NtxDebugProcess(hxProcess.Handle, hxDebugObject.Handle);

  if not Result.IsSuccess then
    Exit;

  // Inject the EXE as a if it's a DLL and use a custom waiting callback
  // to acknowledge generated debug events and patch image headers
  Result := RtlxInjectDllProcess(hxProcess, FileName, Timeout, nil, nil,
    function (
      const hxProcess: IHandle;
      const hxThread: IHandle;
      const Timeout: Int64
    ): TNtxStatus
    var
      ThreadInfo: TThreadBasicInformation;
      WaitState: TDbgxWaitState;
      DebugHandles: TDbgxHandles;
      EncounteredExe: Boolean;
      Status: NTSTATUS;
    begin
      EncounteredExe := False;
      Result.Status := STATUS_SUCCESS;

      try
        // Determine the client ID of the injector thread
        Result := NtxThread.Query(hxThread.Handle, ThreadBasicInformation,
          ThreadInfo);

        if not Result.IsSuccess then
          Exit;

        // Start processing debug events
        while NtxDebugWait(hxDebugObject.Handle, WaitState, DebugHandles,
          Timeout).Save(Result) do
        begin
          if Result.IsFailOrTimeout then
            Exit;

          // Abort if the target exits
          if (WaitState.NewState = DbgExitProcessStateChange) and (WaitState.
            AppClientId.UniqueProcess = ThreadInfo.ClientId.UniqueProcess) then
          begin
            Result.Location := 'RtlxInjectExeProcess';
            Result.Status := STATUS_PROCESS_IS_TERMINATING;
            Exit;
          end;

          // Select a suitable continue code
          case WaitState.NewState of
            DbgExceptionStateChange, DbgBreakpointStateChange,
            DbgSingleStepStateChange:
              Status := DBG_EXCEPTION_NOT_HANDLED;
          else
            Status := DBG_CONTINUE;
          end;

          // We are only interested in specific events from the injected thread
          if WaitState.AppClientId = ThreadInfo.ClientId then
            case WaitState.NewState of
              DbgExitThreadStateChange:
              begin
                // Forward the result
                Result.Location := 'Remote::LdrLoadDll';
                Result.Status := WaitState.ExitThread.ExitStatus;

                if Result.IsSuccess and not EncounteredExe then
                begin
                  // We were either given a DLL instead of an EXE,
                  // or the file was already loaded into the process.
                  Result.Location := 'RtlxInjectExeProcess';
                  Result.Status := STATUS_UNSUCCESSFUL;
                end;

                Exit;
              end;

              DbgLoadDllStateChange:
              begin
                // The target mapped the file but haven't processed it yet since
                // it's frozen. If it's an EXE, adjust the image headers to
                // pretend that the module is a DLL so that LdrLoadDll resolves
                // its imports.

                Result := RtlxpConvertMappedExeToDll(hxProcess,
                  DebugHandles.hxFile, WaitState.LoadDll.BaseOfDll, Entrypoint,
                    StackSize, MaxStackSize, RequiresConsole);

                // Note: we don't exit on the first EXE encounter because we
                // might need to patch it twice under WoW64.

                if Result.IsSuccess then
                  EncounteredExe := True
                else if Result.Matches(STATUS_RETRY,
                  'RtlxpConvertMappedExeToDll') then
                  // the event was not about our image; continue processing
                else
                  Exit;
              end;
            end;

          // Acknowledge the debug event
          Result := NtxDebugContinue(hxDebugObject.Handle,
            WaitState.AppClientId, Status);

          if not Result.IsSuccess then
            Exit;
        end;
      finally
        // We are done with debugging. Detach to allow pending thread termiation
        // to complete.
        NtxDebugProcessStop(hxProcess.Handle, hxDebugObject.Handle);
        AlreadyDetached := True;

        case Result.Status of
          STATUS_TIMEOUT, STATUS_WAIT_TIMEOUT:
            ; // Already waited and timed out, no need to do it again
        else
          // We still want to wait and clean-up after shellcode injection
          NtxWaitForSingleObject(hxThread.Handle, Timeout);
        end;
      end;
    end
  );

  // No need to debug the target anymore
  if not AlreadyDetached then
    NtxDebugProcessStop(hxProcess.Handle, hxDebugObject.Handle);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(Entrypoint) then
  begin
    // The injection succeeded, but the provided image doesn't have an
    // entrypoint we can invoke
    Result.Location := 'RtlxInjectExeProcess';
    Result.Win32Error := STATUS_BAD_DLL_ENTRYPOINT;
    Exit;
  end;

  // Locate Native/WoW64 PEB
{$IFDEF Win64}
  if Assigned(WoW64Peb) then
    BasicInfo.PebBaseAddress := Pointer(WoW64Peb)
  else
{$ENDIF}
    Result := NtxProcess.Query(hxProcess.Handle, ProcessBasicInformation,
      BasicInfo);

  if not Result.IsSuccess then
    Exit;

  // Allocating a console requires more steps
  if RequiresConsole then
    CreateFlags := ThreadFlags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED
  else
    CreateFlags := ThreadFlags;

  // Create a thread to execute EXE's entrypoint
  Result := NtxCreateThread(hxThread, hxProcess.Handle, Entrypoint,
    BasicInfo.PebBaseAddress, CreateFlags, 0, StackSize, MaxStackSize);

  if not Result.IsSuccess then
    Exit;

  if RequiresConsole then
  begin
    // Locate AllocConsole
    Result := RtlxFindKnownDllExport(kernel32, Assigned(WoW64Peb),
      'AllocConsole', AllocConsole);

    if not Result.IsSuccess then
      Exit;

    if Assigned(WoW64Peb) then
      ApcOptions := [apcWoW64]
    else
      ApcOptions := [];

    // Queue an APC that allocates the console before the thread starts
    Result := NtxQueueApcThreadEx(hxThread.Handle, AllocConsole, nil, nil, nil,
      ApcOptions);

    if not Result.IsSuccess then
      Exit;

    // Resume if necessary
    if CreateFlags <> ThreadFlags then
      Result := NtxResumeThread(hxThread.Handle);
  end;
end;

end.
