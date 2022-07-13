unit NtUtils.Objects.Compare;

{
  This modules provides a routine that checks if two handles point to the same
  kernel object.
}

interface

uses
  Ntapi.WinNt, NtUtils;

  { Helper functions }

type
  THashingRoutine = function (
    const hxObject: IHandle;
    out Hash: UInt64
  ): TNtxStatus;

// Compute an object hash. Can reopen the object for required access.
function NtxQueryHandleHash(
  hxObject: IHandle;
  HashingRoutine: THashingRoutine;
  RequiredAccess: TAccessMask;
  out Hash: UInt64
): TNtxStatus;

// Compare two objects by computing their hashes
function NtxCompareHandlesByHash(
  const hxObject1: IHandle;
  const hxObject2: IHandle;
  HashingRoutine: THashingRoutine;
  RequiredAccess: TAccessMask;
  out Equal: Boolean
): TNtxStatus;

// Hashing routines
function NtxHashToken(const hxToken: IHandle; out Hash: UInt64): TNtxStatus;
function NtxHashProcess(const hxProcess: IHandle; out Hash: UInt64): TNtxStatus;
function NtxHashThread(const hxThread: IHandle; out Hash: UInt64): TNtxStatus;

  { Generic comparison }

// Check whether two handles point to the same kernel object.
// Returns STATUS_SUCCESS (same), STATUS_NOT_SAME_OBJECT, or other error
function NtxCompareObjects(
  out Equal: Boolean;
  hxObject1: IHandle;
  hxObject2: IHandle;
  [opt] ObjectTypeName: String = ''
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, Ntapi.ntobapi, Ntapi.ntpsapi, Ntapi.ntseapi,
  NtUtils.Objects, NtUtils.Ldr, NtUtils.Objects.Snapshots, DelphiUtils.Arrays,
  NtUtils.Tokens, NtUtils.Tokens.Info, NtUtils.Processes.Info, NtUtils.Threads;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxQueryHandleHash;
begin
  // Try to peform hashing
  Result := HashingRoutine(hxObject, Hash);

  // If necessary, reopen the object and try again
  if (Result.Status = STATUS_ACCESS_DENIED) and
    NtxReopenHandle(hxObject, RequiredAccess).IsSuccess then
    Result := HashingRoutine(hxObject, Hash);
end;

function NtxCompareHandlesByHash;
var
  Hash1, Hash2: UInt64;
begin
  // Hash the first handle
  Result := NtxQueryHandleHash(hxObject1, HashingRoutine, RequiredAccess, Hash1);

  if not Result.IsSuccess then
    Exit;

  // Hash the second handle
  Result := NtxQueryHandleHash(hxObject2, HashingRoutine, RequiredAccess, Hash2);

  if not Result.IsSuccess then
    Exit;

  Equal := Hash1 = Hash2;
end;

function NtxHashToken;
var
  Stats: TTokenStatistics;
begin
  // Use TokenId as a hash value
  Result := NtxToken.Query(hxToken, TokenStatistics, Stats);

  if Result.IsSuccess then
    Hash := UInt64(Stats.TokenId);
end;

function NtxHashProcess;
var
  Info: TProcessBasicInformation;
begin
  // Use ProcessId as a hash value
  Result := NtxProcess.Query(hxProcess.Handle, ProcessBasicInformation, Info);

  if Result.IsSuccess then
    Hash := UInt64(Info.UniqueProcessId);
end;

function NtxHashThread;
var
  Info: TThreadBasicInformation;
begin
  // Use ThreadId as a hash value
  Result := NtxThread.Query(hxThread.Handle, ThreadBasicInformation, Info);

  if Result.IsSuccess then
    Hash := UInt64(Info.ClientId.UniqueThread);
end;

function ExpandCustomPseudoHandles(var hxObject: IHandle): TNtxStatus;
begin
  // Only tokens for now
  if (hxObject.Handle = NtCurrentProcessToken) or
    (hxObject.Handle = NtCurrentThreadToken) or
   (hxObject.Handle = NtCurrentEffectiveToken) then
    Result := NtxExpandToken(hxObject, TOKEN_QUERY)
  else
    Result.Status := STATUS_SUCCESS;
end;

function NtxCompareObjects;
var
  Type1, Type2: TObjectTypeInfo;
  Name1, Name2: String;
  Handles: TArray<TSystemHandleEntry>;
  i, j: Integer;
begin
  Result.Status := STATUS_SUCCESS;

  if hxObject1.Handle = hxObject2.Handle then
  begin
    Equal := True;
    Exit;
  end;

  // Add support for token pseudo-handles
  Result := ExpandCustomPseudoHandles(hxObject1);

  if not Result.IsSuccess then
    Exit;

  Result := ExpandCustomPseudoHandles(hxObject2);

  if not Result.IsSuccess then
    Exit;

  // Win 10 TH+ makes things way easier
  if LdrxCheckNtDelayedImport('NtCompareObjects').IsSuccess then
  begin
    Result.Location := 'NtCompareObjects';
    Result.Status := NtCompareObjects(hxObject1.Handle, hxObject2.Handle);
    Equal := Result.Status <> STATUS_NOT_SAME_OBJECT;
    Exit;
  end;

  // Get object's type if the caller didn't specify it
  if ObjectTypeName = '' then
    if NtxQueryTypeObject(hxObject1.Handle, Type1).IsSuccess and
      NtxQueryTypeObject(hxObject2.Handle, Type2).IsSuccess then
    begin
      if Type1.TypeName <> Type2.TypeName then
      begin
        Equal := False;
        Exit;
      end;

      ObjectTypeName := Type1.TypeName;
    end;

  // Perform type-specific comparison
  if ObjectTypeName <> '' then
  begin
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;

    if ObjectTypeName = 'Token' then
      Result := NtxCompareHandlesByHash(hxObject1, hxObject2, NtxHashToken,
        TOKEN_QUERY, Equal)
    else
    if ObjectTypeName = 'Process' then
      Result := NtxCompareHandlesByHash(hxObject1, hxObject2, NtxHashProcess,
        PROCESS_QUERY_LIMITED_INFORMATION, Equal)
    else
    if ObjectTypeName = 'Thread' then
      Result := NtxCompareHandlesByHash(hxObject1, hxObject2, NtxHashThread,
        THREAD_QUERY_LIMITED_INFORMATION, Equal);

    if Result.IsSuccess then
      Exit;
  end;

  // Note: desktops with the same name located in different window
  // station appear the same, although they are not.

  // Compare named objects
  if NtxQueryNameObject(hxObject1.Handle, Name1).IsSuccess and
    NtxQueryNameObject(hxObject2.Handle, Name2).IsSuccess then
    if (Name1 <> Name2) then
    begin
      Equal := False;
      Result.Status := STATUS_SUCCESS;
      Exit;
    end
    else if (Name1 <> '') and (ObjectTypeName <> 'Desktop') then
    begin
      Equal := True;
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

  // The last resort is to proceed via a handle snapshot
  Result := NtxEnumerateHandles(Handles);

  if not Result.IsSuccess then
    Exit;

  TArray.FilterInline<TSystemHandleEntry>(Handles,
    ByProcess(NtCurrentProcessId));

  for i := 0 to High(Handles) do
    if Handles[i].HandleValue = hxObject1.Handle then
      for j := i + 1 to High(Handles) do
        if Handles[j].HandleValue = hxObject2.Handle then
        begin
          Equal := (Handles[i].PObject = Handles[j].PObject);
          Exit;
        end;

  Result.Location := 'NtxCompareObjects';
  Result.Status := STATUS_INVALID_HANDLE;
end;

end.
