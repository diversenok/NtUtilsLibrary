unit NtUtils.Files.Open;

{
  This modules provides interfaces and functions for opening and creating files.
}

interface

uses
  Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntseapi, NtUtils, NtUtils.Files;

{ Parameters Builder }

const
  fnNative = TFileNameMode.fnNative;
  fnWin32 = TFileNameMode.fnWin32;

  fsSynchronousNonAlert = TFileSyncMode.fsSynchronousNonAlert;
  fsSynchronousAlert = TFileSyncMode.fsSynchronousAlert;
  fsAsynchronous = TFileSyncMode.fsAsynchronous;

// Make an instance of file open/create parameters builder
function FileParameters(
  [opt] const Template: IFileParameters = nil
): IFileParameters;

{ I/O Operations}

// Open an existing file object
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenFile(
  out hxFile: IHandle;
  const Parameters: IFileParameters
): TNtxStatus;

// Create or open a file
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxCreateFile(
  out hxFile: IHandle;
  const Parameters: IFileParameters;
  [out, opt] ActionTaken: PFileIoStatusResult = nil
): TNtxStatus;

// Create or open a named pipe file
function NtxCreatePipe(
  out hxPipe: IHandle;
  const Parameters: IFileParameters;
  [out, opt] ActionTaken: PFileIoStatusResult = nil
): TNtxStatus;

// Create a mailslot file
function NtxCreateMailslot(
  out hxMailslot: IHandle;
  const Parameters: IFileParameters;
  MaximumMessageSize: Cardinal = 0;
  MailslotQuota: Cardinal = 0
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, NtUtils.Objects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TFileParametersBuiler }

type
  TFileParametersBuiler = class (TInterfacedObject, IFileParameters)
  protected
    FObjAttr: TObjectAttributes;
    FNameStr: TNtUnicodeString;
    FNameBuffer: IMemory;
    FName: String;
    FFileId: TFileId128;
    FAccess: TFileAccessMask;
    FRoot: IHandle;
    FSecurity: ISecurityDescriptor;
    FCreateOpenOptions: TFileOpenOptions;
    FFileAttributes: TFileAttributes;
    FAllocationSize: UInt64;
    FDisposition: TFileDisposition;
    FShareMode: TFileShareMode;
    FSyncMode: TFileSyncMode;
    FTimeout: Int64;
    FPipeType: TFilePipeType;
    FPipeReadMode: TFilePipeReadMode;
    FPipeCompletion: TFilePipeCompletion;
    FPipeMaximumInstances: Cardinal;
    FMailslotMaximumMessageSize: Cardinal;
    FPipeInboundQuota, FPipeOutboundQuota, FMailslotQuota: Cardinal;
    function SetFileName(const Value: String; ValueMode: TFileNameMode): TFileParametersBuiler;
    function SetFileId(const ValueLow: TFileId; const ValueHigh: UInt64): TFileParametersBuiler;
    function SetAccess(const Value: TFileAccessMask): TFileParametersBuiler;
    function SetRoot(const Value: IHandle): TFileParametersBuiler;
    function SetHandleAttributes(const Value: TObjectAttributesFlags): TFileParametersBuiler;
    function SetSecurity(const Value: ISecurityDescriptor): TFileParametersBuiler;
    function SetShareMode(const Value: TFileShareMode): TFileParametersBuiler;
    function SetOptions(const Value: TFileOpenOptions): TFileParametersBuiler;
    function SetSyncMode(const Value: TFileSyncMode): TFileParametersBuiler;
    function SetFileAttributes(const Value: TFileAttributes): TFileParametersBuiler;
    function SetAllocationSize(const Value: UInt64): TFileParametersBuiler;
    function SetDisposition(const Value: TFileDisposition): TFileParametersBuiler;
    function SetTimeout(const Value: Int64): TFileParametersBuiler;
    function SetPipeType(const Value: TFilePipeType): TFileParametersBuiler;
    function SetPipeReadMode(const Value: TFilePipeReadMode): TFileParametersBuiler;
    function SetPipeCompletion(const Value: TFilePipeCompletion): TFileParametersBuiler;
    function SetPipeMaximumInstances(const Value: Cardinal): TFileParametersBuiler;
    function SetPipeInboundQuota(const Value: Cardinal): TFileParametersBuiler;
    function SetPipeOutboundQuota(const Value: Cardinal): TFileParametersBuiler;
    function SetMailslotQuota(const Value: Cardinal): TFileParametersBuiler;
    function SetMailslotMaximumMessageSize(const Value: Cardinal): TFileParametersBuiler;
    function Duplicate: TFileParametersBuiler;
    procedure UpdateNameBuffer;
  public
    function UseFileName(const Value: String; ValueMode: TFileNameMode): IFileParameters;
    function UseFileId(const ValueLow: TFileId; const ValueHigh: UInt64): IFileParameters;
    function UseAccess(const Value: TFileAccessMask): IFileParameters;
    function UseRoot(const Value: IHandle): IFileParameters;
    function UseHandleAttributes(const Value: TObjectAttributesFlags): IFileParameters;
    function UseSecurity(const Value: ISecurityDescriptor): IFileParameters;
    function UseShareMode(const Value: TFileShareMode): IFileParameters;
    function UseOptions(const Value: TFileOpenOptions): IFileParameters;
    function UseSyncMode(const Value: TFileSyncMode): IFileParameters;
    function UseFileAttributes(const Value: TFileAttributes): IFileParameters;
    function UseAllocationSize(const Value: UInt64): IFileParameters;
    function UseDisposition(const Value: TFileDisposition): IFileParameters;
    function UseTimeout(const Value: Int64): IFileParameters;
    function UsePipeType(const Value: TFilePipeType): IFileParameters;
    function UsePipeReadMode(const Value: TFilePipeReadMode): IFileParameters;
    function UsePipeCompletion(const Value: TFilePipeCompletion): IFileParameters;
    function UsePipeMaximumInstances(const Value: Cardinal): IFileParameters;
    function UsePipeInboundQuota(const Value: Cardinal): IFileParameters;
    function UsePipeOutboundQuota(const Value: Cardinal): IFileParameters;
    function UseMailslotQuota(const Value: Cardinal): IFileParameters;
    function UseMailslotMaximumMessageSize(const Value: Cardinal): IFileParameters;

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
    property HasFileId: Boolean read GetHasFileId;

    constructor Create;
  end;

