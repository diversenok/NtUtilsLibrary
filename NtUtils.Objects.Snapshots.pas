unit NtUtils.Objects.Snapshots;

{
  This module provides functions for enumerating handles, objects, and kernel
  types on the system.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntexapi, Ntapi.ntpsapi, Ntapi.ntseapi,
  NtUtils, NtUtils.Objects, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TProcessHandleEntry = record
    ProcessId: TProcessId;
    HandleValue: THandle;
    HandleCount: NativeUInt;
    PointerCount: NativeUInt;
    GrantedAccess: TAccessMask;
    ObjectTypeIndex: Cardinal;
    HandleAttributes: TObjectAttributesFlags;
  end;

  TSystemHandleEntry = Ntapi.ntexapi.TSystemHandleTableEntryInfoEx;
  THandleGroup = TArrayGroup<TProcessId, TSystemHandleEntry>;

  TObjectEntry = record
    ObjectName: String;
    Other: TSystemObjectInformation;
  end;
  PObjectEntry = ^TObjectEntry;

  TObjectTypeEntry = record
    TypeName: String;
    Other: TSystemObjectTypeInformation;
    Objects: TArray<TObjectEntry>;
  end;

{ Process handles }

// Snapshot handles of a specific process
function NtxEnumerateHandlesProcess(
  [Access(PROCESS_QUERY_INFORMATION)] const hxProcess: IHandle;
  out Handles: TArray<TProcessHandleEntry>
): TNtxStatus;

{ System Handles }

// Snapshot all handles on the system
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForExtendedFunctionality)]
function NtxEnumerateHandles(
  out Handles: TArray<TSystemHandleEntry>
): TNtxStatus;

// Snapshot all handles on the system and groups them by process IDs
function NtxEnumerateHandlesGroupByPid(
  out HandleGroups: TArray<THandleGroup>;
  [opt] Filter: TCondition<TSystemHandleEntry> = nil
): TNtxStatus;

// Find a handle entry
function RtlxFindHandleEntry(
  const Handles: TArray<TSystemHandleEntry>;
  PID: TProcessId;
  HandleValue: THandle;
  out Entry: TSystemHandleEntry
): TNtxStatus;

// Filter handles that reference the same object as a local handle
function RtlxFilterHandlesByHandle(
  var Handles: TArray<TSystemHandleEntry>;
  const Handle: IHandle
): TNtxStatus;

{ System objects }

// Check if object snapshotting is supported
function RtlxObjectEnumerationSupported: Boolean;

// Snapshot objects on the system
function NtxEnumerateObjects(
  out Types: TArray<TObjectTypeEntry>
): TNtxStatus;

// Find object entry by a object's address
function RtlxFindObjectByAddress(
  const Types: TArray<TObjectTypeEntry>;
  [in] Address: Pointer
): PObjectEntry;

{ Types }

// Enumerate kernel object types on the system
function NtxEnumerateKernelTypes(
  out Types: TArray<TObjectTypeInfo>
): TNtxStatus;

// Find information about a kernel object type by its name
function RtlxFindKernelType(
  const TypeName: String;
  out Info: TObjectTypeInfo;
  [ThreadSafe] UseCaching: Boolean = True
): TNtxStatus;

{ Filtration routines }

// Process handles

function ByType(
  TypeIndex: Word
): TCondition<TProcessHandleEntry>;

function ByAccess(
  AccessMask: TAccessMask
): TCondition<TProcessHandleEntry>;

// System handles

function ByProcess(
  PID: TProcessId
): TCondition<TSystemHandleEntry>;

function ByAddress(
  [in] Address: Pointer
): TCondition<TSystemHandleEntry>;

function ByTypeIndex(
  TypeIndex: Word
): TCondition<TSystemHandleEntry>;

function ByGrantedAccess(
  AccessMask: TAccessMask
): TCondition<TSystemHandleEntry>;

implementation

uses
  Ntapi.ntobapi, Ntapi.ntstatus, Ntapi.ntpebteb, Ntapi.Versions,
  NtUtils.Processes.Info, NtUtils.System, NtUtils.Synchronization,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Process Handles }

