unit NtUtils.Profiles;

interface

uses
  Winapi.WinNt, NtUtils.Exceptions, NtUtils.Security.Sid, DelphiApi.Reflection;

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
  end;

{ User profiles }

// Enumerate existing profiles on the system
function UnvxEnumerateProfiles(out Profiles: TArray<ISid>): TNtxStatus;

// Enumerate loaded profiles on the system
function UnvxEnumerateLoadedProfiles(out Profiles: TArray<ISid>): TNtxStatus;

// Query profile information
function UnvxQueryProfile(Sid: PSid; out Info: TProfileInfo): TNtxStatus;

{ AppContainer profiles }

// Create an AppContainer profile
function UnvxCreateAppContainer(out Sid: ISid; AppContainerName, DisplayName,
  Description: String; Capabilities: TArray<TGroup> = nil): TNtxStatus;

// Delete an AppContainer profile
function UnvxDeleteAppContainer(AppContainerName: String): TNtxStatus;

// Query AppContainer information
function UnvxQueryAppContainer(UserSid: String; AppContainerSid: PSid;
  out Info: TAppContainerInfo): TNtxStatus;

// Query AppContainer folder location
function UnvxQueryFolderAppContainer(AppContainerSid: String;
  out Path: String): TNtxStatus;

// Enumerate AppContainer profiles
function UnvxEnumerateAppContainers(UserSid: String;
  out AppContainers: TArray<ISid>): TNtxStatus;

// Enumerate children of AppContainer profile
function UnvxEnumerateChildrenAppContainer(UserSid, AppContainerSid: String;
  out Children: TArray<ISid>): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntseapi, Winapi.UserEnv, Ntapi.ntstatus, Ntapi.ntregapi,
  NtUtils.Registry, NtUtils.Ldr, NtUtils.Objects, NtUtils.Security.AppContainer,
  DelphiUtils.Arrays;

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

function UnvxEnumerateProfiles(out Profiles: TArray<ISid>): TNtxStatus;
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
    TArrayHelper.Convert<String, ISid>(ProfileStrings, Profiles,
      RtlxStringToSidConverter);
end;

function UnvxEnumerateLoadedProfiles(out Profiles: TArray<ISid>): TNtxStatus;
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
    TArrayHelper.Convert<String, ISid>(ProfileStrings, Profiles,
      RtlxStringToSidConverter);
end;

function UnvxQueryProfile(Sid: PSid; out Info: TProfileInfo): TNtxStatus;
var
  hxKey: IHandle;
begin
  // Retrieve the information from the registry
  Result := NtxOpenKey(hxKey, PROFILE_PATH + '\' + RtlxConvertSidToString(Sid),
    KEY_QUERY_VALUE);

  if not Result.IsSuccess then
    Exit;

  FillChar(Result, SizeOf(Result), 0);

  // The only necessary value
  Result := NtxQueryStringValueKey(hxKey.Handle, 'ProfileImagePath',
    Info.ProfilePath);

  if Result.IsSuccess then
  begin
    NtxQueryDwordValueKey(hxKey.Handle, 'Flags', Info.Flags);
    NtxQueryDwordValueKey(hxKey.Handle, 'FullProfile', PCardinal(PLongBool(
      @Info.FullProfile))^);
  end;
end;

{ AppContainer profiles }

function UnvxCreateAppContainer(out Sid: ISid; AppContainerName, DisplayName,
  Description: String; Capabilities: TArray<TGroup>): TNtxStatus;
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
    CapArray[i].Sid := Capabilities[i].SecurityIdentifier.Sid;
    CapArray[i].Attributes := Capabilities[i].Attributes;
  end;

  Result.Location := 'CreateAppContainerProfile';
  Result.HResult := CreateAppContainerProfile(PWideChar(AppContainerName),
    PWideChar(DisplayName), PWideChar(Description), CapArray, Length(CapArray),
    Buffer);

  if Result.IsSuccess then
  begin
    Sid := TSid.CreateCopy(Buffer);
    RtlFreeSid(Buffer);
  end;
end;

function UnvxDeleteAppContainer(AppContainerName: String): TNtxStatus;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'DeleteAppContainerProfile');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DeleteAppContainerProfile';
  Result.HResult := DeleteAppContainerProfile(PWideChar(AppContainerName));
