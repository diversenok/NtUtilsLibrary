unit Ntapi.Versions;

{
  This module allows checking Windows version in runtime and provides a custom
  attribute for annotating entities that require a minimal specific version.
}

interface

uses
  DelphiApi.Reflection;

{$MINENUMSIZE 4}

type
  [NamingStyle(nsCamelCase, 'Os')]
  TWindowsVersion = (
    OsWinOld,
    OsWinXP,
    OsWinVista,
    OsWin7,
    OsWin8,
    OsWin81,
    OsWin10,
    OsWin10TH1,
    OsWin10TH2,
    OsWin10RS1,
    OsWin10RS2,
    OsWin10RS3,
    OsWin10RS4,
    OsWin10RS5,
    OsWin1019H1,
    OsWin1019H2,
    OsWin1020H1,
    OsWin1020H2,
    OsWin1021H1,
    OsWin1021H2,
    OsWin1022H2,
    OsWin11,
    OsWin1122H2
  );

  TOsBuild = record
    OSMajorVersion: Cardinal;
    OSMinorVersion: Cardinal;
    OSBuildNumber: Word;
  end;

  // Marks a type or a field that requires a particular version of Windows
  MinOSVersionAttribute = class(TCustomAttribute)
    Version: TWindowsVersion;
    constructor Create(OsVersion: TWindowsVersion);
  end;

const
  KnownOsBuilds: array [TWindowsVersion] of TOsBuild = (
    (OSMajorVersion: 0;  OSMinorVersion: 0; OSBuildNumber: 0),     // Older
    (OSMajorVersion: 5;  OSMinorVersion: 1; OSBuildNumber: 0),     // XP
    (OSMajorVersion: 6;  OSMinorVersion: 0; OSBuildNumber: 0),     // Vista
    (OSMajorVersion: 6;  OSMinorVersion: 1; OSBuildNumber: 0),     // 7
    (OSMajorVersion: 6;  OSMinorVersion: 2; OSBuildNumber: 0),     // 8
    (OSMajorVersion: 6;  OSMinorVersion: 3; OSBuildNumber: 0),     // 8.1
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 0),     // 10
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 10240), // 10 TH1
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 10586), // 10 TH2
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 14393), // 10 RS1
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 15063), // 10 RS2
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 16299), // 10 RS3
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 17134), // 10 RS4
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 17763), // 10 RS5
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 18362), // 10 19H1
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 18363), // 10 19H2
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 19041), // 10 20H1
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 19042), // 10 20H2
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 19043), // 10 21H1
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 19044), // 10 21H2
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 19045), // 10 22H2
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 22000), // 11 21H2
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 22621)  // 11 22H2
  );

// Make sure that Windows version matches the minimum requirement
function RtlOsVersionAtLeast(Version: TWindowsVersion): Boolean;

// Get the version of Windows
function RtlOsVersion: TWindowsVersion;

implementation

uses
  Ntapi.Ntpebteb;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlOsVersionAtLeast;
var
  Peb: PPeb;
begin
  Peb := RtlGetCurrentPeb;

  with KnownOsBuilds[Version] do
    Result := (Peb.OSMajorVersion > OSMajorVersion) or (
      (Peb.OSMajorVersion = OSMajorVersion) and (
      (Peb.OSMinorVersion > OSMinorVersion) or
      ((Peb.OSMinorVersion = OSMinorVersion) and
      (Peb.OSBuildNumber >= OSBuildNumber))));
end;

function RtlOsVersion;
var
  Peb: PPeb;
begin
  Peb := RtlGetCurrentPeb;

  // More than Windows 10
  if Peb.OSMajorVersion > KnownOsBuilds[OsWin10].OSMajorVersion then
    Exit(High(TWindowsVersion));

  // Less than Windows 7
  if Peb.OSMajorVersion < KnownOsBuilds[OsWin7].OSMajorVersion then
      Exit(OsWinOld);

  // Before Windows 10
  if Peb.OSMajorVersion < KnownOsBuilds[OsWin10].OSMajorVersion then
  begin
    if Peb.OSMajorVersion > KnownOsBuilds[OsWin81].OSMajorVersion then
      Exit(OsWin81);

    for Result := OsWin81 downto OsWin7 do
      if Peb.OSMinorVersion >= KnownOsBuilds[Result].OSMinorVersion then
        Exit;

    Exit(OsWinOld);
  end;

  // Windows 10, but too new minor
  if Peb.OSMinorVersion > KnownOsBuilds[OsWin10].OSMinorVersion then
    Exit(High(TWindowsVersion));

  // One of the known Windows 10
  for Result := High(TWindowsVersion) downto OsWin10TH1 do
    if Peb.OSBuildNumber >= KnownOsBuilds[Result].OSBuildNumber then
      Exit;

  // Too old Windows 10
  Result := OsWin10;
end;

{ MinOSVersionAttribute }

constructor MinOSVersionAttribute.Create;
begin
  Version := OsVersion;
end;

end.
