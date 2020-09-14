unit NtUtils.Objects.Snapshots;

interface

uses
  Winapi.WinNt, Ntapi.ntexapi, Ntapi.ntpsapi, NtUtils, NtUtils.Objects,
  DelphiUtils.Arrays;

type
  TProcessHandleEntry = Ntapi.ntpsapi.TProcessHandleTableEntryInfo;
  TSystemHandleEntry = Ntapi.ntexapi.TSystemHandleTableEntryInfoEx;

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
function NtxEnumerateHandlesProcess(hProcess: THandle; out Handles:
  TArray<TProcessHandleEntry>): TNtxStatus;

{ System Handles }

// Snapshot all handles on the system
function NtxEnumerateHandles(out Handles: TArray<TSystemHandleEntry>):
  TNtxStatus;

// Find a handle entry
function NtxFindHandleEntry(Handles: TArray<TSystemHandleEntry>;
  PID: TProcessId; Handle: THandle; out Entry: TSystemHandleEntry): Boolean;

// Filter handles that reference the same object as a local handle
procedure NtxFilterHandlesByHandle(var Handles: TArray<TSystemHandleEntry>;
  Handle: THandle);

{ System objects }

// Check if object snapshoting is supported
function NtxObjectEnumerationSupported: Boolean;

// Snapshot objects on the system
function NtxEnumerateObjects(out Types: TArray<TObjectTypeEntry>): TNtxStatus;

// Find object entry by a object's address
function NtxFindObjectByAddress(Types: TArray<TObjectTypeEntry>;
  Address: Pointer): PObjectEntry;

{ Types }

// Enumerate kernel object types on the system
function NtxEnumerateTypes(out Types: TArray<TObjectTypeInfo>): TNtxStatus;

// Find an index of a kernel object type by its name
function NtxFindType(const TypeName: String; out Index: Integer): TNtxStatus;

{ Filtration routines }

// Process handles
function ByType(TypeIndex: Word): TCondition<TProcessHandleEntry>;
function ByAccess(AccessMask: TAccessMask): TCondition<TProcessHandleEntry>;

// System handles
function ByProcess(PID: TProcessId): TCondition<TSystemHandleEntry>;
function ByAddress(Address: Pointer): TCondition<TSystemHandleEntry>;
function ByTypeIndex(TypeIndex: Word): TCondition<TSystemHandleEntry>;
function ByGrantedAccess(AccessMask: TAccessMask):
  TCondition<TSystemHandleEntry>;

implementation

uses
  Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntobapi, Ntapi.ntstatus,
  NtUtils.Processes.Query, NtUtils.System, NtUtils.Version,
  DelphiUtils.AutoObject;

{ Process Handles }

function SystemToProcessEntry(const Entry: TSystemHandleEntry)
  : TProcessHandleEntry;
begin
  Result.HandleValue := Entry.HandleValue;
  Result.HandleCount := 0; // unavailable, query it manually
  Result.PointerCount := 0; // unavailable, query it manually
  Result.GrantedAccess := Entry.GrantedAccess;
  Result.ObjectTypeIndex := Entry.ObjectTypeIndex;
  Result.HandleAttributes := Entry.HandleAttributes;
end;

function NtxEnumerateHandlesProcess(hProcess: THandle; out Handles:
  TArray<TProcessHandleEntry>): TNtxStatus;
var
  xMemory: IMemory<PProcessHandleSnapshotInformation>;
  i: Integer;
  BasicInfo: TProcessBasicInformation;
  AllHandles: TArray<TSystemHandleEntry>;
begin
  if RtlOsVersionAtLeast(OsWin8) then
  begin
    // Use a per-process handle enumeration on Win 8+
    Result := NtxQueryProcess(hProcess, ProcessHandleInformation,IMemory(xMemory));

    if Result.IsSuccess then
    begin
      SetLength(Handles, xMemory.Data.NumberOfHandles);

      for i := 0 to High(Handles) do
        Handles[i] := xMemory.Data.Handles{$R-}[i]{$R+};
    end;
  end
  else
  begin
    // Determine the process ID
    if hProcess <> NtCurrentProcess then
    begin
      Result := NtxProcess.Query(hProcess, ProcessBasicInformation, BasicInfo);

      if not Result.IsSuccess then
        Exit;
    end
    else
      BasicInfo.UniqueProcessID := NtCurrentProcessId;

    // Make a snapshot of all handles
    Result := NtxEnumerateHandles(AllHandles);

    if not Result.IsSuccess then
      Exit;

    // Filter only the target process
    TArray.FilterInline<TSystemHandleEntry>(AllHandles,
      ByProcess(BasicInfo.UniqueProcessID));

    // Convert system handle entries to process handle entries
    Handles := TArray.Map<TSystemHandleEntry, TProcessHandleEntry>(
      AllHandles, SystemToProcessEntry);
  end;
end;

{ System Handles }

function NtxEnumerateHandles(out Handles: TArray<TSystemHandleEntry>):
  TNtxStatus;
var
  xMemory: IMemory<PSystemHandleInformationEx>;
  i: Integer;
begin
  // On my system it is usually about 60k handles, so it's about 2.5 MB of data.
  // We don't want to use a huge initial buffer since system spends more time
  // probing it rather than coollecting the handles. Use 4 MB initially.

  Result := NtxQuerySystem(SystemExtendedHandleInformation, IMemory(xMemory),
    4 * 1024 * 1024, Grow12Percent);

  if not Result.IsSuccess then
    Exit;

  SetLength(Handles, xMemory.Data.NumberOfHandles);

  for i := 0 to High(Handles) do
    Handles[i] := xMemory.Data.Handles{$R-}[i]{$R+};
