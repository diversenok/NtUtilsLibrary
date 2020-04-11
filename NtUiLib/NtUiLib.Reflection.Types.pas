unit NtUiLib.Reflection.Types;

interface

implementation

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiUiLib.Reflection, System.SysUtils,
  DelphiUtils.Strings, NtUtils.Exceptions, NtUtils.ErrorMsg, NtUtils.Lsa.Sid,
  NtUtils.Lsa.Logon, NtUtils.WinStation, Winapi.WinUser, NtUtils.Security.Sid,
  DelphiUtils.Reflection, Ntapi.ntseapi, NtUtils.Processes.Query;

function RepresentWideChars(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  if not Assigned(PWideChar(Instance^)) then
    Result.Text := ''
  else
    Result.Text := String(PWideChar(Instance^));
end;

function RepresentAnsiChars(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  if not Assigned(PAnsiChar(Instance^)) then
    Result.Text := ''
  else
    Result.Text := String(AnsiString(PAnsiChar(Instance^)));
end;

function RepresentUnicodeString(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  if UNICODE_STRING(Instance^).Length = 0 then
    Result.Text := ''
  else
    Result.Text := UNICODE_STRING(Instance^).ToString;
end;

function RepresentClientId(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result.Text := Format('[PID: %d, TID: %d]', [
    TClientId(Instance^).UniqueProcess, TClientId(Instance^).UniqueThread]);
  // TODO: Represent TThreadId
end;

function RepresentProcessId(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
var
  ImageName: String;
  HintSection: THintSection;
begin
  if TProcessId(Instance^) = 0 then
    ImageName := 'System Idle Process'
  else if TProcessId(Instance^) = 4 then
    ImageName := 'System'
  else if NtxQueryImageNameProcessId(TProcessId(Instance^),
    ImageName).IsSuccess then
  begin
    ImageName := ExtractFileName(ImageName);

    HintSection.Title := 'NT Image Name';
    HintSection.Enabled := True;
    HintSection.Content := ImageName;
    Result.Hint := BuildHint([HintSection]);
  end
  else
    ImageName := 'Unknown';

  Result.Text := Format('%s [%d]', [ImageName, TProcessId(Instance^)]);
end;

function RepresentProcessId32(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
var
  PID: TProcessId;
begin
  PID := TProcessId32(Instance^);
  Result := RepresentProcessId(@PID, Attributes);
end;

function RepresentNtstatus(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result.Text := NtxStatusToString(NTSTATUS(Instance^));
  Result.Hint := NtxStatusDescription(NTSTATUS(Instance^));
end;

function RepresentWin32Error(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result.Text := NtxWin32ErrorToString(TWin32Error(Instance^));
  Result.Hint := NtxWin32ErrorDescription(TWin32Error(Instance^));
end;

function RepresentGuid(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result.Text := TGuid(Instance^).ToString;
end;

function RepresentLargeInteger(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  if TLargeInteger(Instance^) = 0 then
    Result.Text := 'Never'
  else if TLargeInteger(Instance^) = Int64.MaxValue then
    Result.Text := 'Infinite'
  else
    Result.Text := DateTimeToStr(LargeIntegerToDateTime(
      TLargeInteger(Instance^)));
end;

function RepresentULargeInteger(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result.Text := TimeIntervalToString(TULargeInteger(Instance^) div
    NATIVE_TIME_SECOND);
end;

function RepresentSidWorker(Sid: PSid; Attributes: TGroupAttributes;
  AttributesPresent: Boolean): TRepresentation;
var
  Sections: array of THintSection;
  Success, KnownSidType: Boolean;
  Lookup: TTranslatedName;
  State: TGroupAttributes;
begin
  SetLength(Sections, 5);

  Success := LsaxLookupSid(Sid, Lookup).IsSuccess;
  KnownSidType := Success and not
    (Lookup.SidType in [SidTypeUndefined, SidTypeInvalid, SidTypeUnknown]);

  if KnownSidType then
    Result.Text := Lookup.FullName
  else
    Result.Text := RtlxConvertSidToString(Sid);

  Sections[0].Title := 'Friendly Name';
  Sections[0].Enabled := KnownSidType;
  Sections[0].Content := Lookup.FullName;

  Sections[1].Title := 'SID';
  Sections[1].Enabled := True;
  Sections[1].Content := RtlxConvertSidToString(Sid);

  Sections[2].Title := 'Type';
  Sections[2].Enabled := Success;
  Sections[2].Content := GetNumericReflection(TypeInfo(TSidNameUse),
    @Lookup.SidType).Name;

  if AttributesPresent then
  begin
    // Separate state and flags
    State := Attributes and SE_GROUP_STATE_MASK;
    Attributes := Attributes and not SE_GROUP_STATE_MASK;

    Sections[3].Title := 'State';
    Sections[3].Enabled := True;
    Sections[3].Content := GetNumericReflection(TypeInfo(TGroupAttributes),
      @State).Name;

    Sections[4].Title := 'Flags';
    Sections[4].Enabled := Attributes <> 0;
    Sections[4].Content := GetNumericReflection(TypeInfo(TGroupAttributes),
      @Attributes).Name;
  end
  else
  begin
    Sections[3].Enabled := False;
    Sections[4].Enabled := False;
  end;

  Result.Hint := BuildHint(Sections);
end;

function RepresentSid(Instance: Pointer; Attributes:
  TArray<TCustomAttribute>): TRepresentation;
begin
  if not Assigned(PSid(Instance^)) then
  begin
    Result.Text := '(nil)';
    Exit;
  end;

  Result := RepresentSidWorker(PSid(Instance^), 0, False);
end;

function RepresentSidAndAttributes(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result := RepresentSidWorker(TSidAndAttributes(Instance^).SID,
    TSidAndAttributes(Instance^).Attributes, True);
end;

function RepresentISid(Instance: Pointer; Attributes:
  TArray<TCustomAttribute>): TRepresentation;
begin
  if not Assigned(ISid(Instance^)) then
  begin
    Result.Text := '(nil)';
    Exit;
  end;

  Result := RepresentSidWorker(ISid(Instance^).Sid, 0, False);
end;

function RepresentGroup(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  if not Assigned(TGroup(Instance^).SecurityIdentifier) then
  begin
    Result.Text := '(nil)';
    Exit;
  end;

  Result := RepresentSidWorker(TGroup(Instance^).SecurityIdentifier.Sid,
    TGroup(Instance^).Attributes, True);
end;

function RepresentLogonId(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result.Text := LsaxQueryNameLogonSession(TLogonId(Instance^));
  // TODO: Add more logon info to hint
end;

function RepresentSessionId(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result.Text := WsxQueryName(TSessionId(Instance^));
  // TODO: Add more session info to hint
end;

function RepresentRect(Instance: Pointer; Attributes:
    TArray<TCustomAttribute>): TRepresentation;
begin
  Result.Text := Format('[(%d, %d), (%d, %d)]', [TRect(Instance^).Left,
    TRect(Instance^).Top, TRect(Instance^).Right, TRect(Instance^).Bottom]);
end;

initialization
  RegisterRepresenter(TypeInfo(PWideChar), RepresentWideChars);
  RegisterRepresenter(TypeInfo(PAnsiChar), RepresentAnsiChars);
  RegisterRepresenter(TypeInfo(UNICODE_STRING), RepresentUnicodeString);
  RegisterRepresenter(TypeInfo(TClientId), RepresentClientId);
  RegisterRepresenter(TypeInfo(TProcessId), RepresentProcessId);
  RegisterRepresenter(TypeInfo(TProcessId32), RepresentProcessId32);
  RegisterRepresenter(TypeInfo(NTSTATUS), RepresentNtstatus);
  RegisterRepresenter(TypeInfo(TWin32Error), RepresentWin32Error);
  RegisterRepresenter(TypeInfo(TGuid), RepresentGuid);
  RegisterRepresenter(TypeInfo(TLargeInteger), RepresentLargeInteger);
  RegisterRepresenter(TypeInfo(TULargeInteger), RepresentULargeInteger);
  RegisterRepresenter(TypeInfo(PSid), RepresentSid);
  RegisterRepresenter(TypeInfo(TSidAndAttributes), RepresentSidAndAttributes);
  RegisterRepresenter(TypeInfo(ISid), RepresentISid);
  RegisterRepresenter(TypeInfo(TGroup), RepresentGroup);
  RegisterRepresenter(TypeInfo(TLogonId), RepresentLogonId);
  RegisterRepresenter(TypeInfo(TSessionId), RepresentSessionId);
  RegisterRepresenter(TypeInfo(TRect), RepresentRect);
finalization

end.
