unit NtUtils.Profiles.AppContainer;

{
  The module provides support for working with AppContainer profiles.
}

interface

uses
  Ntapi.Versions, Ntapi.UserEnv, Ntapi.ntseapi, NtUtils;

type
  TFwxAppContainer = record
    AppContainerSid: ISid;
    UserSid: ISid;
    AppContainerName: String;
    DisplayName: String;
    Description: String;
    Capabilities: TArray<TGroup>;
    Binaries: TArray<String>;
    WorkingDirectory: String;
    PackageFullName: String;
  end;

// Create an AppContainer profile.
// When called from a parent AppContainer, it creates a child AppContainer.
[MinOSVersion(OsWin8)]
function UnvxCreateAppContainer(
  out Sid: ISid;
  const AppContainerName: String;
  [opt] DisplayName: String = '';
  [opt] Description: String = '';
  [opt] const Capabilities: TArray<TGroup> = nil;
  ProfileType: TAppContainerProfileType = APP_CONTAINER_PROFILE_TYPE_WIN32
): TNtxStatus;

// Delete an AppContainer profile.
// When called from a parent AppContainer, it deletes a child AppContainer.
[MinOSVersion(OsWin8)]
function UnvxDeleteAppContainer(
  const AppContainerName: String;
  ProfileType: TAppContainerProfileType = APP_CONTAINER_PROFILE_TYPE_WIN32
): TNtxStatus;

// Query AppContainer folder location
[MinOSVersion(OsWin10)]
function UnvxQueryAppContainerPath(
  out Path: String;
  const UserSid: ISid;
  const AppContainerSid: ISid
): TNtxStatus;

// Query AppContainer folder location by token
[MinOSVersion(OsWin10)]
function UnvxQueryAppContainerPathFromToken(
  out Path: String;
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  [opt] const AppContainerSidOverride: ISid = nil
): TNtxStatus;

{ Network Isolation Profiles }

// Retrieve AppContainer information from its firewall profile
[MinOSVersion(OsWin10TH1)]
function FwxQueryAppContainer(
  out Info: TFwxAppContainer;
  const AppContainerSid: ISid;
  [opt] UserSid: ISid = nil
): TNtxStatus;

// Retrieve AppContainer information from its firewall profile or firewall
// profile enumeration
[MinOSVersion(OsWin8)]
function FwxQueryAppContainerWithFallback(
  out Info: TFwxAppContainer;
  const AppContainerSid: ISid;
  [opt] UserSid: ISid = nil
): TNtxStatus;

