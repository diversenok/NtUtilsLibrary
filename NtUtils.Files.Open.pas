unit NtUtils.Files.Open;

{
  This modules provides interfaces and functions for opening and creating files.
}

interface

uses
  Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntseapi, NtUtils, NtUtils.Files,
  DelphiApi.Reflection;

{ Parameters Builder }

const
  fnNative = TFileNameMode.fnNative;
  fnWin32 = TFileNameMode.fnWin32;

  fsSynchronousNonAlert = TFileSyncMode.fsSynchronousNonAlert;
  fsSynchronousAlert = TFileSyncMode.fsSynchronousAlert;
  fsAsynchronous = TFileSyncMode.fsAsynchronous;

// Make an instance of file open parameters builder
function FileOpenParameters(
  [opt] const Template: IFileOpenParameters = nil
): IFileOpenParameters;

// Make an instance of file create parameters builder
function FileCreateParameters(
  [opt] const Template: IFileCreateParameters = nil
): IFileCreateParameters;

{ I/O Operations}

// Open an existing file object
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenFile(
  out hxFile: IHandle;
  const Parameters: IFileOpenParameters
): TNtxStatus;

// Create or open a file
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxCreateFile(
  out hxFile: IHandle;
  const Parameters: IFileCreateParameters;
  [out, opt] ActionTaken: PFileIoStatusResult = nil
): TNtxStatus;

// Open a named pipe file
function NtxOpenNamedPipe(
  out hxPipe: IHandle;
  const Parameters: IFileOpenParameters
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, NtUtils.Objects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TFileOpenParametersBuiler }

type
  TFileOpenParametersBuiler = class (TInterfacedObject, IFileOpenParameters)
  protected
    FObjAttr: TObjectAttributes;
    FNameStr: TNtUnicodeString;
    FNameBuffer: IMemory;
    FName: String;
    FFileId: TFileId128;
    FAccess: TFileAccessMask;
    FRoot: IHandle;
    FOpenOptions: TFileOpenOptions;
    FShareMode: TFileShareMode;
    FSyncMode: TFileSyncMode;
    function SetFileName(const Value: String; ValueMode: TFileNameMode): TFileOpenParametersBuiler;
    function SetFileId(const ValueLow: TFileId; const ValueHigh: UInt64): TFileOpenParametersBuiler;
    function SetAccess(const Value: TFileAccessMask): TFileOpenParametersBuiler;
    function SetRoot(const Value: IHandle): TFileOpenParametersBuiler;
    function SetHandleAttributes(const Value: TObjectAttributesFlags): TFileOpenParametersBuiler;
    function SetShareMode(const Value: TFileShareMode): TFileOpenParametersBuiler;
    function SetOpenOptions(const Value: TFileOpenOptions): TFileOpenParametersBuiler;
    function SetSyncMode(const Value: TFileSyncMode): TFileOpenParametersBuiler;
    function Duplicate: TFileOpenParametersBuiler;
    procedure UpdateNameBuffer;
  public
    function UseFileName(const Value: String; ValueMode: TFileNameMode): IFileOpenParameters;
    function UseFileId(const ValueLow: TFileId; const ValueHigh: UInt64): IFileOpenParameters;
    function UseAccess(const Value: TFileAccessMask): IFileOpenParameters;
    function UseRoot(const Value: IHandle): IFileOpenParameters;
    function UseHandleAttributes(const Value: TObjectAttributesFlags): IFileOpenParameters;
    function UseShareMode(const Value: TFileShareMode): IFileOpenParameters;
    function UseOpenOptions(const Value: TFileOpenOptions): IFileOpenParameters;
    function UseSyncMode(const Value: TFileSyncMode): IFileOpenParameters;

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
    property HasFileId: Boolean read GetHasFileId;

    constructor Create;
  end;

