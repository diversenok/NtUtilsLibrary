unit Ntapi.ImageHlp;

{
  This file defines structures for parsing PE files (.exe and .dll).
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection;

const
  // SDK::winnt.h
  IMAGE_DOS_SIGNATURE = $5A4D; // MZ
  IMAGE_NT_SIGNATURE = $4550; // PE

  // SDK::winnt.h
  IMAGE_FILE_MACHINE_I386 = $014c;
  IMAGE_FILE_MACHINE_AMD64 = $8664;

  // SDK::winnt.h - file characteristics
  IMAGE_FILE_RELOCS_STRIPPED = $0001;
  IMAGE_FILE_EXECUTABLE_IMAGE = $0002;
  IMAGE_FILE_LINE_NUMS_STRIPPED = $0004;
  IMAGE_FILE_LOCAL_SYMS_STRIPPED = $0008;
  IMAGE_FILE_AGGRESIVE_WS_TRIM = $0010;
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;
  IMAGE_FILE_BYTES_REVERSED_LO = $0080;
  IMAGE_FILE_32BIT_MACHINE = $0100;
  IMAGE_FILE_DEBUG_STRIPPED = $0200;
  IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP = $0400;
  IMAGE_FILE_NET_RUN_FROM_SWAP = $0800;
  IMAGE_FILE_SYSTEM = $1000;
  IMAGE_FILE_DLL = $2000;
  IMAGE_FILE_UP_SYSTEM_ONLY = $4000;
  IMAGE_FILE_BYTES_REVERSED_HI = $8000;

  // SDK::winnt.h
  IMAGE_NT_OPTIONAL_HDR32_MAGIC = $10b;
  IMAGE_NT_OPTIONAL_HDR64_MAGIC = $20b;

  // SDK::winnt.h
  IMAGE_SIZEOF_SHORT_NAME = 8;

  // SDK::winnt.h - section characteristics
  IMAGE_SCN_CNT_CODE = $00000020;
  IMAGE_SCN_CNT_INITIALIZED_DATA = $00000040;
  IMAGE_SCN_CNT_UNINITIALIZED_DATA = $00000080;
  IMAGE_SCN_LNK_INFO = $00000200;
  IMAGE_SCN_LNK_REMOVE = $00000800;
  IMAGE_SCN_LNK_COMDAT = $00001000;
  IMAGE_SCN_NO_DEFER_SPEC_EXC = $00004000;
  IMAGE_SCN_GPREL = $00008000;
  IMAGE_SCN_MEM_16BIT = $00020000;
  IMAGE_SCN_ALIGN_1BYTES = $00100000;
  IMAGE_SCN_ALIGN_2BYTES = $00200000;
  IMAGE_SCN_ALIGN_4BYTES = $00300000;
  IMAGE_SCN_ALIGN_8BYTES = $00400000;
  IMAGE_SCN_ALIGN_16BYTES = $00500000;
  IMAGE_SCN_ALIGN_32BYTES = $00600000;
  IMAGE_SCN_ALIGN_64BYTES = $00700000;
  IMAGE_SCN_ALIGN_128BYTES = $00800000;
  IMAGE_SCN_ALIGN_256BYTES = $00900000;
  IMAGE_SCN_ALIGN_512BYTES = $00A00000;
  IMAGE_SCN_ALIGN_1024BYTES = $00B00000;
  IMAGE_SCN_ALIGN_2048BYTES = $00C00000;
  IMAGE_SCN_ALIGN_4096BYTES = $00D00000;
  IMAGE_SCN_ALIGN_8192BYTES = $00E00000;
  IMAGE_SCN_LNK_NRELOC_OVFL = $01000000;
  IMAGE_SCN_MEM_DISCARDABLE = $02000000;
  IMAGE_SCN_MEM_NOT_CACHED = $04000000;
  IMAGE_SCN_MEM_NOT_PAGED = $08000000;
  IMAGE_SCN_MEM_SHARED = $10000000;
  IMAGE_SCN_MEM_EXECUTE = $20000000;
  IMAGE_SCN_MEM_READ = $40000000;
  IMAGE_SCN_MEM_WRITE = $80000000;

  IMAGE_SCN_ALIGN_MASK = $00F00000;

  IMAGE_RELOCATION_OFFET_MASK = $0FFF;
  IMAGE_RELOCATION_TYPE_SHIFT = 12;

  // SDK::WinUser.h
  RT_RCDATA = MAKEINTRESOURCE(10);

type
  // SDK::winnt.h
  [SDKName('IMAGE_DOS_HEADER')]
  TImageDosHeader = record
    [Reserved(IMAGE_DOS_SIGNATURE)] e_magic: Word;
    [Bytes] e_cblp: Word;
    e_cp: Word;
    e_crlc: Word;
    e_cparhdr: Word;
    [Bytes] e_minalloc: Word;
    [Bytes] e_maxalloc: Word;
    [Hex] e_ss: Word;
    [Hex] e_sp: Word;
    [Hex] e_csum: Word;
    [Hex] e_ip: Word;
    [Hex] e_cs: Word;
    [Hex] e_lfarlc: Word;
    e_ovno: Word;
    e_res: array [0..3] of Word;
    e_oemid: Word;
    e_oeminfo: Word;
    e_res2: array [0..9] of Word;
    [Hex] e_lfanew: Cardinal;
  end;
  PImageDosHeader = ^TImageDosHeader;

  [SubEnum($FFFF, IMAGE_FILE_MACHINE_I386, 'I386')]
  [SubEnum($FFFF, IMAGE_FILE_MACHINE_AMD64, 'AMD64')]
  TImageMachine = type Word;

  [FlagName(IMAGE_FILE_RELOCS_STRIPPED, 'Relocs Stripped')]
  [FlagName(IMAGE_FILE_EXECUTABLE_IMAGE, 'Executable')]
  [FlagName(IMAGE_FILE_LINE_NUMS_STRIPPED, 'Line Numbers Stripped')]
  [FlagName(IMAGE_FILE_LOCAL_SYMS_STRIPPED, 'Local Symbols Stipped')]
  [FlagName(IMAGE_FILE_AGGRESIVE_WS_TRIM, 'Aggressive WS Trim')]
  [FlagName(IMAGE_FILE_LARGE_ADDRESS_AWARE, 'Large Address Aware')]
  [FlagName(IMAGE_FILE_32BIT_MACHINE, '32-bit Machine')]
  [FlagName(IMAGE_FILE_DEBUG_STRIPPED, 'Debug Stripped')]
  [FlagName(IMAGE_FILE_REMOVABLE_RUN_FROM_SWAP, 'Removable Run From Swap')]
  [FlagName(IMAGE_FILE_NET_RUN_FROM_SWAP, 'Net Run From Swap')]
  [FlagName(IMAGE_FILE_SYSTEM, 'System')]
  [FlagName(IMAGE_FILE_DLL, 'DLL')]
  [FlagName(IMAGE_FILE_UP_SYSTEM_ONLY, 'Uni-processor')]
  TImageCharacteristics = type Word;

  // SDK::winnt.h
  [SDKName('IMAGE_FILE_HEADER')]
  TImageFileHeader = record
    Machine: TImageMachine;
    NumberOfSections: Word;
    TimeDateStamp: TUnixTime;
    [Hex] PointerToSymbolTable: Cardinal;
    NumberOfSymbols: Cardinal;
    [Bytes] SizeOfOptionalHeader: Word;
    Characteristics: TImageCharacteristics;
  end;
  PImageFileHeader = ^TImageFileHeader;

  // SDK::winnt.h
  [SDKName('IMAGE_DATA_DIRECTORY')]
  TImageDataDirectory = record
    [Hex] VirtualAddress: Cardinal;
    [Bytes] Size: Cardinal;
  end;
  PImageDataDirectory = ^TImageDataDirectory;

  // SDK::winnt.h
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'IMAGE_SUBSYSTEM')]
  TImageSubsystem = (
    IMAGE_SUBSYSTEM_UNKNOWN = 0,
    IMAGE_SUBSYSTEM_NATIVE = 1,
    IMAGE_SUBSYSTEM_WINDOWS_GUI = 2,
    IMAGE_SUBSYSTEM_WINDOWS_CUI = 3
  );
  {$MINENUMSIZE 4}

  // SDK::winnt.h
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'IMAGE_DIRECTORY_ENTRY'), Range(0, 14)]
  TImageDirectoryEntry = (
    IMAGE_DIRECTORY_ENTRY_EXPORT = 0,        // TImageExportDirectory
    IMAGE_DIRECTORY_ENTRY_IMPORT = 1,        // TImageImportDescriptor
    IMAGE_DIRECTORY_ENTRY_RESOURCE = 2,
    IMAGE_DIRECTORY_ENTRY_EXCEPTION = 3,
    IMAGE_DIRECTORY_ENTRY_SECURITY = 4,
    IMAGE_DIRECTORY_ENTRY_BASERELOC = 5,     // TImageBaseRelocation
    IMAGE_DIRECTORY_ENTRY_DEBUG = 6,
    IMAGE_DIRECTORY_ENTRY_ARCHITECTURE = 7,
    IMAGE_DIRECTORY_ENTRY_GLOBALPTR = 8,
    IMAGE_DIRECTORY_ENTRY_TLS = 9,
    IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG = 10,
    IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT = 11,
    IMAGE_DIRECTORY_ENTRY_IAT = 12,
    IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT = 13, // TImageDelayLoadDescriptor
    IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR = 14,
    IMAGE_DIRECTORY_ENTRY_RESERVED = 15
  );
  {$MINENUMSIZE 4}

  TImageDataDirectories = array [TImageDirectoryEntry] of TImageDataDirectory;

  // SDK::winnt.h
  [SDKName('IMAGE_OPTIONAL_HEADER32')]
  TImageOptionalHeader32 = record
    [Reserved(IMAGE_NT_OPTIONAL_HDR32_MAGIC)] Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    [Bytes] SizeOfCode: Cardinal;
    [Bytes] SizeOfInitializedData: Cardinal;
    [Bytes] SizeOfUninitializedData: Cardinal;
    [Hex] AddressOfEntryPoint: Cardinal;
    [Hex] BaseOfCode: Cardinal;
    [Hex] BaseOfData: Cardinal;
    [Hex] ImageBase: Cardinal;
    SectionAlignment: Cardinal;
    FileAlignment: Cardinal;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: Cardinal;
    [Bytes] SizeOfImage: Cardinal;
    [Bytes] SizeOfHeaders: Cardinal;
    [Hex] CheckSum: Cardinal;
    Subsystem: TImageSubsystem;
    [Hex] DllCharacteristics: Word;
    [Bytes] SizeOfStackReserve: Cardinal;
    [Bytes] SizeOfStackCommit: Cardinal;
    [Bytes] SizeOfHeapReserve: Cardinal;
    [Bytes] SizeOfHeapCommit: Cardinal;
    [Hex] LoaderFlags: Cardinal;
    NumberOfRvaAndSizes: Cardinal;
    DataDirectory: TImageDataDirectories;
  end;
  PImageOptionalHeader32 = ^TImageOptionalHeader32;

  // SDK::winnt.h
  [SDKName('IMAGE_OPTIONAL_HEADER64')]
  TImageOptionalHeader64 = record
    [Reserved(IMAGE_NT_OPTIONAL_HDR64_MAGIC)] Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    [Bytes] SizeOfCode: Cardinal;
    [Bytes] SizeOfInitializedData: Cardinal;
    [Bytes] SizeOfUninitializedData: Cardinal;
    [Hex] AddressOfEntryPoint: Cardinal;
    [Hex] BaseOfCode: Cardinal;
    [Hex] ImageBase: UInt64;
    SectionAlignment: Cardinal;
    FileAlignment: Cardinal;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: Cardinal;
    [Bytes] SizeOfImage: Cardinal;
    [Bytes] SizeOfHeaders: Cardinal;
    [Hex] CheckSum: Cardinal;
    Subsystem: TImageSubsystem;
    [Hex] DllCharacteristics: Word;
    [Bytes] SizeOfStackReserve: UInt64;
    [Bytes] SizeOfStackCommit: UInt64;
    [Bytes] SizeOfHeapReserve: UInt64;
    [Bytes] SizeOfHeapCommit: UInt64;
    [Hex] LoaderFlags: Cardinal;
    NumberOfRvaAndSizes: Cardinal;
    DataDirectory: TImageDataDirectories;
  end;
  PImageOptionalHeader64 = ^TImageOptionalHeader64;

  // Common part of 32- abd 64-bit structures
  [SDKName('IMAGE_OPTIONAL_HEADER')]
  TImageOptionalHeader = record
  public
    [Hex] Magic: Word; // IMAGE_NT_OPTIONAL_HDR*_MAGIC
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    [Bytes] SizeOfCode: Cardinal;
    [Bytes] SizeOfInitializedData: Cardinal;
    [Bytes] SizeOfUninitializedData: Cardinal;
    [Hex] AddressOfEntryPoint: Cardinal;
    [Hex] BaseOfCode: Cardinal;
    FImageBase: UInt64 deprecated 'Use ImageBase function instead';
    SectionAlignment: Cardinal;
    FileAlignment: Cardinal;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: Cardinal;
    [Bytes] SizeOfImage: Cardinal;
    [Bytes] SizeOfHeaders: Cardinal;
    [Hex] CheckSum: Cardinal;
    Subsystem: TImageSubsystem;
    [Hex] DllCharacteristics: Word;
    function SelfAs32: PImageOptionalHeader32;
    function SelfAs64: PImageOptionalHeader64;
    function ImageBase: UInt64;
    function SizeOfStackReserve: UInt64;
    function SizeOfStackCommit: UInt64;
    function SizeOfHeapReserve: UInt64;
    function SizeOfHeapCommit: UInt64;
    function LoaderFlags: Cardinal;
    function NumberOfRvaAndSizes: Cardinal;
    function GetDataDirectory(Index: TImageDirectoryEntry): TImageDataDirectory;
    property DataDirectory[Index: TImageDirectoryEntry]: TImageDataDirectory read GetDataDirectory;
  end;

  TImageSectionName = array [0 .. IMAGE_SIZEOF_SHORT_NAME - 1] of AnsiChar;

  [FlagName(IMAGE_SCN_CNT_CODE, 'Code')]
  [FlagName(IMAGE_SCN_CNT_INITIALIZED_DATA, 'Initialized Data')]
  [FlagName(IMAGE_SCN_CNT_UNINITIALIZED_DATA, 'Uninitialized Data')]
  [FlagName(IMAGE_SCN_LNK_INFO, 'Comments')]
  [FlagName(IMAGE_SCN_LNK_REMOVE, 'Remove Content')]
  [FlagName(IMAGE_SCN_LNK_COMDAT, 'Comdat')]
  [FlagName(IMAGE_SCN_NO_DEFER_SPEC_EXC, 'No Speculative Exceptions')]
  [FlagName(IMAGE_SCN_GPREL, 'GP-relative')]
  [FlagName(IMAGE_SCN_LNK_NRELOC_OVFL, 'Extended Relocations')]
  [FlagName(IMAGE_SCN_MEM_DISCARDABLE, 'Discardable')]
  [FlagName(IMAGE_SCN_MEM_NOT_CACHED, 'Not Cached')]
  [FlagName(IMAGE_SCN_MEM_NOT_PAGED, 'Not Paged')]
  [FlagName(IMAGE_SCN_MEM_SHARED, 'Shared')]
  [FlagName(IMAGE_SCN_MEM_EXECUTE, 'Executable')]
  [FlagName(IMAGE_SCN_MEM_READ, 'Readable')]
  [FlagName(IMAGE_SCN_MEM_WRITE, 'Writale')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, 0, 'Default Alignment')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_1BYTES, 'Align 1 Byte')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_2BYTES, 'Align 2 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_4BYTES, 'Align 4 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_8BYTES, 'Align 8 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_16BYTES, 'Align 16 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_32BYTES, 'Align 32 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_64BYTES, 'Align 64 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_128BYTES, 'Align 128 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_256BYTES, 'Align 256 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_512BYTES, 'Align 512 Bytes')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_1024BYTES, 'Align 1 KiB')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_2048BYTES, 'Align 2 KiB')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_4096BYTES, 'Align 4 KiB')]
  [SubEnum(IMAGE_SCN_ALIGN_MASK, IMAGE_SCN_ALIGN_8192BYTES, 'Align 8 KiB')]
  TImageSectionCharacteristics = type Cardinal;

  // SDK::winnt.h
  [SDKName('IMAGE_SECTION_HEADER')]
  TImageSectionHeader = record
    Name: TImageSectionName;
    [Bytes] VirtualSize: Cardinal;
    [Hex] VirtualAddress: Cardinal;
    [Bytes] SizeOfRawData: Cardinal;
    [Hex] PointerToRawData: Cardinal;
    [Hex] PointerToRelocations: Cardinal;
    [Hex] PointerToLinenumbers: Cardinal;
    NumberOfRelocations: Word;
    NumberOfLineNumbers: Word;
    Characteristics: TImageSectionCharacteristics;
  end;
  PImageSectionHeader = ^TImageSectionHeader;
  PPImageSectionHeader = ^PImageSectionHeader;

  // SDK::winnt.h
  [SDKName('IMAGE_NT_HEADERS')]
  TImageNtHeaders = record
  private
    function GetSection(Index: Cardinal): PImageSectionHeader;
  public
    [Reserved(IMAGE_NT_SIGNATURE)] Signature: Cardinal;
    FileHeader: TImageFileHeader;
    property Section[Index: Cardinal]: PImageSectionHeader read GetSection;
  case Word of
    0: (OptionalHeader: TImageOptionalHeader);
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: (OptionalHeader32: TImageOptionalHeader32);
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: (OptionalHeader64: TImageOptionalHeader64);
  end;
  PImageNtHeaders = ^TImageNtHeaders;

  // SDK::winnt.h
  [SDKName('IMAGE_EXPORT_DIRECTORY')]
  TImageExportDirectory = record
    [Hex] Characteristics: Cardinal;
    TimeDateStamp: TUnixTime;
    MajorVersion: Word;
    MinorVersion: Word;
    Name: Cardinal;
    [Hex] Base: Cardinal;
    NumberOfFunctions: Cardinal;
    NumberOfNames: Cardinal;
    [Hex] AddressOfFunctions: Cardinal;     // RVA from base of image
    [Hex] AddressOfNames: Cardinal;         // RVA from base of image
    [Hex] AddressOfNameOrdinals: Cardinal;  // RVA from base of image
  end;
  PImageExportDirectory = ^TImageExportDirectory;

  // SDK::winnt.h
  [SDKName('IMAGE_IMPORT_BY_NAME')]
  TImageImportByName = record
    Hint: Word;
    Name: TAnysizeArray<AnsiChar>;
  end;
  PImageImportByName = ^TImageImportByName;

  // SDK::winnt.h
  [SDKName('IMAGE_IMPORT_DESCRIPTOR')]
  TImageImportDescriptor = record
    [Hex] OriginalFirstThunk: Cardinal;
    TimeDateStamp: TUnixTime;
    [Hex] ForwarderChain: Cardinal;
    [Hex] Name: Cardinal;
    [Hex] FirstThunk: Cardinal;
  end;
  PImageImportDescriptor = ^TImageImportDescriptor;

  // SDK::winnt.h
  [SDKName('IMAGE_RESOURCE_DIRECTORY')]
  TImageResourceDirectory = record
    [Hex] Characteristics: Cardinal;
    TimeDateStamp: TUnixTime;
    MajorVersion: Word;
    MinorVersion: Word;
    NumberOfNamedEntries: Word;
    NumberOfIdEntries: Word;
  end;
  PImageResourceDirectory = ^TImageResourceDirectory;

  // SDK::winnt.h
  [SDKName('IMAGE_RESOURCE_DATA_ENTRY')]
  TImageResourceDataEntry = record
    OffsetToData: Cardinal;
    [Bytes] Size: Cardinal;
    CodePage: Cardinal;
    [Reserved] Reserved: Cardinal;
  end;
  PImageResourceDataEntry = ^TImageResourceDataEntry;

  // SDK::winnt.h
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'IMAGE_REL_BASED')]
  TImageRelocationType = (
    IMAGE_REL_BASED_ABSOLUTE = 0,
    IMAGE_REL_BASED_HIGH = 1,
    IMAGE_REL_BASED_LOW = 2,
    IMAGE_REL_BASED_HIGHLOW = 3,
    IMAGE_REL_BASED_HIGHADJ = 4,
    IMAGE_REL_BASED_MACHINE_SPECIFIC_5 = 5,
    IMAGE_REL_BASED_RESERVED = 6,
    IMAGE_REL_BASED_MACHINE_SPECIFIC_7 = 7,
    IMAGE_REL_BASED_MACHINE_SPECIFIC_8 = 8,
    IMAGE_REL_BASED_MACHINE_SPECIFIC_9 = 9,
    IMAGE_REL_BASED_DIR64 = 10
  );
  {$MINENUMSIZE 4}

  // Helper type for unpacking relocations
  TImageRelocationTypeOffset = record
    TypeOffset: Word;
    function &Type: TImageRelocationType;
    function Offset: Word;
    function SpansOnNextPage: Boolean;
  end;
  PImageRelocationTypeOffset = ^TImageRelocationTypeOffset;

  // SDK::winnt.h
  [SDKName('IMAGE_BASE_RELOCATION')]
  TImageBaseRelocation = record
    VirtualAddress: Cardinal;
    SizeOfBlock: Cardinal;
    TypeOffsets: TAnysizeArray<TImageRelocationTypeOffset>;
  end;
  PImageBaseRelocation = ^TImageBaseRelocation;

  // SDK::winnt.h
  [SDKName('IMAGE_DELAYLOAD_DESCRIPTOR')]
  TImageDelayLoadDescriptor = record
    [Hex] Attributes: Cardinal;
    [Hex] DllNameRVA: Cardinal;
    [Hex] ModuleHandleRVA: Cardinal;
    [Hex] ImportAddressTableRVA: Cardinal;
    [Hex] ImportNameTableRVA: Cardinal;
    [Hex] BoundImportAddressTableRVA: Cardinal;
    [Hex] UnloadInformationTableRVA: Cardinal;
    TimeDateStamp: TUnixTime;
  end;
  PImageDelayLoadDescriptor = ^TImageDelayLoadDescriptor;

  // SDK::winnt.h
  [SDKName('IMAGE_RUNTIME_FUNCTION_ENTRY')]
  TImageRuntimeFunctionEntry = record
    BeginAddress: Cardinal;
    EndAddress: Cardinal;
    UnwindInfoAddress: Cardinal;
  end;
  PRuntimeFunction = ^TImageRuntimeFunctionEntry;

