unit NtUtils.Files.Folders;

{
  The module allows enumerating and traversing folders on a filesystem.
}

interface

uses
  Ntapi.ntioapi, Ntapi.ntseapi, NtUtils, NtUtils.Files, DelphiApi.Reflection;

type
{
  Info class                         | EA | Short | ID | ID 128 | Reparse | TX |
  ---------------------------------- | -- | ----- | -- | ------ | ------- | -- |
  FileDirectoryInformation           |    |       |    |        |         |    |
  FileFullDirectoryInformation       | +  |       |    |        |         |    |
  FileBothDirectoryInformation       | +  |   +   |    |        |         |    |
  FileIdBothDirectoryInformation     | +  |   +   | +  |        |         |    |
  FileIdFullDirectoryInformation     | +  |       | +  |        |         |    |
  FileIdGlobalTxDirectoryInformation |    |       | +  |        |         | +  |
  FileIdExtdDirectoryInformation     | +  |       | +  |   +    |    +    |    |
  FileIdExtdBothDirectoryInformation | +  |   +   | +  |   +    |    +    |    |
}

  TFolderFields = set of (
    fcShortName,
    fcEaSize,
    fcFileId,
    fcFileId128,
    fcReparseTag,
    fcTransactionInfo
  );

  TFolderEntry = record
    OptionalFields: TFolderFields;
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

  // Note: ContinuePropagation applies only to folders and allows callers can
  // explicitly cancel traversing of specific locations, as well as enable it
  // back when skipping reparse points.
  TFileTraverseCallback = reference to function(
    const FileInfo: TFolderEntry;
    const Root: IHandle;
    const RootName: String;
    var ContinuePropagation: Boolean
  ): TNtxStatus;

  TFileTraverseOptions = set of (
    ftInvokeOnFiles,
    ftInvokeOnFolders,
    ftIgnoreCallbackFailures,
    ftIgnoreTraverseFailures,
    ftSkipReparsePoints
  );

// Iterate on the condent of a filesystem directory
function NtxIterateFolder(
  [Access(FILE_LIST_DIRECTORY)] hFolder: THandle;
  out Entry: TFolderEntry;
  var FirstScan: Boolean;
  InfoClass: TFileInformationClass = FileDirectoryInformation;
  [opt] const Pattern: String = ''
): TNtxStatus;

// Enumerate content of a filesystem directory
function NtxEnumerateFolder(
  [Access(FILE_LIST_DIRECTORY)] hFolder: THandle;
  out Files: TArray<TFolderEntry>;
  InfoClass: TFileInformationClass = FileDirectoryInformation;
  [opt] const Pattern: String = ''
): TNtxStatus;

