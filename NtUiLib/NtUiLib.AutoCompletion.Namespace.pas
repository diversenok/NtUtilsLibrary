unit NtUiLib.AutoCompletion.Namespace;

{
  This module provides suggestion and auto-completion logic for the native
  object namespace.
}

interface

uses
  DelphiApi.Reflection, NtUtils, NtUtils.Objects, NtUiLib.AutoCompletion,
  DelphiUtils.LiteRTTI.Base;

type
  [NamingStyle(nsCamelCase, 'ot')]
  TNamespaceObjectType = (
    otUnknown,
    otSymlink,
    otDirectory,
    otDevice,
    otFileDirectory,
    otFile,
    otNamedPipe,
    otRegistryKey,
    otSection,
    otEvent,
    otSemaphore,
    otMutex,
    otTimer,
    otJob,
    otSession,
    otKeyedEvent,
    otIoCompletion,
    otPartition,
    otRegistryTransaction,
    otWindowStation,
    otDesktop
  );

  TNamespaceObjectTypes = set of TNamespaceObjectType;

  TNamespaceEntry = record
    Name: String;
    FullPath: String;
    TypeName: String;
    KnownType: TNamespaceObjectType;
  end;

const
  NT_NAMESPACE_ALL_TYPES = [Low(TNamespaceObjectType)..High(TNamespaceObjectType)];
  NT_NAMESPACE_KNOWN_TYPES = NT_NAMESPACE_ALL_TYPES - [otUnknown];
  NT_NAMESPACE_FILE_TYPES = [otDevice, otFileDirectory, otFile, otNamedPipe];

// Suggest child objects under the specified root
function RtlxEnumerateNamespaceEntries(
  const Root: String;
  out Suggestions: TArray<TNamespaceEntry>;
  SupportedTypes: TNamespaceObjectTypes = NT_NAMESPACE_ALL_TYPES
): TNtxStatus;

// Determine the type of a named object
function RtlxQueryNamespaceEntry(
  const FullPath: String;
  SupportedTypes: TNamespaceObjectTypes = NT_NAMESPACE_KNOWN_TYPES
): TNamespaceEntry;

// Get RTTI TypeInfo of the access mask type that corresponds to the object type
[Result: MayReturnNil]
function RtlxGetNamespaceAccessMaskType(
  KnownType: TNamespaceObjectType
): PLiteRttiTypeInfo;

// Allocate an object namespace suggestions provider for use with
// ShlxEnableSuggestions
function ShlxPrepareNamespaceSuggestions(
  SupportedTypes: TNamespaceObjectTypes = NT_NAMESPACE_ALL_TYPES
): IAutoCompletionSuggestions;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntioapi, Ntapi.ntobapi, Ntapi.ntregapi,
  Ntapi.ntmmapi, Ntapi.ntexapi, Ntapi.ntpsapi, Ntapi.nttmapi, Ntapi.ntpebteb,
  Ntapi.ntioapi.fsctl, Ntapi.WinUser, Ntapi.Versions,
  NtUtils.SysUtils, NtUtils.Objects.Namespace, NtUtils.Objects.Snapshots,
  NtUtils.Files.Open, NtUtils.Files.Directories, NtUtils.Files.Operations,
  NtUtils.Registry, NtUtils.Sections, NtUtils.Synchronization, NtUtils.Jobs,
  NtUtils.Memory, NtUtils.Transactions, NtUtils.NtUser;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function IsMatchingTypeStatus(
  const Status: TNtxStatus
): Boolean;
begin
  case Status.Status of
    STATUS_OBJECT_PATH_SYNTAX_BAD, STATUS_OBJECT_PATH_INVALID,
    STATUS_OBJECT_PATH_NOT_FOUND, STATUS_OBJECT_NAME_INVALID,
    STATUS_OBJECT_NAME_NOT_FOUND, STATUS_OBJECT_TYPE_MISMATCH,
    STATUS_NOT_FOUND, STATUS_NO_SUCH_DEVICE, STATUS_NO_SUCH_FILE,
    STATUS_BAD_NETWORK_NAME, STATUS_BAD_NETWORK_PATH,
    STATUS_INVALID_DEVICE_REQUEST, STATUS_INVALID_PARAMETER,
    STATUS_UNSUCCESSFUL, STATUS_NOT_SUPPORTED, STATUS_NOT_IMPLEMENTED,
    STATUS_ASSERTION_FAILURE, STATUS_ACCESS_VIOLATION:
      Result := False;

    NT_SUCCESS_MIN..NT_SUCCESS_MAX,
    STATUS_ACCESS_DENIED, STATUS_SHARING_VIOLATION, STATUS_DELETE_PENDING,
    STATUS_PIPE_NOT_AVAILABLE, STATUS_INSTANCE_NOT_AVAILABLE:
      Result := True;
  else
    // For breakpoints
    Result := False;
  end;
