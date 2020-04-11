unit NtUtils.Registry;

interface

uses
  Winapi.WinNt, Ntapi.ntregapi, NtUtils, NtUtils.Objects;

type
  TRegValueType = Ntapi.ntregapi.TRegValueType;

  TKeyBasicInfo = record
    LastWriteTime: TLargeInteger;
    TitleIndex: Cardinal;
    Name: String;
  end;

  TRegValueEntry = record
    ValueType: TRegValueType;
    ValueName: String;
  end;

{ Keys }

// Open a key
function NtxOpenKey(out hxKey: IHandle; Name: String;
  DesiredAccess: TAccessMask; Root: THandle = 0; OpenOptions: Cardinal = 0;
  Attributes: Cardinal = 0): TNtxStatus;

// Create a key
function NtxCreateKey(out hxKey: IHandle; Name: String;
  DesiredAccess: TAccessMask; Root: THandle = 0; CreateOptions: Cardinal = 0;
  Attributes: Cardinal = 0; Disposition: PRegDisposition = nil): TNtxStatus;

// Delete a key
function NtxDeleteKey(hKey: THandle): TNtxStatus;

// Rename a key
function NtxRenameKey(hKey: THandle; NewName: String): TNtxStatus;

// Enumerate sub-keys
function NtxEnumerateSubKeys(hKey: THandle; out SubKeys: TArray<String>)
  : TNtxStatus;

// Query variable-length key information
function NtxQueryInformationKey(hKey: THandle; InfoClass: TKeyInformationClass;
  out xMemory: IMemory): TNtxStatus;

// Query key basic information
function NtxQueryBasicKey(hKey: THandle; out Info: TKeyBasicInfo): TNtxStatus;

type
  NtxKey = class
    // Query fixed-size key information
    class function Query<T>(hKey: THandle; InfoClass: TKeyInformationClass;
      out Buffer: T): TNtxStatus; static;

    // Set fixed-size key information
    class function SetInfo<T>(hKey: THandle; InfoClass: TKeySetInformationClass;
      const Buffer: T): TNtxStatus; static;
  end;

{ Symbolic Links }

// Create a symbolic link key
function NtxCreateSymlinkKey(Source: String; Target: String;
  SourceRoot: THandle = 0; Options: Cardinal = 0): TNtxStatus;

// Delete a symbolic link key
function NtxDeleteSymlinkKey(Name: String; Root: THandle = 0; Options:
  Cardinal = 0): TNtxStatus;

{ Values }

// Enumerate values of a key
function NtxEnumerateValuesKey(hKey: THandle;
  out ValueNames: TArray<TRegValueEntry>): TNtxStatus;

// Query variable-length value information
function NtxQueryValueKey(hKey: THandle; ValueName: String;
  InfoClass: TKeyValueInformationClass; out Status: TNtxStatus): Pointer;

// Query value of a DWORD type
function NtxQueryDwordValueKey(hKey: THandle; ValueName: String;
  out Value: Cardinal): TNtxStatus;

// Query value of a string type
function NtxQueryStringValueKey(hKey: THandle; ValueName: String;
  out Value: String): TNtxStatus;

// Query value of a multi-string type
function NtxQueryMultiStringValueKey(hKey: THandle; ValueName: String;
  out Value: TArray<String>): TNtxStatus;

// Set value
function NtxSetValueKey(hKey: THandle; ValueName: String;
  ValueType: TRegValueType; Data: Pointer; DataSize: Cardinal): TNtxStatus;

// Set a DWORD value
function NtxSetDwordValueKey(hKey: THandle; ValueName: String; Value: Cardinal)
  : TNtxStatus;

// Set a string value
function NtxSetStringValueKey(hKey: THandle; ValueName: String; Value: String;
  ValueType: TRegValueType = REG_SZ): TNtxStatus;

// Set a multi-string value
function NtxSetMultiStringValueKey(hKey: THandle; ValueName: String;
  Value: TArray<String>): TNtxStatus;

// Delete a value
function NtxDeleteValueKey(hKey: THandle; ValueName: String): TNtxStatus;

{ Other }

