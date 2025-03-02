unit NtUtils.Packages.ExecAlias;

{
  This module provides functions for working with app execution aliases.
}

interface

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

uses
  Ntapi.WinNt, Ntapi.appmodel.ExecAlias, Ntapi.ntseapi, Ntapi.ntioapi, Ntapi.ObjBase,
  Ntapi.Versions, NtUtils, DelphiUtils.AutoObjects;

type
  IExecAliasInfo = IAutoPointer<PAppExecutionAliasInfo>;
  IExecAliasData = IAutoPointer<PAppExecAliasData>;

// Ask AppInfo to parse an execution alias and derive a token for it
[MinOSVersion(OsWin10RS3)]
function AdvxLoadExecutionAliasInfo(
  out Info: IExecAliasInfo;
  const ApplicationPath: String;
  [opt, Access(TOKEN_LOAD_ALIAS)] const hxIncomingToken: IHandle = nil
): TNtxStatus;

// Generate a token for an execution alias
[MinOSVersion(OsWin10RS3)]
function AdvxLoadExecutionAliasToken(
  out hxToken: IHandle;
  const ApplicationPath: String;
  [opt, Access(TOKEN_LOAD_ALIAS)] const hxIncomingToken: IHandle = nil
): TNtxStatus;

// Open and parse an execution alias
[MinOSVersion(OsWin10RS3)]
function AdvxOpenExecutionAlias(
  out hxExecAlias: IExecAliasData;
  const Path: String;
  [opt, Access(TOKEN_QUERY)] const hxToken: IHandle = nil
): TNtxStatus;

// Prepare a new execution alias
[MinOSVersion(OsWin10RS4)]
function AdvxCreateExecutionAlias(
  out hxExecAlias: IExecAliasData;
  const ApplicationUserModelId: String;
  const PackageRelativeExecutable: String;
  AliasType: TAppExecutionAliasType;
  [opt] PackageFamilyName: String = ''
): TNtxStatus;

// Save an execution alias to an existing file by name
[MinOSVersion(OsWin10RS3)]
function AdvxPersistExecutionAliasByName(
  const hxExecAlias: IExecAliasData;
  const Path: String
): TNtxStatus;

// Save an execution alias to a file by handle
[MinOSVersion(OsWin1019H2)]
function AdvxPersistExecutionAliasByHandle(
  const hxExecAlias: IExecAliasData;
  [Access(FILE_WRITE_DATA or FILE_WRITE_ATTRIBUTES)] const hxFile: IHandle
): TNtxStatus;

// Save an execution alias to a new/existing file
[MinOSVersion(OsWin10RS3)]
function AdvxPersistExecutionAlias(
  const hxExecAlias: IExecAliasData;
  const Path: String
): TNtxStatus;

// Query the target executable for an execution alias
[MinOSVersion(OsWin10RS3)]
function AdvxQueryExecutionAliasExecutable(
  const hxExecAlias: IExecAliasData;
  out Executable: String
): TNtxStatus;

// Query the target app user model ID for an execution alias
[MinOSVersion(OsWin10RS3)]
function AdvxQueryExecutionAliasAumid(
  const hxExecAlias: IExecAliasData;
  out Aumid: String
): TNtxStatus;

// Query the target full package name for an execution alias
[RequiresCOM]
[MinOSVersion(OsWin10RS3)]
function AdvxQueryExecutionAliasFullPackageName(
  const hxExecAlias: IExecAliasData;
  out PackageFullName: String
): TNtxStatus;

// Query the target package family name for an execution alias
[MinOSVersion(OsWin10RS3)]
function AdvxQueryExecutionAliasFamilyPackageName(
  const hxExecAlias: IExecAliasData;
  out PackageFamilyName: String
): TNtxStatus;

