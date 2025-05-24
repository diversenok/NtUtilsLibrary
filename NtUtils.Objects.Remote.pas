unit NtUtils.Objects.Remote;

{
  This modules provides extended operation on handles in context of other
  processes.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, NtUtils, NtUtils.Shellcode;

const
  // Access masks for annotations
  PROCESS_PLACE_HANDLE = PROCESS_DUP_HANDLE or PROCESS_QUERY_LIMITED_INFORMATION;
  PROCESS_SET_HANDLE_FLAGS = PROCESS_REMOTE_EXECUTE;

type
  TNtxPlaceHandleOptions = set of (
    phInheritable,
    phNoRightsUpgrade
  );

// Send a handle to a process and make sure it ends up with a particular value
function NtxPlaceHandle(
  [Access(PROCESS_PLACE_HANDLE)] const hxProcess: IHandle;
  hRemoteHandle: THandle;
  const hxLocalHandle: IHandle;
  Options: TNtxPlaceHandleOptions = [];
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Replace a handle in a process with another handle
function NtxReplaceHandle(
  [Access(PROCESS_PLACE_HANDLE)] const hxProcess: IHandle;
  hRemoteHandle: THandle;
  const hxLocalHandle: IHandle;
  Options: TNtxPlaceHandleOptions = [];
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Reopen a handle in a process with a different access
function NtxReplaceHandleReopen(
  [Access(PROCESS_PLACE_HANDLE)] const hxProcess: IHandle;
  hRemoteHandle: THandle;
  DesiredAccess: TAccessMask;
  Options: TNtxPlaceHandleOptions = [];
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Set flags for a handles in a process
function NtxSetFlagsHandleRemote(
  [Access(PROCESS_SET_HANDLE_FLAGS)] const hxProcess: IHandle;
  hRemoteHandle: THandle;
  Inherit: Boolean;
  ProtectFromClose: Boolean;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntobapi, ntapi.ntpsapi, Ntapi.ntpebteb, Ntapi.ntmmapi,
  NtUtils.Objects, NtUtils.Processes.Info, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxPlaceHandle;
const
  HANDLE_SLOTS_PER_PAGE: array [Boolean] of Cardinal = (
    PAGE_SIZE div (SizeOf(Pointer) * 2), // Native (32- or 64-bit OS)
    PAGE_SIZE div (SizeOf(UInt64) * 2)   // Under WoW64 (64-bit OS)
  );
  HANDLE_ATTRIBUTES: array [Boolean] of TObjectAttributesFlags = (0,
    OBJ_INHERIT);
  DUPLICATE_OPTIONS: array [Boolean] of TDuplicateOptions = (0,
    DUPLICATE_NO_RIGHTS_UPGRADE);
var
  Slots: TArray<IHandle>;
  Stats: TProcessHandleInformation;
  RequiredHighWatermark: Cardinal;
  i: Integer;
begin
  // The value must be dividable by 4 and not be the first slot on the page
  if (hRemoteHandle and $3 <> 0) or
    (hRemoteHandle mod (4 * HANDLE_SLOTS_PER_PAGE[RtlIsWoW64]) = 0) then
  begin
    Result.Location := 'NtxPlaceHandle';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Stats := Default(TProcessHandleInformation);

  // Determine the handle statistics for the target process
  Result := NtxProcess.Query(hxProcess, ProcessHandleInformation, Stats);

  if not Result.IsSuccess then
    Exit;

  if Stats.HandleCountHighWatermark < Stats.HandleCount then
  begin
    // Should not happen
    Result.Location := 'NtxPlaceHandle';
    Result.Status := STATUS_ASSERTION_FAILURE;
    Exit;
  end;

  // Determine the number of handles below and including the value
  RequiredHighWatermark := hRemoteHandle div 4 -
    hRemoteHandle div (4 * HANDLE_SLOTS_PER_PAGE[RtlIsWoW64]);

  // If the process ever had handles above the one we need, it might reuse them
  // first. So choose the maximum of the two watermarks
  if RequiredHighWatermark < Stats.HandleCountHighWatermark then
    RequiredHighWatermark := Stats.HandleCountHighWatermark;

  // Round it up to completelely fill the last page with handles
  RequiredHighWatermark := RequiredHighWatermark or
    (HANDLE_SLOTS_PER_PAGE[RtlIsWoW64] - 1) + 1;

  // We need that maximum number of handles to guarantee occupying the slot
  SetLength(Slots, RequiredHighWatermark - Stats.HandleCount);

  for i := High(Slots) downto Low(Slots) do
  begin
    // Send the handle to the target (IAutoReleasable will close them later)
    Result := NtxDuplicateHandleToAuto(hxProcess, hxLocalHandle, Slots[i], 0,
      HANDLE_ATTRIBUTES[phInheritable in Options], DUPLICATE_SAME_ACCESS or
      DUPLICATE_OPTIONS[phNoRightsUpgrade in Options], AccessMaskType);

    if not Result.IsSuccess then
      Exit;

    if Slots[i].Handle = hRemoteHandle then
    begin
      // This is the right slot; do not close it
      Slots[i].AutoRelease := False;
      Exit;
    end;
  end;

  // Unable to complete within our limits
  Result.Location := 'NtxPlaceHandle';
  Result.Status := STATUS_UNSUCCESSFUL;
end;

function NtxReplaceHandle;
begin
  // Start with closing a remote handle to free its slot. Use verbose checking.
  Result := NtxCloseRemoteHandleWithCheck(hxProcess, hRemoteHandle);

  if not Result.IsSuccess then
    Exit;

  // Send the new handle to a occupy the same spot
  Result := NtxPlaceHandle(hxProcess, hRemoteHandle, hxLocalHandle, Options,
    AccessMaskType);

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
begin
  // Copy the handle into our process with the specified access
  Result := NtxDuplicateHandleFrom(hxProcess, hRemoteHandle, hxLocalHandle,
    DesiredAccess, 0, 0, AccessMaskType);

  if not Result.IsSuccess then
    Exit;

  // Replace the handle in the remote process
  Result := NtxReplaceHandle(hxProcess, hRemoteHandle, hxLocalHandle, Options,
    AccessMaskType);
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
  Result := RtlxAssertWoW64Compatible(hxProcess, TargetIsWoW64);

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
  LocalMapping.Data.Handle := hRemoteHandle;
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
    hxProcess,
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
