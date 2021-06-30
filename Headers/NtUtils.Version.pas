unit NtUtils.Version;

interface

type
  TKnownOsVersion = (
    OsWinOld,
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
    OsWin1021H1
  );

  TOsBuild = record
    OSMajorVersion: Cardinal;
    OSMinorVersion: Cardinal;
    OSBuildNumber: Word;
  end;

  // Marks a type or a field that requires a particular version of Windows
  MinOSVersionAttribute = class(TCustomAttribute)
    Version: TKnownOsVersion;
    constructor Create(OsVersion: TKnownOsVersion);
  end;

const
  KnownOsBuilds: array [TKnownOsVersion] of TOsBuild = (
    (OSMajorVersion: 0;  OSMinorVersion: 0; OSBuildNumber: 0),     // Older
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
    (OSMajorVersion: 10; OSMinorVersion: 0; OSBuildNumber: 19043)  // 10 21H1
  );

// Ensure Windows version is at least specified
function RtlOsVersionAtLeast(Version: TKnownOsVersion): Boolean;

// Get Windows version
function RtlOsVersion: TKnownOsVersion;

implementation

uses
  Ntapi.Ntpebteb;

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
    Exit(High(TKnownOsVersion));

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
    Exit(High(TKnownOsVersion));

  // One of the known Windows 10
  for Result := High(TKnownOsVersion) downto OsWin10TH1 do
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
