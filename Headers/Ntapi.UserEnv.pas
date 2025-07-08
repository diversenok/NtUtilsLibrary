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
  firewallapi = 'Firewallapi.dll';
  profext = 'profext.dll';

var
  delayed_userenv: TDelayedLoadDll = (DllName: userenv);
  delayed_profext: TDelayedLoadDll = (DllName: profext);
  delayed_firewallapi: TDelayedLoadDll = (DllName: firewallapi);

const
  // SDK::UserEnv.h - profile flags
  PT_TEMPORARY = $00000001;
  PT_ROAMING = $00000002;
  PT_MANDATORY = $00000004;
  PT_ROAMING_PREEXISTING = $00000008;

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

  // SDK::ProfInfo.h
  [SDKName('PROFILEINFOW')]
  TProfileInfoW = record
    [RecordSize] Size: Cardinal;
    Flags: TProfileType;
    UserName: PWideChar;
    ProfilePath: PWideChar;
    DefaultPath: PWideChar;
    ServerName: PWideChar;
    PolicyPath: PWideChar;
    hProfile: THandle;
  end;
  PProfileInfoW = ^TProfileInfoW;

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

// SDK::UserEnv.h
[SetsLastError]
function GetProfilesDirectoryW(
  [out, WritesTo] ProfileDir: PWideChar;
  [in, out, NumberOfElements] var Size: Cardinal
): LongBool; stdcall; external userenv delayed;

var delayed_GetProfilesDirectoryW: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'GetProfilesDirectoryW';
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
function GetAppContainerRegistryLocation(
  [in] DesiredAccess: TRegKeyAccessMask;
  [out, ReleaseWith('NtClose')] out hAppContainerKey: THandle
): HResult; stdcall; external userenv delayed;

var delayed_GetAppContainerRegistryLocation: TDelayedLoadFunction = (
  Dll: @delayed_userenv;
  FunctionName: 'GetAppContainerRegistryLocation';
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
[MinOSVersion(OsWin8)]
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
