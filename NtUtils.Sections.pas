unit NtUtils.Sections;

{
  The module provides a set of operations with sections including support for
  mapping files and known DLLs.
}

interface

uses
  Winapi.WinNt, Ntapi.ntmmapi, NtUtils, NtUtils.Objects, DelphiUtils.AutoObject;

// Create a section
function NtxCreateSection(
  out hxSection: IHandle;
  hFile: THandle;
  MaximumSize: UInt64;
  PageProtection: TMemoryProtection;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open a section
function NtxOpenSection(
  out hxSection: IHandle;
  DesiredAccess: TSectionAccessMask;
  ObjectName: String;
  ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Map a section
function NtxMapViewOfSection(
  hSection: THandle;
  hProcess: THandle;
  var Memory: TMemory;
  Protection: TMemoryProtection;
  SectionOffset: UInt64 = 0
) : TNtxStatus;

// Unmap a section
function NtxUnmapViewOfSection(
  hProcess: THandle;
  Address: Pointer
): TNtxStatus;

type
  NtxSection = class abstract
    // Query fixed-size information
    class function Query<T>(
      hSection: THandle;
      InfoClass: TSectionInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Map a section locally
function NtxMapViewOfSectionLocal(
  hSection: THandle;
  out MappedMemory: IMemory;
  Protection: TMemoryProtection
): TNtxStatus;

// Map an image as a file using a read-only section
function RtlxMapReadonlyFile(
  out hxSection: IHandle;
  FileName: String;
  out MappedMemory: IMemory
): TNtxStatus;

// Map a known dll as an image
function RtlxMapKnownDll(
  out hxSection: IHandle;
  DllName: String;
  WoW64: Boolean;
  out MappedMemory: IMemory
): TNtxStatus;

// Map a system dll (tries known dlls first, than falls back to reading a file)
function RtlxMapSystemDll(
  out hxSection: IHandle;
  DllName: String;
  WoW64: Boolean;
  out MappedMemory: IMemory;
  out MappedAsImage: Boolean
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntpsapi, Ntapi.ntexapi, NtUtils.Files;

type
  TLocalAutoSection = class(TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

function NtxCreateSection;
var
  hSection: THandle;
  pSize: PUInt64;
begin
  if MaximumSize <> 0 then
    pSize := @MaximumSize
  else
    pSize := nil;

  Result.Location := 'NtCreateSection';
  Result.LastCall.Expects(ExpectedSectionFileAccess(PageProtection));

  Result.Status := NtCreateSection(hSection, SECTION_ALL_ACCESS,
    AttributesRefOrNil(ObjectAttributes), pSize, PageProtection,
    AllocationAttributes, hFile);

  if Result.IsSuccess then
    hxSection := TAutoHandle.Capture(hSection);
end;

function NtxOpenSection;
var
  hSection: THandle;
begin
  Result.Location := 'NtOpenSection';
  Result.LastCall.AttachAccess(DesiredAccess);

  Result.Status := NtOpenSection(hSection, DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^);

  if Result.IsSuccess then
    hxSection := TAutoHandle.Capture(hSection);
end;

function NtxMapViewOfSection;
begin
  Result.Location := 'NtMapViewOfSection';
  Result.LastCall.Expects(ExpectedSectionMapAccess(Protection));
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtMapViewOfSection(hSection, hProcess, Memory.Address, 0, 0,
    @SectionOffset, Memory.Size, ViewUnmap, 0, Protection);
end;

function NtxUnmapViewOfSection;
begin
  Result.Location := 'NtUnmapViewOfSection';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);
  Result.Status := NtUnmapViewOfSection(hProcess, Address);
end;

class function NtxSection.Query<T>;
begin
  Result.Location := 'NtQuerySection';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TSectionAccessMask>(SECTION_QUERY);

  Result.Status := NtQuerySection(hSection, InfoClass, @Buffer, SizeOf(Buffer),
    nil);
end;

procedure TLocalAutoSection.Release;
begin
  NtxUnmapViewOfSection(NtCurrentProcess, FAddress);
  inherited;
end;

function NtxMapViewOfSectionLocal;
var
  Memory: TMemory;
begin
  Memory.Address := nil;
  Memory.Size := 0;

  Result := NtxMapViewOfSection(hSection, NtCurrentProcess, Memory, Protection);

  if Result.IsSuccess then
    MappedMemory := TLocalAutoSection.Capture(Memory.Address, Memory.Size);
end;

function RtlxMapReadonlyFile;
var
  hxFile: IHandle;
begin
  // Open the file
  Result := NtxOpenFile(hxFile, FILE_READ_DATA, FileName);

  if not Result.IsSuccess then
    Exit;

  // Create a section, baked by this file
  Result := NtxCreateSection(hxSection, hxFile.Handle, 0, PAGE_READONLY);

  if not Result.IsSuccess then
    Exit;

  // Map the section
  Result := NtxMapViewOfSectionLocal(hxSection.Handle, MappedMemory,
    PAGE_READONLY);
end;

function RtlxMapKnownDll;
begin
  if Wow64 then
    DllName := '\KnownDlls32\' + DllName
  else
    DllName := '\KnownDlls\' + DllName;

  // Open a known-dll section
  Result := NtxOpenSection(hxSection, SECTION_MAP_READ or SECTION_QUERY,
    DllName);

  if not Result.IsSuccess then
    Exit;

  // Map it
  Result := NtxMapViewOfSectionLocal(hxSection.Handle, MappedMemory,
    PAGE_READONLY);
end;

function RtlxMapSystemDll;
begin
  // Try known dlls first
  Result := RtlxMapKnownDll(hxSection, DllName, WoW64, MappedMemory);

  if Result.IsSuccess then
    MappedAsImage := True
  else
  begin
    // There is no such known dll, read the file from the disk
    MappedAsImage := False;

    if WoW64 then
      DllName := USER_SHARED_DATA.NtSystemRoot + '\SysWoW64\' + DllName
    else
      DllName := USER_SHARED_DATA.NtSystemRoot + '\System32\' + DllName;

    // Convert the path to NT format
    Result := RtlxDosPathToNtPathVar(DllName);

    // Map the file
    if Result.IsSuccess then
      Result := RtlxMapReadonlyFile(hxSection, DllName, MappedMemory);
  end;
end;

end.
