unit NtUtils.Sections;

interface

uses
  Winapi.WinNt, Ntapi.ntmmapi, NtUtils, NtUtils.Objects, DelphiUtils.AutoObject;

// Create a section
function NtxCreateSection(out hxSection: IHandle; hFile: THandle;
  MaximumSize: UInt64; PageProtection: Cardinal; AllocationAttributes:
  Cardinal = SEC_COMMIT; ObjectName: String = ''; RootDirectory: THandle = 0;
  HandleAttributes: Cardinal = 0): TNtxStatus;

// Open a section
function NtxOpenSection(out hxSection: IHandle; DesiredAccess: TAccessMask;
  ObjectName: String; RootDirectory: THandle = 0; HandleAttributes
  : Cardinal = 0): TNtxStatus;

// Map a section
function NtxMapViewOfSection(hSection: THandle; hProcess: THandle; var Memory:
  TMemory; Protection: Cardinal; SectionOffset: UInt64 = 0) : TNtxStatus;

// Unmap a section
function NtxUnmapViewOfSection(hProcess: THandle; Address: Pointer): TNtxStatus;

type
  NtxSection = class
    // Query fixed-size information
    class function Query<T>(hSection: THandle;
      InfoClass: TSectionInformationClass; out Buffer: T): TNtxStatus; static;
  end;

// Map a section locally
function NtxMapViewOfSectionLocal(hSection: THandle; out MappedMemory: IMemory;
  Protection: Cardinal): TNtxStatus;

// Map an image as a file using a read-only section
function RtlxMapReadonlyFile(out hxSection: IHandle; FileName: String;
  out MappedMemory: IMemory): TNtxStatus;

// Map a known dll as an image
function RtlxMapKnownDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out MappedMemory: IMemory): TNtxStatus;

// Map a system dll (tries known dlls first, than falls back to reading a file)
function RtlxMapSystemDll(out hxSection: IHandle; DllName: String; WoW64:
  Boolean; out MappedMemory: IMemory; out MappedAsImage: Boolean): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntpsapi, Ntapi.ntexapi,
  NtUtils.Access.Expected, NtUtils.Files;

type
  TLocalAutoSection<P> = class(TCustomAutoMemory<P>, IMemory<P>)
    destructor Destroy; override;
  end;

function NtxCreateSection(out hxSection: IHandle; hFile: THandle;
  MaximumSize: UInt64; PageProtection, AllocationAttributes: Cardinal;
  ObjectName: String; RootDirectory: THandle; HandleAttributes: Cardinal)
  : TNtxStatus;
var
  hSection: THandle;
  ObjAttr: TObjectAttributes;
  NameStr: UNICODE_STRING;
  pSize: PUInt64;
begin
  if ObjectName <> '' then
  begin
    NameStr.FromString(ObjectName);
    InitializeObjectAttributes(ObjAttr, @NameStr, HandleAttributes,
      RootDirectory);
  end
  else
    InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);

  if MaximumSize <> 0 then
    pSize := @MaximumSize
  else
    pSize := nil;

  // TODO: Expected file handle access
  Result.Location := 'NtCreateSection';
  Result.Status := NtCreateSection(hSection, SECTION_ALL_ACCESS, @ObjAttr,
    pSize, PageProtection, AllocationAttributes, hFile);

  if Result.IsSuccess then
    hxSection := TAutoHandle.Capture(hSection);
end;

function NtxOpenSection(out hxSection: IHandle; DesiredAccess: TAccessMask;
  ObjectName: String; RootDirectory: THandle; HandleAttributes: Cardinal):
  TNtxStatus;
var
  hSection: THandle;
  ObjAttr: TObjectAttributes;
  NameStr: UNICODE_STRING;
begin
  NameStr.FromString(ObjectName);
  InitializeObjectAttributes(ObjAttr, @NameStr, HandleAttributes,
    RootDirectory);

  Result.Location := 'NtOpenSection';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @SectionAccessType;

  Result.Status := NtOpenSection(hSection, DesiredAccess, ObjAttr);

  if Result.IsSuccess then
    hxSection := TAutoHandle.Capture(hSection);
