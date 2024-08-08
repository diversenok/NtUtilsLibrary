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

// Allocate memory in a process
function NtxAllocateMemory(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  Size: NativeUInt;
  out xMemory: IMemory;
  Protection: TMemoryProtection = PAGE_READWRITE;
  Address: Pointer = nil;
  AllocationType: TAllocationType= MEM_COMMIT
): TNtxStatus;

// Manually free memory in a process
function NtxFreeMemory(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  [in] Address: Pointer;
  Size: NativeUInt;
  FreeType: TAllocationType = MEM_FREE
): TNtxStatus;

// Change memory protection
function NtxProtectMemory(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
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
  [Access(PROCESS_VM_READ)] const hxProcess: IHandle;
  [in] Address: Pointer;
  const TargetBuffer: TMemory
): TNtxStatus;

// Read memory to a dynamic buffer
function NtxReadMemoryAuto(
  [Access(PROCESS_VM_READ)] const hxProcess: IHandle;
  [in] Address: Pointer;
  Size: NativeUInt;
  out Buffer: IMemory
): TNtxStatus;

// Write memory
function NtxWriteMemory(
  [Access(PROCESS_VM_WRITE)] const hxProcess: IHandle;
  [in] Address: Pointer;
  const SourceBuffer: TMemory
): TNtxStatus;

// Flush instruction cache
function NtxFlushInstructionCache(
  [Access(PROCESS_VM_WRITE)] const hxProcess: IHandle;
  [in] Address: Pointer;
  Size: NativeUInt
): TNtxStatus;

// Lock memory pages in working set or physical memory
[RequiredPrivilege(SE_LOCK_MEMORY_PRIVILEGE, rpWithExceptions)]
function NtxLockMemory(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  var Memory: TMemory;
  MapType: TMapLockType = MAP_PROCESS
): TNtxStatus;

// Unlock locked memory pages
[RequiredPrivilege(SE_LOCK_MEMORY_PRIVILEGE, rpWithExceptions)]
function NtxUnlockMemory(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  var Memory: TMemory;
  MapType: TMapLockType = MAP_PROCESS
): TNtxStatus;

{ ------------------------------- Information ------------------------------- }

// Query variable-size memory information
function NtxQueryMemory(
  [Access(PROCESS_QUERY_INFORMATION)] const hxProcess: IHandle;
  [in] Address: Pointer;
  InfoClass: TMemoryInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query mapped filename
function NtxQueryFileNameMemory(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] const hxProcess: IHandle;
  [in] Address: Pointer;
  out Filename: String
): TNtxStatus;

// Query information about an address
function NtxQueryWorkingSetEx(
  [Access(PROCESS_QUERY_INFORMATION)] const hxProcess: IHandle;
  [in, opt] Address: Pointer;
  out Attributes: TWorkingSetBlockEx
): TNtxStatus;

// Query information about multiple addresses
function NtxQueryWorkingSetExMany(
  [Access(PROCESS_QUERY_INFORMATION)] const hxProcess: IHandle;
  const Addresses: TArray<Pointer>;
  out Attributes: TArray<TWorkingSetBlockEx>
): TNtxStatus;

// Make a for-in iterator for enumerating process's memory regions.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function NtxIterateMemory(
  [out, opt] Status: PNtxStatus;
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] const hxProcess: IHandle;
  [in, opt] StartAddress: Pointer = nil
): IEnumerable<TMemoryBasicInformation>;

// Enumerate all process's memory regions
function NtxEnumerateMemory(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] const hxProcess: IHandle;
  out Blocks: TArray<TMemoryBasicInformation>;
  [in, opt] StartAddress: Pointer = nil  
): TNtxStatus;

{ ----------------------------- Generic wrapper ----------------------------- }

