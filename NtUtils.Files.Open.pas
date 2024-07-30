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
  Ntapi.WinNt, Ntapi.ntstatus, NtUtils.Objects, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TFileParametersBuilder }

type
  TFileParametersBuilder = class (TInterfacedObject, IFileParameters)
  protected
    FObjAttr: TObjectAttributes;
    FNameStr: TNtUnicodeString;
    FQoS: TSecurityQualityOfService;
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
    FEA: TArray<TNtxExtendedAttribute>;
    FTimeout: Int64;
    FPipeType: TFilePipeType;
    FPipeReadMode: TFilePipeReadMode;
    FPipeCompletion: TFilePipeCompletion;
    FPipeMaximumInstances: Cardinal;
    FMailslotMaximumMessageSize: Cardinal;
    FPipeInboundQuota, FPipeOutboundQuota, FMailslotQuota: Cardinal;
    function SetFileName(const Value: String; ValueMode: TFileNameMode): TFileParametersBuilder;
    function SetFileId(const ValueLow: TFileId; const ValueHigh: UInt64): TFileParametersBuilder;
    function SetAccess(const Value: TFileAccessMask): TFileParametersBuilder;
    function SetRoot(const Value: IHandle): TFileParametersBuilder;
    function SetHandleAttributes(const Value: TObjectAttributesFlags): TFileParametersBuilder;
    function SetImpersonation(const Value: TSecurityImpersonationLevel): TFileParametersBuilder;
    function SetEffectiveOnly(const Value: Boolean): TFileParametersBuilder;
    function SetContextTracking(const Value: Boolean): TFileParametersBuilder;
    function SetSecurity(const Value: ISecurityDescriptor): TFileParametersBuilder;
    function SetShareMode(const Value: TFileShareMode): TFileParametersBuilder;
    function SetOptions(const Value: TFileOpenOptions): TFileParametersBuilder;
    function SetSyncMode(const Value: TFileSyncMode): TFileParametersBuilder;
    function SetFileAttributes(const Value: TFileAttributes): TFileParametersBuilder;
    function SetAllocationSize(const Value: UInt64): TFileParametersBuilder;
    function SetDisposition(const Value: TFileDisposition): TFileParametersBuilder;
    function SetEA(const Value: TArray<TNtxExtendedAttribute>): TFileParametersBuilder;
    function SetTimeout(const Value: Int64): TFileParametersBuilder;
    function SetPipeType(const Value: TFilePipeType): TFileParametersBuilder;
    function SetPipeReadMode(const Value: TFilePipeReadMode): TFileParametersBuilder;
    function SetPipeCompletion(const Value: TFilePipeCompletion): TFileParametersBuilder;
    function SetPipeMaximumInstances(const Value: Cardinal): TFileParametersBuilder;
    function SetPipeInboundQuota(const Value: Cardinal): TFileParametersBuilder;
    function SetPipeOutboundQuota(const Value: Cardinal): TFileParametersBuilder;
    function SetMailslotQuota(const Value: Cardinal): TFileParametersBuilder;
    function SetMailslotMaximumMessageSize(const Value: Cardinal): TFileParametersBuilder;
    function Duplicate: TFileParametersBuilder;
  public
    function UseFileName(const Value: String; ValueMode: TFileNameMode): IFileParameters;
    function UseFileId(const ValueLow: TFileId; const ValueHigh: UInt64): IFileParameters;
    function UseAccess(const Value: TFileAccessMask): IFileParameters;
    function UseRoot(const Value: IHandle): IFileParameters;
    function UseHandleAttributes(const Value: TObjectAttributesFlags): IFileParameters;
    function UseImpersonation(const Value: TSecurityImpersonationLevel): IFileParameters;
    function UseEffectiveOnly(const Value: Boolean): IFileParameters;
    function UseContextTracking(const Value: Boolean): IFileParameters;
    function UseSecurity(const Value: ISecurityDescriptor): IFileParameters;
    function UseShareMode(const Value: TFileShareMode): IFileParameters;
    function UseOptions(const Value: TFileOpenOptions): IFileParameters;
    function UseSyncMode(const Value: TFileSyncMode): IFileParameters;
    function UseFileAttributes(const Value: TFileAttributes): IFileParameters;
    function UseAllocationSize(const Value: UInt64): IFileParameters;
    function UseDisposition(const Value: TFileDisposition): IFileParameters;
    function UseEA(const Value: TArray<TNtxExtendedAttribute>): IFileParameters;
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
    property HasFileId: Boolean read GetHasFileId;

    function BuildObjectAttributes(out Reference: PObjectAttributes): TNtxStatus;
    constructor Create;
  end;

