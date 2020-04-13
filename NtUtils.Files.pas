unit NtUtils.Files;

interface

uses
  Winapi.WinNt, Ntapi.ntioapi, NtUtils, NtUtils.Objects, DelphiApi.Reflection;

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
function RtlxDosPathToNtPathUnsafe(Path: String): String;

// Convert an NT path to a Win32 path
function RtlxNtPathToDosPathUnsafe(Path: String): String;

// Get current path
function RtlxGetCurrentPath(out CurrentPath: String): TNtxStatus;
function RtlxGetCurrentPathPeb: String;

// Set a current directory
function RtlxSetCurrentPath(CurrentPath: String): TNtxStatus;

{ Open & Create }

// Create/open a file
function NtxCreateFile(out hxFile: IHandle; DesiredAccess: THandle;
  FileName: String; Root: THandle = 0; CreateDisposition: TFileDisposition =
  FILE_CREATE; ShareAccess: TFileShareMode = FILE_SHARE_ALL; CreateOptions:
  Cardinal = 0; FileAttributes: Cardinal = FILE_ATTRIBUTE_NORMAL;
  HandleAttributes: Cardinal = 0; ActionTaken: PCardinal = nil): TNtxStatus;

// Open a file
function NtxOpenFile(out hxFile: IHandle; DesiredAccess: TAccessMask;
  FileName: String; Root: THandle = 0; ShareAccess: TFileShareMode =
  FILE_SHARE_ALL; OpenOptions: Cardinal = 0; HandleAttributes: Cardinal = 0):
  TNtxStatus;

// Open a file by ID
function NtxOpenFileById(out hxFile: IHandle; DesiredAccess: TAccessMask;
  FileId: Int64; Root: THandle = 0; ShareAccess: TFileShareMode =
  FILE_SHARE_ALL; HandleAttributes: Cardinal = 0): TNtxStatus;

{ Operations }

// Rename a file
function NtxRenameFile(hFile: THandle; NewName: String;
  ReplaceIfExists: Boolean = False; RootDirectory: THandle = 0): TNtxStatus;

// Creare a hardlink for a file
function NtxHardlinkFile(hFile: THandle; NewName: String;
  ReplaceIfExists: Boolean = False; RootDirectory: THandle = 0): TNtxStatus;

{ Information }

// Query variable-length information
function NtxQueryFile(hFile: THandle; InfoClass: TFileInformationClass;
  out xMemory: IMemory; InitialBufferSize: Cardinal = 0): TNtxStatus;

// Set variable-length information
function NtxSetFile(hFile: THandle; InfoClass: TFileInformationClass;
  Buffer: Pointer; BufferSize: Cardinal): TNtxStatus;

type
  NtxFile = class
    // Query fixed-size information
    class function Query<T>(hFile: THandle;
      InfoClass: TFileInformationClass; out Buffer: T): TNtxStatus; static;

    // Set fixed-size information
    class function SetInfo<T>(hFile: THandle;
      InfoClass: TFileInformationClass; const Buffer: T): TNtxStatus; static;
  end;

// Query name of a file
function NtxQueryNameFile(hFile: THandle; out Name: String): TNtxStatus;

// Enumerate file streams
function NtxEnumerateStreamsFile(hFile: THandle; out Streams:
  TArray<TFileStreamInfo>) : TNtxStatus;

// Enumerate hardlinks pointing to the file
function NtxEnumerateHardLinksFile(hFile: THandle; out Links:
  TArray<TFileHardlinkLinkInfo>) : TNtxStatus;

// Get full name of a hardlink target
function NtxExpandHardlinkTarget(hOriginalFile: THandle;
  const Hardlink: TFileHardlinkLinkInfo; out FullName: String): TNtxStatus;

// Enumerate processes that use this file. Requires FILE_READ_ATTRIBUTES.
function NtxEnumerateUsingProcessesFile(hFile: THandle;
  out PIDs: TArray<TProcessId>): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb;

{ Paths }

