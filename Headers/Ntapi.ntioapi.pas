unit Ntapi.ntioapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection, NtUtils.Version;

const
  // ntifs.4531
  FILE_ANY_ACCESS = $0000;
  FILE_SPECIAL_ACCESS = FILE_ANY_ACCESS;
  FILE_READ_ACCESS    = $0001;
  FILE_WRITE_ACCESS   = $0002;

  // WinNt.13044
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

  // WinNt.13091
  FILE_SHARE_READ = $00000001;
  FILE_SHARE_WRITE = $00000002;
  FILE_SHARE_DELETE = $00000004;
  FILE_SHARE_ALL = FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE;

  // WinNt.13094
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

  // wdm.6433, create/open flags
  FILE_DIRECTORY_FILE = $00000001;
  FILE_WRITE_THROUGH = $00000002;
  FILE_SEQUENTIAL_ONLY = $00000004;
  FILE_NO_INTERMEDIATE_BUFFERING = $00000008;
  FILE_SYNCHRONOUS_IO_ALERT = $00000010;
  FILE_SYNCHRONOUS_IO_NONALERT = $00000020;
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

  // ntifs.6649
  FILE_RENAME_REPLACE_IF_EXISTS = $00000001;                    // Win 10 RS1+
  FILE_RENAME_POSIX_SEMANTICS = $00000002;                      // Win 10 RS1+
  FILE_RENAME_SUPPRESS_PIN_STATE_INHERITANCE = $00000004;       // Win 10 RS3+
  FILE_RENAME_SUPPRESS_STORAGE_RESERVE_INHERITANCE = $00000008; // Win 10 RS5+
  FILE_RENAME_NO_INCREASE_AVAILABLE_SPACE = $00000010;          // Win 10 RS5+
  FILE_RENAME_NO_DECREASE_AVAILABLE_SPACE = $00000020;          // Win 10 RS5+
  FILE_RENAME_IGNORE_READONLY_ATTRIBUTE = $00000040;            // Win 10 RS5+
  FILE_RENAME_FORCE_RESIZE_TARGET_SR = $00000080;               // Win 10 19H1+
  FILE_RENAME_FORCE_RESIZE_SOURCE_SR = $00000100;               // Win 10 19H1+

  // ntifs.6594
  FILE_LINK_REPLACE_IF_EXISTS = $00000001;                      // Win 10 RS1+
  FILE_LINK_POSIX_SEMANTICS = $00000002;                        // Win 10 RS1+
  FILE_LINK_SUPPRESS_STORAGE_RESERVE_INHERITANCE = $00000008;   // Win 10 RS5+
  FILE_LINK_NO_INCREASE_AVAILABLE_SPACE = $00000010;            // Win 10 RS5+
  FILE_LINK_NO_DECREASE_AVAILABLE_SPACE = $00000020;            // Win 10 RS5+
  FILE_LINK_IGNORE_READONLY_ATTRIBUTE = $00000040;              // Win 10 RS5+
  FILE_LINK_FORCE_RESIZE_TARGET_SR = $00000080;                 // Win 10 19H1+
  FILE_LINK_FORCE_RESIZE_SOURCE_SR = $00000100;                 // Win 10 19H1+

  // ntddk.4671, Win 10 RS1+
  FILE_DISPOSITION_DO_NOT_DELETE = $00000000;
  FILE_DISPOSITION_DELETE = $00000001;
  FILE_DISPOSITION_POSIX_SEMANTICS = $00000002;
  FILE_DISPOSITION_FORCE_IMAGE_SECTION_CHECK = $00000004;
  FILE_DISPOSITION_ON_CLOSE = $00000008;
  FILE_DISPOSITION_IGNORE_READONLY_ATTRIBUTE = $00000010; // RS5+

  // File System

  // wdm.6551, device characteristics
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

  // ntifs.6061, file system attributes
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

  // ntifs.7015, fs control flags
  FILE_VC_QUOTA_NONE = $00000000;
  FILE_VC_QUOTA_TRACK = $00000001;
  FILE_VC_QUOTA_ENFORCE = $00000002;
  FILE_VC_QUOTA_MASK = $00000003;
  FILE_VC_CONTENT_INDEX_DISABLED = $00000008;
  FILE_VC_LOG_QUOTA_THRESHOLD = $00000010;
  FILE_VC_LOG_QUOTA_LIMIT = $00000020;
  FILE_VC_LOG_VOLUME_THRESHOLD = $00000040;
  FILE_VC_LOG_VOLUME_LIMIT = $00000080;
  FILE_VC_QUOTAS_INCOMPLETE = $00000100;
  FILE_VC_QUOTAS_REBUILDING = $00000200;

  // Notifications

  // ntifs.5975, notification filters
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

  // ntifs.6010, named pipe type
  FILE_PIPE_BYTE_STREAM_TYPE = $00000000;
  FILE_PIPE_MESSAGE_TYPE = $00000001;
  FILE_PIPE_ACCEPT_REMOTE_CLIENTS = $00000000;
  FILE_PIPE_REJECT_REMOTE_CLIENTS = $00000002;

  // IO Completion

  IO_COMPLETION_QUERY_STATE = $0001;
  IO_COMPLETION_MODIFY_STATE = $0002;

  IO_COMPLETION_ALL_ACCESS = STANDARD_RIGHTS_ALL or $03;

