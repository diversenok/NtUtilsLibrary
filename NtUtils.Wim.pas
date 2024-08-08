unit NtUtils.Wim;

{
  This module provides support for interacting Windows Imaging API for accessing
  .wim files.
}

interface

uses
  Ntapi.wimgapi, Ntapi.ntseapi, NtUtils;

type
  IWimHandle = IHandle;

  IWimImageHandle = interface (IWimHandle)
    ['{E543B71B-6F7D-4553-B0FD-36D6E8148103}']
    function GetParent: IWimHandle;
    property Parent: IWimHandle read GetParent;
  end;

  TWimxMountEntry = record
    WimPath: String;
    MountPath: String;
    ImageIndex: Cardinal;
    MountedForRW: Boolean;
  end;

// Allow WIM functions to proceed without some privileges
function WimxSuppressPrivilegeChecks(
): TNtxStatus;

// Set a directory to use for temporary purposes
function WimxSetTemporaryPath(
  const hxWim: IWimHandle;
  const Path: String
): TNtxStatus;

// Open or create a .wim file
function WimxCreate(
  out hxWim: IWimHandle;
  const WimPath: String;
  DesiredAccess: TWimAccessMask;
  CreationDisposition: TWimCreationDisposition = WIM_OPEN_EXISTING;
  FlagsAndAttributes: TWimFlags = 0;
  CompressionType: TWimCompression = WIM_COMPRESS_XPRESS;
  [out, opt] CreationResult: PWimCreationResult = nil
): TNtxStatus;

// Determine the number of images in a .wim file
function WimxQueryImageCount(
  const hxWim: IWimHandle;
  out Count: Cardinal
): TNtxStatus;

// Query information about a .wim file
function WimxQueryAttributes(
  const hxWim: IWimHandle;
  out Info: TWimInfo
): TNtxStatus;

// Delete an image from a .wim file
function WimxDeleteImage(
  [Access(WIM_GENERIC_WRITE)] const hxWim: IWimHandle;
  ImageIndex: Cardinal
): TNtxStatus;

// Capture content of a path into a new image inside a .wim file
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_TAKE_OWNERSHIP_PRIVILEGE, rpWithExceptions)]
function WimxCaptureImage(
  out hxImage: IWimImageHandle;
  const hxWim: IWimHandle;
  const Path: String;
  CaptureFlags: TWimFlags = 0
): TNtxStatus;

// Open an image in a .wim file
function WimxLoadImage(
  out hxImage: IWimImageHandle;
  [Access(WIM_GENERIC_WRITE)] const hxWim: IWimHandle;
  ImageIndex: Cardinal
): TNtxStatus;

// Apply an .wim image to a directory
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_TAKE_OWNERSHIP_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpWithExceptions)]
function WimxApplyImage(
  const hxImage: IWimImageHandle;
  [opt] const Path: String;
  ApplyFlags: TWimFlags = 0
): TNtxStatus;

// Read image information as XML
function WimxQueryImageXML(
  const hxImage: IWimImageHandle;
  out ImageInfo: String
): TNtxStatus;

// Write image information as XML
function WimxSetImageXML(
  const hxImage: IWimImageHandle;
  const ImageInfo: String
): TNtxStatus;

// Mount an image from a .wim file to a directory
[RequiredPrivilege(SE_LOAD_DRIVER_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_TAKE_OWNERSHIP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpWithExceptions)]
function WimxMountImage(
  const MountPath: String;
  const WimFileName: String;
  ImageIndex: Cardinal = 1;
  [opt] const TempPath: String = ''
): TNtxStatus;

// Mount an image from a .wim file to a directory and unload it later
[RequiredPrivilege(SE_LOAD_DRIVER_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_TAKE_OWNERSHIP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpWithExceptions)]
function WimxMountImageAuto(
  out Unmounter: IAutoReleasable;
  const MountPath: String;
  const WimFileName: String;
  ImageIndex: Cardinal = 1;
  [opt] const TempPath: String = '';
  CommitOnUmount: Boolean = False
): TNtxStatus;

// Refreshes a mounted image
[RequiresAdmin]
function WimxRemountImage(
  const MountPath: String
): TNtxStatus;

