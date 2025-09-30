unit NtUtils.Wnf;

{
  This module provides functions for working Windows Notification Facility.
}

interface

uses
  Ntapi.ntwnf, Ntapi.ntseapi, Ntapi.ntregapi, Ntapi.Versions,
  DelphiApi.Reflection, NtUtils;

type
  TRtlxWnfCallback = reference to procedure (
    const StateName: TWnfStateName;
    const Buffer: TMemory;
    ChangeStamp: Cardinal;
    [in, opt] TypeId: PWnfTypeId
  );

  NtxWnfState = class abstract
    // Query fixed-size WNF state data
    class function QueryData<T>(
      [Access(WNF_STATE_SUBSCRIBE)] const StateName: TWnfStateName;
      out Buffer: T;
      [opt] NameHint: String = '';
      [opt] TypeId: PWnfTypeId = nil;
      [opt, RequiredPrivilege(SE_TCB_PRIVILEGE, rpWithExceptions)]
        ExplicitScope: PWnfExplicitScope = nil;
      [out] ChangeStamp: PCardinal = nil
    ): TNtxStatus; static;

    // Update WNF state data with fixed buffer
    class function UpdateData<T>(
      [Access(WNF_STATE_PUBLISH)] const StateName: TWnfStateName;
      const Buffer: T;
      [opt] NameHint: String = '';
      [opt] TypeId: PWnfTypeId = nil;
      [opt, RequiredPrivilege(SE_TCB_PRIVILEGE, rpWithExceptions)]
        ExplicitScope: PWnfExplicitScope = nil;
      [opt] ChangeStampToMatch: PCardinal = nil
    ): TNtxStatus; static;

    // Query WNF name Information
    class function Query<T>(
      [Access(WNF_STATE_SUBSCRIBE)] const StateName: TWnfStateName;
      InfoClass: TWnfStateNameInformation;
      out Buffer: T;
      [opt] NameHint: String = '';
      [opt, RequiredPrivilege(SE_TCB_PRIVILEGE, rpWithExceptions)]
        ExplicitScope: PWnfExplicitScope = nil
    ): TNtxStatus; static;
  end;

// Query variable-size WNF state data
[MinOSVersion(OsWin8)]
function NtxQueryWnfStateData(
  [Access(WNF_STATE_SUBSCRIBE)] const StateName: TWnfStateName;
  out Buffer: IMemory;
  InitialBufferSize: Cardinal = 0;
  [opt] NameHint: String = '';
  [opt] TypeId: PWnfTypeId = nil;
  [opt, RequiredPrivilege(SE_TCB_PRIVILEGE, rpWithExceptions)]
    ExplicitScope: PWnfExplicitScope = nil;
  [out] ChangeStamp: PCardinal = nil
): TNtxStatus;

// Update data associated with a WNF state name
[MinOSVersion(OsWin8)]
function NtxUpdateWnfStateData(
  [Access(WNF_STATE_PUBLISH)] const StateName: TWnfStateName;
  [ReadsFrom] Buffer: Pointer = nil;
  Length: Cardinal = 0;
  [opt] NameHint: String = '';
  [opt] TypeId: PWnfTypeId = nil;
  [opt, RequiredPrivilege(SE_TCB_PRIVILEGE, rpWithExceptions)]
    ExplicitScope: PWnfExplicitScope = nil;
  [opt] ChangeStampToMatch: PCardinal = nil
): TNtxStatus;

[MinOSVersion(OsWin8)]
function NtxDeleteWnfStateData(
  [Access(WNF_STATE_PUBLISH)] const StateName: TWnfStateName;
  [opt] NameHint: String = '';
  [opt] ExplicitScope: PWnfExplicitScope = nil
): TNtxStatus;

// Subscribe to notifications about changes of a WNF state
[MinOSVersion(OsWin8)]
function RtlxSubscribeWnfStateChange(
  out Registration: IDiscardableResource;
  const StateName: TWnfStateName;
  Callback: TRtlxWnfCallback;
  [opt] NameHint: String = '';
  [opt] TypeId: PWnfTypeId = nil;
  [in] ChangeStamp: Cardinal = 0
): TNtxStatus;

