unit NtUtils.ImageHlp;

{
  This module include various parsing routines for Portable Executable format.
}

interface

uses
  Ntapi.WinNt, Ntapi.ImageHlp, Ntapi.ntmmapi, NtUtils, DelphiApi.Reflection;

type
  TImageBitness = (ib32Bit, ib64Bit);

  TExportEntry = record
    Name: AnsiString;
    Ordinal: Word;
    [Hex] VirtualAddress: Cardinal;
    Forwards: Boolean;
    ForwardsTo: AnsiString;
  end;
  PExportEntry = ^TExportEntry;

  TImportType = (
    itNormal,
    itDelayed
  );

  TImportTypeSet = set of TImportType;

  TImportEntry = record
    ImportByName: Boolean;
    DelayedImport: Boolean;
    Name: AnsiString;
    Ordinal: Word;
  end;

  TImportDllEntry = record
    DllName: AnsiString;
    [Hex] IAT: Cardinal; // Import Address Table RVA
    Functions: TArray<TImportEntry>;
  end;

// Get an NT header of an image
function RtlxGetNtHeaderImage(
  out NtHeader: PImageNtHeaders;
  const Image: TMemory;
  RangeChecks: Boolean = True
): TNtxStatus;

// Get image bitness
function RtlxGetImageBitness(
  out Bitness: TImageBitness;
  const Image: TMemory;
  [in, opt] NtHeaders: PImageNtHeaders = nil;
  RangeChecks: Boolean = True
): TNtxStatus;

// Get a section that contains a virtual address
function RtlxSectionTableFromVirtualAddress(
  out Section: PImageSectionHeader;
  const Image: TMemory;
  MappedAsImage: Boolean;
  VirtualAddress: Cardinal;
  AddressRange: Cardinal;
  [in, opt] NtHeaders: PImageNtHeaders = nil;
  RangeChecks: Boolean = True
): TNtxStatus;

// Get a pointer to a virtual address in an image
function RtlxExpandVirtualAddress(
  out Address: Pointer;
  const Image: TMemory;
  MappedAsImage: Boolean;
  VirtualAddress: Cardinal;
  AddressRange: Cardinal;
  [in, opt] NtHeaders: PImageNtHeaders = nil;
  RangeChecks: Boolean = True;
  [out, opt] pSectionEndAddress: PPointer = nil
): TNtxStatus;

// Get a data directory in an image
function RtlxGetDirectoryEntryImage(
  out Directory: PImageDataDirectory;
  const Image: TMemory;
  MappedAsImage: Boolean;
  Entry: TImageDirectoryEntry;
  RangeChecks: Boolean = True
): TNtxStatus;

// Enumerate exported functions in an image
function RtlxEnumerateExportImage(
  out Entries: TArray<TExportEntry>;
  const Image: TMemory;
  MappedAsImage: Boolean;
  RangeChecks: Boolean = True
): TNtxStatus;

// Find an export enrty by name
function RtlxFindExportedNameIndex(
  const Entries: TArray<TExportEntry>;
  const Name: AnsiString
): Integer;

// Enumerate imported or delayed import of an image
function RtlxEnumerateImportImage(
  out Entries: TArray<TImportDllEntry>;
  const Image: TMemory;
  MappedAsImage: Boolean;
  ImportTypes: TImportTypeSet = [itNormal, itDelayed];
  RangeChecks: Boolean = True
): TNtxStatus;

// Relocate an image to a new base address
function RtlxRelocateImage(
  const Image: TMemory;
  NewImageBase: NativeUInt;
  MappedAsImage: Boolean;
  RangeChecks: Boolean = True
): TNtxStatus;

// Query the image base address that a section would occupy without relocating
function RtlxQueryOriginalBaseImage(
  [Access(SECTION_QUERY)] hSection: THandle;
  const PotentiallyRelocatedMapping: TMemory;
  out Address: Pointer
): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, ntapi.ntstatus, NtUtils.SysUtils, DelphiUtils.Arrays,
  NtUtils.Sections, NtUtils.Processes, NtUtils.Memory,  DelphiUtils.RangeChecks;

