unit NtUtils.Registry.Offline;

{
  This module provides functions for working with offline registry hives.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntregapi, Ntapi.ntioapi, Ntapi.Versions,
  NtUtils, DelphiApi.Reflection;

type
  IORHandle = interface (IHandle)
    function GetHive: IORHandle;
    property Hive: IORHandle read GetHive;
  end;

  TORxSubKeyInfo = record
    KeyName: String;
    ClassName: String;
    LastWriteTime: TLargeInteger;
  end;

  TORxKeyInfo = record
    ClassName: String;
    SubKeys: Cardinal;
    MaxSubKeyLen: Cardinal;
    MaxClassLen: Cardinal;
    Values: Cardinal;
    MaxValueNameLen: Cardinal;
    [Bytes] MaxValueLen: Cardinal;
    [Bytes] SecurityDescriptorSize: Cardinal;
    LastWriteTime: TLargeInteger
  end;

  TORxValueInfo = record
    ValueName: String;
    ValueType: TRegValueType;
    [MayReturnNil] Data: IMemory;
  end;

{ Hives }

// Create an empty in-memory hive
[MinOSVersion(OsWin81)]
function ORxCreateHive(
  out hxHive: IORHandle
): TNtxStatus;

// Parse a hive from a file by name
[MinOSVersion(OsWin81)]
function ORxOpenHiveByName(
  out hxHive: IORHandle;
  [Access(FILE_READ_DATA)] const FilePath: String
): TNtxStatus;

// Parse a hive from a file by handle
[MinOSVersion(OsWin81)]
function ORxOpenHiveByHandle(
  out hxHive: IORHandle;
  [Access(FILE_READ_DATA)] const hxFile: IHandle
): TNtxStatus;

// Merges keys from multiple hives into one in-memry hive
[MinOSVersion(OsWin1020H1)]
function ORxMergeHives(
  out hxMergedHive: IORHandle;
  const Hives: TArray<IORHandle>
): TNtxStatus;

// Save changes made to the hive into a file.
// Mapping of OS version to hive format version:
//  5.0 -> 1.3
//  5.1, 5.2, 6.0, 6.1, 6.2, 6.3, 10.0 -> 1.5
[MinOSVersion(OsWin81)]
function ORxSaveHive(
  const hxHive: IORHandle;
  [Access(FILE_WRITE_DATA)] const FilePath: String;
  OsMajor: Cardinal = 6;
  OsMinor: Cardinal = 1
): TNtxStatus;

{ Keys }

// Open an key under a hive or another key
[MinOSVersion(OsWin81)]
function ORxOpenKey(
  out hxKey: IORHandle;
  const hxParent: IORHandle;
  const SubKeyName: String
): TNtxStatus;

// Create an key under a hive or another key
[MinOSVersion(OsWin81)]
function ORxCreateKey(
  out hxKey: IORHandle;
  const hxParent: IORHandle;
  const SubKeyName: String;
  Options: TRegOpenOptions = 0;
  [opt] SecurityDescriptor: PSecurityDescriptor = nil;
  [opt] const ClassName: String = '';
  [out, opt] Disposition: PRegDisposition = nil
): TNtxStatus;

// Enumerate sub-keys under the specified hive or key one-by-one
[MinOSVersion(OsWin81)]
function ORxEnumerateKey(
  const hxParent: IORHandle;
  Index: Cardinal;
  out Key: TORxSubKeyInfo;
  [opt, NumberOfElements] InitialNameLength: Cardinal = 20;
  [opt, NumberOfElements] InitialClassNameLength: Cardinal = 0
): TNtxStatus;

// Enumerate all sub-keys under the specified hive or key
[MinOSVersion(OsWin81)]
function ORxEnumerateKeys(
  const hxParent: IORHandle;
  out Keys: TArray<TORxSubKeyInfo>;
  [opt, NumberOfElements] InitialNameLength: Cardinal = 20;
  [opt, NumberOfElements] InitialClassNameLength: Cardinal = 0
): TNtxStatus;

// Make a for-in iterator for enumerating keys under the specified hive or key.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
[MinOSVersion(OsWin81)]
function ORxIterateKey(
  [out, opt] Status: PNtxStatus;
  const hxParent: IORHandle;
  [opt, NumberOfElements] InitialNameLength: Cardinal = 20;
  [opt, NumberOfElements] InitialClassNameLength: Cardinal = 0
): IEnumerable<TORxSubKeyInfo>;

// Retrieve various infomation about a hive or a key
[MinOSVersion(OsWin81)]
function ORxQueryKey(
  const hxKey: IORHandle;
  out Info: TORxKeyInfo;
  [opt, NumberOfElements] InitialClassNameLength: Cardinal = 0
): TNtxStatus;

// Retrieve virtualization control flags on a key
[MinOSVersion(OsWin81)]
function ORxQueryVirtualFlagsKey(
  const hxKey: IORHandle;
  out Flags: TKeyControlFlags
): TNtxStatus;

// Set virtualization control flags on a key
[MinOSVersion(OsWin81)]
function ORxSetVirtualFlagsKey(
  const hxKey: IORHandle;
  Flags: TKeyControlFlags
): TNtxStatus;

// Retrieve the security descriptor of a key
[MinOSVersion(OsWin81)]
function ORxQuerySecurityKey(
  const hxKey: IORHandle;
  Info: TSecurityInformation;
  out SD: ISecurityDescriptor
): TNtxStatus;

// Set the security descriptor on an key
[MinOSVersion(OsWin81)]
function ORxSetSecurityKey(
  const hxKey: IORHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

// Delete the specified key
[MinOSVersion(OsWin81)]
function ORxDeleteKey(
  const hxParent: IORHandle;
  [opt] const KeyName: String = ''
): TNtxStatus;

// Rename the specified key
[MinOSVersion(OsWin10RS2)]
function ORxRenameKey(
  const hxKey: IORHandle;
  const KeyName: String
): TNtxStatus;

{ Values }

// Enumerate values under the specified hive or key one-by-one
[MinOSVersion(OsWin81)]
function ORxEnumerateValue(
  const hxKey: IORHandle;
  Index: Cardinal;
  out Value: TORxValueInfo;
  RetrieveData: Boolean = False;
  [opt, NumberOfElements] InitialNameLength: Cardinal = 0;
  [opt, NumberOfBytes] InitialDataSize: Cardinal = 0
): TNtxStatus;

// Enumerate all values under the specified hive or key
[MinOSVersion(OsWin81)]
function ORxEnumerateValues(
  const hxKey: IORHandle;
  out Values: TArray<TORxValueInfo>;
  RetrieveData: Boolean = False;
  [opt, NumberOfElements] InitialNameLength: Cardinal = 0;
  [opt, NumberOfBytes] InitialDataSize: Cardinal = 0
): TNtxStatus;

// Make a for-in iterator for enumerating keys under the specified hive or key.
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
[MinOSVersion(OsWin81)]
function ORxIterateValue(
  [out, opt] Status: PNtxStatus;
  const hxKey: IORHandle;
  RetrieveData: Boolean = False;
  [opt, NumberOfElements] InitialNameLength: Cardinal = 0;
  [opt, NumberOfBytes] InitialDataSize: Cardinal = 0
): IEnumerable<TORxValueInfo>;

// Retrieve value information and/or data
[MinOSVersion(OsWin81)]
function ORxGetValue(
  const hxKey: IORHandle;
  [opt] const SubKeyName: String;
  [opt] const ValueName: String;
  out Info: TORxValueInfo;
  RetrieveData: Boolean = True;
  [opt, NumberOfBytes] InitialDataSize: Cardinal = 0
): TNtxStatus;

// Retrieve a 32-bit value
[MinOSVersion(OsWin81)]
function ORxGetValueUInt32(
  const hxKey: IORHandle;
  [opt] const SubKeyName: String;
  [opt] const ValueName: String;
  out Value: Cardinal
): TNtxStatus;

// Retrieve a 64-bit value
[MinOSVersion(OsWin81)]
function ORxGetValueUInt64(
  const hxKey: IORHandle;
  [opt] const SubKeyName: String;
  [opt] const ValueName: String;
  out Value: UInt64
): TNtxStatus;

// Retrieve a string value
[MinOSVersion(OsWin81)]
function ORxGetValueString(
  const hxKey: IORHandle;
  [opt] const SubKeyName: String;
  [opt] const ValueName: String;
  out Value: String;
  [out, opt] ValueType: PRegValueType = nil
): TNtxStatus;

// Retrieve a multi-string value
[MinOSVersion(OsWin81)]
function ORxGetValueMultiString(
  const hxKey: IORHandle;
  [opt] const SubKeyName: String;
  [opt] const ValueName: String;
  out Value: TArray<String>
): TNtxStatus;

// Set a value of an arbitrary type
[MinOSVersion(OsWin81)]
function ORxSetValue(
  const hxKey: IORHandle;
  [opt] const ValueName: String;
  [in] Data: Pointer;
  [NumberOfBytes] DataSize: Cardinal;
  ValueType: TRegValueType = REG_BINARY
): TNtxStatus;

// Set a value of a 32-bit integer type
[MinOSVersion(OsWin81)]
function ORxSetValueUInt32(
  const hxKey: IORHandle;
  [opt] const ValueName: String;
  Value: Cardinal;
  ValueType: TRegValueType = REG_DWORD
): TNtxStatus;

// Set a value of a 64-bit integer type
[MinOSVersion(OsWin81)]
function ORxSetValueUInt64(
  const hxKey: IORHandle;
  [opt] const ValueName: String;
  const Value: UInt64
): TNtxStatus;

// Set a value of a string type
[MinOSVersion(OsWin81)]
function ORxSetValueString(
  const hxKey: IORHandle;
  [opt] const ValueName: String;
  const Value: String;
  ValueType: TRegValueType = REG_SZ
): TNtxStatus;

// Set a value of a multi-string type
[MinOSVersion(OsWin81)]
function ORxSetValueMultiString(
  const hxKey: IORHandle;
  [opt] const ValueName: String;
  const Value: TArray<String>
): TNtxStatus;

// Delete an existing value
[MinOSVersion(OsWin81)]
function ORxDeleteValue(
  const hxKey: IORHandle;
  [opt] const ValueName: String
): TNtxStatus;

implementation

uses
  Ntapi.WinError, Ntapi.ntstatus, Ntapi.offreg, DelphiUtils.AutoObjects,
  NtUtils.Ldr, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Hives }

type
  TORAutoHiveHandle = class(TCustomAutoHandle, IORHandle, IAutoReleasable)
    function GetHive: IORHandle;
    procedure Release; override;
  end;

function TORAutoHiveHandle.GetHive;
begin
  // The parent hive for a hive handle is itself
  Result := Self;
end;

procedure TORAutoHiveHandle.Release;
begin
  if (FHandle <> 0) and LdrxCheckDelayedImport(delayed_ORCloseHive).IsSuccess then
    ORCloseHive(FHandle);

  FHandle := 0;
  inherited;
end;

function ORxCreateHive;
var
  hHive: TORHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_ORCreateHive);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORCreateHive';
  Result.Win32ErrorOrSuccess := ORCreateHive(hHive);

  if Result.IsSuccess then
    hxHive := TORAutoHiveHandle.Capture(hHive);
