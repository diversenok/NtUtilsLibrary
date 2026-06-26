unit Ntapi.biapi;

{
  This module provides definitions for Background Broker Infrastructure APIs.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntwnf, Ntapi.ntseapi, Ntapi.Versions,
  DelphiApi.DelayLoad, DelphiApi.Reflection;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

const
  // twinapi.dll on Win 8; twinapi.appcore.dll on Win 8.1+
  apiset_biptcltapi = 'api-ms-win-core-biptcltapi-l1-1-0.dll';
  bi = 'bi.dll';

var
  delayed_apiset_biptcltapi: TDelayedLoadDll = (DllName: apiset_biptcltapi);
  delayed_bi: TDelayedLoadDll = (DllName: bi);

type
  // private
  [SDKName('BI_WORK_ITEM_ACTIVATION_TYPE')]
  TBiWorkItemActivationType = (
    ApplicationObjectExtension = 0,
    ActivationProxy = 1,
    ActivationWin32Clsid = 2, // Win 10 20H1+
    ActivationSuspendableWin32Clsid = 3 // Win 11 21H2+
  );

  // private - before RS3
  [SDKName('BI_BROKERED_WORK_ITEM')]
  TBiBrokeredWorkItemV1 = record
    TriggerEventId: TGuid;
    WorkItemId: TGuid;
    StatusStateName: TWnfStateName;
    ActivationType: TBiWorkItemActivationType;
    [Offset] NameOffset: Cardinal;
    [NumberOfBytes] NameLength: Cardinal;
    [Hex] WorkItemFlags: Cardinal;
    [Offset] ActivationInformationOffset: Cardinal;
    [NumberOfBytes] ActivationInformationLength: Cardinal;
    [NumberOfElements] NumberOfConditionals: Cardinal;
    [Offset] ConditionalEventIdsOffset: Cardinal;
    [Offset] ConditionalEventDesiredValuesOffset: Cardinal;
  end;
  PBiBrokeredWorkItemV1 = ^TBiBrokeredWorkItemV1;

  // private
  [SDKName('BI_BROKERED_WORK_ITEM')]
  TBiBrokeredWorkItem = record
    TriggerEventId: TGuid;
    WorkItemId: TGuid;
    StatusStateName: TWnfStateName;
    ActivationType: TBiWorkItemActivationType;
    [MinOSVersion(OsWin10RS3), Reserved] Padding: Cardinal;
    [MinOSVersion(OsWin10RS3), Hex] HostId: UInt64;
    [MinOSVersion(OsWin10RS3), Hex] TypeId: Cardinal;
    [Offset] NameOffset: Cardinal;
    [NumberOfBytes] NameLength: Cardinal;
    [Hex] WorkItemFlags: Cardinal;
    [Offset] ActivationInformationOffset: Cardinal;
    [NumberOfBytes] ActivationInformationLength: Cardinal;
    [NumberOfElements] NumberOfConditionals: Cardinal;
    [Offset] ConditionalEventIdsOffset: Cardinal;
    [Offset] ConditionalEventDesiredValuesOffset: Cardinal;
  end;
  PBiBrokeredWorkItem = ^TBiBrokeredWorkItem;

  // private
  [SDKName('BI_BROKERED_EVENT')]
  TBiBrokeredEvent = record
    BrokerId: TGuid;
    EventId: TGuid;
    [Hex] EventFlags: Cardinal;
    [Offset] PackageFullNameOffset: Cardinal;
    [Offset] UserSidOffset: Cardinal;
    [Offset] EventInformationOffset: Cardinal;
    [NumberOfBytes] EventInformationSize: Cardinal;
    AssociatedWorkItemCount: Cardinal;
  end;
  PBiBrokeredEvent = ^TBiBrokeredEvent;

  // private
  [SDKName('BI_BROADCAST_CHANNEL_NAME')]
  [NamingStyle(nsCamelCase, 'Channel')]
  TBiBroadcastChannelName = (
    ChannelUserLogOn = 0,
    ChannelUserLogOff = 1,
    ChannelSessionConnect = 2,
    ChannelSessionDisconnect = 3,
    ChannelApplicationUninstall = 4,
    ChannelApplicationServicingStart = 5,
    ChannelApplicationServicingStop = 6,
    ChannelLockScreenUpdate = 7,
    ChannelEventDeletion = 8,
    ChannelQuietModeUpdate = 9,    // Win 8.1+
    ChannelNotifyNewSession = 10,  // Win 8.1+
    ChannelNotifyCloseSession = 11 // Win 8.1+
  );

  // private
  [SDKName('BI_BROADCAST_CHANNELS')]
  TBiBroadcastChannels = array [TBiBroadcastChannelName] of TWnfStateName;

{ Partial trust APIs }

// private
[MinOSVersion(OsWin8)]
procedure BiPtFreeMemory(
  [in] Memory: Pointer
); stdcall external apiset_biptcltapi delayed;

var delayed_BiPtFreeMemory: TDelayedLoadFunction = (
  Dll: @delayed_apiset_biptcltapi;
  FunctionName: 'BiPtFreeMemory';
);

// private
[MinOSVersion(OsWin8)]
function BiPtEnumerateWorkItemsForPackageName(
  [in] const PackageFullName: TNtUnicodeString;
  [in] ExclusionFlags: Cardinal;
  [out, NumberOfElements] out NumberOfWorkItems: Integer;
  [out, ReleaseWith('BiPtFreeMemory')] out WorkItems: PGuid
): NTSTATUS; stdcall external apiset_biptcltapi delayed;

var delayed_BiPtEnumerateWorkItemsForPackageName: TDelayedLoadFunction = (
  Dll: @delayed_apiset_biptcltapi;
  FunctionName: 'BiPtEnumerateWorkItemsForPackageName';
);

// private
[MinOSVersion(OsWin8)]
function BiPtQueryWorkItem(
  [in] const WorkItemId: TGuid;
  [out] out WorkItemSize: Cardinal;
  [out, ReleaseWith('BiPtFreeMemory')] out WorkItem: PBiBrokeredWorkItem
): NTSTATUS; stdcall external apiset_biptcltapi delayed;

var delayed_BiPtQueryWorkItem: TDelayedLoadFunction = (
  Dll: @delayed_apiset_biptcltapi;
  FunctionName: 'BiPtQueryWorkItem';
);

// private
[MinOSVersion(OsWin10RS1)]
function BiPtQueryWorkItemStatusStateName(
  [in] const WorkItemId: TGuid;
  [out] out StateName: TWnfStateName
): NTSTATUS; stdcall external apiset_biptcltapi;

var delayed_BiPtQueryWorkItemStatusStateName: TDelayedLoadFunction = (
  Dll: @delayed_apiset_biptcltapi;
  FunctionName: 'BiPtQueryWorkItemStatusStateName';
);

// private
[MinOSVersion(OsWin8)]
function BiPtQueryBrokeredEvent(
  [in] const EventId: TGuid;
  [out] out BrokeredEventSize: Cardinal;
  [out, ReleaseWith('BiPtFreeMemory')] out BrokeredEvent: PBiBrokeredEvent
): NTSTATUS; stdcall external apiset_biptcltapi delayed;

var delayed_BiPtQueryBrokeredEvent: TDelayedLoadFunction = (
  Dll: @delayed_apiset_biptcltapi;
  FunctionName: 'BiPtQueryBrokeredEvent';
);

// private
[MinOSVersion(OsWin8)]
function BiPtEnumerateBrokeredEvents(
  [in] const BrokerId: TGuid;
  [out, NumberOfElements] out NumberOfEvents: Integer;
  [out, ReleaseWith('BiPtFreeMemory')] out BrokeredEvents: PGuid
): NTSTATUS; stdcall external apiset_biptcltapi delayed;

var delayed_BiPtEnumerateBrokeredEvents: TDelayedLoadFunction = (
  Dll: @delayed_apiset_biptcltapi;
  FunctionName: 'BiPtEnumerateBrokeredEvents';
);

// private
[MinOSVersion(OsWin10TH1)]
function BiPtEnumerateBrokeredEventsEx(
  [in] const BrokerId: TGuid;
  [in, opt] PackageFullName: PNtUnicodeString;
  [in] BrokerEventType: Cardinal;
  [out, NumberOfElements] out NumberOfEvents: Integer;
  [out, ReleaseWith('BiPtFreeMemory')] out BrokeredEvents: PGuid
): NTSTATUS; stdcall external apiset_biptcltapi delayed;

var delayed_BiPtEnumerateBrokeredEventsEx: TDelayedLoadFunction = (
  Dll: @delayed_apiset_biptcltapi;
  FunctionName: 'BiPtEnumerateBrokeredEventsEx';
);

// private
[MinOSVersion(OsWin8)]
function BiPtQuerySystemStateBroadcastChannels(
  [out] out BroadcastChannels: TBiBroadcastChannels
): NTSTATUS; stdcall external apiset_biptcltapi delayed;

var delayed_BiPtQuerySystemStateBroadcastChannels: TDelayedLoadFunction = (
  Dll: @delayed_apiset_biptcltapi;
  FunctionName: 'BiPtQuerySystemStateBroadcastChannels';
);

{ Full trust APIs }

// private
[RequiresSystem]
[MinOSVersion(OsWin8)]
procedure BiFreeMemory(
  [in] Memory: Pointer
); stdcall external bi delayed;

var delayed_BiFreeMemory: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiFreeMemory';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BiEnumerateWorkItemsForPackageName(
  [in] const PackageFullName: TNtUnicodeString;
  [in] UserSid: PSid;
  [in] ExclusionFlags: Cardinal;
  [out, NumberOfElements] out NumberOfWorkItems: Integer;
  [out, ReleaseWith('BiFreeMemory')] out WorkItems: PGuid
): NTSTATUS; stdcall external bi delayed;

