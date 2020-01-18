unit NtUtils.Sections;

interface

uses
  Winapi.WinNt, Ntapi.ntmmapi, NtUtils.Exceptions, NtUtils.Objects,
  NtUtils.Processes.Memory;

type
  TMemoryRange = NtUtils.Processes.Memory.TMemoryRange;

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
  TMemoryRange; Protection: Cardinal; SectionOffset: UInt64 = 0) : TNtxStatus;

// Unmap a section
function NtxUnmapViewOfSection(hProcess: THandle; Address: Pointer): TNtxStatus;

type
  NtxSection = class
    // Query fixed-size information
    class function Query<T>(hSection: THandle;
      InfoClass: TSectionInformationClass; out Buffer: T): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpsapi, NtUtils.Access.Expected;

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
  TMemoryRange; Protection: Cardinal; SectionOffset: UInt64) : TNtxStatus;
begin
  Result.Location := 'NtMapViewOfSection';
  RtlxComputeSectionMapAccess(Result.LastCall, Protection);
  Result.LastCall.Expects(PROCESS_VM_OPERATION, @ProcessAccessType);

  Result.Status := NtMapViewOfSection(hSection, hProcess, Memory.Address, 0, 0,
    @SectionOffset, Memory.RegionSize, ViewUnmap, 0, Protection);
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
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TSectionInformationClass);
  Result.LastCall.Expects(SECTION_QUERY, @SectionAccessType);

  Result.Status := NtQuerySection(hSection, InfoClass, @Buffer, SizeOf(Buffer),
    nil);
end;

end.
