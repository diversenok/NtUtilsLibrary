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

  TNtxEaIterationMode = (
    // Iterate using the built-in handle state. Fails the query with
    // STATUS_EA_CORRUPT_ERROR if an external modification occurs.
    eaiViaRestartScan,

    // Iterate using indexes. External modifications might cause skipping EAs.
    eaiByIndex
  );

{ Operations }

// Synchronously wait for a completion of an operation on an asynchronous handle
procedure AwaitFileOperation(
  var Result: TNtxStatus;
  [Access(SYNCHRONIZE)] const hxFile: IHandle;
  const xIoStatusBlock: IMemory<PIoStatusBlock>
);

// Read from a file into a buffer
function NtxReadFile(
  [Access(FILE_READ_DATA)] const hxFile: IHandle;
  [out] Buffer: Pointer;
  BufferSize: Cardinal;
  const Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION;
  [opt] AsyncCallback: TAnonymousApcCallback = nil;
  [out, opt] BytesRead: PNativeUInt = nil
): TNtxStatus;

// Write to a file from a buffer
function NtxWriteFile(
  [Access(FILE_WRITE_DATA)] const hxFile: IHandle;
  [in] Buffer: Pointer;
  BufferSize: Cardinal;
  const Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION;
  [opt] AsyncCallback: TAnonymousApcCallback = nil;
  [out, opt] BytesWritten: PNativeUInt = nil
): TNtxStatus;

