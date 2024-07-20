unit NtUtils.Files.Directories;

{
  The module allows enumerating and traversing directories on a filesystem.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntioapi, Ntapi.ntseapi, NtUtils, NtUtils.Files,
  DelphiApi.Reflection;

type
{
  Info class                         | A/S/T | EA | Short | ID | ID 128 | Reparse | TX | Min version
  ---------------------------------- | ----- | -- | ----- | -- | ------ | ------- | -- | ------------
  FileNamesInformation               |       |    |       |    |        |         |    |
  FileDirectoryInformation           |   +   |    |       |    |        |         |    |
  FileFullDirectoryInformation       |   +   | +  |       |    |        |         |    |
  FileBothDirectoryInformation       |   +   | +  |   +   |    |        |         |    |
  FileIdBothDirectoryInformation     |   +   | +  |   +   | +  |        |         |    |
  FileIdFullDirectoryInformation     |   +   | +  |       | +  |        |         |    |
  FileIdGlobalTxDirectoryInformation |   +   |    |       | +  |        |         | +  |
  FileIdExtdDirectoryInformation     |   +   | +  |       | +  |   +    |    +    |    | Win 8+
  FileIdExtdBothDirectoryInformation |   +   | +  |   +   | +  |   +    |    +    |    | Win 10 TH1+

  A/S/T - Attributes, Size, Times
}

  TDirectoryFileFields = set of (
    fcAttributes,
    fcSize,
    fcTimes,
    fcShortName,
    fcEaSize,
    fcFileId,
    fcFileId128,
    fcReparseTag,
    fcTransactionInfo
  );

  TDirectoryFileEntry = record
    OptionalFields: TDirectoryFileFields;
    [Aggregate] Common: TFileDirectoryCommonInformation;
    FileName: String;
    ShortName: String;
    [Bytes] EaSize: Cardinal;
    FileId: TFileId;
    FileId128: TFileId128;
    ReparsePointTag: TReparseTag;
    LockingTransactionId: TGuid;
    TxInfoFlags: TFileTxInfoFlags;
  end;

  // Note: ContinueTraversing allows callers to explicitly cancel traversing of
  // specific locations, as well as enable it back when skipping reparse points 
  // or reached the maximum depth.
  TFileTraverseCallback = reference to function(
    const FileInfo: TDirectoryFileEntry;
    const Root: IHandle;
    const RootName: String;
    var ContinueTraversing: Boolean
  ): TNtxStatus;

  TFileTraverseBulkCallback = reference to function(
    const Files: TArray<TDirectoryFileEntry>;
    const Root: IHandle;
    const RootName: String;
    var ContinueTraversing: TArray<Boolean>
  ): TNtxStatus;

  TFileTraverseOptions = set of (
    ftInvokeOnFiles,
    ftInvokeOnDirectories,
    ftIgnoreCallbackFailures,
    ftIgnoreTraverseFailures,
    ftFollowReparsePoints
  );

// Iterate a content of a filesystem directory one entry at at time.
function NtxGetNextDirectoryFile(
  [Access(FILE_LIST_DIRECTORY)] const hxFile: IHandle;
  out Entry: TDirectoryFileEntry;
  var FirstScan: Boolean;
  InfoClass: TFileInformationClass = FileDirectoryInformation;
  [opt] const Pattern: String = ''
): TNtxStatus;

// Enumerate files in a filesystem directory multiple entries at a time
function NtxIterateDirectoryFile(
  [Access(FILE_LIST_DIRECTORY)] const hxFile: IHandle;
  out Files: TArray<TDirectoryFileEntry>;
  var FirstScan: Boolean;
  InfoClass: TFileInformationClass = FileDirectoryInformation;
  SuggestedBufferSize: NativeUInt = $1000;
  [opt] const Pattern: String = ''
): TNtxStatus;

// Enumerate all files in a filesystem directory
function NtxEnumerateDirectoryFile(
  [Access(FILE_LIST_DIRECTORY)] const hxFile: IHandle;
  out Files: TArray<TDirectoryFileEntry>;
  InfoClass: TFileInformationClass = FileDirectoryInformation;
  [opt] const Pattern: String = '';
  SuggestedBufferSize: NativeUInt = $4000
): TNtxStatus;

// Recursively traverse a filesystem directory and its sub-directories.
// Invokes the callback on one file at a time.
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function NtxTraverseDirectoryFile(
  [opt, Access(FILE_LIST_DIRECTORY)] hxRoot: IHandle;
  [opt, Access(FILE_LIST_DIRECTORY)] OpenParameters: IFileParameters;
  Callback: TFileTraverseCallback;
  Options: TFileTraverseOptions = [ftInvokeOnFiles, ftInvokeOnDirectories];
  InfoClass: TFileInformationClass = FileDirectoryInformation;
  MaxDepth: Integer = 32767
): TNtxStatus;

// Recursively traverse a filesystem directory and its sub-directories
// Invokes the callback on all files in a directory at a time.
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function NtxTraverseDirectoryFileBulk(
  [opt, Access(FILE_LIST_DIRECTORY)] hxRoot: IHandle;
  [opt, Access(FILE_LIST_DIRECTORY)] OpenParameters: IFileParameters;
  Callback: TFileTraverseBulkCallback;
  Options: TFileTraverseOptions = [ftInvokeOnFiles, ftInvokeOnDirectories];
  InfoClass: TFileInformationClass = FileDirectoryInformation;
  MaxDepth: Integer = 32767
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Files.Open, NtUtils.Synchronization,
  NtUtils.Files.Operations, NtUtils.Security.Sid, NtUtils.SysUtils,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  PFolderEntry = ^TDirectoryFileEntry;

function RtlxpCaptureDirectoryInfo(
  [in, out] var Buffer: Pointer;
  InfoClass: TFileInformationClass;
  [out, opt] Entry: PFolderEntry
): Boolean;
var
  BufferNames: PFileNamesInformation absolute Buffer;
  BufferDir: PFileDirectoryInformation absolute Buffer;
  BufferFull: PFileFullDirInformation absolute Buffer;
  BufferBoth: PFileBothDirInformation absolute Buffer;
  BufferIdBoth: PFileIdBothDirInformation absolute Buffer;
  BufferIdFull: PFileIdFullDirInformation absolute Buffer;
  BufferIdGlobalTx: PFileIdGlobalTxDirInformation absolute Buffer;
  BufferIdExtd: PFileIdExtdDirInformation absolute Buffer;
  BufferIdExtdBoth: PFileIdExtdBothDirInformation absolute Buffer;
begin
  case InfoClass of
    FileNamesInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [];
          Entry.Common.NextEntryOffset := BufferNames.NextEntryOffset;
          Entry.Common.FileIndex := BufferNames.FileIndex;
          Entry.Common.FileNameLength := BufferNames.FileNameLength;

          SetString(Entry.FileName, BufferNames.FileName,
            BufferNames.FileNameLength div SizeOf(WideChar));
        end;

        Result := BufferNames.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferNames.NextEntryOffset);
      end;

    FileDirectoryInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [fcAttributes, fcSize, fcTimes];
          Entry.Common := BufferDir.Common;

          SetString(Entry.FileName, BufferDir.FileName,
            BufferDir.Common.FileNameLength div SizeOf(WideChar));
        end;

        Result := BufferDir.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferDir.Common.NextEntryOffset);
      end;


    FileFullDirectoryInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [fcAttributes, fcSize, fcTimes, fcEaSize];
          Entry.Common := BufferFull.Common;
          Entry.EaSize := BufferFull.EaSize;

          SetString(Entry.FileName, BufferFull.FileName,
            BufferFull.Common.FileNameLength div SizeOf(WideChar));
        end;

        Result := BufferFull.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferFull.Common.NextEntryOffset);
      end;

    FileBothDirectoryInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [fcAttributes, fcSize, fcTimes, fcEaSize,
            fcShortName];
          Entry.Common := BufferBoth.Common;
          Entry.EaSize := BufferBoth.EaSize;

          SetString(Entry.FileName, BufferBoth.FileName,
            BufferBoth.Common.FileNameLength div SizeOf(WideChar));

          SetString(Entry.ShortName, BufferBoth.ShortName,
            BufferBoth.ShortNameLength div SizeOf(WideChar));
        end;

        Result := BufferBoth.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferBoth.Common.NextEntryOffset);
      end;

    FileIdBothDirectoryInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [fcAttributes, fcSize, fcTimes, fcEaSize,
            fcShortName, fcFileId];
          Entry.Common := BufferIdBoth.Common;
          Entry.EaSize := BufferIdBoth.EaSize;
          Entry.FileId := BufferIdBoth.FileId;

          SetString(Entry.FileName, BufferIdBoth.FileName,
            BufferIdBoth.Common.FileNameLength div SizeOf(WideChar));

          SetString(Entry.ShortName, BufferIdBoth.ShortName,
            BufferIdBoth.ShortNameLength div SizeOf(WideChar));
        end;

        Result := BufferIdBoth.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdBoth.Common.NextEntryOffset);
      end;

    FileIdFullDirectoryInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [fcAttributes, fcSize, fcTimes, fcEaSize,
            fcFileId];
          Entry.Common := BufferIdFull.Common;
          Entry.EaSize := BufferIdFull.EaSize;
          Entry.FileId := BufferIdFull.FileId;

          SetString(Entry.FileName, BufferIdFull.FileName,
            BufferIdFull.Common.FileNameLength div SizeOf(WideChar));
        end;

        Result := BufferIdFull.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdFull.Common.NextEntryOffset);
      end;


    FileIdGlobalTxDirectoryInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [fcAttributes, fcSize, fcTimes, fcFileId,
            fcTransactionInfo];
          Entry.Common := BufferIdGlobalTx.Common;
          Entry.FileId := BufferIdGlobalTx.FileId;
          Entry.LockingTransactionId := BufferIdGlobalTx.LockingTransactionId;
          Entry.TxInfoFlags := BufferIdGlobalTx.TxInfoFlags;

          SetString(Entry.FileName, BufferIdGlobalTx.FileName,
            BufferIdGlobalTx.Common.FileNameLength div SizeOf(WideChar));
        end;

        Result := BufferIdGlobalTx.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdGlobalTx.Common.NextEntryOffset);
      end;

    FileIdExtdDirectoryInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [fcAttributes, fcSize, fcTimes, fcEaSize,
            fcFileId, fcFileId128, fcReparseTag];
          Entry.Common := BufferIdExtd.Common;
          Entry.EaSize := BufferIdExtd.EaSize;
          Entry.FileId128 := BufferIdExtd.FileId;
          Entry.ReparsePointTag := BufferIdExtd.ReparsePointTag;

          if Entry.FileId128.High = 0 then
            Entry.FileId := Entry.FileId128.Low
          else
            Entry.FileId := FILE_INVALID_FILE_ID;

          SetString(Entry.FileName, BufferIdExtd.FileName,
            BufferIdExtd.Common.FileNameLength div SizeOf(WideChar));
        end;

        Result := BufferIdExtd.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdExtd.Common.NextEntryOffset);
      end;

    FileIdExtdBothDirectoryInformation:
      begin
        if Assigned(Entry) then
        begin
          Entry.OptionalFields := [fcAttributes, fcSize, fcTimes, fcEaSize,
            fcFileId, fcFileId128, fcReparseTag, fcShortName];
          Entry.Common := BufferIdExtdBoth.Common;
          Entry.EaSize := BufferIdExtdBoth.EaSize;
          Entry.FileId128 := BufferIdExtdBoth.FileId;
          Entry.ReparsePointTag := BufferIdExtdBoth.ReparsePointTag;

          if Entry.FileId128.High = 0 then
            Entry.FileId := Entry.FileId128.Low
          else
            Entry.FileId := FILE_INVALID_FILE_ID;

          SetString(Entry.FileName, BufferIdExtdBoth.FileName,
            BufferIdExtdBoth.Common.FileNameLength div SizeOf(WideChar));

          SetString(Entry.ShortName, BufferIdExtdBoth.ShortName,
            BufferIdExtdBoth.ShortNameLength div SizeOf(WideChar));
        end;

        Result := BufferIdExtdBoth.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdExtdBoth.Common.NextEntryOffset);
      end;
  else
    Result := False;
  end;