function TFileParametersBuilder.BuildObjectAttributes;
var
  IdSize: Word;
  BufferSize: NativeUInt;
begin
  FNameBuffer := nil;

  // A mixed (name + ID) buffer
  if (FName <> '') and HasFileId then
  begin
    if FFileId.High = 0 then
      IdSize := SizeOf(TFileId)
    else
      IdSize := SizeOf(TFileId128);

    BufferSize := StringSizeNoZero(FName) + IdSize;

    if BufferSize > MAX_UNICODE_STRING then
    begin
      Result.Location := 'IFileParameters::BuildObjectAttributes';
      Result.Status := STATUS_NAME_TOO_LONG;
      Exit;
    end;

    // Concatenate the string without null terminator with the binary ID
    FNameBuffer := Auto.AllocateDynamic(BufferSize);
    Move(PWideChar(FName)^, FNameBuffer.Data^, StringSizeNoZero(FName));
    Move(FFileId, FNameBuffer.Offset(StringSizeNoZero(FName))^, IdSize);

    FNameStr.Length := BufferSize;
    FNameStr.MaximumLength := BufferSize;
    FNameStr.Buffer := FNameBuffer.Data;
  end

  // A binary (ID) buffer
  else if HasFileId then
  begin
    if FFileId.High = 0 then
      IdSize := SizeOf(TFileId)
    else
      IdSize := SizeOf(TFileId128);

    FNameStr.Length := IdSize;
    FNameStr.MaximumLength := IdSize;
    FNameStr.Buffer := Pointer(@FFileId);
  end

  // Plain text (name) buffer
  else
  begin
    Result := RtlxInitUnicodeString(FNameStr, FName);

    if not Result.IsSuccess then
      Exit;
  end;

  // Complete
  Reference := @FObjAttr;
  Result := NtxSuccess;
end;

constructor TFileParametersBuilder.Create;
begin
  inherited;
  FAccess := SYNCHRONIZE;
  FQoS.Length := SizeOf(FQoS);
  FQoS.ImpersonationLevel := SecurityImpersonation;
  FObjAttr.Length := SizeOf(FObjAttr);
  FObjAttr.Attributes := OBJ_CASE_INSENSITIVE;
  FObjAttr.SecurityQualityOfService := @FQos;
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

function TFileParametersBuilder.Duplicate;
begin
  Result := TFileParametersBuilder.Create
    .SetFileName(GetFileName, fnNative)
    .SetFileId(GetFileId, GetFileIdHigh)
    .SetAccess(GetAccess)
    .SetRoot(GetRoot)
    .SetHandleAttributes(GetHandleAttributes)
    .SetImpersonation(GetImpersonation)
    .SetEffectiveOnly(GetEffectiveOnly)
    .SetContextTracking(GetContextTracking)
    .SetSecurity(GetSecurity)
    .SetShareMode(GetShareMode)
    .SetOptions(GetOptions)
    .SetSyncMode(FSyncMode)
    .SetFileAttributes(GetFileAttributes)
    .SetAllocationSize(GetAllocationSize)
    .SetDisposition(GetDisposition)
    .SetEA(GetEA)
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

function TFileParametersBuilder.GetAccess;
begin
  Result := FAccess;
end;

function TFileParametersBuilder.GetAllocationSize;
begin
  Result := FAllocationSize;
end;

function TFileParametersBuilder.GetContextTracking;
begin
  Result := FQoS.ContextTrackingMode;
end;

function TFileParametersBuilder.GetDisposition;
begin
  Result := FDisposition;
end;

function TFileParametersBuilder.GetEA;
begin
  Result := FEA;
end;

function TFileParametersBuilder.GetEffectiveOnly;
begin
  Result := FQoS.EffectiveOnly;
end;

function TFileParametersBuilder.GetFileAttributes;
begin
  Result := FFileAttributes;
end;

function TFileParametersBuilder.GetFileId;
begin
  Result := FFileId.Low;
end;

function TFileParametersBuilder.GetFileIdHigh;
begin
  Result := FFileId.High;
end;

function TFileParametersBuilder.GetFileName;
begin
  Result := FName;
end;

function TFileParametersBuilder.GetHandleAttributes;
begin
  Result := FObjAttr.Attributes;
end;

function TFileParametersBuilder.GetHasFileId;
begin
  Result := (FFileId.Low <> 0) or (FFileId.High <> 0);
end;

function TFileParametersBuilder.GetImpersonation;
begin
  Result := FQoS.ImpersonationLevel;
