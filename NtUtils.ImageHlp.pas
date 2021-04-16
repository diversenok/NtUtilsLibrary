unit NtUtils.ImageHlp;

{
  This module include various parsing routines for Portable Executable format.
}

interface

{$OVERFLOWCHECKS OFF}

uses
  Winapi.WinNt, NtUtils, DelphiApi.Reflection;

type
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
  Base: PByte;
  ImageSize: NativeUInt;
  out NtHeader: PImageNtHeaders
): TNtxStatus;

// Get image bitness
function RtlxGetImageBitness(
  NtHeaders: PImageNtHeaders;
  out Is64Bit: Boolean
): TNtxStatus;

// Get a section that contains a virtual address
function RtlxGetSectionImage(
  Base: PByte;
  ImageSize: NativeUInt;
  NtHeaders: PImageNtHeaders;
  VirtualAddress: Cardinal;
  out Section: PImageSectionHeader
): TNtxStatus;

// Get a pointer to a virtual address in an image
function RtlxExpandVirtualAddress(
  Base: PByte;
  ImageSize: NativeUInt;
  NtHeaders: PImageNtHeaders;
  MappedAsImage: Boolean;
  VirtualAddress: Cardinal;
  AddressRange: Cardinal;
  out Status: TNtxStatus
): Pointer;

// Get a data directory in an image
function RtlxGetDirectoryEntryImage(
  Base: PByte;
  ImageSize: NativeUInt;
  MappedAsImage: Boolean;
  Entry: TImageDirectoryEntry;
  out Directory: PImageDataDirectory
): TNtxStatus;

// Enumerate exported functions in an image
function RtlxEnumerateExportImage(
  Base: PByte;
  ImageSize: Cardinal;
  MappedAsImage: Boolean;
  out Entries: TArray<TExportEntry>
): TNtxStatus;

// Find an export enrty by name
function RtlxFindExportedName(
  const Entries: TArray<TExportEntry>;
  Name: AnsiString
): PExportEntry;

// Enumerate imported or delayed import of an image
function RtlxEnumerateImportImage(
  out Entries: TArray<TImportDllEntry>;
  Base: Pointer;
  ImageSize: NativeUInt;
  MappedAsImage: Boolean;
  ImportTypes: TImportTypeSet = [itNormal, itDelayed]
): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, ntapi.ntstatus, DelphiUtils.Arrays;

function RtlxGetNtHeaderImage;
begin
  try
    Result.Location := 'RtlImageNtHeaderEx';
    Result.Status := RtlImageNtHeaderEx(0, Base, ImageSize, NtHeader);
  except
    Result.Location := 'RtlxGetNtHeaderImage';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;
end;

function RtlxGetImageBitness;
begin
  case NtHeaders.OptionalHeader.Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: Is64Bit := False;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: Is64Bit := True;
  else
    Result.Location := 'RtlxGetImageBits';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;
  end;
end;

function RtlxGetSectionImage;
var
  i: Integer;
begin
  // Reproduce behavior of RtlSectionTableFromVirtualAddress with more
  // range checks
  
  if not Assigned(NtHeaders) then
  begin
    Result := RtlxGetNtHeaderImage(Base, ImageSize, NtHeaders);

    if not Result.IsSuccess then
      Exit;
  end;

  // Fail with this status if something goes wrong with range checks
  Result.Location := 'RtlxGetSectionImage';
  Result.Status := STATUS_INVALID_IMAGE_FORMAT;
  
  try
    Section := Pointer(UIntPtr(@NtHeaders.OptionalHeader) +
      NtHeaders.FileHeader.SizeOfOptionalHeader);

    for i := 0 to Integer(NtHeaders.FileHeader.NumberOfSections) - 1 do
    begin
      // Make sure the section is within the image
      if UIntPtr(Section) - UIntPtr(Base) + SizeOf(TImageSectionHeader) >
        ImageSize then
        Exit;

      // Does this virtual address belong to this section?
      if (VirtualAddress >= Section.VirtualAddress) and (VirtualAddress <
        Section.VirtualAddress + Section.SizeOfRawData) then
      begin
        // Yes, it does
        Result.Status := STATUS_SUCCESS;
        Exit;
      end;

      // Go to the next section
      Inc(Section);
    end;

  except
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;

  // The virtual address is not found within image sections
  Result.Status := STATUS_NOT_FOUND;
end;

function RtlxExpandVirtualAddress;
var
  Section: PImageSectionHeader;
