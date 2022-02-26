unit NtUtils.Files.Open;

{
  This modules provides interfaces and functions for opening and creating files.
}

interface

uses
  Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntseapi, NtUtils, NtUtils.Files,
  DelphiApi.Reflection;

{ Parameters Builder }

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

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, NtUtils.Objects;

{ TFileOpenParametersBuiler }

type
  TFileOpenParametersBuiler = class (TInterfacedObject, IFileOpenParameters)
  protected
    FObjAttr: TObjectAttributes;
    FNameStr: TNtUnicodeString;
    FName: String;
    FFileId: TFileId;
    FAccess: TFileAccessMask;
    FRoot: IHandle;
    FOpenOptions: TFileOpenOptions;
    FShareMode: TFileShareMode;
    function SetFileName(const Value: String; ValueMode: TFileNameMode): TFileOpenParametersBuiler;
    function SetFileId(const Value: TFileId): TFileOpenParametersBuiler;
    function SetAccess(const Value: TFileAccessMask): TFileOpenParametersBuiler;
    function SetRoot(const Value: IHandle): TFileOpenParametersBuiler;
    function SetHandleAttributes(const Value: TObjectAttributesFlags): TFileOpenParametersBuiler;
    function SetShareMode(const Value: TFileShareMode): TFileOpenParametersBuiler;
    function SetOpenOptions(const Value: TFileOpenOptions): TFileOpenParametersBuiler;
    function Duplicate: TFileOpenParametersBuiler;
  public
    function UseFileName(const Value: String; ValueMode: TFileNameMode): IFileOpenParameters;
    function UseFileId(const Value: TFileId): IFileOpenParameters;
    function UseAccess(const Value: TFileAccessMask): IFileOpenParameters;
    function UseRoot(const Value: IHandle): IFileOpenParameters;
    function UseHandleAttributes(const Value: TObjectAttributesFlags): IFileOpenParameters;
    function UseShareMode(const Value: TFileShareMode): IFileOpenParameters;
    function UseOpenOptions(const Value: TFileOpenOptions): IFileOpenParameters;

    function GetFileName: String;
    function GetFileId: TFileId;
    function GetAccess: TFileAccessMask;
    function GetRoot: IHandle;
    function GetHandleAttributes: TObjectAttributesFlags;
    function GetShareMode: TFileShareMode;
    function GetOpenOptions: TFileOpenOptions;
    function GetObjectAttributes: PObjectAttributes;

    constructor Create;
  end;

constructor TFileOpenParametersBuiler.Create;
begin
  inherited;
  FAccess := SYNCHRONIZE;
  FObjAttr.Length := SizeOf(FObjAttr);
  FObjAttr.Attributes := OBJ_CASE_INSENSITIVE;
  FObjAttr.ObjectName := @FNameStr;
  FOpenOptions := FILE_SYNCHRONOUS_IO_NONALERT;
  FShareMode := FILE_SHARE_ALL;
end;

function TFileOpenParametersBuiler.Duplicate;
begin
  Result := TFileOpenParametersBuiler.Create
    .SetFileName(GetFileName, fnNative)
    .SetFileId(GetFileId)
    .SetAccess(GetAccess)
    .SetRoot(GetRoot)
    .SetHandleAttributes(GetHandleAttributes)
    .SetShareMode(GetShareMode)
    .SetOpenOptions(GetOpenOptions and not FILE_OPEN_BY_FILE_ID);
end;

function TFileOpenParametersBuiler.GetAccess;
begin
  Result := FAccess;
end;

function TFileOpenParametersBuiler.GetFileId;
begin
  Result := FFileId;
end;

function TFileOpenParametersBuiler.GetFileName;
begin
  Result := FName;
end;

function TFileOpenParametersBuiler.GetHandleAttributes;
begin
  Result := FObjAttr.Attributes;
end;

function TFileOpenParametersBuiler.GetObjectAttributes;
begin
  Result := @FObjAttr;
end;

function TFileOpenParametersBuiler.GetOpenOptions;
begin
  Result := FOpenOptions;

  if FFileId <> 0 then
    Result := Result or FILE_OPEN_BY_FILE_ID;
end;

function TFileOpenParametersBuiler.GetRoot;
begin
  Result := FRoot;
