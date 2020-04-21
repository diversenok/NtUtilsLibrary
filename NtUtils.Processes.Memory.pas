unit NtUtils.Processes.Memory;

interface

uses
  Ntapi.ntmmapi, NtUtils, DelphiApi.Reflection;

type
  TWorkingSetBlock = record
    VirtualAddress: Pointer;
    [Hex] Protection: Cardinal;
    ShareCount: Cardinal;
    Shared: Boolean;
    Node: Cardinal;
  end;

// Make sure the memory region is accessible from a WoW64 process
{$IFDEF Win64}
function NtxAssertWoW64Accessible(const Memory: TMemory): TNtxStatus;
{$ENDIF}

// Allocate memory in a process
function NtxAllocateMemoryProcess(hProcess: THandle; Size: NativeUInt;
  out Memory: TMemory; EnsureWoW64Accessible: Boolean = False;
  Protection: Cardinal = PAGE_READWRITE): TNtxStatus;

// Free memory in a process
function NtxFreeMemoryProcess(hProcess: THandle; Address: Pointer;
  Size: NativeUInt): TNtxStatus;

// Change memory protection
function NtxProtectMemoryProcess(hProcess: THandle; var Memory: TMemory;
  Protection: Cardinal; pOldProtected: PCardinal = nil): TNtxStatus;

// Read memory
function NtxReadMemoryProcess(hProcess: THandle; Address: Pointer;
  Buffer: Pointer; BufferSize: NativeUInt): TNtxStatus;

// Write memory
function NtxWriteMemoryProcess(hProcess: THandle; Address: Pointer;
  Buffer: Pointer; BufferSize: NativeUInt): TNtxStatus;

// Flush instruction cache
function NtxFlushInstructionCache(hProcess: THandle; Address: Pointer;
  Size: NativeUInt): TNtxStatus;

// Lock memory pages in working set or physical memory
function NtxLockVirtualMemory(hProcess: THandle; var Memory: TMemory;
  MapType: TMapLockType = MAP_PROCESS): TNtxStatus;

// Unlock locked memory pages
function NtxUnlockVirtualMemory(hProcess: THandle; var Memory: TMemory;
  MapType: TMapLockType = MAP_PROCESS): TNtxStatus;

{ -------------------------------- Extension -------------------------------- }

// Allocate and write memory
function NtxAllocWriteMemoryProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Memory: TMemory; EnsureWoW64Accessible: Boolean =
  False): TNtxStatus;

// Allocate and write executable memory
function NtxAllocWriteExecMemoryProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Memory: TMemory; EnsureWoW64Accessible: Boolean =
  False): TNtxStatus;

{ ------------------------------- Information ------------------------------- }

// Query variable-size memory information
function NtxQueryMemory(hProcess: THandle; Address: Pointer;
  InfoClass: TMemoryInformationClass; out xBuffer: IMemory): TNtxStatus;

// Query mapped filename
function NtxQueryFileNameMemory(hProcess: THandle; Address: Pointer;
  out Filename: String): TNtxStatus;

// Enumerate memory regions of a process's working set
function NtxEnumerateMemory(hProcess: THandle; out WorkingSet:
  TArray<TWorkingSetBlock>): TNtxStatus;

{ ----------------------------- Generic wrapper ----------------------------- }

type
  NtxMemory = class
    // Query fixed-size information
    class function Query<T>(hProcess: THandle; Address: Pointer;
      InfoClass: TMemoryInformationClass; out Buffer: T): TNtxStatus; static;

    // Read a fixed-size structure
    class function Read<T>(hProcess: THandle; Address: Pointer; out Buffer: T):
      TNtxStatus; static;

    // Write a fixed-size structure
    class function Write<T>(hProcess: THandle; Address: Pointer; const
      Buffer: T): TNtxStatus; static;

    // Allocate and write a fixed-size structure
    class function AllocWrite<T>(hProcess: THandle; const Buffer: T;
      out Memory: TMemory; EnsureWoW64Accessible: Boolean = False): TNtxStatus;
      static;

    // Allocate and write executable memory a fixed-size structure
    class function AllocWriteExec<T>(hProcess: THandle; const Buffer: T;
      out Memory: TMemory; EnsureWoW64Accessible: Boolean = False): TNtxStatus;
      static;
  end;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntseapi, Ntapi.ntdef, Ntapi.ntstatus;

{$IFDEF Win64}
function NtxAssertWoW64Accessible(const Memory: TMemory): TNtxStatus;
begin
  if NativeUInt(Memory.Address) + Memory.Size < Cardinal(-1) then
    Result.Status := STATUS_SUCCESS
  else
  begin
    Result.Location := 'NtxAssertWoW64Accessible';
    Result.Status := STATUS_NO_MEMORY;
  end;
end;
{$ENDIF}

