unit NtUtils.Manifests;

{
  This module provides a constructor for EXE manifests.
}

interface

uses
  Ntapi.ntldr, Ntapi.ntmmapi, Ntapi.ntioapi, NtUtils, NtUtils.Files,
  DelphiApi.Reflection;

{$MINENUMSIZE 4}

type
  TSupportedOs = (
    soWindowsVista,
    soWindows7,
    soWindows8,
    soWindows81,
    soWindows10
  );

  TSupportedOsSet = set of TSupportedOs;

  TDpiAware = (
    dpiAwareAbsent,
    dpiAwareFalse,
    dpiAwareTrue,
    dpiAwareTruePerMonitor
  );

  TDpiAwareness = (
    dpiAbsent,
    dpiUnaware,
    dpiSystem,
    dpiPerMonitor,
    dpiPerMonitorV2
  );

  TRunLevel = (
    rlAsInvoker,
    rlHighestAvailable,
    rlRequireAdministrator
  );

  IManifestBuilder = interface
    // Fluent builder
    function UseRuntimeThemes(const Enabled: Boolean): IManifestBuilder;
    function UseRunLevel(const Value: TRunLevel): IManifestBuilder;
    function UseUiAccess(const Enabled: Boolean): IManifestBuilder;
    function UseSupportedOS(const Versions: TSupportedOsSet): IManifestBuilder;
    function UseActiveCodePage(const CodePage: String): IManifestBuilder;
    function UseDpiAware(const Value: TDpiAware): IManifestBuilder;
    function UseDpiAwareness(const Value: TDpiAwareness): IManifestBuilder;
    function UseGdiScaling(const Value: Boolean): IManifestBuilder;
    function UseLongPathAware(const Value: Boolean): IManifestBuilder;

    // Finalization
    function Build: UTF8String;

    // Accessor functions
    function GetRuntimeThemes: Boolean;
    function GetUiAccess: Boolean;
    function GetRunLevel: TRunLevel;
    function GetSupportedOS: TSupportedOsSet;
    function GetActiveCodePage: String;
    function GetDpiAware: TDpiAware;
    function GetDpiAwareness: TDpiAwareness;
    function GetGdiScaling: Boolean;
    function GetLongPathAware: Boolean;

    // Accessors
    property RuntimeThemes: Boolean read GetRuntimeThemes;
    property RunLevel: TRunLevel read GetRunLevel;
    property UiAccess: Boolean read GetUiAccess;
    property SupportedOS: TSupportedOsSet read GetSupportedOS;
    property ActiveCodePage: String read GetActiveCodePage;
    property DpiAware: TDpiAware read GetDpiAware;
    property DpiAwareness: TDpiAwareness read GetDpiAwareness;
    property GdiScaling: Boolean read GetGdiScaling;
    property LongPathAware: Boolean read GetLongPathAware;
  end;

// Make a new instance of a fluent manifest builder
function NewManifestBuilder(
  [opt] const Template: IManifestBuilder = nil
): IManifestBuilder;

// Find an embedded manifest in a DLL/EXE file
function LdrxFindManifest(
  [in] DllBase: PDllBase;
  out Manifest: TMemory
): TNtxStatus;

// Find an RVA of an embedded manifest in a DLL/EXE file section
function RtlxFindManifestInSection(
  [Access(SECTION_MAP_READ)] hImageSection: THandle;
  out ManifestRva: TMemory
): TNtxStatus;