// Unmount a previously mounted .wim image
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_TAKE_OWNERSHIP_PRIVILEGE, rpWithExceptions)]
function WimxUnmountImage(
  const MountPath: String;
  CommitChanges: LongBool
): TNtxStatus;

// Mount an image (by handle) from a .wim file to a directory
[RequiredPrivilege(SE_LOAD_DRIVER_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_TAKE_OWNERSHIP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpWithExceptions)]
function WimxMountImageHandle(
  [Access(WIM_GENERIC_MOUNT)] const hxImage: IWimImageHandle;
  const MountPath: String;
  MountFlags: TWimFlags = 0
): TNtxStatus;

// Mount an image (by handle) from a .wim file to a directory and unmount later
[RequiredPrivilege(SE_LOAD_DRIVER_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_TAKE_OWNERSHIP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_MANAGE_VOLUME_PRIVILEGE, rpWithExceptions)]
function WimxMountImageHandleAuto(
  out Unmounter: IAutoReleasable;
  [Access(WIM_GENERIC_MOUNT)] const hxImage: IWimImageHandle;
  const MountPath: String;
  MountFlags: TWimFlags = 0;
  CommitOnUmount: Boolean = False;
  CommitFlags: TWimCommitFlags = 0
): TNtxStatus;

// Commit changes to a mounted image
function WimxCommitImageHandle(
  [Access(WIM_GENERIC_MOUNT)] const hxImage: IWimImageHandle;
  CommitFlags: TWimCommitFlags = 0
): TNtxStatus;

// Commit changes to a mounted image into a new image
function WimxCommitAppendImageHandle(
  out hxNewImage: IWimImageHandle;
  [Access(WIM_GENERIC_MOUNT)] const hxImage: IWimImageHandle;
  CommitFlags: TWimCommitFlags = 0
): TNtxStatus;

// Unmount a previously mounted .wim image by handle
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_SECURITY_PRIVILEGE, rpWithExceptions)]
[RequiredPrivilege(SE_TAKE_OWNERSHIP_PRIVILEGE, rpWithExceptions)]
function WimxUnmountImageHandle(
  [Access(WIM_GENERIC_MOUNT)] const hxImage: IWimImageHandle
): TNtxStatus;

// Retieve the list of mounted images
[RequiresAdmin]
function WimxEnumerateMountedImages(
  out MountList: TArray<TWimxMountEntry>
): TNtxStatus;

// Open a mounted image
function WimxOpenMountedImage(
  const MountPath: String;
  out hxWimHandle: IWimHandle;
  out hxImageHandle: IWimImageHandle;
  Flags: TWimFlags = 0
): TNtxStatus;

implementation

uses
  Ntapi.WinError, Ntapi.ntstatus, Ntapi.ntdef, Ntapi.ntrtl, NtUtils.Ldr,
  DelphiUtils.AutoObjects, NtUtils.AntiHooking, NtUtils.SysUtils,
  NtUtils.Synchronization;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TWimAutoHandle = class (TCustomAutoHandle, IWimHandle)
    procedure Release; override;
  end;

  TWimImageAutoHandle = class (TWimAutoHandle, IWimImageHandle)
  protected
    FParent: IWimHandle;
    function GetParent: IWimHandle;
    constructor Capture(const hxParent: IWimHandle; hWimImage: TWimHandle);
  end;

procedure TWimAutoHandle.Release;
begin
  if (FHandle <> 0) and LdrxCheckDelayedImport(
    delayed_WIMCloseHandle).IsSuccess then
    WIMCloseHandle(FHandle);

  FHandle := 0;
  inherited;
end;

constructor TWimImageAutoHandle.Capture;
begin
  inherited Capture(hWimImage);
  FParent := hxParent;
end;

function TWimImageAutoHandle.GetParent;
begin
  Result := FParent;
end;

{ Functions }

function PatchedRtlAdjustPrivilege(
  [in] Privilege: TSeWellKnownPrivilege;
  [in] Enable: Boolean;
  [in] Client: Boolean;
  [out] out WasEnabled: Boolean
): NTSTATUS; stdcall;
begin
  try
    Result := RtlAdjustPrivilege(Privilege, Enable, Client, WasEnabled);

    if Result = STATUS_PRIVILEGE_NOT_HELD then
    begin
      // Convert the status into a successful one
      WasEnabled := True;
      Result := STATUS_NOT_ALL_ASSIGNED;
    end;
  except
    Result := STATUS_ACCESS_VIOLATION;
  end;
