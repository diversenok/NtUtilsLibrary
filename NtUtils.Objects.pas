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
    [Aggregate] Other: TObjectTypeInformation;
  end;

// Close a kernel handle
function NtxClose(hObject: THandle): TNtxStatus;

type
  TAutoKernelObjectHelper = class helper for Auto
    // Capture ownership of a kernel handle
    class function CaptureHandle(hObject: THandle): IHandle; static;
  end;

// Capture ownership of a kernel handle and validate it's within valid range
function NtxCaptureHandle(
  out hxObject: IHandle;
  hObject: THandle
): TNtxStatus;

// ------------------------------ Duplication ------------------------------ //

// Duplicate a handle to an object. Supports MAXIMUM_ALLOWED.
function NtxDuplicateHandle(
  [Access(PROCESS_DUP_HANDLE)] const SourceProcessHandle: IHandle;
  SourceHandle: THandle;
  [Access(PROCESS_DUP_HANDLE)] const TargetProcessHandle: IHandle;
  out TargetHandle: THandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags;
  Options: TDuplicateOptions
): TNtxStatus;

// Duplicate a handle locally
function NtxDuplicateHandleLocal(
  SourceHandle: THandle;
  out hxNewHandle: IHandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = 0
): TNtxStatus;

// Reopen a local handle
function NtxReopenHandle(
  var hxHandle: IHandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = DUPLICATE_SAME_ATTRIBUTES
): TNtxStatus;

// Check if a handle grants an access mask and reopen it if necessary
function NtxEnsureAccessHandle(
  var hxHandle: IHandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = DUPLICATE_SAME_ATTRIBUTES
): TNtxStatus;

