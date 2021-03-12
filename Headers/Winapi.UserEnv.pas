unit Winapi.UserEnv;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntseapi, Ntapi.ntregapi, DelphiApi.Reflection;

const
  userenv = 'userenv.dll';

const
  // 172
  PT_TEMPORARY = $00000001;
  PT_ROAMING = $00000002;
  PT_MANDATORY = $00000004;
  PT_ROAMING_PREEXISTING = $00000008;

type
  [FlagName(PT_TEMPORARY, 'Temporary')]
  [FlagName(PT_ROAMING, 'Roaming')]
  [FlagName(PT_MANDATORY, 'Mandatory')]
  [FlagName(PT_ROAMING_PREEXISTING, 'Roaming Pre-existing')]
  TProfileType = type Cardinal;

  // profinfo.38
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

// 80
function LoadUserProfileW(
  hToken: THandle;
  var ProfileInfo: TProfileInfoW
): LongBool; stdcall; external userenv delayed;

// 108
function UnloadUserProfile(
  hToken: THandle;
  hProfile: THandle
): LongBool; stdcall; external userenv delayed;

// 140
function GetProfilesDirectoryW(
  ProfileDir: PWideChar;
  var Size: Cardinal
): LongBool; stdcall; external userenv delayed;

// 180
function GetProfileType(
  out Flags: Cardinal
): LongBool; stdcall; external userenv delayed;

// 412
function CreateEnvironmentBlock(
  out Environment: PEnvironment;
  hToken: THandle;
  bInherit: LongBool
): LongBool; stdcall; external userenv delayed;

// 1396, Win 8+, free with RtlFreeSid
function CreateAppContainerProfile(
  AppContainerName: PWideChar;
  DisplayName: PWideChar;
  Description: PWideChar;
  Capabilities: TArray<TSidAndAttributes>;
  CapabilityCount: Integer;
  out SidAppContainerSid: PSid
): HResult; stdcall; external userenv delayed;

// 1427, Win 8+
function DeleteAppContainerProfile(
  AppContainerName: PWideChar
): HResult; stdcall; external userenv delayed;

// 1455, Win 8+
function GetAppContainerRegistryLocation(
  DesiredAccess: TRegKeyAccessMask;
  out hAppContainerKey: THandle
): HResult; stdcall; external userenv delayed;

// combaseapi.1452
procedure CoTaskMemFree(
  pv: Pointer
); stdcall; external 'ole32.dll';

// 1484, Win 8+, free with CoTaskMemFree
function GetAppContainerFolderPath(
  AppContainerSid: PWideChar;
  out Path: PWideChar
): HResult; stdcall; external userenv delayed;

// rev, Win 8+, free with RtlFreeSid
// aka DeriveAppContainerSidFromAppContainerName
function AppContainerDeriveSidFromMoniker(
  Moniker: PWideChar;
  out AppContainerSid: PSid
): HResult; stdcall; external kernelbase delayed;

// rev, Win 8+
function AppContainerFreeMemory(
  Memory: Pointer
): Boolean; stdcall; external kernelbase delayed;

// rev, Win 8+, free with AppContainerFreeMemory
function AppContainerLookupMoniker(
  Sid: PSid;
  out Moniker: PWideChar
): HResult; stdcall; external kernelbase delayed;

// 1539, Win 8.1+, free with RtlFreeSid
function DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName(
  AppContainerSid: PSid;
  RestrictedAppContainerName: PWideChar;
  out RestrictedAppContainerSid: PSid
): HResult; stdcall; external userenv delayed;

implementation

end.