{$RANGECHECKS OFF}
{$OVERFLOWCHECKS OFF}

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxGetNtHeaderImage;
const
  Flags: array [Boolean] of Cardinal = (
    RTL_IMAGE_NT_HEADER_EX_FLAG_NO_RANGE_CHECK, 0
  );
begin
  try
    Result.Location := 'RtlImageNtHeaderEx';
    Result.Status := RtlImageNtHeaderEx(Flags[RangeChecks <> False],
      Image.Address, Image.Size, NtHeader);
  except
    Result.Location := 'RtlxGetNtHeaderImage';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxGetImageBitness;
begin
  try
    if not Assigned(NtHeaders) then
    begin
      Result := RtlxGetNtHeaderImage(NtHeaders, Image, RangeChecks);

      if not Result.IsSuccess then
        Exit;
    end;

    Result.Location := 'RtlxGetImageBitness';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;

    if RangeChecks and not CheckStruct(Image,
      @NtHeaders.OptionalHeader.Magic, SizeOf(Word)) then
      Exit;

    case NtHeaders.OptionalHeader.Magic of
      IMAGE_NT_OPTIONAL_HDR32_MAGIC: Bitness := ib32Bit;
      IMAGE_NT_OPTIONAL_HDR64_MAGIC: Bitness := ib64Bit;
    else
      Exit;
    end;

    Result.Status := STATUS_SUCCESS;
  except
    Result.Location := 'RtlxGetImageBitness';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxSectionTableFromVirtualAddress;
var
  SectionRegion: TMemory;
  i: Integer;
begin
  try
    // Reproduce RtlSectionTableFromVirtualAddress with more range checks

    if not Assigned(NtHeaders) then
    begin
      Result := RtlxGetNtHeaderImage(NtHeaders, Image, RangeChecks);

      if not Result.IsSuccess then
        Exit;
    end;

    // Fail with this status if something goes wrong with range checks
    Result.Location := 'RtlxSectionTableFromVirtualAddress';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;

    if RangeChecks and not CheckStruct(Image,
      @NtHeaders.FileHeader, SizeOf(TImageFileHeader)) then
      Exit;

    Pointer(Section) := PByte(@NtHeaders.OptionalHeader) +
      NtHeaders.FileHeader.SizeOfOptionalHeader;

    if RangeChecks and not CheckArray(Image, Section,
      SizeOf(TImageSectionHeader), NtHeaders.FileHeader.NumberOfSections) then
      Exit;

    for i := 0 to Integer(NtHeaders.FileHeader.NumberOfSections) - 1 do
    begin
      UIntPtr(SectionRegion.Address) := Section.VirtualAddress;

      if MappedAsImage then
        SectionRegion.Size := Section.VirtualSize
      else
        SectionRegion.Size := Section.SizeOfRawData;

      // If range checks are disabled, test the starting virtual address only
      if not RangeChecks then
        AddressRange := 0;

      // Does this virtual address (range) belong to this section?
      if CheckStruct(SectionRegion, Pointer(VirtualAddress), AddressRange) then
      begin
        // Found it
        Result.Status := STATUS_SUCCESS;
        Exit;
      end;

      // Go to the next section
      Inc(Section);
    end;

    // The virtual address is not found within image sections
    Result.Status := STATUS_NOT_FOUND;
  except
    Result.Location := 'RtlxSectionTableFromVirtualAddress';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxExpandVirtualAddress;
var
  Section: PImageSectionHeader;
  RawAddress64: UInt64;
