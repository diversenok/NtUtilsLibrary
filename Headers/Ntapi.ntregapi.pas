unit Ntapi.ntregapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, NtUtils.Version,
  DelphiApi.Reflection;

const
  REG_PATH_MACHINE = '\Registry\Machine';
  REG_PATH_USER = '\Registry\User';
  REG_PATH_USER_DEFAULT = '\Registry\User\.Default';
  REG_PATH_APPKEY = '\Registry\A';
  REG_PATH_CONTAINERS = '\Registry\WC';

  REG_SYMLINK_VALUE_NAME = 'SymbolicLinkValue';

  // WinNt.21612, access masks
  KEY_QUERY_VALUE = $0001;
  KEY_SET_VALUE = $0002;
  KEY_CREATE_SUB_KEY = $0004;
  KEY_ENUMERATE_SUB_KEYS = $0008;
  KEY_NOTIFY = $0010;
  KEY_CREATE_LINK = $0020;

  KEY_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

  // WinNt.21653, open/create options
  REG_OPTION_VOLATILE = $00000001;
  REG_OPTION_CREATE_LINK = $00000002;
  REG_OPTION_BACKUP_RESTORE = $00000004;
  REG_OPTION_OPEN_LINK = $00000008;
  REG_OPTION_DONT_VIRTUALIZE = $00000010;

  // WinNt.21703, flags for NtSaveKeyEx
  REG_STANDARD_FORMAT = $01;
  REG_LATEST_FORMAT = $02;
  REG_NO_COMPRESSION = $04;

  // WinNt.21711, load/restore flags
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
  REG_NO_IMPERSONATION_FALLBACK = $00008000; // Do not fall back to impersonating the caller if hive file access fails

  // WinNt.21732, unload flags
  REG_FORCE_UNLOAD = $0001;

  // rev, KeyFlagsInformation
  REG_FLAG_VOLATILE = $0001;
  REG_FLAG_LINK = $0002;

  // MSDN, control flags
  REG_KEY_DONT_VIRTUALIZE = $0002;
  REG_KEY_DONT_SILENT_FAIL = $0004;
  REG_KEY_RECURSE_FLAG = $0008;

  // ntddk.5003 (bits), KeyVirtualizationInformation
  REG_GET_VIRTUAL_CANDIDATE = $0001;
  REG_GET_VIRTUAL_ENABLED = $0002;
  REG_GET_VIRTUAL_TARGET = $0004;
  REG_GET_VIRTUAL_STORE = $0008;
  REG_GET_VIRTUAL_SOURCE = $0010;

  // wdm.7505 (bits), KeyTrustInformation
  REG_KEY_TRUSTED_KEY = $0001;

  // wdm.7427 (bits), KeySetVirtualizationInformation
  REG_SET_VIRTUAL_TARGET = $0001;
  REG_SET_VIRTUAL_STORE = $0002;
  REG_SET_VIRTUAL_SOURCE = $0004;

  // ntddk.5012 (bits), KeyLayerInformation
  REG_KEY_LAYER_IS_TOMBSTONE = $0001;
  REG_KEY_LAYER_IS_SUPERSEDE_LOCAL = $0002;
  REG_KEY_LAYER_IS_SUPERSEDE_TREE = $0004;
  REG_KEY_LAYER_CLASS_IS_INHERITED = $0008;

  // wdm.7481 (bits), KeyValueLayerInformation
  REG_KEY_VALUE_LAYER_IS_TOMBSTONE = $0001;

  // WinNt.21739, notify filters
  REG_NOTIFY_CHANGE_NAME = $00000001;
  REG_NOTIFY_CHANGE_ATTRIBUTES = $00000002;
  REG_NOTIFY_CHANGE_LAST_SET = $00000004;
  REG_NOTIFY_CHANGE_SECURITY = $00000008;
  REG_NOTIFY_CHANGE_ALL = $0000000F;
  REG_NOTIFY_THREAD_AGNOSTIC = $10000000; // Windows 8+

