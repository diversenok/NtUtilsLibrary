unit NtUtils.Registry.HKCU;

{
  The module provides functions for opening HKEY_CURRENT_USER key relative to a
  token.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, Ntapi.ntregapi, NtUtils;

// Get current user's hive path
function RtlxFormatUserKeyPath(
  out Path: String;
  hToken: THandle = NtCurrentProcessToken
): TNtxStatus;

// Open a handle to the HKCU part of the registry
function RtlxOpenUserKey(
  out hxKey: IHandle;
  DesiredAccess: TRegKeyAccessMask;
  hToken: THandle = NtCurrentProcessToken;
  OpenOptions: TRegOpenOptions = 0;
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.Tokens.Query,
  NtUtils.Security.Sid, NtUtils.Registry;

function RtlxFormatUserKeyPath;
begin
  Result := NtxQueryUserSddlToken(hToken, Path);

  if Result.IsSuccess then
    Path := REG_PATH_USER + '\' + Path;
end;

function RtlxOpenUserKey;
var
  HKCU: String;
  ObjAttributes: IObjectAttributes;
begin
  Result := RtlxFormatUserKeyPath(HKCU, hToken);

  if not Result.IsSuccess then
    Exit;

  if HandleAttributes <> 0 then
    ObjAttributes := AttributeBuilder.UseAttributes(HandleAttributes)
  else
    ObjAttributes := nil;

  Result := NtxOpenKey(hxKey, HKCU, DesiredAccess, OpenOptions,
    ObjAttributes);

  // Redirect to HKU\.Default if the user's profile is not loaded
  if Result.Status = STATUS_OBJECT_NAME_NOT_FOUND then
    Result := NtxOpenKey(hxKey, REG_PATH_USER_DEFAULT, DesiredAccess,
      OpenOptions, ObjAttributes);
end;

end.
