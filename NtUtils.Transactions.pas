unit NtUtils.Transactions;

{
  The module introduces functions for working with transactions and related
  object types.
}

interface

uses
  Ntapi.WinNt, Ntapi.nttmapi, Ntapi.ntioapi, Ntapi.Versions, NtUtils,
  NtUtils.Objects;

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

  TTxfsLockedFile = record
    Flags: TTxfsTransactionLockedFilesFlags;
    FileId: TFileId;
    Name: String;
  end;

// Iterate over Kernel Transaction Manager object IDs one-by-one
function NtxGetNextKtmObject(
  KtmObjectType: TKtmObjectType;
  var Cursor: TGuid;
  [opt] const hxRootObject: IHandle = nil
): TNtxStatus;

// Make a for-in iterator for enumerating KTM objects.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function NtxIterateKtmObjects(
  [out, opt] Status: PNtxStatus;
  KtmObjectType: TKtmObjectType;
  [opt] const hxRootObject: IHandle = nil
): IEnumerable<TGuid>;

// Enumerate Kernel Transaction Manager objects on the system
function NtxEnumerateKtmObjects(
  KtmObjectType: TKtmObjectType;
  out Guids: TArray<TGuid>;
  [opt] const hxRootObject: IHandle = nil
): TNtxStatus;

// ------------------------------ Transaction ------------------------------ //

// Get an IHandle that always points to the current transaction handle in PEB
function RtlxGetCurrentTransaction: IHandle;

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
  [opt, Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] const hxTmTm: IHandle = nil
): TNtxStatus;

type
  NtxTransaction = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(TRANSACTION_QUERY_INFORMATION)] const hxTransaction: IHandle;
      InfoClass: TTransactionInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Query transaction properties
function NtxQueryPropertiesTransaction(
  [Access(TRANSACTION_QUERY_INFORMATION)] const hxTransaction: IHandle;
  out Properties: TTransactionProperties
): TNtxStatus;

// Commit a transaction
function NtxCommitTransaction(
  [Access(TRANSACTION_COMMIT)] const hxTransaction: IHandle;
  Wait: Boolean = True
): TNtxStatus;

// Abort a transaction
function NtxRollbackTransaction(
  [Access(TRANSACTION_ROLLBACK)] const hxTransaction: IHandle;
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
  [Access(TRANSACTION_COMMIT)] const hxTransaction: IHandle
): TNtxStatus;

// Abort a registry transaction
[MinOSVersion(OsWin10RS1)]
function NtxRollbackRegistryTransaction(
  [Access(TRANSACTION_ROLLBACK)] const hxTransaction: IHandle
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
  NtxTmTm = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] const hxTmTm: IHandle;
      InfoClass: TTransactionManagerInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Query a LOG file path for a transaction manager
function NtxQueryLogPathTmTx(
  [Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] const hxTmTx: IHandle;
  out LogPath: String
): TNtxStatus;

// --------------------------- Resource Manager ---------------------------- //