// Mount a hive file to the registry
function NtxLoadKeyEx(out hxKey: IHandle; FileName: String; KeyPath: String;
  Flags: Cardinal = REG_LOAD_HIVE_OPEN_HANDLE; TrustClassKey: THandle = 0;
  FileRoot: THandle = 0): TNtxStatus;

// Unmount a hive file from the registry
function NtxUnloadKey(KeyName: String; Force: Boolean = False): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntseapi, DelphiUtils.Arrays;

{ Keys }

function NtxOpenKey(out hxKey: IHandle; Name: String;
  DesiredAccess: TAccessMask; Root: THandle; OpenOptions: Cardinal;
  Attributes: Cardinal): TNtxStatus;
var
  hKey: THandle;
  NameStr: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
begin
  NameStr.FromString(Name);
  InitializeObjectAttributes(ObjAttr, @NameStr, Attributes or
    OBJ_CASE_INSENSITIVE, Root);

  Result.Location := 'NtOpenKeyEx';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @KeyAccessType;

  Result.Status := NtOpenKeyEx(hKey, DesiredAccess, ObjAttr, OpenOptions);

  if Result.IsSuccess then
    hxKey := TAutoHandle.Capture(hKey);
end;

function NtxCreateKey(out hxKey: IHandle; Name: String;
  DesiredAccess: TAccessMask; Root: THandle; CreateOptions: Cardinal;
  Attributes: Cardinal; Disposition: PRegDisposition): TNtxStatus;
var
  hKey: THandle;
  NameStr: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
begin
  NameStr.FromString(Name);
  InitializeObjectAttributes(ObjAttr, @NameStr, Attributes or
    OBJ_CASE_INSENSITIVE, Root);

  Result.Location := 'NtCreateKey';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @KeyAccessType;

  Result.Status := NtCreateKey(hKey, DesiredAccess, ObjAttr, 0, nil,
    CreateOptions, Disposition);

  if Result.IsSuccess then
    hxKey := TAutoHandle.Capture(hKey);
end;

function NtxDeleteKey(hKey: THandle): TNtxStatus;
begin
  Result.Location := 'NtDeleteKey';
  Result.LastCall.Expects(_DELETE, @KeyAccessType);

  Result.Status := NtDeleteKey(hKey);
end;

function NtxRenameKey(hKey: THandle; NewName: String): TNtxStatus;
var
  NewNameStr: UNICODE_STRING;
begin
  NewNameStr.FromString(NewName);
  Result.Location := 'NtRenameKey';
  Result.LastCall.Expects(READ_CONTROL or KEY_SET_VALUE or KEY_CREATE_SUB_KEY,
    @KeyAccessType);

  // Or READ_CONTROL | KEY_NOTIFY | KEY_ENUMERATE_SUB_KEYS | KEY_QUERY_VALUE
  // in case of enabled virtualization

  Result.Status := NtRenameKey(hKey, NewNameStr)
end;

function NtxEnumerateSubKeys(hKey: THandle; out SubKeys: TArray<String>)
  : TNtxStatus;
var
  Index: Integer;
  Buffer: PKeyBasicInformation;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'NtEnumerateKey';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(KeyBasicInformation);
  Result.LastCall.InfoClassType := TypeInfo(TKeyInformationClass);
  Result.LastCall.Expects(KEY_ENUMERATE_SUB_KEYS, @KeyAccessType);

  SetLength(SubKeys, 0);

  Index := 0;
  repeat

    // Query sub-key name
    BufferSize := 0;
    repeat
      Buffer := AllocMem(BufferSize);

      Required := 0;
      Result.Status := NtEnumerateKey(hKey, Index, KeyBasicInformation, Buffer,
        BufferSize, Required);

      if not Result.IsSuccess then
        FreeMem(Buffer);

    until not NtxExpandBuffer(Result, BufferSize, Required);

    if Result.IsSuccess then
    begin
      SetLength(SubKeys, Length(SubKeys) + 1);
      SetString(SubKeys[High(SubKeys)], PWideChar(@Buffer.Name),
        Buffer.NameLength div SizeOf(WideChar));
      FreeMem(Buffer);
    end;

    Inc(Index);
  until not Result.IsSuccess;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

