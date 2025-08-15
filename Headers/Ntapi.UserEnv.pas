unit Ntapi.UserEnv;

{
  This file defines functions for working with user and AppContainer profiles.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.ntregapi, Ntapi.Versions,
  DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  userenv = 'userenv.dll';
  profapi = 'profapi.dll';
  profext = 'profext.dll';
  firewallapi = 'FirewallAPI.dll';

var
  delayed_userenv: TDelayedLoadDll = (DllName: userenv);
  delayed_profapi: TDelayedLoadDll = (DllName: profapi);
  delayed_profext: TDelayedLoadDll = (DllName: profext);
  delayed_firewallapi: TDelayedLoadDll = (DllName: firewallapi);

const
  // SDK::UserEnv.h - profile type
  PT_TEMPORARY = $00000001;
  PT_ROAMING = $00000002;
  PT_MANDATORY = $00000004;
  PT_ROAMING_PREEXISTING = $00000008;

  // SDK::UserEnv.h - profile flags
  PI_NOUI = $00000001;
  PI_APPLYPOLICY = $00000002;
  PI_LITELOAD = $00000004; // private
  PI_HIDEPROFILE = $00000008; // private

  // private - profile state (aka. internal flags)
  PROFILE_MANDATORY = $00000001;
  PROFILE_USE_CACHE = $00000002;
  PROFILE_NEW_LOCAL = $00000004;
  PROFILE_NEW_CENTRAL = $00000008;
  PROFILE_UPDATE_CENTRAL = $00000010;
  PROFILE_DELETE_CACHE = $00000020;
  PROFILE_GUEST_USER = $00000080;
  PROFILE_ADMIN_USER = $00000100;
  DEFAULT_NET_READY = $00000200;
  PROFILE_SLOW_LINK = $00000400;
  PROFILE_TEMP_ASSIGNED = $00000800;
  PROFILE_PARTLY_LOADED = $00002000;
  PROFILE_BACKUP_EXISTS = $00004000;
  PROFILE_THIS_IS_BAK = $00008000;
  PROFILE_READONLY = $00010000;
  PROFILE_LOCALMANDATORY = $00020000;

  // For annotations
  TOKEN_LOAD_PROFILE = TOKEN_QUERY or TOKEN_IMPERSONATE or TOKEN_DUPLICATE;

  // SDK::netfw.h
  NETISO_FLAG_FORCE_COMPUTE_BINARIES = $01;
  NETISO_FLAG_REPORT_INCLUDE_CHILD_AC = $02; // private

type
  [FlagName(PT_TEMPORARY, 'Temporary')]
  [FlagName(PT_ROAMING, 'Roaming')]
  [FlagName(PT_MANDATORY, 'Mandatory')]
  [FlagName(PT_ROAMING_PREEXISTING, 'Roaming Pre-existing')]
  TProfileType = type Cardinal;

  [FlagName(PI_NOUI, 'No UI')]
  [FlagName(PI_APPLYPOLICY, 'Apply Policy')]
  [FlagName(PI_LITELOAD, 'Lite Load')]
  [FlagName(PI_HIDEPROFILE, 'Hide Profile')]
  TProfileFlags = type Cardinal;

  [FlagName(PROFILE_MANDATORY, 'Mandatory')]
  [FlagName(PROFILE_USE_CACHE, 'Use Cache')]
  [FlagName(PROFILE_NEW_LOCAL, 'New Local')]
  [FlagName(PROFILE_NEW_CENTRAL, 'New Central')]
  [FlagName(PROFILE_UPDATE_CENTRAL, 'Update Central')]
  [FlagName(PROFILE_DELETE_CACHE, 'Delete Cache')]
  [FlagName(PROFILE_GUEST_USER, 'Guest User')]
  [FlagName(PROFILE_ADMIN_USER, 'Admin User')]
  [FlagName(DEFAULT_NET_READY, 'Net Ready')]
  [FlagName(PROFILE_SLOW_LINK, 'Slow Link')]
  [FlagName(PROFILE_TEMP_ASSIGNED, 'Temp Assigned')]
  [FlagName(PROFILE_PARTLY_LOADED, 'Partly Loaded')]
  [FlagName(PROFILE_BACKUP_EXISTS, 'Backup Exists')]
  [FlagName(PROFILE_THIS_IS_BAK, 'BAK')]
  [FlagName(PROFILE_READONLY, 'Read-only')]
  [FlagName(PROFILE_LOCALMANDATORY, 'Local Mandatory')]
  TProfileInternalFlags = type Cardinal;

  // SDK::ProfInfo.h
  [SDKName('PROFILEINFOW')]
  TProfileInfoW = record
    [RecordSize] Size: Cardinal;
    Flags: TProfileFlags;
    UserName: PWideChar;
    ProfilePath: PWideChar;
    DefaultPath: PWideChar;
    ServerName: PWideChar;
    PolicyPath: PWideChar;
    hProfile: THandle;
  end;
  PProfileInfoW = ^TProfileInfoW;

  // private
  [SDKName('PROFILE_FOLDER_ID')]
  [NamingStyle(nsSnakeCase, 'FOLDER'), MinValue(1)]
  TProfileFolderId = (
    [Reserved] FOLDER_UNUSED = 0,
    FOLDER_USERS = 1,
    FOLDER_DEFAULT = 2,
    FOLDER_PUBLIC = 3,
    FOLDER_PROGRAM_DATA = 4,
    FOLDER_USER_PROFILE = 5,
    FOLDER_LOCAL_APPDATA = 6,
    FOLDER_ROAMING_APPDATA = 7,
    FOLDER_LOCAL_APPDATA_NO_APPCONTAINER_REDIRECT = 8 // Win 8+
  );

  // private
  [SDKName('APP_CONTAINER_PROFILE_TYPE')]
  [NamingStyle(nsSnakeCase, 'APP_CONTAINER_PROFILE_TYPE')]
  TAppContainerProfileType = (
    APP_CONTAINER_PROFILE_TYPE_WIN32 = 0,
    APP_CONTAINER_PROFILE_TYPE_APPX = 1,
    APP_CONTAINER_PROFILE_TYPE_XAP = 2,
    APP_CONTAINER_PROFILE_TYPE_APPX_FRAMEWORK = 3
  );

  [SDKName('NETISO_FLAG')]
  [FlagName(NETISO_FLAG_FORCE_COMPUTE_BINARIES, 'Force Compute Binaries')]
  [FlagName(NETISO_FLAG_REPORT_INCLUDE_CHILD_AC, 'Include Child AppContainer')]
  TNetIsoFlags = type Cardinal;

  // SDK::netfw.h
  [SDKName('INET_FIREWALL_AC_CAPABILITIES')]
  TInetFirewallAcCapabilities = record
    [NumberOfElements] Count: Integer;
    Capabilities: PSidAndAttributes;
  end;
  PInetFirewallAcCapabilities = ^TInetFirewallAcCapabilities;

  // SDK::netfw.h
  [SDKName('INET_FIREWALL_AC_BINARIES')]
  TInetFirewallAcBinaries = record
    [NumberOfElements] Count: Integer;
    Binaries: PPWideChar;
  end;
  PInetFirewallAcBinaries = ^TInetFirewallAcBinaries;

  // SDK::netfw.h
  [SDKName('INET_FIREWALL_APP_CONTAINER')]
  TInetFirewallAppContainer = record
    AppContainerSid: PSid;
    UserSid: PSid;
    AppContainerName: PWideChar;
    DisplayName: PWideChar;
    Description: PWideChar;
    Capabilities: TInetFirewallAcCapabilities;
    Binaries: TInetFirewallAcBinaries;
    WorkingDirectory: PWideChar;
    PackageFullName: PWideChar;
  end;
  PInetFirewallAppContainer = ^TInetFirewallAppContainer;
  TInetFirewallAppContainerArray = TAnysizeArray<TInetFirewallAppContainer>;
  PInetFirewallAppContainerArray = ^TInetFirewallAppContainerArray;

// SDK::UserEnv.h
[SetsLastError]
[Result: ReleaseWith('UnloadUserProfile')]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function LoadUserProfileW(
  [in, Access(TOKEN_LOAD_PROFILE)] hToken: THandle;
  [in, out] var ProfileInfo: TProfileInfoW
): LongBool; stdcall; external userenv delayed;

var delayed_LoadUserProfileW: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'LoadUserProfileW';
);

