unit NtUtils.Registry;

interface

uses
  Winapi.WinNt, Ntapi.ntregapi, NtUtils, NtUtils.Objects,
  DelphiUtils.AutoObject;

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

// Enumerate keys using an information class
function NtxEnumerateKey(hKey: THandle; Index: Integer; InfoClass:
  TKeyInformationClass; out xMemory: IMemory; InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil): TNtxStatus;

// Enumerate sub-keys
function NtxEnumerateSubKeys(hKey: THandle; out SubKeys: TArray<String>)
  : TNtxStatus;

// Query variable-length key information
function NtxQueryInformationKey(hKey: THandle; InfoClass: TKeyInformationClass;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil): TNtxStatus;

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

// Enumerate values using an information class
function NtxEnumerateValueKey(hKey: THandle; Index: Integer; InfoClass:
  TKeyValueInformationClass; out xMemory: IMemory; InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil): TNtxStatus;

// Enumerate values of a key
function NtxEnumerateValuesKey(hKey: THandle;
  out ValueNames: TArray<TRegValueEntry>): TNtxStatus;

// Query variable-length value information
function NtxQueryValueKey(hKey: THandle; ValueName: String; InfoClass:
  TKeyValueInformationClass; out xMemory: IMemory; InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil): TNtxStatus;

// Query raw value data of a key
function NtxQueryPartialValueKey(hKey: THandle; ValueName: String;
  ExpectedSize: Cardinal; out xMemory: IMemory<PKeyValuePartialInfromation>):
  TNtxStatus;

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
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(Name).RefOrNull,
    Attributes or OBJ_CASE_INSENSITIVE, Root);

  Result.Location := 'NtOpenKeyEx';
  Result.LastCall.AttachAccess<TRegKeyAccessMask>(DesiredAccess);

  Result.Status := NtOpenKeyEx(hKey, DesiredAccess, ObjAttr, OpenOptions);

  if Result.IsSuccess then
    hxKey := TAutoHandle.Capture(hKey);
end;

function NtxCreateKey(out hxKey: IHandle; Name: String;
  DesiredAccess: TAccessMask; Root: THandle; CreateOptions: Cardinal;
  Attributes: Cardinal; Disposition: PRegDisposition): TNtxStatus;
var
  hKey: THandle;
  ObjAttr: TObjectAttributes;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(Name).RefOrNull,
    Attributes or OBJ_CASE_INSENSITIVE, Root);

  Result.Location := 'NtCreateKey';
  Result.LastCall.AttachAccess<TRegKeyAccessMask>(DesiredAccess);

  Result.Status := NtCreateKey(hKey, DesiredAccess, ObjAttr, 0, nil,
    CreateOptions, Disposition);

  if Result.IsSuccess then
    hxKey := TAutoHandle.Capture(hKey);
end;

function NtxDeleteKey(hKey: THandle): TNtxStatus;
begin
  Result.Location := 'NtDeleteKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(_DELETE);

  Result.Status := NtDeleteKey(hKey);
end;

function NtxRenameKey(hKey: THandle; NewName: String): TNtxStatus;
begin
  Result.Location := 'NtRenameKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(READ_CONTROL or KEY_SET_VALUE or
    KEY_CREATE_SUB_KEY);

  // Or READ_CONTROL | KEY_NOTIFY | KEY_ENUMERATE_SUB_KEYS | KEY_QUERY_VALUE
  // in case of enabled virtualization

  Result.Status := NtRenameKey(hKey, TNtUnicodeString.From(NewName));
end;

