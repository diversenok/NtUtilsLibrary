unit NtUtils.BrokerInfra;

{
  This module provides support for querying information about
  Background Broker Infrastructure.
}

interface

uses
  Ntapi.ntwnf, Ntapi.biapi, Ntapi.ntseapi, NtUtils, Ntapi.Versions,
  DelphiApi.Reflection;

type
  TBixBrokeredWorkItem = record
    TriggerEventId: TGuid;
    WorkItemId: TGuid;
    StatusStateName: TWnfStateName;
    ActivationType: TBiWorkItemActivationType;
    [MinOSVersion(OsWin10RS3), Hex] HostId: UInt64;
    [MinOSVersion(OsWin10RS3), Hex] TypeId: Cardinal;
    Name: String;
    [Hex] WorkItemFlags: Cardinal;
  end;

  TBixBrokeredEvent = record
    BrokerId: TGuid;
    EventId: TGuid;
    [Hex] EventFlags: Cardinal;
    PackageFullName: String;
    UserSid: ISid;
    AssociatedWorkItemCount: Cardinal;
  end;

{ Partial trust APIs }

// Enumerate work items of a package of the current user
[MinOSVersion(OsWin8)]
function BixPartialTrustEnumeratePackageWorkItems(
  const PackageFullName: String;
  out WorkItems: TArray<TGuid>
): TNtxStatus;

// Query information about a work item
[MinOSVersion(OsWin8)]
function BixPartialTrustQueryWorkItem(
  const WorkItemId: TGuid;
  out Info: TBixBrokeredWorkItem
): TNtxStatus;

// Query information about a brokered event
[MinOSVersion(OsWin8)]
function BixPartialTrustQueryBrokeredEvent(
  const EventId: TGuid;
  out Info: TBixBrokeredEvent
): TNtxStatus;

// Enumerate event IDs for a broker
[MinOSVersion(OsWin8)]
function BixPartialTrustEnumerateBrokeredEvents(
  const BrokerId: TGuid;
  out BrokeredEvents: TArray<TGuid>
): TNtxStatus;

// Query WNF names for system broadcast channels
[MinOSVersion(OsWin8)]
function BixPartialTrustQueryBroadcastChannels(
  out BroadcastChannels: TBiBroadcastChannels
): TNtxStatus;

{ Full trust APIs }

// Enumerate work items of a package of any user
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BixFullTrustEnumeratePackageWorkItems(
  const PackageFullName: String;
  const UserSid: ISid;
  out WorkItems: TArray<TGuid>
): TNtxStatus;

// Query information about a work item
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BixFullTrustQueryWorkItem(
  const WorkItemId: TGuid;
  out Info: TBixBrokeredWorkItem
): TNtxStatus;

// Query information about a brokered event
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BixFullTrustQueryBrokeredEvent(
  const EventId: TGuid;
  out Info: TBixBrokeredEvent
): TNtxStatus;

// Enumerate event IDs for a broker
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BixFullTrustEnumerateBrokeredEvents(
  const BrokerId: TGuid;
  out BrokeredEvents: TArray<TGuid>
): TNtxStatus;

// Query WNF names for system broadcast channels
[RequiresSystem]
[MinOSVersion(OsWin8)]
function BixFullTrustQueryBroadcastChannels(
  out BroadcastChannels: TBiBroadcastChannels
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, NtUtils.Ldr, NtUtils.SysUtils, NtUtils.Security.Sid;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Shared }

procedure BixpCaptureWorkItemInfo(
  Buffer: PBiBrokeredWorkItem;
  BufferSize: Cardinal;
  out Info: TBixBrokeredWorkItem
);
var
  BufferV1: PBiBrokeredWorkItemV1 absolute Buffer;
