unit NtUiLib.WinCred;

interface

uses
  Ntapi.WinNt, Ntapi.wincred, Ntapi.WinUser, Ntapi.WinError, Ntapi.NtSecApi,
  NtUtils, NtUtils.Tokens.Logon;

// Show a Windows credentials prompt UI
function CredxPromptForWindowsCredentials(
  [opt] ParentHwnd: THwnd;
  const CaptionText: String;
  const MessageText: String;
  out Credentials: TLogonCredentials;
  [in] PromptFlags: TCredUiWinFlags = 0;
  [in] UnpackFlags: TCredPackFlags = 0;
  AuthPackage: AnsiString = NEGOSSP_NAME_A;
  [opt] AuthError: TWin32Error = ERROR_SUCCESS;
  [in, out, opt] Save: PLongBool = nil
): TNtxStatus;

implementation

uses
  Ntapi.ObjBase, NtUtils.Ldr, NtUtils.Lsa, NtUtils.Lsa.Sid, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function CredxDelayFree(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      CoTaskMemFree(Buffer);
    end
  );
end;

function CredxPromptForWindowsCredentials;
var
  Info: TCredUIInfoW;
  PackageId: Cardinal;
  OutAuthBuffer: Pointer;
  OutAuthBufferSize: Cardinal;
  OutAuthBufferDeallocator: IAutoReleasable;
  Domain, Username, Password: IMemory;
  DomainLength, UsernameLength, PasswordLength: Cardinal;
  FullName: String;
  TranslatedName: TTranslatedName;
begin
  Result := LdrxCheckDelayedImport(delayed_CredUIPromptForWindowsCredentialsW);

  if not Result.IsSuccess then
    Exit;

  Result := LdrxCheckDelayedImport(delayed_CredUnPackAuthenticationBufferW);

  if not Result.IsSuccess then
    Exit;

  Result := LsaxLookupAuthPackage(PackageId, AuthPackage);

  if not Result.IsSuccess then
    Exit;

  Info := Default(TCredUIInfoW);
  Info.Size := SizeOf(Info);
  Info.Parent := ParentHwnd;
  Info.MessageText := PWideChar(MessageText);
  Info.CaptionText := PWideChar(CaptionText);

  // Show the prompt
  Result.Location := 'CredUIPromptForWindowsCredentialsW';
  Result.Win32ErrorOrSuccess := CredUIPromptForWindowsCredentialsW(@Info,
    AuthError, PackageId, nil, 0, OutAuthBuffer, OutAuthBufferSize, Save,
    PromptFlags);

  if not Result.IsSuccess then
    Exit;

  OutAuthBufferDeallocator := CredxDelayFree(OutAuthBuffer);
  Domain := Auto.AllocateDynamic(0);
  Username := Auto.AllocateDynamic(0);
  Password := Auto.AllocateDynamic(0);

  repeat
    DomainLength := Domain.Size div SizeOf(WideChar);
    UsernameLength := Username.Size div SizeOf(WideChar);
    PasswordLength := Password.Size div SizeOf(WideChar);

    // Extract the credentials (which might be encrypted)
    Result.Location := 'CredUnPackAuthenticationBufferW';
    Result.Win32Result := CredUnPackAuthenticationBufferW(UnpackFlags,
      OutAuthBuffer, OutAuthBufferSize, Username.Data, UsernameLength,
      Domain.Data, DomainLength, Password.Data, PasswordLength);

  until not NtxExpandBufferEx(Result, Domain, Succ(DomainLength) *
    SizeOf(WideChar), nil) or not NtxExpandBufferEx(Result, Username,
    Succ(UsernameLength) * SizeOf(WideChar), nil) or not NtxExpandBufferEx(
    Result, Password, Succ(PasswordLength) * SizeOf(WideChar), nil);

  if not Result.IsSuccess then
    Exit;

  // Save the credentials
  Credentials := Default(TLogonCredentials);

  if DomainLength > 0 then
    SetString(Credentials.Domain, PWideChar(Domain.Data), Pred(DomainLength));

  if UsernameLength > 0 then
    SetString(Credentials.Username, PWideChar(Username.Data),
      Pred(UsernameLength));

  if PasswordLength > 0 then
    SetString(Credentials.Password, PWideChar(Password.Data),
      Pred(PasswordLength));

  // The function can return the domain inside the username; fix that with
  // canonicalization
  if Credentials.Domain <> '' then
    FullName := Credentials.Domain + '\' + Credentials.Username
  else
    FullName := Credentials.Username;

  Result := LsaxCanonicalizeName(FullName, TranslatedName);

  // When the user doesn't provide a domain, the function tends to append the
  // default one, which might be wrong. As a workaround, strip the domain and
  // retry canonicalization. Note that this problem doesn't happen with plaintext
  // credentials, so we skip them.
  if not Result.IsSuccess and
    not BitTest(PromptFlags and CREDUIWIN_GENERIC) then
    Result := LsaxCanonicalizeName(RtlxExtractNamePath(FullName),
      TranslatedName);

  if not Result.IsSuccess then
    Exit;

  Credentials.Domain := TranslatedName.DomainName;
  Credentials.Username := TranslatedName.UserName;
end;

end.
