unit NtUiLib.AutoCompletion.Sid.Capabilities;

{
  This module adds support for representing and recognizing capability SIDs.

  Adding the module as a dependency enhances the following functions:
   - RtlxStringToSid
   - RtlxLookupSidInCustomProviders
   - LsaxLookupSids
}

interface

uses
  Ntapi.Versions, NtUtils;

const
  // Custom domain names for capability and AppContainer SIDs
  APP_CAPABILITY_DOMAIN = 'APP CAPABILITY';
  GROUP_CAPABILITY_DOMAIN = 'GROUP CAPABILITY';

// Make sure the cache of known capability names is initialized
procedure RtlxInitializeKnownCapabilities;

// Remember a SID-name mapping for a capability
function RtlxRememberCapability(
  const CapabilityName: String
): TNtxStatus;

// Retrieve the list of known and remembered capability names
[MinOSVersion(OsWin10TH1)]
function RtlxEnumerateKnownCapabilities(
  const AddPrefix: String = ''
): TArray<String>;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ImageHlp,
  NtUtils.Ldr, NtUtils.SysUtils, NtUtils.Security.Sid,
  NtUtils.Security.AppContainer, NtUtils.Lsa.Sid, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

// Embed the list of known capabilities
{$RESOURCE NtUiLib.AutoCompletion.Sid.Capabilities.res}

type
  TCapabilityEntry = record
    Sid: ISid;
    Name: String;
  end;

function RtlxCompareCapabilities(const A, B: TCapabilityEntry): Integer;
begin
   Result := RtlxCompareSids(A.Sid, B.Sid);
end;

var
  // Cache of known capabilities
  CapabilitiesInitialized: Boolean;
  AppCapabilities: TArray<TCapabilityEntry>;
  GroupCapabilities: TArray<TCapabilityEntry>;

procedure RtlxInitializeKnownCapabilities;
var
  Status: TNtxStatus;
  Buffer: PAnsiMultiSz;
  BufferSize: Cardinal;
  Names: TArray<AnsiString>;
  Name: String;
  i, j: Integer;
begin
  if CapabilitiesInitialized then
    Exit;

  // There is no apparent reason why the operation would fail once but not twice
  CapabilitiesInitialized := True;

  // Check if the OS supports capability SIDs
  Status := LdrxCheckDelayedImport(delayed_ntdll,
    delayed_RtlDeriveCapabilitySidsFromName);

  if not Status.IsSuccess then
    Exit;

  // Find the embedded resource with the list of capability names
  Status := LdrxFindResourceData(
    Pointer(@ImageBase),
    'CAPABILITIES',
    RT_RCDATA,
    LANG_NEUTRAL or (SUBLANG_NEUTRAL shl SUBLANGID_SHIFT),
    Pointer(Buffer),
    BufferSize
  );

  if not Status.IsSuccess then
    Exit;

  // Extract all known names
  Names := RtlxParseAnsiMultiSz(Buffer, BufferSize);

  // We store app and group capabilities separately. While most of them
  // share sub authorities derived from the capability name, there are a few
  // legacy entries that make it impossible to have both arrays sorted at once.
  SetLength(AppCapabilities, Length(Names));
  SetLength(GroupCapabilities, Length(Names));

  j := 0;

  for i := 0 to High(Names) do
  begin
    Name := String(Names[i]);

    // Prepare both SIDs at once without remembering the translation
    if not RtlxDeriveCapabilitySids(Name, GroupCapabilities[j].Sid,
      AppCapabilities[j].Sid).IsSuccess then
      Continue;

    // Save on success
    AppCapabilities[j].Name := Name;
    GroupCapabilities[j].Name := Name;
    Inc(j);
  end;

  // Truncate if necessary
  SetLength(AppCapabilities, j);
  SetLength(GroupCapabilities, j);

  // Sort both arrays to allow using binary search
  TArray.SortInline<TCapabilityEntry>(AppCapabilities, RtlxCompareCapabilities);
  TArray.SortInline<TCapabilityEntry>(GroupCapabilities, RtlxCompareCapabilities);
end;

procedure RtlxRememberCapabilityInternal(
  const Name: String;
  const CapGroupSid: ISid;
  const CapSid: ISid
);
var
  Entry: TCapabilityEntry;
begin
  RtlxInitializeKnownCapabilities;
  Entry.Name := Name;

  // Remember the app capabiliy mapping
  Entry.Sid := CapSid;
  TArray.InsertSorted<TCapabilityEntry>(AppCapabilities, Entry, dhOverwrite,
    RtlxCompareCapabilities);

  // Remember the group capabiliy mapping
  Entry.Sid := CapGroupSid;
  TArray.InsertSorted<TCapabilityEntry>(GroupCapabilities, Entry, dhOverwrite,
    RtlxCompareCapabilities);
