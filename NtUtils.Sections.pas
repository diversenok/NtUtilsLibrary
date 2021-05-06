unit NtUtils.Sections;

{
  The module provides a set of operations with sections including support for
  mapping files and known DLLs.
}

interface

uses
  Winapi.WinNt, Ntapi.ntmmapi, NtUtils, NtUtils.Objects, DelphiUtils.AutoObject;

// Create a section object backed by a paging or a regular file
function NtxCreateSection(
  out hxSection: IHandle;
  [opt] const MaximumSize: UInt64;
  PageProtection: TMemoryProtection = PAGE_READWRITE;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  [opt] hFile: THandle = 0
): TNtxStatus;

// Open a section object by name
function NtxOpenSection(
  out hxSection: IHandle;
  DesiredAccess: TSectionAccessMask;
  const ObjectName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Map a view section into a process's address space
function NtxMapViewOfSection(
  out MappedMemory: IMemory;
  hSection: THandle;
  const hxProcess: IHandle;
  Protection: TMemoryProtection = PAGE_READWRITE;
  AllocationType: TAllocationType = 0;
  [in, opt] Address: Pointer = nil;
  [opt] SectionOffset: UInt64 = 0;
  [opt] ViewSize: NativeUInt = 0;
  [opt] ZeroBits: NativeUInt = 0;
  [opt] CommitSize: NativeUInt = 0;
  InheritDisposition: TSectionInherit = ViewShare
) : TNtxStatus;

// Unmap a view of section
function NtxUnmapViewOfSection(
  hProcess: THandle;
  [in] Address: Pointer
): TNtxStatus;

type
  NtxSection = class abstract
    // Query fixed-size information about a section
    class function Query<T>(
      hSection: THandle;
      InfoClass: TSectionInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

{ Helper functions }

// Map a file as a read-only section
function RtlxMapReadonlyFile(
  out MappedMemory: IMemory;
  const FileName: String
): TNtxStatus;

// Create an image section from an executable file
function RtlxCreateImageSection(
  out hxSection: IHandle;
  const FileName: String
): TNtxStatus;

// Map a known dll as an image
function RtlxMapKnownDll(
  out MappedMemory: IMemory;
  DllName: String;
  WoW64: Boolean
): TNtxStatus;

// Map a system dll (tries known dlls first, than falls back to reading a file)
function RtlxMapSystemDll(
  out MappedMemory: IMemory;
  out MappedAsImage: Boolean;
  DllName: String;
  WoW64: Boolean
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntpsapi, Ntapi.ntexapi, NtUtils.Files,
  NtUtils.Processes;

type
  TMappedAutoSection = class(TCustomAutoMemory, IMemory)
    FProcess: IHandle;
    procedure Release; override;
    constructor Create(
      const hxProcess: IHandle;
      Address: Pointer;
      Size: NativeUInt
    );
  end;

constructor TMappedAutoSection.Create;
begin
  inherited Capture(Address, Size);
  FProcess := hxProcess;
end;

procedure TMappedAutoSection.Release;
begin
  NtxUnmapViewOfSection(FProcess.Handle, FAddress);
  inherited;
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

  Result.Status := NtCreateSection(
    hSection,
    AccessMaskOverride(SECTION_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    pSize,
    PageProtection,
    AllocationAttributes,
    hFile
  );

  if Result.IsSuccess then
    hxSection := TAutoHandle.Capture(hSection);
end;

function NtxOpenSection;
var
  hSection: THandle;
begin
  Result.Location := 'NtOpenSection';
  Result.LastCall.AttachAccess(DesiredAccess);

  Result.Status := NtOpenSection(
    hSection,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxSection := TAutoHandle.Capture(hSection);
end;

function NtxMapViewOfSection;
begin
  Result.Location := 'NtMapViewOfSection';
  Result.LastCall.Expects(ExpectedSectionMapAccess(Protection));
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtMapViewOfSection(hSection, hxProcess.Handle, Address,
    ZeroBits, CommitSize, @SectionOffset, ViewSize, InheritDisposition,
    AllocationType, Protection);

  if Result.IsSuccess then
    MappedMemory := TMappedAutoSection.Create(hxProcess, Address, ViewSize);
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

{ Helper functions }

function RtlxMapReadonlyFile;
var
  hxFile, hxSection: IHandle;
begin
  // Open the file
  Result := NtxOpenFile(hxFile, FILE_READ_DATA, FileName);

  if not Result.IsSuccess then
    Exit;

  // Create a section backed by the file
  Result := NtxCreateSection(hxSection, 0, PAGE_READONLY, SEC_COMMIT, nil,
    hxFile.Handle);

  if not Result.IsSuccess then
    Exit;

  // Map the section
  Result := NtxMapViewOfSection(MappedMemory, hxSection.Handle,
    NtxCurrentProcess, PAGE_READONLY);
end;

function RtlxCreateImageSection;
var
  hxFile: IHandle;
begin
  // Open the file for execution
  Result := NtxOpenFile(hxFile, FILE_READ_DATA or FILE_EXECUTE, FileName);

  if not Result.IsSuccess then
    Exit;

  // Create an image section backed by the file
  Result := NtxCreateSection(hxSection, 0, PAGE_READONLY, SEC_IMAGE, nil,
    hxFile.Handle);
end;

function RtlxMapKnownDll;
var
  hxSection: IHandle;
begin
  if Wow64 then
    DllName := '\KnownDlls32\' + DllName
  else
    DllName := '\KnownDlls\' + DllName;

  // Open a known-dll section
  Result := NtxOpenSection(hxSection, SECTION_MAP_READ, DllName);

  if not Result.IsSuccess then
    Exit;

  // Map it
  Result := NtxMapViewOfSection(MappedMemory, hxSection.Handle,
    NtxCurrentProcess, PAGE_READONLY);
end;

function RtlxMapSystemDll;
begin
  // Try known dlls first
  Result := RtlxMapKnownDll(MappedMemory, DllName, WoW64);

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
      Result := RtlxMapReadonlyFile(MappedMemory, DllName);
  end;
end;

end.
