unit NtUtils.Registry;

{
  This module provides support for working with registry via Native API.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntregapi, Ntapi.ntioapi, Ntapi.ntseapi, NtUtils,
  NtUtils.Objects, DelphiUtils.Async, DelphiApi.Reflection;

type
  TNtxKeyCreationBehavior = set of (
    // Create missing parent keys if necessary
    kcRecursive,

    // Apply the supplied security descriptor when creating missing parent keys
    kcUseSecurityWithRecursion
  );

{
  Info class          | Name | Timestamp | TitleIndex | Class | Counters
  ------------------- | ---- | --------- | ---------- | ----- | --------
  KeyBasicInformation |  +   |     +     |     +      |       |
  KeyNodeInformation  |  +   |     +     |     +      |   +   |
  KeyFullInformation  |      |     +     |     +      |   +   |    +
}

  TNtxRegKeyField = (
    ksfName,
    ksfLastWriteTime,
    ksfTitleIndex,
    ksfClassName,
    ksfCounters
  );

  TNtxRegKeyFields = set of TNtxRegKeyField;

  TNtxRegKeyCounters = record
    SubKeys: Cardinal;
    [Bytes] MaxNameLen: Cardinal;
    [Bytes] MaxClassLen: Cardinal;
    Values: Cardinal;
    [Bytes] MaxValueNameLen: Cardinal;
    [Bytes] MaxValueDataLen: Cardinal;
  end;

  TNtxRegKey = record
    ValidFields: TNtxRegKeyFields;
    Name: String;
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    ClassName: String;
    [Aggregate] Counters: TNtxRegKeyCounters;
  end;

{
  Info class                 | Name | Type  | TitleIndex | Data
  -------------------------- | ---- | ----- | ---------- | -----
  KeyValueBasicInformation   |  +   |   +   |     +      |
  KeyValueFullInformation    |  +   |   +   |     +      |   +
  KeyValuePartialInformation |      |   +   |     +      |   +
}

  TNtxRegValueField = (
    rvfName,
    rvfValueType,
    rvfTitleIndex,
    rvfData
  );

  TNtxRegValueFields = set of TNtxRegValueField;

  TNtxRegValue = record
    ValidFields: TNtxRegValueFields;
    Name: String;
    ValueType: TRegValueType;
    TitleIndex: Cardinal;
    [MayReturnNil] Data: IMemory;
  end;

  TNtxSubKeyProcessEntry = record
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

// Open a key in an (either normal or registry) transaction
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
  CreationBehavior: TNtxKeyCreationBehavior = [kcRecursive];
  [out, opt] Disposition: PRegDisposition = nil
): TNtxStatus;

// Create a key in an (either normal or registry) transaction
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxCreateKeyTransacted(
  out hxKey: IHandle;
  [Access(TRANSACTION_ENLIST)] hTransaction: THandle;
  const Name: String;
  DesiredAccess: TRegKeyAccessMask;
  CreateOptions: TRegOpenOptions = 0;
  [opt] const ObjectAttributes: IObjectAttributes = nil;
  CreationBehavior: TNtxKeyCreationBehavior = [kcRecursive];
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

// Enumerate sub-keys of the specified key one-by-one
function NtxEnumerateKey(
  [Access(KEY_ENUMERATE_SUB_KEYS)] hKey: THandle;
  Index: Cardinal;
  out SubKey: TNtxRegKey;
  InfoClass: TKeyInformationClass = KeyBasicInformation
): TNtxStatus;

// Enumerate all sub-keys of the specified key
function NtxEnumerateKeys(
  [Access(KEY_ENUMERATE_SUB_KEYS)] hKey: THandle;
  out SubKeys: TArray<TNtxRegKey>;
  InfoClass: TKeyInformationClass = KeyBasicInformation
): TNtxStatus;

// Make a for-in iterator for enumerating sub-keys of the specified key.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function NtxIterateKeys(
  [out, opt] Status: PNtxStatus;
  const hxKey: IHandle;
  InfoClass: TKeyInformationClass = KeyBasicInformation
): IEnumerable<TNtxRegKey>;

// Query variable-size key information
function NtxQueryKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  out Info: TNtxRegKey;
  InfoClass: TKeyInformationClass = KeyBasicInformation
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
  CreationBehavior: TNtxKeyCreationBehavior = [kcRecursive]
): TNtxStatus;

// Delete a symbolic link key
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function NtxDeleteSymlinkKey(
  [Access(_DELETE)] const Name: String;
  [opt] const Root: IHandle = nil;
  Options: TRegOpenOptions = 0
): TNtxStatus;

