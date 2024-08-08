unit NtUtils.Objects.Namespace;

{
  The module include various functions for working with Object Manager's
  namespace.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntobapi, Ntapi.ntseapi, NtUtils, NtUtils.Objects,
  DelphiUtils.AutoObjects, DelphiApi.Reflection;

const
  DIRECTORY_SHADOW = DIRECTORY_QUERY or DIRECTORY_TRAVERSE;

type
  IBoundaryDescriptor = IMemory<PObjectBoundaryDescriptor>;

  TNtxDirectoryEntry = record
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

// Create directory object using extended parameters
function NtxCreateDirectoryEx(
  out hxDirectory: IHandle;
  const Name: String;
  [opt, Access(DIRECTORY_SHADOW)] const hxShadowDirectory: IHandle = nil;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open directory object
function NtxOpenDirectory(
  out hxDirectory: IHandle;
  DesiredAccess: TDirectoryAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Retrieve the raw directory content information
function NtxQueryDirectoryRaw(
  [Access(DIRECTORY_QUERY)] const hxDirectory: IHandle;
  var Index: Cardinal;
  out Buffer: IMemory<PObjectDirectoryInformationArray>;
  ReturnSingleEntry: Boolean;
  [NumberOfBytes] InitialSize: Cardinal
): TNtxStatus;

// Retrieve information about one named object in a directory
function NtxQueryDirectory(
  [Access(DIRECTORY_QUERY)] const hxDirectory: IHandle;
  Index: Cardinal;
  out Entry: TNtxDirectoryEntry
): TNtxStatus;

// Retrieve information about multiple named objects in a directory
function NtxQueryDirectoryBulk(
  [Access(DIRECTORY_QUERY)] const hxDirectory: IHandle;
  Index: Cardinal;
  out Entries: TArray<TNtxDirectoryEntry>;
  [NumberOfBytes] BlockSize: Cardinal = 4000
): TNtxStatus;

// Make a for-in iterator for enumerating named objects in a directory.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function NtxIterateDirectory(
  [out, opt] Status: PNtxStatus;
  [Access(DIRECTORY_QUERY)] const hxDirectory: IHandle
): IEnumerable<TNtxDirectoryEntry>;

// Enumerate all named objects in a directory
function NtxEnumerateDirectory(
  [Access(DIRECTORY_QUERY)] const hxDirectory: IHandle;
  out Entries: TArray<TNtxDirectoryEntry>
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
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  RegisterNamespace: Boolean = True
): TNtxStatus;

// Open an existing private namespace directory
function NtxOpenPrivateNamespace(
  out hxNamespace: IHandle;
  const BoundaryDescriptor: IBoundaryDescriptor;
  AccessMask: TDirectoryAccessMask;
  [opt] const ObjectAttributes: IObjectAttributes = nil
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
  DesiredAccess: TSymlinkAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Get symbolic link target
function NtxQueryTargetSymlink(
  [Access(SYMBOLIC_LINK_QUERY)] const hxSymlink: IHandle;
  out Target: String
): TNtxStatus;

type
  NtxSymlink = class abstract
    // Set information for object manager symbolic link object
    [RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
    class function &Set<T>(
      [Access(SYMBOLIC_LINK_SET)] const hxSymlink: IHandle;
      InfoClass: TLinkInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb, NtUtils.Ldr,
  NtUtils.Tokens, NtUtils.Tokens.Info, NtUtils.SysUtils, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxGetNamedObjectPath;
var
  SessionId: TSessionId;
  Buffer: TNtUnicodeString;
  BufferDeallocator: IAutoReleasable;
begin
  // Uses the current process token by default
  if not Assigned(hxToken) then
    hxToken := NtxCurrentProcessToken;

  Result := LdrxCheckDelayedImport(delayed_RtlGetTokenNamedObjectPath);

  if not Result.IsSuccess then
  begin
    // AppContainers are not supported, obtain
    // the current session and construct the path manually.

    if hxToken.Handle = NtCurrentProcessToken then
    begin
      // Process session does not change
      SessionId := RtlGetCurrentPeb.SessionId;
      Result := NtxSuccess;
    end
    else
      Result := NtxToken.Query(hxToken, TokenSessionId, SessionId);

    if Result.IsSuccess then
      Path := '\Sessions\' + RtlxUIntToStr(SessionId) + '\BaseNamedObjects';
  end
  else
  begin
    Buffer := Default(TNtUnicodeString);

    // This function uses only NtQueryInformationToken under the hood and,
    // therefore, supports token pseudo-handles
    Result.Location := 'RtlGetTokenNamedObjectPath';
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);
    Result.Status := RtlGetTokenNamedObjectPath(hxToken.Handle, nil, Buffer);

    if not Result.IsSuccess then
      Exit;

    BufferDeallocator := RtlxDelayFreeUnicodeString(@Buffer);
    Path := Buffer.ToString;
  end;
end;

function NtxCreateDirectory;
var
  ObjAttr: PObjectAttributes;
  hDirectory: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateDirectoryObject';
  Result.Status := NtCreateDirectoryObject(
    hDirectory,
    AccessMaskOverride(DIRECTORY_ALL_ACCESS, ObjectAttributes),
    ObjAttr^
  );

  if Result.IsSuccess then
    hxDirectory := Auto.CaptureHandle(hDirectory);
end;

function NtxCreateDirectoryEx;
var
  ObjAttr: PObjectAttributes;
  hDirectory: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtCreateDirectoryObjectEx);

  if not Result.IsSuccess then
    Exit;

  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateDirectoryObjectEx';

  if Assigned(hxShadowDirectory) then
    Result.LastCall.Expects<TDirectoryAccessMask>(DIRECTORY_SHADOW);

  Result.Status := NtCreateDirectoryObjectEx(
    hDirectory,
    AccessMaskOverride(DIRECTORY_ALL_ACCESS, ObjectAttributes),
    ObjAttr^,
    HandleOrDefault(hxDirectory),
    0
  );

  if Result.IsSuccess then
    hxDirectory := Auto.CaptureHandle(hDirectory);
end;

function NtxOpenDirectory;
var
  ObjAttr: PObjectAttributes;
  hDirectory: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenDirectoryObject';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenDirectoryObject(hDirectory, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxDirectory := Auto.CaptureHandle(hDirectory);
end;

function NtxQueryDirectoryRaw;
var
  Required: Cardinal;
  InputIndex: Cardinal;
begin
  InputIndex := Index;

  if InitialSize < SizeOf(TObjectDirectoryInformation) then
    InitialSize := SizeOf(TObjectDirectoryInformation);

  Result.Location := 'NtQueryDirectoryObject';
  Result.LastCall.Expects<TDirectoryAccessMask>(DIRECTORY_QUERY);

  // Retieve one entry
  IMemory(Buffer) := Auto.AllocateDynamic(InitialSize);
  repeat
    Index := InputIndex;
    Required := 0;
    Result.Status := NtQueryDirectoryObject(HandleOrDefault(hxDirectory),
      Buffer.Data, Buffer.Size, ReturnSingleEntry, False, Index, @Required);

    // The function might succeed without returning any entries; fail it instead
    if Result.IsSuccess and (not ReturnSingleEntry) and (Index = InputIndex) then
    begin
      Result.Status := STATUS_BUFFER_TOO_SMALL;

      // Arbitrarily increase the buffer if necessary
      if Required <= Buffer.Size then
        Required := Buffer.Size shl 1;
    end;
  until not NtxExpandBufferEx(Result, IMemory(Buffer), Required, Grow12Percent);
end;

function NtxQueryDirectory;
var
  Buffer: IMemory<PObjectDirectoryInformationArray>;
begin
  Result := NtxQueryDirectoryRaw(hxDirectory, Index, Buffer, True,
    RtlGetLongestNtPathLength * SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  Entry.Name := Buffer.Data[0].Name.ToString;
  Entry.TypeName := Buffer.Data[0].TypeName.ToString;
end;

function NtxQueryDirectoryBulk;
var
  Buffer: IMemory<PObjectDirectoryInformationArray>;
  BufferCursor: PObjectDirectoryInformation;
  Count: Cardinal;
begin
  Result := NtxQueryDirectoryRaw(hxDirectory, Index, Buffer, False, BlockSize);

  if not Result.IsSuccess then
    Exit;

  // Count returned entries; they are terminated with a NULL entry
  Count := 0;
  BufferCursor := @Buffer.Data[0];

  while Assigned(BufferCursor.Name.Buffer) and
    Assigned(BufferCursor.TypeName.Buffer) do
  begin
    Inc(Count);
    Inc(BufferCursor);
  end;

  // Capture the enties
  SetLength(Entries, Count);
  Count := 0;
  BufferCursor := @Buffer.Data[0];

  while Assigned(BufferCursor.Name.Buffer) and
    Assigned(BufferCursor.TypeName.Buffer) do
  begin
    Entries[Count].Name := BufferCursor.Name.ToString;
    Entries[Count].TypeName := BufferCursor.TypeName.ToString;
    Inc(Count);
    Inc(BufferCursor);
  end;
end;

function NtxIterateDirectory;
var
  Index: Cardinal;
begin
  Index := 0;

  Result := NtxAuto.Iterate<TNtxDirectoryEntry>(Status,
    function (out Entry: TNtxDirectoryEntry): TNtxStatus
    begin
      // Retieve one entry of directory content
      Result := NtxQueryDirectory(hxDirectory, Index, Entry);

      if not Result.IsSuccess then
        Exit;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function NtxEnumerateDirectory;
const
  BLOCK_SIZE = 8000;
var
  Index: Cardinal;
  EntriesBlocks: TArray<TArray<TNtxDirectoryEntry>>;
begin
  EntriesBlocks := nil;
  Index := 0;

  // Collect directory content in blocks
  while NtxQueryDirectoryBulk(hxDirectory, Index, Entries,
    BLOCK_SIZE).HasEntry(Result) do
  begin
    SetLength(EntriesBlocks, Succ(Length(EntriesBlocks)));
    EntriesBlocks[High(EntriesBlocks)] := Entries;
    Inc(Index, Length(Entries));
  end;

  if not Result.IsSuccess then
    Exit;

  // Merge them together
  Entries := TArray.Flatten<TNtxDirectoryEntry>(EntriesBlocks);
end;

type
  TAutoBoundaryDescriptor = class (TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

  TAutoPrivateNamespace = class (TCustomAutoHandle, IHandle, IAutoReleasable)
    procedure Release; override;
  end;

procedure TAutoBoundaryDescriptor.Release;
begin
  if Assigned(FData) then
    RtlDeleteBoundaryDescriptor(FData);

  FData := nil;
  inherited;
end;

procedure TAutoPrivateNamespace.Release;
begin
  if FHandle <> 0 then
  begin
    NtDeletePrivateNamespace(FHandle);
    NtxClose(FHandle);
  end;

  FHandle := 0;
  inherited;
end;

function RtlxCreateBoundaryDescriptor;
var
  BoundaryNameStr: TNtUnicodeString;
  pBoundary: PObjectBoundaryDescriptor;
  BoundaryObj: TAutoBoundaryDescriptor;
  Flags: TBoundaryDescriptorFlags;
  i: Integer;
begin
  Result := RtlxInitUnicodeString(BoundaryNameStr, BoundaryName);

  if not Result.IsSuccess then
    Exit;

  if AddAppContainerSid then
    Flags := BOUNDARY_DESCRIPTOR_ADD_APPCONTAINER_SID
  else
    Flags := 0;

  // Allocate a named boundary descriptor
  pBoundary := RtlCreateBoundaryDescriptor(BoundaryNameStr, Flags);

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
  ObjAttr: PObjectAttributes;
  hNamespace: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreatePrivateNamespace';
  Result.Status := NtCreatePrivateNamespace(
    hNamespace,
    AccessMaskOverride(DIRECTORY_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    BoundaryDescriptor.Data
  );

  if not Result.IsSuccess then
    Exit;

  if not RegisterNamespace then
  begin
    // Delete now, making inaccessible via a boundary descriptor
    NtDeletePrivateNamespace(hNamespace);
    hxNamespace := Auto.CaptureHandle(hNamespace);
  end
  else
    // Delete on close
    hxNamespace := TAutoPrivateNamespace.Capture(hNamespace)
end;

function NtxOpenPrivateNamespace;
var
  ObjAttr: PObjectAttributes;
  hNamespace: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenPrivateNamespace';
  Result.LastCall.OpensForAccess(AccessMask);
  Result.Status := NtOpenPrivateNamespace(hNamespace, AccessMask, ObjAttr,
    BoundaryDescriptor.Data);

  if Result.IsSuccess then
    hxNamespace := Auto.CaptureHandle(hNamespace);
end;

function NtxCreateSymlink;
var
  TargetStr: TNtUnicodeString;
  ObjAttr: PObjectAttributes;
  hSymlink: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(TargetStr, Target);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateSymbolicLinkObject';
  Result.Status := NtCreateSymbolicLinkObject(
    hSymlink,
    AccessMaskOverride(SYMBOLIC_LINK_ALL_ACCESS, ObjectAttributes),
    ObjAttr^,
    TargetStr
  );

  if Result.IsSuccess then
    hxSymlink := Auto.CaptureHandle(hSymlink);
end;

function NtxOpenSymlink;
var
  ObjAttr: PObjectAttributes;
  hSymlink: THandle;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenSymbolicLinkObject';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenSymbolicLinkObject(hSymlink, DesiredAccess, ObjAttr^);

  if Result.IsSuccess then
    hxSymlink := Auto.CaptureHandle(hSymlink);
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
    Result.Status := NtQuerySymbolicLinkObject(HandleOrDefault(hxSymlink), Str,
      @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, nil);

  if Result.IsSuccess then
    Target := Str.ToString;
end;

class function NtxSymlink.&Set<T>;
begin
  Result := LdrxCheckDelayedImport(delayed_NtSetInformationSymbolicLink);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtSetInformationSymbolicLink';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects<TSymlinkAccessMask>(SYMBOLIC_LINK_SET);
  Result.Status := NtSetInformationSymbolicLink(HandleOrDefault(hxSymlink),
    InfoClass, @Buffer, SizeOf(Buffer));
end;

end.