type
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

  [FriendlyName('IO completion')]
  [ValidMask(IO_COMPLETION_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(IO_COMPLETION_QUERY_STATE, 'Query')]
  [FlagName(IO_COMPLETION_MODIFY_STATE, 'Modify')]
  TIoCompeletionAccessMask = type TAccessMask;

  [FlagName(FILE_SHARE_READ, 'Share Read')]
  [FlagName(FILE_SHARE_WRITE, 'Share Write')]
  [FlagName(FILE_SHARE_DELETE, 'Share Delete')]
  TFileShareMode = type Cardinal;

  // wdm.6421
  [NamingStyle(nsSnakeCase, 'FILE')]
  TFileDisposition = (
    FILE_SUPERSEDE = 0,
    FILE_OPEN = 1,
    FILE_CREATE = 2,
    FILE_OPEN_IF = 3,
    FILE_OVERWRITE = 4,
    FILE_OVERWRITE_IF = 5
  );

  // wdm.6497
  [NamingStyle(nsSnakeCase, 'FILE')]
  TFileIoStatusResult = (
    FILE_SUPERSEDED = 0,
    FILE_OPENED = 1,
    FILE_CREATED = 2,
    FILE_OVERWRITTEN = 3,
    FILE_EXISTS = 4,
    FILE_DOES_NOT_EXIST = 5
  );

  // wdm.6573
  TIoStatusBlock = record
  case Integer of
    0: (Pointer: Pointer; Result: TFileIoStatusResult);
    1: (Status: NTSTATUS; Information: NativeUInt);
  end;
  PIoStatusBlock = ^TIoStatusBlock;

  // wdm.6597
  TIoApcRoutine = procedure (ApcContext: Pointer; const [ref] IoStatusBlock:
    TIoStatusBlock; Reserved: Cardinal); stdcall;

  // wdm.6972
  TFileSegmentElement = record
    Buffer: Pointer;
    Alignment: UInt64;
  end;
  PFileSegmentElement = ^TFileSegmentElement;

  // Files

  // wdm.6668 (q - query; s - set; d - directory)
  [NamingStyle(nsCamelCase, 'File'), Range(1)]
  TFileInformationClass = (
    FileReserved = 0,
    FileDirectoryInformation = 1,     // d: TFileDirectoryInformation
    FileFullDirectoryInformation = 2, // d: TFileFullDirInformation
    FileBothDirectoryInformation = 3, // d:
    FileBasicInformation = 4,         // q, s: TFileBasicInformation
    FileStandardInformation = 5,      // q: TFileStandardInformation[Ex]
    FileInternalInformation = 6,      // q: UInt64 (IndexNumber)
    FileEaInformation = 7,            // q: Cardinal (EaSize)
    FileAccessInformation = 8,        // q: TAccessMask
    FileNameInformation = 9,          // q: TFileNameInformation
    FileRenameInformation = 10,       // s: TFileRenameInformation
    FileLinkInformation = 11,         // s: TFileLinkInformation
    FileNamesInformation = 12,        // q, d: TFileNamesInformation
    FileDispositionInformation = 13,  // s: Boolean (DeleteFile)
    FilePositionInformation = 14,     // q, s: UInt64 (CurrentByteOffset)
    FileFullEaInformation = 15,       // q: TFileFullEaInformation
    FileModeInformation = 16,         // q, s: Cardinal (Mode)
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
    FileStandardLinkInformation = 54,
    FileRemoteProtocolInformation = 55,
    FileRenameInformationBypassAccessCheck = 56,
    FileLinkInformationBypassAccessCheck = 57,
    FileVolumeNameInformation = 58,
    FileIdInformation = 59,
    FileIdExtdDirectoryInformation = 60,
    FileReplaceCompletionInformation = 61,
    FileHardLinkFullIdInformation = 62,
    FileIdExtdBothDirectoryInformation = 63,
    FileDispositionInformationEx = 64,       // s: Cardinal FILE_DISPOSITION_*
    FileRenameInformationEx = 65,            // s: TFileRenameInformationEx, Win 10 RS1+
    FileRenameInformationExBypassAccessCheck = 66,
    FileDesiredStorageClassInformation = 67,
    FileStatInformation = 68,
    FileMemoryPartitionInformation = 69,
    FileStatLxInformation = 70,
    FileCaseSensitiveInformation = 71,
    FileLinkInformationEx = 72,              // s: TFileLinkInformationEx, Win 10 RS1+
    FileLinkInformationExBypassAccessCheck = 73,
    FileStorageReserveIdInformation = 74,
    FileCaseSensitiveInformationForceAccessCheck = 75
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

  TFileTimes = record
    CreationTime: TLargeInteger;
    LastAccessTime: TLargeInteger;
    LastWriteTime: TLargeInteger;
    ChangeTime: TLargeInteger;
  end;

  // ntifs.6319, info class 1, use with NtQueryDirectoryFile
  TFileDirectoryInformation = record
    NextEntryOffset: Cardinal;
    FileIndex: Cardinal;
    [Aggregate] Times: TFileTimes;
    [Bytes] EndOfFile: UInt64;
    [Bytes] AllocationSize: UInt64;
    FileAttributes: TFileAttributes;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileDirectoryInformation = ^TFileDirectoryInformation;

  // ntifs.6333, info class 2, use with NtQueryDirectoryFile
  TFileFullDirInformation = record
    NextEntryOffset: Cardinal;
    FileIndex: Cardinal;
    [Aggregate] Times: TFileTimes;
    [Bytes] EndOfFile: UInt64;
    [Bytes] AllocationSize: UInt64;
    FileAttributes: TFileAttributes;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    EaSize: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;

  // wdm.6774, info class 4
  TFileBasicInformation = record
    [Aggregate] Times: TFileTimes;
    FileAttributes: TFileAttributes;
  end;
  PFileBasicInformation = ^TFileBasicInformation;

  // wdm.6784, info class 5
  TFileStandardInformation = record
    [Bytes] AllocationSize: UInt64;
    [Bytes] EndOfFile: UInt64;
    NumberOfLinks: Cardinal;
    DeletePending: Boolean;
    Directory: Boolean;
  end;
  PFileStandardInformation = ^TFileStandardInformation;

  // wdm.6792, info class 5
  [MinOSVersion(OsWin10TH1)]
  TFileStandardInformationEx = record
    [Aggregate] Standard: TFileStandardInformation;
    AlternateStream: Boolean;
    MetadataAttribute: Boolean;
  end;
  PFileStandardInformationEx = ^TFileStandardInformationEx;

  // ntddk.4651, info classes 9, 21, 40, 48
  TFileNameInformation = record
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileNameInformation = ^TFileNameInformation;

  // ntifs.6672, info class 10
  TFileRenameInformation = record
    ReplaceIfExists: Boolean;
    RootDirectory: THandle;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileRenameInformation = ^TFileRenameInformation;

  // ntifs.6614, info class 11
  TFileLinkInformation = TFileRenameInformation;
  PFileLinkInformation = ^TFileLinkInformation;

  // ntifs.6304, info class 12
  TFileNamesInformation = record
    NextEntryOffset: Cardinal;
    FileIndex: Cardinal;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileNamesInformation = ^TFileNamesInformation;

  // wdm.6825, info class 15
  TFileFullEaInformation = record
    NextEntryOffset: Cardinal;
    [Hex] Flags: Byte;
    [Counter(ctBytes)] EaNameLength: Byte;
    EaValueLength: Word;
    EaName: TAnysizeArray<AnsiChar>;
  end;
  PFileFullEaInformation = ^TFileFullEaInformation;

  // ntifs.6486, info class 18
  TFileAllInformation = record
    BasicInformation: TFileBasicInformation;
    StandardInformation: TFileStandardInformation;
    IndexNumber: UInt64;
    [Bytes] EaSize: Cardinal;
    AccessFlags: TAccessMask;
    CurrentByteOffset: UInt64;
    [Hex] Mode: Cardinal;
    AlignmentRequirement: Cardinal;
    NameInformation: TFileNameInformation;
  end;
  PFileAllInformation = ^TFileAllInformation;

  // ntifs.6692, info class 22
  TFileStreamInformation = record
    NextEntryOffset: Cardinal;
    [Counter(ctBytes)] StreamNameLength: Cardinal;
    [Bytes] StreamSize: UInt64;
    [Bytes] StreamAllocationSize: UInt64;
    StreamName: TAnysizeArray<WideChar>;
  end;
  PFileStreamInformation = ^TFileStreamInformation;

  // ntifs.6029
  [NamingStyle(nsSnakeCase, 'FILE_PIPE', 'MODE')]
  TFilePipeReadMode = (
    FILE_PIPE_BYTE_STREAM_MODE = 0,
    FILE_PIPE_MESSAGE_MODE = 1
  );

  // ntifs.6022
  [NamingStyle(nsSnakeCase, 'FILE_PIPE', 'OPERATION')]
  TFilePipeCompletion = (
    FILE_PIPE_QUEUE_OPERATION = 0,
    FILE_PIPE_COMPLETE_OPERATION = 1
  );

  // ntifs.6036
  [NamingStyle(nsSnakeCase, 'FILE_PIPE')]
  TFilePipeConfiguration = (
    FILE_PIPE_INBOUND = 0,
    FILE_PIPE_OUTBOUND = 1,
    FILE_PIPE_FULL_DUPLEX = 2
  );

  // ntifs.6044
  [NamingStyle(nsSnakeCase, 'FILE_PIPE', 'STATE'), Range(1)]
  TFilePipeState = (
    FILE_PIPE_UNKNOWN_STATE = 0,
    FILE_PIPE_DISCONNECTED_STATE = 1,
    FILE_PIPE_LISTENING_STATE = 2,
    FILE_PIPE_CONNECTED_STATE = 3,
    FILE_PIPE_CLOSING_STATE = 4
  );

  // ntifs.6053
  [NamingStyle(nsSnakeCase, 'FILE_PIPE', 'END')]
  TFilePipeEnd = (
    FILE_PIPE_CLIENT_END = 0,
    FILE_PIPE_SERVER_END = 1
  );

  // ntifs.6717, info class 23
  TFilePipeInformation = record
    ReadMode: TFilePipeReadMode;
    CompletionMode: TFilePipeCompletion;
  end;
  PFilePipeInformation = ^TFilePipeInformation;

  // ntifs.6725, info class 24
  TFilePipeLocalInformation = record
    NamedPipeType: Cardinal; // See FILE_PIPE_* constants
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

  // ntifs.6739, info class 25
  TFilePipeRemoteInformation = record
     CollectDataTime: TULargeInteger;
     MaximumCollectionCount: Cardinal;
  end;
  PFilePipeRemoteInformation = ^TFilePipeRemoteInformation;

  // ntifs.6746, info class 26
  TFileMailsoltQueryInformation = record
    MaximumMessageSize: Cardinal;
    MailslotQuota: Cardinal;
    NextMessageSize: Cardinal;
    MessagesAvailable: Cardinal;
    ReadTimeout: TULargeInteger;
  end;
  PFileMailsoltQueryInformation = ^TFileMailsoltQueryInformation;

  // ntifs.6576, info class 28
  TFileCompressionInformation = record
    [Bytes] CompressedFileSize: UInt64;
    CompressionFormat: Word;
    CompressionUnitShift: Byte;
    ChunkShift: Byte;
    ClusterShift: Byte;
    Reserved: array [0..2] of Byte;
  end;
  PFileCompressionInformation = ^TFileCompressionInformation;

  // Info class 29
  TFileObjectIdInformation = record
    [Hex] FileReference: UInt64;
    ObjectID: TGuid;
    BirthVolumeID: TGuid;
    BirthObjectID: TGuid;
    DomainID: TGuid;
  end;
  PFileObjectIdInformation = ^TFileObjectIdInformation;

  // ntifs.6710, info class 30
  TFileCompletionInformation = record
    Port: THandle;
    Key: Pointer;
  end;
  PFileCompletionInformation = ^TFileCompletionInformation;

  // ntifs.6762, info class 33
  TFileReparsePointInformation = record
    [Hex] FileReference: UInt64;
    [Hex] Tag: Cardinal;
  end;
  PFileReparsePointInformation = ^TFileReparsePointInformation;

  // wdm.6814, info class 34
  TFileNetworkOpenInformation = record
    [Aggregate] Times: TFileTimes;
    [Bytes] AllocationSize: UInt64;
    [Bytes] EndOfFile: UInt64;
    FileAttributes: TFileAttributes;
  end;
  PFileNetworkOpenInformation = ^TFileNetworkOpenInformation;

  // ntddk.4659, info class 35
  TFileAttributeTagInformation = record
    FileAttributes: TFileAttributes;
    [Hex] ReparseTag: Cardinal;
  end;
  PFileAttributeTagInformation = ^TFileAttributeTagInformation;

  // wdm.6861, info class 43
  [NamingStyle(nsCamelCase, 'IoPriority')]
  TIoPriorityHint = (
    IoPriorityVeryLow = 0,
    IoPriorityLow = 1,
    IoPriorityNormal = 2,
    IoPriorityHigh = 3,
    IoPriorityCritical = 4
  );

  // ntifs.6769
  TFileLinkEntryInformation = record
    NextEntryOffset: Cardinal;
    ParentFileID: Int64;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileLinkEntryInformation = ^TFileLinkEntryInformation;

  // ntifs.6776, info class 46
  TFileLinksInformation = record
    [Bytes] BytesNeeded: Cardinal;
    EntriesReturned: Cardinal;
    Entry: TFileLinkEntryInformation;
  end;
  PFileLinksInformation = ^TFileLinksInformation;

  // wdm.6899, info class 47
  TFileProcessIdsUsingFileInformation = record
    [Counter] NumberOfProcessIdsInList: Integer;
    ProcessIdList: TAnysizeArray<TProcessId>;
  end;
  PFileProcessIdsUsingFileInformation = ^TFileProcessIdsUsingFileInformation;

  // ntifs.6672, info class 65
  [MinOSVersion(OsWin10RS1)]
  TFileRenameInformationEx = record
    [Hex] Flags: Cardinal; // FILE_RENAME_*
    RootDirectory: THandle;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileRenameInformationEx = ^TFileRenameInformationEx;

  // ntifs.6614, info class 72
  [MinOSVersion(OsWin10RS1)]
  TFileLinkInformationEx = record
    [Hex] Flags: Cardinal; // FILE_LINK_*
    RootDirectory: THandle;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileLinkInformationEx = ^TFileLinkInformationEx;

  // File System

  // wdm.6943
  [NamingStyle(nsCamelCase, 'FileFs'), Range(1)]
  TFsInfoClass = (
    FileFsReserved = 0,
    FileFsVolumeInformation = 1,        // q: TFileFsVolumeInformation
    FileFsLabelInformation = 2,         // s: TFileFsLabelInformation
    FileFsSizeInformation = 3,          // q: TFileFsSizeInformation
    FileFsDeviceInformation = 4,        // q: TFileFsDeviceInformation
    FileFsAttributeInformation = 5,     // q: TFileFsAttributeInformation
    FileFsControlInformation = 6,       // q, s: TFileFsControlInformation
    FileFsFullSizeInformation = 7,      // q: TFileFsFullSizeInformation
    FileFsObjectIdInformation = 8,      // q, s: TFileFsObjectIdInformation
    FileFsDriverPathInformation = 9,    // q: TFileFsDriverPathInformation
    FileFsVolumeFlagsInformation = 10,  // q, s: Cardinal
    FileFsSectorSizeInformation = 11,
    FileFsDataCopyInformation = 12,
    FileFsMetadataSizeInformation = 13,
    FileFsFullSizeInformationEx = 14
  );

  // ntddk.4721, info class 1
  TFileFsVolumeInformation = record
    VolumeCreationTime: TLargeInteger;
    VolumeSerialNumber: Cardinal;
    [Counter(ctBytes)] VolumeLabelLength: Cardinal;
    SupportsObjects: Boolean;
    VolumeLabel: TAnysizeArray<WideChar>;
  end;
  PFileFsVolumeInformation = ^TFileFsVolumeInformation;

  // ntddk.4716, info class 2
  TFileFsLabelInformation = record
    [Counter(ctBytes)] VolumeLabelLength: Cardinal;
    VolumeLabel: TAnysizeArray<WideChar>;
  end;
  PFileFsLabelInformation = ^TFileFsLabelInformation;

  // ntddk.4734, info class 3
  TFileFsSizeInformation = record
    TotalAllocationUnits: UInt64;
    AvailableAllocationUnits: UInt64;
    SectorsPerAllocationUnit: Cardinal;
    [Bytes] BytesPerSector: Cardinal;
  end;
  PFileFsSizeInformation = ^TFileFsSizeInformation;

  {$SCOPEDENUMS ON}
  [NamingStyle(nsSnakeCase, 'FILE_DEVICE')]
  TDeciveType = (
    FILE_DEVICE_BEEP = $00000001,
    FILE_DEVICE_CD_ROM = $00000002,
    FILE_DEVICE_CD_ROM_FILE_SYSTEM = $00000003,
    FILE_DEVICE_CONTROLLER = $00000004,
    FILE_DEVICE_DATALINK = $00000005,
    FILE_DEVICE_DFS = $00000006,
    FILE_DEVICE_DISK = $00000007,
    FILE_DEVICE_DISK_FILE_SYSTEM = $00000008,
    FILE_DEVICE_FILE_SYSTEM = $00000009,
    FILE_DEVICE_INPORT_PORT = $0000000a,
    FILE_DEVICE_KEYBOARD = $0000000b,
    FILE_DEVICE_MAILSLOT = $0000000c,
    FILE_DEVICE_MIDI_IN = $0000000d,
    FILE_DEVICE_MIDI_OUT = $0000000e,
    FILE_DEVICE_MOUSE = $0000000f,
    FILE_DEVICE_MULTI_UNC_PROVIDER = $00000010,
    FILE_DEVICE_NAMED_PIPE = $00000011,
    FILE_DEVICE_NETWORK = $00000012,
    FILE_DEVICE_NETWORK_BROWSER = $00000013,
    FILE_DEVICE_NETWORK_FILE_SYSTEM = $00000014,
    FILE_DEVICE_NULL = $00000015,
    FILE_DEVICE_PARALLEL_PORT = $00000016,
    FILE_DEVICE_PHYSICAL_NETCARD = $00000017,
    FILE_DEVICE_PRINTER = $00000018,
    FILE_DEVICE_SCANNER = $00000019,
    FILE_DEVICE_SERIAL_MOUSE_PORT = $0000001a,
    FILE_DEVICE_SERIAL_PORT = $0000001b,
    FILE_DEVICE_SCREEN = $0000001c,
    FILE_DEVICE_SOUND = $0000001d,
    FILE_DEVICE_STREAMS = $0000001e,
    FILE_DEVICE_TAPE = $0000001f,
    FILE_DEVICE_TAPE_FILE_SYSTEM = $00000020,
    FILE_DEVICE_TRANSPORT = $00000021,
    FILE_DEVICE_UNKNOWN = $00000022,
    FILE_DEVICE_VIDEO = $00000023,
    FILE_DEVICE_VIRTUAL_DISK = $00000024,
    FILE_DEVICE_WAVE_IN = $00000025,
    FILE_DEVICE_WAVE_OUT = $00000026,
    FILE_DEVICE_8042_PORT = $00000027,
    FILE_DEVICE_NETWORK_REDIRECTOR = $00000028,
    FILE_DEVICE_BATTERY = $00000029,
    FILE_DEVICE_BUS_EXTENDER = $0000002a,
    FILE_DEVICE_MODEM = $0000002b,
    FILE_DEVICE_VDM = $0000002c,
    FILE_DEVICE_MASS_STORAGE = $0000002d,
    FILE_DEVICE_SMB = $0000002e,
    FILE_DEVICE_KS = $0000002f,
    FILE_DEVICE_CHANGER = $00000030,
    FILE_DEVICE_SMARTCARD = $00000031,
    FILE_DEVICE_ACPI = $00000032,
    FILE_DEVICE_DVD = $00000033,
    FILE_DEVICE_FULLSCREEN_VIDEO = $00000034,
    FILE_DEVICE_DFS_FILE_SYSTEM = $00000035,
    FILE_DEVICE_DFS_VOLUME = $00000036,
    FILE_DEVICE_SERENUM = $00000037,
    FILE_DEVICE_TERMSRV = $00000038,
    FILE_DEVICE_KSEC = $00000039,
    FILE_DEVICE_FIPS = $0000003a,
    FILE_DEVICE_INFINIBAND = $0000003b,
    FILE_DEVICE_TYPE_60 = $0000003c,
    FILE_DEVICE_TYPE_61 = $0000003d,
    FILE_DEVICE_VMBUS = $0000003e,
    FILE_DEVICE_CRYPT_PROVIDER = $0000003f,
    FILE_DEVICE_WPD = $00000040,
    FILE_DEVICE_BLUETOOTH = $00000041,
    FILE_DEVICE_MT_COMPOSITE = $00000042,
    FILE_DEVICE_MT_TRANSPORT = $00000043,
    FILE_DEVICE_BIOMETRIC = $00000044,
    FILE_DEVICE_PMI = $00000045,
    FILE_DEVICE_EHSTOR = $00000046,
    FILE_DEVICE_DEVAPI = $00000047,
    FILE_DEVICE_GPIO = $00000048,
    FILE_DEVICE_USBEX = $00000049,
    FILE_DEVICE_CONSOLE = $00000050,
    FILE_DEVICE_NFP = $00000051,
    FILE_DEVICE_SYSENV = $00000052,
    FILE_DEVICE_VIRTUAL_BLOCK = $00000053,
    FILE_DEVICE_POINT_OF_SERVICE = $00000054,
    FILE_DEVICE_STORAGE_REPLICATION = $00000055,
    FILE_DEVICE_TRUST_ENV = $00000056,
    FILE_DEVICE_UCM = $00000057,
    FILE_DEVICE_UCMTCPCI = $00000058,
    FILE_DEVICE_PERSISTENT_MEMORY = $00000059,
    FILE_DEVICE_NVDIMM = $0000005a,
    FILE_DEVICE_HOLOGRAPHIC = $0000005b,
    FILE_DEVICE_SDFXHCI = $0000005c,
    FILE_DEVICE_UCMUCSI = $0000005d
  );
  {$SCOPEDENUMS OFF}

  // ntifs.4596
  [NamingStyle(nsSnakeCase, 'METHOD')]
  TIoControlMethod = (
    METHOD_BUFFERED = 0,
    METHOD_IN_DIRECT = 1,
    METHOD_OUT_DIRECT = 2,
    METHOD_NEITHER = 3
  );

  [FlagName(FILE_REMOVABLE_MEDIA, 'Removable Media')]
  [FlagName(FILE_READ_ONLY_DEVICE, 'Read-only Device')]
  [FlagName(FILE_FLOPPY_DISKETTE, 'Floppy Disk')]
  [FlagName(FILE_WRITE_ONCE_MEDIA, 'Write-once Media')]
  [FlagName(FILE_REMOTE_DEVICE, 'Remote Device')]
  [FlagName(FILE_DEVICE_IS_MOUNTED, 'Device Is Mounted')]
  [FlagName(FILE_VIRTUAL_VOLUME, 'Virtual Volume')]
  [FlagName(FILE_AUTOGENERATED_DEVICE_NAME, 'Autogenerated Device Name')]
  [FlagName(FILE_DEVICE_SECURE_OPEN, 'Device Secure Open')]
  [FlagName(FILE_CHARACTERISTIC_PNP_DEVICE, 'PnP Device')]
  [FlagName(FILE_CHARACTERISTIC_TS_DEVICE, 'TS Device')]
  [FlagName(FILE_CHARACTERISTIC_WEBDAV_DEVICE, 'WebDav Device')]
  [FlagName(FILE_CHARACTERISTIC_CSV, 'CSV')]
  [FlagName(FILE_DEVICE_ALLOW_APPCONTAINER_TRAVERSAL, 'Allow AppContainer Traversal')]
  [FlagName(FILE_PORTABLE_DEVICE, 'Portbale Device')]
  TDeviceCharacteristics = type Cardinal;

  // wdm.6962, info class 4
  TFileFsDeviceInformation = record
    DeviceType: TDeciveType;
    Characteristics: TDeviceCharacteristics;
  end;
  PFileFsDeviceInformation = ^TFileFsDeviceInformation;

  [FlagName(FILE_CASE_SENSITIVE_SEARCH, 'Case-sensitive Search')]
  [FlagName(FILE_CASE_PRESERVED_NAMES, 'Case-preserved Names')]
  [FlagName(FILE_UNICODE_ON_DISK, 'Unicode On Disk')]
  [FlagName(FILE_PERSISTENT_ACLS, 'Persistent ACLs')]
  [FlagName(FILE_FILE_COMPRESSION, 'Supports Compression')]
  [FlagName(FILE_VOLUME_QUOTAS, 'Volume Quotas')]
  [FlagName(FILE_SUPPORTS_SPARSE_FILES, 'Supports Sparse Files')]
  [FlagName(FILE_SUPPORTS_REPARSE_POINTS, 'Supports Reparse Points')]
  [FlagName(FILE_SUPPORTS_REMOTE_STORAGE, 'Supports Remote Storage')]
  [FlagName(FILE_RETURNS_CLEANUP_RESULT_INFO, 'Returns Cleanup Result Info')]
  [FlagName(FILE_SUPPORTS_POSIX_UNLINK_RENAME, 'Supports Posix Unlink Rename')]
  [FlagName(FILE_VOLUME_IS_COMPRESSED, 'Volume Is Compressed')]
  [FlagName(FILE_SUPPORTS_OBJECT_IDS, 'Supports Object IDs')]
  [FlagName(FILE_SUPPORTS_ENCRYPTION, 'Supports Encryption')]
  [FlagName(FILE_NAMED_STREAMS, 'Named Streams')]
  [FlagName(FILE_READ_ONLY_VOLUME, 'Read-only Volume')]
  [FlagName(FILE_SEQUENTIAL_WRITE_ONCE, 'Sequential Write Once')]
  [FlagName(FILE_SUPPORTS_TRANSACTIONS, 'Supports Transactions')]
  [FlagName(FILE_SUPPORTS_HARD_LINKS, 'Supports Hardlinks')]
  [FlagName(FILE_SUPPORTS_EXTENDED_ATTRIBUTES, 'Supports EA')]
  [FlagName(FILE_SUPPORTS_OPEN_BY_FILE_ID, 'Supports Open By ID')]
  [FlagName(FILE_SUPPORTS_USN_JOURNAL, 'Supports USN Journal')]
  [FlagName(FILE_SUPPORTS_INTEGRITY_STREAMS, 'Supports Integrity Streams')]
  [FlagName(FILE_SUPPORTS_BLOCK_REFCOUNTING, 'Supports Block Ref. Counting')]
  [FlagName(FILE_SUPPORTS_SPARSE_VDL, 'Supports Sparse VDL')]
  [FlagName(FILE_DAX_VOLUME, 'DAX Volume')]
  [FlagName(FILE_SUPPORTS_GHOSTING, 'Supports Ghosting')]
  TFileSystemAttributes = type Cardinal;

  // ntifs.6994, info class 5
  TFileFsAttributeInformation = record
    FileSystemAttributes: TFileSystemAttributes;
    MaximumComponentNameLength: Integer;
    [Counter(ctBytes)] FileSystemNameLength: Cardinal;
    FileSystemName: TAnysizeArray<WideChar>;
  end;
  PFileFsAttributeInformation = ^TFileFsAttributeInformation;

  // ntifs.7032, info class 6
  TFileFsControlInformation = record
    FreeSpaceStartFiltering: UInt64;
    FreeSpaceThreshold: UInt64;
    FreeSpaceStopFiltering: UInt64;
    DefaultQuotaThreshold: UInt64;
    DefaultQuotaLimit: UInt64;
    [Hex] FileSystemControlFlags: Cardinal; // FILE_VC_*
  end;
  PFileFsControlInformation = ^TFileFsControlInformation;

  // ntddk.4741, info class 7
  TFileFsFullSizeInformation = record
    TotalAllocationUnits: UInt64;
    CallerAvailableAllocationUnits: UInt64;
    ActualAvailableAllocationUnits: UInt64;
    SectorsPerAllocationUnit: Cardinal;
    [Bytes] BytesPerSector: Cardinal;
  end;
  PFileFsFullSizeInformation = ^TFileFsFullSizeInformation;

  // ntddk.4915, info class 8
  TFileFsObjectIdInformation = record
    ObjectID: TGuid;
    ExtendedInfo: array [0..2] of TGuid;
  end;
  PFileFsObjectIdInformation = ^TFileFsObjectIdInformation;

  // ntifs.7001, info class 9
  TFileFsDriverPathInformation = record
    DriverInPath: Boolean;
    [Counter(ctBytes)] DriverNameLength: Cardinal;
    DriverName: TAnysizeArray<WideChar>;
  end;
  PFileFsDriverPathInformation = ^TFileFsDriverPathInformation;

  // Notifications

  // wdm.6762
  [NamingStyle(nsCamelCase, 'DirectoryNotify'), Range(1)]
  TDirectoryNotifyInformationClass = (
    DirectoryNotifyReserved = 0,
    DirectoryNotifyInformation = 1,         // TFileNotifyInformation
    DirectoryNotifyExtendedInformation = 2  // TFileNotifyExtendedInformation
  );

  // ntifs.5994
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

  // ntifs.6183, info class 1
  TFileNotifyInformation = record
    NextEntryOffset: Cardinal;
    Action: TFileAction;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileNotifyInformation = ^TFileNotifyInformation;

  // ntifs.6191, info class 2
  [MinOsVersion(OsWin10RS3)]
  TFileNotifyExtendedInformation = record
    NextEntryOffset: Cardinal;
    Action: TFileAction;
    CreationTime: TLargeInteger;
    LastModificationTime: TLargeInteger;
    LastChangeTime: TLargeInteger;
    LastAccessTime: TLargeInteger;
    [Bytes] AllocatedLength: UInt64;
    [Bytes] FileSize: UInt64;
    FileAttributes: TFileAttributes;
    ReparsePointTag: Cardinal;
    FileID: UInt64;
    ParentFileID: UInt64;
    [Counter(ctBytes)] FileNameLength: Cardinal;
    FileName: TAnysizeArray<WideChar>;
  end;
  PFileNotifyExtendedInformation = ^TFileNotifyExtendedInformation;

// ntifs.7068
function NtCreateFile(out FileHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; out IoStatusBlock: TIoStatusBlock;
  AllocationSize: PLargeInteger; FileAttributes: Cardinal; ShareAccess:
  TFileShareMode; CreateDisposition: TFileDisposition; CreateOptions: Cardinal;
  EaBuffer: Pointer; EaLength: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtCreateNamedPipeFile(out FileHandle: THandle; DesiredAccess:
  TAccessMask; const ObjectAttributes: TObjectAttributes; out IoStatusBlock:
  TIoStatusBlock; ShareAccess: TFileShareMode; CreateDisposition:
  TFileDisposition; CreateOptions: Cardinal; NamedPipeType: Cardinal; ReadMode:
  TFilePipeReadMode; CompletionMode: TFilePipeCompletion; MaximumInstances:
  Cardinal; InboundQuota: Cardinal; OutboundQuota: Cardinal; DefaultTimeout:
  PULargeInteger): NTSTATUS; stdcall; external ntdll;

function NtCreateMailslotFile(out FileHandle: THandle; DesiredAccess:
  TAccessMask; const ObjectAttributes: TObjectAttributes; out IoStatusBlock:
  TIoStatusBlock; CreateOptions: Cardinal; MailslotQuota: Cardinal;
  MaximumMessageSize: Cardinal; const [ref] ReadTimeout: TULargeInteger):
  NTSTATUS; stdcall; external ntdll;

// ntifs.7148
function NtOpenFile(out FileHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; out IoStatusBlock: TIoStatusBlock;
  ShareAccess: TFileShareMode; OpenOptions: Cardinal): NTSTATUS; stdcall;
  external ntdll;

// ntifs.27829
function NtDeleteFile(const ObjectAttributes: TObjectAttributes): NTSTATUS;
  stdcall; external ntdll;

// ntifs.28249
function NtFlushBuffersFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock): NTSTATUS; stdcall; external ntdll;

// ntifs.7202
function NtQueryInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; FileInformation: Pointer; Length: Cardinal;
  FileInformationClass: TFileInformationClass): NTSTATUS; stdcall;
  external ntdll;

// wdm.40673, Win 10 RS2+
function NtQueryInformationByName(const ObjectAttributes: TObjectAttributes;
  out IoStatusBlock: TIoStatusBlock; FileInformation: Pointer; Length: Cardinal;
  FileInformationClass: TFileInformationClass): NTSTATUS; stdcall;
  external ntdll delayed;

// ntifs.7269
function NtSetInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; FileInformation: Pointer; Length: Cardinal;
  FileInformationClass: TFileInformationClass): NTSTATUS; stdcall;
  external ntdll;

