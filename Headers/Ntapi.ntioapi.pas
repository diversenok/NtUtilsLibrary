unit Ntapi.ntioapi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef;

const
  // WinNt.12936
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

  // WinNt.12983
  FILE_SHARE_READ = $00000001;
  FILE_SHARE_WRITE = $00000002;
  FILE_SHARE_DELETE = $00000004;
  FILE_SHARE_ALL = FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE;

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

  // Create disposition
  FILE_SUPERSEDE = $00000000;
  FILE_OPEN = $00000001;
  FILE_CREATE = $00000002;
  FILE_OPEN_IF = $00000003;
  FILE_OVERWRITE = $00000004;
  FILE_OVERWRITE_IF = $00000005;
  FILE_MAXIMUM_DISPOSITION = $00000005;

  // Create/open flags
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
  FILE_SESSION_AWARE = $00040000;

  // IO status results
  FILE_SUPERSEDED = $00000000;
  FILE_OPENED = $00000001;
  FILE_CREATED = $00000002;
  FILE_OVERWRITTEN = $00000003;
  FILE_EXISTS = $00000004;
  FILE_DOES_NOT_EXIST = $00000005;

type
  TIoStatusBlock = record
    Status: NTSTATUS;
    {$IFDEF WIN64}
    Padding: Cardinal;
    {$ENDIF}
    Information: NativeUInt;
  end;
  PIoStatusBlock = ^TIoStatusBlock;

  TFileInformationClass = (
    FileReserved = 0,
    FileDirectoryInformation = 1,     //
    FileFullDirectoryInformation = 2, //
    FileBothDirectoryInformation = 3, //
    FileBasicInformation = 4,         // q, s: TFileBasicInformation
    FileStandardInformation = 5,      // q: TFileStandardInformation
    FileInternalInformation = 6,      // q:
    FileEaInformation = 7,            // q: Cardinal (Size)
    FileAccessInformation = 8,        // q: TAccessMask
    FileNameInformation = 9,          // q: TFileNameInformation
    FileRenameInformation = 10,       // s: TFileRenameInformation
    FileLinkInformation = 11,         // s: TFileLinkInformation
    FileNamesInformation = 12,        // q:
    FileDispositionInformation = 13,  // s: Boolean (Delete file)
    FilePositionInformation = 14,     // q, s: UInt64 (Byte offset)
    FileFullEaInformation = 15,       // q:
    FileModeInformation = 16,         // q, s: Cardinal
    FileAlignmentInformation = 17,    // q: Cardinal
    FileAllInformation = 18,          // q:
    FileAllocationInformation = 19,   // s: UInt64 (Size)
    FileEndOfFileInformation = 20,    // s: UInt64
    FileAlternateNameInformation = 21,// q:
    FileStreamInformation = 22,       // q: TFileStreamInformation
    FilePipeInformation = 23,         // q, s:
    FilePipeLocalInformation = 24,    // q:
    FilePipeRemoteInformation = 25,   // q, s:
    FileMailslotQueryInformation = 26,// q:
    FileMailslotSetInformation = 27,  // s:
    FileCompressionInformation = 28,  // q: TFileCompressionInformation
    FileObjectIdInformation = 29,     // q, s:
    FileCompletionInformation = 30,   // s:
    FileMoveClusterInformation = 31,  // s:
    FileQuotaInformation = 32,        // q, s:
    FileReparsePointInformation = 33, // q: TFileReparsePointInformation
    FileNetworkOpenInformation = 34,  // q:
    FileAttributeTagInformation = 35, // q: TFileAttributeTagInformation
    FileTrackingInformation = 36,     // s:
    FileIdBothDirectoryInformation = 37, //
    FileIdFullDirectoryInformation = 38, //
    FileValidDataLengthInformation = 39, // s: UInt64
    FileShortNameInformation = 40,       // s:
    FileIoCompletionNotificationInformation = 41, // q, s:
    FileIoStatusBlockRangeInformation = 42, // s:
    FileIoPriorityHintInformation = 43,  // q, s:
    FileSfioReserveInformation = 44,     // q, s:
    FileSfioVolumeInformation = 45,      // q:
    FileHardLinkInformation = 46         // q: TFileLinksInformation
  );

  // FileBasicInformation
  TFileBasicInformation = record
    CreationTime: TLargeInteger;
    LastAccessTime: TLargeInteger;
    LastWriteTime: TLargeInteger;
    ChangeTime: TLargeInteger;
    FileAttributes: Cardinal;
  end;
  PFileBasicInformation = ^TFileBasicInformation;

  // FileStandardInformation
  TFileStandardInformation = record
    AllocationSize: UInt64;
    EndOfFile: UInt64;
    NumberOfLinks: Cardinal;
    DeletePending: Boolean;
    Directory: Boolean;
  end;
  PFileStandardInformation = ^TFileStandardInformation;

  // FileNameInformation
  TFileNameInformation = record
    FileNameLength: Cardinal;
    FileName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileNameInformation = ^TFileNameInformation;

  // FileRenameInformation
  TFileRenameInformation = record
    ReplaceIfExists: Boolean;
    RootDirectory: THandle;
    FileNameLength: Cardinal;
    FileName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileRenameInformation = ^TFileRenameInformation;

  // FileLinkInformation
  TFileLinkInformation = TFileRenameInformation;
  PFileLinkInformation = ^TFileLinkInformation;

  // FileStreamInformation
  TFileStreamInformation = record
    NextEntryOffset: Cardinal;
    StreamNameLength: Cardinal;
    StreamSize: UInt64;
    StreamAllocationSize: UInt64;
    StreamName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileStreamInformation = ^TFileStreamInformation;

  // FileCompressionInformation
  TFileCompressionInformation = record
    CompressedFileSize: UInt64;
    CompressionFormat: Word;
    CompressionUnitShift: Byte;
    ChunkShift: Byte;
    ClusterShift: Byte;
    Reserved: array [0..2] of Byte;
  end;
  PFileCompressionInformation = ^TFileCompressionInformation;

  // FileReparsePointInformation
  TFileReparsePointInformation = record
    FileReference: Int64;
    Tag: Cardinal;
  end;
  PFileReparsePointInformation = ^TFileReparsePointInformation;

  // FileAttributeTagInformation
  TFileAttributeTagInformation = record
    FileAttributes: Cardinal;
    ReparseTag: Cardinal;
  end;
  PFileAttributeTagInformation = ^TFileAttributeTagInformation;

  TFileLinkEntryInformation = record
    NextEntryOffset: Cardinal;
    ParentFileId: Int64;
    FileNameLength: Cardinal;
    FileName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileLinkEntryInformation = ^TFileLinkEntryInformation;

  // FileHardLinkInformation
  TFileLinksInformation = record
    BytesNeeded: Cardinal;
    EntriesReturned: Cardinal;
    Entry: TFileLinkEntryInformation;
  end;
  PFileLinksInformation = ^TFileLinksInformation;

  TFsInfoClass = (
    FileFsReserved = 0,
    FileFsVolumeInformation = 1,      // q: TFileFsVolumeInformation
    FileFsLabelInformation = 2,       // s: TFileFsLabelInformation
    FileFsSizeInformation = 3,        // q: TFileFsSizeInformation
    FileFsDeviceInformation = 4,      // q:
    FileFsAttributeInformation = 5,   // q:
    FileFsControlInformation = 6,     // q, s:
    FileFsFullSizeInformation = 7,    // q:
    FileFsObjectIdInformation = 8,    // q, s:
    FileFsDriverPathInformation = 9,  // q:
    FileFsVolumeFlagsInformation = 10 // q, s: Cardinal
  );

  // FileFsVolumeInformation
  TFileFsVolumeInformation = record
    VolumeCreationTime: TLargeInteger;
    VolumeSerialNumber: Cardinal;
    VolumeLabelLength: Cardinal;
    SupportsObjects: Boolean;
    VolumeLabel: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileFsVolumeInformation = ^TFileFsVolumeInformation;

  // FileFsLabelInformation
  TFileFsLabelInformation = record
    VolumeLabelLength: Cardinal;
    VolumeLabel: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileFsLabelInformation = ^TFileFsLabelInformation;

  // FileFsSizeInformation
  TFileFsSizeInformation = record
    TotalAllocationUnits: UInt64;
    AvailableAllocationUnits: UInt64;
    SectorsPerAllocationUnit: Cardinal;
    BytesPerSector: Cardinal;
  end;
  PFileFsSizeInformation = ^TFileFsSizeInformation;

