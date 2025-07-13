unit NtUtils.Objects;

{
  This modules provides functions for operations with handles that are common
  for all types of kernel objects.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntobapi, NtUtils, DelphiApi.Reflection;

type
  TObjectTypeInfo = record
    TypeName: String;
    [Aggregate] Native: TObjectTypeInformation;
  end;

// Close a kernel handle
function NtxClose(hObject: THandle): TNtxStatus;

type
  TAutoKernelObjectHelper = class helper for Auto
    // Capture ownership of a kernel handle
    class function CaptureHandle(hObject: THandle): IHandle; static;

    // Capture ownership of a kernel handle in another process
    class function CaptureRemoteHandle(
      [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
      hObject: THandle
    ): IHandle; static;
  end;

// Capture ownership of a kernel handle and validate it's within valid range
function NtxCaptureHandle(
  out hxObject: IHandle;
  hObject: THandle
): TNtxStatus;

// Capture ownership of a kernel handle in another process and validate range
function NtxCaptureRemoteHandle(
  out hxObject: IHandle;
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  hObject: THandle
): TNtxStatus;

// ------------------------------ Duplication ------------------------------ //

// Note: all handle duplication routines here support MAXIMUM_ALLOWED

// Duplicate a handle within the current process
function NtxDuplicateHandleLocal(
  const hxSource: IHandle;
  out hxNewHandle: IHandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags;
  Options: TDuplicateOptions;
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Duplicate a handle in-place within the current process
function NtxReopenHandle(
  var hxHandle: IHandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = DUPLICATE_SAME_ATTRIBUTES;
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Duplicate a handle between two processes
function NtxDuplicateHandle(
  [Access(PROCESS_DUP_HANDLE)] const hxSourceProcess: IHandle;
  hSourceHandle: THandle;
  [Access(PROCESS_DUP_HANDLE)] const hxTargetProcess: IHandle;
  out hTargetHandle: THandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags;
  Options: TDuplicateOptions;
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Check if a handle grants an access mask and reopen it if necessary
function NtxEnsureAccessHandle(
  var hxHandle: IHandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = DUPLICATE_SAME_ATTRIBUTES;
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Retrieve a handle from a process
function NtxDuplicateHandleFrom(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  hRemoteHandle: THandle;
  out hxLocalHandle: IHandle;
  DesiredAccess: TAccessMask = 0;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = DUPLICATE_SAME_ACCESS;
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Send a handle to a process
function NtxDuplicateHandleTo(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  const hxLocalHandle: IHandle;
  out hRemoteHandle: THandle;
  DesiredAccess: TAccessMask = 0;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = DUPLICATE_SAME_ACCESS;
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Send a handle to a process and then automatically close it later
function NtxDuplicateHandleToAuto(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  const hxLocalHandle: IHandle;
  out hxRemoteHandle: IHandle;
  DesiredAccess: TAccessMask = 0;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = DUPLICATE_SAME_ACCESS;
  [opt] AccessMaskType: Pointer = nil
): TNtxStatus;

// Close a handle in a process
function NtxCloseRemoteHandle(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  hRemoteHandle: THandle
): TNtxStatus;

// Close a handle in a process and ensure it's closed
function NtxCloseRemoteHandleWithCheck(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  hRemoteHandle: THandle
): TNtxStatus;

// ------------------------------ Information ------------------------------ //

type
  NtxObject = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(0)] const hxObject: IHandle;
      InfoClass: TObjectInformationClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Query variable-length object information
function NtxQueryObject(
  [Access(0)] const hxObject: IHandle;
  InfoClass: TObjectInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query name of an object
function NtxQueryNameObject(
  [Access(0)] const hxObject: IHandle;
  out Name: String
): TNtxStatus;

// Query object type information
function NtxQueryTypeObject(
  [Access(0)] const hxObject: IHandle;
  out Info: TObjectTypeInfo
): TNtxStatus;

// Set flags for a handle
function NtxSetFlagsHandle(
  [Access(0)] const hxObject: IHandle;
  Inherit: Boolean;
  ProtectFromClose: Boolean
): TNtxStatus;

// ------------------------------- Security -------------------------------- //

// Query security descriptor of a kernel object
function NtxQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] const hxObject: IHandle;
  Info: TSecurityInformation;
  out SD: ISecurityDescriptor
): TNtxStatus;

// Set security descriptor on a kernel object
function NtxSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] const hxObject: IHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

// ----------------------------- Access masks ------------------------------ //

type
  TObjectOpener = reference to function (
    [out] out hxObject: IHandle;
    [in] AccessMask: TAccessMask
  ): TNtxStatus;

// Determine what is the maximum access that we can get to an object
function RtlxComputeMaximumAccess(
  out MaximumAccess: TAccessMask;
  ObjectOpener: TObjectOpener;
  IsKernelObject: Boolean;
  FullAccessMask: TAccessMask;
  [opt] ReadOnlyAccessMask: TAccessMask
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.ntpebteb, Ntapi.ntdbg, Ntapi.ntseapi,
  Ntapi.ntrtl, DelphiUtils.AutoObjects, NtUtils.Objects.Compare;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}
{$WARN SYMBOL_PLATFORM OFF}

type
  TAutoHandle = class (TCustomAutoHandle)
    destructor Destroy; override;
  end;

  TAutoRemoteHandle = class (TCustomAutoHandle)
    FProcess: IHandle;
    destructor Destroy; override;
    constructor Capture(const hxProcess: IHandle; hObject: THandle);
  end;

destructor TAutoHandle.Destroy;
begin
  if (FHandle <> 0) and not FDiscardOwnership then
    NtxClose(FHandle);

  inherited;
end;

constructor TAutoRemoteHandle.Capture;
begin
  inherited Capture(hObject);
  FProcess := hxProcess;
end;

destructor TAutoRemoteHandle.Destroy;
begin
  if Assigned(FProcess) and (FHandle <> 0) and not FDiscardOwnership then
    NtxCloseRemoteHandle(FProcess, FHandle);

  inherited;
end;

class function TAutoKernelObjectHelper.CaptureHandle;
begin
  Result := TAutoHandle.Capture(hObject);
end;

class function TAutoKernelObjectHelper.CaptureRemoteHandle;
begin
  Result := TAutoRemoteHandle.Capture(hxProcess, hObject);
end;

function NtxClose;
var
  Flags: TObjectHandleFlagInformation;
begin
  Flags.Inherit := False;
  Flags.ProtectFromClose := False;

  // Clear handle protection
  NtSetInformationObject(hObject, ObjectHandleFlagInformation, @Flags,
    SizeOf(Flags));

  Result.Location := 'NtClose';
  Result.Status := NtClose(hObject);
end;

function NtxCaptureHandle;
begin
  if (hObject > 0) and (hObject <= MAX_HANDLE) then
  begin
    hxObject := Auto.CaptureHandle(hObject);
    Exit(NtxSuccess);
  end;

  Result.Location := 'NtxCaptureHandle';
  Result.Status := STATUS_INVALID_HANDLE;
end;

function NtxCaptureRemoteHandle;
begin
  if (hObject > 0) and (hObject <= MAX_HANDLE) and Assigned(hxProcess) then
  begin
    hxObject := Auto.CaptureRemoteHandle(hxProcess, hObject);
    Exit(NtxSuccess);
  end;

  Result.Location := 'NtxCaptureHandle';
  Result.Status := STATUS_INVALID_HANDLE;
end;

procedure RtlxpTryDuplicateAccess(
  const hxSource: IHandle;
  var AccumulatedAccess: TAccessMask;
  AccessToTry: TAccessMask
);
var
  BasicInfo: TObjectBasicInformation;
  hTemp: THandle;
  hxTemp: IHandle;
begin
  // Already tested?
  if HasAll(AccumulatedAccess, AccessToTry) then
    Exit;

  // Try to duplicate the handle for the requested access
  if not NT_SUCCESS(NtDuplicateObject(NtCurrentProcess, HandleOrDefault(
    hxSource), NtCurrentProcess, hTemp, AccessToTry, 0, 0)) then
    Exit;

  hxTemp := Auto.CaptureHandle(hTemp);

  // Record which rights we successfully got, in case they were filtered
  if NtxObject.Query(hxTemp, ObjectBasicInformation, BasicInfo).IsSuccess then
    AccumulatedAccess := AccumulatedAccess or BasicInfo.GrantedAccess;
end;

function NtxDuplicateHandleLocal;
var
  Basic: TObjectBasicInformation;
  ObjectType: TObjectTypeInfo;
  Status: NTSTATUS;
  hObject: THandle;
  AccumulatedAccess: TAccessMask;
  Bit: Integer;
begin
  if BitTest(DesiredAccess and MAXIMUM_ALLOWED) and
    not BitTest(Options and DUPLICATE_SAME_ACCESS) then
  begin
    // NtDuplicateObject does not support MAXIMUM_ALLOWED (it returns zero
    // access instead). We need to probe access masks to calculate how much
    // access we can return. Keep in mind that the caller can also combine
    // MAXIMUM_ALLOWED with other access rights which we must grant to succeed.

    // Determine the maximum possible access for handles of this type
    Result := NtxQueryTypeObject(hxSource, ObjectType);

    if not Result.IsSuccess then
      Exit;

    // Try full access first. If the desired access includes system security,
    // don't forget to include it as well.
    Status := NtDuplicateObject(NtCurrentProcess, HandleOrDefault(hxSource),
      NtCurrentProcess, hObject, (ObjectType.Native.ValidAccessMask or
        DesiredAccess) and not MAXIMUM_ALLOWED, HandleAttributes,
        Options and not DUPLICATE_CLOSE_SOURCE);

    if NT_SUCCESS(Status) then
    begin
      // Correct guess
      hxNewHandle := Auto.CaptureHandle(hObject);

      // Close the source if necessary
      if BitTest(Options and DUPLICATE_CLOSE_SOURCE) then
        NtDuplicateObject(NtCurrentProcess, HandleOrDefault(hxSource), 0,
          THandle(nil^), 0, 0, DUPLICATE_CLOSE_SOURCE);

      Exit(NtxSuccess);
    end;

    // Always include the required bits
    AccumulatedAccess := DesiredAccess;

    // Try all existing access at once
    if NtxObject.Query(hxSource, ObjectBasicInformation, Basic).IsSuccess then
      RtlxpTryDuplicateAccess(hxSource, AccumulatedAccess, Basic.GrantedAccess);

    // Try read and execute groups in bulk
    RtlxpTryDuplicateAccess(hxSource, AccumulatedAccess,
      ObjectType.Native.GenericMapping.GenericRead);
    RtlxpTryDuplicateAccess(hxSource, AccumulatedAccess,
      ObjectType.Native.GenericMapping.GenericExecute);

    // Try each optional valid access mask bit
    for Bit := 0 to 24 do
      RtlxpTryDuplicateAccess(hxSource, AccumulatedAccess,
        ObjectType.Native.ValidAccessMask and (1 shl Bit));

    // Replace maximum allowed with the calculated value
    DesiredAccess := AccumulatedAccess and not MAXIMUM_ALLOWED;
  end;

  // Finally, try all collected access at once
  Result.Location := 'NtDuplicateObject';

  if not BitTest(Options and DUPLICATE_SAME_ACCESS) then
  begin
    Result.LastCall.OpensForAccess(DesiredAccess);

    if Assigned(AccessMaskType) then
      Result.LastCall.AccessMaskType := AccessMaskType;
  end;

  Result.Status := NtDuplicateObject(NtCurrentProcess, HandleOrDefault(
    hxSource), NtCurrentProcess, hObject, DesiredAccess, HandleAttributes,
    Options);

  if Result.IsSuccess then
    hxNewHandle := Auto.CaptureHandle(hObject);
end;

function NtxReopenHandle;
var
  hxSourceHandle: IHandle;
begin
  hxSourceHandle := hxHandle;
  Result := NtxDuplicateHandleLocal(hxSourceHandle, hxHandle, DesiredAccess,
    HandleAttributes, Options, AccessMaskType);
end;

function NtxDuplicateHandle;
var
  hxLocalHandle: IHandle;
  hLocalHandle: THandle;
  ReopenOptions: TDuplicateOptions;
begin
  Result.Location := 'NtDuplicateObject';

  if not BitTest(Options and DUPLICATE_SAME_ACCESS) then
  begin
    Result.LastCall.OpensForAccess(DesiredAccess);

    if Assigned(AccessMaskType) then
      Result.LastCall.AccessMaskType := AccessMaskType;
  end;

  if (HandleOrDefault(hxSourceProcess) <> NtCurrentProcess) or
    (HandleOrDefault(hxTargetProcess) <> NtCurrentProcess) then
    Result.LastCall.Expects<TProcessAccessMask>(PROCESS_DUP_HANDLE);

  // NtDuplicateObject does not support MAXIMUM_ALLOWED (it returns zero access
  // instead), so we make a local handle copy and probe access masks on it to
  // calculate how much access we can return. Keep in mind that the caller can
  // combine MAXIMUM_ALLOWED with other access rights which we must grant to
  // succeed.

  if BitTest(DesiredAccess and MAXIMUM_ALLOWED) and
    not BitTest(Options and DUPLICATE_SAME_ACCESS) then
  begin
    if HandleOrDefault(hxSourceProcess) <> NtCurrentProcess then
    begin
      // Make a local handle copy to use for probing rights
      Result.Status := NtDuplicateObject(HandleOrDefault(hxSourceProcess),
        hSourceHandle, NtCurrentProcess, hLocalHandle, 0, 0,
        DUPLICATE_SAME_ACCESS or (Options and (DUPLICATE_SAME_ATTRIBUTES or
        DUPLICATE_CLOSE_SOURCE)));

      if not Result.IsSuccess then
        Exit;

      // We own the local copy now
      hxLocalHandle := Auto.CaptureHandle(hLocalHandle);
    end
    else
      hxLocalHandle := Auto.RefHandle(hSourceHandle);

    if HandleOrDefault(hxTargetProcess) <> NtCurrentProcess then
      ReopenOptions := Options and DUPLICATE_SAME_ATTRIBUTES
    else
      ReopenOptions := Options;

    // Obtain the maximum allowed access on the handle
    Result := NtxReopenHandle(hxLocalHandle, DesiredAccess, HandleAttributes,
      ReopenOptions, AccessMaskType);

    if not Result.IsSuccess then
      Exit;

    if HandleOrDefault(hxTargetProcess) <> NtCurrentProcess then
    begin
      // Send the handle to the target
      Result.Location := 'NtDuplicateObject';
      Result.LastCall.Expects<TProcessAccessMask>(PROCESS_DUP_HANDLE);
      Result.Status := NtDuplicateObject(NtCurrentProcess, hxLocalHandle.Handle,
        HandleOrDefault(hxTargetProcess), hTargetHandle, 0, HandleAttributes,
        DUPLICATE_SAME_ACCESS or (Options and
        (DUPLICATE_SAME_ATTRIBUTES or DUPLICATE_NO_RIGHTS_UPGRADE)));
    end
    else
    begin
      // Transfer local ownerhip over the handle with the expanded access
      hTargetHandle := hxLocalHandle.Handle;
      hxLocalHandle.DiscardOwnership;
    end;
  end
  else
  begin
    // Forward simple request to the system
    Result.Status := NtDuplicateObject(HandleOrDefault(hxSourceProcess),
      hSourceHandle, HandleOrDefault(hxTargetProcess), hTargetHandle,
      DesiredAccess, HandleAttributes, Options);
  end;
end;

function NtxEnsureAccessHandle;
var
  Info: TObjectBasicInformation;
  ObjectType: TObjectTypeInfo;
begin
  // Expand generic rights
  if HasAny(DesiredAccess and (GENERIC_RIGHTS_ALL or MAXIMUM_ALLOWED)) then
  begin
    Result := NtxQueryTypeObject(hxHandle, ObjectType);

    if not Result.IsSuccess then
      Exit;

    RtlMapGenericMask(DesiredAccess, ObjectType.Native.GenericMapping);
  end;

  // Determine existing access
  Result := NtxObject.Query(hxHandle, ObjectBasicInformation, Info);

  if not Result.IsSuccess then
    Exit;

  // Full access satisfies MAXIMUM_ALLOWED
  if BitTest(DesiredAccess and MAXIMUM_ALLOWED) and HasAll(Info.GrantedAccess,
    ObjectType.Native.ValidAccessMask or DesiredAccess and not MAXIMUM_ALLOWED)
    then
    Exit;

  // Check fixed granted access
  if HasAll(Info.GrantedAccess, DesiredAccess) then
    Exit;

  // Reopen
  Result := NtxReopenHandle(hxHandle, DesiredAccess, HandleAttributes,
    Options, AccessMaskType);
end;

function NtxDuplicateHandleFrom;
var
  hLocalHandle: THandle;
begin
  Result := NtxDuplicateHandle(hxProcess, hRemoteHandle, NtxCurrentProcess,
    hLocalHandle, DesiredAccess, HandleAttributes, Options, AccessMaskType);

  if Result.IsSuccess then
    hxLocalHandle := Auto.CaptureHandle(hLocalHandle);
end;

function NtxDuplicateHandleTo;
begin
  Result := NtxDuplicateHandle(NtxCurrentProcess, HandleOrDefault(
    hxLocalHandle), hxProcess, hRemoteHandle, DesiredAccess, HandleAttributes,
    Options, AccessMaskType);
end;

function NtxDuplicateHandleToAuto;
var
  hRemoteHandle: THandle;
begin
  Result := NtxDuplicateHandle(NtxCurrentProcess, HandleOrDefault(
    hxLocalHandle), hxProcess, hRemoteHandle, DesiredAccess, HandleAttributes,
    Options, AccessMaskType);

  if Result.IsSuccess then
    hxRemoteHandle := Auto.CaptureRemoteHandle(hxProcess, hRemoteHandle);
end;

function NtxCloseRemoteHandle;
begin
  Result.Location := 'NtDuplicateObject';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_DUP_HANDLE);
  Result.Status := NtDuplicateObject(HandleOrDefault(hxProcess), hRemoteHandle,
    0, THandle(nil^), 0, 0, DUPLICATE_CLOSE_SOURCE);
end;

function NtxCloseRemoteHandleWithCheck;
var
  hxLocalCopyA, hxLocalCopyB: IHandle;
  Equal: Boolean;
begin
  // A DUPLICATE_CLOSE_SOURCE request might succeed without actually closing
  // the handle. It happens when the handle is protected via a flag
  // (OBJ_PROTECT_CLOSE) or a kernel callback (such as actively used window
  // station and desktop handles). To see if it happens, we check if the
  // handle is still there.

  // Make a local copy and close the remote handle
  Result := NtxDuplicateHandleFrom(hxProcess, hRemoteHandle, hxLocalCopyA, 0, 0,
    DUPLICATE_SAME_ACCESS or DUPLICATE_CLOSE_SOURCE);

  if not Result.IsSuccess then
    Exit;

  // Try to copy the handle again. This time, without closing (in case the slot
  // was reused)
  Result := NtxDuplicateHandleFrom(hxProcess, hRemoteHandle, hxLocalCopyB, 0, 0,
    DUPLICATE_SAME_ACCESS);

  if Result.IsSuccess then
  begin
    // If the second copy succeeded, either the first one failed to close the
    // handle or the slot got reused between calls. Verify what happened by
    // comparing the objects.
    Result := NtxCompareObjects(Equal, hxLocalCopyA, hxLocalCopyB);

    if not Result.IsSuccess then
      Exit;

    if not Equal then
    begin
      Result.Location := 'NtxCloseRemoteHandleWithCheck';
      Result.Status := STATUS_HANDLE_NOT_CLOSABLE;
    end;
  end
  else if Result.Status = STATUS_INVALID_HANDLE then
    Result := NtxSuccess; // No handle anymore
end;

class function NtxObject.Query<T>;
begin
  Result.Location := 'NtQueryObject';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.Status := NtQueryObject(HandleOrDefault(hxObject), InfoClass, @Buffer,
    SizeOf(Buffer), nil);
end;

function NtxQueryObject;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryObject';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryObject(HandleOrDefault(hxObject), InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxQueryNameObject;
var
  xMemory: IMemory<PNtUnicodeString>;
begin
  Result := NtxQueryObject(hxObject, ObjectNameInformation, IMemory(xMemory));

  if Result.IsSuccess then
    Name := xMemory.Data.ToString;
end;

function NtxQueryTypeObject;
var
  xMemory: IMemory<PObjectTypeInformation>;
begin
  Result := NtxQueryObject(hxObject, ObjectTypeInformation, IMemory(xMemory),
    SizeOf(TObjectTypeInformation));

  if not Result.IsSuccess then
    Exit;

  Info.TypeName := xMemory.Data.TypeName.ToString;
  Info.Native := xMemory.Data^;
  Info.Native.TypeName.Buffer := PWideChar(Info.TypeName);
end;

function NtxSetFlagsHandle;
var
  Info: TObjectHandleFlagInformation;
begin
  Info.Inherit := Inherit;
  Info.ProtectFromClose := ProtectFromClose;

  Result.Location := 'NtSetInformationObject';
  Result.LastCall.UsesInfoClass(ObjectHandleFlagInformation, icSet);

  Result.Status := NtSetInformationObject(HandleOrDefault(hxObject),
    ObjectHandleFlagInformation, @Info, SizeOf(Info));
end;

function NtxQuerySecurityObject;
var
  Buffer: IMemory absolute SD;
  Required: Cardinal;
begin
  Result.Location := 'NtQuerySecurityObject';
  Result.LastCall.Expects(SecurityReadAccess(Info));

  Buffer := Auto.AllocateDynamic(0);
  repeat
    Required := 0;
    Result.Status := NtQuerySecurityObject(HandleOrDefault(hxObject), Info,
      Buffer.Data, Buffer.Size, Required);
  until not NtxExpandBufferEx(Result, Buffer, Required, nil);
end;

function NtxSetSecurityObject;
begin
  Result.Location := 'NtSetSecurityObject';
  Result.LastCall.Expects(SecurityWriteAccess(Info));
  Result.Status := NtSetSecurityObject(HandleOrDefault(hxObject), Info, SD);
end;

{ Access masks }

function RtlxpRecordAccess(
  const hxObject: IHandle;
  var MaximumAccess: TAccessMask;
  var BitsToTest: TAccessMask
): TNtxStatus;
var
  Info: TObjectBasicInformation;
begin
  Result := NtxObject.Query(hxObject, ObjectBasicInformation, Info);

  if Result.IsSuccess then
  begin
    MaximumAccess := MaximumAccess or Info.GrantedAccess;
    BitsToTest := BitsToTest and not Info.GrantedAccess;
  end;
end;

function RtlxComputeMaximumAccess;
var
  hxObject: IHandle;
  BitsToTest: TAccessMask;
  i: Byte;
begin
  MaximumAccess := 0;
  BitsToTest := FullAccessMask;

  // Try MAXIMUM_ALLOWED on kernel objects because we can query the results
  if IsKernelObject and ObjectOpener(hxObject, MAXIMUM_ALLOWED).IsSuccess then
    Result := RtlxpRecordAccess(hxObject, MaximumAccess, BitsToTest);

  // Try all read-only rights at once
  if HasAny(BitsToTest and ReadOnlyAccessMask) and
    ObjectOpener(hxObject, BitsToTest and ReadOnlyAccessMask).IsSuccess then
  begin
    // Test for externally-filtered rights when possible
    if IsKernelObject then
      Result := RtlxpRecordAccess(hxObject, MaximumAccess, BitsToTest)
    else
      MaximumAccess := MaximumAccess or (BitsToTest and ReadOnlyAccessMask);
        BitsToTest := BitsToTest and not ReadOnlyAccessMask;
  end;

  // Test bits one-by-one
  for i := 0 to 31 do
  begin
    if not BitTest(BitsToTest and (1 shl i)) then
      Continue;

    Result := ObjectOpener(hxObject, 1 shl i);

    if not Result.IsSuccess then
      Continue;

    if IsKernelObject then
      Result := RtlxpRecordAccess(hxObject, MaximumAccess, BitsToTest)
    else
    begin
      // Believe that success indicates granted (and not filtered) access
      // because we cannot verify it in general case
      MaximumAccess := MaximumAccess or (1 shl i);
      BitsToTest := BitsToTest and not (1 shl i);
    end;
  end;

  if MaximumAccess <> 0 then
    Result := NtxSuccess;
end;

end.
