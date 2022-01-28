unit NtUtils.Objects.Namespace;

{
  The module include various functions for working with Object Manager's
  namespace.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntobapi, Ntapi.ntseapi, NtUtils, NtUtils.Objects,
    DelphiUtils.AutoObjects;

type
  IBoundaryDescriptor = IMemory<PObjectBoundaryDescriptor>;

  TDirectoryEnumEntry = record
    Name: String;
    TypeName: String;
  end;

  { Directories }

// Get an object manager's namespace path
function RtlxGetNamedObjectPath(
  out Path: String;
  [opt, Access(TOKEN_QUERY)] hxToken: IHandle = nil
): TNtxStatus;

// Create directory object
function NtxCreateDirectory(
  out hxDirectory: IHandle;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open directory object
function NtxOpenDirectory(
  out hxDirectory: IHandle;
  const Name: String;
  DesiredAccess: TDirectoryAccessMask;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Enumerate named objects in a directory
function NtxEnumerateDirectory(
  [Access(DIRECTORY_QUERY)] hDirectory: THandle;
  out Entries: TArray<TDirectoryEnumEntry>
): TNtxStatus;

  { Private namespaces }

// Create a boundary descriptor for defining a private namespace
function RtlxCreateBoundaryDescriptor(
  out BoundaryDescriptor: IBoundaryDescriptor;
  const BoundaryName: String;
  [opt] const BoundarySIDs: TArray<ISid> = nil;
  [opt] const BoundaryIL: ISid = nil;
  AddAppContainerSid: Boolean = False
): TNtxStatus;

// Create a private namespace directory
function NtxCreatePrivateNamespace(
  out hxNamespace: IHandle;
  const BoundaryDescriptor: IBoundaryDescriptor;
  [opt] const Attributes: IObjectAttributes = nil;
  RegisterNamespace: Boolean = True
): TNtxStatus;

// Open an existing private namespace directory
function NtxOpenPrivateNamespace(
  out hxNamespace: IHandle;
  const BoundaryDescriptor: IBoundaryDescriptor;
  AccessMask: TDirectoryAccessMask;
  [opt] const Attributes: IObjectAttributes = nil
): TNtxStatus;

  { Symbolic links }

// Create symbolic link
function NtxCreateSymlink(
  out hxSymlink: IHandle;
  const Name: String;
  const Target: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open symbolic link
function NtxOpenSymlink(
  out hxSymlink: IHandle;
  const Name: String;
  DesiredAccess: TSymlinkAccessMask;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Get symbolic link target
function NtxQueryTargetSymlink(
  [Access(SYMBOLIC_LINK_QUERY)] hSymlink: THandle;
  out Target: String
): TNtxStatus;

type
  NtxSymlink = class abstract
    // Set information for object manager symbolic link object
    [RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
    class function &Set<T>(
      [Access(SYMBOLIC_LINK_SET)] hSymlink: THandle;
      InfoClass: TLinkInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb, NtUtils.Ldr,
  NtUtils.Tokens, NtUtils.Tokens.Info, NtUtils.SysUtils;

function RtlxGetNamedObjectPath;
var
  SessionId: TSessionId;
  ObjectPath: TNtUnicodeString;
begin
  // Uses the current process token by default
  if not Assigned(hxToken) then
    hxToken := NtxCurrentProcessToken;

  Result := LdrxCheckNtDelayedImport('RtlGetTokenNamedObjectPath');

  if not Result.IsSuccess then
  begin
    // AppContainers are not supported, obtain
    // the current session and construct the path manually.

    if hxToken.Handle = NtCurrentProcessToken then
    begin
      // Process session does not change
      SessionId := RtlGetCurrentPeb.SessionId;
      Result.Status := STATUS_SUCCESS;
    end
    else
      Result := NtxToken.Query(hxToken, TokenSessionId, SessionId);

    if Result.IsSuccess then
      Path := '\Sessions\' + RtlxUIntToStr(SessionId) + '\BaseNamedObjects';
  end
  else
  begin
    FillChar(ObjectPath, SizeOf(ObjectPath), 0);

    // This function uses only NtQueryInformationToken under the hood and,
    // therefore, supports token pseudo-handles
    Result.Location := 'RtlGetTokenNamedObjectPath';
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);

    Result.Status := RtlGetTokenNamedObjectPath(hxToken.Handle, nil,
      ObjectPath);

    if Result.IsSuccess then
    begin
      Path := ObjectPath.ToString;
      RtlFreeUnicodeString(ObjectPath);
    end;
  end;
end;

function NtxCreateDirectory;
var
  hDirectory: THandle;
begin
  Result.Location := 'NtCreateDirectoryObject';
  Result.Status := NtCreateDirectoryObject(
    hDirectory,
    AccessMaskOverride(DIRECTORY_ALL_ACCESS, ObjectAttributes),
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^
  );

  if Result.IsSuccess then
    hxDirectory := NtxObject.Capture(hDirectory);
end;

function NtxOpenDirectory;
var
  hDirectory: THandle;
begin
  Result.Location := 'NtOpenDirectoryObject';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtOpenDirectoryObject(
    hDirectory,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^
  );

  if Result.IsSuccess then
    hxDirectory := NtxObject.Capture(hDirectory);
end;

function NtxEnumerateDirectory;
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

    IMemory(xMemory) := Auto.AllocateDynamic(RtlGetLongestNtPathLength);
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

type
  TAutoBoundaryDescriptor = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

  TAutoPrivateNamespace = class (TCustomAutoHandle, IHandle)
    procedure Release; override;
  end;

procedure TAutoBoundaryDescriptor.Release;
begin
  RtlDeleteBoundaryDescriptor(FData);
  inherited;
end;

procedure TAutoPrivateNamespace.Release;
begin
  NtDeletePrivateNamespace(FHandle);
  NtxClose(FHandle);
  inherited;
end;

function RtlxCreateBoundaryDescriptor;
var
  pBoundary: PObjectBoundaryDescriptor;
  BoundaryObj: TAutoBoundaryDescriptor;
  Flags: TBoundaryDescriptorFlags;
  i: Integer;
begin
  if AddAppContainerSid then
    Flags := BOUNDARY_DESCRIPTOR_ADD_APPCONTAINER_SID
  else
    Flags := 0;

  // Allocate a named boundary descriptor
  pBoundary := RtlCreateBoundaryDescriptor(TNtUnicodeString.From(BoundaryName),
    Flags);

  if not Assigned(pBoundary) then
  begin
    Result.Location := 'RtlCreateBoundaryDescriptor';
    Result.Status := STATUS_NO_MEMORY;
    Exit;
  end;

  BoundaryObj := TAutoBoundaryDescriptor.Capture(pBoundary, 0);
  IMemory(BoundaryDescriptor) := BoundaryObj;

  // Add required SIDs
  Result.Location := 'RtlAddSIDToBoundaryDescriptor';
  for i := 0 to High(BoundarySIDs) do
  begin
    Result.Status := RtlAddSIDToBoundaryDescriptor(
      PObjectBoundaryDescriptor(BoundaryObj.FData), BoundarySIDs[i].Data);

    if not Result.IsSuccess then
      Exit;
  end;

  // Add required integrity level
  if Assigned(BoundaryIL) then
  begin
    Result.Location := 'RtlAddIntegrityLabelToBoundaryDescriptor';
    Result.Status := RtlAddIntegrityLabelToBoundaryDescriptor(
      PObjectBoundaryDescriptor(BoundaryObj.FData), BoundaryIL.Data);

    if not Result.IsSuccess then
      Exit;
  end;
end;

function NtxCreatePrivateNamespace;
var
  hNamespace: THandle;
begin
  Result.Location := 'NtCreatePrivateNamespace';
  Result.Status := NtCreatePrivateNamespace(
    hNamespace,
    AccessMaskOverride(DIRECTORY_ALL_ACCESS, Attributes),
    AttributesRefOrNil(Attributes),
    BoundaryDescriptor.Data
  );

  if not Result.IsSuccess then
    Exit;

  if not RegisterNamespace then
  begin
    // Delete now, making inaccessible via a boundary descriptor
    NtDeletePrivateNamespace(hNamespace);
    hxNamespace := NtxObject.Capture(hNamespace);
  end
  else
    // Delete on close
    hxNamespace := TAutoPrivateNamespace.Capture(hNamespace)
end;

function NtxOpenPrivateNamespace;
var
  hNamespace: THandle;
begin
  Result.Location := 'NtOpenPrivateNamespace';
  Result.LastCall.OpensForAccess(AccessMask);

  Result.Status := NtOpenPrivateNamespace(
    hNamespace,
    AccessMask,
    AttributesRefOrNil(Attributes),
    BoundaryDescriptor.Data
  );

  if Result.IsSuccess then
    hxNamespace := NtxObject.Capture(hNamespace);
end;

function NtxCreateSymlink;
var
  hSymlink: THandle;
begin
  Result.Location := 'NtCreateSymbolicLinkObject';
  Result.Status := NtCreateSymbolicLinkObject(
    hSymlink,
    AccessMaskOverride(SYMBOLIC_LINK_ALL_ACCESS, ObjectAttributes),
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^,
    TNtUnicodeString.From(Target)
  );

  if Result.IsSuccess then
    hxSymlink := NtxObject.Capture(hSymlink);
end;

function NtxOpenSymlink;
var
  hSymlink: THandle;
begin
  Result.Location := 'NtOpenSymbolicLinkObject';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtOpenSymbolicLinkObject(
    hSymlink,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^
  );

  if Result.IsSuccess then
    hxSymlink := NtxObject.Capture(hSymlink);
end;

function NtxQueryTargetSymlink;
var
  xMemory: IMemory;
  Str: TNtUnicodeString;
  Required: Cardinal;
begin
  Result.Location := 'NtQuerySymbolicLinkObject';
  Result.LastCall.Expects<TSymlinkAccessMask>(SYMBOLIC_LINK_QUERY);

  xMemory := Auto.AllocateDynamic(RtlGetLongestNtPathLength);
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

class function NtxSymlink.&Set<T>;
begin
  Result.Location := 'NtSetInformationSymbolicLink';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TSymlinkAccessMask>(SYMBOLIC_LINK_SET);
  Result.Status := NtSetInformationSymbolicLink(hSymlink, InfoClass, @Buffer,
    SizeOf(Buffer));
end;

end.
