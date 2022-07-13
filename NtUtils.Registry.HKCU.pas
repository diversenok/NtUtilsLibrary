unit NtUtils.Registry.HKCU;

{
  The module provides functions for opening HKEY_CURRENT_USER key relative to a
  token.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, Ntapi.ntregapi, NtUtils;

// Get user's hive path. Uses the effective token by default.
function RtlxFormatUserKeyPath(
  out Path: String;
  [opt, Access(TOKEN_QUERY)] hxToken: IHandle = nil
): TNtxStatus;

// Open a handle to a key under the HKCU hive
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpForBypassingChecks)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpForBypassingChecks)]
function RtlxOpenUserKey(
  out hxKey: IHandle;
  DesiredAccess: TRegKeyAccessMask;
  [opt] Name: String = '';
  [opt, Access(TOKEN_QUERY)] hxToken: IHandle = nil;
  OpenOptions: TRegOpenOptions = 0;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.Tokens, NtUtils.Tokens.Info, NtUtils.Security.Sid,
  NtUtils.Registry;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxFormatUserKeyPath;
begin
  if not Assigned(hxToken) then
    hxToken := NtxCurrentEffectiveToken;

  Result := NtxQueryUserSddlToken(hxToken, Path);

  if Result.IsSuccess then
    Path := REG_PATH_USER + '\' + Path;
end;

function RtlxOpenUserKey;
var
  HKCU: String;
begin
  Result := RtlxFormatUserKeyPath(HKCU, hxToken);

  if not Result.IsSuccess then
    Exit;

  if Name <> '' then
    Name := HKCU + '\' + Name
  else
    Name := HKCU;

  Result := NtxOpenKey(hxKey, Name, DesiredAccess, OpenOptions,
    AttributeBuilder.UseAttributes(HandleAttributes));

  // Redirect to HKU\.Default if the user's profile is not loaded
  if Result.Status = STATUS_OBJECT_NAME_NOT_FOUND then
    Result := NtxOpenKey(hxKey, REG_PATH_USER_DEFAULT, DesiredAccess,
      OpenOptions, AttributeBuilder.UseAttributes(HandleAttributes));
end;

end.
