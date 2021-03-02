unit Ntapi.ntregapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, DelphiApi.Reflection;

const
  REG_PATH_MACHINE = '\Registry\Machine';
  REG_PATH_USER = '\Registry\User';
  REG_PATH_USER_DEFAULT = '\Registry\User\.Default';
  REG_PATH_APPKEY = '\Registry\A';
  REG_PATH_CONTAINERS = '\Registry\WC';

  REG_SYMLINK_VALUE_NAME = 'SymbolicLinkValue';

  // WinNt.21186, access masks
  KEY_QUERY_VALUE = $0001;
  KEY_SET_VALUE = $0002;
  KEY_CREATE_SUB_KEY = $0004;
  KEY_ENUMERATE_SUB_KEYS = $0008;
  KEY_NOTIFY = $0010;
  KEY_CREATE_LINK = $0020;

  KEY_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

  // WinNt.21230, open/create options
  REG_OPTION_VOLATILE = $00000001;
  REG_OPTION_CREATE_LINK = $00000002;
  REG_OPTION_BACKUP_RESTORE = $00000004;
  REG_OPTION_OPEN_LINK = $00000008;
  REG_OPTION_DONT_VIRTUALIZE = $00000010;

  // WinNt.21285, load/restore flags
  REG_WHOLE_HIVE_VOLATILE = $00000001;    // Restore whole hive volatile
  REG_REFRESH_HIVE = $00000002;           // Unwind changes to last flush
  REG_NO_LAZY_FLUSH = $00000004;          // Never lazy flush this hive
  REG_FORCE_RESTORE = $00000008;          // Force the restore process even when we have open handles on subkeys
  REG_APP_HIVE = $00000010;               // Loads the hive visible to the calling process
  REG_PROCESS_PRIVATE = $00000020;        // Hive cannot be mounted by any other process while in use
  REG_START_JOURNAL = $00000040;          // Starts Hive Journal
  REG_HIVE_EXACT_FILE_GROWTH = $00000080; // Grow hive file in exact 4k increments
  REG_HIVE_NO_RM = $00000100;             // No RM is started for this hive (no transactions)
  REG_HIVE_SINGLE_LOG = $00000200;        // Legacy single logging is used for this hive
  REG_BOOT_HIVE = $00000400;              // This hive might be used by the OS loader
  REG_LOAD_HIVE_OPEN_HANDLE = $00000800;  // Load the hive and return a handle to its root kcb
  REG_FLUSH_HIVE_FILE_GROWTH = $00001000; // Flush changes to primary hive file size as part of all flushes
  REG_OPEN_READ_ONLY = $00002000;         // Open a hive's files in read-only mode
  REG_IMMUTABLE = $00004000;              // Load the hive, but don't allow any modification of it

  // Unload flags
  REG_FORCE_UNLOAD = $0001;

  // Flags, rev
  REG_FLAG_VOLATILE = $0001;
  REG_FLAG_LINK = $0002;

  // Control flags, rev from reg.exe
  REG_KEY_DONT_VIRTUALIZE = $0002;
  REG_KEY_DONT_SILENT_FAIL = $0004;
  REG_KEY_RECURSE_FLAG = $0008;

  // bits from ntddk.4966
  REG_GET_VIRTUAL_CANDIDATE = $0001;
  REG_GET_VIRTUAL_ENABLED = $0002;
  REG_GET_VIRTUAL_TARGET = $0004;
  REG_GET_VIRTUAL_STORE = $0008;
  REG_GET_VIRTUAL_SOURCE = $0010;

  // bits from wdm.7403
  REG_SET_VIRTUAL_TARGET = $0001;
  REG_SET_VIRTUAL_STORE = $0002;
  REG_SET_VIRTUAL_SOURCE = $0004;

  // winnt.21739
  REG_NOTIFY_CHANGE_NAME = $00000001;
  REG_NOTIFY_CHANGE_ATTRIBUTES = $00000002;
  REG_NOTIFY_CHANGE_LAST_SET = $00000004;
  REG_NOTIFY_CHANGE_SECURITY = $00000008;
  REG_NOTIFY_CHANGE_ALL = $0000000F;
  REG_NOTIFY_THREAD_AGNOSTIC = $10000000; // Windows 8+

