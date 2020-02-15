unit NtUiLib.Reflection.Types;

interface

implementation

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiUiLib.Reflection, System.SysUtils,
  DelphiUtils.Strings, NtUtils.Exceptions, NtUtils.ErrorMsg, NtUtils.Lsa.Sid,
  NtUtils.Lsa.Logon, NtUtils.WinStation, Winapi.WinUser, NtUtils.Security.Sid,
  DelphiUtils.Reflection, Ntapi.ntseapi;

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
  // TODO: Represent TProcessId and TThreadId
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

function RepresentSidWorker(Sid: PSid; Attributes: Cardinal;
  AttributesPresent: Boolean): TRepresentation;
var
  Sections: array of THintSection;
  Success, KnownSidType: Boolean;
  Lookup: TTranslatedName;
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
    Sections[3].Title := 'State';
    Sections[3].Enabled := True;
    Sections[3].Content := MapFlags(Attributes and TGroupFlagProvider.StateMask,
      TGroupFlagProvider.Flags, False, TGroupFlagProvider.Default,
      TGroupFlagProvider.StateMask);

    Attributes := Attributes and not TGroupFlagProvider.StateMask;

    Sections[4].Title := 'Flags';
    Sections[4].Enabled := Attributes <> 0;
    Sections[4].Content := MapFlags(Attributes, TGroupFlagProvider.Flags);
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
  RegisterRepresenter(TypeInfo(NTSTATUS), RepresentNtstatus);
  RegisterRepresenter(TypeInfo(TWin32Error), RepresentWin32Error);
  RegisterRepresenter(TypeInfo(TGuid), RepresentGuid);
  RegisterRepresenter(TypeInfo(TLargeInteger), RepresentLargeInteger);
  RegisterRepresenter(TypeInfo(PSid), RepresentSid);
  RegisterRepresenter(TypeInfo(TSidAndAttributes), RepresentSidAndAttributes);
  RegisterRepresenter(TypeInfo(TLogonId), RepresentLogonId);
  RegisterRepresenter(TypeInfo(TSessionId), RepresentSessionId);
  RegisterRepresenter(TypeInfo(TRect), RepresentRect);
finalization

end.
