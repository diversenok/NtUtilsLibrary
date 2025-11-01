unit DelphiUiLib.LiteReflection.Types;

{
  This module integrates custom formatting for known types into the lightweight
  reflection system.
}

interface

// Enables reflection for TGuid, TNtUnicodeString, TNtAnsiString, NTSTATUS,
// HResult, TWin32Error, TNtxStatus, TRect
procedure RttixRegisterBasicFormatters;

// Enables reflection for TDateTime, TLargeInteger, TUnixTime, TULargeInteger
procedure RttixRegisterTimeFormatters;

// Enables reflection for TProcessId, TProcessId32, TThreadId, TThreadId32,
// TClientId
procedure RttixRegisterClientIdFormatters;

// Enables reflection for PSid, TSidAndAttributes, ISid, TGroup
procedure RttixRegisterSidFormatters;

// Enables reflection for TSessionId
procedure RttixRegisterSessionIdFormatter;

// Enables reflection for TLogonId
procedure RttixRegisterLogonIdFormatter;

// Enables reflection for all known types
procedure RttixRegisterAllFormatter;

implementation

uses
  Ntapi.ntdef, Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.winsta,
  Ntapi.ntrtl, Ntapi.ntseapi, Ntapi.WinUser, Ntapi.ObjBase, NtUtils,
  NtUtils.SysUtils, NtUtils.Errors, NtUiLib.Errors, NtUtils.Synchronization,
  NtUtils.Processes, NtUtils.Processes.Info, NtUtils.Threads, NtUtils.WinStation,
  NtUtils.Lsa.Logon, NtUtils.Security.Sid, NtUtils.Lsa.Sid, DelphiUiLib.Strings,
  DelphiUtils.LiteRTTI, DelphiUiLib.LiteReflection;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

// TDateTime
function RttixDateTimeFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  DateTime: TDateTime absolute Instance;
begin
  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    Result.Text := UiLibDateTimeToString(DateTime);
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    Result.Hint := BuildHint('Relative To Now',
      UiLibSystemTimeDurationFromNow(RtlxDateTimeToLargeInteger(DateTime)));
    Include(Result.ValidFormats, rfHint);
  end;
end;

// TLargeInteger
function RttixLargeIntegerFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Value: TLargeInteger absolute Instance;
  HintSections: TArray<THintSection>;
begin
  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    Result.Text := UiLibNativeTimeToString(Value);
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    HintSections := [
      THintSection.New('Raw Value (Dec)', UiLibUIntToDec(Value)),
      THintSection.New('Raw Value (Hex)', UiLibUIntToHex(Value)),
      THintSection.New('Relative To Now', '')
    ];

    if (Value <> 0) and (Value <> MAX_INT64) then
      HintSections[2].Content := UiLibSystemTimeDurationFromNow(Value);

    Result.Hint := BuildHint(HintSections);
    Include(Result.ValidFormats, rfHint);
  end;
end;

// TUnixTime
function RttixUnixTimeFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Value: TUnixTime absolute Instance;
  NativeTime: TLargeInteger;
begin
  Result.ValidFormats := [];
  RtlSecondsSince1970ToTime(Value, NativeTime);

  if rfText in RequestedFormats then
  begin
    Result.Text := UiLibNativeTimeToString(NativeTime);
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    Result.Hint := BuildHint([
      THintSection.New('Raw Value (Dec)', UiLibUIntToDec(Value)),
      THintSection.New('Raw Value (Hex)', UiLibUIntToHex(Value)),
      THintSection.New('Relative To Now', UiLibSystemTimeDurationFromNow(
        NativeTime))
    ]);
    Include(Result.ValidFormats, rfHint);
  end;
end;

// TULargeInteger
function RttixULargeIntegerFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Value: TULargeInteger absolute Instance;
begin
  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    Result.Text := UiLibDurationToString(Value);
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    Result.Hint := BuildHint([
      THintSection.New('Raw Value (Dec)', UiLibUIntToDec(Value)),
      THintSection.New('Raw Value (Hex)', UiLibUIntToHex(Value))
    ]);
    Include(Result.ValidFormats, rfHint);
  end;
end;

// TGuid
function RttixGuidFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
begin
  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    Result.Text := RtlxGuidToString(TGuid(Instance));
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    Result.Hint := '';
    Include(Result.ValidFormats, rfHint);
  end;
