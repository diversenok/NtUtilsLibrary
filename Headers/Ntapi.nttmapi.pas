unit Ntapi.nttmapi;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

const
  // Transaction manager

  // WinNt.21983
  TRANSACTIONMANAGER_QUERY_INFORMATION = $0001;
  TRANSACTIONMANAGER_SET_INFORMATION = $0002;
  TRANSACTIONMANAGER_RECOVER = $0004;
  TRANSACTIONMANAGER_RENAME = $0008;
  TRANSACTIONMANAGER_CREATE_RM = $0010;
  TRANSACTIONMANAGER_BIND_TRANSACTION = $0020;

  TRANSACTIONMANAGER_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

  // ktmtypes.38 open/create options
  TRANSACTION_MANAGER_VOLATILE = $00000001;
  TRANSACTION_MANAGER_COMMIT_DEFAULT = $00000000;
  TRANSACTION_MANAGER_COMMIT_SYSTEM_VOLUME = $00000002;
  TRANSACTION_MANAGER_COMMIT_SYSTEM_HIVES = $00000004;
  TRANSACTION_MANAGER_COMMIT_LOWEST = $00000008;
  TRANSACTION_MANAGER_CORRUPT_FOR_RECOVERY = $00000010;
  TRANSACTION_MANAGER_CORRUPT_FOR_PROGRESS = $00000020;

  // Transaction

  // WinNt.22018
  TRANSACTION_QUERY_INFORMATION = $0001;
  TRANSACTION_SET_INFORMATION = $0002;
  TRANSACTION_ENLIST = $0004;
  TRANSACTION_COMMIT = $0008;
  TRANSACTION_ROLLBACK = $0010;
  TRANSACTION_PROPAGATE = $0020;
  TRANSACTION_RIGHT_RESERVED1 = $0040;

  TRANSACTION_ALL_ACCESS = STANDARD_RIGHTS_ALL or $7F;

  // ktmtypes.52, create options
  TRANSACTION_DO_NOT_PROMOTE = $00000001;

  // ktmtypes.180
  MAX_TRANSACTION_DESCRIPTION_LENGTH = 64;

  // Resource manager

  // WinNt.22067
  RESOURCEMANAGER_QUERY_INFORMATION = $0001;
  RESOURCEMANAGER_SET_INFORMATION = $0002;
  RESOURCEMANAGER_RECOVER = $0004;
  RESOURCEMANAGER_ENLIST = $0008;
  RESOURCEMANAGER_GET_NOTIFICATION = $0010;
  RESOURCEMANAGER_REGISTER_PROTOCOL = $0020;
  RESOURCEMANAGER_COMPLETE_PROPAGATION = $0040;

  RESOURCEMANAGER_ALL_ACCESS = STANDARD_RIGHTS_ALL or $7F;

  // ktmtypes.181
  MAX_RESOURCEMANAGER_DESCRIPTION_LENGTH = 64;

  // ktmtypes.60, create options
  RESOURCE_MANAGER_VOLATILE = $00000001;
  RESOURCE_MANAGER_COMMUNICATION = $00000002;

  // ktmtype.84, notification mask
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

  // WinNt.22067
  ENLISTMENT_QUERY_INFORMATION = $0001;
  ENLISTMENT_SET_INFORMATION = $0002;
  ENLISTMENT_RECOVER = $0004;
  ENLISTMENT_SUBORDINATE_RIGHTS = $0008;
  ENLISTMENT_SUPERIOR_RIGHTS = $0010;

  ENLISTMENT_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  // ktmtypes.78, create options
  ENLISTMENT_SUPERIOR = $00000001;

