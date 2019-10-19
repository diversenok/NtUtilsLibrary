unit NtUtils.Objects.Namespace;

interface

uses
  Winapi.WinNt, Ntapi.ntobapi, NtUtils.Exceptions, NtUtils.Objects;

type
  TDirectoryEnumEntry = record
    Name: String;
    TypeName: String;
  end;

  { Directories }

// Create directory object
function NtxCreateDirectory(out hxDirectory: IHandle; Name: String;
  DesiredAccess: TAccessMask = DIRECTORY_ALL_ACCESS; Root: THandle = 0;
  Attributes: Cardinal = 0): TNtxStatus;

// Open directory object
function NtxOpenDirectory(out hxDirectory: IHandle; Name: String; DesiredAccess:
  TAccessMask; Root: THandle = 0; Attributes: Cardinal = 0): TNtxStatus;

// Enumerate named objects in a directory
function NtxEnumerateDirectory(hDirectory: THandle;
  out Entries: TArray<TDirectoryEnumEntry>): TNtxStatus;

  { Symbolic links }

// Create symbolic link
function NtxCreateSymlink(out hxSymlink: IHandle; Name, Target: String;
  DesiredAccess: TAccessMask = SYMBOLIC_LINK_ALL_ACCESS; Root: THandle = 0;
  Attributes: Cardinal = 0): TNtxStatus;

// Open symbolic link
function NtxOpenSymlink(out hxSymlink: IHandle; Name: String; DesiredAccess:
  TAccessMask; Root: THandle = 0; Attributes: Cardinal = 0): TNtxStatus;

// Get symbolic link target
function NtxQueryTargetSymlink(hSymlink: THandle; out Target: String)
  : TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus;

function NtxCreateDirectory(out hxDirectory: IHandle; Name: String;
  DesiredAccess: TAccessMask; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  hDirectory: THandle;
  ObjAttr: TObjectAttributes;
  NameStr: UNICODE_STRING;
begin
  NameStr.FromString(Name);
  InitializeObjectAttributes(ObjAttr, @NameStr, Attributes, Root);

  Result.Location := 'NtCreateDirectoryObject';
  Result.Status := NtCreateDirectoryObject(hDirectory, DesiredAccess, ObjAttr);

  if Result.IsSuccess then
    hxDirectory := TAutoHandle.Capture(hDirectory);
end;

function NtxOpenDirectory(out hxDirectory: IHandle; Name: String; DesiredAccess:
  TAccessMask; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  hDirectory: THandle;
  ObjAttr: TObjectAttributes;
  NameStr: UNICODE_STRING;
begin
  NameStr.FromString(Name);
  InitializeObjectAttributes(ObjAttr, @NameStr, Attributes, Root);

  Result.Location := 'NtOpenDirectoryObject';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @DirectoryAccessType;

  Result.Status := NtOpenDirectoryObject(hDirectory, DesiredAccess, ObjAttr);

  if Result.IsSuccess then
    hxDirectory := TAutoHandle.Capture(hDirectory);
end;

function NtxEnumerateDirectory(hDirectory: THandle;
  out Entries: TArray<TDirectoryEnumEntry>): TNtxStatus;
var
  Buffer: PObjectDirectoryInformation;
  BufferSize, Required, Context: Cardinal;
begin
  Result.Location := 'NtQueryDirectoryObject';
  Result.LastCall.Expects(DIRECTORY_QUERY, @DirectoryAccessType);

  // TODO: check, if there is a more efficient way to get directory content

  Context := 0;
  SetLength(Entries, 0);
  repeat
    // Retrive entries one by one

    BufferSize := 256;
    repeat
      Buffer := AllocMem(BufferSize);

      Result.Status := NtQueryDirectoryObject(hDirectory, Buffer, BufferSize,
        True, False, Context, @Required);

      if not Result.IsSuccess then
        FreeMem(Buffer);

    until not NtxExpandBuffer(Result, BufferSize, Required);

    if Result.IsSuccess then
    begin
      SetLength(Entries, Length(Entries) + 1);
      Entries[High(Entries)].Name := Buffer.Name.ToString;
      Entries[High(Entries)].TypeName := Buffer.TypeName.ToString;

      FreeMem(Buffer);
      Result.Status := STATUS_MORE_ENTRIES;
    end;

  until Result.Status <> STATUS_MORE_ENTRIES;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

function NtxCreateSymlink(out hxSymlink: IHandle; Name, Target: String;
  DesiredAccess: TAccessMask; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  hSymlink: THandle;
  ObjAttr: TObjectAttributes;
  NameStr, TargetStr: UNICODE_STRING;
begin
  NameStr.FromString(Name);
  TargetStr.FromString(Target);
  InitializeObjectAttributes(ObjAttr, @NameStr, Attributes, Root);

  Result.Location := 'NtCreateSymbolicLinkObject';
  Result.Status := NtCreateSymbolicLinkObject(hSymlink, DesiredAccess, ObjAttr,
    TargetStr);

  if Result.IsSuccess then
    hxSymlink := TAutoHandle.Capture(hSymlink);
end;

function NtxOpenSymlink(out hxSymlink: IHandle; Name: String; DesiredAccess:
  TAccessMask; Root: THandle = 0; Attributes: Cardinal = 0): TNtxStatus;
var
  hSymlink: THandle;
  ObjAttr: TObjectAttributes;
  NameStr: UNICODE_STRING;
begin
  NameStr.FromString(Name);
  InitializeObjectAttributes(ObjAttr, @NameStr, Attributes, Root);

  Result.Location := 'NtOpenSymbolicLinkObject';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @SymlinkAccessType;
  Result.Status := NtOpenSymbolicLinkObject(hSymlink, DesiredAccess, ObjAttr);

  if Result.IsSuccess then
    hxSymlink := TAutoHandle.Capture(hSymlink);
end;

function NtxQueryTargetSymlink(hSymlink: THandle; out Target: String)
  : TNtxStatus;
var
  Buffer: UNICODE_STRING;
  Required: Cardinal;
begin
  Result.Location := 'NtQuerySymbolicLinkObject';
  Result.LastCall.Expects(SYMBOLIC_LINK_QUERY, @SymlinkAccessType);

  Buffer.MaximumLength := 0;
  repeat
    Required := 0;
    Buffer.Length := 0;
    Buffer.Buffer := AllocMem(Buffer.MaximumLength);

    Result.Status := NtQuerySymbolicLinkObject(hSymlink, Buffer, @Required);

    if not Result.IsSuccess then
      FreeMem(Buffer.Buffer);

  until not NtxExpandStringBuffer(Result, Buffer, Required);

  if Result.IsSuccess then
  begin
    Target := Buffer.ToString;
    FreeMem(Buffer.Buffer);
  end;
end;

end.
