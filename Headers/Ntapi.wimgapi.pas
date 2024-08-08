unit Ntapi.wimgapi;

{
  This file provides definitions for working with .wim files.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntioapi, Ntapi.WinError, Ntapi.WinUser,
  DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  wimgapi = 'wimgapi.dll';

var
  delayed_wimgapi: TDelayedLoadDll = (DllName: wimgapi);

const
  // ADK::wimgapi.h - access rights
  WIM_GENERIC_READ = GENERIC_READ;
  WIM_GENERIC_WRITE = GENERIC_WRITE;
  WIM_GENERIC_MOUNT = GENERIC_EXECUTE;
  WIM_GENERIC_ALL = WIM_GENERIC_READ or WIM_GENERIC_WRITE or WIM_GENERIC_MOUNT;

  // ADK::wimgapi.h - create/capture/apply/mount flags
  WIM_FLAG_VERIFY = $00000002;
  WIM_FLAG_INDEX = $00000004;
  WIM_FLAG_NO_APPLY = $00000008;
  WIM_FLAG_NO_DIRACL = $00000010;
  WIM_FLAG_NO_FILEACL = $00000020;
  WIM_FLAG_SHARE_WRITE = $00000040;
  WIM_FLAG_FILEINFO = $00000080;
  WIM_FLAG_NO_RP_FIX = $00000100;
  WIM_FLAG_MOUNT_READONLY = $00000200;
  WIM_FLAG_MOUNT_FAST = $00000400;    // Win 8+
  WIM_FLAG_MOUNT_LEGACY = $00000800;  // Win 8+
  WIM_FLAG_APPLY_CI_EA = $00001000;   // Win 8.1+
  WIM_FLAG_WIM_BOOT = $00002000;      // Win 8.1+
  WIM_FLAG_APPLY_COMPACT = $00004000; // Win 10 TH1+
  WIM_FLAG_SUPPORT_EA = $00008000;    // Win 10 RS1+

  // ADK::wimgapi.h - mounted list flags
  WIM_MOUNT_FLAG_MOUNTED = $00000001;
  WIM_MOUNT_FLAG_MOUNTING = $00000002;
  WIM_MOUNT_FLAG_REMOUNTABLE = $00000004;
  WIM_MOUNT_FLAG_INVALID = $00000008;
  WIM_MOUNT_FLAG_NO_WIM = $00000010;
  WIM_MOUNT_FLAG_NO_MOUNTDIR = $00000020;
  WIM_MOUNT_FLAG_MOUNTDIR_REPLACED = $00000040;
  WIM_MOUNT_FLAG_READWRITE = $00000100;

  // ADK::wimgapi.h - commit flags
  WIM_COMMIT_FLAG_APPEND = $00000001;

  // ADK::wimgapi.h - export flags
  WIM_EXPORT_ALLOW_DUPLICATES = $00000001;
  WIM_EXPORT_ONLY_RESOURCES = $00000002;
  WIM_EXPORT_ONLY_METADATA = $00000004;
  WIM_EXPORT_VERIFY_SOURCE = $00000008;      // Windows 8+
  WIM_EXPORT_VERIFY_DESTINATION = $00000010; // Windows 8+

  // ADK::wimgapi.h - callback registration error
  INVALID_CALLBACK_VALUE = $FFFFFFFF;

  // ADK::wimgapi.h - delete image mounts flags
  WIM_DELETE_MOUNTS_ALL = $00000001;

  // ADK::wimgapi.h - register log flags
  WIM_LOGFILE_UTF8 = $00000001; // Windows 8+

  // ADK::wimgapi.h - callback return codes
  WIM_MSG_SUCCESS = ERROR_SUCCESS;
  WIM_MSG_DONE = $FFFFFFF0;
  WIM_MSG_SKIP_ERROR = $FFFFFFFE;
  WIM_MSG_ABORT_IMAGE = $FFFFFFFF;

  // ADK::wimgapi.h - info flags
  WIM_ATTRIBUTE_NORMAL = $00000000;
  WIM_ATTRIBUTE_RESOURCE_ONLY = $00000001;
  WIM_ATTRIBUTE_METADATA_ONLY = $00000002;
  WIM_ATTRIBUTE_VERIFY_DATA = $00000004;
  WIM_ATTRIBUTE_RP_FIX = $00000008;
  WIM_ATTRIBUTE_SPANNED = $00000010;
  WIM_ATTRIBUTE_READONLY = $00000020;

type
  TWimHandle = type THandle;
  PWimHandle = ^TWimHandle;

  [FriendlyName('WIM image'), ValidBits(WIM_GENERIC_ALL)]
  [FlagName(WIM_GENERIC_READ, 'Read')]
  [FlagName(WIM_GENERIC_WRITE, 'Write')]
  [FlagName(WIM_GENERIC_MOUNT, 'Mount')]
  TWimAccessMask = type Cardinal;

  [NamingStyle(nsSnakeCase, 'WIM')]
  TWimCreationDisposition = (
    WIM_CREATE_NEW = 1,
    WIM_CREATE_ALWAYS = 2,
    WIM_OPEN_EXISTING = 3,
    WIM_OPEN_ALWAYS = 4
  );

  // ADK::wimgapi.h
  [NamingStyle(nsSnakeCase, 'WIM_COMPRESS')]
  TWimCompression = (
    WIM_COMPRESS_NONE = 0,
    WIM_COMPRESS_XPRESS = 1,
    WIM_COMPRESS_LZX = 2,
    WIM_COMPRESS_LZMS = 3 // Win 8+
  );

  // ADK::wimgapi.h
  [NamingStyle(nsSnakeCase, 'WIM')]
  TWimCreationResult = (
    WIM_CREATED_NEW = 0,
    WIM_OPENED_EXISTING = 1
  );
  PWimCreationResult = ^TWimCreationResult;

  [FlagName(WIM_FLAG_VERIFY, 'Verify')]
  [FlagName(WIM_FLAG_INDEX, 'Index')]
  [FlagName(WIM_FLAG_NO_APPLY, 'No Apply')]
  [FlagName(WIM_FLAG_NO_DIRACL, 'No Directory ACL')]
  [FlagName(WIM_FLAG_NO_FILEACL, 'No File ACL')]
  [FlagName(WIM_FLAG_SHARE_WRITE, 'Share Write')]
  [FlagName(WIM_FLAG_FILEINFO, 'Message File Info')]
  [FlagName(WIM_FLAG_NO_RP_FIX, 'No Reparse Fix')]
  [FlagName(WIM_FLAG_MOUNT_READONLY, 'Mount Read-only')]
  [FlagName(WIM_FLAG_MOUNT_FAST, 'Mount Fast')]
  [FlagName(WIM_FLAG_MOUNT_LEGACY, 'Mount Legacy')]
  [FlagName(WIM_FLAG_APPLY_CI_EA, 'Apply CI EA')]
  [FlagName(WIM_FLAG_WIM_BOOT, 'WIM Boot')]
  [FlagName(WIM_FLAG_APPLY_COMPACT, 'Apply Compat')]
  [FlagName(WIM_FLAG_SUPPORT_EA, 'Support EA')]
  TWimFlags = type Cardinal;

  [FlagName(WIM_MOUNT_FLAG_MOUNTED, 'Mounted')]
  [FlagName(WIM_MOUNT_FLAG_MOUNTING, 'Mounting')]
  [FlagName(WIM_MOUNT_FLAG_REMOUNTABLE, 'Remountable')]
  [FlagName(WIM_MOUNT_FLAG_INVALID, 'Invalid')]
  [FlagName(WIM_MOUNT_FLAG_NO_WIM, 'No WIM')]
  [FlagName(WIM_MOUNT_FLAG_NO_MOUNTDIR, 'No Mount Dir')]
  [FlagName(WIM_MOUNT_FLAG_MOUNTDIR_REPLACED, 'Mount Dir Replaced')]
  [FlagName(WIM_MOUNT_FLAG_READWRITE, 'Read/write')]
  TWimMountFlags = type Cardinal;

  [InheritsFrom(System.TypeInfo(TWimFlags))]
  [FlagName(WIM_COMMIT_FLAG_APPEND, 'Append')]
  TWimCommitFlags = type Cardinal;

  // ADK::wimgapi.h
  [NamingStyle(nsSnakeCase, 'WIM_REFERENCE')]
  TWimSetReferenceFlags = (
    WIM_REFERENCE_APPEND = $00010000,
    WIM_REFERENCE_REPLACE = $00020000
  );

  [FlagName(WIM_EXPORT_ALLOW_DUPLICATES, 'Allow Duplicates')]
  [FlagName(WIM_EXPORT_ONLY_RESOURCES, 'Only Resources')]
  [FlagName(WIM_EXPORT_ONLY_METADATA, 'Only Metadata')]
  [FlagName(WIM_EXPORT_VERIFY_SOURCE, 'Verify Source')]
  [FlagName(WIM_EXPORT_VERIFY_DESTINATION, 'Verify Destination')]
  TWimExportFlags = type Cardinal;

  [FlagName(WIM_DELETE_MOUNTS_ALL, 'Delete All Mounts')]
  TWimDeleteFlags = type Cardinal;

  [FlagName(WIM_LOGFILE_UTF8, 'UTF-8')]
  TWimLogFlags = type Cardinal;

  // ADK::wimgapi.h
  [NamingStyle(nsSnakeCase, 'WIM_MSG')]
  TWimMessage = (
    WIM_MSG = WM_APP + $1476,
    WIM_MSG_TEXT,
    WIM_MSG_PROGRESS,
    WIM_MSG_PROCESS,
    WIM_MSG_SCANNING,
    WIM_MSG_SETRANGE,
    WIM_MSG_SETPOS,
    WIM_MSG_STEPIT,
    WIM_MSG_COMPRESS,
    WIM_MSG_ERROR,
    WIM_MSG_ALIGNMENT,
    WIM_MSG_RETRY,
    WIM_MSG_SPLIT,
    WIM_MSG_FILEINFO,
    WIM_MSG_INFO,
    WIM_MSG_WARNING,
    WIM_MSG_CHK_PROCESS,
    WIM_MSG_WARNING_OBJECTID,
    WIM_MSG_STALE_MOUNT_DIR,
    WIM_MSG_STALE_MOUNT_FILE,
    WIM_MSG_MOUNT_CLEANUP_PROGRESS,
    WIM_MSG_CLEANUP_SCANNING_DRIVE,
    WIM_MSG_IMAGE_ALREADY_MOUNTED,
    WIM_MSG_CLEANUP_UNMOUNTING_IMAGE,
    WIM_MSG_QUERY_ABORT,
    WIM_MSG_IO_RANGE_START_REQUEST_LOOP,      // Windows 8+
    WIM_MSG_IO_RANGE_END_REQUEST_LOOP,        // Windows 8+
    WIM_MSG_IO_RANGE_REQUEST,                 // Windows 8+
    WIM_MSG_IO_RANGE_RELEASE,                 // Windows 8+
    WIM_MSG_VERIFY_PROGRESS,                  // Windows 8+
    WIM_MSG_COPY_BUFFER,                      // Windows 8+
    WIM_MSG_METADATA_EXCLUDE,                 // Windows 8+
    WIM_MSG_GET_APPLY_ROOT,                   // Windows 8+
    WIM_MSG_MDPAD,                            // Windows 8+
    WIM_MSG_STEPNAME,                         // Windows 8+
    WIM_MSG_PERFILE_COMPRESS,                 // Windows 8.1+
    WIM_MSG_CHECK_CI_EA_PREREQUISITE_NOT_MET, // Windows 8.1+
    WIM_MSG_JOURNALING_ENABLED                // Windows 8.1+
  );

  [SubEnum(MAX_UINT, WIM_MSG_SUCCESS, 'Success')]
  [SubEnum(MAX_UINT, WIM_MSG_DONE, 'Done')]
  [SubEnum(MAX_UINT, WIM_MSG_SKIP_ERROR, 'Skip Error')]
  [SubEnum(MAX_UINT, WIM_MSG_ABORT_IMAGE, 'Abort Image')]
  TWimCallbackError = type Cardinal;

  [FlagName(WIM_ATTRIBUTE_NORMAL, 'Normal')]
  [FlagName(WIM_ATTRIBUTE_RESOURCE_ONLY, 'Resource Only')]
  [FlagName(WIM_ATTRIBUTE_METADATA_ONLY, 'Metadata Only')]
  [FlagName(WIM_ATTRIBUTE_VERIFY_DATA, 'Verify Data')]
  [FlagName(WIM_ATTRIBUTE_RP_FIX, 'Repars Point Fix')]
  [FlagName(WIM_ATTRIBUTE_SPANNED, 'Spanned')]
  [FlagName(WIM_ATTRIBUTE_READONLY, 'Read-only')]
  TWimAttributes = type Cardinal;

  // ADK::wimgapi.h
  [SDKName('WIM_INFO')]
  TWimInfo = record
    WimPath: TMaxPathWideCharArray;
    Guid: TGuid;
    [NumberOfElements] ImageCount: Cardinal;
    CompressionType: TWimCompression;
    PartNumber: Word;
    TotalParts: Word;
    BootIndex: Cardinal;
    WimAttributes: TWimAttributes;
    WimFlagsAndAttr: TWimFlags;
  end;
  PWimInfo = ^TWimInfo;

  // ADK::wimgapi.h
  [SDKName('WIM_MOUNT_LIST')]
  TWimMountList = record
    WimPath: TMaxPathWideCharArray;
    MountPath: TMaxPathWideCharArray;
    ImageIndex: Cardinal;
    MountedForRW: LongBool;
  end;
  PWimMountList = ^TWimMountList;
  TWimMountListArray = TAnysizeArray<TWimMountList>;
  PWimMountListArray = ^TWimMountListArray;

  // ADK::wimgapi.h
  [SDKName('MOUNTED_IMAGE_INFO_LEVELS')]
  [NamingStyle(nsCamelCase, 'MountedImage')]
  TMountedImageInfoLevels = (
    MountedImageInfoLevel0 = 0, // out: TWimMountInfoLevel0
    MountedImageInfoLevel1 = 1  // out: TWimMountInfoLevel1
  );

  // ADK::wimgapi.h
  [SDKName('WIM_MOUNT_INFO_LEVEL0')]
  TWimMountInfoLevel0 = type TWimMountList;
  PWimMountInfoLevel0 = ^TWimMountInfoLevel0;

  // ADK::wimgapi.h
  [SDKName('WIM_MOUNT_INFO_LEVEL1')]
  TWimMountInfoLevel1 = record
    WimPath: TMaxPathWideCharArray;
    MountPath: TMaxPathWideCharArray;
    ImageIndex: Cardinal;
    MountFlags: TWimMountFlags;
  end;
  PWimMountInfoLevel1 = ^TWimMountInfoLevel1;

  // ADK::wimgapi.h
  [SDKName('WIMMessageCallback')]
  TWimMessageCallback = function (
    [in] MessageId: TWimMessage;
    [in] wParam: WPARAM;
    [in] lParam: LPARAM;
    [in] UserData: Pointer
  ): TWimCallbackError; stdcall;

// ADK::wimgapi.h
[SetsLastError]
[Result: MayReturnNil, ReleaseWith('WIMCloseHandle')]
function WIMCreateFile(
  [in] WimPath: PWideChar;
  [in] DesiredAccess: TWimAccessMask;
  [in] CreationDisposition: TWimCreationDisposition;
  [in] FlagsAndAttributes: TWimFlags;
  [in] CompressionType: TWimCompression;
  [out, opt] CreationResult: PWimCreationResult
): TWimHandle; stdcall; external wimgapi delayed;

var delayed_WIMCreateFile: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMCreateFile';
);