function NtCreateFile(out FileHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; out IoStatusBlock: TIoStatusBlock;
  AllocationSize: PLargeInteger; FileAttributes: Cardinal; ShareAccess:
  Cardinal; CreateDisposition: Cardinal; CreateOptions: Cardinal;
  EaBuffer: Pointer; EaLength: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtOpenFile(out FileHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; out IoStatusBlock: TIoStatusBlock;
  ShareAccess: Cardinal; OpenOptions: Cardinal): NTSTATUS; stdcall;
  external ntdll;

function NtDeleteFile(const ObjectAttributes: TObjectAttributes): NTSTATUS;
  stdcall; external ntdll;

function NtFlushBuffersFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock): NTSTATUS; stdcall; external ntdll;

function NtQueryInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; FileInformation: Pointer; Length: Cardinal;
  FileInformationClass: TFileInformationClass): NTSTATUS; stdcall;
  external ntdll;

function NtSetInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; FileInformation: Pointer; Length: Cardinal;
  FileInformationClass: TFileInformationClass): NTSTATUS; stdcall;
  external ntdll;

function NtQueryVolumeInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; FsInformation: Pointer; Length: Cardinal; FsInformationClass:
  TFsInfoClass): NTSTATUS; stdcall; external ntdll;

function NtSetVolumeInformationFile(FileHandle: THandle; out IoStatusBlock:
  TIoStatusBlock; FsInformation: Pointer; Length: Cardinal; FsInformationClass:
  TFsInfoClass): NTSTATUS; stdcall; external ntdll;

implementation

end.
