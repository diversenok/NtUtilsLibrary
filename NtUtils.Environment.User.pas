unit NtUtils.Environment.User;

interface

uses
  NtUtils.Environment, NtUtils.Exceptions, Ntapi.ntseapi;

const
  TOKEN_CREATE_ENVIRONMEMT = TOKEN_QUERY or TOKEN_DUPLICATE or TOKEN_IMPERSONATE;

// Prepare an environment for a user. If the token is zero the function
// returns only system environmental variables. Supports AppContainers.
function UnvxCreateUserEnvironment(out Environment: IEnvironment;
  hToken: THandle; InheritCurrent: Boolean = False): TNtxStatus;

// Prepare an environment for a user. Does not support AppContainers.
function UnvxpCreateUserEnvironment(out Environment: IEnvironment;
  hToken: THandle; InheritCurrent: Boolean = False): TNtxStatus;

// Update an environment to point to correct folders in case of AppContainer
function UnvxUpdateAppContainterEnvironment(var Environment: IEnvironment;
  AppContainerSid: String): TNtxStatus;

implementation

uses
  Winapi.WinNt, Winapi.UserEnv, NtUtils.Profiles, NtUtils.Ldr,
  NtUtils.Tokens, NtUtils.Tokens.Query, NtUtils.Security.Sid, NtUtils.Version;

function UnvxCreateUserEnvironment(out Environment: IEnvironment;
  hToken: THandle; InheritCurrent: Boolean): TNtxStatus;
var
  Package: ISid;
begin
  // On Win8+ we might need to fix AppContainer profile path
  if (hToken <> 0) and RtlOsVersionAtLeast(OsWin8) then
  begin
    // Get the package SID
    Result := NtxQuerySidToken(hToken, TokenAppContainerSid, Package);

    if not Result.IsSuccess then
      Exit;
  end
  else
    Package := nil;

  // Get environment for the user
  Result := UnvxpCreateUserEnvironment(Environment, hToken, InheritCurrent);

  // Fix AppContainer paths
  if Result.IsSuccess and Assigned(Package) then
    Result := UnvxUpdateAppContainterEnvironment(Environment, Package.SDDL);
end;

function UnvxpCreateUserEnvironment(out Environment: IEnvironment;
  hToken: THandle; InheritCurrent: Boolean): TNtxStatus;
var
  hxToken: IHandle;
  EnvBlock: Pointer;
begin
  Result := LdrxCheckModuleDelayedImport(userenv, 'CreateEnvironmentBlock');

  if not Result.IsSuccess then
    Exit;

  // Handle pseudo-tokens
  Result := NtxExpandPseudoToken(hxToken, hToken, TOKEN_CREATE_ENVIRONMEMT);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'CreateEnvironmentBlock';
  Result.LastCall.Expects(TOKEN_CREATE_ENVIRONMEMT, @TokenAccessType);

  Result.Win32Result := CreateEnvironmentBlock(EnvBlock, hxToken.Handle,
    InheritCurrent);

  if Result.IsSuccess then
    Environment := TEnvironment.CreateOwned(EnvBlock);
end;

function UnvxUpdateAppContainterEnvironment(var Environment: IEnvironment;
  AppContainerSid: String): TNtxStatus;
var
  ProfilePath, TempPath: String;
begin
  // Obtain the profile path
  Result := UnvxQueryFolderAppContainer(AppContainerSid, ProfilePath);

  if not Result.IsSuccess then
    Exit;

  // Fix AppData
  Result := Environment.SetVariable('LOCALAPPDATA', ProfilePath);

  // Fix Temp
  TempPath := ProfilePath + '\Temp';
  if Result.IsSuccess then Result := Environment.SetVariable('TEMP', TempPath);
  if Result.IsSuccess then Result := Environment.SetVariable('TMP', TempPath);
end;

end.
