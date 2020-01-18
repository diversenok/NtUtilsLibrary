unit NtUtils.ImageHlp.Map;

interface

uses
  NtUtils.Exceptions, NtUtils.Objects, NtUtils.ImageHlp, NtUtils.Sections;

type
  TMemoryRange = NtUtils.Sections.TMemoryRange;

// Map an image as a file using a read-only section
function RtlxMapFile(out hxSection: IHandle; FileName: String;
  out Memory: TMemoryRange): TNtxStatus;

// Map a known dll as an image
function RtlxMapKnownDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out Memory: TMemoryRange): TNtxStatus;

// Map a system dll (tries known dlls first, than falls back to reading a file)
function RtlxMapSystemDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out Memory: TMemoryRange; out MappedAsImage: Boolean)
  : TNtxStatus;

// Enumerate export of an executable file
function RtlxEnumerateExportFile(FileName: String;
  out Entries: TArray<TExportEntry>): TNtxStatus;

// Enumerate export of a system dll
function RtlxEnumerateExportSystemDll(DllName: String; WoW64: Boolean;
  out Entries: TArray<TExportEntry>): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntmmapi, Ntapi.ntioapi, NtUtils.Files,
  NtUtils.Environment;

function RtlxMapFile(out hxSection: IHandle; FileName: String;
  out Memory: TMemoryRange): TNtxStatus;
var
  hxFile: IHandle;
begin
  // Open the file, create the section baked by this file, map it
  Result := NtxOpenFile(hxFile, FILE_READ_DATA, FileName);

  if Result.IsSuccess then
    Result := NtxCreateSection(hxSection, hxFile.Handle, 0, PAGE_READONLY);

  Memory.Address := nil;
  Memory.RegionSize := 0;

  if Result.IsSuccess then
    Result := NtxMapViewOfSection(hxSection.Handle, NtCurrentProcess, Memory,
      PAGE_READONLY);
end;

function RtlxMapKnownDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out Memory: TMemoryRange): TNtxStatus;
begin
  if Wow64 then
    DllName := '\KnownDlls32\' + DllName
  else
    DllName := '\KnownDlls\' + DllName;

  Result := NtxOpenSection(hxSection, SECTION_MAP_READ or SECTION_QUERY,
    DllName);

  Memory.Address := nil;
  Memory.RegionSize := 0;

  if Result.IsSuccess then
    Result := NtxMapViewOfSection(hxSection.Handle, NtCurrentProcess,
      Memory, PAGE_READONLY);
end;

function RtlxMapSystemDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out Memory: TMemoryRange; out MappedAsImage: Boolean)
  : TNtxStatus;
begin
  // Try known dlls first
  Result := RtlxMapKnownDll(hxSection, DllName, WoW64, Memory);

  if Result.IsSuccess then
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
    Result := RtlxExpandStringVar(DllName);

    // Convert the path to NT format
    if Result.IsSuccess then
      Result := RtlxDosPathToNtPathVar(DllName);

    // Map the file
    if Result.IsSuccess then
      Result := RtlxMapFile(hxSection, DllName, Memory);
  end;
end;

function RtlxEnumerateExportFile(FileName: String;
  out Entries: TArray<TExportEntry>): TNtxStatus;
var
  hxSection: IHandle;
  Memory: TMemoryRange;
begin
  // Map the file
  Result := RtlxMapFile(hxSection, FileName, Memory);

  if Result.IsSuccess then
  begin
    // Enumerate export
    Result := RtlxEnumerateExportImage(Memory.Address, Memory.RegionSize,
      False, Entries);

    // Unmap the section
    NtxUnmapViewOfSection(NtCurrentProcess, Memory.Address);
  end;
end;

function RtlxEnumerateExportSystemDll(DllName: String; WoW64: Boolean;
  out Entries: TArray<TExportEntry>): TNtxStatus;
var
  hxSection: IHandle;
  MappedAsImage: Boolean;
  Memory: TMemoryRange;
begin
  // Map the dll
  Result := RtlxMapSystemDll(hxSection, DllName, WoW64, Memory, MappedAsImage);

  if Result.IsSuccess then
  begin
    // Enumerate export
    Result := RtlxEnumerateExportImage(Memory.Address, Memory.RegionSize,
      MappedAsImage, Entries);

    // Unmap the section
    NtxUnmapViewOfSection(NtCurrentProcess, Memory.Address);
  end;
end;

end.
