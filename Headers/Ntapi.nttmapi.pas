unit Ntapi.nttmapi;

{
  This module defines functions for interacting with Kernel Transaction Manager
  and using TxF and TxR.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.Versions, DelphiApi.Reflection;

const
  // Transaction manager

  // SDK::winnt.h - TmTm access masks
  TRANSACTIONMANAGER_QUERY_INFORMATION = $0001;
  TRANSACTIONMANAGER_SET_INFORMATION = $0002;
  TRANSACTIONMANAGER_RECOVER = $0004;
  TRANSACTIONMANAGER_RENAME = $0008;
  TRANSACTIONMANAGER_CREATE_RM = $0010;
  TRANSACTIONMANAGER_BIND_TRANSACTION = $0020;

  TRANSACTIONMANAGER_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

  // SDK::ktmtypes.h - open/create options
  TRANSACTION_MANAGER_VOLATILE = $00000001;
  TRANSACTION_MANAGER_COMMIT_DEFAULT = $00000000;
  TRANSACTION_MANAGER_COMMIT_SYSTEM_VOLUME = $00000002;
  TRANSACTION_MANAGER_COMMIT_SYSTEM_HIVES = $00000004;
  TRANSACTION_MANAGER_COMMIT_LOWEST = $00000008;
  TRANSACTION_MANAGER_CORRUPT_FOR_RECOVERY = $00000010;
  TRANSACTION_MANAGER_CORRUPT_FOR_PROGRESS = $00000020;

  // Transaction

  // SDK::winnt.h - TmTx access masks
  TRANSACTION_QUERY_INFORMATION = $0001;
  TRANSACTION_SET_INFORMATION = $0002;
  TRANSACTION_ENLIST = $0004;
  TRANSACTION_COMMIT = $0008;
  TRANSACTION_ROLLBACK = $0010;
  TRANSACTION_PROPAGATE = $0020;
  TRANSACTION_RIGHT_RESERVED1 = $0040;

  TRANSACTION_ALL_ACCESS = STANDARD_RIGHTS_ALL or $7F;

  // SDK::ktmtypes.h - create options
  TRANSACTION_DO_NOT_PROMOTE = $00000001;

  // SDK::ktmtypes.h
  MAX_TRANSACTION_DESCRIPTION_LENGTH = 64;

  // Resource manager

  // SDK::winnt.h - TmRm access masks
  RESOURCEMANAGER_QUERY_INFORMATION = $0001;
  RESOURCEMANAGER_SET_INFORMATION = $0002;
  RESOURCEMANAGER_RECOVER = $0004;
  RESOURCEMANAGER_ENLIST = $0008;
  RESOURCEMANAGER_GET_NOTIFICATION = $0010;
  RESOURCEMANAGER_REGISTER_PROTOCOL = $0020;
  RESOURCEMANAGER_COMPLETE_PROPAGATION = $0040;

  RESOURCEMANAGER_ALL_ACCESS = STANDARD_RIGHTS_ALL or $7F;

  // SDK::ktmtypes.h
  MAX_RESOURCEMANAGER_DESCRIPTION_LENGTH = 64;

  // SDK::ktmtypes.h - creation options
  RESOURCE_MANAGER_VOLATILE = $00000001;
  RESOURCE_MANAGER_COMMUNICATION = $00000002;

  // SDK::ktmtypes.h - notification mask
  TRANSACTION_NOTIFY_PREPREPARE = $00000001;
  TRANSACTION_NOTIFY_PREPARE = $00000002;
  TRANSACTION_NOTIFY_COMMIT = $00000004;
  TRANSACTION_NOTIFY_ROLLBACK = $00000008;
  TRANSACTION_NOTIFY_PREPREPARE_COMPLETE = $00000010;
  TRANSACTION_NOTIFY_PREPARE_COMPLETE = $00000020;
  TRANSACTION_NOTIFY_COMMIT_COMPLETE = $00000040;
  TRANSACTION_NOTIFY_ROLLBACK_COMPLETE = $00000080;
  TRANSACTION_NOTIFY_RECOVER = $00000100;
  TRANSACTION_NOTIFY_SINGLE_PHASE_COMMIT = $00000200;
  TRANSACTION_NOTIFY_DELEGATE_COMMIT = $00000400;
  TRANSACTION_NOTIFY_RECOVER_QUERY = $00000800;
  TRANSACTION_NOTIFY_ENLIST_PREPREPARE = $00001000;
  TRANSACTION_NOTIFY_LAST_RECOVER = $00002000;
  TRANSACTION_NOTIFY_INDOUBT = $00004000;
  TRANSACTION_NOTIFY_PROPAGATE_PULL = $00008000;
  TRANSACTION_NOTIFY_PROPAGATE_PUSH = $00010000;
  TRANSACTION_NOTIFY_MARSHAL = $00020000;
  TRANSACTION_NOTIFY_ENLIST_MASK = $00040000;
  TRANSACTION_NOTIFY_RM_DISCONNECTED = $01000000;
  TRANSACTION_NOTIFY_TM_ONLINE = $02000000;
  TRANSACTION_NOTIFY_COMMIT_REQUEST = $04000000;
  TRANSACTION_NOTIFY_PROMOTE = $08000000;
  TRANSACTION_NOTIFY_PROMOTE_NEW = $10000000;
  TRANSACTION_NOTIFY_REQUEST_OUTCOME = $20000000;

  // Enlistment

  // SDK:winnt.h - TmEn access masks
  ENLISTMENT_QUERY_INFORMATION = $0001;
  ENLISTMENT_SET_INFORMATION = $0002;
  ENLISTMENT_RECOVER = $0004;
  ENLISTMENT_SUBORDINATE_RIGHTS = $0008;
  ENLISTMENT_SUPERIOR_RIGHTS = $0010;

  ENLISTMENT_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  // SDK::ktmtypes.h - creation options
  ENLISTMENT_SUPERIOR = $00000001;

type
  // WDK::wdm.h
  [SDKName('KTMOBJECT_TYPE')]
  [NamingStyle(nsSnakeCase, 'KTMOBJECT')]
  TKtmObjectType = (
    KTMOBJECT_TRANSACTION = 0,
    KTMOBJECT_TRANSACTION_MANAGER = 1,
    KTMOBJECT_RESOURCE_MANAGER = 2,
    KTMOBJECT_ENLISTMENT = 3
  );

  // WDK::wdm.h
  [SDKName('KTMOBJECT_CURSOR')]
  TKtmObjectCursor = record
    LastQuery: TGuid;
    [Counter] ObjectIDCount: Integer;
    ObjectIds: TAnysizeArray<TGuid>;
  end;
  PKtmObjectCursor = ^TKtmObjectCursor;

  // Transaction Manager

  [FriendlyName('transaction manager')]
  [ValidMask(TRANSACTIONMANAGER_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(TRANSACTIONMANAGER_QUERY_INFORMATION, 'Query Information')]
  [FlagName(TRANSACTIONMANAGER_SET_INFORMATION, 'Set Information')]
  [FlagName(TRANSACTIONMANAGER_RECOVER, 'Recover')]
  [FlagName(TRANSACTIONMANAGER_RENAME, 'Rename')]
  [FlagName(TRANSACTIONMANAGER_CREATE_RM, 'Create Resource Manager')]
  [FlagName(TRANSACTIONMANAGER_BIND_TRANSACTION, 'Bind Transaction')]
  TTmTmAccessMask = type TAccessMask;

  [FlagName(TRANSACTION_MANAGER_VOLATILE, 'Volatile')]
  [FlagName(TRANSACTION_MANAGER_COMMIT_DEFAULT, 'Commit Default')]
  [FlagName(TRANSACTION_MANAGER_COMMIT_SYSTEM_VOLUME, 'System Volume')]
  [FlagName(TRANSACTION_MANAGER_COMMIT_SYSTEM_HIVES, 'System Hives')]
  [FlagName(TRANSACTION_MANAGER_COMMIT_LOWEST, 'Commit Lowest')]
  [FlagName(TRANSACTION_MANAGER_CORRUPT_FOR_RECOVERY, 'Corrupt For Recovery')]
  [FlagName(TRANSACTION_MANAGER_CORRUPT_FOR_PROGRESS, 'Corrupt For Progress')]
  TTmTmCreateOptions = type Cardinal;

  // WDK::wdm.h
  [SDKName('TRANSACTIONMANAGER_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'TransactionManager')]
  TTransactionManagerInformationClass = (
    TransactionManagerBasicInformation = 0,   // TTransactionManagerBasicInformation
    TransactionManagerLogInformation = 1,     // TGuid (log identity)
    TransactionManagerLogPathInformation = 2, // TTransactionManagerLogPathInformation
    TransactionManagerReserved = 3,
    TransactionManagerRecoveryInformation = 4 // UInt64 (last recovery LSN)
  );

  // WDK::wdm.h
  [SDKName('TRANSACTIONMANAGER_BASIC_INFORMATION')]
  TTransactionManagerBasicInformation = record
    TmIdentity: TGuid;
    VirtualClock: TLargeInteger;
  end;
  PTransactionManagerBasicInformation = ^TTransactionManagerBasicInformation;

  // WDK::wdm.h
  [SDKName('TRANSACTIONMANAGER_LOGPATH_INFORMATION')]
  TTransactionManagerLogPathInformation = record
    [Counter(ctBytes)] LogPathLength: Integer;
    LogPath: TAnysizeArray<WideChar>;
  end;
  PTransactionManagerLogPathInformation = ^TTransactionManagerLogPathInformation;

  // Transaction

  [FriendlyName('transaction')]
  [ValidMask(TRANSACTION_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(TRANSACTION_QUERY_INFORMATION, 'Query Information')]
  [FlagName(TRANSACTION_SET_INFORMATION, 'Set Information')]
  [FlagName(TRANSACTION_ENLIST, 'Enlist')]
  [FlagName(TRANSACTION_COMMIT, 'Commit')]
  [FlagName(TRANSACTION_ROLLBACK, 'Rollback')]
  [FlagName(TRANSACTION_PROPAGATE, 'Propagate')]
  TTmTxAccessMask = type TAccessMask;

  [FlagName(TRANSACTION_DO_NOT_PROMOTE, 'Do Not Promote')]
  TTmTxCreateOptions = type Cardinal;

  // WDK::wdm.h
  [SDKName('TRANSACTION_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Transaction')]
  TTransactionInformationClass = (
    TransactionBasicInformation = 0,      // q: TTrasactionBasicInformation
    TransactionPropertiesInformation = 1, // q, s: TTransactionPropertiesInformation
    TransactionEnlistmentInformation = 2, // q: TTransactionEnlistmentsInformation
    TransactionSuperiorEnlistmentInformation = 3 // q: TTransactionEnlistmentPair
  );

  // WDK::wdm.h
  [SDKName('TRANSACTION_OUTCOME')]
  [NamingStyle(nsCamelCase, 'TransactionOutcome'), Range(1)]
  TTransactionOutcome = (
    TransactionOutcomeInvalid = 0,
    TransactionOutcomeUndetermined = 1,
    TransactionOutcomeCommitted = 2,
    TransactionOutcomeAborted = 3
  );

  // WDK::wdm.h
  [SDKName('TRANSACTION_STATE')]
  [NamingStyle(nsCamelCase, 'TransactionState'), Range(1)]
  TTransactionState = (
    TransactionStateInvalid = 0,
    TransactionStateNormal = 1,
    TransactionStateInDoubt = 2,
    TransactionStateCommittedNotify = 3
  );

  // WDK::wdm.h
  [SDKName('TRANSACTION_BASIC_INFORMATION')]
  TTransactionBasicInformation = record
    TransactionID: TGuid;
    State: TTransactionState;
    Outcome: TTransactionOutcome;
  end;
  PTransactionBasicInformation = ^TTransactionBasicInformation;

  // WDK::wdm.h
  [SDKName('TRANSACTION_PROPERTIES_INFORMATION')]
  TTransactionPropertiesInformation = record
    IsolationLevel: Cardinal;
    [Hex] IsolationFlags: Cardinal;
    Timeout: TULargeInteger;
    Outcome: TTransactionOutcome;
    [Counter(ctBytes)] DescriptionLength: Cardinal;
    Description: TAnysizeArray<WideChar>;
  end;
  PTransactionPropertiesInformation = ^TTransactionPropertiesInformation;

  // WDK::wdm.h
  [SDKName('TRANSACTION_ENLISTMENT_PAIR')]
  TTransactionEnlistmentPair = record
    EnlistmentID: TGuid;
    ResourceManagerID: TGuid;
  end;
  PTransactionEnlistmentPair = ^TTransactionEnlistmentPair;

  // WDK::wdm.h
  [SDKName('TRANSACTION_SUPERIOR_ENLISTMENT_INFORMATION')]
  TTransactionEnlistmentsInformation = record
    [Counter] NumberOfEnlistments: Cardinal;
    EnlistmentPair: TAnysizeArray<TTransactionEnlistmentPair>;
  end;
  PTransactionEnlistmentsInformation = ^TTransactionEnlistmentsInformation;

  // Resource Manager

  [FriendlyName('resource manager')]
  [ValidMask(RESOURCEMANAGER_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(RESOURCEMANAGER_QUERY_INFORMATION, 'Query Information')]
  [FlagName(RESOURCEMANAGER_SET_INFORMATION, 'Set Information')]
  [FlagName(RESOURCEMANAGER_RECOVER, 'Recover')]
  [FlagName(RESOURCEMANAGER_ENLIST, 'Enlist')]
  [FlagName(RESOURCEMANAGER_GET_NOTIFICATION, 'Get Notification')]
  [FlagName(RESOURCEMANAGER_REGISTER_PROTOCOL, 'Register Protocol')]
  [FlagName(RESOURCEMANAGER_COMPLETE_PROPAGATION, 'Complete Propagation')]
  TTmRmAccessMask = type TAccessMask;

  [FlagName(RESOURCE_MANAGER_VOLATILE, 'Volatile')]
  [FlagName(RESOURCE_MANAGER_COMMUNICATION, 'Communication')]
  TTmRmCreateOptions = type Cardinal;

  // WDK::wdm.h
  [SDKName('RESOURCEMANAGER_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'ResourceManager')]
  TResourceManagerInformationClass = (
    ResourceManagerBasicInformation = 0,     // TResourceManagerBasicInformation
    ResourceManagerCompletionInformation = 1 // TResourceManagerCompletionInformation
  );

  // WDK::wdm.h
  [SDKName('RESOURCEMANAGER_BASIC_INFORMATION')]
  TResourceManagerBasicInformation = record
    ResourceManagerId: TGuid;
    [Counter(ctBytes)] DescriptionLength: Integer;
    Description: TAnysizeArray<WideChar>;
  end;
  PResourceManagerBasicInformation = ^TResourceManagerBasicInformation;

  // WDK::wdm.h
  [SDKName('RESOURCEMANAGER_COMPLETION_INFORMATION')]
  TResourceManagerCompletionInformation = record
    IoCompletionPortHandle: THandle;
    CompletionKey: NativeUInt;
  end;
  PResourceManagerCompletionInformation = ^TResourceManagerCompletionInformation;

  // Enlistment

  [FriendlyName('enlistment'), ValidMask(ENLISTMENT_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(ENLISTMENT_QUERY_INFORMATION, 'Query Information')]
  [FlagName(ENLISTMENT_SET_INFORMATION, 'Set Information')]
  [FlagName(ENLISTMENT_RECOVER, 'Recover')]
  [FlagName(ENLISTMENT_SUBORDINATE_RIGHTS, 'Subordinate Rights')]
  [FlagName(ENLISTMENT_SUPERIOR_RIGHTS, 'Superior Rights')]
  TTmEnAccessMask = type TAccessMask;

  [FlagName(ENLISTMENT_SUPERIOR, 'Superior')]
  TTmEnCreateMask = type Cardinal;

  [FlagName(TRANSACTION_NOTIFY_PREPREPARE, 'Pre-prepare')]
  [FlagName(TRANSACTION_NOTIFY_PREPARE, 'Prepare')]
  [FlagName(TRANSACTION_NOTIFY_COMMIT, 'Commit')]
  [FlagName(TRANSACTION_NOTIFY_ROLLBACK, 'Rollback')]
  [FlagName(TRANSACTION_NOTIFY_PREPREPARE_COMPLETE, 'Pre-prepare Complete')]
  [FlagName(TRANSACTION_NOTIFY_PREPARE_COMPLETE, 'Prepare Complete')]
  [FlagName(TRANSACTION_NOTIFY_COMMIT_COMPLETE, 'Commit Complete')]
  [FlagName(TRANSACTION_NOTIFY_ROLLBACK_COMPLETE, 'Rollback Complete')]
  [FlagName(TRANSACTION_NOTIFY_RECOVER, 'Recover')]
  [FlagName(TRANSACTION_NOTIFY_SINGLE_PHASE_COMMIT, 'Single Phase Commit')]
  [FlagName(TRANSACTION_NOTIFY_DELEGATE_COMMIT, 'Delegate Commit')]
  [FlagName(TRANSACTION_NOTIFY_RECOVER_QUERY, 'Recover Query')]
  [FlagName(TRANSACTION_NOTIFY_ENLIST_PREPREPARE, 'Enlist Prepare')]
  [FlagName(TRANSACTION_NOTIFY_LAST_RECOVER, 'Last Recover')]
  [FlagName(TRANSACTION_NOTIFY_INDOUBT, 'In Dought')]
  [FlagName(TRANSACTION_NOTIFY_PROPAGATE_PULL, 'Propagate Pull')]
  [FlagName(TRANSACTION_NOTIFY_PROPAGATE_PUSH, 'Propagate Push')]
  [FlagName(TRANSACTION_NOTIFY_MARSHAL, 'Marshal')]
  [FlagName(TRANSACTION_NOTIFY_ENLIST_MASK, 'Enlist Mask')]
  [FlagName(TRANSACTION_NOTIFY_RM_DISCONNECTED, 'RM Disconnected')]
  [FlagName(TRANSACTION_NOTIFY_TM_ONLINE, 'TM Online')]
  [FlagName(TRANSACTION_NOTIFY_COMMIT_REQUEST, 'Commit Request')]
  [FlagName(TRANSACTION_NOTIFY_PROMOTE, 'Promote')]
  [FlagName(TRANSACTION_NOTIFY_PROMOTE_NEW, 'Promote New')]
  [FlagName(TRANSACTION_NOTIFY_REQUEST_OUTCOME, 'Request Outcome')]
  TTmEnNotificationMask = type Cardinal;

  // WDK::wdm.h
  [SDKName('ENLISTMENT_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Enlistment')]
  TEnlistmentInformationClass = (
    EnlistmentBasicInformation = 0,    // TEnlistmentBasicInformation
    EnlistmentRecoveryInformation = 1,
    EnlistmentCrmInformation = 2       // TEnlistmentCrmInformation
  );

  // WDK::wdm.h
  [SDKName('ENLISTMENT_BASIC_INFORMATION')]
  TEnlistmentBasicInformation = record
    EnlistmentID: TGuid;
    TransactionID: TGuid;
    ResourceManagerID: TGuid;
  end;
  PEnlistmentBasicInformation = ^TEnlistmentBasicInformation;

  // WDK::wdm.h
  [SDKName('ENLISTMENT_CRM_INFORMATION')]
  TEnlistmentCrmInformation = record
    CRMTransactionManagerID: TGuid;
    CRMResourceManagerID: TGuid;
    CRMEnlistmentID: TGuid;
  end;
  PEnlistmentCrmInformation = ^TEnlistmentCrmInformation;

// PHNT::ntrtl.h
function RtlGetCurrentTransaction(
): THandle; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlSetCurrentTransaction(
  [in, opt] TransactionHandle: THandle
): LongBool; stdcall; external ntdll;

// WDK::wdm.h
function NtEnumerateTransactionObject(
  [in] RootObjectHandle: THandle;
  [in] QueryType: TKtmObjectType;
  [in, out, WritesTo] ObjectCursor: PKtmObjectCursor;
  [in, NumberOfBytes] ObjectCursorLength: Cardinal;
  [out, NumberOfBytes] out ReturnLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

{ Transaction Manager }

// WDK::wdm.h
function NtCreateTransactionManager(
  [out, ReleaseWith('NtClose')] out TmHandle: THandle;
  DesiredAccess: TTmTmAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in, opt] LogFileName: PNtUnicodeString;
  CreateOptions: TTmTmCreateOptions;
  [opt] CommitStrength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtOpenTransactionManager(
  [out, ReleaseWith('NtClose')] out TmHandle: THandle;
  [in] DesiredAccess: TTmTmAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in, opt] LogFileName: PNtUnicodeString;
  [in, opt] TmIdentity: PGuid;
  [in] OpenOptions: TTmTmCreateOptions
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtRenameTransactionManager(
  [in] const LogFileName: TNtUnicodeString;
  [in] const ExistingTransactionManagerGuid: TGuid
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtQueryInformationTransactionManager(
  [in, Access(TRANSACTIONMANAGER_QUERY_INFORMATION)]
    TransactionManagerHandle: THandle;
  [in] TransactionManagerInformationClass: TTransactionManagerInformationClass;
  [out, WritesTo] TransactionManagerInformation: Pointer;
  [in, NumberOfBytes] TransactionManagerInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtSetInformationTransactionManager(
  [in, Access(TRANSACTIONMANAGER_SET_INFORMATION)] TmHandle: THandle;
  [in] TransactionManagerInformationClass: TTransactionManagerInformationClass;
  [in, ReadsFrom] TransactionManagerInformation: Pointer;
  [in, NumberOfBytes] TransactionManagerInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

{ Transaction }

// WDK::wdm.h
function NtCreateTransaction(
  [out, ReleaseWith('NtClose')] out TransactionHandle: THandle;
  [in] DesiredAccess: TTmTxAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in, opt] Uow: PGuid;
  [in, opt, Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] TmHandle: THandle;
  [in] CreateOptions: TTmTxCreateOptions;
  [in, opt] IsolationLevel: Cardinal;
  [in, opt] IsolationFlags: Cardinal;
  [in, opt] Timeout: PLargeInteger;
  [in, opt] Description: PNtUnicodeString
): NTSTATUS;  stdcall; external ntdll;

// WDK::wdm.h
function NtOpenTransaction(
  [out, ReleaseWith('NtClose')] out TransactionHandle: THandle;
  [in] DesiredAccess: TTmTxAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in, opt] Uow: PGuid;
  [in, Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] TmHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtQueryInformationTransaction(
  [in, Access(TRANSACTION_QUERY_INFORMATION)] TransactionHandle: THandle;
  [in] TransactionInformationClass: TTransactionInformationClass;
  [out, WritesTo] TransactionInformation: Pointer;
  [in, NumberOfBytes] TransactionInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtSetInformationTransaction(
  [in, Access(TRANSACTION_SET_INFORMATION)] TransactionHandle: THandle;
  [in] TransactionInformationClass: TTransactionInformationClass;
  [in, ReadsFrom] TransactionInformation: Pointer;
  [in, NumberOfBytes] TransactionInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtCommitTransaction(
  [in, Access(TRANSACTION_COMMIT)] TransactionHandle: THandle;
  [in] Wait: Boolean
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtRollbackTransaction(
  [in, Access(TRANSACTION_ROLLBACK)] TransactionHandle: THandle;
  [in] Wait: Boolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::nttmapi.h
function NtFreezeTransactions(
  [in] const [ref] FreezeTimeout: TLargeInteger;
  [in] const [ref] ThawTimeout: TLargeInteger
): NTSTATUS; stdcall; external ntdll;

// PHNT::nttmapi.h
function NtThawTransactions(
): NTSTATUS; stdcall; external ntdll;

{ Registry Transaction }

// WDK::wdm.h
[MinOSVersion(OsWin10RS1)]
function NtCreateRegistryTransaction(
  [out, ReleaseWith('NtClose')] out TransactionHandle: THandle;
  [in] DesiredAccess: TTmTxAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] CreateOptions: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// WDK::wdm.h
[MinOSVersion(OsWin10RS1)]
function NtOpenRegistryTransaction(
  [out, ReleaseWith('NtClose')] out TransactionHandle: THandle;
  [in] DesiredAccess: TTmTxAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll delayed;

// WDK::wdm.h
[MinOSVersion(OsWin10RS1)]
function NtCommitRegistryTransaction(
  [in, Access(TRANSACTION_COMMIT)] TransactionHandle: THandle;
  [Reserved] Flags: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// WDK::wdm.h
[MinOSVersion(OsWin10RS1)]
function NtRollbackRegistryTransaction(
  [in, Access(TRANSACTION_ROLLBACK)] TransactionHandle: THandle;
  [Reserved] Flags: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

{ Resource Manager }

// WDK::wdm.h
function NtCreateResourceManager(
  [out, ReleaseWith('NtClose')] out ResourceManagerHandle: THandle;
  [in] DesiredAccess: TTmRmAccessMask;
  [in, Access(TRANSACTIONMANAGER_CREATE_RM)] TmHandle: THandle;
  [in] const RmGuid: TGuid;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] CreateOptions: TTmRmCreateOptions;
  [in, opt] Description: PNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtOpenResourceManager(
  [out, ReleaseWith('NtClose')] out ResourceManagerHandle: THandle;
  [in] DesiredAccess: TTmRmAccessMask;
  [in, Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] TmHandle: THandle;
  [in, opt] ResourceManagerGuid: PGuid;
  [in, opt] ObjectAttributes: PObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtQueryInformationResourceManager(
  [in, Access(RESOURCEMANAGER_QUERY_INFORMATION)] ResourceManagerHandle: THandle;
  [in] ResourceManagerInformationClass: TResourceManagerInformationClass;
  [out, WritesTo] ResourceManagerInformation: Pointer;
  [in, NumberOfBytes] ResourceManagerInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtSetInformationResourceManager(
  [in, Access(RESOURCEMANAGER_SET_INFORMATION)] ResourceManagerHandle: THandle;
  [in] ResourceManagerInformationClass: TResourceManagerInformationClass;
  [in, ReadsFrom] ResourceManagerInformation: Pointer;
  [in, NumberOfBytes] ResourceManagerInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

{ Enlistment }

// WDK::wdm.h
function NtCreateEnlistment(
  [out, ReleaseWith('NtClose')] out EnlistmentHandle: THandle;
  [in] DesiredAccess: TTmEnAccessMask;
  [in] ResourceManagerHandle: THandle;
  [in, Access(TRANSACTION_ENLIST)] TransactionHandle: THandle;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] CreateOptions: Cardinal;
  [in] NotificationMask: TTmEnNotificationMask;
  [in] EnlistmentKey: Pointer
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtOpenEnlistment(
  [out, ReleaseWith('NtClose')] out EnlistmentHandle: THandle;
  [in] DesiredAccess: TTmEnAccessMask;
  [in, Access(RESOURCEMANAGER_QUERY_INFORMATION)] ResourceManagerHandle: THandle;
  [in] const EnlistmentGuid: TGuid;
  [in, opt] ObjectAttributes: PObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtQueryInformationEnlistment(
  [in, Access(ENLISTMENT_QUERY_INFORMATION)] EnlistmentHandle: THandle;
  [in] EnlistmentInformationClass: TEnlistmentInformationClass;
  [out, WritesTo] EnlistmentInformation: Pointer;
  [in, NumberOfBytes] EnlistmentInformationLength: Cardinal;
  [out, opt, NumberOfBytes] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtSetInformationEnlistment(
  [in, Access(ENLISTMENT_SET_INFORMATION)] EnlistmentHandle: THandle;
  [in] EnlistmentInformationClass: TEnlistmentInformationClass;
  [in, ReadsFrom] EnlistmentInformation: Pointer;
  [in, NumberOfBytes] EnlistmentInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
