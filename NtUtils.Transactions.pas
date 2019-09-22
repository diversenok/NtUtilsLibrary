unit NtUtils.Transactions;

interface

uses
  Winapi.WinNt, Ntapi.nttmapi, NtUtils.Exceptions;

type
  TTransactionProperties = record
    IsolationLevel: Cardinal;
    IsolationFlags: Cardinal;
    Timeout: TLargeInteger;
    Outcome: TTransactionOutcome;
    Description: String;
  end;

// Create a transaction object
function NtxCreateTransaction(out hTransaction: THandle; Description:
  String = ''; Name: String = ''; Root: THandle = 0;
  Attributes: Cardinal = 0): TNtxStatus;

// Open existing transaction
function NtxOpenTransaction(out hTransaction: THandle; DesiredAccess:
  TAccessMask; Name: String; Root: THandle = 0; Attributes: Cardinal = 0)
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

implementation

uses
  Ntapi.ntdef;

function NtxCreateTransaction(out hTransaction: THandle; Description: String;
  Name: String; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
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
end;

function NtxOpenTransaction(out hTransaction: THandle; DesiredAccess:
  TAccessMask; Name: String; Root: THandle; Attributes: Cardinal): TNtxStatus;
var
  ObjName: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
begin
  ObjName.FromString(Name);
  InitializeObjectAttributes(ObjAttr, @ObjName, Attributes, Root);

  Result.Location := 'NtOpenTransaction';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := objNtTransaction;

  Result.Status := NtOpenTransaction(hTransaction, DesiredAccess, ObjAttr, nil,
    0);
end;

class function NtxTransaction.Query<T>(hTransaction: THandle;
  InfoClass: TTransactionInformationClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQueryInformationTransaction';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TTransactionInformationClass);
  Result.LastCall.Expects(TRANSACTION_QUERY_INFORMATION, objNtTransaction);

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
  Result.LastCall.Expects(TRANSACTION_QUERY_INFORMATION, objNtTransaction);

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

end.
