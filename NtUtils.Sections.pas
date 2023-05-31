unit NtUtils.Sections;

{
  The module provides a set of operations with sections including support for
  mapping files and known DLLs.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntmmapi, Ntapi.ntseapi, Ntapi.ntioapi, NtUtils,
  NtUtils.Objects, NtUtils.Files, DelphiUtils.AutoObjects;

// Get SEC_IMAGE_NO_EXECUTE when supported or SEC_IMAGE otherwise
function RtlxSecImageNoExecute: TAllocationAttributes;

// Create a section object backed by a paging or a regular file
function NtxCreateSection(
  out hxSection: IHandle;
  [opt] const MaximumSize: UInt64;
  PageProtection: TMemoryProtection = PAGE_READWRITE;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  [opt, Access(FILE_MAP_SECTION)] hFile: THandle = 0
): TNtxStatus;

// Create a section from a file
function NtxCreateFileSection(
  out hxSection: IHandle;
  [Access(FILE_MAP_SECTION)] hFile: THandle;
  PageProtection: TMemoryProtection = PAGE_READONLY;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT;
  [opt] const ObjectAttributes: IObjectAttributes = nil
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
  [Access(SECTION_MAP_ANY)] hSection: THandle;
  [opt, Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle = nil;
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
  [in] Address: Pointer;
  [opt, Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle = nil
): TNtxStatus;

// Determine a name of a backing file for a section
function NtxQueryFileNameSection(
  [Access(SECTION_MAP_READ)] hSection: THandle;
  out FileName: String
): TNtxStatus;

type
  NtxSection = class abstract
    // Query fixed-size information about a section
    class function Query<T>(
      [Access(SECTION_QUERY)] hSection: THandle;
      InfoClass: TSectionInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

{ Helper functions }

// Create a section from a file
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function RtlxCreateFileSection(
  out hxSection: IHandle;
  const FileParameters: IFileParameters;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT;
  Protection: TMemoryProtection = PAGE_READONLY;
  const SectionObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Map it into into the memory
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function RtlxMapFile(
  out MappedMemory: IMemory;
  [Access(FILE_MAP_SECTION)] hFile: THandle;
  Attributes: TAllocationAttributes = SEC_COMMIT;
  Protection: TMemoryProtection = PAGE_READONLY;
  [opt, Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle = nil
): TNtxStatus;

// Open a file and map it into into the memory
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function RtlxMapFileByName(
  out MappedMemory: IMemory;
  const FileParameters: IFileParameters;
  Attributes: TAllocationAttributes = SEC_COMMIT;
  Protection: TMemoryProtection = PAGE_READONLY;
  [opt, Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle = nil
): TNtxStatus;

// Map a known DLL
function RtlxMapKnownDll(
  out MappedMemory: IMemory;
  DllName: String;
  WoW64: Boolean
): TNtxStatus;

// Map a system dll (tries known dlls first, than falls back to the file)
function RtlxMapSystemDll(
  out MappedMemory: IMemory;
  DllName: String;
  WoW64: Boolean
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntexapi, Ntapi.Versions, NtUtils.Processes,
  NtUtils.Memory, NtUtils.Files.Open;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TMappedAutoSection = class(TCustomAutoMemory, IMemory)
    [opt] FProcess: IHandle;
    procedure Release; override;
    constructor Create(
      [opt] const hxProcess: IHandle;
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
  if Assigned(FData) then
    NtxUnmapViewOfSection(FData, FProcess);

  FProcess := nil;
  FData := nil;
  inherited;
end;

function RtlxSecImageNoExecute;
begin
  if RtlOsVersionAtLeast(OsWin8) then
    Result := SEC_IMAGE_NO_EXECUTE
  else
    Result := SEC_IMAGE;
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
    hxSection := Auto.CaptureHandle(hSection);
end;

function NtxCreateFileSection;
begin
  Result := NtxCreateSection(hxSection, 0, PageProtection, AllocationAttributes,
    ObjectAttributes, hFile);
end;

function NtxOpenSection;
var
  PassedAttributes: TObjectAttributesFlags;
  hSection: THandle;
begin
  Result.Location := 'NtOpenSection';
  Result.LastCall.OpensForAccess(DesiredAccess);

  if Assigned(ObjectAttributes) then
    PassedAttributes := ObjectAttributes.Attributes
  else
    PassedAttributes := 0;

  Result.Status := NtOpenSection(
    hSection,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes)
      .UseAttributes(PassedAttributes or OBJ_CASE_INSENSITIVE)
      .UseName(ObjectName).ToNative^
  );

  if Result.IsSuccess then
    hxSection := Auto.CaptureHandle(hSection);
end;

function NtxMapViewOfSection;
begin
  Result.Location := 'NtMapViewOfSection';
  Result.LastCall.Expects(ExpectedSectionMapAccess(Protection));
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtMapViewOfSection(hSection, HandleOrDefault(hxProcess,
    NtCurrentProcess), Address, ZeroBits, CommitSize, @SectionOffset, ViewSize,
    InheritDisposition, AllocationType, Protection);

  if Result.IsSuccess then
    MappedMemory := TMappedAutoSection.Create(hxProcess, Address, ViewSize);
end;

function NtxUnmapViewOfSection;
begin
  Result.Location := 'NtUnmapViewOfSection';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);
  Result.Status := NtUnmapViewOfSection(HandleOrDefault(hxProcess,
    NtCurrentProcess), Address);
end;

function NtxQueryFileNameSection;
var
  MappedMemory: IMemory;
begin
  Result := NtxMapViewOfSection(MappedMemory, hSection, NtxCurrentProcess,
    PAGE_NOACCESS);

  if Result.IsSuccess then
    Result := NtxQueryFileNameMemory(NtCurrentProcess, MappedMemory.Data,
      FileName);
end;

class function NtxSection.Query<T>;
begin
  Result.Location := 'NtQuerySection';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TSectionAccessMask>(SECTION_QUERY);

  Result.Status := NtQuerySection(hSection, InfoClass, @Buffer, SizeOf(Buffer),
    nil);
end;

{ Helper functions }

function RtlxCreateFileSection;
var
  hxFile: IHandle;
begin
  Result := NtxOpenFile(hxFile, FileParameters
    .UseOptions(FileParameters.Options or FILE_NON_DIRECTORY_FILE)
    .UseAccess(FileParameters.Access or ExpectedSectionFileAccess(Protection))
    .UseSyncMode(fsAsynchronous)
  );

  if Result.IsSuccess then
    Result := NtxCreateFileSection(hxSection, hxFile.Handle, Protection,
      AllocationAttributes, SectionObjectAttributes);
end;

function RtlxMapFile;
var
  hxSection: IHandle;
begin
  Result := NtxCreateFileSection(hxSection, hFile, Protection, Attributes);

  if Result.IsSuccess then
    Result := NtxMapViewOfSection(MappedMemory, hxSection.Handle, hxProcess,
      Protection);
end;

function RtlxMapFileByName;
var
  hxSection: IHandle;
begin
  Result := RtlxCreateFileSection(hxSection, FileParameters, Attributes,
    Protection);

  if Result.IsSuccess then
    Result := NtxMapViewOfSection(MappedMemory, hxSection.Handle,
      hxProcess, Protection);
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

  if not Result.IsSuccess then
  begin
    // There is no such known dll, read the file from the disk
    if WoW64 then
      DllName := '\SystemRoot\SysWoW64\' + DllName
    else
      DllName := '\SystemRoot\System32\' + DllName;

    // Map the file
    Result := RtlxMapFileByName(MappedMemory, FileParameters
      .UseFileName(DllName), RtlxSecImageNoExecute);
  end;
end;

end.