// Recursively traverse a filesystem directory and its sub-directories
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
function NtxTraverseFolder(
  [opt, Access(FILE_LIST_DIRECTORY)] hxFolder: IHandle;
  [opt, Access(FILE_LIST_DIRECTORY)] OpenParameters: IFileOpenParameters;
  const Callback: TFileTraverseCallback;
  Options: TFileTraverseOptions = [ftInvokeOnFiles, ftInvokeOnFolders,
    ftSkipReparsePoints];
  MaxDepth: Integer = 64
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Files.Open, NtUtils.Synchronization,
  NtUtils.Files.Operations, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxpCaptureDirectoryInfo(
  [in, out] var Buffer: Pointer;
  InfoClass: TFileInformationClass;
  out Entry: TFolderEntry
): Boolean;
var
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
    FileDirectoryInformation:
      begin
        Entry.OptionalFields := [];
        Entry.Common := BufferDir.Common;

        SetString(Entry.FileName, BufferDir.FileName,
          BufferDir.Common.FileNameLength div SizeOf(WideChar));

        Result := BufferDir.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferDir.Common.NextEntryOffset);
      end;


    FileFullDirectoryInformation:
      begin
        Entry.OptionalFields := [fcEaSize];
        Entry.Common := BufferFull.Common;
        Entry.EaSize := BufferFull.EaSize;

        SetString(Entry.FileName, BufferFull.FileName,
          BufferFull.Common.FileNameLength div SizeOf(WideChar));

        Result := BufferFull.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferFull.Common.NextEntryOffset);
      end;

    FileBothDirectoryInformation:
      begin
        Entry.OptionalFields := [fcEaSize, fcShortName];
        Entry.Common := BufferBoth.Common;
        Entry.EaSize := BufferBoth.EaSize;

        SetString(Entry.FileName, BufferBoth.FileName,
          BufferBoth.Common.FileNameLength div SizeOf(WideChar));

        SetString(Entry.ShortName, BufferBoth.ShortName,
          BufferBoth.ShortNameLength div SizeOf(WideChar));

        Result := BufferBoth.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferBoth.Common.NextEntryOffset);
      end;

    FileIdBothDirectoryInformation:
      begin
        Entry.OptionalFields := [fcEaSize, fcShortName, fcFileId];
        Entry.Common := BufferIdBoth.Common;
        Entry.EaSize := BufferIdBoth.EaSize;
        Entry.FileId := BufferIdBoth.FileId;

        SetString(Entry.FileName, BufferIdBoth.FileName,
          BufferIdBoth.Common.FileNameLength div SizeOf(WideChar));

        SetString(Entry.ShortName, BufferIdBoth.ShortName,
          BufferIdBoth.ShortNameLength div SizeOf(WideChar));

        Result := BufferIdBoth.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdBoth.Common.NextEntryOffset);
      end;

    FileIdFullDirectoryInformation:
      begin
        Entry.OptionalFields := [fcEaSize, fcFileId];
        Entry.Common := BufferIdFull.Common;
        Entry.EaSize := BufferIdFull.EaSize;
        Entry.FileId := BufferIdFull.FileId;

        SetString(Entry.FileName, BufferIdFull.FileName,
          BufferIdFull.Common.FileNameLength div SizeOf(WideChar));

        Result := BufferIdFull.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdFull.Common.NextEntryOffset);
      end;


    FileIdGlobalTxDirectoryInformation:
      begin
        Entry.OptionalFields := [fcFileId, fcTransactionInfo];
        Entry.Common := BufferIdGlobalTx.Common;
        Entry.FileId := BufferIdGlobalTx.FileId;
        Entry.LockingTransactionId := BufferIdGlobalTx.LockingTransactionId;
        Entry.TxInfoFlags := BufferIdGlobalTx.TxInfoFlags;

        SetString(Entry.FileName, BufferIdGlobalTx.FileName,
          BufferIdGlobalTx.Common.FileNameLength div SizeOf(WideChar));

        Result := BufferIdGlobalTx.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdGlobalTx.Common.NextEntryOffset);
      end;

    FileIdExtdDirectoryInformation:
      begin
        Entry.OptionalFields := [fcEaSize, fcFileId, fcFileId128, fcReparseTag];
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

        Result := BufferIdExtd.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdExtd.Common.NextEntryOffset);
      end;

    FileIdExtdBothDirectoryInformation:
      begin
        Entry.OptionalFields := [fcEaSize, fcFileId, fcFileId128, fcReparseTag,
          fcShortName];
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

        Result := BufferIdExtdBoth.Common.NextEntryOffset <> 0;
        Inc(PByte(Buffer), BufferIdExtdBoth.Common.NextEntryOffset);
      end;
  else
    Result := False;
  end;
end;

function NtxIterateFolder;
const
  BUFFER_SIZE = $100;
var
  Isb: IMemory<PIoStatusBlock>;
  xMemory: IMemory;
  Buffer: Pointer;
