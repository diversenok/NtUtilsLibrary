unit NtUtils.Shellcode.Dll;

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils.Exceptions, NtUtils.Shellcode;

const
  PROCESS_INJECT_DLL = PROCESS_QUERY_LIMITED_INFORMATION or PROCESS_INJECT_CODE;
  INJECT_DEAFULT_TIMEOUT = 5000 * MILLISEC;

// Inject a DLL into a process using LoadLibraryW
function RtlxInjectDllProcess(hProcess: THandle; DllName: String;
  Timeout: Int64 = INJECT_DEAFULT_TIMEOUT): TNtxStatus;

type
  // A callback to execute when injecting a dll. For example, here you can
  // adjust the security context of the thread that is going to inject the dll.
  //
  // **NOTE**: The thread is suspended, it is the responsibility of the
  //   callback to resume it!
  //
  TInjectionCallback = reference to function (hProcess: THandle;
    hxThread: IHandle; DllName: String; RemoteContext, RemoteCode: TMemory;
    TargetIsWoW64: Boolean): TNtxStatus;

// Injects a DLL into a process using a shellcode with LdrLoadDll.
// Forwards error codes and tries to prevent deadlocks.
function RtlxInjectDllProcessEx(hProcess: THandle; DllPath: String;
  Timeout: Int64 = INJECT_DEAFULT_TIMEOUT; OnInjection: TInjectionCallback =
  nil): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntwow64, Ntapi.ntldr, Ntapi.ntstatus,
  NtUtils.Objects, NtUtils.Processes.Query, NtUtils.Threads,
  NtUtils.Processes.Memory;

function RtlxInjectDllProcess(hProcess: THandle; DllName: String;
  Timeout: Int64): TNtxStatus;
var
  TargetIsWoW64: Boolean;
  Addresses: TArray<Pointer>;
  Memory: TMemory;
  hxThread: IHandle;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hProcess, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Find function's address
  Result := RtlxFindKnownDllExports(kernel32, TargetIsWoW64, ['LoadLibraryW'],
    Addresses);

  if not Result.IsSuccess then
    Exit;

  // Write DLL path into process' memory
  Result := NtxAllocWriteMemoryProcess(hProcess, PWideChar(DllName),
    (Length(DllName) + 1) * SizeOf(WideChar), Memory);

  if not Result.IsSuccess then
    Exit;

  // Create a thread
  Result := RtlxCreateThread(hxThread, hProcess, Addresses[0], Memory.Address);

  if not Result.IsSuccess then
  begin
    NtxFreeMemoryProcess(hProcess, Memory.Address, Memory.Size);
    Exit;
  end;

  // Sychronize with it
  Result := RtlxSyncThreadProcess(hProcess, hxThread.Handle,
    'Remote::LoadLibraryW', Timeout);

  // Undo memory allocation only if the thread exited
  if not Result.Matches(STATUS_WAIT_TIMEOUT, 'NtWaitForSingleObject') then
    NtxFreeMemoryProcess(hProcess, Memory.Address, Memory.Size);

  if Result.Location = 'Remote::LoadLibraryW' then
  begin
    // LoadLibraryW returns the address of the DLL. It needs to be non-null

    if Result.Status = 0 then
      Result.Status := STATUS_UNSUCCESSFUL
    else
      Result.Status := STATUS_SUCCESS;
  end;
end;

{ Native DLL loader }

type
  TLdrLoadDll = function (DllPath: PWideChar; DllCharacteristics: PCardinal;
    const DllName: UNICODE_STRING; out DllHandle: HMODULE): NTSTATUS; stdcall;

  TLdrLockLoaderLock = function(Flags: Cardinal; var Disposition:
    TLdrLoaderLockDisposition; out Cookie: NativeUInt): NTSTATUS; stdcall;

  TLdrUnlockLoaderLock = function(Flags: Cardinal; Cookie: NativeUInt):
    NTSTATUS; stdcall;

  // The shellcode we are going to injects requires some data to work with

  TDllLoaderContext = record
    LdrLoadDll: TLdrLoadDll;
    LdrLockLoaderLock: TLdrLockLoaderLock;
    LdrUnlockLoaderLock: TLdrUnlockLoaderLock;

    DllName: UNICODE_STRING;
    DllHandle: HMODULE;
    DllNameBuffer: array [ANYSIZE_ARRAY] of Char;
  end;
  PDllLoaderContext = ^TDllLoaderContext;

  {$IFDEF Win64}
  TDllLoaderContextWoW64 = record
    LdrLoadDll: Wow64Pointer;
    LdrLockLoaderLock: Wow64Pointer;
    LdrUnlockLoaderLock: Wow64Pointer;

    DllName: UNICODE_STRING32;
    DllHandle: Wow64Pointer;
    DllNameBuffer: array [ANYSIZE_ARRAY] of Char;
  end;
  PDllLoaderContextWoW64 = ^TDllLoaderContextWoW64;
  {$ENDIF}

