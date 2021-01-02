unit NtUtils.Environment.Remote;

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode;

const
  PROCESS_QUERY_ENVIRONMENT = PROCESS_QUERY_LIMITED_INFORMATION or
    PROCESS_VM_READ;

  PROCESS_SET_ENVIRONMENT = PROCESS_REMOTE_EXECUTE;
  PROCESS_SET_DIRECTORY = PROCESS_REMOTE_EXECUTE;

// Obtain a copy of environment of a process
function NtxQueryEnvironmentProcess(hProcess: THandle;
  out Environment: IEnvironment): TNtxStatus;

// Set environment for a process
function NtxSetEnvironmentProcess(hxProcess: IHandle; Environment: IEnvironment;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT): TNtxStatus;

// Set current directory for a process
function RtlxSetDirectoryProcess(hxProcess: IHandle; Directory: String;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb, Ntapi.ntwow64,
  NtUtils.Processes.Query, NtUtils.Processes.Memory, NtUtils.Threads,
  NtUtils.Environment, DelphiUtils.AutoObject;

function NtxQueryEnvironmentProcess(hProcess: THandle;
  out Environment: IEnvironment): TNtxStatus;
var
  IsWoW64: Boolean;
  BasicInfo: TProcessBasicInformation;
  Params: PRtlUserProcessParameters;
  Size: NativeUInt;
  pRemoteEnv: Pointer;
  HeapBuffer: PEnvironment;
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
  HeapBuffer := RtlAllocateHeap(RtlGetCurrentPeb.ProcessHeap, HEAP_ZERO_MEMORY
    or HEAP_GENERATE_EXCEPTIONS, Size);

  // Capture it
  Environment := RtlxCaptureEnvironment(HeapBuffer);

  // Retrieve the environmental block
  Result := NtxReadMemoryProcess(hProcess, pRemoteEnv, TMemory.From(HeapBuffer,
    Size));
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
  EnvBlock: PEnvironment;
begin
  // Allocate memory the same way RtlCreateEnvironment does,
  // so it can be freed with RtlDestroyEnvironment.
  EnvBlock := Context.RtlAllocateHeap(Context.Peb.ProcessHeap, 0, Context.Size);

  if EnvBlock = nil then
    Exit(STATUS_NO_MEMORY);

  // Fill the environment. The source is stored after the context.
  {$Q-}
  Context.memmove(EnvBlock, Pointer(UIntPtr(Context) +
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

function NtxpPrepareEnvSetterNative(hxProcess: IHandle; RemotePeb: Pointer;
  Environment: IEnvironment; out Context: IMemory): TNtxStatus;
var
  Addresses: TArray<Pointer>;
  LocalContext: IMemory<PEnvironmetSetterContext>;
  pEnvStart: Pointer;
begin
  // Find required functions
  Result := RtlxFindKnownDllExportsNative(ntdll, ['RtlAllocateHeap', 'memmove',
    'RtlSetCurrentEnvironment'], Addresses);

  if not Result.IsSuccess then
    Exit;

  // Allocate local context buffer
  IMemory(LocalContext) := TAutoMemory.Allocate(SizeOf(TEnvironmetSetterContext)
    + Environment.Size);

  // Fill it in
  LocalContext.Data.RtlAllocateHeap := Addresses[0];
  LocalContext.Data.memmove := Addresses[1];
  LocalContext.Data.RtlSetCurrentEnvironment := Addresses[2];
  LocalContext.Data.Peb := RemotePeb;
  LocalContext.Data.Size := Environment.Size;

  // Append the environment
  pEnvStart := LocalContext.Offset(SizeOf(TEnvironmetSetterContext));
  Move(Environment.Data^, pEnvStart^, Environment.Size);

  // Write the context
  Result := NtxAllocWriteMemoryProcess(hxProcess, LocalContext.Region, Context);
end;

{$IFDEF Win64}
function NtxpPrepareEnvSetterWoW64(hxProcess: IHandle; RemotePeb: Pointer;
  Environment: IEnvironment; out Context: IMemory): TNtxStatus;
var
  Addresses: TArray<Pointer>;
  LocalContext: IMemory<PEnvironmetSetterContextWoW64>;
  pEnvStart: Pointer;
begin
  // Find required functions
  Result := RtlxFindKnownDllExportsWoW64(ntdll, ['RtlAllocateHeap', 'memmove',
    'RtlSetCurrentEnvironment'], Addresses);

  if not Result.IsSuccess then
    Exit;

  // Allocate local context buffer
  IMemory(LocalContext) := TAutoMemory.Allocate(
    SizeOf(TEnvironmetSetterContextWoW64) + Environment.Size);

  // Fill it in
  LocalContext.Data.RtlAllocateHeap := WoW64Pointer(Addresses[0]);
  LocalContext.Data.memmove := WoW64Pointer(Addresses[1]);
  LocalContext.Data.RtlSetCurrentEnvironment := WoW64Pointer(Addresses[2]);
  LocalContext.Data.Peb := WoW64Pointer(RemotePeb);
  LocalContext.Data.Size := Cardinal(Environment.Size);

  // Append the environment
  pEnvStart := LocalContext.Offset(SizeOf(TEnvironmetSetterContextWoW64));
  Move(Environment.Data^, pEnvStart^, Environment.Size);

  // Write the context
  Result := NtxAllocWriteMemoryProcess(hxProcess, LocalContext.Region, Context,
    True);
end;
{$ENDIF}

function NtxSetEnvironmentProcess(hxProcess: IHandle; Environment: IEnvironment;
  Timeout: Int64): TNtxStatus;
var
  WoW64Peb: PPeb32;
  BasicInfo: TProcessBasicInformation;
  Context, Code: IMemory;
  hxThread: IHandle;
begin
  // Prevent WoW64 -> Native scenarious
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, WoW64Peb);

  if not Result.IsSuccess then
    Exit;

  // Prepare and write the context data
{$IFDEF Win64}
  if Assigned(WoW64Peb) then
    Result := NtxpPrepareEnvSetterWoW64(hxProcess, WoW64Peb, Environment,
      Context)
  else
{$ENDIF}
  begin
    // Query native PEB location
    Result := NtxProcess.Query(hxProcess.Handle, ProcessBasicInformation,
      BasicInfo);

    if Result.IsSuccess then
      Result := NtxpPrepareEnvSetterNative(hxProcess, BasicInfo.PebBaseAddress,
        Environment, Context);
  end;

  if not Result.IsSuccess then
    Exit;

  // Allocate our payload's code
{$IFDEF Win64}
  if not Assigned(WoW64Peb) then
    Result := NtxMemory.AllocWriteExec(hxProcess, RemoteEnvSetter64, Code,
      False)
  else
{$ENDIF}
    Result := NtxMemory.AllocWriteExec(hxProcess, RemoteEnvSetter32, Code,
      True);

  if not Result.IsSuccess then
    Exit;

  // Create a thread
  Result := NtxCreateThread(hxThread, hxProcess.Handle, Code.Data,
    Context.Data);

  if not Result.IsSuccess then
    Exit;

  // Sync with the thread. Prolong remote memory lifetime on timeout.
  Result := RtlxSyncThread(hxThread.Handle, 'Remote::RtlSetCurrentEnvironment',
    Timeout, [Code, Context]);
end;

function RtlxSetDirectoryProcess(hxProcess: IHandle; Directory: String;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT): TNtxStatus;
var
  TargetIsWoW64: Boolean;
  Functions: TArray<Pointer>;
  LocalBuffer: IMemory<PNtUnicodeString>;
  BufferSize: NativeUInt;
  RemoteBuffer: IMemory;
  hxThread: IHandle;
{$IFDEF Win64}
  LocalBuffer32: IMemory<PNtUnicodeString32> absolute LocalBuffer;
{$ENDIF}
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

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
    BufferSize := TNtUnicodeString32.RequiredSize(Directory)
  else
{$ENDIF}
    BufferSize := TNtUnicodeString.RequiredSize(Directory);

  // Allocate a remote buffer
  Result := NtxAllocateMemoryProcess(hxProcess, BufferSize, RemoteBuffer,
    TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  IMemory(LocalBuffer) := TAutoMemory.Allocate(BufferSize);

  // Marshal the data
{$IFDEF Win64}
  if TargetIsWoW64 then
  begin
    TNtUnicodeString32.Marshal(Directory, LocalBuffer32.Data);
    LocalBuffer32.Data.Buffer := WoW64Pointer(RemoteBuffer.Offset(
      SizeOf(TNtUnicodeString32)));
  end
  else
{$ENDIF}
  begin
    TNtUnicodeString.Marshal(Directory, LocalBuffer.Data);
    LocalBuffer.Data.Buffer := RemoteBuffer.Offset(SizeOf(TNtUnicodeString));
  end;

  // Write it
  Result := NtxWriteMemoryProcess(hxProcess.Handle, RemoteBuffer.Data,
    TMemory.From(LocalBuffer.Data, BufferSize));

  if not Result.IsSuccess then
    Exit;

  // Create a thread that will do the work
  Result := NtxCreateThread(hxThread, hxProcess.Handle, Functions[0],
    RemoteBuffer.Data);

  if not Result.IsSuccess then
    Exit;

  // Sync with the thread. Prolong remote buffer lifetime on timeout.
  Result := RtlxSyncThread(hxThread.Handle, 'Remote::RtlSetCurrentDirectory_U',
    Timeout, [RemoteBuffer]);
end;


end.
