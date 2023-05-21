unit NtUtils.Profiles;

{
  The module provides support for working with normal (user) and AppContainer
  profiles.
}

interface

uses
  Ntapi.UserEnv, Ntapi.ntseapi, NtUtils, Ntapi.Versions, DelphiApi.Reflection;

type
  TProfileInfo = record
    [Hex] Flags: Cardinal;
    FullProfile: LongBool;
    ProfilePath: String;
    User: ISid;
  end;

{ User profiles }

// Load a profile using a token
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnvxLoadProfile(
  out hxKey: IHandle;
  [Access(TOKEN_LOAD_PROFILE)] hxToken: IHandle
): TNtxStatus;

// Unload a profile using a token
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnvxUnloadProfile(
  [Access(0)] hProfileKey: THandle;
  [Access(TOKEN_LOAD_PROFILE)] hxToken: IHandle
): TNtxStatus;

// Enumerate existing profiles on the system
function UnvxEnumerateProfiles(
  out Profiles: TArray<ISid>
): TNtxStatus;

// Enumerate loaded profiles on the system
function UnvxEnumerateLoadedProfiles(
  out Profiles: TArray<ISid>
): TNtxStatus;

// Query profile information
function UnvxQueryProfile(
  const Sid: ISid;
  out Info: TProfileInfo
): TNtxStatus;

{ AppContainer profiles }

// Create an AppContainer profile.
// NOTE: when called within an AppContainer context, the function returns a
// child AppContainer SIDs
[MinOSVersion(OsWin8)]
function UnvxCreateAppContainer(
  out Sid: ISid;
  const AppContainerName: String;
  [opt] DisplayName: String = '';
  [opt] Description: String = '';
  [opt] const Capabilities: TArray<TGroup> = nil
): TNtxStatus;

// Constrct a SID of an AppContainer profile.
// NOTE: when called within an AppContainer context, the function returns a
// child AppContainer SIDs
[MinOSVersion(OsWin8)]
function UnvxDeriveAppContainer(
  out Sid: ISid;
  const AppContainerName: String
): TNtxStatus;

// Create an AppContainer profile or open an existing one.
// NOTE: when called within an AppContainer context, the function returns a
// child AppContainer SIDs
[MinOSVersion(OsWin8)]
function UnvxCreateDeriveAppContainer(
  out Sid: ISid;
  const AppContainerName: String;
  [opt] const DisplayName: String = '';
  [opt] const Description: String = '';
  [opt] const Capabilities: TArray<TGroup> = nil
): TNtxStatus;

// Delete an AppContainer profile.
// NOTE: when called within an AppContainer context, the function deletes a
// child AppContainer.
[MinOSVersion(OsWin8)]
function UnvxDeleteAppContainer(
  const AppContainerName: String
): TNtxStatus;

// Query AppContainer folder location
[MinOSVersion(OsWin8)]
function UnvxQueryFolderAppContainer(
  const AppContainerSid: ISid;
  out Path: String
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntregapi, Ntapi.ntdef, Ntapi.WinError, Ntapi.ObjBase,
  NtUtils.Registry, NtUtils.Errors, NtUtils.Ldr, NtUtils.Tokens,
  DelphiUtils.Arrays, NtUtils.Security.Sid, NtUtils.Security.AppContainer,
  NtUtils.Objects, NtUtils.Tokens.Info, NtUtils.Lsa.Sid;

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
  // Expand pseudo-handles
  Result := NtxExpandToken(hxToken, TOKEN_LOAD_PROFILE);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'UnloadUserProfile';
  Result.LastCall.ExpectedPrivilege := SE_RESTORE_PRIVILEGE;
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_LOAD_PROFILE);

  Result.Win32Result := UnloadUserProfile(hxToken.Handle, hProfileKey);
end;

function UnvxEnumerateProfiles;
var
  hxKey: IHandle;
  ProfileStrings: TArray<String>;
begin
  // Lookup the profile list in the registry
  Result := NtxOpenKey(hxKey, PROFILE_PATH, KEY_ENUMERATE_SUB_KEYS);

  // Each sub-key is a profile SID
  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, ProfileStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    Profiles := TArray.Convert<String, ISid>(ProfileStrings,
      RtlxStringToSidConverter);
