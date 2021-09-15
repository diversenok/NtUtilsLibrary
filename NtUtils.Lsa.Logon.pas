unit NtUtils.Lsa.Logon;

{
  This module enumerating and retrieving information about active logon sessions
}

interface

uses
  Ntapi.WinNt, Ntapi.NtSecApi, NtUtils, DelphiUtils.AutoObjects;

type
  ILogonSession = IMemory<PSecurityLogonSessionData>;

// Enumerate logon sessions
function LsaxEnumerateLogonSessions(
  out Luids: TArray<TLogonId>
): TNtxStatus;

// Query logon session information
function LsaxQueryLogonSession(
  const LogonId: TLogonId;
  out Data: ILogonSession
): TNtxStatus;

// Construct a SID for one of well-known logon sessions
function LsaxLookupKnownLogonSessionSid(
  const LogonId: TLogonId
): ISid;

implementation

uses
  NtUtils.Security.Sid, NtUtils.Processes.Info;

type
  TLsaAutoMemory = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

{ TLogonAutoMemory<P> }

procedure TLsaAutoMemory.Release;
begin
  LsaFreeReturnBuffer(FData);
  inherited;
end;

{ Functions }

function LsaxEnumerateLogonSessions;
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

function LsaxQueryLogonSession;
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

  IMemory(Data) := TLsaAutoMemory.Capture(Buffer, Buffer.Size);
end;

function LsaxLookupKnownLogonSessionSid;
begin
  case LogonId of
    SYSTEM_LUID:
      RtlxCreateSid(Result, SECURITY_NT_AUTHORITY, [SECURITY_LOCAL_SYSTEM_RID]);

    ANONYMOUS_LOGON_LUID:
      RtlxCreateSid(Result, SECURITY_NT_AUTHORITY, [SECURITY_ANONYMOUS_LOGON_RID]);

    LOCALSERVICE_LUID:
      RtlxCreateSid(Result, SECURITY_NT_AUTHORITY, [SECURITY_LOCAL_SERVICE_RID]);

    NETWORKSERVICE_LUID:
      RtlxCreateSid(Result, SECURITY_NT_AUTHORITY, [SECURITY_NETWORK_SERVICE_RID]);

    IUSER_LUID:
      RtlxCreateSid(Result, SECURITY_NT_AUTHORITY, [SECURITY_IUSER_RID]);
  else
    Result := nil;
  end;
end;

end.
