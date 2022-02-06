unit NtUtils.Files.Operations;

{
  The module provides support for various file operations using Native API.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntioapi,DelphiApi.Reflection, DelphiUtils.AutoObjects,
  DelphiUtils.Async, NtUtils;

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
  [opt] const AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Write to a file from a buffer
function NtxWriteFile(
  [Access(FILE_WRITE_DATA)] hFile: THandle;
  [in] Buffer: Pointer;
  BufferSize: Cardinal;
  const Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION;
  [opt] const AsyncCallback: TAnonymousApcCallback = nil
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
  ReplaceIfExists: Boolean = False;
  [opt] RootDirectory: THandle = 0
): TNtxStatus;

// Creare a hardlink for a file
function NtxHardlinkFile(
  [Access(0)] hFile: THandle;
  const NewName: String;
  ReplaceIfExists: Boolean = False;
  [opt] RootDirectory: THandle = 0
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
  Ntapi.ntstatus, Ntapi.ntrtl, NtUtils.Objects, NtUtils.SysUtils,
  NtUtils.Files.Open, NtUtils.Synchronization;

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
  ReplaceIfExists: Boolean;
  RootDirectory: THandle;
  InfoClass: TFileInformationClass
): TNtxStatus;
var
  xMemory: IMemory<PFileRenameInformation>; // aka PFileLinkInformation
begin
  IMemory(xMemory) := Auto.AllocateDynamic(SizeOf(TFileRenameInformation) +
    Length(TargetName) * SizeOf(WideChar));

  // Prepare a variable-length buffer for rename or hardlink operations
  xMemory.Data.ReplaceIfExists := ReplaceIfExists;
  xMemory.Data.RootDirectory := RootDirectory;
  xMemory.Data.FileNameLength := Length(TargetName) * SizeOf(WideChar);
  Move(PWideChar(TargetName)^, xMemory.Data.FileName,
    xMemory.Data.FileNameLength);

  Result := NtxSetFile(hFile, InfoClass, xMemory.Data, xMemory.Size);
end;

function NtxRenameFile;
begin
  // Note: if you get sharing violation when using RootDirectory, open it with
  // FILE_TRAVERSE | FILE_READ_ATTRIBUTES access.

  Result := NtxpSetRenameInfoFile(hFile, NewName, ReplaceIfExists,
    RootDirectory, FileRenameInformation);
  Result.LastCall.Expects<TFileAccessMask>(_DELETE);
end;

function NtxHardlinkFile;
begin
  Result := NtxpSetRenameInfoFile(hFile, NewName, ReplaceIfExists,
    RootDirectory, FileLinkInformation);
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
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  IMemory(xIsb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));

  // NtQueryInformationFile does not return the required size. We either need
  // to know how to grow the buffer, or we should guess.
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowFileDefault;

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    xIsb.Data.Information := 0;

    Result.Status := NtQueryInformationFile(hFile, xIsb.Data, xMemory.Data,
      xMemory.Size, InfoClass);

    // Wait on async handles
    AwaitFileOperation(Result, hFile, xIsb);

  until not NtxExpandBufferEx(Result, xMemory, xIsb.Data.Information,
    GrowthMethod);
end;

function NtxSetFile;
var
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtSetInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  IMemory(xIsb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));

  Result.Status := NtSetInformationFile(hFile, xIsb.Data, Buffer,
    BufferSize, InfoClass);

  // Wait on async handles
  AwaitFileOperation(Result, hFile, xIsb);
end;

class function NtxFile.Query<T>;
var
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  IMemory(xIsb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));

  Result.Status := NtQueryInformationFile(hFile, xIsb.Data, @Buffer,
    SizeOf(Buffer), InfoClass);

  // Wait on async handles
  AwaitFileOperation(Result, hFile, xIsb);
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

  pLink := @xMemory.Data.Entry;
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

  if Result.IsSuccess then
  begin
    SetLength(PIDs, xMemory.Data.NumberOfProcessIdsInList);

    for i := 0 to High(PIDs) do
      PIDs[i] := xMemory.Data.ProcessIdList{$R-}[i]{$R+};
  end;
end;

end.