constructor TFileParametersBuiler.Create;
begin
  inherited;
  FAccess := SYNCHRONIZE;
  FObjAttr.Length := SizeOf(FObjAttr);
  FObjAttr.Attributes := OBJ_CASE_INSENSITIVE;
  FObjAttr.ObjectName := @FNameStr;
  FCreateOpenOptions := 0;
  FSyncMode := fsSynchronousNonAlert;
  FShareMode := FILE_SHARE_ALL;
  FFileAttributes := FILE_ATTRIBUTE_NORMAL;
  FDisposition := FILE_OPEN_IF;
  FTimeout := NT_INFINITE;
  FPipeType := FILE_PIPE_BYTE_STREAM_TYPE;
  FPipeReadMode := FILE_PIPE_BYTE_STREAM_MODE;
  FPipeCompletion := FILE_PIPE_COMPLETE_OPERATION;
  FPipeMaximumInstances := $FFFFFFFF;
  FMailslotMaximumMessageSize := 0;
end;

function TFileParametersBuiler.Duplicate;
begin
  Result := TFileParametersBuiler.Create
    .SetFileName(GetFileName, fnNative)
    .SetFileId(GetFileId, GetFileIdHigh)
    .SetAccess(GetAccess)
    .SetRoot(GetRoot)
    .SetHandleAttributes(GetHandleAttributes)
    .SetSecurity(GetSecurity)
    .SetShareMode(GetShareMode)
    .SetOptions(GetOptions)
    .SetSyncMode(FSyncMode)
    .SetFileAttributes(GetFileAttributes)
    .SetAllocationSize(GetAllocationSize)
    .SetDisposition(GetDisposition)
    .SetTimeout(GetTimeout)
    .SetPipeType(GetPipeType)
    .SetPipeReadMode(GetPipeReadMode)
    .SetPipeCompletion(GetPipeCompletion)
    .SetPipeMaximumInstances(GetPipeMaximumInstances)
    .SetPipeInboundQuota(GetPipeInboundQuota)
    .SetPipeOutboundQuota(GetPipeOutboundQuota)
    .SetMailslotQuota(GetMailslotQuota)
    .SetMailslotMaximumMessageSize(GetMailslotMaximumMessageSize)
  ;