end;

function NtxQueryDirectoryFile(
  [Access(FILE_LIST_DIRECTORY)] const hxFile: IHandle;
  InfoClass: TFileInformationClass;
  out Buffer: IMemory;
  ReturnSingleEntry: Boolean;
  FirstScan: Boolean;
  SuggestedBufferSize: NativeUInt;
  [opt] const Pattern: String
): TNtxStatus;
var
  Isb: IMemory<PIoStatusBlock>;
  PatternStr: TNtUnicodeString;
begin
  Result := RtlxInitUnicodeString(PatternStr, Pattern);

  if not Result.IsSuccess then
    Exit;

  IMemory(Isb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));

  Result.Location := 'NtQueryDirectoryFile';
  Result.LastCall.Expects<TIoDirectoryAccessMask>(FILE_LIST_DIRECTORY);
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  IMemory(Buffer) := Auto.AllocateDynamic(SuggestedBufferSize);
  repeat
    Result.Status := NtQueryDirectoryFile(HandleOrDefault(hxFile), 0, nil, nil,
      Isb.Data, Buffer.Data, Buffer.Size, InfoClass, ReturnSingleEntry,
      PatternStr.RefOrNil, FirstScan);

    AwaitFileOperation(Result, hxFile, Isb);
  until not NtxExpandBufferEx(Result, IMemory(Buffer), Buffer.Size shl 1,
    nil);

  if (Result.Status = STATUS_NO_SUCH_FILE) or
    (Result.Status = STATUS_NO_MORE_FILES) then
  begin
    Result.Location := 'NtxQueryDirectoryFile';
    Result.LastCall.Expects<TIoDirectoryAccessMask>(FILE_LIST_DIRECTORY);
    Result.LastCall.UsesInfoClass(InfoClass, icQuery);
    Result.Status := STATUS_NO_MORE_ENTRIES;
  end;