// **NOTE**
// This function was used to generate the raw assembly listed below.
// Keep it in sync with the code when applying changes.
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

  // Fix DLL name pointer
  Context.DllName.Buffer := PWideChar(@Context.DllNameBuffer);

  // Load the DLL
  Result := Context.LdrLoadDll(nil, nil, Context.DllName, Context.DllHandle);
end;

const
  {$IFDEF Win64}
  // NOTE: Keep it in sync with the function code above
  DllLoaderRaw64: array [0..137] of Byte = (
    $55, $48, $83, $EC, $30, $48, $8B, $EC, $48, $89, $4D, $40, $B9, $02, $00,
    $00, $00, $48, $8D, $55, $28, $4C, $8D, $45, $20, $48, $8B, $45, $40, $FF,
    $50, $08, $89, $45, $2C, $83, $7D, $2C, $00, $7C, $58, $8B, $45, $28, $83,
    $E8, $01, $85, $C0, $74, $09, $83, $E8, $01, $85, $C0, $75, $1A, $EB, $0F,
    $33, $C9, $48, $8B, $55, $20, $48, $8B, $45, $40, $FF, $50, $10, $EB, $09,
    $C7, $45, $2C, $94, $01, $00, $C0, $EB, $2D, $48, $8B, $45, $40, $48, $8B,
    $4D, $40, $48, $8D, $49, $30, $48, $89, $48, $20, $33, $C9, $33, $D2, $48,
    $8B, $45, $40, $4C, $8D, $40, $18, $48, $8B, $45, $40, $4C, $8D, $48, $28,
    $48, $8B, $45, $40, $FF, $10, $89, $45, $2C, $8B, $45, $2C, $48, $8D, $65,
    $30, $5D, $C3
  );
  {$ENDIF}

  // NOTE: Keep it in sync with the function code above
  DllLoaderRaw32: array [0..111] of Byte = (
    $55, $8B, $EC, $83, $C4, $F4, $8D, $45, $F4, $50, $8D, $45, $F8, $50, $6A,
    $02, $8B, $45, $08, $FF, $50, $04, $89, $45, $FC, $83, $7D, $FC, $00, $7C,
    $48, $8B, $45, $F8, $48, $74, $05, $48, $74, $10, $EB, $17, $8B, $45, $F4,
    $50, $6A, $00, $8B, $45, $08, $FF, $50, $08, $EB, $09, $C7, $45, $FC, $94,
    $01, $00, $C0, $EB, $26, $8B, $45, $08, $83, $C0, $18, $8B, $55, $08, $89,
    $42, $10, $8B, $45, $08, $83, $C0, $14, $50, $8B, $45, $08, $83, $C0, $0C,
    $50, $6A, $00, $6A, $00, $8B, $45, $08, $FF, $10, $89, $45, $FC, $8B, $45,
    $FC, $8B, $E5, $5D, $C2, $04, $00
  );

function RtlxpPrepareLoaderContextNative(DllPath: String;
  out Memory: IMemory): TNtxStatus;
var
  Context: PDllLoaderContext;
  Addresses: TArray<Pointer>;
begin
  // Find required functions
  Result := RtlxFindKnownDllExportsNative(ntdll, ['LdrLoadDll',
    'LdrLockLoaderLock', 'LdrUnlockLoaderLock'], Addresses);

  if not Result.IsSuccess then
    Exit;

  // Allocate the context
  Memory := TAutoMemory.Allocate(SizeOf(TDllLoaderContext) +
    Length(DllPath) * SizeOf(WideChar));

  Context := Memory.Address;
  Context.LdrLoadDll := Addresses[0];
  Context.LdrLockLoaderLock := Addresses[1];
  Context.LdrUnlockLoaderLock := Addresses[2];
  Context.DllName.FromString(DllPath);

  // Copy the dll path
  Move(PWideChar(DllPath)^, Context.DllNameBuffer,
    Length(DllPath) * SizeOf(WideChar));
end;

{$IFDEF Win64}
function RtlxpPrepareLoaderContextWoW64(DllPath: String;
  out Memory: IMemory): TNtxStatus;