end;

// Variant, TVarData
function RttixVariantFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
type
  PIntPtr = ^IntPtr;
  PUIntPtr = ^UIntPtr;
  PHResult = ^HResult;
var
  VarInstance: TVarData absolute Instance;
  VarEnumTypeInfo: IRttixEnumType;
  ValueType: TVarEnum;
  KindName: String;
  ByRef, KnownName: Boolean;
  ReflectionType: PLiteRttiTypeInfo;
begin
  if (RttixType.TypeInfo <> TypeInfo(Variant)) and
    (RttixType.TypeInfo <> TypeInfo(TVarData)) then
  begin
    Error(reAssertionFailed);
    Exit;
  end;

  // Prepare type info for variant kinds enumerations
  VarEnumTypeInfo := (RttixTypeInfo(TypeInfo(TVarEnum),
    RttixPreserveEnumCase) as IRttixEnumType);

  // Determine the packed value type
  ValueType := TVarEnum(VarInstance.VType and
    not (Word(VT_ARRAY) or Word(VT_BYREF)));

  ByRef := BitTest(VarInstance.VType and Word(VT_BYREF));
  KnownName := True;

  // Prepare the name for the value type
  if Word(ValueType) in VarEnumTypeInfo.ValidValues then
  begin
    KindName := VarEnumTypeInfo.TypeInfo.EnumerationName(Integer(ValueType));
  end
  else if ValueType = VT_PASCAL_STRING then
    KindName := 'VT_PASCAL_STRING'
  else if ValueType = VT_PASCAL_UNICODE_STRING then
    KindName := 'VT_PASCAL_UNICODE_STRING'
  else
  begin
    KnownName := False;
    KindName := RtlxFormatString('unrecogized variant type (%u)',
      [Cardinal(VarInstance.VType)]);
  end;

  if KnownName and ByRef then
    KindName := KindName + ' | VT_BYREF';

  if BitTest(VarInstance.VType and Word(VT_ARRAY)) then
  begin
    Result.ValidFormats := [rfText, rfHint];
    Result.Text := RtlxFormatString('(VT_ARRAY of %s values)', [KindName]);
    Result.Hint := '';
    Exit;
  end;

  case ValueType of
    VT_I2:
      if ByRef then
        ReflectionType := TypeInfo(PSmallInt)
      else
        ReflectionType := TypeInfo(SmallInt);

    VT_I4:
      if ByRef then
        ReflectionType := TypeInfo(PInteger)
      else
        ReflectionType := TypeInfo(Integer);

    VT_R4:
      if ByRef then
        ReflectionType := TypeInfo(PSingle)
      else
        ReflectionType := TypeInfo(Single);

    VT_R8:
      if ByRef then
        ReflectionType := TypeInfo(PDouble)
      else
        ReflectionType := TypeInfo(Double);

    VT_BSTR:
      if ByRef then
        ReflectionType := TypeInfo(PWideString)
      else
        ReflectionType := TypeInfo(WideString);

    VT_BOOL:
      if ByRef then
        ReflectionType := TypeInfo(PLongBool)
      else
        ReflectionType := TypeInfo(LongBool);

    VT_VARIANT:
      if ByRef then
        ReflectionType := TypeInfo(PVarData)
      else
        ReflectionType := TypeInfo(TVarData);

    VT_I1:
      if ByRef then
        ReflectionType := TypeInfo(PShortInt)
      else
        ReflectionType := TypeInfo(ShortInt);

    VT_UI1:
      if ByRef then
        ReflectionType := TypeInfo(PByte)
      else
        ReflectionType := TypeInfo(Byte);

    VT_UI2:
      if ByRef then
        ReflectionType := TypeInfo(PWord)
      else
        ReflectionType := TypeInfo(Word);

    VT_UI4:
      if ByRef then
        ReflectionType := TypeInfo(PCardinal)
      else
        ReflectionType := TypeInfo(Cardinal);

    VT_I8:
      if ByRef then
        ReflectionType := TypeInfo(PInt64)
      else
        ReflectionType := TypeInfo(Int64);

    VT_UI8:
      if ByRef then
        ReflectionType := TypeInfo(PUInt64)
      else
        ReflectionType := TypeInfo(UInt64);

    VT_INT:
      if ByRef then
        ReflectionType := TypeInfo(PIntPtr)
      else
        ReflectionType := TypeInfo(IntPtr);

    VT_UINT:
      if ByRef then
        ReflectionType := TypeInfo(PUIntPtr)
      else
        ReflectionType := TypeInfo(UIntPtr);

    VT_HRESULT:
      if ByRef then
        ReflectionType := TypeInfo(PHResult)
      else
        ReflectionType := TypeInfo(HResult);

    {$WARN CASE_LABEL_RANGE OFF}
    VT_PASCAL_STRING:
      if ByRef then
        ReflectionType := TypeInfo(PShortString)
      else
        ReflectionType := TypeInfo(ShortString);

    VT_PASCAL_UNICODE_STRING:
      if ByRef then
        ReflectionType := TypeInfo(PUnicodeString)
      else
        ReflectionType := TypeInfo(UnicodeString);
    {$WARN CASE_LABEL_RANGE ON}
  else
    Result.ValidFormats := [rfText, rfHint];
    Result.Text := RtlxFormatString('(%s value)', [KindName]);
    Result.Hint := '';
    Exit;
  end;

  // Format the underlying type
  Result := RttixFormatFull(ReflectionType, VarInstance.VPointer);

  if rfHint in RequestedFormats then
    Result.Hint := RtlxJoinStrings([Result.Hint, BuildHint('Variant Type',
      KindName)], #$D#$A);
end;

// TNtUnicodeString, TNtAnsiString
function RttixNtStringFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Unicode: Boolean;
  UnicodeInstance: TNtUnicodeString absolute Instance;
  AnsiInstance: TNtAnsiString absolute Instance;
begin
  if RttixType.TypeInfo = TypeInfo(TNtUnicodeString) then
    Unicode := True
  else if RttixType.TypeInfo = TypeInfo(TNtAnsiString) then
    Unicode := False
  else
  begin
    Error(reAssertionFailed);
    Exit;
  end;

  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    if Unicode then
      Result.Text := UnicodeInstance.ToString
    else
      Result.Text := String(AnsiInstance.ToString);

    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    // Length and maximum length fields are the same between ansi/unicode
    Result.Hint := BuildHint([
      THintSection.New('Length', UiLibBytesToString(AnsiInstance.Length)),
      THintSection.New('Maximum Length', UiLibBytesToString(
        AnsiInstance.MaximumLength))
    ]);

    Include(Result.ValidFormats, rfHint);
  end;
end;

// TProcessId, TProcessId32, TThreadId, TThreadId32, TClientId
function RttixClientIdFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  CID: TClientId;
  IsProcessIdKnown, IsThreadIdKnown: Boolean;
  IsTerminated: LongBool;
  hxProcess, hxThread: IHandle;
  ThreadInfo: TThreadBasicInformation;
  ImagePath, ProcessName, ThreadName: String;
begin
  // Read the PID and TID
  if RttixType.TypeInfo = TypeInfo(TProcessId) then
  begin
    CID.UniqueProcess := TProcessId(Instance);
    IsProcessIdKnown := True;
    IsThreadIdKnown := False;
  end
  else if RttixType.TypeInfo = TypeInfo(TProcessId32) then
  begin
    CID.UniqueProcess := TProcessId32(Instance);
    IsProcessIdKnown := True;
    IsThreadIdKnown := False;
  end
  else if RttixType.TypeInfo = TypeInfo(TThreadId) then
  begin
    CID.UniqueThread := TThreadId(Instance);
    IsProcessIdKnown := False;
    IsThreadIdKnown := True;
  end
  else if RttixType.TypeInfo = TypeInfo(TThreadId32) then
  begin
    CID.UniqueThread := TThreadId32(Instance);
    IsProcessIdKnown := False;
    IsThreadIdKnown := True;
  end
  else if RttixType.TypeInfo = TypeInfo(TClientId) then
  begin
    CID := TClientId(Instance);
    IsProcessIdKnown := True;
    IsThreadIdKnown := True;
  end
  else
  begin
    Error(reAssertionFailed);
    Exit;
  end;

  // Collect thread information
  if IsThreadIdKnown then
  begin
    if NtxOpenThread(hxThread, CID.UniqueThread,
      THREAD_QUERY_LIMITED_INFORMATION).IsSuccess then
    begin
      // Recover the PID if necessary
      if not IsProcessIdKnown and NtxThread.Query(hxThread,
        ThreadBasicInformation, ThreadInfo).IsSuccess then
      begin
        IsProcessIdKnown := True;
        CID.UniqueProcess := ThreadInfo.ClientId.UniqueProcess;
      end;

      // Determine thread name
      if not NtxQueryNameThread(hxThread, ThreadName).IsSuccess or
        (ThreadName = '') then
        ThreadName := 'Unnamed Thread';

      // Check for termination
      if NtxThread.Query(hxThread, ThreadIsTerminated, IsTerminated).IsSuccess
        and IsTerminated then
        ThreadName := 'Terminated ' + ThreadName;
    end
    else
      ThreadName := 'Unknown Thread';

    ThreadName := ThreadName + ' [' + UiLibUIntToDec(CID.UniqueThread) + ']';
  end;

  // Collect process information
  if IsProcessIdKnown then
  begin
    ImagePath := '';

    if CID.UniqueProcess = SYSTEM_IDLE_PID then
      ProcessName := 'System Idle Process'
    else if CID.UniqueProcess = SYSTEM_PID then
      ProcessName := 'System'
    else if NtxQueryImageNameProcessId(CID.UniqueProcess,
      ImagePath).IsSuccess then
    begin
      if ImagePath <> '' then
        ProcessName := RtlxExtractNamePath(ImagePath)
      else
        ProcessName := 'Unnamed Process';

      if NtxOpenProcess(hxProcess, CID.UniqueProcess, SYNCHRONIZE).IsSuccess and
        (NtxWaitForSingleObject(hxProcess, 0).Status = STATUS_WAIT_0) then
        ProcessName := 'Terminated ' + ProcessName;
    end
    else
      ProcessName := 'Unknown Process';

    ProcessName := ProcessName + ' [' + UiLibUIntToDec(CID.UniqueProcess) + ']';
  end;

  Result.ValidFormats := [];

  // Format as text
  if rfText in RequestedFormats then
  begin
    if IsProcessIdKnown and IsThreadIdKnown then
      Result.Text := ProcessName + ': ' + ThreadName
    else if IsProcessIdKnown then
      Result.Text := ProcessName
    else if IsThreadIdKnown then
      Result.Text := ThreadName
    else
      Error(reAssertionFailed);

    Include(Result.ValidFormats, rfText);
  end;

  // Format as hint
  if rfHint in RequestedFormats then
  begin
    if IsProcessIdKnown then
      Result.Hint := BuildHint('Process Image', ImagePath)
    else
      Result.Hint := '';

    Include(Result.ValidFormats, rfHint);
  end;
end;

// NTSTATUS, HResult, TWin32Error
function RttixStatusFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Status: NTSTATUS;
begin
  if RttixType.TypeInfo = TypeInfo(NTSTATUS) then
    Status := NTSTATUS(Instance)
  else if RttixType.TypeInfo = TypeInfo(HResult) then
    Status := HResult(Instance).ToNtStatus
  else if RttixType.TypeInfo = TypeInfo(TWin32Error) then
    Status := TWin32Error(Instance).ToNtStatus
  else
  begin
    Error(reAssertionFailed);
    Exit;
  end;

  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    Result.Text := RtlxNtStatusName(Status);
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    Result.Hint := BuildHint([
      THintSection.New('Raw Value (Hex): ', UiLibUIntToHex(Status)),
      THintSection.New('Raw Value (Dec): ', UiLibUIntToDec(Status)),
      THintSection.New('Description: ', RtlxNtStatusMessage(Status))
    ]);
    Include(Result.ValidFormats, rfHint);
  end;
end;

// TNtxStatus
function RttixNtxStatusFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Status: TNtxStatus absolute Instance;
begin
  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    Result.Text := Status.ToString;
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    Result.Hint := BuildHint([
      THintSection.New('Value: ', UiLibUIntToHex(Status.Status)),
      THintSection.New('Description: ', RtlxNtStatusMessage(Status.Status))
    ]);
    Include(Result.ValidFormats, rfHint);
  end;
end;

// TSessionId
function RttixSessionIdFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  SessionId: TSessionId absolute Instance;
  Info: TWinStationInformation;
  InfoValid: Boolean;
begin
  Result.ValidFormats := [];

  InfoValid := WsxWinStation.Query(SessionId, WinStationInformation,
    Info).IsSuccess;

  if rfText in RequestedFormats then
  begin
    Result.Text := UiLibUIntToDec(SessionId);

    if InfoValid and (Info.WinStationName <> '') then
      Result.Text := Result.Text + ': ' + Info.WinStationName;

    if InfoValid then
      Result.Text := Result.Text + ' (' + RtlxStringOrDefault(Info.FullUserName,
        'No User') + ')';

    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    if InfoValid then
      Result.Hint := BuildHint([
        THintSection.New('Session ID', UiLibUIntToDec(SessionId)),
        THintSection.New('Name', Info.WinStationName),
        THintSection.New('User', Info.FullUserName),
        THintSection.New('Logon Time', UiLibNativeTimeToString(Info.LogonTime))
      ])
    else
      Result.Hint := '';

    Include(Result.ValidFormats, rfHint);
  end;
end;

// TLogonId
function RttixLogonIdFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  LogonId: TLogonId absolute Instance;
  UserName: String;
  LogonData: ILogonSession;
begin
  Result.ValidFormats := [];
  LsaxQueryLogonSession(LogonId, LogonData);

  case LogonId of
    SYSTEM_LUID:          UserName := 'SYSTEM';
    ANONYMOUS_LOGON_LUID: UserName := 'ANONYMOUS LOGON';
    LOCALSERVICE_LUID:    UserName := 'LOCAL SERVICE';
    NETWORKSERVICE_LUID:  UserName := 'NETWORK SERVICE';
    IUSER_LUID:           UserName := 'IUSR';
  else
    if Assigned(LogonData) then
      if LogonData.Data.UserName.Length > 0 then
        UserName := LogonData.Data.UserName.ToString
      else
        UserName := 'No User'
    else
      UserName := '';
  end;

  if rfText in RequestedFormats then
  begin
    Result.Text := UiLibUIntToHex(LogonId);

    if Assigned(LogonData) then
      Result.Text := Result.Text + ' (' + UserName + ' @ ' +
        UiLibUIntToDec(LogonData.Data.Session) + ')'
    else if UserName <> '' then
      Result.Text := Result.Text + ' (' + UserName + ')';

    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    Result.Hint := BuildHint([
      THintSection.New('Logon Time', UiLibNativeTimeToString(
        LogonData.Data.LogonTime)),
      THintSection.New('User', RttixFormat(TypeInfo(PSid), LogonData.Data.SID)),
      THintSection.New('Session', RttixFormat(TypeInfo(TSessionId),
        LogonData.Data.Session))
    ]);
    Include(Result.ValidFormats, rfHint);
  end;
end;

// TRect
function RttixRectFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Rect: TRect absolute Instance;
begin
  Result.ValidFormats := [];

  if rfText in RequestedFormats then
  begin
    Result.Text := RtlxFormatString('(%d, %d) - (%d, %d) [%dx%d]',
      [Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, Rect.Right - Rect.Left,
      Rect.Bottom - Rect.Top]);
    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    Result.Hint := '';
    Include(Result.ValidFormats, rfHint);
  end;
end;

// PSid, ISid
function RttixSidFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Sid: ISid;
  SidValid: Boolean;
  Lookup: TTranslatedName;
begin
  SidValid := True;

  // Collect SID and attributes
  if RttixType.TypeInfo = TypeInfo(PSid) then
    if Assigned(PSid(Instance)) then
      SidValid := RtlxCopySid(PSid(Instance), Sid).IsSuccess
    else
      Sid := nil
  else if RttixType.TypeInfo = TypeInfo(ISid) then
    Sid := ISid(Instance)
  else
  begin
    Error(reAssertionFailed);
    Exit;
  end;

  Result.ValidFormats := [];

  if SidValid then
    LsaxLookupSid(Sid, Lookup);

  if rfText in RequestedFormats then
  begin
    if SidValid and Lookup.IsValid then
      Result.Text := Lookup.FullName
    else if SidValid then
      Result.Text := RtlxSidToStringNoError(Sid)
    else
      Result.Text := '(invalid)';

    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    if SidValid and Lookup.IsValid then
      Result.Hint := BuildHint([
        THintSection.New('SID', RtlxSidToStringNoError(Sid)),
        THintSection.New('SID Type', RttixFormat(TypeInfo(TSidNameUse),
          Lookup.SidType))
      ])
    else
      Result.Hint := '';

    Include(Result.ValidFormats, rfHint);
  end;
end;

// TSidAndAttributes, TGroup
function RttixGroupFormatter(
  const RttixType: IRttixType;
  const [ref] Instance;
  RequestedFormats: TRttixReflectionFormats
): TRttixFullReflection;
var
  Attributes: TGroupAttributes;
  State: TGroupAttributesFullState;
begin
  if RttixType.TypeInfo = TypeInfo(TSidAndAttributes) then
  begin
    // Start with PSid formatting
    Result := RttixSidFormatter(RttixTypeInfo(TypeInfo(PSid)),
      TSidAndAttributes(Instance).Sid, RequestedFormats);
    Attributes := TSidAndAttributes(Instance).Attributes;
  end
  else if RttixType.TypeInfo = TypeInfo(TGroup) then
  begin
    // Start with ISid formatting
    Result := RttixSidFormatter(RttixTypeInfo(TypeInfo(ISid)),
      TGroup(Instance).Sid, RequestedFormats);
    Attributes := TGroup(Instance).Attributes;
  end
  else
  begin
    Error(reAssertionFailed);
    Exit;
  end;

  if rfHint in RequestedFormats then
  begin
    // Split state and flags
    State := Attributes and SE_GROUP_STATE_MASK;
    Attributes := Attributes and not SE_GROUP_STATE_MASK;

    // Add attributes to the
    Result.Hint := RtlxJoinStrings([
      Result.Hint,
      BuildHint([
        THintSection.New('State', RttixFormat(
          TypeInfo(TGroupAttributesFullState), State)),
        THintSection.New('Flags', RttixFormat(
          TypeInfo(TGroupAttributes), Attributes))
      ])
    ], #$D#$A);
  end;
end;

{ Registration }

procedure RttixRegisterBasicFormatters;
begin
  RttixRegisterCustomTypeFormatter(TypeInfo(TGuid), RttixGuidFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(Variant), RttixVariantFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TVarData), RttixVariantFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TNtUnicodeString), RttixNtStringFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TNtAnsiString), RttixNtStringFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(NTSTATUS), RttixStatusFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(HResult), RttixStatusFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TWin32Error), RttixStatusFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TNtxStatus), RttixNtxStatusFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TRect), RttixRectFormatter);
