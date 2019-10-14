unit Ntapi.nttmapi;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef;

const
  // WinNt.22018
  TRANSACTION_QUERY_INFORMATION = $0001;
  TRANSACTION_SET_INFORMATION = $0002;
  TRANSACTION_ENLIST = $0004;
  TRANSACTION_COMMIT = $0008;
  TRANSACTION_ROLLBACK = $0010;
  TRANSACTION_PROPAGATE = $0020;

  TRANSACTION_ALL_ACCESS = $003F or STANDARD_RIGHTS_ALL;

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

type
  // wdm.15389
  TKtmObjectType = (
    KtmObjectTransaction = 0,
    KtmObjectTransactionManager = 1,
    KtmObjectResourceManager = 2,
    KtmObjectEnlistment = 3,
    KtmObjectInvalid = 4
  );

  // wdm.15407
  TKtmObjectCursor = record
    LastQuery: TGuid;
    ObjectIdCount: Integer;
    ObjectIds: array [ANYSIZE_ARRAY] of TGuid;
  end;
  PKtmObjectCursor = ^TKtmObjectCursor;

  TTransactionInformationClass = (
    TransactionBasicInformation = 0,      // q: TTrasactionBasicInformation
    TransactionPropertiesInformation = 1, // q, s: TTransactionPropertiesInformation
    TransactionEnlistmentInformation = 2, // q: TTransactionEnlistmentsInformation
    TransactionSuperiorEnlistmentInformation = 3 // q: TTransactionEnlistmentPair
  );

  TTransactionOutcome = (
    TransactionOutcomeReserved = 0,
    TransactionOutcomeUndetermined = 1,
    TransactionOutcomeCommitted = 2,
    TransactionOutcomeAborted = 3
  );

  TTransactionState = (
    TransactionStateReserved = 0,
    TransactionStateNormal = 1,
    TransactionStateIndoubt = 2,
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
    IsolationFlags: Cardinal;
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