// Find an RVA of an embedded manifest in a DLL/EXE file
function RtlxFindManifestInFile(
  [Access(FILE_READ_DATA)] const FileParameters: IFileOpenParameters;
  out ManifestRva: TMemory
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ImageHlp, NtUtils.Ldr, NtUtils.Sections, NtUtils.Processes,
  NtUtils.Files.Open, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TManifestBuilder = class (TInterfacedObject, IManifestBuilder)
  private
    FRuntimeThemes: Boolean;
    FRunLevel: TRunLevel;
    FUiAccess: Boolean;
    FSupportedOs: TSupportedOsSet;
    FActiveCodePage: String;
    FDpiAware: TDpiAware;
    FDpiAwareness: TDpiAwareness;
    FGdiScaling: Boolean;
    FLongPathAware: Boolean;
    function SetRuntimeThemes(const Value: Boolean): TManifestBuilder;
    function SetRunLevel(const Value: TRunLevel): TManifestBuilder;
    function SetUiAccess(const Value: Boolean): TManifestBuilder;
    function SetSupportedOS(const Value: TSupportedOsSet): TManifestBuilder;
    function SetActiveCodePage(const Value: String): TManifestBuilder;
    function SetDpiAware(const Value: TDpiAware): TManifestBuilder;
    function SetDpiAwareness(const Value: TDpiAwareness): TManifestBuilder;
    function SetGdiScaling(const Value: Boolean): TManifestBuilder;
    function SetLongPathAware(const Value: Boolean): TManifestBuilder;
    function Duplicate: TManifestBuilder;
    function BuildInternal: String;
  public
    function UseRuntimeThemes(const Value: Boolean): IManifestBuilder;
    function UseRunLevel(const Value: TRunLevel): IManifestBuilder;
    function UseUiAccess(const Value: Boolean): IManifestBuilder;
    function UseSupportedOS(const Value: TSupportedOsSet): IManifestBuilder;
    function UseActiveCodePage(const Value: String): IManifestBuilder;
    function UseDpiAware(const Value: TDpiAware): IManifestBuilder;
    function UseDpiAwareness(const Value: TDpiAwareness): IManifestBuilder;
    function UseGdiScaling(const Value: Boolean): IManifestBuilder;
    function UseLongPathAware(const Value: Boolean): IManifestBuilder;
    function Build: UTF8String;
    function GetRuntimeThemes: Boolean;
    function GetRunLevel: TRunLevel;
    function GetUiAccess: Boolean;
    function GetSupportedOS: TSupportedOsSet;
    function GetActiveCodePage: String;
    function GetDpiAware: TDpiAware;
    function GetDpiAwareness: TDpiAwareness;
    function GetGdiScaling: Boolean;
    function GetLongPathAware: Boolean;
  end;

const
  MANIFEST =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'#$D#$A +
    '<assembly xmlns="urn:schemas-microsoft-com:asm.v1"'#$D#$A +
    '  manifestVersion="1.0" xmlns:asmv3="urn:schemas-microsoft-com:asm.v3">'#$D#$A +
    '%s</assembly>';

  WINDOWS_SETTINGS =
    '  <asmv3:application>'#$D#$A +
    '    <asmv3:windowsSettings>'#$D#$A +
    '%s    </asmv3:windowsSettings>'#$D#$A +
    '  </asmv3:application>'#$D#$A;

  DPI_AWARE =
    '      <dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">%s</dpiAware>'#$D#$A;

  DPI_AWARENESS =
    '      <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">%s</dpiAwareness>'#$D#$A;

  ACTIVE_CODE_PAGE =
    '      <activeCodePage xmlns="http://schemas.microsoft.com/SMI/2019/WindowsSettings">%s</activeCodePage>'#$D#$A;

  GDI_SCALING =
    '      <gdiScaling xmlns="http://schemas.microsoft.com/SMI/2017/WindowsSettings">true</gdiScaling>'#$D#$A;

  LONG_PATH_AWARE =
    '      <longPathAware xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">true</longPathAware>'#$D#$A;

  DPI_AWARE_VALUE: array [TDpiAware] of String = ('', 'false', 'true', 'true/pm');
  DPI_AWARENESS_VALUE: array [TDpiAwareness] of String = ('', 'unaware',
    'system', 'permonitor, system', 'permonitorv2, permonitor, system');

  TRUST_INFO =
    '  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">'#$D#$A +
    '    <security>'#$D#$A +
    '      <requestedPrivileges>'#$D#$A +
    '        <requestedExecutionLevel level="%s" uiAccess="%s"/>'#$D#$A +
    '      </requestedPrivileges>'#$D#$A +
    '    </security>'#$D#$A +
    '  </trustInfo>'#$D#$A;

  RUN_LEVEL_VALUE: array [TRunLevel] of String = ('asInvoker',
    'highestAvailable', 'requireAdministrator');

  UI_ACCESS_VALUE: array [Boolean] of String = ('false', 'true');

  COMPATIBILITY =
    '  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">'#$D#$A +
    '    <application>'#$D#$A +
    '%s    </application>'#$D#$A +
    '  </compatibility>'#$D#$A;

  COMPATIBILITY_VALUE: array [TSupportedOs] of String = (
    '      <!--The ID below indicates app support for Windows Vista -->'#$D#$A +
    '      <supportedOS Id="{e2011457-1546-43c5-a5fe-008deee3d3f0}"/>'#$D#$A,
    '      <!--The ID below indicates app support for Windows 7 -->'#$D#$A +
    '      <supportedOS Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"/>'#$D#$A,
    '      <!--The ID below indicates app support for Windows 8 -->'#$D#$A +
    '      <supportedOS Id="{4a2f28e3-53b9-4441-ba9c-d69d4a4a6e38}"/>'#$D#$A,
    '      <!--The ID below indicates app support for Windows 8.1 -->'#$D#$A +
    '      <supportedOS Id="{1f676c76-80e1-4239-95bb-83d0f6d0da78}"/>'#$D#$A,
    '      <!--The ID below indicates app support for Windows 10 -->'#$D#$A +
    '      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>'#$D#$A
  );

  COMCTRL_DEPENDENCY =
    '  <dependency>'#$D#$A +
    '    <dependentAssembly>'#$D#$A +
    '      <assemblyIdentity'#$D#$A +
    '        type="win32"'#$D#$A +
    '        name="Microsoft.Windows.Common-Controls"'#$D#$A +
    '        version="6.0.0.0"'#$D#$A +
    '        publicKeyToken="6595b64144ccf1df"'#$D#$A +
    '        language="*"'#$D#$A +
    '        processorArchitecture="*"/>'#$D#$A +
    '    </dependentAssembly>'#$D#$A +
    '  </dependency>'#$D#$A;

function StringOrDefault(const Value: String; Default: String = ''): String;
begin
  // We don't support escaping, so block bad-formatted strings entirely

  if (Value = '') or (Pos('''', Value) > 0) or (Pos('"', Value) > 0) or
    (Pos('&', Value) > 0) or (Pos('<', Value) > 0) or (Pos('>', Value) > 0) then
    Result := Default
  else
    Result := Value;
end;

{ TManifestBuilder }

function TManifestBuilder.Build;
begin
  Result := UTF8String(BuildInternal);
end;

function TManifestBuilder.BuildInternal;
var
  Os: TSupportedOs;
  CompatibilityStr: String;
begin
  Assert(FDpiAware <= High(TDpiAware), 'Invalid dpiAware');
  Assert(FDpiAwareness <= High(TDpiAwareness), 'Invalid dpiAwareness');
  Assert(FRunLevel <= High(TRunLevel), 'Invalid requestedExecutionLevel');

  Result := '';

  // Add dpiAware
  if (FDpiAware > dpiAwareAbsent) then
    Result := Result + RtlxFormatString(DPI_AWARE, [DPI_AWARE_VALUE[FDpiAware]]);

  // Add dpiAwareness
  if (FDpiAwareness > dpiAbsent) then
    Result := Result + RtlxFormatString(DPI_AWARENESS, [
      DPI_AWARENESS_VALUE[FDpiAwareness]]);

  // Add activeCodePage
  if FActiveCodePage <> '' then
    Result := Result + RtlxFormatString(ACTIVE_CODE_PAGE, [
      StringOrDefault(FActiveCodePage)]);

  // Add gdiScaling
  if FGdiScaling then
    Result := Result + GDI_SCALING;

  // Add longPathAware
  if FLongPathAware then
    Result := Result + LONG_PATH_AWARE;

  // Merge all windowsSettings
  if Result <> '' then
    Result := RtlxFormatString(WINDOWS_SETTINGS, [Result]);

  // Add trustInfo
  Result := Result + RtlxFormatString(TRUST_INFO, [RUN_LEVEL_VALUE[FRunLevel],
    UI_ACCESS_VALUE[FUiAccess <> False]]);

  // Add dependentAssembly for ComCtrl 6.0
  if FRuntimeThemes then
    Result := Result + COMCTRL_DEPENDENCY;

  // Add compatibility
  if FSupportedOs * [soWindowsVista..soWindows10] <> [] then
  begin
    CompatibilityStr := '';


    for Os in FSupportedOS do
      CompatibilityStr := CompatibilityStr + COMPATIBILITY_VALUE[Os];

    Result := Result + RtlxFormatString(COMPATIBILITY, [CompatibilityStr]);
  end;

  // Wrap into assembly
  Result := RtlxFormatString(MANIFEST, [Result]);
end;

function TManifestBuilder.Duplicate;
begin
  Result := TManifestBuilder.Create
    .SetRuntimeThemes(FRuntimeThemes)
    .SetRunLevel(FRunLevel)
    .SetUiAccess(FUiAccess)
    .SetSupportedOS(FSupportedOs)
    .SetActiveCodePage(FActiveCodePage)
    .SetDpiAware(FDpiAware)
    .SetDpiAwareness(FDpiAwareness)
    .SetGdiScaling(FGdiScaling)
    .SetLongPathAware(FLongPathAware);
end;

function TManifestBuilder.GetActiveCodePage;
begin
  Result := FActiveCodePage;
end;

function TManifestBuilder.GetDpiAware;
begin
  Result := FDpiAware;
end;

function TManifestBuilder.GetDpiAwareness;
begin
  Result := FDpiAwareness;
end;

function TManifestBuilder.GetGdiScaling;
begin
  Result := FGdiScaling;
end;

function TManifestBuilder.GetLongPathAware;
begin
  Result := FLongPathAware;
end;

function TManifestBuilder.GetRunLevel;
begin
  Result := FRunLevel;
end;

function TManifestBuilder.GetRuntimeThemes;
begin
  Result := FRuntimeThemes;
end;

function TManifestBuilder.GetSupportedOS;
begin
  Result := FSupportedOs;
end;

function TManifestBuilder.GetUiAccess;
begin
  Result := FUiAccess;
end;

function TManifestBuilder.SetActiveCodePage;
begin
  FActiveCodePage := Value;
  Result := Self;
end;

function TManifestBuilder.SetDpiAware;
begin
  FDpiAware := Value;
  Result := Self;
end;

function TManifestBuilder.SetDpiAwareness;
begin
  FDpiAwareness := Value;
  Result := Self;
end;

function TManifestBuilder.SetGdiScaling;
begin
  FGdiScaling := Value;
  Result := Self;
end;

function TManifestBuilder.SetLongPathAware;
begin
  FLongPathAware := Value;
  Result := Self;
end;

function TManifestBuilder.SetRunLevel;
begin
  FRunLevel := Value;
  Result := Self;
end;

function TManifestBuilder.SetRuntimeThemes;
begin
  FRuntimeThemes := Value;
  Result := Self;
end;

function TManifestBuilder.SetSupportedOS;
begin
  FSupportedOs := Value;
  Result := Self;
end;

function TManifestBuilder.SetUiAccess;
begin
  FUiAccess := Value;
  Result := Self;
end;

function TManifestBuilder.UseActiveCodePage;
begin
  Result := Duplicate.SetActiveCodePage(Value);
end;

function TManifestBuilder.UseDpiAware;
begin
  Result := Duplicate.SetDpiAware(Value);
end;

function TManifestBuilder.UseDpiAwareness;
begin
  Result := Duplicate.SetDpiAwareness(Value);
end;

function TManifestBuilder.UseGdiScaling;
begin
  Result := Duplicate.SetGdiScaling(Value);
end;

function TManifestBuilder.UseLongPathAware;
begin
  Result := Duplicate.SetLongPathAware(Value);
end;

function TManifestBuilder.UseRunLevel;
begin
  Result := Duplicate.SetRunLevel(Value);
end;

function TManifestBuilder.UseRuntimeThemes;
begin
  Result := Duplicate.SetRuntimeThemes(Value);
end;

function TManifestBuilder.UseSupportedOS;
begin
  Result := Duplicate.SetSupportedOS(Value);
end;

function TManifestBuilder.UseUiAccess;
begin
  Result := Duplicate.SetUiAccess(Value);
end;

{ Functions }

function NewManifestBuilder;
begin
  if Assigned(Template) then
    Result := Template
  else
    Result := TManifestBuilder.Create;
end;

function LdrxFindManifest;
const
  KNOWN_MANIFEST_IDs: array [0..2] of PWideChar = (
    CREATEPROCESS_MANIFEST_RESOURCE_ID,
    ISOLATIONAWARE_MANIFEST_RESOURCE_ID,
    ISOLATIONAWARE_NOSTATICIMPORT_MANIFEST_RESOURCE_ID
  );
var
  i: Integer;
  Buffer: Pointer;
  Size: Cardinal;
begin
  for i := Low(KNOWN_MANIFEST_IDs) to High(KNOWN_MANIFEST_IDs) do
  begin
    Result := LdrxFindResourceData(DllBase, KNOWN_MANIFEST_IDs[i],
      RT_MANIFEST, LANG_NEUTRAL, Buffer, Size);

    if Result.IsSuccess then
    begin
      Manifest.Address := Buffer;
      Manifest.Size := Size;
      Exit;
    end;
  end;
end;

function RtlxFindManifestInSection;
var
  Mapping: IMemory;
begin
  Result := NtxMapViewOfSection(Mapping, hImageSection, NtxCurrentProcess,
    PAGE_READONLY);

  if Result.IsSuccess then
    Result := LdrxFindManifest(Mapping.Data, ManifestRva);

  if Result.IsSuccess then
    Dec(PByte(ManifestRva.Address), UIntPtr(Mapping.Data));
end;

function RtlxFindManifestInFile;
var
  hxSection: IHandle;
begin
  Result := RtlxCreateFileSection(hxSection, FileParameters,
    RtlxSecImageNoExecute);

  if Result.IsSuccess then
    Result := RtlxFindManifestInSection(hxSection.Handle, ManifestRva);
end;

end.
