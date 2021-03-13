unit NtUtils.Processes.Memory;

{
  This module includes function for process memory management.
}

interface

uses
  Ntapi.ntmmapi, NtUtils, DelphiApi.Reflection;

type
  TWorkingSetBlock = record
    VirtualAddress: Pointer;
    Protection: TMemoryProtection;
    ShareCount: Cardinal;
    Shared: Boolean;
    Node: Cardinal;
  end;

{$IFDEF Win64}
// Make sure the memory region is accessible from a WoW64 process
function NtxAssertWoW64Accessible(const Memory: TMemory): TNtxStatus;
{$ENDIF}

// Allocate memory in a process
function NtxAllocateMemoryProcess(
  hxProcess: IHandle;
  Size: NativeUInt;
  out xMemory: IMemory;
  EnsureWoW64Accessible: Boolean = False;
  Protection: TMemoryProtection = PAGE_READWRITE
): TNtxStatus;

// Free memory in a process
function NtxFreeMemoryProcess(
  hProcess: THandle;
  Address: Pointer;
  Size: NativeUInt
): TNtxStatus;

// Change memory protection
function NtxProtectMemoryProcess(
  hProcess: THandle;
  Address: Pointer;
  Size: NativeUInt;
  Protection: TMemoryProtection;
  pOldProtected: PMemoryProtection = nil
): TNtxStatus;

// Read memory
function NtxReadMemoryProcess(
  hProcess: THandle;
  Address: Pointer;
  const Buffer: TMemory
): TNtxStatus;

// Write memory
function NtxWriteMemoryProcess(
  hProcess: THandle;
  Address: Pointer;
  const Buffer: TMemory
): TNtxStatus;

// Flush instruction cache
function NtxFlushInstructionCache(
  hProcess: THandle;
  Address: Pointer;
  Size: NativeUInt
): TNtxStatus;

// Lock memory pages in working set or physical memory
function NtxLockVirtualMemory(
  hProcess: THandle;
  var Memory: TMemory;
  MapType: TMapLockType = MAP_PROCESS
): TNtxStatus;

// Unlock locked memory pages
function NtxUnlockVirtualMemory(
  hProcess: THandle;
  var Memory: TMemory;
  MapType: TMapLockType = MAP_PROCESS
): TNtxStatus;

{ -------------------------------- Extension -------------------------------- }

// Allocate and write memory
function NtxAllocWriteMemoryProcess(
  hxProcess: IHandle;
  const Buffer: TMemory;
  out xMemory: IMemory;
  EnsureWoW64Accessible: Boolean = False
): TNtxStatus;

// Allocate and write executable memory
function NtxAllocWriteExecMemoryProcess(
  hxProcess: IHandle;
  const Buffer: TMemory;
  out xMemory: IMemory;
  EnsureWoW64Accessible: Boolean = False
): TNtxStatus;

{ ------------------------------- Information ------------------------------- }

