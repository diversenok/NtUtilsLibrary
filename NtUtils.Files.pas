unit NtUtils.Files;

interface

uses
  Winapi.WinNt, Ntapi.ntioapi, Ntapi.ntdef, DelphiApi.Reflection, NtUtils,
  DelphiUtils.AutoObject, DelphiUtils.Async;

type
  TFileStreamInfo = record
    [Bytes] StreamSize: Int64;
    [Bytes] StreamAllocationSize: Int64;
    StreamName: String;
  end;

  TFileHardlinkLinkInfo = record
    ParentFileID: Int64;
    FileName: String;
  end;

{ Paths }

// Convert a Win32 path to an NT path
function RtlxDosPathToNtPath(DosPath: String; out NtPath: String): TNtxStatus;
function RtlxDosPathToNtPathVar(var Path: String): TNtxStatus;

// Get current path
function RtlxGetCurrentPath(out CurrentPath: String): TNtxStatus;
function RtlxGetCurrentPathPeb: String;

// Set a current directory
function RtlxSetCurrentPath(CurrentPath: String): TNtxStatus;

{ Open & Create }

// Create/open a file
function NtxCreateFile(out hxFile: IHandle; DesiredAccess: THandle; FileName:
  String; CreateDisposition: TFileDisposition; ShareAccess: TFileShareMode =
  FILE_SHARE_ALL; CreateOptions: TFileOpenOptions =
  FILE_SYNCHRONOUS_IO_NONALERT; ObjectAttributes: IObjectAttributes = nil;
  FileAttributes: TFileAttributes = FILE_ATTRIBUTE_NORMAL; ActionTaken:
  PFileIoStatusResult = nil): TNtxStatus;

// Open a file
function NtxOpenFile(out hxFile: IHandle; DesiredAccess: TAccessMask;
  FileName: String; ObjectAttributes: IObjectAttributes = nil; ShareAccess:
  TFileShareMode = FILE_SHARE_ALL; OpenOptions: TFileOpenOptions =
  FILE_SYNCHRONOUS_IO_NONALERT): TNtxStatus;

// Open a file by ID
function NtxOpenFileById(out hxFile: IHandle; DesiredAccess: TAccessMask;
  const FileId: Int64; Root: THandle; ShareAccess: TFileShareMode =
  FILE_SHARE_ALL; OpenOptions: TFileOpenOptions = FILE_SYNCHRONOUS_IO_NONALERT;
  HandleAttributes: TObjectAttributesFlags = 0): TNtxStatus;

{ Operations }

// Synchronously wait for a completion of an operation on an asynchronous handle
procedure AwaitFileOperation(var Result: TNtxStatus; hFile: THandle;
  xIoStatusBlock: IMemory<PIoStatusBlock>);

// Read from a file into a buffer
function NtxReadFile(hFile: THandle; Buffer: Pointer; BufferSize: Cardinal;
  Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION; AsyncCallback:
  TAnonymousApcCallback = nil): TNtxStatus;

// Write to a file from a buffer
function NtxWriteFile(hFile: THandle; Buffer: Pointer; BufferSize: Cardinal;
  Offset: UInt64 = FILE_USE_FILE_POINTER_POSITION; AsyncCallback:
  TAnonymousApcCallback = nil): TNtxStatus;

// Rename a file
function NtxRenameFile(hFile: THandle; NewName: String;
  ReplaceIfExists: Boolean = False; RootDirectory: THandle = 0): TNtxStatus;

// Creare a hardlink for a file
function NtxHardlinkFile(hFile: THandle; NewName: String;
  ReplaceIfExists: Boolean = False; RootDirectory: THandle = 0): TNtxStatus;

{ Information }

// Query variable-length information
function NtxQueryFile(hFile: THandle; InfoClass: TFileInformationClass;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil): TNtxStatus;

// Set variable-length information
function NtxSetFile(hFile: THandle; InfoClass: TFileInformationClass;
  Buffer: Pointer; BufferSize: Cardinal): TNtxStatus;

type
  NtxFile = class abstract
    // Query fixed-size information
    class function Query<T>(hFile: THandle;
      InfoClass: TFileInformationClass; out Buffer: T): TNtxStatus; static;

    // Set fixed-size information
    class function SetInfo<T>(hFile: THandle;
      InfoClass: TFileInformationClass; const Buffer: T): TNtxStatus; static;
  end;

// Query name of a file
function NtxQueryNameFile(hFile: THandle; out Name: String): TNtxStatus;

