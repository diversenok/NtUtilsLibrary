unit NtUtils.Profiles;

interface

uses
  Winapi.WinNt, NtUtils.Exceptions, NtUtils.Security.Sid;

type
  TAppContainerInfo = record
    Name: String;
    DisplayName: String;
    IsChild: Boolean;
    ParentName: String;
  end;

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
  out AppContainers: TArray<String>): TNtxStatus;

// Enumerate children of AppContainer profile
function UnvxEnumerateChildrenAppContainer(UserSid: String;
  AppContainerSid: PSid; out Children: TArray<String>): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, Winapi.UserEnv, Ntapi.ntstatus, Ntapi.ntregapi, NtUtils.Registry,
  NtUtils.Ldr, NtUtils.Objects, NtUtils.Security.AppContainer;

const
  APPCONTAINER_MAPPING_PATH = '\Software\Classes\Local Settings\Software\' +
    'Microsoft\Windows\CurrentVersion\AppContainer\Mappings';
  APPCONTAINER_NAME = 'Moniker';
  APPCONTAINER_PARENT_NAME = 'ParentMoniker';
  APPCONTAINER_DISPLAY_NAME = 'DisplayName';
  APPCONTAINER_CHILDREN = '\Children';

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

function RtlxpGetAppContainerPath(UserSid: String; AppContainerSid: PSid)
  : String;
begin
  Result := REG_PATH_USER + '\' + UserSid + APPCONTAINER_MAPPING_PATH +
    '\' + RtlxConvertSidToString(AppContainerSid);
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
      Result := NtxOpenKey(hxKey, RtlxpGetAppContainerPath(UserSid,
        Parent.Sid) + APPCONTAINER_CHILDREN + '\' +
        RtlxConvertSidToString(AppContainerSid), KEY_QUERY_VALUE);

    // Parent's name (aka parent moniker)
    if Result.IsSuccess then
      Result := NtxQueryStringValueKey(hxKey.Value, APPCONTAINER_PARENT_NAME,
        Info.ParentName);
  end
  else
    Result := NtxOpenKey(hxKey, RtlxpGetAppContainerPath(UserSid,
      AppContainerSid), KEY_QUERY_VALUE);

  if not Result.IsSuccess then
    Exit;

  // Name (aka moniker)
  Result := NtxQueryStringValueKey(hxKey.Value, APPCONTAINER_NAME, Info.Name);

  if not Result.IsSuccess then
    Exit;

  // DisplayName
  Result := NtxQueryStringValueKey(hxKey.Value, APPCONTAINER_DISPLAY_NAME,
    Info.DisplayName);
end;

function UnvxEnumerateAppContainers(UserSid: String;
  out AppContainers: TArray<String>): TNtxStatus;
var
  hxKey: IHandle;
begin
  // All registered AppContainers are stored as registry keys

  Result := NtxOpenKey(hxKey, REG_PATH_USER + '\' + UserSid +
    APPCONTAINER_MAPPING_PATH, KEY_ENUMERATE_SUB_KEYS);

  if not Result.IsSuccess then
    Exit;

  Result := NtxEnumerateSubKeys(hxKey.Value, AppContainers);
end;

function UnvxEnumerateChildrenAppContainer(UserSid: String;
  AppContainerSid: PSid; out Children: TArray<String>): TNtxStatus;
var
  hxKey: IHandle;
begin
  // All registered children are stored as subkeys of a parent profile

  Result := NtxOpenKey(hxKey, RtlxpGetAppContainerPath(UserSid,
    AppContainerSid) + APPCONTAINER_CHILDREN, KEY_ENUMERATE_SUB_KEYS);

  if not Result.IsSuccess then
    Exit;

  Result := NtxEnumerateSubKeys(hxKey.Value, Children);
end;

end.