end;

{ Known types }

const
  TYPE_NAMES: array [TNamespaceObjectType] of String = (
    '', 'SymbolicLink', 'Directory', 'Device', 'File', 'File', 'File', 'Key',
    'Section', 'Event', 'Semaphore', 'Mutant', 'Timer', 'Job', 'Session',
    'KeyedEvent', 'IoCompletion', 'Partition', 'RegistryTransaction',
    'WindowStation', 'Desktop'
  );

function RtlxGetNamespaceAccessMaskType;
begin
  case KnownType of
    otDirectory:           Result := TypeInfo(TDirectoryAccessMask);
    otSymlink:             Result := TypeInfo(TSymlinkAccessMask);
    otDevice:              Result := TypeInfo(TFileAccessMask);
    otFileDirectory:       Result := TypeInfo(TIoDirectoryAccessMask);
    otFile:                Result := TypeInfo(TIoFileAccessMask);
    otNamedPipe:           Result := TypeInfo(TIoPipeAccessMask);
    otRegistryKey:         Result := TypeInfo(TRegKeyAccessMask);
    otSection:             Result := TypeInfo(TSectionAccessMask);
    otEvent:               Result := TypeInfo(TEventAccessMask);
    otSemaphore:           Result := TypeInfo(TSemaphoreAccessMask);
    otMutex:               Result := TypeInfo(TMutantAccessMask);
    otTimer:               Result := TypeInfo(TTimerAccessMask);
    otJob:                 Result := TypeInfo(TJobObjectAccessMask);
    otSession:             Result := TypeInfo(TSessionAccessMask);
    otKeyedEvent:          Result := TypeInfo(TKeyedEventAccessMask);
    otIoCompletion:        Result := TypeInfo(TIoCompletionAccessMask);
    otPartition:           Result := TypeInfo(TPartitionAccessMask);
    otRegistryTransaction: Result := TypeInfo(TTmTxAccessMask);
    otWindowStation:       Result := TypeInfo(TWinStaAccessMask);
    otDesktop:             Result := TypeInfo(TDesktopAccessMask);
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
    otSymlink:      Result := NtxOpenSymlink(hxObject, 0, TrimmedPath);
    otDirectory:    Result := NtxOpenDirectory(hxObject, 0, TrimmedPath);
    otRegistryKey:  Result := NtxOpenKey(hxObject, FullPath, 0);
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
    otRegistryTransaction: Result := NtxOpenRegistryTransaction(hxObject, 0, TrimmedPath);
    otWindowStation: Result := NtxOpenWindowStation(hxObject, 0, TrimmedPath);
    otDesktop:       Result := NtxOpenDesktop(hxObject, 0, TrimmedPath);
  else
    // File types are determined independently
    Result.Location := 'RtlxTestObjectType';
    Result.Status := STATUS_NOT_SUPPORTED;
  end;
end;

function RtlxTestFileTypes(
  const FullPath: String;
  const TrimmedPath: String;
  SupportedTypes: TNamespaceObjectTypes
): TNamespaceObjectType;
var
  Status: TNtxStatus;
  RootPath: String;
  hxObject: IHandle;
