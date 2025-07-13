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

// Construct a SID for one of well-known logon sessions. May return nil.
[Result: opt]
function LsaxLookupKnownLogonSessionSid(
  const LogonId: TLogonId
): ISid;

implementation

uses
  NtUtils.Security.Sid, NtUtils.Processes.Info;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TAutoLsaBufferMemory = class (TCustomAutoMemory)
    destructor Destroy; override;
  end;

{ TLogonAutoMemory }

destructor TAutoLsaBufferMemory.Destroy;
begin
  if Assigned(FData) and not FDiscardOwnership then
    LsaFreeReturnBuffer(FData);

  inherited;
end;

function DeferLsaFreeReturnBuffer(
  [in] Buffer: Pointer
): IDeferredOperation;
begin
  Result := Auto.Defer(
    procedure
    begin
      LsaFreeReturnBuffer(Buffer);
    end
  );
end;

{ Functions }

function LsaxEnumerateLogonSessions;
var
  Count, i: Integer;
  Buffer: PLuidArray;
  BufferDeallocator: IDeferredOperation;
  HasAnonymousLogon: Boolean;
begin
  Result.Location := 'LsaEnumerateLogonSessions';
  Result.Status := LsaEnumerateLogonSessions(Count, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferLsaFreeReturnBuffer(Buffer);
  SetLength(Luids, Count);

  // Invert the order so that later logons appear later in the list
  for i := 0 to High(Luids) do
    Luids[i] := Buffer{$R-}[Count - 1 - i]{$IFDEF R+}{$R+}{$ENDIF};

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

  IMemory(Data) := TAutoLsaBufferMemory.Capture(Buffer, Buffer.Size);
end;

function LsaxLookupKnownLogonSessionSid;
begin
  case LogonId of
    SYSTEM_LUID:
      Result := RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_LOCAL_SYSTEM_RID]);

    ANONYMOUS_LOGON_LUID:
      Result := RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_ANONYMOUS_LOGON_RID]);

    LOCALSERVICE_LUID:
      Result := RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_LOCAL_SERVICE_RID]);

    NETWORKSERVICE_LUID:
      Result := RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_NETWORK_SERVICE_RID]);

    IUSER_LUID:
      Result := RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_IUSER_RID]);
  else
    Result := nil;
  end;
end;

end.