function NtxEnumerateKey(hKey: THandle; Index: Integer; InfoClass:
  TKeyInformationClass; out xMemory: IMemory; InitialBuffer: Cardinal;
  GrowthMethod: TBufferGrowthMethod): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'NtEnumerateKey';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_ENUMERATE_SUB_KEYS);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtEnumerateKey(hKey, Index, InfoClass, xMemory.Data,
      xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxEnumerateSubKeys(hKey: THandle; out SubKeys: TArray<String>)
  : TNtxStatus;
var
  xMemory: IMemory<PKeyBasicInformation>;
  Index: Integer;
begin
  SetLength(SubKeys, 0);

  Index := 0;
  repeat
    // Query sub-key name
    Result := NtxEnumerateKey(hKey, Index, KeyBasicInformation,
      IMemory(xMemory));

    if Result.IsSuccess then
    begin
      SetLength(SubKeys, Length(SubKeys) + 1);
      SetString(SubKeys[High(SubKeys)], PWideChar(@xMemory.Data.Name),
        xMemory.Data.NameLength div SizeOf(WideChar));
    end;

    Inc(Index);
  until not Result.IsSuccess;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

function NtxQueryInformationKey(hKey: THandle; InfoClass: TKeyInformationClass;
  out xMemory: IMemory; InitialBuffer: Cardinal; GrowthMethod:
  TBufferGrowthMethod): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQueryKey';
  Result.LastCall.AttachInfoClass(InfoClass);

  if not (InfoClass in [KeyNameInformation, KeyHandleTagsInformation]) then
    Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryKey(hKey, InfoClass, xMemory.Data, xMemory.Size,
      Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxQueryBasicKey(hKey: THandle; out Info: TKeyBasicInfo): TNtxStatus;
var
  xMemory: IMemory<PKeyBasicInformation>;
begin
  Result := NtxQueryInformationKey(hKey, KeyBasicInformation, IMemory(xMemory));

  if Result.IsSuccess then
  begin
    Info.LastWriteTime := xMemory.Data.LastWriteTime;
    Info.TitleIndex := xMemory.Data.TitleIndex;
    SetString(Info.Name, PWideChar(@xMemory.Data.Name),
      xMemory.Data.NameLength div SizeOf(WideChar));
  end;
end;

class function NtxKey.Query<T>(hKey: THandle; InfoClass: TKeyInformationClass;
  out Buffer: T): TNtxStatus;
var
  Returned: Cardinal;
begin
  Result.Location := 'NtQueryKey';
  Result.LastCall.AttachInfoClass(InfoClass);

  if not (InfoClass in [KeyNameInformation, KeyHandleTagsInformation]) then
    Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  Result.Status := NtQueryKey(hKey, InfoClass, @Buffer, SizeOf(Buffer),
    Returned);
end;

class function NtxKey.SetInfo<T>(hKey: THandle;
  InfoClass: TKeySetInformationClass; const Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtSetInformationKey';
  Result.LastCall.AttachInfoClass(InfoClass);

  if InfoClass <> KeySetHandleTagsInformation then
    Result.LastCall.Expects<TRegKeyAccessMask>(KEY_SET_VALUE);

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

function NtxEnumerateValueKey(hKey: THandle; Index: Integer; InfoClass:
  TKeyValueInformationClass; out xMemory: IMemory; InitialBuffer: Cardinal;
  GrowthMethod: TBufferGrowthMethod): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'NtEnumerateValueKey';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtEnumerateValueKey(hKey, Index, InfoClass, xMemory.Data,
      xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function NtxEnumerateValuesKey(hKey: THandle;
  out ValueNames: TArray<TRegValueEntry>): TNtxStatus;
var
  Index: Integer;
  xMemory: IMemory<PKeyValueBasicInformation>;
begin
  SetLength(ValueNames, 0);

  Index := 0;
  repeat
    Result := NtxEnumerateValueKey(hKey, Index, KeyValueBasicInformation,
      IMemory(xMemory));

    if Result.IsSuccess then
    begin
      SetLength(ValueNames, Length(ValueNames) + 1);
      ValueNames[High(ValueNames)].ValueType := xMemory.Data.ValueType;
      SetString(ValueNames[High(ValueNames)].ValueName, PWideChar(
        @xMemory.Data.Name), xMemory.Data.NameLength div SizeOf(WideChar));
    end;

    Inc(Index);
  until not Result.IsSuccess;

  if Result.Status = STATUS_NO_MORE_ENTRIES then
    Result.Status := STATUS_SUCCESS;
end;

function NtxQueryValueKey(hKey: THandle; ValueName: String; InfoClass:
  TKeyValueInformationClass; out xMemory: IMemory; InitialBuffer: Cardinal;
  GrowthMethod: TBufferGrowthMethod): TNtxStatus;
var
  NameStr: TNtUnicodeString;
  Required: Cardinal;
begin
  Result.Location := 'NtQueryValueKey';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_QUERY_VALUE);

  NameStr := TNtUnicodeString.From(ValueName);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQueryValueKey(hKey, NameStr, InfoClass, xMemory.Data,
      xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function GrowPartial(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  Result := SizeOf(TKeyValuePartialInfromation) +
    PKeyValuePartialInfromation(Memory.Data).DataLength;

  if Result < Required then
    Result := Required;
end;

function NtxQueryPartialValueKey(hKey: THandle; ValueName: String;
  ExpectedSize: Cardinal; out xMemory: IMemory<PKeyValuePartialInfromation>):
  TNtxStatus;
begin
  Result := NtxQueryValueKey(hKey, ValueName, KeyValuePartialInformation,
    IMemory(xMemory), SizeOf(TKeyValuePartialInfromation) - SizeOf(Byte) +
    ExpectedSize, GrowPartial);
end;

function NtxQueryDwordValueKey(hKey: THandle; ValueName: String;
  out Value: Cardinal): TNtxStatus;
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
      Result.Location := 'NtxQueryDwordValueKey';
      Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    end;
end;

function NtxQueryStringValueKey(hKey: THandle; ValueName: String;
  out Value: String): TNtxStatus;
var
  xMemory: IMemory<PKeyValuePartialInfromation>;
begin
  Result := NtxQueryPartialValueKey(hKey, ValueName, SizeOf(WideChar),
    xMemory);

  if Result.IsSuccess then
    case xMemory.Data.ValueType of
      REG_SZ, REG_EXPAND_SZ, REG_LINK, REG_MULTI_SZ:
        SetString(Value, PWideChar(@xMemory.Data.Data),
          xMemory.Data.DataLength div SizeOf(WideChar) - 1);
    else
      Result.Location := 'NtxQueryStringValueKey';
      Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    end;
end;

function NtxQueryMultiStringValueKey(hKey: THandle; ValueName: String;
  out Value: TArray<String>): TNtxStatus;
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
        Value := ParseMultiSz(PWideChar(@xMemory.Data.Data),
          xMemory.Data.DataLength div SizeOf(WideChar));
    else
      Result.Location := 'NtxQueryMultiStringValueKey';
      Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    end;
end;

function NtxSetValueKey(hKey: THandle; ValueName: String;
  ValueType: TRegValueType; Data: Pointer; DataSize: Cardinal): TNtxStatus;
begin
  Result.Location := 'NtSetValueKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_SET_VALUE);

  Result.Status := NtSetValueKey(hKey, TNtUnicodeString.From(ValueName), 0,
    ValueType, Data, DataSize);
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
  xMemory: IMemory;
  pCurrentPosition: PWideChar;
  BufferSize: Cardinal;
  i: Integer;
begin
  // Calculate required memory
  BufferSize := SizeOf(WideChar); // Include additional #0 at the end
  for i := 0 to High(Value) do
    Inc(BufferSize, Succ(Length(Value[i])) * SizeOf(WideChar));

  xMemory := TAutoMemory.Allocate(BufferSize);

  pCurrentPosition := xMemory.Data;
  for i := 0 to High(Value) do
  begin
    // Copy each string
    Move(PWideChar(Value[i])^, pCurrentPosition^,
      Length(Value[i]) * SizeOf(WideChar));

    // Add zero termination
    Inc(pCurrentPosition, Length(Value[i]) + 1);
  end;

  Result := NtxSetValueKey(hKey, ValueName, REG_MULTI_SZ, xMemory.Data,
    xMemory.Size);
end;

function NtxDeleteValueKey(hKey: THandle; ValueName: String): TNtxStatus;
begin
  Result.Location := 'NtDeleteValueKey';
  Result.LastCall.Expects<TRegKeyAccessMask>(KEY_SET_VALUE);

  // Or READ_CONTROL | KEY_NOTIFY | KEY_ENUMERATE_SUB_KEYS | KEY_QUERY_VALUE
  // in case of enabled virtualization

  Result.Status := NtDeleteValueKey(hKey, TNtUnicodeString.From(ValueName));
end;

function NtxLoadKeyEx(out hxKey: IHandle; FileName: String; KeyPath: String;
  Flags: Cardinal; TrustClassKey: THandle; FileRoot: THandle): TNtxStatus;
var
  Target, Source: TObjectAttributes;
  hKey: THandle;
begin
  InitializeObjectAttributes(Source, TNtUnicodeString.From(FileName).RefOrNull,
    OBJ_CASE_INSENSITIVE, FileRoot);

  InitializeObjectAttributes(Target, TNtUnicodeString.From(KeyPath).RefOrNull,
    OBJ_CASE_INSENSITIVE);

  Result.Location := 'NtLoadKeyEx';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;

  Result.Status := NtLoadKeyEx(Target, Source, Flags, TrustClassKey, 0,
    KEY_ALL_ACCESS, hKey, nil);

  if Result.IsSuccess then
    hxKey := TAutoHandle.Capture(hKey);
end;

function NtxUnloadKey(KeyName: String; Force: Boolean): TNtxStatus;
var
  ObjAttr: TObjectAttributes;
  Flags: Cardinal;
begin
  InitializeObjectAttributes(ObjAttr, TNtUnicodeString.From(KeyName).RefOrNull);

  if Force then
    Flags := REG_FORCE_UNLOAD
  else
    Flags := 0;

  Result.Location := 'NtUnloadKey2';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;
  Result.Status := NtUnloadKey2(ObjAttr, Flags);
end;

end.
