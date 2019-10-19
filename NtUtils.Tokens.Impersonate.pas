unit NtUtils.Tokens.Impersonate;

interface

uses
  NtUtils.Exceptions, NtUtils.Objects;

// Save current impersonation token before operations that can alter it
function NtxBackupImpersonation(hThread: THandle): IHandle;
procedure NtxRestoreImpersonation(hThread: THandle; hxToken: IHandle);

// Set thread token
function NtxSetThreadToken(hThread: THandle; hToken: THandle): TNtxStatus;
function NtxSetThreadTokenById(TID: NativeUInt; hToken: THandle): TNtxStatus;

// Set thread token and make sure it was not duplicated to Identification level
function NtxSafeSetThreadToken(hThread: THandle; hToken: THandle): TNtxStatus;
function NtxSafeSetThreadTokenById(TID: NativeUInt; hToken: THandle): TNtxStatus;

// Impersonate the token of any type on the current thread
function NtxImpersonateAnyToken(hToken: THandle): TNtxStatus;

// Assign primary token to a process
function NtxAssignPrimaryToken(hProcess: THandle; hToken: THandle): TNtxStatus;
function NtxAssignPrimaryTokenById(PID: NativeUInt; hToken: THandle): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.ntseapi,
  NtUtils.Tokens, NtUtils.Ldr, NtUtils.Processes, NtUtils.Threads,
  NtUtils.Objects.Compare;

{ Impersonation }

function NtxBackupImpersonation(hThread: THandle): IHandle;
var
  Status: NTSTATUS;
begin
  // Open the thread's token
  Status := NtxOpenThreadToken(Result, hThread, TOKEN_IMPERSONATE).Status;

  if Status = STATUS_NO_TOKEN then
    Result := nil
  else if not NT_SUCCESS(Status) then
  begin
    // Most likely the token is here, but we can't access it. Although we can
    // make a copy via direct impersonation, I am not sure we should do it.
    // Currently, just clear the token as most of Winapi functions do in this
    // situation
    Result := nil;

    if hThread = NtCurrentThread then
      ENtError.Report(Status, 'NtxBackupImpersonation');
  end;
end;

procedure NtxRestoreImpersonation(hThread: THandle; hxToken: IHandle);
begin
  // Try to establish the previous token
  if not Assigned(hxToken) or not NtxSetThreadToken(hThread,
    hxToken.Value).IsSuccess then
    NtxSetThreadToken(hThread, 0);
end;

function NtxSetThreadToken(hThread: THandle; hToken: THandle): TNtxStatus;
begin
  Result := NtxThread.SetInfo<THandle>(hThread, ThreadImpersonationToken,
    hToken);

  // TODO: what about inconsistency with NtCurrentTeb.IsImpersonating ?
end;

function NtxSetThreadTokenById(TID: NativeUInt; hToken: THandle): TNtxStatus;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_SET_THREAD_TOKEN);

  if Result.IsSuccess then
    Result := NtxSetThreadToken(hxThread.Value, hToken);
end;

{ Some notes about safe impersonation...

   In case of absence of SeImpersonatePrivilege some security contexts
   might cause the system to duplicate the token to Identification level
   which fails all access checks. The result of NtSetInformationThread
   does not provide information whether it happened.
   The goal is to detect and avoid such situations.

   NtxSafeSetThreadToken sets the token, queries it back, and compares these
   two. Anything but success causes the routine to undo the work.

   NOTE: The secutity context of the target thread is not guaranteed to return
   to its previous state. It might happen if the target thread is impersonating
   a token that the caller can't open. In this case after the failed call the
   target thread will have no token.

   To address this issue the caller can make a copy of the target thread's
   security context by using NtImpersonateThread. See implementation of
   NtxOpenEffectiveToken for more details.

Other possible implementations:

 * NtImpersonateThread fails with BAD_IMPERSONATION_LEVEL when we request
   Impersonation-level token while the thread's token is Identification or less.

}

function NtxSafeSetThreadToken(hThread: THandle; hToken: THandle): TNtxStatus;
var
  hxOldStateToken, hxActuallySetToken: IHandle;
