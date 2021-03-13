unit Ntapi.ntmmapi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, DelphiApi.Reflection,
  NtUtils.Version;

const
  // WinNt.12943
  PAGE_NOACCESS = $00000001;
  PAGE_READONLY = $00000002;
  PAGE_READWRITE = $00000004;
  PAGE_WRITECOPY = $00000008;
  PAGE_EXECUTE = $00000010;
  PAGE_EXECUTE_READ = $00000020;
  PAGE_EXECUTE_READWRITE = $00000040;
  PAGE_EXECUTE_WRITECOPY = $00000080;
  PAGE_GUARD = $00000100;
  PAGE_NOCACHE = $00000200;
  PAGE_WRITECOMBINE = $00000400;
  PAGE_GRAPHICS_NOACCESS = $00000800;
  PAGE_GRAPHICS_READONLY = $00001000;
  PAGE_GRAPHICS_READWRITE = $00002000;
  PAGE_GRAPHICS_EXECUTE = $00004000;
  PAGE_GRAPHICS_EXECUTE_READ = $00008000;
  PAGE_GRAPHICS_EXECUTE_READWRITE = $00010000;
  PAGE_GRAPHICS_COHERENT = $00020000;
  PAGE_GRAPHICS_NOCACHE = $00040000;
  PAGE_ENCLAVE_MASK = $10000000;
  PAGE_ENCLAVE_UNVALIDATED = $20000000;
  PAGE_TARGETS_NO_UPDATE = $40000000;
  PAGE_TARGETS_INVALID = $40000000;
  PAGE_ENCLAVE_THREAD_CONTROL = $80000000;
  PAGE_REVERT_TO_FILE_MAP = $80000000;

  // WinNt.12971
  MEM_UNMAP_WITH_TRANSIENT_BOOST = $00000001;
  MEM_COALESCE_PLACEHOLDERS = $00000001;
  MEM_PRESERVE_PLACEHOLDER = $00000002;
  MEM_COMMIT = $00001000;
  MEM_RESERVE = $00002000;
  MEM_DECOMMIT = $00004000;
  MEM_REPLACE_PLACEHOLDER = $00004000;
  MEM_RELEASE = $00008000;
  MEM_FREE = $00010000;
  MEM_RESERVE_PLACEHOLDER = $00040000;
  MEM_RESET = $00080000;
  MEM_TOP_DOWN = $00100000;
  MEM_WRITE_WATCH = $00200000;
  MEM_PHYSICAL = $00400000;
  MEM_ROTATE = $00800000;
  MEM_DIFFERENT_IMAGE_BASE_OK = $00800000;
  MEM_RESET_UNDO = $01000000;
  MEM_LARGE_PAGES = $20000000;
  MEM_64K_PAGES = MEM_LARGE_PAGES or MEM_PHYSICAL;
  MEM_4MB_PAGES = $80000000;

  // WinNt.13047
  SEC_PARTITION_OWNER_HANDLE = $00040000;
  SEC_64K_PAGES = $00080000;
  SEC_FILE = $00800000;
  SEC_IMAGE = $01000000;
  SEC_PROTECTED_IMAGE = $02000000;
  SEC_RESERVE = $04000000;
  SEC_COMMIT = $08000000;
  SEC_NOCACHE = $10000000;
  SEC_WRITECOMBINE = $40000000;
  SEC_LARGE_PAGES = $80000000;

  // WinNt.13067
  MEM_PRIVATE = $00020000;
  MEM_MAPPED = $00040000;
  MEM_IMAGE = $01000000;

  MEMORY_REGION_PRIVATE = $00000001;
  MEMORY_REGION_MAPPED_DATA_FILE = $00000002;
  MEMORY_REGION_MAPPED_IMAGE = $00000004;
  MEMORY_REGION_MAPPED_PAGE_FILE = $00000008;
  MEMORY_REGION_MAPPED_PHYSICAL = $00000010;
  MEMORY_REGION_DIRECT_MAPPED = $00000020;
  MEMORY_REGION_SOFTWARE_ENCLAVE = $00000040; // RS3
  MEMORY_REGION_PAGE_SIZE_64K = $00000080;
  MEMORY_REGION_PLACEHOLDER_RESERVATION = $00000100; // RS4

  // Sections

  SECTION_QUERY = $0001;
  SECTION_MAP_WRITE = $0002;
  SECTION_MAP_READ = $0004;
  SECTION_MAP_EXECUTE = $0008;
  SECTION_EXTEND_SIZE = $0010;
  SECTION_MAP_EXECUTE_EXPLICIT = $0020; // not included into SECTION_ALL_ACCESS

  SECTION_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  // Partitions

  MEMORY_PARTITION_QUERY_ACCESS = $0001;
  MEMORY_PARTITION_MODIFY_ACCESS = $0002;
  MEMORY_PARTITION_ALL_ACCESS = STANDARD_RIGHTS_ALL or $03;

  // Sessions

  // WinNt.12832
  SESSION_QUERY_ACCESS = $0001;
  SESSION_MODIFY_ACCESS = $0002;

  SESSION_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $03;

