unit NtUtils.Dism;

{
  This module provides support for using DISM (Deployment Image Servicing and
  Managemen) API.
}

interface

uses
  Ntapi.dismapi, Ntapi.ntseapi, NtUtils, DelphiApi.Reflection;

const
  // Forward the online image pseudo-path
  DISM_ONLINE_IMAGE = Ntapi.dismapi.DISM_ONLINE_IMAGE;

type
  IDismSession = NtUtils.IHandle;

  // An anonymous callback for monitoring progress
  TDismxProgressCallback = reference to procedure (Current, Total: Cardinal);

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

implementation

uses
  NtUtils.Ldr, NtUtils.Synchronization, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Helpers }

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

end.