begin
  if RtlOsVersionAtLeast(OsWin10RS3) then
  begin
    Info.TriggerEventId := Buffer.TriggerEventId;
    Info.WorkItemId := Buffer.WorkItemId;
    Info.StatusStateName := Buffer.StatusStateName;
    Info.ActivationType := Buffer.ActivationType;
    Info.WorkItemFlags := Buffer.WorkItemFlags;
    Info.HostId := Buffer.HostId;
    Info.TypeId := Buffer.TypeId;
    Info.Name := RtlxCaptureStringFromOffset(Buffer, BufferSize,
      Buffer.NameOffset, Buffer.NameLength div SizeOf(WideChar));
  end
  else
  begin
    Info.TriggerEventId := BufferV1.TriggerEventId;
    Info.WorkItemId := BufferV1.WorkItemId;
    Info.StatusStateName := BufferV1.StatusStateName;
    Info.ActivationType := BufferV1.ActivationType;
    Info.WorkItemFlags := BufferV1.WorkItemFlags;
    Info.HostId := 0;
    Info.TypeId := 0;
    Info.Name := RtlxCaptureStringFromOffset(BufferV1, BufferSize,
      BufferV1.NameOffset, BufferV1.NameLength div SizeOf(WideChar));
  end;
end;

function BixpCaptureBrokeredEventInfo(
  Buffer: PBiBrokeredEvent;
  out Info: TBixBrokeredEvent
): TNtxStatus;
begin
  Info.BrokerId := Buffer.BrokerId;
  Info.EventId := Buffer.EventId;
  Info.EventFlags := Buffer.EventFlags;
  Info.AssociatedWorkItemCount := Buffer.AssociatedWorkItemCount;
  Info.PackageFullName := String(PWideChar(PByte(Buffer) +
    Buffer.PackageFullNameOffset));
  Result := RtlxCopySid(Pointer(PByte(Buffer) + Buffer.UserSidOffset),
    Info.UserSid);
end;

{ Partial trust APIs }