// Create a resource manager
function NtxCreateResourceManager(
  out hxTmRm: IHandle;
  [Access(TRANSACTIONMANAGER_CREATE_RM)] const hxTmTm: IHandle;
  const RmGuid: TGuid;
  CreateOptions: TTmRmCreateOptions;
  [opt] const Description: String = '';
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus; stdcall;

// Open a resource manager by a GUID
function NtxOpenResourceManager(
  out hxTmRm: IHandle;
  const RmGuid: TGuid;
  [Access(TRANSACTIONMANAGER_QUERY_INFORMATION)] const hxTmTm: IHandle;
  DesiredAccess: TTmRmAccessMask
): TNtxStatus;

// Query basic information about a resource Manager
function NtxQueryBasicTmRm(
  [Access(RESOURCEMANAGER_QUERY_INFORMATION)] const hxTmRm: IHandle;
  out BasicInfo: TResourceManagerBasicInfo
): TNtxStatus;

// ------------------------------ Enlistment ------------------------------- //

// Create an enlistment
function NtxCreateEnlistment(
  out hxTmEn: IHandle;
  [Access(RESOURCEMANAGER_ENLIST)] const hxTmRm: IHandle;
  [Access(TRANSACTION_ENLIST)] const hxTmTx: IHandle;
  CreateOptions: TTmEnCreateOptions;
  NotificationMask: TTmEnNotificationMask;
  EnlistmentKey: NativeUInt;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open an enlistment
function NtxOpenEnlistment(
  out hxTmEn: IHandle;
  const EnlistmentGuid: TGuid;
  [Access(RESOURCEMANAGER_QUERY_INFORMATION)] const hxRmHandle: IHandle;
  DesiredAccess: TTmEnAccessMask
): TNtxStatus;

type
  NtxTmEn = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(ENLISTMENT_QUERY_INFORMATION)] const hxTmEn: IHandle;
      InfoClass: TEnlistmentInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// --------------------------------- FSCTLs --------------------------------- //

// Enumerate filesystem transactions registered on a volume
function NtxEnumerateVolumeTransactions(
  [Access(FILE_READ_DATA)] const hxFileVolume: IHandle;
  out Entries: TArray<TTxfsListTransactionsEntry>
): TNtxStatus;

// Enumerate files on a volume locked by a transaction
function NtxEnumerateTransactionLockedFiles(
  [Access(FILE_READ_DATA)] const hxFileVolume: IHandle;
  const TransactionId: TGuid;
  out Entries: TArray<TTxfsLockedFile>
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, NtUtils.Ldr, NtUtils.Files.Control,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxGetNextKtmObject;
var
  Required: Cardinal;
  KtmCursor: TKtmObjectCursor;
begin
  KtmCursor := Default(TKtmObjectCursor);
  KtmCursor.LastQuery := Cursor;

  Result.Location := 'NtEnumerateTransactionObject';
  Result.LastCall.UsesInfoClass(KtmObjectType, icQuery);

  case KtmObjectType of
    KTMOBJECT_TRANSACTION:
      if Assigned(hxRootObject) then
        Result.LastCall.Expects<TTmTmAccessMask>(
          TRANSACTIONMANAGER_QUERY_INFORMATION);

    KTMOBJECT_RESOURCE_MANAGER:
      Result.LastCall.Expects<TTmTmAccessMask>(
        TRANSACTIONMANAGER_QUERY_INFORMATION);

    KTMOBJECT_ENLISTMENT:
      Result.LastCall.Expects<TTmRmAccessMask>(
        RESOURCEMANAGER_QUERY_INFORMATION);
  end;

  Result.Status := NtEnumerateTransactionObject(HandleOrDefault(hxRootObject),
    KtmObjectType, @KtmCursor, SizeOf(KtmCursor), Required);

  if not Result.IsSuccess then
    Exit;

  // The buffer has space only for one entry
  Cursor := KtmCursor.ObjectIds[0];
end;

function NtxIterateKtmObjects;
var
  Cursor: TGuid;
begin
  Cursor := Default(TGuid);

  Result := NtxAuto.Iterate<TGuid>(Status,
    function (out Entry: TGuid): TNtxStatus
    begin
      // Advance one entry
      Result := NtxGetNextKtmObject(KtmObjectType, Cursor, hxRootObject);

      if not Result.IsSuccess then
        Exit;

      Entry := Cursor;
    end
  );
end;

function NtxEnumerateKtmObjects;
var
  Cursor: TGuid;
begin
  Guids := nil;
  Cursor := Default(TGuid);

  while NtxGetNextKtmObject(KtmObjectType, Cursor,
    hxRootObject).HasEntry(Result) do
  begin
    SetLength(Guids, Succ(Length(Guids)));
    Guids[High(Guids)] := Cursor;
  end;
end;

// Transactions

type
  TCurrentTmTxHandle = class (TCustomAutoReleasable, IHandle)
    procedure Release; override;
    function GetHandle: THandle; virtual;
  end;

function TCurrentTmTxHandle.GetHandle;
begin
  // Always read the value from PEB
  Result := RtlGetCurrentTransaction;
end;

procedure TCurrentTmTxHandle.Release;
begin
  inherited;
  // No cleanup since we don't take ownership
end;

function RtlxGetCurrentTransaction;
begin
  Result := TCurrentTmTxHandle.Create;
end;

function NtxCreateTransaction;
var
  ObjAttr: PObjectAttributes;
  hTransaction: THandle;
  DescriptionStr: TNtUnicodeString;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(DescriptionStr, Description);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateTransaction';
  Result.Status := NtCreateTransaction(
    hTransaction,
    AccessMaskOverride(TRANSACTION_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
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
    HandleOrDefault(hxTmTm));

  if Result.IsSuccess then
    hxTransaction := Auto.CaptureHandle(hTransaction);
end;

class function NtxTransaction.Query<T>;
begin
  Result.Location := 'NtQueryInformationTransaction';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_QUERY_INFORMATION);

  Result.Status := NtQueryInformationTransaction(HandleOrDefault(hxTransaction),
    InfoClass, @Buffer, SizeOf(Buffer), nil);
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
    Result.Status := NtQueryInformationTransaction(
      HandleOrDefault(hxTransaction), TransactionPropertiesInformation,
      xMemory.Data, BUFFER_SIZE, @Required);
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
  Result.Status := NtCommitTransaction(HandleOrDefault(hxTransaction), Wait);
end;

function NtxRollbackTransaction;
begin
  Result.Location := 'NtRollbackTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ROLLBACK);
  Result.Status := NtRollbackTransaction(HandleOrDefault(hxTransaction), Wait);
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
  ObjAttr: PObjectAttributes;
  hTransaction: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtCreateRegistryTransaction);

  if not Result.IsSuccess then
    Exit;

  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateRegistryTransaction';
  Result.Status := NtCreateRegistryTransaction(
    hTransaction,
    AccessMaskOverride(TRANSACTION_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
    0
  );

  if Result.IsSuccess then
    hxTransaction := Auto.CaptureHandle(hTransaction);
end;

function NtxOpenRegistryTransaction;
var
  ObjAttr: PObjectAttributes;
  hTransaction: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtOpenRegistryTransaction);

  if not Result.IsSuccess then
    Exit;

  Result := AttributeBuilder(ObjectAttributes).UseName(Name).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtOpenRegistryTransaction';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.Status := NtOpenRegistryTransaction(hTransaction, DesiredAccess,
    ObjAttr^);

  if Result.IsSuccess then
    hxTransaction := Auto.CaptureHandle(hTransaction);