begin
  try
    // Reproduce and extend RtlImageRvaToVa with more access checks

    if MappedAsImage and not RangeChecks then
    begin
      // Virtual addresses in an image without range checks are just offsets
      Address := Image.Offset(VirtualAddress);

      // No range checks mean no end address
      if Assigned(pSectionEndAddress) then
        pSectionEndAddress^ := Pointer(UInt64(-1));

      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    // Find a section containing the virtual address range
    Result := RtlxSectionTableFromVirtualAddress(Section, Image, MappedAsImage,
      VirtualAddress, AddressRange, NtHeaders, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'RtlxExpandVirtualAddress';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;

    if MappedAsImage then
    begin
      // Validate the virtual address range
      if RangeChecks and not CheckOffsetStruct(Image, VirtualAddress,
        AddressRange) then
        Exit;

      Address := Image.Offset(VirtualAddress);

      if Assigned(pSectionEndAddress) then
      begin
        // Validate section up to its end
        if RangeChecks and not CheckOffsetStruct(Image, Section.VirtualAddress,
          Section.VirtualSize) then
          Exit;

        pSectionEndAddress^ := Image.Offset(Section.VirtualAddress +
          Section.VirtualSize);
      end;
    end
    else
    begin
      // Compute the address without a possibility to overflow
      RawAddress64 := UInt64(Section.PointerToRawData) + VirtualAddress -
        Section.VirtualAddress;

      // Validate raw data range
      if RangeChecks and not CheckOffsetStruct(Image, RawAddress64,
        AddressRange) then
        Exit;

      // Conver the address from VA to raw
      Address := Image.Offset(RawAddress64);

      if Assigned(pSectionEndAddress) then
      begin
        // Validate section up to the end
        if RangeChecks and not CheckOffsetStruct(Image,
          Section.PointerToRawData, Section.SizeOfRawData) then
          Exit;

        if RangeChecks then
          pSectionEndAddress^ := Image.Offset(Section.PointerToRawData +
            Section.SizeOfRawData)
        else
          pSectionEndAddress^ := Pointer(UInt64(-1)); // No end expected
      end;
    end;

    Result.Status := STATUS_SUCCESS;
  except
    Result.Location := 'RtlxExpandVirtualAddress';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxGetDirectoryEntryImage;
var
  Header: PImageNtHeaders;
  Bitness: TImageBitness;
begin
  // Reproduce RtlImageDirectoryEntryToData with more range checks

  Result := RtlxGetNtHeaderImage(Header, Image, RangeChecks);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxGetImageBitness(Bitness, Image, Header, RangeChecks);

  if not Result.IsSuccess then
    Exit;

  if Bitness = ib64Bit then
    Directory := @Header.OptionalHeader64.DataDirectory[Entry]
  else
    Directory := @Header.OptionalHeader32.DataDirectory[Entry];

  if RangeChecks and not CheckStruct(Image, Directory,
    SizeOf(TImageDataDirectory)) then
    Exit;

  Result.Status := STATUS_SUCCESS;
end;

function CaptureAnsiString(
  const Image: TMemory;
  [in] Start: PAnsiChar;
  RangeChecks: Boolean = True
): AnsiString;
var
  Finish, Boundary: PAnsiChar;
begin
  Finish := Start;

  if RangeChecks then
    Boundary := Image.Offset(Image.Size)
  else
    Boundary := Pointer(UIntPtr(-1));

  while (Finish < Boundary) and (Finish^ <> #0) do
    Inc(Finish);

  SetString(Result, Start, UIntPtr(Finish) - UIntPtr(Start));
end;

{ Export }

function RtlxEnumerateExportImage;
var
  Header: PImageNtHeaders;
  ExportData: PImageDataDirectory;
  ExportDirectory: PImageExportDirectory;
  Names, Functions: ^TAnysizeArray<Cardinal>;
  Ordinals: ^TAnysizeArray<Word>;
  i: Integer;
  Name: PAnsiChar;
begin
  try
    Result := RtlxGetNtHeaderImage(Header, Image, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    // Find export directory data
    Result := RtlxGetDirectoryEntryImage(ExportData, Image,
      MappedAsImage, IMAGE_DIRECTORY_ENTRY_EXPORT, RangeChecks);

    if not Result.IsSuccess then
      Exit;
      
    // Check if the image has any exports
    if ExportData.VirtualAddress = 0 then
    begin
      // Nothing to parse, exit
      Entries := nil;
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;
    
    // Make sure export directory has appropriate size
    if RangeChecks and (ExportData.Size < SizeOf(TImageExportDirectory)) then
    begin
      Result.Location := 'RtlxEnumerateExportImage';
      Result.Status := STATUS_INVALID_IMAGE_FORMAT;
      Exit;
    end;

    // Obtain a pointer to the export directory
    Result := RtlxExpandVirtualAddress(Pointer(ExportDirectory), Image,
      MappedAsImage, ExportData.VirtualAddress, ExportData.Size,
      Header, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    // Verify names and ordinals array size
    if RangeChecks and (ExportDirectory.NumberOfNames >
      Cardinal(-1) div SizeOf(Cardinal)) then
    begin
      Result.Location := 'RtlxEnumerateExportImage';
      Result.Status := STATUS_INTEGER_OVERFLOW;
      Exit;
    end;

    // Get the address of names
    Result := RtlxExpandVirtualAddress(Pointer(Names), Image, MappedAsImage,
      ExportDirectory.AddressOfNames, ExportDirectory.NumberOfNames *
      SizeOf(Cardinal), Header, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    // Get an address of name ordinals
    Result := RtlxExpandVirtualAddress(Pointer(Ordinals), Image,  MappedAsImage,
      ExportDirectory.AddressOfNameOrdinals, ExportDirectory.NumberOfNames *
      SizeOf(Word), Header, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    // Ordinals can reference only up to 65k exported functions
    if RangeChecks and (ExportDirectory.NumberOfFunctions > High(Word)) then
    begin
      Result.Location := 'RtlxEnumerateExportImage';
      Result.Status := STATUS_INTEGER_OVERFLOW;
      Exit;
    end;

    // Get an address of functions
    Result := RtlxExpandVirtualAddress(Pointer(Functions), Image, MappedAsImage,
      ExportDirectory.AddressOfFunctions, ExportDirectory.NumberOfFunctions *
      SizeOf(Cardinal), Header, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    // Fail with this status if something goes wrong
    Result.Location := 'RtlxEnumerateExportImage';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;

    SetLength(Entries, ExportDirectory.NumberOfNames);

    for i := 0 to High(Entries) do
    begin
      Entries[i].Ordinal := Ordinals{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};

      // Get a pointer to a name
      Result := RtlxExpandVirtualAddress(Pointer(Name), Image, MappedAsImage,
        Names{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}, 0, Header,
        RangeChecks);

      if not Result.IsSuccess then
        Exit;

      Entries[i].Name := CaptureAnsiString(Image, Name, RangeChecks);

      // Each ordinal is an index inside an array of functions
      if RangeChecks and (Entries[i].Ordinal >=
        ExportDirectory.NumberOfFunctions) then
      begin
        Result.Location := 'RtlxEnumerateExportImage';
        Result.Status := STATUS_INTEGER_OVERFLOW;
        Exit;
      end;

      Entries[i].VirtualAddress :=
        Functions{$R-}[Ordinals[i]]{$IFDEF R+}{$R+}{$ENDIF};

      // Forwarded functions have the virtual address in the same section as
      // the export directory
      Entries[i].Forwards := (Entries[i].VirtualAddress >=
        ExportData.VirtualAddress) and (Entries[i].VirtualAddress <
        UInt64(ExportData.VirtualAddress) + ExportData.Size);

      if Entries[i].Forwards then
      begin
        // In case of forwarding the address actually points to the target name
        Result := RtlxExpandVirtualAddress(Pointer(Name), Image, MappedAsImage,
          Entries[i].VirtualAddress, 0, Header, RangeChecks);
          
        if not Result.IsSuccess then
          Exit;

        Entries[i].ForwardsTo := CaptureAnsiString(Image, Name, RangeChecks);
      end;
    end;
  except
    Result.Location := 'RtlxEnumerateExportImage';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxFindExportedNameIndex;
begin
  // Export entries are sorted, use fast case-sensitive binary search
  Result := TArray.BinarySearchEx<TExportEntry>(Entries,
    function (const Entry: TExportEntry): Integer
    begin
      Result := RtlxCompareAnsiStrings(Entry.Name, Name, True);
    end
  );
end;

{ Import }

const
  IMAGE_DIRECTORY: array [TImportType] of TImageDirectoryEntry = (
    IMAGE_DIRECTORY_ENTRY_IMPORT, IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT
  );

  DESCRIPTOR_SIZE: array [TImportType] of Cardinal = (
    SizeOf(TImageImportDescriptor), SizeOf(TImageDelayLoadDescriptor)
  );

  IAT_ENTRY_SIZE: array [TImageBitness] of Cardinal = (
    SizeOf(Cardinal), SizeOf(UInt64)
  );

function RtlxpDumpImportTableFunctions(
  out Functions: TArray<TImportEntry>;
  const Image: TMemory;
  MappedAsImage: Boolean;
  TableRVA: Cardinal;
  [in] Header: PImageNtHeaders;
  ImportType: TImportType;
  Bitness: TImageBitness;
  RangeChecks: Boolean
): TNtxStatus;
var
  UnboundIAT, UnboundIATStart, SectionEnd: Pointer;
  ByName: PImageImportByName;
  Count: Cardinal;
  i: Integer;
begin
  try
    // Locate import name table
    Result := RtlxExpandVirtualAddress(Pointer(UnboundIATStart),
      Image, MappedAsImage, TableRVA, IAT_ENTRY_SIZE[Bitness], Header,
      RangeChecks, @SectionEnd);

    if not Result.IsSuccess then
      Exit;

    Count := 0;
    UnboundIAT := UnboundIATStart;
    Dec(PByte(SectionEnd), IAT_ENTRY_SIZE[Bitness]);

    // Count number of functions
    while ((Bitness = ib64Bit) and (UInt64(UnboundIAT^) <> 0)) or
      ((Bitness = ib32Bit) and (Cardinal(UnboundIAT^) <> 0)) do
    begin
      Inc(Count);
      Inc(PByte(UnboundIAT), IAT_ENTRY_SIZE[Bitness]);

      // Make sure the next element belongs to the same section
      if RangeChecks and (UIntPtr(UnboundIAT) > UIntPtr(SectionEnd)) then
      begin
        Result.Location := 'RtlxpDumpImportTableFunctions';
        Result.Status := STATUS_INVALID_IMAGE_FORMAT;
        Exit;
      end;
    end;

    UnboundIAT := UnboundIATStart;
    SetLength(Functions, Count);

    for i := 0 to High(Functions) do
    with Functions[i] do
      begin
        DelayedImport := (ImportType = itDelayed);

        if Bitness = ib64Bit then
          ImportByName := UInt64(UnboundIAT^) and (UInt64(1) shl 63) = 0
        else
          ImportByName := Cardinal(UnboundIAT^) and (1 shl 31) = 0;

        if ImportByName then
        begin
          // Locate function name
          Result := RtlxExpandVirtualAddress(Pointer(ByName), Image,
            MappedAsImage, Cardinal(UnboundIAT^), SizeOf(TImageImportByName),
            Header, RangeChecks);

          if not Result.IsSuccess then
            Exit;

          Name := CaptureAnsiString(Image, @ByName.Name[0], RangeChecks);
        end
        else
          Ordinal := Word(UnboundIAT^); // Import by ordinal

        Inc(PByte(UnboundIAT), IAT_ENTRY_SIZE[Bitness]);
      end;
  except
    Result.Location := 'RtlxpDumpImportTableFunctions';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxpDumpImportTable(
  out Entries: TArray<TImportDllEntry>;
  const Image: TMemory;
  MappedAsImage: Boolean;
  [in] ImportData: PImageDataDirectory;
  [in] Header: PImageNtHeaders;
  ImportType: TImportType;
  Bitness: TImageBitness;
  RangeChecks: Boolean
): TNtxStatus;
var
  ImportDescriptor: PImageImportDescriptor;
  DelayImportDescriptor: PImageDelayLoadDescriptor absolute ImportDescriptor;
  DescriporsStart, DescriporsEnd: Pointer;
  Count: Cardinal;
  i: Integer;
  DllNameRVA, TableRVA: Cardinal;
  pDllName: PAnsiChar;
begin
  try
    // Make sure import directory has appropriate size
    if ImportData.Size < DESCRIPTOR_SIZE[ImportType] then
    begin
      Result.Location := 'RtlxpDumpImportTable';
      Result.Status := STATUS_INVALID_IMAGE_FORMAT;
      Exit;
    end;

    // Obtain a pointer to the import directory
    Result := RtlxExpandVirtualAddress(Pointer(DescriporsStart), Image,
      MappedAsImage, ImportData.VirtualAddress, DESCRIPTOR_SIZE[ImportType],
      Header, RangeChecks, @DescriporsEnd);

    if not Result.IsSuccess then
      Exit;

    Count := 0;
    ImportDescriptor := DescriporsStart;
    Dec(PByte(DescriporsEnd), DESCRIPTOR_SIZE[ImportType]);

    // Count the number of descriptors
    while ((ImportType = itNormal) and (ImportDescriptor.Name <> 0)) or
      ((ImportType = itDelayed) and (DelayImportDescriptor.DllNameRVA <> 0)) do
    begin
      Inc(Count);

      // Move to the next DLL
      if ImportType = itNormal then
        Inc(ImportDescriptor)
      else
        Inc(DelayImportDescriptor);

      // Make sure it is still within the image
      if UIntPtr(ImportDescriptor) > UIntPtr(DescriporsEnd) then
      begin
        Result.Location := 'RtlxpDumpImportTable';
        Result.Status := STATUS_INVALID_IMAGE_FORMAT;
        Exit;
      end;
    end;

    ImportDescriptor := DescriporsStart;
    SetLength(Entries, Count);

    for i := 0 to High(Entries) do
      with Entries[i] do
      begin
        if ImportType = itNormal then
          DllNameRVA := ImportDescriptor.Name
        else
          DllNameRVA := DelayImportDescriptor.DllNameRVA;

        // Locate the DLL name string
        Result := RtlxExpandVirtualAddress(Pointer(pDllName), Image,
          MappedAsImage, DllNameRVA, SizeOf(AnsiChar), Header, RangeChecks);

        if not Result.IsSuccess then
          Exit;

        // Save DLL name and IAT RVA
        DllName := CaptureAnsiString(Image, pDllName, RangeChecks);

        if ImportType = itNormal then
        begin
          IAT := ImportDescriptor.FirstThunk;
          TableRVA := ImportDescriptor.OriginalFirstThunk;
        end
        else
        begin
          IAT := DelayImportDescriptor.ImportAddressTableRVA;
          TableRVA := DelayImportDescriptor.ImportNameTableRVA;
        end;

        // Save all functions from the descriptor
        Result := RtlxpDumpImportTableFunctions(Functions, Image, MappedAsImage,
          TableRVA, Header, ImportType, Bitness, RangeChecks);

        if not Result.IsSuccess then
          Exit;

        // Move to the next DLL
        if ImportType = itNormal then
          Inc(ImportDescriptor)
        else
          Inc(DelayImportDescriptor);
      end;
  except
    Result.Location := 'RtlxpDumpImportTable';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

// A worker function for enumerating image import
function RtlxpEnumerateImportImage(
  out Entries: TArray<TImportDllEntry>;
  const Image: TMemory;
  MappedAsImage: Boolean;
  ImportType: TImportType;
  RangeChecks: Boolean
): TNtxStatus;
var
  Header: PImageNtHeaders;
  ImportData: PImageDataDirectory;
  Bitness: TImageBitness;
begin
  try
    Result := RtlxGetNtHeaderImage(Header, Image, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    // Find import directory data
    Result := RtlxGetDirectoryEntryImage(ImportData, Image, MappedAsImage,
      IMAGE_DIRECTORY[ImportType], RangeChecks);

    if not Result.IsSuccess then
      Exit;

    // Check if the image has any imports
    if ImportData.VirtualAddress = 0 then
    begin
      // Nothing to parse, exit
      Entries := nil;
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    // The structure of import depends on image bitness
    Result := RtlxGetImageBitness(Bitness, Image, Header, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    Result := RtlxpDumpImportTable(Entries, Image, MappedAsImage, ImportData,
      Header, ImportType, Bitness, RangeChecks);
  except
    Result.Location := 'RtlxEnumerateImportImage';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxEnumerateImportImage;
var
  PerTypeEntries: TArray<TImportDllEntry>;
  ImportType: TImportType;
begin
  if ImportTypes - [itNormal, itDelayed] <> [] then
  begin
    Result.Location := 'RtlxEnumerateImportImage';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Entries := nil;

  for ImportType in ImportTypes do
  begin
    Result := RtlxpEnumerateImportImage(PerTypeEntries, Image, MappedAsImage,
      ImportType, RangeChecks);

    if not Result.IsSuccess then
    begin
      Entries := nil;
      Exit;
    end;

    Entries := Entries + PerTypeEntries;
  end;
end;

{ Relocations }

function RtlxRelocateImage;
var
  NtHeaders: PImageNtHeaders;
  Bitness: TImageBitness;
  RelocationDelta: UInt64;
  RelocDirectory: PImageDataDirectory;
  Entry: PImageBaseRelocation;
  DirectoryEnd, TargetPage, Target, TargetBoundary: Pointer;
  TargetSize: Cardinal;
  TypeOffset: PImageRelocationTypeOffset;
  ProtectionReverter, NextPageProtectionReverter: IAutoReleasable;
begin
  try
    Result := RtlxGetNtHeaderImage(NtHeaders, Image, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    Result := RtlxGetImageBitness(Bitness, Image, NtHeaders, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'RtlxRelocateImage';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;

    if RangeChecks then
      case Bitness of
        ib32Bit:
          if not CheckStruct(Image, @NtHeaders.OptionalHeader32.ImageBase,
            SizeOf(Cardinal)) then
            Exit;

        ib64Bit:
          if not CheckStruct(Image, @NtHeaders.OptionalHeader64.ImageBase,
            SizeOf(UInt64)) then
            Exit;
      end;

    {$Q-}{$R-}
    RelocationDelta := NewImageBase - NtHeaders.OptionalHeader.ImageBase;
    {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

    if RelocationDelta = 0 then
    begin
      // No need to relocate
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    // Find the relocations directory
    Result := RtlxGetDirectoryEntryImage(RelocDirectory, Image, MappedAsImage,
      IMAGE_DIRECTORY_ENTRY_BASERELOC, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    if RelocDirectory.Size = 0 then
    begin
      Result.Location := 'RtlxRelocateImage';
      Result.Status := STATUS_ILLEGAL_DLL_RELOCATION;
      Exit;
    end;

    if RangeChecks and (RelocDirectory.Size < SizeOf(TImageBaseRelocation)) then
    begin
      Result.Location := 'RtlxRelocateImage';
      Result.Status := STATUS_INVALID_IMAGE_FORMAT;
      Exit;
    end;

    // Get the start of the relocations block
    Result := RtlxExpandVirtualAddress(Pointer(Entry), Image, MappedAsImage,
      RelocDirectory.VirtualAddress, RelocDirectory.Size, NtHeaders, RangeChecks);

    if not Result.IsSuccess then
      Exit;

    UIntPtr(DirectoryEnd) := UIntPtr(Entry) + RelocDirectory.Size;

    while UIntPtr(Entry) <= UIntPtr(DirectoryEnd) - SizeOf(TImageBaseRelocation) do
    begin
      // Make sure we don't skip the end of the relocation block
      if RangeChecks and (not CheckStruct(Image, @Entry, Entry.SizeOfBlock) or
        (UIntPtr(Entry) + Entry.SizeOfBlock > UIntPtr(DirectoryEnd))) then
      begin
        Result.Location := 'RtlxRelocateImage';
        Result.Status := STATUS_INVALID_IMAGE_FORMAT;
        Exit;
      end;

      // Find the start of the target page
      Result := RtlxExpandVirtualAddress(TargetPage, Image, MappedAsImage,
        Entry.VirtualAddress, 0, NtHeaders, RangeChecks, @TargetBoundary);

      if not Result.IsSuccess then
        Exit;

      if MappedAsImage then
      begin
        // Make sure the memory is writable
        Result := NtxProtectMemoryAuto(NtxCurrentProcess, TargetPage, PAGE_SIZE,
          PAGE_READWRITE, ProtectionReverter);

        if not Result.IsSuccess then
          Exit;
      end;

      TypeOffset := @Entry.TypeOffsets[0];

      while UIntPtr(TypeOffset) <= UIntPtr(Entry) + Entry.SizeOfBlock -
        SizeOf(TImageRelocationTypeOffset) do
      begin
        // Compute the address to patch
        Target := PByte(TargetPage) + TypeOffset.Offset;

        case TypeOffset.&Type of
          IMAGE_REL_BASED_ABSOLUTE:
          begin
            Inc(TypeOffset);
            Continue;
          end;

          IMAGE_REL_BASED_HIGH, IMAGE_REL_BASED_LOW:
            TargetSize := SizeOf(Word);

          IMAGE_REL_BASED_HIGHLOW:
            TargetSize := SizeOf(Cardinal);

          IMAGE_REL_BASED_DIR64:
            TargetSize := SizeOf(UInt64);
        else
          Result.Location := 'RtlxRelocateImage';
          Result.Status := STATUS_NOT_SUPPORTED;
          Exit;
        end;

        // Validate the target address
        if RangeChecks and not CheckStruct(Image, Target, TargetSize) then
        begin
          Result.Location := 'RtlxRelocateImage';
          Result.Status := STATUS_INVALID_IMAGE_FORMAT;
          Exit;
        end;

        // If the relocation spans on the next page, make it writable as well
        if MappedAsImage and TypeOffset.SpansOnNextPage then
        begin
          Result := NtxProtectMemoryAuto(NtxCurrentProcess,
            PByte(TargetPage) + PAGE_SIZE, PAGE_SIZE, PAGE_READWRITE,
            NextPageProtectionReverter);

          if not Result.IsSuccess then
            Exit;
        end;

        // Apply the relocation
        {$Q-}{$R-}
        case TypeOffset.&Type of
          IMAGE_REL_BASED_HIGH:
            Inc(Word(Target^), Word(RelocationDelta shr 16));

          IMAGE_REL_BASED_LOW:
            Inc(Word(Target^), Word(RelocationDelta));

          IMAGE_REL_BASED_HIGHLOW:
            Inc(Cardinal(Target^), Cardinal(RelocationDelta));

          IMAGE_REL_BASED_DIR64:
            Inc(UInt64(Target^), UInt64(RelocationDelta));
        end;
        {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

        Inc(TypeOffset);
      end;

      Inc(PByte(Entry), Entry.SizeOfBlock);
    end;

    // Make the header writable
    if MappedAsImage then
      case Bitness of
        ib32Bit:
        begin
          Result := NtxProtectMemoryAuto(NtxCurrentProcess,
            @NtHeaders.OptionalHeader32.ImageBase, SizeOf(Cardinal),
            PAGE_READWRITE, ProtectionReverter);

          if not Result.IsSuccess then
            Exit;
        end;

        ib64Bit:
        begin
          Result := NtxProtectMemoryAuto(NtxCurrentProcess,
            @NtHeaders.OptionalHeader64.ImageBase, SizeOf(UInt64),
            PAGE_READWRITE, ProtectionReverter);

          if not Result.IsSuccess then
            Exit;
        end;
      end;

    // Adjust the image base in the header
    case Bitness of
      ib32Bit:
        NtHeaders.OptionalHeader32.ImageBase := Cardinal(NewImageBase);

      ib64Bit:
        NtHeaders.OptionalHeader64.ImageBase := NewImageBase;
    end;

    Result.Status := STATUS_SUCCESS;
  except
    Result.Location := 'RtlxRelocateImage';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

function RtlxQueryOriginalBaseImage;
var
  Info: TSectionImageInformation;
  NtHeaders: PImageNtHeaders;
begin
  // Determine the intended entrypoint address of the known DLL
  Result := NtxSection.Query(hSection, SectionImageInformation, Info);

  if not Result.IsSuccess then
    Exit;

  // Find the image header where we can lookup the etrypoint offset
  Result := RtlxGetNtHeaderImage(NtHeaders, PotentiallyRelocatedMapping, False);

  if not Result.IsSuccess then
    Exit;

  // Calculate the original base address
  Address := PByte(Info.TransferAddress) -
    NtHeaders.OptionalHeader.AddressOfEntryPoint;
end;

end.