{ Enumeration }

// Enumerate file streams
function NtxEnumerateStreamsFile(hFile: THandle; out Streams:
  TArray<TFileStreamInfo>): TNtxStatus;

// Enumerate hardlinks pointing to the file
function NtxEnumerateHardLinksFile(hFile: THandle; out Links:
  TArray<TFileHardlinkLinkInfo>): TNtxStatus;

// Get full name of a hardlink target
function NtxExpandHardlinkTarget(hOriginalFile: THandle;
  const Hardlink: TFileHardlinkLinkInfo; out FullName: String): TNtxStatus;

// Enumerate processes that use this file. Requires FILE_READ_ATTRIBUTES.
function NtxEnumerateUsingProcessesFile(hFile: THandle;
  out PIDs: TArray<TProcessId>): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb, NtUtils.Objects;

{ Paths }

function RtlxDosPathToNtPath(DosPath: String; out NtPath: String): TNtxStatus;
var
  NtPathStr: TNtUnicodeString;
begin
  FillChar(NtPathStr, SizeOf(NtPathStr), 0);

  Result.Location := 'RtlDosPathNameToNtPathName_U_WithStatus';
  Result.Status := RtlDosPathNameToNtPathName_U_WithStatus(PWideChar(DosPath),
    NtPathStr, nil, nil);

  if Result.IsSuccess then
  begin
    NtPath := NtPathStr.ToString;
    RtlFreeUnicodeString(NtPathStr);
  end;
end;

function RtlxDosPathToNtPathVar(var Path: String): TNtxStatus;
var
  NtPath: String;
begin
  Result := RtlxDosPathToNtPath(Path, NtPath);

  if Result.IsSuccess then
    Path := NtPath;
end;

function RtlxGetCurrentPath(out CurrentPath: String): TNtxStatus;
var
  xMemory: IMemory<PWideChar>;
begin
  IMemory(xMemory) := TAutoMemory.Allocate(RtlGetLongestNtPathLength);

  Result.Location := 'RtlGetCurrentDirectory_U';
  Result.Status := RtlGetCurrentDirectory_U(xMemory.Size, xMemory.Data);

  if Result.IsSuccess then
    CurrentPath := String(xMemory.Data);
end;

function RtlxGetCurrentPathPeb: String;
begin
  Result := RtlGetCurrentPeb.ProcessParameters.CurrentDirectory.DosPath.ToString;
end;

function RtlxSetCurrentPath(CurrentPath: String): TNtxStatus;
begin
  Result.Location := 'RtlSetCurrentDirectory_U';
  Result.Status := RtlSetCurrentDirectory_U(TNtUnicodeString.From(CurrentPath));
end;

{ Open & Create }

function NtxCreateFile(out hxFile: IHandle; DesiredAccess: THandle; FileName:
  String; CreateDisposition: TFileDisposition; ShareAccess: TFileShareMode;
  CreateOptions: TFileOpenOptions; ObjectAttributes: IObjectAttributes;
  FileAttributes: TFileAttributes; ActionTaken: PFileIoStatusResult):
  TNtxStatus;
var
  hFile: THandle;
  IoStatusBlock: TIoStatusBlock;
begin
  // Synchronious operations fail without SYNCHRONIZE right,
  // asynchronious handles are useless without it as well.
  DesiredAccess := DesiredAccess or SYNCHRONIZE;

  Result.Location := 'NtCreateFile';
  Result.LastCall.AttachAccess<TFileAccessMask>(DesiredAccess);

  Result.Status := NtCreateFile(hFile, DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(FileName).ToNative,
    IoStatusBlock, nil, FileAttributes, ShareAccess, CreateDisposition,
    CreateOptions, nil, 0);

  if Result.IsSuccess then
  begin
    hxFile := TAutoHandle.Capture(hFile);

    if Assigned(ActionTaken) then
      ActionTaken^ := TFileIoStatusResult(IoStatusBlock.Information);
  end;
end;

function NtxOpenFile(out hxFile: IHandle; DesiredAccess: TAccessMask;
  FileName: String; ObjectAttributes: IObjectAttributes; ShareAccess:
  TFileShareMode; OpenOptions: TFileOpenOptions): TNtxStatus;
var
  hFile: THandle;
  IoStatusBlock: TIoStatusBlock;
