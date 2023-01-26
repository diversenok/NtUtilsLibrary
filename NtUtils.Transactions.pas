unit NtUtils.Transactions;

{
  The module introduces functions for working with transactions and related
  object types.
}

interface

uses
  Ntapi.WinNt, Ntapi.nttmapi, Ntapi.Versions, NtUtils, NtUtils.Objects;

type
  TTransactionProperties = record
    IsolationLevel: Cardinal;
    IsolationFlags: Cardinal;
    Timeout: TLargeInteger;
    Outcome: TTransactionOutcome;
    Description: String;
  end;

  TResourceManagerBasicInfo = record
    ResourceManagerID: TGuid;
    Description: String;
  end;

// Enumerate Kernel Transaction Manager objects on the system
function NtxEnumerateKtmObjects(
  KtmObjectType: TKtmObjectType;
  out Guids: TArray<TGuid>;
  [opt] RootObject: THandle = 0
): TNtxStatus;

// ------------------------------ Transaction ------------------------------ //

// Create a transaction object
function NtxCreateTransaction(
  out hxTransaction: IHandle;
  [opt] const Description: String = '';
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open a transaction object by GUID
function NtxOpenTransaction(
  out hxTransaction: IHandle;
  const Uow: TGuid;
  DesiredAccess: TTmTxAccessMask;
  [opt, Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] hTmTm: THandle = 0
): TNtxStatus;

type
  NtxTransaction = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(TRANSACTION_QUERY_INFORMATION)] hTransaction: THandle;
      InfoClass: TTransactionInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Query transaction properties
function NtxQueryPropertiesTransaction(
  [Access(TRANSACTION_QUERY_INFORMATION)] hTransaction: THandle;
  out Properties: TTransactionProperties
): TNtxStatus;

// Commit a transaction
function NtxCommitTransaction(
  [Access(TRANSACTION_COMMIT)] hTransaction: THandle;
  Wait: Boolean = True
): TNtxStatus;

// Abort a transaction
function NtxRollbackTransaction(
  [Access(TRANSACTION_ROLLBACK)] hTransaction: THandle;
  Wait: Boolean = True
): TNtxStatus;

// Set the current filesystem transaction and reset it later
function RtlxSetCurrentTransaction(
  [Access(TRANSACTION_ENLIST)] const hxTransaction: IHandle
): IAutoReleasable;

// ------------------------- Registry Transaction -------------------------- //

