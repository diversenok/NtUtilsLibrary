unit NtUtils.Environment.User;

{
  The functions for constructing user environment using a token.
}

interface

uses
  Winapi.WinNt, Ntapi.ntseapi, NtUtils;

const
  TOKEN_CREATE_ENVIRONMEMT = TOKEN_QUERY or TOKEN_DUPLICATE or TOKEN_IMPERSONATE;

// Prepare an environment for a user. If the token is zero the function
// returns only system environmental variables. Supports AppContainers.
function UnvxCreateUserEnvironment(
  out Environment: IEnvironment;
  [opt] hToken: THandle;
  InheritCurrent: Boolean = False;
  FixAppContainers: Boolean = True
): TNtxStatus;

// Update an environment to point to correct folders in case of AppContainer
function UnvxUpdateAppContainterEnvironment(
  var Environment: IEnvironment;
  [in] AppContainerSid: PSid
): TNtxStatus;

implementation

uses
  Winapi.UserEnv, NtUtils.Profiles, NtUtils.Ldr, NtUtils.Tokens,
  NtUtils.Tokens.Query, NtUtils.Security.Sid, NtUtils.Version,
  NtUtils.Environment;

function UnvxCreateUserEnvironment;
var
  hxToken: IHandle;
  EnvBlock: PEnvironment;
  Package: ISid;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'CreateEnvironmentBlock');

  if not Result.IsSuccess then
    Exit;

  // Handle pseudo-tokens
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_CREATE_ENVIRONMEMT);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'CreateEnvironmentBlock';
  Result.LastCall.Expects<TTokenAccessMask>(TOKEN_CREATE_ENVIRONMEMT);

  Result.Win32Result := CreateEnvironmentBlock(EnvBlock, hxToken.Handle,
    InheritCurrent);

  // Capture the environment
  if Result.IsSuccess then
    Environment := RtlxCaptureEnvironment(EnvBlock)
  else
    Exit;

  // On Win8+ we might need to fix AppContainer profile path
  if FixAppContainers and (hToken <> 0) and RtlOsVersionAtLeast(OsWin8) then
  begin
    // Get the package SID
    Result := NtxQuerySidToken(hToken, TokenAppContainerSid, Package);

    if not Result.IsSuccess then
      Exit;

    // Fix AppContainer paths
    if Result.IsSuccess and Assigned(Package) then
      Result := UnvxUpdateAppContainterEnvironment(Environment, Package.Data);
  end;
end;

function UnvxUpdateAppContainterEnvironment;
var
  ProfilePath, TempPath: String;
begin
  // Obtain the profile path
  Result := UnvxQueryFolderAppContainer(AppContainerSid, ProfilePath);

  if not Result.IsSuccess then
    Exit;

  // Fix AppData
  Result := RtlxSetVariableEnvironment(Environment, 'LOCALAPPDATA', ProfilePath);

  // Fix Temp
  TempPath := ProfilePath + '\Temp';

  if Result.IsSuccess then
    Result := RtlxSetVariableEnvironment(Environment, 'TEMP', TempPath);

  if Result.IsSuccess then
    Result := RtlxSetVariableEnvironment(Environment, 'TMP', TempPath);
end;

end.
