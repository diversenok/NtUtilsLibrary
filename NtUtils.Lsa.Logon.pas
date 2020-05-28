unit NtUtils.Lsa.Logon;

interface

uses
  Winapi.WinNt, Winapi.NtSecApi, NtUtils, NtUtils.Security.Sid,
  DelphiUtils.AutoObject;

type
  ILogonSession = IMemory<PSecurityLogonSessionData>;

// Enumerate logon sessions
function LsaxEnumerateLogonSessions(out Luids: TArray<TLogonId>): TNtxStatus;

// Query logon session information
function LsaxQueryLogonSession(LogonId: TLogonId; out Data: ILogonSession):
  TNtxStatus;

// Construct a SID for one of well-known logon sessions
function LsaxLookupKnownLogonSessionSid(LogonId: TLogonId): ISid;

// Format a name of a logon session
function LsaxQueryNameLogonSession(LogonId: TLogonId): String;

implementation

uses
  NtUtils.Lsa.Sid, NtUtils.SysUtils, NtUtils.Processes.Query;

type
  TLsaAutoMemory<P> = class (TCustomAutoMemory<P>, IMemory<P>)
    destructor Destroy; override;
  end;

{ TLogonAutoMemory<P> }

destructor TLsaAutoMemory<P>.Destroy;
begin
  if FAutoRelease then
    LsaFreeReturnBuffer(FAddress);
  inherited;
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

function LsaxQueryLogonSession(LogonId: TLogonId; out Data: ILogonSession):
  TNtxStatus;
var
  Buffer: PSecurityLogonSessionData;
begin
{$IFDEF Win32}
  // LsaGetLogonSessionData returns an invalid pointer under WoW64
  if RtlxAssertNotWoW64(Result) then
    Exit;
{$ENDIF}

  Result.Location := 'LsaGetLogonSessionData';
  Result.Status := LsaGetLogonSessionData(LogonId, Buffer);

  if not Result.IsSuccess then
    Exit;

  // Fix missing logon ID
  if Buffer.LogonId = 0 then
    Buffer.LogonId := LogonId;

  Data := TLsaAutoMemory<PSecurityLogonSessionData>.Capture(Buffer, 0);
end;

function LsaxLookupKnownLogonSessionSid(LogonId: TLogonId): ISid;
begin
  case LogonId of
    SYSTEM_LUID:
      Result := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
        SECURITY_LOCAL_SYSTEM_RID);

    ANONYMOUS_LOGON_LUID:
      Result := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
        SECURITY_ANONYMOUS_LOGON_RID);

    LOCALSERVICE_LUID:
      Result := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
        SECURITY_LOCAL_SERVICE_RID);

    NETWORKSERVICE_LUID:
      Result := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
        SECURITY_NETWORK_SERVICE_RID);

    IUSER_LUID:
      Result := TSid.CreateNew(SECURITY_NT_AUTHORITY, 1,
        SECURITY_IUSER_RID);
  else
    Result := nil;
  end;
end;

function LsaxQueryNameLogonSession(LogonId: TLogonId): String;
var
  LogonData: ILogonSession;
  Sid: ISid;
  User: TTranslatedName;
begin
  Result := RtlxIntToStr(LogonId, 16);

  // Try known SIDs first
  Sid := LsaxLookupKnownLogonSessionSid(LogonId);

  // Query logon session otherwise
  if not Assigned(Sid) and LsaxQueryLogonSession(LogonId, LogonData).IsSuccess
    and not RtlxCaptureCopySid(LogonData.Data.Sid, Sid).IsSuccess then
    Sid := nil;

  // Lookup the user name
  if Assigned(Sid) and LsaxLookupSid(Sid.Sid, User).IsSuccess and not
    (User.SidType in [SidTypeUndefined, SidTypeInvalid, SidTypeUnknown]) and
    (User.UserName <> '') then
  begin
    Result := Result + ' (' + User.UserName;

    if Assigned(LogonData) then
      Result := Result + ' @ ' + RtlxIntToStr(LogonData.Data.Session);

    Result := Result + ')';
  end;
end;

end.
