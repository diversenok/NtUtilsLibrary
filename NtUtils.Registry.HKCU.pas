unit NtUtils.Registry.HKCU;

interface

uses
  Winapi.WinNt, NtUtils;

// Get current user's hive path
function RtlxCurrentUserKeyPath(hToken: THandle;
  out Path: String): TNtxStatus;

// Open a handle to the HKCU part of the registry
function RtlxOpenCurrentUserKey(hToken: THandle; out hxKey: IHandle;
  DesiredAccess: TAccessMask; OpenOptions: Cardinal = 0;
  Attributes: Cardinal = 0): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntseapi, Ntapi.ntregapi, NtUtils.Tokens.Query,
  NtUtils.Security.Sid, NtUtils.Registry;

function RtlxCurrentUserKeyPath(hToken: THandle;
  out Path: String): TNtxStatus;
begin
  Result := NtxQueryUserSddlToken(hToken, Path);

  if Result.IsSuccess then
    Path := REG_PATH_USER + '\' + Path;
end;

function RtlxOpenCurrentUserKey(hToken: THandle; out hxKey: IHandle;
  DesiredAccess: TAccessMask; OpenOptions: Cardinal; Attributes: Cardinal):
  TNtxStatus;
var
  HKCU: String;
begin
  Result := RtlxCurrentUserKeyPath(hToken, HKCU);

  if not Result.IsSuccess then
    Exit;

  Result := NtxOpenKey(hxKey, HKCU, DesiredAccess, 0, OpenOptions, Attributes);

  // Redirect to HKU\.Default if the user's profile is not loaded
  if Result.Status = STATUS_OBJECT_NAME_NOT_FOUND then
    Result := NtxOpenKey(hxKey, REG_PATH_USER_DEFAULT, DesiredAccess, 0,
      OpenOptions, Attributes);
end;

end.
