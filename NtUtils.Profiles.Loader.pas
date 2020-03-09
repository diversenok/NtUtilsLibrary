unit NtUtils.Profiles.Loader;

interface

uses
  NtUtils.Exceptions, NtUtils.Objects, NtUtils.Profiles;

// Load a profile using a token
function UnvxLoadProfile(out hxKey: IHandle; hToken: THandle; UserName: String;
  out Info: TProfileInfo): TNtxStatus;

// Unload a profile using a token
function UnvxUnloadProfile(hToken: THandle; hProfile: THandle): TNtxStatus;

implementation

uses
  Ntapi.ntseapi, Winapi.UserEnv;

function UnvxLoadProfile(out hxKey: IHandle; hToken: THandle; UserName: String;
  out Info: TProfileInfo): TNtxStatus;
var
  Profile: TProfileInfoW;
begin
  FillChar(Profile, SizeOf(Profile), 0);
  Profile.Size := SizeOf(Profile);
  Profile.UserName := PWideChar(UserName);

  Result.Location := 'LoadUserProfileW';
  Result.LastCall.Expects(TOKEN_QUERY or TOKEN_IMPERSONATE or TOKEN_DUPLICATE,
    @TokenAccessType);
  Result.Win32Result := LoadUserProfileW(hToken, Profile);

  if Result.IsSuccess then
  begin
     Info.Flags := Profile.Flags;
     Info.ProfilePath := String(Profile.ProfilePath);
     hxKey := TAutoHandle.Capture(Profile.hProfile);
  end;
end;

function UnvxUnloadProfile(hToken: THandle; hProfile: THandle): TNtxStatus;
begin
  Result.Location := 'UnloadUserProfile';
  Result.Win32Result := UnloadUserProfile(hToken, hProfile);
end;

end.