implementation

{ TImageOptionalHeader }

function TImageOptionalHeader.GetDataDirectory;
begin
  case Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Result := SelfAs32.DataDirectory[Index];
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Result := SelfAs64.DataDirectory[Index];
  else
    Result := Default(TImageDataDirectory);
  end;
end;

function TImageOptionalHeader.ImageBase;
begin
  case Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Result := SelfAs32.ImageBase;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Result := SelfAs64.ImageBase;
  else
    Result := 0;
  end;
end;

function TImageOptionalHeader.LoaderFlags;
begin
  case Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Result := SelfAs32.LoaderFlags;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Result := SelfAs64.LoaderFlags;
  else
    Result := 0;
  end;
end;

function TImageOptionalHeader.NumberOfRvaAndSizes;
begin
  case Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Result := SelfAs32.NumberOfRvaAndSizes;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Result := SelfAs64.NumberOfRvaAndSizes;
  else
    Result := 0;
  end;
end;

function TImageOptionalHeader.SelfAs32;
begin
  Pointer(Result) := @Self;
end;

function TImageOptionalHeader.SelfAs64;
begin
  Pointer(Result) := @Self;
end;

function TImageOptionalHeader.SizeOfHeapCommit;
begin
  case Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Result := SelfAs32.SizeOfHeapCommit;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Result := SelfAs64.SizeOfHeapCommit;
  else
    Result := 0;
  end;