// ntifs.7162
function NtQueryDirectoryFile(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock;
  FileInformation: Pointer; Length: Cardinal; FileInformationClass:
  TFileInformationClass; ReturnSingleEntry: Boolean; FileName: PNtUnicodeString;
  RestartScan: Boolean): NTSTATUS; stdcall; external ntdll;

// ntifs.28270
function NtQueryEaFile(FileHandle: THandle; out IoStatusBlock: TIoStatusBlock;
  Buffer: Pointer; Length: Cardinal; ReturnSingleEntry: Boolean; EaList:
  Pointer; EaListLength: Cardinal; EaIndex: PCardinal; RestartScan: Boolean):
  NTSTATUS; stdcall; external ntdll;

// ntifs.28284
function ZwSetEaFile(FileHandle: THandle; out IoStatusBlock: TIoStatusBlock;
  Buffer: Pointer; Length: Cardinal): NTSTATUS; stdcall; external ntdll;

// ntifs.7217
function NtQueryQuotaInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; Buffer: Pointer; Length: Cardinal; ReturnSingleEntry: Boolean;
  SidList: Pointer; SidListLength: Cardinal; StartSid: PSid; RestartScan:
  Boolean): NTSTATUS; stdcall; external ntdll;

// ntifs.7284
function NtSetQuotaInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; Buffer: Pointer; Length: Cardinal): NTSTATUS; stdcall;
  external ntdll;

