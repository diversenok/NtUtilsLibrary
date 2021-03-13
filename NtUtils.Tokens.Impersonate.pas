unit NtUtils.Tokens.Impersonate;

{
  The module provides support for working with impersonation tokens.
}

interface

{ NOTE: All functions here support pseudo-handles on input on all OS versions }

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils, NtUtils.Objects;

const
  THREAD_SAFE_SET_TOKEN = THREAD_SET_THREAD_TOKEN or
    THREAD_QUERY_LIMITED_INFORMATION;

  // For server thread
  THREAD_SAFE_IMPERSONATE = THREAD_IMPERSONATE or THREAD_DIRECT_IMPERSONATION;

type
  // Custom flags for safe impersonation
  TSafeImpersonateFlags = set of (
    siSkipLevelCheck,
    siConvertPrimary
  );

// Capture the current impersonation token before performing operations that can
// alter it. The interface we return will set the token back when released.
function NtxBackupImpersonation(hxThread: IHandle): IAutoReleasable;

// Set thread token
function NtxSetThreadToken(
  hThread: THandle;
  hToken: THandle
): TNtxStatus;

// Set thread token by Thread ID
function NtxSetThreadTokenById(
  TID: TThreadId;
  hToken: THandle
): TNtxStatus;

// Set thread token and make sure it was not duplicated to Identification level
function NtxSafeSetThreadToken(
  hxThread: IHandle;
  hToken: THandle;
  Flags: TSafeImpersonateFlags = []
): TNtxStatus;

// Set thread token and make sure it was not duplicated to Identification level
function NtxSafeSetThreadTokenById(
  TID: TThreadId;
  hToken: THandle;
  Flags: TSafeImpersonateFlags = []
): TNtxStatus;

// Impersonate the token of any type on the current thread
function NtxImpersonateAnyToken(hToken: THandle): TNtxStatus;

// Makes a server thread impersonate a client thread
function NtxImpersonateThread(
  hServerThread: THandle;
  hClientThread: THandle;
  ImpersonationLevel: TSecurityImpersonationLevel = SecurityImpersonation;
  EffectiveOnly: Boolean = False
): TNtxStatus;

// Makes a server thread impersonate a client thread. Also determines which
// impersonation level was actually used.
function NtxSafeImpersonateThread(
  hServerThread: THandle;
  hClientThread: THandle;
  var ImpersonationLevel: TSecurityImpersonationLevel;
  EffectiveOnly: Boolean = False
): TNtxStatus;

// Make a thread impersonate an anonymous token
function NtxImpersonateAnonymousToken(hThread: THandle): TNtxStatus;

// Assign primary token to a process
function NtxAssignPrimaryToken(
  hProcess: THandle;
  hToken: THandle
): TNtxStatus;

// Assign primary token to a process by a process ID
function NtxAssignPrimaryTokenById(
  PID: TProcessId;
  hToken: THandle
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntseapi, NtUtils.Processes,
  NtUtils.Tokens, NtUtils.Processes.Query, NtUtils.Threads,
  NtUtils.Tokens.Query;

function NtxBackupImpersonation;
var
  Status: TNtxStatus;
  hxToken: IHandle;
begin
  // Open the thread's token
  Status := NtxOpenThreadToken(hxToken, hxThread.Handle, TOKEN_IMPERSONATE);

  if not Status.IsSuccess then
  begin
    // Ideally, we should clear impersonation only on STATUS_NO_TOKEN.
    // However, it might happen that we get STATUS_ACCESS_DENIED or other errors
    // that indicate that the thread has a token we cannot read. We could
    // use direct impersonation to obtain a copy in this case, but for now just
    // clear it the same way most Winapi functions do.

    // Zero token indicates clearing impersonation
    hxToken := TAutoHandle.Capture(0);
    hxToken.AutoRelease := False;
  end;

  Result := TDelayedOperation.Create(
    procedure
    begin
      // Try to establish the captured token. If we can't, at least clear
      // current impersonation as most Winapi functions would do. Also, we
      // can potentially introduce a setting for using safe impersonation
      // here. Not sure whether we should, though.

      if not NtxSetThreadToken(hxThread.Handle, hxToken.Handle).IsSuccess then
        NtxSetThreadToken(hxThread.Handle, 0);
    end
  );
end;

function NtxSetThreadToken;
var
  hxToken: IHandle;
begin
  // Handle pseudo-handles as well
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_IMPERSONATE);

  if Result.IsSuccess then
    Result := NtxThread.&Set(hThread, ThreadImpersonationToken, hxToken.Handle);

  // TODO: what about inconsistency with NtCurrentTeb.IsImpersonating ?
