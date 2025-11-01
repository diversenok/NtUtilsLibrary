unit NtUtils.Profiles;

{
  The module provides support for working with user profiles.
}

interface

uses
  Ntapi.WinNt, Ntapi.UserEnv, Ntapi.ntseapi, NtUtils, DelphiApi.Reflection;

// Load a user profile
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnvxLoadProfile(
  out hxKey: IHandle;
  [Access(TOKEN_LOAD_PROFILE)] hxToken: IHandle
): TNtxStatus;

// Unload a user profile
// Note: the function closes the profile key handle.
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnvxUnloadProfile(
  [Access(0)] const hxProfileKey: IHandle;
  [Access(TOKEN_LOAD_PROFILE)] hxToken: IHandle
): TNtxStatus;

// Query a known path for a profile
function UnvxQueryProfileFolder(
  FolderId: TProfileFolderId;
  const Sid: ISid;
  out Path: String
): TNtxStatus;

{ Profile List }

// Enumerate existing profiles on the system
function RtlxEnumerateProfiles(
  out Profiles: TArray<ISid>
): TNtxStatus;

// Enumerate loaded profiles on the system
function RtlxEnumerateLoadedProfiles(
  out Profiles: TArray<ISid>
): TNtxStatus;

// Determine is a user profile is currently loaded
function RtlxIsProfileLoaded(
  const UserSid: ISid
): Boolean;

// Open the registry key that stores profile properties
function RtlxOpenProfileListKey(
  const UserSid: ISid;
  out hxProfileListKey: IHandle
): TNtxStatus;

// Query the path to the root of a profile
function RtlxQueryProfilePath(
  const hxProfileListKey: IHandle;
  out Path: String
): TNtxStatus;

// Query the flags for a profile
function RtlxQueryProfileFlags(
  const hxProfileListKey: IHandle;
  out Flags: TProfileFlags
): TNtxStatus;

// Query the state (aka. internal flags) for a profile
function RtlxQueryProfileState(
  const hxProfileListKey: IHandle;
  out State: TProfileInternalFlags
): TNtxStatus;

// Query if a profile is a full profile
function RtlxQueryProfileIsFullProfile(
  const hxProfileListKey: IHandle;
  out FullProfile: LongBool
): TNtxStatus;

// Query the last load time of a profile
function RtlxQueryProfileLocalLoadTime(
  const hxProfileListKey: IHandle;
  out LoadTime: TLargeInteger
): TNtxStatus;

// Query the last unload time of a profile
function RtlxQueryProfileLocalUnloadTime(
  const hxProfileListKey: IHandle;
  out UnloadTime: TLargeInteger
): TNtxStatus;

implementation

uses
  Ntapi.ntregapi, Ntapi.ntstatus, NtUtils.Registry, NtUtils.Ldr, NtUtils.Tokens,
  DelphiUtils.Arrays, NtUtils.Security.Sid, NtUtils.Objects, NtUtils.SysUtils,
  NtUtils.Tokens.Info, NtUtils.Lsa.Sid;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

const
  PROFILE_PATH = REG_PATH_MACHINE + '\SOFTWARE\Microsoft\Windows NT\' +
    'CurrentVersion\ProfileList';

{ User profiles }

function UnvxLoadProfile;
var
  Sid: ISid;
  UserName: String;
  Profile: TProfileInfoW;
begin
  Result := LdrxCheckDelayedImport(delayed_LoadUserProfileW);

  if not Result.IsSuccess then
    Exit;

  // Expand pseudo-handles
  Result := NtxExpandToken(hxToken, TOKEN_LOAD_PROFILE);

  if not Result.IsSuccess then
    Exit;

  // Determine the SID
  Result := NtxQuerySidToken(hxToken, TokenUser, Sid);

  if not Result.IsSuccess then
    Exit;

  UserName := LsaxSidToString(Sid);

  Profile := Default(TProfileInfoW);
  Profile.Size := SizeOf(Profile);
  Profile.UserName := PWideChar(UserName);

  Result.Location := 'LoadUserProfileW';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_LOAD_PROFILE);

  Result.Win32Result := LoadUserProfileW(hxToken.Handle, Profile);

  if Result.IsSuccess then
    hxKey := Auto.CaptureHandle(Profile.hProfile);
end;

function UnvxUnloadProfile;
begin
  Result := LdrxCheckDelayedImport(delayed_UnloadUserProfile);

  if not Result.IsSuccess then
    Exit;

  // Expand pseudo-handles
  Result := NtxExpandToken(hxToken, TOKEN_LOAD_PROFILE);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'UnloadUserProfile';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_LOAD_PROFILE);

  Result.Win32Result := UnloadUserProfile(hxToken.Handle,
    HandleOrDefault(hxProfileKey));

  // UnloadUserProfile closes the key handle
  if Result.IsSuccess then
    hxProfileKey.DiscardOwnership;
end;

function UnvxQueryProfileFolder;
const
  INITIAL_SIZE = MAX_PATH * SizeOf(WideChar);
var
  UserSidString: String;
  Buffer: IMemory;
