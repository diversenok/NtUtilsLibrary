unit NtUtils.Shellcode.Dll;

{
  This module provides support for improved DLL injection.
}

interface

uses
  Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode, DelphiApi.Reflection;

const
  PROCESS_INJECT_DLL = NtUtils.Shellcode.PROCESS_REMOTE_EXECUTE;

type
  TDllInjectionOptions = set of (
    // Force using 64-bit mode injection in WoW64 processes
    dioIgnoreWoW64,

    // Automatically determine if the DLL requires a 32- or 64- bit injection
    dioAutoIgnoreWoW64,

    // Temporarily change the current directory to the file location
    dioAdjustCurrentDirectory,

    // Unload the DLL immediately after loading
    dioUnloadImmediately
  );

// Force another process into loading a DLL
function RtlxInjectDllProcess(
  [Access(PROCESS_INJECT_DLL)] const hxProcess: IHandle;
  const DllPath: String;
  Options: TDllInjectionOptions = [dioAutoIgnoreWoW64];
  ThreadFlags: TThreadCreateFlags = 0;
  [opt] const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT;
  [opt] const CustomWait: TCustomWaitRoutine = nil;
  [out, opt] DllBase: PPointer = nil
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntldr, Ntapi.ntstatus, Ntapi.ntpebteb,
  Ntapi.ntioapi, Ntapi.ntmmapi, Ntapi.ImageHlp, Ntapi.Versions,
  DelphiUtils.AutoObjects, NtUtils.Processes.Info,  NtUtils.Threads,
  NtUtils.Files.Open, NtUtils.Sections;

type
  TDllLoaderContext = record
    RtlSetThreadErrorMode: function (
      NewMode: TRtlErrorMode;
      [out, opt] OldMode: PRtlErrorMode
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding0: Cardinal;{$ENDIF}

    RtlGetCurrentDirectory_U: function (
      BufferLength: Cardinal;
      [out] Buffer: PWideChar
    ): Cardinal; stdcall;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}

    RtlSetCurrentDirectory_U: function (
      const PathName: TNtUnicodeString
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}

    LdrLockLoaderLock: function(
      Options: TLdrLockFlags;
      var Disposition: TLdrLoaderLockDisposition;
      out Cookie: NativeUInt
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding3: Cardinal;{$ENDIF}

    LdrUnlockLoaderLock: function (
      Options: TLdrLockFlags;
      Cookie: NativeUInt
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding4: Cardinal;{$ENDIF}

    LdrLoadDll: function (
      [in, opt] DllPath: PWideChar;
      [in, opt] DllCharacteristics: PCardinal;
      const DllName: TNtUnicodeString;
      out DllHandle: HMODULE
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding5: Cardinal;{$ENDIF}

    LdrUnloadDll: function (
      DllHandle: HMODULE
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding6: Cardinal;{$ENDIF}

    [out] DllHandle: HMODULE;
    {$IFDEF Win32}WoW64Padding7: Cardinal;{$ENDIF}

    [out] Status: NTSTATUS;
    DllNameLength: Word;
    DllDirectoryLength: Word;
    UnloadImmediately: LongBool;
    AdjustCurrentDirectory: LongBool;
    PreviousDirectory: array [MAX_LONG_PATH_ARRAY] of WideChar;
    DllName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PDllLoaderContext = ^TDllLoaderContext;

// A function to execute in a context of another process.
// Notes:
//  - Only call routines referenced via the context parameter;
//  - Keep in sync with raw assembly bytes below.
procedure Payload(
  Context: PDllLoaderContext;
  Unused1: Pointer;
  Ununsed2: Pointer
); stdcall;
var
  Disposition: TLdrLoaderLockDisposition;
  Cookie: NativeUInt;
  PreviousDirectoryLength: Cardinal;
  Path: TNtUnicodeString;
begin
  // Suppress error messages
  Context.RtlSetThreadErrorMode(RTL_ERRORMODE_FAILCRITICALERRORS or
    RTL_ERRORMODE_NOGPFAULTERRORBOX, nil);

  // Try to acquire the loader lock to prevent possible deadlocks
  Context.Status := Context.LdrLockLoaderLock(
    LDR_LOCK_LOADER_LOCK_FLAG_TRY_ONLY, Disposition, Cookie);

  if not NT_SUCCESS(Context.Status) then
    Exit;

  case Disposition of
    // Undo acquiring if necessary
    LDR_LOCK_LOADER_LOCK_DISPOSITION_LOCK_ACQUIRED:
      Context.LdrUnlockLoaderLock(0, Cookie);

    // Can't load DLLs now, exit
    LDR_LOCK_LOADER_LOCK_DISPOSITION_LOCK_NOT_ACQUIRED:
    begin
      Context.Status := STATUS_POSSIBLE_DEADLOCK;
      Exit;
    end;
  end;

  if Context.AdjustCurrentDirectory then
  begin
    // Backup the current directory
    PreviousDirectoryLength := Context.RtlGetCurrentDirectory_U(
      SizeOf(Context.PreviousDirectory), @Context.PreviousDirectory[0]);

    // Make sure backing up was successful
    Context.AdjustCurrentDirectory := (PreviousDirectoryLength > 0) and
      (PreviousDirectoryLength <= High(Word));

    // Adjust the current directory to the location of the DLL
    Path.Buffer := @Context.DllName[0];
    Path.Length := Context.DllDirectoryLength;
    Path.MaximumLength := Context.DllDirectoryLength;
    Context.RtlSetCurrentDirectory_U(Path);
  end
  else
    PreviousDirectoryLength := 0;

  // Load the DLL
  Path.Buffer := @Context.DllName[0];
  Path.Length := Context.DllNameLength;
  Path.MaximumLength := Context.DllNameLength;
  Context.Status := Context.LdrLoadDll(nil, nil, Path, Context.DllHandle);

  // Unload if necessary
  if Context.UnloadImmediately and NT_SUCCESS(Context.Status) then
    Context.LdrUnloadDll(Context.DllHandle);

  if Context.AdjustCurrentDirectory then
  begin
    // Restore the previous current directory
    Path.Buffer := @Context.PreviousDirectory[0];
    Path.Length := Word(PreviousDirectoryLength);
    Path.MaximumLength := Word(PreviousDirectoryLength);
    Context.RtlSetCurrentDirectory_U(Path);
  end;
end;

const
  {$IFDEF Win64}
  // NOTE: Keep it in sync with the function code above
  PayloadRaw64: array [0..273] of Byte = (
    $55, $56, $53, $48, $83, $EC, $40, $48, $8B, $EC, $48, $89, $CB, $B9, $30,
    $00, $00, $00, $33, $D2, $FF, $13, $B9, $02, $00, $00, $00, $48, $8D, $55,
    $3C, $4C, $8D, $45, $30, $FF, $53, $18, $89, $43, $40, $85, $C0, $0F, $8C,
    $D9, $00, $00, $00, $8B, $45, $3C, $83, $E8, $01, $85, $C0, $74, $09, $83,
    $E8, $01, $85, $C0, $75, $19, $EB, $0B, $33, $C9, $48, $8B, $55, $30, $FF,
    $53, $20, $EB, $0C, $C7, $43, $40, $94, $01, $00, $C0, $E9, $AF, $00, $00,
    $00, $83, $7B, $4C, $00, $74, $4F, $B9, $FE, $FF, $00, $00, $48, $8D, $53,
    $50, $FF, $53, $08, $89, $C6, $85, $F6, $76, $08, $81, $FE, $FF, $FF, $00,
    $00, $76, $04, $33, $C0, $EB, $02, $B0, $01, $84, $C0, $0F, $95, $C0, $48,
    $0F, $B6, $C0, $F7, $D8, $89, $43, $4C, $48, $8D, $83, $4E, $00, $01, $00,
    $48, $89, $45, $28, $48, $0F, $B7, $43, $46, $66, $89, $45, $20, $66, $89,
    $45, $22, $48, $8D, $4D, $20, $FF, $53, $10, $EB, $02, $33, $F6, $48, $8D,
    $83, $4E, $00, $01, $00, $48, $89, $45, $28, $48, $0F, $B7, $43, $44, $66,
    $89, $45, $20, $66, $89, $45, $22, $33, $C9, $33, $D2, $4C, $8D, $45, $20,
    $4C, $8D, $4B, $38, $FF, $53, $28, $89, $43, $40, $83, $7B, $48, $00, $74,
    $0B, $85, $C0, $7C, $07, $48, $8B, $4B, $38, $FF, $53, $30, $83, $7B, $4C,
    $00, $74, $17, $48, $8D, $43, $50, $48, $89, $45, $28, $66, $89, $75, $20,
    $66, $89, $75, $22, $48, $8D, $4D, $20, $FF, $53, $10, $48, $8D, $65, $40,
    $5B, $5E, $5D, $C3
  );

  {$ENDIF}

  // NOTE: Keep it in sync with the function code above
  PayloadRaw32: array [0..254] of Byte = (
    $55, $8B, $EC, $83, $C4, $F0, $53, $56, $57, $8B, $5D, $08, $6A, $00, $6A,
    $30, $FF, $13, $8D, $45, $F8, $50, $8D, $45, $FC, $50, $6A, $02, $FF, $53,
    $18, $8B, $F0, $89, $73, $40, $8B, $C6, $85, $C0, $0F, $8C, $C8, $00, $00,
    $00, $8B, $45, $FC, $48, $74, $05, $48, $74, $0D, $EB, $17, $8B, $45, $F8,
    $50, $6A, $00, $FF, $53, $20, $EB, $0C, $C7, $43, $40, $94, $01, $00, $C0,
    $E9, $A6, $00, $00, $00, $83, $7B, $4C, $00, $74, $45, $8D, $43, $50, $50,
    $68, $FE, $FF, $00, $00, $FF, $53, $08, $8B, $F0, $85, $F6, $76, $08, $81,
    $FE, $FF, $FF, $00, $00, $76, $04, $33, $C0, $EB, $02, $B0, $01, $F6, $D8,
    $1B, $C0, $89, $43, $4C, $8D, $83, $4E, $00, $01, $00, $89, $45, $F4, $0F,
    $B7, $43, $46, $66, $89, $45, $F0, $66, $89, $45, $F2, $8D, $45, $F0, $50,
    $FF, $53, $10, $EB, $02, $33, $F6, $8D, $83, $4E, $00, $01, $00, $89, $45,
    $F4, $0F, $B7, $43, $44, $66, $89, $45, $F0, $66, $89, $45, $F2, $8D, $43,
    $38, $50, $8D, $45, $F0, $50, $6A, $00, $6A, $00, $FF, $53, $28, $8B, $F8,
    $89, $7B, $40, $83, $7B, $48, $00, $74, $0D, $8B, $C7, $85, $C0, $7C, $07,
    $8B, $43, $38, $50, $FF, $53, $30, $83, $7B, $4C, $00, $74, $17, $8D, $43,
    $50, $89, $45, $F4, $8B, $C6, $66, $89, $45, $F0, $66, $89, $45, $F2, $8D,
    $45, $F0, $50, $FF, $53, $10, $5F, $5E, $5B, $8B, $E5, $5D, $C2, $0C, $00
  );

function RtlxAutoSelectModeDll(
  const DllPath: String;
  var Options: TDllInjectionOptions
): TNtxStatus;
var
  hxFile, hxSection: IHandle;
  Attributes: TAllocationAttributes;
  Info: TSectionImageInformation;
begin
  // Open the DLL for inspection
  Result := NtxOpenFile(hxFile, FileOpenParameters
    .UseFileName(DllPath, fnWin32).UseAccess(FILE_READ_DATA)
    .UseOpenOptions(FILE_SYNCHRONOUS_IO_NONALERT or FILE_NON_DIRECTORY_FILE)
  );

  if not Result.IsSuccess then
    Exit;

  if RtlOsVersionAtLeast(OsWin8) then
    Attributes := SEC_IMAGE_NO_EXECUTE
  else
    Attributes := SEC_IMAGE;

  // Create an image section from it
  Result := NtxCreateFileSection(hxSection, hxFile.Handle, PAGE_READONLY,
    Attributes);

  if not Result.IsSuccess then
    Exit;

  // Query information from its headers
  Result := NtxSection.Query(hxSection.Handle, SectionImageInformation, Info);

  if not Result.IsSuccess then
    Exit;

  // The image does not require WoW64, select to ignore it
  if Info.Machine = IMAGE_FILE_MACHINE_AMD64 then
    Include(Options, dioIgnoreWoW64);
end;

function RtlxInjectDllProcess;
var
  TargetIsWoW64: Boolean;
  CodeRef: TMemory;
  LocalContext: IMemory<PDllLoaderContext>;
  LocalCode, RemoteCode, RemoteContext: IMemory;
  ThreadMain: Pointer;
  Dependencies: TArray<Pointer>;
  hxThread: IHandle;
  ApcOptions: TThreadApcOptions;
  i: Integer;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  if dioAutoIgnoreWoW64 in Options then
  begin
    // Lookup the bitness of the DLL to select the mode
    Result := RtlxAutoSelectModeDll(DllPath, Options);

    if not Result.IsSuccess then
      Exit;
  end;

  // Choose a suitable shellcode
{$IFDEF Win64}
  if (dioIgnoreWoW64 in Options) or not TargetIsWoW64 then
    CodeRef := TMemory.Reference(PayloadRaw64)
  else
{$ENDIF}
    CodeRef := TMemory.Reference(PayloadRaw32);

  // Create a shared memory region for the payload code
  Result := RtlxMapSharedMemory(hxProcess, CodeRef.Size, LocalCode,
    RemoteCode, [mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  // Fill in the payload code
  Move(CodeRef.Address^, LocalCode.Data^, CodeRef.Size);

  // Create a shared memory region for the context
  Result := RtlxMapSharedMemory(hxProcess, SizeOf(TDllLoaderContext) +
    Length(DllPath) * SizeOf(WideChar), IMemory(LocalContext),
    RemoteContext, [mmAllowWrite]);

  if not Result.IsSuccess then
    Exit;

  // Resolve dependencies for the payload
  Result := RtlxFindKnownDllExports(
    ntdll,
    TargetIsWoW64 and not (dioIgnoreWoW64 in Options),
    [
      'RtlSetThreadErrorMode',
      'RtlGetCurrentDirectory_U',
      'RtlSetCurrentDirectory_U',
      'LdrLockLoaderLock',
      'LdrUnlockLoaderLock',
      'LdrLoadDll',
      'LdrUnloadDll'
    ],
    Dependencies
  );

  if not Result.IsSuccess then
    Exit;

  // Fill in payload's context
  LocalContext.Data.RtlSetThreadErrorMode := Dependencies[0];
  LocalContext.Data.RtlGetCurrentDirectory_U := Dependencies[1];
  LocalContext.Data.RtlSetCurrentDirectory_U := Dependencies[2];
  LocalContext.Data.LdrLockLoaderLock := Dependencies[3];
  LocalContext.Data.LdrUnlockLoaderLock := Dependencies[4];
  LocalContext.Data.LdrLoadDll := Dependencies[5];
  LocalContext.Data.LdrUnloadDll := Dependencies[6];
  LocalContext.Data.Status := STATUS_UNSUCCESSFUL;
  LocalContext.Data.UnloadImmediately := dioUnloadImmediately in Options;
  LocalContext.Data.DllNameLength := Length(DllPath) * SizeOf(WideChar);

  // Extract the path from the DLL name
  if dioAdjustCurrentDirectory in Options then
    for i := High(DllPath) downto Low(DllPath) do
      if DllPath[i] = '\' then
      begin
        LocalContext.Data.AdjustCurrentDirectory := True;
        LocalContext.Data.DllDirectoryLength := (i - Low(DllPath) + 1) *
          SizeOf(WideChar);
        Break;
      end;

  // Copy the filename
  Move(PWideChar(DllPath)^, LocalContext.Data.DllName[0],
    LocalContext.Data.DllNameLength);

  // Find a function to execute as the thread main
  Result := RtlxFindKnownDllExport(ntdll, TargetIsWoW64, 'NtTestAlert',
    ThreadMain);

  if not Result.IsSuccess then
    Exit;

  // Create a suspended thread
  Result := NtxCreateThread(hxThread, hxProcess.Handle, ThreadMain,
    Pointer(UIntPtr(STATUS_SUCCESS)), THREAD_CREATE_FLAGS_CREATE_SUSPENDED or
    ThreadFlags);

  if not Result.IsSuccess then
    Exit;

  ApcOptions := [];

  // Choose execution mode for APC between 32- and 64- bits
  if TargetIsWoW64 and not (dioIgnoreWoW64 in Options) then
    Include(ApcOptions, apcWoW64);

  // Queue the APC for executing the payload
  Result := NtxQueueApcThreadEx(hxThread.Handle, RemoteCode.Data,
    RemoteContext.Data, nil, nil, ApcOptions);

  if not Result.IsSuccess then
    Exit;

  // Resume and execute the APC
  Result := NtxResumeThread(hxThread.Handle);

  if not Result.IsSuccess then
    Exit;

  // Wait for injection to complete; prolong remote memory lifetime on timeout
  Result := RtlxSyncThread(hxProcess, hxThread, Timeout, [RemoteContext,
    RemoteCode], CustomWait);

  if not Result.IsSuccess then
    Exit;

  // Read the operation status from the shared memory
  Result.Location := 'Remote::LdrLoadDll';
  Result.Status := LocalContext.Data.Status;

  // Copy the base address back if necessary
  if Result.IsSuccess and Assigned(DllBase) then
    HMODULE(DllBase^) := LocalContext.Data.DllHandle
end;

end.
