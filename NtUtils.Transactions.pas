unit NtUtils.Transactions;

interface

uses
  Winapi.WinNt, Ntapi.nttmapi, NtUtils.Exceptions, NtUtils.Objects;

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
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl;

function NtxEnumerateKtmObjects(KtmObjectType: TKtmObjectType;
  out Guids: TArray<TGuid>; RootObject: THandle): TNtxStatus;
var
  Buffer: TKtmObjectCursor;
  Required: Cardinal;
begin
  Result.Location := 'NtEnumerateTransactionObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(KtmObjectType);
  Result.LastCall.InfoClassType := TypeInfo(TKtmObjectType);

  case KtmObjectType of
    KTMOBJECT_TRANSACTION:
      if RootObject <> 0 then
        Result.LastCall.Expects(TRANSACTIONMANAGER_QUERY_INFORMATION,
          @TmTmAccessType);

    KTMOBJECT_RESOURCE_MANAGER:
      Result.LastCall.Expects(TRANSACTIONMANAGER_QUERY_INFORMATION,
        @TmTmAccessType);

    KTMOBJECT_ENLISTMENT:
      Result.LastCall.Expects(RESOURCEMANAGER_QUERY_INFORMATION,
        @TmRmAccessType);
  end;

  FillChar(Buffer, SizeOf(Buffer), 0);
  SetLength(Guids, 0);

  repeat
    Result.Status := NtEnumerateTransactionObject(RootObject, KtmObjectType,
      @Buffer, SizeOf(Buffer), Required);

    if not Result.IsSuccess then
      Break;

    SetLength(Guids, Length(Guids) + 1);
    Guids[High(Guids)] := Buffer.ObjectIds[0];
  until False;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

// Transactions