begin
  Result := LdrxCheckDelayedImport(delayed_GetBasicProfileFolderPath);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Sid) then
  begin
    Result := RtlxSidToString(Sid, UserSidString);

    if not Result.IsSuccess then
      Exit;
  end
  else
    UserSidString := '';

  Buffer := Auto.AllocateDynamic(INITIAL_SIZE);
  repeat
    Result.Location := 'GetBasicProfileFolderPath';
    Result.LastCall.UsesInfoClass(FolderId, icQuery);
    Result.HResult := GetBasicProfileFolderPath(FolderId, PWideChar(
      UserSidString), Buffer.Data, Buffer.Size div SizeOf(WideChar));
  until not NtxExpandBufferEx(Result, Buffer, Buffer.Size * 2 + 16, nil);

  if not Result.IsSuccess then
    Exit;

  Path := RtlxCaptureStringWithRange(Buffer.Data, Buffer.Offset(Buffer.Size));
end;

function RtlxEnumerateProfiles;
var
  hxKey: IHandle;
  ProfileKeys: TArray<TNtxRegKey>;
begin
  // Lookup the profile list in the registry
  Result := NtxOpenKey(hxKey, PROFILE_PATH, KEY_ENUMERATE_SUB_KEYS);

  if not Result.IsSuccess then
    Exit;

  // Each sub-key is a profile SID
  Result := NtxEnumerateKeys(hxKey, ProfileKeys);

  if not Result.IsSuccess then
    Exit;

  // Convert strings to SIDs ignoring irrelevant entries
  Profiles := TArray.Convert<TNtxRegKey, ISid>(ProfileKeys,
    function (
      const Key: TNtxRegKey;
      out Sid: ISid
    ): Boolean
    begin
      Result := RtlxStringToSidConverter(Key.Name, Sid);
    end
  );
end;

function RtlxEnumerateLoadedProfiles;
var
  hxKey: IHandle;
  ProfileKeys: TArray<TNtxRegKey>;
begin
  // Each loaded profile is a sub-key in HKU
  Result := NtxOpenKey(hxKey, REG_PATH_USER, KEY_ENUMERATE_SUB_KEYS);

  if not Result.IsSuccess then
    Exit;

  Result := NtxEnumerateKeys(hxKey, ProfileKeys);

  if not Result.IsSuccess then
    Exit;

  // Convert strings to SIDs ignoring irrelevant entries
  Profiles := TArray.Convert<TNtxRegKey, ISid>(ProfileKeys,
    function (
      const Key: TNtxRegKey;
      out Sid: ISid
    ): Boolean
    begin
      Result := RtlxStringToSidConverter(Key.Name, Sid);
    end
  );
end;

function RtlxIsProfileLoaded;
var
  hxKey: IHandle;
  UserSidString: String;
begin
  Result := RtlxSidToString(UserSid, UserSidString).IsSuccess and
    (NtxOpenKey(hxKey, REG_PATH_USER + '\' + UserSidString, 0).Status <>
    STATUS_OBJECT_NAME_NOT_FOUND);
end;

function RtlxOpenProfileListKey;
var
  UserSidString: String;
begin
  Result := RtlxSidToString(UserSid, UserSidString);

  if not Result.IsSuccess then
    Exit;

  Result := NtxOpenKey(hxProfileListKey, PROFILE_PATH + '\' + UserSidString,
    KEY_QUERY_VALUE);
end;

function RtlxQueryProfilePath;
begin
  Result := NtxQueryValueKeyString(hxProfileListKey, 'ProfileImagePath', Path);
end;

function RtlxQueryProfileFlags;
begin
  Result := NtxQueryValueKeyUInt32(hxProfileListKey, 'Flags', Cardinal(Flags));
end;

function RtlxQueryProfileState;
begin
  Result := NtxQueryValueKeyUInt32(hxProfileListKey, 'State', Cardinal(State));
end;

function RtlxQueryProfileIsFullProfile;
begin
  Result := NtxQueryValueKeyUInt32(hxProfileListKey, 'FullProfile',
    Cardinal(FullProfile));
end;

function RtlxQueryProfileLocalLoadTime;
var
  LowHigh: TLargeIntegerRecord absolute LoadTime;
begin
  Result := NtxQueryValueKeyUInt32(hxProfileListKey, 'LocalProfileLoadTimeLow',
    LowHigh.LowPart);

  if not Result.IsSuccess then
    Exit;

  Result := NtxQueryValueKeyUInt32(hxProfileListKey, 'LocalProfileLoadTimeHigh',
    LowHigh.HighPart);
end;

function RtlxQueryProfileLocalUnloadTime;
var
  LowHigh: TLargeIntegerRecord absolute UnloadTime;
begin
  Result := NtxQueryValueKeyUInt32(hxProfileListKey,
    'LocalProfileUnloadTimeLow', LowHigh.LowPart);

  if not Result.IsSuccess then
    Exit;

  Result := NtxQueryValueKeyUInt32(hxProfileListKey,
    'LocalProfileUnloadTimeHigh', LowHigh.HighPart);
end;

end.