end;

function TFileParametersBuiler.GetAccess;
begin
  Result := FAccess;
end;

function TFileParametersBuiler.GetAllocationSize;
begin
  Result := FAllocationSize;
end;

function TFileParametersBuiler.GetDisposition;
begin
  Result := FDisposition;
end;

function TFileParametersBuiler.GetFileAttributes;
begin
  Result := FFileAttributes;
end;

function TFileParametersBuiler.GetFileId;
begin
  Result := FFileId.Low;
end;

function TFileParametersBuiler.GetFileIdHigh;
begin
  Result := FFileId.High;
end;

function TFileParametersBuiler.GetFileName;
begin
  Result := FName;
end;

function TFileParametersBuiler.GetHandleAttributes;
begin
  Result := FObjAttr.Attributes;
end;

function TFileParametersBuiler.GetHasFileId;
begin
  Result := (FFileId.Low <> 0) or (FFileId.High <> 0);
end;

function TFileParametersBuiler.GetMailslotMaximumMessageSize;
begin
  Result := FMailslotMaximumMessageSize;
end;

function TFileParametersBuiler.GetMailslotQuota;
begin
  Result := FMailslotQuota;
end;

function TFileParametersBuiler.GetObjectAttributes;
begin
  UpdateNameBuffer;
  Result := @FObjAttr;
end;

function TFileParametersBuiler.GetOptions;
begin
  Result := FCreateOpenOptions;
end;

function TFileParametersBuiler.GetPipeCompletion;
begin
  Result := FPipeCompletion;
end;

function TFileParametersBuiler.GetPipeInboundQuota;
begin
  Result := FPipeInboundQuota;
end;

function TFileParametersBuiler.GetPipeMaximumInstances;
begin
  Result := FPipeMaximumInstances;
end;

function TFileParametersBuiler.GetPipeOutboundQuota;
begin
  Result := FPipeOutboundQuota;
end;

function TFileParametersBuiler.GetPipeReadMode;
begin
  Result := FPipeReadMode;
end;

function TFileParametersBuiler.GetPipeType;
begin
  Result := FPipeType;
end;

function TFileParametersBuiler.GetRoot;
begin
  Result := FRoot;
end;

function TFileParametersBuiler.GetSecurity;
begin
  Result := FSecurity;
end;

function TFileParametersBuiler.GetShareMode;
begin
  Result := FShareMode;
end;

function TFileParametersBuiler.GetSyncMode;
begin
  Result := FSyncMode;
end;

function TFileParametersBuiler.GetTimeout;
begin
  Result := FTimeout;
end;

function TFileParametersBuiler.SetAccess;
begin
  FAccess := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetAllocationSize;
begin
  FAllocationSize := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetDisposition;
begin
  FDisposition := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetFileAttributes;
begin
  FFileAttributes := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetFileId;
begin
  FFileId.Low := ValueLow;
  FFileId.High := ValueHigh;
  Result := Self;
end;

function TFileParametersBuiler.SetFileName;
begin
  // Convert the filename to NT format as soon as possible becasuse Win32
  // filenames can be relative to the current directory that might change
  if ValueMode = fnWin32 then
    FName := RtlxDosPathToNativePath(Value)
  else
    FName := Value;

  Result := Self;
end;

function TFileParametersBuiler.SetHandleAttributes;
begin
  FObjAttr.Attributes := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetMailslotMaximumMessageSize;
begin
  FMailslotMaximumMessageSize := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetMailslotQuota;
begin
  FMailslotQuota := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetOptions;
begin
  FCreateOpenOptions := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetPipeCompletion;
begin
  FPipeCompletion := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetPipeInboundQuota;
begin
  FPipeInboundQuota := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetPipeMaximumInstances;
begin
  FPipeMaximumInstances := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetPipeOutboundQuota;
