unit NtUtils.ApiSets;

{
  This module provides support for parsing API Set maps (versions 2, 4, and 6).
}

interface

uses
  Ntapi.ntpebteb, NtUtils;

type
  TRtlxApiSetValueEntry = record
    Name: String;
    Value: String;
  end;

  TRtlxApiSetNamespaceEntry = record
    Flags: TApiSetSchemaEntryFlags;
    Name: String;
    Values: TArray<TRtlxApiSetValueEntry>;
  end;

// Lookup the file name implementing an API Set
function RtlxResolveApiSet(
  out HostBinary: String;
  const ApiSetName: String;
  [opt] const ParentName: String = '';
  [in, opt] Schema: PApiSetMap = nil
): TNtxStatus;

// Enumerate entries in the API Set map
function RtlxEnumerateApiSet(
  [in, opt] Schema: PApiSetMap = nil
): TArray<TRtlxApiSetNamespaceEntry>;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntrtl, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Lookup }

procedure RtlxHashApiSetName(
  const ApiSetName: String;
  const HashFactor: Cardinal;
  out Hash: Cardinal;
  out HashedLength: Cardinal
);
var
  i: Integer;
begin
  HashedLength := Low(String);

  // The hash covers the length up to but not including the last hyphen
  for i := High(ApiSetName) downto Low(ApiSetName) do
    if ApiSetName[i] = '-' then
    begin
      HashedLength := Cardinal(i - 1);
      Break;
    end;

  Hash := 0;

  for i := Low(ApiSetName) to Integer(HashedLength) do
  begin
    {$R-}{$Q-}
    Hash := Hash * HashFactor + Ord(ApiSetName[i]);
    {$IFDEF Q+}{$Q+}{$ENDIF}{$IFDEF R+}{$R+}{$ENDIF}

    case ApiSetName[i] of
      'A'..'Z': Inc(Hash, Ord('a') - Ord('A'));
    end;
  end;
end;

function RtlxResolveApiSetV6(
  out HostBinary: String;
  const ApiSetName: String;
  const ParentName: String;
  Schema: PApiSetNamespaceV6
): NTSTATUS;
var
  NamespaceEntries: ^TAnysizeArray<TApiSetNamespaceEntryV6>;
  NamespaceEntry: PApiSetNamespaceEntryV6;
  HashEntries: ^TAnysizeArray<TApiSetHashEntryV6>;
  HashEntry: PApiSetHashEntryV6;
  ValueEntries: ^TAnysizeArray<TApiSetValueEntryV6>;
  ValueEntry: PApiSetValueEntryV6;
  MinIndex, MidIndex, MaxIndex, Comparison: Integer;
  Hash, HashedLength: Cardinal;