{ Values }

// Enumerate values under the specified key one-by-one
function NtxEnumerateValueKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  Index: Integer;
  out Value: TNtxRegValue;
  InfoClass: TKeyValueInformationClass = KeyValueBasicInformation
): TNtxStatus;

// Enumerate all values under the specified key
function NtxEnumerateValuesKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  out Values: TArray<TNtxRegValue>;
  InfoClass: TKeyValueInformationClass = KeyValueBasicInformation
): TNtxStatus;

// Make a for-in iterator for enumerating values under the specified key.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function NtxIterateValuesKey(
  [out, opt] Status: PNtxStatus;
  const hxKey: IHandle;
  InfoClass: TKeyValueInformationClass = KeyValueBasicInformation
): IEnumerable<TNtxRegValue>;

// Query information about a value by name
function NtxQueryValueKey(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  out Value: TNtxRegValue;
  InfoClass: TKeyValueInformationClass = KeyValuePartialInformation;
  ExpectedSize: Cardinal = 0
): TNtxStatus;

// Query value of a 32-bit integer type
function NtxQueryValueKeyUInt32(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  out Value: Cardinal
): TNtxStatus;

// Query value of a 64-bit integer type
function NtxQueryValueKeyUInt64(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  out Value: UInt64
): TNtxStatus;

