unit NtUtils.Tokens.Logon;

{
  The module introduces functions for logging users into the system via a
  normal and Services-for-Users logon.
}

interface

uses
  Ntapi.WinNt, Ntapi.WinBase, Ntapi.NtSecApi, Ntapi.ntseapi, NtUtils,
  NtUtils.Objects, DelphiApi.Reflection;

type
  TLogonInfoFields = set of (
    liToken,              // All
    liLogonId,            // All
    liQuotas,             // All
    liLogonCount,         // Interactive
    liBadPasswordCount,   // Interactive
    liLogonTime,          // Interactive
    liLogoffTime,         // Interactive, Lm20
    liKickOffTime,        // Interactive, Lm20
    liPasswordLastSet,    // Interactive
    liPasswordCanChange,  // Interactive
    liPasswordMustChange, // Interactive
    liLogonScript,        // Interactive
    liHomeDirectory,      // Interactive
    liHomeDirectoryDrive, // Interactive
    liFullName,           // Interactive
    liProfilePath,        // Interactive
    liLogonServer,        // Interactive, Lm20
    liUserFlags,          // Interactive, Lm20
    liUserSessionKey,     // Lm20
    liLogonDomainName,    // Lm20
    liLanmanSessionKey,   // Lm20
    liUserParameters      // Lm20
  );

  TLogonInfo = record
    ValidFields: TLogonInfoFields;
    hxToken: IHandle;
    LogonId: TLogonId;
    Quotas: TQuotaLimits;
    LogonCount: Word;
    BadPasswordCount: Word;
    LogonTime: TLargeInteger;
    LogoffTime: TLargeInteger;
    KickOffTime: TLargeInteger;
    PasswordLastSet: TLargeInteger;
    PasswordCanChange: TLargeInteger;
    PasswordMustChange: TLargeInteger;
    LogonScript: String;
    HomeDirectory: String;
    HomeDirectoryDrive: String;
    FullName: String;
    ProfilePath: String;
    LogonServer: String;
    UserFlags: TLogonFlags;
    UserSessionKey: TGuid;
    LogonDomainName: String;
    [Hex] LanmanSessionKey: UInt64;
    UserParameters: String;
  end;

// Call LsaLogonUser and capture the profile details
function LsaxLogonUser(
  out Info: TLogonInfo;
  const Buffer: IMemory;
  const LogonType: TSecurityLogonType;
  const TokenSource: TTokenSource;
  [opt] const AdditionalGroups: TArray<TGroup> = nil;
  const PackageName: AnsiString = NEGOSSP_NAME_A
): TNtxStatus;

// Logon a user via interatvive logon message
function LsaxLogonUserInteractive(
  out Info: TLogonInfo;
  const Domain: String;
  const Username: String;
  const Password: String;
  const TokenSource: TTokenSource;
  const LogonType: TSecurityLogonType = TSecurityLogonType.Interactive;
  const MessageType: TLogonSubmitType = TLogonSubmitType.InteractiveLogon;
  [opt] const AdditionalGroups: TArray<TGroup> = nil;
  const PackageName: AnsiString = NEGOSSP_NAME_A
): TNtxStatus;

