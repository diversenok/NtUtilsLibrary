unit NtUiLib.Reflection.Types;

interface

implementation

uses
  Winapi.WinNt, Ntapi.ntdef, NtUiLib.Reflection, System.SysUtils,
  DelphiUtils.Strings, NtUtils.Exceptions, NtUtils.ErrorMsg, NtUtils.Lsa.Sid,
  NtUtils.Lsa.Logon, NtUtils.WinStation;

function RepresentWideString(Instance: Pointer): String;
begin
  if not Assigned(PWideChar(Instance^)) then
    Result := '(empty)'
  else
    Result := String(PWideChar(Instance^));
end;

function RepresentUnicodeString(Instance: Pointer): String;
begin
  if UNICODE_STRING(Instance^).Length = 0 then
    Result := '(empty)'
  else
    Result := UNICODE_STRING(Instance^).ToString;
end;

function RepresentClientId(Instance: Pointer): String;
begin
  Result := Format('[PID: %d, TID: %d]', [TClientId(Instance^).UniqueProcess,
    TClientId(Instance^).UniqueThread]);
end;

function RepresentNtstatus(Instance: Pointer): String;
begin
  Result := NtxStatusToString(NTSTATUS(Instance^));
end;

function RepresentWin32Error(Instance: Pointer): String;
begin
  Result := NtxWin32ErrorToString(TWin32Error(Instance^));
end;

function RepresentLargeInteger(Instance: Pointer): String;
begin
  if TLargeInteger(Instance^) = 0 then
    Result := 'Never'
  else if TLargeInteger(Instance^) = Int64.MaxValue then
    Result := 'Infinite'
  else
    Result := DateTimeToStr(LargeIntegerToDateTime(TLargeInteger(Instance^)));
end;

function RepresentSid(Instance: Pointer): String;
begin
  if Assigned(PSid(Instance^)) then
    Result := LsaxSidToString(PSid(Instance^))
  else
    Result := '(nil)'
end;

function RepresentLogonId(Instance: Pointer): String;
begin
  Result := LsaxQueryNameLogonSession(TLogonId(Instance^));
end;

function RepresentSessionId(Instance: Pointer): String;
begin
  Result := WsxQueryName(TSessionId(Instance^));
end;

initialization
  RegisterRepresenter(TypeInfo(PWideChar), RepresentWideString);
  RegisterRepresenter(TypeInfo(UNICODE_STRING), RepresentUnicodeString);
  RegisterRepresenter(TypeInfo(TClientId), RepresentClientId);
  RegisterRepresenter(TypeInfo(NTSTATUS), RepresentNtstatus);
  RegisterRepresenter(TypeInfo(TWin32Error), RepresentWin32Error);
  RegisterRepresenter(TypeInfo(TLargeInteger), RepresentLargeInteger);
  RegisterRepresenter(TypeInfo(PSid), RepresentSid);
  RegisterRepresenter(TypeInfo(TLogonId), RepresentLogonId);
  RegisterRepresenter(TypeInfo(TSessionId), RepresentSessionId);
finalization

end.
