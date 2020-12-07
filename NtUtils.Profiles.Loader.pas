unit NtUtils.Profiles.Loader;

interface

uses
  Winapi.WinNt, NtUtils, NtUtils.Objects, NtUtils.Profiles;

// Load a profile using a SID
function UnvxLoadProfileBySid(Sid: PSid; LoadFlags: Cardinal = 0): TNtxStatus;

// Unload a profile
function UnvxUnloadProfileBySid(Sid: PSid; Force: Boolean = False): TNtxStatus;

// Reload the profile making it readonly/writable
function UnvxReloadProfileBySid(Sid: PSid; MakeReadOnly: Boolean): TNtxStatus;

// Load a profile using a token
function UnvxLoadProfile(out hxKey: IHandle; hToken: THandle; UserName: String;
  out Info: TProfileInfo): TNtxStatus;

// Unload a profile using a token
function UnvxUnloadProfile(hToken: THandle; hProfile: THandle): TNtxStatus;

implementation

uses
  Ntapi.ntregapi, Ntapi.ntseapi, Winapi.UserEnv, NtUtils.Registry,
  NtUtils.Security.Sid, NtUtils.Environment, NtUtils.Files;

const
  PROFILE_CLASSES_LINK = 'Software\Classes';
  PROFILE_CLASSES_HIVE = '_Classes';
  PROFILE_REG_FILE = '\NTUSER.DAT';
  PROFILE_REG_CLASS_FILE = '\AppData\Local\Microsoft\Windows\UsrClass.dat';

function UnvxLoadProfileBySid(Sid: PSid; LoadFlags: Cardinal): TNtxStatus;
var
  Info: TProfileInfo;
  UserFileName, ClassesFileName: String;
  UserKeyName, ClassesKeyName: String;
  hxUser, hxClasses: IHandle;
begin
  // Query profile
  Result := UnvxQueryProfile(Sid, Info);

  if not Result.IsSuccess then
    Exit;

  // Make the profile path absolute
  Result := RtlxExpandStringVar(RtlxCurrentEnvironment, Info.ProfilePath);

  if not Result.IsSuccess then
    Exit;

  // Prepare the file names
  UserFileName := Info.ProfilePath + PROFILE_REG_FILE;
  Result := RtlxDosPathToNtPathVar(UserFileName);

  if not Result.IsSuccess then
    Exit;

  // Load the profile key
  UserKeyName := REG_PATH_USER + '\' + RtlxSidToString(Sid);
  Result := NtxLoadKeyEx(hxUser, UserFileName, UserKeyName,
    REG_LOAD_HIVE_OPEN_HANDLE or LoadFlags);

  if not Result.IsSuccess then
    Exit;

  if Info.FullProfile then
  begin
    // Prepare the hive file for Classes
    ClassesFileName := Info.ProfilePath + PROFILE_REG_CLASS_FILE;
    Result := RtlxDosPathToNtPathVar(ClassesFileName);
    ClassesKeyName := UserKeyName + PROFILE_CLASSES_HIVE;

    // Load the Classes key using the User key as a trust class key
    // to make the symlink to Classes work
    if Result.IsSuccess then
      Result := NtxLoadKeyEx(hxClasses, ClassesFileName, ClassesKeyName,
        REG_LOAD_HIVE_OPEN_HANDLE or LoadFlags, hxUser.Handle);

    if Result.IsSuccess then
    begin
      // Create a volatile symlink to the user's classes
      Result := NtxCreateSymlinkKey(PROFILE_CLASSES_LINK, ClassesKeyName,
        REG_OPTION_VOLATILE, AttributeBuilder.UseRoot(hxUser));

      // Undo classes load if failed to link it
      if not Result.IsSuccess then
      begin
        hxClasses := nil;
        NtxUnloadKey(ClassesKeyName, True);
      end;
    end;

    // Undo partial profile load
    if not Result.IsSuccess then
    begin
      hxUser := nil;
      NtxUnloadKey(UserKeyName, True);
    end;
  end;
end;

function UnvxUnloadProfileBySid(Sid: PSid; Force: Boolean = False): TNtxStatus;
begin
  Result := NtxUnloadKey(REG_PATH_USER + '\' + RtlxSidToString(Sid), Force);

  if Result.IsSuccess then
    Result := NtxUnloadKey(REG_PATH_USER + '\' + RtlxSidToString(Sid) +
      PROFILE_CLASSES_HIVE, Force);
end;

function UnvxReloadProfileBySid(Sid: PSid; MakeReadOnly: Boolean): TNtxStatus;
var
  Flags: Cardinal;
begin
  // Unload the profile forcibly
  Result := UnvxUnloadProfileBySid(Sid, True);

  // Load it back with/without readonly flag
  if Result.IsSuccess then
  begin
    if MakeReadOnly then
      Flags := REG_OPEN_READ_ONLY
    else
      Flags := 0;

    Result := UnvxLoadProfileBySid(Sid, Flags);
  end;
end;

function UnvxLoadProfile(out hxKey: IHandle; hToken: THandle; UserName: String;
  out Info: TProfileInfo): TNtxStatus;
var
  Profile: TProfileInfoW;
begin
  FillChar(Profile, SizeOf(Profile), 0);
  Profile.Size := SizeOf(Profile);
  Profile.UserName := PWideChar(UserName);

  Result.Location := 'LoadUserProfileW';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY or TOKEN_IMPERSONATE or
    TOKEN_DUPLICATE);

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
