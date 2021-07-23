unit NtUtils.Shellcode.Dll;

{
  This module provides functions for injecting DLLs into other processes.
}

interface

uses
  Winapi.WinNt, NtUtils, NtUtils.Shellcode;

const
  PROCESS_INJECT_DLL = PROCESS_REMOTE_EXECUTE;

type
  // A callback to execute when injecting a dll. For example, here you can
  // adjust the security context of the thread that is going to inject the dll.
  //
  // **NOTE**: The thread is suspended and has not injected the DLL yet.
  //   It is the responsibility of the callback to resume it (provided it
  //   succeeds).
  //
  TInjectionCallback = reference to function (
    [Access(PROCESS_INJECT_DLL)] const hxProcess: IHandle;
    [Access(THREAD_ALL_ACCESS)] const hxThread: IHandle;
    const DllName: String;
    TargetIsWoW64: Boolean
  ): TNtxStatus;

// Injects a DLL into a process using a shellcode with LdrLoadDll.
// Forwards error codes and tries to prevent deadlocks.
function RtlxInjectDllProcess(
  [Access(PROCESS_INJECT_DLL)] const hxProcess: IHandle;
  const DllPath: String;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT;
  [opt] const OnInjection: TInjectionCallback = nil;
  [out, opt] DllBase: PPointer = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntldr, Ntapi.ntwow64, Ntapi.ntstatus,
  NtUtils.Processes.Info, NtUtils.Threads, NtUtils.Memory,
  DelphiUtils.AutoObjects;

type
  // The shellcode we are going to injects requires some data to work with
  TDllLoaderContext = record
    LdrLoadDll: function (
      DllPath: PWideChar;
      DllCharacteristics: PCardinal;
      const DllName: TNtUnicodeString;
      out DllHandle: HMODULE
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}

    LdrLockLoaderLock: function(
      Flags: TLdrLockFlags;
      var Disposition: TLdrLoaderLockDisposition;
      out Cookie: NativeUInt
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}

    LdrUnlockLoaderLock: function (
      Flags: TLdrLockFlags;
      Cookie: NativeUInt
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding3: Cardinal;{$ENDIF}

    pDllName: PNtUnicodeString;
    {$IFDEF Win32}WoW64Padding4: Cardinal;{$ENDIF}

    DllHandle: HMODULE;
    {$IFDEF Win32}WoW64Padding5: Cardinal;{$ENDIF}
  end;
  PDllLoaderContext = ^TDllLoaderContext;

// The function to execute in the context of the target.
// Note: keep it in sync with assembly below when applying changes.
function DllLoader(Context: PDllLoaderContext): NTSTATUS; stdcall;
var
  Disposition: TLdrLoaderLockDisposition;
  Cookie: NativeUInt;
begin
  // Try to acquire loader lock to prevent possible deadlocks
  Result := Context.LdrLockLoaderLock(LDR_LOCK_LOADER_LOCK_FLAG_TRY_ONLY,
    Disposition, Cookie);

  if not NT_SUCCESS(Result) then
    Exit;

  case Disposition of
    // Undo aquiring if necessary
    LDR_LOCK_LOADER_LOCK_DISPOSITION_LOCK_ACQUIRED:
      Context.LdrUnlockLoaderLock(0, Cookie);

    // Can't load DLLs now, exit
    LDR_LOCK_LOADER_LOCK_DISPOSITION_LOCK_NOT_ACQUIRED:
      Exit(STATUS_POSSIBLE_DEADLOCK);
  end;

  // Load the DLL
  Result := Context.LdrLoadDll(nil, nil, Context.pDllName^, Context.DllHandle);
end;

const
  {$IFDEF Win64}
  // NOTE: Keep it in sync with the function code above
  DllLoaderRaw64: array [0..95] of Byte = (
    $55, $53, $48, $83, $EC, $38, $48, $8B, $EC, $48, $89, $CB, $B9, $02, $00,
    $00, $00, $48, $8D, $55, $2C, $4C, $8D, $45, $20, $FF, $53, $08, $85, $C0,
    $7C, $33, $8B, $45, $2C, $83, $E8, $01, $85, $C0, $74, $09, $83, $E8, $01,
    $85, $C0, $75, $14, $EB, $0B, $33, $C9, $48, $8B, $55, $20, $FF, $53, $10,
    $EB, $07, $B8, $94, $01, $00, $C0, $EB, $0E, $33, $C9, $33, $D2, $4C, $8B,
    $43, $18, $4C, $8D, $4B, $20, $FF, $13, $48, $8D, $65, $38, $5B, $5D, $C3,
    $CC, $CC, $CC, $CC, $CC, $CC
  );
  {$ENDIF}

  // NOTE: Keep it in sync with the function code above
  DllLoaderRaw32: array [0..79] of Byte = (
    $55, $8B, $EC, $83, $C4, $F8, $53, $8B, $5D, $08, $8D, $45, $F8, $50, $8D,
    $45, $FC, $50, $6A, $02, $FF, $53, $08, $85, $C0, $7C, $2B, $8B, $45, $FC,
    $48, $74, $05, $48, $74, $0D, $EB, $12, $8B, $45, $F8, $50, $6A, $00, $FF,
    $53, $10, $EB, $07, $B8, $94, $01, $00, $C0, $EB, $0E, $8D, $43, $20, $50,
    $8B, $43, $18, $50, $6A, $00, $6A, $00, $FF, $13, $5B, $59, $59, $5D, $C2,
    $04, $00, $CC, $CC, $CC
  );

function RtlxInjectDllProcess;
var
  TargetIsWoW64: Boolean;
  hxThread: IHandle;
  CodeRef: TMemory;
  LocalMapping: IMemory<PDllLoaderContext>;
  RemoteMapping: IMemory;
  Dependencies: TArray<Pointer>;
  Flags: TThreadCreateFlags;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Select suitable shellcode
{$IFDEF Win64}
  if not TargetIsWoW64 then
    CodeRef := TMemory.Reference(DllLoaderRaw64)
  else
{$ENDIF}
    CodeRef := TMemory.Reference(DllLoaderRaw32);

  // Create a shared memory region
  Result := RtlxMapSharedMemory(hxProcess, SizeOf(TDllLoaderContext) +
    CodeRef.Size + TNtUnicodeString.RequiredSize(DllPath),
    IMemory(LocalMapping), RemoteMapping, [mmAllowWrite, mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  // Resolve dependencies
  Result := RtlxFindKnownDllExports(ntdll, TargetIsWoW64, ['LdrLoadDll',
    'LdrLockLoaderLock', 'LdrUnlockLoaderLock'], Dependencies);

  if not Result.IsSuccess then
    Exit;

  // Prepare the shellcode and its parameters
  LocalMapping.Data.LdrLoadDll := Dependencies[0];
  LocalMapping.Data.LdrLockLoaderLock := Dependencies[1];
  LocalMapping.Data.LdrUnlockLoaderLock := Dependencies[2];
  LocalMapping.Data.pDllName := RemoteMapping.Offset(SizeOf(TDllLoaderContext) +
    CodeRef.Size);

  Move(CodeRef.Address^, LocalMapping.Offset(SizeOf(TDllLoaderContext))^,
    CodeRef.Size);

{$IFDEF Win64}
  if TargetIsWoW64 then
    TNtUnicodeString32.MarshalEx(DllPath,
      LocalMapping.Offset(SizeOf(TDllLoaderContext) + CodeRef.Size),
      RemoteMapping.Offset(SizeOf(TDllLoaderContext) + CodeRef.Size)
    )
  else
{$ENDIF}
    TNtUnicodeString.MarshalEx(DllPath,
      LocalMapping.Offset(SizeOf(TDllLoaderContext) + CodeRef.Size),
      RemoteMapping.Offset(SizeOf(TDllLoaderContext) + CodeRef.Size)
    );

  // Make sure to invalidate instruction cache after modifying code
  NtxFlushInstructionCache(hxProcess.Handle, RemoteMapping.Offset(
    SizeOf(TDllLoaderContext)), CodeRef.Size);

  // Skipping attaching to existing DLLs helps to prevent deadlocks.
  Flags := THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH;

  // Using a callback requires a suspended thread
  if Assigned(OnInjection) then
    Flags := Flags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED;

  // Create the remote thread
  Result := NtxCreateThread(hxThread, hxProcess.Handle, RemoteMapping.Offset(
    SizeOf(TDllLoaderContext)), RemoteMapping.Data, Flags);

  if not Result.IsSuccess then
    Exit;

  // Invoke the callback
  if Assigned(OnInjection) then
  begin
    // The callback is responsible for resuming the thread, but only when it
    // succeeds
    Result := OnInjection(hxProcess, hxThread, DllPath, TargetIsWoW64);

    // Abort the operation if the callback failed
    if not Result.IsSuccess then
    begin
      NtxTerminateThread(hxThread.Handle, STATUS_CANCELLED);
      Exit;
    end
  end;

  // Sync with the thread. Prolong remote memory lifetime on timeout.
  Result := RtlxSyncThread(hxThread.Handle, 'Remote::LdrLoadDll', Timeout,
    [RemoteMapping]);

  // Return the DLL base to the caller
  if Result.IsSuccess and Assigned(DllBase) then
    DllBase^ := Pointer(LocalMapping.Data.DllHandle);
end;

end.
