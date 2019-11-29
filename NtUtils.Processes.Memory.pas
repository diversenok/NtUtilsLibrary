unit NtUtils.Processes.Memory;

interface

uses
  NtUtils.Exceptions, Ntapi.ntmmapi;

// Allocate memory in a process
function NtxAllocateMemoryProcess(hProcess: THandle; Size: NativeUInt;
  out Address: Pointer; Protection: Cardinal = PAGE_READWRITE): TNtxStatus;

// Free memory in a process
function NtxFreeMemoryProcess(hProcess: THandle; Address: Pointer;
  Size: NativeUInt): TNtxStatus;

// Change memory protection
function NtxProtectMemoryProcess(hProcess: THandle; Address: Pointer;
  Size: NativeUInt; Protection: Cardinal; OldProtection: PCardinal = nil)
  : TNtxStatus;

// Read memory
function NtxReadMemoryProcess(hProcess: THandle; Address: Pointer;
  Buffer: Pointer; BufferSize: NativeUInt): TNtxStatus;

// Write memory
function NtxWriteMemoryProcess(hProcess: THandle; Address: Pointer;
  Buffer: Pointer; BufferSize: NativeUInt): TNtxStatus;

// Flush instruction cache
function NtxFlushInstructionCache(hProcess: THandle; Address: Pointer;
  Size: NativeUInt): TNtxStatus;

type
  NtxMemory = class
    // Query fixed-size information
    class function Query<T>(hProcess: THandle; Address: Pointer;
      InfoClass: TMemoryInformationClass; out Buffer: T): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntpsapi;

function NtxAllocateMemoryProcess(hProcess: THandle; Size: NativeUInt;
  out Address: Pointer; Protection: Cardinal): TNtxStatus;
var
  RegionSize: NativeUInt;
begin
  Address := nil;
  RegionSize := Size;

  Result.Location := 'NtAllocateVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtAllocateVirtualMemory(hProcess, Address, 0,
    RegionSize, MEM_COMMIT, Protection);
end;

function NtxFreeMemoryProcess(hProcess: THandle; Address: Pointer;
  Size: NativeUInt): TNtxStatus;
var
  BaseAddress: Pointer;
  RegionSize: NativeUInt;
begin
  BaseAddress := Address;
  RegionSize := Size;

  Result.Location := 'NtFreeVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtFreeVirtualMemory(hProcess, BaseAddress, RegionSize,
    MEM_RELEASE);
end;

function NtxProtectMemoryProcess(hProcess: THandle; Address: Pointer;
  Size: NativeUInt; Protection: Cardinal; OldProtection: PCardinal): TNtxStatus;
var
  BaseAddress: Pointer;
  RegionSize: NativeUInt;
  dwOldProtection: Cardinal;
begin
  BaseAddress := Address;
  RegionSize := Size;

  Result.Location := 'NtProtectVirtualMemory';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtProtectVirtualMemory(hProcess, BaseAddress, RegionSize,
    Protection, dwOldProtection);

  if Assigned(OldProtection) then
    OldProtection^ := dwOldProtection;
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

end.
