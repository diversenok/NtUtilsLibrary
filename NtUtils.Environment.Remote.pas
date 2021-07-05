unit NtUtils.Environment.Remote;

{
  This module provides functions to manipulate environment variables and the
  current directory of other processes.
}

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode;

const
  PROCESS_QUERY_ENVIRONMENT = PROCESS_QUERY_LIMITED_INFORMATION or
    PROCESS_VM_READ;

  PROCESS_SET_ENVIRONMENT = PROCESS_REMOTE_EXECUTE;
  PROCESS_SET_DIRECTORY = PROCESS_REMOTE_EXECUTE;

// Obtain a copy of environment of a process
function NtxQueryEnvironmentProcess(
  const hProcess: THandle;
  out Environment: IEnvironment
): TNtxStatus;

// Set environment for a process
function NtxSetEnvironmentProcess(
  const hxProcess: IHandle;
  const Environment: IEnvironment;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

// Set current directory for a process
function RtlxSetDirectoryProcess(
  const hxProcess: IHandle;
  const Directory: String;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb, Ntapi.ntwow64,
  NtUtils.Processes.Query, NtUtils.Processes.Memory, NtUtils.Environment,
  DelphiUtils.AutoObjects;

{ --------------------------- Environment Querying --------------------------- }

function NtxQueryEnvironmentProcess;
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

{ --------------------------- Environment Setting ---------------------------- }

type
  // We are going to execute a function within the target process,
  // so it requires some data to work with
  TEnvContext = record
    RtlAllocateHeap: function (
      HeapHandle: Pointer;
      Flags: THeapFlags;
      Size: NativeUInt
    ): Pointer; stdcall;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}

    memmove: function (
      Dst: Pointer;
      Src: Pointer;
      Size: NativeUInt
    ): Pointer; cdecl;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}

    RtlSetCurrentEnvironment: function (
      Environment: Pointer;
      PreviousEnvironment: PPointer
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding3: Cardinal;{$ENDIF}

    Peb: PPeb;
    {$IFDEF Win32}WoW64Padding4: Cardinal;{$ENDIF}

    EnvironmentSize: Cardinal;
    {$IFDEF Win32}WoW64Padding5: Cardinal;{$ENDIF}
  end;
  PEnvContext = ^TEnvContext;

// NOTE: be consistent with raw assembly below. We are going to inject it.
function RemoteEnvSetter(Context: PEnvContext): NTSTATUS; stdcall;
var
  EnvBlock: PEnvironment;
begin
  // Allocate memory the same way RtlCreateEnvironment does,
  // so it can be freed with RtlDestroyEnvironment.
  EnvBlock := Context.RtlAllocateHeap(Context.Peb.ProcessHeap, 0,
    Context.EnvironmentSize);

  if EnvBlock = nil then
    Exit(STATUS_NO_MEMORY);

  // Fill the environment. The source is stored after the context.
  {$Q-}
  Context.memmove(EnvBlock, PByte(Context) + SizeOf(TEnvContext),
    Context.EnvironmentSize);
  {$Q+}

  // Set it
  Result := Context.RtlSetCurrentEnvironment(EnvBlock, nil);
end;

const
  {$IFDEF Win64}
  // Raw assembly code we are going to inject.
  // NOTE: be consistent with the function code above
  RemoteEnvSetter64: array [0..71] of Byte = (
    $56, $53, $48, $83, $EC, $28, $48, $89, $CB, $48, $8B, $43, $18, $48, $8B,
    $48, $30, $33, $D2, $44, $8B, $43, $20, $FF, $13, $48, $89, $C6, $48, $85,
    $F6, $75, $07, $B8, $17, $00, $00, $C0, $EB, $16, $48, $89, $F1, $48, $8D,
    $53, $28, $44, $8B, $43, $20, $FF, $53, $08, $48, $89, $F1, $33, $D2, $FF,
    $53, $10, $48, $83, $C4, $28, $5B, $5E, $C3, $CC, $CC, $CC
  );
  {$ENDIF}

  // Raw assembly code we are going to inject.
  // NOTE: be consistent with the function code above
  RemoteEnvSetter32: array [0..71] of Byte = (
    $55, $8B, $EC, $53, $56, $8B, $5D, $08, $8B, $43, $20, $50, $6A, $00, $8B,
    $43, $18, $8B, $40, $18, $50, $FF, $13, $8B, $F0, $85, $F6, $75, $07, $B8,
    $17, $00, $00, $C0, $EB, $17, $8B, $43, $20, $50, $8B, $C3, $83, $C0, $28,
    $50, $56, $FF, $53, $08, $83, $C4, $0C, $6A, $00, $56, $FF, $53, $10, $5E,
    $5B, $5D, $C2, $04, $00, $CC, $CC, $CC, $CC, $CC, $CC, $CC
  );

function NtxSetEnvironmentProcess;
var
  WoW64Peb: PPeb32;
  BasicInfo: TProcessBasicInformation;
  LocalMapping: IMemory<PEnvContext>;
  RemoteMapping: IMemory;
  CodeRef: TMemory;
  Addresses: TArray<Pointer>;
begin
  // Prevent WoW64 -> Native scenarious
  Result := RtlxAssertWoW64CompatiblePeb(hxProcess.Handle, WoW64Peb);

  if not Result.IsSuccess then
    Exit;

  // Select suitable shellcode
{$IFDEF Win64}
  if not Assigned(WoW64Peb) then
    CodeRef := TMemory.Reference(RemoteEnvSetter64)
  else
{$ENDIF}
    CodeRef := TMemory.Reference(RemoteEnvSetter32);

  // Map a shared memory region
  Result := RtlxMapSharedMemory(hxProcess, SizeOf(TEnvContext) +
    Environment.Size + CodeRef.Size, IMemory(LocalMapping), RemoteMapping,
    [mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  // Find dependencies
  Result := RtlxFindKnownDllExports(ntdll, Assigned(WoW64Peb),
    ['RtlAllocateHeap', 'memmove', 'RtlSetCurrentEnvironment'], Addresses);

  if not Result.IsSuccess then
    Exit;

  // Start preparing the shellcode and its parameters
  LocalMapping.Data.RtlAllocateHeap := Addresses[0];
  LocalMapping.Data.memmove := Addresses[1];
  LocalMapping.Data.RtlSetCurrentEnvironment := Addresses[2];
  LocalMapping.Data.EnvironmentSize := Cardinal(Environment.Size);

  Move(Environment.Data^, LocalMapping.Offset(SizeOf(TEnvContext))^,
    Environment.Size);

  Move(CodeRef.Address^, LocalMapping.Offset(SizeOf(TEnvContext) +
    Environment.Size)^, CodeRef.Size);

  // We also need PEB address
{$IFDEF Win64}
  if Assigned(WoW64Peb) then
    LocalMapping.Data.Peb := Pointer(WoW64Peb)
  else
{$ENDIF}
  begin
    // Query native PEB's location
    Result := NtxProcess.Query(hxProcess.Handle, ProcessBasicInformation,
      BasicInfo);

    if not Result.IsSuccess then
      Exit;

    LocalMapping.Data.Peb := Pointer(BasicInfo.PebBaseAddress);
  end;

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    hxProcess.Handle,
    'Remote::RtlSetCurrentEnvironment',
    RemoteMapping.Offset(SizeOf(TEnvContext) + Environment.Size),
    CodeRef.Size,
    RemoteMapping.Data,
    0,
    Timeout,
    [RemoteMapping]
  );
end;

{ ---------------------------- Directory Setting ----------------------------- }

function RtlxSetDirectoryProcess;
var
  TargetIsWoW64: Boolean;
  pRtlSetCurrentDirectory_U: Pointer;
  LocalMapping, RemoteMapping: IMemory;
  BufferSize: NativeUInt;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Compute the required amount of memory for the path we are going to allocate
{$IFDEF Win64}
  if TargetIsWoW64 then
    BufferSize := TNtUnicodeString32.RequiredSize(Directory)
  else
{$ENDIF}
    BufferSize := TNtUnicodeString.RequiredSize(Directory);

  // Prepare for sharing a read-only buffer
  Result := RtlxMapSharedMemory(hxProcess, BufferSize, LocalMapping,
    RemoteMapping, []);

  if not Result.IsSuccess then
    Exit;

  // Write the string to the section
{$IFDEF Win64}
  if TargetIsWoW64 then
    TNtUnicodeString32.MarshalEx(Directory, LocalMapping.Data,
      RemoteMapping.Data)
  else
{$ENDIF}
    TNtUnicodeString.MarshalEx(Directory, LocalMapping.Data,
      RemoteMapping.Data);

  // Find the function's address. Conveniently, it has the same prototype as
  // a thread routine, so we can create a remote thread pointing directly to
  // this function.
  Result := RtlxFindKnownDllExport(ntdll, TargetIsWoW64,
    'RtlSetCurrentDirectory_U', pRtlSetCurrentDirectory_U);

  if not Result.IsSuccess then
    Exit;

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    hxProcess.Handle,
    'Remote::RtlSetCurrentDirectory_U',
    pRtlSetCurrentDirectory_U,
    0,
    RemoteMapping.Data,
    0,
    Timeout,
    [RemoteMapping]
  );
end;

end.