// Create a registry transaction
[MinOSVersion(OsWin10RS1)]
function NtxCreateRegistryTransaction(
  out hxTransaction: IHandle;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open a registry transaction by name
[MinOSVersion(OsWin10RS1)]
function NtxOpenRegistryTransaction(
  out hxTransaction: IHandle;
  DesiredAccess: TTmTxAccessMask;
  const Name: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Commit a registry transaction
[MinOSVersion(OsWin10RS1)]
function NtxCommitRegistryTransaction(
  [Access(TRANSACTION_COMMIT)] hTransaction: THandle
): TNtxStatus;

// Abort a registry transaction
[MinOSVersion(OsWin10RS1)]
function NtxRollbackRegistryTransaction(
  [Access(TRANSACTION_ROLLBACK)] hTransaction: THandle
): TNtxStatus;

// -------------------------- Transaction Manager -------------------------- //

// Create a transaction manager
function NtxCreateTransactionManager(
  out hxTmTm: IHandle;
  [opt] const LogFileName: String;
  CreateOptions: TTmTmCreateOptions;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open a transaction manager by a GUID
function NtxOpenTransactionManager(
  out hxTmTm: IHandle;
  [opt] const LogFileName: String;
  [in, opt] TmIdentity: PGuid;
  DesiredAccess: TTmTmAccessMask
): TNtxStatus;

type
  NtxTmTm = class
    // Query fixed-size information
    class function Query<T>(
      [Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] hTmTm: THandle;
      InfoClass: TTransactionManagerInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Query a LOG file path for a transaction manager
function NtxQueryLogPathTmTx(
  [Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] hTmTx: THandle;
  out LogPath: String
): TNtxStatus;

// --------------------------- Resource Manager ---------------------------- //

// Create a resource manager
function NtxCreateResourceManager(
  out hxTmRm: IHandle;
  [Access(TRANSACTIONMANAGER_CREATE_RM)] hTmTm: THandle;
  const RmGuid: TGuid;
  CreateOptions: TTmRmCreateOptions;
  [opt] const Description: String = '';
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus; stdcall;

// Open a resource manager by a GUID
function NtxOpenResourceManager(
  out hxTmRm: IHandle;
  const RmGuid: TGuid;
  [Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] hTmTm: THandle;
  DesiredAccess: TTmRmAccessMask
): TNtxStatus;

// Query basic information about a resource Manager
function NtxQueryBasicTmRm(
  [Access(RESOURCEMANAGER_QUERY_INFORMATION)] hTmRm: THandle;
  out BasicInfo: TResourceManagerBasicInfo
): TNtxStatus;

// ------------------------------ Enlistment ------------------------------- //

// Create an enlistment
function NtxCreateEnlistment(
  out hxTmEn: IHandle;
  [Access(RESOURCEMANAGER_ENLIST)] hTmRm: THandle;
  [Access(TRANSACTION_ENLIST)] hTmTx: THandle;
  CreateOptions: TTmEnCreateOptions;
  NotificationMask: TTmEnNotificationMask;
  EnlistmentKey: NativeUInt;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an enlistment
function NtxOpenEnlistment(
  out hxTmEn: IHandle;
  const EnlistmentGuid: TGuid;
  [Access(RESOURCEMANAGER_QUERY_INFORMATION)] RmHandle: THandle;
  DesiredAccess: TTmEnAccessMask
): TNtxStatus;

type
  NtxTmEn = class
    // Query fixed-size information
    class function Query<T>(
      [Access(ENLISTMENT_QUERY_INFORMATION)] hTmEn: THandle;
      InfoClass: TEnlistmentInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, NtUtils.Ldr, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxEnumerateKtmObjects;
var
  Cursor: TKtmObjectCursor;
  Required: Cardinal;
begin
  Result.Location := 'NtEnumerateTransactionObject';
  Result.LastCall.UsesInfoClass(KtmObjectType, icQuery);

  case KtmObjectType of
    KTMOBJECT_TRANSACTION:
      if RootObject <> 0 then
        Result.LastCall.Expects<TTmTmAccessMask>(
          TRANSACTIONMANAGER_QUERY_INFORMATION);

    KTMOBJECT_RESOURCE_MANAGER:
      Result.LastCall.Expects<TTmTmAccessMask>(
        TRANSACTIONMANAGER_QUERY_INFORMATION);

    KTMOBJECT_ENLISTMENT:
      Result.LastCall.Expects<TTmRmAccessMask>(
        RESOURCEMANAGER_QUERY_INFORMATION);
  end;

  Cursor := Default(TKtmObjectCursor);
  SetLength(Guids, 0);

  repeat
    Result.Status := NtEnumerateTransactionObject(RootObject, KtmObjectType,
      @Cursor, SizeOf(Cursor), Required);

    if not Result.IsSuccess then
      Break;

    SetLength(Guids, Length(Guids) + 1);
    Guids[High(Guids)] := Cursor.ObjectIds[0];
  until False;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

// Transactions

function NtxCreateTransaction;
var
  hTransaction: THandle;
  DescriptionStr: TNtUnicodeString;
begin
  DescriptionStr := TNtUnicodeString.From(Description);

  Result.Location := 'NtCreateTransaction';
  Result.Status := NtCreateTransaction(
    hTransaction,
    AccessMaskOverride(TRANSACTION_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    nil,
    0,
    0,
    0,
    0,
    nil,
    DescriptionStr.RefOrNil
  );

  if Result.IsSuccess then
    hxTransaction := Auto.CaptureHandle(hTransaction);
end;

function NtxOpenTransaction;
var
  hTransaction: THandle;
begin
  Result.Location := 'NtOpenTransaction';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenTransaction(hTransaction, DesiredAccess, nil, Uow,
    hTmTm);

  if Result.IsSuccess then
    hxTransaction := Auto.CaptureHandle(hTransaction);
end;

class function NtxTransaction.Query<T>;
begin
  Result.Location := 'NtQueryInformationTransaction';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_QUERY_INFORMATION);

  Result.Status := NtQueryInformationTransaction(hTransaction, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

function NtxQueryPropertiesTransaction;
const
  BUFFER_SIZE = SizeOf(TTransactionPropertiesInformation) +
    MAX_TRANSACTION_DESCRIPTION_LENGTH * SizeOf(WideChar);
var
  xMemory: IMemory<PTransactionPropertiesInformation>;
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationTransaction';
  Result.LastCall.UsesInfoClass(TransactionPropertiesInformation, icQuery);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_QUERY_INFORMATION);

  IMemory(xMemory) := Auto.AllocateDynamic(BUFFER_SIZE);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationTransaction(hTransaction,
      TransactionPropertiesInformation, xMemory.Data, BUFFER_SIZE, @Required);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), Required, nil);

  if Result.IsSuccess then
  begin
    Properties.IsolationLevel := xMemory.Data.IsolationLevel;
    Properties.IsolationFlags := xMemory.Data.IsolationFlags;
    Properties.Timeout := xMemory.Data.Timeout;
    Properties.Outcome := xMemory.Data.Outcome;
    SetString(Properties.Description, xMemory.Data.Description,
      xMemory.Data.DescriptionLength div SizeOf(WideChar));
  end;
end;

function NtxCommitTransaction;
begin
  Result.Location := 'NtCommitTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_COMMIT);
  Result.Status := NtCommitTransaction(hTransaction, Wait);
end;

function NtxRollbackTransaction;
begin
  Result.Location := 'NtRollbackTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ROLLBACK);
  Result.Status := NtRollbackTransaction(hTransaction, Wait);
end;

function RtlxSetCurrentTransaction;
begin
  // Select the transaction, capture its handle, and queue an undo operation
  if RtlSetCurrentTransaction(hxTransaction.Handle) then
    Result := Auto.Delay(
      procedure
      begin
        if RtlGetCurrentTransaction = hxTransaction.Handle then
          RtlSetCurrentTransaction(0);
      end
    );
end;

// Registry Transactions

function NtxCreateRegistryTransaction;
var
  hTransaction: THandle;
begin
  Result := LdrxCheckNtDelayedImport('NtCreateRegistryTransaction');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateRegistryTransaction';
  Result.Status := NtCreateRegistryTransaction(
    hTransaction,
    AccessMaskOverride(TRANSACTION_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    0
  );

  if Result.IsSuccess then
    hxTransaction := Auto.CaptureHandle(hTransaction);
end;

function NtxOpenRegistryTransaction;
var
  hTransaction: THandle;
begin
  Result := LdrxCheckNtDelayedImport('NtOpenRegistryTransaction');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenRegistryTransaction';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtOpenRegistryTransaction(
    hTransaction,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^
  );

  if Result.IsSuccess then
    hxTransaction := Auto.CaptureHandle(hTransaction);
end;

function NtxCommitRegistryTransaction;
begin
  Result := LdrxCheckNtDelayedImport('NtCommitRegistryTransaction');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCommitRegistryTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_COMMIT);
  Result.Status := NtCommitRegistryTransaction(hTransaction, 0);
end;

function NtxRollbackRegistryTransaction;
begin
  Result := LdrxCheckNtDelayedImport('NtRollbackRegistryTransaction');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtRollbackRegistryTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ROLLBACK);
  Result.Status := NtRollbackRegistryTransaction(hTransaction, 0);
end;

// Transaction Manager

function NtxCreateTransactionManager;
var
  hTmTm: THandle;
  LogFileNameStr: TNtUnicodeString;
begin
  LogFileNameStr := TNtUnicodeString.From(LogFileName);

  Result.Location := 'NtCreateTransactionManager';
  Result.Status := NtCreateTransactionManager(
    hTmTm,
    AccessMaskOverride(TRANSACTIONMANAGER_ALL_ACCESS, ObjectAttributes),
    AttributesRefOrNil(ObjectAttributes),
    LogFileNameStr.RefOrNil,
    CreateOptions,
    0
  );

  if Result.IsSuccess then
    hxTmTm := Auto.CaptureHandle(hTmTm);
end;

function NtxOpenTransactionManager;
var
  hTmTm: THandle;
  LogFileNameStr: TNtUnicodeString;
begin
  LogFileNameStr := TNtUnicodeString.From(LogFileName);

  Result.Location := 'NtOpenTransactionManager';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtOpenTransactionManager(
    hTmTm,
    DesiredAccess,
    nil,
    LogFileNameStr.RefOrNil,
    TmIdentity,
    0
  );

  if Result.IsSuccess then
    hxTmTm := Auto.CaptureHandle(hTmTm);
end;

class function NtxTmTm.Query<T>;
begin
  Result.Location := 'NtQueryInformationTransactionManager';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TTmTmAccessMask>(TRANSACTIONMANAGER_QUERY_INFORMATION);
  Result.Status := NtQueryInformationTransactionManager(hTmTm,
    InfoClass, @Buffer, SizeOf(Buffer), nil);
end;

function NtxQueryLogPathTmTx;
var
  xMemory: IMemory<PTransactionManagerLogPathInformation>;
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationTransactionManager';
  Result.LastCall.UsesInfoClass(TransactionManagerLogPathInformation, icQuery);
  Result.LastCall.Expects<TTmTmAccessMask>(TRANSACTIONMANAGER_QUERY_INFORMATION);

  // Initial size
  IMemory(xMemory) := Auto.AllocateDynamic(
    SizeOf(TTransactionManagerLogPathInformation) +
    RtlGetLongestNtPathLength * SizeOf(WideChar));

  repeat
    Required := 0;
    Result.Status := NtQueryInformationTransactionManager(hTmTx,
      TransactionManagerLogPathInformation, xMemory.Data, xMemory.Size,
      @Required);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), Required, nil);

  if Result.IsSuccess then
    SetString(LogPath, PWideChar(@xMemory.Data.LogPath),
      xMemory.Data.LogPathLength div SizeOf(WideChar));
end;

// Resource Manager

function NtxCreateResourceManager;
var
  hTmRm: THandle;
  DescriptionStr: TNtUnicodeString;
begin
  DescriptionStr := TNtUnicodeString.From(Description);

  Result.Location := 'NtCreateResourceManager';
  Result.LastCall.Expects<TTmTmAccessMask>(TRANSACTIONMANAGER_CREATE_RM);
  Result.Status := NtCreateResourceManager(
    hTmRm,
    AccessMaskOverride(RESOURCEMANAGER_ALL_ACCESS, ObjectAttributes),
    hTmTm,
    RmGuid,
    AttributesRefOrNil(ObjectAttributes),
    CreateOptions,
    DescriptionStr.RefOrNil
  );

  if Result.IsSuccess then
    hxTmRm := Auto.CaptureHandle(hTmRm);
end;

function NtxOpenResourceManager;
var
  hTmRm: THandle;
begin
  Result.Location := 'NtOpenResourceManager';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TTmTmAccessMask>(TRANSACTIONMANAGER_QUERY_INFORMATION);

  Result.Status := NtOpenResourceManager(
    hTmRm,
    DesiredAccess,
    hTmTm,
    RmGuid,
    nil
  );

  if Result.IsSuccess then
    hxTmRm := Auto.CaptureHandle(hTmRm);
end;

function NtxQueryBasicTmRm;
const
  BUFFER_SIZE = SizeOf(TResourceManagerBasicInformation) +
    MAX_RESOURCEMANAGER_DESCRIPTION_LENGTH * SizeOf(WideChar);
var
  xMemory: IMemory<PResourceManagerBasicInformation>;
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationResourceManager';
  Result.LastCall.UsesInfoClass(ResourceManagerBasicInformation, icQuery);
  Result.LastCall.Expects<TTmRmAccessMask>(RESOURCEMANAGER_QUERY_INFORMATION);

  IMemory(xMemory) := Auto.AllocateDynamic(BUFFER_SIZE);
  repeat
    Required := 0;
    Result.Status := NtQueryInformationResourceManager(hTmRm,
      ResourceManagerBasicInformation, xMemory.Data, BUFFER_SIZE, @Required);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), Required, nil);

  if Result.IsSuccess then
  begin
    BasicInfo.ResourceManagerID := xMemory.Data.ResourceManagerId;
    SetString(BasicInfo.Description, xMemory.Data.Description,
      xMemory.Data.DescriptionLength div SizeOf(WideChar));
  end;
