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
function PkgxLoadExecutionAliasInfo(
  out Info: IExecAliasInfo;
  const ApplicationPath: String;
  [opt, Access(TOKEN_LOAD_ALIAS)] const hxIncomingToken: IHandle = nil
): TNtxStatus;

// Generate a token for an existing execution alias
[MinOSVersion(OsWin10RS3)]
function PkgxLoadExecutionAliasToken(
  out hxToken: IHandle;
  const ApplicationPath: String;
  [opt, Access(TOKEN_LOAD_ALIAS)] const hxIncomingToken: IHandle = nil
): TNtxStatus;

// Generate a token for an AUMID by creating a temporary execution alias
[MinOSVersion(OsWin10RS4)]
function PkgxGenerateExecAliasTokenForAumid(
  out hxToken: IHandle;
  const ApplicationUserModelId: String;
  AliasType: TAppExecutionAliasType = AppExecAliasDesktop;
  [opt] const hxIncomingToken: IHandle = nil
): TNtxStatus;

// Open and parse an execution alias
[MinOSVersion(OsWin10RS3)]
function PkgxOpenExecutionAlias(
  out hxExecAlias: IExecAliasData;
  const Path: String;
  [opt, Access(TOKEN_QUERY)] const hxToken: IHandle = nil
): TNtxStatus;

// Prepare a new execution alias
[MinOSVersion(OsWin10RS4)]
function PkgxCreateExecutionAlias(
  out hxExecAlias: IExecAliasData;
  const ApplicationUserModelId: String;
  const PackageRelativeExecutable: String;
  AliasType: TAppExecutionAliasType = AppExecAliasDesktop;
  [opt] PackageFamilyName: String = ''
): TNtxStatus;

// Save an execution alias to an existing file by name
[MinOSVersion(OsWin10RS3)]
function PkgxPersistExecutionAliasByName(
  const hxExecAlias: IExecAliasData;
  const Path: String
): TNtxStatus;

// Save an execution alias to a file by handle
[MinOSVersion(OsWin1019H2)]
function PkgxPersistExecutionAliasByHandle(
  const hxExecAlias: IExecAliasData;
  [Access(FILE_WRITE_DATA or FILE_WRITE_ATTRIBUTES)] const hxFile: IHandle
): TNtxStatus;

// Save an execution alias to a new/existing file
[MinOSVersion(OsWin10RS3)]
function PkgxPersistExecutionAlias(
  const hxExecAlias: IExecAliasData;
  const Path: String
): TNtxStatus;

// Query the target executable for an execution alias
[MinOSVersion(OsWin10RS3)]
function PkgxQueryExecutionAliasExecutable(
  const hxExecAlias: IExecAliasData;
  out Executable: String
): TNtxStatus;

// Query the target app user model ID for an execution alias
[MinOSVersion(OsWin10RS3)]
function PkgxQueryExecutionAliasAumid(
  const hxExecAlias: IExecAliasData;
  out Aumid: String
): TNtxStatus;

// Query the target full package name for an execution alias
[RequiresCOM]
[MinOSVersion(OsWin10RS3)]
function PkgxQueryExecutionAliasFullPackageName(
  const hxExecAlias: IExecAliasData;
  out PackageFullName: String
): TNtxStatus;

// Query the target package family name for an execution alias
[MinOSVersion(OsWin10RS3)]
function PkgxQueryExecutionAliasFamilyPackageName(
  const hxExecAlias: IExecAliasData;
  out PackageFamilyName: String
): TNtxStatus;