begin
  FPipeOutboundQuota := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetPipeReadMode;
begin
  FPipeReadMode := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetPipeType;
begin
  FPipeType := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetRoot;
begin
  FRoot := Value;
  FObjAttr.RootDirectory := HandleOrDefault(FRoot);
  Result := Self;
end;

function TFileParametersBuiler.SetSecurity;
begin
  FSecurity := Value;
  FObjAttr.SecurityDescriptor := Auto.RefOrNil<PSecurityDescriptor>(FSecurity);
  Result := Self;
end;

function TFileParametersBuiler.SetShareMode;
begin
  FShareMode := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetSyncMode;
begin
  FSyncMode := Value;
  Result := Self;
end;

function TFileParametersBuiler.SetTimeout;
begin
  FTimeout := Value;
  Result := Self;
end;

procedure TFileParametersBuiler.UpdateNameBuffer;
var
  IdSize: Word;
begin
  // A mixed (name + ID) buffer
  if (FName <> '') and HasFileId then
  begin
    if FFileId.High = 0 then
      IdSize := SizeOf(TFileId)
    else
      IdSize := SizeOf(TFileId128);

    // Concat the string without null terminator with binary ID
    FNameBuffer := Auto.AllocateDynamic(StringSizeNoZero(FName) + IdSize);
    Move(PWideChar(FName)^, FNameBuffer.Data^, StringSizeNoZero(FName));
    Move(FFileId, FNameBuffer.Offset(StringSizeNoZero(FName))^, IdSize);

    FNameStr.Length := FNameBuffer.Size;
    FNameStr.MaximumLength := FNameBuffer.Size;
    FNameStr.Buffer := FNameBuffer.Data;
  end

  // A binary (ID) buffer
  else if HasFileId then
  begin
    if FFileId.High = 0 then
      IdSize := SizeOf(TFileId)
    else
      IdSize := SizeOf(TFileId128);

    FNameBuffer := nil;
    FNameStr.Length := IdSize;
    FNameStr.MaximumLength := IdSize;
    FNameStr.Buffer := Pointer(@FFileId);
  end

  // Plain text (name) buffer
  else
  begin
    FNameBuffer := nil;
    FNameStr := TNtUnicodeString.From(FName);
  end;
end;

function TFileParametersBuiler.UseAccess;
begin
  Result := Duplicate.SetAccess(Value);
end;

function TFileParametersBuiler.UseAllocationSize;
begin
  Result := Duplicate.SetAllocationSize(Value);
end;

function TFileParametersBuiler.UseDisposition;
begin
  Result := Duplicate.SetDisposition(Value);
end;

function TFileParametersBuiler.UseFileAttributes;
begin
  Result := Duplicate.SetFileAttributes(Value);
end;

function TFileParametersBuiler.UseFileId;
begin
  Result := Duplicate.SetFileId(ValueLow, ValueHigh);
end;

function TFileParametersBuiler.UseFileName;
begin
  Result := Duplicate.SetFileName(Value, ValueMode);
end;

function TFileParametersBuiler.UseHandleAttributes;
begin
  Result := Duplicate.SetHandleAttributes(Value);
end;

function TFileParametersBuiler.UseMailslotMaximumMessageSize;
begin
  Result := Duplicate.SetMailslotMaximumMessageSize(Value);
end;

function TFileParametersBuiler.UseMailslotQuota;
begin
  Result := Duplicate.SetMailslotQuota(Value);
end;

function TFileParametersBuiler.UseOptions;
begin
  Result := Duplicate.SetOptions(Value);
end;

function TFileParametersBuiler.UsePipeCompletion;
begin
  Result := Duplicate.SetPipeCompletion(Value);
end;

function TFileParametersBuiler.UsePipeInboundQuota;
begin
  Result := Duplicate.SetPipeInboundQuota(Value);
end;

function TFileParametersBuiler.UsePipeMaximumInstances;
begin
  Result := Duplicate.SetPipeMaximumInstances(Value);
end;

function TFileParametersBuiler.UsePipeOutboundQuota;
begin
  Result := Duplicate.SetPipeOutboundQuota(Value);
end;

