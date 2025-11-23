unit DelphiUtils.RangeChecks;

{
  This module introduces helper functions for performing strict range checks
  during parsing.
}

interface

uses
  NtUtils;

// Checks if a region doesn not overflow
function ValidRegion(
  const Region: TMemory
): Boolean;

// Check if an address belongs to a memory region (or its end)
function CheckAddress(
  const Region: TMemory;
  [in] Address: Pointer
): Boolean;

// Check if a range of addresses belongs to a memory region
function CheckRange(
  const Region: TMemory;
  [in] BlockStart: Pointer;
  [in] BlockEnd: Pointer
): Boolean;

// Check if a structure allocated at an address belongs to a memory region
function CheckStruct(
  const Region: TMemory;
  [in] BlockStart: Pointer;
  const BlockSize: UInt64
): Boolean;

// Check if an offset belongs to the memory region or its end
function CheckOffset(
  RegionSize: NativeUInt;
  const Offset: UInt64
): Boolean;

// Check if a structure allocated at an offset fits into a memory region
function CheckOffsetStruct(
  const Region: TMemory;
  const BlockOffset: UInt64;
  const BlockSize: UInt64
): Boolean;

// Check if an array of elements fits into a buffer
function CheckArraySize(
  RangeSize: NativeUInt;
  const ElementSize: UInt64;
  const ElementCount: UInt64
): Boolean;

// Check if an array allocated at an address belongs to a memory region
function CheckArray(
  const Region: TMemory;
  [in] ArrayStart: Pointer;
  const ElementSize: UInt64;
  const ElementCount: UInt64
): Boolean;

// Check if an array allocated at an offset fits into a memory region
function CheckOffsetArray(
  const Region: TMemory;
  const ArrayOffset: UInt64;
  const ElementSize: UInt64;
  const ElementCount: UInt64
): Boolean;

// Select a an intersection of a memory region and a range of addresses
function IntersectRange(
  const Region: TMemory;
  [in] BlockStart: Pointer;
  [in] BlockEnd: Pointer
): TMemory;

// Select a an intersection of a memory region and a structure at address
function IntersectStruct(
  const Region: TMemory;
  [in] BlockStart: Pointer;
  const BlockSize: UInt64
): TMemory;

// Select a an intersection of a memory region and a structure at offset
function IntersectOffsetStruct(
  const Region: TMemory;
  const BlockOffset: UInt64;
  const BlockSize: UInt64
): TMemory;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function ValidRegion;
begin
  Result := UIntPtr(Region.Address) <= UIntPtr(Region.Offset(Region.Size));
end;

function CheckAddress;
begin
  // Automatically verifies the region
  Result := (UIntPtr(Address) >= UIntPtr(Region.Address)) and
    ((UIntPtr(Address) <= UIntPtr(Region.Offset(Region.Size))));
end;

function CheckRange;
begin
  Result := (UIntPtr(BlockEnd) >= UIntPtr(BlockStart)) and
    CheckAddress(Region, BlockStart) and CheckAddress(Region, BlockEnd);
end;

function CheckStruct;
begin
  Result := CheckAddress(Region, BlockStart) and (BlockSize <= Region.Size) and
    CheckAddress(Region, PByte(BlockStart) + BlockSize);
end;

function CheckOffset;
begin
  Result := Offset <= RegionSize;
end;

function CheckOffsetStruct;
begin
  {$Q-}
  Result := ValidRegion(Region) and (BlockSize <= Region.Size) and
    (BlockOffset <= Region.Size) and (Region.Size - BlockOffset >= BlockSize);
  {$IFDEF Q+}{$Q+}{$ENDIF}
end;

function CheckArraySize;
begin
  Result := (ElementSize = 0) or ((RangeSize div ElementSize) >= ElementCount);
end;

function CheckArray;
begin
  {$Q-}
  Result := CheckAddress(Region, ArrayStart) and CheckArraySize(
    UIntPtr(Region.Offset(Region.Size)) - UIntPtr(ArrayStart), ElementSize,
    ElementCount);
  {$IFDEF Q+}{$Q+}{$ENDIF}
end;

function CheckOffsetArray;
begin
  {$Q-}
  Result := ValidRegion(Region) and (ArrayOffset <= Region.Size) and
    CheckArraySize(Region.Size - ArrayOffset, ElementSize, ElementCount);
  {$IFDEF Q+}{$Q+}{$ENDIF}
end;

function IntersectRange;
var
  ResultEnd: PByte;
begin
  if not ValidRegion(Region) or (PByte(BlockStart) > PByte(BlockEnd)) then
    Exit(Default(TMemory));

  // Select the biggest start
  if PByte(Region.Address) < PByte(BlockStart) then
    Result.Address := BlockStart
  else
    Result.Address := Region.Address;

  if PByte(BlockEnd) < PByte(Region.Offset(Region.Size)) then
    ResultEnd := BlockEnd
  else
    ResultEnd := Region.Offset(Region.Size);

  if ResultEnd > PByte(Result.Address) then
    Result.Size := UIntPtr(ResultEnd - PByte(Result.Address))
  else
    Result.Size := 0;
 end;

function IntersectStruct;
begin
  if BlockSize < UIntPtr(PByte(UIntPtr(-1)) - UIntPtr(BlockStart)) then
    Result := IntersectRange(Region, BlockStart, PByte(BlockStart) + BlockSize)
  else
    Result := Default(TMemory);
end;

function IntersectOffsetStruct;
begin
   if BlockOffset < Region.Size then
    Result := IntersectStruct(Region, Region.Offset(UIntPtr(BlockOffset)),
      BlockSize)
   else
     Result := Default(TMemory);
end;

end.
