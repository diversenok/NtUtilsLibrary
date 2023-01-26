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
    otKey,
    otSection,
    otEvent,
    otSemaphore,
    otMutex,
    otTimer,
    otJob,
    otSession,
    otKeyedEvent,
    otIoCompletion,
    otPartition
  );

  TNamespaceObjectTypes = set of TNamespaceObjectType;

  TNamespaceEntry = record
    Name: String;
    FullPath: String;
    TypeName: String;
    KnownType: TNamespaceObjectType;
  end;

const
  ALL_NAMESPACE_TYPES = [Low(TNamespaceObjectType)..High(TNamespaceObjectType)];
  ALL_KNOWN_NAMESPACE_TYPES = ALL_NAMESPACE_TYPES - [otUnknown];

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

// Get RTTI TypeInfo of the access mask type that corresponds to the object type
[Result: MayReturnNil]
function RtlxGetNamespaceAccessMaskType(
  KnownType: TNamespaceObjectType
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
  Ntapi.ntmmapi, Ntapi.ntexapi, Ntapi.ntpsapi,
  NtUtils.SysUtils, NtUtils.Objects.Namespace, NtUtils.Objects.Snapshots,
  NtUtils.Files.Open, NtUtils.Files.Folders, NtUtils.Registry, NtUtils.Sections,
  NtUtils.Synchronization, NtUtils.Jobs, NtUtils.Memory, NtUiLib.AutoCompletion;

{ Known types }

const
  TypeNames: array [TNamespaceObjectType] of String = (
    '', 'SymbolicLink', 'Directory', 'File', 'File', 'Key', 'Section', 'Event',
    'Semaphore', 'Mutant', 'Timer', 'Job', 'Session', 'KeyedEvent',
    'IoCompletion', 'Partition'
  );

function RtlxGetNamespaceAccessMaskType;
begin
  case KnownType of
    otDirectory:        Result := TypeInfo(TDirectoryAccessMask);
    otSymlink:          Result := TypeInfo(TSymlinkAccessMask);
    otFileDirectory:    Result := TypeInfo(TIoDirectoryAccessMask);
    otFileNonDirectory: Result := TypeInfo(TIoFileAccessMask);
    otKey:              Result := TypeInfo(TRegKeyAccessMask);
    otSection:          Result := TypeInfo(TSectionAccessMask);
    otEvent:            Result := TypeInfo(TEventAccessMask);
    otSemaphore:        Result := TypeInfo(TSemaphoreAccessMask);
    otMutex:            Result := TypeInfo(TMutantAccessMask);
    otTimer:            Result := TypeInfo(TTimerAccessMask);
    otJob:              Result := TypeInfo(TJobObjectAccessMask);
    otSession:          Result := TypeInfo(TSessionAccessMask);
    otKeyedEvent:       Result := TypeInfo(TKeyedEventAccessMask);
    otIoCompletion:     Result := TypeInfo(TIoCompletionAccessMask);
    otPartition:        Result := TypeInfo(TPartitionAccessMask);
  else
    Result := nil;
  end;
end;

function RtlxTestObjectType(
  const FullPath: String;
  const TrimmedPath: String;
  KnownType: TNamespaceObjectType
): TNtxStatus;
var
  hxObject: IHandle;
begin
  case KnownType of
    otFileDirectory, otFileNonDirectory:
      Result := NtxOpenFile(hxObject, FileOpenParameters
        .UseFileName(FullPath)
        .UseOpenOptions(FILE_DIRECTORY_FILE or FILE_COMPLETE_IF_OPLOCKED)
      );

    otSymlink:      Result := NtxOpenSymlink(hxObject, 0, TrimmedPath);
    otDirectory:    Result := NtxOpenDirectory(hxObject, 0, TrimmedPath);
    otKey:          Result := NtxOpenKey(hxObject, FullPath, 0);
    otSection:      Result := NtxOpenSection(hxObject, 0, TrimmedPath);
    otEvent:        Result := NtxOpenEvent(hxObject, 0, TrimmedPath);
    otSemaphore:    Result := NtxOpenSemaphore(hxObject, 0, TrimmedPath);
    otMutex:        Result := NtxOpenMutant(hxObject, 0, TrimmedPath);
    otTimer:        Result := NtxOpenTimer(hxObject, 0, TrimmedPath);
    otJob:          Result := NtxOpenJob(hxObject, 0, TrimmedPath);
    otSession:      Result := NtxOpenSession(hxObject, 0, TrimmedPath);
    otKeyedEvent:   Result := NtxOpenKeyedEvent(hxObject, 0, TrimmedPath);
    otIoCompletion: Result := NtxOpenIoCompletion(hxObject, 0, TrimmedPath);
    otPartition:    Result := NtxOpenPartition(hxObject, 0, TrimmedPath);
  else
    Result.Location := 'RtlxTestObjectType';
    Result.Status := STATUS_NOT_SUPPORTED;
  end;
end;

{ Helper functions }

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
  const TypeName: String;
  KnownType: TNamespaceObjectType
): TNamespaceEntry;
begin
  Result.Name := Name;
  Result.FullPath := TrimLastBackslash(Root) + '\' + Name;
  Result.TypeName := TypeName;
  Result.KnownType := KnownType;
