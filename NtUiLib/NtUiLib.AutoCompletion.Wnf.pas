unit NtUiLib.AutoCompletion.Wnf;

{
  This module provides support for collecting known WNF state name descriptions.
}

interface

uses
  Ntapi.ntwnf, Ntapi.Versions;

type
  TUiLibKnownWnfName = record
    Value: TWnfStateName;
    Name: String;
    Description: String;
  end;

// Collect known WNF state name descriptions
[MinOSVersion(OsWin10RS2)]
function UiLibEnumerateKnownWnfNames: TArray<TUiLibKnownWnfName>;

// Make a human-readable name for a WNF state
function UiLibFormatWnfName(
  const StateName: TWnfStateName
): TUiLibKnownWnfName;

implementation

uses
  Ntapi.ntldr, NtUtils, NtUtils.Ldr, NtUtils.SysUtils, NtUtils.Synchronization,
  DelphiUtils.RangeChecks, DelphiUtils.Arrays, DelphiUiLib.Strings,
  DelphiUtils.LiteRTTI, DelphiUiLib.LiteReflection, DelphiApi.Reflection;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function UiLibKnownWnfNameComparer(const A, B: TUiLibKnownWnfName): Integer;
var
  Difference: Int64;
begin
  {$Q-}{$R-}
  Difference := Int64(A.Value) - Int64(B.Value);
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

  if Difference > 0 then
    Result := 1
  else if Difference < 0 then
    Result := -1
  else
    Result := 0;
end;

function UiLibEnumerateWnfNamesWorker: TArray<TUiLibKnownWnfName>;
const
  ContentDeliveryManagerUtilities = 'ContentDeliveryManager.Utilities.dll';
  FIRST_ENTRIES: array [0..3] of TWnfStateName = (
    $41C61E54A3BC0875, // WNF_9P_UNKNOWN_DISTRO_NAME // 20H1+
    $41820F2CA3BC0875, // WNF_AAD_DEVICE_REGISTRATION_STATUS_CHANGE // RS4+
    $41850D2CA3BC0835, // WNF_ACC_EC_ENABLED // RS3+
    $4191012CA3BC0875  // WNF_AOW_BOOT_PROGRESS // RS2+
  );
type
  TWnfArrayEntry = record
    Value: PWnfStateName;
    Name: PWideChar;
    Description: PWideChar;
  end;
  PWnfArrayEntry = ^TWnfArrayEntry;
var
  Status: TNtxStatus;
  Dll: IPointer;
  LdrEntry: PLdrDataTableEntry;
  DllRange: TMemory;
  FirstStateName: PWnfStateName;
  ArrayStart, ArrayCursor: PWnfArrayEntry;
  Count: Integer;
  i: Integer;
  Found: Boolean;
begin
  Result := nil;

  // Load the DLL containing a WNF name list
  Status := LdrxLoadDllAuto(ContentDeliveryManagerUtilities, Dll);

  if not Status.IsSuccess then
    Exit;

  // Locate the LDR entry to determine the DLL size
  Status := LdrxFindModuleEntryByAddress(LdrEntry, Dll.Data);

  if not Status.IsSuccess then
    Exit;

  DllRange := TMemory.From(Dll.Data, LdrEntry.SizeOfImage and not $3);
  Found := False;

  for i := Low(FIRST_ENTRIES) to High(FIRST_ENTRIES) do
  begin
    // Find the value for the first state name
    FirstStateName := DllRange.Offset(DllRange.Size - SizeOf(UInt64));

    while UIntPtr(FirstStateName) >= UIntPtr(Dll.Data) do
    begin
      if FirstStateName^ = FIRST_ENTRIES[i] then
      begin
        Found := True;
        Break;
      end;

      Dec(PCardinal(FirstStateName));
    end;

    if Found then
      Break;
  end;

  if not Found then
    Exit;

  // Find the start of the array that references it
  ArrayStart := DllRange.Offset(DllRange.Size - SizeOf(Pointer));

  while UIntPtr(ArrayStart) >= UIntPtr(Dll.Data) do
  begin
    if ArrayStart.Value = FirstStateName then
      Break;

    Dec(PNativeUInt(ArrayStart));
  end;

  if UIntPtr(ArrayStart) < UIntPtr(Dll.Data) then
    Exit;

  // Count valid entries
  Count := 0;
  ArrayCursor := ArrayStart;

  while CheckStruct(DllRange, ArrayCursor, SizeOf(TWnfArrayEntry)) and
    CheckStruct(DllRange, ArrayCursor.Value, SizeOf(TWnfStateName)) and
    CheckStruct(DllRange, ArrayCursor.Name, SizeOf(WideChar)) and
    CheckStruct(DllRange, ArrayCursor.Description, SizeOf(WideChar)) do
  begin
    Inc(Count);
    Inc(ArrayCursor);
  end;

  // Save them
  SetLength(Result, Count);
  ArrayCursor := ArrayStart;

  for i := 0 to High(Result) do
  begin
    Result[i].Value := ArrayCursor.Value^;
    Result[i].Name := RtlxCaptureStringWithRange(ArrayCursor.Name,
      DllRange.Offset(DllRange.Size));
    Result[i].Description := RtlxCaptureStringWithRange(ArrayCursor.Description,
      DllRange.Offset(DllRange.Size));
    Inc(ArrayCursor);
  end;

  // Sort them for quick search
  TArray.SortInline<TUiLibKnownWnfName>(Result, UiLibKnownWnfNameComparer);