// SDK::UserEnv.h
[SetsLastError]
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnloadUserProfile(
  [in, Access(TOKEN_LOAD_PROFILE)] hToken: THandle;
  [in] hProfile: THandle
): LongBool; stdcall; external userenv delayed;

var delayed_UnloadUserProfile: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'UnloadUserProfile';
);

// private
function GetBasicProfileFolderPath(
  [in] FolderID: TProfileFolderId;
  [in, opt] UserSid: PWideChar;
  [out, WritesTo] Path: PWideChar;
  [in, NumberOfElements] cchPath: Cardinal
): HResult; stdcall; external profapi index 104 delayed;

var delayed_GetBasicProfileFolderPath: TDelayedLoadFunction = (
  Dll: @delayed_profapi;
  FunctionName: MAKEINTRESOURCEA(104);
);

// SDK::UserEnv.h
[SetsLastError]
function GetProfileType(
  [out] out Flags: TProfileType
): LongBool; stdcall; external userenv delayed;

var delayed_GetProfileType: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'GetProfileType';
);

// SDK::UserEnv.h
[SetsLastError]
function CreateEnvironmentBlock(
  [out, ReleaseWith('RtlDestroyEnvironment')] out Environment: PEnvironment;
  [in, opt] hToken: THandle;
  [in] bInherit: LongBool
): LongBool; stdcall; external userenv delayed;