// ADK::wimgapi.h
function WIMCloseHandle(
  [in] hObject: TWimHandle
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMCloseHandle: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMCloseHandle';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMSetTemporaryPath(
  [in] hWim: TWimHandle;
  [in] Path: PWideChar
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMSetTemporaryPath: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMSetTemporaryPath';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMSetReferenceFile(
  [in] hWim: TWimHandle;
  [in] Path: PWideChar;
  [in] Flags: TWimSetReferenceFlags
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMSetReferenceFile: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMSetReferenceFile';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMSplitFile(
  [in] hWim: TWimHandle;
  [in] PartPath: PWideChar;
  [in, out] var PartSize: UInt64;
  [Reserved] Flags: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMSplitFile: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMSplitFile';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMExportImage(
  [in] hImage: TWimHandle;
  [in, Access(WIM_GENERIC_WRITE)] hWim: TWimHandle;
  [in] Flags: TWimExportFlags
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMExportImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMExportImage';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMDeleteImage(
  [in, Access(WIM_GENERIC_WRITE)] hWim: TWimHandle;
  [in] ImageIndex: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMDeleteImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMDeleteImage';
);

// ADK::wimgapi.h
[SetsLastError]
[Result: NumberOfElements]
function WIMGetImageCount(
  [in] hWim: TWimHandle
): Cardinal; stdcall; external wimgapi delayed;