begin
  // Check for supported info classes
  case InfoClass of
    FileDirectoryInformation, FileFullDirectoryInformation,
    FileBothDirectoryInformation, FileIdBothDirectoryInformation,
    FileIdFullDirectoryInformation, FileIdGlobalTxDirectoryInformation,
    FileIdExtdDirectoryInformation, FileIdExtdBothDirectoryInformation: ;
  else
    Result.Location := 'NtxEnumerateFolder';
    Result.Status := STATUS_INVALID_INFO_CLASS;
  end;

  IMemory(Isb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));

  Result.Location := 'NtQueryDirectoryFile';
  Result.LastCall.Expects<TIoDirectoryAccessMask>(FILE_LIST_DIRECTORY);
  Result.LastCall.UsesInfoClass(FileDirectoryInformation, icQuery);

  IMemory(xMemory) := Auto.AllocateDynamic(BUFFER_SIZE);
  repeat
    Result.Status := NtQueryDirectoryFile(hFolder, 0, nil, nil,
      Isb.Data, xMemory.Data, xMemory.Size, InfoClass, True,
      TNtUnicodeString.From(Pattern).RefOrNil, FirstScan);

    AwaitFileOperation(Result, hFolder, Isb);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), xMemory.Size shl 1,
    nil);

  if not Result.IsSuccess then
    Exit;

  Buffer := xMemory.Data;
  RtlxpCaptureDirectoryInfo(Buffer, InfoClass, Entry);
  FirstScan := False;
end;

function NtxEnumerateFolder;
const
  BUFFER_SIZE = $F00;
var
  Isb: IMemory<PIoStatusBlock>;
  xMemory: IMemory;
  Buffer: Pointer;
  FirstScan: Boolean;
begin
  // Check for supported modes
  case InfoClass of
    FileDirectoryInformation, FileFullDirectoryInformation,
    FileBothDirectoryInformation, FileIdBothDirectoryInformation,
    FileIdFullDirectoryInformation, FileIdGlobalTxDirectoryInformation,
    FileIdExtdDirectoryInformation, FileIdExtdBothDirectoryInformation: ;
  else
    Result.Location := 'NtxEnumerateFolder';
    Result.Status := STATUS_INVALID_INFO_CLASS;
  end;

  Files := nil;
  FirstScan := True;
  IMemory(Isb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));

  Result.Location := 'NtQueryDirectoryFile';
  Result.LastCall.Expects<TIoDirectoryAccessMask>(FILE_LIST_DIRECTORY);
  Result.LastCall.UsesInfoClass(FileDirectoryInformation, icQuery);

  repeat
    // Retrieve a portion of files
    IMemory(xMemory) := Auto.AllocateDynamic(BUFFER_SIZE);
    repeat
      Result.Status := NtQueryDirectoryFile(hFolder, 0, nil, nil,
        Isb.Data, xMemory.Data, xMemory.Size, InfoClass, False,
        TNtUnicodeString.From(Pattern).RefOrNil, FirstScan);

      AwaitFileOperation(Result, hFolder, Isb);
    until not NtxExpandBufferEx(Result, IMemory(xMemory), xMemory.Size shl 1,
      nil);

    // Nothing left to do
    if (Result.Status = STATUS_NO_MORE_FILES) or
      (Result.Status = STATUS_NO_SUCH_FILE) then
    begin
      Result.Status := STATUS_SUCCESS;
      Break;
    end
    else if not Result.IsSuccess then
      Break;

    // Collect all new files we recieved
    Buffer := xMemory.Data;
    repeat
      SetLength(Files, Succ(Length(Files)));
    until not RtlxpCaptureDirectoryInfo(Buffer, InfoClass, Files[High(Files)]);

    FirstScan := False;
  until False;
end;

function NtxTraverseFolderWorker(
  const hxFolder: IHandle;
  const AccumulatedPath: String;
  const ParametersTemplate: IFileOpenParameters;
  const Callback: TFileTraverseCallback;
  Options: TFileTraverseOptions;
  RemainingDepth: Integer
): TNtxStatus;
var
  Files: TArray<TFolderEntry>;
  hxSubFolder: IHandle;
  IsFolder, ContinuePropagation, MoreEntries: Boolean;
  i: Integer;
