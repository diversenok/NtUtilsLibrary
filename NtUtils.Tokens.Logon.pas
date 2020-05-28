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
  DelphiUtils.AutoObject, NtUtils.Lsa;

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
  LsaHandle: ILsaHandle;
  AuthPkg: Cardinal;
  Buffer: IMemory<PKERB_S4U_LOGON>;
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
  Result := LsaxConnectUntrusted(LsaHandle);

  if not Result.IsSuccess then
    Exit;

  // Lookup the Negotiate package
  Result := LsaxLookupAuthPackage(AuthPkg, NEGOSSP_NAME_A, LsaHandle);

  if not Result.IsSuccess then
    Exit;

  // We need to prepare a blob where KERB_S4U_LOGON is followed by the username
  // and the domain.
  Buffer := TAutoMemory<PKERB_S4U_LOGON>.Allocate(SizeOf(KERB_S4U_LOGON) +
    Length(Username) * SizeOf(WideChar) + Length(Domain) * SizeOf(WideChar));

  Buffer.Data.MessageType := KerbS4ULogon;

  Buffer.Data.ClientUpn.Length := Length(Username) * SizeOf(WideChar);
  Buffer.Data.ClientUpn.MaximumLength := Buffer.Data.ClientUpn.Length;

  // Place the username just after the structure
  Buffer.Data.ClientUpn.Buffer := Buffer.Offset(SizeOf(KERB_S4U_LOGON));
  Move(PWideChar(Username)^, Buffer.Data.ClientUpn.Buffer^,
    Buffer.Data.ClientUpn.Length);

  Buffer.Data.ClientRealm.Length := Length(Domain) * SizeOf(WideChar);
  Buffer.Data.ClientRealm.MaximumLength := Buffer.Data.ClientRealm.Length;

  // Place the domain after the username
  Buffer.Data.ClientRealm.Buffer := Buffer.Offset(SizeOf(KERB_S4U_LOGON) +
    Buffer.Data.ClientUpn.Length);
  Move(PWideChar(Domain)^, Buffer.Data.ClientRealm.Buffer^,
    Buffer.Data.ClientRealm.Length);

  OriginName.FromString('S4U');

  // Note: LsaLogonUser returns STATUS_ACCESS_DENIED where it
  // should return STATUS_PRIVILEGE_NOT_HELD which is confusing.
  if Length(AdditionalGroups) > 0 then
  begin
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;
    GroupArray := NtxpAllocGroups2(AdditionalGroups);
  end
  else
    GroupArray := TAutoMemory<PTokenGroups>.Allocate(0);

  // Perform the logon
  SubStatus := STATUS_SUCCESS;
  Result.Location := 'LsaLogonUser';
  Result.Status := LsaLogonUser(LsaHandle.Handle, OriginName, LogonTypeNetwork,
    AuthPkg, Buffer.Data, Buffer.Size, GroupArray.Data, TokenSource,
    ProfileBuffer, ProfileSize, LogonId, hToken, Quotas, SubStatus);

  if Result.IsSuccess then
  begin
    hxToken := TAutoHandle.Capture(hToken);
    LsaFreeReturnBuffer(ProfileBuffer);
  end
  else if not NT_SUCCESS(SubStatus) then
    Result.Status := SubStatus; // Prefer more detailed statuses on failure
end;

end.
