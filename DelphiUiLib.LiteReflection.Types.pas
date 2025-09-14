unit DelphiUiLib.LiteReflection.Types;

{
  This module integrates custom formatting for known types into the lightweight
  reflection system.
}

interface

// Including the unit automatically registers custom type formatters

implementation

uses
  Ntapi.ntdef, Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.winsta,
  Ntapi.ntrtl, Ntapi.ntseapi, Ntapi.WinUser, NtUtils, NtUtils.SysUtils,
  NtUtils.Errors, NtUiLib.Errors, NtUtils.Synchronization, NtUtils.Processes,
  NtUtils.Processes.Info, NtUtils.Threads, NtUtils.WinStation,
  NtUtils.Lsa.Logon, NtUtils.Security.Sid, NtUtils.Lsa.Sid, DelphiUiLib.Strings,
  DelphiUtils.LiteRTTI, DelphiUtils.LiteRTTI.Extension,
  DelphiUiLib.LiteReflection;

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
      Result.Text := RtlxSidToString(Sid)
    else
      Result.Text := '(invalid)';

    Include(Result.ValidFormats, rfText);
  end;

  if rfHint in RequestedFormats then
  begin
    if SidValid and Lookup.IsValid then
      Result.Hint := BuildHint([
        THintSection.New('SID', RtlxSidToString(Sid)),
        THintSection.New('SID Type', RttixFormat(TypeInfo(TSidNameUse),
          Lookup.SidType))
      ])
    else
      Result.Hint := '';

    Include(Result.ValidFormats, rfHint);
  end;
end;

initialization
  RttixRegisterCustomTypeFormatter(TypeInfo(TDateTime), RttixDateTimeFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TLargeInteger), RttixLargeIntegerFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TUnixTime), RttixUnixTimeFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TULargeInteger), RttixULargeIntegerFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TGuid), RttixGuidFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TNtUnicodeString), RttixNtStringFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TNtAnsiString), RttixNtStringFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TProcessId), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TProcessId32), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TThreadId), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TThreadId32), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TClientId), RttixClientIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(NTSTATUS), RttixStatusFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(HResult), RttixStatusFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TWin32Error), RttixStatusFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TNtxStatus), RttixNtxStatusFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TSessionId), RttixSessionIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TLogonId), RttixLogonIdFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(TRect), RttixRectFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(PSid), RttixSidFormatter);
  RttixRegisterCustomTypeFormatter(TypeInfo(ISid), RttixSidFormatter);
end.