end;

function ORxOpenHiveByName;
var
  hHive: TORHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_OROpenHive);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OROpenHive';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_READ_DATA);
  Result.Win32ErrorOrSuccess := OROpenHive(PWideChar(FilePath), hHive);

  if Result.IsSuccess then
    hxHive := TORAutoHiveHandle.Capture(hHive);
end;

function ORxOpenHiveByHandle;
var
  hHive: TORHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_OROpenHiveByHandle);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OROpenHiveByHandle';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_READ_DATA);
  Result.Win32ErrorOrSuccess := OROpenHiveByHandle(HandleOrDefault(hxFile),
    hHive);

  if Result.IsSuccess then
    hxHive := TORAutoHiveHandle.Capture(hHive);
end;

function ORxMergeHives;
var
  HiveHandles: TArray<TORHandle>;
  pHives: PORHandleArray;
  hNewHive: TORHandle;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_ORMergeHives);

  if not Result.IsSuccess then
    Exit;

  SetLength(HiveHandles, Length(Hives));

  for i := 0 to High(Hives) do
    HiveHandles[i] := Hives[i].Handle;

  if Length(HiveHandles) > 0 then
    pHives := Pointer(@HiveHandles[0])
  else
    pHives := nil;

  Result.Location := 'ORMergeHives';
  Result.Win32ErrorOrSuccess := ORMergeHives(pHives, Length(HiveHandles),
    hNewHive);

  if Result.IsSuccess then
    hxMergedHive := TORAutoHiveHandle.Capture(hNewHive);