// Open a registry storage for WNF security descriptors
function NtxOpenWnfSecurityKey(
  out hxKey: IHandle;
  Lifetime: TWnfStateNameLifetime;
  DesiredAccess: TRegKeyAccessMask
): TNtxStatus;

// Query a security descriptor of a well-known WNF state name
function NtxQueryWnfStateSecurity(
  out SD: ISecurityDescriptor;
  const StateName: TWnfStateName;
  [opt] hxSecurityDescrptorKey: IHandle = nil
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Ldr, Ntapi.ntrtl,
  NtUtils.Registry, NtUtils.SysUtils, DelphiUtils.AutoObjects,
  DelphiUtils.AutoEvents;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

class function NtxWnfState.Query<T>;
begin
  Result := LdrxCheckDelayedImport(delayed_NtQueryWnfStateNameInformation);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtQueryWnfStateNameInformation';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Parameter := NameHint;
  Result.Status := NtQueryWnfStateNameInformation(StateName, InfoClass,
    ExplicitScope, @Buffer, SizeOf(Buffer));
end;

class function NtxWnfState.QueryData<T>;
var
  ChangeStampValue, BufferSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtQueryWnfStateData);

  if not Result.IsSuccess then
    Exit;

  BufferSize := SizeOf(Buffer);
  Result.Location := 'NtQueryWnfStateData';
  Result.LastCall.Parameter := NameHint;
  Result.Status := NtQueryWnfStateData(StateName, TypeId, ExplicitScope,
    ChangeStampValue, @Buffer, BufferSize);

  if Result.IsSuccess and Assigned(ChangeStamp) then
    ChangeStamp^ := ChangeStampValue;
end;

class function NtxWnfState.UpdateData<T>;
var
  ChangeStamp: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUpdateWnfStateData);

  if not Result.IsSuccess then
    Exit;

  if Assigned(ChangeStampToMatch) then
    ChangeStamp := ChangeStampToMatch^
  else
    ChangeStamp := 0;

  Result.Location := 'NtUpdateWnfStateData';
  Result.LastCall.Parameter := NameHint;
  Result.Status := NtUpdateWnfStateData(StateName, @Buffer, SizeOf(Buffer),
    TypeId, ExplicitScope, ChangeStamp, Assigned(ChangeStampToMatch));
end;

function NtxQueryWnfStateData;
var
  ChangeStampValue: Cardinal;
  BufferSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtQueryWnfStateData);

  if not Result.IsSuccess then
    Exit;

  Buffer := Auto.AllocateDynamic(InitialBufferSize);
  Result.Location := 'NtQueryWnfStateData';
  Result.LastCall.Parameter := NameHint;

  repeat
    BufferSize := Buffer.Size;
    Result.Status := NtQueryWnfStateData(StateName, TypeId, ExplicitScope,
      ChangeStampValue, Buffer.Data, BufferSize);
  until not NtxExpandBufferEx(Result, Buffer, BufferSize, nil);

  if Result.IsSuccess and Assigned(ChangeStamp) then
    ChangeStamp^ := ChangeStampValue;
end;

function NtxUpdateWnfStateData;
var
  ChangeStamp: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUpdateWnfStateData);

  if not Result.IsSuccess then
    Exit;

  if Assigned(ChangeStampToMatch) then
    ChangeStamp := ChangeStampToMatch^
  else
    ChangeStamp := 0;

  Result.Location := 'NtUpdateWnfStateData';
  Result.LastCall.Parameter := NameHint;
  Result.Status := NtUpdateWnfStateData(StateName, Buffer, Length, TypeId,
    ExplicitScope, ChangeStamp, Assigned(ChangeStampToMatch));
end;

function NtxDeleteWnfStateData;
begin
  Result := LdrxCheckDelayedImport(delayed_NtDeleteWnfStateData);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtDeleteWnfStateData';
  Result.LastCall.Parameter := NameHint;
  Result.Status := NtDeleteWnfStateData(StateName, ExplicitScope);
end;

type
  TAutoWnfNotification = class (TDiscardableResource, IDiscardableResource)
    FSubscription: THandle;
    FCookie: NativeUInt;
    constructor Capture(Subscription: THandle; Cookie: NativeUInt);
    destructor Destroy; override;
  end;

constructor TAutoWnfNotification.Capture;
begin
  inherited Create;
  FSubscription := Subscription;
  FCookie := Cookie;
end;

