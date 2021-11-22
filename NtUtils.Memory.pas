unit NtUtils.Memory;

{
  This module includes function for process memory management.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntmmapi, Ntapi.ntseapi, Ntapi.Versions, NtUtils;

type
  {$SCOPEDENUMS ON}
  TWSBlockFlags = set of (
    Valid,
    Bad,
    Locked,
    LargePage,
    Shared,
    SharedOriginal
  );
  {$SCOPEDENUMS OFF}

  TWorkingSetBlockEx = record
    VirtualAddress: Pointer;
    Flags: TWSBlockFlags;
    Protection: TMemoryProtection;
    ShareCount: Cardinal;
    Priority: Cardinal;
    Node: Cardinal;
    [MinOSVersion(OsWin1019H1)] Win32GraphicsProtection: TMemoryProtection;
  end;

{$IFDEF Win64}
// Make sure the memory region is accessible from a WoW64 process
function NtxAssertWoW64Accessible(const Memory: TMemory): TNtxStatus;
{$ENDIF}

// Allocate memory in a process
function NtxAllocateMemory(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  Size: NativeUInt;
  out xMemory: IMemory;
  EnsureWoW64Accessible: Boolean = False;
  Protection: TMemoryProtection = PAGE_READWRITE;
  Address: Pointer = nil
): TNtxStatus;

// Manually free memory in a process
function NtxFreeMemory(
  [Access(PROCESS_VM_OPERATION)] hProcess: THandle;
  [in] Address: Pointer;
  Size: NativeUInt
): TNtxStatus;

// Change memory protection
function NtxProtectMemory(
  [Access(PROCESS_VM_OPERATION)] hProcess: THandle;
  [in] Address: Pointer;
  Size: NativeUInt;
  Protection: TMemoryProtection;
  [out, opt] PreviousProtection: PMemoryProtection = nil
): TNtxStatus;

// Change memory protection and automatically undo it later
function NtxProtectMemoryAuto(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  [in] Address: Pointer;
  Size: NativeUInt;
  Protection: TMemoryProtection;
  out Reverter: IAutoReleasable
): TNtxStatus;

// Read memory
function NtxReadMemory(
  [Access(PROCESS_VM_READ)] hProcess: THandle;
  [in] Address: Pointer;
  const TargetBuffer: TMemory
): TNtxStatus;

// Read memory to a dynamic buffer
function NtxReadMemoryAuto(
  [Access(PROCESS_VM_READ)] hProcess: THandle;
  [in] Address: Pointer;
  Size: NativeUInt;
  out Buffer: IMemory
): TNtxStatus;

// Write memory
function NtxWriteMemory(
  [Access(PROCESS_VM_WRITE)] hProcess: THandle;
  [in] Address: Pointer;
  const SourceBuffer: TMemory
): TNtxStatus;

// Flush instruction cache
function NtxFlushInstructionCache(
  [Access(PROCESS_VM_WRITE)] hProcess: THandle;
  [in] Address: Pointer;
  Size: NativeUInt
): TNtxStatus;

// Lock memory pages in working set or physical memory
[RequiredPrivilege(SE_LOCK_MEMORY_PRIVILEGE, rpWithExceptions)]
function NtxLockMemory(
  [Access(PROCESS_VM_OPERATION)] hProcess: THandle;
  var Memory: TMemory;
  MapType: TMapLockType = MAP_PROCESS
): TNtxStatus;

// Unlock locked memory pages
[RequiredPrivilege(SE_LOCK_MEMORY_PRIVILEGE, rpWithExceptions)]
function NtxUnlockMemory(
  [Access(PROCESS_VM_OPERATION)]  hProcess: THandle;
  var Memory: TMemory;
  MapType: TMapLockType = MAP_PROCESS
): TNtxStatus;

{ ------------------------------- Information ------------------------------- }

// Query variable-size memory information
function NtxQueryMemory(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  [in] Address: Pointer;
  InfoClass: TMemoryInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query mapped filename
function NtxQueryFileNameMemory(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  [in] Address: Pointer;
  out Filename: String
): TNtxStatus;

// Query information about an address
function NtxQueryWorkingSetEx(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  [in, opt] Address: Pointer;
  out Attributes: TWorkingSetBlockEx
): TNtxStatus;

// Query information about multiple addresses
function NtxQueryWorkingSetExMany(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  const Addresses: TArray<Pointer>;
  out Attributes: TArray<TWorkingSetBlockEx>
): TNtxStatus;

// Iterate over process's memory regions in a loop
// Usage: while NtxIterateMemory(/.../).Save(Result) do /.../
function NtxIterateMemory(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  var CurrentAddress: Pointer;
  out Info: TMemoryBasicInformation
): TNtxStatus;

// Enumerate all process's memory regions
function NtxEnumerateMemory(
  [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
  out Memory: TArray<TMemoryBasicInformation>
): TNtxStatus;

{ ----------------------------- Generic wrapper ----------------------------- }

type
  NtxMemory = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(PROCESS_QUERY_INFORMATION)] hProcess: THandle;
      [in] Address: Pointer;
      InfoClass: TMemoryInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Read a fixed-size structure
    class function Read<T>(
      [Access(PROCESS_VM_READ)] hProcess: THandle;
      [in] Address: Pointer;
      out Buffer: T
    ): TNtxStatus; static;

    // Write a fixed-size structure
    class function Write<T>(
      [Access(PROCESS_VM_WRITE)] hProcess: THandle;
      [in] Address: Pointer;
      const Buffer: T
    ): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntdef, Ntapi.ntstatus, DelphiUtils.AutoObjects,
  NtUtils.Objects;

type
  // Auto-releasable memory in a remote process
  TRemoteAutoMemory = class(TCustomAutoMemory, IMemory)
    FxProcess: IHandle;
    constructor Capture(const hxProcess: IHandle; const Region: TMemory);
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
    NtxFreeMemory(FxProcess.Handle, FData, FSize);

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

function NtxAllocateMemory;
var
  Region: TMemory;
begin
  Region := TMemory.From(Address, Size);

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

function NtxFreeMemory;
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

type
  TAutoProtectMemory = class (TCustomAutoMemory, IAutoReleasable)
    FProcess: IHandle;
    FProtection: TMemoryProtection;
    constructor Create(
      hxProcess: IHandle;
      Address: Pointer;
      Size: NativeUInt;
      Protection: TMemoryProtection
    );
    procedure Release; override;
  end;

constructor TAutoProtectMemory.Create;
begin
  inherited Capture(Address, Size);
  FProcess := hxProcess;
  FProtection := Protection;
end;

function NtxProtectMemory;
var
  OldProtection: TMemoryProtection;
begin
  Result.Location := 'NtProtectVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtProtectVirtualMemory(hProcess, Address, Size,
    Protection, OldProtection);

  if Result.IsSuccess and Assigned(PreviousProtection) then
    PreviousProtection^ := OldProtection;
end;

function NtxProtectMemoryAuto;
var
  PreviousProtection: TMemoryProtection;
begin
  Result := NtxProtectMemory(hxProcess.Handle, Address, Size, Protection,
    @PreviousProtection);

  if Result.IsSuccess and (Protection <> PreviousProtection) then
    Reverter := TAutoProtectMemory.Create(hxProcess, Address, Size,
      PreviousProtection);
end;

procedure TAutoProtectMemory.Release;
var
  Dummy: TMemoryProtection;
begin
  NtProtectVirtualMemory(FProcess.Handle, FData, FSize, FProtection, Dummy);
  inherited;
end;

function NtxReadMemory;
begin
  Result.Location := 'NtReadVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_READ);

  Result.Status := NtReadVirtualMemory(hProcess, Address, TargetBuffer.Address,
    TargetBuffer.Size, nil);
end;

function NtxReadMemoryAuto;
begin
  Buffer := Auto.AllocateDynamic(Size);
  Result := NtxReadMemory(hProcess, Address, Buffer.Region);

  if not Result.IsSuccess then
    Buffer := nil;
end;

function NtxWriteMemory;
begin
  Result.Location := 'NtWriteVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_WRITE);

  Result.Status := NtWriteVirtualMemory(hProcess, Address, SourceBuffer.Address,
    SourceBuffer.Size, nil);
end;

function NtxFlushInstructionCache;
begin
  Result.Location := 'NtFlushInstructionCache';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_WRITE);

  Result.Status := NtFlushInstructionCache(hProcess, Address, Size);