// Query value of a string type
function NtxQueryValueKeyString(
  [Access(KEY_QUERY_VALUE)] hKey: THandle;
  const ValueName: String;
  out Value: String;
  [out, opt] ValueType: PRegValueType = nil
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

// Set a 32-bit integer value
function NtxSetValueKeyUInt32(
  [Access(KEY_SET_VALUE)] hKey: THandle;
  const ValueName: String;
  Value: Cardinal;
  ValueType: TRegValueType = REG_DWORD
): TNtxStatus;

// Set a 64-bit integer value
function NtxSetValueKeyUInt64(
  [Access(KEY_SET_VALUE)] hKey: THandle;
  const ValueName: String;
  const Value: UInt64
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
  out SubKeys: TArray<TNtxSubKeyProcessEntry>;
  const KeyName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Subscribe for registry changes notifications
function NtxNotifyChangeKey(
  [Access(KEY_NOTIFY)] hKey: THandle;
  Flags: TRegNotifyFlags;
  WatchTree: Boolean;
  [opt] AsyncCallback: TAnonymousApcCallback
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.nttmapi, NtUtils.SysUtils,
  DelphiUtils.AutoObjects, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

  // Do not adjust parent's security unless explicitly told to
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

  // Do not adjust parent's security unless explicitly told to
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
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_WRITE);
  // or KEY_READ under virtualization

  Result.Status := NtRenameKey(hKey, TNtUnicodeString.From(NewName));
end;

function NtxpCaptureKeyInfo(
  const Buffer: IMemory;
  InfoClass: TKeyInformationClass
): TNtxRegKey;
var
  BufferBasic: PKeyBasicInformation;
  BufferNode: PKeyNodeInformation;
  BufferFull: PKeyFullInformation;
begin
  Result := Default(TNtxRegKey);

  case InfoClass of
    KeyBasicInformation:
    begin
      BufferBasic := Buffer.Data;
      Result.ValidFields := [ksfName, ksfLastWriteTime, ksfTitleIndex];
      SetString(Result.Name, PWideChar(@BufferBasic.Name[0]),
        BufferBasic.NameLength div SizeOf(WideChar));
      Result.LastWriteTime := BufferBasic.LastWriteTime;
      Result.TitleIndex := BufferBasic.TitleIndex;
    end;

    KeyNodeInformation:
    begin
      BufferNode := Buffer.Data;
      Result.ValidFields := [ksfName, ksfLastWriteTime, ksfTitleIndex,
        ksfClassName];

      SetString(Result.Name, PWideChar(@BufferNode.Name[0]),
        BufferNode.NameLength div SizeOf(WideChar));
      SetString(Result.ClassName, PWideChar(Buffer.Offset(BufferNode
        .ClassOffset)), BufferNode.ClassLength div SizeOf(WideChar));

      Result.LastWriteTime := BufferNode.LastWriteTime;
      Result.TitleIndex := BufferNode.TitleIndex;
    end;

    KeyFullInformation:
    begin
      BufferFull := Buffer.Data;
      Result.ValidFields := [ksfLastWriteTime, ksfTitleIndex, ksfClassName,
        ksfCounters];

      SetString(Result.ClassName, PWideChar(Buffer.Offset(BufferFull
        .ClassOffset)), BufferFull.ClassLength div SizeOf(WideChar));

      Result.LastWriteTime := BufferFull.LastWriteTime;
      Result.TitleIndex := BufferFull.TitleIndex;
      Result.Counters.SubKeys := BufferFull.SubKeys;
      Result.Counters.MaxNameLen := BufferFull.MaxNameLen;
      Result.Counters.MaxClassLen := BufferFull.MaxClassLen;
      Result.Counters.Values := BufferFull.Values;
      Result.Counters.MaxValueNameLen := BufferFull.MaxValueNameLen;
      Result.Counters.MaxValueDataLen := BufferFull.MaxValueDataLen;
    end;
  end;
end;

function NtxEnumerateKey;
const
  INITIAL_SIZE = 100;
var
  Required: Cardinal;
  Buffer: IMemory;
begin
  // Select info-class specific buffer growth method
  case InfoClass of
    KeyBasicInformation, KeyNodeInformation, KeyFullInformation:
      ; // pass through
  else
    Result.Location := 'NtxEnumerateSubKey';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Retrieve information by index
  Result.Location := 'NtEnumerateKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_ENUMERATE_SUB_KEYS);

  Buffer := Auto.AllocateDynamic(INITIAL_SIZE);
  repeat
    Required := 0;
    Result.Status := NtEnumerateKey(hKey, Index, InfoClass, Buffer.Data,
      Buffer.Size, Required);
  until not NtxExpandBufferEx(Result, Buffer, Required, nil);

  if Result.IsSuccess then
    SubKey := NtxpCaptureKeyInfo(Buffer, InfoClass);
end;

function NtxEnumerateKeys;
var
  Index: Cardinal;
  SubKey: TNtxRegKey;
begin
  Index := 0;
  SubKeys := nil;

  while NtxEnumerateKey(hKey, Index, SubKey, InfoClass).HasEntry(Result) do
  begin
    SetLength(SubKeys, Succ(Length(SubKeys)));
    SubKeys[High(SubKeys)] := SubKey;
    Inc(Index);
  end;
end;

function NtxIterateKeys;
var
  Index: Cardinal;
begin
  Index := 0;

  Result := NtxAuto.Iterate<TNtxRegKey>(Status,
    function (out Current: TNtxRegKey): TNtxStatus
    begin
      // Retrieve the sub-key by index
      Result := NtxEnumerateKey(hxKey.Handle, Index, Current,
        InfoClass);

      if not Result.IsSuccess then
        Exit;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function NtxQueryKey;
const
  INITIAL_SIZE = 100;
var
  Required: Cardinal;
  Buffer: IMemory;
begin
  case InfoClass of
    KeyBasicInformation, KeyNodeInformation, KeyFullInformation,
    KeyNameInformation:
      ; // Pass through
  else
    // For fixed-size info classes, use the generic wrapper
    Result.Location := 'NtxQueryKey';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result.Location := 'NtQueryKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  if not (InfoClass in [KeyNameInformation, KeyHandleTagsInformation]) then
    Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  // Retrieve the information
  Buffer := Auto.AllocateDynamic(INITIAL_SIZE);
  repeat
    Required := 0;
    Result.Status := NtQueryKey(hKey, InfoClass, Buffer.Data, Buffer.Size,
      Required);
  until not NtxExpandBufferEx(Result, Buffer, Required, nil);

  if Result.IsSuccess then
    Info := NtxpCaptureKeyInfo(Buffer, InfoClass);
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
    Result.LastCall.Expects<TRegKeyAccessMask>(KEY_SET_VALUE);
    // or KEY_READ under virtualization

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

function NtxpCaptureKeyValueInfo(
  const Buffer: IMemory;
  InfoClass: TKeyValueInformationClass
): TNtxRegValue;
var
  BufferBasic: PKeyValueBasicInformation;
  BufferFull: PKeyValueFullInformation;
  BufferPartial: PKeyValuePartialInformation;
begin
  Result := Default(TNtxRegValue);

  case InfoClass of
    KeyValueBasicInformation:
    begin
      BufferBasic := Buffer.Data;
      Result.ValidFields := [rvfName, rvfValueType, rvfTitleIndex];
      SetString(Result.Name, PWideChar(@BufferBasic.Name[0]),
        BufferBasic.NameLength div SizeOf(WideChar));
      Result.ValueType := BufferBasic.ValueType;
      Result.TitleIndex := BufferBasic.TitleIndex;
    end;

    KeyValueFullInformation:
    begin
      BufferFull := Buffer.Data;
      Result.ValidFields := [rvfName, rvfValueType, rvfTitleIndex, rvfData];
      SetString(Result.Name, PWideChar(@BufferFull.Name[0]),
        BufferFull.NameLength div SizeOf(WideChar));
      Result.ValueType := BufferFull.ValueType;
      Result.TitleIndex := BufferFull.TitleIndex;
      Result.Data := Auto.CopyDynamic(Buffer.Offset(BufferFull.DataOffset),
        BufferFull.DataLength);
    end;

    KeyValuePartialInformation:
    begin
      BufferPartial := Buffer.Data;
      Result.ValidFields := [rvfValueType, rvfTitleIndex, rvfData];
      Result.ValueType := BufferPartial.ValueType;
      Result.TitleIndex := BufferPartial.TitleIndex;
      Result.Data := Auto.CopyDynamic(@BufferPartial.Data,
        BufferPartial.DataLength);
    end;
  end;
end;

function NtxEnumerateValueKey;
const
  INITIAL_SIZE = 100;
var
  Required: Cardinal;
  Buffer: IMemory;
begin
  // Select info-class specific buffer growth method
  case InfoClass of
    KeyValueBasicInformation, KeyValueFullInformation,
    KeyValuePartialInformation:
      ; // pass through
  else
    Result.Location := 'NtxEnumerateValueKey';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Retrieve information by index
  Result.Location := 'NtEnumerateValueKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  Buffer := Auto.AllocateDynamic(INITIAL_SIZE);
  repeat
    Required := 0;
    Result.Status := NtEnumerateValueKey(hKey, Index, InfoClass, Buffer.Data,
      Buffer.Size, Required);
  until not NtxExpandBufferEx(Result, Buffer, Required, nil);

  if Result.IsSuccess then
    Value := NtxpCaptureKeyValueInfo(Buffer, InfoClass);
end;

function NtxEnumerateValuesKey;
var
  Index: Cardinal;
  Value: TNtxRegValue;
begin
  Index := 0;
  Values := nil;

  while NtxEnumerateValueKey(hKey, Index, Value, InfoClass).HasEntry(Result) do
  begin
    SetLength(Values, Succ(Length(Values)));
    Values[High(Values)] := Value;
    Inc(Index);
  end;
end;

function NtxIterateValuesKey;
var
  Index: Cardinal;
begin
  Index := 0;

  Result := NtxAuto.Iterate<TNtxRegValue>(Status,
    function (out Current: TNtxRegValue): TNtxStatus
    begin
      // Retrieve the value by index
      Result := NtxEnumerateValueKey(hxKey.Handle, Index, Current,
        InfoClass);

      if not Result.IsSuccess then
        Exit;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function NtxQueryValueKey;
var
  NameStr: TNtUnicodeString;
  Required: Cardinal;
  Buffer: IMemory;
begin
  case InfoClass of
    KeyValueBasicInformation:   Required := SizeOf(TKeyValueBasicInformation);
    KeyValueFullInformation:    Required := SizeOf(TKeyValueFullInformation);
    KeyValuePartialInformation: Required := SizeOf(TKeyValuePartialInformation);
  else
    // For fixed-size info classes, use the generic wrapper
    Result.Location := 'NtxQueryValueKey';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result.Location := 'NtQueryValueKey';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  // Retrieve value information
  Inc(Required, ExpectedSize);
  NameStr := TNtUnicodeString.From(ValueName);
  Buffer := Auto.AllocateDynamic(Required);
  repeat
    Required := 0;
    Result.Status := NtQueryValueKey(hKey, NameStr, InfoClass, Buffer.Data,
      Buffer.Size, Required);
  until not NtxExpandBufferEx(Result, Buffer, Required, nil);

  // Capture it
  if Result.IsSuccess then
    Value := NtxpCaptureKeyValueInfo(Buffer, InfoClass);
end;

function NtxQueryValueKeyUInt32;
var
  NameStr: TNtUnicodeString;
  Required: Cardinal;
  Buffer: IMemory<PKeyValuePartialInformation>;
begin
  NameStr := TNtUnicodeString.From(ValueName);
  Required := SizeOf(TKeyValuePartialInformation) + SizeOf(Value);
  IMemory(Buffer) := Auto.AllocateDynamic(Required);

  Result.Location := 'NtQueryValueKey';
  Result.LastCall.UsesInfoClass(KeyValuePartialInformation, icQuery);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);
  Result.Status := NtQueryValueKey(hKey, NameStr, KeyValuePartialInformation,
    Buffer.Data, Buffer.Size, Required);

  if not Result.IsSuccess then
    Exit;

  if not (Buffer.Data.ValueType in [REG_DWORD, REG_DWORD_BIG_ENDIAN]) then
  begin
    Result.Location := 'NtxQueryValueKeyUInt32';
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    Exit;
  end;

  if Buffer.Data.DataLength <> SizeOf(Value) then
  begin
    Result.Location := 'NtxQueryValueKeyUInt32';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  Value := PCardinal(@Buffer.Data.Data)^;

  if Buffer.Data.ValueType = REG_DWORD_BIG_ENDIAN then
    Value := RtlxSwapEndianness(Value);
end;

function NtxQueryValueKeyUInt64;
var
  NameStr: TNtUnicodeString;
  Required: Cardinal;
  Buffer: IMemory<PKeyValuePartialInformation>;
begin
  NameStr := TNtUnicodeString.From(ValueName);
  Required := SizeOf(TKeyValuePartialInformation) + SizeOf(Value);
  IMemory(Buffer) := Auto.AllocateDynamic(Required);

  Result.Location := 'NtQueryValueKey';
  Result.LastCall.UsesInfoClass(KeyValuePartialInformation, icQuery);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);
  Result.Status := NtQueryValueKey(hKey, NameStr, KeyValuePartialInformation,
    Buffer.Data, Buffer.Size, Required);

  if not Result.IsSuccess then
    Exit;

  if Buffer.Data.ValueType <> REG_QWORD then
  begin
    Result.Location := 'NtxQueryValueKeyUInt64';
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    Exit;
  end;

  if Buffer.Data.DataLength <> SizeOf(Value) then
  begin
    Result.Location := 'NtxQueryValueKeyUInt64';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  Value := PUInt64(@Buffer.Data.Data)^;
end;

function NtxQueryValueKeyString;
var
  Info: TNtxRegValue;
begin
  Result := NtxQueryValueKey(hKey, ValueName, Info, KeyValuePartialInformation);

  if not Result.IsSuccess then
    Exit;

  case Info.ValueType of
    // Normal strings should be zero-terminated
    REG_SZ, REG_EXPAND_SZ:
      Value := RtlxCaptureString(PWideChar(Info.Data.Data),
        Info.Data.Size div SizeOf(WideChar));

    // Symlinks store the target path as-is
    REG_LINK:
      SetString(Value, PWideChar(Info.Data.Data),
        Info.Data.Size div SizeOf(WideChar));
  else
    Result.Location := 'NtxQueryValueKeyString';
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    Exit;
  end;

  if Assigned(ValueType) then
    ValueType^ := Info.ValueType;
end;

function NtxQueryValueKeyMultiString;
var
  Info: TNtxRegValue;
begin
  Result := NtxQueryValueKey(hKey, ValueName, Info, KeyValuePartialInformation);

  if not Result.IsSuccess then
    Exit;

  case Info.ValueType of
    REG_SZ, REG_EXPAND_SZ, REG_MULTI_SZ:
      Value := RtlxParseWideMultiSz(PWideMultiSz(Info.Data.Data),
        Info.Data.Size div SizeOf(WideChar));
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

function NtxSetValueKeyUInt32;
begin
  if ValueType = REG_DWORD_BIG_ENDIAN then
    Value := RtlxSwapEndianness(Value)
  else if ValueType <> REG_DWORD then
  begin
    Result.Location := 'NtxSetValueKeyUInt32';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result := NtxSetValueKey(hKey, ValueName, ValueType, @Value, SizeOf(Value));
end;

function NtxSetValueKeyUInt64;
begin
  Result := NtxSetValueKey(hKey, ValueName, REG_QWORD, @Value, SizeOf(Value));
end;

function NtxSetValueKeyString;
var
  Size: Cardinal;
begin
  // Symbolic links should not be zero-terminated; other strings should
  if ValueType = REG_LINK then
    Size := StringSizeNoZero(Value)
  else if ValueType in [REG_SZ, REG_EXPAND_SZ] then
    Size := StringSizeZero(Value)
  else
  begin
    Result.Location := 'NtxSetValueKeyString';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result := NtxSetValueKey(hKey, ValueName, ValueType, PWideChar(Value), Size);
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
  begin
    SubKeys[i].ProcessId := xMemory.Data
      .KeyArray{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.ProcessId;
    SubKeys[i].KeyName := xMemory.Data
      .KeyArray{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF}.KeyName.ToString;
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
