unit Ntapi.nttmapi;

{
  This module defines functions for interacting with Kernel Transaction Manager
  and using TxF and TxR.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntioapi, Ntapi.Versions, DelphiApi.Reflection,
  DelphiApi.DelayLoad;

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

  // FSTCLs

  // WDK::ntifs.h
  FSCTL_TXFS_QUERY_RM_INFORMATION = $00094148;
  FSCTL_TXFS_GET_METADATA_INFO = $0009416C;
  FSCTL_TXFS_GET_TRANSACTED_VERSION = $00094170;
  FSCTL_TXFS_TRANSACTION_ACTIVE = $0009418C;
  FSCTL_TXFS_LIST_TRANSACTION_LOCKED_FILES = $000941E0;
  FSCTL_TXFS_LIST_TRANSACTIONS = $000941E4;

  // WDK::ntifs.h - resource manager flags
  TXFS_RM_FLAG_LOGGING_MODE = $00000001;
  TXFS_RM_FLAG_RENAME_RM = $00000002;
  TXFS_RM_FLAG_LOG_CONTAINER_COUNT_MAX = $00000004;
  TXFS_RM_FLAG_LOG_CONTAINER_COUNT_MIN = $00000008;
  TXFS_RM_FLAG_LOG_GROWTH_INCREMENT_NUM_CONTAINERS = $00000010;
  TXFS_RM_FLAG_LOG_GROWTH_INCREMENT_PERCENT = $00000020;
  TXFS_RM_FLAG_LOG_AUTO_SHRINK_PERCENTAGE = $00000040;
  TXFS_RM_FLAG_LOG_NO_CONTAINER_COUNT_MAX = $00000080;
  TXFS_RM_FLAG_LOG_NO_CONTAINER_COUNT_MIN = $00000100;
  TXFS_RM_FLAG_GROW_LOG = $00000400;
  TXFS_RM_FLAG_SHRINK_LOG = $00000800;
  TXFS_RM_FLAG_ENFORCE_MINIMUM_SIZE = $00001000;
  TXFS_RM_FLAG_PRESERVE_CHANGES = $00002000;
  TXFS_RM_FLAG_RESET_RM_AT_NEXT_START = $00004000;
  TXFS_RM_FLAG_DO_NOT_RESET_RM_AT_NEXT_START = $00008000;
  TXFS_RM_FLAG_PREFER_CONSISTENCY = $00010000;
  TXFS_RM_FLAG_PREFER_AVAILABILITY = $00020000;

  // WDK::ntifs.h - special version values
  TXFS_TRANSACTED_VERSION_NONTRANSACTED = $FFFFFFFE;
  TXFS_TRANSACTED_VERSION_UNCOMMITTED = $FFFFFFFF;

  // WDK::ntifs.h - transaction lock name flags
  TXFS_LIST_TRANSACTION_LOCKED_FILES_ENTRY_FLAG_CREATED = $00000001;
  TXFS_LIST_TRANSACTION_LOCKED_FILES_ENTRY_FLAG_DELETED = $00000002;

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

  [FriendlyName('transaction manager'), ValidBits(TRANSACTIONMANAGER_ALL_ACCESS)]
  [SubEnum(TRANSACTIONMANAGER_ALL_ACCESS, TRANSACTIONMANAGER_ALL_ACCESS, 'Full Access')]
  [FlagName(TRANSACTIONMANAGER_QUERY_INFORMATION, 'Query Information')]
  [FlagName(TRANSACTIONMANAGER_SET_INFORMATION, 'Set Information')]
  [FlagName(TRANSACTIONMANAGER_RECOVER, 'Recover')]
  [FlagName(TRANSACTIONMANAGER_RENAME, 'Rename')]
  [FlagName(TRANSACTIONMANAGER_CREATE_RM, 'Create Resource Manager')]
  [FlagName(TRANSACTIONMANAGER_BIND_TRANSACTION, 'Bind Transaction')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
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
  [NamingStyle(nsCamelCase, 'TransactionManager'), ValidBits([0..2, 4])]
  TTransactionManagerInformationClass = (
    TransactionManagerBasicInformation = 0,   // TTransactionManagerBasicInformation
    TransactionManagerLogInformation = 1,     // TGuid (log identity)
    TransactionManagerLogPathInformation = 2, // TTransactionManagerLogPathInformation
    [Reserved] TransactionManagerUnused = 3,
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

  [FriendlyName('transaction'), ValidBits(TRANSACTION_ALL_ACCESS)]
  [SubEnum(TRANSACTION_ALL_ACCESS, TRANSACTION_ALL_ACCESS, 'Full Access')]
  [FlagName(TRANSACTION_QUERY_INFORMATION, 'Query Information')]
  [FlagName(TRANSACTION_SET_INFORMATION, 'Set Information')]
  [FlagName(TRANSACTION_ENLIST, 'Enlist')]
  [FlagName(TRANSACTION_COMMIT, 'Commit')]
  [FlagName(TRANSACTION_ROLLBACK, 'Rollback')]
  [FlagName(TRANSACTION_PROPAGATE, 'Propagate')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TTmTxAccessMask = type TAccessMask;

  [FlagName(TRANSACTION_DO_NOT_PROMOTE, 'Do Not Promote')]
  TTmTxCreateOptions = type Cardinal;

  // WDK::wdm.h
  [SDKName('TRANSACTION_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Transaction')]
  TTransactionInformationClass = (
    TransactionBasicInformation = 0,      // q: TTransactionBasicInformation
    TransactionPropertiesInformation = 1, // q, s: TTransactionPropertiesInformation
    TransactionEnlistmentInformation = 2, // q: TTransactionEnlistmentsInformation
    TransactionSuperiorEnlistmentInformation = 3 // q: TTransactionEnlistmentPair
  );

  // WDK::wdm.h
  [SDKName('TRANSACTION_OUTCOME')]
  [NamingStyle(nsCamelCase, 'TransactionOutcome'), Range(1)]
  TTransactionOutcome = (
    [Reserved] TransactionOutcomeInvalid = 0,
    TransactionOutcomeUndetermined = 1,
    TransactionOutcomeCommitted = 2,
    TransactionOutcomeAborted = 3
  );

  // WDK::wdm.h
  [SDKName('TRANSACTION_STATE')]
  [NamingStyle(nsCamelCase, 'TransactionState'), Range(1)]
  TTransactionState = (
    [Reserved] TransactionStateInvalid = 0,
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

  [FriendlyName('resource manager'), ValidBits(RESOURCEMANAGER_ALL_ACCESS)]
  [SubEnum(RESOURCEMANAGER_ALL_ACCESS, RESOURCEMANAGER_ALL_ACCESS, 'Full Access')]
  [FlagName(RESOURCEMANAGER_QUERY_INFORMATION, 'Query Information')]
  [FlagName(RESOURCEMANAGER_SET_INFORMATION, 'Set Information')]
  [FlagName(RESOURCEMANAGER_RECOVER, 'Recover')]
  [FlagName(RESOURCEMANAGER_ENLIST, 'Enlist')]
  [FlagName(RESOURCEMANAGER_GET_NOTIFICATION, 'Get Notification')]
  [FlagName(RESOURCEMANAGER_REGISTER_PROTOCOL, 'Register Protocol')]
  [FlagName(RESOURCEMANAGER_COMPLETE_PROPAGATION, 'Complete Propagation')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
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

  [FriendlyName('enlistment'), ValidBits(ENLISTMENT_ALL_ACCESS)]
  [SubEnum(ENLISTMENT_ALL_ACCESS, ENLISTMENT_ALL_ACCESS, 'Full Access')]
  [FlagName(ENLISTMENT_QUERY_INFORMATION, 'Query Information')]
  [FlagName(ENLISTMENT_SET_INFORMATION, 'Set Information')]
  [FlagName(ENLISTMENT_RECOVER, 'Recover')]
  [FlagName(ENLISTMENT_SUBORDINATE_RIGHTS, 'Subordinate Rights')]
  [FlagName(ENLISTMENT_SUPERIOR_RIGHTS, 'Superior Rights')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TTmEnAccessMask = type TAccessMask;

  [FlagName(ENLISTMENT_SUPERIOR, 'Superior')]
  TTmEnCreateOptions = type Cardinal;

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
  [FlagName(TRANSACTION_NOTIFY_INDOUBT, 'In Doubt')]
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

  { FSCTLs }

  [FlagName(TXFS_RM_FLAG_LOGGING_MODE, 'Logging Mode')]
  [FlagName(TXFS_RM_FLAG_RENAME_RM, 'Rename RM')]
  [FlagName(TXFS_RM_FLAG_LOG_CONTAINER_COUNT_MAX, 'Log Container Count Max')]
  [FlagName(TXFS_RM_FLAG_LOG_CONTAINER_COUNT_MIN, 'Log Container Count Min')]
  [FlagName(TXFS_RM_FLAG_LOG_GROWTH_INCREMENT_NUM_CONTAINERS, 'Log Growth Inc Num Containers')]
  [FlagName(TXFS_RM_FLAG_LOG_GROWTH_INCREMENT_PERCENT, 'Log Growth Inc Percent')]
  [FlagName(TXFS_RM_FLAG_LOG_AUTO_SHRINK_PERCENTAGE, 'Auto-shrink Percentage')]
  [FlagName(TXFS_RM_FLAG_LOG_NO_CONTAINER_COUNT_MAX, 'Log No Container Count Max')]
  [FlagName(TXFS_RM_FLAG_LOG_NO_CONTAINER_COUNT_MIN, 'Log No Container Count Min')]
  [FlagName(TXFS_RM_FLAG_GROW_LOG, 'Grow Log')]
  [FlagName(TXFS_RM_FLAG_SHRINK_LOG, 'Shrink Log')]
  [FlagName(TXFS_RM_FLAG_ENFORCE_MINIMUM_SIZE, 'Enforce Minimum Size')]
  [FlagName(TXFS_RM_FLAG_PRESERVE_CHANGES, 'Preserver Changes')]
  [FlagName(TXFS_RM_FLAG_RESET_RM_AT_NEXT_START, 'Reset RM At Next Start')]
  [FlagName(TXFS_RM_FLAG_DO_NOT_RESET_RM_AT_NEXT_START, 'Not Reset RM At Next Start')]
  [FlagName(TXFS_RM_FLAG_PREFER_CONSISTENCY, 'Prefer Consistency')]
  [FlagName(TXFS_RM_FLAG_PREFER_AVAILABILITY, 'Prefer Availability')]
  TTxfsRmFlags = type Cardinal;

  // WDK::ntifs.h
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'TXFS_LOGGING_MODE'), Range(1)]
  TTxfsLoggingMode = (
    [Reserved] TXFS_LOGGING_MODE_UNKNOWN = 0,
    TXFS_LOGGING_MODE_SIMPLE = 1,
    TXFS_LOGGING_MODE_FULL = 2
  );
  {$MINENUMSIZE 4}

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'TXFS_RM_STATE')]
  TTxfsRmState = (
    TXFS_RM_STATE_NOT_STARTED = 0,
    TXFS_RM_STATE_STARTING = 1,
    TXFS_RM_STATE_ACTIVE = 2,
    TXFS_RM_STATE_SHUTTING_DOWN = 3
  );

  // WDK::ntifs.h
  [NamingStyle(nsSnakeCase, 'TXFS_TRANSACTION_STATE')]
  TTxfsTransactionState = (
    TXFS_TRANSACTION_STATE_NONE = 0,
    TXFS_TRANSACTION_STATE_ACTIVE = 1,
    TXFS_TRANSACTION_STATE_PREPARED = 2,
    TXFS_TRANSACTION_STATE_NOT_ACTIVE = 3
  );

  // WDK::ntifs.h - FSCTL 82
  [SDKName('TXFS_QUERY_RM_INFORMATION')]
  TTxfsQueryRmInformation = record
    [RecordSize] BytesRequired: Cardinal;
    TailLsn: UInt64;
    CurrentLsn: UInt64;
    ArchiveTailLsn: UInt64;
    [Bytes] LogContainerSize: UInt64;
    HighestVirtualClock: TLargeInteger;
    LogContainerCount: Cardinal;
    LogContainerCountMax: Cardinal;
    LogContainerCountMin: Cardinal;
    LogGrowthIncrement: Cardinal;
    LogAutoShrinkPercentage: Cardinal;
    Flags: TTxfsRmFlags;
    LoggingMode: TTxfsLoggingMode;
    [Unlisted] Reserved: Word;
    RmState: TTxfsRmState;
    [Bytes] LogCapacity: UInt64;
    [Bytes] LogFree: UInt64;
    [Bytes] TopsSize: UInt64;
    [Bytes] TopsUsed: UInt64;
    TransactionCount: UInt64;
    OnePCCount: UInt64;
    TwoPCCount: UInt64;
    NumberLogFileFull: UInt64;
    OldestTransactionAge: UInt64;
    RMName: TGuid;
    [Offset] TmLogPathOffset: Cardinal; // to PWideChar
  end;
  PTxfsQueryRmInformation = ^TTxfsQueryRmInformation;

  // WDK::ntifs.h - FSCTL 91
  [SDKName('TXFS_GET_METADATA_INFO_OUT')]
  TTxfsGetMetadataInfoOut = record
    TxfFileId: TGuid;
    LockingTransaction: TGuid;
    LastLsn: UInt64;
    TransactionState: TTxfsTransactionState;
  end;

  // WDK::ntifs.h - FSCTL 92
  [SDKName('TXFS_GET_TRANSACTED_VERSION')]
  TTxfsGetTransactedVersion = record
    ThisBaseVersion: Cardinal;
    LatestVersion: Cardinal;
    ThisMiniVersion: Word;
    FirstMiniVersion: Word;
    LatestMiniVersion: Word;
  end;

  [FlagName(TXFS_LIST_TRANSACTION_LOCKED_FILES_ENTRY_FLAG_CREATED, 'Created')]
  [FlagName(TXFS_LIST_TRANSACTION_LOCKED_FILES_ENTRY_FLAG_DELETED, 'Deleted')]
  TTxfsTransactionLockedFilesFlags = type Cardinal;

  // WDK::ntifs.h
  [SDKName('TXFS_LIST_TRANSACTION_LOCKED_FILES_ENTRY')]
  TTxfsListTransactionLockedFilesEntry = record
    [Offset] NextEntryOffset: UInt64; // from TTxfsListTransactionLockedFiles
    NameFlags: TTxfsTransactionLockedFilesFlags;
    FileId: TFileId;
    [Unlisted] Reserved1: Cardinal;
    [Unlisted] Reserved2: Cardinal;
    [Unlisted] Reserved3: UInt64;
    FileName: TAnysizeArray<WideChar>;
  end;
  PTxfsListTransactionLockedFilesEntry = ^TTxfsListTransactionLockedFilesEntry;

  // WDK::ntifs.h - FSCTL 120
  [SDKName('TXFS_LIST_TRANSACTION_LOCKED_FILES')]
  TTxfsListTransactionLockedFiles = record
    [in] KtmTransaction: TGuid;
    [out] NumberOfFiles: UInt64;
    [out, Bytes] BufferSizeRequired: UInt64;
    [out, Offset] FirstEntryOffset: UInt64; // to TTxfsListTransactionLockedFilesEntry
  end;
  PTxfsListTransactionLockedFiles = ^TTxfsListTransactionLockedFiles;

  // WDK::ntifs.h
  [SDKName('TXFS_LIST_TRANSACTIONS_ENTRY')]
  TTxfsListTransactionsEntry = record
    TransactionId: TGuid;
    TransactionState: TTxfsTransactionState;
    [Unlisted] Reserved1: Cardinal;
    [Unlisted] Reserved2: Cardinal;
    [Unlisted] Reserved3: UInt64;
  end;
  PTxfsListTransactionsEntry = ^TTxfsListTransactionsEntry;

  // WDK::ntifs.h - FSCTL 120
  [SDKName('TXFS_LIST_TRANSACTIONS')]
  TTxfsListTransactions = record
    NumberOfTransactions: UInt64;
    BufferSizeRequired: UInt64;
    Entries: TPlaceholder<TTxfsListTransactionsEntry>;
  end;
  PTxfsListTransactions = ^TTxfsListTransactions;

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
  [Reserved] CommitStrength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// WDK::wdm.h
function NtOpenTransactionManager(
  [out, ReleaseWith('NtClose')] out TmHandle: THandle;
  [in] DesiredAccess: TTmTmAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in, opt] LogFileName: PNtUnicodeString;
  [in, opt] TmIdentity: PGuid;
  [Reserved] OpenOptions: TTmTmCreateOptions
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
  [in] const Uow: TGuid;
  [in, opt, Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] TmHandle: THandle
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

var delayed_NtCreateRegistryTransaction: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtCreateRegistryTransaction';
);

// WDK::wdm.h
[MinOSVersion(OsWin10RS1)]
function NtOpenRegistryTransaction(
  [out, ReleaseWith('NtClose')] out TransactionHandle: THandle;
  [in] DesiredAccess: TTmTxAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtOpenRegistryTransaction: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtOpenRegistryTransaction';
);

// WDK::wdm.h
[MinOSVersion(OsWin10RS1)]
function NtCommitRegistryTransaction(
  [in, Access(TRANSACTION_COMMIT)] TransactionHandle: THandle;
  [Reserved] Flags: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtCommitRegistryTransaction: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtCommitRegistryTransaction';
);

// WDK::wdm.h
[MinOSVersion(OsWin10RS1)]
function NtRollbackRegistryTransaction(
  [in, Access(TRANSACTION_ROLLBACK)] TransactionHandle: THandle;
  [Reserved] Flags: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtRollbackRegistryTransaction: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtRollbackRegistryTransaction';
);

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
  [in] const ResourceManagerGuid: TGuid;
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
  [in, Access(RESOURCEMANAGER_ENLIST)] ResourceManagerHandle: THandle;
  [in, Access(TRANSACTION_ENLIST)] TransactionHandle: THandle;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] CreateOptions: TTmEnCreateOptions;
  [in] NotificationMask: TTmEnNotificationMask;
  [in] EnlistmentKey: NativeUInt
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
