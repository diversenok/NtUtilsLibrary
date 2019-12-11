unit NtUtils.Security.AppContainer;

interface

uses
  Winapi.WinNt, Ntapi.ntrtl, NtUtils.Exceptions, NtUtils.Security.Sid;

{ Capabilities }

// Convert a capability name to a SID
function RtlxLookupCapability(Name: String; out CapabilityGroupSid,
  CapabilitySid: ISid): TNtxStatus;

{ AppContainer }

// Convert an AppContainer name to a SID
function RtlxAppContainerNameToSid(Name: String; out Sid: ISid): TNtxStatus;

// Get a child AppContainer SID based on its name and parent
function RtlxAppContainerChildNameToSid(ParentSid: ISid; Name: String;
  out ChildSid: ISid): TNtxStatus;

// Convert a SID to an AppContainer name
function RtlxAppContainerSidToName(Sid: PSid; out Name: String): TNtxStatus;

// Get type of an SID
function RtlxGetAppContainerType(Sid: PSid): TAppContainerSidType;

// Get a SID of a parent AppContainer
function RtlxGetAppContainerParent(AppContainerSid: PSid;
  out AppContainerParent: ISid): TNtxStatus;

implementation

uses
  Ntapi.ntdef, NtUtils.Ldr, Winapi.UserEnv, Ntapi.ntstatus;

function RtlxLookupCapability(Name: String; out CapabilityGroupSid,
  CapabilitySid: ISid): TNtxStatus;
var
  BufferGroup, BufferSid: PSid;
  NameStr: UNICODE_STRING;
begin
  Result := LdrxCheckNtDelayedImport('RtlDeriveCapabilitySidsFromName');

  if not Result.IsSuccess then
    Exit;

  NameStr.FromString(Name);

  BufferGroup := nil;
  BufferSid := nil;

  try
    BufferGroup := AllocMem(RtlLengthRequiredSid(
      SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT));

    BufferSid := AllocMem(RtlLengthRequiredSid(
      SECURITY_INSTALLER_CAPABILITY_RID_COUNT));

    Result.Location := 'RtlDeriveCapabilitySidsFromName';
    Result.Status := RtlDeriveCapabilitySidsFromName(NameStr, BufferGroup,
      BufferSid);

    if Result.IsSuccess then
    begin
      CapabilityGroupSid := TSid.CreateCopy(BufferGroup);
      CapabilitySid := TSid.CreateCopy(BufferSid);
    end;
  finally
    FreeMem(BufferGroup);
    FreeMem(BufferSid);
  end;
end;

function RtlxAppContainerNameToSid(Name: String; out Sid: ISid): TNtxStatus;
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
    Sid := TSid.CreateCopy(Buffer);
    RtlFreeSid(Buffer);
  end;
end;

function RtlxAppContainerChildNameToSid(ParentSid: ISid; Name: String;
  out ChildSid: ISid): TNtxStatus;
var
  Sid: ISid;
  i: Integer;
  SubAuthorities: TArray<Cardinal>;
begin
  // Construct the SID manually by reproducing the behavior of
  // DeriveRestrictedAppContainerSidFromAppContainerSidAndRestrictedName

  if RtlxGetAppContainerType(ParentSid.Sid) <> ParentAppContainerSidType then
  begin
    Result.Location := 'RtlxAppContainerRestrictedNameToSid';
    Result.Status := STATUS_INVALID_SID;
    Exit;
  end;

  // Construct an SID using the child's name as it is a parent's name
  Result := RtlxAppContainerNameToSid(Name, Sid);

  if not Result.IsSuccess then
    Exit;

  SetLength(SubAuthorities, SECURITY_CHILD_PACKAGE_RID_COUNT);

  // Copy all parent sub-authorities (8 of 12 available)
  for i := 0 to ParentSid.SubAuthorities - 1 do
    SubAuthorities[i] := ParentSid.SubAuthority(i);

  // Append the last four child's sub-authorities to the SID
  for i := SECURITY_PARENT_PACKAGE_RID_COUNT to
    SECURITY_CHILD_PACKAGE_RID_COUNT - 1 do
    SubAuthorities[i] := Sid.SubAuthority(i - SECURITY_CHILD_PACKAGE_RID_COUNT
      + SECURITY_PARENT_PACKAGE_RID_COUNT);

  // Make a child SID with these sub-authorities
  ChildSid := TSid.Create(SECURITY_APP_PACKAGE_AUTHORITY, SubAuthorities);
end;

function RtlxAppContainerSidToName(Sid: PSid; out Name: String): TNtxStatus;
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

function RtlxGetAppContainerType(Sid: PSid): TAppContainerSidType;
begin
  // If ntdll does not have this function then
  // the OS probably does not support appcontainers
  if not LdrxCheckNtDelayedImport('RtlGetAppContainerSidType').IsSuccess or
    not NT_SUCCESS(RtlGetAppContainerSidType(Sid, Result)) then
    Result := NotAppContainerSidType;
end;

function RtlxGetAppContainerParent(AppContainerSid: PSid;
  out AppContainerParent: ISid): TNtxStatus;
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
    AppContainerParent := TSid.CreateCopy(Buffer);
    RtlFreeSid(Buffer);
  end;
end;

end.