function NtxEnumerateHandlesProcess;
var
  xMemory: IMemory<PProcessHandleSnapshotInformation>;
  i: Integer;
  BasicInfo: TProcessBasicInformation;
  AllHandles: TArray<TSystemHandleEntry>;
begin
  if Assigned(hxProcess) and (hxProcess.Handle <> NtCurrentProcess) then
  begin
    // Determine the process ID
    Result := NtxProcess.Query(hxProcess, ProcessBasicInformation, BasicInfo);

    if not Result.IsSuccess then
      Exit;
  end
  else
    BasicInfo.UniqueProcessID := NtCurrentProcessId;

  if RtlOsVersionAtLeast(OsWin8) then
  begin
    // Use a per-process handle enumeration on Win 8+
    Result := NtxQueryProcess(hxProcess, ProcessHandleInformation,
      IMemory(xMemory));

    if not Result.IsSuccess then
      Exit;

    SetLength(Handles, xMemory.Data.NumberOfHandles);

    for i := 0 to High(Handles) do
      with xMemory.Data.Handles{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}  do
      begin
        Handles[i].ProcessId := BasicInfo.UniqueProcessID;
        Handles[i].HandleValue := HandleValue;
        Handles[i].HandleCount := HandleCount;
        Handles[i].PointerCount := PointerCount;
        Handles[i].GrantedAccess := GrantedAccess;
        Handles[i].ObjectTypeIndex := ObjectTypeIndex;
        Handles[i].HandleAttributes := HandleAttributes;
      end;
  end
  else
  begin
    // Make a snapshot of all handles
    Result := NtxEnumerateHandles(AllHandles);

    if not Result.IsSuccess then
      Exit;

    // Include only handles from the target process
    TArray.FilterInline<TSystemHandleEntry>(AllHandles,
      ByProcess(BasicInfo.UniqueProcessID));

    SetLength(Handles, Length(AllHandles));

    // Convert system handle entries to process handle entries
    for i := 0 to High(Handles) do
      with AllHandles[i] do
      begin
        Handles[i].ProcessId := BasicInfo.UniqueProcessID;
        Handles[i].HandleValue := HandleValue;
        Handles[i].HandleCount := 0; // unavailable, query it manually
        Handles[i].PointerCount := 0; // unavailable, query it manually
        Handles[i].GrantedAccess := GrantedAccess;
        Handles[i].ObjectTypeIndex := ObjectTypeIndex;
        Handles[i].HandleAttributes := HandleAttributes;
      end;
  end;
end;

{ System Handles }

function NtxEnumerateHandles;
const
  INITIAL_SIZE = 6 * 1024 * 1024;
var
  xMemory: IMemory<PSystemHandleInformationEx>;
  i: Integer;