// Delete a file
function NtxDeleteFile(
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Rename a file
function NtxRenameFile(
  [Access(_DELETE)] const hxFile: IHandle;
  const NewName: String;
  Flags: TFileRenameFlags = 0;
  [opt] const RootDirectory: IHandle = nil;
  InfoClass: TFileInformationClass = FileRenameInformation
): TNtxStatus;

// Create a hardlink for a file
function NtxHardlinkFile(
  [Access(0)] const hxFile: IHandle;
  const NewName: String;
  Flags: TFileLinkFlags = 0;
  [opt] const RootDirectory: IHandle = nil;
  InfoClass: TFileInformationClass = FileLinkInformation
): TNtxStatus;

// Lock a range of bytes in a file
function NtxLockFile(
  [Access(FILE_READ_DATA), {or} Access(FILE_WRITE_DATA)] const hxFile: IHandle;
  const ByteOffset: UInt64;
  const Length: UInt64;
  ExclusiveLock: Boolean = True;
  FailImmediately: Boolean = True;
  Key: Cardinal = 0
): TNtxStatus;

// Unlock a range of bytes in a file
function NtxUnlockFile(
  [Access(FILE_READ_DATA), {or} Access(FILE_WRITE_DATA)] const hxFile: IHandle;
  const ByteOffset: UInt64;
  const Length: UInt64;
  Key: Cardinal = 0
): TNtxStatus;

// Lock a range of bytes in a file and automatically unlock it later
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
  const hxFile: IHandle;
  InfoClass: TFileInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query basic information by file name
function NtxQueryAttributesFile(
  out BasicInfo: TFileBasicInformation;
  [Access(FILE_READ_ATTRIBUTES)] const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Query extended information by file name
function NtxQueryFullAttributesFile(
  out NetworkInfo: TFileNetworkOpenInformation;
  [Access(FILE_READ_ATTRIBUTES)] const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Set variable-length information
function NtxSetFile(
  const hxFile: IHandle;
  InfoClass: TFileInformationClass;
  [in] Buffer: Pointer;
  BufferSize: Cardinal
): TNtxStatus;

type
  NtxFile = class abstract
    // Query fixed-size information
    class function Query<T>(
      const hxFile: IHandle;
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
      const hxFile: IHandle;
      InfoClass: TFileInformationClass;
      const Buffer: T
    ): TNtxStatus; static;

    // Read a fixed-size buffer
    class function Read<T>(
      const hxFile: IHandle;
      out Buffer: T;
      const Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION
    ): TNtxStatus; static;

    // Write a fixed-size buffer
    class function Write<T>(
      const hxFile: IHandle;
      const Buffer: T;
      const Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION
    ): TNtxStatus; static;
  end;

// Query a name of a file without the device name
function NtxQueryNameFile(
  [Access(0)] const hxFile: IHandle;
  out Name: String;
  InfoClass: TFileInformationClass = FileNameInformation
): TNtxStatus;

// Modify a short (alternative) name of a file
function NtxSetShortNameFile(
  [Access(_DELETE)] const hxFile: IHandle;
  const ShortName: String
): TNtxStatus;

{ Volume information }

// Query variable-length information about a volume of a file
function NtxQueryVolume(
  const hxFile: IHandle;
  InfoClass: TFsInfoClass;
  out Buffer: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

type
  NtxVolume = class abstract
    // Query fixed-size information
    class function Query<T>(
      const hxFile: IHandle;
      InfoClass: TFsInfoClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

{ Enumeration }

// Enumerate file streams
function NtxEnumerateStreamsFile(
  [Access(0)] const hxFile: IHandle;
  out Streams: TArray<TFileStreamInfo>
): TNtxStatus;

// Enumerate hardlinks pointing to the file
function NtxEnumerateHardLinksFile(
  [Access(0)] const hxFile: IHandle;
  out Links: TArray<TFileHardlinkLinkInfo>
): TNtxStatus;

// Enumerate processes that use this file. Requires FILE_READ_ATTRIBUTES.
function NtxEnumerateUsingProcessesFile(
  [Access(FILE_READ_ATTRIBUTES)] const hxFile: IHandle;
  out PIDs: TArray<TProcessId>
): TNtxStatus;

{ Extended Attributes }

// Query a single extended attribute by name
function NtxQueryEaFile(
  [Access(FILE_READ_EA)] const hxFile: IHandle;
  const Name: AnsiString;
  out EA: TNtxExtendedAttribute
): TNtxStatus;

// Query multiple extended attributes by name
function NtxQueryEAsFile(
  [Access(FILE_READ_EA)] const hxFile: IHandle;
  const Names: TArray<AnsiString>;
  out EAs: TArray<TNtxExtendedAttribute>
): TNtxStatus;

// Enumerate all extended attributes on a file
function NtxEnumerateEAsFile(
  [Access(FILE_READ_EA)] const hxFile: IHandle;
  out EAs: TArray<TNtxExtendedAttribute>
): TNtxStatus;

// Make a for-in iterator for enumerating extended attributes on a file.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function NtxIterateEaFile(
  [out, opt] Status: PNtxStatus;
  [Access(FILE_READ_EA)] const hxFile: IHandle;
  IterationMode: TNtxEaIterationMode = eaiByIndex
): IEnumerable<TNtxExtendedAttribute>;

// Set/delete multiple extended attributes on a file
// Note: use a nil value to delete an attribute
function NtxSetEAsFile(
  [Access(FILE_WRITE_EA)] const hxFile: IHandle;
  const EAs: TArray<TNtxExtendedAttribute>;
  [opt] AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Set a single extended attributes on a file
function NtxSetEAFile(
  [Access(FILE_WRITE_EA)] const hxFile: IHandle;
  const Name: AnsiString;
  const Value: TMemory;
  Flags: TFileEaFlags = 0;
  [opt] AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Delete a single extended attributes on a file
function NtxDeleteEAFile(
  [Access(FILE_WRITE_EA)] const hxFile: IHandle;
  const Name: AnsiString;
  [opt] AsyncCallback: TAnonymousApcCallback = nil
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
    Result := NtxWaitForSingleObject(hxFile);

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

  Result.Status := NtReadFile(HandleOrDefault(hxFile), 0,
    GetApcRoutine(AsyncCallback), Pointer(ApcContext),
    PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb), Buffer, BufferSize,
    @Offset, nil);

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
  begin
    AwaitFileOperation(Result, hxFile, xIsb);

    if Assigned(BytesRead) then
      BytesRead^ := xIsb.Data.Information;
  end;
end;

function NtxWriteFile;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtWriteFile';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA);

  Result.Status := NtWriteFile(HandleOrDefault(hxFile), 0,
    GetApcRoutine(AsyncCallback), Pointer(ApcContext),
    PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb), Buffer, BufferSize,
    @Offset, nil);

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
  begin
    AwaitFileOperation(Result, hxFile, xIsb);

    if Assigned(BytesWritten) then
      BytesWritten^ := xIsb.Data.Information;
  end;
end;

function NtxDeleteFile;
var
  ObjAttr: PObjectAttributes;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtDeleteFile';
  Result.Status := NtDeleteFile(ObjAttr^);
end;

function NtxpSetRenameInfoFile(
  const hxFile: IHandle;
  TargetName: String;
  Flags: Cardinal;
  [opt] const RootDirectory: IHandle;
  InfoClass: TFileInformationClass
): TNtxStatus;
var
  xMemory: IMemory<PFileRenameInformationEx>; // aka PFileLinkInformationEx
begin
  IMemory(xMemory) := Auto.AllocateDynamic(SizeOf(TFileRenameInformation) +
    StringSizeNoZero(TargetName));

  // Prepare a variable-length buffer for rename or hardlink operations
  xMemory.Data.Flags := Flags;
  xMemory.Data.RootDirectory := HandleOrDefault(RootDirectory);
  xMemory.Data.FileNameLength := StringSizeNoZero(TargetName);
  MarshalString(TargetName, @xMemory.Data.FileName);

  Result := NtxSetFile(hxFile, InfoClass, xMemory.Data, xMemory.Size);
end;

function NtxRenameFile;
begin
  // Note: if you get sharing violation when using RootDirectory, open it with
  // FILE_TRAVERSE | FILE_READ_ATTRIBUTES access.

  Result := NtxpSetRenameInfoFile(hxFile, NewName, Flags, RootDirectory,
    InfoClass);
  Result.LastCall.Expects<TFileAccessMask>(_DELETE);
end;

function NtxHardlinkFile;
begin
  Result := NtxpSetRenameInfoFile(hxFile, NewName, Flags,
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

  Result.Status := NtLockFile(HandleOrDefault(hxFile), 0, nil, nil, xIsb.Data,
    ByteOffset, Length, Key, FailImmediately, ExclusiveLock);

  AwaitFileOperation(Result, hxFile, xIsb);
end;

function NtxUnlockFile;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtUnlockFile';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_READ_DATA);
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA);
  Result.Status := NtUnlockFile(HandleOrDefault(hxFile), Isb, ByteOffset,
    Length, Key);
end;

function NtxLockFileAuto;
begin
  Result := NtxLockFile(hxFile, ByteOffset, Length, ExclusiveLock,
    FailImmediately, Key);

  if Result.IsSuccess then
    Unlocker := Auto.Delay(procedure
      begin
        NtxUnlockFile(hxFile, ByteOffset, Length, Key);
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

    Result.Status := NtQueryInformationFile(HandleOrDefault(hxFile), Isb,
      xMemory.Data, xMemory.Size, InfoClass);

  until not NtxExpandBufferEx(Result, xMemory, Isb.Information, GrowthMethod);
end;

function NtxQueryAttributesFile;
var
  ObjAttr: PObjectAttributes;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryAttributesFile';
  Result.LastCall.Expects<TFileAccessMask>(FILE_READ_ATTRIBUTES);
  Result.Status := NtQueryAttributesFile(ObjAttr^, BasicInfo);
end;

function NtxQueryFullAttributesFile;
var
  ObjAttr: PObjectAttributes;
begin
  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryFullAttributesFile';
  Result.LastCall.Expects<TFileAccessMask>(FILE_READ_ATTRIBUTES);
  Result.Status := NtQueryFullAttributesFile(ObjAttr^, NetworkInfo);
end;

function NtxSetFile;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtSetInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.LastCall.Expects(ExpectedFileSetAccess(InfoClass));

  Result.Status := NtSetInformationFile(HandleOrDefault(hxFile), Isb, Buffer,
    BufferSize, InfoClass);
end;

class function NtxFile.Query<T>;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedFileQueryAccess(InfoClass));

  Result.Status := NtQueryInformationFile(HandleOrDefault(hxFile), Isb, @Buffer,
    SizeOf(Buffer), InfoClass);
end;

class function NtxFile.QueryByName<T>;
var
  Isb: TIoStatusBlock;
  ObjAttr: PObjectAttributes;
  hxFile: IHandle;
begin
  if LdrxCheckDelayedImport(delayed_NtQueryInformationByName).IsSuccess then
  begin
    Result := AttributeBuilder(ObjectAttributes).UseName(FileName)
      .Build(ObjAttr);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'NtQueryInformationByName';
    Result.LastCall.UsesInfoClass(InfoClass, icQuery);
    Result.LastCall.Expects<TFileAccessMask>(FILE_READ_ATTRIBUTES);
    Result.Status := NtQueryInformationByName(ObjAttr^, Isb, @Buffer,
      SizeOf(Buffer), InfoClass);
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
      Result := Query(hxFile, InfoClass, Buffer);
  end;
end;

class function NtxFile.Read<T>;
begin
  Result := NtxReadFile(hxFile, @Buffer, SizeOf(Buffer), Offset);
end;

class function NtxFile.&Set<T>;
begin
  Result := NtxSetFile(hxFile, InfoClass, @Buffer, SizeOf(Buffer));
end;

class function NtxFile.Write<T>;
begin
  Result := NtxWriteFile(hxFile, @Buffer, SizeOf(Buffer), Offset);
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
  Result := NtxQueryFile(hxFile, InfoClass, IMemory(xMemory),
    SizeOf(TFileNameInformation) + SizeOf(WideChar) * MAX_PATH, GrowFileName);

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

  Result := NtxSetFile(hxFile, FileShortNameInformation, Buffer.Data,
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

    Result.Status := NtQueryVolumeInformationFile(HandleOrDefault(hxFile), Isb,
      Buffer.Data, Buffer.Size, InfoClass);

  until not NtxExpandBufferEx(Result, Buffer, Isb.Information, GrowthMethod);
end;

class function NtxVolume.Query<T>;
var
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtQueryVolumeInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects(ExpectedFsQueryAccess(InfoClass));

  Result.Status := NtQueryVolumeInformationFile(HandleOrDefault(hxFile), Isb,
    @Buffer, SizeOf(Buffer), InfoClass);
end;

{ Enumeration }

function NtxEnumerateStreamsFile;
var
  xMemory: IMemory;
  pStream: PFileStreamInformation;
begin
  Result := NtxQueryFile(hxFile, FileStreamInformation, xMemory,
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
  Result := NtxQueryFile(hxFile, FileHardLinkInformation, IMemory(xMemory),
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
  Result := NtxQueryFile(hxFile, FileProcessIdsUsingFileInformation,
    IMemory(xMemory), SizeOf(TFileProcessIdsUsingFileInformation));
  Result.LastCall.Expects<TFileAccessMask>(FILE_READ_ATTRIBUTES);

  if not Result.IsSuccess then
    Exit;

  SetLength(PIDs, xMemory.Data.NumberOfProcessIdsInList);

  for i := 0 to High(PIDs) do
    PIDs[i] := xMemory.Data.ProcessIdList{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

{ Extended Attributes }

function NtxQueryEaFileInternal(
  [Access(FILE_READ_EA)] const hxFile: IHandle;
  out EAs: TArray<TNtxExtendedAttribute>;
  ReturnSingleEntry: Boolean;
  [opt] const Names: TArray<AnsiString>;
  [in, opt] Index: PCardinal;
  RestartScan: Boolean
): TNtxStatus;
const
  INITIAL_SIZE = 80;
var
  Buffer: IMemory<PFileFullEaInformation>;
  xIsb: IMemory<PIoStatusBlock>;
  EaList: IMemory<PFileGetEaInformation>;
  EaListCursor: PFileGetEaInformation;
  EaListSize: Cardinal;
  i: Integer;
begin
  EaListSize := 0;
  EaListCursor := nil;

  // Collect input names
  if Length(Names) > 0 then
  begin
    for i := 0 to High(Names) do
      Inc(EaListSize, AlignUp(SizeOf(TFileGetEaInformation) +
        Length(Names[i]), 4));

    IMemory(EaList) := Auto.AllocateDynamic(EaListSize);
    EaListCursor := EaList.Data;

    for i := 0 to High(Names) do
    begin
      EaListCursor.EaNameLength := Length(Names[i]);
      Move(PAnsiChar(Names[i])^, EaListCursor.EaName, EaListCursor.EaNameLength);

      if i < High(Names) then
      begin
        // Record offsets and advance to the next entry
        EaListCursor.NextEntryOffset := AlignUp(SizeOf(TFileGetEaInformation) +
          EaListCursor.EaNameLength, 4);
        EaListCursor := Pointer(PByte(EaListCursor) +
          EaListCursor.NextEntryOffset);
      end;
    end;

    EaListCursor := EaList.Data;
  end;

  IMemory(xIsb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));
  IMemory(Buffer) := Auto.AllocateDynamic(INITIAL_SIZE + EaListSize);

  repeat
    // Query the information
    Result.Location := 'NtQueryEaFile';
    Result.Status := NtQueryEaFile(HandleOrDefault(hxFile), xIsb.Data,
      Buffer.Data, Buffer.Size, ReturnSingleEntry, EaListCursor, EaListSize,
      Index, RestartScan);

    AwaitFileOperation(Result, hxFile, xIsb);
  until not NtxExpandBufferEx(Result, IMemory(Buffer), Buffer.Size shl 1, nil);

  if not Result.IsSuccess then
    Exit;

  // Collect attributes
  EAs := RtlxCaptureFullEaInformation(Buffer.Data);
end;

function NtxQueryEaFile;
var
  EAs: TArray<TNtxExtendedAttribute>;
begin
  Result := NtxQueryEaFileInternal(hxFile, EAs, True, [Name], nil, False);

  if Result.IsSuccess then
    EA := EAs[0];
end;

function NtxQueryEAsFile;
begin
  Result := NtxQueryEaFileInternal(hxFile, EAs, False, Names, nil, False);
end;

function NtxEnumerateEAsFile;
begin
  Result := NtxQueryEaFileInternal(hxFile, EAs, False, nil, nil, True);
end;

function NtxIterateEaFile;
var
  RestartScan: Boolean;
  Index: Cardinal;
begin
  RestartScan := (IterationMode = eaiViaRestartScan);
  Index := 1;

  Result := NtxAuto.Iterate<TNtxExtendedAttribute>(Status,
    function (out Entry: TNtxExtendedAttribute): TNtxStatus
    var
      EAs: TArray<TNtxExtendedAttribute>;
      pIndex: PCardinal;
    begin
      // Select how we want to iterate EAs
      if IterationMode = eaiByIndex then
        pIndex := @Index
      else
        pIndex := nil;

      // Retrieve one attribute
      Result := NtxQueryEaFileInternal(hxFile, EAs, True, nil, pIndex,
        RestartScan);

      if not Result.IsSuccess then
        Exit;

      // Save and advance
      Entry := EAs[0];
      RestartScan := False;
      Inc(Index);
    end
  );
end;

function NtxSetEAsFile;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
  EaBuffer: IMemory<PFileFullEaInformation>;
begin
  EaBuffer := RtlxAllocateEAs(EAs);

  Result.Location := 'NtSetEaFile';
  Result.LastCall.Expects<TFileAccessMask>(FILE_WRITE_EA);
  Result.Status := NtSetEaFile(HandleOrDefault(hxFile),
    PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb),
    Auto.RefOrNil(IMemory(EaBuffer)), Auto.SizeOrZero(IMemory(EaBuffer)));

  if not Result.IsSuccess then
    Exit;

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
    AwaitFileOperation(Result, hxFile, xIsb);
end;

function NtxSetEAFile;
begin
  Result := NtxSetEAsFile(hxFile, [TNtxExtendedAttribute.From(Name,
    Auto.AddressRange(Value.Address, Value.Size), Flags)], AsyncCallback);
end;

function NtxDeleteEAFile;
begin
  Result := NtxSetEAsFile(hxFile, [TNtxExtendedAttribute.From(Name, nil)],
    AsyncCallback);
end;

end.
