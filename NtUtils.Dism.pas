unit NtUtils.Dism;

{
  This module provides support for using DISM (Deployment Image Servicing and
  Managemen) API.
}

interface

uses
  Ntapi.WinNt, Ntapi.dismapi, Ntapi.ntseapi, NtUtils, DelphiApi.Reflection;

const
  // Forward the online image pseudo-path
  DISM_ONLINE_IMAGE = Ntapi.dismapi.DISM_ONLINE_IMAGE;

type
  IDismSession = NtUtils.IHandle;

  // An anonymous callback for monitoring progress
  TDismxProgressCallback = reference to procedure (Current, Total: Cardinal);

  TDismxImageInfo = record
    ImageType: TDismImageType;
    ImageIndex: Cardinal;
    ImageName: String;
    ImageDescription: String;
    [Bytes] ImageSize: UInt64;
    Architecture: TProcessorArchitecture32;
    ProductName: String;
    EditionId: String;
    InstallationType: String;
    Hal: String;
    ProductType: String;
    ProductSuite: String;
    MajorVersion: Cardinal;
    MinorVersion: Cardinal;
    Build: Cardinal;
    SpBuild: Cardinal;
    SpLevel: Cardinal;
    Bootable: TDismImageBootable;
    SystemRoot: String;
    Language: TArray<String>;
    DefaultLanguageIndex: Cardinal;
  end;

  TDismxMountedImageInfo = record
    MountPath: String;
    ImageFilePath: String;
    ImageIndex: Cardinal;
    MountMode: TDismMountMode;
    MountStatus: TDismMountStatus;
  end;

// Initialize DISM API
[RequiresAdmin]
[Result: ReleaseWith('DismxShutdown')]
function DismxInitialize(
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

// Uninitialize DISM API
function DismxShutdown(
): TNtxStatus;

// Initialize DISM API and uninitialize it later
[RequiresAdmin]
function DismxInitializeAuto(
  out Uninitializer: IAutoReleasable;
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

// Initialize DISM API once and uninitialize it on this unit finalizatoin
[RequiresAdmin]
function DismxInitializeOnce(
  LogLevel: TDismLogLevel = DismLogErrorsWarnings;
  [opt] const LogFilePath: String = '';
  [opt] const ScratchDirectory: String = ''
): TNtxStatus;

// Open a DISM session for the specified online/offline image path
function DismxOpenSession(
  out hxSession: IDismSession;
  const ImagePath: String;
  [opt] const WindowsDirectory: String = '';
  [opt] const SystemDrive: String = ''
): TNtxStatus;

// Query information about an image
function DismxGetImageInfo(
  const ImageFilePath: String;
  out ImageInfo: TArray<TDismxImageInfo>
): TNtxStatus;

{ Mounting }

// Mount a .wim or a .vhdx image to a given directory
function DismxMountImage(
  const ImageFilePath: String;
  const MountPath: String;
  [opt] ImageIndex: Cardinal;
  [opt] ImageName: String;
  ImageIdentifier: TDismImageIdentifier;
  Flags: TDismMountFlags = DISM_MOUNT_READONLY;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Unmount a previously mounted image
function DismxUnmountImage(
  const MountPath: String;
  Flags: TDismUnmountFlags = DISM_DISCARD_IMAGE;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Remount a previously mounted image
function DismxRemountImage(
  const MountPath: String
): TNtxStatus;

// Save changes to a mounted image
function DismxCommitImage(
  const hxSession: IDismSession;
  [in] Flags: Cardinal;
  [opt] const ProgressCallback: TDismxProgressCallback = nil;
  [opt] CancelEvent: THandle = 0
): TNtxStatus;

// Query information about a mounted image
function DismxGetMountedImageInfo(
  out ImageInfo: TArray<TDismxMountedImageInfo>
): TNtxStatus;

implementation

uses
  NtUtils.Ldr, NtUtils.Synchronization, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Auto resources }

type
  TDismSessionAutoHandle = class (TCustomAutoHandle, IDismSession)
    procedure Release; override;
  end;

procedure TDismSessionAutoHandle.Release;
begin
  if (FHandle <> 0) and LdrxCheckDelayedImport(delayed_dismapi,
    delayed_DismCloseSession).IsSuccess then
    DismCloseSession(FHandle);

  FHandle := 0;
  inherited;
end;

type
  TDismAutoMemory = class (TCustomAutoPointer, IAutoPointer)
    procedure Release; override;
  end;

procedure TDismAutoMemory.Release;
begin
  if Assigned(FData) and LdrxCheckDelayedImport(delayed_dismapi,
    delayed_DismDelete).IsSuccess then
    DismDelete(FData);

  FData := nil;
  inherited;
end;

function DismxDelayedFree(
  Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      if LdrxCheckDelayedImport(delayed_dismapi,
        delayed_DismDelete).IsSuccess then
        DismDelete(Buffer);
    end
  );
end;

{ Callback support }

procedure DismxpCallbackDispatcher(
  [in] Current: Cardinal;
  [in] Total: Cardinal;
  [in] UserData: Pointer
); stdcall;
var
  Callback: TDismxProgressCallback absolute UserData;
begin
  if Assigned(Callback) then
    Callback(Current, Total);
end;

[Result: MayReturnNil]
function DismxpGetCallbackDispatcher(
  [opt] const Callback: TDismxProgressCallback
): TDismProgressCallback;
begin
  if Assigned(Callback) then
    Result := DismxpCallbackDispatcher
  else
    Result := nil;
end;

{ Initialization }

function DismxInitialize;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismInitialize);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismInitialize';
  Result.HResult := DismInitialize(LogLevel, RefStrOrNil(LogFilePath),
    RefStrOrNil(ScratchDirectory));
end;

function DismxShutdown;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismShutdown);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismShutdown';
  Result.HResult := DismShutdown;
end;

function DismxInitializeAuto;
begin
  Result := DismxInitialize(LogLevel, LogFilePath, ScratchDirectory);

  if not Result.IsSuccess then
    Exit;

  Uninitializer := Auto.Delay(
    procedure
    begin
      DismxShutdown;
    end
  );
end;

var
  DismxInitialized: TRtlRunOnce;
  DismxUnitinitializer: IAutoReleasable;

function DismxInitializeOnce;
var
  InitState: IAcquiredRunOnce;
begin
  if RtlxRunOnceBegin(@DismxInitialized, InitState) then
  begin
    // Put uninitializer into a global variable to trigger cleaup on unit unload
    Result := DismxInitializeAuto(DismxUnitinitializer, LogLevel, LogFilePath,
      ScratchDirectory);

    if not Result.IsSuccess then
      Exit;

    InitState.Complete;
  end
  else
    Result := NtxSuccess;
end;

function DismxOpenSession;
var
  hSession: TDismSession;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismOpenSession);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismOpenSession';
  Result.HResult := DismOpenSession(PWideChar(ImagePath),
    RefStrOrNil(WindowsDirectory), RefStrOrNil(SystemDrive), hSession);

  if Result.IsSuccess then
    hxSession := TDismSessionAutoHandle.Capture(hSession);
