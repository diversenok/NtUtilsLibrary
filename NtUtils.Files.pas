unit NtUtils.Files;

{
  This module defines the interfaces for preparing parameters for file open and
  create operations and provides filename manipulation routines.
}

interface

uses
  Ntapi.ntdef, Ntapi.ntioapi, Ntapi.WinBase, NtUtils;

type
  TFileNameMode = (
    fnNative,
    fnWin32
  );

  TFileSyncMode = (
    fsSynchronousNonAlert,
    fsSynchronousAlert,
    fsAsynchronous
  );

  // File open operation parameteres; see NtUtils.Files.Open
  IFileOpenParameters = interface
    // Fluent builder
    function UseFileName(const FileName: String; Mode: TFileNameMode = fnNative): IFileOpenParameters;
    function UseFileId(const FileId: TFileId; const FileIdHigh: UInt64 = 0): IFileOpenParameters;
    function UseAccess(const AccessMask: TFileAccessMask): IFileOpenParameters;
    function UseRoot(const RootDirectory: IHandle): IFileOpenParameters;
    function UseHandleAttributes(const Attributes: TObjectAttributesFlags): IFileOpenParameters;
    function UseShareMode(const ShareMode: TFileShareMode): IFileOpenParameters;
    function UseOpenOptions(const OpenOptions: TFileOpenOptions): IFileOpenParameters;
    function UseSyncMode(const SyncMode: TFileSyncMode): IFileOpenParameters;

    // Accessor functions
    function GetFileName: String;
    function GetFileId: TFileId;
    function GetFileIdHigh: UInt64;
    function GetHasFileId: Boolean;
    function GetAccess: TFileAccessMask;
    function GetRoot: IHandle;
    function GetHandleAttributes: TObjectAttributesFlags;
    function GetShareMode: TFileShareMode;
    function GetOpenOptions: TFileOpenOptions;
    function GetSyncMode: TFileSyncMode;
    function GetObjectAttributes: PObjectAttributes;

    // Accessors
    property FileName: String read GetFileName;
    property FileId: TFileId read GetFileId;
    property FileIdHigh: UInt64 read GetFileIdHigh;
    property HasFileId: Boolean read GetHasFileId;
    property Access: TFileAccessMask read GetAccess;
    property Root: IHandle read GetRoot;
    property HandleAttributes: TObjectAttributesFlags read GetHandleAttributes;
    property ShareMode: TFileShareMode read GetShareMode;
    property OpenOptions: TFileOpenOptions read GetOpenOptions;
    property SyncMode: TFileSyncMode read GetSyncMode;
    property ObjectAttributes: PObjectAttributes read GetObjectAttributes;
  end;

  // File create operation parameteres; see NtUtils.Files.Open
  IFileCreateParameters = interface
    // Fluent builder
    function UseFileName(const FileName: String; Mode: TFileNameMode = fnNative): IFileCreateParameters;
    function UseAccess(const AccessMask: TFileAccessMask): IFileCreateParameters;
    function UseRoot(const RootDirectory: IHandle): IFileCreateParameters;
    function UseHandleAttributes(const Attributes: TObjectAttributesFlags): IFileCreateParameters;
    function UseSecurity(const SecurityDescriptor: ISecurityDescriptor): IFileCreateParameters;
    function UseShareMode(const ShareMode: TFileShareMode): IFileCreateParameters;
    function UseCreateOptions(const CreateOptions: TFileOpenOptions): IFileCreateParameters;
    function UseSyncMode(const SyncMode: TFileSyncMode): IFileCreateParameters;
    function UseFileAttributes(const Attributes: TFileAttributes): IFileCreateParameters;
    function UseAllocationSize(const Size: UInt64): IFileCreateParameters;
    function UseDisposition(const Disposition: TFileDisposition): IFileCreateParameters;

    // Accessor functions
    function GetFileName: String;
    function GetAccess: TFileAccessMask;
    function GetRoot: IHandle;
    function GetHandleAttributes: TObjectAttributesFlags;
    function GetSecurity: ISecurityDescriptor;
    function GetShareMode: TFileShareMode;
    function GetCreateOptions: TFileOpenOptions;
    function GetSyncMode: TFileSyncMode;
    function GetFileAttributes: TFileAttributes;
    function GetAllocationSize: UInt64;
    function GetDisposition: TFileDisposition;
    function GetObjectAttributes: PObjectAttributes;

    // Accessors
    property FileName: String read GetFileName;
    property Access: TFileAccessMask read GetAccess;
    property Root: IHandle read GetRoot;
    property HandleAttributes: TObjectAttributesFlags read GetHandleAttributes;
    property Security: ISecurityDescriptor read GetSecurity;
    property ShareMode: TFileShareMode read GetShareMode;
    property CreateOptions: TFileOpenOptions read GetCreateOptions;
    property SyncMode: TFileSyncMode read GetSyncMode;
    property FileAttributes: TFileAttributes read GetFileAttributes;
    property AllocationSize: UInt64 read GetAllocationSize;
    property Disposition: TFileDisposition read GetDisposition;
    property ObjectAttributes: PObjectAttributes read GetObjectAttributes;
  end;

