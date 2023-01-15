unit NtUiLib.AutoCompletion.Namespace;

{
  This module provides suggestion and auto-completion logic for the native
  object namespace.
}

interface

uses
  Ntapi.WinUser, Ntapi.Shlwapi, DelphiApi.Reflection, NtUtils, NtUtils.Objects;

type
  [NamingStyle(nsCamelCase, 'ot')]
  TNamespaceObjectType = (
    otUnknown,
    otSymlink,
    otDirectory,
    otFileDirectory,
    otFileNonDirectory,
    otKey
  );

  TNamespaceObjectTypes = set of TNamespaceObjectType;

  TNamespaceEntry = record
    Name: String;
    FullPath: String;
    ObjectType: TNamespaceObjectType;
  end;

const
  ALL_NAMESPACE_TYPES = [Low(TNamespaceObjectType)..High(TNamespaceObjectType)];

// Suggest child objects under the specified root
function RtlxEnumerateNamespaceEntries(
  const Root: String;
  out Suggestions: TArray<TNamespaceEntry>;
  SupportedTypes: TNamespaceObjectTypes = ALL_NAMESPACE_TYPES
): TNtxStatus;

// Determine the type of a named object
function RtlxQueryNamespaceEntry(
  const FullPath: String;
  SupportedTypes: TNamespaceObjectTypes = ALL_NAMESPACE_TYPES
): TNamespaceEntry;

// Query information about a kernel object type
function RtlxQueryNamespaceObjectType(
  out Info: TObjectTypeInfo;
  ObjectType: TNamespaceObjectType;
  UseCaching: Boolean = True
): TNtxStatus;

// Get RTTI TypeInfo of the access mask type that corresponds to the object type
[Result: MayReturnNil]
function RtlxGetNamespaceAccessMaskType(
  ObjectType: TNamespaceObjectType
): Pointer;