end;

function DismxGetImageInfo;
var
  Buffer: PDismImageInfoArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismImageInfo;
  Count: Cardinal;
  i, j: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismGetImageInfo);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetImageInfo';
  Result.HResult := DismGetImageInfo(PWideChar(ImageFilePath), Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(ImageInfo, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(ImageInfo) do
  begin
    ImageInfo[i].ImageType := Cursor.ImageType;
    ImageInfo[i].ImageIndex := Cursor.ImageIndex;
    ImageInfo[i].ImageName := Cursor.ImageName;
    ImageInfo[i].ImageDescription := Cursor.ImageDescription;
    ImageInfo[i].ImageSize := Cursor.ImageSize;
    ImageInfo[i].Architecture := Cursor.Architecture;
    ImageInfo[i].ProductName := Cursor.ProductName;
    ImageInfo[i].EditionId := Cursor.EditionId;
    ImageInfo[i].InstallationType := Cursor.InstallationType;
    ImageInfo[i].Hal := Cursor.Hal;
    ImageInfo[i].ProductType := Cursor.ProductType;
    ImageInfo[i].ProductSuite := Cursor.ProductSuite;
    ImageInfo[i].MajorVersion := Cursor.MajorVersion;
    ImageInfo[i].MinorVersion := Cursor.MinorVersion;
    ImageInfo[i].Build := Cursor.Build;
    ImageInfo[i].SpBuild := Cursor.SpBuild;
    ImageInfo[i].SpLevel := Cursor.SpLevel;
    ImageInfo[i].Bootable := Cursor.Bootable;
    ImageInfo[i].SystemRoot := Cursor.SystemRoot;
    SetLength(ImageInfo[i].Language, Cursor.LanguageCount);

    for j := 0 to High(ImageInfo[i].Language) do
      ImageInfo[i].Language[j] := Cursor
        .Language{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF}.Value;

    ImageInfo[i].DefaultLanguageIndex := Cursor.DefaultLanguageIndex;
    Inc(Cursor);
  end;
end;

{ Mounting }

function DismxMountImage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismMountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismMountImage';
  Result.HResult := DismMountImage(
    PWideChar(ImageFilePath),
    PWideChar(MountPath),
    ImageIndex,
    RefStrOrNil(ImageName),
    ImageIdentifier,
    Flags,
    CancelEvent,
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxUnmountImage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismUnmountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismUnmountImage';
  Result.HResult := DismUnmountImage(
    PWideChar(MountPath),
    Flags,
    CancelEvent,
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxRemountImage;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismRemountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismRemountImage';
  Result.HResult := DismRemountImage(PWideChar(MountPath));
end;

function DismxCommitImage;
var
  Context: Pointer absolute ProgressCallback;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi, delayed_DismCommitImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismCommitImage';
  Result.HResult := DismCommitImage(
    HandleOrDefault(hxSession),
    Flags,
    CancelEvent,
    DismxpGetCallbackDispatcher(ProgressCallback),
    Context
  );
end;

function DismxGetMountedImageInfo;
var
  Buffer: PDismMountedImageInfoArray;
  BufferDeallocator: IAutoReleasable;
  Cursor: PDismMountedImageInfo;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_dismapi,
    delayed_DismGetMountedImageInfo);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DismGetMountedImageInfo';
  Result.HResult := DismGetMountedImageInfo(Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DismxDelayedFree(Buffer);
  SetLength(ImageInfo, Count);
  Cursor := @Buffer[0];

  for i := 0 to High(ImageInfo) do
  begin
    ImageInfo[i].MountPath := Cursor.MountPath;
    ImageInfo[i].ImageFilePath := Cursor.ImageFilePath;
    ImageInfo[i].ImageIndex := Cursor.ImageIndex;
    ImageInfo[i].MountMode := Cursor.MountMode;
    ImageInfo[i].MountStatus := Cursor.MountStatus;
    Inc(Cursor);
  end;
end;

end.
