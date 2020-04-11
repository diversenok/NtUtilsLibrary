unit NtUtils.Lsa.Logon;

interface

uses
  Winapi.WinNt, Winapi.ntsecapi, NtUtils.Exceptions, NtUtils.Security.Sid,
  DelphiUiLib.Strings, DelphiApi.Reflection;

type
  TLogonDataClass = (lsLogonId, lsSecurityIdentifier, lsUserName, lsLogonDomain,
    lsAuthPackage, lsLogonType, lsSession, lsLogonTime, lsLogonServer,
    lsDnsDomainName, lsUpn, lsUserFlags, lsLastSuccessfulLogon,
    lsLastFailedLogon, lsFailedAttemptSinceSuccess, lsLogonScript,
    lsProfilePath, lsHomeDirectory, lsHomeDirectoryDrive, lsLogoffTime,
    lsKickOffTime, lsPasswordLastSet, lsPasswordCanChange, lsPasswordMustChange
  );

  ILogonSession = interface
    function LogonId: TLogonId;
    function RawData: PSecurityLogonSessionData;
    function User: ISid;
    function QueryString(InfoClass: TLogonDataClass): String;
  end;

// Enumerate logon sessions
function LsaxEnumerateLogonSessions(out Luids: TArray<TLogonId>): TNtxStatus;

// Query logon session information; always returns LogonSession parameter
function LsaxQueryLogonSession(LogonId: TLogonId;
  out LogonSession: ILogonSession): TNtxStatus;

// Format a name of a logon session
function LsaxQueryNameLogonSession(LogonId: TLogonId): String;

implementation

uses
  NtUtils.Processes.Query, System.SysUtils, NtUtils.Lsa.Sid,
  DelphiUiLib.Reflection;

type
  TLogonSession = class(TInterfacedObject, ILogonSession)
  private
    FLuid: TLogonId;
    FSid: ISid;
    Data: PSecurityLogonSessionData;
  public
    constructor Create(Id: TLogonId; Buffer: PSecurityLogonSessionData);
    function LogonId: TLogonId;
    function RawData: PSecurityLogonSessionData;
    function User: ISid;
    function QueryString(InfoClass: TLogonDataClass): String;
    destructor Destroy; override;
  end;

{ TLogonSession }

constructor TLogonSession.Create(Id: TLogonId;
  Buffer: PSecurityLogonSessionData);
begin
  FLuid := Id;
  Data := Buffer;

  // Fix missing logon ID
  if Assigned(Buffer) and (Buffer.LogonId = 0) then
    Buffer.LogonId := Id;

  // Construct well known SIDs
  if not Assigned(Data) then
    case FLuid of
      SYSTEM_LUID:
        FSid := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
          SECURITY_LOCAL_SYSTEM_RID);

      ANONYMOUS_LOGON_LUID:
        FSid := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
          SECURITY_ANONYMOUS_LOGON_RID);

      LOCALSERVICE_LUID:
        FSid := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
          SECURITY_LOCAL_SERVICE_RID);

      NETWORKSERVICE_LUID:
        FSid := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
          SECURITY_NETWORK_SERVICE_RID);
    end
  else if not RtlxCaptureCopySid(Data.Sid, FSid).IsSuccess then
    FSid := nil;
end;

destructor TLogonSession.Destroy;
begin
  if Assigned(Data) then
    LsaFreeReturnBuffer(Data);
  inherited;
end;

function TLogonSession.LogonId: TLogonId;
begin
  Result := FLuid;
end;

