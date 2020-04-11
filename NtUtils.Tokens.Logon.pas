unit NtUtils.Tokens.Logon;

interface

uses
  Winapi.WinNt, Winapi.WinBase, Winapi.NtSecApi, Ntapi.ntseapi,
  NtUtils, NtUtils.Security.Sid, NtUtils.Objects;

// Logon a user
function NtxLogonUser(out hxToken: IHandle; Domain, Username: String;
  Password: PWideChar; LogonType: TSecurityLogonType; AdditionalGroups:
  TArray<TGroup> = nil): TNtxStatus;

// Logon a user without a password using S4U logon
function NtxLogonS4U(out hxToken: IHandle; Domain, Username: String;
  const TokenSource: TTokenSource; AdditionalGroups: TArray<TGroup> = nil):
  TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Processes.Query, NtUtils.Tokens.Misc,
  DelphiUtils.AutoObject;

function NtxLogonUser(out hxToken: IHandle; Domain, Username: String;
  Password: PWideChar; LogonType: TSecurityLogonType; AdditionalGroups:
  TArray<TGroup>): TNtxStatus;
var
  hToken: THandle;
  GroupsBuffer: IMemory<PTokenGroups>;
begin
  if Length(AdditionalGroups) = 0 then
  begin
    // Use regular LogonUserW if the caller did not specify additional groups
    Result.Location := 'LogonUserW';
    Result.Win32Result := LogonUserW(PWideChar(Username), PWideChar(Domain),
      Password, LogonType, LOGON32_PROVIDER_DEFAULT, hToken);

    if Result.IsSuccess then
      hxToken := TAutoHandle.Capture(hToken);
  end
  else
  begin
    // Prepare groups
    GroupsBuffer := NtxpAllocGroups2(AdditionalGroups);

    // Call LogonUserExExW that allows us to add arbitrary groups to a token.
    Result.Location := 'LogonUserExExW';

    // Note: LogonUserExExW returns ERROR_ACCESS_DENIED where it
    // should return ERROR_PRIVILEGE_NOT_HELD which is confusing.
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

    Result.Win32Result := LogonUserExExW(PWideChar(Username), PWideChar(Domain),
      Password, LogonType, LOGON32_PROVIDER_DEFAULT, GroupsBuffer.Data,
      hToken, nil, nil, nil, nil);

    if Result.IsSuccess then
      hxToken := TAutoHandle.Capture(hToken);
  end;
end;

function NtxLogonS4U(out hxToken: IHandle; Domain, Username: String;
  const TokenSource: TTokenSource; AdditionalGroups: TArray<TGroup>):
  TNtxStatus;
var
  hToken: THandle;
  SubStatus: NTSTATUS;
  LsaHandle: TLsaHandle;
  PkgName: ANSI_STRING;
  AuthPkg: Cardinal;
  Buffer: PKERB_S4U_LOGON;
  BufferSize: Cardinal;
  OriginName: ANSI_STRING;
  GroupArray: IMemory<PTokenGroups>;
  ProfileBuffer: Pointer;
  ProfileSize: Cardinal;
  LogonId: TLogonId;
  Quotas: TQuotaLimits;
begin
{$IFDEF Win32}
  // TODO -c WoW64: LsaLogonUser overwrites our memory for some reason
  if RtlxAssertNotWoW64(Result) then
    Exit;
{$ENDIF}

  // Connect to LSA
  Result.Location := 'LsaConnectUntrusted';
  Result.Status := LsaConnectUntrusted(LsaHandle);

  // Lookup for Negotiate package
  PkgName.FromString(NEGOSSP_NAME_A);
  Result.Location := 'LsaLookupAuthenticationPackage';
  Result.Status := LsaLookupAuthenticationPackage(LsaHandle, PkgName, AuthPkg);

  if not Result.IsSuccess then
  begin
    LsaDeregisterLogonProcess(LsaHandle);
    Exit;
  end;

  // We need to prepare a blob where KERB_S4U_LOGON is followed by the username
  // and the domain.
  BufferSize := SizeOf(KERB_S4U_LOGON) + Length(Username) * SizeOf(WideChar) +
    Length(Domain) * SizeOf(WideChar);
  Buffer := AllocMem(BufferSize);

  Buffer.MessageType := KerbS4ULogon;

  Buffer.ClientUpn.Length := Length(Username) * SizeOf(WideChar);
  Buffer.ClientUpn.MaximumLength := Buffer.ClientUpn.Length;

  // Place the username just after the structure
  Buffer.ClientUpn.Buffer := Pointer(NativeUInt(Buffer) +
    SizeOf(KERB_S4U_LOGON));
  Move(PWideChar(Username)^, Buffer.ClientUpn.Buffer^, Buffer.ClientUpn.Length);

  Buffer.ClientRealm.Length := Length(Domain) * SizeOf(WideChar);
  Buffer.ClientRealm.MaximumLength := Buffer.ClientRealm.Length;

  // Place the domain after the username
  Buffer.ClientRealm.Buffer := Pointer(NativeUInt(Buffer) +
    SizeOf(KERB_S4U_LOGON) + Buffer.ClientUpn.Length);
  Move(PWideChar(Domain)^, Buffer.ClientRealm.Buffer^,
    Buffer.ClientRealm.Length);

  OriginName.FromString('S4U');

  // Allocate PTokenGroups if necessary
  if Length(AdditionalGroups) > 0 then
    GroupArray := NtxpAllocGroups2(AdditionalGroups)
  else
    GroupArray := nil;

  // Perform the logon
  SubStatus := STATUS_SUCCESS;
  Result.Location := 'LsaLogonUser';
  Result.Status := LsaLogonUser(LsaHandle, OriginName, LogonTypeNetwork,
    AuthPkg, Buffer, BufferSize, GroupArray.Data, TokenSource, ProfileBuffer,
    ProfileSize, LogonId, hToken, Quotas, SubStatus);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(hToken);

  // Note: LsaLogonUser returns STATUS_ACCESS_DENIED where it
  // should return STATUS_PRIVILEGE_NOT_HELD which is confusing.

  if Length(AdditionalGroups) > 0 then
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

  // Prefer a more detailed status
  if not NT_SUCCESS(SubStatus) then
    Result.Status := SubStatus;
    
  // Clean up
  LsaFreeReturnBuffer(ProfileBuffer);
  LsaDeregisterLogonProcess(LsaHandle);

  FreeMem(Buffer);  
end;

end.
