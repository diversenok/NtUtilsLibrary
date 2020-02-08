unit Ntapi.nttmapi;

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

  TmTmAccessMapping: array [0..5] of TFlagName = (
    (Value: TRANSACTIONMANAGER_QUERY_INFORMATION; Name: 'Query information'),
    (Value: TRANSACTIONMANAGER_SET_INFORMATION;   Name: 'Set information'),
    (Value: TRANSACTIONMANAGER_RECOVER;           Name: 'Recover'),
    (Value: TRANSACTIONMANAGER_RENAME;            Name: 'Rename'),
    (Value: TRANSACTIONMANAGER_CREATE_RM;         Name: 'Create resource manager'),
    (Value: TRANSACTIONMANAGER_BIND_TRANSACTION;  Name: 'Bind transaction')
  );

  TmTmAccessType: TAccessMaskType = (
    TypeName: 'transaction manager';
    FullAccess: TRANSACTIONMANAGER_ALL_ACCESS;
    Count: Length(TmTmAccessMapping);
    Mapping: PFlagNameRefs(@TmTmAccessMapping);
  );

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

  TmTxAccessMapping: array [0..5] of TFlagName = (
    (Value: TRANSACTION_QUERY_INFORMATION; Name: 'Query information'),
    (Value: TRANSACTION_SET_INFORMATION;   Name: 'Set information'),
    (Value: TRANSACTION_ENLIST;            Name: 'Enlist'),
    (Value: TRANSACTION_COMMIT;            Name: 'Commit'),
    (Value: TRANSACTION_ROLLBACK;          Name: 'Rollback'),
    (Value: TRANSACTION_PROPAGATE;         Name: 'Propagate')
  );

  TmTxAccessType: TAccessMaskType = (
    TypeName: 'transaction';
    FullAccess: TRANSACTION_ALL_ACCESS;
    Count: Length(TmTxAccessMapping);
    Mapping: PFlagNameRefs(@TmTxAccessMapping);
  );

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

  TmRmAccessMapping: array [0..6] of TFlagName = (
    (Value: RESOURCEMANAGER_QUERY_INFORMATION;    Name: 'Query information'),
    (Value: RESOURCEMANAGER_SET_INFORMATION;      Name: 'Set information'),
    (Value: RESOURCEMANAGER_RECOVER;              Name: 'Recover'),
    (Value: RESOURCEMANAGER_ENLIST;               Name: 'Enlist'),
    (Value: RESOURCEMANAGER_GET_NOTIFICATION;     Name: 'Get notification'),
    (Value: RESOURCEMANAGER_REGISTER_PROTOCOL;    Name: 'Register protocol'),
    (Value: RESOURCEMANAGER_COMPLETE_PROPAGATION; Name: 'Complete propagation')
  );

  TmRmAccessType: TAccessMaskType = (
    TypeName: 'resource manager';
    FullAccess: RESOURCEMANAGER_ALL_ACCESS;
    Count: Length(TmRmAccessMapping);
    Mapping: PFlagNameRefs(@TmRmAccessMapping);
  );

  // Enlistment

  // WinNt.22067
  ENLISTMENT_QUERY_INFORMATION = $0001;
  ENLISTMENT_SET_INFORMATION = $0002;
  ENLISTMENT_RECOVER = $0004;
  ENLISTMENT_SUBORDINATE_RIGHTS = $0008;
  ENLISTMENT_SUPERIOR_RIGHTS = $0010;

  ENLISTMENT_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  TmEnAccessMapping: array [0..4] of TFlagName = (
    (Value: ENLISTMENT_QUERY_INFORMATION;  Name: 'Query information'),
    (Value: ENLISTMENT_SET_INFORMATION;    Name: 'Set information'),
    (Value: ENLISTMENT_RECOVER;            Name: 'Recover'),
    (Value: ENLISTMENT_SUBORDINATE_RIGHTS; Name: 'Subordinate rights'),
    (Value: ENLISTMENT_SUPERIOR_RIGHTS;    Name: 'Superior rights')
  );

  TmEnAccessType: TAccessMaskType = (
    TypeName: 'enlistment';
    FullAccess: ENLISTMENT_ALL_ACCESS;
    Count: Length(TmEnAccessMapping);
    Mapping: PFlagNameRefs(@TmEnAccessMapping);
  );