type
  // wdm.15389
  [NamingStyle(nsSnakeCase, 'KTMOBJECT')]
  TKtmObjectType = (
    KTMOBJECT_TRANSACTION = 0,
    KTMOBJECT_TRANSACTION_MANAGER = 1,
    KTMOBJECT_RESOURCE_MANAGER = 2,
    KTMOBJECT_ENLISTMENT = 3
  );

  // wdm.15407
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

  // wdm.15339
  [NamingStyle(nsCamelCase, 'TransactionManager')]
  TTransactionManagerInformationClass = (
    TransactionManagerBasicInformation = 0,   // TTransactionManagerBasicInformation
    TransactionManagerLogInformation = 1,     // TGuid (log identity)
    TransactionManagerLogPathInformation = 2, // TTransactionManagerLogPathInformation
    TransactionManagerReserved = 3,
    TransactionManagerRecoveryInformation = 4 // UInt64 (last recovery LSN)
  );

  // wdm.15267
  TTransactionManagerBasicInformation = record
    TmIdentity: TGuid;
    VirtualClock: TLargeInteger;
  end;
  PTransactionManagerBasicInformation = ^TTransactionManagerBasicInformation;

  // wdm.15276
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

  // wdm.15331
  [NamingStyle(nsCamelCase, 'Transaction')]
  TTransactionInformationClass = (
    TransactionBasicInformation = 0,      // q: TTrasactionBasicInformation
    TransactionPropertiesInformation = 1, // q, s: TTransactionPropertiesInformation
    TransactionEnlistmentInformation = 2, // q: TTransactionEnlistmentsInformation
    TransactionSuperiorEnlistmentInformation = 3 // q: TTransactionEnlistmentPair
  );

  // wdm.15247
  [NamingStyle(nsCamelCase, 'TransactionOutcome'), Range(1)]
  TTransactionOutcome = (
    TransactionOutcomeInvalid = 0,
    TransactionOutcomeUndetermined = 1,
    TransactionOutcomeCommitted = 2,
    TransactionOutcomeAborted = 3
  );

  // wdm.15254
  [NamingStyle(nsCamelCase, 'TransactionState'), Range(1)]
  TTransactionState = (
    TransactionStateInvalid = 0,
    TransactionStateNormal = 1,
    TransactionStateInDoubt = 2,
    TransactionStateCommittedNotify = 3
  );

  // wdm.15261
  TTransactionBasicInformation = record
    TransactionID: TGuid;
    State: TTransactionState;
    Outcome: TTransactionOutcome;
  end;
  PTransactionBasicInformation = ^TTransactionBasicInformation;

  // wdm.15289
  TTransactionPropertiesInformation = record
    IsolationLevel: Cardinal;
    [Hex] IsolationFlags: Cardinal;
    Timeout: TULargeInteger;
    Outcome: TTransactionOutcome;
    [Counter(ctBytes)] DescriptionLength: Cardinal;
    Description: TAnysizeArray<WideChar>;
  end;
  PTransactionPropertiesInformation = ^TTransactionPropertiesInformation;

  // wdm.15305
  TTransactionEnlistmentPair = record
    EnlistmentID: TGuid;
    ResourceManagerID: TGuid;
  end;
  PTransactionEnlistmentPair = ^TTransactionEnlistmentPair;

  // wdm.15310
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

  // wdm.15349
  [NamingStyle(nsCamelCase, 'ResourceManager')]
  TResourceManagerInformationClass = (
    ResourceManagerBasicInformation = 0,     // TResourceManagerBasicInformation
    ResourceManagerCompletionInformation = 1 // TResourceManagerCompletionInformation
  );

  // wdm.15320
  TResourceManagerBasicInformation = record
    ResourceManagerId: TGuid;
    [Counter(ctBytes)] DescriptionLength: Integer;
    Description: TAnysizeArray<WideChar>;
  end;
  PResourceManagerBasicInformation = ^TResourceManagerBasicInformation;

  // wdm.15326
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

  // wdm.15369
  [NamingStyle(nsCamelCase, 'Enlistment')]
  TEnlistmentInformationClass = (
    EnlistmentBasicInformation = 0,    // TEnlistmentBasicInformation
    EnlistmentRecoveryInformation = 1,
    EnlistmentCrmInformation = 2       // TEnlistmentCrmInformation
  );

  // wdm.15355
  TEnlistmentBasicInformation = record
    EnlistmentID: TGuid;
    TransactionID: TGuid;
    ResourceManagerID: TGuid;
  end;
  PEnlistmentBasicInformation = ^TEnlistmentBasicInformation;

  // wdm.15361
  TEnlistmentCrmInformation = record
    CRMTransactionManagerID: TGuid;
    CRMResourceManagerID: TGuid;
    CRMEnlistmentID: TGuid;
  end;
  PEnlistmentCrmInformation = ^TEnlistmentCrmInformation;

{ Common }