function NtxQueryInformationKey(hKey: THandle; InfoClass: TKeyInformationClass;
  out xMemory: IMemory): TNtxStatus;
var
  Buffer: Pointer;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'NtQueryKey';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TKeyInformationClass);

  if not (InfoClass in [KeyNameInformation, KeyHandleTagsInformation]) then
    Result.LastCall.Expects(KEY_QUERY_VALUE, @KeyAccessType);

  BufferSize := 0;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQueryKey(hKey, InfoClass, Buffer, BufferSize, Required);

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;

  until not NtxExpandBuffer(Result, BufferSize, Required);

  if Result.IsSuccess then
    xMemory := TAutoMemory.Capture(Buffer, BufferSize);
end;

function NtxQueryBasicKey(hKey: THandle; out Info: TKeyBasicInfo): TNtxStatus;
var
  xMemory: IMemory;
  Buffer: PKeyBasicInformation;
begin
  Result := NtxQueryInformationKey(hKey, KeyBasicInformation, xMemory);

  if Result.IsSuccess then
  begin
    Buffer := xMemory.Address;
    Info.LastWriteTime := Buffer.LastWriteTime;
    Info.TitleIndex := Buffer.TitleIndex;
    SetString(Info.Name, PWideChar(@Buffer.Name), Buffer.NameLength);
  end;
end;

class function NtxKey.Query<T>(hKey: THandle; InfoClass: TKeyInformationClass;
  out Buffer: T): TNtxStatus;
var
  Returned: Cardinal;
begin
  Result.Location := 'NtQueryKey';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TKeyInformationClass);

  if not (InfoClass in [KeyNameInformation, KeyHandleTagsInformation]) then
    Result.LastCall.Expects(KEY_QUERY_VALUE, @KeyAccessType);

  Result.Status := NtQueryKey(hKey, InfoClass, @Buffer, SizeOf(Buffer),
    Returned);
end;