destructor TAutoWnfNotification.Destroy;
begin
  if not FDiscardOwnership then
  begin
    if FCookie <> 0 then
      TInterfaceTable.Remove(FCookie);

    if (FSubscription <> 0) and LdrxCheckDelayedImport(
      delayed_RtlUnsubscribeWnfStateChangeNotification).IsSuccess then
      RtlUnsubscribeWnfStateChangeNotification(FSubscription);
  end;

  FCookie := 0;
  FSubscription := 0;
  inherited;
end;

function RtlxWnfStateChangeNotificationDispatcher(
  [in] StateName: TWnfStateName;
  [in] ChangeStamp: Cardinal;
  [in, opt] TypeId: PWnfTypeId;
  [in, opt] CallbackContext: Pointer;
  [in, ReadsFrom] Buffer: Pointer;
  [in, NumberOfBytes] Length: Cardinal
): NTSTATUS; stdcall;
var
  CallbackCookie: NativeUInt absolute CallbackContext;
  Callback: TRtlxWnfCallback;
  BufferRange: TMemory;
begin
  if TInterfaceTable.Find(CallbackCookie, Callback) then
  try
    BufferRange.Address := Buffer;
    BufferRange.Size := Length;

    Callback(StateName, BufferRange, ChangeStamp, TypeId);
  except
    on E: TObject do
      if not Assigned(AutoExceptionHanlder) or not AutoExceptionHanlder(E) then
        raise;
  end;

  Result := STATUS_SUCCESS;
end;

function RtlxSubscribeWnfStateChange;
var
  hSubscripton: THandle;
  CallbackIntf: IInterface absolute Callback;
  Cookie: NativeUInt;
begin
  Result := LdrxCheckDelayedImport(
    delayed_RtlSubscribeWnfStateChangeNotification);

  if not Result.IsSuccess then
    Exit;

  Cookie := TInterfaceTable.Add(CallbackIntf);

  Result.Location := 'RtlSubscribeWnfStateChangeNotification';
  Result.Status := RtlSubscribeWnfStateChangeNotification(hSubscripton,
    StateName, ChangeStamp, RtlxWnfStateChangeNotificationDispatcher,
    Pointer(Cookie), TypeId, 0, 0);

  if not Result.IsSuccess then
  begin
    TInterfaceTable.Remove(Cookie);
    Exit;
  end;

  Registration := TAutoWnfNotification.Capture(hSubscripton, Cookie);
end;

function NtxOpenWnfSecurityKey;
var
  KeyName: String;
begin
  case Lifetime of
    WnfWellKnownStateName:  KeyName := WNF_STATE_STORAGE_WELL_KNOWN;
    WnfPermanentStateName:  KeyName := WNF_STATE_STORAGE_PERMANENT;
    WnfPersistentStateName: KeyName := WNF_STATE_STORAGE_PERSISTENT;
  else
    Result.Location := 'NtxOpenWnfSecurityKey';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result := NtxOpenKey(hxKey, KeyName, DesiredAccess);
end;

function NtxQueryWnfStateSecurity;
var
  Value: TNtxRegValue;
begin
  // Verify the state name version
  if WNF_EXTRACT_VERSION(StateName) <> WNF_STATE_VERSION then
  begin
    Result.Location := 'NtxQueryWnfStateSecurity';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Open the storage key if necessary
  if not Assigned(hxSecurityDescrptorKey) then
  begin
    Result := NtxOpenWnfSecurityKey(hxSecurityDescrptorKey,
      WNF_EXTRACT_LIFETIME(StateName), KEY_QUERY_VALUE);

    if not Result.IsSuccess then
      Exit;
  end;

  // Read the security descriptor value
  Result := NtxQueryValueKey(hxSecurityDescrptorKey,
    RtlxIntToHex(StateName, 16, False), Value);

  if not Result.IsSuccess then
    Exit;

  // Validate
  if Assigned(Value.Data) and RtlValidRelativeSecurityDescriptor(
    Value.Data.Data, Value.Data.Size, DACL_SECURITY_INFORMATION) then
    SD := ISecurityDescriptor(Value.Data)
  else
  begin
    Result.Location := 'NtxQueryWnfStateSecurity';
    Result.Status := STATUS_INVALID_SECURITY_DESCR;
  end;
end;

end.