// Retrieve a handle from a process
function NtxDuplicateHandleFrom(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  hRemoteHandle: THandle;
  out hxLocalHandle: IHandle;
  Options: TDuplicateOptions = DUPLICATE_SAME_ACCESS;
  DesiredAccess: TAccessMask = 0;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Send a handle to a process
function NtxDuplicateHandleTo(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  hLocalHandle: THandle;
  out hRemoteHandle: THandle;
  Options: TDuplicateOptions = DUPLICATE_SAME_ACCESS;
  DesiredAccess: TAccessMask = 0;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Send a handle to a process and then automatically close it later
function NtxDuplicateHandleToAuto(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  hLocalHandle: THandle;
  out hxRemoteHandle: IHandle;
  Options: TDuplicateOptions = DUPLICATE_SAME_ACCESS;
  DesiredAccess: TAccessMask = 0;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Closes a handle in a process
function NtxCloseRemoteHandle(
  [Access(PROCESS_DUP_HANDLE)] const hxProcess: IHandle;
  hObject: THandle;
  DoubleCheck: Boolean = False
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
  Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.ntpebteb, Ntapi.ntdbg,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}
{$WARN SYMBOL_PLATFORM OFF}

type
  TAutoHandle = class(TCustomAutoHandle, IHandle, IAutoReleasable)
  protected
    procedure Release; override;
  end;

  TAutoRemoteHandle = class(TCustomAutoHandle, IHandle, IAutoReleasable)
  protected
    FProcess: IHandle;
    procedure Release; override;
  public
    constructor Capture(const hxProcess: IHandle; hObject: THandle);
  end;

procedure TAutoHandle.Release;
begin
  if FHandle <> 0 then
    NtxClose(FHandle);

  FHandle := 0;
  inherited;
end;

constructor TAutoRemoteHandle.Capture;
begin
  inherited Capture(hObject);
  FProcess := hxProcess;
end;

procedure TAutoRemoteHandle.Release;
begin
  if (FHandle <> 0) and Assigned(FProcess) then
    NtxCloseRemoteHandle(FProcess, FHandle);

  FHandle := 0;
  inherited;
end;

class function TAutoKernelObjectHelper.CaptureHandle;
begin
  Result := TAutoHandle.Capture(hObject);
end;

function NtxClose;
var
  Flags: TObjectHandleFlagInformation;
begin
  if (hObject = 0) or (hObject > MAX_HANDLE) then
  begin
    Result.Location := 'NtxClose';
    Result.Status := STATUS_INVALID_HANDLE
  end
  else
  try
    Flags.Inherit := False;
    Flags.ProtectFromClose := False;

    // Clear handle protection
    Result.Location := 'NtSetInformationObject';
    Result.Status := NtSetInformationObject(hObject,
      ObjectHandleFlagInformation, @Flags, SizeOf(Flags));

    if not Result.IsSuccess then
      Exit;

    // Note: NtClose might throw exceptions
    Result.Location := 'NtClose';
    Result.Status := NtClose(hObject);
  except
    Result.Location := 'NtxClose';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
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

function NtxDuplicateHandle;
var
  hSameAccess, hTemp: THandle;
  objTypeInfo: TObjectTypeInfo;
  Info: TObjectBasicInformation;
  handleInfo: TObjectHandleFlagInformation;
  bit: Integer;
label
  MaskExpandingDone, Cleanup;
begin
  // NtDuplicateObject does not support MAXIMUM_ALLOWED (it returns zero
  // access instead). We will implement this feature by probing additional
  // access masks. Note, that the caller can also combine MAXIMUM_ALLOWED with
  // other access rights which we must grant to succeed.

  Result.Location := 'NtDuplicateObject';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_DUP_HANDLE);

  if BitTest(DesiredAccess and MAXIMUM_ALLOWED) and not
    BitTest(Options and DUPLICATE_SAME_ACCESS) then
  begin
    // To prevent race conditions we duplicate the handle to the current process
    // with the same access and attributes to perform all further probing on it.
    // This operation might close the source handle if DUPLICATE_CLOSE_SOURCE is
    // specified. Be aware that we might get a handle that is protected from
    // closing, since the caller might have used DUPLICATE_SAME_ATTRIBUTES or
    // OBJ_PROTECT_CLOSE.

    Result.Status := NtDuplicateObject(HandleOrDefault(SourceProcessHandle),
      SourceHandle, NtCurrentProcess, hSameAccess, 0, HandleAttributes,
      Options or DUPLICATE_SAME_ACCESS);

    // If we fail to duplicate it even with the same access, we are finished.
    if not Result.IsSuccess then
      Exit;

    // Query which access rights are meaningful for this type of object.
    // Fallback to a full mask on failure.
    if not NtxQueryTypeObject(Auto.RefHandle(hSameAccess),
      objTypeInfo).IsSuccess then
      objTypeInfo.Other.ValidAccessMask := SPECIFIC_RIGHTS_ALL or
        STANDARD_RIGHTS_ALL;

    // Start probing. Try full access first.
    Result.Status := NtDuplicateObject(NtCurrentProcess, hSameAccess,
      NtCurrentProcess, hTemp, objTypeInfo.Other.ValidAccessMask, 0, 0);

    // Was the guess correct?
    if Result.IsSuccess then
    begin
      DesiredAccess := objTypeInfo.Other.ValidAccessMask;
      NtxClose(hTemp);
      goto MaskExpandingDone;
    end;

    // Did something else happen? Access denied is fine, we can try less access.
    if Result.Status <> STATUS_ACCESS_DENIED then
      goto Cleanup;

    // The caller might combine MAXIMUM_ALLOWED with other access rights
    DesiredAccess := DesiredAccess and not MAXIMUM_ALLOWED;

    // In this case, we need to check whether we can satisfy the minimum
    // requirements which must include them.
    if DesiredAccess <> 0 then
    begin
      Result.Status := NtDuplicateObject(NtCurrentProcess, hSameAccess,
        NtCurrentProcess, hTemp, DesiredAccess, 0, 0);

      if Result.IsSuccess then
        NtxClose(hTemp)
      else
        goto Cleanup;
    end;

    // Include whatever access we already have based on DUPLICATE_SAME_ACCESS
    if NtxObject.Query(Auto.RefHandle(hSameAccess), ObjectBasicInformation,
      Info).IsSuccess then
      DesiredAccess := DesiredAccess or Info.GrantedAccess and
        not ACCESS_SYSTEM_SECURITY;

    // Try each one standard or specific access right that is not granted yet
    for bit := 0 to 31 do
      if BitTest((1 shl bit) and objTypeInfo.Other.ValidAccessMask
        and not DesiredAccess) then
        if NT_SUCCESS(NtDuplicateObject(NtCurrentProcess, hSameAccess,
          NtCurrentProcess, hTemp, 1 shl bit, 0, 0)) then
        begin
          // Yes, this access can be granted, add it
          DesiredAccess := DesiredAccess or (1 shl bit);
          NtxClose(hTemp);
        end;

  MaskExpandingDone:

    // Finally, duplicate the handle to the target process with the requested
    // attributes and expanded maximum access
    Result.Status := NtDuplicateObject(NtCurrentProcess, hSameAccess,
      HandleOrDefault(TargetProcessHandle), TargetHandle, DesiredAccess,
      HandleAttributes, Options and not DUPLICATE_CLOSE_SOURCE);

  Cleanup:

    // Make sure our copy is closable by clearing protection
    if BitTest(Options and DUPLICATE_SAME_ATTRIBUTES) or
      BitTest(HandleAttributes and OBJ_PROTECT_CLOSE) then
    begin
      handleInfo.Inherit := False;
      handleInfo.ProtectFromClose := False;

      NtSetInformationObject(hSameAccess, ObjectHandleFlagInformation,
        @handleInfo, SizeOf(handleInfo));
    end;

    // Close local copy
    NtxClose(hSameAccess);
  end
  else
  begin
    // Usual case
    Result.Status := NtDuplicateObject(HandleOrDefault(SourceProcessHandle),
      SourceHandle, HandleOrDefault(TargetProcessHandle), TargetHandle,
      DesiredAccess, HandleAttributes, Options);
  end;
end;

function NtxDuplicateHandleLocal;
var
  hNewHandle: THandle;
begin
  Result := NtxDuplicateHandle(NtxCurrentProcess, SourceHandle,
    NtxCurrentProcess, hNewHandle, DesiredAccess, HandleAttributes, Options);

  if Result.IsSuccess then
    hxNewHandle := Auto.CaptureHandle(hNewHandle);
end;

function NtxReopenHandle;
var
  hNewHandle: THandle;
begin
  Result := NtxDuplicateHandle(NtxCurrentProcess, hxHandle.Handle,
    NtxCurrentProcess, hNewHandle, DesiredAccess, HandleAttributes, Options and
      not DUPLICATE_CLOSE_SOURCE);

  // Swap the handle with the new one
  if Result.IsSuccess then
    hxHandle := Auto.CaptureHandle(hNewHandle);
end;

function NtxEnsureAccessHandle;
var
  Info: TObjectBasicInformation;
begin
  if HasAny(DesiredAccess and not
    (SPECIFIC_RIGHTS_ALL or STANDARD_RIGHTS_ALL or ACCESS_SYSTEM_SECURITY)) then
  begin
    // Cannot process generic and maximum allowed rights here
    Result.Location := 'NtxEnsureAccessHandle';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Determine existing access
  Result := NtxObject.Query(hxHandle, ObjectBasicInformation, Info);

  if not Result.IsSuccess then
    Exit;

  // Duplicate the handle if necessary
  if (Info.GrantedAccess and DesiredAccess) <> DesiredAccess then
    Result := NtxReopenHandle(hxHandle, DesiredAccess, HandleAttributes,
      Options);
end;

function NtxDuplicateHandleFrom;
var
  hLocalHandle: THandle;
begin
  Result := NtxDuplicateHandle(hxProcess, hRemoteHandle, NtxCurrentProcess,
    hLocalHandle, DesiredAccess, HandleAttributes, Options);

  if Result.IsSuccess then
    hxLocalHandle := Auto.CaptureHandle(hLocalHandle);
end;

function NtxDuplicateHandleTo;
begin
  Result := NtxDuplicateHandle(NtxCurrentProcess, hLocalHandle, hxProcess,
    hRemoteHandle, DesiredAccess, HandleAttributes, Options);
end;

function NtxDuplicateHandleToAuto;
var
  hRemoteHandle: THandle;
begin
  Result := NtxDuplicateHandle(NtxCurrentProcess, hLocalHandle, hxProcess,
    hRemoteHandle, DesiredAccess, HandleAttributes, Options);

  if Result.IsSuccess then
    hxRemoteHandle := TAutoRemoteHandle.Capture(hxProcess, hRemoteHandle);
end;

function NtxCloseRemoteHandle;
var
  hxTemp: IHandle;
begin
  // Duplicate the handle closing the source and discarding the result
  Result.Location := 'NtDuplicateObject';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_DUP_HANDLE);
  Result.Status := NtDuplicateObject(HandleOrDefault(hxProcess), hObject, 0,
    THandle(nil^), 0, 0, DUPLICATE_CLOSE_SOURCE);

  if DoubleCheck and Result.IsSuccess then
  begin
    // We need to make sure that the previous operation actually closed the
    // handle. Might happen that the system does not allow this action (i.e.
    // this handle is a current desktop for one of the threads), but still
    // returns success.
    Result := NtxDuplicateHandleFrom(hxProcess, hObject, hxTemp);

    // We expect the operation to fail since the first call was supposed to
    // close it.
    if Result.IsSuccess then
    begin
      Result.Location := 'NtxCloseRemoteHandle';
      Result.Status := STATUS_HANDLE_NOT_CLOSABLE;
    end
    else if Result.Status = STATUS_INVALID_HANDLE then
      // The handle was closed successfully
      Result := NtxSuccess;

    // If something else went wrong, forward the error
  end;
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
  Info.Other := xMemory.Data^;
  Info.Other.TypeName.Buffer := PWideChar(Info.TypeName);
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