var
  Context: PDllLoaderContextWoW64;
  Names: TArray<AnsiString>;
  Addresses: TArray<Pointer>;
begin
  SetLength(Names, 3);
  Names[0] := 'LdrLoadDll';
  Names[1] := 'LdrLockLoaderLock';
  Names[2] := 'LdrUnlockLoaderLock';

  // Find the required functions in the WoW64 ntdll
  Result := RtlxFindKnownDllExportsWoW64(ntdll, Names, Addresses);

  if not Result.IsSuccess then
    Exit;

  // Allocate WoW64 loader context
  Memory := TAutoMemory.Allocate(SizeOf(TDllLoaderContextWoW64) +
    Length(DllPath) * SizeOf(WideChar));

  Context := Memory.Address;
  Context.LdrLoadDll := Wow64Pointer(Addresses[0]);
  Context.LdrLockLoaderLock := Wow64Pointer(Addresses[1]);
  Context.LdrUnlockLoaderLock := Wow64Pointer(Addresses[2]);

  Context.DllName.Length := System.Length(DllPath) * SizeOf(WideChar);
  Context.DllName.MaximumLength := Context.DllName.Length + SizeOf(WideChar);

  // Copy the dll path
  Move(PWideChar(DllPath)^, Context.DllNameBuffer,
    Length(DllPath) * SizeOf(WideChar));
end;
{$ENDIF}

function RtlxpPrepareLoaderContext(DllPath: String; TargetIsWoW64: Boolean;
  out Memory: IMemory; out Code: TMemory): TNtxStatus;
begin
{$IFDEF Win64}
  if TargetIsWoW64 then
  begin
    // Native -> WoW64
    Code.Address := @DllLoaderRaw32;
    Code.Size := SizeOf(DllLoaderRaw32);

    Result := RtlxpPrepareLoaderContextWoW64(DllPath, Memory);
    Exit;
  end;
{$ENDIF}

  // Native -> Native / WoW64 -> WoW64
  Result := RtlxpPrepareLoaderContextNative(DllPath, Memory);

{$IFDEF Win64}
  Code.Address := @DllLoaderRaw64;
  Code.Size := SizeOf(DllLoaderRaw64);
{$ELSE}
  Code.Address := @DllLoaderRaw32;
  Code.Size := SizeOf(DllLoaderRaw32);
{$ENDIF}
end;

function RtlxInjectDllProcessEx(hProcess: THandle; DllPath: String;
  Timeout: Int64; OnInjection: TInjectionCallback): TNtxStatus;
var
  TargetIsWoW64: Boolean;
  hxThread: IHandle;
  Context: IMemory;
  Code: TMemory;
  RemoteContext, RemoteCode: TMemory;
  Flags: Cardinal;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hProcess, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Prepare the loader context
  Result := RtlxpPrepareLoaderContext(DllPath, TargetIsWoW64, Context, Code);

  if not Result.IsSuccess then
    Exit;

  // Copy the context and the code into the target
  Result := RtlxAllocWriteDataCodeProcess(hProcess, Context.Address,
    Context.Size, RemoteContext, Code.Address, Code.Size, RemoteCode);

  if not Result.IsSuccess then
    Exit;

  // Skipping attaching to existing DLLs helps to prevent deadlocks.
  Flags := THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH;

  // We want to invoke the callback before the thread starts executing
  if Assigned(OnInjection) then
    Flags := Flags or THREAD_CREATE_FLAGS_CREATE_SUSPENDED;

  // Create the remote thread
  Result := NtxCreateThread(hxThread, hProcess, RemoteCode.Address,
    RemoteContext.Address, Flags);

  // Invoke the callback
  if Result.IsSuccess and Assigned(OnInjection) then
  begin
    Result := OnInjection(hProcess, hxThread, DllPath, RemoteContext,
      RemoteCode, TargetIsWoW64);

    // Abort the operation if the callback failed
    if not Result.IsSuccess then
      NtxTerminateThread(hxThread.Handle, STATUS_CANCELLED);
  end;

  // Sync with the thread
  if Result.IsSuccess then
    Result := RtlxSyncThreadProcess(hProcess, hxThread.Handle,
      'Remote::LdrLoadDll', Timeout);

  // Undo memory allocation
  if not Result.Matches(STATUS_WAIT_TIMEOUT, 'NtWaitForSingleObject') then
  begin
    NtxFreeMemoryProcess(hProcess, RemoteCode.Address, RemoteCode.Size);
    NtxFreeMemoryProcess(hProcess, RemoteContext.Address, RemoteContext.Size);
  end;
end;

end.
