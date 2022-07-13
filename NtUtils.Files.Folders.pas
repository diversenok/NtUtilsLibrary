unit NtUtils.Files.Folders;

{
  The module allows enumerating and traversing folders on a filesystem.
}

interface

uses
  Ntapi.ntioapi, Ntapi.ntseapi, NtUtils, NtUtils.Files, DelphiApi.Reflection;

type
  TFolderContentInfo = record
    [Aggregate] Times: TFileTimestamps;
    [Bytes] EndOfFile: UInt64;
    [Bytes] AllocationSize: UInt64;
    FileAttributes: TFileAttributes;
    Name: String;
  end;

  // Note: ContinuePropagation applies only to folders and allows callers can
  // explicitly cancel traversing of specific locations, as well as enable it
  // back when skipping reparse points.
  TFileTraverseCallback = reference to function(
    const FileInfo: TFolderContentInfo;
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

// Enumerate content of a folder
function NtxEnumerateFolder(
  [Access(FILE_LIST_DIRECTORY)] hFolder: THandle;
  out Files: TArray<TFolderContentInfo>;
  [opt] const Pattern: String = ''
): TNtxStatus;

// Recursively traverse a folder and its sub-folders
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
  Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Files.Open, NtUtils.Synchronization;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxEnumerateFolder;
const
  BUFFER_SIZE = $F00;
var
  IoStatusBlock: TIoStatusBlock;
  xMemory: IMemory;
  Buffer: PFileDirectoryInformation;
  FirstScan: Boolean;
begin
  FirstScan := True;

  Result.Location := 'NtQueryDirectoryFile';
  Result.LastCall.Expects<TIoDirectoryAccessMask>(FILE_LIST_DIRECTORY);
  Result.LastCall.UsesInfoClass(FileDirectoryInformation, icQuery);

  repeat
    // Retrieve a portion of files
    IMemory(xMemory) := Auto.AllocateDynamic(BUFFER_SIZE);
    repeat
      Result.Status := NtQueryDirectoryFile(hFolder, 0, nil, nil,
        @IoStatusBlock, xMemory.Data, xMemory.Size, FileDirectoryInformation,
        False, TNtUnicodeString.From(Pattern).RefOrNil, FirstScan);

      // Since IoStatusBlock is on our stack, we must wait for completion
      if Result.Status = STATUS_PENDING then
      begin
        Result := NtxWaitForSingleObject(hFolder);

        if Result.IsSuccess then
          Result.Status := IoStatusBlock.Status;
      end;
    until not NtxExpandBufferEx(Result, IMemory(xMemory), xMemory.Size shl 1, nil);

    // Nothing left to do
    if Result.Status = STATUS_NO_MORE_FILES then
    begin
      Result.Status := STATUS_SUCCESS;
      Break;
    end
    else if not Result.IsSuccess then
      Break;

    // Collect all the files we recieved
    Buffer := xMemory.Data;
    repeat
      SetLength(Files, Succ(Length(Files)));

      with Files[High(Files)] do
      begin
        Times := Buffer.Times;
        EndOfFile := Buffer.EndOfFile;
        AllocationSize := Buffer.AllocationSize;
        FileAttributes := Buffer.FileAttributes;
        SetString(Name, Buffer.FileName, Buffer.FileNameLength div
          SizeOf(WideChar));
      end;

      if Buffer.NextEntryOffset = 0 then
        Break;

      Buffer := Pointer(UIntPtr(Buffer) + Buffer.NextEntryOffset);
    until False;

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
  Files: TArray<TFolderContentInfo>;
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
    if (Files[i].Name = '.') or (Files[i].Name = '..')  then
      Continue;

    IsFolder := BitTest(Files[i].FileAttributes and FILE_ATTRIBUTE_DIRECTORY);

    // Allow skipping junctions and symlinks
    ContinuePropagation := not (ftSkipReparsePoints in Options) or not
      BitTest(Files[i].FileAttributes and FILE_ATTRIBUTE_REPARSE_POINT);

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
        .UseFileName(Files[i].Name).UseRoot(hxFolder));

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
        AccumulatedPath + '\' + Files[i].Name, ParametersTemplate, Callback,
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