begin
  if Schema.Count = 0 then
    Exit(STATUS_NOT_FOUND);

  NamespaceEntries := Pointer(UIntPtr(Schema) + Schema.EntryOffset);
  HashEntries := Pointer(UIntPtr(Schema) + Schema.HashOffset);
  RtlxHashApiSetName(ApiSetName, Schema.HashFactor, Hash, HashedLength);
  MinIndex := 0;
  MaxIndex := Pred(Schema.Count);

  // Perform a binary search for the API Set name hash
  repeat
    MidIndex := (MaxIndex + MinIndex) div 2;

    {$R-}
    HashEntry := @HashEntries[MidIndex];
    {$IFDEF R+}{$R+}{$ENDIF}

    if Hash < HashEntry.Hash then
      MaxIndex := Pred(MidIndex)
    else if Hash > HashEntry.Hash then
      MinIndex := Succ(MidIndex)
    else
    begin
      {$R-}
      NamespaceEntry := @NamespaceEntries[HashEntry.Index];
      {$IFDEF R+}{$R+}{$ENDIF}

      // Verify the API Set name matches, in addition to its hash
      Comparison := RtlCompareUnicodeStrings(
        PWideChar(ApiSetName),
        HashedLength,
        Pointer(UIntPtr(Schema) + NamespaceEntry.NameOffset),
        NamespaceEntry.HashedLength div SizeOf(WideChar),
        True
      );

      if Comparison < 0 then
        MaxIndex := Pred(MidIndex)
      else if Comparison > 0 then
        MinIndex := Succ(MidIndex)
      else
        Break;
    end;

    if MinIndex > MaxIndex then
      Exit(STATUS_NOT_FOUND);
  until False;

  ValueEntries := Pointer(UIntPtr(Schema) + NamespaceEntry.ValueOffset);
  ValueEntry := nil;

  // Try module-specific search
  if (ParentName <> '') and (NamespaceEntry.ValueCount > 1) then
  begin
    MinIndex := 0;
    MaxIndex := Pred(NamespaceEntry.ValueCount);

    // Perform binary search for the parent name
    repeat
      MidIndex := (MaxIndex + MinIndex) div 2;

      {$R-}
      ValueEntry := @ValueEntries[MidIndex];
      {$IFDEF R+}{$R+}{$ENDIF}

      Comparison := RtlCompareUnicodeStrings(
        PWideChar(ParentName),
        Length(ParentName),
        Pointer(UIntPtr(Schema) + ValueEntry.NameOffset),
        ValueEntry.NameLength div SizeOf(WideChar),
        True
      );

      if Comparison < 0 then
        MaxIndex := Pred(MidIndex)
      else if Comparison > 0 then
        MinIndex := Succ(MidIndex)
      else
        Break;

      // No match; fall back to the default value
      if MinIndex > MaxIndex then
      begin
        ValueEntry := nil;
        Break;
      end;

    until False;
  end;

  // Use the default value
  if not Assigned(ValueEntry) and (NamespaceEntry.ValueCount > 0) then
    ValueEntry := @ValueEntries[0];

  if Assigned(ValueEntry) then
  begin
    if ValueEntry.ValueLength = 0 then
      Result := STATUS_APISET_NOT_HOSTED
    else
    begin
      // Capture the host DLL name
      SetString(
        HostBinary,
        PWideChar(UIntPtr(Schema) + ValueEntry.ValueOffset),
        ValueEntry.ValueLength div SizeOf(WideChar)
      );
      Result := STATUS_SUCCESS;
    end;
  end
  else
    Result := STATUS_NOT_FOUND;
end;

function RtlxResolveApiSetV4(
  out HostBinary: String;
  const ApiSetName: String;
  const ParentName: String;
  Schema: PApiSetNamespaceArrayV4
): NTSTATUS;
var
  NamespaceEnty: PApiSetNamespaceEntryV4;
  ValueArray: PApiSetValueArrayV4;
  ValueEntry: PApiSetValueEntryV4;
  ApiSetNameStart: PWideChar;
  MinIndex, MidIndex, MaxIndex, Comparison, ApiSetNameLength, i: Integer;