var delayed_BiEnumerateWorkItemsForPackageName: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiEnumerateWorkItemsForPackageName';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BiQueryWorkItem(
  [in] const WorkItemId: TGuid;
  [out] out BufferSize: Cardinal;
  [out, ReleaseWith('BiFreeMemory')] out WorkItem: PBiBrokeredWorkItem
): NTSTATUS; stdcall external bi delayed;

var delayed_BiQueryWorkItem: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiQueryWorkItem';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin10RS1)]
function BiQueryWorkItemStatusStateName(
  [in] const WorkItemId: TGuid;
  [out] out StateName: TWnfStateName
): NTSTATUS; stdcall external bi delayed;

var delayed_BiQueryWorkItemStatusStateName: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiQueryWorkItemStatusStateName';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BiQueryBrokeredEvent(
  [in] const EventId: TGuid;
  [out] out BufferSize: Cardinal;
  [out, ReleaseWith('BiFreeMemory')] out BrokeredEvent: PBiBrokeredEvent
): NTSTATUS; stdcall external bi delayed;

var delayed_BiQueryBrokeredEvent: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiQueryBrokeredEvent';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BiEnumerateBrokeredEvents(
  [in] const BrokerId: TGuid;
  [out, NumberOfElements] out NumberOfEvents: Integer;
  [out, ReleaseWith('BiFreeMemory')] out BrokeredEvents: PGuid
): NTSTATUS; stdcall external bi delayed;

