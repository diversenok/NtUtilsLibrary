unit DelphiUtils.RangeChecks;

{
  This module introduces helper functions for performing strict range checks
  during parsing.
}

interface

uses
  NtUtils;

// Check if an address belongs to a memory region
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

// Check if an offset belongs to the memory region
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

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function CheckAddress;
begin
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
  Result := (BlockSize <= Region.Size) and CheckAddress(Region, BlockStart) and
    CheckAddress(Region, PByte(BlockStart) + BlockSize);
end;

function CheckOffset;
begin
  Result := Offset <= RegionSize;
end;

function CheckOffsetStruct;
begin
  {$Q-}
  Result := (BlockSize <= Region.Size) and (BlockOffset <= Region.Size) and
    (Region.Size - BlockOffset >= BlockSize);
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
  Result := (ArrayOffset <= Region.Size) and CheckArraySize(
    Region.Size - ArrayOffset, ElementSize, ElementCount);
  {$IFDEF Q+}{$Q+}{$ENDIF}
end;

end.
