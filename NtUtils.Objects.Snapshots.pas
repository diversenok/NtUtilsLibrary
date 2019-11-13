unit NtUtils.Objects.Snapshots;

interface

uses
  Ntapi.ntexapi, NtUtils.Objects, NtUtils.Exceptions, Ntapi.ntpsapi;

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
    Objects: array of TObjectEntry;
  end;

  TFilterAction = (ftInclude, ftExclude);

{ Process handles }

// Snapshot handles of a specific process (only Windows 8+)
function NtxEnumerateHandlesProcess(hProcess: THandle;
  out Handles: TArray<TProcessHandleEntry>): TNtxStatus;

{ System Handles }

// Snapshot all handles on the system
function NtxEnumerateHandles(out Handles: TArray<TSystemHandleEntry>):
  TNtxStatus;

// Find a handle entry
function NtxFindHandleEntry(Handles: TArray<TSystemHandleEntry>;
  PID: NativeUInt; Handle: THandle; out Entry: TSystemHandleEntry): Boolean;

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

{ Filtration routines }

// Process handles
function FilterByType(const HandleEntry: TProcessHandleEntry;
  TypeIndex: NativeUInt): Boolean; overload;
function FilterByAccess(const HandleEntry: TProcessHandleEntry;
  AccessMask: NativeUInt): Boolean; overload;

// System handles
function FilterByProcess(const HandleEntry: TSystemHandleEntry;
  PID: NativeUInt): Boolean;
function FilterByAddress(const HandleEntry: TSystemHandleEntry;
  ObjectAddress: NativeUInt): Boolean;
function FilterByType(const HandleEntry: TSystemHandleEntry;
  TypeIndex: NativeUInt): Boolean; overload;
function FilterByAccess(const HandleEntry: TSystemHandleEntry;
  AccessMask: NativeUInt): Boolean; overload;

implementation

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntobapi,
  NtUtils.Processes, DelphiUtils.Arrays;

{ Process Handles }

function NtxEnumerateHandlesProcess(hProcess: THandle;
  out Handles: TArray<TProcessHandleEntry>): TNtxStatus;
var
  Buffer: PProcessHandleSnapshotInformation;
  i: Integer;
begin
  Buffer := NtxQueryProcess(hProcess, ProcessHandleInformation, Result);

  if not Result.IsSuccess then
    Exit;

  SetLength(Handles, Buffer.NumberOfHandles);

  for i := 0 to High(Handles) do
    Handles[i] := Buffer.Handles{$R-}[i]{$R+};

  FreeMem(Buffer);
end;

{ System Handles }

function NtxEnumerateHandles(out Handles: TArray<TSystemHandleEntry>):
  TNtxStatus;
var
  BufferSize, ReturnLength: Cardinal;
  Buffer: PSystemHandleInformationEx;
  i: Integer;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(SystemExtendedHandleInformation);
  Result.LastCall.InfoClassType := TypeInfo(TSystemInformationClass);

  // On my system it is usually about 60k handles, so it's about 2.5 MB of data.
  //
  // We don't want to use a huge initial buffer since system spends
  // more time probing it rather than coollecting the handles.

  BufferSize := 4 * 1024 * 1024;
  repeat
    Buffer := AllocMem(BufferSize);

    ReturnLength := 0;
    Result.Status := NtQuerySystemInformation(SystemExtendedHandleInformation,
      Buffer, BufferSize, @ReturnLength);

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, ReturnLength, True);

  if not Result.IsSuccess then
    Exit;

  SetLength(Handles, Buffer.NumberOfHandles);

  for i := 0 to High(Handles) do
    Handles[i] := Buffer.Handles{$R-}[i]{$R+};

  FreeMem(Buffer);
end;

function NtxFindHandleEntry(Handles: TArray<TSystemHandleEntry>;
  PID: NativeUInt; Handle: THandle; out Entry: TSystemHandleEntry): Boolean;
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
    TArrayHelper.Filter<TSystemHandleEntry>(Handles, FilterByAddress,
      NativeUInt(Entry.PObject))
  else
    SetLength(Handles, 0);
end;

{ Objects }

function NtxObjectEnumerationSupported: Boolean;
begin
  Result := (RtlGetNtGlobalFlags and FLG_MAINTAIN_OBJECT_TYPELIST <> 0);
end;