begin
  // No need to use safe impersonation to revoke tokens
  if hToken = 0 then
    Exit(NtxSetThreadToken(hThread, hToken));

  // Backup old state
  hxOldStateToken := NtxBackupImpersonation(hThread);

  // Set the token
  Result := NtxSetThreadToken(hThread, hToken);

  if not Result.IsSuccess then
    Exit;

  // Read it back for comparison. Any access works for us.
  Result := NtxOpenThreadToken(hxActuallySetToken, hThread, MAXIMUM_ALLOWED);

  if not Result.IsSuccess then
  begin
    // Reset and exit
    NtxRestoreImpersonation(hThread, hxOldStateToken);
    Exit;
  end;

  // Revert the current thread (if it's the target) to perform comparison
  if hThread = NtCurrentThread then
    NtxRestoreImpersonation(hThread, hxOldStateToken);

  // Compare the one we were trying to set with the one actually set
  Result.Location := 'NtxCompareObjects';
  Result.Status := NtxCompareObjects(hToken, hxActuallySetToken.Value, 'Token');

  // STATUS_SUCCESS => Impersonation works fine, use it.
  // STATUS_NOT_SAME_OBJECT => Duplication happened, reset and exit
  // Oher errors => Reset and exit

  // SeImpersonatePrivilege on the target process can help
  if Result.Status = STATUS_NOT_SAME_OBJECT then
  begin
    Result.Location := 'NtxSafeSetThreadToken';
    Result.LastCall.ExpectedPrivilege := SE_IMPERSONATE_PRIVILEGE;
    Result.Status := STATUS_PRIVILEGE_NOT_HELD;
  end;

  if Result.Status = STATUS_SUCCESS then
  begin
    // Repeat in case of the current thread (we reverted it for comparison)
    if hThread = NtCurrentThread then
      Result := NtxSetThreadToken(hThread, hToken);
  end
  else
  begin
    // Failed, reset the security context if we haven't done it yet
    if hThread <> NtCurrentThread then
      NtxRestoreImpersonation(hThread, hxOldStateToken);
  end;
end;

function NtxSafeSetThreadTokenById(TID: NativeUInt; hToken: THandle):
  TNtxStatus;
var
  hxThread: IHandle;
begin
  Result := NtxOpenThread(hxThread, TID, THREAD_QUERY_LIMITED_INFORMATION or
    THREAD_SET_THREAD_TOKEN);

  if Result.IsSuccess then
    Result := NtxSafeSetThreadToken(hxThread.Value, hToken);
end;

function NtxImpersonateAnyToken(hToken: THandle): TNtxStatus;
var
  hxImpToken: IHandle;
begin
  // Try to impersonate (in case it is an impersonation-type token)
  Result := NtxSetThreadToken(NtCurrentThread, hToken);

  if Result.Matches(STATUS_BAD_TOKEN_TYPE, 'NtSetInformationThread') then
  begin
    // Nope, it is a primary token, duplicate it
    Result := NtxDuplicateToken(hxImpToken, hToken, TOKEN_IMPERSONATE,
      TokenImpersonation, SecurityImpersonation);

    // Impersonate, second attempt
    if Result.IsSuccess then
      Result := NtxSetThreadToken(NtCurrentThread, hxImpToken.Value);
  end;
end;

function NtxAssignPrimaryToken(hProcess: THandle;
  hToken: THandle): TNtxStatus;
var
  AccessToken: TProcessAccessToken;
begin
  AccessToken.Thread := 0; // Looks like the call ignores it
  AccessToken.Token := hToken;

  Result := NtxProcess.SetInfo<TProcessAccessToken>(hProcess,
    ProcessAccessToken, AccessToken);
end;

function NtxAssignPrimaryTokenById(PID: NativeUInt;
  hToken: THandle): TNtxStatus;
var
  hxProcess: IHandle;
begin
  Result := NtxOpenProcess(hxProcess, PID, PROCESS_SET_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  Result := NtxAssignPrimaryToken(hxProcess.Value, hToken);
end;

end.
