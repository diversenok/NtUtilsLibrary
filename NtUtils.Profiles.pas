unit NtUtils.Profiles;

{
  The module provides support for working with normal (user) and AppContainer
  profiles.
}

interface

uses
  Winapi.WinNt, NtUtils, DelphiApi.Reflection;

type
  TProfileInfo = record
    [Hex] Flags: Cardinal;
    FullProfile: LongBool;
    ProfilePath: String;
  end;

  TAppContainerInfo = record
    Name: String;
    DisplayName: String;
    IsChild: Boolean;
    ParentName: String;
    function FullName: String;
  end;

{ User profiles }

// Load a profile using a token
function UnvxLoadProfile(
  out hxKey: IHandle;
  hToken: THandle
): TNtxStatus;

// Unload a profile using a token
function UnvxUnloadProfile(
  hToken: THandle;
  hProfile: THandle
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
  [in] Sid: PSid;
  out Info: TProfileInfo
): TNtxStatus;

{ AppContainer profiles }

// Create an AppContainer profile
function UnvxCreateAppContainer(
  out Sid: ISid;
  const AppContainerName: String;
  [opt] DisplayName: String = '';
  [opt] Description: String = '';
  [opt] const Capabilities: TArray<TGroup> = nil
): TNtxStatus;

// Create an AppContainer profile or open an existing one
function UnvxCreateDeriveAppContainer(
  out Sid: ISid;
  const AppContainerName: String;
  [opt] const DisplayName: String = '';
  [opt] const Description: String = '';
  [opt] const Capabilities: TArray<TGroup> = nil
): TNtxStatus;

// Delete an AppContainer profile
function UnvxDeleteAppContainer(
  const AppContainerName: String
): TNtxStatus;

// Query AppContainer information
function UnvxQueryAppContainer(
  out Info: TAppContainerInfo;
  [in] AppContainer: PSid;
  [in, opt] User: PSid = nil
): TNtxStatus;

// Get a name or an SID of an AppContainer
function UnvxAppContainerToString(
  [in] AppContainer: PSid;
  [in, opt] User: PSid = nil
): String;

// Query AppContainer folder location
function UnvxQueryFolderAppContainer(
  [in] AppContainerSid: PSid;
  out Path: String
): TNtxStatus;

// Enumerate AppContainer profiles
function UnvxEnumerateAppContainers(
  out AppContainers: TArray<ISid>;
  [in, opt] User: PSid = nil
): TNtxStatus;

// Enumerate children of AppContainer profile
function UnvxEnumerateChildrenAppContainer(
  out Children: TArray<ISid>;
  [in] AppContainer: PSid;
  [in, opt] User: PSid = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntregapi, Ntapi.ntseapi, Ntapi.ntdef, Winapi.UserEnv, Ntapi.ntstatus,
  Ntapi.ntrtl, Winapi.WinError, NtUtils.Registry, NtUtils.Errors, NtUtils.Ldr,
  NtUtils.Security.AppContainer, DelphiUtils.Arrays, NtUtils.Security.Sid,
  NtUtils.Registry.HKCU, NtUtils.Objects, NtUtils.Tokens.Query, NtUtils.Lsa.Sid;

const
  PROFILE_PATH = REG_PATH_MACHINE + '\SOFTWARE\Microsoft\Windows NT\' +
    'CurrentVersion\ProfileList';

  APPCONTAINER_MAPPING_PATH = '\Software\Classes\Local Settings\Software\' +
    'Microsoft\Windows\CurrentVersion\AppContainer\Mappings';
  APPCONTAINER_NAME = 'Moniker';
  APPCONTAINER_PARENT_NAME = 'ParentMoniker';
  APPCONTAINER_DISPLAY_NAME = 'DisplayName';
  APPCONTAINER_CHILDREN = '\Children';

{ User profiles }

function UnvxLoadProfile;
var
  Sid: ISid;
  UserName: String;
  Profile: TProfileInfoW;
begin
  // Determine the SID
  Result := NtxQuerySidToken(hToken, TokenUser, Sid);

  if not Result.IsSuccess then
    Exit;

  UserName := LsaxSidToString(Sid.Data);

  FillChar(Profile, SizeOf(Profile), 0);
  Profile.Size := SizeOf(Profile);
  Profile.UserName := PWideChar(UserName);

  Result.Location := 'LoadUserProfileW';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_QUERY or TOKEN_IMPERSONATE or
    TOKEN_DUPLICATE);

  Result.Win32Result := LoadUserProfileW(hToken, Profile);

  if Result.IsSuccess then
     hxKey := TAutoHandle.Capture(Profile.hProfile);
end;

function UnvxUnloadProfile;
begin
  Result.Location := 'UnloadUserProfile';
  Result.Win32Result := UnloadUserProfile(hToken, hProfile);
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
  // Retrieve the information from the registry
  Result := NtxOpenKey(hxKey, PROFILE_PATH + '\' + RtlxSidToString(Sid),
    KEY_QUERY_VALUE);

  if not Result.IsSuccess then
    Exit;

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
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'CreateAppContainerProfile');

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

  if Result.IsSuccess then
  begin
    Result := RtlxCopySid(Buffer, Sid);
    RtlFreeSid(Buffer);
  end;