type
  [FriendlyName('registry'), ValidMask(KEY_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(KEY_QUERY_VALUE, 'Query Values')]
  [FlagName(KEY_SET_VALUE, 'Set Values')]
  [FlagName(KEY_CREATE_SUB_KEY, 'Create Sub-keys')]
  [FlagName(KEY_ENUMERATE_SUB_KEYS, 'Enumerate Sub-keys')]
  [FlagName(KEY_NOTIFY, 'Notify Changes')]
  [FlagName(KEY_CREATE_LINK, 'Create Links')]
  TRegKeyAccessMask = type TAccessMask;

  [FlagName(REG_OPTION_VOLATILE, 'Volatile')]
  [FlagName(REG_OPTION_CREATE_LINK, 'Create Link')]
  [FlagName(REG_OPTION_BACKUP_RESTORE, 'Backup/Restore')]
  [FlagName(REG_OPTION_OPEN_LINK, 'Open Link')]
  [FlagName(REG_OPTION_DONT_VIRTUALIZE, 'Don''t Virtualize')]
  TRegOpenOptions = type Cardinal;

  [FlagName(REG_NOTIFY_CHANGE_NAME, 'Name')]
  [FlagName(REG_NOTIFY_CHANGE_ATTRIBUTES, 'Attributes')]
  [FlagName(REG_NOTIFY_CHANGE_LAST_SET, 'Last Set')]
  [FlagName(REG_NOTIFY_CHANGE_SECURITY, 'Security')]
  [FlagName(REG_NOTIFY_THREAD_AGNOSTIC, 'Thread-Agnostic')]
  TRegNotifyFlags = type Cardinal;

  // WinNt.21271
  [NamingStyle(nsSnakeCase, 'REG'), Range(1)]
  TRegDisposition = (
    REG_DISPOSITION_RESERVED = 0,
    REG_CREATED_NEW_KEY = 1,
    REG_OPENED_EXISTING_KEY = 2
  );
  PRegDisposition = ^TRegDisposition;

  // WinNt.21333, value types
  TRegValueType = (
    REG_NONE = 0,
    REG_SZ = 1,
    REG_EXPAND_SZ = 2,
    REG_BINARY = 3,
    REG_DWORD = 4,
    REG_DWORD_BIG_ENDIAN = 5,
    REG_LINK = 6,
    REG_MULTI_SZ = 7,
    REG_RESOURCE_LIST = 8,
    REG_FULL_RESOURCE_DESCRIPTOR = 9,
    REG_RESOURCE_REQUIREMENTS_LIST = 10,
    REG_QWORD = 11
  );

  // wdm.7377
  [NamingStyle(nsCamelCase, 'Key')]
  TKeyInformationClass = (
    KeyBasicInformation = 0,          // TKeyBasicInformation
    KeyNodeInformation = 1,
    KeyFullInformation = 2,
    KeyNameInformation = 3,           // TKeyNameInformation
    KeyCachedInformation = 4,         // TKeyCachedInformation
    KeyFlagsInformation = 5,          // TKeyFlagsInformation
    KeyVirtualizationInformation = 6, // Cardinal, REG_GET_VIRTUAL_*
    KeyHandleTagsInformation = 7,     // Cardinal
    KeyTrustInformation = 8,          // Cardinal
    KeyLayerInformation = 9
  );

  // wdm.7346
  TKeyBasicInformation = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyBasicInformation = ^TKeyBasicInformation;

  // ntddk.4950
  TKeyNameInformation = record
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyNameInformation = ^TKeyNameInformation;

  // ntddk.4955
  TKeyCachedInformation = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    SubKeys: Cardinal;
    MaxNameLen: Cardinal;
    Values: Cardinal;
    MaxValueNameLen: Cardinal;
    MaxValueDataLen: Cardinal;
    NameLength: Cardinal;
  end;
  PKeyCachedInformation = ^TKeyCachedInformation;

  [FlagName(REG_FLAG_VOLATILE, 'Volatile')]
  [FlagName(REG_FLAG_LINK, 'Symbolic Link')]
  TKeyFlags = type Cardinal;

  [FlagName(REG_KEY_DONT_VIRTUALIZE, 'No Virtualize')]
  [FlagName(REG_KEY_DONT_SILENT_FAIL, 'No Silent Fail')]
  [FlagName(REG_KEY_RECURSE_FLAG, 'Recursive')]
  TKeyControlFlags = type Cardinal;

  TKeyFlagsInformation = record
    [Hex] Wow64Flags: Cardinal;
    KeyFlags: TKeyFlags;
    ControlFlags: TKeyControlFlags;
  end;
  PKeyFlagsInformation = ^TKeyFlagsInformation;

  // wdm.7411
  [NamingStyle(nsCamelCase, 'Key')]
  TKeySetInformationClass = (
    KeyWriteTimeInformation = 0,         // TLargeInteger
    KeyWow64FlagsInformation = 1,        // Cardinal
    KeyControlFlagsInformation = 2,      // Cardinal, REG_KEY_*
    KeySetVirtualizationInformation = 3, // Cardinal, REG_SET_VIRTUAL_*
    KeySetDebugInformation = 4,
    KeySetHandleTagsInformation = 5,     // Cardinal
    KeySetLayerInformation = 6           // Cardinal
  );

  // wdm.7469
  [NamingStyle(nsCamelCase, 'KeyValue')]
  TKeyValueInformationClass = (
    KeyValueBasicInformation = 0,       // TKeyValueBasicInformation
    KeyValueFullInformation = 1,
    KeyValuePartialInformation = 2,     // TKeyValuePartialInfromation
    KeyValueFullInformationAlign64 = 3,
    KeyValuePartialInformationAlign64 = 4,
    KeyValueLayerInformation = 5
  );

  // wdm.7427
  TKeyValueBasicInformation = record
    TitleIndex: Cardinal;
    ValueType: TRegValueType;
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyValueBasicInformation = ^TKeyValueBasicInformation;

  // wdm.7444
  TKeyValuePartialInfromation = record
    TitleIndex: Cardinal;
    ValueType: TRegValueType;
    [Counter(ctBytes)] DataLength: Cardinal;
    Data: TAnysizeArray<Byte>;
  end;
  PKeyValuePartialInfromation = ^TKeyValuePartialInfromation;

  [NamingStyle(nsCamelCase, 'KeyLoad'), RangeAttribute(1)]
  TKeyLoadHandleType = (
    KeyLoadReserved = 0,
    KeyLoadTrustClassKey = 1,
    KeyLoadEvent = 2,
    KeyLoadToken = 3
  );

  TKeyLoadHandle = record
    HandleType: TKeyLoadHandleType;
    Handle: THandle;
  end;

  TKeyPidInformation = record
    ProcessId: TProcessId;
    KeyName: TNtUnicodeString;
  end;

  TKeyOpenSubkeysInformation = record
    [Counter] Count: Cardinal;
    KeyArray: TAnysizeArray<TKeyPidInformation>;
  end;
  PKeyOpenSubkeysInformation = ^TKeyOpenSubkeysInformation;

function NtCreateKey(
  out KeyHandle: THandle;
  DesiredAccess: TRegKeyAccessMask;
  ObjectAttributes: PObjectAttributes;
  TitleIndex: Cardinal;
  ClassName: PNtUnicodeString;
  CreateOptions: TRegOpenOptions;
  Disposition: PRegDisposition
): NTSTATUS; stdcall; external ntdll;

function NtCreateKeyTransacted(
  out KeyHandle: THandle;
  DesiredAccess: TRegKeyAccessMask;
  ObjectAttributes: PObjectAttributes;
  TitleIndex: Cardinal;
  ClassName: PNtUnicodeString;
  CreateOptions: TRegOpenOptions;
  TransactionHandle: THandle;
  Disposition: PRegDisposition
): NTSTATUS; stdcall; external ntdll;

function NtOpenKeyEx(
  out KeyHandle: THandle;
  DesiredAccess: TRegKeyAccessMask;
  ObjectAttributes: PObjectAttributes;
  OpenOptions: TRegOpenOptions
): NTSTATUS; stdcall; external ntdll;

function NtOpenKeyTransactedEx(
  out KeyHandle: THandle;
  DesiredAccess: TRegKeyAccessMask;
  ObjectAttributes: PObjectAttributes;
  OpenOptions: TRegOpenOptions;
  TransactionHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtDeleteKey(
  KeyHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtRenameKey(
  KeyHandle: THandle;
  const NewName: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function NtDeleteValueKey(
  KeyHandle: THandle;
  const ValueName: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

function NtQueryKey(
  KeyHandle: THandle;
  KeyInformationClass: TKeyInformationClass;
  KeyInformation: Pointer;
  Length: Cardinal;
  out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtSetInformationKey(
  KeyHandle: THandle;
  KeySetInformationClass: TKeySetInformationClass;
  KeySetInformation: Pointer;
  KeySetInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtQueryValueKey(
  KeyHandle: THandle;
  const ValueName: TNtUnicodeString;
  KeyValueInformationClass: TKeyValueInformationClass;
  KeyValueInformation: Pointer;
  Length: Cardinal;
  out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtSetValueKey(
  KeyHandle: THandle;
  const ValueName: TNtUnicodeString;
  TitleIndex: Cardinal;
  ValueType: TRegValueType;
  Data: Pointer;
  DataSize: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtEnumerateKey(
  KeyHandle: THandle;
  Index: Cardinal;
  KeyInformationClass: TKeyInformationClass;
  KeyInformation: Pointer;
  Length: Cardinal;
  out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtEnumerateValueKey(
  KeyHandle: THandle;
  Index: Cardinal;
  KeyValueInformationClass: TKeyValueInformationClass;
  KeyValueInformation: Pointer;
  Length: Cardinal;
  out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtFlushKey(
  KeyHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtCompressKey(
  Key: THandle
): NTSTATUS; stdcall; external ntdll;

function NtLoadKeyEx(
  TargetKey: PObjectAttributes;
  SourceFile: PObjectAttributes;
  Flags: Cardinal;
  TrustClassKey: THandle;
  Event: THandle;
  DesiredAccess: TRegKeyAccessMask;
  out RootHandle: THandle;
  IoStatus: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll;

// Win10 20H1+
function NtLoadKey3(
  const TargetKey: TObjectAttributes;
  const SourceFile: TObjectAttributes;
  Flags: Cardinal;
  LoadEntries: TArray<TKeyLoadHandle>;
  LoadEntryCount: Cardinal;
  DesiredAccess: TRegKeyAccessMask;
  out RootHandle: THandle;
  IoStatus: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll delayed;

function NtSaveKey(
  KeyHandle: THandle;
  FileHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtUnloadKey2(
  TargetKey: PObjectAttributes;
  Flags: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtQueryOpenSubKeys(
  const TargetKey: TObjectAttributes;
  out HandleCount: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtQueryOpenSubKeysEx(
  TargetKey: PObjectAttributes;
  BufferLength: Cardinal;
  Buffer: PKeyOpenSubkeysInformation;
  out RequiredSize: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtNotifyChangeKey(
  KeyHandle: THandle;
  Event: THandle;
  ApcRoutine: TIoApcRoutine;
  ApcContext: Pointer;
  IoStatusBlock: PIoStatusBlock;
  CompletionFilter: TRegNotifyFlags;
  WatchTree: Boolean;
  Buffer: Pointer;
  BufferSize: Cardinal;
  Asynchronous: Boolean
): NTSTATUS; stdcall; external ntdll;

function NtFreezeRegistry(
  TimeOutInSeconds: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtThawRegistry: NTSTATUS; stdcall; external ntdll;

implementation

end.
