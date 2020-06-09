unit NtUtils.Transactions;

interface

uses
  Winapi.WinNt, Ntapi.nttmapi, NtUtils, NtUtils.Objects;

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
function NtxEnumerateKtmObjects(KtmObjectType: TKtmObjectType;
  out Guids: TArray<TGuid>; RootObject: THandle = 0): TNtxStatus;

// ------------------------------ Transaction ------------------------------ //

// Create a transaction object
function NtxCreateTransaction(out hxTransaction: IHandle; Description:
  String = ''; Name: String = ''; Root: THandle = 0;
  Attributes: Cardinal = 0): TNtxStatus;

// Open existing transaction by name
function NtxOpenTransaction(out hxTransaction: IHandle; DesiredAccess:
  TAccessMask; Name: String; Root: THandle = 0; Attributes: Cardinal = 0)
  : TNtxStatus;

// Open a transaction object by id
function NtxOpenTransactionById(out hxTransaction: IHandle; const Uow: TGuid;
  DesiredAccess: TAccessMask; Attributes: Cardinal = 0): TNtxStatus;

type
  NtxTransaction = class
    // Query fixed-size information
    class function Query<T>(hTransaction: THandle; InfoClass
      : TTransactionInformationClass; out Buffer: T): TNtxStatus; static;
  end;

// Query transaction properties
function NtxQueryPropertiesTransaction(hTransaction: THandle;
  out Properties: TTransactionProperties): TNtxStatus;

// Commit a transaction
function NtxCommitTransaction(hTransaction: THandle; Wait: Boolean = True)
  : TNtxStatus;

// Abort a transaction
function NtxRollbackTransaction(hTransaction: THandle; Wait: Boolean = True):
  TNtxStatus;

// -------------------------- Transaction Manager -------------------------- //

// Open a transaction manager by a GUID
function NtxOpenTransactionManagerById(out hxTmTm: IHandle; DesiredAccess:
  TAccessMask; const TmIdentity: TGuid; HandleAttributes: Cardinal = 0;
  OpenOptions: Cardinal = 0): TNtxStatus;

// Open a transaction manager by a name
function NtxOpenTransactionManagerByName(out hxTmTm: IHandle; DesiredAccess:
  TAccessMask; ObjectName: String; Root: THandle = 0; HandleAttributes:
  Cardinal = 0; OpenOptions: Cardinal = 0): TNtxStatus;

type
  NtxTmTm = class
    // Query fixed-size information
    class function Query<T>(hTmTm: THandle; InfoClass:
      TTransactionManagerInformationClass; out Buffer: T): TNtxStatus; static;
  end;

// Query a LOG file path for a transaction manager
function NtxQueryLogPathTmTx(hTmTx: THandle; out LogPath: String): TNtxStatus;

// --------------------------- Resource Manager ---------------------------- //

// Open a resource manager by a GUID
function NtxOpenResourceManagerById(out hxTmRm: IHandle; DesiredAccess:
  TAccessMask; TmHandle: THandle; const ResourceManagerGuid: TGuid;
  HandleAttributes: Cardinal = 0): TNtxStatus;

// Query basic information about a resource Manager
function NtxQueryBasicTmRm(hTmRm: THandle; out BasicInfo:
  TResourceManagerBasicInfo): TNtxStatus;

// ------------------------------ Enlistment ------------------------------- //

// Open an enlistment
function NtxOpenEnlistmentById(out hxTmEn: IHandle; DesiredAccess: TAccessMask;
  RmHandle: THandle; const EnlistmentGuid: TGuid; HandleAttributes:
  Cardinal = 0): TNtxStatus;

type
  NtxTmEn = class
    // Query fixed-size information
    class function Query<T>(hTmEn: THandle; InfoClass:
      TEnlistmentInformationClass; out Buffer: T): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, DelphiUtils.AutoObject;

function NtxEnumerateKtmObjects(KtmObjectType: TKtmObjectType;
  out Guids: TArray<TGuid>; RootObject: THandle): TNtxStatus;
var
  Cursor: TKtmObjectCursor;
  Required: Cardinal;