end;

function NtxLockMemory;
begin
  Result.Location := 'NtLockVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  if MapType = MAP_SYSTEM then
    Result.LastCall.ExpectedPrivilege := SE_LOCK_MEMORY_PRIVILEGE;

  Result.Status := NtLockVirtualMemory(hProcess, Memory.Address, Memory.Size,
    MapType);
end;

function NtxUnlockMemory;
begin
  Result.Location := 'NtUnlockVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  if MapType = MAP_SYSTEM then
    Result.LastCall.ExpectedPrivilege := SE_LOCK_MEMORY_PRIVILEGE;

  Result.Status := NtUnlockVirtualMemory(hProcess, Memory.Address, Memory.Size,
    MapType);
end;

{ Information }

function NtxQueryMemory;
var
  Required: NativeUInt;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryVirtualMemory(hProcess, Address, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxQueryFileNameMemory(
  hProcess: THandle;
  [in] Address: Pointer;
  out Filename: String
): TNtxStatus;
var
  xMemory: INtUnicodeString;
begin
  Result := NtxQueryMemory(hProcess, Address, MemoryMappedFilenameInformation,
    IMemory(xMemory));

  if Result.IsSuccess then
    Filename := xMemory.Data.ToString;
end;

function GrowWorkingSet(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := SizeOf(TMemoryWorkingSetInformation) + SizeOf(NativeUInt)*
    PMemoryWorkingSetInformation(Memory.Data).NumberOfEntries;
  Inc(Result, Result shr 4); // + 6%;
end;

function NtxQueryWorkingSetEx;
var
  BulkAttributes: TArray<TWorkingSetBlockEx>;
begin
  Result := NtxQueryWorkingSetExMany(hProcess, [Address], BulkAttributes);

  if Result.IsSuccess then
    Attributes := BulkAttributes[0];
end;

function NtxQueryWorkingSetExMany;
var
  i: Integer;
  Blocks: TArray<TMemoryWorkingSetExInformation>;
begin
  SetLength(Blocks, Length(Addresses));

  for i := 0 to High(Blocks) do
    Blocks[i].VirtualAddress := Addresses[i];

  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.UsesInfoClass(MemoryWorkingSetExInformation, icQuery);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION);

  Result.Status := NtQueryVirtualMemory(hProcess, nil,
    MemoryWorkingSetExInformation, Blocks, Length(Blocks) *
    SizeOf(TMemoryWorkingSetExInformation), nil);

  if not Result.IsSuccess then
    Exit;

  SetLength(Attributes, Length(Blocks));

  for i := 0 to High(Attributes) do
    with Attributes[i] do
    begin
      VirtualAddress := Blocks[i].VirtualAddress;
      Flags := [];

      // bit 0
      if BitTest(Blocks[i].VirtualAttributes and $1) then
        Include(Flags, Valid);

      // bits 1..3
      ShareCount := (Blocks[i].VirtualAttributes and $E) shr 1;

      // bits 4..14
      Protection := (Blocks[i].VirtualAttributes and $7FF0) shr 4;

      // bit 15
      if BitTest(Blocks[i].VirtualAttributes and $8000) then
        Include(Flags, Shared);

      // bits 16..21
      Node := (Blocks[i].VirtualAttributes and $3F0000) shr 16;

      // bit 22
      if BitTest(Blocks[i].VirtualAttributes and $400000) then
        Include(Flags, Locked);

      // bit 23
      if BitTest(Blocks[i].VirtualAttributes and $800000) then
        Include(Flags, LargePage);

      // bits 24..26
      Priority := (Blocks[i].VirtualAttributes and $7000000) shr 24;

      // bits 27..29 are reserved

      // bit 30
      if BitTest(Blocks[i].VirtualAttributes and $40000000) then
        Include(Flags, SharedOriginal);

      // bit 31
      if BitTest(Blocks[i].VirtualAttributes and $80000000) then
        Include(Flags, Bad);

    {$IFDEF Win64}
      // bits 32..35
      Priority := (Blocks[i].VirtualAttributes and $F00000000) shr 32;
    {$ELSE}
      Win32GraphicsProtection := 0;
    {$ENDIF}
    end;
end;

function NtxIterateMemory;
begin
  Result := NtxMemory.Query(hProcess, CurrentAddress, MemoryBasicInformation,
    Info);

  // Getting into kernel range results in "invalid parameter"
  if Result.Status = STATUS_INVALID_PARAMETER then
    Result.Status := STATUS_NO_MORE_ENTRIES;

  if Result.IsSuccess then
    CurrentAddress := PByte(Info.BaseAddress) + Info.RegionSize;
end;

function NtxEnumerateMemory;
var
  Address: Pointer;
  Block: TMemoryBasicInformation;
begin
  Address := nil;
  Memory := nil;

  while NtxIterateMemory(hProcess, Address, Block).Save(Result) do
  begin
    SetLength(Memory, Length(Memory) + 1);
    Memory[High(Memory)] := Block;
  end;
end;

{ NtxMemory }

class function NtxMemory.Query<T>;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION);

  Result.Status := NtQueryVirtualMemory(hProcess, Address, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

class function NtxMemory.Read<T>;
begin
  Result := NtxReadMemory(hProcess, Address, TMemory.Reference(Buffer));
end;

class function NtxMemory.Write<T>;
begin
  Result := NtxWriteMemory(hProcess, Address, TMemory.Reference(Buffer));
end;

end.