constructor TFileOpenParametersBuiler.Create;
begin
  inherited;
  FAccess := SYNCHRONIZE;
  FObjAttr.Length := SizeOf(FObjAttr);
  FObjAttr.Attributes := OBJ_CASE_INSENSITIVE;
  FObjAttr.ObjectName := @FNameStr;
  FOpenOptions := 0;
  FSyncMode := fsSynchronousNonAlert;
  FShareMode := FILE_SHARE_ALL;
end;

function TFileOpenParametersBuiler.Duplicate;
begin
  Result := TFileOpenParametersBuiler.Create
    .SetFileName(GetFileName, fnNative)
    .SetFileId(GetFileId, GetFileIdHigh)
    .SetAccess(GetAccess)
    .SetRoot(GetRoot)
    .SetHandleAttributes(GetHandleAttributes)
    .SetShareMode(GetShareMode)
    .SetOpenOptions(GetOpenOptions)
    .SetSyncMode(FSyncMode);
end;

function TFileOpenParametersBuiler.GetAccess;
begin
  Result := FAccess;
end;

function TFileOpenParametersBuiler.GetFileId;
begin
  Result := FFileId.Low;
end;

function TFileOpenParametersBuiler.GetFileIdHigh;
begin
  Result := FFileId.High;
end;

function TFileOpenParametersBuiler.GetFileName;
begin
  Result := FName;
end;

function TFileOpenParametersBuiler.GetHandleAttributes;
begin
  Result := FObjAttr.Attributes;
end;

function TFileOpenParametersBuiler.GetHasFileId;
begin
  Result := (FFileId.Low <> 0) or (FFileId.High <> 0);
end;

function TFileOpenParametersBuiler.GetObjectAttributes;
begin
  UpdateNameBuffer;
  Result := @FObjAttr;
end;

function TFileOpenParametersBuiler.GetOpenOptions;
begin
  Result := FOpenOptions;
end;

function TFileOpenParametersBuiler.GetRoot;
begin
  Result := FRoot;
end;

function TFileOpenParametersBuiler.GetShareMode;
begin
  Result := FShareMode;
end;

function TFileOpenParametersBuiler.GetSyncMode;
begin
  Result := FSyncMode;
end;

function TFileOpenParametersBuiler.SetAccess;
begin
  FAccess := Value;
  Result := Self;
end;

function TFileOpenParametersBuiler.SetFileId;
begin
  FFileId.Low := ValueLow;
  FFileId.High := ValueHigh;
  Result := Self;
end;

function TFileOpenParametersBuiler.SetFileName;
begin
  // Convert the filename to NT format as soon as possible becasuse Win32
  // filenames can be relative to the current directory that might change
  if ValueMode = fnWin32 then
    FName := RtlxDosPathToNativePath(Value)
  else
    FName := Value;

  Result := Self;
end;

function TFileOpenParametersBuiler.SetHandleAttributes;
begin
  FObjAttr.Attributes := Value;
  Result := Self;
end;

function TFileOpenParametersBuiler.SetOpenOptions;
begin
  FOpenOptions := Value;
  Result := Self;
end;

function TFileOpenParametersBuiler.SetRoot;
begin
  FRoot := Value;
  FObjAttr.RootDirectory := HandleOrDefault(FRoot);
  Result := Self;
end;

function TFileOpenParametersBuiler.SetShareMode;
begin
  FShareMode := Value;
  Result := Self;
end;

function TFileOpenParametersBuiler.SetSyncMode;
begin
  FSyncMode := Value;
  Result := Self;
end;

procedure TFileOpenParametersBuiler.UpdateNameBuffer;
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

    FNameBuffer := Auto.AllocateDynamic(
      Cardinal(Length(FName) * SizeOf(WideChar)) +
      IdSize
    );

    Move(PWideChar(FName)^, FNameBuffer.Data^, Length(FName) * SizeOf(WideChar));
    Move(FFileId, FNameBuffer.Offset(Length(FName) * SizeOf(WideChar))^, IdSize);

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

