unit NtUiLib.Reflection.Types;

{
  This module provides RTTI representers for many commonly used types among
  NtUtils. See DelphiUiLib.Reflection for using and selectively registering
  them with the RTTI system.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntseapi, NtUtils, DelphiUiLib.Reflection;

type
  // TNtUnicodeString
  TNtUnicodeStringRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TNtAnsiString
  TNtAnsiStringRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TClientId
  TClientIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TProcessId
  TProcessIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TProcessId32
  TProcessId32Representer = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TThreadId
  TThreadIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TThreadId32
  TThreadId32Representer = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // NTSTATUS
  TNtStatusRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // HRESULT
  THResultRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TWin32Error
  TWin32ErrorRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TNtxStatus
  TNtxStatusRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TLargeInteger
  TLargeIntegerRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TULargeInteger
  TULargeIntegerRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TUnixTime
  TUnixTimeRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // PSid
  TSidRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TSidAndAttributes
  TSidAndAttributesRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // ISid
  TISidRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TGroup
  TGroupRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TLogonId
  TLogonIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TSessionId
  TSessionIdRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

  // TRect
  TRectRepresenter = class abstract (TRepresenter)
    class function GetType: Pointer; override;
    class function Represent(
      const Instance;
      [opt] const Attributes: TArray<TCustomAttribute>
    ): TRepresentation; override;
  end;

// A worker function that represents SIDs and attributes
function RepresentSidWorker(
  [in, opt] Sid: PSid;
  Attributes: TGroupAttributes;
  AttributesPresent: Boolean;
  [opt] const hxPolicy: IHandle = nil
): TRepresentation;

implementation

uses
  System.SysUtils, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.WinUser, Ntapi.winsta,
  DelphiApi.Reflection, NtUtils.Errors, NtUiLib.Errors,NtUtils.Lsa.Sid,
  NtUtils.Lsa.Logon, NtUtils.WinStation, NtUtils.Security.Sid,
  NtUtils.Processes, NtUtils.Processes.Info, NtUtils.Threads,
  NtUtils.Synchronization, DelphiUiLib.Strings, DelphiUiLib.Reflection.Strings,
  DelphiUiLib.Reflection.Numeric;

function RepresentSidWorker;
var
  SidCopy: ISid;
  HintSections: TArray<THintSection>;
  Lookup: TTranslatedName;
  Success: Boolean;
  i: Integer;
begin
  if not Assigned(Sid) then
  begin
    Result.Text := '(nil)';
    Exit;
  end;

  if not RtlxCopySid(Sid, SidCopy).IsSuccess then
  begin
    Result.Text := '(invalid)';
    Exit;
  end;

  Success := LsaxLookupSid(SidCopy, Lookup, hxPolicy).IsSuccess;

  // Choose the best option for the main view
  if Success and Lookup.IsValid then
    Result.Text := Lookup.FullName
  else
    Result.Text := RtlxSidToString(SidCopy);

  // Build the hint with what we have
  i := 0;
  SetLength(HintSections, 5);

  if Success and Lookup.IsValid then
  begin
    HintSections[i] := THintSection.New('Friendly Name', Result.Text);
    Inc(i);
  end;

  HintSections[i] := THintSection.New('SID', RtlxSidToString(SidCopy));
  Inc(i);

  if Success then
  begin
    HintSections[i] := THintSection.New('Type', TNumeric.Represent(
      Lookup.SidType).Text);
    Inc(i);
  end;

  if AttributesPresent then
  begin
    HintSections[i] := THintSection.New('State', TNumeric.Represent
      <TGroupAttributes>(Attributes and SE_GROUP_STATE_MASK).Text);
    Inc(i);

    HintSections[i] := THintSection.New('Flags', TNumeric.Represent
      <TGroupAttributes>(Attributes and not SE_GROUP_STATE_MASK,
      [Auto.From(IgnoreSubEnumsAttribute.Create).Data]).Text);
    Inc(i);
  end;

  SetLength(HintSections, i);
  Result.Hint := BuildHint(HintSections);
end;

{ TNtUnicodeStringRepresenter }

class function TNtUnicodeStringRepresenter.GetType;
begin
  Result := TypeInfo(TNtUnicodeString);
end;

class function TNtUnicodeStringRepresenter.Represent;
var
  Value: TNtUnicodeString absolute Instance;
begin
  Result.Text := Value.ToString;
end;

{ TNtAnsiStringRepresenter }

class function TNtAnsiStringRepresenter.GetType;
begin
  Result := TypeInfo(TNtAnsiString);
end;

class function TNtAnsiStringRepresenter.Represent;
var
  Value: TNtAnsiString absolute Instance;
begin
  Result.Text := String(Value.ToString);
end;

{ TClientIdRepresenter }

class function TClientIdRepresenter.GetType;
begin
  Result := TypeInfo(TClientId);
end;

class function TClientIdRepresenter.Represent;
var
  CID: TClientId absolute Instance;
begin
  Result.Text := Format('[PID: %d, TID: %d]',
    [CID.UniqueProcess, CID.UniqueThread]);
end;

{ TProcessIdRepresenter }

class function TProcessIdRepresenter.GetType;
begin
  Result := TypeInfo(TProcessId);
end;

class function TProcessIdRepresenter.Represent;
var
  PID: TProcessId absolute Instance;
  ImageName: String;
  hxProcess: IHandle;
begin
  if PID = 0 then
    ImageName := 'System Idle Process'
  else if PID = 4 then
    ImageName := 'System'
  else if NtxQueryImageNameProcessId(PID, ImageName).IsSuccess then
  begin
    if ImageName <> '' then
    begin
      Result.Hint := BuildHint('NT Image Name', ImageName);
      ImageName := ExtractFileName(ImageName);
    end
    else
      ImageName := 'Unnamed Process';

    if NtxOpenProcess(hxProcess, PID, SYNCHRONIZE).IsSuccess and
      (NtxWaitForSingleObject(hxProcess.Handle, 0).Status = STATUS_SUCCESS) then
      ImageName := 'Terminated ' + ImageName;
  end
  else
    ImageName := 'Unknown Process';

  Result.Text := Format('%s [%d]', [ImageName, PID]);
end;

{ TProcessId32Representer }

class function TProcessId32Representer.GetType;
begin
  Result := TypeInfo(TProcessId32);
end;

class function TProcessId32Representer.Represent;
var
  PID32: TProcessId32 absolute Instance;
  PID: TProcessId;
begin
  PID := PID32;
  Result := TProcessIdRepresenter.Represent(PID, Attributes);
end;

{ TThreadIdRepresenter }

class function TThreadIdRepresenter.GetType;
begin
  Result := TypeInfo(TThreadId);
end;

class function TThreadIdRepresenter.Represent;
var
  TID: TThreadId absolute Instance;
  hxThread: IHandle;
  BasicInfo: TThreadBasicInformation;
  IsKnownName, IsTerminated: LongBool;
  ThreadName: String;
begin
  Result.Text := 'Unknown Process';
  IsTerminated := False;
  IsKnownName := False;

  if NtxOpenThread(hxThread, TID, THREAD_QUERY_LIMITED_INFORMATION).IsSuccess then
  begin
    // Represent owning process
    if NtxThread.Query(hxThread.Handle, ThreadBasicInformation,
      BasicInfo).IsSuccess then
      Result := TProcessIdRepresenter.Represent(
        BasicInfo.ClientId.UniqueProcess, Attributes);

    // Check if we can query the name
    IsKnownName := NtxQueryNameThread(hxThread.Handle, ThreadName).IsSuccess;

    if IsKnownName and (ThreadName = '') then
       ThreadName := 'unnamed thread';

    // Check for termination
    NtxThread.Query(hxThread.Handle, ThreadIsTerminated, IsTerminated);
  end;

  if not IsKnownName then
    ThreadName := 'thread';

  if IsTerminated then
    ThreadName := 'terminated ' + ThreadName;

  Result.Text := Format('%s: %s [%d]', [Result.Text, ThreadName, TID]);
end;

{ TProcessId32Representer }

class function TThreadId32Representer.GetType;
begin
  Result := TypeInfo(TThreadId32);
end;

class function TThreadId32Representer.Represent;
var
  TID32: TThreadId32 absolute Instance;
  TID: TProcessId;
begin
  TID := TID32;
  Result := TThreadIdRepresenter.Represent(TID, Attributes);
end;

{ TNtStatusRepresenter }

class function TNtStatusRepresenter.GetType;
begin
  Result := TypeInfo(NTSTATUS);
end;

class function TNtStatusRepresenter.Represent;
var
  Status: NTSTATUS absolute Instance;
begin
  Result.Text := RtlxNtStatusName(Status);
  Result.Hint := RtlxNtStatusMessage(Status);
end;

{ THResultRepresenter }

class function THResultRepresenter.GetType: Pointer;
begin
  Result := TypeInfo(HResult);
end;

class function THResultRepresenter.Represent;
var
  Value: HResult absolute Instance;
begin
  Result.Text := RtlxNtStatusName(Value.ToNtStatus);
  Result.Hint := RtlxNtStatusMessage(Value.ToNtStatus);
end;

{ TWin32ErrorRepresenter }

class function TWin32ErrorRepresenter.GetType;
begin
  Result := TypeInfo(TWin32Error);
end;

class function TWin32ErrorRepresenter.Represent;
var
  Error: TWin32Error absolute Instance;
begin
  Result.Text := RtlxNtStatusName(Error.ToNtStatus);
  Result.Hint := RtlxNtStatusMessage(Error.ToNtStatus);
end;

{ TNtxStatusRepresenter }

class function TNtxStatusRepresenter.GetType;
begin
  Result := TypeInfo(TNtxStatus);
end;

class function TNtxStatusRepresenter.Represent;
var
  Status: TNtxStatus absolute Instance;
begin
  Result.Text := Status.ToString;
  Result.Hint := Status.Description;
end;

{ TLargeIntegerRepresenter }

class function TLargeIntegerRepresenter.GetType;
begin
  Result := TypeInfo(TLargeInteger);
end;

class function TLargeIntegerRepresenter.Represent;
var
  Value: TLargeInteger absolute Instance;
begin
  if Value = 0 then
    Result.Text := 'Never'
  else if Value = Int64.MaxValue then
    Result.Text := 'Infinite'
  else
    Result.Text := DateTimeToStr(LargeIntegerToDateTime(Value));

  Result.Hint := BuildHint('Raw value', IntToStrEx(UInt64(Value)));
end;

{ TULargeIntegerRepresenter }

class function TULargeIntegerRepresenter.GetType;
begin
  Result := TypeInfo(TULargeInteger);
end;

class function TULargeIntegerRepresenter.Represent;
var
  Value: TULargeInteger absolute Instance;
begin
  Result.Text := TimeIntervalToString(Value div NATIVE_TIME_SECOND);
  Result.Hint := BuildHint('Raw value', IntToStrEx(Value));
end;

{ TUnixTimeRepresenter }

class function TUnixTimeRepresenter.GetType;
begin
  Result := TypeInfo(TUnixTime);
end;

class function TUnixTimeRepresenter.Represent;
var
  Value: TUnixTime absolute Instance;
begin
  Result.Text := DateTimeToStr(UnixTimeToDateTime(Value));
  Result.Hint := BuildHint('Raw value', IntToStrEx(Value));
end;

{ TSidRepresenter }

class function TSidRepresenter.GetType;
begin
  Result := TypeInfo(PSid);
end;

class function TSidRepresenter.Represent;
var
  Sid: PSid absolute Instance;
begin
  Result := RepresentSidWorker(Sid, 0, False);
end;

{ TSidAndAttributesRepresenter }

class function TSidAndAttributesRepresenter.GetType;
begin
  Result := TypeInfo(TSidAndAttributes);
end;

class function TSidAndAttributesRepresenter.Represent;
var
  Value: TSidAndAttributes absolute Instance;
begin
  Result := RepresentSidWorker(Value.Sid, Value.Attributes, True);
end;

{ TISidRepresenter }

class function TISidRepresenter.GetType;
begin
  Result := TypeInfo(ISid);
end;

class function TISidRepresenter.Represent;
var
  Sid: ISid absolute Instance;
begin
  Result := RepresentSidWorker(Auto.RefOrNil<PSid>(Sid), 0, False);
end;

{ TGroupRepresenter }

class function TGroupRepresenter.GetType;
begin
  Result := TypeInfo(TGroup);
end;

class function TGroupRepresenter.Represent;
var
  Group: TGroup absolute Instance;
begin
  Result := RepresentSidWorker(Auto.RefOrNil<PSid>(Group.SID),
    Group.Attributes, True);
end;

{ TLogonIdRepresenter }

class function TLogonIdRepresenter.GetType;
begin
  Result := TypeInfo(TLogonId);
end;

class function TLogonIdRepresenter.Represent;
var
  LogonId: TLogonId absolute Instance;
  UserName: String;
  LogonData: ILogonSession;
begin
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
        UserName := 'No user'
    else
      UserName := '';
  end;

  Result.Text := IntToHexEx(LogonId);

  if Assigned(LogonData) then
  begin
    Result.Text := Format('%s (%s @ %d)', [Result.Text, UserName,
      LogonData.Data.Session]);

    Result.Hint := BuildHint([
      THintSection.New('Logon ID', IntToHexEx(LogonId)),
      THintSection.New('Logon Time', TLargeIntegerRepresenter.Represent(
        LogonData.Data.LogonTime, nil).Text),
      THintSection.New('User', TSidRepresenter.Represent(
        LogonData.Data.SID, nil).Text),
      THintSection.New('Session', TSessionIdRepresenter.Represent(
        LogonData.Data.Session, nil).Text)
    ]);
  end;
end;

{ TSessionIdRepresenter }

class function TSessionIdRepresenter.GetType;
begin
  Result := TypeInfo(TSessionId);
end;

class function TSessionIdRepresenter.Represent;
var
  SessionId: TSessionId absolute Instance;
  Info: TWinStationInformation;
begin
  Result.Text := IntToStrEx(SessionId);

  if not WsxWinStation.Query(SessionId, WinStationInformation, Info).IsSuccess then
    Exit;

  if Info.WinStationName <> '' then
    Result.Text := Format('%s: %s', [Result.Text, Info.WinStationName]);

  Result.Text := Format('%s (%s)', [Result.Text, Info.FullUserName]);

  Result.Hint := BuildHint([
    THintSection.New('ID', IntToStrEx(Info.LogonID)),
    THintSection.New('Name', Info.WinStationName),
    THintSection.New('User', Info.FullUserName)
  ]);
end;

{ TRectRepresenter }

class function TRectRepresenter.GetType;
begin
  Result := TypeInfo(TRect);
end;

class function TRectRepresenter.Represent;
var
  Rect: TRect absolute Instance;
begin
  Result.Text := Format('[(%d, %d), (%d, %d)]', [Rect.Left, Rect.Top,
    Rect.Right, Rect.Bottom]);
end;

initialization
  // Make all representers available at runtime for RTTI
  CompileTimeInclude(TNtUnicodeStringRepresenter);
  CompileTimeInclude(TNtAnsiStringRepresenter);
  CompileTimeInclude(TClientIdRepresenter);
  CompileTimeInclude(TProcessIdRepresenter);
  CompileTimeInclude(TProcessId32Representer);
  CompileTimeInclude(TThreadIdRepresenter);
  CompileTimeInclude(TThreadId32Representer);
  CompileTimeInclude(TNtStatusRepresenter);
  CompileTimeInclude(THResultRepresenter);
  CompileTimeInclude(TWin32ErrorRepresenter);
  CompileTimeInclude(TNtxStatusRepresenter);
  CompileTimeInclude(TLargeIntegerRepresenter);
  CompileTimeInclude(TULargeIntegerRepresenter);
  CompileTimeInclude(TUnixTimeRepresenter);
  CompileTimeInclude(TSidRepresenter);
  CompileTimeInclude(TSidAndAttributesRepresenter);
  CompileTimeInclude(TISidRepresenter);
  CompileTimeInclude(TGroupRepresenter);
  CompileTimeInclude(TLogonIdRepresenter);
  CompileTimeInclude(TSessionIdRepresenter);
  CompileTimeInclude(TRectRepresenter);
finalization

end.