type
  { Common }

  // WinNt.21612
  [FriendlyName('registry'), ValidMask(KEY_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(KEY_QUERY_VALUE, 'Query Values')]
  [FlagName(KEY_SET_VALUE, 'Set Values')]
  [FlagName(KEY_CREATE_SUB_KEY, 'Create Sub-keys')]
  [FlagName(KEY_ENUMERATE_SUB_KEYS, 'Enumerate Sub-keys')]
  [FlagName(KEY_NOTIFY, 'Notify Changes')]
  [FlagName(KEY_CREATE_LINK, 'Create Links')]
  TRegKeyAccessMask = type TAccessMask;

  // WinNt.21656
  [FlagName(REG_OPTION_VOLATILE, 'Volatile')]
  [FlagName(REG_OPTION_CREATE_LINK, 'Create Link')]
  [FlagName(REG_OPTION_BACKUP_RESTORE, 'Backup/Restore')]
  [FlagName(REG_OPTION_OPEN_LINK, 'Open Link')]
  [FlagName(REG_OPTION_DONT_VIRTUALIZE, 'Don''t Virtualize')]
  TRegOpenOptions = type Cardinal;

  // WinNt.21697
  [NamingStyle(nsSnakeCase, 'REG'), Range(1)]
  TRegDisposition = (
    REG_DISPOSITION_RESERVED = 0,
    REG_CREATED_NEW_KEY = 1,
    REG_OPENED_EXISTING_KEY = 2
  );
  PRegDisposition = ^TRegDisposition;

  // WinNt.21711
  [FlagName(REG_WHOLE_HIVE_VOLATILE, 'Whole Hive Volatile')]
  [FlagName(REG_REFRESH_HIVE, 'Refresh Hive')]
  [FlagName(REG_NO_LAZY_FLUSH, 'No Lazy Flush')]
  [FlagName(REG_FORCE_RESTORE, 'Force Restore')]
  [FlagName(REG_APP_HIVE, 'App Hive')]
  [FlagName(REG_PROCESS_PRIVATE, 'Process-private')]
  [FlagName(REG_START_JOURNAL, 'Start Journal')]
  [FlagName(REG_HIVE_EXACT_FILE_GROWTH, 'Exact File Growth')]
  [FlagName(REG_HIVE_NO_RM, 'No RM')]
  [FlagName(REG_HIVE_SINGLE_LOG, 'Single Log')]
  [FlagName(REG_BOOT_HIVE, 'Boot Hive')]
  [FlagName(REG_LOAD_HIVE_OPEN_HANDLE, 'Open Handle')]
  [FlagName(REG_FLUSH_HIVE_FILE_GROWTH, 'Flush File Growth')]
  [FlagName(REG_OPEN_READ_ONLY, 'Open Readonly')]
  [FlagName(REG_IMMUTABLE, 'Immutable')]
  TRegLoadFlags = type Cardinal;

  // WinNt.21732
  [FlagName(REG_FORCE_UNLOAD, 'Force Unload')]
  TRegUnloadFlags = type Cardinal;

  // rev
  [FlagName(REG_FLAG_VOLATILE, 'Volatile')]
  [FlagName(REG_FLAG_LINK, 'Symbolic Link')]
  TKeyFlags = type Cardinal;

  // MSDN
  [FlagName(REG_KEY_DONT_VIRTUALIZE, 'No Virtualize')]
  [FlagName(REG_KEY_DONT_SILENT_FAIL, 'No Silent Fail')]
  [FlagName(REG_KEY_RECURSE_FLAG, 'Recursive')]
  TKeyControlFlags = type Cardinal;

  // WinNt.21760, value types
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

  { Querying Key Information }

  // wdm.7401
  [NamingStyle(nsCamelCase, 'Key')]
  TKeyInformationClass = (
    KeyBasicInformation = 0,          // TKeyBasicInformation
    KeyNodeInformation = 1,           // TKeyNodeInformation
    KeyFullInformation = 2,           // TKeyFullInformation
    KeyNameInformation = 3,           // TKeyNameInformation
    KeyCachedInformation = 4,         // TKeyCachedInformation
    KeyFlagsInformation = 5,          // TKeyFlagsInformation
    KeyVirtualizationInformation = 6, // TKeyGetVirtualization
    KeyHandleTagsInformation = 7,     // TRegKeyTrustInformation
    KeyTrustInformation = 8,          // Cardinal
    KeyLayerInformation = 9           // TKeyLayerInformation
  );

  // wdm.7310, key info class 0
  TKeyBasicInformation = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyBasicInformation = ^TKeyBasicInformation;

  // wdm.7377, key info class 1
  TKeyNodeInformation = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    ClassOffset: Cardinal;
    [Bytes] ClassLength: Cardinal;
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
    // ...
    // Class: TAnysizeArray<WideChar>;
  end;
  PKeyNodeInformation = ^TKeyNodeInformation;

  // wdm.7387, key info class 2
  TKeyFullInformation = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    ClassOffset: Cardinal;
    [Counter(ctBytes)] ClassLength: Cardinal;
    SubKeys: Cardinal;
    [Bytes] MaxNameLen: Cardinal;
    [Bytes] MaxClassLen: Cardinal;
    Values: Cardinal;
    [Bytes] MaxValueNameLen: Cardinal;
    [Bytes] MaxValueDataLen: Cardinal;
    &Class: TAnysizeArray<WideChar>;
  end;
  PKeyFullInformation = ^TKeyFullInformation;

  // ntddk.4987, key info class 3
  TKeyNameInformation = record
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyNameInformation = ^TKeyNameInformation;

  // ntddk.4992, key info class 4
  TKeyCachedInformation = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    SubKeys: Cardinal;
    [Bytes] MaxNameLen: Cardinal;
    Values: Cardinal;
    [Bytes] MaxValueNameLen: Cardinal;
    [Bytes] MaxValueDataLen: Cardinal;
    [Bytes] NameLength: Cardinal;
  end;
  PKeyCachedInformation = ^TKeyCachedInformation;

  // rev, key info class 5
  TKeyFlagsInformation = record
    [Hex] Wow64Flags: Cardinal;
    KeyFlags: TKeyFlags;
    ControlFlags: TKeyControlFlags;
  end;
  PKeyFlagsInformation = ^TKeyFlagsInformation;

  // ntddk.5003, key info class 6
  [FlagName(REG_GET_VIRTUAL_CANDIDATE, 'Candidate')]
  [FlagName(REG_GET_VIRTUAL_ENABLED, 'Enabled')]
  [FlagName(REG_GET_VIRTUAL_TARGET, 'Target')]
  [FlagName(REG_GET_VIRTUAL_STORE, 'Store')]
  [FlagName(REG_GET_VIRTUAL_SOURCE, 'Source')]
  TKeyGetVirtualization = type Cardinal;

  // wdm.7505 (bits), key info class 7
  [FlagName(REG_KEY_TRUSTED_KEY, 'Trusted Key')]
  TRegKeyTrustInformation = type Cardinal;

  // ntddk.5012, key info class 9
  [FlagName(REG_KEY_LAYER_IS_TOMBSTONE, 'REG_KEY_LAYER_IS_TOMBSTONE')]
  [FlagName(REG_KEY_LAYER_IS_SUPERSEDE_LOCAL, 'REG_KEY_LAYER_IS_SUPERSEDE_LOCAL')]
  [FlagName(REG_KEY_LAYER_IS_SUPERSEDE_TREE, 'REG_KEY_LAYER_IS_SUPERSEDE_TREE')]
  [FlagName(REG_KEY_LAYER_CLASS_IS_INHERITED, 'REG_KEY_LAYER_CLASS_IS_INHERITED')]
  TKeyLayerInformation = type Cardinal;

  { Setting Key Information }

  // wdm.7435
  [NamingStyle(nsCamelCase, 'Key')]
  TKeySetInformationClass = (
    KeyWriteTimeInformation = 0,         // TLargeInteger
    KeyWow64FlagsInformation = 1,        // Cardinal
    KeyControlFlagsInformation = 2,      // TKeyControlFlags
    KeySetVirtualizationInformation = 3, // TKeySetVirtualization
    KeySetDebugInformation = 4,
    KeySetHandleTagsInformation = 5,     // Cardinal
    KeySetLayerInformation = 6           // TKeyLayerInformation
  );

  // wdm.7427, key set info class 3
  [FlagName(REG_SET_VIRTUAL_TARGET, 'Target')]
  [FlagName(REG_SET_VIRTUAL_STORE, 'Store')]
  [FlagName(REG_SET_VIRTUAL_SOURCE, 'Source')]
  TKeySetVirtualization = type Cardinal;

  { Value Information }

  // wdm.7493
  [NamingStyle(nsCamelCase, 'KeyValue')]
  TKeyValueInformationClass = (
    KeyValueBasicInformation = 0,          // TKeyValueBasicInformation
    KeyValueFullInformation = 1,           // TKeyValueFullInformation
    KeyValuePartialInformation = 2,        // TKeyValuePartialInfromation
    KeyValueFullInformationAlign64 = 3,    // TKeyValueFullInformation
    KeyValuePartialInformationAlign64 = 4, // TKeyValuePartialInfromation
    KeyValueLayerInformation = 5           // TKeyValueLayerInformation
  );

  // wdm.7451, value info class 0
  TKeyValueBasicInformation = record
    TitleIndex: Cardinal;
    ValueType: TRegValueType;
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyValueBasicInformation = ^TKeyValueBasicInformation;

  // wdm 7458, value info class 1 & 3
  TKeyValueFullInformation = record
    TitleIndex: Cardinal;
    ValueType: TRegValueType;
    DataOffset: Cardinal;
    [Bytes] DataLength: Cardinal;
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
    // ...
    // Data: TAnysizeArray<Byte>;
  end;
  PKeyValueFullInformation = ^TKeyValueFullInformation;

  // wdm.7468, value info class 2 & 4
  TKeyValuePartialInfromation = record
    TitleIndex: Cardinal;
    ValueType: TRegValueType;
    [Counter(ctBytes)] DataLength: Cardinal;
    Data: TAnysizeArray<Byte>;
  end;
  PKeyValuePartialInfromation = ^TKeyValuePartialInfromation;

  // wdm.7481, value info class 5
  [FlagName(REG_KEY_VALUE_LAYER_IS_TOMBSTONE, 'Is Tombstone')]
  TKeyValueLayerInformation = type Cardinal;

  // wdm.7486
  TKeyValueEnrty = record
    ValueName: PNtUnicodeString;
    [Bytes] DataLength: Cardinal;
    DataOffset: Cardinal;
    DataType: TRegValueType;
  end;
  PKeyValueEnrty = ^TKeyValueEnrty;

  { Other }

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

  // WinNt.21703
  [FlagName(REG_STANDARD_FORMAT, 'Standard')]
  [FlagName(REG_LATEST_FORMAT, 'Latest')]
  [FlagName(REG_NO_COMPRESSION, 'No Compression')]
  TRegSaveFormat = type Cardinal;

  // WinNt.21739
  [FlagName(REG_NOTIFY_CHANGE_NAME, 'Name')]
  [FlagName(REG_NOTIFY_CHANGE_ATTRIBUTES, 'Attributes')]
  [FlagName(REG_NOTIFY_CHANGE_LAST_SET, 'Last Set')]
  [FlagName(REG_NOTIFY_CHANGE_SECURITY, 'Security')]
  [FlagName(REG_NOTIFY_THREAD_AGNOSTIC, 'Thread-Agnostic')]
  TRegNotifyFlags = type Cardinal;

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
  const ObjectAttributes: TObjectAttributes;
  TitleIndex: Cardinal;
  [in, opt] ClassName: PNtUnicodeString;
  CreateOptions: TRegOpenOptions;
  [out, opt] Disposition: PRegDisposition
): NTSTATUS; stdcall; external ntdll;

