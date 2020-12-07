unit NtUtils.Registry.HKCU;

interface

uses
  Winapi.WinNt, Ntapi.ntseapi, Ntapi.ntdef, NtUtils;

// Get current user's hive path
function RtlxFormatUserKeyPath(out Path: String; hToken: THandle =
  NtCurrentProcessToken): TNtxStatus;

// Open a handle to the HKCU part of the registry
function RtlxOpenUserKey(out hxKey: IHandle; DesiredAccess: TAccessMask;
  hToken: THandle = NtCurrentProcessToken; OpenOptions: Cardinal = 0;
  HandleAttributes: TObjectAttributesFlags = 0): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntregapi, NtUtils.Tokens.Query,
  NtUtils.Security.Sid, NtUtils.Registry;

function RtlxFormatUserKeyPath(out Path: String; hToken: THandle): TNtxStatus;
begin
  Result := NtxQueryUserSddlToken(hToken, Path);

  if Result.IsSuccess then
    Path := REG_PATH_USER + '\' + Path;
end;

function RtlxOpenUserKey(out hxKey: IHandle; DesiredAccess: TAccessMask;
  hToken: THandle; OpenOptions: Cardinal; HandleAttributes:
  TObjectAttributesFlags): TNtxStatus;
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