end;

function NtxGetNextDirectoryFile;
var
  Buffer: IMemory;
  BufferStart: Pointer;
begin
  // Check for supported info classes
  case InfoClass of
    FileNamesInformation,
    FileDirectoryInformation, FileFullDirectoryInformation,
    FileBothDirectoryInformation, FileIdBothDirectoryInformation,
    FileIdFullDirectoryInformation, FileIdGlobalTxDirectoryInformation,
    FileIdExtdDirectoryInformation, FileIdExtdBothDirectoryInformation: ;
  else
    Result.Location := 'NtxGetNextDirectoryFile';
    Result.Status := STATUS_INVALID_INFO_CLASS;
  end;

  Result := NtxQueryDirectoryFile(hxFile, InfoClass, Buffer, True, FirstScan,
    MAX_PATH, Pattern);

  if not Result.IsSuccess then
    Exit;

  FirstScan := False;
  BufferStart := Buffer.Data;
  RtlxpCaptureDirectoryInfo(BufferStart, InfoClass, @Entry);
end;

function NtxIterateDirectoryFile;
var
  Buffer: IMemory;
  BufferCursor: Pointer;
  Count: Integer;
  i: Integer;
begin
  Files := nil;

  // Check for supported modes
  case InfoClass of
    FileNamesInformation,
    FileDirectoryInformation, FileFullDirectoryInformation,
    FileBothDirectoryInformation, FileIdBothDirectoryInformation,
    FileIdFullDirectoryInformation, FileIdGlobalTxDirectoryInformation,
    FileIdExtdDirectoryInformation, FileIdExtdBothDirectoryInformation: ;
  else
    Result.Location := 'NtxIterateDirectoryFile';
    Result.Status := STATUS_INVALID_INFO_CLASS;
  end;

  Result := NtxQueryDirectoryFile(hxFile, InfoClass, Buffer, False, FirstScan,
    SuggestedBufferSize, Pattern);

  if not Result.IsSuccess then
    Exit;

  // Count returned entries
  Count := 0;
  BufferCursor := Buffer.Data;

  repeat
    Inc(Count);
  until not RtlxpCaptureDirectoryInfo(BufferCursor, InfoClass, nil);

  // Save them
  SetLength(Files, Count);
  BufferCursor := Buffer.Data;

  for i := 0 to High(Files) do
    RtlxpCaptureDirectoryInfo(BufferCursor, InfoClass, @Files[i]);

  FirstScan := False;