end;

function NtxMapViewOfSection(hSection: THandle; hProcess: THandle; var Memory:
  TMemory; Protection: Cardinal; SectionOffset: UInt64) : TNtxStatus;
begin
  Result.Location := 'NtMapViewOfSection';
  RtlxComputeSectionMapAccess(Result.LastCall, Protection);
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtMapViewOfSection(hSection, hProcess, Memory.Address, 0, 0,
    @SectionOffset, Memory.Size, ViewUnmap, 0, Protection);
end;

function NtxUnmapViewOfSection(hProcess: THandle; Address: Pointer): TNtxStatus;
begin
  Result.Location := 'NtUnmapViewOfSection';
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);
  Result.Status := NtUnmapViewOfSection(hProcess, Address);
end;

class function NtxSection.Query<T>(hSection: THandle;
  InfoClass: TSectionInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQuerySection';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects(SECTION_QUERY, @SectionAccessType);

  Result.Status := NtQuerySection(hSection, InfoClass, @Buffer, SizeOf(Buffer),
    nil);
end;

destructor TLocalAutoSection<P>.Destroy;
begin
  if FAutoRelease then
    NtxUnmapViewOfSection(NtCurrentProcess, FAddress);
  inherited;
end;

function NtxMapViewOfSectionLocal(hSection: THandle; out MappedMemory: IMemory;
  Protection: Cardinal): TNtxStatus;
var
  Memory: TMemory;
begin
  Memory.Address := nil;
  Memory.Size := 0;

  Result := NtxMapViewOfSection(hSection, NtCurrentProcess, Memory, Protection);

  if Result.IsSuccess then
    MappedMemory := TLocalAutoSection<Pointer>.Capture(Memory.Address,
      Memory.Size);
end;

function RtlxMapReadonlyFile(out hxSection: IHandle; FileName: String;
  out MappedMemory: IMemory): TNtxStatus;
var
  hxFile: IHandle;
begin
  // Open the file
  Result := NtxOpenFile(hxFile, FILE_READ_DATA, FileName);

  if not Result.IsSuccess then
    Exit;

  // Create a section, baked by this file
  Result := NtxCreateSection(hxSection, hxFile.Handle, 0, PAGE_READONLY);

  if not Result.IsSuccess then
    Exit;

  // Map the section
  Result := NtxMapViewOfSectionLocal(hxSection.Handle, MappedMemory,
    PAGE_READONLY);
end;

function RtlxMapKnownDll(out hxSection: IHandle; DllName: String;
  WoW64: Boolean; out MappedMemory: IMemory): TNtxStatus;
begin
  if Wow64 then
    DllName := '\KnownDlls32\' + DllName
  else
    DllName := '\KnownDlls\' + DllName;

  // Open a known-dll section
  Result := NtxOpenSection(hxSection, SECTION_MAP_READ or SECTION_QUERY,
    DllName);

  if not Result.IsSuccess then
    Exit;

  // Map it
  Result := NtxMapViewOfSectionLocal(hxSection.Handle, MappedMemory,
    PAGE_READONLY);
end;

function RtlxMapSystemDll(out hxSection: IHandle; DllName: String; WoW64:
  Boolean; out MappedMemory: IMemory; out MappedAsImage: Boolean): TNtxStatus;
begin
  // Try known dlls first
  Result := RtlxMapKnownDll(hxSection, DllName, WoW64, MappedMemory);

  if Result.IsSuccess then
    MappedAsImage := True
  else
  begin
    // There is no such known dll, read the file from the disk
    MappedAsImage := False;

    if WoW64 then
      DllName := USER_SHARED_DATA.NtSystemRoot + '\SysWoW64\' + DllName
    else
      DllName := USER_SHARED_DATA.NtSystemRoot + '\System32\' + DllName;

    // Convert the path to NT format
    Result := RtlxDosPathToNtPathVar(DllName);

    // Map the file
    if Result.IsSuccess then
      Result := RtlxMapReadonlyFile(hxSection, DllName, MappedMemory);
  end;
end;

end.