var delayed_WIMGetImageCount: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMGetImageCount';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMGetAttributes(
  [in] hWim: TWimHandle;
  [out, WritesTo] pWimInfo: PWimInfo;
  [in, NumberOfBytes] cbWimInfo: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMGetAttributes: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMGetAttributes';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMSetBootImage(
  [in] hWim: TWimHandle;
  [in, opt] ImageIndex: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMSetBootImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMSetBootImage';
);

// ADK::wimgapi.h
[SetsLastError]
[Result: MayReturnNil, ReleaseWith('WIMCloseHandle')]
function WIMCaptureImage(
  [in, Access(WIM_GENERIC_WRITE)] hWim: TWimHandle;
  [in] Path: PWideChar;
  [in] CaptureFlags: TWimFlags
): TWimHandle; stdcall; external wimgapi delayed;

var delayed_WIMCaptureImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMCaptureImage';
);

// ADK::wimgapi.h
[SetsLastError]
[Result: MayReturnNil, ReleaseWith('WIMCloseHandle')]
function WIMLoadImage(
  [in] hWim: TWimHandle;
  [in] ImageIndex: Cardinal
): TWimHandle; stdcall; external wimgapi delayed;

var delayed_WIMLoadImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMLoadImage';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMApplyImage(
  [in] hImage: TWimHandle;
  [in, opt] Path: PWideChar;
  [in] ApplyFlags: TWimFlags
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMApplyImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMApplyImage';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMGetImageInformation(
  [in] hImage: TWimHandle;
  [out, ReleaseWith('LocalFree')] out ImageInfo: PWideChar;
  [out, NumberOfBytes] out cbImageInfo: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMGetImageInformation: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMGetImageInformation';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMSetImageInformation(
  [in] hImage: TWimHandle;
  [in, ReadsFrom] ImageInfo: PWideChar;
  [in, NumberOfBytes] cbImageInfo: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMSetImageInformation: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMSetImageInformation';
);