end;

function NtxEnumerateDirectoryFile;
var
  FirstScan: Boolean;
  FilesPortion: TArray<TDirectoryFileEntry>;
begin
  Files := nil;
  FirstScan := True;

  // Collect all entries
  while NtxIterateDirectoryFile(hxFile, FilesPortion, FirstScan, InfoClass,
    SuggestedBufferSize, Pattern).HasEntry(Result) do
    Files := Files + FilesPortion;
end;

function NtxTraverseDirectoryFileWorker(
  const hxRoot: IHandle;
  const AccumulatedPath: String;
  const ParametersTemplate: IFileParameters;
  const Callback: TFileTraverseCallback;
  InfoClass: TFileInformationClass;
  Options: TFileTraverseOptions;
  RemainingDepth: Integer
): TNtxStatus;
var
  Files: TArray<TDirectoryFileEntry>;
  hxSubDirectory: IHandle;
  FirstScan, IsDirectory, ContinueTraversing, MoreEntries: Boolean;
  i: Integer;
begin
  FirstScan := True;
  MoreEntries := False;

  repeat
    // Retrieve a portion of files and sub-directories inside the root
    Result := NtxIterateDirectoryFile(hxRoot, Files, FirstScan,
      InfoClass);

    if Result.Status = STATUS_NO_MORE_ENTRIES then
      Break;

    if not Result.IsSuccess then
    begin
      // Allow skipping this location if we cannot traverse it
      if ftIgnoreTraverseFailures in Options then
      begin
        MoreEntries := True;
        Break;
      end;

      Exit;
    end;

    // Process each file in this block
    for i := 0 to High(Files) do
    begin
      // Skip pseudo-directories
      if (Files[i].FileName = '.') or (Files[i].FileName = '..')  then
        Continue;

      IsDirectory := BitTest(Files[i].Common.FileAttributes and
        FILE_ATTRIBUTE_DIRECTORY);

      // Allow skipping junctions and symlinks
      ContinueTraversing := IsDirectory and (RemainingDepth > 0) and (
        (ftFollowReparsePoints in Options) or not
        BitTest(Files[i].Common.FileAttributes and FILE_ATTRIBUTE_REPARSE_POINT)
      );

      // Invoke the callback
      if (IsDirectory and (ftInvokeOnDirectories in Options)) or
        (not IsDirectory and (ftInvokeOnFiles in Options)) then
      begin
        Result := Callback(Files[i], hxRoot, AccumulatedPath,
          ContinueTraversing);

        // Fail with callback failures, unless told to ignore them
        if not Result.IsSuccess and
          not (ftIgnoreCallbackFailures in Options) then
          Exit;
      end;

      if not IsDirectory or not ContinueTraversing then
        Continue;
        
      // Open the sub-directory for further traversing
      Result := NtxOpenFile(hxSubDirectory, ParametersTemplate
        .UseFileName(Files[i].FileName).UseRoot(hxRoot));

      if not Result.IsSuccess then
      begin
        // Allow skipping directories we cannot access
        if ftIgnoreTraverseFailures in Options then
        begin
          MoreEntries := True;
          Continue;
        end;

        Exit;
      end;

      // Call recursively
      Result := NtxTraverseDirectoryFileWorker(hxSubDirectory,
        RtlxCombinePaths(AccumulatedPath, Files[i].FileName),
        ParametersTemplate, Callback, InfoClass, Options, RemainingDepth - 1);

      if Result.Status = STATUS_MORE_ENTRIES then
        MoreEntries := True
      else if not Result.IsSuccess then
        Exit;
    end;
  until False;

  // We reach here only if no unhandled errors occurred.
  Result.Location := 'NtxTraverseFolderWorker';

  if MoreEntries then
    Result.Status := STATUS_MORE_ENTRIES
  else
    Result.Status := STATUS_SUCCESS;
