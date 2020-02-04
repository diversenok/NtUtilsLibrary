unit Ntapi.ntioapi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

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

  FileAccessMapping: array [0..7] of TFlagName = (
    (Value: FILE_READ_DATA;        Name: 'Read data'),
    (Value: FILE_WRITE_DATA;       Name: 'Write data'),
    (Value: FILE_APPEND_DATA;      Name: 'Append data'),
    (Value: FILE_READ_EA;          Name: 'Read extended attributes'),
    (Value: FILE_WRITE_EA;         Name: 'Write extended attributes'),
    (Value: FILE_EXECUTE;          Name: 'Execute'),
    (Value: FILE_READ_ATTRIBUTES;  Name: 'Read attributes'),
    (Value: FILE_WRITE_ATTRIBUTES; Name: 'Write attributes')
  );

  FileAccessType: TAccessMaskType = (
    TypeName: 'file';
    FullAccess: FILE_ALL_ACCESS;
    Count: Length(FileAccessMapping);
    Mapping: PFlagNameRefs(@FileAccessMapping);
  );

  FsDirectoryAccessMapping: array [0..8] of TFlagName = (
    (Value: FILE_LIST_DIRECTORY;   Name: 'List directory'),
    (Value: FILE_ADD_FILE;         Name: 'Add file'),
    (Value: FILE_ADD_SUBDIRECTORY; Name: 'Add sub-directory'),
    (Value: FILE_READ_EA;          Name: 'Read extended attributes'),
    (Value: FILE_WRITE_EA;         Name: 'Write extended attributes'),
    (Value: FILE_TRAVERSE;         Name: 'Traverse'),
    (Value: FILE_DELETE_CHILD;     Name: 'Delete child'),
    (Value: FILE_READ_ATTRIBUTES;  Name: 'Read attributes'),
    (Value: FILE_WRITE_ATTRIBUTES; Name: 'Write attributes')
  );

  FsDirectoryAccessType: TAccessMaskType = (
    TypeName: 'directory';
    FullAccess: FILE_ALL_ACCESS;
    Count: Length(FsDirectoryAccessMapping);
    Mapping: PFlagNameRefs(@FsDirectoryAccessMapping);
  );

  PipeAccessMapping: array [0..4] of TFlagName = (
    (Value: FILE_READ_DATA;            Name: 'Read data'),
    (Value: FILE_WRITE_DATA;           Name: 'Write data'),
    (Value: FILE_CREATE_PIPE_INSTANCE; Name: 'Create pipe instance'),
    (Value: FILE_READ_ATTRIBUTES;      Name: 'Read attributes'),
    (Value: FILE_WRITE_ATTRIBUTES;     Name: 'Write attributes')
  );

  PipeAccessType: TAccessMaskType = (
    TypeName: 'pipe';
    FullAccess: FILE_ALL_ACCESS;
    Count: Length(PipeAccessMapping);
    Mapping: PFlagNameRefs(@PipeAccessMapping);
  );

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

  // IO Completion

  IO_COMPLETION_QUERY_STATE = $0001;
  IO_COMPLETION_MODIFY_STATE = $0002;

  IO_COMPLETION_ALL_ACCESS = STANDARD_RIGHTS_ALL or $03;

  IoCompletionAccessMapping: array [0..1] of TFlagName = (
    (Value: IO_COMPLETION_QUERY_STATE;  Name: 'Query'),
    (Value: IO_COMPLETION_MODIFY_STATE; Name: 'Modify')
  );

  IoCompletionAccessType: TAccessMaskType = (
    TypeName: 'IO completion';
    FullAccess: IO_COMPLETION_ALL_ACCESS;
    Count: Length(IoCompletionAccessMapping);
    Mapping: PFlagNameRefs(@IoCompletionAccessMapping);
  );