end;

function NtxCommitRegistryTransaction;
begin
  Result := LdrxCheckDelayedImport(delayed_NtCommitRegistryTransaction);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCommitRegistryTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_COMMIT);
  Result.Status := NtCommitRegistryTransaction(HandleOrDefault(hxTransaction),
    0);
end;

function NtxRollbackRegistryTransaction;
begin
  Result := LdrxCheckDelayedImport(delayed_NtRollbackRegistryTransaction);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtRollbackRegistryTransaction';
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ROLLBACK);
  Result.Status := NtRollbackRegistryTransaction(HandleOrDefault(hxTransaction),
    0);
end;

// Transaction Manager

function NtxCreateTransactionManager;
var
  ObjAttr: PObjectAttributes;
  hTmTm: THandle;
  LogFileNameStr: TNtUnicodeString;
begin
  Result := RtlxInitUnicodeString(LogFileNameStr, LogFileName);

  if not Result.IsSuccess then
    Exit;

  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateTransactionManager';
  Result.Status := NtCreateTransactionManager(
    hTmTm,
    AccessMaskOverride(TRANSACTIONMANAGER_ALL_ACCESS, ObjectAttributes),
    ObjAttr,
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
  Result := RtlxInitUnicodeString(LogFileNameStr, LogFileName);

  if not Result.IsSuccess then
    Exit;

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
  Result.Status := NtQueryInformationTransactionManager(HandleOrDefault(hxTmTm),
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
    Result.Status := NtQueryInformationTransactionManager(
      HandleOrDefault(hxTmTx), TransactionManagerLogPathInformation,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), Required, nil);

  if Result.IsSuccess then
    SetString(LogPath, PWideChar(@xMemory.Data.LogPath),
      xMemory.Data.LogPathLength div SizeOf(WideChar));
end;

// Resource Manager

function NtxCreateResourceManager;
var
  ObjAttr: PObjectAttributes;
  hTmRm: THandle;
  DescriptionStr: TNtUnicodeString;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(DescriptionStr, Description);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateResourceManager';
  Result.LastCall.Expects<TTmTmAccessMask>(TRANSACTIONMANAGER_CREATE_RM);
  Result.Status := NtCreateResourceManager(
    hTmRm,
    AccessMaskOverride(RESOURCEMANAGER_ALL_ACCESS, ObjectAttributes),
    HandleOrDefault(hxTmTm),
    RmGuid,
    ObjAttr,
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
    HandleOrDefault(hxTmTm),
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
    Result.Status := NtQueryInformationResourceManager(HandleOrDefault(hxTmRm),
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
  ObjAttr: PObjectAttributes;
  hTmEn: THandle;
begin
  Result := AttributesRefOrNil(ObjAttr, ObjectAttributes);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtCreateEnlistment';
  Result.LastCall.Expects<TTmRmAccessMask>(RESOURCEMANAGER_ENLIST);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ENLIST);

  Result.Status := NtCreateEnlistment(
    hTmEn,
    AccessMaskOverride(ENLISTMENT_ALL_ACCESS, ObjectAttributes),
    HandleOrDefault(hxTmRm),
    HandleOrDefault(hxTmTx),
    ObjAttr,
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
    HandleOrDefault(hxRmHandle),
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

  Result.Status := NtQueryInformationEnlistment(HandleOrDefault(hxTmEn),
    InfoClass, @Buffer, SizeOf(Buffer), nil);
end;

// FSCTLs

function RtlxpGrowTransactionsBuffer(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := PTxfsListTransactions(Memory.Data).BufferSizeRequired;
end;

function NtxEnumerateVolumeTransactions;
var
  Buffer: IMemory<PTxfsListTransactions>;
  Entry: PTxfsListTransactionsEntry;
  i: Integer;
begin
  Result := NtxFsControlFileEx(hxFileVolume,
    FSCTL_TXFS_LIST_TRANSACTIONS, IMemory(Buffer),
    SizeOf(TTxfsListTransactions), RtlxpGrowTransactionsBuffer);

  if not Result.IsSuccess then
    Exit;

  SetLength(Entries, Buffer.Data.NumberOfTransactions);
  Entry := Pointer(@Buffer.Data.Entries);

  for i := 0 to High(Entries) do
  begin
    Entries[i] := Entry^;
    Inc(Entry);
  end;
end;

function RtlxpGrowLockedFilesBuffer(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := PTxfsListTransactionLockedFiles(Memory.Data).BufferSizeRequired;
end;

function NtxEnumerateTransactionLockedFiles;
var
  Input: TTxfsListTransactionLockedFiles;
  Buffer: IMemory<PTxfsListTransactionLockedFiles>;
  Entry: PTxfsListTransactionLockedFilesEntry;
  i: Integer;
begin
  Input := Default(TTxfsListTransactionLockedFiles);
  Input.KtmTransaction := TransactionId;

  // Issue the FSCTL
  Result := NtxFsControlFileEx(hxFileVolume,
    FSCTL_TXFS_LIST_TRANSACTION_LOCKED_FILES, IMemory(Buffer),
    SizeOf(TTxfsListTransactionLockedFiles),
    RtlxpGrowLockedFilesBuffer,
    @Input, SizeOf(Input));

  if (not Result.IsSuccess) or (Buffer.Data.FirstEntryOffset = 0)  then
    Exit;

  // Save the entries
  SetLength(Entries, Buffer.Data.NumberOfFiles);
  Entry := Buffer.Offset(Buffer.Data.FirstEntryOffset);

  for i := 0 to High(Entries) do
  begin
    Entries[i].Flags := Entry.NameFlags;
    Entries[i].FileId := Entry.FileId;
    Entries[i].Name := PWideChar(@Entry.FileName[0]);
    Entry := Buffer.Offset(Entry.NextEntryOffset);
  end;
end;

end.