begin
  if Schema.Count = 0 then
    Exit(STATUS_NOT_FOUND);

  // Skip the "api-" and "ext-" prefixes
  ApiSetNameStart := @ApiSetName[Low(String) + 4];
  ApiSetNameLength := Length(ApiSetName) - 4;

  // Trim file extension (when present)
  for i := High(ApiSetName) downto Low(ApiSetName) do
    if ApiSetName[i] = '.' then
    begin
      Dec(ApiSetNameLength, High(ApiSetName) - i + 1);
      Break;
    end;

  MinIndex := 0;
  MaxIndex := Pred(Schema.Count);

  // Perform a binary search for the API Set name
  repeat
    MidIndex := (MaxIndex + MinIndex) div 2;

    {$R-}
    NamespaceEnty := @Schema.EntryArray[MidIndex];
    {$IFDEF R+}{$R+}{$ENDIF}

    Comparison := RtlCompareUnicodeStrings(
      ApiSetNameStart,
      ApiSetNameLength,
      Pointer(UIntPtr(Schema) + NamespaceEnty.NameOffset),
      NamespaceEnty.NameLength div SizeOf(WideChar),
      True
    );

    if Comparison < 0 then
      MaxIndex := Pred(MidIndex)
    else if Comparison > 0 then
      MinIndex := Succ(MidIndex)
    else
      Break;

    if MinIndex > MaxIndex then
      Exit(STATUS_NOT_FOUND);
  until False;

  ValueArray := Pointer(UIntPtr(Schema) + NamespaceEnty.DataOffset);
  ValueEntry := nil;

  // Try module-specific search
  if (ParentName <> '') and (ValueArray.Count > 1) then
  begin
    MinIndex := 0;
    MaxIndex := Pred(ValueArray.Count);

    // Perform binary search for the parent name
    repeat
      MidIndex := (MaxIndex + MinIndex) div 2;

      {$R-}
      ValueEntry := @ValueArray.EntryArray[MidIndex];
      {$IFDEF R+}{$R+}{$ENDIF}

      Comparison := RtlCompareUnicodeStrings(
        PWideChar(ParentName),
        Length(ParentName),
        Pointer(UIntPtr(Schema) + ValueEntry.NameOffset),
        ValueEntry.NameLength div SizeOf(WideChar),
        True
      );

      if Comparison < 0 then
        MaxIndex := Pred(MidIndex)
      else if Comparison > 0 then
        MinIndex := Succ(MidIndex)
      else
        Break;

      // No match; fall back to the default value
      if MinIndex > MaxIndex then
      begin
        ValueEntry := nil;
        Break;
      end;

    until False;
  end;

  // Use the default value
  if not Assigned(ValueEntry) and (ValueArray.Count > 0) then
    ValueEntry := @ValueArray.EntryArray[0];

  if Assigned(ValueEntry) then
  begin
    if ValueEntry.ValueLength = 0 then
      Result := STATUS_APISET_NOT_HOSTED
    else
    begin
      // Capture the host DLL name
      SetString(
        HostBinary,
        PWideChar(UIntPtr(Schema) + ValueEntry.ValueOffset),
        ValueEntry.ValueLength div SizeOf(WideChar)
      );
      Result := STATUS_SUCCESS;
    end;
  end
  else
    Result := STATUS_NOT_FOUND;
end;

function RtlxResolveApiSetV2(
  out HostBinary: String;
  const ApiSetName: String;
  const ParentName: String;
  Schema: PApiSetNamespaceArrayV2
): NTSTATUS;
var
  NamespaceEnty: PApiSetNamespaceEntryV2;
  ValueArray: PApiSetValueArrayV2;
  ValueEntry: PApiSetValueEntryV2;
  ApiSetNameStart: PWideChar;
  MinIndex, MidIndex, MaxIndex, Comparison, ApiSetNameLength, i: Integer;
