unit NtUiLib.AutoCompletion.Sid.Common;

{
  The module registers additional SID recognizers and name providers, allowing
  parsing and representing of some common SIDs.

  Parsing:
    - NT SERVICE\*
    - NT TASK\*
    - NT AUTHORITY\LogonSessionId_*_*
    - Process Trust\*

  Representation:
    - Process Trust\*
}

interface

const
  SERVICE_SID_DOMAIN = 'NT SERVICE';
  TASK_SID_DOMAIN = 'NT TASK';
  PROCESS_TRUST_DOMAIN = 'Process Trust'; // custom

implementation

uses
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.Versions, NtUtils, NtUtils.Security.Sid,
  NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxLogonSidRecognizer(
  const StringSid: String;
  out Sid: ISid
): Boolean;
const
  FULL_PREFIX = 'NT AUTHORITY\LogonSessionId_';
  SHORT_PREFIX = 'LogonSessionId_';
var
  LogonIdStr: String;
  SplitIndex: Integer;
  LogonIdHighString, LogonIdLowString: String;
  LogonIdHigh, LogonIdLow: Cardinal;
  i: Integer;
begin
  // LSA lookup functions automatically convert S-1-5-5-X-Y to
  // NT AUTHORITY\LogonSessionId_X_Y and then refuse to parse them back.
  // Fix this issue by parsing such strings manually.

  // Check if the string has the logon SID prefix and strip it
  LogonIdStr := StringSid;

  if not RtlxPrefixStripString(FULL_PREFIX, LogonIdStr) and not
    RtlxPrefixString(SHORT_PREFIX, LogonIdStr) then
    Exit(False);

  // Find the underscore between high and low parts
  SplitIndex := -1;

  for i := Low(LogonIdStr) to High(LogonIdStr) do
    if LogonIdStr[i] = '_' then
    begin
      SplitIndex := i;
      Break;
    end;

  if SplitIndex < 0 then
    Exit(False);

  // Split the string
  LogonIdHighString := Copy(LogonIdStr, 1, SplitIndex - Low(String));
  LogonIdLowString := Copy(LogonIdStr, SplitIndex - Low(String) + 2,
    Length(LogonIdStr) - SplitIndex + Low(String));

  // Parse and construct the SID
  Result :=
    (Length(LogonIdHighString) > 0) and
    (Length(LogonIdLowString) > 0) and
    RtlxStrToUInt(LogonIdHighString, LogonIdHigh) and
    RtlxStrToUInt(LogonIdLowString, LogonIdLow) and
    RtlxCreateSid(Sid, SECURITY_NT_AUTHORITY,
      [SECURITY_LOGON_IDS_RID, LogonIdHigh, LogonIdLow]).IsSuccess;
end;

function RtlxServiceSidRecognizer(
  const StringSid: String;
  out Sid: ISid
): Boolean;
const
  PREFIX = SERVICE_SID_DOMAIN + '\';
  ALL_SERVICES = 'ALL SERVICES';
var
  ServiceName: String;
begin
  // Service SIDs are deterministically derived from the service name.
  // We can parse them even without the help of LSA.

  Result := False;
  ServiceName := StringSid;

  if not RtlxPrefixStripString(PREFIX, ServiceName) then
    Exit;

  // NT SERVICE\ALL SERVICES is a reserved name
  if RtlxEqualStrings(ServiceName, ALL_SERVICES) then
    Result := RtlxCreateSid(Sid, SECURITY_NT_AUTHORITY,
      [SECURITY_SERVICE_ID_BASE_RID, SECURITY_SERVICE_ID_GROUP_RID]).IsSuccess
  else
    Result := RtlxCreateServiceSid(ServiceName, Sid).IsSuccess;
end;

function RtlxTaskSidRecognizer(
  const StringSid: String;
  out Sid: ISid
): Boolean;
const
  PREFIX = TASK_SID_DOMAIN + '\';
var
  TaskName: String;
begin
  // Task SIDs are deterministically derived from the task path name.
  // We can parse them even without the help of LSA.

  TaskName := StringSid;
  Result := RtlxPrefixStripString(PREFIX, TaskName) and
    RtlxCreateVirtualAccountSid(TaskName, SECURITY_TASK_ID_BASE_RID,
    Sid).IsSuccess;