function TFileParametersBuiler.UsePipeReadMode;
begin
  Result := Duplicate.SetPipeReadMode(Value);
end;

function TFileParametersBuiler.UsePipeType;
begin
  Result := Duplicate.SetPipeType(Value);
end;

function TFileParametersBuiler.UseRoot;
begin
  Result := Duplicate.SetRoot(Value);
end;

function TFileParametersBuiler.UseSecurity;
begin
  Result := Duplicate.SetSecurity(Value);
end;

function TFileParametersBuiler.UseShareMode;
begin
  Result := Duplicate.SetShareMode(Value);
end;

function TFileParametersBuiler.UseSyncMode;
begin
  Result := Duplicate.SetSyncMode(Value);
end;

function TFileParametersBuiler.UseTimeout;
begin
  Result := Duplicate.SetTimeout(Value);
end;

{ Builder Functions }

function FileParameters;
begin
  if Assigned(Template) then
    Result := Template
  else
    Result := TFileParametersBuiler.Create;
end;

{ I/O Operations }

function NtxOpenFile;
var
  hFile: THandle;
  IoStatusBlock: TIoStatusBlock;
  OpenOptions: TFileOpenOptions;
  Access: TFileAccessMask;
begin
  Access := Parameters.Access;
  OpenOptions := Parameters.Options and not FILE_SYNCHRONOUS_FLAGS;

  case Parameters.SyncMode of
    fsSynchronousNonAlert:
    begin
      Access := Access or SYNCHRONIZE;
      OpenOptions := OpenOptions or FILE_SYNCHRONOUS_IO_NONALERT;
    end;

    fsSynchronousAlert:
    begin
      Access := Access or SYNCHRONIZE;
      OpenOptions := OpenOptions or FILE_SYNCHRONOUS_IO_ALERT;
    end;

    fsAsynchronous:
      ;
  else
    Result.Location := 'NtxOpenFile';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  if Parameters.HasFileId then
    OpenOptions := OpenOptions or FILE_OPEN_BY_FILE_ID;

  Result.Location := 'NtOpenFile';

  if BitTest(Parameters.Options and FILE_NON_DIRECTORY_FILE) then
    Result.LastCall.OpensForAccess<TIoFileAccessMask>(Access)
  else if BitTest(Parameters.Options and FILE_DIRECTORY_FILE) then
    Result.LastCall.OpensForAccess<TIoDirectoryAccessMask>(Access)
  else
    Result.LastCall.OpensForAccess<TFileAccessMask>(Access);

  Result.Status := NtOpenFile(
    hFile,
    Access,
    Parameters.ObjectAttributes^,
    IoStatusBlock,
    Parameters.ShareMode,
    OpenOptions
  );

  if Result.IsSuccess then
    hxFile := Auto.CaptureHandle(hFile);
end;

function NtxCreateFile;
var
  hFile: THandle;
  IoStatusBlock: TIoStatusBlock;
  Access: TFileAccessMask;
  CreateOptions: TFileOpenOptions;
  AllocationSize: UInt64;
begin
  Access := Parameters.Access;
  CreateOptions := Parameters.Options and not FILE_SYNCHRONOUS_FLAGS;
  AllocationSize := Parameters.AllocationSize;

  case Parameters.SyncMode of
    fsSynchronousNonAlert:
      begin
        Access := Access or SYNCHRONIZE;
        CreateOptions := CreateOptions or FILE_SYNCHRONOUS_IO_NONALERT;
      end;

    fsSynchronousAlert:
      begin
        Access := Access or SYNCHRONIZE;
        CreateOptions := CreateOptions or FILE_SYNCHRONOUS_IO_ALERT;
      end;

    fsAsynchronous:
      ;
  else
    Result.Location := 'NtxCreateFile';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result.Location := 'NtCreateFile';

  if BitTest(Parameters.Options and FILE_NON_DIRECTORY_FILE) then
    Result.LastCall.OpensForAccess<TIoFileAccessMask>(Access)
  else if BitTest(Parameters.Options and FILE_DIRECTORY_FILE) then
    Result.LastCall.OpensForAccess<TIoDirectoryAccessMask>(Access)
  else
    Result.LastCall.OpensForAccess<TFileAccessMask>(Access);

  Result.Status := NtCreateFile(
    hFile,
    Access,
    Parameters.ObjectAttributes^,
    IoStatusBlock,
    @AllocationSize,
    Parameters.FileAttributes,
    Parameters.ShareMode,
    Parameters.Disposition,
    CreateOptions,
    nil,
    0
  );

  if not Result.IsSuccess then
    Exit;

  hxFile := Auto.CaptureHandle(hFile);

  if Assigned(ActionTaken) then
    ActionTaken^ := TFileIoStatusResult(IoStatusBlock.Information);