begin
  // Try generic file open operation
  Status := NtxOpenFile(hxObject, FileParameters
    .UseFileName(FullPath)
    .UseOptions(FILE_COMPLETE_IF_OPLOCKED or FILE_OPEN_NO_RECALL or
      FILE_OPEN_REPARSE_POINT)
  );

  if not IsMatchingTypeStatus(Status) then
    Exit(otUnknown);

  if otDevice in SupportedTypes then
  begin
    // Files appearing directly under directories are devices
    RootPath := RtlxExtractRootPath(FullPath);

    if RootPath = '' then
      Exit(otDevice);

    Status := NtxOpenDirectory(hxObject, 0, RootPath);

    if IsMatchingTypeStatus(Status) then
      Exit(otDevice);
  end;

  // Test file directories vs. file non-directories
  Status := NtxOpenFile(hxObject, FileParameters
    .UseFileName(FullPath)
    .UseOptions(FILE_DIRECTORY_FILE or FILE_COMPLETE_IF_OPLOCKED or
      FILE_OPEN_REPARSE_POINT)
  );

  if Status.Status = STATUS_NOT_A_DIRECTORY then
    Exit(otFile);

  // Test pipes via a dedicated function that only works on pipes
  if otNamedPipe in SupportedTypes then
  begin
    Status := NtxCreatePipe(hxObject, FileParameters
      .UseFileName(FullPath)
      .UseDisposition(FILE_OPEN)
    );

    if IsMatchingTypeStatus(Status) then
      Exit(otNamedPipe);
  end;

  Result := otFileDirectory;
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
  KnownType: TNamespaceObjectType;
  const TypeName: String = ''
): TNamespaceEntry;
begin
  Result.Name := Name;
  Result.FullPath := RtlxCombinePaths(Root, Name);
  Result.KnownType := KnownType;

  if TypeName = '' then
    Result.TypeName := TYPE_NAMES[KnownType];
end;

function LookupObjectType(
  const TypeName: String;
  SupportedTypes: TNamespaceObjectTypes
): TNamespaceObjectType;
const
  NT_NAMESPACE_NESTED_FILE_TYPES = [otFileDirectory, otFile, otNamedPipe];
begin
  // Check all type names appearing directly in the object namespace, i.e.,
  // everything, except for files and pipes (which exist inside devices)

  for Result in SupportedTypes - [otUnknown] - NT_NAMESPACE_NESTED_FILE_TYPES do
    if TYPE_NAMES[Result] = TypeName then
      Exit;

  Result := otUnknown;
end;

function IsSessionsDirectory(
  const Root: String;
  out RemainingPath: String;
  out SessionId: Cardinal
): Boolean;
const
  SESSIONS_PREFIX = '\Sessions\';
var
  SessionIdStr, Path: String;
begin
  Path := Root;
  Result := RtlxPrefixStripString(SESSIONS_PREFIX, Path);

  if not Result then
    Exit;

  if not RtlxSplitPathOnFirst(Path, SessionIdStr, RemainingPath) then
  begin
    SessionIdStr := Path;
    RemainingPath := '';
  end;

  Result := RtlxStrToUInt(SessionIdStr, SessionId, nsDecimal, [], False, []);
end;

function MergeSuggestions(
  const PrimaryEntries: TArray<TNamespaceEntry>;
  const ShadowEntries: TArray<TNamespaceEntry>
): TArray<TNamespaceEntry>;
var
  i, j, Count: Integer;
  UseShadowEntries: TArray<Boolean>;
begin
  Count := 0;
  SetLength(UseShadowEntries, Length(ShadowEntries));

  for i := 0 to High(ShadowEntries) do
  begin
    UseShadowEntries[i] := True;

    for j := 0 to High(PrimaryEntries) do
      if RtlxEqualStrings(PrimaryEntries[j].Name, ShadowEntries[i].Name) then
      begin
        // Found a primary item that hides the shadow one
        UseShadowEntries[i] := False;
        Break;
      end;

    if UseShadowEntries[i] then
      Inc(Count);
  end;

  SetLength(Result, Length(PrimaryEntries) + Count);

  // Primary entries go first
  for j := 0 to High(PrimaryEntries) do
    Result[j] := PrimaryEntries[j];

  // Non-hidden shadow entries follow
  j := Length(PrimaryEntries);

  for i := 0 to High(ShadowEntries) do
    if UseShadowEntries[i] then
    begin
      Result[j] := ShadowEntries[i];
      Inc(j);
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
  Files: TArray<TDirectoryFileEntry>;
  CurrentNonDirectoryType, KnownType: TNamespaceObjectType;
  i, Count: Integer;
  VolumeInfo: TFileFsDeviceInformation;
