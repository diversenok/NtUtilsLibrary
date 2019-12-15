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

// Create a transaction object
function NtxCreateTransaction(out hxTransaction: IHandle; Description:
  String = ''; Name: String = ''; Root: THandle = 0;
  Attributes: Cardinal = 0): TNtxStatus;

// Open existing transaction
function NtxOpenTransaction(out hxTransaction: IHandle; DesiredAccess:
  TAccessMask; Name: String; Root: THandle = 0; Attributes: Cardinal = 0)
  : TNtxStatus;

// Open a transaction object by id
function NtxOpenTransactionById(out hxTransaction: IHandle; const Uow: TGuid;
  DesiredAccess: TAccessMask; Attributes: Cardinal = 0): TNtxStatus;

// Enumerate transactions on the system
function NtxEnumerateTransactions(out Guids: TArray<TGuid>;
  KtmObjectType: TKtmObjectType = KtmObjectTransaction; RootObject: THandle = 0)
  : TNtxStatus;

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

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus;

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

function NtxEnumerateTransactions(out Guids: TArray<TGuid>;
  KtmObjectType: TKtmObjectType; RootObject: THandle): TNtxStatus;
var
  Buffer: TKtmObjectCursor;
  Required: Cardinal;
begin
  Result.Location := 'NtEnumerateTransactionObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(KtmObjectType);
  Result.LastCall.InfoClassType := TypeInfo(TKtmObjectType);

  FillChar(Buffer, SizeOf(Buffer), 0);
  SetLength(Guids, 0);

  repeat
    Result.Status := NtEnumerateTransactionObject(0, KtmObjectType,
      @Buffer, SizeOf(Buffer), Required);

    if not Result.IsSuccess then
      Break;

    SetLength(Guids, Length(Guids) + 1);
    Guids[High(Guids)] := Buffer.ObjectIds[0];
  until False;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
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

end.