end;

function NtxSetThreadTokenById;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_SET_THREAD_TOKEN);

  if Result.IsSuccess then
    Result := NtxSetThreadToken(hxThread.Handle, hToken);
end;

{ Some notes about safe impersonation...

   Usually, the system establishes the exact token we passed to the system call
   as an impersonation token for the target thread. However, in some cases it
   duplicates the token or adjusts it a bit.

 * Anonymous up to identification-level tokens do not require any special
   treatment - you can impersonate any of them without limitations.

 As for impersonation- and delegation-level tokens:

 * If the target process does not have SeImpersonatePrivilege, some security
   contexts can't be impersonated by its threads. The system duplicates such
   tokens to identification level which fails all further access checks for
   the target thread. Unfortunately, the result of NtSetInformationThread does
   not provide any information whether it happened. The goal is to detect and
   avoid such situations since we should consider such impersonations as failed.

 * Also, if the trust level of the target process is lower than the trust level
   specified in the token, the system duplicates the token removing the trust
   label; as for the rest, the impersonations succeeds. This scenario does not
   allow us to determine whether the impersonation was successful by simply
   comparing the source and the actually set tokens. Duplication does not
   necessarily means failed impersonation.

   NtxSafeSetThreadToken sets the token, queries what was actually set, and
   checks the impersonation level. Anything but success causes the routine to
   undo its work.

 Note:

   The security context of the target thread is not guaranteed to return to its
   previous state. It might happen if the target thread is impersonating a token
   that the caller can't open. In this case after the failed call the target
   thread will have no token.

   To address this issue the caller can make a copy of the target thread's
   token by using NtImpersonateThread. See implementation of
   NtxDuplicateEffectiveToken for more details.

 Other possible implementations:

 * Since NtImpersonateThread fails with BAD_IMPERSONATION_LEVEL when we request
   Impersonation-level token while the thread's token is Identification or less.
   We can use this behaviour to determine which level the target token is.
}

function NtxSafeSetThreadToken;
var
  hxActuallySetToken, hxToken: IHandle;
  StateBackup: IAutoReleasable;
  Stats: TTokenStatistics;
begin
  // No need to use safe impersonation to revoke tokens
  if hToken = 0 then
    Exit(NtxSetThreadToken(hxThread.Handle, hToken));

  hxToken := nil;

  if not (siSkipLevelCheck in Flags) then
  begin
    // Determine the type and impersonation level of the token
    Result := NtxToken.Query(hToken, TokenStatistics, Stats);

    if not Result.IsSuccess then
      Exit;

    // Convert primary tokens if required
    if (Stats.TokenType = TokenPrimary) and (siConvertPrimary in Flags) then
    begin
      Result := NtxDuplicateToken(hxToken, hToken, TokenImpersonation,
        SecurityImpersonation);

      if not Result.IsSuccess then
        Exit;
    end

    // Anonymous up to Identification do not require any special treatment
    else if (Stats.TokenType <> TokenImpersonation) or
      (Stats.ImpersonationLevel < SecurityImpersonation) then
      Exit(NtxSetThreadToken(hxThread.Handle, hToken));
  end;

  // Make sure we handle pseudo-tokens as well
  if not Assigned(hxToken) then
  begin
    Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_IMPERSONATE);

    if not Result.IsSuccess then
      Exit;
  end;

  // Backup the current impersonation state of the target thread.
  // IAutoReleasable will revert it in case of failure.
  StateBackup := NtxBackupImpersonation(hxThread);

  // Set the token
  Result := NtxSetThreadToken(hxThread.Handle, hxToken.Handle);

  if not Result.IsSuccess then
  begin
    // No need to revert impersonation if we didn't change it.
    StateBackup.AutoRelease := False;
    Exit;
  end;

  // Read the token back for inspection
  Result := NtxOpenThreadToken(hxActuallySetToken, hxThread.Handle, TOKEN_QUERY);

  if not Result.IsSuccess then
    Exit;

  // Determine the used impersonation level
  Result := NtxToken.Query(hxActuallySetToken.Handle, TokenStatistics, Stats);

  if not Result.IsSuccess then
    Exit;

  if Stats.ImpersonationLevel < SecurityImpersonation then
  begin
    // Safe impersonation failed. SeImpersonatePrivilege
    // on the target process can help.
    Result.Location := 'NtxSafeSetThreadToken';
    Result.LastCall.ExpectedPrivilege := SE_IMPERSONATE_PRIVILEGE;
    Result.Status := STATUS_PRIVILEGE_NOT_HELD;
    Exit;
  end;

  // Success. No need to revert anything.
  StateBackup.AutoRelease := False;