var delayed_BiEnumerateBrokeredEvents: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiEnumerateBrokeredEvents';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BiQuerySystemStateBroadcastChannels(
  [out] out BroadcastChannels: TBiBroadcastChannels
): NTSTATUS; stdcall external bi delayed;

var delayed_BiQuerySystemStateBroadcastChannels: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiQuerySystemStateBroadcastChannels';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BiEnumerateUserSessions(
  [out, NumberOfElements] out NumberOfSessions: Integer;
  [out, ReleaseWith('BiFreeMemory')] out SessionIdList: PSessionId
): NTSTATUS; stdcall external bi delayed;

var delayed_BiEnumerateUserSessions: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiEnumerateUserSessions';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin10TH1)]
function BiEnumerateUserContexts(
  [out, NumberOfElements] out NumberOfUserContexts: Integer;
  [out, ReleaseWith('BiFreeMemory')] out UserContextIdList: PLuid
): NTSTATUS; stdcall external bi delayed;

var delayed_BiEnumerateUserContexts: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiEnumerateUserContexts';
);

// private
[RequiresSystem]
[MinOSVersion(OsWin10TH1)]
function BiQueryUserContext(
  [in] UserContextId: TLuid;
  [out] out SessionId: TSessionId;
  [out, ReleaseWith('BiFreeMemory')] out UserSid: PSid
): NTSTATUS; stdcall external bi delayed;

var delayed_BiQueryUserContext: TDelayedLoadFunction = (
  Dll: @delayed_bi;
  FunctionName: 'BiQueryUserContext';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