function NtxEnumerateObjects(out Types: TArray<TObjectTypeEntry>): TNtxStatus;
var
  BufferSize, Required: Cardinal;
  Buffer, pTypeEntry: PSystemObjectTypeInformation;
  pObjEntry: PSystemObjectInformation;
  Count, i, j: Integer;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(SystemObjectInformation);
  Result.LastCall.InfoClassType := TypeInfo(TSystemInformationClass);

  // On my system it is usually about 22k objects, so about 2 MB of data.
  // We don't want to use a huge initial buffer since system spends more time
  // probing it rather than collecting the objects
  BufferSize := 3 * 1024 * 1024;

  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQuerySystemInformation(SystemObjectInformation, Buffer,
      BufferSize, @Required);

    if not Result.IsSuccess then
      FreeMem(Buffer);

    // The call usually does not calculate the required
    // size in one pass, we need to speed it up.
    Required := Required shl 1 + 64 * 1024 // x2 + 64 kB

  until not NtxExpandBuffer(Result, BufferSize, Required);

  if not Result.IsSuccess then
    Exit;

  // Count returned types
  Count := 0;
  pTypeEntry := Buffer;

  repeat
    Inc(Count);

    if pTypeEntry.NextEntryOffset = 0 then
      Break
    else
      pTypeEntry := Offset(Buffer, pTypeEntry.NextEntryOffset);
  until False;

  SetLength(Types, Count);

  // Iterarate through each type
  j := 0;
  pTypeEntry := Buffer;

  repeat
    // Copy type information
    Types[j].TypeName := pTypeEntry.TypeName.ToString;
    Types[j].Other := pTypeEntry^;
    Types[j].Other.TypeName.Buffer := PWideChar(Types[j].TypeName);

    // Count objects of this type
    Count := 0;
    pObjEntry := Offset(pTypeEntry, SizeOf(TSystemObjectTypeInformation) +
        pTypeEntry.TypeName.MaximumLength);

    repeat
      Inc(Count);

      if pObjEntry.NextEntryOffset = 0 then
        Break
      else
        pObjEntry := Offset(Buffer, pObjEntry.NextEntryOffset);
    until False;

    SetLength(Types[j].Objects, Count);

    // Iterate trough objects
    i := 0;
    pObjEntry := Offset(pTypeEntry, SizeOf(TSystemObjectTypeInformation) +
        pTypeEntry.TypeName.MaximumLength);

    repeat
      // Copy object information
      Types[j].Objects[i].ObjectName := pObjEntry.NameInfo.ToString;
      Types[j].Objects[i].Other := pObjEntry^;
      Types[j].Objects[i].Other.NameInfo.Buffer :=
        PWideChar(Types[j].Objects[i].ObjectName);

      if pObjEntry.NextEntryOffset = 0 then
        Break
      else
        pObjEntry := Offset(Buffer, pObjEntry.NextEntryOffset);

      Inc(i);
    until False;

    // Skip to the next type
    if pTypeEntry.NextEntryOffset = 0 then
      Break
    else
      pTypeEntry := Offset(Buffer, pTypeEntry.NextEntryOffset);

    Inc(j);
  until False;

  FreeMem(Buffer);
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
  Buffer: PObjectTypesInformation;
  pType: PObjectTypeInformation;
  BufferSize, Required: Cardinal;
  i: Integer;
begin
  Result.Location := 'NtQueryObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(ObjectTypesInformation);
  Result.LastCall.InfoClassType := TypeInfo(TObjectInformationClass);

  BufferSize := SizeOf(TObjectTypesInformation);
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryObject(0, ObjectTypesInformation, Buffer,
      BufferSize, @Required);

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, Required, True);

  if not Result.IsSuccess then
    Exit;

  SetLength(Types, Buffer.NumberOfTypes);

  i := 0;
  pType := Offset(Buffer, SizeOf(NativeUInt));

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

    pType := Offset(pType, AlighUp(SizeOf(TObjectTypeInformation)) +
      AlighUp(pType.TypeName.MaximumLength));

    Inc(i);
  until i > High(Types);

  FreeMem(Buffer);
end;

{ Filtration routines}

// Process handles

function FilterByType(const HandleEntry: TProcessHandleEntry;
  TypeIndex: NativeUInt): Boolean; overload;
begin
  Result := (HandleEntry.ObjectTypeIndex = Cardinal(TypeIndex));
end;

function FilterByAccess(const HandleEntry: TProcessHandleEntry;
  AccessMask: NativeUInt): Boolean; overload;
begin
  Result := (HandleEntry.GrantedAccess = TAccessMask(AccessMask));
end;

// System handles

function FilterByProcess(const HandleEntry: TSystemHandleEntry;
  PID: NativeUInt): Boolean;
begin
  Result := (HandleEntry.UniqueProcessId = PID);
end;

function FilterByAddress(const HandleEntry: TSystemHandleEntry;
  ObjectAddress: NativeUInt): Boolean;
begin
  Result := (HandleEntry.PObject = Pointer(ObjectAddress));
end;

function FilterByType(const HandleEntry: TSystemHandleEntry;
  TypeIndex: NativeUInt): Boolean;
begin
  Result := (HandleEntry.ObjectTypeIndex = Word(TypeIndex));
end;

function FilterByAccess(const HandleEntry: TSystemHandleEntry;
  AccessMask: NativeUInt): Boolean;
begin
  Result := (HandleEntry.GrantedAccess = TAccessMask(AccessMask));
end;

end.