function RtlxDosPathToNtPath(DosPath: String; out NtPath: String): TNtxStatus;
var
  NtPathStr: UNICODE_STRING;
begin
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

function RtlxDosPathToNtPathUnsafe(Path: String): String;
begin
  Result := '\??\' + Path;
end;

function RtlxNtPathToDosPathUnsafe(Path: String): String;
begin
  Result := '\\.\Global\GLOBALROOT' + Path;
end;

function RtlxGetCurrentPath(out CurrentPath: String): TNtxStatus;
var
  Buffer: PWideChar;
  BufferSize: Cardinal;
begin
  BufferSize := RtlGetLongestNtPathLength;
  Buffer := AllocMem(BufferSize);

  try
    Result.Location := 'RtlGetCurrentDirectory_U';
    Result.Status := RtlGetCurrentDirectory_U(BufferSize, Buffer);

    if Result.IsSuccess then
      CurrentPath := String(Buffer);
  finally
    FreeMem(Buffer);
  end;
end;

function RtlxGetCurrentPathPeb: String;
begin
  Result := RtlGetCurrentPeb.ProcessParameters.CurrentDirectory.DosPath.ToString;
end;

function RtlxSetCurrentPath(CurrentPath: String): TNtxStatus;
var
  PathStr: UNICODE_STRING;
begin
  PathStr.FromString(CurrentPath);

  Result.Location := 'RtlSetCurrentDirectory_U';
  Result.Status := RtlSetCurrentDirectory_U(PathStr);
end;

{ Open & Create }

function NtxCreateFile(out hxFile: IHandle; DesiredAccess: THandle;
  FileName: String; Root: THandle; CreateDisposition: TFileDisposition;
  ShareAccess: TFileShareMode; CreateOptions: Cardinal; FileAttributes:
  Cardinal; HandleAttributes: Cardinal; ActionTaken: PCardinal): TNtxStatus;
var
  hFile: THandle;
  ObjAttr: TObjectAttributes;
  ObjName: UNICODE_STRING;
  IoStatusBlock: TIoStatusBlock;
begin
  ObjName.FromString(FileName);
  InitializeObjectAttributes(ObjAttr, @ObjName, HandleAttributes, Root);

  Result.Location := 'NtCreateFile';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @FileAccessType;

  Result.Status := NtCreateFile(hFile, DesiredAccess, ObjAttr, IoStatusBlock,
    nil, FileAttributes, ShareAccess, CreateDisposition, CreateOptions, nil, 0);

  if Result.IsSuccess then
    hxFile := TAutoHandle.Capture(hFile);

  if Result.IsSuccess and Assigned(ActionTaken) then
    ActionTaken^ := Cardinal(IoStatusBlock.Information);
end;

function NtxOpenFile(out hxFile: IHandle; DesiredAccess: TAccessMask;
  FileName: String; Root: THandle; ShareAccess: TFileShareMode; OpenOptions:
  Cardinal; HandleAttributes: Cardinal): TNtxStatus;
var
  hFile: THandle;
  ObjName: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
  IoStatusBlock: TIoStatusBlock;
begin
  ObjName.FromString(FileName);
  InitializeObjectAttributes(ObjAttr, @ObjName, HandleAttributes, Root);

  Result.Location := 'NtOpenFile';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @FileAccessType;

  Result.Status := NtOpenFile(hFile, DesiredAccess, ObjAttr, IoStatusBlock,
    ShareAccess, OpenOptions);

  if Result.IsSuccess then
    hxFile := TAutoHandle.Capture(hFile);
end;

function NtxOpenFileById(out hxFile: IHandle; DesiredAccess: TAccessMask;
  FileId: Int64; Root: THandle; ShareAccess: TFileShareMode; HandleAttributes:
  Cardinal): TNtxStatus;
var
  hFile: THandle;
  ObjName: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
  IoStatusBlock: TIoStatusBlock;