function NtCreateKeyTransacted(
  out KeyHandle: THandle;
  DesiredAccess: TRegKeyAccessMask;
  const ObjectAttributes: TObjectAttributes;
  TitleIndex: Cardinal;
  [in, opt] ClassName: PNtUnicodeString;
  CreateOptions: TRegOpenOptions;
  TransactionHandle: THandle;
  [out, opt] Disposition: PRegDisposition
): NTSTATUS; stdcall; external ntdll;

function NtOpenKeyEx(
  out KeyHandle: THandle;
  DesiredAccess: TRegKeyAccessMask;
  const ObjectAttributes: TObjectAttributes;
  OpenOptions: TRegOpenOptions
): NTSTATUS; stdcall; external ntdll;

function NtOpenKeyTransactedEx(
  out KeyHandle: THandle;
  DesiredAccess: TRegKeyAccessMask;
  const ObjectAttributes: TObjectAttributes;
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
  [out] KeyInformation: Pointer;
  Length: Cardinal;
  out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtSetInformationKey(
  KeyHandle: THandle;
  KeySetInformationClass: TKeySetInformationClass;
  [in] KeySetInformation: Pointer;
  KeySetInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtQueryValueKey(
  KeyHandle: THandle;
  const ValueName: TNtUnicodeString;
  KeyValueInformationClass: TKeyValueInformationClass;
  [out] KeyValueInformation: Pointer;
  Length: Cardinal;
  out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtSetValueKey(
  KeyHandle: THandle;
  const ValueName: TNtUnicodeString;
  TitleIndex: Cardinal;
  ValueType: TRegValueType;
  [in] Data: Pointer;
  DataSize: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtQueryMultipleValueKey(
  KeyHandle: THandle;
  ValueEntries: TArray<TKeyValueEnrty>;
  EntryCount: Cardinal;
  [out] ValueBuffer: Pointer;
  var BufferLength: Cardinal;
  [out, opt] RequiredBufferLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

function NtEnumerateKey(
  KeyHandle: THandle;
  Index: Cardinal;
  KeyInformationClass: TKeyInformationClass;
  [out] KeyInformation: Pointer;
  Length: Cardinal;
  out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtEnumerateValueKey(
  KeyHandle: THandle;
  Index: Cardinal;
  KeyValueInformationClass: TKeyValueInformationClass;
  [out] KeyValueInformation: Pointer;
  Length: Cardinal;
  out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtFlushKey(
  KeyHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtCompactKeys(
  Count: Cardinal;
  KeyArray: TArray<THandle>
): NTSTATUS; stdcall; external ntdll;

function NtCompressKey(
  Key: THandle
): NTSTATUS; stdcall; external ntdll;

function NtLoadKeyEx(
  const TargetKey: TObjectAttributes;
  const SourceFile: TObjectAttributes;
  Flags: TRegLoadFlags;
  [opt] TrustClassKey: THandle;
  [opt] Event: THandle;
  DesiredAccess: TRegKeyAccessMask;
  out RootHandle: THandle;
  [out, opt] IoStatus: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll;

[MinOSVersion(OsWin1020H1)]
function NtLoadKey3(
  const TargetKey: TObjectAttributes;
  const SourceFile: TObjectAttributes;
  Flags: TRegLoadFlags;
  LoadEntries: TArray<TKeyLoadHandle>;
  LoadEntryCount: Cardinal;
  DesiredAccess: TRegKeyAccessMask;
  out RootHandle: THandle;
  [out, opt] IoStatus: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll delayed;

function NtReplaceKey(
  const NewFile: TObjectAttributes;
  TargetHandle: THandle;
  const OldFile: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

function NtSaveKey(
  KeyHandle: THandle;
  FileHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtSaveKeyEx(
  KeyHandle: THandle;
  FileHandle: THandle;
  Format: TRegSaveFormat
): NTSTATUS; stdcall; external ntdll;

function NtSaveMergedKeys(
  HighPrecedenceKeyHandle: THandle;
  LowPrecedenceKeyHandle: THandle;
  FileHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtRestoreKey(
  KeyHandle: THandle;
  FileHandle: THandle;
  Flags: TRegLoadFlags
): NTSTATUS; stdcall; external ntdll;

function NtUnloadKey2(
  const TargetKey: TObjectAttributes;
  Flags: TRegUnloadFlags
): NTSTATUS; stdcall; external ntdll;

function NtNotifyChangeKey(
  KeyHandle: THandle;
  [opt] Event: THandle;
  [opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  CompletionFilter: TRegNotifyFlags;
  WatchTree: Boolean;
  [out, opt] Buffer: Pointer;
  BufferSize: Cardinal;
  Asynchronous: Boolean
): NTSTATUS; stdcall; external ntdll;

function NtQueryOpenSubKeys(
  const TargetKey: TObjectAttributes;
  out HandleCount: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtQueryOpenSubKeysEx(
  const TargetKey: TObjectAttributes;
  BufferLength: Cardinal;
  [out] Buffer: PKeyOpenSubkeysInformation;
  out RequiredSize: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtLockRegistryKey(
  KeyHandle: THandle
): NTSTATUS; stdcall; external ntdll;

function NtFreezeRegistry(
  TimeOutInSeconds: Cardinal
): NTSTATUS; stdcall; external ntdll;

function NtThawRegistry: NTSTATUS; stdcall; external ntdll;

implementation

end.