function TFileOpenParametersBuiler.UseAccess;
begin
  Result := Duplicate.SetAccess(Value);
end;

function TFileOpenParametersBuiler.UseFileId;
begin
  Result := Duplicate.SetFileId(ValueLow, ValueHigh);
end;

function TFileOpenParametersBuiler.UseFileName;
begin
  Result := Duplicate.SetFileName(Value, ValueMode);
end;

function TFileOpenParametersBuiler.UseHandleAttributes;
begin
  Result := Duplicate.SetHandleAttributes(Value);
end;

function TFileOpenParametersBuiler.UseOpenOptions;
begin
  Result := Duplicate.SetOpenOptions(Value);
end;

function TFileOpenParametersBuiler.UseRoot;
begin
  Result := Duplicate.SetRoot(Value);
end;

function TFileOpenParametersBuiler.UseShareMode;
begin
  Result := Duplicate.SetShareMode(Value);
end;

function TFileOpenParametersBuiler.UseSyncMode;
begin
  Result := Duplicate.SetSyncMode(Value);
end;

{ TFileCreateParametersBuiler }

type
  TFileCreateParametersBuiler = class (TInterfacedObject, IFileCreateParameters)
  protected
    FObjAttr: TObjectAttributes;
    FNameStr: TNtUnicodeString;
    FName: String;
    FAccess: TFileAccessMask;
    FRoot: IHandle;
    FSecurity: ISecurityDescriptor;
    FCreateOptions: TFileOpenOptions;
    FFileAttributes: TFileAttributes;
    FAllocationSize: UInt64;
    FDisposition: TFileDisposition;
    FShareMode: TFileShareMode;
    FSyncMode: TFileSyncMode;
    function SetFileName(const Value: String; ValueMode: TFileNameMode): TFileCreateParametersBuiler;
    function SetAccess(const Value: TFileAccessMask): TFileCreateParametersBuiler;
    function SetRoot(const Value: IHandle): TFileCreateParametersBuiler;
    function SetHandleAttributes(const Value: TObjectAttributesFlags): TFileCreateParametersBuiler;
    function SetSecurity(const Value: ISecurityDescriptor): TFileCreateParametersBuiler;
    function SetShareMode(const Value: TFileShareMode): TFileCreateParametersBuiler;
    function SetCreateOptions(const Value: TFileOpenOptions): TFileCreateParametersBuiler;
    function SetSyncMode(const Value: TFileSyncMode): TFileCreateParametersBuiler;
    function SetFileAttributes(const Value: TFileAttributes): TFileCreateParametersBuiler;
    function SetAllocationSize(const Value: UInt64): TFileCreateParametersBuiler;
    function SetDisposition(const Value: TFileDisposition): TFileCreateParametersBuiler;
    function Duplicate: TFileCreateParametersBuiler;
  public
    function UseFileName(const Value: String; ValueMode: TFileNameMode = fnNative): IFileCreateParameters;
    function UseAccess(const Value: TFileAccessMask): IFileCreateParameters;
    function UseRoot(const Value: IHandle): IFileCreateParameters;
    function UseHandleAttributes(const Value: TObjectAttributesFlags): IFileCreateParameters;
    function UseSecurity(const Value: ISecurityDescriptor): IFileCreateParameters;
    function UseShareMode(const Value: TFileShareMode): IFileCreateParameters;
    function UseCreateOptions(const Value: TFileOpenOptions): IFileCreateParameters;
    function UseSyncMode(const Value: TFileSyncMode): IFileCreateParameters;
    function UseFileAttributes(const Value: TFileAttributes): IFileCreateParameters;
    function UseAllocationSize(const Value: UInt64): IFileCreateParameters;
    function UseDisposition(const Value: TFileDisposition): IFileCreateParameters;

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

    constructor Create;
  end;