// ntifs.7235
function NtQueryVolumeInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; FsInformation: Pointer; Length: Cardinal; FsInformationClass:
  TFsInfoClass): NTSTATUS; stdcall; external ntdll;

// ntifs.7296
function NtSetVolumeInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; FsInformation: Pointer; Length: Cardinal; FsInformationClass:
  TFsInfoClass): NTSTATUS; stdcall; external ntdll;

function NtCancelIoFile(FileHandle: THandle; out IoStatusBlock: TIoStatusBlock):
  NTSTATUS; stdcall; external ntdll;

function NtCancelIoFileEx(FileHandle: THandle; IoRequestToCancel:
  PIoStatusBlock; out IoStatusBlock: TIoStatusBlock): NTSTATUS; stdcall;
  external ntdll;

function NtCancelSynchronousIoFile(FileHandle: THandle; IoRequestToCancel:
  PIoStatusBlock; out IoStatusBlock: TIoStatusBlock): NTSTATUS; stdcall;
  external ntdll;

// ntifs.7090
function NtDeviceIoControlFile(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock;
  IoControlCode: Cardinal; InputBuffer: Pointer; InputBufferLength: Cardinal;
  OutputBuffer: Pointer; OutputBufferLength: Cardinal): NTSTATUS; stdcall;
  external ntdll;