type
  [FriendlyName('section'), ValidMask(SECTION_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SECTION_QUERY, 'Query')]
  [FlagName(SECTION_MAP_WRITE, 'Map Write')]
  [FlagName(SECTION_MAP_READ, 'Map Read')]
  [FlagName(SECTION_MAP_EXECUTE, 'Map Execute')]
  [FlagName(SECTION_EXTEND_SIZE, 'Extend Size')]
  [FlagName(SECTION_MAP_EXECUTE_EXPLICIT, 'Map Execute Explicit')]
  TSectionAccessMask = type TAccessMask;

  [FriendlyName('memory partition')]
  [ValidMask(MEMORY_PARTITION_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(MEMORY_PARTITION_QUERY_ACCESS, 'Query')]
  [FlagName(MEMORY_PARTITION_MODIFY_ACCESS, 'Modify')]
  TPartitionAccessMask = type TAccessMask;

  [FriendlyName('session'), ValidMask(SESSION_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SESSION_QUERY_ACCESS, 'Query')]
  [FlagName(SESSION_MODIFY_ACCESS, 'Modify')]
  TSessionAccessMask = type TAccessMask;

  [FlagName(PAGE_NOACCESS, 'No Access')]
  [FlagName(PAGE_READONLY, 'Readonly')]
  [FlagName(PAGE_READWRITE, 'Read-Write')]
  [FlagName(PAGE_WRITECOPY, 'Write-Copy')]
  [FlagName(PAGE_EXECUTE, 'Execute')]
  [FlagName(PAGE_EXECUTE_READ, 'Execute-Read')]
  [FlagName(PAGE_EXECUTE_READWRITE, 'Execute-Read-Write')]
  [FlagName(PAGE_EXECUTE_WRITECOPY, 'Execute0Write-Copy')]
  [FlagName(PAGE_GUARD, 'Guard')]
  [FlagName(PAGE_NOCACHE, 'No-Cache')]
  [FlagName(PAGE_WRITECOMBINE, 'Write-Combine')]
  [FlagName(PAGE_TARGETS_NO_UPDATE, 'Targets No-Update / Targets Invalid')]
  TMemoryProtection = type Cardinal;
  PMemoryProtection = ^TMemoryProtection;

  [FlagName(MEM_COMMIT, 'Commit')]
  [FlagName(MEM_RESERVE, 'Reserve')]
  [FlagName(MEM_DECOMMIT, 'Decommit')]
  [FlagName(MEM_RELEASE, 'Release')]
  [FlagName(MEM_FREE, 'Free')]
  [FlagName(MEM_RESET, 'Reset')]
  [FlagName(MEM_TOP_DOWN, 'Top-Down')]
  [FlagName(MEM_WRITE_WATCH, 'Write Watch')]
  [FlagName(MEM_64K_PAGES, '64K Pages')]
  [FlagName(MEM_PHYSICAL, 'Physical')]
  [FlagName(MEM_LARGE_PAGES, 'Large Pages')]
  [FlagName(MEM_4MB_PAGES, '4Mb Pages')]
  [FlagName(MEM_ROTATE, 'Rotate')]
  [FlagName(MEM_DIFFERENT_IMAGE_BASE_OK, 'Different Image Base Ok')]
  [FlagName(MEM_RESET_UNDO, 'Reset Undo')]
  TAllocationType = type Cardinal;

  // ntddk.5211
  [NamingStyle(nsCamelCase, 'MemoryPriority')]
  TMemoryPriority = (
    MemoryPriorityLowest = 0,
    MemoryPriorityVeryLow = 1,
    MemoryPriorityLow = 2,
    MemoryPriorityMedium = 3,
    MemoryPriorityBelowNormal = 4,
    MemoryPriorityNormal = 5
  );

  [NamingStyle(nsCamelCase, 'Memory')]
  TMemoryInformationClass = (
    MemoryBasicInformation = 0,          // q: TMemoryBasicInformation
    MemoryWorkingSetInformation = 1,     // q: TMemoryWorkingSetInformation
    MemoryMappedFilenameInformation = 2, // q: UNICODE_STRING
    MemoryRegionInformation = 3,         // q: TMemoryRegionInformation
    MemoryWorkingSetExInformation = 4,
    MemorySharedCommitInformation = 5,
    MemoryImageInformation = 6           // q: TMemoryImageInformation
  );

  [FlagName(MEM_PRIVATE, 'Private')]
  [FlagName(MEM_MAPPED, 'Mapped')]
  [FlagName(MEM_IMAGE, 'Image')]
  TMemoryType = type Cardinal;

  // WinNt.12692
  TMemoryBasicInformation = record
    BaseAddress: Pointer;
    AllocationBase: Pointer;
    AllocationProtect: TMemoryProtection;
    [Bytes] RegionSize: NativeUInt;
    State: TAllocationType;
    Protect: TMemoryProtection;
    &Type: TMemoryType;
  end;
  PMemoryBasicInformation = ^TMemoryBasicInformation;

  TMemoryWorkingSetInformation = record
    [Counter] NumberOfEntries: NativeUInt;
    WorkingSetInfo: TAnysizeArray<NativeUInt>;
  end;
  PMemoryWorkingSetInformation = ^TMemoryWorkingSetInformation;

  [FlagName(MEMORY_REGION_PRIVATE, 'Private')]
  [FlagName(MEMORY_REGION_MAPPED_DATA_FILE, 'Mapped Data File')]
  [FlagName(MEMORY_REGION_MAPPED_IMAGE, 'Mapped Image')]
  [FlagName(MEMORY_REGION_MAPPED_PAGE_FILE, 'Mapped Page File')]
  [FlagName(MEMORY_REGION_MAPPED_PHYSICAL, 'Mapped Physical')]
  [FlagName(MEMORY_REGION_DIRECT_MAPPED, 'Directly Mapped')]
  [FlagName(MEMORY_REGION_SOFTWARE_ENCLAVE, 'Software Enclave')]
  [FlagName(MEMORY_REGION_PAGE_SIZE_64K, 'Page Size 64K')]
  [FlagName(MEMORY_REGION_PLACEHOLDER_RESERVATION, 'Placeholder Reservation')]
  TRegionType = type Cardinal;

  // memoryapi.884
  TMemoryRegionInformation = record
    AllocationBase: Pointer;
    AllocationProtect: TMemoryProtection;
    RegionType: TRegionType;
    [Bytes] RegionSize: NativeUInt;
    [Bytes] CommitSize: NativeUInt;
    [MinOSVersion(OsWin1019H1)] PartitionID: NativeUInt;
  end;
  PMemoryRegionInformation = ^TMemoryRegionInformation;

  TMemoryImageInformation = record
    ImageBase: Pointer;
    [Bytes] SizeOfImage: NativeUInt;
    [Hex] ImageFlags: Cardinal;
  end;
  PMemoryImageInformation = ^TMemoryImageInformation;

  [NamingStyle(nsCamelCase, 'Section')]
  TSectionInformationClass = (
    SectionBasicInformation = 0,       // q: TSectionBasicInformation
    SectionImageInformation = 1,       // q: TSectionImageInformation
    SectionRelocationInformation = 2,
    SectionOriginalBaseInformation = 3 // q: Pointer
  );

  [FlagName(SEC_PARTITION_OWNER_HANDLE, 'Partition Owner Handle')]
  [FlagName(SEC_64K_PAGES, '64K Pages')]
  [FlagName(SEC_FILE, 'File')]
  [FlagName(SEC_IMAGE, 'Image')]
  [FlagName(SEC_PROTECTED_IMAGE, 'Protected Image')]
  [FlagName(SEC_RESERVE, 'Reserve')]
  [FlagName(SEC_COMMIT, 'Commit')]
  [FlagName(SEC_NOCACHE, 'No Cache')]
  [FlagName(SEC_WRITECOMBINE, 'Write-Combine')]
  [FlagName(SEC_LARGE_PAGES, 'Large Pages')]
  TAllocationAttributes = type Cardinal;

  TSectionBasicInformation = record
    BaseAddress: Pointer;
    AllocationAttributes: TAllocationAttributes;
    [Bytes] MaximumSize: UInt64;
  end;
  PSectionBasicInformation = ^TSectionBasicInformation;

  TSectionImageInformation = record
    TransferAddress: Pointer;
    ZeroBits: Cardinal;
    [Bytes] MaximumStackSize: NativeUInt;
    [Bytes] CommittedStackSize: NativeUInt;
    SubSystemType: TImageSubsystem;
    SubSystemVersion: Cardinal;
    OperatingSystemVersion: Cardinal;
    [Hex] ImageCharacteristics: Word;
    [Hex] DllCharacteristics: Word;
    [Hex] Machine: Word;
    ImageContainsCode: Boolean;
    [Hex] ImageFlags: Byte;
    [Hex] LoaderFlags: Cardinal;
    [Bytes] ImageFileSize: Cardinal;
    [Hex] CheckSum: Cardinal;
  end;
  PSectionImageInformation = ^TSectionImageInformation;

  // wdm.7542
  [NamingStyle(nsCamelCase, 'View'), Range(1)]
  TSectionInherit = (
    ViewInvalid = 0,
    ViewShare = 1, // Map into child processes
    ViewUnmap = 2  // Don't map into child processes
  );

  // reactos.mmtypes
  [NamingStyle(nsSnakeCase, 'MAP'), Range(1)]
  TMapLockType = (
    MAP_INVALID = 0,
    MAP_PROCESS = 1, // Lock in working set
    MAP_SYSTEM = 2   // Lock in physical memory
  );

// Virtual memory

function NtAllocateVirtualMemory(
  ProcessHandle: THandle;
  var BaseAddress: Pointer;
  ZeroBits: NativeUInt;
  var RegionSize: NativeUInt;
  AllocationType: TAllocationType;
  Protect: TMemoryProtection
): NTSTATUS; stdcall; external ntdll;

function NtFreeVirtualMemory(
  ProcessHandle: THandle;
  var BaseAddress: Pointer;
  var RegionSize: NativeUInt;
  FreeType: TAllocationType
): NTSTATUS; stdcall; external ntdll;

function NtReadVirtualMemory(
  ProcessHandle: THandle;
  BaseAddress: Pointer;
  Buffer: Pointer;
  BufferSize: NativeUInt;
  NumberOfBytesRead: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

function NtWriteVirtualMemory(
  ProcessHandle: THandle;
  BaseAddress: Pointer;
  Buffer: Pointer;
  BufferSize: NativeUInt;
  NumberOfBytesWritten: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

function NtProtectVirtualMemory(
  ProcessHandle: THandle;
  var BaseAddress: Pointer;
  var RegionSize: NativeUInt;
  NewProtect: TMemoryProtection;
  out OldProtect: TMemoryProtection
): NTSTATUS; stdcall; external ntdll;

function NtQueryVirtualMemory(
  ProcessHandle: THandle;
  BaseAddress: Pointer;
  MemoryInformationClass: TMemoryInformationClass;
  MemoryInformation: Pointer;
  MemoryInformationLength: NativeUInt;
  ReturnLength: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

function NtLockVirtualMemory(
  ProcessHandle: THandle;
  var BaseAddress: Pointer;
  var RegionSize: NativeUInt;
  MapType: TMapLockType
): NTSTATUS; stdcall; external ntdll;

function NtUnlockVirtualMemory(
  ProcessHandle: THandle;
  var BaseAddress: Pointer;
  var RegionSize: NativeUInt;
  MapType: TMapLockType
): NTSTATUS; stdcall; external ntdll;

// Sections

function NtCreateSection(
  out SectionHandle: THandle;
  DesiredAccess: TSectionAccessMask;
  ObjectAttributes: PObjectAttributes;
  MaximumSize: PUInt64;
  SectionPageProtection: TMemoryProtection;
  AllocationAttributes: TAllocationAttributes;
  FileHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtOpenSection(
  out SectionHandle: THandle;
  DesiredAccess: TSectionAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

function NtMapViewOfSection(
  SectionHandle: THandle;
  ProcessHandle: THandle;
  var BaseAddress: Pointer;
  ZeroBits: NativeUInt;
  CommitSize: NativeUInt;
  SectionOffset: PUInt64;
  var ViewSize: NativeUInt;
  InheritDisposition: TSectionInherit;
  AllocationType: TAllocationType;
  Win32Protect: TMemoryProtection
): NTSTATUS; stdcall; external ntdll;

function NtUnmapViewOfSection(
  ProcessHandle: THandle;
  BaseAddress: Pointer
): NTSTATUS; stdcall; external ntdll;

function NtExtendSection(
  SectionHandle: THandle;
  var NewSectionSize: UInt64
): NTSTATUS; stdcall; external ntdll;

function NtQuerySection(
  SectionHandle: THandle;
  SectionInformationClass: TSectionInformationClass;
  SectionInformation: Pointer;
  SectionInformationLength: NativeUInt;
  ReturnLength: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

function NtAreMappedFilesTheSame(
  File1MappedAsAnImage: Pointer;
  File2MappedAsFile: Pointer
): NTSTATUS; stdcall; external ntdll;

// Misc.

function NtFlushInstructionCache(
  ProcessHandle: THandle;
  BaseAddress: Pointer;
  Length: NativeUInt
): NTSTATUS; stdcall; external ntdll;

function NtFlushWriteBuffer: NTSTATUS; stdcall; external ntdll;

 { Expected Access Masks }

function ExpectedSectionFileAccess(
  Win32Protect: TMemoryProtection
): TIoFileAccessMask;

function ExpectedSectionMapAccess(
  Win32Protect: TMemoryProtection
): TSectionAccessMask;

implementation

function ExpectedSectionFileAccess;
begin
  case Win32Protect and $FF of
    PAGE_NOACCESS, PAGE_READONLY, PAGE_WRITECOPY:
      Result := FILE_READ_DATA;

    PAGE_READWRITE:
      Result := FILE_WRITE_DATA or FILE_READ_DATA;

    PAGE_EXECUTE:
      Result := FILE_EXECUTE;

    PAGE_EXECUTE_READ, PAGE_EXECUTE_WRITECOPY:
      Result := FILE_EXECUTE or FILE_READ_DATA;

    PAGE_EXECUTE_READWRITE:
      Result := FILE_EXECUTE or FILE_WRITE_DATA or FILE_READ_DATA;

    else
      Result := 0;
  end;
end;

function ExpectedSectionMapAccess;
begin
  case Win32Protect and $FF of
    PAGE_NOACCESS, PAGE_READONLY, PAGE_WRITECOPY:
      Result := SECTION_MAP_READ;

    PAGE_READWRITE:
      Result := SECTION_MAP_WRITE;

    PAGE_EXECUTE:
      Result := SECTION_MAP_EXECUTE;

    PAGE_EXECUTE_READ, PAGE_EXECUTE_WRITECOPY:
      Result := SECTION_MAP_EXECUTE or SECTION_MAP_READ;

    PAGE_EXECUTE_READWRITE:
      Result := SECTION_MAP_EXECUTE or SECTION_MAP_WRITE;
  else
    Result := 0;
  end;
end;

end.
