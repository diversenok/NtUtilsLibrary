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

type
  // Parameter builder for section mappings
  IMappingParameters = interface
    ['{93E0C43F-3B7A-40D1-AD85-89158B242D44}']
    // Fluent builder
    function UseProtection(PageProtection: TMemoryProtection): IMappingParameters;
    function UseAllocationType(AllocationType: TAllocationType): IMappingParameters;
    function UseSectionOffset(SectionOffset: UInt64): IMappingParameters;
    function UseViewSize(ViewSize: NativeUInt): IMappingParameters;
    function UseCommitSize(CommitSize: NativeUInt): IMappingParameters;
    function UseZeroBits(ZeroBits: NativeUInt): IMappingParameters;
    function UseAddress(Address: Pointer): IMappingParameters;
    function UseInheritDisposition(InheritDisposition: TSectionInherit): IMappingParameters;

    // Accessor functions
    function GetProtection: TMemoryProtection;
    function GetAllocationType: TAllocationType;
    function GetSectionOffset: UInt64;
    function GetViewSize: NativeUInt;
    function GetCommitSize: NativeUInt;
    function GetZeroBits: NativeUInt;
    function GetAddress: Pointer;
    function GetInheritDisposition: TSectionInherit;

    // Accessors
    property Protection: TMemoryProtection read GetProtection;
    property AllocationType: TAllocationType read GetAllocationType;
    property SectionOffset: UInt64 read GetSectionOffset;
    property ViewSize: NativeUInt read GetViewSize;
    property CommitSize: NativeUInt read GetCommitSize;
    property ZeroBits: NativeUInt read GetZeroBits;
    property Address: Pointer read GetAddress;
    property InheritDisposition: TSectionInherit read GetInheritDisposition;
  end;

// Make an instance of section mapping parameter builder
function MappingParameters(
  [opt] const Template: IMappingParameters = nil
): IMappingParameters;

// Get SEC_IMAGE_NO_EXECUTE when supported or SEC_IMAGE otherwise
function RtlxSecImageNoExecute: TAllocationAttributes;

// Create a section object backed by a paging or a regular file
function NtxCreateSection(
  out hxSection: IHandle;
  [opt] const MaximumSize: UInt64;
  PageProtection: TMemoryProtection = PAGE_READWRITE;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  [opt, Access(FILE_MAP_SECTION)] const hxFile: IHandle = nil
): TNtxStatus;

// Create a section from a file
function NtxCreateFileSection(
  out hxSection: IHandle;
  [Access(FILE_MAP_SECTION)] const hxFile: IHandle;
  PageProtection: TMemoryProtection;
  AllocationAttributes: TAllocationAttributes;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  [opt] const MaximumSize: UInt64 = 0
): TNtxStatus;