end;

function TFileOpenParametersBuiler.GetShareMode;
begin
  Result := FShareMode;
end;

function TFileOpenParametersBuiler.SetAccess;
begin
  // Synchronious I/O doesn't work without the SYNCHRONIZE right;
  // asynchronious handles are useless without ability to wait for completion
  FAccess := Value or SYNCHRONIZE;
  Result := Self;
end;

function TFileOpenParametersBuiler.SetFileId;
begin
  FFileId := Value;

  if FFileId <> 0 then
  begin
    // Put the raw File ID data into the ObjectName field of object attributes
    FNameStr.Length := SizeOf(FFileId);
    FNameStr.MaximumLength := SizeOf(FFileId);
    FNameStr.Buffer := Pointer(@FFileId);

    // Clear the string name to avoid confusion
    FName := '';
  end;

  Result := Self;
end;

function TFileOpenParametersBuiler.SetFileName;
begin
  FName := Value;

  // Convert the filename to NT format as soon as possible becasuse Win32
  // filenames can be relative to the current directory that might change
  if ValueMode <> fnNative then
    FName := RtlxDosPathToNativePath(FName);

  if FName <> '' then
  begin
    FNameStr := TNtUnicodeString.From(FName);

    // Clear the file ID so we won't include the corresponding flag
    FFileId := 0;
  end;

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

function TFileOpenParametersBuiler.UseAccess;
begin
  Result := Duplicate.SetAccess(Value);
end;

function TFileOpenParametersBuiler.UseFileId;
begin
  Result := Duplicate.SetFileId(Value);
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
    function SetFileName(const Value: String; ValueMode: TFileNameMode): TFileCreateParametersBuiler;
    function SetAccess(const Value: TFileAccessMask): TFileCreateParametersBuiler;
    function SetRoot(const Value: IHandle): TFileCreateParametersBuiler;
    function SetHandleAttributes(const Value: TObjectAttributesFlags): TFileCreateParametersBuiler;
    function SetSecurity(const Value: ISecurityDescriptor): TFileCreateParametersBuiler;
    function SetShareMode(const Value: TFileShareMode): TFileCreateParametersBuiler;
    function SetCreateOptions(const Value: TFileOpenOptions): TFileCreateParametersBuiler;
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
  FCreateOptions := FILE_SYNCHRONOUS_IO_NONALERT;
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

function TFileCreateParametersBuiler.SetAccess;
begin
  // Synchronious I/O doesn't work without the SYNCHRONIZE right;
  // asynchronious handles are useless without ability to wait for completion
  FAccess := Value or SYNCHRONIZE;
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
  FName := Value;

  // Convert the filename to NT format as soon as possible becasuse Win32
  // filenames can be relative to the current directory that might change
  if ValueMode <> fnNative then
    FName := RtlxDosPathToNativePath(FName);

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
begin
  Result.Location := 'NtOpenFile';
  Result.LastCall.OpensForAccess(Parameters.Access);

  Result.Status := NtOpenFile(
    hFile,
    Parameters.Access,
    Parameters.ObjectAttributes^,
    IoStatusBlock,
    Parameters.ShareMode,
    Parameters.OpenOptions
  );

  if Result.IsSuccess then
    hxFile := NtxObject.Capture(hFile);
end;

function NtxCreateFile;
var
  hFile: THandle;
  IoStatusBlock: TIoStatusBlock;
  AllocationSize: UInt64;
begin
  Result.Location := 'NtCreateFile';
  Result.LastCall.OpensForAccess(Parameters.Access);
  AllocationSize := Parameters.AllocationSize;

  Result.Status := NtCreateFile(
    hFile,
    Parameters.Access,
    Parameters.ObjectAttributes^,
    IoStatusBlock,
    @AllocationSize,
    Parameters.FileAttributes,
    Parameters.ShareMode,
    Parameters.Disposition,
    Parameters.CreateOptions,
    nil,
    0
  );

  if Result.IsSuccess then
  begin
    hxFile := NtxObject.Capture(hFile);

    if Assigned(ActionTaken) then
      ActionTaken^ := TFileIoStatusResult(IoStatusBlock.Information);
  end;
end;

end.