// wdm.15544
function NtEnumerateTransactionObject(
  RootObjectHandle: THandle;
  QueryType: TKtmObjectType;
  ObjectCursor: PKtmObjectCursor;
  ObjectCursorLength: Cardinal;
  out ReturnLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

{ Transaction Manager }

// wdm.15441
function NtCreateTransactionManager(
  out TmHandle: THandle;
  DesiredAccess: TTmTmAccessMask;
  ObjectAttributes: PObjectAttributes;
  LogFileName: PNtUnicodeString;
  CreateOptions: Cardinal;
  CommitStrength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// wdm.15458
function NtOpenTransactionManager(
  out TmHandle: THandle;
  DesiredAccess: TTmTmAccessMask;
  ObjectAttributes: PObjectAttributes;
  LogFileName: PNtUnicodeString;
  TmIdentity: PGuid;
  OpenOptions: Cardinal
): NTSTATUS; stdcall; external ntdll;

// wdm.15475
function NtRenameTransactionManager(
  const LogFileName: TNtUnicodeString;
  const ExistingTransactionManagerGuid: TGuid
): NTSTATUS; stdcall; external ntdll;

// wdm.15513
function NtQueryInformationTransactionManager(
  TransactionManagerHandle: THandle;
  TransactionManagerInformationClass: TTransactionManagerInformationClass;
  TransactionManagerInformation: Pointer;
  TransactionManagerInformationLength: Cardinal;
  ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// wdm.15529
function NtSetInformationTransactionManager(
  TmHandle: THandle;
  TransactionManagerInformationClass: TTransactionManagerInformationClass;
  TransactionManagerInformation: Pointer;
  TransactionManagerInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

{ Transaction }

// wdm.15574
function NtCreateTransaction(
  out TransactionHandle: THandle;
  DesiredAccess: TTmTxAccessMask;
  ObjectAttributes: PObjectAttributes;
  Uow: PGuid;
  TmHandle: THandle;
  CreateOptions: Cardinal;
  IsolationLevel: Cardinal;
  IsolationFlags: Cardinal;
  Timeout: PLargeInteger;
  Description: PNtUnicodeString
): NTSTATUS;  stdcall; external ntdll;

// wdm.15604
function NtOpenTransaction(
  out TransactionHandle: THandle;
  DesiredAccess: TTmTxAccessMask;
  ObjectAttributes: PObjectAttributes;
  Uow: PGuid;
  TmHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// wdm.15629
function NtQueryInformationTransaction(
  TransactionHandle: THandle;
  TransactionInformationClass: TTransactionInformationClass;
  TransactionInformation: Pointer;
  TransactionInformationLength: Cardinal;
  ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// wdm.15653
function NtSetInformationTransaction(
  TransactionHandle: THandle;
  TransactionInformationClass: TTransactionInformationClass;
  TransactionInformation: Pointer;
  TransactionInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

// wdm.15673
function NtCommitTransaction(
  TransactionHandle: THandle;
  Wait: Boolean
): NTSTATUS; stdcall; external ntdll;

// wdm.15691
function NtRollbackTransaction(
  TransactionHandle: THandle;
  Wait: Boolean
): NTSTATUS; stdcall; external ntdll;

// rev
function NtFreezeTransactions(
  const [ref] FreezeTimeout: TLargeInteger;
  const [ref] ThawTimeout: TLargeInteger
): NTSTATUS; stdcall; external ntdll;

// rev
function NtThawTransactions: NTSTATUS; stdcall; external ntdll;

{ Registry Transaction }

// wdm.40646, Windows 10 RS1+
function NtCreateRegistryTransaction(
  out TransactionHandle: THandle;
  DesiredAccess: TTmTxAccessMask;
  ObjectAttributes: PObjectAttributes;
  CreateOptions: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// wdm.40660, Windows 10 RS1+
function NtOpenRegistryTransaction(
  out TransactionHandle: THandle;
  DesiredAccess: TTmTxAccessMask;
  ObjectAttributes: PObjectAttributes
): NTSTATUS; stdcall; external ntdll delayed;

// wdm.40672, Windows 10 RS1+
function NtCommitRegistryTransaction(
  TransactionHandle: THandle;
  Flags: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

// wdm.40683, Windows 10 RS1+
function NtRollbackRegistryTransaction(
  TransactionHandle: THandle;
  Flags: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

{ Resource Manager }

// wdm.15906
function NtCreateResourceManager(
  out ResourceManagerHandle: THandle;
  DesiredAccess: TTmRmAccessMask;
  TmHandle: THandle;
  const RmGuid: TGuid;
  ObjectAttributes: PObjectAttributes;
  CreateOptions: Cardinal;
  Description: PNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// wdm.15924
function NtOpenResourceManager(
  out ResourceManagerHandle: THandle;
  DesiredAccess: TTmRmAccessMask;
  TmHandle: THandle;
  ResourceManagerGuid: PGuid;
  ObjectAttributes: PObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// wdm.15970
function NtQueryInformationResourceManager(
  ResourceManagerHandle: THandle;
  ResourceManagerInformationClass: TResourceManagerInformationClass;
  ResourceManagerInformation: Pointer;
  ResourceManagerInformationLength:
  Cardinal; ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// wdm.15986
function NtSetInformationResourceManager(
  ResourceManagerHandle: THandle;
  ResourceManagerInformationClass: TResourceManagerInformationClass;
  ResourceManagerInformation: Pointer;
  ResourceManagerInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

{ Enlistment }

// wdm.15704
function NtCreateEnlistment(
  out EnlistmentHandle: THandle;
  DesiredAccess: TTmEnAccessMask;
  ResourceManagerHandle: THandle;
  TransactionHandle: THandle;
  ObjectAttributes: PObjectAttributes;
  CreateOptions: Cardinal;
  NotificationMask: Cardinal;
  EnlistmentKey: Pointer
): NTSTATUS; stdcall; external ntdll;

// wdm.15723
function NtOpenEnlistment(
  out EnlistmentHandle: THandle;
  DesiredAccess: TTmEnAccessMask;
  ResourceManagerHandle: THandle;
  const EnlistmentGuid: TGuid;
  ObjectAttributes: PObjectAttributes
): NTSTATUS; stdcall; external ntdll;

// wdm.15739
function NtQueryInformationEnlistment(
  EnlistmentHandle: THandle;
  EnlistmentInformationClass: TEnlistmentInformationClass;
  EnlistmentInformation: Pointer;
  EnlistmentInformationLength: Cardinal;
  ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// wdm.15755
function NtSetInformationEnlistment(
  EnlistmentHandle: THandle;
  EnlistmentInformationClass: TEnlistmentInformationClass;
  EnlistmentInformation: Pointer;
  EnlistmentInformationLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

implementation

end.
