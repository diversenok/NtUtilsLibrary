unit Ntapi.ntioapi;

{
  This file defines types and functions for working with files via Native API.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, DelphiApi.Reflection, Ntapi.Versions;

const
  // SDK::winnt.h - file access masks
  FILE_READ_DATA = $0001;            // file & pipe
  FILE_LIST_DIRECTORY = $0001;       // directory
  FILE_WRITE_DATA = $0002;           // file & pipe
  FILE_ADD_FILE = $0002;             // directory
  FILE_APPEND_DATA = $0004;          // file
  FILE_ADD_SUBDIRECTORY = $0004;     // directory
  FILE_CREATE_PIPE_INSTANCE = $0004; // named pipe
  FILE_READ_EA = $0008;              // file & directory
  FILE_WRITE_EA = $0010;             // file & directory
  FILE_EXECUTE = $0020;              // file
  FILE_TRAVERSE = $0020;             // directory
  FILE_DELETE_CHILD = $0040;         // directory
  FILE_READ_ATTRIBUTES = $0080;      // all
  FILE_WRITE_ATTRIBUTES = $0100;     // all
  FILE_ALL_ACCESS = STANDARD_RIGHTS_ALL or $1FF;

  // SDK::winnt.h - sharing options
  FILE_SHARE_READ = $00000001;
  FILE_SHARE_WRITE = $00000002;
  FILE_SHARE_DELETE = $00000004;
  FILE_SHARE_ALL = FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE;

  // SDK::winnt.h - file attributes
  FILE_ATTRIBUTE_READONLY = $00000001;
  FILE_ATTRIBUTE_HIDDEN = $00000002;
  FILE_ATTRIBUTE_SYSTEM = $00000004;
  FILE_ATTRIBUTE_DIRECTORY = $00000010;
  FILE_ATTRIBUTE_ARCHIVE = $00000020;
  FILE_ATTRIBUTE_DEVICE = $00000040;
  FILE_ATTRIBUTE_NORMAL = $00000080;
  FILE_ATTRIBUTE_TEMPORARY = $00000100;
  FILE_ATTRIBUTE_SPARSE_FILE = $00000200;
  FILE_ATTRIBUTE_REPARSE_POINT = $00000400;
  FILE_ATTRIBUTE_COMPRESSED = $00000800;
  FILE_ATTRIBUTE_OFFLINE = $00001000;
  FILE_ATTRIBUTE_NOT_CONTENT_INDEXED = $00002000;
  FILE_ATTRIBUTE_ENCRYPTED = $00004000;
  FILE_ATTRIBUTE_INTEGRITY_STREAM = $00008000;
  FILE_ATTRIBUTE_VIRTUAL = $00010000;
  FILE_ATTRIBUTE_NO_SCRUB_DATA = $00020000;
  FILE_ATTRIBUTE_EA = $00040000;
  FILE_ATTRIBUTE_PINNED = $00080000;
  FILE_ATTRIBUTE_UNPINNED = $00100000;
  FILE_ATTRIBUTE_RECALL_ON_OPEN = $00040000;
  FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS = $00400000;

  // WDK::wdm.h - create/open flags
  FILE_ASYNCHRONOUS_IO = $00000000; // helper flag
  FILE_DIRECTORY_FILE = $00000001;
  FILE_WRITE_THROUGH = $00000002;
  FILE_SEQUENTIAL_ONLY = $00000004;
  FILE_NO_INTERMEDIATE_BUFFERING = $00000008;
  FILE_SYNCHRONOUS_IO_ALERT = $00000010;
  FILE_SYNCHRONOUS_IO_NONALERT = $00000020;
  FILE_SYNCHRONOUS_FLAGS = $00000030; // helper flag
  FILE_NON_DIRECTORY_FILE = $00000040;
  FILE_CREATE_TREE_CONNECTION = $00000080;
  FILE_COMPLETE_IF_OPLOCKED = $00000100;
  FILE_NO_EA_KNOWLEDGE = $00000200;
  FILE_OPEN_FOR_RECOVERY = $00000400;
  FILE_RANDOM_ACCESS = $00000800;
  FILE_DELETE_ON_CLOSE = $00001000;
  FILE_OPEN_BY_FILE_ID = $00002000;
  FILE_OPEN_FOR_BACKUP_INTENT = $00004000;
  FILE_NO_COMPRESSION = $00008000;
  FILE_OPEN_REQUIRING_OPLOCK = $00010000;
  FILE_DISALLOW_EXCLUSIVE = $00020000;
  FILE_RESERVE_OPFILTER = $00100000;
  FILE_OPEN_REPARSE_POINT = $00200000;
  FILE_OPEN_NO_RECALL = $00400000;
  FILE_OPEN_FOR_FREE_SPACE_QUERY = $00800000;
  FILE_SESSION_AWARE = $00040000; // Win 8+

  // WDK::wdm.h - special ByteOffset for read/write operations
  FILE_USE_FILE_POINTER_POSITION = UInt64($FFFFFFFFFFFFFFFE);
  FILE_WRITE_TO_END_OF_FILE = UInt64($FFFFFFFFFFFFFFFF);

  // WDK::ntifs.h - flags for renaming
  FILE_RENAME_REPLACE_IF_EXISTS = $00000001;                    // Win 10 RS1+
  FILE_RENAME_POSIX_SEMANTICS = $00000002;                      // Win 10 RS1+
  FILE_RENAME_SUPPRESS_PIN_STATE_INHERITANCE = $00000004;       // Win 10 RS3+
  FILE_RENAME_SUPPRESS_STORAGE_RESERVE_INHERITANCE = $00000008; // Win 10 RS5+
  FILE_RENAME_NO_INCREASE_AVAILABLE_SPACE = $00000010;          // Win 10 RS5+
  FILE_RENAME_NO_DECREASE_AVAILABLE_SPACE = $00000020;          // Win 10 RS5+
  FILE_RENAME_IGNORE_READONLY_ATTRIBUTE = $00000040;            // Win 10 RS5+
  FILE_RENAME_FORCE_RESIZE_TARGET_SR = $00000080;               // Win 10 19H1+
  FILE_RENAME_FORCE_RESIZE_SOURCE_SR = $00000100;               // Win 10 19H1+

  // WDK::ntifs.h - flags for creating a link
  FILE_LINK_REPLACE_IF_EXISTS = $00000001;                      // Win 10 RS1+
  FILE_LINK_POSIX_SEMANTICS = $00000002;                        // Win 10 RS1+
  FILE_LINK_SUPPRESS_STORAGE_RESERVE_INHERITANCE = $00000008;   // Win 10 RS5+
  FILE_LINK_NO_INCREASE_AVAILABLE_SPACE = $00000010;            // Win 10 RS5+
  FILE_LINK_NO_DECREASE_AVAILABLE_SPACE = $00000020;            // Win 10 RS5+
  FILE_LINK_IGNORE_READONLY_ATTRIBUTE = $00000040;              // Win 10 RS5+
  FILE_LINK_FORCE_RESIZE_TARGET_SR = $00000080;                 // Win 10 19H1+
  FILE_LINK_FORCE_RESIZE_SOURCE_SR = $00000100;                 // Win 10 19H1+

  // WDK::ntddk.h - disposition flags
  FILE_DISPOSITION_DO_NOT_DELETE = $00000000;             // Win 10 RS1+
  FILE_DISPOSITION_DELETE = $00000001;                    // Win 10 RS1+
  FILE_DISPOSITION_POSIX_SEMANTICS = $00000002;           // Win 10 RS1+
  FILE_DISPOSITION_FORCE_IMAGE_SECTION_CHECK = $00000004; // Win 10 RS1+
  FILE_DISPOSITION_ON_CLOSE = $00000008;                  // Win 10 RS1+
  FILE_DISPOSITION_IGNORE_READONLY_ATTRIBUTE = $00000010; // Win 10 RS5+

  // File System

  // WDK::wdm.h - device characteristics
  FILE_REMOVABLE_MEDIA = $00000001;
  FILE_READ_ONLY_DEVICE = $00000002;
  FILE_FLOPPY_DISKETTE = $00000004;
  FILE_WRITE_ONCE_MEDIA = $00000008;
  FILE_REMOTE_DEVICE = $00000010;
  FILE_DEVICE_IS_MOUNTED = $00000020;
  FILE_VIRTUAL_VOLUME = $00000040;
  FILE_AUTOGENERATED_DEVICE_NAME = $00000080;
  FILE_DEVICE_SECURE_OPEN = $00000100;
  FILE_CHARACTERISTIC_PNP_DEVICE = $00000800;
  FILE_CHARACTERISTIC_TS_DEVICE = $00001000;
  FILE_CHARACTERISTIC_WEBDAV_DEVICE = $00002000;
  FILE_CHARACTERISTIC_CSV = $00010000;
  FILE_DEVICE_ALLOW_APPCONTAINER_TRAVERSAL = $00020000;
  FILE_PORTABLE_DEVICE = $00040000;

  // WDK::ntifs.h - file system attributes
  FILE_CASE_SENSITIVE_SEARCH = $00000001;
  FILE_CASE_PRESERVED_NAMES = $00000002;
  FILE_UNICODE_ON_DISK = $00000004;
  FILE_PERSISTENT_ACLS = $00000008;
  FILE_FILE_COMPRESSION = $00000010;
  FILE_VOLUME_QUOTAS = $00000020;
  FILE_SUPPORTS_SPARSE_FILES = $00000040;
  FILE_SUPPORTS_REPARSE_POINTS = $00000080;
  FILE_SUPPORTS_REMOTE_STORAGE = $00000100;
  FILE_RETURNS_CLEANUP_RESULT_INFO = $00000200;
  FILE_SUPPORTS_POSIX_UNLINK_RENAME = $00000400;
  FILE_VOLUME_IS_COMPRESSED = $00008000;
  FILE_SUPPORTS_OBJECT_IDS = $00010000;
  FILE_SUPPORTS_ENCRYPTION = $00020000;
  FILE_NAMED_STREAMS = $00040000;
  FILE_READ_ONLY_VOLUME = $00080000;
  FILE_SEQUENTIAL_WRITE_ONCE = $00100000;
  FILE_SUPPORTS_TRANSACTIONS = $00200000;
  FILE_SUPPORTS_HARD_LINKS = $00400000;
  FILE_SUPPORTS_EXTENDED_ATTRIBUTES = $00800000;
  FILE_SUPPORTS_OPEN_BY_FILE_ID = $01000000;
  FILE_SUPPORTS_USN_JOURNAL = $02000000;
  FILE_SUPPORTS_INTEGRITY_STREAMS = $04000000;
  FILE_SUPPORTS_BLOCK_REFCOUNTING = $08000000;
  FILE_SUPPORTS_SPARSE_VDL = $10000000;
  FILE_DAX_VOLUME = $20000000;
  FILE_SUPPORTS_GHOSTING = $40000000;

  // WDK::ntifs.h - known reparse tags
  IO_REPARSE_TAG_MOUNT_POINT = $A0000003;
  IO_REPARSE_TAG_SIS = $80000007;
  IO_REPARSE_TAG_WIM = $80000008;
  IO_REPARSE_TAG_DFS = $8000000A;
  IO_REPARSE_TAG_FILTER_MANAGER = $8000000B;
  IO_REPARSE_TAG_SYMLINK = $A000000C;
  IO_REPARSE_TAG_DFSR = $80000012;
  IO_REPARSE_TAG_DEDUP = $80000013;
  IO_REPARSE_TAG_APPXSTRM = $C0000014;
  IO_REPARSE_TAG_NFS = $80000014;
  IO_REPARSE_TAG_DFM = $80000016;
  IO_REPARSE_TAG_WOF = $80000017;
  IO_REPARSE_TAG_WCI = $80000018;
  IO_REPARSE_TAG_WCI_1 = $90001018;
  IO_REPARSE_TAG_GLOBAL_REPARSE = $A0000019;
  IO_REPARSE_TAG_CLOUD = $9000001A;
  IO_REPARSE_TAG_APPEXECLINK = $8000001B;
  IO_REPARSE_TAG_PROJFS = $9000001C;
  IO_REPARSE_TAG_LX_SYMLINK = $A000001D;
  IO_REPARSE_TAG_STORAGE_SYNC = $8000001E;
  IO_REPARSE_TAG_WCI_TOMBSTONE = $A000001F;
  IO_REPARSE_TAG_UNHANDLED = $80000020;
  IO_REPARSE_TAG_PROJFS_TOMBSTONE = $A0000022;
  IO_REPARSE_TAG_AF_UNIX = $80000023;
  IO_REPARSE_TAG_LX_FIFO = $80000024;
  IO_REPARSE_TAG_LX_CHR = $80000025;
  IO_REPARSE_TAG_LX_BLK = $80000026;
  IO_REPARSE_TAG_WCI_LINK = $A0000027;
  IO_REPARSE_TAG_WCI_LINK_1 = $A0001027;

  // Notifications

  // WDK::ntifs.h - notification filters
  FILE_NOTIFY_CHANGE_FILE_NAME = $00000001;
  FILE_NOTIFY_CHANGE_DIR_NAME = $00000002;
  FILE_NOTIFY_CHANGE_NAME = $0000000;
  FILE_NOTIFY_CHANGE_ATTRIBUTES = $00000004;
  FILE_NOTIFY_CHANGE_SIZE = $00000008;
  FILE_NOTIFY_CHANGE_LAST_WRITE = $00000010;
  FILE_NOTIFY_CHANGE_LAST_ACCESS = $00000020;
  FILE_NOTIFY_CHANGE_CREATION = $00000040;
  FILE_NOTIFY_CHANGE_EA = $0000008;
  FILE_NOTIFY_CHANGE_SECURITY = $00000100;
  FILE_NOTIFY_CHANGE_STREAM_NAME = $0000020;
  FILE_NOTIFY_CHANGE_STREAM_SIZE = $0000040;
  FILE_NOTIFY_CHANGE_STREAM_WRITE = $0000080;

  // Pipe

  // WDK::ntifs.h - named pipe types
  FILE_PIPE_BYTE_STREAM_TYPE = $00000000;
  FILE_PIPE_MESSAGE_TYPE = $00000001;
  FILE_PIPE_ACCEPT_REMOTE_CLIENTS = $00000000;
  FILE_PIPE_REJECT_REMOTE_CLIENTS = $00000002;

  // IO Completion

  // PHNT::ntioapi.h - I/O completion access masks
  IO_COMPLETION_QUERY_STATE = $0001;
  IO_COMPLETION_MODIFY_STATE = $0002;
  IO_COMPLETION_ALL_ACCESS = STANDARD_RIGHTS_ALL or $03;

type
  TFileId = type UInt64;

  [FriendlyName('file object'), ValidMask(FILE_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(FILE_READ_DATA, 'Read Data / List Directory')]
  [FlagName(FILE_WRITE_DATA, 'Write Data / Add File')]
  [FlagName(FILE_APPEND_DATA, 'Append Data / Add Sub-directory / Create Pipe Instance')]
  [FlagName(FILE_READ_EA, 'Read Extended Attributes')]
  [FlagName(FILE_WRITE_EA, 'Write Extended Attributes')]
  [FlagName(FILE_EXECUTE, 'Execute / Traverse')]
  [FlagName(FILE_READ_ATTRIBUTES, 'Read Attributes')]
  [FlagName(FILE_WRITE_ATTRIBUTES, 'Write Attributes')]
  TFileAccessMask = type TAccessMask;

  [FriendlyName('file'), ValidMask(FILE_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(FILE_READ_DATA, 'Read Data')]
  [FlagName(FILE_WRITE_DATA, 'Write Data')]
  [FlagName(FILE_APPEND_DATA, 'Append Data')]
  [FlagName(FILE_READ_EA, 'Read Extended Attributes')]
  [FlagName(FILE_WRITE_EA, 'Write Extended Attributes')]
  [FlagName(FILE_EXECUTE, 'Execute')]
  [FlagName(FILE_READ_ATTRIBUTES, 'Read Attributes')]
  [FlagName(FILE_WRITE_ATTRIBUTES, 'Write attributes')]
  TIoFileAccessMask = type TAccessMask;

  [FriendlyName('directory'), ValidMask(FILE_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(FILE_LIST_DIRECTORY, 'List Directory')]
  [FlagName(FILE_ADD_FILE, 'Add File')]
  [FlagName(FILE_ADD_SUBDIRECTORY, 'Add Sub-directory')]
  [FlagName(FILE_READ_EA, 'Read Extended Attributes')]
  [FlagName(FILE_WRITE_EA, 'Write Extended Attributes')]
  [FlagName(FILE_TRAVERSE, 'Traverse')]
  [FlagName(FILE_DELETE_CHILD, 'Delete Child')]
  [FlagName(FILE_READ_ATTRIBUTES, 'Read Attributes')]
  [FlagName(FILE_WRITE_ATTRIBUTES, 'Write Attributes')]
  TIoDirectoryAccessMask = type TAccessMask;

  [FriendlyName('pipe'), ValidMask(FILE_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(FILE_READ_DATA, 'Read Data')]
  [FlagName(FILE_WRITE_DATA, 'Write Data')]
  [FlagName(FILE_CREATE_PIPE_INSTANCE, 'Create Pipe Instance')]
  [FlagName(FILE_READ_ATTRIBUTES, 'Read Attributes')]
  [FlagName(FILE_WRITE_ATTRIBUTES, 'Write Attributes')]
  TIoPipeAccessMask = type TAccessMask;

  [FriendlyName('I/O completion')]
  [ValidMask(IO_COMPLETION_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(IO_COMPLETION_QUERY_STATE, 'Query')]
  [FlagName(IO_COMPLETION_MODIFY_STATE, 'Modify')]
  TIoCompeletionAccessMask = type TAccessMask;

  [FlagName(FILE_SHARE_READ, 'Share Read')]
  [FlagName(FILE_SHARE_WRITE, 'Share Write')]
  [FlagName(FILE_SHARE_DELETE, 'Share Delete')]
  TFileShareMode = type Cardinal;

  [SubEnum(FILE_SYNCHRONOUS_FLAGS, FILE_ASYNCHRONOUS_IO, 'Asynchronous')]
  [SubEnum(FILE_SYNCHRONOUS_FLAGS, FILE_SYNCHRONOUS_IO_ALERT, 'Synchronous Alert')]
  [SubEnum(FILE_SYNCHRONOUS_FLAGS, FILE_SYNCHRONOUS_IO_NONALERT, 'Synchronous Non-Alert')]
  [FlagName(FILE_DIRECTORY_FILE, 'Directory')]
  [FlagName(FILE_WRITE_THROUGH, 'Write Through')]
  [FlagName(FILE_SEQUENTIAL_ONLY, 'Sequential Only')]
  [FlagName(FILE_NO_INTERMEDIATE_BUFFERING, 'No Intermediate Buffering')]
  [FlagName(FILE_NON_DIRECTORY_FILE, 'Non-directory')]
  [FlagName(FILE_CREATE_TREE_CONNECTION, 'Create Tree Connection')]
  [FlagName(FILE_COMPLETE_IF_OPLOCKED, 'Complete If Oplocked')]
  [FlagName(FILE_NO_EA_KNOWLEDGE, 'No EA Knowledge')]
  [FlagName(FILE_OPEN_FOR_RECOVERY, 'Open For Recovery')]
  [FlagName(FILE_RANDOM_ACCESS, 'Random Access')]
  [FlagName(FILE_DELETE_ON_CLOSE, 'Delete On Close')]
  [FlagName(FILE_OPEN_BY_FILE_ID, 'Open By ID')]
  [FlagName(FILE_OPEN_FOR_BACKUP_INTENT, 'Open For Backup')]
  [FlagName(FILE_NO_COMPRESSION, 'No Compression')]
  [FlagName(FILE_OPEN_REQUIRING_OPLOCK, 'Open Requiring Oplock')]
  [FlagName(FILE_DISALLOW_EXCLUSIVE, 'Disallow Exclusive')]
  [FlagName(FILE_RESERVE_OPFILTER, 'Reserve Opfilter')]
  [FlagName(FILE_OPEN_REPARSE_POINT, 'Open Reparse Point')]
  [FlagName(FILE_OPEN_NO_RECALL, 'Open No Recall')]
  [FlagName(FILE_OPEN_FOR_FREE_SPACE_QUERY, 'Open For Free Space Query')]
  [FlagName(FILE_SESSION_AWARE, 'Session Aware')]
  TFileOpenOptions = type Cardinal;

  // WDK::wdm.h
  [NamingStyle(nsSnakeCase, 'FILE')]
  TFileDisposition = (
    FILE_SUPERSEDE = 0,
    FILE_OPEN = 1,
    FILE_CREATE = 2,
    FILE_OPEN_IF = 3,
    FILE_OVERWRITE = 4,
    FILE_OVERWRITE_IF = 5
  );

  // WDK::wdm.h
  [NamingStyle(nsSnakeCase, 'FILE')]
  TFileIoStatusResult = (
    FILE_SUPERSEDED = 0,
    FILE_OPENED = 1,
    FILE_CREATED = 2,
    FILE_OVERWRITTEN = 3,
    FILE_EXISTS = 4,
    FILE_DOES_NOT_EXIST = 5
  );
  PFileIoStatusResult = ^TFileIoStatusResult;

  // WDK::wdm.h
  [SDKName('IO_STATUS_BLOCK')]
  TIoStatusBlock = record
  case Integer of
    0: (Pointer: Pointer; Result: TFileIoStatusResult);
    1: (Status: NTSTATUS; Information: NativeUInt);
  end;
  PIoStatusBlock = ^TIoStatusBlock;

  // WDK::wdm.h
  [SDKName('PIO_APC_ROUTINE')]
  TIoApcRoutine = procedure (
    [in] ApcContext: Pointer;
    const IoStatusBlock: TIoStatusBlock;
    [Reserved] Reserved: Cardinal
  ); stdcall;

  // PHNT::ntioapi.h
  [SDKName('FILE_IO_COMPLETION_INFORMATION')]
  TFileIoCompletionInformation = record
    KeyContext: Pointer;
    ApcContext: Pointer;
    IoStatusBlock: TIoStatusBlock;
  end;
  PFileIoCompletionInformation = ^TFileIoCompletionInformation;

  // WDK::wdm.h
  [SDKName('FILE_SEGMENT_ELEMENT')]
  TFileSegmentElement = record
    Buffer: Pointer;
    Alignment: UInt64;
  end;
  PFileSegmentElement = ^TFileSegmentElement;

  // Files

  // WDK::wdm.h (q - query; s - set; d - directory)
  [NamingStyle(nsCamelCase, 'File'), Range(1)]
  TFileInformationClass = (
    FileReserved = 0,
    FileDirectoryInformation = 1,     // d: TFileDirectoryInformation
    FileFullDirectoryInformation = 2, // d: TFileFullDirInformation
    FileBothDirectoryInformation = 3, // d:
    FileBasicInformation = 4,         // q, s: TFileBasicInformation
    FileStandardInformation = 5,      // q: TFileStandardInformation[Ex]
    FileInternalInformation = 6,      // q: TFileId
    FileEaInformation = 7,            // q: Cardinal (EaSize)
    FileAccessInformation = 8,        // q: TAccessMask
    FileNameInformation = 9,          // q: TFileNameInformation
    FileRenameInformation = 10,       // s: TFileRenameInformation
    FileLinkInformation = 11,         // s: TFileLinkInformation
    FileNamesInformation = 12,        // q, d: TFileNamesInformation
    FileDispositionInformation = 13,  // s: Boolean (DeleteFile)
    FilePositionInformation = 14,     // q, s: UInt64 (CurrentByteOffset)
    FileFullEaInformation = 15,       // q: TFileFullEaInformation
    FileModeInformation = 16,         // q, s: TFileMode
    FileAlignmentInformation = 17,    // q: Cardinal (AlignmentRequirement)
    FileAllInformation = 18,          // q: TFileAllInformation
    FileAllocationInformation = 19,   // s: UInt64 (AllocationSize)
    FileEndOfFileInformation = 20,    // s: UInt64 (EndOfFile)
    FileAlternateNameInformation = 21,// q: TFileNameInformation
    FileStreamInformation = 22,       // q: TFileStreamInformation
    FilePipeInformation = 23,         // q, s: TFilePipeInformation
    FilePipeLocalInformation = 24,    // q: TFilePipeLocalInformation
    FilePipeRemoteInformation = 25,   // q, s: TFilePipeRemoteInformation
    FileMailslotQueryInformation = 26,// q: TFileMailsoltQueryInformation
    FileMailslotSetInformation = 27,  // s: TULargeInteger (ReadTimeout)
    FileCompressionInformation = 28,  // q: TFileCompressionInformation
    FileObjectIdInformation = 29,     // q, s, d: TFileObjectIdInformation
    FileCompletionInformation = 30,   // s: TFileCompletionInformation
    FileMoveClusterInformation = 31,  // s:
    FileQuotaInformation = 32,        // q, s:
    FileReparsePointInformation = 33, // q, d: TFileReparsePointInformation
    FileNetworkOpenInformation = 34,  // q: TFileNetworkOpenInformation
    FileAttributeTagInformation = 35, // q: TFileAttributeTagInformation
    FileTrackingInformation = 36,     // s:
    FileIdBothDirectoryInformation = 37, // q, d:
    FileIdFullDirectoryInformation = 38, // q, d:
    FileValidDataLengthInformation = 39, // s: UInt64 (ValidDataLength)
    FileShortNameInformation = 40,       // s: TFileNameInformation
    FileIoCompletionNotificationInformation = 41, // q, s: Cardinal
    FileIoStatusBlockRangeInformation = 42, // s:
    FileIoPriorityHintInformation = 43,  // q, s: TIoPriorityHint
    FileSfioReserveInformation = 44,     // q, s:
    FileSfioVolumeInformation = 45,      // q:
    FileHardLinkInformation = 46,        // q: TFileLinksInformation
    FileProcessIdsUsingFileInformation = 47, // q: TFileProcessIdsUsingFileInformation
    FileNormalizedNameInformation = 48,  // q: TFileNameInformation
    FileNetworkPhysicalNameInformation = 49,
    FileIdGlobalTxDirectoryInformation = 50,
    FileIsRemoteDeviceInformation = 51,  // q: Boolean (IsRemote)
    FileUnusedInformation = 52,
    FileNumaNodeInformation = 53,
    FileStandardLinkInformation = 54,    // q: TFileStandardLinkInformation
    FileRemoteProtocolInformation = 55,
    FileRenameInformationBypassAccessCheck = 56, // Kernel only
    FileLinkInformationBypassAccessCheck = 57,   // Kernel only
    FileVolumeNameInformation = 58,
    FileIdInformation = 59,
    FileIdExtdDirectoryInformation = 60,
    FileReplaceCompletionInformation = 61,
    FileHardLinkFullIdInformation = 62,
    FileIdExtdBothDirectoryInformation = 63,
    FileDispositionInformationEx = 64,       // s: TFileDispositionFlags, Win 10 RS1+
    FileRenameInformationEx = 65,            // s: TFileRenameInformationEx, Win 10 RS1+
    FileRenameInformationExBypassAccessCheck = 66, // Kernel only
    FileDesiredStorageClassInformation = 67,
    FileStatInformation = 68,
    FileMemoryPartitionInformation = 69,
    FileStatLxInformation = 70,
    FileCaseSensitiveInformation = 71,
    FileLinkInformationEx = 72,              // s: TFileLinkInformationEx, Win 10 RS1+
    FileLinkInformationExBypassAccessCheck = 73, // Kernel only
    FileStorageReserveIdInformation = 74,
    FileCaseSensitiveInformationForceAccessCheck = 75,
    FileKnownFolderInformation = 76
  );

  [FlagName(FILE_ATTRIBUTE_READONLY, 'Readonly')]
  [FlagName(FILE_ATTRIBUTE_HIDDEN, 'Hidden')]
  [FlagName(FILE_ATTRIBUTE_SYSTEM, 'System')]
  [FlagName(FILE_ATTRIBUTE_DIRECTORY, 'Directory')]
  [FlagName(FILE_ATTRIBUTE_ARCHIVE, 'Archive')]
  [FlagName(FILE_ATTRIBUTE_DEVICE, 'Device')]
  [FlagName(FILE_ATTRIBUTE_NORMAL, 'Normal')]
  [FlagName(FILE_ATTRIBUTE_TEMPORARY, 'Temporary')]
  [FlagName(FILE_ATTRIBUTE_SPARSE_FILE, 'Sparse')]
  [FlagName(FILE_ATTRIBUTE_REPARSE_POINT, 'Reparse Point')]
  [FlagName(FILE_ATTRIBUTE_COMPRESSED, 'Compressed')]
  [FlagName(FILE_ATTRIBUTE_OFFLINE, 'Offline')]
  [FlagName(FILE_ATTRIBUTE_NOT_CONTENT_INDEXED, 'Not Indexed')]
  [FlagName(FILE_ATTRIBUTE_ENCRYPTED, 'Encrypted')]
  [FlagName(FILE_ATTRIBUTE_INTEGRITY_STREAM, 'Integrity Stream')]
  [FlagName(FILE_ATTRIBUTE_VIRTUAL, 'Virtual')]
  [FlagName(FILE_ATTRIBUTE_NO_SCRUB_DATA, 'No Scrub Data')]
  [FlagName(FILE_ATTRIBUTE_EA, 'Extended Attribute')]
  [FlagName(FILE_ATTRIBUTE_PINNED, 'Pinned')]
  [FlagName(FILE_ATTRIBUTE_UNPINNED, 'Unpinned')]
  [FlagName(FILE_ATTRIBUTE_RECALL_ON_OPEN, 'Recall On Open')]
  [FlagName(FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS, 'Recall On Data Access')]
  TFileAttributes = type Cardinal;

  // WDK::ntifs.h
  [SDKName('FILE_TIMESTAMPS')]
  TFileTimestamps = record
    CreationTime: TLargeInteger;
    LastAccessTime: TLargeInteger;
    LastWriteTime: TLargeInteger;
    ChangeTime: TLargeInteger;
  end;

  // WDK::ntifs.h - info class 1, use with NtQueryDirectoryFile
  [SDKName('FILE_DIRECTORY_INFORMATION')]
  TFileDirectoryInformation = record
    [Unlisted] NextEntryOffset: Cardinal;
    FileIndex: Cardinal;
    [Aggregate] Times: TFileTimestamps;
    [Bytes] EndOfFile: UInt64;
    [Bytes] AllocationSize: UInt64;
    FileAttributes: TFileAttributes;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileDirectoryInformation = ^TFileDirectoryInformation;

  // WDK::ntifs.h - info class 2, use with NtQueryDirectoryFile
  [SDKName('FILE_FULL_DIR_INFORMATION')]
  TFileFullDirInformation = record
    [Unlisted] NextEntryOffset: Cardinal;
    FileIndex: Cardinal;
    [Aggregate] Times: TFileTimestamps;
    [Bytes] EndOfFile: UInt64;
    [Bytes] AllocationSize: UInt64;
    FileAttributes: TFileAttributes;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    EaSize: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;

  // WDK::wdm.h - info class 4
  [SDKName('FILE_BASIC_INFORMATION')]
  TFileBasicInformation = record
    [Aggregate] Times: TFileTimestamps;
    FileAttributes: TFileAttributes;
  end;
  PFileBasicInformation = ^TFileBasicInformation;

  // WDK::wdm.h - info class 5
  [SDKName('FILE_STANDARD_INFORMATION')]
  TFileStandardInformation = record
    [Bytes] AllocationSize: UInt64;
    [Bytes] EndOfFile: UInt64;
    NumberOfLinks: Cardinal;
    DeletePending: Boolean;
    Directory: Boolean;
  end;
  PFileStandardInformation = ^TFileStandardInformation;

  // WDK::wdm.h - info class 4
  [MinOSVersion(OsWin10TH1)]
  [SDKName('FILE_STANDARD_INFORMATION_EX')]
  TFileStandardInformationEx = record
    [Aggregate] Standard: TFileStandardInformation;
    AlternateStream: Boolean;
    MetadataAttribute: Boolean;
  end;
  PFileStandardInformationEx = ^TFileStandardInformationEx;

  // WDK::ntddk.h - info classes 9, 21, 40, 48
  [SDKName('FILE_NAME_INFORMATION')]
  TFileNameInformation = record
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileNameInformation = ^TFileNameInformation;

  // WDK::ntifs.h - info class 10
  [SDKName('FILE_RENAME_INFORMATION')]
  TFileRenameInformation = record
    ReplaceIfExists: Boolean;
    RootDirectory: THandle;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileRenameInformation = ^TFileRenameInformation;

  // WDK::ntifs.h - info class 11
  [SDKName('FILE_LINK_INFORMATION')]
  TFileLinkInformation = TFileRenameInformation;
  PFileLinkInformation = ^TFileLinkInformation;

  // WDK::ntifs.h - info class 12
  [SDKName('FILE_NAMES_INFORMATION')]
  TFileNamesInformation = record
    [Unlisted] NextEntryOffset: Cardinal;
    FileIndex: Cardinal;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileNamesInformation = ^TFileNamesInformation;

  // WDK::wdm.h - info class 15
  [SDKName('FILE_FULL_EA_INFORMATION')]
  TFileFullEaInformation = record
    [Unlisted] NextEntryOffset: Cardinal;
    [Hex] Flags: Byte;
    [Counter(ctBytes)] EaNameLength: Byte;
    EaValueLength: Word;
    EaName: TAnysizeArray<AnsiChar>;
  end;
  PFileFullEaInformation = ^TFileFullEaInformation;

  // WDK::ntifs.h - info class 16
  [FlagName(FILE_WRITE_THROUGH, 'Write Through')]
  [FlagName(FILE_SEQUENTIAL_ONLY, 'Sequential Only')]
  [FlagName(FILE_NO_INTERMEDIATE_BUFFERING, 'No Intermediate Buffering')]
  [FlagName(FILE_SYNCHRONOUS_IO_ALERT, 'Synchronous IO Alert')]
  [FlagName(FILE_SYNCHRONOUS_IO_NONALERT, 'Synchronous IO Non-Alert')]
  [FlagName(FILE_DELETE_ON_CLOSE, 'Delete-On-Close')]
  TFileMode = type Cardinal;

  // WDK::ntifs.h - info class 18
  [SDKName('FILE_ALL_INFORMATION')]
  TFileAllInformation = record
    BasicInformation: TFileBasicInformation;
    StandardInformation: TFileStandardInformation;
    IndexNumber: UInt64;
    [Bytes] EaSize: Cardinal;
    AccessFlags: TFileAccessMask;
    CurrentByteOffset: UInt64;
    Mode: TFileMode;
    AlignmentRequirement: Cardinal;
    NameInformation: TFileNameInformation;
  end;
  PFileAllInformation = ^TFileAllInformation;

  // WDK::ntifs.h - info class 22
  [SDKName('FILE_STREAM_INFORMATION')]
  TFileStreamInformation = record
    [Unlisted] NextEntryOffset: Cardinal;
    [Counter(ctBytes)] StreamNameLength: Cardinal;
    [Bytes] StreamSize: UInt64;
    [Bytes] StreamAllocationSize: UInt64;
    StreamName: TAnysizeArray<WideChar>;
  end;
  PFileStreamInformation = ^TFileStreamInformation;

  [FlagName(FILE_PIPE_BYTE_STREAM_TYPE, 'Byte Stream Type')]
  [FlagName(FILE_PIPE_MESSAGE_TYPE, 'Message Type')]
  [FlagName(FILE_PIPE_ACCEPT_REMOTE_CLIENTS, 'Accept Remote Clients')]
  [FlagName(FILE_PIPE_REJECT_REMOTE_CLIENTS, 'Reject Remote Clients')]
  TFilePipeType = type Cardinal;

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'FILE_PIPE', 'MODE')]
  TFilePipeReadMode = (
    FILE_PIPE_BYTE_STREAM_MODE = 0,
    FILE_PIPE_MESSAGE_MODE = 1
  );

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'FILE_PIPE', 'OPERATION')]
  TFilePipeCompletion = (
    FILE_PIPE_QUEUE_OPERATION = 0,
    FILE_PIPE_COMPLETE_OPERATION = 1
  );

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'FILE_PIPE')]
  TFilePipeConfiguration = (
    FILE_PIPE_INBOUND = 0,
    FILE_PIPE_OUTBOUND = 1,
    FILE_PIPE_FULL_DUPLEX = 2
  );

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'FILE_PIPE', 'STATE'), Range(1)]
  TFilePipeState = (
    FILE_PIPE_UNKNOWN_STATE = 0,
    FILE_PIPE_DISCONNECTED_STATE = 1,
    FILE_PIPE_LISTENING_STATE = 2,
    FILE_PIPE_CONNECTED_STATE = 3,
    FILE_PIPE_CLOSING_STATE = 4
  );

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'FILE_PIPE', 'END')]
  TFilePipeEnd = (
    FILE_PIPE_CLIENT_END = 0,
    FILE_PIPE_SERVER_END = 1
  );

  // WDK::ntifs.h - info class 23
  [SDKName('FILE_PIPE_INFORMATION')]
  TFilePipeInformation = record
    ReadMode: TFilePipeReadMode;
    CompletionMode: TFilePipeCompletion;
  end;
  PFilePipeInformation = ^TFilePipeInformation;

  // WDK::ntifs.h - info class 24
  [SDKName('FILE_PIPE_LOCAL_INFORMATION')]
  TFilePipeLocalInformation = record
    NamedPipeType: TFilePipeType;
    NamedPipeConfiguration: TFilePipeConfiguration;
    MaximumInstances: Cardinal;
    CurrentInstances: Cardinal;
    InboundQuota: Cardinal;
    ReadDataAvailable: Cardinal;
    OutboundQuota: Cardinal;
    WriteQuotaAvailable: Cardinal;
    NamedPipeState: TFilePipeState;
    NamedPipeEnd: TFilePipeEnd;
  end;
  PFilePipeLocalInformation = ^TFilePipeLocalInformation;

  // WDK::ntifs.h - info class 25
  [SDKName('FILE_PIPE_REMOTE_INFORMATION')]
  TFilePipeRemoteInformation = record
     CollectDataTime: TULargeInteger;
     MaximumCollectionCount: Cardinal;
  end;
  PFilePipeRemoteInformation = ^TFilePipeRemoteInformation;

  // WDK::ntifs.h - info class 26
  [SDKName('FILE_MAILSLOT_QUERY_INFORMATION')]
  TFileMailsoltQueryInformation = record
    MaximumMessageSize: Cardinal;
    MailslotQuota: Cardinal;
    NextMessageSize: Cardinal;
    MessagesAvailable: Cardinal;
    ReadTimeout: TULargeInteger;
  end;
  PFileMailsoltQueryInformation = ^TFileMailsoltQueryInformation;

  // WDK::ntifs.h
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'COMPRESSION_FORMAT')]
  TCompressionFormat = (
    COMPRESSION_FORMAT_NONE = 0,
    COMPRESSION_FORMAT_DEFAULT = 1,
    COMPRESSION_FORMAT_LZNT1 = 2,
    COMPRESSION_FORMAT_XPRESS = 3,
    COMPRESSION_FORMAT_XPRESS_HUFF = 4
  );
  {$MINENUMSIZE 4}

  // WDK::ntifs.h - info class 28
  [SDKName('FILE_COMPRESSION_INFORMATION')]
  TFileCompressionInformation = record
    [Bytes] CompressedFileSize: UInt64;
    CompressionFormat: TCompressionFormat;
    CompressionUnitShift: Byte;
    ChunkShift: Byte;
    ClusterShift: Byte;
    Reserved: array [0..2] of Byte;
  end;
  PFileCompressionInformation = ^TFileCompressionInformation;

  // WDK::ntifs.h - info class 29
  [SDKName('FILE_OBJECTID_INFORMATION')]
  TFileObjectIdInformation = record
    [Hex] FileReference: UInt64;
    ObjectID: TGuid;
    BirthVolumeID: TGuid;
    BirthObjectID: TGuid;
    DomainID: TGuid;
  end;
  PFileObjectIdInformation = ^TFileObjectIdInformation;

  // WDK::ntifs.h - info class 30
  [SDKName('FILE_COMPLETION_INFORMATION')]
  TFileCompletionInformation = record
    Port: THandle;
    Key: Pointer;
  end;
  PFileCompletionInformation = ^TFileCompletionInformation;

  [SubEnum(MAX_UINT, IO_REPARSE_TAG_MOUNT_POINT, 'Mount Point')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_SIS, 'Single-Instance-Storage')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_WIM, 'Windows Imaging Format')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_DFS, 'Distributed File System')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_SYMLINK, 'Symbolic Link')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_DFSR, 'Distributed File System [R]')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_DEDUP, 'Data Deduplication')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_APPXSTRM, 'APPX Stream')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_NFS, 'Network File System')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_DFM, 'Dynamic File')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_WOF, 'Windows Overlay Filter')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_WCI, 'Windows Container Isolation')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_WCI_1, 'Windows Container Isolation 1')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_GLOBAL_REPARSE, 'Named Pipe Symbolic Link')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_CLOUD, 'Cloud File')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_APPEXECLINK, 'AppExec Link')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_PROJFS, 'Projected File System')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_LX_SYMLINK, 'Windows Subsystem for Linux Symbolic Link')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_STORAGE_SYNC, 'Azure File Sync')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_WCI_TOMBSTONE, 'Windows Container Isolation Tombstone')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_UNHANDLED, 'Windows Container Isolation Unhandled')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_PROJFS_TOMBSTONE, 'Projected File System Tombstone')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_AF_UNIX, 'Windows Subsystem for Linux Socket')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_LX_FIFO, 'Windows Subsystem for Linux Named Pipe')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_LX_CHR, 'Windows Subsystem for Linux Character File')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_LX_BLK, 'Windows Subsystem for Linux Block File')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_WCI_LINK, 'Windows Container Isolation Link')]
  [SubEnum(MAX_UINT, IO_REPARSE_TAG_WCI_LINK_1, 'Windows Container Isolation Link 1')]
  [Hex] TReparseTag = type Cardinal;

  // WDK::ntifs.h - info class 33
  [SDKName('FILE_REPARSE_POINT_INFORMATION')]
  TFileReparsePointInformation = record
    [Hex] FileReference: UInt64;
    Tag: TReparseTag;
  end;
  PFileReparsePointInformation = ^TFileReparsePointInformation;

  // WDK::wdm.h - info class 34
  [SDKName('FILE_NETWORK_OPEN_INFORMATION')]
  TFileNetworkOpenInformation = record
    [Aggregate] Times: TFileTimestamps;
    [Bytes] AllocationSize: UInt64;
    [Bytes] EndOfFile: UInt64;
    FileAttributes: TFileAttributes;
  end;
  PFileNetworkOpenInformation = ^TFileNetworkOpenInformation;

  // WDK::ntddk.h - info class 35
  [SDKName('FILE_ATTRIBUTE_TAG_INFORMATION')]
  TFileAttributeTagInformation = record
    FileAttributes: TFileAttributes;
    ReparseTag: TReparseTag;
  end;
  PFileAttributeTagInformation = ^TFileAttributeTagInformation;

  // WDK::wdm.h - info class 43
  [SDKName('IO_PRIORITY_HINT')]
  [NamingStyle(nsCamelCase, 'IoPriority')]
  TIoPriorityHint = (
    IoPriorityVeryLow = 0,
    IoPriorityLow = 1,
    IoPriorityNormal = 2,
    IoPriorityHigh = 3,
    IoPriorityCritical = 4
  );

  // WDK::ntifs.h
  [SDKName('FILE_LINK_ENTRY_INFORMATION')]
  TFileLinkEntryInformation = record
    [Unlisted] NextEntryOffset: Cardinal;
    ParentFileID: TFileId;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileLinkEntryInformation = ^TFileLinkEntryInformation;

  // WDK::ntifs.h - info class 46
  [SDKName('FILE_LINKS_INFORMATION')]
  TFileLinksInformation = record
    [Bytes] BytesNeeded: Cardinal;
    EntriesReturned: Cardinal;
    Entry: TFileLinkEntryInformation;
  end;
  PFileLinksInformation = ^TFileLinksInformation;

  // WDK::wdm.h - info class 47
  [SDKName('FILE_PROCESS_IDS_USING_FILE_INFORMATION')]
  TFileProcessIdsUsingFileInformation = record
    [Counter] NumberOfProcessIdsInList: Integer;
    ProcessIdList: TAnysizeArray<TProcessId>;
  end;
  PFileProcessIdsUsingFileInformation = ^TFileProcessIdsUsingFileInformation;

  // WDK::ntifs.h - info class 54
  [SDKName('FILE_STANDARD_LINK_INFORMATION')]
  TFileStandardLinkInformation = record
    NumberOfAccessibleLinks: Cardinal;
    TotalNumberOfLinks: Cardinal;
    DeletePending: Boolean;
    Directory: Boolean;
  end;
  PFileStandardLinkInformation = ^TFileStandardLinkInformation;

  // WDK::ntddk.h - info class 64
  [MinOSVersion(OsWin10RS1)]
  [SubEnum(FILE_DISPOSITION_DELETE, FILE_DISPOSITION_DO_NOT_DELETE, 'Don''t Delete')]
  [SubEnum(FILE_DISPOSITION_DELETE, FILE_DISPOSITION_DELETE, 'Delete')]
  [FlagName(FILE_DISPOSITION_POSIX_SEMANTICS, 'Posix Semantics')]
  [FlagName(FILE_DISPOSITION_FORCE_IMAGE_SECTION_CHECK, 'Force Image Section Check')]
  [FlagName(FILE_DISPOSITION_ON_CLOSE, 'On Close')]
  [FlagName(FILE_DISPOSITION_IGNORE_READONLY_ATTRIBUTE, 'Ignore Readonly Attribute')]
  TFileDispositionFlags = type Cardinal;

  [MinOSVersion(OsWin10RS1)]
  [FlagName(FILE_RENAME_REPLACE_IF_EXISTS, 'Replace If Exists')]
  [FlagName(FILE_RENAME_POSIX_SEMANTICS, 'Posix Semantics')]
  [FlagName(FILE_RENAME_SUPPRESS_PIN_STATE_INHERITANCE, 'Suppress Pin State Inheritance')]
  [FlagName(FILE_RENAME_SUPPRESS_STORAGE_RESERVE_INHERITANCE, 'Suppress Storage Reserve Inheritance')]
  [FlagName(FILE_RENAME_NO_INCREASE_AVAILABLE_SPACE, 'No Increase Available Space')]
  [FlagName(FILE_RENAME_NO_DECREASE_AVAILABLE_SPACE, 'No Decrease Available Space')]
  [FlagName(FILE_RENAME_IGNORE_READONLY_ATTRIBUTE, 'Ignore Readonly Attribute')]
  [FlagName(FILE_RENAME_FORCE_RESIZE_TARGET_SR, 'Force Resize Target')]
  [FlagName(FILE_RENAME_FORCE_RESIZE_SOURCE_SR, 'Force Resize Source')]
  TFileRenameFlags = type Cardinal;

  // WDK::ntifs.h - info class 65
  [MinOSVersion(OsWin10RS1)]
  [SDKName('FILE_RENAME_INFORMATION_EX')]
  TFileRenameInformationEx = record
    Flags: TFileRenameFlags;
    RootDirectory: THandle;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileRenameInformationEx = ^TFileRenameInformationEx;

  [MinOSVersion(OsWin10RS1)]
  [FlagName(FILE_LINK_REPLACE_IF_EXISTS, 'Replace If Exists')]
  [FlagName(FILE_LINK_POSIX_SEMANTICS, 'FILE_LINK_POSIX_SEMANTICS')]
  [FlagName(FILE_LINK_SUPPRESS_STORAGE_RESERVE_INHERITANCE, 'Suppress Storage Reserve Inheritance')]
  [FlagName(FILE_LINK_NO_INCREASE_AVAILABLE_SPACE, 'No Increase Available Space')]
  [FlagName(FILE_LINK_NO_DECREASE_AVAILABLE_SPACE, 'No Decrease Available Space')]
  [FlagName(FILE_LINK_IGNORE_READONLY_ATTRIBUTE, 'Ignore Readonly Attribute')]
  [FlagName(FILE_LINK_FORCE_RESIZE_TARGET_SR, 'Force Resize Target')]
  [FlagName(FILE_LINK_FORCE_RESIZE_SOURCE_SR, 'Force Resize Source')]
  TFileLinkFlags = type Cardinal;

  // WDK::ntifs.h - info class 72
  [MinOSVersion(OsWin10RS1)]
  [SDKName('FILE_LINK_INFORMATION_EX')]
  TFileLinkInformationEx = record
    Flags: TFileLinkFlags;
    RootDirectory: THandle;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileLinkInformationEx = ^TFileLinkInformationEx;

  // Notifications

  // WDK::wdm.h
  [SDKName('DIRECTORY_NOTIFY_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'DirectoryNotify'), Range(1)]
  TDirectoryNotifyInformationClass = (
    DirectoryNotifyReserved = 0,
    DirectoryNotifyInformation = 1,         // TFileNotifyInformation
    DirectoryNotifyExtendedInformation = 2  // TFileNotifyExtendedInformation
  );

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'FILE_ACTION'), Range(1)]
  TFileAction = (
    FILE_ACTION_INVALID = 0,
    FILE_ACTION_ADDED = 1,
    FILE_ACTION_REMOVED = 2,
    FILE_ACTION_MODIFIED = 3,
    FILE_ACTION_RENAMED_OLD_NAME = 4,
    FILE_ACTION_RENAMED_NEW_NAME = 5,
    FILE_ACTION_ADDED_STREAM = 6,
    FILE_ACTION_REMOVED_STREAM = 7,
    FILE_ACTION_MODIFIED_STREAM = 8,
    FILE_ACTION_REMOVED_BY_DELETE = 9,
    FILE_ACTION_ID_NOT_TUNNELLED = 10,
    FILE_ACTION_TUNNELLED_ID_COLLISION = 11
  );

  // WDK::ntifs.h - info class 1
  [SDKName('FILE_NOTIFY_INFORMATION')]
  TFileNotifyInformation = record
    [Unlisted] NextEntryOffset: Cardinal;
    Action: TFileAction;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileNotifyInformation = ^TFileNotifyInformation;

  // WDK::ntifs.h - info class 2
  [MinOsVersion(OsWin10RS3)]
  [SDKName('FILE_NOTIFY_EXTENDED_INFORMATION')]
  TFileNotifyExtendedInformation = record
    [Unlisted] NextEntryOffset: Cardinal;
    Action: TFileAction;
    CreationTime: TLargeInteger;
    LastModificationTime: TLargeInteger;
    LastChangeTime: TLargeInteger;
    LastAccessTime: TLargeInteger;
    [Bytes] AllocatedLength: UInt64;
    [Bytes] FileSize: UInt64;
    FileAttributes: TFileAttributes;
    ReparsePointTag: TReparseTag;
    FileID: TFileId;
    ParentFileID: TFileId;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileNotifyExtendedInformation = ^TFileNotifyExtendedInformation;

  // I/O Completion

  // PHNT::ntioapi.h
  [NamingStyle(nsCamelCase, 'IoCompletion')]
  TIoCompletionInformationClass = (
    IoCompletionBasicInformation = 0 // Cardinal (Depth)
  );