function DeferBiPtFreeMemory(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Defer(
    procedure
    begin
      if LdrxCheckDelayedImport(delayed_BiPtFreeMemory).IsSuccess then
        BiPtFreeMemory(Buffer);
    end
  );
end;

function BixPartialTrustEnumeratePackageWorkItems;
var
  PackageFullNameStr: TNtUnicodeString;
  i, Count: Integer;
  Buffer, Cursor: PGuid;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_BiPtEnumerateWorkItemsForPackageName);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(PackageFullNameStr, PackageFullName);

  if not Result.IsSuccess then
    Exit;

  Count := 0;
  Buffer := nil;
  Result.Location := 'BiPtEnumerateWorkItemsForPackageName';
  Result.Status := BiPtEnumerateWorkItemsForPackageName(PackageFullNameStr, 0,
    Count, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferBiPtFreeMemory(Buffer);
  SetLength(WorkItems, Count);
  Cursor := Buffer;

  for i := 0 to High(WorkItems) do
  begin
    WorkItems[i] := Cursor^;
    Inc(Cursor)
  end;
end;

function BixPartialTrustQueryWorkItem;
var
  BufferSize: Cardinal;
  Buffer: PBiBrokeredWorkItem;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_BiPtQueryWorkItem);

  if not Result.IsSuccess then
    Exit;

  BufferSize := 0;
  Buffer := nil;
  Result.Location := 'BiPtQueryWorkItem';
  Result.Status := BiPtQueryWorkItem(WorkItemId, BufferSize, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferBiPtFreeMemory(Buffer);
  BixpCaptureWorkItemInfo(Buffer, BufferSize, Info);
end;

function BixPartialTrustQueryBrokeredEvent;
var
  BufferSize: Cardinal;
  Buffer: PBiBrokeredEvent;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_BiPtQueryBrokeredEvent);

  if not Result.IsSuccess then
    Exit;

  BufferSize := 0;
  Buffer := nil;
  Result.Location := 'BiPtQueryBrokeredEvent';
  Result.Status := BiPtQueryBrokeredEvent(EventId, BufferSize, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferBiPtFreeMemory(Buffer);
  Result := BixpCaptureBrokeredEventInfo(Buffer, Info);
end;

function BixPartialTrustEnumerateBrokeredEvents;
var
  Count: Integer;
  Buffer, Cursor: PGuid;
  BufferDeallocator: IAutoReleasable;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_BiPtEnumerateBrokeredEvents);

  if not Result.IsSuccess then
    Exit;

  Count := 0;
  Buffer := nil;
  Result.Location := 'BiPtEnumerateBrokeredEvents';
  Result.Status := BiPtEnumerateBrokeredEvents(BrokerId, Count, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferBiPtFreeMemory(Buffer);
  SetLength(BrokeredEvents, Count);
  Cursor := Buffer;

  for i := 0 to High(BrokeredEvents) do
  begin
    BrokeredEvents[i] := Cursor^;
    Inc(Cursor);
  end;
end;

function BixPartialTrustQueryBroadcastChannels;
begin
  Result := LdrxCheckDelayedImport(delayed_BiPtQuerySystemStateBroadcastChannels);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'BiPtQuerySystemStateBroadcastChannels';
  Result.Status := BiPtQuerySystemStateBroadcastChannels(BroadcastChannels);
end;

{ Full trust APIs }

function DeferBiFreeMemory(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Defer(
    procedure
    begin
      if LdrxCheckDelayedImport(delayed_BiFreeMemory).IsSuccess then
        BiFreeMemory(Buffer);
    end
  );
end;

function BixFullTrustEnumeratePackageWorkItems;
var
  PackageFullNameStr: TNtUnicodeString;
  i, Count: Integer;
  Buffer, Cursor: PGuid;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_BiEnumerateWorkItemsForPackageName);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(PackageFullNameStr, PackageFullName);

  if not Result.IsSuccess then
    Exit;

  Count := 0;
  Buffer := nil;
  Result.Location := 'BiEnumerateWorkItemsForPackageName';
  Result.Status := BiEnumerateWorkItemsForPackageName(PackageFullNameStr,
    UserSid.Data, 0, Count, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferBiFreeMemory(Buffer);
  SetLength(WorkItems, Count);
  Cursor := Buffer;

  for i := 0 to High(WorkItems) do
  begin
    WorkItems[i] := Cursor^;
    Inc(Cursor)
  end;
end;

function BixFullTrustQueryWorkItem;
var
  BufferSize: Cardinal;
  Buffer: PBiBrokeredWorkItem;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_BiQueryWorkItem);

  if not Result.IsSuccess then
    Exit;

  BufferSize := 0;
  Buffer := nil;
  Result.Location := 'BiQueryWorkItem';
  Result.Status := BiQueryWorkItem(WorkItemId, BufferSize, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferBiFreeMemory(Buffer);
  BixpCaptureWorkItemInfo(Buffer, BufferSize, Info);
end;

function BixFullTrustQueryBrokeredEvent;
var
  BufferSize: Cardinal;
  Buffer: PBiBrokeredEvent;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_BiQueryBrokeredEvent);

  if not Result.IsSuccess then
    Exit;

  BufferSize := 0;
  Buffer := nil;
  Result.Location := 'BiQueryBrokeredEvent';
  Result.Status := BiQueryBrokeredEvent(EventId, BufferSize, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferBiFreeMemory(Buffer);
  Result := BixpCaptureBrokeredEventInfo(Buffer, Info);
end;

function BixFullTrustEnumerateBrokeredEvents;
var
  Count: Integer;
  Buffer, Cursor: PGuid;
  BufferDeallocator: IAutoReleasable;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_BiEnumerateBrokeredEvents);

  if not Result.IsSuccess then
    Exit;

  Count := 0;
  Buffer := nil;
  Result.Location := 'BiEnumerateBrokeredEvents';
  Result.Status := BiEnumerateBrokeredEvents(BrokerId, Count, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferBiFreeMemory(Buffer);
  SetLength(BrokeredEvents, Count);
  Cursor := Buffer;

  for i := 0 to High(BrokeredEvents) do
  begin
    BrokeredEvents[i] := Cursor^;
    Inc(Cursor);
  end;
end;

function BixFullTrustQueryBroadcastChannels;
begin
  Result := LdrxCheckDelayedImport(delayed_BiQuerySystemStateBroadcastChannels);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'BiQuerySystemStateBroadcastChannels';
  Result.Status := BiQuerySystemStateBroadcastChannels(BroadcastChannels);
end;

end.