end;

function RtlxTrustSidRecognizer(
  const SidString: String;
  out Sid: ISid
): Boolean;
const
  PROCESS_TRUST_PREFIX = PROCESS_TRUST_DOMAIN + '\';
var
  Name: String;
  TrustType: TSecurityTrustType;
  TrustLevel: TSecurityTrustLevel;
begin
  Name := SidString;
  Result := RtlxPrefixStripString(PROCESS_TRUST_PREFIX, Name);

  if not Result then
    Exit;

  if RtlxEqualStrings(Name, 'None') then
  begin
    TrustType := SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID;
    TrustLevel := SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID;
  end
  else
  begin
    if RtlxPrefixStripString('None ', Name) then
      TrustType := SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID
    else if RtlxPrefixStripString('Light ', Name) then
      TrustType := SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID
    else if RtlxPrefixStripString('Full ', Name) then
      TrustType := SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID
    else
      Exit(False);

    if RtlxEqualStrings('(None)', Name) then
      TrustLevel := SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID
    else if RtlxEqualStrings('(Authenticode)', Name) then
      TrustLevel := SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID
    else if RtlxEqualStrings('(Antimalware)', Name) then
      TrustLevel := SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID
    else if RtlxEqualStrings('(Store)', Name) then
      TrustLevel := SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID
    else if RtlxEqualStrings('(Windows)', Name) then
      TrustLevel := SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID
    else if RtlxEqualStrings('(WinTcb)', Name) then
      TrustLevel := SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID
    else
      Exit(False);
  end;

  // Generate the SID
  Result := RtlxCreateSid(Sid, SECURITY_PROCESS_TRUST_AUTHORITY,
    [TrustType, TrustLevel]).IsSuccess;
end;

function RtlxTrustSidProvider(
  const Sid: ISid;
  out SidType: TSidNameUse;
  out SidDomain: String;
  out SidUser: String
): Boolean;
var
  TrustType: TSecurityTrustType;
  TrustLevel: TSecurityTrustLevel;
begin
  // Check the SID structure
  Result := (RtlxIdentifierAuthoritySid(Sid) = SECURITY_PROCESS_TRUST_AUTHORITY)
    and (RtlxSubAuthorityCountSid(Sid) =
    SECURITY_PROCESS_TRUST_AUTHORITY_RID_COUNT);

  if not Result then
    Exit;

  SidDomain := PROCESS_TRUST_DOMAIN;
  SidType := SidTypeWellKnownGroup;

  TrustType := RtlxSubAuthoritySid(Sid, 0);
  TrustLevel := RtlxSubAuthoritySid(Sid, 1);

  // Shortcut for no trust
  if (TrustType = SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID) and
    (TrustLevel = SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID) then
  begin
    SidUser := 'None';
    Exit;
  end;

  case TrustType of
    SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID: SidUser := 'None';
    SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID: SidUser := 'Light';
    SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID: SidUser := 'Full';
  else
    Exit(False);
  end;

  case TrustLevel of
    SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID:
      SidUser := SidUser + ' (None)';

    SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID:
      SidUser := SidUser + ' (Authenticode)';

    SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID:
      SidUser := SidUser + ' (Antimalware)';

    SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID:
      SidUser := SidUser + ' (Store)';

    SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID:
      SidUser := SidUser + ' (Windows)';

    SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID:
      SidUser := SidUser + ' (WinTcb)';
  else
    Exit(False);
  end;
end;

initialization
  RtlxRegisterSidNameRecognizer(RtlxLogonSidRecognizer);
  RtlxRegisterSidNameRecognizer(RtlxServiceSidRecognizer);
  RtlxRegisterSidNameRecognizer(RtlxTaskSidRecognizer);

  if RtlOsVersionAtLeast(OsWin81) then
  begin
    RtlxRegisterSidNameProvider(RtlxTrustSidProvider);
    RtlxRegisterSidNameRecognizer(RtlxTrustSidRecognizer);
  end;
end.
