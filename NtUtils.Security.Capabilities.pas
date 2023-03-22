unit NtUtils.Security.Capabilities;

{
  This module adds support for representing and recognizing capability SIDs.

  Adding the module as a dependency enhances the following functions on
  Windows 10 and above:
   - RtlxStringToSid
   - RtlxLookupSidInCustomProviders
   - LsaxLookupSids
}

interface

uses
  NtUtils;

const
  // Custom domain names for capability SIDs
  APP_CAPABILITY_DOMAIN = 'APP CAPABILITY';
  GROUP_CAPABILITY_DOMAIN = 'GROUP CAPABILITY';

// Retrieve the list of known capability names
function RtlxEnumerateKnownCapabilities(
  const AddPrefix: String = ''
): TArray<String>;

implementation

uses
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.ImageHlp, Ntapi.Versions, NtUtils.Ldr,
  NtUtils.SysUtils, NtUtils.Security.Sid, NtUtils.Security.AppContainer,
  NtUtils.Lsa.Sid, DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

// Embed the list of known capabilities
{$RESOURCE NtUtils.Security.Capabilities.res}

type
  TSidEntry = record
    Sid: ISid;
    Name: String;
  end;

var
  // Cache for lookup
  CapabilitiesInitialized: Boolean;
  AppCapabilities: TArray<TSidEntry>;
  GroupCapabilities: TArray<TSidEntry>;

function RtlxCompareSidEntries(const A, B: TSidEntry): Integer;
begin
   Result := RtlxCompareSids(A.Sid, B.Sid);
end;

function InitializeCapabilities: TNtxStatus;
var
  Buffer: PAnsiMultiSz;
  BufferSize: Cardinal;
  Names: TArray<AnsiString>;
  Name: String;
  i, j: Integer;
begin
  if CapabilitiesInitialized then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // There is no apparent reason why the operation would fail once but not twice
  CapabilitiesInitialized := True;

  // Check if the OS supports capability SIDs
  Result := LdrxCheckNtDelayedImport('RtlDeriveCapabilitySidsFromName');

  if not Result.IsSuccess then
    Exit;

  // Find the embedded resource with the list of capability names
  Result := LdrxFindResourceData(
    Pointer(@ImageBase),
    'CAPABILITIES',
    RT_RCDATA,
    LANG_NEUTRAL or (SUBLANG_NEUTRAL shl SUBLANGID_SHIFT),
    Pointer(Buffer),
    BufferSize
  );

  if not Result.IsSuccess then
    Exit;

  // Extract all known capability names
  Names := RtlxParseAnsiMultiSz(Buffer, BufferSize);

  // We store app and group capabilities separately. While most of them
  // use the same sub authorities derived from the capability name, there are
  // several legacy entries that make it impossible to sort both types at the
  // same time.
  SetLength(AppCapabilities, Length(Names));
  SetLength(GroupCapabilities, Length(Names));

  j := 0;

  for i := 0 to High(Names) do
  begin
    Name := String(Names[i]);

    // Prepare both SIDs at once
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
  TArray.SortInline<TSidEntry>(AppCapabilities, RtlxCompareSidEntries);
  TArray.SortInline<TSidEntry>(GroupCapabilities, RtlxCompareSidEntries);
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
begin
  Name := StringSid;

  if RtlxPrefixStripString(APP_CAPABILITY_PREFIX, Name) then
    Mode := ctAppCapability
  else if RtlxPrefixStripString(GROUP_CAPABILITY_PREFIX, Name) then
    Mode := ctGroupCapability
  else
    Exit(False);

  Result := RtlxDeriveCapabilitySid(Sid, Name, Mode).IsSuccess;
end;

function RtlxProvideCapabilitySIDs(
  const Sid: ISid;
  out SidType: TSidNameUse;
  out SidDomain: String;
  out SidUser: String
): Boolean;
var
  Index: Integer;
  Mode: TCapabilityType;
  Cache: TArray<TSidEntry>;
begin
  Result := False;

  // Skip unsupported OS versions
  if not RtlOsVersionAtLeast(OsWin10) then
    Exit;

  if (RtlxIdentifierAuthoritySid(Sid) = SECURITY_APP_PACKAGE_AUTHORITY) and (
    (RtlSubAuthorityCountSid(Sid.Data)^ = SECURITY_BUILTIN_CAPABILITY_RID_COUNT)
    or (RtlSubAuthorityCountSid(Sid.Data)^ =
    SECURITY_INSTALLER_CAPABILITY_RID_COUNT)) and
    (RtlSubAuthoritySid(Sid.Data, 0)^ = SECURITY_CAPABILITY_BASE_RID) then
  begin
    Mode := ctAppCapability;
    SidDomain := APP_CAPABILITY_DOMAIN;
  end
  else if (RtlxIdentifierAuthoritySid(Sid) = SECURITY_NT_AUTHORITY) and
    (RtlSubAuthorityCountSid(Sid.Data)^ =
    SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT) and
    (RtlSubAuthoritySid(Sid.Data, 0)^ =
    SECURITY_INSTALLER_GROUP_CAPABILITY_BASE) then
  begin
    Mode := ctGroupCapability;
    SidDomain := GROUP_CAPABILITY_DOMAIN;
  end
  else
    Exit;

  // Make sure the cache is initialized
  if not InitializeCapabilities.IsSuccess then
    Exit;

  case Mode of
    ctAppCapability:   Cache := AppCapabilities;
    ctGroupCapability: Cache := GroupCapabilities;
  else
    Cache := nil;
  end;

  // Try to find the SID
  Index := TArray.BinarySearchEx<TSidEntry>(Cache,
    function (const Entry: TSidEntry): Integer
    begin
      Result := RtlxCompareSids(Entry.Sid, Sid);
    end
  );

  Result := Index >= 0;

  if Result then
  begin
    SidType := SidTypeWellKnownGroup;
    SidUser := Cache[Index].Name;
  end;
end;

function RtlxEnumerateKnownCapabilities;
begin
  // Return the entries from the cache
  if InitializeCapabilities.IsSuccess then
    Result := TArray.Map<TSidEntry, String>(GroupCapabilities,
      function (const Entry: TSidEntry): String
      begin
        if AddPrefix <> '' then
          Result := AddPrefix + Entry.Name
        else
          Result := Entry.Name;
      end
    )
  else
    Result := nil;
end;

initialization
  if RtlOsVersionAtLeast(OsWin10) then
  begin
    RtlxRegisterSidNameRecognizer(RtlxRecognizeCapabilitySIDs);
    RtlxRegisterSidNameProvider(RtlxProvideCapabilitySIDs);
  end;
end.