function TLogonSession.QueryString(InfoClass: TLogonDataClass): String;
begin
  Result := 'Unknown';

  // Only a few data classes are available when the query failed
  case InfoClass of
    lsLogonId:
      Result := IntToHexEx(FLuid);

    lsSecurityIdentifier:
      if Assigned(FSid) then
        Result := LsaxSidToString(FSid.Sid)
      else if Assigned(Data) then
        Result := 'No User';
  end;

  if not Assigned(Data) then
    Exit;

  case InfoClass of
    lsUserName:
      Result := Data.UserName.ToString;

    lsLogonDomain:
      Result := Data.LogonDomain.ToString;

    lsAuthPackage:
      Result := Data.AuthenticationPackage.ToString;

    lsLogonType:
      Result := PrettifyCamelCaseEnum(TypeInfo(TSecurityLogonType),
        Integer(Data.LogonType), 'LogonType');

    lsSession:
      Result := Cardinal(Data.Session).ToString;

    lsLogonTime:
      Result := RepresentType(TypeInfo(TLargeInteger), Data.LogonTime).Text;

    lsLogonServer:
      Result := Data.LogonServer.ToString;

    lsDnsDomainName:
      Result := Data.DnsDomainName.ToString;

    lsUpn:
      Result := Data.Upn.ToString;

    lsUserFlags:
      Result := RepresentType(TypeInfo(TLogonFlags), Data.UserFlags).Text;

    lsLastSuccessfulLogon:
      Result := RepresentType(TypeInfo(TLargeInteger),
        Data.LastLogonInfo.LastSuccessfulLogon).Text;

    lsLastFailedLogon:
      Result := RepresentType(TypeInfo(TLargeInteger),
        Data.LastLogonInfo.LastFailedLogon).Text;

    lsFailedAttemptSinceSuccess:
      Result := Data.LastLogonInfo.FailedAttemptsSinceLastSuccessfulLogon.
        ToString;

    lsLogonScript:
      Result := Data.LogonScript.ToString;

    lsProfilePath:
      Result := Data.ProfilePath.ToString;

    lsHomeDirectory:
      Result := Data.HomeDirectory.ToString;

    lsHomeDirectoryDrive:
      Result := Data.HomeDirectoryDrive.ToString;

    lsLogoffTime:
      Result := RepresentType(TypeInfo(TLargeInteger), Data.LogoffTime).Text;

    lsKickOffTime:
      Result := RepresentType(TypeInfo(TLargeInteger), Data.KickOffTime).Text;

    lsPasswordLastSet:
      Result := RepresentType(TypeInfo(TLargeInteger),
        Data.PasswordLastSet).Text;

    lsPasswordCanChange:
      Result := RepresentType(TypeInfo(TLargeInteger),
        Data.PasswordCanChange).Text;

    lsPasswordMustChange:
      Result := RepresentType(TypeInfo(TLargeInteger),
        Data.PasswordMustChange).Text;

  end;
end;

function TLogonSession.RawData: PSecurityLogonSessionData;
begin
  Result := Data;
end;

function TLogonSession.User: ISid;
begin
  Result := FSid;
end;

{ Functions }

function LsaxEnumerateLogonSessions(out Luids: TArray<TLogonId>): TNtxStatus;
var
  Count, i: Integer;
  Buffer: PLuidArray;
  HasAnonymousLogon: Boolean;
begin
  Result.Location := 'LsaEnumerateLogonSessions';
  Result.Status := LsaEnumerateLogonSessions(Count, Buffer);

  if not Result.IsSuccess then
    Exit;

  SetLength(Luids, Count);

  // Invert the order so that later logons appear later in the list
  for i := 0 to High(Luids) do
    Luids[i] := Buffer{$R-}[Count - 1 - i]{$R+};

  LsaFreeReturnBuffer(Buffer);

  // Make sure anonymous logon is in the list (most likely it is not)
  HasAnonymousLogon := False;

  for i := 0 to High(Luids) do
    if Luids[i] = ANONYMOUS_LOGON_LUID then
    begin
      HasAnonymousLogon := True;
      Break;
    end;

  if not HasAnonymousLogon then
    Insert(ANONYMOUS_LOGON_LUID, Luids, 0);
end;

function LsaxQueryLogonSession(LogonId: TLogonId;
  out LogonSession: ILogonSession): TNtxStatus;
var
  Buffer: PSecurityLogonSessionData;
begin
{$IFDEF Win32}
  // TODO -c WoW64: LsaGetLogonSessionData returns a weird pointer
  if RtlxAssertNotWoW64(Result) then
    Exit;
{$ENDIF}

  Result.Location := 'LsaGetLogonSessionData';
  Result.Status := LsaGetLogonSessionData(LogonId, Buffer);

  if not Result.IsSuccess then
    Buffer := nil;

  LogonSession := TLogonSession.Create(LogonId, Buffer)
end;

function LsaxQueryNameLogonSession(LogonId: TLogonId): String;
var
  LogonData: ILogonSession;
  User: TTranslatedName;
begin
  Result := IntToHexEx(LogonId);

  if LsaxQueryLogonSession(LogonId, LogonData).IsSuccess then
  begin
    if Assigned(LogonData.User) and LsaxLookupSid(LogonData.User.Sid,
      User).IsSuccess and not (User.SidType in [SidTypeUndefined,
      SidTypeInvalid, SidTypeUnknown]) and (User.UserName <> '') then
    begin
      if Assigned(LogonData.RawData) then
        Result := Format('%s (%s @ %d)', [Result, User.UserName,
          LogonData.RawData.Session])
      else
        Result := Format('%s (%s)', [Result, User.UserName])
    end;
  end;
end;

end.