end;

function TFileParametersBuilder.GetMailslotMaximumMessageSize;
begin
  Result := FMailslotMaximumMessageSize;
end;

function TFileParametersBuilder.GetMailslotQuota;
begin
  Result := FMailslotQuota;
end;

function TFileParametersBuilder.GetOptions;
begin
  Result := FCreateOpenOptions;
end;

function TFileParametersBuilder.GetPipeCompletion;
begin
  Result := FPipeCompletion;
end;

function TFileParametersBuilder.GetPipeInboundQuota;
begin
  Result := FPipeInboundQuota;
end;

function TFileParametersBuilder.GetPipeMaximumInstances;
begin
  Result := FPipeMaximumInstances;
end;

function TFileParametersBuilder.GetPipeOutboundQuota;
begin
  Result := FPipeOutboundQuota;
end;

function TFileParametersBuilder.GetPipeReadMode;
begin
  Result := FPipeReadMode;
end;

function TFileParametersBuilder.GetPipeType;
begin
  Result := FPipeType;
end;

function TFileParametersBuilder.GetRoot;
begin
  Result := FRoot;
end;

function TFileParametersBuilder.GetSecurity;
begin
  Result := FSecurity;
end;

function TFileParametersBuilder.GetShareMode;
begin
  Result := FShareMode;
end;

function TFileParametersBuilder.GetSyncMode;
begin
  Result := FSyncMode;
end;

function TFileParametersBuilder.GetTimeout;
begin
  Result := FTimeout;
end;

function TFileParametersBuilder.SetAccess;
begin
  FAccess := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetAllocationSize;
begin
  FAllocationSize := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetContextTracking;
begin
  FQoS.ContextTrackingMode := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetDisposition;
begin
  FDisposition := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetEA;
begin
  FEA := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetEffectiveOnly;
begin
  FQoS.EffectiveOnly := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetFileAttributes;
begin
  FFileAttributes := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetFileId;
begin
  FFileId.Low := ValueLow;
  FFileId.High := ValueHigh;
  Result := Self;
end;

function TFileParametersBuilder.SetFileName;
begin
  // Convert the filename to NT format as soon as possible because Win32
  // filenames can be relative to the current directory that might change
  if ValueMode = fnWin32 then
    FName := RtlxDosPathToNativePath(Value)
  else
    FName := Value;

  Result := Self;
end;

function TFileParametersBuilder.SetHandleAttributes;
begin
  FObjAttr.Attributes := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetImpersonation;
begin
  FQoS.ImpersonationLevel := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetMailslotMaximumMessageSize;
begin
  FMailslotMaximumMessageSize := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetMailslotQuota;
begin
  FMailslotQuota := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetOptions;
begin
  FCreateOpenOptions := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetPipeCompletion;
begin
  FPipeCompletion := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetPipeInboundQuota;
begin
  FPipeInboundQuota := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetPipeMaximumInstances;
begin
  FPipeMaximumInstances := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetPipeOutboundQuota;
begin
  FPipeOutboundQuota := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetPipeReadMode;
begin
  FPipeReadMode := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetPipeType;
begin
  FPipeType := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetRoot;
begin
  FRoot := Value;
  FObjAttr.RootDirectory := HandleOrDefault(FRoot);
  Result := Self;
end;

function TFileParametersBuilder.SetSecurity;
begin
  FSecurity := Value;
  FObjAttr.SecurityDescriptor := Auto.RefOrNil<PSecurityDescriptor>(FSecurity);
  Result := Self;
end;

function TFileParametersBuilder.SetShareMode;
begin
  FShareMode := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetSyncMode;
begin
  FSyncMode := Value;
  Result := Self;
end;

function TFileParametersBuilder.SetTimeout;
begin
  FTimeout := Value;
  Result := Self;
end;

function TFileParametersBuilder.UseAccess;
begin
  Result := Duplicate.SetAccess(Value);
end;

function TFileParametersBuilder.UseAllocationSize;
begin
  Result := Duplicate.SetAllocationSize(Value);
end;

function TFileParametersBuilder.UseContextTracking;
begin
  Result := Duplicate.SetContextTracking(Value);
end;

function TFileParametersBuilder.UseDisposition;
begin
  Result := Duplicate.SetDisposition(Value);
end;

function TFileParametersBuilder.UseEA;
begin
  Result := Duplicate.SetEA(Value);
end;

function TFileParametersBuilder.UseEffectiveOnly;
begin
  Result := Duplicate.SetEffectiveOnly(Value);
