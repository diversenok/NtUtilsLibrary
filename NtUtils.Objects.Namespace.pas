unit NtUtils.Objects.Namespace;

interface

uses
  Winapi.WinNt, Ntapi.ntobapi, Ntapi.ntseapi, NtUtils, NtUtils.Objects;

type
  TDirectoryEnumEntry = record
    Name: String;
    TypeName: String;
  end;

  { Directories }

// Get an object manager's namespace path for a token (supports pseudo-handles)
function RtlxGetNamedObjectPath(out Path: String; hToken: THandle): TNtxStatus;

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
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb, NtUtils.Ldr,
  NtUtils.Tokens.Query, NtUtils.SysUtils, DelphiUtils.AutoObject;

function RtlxGetNamedObjectPath(out Path: String; hToken: THandle): TNtxStatus;
var
  SessionId: Cardinal;
  ObjectPath: TNtUnicodeString;
begin
  Result := LdrxCheckNtDelayedImport('RtlGetTokenNamedObjectPath');

  if not Result.IsSuccess then
  begin
    // AppContainers are not supported, obtain
    // the current session and construct the path manually.

    if hToken = NtCurrentProcessToken then
    begin
      // Process session does not change
      SessionId := RtlGetCurrentPeb.SessionId;
      Result.Status := STATUS_SUCCESS;
    end
    else
      Result := NtxToken.Query(hToken, TokenSessionId, SessionId);

    if Result.IsSuccess then
      Path := '\Sessions\' + RtlxIntToStr(SessionId) + '\BaseNamedObjects';
  end
  else
  begin
    FillChar(ObjectPath, SizeOf(ObjectPath), 0);

    Result.Location := 'RtlGetTokenNamedObjectPath';
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);

    Result.Status := RtlGetTokenNamedObjectPath(hToken, nil, ObjectPath);

    if Result.IsSuccess then
    begin
      Path := ObjectPath.ToString;
      RtlFreeUnicodeString(ObjectPath);
    end;
  end;
end;

function NtxCreateDirectory(out hxDirectory: IHandle; Name: String;
  DesiredAccess: TAccessMask; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  hDirectory: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(Name).RefOrNull,
    Attributes, Root);

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
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(Name).RefOrNull,
    Attributes, Root);

  Result.Location := 'NtOpenDirectoryObject';
  Result.LastCall.AttachAccess<TDirectoryAccessMask>(DesiredAccess);

  Result.Status := NtOpenDirectoryObject(hDirectory, DesiredAccess, ObjAttr);

  if Result.IsSuccess then
    hxDirectory := TAutoHandle.Capture(hDirectory);
end;

function NtxEnumerateDirectory(hDirectory: THandle;
  out Entries: TArray<TDirectoryEnumEntry>): TNtxStatus;
var
  xMemory: IMemory<PObjectDirectoryInformation>;
  Required, Context: Cardinal;
begin
  Result.Location := 'NtQueryDirectoryObject';
  Result.LastCall.Expects<TDirectoryAccessMask>(DIRECTORY_QUERY);

  Context := 0;
  SetLength(Entries, 0);
  repeat
    // Retrive entries one by one

    xMemory := TAutoMemory<PObjectDirectoryInformation>.Allocate(
      RtlGetLongestNtPathLength);

    repeat
      Required := 0;
      Result.Status := NtQueryDirectoryObject(hDirectory, xMemory.Data,
        xMemory.Size, True, False, Context, @Required);
    until not NtxExpandBufferEx(Result, IMemory(xMemory), Required, nil);

    if Result.IsSuccess then
    begin
      SetLength(Entries, Length(Entries) + 1);
      Entries[High(Entries)].Name := xMemory.Data.Name.ToString;
      Entries[High(Entries)].TypeName := xMemory.Data.TypeName.ToString;
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
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(Name).RefOrNull,
    Attributes, Root);

  Result.Location := 'NtCreateSymbolicLinkObject';
  Result.Status := NtCreateSymbolicLinkObject(hSymlink, DesiredAccess, ObjAttr,
    TNtUnicodeString.From(Target));

  if Result.IsSuccess then
    hxSymlink := TAutoHandle.Capture(hSymlink);
end;

function NtxOpenSymlink(out hxSymlink: IHandle; Name: String; DesiredAccess:
  TAccessMask; Root: THandle = 0; Attributes: Cardinal = 0): TNtxStatus;
var
  hSymlink: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(Name).RefOrNull,
    Attributes, Root);

  Result.Location := 'NtOpenSymbolicLinkObject';
  Result.LastCall.AttachAccess<TSymlinkAccessMask>(DesiredAccess);
  Result.Status := NtOpenSymbolicLinkObject(hSymlink, DesiredAccess, ObjAttr);

  if Result.IsSuccess then
    hxSymlink := TAutoHandle.Capture(hSymlink);
end;

function NtxQueryTargetSymlink(hSymlink: THandle; out Target: String)
  : TNtxStatus;
var
  xMemory: IMemory;
  Str: TNtUnicodeString;
  Required: Cardinal;
begin
  Result.Location := 'NtQuerySymbolicLinkObject';
  Result.LastCall.Expects<TSymlinkAccessMask>(SYMBOLIC_LINK_QUERY);

  xMemory := TAutoMemory.Allocate(RtlGetLongestNtPathLength);
  repeat
    // Describe the string
    Str.Buffer := xMemory.Data;
    Str.MaximumLength := xMemory.Size;
    Str.Length := 0;

    Required := 0;
    Result.Status := NtQuerySymbolicLinkObject(hSymlink, Str, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, nil);

  if Result.IsSuccess then
    Target := Str.ToString;
end;

end.