// Logon a user without a password via S4U
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpSometimes)]
function LsaxLogonUserS4U(
  out Info: TLogonInfo;
  const Domain: String;
  const Username: String;
  const TokenSource: TTokenSource;
  Flags: TS4ULogonFlags = 0;
  [opt] const AdditionalGroups: TArray<TGroup> = nil;
  const PackageName: AnsiString = NEGOSSP_NAME_A
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Processes.Info, NtUtils.Tokens.Misc,
  DelphiUtils.AutoObjects, NtUtils.Lsa, NtUtils.Security.Sid;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function LsaxDelayFreeReturnBuffer(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      LsaFreeReturnBuffer(Buffer);
    end
  );
end;

function LsaxCaptureLogonProfile(
  var Info: TLogonInfo;
  [in, ReadsFrom] Profile: Pointer;
  [in, NumberOfBytes] ProfileSize: Cardinal
): TNtxStatus;
var
  ProfileInteractive: PInteractiveLogonProfile absolute Profile;
  ProfileLm20: PLm20LogonProfile absolute Profile;
begin
  Result.Location := 'LsaxCaptureLogonProfile';

  if ProfileSize < SizeOf(TLogonProfileBufferType) then
  begin
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  case TLogonProfileBufferType(Profile^) of
    TLogonProfileBufferType.InteractiveProfile:
    begin
      if ProfileSize < SizeOf(TInteractiveLogonProfile) then
      begin
        Result.Status := STATUS_INVALID_BUFFER_SIZE;
        Exit;
      end;

      Info.ValidFields := Info.ValidFields + [liLogonCount..liUserFlags];
      Info.LogonCount := ProfileInteractive.LogonCount;
      Info.BadPasswordCount := ProfileInteractive.BadPasswordCount;
      Info.LogonTime := ProfileInteractive.LogonTime;
      Info.LogoffTime := ProfileInteractive.LogoffTime;
      Info.KickOffTime := ProfileInteractive.KickOffTime;
      Info.PasswordLastSet := ProfileInteractive.PasswordLastSet;
      Info.PasswordCanChange := ProfileInteractive.PasswordCanChange;
      Info.PasswordMustChange := ProfileInteractive.PasswordMustChange;
      Info.LogonScript := ProfileInteractive.LogonScript.ToString;
      Info.HomeDirectory := ProfileInteractive.HomeDirectory.ToString;
      Info.HomeDirectoryDrive := ProfileInteractive.HomeDirectoryDrive.ToString;
      Info.FullName := ProfileInteractive.FullName.ToString;
      Info.ProfilePath := ProfileInteractive.ProfilePath.ToString;
      Info.LogonServer := ProfileInteractive.LogonServer.ToString;
      Info.UserFlags := ProfileInteractive.UserFlags;
    end;

    TLogonProfileBufferType.Lm20LogonProfile:
    begin
      if ProfileSize < SizeOf(TLm20LogonProfile) then
      begin
        Result.Status := STATUS_INVALID_BUFFER_SIZE;
        Exit;
      end;

      Info.ValidFields := Info.ValidFields + [liLogoffTime, liKickOffTime,
        liLogonServer, liUserFlags, liUserSessionKey..liUserParameters];
      Info.LogoffTime := ProfileLm20.LogoffTime;
      Info.KickOffTime := ProfileLm20.KickOffTime;
      Info.LogonServer := ProfileLm20.LogonServer.ToString;
      Info.UserFlags := ProfileLm20.UserFlags;
      Info.UserSessionKey := ProfileLm20.UserSessionKey;
      Info.LogonDomainName := ProfileLm20.LogonDomainName.ToString;
      Info.LanmanSessionKey := ProfileLm20.LanmanSessionKey;
      Info.UserParameters := ProfileLm20.UserParameters.ToString;
    end
  else
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function LsaxLogonUser;
var
  hToken: THandle;
  LsaHandle: ILsaHandle;
  AuthPkg: Cardinal;
  GroupArray: IMemory<PTokenGroups>;
  GroupArrayData: Pointer;
  ProfileBuffer: Pointer;
  ProfileBufferLength: Cardinal;
  ProfileBufferDeallocator: IAutoReleasable;
  SubStatus: NTSTATUS;
begin
{$IFDEF Win32}
  // LsaLogonUser overwrites our memory under WoW64 for some reason
  if RtlxAssertNotWoW64(Result) then
    Exit;
{$ENDIF}

  Info := Default(TLogonInfo);
  GroupArrayData := nil;

  // Connect to LSA
  Result := LsaxConnectUntrusted(LsaHandle);

  if not Result.IsSuccess then
    Exit;

  // Lookup the Negotiate package
  Result := LsaxLookupAuthPackage(AuthPkg, PackageName, LsaHandle);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LsaLogonUser';
  Result.LastCall.UsesInfoClass(TLogonSubmitType(Buffer.Data^), icPerform);

  if Length(AdditionalGroups) > 0 then
  begin
    // Note: The function requires SeTcbPrivilege when adding groups but
    // returns ERROR_ACCESS_DENIED in place of ERROR_PRIVILEGE_NOT_HELD,
    // which is confusing.
    Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;

    GroupArray := NtxpAllocGroups2(AdditionalGroups);
    GroupArrayData := GroupArray.Data;
  end;

  // Perform the logon
  Result.Status := LsaLogonUser(LsaHandle.Handle, TLsaAnsiString.From('S4U'),
    LogonType, AuthPkg, Buffer.Data, Buffer.Size, GroupArrayData, TokenSource,
    ProfileBuffer, ProfileBufferLength, Info.LogonId, hToken, Info.Quotas,
    SubStatus);

  // Prefer more detailed errors
  if (Result.Status = STATUS_ACCOUNT_RESTRICTION) and
    not NT_SUCCESS(SubStatus) then
    Result.Status := SubStatus;

  if not Result.IsSuccess then
    Exit;

  Info.ValidFields := [liToken, liLogonId, liQuotas];
  Info.hxToken := Auto.CaptureHandle(hToken);

  if Assigned(ProfileBuffer) then
  begin
    ProfileBufferDeallocator := LsaxDelayFreeReturnBuffer(ProfileBuffer);
    LsaxCaptureLogonProfile(Info, ProfileBuffer, ProfileBufferLength);
  end;
end;

function LsaxLogonUserInteractive;
var
  Buffer: IMemory<PInteractiveLogon>;
  Cursor: Pointer;
begin
  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TInteractiveLogon) +
    StringSizeZero(Username) + StringSizeZero(Domain) + StringSizeZero(Password));

  Buffer.Data.MessageType := MessageType;
  Cursor := Buffer.Offset(SizeOf(TInteractiveLogon));

  MarshalUnicodeString(Domain, Buffer.Data.LogonDomainName, Cursor);
  Inc(PByte(Cursor), Buffer.Data.LogonDomainName.MaximumLength);

  MarshalUnicodeString(Username, Buffer.Data.UserName, Cursor);
  Inc(PByte(Cursor), Buffer.Data.UserName.MaximumLength);

  MarshalUnicodeString(Password, Buffer.Data.Password, Cursor);
  Inc(PByte(Cursor), Buffer.Data.Password.MaximumLength);

  Result := LsaxLogonUser(Info, IMemory(Buffer), LogonType, TokenSource,
    AdditionalGroups, PackageName);
end;

function LsaxLogonUserS4U;
var
  Buffer: IMemory<PS4ULogon>;
  Cursor: Pointer;
begin
  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TS4ULogon) +
    StringSizeZero(Username) + StringSizeZero(Domain));

  Buffer.Data.MessageType := TLogonSubmitType.S4ULogon;
  Buffer.Data.Flags := Flags;
  Cursor := Buffer.Offset(SizeOf(TS4ULogon));

  MarshalUnicodeString(Username, Buffer.Data.UserPrincipalName, Cursor);
  Inc(PByte(Cursor), Buffer.Data.UserPrincipalName.MaximumLength);

  MarshalUnicodeString(Domain, Buffer.Data.DomainName, Cursor);
  Inc(PByte(Cursor), Buffer.Data.DomainName.MaximumLength);

  Result := LsaxLogonUser(Info, IMemory(Buffer), TSecurityLogonType.Network,
    TokenSource, AdditionalGroups, PackageName);
end;

end.
