unit Ntapi.ntwnf;

{
  This file includes definitions for Windows Notification Facility.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, Ntapi.ntregapi, Ntapi.Versions,
  DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  // PHNT::ntrtl.h - XOR key for decoding WNF names
  WNF_STATE_KEY = $41C64E6DA3BC0074;

  // rev - expected WNF name version
  WNF_STATE_VERSION = 1;

  // private - WNF access masks
  WNF_STATE_SUBSCRIBE = $0001;
  WNF_STATE_PUBLISH = $0002;
  WNF_STATE_CROSS_SCOPE_ACCESS = $0010;

  // rev
  WNF_STATE_GENERIC_READ = $120001;
  WNF_STATE_GENERIC_WRITE = $000002;
  WNF_STATE_GENERIC_EXECUTE = $1F0000;
  WNF_STATE_ALL_ACCESS = $1F0013;

  // rev - security descriptor and data storage
  WNF_STATE_STORAGE_WELL_KNOWN = REG_PATH_MACHINE +
    '\SYSTEM\CurrentControlSet\Control\Notifications';
  WNF_STATE_STORAGE_PERMANENT = REG_PATH_MACHINE +
    '\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Notifications';
  WNF_STATE_STORAGE_PERSISTENT = REG_PATH_MACHINE +
    '\SOFTWARE\Microsoft\Windows NT\CurrentVersion\VolatileNotifications';

  // private - known names
  WNF_FSRL_OPLOCK_BREAK = $D941D2BA3BC1075;           // TWnfFsrlOplockBreakData
  WNF_SHEL_APPLICATION_STARTED = $D83063EA3BE0075;    // PWideChar (AppId)
  WNF_SHEL_APPLICATION_TERMINATED = $D83063EA3BE0875; // PWideChar (AppId)
  WNF_WER_SERVICE_START = $41940B3AA3BC0875;          // void

type
  [FriendlyName('WNF state'), ValidMask(WNF_STATE_ALL_ACCESS)]
  [SubEnum(WNF_STATE_ALL_ACCESS, WNF_STATE_ALL_ACCESS, 'Full Access')]
  [FlagName(WNF_STATE_SUBSCRIBE, 'Subscribe')]
  [FlagName(WNF_STATE_PUBLISH, 'Publish')]
  [FlagName(WNF_STATE_CROSS_SCOPE_ACCESS, 'Cross-Scope Access')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TWnfStateAccessMask = type TAccessMask;

  // PHNT::ntexapi.h
  [SDKName('WNF_STATE_NAME')]
  TWnfStateName = type UInt64;
  PWnfStateName = ^TWnfStateName;

  // PHNT::ntexapi.h
  [SDKName('WNF_STATE_NAME_LIFETIME')]
  [NamingStyle(nsCamelCase, 'Wnf', 'StateName')]
  TWnfStateNameLifetime = (
    WnfWellKnownStateName = 0,
    WnfPermanentStateName = 1,
    WnfPersistentStateName = 2,
    WnfTemporaryStateName = 3
  );

  // PHNT::ntexapi.h
  [SDKName('WNF_DATA_SCOPE')]
  [NamingStyle(nsCamelCase, 'WnfDataScope')]
  TWnfDataScope = (
    WnfDataScopeSystem = 0,
    WnfDataScopeSession = 1,
    WnfDataScopeUser = 2,
    WnfDataScopeProcess = 3,
    WnfDataScopeMachine = 4,
    WnfDataScopePhysicalMachine = 5
  );

  // PHNT::ntexapi.h
  [SDKName('WNF_TYPE_ID')]
  TWnfTypeId = TGuid;
  PWnfTypeId = ^TWnfTypeId;

  // rev
  TWnfExplicitScope = record
  case TWnfDataScope of
    WnfDataScopeSession: (SessionId: TSessionId);
    WnfDataScopeUser:    (UserSid: PSid);
    WnfDataScopeProcess: ([Access(0)] ProcessHandle: THandle);
  end;
  PWnfExplicitScope = ^TWnfExplicitScope;

  // PHNT::ntexapi.h
  [SDKName('WNF_STATE_NAME_INFORMATION')]
  [NamingStyle(nsCamelCase, 'WnfInfo')]
  TWnfStateNameInformation = (
    WnfInfoStateNameExist = 0,     // q: LongBool
    WnfInfoSubscribersPresent = 1, // q: LongBool
    WnfInfoIsQuiescent = 2         // q: LongBool
  );

  // PHNT::ntrtl.h
  [SDKName('WNF_USER_CALLBACK')]
  TWnfUserCallback = function (
    [in] StateName: TWnfStateName;
    [in] ChangeStamp: Cardinal;
    [in, opt] TypeId: PWnfTypeId;
    [in, opt] CallbackContext: Pointer;
    [in, ReadsFrom] Buffer: Pointer;
    [in, NumberOfBytes] Length: Cardinal
  ): NTSTATUS; stdcall;

  // rev
  TWnfFsrlOplockBreakData = record
    [NumberOfElements] Count: Cardinal;
    ProcessId: TAnysizeArray<TProcessId32>;
  end;
  PWnfFsrlOplockBreakData = ^TWnfFsrlOplockBreakData;

// PHNT::ntexapi.h
[MinOSVersion(OsWin8)]
[RequiredPrivilege(SE_CREATE_PERMANENT_PRIVILEGE, rpSometimes)]
function NtCreateWnfStateName(
  [out] out StateName: TWnfStateName;
  [in] NameLifetime: TWnfStateNameLifetime;
  [in] DataScope: TWnfDataScope;
  [in] PersistData: Boolean;
  [in, opt] TypeId: PWnfTypeId;
  [in] MaximumStateSize: Cardinal;
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtCreateWnfStateName: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtCreateWnfStateName';
);

// PHNT::ntexapi.h
[MinOSVersion(OsWin8)]
function NtDeleteWnfStateName(
  [in, Access(_DELETE)] StateName: TWnfStateName
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtDeleteWnfStateName: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtDeleteWnfStateName';
);

// PHNT::ntexapi.h
[MinOSVersion(OsWin8)]
function NtUpdateWnfStateData(
  [in, Access(WNF_STATE_PUBLISH)] const [ref] StateName: TWnfStateName;
  [in, opt, ReadsFrom] Buffer: Pointer;
  [in, opt, NumberOfBytes] Length: Cardinal;
  [in, opt] TypeId: PWnfTypeId;
  [in, opt] ExplicitScope: PWnfExplicitScope;
  [in] MatchingChangeStamp: Cardinal;
  [in] CheckStamp: LongBool
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtUpdateWnfStateData: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtUpdateWnfStateData';
);

// PHNT::ntexapi.h
[MinOSVersion(OsWin8)]
function NtDeleteWnfStateData(
  [in, Access(WNF_STATE_PUBLISH)] const [ref] StateName: TWnfStateName;
  [in, opt] ExplicitScope: PWnfExplicitScope
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtDeleteWnfStateData: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtDeleteWnfStateData';
);

// PHNT::ntexapi.h
[MinOSVersion(OsWin8)]
function NtQueryWnfStateData(
  [in, Access(WNF_STATE_SUBSCRIBE)] const [ref] StateName: TWnfStateName;
  [in, opt] TypeId: PWnfTypeId;
  [in, opt] ExplicitScope: PWnfExplicitScope;
  [out] out ChangeStamp: Cardinal;
  [out, WritesTo] Buffer: Pointer;
  [in, out] var BufferLength: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtQueryWnfStateData: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtQueryWnfStateData';
);

// PHNT::ntexapi.h
[MinOSVersion(OsWin8)]
function NtQueryWnfStateNameInformation(
  [in, Access(WNF_STATE_SUBSCRIBE)] const [ref] StateName: TWnfStateName;
  [in] NameInfoClass: TWnfStateNameInformation;
  [in, opt] ExplicitScope: PWnfExplicitScope;
  [out, WritesTo] Buffer: Pointer;
  [in] BufferLength: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtQueryWnfStateNameInformation: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'NtQueryWnfStateNameInformation';
);

// PHNT::ntrtl.h
[MinOSVersion(OsWin8)]
function RtlSubscribeWnfStateChangeNotification(
  [out, ReleaseWith('RtlUnsubscribeWnfStateChangeNotification')]
    out Subscription: THandle;
  [in, Access(WNF_STATE_SUBSCRIBE)] StateName: TWnfStateName;
  [in] ChangeStamp: Cardinal;
  [in] Callback: TWnfUserCallback;
  [in, opt] CallbackContext: Pointer;
  [in, opt] TypeId: PWnfTypeId;
  [in, opt] SerializationGroup: Cardinal;
  [in] DeliveryOptions: Cardinal
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_RtlSubscribeWnfStateChangeNotification: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'RtlSubscribeWnfStateChangeNotification';
);

// PHNT::ntrtl.h
[MinOSVersion(OsWin8)]
function RtlUnsubscribeWnfStateChangeNotification(
  [in] Subscription: THandle
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_RtlUnsubscribeWnfStateChangeNotification: TDelayedLoadFunction = (
  Dll: @delayed_ntdll;
  FunctionName: 'RtlUnsubscribeWnfStateChangeNotification';
);

// Macros

function WNF_EXTRACT_VERSION(
  const StateName: TWnfStateName
): Cardinal;

function WNF_EXTRACT_LIFETIME(
  const StateName: TWnfStateName
): TWnfStateNameLifetime;

function WNF_EXTRACT_SCOPE(
  const StateName: TWnfStateName
): TWnfDataScope;

function WNF_EXTRACT_PERMANENT_DATA(
  const StateName: TWnfStateName
): Boolean;

function WNF_EXTRACT_UNIQUE(
  const StateName: TWnfStateName
): UInt64;

function WNF_EXTRACT_FAMILY(
  const StateName: TWnfStateName
): Cardinal;

function WNF_EXTRACT_FAMILY_UNIQUE(
  const StateName: TWnfStateName
): Cardinal;

implementation

function WNF_EXTRACT_VERSION;
begin
  Result := (StateName xor WNF_STATE_KEY) and $F;
end;

function WNF_EXTRACT_LIFETIME;
begin
  Result := TWnfStateNameLifetime(((StateName xor WNF_STATE_KEY) shr 4) and $3);
end;

function WNF_EXTRACT_SCOPE;
begin
  Result := TWnfDataScope(((StateName xor WNF_STATE_KEY) shr 6) and $F);
end;

function WNF_EXTRACT_PERMANENT_DATA;
begin
  Result := Boolean(((StateName xor WNF_STATE_KEY) shr 10) and $1);
end;

function WNF_EXTRACT_UNIQUE;
begin
  Result := (StateName xor WNF_STATE_KEY) shr 11;
end;

function WNF_EXTRACT_FAMILY;
begin
  Result := Cardinal((StateName xor WNF_STATE_KEY) shr 32);
end;

function WNF_EXTRACT_FAMILY_UNIQUE;
begin
  Result := Cardinal(((StateName xor WNF_STATE_KEY) shr 11) and $1FFFFF);
end;

end.
