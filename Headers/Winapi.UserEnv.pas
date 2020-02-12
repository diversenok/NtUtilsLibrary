unit Winapi.UserEnv;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

const
  userenv = 'userenv.dll';

const
  // 172
  PT_TEMPORARY = $00000001;
  PT_ROAMING = $00000002;
  PT_MANDATORY = $00000004;
  PT_ROAMING_PREEXISTING = $00000008;

  ProfileTypeNames: array [0..3] of TFlagName = (
    (Value: PT_TEMPORARY; Name: 'Temporary'),
    (Value: PT_ROAMING; Name: 'Roaming'),
    (Value: PT_MANDATORY; Name: 'Mandatory'),
    (Value: PT_ROAMING_PREEXISTING; Name: 'Roaming Preexisting')
  );

type
  TProfileTypeProvider = class(TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

  // profinfo.38
  TProfileInfoW = record
    [Bytes, Unlisted] Size: Cardinal;
    [Bitwise(TProfileTypeProvider)] Flags: Cardinal;
    UserName: PWideChar;
    ProfilePath: PWideChar;
    DefaultPath: PWideChar;
    ServerName: PWideChar;
    PolicyPath: PWideChar;
    hProfile: THandle;
  end;
  PProfileInfoW = ^TProfileInfoW;

// 80
function LoadUserProfileW(hToken: THandle; var ProfileInfo: TProfileInfoW):
  LongBool; stdcall; external userenv delayed;

// 108
function UnloadUserProfile(hToken: THandle; hProfile: THandle): LongBool;
  stdcall; external userenv delayed;

// 140
function GetProfilesDirectoryW(ProfileDir: PWideChar; var Size: Cardinal)
  : LongBool; stdcall; external userenv delayed;

// 180
function GetProfileType(out Flags: Cardinal): LongBool; stdcall;
  external userenv delayed;

// 412
function CreateEnvironmentBlock(out Environment: Pointer; hToken: THandle;
  bInherit: LongBool): LongBool; stdcall; external userenv delayed;

// 1396, Win 8+, free with RtlFreeSid
function CreateAppContainerProfile(AppContainerName: PWideChar; DisplayName:
  PWideChar; Description: PWideChar; Capabilities: TArray<TSidAndAttributes>;
  CapabilityCount: Integer; out SidAppContainerSid: PSid): HRESULT; stdcall;
  external userenv delayed;

// 1427, Win 8+
function DeleteAppContainerProfile(AppContainerName: PWideChar): HRESULT;
  stdcall; external userenv delayed;

// 1455, Win 8+
function GetAppContainerRegistryLocation(DesiredAccess: TAccessMask;
  out hAppContainerKey: THandle): HRESULT; stdcall; external userenv delayed;

// combaseapi.1452
procedure CoTaskMemFree(pv: Pointer); stdcall; external 'ole32.dll';

// 1484, Win 8+, free with CoTaskMemFree
function GetAppContainerFolderPath(AppContainerSid: PWideChar;
  out Path: PWideChar): HRESULT; stdcall; external userenv delayed;

// rev, Win 8+, free with RtlFreeSid
// aka DeriveAppContainerSidFromAppContainerName
function AppContainerDeriveSidFromMoniker(Moniker: PWideChar;
  out AppContainerSid: PSid): HRESULT; stdcall; external kernelbase delayed;

// rev, Win 8+
function AppContainerFreeMemory(Memory: Pointer): Boolean; stdcall;
  external kernelbase delayed;

// rev, Win 8+, free with AppContainerFreeMemory
function AppContainerLookupMoniker(Sid: PSid; out Moniker: PWideChar): HRESULT;
  stdcall; external kernelbase delayed;

// 1539, Win 8.1+, free with RtlFreeSid
function DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName(
  AppContainerSid: PSid; RestrictedAppContainerName: PWideChar;
  out RestrictedAppContainerSid: PSid): HRESULT; stdcall;
  external userenv delayed;

implementation

class function TProfileTypeProvider.Flags: TFlagNames;
begin
  Result := Capture(ProfileTypeNames);
end;

end.
