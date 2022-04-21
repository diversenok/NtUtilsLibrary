unit NtUtils.Registry;

{
  This module provides support for working with registry via Native API.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntregapi, Ntapi.ntioapi, Ntapi.ntseapi, NtUtils,
  NtUtils.Objects, DelphiUtils.Async;

type
  TKeyCreationBehavior = set of (
    // Create missing parent keys if necessary
    kcRecursive,

    // Apply the supplied security descriptor when creating missing parent keys
    kcUseSecurityWithRecursion
  );

  TKeyBasicInfo = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    Name: String;
  end;

  TRegValueEntry = record
    ValueName: String;
    ValueType: TRegValueType;
  end;

  TRegValueDataEntry = record
    ValueName: String;
    ValueType: TRegValueType;
    ValueData: IMemory;
  end;

  TSubKeyEntry = record
    ProcessId: TProcessId;
    KeyName: String;
  end;

{ Keys }

// Open a key
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenKey(
  out hxKey: IHandle;
  const Name: String;
  DesiredAccess: TRegKeyAccessMask;
  OpenOptions: TRegOpenOptions = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Open a key in a (either normal or registry) transaction
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenKeyTransacted(
  out hxKey: IHandle;
  [Access(TRANSACTION_ENLIST)] hTransaction: THandle;
  const Name: String;
  DesiredAccess: TRegKeyAccessMask;
  OpenOptions: TRegOpenOptions = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Create a key
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxCreateKey(
  out hxKey: IHandle;
  const Name: String;
  DesiredAccess: TRegKeyAccessMask;
  CreateOptions: TRegOpenOptions = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  CreationBehavior: TKeyCreationBehavior = [kcRecursive];
  [out, opt] Disposition: PRegDisposition = nil
): TNtxStatus;

// Create a key in a (either normal or registry) transaction
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxCreateKeyTransacted(
  out hxKey: IHandle;
  [Access(TRANSACTION_ENLIST)] hTransaction: THandle;
  const Name: String;
  DesiredAccess: TRegKeyAccessMask;
  CreateOptions: TRegOpenOptions = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  CreationBehavior: TKeyCreationBehavior = [kcRecursive];
  [out, opt] Disposition: PRegDisposition = nil
): TNtxStatus;

// Delete a key
function NtxDeleteKey(
  [Access(_DELETE)] hKey: THandle
): TNtxStatus;

// Rename a key
function NtxRenameKey(
  [Access(KEY_WRITE)] hKey: THandle;
  const NewName: String
): TNtxStatus;

// Enumerate keys using an information class
function NtxEnumerateKey(
  [Access(KEY_ENUMERATE_SUB_KEYS)] hKey: THandle;
  Index: Integer;
  InfoClass: TKeyInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Enumerate sub-keys
function NtxEnumerateSubKeys(
  [Access(KEY_ENUMERATE_SUB_KEYS)] hKey: THandle;
  out SubKeys: TArray<String>
): TNtxStatus;

// Query variable-length key information
function NtxQueryKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  InfoClass: TKeyInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query key basic information
function NtxQueryBasicKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  out Info: TKeyBasicInfo
): TNtxStatus;

type
  NtxKey = class abstract
    // Query fixed-size key information
    class function Query<T>(
      [Access(KEY_QUERY_VALUE)] hKey: THandle;
      InfoClass: TKeyInformationClass;
      out Buffer: T
    ): TNtxStatus; static;

    // Set fixed-size key information
    class function &Set<T>(
      [Access(KEY_SET_VALUE)] hKey: THandle;
      InfoClass: TKeySetInformationClass;
      const Buffer: T
    ): TNtxStatus; static;
  end;

{ Symbolic Links }

// Create a symbolic link key
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxCreateSymlinkKey(
  [Access(KEY_SET_VALUE or KEY_CREATE_LINK)] const Source: String;
  const Target: String;
  Options: TRegOpenOptions = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  CreationBehavior: TKeyCreationBehavior = [kcRecursive]
): TNtxStatus;

// Delete a symbolic link key
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxDeleteSymlinkKey(
  [Access(_DELETE)] const Name: String;
  [opt] const Root: IHandle = nil;
  Options: TRegOpenOptions = 0
): TNtxStatus;

{ Values }

// Enumerate one value at a time using an information class
function NtxEnumerateValueKeyEx(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  Index: Integer;
  InfoClass: TKeyValueInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Enumerate all values using an information class
function NtxEnumerateValuesKeyEx(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  InfoClass: TKeyValueInformationClass;
  out Values: TArray<IMemory>;
  InitialBuffer: Cardinal = 0
): TNtxStatus;

// Enumerate names and types of all values within a key
function NtxEnumerateValuesKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  out Values: TArray<TRegValueEntry>
): TNtxStatus;

// Enumerate and retrieve data for all values within a key
function NtxEnumerateValuesDataKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  out Values: TArray<TRegValueDataEntry>
): TNtxStatus;

// Query variable-length value information
function NtxQueryValueKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  InfoClass: TKeyValueInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Query value of an arbitrary type
function NtxQueryValueKeyBinary(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  out ValueType: TRegValueType;
  out Value: IMemory;
  ExpectedSize: Cardinal = 0
): TNtxStatus;

// Query value of a 32-bit integer type
function NtxQueryValueKeyUInt(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  out Value: Cardinal
): TNtxStatus;

// Query value of a string type
function NtxQueryValueKeyString(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  out Value: String
): TNtxStatus;

// Query value of a multi-string type
function NtxQueryValueKeyMultiString(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  out Value: TArray<String>
): TNtxStatus;

// Set value
function NtxSetValueKey(
  [Access(KEY_SET_VALUE)] hKey: THandle;
  const ValueName: String;
  ValueType: TRegValueType;
  [in] Data: Pointer;
  DataSize: Cardinal
): TNtxStatus;

// Set a DWORD value
function NtxSetValueKeyUInt(
  [Access(KEY_SET_VALUE)] hKey: THandle;
  const ValueName: String;
  const Value: Cardinal
): TNtxStatus;

// Set a string value
function NtxSetValueKeyString(
  [Access(KEY_SET_VALUE)] hKey: THandle;
  const ValueName: String;
  const Value: String;
  ValueType: TRegValueType = REG_SZ
): TNtxStatus;

// Set a multi-string value
function NtxSetValueKeyMultiString(
  [Access(KEY_SET_VALUE)] hKey: THandle;
  const ValueName: String;
  const Value: TArray<String>
): TNtxStatus;

// Delete a value
function NtxDeleteValueKey(
  [Access(KEY_SET_VALUE)] hKey: THandle;
  const ValueName: String
): TNtxStatus;

{ Other }

// Mount a hive file to the registry
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpWithExceptions)]
function NtxLoadKeyEx(
  out hxKey: IHandle;
  const FileName: String;
  const KeyPath: String;
  Flags: TRegLoadFlags = 0;
  [opt, Access(0)] TrustClassKey: THandle = 0;
  [opt] const FileObjAttr: IObjectAttributes = nil;
  [opt] const KeyObjAttr: IObjectAttributes = nil
): TNtxStatus;

