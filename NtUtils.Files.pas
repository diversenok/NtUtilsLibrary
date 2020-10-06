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
// TODO: Add safe NT to Win32 path conversion
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
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil): TNtxStatus;

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
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntpebteb,
  DelphiUtils.AutoObject;

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

function NtxCreateFile(out hxFile: IHandle; DesiredAccess: THandle;
  FileName: String; Root: THandle; CreateDisposition: TFileDisposition;
  ShareAccess: TFileShareMode; CreateOptions: Cardinal; FileAttributes:
  Cardinal; HandleAttributes: Cardinal; ActionTaken: PCardinal): TNtxStatus;
var
  hFile: THandle;
  ObjAttr: TObjectAttributes;
  IoStatusBlock: TIoStatusBlock;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(FileName).RefOrNull,
    HandleAttributes, Root);

  Result.Location := 'NtCreateFile';
  Result.LastCall.AttachAccess<TFileAccessMask>(DesiredAccess);

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
  ObjAttr: TObjectAttributes;
  IoStatusBlock: TIoStatusBlock;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(FileName).RefOrNull,
    HandleAttributes, Root);

  Result.Location := 'NtOpenFile';
  Result.LastCall.AttachAccess<TFileAccessMask>(DesiredAccess);

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
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.AttachInfoClass(InfoClass);

  // NtQueryInformationFile does not return the required size. We either need
  // to know how to grow the buffer, or we should guess.
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowFileDefault;

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    IoStatusBlock.Information := 0;
    Result.Status := NtQueryInformationFile(hFile, IoStatusBlock, xMemory.Data,
      xMemory.Size, InfoClass);
  until not NtxExpandBufferEx(Result, xMemory, IoStatusBlock.Information,
    GrowthMethod);
end;

function NtxSetFile(hFile: THandle; InfoClass: TFileInformationClass;
  Buffer: Pointer; BufferSize: Cardinal): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtSetInformationFile';
  Result.LastCall.AttachInfoClass(InfoClass);

  Result.Status := NtSetInformationFile(hFile, IoStatusBlock, Buffer,
    BufferSize, InfoClass);
end;

class function NtxFile.Query<T>(hFile: THandle;
  InfoClass: TFileInformationClass; out Buffer: T): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtQueryInformationFile';
  Result.LastCall.AttachInfoClass(InfoClass);

  Result.Status := NtQueryInformationFile(hFile, IoStatusBlock, @Buffer,
    SizeOf(Buffer), InfoClass);
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

function NtxEnumerateStreamsFile(hFile: THandle; out Streams:
  TArray<TFileStreamInfo>) : TNtxStatus;
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
  TArray<TFileHardlinkLinkInfo>) : TNtxStatus;
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