begin
  // Note: the system ignores the backup flag when we don't have the privileges
  Result := NtxOpenFile(hxFolder, FileParameters
    .UseFileName(Root)
    .UseAccess(FILE_LIST_DIRECTORY)
    .UseOptions(FILE_COMPLETE_IF_OPLOCKED or FILE_OPEN_FOR_BACKUP_INTENT)
  );

  if not Result.IsSuccess then
    Exit;

  // Enumerate the content
  Result := NtxEnumerateDirectoryFile(hxFolder, Files, FileDirectoryInformation);

  if not Result.IsSuccess then
    Exit;

  // By default, assume non-directory files as regular files
  CurrentNonDirectoryType := otFile;

  if otNamedPipe in SupportedTypes then
  begin
    // But if the device type indicates a named pipe, mark them as pipes
    Result := NtxVolume.Query(hxFolder, FileFsDeviceInformation, VolumeInfo);

    if Result.IsSuccess and (VolumeInfo.DeviceType =
      TDeviceType.FILE_DEVICE_NAMED_PIPE) then
      CurrentNonDirectoryType := otNamedPipe;

    // Don't fail enumeration when failed to query
    Result := NtxSuccess;
  end;

  Count := 0;
  for i := 0 to High(Files) do
  begin
    // Ignore pseudo-entries
    if (Files[i].FileName = '.') or (Files[i].FileName = '..') then
      Continue;

    if BitTest(Files[i].Common.FileAttributes and FILE_ATTRIBUTE_DIRECTORY) then
      KnownType := otFileDirectory
    else
      KnownType := CurrentNonDirectoryType;

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
      KnownType := CurrentNonDirectoryType;

    // Save the object
    if KnownType in SupportedTypes then
    begin
      Objects[Count] := MakeNamespaceEntry(Root, Files[i].FileName, KnownType);
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
  SubKeys: TArray<TNtxRegKey>;
  i: Integer;
begin
  // Since the backup/restore option always requires the privileges (as opposed
  // to how file I/O works), try without it first
  Result := NtxOpenKey(hxKey, Root, KEY_ENUMERATE_SUB_KEYS);

  // If failed, retry with it
  if Result.Status = STATUS_ACCESS_DENIED then
    Result := NtxOpenKey(hxKey, Root, KEY_ENUMERATE_SUB_KEYS,
      REG_OPTION_BACKUP_RESTORE);

  if not Result.IsSuccess then
    Exit;

  Result := NtxEnumerateKeys(hxKey, SubKeys);

  if not Result.IsSuccess then
    Exit;

  SetLength(Objects, Length(SubKeys));

  for i := 0 to High(Objects) do
    Objects[i] := MakeNamespaceEntry(Root, SubKeys[i].Name, otRegistryKey);
end;

function RtlxpCollectForDirectory(
  const Root: String;
  const RootSubstitution: String;
  SupportedTypes: TNamespaceObjectTypes;
  out Objects: TArray<TNamespaceEntry>
): TNtxStatus;
var
  hxDirectory: IHandle;
  Entries: TArray<TNtxDirectoryEntry>;
  ObjectTypes: TArray<TNamespaceObjectType>;
  InheritedObjects: TArray<TNamespaceEntry>;
  Count, i: Integer;
begin
  // Always include directories and symlinks to make objects discoverable
  SupportedTypes := SupportedTypes + [otDirectory, otSymlink];

  // Desktops are only discoverable via window stations
  if otDesktop in SupportedTypes then
    Include(SupportedTypes, otWindowStation);

  Result := NtxOpenDirectory(hxDirectory, DIRECTORY_QUERY, Root);

  if not Result.IsSuccess then
    Exit;

  Result := NtxEnumerateDirectory(hxDirectory, Entries);

  if not Result.IsSuccess then
    Exit;

  // Lookup known object types
  SetLength(ObjectTypes, Length(Entries));
  Count := 0;

  for i := 0 to High(Entries) do
  begin
    ObjectTypes[i] := LookupObjectType(Entries[i].TypeName, SupportedTypes);

    if ObjectTypes[i] in SupportedTypes then
      Inc(Count);
  end;

  // Save them
  SetLength(Objects, Count);
  Count := 0;

  for i := 0 to High(Entries) do
    if ObjectTypes[i] in SupportedTypes then
    begin
      Objects[Count] := MakeNamespaceEntry(RootSubstitution, Entries[i].Name,
        ObjectTypes[i], Entries[i].TypeName);
      Inc(Count);
    end;

  // When enumerating global root, add local \??
  if Root = '\' then
    Objects := MergeSuggestions([MakeNamespaceEntry(RootSubstitution, '??',
      otDirectory)], Objects);

  // When enumerating local DosDevices, append global entries
  if RtlxEqualStrings(Root, '\??') or RtlxEqualStrings(Root, '\DosDevices') then
    if RtlxpCollectForDirectory('\Global??', Root, SupportedTypes,
      InheritedObjects).IsSuccess then
      Objects := MergeSuggestions(Objects, InheritedObjects);
