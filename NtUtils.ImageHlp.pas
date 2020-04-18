unit NtUtils.ImageHlp;

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

// Get an NT header of an image
function RtlxGetNtHeaderImage(Base: PByte; ImageSize: NativeUInt;
  out NtHeader: PImageNtHeaders): TNtxStatus;

// Get a section that contains a virtual address
function RtlxGetSectionImage(Base: PByte; ImageSize: NativeUInt; NtHeaders:
  PImageNtHeaders; VirtualAddress: Cardinal; out Section: PImageSectionHeader):
  TNtxStatus;

// Get a pointer to a virtual address in an image
function RtlxExpandVirtualAddress(Base: PByte; ImageSize: NativeUInt;
  NtHeaders: PImageNtHeaders; MappedAsImage: Boolean; VirtualAddress: Cardinal;
  AddressRange: Cardinal; out Status: TNtxStatus): Pointer;

// Get a data directory in an image
function RtlxGetDirectoryEntryImage(Base: PByte; ImageSize: NativeUInt;
  MappedAsImage: Boolean; Entry: TImageDirectoryEntry; out Directory:
  PImageDataDirectory): TNtxStatus;

// Enumerate exported functions in a dll
function RtlxEnumerateExportImage(Base: PByte; ImageSize: Cardinal;
  MappedAsImage: Boolean; out Entries: TArray<TExportEntry>): TNtxStatus;

// Find an export enrty by name
function RtlxFindExportedName(const Entries: TArray<TExportEntry>;
  Name: AnsiString): PExportEntry;

function GetAnsiString(Start: PAnsiChar; Boundary: PByte): AnsiString;

implementation

uses
  Ntapi.ntrtl, ntapi.ntstatus, DelphiUtils.Arrays;

function RtlxGetNtHeaderImage(Base: PByte; ImageSize: NativeUInt;
  out NtHeader: PImageNtHeaders): TNtxStatus;
begin
  try
    Result.Location := 'RtlImageNtHeaderEx';
    Result.Status := RtlImageNtHeaderEx(0, Base, ImageSize, NtHeader);
  except
    Result.Location := 'RtlxGetNtHeaderImage';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;
end;

function RtlxGetSectionImage(Base: PByte; ImageSize: NativeUInt; NtHeaders:
  PImageNtHeaders; VirtualAddress: Cardinal; out Section: PImageSectionHeader)
  : TNtxStatus;
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

function RtlxExpandVirtualAddress(Base: PByte; ImageSize: NativeUInt;
  NtHeaders: PImageNtHeaders; MappedAsImage: Boolean; VirtualAddress: Cardinal;
  AddressRange: Cardinal; out Status: TNtxStatus): Pointer;
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
    Result := Pointer(NativeUInt(Base) + VirtualAddress); // Mapped as image
  
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

function RtlxGetDirectoryEntryImage(Base: PByte; ImageSize: NativeUInt;
  MappedAsImage: Boolean; Entry: TImageDirectoryEntry; out Directory:
  PImageDataDirectory): TNtxStatus;
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
    if UIntPtr(Directory) + SizeOf(TImageDataDirectory) - NativeUInt(Base) >
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

  SetAnsiString(@Result, Start, UIntPtr(Finish) - UIntPtr(Start), 0);
end;

function RtlxEnumerateExportImage(Base: PByte; ImageSize: Cardinal;
  MappedAsImage: Boolean; out Entries: TArray<TExportEntry>): TNtxStatus;
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

function RtlxFindExportedName(const Entries: TArray<TExportEntry>;
  Name: AnsiString): PExportEntry;
var
  Index: Integer;
begin
  // Export entries are sorted, use fast binary search
  Index := TArrayHelper.BinarySearch<TExportEntry>(Entries,
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

end.
