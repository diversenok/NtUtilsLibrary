unit Ntapi.ntregapi;

{
  This module provides functions for working with registry via Native API.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, Ntapi.ntseapi, Ntapi.Versions,
  DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  // Registry paths
  REG_PATH_MACHINE = '\Registry\Machine';
  REG_PATH_USER = '\Registry\User';
  REG_PATH_USER_DEFAULT = '\Registry\User\.Default';
  REG_PATH_APPKEY = '\Registry\A';
  REG_PATH_CONTAINERS = '\Registry\WC';

  // Special value name for symlink keys
  REG_SYMLINK_VALUE_NAME = 'SymbolicLinkValue';

  // SDK::winnt.h - registry access masks
  KEY_QUERY_VALUE = $0001;
  KEY_SET_VALUE = $0002;
  KEY_CREATE_SUB_KEY = $0004;
  KEY_ENUMERATE_SUB_KEYS = $0008;
  KEY_NOTIFY = $0010;
  KEY_CREATE_LINK = $0020;

  KEY_READ = KEY_QUERY_VALUE or KEY_ENUMERATE_SUB_KEYS or KEY_NOTIFY or
    STANDARD_RIGHTS_READ;
  KEY_WRITE = KEY_SET_VALUE or KEY_CREATE_SUB_KEY or STANDARD_RIGHTS_WRITE;

  KEY_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

  // SDK::winnt.h - open/create options
  REG_OPTION_VOLATILE = $00000001;
  REG_OPTION_CREATE_LINK = $00000002;
  REG_OPTION_BACKUP_RESTORE = $00000004;
  REG_OPTION_OPEN_LINK = $00000008;
  REG_OPTION_DONT_VIRTUALIZE = $00000010;

  // SDK::winnt.h - flags for NtSaveKeyEx
  REG_STANDARD_FORMAT = $01;
  REG_LATEST_FORMAT = $02;
  REG_NO_COMPRESSION = $04;

  // SDK::winnt.h - load/restore flags
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

  // SDK::winnt.h - unload flags
  REG_FORCE_UNLOAD = $0001;

  // rev, KeyFlagsInformation
  REG_FLAG_VOLATILE = $0001;
  REG_FLAG_LINK = $0002;

  // MSDocs::desktop-src/SysInfo/registry-virtualization.md - control flags
  REG_KEY_DONT_VIRTUALIZE = $0002;
  REG_KEY_DONT_SILENT_FAIL = $0004;
  REG_KEY_RECURSE_FLAG = $0008;

  // WDK::ntddk.h (bits from KEY_VIRTUALIZATION_INFORMATION)
  REG_GET_VIRTUAL_CANDIDATE = $0001;
  REG_GET_VIRTUAL_ENABLED = $0002;
  REG_GET_VIRTUAL_TARGET = $0004;
  REG_GET_VIRTUAL_STORE = $0008;
  REG_GET_VIRTUAL_SOURCE = $0010;

  // WDK::wdm.h (bits from KEY_TRUST_INFORMATION)
  REG_KEY_TRUSTED_KEY = $0001;

  // WDK::wdm.h (bits from KEY_SET_VIRTUALIZATION_INFORMATION)
  REG_SET_VIRTUAL_TARGET = $0001;
  REG_SET_VIRTUAL_STORE = $0002;
  REG_SET_VIRTUAL_SOURCE = $0004;

  // WDK::ntddk.h (bits from KEY_LAYER_INFORMATION)
  REG_KEY_LAYER_IS_TOMBSTONE = $0001;
  REG_KEY_LAYER_IS_SUPERSEDE_LOCAL = $0002;
  REG_KEY_LAYER_IS_SUPERSEDE_TREE = $0004;
  REG_KEY_LAYER_CLASS_IS_INHERITED = $0008;

  // WDK::wdm.h (bits form KEY_VALUE_LAYER_INFORMATION)
  REG_KEY_VALUE_LAYER_IS_TOMBSTONE = $0001;

  // SDK::winnt.h - notify filters
  REG_NOTIFY_CHANGE_NAME = $00000001;
  REG_NOTIFY_CHANGE_ATTRIBUTES = $00000002;
  REG_NOTIFY_CHANGE_LAST_SET = $00000004;
  REG_NOTIFY_CHANGE_SECURITY = $00000008;
  REG_NOTIFY_CHANGE_ALL = $0000000F;
  REG_NOTIFY_THREAD_AGNOSTIC = $10000000; // Windows 8+

  // Re-declare for annotations
  TRANSACTION_ENLIST = $0004; // Ntapi.nttmapi
  EVENT_MODIFY_STATE = $0002; // Ntapi.ntexapi

type
  { Common }

  [FriendlyName('registry'), ValidBits(KEY_ALL_ACCESS), IgnoreUnnamed]
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

  // SDK::winnt.h
  [NamingStyle(nsSnakeCase, 'REG'), Range(1)]
  TRegDisposition = (
    REG_DISPOSITION_RESERVED = 0,
    REG_CREATED_NEW_KEY = 1,
    REG_OPENED_EXISTING_KEY = 2
  );
  PRegDisposition = ^TRegDisposition;

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

  [FlagName(REG_FORCE_UNLOAD, 'Force Unload')]
  TRegUnloadFlags = type Cardinal;

  [FlagName(REG_FLAG_VOLATILE, 'Volatile')]
  [FlagName(REG_FLAG_LINK, 'Symbolic Link')]
  TKeyFlags = type Cardinal;

  [FlagName(REG_KEY_DONT_VIRTUALIZE, 'No Virtualize')]
  [FlagName(REG_KEY_DONT_SILENT_FAIL, 'No Silent Fail')]
  [FlagName(REG_KEY_RECURSE_FLAG, 'Recursive')]
  TKeyControlFlags = type Cardinal;

  // SDK::winnt.h - value types
  [NamingStyle(nsSnakeCase, 'REG')]
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

  // WDK::wdm.h
  [SDKName('KEY_INFORMATION_CLASS')]
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

  // WDK::wdm.h - key info class 0
  [SDKName('KEY_BASIC_INFORMATION')]
  TKeyBasicInformation = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyBasicInformation = ^TKeyBasicInformation;

  // WDK::wdm.h - key info class 1
  [SDKName('KEY_NODE_INFORMATION')]
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

  // WDK::wdm.h - key info class 2
  [SDKName('KEY_FULL_INFORMATION')]
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

  // WDK::ntddk.h - key info class 3
  [SDKName('KEY_NAME_INFORMATION')]
  TKeyNameInformation = record
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyNameInformation = ^TKeyNameInformation;

  // WDK::ntddk.h - key info class 4
  [SDKName('KEY_CACHED_INFORMATION')]
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

  // PHNT::ntreg.h - key info class 5
  [SDKName('KEY_FLAGS_INFORMATION')]
  TKeyFlagsInformation = record
    [Hex] Wow64Flags: Cardinal;
    KeyFlags: TKeyFlags;
    ControlFlags: TKeyControlFlags;
  end;
  PKeyFlagsInformation = ^TKeyFlagsInformation;

  // WDK::ntddk.h - key info class 6
  [SDKName('KEY_VIRTUALIZATION_INFORMATION')]
  [FlagName(REG_GET_VIRTUAL_CANDIDATE, 'Candidate')]
  [FlagName(REG_GET_VIRTUAL_ENABLED, 'Enabled')]
  [FlagName(REG_GET_VIRTUAL_TARGET, 'Target')]
  [FlagName(REG_GET_VIRTUAL_STORE, 'Store')]
  [FlagName(REG_GET_VIRTUAL_SOURCE, 'Source')]
  TKeyGetVirtualization = type Cardinal;

  // WDK::wdm.h - key info class 7
  [SDKName('KEY_TRUST_INFORMATION')]
  [FlagName(REG_KEY_TRUSTED_KEY, 'Trusted Key')]
  TRegKeyTrustInformation = type Cardinal;

  // WDK::ntddk.h - key info class 9
  [SDKName('KEY_LAYER_INFORMATION')]
  [FlagName(REG_KEY_LAYER_IS_TOMBSTONE, 'Tombstone')]
  [FlagName(REG_KEY_LAYER_IS_SUPERSEDE_LOCAL, 'Supersede Local')]
  [FlagName(REG_KEY_LAYER_IS_SUPERSEDE_TREE, 'Supersede Tree')]
  [FlagName(REG_KEY_LAYER_CLASS_IS_INHERITED, 'Class Is Inherited')]
  TKeyLayerInformation = type Cardinal;

  { Setting Key Information }

  // WDK::wdm.h
  [SDKName('KEY_SET_INFORMATION_CLASS')]
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

  // WDK::wdm.h - key set info class 3
  [SDKName('KEY_SET_VIRTUALIZATION_INFORMATION')]
  [FlagName(REG_SET_VIRTUAL_TARGET, 'Target')]
  [FlagName(REG_SET_VIRTUAL_STORE, 'Store')]
  [FlagName(REG_SET_VIRTUAL_SOURCE, 'Source')]
  TKeySetVirtualization = type Cardinal;

  { Value Information }

  // WDK::wdm.h
  [SDKName('KEY_VALUE_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'KeyValue')]
  TKeyValueInformationClass = (
    KeyValueBasicInformation = 0,          // TKeyValueBasicInformation
    KeyValueFullInformation = 1,           // TKeyValueFullInformation
    KeyValuePartialInformation = 2,        // TKeyValuePartialInfromation
    KeyValueFullInformationAlign64 = 3,    // TKeyValueFullInformation
    KeyValuePartialInformationAlign64 = 4, // TKeyValuePartialInfromation
    KeyValueLayerInformation = 5           // TKeyValueLayerInformation
  );

  // WDK::wdm.h - value info class 0
  [SDKName('KEY_VALUE_BASIC_INFORMATION')]
  TKeyValueBasicInformation = record
    TitleIndex: Cardinal;
    ValueType: TRegValueType;
    [Counter(ctBytes)] NameLength: Cardinal;
    Name: TAnysizeArray<WideChar>;
  end;
  PKeyValueBasicInformation = ^TKeyValueBasicInformation;

  // WDK::wdm.h - value info class 1 & 3
  [SDKName('KEY_VALUE_FULL_INFORMATION')]
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

  // WDK::wdm.h - value info class 2 & 4
  [SDKName('KEY_VALUE_PARTIAL_INFORMATION')]
  TKeyValuePartialInfromation = record
    TitleIndex: Cardinal;
    ValueType: TRegValueType;
    [Counter(ctBytes)] DataLength: Cardinal;
    Data: TAnysizeArray<Byte>;
  end;
  PKeyValuePartialInfromation = ^TKeyValuePartialInfromation;

  // WDK::wdm.h - value info class 5
  [SDKName('KEY_VALUE_LAYER_INFORMATION')]
  [FlagName(REG_KEY_VALUE_LAYER_IS_TOMBSTONE, 'Is Tombstone')]
  TKeyValueLayerInformation = type Cardinal;

  // WDK::wdm.h
  [SDKName('KEY_VALUE_ENTRY')]
  TKeyValueEnrty = record
    ValueName: PNtUnicodeString;
    [Bytes] DataLength: Cardinal;
    DataOffset: Cardinal;
    DataType: TRegValueType;
  end;
  PKeyValueEnrty = ^TKeyValueEnrty;

  { Other }

  // PHNT::ntregapi.h
  [NamingStyle(nsCamelCase, 'KeyLoad'), RangeAttribute(1)]
  TKeyLoadHandleType = (
    KeyLoadReserved = 0,
    KeyLoadTrustClassKey = 1,
    KeyLoadEvent = 2,
    KeyLoadToken = 3
  );

  // PHNT::ntregapi.h
  TKeyLoadHandle = record
    HandleType: TKeyLoadHandleType;
    Handle: THandle;
  end;

  [FlagName(REG_STANDARD_FORMAT, 'Standard')]
  [FlagName(REG_LATEST_FORMAT, 'Latest')]
  [FlagName(REG_NO_COMPRESSION, 'No Compression')]
  TRegSaveFormat = type Cardinal;

  [FlagName(REG_NOTIFY_CHANGE_NAME, 'Name')]
  [FlagName(REG_NOTIFY_CHANGE_ATTRIBUTES, 'Attributes')]
  [FlagName(REG_NOTIFY_CHANGE_LAST_SET, 'Last Set')]
  [FlagName(REG_NOTIFY_CHANGE_SECURITY, 'Security')]
  [FlagName(REG_NOTIFY_THREAD_AGNOSTIC, 'Thread-Agnostic')]
  TRegNotifyFlags = type Cardinal;

  // PHNT::ntregapi.h
  [SDKName('KEY_PID_ARRAY')]
  TKeyPidInformation = record
    ProcessId: TProcessId;
    KeyName: TNtUnicodeString;
  end;
  PKeyPidInformation = ^TKeyPidInformation;

  // PHNT::ntregapi.h
  [SDKName('KEY_OPEN_SUBKEYS_INFORMATION')]
  TKeyOpenSubkeysInformation = record
    [Counter] Count: Cardinal;
    KeyArray: TAnysizeArray<TKeyPidInformation>;
  end;
  PKeyOpenSubkeysInformation = ^TKeyOpenSubkeysInformation;

// WDK::wdm.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtCreateKey(
  [out, ReleaseWith('NtClose')] out KeyHandle: THandle;
  [in] DesiredAccess: TRegKeyAccessMask;
  [in] const ObjectAttributes: TObjectAttributes;
  [in, opt] TitleIndex: Cardinal;
  [in, opt] ClassName: PNtUnicodeString;
  [in] CreateOptions: TRegOpenOptions;
  [out, opt] Disposition: PRegDisposition
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtCreateKeyTransacted(
  [out, ReleaseWith('NtClose')] out KeyHandle: THandle;
  [in] DesiredAccess: TRegKeyAccessMask;
  [in] const ObjectAttributes: TObjectAttributes;
  [in, opt] TitleIndex: Cardinal;
  [in, opt] ClassName: PNtUnicodeString;
  [in] CreateOptions: TRegOpenOptions;
  [in, Access(TRANSACTION_ENLIST)] TransactionHandle: THandle;
  [out, opt] Disposition: PRegDisposition
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtOpenKeyEx(
  [out, ReleaseWith('NtClose')] out KeyHandle: THandle;
  [in] DesiredAccess: TRegKeyAccessMask;
  [in] const ObjectAttributes: TObjectAttributes;
  [in] OpenOptions: TRegOpenOptions
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtOpenKeyTransactedEx(
  [out, ReleaseWith('NtClose')] out KeyHandle: THandle;
  [in] DesiredAccess: TRegKeyAccessMask;
  [in] const ObjectAttributes: TObjectAttributes;
  [in] OpenOptions: TRegOpenOptions;
  [in, Access(TRANSACTION_ENLIST)] TransactionHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtDeleteKey(
  [in, Access(_DELETE)] KeyHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtRenameKey(
  [in, Access(KEY_WRITE)] KeyHandle: THandle;
  const NewName: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtDeleteValueKey(
  [in, Access(KEY_SET_VALUE)] KeyHandle: THandle;
  [in] const ValueName: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtQueryKey(
  [in, Access(KEY_QUERY_VALUE)] KeyHandle: THandle;
  [in] KeyInformationClass: TKeyInformationClass;
  [out, WritesTo] KeyInformation: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [out, NumberOfBytes] out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtSetInformationKey(
  [in, Access(KEY_SET_VALUE)] KeyHandle: THandle;
  [in] KeySetInformationClass: TKeySetInformationClass;
  [in, ReadsFrom] KeySetInformation: Pointer;
  [in, NumberOfBytes] KeySetInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtQueryValueKey(
  [in, Access(KEY_QUERY_VALUE)] KeyHandle: THandle;
  [in] const ValueName: TNtUnicodeString;
  [in] KeyValueInformationClass: TKeyValueInformationClass;
  [out, WritesTo] KeyValueInformation: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [out, NumberOfBytes] out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtSetValueKey(
  [in, Access(KEY_SET_VALUE)] KeyHandle: THandle;
  [in] const ValueName: TNtUnicodeString;
  [in, opt] TitleIndex: Cardinal;
  [in] ValueType: TRegValueType;
  [in, ReadsFrom] Data: Pointer;
  [in, NumberOfBytes] DataSize: Cardinal
): NTSTATUS; stdcall; external ntdll;

// SDK::winternl.h
function NtQueryMultipleValueKey(
  [in, Access(KEY_QUERY_VALUE)] KeyHandle: THandle;
  [in, ReadsFrom] const ValueEntries: TArray<TKeyValueEnrty>;
  [in, NumberOfElements] EntryCount: Cardinal;
  [out, WritesTo] ValueBuffer: Pointer;
  [in, out, NumberOfBytes] var BufferLength: Cardinal;
  [out, opt, NumberOfBytes] RequiredBufferLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtEnumerateKey(
  [in, Access(KEY_ENUMERATE_SUB_KEYS)] KeyHandle: THandle;
  [in] Index: Cardinal;
  [in] KeyInformationClass: TKeyInformationClass;
  [out, WritesTo] KeyInformation: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [out, NumberOfBytes] out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtEnumerateValueKey(
  [in, Access(KEY_QUERY_VALUE)] KeyHandle: THandle;
  [in] Index: Cardinal;
  [in] KeyValueInformationClass: TKeyValueInformationClass;
  [out, WritesTo] KeyValueInformation: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [out, NumberOfBytes] out ResultLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtFlushKey(
  [in, Access(0)] KeyHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtCompactKeys(
  [in, NumberOfElements] Count: Cardinal;
  [in, ReadsFrom, Access(KEY_WRITE)] const KeyArray: TArray<THandle>
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtCompressKey(
  [in, Access(KEY_WRITE)] Key: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
[Result: ReleaseWith('NtUnloadKey2')]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpWithExceptions)]
function NtLoadKeyEx(
  [in] const TargetKey: TObjectAttributes;
  [in] const SourceFile: TObjectAttributes;
  [in] Flags: TRegLoadFlags;
  [in, opt, Access(0)] TrustClassKey: THandle;
  [in, opt, Access(EVENT_MODIFY_STATE)] Event: THandle;
  [in] DesiredAccess: TRegKeyAccessMask;
  [out, opt, ReleaseWith('NtClose')] out RootHandle: THandle;
  [out, opt] IoStatus: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h & NtApiDotNet::NtKeyNative.cs
[MinOSVersion(OsWin1020H1)]
[Result: ReleaseWith('NtUnloadKey2')]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpWithExceptions)]
function NtLoadKey3(
  [in] const TargetKey: TObjectAttributes;
  [in] const SourceFile: TObjectAttributes;
  [in] Flags: TRegLoadFlags;
  [in, ReadsFrom] const LoadEntries: TArray<TKeyLoadHandle>;
  [in, NumberOfElements] LoadEntryCount: Cardinal;
  [in] DesiredAccess: TRegKeyAccessMask;
  [out, opt, ReleaseWith('NtClose')] out RootHandle: THandle;
  [out, opt] IoStatus: PIoStatusBlock
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtLoadKey3: TDelayedLoadFunction = (
  DllName: ntdll;
  FunctionName: 'NtLoadKey3';
);

// PHNT::ntregapi.h
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function NtReplaceKey(
  [in] const NewFile: TObjectAttributes;
  [in, Access(0)] TargetHandle: THandle;
  [in] const OldFile: TObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtSaveKey(
  [in, Access(0)] KeyHandle: THandle;
  [in, Access(FILE_WRITE_DATA)] FileHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtSaveKeyEx(
  [in, Access(0)] KeyHandle: THandle;
  [in, Access(FILE_WRITE_DATA)] FileHandle: THandle;
  [in] Format: TRegSaveFormat
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtSaveMergedKeys(
  [in, Access(0)] HighPrecedenceKeyHandle: THandle;
  [in, Access(0)] LowPrecedenceKeyHandle: THandle;
  [in, Access(FILE_WRITE_DATA)] FileHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function NtRestoreKey(
  [in, Access(0)] KeyHandle: THandle;
  [in, Access(FILE_READ_DATA)] FileHandle: THandle;
  [in] Flags: TRegLoadFlags
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpWithExceptions)]
function NtUnloadKey2(
  [in] const TargetKey: TObjectAttributes;
  [in] Flags: TRegUnloadFlags
): NTSTATUS; stdcall; external ntdll;

// WDK::ntifs.h
function NtNotifyChangeKey(
  [in, Access(KEY_NOTIFY)] KeyHandle: THandle;
  [in, opt, Access(EVENT_MODIFY_STATE)] Event: THandle;
  [in, opt] ApcRoutine: TIoApcRoutine;
  [in, opt] ApcContext: Pointer;
  [out] IoStatusBlock: PIoStatusBlock;
  [in] CompletionFilter: TRegNotifyFlags;
  [in] WatchTree: Boolean;
  [out, opt, WritesTo] Buffer: Pointer;
  [in, opt, NumberOfBytes] BufferSize: Cardinal;
  [in] Asynchronous: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
function NtQueryOpenSubKeys(
  [in] const TargetKey: TObjectAttributes;
  [in] out HandleCount: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function NtQueryOpenSubKeysEx(
  [in] const TargetKey: TObjectAttributes;
  [in, NumberOfBytes] BufferLength: Cardinal;
  [out, WritesTo] Buffer: PKeyOpenSubkeysInformation;
  [out, NumberOfBytes] out RequiredSize: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
[Result: ReleaseWith('NtThawRegistry')]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtFreezeRegistry(
  [in] TimeOutInSeconds: Cardinal
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntregapi.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtThawRegistry(
): NTSTATUS; stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
