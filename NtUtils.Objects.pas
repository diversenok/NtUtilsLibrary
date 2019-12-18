unit NtUtils.Objects;

interface
{$WARN SYMBOL_PLATFORM OFF}

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntobapi, NtUtils.Exceptions,
  NtUtils.AutoHandle;

type
  IHandle = NtUtils.AutoHandle.IHandle;

  TAutoHandle = class(TCustomAutoHandle, IHandle)
    destructor Destroy; override;
  end;

  TObjectBasicInformaion = Ntapi.ntobapi.TObjectBasicInformaion;

  TObjectTypeInfo = record
    TypeName: String;
    Other: TObjectTypeInformation;
  end;

// Close a handle safely and set it to zero
function NtxSafeClose(var hObject: THandle): NTSTATUS;

// Duplicate handle to an object. Supports MAXIMUM_ALLOWED.
function NtxDuplicateObject(SourceProcessHandle: THandle;
  SourceHandle: THandle; TargetProcessHandle: THandle;
  out TargetHandle: THandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal; Options: Cardinal): TNtxStatus;

// Duplicate a handle from a process
function NtxDuplicateObjectFrom(hProcess: THandle; hRemoteHandle: THandle;
  out hxLocalHandle: IHandle; HandleAttributes: Cardinal = 0): TNtxStatus;

// Duplicate a handle to a process
function NtxDuplicateObjectTo(hProcess: THandle; hLocalHandle: THandle;
  out hRemoteHandle: THandle; HandleAttributes: Cardinal = 0): TNtxStatus;

// Duplicate a local handle
function NtxDuplicateObjectLocal(SourceHandle: THandle;
  out hxNewHandle: IHandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal = 0): TNtxStatus;

// Closes a handle in a process
function NtxCloseRemoteHandle(hProcess: THandle; hObject: THandle): TNtxStatus;

// Query name of an object
function NtxQueryNameObject(hObject: THandle; out Name: String): TNtxStatus;

// Query basic information about an object
function NtxQueryBasicInfoObject(hObject: THandle;
  out Info: TObjectBasicInformaion): TNtxStatus;

// Query object type information
function NtxQueryTypeObject(hObject: THandle;
  out Info: TObjectTypeInfo): TNtxStatus;

// Wait for an object to enter signaled state
function NtxWaitForSingleObject(hObject: THandle; Timeout: Int64 = NT_INFINITE;
  Alertable: Boolean = False): TNtxStatus;

// Wait for any/all objects to enter a signaled state
function NtxWaitForMultipleObjects(Objects: TArray<THandle>; WaitType:
  TWaitType; Timeout: Int64 = NT_INFINITE; Alertable: Boolean = False)
  : TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpsapi, System.SysUtils;

destructor TAutoHandle.Destroy;
begin
  if FAutoClose then
    NtxSafeClose(Handle);
  inherited;
end;

function NtxSafeClose(var hObject: THandle): NTSTATUS;
begin
  if hObject > MAX_HANDLE then
    Exit(STATUS_INVALID_HANDLE);

  Result := STATUS_UNSUCCESSFUL;
  try
    // NtClose can raise errors, we should capture them
    Result := NtClose(hObject);
  except
    on E: EExternalException do
      if Assigned(E.ExceptionRecord) then
        Result := E.ExceptionRecord.ExceptionCode;
  end;

  // Log failed close attempts
  if not NT_SUCCESS(Result) then
    ENtError.Report(Result, 'NtClose 0x' + IntToHex(hObject, 0));

  // Prevent future use
  hObject := 0;
end;

function NtxDuplicateObject(SourceProcessHandle: THandle;
  SourceHandle: THandle; TargetProcessHandle: THandle;
  out TargetHandle: THandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal; Options: Cardinal): TNtxStatus;
var
  hSameAccess, hTemp: THandle;
  objInfo: TObjectBasicInformaion;
  handleInfo: TObjectHandleFlagInformation;
  bit: Integer;