end;

function NtxFindHandleEntry(Handles: TArray<TSystemHandleEntry>;
  PID: TProcessId; Handle: THandle; out Entry: TSystemHandleEntry): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(Handles) do
    if (Handles[i].UniqueProcessId = PID) and (Handles[i].HandleValue = Handle)
      then
    begin
      Entry := Handles[i];
      Exit(True);
    end;

  Result := False;
end;

procedure NtxFilterHandlesByHandle(var Handles: TArray<TSystemHandleEntry>;
  Handle: THandle);
var
  Entry: TSystemHandleEntry;
begin
  if NtxFindHandleEntry(Handles, NtCurrentProcessId, Handle, Entry) then
    TArray.FilterInline<TSystemHandleEntry>(Handles, ByAddress(Entry.PObject))
  else
    SetLength(Handles, 0);
end;

{ Objects }

function NtxObjectEnumerationSupported: Boolean;
begin
  Result := (RtlGetNtGlobalFlags and FLG_MAINTAIN_OBJECT_TYPELIST <> 0);
end;

function GrowObjectBuffer(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  // Object collection works in stages, we don't recieve the correct buffer
  // size on the first attempt. Speed it up.
  Result := Required shl 1 + 64 * 1024 // x2 + 64 kB
end;

function NtxEnumerateObjects(out Types: TArray<TObjectTypeEntry>): TNtxStatus;
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

  // Iterarate through each type
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

function NtxFindObjectByAddress(Types: TArray<TObjectTypeEntry>;
  Address: Pointer): PObjectEntry;
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

function NtxEnumerateTypes(out Types: TArray<TObjectTypeInfo>): TNtxStatus;
var
  xMemory: IMemory<PObjectTypesInformation>;
  pType: PObjectTypeInformation;
  i: Integer;
begin
  Result := NtxQueryObject(0, ObjectTypesInformation, IMemory(xMemory),
    SizeOf(TObjectTypesInformation));

  if not Result.IsSuccess then
    Exit;

  SetLength(Types, xMemory.Data.NumberOfTypes);

  i := 0;
  pType := @xMemory.Data.FirstEntry;

  repeat
    Types[i].Other := pType^;
    Types[i].TypeName := pType.TypeName.ToString;
    Types[i].Other.TypeName.Buffer := PWideChar(Types[i].TypeName);

    // Until Win 8.1 ObQueryTypeInfo didn't write anything to TypeIndex field.
    // Fix it by manually calculating this value.

    // Note: NtQueryObject iterates through ObpObjectTypes which is zero-based;
    // but TypeIndex is an index in ObTypeIndexTable which starts with 2.

    if Types[i].Other.TypeIndex = 0 then
      Types[i].Other.TypeIndex := OB_TYPE_INDEX_TABLE_TYPE_OFFSET + i;

    pType := Pointer(UIntPtr(pType) + AlighUp(SizeOf(TObjectTypeInformation)) +
      AlighUp(pType.TypeName.MaximumLength));

    Inc(i);
  until i > High(Types);
end;

function NtxFindType(const TypeName: String; out Index: Integer): TNtxStatus;
var
  Types: TArray<TObjectTypeInfo>;
begin
  Result := NtxEnumerateTypes(Types);

  if not Result.IsSuccess then
    Exit;

  Index := TArray.ConvertFirstOrDefault<TObjectTypeInfo, Integer>(Types,
    function (const Entry: TObjectTypeInfo; out TypeIndex: Integer): Boolean
    begin
      Result := Entry.TypeName = TypeName;

      if Result then
        TypeIndex := Entry.Other.TypeIndex;
    end,
    -1
  );

  if Index < 0 then
  begin
    Result.Location := 'NtxFindType';
    Result.Status := STATUS_NOT_FOUND;
  end;
end;

{ Filtration routines}

// Process handles

function ByType(TypeIndex: Word): TCondition<TProcessHandleEntry>;
begin
  Result := function (const HandleEntry: TProcessHandleEntry): Boolean
    begin
      Result := HandleEntry.ObjectTypeIndex = TypeIndex;
    end;
end;

function ByAccess(AccessMask: TAccessMask): TCondition<TProcessHandleEntry>;
begin
  Result := function (const HandleEntry: TProcessHandleEntry): Boolean
    begin
      Result := HandleEntry.GrantedAccess = AccessMask;
    end;
end;

// System handles

function ByProcess(PID: TProcessId): TCondition<TSystemHandleEntry>;
begin
  Result := function (const HandleEntry: TSystemHandleEntry): Boolean
    begin
      Result := HandleEntry.UniqueProcessId = PID;
    end;
end;

function ByAddress(Address: Pointer): TCondition<TSystemHandleEntry>;
begin
  Result := function (const HandleEntry: TSystemHandleEntry): Boolean
    begin
      Result := HandleEntry.PObject = Address;
    end;
end;

function ByTypeIndex(TypeIndex: Word): TCondition<TSystemHandleEntry>;
begin
  Result := function (const HandleEntry: TSystemHandleEntry): Boolean
    begin
      Result := HandleEntry.ObjectTypeIndex = TypeIndex;
    end;
end;

function ByGrantedAccess(AccessMask: TAccessMask):
  TCondition<TSystemHandleEntry>;
begin
  Result := function (const HandleEntry: TSystemHandleEntry): Boolean
    begin
      Result := HandleEntry.GrantedAccess = AccessMask;
    end;
end;

end.