end;

var
  KnownWnfNameCacheInitialized: TRtlRunOnce;
  KnownWnfNameCache: TArray<TUiLibKnownWnfName>;

function UiLibEnumerateKnownWnfNames;
var
  Init: IAcquiredRunOnce;
begin
  if RtlxRunOnceBegin(@KnownWnfNameCacheInitialized, Init) then
  begin
    KnownWnfNameCache := UiLibEnumerateWnfNamesWorker;
    Init.Complete;
  end;

  Result := KnownWnfNameCache;
end;

function UiLibFormatWnfName;
var
  Names: TArray<TUiLibKnownWnfName>;
  Index: Integer;
begin
  Names := UiLibEnumerateKnownWnfNames;

  Index := TArray.BinarySearchEx<TUiLibKnownWnfName>(Names,
    function (const Entry: TUiLibKnownWnfName): Integer
    var
      Difference: Int64;
    begin
      {$Q-}{$R-}
      Difference := Int64(Entry.Value) - Int64(StateName);
      {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

      if Difference > 0 then
        Result := 1
      else if Difference < 0 then
        Result := -1
      else
        Result := 0;
    end
  );

  if Index >= 0 then
    Result := Names[Index]
  else
  begin
    Result.Value := StateName;
    Result.Description := '';

    // Make a fake name from the family for well-known names
    if (WNF_EXTRACT_VERSION(StateName) = WNF_STATE_VERSION) and
      (WNF_EXTRACT_LIFETIME(StateName) = WnfWellKnownStateName) then
      Result.Name := 'WNF_' + UiLibAsciiMagicToString(WNF_EXTRACT_FAMILY(
        StateName)) + '_' + RtlxIntToDec(WNF_EXTRACT_FAMILY_UNIQUE(StateName))
    else
      Result.Name := RtlxIntToHex(StateName, 16);
  end;
end;

function UiLibWnfStateFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  StateName: TWnfStateName absolute Instance;
  Format: TUiLibKnownWnfName;
  HintSections: TArray<THintSection>;
  i: Integer;
begin
  Format := UiLibFormatWnfName(StateName);
  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    Result.Text := Format.Name;
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    i := 0;
    SetLength(HintSections, 5);

    HintSections[i] := THintSection.New('Value', UiLibUIntToHex(StateName));
    Inc(i);

    if WNF_EXTRACT_VERSION(StateName) = WNF_STATE_VERSION then
    begin
      HintSections[i] := THintSection.New('Lifetime',
        Rttix.Format(WNF_EXTRACT_LIFETIME(StateName)));
      Inc(i);

      HintSections[i] := THintSection.New('Scope',
        Rttix.Format(WNF_EXTRACT_SCOPE(StateName)));
      Inc(i);

      HintSections[i] := THintSection.New('Permanent Data',
        BooleanToString(WNF_EXTRACT_PERMANENT_DATA(StateName), bkYesNo));
      Inc(i);
    end;

    HintSections[i] := THintSection.New('Description', Format.Description);
    Inc(i);

    SetLength(HintSections, i);
    Result.Hint := BuildHint(HintSections);
    Include(Result.ValidFormats, rfHint);
  end;
end;

initialization
  RttixRegisterCustomTypeFormatter(TypeInfo(TWnfStateName), UiLibWnfStateFormatter);
end.
