unit Ntapi.UserEnv;

{
  This file defines functions for working with user and AppContainer profiles.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.ntregapi, Ntapi.Versions,
  DelphiApi.Reflection;

const
  userenv = 'userenv.dll';

const
  // SDK::UserEnv.h - profile flags
  PT_TEMPORARY = $00000001;
  PT_ROAMING = $00000002;
  PT_MANDATORY = $00000004;
  PT_ROAMING_PREEXISTING = $00000008;

  // For annotations
  TOKEN_LOAD_PROFILE = TOKEN_QUERY or TOKEN_IMPERSONATE or TOKEN_DUPLICATE;

type
  [FlagName(PT_TEMPORARY, 'Temporary')]
  [FlagName(PT_ROAMING, 'Roaming')]
  [FlagName(PT_MANDATORY, 'Mandatory')]
  [FlagName(PT_ROAMING_PREEXISTING, 'Roaming Pre-existing')]
  TProfileType = type Cardinal;

  // SDK::ProfInfo.h
  [SDKName('PROFILEINFOW')]
  TProfileInfoW = record
    [Bytes, Unlisted] Size: Cardinal;
    Flags: TProfileType;
    UserName: PWideChar;
    ProfilePath: PWideChar;
    DefaultPath: PWideChar;
    ServerName: PWideChar;
    PolicyPath: PWideChar;
    hProfile: THandle;
  end;
  PProfileInfoW = ^TProfileInfoW;

// SDK::UserEnv.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function LoadUserProfileW(
  [Access(TOKEN_LOAD_PROFILE)] hToken: THandle;
  var ProfileInfo: TProfileInfoW
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
[RequiredPrivilege(SE_BACKUP_PRIVILEGE, rpAlways)]
[RequiredPrivilege(SE_RESTORE_PRIVILEGE, rpAlways)]
function UnloadUserProfile(
  [Access(TOKEN_LOAD_PROFILE)] hToken: THandle;
  hProfile: THandle
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
function GetProfilesDirectoryW(
  [out, opt] ProfileDir: PWideChar;
  var Size: Cardinal
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
function GetProfileType(
  out Flags: Cardinal
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
function CreateEnvironmentBlock(
  out Environment: PEnvironment;
  [opt] hToken: THandle;
  bInherit: LongBool
): LongBool; stdcall; external userenv delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function CreateAppContainerProfile(
  [in] AppContainerName: PWideChar;
  [in] DisplayName: PWideChar;
  [in] Description: PWideChar;
  [in, opt] Capabilities: TArray<TSidAndAttributes>;
  CapabilityCount: Integer;
  [allocates('RtlFreeSid')] out SidAppContainerSid: PSid
): HResult; stdcall; external userenv delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function DeleteAppContainerProfile(
  [in] AppContainerName: PWideChar
): HResult; stdcall; external userenv delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function GetAppContainerRegistryLocation(
  DesiredAccess: TRegKeyAccessMask;
  out hAppContainerKey: THandle
): HResult; stdcall; external userenv delayed;

// SDK::combaseapi.h
procedure CoTaskMemFree(
  [in, opt] pv: Pointer
); stdcall; external 'ole32.dll';

// SDK::UserEnv.h
[MinOSVersion(OsWin8)]
function GetAppContainerFolderPath(
  [in] AppContainerSid: PWideChar;
  [allocates('CoTaskMemFree')] out Path: PWideChar
): HResult; stdcall; external userenv delayed;

// MSDN
[MinOSVersion(OsWin8)]
function AppContainerDeriveSidFromMoniker(
  [in] Moniker: PWideChar;
  [allocates('RtlFreeSid')] out AppContainerSid: PSid
): HResult; stdcall; external kernelbase delayed;

// rev
[MinOSVersion(OsWin8)]
function AppContainerFreeMemory(
  [in] Memory: Pointer
): Boolean; stdcall; external kernelbase delayed;

// rev
[MinOSVersion(OsWin8)]
function AppContainerLookupMoniker(
  [in] Sid: PSid;
  [allocates('AppContainerFreeMemory')] out Moniker: PWideChar
): HResult; stdcall; external kernelbase delayed;

// SDK::UserEnv.h
[MinOSVersion(OsWin81)]
function DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName(
  [in] AppContainerSid: PSid;
  [in] RestrictedAppContainerName: PWideChar;
  [allocates('RtlFreeSid')] out RestrictedAppContainerSid: PSid
): HResult; stdcall; external userenv delayed;

implementation

end.