// Enumerate AppContainer firewall profiles
[MinOSVersion(OsWin8)]
function FwxEnumerateAppContainers(
  out AppContainers: TArray<TFwxAppContainer>;
  Flags: TNetIsoFlags = 0
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.ntstatus, Ntapi.WinError, NtUtils.Ldr,
  NtUtils.Security.Sid, NtUtils.SysUtils, NtUtils.Tokens.Info,
  NtUtils.Security.AppContainer;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function UnvxCreateAppContainer;
var
  CapArray: TArray<TSidAndAttributes>;
  i: Integer;
  Buffer: PSid;
  BufferDeallocator: IDeferredOperation;
begin
  Result := LdrxCheckDelayedImport(delayed_CreateAppContainerProfileWorker);

  if not Result.IsSuccess then
    Exit;

  SetLength(CapArray, Length(Capabilities));

  for i := 0 to High(CapArray) do
  begin
    CapArray[i].Sid := Capabilities[i].Sid.Data;
    CapArray[i].Attributes := Capabilities[i].Attributes;
  end;

  // The function does not like empty strings
  if DisplayName = '' then
    DisplayName := AppContainerName;

  if Description = '' then
    Description := DisplayName;

  Result.Location := 'CreateAppContainerProfileWorker';
  Result.HResult := CreateAppContainerProfileWorker(PWideChar(AppContainerName),
    PWideChar(DisplayName), PWideChar(Description), CapArray, Length(CapArray),
    ProfileType, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferRtlFreeSid(Buffer);
  Result := RtlxCopySid(Buffer, Sid);
end;

function UnvxDeleteAppContainer;
begin
  Result := LdrxCheckDelayedImport(delayed_DeleteAppContainerProfileWorker);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DeleteAppContainerProfileWorker';
  Result.HResult := DeleteAppContainerProfileWorker(PWideChar(AppContainerName),
    ProfileType);
end;

function UnvxQueryAppContainerPath;
const
  INITIAL_SIZE = MAX_PATH * SizeOf(WideChar);
var
  UserSidString, AppContainerSidString: String;
  Buffer: IMemory;
begin
  Result := LdrxCheckDelayedImport(delayed_GetAppContainerPathFromSidString);

  if not Result.IsSuccess then
    Exit;

  // Prepare strings
  Result := RtlxSidToString(UserSid, UserSidString);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxSidToString(AppContainerSid, AppContainerSidString);

  if not Result.IsSuccess then
    Exit;

  Buffer := Auto.AllocateDynamic(INITIAL_SIZE);
  repeat
    Result.Location := 'GetAppContainerPathFromSidString';
    Result.HResult := GetAppContainerPathFromSidString(PWideChar(UserSidString),
      PWideChar(AppContainerSidString), Buffer.Data, Buffer.Size div
      SizeOf(WideChar));

    // Unfortunately, we need to guess the size
  until not NtxExpandBufferEx(Result, Buffer, Buffer.Size * 2 + 16, nil);

  if not Result.IsSuccess then
    Exit;

  Path := RtlxCaptureStringWithRange(Buffer.Data, Buffer.Offset(Buffer.Size));
end;

function UnvxQueryAppContainerPathFromToken;
var
  UserSid, AppContainerSid: ISid;
begin
  // Choose the AppContainer SID
  if not Assigned(AppContainerSidOverride) then
  begin
    Result := NtxQuerySidToken(hxToken, TokenAppContainerSid, AppContainerSid);

    if not Result.IsSuccess then
      Exit;

    if not Assigned(AppContainerSid) then
    begin
      Result.Location := 'UnvxQueryPathAppContainer';
      Result.Status := STATUS_NOT_APPCONTAINER;
      Exit;
    end;
  end
  else
    AppContainerSid := AppContainerSidOverride;

  // Determine the user SID
  Result := NtxQuerySidToken(hxToken, TokenUser, UserSid);

  if not Result.IsSuccess then
    Exit;

  // Query the path
  Result := UnvxQueryAppContainerPath(Path, UserSid, AppContainerSid);
end;

{ AppContainer Network Isolation }

function DeferNetworkIsolationFreeAppContainers(
  [in] Buffer: PInetFirewallAppContainer;
  [in] Count: Integer
): IDeferredOperation;
begin
  Result := Auto.Defer(
    procedure
    var
      Cursor: PInetFirewallAppContainer;
      CapabilityBuffer: PSidAndAttributes;
      BinaryBuffer: PPWideChar;
      i, j: Integer;
    begin
      if not LdrxCheckDelayedImport(
        delayed_NetworkIsolationFreeAppContainers).IsSuccess then
        Exit;

      Cursor := Buffer;

      for i := 0 to Pred(Count) do
      begin
        NetworkIsolationFreeAppContainers(Cursor.AppContainerSid);
        NetworkIsolationFreeAppContainers(Cursor.UserSid);
        NetworkIsolationFreeAppContainers(Cursor.AppContainerName);
        NetworkIsolationFreeAppContainers(Cursor.DisplayName);
        NetworkIsolationFreeAppContainers(Cursor.Description);

        CapabilityBuffer := Cursor.Capabilities.Capabilities;
        for j := 0 to Pred(Cursor.Capabilities.Count) do
        begin
          NetworkIsolationFreeAppContainers(CapabilityBuffer.SID);
          Inc(CapabilityBuffer);
        end;
        NetworkIsolationFreeAppContainers(Cursor.Capabilities.Capabilities);

        BinaryBuffer := Cursor.Binaries.Binaries;
        for j := 0 to Pred(Cursor.Binaries.Count) do
        begin
          NetworkIsolationFreeAppContainers(BinaryBuffer^);
          Inc(BinaryBuffer);
        end;
        NetworkIsolationFreeAppContainers(Cursor.Binaries.Binaries);

        NetworkIsolationFreeAppContainers(Cursor.WorkingDirectory);
        NetworkIsolationFreeAppContainers(Cursor.PackageFullName);
        Inc(Cursor);
      end;

      NetworkIsolationFreeAppContainers(Buffer);
    end
  );
end;

function FwxCaptureAppContainerBuffer(
  out Info: TFwxAppContainer;
  [in] Buffer: PInetFirewallAppContainer
): TNtxStatus;
var
  CapabilityBuffer: PSidAndAttributes;
  BinaryBuffer: PPWideChar;
  i: Integer;
begin
  // Collect SIDs
  Result := RtlxCopySid(Buffer.AppContainerSid, Info.AppContainerSid);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxCopySid(Buffer.UserSid, Info.UserSid);

  if not Result.IsSuccess then
    Exit;

  // Collect strings
  Info.AppContainerName := String(Buffer.AppContainerName);
  Info.DisplayName := String(Buffer.DisplayName);
  Info.Description := String(Buffer.Description);
  Info.WorkingDirectory := String(Buffer.WorkingDirectory);
  Info.PackageFullName := String(Buffer.PackageFullName);

  // Collect capabilities
  SetLength(Info.Capabilities, Buffer.Capabilities.Count);
  CapabilityBuffer := Buffer.Capabilities.Capabilities;

  for i := 0 to High(Info.Capabilities) do
  begin
    Result := RtlxCopySid(CapabilityBuffer.Sid, Info.Capabilities[i].Sid);

    if not Result.IsSuccess then
      Exit;

    Info.Capabilities[i].Attributes := CapabilityBuffer.Attributes;
    Inc(CapabilityBuffer);
  end;

  // Collect binaries
  SetLength(Info.Binaries, Buffer.Binaries.Count);
  BinaryBuffer := Buffer.Binaries.Binaries;

  for i := 0 to High(Info.Binaries) do
  begin
    Info.Binaries[i] := String(BinaryBuffer^);
    Inc(BinaryBuffer);
  end;
end;

function FwxQueryAppContainer;
var
  Buffer: PInetFirewallAppContainer;
  BufferDeallocator: IDeferredOperation;
begin
  Result := LdrxCheckDelayedImport(delayed_NetworkIsolationGetAppContainer);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(UserSid) then
  begin
    Result := NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, UserSid);

    if not Result.IsSuccess then
      Exit;
  end;

  Result.Location := 'NetworkIsolationGetAppContainer';
  Result.Win32ErrorOrSuccess := NetworkIsolationGetAppContainer(0,
    UserSid.Data, AppContainerSid.Data, Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferNetworkIsolationFreeAppContainers(Buffer, 1);
  Result := FwxCaptureAppContainerBuffer(Info, Buffer);
end;

function FwxQueryAppContainerWithFallback;
var
  Flags: TNetIsoFlags;
  AppContainers: TArray<TFwxAppContainer>;
  i: Integer;
begin
  case RtlxGetAppContainerType(AppContainerSid) of
    ParentAppContainerSidType:
      Flags := 0;
    ChildAppContainerSidType:
      Flags := NETISO_FLAG_REPORT_INCLUDE_CHILD_AC;
  else
    Result.Location := 'FwxQueryAppContainerWithFallback';
    Result.Status := ERROR_INVALID_PARAMETER;
    Exit;
  end;

  if not Assigned(UserSid) then
  begin
    Result := NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, UserSid);

    if not Result.IsSuccess then
      Exit;
  end;

  if LdrxCheckDelayedImport(delayed_NetworkIsolationGetAppContainer)
    .IsSuccess then
  begin
    // Try querying first
    Result := FwxQueryAppContainer(Info, AppContainerSid, UserSid);

    if Result.IsSuccess or (Result.IsWin32 and (Result.Win32Error =
      ERROR_FILE_NOT_FOUND)) then
      Exit;
  end;

  // Fall back to enumeration since querying might fail due to access denied or
  // an older OS version
  Result := FwxEnumerateAppContainers(AppContainers, Flags);

  if not Result.IsSuccess then
    Exit;

  for i := 0 to High(AppContainers) do
    if RtlxEqualSids(AppContainers[i].AppContainerSid, AppContainerSid) and
      RtlxEqualSids(AppContainers[i].UserSid, UserSid) then
    begin
      Info := AppContainers[i];
      Exit;
    end;

  Result.Location := 'FwxQueryAppContainerWithFallback';
  Result.Status := STATUS_NOT_FOUND;
end;

function FwxEnumerateAppContainers;
var
  Count: Cardinal;
  Buffer: PInetFirewallAppContainer;
  BufferDeallocator: IDeferredOperation;
  i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_NetworkIsolationEnumAppContainers);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NetworkIsolationEnumAppContainers';
  Result.Win32ErrorOrSuccess := NetworkIsolationEnumAppContainers(Flags, Count,
    Buffer);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := DeferNetworkIsolationFreeAppContainers(Buffer, Count);
  SetLength(AppContainers, Count);

  for i := 0 to High(AppContainers) do
  begin
    Result := FwxCaptureAppContainerBuffer(AppContainers[i], Buffer);
    Inc(Buffer);
  end;
end;

end.