function NtxCreateTransaction(out hxTransaction: IHandle; Description: String;
  Name: String; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  hTransaction: THandle;
  ObjName, ObjDescription: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
  pDescription: PUNICODE_STRING;
begin
  InitializeObjectAttributes(ObjAttr, nil, Attributes, Root);

  if Name <> '' then
  begin
    ObjName.FromString(Name);
    ObjAttr.ObjectName := @ObjName;
  end;

  if Description <> '' then
  begin
    ObjDescription.FromString(Description);
    pDescription := @ObjDescription;
  end
  else
    pDescription := nil;

  Result.Location := 'NtCreateTransaction';
  Result.Status := NtCreateTransaction(hTransaction, TRANSACTION_ALL_ACCESS,
    @ObjAttr, nil, 0, 0, 0, 0, nil, pDescription);

  if Result.IsSuccess then
    hxTransaction := TAutoHandle.Capture(hTransaction);
end;

function NtxOpenTransaction(out hxTransaction: IHandle; DesiredAccess:
  TAccessMask; Name: String; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  hTransaction: THandle;
  ObjName: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
begin
  ObjName.FromString(Name);
  InitializeObjectAttributes(ObjAttr, @ObjName, Attributes, Root);

  Result.Location := 'NtOpenTransaction';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @TmTxAccessType;

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
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @TmTxAccessType;

  Result.Status := NtOpenTransaction(hTransaction, DesiredAccess, ObjAttr, @Uow,
    0);

  if Result.IsSuccess then
    hxTransaction := TAutoHandle.Capture(hTransaction);
end;

class function NtxTransaction.Query<T>(hTransaction: THandle;
  InfoClass: TTransactionInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationTransaction';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTransactionInformationClass);
  Result.LastCall.Expects(TRANSACTION_QUERY_INFORMATION, @TmTxAccessType);

  Result.Status := NtQueryInformationTransaction(hTransaction, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

function NtxQueryPropertiesTransaction(hTransaction: THandle;
  out Properties: TTransactionProperties): TNtxStatus;
const
  BUFFER_SIZE = SizeOf(TTransactionPropertiesInformation) +
    MAX_TRANSACTION_DESCRIPTION_LENGTH * SizeOf(WideChar);
var
  Buffer: PTransactionPropertiesInformation;
begin
  Result.Location := 'NtQueryInformationTransaction';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(TransactionPropertiesInformation);
  Result.LastCall.InfoClassType := TypeInfo(TTransactionInformationClass);
  Result.LastCall.Expects(TRANSACTION_QUERY_INFORMATION, @TmTxAccessType);

  Buffer := AllocMem(BUFFER_SIZE);
  Result.Status := NtQueryInformationTransaction(hTransaction,
    TransactionPropertiesInformation, Buffer, BUFFER_SIZE, nil);

  if Result.IsSuccess then
  begin
    Properties.IsolationLevel := Buffer.IsolationLevel;
    Properties.IsolationFlags := Buffer.IsolationFlags;
    Properties.Timeout := Buffer.Timeout;
    Properties.Outcome := Buffer.Outcome;
    SetString(Properties.Description, Buffer.Description,
      Buffer.DescriptionLength div SizeOf(WideChar));
  end;

  FreeMem(Buffer);
end;

function NtxCommitTransaction(hTransaction: THandle; Wait: Boolean): TNtxStatus;
begin
  Result.Location := 'NtCommitTransaction';
  Result.LastCall.Expects(TRANSACTION_COMMIT, @TmTxAccessType);
  Result.Status := NtCommitTransaction(hTransaction, Wait);
end;

function NtxRollbackTransaction(hTransaction: THandle; Wait: Boolean):
  TNtxStatus;
begin
  Result.Location := 'NtRollbackTransaction';
  Result.LastCall.Expects(TRANSACTION_ROLLBACK, @TmTxAccessType);
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
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @TmTmAccessType;

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
  NameStr: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
begin
  NameStr.FromString(ObjectName);
  InitializeObjectAttributes(ObjAttr, @NameStr, HandleAttributes);

  Result.Location := 'NtOpenTransactionManager';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @TmTmAccessType;

  Result.Status := NtOpenTransactionManager(hTm, DesiredAccess, @ObjAttr, nil,
    nil, OpenOptions);

  if Result.IsSuccess then
    hxTmTm := TAutoHandle.Capture(hTm);
end;

class function NtxTmTm.Query<T>(hTmTm: THandle;
  InfoClass: TTransactionManagerInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationTransactionManager';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTransactionManagerInformationClass);

  Result.Status := NtQueryInformationTransactionManager(hTmTm,
    InfoClass, @Buffer, SizeOf(Buffer), nil);
end;

function NtxQueryLogPathTmTx(hTmTx: THandle; out LogPath: String): TNtxStatus;
var
  Buffer: PTransactionManagerLogPathInformation;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'NtQueryInformationTransactionManager';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(TransactionManagerLogPathInformation);
  Result.LastCall.InfoClassType := TypeInfo(TTransactionManagerInformationClass);
  Result.LastCall.Expects(TRANSACTIONMANAGER_QUERY_INFORMATION, @TmTmAccessType);

  BufferSize := SizeOf(TTransactionManagerLogPathInformation) +
    RtlGetLongestNtPathLength * SizeOf(WideChar);

  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryInformationTransactionManager(hTmTx,
      TransactionManagerLogPathInformation, Buffer, BufferSize, @Required);

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;
  until not NtxExpandBuffer(Result, BufferSize, Required);

  if Result.IsSuccess then
    SetString(LogPath, PWideChar(@Buffer.LogPath), Buffer.LogPathLength div
      SizeOf(WideChar));

  FreeMem(Buffer);
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
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @TmRmAccessType;
  Result.LastCall.Expects(TRANSACTIONMANAGER_QUERY_INFORMATION, @TmTmAccessType);

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
  Buffer: PResourceManagerBasicInformation;
begin
  Result.Location := 'NtQueryInformationResourceManager';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(ResourceManagerBasicInformation);
  Result.LastCall.InfoClassType := TypeInfo(TResourceManagerInformationClass);
  Result.LastCall.Expects(RESOURCEMANAGER_QUERY_INFORMATION, @TmRmAccessType);

  Buffer := AllocMem(BUFFER_SIZE);
  Result.Status := NtQueryInformationResourceManager(hTmRm,
    ResourceManagerBasicInformation, Buffer, BUFFER_SIZE, nil);

  if Result.IsSuccess then
  begin
    BasicInfo.ResourceManagerID := Buffer.ResourceManagerId;
    SetString(BasicInfo.Description, Buffer.Description,
      Buffer.DescriptionLength div SizeOf(WideChar));
  end;

  FreeMem(Buffer);
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
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @TmEnAccessType;
  Result.LastCall.Expects(RESOURCEMANAGER_QUERY_INFORMATION, @TmRmAccessType);

  Result.Status := NtOpenEnlistment(hTmEn, DesiredAccess, RmHandle,
    EnlistmentGuid, @ObjAttr);

  if Result.IsSuccess then
    hxTmEn := TAutoHandle.Capture(hTmEn);
end;

class function NtxTmEn.Query<T>(hTmEn: THandle;
  InfoClass: TEnlistmentInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationEnlistment';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TEnlistmentInformationClass);

  Result.Status := NtQueryInformationEnlistment(hTmEn, InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

end.