type
  // wdm.15389
  [NamingStyle(nsSnakeCase, 'KTMOBJECT')]
  TKtmObjectType = (
    KTMOBJECT_TRANSACTION = 0,
    KTMOBJECT_TRANSACTION_MANAGER = 1,
    KTMOBJECT_RESOURCE_MANAGER = 2,
    KTMOBJECT_ENLISTMENT = 3,
    KTMOBJECT_INVALID = 4
  );

  // wdm.15407
  TKtmObjectCursor = record
    LastQuery: TGuid;
    ObjectIdCount: Integer;
    ObjectIds: array [ANYSIZE_ARRAY] of TGuid;
  end;
  PKtmObjectCursor = ^TKtmObjectCursor;

  [NamingStyle(nsCamelCase, 'Transaction')]
  TTransactionInformationClass = (
    TransactionBasicInformation = 0,      // q: TTrasactionBasicInformation
    TransactionPropertiesInformation = 1, // q, s: TTransactionPropertiesInformation
    TransactionEnlistmentInformation = 2, // q: TTransactionEnlistmentsInformation
    TransactionSuperiorEnlistmentInformation = 3 // q: TTransactionEnlistmentPair
  );

  [NamingStyle(nsCamelCase, 'TransactionOutcome'), Range(1)]
  TTransactionOutcome = (
    TransactionOutcomeInvalid = 0,
    TransactionOutcomeUndetermined = 1,
    TransactionOutcomeCommitted = 2,
    TransactionOutcomeAborted = 3
  );

  [NamingStyle(nsCamelCase, 'TransactionState'), Range(1)]
  TTransactionState = (
    TransactionStateInvalid = 0,
    TransactionStateNormal = 1,
    TransactionStateInDoubt = 2,
    TransactionStateCommittedNotify = 3
  );

  TTransactionBasicInformation = record
    TransactionId: TGuid;
    State: TTransactionState;
    Outcome: TTransactionOutcome;
  end;
  PTransactionBasicInformation = ^TTransactionBasicInformation;

  TTransactionPropertiesInformation = record
    IsolationLevel: Cardinal;
    [Hex]  IsolationFlags: Cardinal;
    Timeout: TLargeInteger;
    Outcome: TTransactionOutcome;
    DescriptionLength: Cardinal;
    Description: array [ANYSIZE_ARRAY] of WideChar;
  end;
  PTransactionPropertiesInformation = ^TTransactionPropertiesInformation;

  TTransactionEnlistmentPair = record
    EnlistmentId: TGuid;
    ResourceManagerId: TGuid;
  end;
  PTransactionEnlistmentPair = ^TTransactionEnlistmentPair;

  TTransactionEnlistmentsInformation = record
    NumberOfEnlistments: Cardinal;
    EnlistmentPair: array [ANYSIZE_ARRAY] of TTransactionEnlistmentPair;
  end;
  PTransactionEnlistmentsInformation = ^TTransactionEnlistmentsInformation;

function NtEnumerateTransactionObject(RootObjectHandle: THandle;
  QueryType: TKtmObjectType; ObjectCursor: PKtmObjectCursor;
  ObjectCursorLength: Cardinal; out ReturnLength: Cardinal): NTSTATUS;
  stdcall; external ntdll;

function NtCreateTransaction(out TransactionHandle: THandle; DesiredAccess:
  TAccessMask; ObjectAttributes: PObjectAttributes; Uow: PGuid; TmHandle:
  THandle; CreateOptions: Cardinal; IsolationLevel: Cardinal; IsolationFlags:
  Cardinal; Timeout: PLargeInteger; Description: PUNICODE_STRING): NTSTATUS;
  stdcall; external ntdll;

function NtOpenTransaction(out TransactionHandle: THandle; DesiredAccess:
  TAccessMask; const ObjectAttributes: TObjectAttributes; Uow: PGuid;
  TmHandle: THandle): NTSTATUS; stdcall; external ntdll;

function NtQueryInformationTransaction(TransactionHandle: THandle;
  TransactionInformationClass: TTransactionInformationClass;
  TransactionInformation: Pointer; TransactionInformationLength: Cardinal;
  ReturnLength: PCardinal): NTSTATUS; stdcall; external ntdll;

function NtSetInformationTransaction(TransactionHandle: THandle;
  TransactionInformationClass: TTransactionInformationClass;
  TransactionInformation: Pointer; TransactionInformationLength: Cardinal):
  NTSTATUS; stdcall; external ntdll;

function NtCommitTransaction(TransactionHandle: THandle; Wait: Boolean):
  NTSTATUS; stdcall; external ntdll;

function NtRollbackTransaction(TransactionHandle: THandle; Wait: Boolean):
  NTSTATUS; stdcall; external ntdll;

implementation

end.