begin
  ObjName.Length := SizeOf(FileId);
  ObjName.MaximumLength := SizeOf(FileId);
  ObjName.Buffer := PWideChar(@FileId); // Pass binary value

  InitializeObjectAttributes(ObjAttr, @ObjName, HandleAttributes, Root);

  Result.Location := 'NtOpenFile';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @FileAccessType;

  Result.Status := NtOpenFile(hFile, DesiredAccess, ObjAttr, IoStatusBlock,
    ShareAccess, FILE_OPEN_BY_FILE_ID or FILE_SYNCHRONOUS_IO_NONALERT);

  if Result.IsSuccess then
    hxFile := TAutoHandle.Capture(hFile);
end;

{ Operations }

function NtxpSetRenameInfoFile(hFile: THandle; TargetName: String;
  ReplaceIfExists: Boolean; RootDirectory: THandle;
  InfoClass: TFileInformationClass): TNtxStatus;
var
  Buffer: PFileRenameInformation; // aka PFileLinkInformation
  BufferSize: Cardinal;
begin
  // Prepare a variable-length buffer for rename or hardlink operation
  BufferSize := SizeOf(TFileRenameInformation) +
    Length(TargetName) * SizeOf(WideChar);
  Buffer := AllocMem(BufferSize);

  Buffer.ReplaceIfExists := ReplaceIfExists;
  Buffer.RootDirectory := RootDirectory;
  Buffer.FileNameLength := Length(TargetName) * SizeOf(WideChar);
  Move(PWideChar(TargetName)^, Buffer.FileName, Buffer.FileNameLength);

  Result := NtxSetFile(hFile, InfoClass, Buffer, BufferSize);
  FreeMem(Buffer);
end;

function NtxRenameFile(hFile: THandle; NewName: String;
  ReplaceIfExists: Boolean; RootDirectory: THandle): TNtxStatus;
begin
  // Note: if you get sharing violation when using RootDirectory open it with
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

procedure NtxpFormatFileQuery(var Status: TNtxStatus;
  InfoClass: TFileInformationClass);
begin
  Status.Location := 'NtQueryInformationFile';
  Status.LastCall.CallType := lcQuerySetCall;
  Status.LastCall.InfoClass := Cardinal(InfoClass);
  Status.LastCall.InfoClassType := TypeInfo(TFileInformationClass);
end;

function NtxQueryFile(hFile: THandle; InfoClass: TFileInformationClass;
  out xMemory: IMemory; InitialBufferSize: Cardinal): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
  Buffer: Pointer;
  BufferSize: Cardinal;
begin
  NtxpFormatFileQuery(Result, InfoClass);

  BufferSize := InitialBufferSize;
  repeat
    Buffer := AllocMem(BufferSize);

    IoStatusBlock.Information := 0;
    Result.Status := NtQueryInformationFile(hFile, IoStatusBlock, Buffer,
      BufferSize, InfoClass);

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, BufferSize shl 1 + 256);

  if Result.IsSuccess then
    xMemory := TAutoMemory.Capture(Buffer, BufferSize);
end;

function NtxSetFile(hFile: THandle; InfoClass: TFileInformationClass;
  Buffer: Pointer; BufferSize: Cardinal): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtSetInformationFile';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TFileInformationClass);

  Result.Status := NtSetInformationFile(hFile, IoStatusBlock, Buffer,
    BufferSize, InfoClass);
end;

class function NtxFile.Query<T>(hFile: THandle;
  InfoClass: TFileInformationClass; out Buffer: T): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TFileInformationClass);

  Result.Status := NtQueryInformationFile(hFile, IoStatusBlock, @Buffer,
    SizeOf(Buffer), InfoClass);
end;

class function NtxFile.SetInfo<T>(hFile: THandle;
  InfoClass: TFileInformationClass; const Buffer: T): TNtxStatus;
begin
  Result := NtxSetFile(hFile, InfoClass, @Buffer, SizeOf(Buffer));
end;

function NtxQueryNameFile(hFile: THandle; out Name: String): TNtxStatus;
var
  Buffer: PFileNameInformation;
  BufferSize, Required: Cardinal;
  IoStatusBlock: TIoStatusBlock;