type
  NtxMemory = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(PROCESS_QUERY_LIMITED_INFORMATION)] const hxProcess: IHandle;
      [in] Address: Pointer;
      InfoClass: TMemoryInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Read a fixed-size structure
    class function Read<T>(
      [Access(PROCESS_VM_READ)] const hProcess: IHandle;
      [in] Address: Pointer;
      out Buffer: T
    ): TNtxStatus; static;

    // Write a fixed-size structure
    class function Write<T>(
      [Access(PROCESS_VM_WRITE)] const hProcess: IHandle;
      [in] Address: Pointer;
      const Buffer: T
    ): TNtxStatus; static;
  end;

{ Other }

// Open a session object
function NtxOpenSession(
  out hxSession: IHandle;
  DesiredAccess: TSessionAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open a memory partition
[MinOSVersion(OsWin10TH1)]
function NtxOpenPartition(
  out hxPartition: IHandle;
  DesiredAccess: TPartitionAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntdef, Ntapi.ntstatus, DelphiUtils.AutoObjects,
  NtUtils.Objects, NtUtils.Ldr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  // Auto-releasable memory in a remote process
  TRemoteAutoMemory = class(TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
    FProcess: IHandle;
    constructor Capture(const hxProcess: IHandle; const Region: TMemory);
    procedure Release; override;
  end;

{ TRemoteAutoMemory<P> }

constructor TRemoteAutoMemory.Capture;
begin
  inherited Capture(Region.Address, Region.Size);
  FProcess := hxProcess;
end;

procedure TRemoteAutoMemory.Release;
begin
  if Assigned(FProcess) and Assigned(FData) then
    NtxFreeMemory(FProcess, FData, FSize);

  FProcess := nil;
  FData := nil;
  inherited;
end;

{ Functions }

function NtxAllocateMemory;
var
  Region: TMemory;
begin
  Region := TMemory.From(Address, Size);

  Result.Location := 'NtAllocateVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtAllocateVirtualMemory(hxProcess.Handle, Region.Address, 0,
    Region.Size, AllocationType, Protection);

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

  Result.Status := NtFreeVirtualMemory(HandleOrDefault(hxProcess),
    Memory.Address, Memory.Size, FreeType);
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

  Result.Status := NtProtectVirtualMemory(HandleOrDefault(hxProcess), Address,
    Size, Protection, OldProtection);

  if Result.IsSuccess and Assigned(PreviousProtection) then
    PreviousProtection^ := OldProtection;
end;

function NtxProtectMemoryAuto;
var
  PreviousProtection: TMemoryProtection;
begin
  Result := NtxProtectMemory(hxProcess, Address, Size, Protection,
    @PreviousProtection);

  if Result.IsSuccess and (Protection <> PreviousProtection) then
    Reverter := TAutoProtectMemory.Create(hxProcess, Address, Size,
      PreviousProtection);
end;

procedure TAutoProtectMemory.Release;
var
  Dummy: TMemoryProtection;
begin
  if Assigned(FProcess) and Assigned(FData) then
    NtProtectVirtualMemory(FProcess.Handle, FData, FSize, FProtection, Dummy);

  FProcess := nil;
  FData := nil;
  inherited;
end;

function NtxReadMemory;
begin
  Result.Location := 'NtReadVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_READ);

  Result.Status := NtReadVirtualMemory(HandleOrDefault(hxProcess), Address,
    TargetBuffer.Address, TargetBuffer.Size, nil);
end;

function NtxReadMemoryAuto;
begin
  Buffer := Auto.AllocateDynamic(Size);
  Result := NtxReadMemory(hxProcess, Address, Buffer.Region);

  if not Result.IsSuccess then
    Buffer := nil;
end;

function NtxWriteMemory;
begin
  Result.Location := 'NtWriteVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_WRITE);

  Result.Status := NtWriteVirtualMemory(HandleOrDefault(hxProcess), Address,
    SourceBuffer.Address, SourceBuffer.Size, nil);
end;

function NtxFlushInstructionCache;
begin
  Result.Location := 'NtFlushInstructionCache';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_WRITE);

  Result.Status := NtFlushInstructionCache(HandleOrDefault(hxProcess), Address,
    Size);
end;

function NtxLockMemory;
begin
  Result.Location := 'NtLockVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  if MapType = MAP_SYSTEM then
    Result.LastCall.ExpectedPrivilege := SE_LOCK_MEMORY_PRIVILEGE;

  Result.Status := NtLockVirtualMemory(HandleOrDefault(hxProcess),
    Memory.Address, Memory.Size, MapType);
end;

function NtxUnlockMemory;
begin
  Result.Location := 'NtUnlockVirtualMemory';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  if MapType = MAP_SYSTEM then
    Result.LastCall.ExpectedPrivilege := SE_LOCK_MEMORY_PRIVILEGE;

  Result.Status := NtUnlockVirtualMemory(HandleOrDefault(hxProcess),
    Memory.Address, Memory.Size, MapType);
end;

{ Information }

function NtxQueryMemory;
var
  Required: NativeUInt;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  case InfoClass of
    MemoryWorkingSetInformation, MemoryWorkingSetExInformation:
      Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_INFORMATION);
  else
    Result.LastCall.Expects<TProcessAccessMask>(
      PROCESS_QUERY_LIMITED_INFORMATION);
  end;

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryVirtualMemory(HandleOrDefault(hxProcess), Address,
      InfoClass, xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxQueryFileNameMemory;
var
  xMemory: IMemory<PNtUnicodeString>;
begin
  Result := NtxQueryMemory(hxProcess, Address, MemoryMappedFilenameInformation,
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
  Result := NtxQueryWorkingSetExMany(hxProcess, [Address], BulkAttributes);

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

  Result.Status := NtQueryVirtualMemory(HandleOrDefault(hxProcess), nil,
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
var
  Address: Pointer;  
begin
  Address := StartAddress;

  Result := NtxAuto.Iterate<TMemoryBasicInformation>(Status,
    function (out Info: TMemoryBasicInformation): TNtxStatus
    begin
      // Retrieve information about the address block
      Result := NtxMemory.Query(hxProcess, Address,
        MemoryBasicInformation, Info);

      // Going into kernel addresses fails with "invalid parameter" and should
      // gracefully stop enumeration
      if (UIntPtr(Address) >= MM_USER_PROBE_ADDRESS) and 
        (Result.Status = STATUS_INVALID_PARAMETER) then
        Result.Status := STATUS_NO_MORE_ENTRIES;

      if not Result.IsSuccess then
        Exit;

      // Advance to the next address block
      Address := PByte(Info.BaseAddress) + Info.RegionSize;
    end
  );
end;

function NtxEnumerateMemory;
var
  Block: TMemoryBasicInformation;
begin
  Blocks := nil;

  for Block in NtxIterateMemory(@Result, hxProcess, StartAddress) do
  begin
    SetLength(Blocks, Succ(Length(Blocks)));
    Blocks[High(Blocks)] := Block;
  end;
end;

{ NtxMemory }

class function NtxMemory.Query<T>;
begin
  Result.Location := 'NtQueryVirtualMemory';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_QUERY_LIMITED_INFORMATION);

  Result.Status := NtQueryVirtualMemory(HandleOrDefault(hxProcess), Address,
    InfoClass, @Buffer, SizeOf(Buffer), nil);
end;

class function NtxMemory.Read<T>;
begin
  Result := NtxReadMemory(hProcess, Address, TMemory.Reference(Buffer));
end;

class function NtxMemory.Write<T>;
begin
  Result := NtxWriteMemory(hProcess, Address, TMemory.Reference(Buffer));
end;

function NtxOpenSession;
var
  ObjAttr: PObjectAttributes;
  hSession: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenSession';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenSession(hSession, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxSession := Auto.CaptureHandle(hSession);
end;

function NtxOpenPartition;
var
  ObjAttr: PObjectAttributes;
  hPartition: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtOpenPartition);

  if not Result.IsSuccess then
    Exit;

  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenPartition';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenPartition(hPartition, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxPartition := Auto.CaptureHandle(hPartition);
end;

end.