begin
  if Schema.Count = 0 then
    Exit(STATUS_NOT_FOUND);

  // Skip the "api-" and "ext-" prefixes
  ApiSetNameStart := @ApiSetName[Low(String) + 4];
  ApiSetNameLength := Length(ApiSetName) - 4;

  // Trim file extension (when present)
  for i := High(ApiSetName) downto Low(ApiSetName) do
    if ApiSetName[i] = '.' then
    begin
      Dec(ApiSetNameLength, High(ApiSetName) - i + 1);
      Break;
    end;

  MinIndex := 0;
  MaxIndex := Pred(Schema.Count);

  // Perform a binary search for the API Set name
  repeat
    MidIndex := (MaxIndex + MinIndex) div 2;

    {$R-}
    NamespaceEnty := @Schema.EntryArray[MidIndex];
    {$IFDEF R+}{$R+}{$ENDIF}

    Comparison := RtlCompareUnicodeStrings(
      ApiSetNameStart,
      ApiSetNameLength,
      Pointer(UIntPtr(Schema) + NamespaceEnty.NameOffset),
      NamespaceEnty.NameLength div SizeOf(WideChar),
      True
    );

    if Comparison < 0 then
      MaxIndex := Pred(MidIndex)
    else if Comparison > 0 then
      MinIndex := Succ(MidIndex)
    else
      Break;

    if MinIndex > MaxIndex then
      Exit(STATUS_NOT_FOUND);
  until False;

  ValueArray := Pointer(UIntPtr(Schema) + NamespaceEnty.DataOffset);
  ValueEntry := nil;

  // Try module-specific search
  if (ParentName <> '') and (ValueArray.Count > 1) then
  begin
    MinIndex := 0;
    MaxIndex := Pred(ValueArray.Count);

    // Perform binary search for the parent name
    repeat
      MidIndex := (MaxIndex + MinIndex) div 2;

      {$R-}
      ValueEntry := @ValueArray.EntryArray[MidIndex];
      {$IFDEF R+}{$R+}{$ENDIF}

      Comparison := RtlCompareUnicodeStrings(
        PWideChar(ParentName),
        Length(ParentName),
        Pointer(UIntPtr(Schema) + ValueEntry.NameOffset),
        ValueEntry.NameLength div SizeOf(WideChar),
        True
      );

      if Comparison < 0 then
        MaxIndex := Pred(MidIndex)
      else if Comparison > 0 then
        MinIndex := Succ(MidIndex)
      else
        Break;

      // No match; fall back to the default value
      if MinIndex > MaxIndex then
      begin
        ValueEntry := nil;
        Break;
      end;

    until False;
  end;

  // Use the default value
  if not Assigned(ValueEntry) and (ValueArray.Count > 0) then
    ValueEntry := @ValueArray.EntryArray[0];

  if Assigned(ValueEntry) then
  begin
    if ValueEntry.ValueLength = 0 then
      Result := STATUS_APISET_NOT_HOSTED
    else
    begin
      // Capture the host DLL name
      SetString(
        HostBinary,
        PWideChar(UIntPtr(Schema) + ValueEntry.ValueOffset),
        ValueEntry.ValueLength div SizeOf(WideChar)
      );
      Result := STATUS_SUCCESS;
    end;
  end
  else
    Result := STATUS_NOT_FOUND;
end;

function RtlxResolveApiSet;
begin
  Result.Location := 'RtlxResolveApiSet';

  // Verify the prefix
  if not RtlxPrefixString('api-', ApiSetName) and
    not RtlxPrefixString('ext-', ApiSetName) then
  begin
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Use the schema from PEB when not provided
  if not Assigned(Schema) then
    Schema := RtlGetCurrentPeb.ApiSetMap;

  // Parse according to the version
  case Schema.Version of
    API_SET_SCHEMA_VERSION_V2:
      Result.Status := RtlxResolveApiSetV2(HostBinary, ApiSetName, ParentName,
        @Schema.V2);

    API_SET_SCHEMA_VERSION_V4:
      Result.Status := RtlxResolveApiSetV4(HostBinary, ApiSetName, ParentName,
        @Schema.V4);

    API_SET_SCHEMA_VERSION_V6:
      Result.Status := RtlxResolveApiSetV6(HostBinary, ApiSetName, ParentName,
        @Schema.V6);
  else
    Result.Status := STATUS_UNKNOWN_REVISION;
  end;
end;

{ Enumeration }

function RtlxEnumerateApiSetV6(
  Schema: PApiSetNamespaceV6
): TArray<TRtlxApiSetNamespaceEntry>;
var
  i, j: Integer;
  Namespace: PApiSetNamespaceEntryV6;
  Value: PApiSetValueEntryV6;