end;

function UnvxEnumerateLoadedProfiles;
var
  hxKey: IHandle;
  ProfileStrings: TArray<String>;
begin
  // Each loaded profile is a sub-key in HKU
  Result := NtxOpenKey(hxKey, REG_PATH_USER, KEY_ENUMERATE_SUB_KEYS);

  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, ProfileStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    Profiles := TArray.Convert<String, ISid>(ProfileStrings,
      RtlxStringToSidConverter);
end;

function UnvxQueryProfile;
var
  hxKey: IHandle;
begin
  Info := Default(TProfileInfo);
  Info.User := Sid;

  // Retrieve the information from the registry
  Result := NtxOpenKey(hxKey, PROFILE_PATH + '\' + RtlxSidToString(Sid),
    KEY_QUERY_VALUE);

  if not Result.IsSuccess then
    Exit;

  Info := Default(TProfileInfo);

  // The only necessary value
  Result := NtxQueryValueKeyString(hxKey.Handle, 'ProfileImagePath',
    Info.ProfilePath);

  if Result.IsSuccess then
  begin
    NtxQueryValueKeyUInt(hxKey.Handle, 'Flags', Info.Flags);
    NtxQueryValueKeyUInt(hxKey.Handle, 'FullProfile',
      Cardinal(Info.FullProfile));
  end;
end;

{ AppContainer profiles }

function UnvxCreateAppContainer;
var
  CapArray: TArray<TSidAndAttributes>;
  i: Integer;
  Buffer: PSid;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_userenv,
    delayed_CreateAppContainerProfile);

  if not Result.IsSuccess then
    Exit;

  SetLength(CapArray, Length(Capabilities));

  for i := 0 to High(CapArray) do
  begin
    CapArray[i].Sid := Capabilities[i].Sid.Data;
    CapArray[i].Attributes := Capabilities[i].Attributes;
  end;

  // The function does not like empty strings
  if DisplayName = '' then
    DisplayName := AppContainerName;

  if Description = '' then
    Description := DisplayName;

  Result.Location := 'CreateAppContainerProfile';
  Result.HResult := CreateAppContainerProfile(PWideChar(AppContainerName),
    PWideChar(DisplayName), PWideChar(Description), CapArray, Length(CapArray),
    Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := RtlxDelayFreeSid(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
end;

function UnvxDeriveAppContainer;
var
  ParentSid: ISid;
begin
  // Determine if we need a parent or a child AppContainer
  Result := NtxQuerySidToken(NtxCurrentEffectiveToken, TokenAppContainerSid,
    ParentSid);

  if not Result.IsSuccess then
    Exit;

  // Construct one
  if Assigned(ParentSid) then
    Result := RtlxDeriveChildAppContainerSid(ParentSid, AppContainerName, Sid)
  else
    Result := RtlxDeriveParentAppContainerSid(AppContainerName, Sid)
end;

function UnvxCreateDeriveAppContainer;
begin
  Result := UnvxCreateAppContainer(Sid, AppContainerName, DisplayName,
    Description, Capabilities);

  if Result.Matches(TWin32Error(ERROR_ALREADY_EXISTS).ToNtStatus,
    'CreateAppContainerProfile') then
    Result := UnvxDeriveAppContainer(Sid, AppContainerName);
end;

function UnvxDeleteAppContainer;
begin
  Result := LdrxCheckDelayedImport(delayed_userenv,
    delayed_DeleteAppContainerProfile);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DeleteAppContainerProfile';
  Result.HResult := DeleteAppContainerProfile(PWideChar(AppContainerName));
end;

function UnvxDelayCoTaskMemFree(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      CoTaskMemFree(Buffer);
    end
  );
end;

function UnvxQueryFolderAppContainer;
var
  Buffer: PWideChar;
  BufferDeallocator: IAutoReleasable;
begin
  Result := LdrxCheckDelayedImport(delayed_userenv,
    delayed_GetAppContainerFolderPath);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetAppContainerFolderPath';
  Result.HResult := GetAppContainerFolderPath(PWideChar(RtlxSidToString(
    AppContainerSid)), Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := UnvxDelayCoTaskMemFree(Buffer);
  Path := String(Buffer);
end;

end.