// ADK::wimgapi.h
[SetsLastError]
[Result: NumberOfElements]
function WIMGetMessageCallbackCount(
  [in, opt] hWim: TWimHandle
): Cardinal; stdcall; external wimgapi delayed;

var delayed_WIMGetMessageCallbackCount: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMGetMessageCallbackCount';
);

// ADK::wimgapi.h
[SetsLastError]
[Result: ReleaseWith('WIMUnregisterMessageCallback')]
function WIMRegisterMessageCallback(
  [in, opt] hWim: TWimHandle;
  [in] MessageProc: TWimMessageCallback;
  [in, opt] UserData: Pointer
): Cardinal; stdcall; external wimgapi delayed;

var delayed_WIMRegisterMessageCallback: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMRegisterMessageCallback';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMUnregisterMessageCallback(
  [in, opt] hWim: TWimHandle;
  [in, opt] MessageProc: TWimMessageCallback
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMUnregisterMessageCallback: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMUnregisterMessageCallback';
);

// ADK::wimgapi.h
[SetsLastError]
[Result: ReleaseWith('WIMUnmountImage')]
function WIMMountImage(
  [in] MountPath: PWideChar;
  [in] WimFileName: PWideChar;
  [in] ImageIndex: Cardinal;
  [in, opt] TempPath: PWideChar
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMMountImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMMountImage';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMUnmountImage(
  [in] MountPath: PWideChar;
  [in, opt] WimFileName: PWideChar;
  [in, opt] ImageIndex: Cardinal;
  [in] CommitChanges: LongBool
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMUnmountImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMUnmountImage';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMGetMountedImages(
  [out, WritesTo] MountList: PWimMountListArray;
  [in, out, NumberOfBytes] var MountListLength: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMGetMountedImages: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMGetMountedImages';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMMountImageHandle(
  [in, Access(WIM_GENERIC_MOUNT)] hImage: TWimHandle;
  [in] MountPath: PWideChar;
  [in] MountFlags: TWimFlags
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMMountImageHandle: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMMountImageHandle';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMRemountImage(
  [in] MountPath: PWideChar;
  [Reserved] Flags: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMRemountImage: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMRemountImage';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMCommitImageHandle(
  [in, Access(WIM_GENERIC_MOUNT)] hImage: TWimHandle;
  [in] CommitFlags: TWimCommitFlags;
  [out, opt] phNewImageHandle: PWimHandle
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMCommitImageHandle: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMCommitImageHandle';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMUnmountImageHandle(
  [in, Access(WIM_GENERIC_MOUNT)] hImage: TWimHandle;
  [Reserved] UnmountFlags: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMUnmountImageHandle: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMUnmountImageHandle';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMGetMountedImageInfo(
  [in] InfoLevelId: TMountedImageInfoLevels;
  [out] out dwImageCount: Cardinal;
  [out, WritesTo] MountInfo: Pointer;
  [in, NumberOfBytes] MountInfoLength: Cardinal;
  [out, NumberOfBytes] ReturnLength: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMGetMountedImageInfo: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMGetMountedImageInfo';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMGetMountedImageInfoFromHandle(
  [in] hImage: TWimHandle;
  [in] InfoLevelId: TMountedImageInfoLevels;
  [out, WritesTo] MountInfo: Pointer;
  [in, NumberOfBytes] MountInfoLength: Cardinal;
  [out, NumberOfBytes] ReturnLength: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMGetMountedImageInfoFromHandle: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMGetMountedImageInfoFromHandle';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMGetMountedImageHandle(
  [in] MountPath: PWideChar;
  [in] Flags: TWimFlags;
  [out, ReleaseWith('WIMCloseHandle')] out hWimHandle: TWimHandle;
  [out, ReleaseWith('WIMCloseHandle')] out hImageHandle: TWimHandle
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMGetMountedImageHandle: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMGetMountedImageHandle';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMDeleteImageMounts(
  [in] DeleteFlags: TWimDeleteFlags
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMDeleteImageMounts: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMDeleteImageMounts';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMRegisterLogFile(
  [in] LogFile: PWideChar;
  [Reserved] Flags: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMRegisterLogFile: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMRegisterLogFile';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMUnregisterLogFile(
  [in] LogFile: PWideChar
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMUnregisterLogFile: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMUnregisterLogFile';
);

// ADK::wimgapi.h
[SetsLastError]
function WIMExtractImagePath(
  [in] hImage: TWimHandle;
  [in] ImagePath: PWideChar;
  [in] DestinationPath: PWideChar;
  [Reserved] ExtractFlags: Cardinal
): LongBool; stdcall; external wimgapi delayed;

var delayed_WIMExtractImagePath: TDelayedLoadFunction = (
  Dll: @delayed_wimgapi;
  FunctionName: 'WIMExtractImagePath';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
