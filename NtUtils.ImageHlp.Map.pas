unit NtUtils.ImageHlp.Map;

interface

uses
  NtUtils.Exceptions, NtUtils.Objects, NtUtils.ImageHlp;

// Map an image as a file using a read-only section
function RtlxMapFile(out hxSection: IHandle; FileName: String;
  out Status: TNtxStatus): Pointer;

// Map a known dll as an image
function RtlxMapKnownDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out Status: TNtxStatus): Pointer;

// Map a system dll (tries known dlls first, than falls back to reading a file)
function RtlxMapSystemDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out MappedAsImage: Boolean; out Status: TNtxStatus): Pointer;

// Enumerate export of an executable file
function RtlxEnumerateExportFile(FileName: String;
  out Entries: TArray<TExportEntry>): TNtxStatus;

// Enumerate export of a system dll
function RtlxEnumerateExportSystemDll(DllName: String; WoW64: Boolean;
  out Entries: TArray<TExportEntry>): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntmmapi, Ntapi.ntioapi, NtUtils.Files, NtUtils.Sections,
  NtUtils.Environment;

function RtlxMapFile(out hxSection: IHandle; FileName: String;
  out Status: TNtxStatus): Pointer;
var
  hxFile: IHandle;
begin
  // Open the file, create the section baked by this file, map it

  Result := nil;
  Status := NtxOpenFile(hxFile, FILE_READ_DATA, FileName);

  if Status.IsSuccess then
    Status := NtxCreateSection(hxSection, hxFile.Value, 0, PAGE_READONLY);

  if Status.IsSuccess then
    Result := NtxMapViewOfSection(hxSection.Value, NtCurrentProcess,
      PAGE_READONLY, Status);
end;

function RtlxMapKnownDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out Status: TNtxStatus): Pointer;
begin
  if Wow64 then
    DllName := '\KnownDlls32\' + DllName
  else
    DllName := '\KnownDlls\' + DllName;

  Status := NtxOpenSection(hxSection, SECTION_MAP_READ or SECTION_QUERY,
    DllName);

  if Status.IsSuccess then
    Result := NtxMapViewOfSection(hxSection.Value, NtCurrentProcess,
      PAGE_READONLY, Status)
  else
    Result := nil;
end;

function RtlxMapSystemDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out MappedAsImage: Boolean; out Status: TNtxStatus): Pointer;
begin
  // Try known dlls first
  Result := RtlxMapKnownDll(hxSection, DllName, WoW64, Status);

  if Status.IsSuccess then
    MappedAsImage := True
  else
  begin
    // There is no such known dll, read the file from the disk
    MappedAsImage := False;

    if WoW64 then
      DllName := '%SystemRoot%\SysWoW64\' + DllName
    else
      DllName := '%SystemRoot%\System32\' + DllName;

    // Expan system root
    Status := RtlxExpandStringVar(DllName);

    // Convert the path to NT format
    if Status.IsSuccess then
      Status := RtlxDosPathToNtPathVar(DllName);

    // Map the file
    if Status.IsSuccess then
      Result := RtlxMapFile(hxSection, DllName, Status);
  end;
end;

function RtlxEnumerateExportFile(FileName: String;
  out Entries: TArray<TExportEntry>): TNtxStatus;
var
  hxSection: IHandle;
  SectionInfo: TSectionBasicInformation;
  Base: Pointer;
begin
  // Map the file
  Base := RtlxMapFile(hxSection, FileName, Result);

  if not Result.IsSuccess then
    Exit;

  // Query its size
  Result := NtxSection.Query(hxSection.Value, SectionBasicInformation,
    SectionInfo);

  // Enumerate export
  if Result.IsSuccess then
    Result := RtlxEnumerateExportImage(Base, SectionInfo.MaximumSize,
      False, Entries);

  // Unmap the section
  NtxUnmapViewOfSection(NtCurrentProcess, Base);
end;

function RtlxEnumerateExportSystemDll(DllName: String; WoW64: Boolean;
  out Entries: TArray<TExportEntry>): TNtxStatus;
var
  hxSection: IHandle;
  SectionInfo: TSectionBasicInformation;
  MappedAsImage: Boolean;
  Base: Pointer;
begin
  // Map the dll
  Base := RtlxMapSystemDll(hxSection, DllName, WoW64, MappedAsImage, Result);

  if not Result.IsSuccess then
    Exit;

  // Query its size
  Result := NtxSection.Query(hxSection.Value, SectionBasicInformation,
    SectionInfo);

  // Enumerate export
  if Result.IsSuccess then
    Result := RtlxEnumerateExportImage(Base, SectionInfo.MaximumSize,
      MappedAsImage, Entries);

  // Unmap the section
  NtxUnmapViewOfSection(NtCurrentProcess, Base);
end;

end.