begin
  // Synchronious opens fail without SYNCHRONIZE right,
  // asynchronious handles are useless without it as well.
  DesiredAccess := DesiredAccess or SYNCHRONIZE;

  Result.Location := 'NtOpenFile';
  Result.LastCall.AttachAccess<TFileAccessMask>(DesiredAccess);

  Result.Status := NtOpenFile(hFile, DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(FileName).ToNative,
    IoStatusBlock, ShareAccess, OpenOptions);

  if Result.IsSuccess then
    hxFile := TAutoHandle.Capture(hFile);
end;

function NtxOpenFileById(out hxFile: IHandle; DesiredAccess: TAccessMask;
  const FileId: Int64; Root: THandle; ShareAccess: TFileShareMode; OpenOptions:
  TFileOpenOptions; HandleAttributes: TObjectAttributesFlags): TNtxStatus;
var
  hFile: THandle;
  ObjName: TNtUnicodeString;
  ObjAttr: TObjectAttributes;
  IoStatusBlock: TIoStatusBlock;
begin
  ObjName.Length := SizeOf(FileId);
  ObjName.MaximumLength := SizeOf(FileId);
  ObjName.Buffer := PWideChar(@FileId); // Pass binary value

  InitializeObjectAttributes(ObjAttr, @ObjName, HandleAttributes, Root);

  Result.Location := 'NtOpenFile';
  Result.LastCall.AttachAccess<TFileAccessMask>(DesiredAccess);

  Result.Status := NtOpenFile(hFile, DesiredAccess, @ObjAttr, IoStatusBlock,
    ShareAccess, OpenOptions or FILE_OPEN_BY_FILE_ID);

  if Result.IsSuccess then
    hxFile := TAutoHandle.Capture(hFile);
end;

{ Operations }

procedure AwaitFileOperation(var Result: TNtxStatus; hFile: THandle;
  xIoStatusBlock: IMemory<PIoStatusBlock>);
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

function NtxReadFile(hFile: THandle; Buffer: Pointer; BufferSize: Cardinal;
  Offset: UInt64; AsyncCallback: TAnonymousApcCallback): TNtxStatus;
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

function NtxWriteFile(hFile: THandle; Buffer: Pointer; BufferSize: Cardinal;
  Offset: UInt64; AsyncCallback: TAnonymousApcCallback): TNtxStatus;
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

function NtxpSetRenameInfoFile(hFile: THandle; TargetName: String;
  ReplaceIfExists: Boolean; RootDirectory: THandle;
  InfoClass: TFileInformationClass): TNtxStatus;
var
  xMemory: IMemory<PFileRenameInformation>; // aka PFileLinkInformation
begin
  IMemory(xMemory) := TAutoMemory.Allocate(SizeOf(TFileRenameInformation) +
    Length(TargetName) * SizeOf(WideChar));

  // Prepare a variable-length buffer for rename or hardlink operations
  xMemory.Data.ReplaceIfExists := ReplaceIfExists;
  xMemory.Data.RootDirectory := RootDirectory;
  xMemory.Data.FileNameLength := Length(TargetName) * SizeOf(WideChar);
  Move(PWideChar(TargetName)^, xMemory.Data.FileName,
    xMemory.Data.FileNameLength);

  Result := NtxSetFile(hFile, InfoClass, xMemory.Data, xMemory.Size);
end;

function NtxRenameFile(hFile: THandle; NewName: String;
  ReplaceIfExists: Boolean; RootDirectory: THandle): TNtxStatus;
begin
  // Note: if you get sharing violation when using RootDirectory, open it with
  // FILE_TRAVERSE | FILE_READ_ATTRIBUTES access.

  Result := NtxpSetRenameInfoFile(hFile, NewName, ReplaceIfExists,
    RootDirectory, FileRenameInformation);
end;

function NtxHardlinkFile(hFile: THandle; NewName: String;
  ReplaceIfExists: Boolean; RootDirectory: THandle): TNtxStatus;
begin
  Result := NtxpSetRenameInfoFile(hFile, NewName, ReplaceIfExists,
    RootDirectory, FileLinkInformation);
end;

{ Information }