end;

function TImageOptionalHeader.SizeOfHeapReserve;
begin
  case Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Result := SelfAs32.SizeOfHeapReserve;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Result := SelfAs64.SizeOfHeapReserve;
  else
    Result := 0;
  end;
end;

function TImageOptionalHeader.SizeOfStackCommit;
begin
  case Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Result := SelfAs32.SizeOfStackCommit;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Result := SelfAs64.SizeOfStackCommit;
  else
    Result := 0;
  end;
end;

function TImageOptionalHeader.SizeOfStackReserve;
begin
  case Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Result := SelfAs32.SizeOfStackReserve;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Result := SelfAs64.SizeOfStackReserve;
  else
    Result := 0;
  end;
end;

{ TImageNtHeaders }

function TImageNtHeaders.GetSection;
begin
  Result := Pointer(UIntPtr(@OptionalHeader) + FileHeader.SizeOfOptionalHeader +
    SizeOf(TImageSectionHeader) * Index)
end;

{ TImageRelocationTypeOffset }

function TImageRelocationTypeOffset.Offset;
begin
  Result := TypeOffset and IMAGE_RELOCATION_OFFET_MASK;
end;

function TImageRelocationTypeOffset.SpansOnNextPage;
const
  PAGE_SIZE = IMAGE_RELOCATION_OFFET_MASK + 1;
begin
  case &Type of
    IMAGE_REL_BASED_HIGH, IMAGE_REL_BASED_LOW:
      Result := Offset + SizeOf(Word) > PAGE_SIZE;

    IMAGE_REL_BASED_HIGHLOW, IMAGE_REL_BASED_HIGHADJ:
      Result := Offset + SizeOf(Cardinal) > PAGE_SIZE;

    IMAGE_REL_BASED_DIR64:
      Result := Offset + SizeOf(Int64) > PAGE_SIZE;
  else
    Result := False;
  end;
end;

function TImageRelocationTypeOffset.&Type;
begin
  Result := TImageRelocationType(TypeOffset shr IMAGE_RELOCATION_TYPE_SHIFT);
end;

end.