end;

procedure RttixRegisterTimeFormatters;
begin
  RttixRegisterCustomTypeFormatter(TypeInfo(TDateTime), RttixDateTimeFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TLargeInteger), RttixLargeIntegerFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TUnixTime), RttixUnixTimeFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TULargeInteger), RttixULargeIntegerFormatter);
end;

procedure RttixRegisterClientIdFormatters;
begin
  RttixRegisterCustomTypeFormatter(TypeInfo(TProcessId), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TProcessId32), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TThreadId), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TThreadId32), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TClientId), RttixClientIdFormatter);
end;

procedure RttixRegisterSidFormatters;
begin
  RttixRegisterCustomTypeFormatter(TypeInfo(PSid), RttixSidFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(ISid), RttixSidFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TSidAndAttributes), RttixGroupFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TGroup), RttixGroupFormatter);
end;

procedure RttixRegisterSessionIdFormatter;
begin
  RttixRegisterCustomTypeFormatter(TypeInfo(TSessionId), RttixSessionIdFormatter);
end;

procedure RttixRegisterLogonIdFormatter;
begin
  RttixRegisterCustomTypeFormatter(TypeInfo(TLogonId), RttixLogonIdFormatter);
end;

procedure RttixRegisterAllFormatter;
begin
  RttixRegisterBasicFormatters;
  RttixRegisterTimeFormatters;
  RttixRegisterClientIdFormatters;
  RttixRegisterSidFormatters;
  RttixRegisterSessionIdFormatter;
  RttixRegisterLogonIdFormatter;
end;

end.
