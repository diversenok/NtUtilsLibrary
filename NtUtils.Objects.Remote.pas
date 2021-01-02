unit NtUtils.Objects.Remote;

interface

uses
  Winapi.WinNt, NtUtils, NtUtils.Shellcode;

const
  // Represents the default amount of attempts when replacing a hanlde.
  // It seelms fairly unlikely that the system will allocate a new page for the
  // handle table instead of using free spots in the existing one. For better
  // estimation, use the current/highwater amount of handles for the process.
  HANDLES_PER_PAGE = $1000 div (SizeOf(Pointer) * 2) - 1;

// Send a handle to a process and make sure it ends up with a particular value
function NtxPlaceHandle(hProcess, hRemoteHandle, hLocalHandle: THandle;
  MaxAttempts: Integer): TNtxStatus;

// Replace a handle in a process with another handle
function NtxReplaceHandle(hProcess, hRemoteHandle, hLocalHandle: THandle):
  TNtxStatus;

// Reopen a handle in a process with a different access
function NtxReplaceHandleReopen(hProcess, hRemoteHandle: THandle;
  DesiredAccess: TAccessMask): TNtxStatus;

// Set flags for a handles in a process
function NtxSetFlagsRemoteHandle(hxProcess: IHandle; hObject: THandle;
  Inherit: Boolean; ProtectFromClose: Boolean; Timeout: Int64 =
  DEFAULT_REMOTE_TIMEOUT): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, Ntapi.ntobapi, Ntapi.ntwow64, ntapi.ntpsapi,
  NtUtils.Objects, NtUtils.Threads, NtUtils.Processes.Query,
  NtUtils.Processes.Memory;

function NtxPlaceHandle(hProcess, hRemoteHandle, hLocalHandle: THandle;
  MaxAttempts: Integer): TNtxStatus;
var
  OccupiedSlots: TArray<THandle>;
  hActual: THandle;
  i: Integer;
begin
  if hRemoteHandle and $3 <> 0 then
  begin
    // The target value should be dividable by 4
    Result.Location := 'NtxPlaceHandle';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  SetLength(OccupiedSlots, 0);

  repeat
    // Send the handle to the target
    Result := NtxDuplicateHandleTo(hProcess, hLocalHandle, hActual);

    if not Result.IsSuccess then
      Break;

    // This is precisely what we wanted
    if hRemoteHandle = hActual then
    begin
      Result.Status := STATUS_SUCCESS;
      Break;
    end;

    // This is not the slot we wanted to occupy.
    // Save the value to close the handle later.
    SetLength(OccupiedSlots, Length(OccupiedSlots) + 1);
    OccupiedSlots[High(OccupiedSlots)] := hActual;

    // Looks like we fell a victim of a race condition and cannot recover.
    if Length(OccupiedSlots) > MaxAttempts then
    begin
      Result.Location := 'NtxPlaceHandle';
      Result.Status := STATUS_UNSUCCESSFUL;
      Break;
    end;
  until False;

  // Close the handles we inserted into wrong slots
  for i := High(OccupiedSlots) downto 0 do
    NtxCloseRemoteHandle(hProcess, OccupiedSlots[i])
end;

function NtxReplaceHandle(hProcess, hRemoteHandle, hLocalHandle: THandle):
  TNtxStatus;
begin
  // Start with closing a remote handle to free its slot. Use verbose checking.
  Result := NtxCloseRemoteHandle(hProcess, hRemoteHandle, True);

  if not Result.IsSuccess then
    Exit;

  // Send the new handle to a occupy the same spot
  Result := NtxPlaceHandle(hProcess, hRemoteHandle, hLocalHandle,
    HANDLES_PER_PAGE);

  if Result.Matches(STATUS_UNSUCCESSFUL, 'NtxPlaceHandle') then
  begin
    // Unfortunately, we closed the handle and cannot restore it
    Result.Location := 'NtxReplaceHandle';
    Result.Status := STATUS_HANDLE_REVOKED;
  end;
end;

function NtxReplaceHandleReopen(hProcess, hRemoteHandle: THandle;
  DesiredAccess: TAccessMask): TNtxStatus;
var
  hxLocalHandle: IHandle;
  BasicInfo: TObjectBasicInformaion;
begin
  // Reopen the handle into our process with the desired access
  Result := NtxDuplicateHandleFrom(hProcess, hRemoteHandle, hxLocalHandle,
    0, DesiredAccess, 0);

  if Result.IsSuccess then
  begin
    // Check which access rights we actually got. In some cases, (like ALPC
    // ports) we might receive a handle with an incomplete access mask.
    Result := NtxQueryBasicObject(hxLocalHandle.Handle, BasicInfo);

    if not Result.IsSuccess then
      Exit;

    if DesiredAccess and not MAXIMUM_ALLOWED and not
      BasicInfo.GrantedAccess <> 0 then
    begin
      // Cannot complete the request without loosing some access rights
      Result.Location := 'NtxReplaceHandleReopen';
      Result.Status := STATUS_ACCESS_DENIED;
      Exit;
    end;

    // Replace the handle in the remote process
    Result := NtxReplaceHandle(hProcess, hRemoteHandle, hxLocalHandle.Handle);
  end;