label
  MaskExpandingDone;
begin
  // NtDuplicateObject does not support MAXIMUM_ALLOWED (it returns zero
  // access instead). We will implement this feature by probing additional
  // access masks.

  Result.Location := 'NtDuplicateObject';
  Result.LastCall.Expects(PROCESS_DUP_HANDLE, @ProcessAccessType);

  if (DesiredAccess = MAXIMUM_ALLOWED) and
    (Options and DUPLICATE_SAME_ACCESS = 0) then
  begin
    // To prevent race conditions we duplicate the handle to the current process
    // with the same access and attributes to perform all further probing on it.
    // This operation might close the source handle if DUPLICATE_CLOSE_SOURCE is
    // specified.

    Result.Status := NtDuplicateObject(SourceProcessHandle, SourceHandle,
      NtCurrentProcess, hSameAccess, 0, HandleAttributes,
      Options or DUPLICATE_SAME_ACCESS);

    // If we can't do it we are finished
    if not Result.IsSuccess then
      Exit;

    // Start probing. Try full access first.
    DesiredAccess := STANDARD_RIGHTS_ALL or SPECIFIC_RIGHTS_ALL;

    Result.Status := NtDuplicateObject(NtCurrentProcess, hSameAccess,
      NtCurrentProcess, hTemp, DesiredAccess, 0, 0);

    // Was the guess correct?
    if Result.IsSuccess then
    begin
      NtxSafeClose(hTemp);
      goto MaskExpandingDone;
    end;

    // Did something else happen?
    if Result.Status <> STATUS_ACCESS_DENIED then
      Exit;

    // Query what access we already have based on DUPLICATE_SAME_ACCESS flag
    if NT_SUCCESS(NtQueryObject(hSameAccess, ObjectBasicInformation, @objInfo,
      SizeOf(objInfo), nil)) then
      DesiredAccess := objInfo.GrantedAccess and not ACCESS_SYSTEM_SECURITY
    else
      DesiredAccess := 0;

    // Try each one standard or specific access right that is not granted yet
    for bit := 0 to 31 do
      if ((STANDARD_RIGHTS_ALL or SPECIFIC_RIGHTS_ALL) and (1 shl bit)
        and not DesiredAccess) <> 0 then
        if NT_SUCCESS(NtDuplicateObject(NtCurrentProcess, hSameAccess,
          NtCurrentProcess, hTemp, (1 shl bit), 0, 0)) then
        begin
          // Yes, this access can be granted, add it
          DesiredAccess := DesiredAccess or (1 shl bit);
          NtxSafeClose(hTemp);
        end;

    // Finally, duplicate the handle to the target process with the requested
    // attributes and expanded maximum access
    MaskExpandingDone:

    Result.Status := NtDuplicateObject(NtCurrentProcess, hSameAccess,
      TargetProcessHandle, TargetHandle, DesiredAccess, HandleAttributes,
      Options and not DUPLICATE_CLOSE_SOURCE);

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

function NtxDuplicateObjectFrom(hProcess: THandle; hRemoteHandle: THandle;
  out hxLocalHandle: IHandle; HandleAttributes: Cardinal): TNtxStatus;
var
  hLocalHandle: THandle;
begin
  Result := NtxDuplicateObject(hProcess, hRemoteHandle, NtCurrentProcess,
    hLocalHandle, 0, HandleAttributes, DUPLICATE_SAME_ACCESS);

  if Result.IsSuccess then
    hxLocalHandle := TAutoHandle.Capture(hLocalHandle);
end;

function NtxDuplicateObjectTo(hProcess: THandle; hLocalHandle: THandle;
  out hRemoteHandle: THandle; HandleAttributes: Cardinal): TNtxStatus;
begin
  Result := NtxDuplicateObject(NtCurrentProcess, hLocalHandle, hProcess,
    hRemoteHandle, 0, HandleAttributes, DUPLICATE_SAME_ACCESS);
end;