end;

function TFileParametersBuilder.UseFileAttributes;
begin
  Result := Duplicate.SetFileAttributes(Value);
end;

function TFileParametersBuilder.UseFileId;
begin
  Result := Duplicate.SetFileId(ValueLow, ValueHigh);
end;

function TFileParametersBuilder.UseFileName;
begin
  Result := Duplicate.SetFileName(Value, ValueMode);
end;

function TFileParametersBuilder.UseHandleAttributes;
begin
  Result := Duplicate.SetHandleAttributes(Value);
end;

function TFileParametersBuilder.UseImpersonation;
begin
  Result := Duplicate.SetImpersonation(Value);
end;

function TFileParametersBuilder.UseMailslotMaximumMessageSize;
begin
  Result := Duplicate.SetMailslotMaximumMessageSize(Value);
end;

function TFileParametersBuilder.UseMailslotQuota;
begin
  Result := Duplicate.SetMailslotQuota(Value);
end;

function TFileParametersBuilder.UseOptions;
begin
  Result := Duplicate.SetOptions(Value);
end;

function TFileParametersBuilder.UsePipeCompletion;
begin
  Result := Duplicate.SetPipeCompletion(Value);
end;

function TFileParametersBuilder.UsePipeInboundQuota;
begin
  Result := Duplicate.SetPipeInboundQuota(Value);
end;

function TFileParametersBuilder.UsePipeMaximumInstances;
begin
  Result := Duplicate.SetPipeMaximumInstances(Value);
end;

function TFileParametersBuilder.UsePipeOutboundQuota;
begin
  Result := Duplicate.SetPipeOutboundQuota(Value);
end;

function TFileParametersBuilder.UsePipeReadMode;
begin
  Result := Duplicate.SetPipeReadMode(Value);
end;

function TFileParametersBuilder.UsePipeType;
begin
  Result := Duplicate.SetPipeType(Value);
end;

function TFileParametersBuilder.UseRoot;
begin
  Result := Duplicate.SetRoot(Value);
end;

function TFileParametersBuilder.UseSecurity;
begin
  Result := Duplicate.SetSecurity(Value);
end;

function TFileParametersBuilder.UseShareMode;
begin
  Result := Duplicate.SetShareMode(Value);
end;

function TFileParametersBuilder.UseSyncMode;
begin
  Result := Duplicate.SetSyncMode(Value);
end;

function TFileParametersBuilder.UseTimeout;
begin
  Result := Duplicate.SetTimeout(Value);
end;

{ Builder Functions }

function FileParameters;
begin
  if Assigned(Template) then
    Result := Template
  else
    Result := TFileParametersBuilder.Create;
end;

{ I/O Operations }

function NtxOpenFile;
var
  hFile: THandle;
  IoStatusBlock: TIoStatusBlock;
  ObjAttr: PObjectAttributes;
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

  Result := Parameters.BuildObjectAttributes(ObjAttr);

  if not Result.IsSuccess then
    Exit;

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
    ObjAttr^,
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
  ObjAttr: PObjectAttributes;
  Access: TFileAccessMask;
  CreateOptions: TFileOpenOptions;
  AllocationSize: UInt64;
  EAs: IMemory<PFileFullEaInformation>;
begin
  Access := Parameters.Access;
  CreateOptions := Parameters.Options and not FILE_SYNCHRONOUS_FLAGS;
  AllocationSize := Parameters.AllocationSize;
  EAs := RtlxAllocateEAs(Parameters.EA);

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

  Result := Parameters.BuildObjectAttributes(ObjAttr);

  if not Result.IsSuccess then
    Exit;

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
    ObjAttr^,
    IoStatusBlock,
    @AllocationSize,
    Parameters.FileAttributes,
    Parameters.ShareMode,
    Parameters.Disposition,
    CreateOptions,
    Auto.RefOrNil(IMemory(EAs)),
    Auto.SizeOrZero(IMemory(EAs))
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
  ObjAttr: PObjectAttributes;
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

  Result := Parameters.BuildObjectAttributes(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateNamedPipeFile';
  Result.LastCall.OpensForAccess(Access);

  Result.Status := NtCreateNamedPipeFile(
    hPipe,
    Access,
    ObjAttr^,
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
  ObjAttr: PObjectAttributes;
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

  Result := Parameters.BuildObjectAttributes(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateMailslotFile';
  Result.LastCall.OpensForAccess(Access);
  Result.Status := NtCreateMailslotFile(
    hMailslot,
    Access,
    ObjAttr^,
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