end;

function RtlxpCollectForWindowStation(
  const Root: String;
  out Objects: TArray<TNamespaceEntry>
): TNtxStatus;
var
  hxWinSta: IHandle;
  Desktops: TArray<String>;
  i: Integer;
begin
  Result := NtxOpenWindowStation(hxWinSta, WINSTA_ENUMDESKTOPS, Root);

  if not Result.IsSuccess then
    Exit;

  Result := NtxEnumerateDesktops(hxWinSta, Desktops);

  if not Result.IsSuccess then
    Exit;

  SetLength(Objects, Length(Desktops));

  for i := 0 to High(Desktops) do
    Objects[i] := MakeNamespaceEntry(Root, Desktops[i], otDesktop);
end;

function RtlxpCollectSessionDirectories(
  const Root: String;
  SessionId: Cardinal;
  const PerSessionPath: String;
  out Objects: TArray<TNamespaceEntry>
): TNtxStatus;
var
  i, j: Integer;
  WindowStations: TArray<String>;
begin
  if PerSessionPath = '' then
  begin
    // Suggest known per-session directories
    Result.Location := 'RtlxpCollectSessionDirectories';
    Result.Status := STATUS_MORE_ENTRIES;

    Objects := [
      RtlxQueryNamespaceEntry(Root + '\Windows', [otSymlink, otDirectory]),
      RtlxQueryNamespaceEntry(Root + '\DosDevices', [otSymlink, otDirectory]),
      RtlxQueryNamespaceEntry(Root + '\BaseNamedObjects', [otSymlink, otDirectory]),
      RtlxQueryNamespaceEntry(Root + '\AppContainerNamedObjects', [otSymlink, otDirectory])
    ];

    // Remove non-existing entries
    j := 0;
    for i := 0 to High(Objects) do
      if Objects[i].KnownType <> otUnknown then
      begin
        if i <> j then
          Objects[j] := Objects[i];
        Inc(j);
      end;

    SetLength(Objects, j);
  end
  else if (SessionId = RtlGetCurrentPeb.SessionID) and
    RtlxEqualStrings(PerSessionPath, 'Windows\WindowStations') then
  begin
    // Suggest window stations
    Result := NtxEnumerateWindowStations(WindowStations);

    if not Result.IsSuccess then
      Exit;

    SetLength(Objects, Length(WindowStations));

    for i := 0 to High(WindowStations) do
      Objects[i] := MakeNamespaceEntry(Root, WindowStations[i], otWindowStation);
  end
  else
  begin
    Result.Location := 'RtlxpCollectSessionDirectories';
    Result.Status := STATUS_NOT_SUPPORTED;
  end;
end;

function RtlxEnumerateNamespaceEntries;
var
  TrimmedRoot, RemainingSessionPath: String;
  SessionId: Cardinal;