end;

type
  // A context for a thread that will set handle flags remotely
  TFlagSetterContext = record
    NtSetInformationObject: function (Handle: THandle; ObjectInformationClass:
      TObjectInformationClass; ObjectInformation: Pointer;
      ObjectInformationLength: Cardinal): NTSTATUS; stdcall;

    Handle: THandle;
    Info: TObjectHandleFlagInformation;
  end;
  PFlagSetterContext = ^TFlagSetterContext;

  TFlagSetterContext32 = record
    NtSetInformationObject: Wow64Pointer;
    Handle: Cardinal;
    Info: TObjectHandleFlagInformation;
  end;

function HandleFlagSetter(Context: PFlagSetterContext): NTSTATUS; stdcall;
begin
  Result := Context.NtSetInformationObject(Context.Handle,
    ObjectHandleFlagInformation, @Context.Info, SizeOf(Context.Info));
end;

const
  {$IFDEF Win64}
  HandleFlagSetterRaw64: array [0..56] of Byte = (
    $55, $48, $83, $EC, $30, $48, $8B, $EC, $48, $89, $4D, $40, $48, $8B, $45,
    $40, $48, $8B, $48, $08, $BA, $04, $00, $00, $00, $48, $8B, $45, $40, $4C,
    $8D, $40, $10, $41, $B9, $02, $00, $00, $00, $48, $8B, $45, $40, $FF, $10,
    $89, $45, $2C, $8B, $45, $2C, $48, $8D, $65, $30, $5D, $C3
  );
  {$ENDIF}

  HandleFlagSetterRaw32: array [0..37] of Byte = (
    $55, $8B, $EC, $51, $6A, $02, $8B, $45, $08, $83, $C0, $08, $50, $6A, $04,
    $8B, $45, $08, $8B, $40, $04, $50, $8B, $45, $08, $FF, $10, $89, $45, $FC,
    $8B, $45, $FC, $59, $5D, $C2, $04, $00
  );

function NtxSetFlagsRemoteHandle(hxProcess: IHandle; hObject: THandle;
  Inherit: Boolean; ProtectFromClose: Boolean; Timeout: Int64): TNtxStatus;
var
  LocalContext: TFlagSetterContext;
  TargetIsWoW64: Boolean;
  Addresses: TArray<Pointer>;
{$IFDEF Win64}
  LocalContext32: TFlagSetterContext32;
{$ENDIF}
  Context, Code: TMemory;
  RemoteContext, RemoteCode: IMemory;
  hxThread: IHandle;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Find dependencies
  Result := RtlxFindKnownDllExports(ntdll, TargetIsWoW64,
    ['NtSetInformationObject'], Addresses);

  if not Result.IsSuccess then
    Exit;

  // Prepare the context
{$IFDEF Win64}
  if TargetIsWoW64 then
  begin
    LocalContext32.NtSetInformationObject := Wow64Pointer(Addresses[0]);
    LocalContext32.Handle := Cardinal(hObject);
    LocalContext32.Info.Inherit := Inherit;
    LocalContext32.Info.ProtectFromClose := ProtectFromClose;
    Context.Address := @LocalContext32;
    Context.Size := SizeOf(LocalContext32);
    Code.Address := @HandleFlagSetterRaw32;
    Code.Size := SizeOf(HandleFlagSetterRaw32);
  end
  else
{$ENDIF}
  begin
    LocalContext.NtSetInformationObject := Addresses[0];
    LocalContext.Handle := hObject;
    LocalContext.Info.Inherit := Inherit;
    LocalContext.Info.ProtectFromClose := ProtectFromClose;
    Context.Address := @LocalContext;
    Context.Size := SizeOf(LocalContext);
  {$IFDEF Win64}
    Code.Address := @HandleFlagSetterRaw64;
    Code.Size := SizeOf(HandleFlagSetterRaw64);
  {$ELSE}
    Code.Address := @HandleFlagSetterRaw32;
    Code.Size := SizeOf(HandleFlagSetterRaw32);
  {$ENDIF}
  end;

  // Copy the context and the code into the target
  Result := RtlxAllocWriteDataCodeProcess(hxProcess, Context, RemoteContext,
    Code, RemoteCode, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Create the remote thread
  Result := NtxCreateThread(hxThread, hxProcess.Handle, RemoteCode.Data,
    RemoteContext.Data, THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH);

  if not Result.IsSuccess then
    Exit;

  // Sync with the thread. Prolong remote memory lifetime on timeout.
  Result := RtlxSyncThread(hxThread.Handle, 'Remote::NtSetInformationObject',
    Timeout, [RemoteCode, RemoteContext]);
end;

end.