end;

function NtxCreatePipe;
var
  hPipe: THandle;
  Access: TIoPipeAccessMask;
  OpenOptions: TFileOpenOptions;
  Timeout: TLargeInteger;
  IoStatusBlock: TIoStatusBlock;
begin
  Timeout := Parameters.Timeout;
  Access := Parameters.Access;
  OpenOptions := Parameters.Options and not FILE_SYNCHRONOUS_FLAGS;

  case Parameters.SyncMode of
    fsSynchronousNonAlert:
      begin
        Access := Access or SYNCHRONIZE;
        OpenOptions := OpenOptions or FILE_SYNCHRONOUS_IO_NONALERT;
      end;

    fsSynchronousAlert:
      begin
        Access := Access or SYNCHRONIZE;
        OpenOptions := OpenOptions or FILE_SYNCHRONOUS_IO_ALERT;
      end;

    fsAsynchronous:
      ;
  else
    Result.Location := 'NtxOpenNamedPipe';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  if Parameters.HasFileId then
    OpenOptions := OpenOptions or FILE_OPEN_BY_FILE_ID;

  Result.Location := 'NtCreateNamedPipeFile';
  Result.LastCall.OpensForAccess(Access);

  Result.Status := NtCreateNamedPipeFile(
    hPipe,
    Access,
    Parameters.ObjectAttributes^,
    IoStatusBlock,
    Parameters.ShareMode and not FILE_SHARE_DELETE,
    Parameters.Disposition,
    OpenOptions,
    Parameters.PipeType,
    Parameters.PipeReadMode,
    Parameters.PipeCompletion,
    Parameters.PipeMaximumInstances,
    Parameters.PipeInboundQuota,
    Parameters.PipeOutboundQuota,
    @Timeout
  );

  if not Result.IsSuccess then
    Exit;

  hxPipe := Auto.CaptureHandle(hPipe);

  if Assigned(ActionTaken) then
    ActionTaken^ := IoStatusBlock.Result;
end;

function NtxCreateMailslot;
var
  hMailslot: THandle;
  Access: TFileAccessMask;
  CreateOptions: TFileOpenOptions;
  Timeout: TLargeInteger;
  Isb: TIoStatusBlock;
begin
  Timeout := Parameters.Timeout;
  Access := Parameters.Access;
  CreateOptions := Parameters.Options and not FILE_SYNCHRONOUS_FLAGS;

  case Parameters.SyncMode of
    fsSynchronousNonAlert:
      begin
        Access := Access or SYNCHRONIZE;
        CreateOptions := CreateOptions or FILE_SYNCHRONOUS_IO_NONALERT;
      end;

    fsSynchronousAlert:
      begin
        Access := Access or SYNCHRONIZE;
        CreateOptions := CreateOptions or FILE_SYNCHRONOUS_IO_ALERT;
      end;

    fsAsynchronous:
      ;
  else
    Result.Location := 'NtxCreateMailslot';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  if Parameters.HasFileId then
    CreateOptions := CreateOptions or FILE_OPEN_BY_FILE_ID;

  Result.Location := 'NtCreateMailslotFile';
  Result.LastCall.OpensForAccess(Access);
  Result.Status := NtCreateMailslotFile(
    hMailslot,
    Access,
    Parameters.ObjectAttributes^,
    Isb,
    CreateOptions,
    Parameters.MailslotQuota,
    Parameters.MailslotMaximumMessageSize,
    @Timeout
  );

  if Result.IsSuccess then
    hxMailslot := Auto.CaptureHandle(hMailslot);
end;

end.
