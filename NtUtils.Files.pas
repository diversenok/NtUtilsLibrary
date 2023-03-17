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

  // File open/create operation parameteres; see NtUtils.Files.Open
  IFileParameters = interface
    // Fluent builder
    function UseFileName(const FileName: String; Mode: TFileNameMode = fnNative): IFileParameters;
    function UseFileId(const FileId: TFileId; const FileIdHigh: UInt64 = 0): IFileParameters;
    function UseAccess(const AccessMask: TFileAccessMask): IFileParameters;
    function UseRoot(const RootDirectory: IHandle): IFileParameters;
    function UseHandleAttributes(const Attributes: TObjectAttributesFlags): IFileParameters;
    function UseSecurity(const SecurityDescriptor: ISecurityDescriptor): IFileParameters;
    function UseShareMode(const ShareMode: TFileShareMode): IFileParameters;
    function UseOptions(const Options: TFileOpenOptions): IFileParameters;
    function UseSyncMode(const SyncMode: TFileSyncMode): IFileParameters;
    function UseFileAttributes(const Attributes: TFileAttributes): IFileParameters;
    function UseAllocationSize(const Size: UInt64): IFileParameters;
    function UseDisposition(const Disposition: TFileDisposition): IFileParameters;
    function UseTimeout(const Timeout: Int64): IFileParameters;
    function UsePipeType(const PipeType: TFilePipeType): IFileParameters;
    function UsePipeReadMode(const ReadMode: TFilePipeReadMode): IFileParameters;
    function UsePipeCompletion(const CompletionMode: TFilePipeCompletion): IFileParameters;
    function UsePipeMaximumInstances(const MaximumInstances: Cardinal): IFileParameters;
    function UsePipeInboundQuota(const InboundQuota: Cardinal): IFileParameters;
    function UsePipeOutboundQuota(const OutboundQuota: Cardinal): IFileParameters;
    function UseMailslotQuota(const MailslotQuota: Cardinal): IFileParameters;
    function UseMailslotMaximumMessageSize(const MaximumMessageSize: Cardinal): IFileParameters;

    // Accessor functions
    function GetFileName: String;
    function GetFileId: TFileId;
    function GetFileIdHigh: UInt64;
    function GetHasFileId: Boolean;
    function GetAccess: TFileAccessMask;
    function GetRoot: IHandle;
    function GetHandleAttributes: TObjectAttributesFlags;
    function GetSecurity: ISecurityDescriptor;
    function GetShareMode: TFileShareMode;
    function GetOptions: TFileOpenOptions;
    function GetSyncMode: TFileSyncMode;
    function GetFileAttributes: TFileAttributes;
    function GetAllocationSize: UInt64;
    function GetDisposition: TFileDisposition;
    function GetTimeout: Int64;
    function GetPipeType: TFilePipeType;
    function GetPipeReadMode: TFilePipeReadMode;
    function GetPipeCompletion: TFilePipeCompletion;
    function GetPipeMaximumInstances: Cardinal;
    function GetPipeInboundQuota: Cardinal;
    function GetPipeOutboundQuota: Cardinal;
    function GetMailslotQuota: Cardinal;
    function GetMailslotMaximumMessageSize: Cardinal;
    function GetObjectAttributes: PObjectAttributes;

    // Accessors
    property FileName: String read GetFileName;
    property FileId: TFileId read GetFileId;
    property FileIdHigh: UInt64 read GetFileIdHigh;
    property HasFileId: Boolean read GetHasFileId;
    property Access: TFileAccessMask read GetAccess;
    property Root: IHandle read GetRoot;
    property HandleAttributes: TObjectAttributesFlags read GetHandleAttributes;
    property Security: ISecurityDescriptor read GetSecurity;
    property ShareMode: TFileShareMode read GetShareMode;
    property Options: TFileOpenOptions read GetOptions;
    property SyncMode: TFileSyncMode read GetSyncMode;
    property FileAttributes: TFileAttributes read GetFileAttributes;
    property AllocationSize: UInt64 read GetAllocationSize;
    property Disposition: TFileDisposition read GetDisposition;
    property Timeout: Int64 read GetTimeout;
    property PipeType: TFilePipeType read GetPipeType;
    property PipeReadMode: TFilePipeReadMode read GetPipeReadMode;
    property PipeCompletion: TFilePipeCompletion read GetPipeCompletion;
    property PipeMaximumInstances: Cardinal read GetPipeMaximumInstances;
    property PipeInboundQuota: Cardinal read GetPipeInboundQuota;
    property PipeOutboundQuota: Cardinal read GetPipeOutboundQuota;
    property MailslotQuota: Cardinal read GetMailslotQuota;
    property MailslotMaximumMessageSize: Cardinal read GetMailslotMaximumMessageSize;
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
  Result := Path;

  if Result = '' then
    Exit;

  // Expand the SystemRoot symlink
  if RtlxPrefixStripString(SYSTEM_ROOT, Result) then
  begin
    Result := USER_SHARED_DATA.NtSystemRoot + Result;
    Exit;
  end;

  // Convert known locations
  for i := Low(SUBSTITUTIONS) to High(SUBSTITUTIONS) do
    if RtlxPrefixStripString(SUBSTITUTIONS[i].NativePath, Result) then
    begin
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
  if (Flags and VOLUME_NAME_MASK = VOLUME_NAME_DOS) then
    RtlxPrefixStripString('\\?\', FileName, True);
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