end;

function UnvxCreateDeriveAppContainer;
begin
  Result := UnvxCreateAppContainer(Sid, AppContainerName, DisplayName,
    Description, Capabilities);

  if Result.Matches(TWin32Error(ERROR_ALREADY_EXISTS).ToNtStatus,
    'CreateAppContainerProfile') then
    Result := RtlxAppContainerNameToSid(AppContainerName, Sid);
end;

function UnvxDeleteAppContainer;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'DeleteAppContainerProfile');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DeleteAppContainerProfile';
  Result.HResult := DeleteAppContainerProfile(PWideChar(AppContainerName));
end;

function UnvxQueryFolderAppContainer;
var
  Buffer: PWideChar;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'GetAppContainerFolderPath');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetAppContainerFolderPath';
  Result.HResult := GetAppContainerFolderPath(PWideChar(RtlxSidToString(
    AppContainerSid)), Buffer);

  if Result.IsSuccess then
  begin
    Path := String(Buffer);
    CoTaskMemFree(Buffer);
  end;
end;

// Functions with custom implementation

function RtlxpAppContainerRegPath(
  [in, opt] User: PSid;
  [in] AppContainer: PSid;
  out Path: String
): TNtxStatus;
begin
  if not Assigned(User) then
  begin
    // Use HKCU of the effective user
    Result := RtlxFormatUserKeyPath(Path, NtCurrentEffectiveToken);

    if not Result.IsSuccess then
      Exit;
  end
  else
  begin
    Result.Status := STATUS_SUCCESS;
    Path := REG_PATH_USER + '\' + RtlxSidToString(User);
  end;

  Path := Path + APPCONTAINER_MAPPING_PATH;

  if Assigned(AppContainer) then
    Path := Path + '\' + RtlxSidToString(AppContainer);
end;

function UnvxQueryAppContainer;
var
  hxKey: IHandle;
  Parent: ISid;
  Path: String;
begin
  // Read the AppContainer profile information from the registry

  // The path depends on whether it is a parent or a child
  Info.IsChild := (RtlxAppContainerType(AppContainer) =
    ChildAppContainerSidType);

  if Info.IsChild then
  begin
    Result := RtlxAppContainerParent(AppContainer, Parent);

    // For child AppContainers, the path contains both the child's and the
    // parent'd SIDs: HKU\<user>\...\<parent>\Children\<app-container>

    // Prepare the parent part
    if Result.IsSuccess then
      Result := RtlxpAppContainerRegPath(User, Parent.Data, Path);

    if Result.IsSuccess then
    begin
      // Append the child part
      Path := Path + '\' + APPCONTAINER_CHILDREN + '\' +
        RtlxSidToString(AppContainer);

      Result := NtxOpenKey(hxKey, Path, KEY_QUERY_VALUE);
    end;

    // Get parent's name (aka parent moniker)
    if Result.IsSuccess then
      Result := NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_PARENT_NAME,
        Info.ParentName);
  end
  else
  begin
    Result := RtlxpAppContainerRegPath(User, AppContainer, Path);

    if Result.IsSuccess then
      Result := NtxOpenKey(hxKey, Path, KEY_QUERY_VALUE);
  end;

  if not Result.IsSuccess then
    Exit;

  // Get the name (aka moniker)
  Result := NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_NAME, Info.Name);

  if not Result.IsSuccess then
    Exit;

  // Get the Display Name
  Result := NtxQueryValueKeyString(hxKey.Handle, APPCONTAINER_DISPLAY_NAME,
    Info.DisplayName);
end;

function UnvxAppContainerToString;
var
  Info: TAppContainerInfo;
begin
  if UnvxQueryAppContainer(Info, AppContainer, User).IsSuccess then
    Result := Info.FullName
  else
    Result := RtlxSidToString(AppContainer);
end;

function UnvxEnumerateAppContainers;
var
  hxKey: IHandle;
  Path: String;
  AppContainerStrings: TArray<String>;
begin
  // All registered AppContainers are stored as registry keys

  Result := RtlxpAppContainerRegPath(User, nil, Path);

  if Result.IsSuccess then
    Result := NtxOpenKey(hxKey, Path, KEY_ENUMERATE_SUB_KEYS);

  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, AppContainerStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    AppContainers := TArray.Convert<String, ISid>(AppContainerStrings,
      RtlxStringToSidConverter);
end;

function UnvxEnumerateChildrenAppContainer;
var
  hxKey: IHandle;
  Path: String;
  ChildrenStrings: TArray<String>;
begin
  // All registered children are stored as subkeys of a parent profile

  Result := RtlxpAppContainerRegPath(User, AppContainer, Path);

  if Result.IsSuccess then
    Result := NtxOpenKey(hxKey, Path + APPCONTAINER_CHILDREN,
      KEY_ENUMERATE_SUB_KEYS);

  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, ChildrenStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    Children := TArray.Convert<String, ISid>(ChildrenStrings,
      RtlxStringToSidConverter);
end;

{ TAppContainerInfo }

function TAppContainerInfo.FullName;
begin
  Result := Name;

  if IsChild then
    Result := ParentName + '/' + Result;
end;

end.
