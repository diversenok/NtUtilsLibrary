unit NtUtils.Files.Operations;

{
  The module provides support for various file operations using Native API.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntioapi, Ntapi.ntioapi.fsctl, DelphiApi.Reflection,
  DelphiUtils.AutoObjects, DelphiUtils.Async, NtUtils, NtUtils.Files;

type
  TFileStreamInfo = record
    [Bytes] StreamSize: Int64;
    [Bytes] StreamAllocationSize: Int64;
    StreamName: String;
  end;

  TFileHardlinkLinkInfo = record
    ParentFileID: TFileId;
    FileName: String;
  end;

{ Operations }

// Synchronously wait for a completion of an operation on an asynchronous handle
procedure AwaitFileOperation(
  var Result: TNtxStatus;
  [Access(SYNCHRONIZE)] hFile: THandle;
  const xIoStatusBlock: IMemory<PIoStatusBlock>
);

// Read from a file into a buffer
function NtxReadFile(
  [Access(FILE_READ_DATA)] hFile: THandle;
  [out] Buffer: Pointer;
  BufferSize: Cardinal;
  const Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION;
  [opt] AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Write to a file from a buffer
function NtxWriteFile(
  [Access(FILE_WRITE_DATA)] hFile: THandle;
  [in] Buffer: Pointer;
  BufferSize: Cardinal;
  const Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION;
  [opt] AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Delete a file
function NtxDeleteFile(
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Rename a file
function NtxRenameFile(
  [Access(_DELETE)] hFile: THandle;
  const NewName: String;
  Flags: TFileRenameFlags = 0;
  [opt] RootDirectory: THandle = 0;
  InfoClass: TFileInformationClass = FileRenameInformation
): TNtxStatus;

// Creare a hardlink for a file
function NtxHardlinkFile(
  [Access(0)] hFile: THandle;
  const NewName: String;
  Flags: TFileLinkFlags = 0;
  [opt] RootDirectory: THandle = 0;
  InfoClass: TFileInformationClass = FileLinkInformation
): TNtxStatus;

// Lock a range of bytes in a file
function NtxLockFile(
  [Access(FILE_READ_DATA), {or} Access(FILE_WRITE_DATA)] hFile: THandle;
  const ByteOffset: UInt64;
  const Length: UInt64;
  ExclusiveLock: Boolean = True;
  FailImmediately: Boolean = True;
  Key: Cardinal = 0
): TNtxStatus;

// Unlock a range of bytes in a file
function NtxUnlockFile(
  [Access(FILE_READ_DATA), {or} Access(FILE_WRITE_DATA)] hFile: THandle;
  const ByteOffset: UInt64;
  const Length: UInt64;
  Key: Cardinal = 0
): TNtxStatus;

// Lock a range of bytes in a file and automaticaly unlock it later
function NtxLockFileAuto(
  out Unlocker: IAutoReleasable;
  [Access(FILE_READ_DATA), {or} Access(FILE_WRITE_DATA)] const hxFile: IHandle;
  ByteOffset: UInt64;
  Length: UInt64;
  ExclusiveLock: Boolean;
  FailImmediately: Boolean = True;
  Key: Cardinal = 0
): TNtxStatus;

{ Information }

// Query variable-length information
function NtxQueryFile(
  hFile: THandle;
  InfoClass: TFileInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query basic information by file name
function NtxQueryAttributesFile(
  [Access(FILE_READ_ATTRIBUTES)] const ObjectAttributes: IObjectAttributes;
  out BasicInfo: TFileBasicInformation
): TNtxStatus;

// Query extended information by file name
function NtxQueryFullAttributesFile(
  [Access(FILE_READ_ATTRIBUTES)] const ObjectAttributes: IObjectAttributes;
  out NetworkInfo: TFileNetworkOpenInformation
): TNtxStatus;

// Set variable-length information
function NtxSetFile(
  hFile: THandle;
  InfoClass: TFileInformationClass;
  [in] Buffer: Pointer;
  BufferSize: Cardinal
): TNtxStatus;

type
  NtxFile = class abstract
    // Query fixed-size information
    class function Query<T>(
      hFile: THandle;
      InfoClass: TFileInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Query fixed-size information by name
    class function QueryByName<T>(
      const FileName: String;
      InfoClass: TFileInformationClass;
      out Buffer: T;
      [opt] const ObjectAttributes: IObjectAttributes = nil
    ): TNtxStatus; static;

    // Set fixed-size information
    class function &Set<T>(
      hFile: THandle;
      InfoClass: TFileInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

// Query a name of a file without the device name
function NtxQueryNameFile(
  [Access(0)] hFile: THandle;
  out Name: String;
  InfoClass: TFileInformationClass = FileNameInformation
): TNtxStatus;

// Modify a short (alternative) name of a file
function NtxSetShortNameFile(
  [Access(_DELETE)] hFile: THandle;
  const ShortName: String
): TNtxStatus;

{ Volume information }

// Query variable-length information about a volume of a file
function NtxQueryVolume(
  hFile: THandle;
  InfoClass: TFsInfoClass;
  out Buffer: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

type
  NtxVolume = class abstract
    // Query fixed-size information
    class function Query<T>(
      hFile: THandle;
      InfoClass: TFsInfoClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

{ Enumeration }

// Enumerate file streams
function NtxEnumerateStreamsFile(
  [Access(0)] hFile: THandle;
  out Streams: TArray<TFileStreamInfo>
): TNtxStatus;

// Enumerate hardlinks pointing to the file
function NtxEnumerateHardLinksFile(
  [Access(0)] hFile: THandle;
  out Links: TArray<TFileHardlinkLinkInfo>
): TNtxStatus;

// Enumerate processes that use this file. Requires FILE_READ_ATTRIBUTES.
function NtxEnumerateUsingProcessesFile(
  [Access(FILE_READ_ATTRIBUTES)] hFile: THandle;
  out PIDs: TArray<TProcessId>
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, NtUtils.Ldr, NtUtils.Files.Open,
  NtUtils.Synchronization;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Operations }

procedure AwaitFileOperation;
begin
  // When performing a synchronous operation on an asynchronous handle, we
  // must wait for completion ourselves.

  if Result.Status = STATUS_PENDING then
  begin
    Result := NtxWaitForSingleObject(hFile);

    // On success, extract the status. On failure, the only option we
    // have is to prolong the lifetime of the I/O status block indefinitely
    // because we never know when the system will write to its memory.

    if Result.IsSuccess then
      Result.Status := xIoStatusBlock.Data.Status
    else
      xIoStatusBlock.AutoRelease := False;
  end;
end;

function NtxReadFile;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtReadFile';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_READ_DATA);

  Result.Status := NtReadFile(hFile, 0, GetApcRoutine(AsyncCallback),
    Pointer(ApcContext), PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb),
    Buffer, BufferSize, @Offset, nil);

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
    AwaitFileOperation(Result, hFile, xIsb);
end;

function NtxWriteFile;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtWriteFile';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA);

  Result.Status := NtWriteFile(hFile, 0, GetApcRoutine(AsyncCallback),
    Pointer(ApcContext), PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb),
    Buffer, BufferSize, @Offset, nil);

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
    AwaitFileOperation(Result, hFile, xIsb);
end;

function NtxDeleteFile;
begin
  Result.Location := 'NtDeleteFile';
  Result.Status := NtDeleteFile(AttributeBuilder(ObjectAttributes)
    .UseName(Name).ToNative^);
end;

function NtxpSetRenameInfoFile(
  hFile: THandle;
  TargetName: String;
  Flags: Cardinal;
  RootDirectory: THandle;
  InfoClass: TFileInformationClass
): TNtxStatus;
var
  xMemory: IMemory<PFileRenameInformationEx>; // aka PFileLinkInformationEx
begin
  IMemory(xMemory) := Auto.AllocateDynamic(SizeOf(TFileRenameInformation) +
    StringSizeNoZero(TargetName));

  // Prepare a variable-length buffer for rename or hardlink operations
  xMemory.Data.Flags := Flags;
  xMemory.Data.RootDirectory := RootDirectory;
  xMemory.Data.FileNameLength := StringSizeNoZero(TargetName);
  MarshalString(TargetName, @xMemory.Data.FileName);

  Result := NtxSetFile(hFile, InfoClass, xMemory.Data, xMemory.Size);
end;

function NtxRenameFile;
begin
  // Note: if you get sharing violation when using RootDirectory, open it with
  // FILE_TRAVERSE | FILE_READ_ATTRIBUTES access.

  Result := NtxpSetRenameInfoFile(hFile, NewName, Flags,
    RootDirectory, InfoClass);
  Result.LastCall.Expects<TFileAccessMask>(_DELETE);
end;

function NtxHardlinkFile;
begin
  Result := NtxpSetRenameInfoFile(hFile, NewName, Flags,
    RootDirectory, InfoClass);
end;

function NtxLockFile;
var
  xIsb: IMemory<PIoStatusBlock>;
begin
  IMemory(xIsb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));

  Result.Location := 'NtLockFile';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_READ_DATA);
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA);

  Result.Status := NtLockFile(hFile, 0, nil, nil, xIsb.Data, ByteOffset, Length,
    Key, FailImmediately, ExclusiveLock);

  AwaitFileOperation(Result, hFile, xIsb);
end;

function NtxUnlockFile;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtUnlockFile';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_READ_DATA);
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA);
  Result.Status := NtUnlockFile(hFile, Isb, ByteOffset, Length, Key);
end;

function NtxLockFileAuto;
begin
  Result := NtxLockFile(hxFile.Handle, ByteOffset, Length, ExclusiveLock,
    FailImmediately, Key);

  if Result.IsSuccess then
    Unlocker := Auto.Delay(procedure
      begin
        NtxUnlockFile(hxFile.Handle, ByteOffset, Length, Key);
      end
    );
end;

{ Information }

function GrowFileDefault(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := Memory.Size shl 1 + 256; // x2 + 256 B
end;

function NtxQueryFile;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedFileQueryAccess(InfoClass));

  // NtQueryInformationFile does not return the required size. We either need
  // to know how to grow the buffer, or we should guess.
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowFileDefault;

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Isb.Information := 0;

    Result.Status := NtQueryInformationFile(hFile, Isb, xMemory.Data,
      xMemory.Size, InfoClass);

  until not NtxExpandBufferEx(Result, xMemory, Isb.Information, GrowthMethod);
end;

function NtxQueryAttributesFile;
begin
  Result.Location := 'NtQueryAttributesFile';
  Result.LastCall.Expects<TFileAccessMask>(FILE_READ_ATTRIBUTES);
  Result.Status := NtQueryAttributesFile(ObjectAttributes.ToNative^, BasicInfo);
end;

function NtxQueryFullAttributesFile;
begin
  Result.Location := 'NtQueryFullAttributesFile';
  Result.LastCall.Expects<TFileAccessMask>(FILE_READ_ATTRIBUTES);
  Result.Status := NtQueryFullAttributesFile(ObjectAttributes.ToNative^,
    NetworkInfo);
end;

function NtxSetFile;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtSetInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(ExpectedFileSetAccess(InfoClass));

  Result.Status := NtSetInformationFile(hFile, Isb, Buffer,
    BufferSize, InfoClass);
end;

class function NtxFile.Query<T>;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedFileQueryAccess(InfoClass));

  Result.Status := NtQueryInformationFile(hFile, Isb, @Buffer,
    SizeOf(Buffer), InfoClass);
end;

class function NtxFile.QueryByName<T>;
var
  Isb: TIoStatusBlock;
  hxFile: IHandle;
begin
  if LdrxCheckDelayedImport(delayed_ntdll,
    delayed_NtQueryInformationByName).IsSuccess then
  begin
    Result.Location := 'NtQueryInformationByName';
    Result.LastCall.UsesInfoClass(InfoClass, icQuery);
    Result.LastCall.Expects<TFileAccessMask>(FILE_READ_ATTRIBUTES);
    Result.Status := NtQueryInformationByName(
      AttributeBuilder(ObjectAttributes).UseName(FileName).ToNative^,
      Isb,
      @Buffer,
      SizeOf(Buffer),
      InfoClass
    );
  end
  else
  begin
    // Fallback to opening the file manually on older versions
    Result := NtxOpenFile(hxFile, FileParameters
      .UseFileName(FileName)
      .UseRoot(AttributeBuilder(ObjectAttributes).Root)
      .UseAccess(FILE_READ_ATTRIBUTES)
      .UseOptions(FILE_OPEN_NO_RECALL)
      .UseSyncMode(fsAsynchronous)
    );

    if Result.IsSuccess then
      Result := Query(hxFile.Handle, InfoClass, Buffer);
  end;
end;

class function NtxFile.&Set<T>;
begin
  Result := NtxSetFile(hFile, InfoClass, @Buffer, SizeOf(Buffer));
end;

function GrowFileName(
  const Memory: IMemory;
  BufferSize: NativeUInt
): NativeUInt;
begin
  Result := SizeOf(Cardinal) + PFileNameInformation(Memory.Data).FileNameLength;
end;

function NtxQueryNameFile;
var
  xMemory: IMemory<PFileNameInformation>;
begin
  Result := NtxQueryFile(hFile, InfoClass, IMemory(xMemory),
    SizeOf(TFileNameInformation), GrowFileName);

  if Result.IsSuccess then
    SetString(Name, xMemory.Data.FileName, xMemory.Data.FileNameLength div
      SizeOf(WideChar));
end;

function NtxSetShortNameFile;
var
  Buffer: IMemory<PFileNameInformation>;
begin
  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TFileNameInformation) +
    StringSizeNoZero(ShortName));

  Buffer.Data.FileNameLength := StringSizeNoZero(ShortName);
  MarshalString(ShortName, @Buffer.Data.FileName);

  Result := NtxSetFile(hFile, FileShortNameInformation, Buffer.Data,
    Buffer.Size);