begin
  if not MappedAsImage then  
  begin
    if not Assigned(NtHeaders) then
    begin
      Status := RtlxGetNtHeaderImage(Base, ImageSize, NtHeaders);
  
      if not Status.IsSuccess then
        Exit(nil);
    end;
    
    // Mapped as a file, find a section that contains this virtual address
    Status := RtlxGetSectionImage(Base, ImageSize, NtHeaders,
      VirtualAddress, Section);

    if not Status.IsSuccess then
      Exit(nil);

    // Compute the address
    Result := Base + Section.PointerToRawData - Section.VirtualAddress +
      VirtualAddress;
  end
  else
    Result := Base + VirtualAddress; // Mapped as image
  
  // Make sure the address is within the image
  if (UIntPtr(Result) + AddressRange - UIntPtr(Base) > ImageSize) or
    (PByte(Result) < Base) then
  begin
    Status.Location := 'RtlxExpandVirtualAddress';
    Status.Status := STATUS_INVALID_IMAGE_FORMAT;
  end
  else
    Status.Status := STATUS_SUCCESS;
end;

function RtlxGetDirectoryEntryImage;
var
  Header: PImageNtHeaders;
begin
  // We are going to reproduce behavior of RtlImageDirectoryEntryToData,
  // but with more range checks

  Result := RtlxGetNtHeaderImage(Base, ImageSize, Header);

  if not Result.IsSuccess then
    Exit;
    
  // If something goes wrong, fail with this Result
  Result.Location := 'RtlxGetDirectoryEntryImage';
  Result.Status := STATUS_INVALID_IMAGE_FORMAT;
  
  try    
    // Get data directory
    case Header.OptionalHeader.Magic of
      IMAGE_NT_OPTIONAL_HDR32_MAGIC:
        Directory := @Header.OptionalHeader32.DataDirectory[Entry];

      IMAGE_NT_OPTIONAL_HDR64_MAGIC:
        Directory := @Header.OptionalHeader64.DataDirectory[Entry];
    else
      // Unknown executable architecture, fail
      Exit;
    end;

    // Make sure we read data within the image
    if UIntPtr(Directory) + SizeOf(TImageDataDirectory) - UIntPtr(Base) >
      ImageSize then
      Exit;
  except
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function GetAnsiString(Start: PAnsiChar; Boundary: PByte): AnsiString;
var
  Finish: PAnsiChar;