{ Function }

// WDK::ntifs.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtCreateFile(
  out FileHandle: THandle;
  DesiredAccess: TFileAccessMask;
  const ObjectAttributes: TObjectAttributes;
  out IoStatusBlock: TIoStatusBlock;
  [in, opt] AllocationSize: PUInt64;
  FileAttributes: TFileAttributes;
  ShareAccess: TFileShareMode;
  CreateDisposition: TFileDisposition;
  CreateOptions: TFileOpenOptions;
  [in, opt] EaBuffer: Pointer;
  EaLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtCreateNamedPipeFile(
  out FileHandle: THandle;
  DesiredAccess: TIoPipeAccessMask;
  const ObjectAttributes: TObjectAttributes;
  out IoStatusBlock: TIoStatusBlock;
  ShareAccess: TFileShareMode;
  CreateDisposition: TFileDisposition;
  CreateOptions: TFileOpenOptions;
  NamedPipeType: TFilePipeType;
  ReadMode: TFilePipeReadMode;
  CompletionMode: TFilePipeCompletion;
  MaximumInstances: Cardinal;
  InboundQuota: Cardinal;
  OutboundQuota: Cardinal;
  [in, opt] DefaultTimeout: PULargeInteger
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtCreateMailslotFile(
  out FileHandle: THandle;
  DesiredAccess: TFileAccessMask;
  const ObjectAttributes: TObjectAttributes;
  out IoStatusBlock: TIoStatusBlock;
  CreateOptions: TFileOpenOptions;
  MailslotQuota: Cardinal;
  MaximumMessageSize: Cardinal;
  const [ref] ReadTimeout: TULargeInteger
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtOpenFile(
  out FileHandle: THandle;
  DesiredAccess: TFileAccessMask;
  const ObjectAttributes: TObjectAttributes;
  out IoStatusBlock: TIoStatusBlock;
  ShareAccess: TFileShareMode;
  OpenOptions: TFileOpenOptions
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtDeleteFile(
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtFlushBuffersFile(
  FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtQueryInformationFile(
  FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock;
  [out] FileInformation: Pointer;
  Length: Cardinal;
  FileInformationClass: TFileInformationClass
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[MinOSVersion(OsWin10RS2)]
function NtQueryInformationByName(
  ObjectAttributes: PObjectAttributes;
  [out] IoStatusBlock: PIoStatusBlock;
  [out] FileInformation: Pointer;
  Length: Cardinal;
  FileInformationClass: TFileInformationClass
): NTSTATUS; stdcall; external ntdll delayed;

// WDK::ntifs.h
function NtSetInformationFile(
  FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock;
  [in] FileInformation: Pointer;
  Length: Cardinal;
  FileInformationClass: TFileInformationClass
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtQueryDirectoryFile(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  [out] FileInformation: Pointer;
  Length: Cardinal;
  FileInformationClass: TFileInformationClass;
  ReturnSingleEntry: Boolean;
  [in, opt] FileName: PNtUnicodeString;
  RestartScan: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtQueryEaFile(
  FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock;
  [out] Buffer: Pointer;
  Length: Cardinal;
  ReturnSingleEntry: Boolean;
  [in] EaList: Pointer;
  EaListLength: Cardinal;
  [in, opt] EaIndex: PCardinal;
  RestartScan: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtSetEaFile(
  FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock;
  [in] Buffer: Pointer;
  Length: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtQueryQuotaInformationFile(
  FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock;
  [out] Buffer: Pointer;
  Length: Cardinal;
  ReturnSingleEntry: Boolean;
  [in, opt] SidList: Pointer;
  SidListLength: Cardinal;
  [in, opt] StartSid: PSid;
  RestartScan: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtSetQuotaInformationFile(
  FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock;
  [in] Buffer: Pointer;
  Length: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtCancelIoFile(
  FileHandle: THandle;
  [out] IoStatusBlock: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtCancelIoFileEx(
  FileHandle: THandle;
  [in, opt] IoRequestToCancel: PIoStatusBlock;
  [out] IoStatusBlock: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtCancelSynchronousIoFile(
  FileHandle: THandle;
  [in, opt] IoRequestToCancel: PIoStatusBlock;
  [out] IoStatusBlock: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtDeviceIoControlFile(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  IoControlCode: Cardinal;
  [in, opt] InputBuffer: Pointer;
  InputBufferLength: Cardinal;
  [out, opt] OutputBuffer: Pointer;
  OutputBufferLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtReadFile(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  [out] Buffer: Pointer;
  Length: Cardinal;
  [in, opt] ByteOffset: PUInt64;
  [in, opt] Key: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtWriteFile(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  [in] Buffer: Pointer;
  Length: Cardinal;
  [in, opt] ByteOffset: PUInt64;
  [in, opt] Key: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtReadFileScatter(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  SegmentArray: TArray<TFileSegmentElement>;
  Length: Cardinal;
  [in, opt] ByteOffset: PUInt64;
  [in, opt] Key: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtWriteFileGather(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  SegmentArray: TArray<TFileSegmentElement>;
  Length: Cardinal;
  [in, opt] ByteOffset: PUInt64;
  [in, opt] Key: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtLockFile(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  const [ref] ByteOffset: UInt64;
  const [ref] Length: UInt64;
  Key: Cardinal;
  FailImmediately: Boolean;
  ExclusiveLock: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtUnlockFile(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  const [ref] ByteOffset: UInt64;
  const [ref] Length: UInt64;
  Key: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtQueryAttributesFile(
  const ObjectAttributes: TObjectAttributes;
  out FileInformation: TFileBasicInformation
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtQueryFullAttributesFile(
  const ObjectAttributes: TObjectAttributes;
  out FileInformation: TFileNetworkOpenInformation
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtNotifyChangeDirectoryFile(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  [out] Buffer: PFileNotifyInformation;
  Length: Cardinal;
  CompletionFilter: Cardinal;
  WatchTree: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtNotifyChangeDirectoryFileEx(
  FileHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  [out] Buffer: Pointer;
  Length: Cardinal;
  CompletionFilter: Cardinal;
  WatchTree: Boolean;
  DirectoryNotifyInformationClass: TDirectoryNotifyInformationClass
): NTSTATUS; stdcall; external ntdll;

// I/O Completion

// PHNT::ntioapi.h
function NtCreateIoCompletion(
  out IoCompletionHandle: THandle;
  DesiredAccess: TIoCompeletionAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  Count: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtOpenIoCompletion(
  out IoCompletionHandle: THandle;
  DesiredAccess: TIoCompeletionAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtQueryIoCompletion(
  [Access(IO_COMPLETION_QUERY_STATE)] IoCompletionHandle: THandle;
  IoCompletionInformationClass: TIoCompletionInformationClass;
  [opt] IoCompletionInformation: Pointer;
  IoCompletionInformationLength: Cardinal;
  [out, opt] ReturnLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtSetIoCompletion(
  [Access(IO_COMPLETION_MODIFY_STATE)] IoCompletionHandle: THandle;
  [in, opt] KeyContext: Pointer;
  [in, opt] ApcContext: Pointer;
  IoStatus: NTSTATUS;
  IoStatusInformation: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtSetIoCompletionEx(
  [Access(IO_COMPLETION_MODIFY_STATE)] IoCompletionHandle: THandle;
  IoCompletionPacketHandle: THandle;
  [in, opt] KeyContext: Pointer;
  [in, opt] ApcContext: Pointer;
  IoStatus: NTSTATUS;
  IoStatusInformation: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtRemoveIoCompletion(
  [Access(IO_COMPLETION_MODIFY_STATE)] IoCompletionHandle: THandle;
  out KeyContext: Pointer;
  out ApcContext: Pointer;
  out IoStatusBlock: TIoStatusBlock;
  [opt] Timeout: PLargeInteger
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntioapi.h
function NtRemoveIoCompletionEx(
  [Access(IO_COMPLETION_MODIFY_STATE)] IoCompletionHandle: THandle;
  [out] IoCompletionInformation: PFileIoCompletionInformation;
  Count: Cardinal;
  out NumEntriesRemoved: Cardinal;
  [opt] Timeout: PLargeInteger;
  Alertable: Boolean
): NTSTATUS; stdcall; external ntdll;

implementation

end.