begin
  Result.Location := 'NtEnumerateTransactionObject';
  Result.LastCall.AttachInfoClass(KtmObjectType);

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

  FillChar(Cursor, SizeOf(Cursor), 0);
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

function NtxCreateTransaction(out hxTransaction: IHandle; Description: String;
  Name: String; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  hTransaction: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(Name).RefOrNull,
    Attributes, Root);

  Result.Location := 'NtCreateTransaction';
  Result.Status := NtCreateTransaction(hTransaction, TRANSACTION_ALL_ACCESS,
    @ObjAttr, nil, 0, 0, 0, 0, nil, TNtUnicodeString.From(
    Description).RefOrNull);

  if Result.IsSuccess then
    hxTransaction := TAutoHandle.Capture(hTransaction);
end;

function NtxOpenTransaction(out hxTransaction: IHandle; DesiredAccess:
  TAccessMask; Name: String; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  hTransaction: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(Name).RefOrNull,
    Attributes, Root);

  Result.Location := 'NtOpenTransaction';
  Result.LastCall.AttachInfoClass<TTmTxAccessMask>(DesiredAccess);

  Result.Status := NtOpenTransaction(hTransaction, DesiredAccess, ObjAttr, nil,
    0);

  if Result.IsSuccess then
    hxTransaction := TAutoHandle.Capture(hTransaction);
end;

function NtxOpenTransactionById(out hxTransaction: IHandle; const Uow: TGuid;
  DesiredAccess: TAccessMask; Attributes: Cardinal = 0): TNtxStatus;
var
  hTransaction: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, nil, Attributes);

  Result.Location := 'NtOpenTransaction';
  Result.LastCall.AttachAccess<TTmTxAccessMask>(DesiredAccess);

  Result.Status := NtOpenTransaction(hTransaction, DesiredAccess, ObjAttr, @Uow,
    0);

  if Result.IsSuccess then
    hxTransaction := TAutoHandle.Capture(hTransaction);
end;

class function NtxTransaction.Query<T>(hTransaction: THandle;
  InfoClass: TTransactionInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationTransaction';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_QUERY_INFORMATION);

  Result.Status := NtQueryInformationTransaction(hTransaction, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

function NtxQueryPropertiesTransaction(hTransaction: THandle;
  out Properties: TTransactionProperties): TNtxStatus;
const
  BUFFER_SIZE = SizeOf(TTransactionPropertiesInformation) +
    MAX_TRANSACTION_DESCRIPTION_LENGTH * SizeOf(WideChar);
var
  xMemory: IMemory<PTransactionPropertiesInformation>;
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationTransaction';
  Result.LastCall.AttachInfoClass(TransactionPropertiesInformation);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_QUERY_INFORMATION);

  IMemory(xMemory) := TAutoMemory.Allocate(BUFFER_SIZE);
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

function NtxCommitTransaction(hTransaction: THandle; Wait: Boolean): TNtxStatus;
begin
  Result.Location := 'NtCommitTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_COMMIT);
  Result.Status := NtCommitTransaction(hTransaction, Wait);
end;

function NtxRollbackTransaction(hTransaction: THandle; Wait: Boolean):
  TNtxStatus;
begin
  Result.Location := 'NtRollbackTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ROLLBACK);
  Result.Status := NtRollbackTransaction(hTransaction, Wait);
end;

// Transaction Manager

function NtxOpenTransactionManagerById(out hxTmTm: IHandle; DesiredAccess:
  TAccessMask; const TmIdentity: TGuid; HandleAttributes: Cardinal;
  OpenOptions: Cardinal): TNtxStatus;
var
  hTmTm: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);

  Result.Location := 'NtOpenTransactionManager';
  Result.LastCall.AttachAccess<TTmTmAccessMask>(DesiredAccess);

  Result.Status := NtOpenTransactionManager(hTmTm, DesiredAccess, @ObjAttr, nil,
    @TmIdentity, OpenOptions);

  if Result.IsSuccess then
    hxTmTm := TAutoHandle.Capture(hTmTm);
end;