constructor TFileCreateParametersBuiler.Create;
begin
  inherited;
  FAccess := SYNCHRONIZE;
  FObjAttr.Length := SizeOf(FObjAttr);
  FObjAttr.Attributes := OBJ_CASE_INSENSITIVE;
  FObjAttr.ObjectName := @FNameStr;
  FCreateOptions := 0;
  FSyncMode := fsSynchronousNonAlert;
  FShareMode := FILE_SHARE_ALL;
  FFileAttributes := FILE_ATTRIBUTE_NORMAL;
  FDisposition := FILE_OPEN_IF;
end;

function TFileCreateParametersBuiler.Duplicate;
begin
  Result := TFileCreateParametersBuiler.Create
    .SetFileName(GetFileName, fnNative)
    .SetAccess(GetAccess)
    .SetRoot(GetRoot)
    .SetHandleAttributes(GetHandleAttributes)
    .SetSecurity(GetSecurity)
    .SetShareMode(GetShareMode)
    .SetCreateOptions(GetCreateOptions)
    .SetSyncMode(GetSyncMode)
    .SetFileAttributes(GetFileAttributes)
    .SetAllocationSize(GetAllocationSize)
    .SetDisposition(GetDisposition);
end;

function TFileCreateParametersBuiler.GetAccess;
begin
  Result := FAccess;
end;

function TFileCreateParametersBuiler.GetAllocationSize;
begin
  Result := FAllocationSize;
end;

function TFileCreateParametersBuiler.GetCreateOptions;
begin
  Result := FCreateOptions;
end;

function TFileCreateParametersBuiler.GetDisposition;
begin
  Result := FDisposition;
end;

function TFileCreateParametersBuiler.GetFileAttributes;
begin
  Result := FFileAttributes;
end;

function TFileCreateParametersBuiler.GetFileName;
begin
  Result := FName;
end;

function TFileCreateParametersBuiler.GetHandleAttributes;
begin
  Result := FObjAttr.Attributes;
end;

function TFileCreateParametersBuiler.GetObjectAttributes;
begin
  Result := @FObjAttr;
end;

function TFileCreateParametersBuiler.GetRoot;
begin
  Result := FRoot;
end;

function TFileCreateParametersBuiler.GetSecurity;
begin
  Result := FSecurity;
end;

function TFileCreateParametersBuiler.GetShareMode;
begin
  Result := FShareMode;
end;

function TFileCreateParametersBuiler.GetSyncMode;
begin
  Result := FSyncMode;
end;

function TFileCreateParametersBuiler.SetAccess;
begin
  FAccess := Value;
  Result := Self;
end;

function TFileCreateParametersBuiler.SetAllocationSize;
begin
  FAllocationSize := Value;
  Result := Self;
end;

function TFileCreateParametersBuiler.SetCreateOptions;
begin
  FCreateOptions := Value;
  Result := Self;
end;

function TFileCreateParametersBuiler.SetDisposition;
begin
  FDisposition := Value;
  Result := Self;
end;

function TFileCreateParametersBuiler.SetFileAttributes;
begin
  FFileAttributes := Value;
  Result := Self;
end;

function TFileCreateParametersBuiler.SetFileName;
begin
  // Convert the filename to NT format as soon as possible becasuse Win32
  // filenames can be relative to the current directory that might change
  if ValueMode = fnWin32 then
    FName := RtlxDosPathToNativePath(FName)
  else
    FName := Value;

  FNameStr := TNtUnicodeString.From(FName);
  Result := Self;
end;

function TFileCreateParametersBuiler.SetHandleAttributes;
begin
  FObjAttr.Attributes := Value;
  Result := Self;
end;

function TFileCreateParametersBuiler.SetRoot;
begin
  FRoot := Value;
  FObjAttr.RootDirectory := HandleOrDefault(FRoot);
  Result := Self;
end;

function TFileCreateParametersBuiler.SetSecurity;
begin
  FSecurity := Value;
  FObjAttr.SecurityDescriptor := Auto.RefOrNil<PSecurityDescriptor>(FSecurity);
  Result := Self;