type
  [NamingStyle(nsSnakeCase, 'FILE')]
  TFileDisposition = (
    FILE_SUPERSEDE = 0,
    FILE_OPEN = 1,
    FILE_CREATE = 2,
    FILE_OPEN_IF = 3,
    FILE_OVERWRITE = 4,
    FILE_OVERWRITE_IF = 5
  );

  [NamingStyle(nsSnakeCase, 'FILE')]
  TFileIoStatusResult = (
    FILE_SUPERSEDED = 0,
    FILE_OPENED = 1,
    FILE_CREATED = 2,
    FILE_OVERWRITTEN = 3,
    FILE_EXISTS = 4,
    FILE_DOES_NOT_EXIST = 5
  );

  TIoStatusBlock = record
  case Integer of
    0: (Pointer: Pointer; Result: TFileIoStatusResult);
    1: (Status: NTSTATUS; Information: NativeUInt);
  end;
  PIoStatusBlock = ^TIoStatusBlock;

  [NamingStyle(nsCamelCase, 'File'), MinValue(1)]
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
    [Hex] FileAttributes: Cardinal; // FILE_ATTRIBUTE_*
  end;
  PFileBasicInformation = ^TFileBasicInformation;

  // FileStandardInformation
  TFileStandardInformation = record
    [Bytes] AllocationSize: UInt64;
    [Bytes] EndOfFile: UInt64;
    NumberOfLinks: Cardinal;
    DeletePending: Boolean;
    Directory: Boolean;
  end;
  PFileStandardInformation = ^TFileStandardInformation;

  // FileNameInformation
  TFileNameInformation = record
    [Bytes] FileNameLength: Cardinal;
    FileName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileNameInformation = ^TFileNameInformation;

  // FileRenameInformation
  TFileRenameInformation = record
    ReplaceIfExists: Boolean;
    RootDirectory: THandle;
    [Bytes] FileNameLength: Cardinal;
    FileName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileRenameInformation = ^TFileRenameInformation;

  // FileLinkInformation
  TFileLinkInformation = TFileRenameInformation;
  PFileLinkInformation = ^TFileLinkInformation;

  // FileStreamInformation
  TFileStreamInformation = record
    [Hex] NextEntryOffset: Cardinal;
    [Bytes] StreamNameLength: Cardinal;
    [Bytes] StreamSize: UInt64;
    [Bytes] StreamAllocationSize: UInt64;
    StreamName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileStreamInformation = ^TFileStreamInformation;

  // FileCompressionInformation
  TFileCompressionInformation = record
    [Bytes] CompressedFileSize: UInt64;
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
    [Hex] FileAttributes: Cardinal;
    ReparseTag: Cardinal;
  end;
  PFileAttributeTagInformation = ^TFileAttributeTagInformation;

  TFileLinkEntryInformation = record
    [Hex] NextEntryOffset: Cardinal;
    ParentFileId: Int64;
    [Bytes] FileNameLength: Cardinal;
    FileName: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileLinkEntryInformation = ^TFileLinkEntryInformation;

  // FileHardLinkInformation
  TFileLinksInformation = record
    [Bytes] BytesNeeded: Cardinal;
    EntriesReturned: Cardinal;
    Entry: TFileLinkEntryInformation;
  end;
  PFileLinksInformation = ^TFileLinksInformation;

  [NamingStyle(nsCamelCase, 'FileFs'), MinValue(1)]
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
    [Bytes] VolumeLabelLength: Cardinal;
    VolumeLabel: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PFileFsLabelInformation = ^TFileFsLabelInformation;

  // FileFsSizeInformation
  TFileFsSizeInformation = record
    TotalAllocationUnits: UInt64;
    AvailableAllocationUnits: UInt64;
    SectorsPerAllocationUnit: Cardinal;
    [Bytes] BytesPerSector: Cardinal;
  end;
  PFileFsSizeInformation = ^TFileFsSizeInformation;

function NtCreateFile(out FileHandle: THandle; DesiredAccess: TAccessMask;
  const ObjectAttributes: TObjectAttributes; out IoStatusBlock: TIoStatusBlock;
  AllocationSize: PLargeInteger; FileAttributes: Cardinal; ShareAccess:
  Cardinal; CreateDisposition: TFileDisposition; CreateOptions: Cardinal;
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