function NtxOpenTransactionManagerByName(out hxTmTm: IHandle; DesiredAccess:
  TAccessMask; ObjectName: String; Root: THandle; HandleAttributes:
  Cardinal; OpenOptions: Cardinal): TNtxStatus;
var
  hTm: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(
    ObjectName).RefOrNull, HandleAttributes);

  Result.Location := 'NtOpenTransactionManager';
  Result.LastCall.AttachAccess<TTmTmAccessMask>(DesiredAccess);

  Result.Status := NtOpenTransactionManager(hTm, DesiredAccess, @ObjAttr, nil,
    nil, OpenOptions);

  if Result.IsSuccess then
    hxTmTm := TAutoHandle.Capture(hTm);
end;

class function NtxTmTm.Query<T>(hTmTm: THandle;
  InfoClass: TTransactionManagerInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationTransactionManager';
  Result.LastCall.AttachInfoClass(InfoClass);

  Result.Status := NtQueryInformationTransactionManager(hTmTm,
    InfoClass, @Buffer, SizeOf(Buffer), nil);
end;

function NtxQueryLogPathTmTx(hTmTx: THandle; out LogPath: String): TNtxStatus;
var
  xMemory: IMemory<PTransactionManagerLogPathInformation>;
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationTransactionManager';
  Result.LastCall.AttachInfoClass(TransactionManagerLogPathInformation);
  Result.LastCall.Expects<TTmTmAccessMask>(TRANSACTIONMANAGER_QUERY_INFORMATION);

  // Initial size
  IMemory(xMemory) := TAutoMemory.Allocate(
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

function NtxOpenResourceManagerById(out hxTmRm: IHandle; DesiredAccess:
  TAccessMask; TmHandle: THandle; const ResourceManagerGuid: TGuid;
  HandleAttributes: Cardinal): TNtxStatus;
var
  hTmRm: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);

  Result.Location := 'NtOpenResourceManager';
  Result.LastCall.AttachAccess<TTmRmAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TTmTmAccessMask>(TRANSACTIONMANAGER_QUERY_INFORMATION);

  Result.Status := NtOpenResourceManager(hTmRm, DesiredAccess, TmHandle,
    @ResourceManagerGuid, @ObjAttr);

  if Result.IsSuccess then
    hxTmRm := TAutoHandle.Capture(hTmRm);
end;

function NtxQueryBasicTmRm(hTmRm: THandle; out BasicInfo:
  TResourceManagerBasicInfo): TNtxStatus;
const
  BUFFER_SIZE = SizeOf(TResourceManagerBasicInformation) +
    MAX_RESOURCEMANAGER_DESCRIPTION_LENGTH * SizeOf(WideChar);
var
  xMemory: IMemory<PResourceManagerBasicInformation>;
  Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationResourceManager';
  Result.LastCall.AttachInfoClass(ResourceManagerBasicInformation);
  Result.LastCall.Expects<TTmRmAccessMask>(RESOURCEMANAGER_QUERY_INFORMATION);

  IMemory(xMemory) := TAutoMemory.Allocate(BUFFER_SIZE);
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

function NtxOpenEnlistmentById(out hxTmEn: IHandle; DesiredAccess: TAccessMask;
  RmHandle: THandle; const EnlistmentGuid: TGuid; HandleAttributes: Cardinal)
  : TNtxStatus;
var
  hTmEn: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, nil, HandleAttributes);

  Result.Location := 'NtOpenEnlistment';
  Result.LastCall.AttachAccess<TTmEnAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TTmRmAccessMask>(RESOURCEMANAGER_QUERY_INFORMATION);

  Result.Status := NtOpenEnlistment(hTmEn, DesiredAccess, RmHandle,
    EnlistmentGuid, @ObjAttr);

  if Result.IsSuccess then
    hxTmEn := TAutoHandle.Capture(hTmEn);
end;

class function NtxTmEn.Query<T>(hTmEn: THandle;
  InfoClass: TEnlistmentInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationEnlistment';
  Result.LastCall.AttachInfoClass(InfoClass);

  Result.Status := NtQueryInformationEnlistment(hTmEn, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

end.