function GrowFileDefault(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  Result := Memory.Size shl 1 + 256; // x2 + 256 B
end;

function NtxQueryFile(hFile: THandle; InfoClass: TFileInformationClass;
  out xMemory: IMemory; InitialBuffer: Cardinal; GrowthMethod:
  TBufferGrowthMethod): TNtxStatus;
var
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.AttachInfoClass(InfoClass);
  IMemory(xIsb) := TAutoMemory.Allocate(SizeOf(TIoStatusBlock));

  // NtQueryInformationFile does not return the required size. We either need
  // to know how to grow the buffer, or we should guess.
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowFileDefault;

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    xIsb.Data.Information := 0;

    Result.Status := NtQueryInformationFile(hFile, xIsb.Data, xMemory.Data,
      xMemory.Size, InfoClass);

    // Wait on async handles
    AwaitFileOperation(Result, hFile, xIsb);

  until not NtxExpandBufferEx(Result, xMemory, xIsb.Data.Information,
    GrowthMethod);
end;

function NtxSetFile(hFile: THandle; InfoClass: TFileInformationClass;
  Buffer: Pointer; BufferSize: Cardinal): TNtxStatus;
var
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtSetInformationFile';
  Result.LastCall.AttachInfoClass(InfoClass);
  IMemory(xIsb) := TAutoMemory.Allocate(SizeOf(TIoStatusBlock));

  Result.Status := NtSetInformationFile(hFile, xIsb.Data, Buffer,
    BufferSize, InfoClass);

  // Wait on async handles
  AwaitFileOperation(Result, hFile, xIsb);
end;

class function NtxFile.Query<T>(hFile: THandle;
  InfoClass: TFileInformationClass; out Buffer: T): TNtxStatus;
var
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.AttachInfoClass(InfoClass);
  IMemory(xIsb) := TAutoMemory.Allocate(SizeOf(TIoStatusBlock));

  Result.Status := NtQueryInformationFile(hFile, xIsb.Data, @Buffer,
    SizeOf(Buffer), InfoClass);

  // Wait on async handles
  AwaitFileOperation(Result, hFile, xIsb);
end;

class function NtxFile.SetInfo<T>(hFile: THandle;
  InfoClass: TFileInformationClass; const Buffer: T): TNtxStatus;
begin
  Result := NtxSetFile(hFile, InfoClass, @Buffer, SizeOf(Buffer));
end;

function GrowFileName(Memory: IMemory; BufferSize: NativeUInt): NativeUInt;
begin
  Result := SizeOf(Cardinal) + PFileNameInformation(Memory.Data).FileNameLength;
end;

function NtxQueryNameFile(hFile: THandle; out Name: String): TNtxStatus;
var
  xMemory: IMemory<PFileNameInformation>;
begin
  Result := NtxQueryFile(hFile, FileNameInformation, IMemory(xMemory),
    SizeOf(TFileNameInformation), GrowFileName);

  if Result.IsSuccess then
    SetString(Name, xMemory.Data.FileName, xMemory.Data.FileNameLength div
      SizeOf(WideChar));
end;

{ Enumeration }

function NtxEnumerateStreamsFile(hFile: THandle; out Streams:
  TArray<TFileStreamInfo>): TNtxStatus;
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

function GrowFileLinks(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  Result := PFileLinksInformation(Memory.Data).BytesNeeded;
end;

function NtxEnumerateHardLinksFile(hFile: THandle; out Links:
  TArray<TFileHardlinkLinkInfo>): TNtxStatus;
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

function NtxExpandHardlinkTarget(hOriginalFile: THandle;
  const Hardlink: TFileHardlinkLinkInfo; out FullName: String): TNtxStatus;
var
  hxFile: IHandle;
begin
  Result := NtxOpenFileById(hxFile, SYNCHRONIZE or FILE_READ_ATTRIBUTES,
    Hardlink.ParentFileId, hOriginalFile);

  if Result.IsSuccess then
  begin
    Result := NtxQueryNameFile(hxFile.Handle, FullName);

    if Result.IsSuccess then
      FullName := FullName + '\' + Hardlink.FileName;
  end;
end;

function NtxEnumerateUsingProcessesFile(hFile: THandle;
  out PIDs: TArray<TProcessId>): TNtxStatus;
var
  xMemory: IMemory<PFileProcessIdsUsingFileInformation>;
  i: Integer;
begin
  Result := NtxQueryFile(hFile, FileProcessIdsUsingFileInformation,
    IMemory(xMemory), SizeOf(TFileProcessIdsUsingFileInformation));

  if Result.IsSuccess then
  begin
    SetLength(PIDs, xMemory.Data.NumberOfProcessIdsInList);

    for i := 0 to High(PIDs) do
      PIDs[i] := xMemory.Data.ProcessIdList{$R-}[i]{$R+};
  end;
end;

end.
