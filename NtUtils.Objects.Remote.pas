unit NtUtils.Objects.Remote;

{
  This modules provides extended operation on handles in context of other
  processes.
}

interface

uses
  Ntapi.WinNt, NtUtils, NtUtils.Shellcode;

const
  // Represents the default amount of attempts when replacing a hanlde.
  // It seelms fairly unlikely that the system will allocate a new page for the
  // handle table instead of using free spots in the existing one. For better
  // estimation, use the current/highwater amount of handles for the process.
  HANDLES_PER_PAGE = $1000 div (SizeOf(Pointer) * 2) - 1;

  // See NtxSetFlagsHandleRemote
  PROCESS_SET_HANDLE_FLAGS = PROCESS_REMOTE_EXECUTE;

// Send a handle to a process and make sure it ends up with a particular value
function NtxPlaceHandle(
  [Access(PROCESS_DUP_HANDLE)] hProcess: THandle;
  hRemoteHandle: THandle;
  hLocalHandle: THandle;
  Inheritable: Boolean = False;
  MaxAttempts: Integer = HANDLES_PER_PAGE
): TNtxStatus;

// Replace a handle in a process with another handle
function NtxReplaceHandle(
  [Access(PROCESS_DUP_HANDLE)] hProcess: THandle;
  hRemoteHandle: THandle;
  hLocalHandle: THandle;
  Inheritable: Boolean = False
): TNtxStatus;

// Reopen a handle in a process with a different access
function NtxReplaceHandleReopen(
  [Access(PROCESS_DUP_HANDLE)] hProcess: THandle;
  hRemoteHandle: THandle;
  DesiredAccess: TAccessMask
): TNtxStatus;

// Set flags for a handles in a process
function NtxSetFlagsHandleRemote(
  [Access(PROCESS_SET_HANDLE_FLAGS)] const hxProcess: IHandle;
  hObject: THandle;
  Inherit: Boolean;
  ProtectFromClose: Boolean;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, Ntapi.ntobapi, ntapi.ntpsapi, NtUtils.Objects,
  NtUtils.Processes.Info, DelphiUtils.AutoObjects;

function NtxPlaceHandle;
var
  OccupiedSlots: TArray<THandle>;
  Attributes: Cardinal;
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

  if Inheritable then
    Attributes := OBJ_INHERIT
  else
    Attributes := 0;

  SetLength(OccupiedSlots, 0);

  repeat
    // Send the handle to the target
    Result := NtxDuplicateHandleTo(hProcess, hLocalHandle, hActual,
      DUPLICATE_SAME_ACCESS, 0, Attributes);

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

function NtxReplaceHandle;
begin
  // Start with closing a remote handle to free its slot. Use verbose checking.
  Result := NtxCloseRemoteHandle(hProcess, hRemoteHandle, True);

  if not Result.IsSuccess then
    Exit;

  // Send the new handle to a occupy the same spot
  Result := NtxPlaceHandle(hProcess, hRemoteHandle, hLocalHandle, Inheritable,
    HANDLES_PER_PAGE);

  if Result.Matches(STATUS_UNSUCCESSFUL, 'NtxPlaceHandle') then
  begin
    // Unfortunately, we closed the handle and cannot restore it
    Result.Location := 'NtxReplaceHandle';
    Result.Status := STATUS_HANDLE_REVOKED;
  end;
end;

function NtxReplaceHandleReopen;
var
  hxLocalHandle: IHandle;
  Info: TObjectBasicInformation;
begin
  // Reopen the handle into our process with the desired access
  Result := NtxDuplicateHandleFrom(hProcess, hRemoteHandle, hxLocalHandle,
    DUPLICATE_SAME_ACCESS, DesiredAccess);

  if not Result.IsSuccess then
    Exit;

  // Check which access rights we actually got. In some cases, (like ALPC
  // ports) we might receive a handle with an incomplete access mask.
  Result := NtxObject.Query(hxLocalHandle.Handle, ObjectBasicInformation, Info);

  if not Result.IsSuccess then
    Exit;

  if HasAny(DesiredAccess and not MAXIMUM_ALLOWED and not
    Info.GrantedAccess) then
  begin
    // Cannot complete the request without loosing some access rights
    Result.Location := 'NtxReplaceHandleReopen';
    Result.Status := STATUS_ACCESS_DENIED;
    Exit;
  end;

  // Replace the handle in the remote process
  Result := NtxReplaceHandle(hProcess, hRemoteHandle, hxLocalHandle.Handle,
    BitTest(Info.Attributes and OBJ_INHERIT));
end;

type
  // A context for a thread that will set handle flags remotely
  TFlagSetterContext = record
    NtSetInformationObject: function (
      Handle: THandle;
      ObjectInformationClass: TObjectInformationClass;
      ObjectInformation: Pointer;
      ObjectInformationLength: Cardinal
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}

    Handle: THandle;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}

    Info: TObjectHandleFlagInformation;
  end;
  PFlagSetterContext = ^TFlagSetterContext;