begin
  Finish := Start;

  while (Finish < Boundary) and (Finish^ <> #0) do
    Inc(Finish);

  SetString(Result, Start, UIntPtr(Finish) - UIntPtr(Start));
end;

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
  Result := RtlxGetNtHeaderImage(Base, ImageSize, Header);

  if not Result.IsSuccess then
    Exit;

  // Find export directory data 
  Result := RtlxGetDirectoryEntryImage(Base, ImageSize, MappedAsImage,
    IMAGE_DIRECTORY_ENTRY_EXPORT, ExportData);

  if not Result.IsSuccess then
    Exit;
      
  try      
    // Check if the image has any exports
    if ExportData.VirtualAddress = 0 then
    begin
      // Nothing to parse, exit
      SetLength(Entries, 0);
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;
    
    // Make sure export directory has appropriate size
    if ExportData.Size < SizeOf(TImageExportDirectory) then
    begin
      Result.Location := 'RtlxEnumerateExportImage';
      Result.Status := STATUS_INVALID_IMAGE_FORMAT;
      Exit;
    end;
    
    // Obtain a pointer to the export directory    
    ExportDirectory := RtlxExpandVirtualAddress(Base, ImageSize, Header, 
      MappedAsImage, ExportData.VirtualAddress, SizeOf(TImageExportDirectory),
      Result);
  
    if not Result.IsSuccess then
      Exit;
    
    // Get an address of names
    Names := RtlxExpandVirtualAddress(Base, ImageSize, Header, MappedAsImage,
      ExportDirectory.AddressOfNames, ExportDirectory.NumberOfNames *
      SizeOf(Cardinal), Result);

    if not Result.IsSuccess then
      Exit;

    // Get an address of name ordinals
    Ordinals := RtlxExpandVirtualAddress(Base, ImageSize, Header, MappedAsImage,
      ExportDirectory.AddressOfNameOrdinals, ExportDirectory.NumberOfNames *
      SizeOf(Word), Result);

    if not Result.IsSuccess then
      Exit;

    // Get an address of functions
    Functions := RtlxExpandVirtualAddress(Base, ImageSize, Header, MappedAsImage,
      ExportDirectory.AddressOfFunctions, ExportDirectory.NumberOfFunctions *
      SizeOf(Cardinal), Result);

    if not Result.IsSuccess then
      Exit;

    // Fail with this status if something goes wrong
    Result.Location := 'RtlxEnumerateExportImage';
    Result.Status := STATUS_INVALID_IMAGE_FORMAT;

    // Ordinals can reference only up to 65k exported functions
    if ExportDirectory.NumberOfFunctions > High(Word) then
      Exit;

    SetLength(Entries, ExportDirectory.NumberOfNames);

    for i := 0 to High(Entries) do
    begin
      Entries[i].Ordinal := Ordinals{$R-}[i]{$R+};
    
      // Get a pointer to a name
      Name := RtlxExpandVirtualAddress(Base, ImageSize, Header, MappedAsImage,
        Names{$R-}[i]{$R+}, 0, Result);

      if Result.IsSuccess then
        Entries[i].Name := GetAnsiString(Name, Base + ImageSize);
    
      // Each ordinal is an index inside an array of functions
      if Entries[i].Ordinal >= ExportDirectory.NumberOfFunctions then
        Continue;
      
      Entries[i].VirtualAddress := Functions{$R-}[Ordinals[i]]{$R+};

      // Forwarded functions have the virtual address in the same section as
      // the export directory
      Entries[i].Forwards := (Entries[i].VirtualAddress >=
        ExportData.VirtualAddress) and (Entries[i].VirtualAddress <
        ExportData.VirtualAddress + ExportData.Size);

      if Entries[i].Forwards then
      begin
        // In case of forwarding the address actually points to the target name
        Name := RtlxExpandVirtualAddress(Base, ImageSize, Header,
          MappedAsImage, Entries[i].VirtualAddress, 0, Result);        
          
        if Result.IsSuccess then        
          Entries[i].ForwardsTo := GetAnsiString(Name, Base + ImageSize);
      end;

      { TODO: add range checks to see if the VA is within the image. Can't
        simply compare the VA to the size of an image that is mapped as a file,
        though. }
    end;
  except
    Result.Location := 'RtlxEnumerateExportImage';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function RtlxFindExportedName;
var
  Index: Integer;
begin
  // Export entries are sorted, use fast binary search
  Index := TArray.BinarySearch<TExportEntry>(Entries,
    function (const Entry: TExportEntry): Integer
    begin
      if Entry.Name = Name then
        Result := 0
      else if Entry.Name < Name then
        Result := -1
      else
        Result := 1;
    end
  );

  if Index < 0 then
    Result := nil
  else
    Result := @Entries[Index];
end;

// A worker function for enumerating image import
function RtlxpEnumerateImportImage(
  Base: PByte;
  ImageSize: NativeUInt;
  MappedAsImage: Boolean;
  ImportType: TImportType;
  out Entries: TArray<TImportDllEntry>
): TNtxStatus;
const
  IMAGE_DIRECTORY: array [TImportType] of TImageDirectoryEntry = (
    IMAGE_DIRECTORY_ENTRY_IMPORT, IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT
  );
  DESCRIPTOR_SIZE: array [TImportType] of Cardinal = (
    SizeOf(TImageImportDescriptor), SizeOf(TImageDelayLoadDescriptor)
  );
var
  Header: PImageNtHeaders;
  ImportData: PImageDataDirectory;
  ImportDescriptor: PImageImportDescriptor;
  DelayImportDescriptor: PImageDelayLoadDescriptor absolute ImportDescriptor;
  Is64Bit: Boolean;
  UnboundIAT: Pointer;
  DllNameRVA, TableRVA, IATEntrySize: Cardinal;
  pDllName: PAnsiChar;
  ByName: PImageImportByName;
label
  Fail;
begin
  Result := RtlxGetNtHeaderImage(Base, ImageSize, Header);

  if not Result.IsSuccess then
    Exit;

  // Find import directory data
  Result := RtlxGetDirectoryEntryImage(Base, ImageSize, MappedAsImage,
    IMAGE_DIRECTORY[ImportType], ImportData);

  if not Result.IsSuccess then
    Exit;

  try
    // Check if the image has any imports
    if ImportData.VirtualAddress = 0 then
    begin
      // Nothing to parse, exit
      SetLength(Entries, 0);
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    // Make sure import directory has appropriate size
    if ImportData.Size < DESCRIPTOR_SIZE[ImportType] then
    begin
      Result.Location := 'RtlxEnumerateImportImage';
      Result.Status := STATUS_INVALID_IMAGE_FORMAT;
      Exit;
    end;

    // Obtain a pointer to the import directory
    ImportDescriptor := RtlxExpandVirtualAddress(Base, ImageSize, Header,
      MappedAsImage, ImportData.VirtualAddress, DESCRIPTOR_SIZE[ImportType],
      Result);

    SetLength(Entries, 0);

    // The structure of import depends on image bitness
    Result := RtlxGetImageBitness(Header, Is64Bit);

    if not Result.IsSuccess then
      Exit;

    if Is64Bit then
      IATEntrySize := SizeOf(UInt64)
    else
      IATEntrySize := SizeOf(Cardinal);

    while ((ImportType = itNormal) and (ImportDescriptor.Name <> 0)) or
       ((ImportType = itDelayed) and (DelayImportDescriptor.DllNameRVA <> 0)) do
    begin
      SetLength(Entries, Length(Entries) + 1);

      with Entries[High(Entries)] do
      begin
        if ImportType = itNormal then
          DllNameRVA := ImportDescriptor.Name
        else
          DllNameRVA := DelayImportDescriptor.DllNameRVA;

        // Locate the DLL name string
        pDllName := RtlxExpandVirtualAddress(Base, ImageSize, Header,
          MappedAsImage, DllNameRVA, SizeOf(AnsiChar), Result);

        if not Result.IsSuccess then
          Exit;

        // Save DLL name and IAT RVA
        DllName := GetAnsiString(pDllName, Base + ImageSize);

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

        // Locate import name table
        UnboundIAT := RtlxExpandVirtualAddress(Base, ImageSize, Header,
          MappedAsImage, TableRVA, IATEntrySize, Result);

        if not Result.IsSuccess then
          Exit;

        // Iterate through the name table
        while (Is64Bit and (UInt64(UnboundIAT^) <> 0)) or
          (not Is64Bit and (Cardinal(UnboundIAT^) <> 0)) do
        begin
          SetLength(Functions, Length(Functions) + 1);

          with Functions[High(Functions)] do
          begin
            DelayedImport := ImportType = itDelayed;

            if Is64Bit then
              ImportByName := UInt64(UnboundIAT^) and (UInt64(1) shl 63) = 0
            else
              ImportByName := Cardinal(UnboundIAT^) and (1 shl 31) = 0;

            if ImportByName then
            begin
              // Locate function name
              ByName := RtlxExpandVirtualAddress(Base, ImageSize, Header,
                MappedAsImage, Cardinal(UnboundIAT^),
                SizeOf(TImageImportByName), Result);

              if not Result.IsSuccess then
                Exit;

              Name := GetAnsiString(@ByName.Name[0], Base + ImageSize);
            end
            else
              Ordinal := Word(UnboundIAT^) // Import by ordinal
          end;

          UnboundIAT := PByte(UnboundIAT) + IATEntrySize;

          // Make sure the next element belongs to the image
          if PByte(UnboundIAT) + IATEntrySize > Base + ImageSize then
            goto Fail;
        end;

        // Make sure the whole IAT section for this DLL belongs to the image
        if MappedAsImage and (IAT + IATEntrySize * Cardinal(Length(Functions)) >
          ImageSize) then
          goto Fail;
      end;

      // Move to the next DLL
      if ImportType = itNormal then
        Inc(ImportDescriptor)
      else
        Inc(DelayImportDescriptor);

      // Make sure it is still within the image
      if UIntPtr(ImportDescriptor) - UIntPtr(Base) >= ImageSize then
      begin
      Fail:
        Result.Location := 'RtlxEnumerateImportImage';
        Result.Status := STATUS_INVALID_IMAGE_FORMAT;
        Exit;
      end;
    end;
  except
    Result.Location := 'RtlxEnumerateImportImage';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function RtlxEnumerateImportImage;
var
  PerTypeEntries: TArray<TImportDllEntry>;
  ImportType: TImportType;
begin
  Entries := nil;

  for ImportType in ImportTypes do
  begin
    Result := RtlxpEnumerateImportImage(Base, ImageSize, MappedAsImage,
      ImportType, PerTypeEntries);

    if not Result.IsSuccess then
    begin
      Entries := nil;
      Exit;
    end;

    Entries := Entries + PerTypeEntries;
  end;
end;

end.