end;

var
  WimxpPrivilegeSuppressionInit: TRtlRunOnce;
  WimxpPrivilegeSuppressionReverter: IAutoReleasable;

function WimxSuppressPrivilegeChecks;
var
  Init: IAcquiredRunOnce;
begin
  if not RtlxRunOnceBegin(@WimxpPrivilegeSuppressionInit, Init) then
    Exit(NtxSuccess);

  // Resolve the module
  Result := LdrxCheckDelayedModule(delayed_wimgapi);

  if not Result.IsSuccess then
    Exit;

  // Redirect the privilege check
  Result := RtlxInstallIATHook(WimxpPrivilegeSuppressionReverter, wimgapi,
    ntdll, 'RtlAdjustPrivilege', @PatchedRtlAdjustPrivilege);

  if not Result.IsSuccess then
    Exit;

  Init.Complete;
end;

function WimxSetTemporaryPath;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMSetTemporaryPath);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMSetTemporaryPath';
  Result.Win32Result := WIMSetTemporaryPath(HandleOrDefault(hxWim),
    PWideChar(Path));
end;

function WimxCreate;
var
  hWim: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMCreateFile);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMCreateFile';
  hWim := WIMCreateFile(PWideChar(WimPath), DesiredAccess, CreationDisposition,
    FlagsAndAttributes, CompressionType, CreationResult);
  Result.Win32Result := hWim <> 0;

  if Result.IsSuccess then
    hxWim := TWimAutoHandle.Capture(hWim);
end;

function WimxQueryImageCount;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMGetImageCount);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMGetImageCount';
  Count := WIMGetImageCount(HandleOrDefault(hxWim));
  Result.Win32Result := Count > 0;
end;

function WimxQueryAttributes;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMGetAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMGetAttributes';
  Result.Win32Result := WIMGetAttributes(HandleOrDefault(hxWim), @Info,
    SizeOf(Info));
end;

function WimxDeleteImage;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMDeleteImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMDeleteImage';
  Result.LastCall.Expects<TWimAccessMask>(WIM_GENERIC_WRITE);
  Result.Win32Result := WIMDeleteImage(HandleOrDefault(hxWim), ImageIndex);
end;

function WimxCaptureImage;
var
  hImage: TWimHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMCaptureImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMCaptureImage';
  Result.LastCall.Expects<TWimAccessMask>(WIM_GENERIC_WRITE);
  hImage := WIMCaptureImage(HandleOrDefault(hxWim), PWideChar(Path),
    CaptureFlags);
  Result.Win32Result := hImage <> 0;

  if Result.IsSuccess then
    hxImage := TWimImageAutoHandle.Capture(hxWim, hImage);
end;

function WimxLoadImage;
var
  hImage: TWimHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMLoadImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMLoadImage';
  hImage := WIMLoadImage(HandleOrDefault(hxWim), ImageIndex);
  Result.Win32Result := hImage <> 0;

  if Result.IsSuccess then
    hxImage := TWimImageAutoHandle.Capture(hxWim, hImage);
end;

function WimxApplyImage;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMApplyImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMApplyImage';
  Result.Win32Result := WIMApplyImage(HandleOrDefault(hxImage),
    RefStrOrNil(Path), ApplyFlags);
end;

function WimxQueryImageXML;
var
  Buffer: PWideChar;
  BufferDeallocator: IAutoReleasable;
  Size: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMGetImageInformation);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMGetImageInformation';
  Result.Win32Result := WIMGetImageInformation(HandleOrDefault(hxImage),
    Buffer, Size);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := AdvxDelayLocalFree(Buffer);
  ImageInfo := RtlxSetStringWithEndian(Buffer, Size div SizeOf(WideChar));
end;

