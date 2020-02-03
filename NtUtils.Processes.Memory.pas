unit NtUtils.Processes.Memory;

interface

uses
  NtUtils.Exceptions, Ntapi.ntmmapi;

// Allocate memory in a process
function NtxAllocateMemoryProcess(hProcess: THandle; Size: NativeUInt;
  out Memory: TMemory; Protection: Cardinal = PAGE_READWRITE): TNtxStatus;

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
  BufferSize: NativeUInt; out Memory: TMemory): TNtxStatus;

// Allocate and write executable memory
function NtxAllocWriteExecMemoryProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Memory: TMemory): TNtxStatus;

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
      out Memory: TMemory): TNtxStatus; static;

    // Allocate and write executable memory a fixed-size structure
    class function AllocWriteExec<T>(hProcess: THandle; const Buffer: T;
      out Memory: TMemory): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntseapi;

function NtxAllocateMemoryProcess(hProcess: THandle; Size: NativeUInt;
  out Memory: TMemory; Protection: Cardinal = PAGE_READWRITE): TNtxStatus;
begin
  Memory.Address := nil;
  Memory.Size := Size;

  Result.Location := 'NtAllocateVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtAllocateVirtualMemory(hProcess, Memory.Address, 0,
    Memory.Size, MEM_COMMIT, Protection);
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
  BufferSize: NativeUInt; out Memory: TMemory): TNtxStatus;
begin
  // Allocate writable memory
  Result := NtxAllocateMemoryProcess(hProcess, BufferSize, Memory);

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
  BufferSize: NativeUInt; out Memory: TMemory): TNtxStatus;
begin
  // Allocate and write RW memory
  Result := NtxAllocWriteMemoryProcess(hProcess, Buffer, BufferSize, Memory);

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
  out Memory: TMemory): TNtxStatus;
begin
  Result := NtxAllocWriteMemoryProcess(hProcess, @Buffer, SizeOf(Buffer),
    Memory);
end;

class function NtxMemory.AllocWriteExec<T>(hProcess: THandle; const Buffer: T;
  out Memory: TMemory): TNtxStatus;
begin
  Result := NtxAllocWriteExecMemoryProcess(hProcess, @Buffer, SizeOf(Buffer),
    Memory);
end;

end.