begin
  SetLength(Result, Schema.Count);
  Namespace := Pointer(UIntPtr(Schema) + Schema.EntryOffset);

  // Collect namespace Result
  for i := 0 to High(Result) do
  begin
    Result[i].Flags := Namespace.Flags;
    SetString(Result[i].Name, PWideChar(UIntPtr(Schema) + Namespace.NameOffset),
      Namespace.NameLength div SizeOf(WideChar));

    SetLength(Result[i].Values, Namespace.ValueCount);
    Value := Pointer(UIntPtr(Schema) + Namespace.ValueOffset);

    // Value namespace Result
    for j := 0 to High(Result[i].Values) do
    begin
      SetString(Result[i].Values[j].Name, PWideChar(UIntPtr(Schema) +
        Value.NameOffset), Value.NameLength div SizeOf(WideChar));

      SetString(Result[i].Values[j].Value, PWideChar(UIntPtr(Schema) +
        Value.ValueOffset), Value.ValueLength div SizeOf(WideChar));

      Inc(Value);
    end;

    Inc(Namespace);
  end;
end;

function RtlxEnumerateApiSetV4(
  Schema: PApiSetNamespaceArrayV4
): TArray<TRtlxApiSetNamespaceEntry>;
var
  Namespace: PApiSetNamespaceEntryV4;
  ValueArray: PApiSetValueArrayV4;
  Value: PApiSetValueEntryV4;
  i, j: Integer;
begin
  SetLength(Result, Schema.Count);
  Namespace := @Schema.EntryArray[0];

  for i := 0 to High(Result) do
  begin
    Result[i].Flags := Namespace.Flags;
    SetString(Result[i].Name, PWideChar(UIntPtr(Schema) + Namespace.NameOffset),
      Namespace.NameLength div SizeOf(WideChar));

    ValueArray := Pointer(UIntPtr(Schema) + Namespace.DataOffset);
    SetLength(Result[i].Values, ValueArray.Count);
    Value := @ValueArray.EntryArray[0];

    for j := 0 to High(Result[i].Values) do
    begin
      SetString(Result[i].Values[j].Name, PWideChar(UIntPtr(Schema) +
        Value.NameOffset), Value.NameLength div SizeOf(WideChar));

      SetString(Result[i].Values[j].Value, PWideChar(UIntPtr(Schema) +
        Value.ValueOffset), Value.ValueLength div SizeOf(WideChar));

      Inc(Value);
    end;

    Inc(Namespace);
  end;
end;

function RtlxEnumerateApiSetV2(
  Schema: PApiSetNamespaceArrayV2
): TArray<TRtlxApiSetNamespaceEntry>;
var
  Namespace: PApiSetNamespaceEntryV2;
  ValueArray: PApiSetValueArrayV2;
  Value: PApiSetValueEntryV2;
  i, j: Integer;
begin
  SetLength(Result, Schema.Count);
  Namespace := @Schema.EntryArray[0];

  for i := 0 to High(Result) do
  begin
    Result[i].Flags := 0;
    SetString(Result[i].Name, PWideChar(UIntPtr(Schema) + Namespace.NameOffset),
      Namespace.NameLength div SizeOf(WideChar));

    ValueArray := Pointer(UIntPtr(Schema) + Namespace.DataOffset);
    SetLength(Result[i].Values, ValueArray.Count);
    Value := @ValueArray.EntryArray[0];

    for j := 0 to High(Result[i].Values) do
    begin
      SetString(Result[i].Values[j].Name, PWideChar(UIntPtr(Schema) +
        Value.NameOffset), Value.NameLength div SizeOf(WideChar));

      SetString(Result[i].Values[j].Value, PWideChar(UIntPtr(Schema) +
        Value.ValueOffset), Value.ValueLength div SizeOf(WideChar));

      Inc(Value);
    end;

    Inc(Namespace);
  end;
end;

function RtlxEnumerateApiSet;
begin
  if not Assigned(Schema) then
    Schema := RtlGetCurrentPeb.ApiSetMap;

  case Schema.Version of
    API_SET_SCHEMA_VERSION_V2:
      Result := RtlxEnumerateApiSetV2(@Schema.V2);

    API_SET_SCHEMA_VERSION_V4:
      Result := RtlxEnumerateApiSetV4(@Schema.V4);

    API_SET_SCHEMA_VERSION_V6:
      Result := RtlxEnumerateApiSetV6(@Schema.V6);
  else
    Result := nil;
  end;
end;

end.