begin
  // Get the listing of files and sub-folders inside the folder
  Result := NtxEnumerateFolder(hxFolder.Handle, Files);

  if not Result.IsSuccess then
  begin
    // Allow skipping this folder if we cannot enumerate it
    if ftIgnoreTraverseFailures in Options then
    begin
      Result.Location := 'NtxTraverseFolderWorker';
      Result.Status := STATUS_MORE_ENTRIES;
    end;

    Exit;
  end;

  MoreEntries := False;

  for i := 0 to High(Files) do
  begin
    // Skip pseudo-directories
    if (Files[i].FileName = '.') or (Files[i].FileName = '..')  then
      Continue;

    IsFolder := BitTest(Files[i].Common.FileAttributes and
      FILE_ATTRIBUTE_DIRECTORY);

    // Allow skipping junctions and symlinks
    ContinuePropagation := not (ftSkipReparsePoints in Options) or not
      BitTest(Files[i].Common.FileAttributes and FILE_ATTRIBUTE_REPARSE_POINT);

    // Invoke the callback
    if (IsFolder and (ftInvokeOnFolders in Options)) or
      (not IsFolder and (ftInvokeOnFiles in Options)) then
    begin
      Result := Callback(Files[i], hxFolder, AccumulatedPath,
        ContinuePropagation);

      // Handle failures
      if ftIgnoreCallbackFailures in Options then
        Result.Status := STATUS_SUCCESS
      else if not Result.IsSuccess then
        Exit;
    end;

    // Traverse sub-folders
    if IsFolder and ContinuePropagation and (RemainingDepth > 0) then
    begin
      Result := NtxOpenFile(hxSubFolder, ParametersTemplate
        .UseFileName(Files[i].FileName).UseRoot(hxFolder));

      if not Result.IsSuccess then
      begin
        // Allow skipping folders we cannot access
        if ftIgnoreTraverseFailures in Options then
        begin
          MoreEntries := True;
          Result.Location := 'NtxTraverseFolderWorker';
          Result.Status := STATUS_MORE_ENTRIES;
          Continue;
        end;

        Exit;
      end;

      // Call recursively
      Result := NtxTraverseFolderWorker(hxSubFolder,
        AccumulatedPath + '\' + Files[i].FileName, ParametersTemplate, Callback,
        Options, RemainingDepth - 1);

      if Result.Status = STATUS_MORE_ENTRIES then
        MoreEntries := True
      else if not Result.IsSuccess then
        Exit;
    end;
  end;

  if Result.IsSuccess and MoreEntries then
  begin
    // We skipped some folders
    Result.Location := 'NtxTraverseFolderWorker';
    Result.Status := STATUS_MORE_ENTRIES;
  end;
end;

function NtxTraverseFolder;
var
  AccummulatedPath: String;
begin
  // Always use synnchronous I/O and at least directory listing access
  OpenParameters := FileOpenParameters(OpenParameters);
  OpenParameters := OpenParameters
    .UseOpenOptions(OpenParameters.OpenOptions or FILE_SYNCHRONOUS_IO_NONALERT
      or FILE_DIRECTORY_FILE)
    .UseAccess(OpenParameters.Access or FILE_LIST_DIRECTORY);

  // Open the root folder if not provided
  if not Assigned(hxFolder) then
  begin
    Result := NtxOpenFile(hxFolder, OpenParameters);

    if not Result.IsSuccess then
      Exit;
  end;

  // Since we want to reuse the open options, clear the file ID information
  AccummulatedPath := OpenParameters.FileName;
  OpenParameters := OpenParameters.UseFileId(0);

  Result := NtxTraverseFolderWorker(hxFolder, '', OpenParameters,
    Callback, Options, MaxDepth);
end;

end.
