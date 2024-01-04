unit NtUtils.Sections;

{
  The module provides a set of operations with sections including support for
  mapping files and known DLLs.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntmmapi, Ntapi.ntseapi, Ntapi.ntioapi, Ntapi.Versions,
  NtUtils, NtUtils.Objects, NtUtils.Files, DelphiUtils.AutoObjects;

const
  // Forward commonly used constants
  PAGE_READONLY = Ntapi.ntmmapi.PAGE_READONLY;
  PAGE_READWRITE = Ntapi.ntmmapi.PAGE_READWRITE;
  SEC_COMMIT = Ntapi.ntmmapi.SEC_COMMIT;
  SEC_IMAGE = Ntapi.ntmmapi.SEC_IMAGE;

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
  PageProtection: TMemoryProtection;
  AllocationAttributes: TAllocationAttributes;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  [opt] const MaximumSize: UInt64 = 0
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
  PageProtection: TMemoryProtection;
  [opt, Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle = nil;
  [in, opt] Address: Pointer = nil;
  [opt] SectionOffset: UInt64 = 0;
  [opt] ViewSize: NativeUInt = 0;
  [opt] ZeroBits: NativeUInt = 0;
  AllocationType: TAllocationType = 0;
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

// Query the entrypoint RVA of an image section
[MinOSVersion(OsWin10RS2)]
function RtlxQueryEntrypointRvaSection(
  [Access(SECTION_QUERY)] hSection: THandle;
  out EntryPointRva: Cardinal
): TNtxStatus;

{ Helper functions }

// Create a section from a file
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function RtlxCreateFileSection(
  out hxSection: IHandle;
  const FileParameters: IFileParameters;
  PageProtection: TMemoryProtection;
  AllocationAttributes: TAllocationAttributes;
  const SectionObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Map it into into the memory
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function RtlxMapFile(
  out MappedMemory: IMemory;
  [Access(FILE_MAP_SECTION)] hFile: THandle;
  PageProtection: TMemoryProtection;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT;
  [opt, Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle = nil
): TNtxStatus;

// Open a file and map it into into the memory
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function RtlxMapFileByName(
  out MappedMemory: IMemory;
  const FileParameters: IFileParameters;
  PageProtection: TMemoryProtection;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT;
  [opt, Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle = nil
): TNtxStatus;

// Map a known DLL
function RtlxMapKnownDll(
  out MappedMemory: IMemory;
  DllName: String;
  WoW64: Boolean
): TNtxStatus;

// Create a pagefile-backed copy of a section
function RtlxDuplicateDataSection(
  hSectionIn: THandle;
  out hxSectionOut: IHandle;
  MakeExecutable: Boolean = False
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntexapi, NtUtils.Processes, NtUtils.Memory,
  NtUtils.Files.Open;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TMappedAutoSection = class(TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
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
  Result := NtxCreateSection(hxSection, MaximumSize, PageProtection,
    AllocationAttributes, ObjectAttributes, hFile);
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
  Result.LastCall.Expects(ExpectedSectionMapAccess(PageProtection));
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Result.Status := NtMapViewOfSection(hSection, HandleOrDefault(hxProcess,
    NtCurrentProcess), Address, ZeroBits, CommitSize, @SectionOffset, ViewSize,
    InheritDisposition, AllocationType, PageProtection);

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
  Result := NtxMapViewOfSection(MappedMemory, hSection, PAGE_NOACCESS);

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

function RtlxQueryEntrypointRvaSection;
var
  OriginalBase, RelocationDelta: UIntPtr;
  ImageInfo: TSectionImageInformation;
begin
  // Determine the image base before dynamic relocation
  Result := NtxSection.Query(hSection, SectionOriginalBaseInformation,
    OriginalBase);

  if not Result.IsSuccess then
    Exit;

  // Determine delta for dynamic relocation
  Result := NtxSection.Query(hSection, SectionRelocationInformation,
    RelocationDelta);

  if not Result.IsSuccess then
    Exit;

  // Determine the entrypoint address after dynamic relocation
  Result := NtxSection.Query(hSection, SectionImageInformation, ImageInfo);

  if not Result.IsSuccess then
    Exit;

  {$R-}{$Q-}
  // Compute the RVA
  EntryPointRva := Cardinal(UIntPtr(ImageInfo.TransferAddress) - OriginalBase -
    RelocationDelta);
  {$IFDEF Q+}{$Q+}{$ENDIF}{$IFDEF R+}{$R+}{$ENDIF}
end;

{ Helper functions }

function RtlxCreateFileSection;
var
  hxFile: IHandle;
begin
  Result := NtxOpenFile(hxFile, FileParameters
    .UseOptions(FileParameters.Options or FILE_NON_DIRECTORY_FILE)
    .UseAccess(FileParameters.Access or
      ExpectedSectionFileAccess(PageProtection))
    .UseSyncMode(fsAsynchronous)
  );

  if Result.IsSuccess then
    Result := NtxCreateFileSection(hxSection, hxFile.Handle, PageProtection,
      AllocationAttributes, SectionObjectAttributes);
end;

function RtlxMapFile;
var
  hxSection: IHandle;
begin
  Result := NtxCreateFileSection(hxSection, hFile, PageProtection,
    AllocationAttributes);

  if Result.IsSuccess then
    Result := NtxMapViewOfSection(MappedMemory, hxSection.Handle,
    PageProtection, hxProcess);
end;

function RtlxMapFileByName;
var
  hxSection: IHandle;
begin
  Result := RtlxCreateFileSection(hxSection, FileParameters, PageProtection,
    AllocationAttributes);

  if Result.IsSuccess then
    Result := NtxMapViewOfSection(MappedMemory, hxSection.Handle,
      PageProtection, hxProcess);
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
  Result := NtxMapViewOfSection(MappedMemory, hxSection.Handle, PAGE_READONLY);
end;

function RtlxDuplicateDataSection;
var
  InView, OutView: IMemory;
  Protection: TMemoryProtection;
begin
  // Map the input
  Result := NtxMapViewOfSection(InView, hSectionIn, PAGE_READONLY);

  if not Result.IsSuccess then
    Exit;

  if MakeExecutable then
    Protection := PAGE_EXECUTE_READWRITE
  else
    Protection := PAGE_READWRITE;

  // Create an output section of required size
  Result := NtxCreateSection(hxSectionOut, InView.Size, Protection);

  if not Result.IsSuccess then
    Exit;

  // Map the output
  Result := NtxMapViewOfSection(OutView, hxSectionOut.Handle, PAGE_READWRITE);

  if not Result.IsSuccess then
    Exit;

  // Copy data
  Move(InView.Data^, OutView.Data^, InView.Size);
end;

end.