begin
  // On my system it is usually about 100k handles, so it's about 4 MB of data.
  // We don't want to use a huge initial buffer since system spends more time
  // probing it rather than collecting the handles. Use 6 MB initially.

  Result := NtxQuerySystem(SystemExtendedHandleInformation, IMemory(xMemory),
    INITIAL_SIZE, Grow12Percent);

  if not Result.IsSuccess then
    Exit;

  SetLength(Handles, xMemory.Data.NumberOfHandles);

  for i := 0 to High(Handles) do
    Handles[i] := xMemory.Data.Handles{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

function NtxEnumerateHandlesGroupByPid;
var
  Handles: TArray<TSystemHandleEntry>;
begin
  // Get all handles
  Result := NtxEnumerateHandles(Handles);

  if not Result.IsSuccess then
    Exit;

  // Optionally, apply the filter
  if Assigned(Filter) then
    TArray.FilterInline<TSystemHandleEntry>(Handles, Filter);

  // Group using owning PID as a key
  HandleGroups := TArray.GroupBy<TSystemHandleEntry, TProcessId>(Handles,
    function (const Entry: TSystemHandleEntry): TProcessId
    begin
      Result := Entry.UniqueProcessId;
    end
  );
end;

function RtlxFindHandleEntry;
var
  i: Integer;
begin
  for i := 0 to High(Handles) do
    if (Handles[i].UniqueProcessId = PID) and
      (Handles[i].HandleValue = HandleValue) then
    begin
      Entry := Handles[i];
      Exit(NtxSuccess);
    end;

  Result.Location := 'NtxFindHandleEntry';
  Result.Status := STATUS_NOT_FOUND;
end;

function RtlxFilterHandlesByHandle;
var
  Entry: TSystemHandleEntry;
begin
  Result := RtlxFindHandleEntry(Handles, NtCurrentProcessId,
    HandleOrDefault(Handle), Entry);

  if not Result.IsSuccess then
    Exit;

  // Kernel address leak prevention can blocks us
  if not Assigned(Entry.PObject) then
  begin
    Result.Location := 'RtlxFilterHandlesByHandle';
    Result.LastCall.ExpectedPrivilege := SE_DEBUG_PRIVILEGE;
    Result.Status := STATUS_PRIVILEGE_NOT_HELD;
    Exit;
  end;

  TArray.FilterInline<TSystemHandleEntry>(Handles, ByAddress(Entry.PObject));
end;

{ Objects }

function RtlxObjectEnumerationSupported;
begin
  Result := BitTest(RtlGetNtGlobalFlags and FLG_MAINTAIN_OBJECT_TYPELIST);
end;

function GrowObjectBuffer(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  // Object collection works in stages, we don't receive the correct buffer
  // size on the first attempt. Speed it up.
  Result := Required shl 1 + 64 * 1024 // x2 + 64 kB
end;

function NtxEnumerateObjects;
var
  xMemory: IMemory<PSystemObjectTypeInformation>;
  pTypeEntry: PSystemObjectTypeInformation;
  pObjEntry: PSystemObjectInformation;
  Count, i, j: Integer;
begin
  // On my system it is usually about 22k objects, so about 2 MB of data.
  // We don't want to use a huge initial buffer since system spends more time
  // probing it rather than collecting the objects.

  Result := NtxQuerySystem(SystemObjectInformation, IMemory(xMemory),
    3 * 1024 * 1024, GrowObjectBuffer);

  if not Result.IsSuccess then
    Exit;

  // Count returned types
  Count := 0;
  pTypeEntry := xMemory.Data;

  repeat
    Inc(Count);

    if pTypeEntry.NextEntryOffset = 0 then
      Break
    else
      pTypeEntry := xMemory.Offset(pTypeEntry.NextEntryOffset);
  until False;

  SetLength(Types, Count);

  // Iterate through each type
  j := 0;
  pTypeEntry := xMemory.Data;

  repeat
    // Copy type information
    Types[j].TypeName := pTypeEntry.TypeName.ToString;
    Types[j].Other := pTypeEntry^;
    Types[j].Other.TypeName.Buffer := PWideChar(Types[j].TypeName);

    // Count objects of this type
    Count := 0;
    pObjEntry := Pointer(UIntPtr(pTypeEntry) +
      SizeOf(TSystemObjectTypeInformation) + pTypeEntry.TypeName.MaximumLength);

    repeat
      Inc(Count);

      if pObjEntry.NextEntryOffset = 0 then
        Break
      else
        pObjEntry := xMemory.Offset(pObjEntry.NextEntryOffset);
    until False;

    SetLength(Types[j].Objects, Count);

    // Iterate trough objects
    i := 0;
    pObjEntry := Pointer(UIntPtr(pTypeEntry) +
      SizeOf(TSystemObjectTypeInformation) + pTypeEntry.TypeName.MaximumLength);

    repeat
      // Copy object information
      Types[j].Objects[i].ObjectName := pObjEntry.NameInfo.ToString;
      Types[j].Objects[i].Other := pObjEntry^;
      Types[j].Objects[i].Other.NameInfo.Buffer :=
        PWideChar(Types[j].Objects[i].ObjectName);

      if pObjEntry.NextEntryOffset = 0 then
        Break
      else
        pObjEntry := xMemory.Offset(pObjEntry.NextEntryOffset);

      Inc(i);
    until False;

    // Skip to the next type
    if pTypeEntry.NextEntryOffset = 0 then
      Break
    else
      pTypeEntry := xMemory.Offset(pTypeEntry.NextEntryOffset);

    Inc(j);
  until False;
end;

function RtlxFindObjectByAddress;
var
  i, j: Integer;
begin
  for i := 0 to High(Types) do
    for j := 0 to High(Types[i].Objects) do
      if Types[i].Objects[j].Other.ObjectAddress = Address then
        Exit(@Types[i].Objects[j]);

  Result := nil;
end;

{ Types }

function NtxEnumerateKernelTypes;
var
  xMemory: IMemory<PObjectTypesInformation>;
  pType: PObjectTypeInformation;
  i: Integer;
begin
  Result := NtxQueryObject(nil, ObjectTypesInformation, IMemory(xMemory),
    SizeOf(TObjectTypesInformation));

  if not Result.IsSuccess then
    Exit;

  SetLength(Types, xMemory.Data.NumberOfTypes);

  i := 0;
  pType := @xMemory.Data.FirstEntry;

  repeat
    Types[i].Native := pType^;
    Types[i].TypeName := pType.TypeName.ToString;
    Types[i].Native.TypeName.Buffer := PWideChar(Types[i].TypeName);

    // Until Windows 8.1, ObQueryTypeInfo didn't write anything to the TypeIndex
    // field. We can work around this issue by manually calculating the value.
    // NtQueryObject iterates through ObpObjectTypes, which is zero-based;
    // TypeIndex is an index into ObTypeIndexTable, which starts with 2.

    if Types[i].Native.TypeIndex = 0 then
      Types[i].Native.TypeIndex := OB_TYPE_INDEX_TABLE_TYPE_OFFSET + i;

    pType := Pointer(UIntPtr(pType) + AlignUp(SizeOf(TObjectTypeInformation)) +
      AlignUp(pType.TypeName.MaximumLength));

    Inc(i);
  until i > High(Types);
end;

var
  TypesCacheInitialized: TRtlRunOnce;
  TypesCache: TArray<TObjectTypeInfo>;

function RtlxFindKernelType;
var
  Types: TArray<TObjectTypeInfo>;
  InitState: IAcquiredRunOnce;
  i: Integer;
begin
  InitState := nil;

  // Enumerate types if we are first or need the latest data
  if RtlxRunOnceBegin(@TypesCacheInitialized, InitState) or not UseCaching then
  begin
    Result := NtxEnumerateKernelTypes(Types);

    if not Result.IsSuccess then
      Exit;

    if Assigned(InitState) then
    begin
      // Cache the results if we are first
      TypesCache := Types;
      InitState.Complete;
    end;
  end
  else
    Types := TypesCache;

  // Find the corresponding entry
  for i := 0 to High(Types) do
    if Types[i].TypeName = TypeName then
    begin
      Info := Types[i];
      Exit(NtxSuccess);
    end;

  Result.Location := 'NtxFindKernelType';
  Result.Status := STATUS_NOT_FOUND;
end;

{ Filtration routines}

// Process handles

function ByType;
begin
  Result := function (const HandleEntry: TProcessHandleEntry): Boolean
    begin
      Result := HandleEntry.ObjectTypeIndex = TypeIndex;
    end;
end;

function ByAccess;
begin
  Result := function (const HandleEntry: TProcessHandleEntry): Boolean
    begin
      Result := HandleEntry.GrantedAccess = AccessMask;
    end;
end;

// System handles

function ByProcess;
begin
  Result := function (const HandleEntry: TSystemHandleEntry): Boolean
    begin
      Result := HandleEntry.UniqueProcessId = PID;
    end;
end;

function ByAddress;
begin
  Result := function (const HandleEntry: TSystemHandleEntry): Boolean
    begin
      Result := HandleEntry.PObject = Address;
    end;
end;

function ByTypeIndex;
begin
  Result := function (const HandleEntry: TSystemHandleEntry): Boolean
    begin
      Result := HandleEntry.ObjectTypeIndex = TypeIndex;
    end;
end;

function ByGrantedAccess;
begin
  Result := function (const HandleEntry: TSystemHandleEntry): Boolean
    begin
      Result := HandleEntry.GrantedAccess = AccessMask;
    end;
end;

end.
