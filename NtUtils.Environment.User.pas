unit NtUtils.Environment.User;

{
  The functions for constructing user environment using a token.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntseapi, NtUtils;

const
  TOKEN_CREATE_ENVIRONMEMT = TOKEN_QUERY or TOKEN_DUPLICATE or TOKEN_IMPERSONATE;

// Prepare an environment for a user. If the token is not specified, the
// function returns only system environmental variables. Supports AppContainers.
function UnvxCreateUserEnvironment(
  out Environment: IEnvironment;
  [opt, Access(TOKEN_CREATE_ENVIRONMEMT)] hxToken: IHandle = nil;
  InheritCurrent: Boolean = False;
  FixAppContainers: Boolean = True
): TNtxStatus;

// Update an environment to point to correct folders in case of AppContainer
function UnvxUpdateAppContainerEnvironment(
  var Environment: IEnvironment;
  const AppContainerSid: ISid
): TNtxStatus;

implementation

uses
  Ntapi.UserEnv, NtUtils.Profiles, NtUtils.Ldr, NtUtils.Tokens,
  NtUtils.Tokens.Info, NtUtils.Security.Sid, NtUtils.Objects, Ntapi.Versions,
  NtUtils.Environment;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function UnvxCreateUserEnvironment;
var
  hToken: THandle;
  EnvBlock: PEnvironment;
  Package: ISid;
begin
  Result := LdrxCheckDelayedImport(delayed_CreateEnvironmentBlock);

  if not Result.IsSuccess then
    Exit;

  if Assigned(hxToken) then
  begin
    // Add support for pseudo-handles
    Result := NtxExpandToken(hxToken, TOKEN_CREATE_ENVIRONMEMT);

    if not Result.IsSuccess then
      Exit;

    hToken := hxToken.Handle;
  end
  else
    hToken := 0; // System environment only

  Result.Location := 'CreateEnvironmentBlock';

  if hToken <> 0 then
    Result.LastCall.Expects<TTokenAccessMask>(TOKEN_CREATE_ENVIRONMEMT);

  Result.Win32Result := CreateEnvironmentBlock(EnvBlock, hToken,
    InheritCurrent);

  if not Result.IsSuccess then
    Exit;

  // Capturing the buffer will look up its size
  Environment:= RtlxCaptureEnvironment(EnvBlock, 0);

  // On Win8+ we might need to fix AppContainer profile path
  if FixAppContainers and Assigned(hxToken) and RtlOsVersionAtLeast(OsWin8) then
  begin
    // Get the package SID
    Result := NtxQuerySidToken(hxToken, TokenAppContainerSid, Package);

    if not Result.IsSuccess then
      Exit;

    // Fix AppContainer paths
    if Result.IsSuccess and Assigned(Package) then
      Result := UnvxUpdateAppContainerEnvironment(Environment, Package);
  end;
end;

function UnvxUpdateAppContainerEnvironment;
var
  ProfilePath, TempPath: String;
begin
  // Obtain the profile path
  Result := UnvxQueryFolderAppContainer(AppContainerSid, ProfilePath);

  if not Result.IsSuccess then
    Exit;

  // Fix AppData
  Result := RtlxSetVariableEnvironment('LOCALAPPDATA', ProfilePath, Environment);

  // Fix Temp
  TempPath := ProfilePath + '\Temp';

  if Result.IsSuccess then
    Result := RtlxSetVariableEnvironment('TEMP', TempPath, Environment);

  if Result.IsSuccess then
    Result := RtlxSetVariableEnvironment('TMP', TempPath, Environment);
end;

end.