end;

function ORxSaveHive;
begin
  Result := LdrxCheckDelayedImport(delayed_ORSaveHive);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORSaveHive';
  Result.LastCall.Expects<TIoFileAccessMask>(FILE_WRITE_DATA);
  Result.Win32ErrorOrSuccess := ORSaveHive(HandleOrDefault(hxHive),
    PWideChar(FilePath), OsMajor, OsMinor);
end;

{ Keys }

type
  TORAutoKeyHandle = class(TCustomAutoHandle, IORHandle, IAutoReleasable)
    FHive: IORHandle;
    function GetHive: IORHandle;
    procedure Release; override;
    constructor Capture(hKey: THandle; const ParentHive: IORHandle);
  end;

constructor TORAutoKeyHandle.Capture;
begin
  // Prolong the lifetime of the parent hive
  FHive := ParentHive;
  inherited Capture(hKey);
end;

function TORAutoKeyHandle.GetHive;
begin
  Result := FHive;
end;

procedure TORAutoKeyHandle.Release;
begin
  if (FHandle <> 0) and LdrxCheckDelayedImport(delayed_ORCloseKey).IsSuccess then
    ORCloseKey(FHandle);

  FHandle := 0;
  FHive := nil;
  inherited;
end;

function ORxOpenKey;
var
  hKey: TORHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_OROpenKey);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OROpenKey';
  Result.Win32ErrorOrSuccess := OROpenKey(HandleOrDefault(hxParent),
    RefStrOrNil(SubKeyName), hKey);

  if Result.IsSuccess then
    hxKey := TORAutoKeyHandle.Capture(hKey, hxParent.Hive);