end;

function TFileCreateParametersBuiler.SetShareMode;
begin
  FShareMode := Value;
  Result := Self;
end;

function TFileCreateParametersBuiler.SetSyncMode;
begin
  FSyncMode := Value;
  Result := Self;
end;

function TFileCreateParametersBuiler.UseAccess;
begin
  Result := Duplicate.SetAccess(Value)
end;

function TFileCreateParametersBuiler.UseAllocationSize;
begin
  Result := Duplicate.SetAllocationSize(Value);
end;

function TFileCreateParametersBuiler.UseCreateOptions;
begin
  Result := Duplicate.SetCreateOptions(Value);
end;

function TFileCreateParametersBuiler.UseDisposition;
begin
  Result := Duplicate.SetDisposition(Value);
end;

function TFileCreateParametersBuiler.UseFileAttributes;
begin
  Result := Duplicate.SetFileAttributes(Value);
end;

function TFileCreateParametersBuiler.UseFileName;
begin
  Result := Duplicate.SetFileName(Value, ValueMode);
end;

function TFileCreateParametersBuiler.UseHandleAttributes;
begin
  Result := Duplicate.SetHandleAttributes(Value);
end;

function TFileCreateParametersBuiler.UseRoot;
begin
  Result := Duplicate.SetRoot(Value);
end;

function TFileCreateParametersBuiler.UseSecurity;
begin
  Result := Duplicate.SetSecurity(Value);
end;

function TFileCreateParametersBuiler.UseShareMode;
begin
  Result := Duplicate.SetShareMode(Value);
end;

function TFileCreateParametersBuiler.UseSyncMode;
begin
  Result := Duplicate.SetSyncMode(Value);
end;

{ Builder Functions }

function FileOpenParameters;
begin
  if Assigned(Template) then
    Result := Template
  else
    Result := TFileOpenParametersBuiler.Create;
end;

function FileCreateParameters;
begin
  if Assigned(Template) then
    Result := Template
  else
    Result := TFileCreateParametersBuiler.Create;
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
  OpenOptions := Parameters.OpenOptions and not FILE_SYNCHRONOUS_FLAGS;

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

  if BitTest(Parameters.OpenOptions and FILE_NON_DIRECTORY_FILE) then
    Result.LastCall.OpensForAccess<TIoFileAccessMask>(Access)
  else if BitTest(Parameters.OpenOptions and FILE_DIRECTORY_FILE) then
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
  CreateOptions := Parameters.CreateOptions and not FILE_SYNCHRONOUS_FLAGS;
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

  if BitTest(Parameters.CreateOptions and FILE_NON_DIRECTORY_FILE) then
    Result.LastCall.OpensForAccess<TIoFileAccessMask>(Access)
  else if BitTest(Parameters.CreateOptions and FILE_DIRECTORY_FILE) then
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

  if Result.IsSuccess then
  begin
    hxFile := Auto.CaptureHandle(hFile);

    if Assigned(ActionTaken) then
      ActionTaken^ := TFileIoStatusResult(IoStatusBlock.Information);
  end;
end;

function NtxOpenNamedPipe;
var
  hPipe: THandle;
  Access: TIoPipeAccessMask;
  OpenOptions: TFileOpenOptions;
  Timeout: TLargeInteger;
  IoStatusBlock: TIoStatusBlock;
begin
  Timeout := -1;
  Access := Parameters.Access;
  OpenOptions := Parameters.OpenOptions and not FILE_SYNCHRONOUS_FLAGS;

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
    FILE_OPEN,
    OpenOptions,
    FILE_PIPE_BYTE_STREAM_TYPE,
    FILE_PIPE_BYTE_STREAM_MODE,
    FILE_PIPE_COMPLETE_OPERATION,
    $FFFFFFFF,
    0,
    0,
    @Timeout
  );

  if Result.IsSuccess then
    hxPipe := Auto.CaptureHandle(hPipe);
end;

end.