end;

function NtxTraverseDirectoryFile;
begin
  // Check for supported info classes. Note: we don't allow FileNamesInformation
  // because we need to know attributes internally.
  case InfoClass of
    FileDirectoryInformation, FileFullDirectoryInformation,
    FileBothDirectoryInformation, FileIdBothDirectoryInformation,
    FileIdFullDirectoryInformation, FileIdGlobalTxDirectoryInformation,
    FileIdExtdDirectoryInformation, FileIdExtdBothDirectoryInformation: ;
  else
    Result.Location := 'NtxTraverseDirectoryFile';
    Result.Status := STATUS_INVALID_INFO_CLASS;
  end;

  // Always use synchronous I/O and at least directory listing access
  OpenParameters := FileParameters(OpenParameters);
  OpenParameters := OpenParameters
    .UseOptions(OpenParameters.Options or FILE_DIRECTORY_FILE)
    .UseSyncMode(fsSynchronousNonAlert)
    .UseAccess(OpenParameters.Access or FILE_LIST_DIRECTORY);

  // Open the root folder if not provided
  if not Assigned(hxRoot) then
  begin
    Result := NtxOpenFile(hxRoot, OpenParameters);

    if not Result.IsSuccess then
      Exit;
  end;

  // Since we want to reuse the open options, clear the file ID information
  OpenParameters := OpenParameters.UseFileId(0);

  Result := NtxTraverseDirectoryFileWorker(hxRoot, OpenParameters.FileName,
    OpenParameters, Callback, InfoClass, Options, MaxDepth);
