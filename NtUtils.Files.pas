unit NtUtils.Files;

{
  This module defines the interfaces for preparing parameters for file open and
  create operations and provides filename manipulation routines.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntrtl, Ntapi.WinBase, NtUtils,
  DelphiUtils.AutoObjects;

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

  TNtxExtendedAttribute = record
    Flags: TFileEaFlags;
    Name: AnsiString;
    [opt] Value: IMemory; // use nil to delete

    class function From(
      const Name: AnsiString;
      [opt] const Value: IMemory;
      Flags: TFileEaFlags = 0
    ): TNtxExtendedAttribute; static;
  end;

  // File open/create operation parameters; see NtUtils.Files.Open
  IFileParameters = interface
    ['{223484B1-C23F-46DE-BAC5-25418010086D}']
    // Fluent builder
    function UseFileName(const FileName: String; Mode: TFileNameMode = fnNative): IFileParameters;
    function UseFileId(const FileId: TFileId; const FileIdHigh: UInt64 = 0): IFileParameters;
    function UseAccess(const AccessMask: TFileAccessMask): IFileParameters;
    function UseRoot(const RootDirectory: IHandle): IFileParameters;
    function UseHandleAttributes(const Attributes: TObjectAttributesFlags): IFileParameters;
    function UseImpersonation(const Level: TSecurityImpersonationLevel): IFileParameters;
    function UseEffectiveOnly(const Enabled: Boolean = True): IFileParameters;
    function UseContextTracking(const Enabled: Boolean = True): IFileParameters;
    function UseSecurity(const SecurityDescriptor: ISecurityDescriptor): IFileParameters;
    function UseShareMode(const ShareMode: TFileShareMode): IFileParameters;
    function UseOptions(const Options: TFileOpenOptions): IFileParameters;
    function UseSyncMode(const SyncMode: TFileSyncMode): IFileParameters;
    function UseFileAttributes(const Attributes: TFileAttributes): IFileParameters;
    function UseAllocationSize(const Size: UInt64): IFileParameters;
    function UseDisposition(const Disposition: TFileDisposition): IFileParameters;
    function UseEA(const EAs: TArray<TNtxExtendedAttribute>): IFileParameters;
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
    function GetImpersonation: TSecurityImpersonationLevel;
    function GetEffectiveOnly: Boolean;
    function GetContextTracking: Boolean;
    function GetSecurity: ISecurityDescriptor;
    function GetShareMode: TFileShareMode;
    function GetOptions: TFileOpenOptions;
    function GetSyncMode: TFileSyncMode;
    function GetFileAttributes: TFileAttributes;
    function GetAllocationSize: UInt64;
    function GetDisposition: TFileDisposition;
    function GetEA: TArray<TNtxExtendedAttribute>;
    function GetTimeout: Int64;
    function GetPipeType: TFilePipeType;
    function GetPipeReadMode: TFilePipeReadMode;
    function GetPipeCompletion: TFilePipeCompletion;
    function GetPipeMaximumInstances: Cardinal;
    function GetPipeInboundQuota: Cardinal;
    function GetPipeOutboundQuota: Cardinal;
    function GetMailslotQuota: Cardinal;
    function GetMailslotMaximumMessageSize: Cardinal;

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
    property EA: TArray<TNtxExtendedAttribute> read GetEA;
    property Timeout: Int64 read GetTimeout;
    property PipeType: TFilePipeType read GetPipeType;
    property PipeReadMode: TFilePipeReadMode read GetPipeReadMode;
    property PipeCompletion: TFilePipeCompletion read GetPipeCompletion;
    property PipeMaximumInstances: Cardinal read GetPipeMaximumInstances;
    property PipeInboundQuota: Cardinal read GetPipeInboundQuota;
    property PipeOutboundQuota: Cardinal read GetPipeOutboundQuota;
    property MailslotQuota: Cardinal read GetMailslotQuota;
    property MailslotMaximumMessageSize: Cardinal read GetMailslotMaximumMessageSize;

    // Make a reference to the object attributes.
    // Note: the operation might fail because UNICODE_STRING for the name has a
    // limit on the number of characters it can address.
    function BuildObjectAttributes(out Reference: PObjectAttributes): TNtxStatus;
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

// Classify a Win32 filename
function RtlxDetermineDosPathType(
  const Path: String
): TRtlPathType;

// Query a name of a file in various formats
function RtlxGetFinalNameFile(
  [Access(0)] const hxFile: IHandle;
  out FileName: String;
  Flags: TFileFinalNameFlags = FILE_NAME_OPENED or VOLUME_NAME_NT
): TNtxStatus;

// Get the current directory
function RtlxGetCurrentDirectory: String;

// Set the current directory
function RtlxSetCurrentDirectory(
  const CurrentDir: String
): TNtxStatus;

{ Extended Attributes }

// Prepare an extended attributes buffer
[Result: MayReturnNil]
function RtlxAllocateEAs(
  const Entries: TArray<TNtxExtendedAttribute>
): IMemory<PFileFullEaInformation>;

// Capture a raw buffer with extended attribtues
function RtlxCaptureFullEaInformation(
  [in, opt] Buffer: PFileFullEaInformation
): TArray<TNtxExtendedAttribute>;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpebteb, NtUtils.SysUtils;

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
begin
  // While RtlGetFullPathName_U can always handle long paths,
  // RtlDosPathNameToNtPathName_U only does that if the long-path-aware bit is
  // set in PEB. Reimplement DOS to NT conversion here to make it always work
  // for long paths, even on older versions.

  // Don't simplify local device paths with a specific prefix
  if RtlxPrefixString('\\?\', Path, True) then
    Exit('\??\' + Copy(Path, 5, Length(Path)));

  // Simplify and convert relative, drive-relative, and rooted to absolute
  Result := RtlxGetFullDosPath(Path);

  if Result = '' then
    Exit;

  case RtlxDetermineDosPathType(Result) of
    RtlPathTypeUncAbsolute:
      // \\Share\Path -> \??\UNC\Share\Path
      Result := '\??\UNC\' + Copy(Result, 3, Length(Result));

    RtlPathTypeLocalDevice:
      // \\.\Path -> \??\Path
      Result := '\??\' + Copy(Result, 5, Length(Result));
  else
    // C:\Path -> \??\C:\Path
    Result := '\??\' + Result;
  end;
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

function RtlxDetermineDosPathType;
begin
  Result := RtlDetermineDosPathNameType_U(PWideChar(Path));
end;

function RtlxGetFinalNameFile;
var
  Buffer: IMemory<PWideChar>;
  Required: Cardinal;
begin
  Result.Location := 'GetFinalPathNameByHandleW';
  IMemory(Buffer) := Auto.AllocateDynamic(RtlGetLongestNtPathLength *
    SizeOf(WideChar));

  repeat
    Required := GetFinalPathNameByHandleW(HandleOrDefault(hxFile), Buffer.Data,
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
var
  CurrentDirStr: TNtUnicodeString;
begin
  Result := RtlxInitUnicodeString(CurrentDirStr, CurrentDir);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlSetCurrentDirectory_U';
  Result.Status := RtlSetCurrentDirectory_U(CurrentDirStr);
end;

{ Extended Attributes }

class function TNtxExtendedAttribute.From;
begin
  Result.Flags := Flags;
  Result.Name := Name;
  Result.Value := Value;
end;

function RtlxAllocateEAs;
var
  Size: Cardinal;
  i: Integer;
  Cursor: PFileFullEaInformation;
begin
  if Length(Entries) <= 0 then
    Exit(nil);

  // Caclulate the required buffer size
  Size := 0;

  for i := 0 to High(Entries) do
    Inc(Size, AlignUp(SizeOf(TFileFullEaInformation) +
      Cardinal(Length(Entries[i].Name)) +
      Auto.SizeOrZero(Entries[i].Value), 4));

  // Write all EAs into the buffer
  IMemory(Result) := Auto.AllocateDynamic(Size);
  Cursor := Result.Data;

  for i := 0 to High(Entries) do
  begin
    Cursor.Flags := Entries[i].Flags;
    Cursor.EaNameLength := Length(Entries[i].Name);
    Cursor.EaValueLength := Auto.SizeOrZero(Entries[i].Value);
    Move(PAnsiChar(Entries[i].Name)^, Cursor.EaName, Cursor.EaNameLength);

    if Assigned(Entries[i].Value) then
      Move(Entries[i].Value.Data^,
        Cursor.EaName{$R-}[Succ(Cursor.EaNameLength)]{$IFDEF R+}{$R+}{$ENDIF},
        Cursor.EaValueLength);

    if i < High(Entries) then
    begin
      // Record offsets and advance to the next entry
      Cursor.NextEntryOffset := AlignUp(SizeOf(TFileFullEaInformation) +
        Cardinal(Length(Entries[i].Name)) + Entries[i].Value.Size, 4);
      Cursor := Pointer(PByte(Cursor) + Cursor.NextEntryOffset);
    end;
  end;
end;

function RtlxCaptureFullEaInformation;
var
  Cursor: PFileFullEaInformation;
  Count: Integer;
begin
  if not Assigned(Buffer) then
    Exit(nil);

  // Count entries
  Count := 1;
  Cursor := Buffer;

  repeat
    if Cursor.NextEntryOffset = 0 then
      Break;

    Inc(Count);
    Cursor := Pointer(PByte(Cursor) + Cursor.NextEntryOffset);
  until False;

  // Allocate the storage
  SetLength(Result, Count);
  Count := 0;
  Cursor := Buffer;

  repeat
    // Save each EA
    Result[Count].Flags := Cursor.Flags;
    SetString(Result[Count].Name, PAnsiChar(@Cursor.EaName[0]),
      Cursor.EaNameLength);

    Result[Count].Value := Auto.CopyDynamic(
      @Cursor.EaName{$R-}[Cursor.EaNameLength]{$IFDEF R+}{$R+}{$ENDIF},
      Cursor.EaValueLength);

    if Cursor.NextEntryOffset = 0 then
      Break;

    Inc(Count);
    Cursor := Pointer(PByte(Cursor) + Cursor.NextEntryOffset);
  until False;
end;

end.