end;

{ Volume information }

function NtxQueryVolume;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtQueryVolumeInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedFsQueryAccess(InfoClass));

  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowFileDefault;

  Buffer := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Isb.Information := 0;

    Result.Status := NtQueryVolumeInformationFile(hFile, Isb, Buffer.Data,
      Buffer.Size, InfoClass);

  until not NtxExpandBufferEx(Result, Buffer, Isb.Information, GrowthMethod);
end;

class function NtxVolume.Query<T>;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtQueryVolumeInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedFsQueryAccess(InfoClass));

  Result.Status := NtQueryVolumeInformationFile(hFile, Isb, @Buffer,
    SizeOf(Buffer), InfoClass);
end;

{ Enumeration }

function NtxEnumerateStreamsFile;
var
  xMemory: IMemory;
  pStream: PFileStreamInformation;
begin
  Result := NtxQueryFile(hFile, FileStreamInformation, xMemory,
    SizeOf(TFileStreamInformation));

  if not Result.IsSuccess then
    Exit;

  SetLength(Streams, 0);
  pStream := xMemory.Data;

  repeat
    SetLength(Streams, Length(Streams) + 1);
    Streams[High(Streams)].StreamSize := pStream.StreamSize;
    Streams[High(Streams)].StreamAllocationSize := pStream.StreamAllocationSize;
    SetString(Streams[High(Streams)].StreamName, pStream.StreamName,
      pStream.StreamNameLength div SizeOf(WideChar));

    if pStream.NextEntryOffset <> 0 then
      pStream := Pointer(UIntPtr(pStream) + pStream.NextEntryOffset)
    else
      Break;

  until False;