// ntifs.7111
function NtFsControlFile(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock;
  FsControlCode: Cardinal; InputBuffer: Pointer; InputBufferLength: Cardinal;
  OutputBuffer: Pointer; OutputBufferLength: Cardinal): NTSTATUS; stdcall;
  external ntdll;

// ntifs.7249
function NtReadFile(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock; Buffer:
  Pointer; Length: Cardinal; ByteOffset: PUInt64; Key: PCardinal): NTSTATUS;
  stdcall; external ntdll;

// ntifs.7310
function NtWriteFile(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock; Buffer:
  Pointer; Length: Cardinal; ByteOffset: PUInt64; Key: PCardinal): NTSTATUS;
  stdcall; external ntdll;

function NtReadFileScatter(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock;
  SegmentArray: TArray<TFileSegmentElement>; Length: Cardinal; ByteOffset:
  PUInt64; Key: PCardinal): NTSTATUS; stdcall; external ntdll;

function NtWriteFileGather(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock;
  SegmentArray: TArray<TFileSegmentElement>; Length: Cardinal; ByteOffset:
  PUInt64; Key: PCardinal): NTSTATUS; stdcall; external ntdll;

// ntifs.7129
function NtLockFile(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock;
  const [ref] ByteOffset: UInt64; const [ref] Length: UInt64; Key: Cardinal;
  FailImmediately: Boolean; ExclusiveLock: Boolean): NTSTATUS; stdcall;
  external ntdll;

