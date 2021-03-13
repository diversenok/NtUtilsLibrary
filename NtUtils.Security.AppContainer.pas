unit NtUtils.Security.AppContainer;

{
  This module includes routines for working with AppContainer and capability
  SIDs.
}

interface

uses
  Winapi.WinNt, Ntapi.ntrtl, NtUtils;

{ Capabilities }

// Convert a capability name to a SID
function RtlxLookupCapability(
  Name: String;
  out CapGroupSid: ISid;
  out CapSid: ISid
): TNtxStatus;

// Convert multiple capability names to a SIDs
function RtlxLookupCapabilities(
  Names: TArray<String>;
  out Capabilities: TArray<TGroup>
): TNtxStatus;

{ AppContainer }

// Convert an AppContainer name to a SID
function RtlxAppContainerNameToSid(
  Name: String;
  out Sid: ISid
): TNtxStatus;

// Get a child AppContainer SID based on its name and parent
function RtlxAppContainerChildNameToSid(
  ParentSid: ISid;
  Name: String;
  out ChildSid: ISid
): TNtxStatus;

// Convert a SID to an AppContainer name
function RtlxAppContainerSidToName(
  Sid: PSid;
  out Name: String
): TNtxStatus;

// Get type of an SID
function RtlxAppContainerType(
  Sid: PSid
): TAppContainerSidType;

// Get a SID of a parent AppContainer
function RtlxAppContainerParent(
  AppContainerSid: PSid;
  out AppContainerParent: ISid
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, NtUtils.Ldr, Winapi.UserEnv, Ntapi.ntstatus, Ntapi.ntseapi,
  NtUtils.Security.Sid;

function RtlxLookupCapability;
begin
  Result := LdrxCheckNtDelayedImport('RtlDeriveCapabilitySidsFromName');

  if not Result.IsSuccess then
    Exit;

  IMemory(CapGroupSid) := TAutoMemory.Allocate(RtlLengthRequiredSid(
    SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT));

  IMemory(CapSid) := TAutoMemory.Allocate(RtlLengthRequiredSid(
    SECURITY_INSTALLER_CAPABILITY_RID_COUNT));

  Result.Location := 'RtlDeriveCapabilitySidsFromName';
  Result.Status := RtlDeriveCapabilitySidsFromName(TNtUnicodeString.From(Name),
    CapGroupSid.Data, CapSid.Data);
end;

function RtlxLookupCapabilities;
var
  i: Integer;
  CapGroup: ISid;
begin
  SetLength(Capabilities, Length(Names));

  for i := 0 to High(Capabilities) do
    with Capabilities[i] do
    begin
      Attributes := SE_GROUP_ENABLED_BY_DEFAULT or SE_GROUP_ENABLED;
      Result := RtlxLookupCapability(Names[i], CapGroup, Sid);

      if not Result.IsSuccess then
        Break;
    end;
end;

function RtlxAppContainerNameToSid;
var
  Buffer: PSid;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'AppContainerDeriveSidFromMoniker');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'AppContainerDeriveSidFromMoniker';
  Result.HResult := AppContainerDeriveSidFromMoniker(PWideChar(Name),
    Buffer);

  if Result.IsSuccess then
  begin
    Result := RtlxCopySid(Buffer, Sid);
    RtlFreeSid(Buffer);
  end;
end;

function RtlxAppContainerChildNameToSid;
var
  Sid: ISid;
  SubAuthorities: TArray<Cardinal>;
begin
  // Construct the SID manually by reproducing the behavior of
  // DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName

  if RtlxAppContainerType(ParentSid.Data) <> ParentAppContainerSidType then
  begin
    Result.Location := 'RtlxAppContainerRestrictedNameToSid';
    Result.Status := STATUS_INVALID_SID;
    Exit;
  end;

  // Construct an SID using the child's name as it is a parent's name
  Result := RtlxAppContainerNameToSid(Name, Sid);

  if not Result.IsSuccess then
    Exit;

  // Retrieve the last four sub-authorities
  SubAuthorities := RtlxSubAuthoritiesSid(Sid.Data);
  Delete(SubAuthorities, 0, Length(SubAuthorities) - 4);

  // Append all parent sub-authorities at the begginning (8 of 12 available)
  SubAuthorities := Concat(RtlxSubAuthoritiesSid(ParentSid.Data),
    SubAuthorities);

  // Make a child SID with these sub-authorities
  Result := RtlxNewSid(ChildSid, SECURITY_APP_PACKAGE_AUTHORITY, SubAuthorities);
end;

function RtlxAppContainerSidToName;
var
  Buffer: PWideChar;
begin
  Result := LdrxCheckModuleDelayedImport(kernelbase,
    'AppContainerLookupMoniker');

  if not Result.IsSuccess then
    Exit;

  Result := LdrxCheckModuleDelayedImport(kernelbase, 'AppContainerFreeMemory');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'AppContainerLookupMoniker';
  Result.HResult := AppContainerLookupMoniker(Sid, Buffer);

  if Result.IsSuccess then
  begin
    Name := String(Buffer);
    AppContainerFreeMemory(Buffer);
  end;
end;

function RtlxAppContainerType;
begin
  // If ntdll does not have this function then
  // the OS probably does not support appcontainers
  if not LdrxCheckNtDelayedImport('RtlGetAppContainerSidType').IsSuccess or
    not NT_SUCCESS(RtlGetAppContainerSidType(Sid, Result)) then
    Result := NotAppContainerSidType;
end;

function RtlxAppContainerParent;
var
  Buffer: PSid;
begin
  Result := LdrxCheckNtDelayedImport('RtlGetAppContainerParent');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlGetAppContainerParent';
  Result.Status := RtlGetAppContainerParent(AppContainerSid, Buffer);

  if Result.IsSuccess then
  begin
    Result := RtlxCopySid(Buffer, AppContainerParent);
    RtlFreeSid(Buffer);
  end;
end;

end.