end;

function ORxCreateKey;
var
  hKey: TORHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_ORCreateKey);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORCreateKey';
  Result.Win32ErrorOrSuccess := ORCreateKey(HandleOrDefault(hxParent),
    PWideChar(SubKeyName), RefStrOrNil(ClassName), Options, SecurityDescriptor,
    hKey, Disposition);

  if Result.IsSuccess then
    hxKey := TORAutoKeyHandle.Capture(hKey, hxParent.Hive);
end;

function ORxEnumerateKey;
var
  NameBuffer, ClassNameBuffer: IMemory;
  NameRequired, ClassNameRequired: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_OREnumKey);

  if not Result.IsSuccess then
    Exit;

  // Prepare initial buffers for the name and class name
  NameBuffer := Auto.AllocateDynamic(Succ(InitialNameLength) *
    SizeOf(WideChar));
  ClassNameBuffer := Auto.AllocateDynamic(Succ(InitialClassNameLength) *
    SizeOf(WideChar));

  repeat
    // Calculate available sizes in chars
    NameRequired := NameBuffer.Size div SizeOf(WideChar);
    ClassNameRequired := ClassNameBuffer.Size div SizeOf(WideChar);

    Result.Location := 'OREnumKey';
    Result.Win32ErrorOrSuccess := OREnumKey(HandleOrDefault(hxParent), Index,
      NameBuffer.Data, NameRequired, ClassNameBuffer.Data, @ClassNameRequired,
      @Key.LastWriteTime);

    // Retry if at least one buffer requires expansion
  {$BOOLEVAL ON}
  until not NtxExpandBufferEx(Result, NameBuffer, NameRequired *
    SizeOf(WideChar), nil) and not NtxExpandBufferEx(Result, ClassNameBuffer,
    ClassNameRequired * SizeOf(WideChar), nil);
  {$BOOLEVAL OFF}

  // Make the function `while ORxEnumerateKey(...).Save(Result) do`-compatible
  if Result.Win32Error = ERROR_NO_MORE_ITEMS then
    Result.Status := STATUS_NO_MORE_ENTRIES;

  if not Result.IsSuccess then
    Exit;

  // Capture the strings and advance the cursor
  SetString(Key.KeyName, PWideChar(NameBuffer.Data), NameRequired);
  SetString(Key.ClassName, PWideChar(ClassNameBuffer.Data), ClassNameRequired);