// Unmount a hive file from the registry
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpWithExceptions)]
function NtxUnloadKey(
  const KeyName: String;
  Force: Boolean = False;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Backup a section of the registry to a hive file
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtxSaveKey(
  [Access(0)] hKey: THandle;
  [Access(FILE_WRITE_DATA)] hFile: THandle;
  Format: TRegSaveFormat = REG_LATEST_FORMAT
): TNtxStatus;

// Backup a result of overlaying two registry keys into a registry hive file
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
function NtxSaveMergedKeys(
  [Access(0)] hHighPrecedenceKey: THandle;
  [Access(0)] hLowPrecedenceKey: THandle;
  [Access(FILE_WRITE_DATA)] hFile: THandle
): TNtxStatus;

// Replace a content of a key with a content of a hive file
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function NtxRestoreKey(
  [Access(0)] hKey: THandle;
  [Access(FILE_READ_DATA)] hFile: THandle;
  Flags: TRegLoadFlags = 0
): TNtxStatus;

// Enumerate opened subkeys from a part of the registry
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function NtxEnumerateOpenedSubkeys(
  out SubKeys: TArray<TSubKeyEntry>;
  const KeyName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Subsribe for registry changes notifications
function NtxNotifyChangeKey(
  [Access(KEY_NOTIFY)] hKey: THandle;
  Flags: TRegNotifyFlags;
  WatchTree: Boolean;
  [opt] const AsyncCallback: TAnonymousApcCallback
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.nttmapi, NtUtils.SysUtils,
  DelphiUtils.AutoObjects, DelphiUtils.Arrays;

{ Keys }

function NtxOpenKey;
var
  hKey: THandle;
begin
  Result.Location := 'NtOpenKeyEx';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtOpenKeyEx(
    hKey,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^,
    OpenOptions
  );

  if Result.IsSuccess then
    hxKey := Auto.CaptureHandle(hKey);
end;

function NtxOpenKeyTransacted;
var
  hKey: THandle;
begin
  Result.Location := 'NtOpenKeyTransactedEx';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ENLIST);

  Result.Status := NtOpenKeyTransactedEx(
    hKey,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^,
    OpenOptions,
    hTransaction
  );

  if Result.IsSuccess then
    hxKey := Auto.CaptureHandle(hKey);
end;

function NtxCreateKey;
var
  hKey: THandle;
  hxParentKey: IHandle;
  ParentName, ChildName: String;
  ParentObjAttr: IObjectAttributes;
begin
  Result.Location := 'NtCreateKey';
  Result.LastCall.OpensForAccess(DesiredAccess);

  Result.Status := NtCreateKey(
    hKey,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^,
    0,
    nil,
    CreateOptions,
    Disposition
  );

  case Result.Status of

    NT_SUCCESS_MIN..NT_SUCCESS_MAX:
    begin
      hxKey := Auto.CaptureHandle(hKey);
      Exit;
    end;

    // Check if we need to create a parent key and fall through in this case
    STATUS_OBJECT_NAME_NOT_FOUND:
      if not (kcRecursive in CreationBehavior) or
        not RtlxSplitPath(Name, ParentName, ChildName) then
        Exit;
  else
    Exit;
  end;

  // Do not adjust parent's security unless explisitly told to
  if Assigned(ObjectAttributes) and not (kcUseSecurityWithRecursion in
    CreationBehavior) then
    ParentObjAttr := AttributeBuilder(ObjectAttributes).UseSecurity(nil)
  else
    ParentObjAttr := ObjectAttributes;

  // The parent is missing and we need to create it (recursively)
  // Note that we don't want the parent to become a symlink
  Result := NtxCreateKey(
    hxParentKey,
    ParentName,
    KEY_CREATE_SUB_KEY,
    CreateOptions and not REG_OPTION_CREATE_LINK,
    ParentObjAttr,
    CreationBehavior
  );

  // Retry using the new parent as a root
  if Result.IsSuccess then
    Result := NtxCreateKey(
      hxKey,
      ChildName,
      DesiredAccess,
      CreateOptions,
      AttributeBuilder(ObjectAttributes).UseRoot(hxParentKey)
    );
end;

function NtxCreateKeyTransacted;
var
  hKey: THandle;
  hxParentKey: IHandle;
  ParentName, ChildName: String;
  ParentObjAttr: IObjectAttributes;
begin
  Result.Location := 'NtCreateKeyTransacted';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TTmTxAccessMask>(TRANSACTION_ENLIST);

  Result.Status := NtCreateKeyTransacted(
    hKey,
    DesiredAccess,
    AttributeBuilder(ObjectAttributes).UseName(Name).ToNative^,
    0,
    nil,
    CreateOptions,
    hTransaction,
    Disposition
  );

  case Result.Status of

    NT_SUCCESS_MIN..NT_SUCCESS_MAX:
    begin
      hxKey := Auto.CaptureHandle(hKey);
      Exit;
    end;

    // Check if we need to create a parent key and fall through in this case
    STATUS_OBJECT_NAME_NOT_FOUND:
      if not (kcRecursive in CreationBehavior) or
        not RtlxSplitPath(Name, ParentName, ChildName) then
        Exit;
  else
    Exit;
  end;

  // Do not adjust parent's security unless explisitly told to
  if Assigned(ObjectAttributes) and not (kcUseSecurityWithRecursion in
    CreationBehavior) then
    ParentObjAttr := AttributeBuilder(ObjectAttributes).UseSecurity(nil)
  else
    ParentObjAttr := ObjectAttributes;

  // The parent is missing and we need to create it (recursively)
  // Note that we don't want the parent to become a symlink
  Result := NtxCreateKeyTransacted(
    hxParentKey,
    hTransaction,
    ParentName,
    KEY_CREATE_SUB_KEY,
    CreateOptions and not REG_OPTION_CREATE_LINK,
    ParentObjAttr,
    CreationBehavior
  );

  // Retry using the new parent as a root
  if Result.IsSuccess then
    Result := NtxCreateKeyTransacted(
      hxKey,
      hTransaction,
      ChildName,
      DesiredAccess,
      CreateOptions,
      AttributeBuilder(ObjectAttributes).UseRoot(hxParentKey)
    );
end;

function NtxDeleteKey;
begin
  Result.Location := 'NtDeleteKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(_DELETE);

  Result.Status := NtDeleteKey(hKey);
end;

function NtxRenameKey;
begin
  Result.Location := 'NtRenameKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_WRITE); // or KEY_READ under virtualization

  Result.Status := NtRenameKey(hKey, TNtUnicodeString.From(NewName));
end;

function NtxEnumerateKey;
var
  Required: Cardinal;
begin
  Result.Location := 'NtEnumerateKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_ENUMERATE_SUB_KEYS);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtEnumerateKey(hKey, Index, InfoClass, xMemory.Data,
      xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxEnumerateSubKeys;
var
  xMemory: IMemory<PKeyBasicInformation>;
  Index: Integer;
begin
  SetLength(SubKeys, 0);

  Index := 0;
  repeat
    // Query details about each sub-key
    Result := NtxEnumerateKey(hKey, Index, KeyBasicInformation,
      IMemory(xMemory));

    if Result.IsSuccess then
    begin
      SetLength(SubKeys, Length(SubKeys) + 1);
      SetString(SubKeys[High(SubKeys)], PWideChar(@xMemory.Data.Name),
        xMemory.Data.NameLength div SizeOf(WideChar));

      Inc(Index);
    end;
  until not Result.IsSuccess;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

function NtxQueryKey;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  if not (InfoClass in [KeyNameInformation, KeyHandleTagsInformation]) then
    Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryKey(hKey, InfoClass, xMemory.Data, xMemory.Size,
      Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxQueryBasicKey;
var
  xMemory: IMemory<PKeyBasicInformation>;
begin
  Result := NtxQueryKey(hKey, KeyBasicInformation, IMemory(xMemory));

  if Result.IsSuccess then
  begin
    Info.LastWriteTime := xMemory.Data.LastWriteTime;
    Info.TitleIndex := xMemory.Data.TitleIndex;
    SetString(Info.Name, PWideChar(@xMemory.Data.Name),
      xMemory.Data.NameLength div SizeOf(WideChar));
  end;
end;

class function NtxKey.Query<T>;
var
  Returned: Cardinal;
begin
  Result.Location := 'NtQueryKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  if not (InfoClass in [KeyNameInformation, KeyHandleTagsInformation]) then
    Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  Result.Status := NtQueryKey(hKey, InfoClass, @Buffer, SizeOf(Buffer),
    Returned);
end;

class function NtxKey.&Set<T>;
begin
  Result.Location := 'NtSetInformationKey';
  Result.LastCall.UsesInfoClass(InfoClass, icSet);

  if InfoClass <> KeySetHandleTagsInformation then
    Result.LastCall.Expects<TRegKeyAccessMask>(KEY_SET_VALUE); // or KEY_READ under virtualization

  Result.Status := NtSetInformationKey(hKey, InfoClass, @Buffer,
    SizeOf(Buffer));
end;

{ Symbolic Links }

function NtxCreateSymlinkKey;
var
  hxKey: IHandle;
begin
  // Create a key
  Result := NtxCreateKey(hxKey, Source, KEY_SET_VALUE or KEY_CREATE_LINK,
    Options or REG_OPTION_CREATE_LINK, ObjectAttributes, CreationBehavior);

  if Result.IsSuccess then
  begin
    // Set its link target
    Result := NtxSetValueKeyString(hxKey.Handle, REG_SYMLINK_VALUE_NAME, Target,
      REG_LINK);

    // Undo key creation on failure
    if not Result.IsSuccess then
      NtxDeleteKey(hxKey.Handle);
  end;
end;

function NtxDeleteSymlinkKey;
var
  hxKey: IHandle;
begin
  Result := NtxOpenKey(hxKey, Name, _DELETE, Options, AttributeBuilder
    .UseAttributes(OBJ_OPENLINK).UseRoot(Root));

  if Result.IsSuccess then
    Result := NtxDeleteKey(hxKey.Handle);
end;

{ Values }

function NtxEnumerateValueKeyEx;
var
  Required: Cardinal;
begin
  Result.Location := 'NtEnumerateValueKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtEnumerateValueKey(hKey, Index, InfoClass, xMemory.Data,
      xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxEnumerateValuesKeyEx;
var
  KeyInfo: TKeyCachedInformation;
  i: Integer;
begin
  // Determine the number of keys
  Result := NtxKey.Query(hKey, KeyCachedInformation, KeyInfo);

  if not Result.IsSuccess then
    Exit;

  // Predefined keys do not allow enumerating values
  if Integer(KeyInfo.Values) < 0 then
  begin
    Result.Location := 'NtxEnumerateValuesKeyEx';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  SetLength(Values, KeyInfo.Values);

  for i := 0 to High(Values) do
  begin
    Result := NtxEnumerateValueKeyEx(hKey, i, InfoClass, Values[i],
      InitialBuffer);

    if not Result.IsSuccess then
    begin
      // Truncate on what we got
      SetLength(Values, i);
      Break;
    end;
  end;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

function NtxEnumerateValuesKey;
const
  INITIAL_SIZE = SizeOf(TKeyValueBasicInformation) + $40;
var
  RawValues: TArray<IMemory>;
  ValueInfo: PKeyValueBasicInformation;
  i: Integer;
begin
  Result := NtxEnumerateValuesKeyEx(hKey, KeyValueBasicInformation, RawValues,
    INITIAL_SIZE);

  if not Result.IsSuccess then
    Exit;

  SetLength(Values, Length(RawValues));

  for i := 0 to High(RawValues) do
  begin
    ValueInfo := PKeyValueBasicInformation(RawValues[i].Data);
    Values[i].ValueType := ValueInfo.ValueType;
    Values[i].ValueName := RtlxCaptureString(ValueInfo.Name,
      ValueInfo.NameLength div SizeOf(WideChar));
  end;
end;

function NtxEnumerateValuesDataKey;
const
  INITIAL_SIZE = SizeOf(TKeyValueBasicInformation) + $A0;
var
  RawValues: TArray<IMemory>;
  Info: PKeyValueFullInformation;
  i: Integer;
begin
  Result := NtxEnumerateValuesKeyEx(hKey, KeyValueFullInformation, RawValues,
    INITIAL_SIZE);

  if not Result.IsSuccess then
    Exit;

  SetLength(Values, Length(RawValues));

  for i := 0 to High(RawValues) do
  begin
    Info := RawValues[i].Data;
    Values[i].ValueType := Info.ValueType;
    Values[i].ValueData := Auto.CopyDynamic(
      RawValues[i].Offset(Info.DataOffset), Info.DataLength);

    Values[i].ValueName := RtlxCaptureString(Info.Name,
      Info.NameLength div SizeOf(WideChar));
  end;
end;

function NtxQueryValueKey;
var
  NameStr: TNtUnicodeString;
  Required: Cardinal;
begin
  Result.Location := 'NtQueryValueKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  NameStr := TNtUnicodeString.From(ValueName);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryValueKey(hKey, NameStr, InfoClass, xMemory.Data,
      xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function GrowPartial(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := SizeOf(TKeyValuePartialInfromation) +
    PKeyValuePartialInfromation(Memory.Data).DataLength;

  if Result < Required then
    Result := Required;
end;

function NtxQueryPartialValueKey(
  hKey: THandle;
  const ValueName: String;
  ExpectedSize: Cardinal;
  out xMemory: IMemory<PKeyValuePartialInfromation>
): TNtxStatus;
begin
  Result := NtxQueryValueKey(hKey, ValueName, KeyValuePartialInformation,
    IMemory(xMemory), SizeOf(TKeyValuePartialInfromation) - SizeOf(Byte) +
    ExpectedSize, GrowPartial);
end;

function NtxQueryValueKeyBinary;
var
  Buffer: IMemory<PKeyValuePartialInfromation>;
begin
  Result := NtxQueryPartialValueKey(hKey, ValueName, ExpectedSize, Buffer);

  if Result.IsSuccess then
  begin
    ValueType := Buffer.Data.ValueType;
    Value := Auto.CopyDynamic(@Buffer.Data.Data, Buffer.Data.DataLength);
  end;
end;

function NtxQueryValueKeyUInt;
var
  xMemory: IMemory<PKeyValuePartialInfromation>;
begin
  Result := NtxQueryPartialValueKey(hKey, ValueName, SizeOf(Cardinal),
    xMemory);

  if Result.IsSuccess then
    case xMemory.Data.ValueType of
      REG_DWORD:
        Value := PCardinal(@xMemory.Data.Data)^;
    else
      Result.Location := 'NtxQueryValueKeyUInt';
      Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    end;
end;

function NtxQueryValueKeyString;
var
  xMemory: IMemory<PKeyValuePartialInfromation>;
begin
  Result := NtxQueryPartialValueKey(hKey, ValueName, SizeOf(WideChar),
    xMemory);

  if Result.IsSuccess then
    case xMemory.Data.ValueType of
      REG_SZ, REG_EXPAND_SZ, REG_LINK, REG_MULTI_SZ:
        Value := RtlxCaptureString(PWideChar(@xMemory.Data.Data[0]),
          xMemory.Data.DataLength div SizeOf(WideChar));
    else
      Result.Location := 'NtxQueryValueKeyString';
      Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    end;
end;

function NtxQueryValueKeyMultiString;
var
  xMemory: IMemory<PKeyValuePartialInfromation>;
begin
  Result := NtxQueryPartialValueKey(hKey, ValueName, SizeOf(WideChar),
    xMemory);

  if Result.IsSuccess then
    case xMemory.Data.ValueType of
      REG_SZ, REG_EXPAND_SZ, REG_LINK:
        begin
          SetLength(Value, 1);
          SetString(Value[0], PWideChar(@xMemory.Data.Data),
            xMemory.Data.DataLength div SizeOf(WideChar) - 1);
        end;

      REG_MULTI_SZ:
        Value := RtlxParseWideMultiSz(PWideMultiSz(@xMemory.Data.Data),
          xMemory.Data.DataLength div SizeOf(WideChar));
    else
      Result.Location := 'NtxQueryValueKeyMultiString';
      Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    end;
end;

function NtxSetValueKey;
begin
  Result.Location := 'NtSetValueKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_SET_VALUE);

  Result.Status := NtSetValueKey(hKey, TNtUnicodeString.From(ValueName), 0,
    ValueType, Data, DataSize);
end;

function NtxSetValueKeyUInt;
begin
  Result := NtxSetValueKey(hKey, ValueName, REG_DWORD, @Value, SizeOf(Value));
end;

function NtxSetValueKeyString;
begin
  Result := NtxSetValueKey(hKey, ValueName, ValueType, PWideChar(Value),
    Length(Value) * SizeOf(WideChar));
end;

function NtxSetValueKeyMultiString;
var
  Buffer: IMemory<PWideMultiSz>;
begin
  Buffer := RtlxBuildWideMultiSz(Value);
  Result := NtxSetValueKey(hKey, ValueName, REG_MULTI_SZ, Buffer.Data,
    Buffer.Size);
end;

function NtxDeleteValueKey;
begin
  Result.Location := 'NtDeleteValueKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_SET_VALUE);
  // or KEY_READ under virtualization

  Result.Status := NtDeleteValueKey(hKey, TNtUnicodeString.From(ValueName));
end;

function NtxLoadKeyEx;
var
  hKey: THandle;
begin
  // Make sure we always get a handle
  if not BitTest(Flags and REG_APP_HIVE) then
    Flags := Flags or REG_LOAD_HIVE_OPEN_HANDLE;

  Result.Location := 'NtLoadKeyEx';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;

  Result.Status := NtLoadKeyEx(
    AttributeBuilder(KeyObjAttr).UseName(KeyPath).ToNative^,
    AttributeBuilder(FileObjAttr).UseName(FileName).ToNative^,
    Flags,
    TrustClassKey,
    0,
    AccessMaskOverride(KEY_ALL_ACCESS, KeyObjAttr),
    hKey,
    nil
  );

  if Result.IsSuccess then
    hxKey := Auto.CaptureHandle(hKey);
end;

function NtxUnloadKey;
var
  Flags: TRegUnloadFlags;
begin
  if Force then
    Flags := REG_FORCE_UNLOAD
  else
    Flags := 0;

  Result.Location := 'NtUnloadKey2';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;

  Result.Status := NtUnloadKey2(
    AttributeBuilder(ObjectAttributes).UseName(KeyName).ToNative^,
    Flags
  );
end;

function NtxSaveKey;
begin
  Result.Location := 'NtSaveKey';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA);
  Result.LastCall.ExpectedPrivilege := SE_BACKUP_PRIVILEGE;

  Result.Status := NtSaveKeyEx(hKey, hFile, Format);
end;

function NtxSaveMergedKeys;
begin
  Result.Location := 'NtSaveMergedKeys';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA);
  Result.LastCall.ExpectedPrivilege := SE_BACKUP_PRIVILEGE;

  Result.Status := NtSaveMergedKeys(hHighPrecedenceKey,
    hLowPrecedenceKey, hFile);
end;

function NtxRestoreKey;
begin
  Result.Location := 'NtRestoreKey';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_READ_DATA);
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;

  Result.Status := NtRestoreKey(hKey, hFile, Flags)
end;

function NtxEnumerateOpenedSubkeys;
var
  pObjAttr: PObjectAttributes;
  xMemory: IMemory<PKeyOpenSubkeysInformation>;
  RequiredSize: Cardinal;
  i: Integer;
begin
  pObjAttr := AttributeBuilder(ObjectAttributes).UseName(KeyName).ToNative;

  Result.Location := 'NtQueryOpenSubKeysEx';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;

  IMemory(xMemory) := Auto.AllocateDynamic($1000);
  repeat
    Result.Status := NtQueryOpenSubKeysEx(pObjAttr^, xMemory.Size, xMemory.Data,
      RequiredSize);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), RequiredSize, nil);

  if not Result.IsSuccess then
    Exit;

  SetLength(SubKeys, xMemory.Data.Count);

  for i := 0 to High(SubKeys) do
    with SubKeys[i] do
    begin
      ProcessId := xMemory.Data.KeyArray{$R-}[i]{$R+}.ProcessId;
      KeyName := xMemory.Data.KeyArray{$R-}[i]{$R+}.KeyName.ToString;
    end;
end;

function NtxNotifyChangeKey;
var
  ApcContext: IAnonymousIoApcContext;
  Isb: TIoStatusBlock;
begin
  Result.Location := 'NtNotifyChangeKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_NOTIFY);

  Result.Status := NtNotifyChangeKey(hKey, 0, GetApcRoutine(AsyncCallback),
    Pointer(ApcContext), PrepareApcIsb(ApcContext, AsyncCallback, Isb), Flags,
    WatchTree, nil, 0, Assigned(AsyncCallback));

  // Keep the context until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;
end;

end.
