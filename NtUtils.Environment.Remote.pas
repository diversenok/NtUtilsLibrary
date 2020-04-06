unit NtUtils.Environment.Remote;

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils.Exceptions, NtUtils.Environment,
  NtUtils.Shellcode;

const
  PROCESS_QUERY_ENVIRONMENT = PROCESS_QUERY_LIMITED_INFORMATION or
    PROCESS_VM_READ;

  PROCESS_SET_ENVIRONMENT = PROCESS_REMOTE_EXECUTE;
  PROCESS_SET_DIRECTORY = PROCESS_REMOTE_EXECUTE;

// Obtain a copy of environment of a process
function NtxQueryEnvironmentProcess(hProcess: THandle;
  out Environment: IEnvironment): TNtxStatus;

// Set environment for a process
function NtxSetEnvironmentProcess(hProcess: THandle; Environment: IEnvironment;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT): TNtxStatus;

// Set current directory for a process
function RtlxSetDirectoryProcess(hProcess: THandle; Directory: String;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb, Ntapi.ntwow64,
  NtUtils.Processes.Query, NtUtils.Processes.Memory, NtUtils.Threads;

function NtxQueryEnvironmentProcess(hProcess: THandle;
  out Environment: IEnvironment): TNtxStatus;
var
  IsWoW64: Boolean;
  BasicInfo: TProcessBasicInformation;
  Params: PRtlUserProcessParameters;
  Size: NativeUInt;
  pRemoteEnv: Pointer;
  Buffer: Pointer;
begin
  // Prevent WoW64 -> Native scenarious
  Result := RtlxAssertWoW64Compatible(hProcess, IsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Usually, both native and WoW64 PEBs point to the same environment.
  // We will query the same bitness of PEB as we are for simplicity.

  // Locate PEB
  Result := NtxProcess.Query(hProcess, ProcessBasicInformation, BasicInfo);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(BasicInfo.PebBaseAddress) or (BasicInfo.ExitStatus <>
    STATUS_PENDING) then
  begin
    Result.Location := 'NtxQueryEnvironmentProcess';
    Result.Status := STATUS_PROCESS_IS_TERMINATING;
    Exit;
  end;

  // Locate process parameters
  Result := NtxMemory.Read(hProcess,
    @BasicInfo.PebBaseAddress.ProcessParameters, Params);

  if not Result.IsSuccess then
    Exit;

  // No process parameters - no environment; create empty one
  if not Assigned(Params) then
  begin
    Result.Location := 'NtxQueryEnvironmentProcess';
    Result.Status := STATUS_ACCESS_VIOLATION;
    Exit;
  end;

  // Get environmental block size
  Result := NtxMemory.Read(hProcess, @Params.EnvironmentSize, Size);

  if not Result.IsSuccess then
    Exit;

  // Do not copy unrealistically huge environments
  if Size > BUFFER_LIMIT then
  begin
    Result.Location := 'NtxQueryEnvironmentProcess';
    Result.Status := STATUS_IMPLEMENTATION_LIMIT;
    Exit;
  end;

  // Obtain environmental block location
  Result := NtxMemory.Read(hProcess, @Params.Environment, pRemoteEnv);

  if not Result.IsSuccess then
    Exit;

  // Allocate memory the same way RtlCreateEnvironment does,
  // so it can be freed with RtlDestroyEnvironment
  Buffer := RtlAllocateHeap(RtlGetCurrentPeb.ProcessHeap, HEAP_ZERO_MEMORY or
    HEAP_GENERATE_EXCEPTIONS, Size);

  // Retrieve the environmental block
  Result := NtxReadMemoryProcess(hProcess, pRemoteEnv, Buffer, Size);

  // Capture it
  if Result.IsSuccess then
    Environment := TEnvironment.CreateOwned(Buffer)
  else
    RtlFreeHeap(RtlGetCurrentPeb.ProcessHeap, HEAP_GENERATE_EXCEPTIONS, Buffer);
end;

type
  // We are going to execute a function within the target process,
  // so it requires some data to work with
  TEnvironmetSetterContext = record
    RtlAllocateHeap: function (HeapHandle: Pointer; Flags: Cardinal;
      Size: NativeUInt): Pointer; stdcall;
    memmove: function (Dst: Pointer; Src: Pointer; Size: NativeUInt): Pointer;
      cdecl;
    RtlSetCurrentEnvironment: function (Environment: Pointer;
      PreviousEnvironment: PPointer): NTSTATUS; stdcall;

    Peb: PPeb;
    Size: NativeUInt;
  end;
  PEnvironmetSetterContext = ^TEnvironmetSetterContext;

  {$IFDEF Win64}
  TEnvironmetSetterContextWoW64 = record
    RtlAllocateHeap: Wow64Pointer;
    memmove: Wow64Pointer;
    RtlSetCurrentEnvironment: Wow64Pointer;
    Peb: Wow64Pointer;
    Size: Cardinal;
  end;
  PEnvironmetSetterContextWoW64 = ^TEnvironmetSetterContextWoW64;
  {$ENDIF}

// NOTE: be consistent with raw assembly below. We are going to inject it.
function RemoteEnvSetter(Context: PEnvironmetSetterContext): NTSTATUS; stdcall;
var
  EnvBlock: Pointer;
begin
  // Allocate memory the same way RtlCreateEnvironment does,
  // so it can be freed with RtlDestroyEnvironment.
  EnvBlock := Context.RtlAllocateHeap(Context.Peb.ProcessHeap, 0, Context.Size);

  if EnvBlock = nil then
    Exit(STATUS_NO_MEMORY);

  // Fill the environment. The source is stored after the context.
  {$Q-}
  Context.memmove(EnvBlock, Pointer(NativeInt(Context) +
    SizeOf(TEnvironmetSetterContext)), Context.Size);
  {$Q+}

  // Set it
  Result := Context.RtlSetCurrentEnvironment(EnvBlock, nil);
end;

const
  {$IFDEF Win64}
  // Raw assembly code we are going to inject.
  // NOTE: be consistent with the function code above
  RemoteEnvSetter64: array [0 .. 111] of Byte = (
    $55, $48, $83, $EC, $30, $48, $8B, $EC, $48, $89, $4D, $40, $48, $8B, $45,
    $40, $48, $8B, $40, $18, $48, $8B, $48, $30, $33, $D2, $48, $8B, $45, $40,
    $4C, $8B, $40, $20, $48, $8B, $45, $40, $FF, $10, $48, $89, $45, $20, $48,
    $83, $7D, $20, $00, $75, $09, $C7, $45, $2C, $17, $00, $00, $C0, $EB, $2B,
    $48, $8B, $4D, $20, $48, $8B, $45, $40, $48, $8D, $50, $28, $48, $8B, $45,
    $40, $4C, $8B, $40, $20, $48, $8B, $45, $40, $FF, $50, $08, $48, $8B, $4D,
    $20, $33, $D2, $48, $8B, $45, $40, $FF, $50, $10, $89, $45, $2C, $8B, $45,
    $2C, $48, $8D, $65, $30, $5D, $C3
  );

  {$ENDIF}

  // Raw assembly code we are going to inject.
  // NOTE: be consistent with the function code above
  RemoteEnvSetter32: array [0 .. 98] of Byte = (
    $55, $8B, $EC, $83, $C4, $F8, $8B, $45, $08, $8B, $40, $10, $50, $6A, $00,
    $8B, $45, $08, $8B, $40, $0C, $8B, $40, $18, $50, $8B, $45, $08, $FF, $10,
    $89, $45, $F8, $83, $7D, $F8, $00, $75, $09, $C7, $45, $FC, $17, $00, $00,
    $C0, $EB, $2A, $8B, $45, $08, $8B, $40, $10, $50, $8B, $45, $08, $83, $C0,
    $14, $50, $8B, $45, $F8, $50, $8B, $45, $08, $FF, $50, $04, $83, $C4, $0C,
    $6A, $00, $8B, $45, $F8, $50, $8B, $45, $08, $FF, $50, $08, $89, $45, $FC,
    $8B, $45, $FC, $59, $59, $5D, $C2, $04, $00
  );

function NtxpPrepareEnvSetterNative(hProcess: THandle; RemotePeb: Pointer;
  Environment: IEnvironment; out Context: TMemory): TNtxStatus;
var
  Addresses: TArray<Pointer>;
  Buffer: PEnvironmetSetterContext;
  BufferSize: NativeUInt;
  pEnvStart: Pointer;
begin
  // Find required functions
  Result := RtlxFindKnownDllExportsNative(ntdll, ['RtlAllocateHeap', 'memmove',
    'RtlSetCurrentEnvironment'], Addresses);

  if not Result.IsSuccess then
    Exit;

  // Allocate local context buffer
  BufferSize := SizeOf(TEnvironmetSetterContext) + Environment.Size;
  Buffer := AllocMem(BufferSize);

  // Fill it in
  Buffer.RtlAllocateHeap := Addresses[0];
  Buffer.memmove := Addresses[1];
  Buffer.RtlSetCurrentEnvironment := Addresses[2];
  Buffer.Peb := RemotePeb;
  Buffer.Size := Environment.Size;

  // Append the environment
  pEnvStart := Pointer(NativeUInt(Buffer) + SizeOf(TEnvironmetSetterContext));
  Move(Environment.Environment^, pEnvStart^, Environment.Size);

  // Write the context
  Result := NtxAllocWriteMemoryProcess(hProcess, Buffer, BufferSize, Context);
end;

{$IFDEF Win64}
function NtxpPrepareEnvSetterWoW64(hProcess: THandle; RemotePeb: Pointer;
  Environment: IEnvironment; out Context: TMemory): TNtxStatus;
var
  Addresses: TArray<Pointer>;
  Buffer: PEnvironmetSetterContextWoW64;
  BufferSize: NativeUInt;
  pEnvStart: Pointer;
begin
  // Find required functions
  Result := RtlxFindKnownDllExportsWoW64(ntdll, ['RtlAllocateHeap', 'memmove',
    'RtlSetCurrentEnvironment'], Addresses);

  if not Result.IsSuccess then
    Exit;

  // Allocate local context buffer
  BufferSize := SizeOf(TEnvironmetSetterContextWoW64) + Environment.Size;
  Buffer := AllocMem(BufferSize);

  // Fill it in
  Buffer.RtlAllocateHeap := WoW64Pointer(Addresses[0]);
  Buffer.memmove := WoW64Pointer(Addresses[1]);
  Buffer.RtlSetCurrentEnvironment := WoW64Pointer(Addresses[2]);
  Buffer.Peb := WoW64Pointer(RemotePeb);
  Buffer.Size := Cardinal(Environment.Size);

  // Append the environment
  pEnvStart := Pointer(NativeUInt(Buffer) +
    SizeOf(TEnvironmetSetterContextWoW64));
  Move(Environment.Environment^, pEnvStart^, Environment.Size);

  // Write the context
  Result := NtxAllocWriteMemoryProcess(hProcess, Buffer, BufferSize, Context,
    True);
end;
{$ENDIF}

function NtxSetEnvironmentProcess(hProcess: THandle; Environment: IEnvironment;
  Timeout: Int64): TNtxStatus;
var
  WoW64Peb: PPeb32;
  BasicInfo: TProcessBasicInformation;
  Context, Code: TMemory;
  hxThread: IHandle;
begin
  // Prevent WoW64 -> Native scenarious
  Result := RtlxAssertWoW64Compatible(hProcess, WoW64Peb);

  if not Result.IsSuccess then
    Exit;

  // Prepare and write the context data
{$IFDEF Win64}
  if Assigned(WoW64Peb) then
    Result := NtxpPrepareEnvSetterWoW64(hProcess, WoW64Peb, Environment,
      Context)
  else
{$ENDIF}
  begin
    // Query native PEB location
    Result := NtxProcess.Query(hProcess, ProcessBasicInformation, BasicInfo);

    if Result.IsSuccess then
      Result := NtxpPrepareEnvSetterNative(hProcess, BasicInfo.PebBaseAddress,
        Environment, Context);
  end;

  if not Result.IsSuccess then
    Exit;

  // Allocate our payload's code
{$IFDEF Win64}
  if not Assigned(WoW64Peb) then
    Result := NtxMemory.AllocWriteExec(hProcess, RemoteEnvSetter64, Code, False)
  else
{$ENDIF}
    Result := NtxMemory.AllocWriteExec(hProcess, RemoteEnvSetter32, Code, True);

  // Undo context allocation on failure
  if not Result.IsSuccess then
  begin
    NtxFreeMemoryProcess(hProcess, Context.Address, Context.Size);
    Exit;
  end;

  // Create a thread
  Result := NtxCreateThread(hxThread, hProcess, Code.Address, Context.Address);

  // Sync with the thread
  if Result.IsSuccess then
    Result := RtlxSyncThreadProcess(hProcess, hxThread.Handle,
      'Remote::RtlSetCurrentEnvironment', Timeout);

  // Undo memory allocations
  if not Result.Matches(STATUS_WAIT_TIMEOUT, 'NtWaitForSingleObject') then
  begin
    NtxFreeMemoryProcess(hProcess, Code.Address, Code.Size);
    NtxFreeMemoryProcess(hProcess, Context.Address, Context.Size);
  end;
end;

function RtlxSetDirectoryProcess(hProcess: THandle; Directory: String;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT): TNtxStatus;
var
  TargetIsWoW64: Boolean;
  Functions: TArray<Pointer>;
  Buffer: PUNICODE_STRING;
  BufferSize: NativeUInt;
  Memory: TMemory;
  hxThread: IHandle;
{$IFDEF Win64}
  Buffer32: ^UNICODE_STRING32;
{$ENDIF}
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hProcess, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Find the function's address. Conveniently, it has the same prototype as
  // a thread routine, so we can create a remote thread pointing directly to
  // this function.
  Result := RtlxFindKnownDllExports(ntdll, TargetIsWoW64,
    ['RtlSetCurrentDirectory_U'], Functions);

  if not Result.IsSuccess then
    Exit;

  // Compute the required amount of memory for the path we are going to allocate
{$IFDEF Win64}
  if TargetIsWoW64 then
    BufferSize := SizeOf(UNICODE_STRING32) + (Length(Directory) + 1) *
      SizeOf(WideChar)
  else
{$ENDIF}
    BufferSize := SizeOf(UNICODE_STRING) + (Length(Directory) + 1) *
      SizeOf(WideChar);

  // Allocate a remote buffer
  Result := NtxAllocateMemoryProcess(hProcess, BufferSize, Memory,
    TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  Buffer := AllocMem(BufferSize);

  // Marshal the data
{$IFDEF Win64}
  if TargetIsWoW64 then
  begin
    Buffer32 := Pointer(Buffer);
    Buffer32.Length := Length(Directory) * SizeOf(WideChar);
    Buffer32.MaximumLength := Buffer32.Length + SizeOf(WideChar);
    Buffer32.Buffer := Wow64Pointer(Memory.Address) + SizeOf(UNICODE_STRING32);
    Move(PWideChar(Directory)^, Pointer(NativeUInt(Buffer32) +
      SizeOf(UNICODE_STRING32))^, Buffer32.Length);
  end
  else
{$ENDIF}
  begin
    Buffer.FromString(Directory);
    Buffer.Buffer := PWideChar(NativeUInt(Memory.Address) +
      SizeOf(UNICODE_STRING));
    Move(PWideChar(Directory)^, Pointer(NativeUInt(Buffer) +
      SizeOf(UNICODE_STRING))^, Buffer.Length);
  end;

  // Write it
  Result := NtxWriteMemoryProcess(hProcess, Memory.Address, Buffer, BufferSize);
  FreeMem(Buffer);

  // Create a thread that will do the work
  if Result.IsSuccess then
    Result := NtxCreateThread(hxThread, hProcess, Functions[0], Memory.Address);

  // Sync with the thread
  if Result.IsSuccess then
    Result := RtlxSyncThreadProcess(hProcess, hxThread.Handle,
    'Remote::RtlSetCurrentDirectory_U', Timeout);

  // Undo memory allocation only if the thread exited
  if not Result.Matches(STATUS_WAIT_TIMEOUT, 'NtWaitForSingleObject') then
    NtxFreeMemoryProcess(hProcess, Memory.Address, Memory.Size);
end;


end.