// Query the application type for an execution alias
[MinOSVersion(OsWin10RS4)]
function AdvxQueryExecutionAliasType(
  const hxExecAlias: IExecAliasData;
  out AliasType: TAppExecutionAliasType
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, NtUtils.Ldr, NtUtils.SysUtils, NtUtils.Objects,
  NtUtils.Packages, NtUtils.Files.Open, NtUtils.Files.Operations;

{ Execution aliases }

type
  TAppExecAliasAutoInfo = class (TCustomAutoPointer, IAutoPointer,
    IAutoReleasable)
    procedure Release; override;
  end;

  TAppExecAliasAutoData = class (TCustomAutoPointer, IAutoPointer,
    IAutoReleasable)
    procedure Release; override;
  end;

procedure TAppExecAliasAutoInfo.Release;
begin
  if Assigned(FData) and LdrxCheckDelayedImport(
    delayed_FreeAppExecutionAliasInfoEx).IsSuccess then
    FreeAppExecutionAliasInfoEx(FData);

  FData := nil;
  inherited;
end;

procedure TAppExecAliasAutoData.Release;
begin
  if Assigned(FData) and LdrxCheckDelayedImport(
    delayed_CloseAppExecutionAliasEx).IsSuccess then
    CloseAppExecutionAliasEx(FData);

  FData := nil;
  inherited;
end;

function AdvxLoadExecutionAliasInfo;
var
  hInfo: PAppExecutionAliasInfo;
begin
  Result := LdrxCheckDelayedImport(delayed_LoadAppExecutionAliasInfoEx);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LoadAppExecutionAliasInfoEx';

  if Assigned(hxIncomingToken) then
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_LOAD_ALIAS);

  Result.Status := LoadAppExecutionAliasInfoEx(PWideChar(ApplicationPath),
    HandleOrDefault(hxIncomingToken), hInfo);

  if Result.IsSuccess then
    IAutoPointer(Info) := TAppExecAliasAutoInfo.Capture(hInfo);
end;

function AdvxLoadExecutionAliasToken;
var
  Info: IExecAliasInfo;
begin
  Result := AdvxLoadExecutionAliasInfo(Info, ApplicationPath, hxIncomingToken);

  if not Result.IsSuccess then
    Exit;

  if Info.Data.ActivationToken = 0 then
  begin
    Result.Location := 'AdvxLoadExecutionAliasToken';
    Result.Status := STATUS_NO_TOKEN;
    Exit;
  end;

  // Reopen the handle since the returned one will be closed with the info
  Result := NtxDuplicateHandleLocal(Info.Data.ActivationToken, hxToken, 0, 0,
    DUPLICATE_SAME_ACCESS or DUPLICATE_SAME_ATTRIBUTES);
end;

function AdvxOpenExecutionAlias;
var
  hExecAlias: PAppExecAliasData;
begin
  Result := LdrxCheckDelayedImport(delayed_OpenAppExecutionAliasForUserEx);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OpenAppExecutionAliasForUserEx';

  if Assigned(hxToken) then
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);

  Result.HResult := OpenAppExecutionAliasForUserEx(PWideChar(Path),
    HandleOrDefault(hxToken), hExecAlias);

  if Result.IsSuccess then
    IAutoPointer(hxExecAlias) := TAppExecAliasAutoData.Capture(hExecAlias);
end;

function AdvxCreateExecutionAlias;
var
  hExecAlias: PAppExecAliasData;
  RelativeAppId: String;
begin
  Result := LdrxCheckDelayedImport(delayed_CreateAppExecutionAliasEx2);

  if not Result.IsSuccess then
    Exit;

  if PackageFamilyName = '' then
  begin
    // Derive the family name from Aumid
    Result := PkgxDeriveFamilyNameFromAppUserModelId(ApplicationUserModelId,
      PackageFamilyName, RelativeAppId);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'CreateAppExecutionAliasEx2';
  Result.HResult := CreateAppExecutionAliasEx2(PWideChar(PackageFamilyName),
    PWideChar(ApplicationUserModelId), PWideChar(PackageRelativeExecutable),
    AliasType, hExecAlias);

  if Result.IsSuccess then
    IAutoPointer(hxExecAlias) := TAppExecAliasAutoData.Capture(hExecAlias);
end;

function AdvxPersistExecutionAliasByName;
begin
  Result := LdrxCheckDelayedImport(delayed_PersistAppExecutionAliasToFileEx);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'PersistAppExecutionAliasToFileEx';
  Result.HResult := PersistAppExecutionAliasToFileEx(
    Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), PWideChar(Path));
end;

function AdvxPersistExecutionAliasByHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_PersistAppExecutionAliasToFileHandleEx);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'PersistAppExecutionAliasToFileHandleEx';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA or
    FILE_WRITE_ATTRIBUTES);
  Result.HResult := PersistAppExecutionAliasToFileHandleEx(
    Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), HandleOrDefault(hxFile));