end;

function RtlxRememberCapability;
var
  CapGroupSid: ISid;
  CapSid: ISid;
begin
  Result := RtlxDeriveCapabilitySids(CapabilityName, CapGroupSid, CapSid);

  if Result.IsSuccess then
    RtlxRememberCapabilityInternal(CapabilityName, CapGroupSid, CapSid);
end;

function RtlxRecognizeCapabilitySIDs(
  const StringSid: String;
  out Sid: ISid
): Boolean;
const
  APP_CAPABILITY_PREFIX = APP_CAPABILITY_DOMAIN + '\';
  GROUP_CAPABILITY_PREFIX = GROUP_CAPABILITY_DOMAIN + '\';
var
  Mode: TCapabilityType;
  Name: String;
  CapGroupSid: ISid;
  CapSid: ISid;
begin
  Name := StringSid;

  if RtlxPrefixStripString(APP_CAPABILITY_PREFIX, Name) then
    Mode := ctAppCapability
  else if RtlxPrefixStripString(GROUP_CAPABILITY_PREFIX, Name) then
    Mode := ctGroupCapability
  else
    Exit(False);

  // Derive the pair of SIDs
  Result := RtlxDeriveCapabilitySids(Name, CapGroupSid, CapSid).IsSuccess;

  if not Result then
    Exit;

  case Mode of
    ctAppCapability:   Sid := CapSid;
    ctGroupCapability: Sid := CapGroupSid;
  end;

  // Save for later translation back
  RtlxRememberCapabilityInternal(Name, CapGroupSid, CapSid);
end;

function RtlxProvideCapabilitySIDs(
  const Sid: ISid;
  out SidType: TSidNameUse;
  out SidDomain: String;
  out SidUser: String
): Boolean;
var
  Mode: TCapabilityType;
  Cache: TArray<TCapabilityEntry>;
  Index: Integer;
begin
  Result := False;

  // Verify the domain
  if (RtlxIdentifierAuthoritySid(Sid) = SECURITY_APP_PACKAGE_AUTHORITY) and (
    (RtlxSubAuthorityCountSid(Sid) = SECURITY_BUILTIN_CAPABILITY_RID_COUNT)
    or (RtlxSubAuthorityCountSid(Sid) =
    SECURITY_INSTALLER_CAPABILITY_RID_COUNT)) and
    (RtlxSubAuthoritySid(Sid, 0) = SECURITY_CAPABILITY_BASE_RID) then
  begin
    Mode := ctAppCapability;
    SidDomain := APP_CAPABILITY_DOMAIN;
  end
  else if (RtlxIdentifierAuthoritySid(Sid) = SECURITY_NT_AUTHORITY) and
    (RtlxSubAuthorityCountSid(Sid) =
    SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT) and
    (RtlxSubAuthoritySid(Sid, 0) =
    SECURITY_INSTALLER_GROUP_CAPABILITY_BASE) then
  begin
    Mode := ctGroupCapability;
    SidDomain := GROUP_CAPABILITY_DOMAIN;
  end
  else
    Exit;

  SidType := SidTypeWellKnownGroup;

  // Make sure the cache is initialized before selecting it
  RtlxInitializeKnownCapabilities;

  case Mode of
    ctAppCapability:   Cache := AppCapabilities;
    ctGroupCapability: Cache := GroupCapabilities;
  else
    Cache := nil;
  end;

  // Find the matching SID
  Index := TArray.BinarySearchEx<TCapabilityEntry>(Cache,
    function (const Entry: TCapabilityEntry): Integer
    begin
      Result := RtlxCompareSids(Entry.Sid, Sid);
    end
  );

  Result := Index >= 0;

  if Result then
    SidUser := Cache[Index].Name;
end;

function RtlxEnumerateKnownCapabilities;
begin
  RtlxInitializeKnownCapabilities;

  // Collect all names
  Result := TArray.Map<TCapabilityEntry, String>(
    GroupCapabilities,
    function (const Entry: TCapabilityEntry): String
    begin
      if AddPrefix <> '' then
        Result := AddPrefix + Entry.Name
      else
        Result := Entry.Name;
    end
  );
end;

initialization
  if RtlOsVersionAtLeast(OsWin10) then
  begin
    RtlxRegisterSidNameRecognizer(RtlxRecognizeCapabilitySIDs);
    RtlxRegisterSidNameProvider(RtlxProvideCapabilitySIDs);
  end;
end.