// Query variable-size memory information
function NtxQueryMemory(
  hProcess: THandle;
  Address: Pointer;
  InfoClass: TMemoryInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query mapped filename
function NtxQueryFileNameMemory(
  hProcess: THandle;
  Address: Pointer;
  out Filename: String
): TNtxStatus;

// Enumerate memory regions of a process's working set
function NtxEnumerateMemory(
  hProcess: THandle;
  out WorkingSet: TArray<TWorkingSetBlock>
): TNtxStatus;

{ ----------------------------- Generic wrapper ----------------------------- }

type
  NtxMemory = class abstract
    // Query fixed-size information
    class function Query<T>(
      hProcess: THandle;
      Address: Pointer;
      InfoClass: TMemoryInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Read a fixed-size structure
    class function Read<T>(
      hProcess: THandle;
      Address: Pointer;
      out Buffer: T
    ): TNtxStatus; static;

    // Write a fixed-size structure
    class function Write<T>(
      hProcess: THandle;
      Address: Pointer;
      const Buffer: T
    ): TNtxStatus; static;

    // Allocate and write a fixed-size structure
    class function AllocWrite<T>(
      hxProcess: IHandle;
      const Buffer: T;
      out xMemory: IMemory;
      EnsureWoW64Accessible: Boolean = False
    ): TNtxStatus; static;

    // Allocate and write executable memory a fixed-size structure
    class function AllocWriteExec<T>(
      hxProcess: IHandle;
      const Buffer: T;
      out xMemory: IMemory;
      EnsureWoW64Accessible: Boolean = False
    ): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntseapi, Ntapi.ntdef, Ntapi.ntstatus,
  DelphiUtils.AutoObject, NtUtils.Objects;

type
  // Auto-releasable memory in a remote process
  TRemoteAutoMemory = class(TCustomAutoMemory, IMemory)
  private
    FxProcess: IHandle;
  public
    constructor Capture(hxProcess: IHandle; Region: TMemory);
    procedure Release; override;
  end;

{ TRemoteAutoMemory<P> }

constructor TRemoteAutoMemory.Capture;
begin
  inherited Capture(Region.Address, Region.Size);
  FxProcess := hxProcess;
end;

procedure TRemoteAutoMemory.Release;
begin
  if Assigned(FxProcess) then
    NtxFreeMemoryProcess(FxProcess.Handle, FAddress, FSize);
  inherited;
end;

{ Functions }

{$IFDEF Win64}
function NtxAssertWoW64Accessible;
begin
  if UInt64(Memory.Address) + Memory.Size < High(Cardinal) then
    Result.Status := STATUS_SUCCESS
  else
  begin
    Result.Location := 'NtxAssertWoW64Accessible';
    Result.Status := STATUS_NO_MEMORY;
  end;
end;
{$ENDIF}

function NtxAllocateMemoryProcess;
var
  Region: TMemory;
begin
  Region.Address := nil;
  Region.Size := Size;

  Result.Location := 'NtAllocateVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtAllocateVirtualMemory(hxProcess.Handle, Region.Address, 0,
    Region.Size, MEM_COMMIT, Protection);

{$IFDEF Win64}
  if EnsureWoW64Accessible and Result.IsSuccess then
    Result := NtxAssertWoW64Accessible(Region);
{$ENDIF}

  if Result.IsSuccess then
    xMemory := TRemoteAutoMemory.Capture(hxProcess, Region);
end;

function NtxFreeMemoryProcess;
var
  Memory: TMemory;
begin
  Memory.Address := Address;
  Memory.Size := Size;

  Result.Location := 'NtFreeVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtFreeVirtualMemory(hProcess, Memory.Address, Memory.Size,
    MEM_RELEASE);
end;

function NtxProtectMemoryProcess;
var
  OldProtected: TMemoryProtection;
begin
  Result.Location := 'NtProtectVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtProtectVirtualMemory(hProcess, Address, Size, Protection,
    OldProtected);

  if Result.IsSuccess and Assigned(pOldProtected) then
    pOldProtected^ := OldProtected;
end;

function NtxReadMemoryProcess;
begin
  Result.Location := 'NtReadVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_READ);

  Result.Status := NtReadVirtualMemory(hProcess, Address, Buffer.Address,
    Buffer.Size, nil);
end;

function NtxWriteMemoryProcess;
begin
  Result.Location := 'NtWriteVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_WRITE);

  Result.Status := NtWriteVirtualMemory(hProcess, Address, Buffer.Address,
    Buffer.Size, nil);
end;

function NtxFlushInstructionCache;
begin
  Result.Location := 'NtxFlushInstructionCacheProcess';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_WRITE);

  Result.Status := NtFlushInstructionCache(hProcess, Address, Size);
end;

function NtxLockVirtualMemory;
begin
  Result.Location := 'NtLockVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  if MapType = MAP_SYSTEM then
    Result.LastCall.ExpectedPrivilege := SE_LOCK_MEMORY_PRIVILEGE;

  Result.Status := NtLockVirtualMemory(hProcess, Memory.Address, Memory.Size,
    MapType);
end;

function NtxUnlockVirtualMemory;
begin
  Result.Location := 'NtUnlockVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  if MapType = MAP_SYSTEM then
    Result.LastCall.ExpectedPrivilege := SE_LOCK_MEMORY_PRIVILEGE;

  Result.Status := NtUnlockVirtualMemory(hProcess, Memory.Address, Memory.Size,
    MapType);