// The function for executing it in the context of target;
// Note: keep in sync with assembly below
function HandleFlagSetter(Context: PFlagSetterContext): NTSTATUS; stdcall;
begin
  Result := Context.NtSetInformationObject(Context.Handle,
    ObjectHandleFlagInformation, @Context.Info, SizeOf(Context.Info));
end;

const
  {$IFDEF Win64}
  // Note: keep in sync with the function above
  HandleFlagSetterAsm64: array [0..39] of Byte = (
    $48, $83, $EC, $28, $48, $89, $C8, $48, $8B, $48, $08, $BA, $04, $00, $00,
    $00, $4C, $8D, $40, $10, $41, $B9, $02, $00, $00, $00, $FF, $10, $48, $83,
    $C4, $28, $C3, $CC, $CC, $CC, $CC, $CC, $CC, $CC
  );
  {$ENDIF}

  // Note: keep in sync with the function above
  HandleFlagSetterAsm32: array [0..23] of Byte = (
    $55, $8B, $EC, $8B, $45, $08, $6A, $02, $8D, $50, $10, $52, $6A, $04, $8B,
    $50, $08, $52, $FF, $10, $5D, $C2, $04, $00
  );

function NtxSetFlagsHandleRemote;
var
  CodeRef: TMemory;
  TargetIsWoW64: Boolean;
  LocalMapping: IMemory<PFlagSetterContext>;
  RemoteMapping: IMemory;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Select suitable shellcode
{$IFDEF Win64}
  if not TargetIsWoW64 then
    CodeRef := TMemory.Reference(HandleFlagSetterAsm64)
  else
{$ENDIF}
    CodeRef := TMemory.Reference(HandleFlagSetterAsm32);

  // Create shared RX memory
  Result := RtlxMapSharedMemory(hxProcess, SizeOf(TFlagSetterContext) +
    CodeRef.Size, IMemory(LocalMapping), RemoteMapping, [mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  // Fill it in with shellcode and its parameters
  LocalMapping.Data.Handle := hObject;
  LocalMapping.Data.Info.Inherit := Inherit;
  LocalMapping.Data.Info.ProtectFromClose := ProtectFromClose;
  Move(CodeRef.Address^, LocalMapping.Offset(SizeOf(TFlagSetterContext))^,
    CodeRef.Size);

  // Find dependencies
  Result := RtlxFindKnownDllExport(ntdll, TargetIsWoW64,
    'NtSetInformationObject', @LocalMapping.Data.NtSetInformationObject);

  if not Result.IsSuccess then
    Exit;

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    hxProcess.Handle,
    'Remote::NtSetInformationObject',
    RemoteMapping.Offset(SizeOf(TFlagSetterContext)),
    CodeRef.Size,
    RemoteMapping.Data,
    THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH,
    Timeout,
    [RemoteMapping]
  );
end;

end.