function WimxSetImageXML;
var
  Buffer: String;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMSetImageInformation);

  if not Result.IsSuccess then
    Exit;

  // The function requires the byte order mask
  Buffer := BOM_LE + ImageInfo;

  Result.Location := 'WIMSetImageInformation';
  Result.Win32Result := WIMSetImageInformation(HandleOrDefault(hxImage),
    PWideChar(Buffer), StringSizeNoZero(Buffer));
end;

function WimxMountImage;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMMountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMMountImage';
  Result.Win32Result := WIMMountImage(PWideChar(MountPath),
    PWideChar(WimFileName), ImageIndex, RefStrOrNil(TempPath));
end;

function WimxMountImageAuto;
begin
  Result := WimxMountImage(MountPath, WimFileName, ImageIndex, TempPath);

  if not Result.IsSuccess then
    Exit;

  Unmounter := Auto.Delay(
    procedure
    begin
      WimxUnmountImage(MountPath, CommitOnUmount);
    end
  );
end;

function WimxRemountImage;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMRemountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMRemountImage';
  Result.Win32Result := WIMRemountImage(PWideChar(MountPath), 0);
end;


function WimxUnmountImage;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMUnmountImage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMUnmountImage';
  Result.Win32Result := WIMUnmountImage(PWideChar(MountPath), nil, 0,
    CommitChanges);
end;

function WimxMountImageHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMMountImageHandle);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMMountImageHandle';
  Result.Win32Result := WIMMountImageHandle(HandleOrDefault(hxImage),
    PWideChar(MountPath), MountFlags);
end;

function WimxMountImageHandleAuto;
begin
  Result := WimxMountImageHandle(hxImage, MountPath, MountFlags);

  if not Result.IsSuccess then
    Exit;

  Unmounter := Auto.Delay(
    procedure
    begin
      if CommitOnUmount then
        WimxCommitImageHandle(hxImage, CommitFlags);

      WimxUnmountImageHandle(hxImage);
    end
  );
end;

function WimxCommitImageHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMCommitImageHandle);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMCommitImageHandle';
  Result.Win32Result := WIMCommitImageHandle(HandleOrDefault(hxImage),
    CommitFlags, nil);
end;

function WimxCommitAppendImageHandle;
var
  hNewImage: TWimHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMCommitImageHandle);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMCommitImageHandle';
  Result.Win32Result := WIMCommitImageHandle(HandleOrDefault(hxImage),
    CommitFlags or WIM_COMMIT_FLAG_APPEND, @hNewImage);

  if Result.IsSuccess then
    hxNewImage := TWimImageAutoHandle.Capture(hxImage.Parent, hNewImage);
end;

function WimxUnmountImageHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMUnmountImageHandle);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMUnmountImageHandle';
  Result.Win32Result := WIMUnmountImageHandle(HandleOrDefault(hxImage), 0);
end;

function WimxEnumerateMountedImages;
var
  Buffer: IMemory<PWimMountListArray>;
  Cursor: PWimMountList;
  Size: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMGetMountedImages);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TWimMountList));

  repeat
    Size := Buffer.Size;
    Result.Location := 'WIMGetMountedImages';
    Result.Win32Result := WIMGetMountedImages(Buffer.Data, Size);
  until not NtxExpandBufferEx(Result, IMemory(Buffer), Size, nil);

  if not Result.IsSuccess then
    Exit;

  SetLength(MountList, Size div SizeOf(TWimMountList));
  Cursor := @Buffer.Data[0];

  for i := 0 to High(MountList) do
  begin
    MountList[i].WimPath := Cursor.WimPath;
    MountList[i].MountPath := Cursor.MountPath;
    MountList[i].ImageIndex := Cursor.ImageIndex;
    MountList[i].MountedForRW := Cursor.MountedForRW;
    Inc(Cursor);
  end;
end;

function WimxOpenMountedImage;
var
  hWim, hImage: TWimHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WIMGetMountedImageHandle);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WIMGetMountedImageHandle';
  Result.Win32Result := WIMGetMountedImageHandle(PWideChar(MountPath), Flags,
    hWim, hImage);

  if not Result.IsSuccess then
    Exit;

  hxWimHandle := TWimAutoHandle.Capture(hWim);
  hxImageHandle := TWimImageAutoHandle.Capture(hxWimHandle, hImage);
end;

end.