end;

function LookupObjectType(
  const TypeName: String
): TNamespaceObjectType;
begin
  for Result := Low(TNamespaceObjectType) to High(TNamespaceObjectType) do
    if TypeNames[Result] = TypeName then
      Exit;

  // Opening devices gives file handles
  if TypeName = 'Device' then
    Result := otFileDirectory
  else
    Result := otUnknown;
end;

function IsTypeMatchingTypeStatus(
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

{ Nested object collectors }

function RtlxpCollectForFile(
  const Root: String;
  SupportedTypes: TNamespaceObjectTypes;
  out Objects: TArray<TNamespaceEntry>
): TNtxStatus;
var
  hxFolder: IHandle;
  Files: TArray<TFolderEntry>;
  KnownType: TNamespaceObjectType;
  i, Count: Integer;
begin
  Result := NtxOpenFile(hxFolder, FileOpenParameters
    .UseFileName(Root)
    .UseAccess(FILE_LIST_DIRECTORY)
    .UseOpenOptions(FILE_DIRECTORY_FILE)
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
      KnownType := otFileDirectory
    else
      KnownType := otFileNonDirectory;

    // Count it
    if KnownType in SupportedTypes then
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
      KnownType := otFileDirectory
    else
      KnownType := otFileNonDirectory;

    // Save the object
    if KnownType in SupportedTypes then
    begin
      Objects[Count] := MakeNamespaceEntry(Root, Files[i].FileName,
        TypeNames[KnownType], KnownType);
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
    Objects[i] := MakeNamespaceEntry(Root, SubKeys[i], TypeNames[otKey], otKey);
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
  Result := NtxOpenDirectory(hxDirectory, DIRECTORY_QUERY, Root);

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
    ObjectTypes[i] := LookupObjectType(Entries[i].TypeName);

    if ObjectTypes[i] in SupportedTypes then
      Inc(Count);
  end;

  // Save them
  SetLength(Objects, Count);
  Count := 0;

  for i := 0 to High(Entries) do
    if ObjectTypes[i] in SupportedTypes then
    begin
      Objects[Count] := MakeNamespaceEntry(Root, Entries[i].Name,
        Entries[i].TypeName, ObjectTypes[i]);
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
    Suggestions := [MakeNamespaceEntry('', '', TypeNames[otDirectory],
      otDirectory)];
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
      Suggestions := [MakeNamespaceEntry(Root, 'REGISTRY', TypeNames[otKey],
        otKey)];
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

function RtlxQueryNamespaceEntry;
var
  TrimmedFullPath: String;
  Status: TNtxStatus;
  i: TNamespaceObjectType;
begin
  Result.Name := RtlxExtractNamePath(FullPath);
  Result.FullPath := FullPath;
  Result.TypeName := '';
  Result.KnownType := otUnknown;

  if FullPath = '' then
    Exit;

  if FullPath = '\' then
  begin
    Result.TypeName := TypeNames[otDirectory];
    Result.KnownType := otDirectory;
    Exit;
  end;

  // Most types don't support the trailing back slash
  TrimmedFullPath := TrimLastBackslash(FullPath);

  // For symlinks, we use this back slash as an indicator that the caller
  // wants to open the target instead of the symlink itself.
  if (otSymlink in SupportedTypes) and (FullPath[High(FullPath)] = '\') then
    SupportedTypes := SupportedTypes - [otSymlink];

  // For files, avoid checking the type twise; use only the file directory check
  if [otFileDirectory, otFileNonDirectory] * SupportedTypes <> [] then
    SupportedTypes := SupportedTypes + [otFileDirectory] - [otFileNonDirectory];

  for i in SupportedTypes - [otUnknown] do
  begin
    // Try to open the name as the specified type
    Status := RtlxTestObjectType(FullPath, TrimmedFullPath, i);

    // File non-directory and file directory checks come at once
    if (i = otFileDirectory) and (Status.Status = STATUS_NOT_A_DIRECTORY) then
    begin
      Result.TypeName := TypeNames[otFileNonDirectory];
      Result.KnownType := otFileNonDirectory;
      Exit;
    end;

    if IsTypeMatchingTypeStatus(Status) then
    begin
      Result.TypeName := TypeNames[i];
      Result.KnownType := i;
      Exit;
    end;
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
