unit NtUtils.Tokens.Logon;

interface

uses
  Winapi.WinNt, Winapi.WinBase, Winapi.NtSecApi, Ntapi.ntseapi, NtUtils,
  NtUtils.Objects;

// Logon a user
function LsaxLogonUser(out hxToken: IHandle; Domain, Username: String;
  Password: PWideChar; LogonType: TSecurityLogonType; AdditionalGroups:
  TArray<TGroup> = nil): TNtxStatus;

// Logon a user without a password using S4U logon
function LsaxLogonS4U(out hxToken: IHandle; Domain, Username: String;
  const TokenSource: TTokenSource; AdditionalGroups: TArray<TGroup> = nil):
  TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Processes.Query, NtUtils.Tokens.Misc,
  DelphiUtils.AutoObject, NtUtils.Lsa;

function LsaxLogonUser(out hxToken: IHandle; Domain, Username: String;
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

function LsaxLogonS4U(out hxToken: IHandle; Domain, Username: String;
  const TokenSource: TTokenSource; AdditionalGroups: TArray<TGroup>):
  TNtxStatus;
var
  hToken: THandle;
  SubStatus: NTSTATUS;
  LsaHandle: ILsaHandle;
  AuthPkg: Cardinal;
  Buffer: IMemory<PKERB_S4U_LOGON>;
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

  // We need to prepare a self-contained buffer
  IMemory(Buffer) := TAutoMemory.Allocate(SizeOf(KERB_S4U_LOGON) +
    Succ(Length(Username)) * SizeOf(WideChar) +
    Succ(Length(Domain)) * SizeOf(WideChar));

  Buffer.Data.MessageType := KerbS4ULogon;

  // Serialize the username, placing it after the structure
  TLsaUnicodeString.Marshal(Username, @Buffer.Data.ClientUPN,
    Buffer.Offset(SizeOf(KERB_S4U_LOGON)));

  // Serialize the domain, placing it after the username
  TLsaUnicodeString.Marshal(Domain, @Buffer.Data.ClientRealm,
    Buffer.Offset(SizeOf(KERB_S4U_LOGON) +
    Succ(Length(Username)) * SizeOf(WideChar)));

  // Note: LsaLogonUser returns STATUS_ACCESS_DENIED where it
  // should return STATUS_PRIVILEGE_NOT_HELD which is confusing.
  if Length(AdditionalGroups) > 0 then
  begin
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;
    GroupArray := NtxpAllocGroups2(AdditionalGroups);
  end
  else
    IMemory(GroupArray) := TAutoMemory.Allocate(0);

  // Perform the logon
  SubStatus := STATUS_SUCCESS;
  Result.Location := 'LsaLogonUser';
  Result.Status := LsaLogonUser(LsaHandle.Handle, TLsaAnsiString.From('S4U'),
    LogonTypeNetwork, AuthPkg, Buffer.Data, Buffer.Size, GroupArray.Data,
    TokenSource, ProfileBuffer, ProfileSize, LogonId, hToken, Quotas,
    SubStatus);

  if Result.IsSuccess then
  begin
    hxToken := TAutoHandle.Capture(hToken);
    LsaFreeReturnBuffer(ProfileBuffer);
  end
  else if not NT_SUCCESS(SubStatus) then
    Result.Status := SubStatus; // Prefer more detailed statuses on failure
end;

end.
