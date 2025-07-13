unit NtUtils.Environment.Remote;

{
  This module provides functions to manipulate environment variables and the
  current directory of other processes.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode;

const
  PROCESS_QUERY_ENVIRONMENT = PROCESS_QUERY_LIMITED_INFORMATION or
    PROCESS_VM_READ;

  PROCESS_SET_ENVIRONMENT = PROCESS_REMOTE_EXECUTE;
  PROCESS_SET_DIRECTORY = PROCESS_REMOTE_EXECUTE;

// Obtain a copy of environment of a process
function NtxQueryEnvironmentProcess(
  [Access(PROCESS_QUERY_ENVIRONMENT)] const hxProcess: IHandle;
  out Environment: IEnvironment
): TNtxStatus;

// Set environment for a process
function NtxSetEnvironmentProcess(
  [Access(PROCESS_SET_ENVIRONMENT)] const hxProcess: IHandle;
  const Environment: IEnvironment;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

// Set current directory for a process
function RtlxSetDirectoryProcess(
  [Access(PROCESS_SET_DIRECTORY)] const hxProcess: IHandle;
  const Directory: String;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb, Ntapi.ntwow64,
  NtUtils.Processes.Info, NtUtils.Memory, NtUtils.Environment,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ --------------------------- Environment Querying --------------------------- }

function NtxQueryEnvironmentProcess;
var
  IsWoW64: Boolean;
  BasicInfo: TProcessBasicInformation;
  Params: PRtlUserProcessParameters;
  Size: NativeUInt;
  pRemoteEnv: Pointer;
  Buffer: IMemory;
begin
  // Prevent WoW64 -> Native scenarios
  Result := RtlxAssertWoW64Compatible(hxProcess, IsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Usually, both native and WoW64 PEBs point to the same environment.
  // We will query the same bitness of PEB for simplicity.

  // Locate PEB
  Result := NtxProcess.Query(hxProcess, ProcessBasicInformation, BasicInfo);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(BasicInfo.PebBaseAddress) then
  begin
    Result.Location := 'NtxQueryEnvironmentProcess';
    Result.Status := STATUS_PROCESS_IS_TERMINATING;
    Exit;
  end;

  // Locate process parameters
  Result := NtxMemory.Read(hxProcess,
    @BasicInfo.PebBaseAddress.ProcessParameters, Params);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(Params) then
  begin
    Result.Location := 'NtxQueryEnvironmentProcess';
    Result.Status := STATUS_ACCESS_VIOLATION;
    Exit;
  end;

  // Get environmental block size
  Result := NtxMemory.Read(hxProcess, @Params.EnvironmentSize, Size);

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
  Result := NtxMemory.Read(hxProcess, @Params.Environment, pRemoteEnv);

  if not Result.IsSuccess then
    Exit;

  // Allocated a region compatible with RtlDestroyEnvironment
  Result := RtlxAllocateHeap(Buffer, Size, 0);

  if not Result.IsSuccess then
    Exit;

  // Read the environment block
  Result := NtxReadMemory(hxProcess, pRemoteEnv, Buffer.Region);

  if not Result.IsSuccess then
    Exit;

  // Re-capture the buffer as an environment block
  Environment := RtlxCaptureEnvironment(Buffer.Data, Buffer.Size);
  Buffer.DiscardOwnership;
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
  {$Q-}{$R-}
  Context.memmove(EnvBlock, PByte(Context) + SizeOf(TEnvContext),
    Context.EnvironmentSize);
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

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
  // Prevent WoW64 -> Native scenarios
  Result := RtlxAssertWoW64CompatiblePeb(hxProcess, WoW64Peb);

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
    Result := NtxProcess.Query(hxProcess, ProcessBasicInformation, BasicInfo);

    if not Result.IsSuccess then
      Exit;

    LocalMapping.Data.Peb := BasicInfo.PebBaseAddress;
  end;

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    hxProcess,
    'Remote::RtlSetCurrentEnvironment',
    RemoteMapping.Offset(SizeOf(TEnvContext) + Environment.Size),
    CodeRef.Size,
    RemoteMapping.Data,
    THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH,
    Timeout,
    [RemoteMapping]
  );
end;

{ ---------------------------- Directory Setting ----------------------------- }

function RtlxSetDirectoryProcess;
var
  TargetIsWoW64: Boolean;
  pRtlSetCurrentDirectory_U: Pointer;
  LocalMapping: IMemory<PNtUnicodeString>;
  RemoteMapping: IMemory;
  BufferSize: NativeUInt;
{$IFDEF Win64}
  LocalMapping32: IMemory<PNtUnicodeString32> absolute LocalMapping;
{$ENDIF}
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Compute the required amount of memory for the path we are going to allocate
{$IFDEF Win64}
  if TargetIsWoW64 then
    BufferSize := SizeOf(TNtUnicodeString32) + StringSizeZero(Directory)
  else
{$ENDIF}
    BufferSize := SizeOf(TNtUnicodeString) + StringSizeZero(Directory);

  // Prepare for sharing a read-only buffer
  Result := RtlxMapSharedMemory(hxProcess, BufferSize, IMemory(LocalMapping),
    IMemory(RemoteMapping), []);

  if not Result.IsSuccess then
    Exit;

  // Write the string to the section
{$IFDEF Win64}
  if TargetIsWoW64 then
  begin
    LocalMapping32.Data.Length := StringSizeNoZero(Directory);
    LocalMapping32.Data.MaximumLength := StringSizeZero(Directory);
    LocalMapping32.Data.Buffer := RemoteMapping.Offset(SizeOf(TNtUnicodeString32));
    MarshalString(Directory, LocalMapping32.Offset(SizeOf(TNtUnicodeString32)));
  end
  else
{$ENDIF}
  begin
    Result := RtlxMarshalUnicodeString(Directory, LocalMapping.Data^,
      LocalMapping.Offset(SizeOf(TNtUnicodeString)));

    if not Result.IsSuccess then
      Exit;

    {$R-}{$Q-}
    Inc(PByte(LocalMapping.Data.Buffer), UIntPtr(RemoteMapping.Data) -
      UIntPtr(LocalMapping.Data));
    {$IFDEF Q+}{$Q+}{$ENDIF}{$IFDEF R+}{$R+}{$ENDIF}
  end;

  // Find the function's address. Conveniently, it has the same prototype as
  // a thread routine, so we can create a remote thread pointing directly to
  // this function.
  Result := RtlxFindKnownDllExport(ntdll, TargetIsWoW64,
    'RtlSetCurrentDirectory_U', pRtlSetCurrentDirectory_U);

  if not Result.IsSuccess then
    Exit;

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    hxProcess,
    'Remote::RtlSetCurrentDirectory_U',
    pRtlSetCurrentDirectory_U,
    0,
    RemoteMapping.Data,
    THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH,
    Timeout,
    [RemoteMapping]
  );
end;

end.