var delayed_CreateEnvironmentBlock: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'CreateEnvironmentBlock';
);

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
[Result: ReleaseWith('DeleteAppContainerProfile')]
function CreateAppContainerProfile(
  [in] AppContainerName: PWideChar;
  [in] DisplayName: PWideChar;
  [in] Description: PWideChar;
  [in, opt, ReadsFrom] const Capabilities: TArray<TSidAndAttributes>;
  [in, opt, NumberOfElements] CapabilityCount: Integer;
  [out, ReleaseWith('RtlFreeSid')] out SidAppContainerSid: PSid
): HResult; stdcall; external userenv delayed;

var delayed_CreateAppContainerProfile: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'CreateAppContainerProfile';
);

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function DeleteAppContainerProfile(
  [in] AppContainerName: PWideChar
): HResult; stdcall; external userenv delayed;

var delayed_DeleteAppContainerProfile: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'DeleteAppContainerProfile';
);

// private
[MinOSVersion(OsWin8)]
[Result: ReleaseWith('DeleteAppContainerProfileWorker')]
function CreateAppContainerProfileWorker(
  [in] AppContainerName: PWideChar;
  [in] DisplayName: PWideChar;
  [in] Description: PWideChar;
  [in, opt, ReadsFrom] const Capabilities: TArray<TSidAndAttributes>;
  [in, NumberOfElements] CapabilityCount: Cardinal;
  [in] ProfileType: TAppContainerProfileType;
  [out, ReleaseWith('RtlFreeSid')] out SidAppContainerSid: PSid
): HResult; stdcall; external profext delayed;

var delayed_CreateAppContainerProfileWorker: TDelayedLoadFunction = (
  Dll: @delayed_profext;
  FunctionName: 'CreateAppContainerProfileWorker';
);

// private
[MinOSVersion(OsWin8)]
function DeleteAppContainerProfileWorker(
  [in] AppContainerName: PWideChar;
  [in] ProfileType: TAppContainerProfileType
): HResult; stdcall; external profext delayed;

var delayed_DeleteAppContainerProfileWorker: TDelayedLoadFunction = (
  Dll: @delayed_profext;
  FunctionName: 'DeleteAppContainerProfileWorker';
);

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function GetAppContainerFolderPath(
  [in] AppContainerSid: PWideChar;
  [out, ReleaseWith('CoTaskMemFree')] out Path: PWideChar
): HResult; stdcall; external userenv delayed;

var delayed_GetAppContainerFolderPath: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'GetAppContainerFolderPath';
);

// private
[MinOSVersion(OsWin10TH1)]
function GetAppContainerPathFromSidString(
  [in] UserSid: PWideChar;
  [in] AppContainerSid: PWideChar;
  [out, WritesTo] FolderPath: PWideChar;
  [in, NumberOfElements] cchFolderPath: Cardinal
): HResult; stdcall; external profapi index 115 delayed;