function NtxDuplicateObjectLocal(SourceHandle: THandle;
  out hxNewHandle: IHandle; DesiredAccess: TAccessMask;
  HandleAttributes: Cardinal): TNtxStatus;
var
  hNewHandle: THandle;
begin
  Result := NtxDuplicateObject(NtCurrentProcess, SourceHandle, NtCurrentProcess,
    hNewHandle, DesiredAccess, HandleAttributes, 0);

  if Result.IsSuccess then
    hxNewHandle := TAutoHandle.Capture(hNewHandle);
end;

function NtxCloseRemoteHandle(hProcess: THandle; hObject: THandle): TNtxStatus;
begin
  Result.Location := 'NtDuplicateObject';
  Result.LastCall.Expects(PROCESS_DUP_HANDLE, @ProcessAccessType);
  Result.Status := NtDuplicateObject(hProcess, hObject, 0, THandle(nil^), 0, 0,
    DUPLICATE_CLOSE_SOURCE);
end;

function NtxQueryNameObject(hObject: THandle; out Name: String): TNtxStatus;
var
  Buffer: PUNICODE_STRING;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'NtQueryObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(ObjectNameInformation);
  Result.LastCall.InfoClassType := TypeInfo(TObjectInformationClass);
  // No special handle access required

  BufferSize := 0;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryObject(hObject, ObjectNameInformation, Buffer,
      BufferSize, @Required);

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, Required);

  if not Result.IsSuccess then
    Exit;

  Name := Buffer.ToString;
  FreeMem(Buffer);
end;

function NtxQueryBasicInfoObject(hObject: THandle;
  out Info: TObjectBasicInformaion): TNtxStatus;
begin
  Result.Location := 'NtQueryObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(ObjectBasicInformation);
  Result.LastCall.InfoClassType := TypeInfo(TObjectInformationClass);
  // No special handle access required

  Result.Status := NtQueryObject(hObject, ObjectBasicInformation, @Info,
    SizeOf(Info), nil);
end;

function NtxQueryTypeObject(hObject: THandle;
  out Info: TObjectTypeInfo): TNtxStatus;
var
  Buffer: PObjectTypeInformation;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'NtQueryObject';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(ObjectTypeInformation);
  Result.LastCall.InfoClassType := TypeInfo(TObjectInformationClass);
  // No special handle access required

  BufferSize := 0;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryObject(hObject, ObjectTypeInformation, Buffer,
      BufferSize, @Required);

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, Required);

  if not Result.IsSuccess then
    Exit;

  if BufferSize >= SizeOf(TObjectTypeInformation) then
  begin
    // Copy the structure and fix string reference
    Info.TypeName := Buffer.TypeName.ToString;
    Info.Other := Buffer^;
    Info.Other.TypeName.Buffer := PWideChar(Info.TypeName);
  end
  else
  begin
    Result.Location := 'NtxQueryTypeObject';
    Result.Status := STATUS_INFO_LENGTH_MISMATCH;
  end;

  FreeMem(Buffer);
end;

function NtxWaitForSingleObject(hObject: THandle; Timeout: Int64;
  Alertable: Boolean): TNtxStatus;
begin
  Result.Location := 'NtWaitForSingleObject';
  Result.LastCall.Expects(SYNCHRONIZE, @NonSpecificAccessType);
  Result.Status := NtWaitForSingleObject(hObject, Alertable,
    Int64ToLargeInteger(Timeout));
end;

function NtxWaitForMultipleObjects(Objects: TArray<THandle>; WaitType:
  TWaitType; Timeout: Int64; Alertable: Boolean): TNtxStatus;
begin
  Result.Location := 'NtWaitForMultipleObjects';
  Result.LastCall.Expects(SYNCHRONIZE, @NonSpecificAccessType);
  Result.Status := NtWaitForMultipleObjects(Length(Objects), Objects,
    WaitType, Alertable, Int64ToLargeInteger(Timeout));
end;

end.