end;

function ORxEnumerateKeys;
var
  Key: TORxSubKeyInfo;
  Index: Cardinal;
begin
  Keys := nil;
  Index := 0;

  while ORxEnumerateKey(hxParent, Index, Key, InitialNameLength,
    InitialClassNameLength).HasEntry(Result) do
  begin
    SetLength(Keys, Succ(Length(Keys)));
    Keys[High(Keys)] := Key;
    Inc(Index);
  end;
end;

function ORxIterateKey;
var
  Index: Cardinal;
begin
  Index := 0;

  Result := NtxAuto.Iterate<TORxSubKeyInfo>(Status,
    function (out Current: TORxSubKeyInfo): TNtxStatus
    begin
      // Retrieve the sub-key by index
      Result := ORxEnumerateKey(hxParent, Index, Current, InitialNameLength,
        InitialClassNameLength);

      if not Result.IsSuccess then
        Exit;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function ORxQueryKey;
var
  ClassNameBuffer: IMemory;
  ClassNameRequired: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_ORQueryInfoKey);

  if not Result.IsSuccess then
    Exit;

  ClassNameBuffer := Auto.AllocateDynamic(Succ(InitialClassNameLength) *
    SizeOf(WideChar));

  repeat
    // Class name buffer size counts in characters
    ClassNameRequired := ClassNameBuffer.Size div SizeOf(WideChar);

    Result.Location := 'ORQueryInfoKey';
    Result.Win32ErrorOrSuccess := ORQueryInfoKey(HandleOrDefault(hxKey),
      ClassNameBuffer.Data, @ClassNameRequired, @Info.SubKeys,
      @Info.MaxSubKeyLen, @Info.MaxClassLen, @Info.Values,
      @Info.MaxValueNameLen, @Info.MaxValueLen, @Info.SecurityDescriptorSize,
      @Info.LastWriteTime);

    // Expand the buffer and retry if necessary
  until not NtxExpandBufferEx(Result, ClassNameBuffer, ClassNameRequired *
    SizeOf(WideChar), nil);

  if Result.IsSuccess then
    Exit;

  SetString(Info.ClassName, PWideChar(ClassNameBuffer.Data), ClassNameRequired);
end;

function ORxQueryVirtualFlagsKey;
begin
  Result := LdrxCheckDelayedImport(delayed_ORGetVirtualFlags);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORGetVirtualFlags';
  Result.Win32ErrorOrSuccess := ORGetVirtualFlags(HandleOrDefault(hxKey),
    Flags);