var delayed_GetAppContainerPathFromSidString: TDelayedLoadFunction = (
  Dll: @delayed_profapi;
  FunctionName: MAKEINTRESOURCEA(115);
);

// MSDN
[MinOSVersion(OsWin8)]
function AppContainerDeriveSidFromMoniker(
  [in] Moniker: PWideChar;
  [out, ReleaseWith('RtlFreeSid')] out AppContainerSid: PSid
): HResult; stdcall; external kernelbase delayed;

var delayed_AppContainerDeriveSidFromMoniker: TDelayedLoadFunction = (
  Dll: @delayed_kernelbase;
  FunctionName: 'AppContainerDeriveSidFromMoniker';
);

// rev
[MinOSVersion(OsWin8)]
function AppContainerFreeMemory(
  [in] Memory: Pointer
): Boolean; stdcall; external kernelbase delayed;

var delayed_AppContainerFreeMemory: TDelayedLoadFunction = (
  Dll: @delayed_kernelbase;
  FunctionName: 'AppContainerFreeMemory';
);

// rev
[MinOSVersion(OsWin8)]
function AppContainerLookupMoniker(
  [in] AppContainerSid: PSid;
  [out, ReleaseWith('AppContainerFreeMemory')] out Moniker: PWideChar
): HResult; stdcall; external kernelbase delayed;

var delayed_AppContainerLookupMoniker: TDelayedLoadFunction = (
  Dll: @delayed_kernelbase;
  FunctionName: 'AppContainerLookupMoniker';
);

// rev
[MinOSVersion(OsWin8)]
function AppContainerLookupDisplayNameMrtReference(
  [in] AppContainerSid: PSid;
  [out, ReleaseWith('AppContainerFreeMemory')] out DisplayName: PWideChar
): HResult; stdcall; external kernelbase delayed;

var delayed_AppContainerLookupDisplayNameMrtReference: TDelayedLoadFunction = (
  Dll: @delayed_kernelbase;
  FunctionName: 'AppContainerLookupDisplayNameMrtReference';
);

// SDK::UserEnv.h
[MinOSVersion(OsWin81)]
function DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName(
  [in] AppContainerSid: PSid;
  [in] RestrictedAppContainerName: PWideChar;
  [out, ReleaseWith('RtlFreeSid')] out RestrictedAppContainerSid: PSid
): HResult; stdcall; external userenv delayed;

var delayed_DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName';
);

// SDK::netfw.h
[MinOSVersion(OsWin8)]
function NetworkIsolationFreeAppContainers(
  [in] Buffer: Pointer
): LongBool; stdcall; external firewallapi delayed;

var delayed_NetworkIsolationFreeAppContainers: TDelayedLoadFunction = (
  Dll: @delayed_firewallapi;
  FunctionName: 'NetworkIsolationFreeAppContainers';
);

// rev
[MinOSVersion(OsWin10TH1)]
function NetworkIsolationGetAppContainer(
  [Reserved] Flags: Cardinal;
  [in] UserSid: PSid;
  [in] AppContainerSid: PSid;
  [out, ReleaseWith('NetworkIsolationFreeAppContainers')]
    out PublicAppCs: PInetFirewallAppContainer
): TWin32Error; stdcall; external firewallapi delayed;

var delayed_NetworkIsolationGetAppContainer: TDelayedLoadFunction = (
  Dll: @delayed_firewallapi;
  FunctionName: 'NetworkIsolationGetAppContainer';
);

// SDK::netfw.h
[MinOSVersion(OsWin8)]
function NetworkIsolationEnumAppContainers(
  [in] Flags: TNetIsoFlags;
  [out, NumberOfElements] out NumPublicAppCs: Cardinal;
  [out, ReleaseWith('NetworkIsolationFreeAppContainers')]
    out PublicAppCs: PInetFirewallAppContainer
): TWin32Error; stdcall; external firewallapi delayed;

var delayed_NetworkIsolationEnumAppContainers: TDelayedLoadFunction = (
  Dll: @delayed_firewallapi;
  FunctionName: 'NetworkIsolationEnumAppContainers';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
