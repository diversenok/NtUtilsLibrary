unit NtUtils.UserManager;

{
  This module provides functions for interacting with User Manager service.
}

interface

uses
  Ntapi.WinNt, Ntapi.usermgr, Ntapi.ntseapi, Ntapi.Versions, NtUtils,
  DelphiUtils.AutoObjects;

type
  TSessionUserContext = Ntapi.usermgr.TSessionUserContext;

{ Contexts }

// Enumerate session user contexts
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UmgrxEnumerateSessionUsers(
  out Contexts: TArray<TSessionUserContext>
): TNtxStatus;

// Query user context from a token
[MinOSVersion(OsWin10TH1)]
function UMgrxQueryUserContext(
  [Access(TOKEN_QUERY)] hxToken: IHandle;
  out ContextToken: TLuid
): TNtxStatus;

// Query user context from a user SID
[MinOSVersion(OsWin10TH1)]
function UMgrxQueryUserContextFromSid(
  const Sid: ISid;
  out ContextToken: TLuid
): TNtxStatus;

// Query user context from a user name
[MinOSVersion(OsWin10TH1)]
function UMgrxQueryUserContextFromName(
  const UserName: String;
  out ContextToken: TLuid
): TNtxStatus;

{ Tokens }

// Open the token of the default account
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrxQueryDefaultAccountToken(
  out hxToken: IHandle
): TNtxStatus;

// Open the token of the user session
[MinOSVersion(OsWin10TH1)]
function UMgrxQuerySessionUserToken(
  SessionId: TSessionId;
  out hxToken: IHandle
): TNtxStatus;

// Open the token of the user by its context
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrxQueryUserToken(
  Context: TLuid;
  out hxToken: IHandle
): TNtxStatus;

// Open the token of the user by its SID
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrxQueryUserTokenFromSid(
  const Sid: ISid;
  out hxToken: IHandle
): TNtxStatus;

// Open the token of the user by its name
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrxQueryUserTokenFromName(
  const UserName: String;
  out hxToken: IHandle
): TNtxStatus;