end;

function ORxSetVirtualFlagsKey;
begin
  Result := LdrxCheckDelayedImport(delayed_ORSetVirtualFlags);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORSetVirtualFlags';
  Result.Win32ErrorOrSuccess := ORSetVirtualFlags(HandleOrDefault(hxKey),
    Flags);
end;

function ORxQuerySecurityKey;
const
  INITIAL_SIZE = 256;
var
  Buffer: IMemory absolute SD;
  RequiredSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_ORGetKeySecurity);

  if not Result.IsSuccess then
    Exit;

  Buffer := Auto.AllocateDynamic(INITIAL_SIZE);
  repeat
    RequiredSize := Buffer.Size;
    Result.Location := 'ORGetKeySecurity';
    Result.Win32ErrorOrSuccess := ORGetKeySecurity(HandleOrDefault(hxKey), Info,
      Buffer.Data, RequiredSize);

    // Expand the buffer and retry if necessary
  until not NtxExpandBufferEx(Result, Buffer, RequiredSize, nil);
end;

function ORxSetSecurityKey;
begin
  Result := LdrxCheckDelayedImport(delayed_ORSetKeySecurity);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORSetKeySecurity';
  Result.Win32ErrorOrSuccess := ORSetKeySecurity(HandleOrDefault(hxKey), Info,
    SD);
end;

function ORxDeleteKey;
begin
  Result := LdrxCheckDelayedImport(delayed_ORDeleteKey);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORDeleteKey';
  Result.Win32ErrorOrSuccess := ORDeleteKey(HandleOrDefault(hxParent),
    RefStrOrNil(KeyName));
end;

function ORxRenameKey;
begin
  Result := LdrxCheckDelayedImport(delayed_ORRenameKey);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORRenameKey';
  Result.Win32ErrorOrSuccess := ORRenameKey(HandleOrDefault(hxKey),
    PWideChar(KeyName));
end;

{ Values }

function ORxEnumerateValue;
var
  NameBuffer: IMemory;
  NameRequired, DataRequired: Cardinal;
  pDataRequired: PCardinal;
  RetryDueToDataExpansion: Boolean;
begin
  Result := LdrxCheckDelayedImport(delayed_OREnumValue);

  if not Result.IsSuccess then
    Exit;

  // Prepare the initial data buffer
  if RetrieveData then
    Value.Data := Auto.AllocateDynamic(InitialDataSize)
  else
    Value.Data := nil;

  // Prepare the initial name buffer
  NameBuffer := Auto.AllocateDynamic(Succ(InitialNameLength) *
    SizeOf(WideChar));

  repeat
    // The function counts characters, not bytes
    NameRequired := NameBuffer.Size div SizeOf(WideChar);

    // Data retrieval is optional and happens for non-nil buffers
    if RetrieveData then
    begin
      DataRequired := Value.Data.Size;
      pDataRequired := @DataRequired;
    end
    else
      pDataRequired := nil;

    Result.Location := 'OREnumValue';
    Result.Win32ErrorOrSuccess := OREnumValue(HandleOrDefault(hxKey), Index,
      NameBuffer.Data, NameRequired, Value.ValueType, Auto.RefOrNil(Value.Data),
      pDataRequired);

    // Check if we need more space for data
    RetryDueToDataExpansion := RetrieveData and
      NtxExpandBufferEx(Result, Value.Data, DataRequired, nil);

    // Retry if at least one buffer requires expansion
  until not NtxExpandBufferEx(Result, NameBuffer, NameRequired *
    SizeOf(WideChar), nil) and not RetryDueToDataExpansion;

  // Make the function `while ORxEnumerateValue(...).Save(Result) do`-compatible
  if Result.Win32Error = ERROR_NO_MORE_ITEMS then
    Result.Status := STATUS_NO_MORE_ENTRIES;

  if not Result.IsSuccess then
    Exit;

  // Capture the string and advance the cursor
  SetString(Value.ValueName, PWideChar(NameBuffer.Data), NameRequired);