end;

function GrowFileLinks(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := PFileLinksInformation(Memory.Data).BytesNeeded;
end;

function NtxEnumerateHardLinksFile;
var
  xMemory: IMemory<PFileLinksInformation>;
  pLink: PFileLinkEntryInformation;
  i: Integer;
begin
  Result := NtxQueryFile(hFile, FileHardLinkInformation, IMemory(xMemory),
    SizeOf(TFileLinksInformation), GrowFileLinks);

  if not Result.IsSuccess then
    Exit;

  SetLength(Links, xMemory.Data.EntriesReturned);

  pLink := Pointer(@xMemory.Data.Entry);
  i := 0;

  repeat
    if i > High(Links) then
      Break;

    // Note: we have only the filename and the ID of the parent directory

    Links[i].ParentFileId := pLink.ParentFileId;
    SetString(Links[i].FileName, pLink.FileName, pLink.FileNameLength);

    if pLink.NextEntryOffset <> 0 then
      pLink := Pointer(UIntPtr(pLink) + pLink.NextEntryOffset)
    else
      Break;

    Inc(i);
  until False;
end;

function NtxEnumerateUsingProcessesFile;
var
  xMemory: IMemory<PFileProcessIdsUsingFileInformation>;
  i: Integer;
begin
  Result := NtxQueryFile(hFile, FileProcessIdsUsingFileInformation,
    IMemory(xMemory), SizeOf(TFileProcessIdsUsingFileInformation));
  Result.LastCall.Expects<TFileAccessMask>(FILE_READ_ATTRIBUTES);

  if not Result.IsSuccess then
    Exit;

  SetLength(PIDs, xMemory.Data.NumberOfProcessIdsInList);

  for i := 0 to High(PIDs) do
    PIDs[i] := xMemory.Data.ProcessIdList{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

end.