// Open the impersonation token of the user by its token and context
[MinOSVersion(OsWin10TH2)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
function UMgrxQueryImpersonationTokenForContext(
  [Access(TOKEN_QUERY or TOKEN_IMPERSONATE)] hxInputToken: IHandle;
  Context: TLuid;
  out hxOutputToken: IHandle
): TNtxStatus;

// Open the token of the active user shell in the session
[MinOSVersion(OsWin10RS1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrxQueryActiveShellUserToken(
  SessionId: TSessionId;
  out hxToken: IHandle
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ProcessThreadsApi, NtUtils.Ldr, NtUtils.Security.Sid,
  NtUtils.Tokens, NtUtils.Objects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function UmgrxDelayedFreeSessionUsers(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  if not LdrxCheckDelayedImport(delayed_UMgrFreeSessionUsers).IsSuccess then
    Exit(nil);

  Result := Auto.Delay(
    procedure
    begin
      UMgrFreeSessionUsers(Buffer);
    end
  );
end;

[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UmgrxEnumerateSessionUsers(
  out Contexts: TArray<TSessionUserContext>
): TNtxStatus;
var
  Buffer: PSessionUserContextArray;
  BufferDeallocator: IAutoReleasable;
  Count: Cardinal;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrEnumerateSessionUsers);

  if not Result.IsSuccess then
    Exit;

  Buffer := nil;
  Result.Location := 'UMgrEnumerateSessionUsers';
  Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;
  Result.HResult := UMgrEnumerateSessionUsers(Count, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := UmgrxDelayedFreeSessionUsers(Buffer);
  SetLength(Contexts, Count);

  for i := 0 to High(Contexts) do
    Contexts[i] := Buffer{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

function UMgrxQueryUserContext;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrQueryUserContext);

  if not Result.IsSuccess then
    Exit;

  Result := NtxExpandToken(hxToken, TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'UMgrQueryUserContext';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY);
  Result.HResult := UMgrQueryUserContext(hxToken.Handle, ContextToken);
end;

function UMgrxQueryUserContextFromSid;
var
  SDDL: String;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrQueryUserContextFromSid);

  if not Result.IsSuccess then
    Exit;

  SDDL := RtlxSidToString(Sid);
  Result.Location := 'UMgrQueryUserContextFromSid';
  Result.HResult := UMgrQueryUserContextFromSid(PWideChar(SDDL), ContextToken);
end;

function UMgrxQueryUserContextFromName;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrQueryUserContextFromName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'UMgrQueryUserContextFromName';
  Result.HResult := UMgrQueryUserContextFromName(PWideChar(UserName),
    ContextToken);
end;

function UMgrxQueryDefaultAccountToken;
var
  hToken: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrQueryDefaultAccountToken);

  if not Result.IsSuccess then
    Exit;

  hToken := 0;
  Result.Location := 'UMgrQueryDefaultAccountToken';
  Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;
  Result.HResult := UMgrQueryDefaultAccountToken(hToken);

  if not Result.IsSuccess then
    Exit;

  Result := NtxCaptureHandle(hxToken, hToken);
end;

function UMgrxQuerySessionUserToken;
var
  hToken: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrQuerySessionUserToken);

  if not Result.IsSuccess then
    Exit;

  hToken := 0;
  Result.Location := 'UMgrQuerySessionUserToken';
  Result.HResult := UMgrQuerySessionUserToken(SessionId, hToken);

  if not Result.IsSuccess then
    Exit;

  Result := NtxCaptureHandle(hxToken, hToken);
end;

function UMgrxQueryUserToken;
var
  hToken: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrQueryUserToken);

  if not Result.IsSuccess then
    Exit;

  hToken := 0;
  Result.Location := 'UMgrQueryUserToken';
  Result.HResult := UMgrQueryUserToken(Context, hToken);

  if not Result.IsSuccess then
    Exit;

  Result := NtxCaptureHandle(hxToken, hToken);
end;

function UMgrxQueryUserTokenFromSid;
var
  hToken: THandle;
  SDDL: String;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrQueryUserTokenFromSid);

  if not Result.IsSuccess then
    Exit;

  hToken := 0;
  SDDL := RtlxSidToString(Sid);
  Result.Location := 'UMgrQueryUserTokenFromSid';
  Result.HResult := UMgrQueryUserTokenFromSid(PWideChar(SDDL), hToken);

  if not Result.IsSuccess then
    Exit;

  Result := NtxCaptureHandle(hxToken, hToken);
end;

function UMgrxQueryUserTokenFromName;
var
  hToken: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrQueryUserTokenFromName);

  if not Result.IsSuccess then
    Exit;

  hToken := 0;
  Result.Location := 'UMgrQueryUserTokenFromName';
  Result.HResult := UMgrQueryUserTokenFromName(PWideChar(UserName), hToken);

  if not Result.IsSuccess then
    Exit;

  Result := NtxCaptureHandle(hxToken, hToken);
end;

function UMgrxQueryImpersonationTokenForContext;
var
  hOutputToken: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrGetImpersonationTokenForContext);

  if not Result.IsSuccess then
    Exit;

  Result := NtxExpandToken(hxInputToken, TOKEN_QUERY or TOKEN_IMPERSONATE);

  if not Result.IsSuccess then
    Exit;

  hOutputToken := 0;
  Result.Location := 'UMgrGetImpersonationTokenForContext';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY or TOKEN_IMPERSONATE);
  Result.LastCall.ExpectedPrivilege := SE_IMPERSONATE_PRIVILEGE;
  Result.HResult := UMgrGetImpersonationTokenForContext(hxInputToken.Handle,
    Context, hOutputToken);

  if not Result.IsSuccess then
    Exit;

  Result := NtxCaptureHandle(hxOutputToken, hOutputToken);
end;

function UMgrxQueryActiveShellUserToken;
var
  hToken: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_UMgrGetSessionActiveShellUserToken);

  if not Result.IsSuccess then
    Exit;

  hToken := 0;
  Result.Location := 'UMgrGetSessionActiveShellUserToken';
  Result.HResult := UMgrGetSessionActiveShellUserToken(SessionId, hToken);

  if not Result.IsSuccess then
    Exit;

  Result := NtxCaptureHandle(hxToken, hToken);
end;

end.
