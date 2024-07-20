unit NtUtils.Shellcode.Exe;

{
  This module provides support for injecting EXE files into existing
  processes so that a single process can host multiple programs.
}

interface

uses
  Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode, NtUtils.Shellcode.Dll;

const
  PROCESS_INJECT_EXE = PROCESS_SUSPEND_RESUME or PROCESS_INJECT_DLL or
    PROCESS_VM_READ or PROCESS_VM_WRITE;

  dioAutoIgnoreWoW64 = NtUtils.Shellcode.Dll.dioAutoIgnoreWoW64;
  dioAdjustCurrentDirectory = NtUtils.Shellcode.Dll.dioAdjustCurrentDirectory;

// Load and start an EXE in a context of an existing process
function RtlxInjectExeProcess(
  [Access(PROCESS_INJECT_EXE)] const hxProcess: IHandle;
  const FileName: String;
  Options: TDllInjectionOptions = [dioAutoIgnoreWoW64, dioAdjustCurrentDirectory];
  ThreadFlags: TThreadCreateFlags = 0;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT;
  [out, opt] ExeBase: PPointer = nil
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.WinError, Ntapi.ntdef, Ntapi.ntmmapi,
  Ntapi.ntwow64, Ntapi.ImageHlp, Ntapi.ntdbg, NtUtils.Errors, NtUtils.Debug,
  NtUtils.Synchronization, NtUtils.Threads, NtUtils.Sections, NtUtils.ImageHlp,
  NtUtils.Processes, NtUtils.Processes.Info, NtUtils.Memory;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

// Adjust image headers to make an EXE appear as a DLL
function RtlxpConvertMappedExeToDll(
  const hxProcess: IHandle;
  [in] RemoteBase: PImageDosHeader;
  out Entrypoint: Pointer;
  out StackSize: UInt64;
  out MaxStackSize: UInt64;
  out RequiresConsole: Boolean
): TNtxStatus;
var
  DosMagic, OptionalMagic: Word;
  NtHeaderOffset, NtHeaderMagic: Cardinal;
  RemoteNtHeader: PImageNtHeaders;
  ImageCharacteristics: TImageCharacteristics;
  Is64BitImage: Boolean;
  EntrypointRVA, StackSize32, MaxStackSize32: Cardinal;
  Subsystem: TImageSubsystem;
  ProtectionReverter: IAutoReleasable;
begin
  // Verify the DOS header magic
  Result := NtxMemory.Read(hxProcess, @RemoteBase.e_magic, DosMagic);

  if not Result.IsSuccess then
    Exit;

  if DosMagic <> IMAGE_DOS_SIGNATURE then
  begin
    Result.Location := 'RtlxpConvertMappedExeToDll';
    Result.Status := STATUS_INVALID_IMAGE_NOT_MZ;
    Exit;
  end;

  // Read the NT header offset
  Result := NtxMemory.Read(hxProcess, @RemoteBase.e_lfanew,
    NtHeaderOffset);

  if not Result.IsSuccess then
    Exit;

  Pointer(RemoteNtHeader) := PByte(RemoteBase) + NtHeaderOffset;

  // Verify the NT header magic
  Result := NtxMemory.Read(hxProcess, @RemoteNtHeader.Signature,
    NtHeaderMagic);

  if not Result.IsSuccess then
    Exit;

  if NtHeaderMagic <> IMAGE_NT_SIGNATURE then
  begin
    Result.Location := 'RtlxpConvertMappedExeToDll';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;
    Exit;
  end;

  // Read the image characteristics
  Result := NtxMemory.Read(hxProcess,
    @RemoteNtHeader.FileHeader.Characteristics,
    ImageCharacteristics);

  if not Result.IsSuccess then
    Exit;

  if BitTest(ImageCharacteristics and IMAGE_FILE_DLL) then
  begin
    // The file is not an EXE
    Result.Location := 'RtlxpConvertMappedExeToDll';
    Result.Status := STATUS_RETRY;
    Exit;
  end;

  // Determine image bitness
  Result := NtxMemory.Read(hxProcess,
    @RemoteNtHeader.OptionalHeader.Magic, OptionalMagic);

  if not Result.IsSuccess then
    Exit;

  case OptionalMagic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Is64BitImage := False;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Is64BitImage := True;
  else
    // Something else?
    Result.Location := 'RtlxpConvertMappedExeToDll';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;
    Exit;
  end;

  // Read the entrypoint RVA
  Result := NtxMemory.Read(hxProcess,
    @RemoteNtHeader.OptionalHeader.AddressOfEntryPoint, EntrypointRVA);

  if not Result.IsSuccess then
    Exit;

  Pointer(Entrypoint) := PByte(RemoteBase) + EntrypointRVA;

  // Read the suggested stack size
  if Is64BitImage then
    Result := NtxMemory.Read(hxProcess,
      @RemoteNtHeader.OptionalHeader64.SizeOfStackCommit, StackSize)
  else
    Result := NtxMemory.Read(hxProcess,
      @RemoteNtHeader.OptionalHeader32.SizeOfStackCommit, StackSize32);

  if not Result.IsSuccess then
    Exit;

  if not Is64BitImage then
    StackSize := StackSize32;

  // Read the suggested stack reserve size
  if Is64BitImage then
    Result := NtxMemory.Read(hxProcess,
      @RemoteNtHeader.OptionalHeader64.SizeOfStackReserve, MaxStackSize)
  else
    Result := NtxMemory.Read(hxProcess,
      @RemoteNtHeader.OptionalHeader32.SizeOfStackReserve, MaxStackSize32);

  if not Result.IsSuccess then
    Exit;

  if not Is64BitImage then
    MaxStackSize := MaxStackSize32;

  // Read the subsystem
  Result := NtxMemory.Read(hxProcess,
    @RemoteNtHeader.OptionalHeader.Subsystem, Subsystem);

  if not Result.IsSuccess then
    Exit;

  RequiresConsole := Subsystem = IMAGE_SUBSYSTEM_WINDOWS_CUI;

  // Make the image characteristics field writable
  Result := NtxProtectMemoryAuto(hxProcess,
    @RemoteNtHeader.FileHeader.Characteristics, SizeOf(ImageCharacteristics),
    PAGE_READWRITE, ProtectionReverter);

  if not Result.IsSuccess then
    Exit;

  // Set the DLL flag
  ImageCharacteristics := ImageCharacteristics or IMAGE_FILE_DLL;

  Result := NtxMemory.Write(hxProcess,
    @RemoteNtHeader.FileHeader.Characteristics, ImageCharacteristics);

  if not Result.IsSuccess then
    Exit;

  // Make the entrypoint field writable
  Result := NtxProtectMemoryAuto(hxProcess,
    @RemoteNtHeader.OptionalHeader.AddressOfEntryPoint, SizeOf(Cardinal),
    PAGE_READWRITE, ProtectionReverter);

  if not Result.IsSuccess then
    Exit;

  // Clear the entrypoint address
  Result := NtxMemory.Write<Cardinal>(hxProcess,
    @RemoteNtHeader.OptionalHeader.AddressOfEntryPoint, 0);
end;

function RtlxInjectExeProcess;
var
  hxDebugObject: IHandle;
  Entrypoint: Pointer;
  StackSize: UInt64;
  MaxStackSize: UInt64;
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
  Result := RtlxAssertWoW64CompatiblePeb(hxProcess, WoW64Peb);

  if not Result.IsSuccess then
    Exit;

  Entrypoint := nil;
  AlreadyDetached := False;
  Exclude(Options, dioUnloadImmediately);

  // Create a debug object for attaching to the target
  Result := NtxCreateDebugObject(hxDebugObject);

  if not Result.IsSuccess then
    Exit;

  // Start debugging the process
  Result := NtxDebugProcess(hxProcess, hxDebugObject);

  if not Result.IsSuccess then
    Exit;

  // Inject the EXE as a if it's a DLL and use a custom waiting callback
  // to acknowledge generated debug events and patch image headers
  Result := RtlxInjectDllProcess(hxProcess, FileName, Options, ThreadFlags,
    Timeout,
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
      Result := NtxSuccess;

      try
        // Determine the client ID of the injector thread
        Result := NtxThread.Query(hxThread, ThreadBasicInformation, ThreadInfo);

        if not Result.IsSuccess then
          Exit;

        // Start processing debug events
        while NtxDebugWait(hxDebugObject, WaitState, DebugHandles,
          Timeout).SaveTo(Result).IsSuccess do
        begin
          // Make timeouts unsuccessful
          if Result.Status = STATUS_TIMEOUT then
          begin
            Result.Status := STATUS_WAIT_TIMEOUT;
            Exit;
          end;

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
                  WaitState.LoadDll.BaseOfDll, Entrypoint, StackSize,
                  MaxStackSize, RequiresConsole);

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
          Result := NtxDebugContinue(hxDebugObject, WaitState.AppClientId,
            Status);

          if not Result.IsSuccess then
            Exit;
        end;
      finally
        // We are done with debugging. Detach to allow pending thread termination
        // to complete.
        NtxDebugProcessStop(hxProcess, hxDebugObject);
        AlreadyDetached := True;

        case Result.Status of
          STATUS_TIMEOUT, STATUS_WAIT_TIMEOUT:
            ; // Already waited and timed out, no need to do it again
        else
          // We still want to wait and clean-up after shellcode injection
          NtxWaitForSingleObject(hxThread, Timeout);
        end;
      end;
    end,
    ExeBase
  );

  // No need to debug the target anymore
  if not AlreadyDetached then
    NtxDebugProcessStop(hxProcess, hxDebugObject);

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
    Result := NtxProcess.Query(hxProcess, ProcessBasicInformation, BasicInfo);

  if not Result.IsSuccess then
    Exit;

  // Allocating a console requires more steps
  if RequiresConsole then
    CreateFlags := ThreadFlags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED
  else
    CreateFlags := ThreadFlags;

  // Create a thread to execute EXE's entrypoint
  Result := NtxCreateThreadEx(hxThread, hxProcess, Entrypoint,
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
    Result := NtxQueueApcThreadEx(hxThread, AllocConsole, nil, nil, nil,
      ApcOptions);

    if not Result.IsSuccess then
      Exit;

    // Resume if necessary
    if CreateFlags <> ThreadFlags then
      Result := NtxResumeThread(hxThread);
  end;
end;

end.
