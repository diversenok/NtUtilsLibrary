unit Ntapi.ImageHlp;

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection;

const
  // 16664
  IMAGE_DOS_SIGNATURE = $5A4D; // MZ

  // 16829
  IMAGE_FILE_MACHINE_I386 = $014c;
  IMAGE_FILE_MACHINE_AMD64 = $8664;

  // 16968
  IMAGE_NT_OPTIONAL_HDR32_MAGIC = $10b;
  IMAGE_NT_OPTIONAL_HDR64_MAGIC = $20b;

  // 17120
  IMAGE_SIZEOF_SHORT_NAME = 8;

type
  // winnt.16682
  TImageDosHeader = record
    [Hex] e_magic: Word; // MZ
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

  // winnt.16799
  TImageFileHeader = record
    [Hex] Machine: Word;
    NumberOfSections: Word;
    TimeDateStamp: TUnixTime;
    [Hex] PointerToSymbolTable: Cardinal;
    NumberOfSymbols: Cardinal;
    [Bytes] SizeOfOptionalHeader: Word;
    [Hex] Characteristics: Word;
  end;
  PImageFileHeader = ^TImageFileHeader;

  // winnt.16865
  TImageDataDirectory = record
    [Hex] VirtualAddress: Cardinal;
    [Bytes] Size: Cardinal;
  end;
  PImageDataDirectory = ^TImageDataDirectory;

  // winnt.17017
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'IMAGE_SUBSYSTEM')]
  TImageSubsystem = (
    IMAGE_SUBSYSTEM_UNKNOWN = 0,
    IMAGE_SUBSYSTEM_NATIVE = 1,
    IMAGE_SUBSYSTEM_WINDOWS_GUI = 2,
    IMAGE_SUBSYSTEM_WINDOWS_CUI = 3
  );
  {$MINENUMSIZE 4}

  // winnt.17053
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'IMAGE_DIRECTORY_ENTRY'), Range(0, 14)]
  TImageDirectoryEntry = (
    IMAGE_DIRECTORY_ENTRY_EXPORT = 0,
    IMAGE_DIRECTORY_ENTRY_IMPORT = 1,
    IMAGE_DIRECTORY_ENTRY_RESOURCE = 2,
    IMAGE_DIRECTORY_ENTRY_EXCEPTION = 3,
    IMAGE_DIRECTORY_ENTRY_SECURITY = 4,
    IMAGE_DIRECTORY_ENTRY_BASERELOC = 5,
    IMAGE_DIRECTORY_ENTRY_DEBUG = 6,
    IMAGE_DIRECTORY_ENTRY_ARCHITECTURE = 7,
    IMAGE_DIRECTORY_ENTRY_GLOBALPTR = 8,
    IMAGE_DIRECTORY_ENTRY_TLS = 9,
    IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG = 10,
    IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT = 11,
    IMAGE_DIRECTORY_ENTRY_IAT = 12,
    IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT = 13,
    IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR = 14,
    IMAGE_DIRECTORY_ENTRY_RESERVED = 15
  );
  {$MINENUMSIZE 4}

  // winnt.16876
  TImageOptionalHeader32 = record
    [Hex] Magic: Word;
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
    DataDirectory: array [TImageDirectoryEntry] of TImageDataDirectory;
  end;
  PImageOptionalHeader32 = ^TImageOptionalHeader32;

  // winnt.16935
  TImageOptionalHeader64 = record
    [Hex] Magic: Word;
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
    DataDirectory: array [TImageDirectoryEntry] of TImageDataDirectory;
  end;
  PImageOptionalHeader64 = ^TImageOptionalHeader64;

  // Common part of 32- abd 64-bit structures
  TImageOptionalHeader = record
  public
    [Hex] Magic: Word;
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

  // winnt.16982
  TImageNtHeaders = record
    [Hex] Signature: Cardinal; // PE
    FileHeader: TImageFileHeader;
  case Word of
    0: (OptionalHeader: TImageOptionalHeader);
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: (OptionalHeader32: TImageOptionalHeader32);
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: (OptionalHeader64: TImageOptionalHeader64);
  end;
  PImageNtHeaders = ^TImageNtHeaders;

  TImageSectionName = array [0 .. IMAGE_SIZEOF_SHORT_NAME - 1] of AnsiChar;

  // winnt.17122
  TImageSectionHeader = record
    Name: TImageSectionName;
    Misc: Cardinal;
    [Hex] VirtualAddress: Cardinal;
    [Bytes] SizeOfRawData: Cardinal;
    [Hex] PointerToRawData: Cardinal;
    [Hex] PointerToRelocations: Cardinal;
    [Hex] PointerToLinenumbers: Cardinal;
    NumberOfRelocations: Word;
    NumberOfLineNumbers: Word;
    [Hex] Characteristics: Cardinal;
  end;
  PImageSectionHeader = ^TImageSectionHeader;
  PPImageSectionHeader = ^PImageSectionHeader;

  // winnt.17982
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

  // winnt.18001
  TImageImportByName = record
    Hint: Word;
    Name: TAnysizeArray<AnsiChar>;
  end;
  PImageImportByName = ^TImageImportByName;

  // winnt.18104
  TImageImportDescriptor = record
    [Hex] OriginalFirstThunk: Cardinal;
    TimeDateStamp: TUnixTime;
    [Hex] ForwarderChain: Cardinal;
    [Hex] Name: Cardinal;
    [Hex] FirstThunk: Cardinal;
  end;
  PImageImportDescriptor = ^TImageImportDescriptor;

  // winnt.18137
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

end.