end;

function NtxTraverseDirectoryFileBulkWorker(
  const hxRoot: IHandle;
  const AccumulatedPath: String;
  const ParametersTemplate: IFileParameters;
  const Callback: TFileTraverseBulkCallback;
  InfoClass: TFileInformationClass;
  Options: TFileTraverseOptions;
  RemainingDepth: Integer
): TNtxStatus;
var
  Files, FilesFiltered: TArray<TDirectoryFileEntry>;
  ContinueTraversingFiltered: TArray<Boolean>;
  IndexToFilteredIndex: TArray<Integer>;
  hxSubDirectory: IHandle;
  MoreEntries, IsDirectory, ContinueTraversing: Boolean;
  i, j: Integer;
begin
  MoreEntries := False;

  // Retrieve all files from the directory
  Result := NtxEnumerateDirectoryFile(hxRoot, Files, InfoClass);

  if not Result.IsSuccess then
  begin
    // Allow skipping this location if we cannot traverse it
    if ftIgnoreTraverseFailures in Options then
      MoreEntries := True
    else
      Exit;
  end;

  // Count entries we want to show to the callback
  j := 0;
  for i := 0 to High(Files) do
  begin
    // Skip pseudo-directories
    if (Files[i].FileName = '.') or (Files[i].FileName = '..')  then
      Continue;

    IsDirectory := BitTest(Files[i].Common.FileAttributes and
      FILE_ATTRIBUTE_DIRECTORY);

    if (IsDirectory and (ftInvokeOnDirectories in Options)) or
      (not IsDirectory and (ftInvokeOnFiles in Options)) then
      Inc(j);
  end;

  // Filter them, plus build an index conversion table and an array that
  // allows the callback to control further traversing
  SetLength(FilesFiltered, j);
  SetLength(ContinueTraversingFiltered, j);
  SetLength(IndexToFilteredIndex, Length(Files));

  j := 0;
  for i := 0 to High(Files) do
  begin
    IndexToFilteredIndex[i] := -1;

    // Skip pseudo-directories
    if (Files[i].FileName = '.') or (Files[i].FileName = '..')  then
      Continue;

    IsDirectory := BitTest(Files[i].Common.FileAttributes and
      FILE_ATTRIBUTE_DIRECTORY);

    if (IsDirectory and (ftInvokeOnDirectories in Options)) or
      (not IsDirectory and (ftInvokeOnFiles in Options)) then
    begin
      FilesFiltered[j] := Files[i];
      IndexToFilteredIndex[i] := j;

      // Choose if we plan to further traverse this directory
      ContinueTraversingFiltered[j] := IsDirectory and (RemainingDepth > 0) and (
        (ftFollowReparsePoints in Options) or not
        BitTest(Files[i].Common.FileAttributes and FILE_ATTRIBUTE_REPARSE_POINT)
      );

      Inc(j);
    end;
  end;

  // Invoke the callback
  Result := Callback(FilesFiltered, hxRoot, AccumulatedPath,
    ContinueTraversingFiltered);

  // Fail with callback failures, unless ignoring them
  if not Result.IsSuccess and not (ftIgnoreCallbackFailures in Options) then
    Exit;

  // Just in case: make sure the callback didn't alter array length
  if Length(ContinueTraversingFiltered) <> Length(FilesFiltered) then
  begin
    Result.Location := 'NtxTraverseDirectoryFileBulkWorker';
    Result.Status := STATUS_ASSERTION_FAILURE;
    Exit;
  end;

  // Traverse all sub-directories  
  for i := 0 to High(Files) do
  begin      
    // Skip non-directories
    if not BitTest(Files[i].Common.FileAttributes and
      FILE_ATTRIBUTE_DIRECTORY) then
      Continue;
    
    // Skip pseudo-directories
    if (Files[i].FileName = '.') or (Files[i].FileName = '..')  then
      Continue;

    // Allow the callback to override further traversing options
    if IndexToFilteredIndex[i] >= 0 then
      ContinueTraversing := ContinueTraversingFiltered[IndexToFilteredIndex[i]]
    else
      ContinueTraversing := (RemainingDepth > 0) and (
        (ftFollowReparsePoints in Options) or not
        BitTest(Files[i].Common.FileAttributes and FILE_ATTRIBUTE_REPARSE_POINT)
      );

    if not ContinueTraversing then
      Continue;
    
    // Open the sub-directory
    Result := NtxOpenFile(hxSubDirectory, ParametersTemplate
      .UseFileName(Files[i].FileName).UseRoot(hxRoot));

    if not Result.IsSuccess then
    begin
      // Allow skipping directories we cannot access
      if ftIgnoreTraverseFailures in Options then
      begin
        MoreEntries := True;
        Continue;
      end;

      Exit;
    end;

    // Call recursively
    Result := NtxTraverseDirectoryFileBulkWorker(hxSubDirectory,
      RtlxCombinePaths(AccumulatedPath, Files[i].FileName), ParametersTemplate,
      Callback, InfoClass, Options, RemainingDepth - 1);

    if Result.Status = STATUS_MORE_ENTRIES then
      MoreEntries := True
    else if not Result.IsSuccess then
      Exit;
  end;

  // We reach here only if no unhandled errors occurred.
  Result.Location := 'NtxTraverseDirectoryFileBulkWorker';

  if MoreEntries then
    Result.Status := STATUS_MORE_ENTRIES
  else
    Result.Status := STATUS_SUCCESS;