begin
  NtxpFormatFileQuery(Result, FileNameInformation);

  BufferSize := SizeOf(TFileNameInformation);
  repeat
    Buffer := AllocMem(BufferSize);

    Result.Status := NtQueryInformationFile(hFile, IoStatusBlock, Buffer,
      BufferSize, FileNameInformation);

    Required := SizeOf(Cardinal) + Buffer.FileNameLength;

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, Required);

  if not Result.IsSuccess then
    Exit;

  SetString(Name, Buffer.FileName, Buffer.FileNameLength div 2);
  FreeMem(Buffer);
end;

function NtxEnumerateStreamsFile(hFile: THandle; out Streams:
  TArray<TFileStreamInfo>) : TNtxStatus;
var
  Buffer, pStream: PFileStreamInformation;
  BufferSize, Required: Cardinal;
  IoStatusBlock: TIoStatusBlock;
begin
  NtxpFormatFileQuery(Result, FileStreamInformation);

  BufferSize := SizeOf(TFileStreamInformation);
  repeat
    Buffer := AllocMem(BufferSize);

    Result.Status := NtQueryInformationFile(hFile, IoStatusBlock, Buffer,
      BufferSize, FileStreamInformation);

    Required := BufferSize shl 1 + 64;

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, Required);

  if not Result.IsSuccess then
    Exit;

  SetLength(Streams, 0);
  pStream := Buffer;

  repeat
    SetLength(Streams, Length(Streams) + 1);
    Streams[High(Streams)].StreamSize := pStream.StreamSize;
    Streams[High(Streams)].StreamAllocationSize := pStream.StreamAllocationSize;
    SetString(Streams[High(Streams)].StreamName, pStream.StreamName,
      pStream.StreamNameLength div 2);

    if pStream.NextEntryOffset <> 0 then
      pStream := Pointer(NativeUInt(pStream) + pStream.NextEntryOffset)
    else
      Break;

  until False;

  FreeMem(Buffer);
end;

function NtxEnumerateHardLinksFile(hFile: THandle; out Links:
  TArray<TFileHardlinkLinkInfo>) : TNtxStatus;
var
  Buffer: PFileLinksInformation;
  pLink: PFileLinkEntryInformation;
  BufferSize, Required: Cardinal;
  IoStatusBlock: TIoStatusBlock;
  i: Integer;
begin
  NtxpFormatFileQuery(Result, FileHardLinkInformation);

  BufferSize := SizeOf(TFileLinksInformation);
  repeat
    Buffer := AllocMem(BufferSize);

    Result.Status := NtQueryInformationFile(hFile, IoStatusBlock, Buffer,
      BufferSize, FileHardLinkInformation);

    Required := Buffer.BytesNeeded;

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, Required);

  if not Result.IsSuccess then
    Exit;

  SetLength(Links, Buffer.EntriesReturned);

  pLink := @Buffer.Entry;
  i := 0;

  repeat
    if i > High(Links) then
      Break;

    // Note: we have only the filename and the ID of the parent directory

    Links[i].ParentFileId := pLink.ParentFileId;
    SetString(Links[i].FileName, pLink.FileName, pLink.FileNameLength);

    if pLink.NextEntryOffset <> 0 then
      pLink := Pointer(NativeUInt(pLink) + pLink.NextEntryOffset)
    else
      Break;

    Inc(i);
  until False;

  FreeMem(Buffer);
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
  xMemory: IMemory;
  Buffer: PFileProcessIdsUsingFileInformation;
  i: Integer;
begin
  Result := NtxQueryFile(hFile, FileProcessIdsUsingFileInformation, xMemory,
    SizeOf(TFileProcessIdsUsingFileInformation));

  if Result.IsSuccess then
  begin
    Buffer := xMemory.Address;
    SetLength(PIDs, Buffer.NumberOfProcessIdsInList);

    for i := 0 to High(PIDs) do
      PIDs[i] := Buffer.ProcessIdList{$R-}[i]{$R+};
  end;
end;

end.