end;

function AdvxPersistExecutionAlias;
var
  hxFile: IHandle;
  ActionTaken: TFileIoStatusResult;
begin
  // Open or create the target file's reparse point
  Result := NtxCreateFile(hxFile, FileParameters
    .UseFileName(Path, fnWin32)
    .UseAccess(FILE_WRITE_ATTRIBUTES or _DELETE)
    .UseDisposition(FILE_OPEN_IF)
    .UseOptions(FILE_OPEN_REPARSE_POINT or FILE_OPEN_FOR_BACKUP_INTENT),
    @ActionTaken
  );

  if not Result.IsSuccess then
    Exit;

  // When available, use the newer (by handle) method; othewise, fall back to
  // the API that reopens the file
  if LdrxCheckDelayedImport(delayed_PersistAppExecutionAliasToFileHandleEx)
    .IsSuccess then
    Result := AdvxPersistExecutionAliasByHandle(hxExecAlias, hxFile)
  else
    Result := AdvxPersistExecutionAliasByName(hxExecAlias, Path);

  // Undo file creation on failure
  if not Result.IsSuccess and (ActionTaken = FILE_CREATED) then
    NtxFile.Set<Boolean>(hxFile, FileDispositionInformation, True);
end;

function AdvxQueryExecutionAliasExecutable;
var
  Buffer: IMemory<PWideChar>;
  Required: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppExecutionAliasExecutableEx);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH * SizeOf(WideChar));
  repeat
    Required := Buffer.Size div SizeOf(WideChar);
    Result.Location := 'GetAppExecutionAliasExecutableEx';
    Result.HResult := GetAppExecutionAliasExecutableEx(
      Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), Buffer.Data, Required);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), Required *
    SizeOf(WideChar), nil);

  if Result.IsSuccess then
    Executable := RtlxCaptureString(Buffer.Data, Required);
end;

function AdvxQueryExecutionAliasAumid;
var
  Buffer: IMemory<PWideChar>;
  Required: Cardinal;
begin
  Result := LdrxCheckDelayedImport(
    delayed_GetAppExecutionAliasApplicationUserModelIdEx);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH * SizeOf(WideChar));
  repeat
    Required := Buffer.Size div SizeOf(WideChar);
    Result.Location := 'GetAppExecutionAliasApplicationUserModelIdEx';
    Result.HResult := GetAppExecutionAliasApplicationUserModelIdEx(
      Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), Buffer.Data, Required);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), Required *
    SizeOf(WideChar), nil);

  if Result.IsSuccess then
    Aumid := RtlxCaptureString(Buffer.Data, Required);
end;

function AdvxQueryExecutionAliasFullPackageName;
var
  Buffer: IMemory<PWideChar>;
  Required: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppExecutionAliasPackageFullNameEx);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH * SizeOf(WideChar));
  repeat
    Required := Buffer.Size div SizeOf(WideChar);
    Result.Location := 'GetAppExecutionAliasPackageFullNameEx';
    Result.HResult := GetAppExecutionAliasPackageFullNameEx(
      Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), Buffer.Data, Required);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), Required *
    SizeOf(WideChar), nil);

  if Result.IsSuccess then
    PackageFullName := RtlxCaptureString(Buffer.Data, Required);
end;

function AdvxQueryExecutionAliasFamilyPackageName;
var
  Buffer: IMemory<PWideChar>;
  Required: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppExecutionAliasPackageFamilyNameEx);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH * SizeOf(WideChar));
  repeat
    Required := Buffer.Size div SizeOf(WideChar);
    Result.Location := 'GetAppExecutionAliasPackageFamilyNameEx';
    Result.HResult := GetAppExecutionAliasPackageFamilyNameEx(
      Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), Buffer.Data, Required);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), Required *
    SizeOf(WideChar), nil);

  if Result.IsSuccess then
    PackageFamilyName := RtlxCaptureString(Buffer.Data, Required);
end;

function AdvxQueryExecutionAliasType;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppExecutionAliasApplicationType);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetAppExecutionAliasApplicationType';
  Result.HResult := GetAppExecutionAliasApplicationType(
    Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), AliasType);
end;

end.