// Add dynamic object namespace suggestion to an edit-derived control
function ShlxEnableNamespaceSuggestions(
  EditControl: THwnd;
  SupportedTypes: TNamespaceObjectTypes = ALL_NAMESPACE_TYPES;
  Options: Cardinal = ACO_AUTOSUGGEST or ACO_UPDOWNKEYDROPSLIST
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntioapi, Ntapi.ntobapi, Ntapi.ntregapi,
  NtUtils.SysUtils, NtUtils.Objects.Namespace, NtUtils.Objects.Snapshots,
  NtUtils.Files.Open, NtUtils.Files.Folders, NtUtils.Registry,
  NtUiLib.AutoCompletion;

function TrimLastBackslash(
  const Path: String
): String;
begin
  if (Length(Path) > 0) and (Path[High(Path)] = '\') then
    Result := Copy(Path, 1, Length(Path) - 1)
  else
    Result := Path;
end;

function MakeNamespaceEntry(
  const Root: String;
  const Name: String;
  ObjectType: TNamespaceObjectType
): TNamespaceEntry;
begin
  Result.Name := Name;
  Result.FullPath := TrimLastBackslash(Root) + '\' + Name;
  Result.ObjectType := ObjectType;
end;

function RtlxpCollectForFile(
  const Root: String;
  SupportedTypes: TNamespaceObjectTypes;
  out Objects: TArray<TNamespaceEntry>
): TNtxStatus;
var
  hxFolder: IHandle;
  Files: TArray<TFolderEntry>;
  ObjectType: TNamespaceObjectType;
  i, Count: Integer;
begin
  Result := NtxOpenFile(hxFolder, FileOpenParameters
    .UseFileName(Root)
    .UseAccess(FILE_LIST_DIRECTORY)
    .UseOpenOptions(FILE_DIRECTORY_FILE or FILE_SYNCHRONOUS_IO_NONALERT)
  );

  if not Result.IsSuccess then
    Exit;

  // Enumerate the content
  Result := NtxEnumerateFolder(hxFolder.Handle, Files);

  if not Result.IsSuccess then
    Exit;

  Count := 0;
  for i := 0 to High(Files) do
  begin
    // Ignore pseudo-entries
    if (Files[i].FileName = '.') or (Files[i].FileName = '..') then
      Continue;

    if BitTest(Files[i].Common.FileAttributes and FILE_ATTRIBUTE_DIRECTORY) then
      ObjectType := otFileDirectory
    else
      ObjectType := otFileNonDirectory;

    // Count it
    if ObjectType in SupportedTypes then
      Inc(Count);
  end;

  SetLength(Objects, Count);

  Count := 0;
  for i := 0 to High(Files) do
  begin
    // Ignore pseudo-entries
    if (Files[i].FileName = '.') or (Files[i].FileName = '..') then
      Continue;

    if BitTest(Files[i].Common.FileAttributes and FILE_ATTRIBUTE_DIRECTORY) then
      ObjectType := otFileDirectory
    else
      ObjectType := otFileNonDirectory;

    // Save the object
    if ObjectType in SupportedTypes then
    begin
      Objects[Count] := MakeNamespaceEntry(Root, Files[i].FileName, ObjectType);
      Inc(Count);
    end;
  end;
end;

function RtlxpCollectForRegistry(
  const Root: String;
  SupportedTypes: TNamespaceObjectTypes;
  out Objects: TArray<TNamespaceEntry>
): TNtxStatus;
var
  hxKey: IHandle;
  SubKeys: TArray<String>;
  i: Integer;
begin
  Result := NtxOpenKey(hxKey, Root, KEY_ENUMERATE_SUB_KEYS);

  if not Result.IsSuccess then
    Exit;

  Result := NtxEnumerateSubKeys(hxKey.Handle, SubKeys);

  if not Result.IsSuccess then
    Exit;

  SetLength(Objects, Length(SubKeys));

  for i := 0 to High(Objects) do
    Objects[i] := MakeNamespaceEntry(Root, SubKeys[i], otKey);
end;

function RtlxpLookupObjectType(
  const TypeName: String
): TNamespaceObjectType;
begin
  if TypeName = 'Directory' then
    Result := otDirectory
  else if TypeName = 'SymbolicLink' then
    Result := otSymlink
  else if TypeName = 'File' then
    Result := otFileDirectory
  else if TypeName = 'Key' then
    Result := otKey
  else
    Result := otUnknown;
end;

function RtlxpCollectForDirectory(
  const Root: String;
  SupportedTypes: TNamespaceObjectTypes;
  out Objects: TArray<TNamespaceEntry>
): TNtxStatus;
var
  hxDirectory: IHandle;
  Entries: TArray<TDirectoryEnumEntry>;
  ObjectTypes: TArray<TNamespaceObjectType>;
  Count, i: Integer;
begin
  Result := NtxOpenDirectory(hxDirectory, Root, DIRECTORY_QUERY);

  if not Result.IsSuccess then
    Exit;

  Result := NtxEnumerateDirectory(hxDirectory.Handle, Entries);

  if not Result.IsSuccess then
    Exit;

  // Lookup their types
  SetLength(ObjectTypes, Length(Entries));
  Count := 0;

  for i := 0 to High(Entries) do
  begin
    ObjectTypes[i] := RtlxpLookupObjectType(Entries[i].TypeName);

    if ObjectTypes[i] in SupportedTypes then
      Inc(Count);
  end;

  // Save them
  SetLength(Objects, Count);
  Count := 0;

  for i := 0 to High(Entries) do
    if ObjectTypes[i] in SupportedTypes then
    begin
      Objects[Count] := MakeNamespaceEntry(Root, Entries[i].Name, ObjectTypes[i]);
      Inc(Count);
    end;
end;

function RtlxEnumerateNamespaceEntries;
var
  TrimmedRoot: String;
begin
  // Enumerate the root of the namespace manually by adding the "\" entry
  if Root = '' then
  begin
    Suggestions := [MakeNamespaceEntry('', '', otDirectory)];
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  Suggestions := nil;

  // Suggest files and folders
  if [otFileDirectory, otFileNonDirectory] * SupportedTypes <> [] then
  begin
    Result := RtlxpCollectForFile(Root, SupportedTypes, Suggestions);

    if (Result.Status <> STATUS_OBJECT_TYPE_MISMATCH) and
      (Result.Status <> STATUS_OBJECT_NAME_INVALID) then
      Exit;
  end;

  if Root <> '\' then
    TrimmedRoot := TrimLastBackslash(Root)
  else
    TrimmedRoot := Root;

  // Suggest registry keys
  if otKey in SupportedTypes then
  begin
    if not (otDirectory in SupportedTypes) and (Root = '\') then
    begin
      // Make the registry root discoverable
      Suggestions := [MakeNamespaceEntry(Root, 'REGISTRY', otKey)];
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    Result := RtlxpCollectForRegistry(Root, SupportedTypes, Suggestions);

    if (Result.Status <> STATUS_OBJECT_TYPE_MISMATCH) and
      (Result.Status <> STATUS_OBJECT_NAME_INVALID) then
      Exit;
  end;

  // Suggest namespace directories
  if SupportedTypes - [otKey] <> [] then
  begin
    Result := RtlxpCollectForDirectory(TrimmedRoot, SupportedTypes, Suggestions);

    if Result.Status <> STATUS_OBJECT_TYPE_MISMATCH then
      Exit;
  end;
end;

function IsTypeMatchingType(
  const Status: TNtxStatus
): Boolean;
begin
  case Status.Status of
    STATUS_OBJECT_PATH_SYNTAX_BAD, STATUS_OBJECT_NAME_INVALID,
    STATUS_OBJECT_TYPE_MISMATCH, STATUS_OBJECT_NAME_NOT_FOUND,
    STATUS_OBJECT_PATH_NOT_FOUND, STATUS_INVALID_PARAMETER,
    STATUS_INVALID_DEVICE_REQUEST, STATUS_UNSUCCESSFUL,
    STATUS_ACCESS_VIOLATION:
      Result := False;

    STATUS_SUCCESS, STATUS_ACCESS_DENIED, STATUS_OPLOCK_BREAK_IN_PROGRESS:
      Result := True;
  else
    // For debugging purposes
    Result := True;
  end;
end;

function RtlxQueryNamespaceEntry;
var
  TrimmedFullPath: String;
  Status: TNtxStatus;
  hxObject: IHandle;
begin
  Result.Name := RtlxExtractNamePath(FullPath);
  Result.FullPath := FullPath;
  Result.ObjectType := otUnknown;

  if FullPath = '' then
    Exit;

  if FullPath = '\' then
  begin
    Result.ObjectType := otDirectory;
    Exit;
  end;

  // Remove the trailing back slash for types that don't support it
  TrimmedFullPath := TrimLastBackslash(FullPath);

  // For symlinks, we use this back slash as an indicator that the caller
  // wants to open the target instead of the symlink itself.
  if (otSymlink in SupportedTypes) and (FullPath[High(FullPath)] <> '\') then
  begin
   Status := NtxOpenSymlink(hxObject, TrimmedFullPath, 0);

    if IsTypeMatchingType(Status) then
    begin
      Result.ObjectType := otSymlink;
      Exit;
    end;
  end;

  // Directory
  if otDirectory in SupportedTypes then
  begin
    Status := NtxOpenDirectory(hxObject, TrimmedFullPath, 0);

    if IsTypeMatchingType(Status) then
    begin
      Result.ObjectType := otDirectory;
      Exit;
    end;
  end;

  // File
  if [otFileDirectory, otFileNonDirectory] * SupportedTypes <> [] then
  begin
    Status := NtxOpenFile(hxObject, FileOpenParameters
      .UseFileName(FullPath)
      .UseOpenOptions(FILE_DIRECTORY_FILE or FILE_COMPLETE_IF_OPLOCKED)
    );

    if Status.Status = STATUS_NOT_A_DIRECTORY then
    begin
      Result.ObjectType := otFileNonDirectory;
      Exit;
    end;

    if IsTypeMatchingType(Status) then
    begin
      Result.ObjectType := otFileDirectory;
      Exit;
    end;
  end;

  // Key
  if otKey in SupportedTypes then
  begin
    Status := NtxOpenKey(hxObject, FullPath, 0);

    if IsTypeMatchingType(Status) then
    begin
      Result.ObjectType := otKey;
      Exit;
    end;
  end;

end;

var
  TypesCacheInitialized: Boolean;
  TypesCache: TArray<TObjectTypeInfo>;

function RtlxQueryNamespaceObjectType;
var
  Types: TArray<TObjectTypeInfo>;
  TypeName: String;
  i: Integer;
begin
  if not TypesCacheInitialized or not UseCaching then
  begin
    Result := NtxEnumerateTypes(Types);

    if not Result.IsSuccess then
      Exit;

    // Refresh the cache
    TypesCache := Types;
    TypesCacheInitialized := True;
  end;

  // Prepare known kernel type names
  case ObjectType of
    otSymlink: TypeName := 'SymbolicLink';
    otDirectory: TypeName := 'Directory';
    otFileDirectory, otFileNonDirectory: TypeName := 'File';
    otKey: TypeName := 'Key';
  else
    Result.Location := 'RtlxQueryNamespaceObjectType';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Find the corresponding entry
  for i := 0 to High(TypesCache) do
    if TypesCache[i].TypeName = TypeName then
    begin
      Info := TypesCache[i];
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

  Result.Location := 'RtlxQueryNamespaceObjectType';
  Result.Status := STATUS_NOT_FOUND;
end;

function RtlxGetNamespaceAccessMaskType;
begin
  case ObjectType of
    otDirectory:        Result := TypeInfo(TDirectoryAccessMask);
    otSymlink:          Result := TypeInfo(TSymlinkAccessMask);
    otFileDirectory:    Result := TypeInfo(TIoDirectoryAccessMask);
    otFileNonDirectory: Result := TypeInfo(TIoFileAccessMask);
    otKey:              Result := TypeInfo(TRegKeyAccessMask);
  else
    Result := nil;
  end;
end;

function ShlxEnableNamespaceSuggestions;
begin
  Result := ShlxEnableDynamicSuggestions(EditControl,
    function (const Root: String; out Names: TArray<String>): TNtxStatus
    var
      Objects: TArray<TNamespaceEntry>;
      i: Integer;
    begin
      // Collect nested objects
      Result := RtlxEnumerateNamespaceEntries(Root, Objects, SupportedTypes);

      if not Result.IsSuccess then
        Exit;

      SetLength(Names, Length(Objects));

      // Provide their names
      for i := 0 to High(Names) do
        Names[i] := Objects[i].FullPath;
    end
  );
end;

end.
