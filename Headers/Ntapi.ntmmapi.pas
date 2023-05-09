unit Ntapi.ntmmapi;

{
  The module provides access to memory management with Native API.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntseapi, Ntapi.ImageHlp,
  Ntapi.Versions, DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  // WDK::wdm.h
  PAGE_SIZE = $1000;

  // SDK::winnt.h - page access options
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

  // SDK::winnt.h - memory operation options
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

  // SDK::winnt.h - allocation attributes
  SEC_PARTITION_OWNER_HANDLE = $00040000;
  SEC_64K_PAGES = $00080000;
  SEC_BASED = $00200000;
  SEC_NO_CHANGE = $00400000;
  SEC_FILE = $00800000;
  SEC_IMAGE = $01000000;
  SEC_PROTECTED_IMAGE = $02000000;
  SEC_RESERVE = $04000000;
  SEC_COMMIT = $08000000;
  SEC_NOCACHE = $10000000;
  SEC_GLOBAL = $20000000;
  SEC_WRITECOMBINE = $40000000;
  SEC_LARGE_PAGES = $80000000;
  SEC_IMAGE_NO_EXECUTE = SEC_IMAGE or SEC_NOCACHE; // Win 8+

  // SDK::winnt.h - types of memory
  MEM_PRIVATE = $00020000;
  MEM_MAPPED = $00040000;
  MEM_IMAGE = $01000000;

  // Memory region types extracted from a bit union of MEMORY_REGION_INFORMATION
  MEMORY_REGION_PRIVATE = $00000001;
  MEMORY_REGION_MAPPED_DATA_FILE = $00000002;
  MEMORY_REGION_MAPPED_IMAGE = $00000004;
  MEMORY_REGION_MAPPED_PAGE_FILE = $00000008;
  MEMORY_REGION_MAPPED_PHYSICAL = $00000010;
  MEMORY_REGION_DIRECT_MAPPED = $00000020;
  MEMORY_REGION_SOFTWARE_ENCLAVE = $00000040; // Win 10 RS3+
  MEMORY_REGION_PAGE_SIZE_64K = $00000080;
  MEMORY_REGION_PLACEHOLDER_RESERVATION = $00000100; // Win 10 RS4+
  MEMORY_REGION_MAPPED_AWE = $00000200; // Win 10 21H1
  MEMORY_REGION_MAPPED_WRITE_WATCH = $00000400;
  MEMORY_REGION_PAGE_SIZE_LARGE = $00000800;
  MEMORY_REGION_PAGE_SIZE_HUGE = $00001000;

  // Extracted bit field from MEMORY_IMAGE_INFORMATION's ImageFlags
  MEMORY_IMAGE_PARTIAL_MAP = $00000001;
  MEMORY_IMAGE_NOT_EXECUTABLE = $00000002;
  MEMORY_IMAGE_SIGNING_LEVEL_MASK = $0000003C; // embedded TSeSigningLevel, Win 10 RS3+
  MEMORY_IMAGE_SIGNING_LEVEL_SHIFT = 2;

  // Extracted bit field from SECTION_IMAGE_INFORMATION's ImageFlags
  SECTION_IMAGE_COMPLUS_NATIVE_READY = $01;
  SECTION_IMAGE_COMPLUS_IL_OONLY = $02;
  SECTION_IMAGE_DYNAMICALLY_RELOCATED = $04;
  SECTION_IMAGE_MAPPED_FLAT = $08;
  SECTION_IMAGE_BELOW_4GB = $10;
  SECTION_IMAGE_COMPLUS_PREFER_32BIT = $20;

  // Sections

  // WDK::wdm.h - section access masks
  SECTION_QUERY = $0001;
  SECTION_MAP_WRITE = $0002;
  SECTION_MAP_READ = $0004;
  SECTION_MAP_EXECUTE = $0008;
  SECTION_EXTEND_SIZE = $0010;
  SECTION_MAP_EXECUTE_EXPLICIT = $0020; // not included into SECTION_ALL_ACCESS
  SECTION_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  // For annotations
  SECTION_MAP_ANY = SECTION_MAP_READ or SECTION_MAP_WRITE or SECTION_MAP_EXECUTE;
  FILE_MAP_SECTION = FILE_READ_DATA or FILE_WRITE_DATA or FILE_EXECUTE;

  // Partitions

  // SDK::winnt.h - memory partition access masks
  MEMORY_PARTITION_QUERY_ACCESS = $0001;
  MEMORY_PARTITION_MODIFY_ACCESS = $0002;
  MEMORY_PARTITION_ALL_ACCESS = STANDARD_RIGHTS_ALL or $03;

  // Sessions

  // SDK::winnt.h - session object access masks
  SESSION_QUERY_ACCESS = $0001;
  SESSION_MODIFY_ACCESS = $0002;
  SESSION_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $03;

type
  [FriendlyName('section'), ValidBits(SECTION_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SECTION_QUERY, 'Query')]
  [FlagName(SECTION_MAP_WRITE, 'Map Write')]
  [FlagName(SECTION_MAP_READ, 'Map Read')]
  [FlagName(SECTION_MAP_EXECUTE, 'Map Execute')]
  [FlagName(SECTION_EXTEND_SIZE, 'Extend Size')]
  [FlagName(SECTION_MAP_EXECUTE_EXPLICIT, 'Map Execute Explicit')]
  TSectionAccessMask = type TAccessMask;

  [FriendlyName('memory partition')]
  [ValidBits(MEMORY_PARTITION_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(MEMORY_PARTITION_QUERY_ACCESS, 'Query')]
  [FlagName(MEMORY_PARTITION_MODIFY_ACCESS, 'Modify')]
  TPartitionAccessMask = type TAccessMask;

  [FriendlyName('session'), ValidBits(SESSION_ALL_ACCESS), IgnoreUnnamed]
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
  [FlagName(PAGE_EXECUTE_WRITECOPY, 'Execute-Write-Copy')]
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

  // WDK::ntddk.h
  [NamingStyle(nsCamelCase, 'MEMORY_PRIORITY')]
  TMemoryPriority = (
    MEMORY_PRIORITY_LOWEST = 0,
    MEMORY_PRIORITY_VERY_LOW = 1,
    MEMORY_PRIORITY_LOW = 2,
    MEMORY_PRIORITY_MEDIUM = 3,
    MEMORY_PRIORITY_BELOW_NORMAL = 4,
    MEMORY_PRIORITY_NORMAL = 5
  );

  // PHNT::ntmmapi.h
  [NamingStyle(nsCamelCase, 'Memory')]
  TMemoryInformationClass = (
    MemoryBasicInformation = 0,          // q: TMemoryBasicInformation
    MemoryWorkingSetInformation = 1,     // q: TMemoryWorkingSetInformation
    MemoryMappedFilenameInformation = 2, // q: UNICODE_STRING
    MemoryRegionInformation = 3,         // q: TMemoryRegionInformation
    MemoryWorkingSetExInformation = 4,   // q: TMemoryWorkingSetExInformation
    MemorySharedCommitInformation = 5,   // q: NativeUInt (CommitSize), Win 8+
    MemoryImageInformation = 6           // q: TMemoryImageInformation
  );

  [FlagName(MEM_PRIVATE, 'Private')]
  [FlagName(MEM_MAPPED, 'Mapped')]
  [FlagName(MEM_IMAGE, 'Image')]
  TMemoryType = type Cardinal;

  // SDK::winnt.h
  [SDKName('MEMORY_BASIC_INFORMATION')]
  TMemoryBasicInformation = record
    BaseAddress: Pointer;
    AllocationBase: Pointer;
    AllocationProtect: TMemoryProtection;
  {$IFDEF Win64}
    [MinOSVersion(OsWin1020H1)] PartitionId: Word;
  {$ENDIF}
    [Bytes] RegionSize: NativeUInt;
    State: TAllocationType;
    Protect: TMemoryProtection;
    MemoryType: TMemoryType;
  end;
  PMemoryBasicInformation = ^TMemoryBasicInformation;

  // PHNT::ntmmapi.h
  [SDKName('MEMORY_WORKING_SET_INFORMATION')]
  TMemoryWorkingSetInformation = record
    [Counter] NumberOfEntries: NativeUInt;
    WorkingSetInfo: TAnysizeArray<NativeUInt>;
  end;
  PMemoryWorkingSetInformation = ^TMemoryWorkingSetInformation;

  [SDKName('MEMORY_WORKING_SET_EX_INFORMATION')]
  TMemoryWorkingSetExInformation = record
    VirtualAddress: Pointer;
    VirtualAttributes: NativeUInt;
  end;
  PMemoryWorkingSetExInformation = ^TMemoryWorkingSetExInformation;

  [FlagName(MEMORY_REGION_PRIVATE, 'Private')]
  [FlagName(MEMORY_REGION_MAPPED_DATA_FILE, 'Mapped Data File')]
  [FlagName(MEMORY_REGION_MAPPED_IMAGE, 'Mapped Image')]
  [FlagName(MEMORY_REGION_MAPPED_PAGE_FILE, 'Mapped Page File')]
  [FlagName(MEMORY_REGION_MAPPED_PHYSICAL, 'Mapped Physical')]
  [FlagName(MEMORY_REGION_DIRECT_MAPPED, 'Directly Mapped')]
  [FlagName(MEMORY_REGION_SOFTWARE_ENCLAVE, 'Software Enclave')]
  [FlagName(MEMORY_REGION_PAGE_SIZE_64K, 'Page Size 64K')]
  [FlagName(MEMORY_REGION_PLACEHOLDER_RESERVATION, 'Placeholder Reservation')]
  [FlagName(MEMORY_REGION_MAPPED_AWE, 'Mapped AWE')]
  [FlagName(MEMORY_REGION_MAPPED_WRITE_WATCH, 'Mapped Write Watch')]
  [FlagName(MEMORY_REGION_PAGE_SIZE_LARGE, 'Page Size Large')]
  [FlagName(MEMORY_REGION_PAGE_SIZE_HUGE, 'Page Size Huge')]
  TRegionType = type Cardinal;

  // PHNT::ntmmapi.h & partially SDK::memoryapi.h
  [SDKName('MEMORY_REGION_INFORMATION')]
  TMemoryRegionInformation = record
    AllocationBase: Pointer;
    AllocationProtect: TMemoryProtection;
    RegionType: TRegionType;
    [Bytes] RegionSize: NativeUInt;
    [Bytes] CommitSize: NativeUInt;
    [MinOSVersion(OsWin1019H1)] PartitionID: NativeUInt;
    [MinOSVersion(OsWin1020H1)] NodePreference: PNativeUInt;
  end;
  PMemoryRegionInformation = ^TMemoryRegionInformation;

  [FlagName(MEMORY_IMAGE_PARTIAL_MAP, 'Partial Map')]
  [FlagName(MEMORY_IMAGE_NOT_EXECUTABLE, 'Not Executable')]
  TMemoryImageFlags = type Cardinal;

  // PHNT::ntmmapi.h
  [SDKName('MEMORY_IMAGE_INFORMATION')]
  TMemoryImageInformation = record
    ImageBase: Pointer;
    [Bytes] SizeOfImage: NativeUInt;
    ImageFlags: TMemoryImageFlags;
  end;
  PMemoryImageInformation = ^TMemoryImageInformation;

  // PHNT::ntmmapi.h
  [SDKName('SECTION_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Section')]
  TSectionInformationClass = (
    SectionBasicInformation = 0,       // q: TSectionBasicInformation
    SectionImageInformation = 1,       // q: TSectionImageInformation
    SectionRelocationInformation = 2,  // q: Pointer
    SectionOriginalBaseInformation = 3 // q: Pointer, Win 10 RS2+
  );

  [FlagName(SEC_PARTITION_OWNER_HANDLE, 'Partition Owner Handle')]
  [FlagName(SEC_64K_PAGES, '64K Pages')]
  [FlagName(SEC_BASED, 'Based')]
  [FlagName(SEC_NO_CHANGE, 'No Change')]
  [FlagName(SEC_FILE, 'File')]
  [FlagName(SEC_IMAGE_NO_EXECUTE, 'Image No Execute')]
  [FlagName(SEC_IMAGE, 'Image')]
  [FlagName(SEC_PROTECTED_IMAGE, 'Protected Image')]
  [FlagName(SEC_RESERVE, 'Reserve')]
  [FlagName(SEC_COMMIT, 'Commit')]
  [FlagName(SEC_NOCACHE, 'No Cache')]
  [FlagName(SEC_GLOBAL, 'Global')]
  [FlagName(SEC_WRITECOMBINE, 'Write-Combine')]
  [FlagName(SEC_LARGE_PAGES, 'Large Pages')]
  TAllocationAttributes = type Cardinal;

  // PHNT::ntmmapi.h
  [SDKName('SECTION_BASIC_INFORMATION')]
  TSectionBasicInformation = record
    BaseAddress: Pointer;
    AllocationAttributes: TAllocationAttributes;
    [Bytes] MaximumSize: UInt64;
  end;
  PSectionBasicInformation = ^TSectionBasicInformation;

  [FlagName(SECTION_IMAGE_COMPLUS_NATIVE_READY, 'ComPlus Native Ready')]
  [FlagName(SECTION_IMAGE_COMPLUS_IL_OONLY, 'ComPlus IL Only')]
  [FlagName(SECTION_IMAGE_DYNAMICALLY_RELOCATED, 'Dynamically Relocated')]
  [FlagName(SECTION_IMAGE_MAPPED_FLAT, 'Mapped Flat')]
  [FlagName(SECTION_IMAGE_BELOW_4GB, 'Below 4GB')]
  [FlagName(SECTION_IMAGE_COMPLUS_PREFER_32BIT, 'ComPlus Prefer 32-bit')]
  TSectionImageFlags = type Byte;

  // PHNT::ntmmapi.h
  [SDKName('SECTION_IMAGE_INFORMATION')]
  TSectionImageInformation = record
    TransferAddress: Pointer;
    ZeroBits: Cardinal;
    [Bytes] MaximumStackSize: NativeUInt;
    [Bytes] CommittedStackSize: NativeUInt;
    SubSystemType: TImageSubsystem;
    SubSystemVersion: Cardinal;
    OperatingSystemVersion: Cardinal;
    ImageCharacteristics: TImageCharacteristics;
    DllCharacteristics: TImageDllCharacteristics;
    Machine: TImageMachine;
    ImageContainsCode: Boolean;
    ImageFlags: TSectionImageFlags;
    [Hex] LoaderFlags: Cardinal;
    [Bytes] ImageFileSize: Cardinal;
    [Hex] CheckSum: Cardinal;
  end;
  PSectionImageInformation = ^TSectionImageInformation;

  // WDK::wdm.h
  [NamingStyle(nsCamelCase, 'View'), Range(1)]
  TSectionInherit = (
    ViewInvalid = 0,
    ViewShare = 1, // Map into child processes
    ViewUnmap = 2  // Don't map into child processes
  );

  // ReactOs::mmtypes.h
  [NamingStyle(nsSnakeCase, 'MAP'), Range(1)]
  TMapLockType = (
    MAP_INVALID = 0,
    MAP_PROCESS = 1, // Lock in working set
    MAP_SYSTEM = 2   // Lock in physical memory
  );

// Virtual memory

// WDK::ntifs.h
[Result: ReleaseWith('NtFreeVirtualMemory')]
function NtAllocateVirtualMemory(
  [in, Access(PROCESS_VM_OPERATION)] ProcessHandle: THandle;
  [in, out, opt] var BaseAddress: Pointer;
  [in, opt] ZeroBits: NativeUInt;
  [in, out] var RegionSize: NativeUInt;
  [in] AllocationType: TAllocationType;
  [in] Protect: TMemoryProtection
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtFreeVirtualMemory(
  [in, Access(PROCESS_VM_OPERATION)] ProcessHandle: THandle;
  [in, out] var BaseAddress: Pointer;
  [in, out] var RegionSize: NativeUInt;
  [in] FreeType: TAllocationType
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
function NtReadVirtualMemory(
  [in, Access(PROCESS_VM_READ)] ProcessHandle: THandle;
  [in] BaseAddress: Pointer;
  [out, WritesTo] Buffer: Pointer;
  [in, NumberOfBytes] BufferSize: NativeUInt;
  [out, opt, NumberOfBytes] NumberOfBytesRead: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
function NtWriteVirtualMemory(
  [in, Access(PROCESS_VM_WRITE)] ProcessHandle: THandle;
  [in] BaseAddress: Pointer;
  [in, ReadsFrom] Buffer: Pointer;
  [in, NumberOfBytes] BufferSize: NativeUInt;
  [out, opt, NumberOfBytes] NumberOfBytesWritten: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
function NtProtectVirtualMemory(
  [in, Access(PROCESS_VM_OPERATION)] ProcessHandle: THandle;
  [in, out] var BaseAddress: Pointer;
  [in, out] var RegionSize: NativeUInt;
  [in] NewProtect: TMemoryProtection;
  [out] out OldProtect: TMemoryProtection
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtQueryVirtualMemory(
  [in, Access(PROCESS_QUERY_INFORMATION)] ProcessHandle: THandle;
  [in, opt] BaseAddress: Pointer;
  [in] MemoryInformationClass: TMemoryInformationClass;
  [out, WritesTo] MemoryInformation: Pointer;
  [in, NumberOfBytes] MemoryInformationLength: NativeUInt;
  [out, opt, NumberOfBytes] ReturnLength: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
[Result: ReleaseWith('NtLockVirtualMemory')]
[RequiredPrivilege(SE_LOCK_MEMORY_PRIVILEGE, rpWithExceptions)]
function NtLockVirtualMemory(
  [in, Access(PROCESS_VM_OPERATION)] ProcessHandle: THandle;
  [in, out] var BaseAddress: Pointer;
  [in, out] var RegionSize: NativeUInt;
  [in] MapType: TMapLockType
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
[RequiredPrivilege(SE_LOCK_MEMORY_PRIVILEGE, rpWithExceptions)]
function NtUnlockVirtualMemory(
  [in, Access(PROCESS_VM_OPERATION)] ProcessHandle: THandle;
  [in, out] var BaseAddress: Pointer;
  [in, out] var RegionSize: NativeUInt;
  [in] MapType: TMapLockType
): NTSTATUS; stdcall; external ntdll;

// Sections

// WDK::ntifs.h
function NtCreateSection(
  [out, ReleaseWith('NtClose')] out SectionHandle: THandle;
  [in] DesiredAccess: TSectionAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in, opt] MaximumSize: PUInt64;
  [in] SectionPageProtection: TMemoryProtection;
  [in] AllocationAttributes: TAllocationAttributes;
  [in, opt] FileHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtOpenSection(
  [out, ReleaseWith('NtClose')] out SectionHandle: THandle;
  [in] DesiredAccess: TSectionAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[Result: ReleaseWith('NtUnmapViewOfSection')]
function NtMapViewOfSection(
  [in, Access(SECTION_MAP_READ or SECTION_MAP_WRITE or
    SECTION_MAP_EXECUTE)] SectionHandle: THandle;
  [in, Access(PROCESS_VM_OPERATION)] ProcessHandle: THandle;
  [in, out, opt] var BaseAddress: Pointer;
  [in, opt] ZeroBits: NativeUInt;
  [in, opt] CommitSize: NativeUInt;
  [in, opt] SectionOffset: PUInt64;
  [in, out, opt] var ViewSize: NativeUInt;
  [in] InheritDisposition: TSectionInherit;
  [in] AllocationType: TAllocationType;
  [in] Win32Protect: TMemoryProtection
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtUnmapViewOfSection(
  [in, Access(PROCESS_VM_OPERATION)] ProcessHandle: THandle;
  [in] BaseAddress: Pointer
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
function NtExtendSection(
  [in, Access(SECTION_EXTEND_SIZE)] SectionHandle: THandle;
  [in, out] var NewSectionSize: UInt64
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
function NtQuerySection(
  [in, Access(SECTION_QUERY)] SectionHandle: THandle;
  [in] SectionInformationClass: TSectionInformationClass;
  [out, WritesTo] SectionInformation: Pointer;
  [in, NumberOfBytes] SectionInformationLength: NativeUInt;
  [out, opt, NumberOfBytes] ReturnLength: PNativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
function NtAreMappedFilesTheSame(
  [in] File1MappedAsAnImage: Pointer;
  [in] File2MappedAsFile: Pointer
): NTSTATUS; stdcall; external ntdll;

// Sessions

// PHNT::ntioapi.h
function NtOpenSession(
  [out] out SessionHandle: THandle;
  [in] DesiredAccess: TSessionAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// Partitions

// PHNT::ntmmapi.h
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_LOCK_MEMORY_PRIVILEGE, rpAlways)]
function NtCreatePartition(
  [in, opt, Access(MEMORY_PARTITION_MODIFY_ACCESS)]
    ParentPartitionHandle: THandle;
  [out] out PartitionHandle: THandle;
  [in] DesiredAccess: TPartitionAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] PreferredNode: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtCreatePartition: TDelayedLoadFunction = (
  DllName: ntdll;
  FunctionName: 'NtCreatePartition';
);

// PHNT::ntmmapi.h
[MinOSVersion(OsWin10TH1)]
function NtOpenPartition(
  [out] out PartitionHandle: THandle;
  [in] DesiredAccess: TPartitionAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtOpenPartition: TDelayedLoadFunction = (
  DllName: ntdll;
  FunctionName: 'NtOpenPartition';
);

// Misc.

// PHNT::ntmmapi.h
function NtFlushInstructionCache(
  [in, Access(PROCESS_VM_WRITE)] ProcessHandle: THandle;
  [in, opt] BaseAddress: Pointer;
  [in, NumberOfBytes] Length: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntmmapi.h
function NtFlushWriteBuffer(
): NTSTATUS; stdcall; external ntdll;

 { Expected Access Masks }

function ExpectedSectionFileAccess(
  [in] Win32Protect: TMemoryProtection
): TIoFileAccessMask;

function ExpectedSectionMapAccess(
  [in] Win32Protect: TMemoryProtection
): TSectionAccessMask;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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