// Query the application type for an execution alias
[MinOSVersion(OsWin10RS4)]
function PkgxQueryExecutionAliasType(
  const hxExecAlias: IExecAliasData;
  out AliasType: TAppExecutionAliasType
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, NtUtils.Ldr, NtUtils.Objects, NtUtils.Packages,
  NtUtils.Packages.SRCache, NtUtils.Files.Open, NtUtils.Files.Operations,
  NtUtils.SysUtils, NtUtils.Environment;

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

function PkgxLoadExecutionAliasInfo;
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

function PkgxLoadExecutionAliasToken;
var
  Info: IExecAliasInfo;
begin
  Result := PkgxLoadExecutionAliasInfo(Info, ApplicationPath, hxIncomingToken);

  if not Result.IsSuccess then
    Exit;

  if Info.Data.ActivationToken = 0 then
  begin
    Result.Location := 'AdvxLoadExecutionAliasToken';
    Result.Status := STATUS_NO_TOKEN;
    Exit;
  end;

  // Reopen the handle since the returned one will be closed with the info
  Result := NtxDuplicateHandleLocal(Auto.RefHandle(Info.Data.ActivationToken),
    hxToken, 0, 0, DUPLICATE_SAME_ACCESS or DUPLICATE_SAME_ATTRIBUTES);
end;

function PkgxGenerateExecAliasTokenForAumid;
var
  ApplicationId: TSRCacheApplicationId;
  PackageId: TSRCachePackageId;
  AliasPath, InstallLocation: String;
  hxAliasData: IExecAliasData;
  hxApplicationKey, hxPackageKey, hxAliasFile: IHandle;
  FileDeleter: IAutoReleasable;
begin
  // Locate the TEMP directory to write the execution alias to
  Result := RtlxQueryVariableEnvironment('TEMP', AliasPath);

  if not Result.IsSuccess then
    Exit;

  // Find the application ID in the state repository cache
  Result := PkgxSRCacheFindApplicationId(ApplicationId, ApplicationUserModelId);

  if not Result.IsSuccess then
    Exit;

  // Open the state repository cache data key for the AUMID
  Result := PkgxSRCacheOpenApplication(ApplicationId, hxApplicationKey);

  if not Result.IsSuccess then
    Exit;

  // Determine the corresponding package ID
  Result := PkgxSRCacheQueryApplicationPackageID(hxApplicationKey, PackageId);

  if not Result.IsSuccess then
    Exit;

  hxApplicationKey := nil;

  // Open the state repository cache data key for the package
  Result := PkgxSRCacheOpenPackage(PackageId, hxPackageKey);

  if not Result.IsSuccess then
    Exit;

  // Determine package installation location
  Result := PkgxSRCacheQueryPackageLocation(hxPackageKey, InstallLocation);

  if not Result.IsSuccess then
    Exit;

  hxPackageKey := nil;

  // Prepare reparse data for the execution alias. AppInfo might require the
  // target file to belong to the package, so we specify the manifest, as it
  // always exists in packages that contain applications.
  Result := PkgxCreateExecutionAlias(hxAliasData, ApplicationUserModelId,
    RtlxCombinePaths(InstallLocation, 'AppxManifest.xml'), AliasType);

  if not Result.IsSuccess then
    Exit;

  // Generate a random file name
  AliasPath := RtlxCombinePaths(AliasPath, RtlxGuidToString(RtlxRandomGuid));

  // Create a temporary file for the reparse point
  Result := NtxCreateFile(hxAliasFile, FileParameters
    .UseFileName(AliasPath, fnWin32)
    .UseAccess(FILE_WRITE_ATTRIBUTES or _DELETE)
    .UseFileAttributes(FILE_ATTRIBUTE_TEMPORARY)
    .UseOptions(FILE_OPEN_REPARSE_POINT or FILE_OPEN_FOR_BACKUP_INTENT)
    .UseShareMode(FILE_SHARE_READ)
    .UseDisposition(FILE_CREATE)
  );

  if not Result.IsSuccess then
    Exit;

  // Undo file creation on exit
  FileDeleter := Auto.Delay(
    procedure
    begin
      NtxFile.Set<Boolean>(hxAliasFile, FileDispositionInformation, True);
    end
  );

  // Apply the execution alias reparse point
  if LdrxCheckDelayedImport(delayed_PersistAppExecutionAliasToFileHandleEx)
    .IsSuccess then
    Result := PkgxPersistExecutionAliasByHandle(hxAliasData, hxAliasFile)
  else
    Result := PkgxPersistExecutionAliasByName(hxAliasData, AliasPath);

  if not Result.IsSuccess then
    Exit;

  // Ask AppInfo to generate a token
  Result := PkgxLoadExecutionAliasToken(hxToken, AliasPath, hxIncomingToken);
end;

function PkgxOpenExecutionAlias;
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

function PkgxCreateExecutionAlias;
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

function PkgxPersistExecutionAliasByName;
begin
  Result := LdrxCheckDelayedImport(delayed_PersistAppExecutionAliasToFileEx);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'PersistAppExecutionAliasToFileEx';
  Result.HResult := PersistAppExecutionAliasToFileEx(
    Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), PWideChar(Path));