end;

function ORxEnumerateValues;
var
  Index: Cardinal;
  Value: TORxValueInfo;
begin
  Values := nil;
  Index := 0;

  while ORxEnumerateValue(hxKey, Index, Value, RetrieveData, InitialNameLength,
    InitialDataSize).HasEntry(Result) do
  begin
    SetLength(Values, Succ(Length(Values)));
    Values[High(Values)] := Value;
    Inc(Index);
  end;
end;

function ORxIterateValue;
var
  Index: Cardinal;
begin
  Index := 0;

  Result := NtxAuto.Iterate<TORxValueInfo>(Status,
    function (out Current: TORxValueInfo): TNtxStatus
    begin
      // Retrieve the value by index
      Result := ORxEnumerateValue(hxKey, Index, Current, RetrieveData,
        InitialNameLength, InitialDataSize);

      if not Result.IsSuccess then
        Exit;

      // Advance to the next
      Inc(Index);
    end
  );
end;

function ORxGetValue;
var
  DataRequired: Cardinal;
  pDataRequired: PCardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_ORGetValue);

  if not Result.IsSuccess then
    Exit;

  // Prepare the initial data buffer
  if RetrieveData then
    Info.Data := Auto.AllocateDynamic(InitialDataSize)
  else
    Info.Data := nil;

  Info.ValueName := ValueName;

  repeat
    // Data retrieval is optional and happens for non-nil buffers
    if RetrieveData then
    begin
      DataRequired := Info.Data.Size;
      pDataRequired := @DataRequired;
    end
    else
      pDataRequired := nil;

    Result.Location := 'ORGetValue';
    Result.Win32ErrorOrSuccess := ORGetValue(HandleOrDefault(hxKey),
      RefStrOrNil(SubKeyName), RefStrOrNil(ValueName), Info.ValueType,
      Auto.RefOrNil(Info.Data), pDataRequired);

    // The function can succeed even when the buffer is too small; fix it here
    if RetrieveData and (DataRequired > Info.Data.Size) then
      Result.Win32Error := ERROR_MORE_DATA;

    // Expand the data buffer if required
  until not RetrieveData or not NtxExpandBufferEx(Result, Info.Data,
    DataRequired, nil);
end;

function ORxGetValueUInt32;
var
  ValueType: TRegValueType;
  RequiredSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_ORGetValue);

  if not Result.IsSuccess then
    Exit;

  RequiredSize := SizeOf(Value);
  Result.Location := 'ORGetValue';
  Result.Win32ErrorOrSuccess := ORGetValue(HandleOrDefault(hxKey),
    RefStrOrNil(SubKeyName), RefStrOrNil(ValueName), ValueType,
    @Value, @RequiredSize);

  if not Result.IsSuccess then
    Exit;

  if not (ValueType in [REG_DWORD, REG_DWORD_BIG_ENDIAN]) then
  begin
    Result.Location := 'ORxGetValueUInt32';
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
  end
  else if RequiredSize <> SizeOf(Value) then
  begin
    Result.Location := 'ORxGetValueUInt32';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
  end;

  if ValueType = REG_DWORD_BIG_ENDIAN then
    Value := RtlxSwapEndianness(Value);
end;

function ORxGetValueUInt64;
var
  ValueType: TRegValueType;
  RequiredSize: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_ORGetValue);

  if not Result.IsSuccess then
    Exit;

  Value := 0;
  RequiredSize := SizeOf(Value);
  Result.Location := 'ORGetValue';
  Result.Win32ErrorOrSuccess := ORGetValue(HandleOrDefault(hxKey),
    RefStrOrNil(SubKeyName), RefStrOrNil(ValueName), ValueType,
    @Value, @RequiredSize);

  if not Result.IsSuccess then
    Exit;

  if ValueType <> REG_QWORD then
  begin
    Result.Location := 'ORxGetValueUInt64';
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
  end
  else if RequiredSize <> SizeOf(Value) then
  begin
    Result.Location := 'ORxGetValueUInt64';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
  end;