end;

function NtxTraverseDirectoryFileBulk;
begin
  // Check for supported info classes. Note: we don't allow FileNamesInformation
  // because we need to know attributes internally.
  case InfoClass of
    FileDirectoryInformation, FileFullDirectoryInformation,
    FileBothDirectoryInformation, FileIdBothDirectoryInformation,
    FileIdFullDirectoryInformation, FileIdGlobalTxDirectoryInformation,
    FileIdExtdDirectoryInformation, FileIdExtdBothDirectoryInformation: ;
  else
    Result.Location := 'NtxTraverseDirectoryFileBulk';
    Result.Status := STATUS_INVALID_INFO_CLASS;
  end;

  // Always use synchronous I/O and at least directory listing access
  OpenParameters := FileParameters(OpenParameters);
  OpenParameters := OpenParameters
    .UseOptions(OpenParameters.Options or FILE_DIRECTORY_FILE)
    .UseSyncMode(fsSynchronousNonAlert)
    .UseAccess(OpenParameters.Access or FILE_LIST_DIRECTORY);

  // Open the root folder if not provided
  if not Assigned(hxRoot) then
  begin
    Result := NtxOpenFile(hxRoot, OpenParameters);

    if not Result.IsSuccess then
      Exit;
  end;

  // Since we want to reuse the open options, clear the file ID information
  OpenParameters := OpenParameters.UseFileId(0);

  Result := NtxTraverseDirectoryFileBulkWorker(hxRoot, OpenParameters.FileName,
    OpenParameters, Callback, InfoClass, Options, MaxDepth);
end;

end.