end;

// Enlistment

function NtxCreateEnlistment;
var
  hTmEn: THandle;
begin
  Result.Location := 'NtCreateEnlistment';
  Result.LastCall.Expects<TTmRmAccessMask>(RESOURCEMANAGER_ENLIST);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ENLIST);

  Result.Status := NtCreateEnlistment(
    hTmEn,
    AccessMaskOverride(ENLISTMENT_ALL_ACCESS, ObjectAttributes),
    hTmRm,
    hTmTx,
    AttributesRefOrNil(ObjectAttributes),
    CreateOptions,
    NotificationMask,
    EnlistmentKey
  );

  if Result.IsSuccess then
    hxTmEn := Auto.CaptureHandle(hTmEn);
end;

function NtxOpenEnlistment;
var
  hTmEn: THandle;
begin
  Result.Location := 'NtOpenEnlistment';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TTmRmAccessMask>(RESOURCEMANAGER_QUERY_INFORMATION);

  Result.Status := NtOpenEnlistment(
    hTmEn,
    DesiredAccess,
    RmHandle,
    EnlistmentGuid,
    nil
  );

  if Result.IsSuccess then
    hxTmEn := Auto.CaptureHandle(hTmEn);
end;

class function NtxTmEn.Query<T>;
begin
  Result.Location := 'NtQueryInformationEnlistment';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TTmEnAccessMask>(ENLISTMENT_QUERY_INFORMATION);

  Result.Status := NtQueryInformationEnlistment(hTmEn, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

end.