end;

function ORxGetValueString;
var
  Info: TORxValueInfo;
begin
  Result := ORxGetValue(hxKey, SubKeyName, ValueName, Info, True);

  if not Result.IsSuccess then
    Exit;

  case Info.ValueType of
    // Normal strings should be zero-terminated
    REG_SZ, REG_EXPAND_SZ:
      Value := RtlxCaptureString(Info.Data.Data,
        Info.Data.Size div SizeOf(WideChar));

    // Symlinks store the target path as-is
    REG_LINK:
      SetString(Value, PWideChar(Info.Data.Data),
        Info.Data.Size div SizeOf(WideChar));

    // No value type mean no/empty string
    REG_NONE:
    begin
      Value := '';

      if Info.Data.Size <> 0 then
      begin
        // A REG_NONE with a non-zero size is not close enough to a string
        Result.Location := 'ORxGetValueString';
        Result.Status := STATUS_INVALID_BUFFER_SIZE;
        Exit;
      end;
    end
  else
    Result.Location := 'ORxGetValueString';
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    Exit;
  end;

  if Assigned(ValueType) then
    ValueType^ := Info.ValueType;
end;

function ORxGetValueMultiString;
var
  Info: TORxValueInfo;
begin
  Result := ORxGetValue(hxKey, SubKeyName, ValueName, Info, True);

  if not Result.IsSuccess then
    Exit;

  case Info.ValueType of
    REG_SZ, REG_EXPAND_SZ, REG_MULTI_SZ:
      Value := RtlxParseWideMultiSz(Info.Data.Data, Info.Data.Size div
        SizeOf(WideChar));
  else
    Result.Location := 'ORxGetValueMultiString';
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
  end;
end;

function ORxSetValue;
begin
  Result := LdrxCheckDelayedImport(delayed_ORSetValue);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORSetValue';
  Result.Win32ErrorOrSuccess := ORSetValue(HandleOrDefault(hxKey),
    RefStrOrNil(ValueName), ValueType, Data, DataSize);
end;

function ORxSetValueUInt32;
begin
  if ValueType = REG_DWORD_BIG_ENDIAN then
    Value := RtlxSwapEndianness(Value)
  else if ValueType <> REG_DWORD then
  begin
    Result.Location := 'ORxSetValueUInt32';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result := ORxSetValue(hxKey, ValueName, @Value, SizeOf(Value), ValueType);
end;

function ORxSetValueUInt64;
begin
  Result := ORxSetValue(hxKey, ValueName, @Value, SizeOf(Value), REG_QWORD);
end;

function ORxSetValueString;
var
  Size: Cardinal;
begin
  // Symbolic link strings should not be zero-terminated; others should
  if ValueType = REG_LINK then
    Size := StringSizeNoZero(Value)
  else
    Size := StringSizeZero(Value);

  Result := ORxSetValue(hxKey, ValueName, PWideChar(Value), Size, ValueType);
end;

function ORxSetValueMultiString;
var
  Buffer: IMemory<PWideMultiSz>;
begin
  // Prepare a double-zero terminated string buffer
  Buffer := RtlxBuildWideMultiSz(Value);

  Result := ORxSetValue(hxKey, ValueName, Buffer.Data, Buffer.Size,
    REG_MULTI_SZ);
end;

function ORxDeleteValue;
begin
  Result := LdrxCheckDelayedImport(delayed_ORDeleteValue);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'ORDeleteValue';
  Result.Win32ErrorOrSuccess := ORDeleteValue(HandleOrDefault(hxKey),
    RefStrOrNil(ValueName));
end;

end.
