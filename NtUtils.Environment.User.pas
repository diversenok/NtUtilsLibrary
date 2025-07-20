unit NtUtils.Environment.User;

{
  The functions for constructing user environment using a token.
}

interface

uses
  Ntapi.ntseapi, Ntapi.Versions, NtUtils;

const
  TOKEN_CREATE_ENVIRONMEMT = TOKEN_QUERY or TOKEN_DUPLICATE or TOKEN_IMPERSONATE;

// Prepare an environment for a user. If the token is not specified, the
// function returns only system environmental variables
function UnvxCreateUserEnvironment(
  out Environment: IEnvironment;
  [opt, Access(TOKEN_CREATE_ENVIRONMEMT)] hxToken: IHandle = nil;
  InheritCurrent: Boolean = False
): TNtxStatus;

// Update environment for an AppContainer
[MinOSVersion(OsWin10)]
function UnvxUpdateAppContainerEnvironment(
  var Environment: IEnvironment;
  [Access(TOKEN_QUERY)] const hxToken: IHandle;
  [opt] const AppContainerSidOverride: ISid = nil
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.UserEnv, NtUtils.Ldr, NtUtils.Tokens, NtUtils.Tokens.Info,
  NtUtils.Environment, NtUtils.Profiles.AppContainer;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function UnvxCreateUserEnvironment;
var
  hToken: THandle;
  EnvBlock: PEnvironment;
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
  Environment := RtlxCaptureEnvironment(EnvBlock, 0);
end;

function UnvxUpdateAppContainerEnvironment;
var
  AppContainer: ISid;
  ProfilePath, TempPath: String;
begin
  // Determine the AppContainer SID
  if not Assigned(AppContainerSidOverride) then
  begin
    Result := NtxQuerySidToken(hxToken, TokenAppContainerSid, AppContainer);

    if not Result.IsSuccess then
      Exit;

    // Nothing to do if not AppContaier
    if not Assigned(AppContainer) then
      Exit(NtxSuccess);
  end
  else
    AppContainer := AppContainerSidOverride;

  // Obtain the profile path
  Result := UnvxQueryAppContainerPathFromToken(ProfilePath, hxToken,
    AppContainer);

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