class function NtxKey.SetInfo<T>(hKey: THandle;
  InfoClass: TKeySetInformationClass; const Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtSetInformationKey';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TKeySetInformationClass);

  if InfoClass <> KeySetHandleTagsInformation then
    Result.LastCall.Expects(KEY_SET_VALUE, @KeyAccessType);

  // Or READ_CONTROL | KEY_NOTIFY | KEY_ENUMERATE_SUB_KEYS | KEY_QUERY_VALUE
  // in case of enabled virtualization

  Result.Status := NtSetInformationKey(hKey, InfoClass, @Buffer,
    SizeOf(Buffer));
end;

{ Symbolic Links }

function NtxCreateSymlinkKey(Source: String; Target: String;
  SourceRoot: THandle; Options: Cardinal): TNtxStatus;
var
  hxKey: IHandle;
begin
  // Create a key
  Result := NtxCreateKey(hxKey, Source, KEY_SET_VALUE or KEY_CREATE_LINK,
    SourceRoot, Options or REG_OPTION_CREATE_LINK);

  if Result.IsSuccess then
  begin
    // Set its link target
    Result := NtxSetStringValueKey(hxKey.Handle, REG_SYMLINK_VALUE_NAME, Target,
      REG_LINK);

    // Undo key creation on failure
    if not Result.IsSuccess then
      NtxDeleteKey(hxKey.Handle);
  end;
end;

function NtxDeleteSymlinkKey(Name: String; Root: THandle; Options: Cardinal)
  : TNtxStatus;
var
  hxKey: IHandle;
begin
  Result := NtxOpenKey(hxKey, Name, _DELETE, Root, Options, OBJ_OPENLINK);

  if Result.IsSuccess then
    Result := NtxDeleteKey(hxKey.Handle);
end;

{ Values }

function NtxEnumerateValuesKey(hKey: THandle;
  out ValueNames: TArray<TRegValueEntry>): TNtxStatus;
var
  Index: Integer;
  Buffer: PKeyValueBasicInformation;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'NtEnumerateValueKey';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(KeyValueBasicInformation);
  Result.LastCall.InfoClassType := TypeInfo(TKeyValueInformationClass);
  Result.LastCall.Expects(KEY_QUERY_VALUE, @KeyAccessType);

  SetLength(ValueNames, 0);

  Index := 0;
  repeat

    // Query value name
    BufferSize := 0;
    repeat
      Buffer := AllocMem(BufferSize);

      Required := 0;
      Result.Status := NtEnumerateValueKey(hKey, Index,
        KeyValueBasicInformation, Buffer, BufferSize, Required);

      if not Result.IsSuccess then
        FreeMem(Buffer);

    until not NtxExpandBuffer(Result, BufferSize, Required);

    if Result.IsSuccess then
    begin
      SetLength(ValueNames, Length(ValueNames) + 1);
      ValueNames[High(ValueNames)].ValueType := Buffer.ValueType;
      SetString(ValueNames[High(ValueNames)].ValueName, PWideChar(@Buffer.Name),
        Buffer.NameLength div SizeOf(WideChar));
      FreeMem(Buffer);
    end;

    Inc(Index);
  until not Result.IsSuccess;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

function NtxQueryValueKey(hKey: THandle; ValueName: String;
  InfoClass: TKeyValueInformationClass; out Status: TNtxStatus): Pointer;
var
  NameStr: UNICODE_STRING;
  BufferSize, Required: Cardinal;
begin
  NameStr.FromString(ValueName);

  Status.Location := 'NtQueryValueKey';
  Status.LastCall.CallType := lcQuerySetCall;
  Status.LastCall.InfoClass := Cardinal(InfoClass);
  Status.LastCall.InfoClassType := TypeInfo(TKeyValueInformationClass);
  Status.LastCall.Expects(KEY_QUERY_VALUE, @KeyAccessType);

  BufferSize := 0;

  repeat
    // Make sure we have a gap for zero-terminate strings
    Result := AllocMem(BufferSize + SizeOf(WideChar));

    Required := 0;
    Status.Status := NtQueryValueKey(hKey, NameStr, InfoClass, Result,
      BufferSize, Required);

    if not Status.IsSuccess then
    begin
      FreeMem(Result);
      Result := nil;
    end;

  until not NtxExpandBuffer(Status, BufferSize, Required);
end;

function NtxQueryDwordValueKey(hKey: THandle; ValueName: String;
  out Value: Cardinal): TNtxStatus;
var
  Buffer: PKeyValuePartialInfromation;
begin
  Buffer := NtxQueryValueKey(hKey, ValueName,
    KeyValuePartialInformation, Result);

  if not Result.IsSuccess then
    Exit;

  if Buffer.DataLength < SizeOf(Cardinal) then
  begin
    Result.Status := STATUS_INFO_LENGTH_MISMATCH;
    Exit;
  end;

  case Buffer.ValueType of
    REG_DWORD:
      Value := PCardinal(@Buffer.Data)^;
  else
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
  end;

  FreeMem(Buffer);
end;

function NtxQueryStringValueKey(hKey: THandle; ValueName: String;
  out Value: String): TNtxStatus;
var
  Buffer: PKeyValuePartialInfromation;
begin
  Buffer := NtxQueryValueKey(hKey, ValueName,
    KeyValuePartialInformation, Result);

  if not Result.IsSuccess then
    Exit;

  case Buffer.ValueType of
    REG_SZ, REG_EXPAND_SZ, REG_LINK:
      Value := String(PWideChar(@Buffer.Data));
  else
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
  end;

  FreeMem(Buffer);
end;

function NtxQueryMultiStringValueKey(hKey: THandle; ValueName: String;
  out Value: TArray<String>): TNtxStatus;
var
  Buffer: PKeyValuePartialInfromation;
begin
  Buffer := NtxQueryValueKey(hKey, ValueName,
    KeyValuePartialInformation, Result);

  if not Result.IsSuccess then
    Exit;

  case Buffer.ValueType of
    REG_SZ, REG_EXPAND_SZ, REG_LINK:
      begin
        SetLength(Value, 1);
        Value[0] := String(PWideChar(@Buffer.Data));
      end;

    REG_MULTI_SZ:
        Value := ParseMultiSz(PWideChar(@Buffer.Data), Buffer.DataLength);
  else
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
  end;

  FreeMem(Buffer);
end;

function NtxSetValueKey(hKey: THandle; ValueName: String;
  ValueType: TRegValueType; Data: Pointer; DataSize: Cardinal): TNtxStatus;
var
  ValueNameStr: UNICODE_STRING;
begin
  ValueNameStr.FromString(ValueName);
  Result.Location := 'NtSetValueKey';
  Result.LastCall.Expects(KEY_SET_VALUE, @KeyAccessType);

  Result.Status := NtSetValueKey(hKey, ValueNameStr, 0, ValueType, Data,
    DataSize);
end;

function NtxSetDwordValueKey(hKey: THandle; ValueName: String; Value: Cardinal)
  : TNtxStatus;
begin
  Result := NtxSetValueKey(hKey, ValueName, REG_DWORD, @Value, SizeOf(Value));
end;

function NtxSetStringValueKey(hKey: THandle; ValueName: String; Value: String;
  ValueType: TRegValueType): TNtxStatus;
begin
  Result := NtxSetValueKey(hKey, ValueName, ValueType, PWideChar(Value),
    Length(Value) * SizeOf(WideChar));
end;

function NtxSetMultiStringValueKey(hKey: THandle; ValueName: String;
  Value: TArray<String>): TNtxStatus;
var
  Buffer, pCurrentPosition: PWideChar;
  BufferSize: Cardinal;
  i: Integer;
begin
  // Calculate required memory
  BufferSize := SizeOf(WideChar); // Include ending #0
  for i := 0 to High(Value) do
    Inc(BufferSize, (Length(Value[i]) + 1) * SizeOf(WideChar));

  Buffer := AllocMem(BufferSize);

  pCurrentPosition := Buffer;
  for i := 0 to High(Value) do
  begin
    Move(PWideChar(Value[i])^, pCurrentPosition^,
      Length(Value[i]) * SizeOf(WideChar));
    Inc(pCurrentPosition, Length(Value[i]) + 1);
  end;

  Result := NtxSetValueKey(hKey, ValueName, REG_MULTI_SZ, Buffer, BufferSize);
  FreeMem(Buffer);
end;

function NtxDeleteValueKey(hKey: THandle; ValueName: String): TNtxStatus;
var
  ValueNameStr: UNICODE_STRING;
begin
  ValueNameStr.FromString(ValueName);
  Result.Location := 'NtDeleteValueKey';
  Result.LastCall.Expects(KEY_SET_VALUE, @KeyAccessType);

  // Or READ_CONTROL | KEY_NOTIFY | KEY_ENUMERATE_SUB_KEYS | KEY_QUERY_VALUE
  // in case of enabled virtualization

  Result.Status := NtDeleteValueKey(hKey, ValueNameStr);
end;

function NtxLoadKeyEx(out hxKey: IHandle; FileName: String; KeyPath: String;
  Flags: Cardinal; TrustClassKey: THandle; FileRoot: THandle): TNtxStatus;
var
  Target, Source: TObjectAttributes;
  KeyStr, FileStr: UNICODE_STRING;
  hKey: THandle;
begin
  FileStr.FromString(FileName);
  InitializeObjectAttributes(Source, @FileStr, OBJ_CASE_INSENSITIVE, FileRoot);

  KeyStr.FromString(KeyPath);
  InitializeObjectAttributes(Target, @KeyStr, OBJ_CASE_INSENSITIVE);

  Result.Location := 'NtLoadKeyEx';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;

  Result.Status := NtLoadKeyEx(Target, Source, Flags, TrustClassKey, 0,
    KEY_ALL_ACCESS, hKey, nil);

  if Result.IsSuccess then
    hxKey := TAutoHandle.Capture(hKey);
end;

function NtxUnloadKey(KeyName: String; Force: Boolean): TNtxStatus;
var
  KeyStr: UNICODE_STRING;
  ObjAttr: TObjectAttributes;
  Flags: Cardinal;
begin
  KeyStr.FromString(KeyName);
  InitializeObjectAttributes(ObjAttr, @KeyStr);

  if Force then
    Flags := REG_FORCE_UNLOAD
  else
    Flags := 0;

  Result.Location := 'NtUnloadKey2';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;
  Result.Status := NtUnloadKey2(ObjAttr, Flags);
end;

end.
