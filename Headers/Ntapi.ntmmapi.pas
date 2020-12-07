unit Ntapi.ntmmapi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, DelphiApi.Reflection,
  NtUtils.Version;

const
  // WinNt.12784
  PAGE_NOACCESS = $01;
  PAGE_READONLY = $02;
  PAGE_READWRITE = $04;
  PAGE_WRITECOPY = $08;
  PAGE_EXECUTE = $10;
  PAGE_EXECUTE_READ = $20;
  PAGE_EXECUTE_READWRITE = $40;
  PAGE_EXECUTE_WRITECOPY = $80;
  PAGE_GUARD = $100;
  PAGE_NOCACHE = $200;
  PAGE_WRITECOMBINE = $400;

  MEM_COMMIT = $00001000;
  MEM_RESERVE = $00002000;
  MEM_DECOMMIT = $00004000;
  MEM_RELEASE = $00008000;
  MEM_FREE = $00010000;
  MEM_RESET = $00080000;
  MEM_TOP_DOWN = $00100000;
  MEM_WRITE_WATCH = $00200000;
  MEM_PHYSICAL = $00400000;
  MEM_ROTATE = $00800000;
  MEM_LARGE_PAGES = $20000000;

  SEC_FILE = $800000;
  SEC_IMAGE = $1000000;
  SEC_PROTECTED_IMAGE = $2000000;
  SEC_RESERVE = $4000000;
  SEC_COMMIT = $8000000;
  SEC_NOCACHE = $10000000;
  SEC_WRITECOMBINE = $40000000;
  SEC_LARGE_PAGES = $80000000;

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

  // WinNt.12692
  TMemoryBasicInformation = record
    BaseAddress: Pointer;
    AllocationBase: Pointer;
    [Hex] AllocationProtect: Cardinal;
    [Bytes] RegionSize: NativeUInt;
    State: Cardinal;
    [Hex] Protect: Cardinal;
    [Hex] MemoryType: Cardinal;
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
    [Hex] AllocationProtect: Cardinal;
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

  TSectionBasicInformation = record
    BaseAddress: Pointer;
    [Hex] AllocationAttributes: Cardinal;
    [Bytes] MaximumSize: UInt64;
  end;
  PSectionBasicInformation = ^TSectionBasicInformation;

  TSectionImageInformation = record
    TransferAddress: Pointer;
    ZeroBits: Cardinal;
    [Bytes] MaximumStackSize: NativeUInt;
    [Bytes] CommittedStackSize: NativeUInt;
    SubSystemType: Cardinal;
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

function NtAllocateVirtualMemory(ProcessHandle: THandle; var BaseAddress:
  Pointer; ZeroBits: NativeUInt; var RegionSize: NativeUInt; AllocationType:
  Cardinal; Protect: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtFreeVirtualMemory(ProcessHandle: THandle; var BaseAddress: Pointer;
  var RegionSize: NativeUInt; FreeType: Cardinal): NTSTATUS; stdcall;
  external ntdll;

function NtReadVirtualMemory(ProcessHandle: THandle; BaseAddress: Pointer;
  Buffer: Pointer; BufferSize: NativeUInt; NumberOfBytesRead: PNativeUInt):
  NTSTATUS; stdcall; external ntdll;

function NtWriteVirtualMemory(ProcessHandle: THandle; BaseAddress: Pointer;
  Buffer: Pointer; BufferSize: NativeUInt; NumberOfBytesWritten: PNativeUInt):
  NTSTATUS; stdcall; external ntdll;

function NtProtectVirtualMemory(ProcessHandle: THandle; var BaseAddress:
  Pointer; var RegionSize: NativeUInt; NewProtect: Cardinal;
  out OldProtect: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtQueryVirtualMemory(ProcessHandle: THandle; BaseAddress: Pointer;
  MemoryInformationClass: TMemoryInformationClass; MemoryInformation: Pointer;
  MemoryInformationLength: NativeUInt; ReturnLength: PNativeUInt): NTSTATUS;
  stdcall; external ntdll;

function NtLockVirtualMemory(ProcessHandle: THandle; var BaseAddress: Pointer;
  var RegionSize: NativeUInt; MapType: TMapLockType): NTSTATUS; stdcall;
  external ntdll;

function NtUnlockVirtualMemory(ProcessHandle: THandle; var BaseAddress: Pointer;
  var RegionSize: NativeUInt; MapType: TMapLockType): NTSTATUS; stdcall;
  external ntdll;

// Sections

function NtCreateSection(out SectionHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes; MaximumSize: PUInt64;
  SectionPageProtection: Cardinal; AllocationAttributes: Cardinal;
  FileHandle: THandle): NTSTATUS; stdcall; external ntdll;

function NtOpenSection(out SectionHandle: THandle; DesiredAccess: TAccessMask;
  ObjectAttributes: PObjectAttributes): NTSTATUS; stdcall; external ntdll;

function NtMapViewOfSection(SectionHandle: THandle; ProcessHandle: THandle;
  var BaseAddress: Pointer; ZeroBits: NativeUInt; CommitSize: NativeUInt;
  SectionOffset: PUInt64; var ViewSize: NativeUInt; InheritDisposition:
  TSectionInherit; AllocationType: Cardinal; Win32Protect: Cardinal): NTSTATUS;
  stdcall; external ntdll;

function NtUnmapViewOfSection(ProcessHandle: THandle; BaseAddress: Pointer)
  : NTSTATUS; stdcall; external ntdll;

function NtExtendSection(SectionHandle: THandle; var NewSectionSize: UInt64):
  NTSTATUS; stdcall; external ntdll;

function NtQuerySection(SectionHandle: THandle; SectionInformationClass:
  TSectionInformationClass; SectionInformation: Pointer;
  SectionInformationLength: NativeUInt; ReturnLength: PNativeUInt): NTSTATUS;
  stdcall; external ntdll;

function NtAreMappedFilesTheSame(File1MappedAsAnImage, File2MappedAsFile
  : Pointer): NTSTATUS; stdcall; external ntdll;

// Misc.

function NtFlushInstructionCache(ProcessHandle: THandle; BaseAddress: Pointer;
  Length: NativeUInt): NTSTATUS; stdcall; external ntdll;

function NtFlushWriteBuffer: NTSTATUS; stdcall; external ntdll;

 { Expected Access Masks }

function ExpectedSectionFileAccess(Win32Protect: Cardinal): TIoFileAccessMask;
function ExpectedSectionMapAccess(Win32Protect: Cardinal): TSectionAccessMask;

implementation

function ExpectedSectionFileAccess(Win32Protect: Cardinal): TIoFileAccessMask;
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

function ExpectedSectionMapAccess(Win32Protect: Cardinal): TSectionAccessMask;
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
