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

// Convert a SID to an AppContainer name
function RtlxAppContainerSidToName(Sid: ISid; out Name: String): TNtxStatus;

// Get type of an SID
function RtlxGetAppContainerSidType(Sid: PSid): TAppContainerSidType;

// Get a SID of a parent AppContainer
function RtlxGetAppContainerParent(AppContainerSid: PSid;
  out AppContainerParent: ISid): TNtxStatus;

implementation

uses
  Ntapi.ntdef, NtUtils.Ldr, Winapi.UserEnv;

function RtlxLookupCapability(Name: String; out CapabilityGroupSid,
  CapabilitySid: ISid): TNtxStatus;
const
  CAP_GROUP_SUB_AUTHORITIES = 9;
  CAP_SID_SUB_AUTHORITIES = 10;
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
    BufferGroup := AllocMem(RtlLengthRequiredSid(CAP_GROUP_SUB_AUTHORITIES));
    BufferSid := AllocMem(RtlLengthRequiredSid(CAP_SID_SUB_AUTHORITIES));

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

function RtlxAppContainerSidToName(Sid: ISid; out Name: String): TNtxStatus;
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
  Result.HResult := AppContainerLookupMoniker(Sid.Sid, Buffer);

  if Result.IsSuccess then
  begin
    Name := String(Buffer);
    AppContainerFreeMemory(Buffer);
  end;
end;

function RtlxGetAppContainerSidType(Sid: PSid): TAppContainerSidType;
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