function NtxAllocateMemoryProcess(hProcess: THandle; Size: NativeUInt;
  out Memory: TMemory; EnsureWoW64Accessible: Boolean; Protection: Cardinal)
  : TNtxStatus;
begin
  Memory.Address := nil;
  Memory.Size := Size;

  Result.Location := 'NtAllocateVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtAllocateVirtualMemory(hProcess, Memory.Address, 0,
    Memory.Size, MEM_COMMIT, Protection);

{$IFDEF Win64}
  if EnsureWoW64Accessible and Result.IsSuccess then
  begin
    Result := NtxAssertWoW64Accessible(Memory);

    // Undo on assertion failure
    if not Result.IsSuccess then
      NtxFreeMemoryProcess(hProcess, Memory.Address, Memory.Size);
  end;
{$ENDIF}
end;

function NtxFreeMemoryProcess(hProcess: THandle; Address: Pointer;
  Size: NativeUInt): TNtxStatus;
var
  Memory: TMemory;
begin
  Memory.Address := Address;
  Memory.Size := Size;

  Result.Location := 'NtFreeVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtFreeVirtualMemory(hProcess, Memory.Address, Memory.Size,
    MEM_RELEASE);
end;

function NtxProtectMemoryProcess(hProcess: THandle; var Memory: TMemory;
  Protection: Cardinal; pOldProtected: PCardinal = nil): TNtxStatus;
var
  OldProtected: Cardinal;
begin
  Result.Location := 'NtProtectVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtProtectVirtualMemory(hProcess, Memory.Address, Memory.Size,
    Protection, OldProtected);

  if Result.IsSuccess and Assigned(pOldProtected) then
    pOldProtected^ := OldProtected;
end;

function NtxReadMemoryProcess(hProcess: THandle; Address: Pointer;
  Buffer: Pointer; BufferSize: NativeUInt): TNtxStatus;
begin
  Result.Location := 'NtReadVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_READ, @ProcessAccessType);

  Result.Status := NtReadVirtualMemory(hProcess, Address, Buffer, BufferSize,
    nil);
end;

function NtxWriteMemoryProcess(hProcess: THandle; Address: Pointer;
  Buffer: Pointer; BufferSize: NativeUInt): TNtxStatus;
begin
  Result.Location := 'NtWriteVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_WRITE, @ProcessAccessType);

  Result.Status := NtWriteVirtualMemory(hProcess, Address, Buffer, BufferSize,
    nil);
end;

function NtxFlushInstructionCache(hProcess: THandle; Address: Pointer;
  Size: NativeUInt): TNtxStatus;
begin
  Result.Location := 'NtxFlushInstructionCacheProcess';
  Result.LastCall.Expects(PROCESS_VM_WRITE, @ProcessAccessType);

  Result.Status := NtFlushInstructionCache(hProcess, Address, Size);
end;

function NtxLockVirtualMemory(hProcess: THandle; var Memory: TMemory;
  MapType: TMapLockType): TNtxStatus;
begin
  Result.Location := 'NtLockVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  if MapType = MAP_SYSTEM then
    Result.LastCall.ExpectedPrivilege := SE_LOCK_MEMORY_PRIVILEGE;

  Result.Status := NtLockVirtualMemory(hProcess, Memory.Address, Memory.Size,
    MapType);
end;

function NtxUnlockVirtualMemory(hProcess: THandle; var Memory: TMemory;
  MapType: TMapLockType): TNtxStatus;
begin
  Result.Location := 'NtUnlockVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  if MapType = MAP_SYSTEM then
    Result.LastCall.ExpectedPrivilege := SE_LOCK_MEMORY_PRIVILEGE;

  Result.Status := NtUnlockVirtualMemory(hProcess, Memory.Address, Memory.Size,
    MapType);
end;

{ Extension }

function NtxAllocWriteMemoryProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Memory: TMemory; EnsureWoW64Accessible: Boolean)
  : TNtxStatus;
begin
  // Allocate writable memory
  Result := NtxAllocateMemoryProcess(hProcess, BufferSize, Memory,
    EnsureWoW64Accessible);

  if Result.IsSuccess then
  begin
    // Write data
    Result := NtxWriteMemoryProcess(hProcess, Memory.Address, Buffer,
      BufferSize);

    // Undo allocation on failure
    if not Result.IsSuccess then
      NtxFreeMemoryProcess(hProcess, Memory.Address, Memory.Size);
  end;
end;

function NtxAllocWriteExecMemoryProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Memory: TMemory; EnsureWoW64Accessible: Boolean): TNtxStatus;
begin
  // Allocate and write RW memory
  Result := NtxAllocWriteMemoryProcess(hProcess, Buffer, BufferSize, Memory,
    EnsureWoW64Accessible);

  if Result.IsSuccess then
  begin
    // Make it executable
    Result := NtxProtectMemoryProcess(hProcess, Memory, PAGE_EXECUTE_READ);

    // Always flush instruction cache when changing executable memory
    if Result.IsSuccess then
      Result := NtxFlushInstructionCache(hProcess, Memory.Address, Memory.Size);

    // Undo on failure
    if not Result.IsSuccess then
      NtxFreeMemoryProcess(hProcess, Memory.Address, Memory.Size);
  end;