end;

function PkgxPersistExecutionAliasByHandle;
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

function PkgxPersistExecutionAlias;
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
    Result := PkgxPersistExecutionAliasByHandle(hxExecAlias, hxFile)
  else
    Result := PkgxPersistExecutionAliasByName(hxExecAlias, Path);

  // Undo file creation on failure
  if not Result.IsSuccess and (ActionTaken = FILE_CREATED) then
    NtxFile.Set<Boolean>(hxFile, FileDispositionInformation, True);
end;

function PkgxQueryExecutionAliasExecutable;
var
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppExecutionAliasExecutableEx);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH * SizeOf(WideChar));
  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Location := 'GetAppExecutionAliasExecutableEx';
    Result.HResult := GetAppExecutionAliasExecutableEx(
      Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), Buffer.Data, BufferLength);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

  if not Result.IsSuccess then
    Exit;

  // Strip the terminating zero
  if BufferLength > 0 then
    Dec(BufferLength);

  SetString(Executable, Buffer.Data, BufferLength);
end;

function PkgxQueryExecutionAliasAumid;
var
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(
    delayed_GetAppExecutionAliasApplicationUserModelIdEx);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH * SizeOf(WideChar));
  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Location := 'GetAppExecutionAliasApplicationUserModelIdEx';
    Result.HResult := GetAppExecutionAliasApplicationUserModelIdEx(
      Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), Buffer.Data, BufferLength);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

  if not Result.IsSuccess then
    Exit;

  // Strip the terminating zero
  if BufferLength > 0 then
    Dec(BufferLength);

  SetString(Aumid, Buffer.Data, BufferLength);
end;

function PkgxQueryExecutionAliasFullPackageName;
var
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppExecutionAliasPackageFullNameEx);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH * SizeOf(WideChar));
  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Location := 'GetAppExecutionAliasPackageFullNameEx';
    Result.HResult := GetAppExecutionAliasPackageFullNameEx(
      Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), Buffer.Data, BufferLength);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

  if not Result.IsSuccess then
    Exit;

  // Strip the terminating zero
  if BufferLength > 0 then
    Dec(BufferLength);

  SetString(PackageFullName, Buffer.Data, BufferLength);
end;

function PkgxQueryExecutionAliasFamilyPackageName;
var
  Buffer: IMemory<PWideChar>;
  BufferLength: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppExecutionAliasPackageFamilyNameEx);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(MAX_PATH * SizeOf(WideChar));
  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    Result.Location := 'GetAppExecutionAliasPackageFamilyNameEx';
    Result.HResult := GetAppExecutionAliasPackageFamilyNameEx(
      Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), Buffer.Data, BufferLength);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), BufferLength *
    SizeOf(WideChar), nil);

  if not Result.IsSuccess then
    Exit;

  // Strip the terminating zero
  if BufferLength > 0 then
    Dec(BufferLength);

  SetString(PackageFamilyName, Buffer.Data, BufferLength);
end;

function PkgxQueryExecutionAliasType;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppExecutionAliasApplicationType);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetAppExecutionAliasApplicationType';
  Result.HResult := GetAppExecutionAliasApplicationType(
    Auto.RefOrNil<PAppExecAliasData>(hxExecAlias), AliasType);
end;

end.