end;

{ Extension }

function NtxAllocWriteMemoryProcess;
begin
  // Allocate writable memory
  Result := NtxAllocateMemoryProcess(hxProcess, Buffer.Size, xMemory,
    EnsureWoW64Accessible);

  // Write data
  if Result.IsSuccess then
    Result := NtxWriteMemoryProcess(hxProcess.Handle, xMemory.Data, Buffer);

  if not Result.IsSuccess then
    xMemory := nil;
end;

function NtxAllocWriteExecMemoryProcess;
begin
  // Allocate and write RW memory
  Result := NtxAllocWriteMemoryProcess(hxProcess, Buffer, xMemory,
    EnsureWoW64Accessible);

  // Make it executable
  if Result.IsSuccess then
    Result := NtxProtectMemoryProcess(hxProcess.Handle, xMemory.Data,
      xMemory.Size, PAGE_EXECUTE_READ);

  // Always flush instruction cache when changing executable memory
  if Result.IsSuccess then
    Result := NtxFlushInstructionCache(hxProcess.Handle, xMemory.Data,
      xMemory.Size);

  if not Result.IsSuccess then
    xMemory := nil;
end;

{ Information }

function NtxQueryMemory;
var
  Required: NativeUInt;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryVirtualMemory(hProcess, Address, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxQueryFileNameMemory;
var
  xMemory: IMemory<PNtUnicodeString>;
begin
  Result := NtxQueryMemory(hProcess, Address, MemoryMappedFilenameInformation,
    IMemory(xMemory));

  if Result.IsSuccess then
    Filename := xMemory.Data.ToString;
end;

function GrowWorkingSet(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  Result := SizeOf(TMemoryWorkingSetInformation) + SizeOf(NativeUInt)*
    PMemoryWorkingSetInformation(Memory.Data).NumberOfEntries;
  Inc(Result, Result shr 4); // + 6%;
end;

function NtxEnumerateMemory;
var
  xMemory: IMemory<PMemoryWorkingSetInformation>;
  Info: NativeUInt;
  i: Integer;
begin
  Result := NtxQueryMemory(hProcess, nil, MemoryWorkingSetInformation,
    IMemory(xMemory), SizeOf(TMemoryWorkingSetInformation), GrowWorkingSet);

  if not Result.IsSuccess then
    Exit;

  SetLength(WorkingSet, xMemory.Data.NumberOfEntries);

  for i := 0 to High(WorkingSet) do
  begin
    Info := xMemory.Data.WorkingSetInfo{$R-}[i]{$R+};

    // Extract information from a bit union
    WorkingSet[i].Protection := Info and $1F;         // Bits 0..4
    WorkingSet[i].ShareCount := (Info and $E0) shr 5; // Bits 5..7
    WorkingSet[i].Shared := (Info and $100) <> 0;     // Bit 8
    WorkingSet[i].Node := (Info and $E00) shr 9;      // Bits 9..11
    WorkingSet[i].VirtualAddress := Pointer(Info and not NativeUInt($FFF));
  end;
end;

{ NtxMemory }

class function NtxMemory.Query<T>;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION);

  Result.Status := NtQueryVirtualMemory(hProcess, Address, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

class function NtxMemory.Read<T>;
begin
  Result := NtxReadMemoryProcess(hProcess, Address, TMemory.Reference(Buffer));
end;

class function NtxMemory.Write<T>;
begin
  Result := NtxWriteMemoryProcess(hProcess, Address, TMemory.Reference(Buffer));
end;

class function NtxMemory.AllocWrite<T>;
begin
  Result := NtxAllocWriteMemoryProcess(hxProcess, TMemory.Reference(Buffer),
    xMemory, EnsureWoW64Accessible);
end;

class function NtxMemory.AllocWriteExec<T>;
begin
  Result := NtxAllocWriteExecMemoryProcess(hxProcess, TMemory.Reference(Buffer),
    xMemory, EnsureWoW64Accessible);
end;

end.