// ntifs.7327
function NtUnlockFile(FileHandle: THandle; Event: THandle; ApcRoutine:
  TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock: TIoStatusBlock;
  const [ref] ByteOffset: UInt64; const [ref] Length: UInt64; Key: Cardinal):
  NTSTATUS; stdcall; external ntdll;

function NtQueryAttributesFile(const ObjectAttributes: TObjectAttributes;
  out FileInformation: TFileBasicInformation): NTSTATUS; stdcall;
  external ntdll;

// wdm.40689
function NtQueryFullAttributesFile(const ObjectAttributes: TObjectAttributes;
   out FileInformation: TFileNetworkOpenInformation): NTSTATUS; stdcall;
   external ntdll;

function NtNotifyChangeDirectoryFile(FileHandle: THandle; Event: THandle;
  ApcRoutine: TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock:
  TIoStatusBlock; Buffer: PFileNotifyInformation; Length: Cardinal;
  CompletionFilter: Cardinal; WatchTree: Boolean): NTSTATUS; stdcall;
  external ntdll;

function NtNotifyChangeDirectoryFileEx(FileHandle: THandle; Event: THandle;
  ApcRoutine: TIoApcRoutine; ApcContext: Pointer; out IoStatusBlock:
  TIoStatusBlock; Buffer: Pointer; Length: Cardinal; CompletionFilter: Cardinal;
  WatchTree: Boolean; DirectoryNotifyInformationClass:
  TDirectoryNotifyInformationClass): NTSTATUS; stdcall; external ntdll;

// ntifs.4578
function CTL_CODE(DeviceType: TDeciveType; Func: Cardinal; Method:
  TIoControlMethod; Access: Cardinal): Cardinal;

implementation

function CTL_CODE(DeviceType: TDeciveType; Func: Cardinal; Method:
  TIoControlMethod; Access: Cardinal): Cardinal;
begin
  Result := (Cardinal(DeviceType) shl 16) or (Access shl 14) or (Func shl 2) or
    Cardinal(Method);
end;

end.