begin
  // Enumerate the root of the namespace manually by adding the "\" entry
  if Root = '' then
  begin
    Suggestions := [MakeNamespaceEntry('', '', otDirectory)];
    Exit(NtxSuccess);
  end;

  if Root <> '\' then
    TrimmedRoot := TrimLastBackslash(Root)
  else
    TrimmedRoot := Root;

  Suggestions := nil;

  // Enumerate objects in namespace directories
  if SupportedTypes - [otRegistryKey] <> [] then
  begin
    Result := RtlxpCollectForDirectory(TrimmedRoot, TrimmedRoot, SupportedTypes,
      Suggestions);

    // In case of failing on per-session directories, at least add known entries
    if (Result.Status = STATUS_ACCESS_DENIED) and
      IsSessionsDirectory(TrimmedRoot, RemainingSessionPath, SessionId) then
      Result := RtlxpCollectSessionDirectories(TrimmedRoot, SessionId,
        RemainingSessionPath, Suggestions);

    if IsMatchingTypeStatus(Result) then
      Exit;
  end;

  // Enumerate objects in files directories
  if NT_NAMESPACE_FILE_TYPES * SupportedTypes <> [] then
  begin
    Result := RtlxpCollectForFile(Root, SupportedTypes, Suggestions);

    if IsMatchingTypeStatus(Result) then
      Exit;
  end;

  // Enumerate objects in registry keys
  if otRegistryKey in SupportedTypes then
  begin
    if not (otDirectory in SupportedTypes) and (Root = '\') then
    begin
      // Make the registry root discoverable
      Suggestions := [MakeNamespaceEntry(Root, 'REGISTRY', otRegistryKey)];
      Exit(NtxSuccess);
    end;

    Result := RtlxpCollectForRegistry(Root, SupportedTypes, Suggestions);

    if IsMatchingTypeStatus(Result) then
      Exit;
  end;

  // Enumerate desktops under window stations
  if otDesktop in SupportedTypes then
  begin
    Result := RtlxpCollectForWindowStation(TrimmedRoot, Suggestions);

    if IsMatchingTypeStatus(Result) then
      Exit;
  end;
end;

function RtlxFindNameInDirectory(
  const DirectoryName: String;
  const ChildName: String;
  out TypeName: String
): TNtxStatus;
var
  hxDirectory: IHandle;
  Block: TArray<TNtxDirectoryEntry>;
  Index: Cardinal;
  i: Integer;
begin
  Result := NtxOpenDirectory(hxDirectory, DIRECTORY_QUERY, DirectoryName);

  if not Result.IsSuccess then
    Exit;

  // Enumerate directory content in blocks
  Index := 0;
  while NtxQueryDirectoryBulk(hxDirectory, Index, Block).HasEntry(Result) do
  begin
    // Try to find our name
    for i := 0 to High(Block) do
      if RtlxEqualStrings(ChildName, Block[i].Name) then
      begin
        TypeName := Block[i].TypeName;
        Exit;
      end;

    // Advance the search
    Inc(Index, Length(Block));
  end;

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlxFindNameInDirectory';
  Result.Status := STATUS_NOT_FOUND;
end;

function RtlxQueryNamespaceEntry;
var
  ParentName, TrimmedChildName, TrimmedFullPath: String;
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
    Result.TypeName := TYPE_NAMES[otDirectory];
    Result.KnownType := otDirectory;
    Exit;
  end;

  SupportedTypes := SupportedTypes - [otUnknown];

  // Most types don't support the trailing back slash; we can ignore it there
  TrimmedFullPath := TrimLastBackslash(FullPath);

  // For symlinks, we use this back slash as an indicator that the caller
  // wants to open the target instead of the symlink itself.
  if (otSymlink in SupportedTypes) and (FullPath[High(FullPath)] = '\') then
    SupportedTypes := SupportedTypes - [otSymlink];

  // If we can get the type from the parent directory, use it
  if RtlxSplitPathOnLast(TrimmedFullPath, ParentName, TrimmedChildName) and
    RtlxFindNameInDirectory(RtlxStringOrDefault(ParentName, '\'),
    TrimmedChildName, Result.TypeName).IsSuccess then
  begin
    Result.KnownType := LookupObjectType(Result.TypeName, SupportedTypes);

    if Result.KnownType = otSymlink then
    begin
      // If the result is a symlink and we need to follow it, we are not done
      Result.KnownType := otUnknown;
      Result.TypeName := '';
    end;

    if Result.KnownType <> otUnknown then
      Exit;
  end;

  // Check all non-file types
  for i in SupportedTypes - NT_NAMESPACE_FILE_TYPES do
  begin
    // Try to open the name as the specified type
    Status := RtlxTestObjectType(FullPath, TrimmedFullPath, i);

    if IsMatchingTypeStatus(Status) then
    begin
      Result.TypeName := TYPE_NAMES[i];
      Result.KnownType := i;
      Exit;
    end;
  end;

  if NT_NAMESPACE_FILE_TYPES * SupportedTypes <> [] then
  begin
    // Check if the object is a file and if so, which kind
    Result.KnownType := RtlxTestFileTypes(FullPath, TrimmedFullPath,
      SupportedTypes);
    Result.TypeName := TYPE_NAMES[Result.KnownType];
  end;
end;

function ShlxPrepareNamespaceSuggestions;
begin
  Result := ShlxPrepareDynamicSuggestions(
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