end;

{ Information }

function NtxQueryMemory(hProcess: THandle; Address: Pointer;
  InfoClass: TMemoryInformationClass; out xBuffer: IMemory): TNtxStatus;
var
  Buffer: Pointer;
  BufferSize: Cardinal;
  Required: NativeUInt;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TMemoryInformationClass);
  Result.LastCall.Expects(PROCESS_QUERY_INFORMATION, @ProcessAccessType);

  BufferSize := 0;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryVirtualMemory(hProcess, Address, InfoClass,
      Buffer, BufferSize, @Required);

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, Cardinal(Required));

  if Result.IsSuccess then
    xBuffer := TAutoMemory.Capture(Buffer, BufferSize);
end;

function NtxQueryFileNameMemory(hProcess: THandle; Address: Pointer;
  out Filename: String): TNtxStatus;
var
  xMemory: IMemory;
begin
  Result := NtxQueryMemory(hProcess, Address, MemoryMappedFilenameInformation,
    xMemory);

  if Result.IsSuccess then
    Filename := UNICODE_STRING(xMemory.Data^).ToString;
end;

function NtxEnumerateMemory(hProcess: THandle; out WorkingSet:
  TArray<TWorkingSetBlock>): TNtxStatus;
var
  Buffer: PMemoryWorkingSetInformation;
  BufferSize, Required: Cardinal;
  Info: NativeUInt;
  i: Integer;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(MemoryWorkingSetInformation);
  Result.LastCall.InfoClassType := TypeInfo(TMemoryInformationClass);
  Result.LastCall.Expects(PROCESS_QUERY_INFORMATION, @ProcessAccessType);

  BufferSize := SizeOf(TMemoryWorkingSetInformation);
  repeat
    Buffer := AllocMem(BufferSize);

    Result.Status := NtQueryVirtualMemory(hProcess, nil,
      MemoryWorkingSetInformation, Buffer, BufferSize, nil);

    // Even if the buffer is too small, we still get the number of entries
    Required := SizeOf(TMemoryWorkingSetInformation) +
      Buffer.NumberOfEntries * SizeOf(NativeUInt);

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, Required, True);

  if not Result.IsSuccess then
    Exit;

  SetLength(WorkingSet, Buffer.NumberOfEntries);

  for i := 0 to High(WorkingSet) do
  begin
    Info := Buffer.WorkingSetInfo{$R-}[i]{$R+};

    // Extract information from a bit union
    WorkingSet[i].Protection := Info and $1F;         // Bits 0..4
    WorkingSet[i].ShareCount := (Info and $E0) shr 5; // Bits 5..7
    WorkingSet[i].Shared := (Info and $100) <> 0;     // Bit 8
    WorkingSet[i].Node := (Info and $E00) shr 9;      // Bits 9..11
    WorkingSet[i].VirtualAddress := Pointer(Info and not NativeUInt($FFF));
  end;

  FreeMem(Buffer);
end;

{ NtxMemory }

class function NtxMemory.Query<T>(hProcess: THandle; Address: Pointer;
  InfoClass: TMemoryInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TMemoryInformationClass);
  Result.LastCall.Expects(PROCESS_QUERY_INFORMATION, @ProcessAccessType);

  Result.Status := NtQueryVirtualMemory(hProcess, Address, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

class function NtxMemory.Read<T>(hProcess: THandle; Address: Pointer;
  out Buffer: T): TNtxStatus;
begin
  Result := NtxReadMemoryProcess(hProcess, Address, @Buffer, SizeOf(Buffer));
end;

class function NtxMemory.Write<T>(hProcess: THandle; Address: Pointer;
  const Buffer: T): TNtxStatus;
begin
  Result := NtxWriteMemoryProcess(hProcess, Address, @Buffer, SizeOf(Buffer));
end;

class function NtxMemory.AllocWrite<T>(hProcess: THandle; const Buffer: T;
  out Memory: TMemory; EnsureWoW64Accessible: Boolean): TNtxStatus;
begin
  Result := NtxAllocWriteMemoryProcess(hProcess, @Buffer, SizeOf(Buffer),
    Memory, EnsureWoW64Accessible);
end;

class function NtxMemory.AllocWriteExec<T>(hProcess: THandle; const Buffer: T;
  out Memory: TMemory; EnsureWoW64Accessible: Boolean): TNtxStatus;
begin
  Result := NtxAllocWriteExecMemoryProcess(hProcess, @Buffer, SizeOf(Buffer),
    Memory, EnsureWoW64Accessible);
end;

end.