// Open a section object by name
function NtxOpenSection(
  out hxSection: IHandle;
  DesiredAccess: TSectionAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Map a view section into a process's address space
function NtxMapViewOfSection(
  [Access(SECTION_MAP_ANY)] const hxSection: IHandle;
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  out MappedMemory: IMemory;
  [opt] Parameters: IMappingParameters = nil
) : TNtxStatus;

// Unmap a view of section
function NtxUnmapViewOfSection(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  [in] Address: Pointer
): TNtxStatus;

// Determine a name of a backing file for a section
function NtxQueryFileNameSection(
  [Access(SECTION_MAP_READ)] const hxSection: IHandle;
  out FileName: String
): TNtxStatus;

type
  NtxSection = class abstract
    // Query fixed-size information about a section
    class function Query<T>(
      [Access(SECTION_QUERY)] const hxSection: IHandle;
      InfoClass: TSectionInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Query the entrypoint RVA of an image section
[MinOSVersion(OsWin10RS2)]
function RtlxQueryEntrypointRvaSection(
  [Access(SECTION_QUERY)] const hxSection: IHandle;
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
  [Access(FILE_MAP_SECTION)] const hxFile: IHandle;
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  out MappedMemory: IMemory;
  [opt] Parameters: IMappingParameters = nil;
  AllocationAttributes: TAllocationType = SEC_COMMIT
): TNtxStatus;

// Open a file and map it into into the memory
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function RtlxMapFileByName(
  const FileParameters: IFileParameters;
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  out MappedMemory: IMemory;
  [opt] Parameters: IMappingParameters = nil;
  AllocationAttributes: TAllocationAttributes = SEC_COMMIT
): TNtxStatus;

// Map a known DLL
function RtlxMapKnownDll(
  out MappedMemory: IMemory;
  DllName: String;
  WoW64: Boolean
): TNtxStatus;

// Create a pagefile-backed copy of a section
function RtlxDuplicateDataSection(
  const hxSectionIn: IHandle;
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

{ Helper types }

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
    NtxUnmapViewOfSection(FProcess, FData);

  FProcess := nil;
  FData := nil;
  inherited;
end;

type
  TMappingParameters = class (TInterfacedObject, IMappingParameters)
  protected
    FProtection: TMemoryProtection;
    FAllocationType: TAllocationType;
    FSectionOffset: UInt64;
    FViewSize: NativeUInt;
    FCommitSize: NativeUInt;
    FZeroBits: NativeUInt;
    FAddress: Pointer;
    FInheritDisposition: TSectionInherit;
    function SetProtection(Value: TMemoryProtection): TMappingParameters;
    function SetAllocationType(Value: TAllocationType): TMappingParameters;
    function SetSectionOffset(Value: UInt64): TMappingParameters;
    function SetViewSize(Value: NativeUInt): TMappingParameters;
    function SetCommitSize(Value: NativeUInt): TMappingParameters;
    function SetZeroBits(Value: NativeUInt): TMappingParameters;
    function SetAddress(Value: Pointer): TMappingParameters;
    function SetInheritDisposition(Value: TSectionInherit): TMappingParameters;
    function GetProtection: TMemoryProtection;
    function GetAllocationType: TAllocationType;
    function GetSectionOffset: UInt64;
    function GetViewSize: NativeUInt;
    function GetCommitSize: NativeUInt;
    function GetZeroBits: NativeUInt;
    function GetAddress: Pointer;
    function GetInheritDisposition: TSectionInherit;
    function Duplicate: TMappingParameters;
  public
    function UseProtection(Value: TMemoryProtection): IMappingParameters;
    function UseAllocationType(Value: TAllocationType): IMappingParameters;
    function UseSectionOffset(Value: UInt64): IMappingParameters;
    function UseViewSize(Value: NativeUInt): IMappingParameters;
    function UseCommitSize(Value: NativeUInt): IMappingParameters;
    function UseZeroBits(Value: NativeUInt): IMappingParameters;
    function UseAddress(Value: Pointer): IMappingParameters;
    function UseInheritDisposition(Value: TSectionInherit): IMappingParameters;
    constructor Create;
  end;

constructor TMappingParameters.Create;
begin
  inherited;
  FProtection := PAGE_READONLY;
  FAllocationType := MEM_COMMIT;
  FInheritDisposition := ViewShare;
end;

function TMappingParameters.Duplicate;
begin
  Result := TMappingParameters.Create
    .SetProtection(GetProtection)
    .SetAllocationType(GetAllocationType)
    .SetSectionOffset(GetSectionOffset)
    .SetViewSize(GetViewSize)
    .SetCommitSize(GetCommitSize)
    .SetZeroBits(GetZeroBits)
    .SetAddress(GetAddress)
    .SetInheritDisposition(GetInheritDisposition)
  ;
end;

function TMappingParameters.GetAddress;
begin
  Result := FAddress;
end;

function TMappingParameters.GetAllocationType;
begin
  Result := FAllocationType;
end;

function TMappingParameters.GetCommitSize;
begin
  Result := FCommitSize;
end;

function TMappingParameters.GetInheritDisposition;
begin
  Result := FInheritDisposition;
end;

function TMappingParameters.GetProtection;
begin
  Result := FProtection;
end;

function TMappingParameters.GetSectionOffset;
begin
  Result := FSectionOffset;
end;

function TMappingParameters.GetViewSize;
begin
  Result := FViewSize;
end;

function TMappingParameters.GetZeroBits;
begin
  Result := FZeroBits;
end;

function TMappingParameters.SetAddress;
begin
  FAddress := Value;
  Result := Self;
end;

function TMappingParameters.SetAllocationType;
begin
  FAllocationType := Value;
  Result := Self;
end;

function TMappingParameters.SetCommitSize;
begin
  FCommitSize := Value;
  Result := Self;
end;

function TMappingParameters.SetInheritDisposition;
begin
  FInheritDisposition := Value;
  Result := Self;
end;

function TMappingParameters.SetProtection;
begin
  FProtection := Value;
  Result := Self;
end;

function TMappingParameters.SetSectionOffset;
begin
  FSectionOffset := Value;
  Result := Self;
end;

function TMappingParameters.SetViewSize;
begin
  FViewSize := Value;
  Result := Self;
end;

function TMappingParameters.SetZeroBits;
begin
  FZeroBits := Value;
  Result := Self;
end;

function TMappingParameters.UseAddress;
begin
  Result := Duplicate.SetAddress(Value);
end;

function TMappingParameters.UseAllocationType;
begin
  Result := Duplicate.SetAllocationType(Value);
end;

function TMappingParameters.UseCommitSize;
begin
  Result := Duplicate.SetCommitSize(Value);
end;

function TMappingParameters.UseInheritDisposition;
begin
  Result := Duplicate.SetInheritDisposition(Value);
end;

function TMappingParameters.UseProtection;
begin
  Result := Duplicate.SetProtection(Value);
end;

function TMappingParameters.UseSectionOffset;
begin
  Result := Duplicate.SetSectionOffset(Value);
end;

function TMappingParameters.UseViewSize;
begin
  Result := Duplicate.SetViewSize(Value);
end;

function TMappingParameters.UseZeroBits;
begin
  Result := Duplicate.SetZeroBits(Value);
end;

function MappingParameters;
begin
  if Assigned(Template) then
    Result := Template
  else
    Result := TMappingParameters.Create;
end;

{ Functions }

function RtlxSecImageNoExecute;
begin
  if RtlOsVersionAtLeast(OsWin8) then
    Result := SEC_IMAGE_NO_EXECUTE
  else
    Result := SEC_IMAGE;
end;

function NtxCreateSection;
var
  ObjAttr: PObjectAttributes;
  hSection: THandle;
  pSize: PUInt64;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  if MaximumSize <> 0 then
    pSize := @MaximumSize
  else
    pSize := nil;

  Result.Location := 'NtCreateSection';
  Result.LastCall.Expects(ExpectedSectionFileAccess(PageProtection));

  Result.Status := NtCreateSection(
    hSection,
    AccessMaskOverride(SECTION_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    pSize,
    PageProtection,
    AllocationAttributes,
    HandleOrDefault(hxFile)
  );

  if Result.IsSuccess then
    hxSection := Auto.CaptureHandle(hSection);
end;

function NtxCreateFileSection;
begin
  Result := NtxCreateSection(hxSection, MaximumSize, PageProtection,
    AllocationAttributes, ObjectAttributes, hxFile);
end;

function NtxOpenSection;
var
  ObjAttr: PObjectAttributes;
  hSection: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenSection';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenSection(hSection, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxSection := Auto.CaptureHandle(hSection);
end;

function NtxMapViewOfSection;
var
  Address: Pointer;
  ViewSize: NativeUInt;
  SectionOffset: UInt64;
begin
  Parameters := MappingParameters(Parameters);

  Result.Location := 'NtMapViewOfSection';
  Result.LastCall.Expects(ExpectedSectionMapAccess(Parameters.Protection));
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_VM_OPERATION);

  Address := Parameters.Address;
  ViewSize := Parameters.ViewSize;
  SectionOffset := Parameters.SectionOffset;

  Result.Status := NtMapViewOfSection(
    HandleOrDefault(hxSection),
    HandleOrDefault(hxProcess),
    Address,
    Parameters.ZeroBits,
    Parameters.CommitSize,
    @SectionOffset,
    ViewSize,
    Parameters.InheritDisposition,
    Parameters.AllocationType,
    Parameters.Protection
  );

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
  // Map at least one byte of the section for whatever access
  Result := NtxMapViewOfSection(hxSection, NtxCurrentProcess, MappedMemory,
    MappingParameters.UseProtection(PAGE_NOACCESS).UseViewSize(1));

  if not Result.IsSuccess then
    Exit;

  // Retrieve its filename
  Result := NtxQueryFileNameMemory(NtxCurrentProcess, MappedMemory.Data,
    FileName);
end;

class function NtxSection.Query<T>;
begin
  Result.Location := 'NtQuerySection';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TSectionAccessMask>(SECTION_QUERY);

  Result.Status := NtQuerySection(HandleOrDefault(hxSection), InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

function RtlxQueryEntrypointRvaSection;
var
  OriginalBase, RelocationDelta: UIntPtr;
  ImageInfo: TSectionImageInformation;
begin
  // Determine the image base before dynamic relocation
  Result := NtxSection.Query(hxSection, SectionOriginalBaseInformation,
    OriginalBase);

  if not Result.IsSuccess then
    Exit;

  // Determine delta for dynamic relocation
  Result := NtxSection.Query(hxSection, SectionRelocationInformation,
    RelocationDelta);

  if not Result.IsSuccess then
    Exit;

  // Determine the entrypoint address after dynamic relocation
  Result := NtxSection.Query(hxSection, SectionImageInformation, ImageInfo);

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

  if not Result.IsSuccess then
    Exit;

  Result := NtxCreateFileSection(hxSection, hxFile, PageProtection,
    AllocationAttributes, SectionObjectAttributes);
end;

function RtlxMapFile;
var
  hxSection: IHandle;
begin
  Parameters := MappingParameters(Parameters);

  Result := NtxCreateFileSection(hxSection, hxFile, Parameters.Protection,
    AllocationAttributes);

  if not Result.IsSuccess then
    Exit;

  Result := NtxMapViewOfSection(hxSection, hxProcess, MappedMemory, Parameters);
end;

function RtlxMapFileByName;
var
  hxSection: IHandle;
begin
  Parameters := MappingParameters(Parameters);

  Result := RtlxCreateFileSection(hxSection, FileParameters,
    Parameters.Protection, AllocationAttributes);

  if not Result.IsSuccess then
    Exit;

  Result := NtxMapViewOfSection(hxSection, hxProcess, MappedMemory, Parameters);
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
  Result := NtxMapViewOfSection(hxSection, NtxCurrentProcess, MappedMemory);
end;

function RtlxDuplicateDataSection;
var
  InView, OutView: IMemory;
  Protection: TMemoryProtection;
begin
  // Map the input for reading
  Result := NtxMapViewOfSection(hxSectionIn, NtxCurrentProcess, InView);

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

  // Map the output for writing
  Result := NtxMapViewOfSection(hxSectionOut, NtxCurrentProcess, OutView,
    MappingParameters.UseProtection(PAGE_READWRITE));

  if not Result.IsSuccess then
    Exit;

 // Copy data
  Move(InView.Data^, OutView.Data^, InView.Size);
end;

end.