end;

function NtxSafeSetThreadTokenById;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_SAFE_SET_TOKEN);

  if Result.IsSuccess then
    Result := NtxSafeSetThreadToken(hxThread, hToken, Flags);
end;

function NtxImpersonateAnyToken;
var
  hxToken, hxImpToken: IHandle;
begin
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_IMPERSONATE);

  if not Result.IsSuccess then
    Exit;

  // Try to impersonate (in case it is an impersonation-type token)
  Result := NtxSetThreadToken(NtCurrentThread, hxToken.Handle);

  if Result.Matches(STATUS_BAD_TOKEN_TYPE, 'NtSetInformationThread') then
  begin
    // Nope, it is a primary token, duplicate it
    Result := NtxDuplicateToken(hxImpToken, hToken, TokenImpersonation,
      SecurityImpersonation);

    // Impersonate, second attempt
    if Result.IsSuccess then
      Result := NtxSetThreadToken(NtCurrentThread, hxImpToken.Handle);
  end;
end;

function NtxImpersonateThread;
var
  QoS: TSecurityQualityOfService;
begin
  InitializaQoS(QoS, ImpersonationLevel, EffectiveOnly);

  // Direct impersonation makes the server thread to impersonate an effective
  // security context of the client thread. No access checks are performed on
  // the client's token, the server obtains a copy. Note, that the actual
  // impersonation level might turn to be less then the one requested.

  Result.Location := 'NtImpersonateThread';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_IMPERSONATE); // Server
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_DIRECT_IMPERSONATION); // Client

  Result.Status := NtImpersonateThread(hServerThread, hClientThread, QoS);
end;

function NtxSafeImpersonateThread;
begin
  // No need to use safe impersonation for identification and less
  if ImpersonationLevel <= SecurityIdentification then
    Exit(NtxImpersonateThread(hServerThread, hClientThread, ImpersonationLevel,
      EffectiveOnly));

  // Make the server impersonate the client. This might result in setting an
  // identification-level token on the server (which might or might not be us).
  Result := NtxImpersonateThread(hServerThread, hClientThread,
    ImpersonationLevel, EffectiveOnly);

  if not Result.IsSuccess then
    Exit;

  // Now try to perform seemingly meaningless operation by using the server
  // thread both as a client and as a server. If the previous operation
  // succeeded, it will merely duplicate the impersonation token. However, if
  // the server previously failed the impersonation and got identification-
  // level token, the system won't allow us to duplicate the token to
  // the requested impersonation level, failing the request.
  Result := NtxImpersonateThread(hServerThread, hServerThread,
    ImpersonationLevel, EffectiveOnly);

  if Result.Matches(STATUS_BAD_IMPERSONATION_LEVEL, 'NtImpersonateThread') then
  begin
    // The srever got identification-level token.
    // SeImpersonatePrivilege on the server process can help
    ImpersonationLevel := SecurityIdentification;
    Result.Status := STATUS_SUCCESS;
  end;
end;

function NtxImpersonateAnonymousToken;
begin
  Result.Location := 'NtImpersonateAnonymousToken';
  Result.LastCall.Expects<TThreadAccessMask>(THREAD_IMPERSONATE);
  Result.Status := NtImpersonateAnonymousToken(hThread);
end;

function NtxAssignPrimaryToken;
var
  hxToken: IHandle;
  AccessToken: TProcessAccessToken;
begin
  // Manage pseudo-tokens
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_ASSIGN_PRIMARY);

  if Result.IsSuccess then
  begin
    AccessToken.Thread := 0; // Looks like the call ignores it
    AccessToken.Token := hxToken.Handle;

    Result := NtxProcess.&Set(hProcess, ProcessAccessToken, AccessToken);
  end;
end;

function NtxAssignPrimaryTokenById;
var
  hxProcess: IHandle;
begin
  Result := NtxOpenProcess(hxProcess, PID, PROCESS_SET_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  Result := NtxAssignPrimaryToken(hxProcess.Handle, hToken);
end;

end.
