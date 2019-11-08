unit NtUtils.Registry.HKCU;

interface

uses
  Winapi.WinNt, NtUtils.Exceptions, NtUtils.Objects, NtUtils.Registry;

// Get current user's hive path
function RtlxFormatCurrentUserKeyPath(out Path: String): TNtxStatus;

// Open a handle to the HKCU part of the registry
function RtlxOpenCurrentUserKey(out hxKey: IHandle; DesiredAccess: TAccessMask;
  OpenOptions: Cardinal = 0; Attributes: Cardinal = 0) : TNtxStatus;

implementation

uses
  Ntapi.ntseapi, Ntapi.ntpsapi, Ntapi.ntstatus, Ntapi.ntregapi,
  NtUtils.Tokens, NtUtils.Lsa, NtUtils.Security.Sid;

function RtlxFormatCurrentUserKeyPath(out Path: String): TNtxStatus;
var
  hxToken: IHandle;
  User: TGroup;
  UserName: String;
begin
  // Check the thread's token
  Result := NtxOpenThreadToken(hxToken, NtCurrentThread, TOKEN_QUERY);

  // Fall back to process' token
  if Result.Status = STATUS_NO_TOKEN then
    Result := NtxOpenProcessToken(hxToken, NtCurrentProcess, TOKEN_QUERY);

  if Result.IsSuccess then
  begin
    // Query the SID and convert it to string
    Result := NtxQueryGroupToken(hxToken.Value, TokenUser, User);

    if Result.IsSuccess then
      Path := User.SecurityIdentifier.SDDL;
  end
  else
  begin
    // Ask LSA for help since we can't open our security context
    if LsaxGetUserName(UserName).IsSuccess then
      if LsaxLookupUserName(UserName, User.SecurityIdentifier).IsSuccess then
      begin
        Path := User.SecurityIdentifier.SDDL;
        Result.Status := STATUS_SUCCESS;
      end;
  end;

  if Result.IsSuccess then
    Path := REG_PATH_USER + '\' + Path;
end;

function RtlxOpenCurrentUserKey(out hxKey: IHandle; DesiredAccess: TAccessMask;
  OpenOptions: Cardinal; Attributes: Cardinal) : TNtxStatus;
var
  HKCU: String;
begin
  Result := RtlxFormatCurrentUserKeyPath(HKCU);

  if not Result.IsSuccess then
    Exit;

  Result := NtxOpenKey(hxKey, HKCU, DesiredAccess, 0, OpenOptions, Attributes);

  // Redirect to HKU\.Default if the user's profile is not loaded
  if Result.Status = STATUS_OBJECT_NAME_NOT_FOUND then
    Result := NtxOpenKey(hxKey, REG_PATH_USER_DEFAULT, DesiredAccess, 0,
      OpenOptions, Attributes);
end;

end.
