unit NtUtils.Objects;

{
  This modules provides functions for operations with handles that are common
  for all types of kernel objects.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntobapi, NtUtils, DelphiUtils.AutoObject,
  DelphiApi.Reflection;

type
  // A wrapper for handles to kernel objects that require NtClose to free them
  TAutoHandle = class(TCustomAutoHandle, IHandle)
    procedure Release; override;
  end;

  TObjectBasicInformaion = Ntapi.ntobapi.TObjectBasicInformaion;

  TObjectTypeInfo = record
    TypeName: String;
    [Aggregate] Other: TObjectTypeInformation;
  end;

// Close a handle safely and set it to zero
function NtxSafeClose(var hObject: THandle): TNtxStatus;

// ------------------------------ Duplication ------------------------------ //

// Duplicate a handle to an object. Supports MAXIMUM_ALLOWED.
function NtxDuplicateHandle(
  SourceProcessHandle: THandle;
  SourceHandle: THandle;
  TargetProcessHandle: THandle;
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

// Reopen a local handle. Works with exclusive handles as well.
function NtxReopenHandle(
  var hxHandle: IHandle;
  DesiredAccess: TAccessMask;
  HandleAttributes: TObjectAttributesFlags = 0;
  Options: TDuplicateOptions = 0
): TNtxStatus;

// Retrieve a handle from a process
function NtxDuplicateHandleFrom(
  hProcess: THandle;
  hRemoteHandle: THandle;
  out hxLocalHandle: IHandle;
  Options: TDuplicateOptions = DUPLICATE_SAME_ACCESS;
  DesiredAccess: TAccessMask = 0;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Send a handle to a process
function NtxDuplicateHandleTo(
  hProcess: THandle;
  hLocalHandle: THandle;
  out hRemoteHandle: THandle;
  Options: TDuplicateOptions = DUPLICATE_SAME_ACCESS;
  DesiredAccess: TAccessMask = 0;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

// Closes a handle in a process
function NtxCloseRemoteHandle(
  hProcess: THandle;
  hObject: THandle;
  DoubleCheck: Boolean = False
): TNtxStatus;

// ------------------------------ Information ------------------------------ //

// Query variable-length object information
function NtxQueryObject(
  hObject: THandle;
  InfoClass: TObjectInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query name of an object
function NtxQueryNameObject(
  hObject: THandle;
  out Name: String
): TNtxStatus;

// Query basic information about an object
function NtxQueryBasicObject(
  hObject: THandle;
  out Info: TObjectBasicInformaion
): TNtxStatus;

// Query object type information
function NtxQueryTypeObject(
  hObject: THandle;
  out Info: TObjectTypeInfo
): TNtxStatus;

// Set flags for a handle
function NtxSetFlagsHandle(
  hObject: THandle;
  Inherit: Boolean;
  ProtectFromClose: Boolean
): TNtxStatus;

// --------------------------------- Waits --------------------------------- //

// Wait for an object to enter signaled state
function NtxWaitForSingleObject(
  hObject: THandle;
  Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False
): TNtxStatus;

// Wait for any/all objects to enter a signaled state
function NtxWaitForMultipleObjects(
  Objects: TArray<THandle>;
  WaitType: TWaitType;
  Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False): TNtxStatus;

// ------------------------------- Security -------------------------------- //

// Query security descriptor of a kernel object
function NtxQuerySecurityObject(
  hObject: THandle;
  Info: TSecurityInformation;
  out SD: ISecDesc
): TNtxStatus;

// Set security descriptor on a kernel object
function NtxSetSecurityObject(
  hObject: THandle;
  Info: TSecurityInformation;
  SD: PSecurityDescriptor
): TNtxStatus;

implementation

{$WARN SYMBOL_PLATFORM OFF}

uses
  Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.ntpebteb, Ntapi.ntrtl;

procedure TAutoHandle.Release;
begin
  NtxSafeClose(FHandle);
  inherited;
end;

function NtxSafeClose;
begin
  if hObject > MAX_HANDLE then
  begin
    Result.Location := 'NtxSafeClose';
    Result.Status := STATUS_INVALID_HANDLE
  end
  else
  try
    // Clear handle protection (just in case)
    Result := NtxSetFlagsHandle(hObject, False, False);

    // Note: NtClose might throw exceptions
    Result.Location := 'NtClose';
    Result.Status := NtClose(hObject);
  except
    Result.Location := 'NtxSafeClose';
    Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;

  // Help debugging handle problems
  DbgBreakOnFailure(Result.Status);

  // Prevent future use
  hObject := 0;
end;

function NtxDuplicateHandle;
var
  hSameAccess, hTemp: THandle;
  objTypeInfo: TObjectTypeInfo;
  objInfo: TObjectBasicInformaion;
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
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_DUP_HANDLE);

  if (DesiredAccess and MAXIMUM_ALLOWED <> 0) and
    (Options and DUPLICATE_SAME_ACCESS = 0) then
  begin
    // To prevent race conditions we duplicate the handle to the current process
    // with the same access and attributes to perform all further probing on it.
    // This operation might close the source handle if DUPLICATE_CLOSE_SOURCE is
    // specified. Be aware that we might get a handle that is protected from
    // closing, since the caller might have used DUPLICATE_SAME_ATTRIBUTES or
    // OBJ_PROTECT_CLOSE.

    Result.Status := NtDuplicateObject(SourceProcessHandle, SourceHandle,
      NtCurrentProcess, hSameAccess, 0, HandleAttributes, Options or
      DUPLICATE_SAME_ACCESS);

    // If we fail to duplicate it even with the same access, we are finished.
    if not Result.IsSuccess then
      Exit;

    // Query which access rights are meaningful for this type of object.
    // Fallback to a full mask on failure.
    if not NtxQueryTypeObject(hSameAccess, objTypeInfo).IsSuccess then
      objTypeInfo.Other.ValidAccessMask := SPECIFIC_RIGHTS_ALL or
        STANDARD_RIGHTS_ALL;

    // Start probing. Try full access first.
    Result.Status := NtDuplicateObject(NtCurrentProcess, hSameAccess,
      NtCurrentProcess, hTemp, objTypeInfo.Other.ValidAccessMask, 0, 0);

    // Was the guess correct?
    if Result.IsSuccess then
    begin
      DesiredAccess := objTypeInfo.Other.ValidAccessMask;
      NtxSafeClose(hTemp);
      goto MaskExpandingDone;
    end;

    // Did something else happen? Access denied is fine, we can try less access.
    if Result.Status <> STATUS_ACCESS_DENIED then
      goto Cleanup;

    // The caller might combine MAXIMUM_ALLOWED with other access rights
    DesiredAccess := DesiredAccess and not MAXIMUM_ALLOWED;

    // In this case, we need to check whether we can satisfy the mininum
    // requirements which must include them.
    if DesiredAccess <> 0 then
    begin
      Result.Status := NtDuplicateObject(NtCurrentProcess, hSameAccess,
        NtCurrentProcess, hTemp, DesiredAccess, 0, 0);

      if Result.IsSuccess then
        NtxSafeClose(hTemp)
      else
        goto Cleanup;
    end;

    // Include whatever access we already have based on DUPLICATE_SAME_ACCESS
    if NtxQueryBasicObject(hSameAccess, objInfo).IsSuccess then
      DesiredAccess := DesiredAccess or objInfo.GrantedAccess and
        not ACCESS_SYSTEM_SECURITY;

    // Try each one standard or specific access right that is not granted yet
    for bit := 0 to 31 do
      if (1 shl bit) and objTypeInfo.Other.ValidAccessMask and not
        DesiredAccess <> 0 then
        if NT_SUCCESS(NtDuplicateObject(NtCurrentProcess, hSameAccess,
          NtCurrentProcess, hTemp, 1 shl bit, 0, 0)) then
        begin
          // Yes, this access can be granted, add it
          DesiredAccess := DesiredAccess or (1 shl bit);
          NtxSafeClose(hTemp);
        end;

  MaskExpandingDone:

    // Finally, duplicate the handle to the target process with the requested
    // attributes and expanded maximum access
    Result.Status := NtDuplicateObject(NtCurrentProcess, hSameAccess,
      TargetProcessHandle, TargetHandle, DesiredAccess, HandleAttributes,
      Options and not DUPLICATE_CLOSE_SOURCE);

  Cleanup:

    // Make sure our copy is closable by clearing protection
    if (Options and DUPLICATE_SAME_ATTRIBUTES <> 0) or
      (HandleAttributes and OBJ_PROTECT_CLOSE <> 0) then
    begin
      handleInfo.Inherit := False;
      handleInfo.ProtectFromClose := False;

      NtSetInformationObject(hSameAccess, ObjectHandleFlagInformation,
        @handleInfo, SizeOf(handleInfo));
    end;

    // Close local copy
    NtxSafeClose(hSameAccess);
  end
  else
  begin
    // Usual case
    Result.Status := NtDuplicateObject(SourceProcessHandle, SourceHandle,
      TargetProcessHandle, TargetHandle, DesiredAccess, HandleAttributes,
      Options);
  end;
end;

function NtxDuplicateHandleLocal;
var
  hNewHandle: THandle;
begin
  Result := NtxDuplicateHandle(NtCurrentProcess, SourceHandle, NtCurrentProcess,
    hNewHandle, DesiredAccess, HandleAttributes, Options);

  if Result.IsSuccess then
    hxNewHandle := TAutoHandle.Capture(hNewHandle);
end;

function NtxReopenHandle;
var
  hNewHandle: THandle;
begin
  Result := NtxDuplicateHandle(NtCurrentProcess, hxHandle.Handle,
    NtCurrentProcess, hNewHandle, DesiredAccess, HandleAttributes, Options or
      DUPLICATE_CLOSE_SOURCE);

  if Result.IsSuccess then
  begin
    // NtDuplicateObject already closed the handle for us
    hxHandle.AutoRelease := False;

    // Swap it with the new one
    hxHandle := TAutoHandle.Capture(hNewHandle);
  end;
end;

function NtxDuplicateHandleFrom;
var
  hLocalHandle: THandle;
begin
  Result := NtxDuplicateHandle(hProcess, hRemoteHandle, NtCurrentProcess,
    hLocalHandle, DesiredAccess, HandleAttributes, Options);

  if Result.IsSuccess then
    hxLocalHandle := TAutoHandle.Capture(hLocalHandle);
end;

function NtxDuplicateHandleTo;
begin
  Result := NtxDuplicateHandle(NtCurrentProcess, hLocalHandle, hProcess,
    hRemoteHandle, DesiredAccess, HandleAttributes, Options);
end;

function NtxCloseRemoteHandle;
var
  hxTemp: IHandle;
begin
  // Duplicate the handle closing the source and discarding the result
  Result.Location := 'NtDuplicateObject';
  Result.LastCall.Expects<TProcessAccessMask>(PROCESS_DUP_HANDLE);
  Result.Status := NtDuplicateObject(hProcess, hObject, 0, THandle(nil^), 0, 0,
    DUPLICATE_CLOSE_SOURCE);

  if DoubleCheck and Result.IsSuccess then
  begin
    // We need to make sure that the previous operation actually closed the
    // handle. Might happen that the system does not allow this action (i.e.
    // this handle is a current desktop for one of the threads), but still
    // returns success.
    Result := NtxDuplicateHandleFrom(hProcess, hObject, hxTemp);

    // We expect the operation to fail since the first call was supposed to
    // close it.
    if Result.IsSuccess then
    begin
      Result.Location := 'NtxCloseRemoteHandle';
      Result.Status := STATUS_HANDLE_NOT_CLOSABLE;
    end
    else if Result.Status = STATUS_INVALID_HANDLE then
      // The handle was closed successfully
      Result.Status := STATUS_SUCCESS;

    // If something else went wrong, forward the error
  end;
end;

function NtxQueryObject;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryObject';
  Result.LastCall.AttachInfoClass(InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryObject(hObject, InfoClass, xMemory.Data,
      xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxQueryNameObject;
var
  xMemory: IMemory<PNtUnicodeString>;
begin
  Result := NtxQueryObject(hObject, ObjectNameInformation, IMemory(xMemory));

  if Result.IsSuccess then
    Name := xMemory.Data.ToString;
end;

function NtxQueryBasicObject;
begin
  Result.Location := 'NtQueryObject';
  Result.LastCall.AttachInfoClass(ObjectBasicInformation);

  Result.Status := NtQueryObject(hObject, ObjectBasicInformation, @Info,
    SizeOf(Info), nil);
end;

function NtxQueryTypeObject;
var
  xMemory: IMemory<PObjectTypeInformation>;
begin
  Result := NtxQueryObject(hObject, ObjectTypeInformation, IMemory(xMemory),
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
  Result.LastCall.AttachInfoClass(ObjectHandleFlagInformation);

  Result.Status := NtSetInformationObject(hObject, ObjectHandleFlagInformation,
    @Info, SizeOf(Info));
end;

function NtxWaitForSingleObject;
begin
  Result.Location := 'NtWaitForSingleObject';
  Result.LastCall.Expects<TAccessMask>(SYNCHRONIZE);
  Result.Status := NtWaitForSingleObject(hObject, Alertable,
    TimeoutToLargeInteger(Timeout));
end;

function NtxWaitForMultipleObjects;
begin
  Result.Location := 'NtWaitForMultipleObjects';
  Result.LastCall.Expects<TAccessMask>(SYNCHRONIZE);
  Result.Status := NtWaitForMultipleObjects(Length(Objects), Objects,
    WaitType, Alertable, TimeoutToLargeInteger(Timeout));
end;

function NtxQuerySecurityObject;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQuerySecurityObject';
  Result.LastCall.Expects(SecurityReadAccess(Info));

  IMemory(SD) := TAutoMemory.Allocate(0);
  repeat
    Required := 0;
    Result.Status := NtQuerySecurityObject(hObject, Info,
      SD.Data, SD.Size, Required);
  until not NtxExpandBufferEx(Result, IMemory(SD), Required, nil);
end;

function NtxSetSecurityObject;
begin
  Result.Location := 'NtSetSecurityObject';
  Result.LastCall.Expects(SecurityWriteAccess(Info));
  Result.Status := NtSetSecurityObject(hObject, Info, SD);
end;

end.