{ Paths }

// Make a Win32 filename absolute
function RtlxGetFullDosPath(
  const Path: String
): String;

// Convert a Win32 filename to Native format
function RtlxDosPathToNativePath(
  const Path: String
): String;

// Convert a Native filename to Win32 format
function RtlxNativePathToDosPath(
  const Path: String
): String;

// Query a name of a file in various formats
function RltxGetFinalNameFile(
  [Access(0)] hFile: THandle;
  out FileName: String;
  Flags: TFileFinalNameFlags = FILE_NAME_OPENED or VOLUME_NAME_NT
): TNtxStatus;

// Get the current directory
function RtlxGetCurrentDirectory: String;

// Set the current directory
function RtlxSetCurrentDirectory(
  const CurrentDir: String
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.ntpebteb, NtUtils.SysUtils,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Paths }

function RtlxGetFullDosPath;
var
  Buffer: IMemory<PWideChar>;
  Required: Cardinal;
begin
  Required := RtlGetLongestNtPathLength;

  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(Required);

    Required := RtlGetFullPathName_U(PWideChar(Path), Buffer.Size,
      Buffer.Data, nil);

  until Required <= Buffer.Size;

  SetString(Result, Buffer.Data, Required div SizeOf(WideChar));
end;

function RtlxDosPathToNativePath;
var
  Buffer: TNtUnicodeString;
  BufferDeallocator: IAutoReleasable;
begin
  Buffer := Default(TNtUnicodeString);

  if not NT_SUCCESS(RtlDosPathNameToNtPathName_U_WithStatus(
    PWideChar(Path), Buffer, nil, nil)) then
    Exit('');

  BufferDeallocator := RtlxDelayFreeUnicodeString(@Buffer);
  Result := Buffer.ToString;
end;

function RtlxNativePathToDosPath;
type
  TPathSubstitution = record
    NativePath, Win32Path: String;
  end;
const
  SUBSTITUTIONS: array [0..2] of TPathSubstitution = (
    (NativePath: '\Device\Mup\'; Win32Path: '\\'),
    (NativePath: '\??\UNC\';     Win32Path: '\\'),
    (NativePath: '\??\';         Win32Path: '')
  );
  SYSTEM_ROOT = '\SystemRoot';
var
  i: Integer;
begin
  if Path = '' then
    Exit('');

  // Expand the SystemRoot symlink
  if RtlxPrefixString(SYSTEM_ROOT, Path) then
  begin
    Result := USER_SHARED_DATA.NtSystemRoot +
      Copy(Path, Succ(Length(SYSTEM_ROOT)), Length(Path));
    Exit;
  end;

  Result := Path;

  // Convert known locations
  for i := Low(SUBSTITUTIONS) to High(SUBSTITUTIONS) do
    if RtlxPrefixString(SUBSTITUTIONS[i].NativePath, Result) then
    begin
      Delete(Result, Low(String), Length(SUBSTITUTIONS[i].NativePath));
      Insert(SUBSTITUTIONS[i].Win32Path, Result, Low(String));
      Exit;
    end;

  // Otherwise, follow the symlink to the global root of the namespace
  Insert('\\.\GlobalRoot', Result, Low(String));
end;

function RltxGetFinalNameFile;
var
  Buffer: IMemory<PWideChar>;
  Required: Cardinal;
begin
  Result.Location := 'GetFinalPathNameByHandleW';
  IMemory(Buffer) := Auto.AllocateDynamic(RtlGetLongestNtPathLength *
    SizeOf(WideChar));

  repeat
    Required := GetFinalPathNameByHandleW(hFile, Buffer.Data,
      Buffer.Size div SizeOf(WideChar), Flags);

    if Required >= Buffer.Size div SizeOf(WideChar) then
      Result.Status := STATUS_BUFFER_TOO_SMALL
    else
      Result.Win32Result := Required > 0;

  until not NtxExpandBufferEx(Result, IMemory(Buffer),
    Succ(Required) * SizeOf(WideChar), nil);

  if not Result.IsSuccess then
    Exit;

  SetString(FileName, Buffer.Data, Required);

  // Remove the excessive prefix
  if (Flags and VOLUME_NAME_MASK = VOLUME_NAME_DOS) and
    RtlxPrefixString('\\?\', FileName, True) then
    Delete(FileName, 1, Length('\\?\'));
end;

function RtlxGetCurrentDirectory;
var
  Buffer: IMemory<PWideChar>;
  Required: Cardinal;
begin
  Required := RtlGetLongestNtPathLength;

  repeat
    IMemory(Buffer) := Auto.AllocateDynamic(Required);
    Required := RtlGetCurrentDirectory_U(Buffer.Size, Buffer.Data);
  until Required <= Buffer.Size;

  SetString(Result, Buffer.Data, Required div SizeOf(WideChar));
end;

function RtlxSetCurrentDirectory;
begin
  Result.Location := 'RtlSetCurrentDirectory_U';
  Result.Status := RtlSetCurrentDirectory_U(TNtUnicodeString.From(CurrentDir));
end;

end.