end;

function UnvxQueryFolderAppContainer(AppContainerSid: String;
  out Path: String): TNtxStatus;
var
  Buffer: PWideChar;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'GetAppContainerFolderPath');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetAppContainerFolderPath';
  Result.HResult := GetAppContainerFolderPath(PWideChar(AppContainerSid),
    Buffer);

  if Result.IsSuccess then
  begin
    Path := String(Buffer);
    CoTaskMemFree(Buffer);
  end;
end;

function RtlxpGetAppContainerRegPath(UserSid, AppContainerSid: String): String;
begin
  Result := REG_PATH_USER + '\' + UserSid + APPCONTAINER_MAPPING_PATH +
    '\' + AppContainerSid;
end;

function UnvxQueryAppContainer(UserSid: String; AppContainerSid: PSid;
  out Info: TAppContainerInfo): TNtxStatus;
var
  hxKey: IHandle;
  Parent: ISid;
begin
  // Read the AppContainer profile information from the registry

  // The path depends on whether it is a parent or a child
  Info.IsChild := (RtlxGetAppContainerType(AppContainerSid) =
    ChildAppContainerSidType);

  if Info.IsChild then
  begin
    Result := RtlxGetAppContainerParent(AppContainerSid, Parent);

    // For child AppContainers the path contains both a user and a parent:
    //  HKU\<user>\...\<parent>\Children\<app-container>

    if Result.IsSuccess then
      Result := NtxOpenKey(hxKey, RtlxpGetAppContainerRegPath(UserSid,
        RtlxConvertSidToString(Parent.Sid)) + APPCONTAINER_CHILDREN + '\' +
        RtlxConvertSidToString(AppContainerSid), KEY_QUERY_VALUE);

    // Parent's name (aka parent moniker)
    if Result.IsSuccess then
      Result := NtxQueryStringValueKey(hxKey.Handle, APPCONTAINER_PARENT_NAME,
        Info.ParentName);
  end
  else
    Result := NtxOpenKey(hxKey, RtlxpGetAppContainerRegPath(UserSid,
      RtlxConvertSidToString(AppContainerSid)), KEY_QUERY_VALUE);

  if not Result.IsSuccess then
    Exit;

  // Name (aka moniker)
  Result := NtxQueryStringValueKey(hxKey.Handle, APPCONTAINER_NAME, Info.Name);

  if not Result.IsSuccess then
    Exit;

  // DisplayName
  Result := NtxQueryStringValueKey(hxKey.Handle, APPCONTAINER_DISPLAY_NAME,
    Info.DisplayName);
end;

function UnvxEnumerateAppContainers(UserSid: String;
  out AppContainers: TArray<ISid>): TNtxStatus;
var
  hxKey: IHandle;
  AppContainerStrings: TArray<String>;
begin
  // All registered AppContainers are stored as registry keys

  Result := NtxOpenKey(hxKey, REG_PATH_USER + '\' + UserSid +
    APPCONTAINER_MAPPING_PATH, KEY_ENUMERATE_SUB_KEYS);

  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, AppContainerStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    TArrayHelper.Convert<String, ISid>(AppContainerStrings, AppContainers,
      RtlxStringToSidConverter);
end;

function UnvxEnumerateChildrenAppContainer(UserSid, AppContainerSid: String;
  out Children: TArray<ISid>): TNtxStatus;
var
  hxKey: IHandle;
  ChildrenStrings: TArray<String>;
begin
  // All registered children are stored as subkeys of a parent profile

  Result := NtxOpenKey(hxKey, RtlxpGetAppContainerRegPath(UserSid,
    AppContainerSid) + APPCONTAINER_CHILDREN, KEY_ENUMERATE_SUB_KEYS);

  if Result.IsSuccess then
    Result := NtxEnumerateSubKeys(hxKey.Handle, ChildrenStrings);

  // Convert strings to SIDs ignoring irrelevant entries
  if Result.IsSuccess then
    TArrayHelper.Convert<String, ISid>(ChildrenStrings, Children,
      RtlxStringToSidConverter);
end;

end.
