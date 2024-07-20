unit NtUiLib.AutoCompletion.Sid;

{
  This module provides suggestion and auto-completion logic for SIDs.
}

interface

uses
  Ntapi.WinNt, Ntapi.WinUser, Ntapi.Shlwapi, Ntapi.ntlsa, Ntapi.ntsam,
  NtUtils, NtUtils.Lsa, NtUtils.Lsa.Sid,  NtUtils.Sam, NtUiLib.AutoCompletion;

type
  TSidSource = (
    ssWellKnown,         // Well-known SIDs from winnt
    ssVirtualAccounts,   // Virtual domains from the SID name mapping range
    ssCurrentToken,      // SIDs from the current token
    ssSamAccounts,       // SIDs of accounts in SAM domains
    ssLsaAccounts,       // SIDs of accounts from the LSA database
    ssLogonSessions,     // SIDs from logon session enumeration
    ssPerSession,        // Font Driver Host & Window Manager SIDs
    ssLogonSID,          // The SID from the window station/desktop
    ssServices,          // NT SERVICE SIDs
    ssTasks,             // NT TASK SIDs
    ssAppCapability,     // Known APP CAPABILITY SIDs
    ssGroupCapability,   // Known GROUP CAPABILITY SIDs
    ssAppContainer,      // Known parent AppContainer SIDs
    ssAppContainerChild, // Known nested AppContainer SIDs
    ssAppPackageFamily   // Known Package Families
  );

  TSidSourceSet = set of TSidSource;
  TSidTypes = set of TSidNameUse;

const
  ALL_SID_SOURCES = [Low(TSidSource)..High(TSidSource)];

// Collect SID suggestions from various sources
function LsaxSuggestSIDs(
  Sources: TSidSourceSet = ALL_SID_SOURCES;
  SidTypeFilter: TSidTypes = VALID_SID_TYPES;
  [opt, Access(POLICY_LOOKUP_NAMES)] const hxLsaPolicy: ILsaHandle = nil;
  [opt, Access(SAM_SERVER_ENUMERATE_DOMAINS or SAM_SERVER_LOOKUP_DOMAIN)]
    const hxSamServer: ISamHandle = nil
): TArray<TTranslatedName>;

// Add dynamic SID suggestion to an edit-derived control
function ShlxEnableSidSuggestions(
  EditControl: THwnd;
  Options: Cardinal = ACO_AUTOSUGGEST or ACO_UPDOWNKEYDROPSLIST;
  SidTypeFilter: TSidTypes = VALID_SID_TYPES
): TNtxStatus;

implementation

uses
  Ntapi.ntseapi, Ntapi.WinSvc, Ntapi.ntioapi, Ntapi.ntpebteb,
  Ntapi.Versions, NtUtils.Security.Sid, NtUtils.Svc, NtUtils.WinUser,
  NtUtils.Tokens, NtUtils.Tokens.Info, NtUtils.SysUtils, NtUtils.Files,
  NtUtils.Files.Open, NtUtils.Files.Directories, NtUtils.WinStation,
  DelphiUtils.Arrays, DelphiUtils.AutoObjects, NtUtils.Lsa.Logon,
  NtUtils.Security.AppContainer, NtUiLib.AutoCompletion.Sid.Common,
  NtUiLib.AutoCompletion.Sid.Capabilities,
  NtUiLib.AutoCompletion.Sid.AppContainer;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

const
  SERVICE_SID_PREFIX = SERVICE_SID_DOMAIN + '\';
  TASK_SID_PREFIX = TASK_SID_DOMAIN + '\';
  APP_CAPABILITY_PREFIX = APP_CAPABILITY_DOMAIN + '\';
  GROUP_CAPABILITY_PREFIX = GROUP_CAPABILITY_DOMAIN + '\';
  APP_CONTAINER_PREFIX = APP_CONTAINER_DOMAIN + '\';
  APP_PACKAGE_PREFIX = APP_PACKAGE_DOMAIN + '\';

function RtlxpSuggestWellKnownSIDs: TArray<ISid>;
var
  KnownDefinitions: TArray<TArray<Cardinal>>;
  i, Count: Integer;
begin
  KnownDefinitions := [
    [SECURITY_NULL_SID_AUTHORITY, SECURITY_NULL_RID],
    [SECURITY_WORLD_SID_AUTHORITY, SECURITY_WORLD_RID],
    [SECURITY_LOCAL_SID_AUTHORITY, SECURITY_LOCAL_RID],
    [SECURITY_LOCAL_SID_AUTHORITY, SECURITY_LOCAL_LOGON_RID],
    [SECURITY_CREATOR_SID_AUTHORITY, SECURITY_CREATOR_OWNER_RID],
    [SECURITY_CREATOR_SID_AUTHORITY, SECURITY_CREATOR_GROUP_RID],
    [SECURITY_CREATOR_SID_AUTHORITY, SECURITY_CREATOR_OWNER_SERVER_RID],
    [SECURITY_CREATOR_SID_AUTHORITY, SECURITY_CREATOR_GROUP_SERVER_RID],
    [SECURITY_CREATOR_SID_AUTHORITY, SECURITY_CREATOR_OWNER_RIGHTS_RID],
    [SECURITY_NON_UNIQUE_AUTHORITY],
    [SECURITY_NT_AUTHORITY, SECURITY_DIALUP_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_NETWORK_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_BATCH_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_INTERACTIVE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_SERVICE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_ANONYMOUS_LOGON_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PROXY_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_ENTERPRISE_CONTROLLERS_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PRINCIPAL_SELF_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_AUTHENTICATED_USER_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_RESTRICTED_CODE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_TERMINAL_SERVER_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_REMOTE_LOGON_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_THIS_ORGANIZATION_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_IUSER_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_LOCAL_SYSTEM_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_LOCAL_SERVICE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_NETWORK_SERVICE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_NT_NON_UNIQUE, 0, 0, 0, DOMAIN_GROUP_RID_AUTHORIZATION_DATA_IS_COMPOUNDED],
    [SECURITY_NT_AUTHORITY, SECURITY_NT_NON_UNIQUE, 0, 0, 0, DOMAIN_GROUP_RID_AUTHORIZATION_DATA_CONTAINS_CLAIMS],
    [SECURITY_NT_AUTHORITY, SECURITY_ENTERPRISE_READONLY_CONTROLLERS_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_USERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_GUESTS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_POWER_USERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ACCOUNT_OPS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_SYSTEM_OPS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_PRINT_OPS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_BACKUP_OPS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_REPLICATOR],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_RAS_SERVERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_PREW2KCOMPACCESS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_REMOTE_DESKTOP_USERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_NETWORK_CONFIGURATION_OPS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_INCOMING_FOREST_TRUST_BUILDERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_MONITORING_USERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_LOGGING_USERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_AUTHORIZATIONACCESS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_TS_LICENSE_SERVERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_DCOM_USERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_IUSERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_CRYPTO_OPERATORS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_EVENT_LOG_READERS_GROUP],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_CERTSVC_DCOM_ACCESS_GROUP],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_RDS_REMOTE_ACCESS_SERVERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_RDS_ENDPOINT_SERVERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_RDS_MANAGEMENT_SERVERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_HYPER_V_ADMINS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ACCESS_CONTROL_ASSISTANCE_OPS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_REMOTE_MANAGEMENT_USERS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_DEFAULT_ACCOUNT],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS],
    [SECURITY_NT_AUTHORITY, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_DEVICE_OWNERS],
    [SECURITY_NT_AUTHORITY, SECURITY_WRITE_RESTRICTED_CODE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_NTLM_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_SCHANNEL_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_DIGEST_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_NTLM_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_SCHANNEL_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_DIGEST_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_CRED_TYPE_BASE_RID, SECURITY_CRED_TYPE_THIS_ORG_CERT_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_SERVICE_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_SERVICE_ID_BASE_RID, SECURITY_SERVICE_ID_GROUP_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_APPPOOL_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_VIRTUALSERVER_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_VIRTUALSERVER_ID_BASE_RID, SECURITY_VIRTUALSERVER_ID_GROUP_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_USERMODEDRIVERHOST_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_USERMODEDRIVERHOST_ID_BASE_RID, 0, 0, 0, 0, SECURITY_USERMODEDRIVERHOST_ID_GROUP_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_CLOUD_INFRASTRUCTURE_SERVICES_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_WMIHOST_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_TASK_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_NFS_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_COM_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_WINDOW_MANAGER_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_WINDOW_MANAGER_BASE_RID, SECURITY_WINDOW_MANAGER_GROUP],
    [SECURITY_NT_AUTHORITY, SECURITY_RDV_GFX_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_DASHOST_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_USERMANAGER_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_WINRM_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_CCG_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_UMFD_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_WINDOWSMOBILE_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_LOCAL_ACCOUNT_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_LOCAL_ACCOUNT_AND_ADMIN_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_OTHER_ORGANIZATION_RID],
    [SECURITY_SITESERVER_AUTHORITY],
    [SECURITY_INTERNETSITE_AUTHORITY],
    [SECURITY_EXCHANGE_AUTHORITY],
    [SECURITY_RESOURCE_MANAGER_AUTHORITY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_APP_PACKAGE_BASE_RID, SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_APP_PACKAGE_BASE_RID, SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_INTERNET_CLIENT],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_INTERNET_CLIENT_SERVER],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_PRIVATE_NETWORK_CLIENT_SERVER],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_PICTURES_LIBRARY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_VIDEOS_LIBRARY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_MUSIC_LIBRARY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_DOCUMENTS_LIBRARY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_ENTERPRISE_AUTHENTICATION],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_SHARED_USER_CERTIFICATES],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_REMOVABLE_STORAGE],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_APPOINTMENTS],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID, SECURITY_CAPABILITY_CONTACTS],
    [SECURITY_MANDATORY_LABEL_AUTHORITY],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_UNTRUSTED_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_LOW_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_MEDIUM_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_MEDIUM_PLUS_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_HIGH_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_SYSTEM_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_PROTECTED_PROCESS_RID],
    [SECURITY_SCOPED_POLICY_ID_AUTHORITY],
    [SECURITY_AUTHENTICATION_AUTHORITY, SECURITY_AUTHENTICATION_AUTHORITY_ASSERTED_RID],
    [SECURITY_AUTHENTICATION_AUTHORITY, SECURITY_AUTHENTICATION_SERVICE_ASSERTED_RID],
    [SECURITY_AUTHENTICATION_AUTHORITY, SECURITY_AUTHENTICATION_FRESH_KEY_AUTH_RID],
    [SECURITY_AUTHENTICATION_AUTHORITY, SECURITY_AUTHENTICATION_KEY_TRUST_RID],
    [SECURITY_AUTHENTICATION_AUTHORITY, SECURITY_AUTHENTICATION_KEY_PROPERTY_MFA_RID],
    [SECURITY_AUTHENTICATION_AUTHORITY, SECURITY_AUTHENTICATION_KEY_PROPERTY_ATTESTATION_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID, SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID, SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID, SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID, SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID, SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID, SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID, SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID, SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID, SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID, SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID],
    [SECURITY_PROCESS_TRUST_AUTHORITY, SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID, SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID]
  ];

  SetLength(Result, Length(KnownDefinitions));
  Count := 0;

  for i := 0 to High(Result) do
    if RtlxCreateSidFromArray(Result[Count], KnownDefinitions[i]).IsSuccess then
      Inc(Count);

  if Count <> Length(KnownDefinitions) then
    SetLength(Result, Count);
end;

function RtlxpSuggestVirtualAccountSIDs: TArray<ISid>;
var
  i, j: Cardinal;
begin
  SetLength(Result, (SECURITY_MAX_BASE_RID - SECURITY_MIN_BASE_RID + 1) * 2);

  j := 0;
  for i := SECURITY_MIN_BASE_RID to SECURITY_MAX_BASE_RID do
  begin
    // Domain account
    if RtlxCreateSid(Result[j], SECURITY_NT_AUTHORITY, [i]).IsSuccess then
      Inc(j);

    // All members group
    if RtlxCreateSid(Result[j], SECURITY_NT_AUTHORITY, [i, 0]).IsSuccess then
      Inc(j);
  end;

  SetLength(Result, j);
end;

function RtlxpSuggestCurrentTokenSIDs: TArray<ISid>;
var
  Sid: ISid;
  Groups: TArray<TGroup>;
begin
  Result := nil;

  // Current user
  if NtxQuerySidToken(NtxCurrentEffectiveToken, TokenUser, Sid).IsSuccess then
    Result := Result + [Sid];

  // Current groups
  if NtxQueryGroupsToken(NtxCurrentEffectiveToken, TokenGroups,
    Groups).IsSuccess then
    Result := Result + TArray.Map<TGroup, ISid>(Groups,
      function (const Group: TGroup): ISid
      begin
        Result := Group.Sid;
      end
    );
end;

function RtlxpCollectSamAccounts(
  const hxDomain: ISamHandle;
  SidTypes: TSidTypes
): TArray<ISid>;
var
  Members, AllMembers: TArray<TRidAndName>;
  RIDs: TArray<Cardinal>;
  i: Integer;
begin
  Result := nil;
  AllMembers := nil;

  // Add users
  if (SidTypeUser in SidTypes) and
    SamxEnumerateUsers(hxDomain, Members).IsSuccess then
    AllMembers := AllMembers + Members;

  // Add groups
  if (SidTypeGroup in SidTypes) and
    SamxEnumerateGroups(hxDomain, Members).IsSuccess then
    AllMembers := AllMembers + Members;

  // Add aliases
  if (SidTypeAlias in SidTypes) and
    SamxEnumerateAliases(hxDomain, Members).IsSuccess then
    AllMembers := AllMembers + Members;

  if Length(AllMembers) = 0 then
    Exit;

  // Converts RIDs to SIDs
  SetLength(RIDs, Length(AllMembers));

  for i := 0 to High(AllMembers) do
    RIDs[i] := AllMembers[i].RelativeID;

  if not SamxRidsToSids(hxDomain, RIDs, Result).IsSuccess then
    Result := nil;
end;

function RtlxpSuggestSamSIDs(
  SidTypes: TSidTypes;
  [opt, Access(SAM_SERVER_ENUMERATE_DOMAINS or SAM_SERVER_LOOKUP_DOMAIN)]
    hxServer: ISamHandle = nil
): TArray<ISid>;
var
  Status: TNtxStatus;
  hxDomain: ISamHandle;
  DomainNames: TArray<String>;
  DomainSid: ISid;
  i: Integer;
begin
  Result := nil;

  if [SidTypeDomain, SidTypeUser, SidTypeGroup, SidTypeAlias] *
    SidTypes = [] then
    Exit;

  if not Assigned(hxServer) then
  begin
    Status := SamxConnect(hxServer, SAM_SERVER_ENUMERATE_DOMAINS or
      SAM_SERVER_LOOKUP_DOMAIN);

    if not Status.IsSuccess then
      Exit;
  end;

  // Retrieve domain names
  Status := SamxEnumerateDomains(DomainNames, hxServer);

  if not Status.IsSuccess then
    Exit;

  for i := 0 to High(DomainNames) do
  begin
    // Convert the name to the SID
    Status := SamxLookupDomain(DomainNames[i], DomainSid, hxServer);

    if not Status.IsSuccess then
      Continue;

    // Include it if necessary
    if SidTypeDomain in SidTypes then
      Result := Result + [DomainSid];

    if [SidTypeUser, SidTypeGroup, SidTypeAlias] * SidTypes <> [] then
    begin
      // Open the domain for listing accounts
      Status := SamxOpenDomain(hxDomain, DomainSid, DOMAIN_LIST_ACCOUNTS,
        hxServer);

      // Save nested accounts
      if Status.IsSuccess then
        Result := Result + RtlxpCollectSamAccounts(hxDomain, SidTypes);
    end;
  end;
end;

function RtlxpSuggestLsaSIDs: TArray<ISid>;
begin
  if not LsaxEnumerateAccounts(Result).IsSuccess then
    Result := nil;
end;

function RtlxpSuggestLogonOwnerSIDs: TArray<ISid>;
var
  LogonSessions: TArray<TLogonId>;
begin
  // Snapshot logon sessions
  if not LsaxEnumerateLogonSessions(LogonSessions).IsSuccess then
    Exit(nil);

  Result := TArray.Convert<TLogonId, ISid>(LogonSessions,
    function (const LogonId: TLogonId; out Sid: ISid): Boolean
    var
      Info: ILogonSession;
     begin
      // Lookup owner of each logon session
      Result := LsaxQueryLogonSession(LogonId, Info).IsSuccess and
        Assigned(Info.Data.SID) and RtlxCopySid(Info.Data.SID, Sid).IsSuccess;
    end
  );
end;

function RtlxpSuggestPerSessionSIDs: TArray<ISid>;
var
  Sessions: TArray<TSessionIdW>;
begin
  if not RtlOsVersionAtLeast(OsWin8) then
    Exit(nil);

  // Add common SIDs
  Result := [
    RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_UMFD_BASE_RID]),
    RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_WINDOW_MANAGER_BASE_RID]),
    RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_WINDOW_MANAGER_BASE_RID,
      SECURITY_WINDOW_MANAGER_GROUP])
  ];

  // Lookup all sessions when possible; otherwise use the ones we know about
  if not WsxEnumerateSessions(Sessions).IsSuccess then
  begin
    SetLength(Sessions, 2);
    Sessions[0].SessionID := 0;
    Sessions[0].SessionID := RtlGetCurrentPeb.SessionID;
  end;

  // Font Driver Host\UMFD-X
  Result := Result + TArray.Map<TSessionIdW, ISid>(Sessions,
    function (const Session: TSessionIdW): ISid
    begin
      Result := RtlxMakeSid(SECURITY_NT_AUTHORITY,
        [SECURITY_UMFD_BASE_RID, 0, Session.SessionID]);
    end
  );

  // Window Manager\DWM-X
  Result := Result + TArray.Map<TSessionIdW, ISid>(Sessions,
    function (const Session: TSessionIdW): ISid
    begin
      Result := RtlxMakeSid(SECURITY_NT_AUTHORITY,
        [SECURITY_WINDOW_MANAGER_BASE_RID, SECURITY_WINDOW_MANAGER_GROUP,
          Session.SessionID]);
    end
  );
end;

function RtlxSuggestLogonSIDs: TArray<ISid>;
var
  Sid: ISid;
begin
  if UsrxQuerySid(UsrxCurrentWindowStation, Sid).IsSuccess and
    Assigned(Sid) then
    Result := [Sid]
  else
    Result := nil;
end;

function RtlxpSuggestServiceSIDs: TArray<ISid>;
var
  ServiceTypes: TServiceType;
  Status: TNtxStatus;
  Services: TArray<TServiceEntry>;
begin
  // Add common SIDs
  Result := [
    RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_SERVICE_ID_BASE_RID]),
    RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_SERVICE_ID_BASE_RID,
      SECURITY_SERVICE_ID_GROUP_RID])
  ];

  ServiceTypes := SERVICE_WIN32;

  if RtlOsVersionAtLeast(OsWin10) then
    ServiceTypes := ServiceTypes or SERVICE_USER_SERVICE;

  // Snapshot the list of services
  Status := ScmxEnumerateServices(Services, ServiceTypes);

  if not Status.IsSuccess then
    Exit;

  // Add their SIDs
  Result := Result + TArray.Convert<TServiceEntry, ISid>(Services,
    function (const Service: TServiceEntry; out Sid: ISid): Boolean
    begin
      Result := RtlxCreateServiceSid(Service.ServiceName, Sid).IsSuccess;
    end
  );
end;

function RtlxpSuggestTaskSIDs: TArray<ISid>;
const
  TASK_ROOT = '\SystemRoot\system32\Tasks';
var
  Status: TNtxStatus;
  TaskPrefix: String;
  OpenParameters: IFileParameters;
  Tasks: TArray<ISid>;
  hxTaskDirectory: IHandle;
begin
  // Add base SID
  Result := [RtlxMakeSid(SECURITY_NT_AUTHORITY, [SECURITY_TASK_ID_BASE_RID])];

  TaskPrefix := '';
  OpenParameters := FileParameters
    .UseAccess(FILE_LIST_DIRECTORY)
    .UseOptions(FILE_DIRECTORY_FILE);

  // Try opening the root of all scheduled tasks
  Status := NtxOpenFile(hxTaskDirectory, OpenParameters.UseFileName(TASK_ROOT));

  if not Status.IsSuccess then
  begin
    TaskPrefix := 'Microsoft';

    // Retry with tasks that might not require admin rights to enumerate
    Status := NtxOpenFile(hxTaskDirectory, OpenParameters
      .UseFileName(TASK_ROOT + '\' + TaskPrefix));
  end;

  if not Status.IsSuccess then
    Exit;

  Tasks := nil;

  // Traverse the tasks and collect their names
  Status := NtxTraverseDirectoryFile(hxTaskDirectory, OpenParameters,
    function(
      const FileInfo: TDirectoryFileEntry;
      const Root: IHandle;
      const RootName: String;
      var ContinuePropagation: Boolean
    ): TNtxStatus
    var
      TaskName: String;
      TaskSid: ISid;
      i: Integer;
    begin
      TaskName := TaskPrefix + RootName + '\' + FileInfo.FileName;

      // Remove leading directory prefix
      if TaskName[Low(String)] = '\' then
        Delete(TaskName, 1, 1);

      // Tasks names use dashes instead of back slashes
      for i := Low(TaskName) to High(TaskName) do
        if TaskName[i] = '\' then
          TaskName[i] := '-';

      // Derive service SID from the name
      Result := RtlxCreateVirtualAccountSid(TaskName, SECURITY_TASK_ID_BASE_RID,
        TaskSid);

      if Result.IsSuccess then
      begin
        SetLength(Tasks, Length(Tasks) + 1);
        Tasks[High(Tasks)] := TaskSid;
      end;
    end,
    [ftInvokeOnFiles, ftIgnoreCallbackFailures, ftIgnoreTraverseFailures],
    FileDirectoryInformation,
    8
  );

  if Status.IsSuccess then
    Result := Tasks;
end;

function RtlxpSuggestCapabilitySIDs(
  Source: TSidSource
): TArray<TTranslatedName>;
var
  Names: TArray<String>;
  Domain: String;
  Mode: TCapabilityType;
begin
  case Source of
    ssAppCapability:
    begin
      Domain := APP_CAPABILITY_DOMAIN;
      Mode := ctAppCapability;
    end;

    ssGroupCapability:
    begin
      Domain := GROUP_CAPABILITY_DOMAIN;
      Mode := ctGroupCapability;
    end;
  else
    Exit(nil);
  end;

  // Get known capability names
  Names := RtlxEnumerateKnownCapabilities;

  // Prepare SIDs and a fake lookup for them
  Result := TArray.Convert<String, TTranslatedName>(Names,
    function (const Name: String; out Translated: TTranslatedName): Boolean
    begin
      Translated.IsFake := True;
      Translated.SidType := SidTypeWellKnownGroup;
      Translated.DomainName := Domain;
      Translated.UserName := Name;
      Result := RtlxDeriveCapabilitySid(Translated.SID, Name, Mode).IsSuccess;
    end
  );
end;

function RtlxpSuggestAppContainerSIDs(
  Source: TSidSource
): TArray<TTranslatedName>;
var
  Filter: TAppContainerFilter;
begin
  case Source of
    ssAppContainer:      Filter := [afParentAppContainer];
    ssAppContainerChild: Filter := [afChildAppContainer];
    ssAppPackageFamily:  Filter := [afPackage];
  else
    Exit(nil);
  end;

  // Make a fake lookup for remembered names
  Result := TArray.Convert<String, TTranslatedName>(
    RtlxEnumerateRememberedAppContainers(Filter),
    function (const Name: String; out Translated: TTranslatedName): Boolean
    begin
      Translated.IsFake := True;
      Translated.SidType := SidTypeWellKnownGroup;
      Translated.UserName := Name;

      if Source = ssAppPackageFamily then
      begin
        Translated.DomainName := APP_PACKAGE_DOMAIN;
        Result := RtlxDerivePackageFamilySid(Name, Translated.SID).IsSuccess;
      end
      else
      begin
        Translated.DomainName := APP_CONTAINER_DOMAIN;
        Result := RtlxDeriveFullAppContainerSid(Name, Translated.SID).IsSuccess;
      end;
    end
  );
end;

function LsaxSuggestSIDs;
var
  SIDs: TArray<ISid>;
begin
  // Collect translatable SIDs
  SIDs := nil;

  if ssWellKnown in Sources then
    SIDs := SIDs + RtlxpSuggestWellKnownSIDs;

  if ssVirtualAccounts in Sources then
    SIDs := SIDs + RtlxpSuggestVirtualAccountSIDs;

  if ssCurrentToken in Sources then
    SIDs := SIDs + RtlxpSuggestCurrentTokenSIDs;

  if ssSamAccounts in Sources then
    SIDs := SIDs + RtlxpSuggestSamSIDs(SidTypeFilter, hxSamServer);

  if ssLsaAccounts in Sources then
    SIDs := SIDs + RtlxpSuggestLsaSIDs;

  if ssLogonSessions in Sources then
    SIDs := SIDs + RtlxpSuggestLogonOwnerSIDs;

  if ssPerSession in Sources then
    SIDs := SIDs + RtlxpSuggestPerSessionSIDs;

  if ssLogonSID in Sources then
    SIDs := SIDs + RtlxSuggestLogonSIDs;

  if ssServices in Sources then
    SIDs := SIDs + RtlxpSuggestServiceSIDs;

  if ssTasks in Sources then
    SIDs := SIDs + RtlxpSuggestTaskSIDs;

  SIDs := TArray.RemoveDuplicates<ISid>(SIDs, RtlxEqualSids);

  // Translate the SIDs
  LsaxLookupSids(SIDs, Result, hxLsaPolicy);

  // Add fake translated names for capabilities, AppContainers, and packages
  if SidTypeWellKnownGroup in SidTypeFilter then
  begin
    if ssAppCapability in Sources then
      Result := Result + RtlxpSuggestCapabilitySIDs(ssAppCapability);

    if ssGroupCapability in Sources then
      Result := Result + RtlxpSuggestCapabilitySIDs(ssGroupCapability);

    // Populate the cache with as many AppContainers/packages as we can
    if [ssAppContainer, ssAppPackageFamily] * Sources <> [] then
      RtlxCollectAllAppContainersAndPackages;

    if ssAppContainer in Sources then
      Result := Result + RtlxpSuggestAppContainerSIDs(ssAppContainer);

    if ssAppContainerChild in Sources then
      Result := Result + RtlxpSuggestAppContainerSIDs(ssAppContainerChild);

    if ssAppPackageFamily in Sources then
      Result := Result + RtlxpSuggestAppContainerSIDs(ssAppPackageFamily);
  end;

  // Filter by type
  TArray.FilterInline<TTranslatedName>(Result,
    function (const Entry: TTranslatedName): Boolean
    begin
      Result := Entry.SidType in SidTypeFilter;
    end
  );
end;

type
  // An interface analog of anonymous completion suggestion callback
  ISuggestionProvider = interface (IAutoReleasable)
    function Suggest(
      const Root: String;
      out Suggestions: TArray<String>
    ): TNtxStatus;
  end;

  // An instance of SID suggestion provider that maintains its state
  TSidSuggestionProvider = class (TCustomAutoReleasable, ISuggestionProvider)
    Names: TArray<TTranslatedName>;
    Filter: TSidTypes;
    procedure Release; override;
    constructor Create(
      SidTypeFilter: TSidTypes = VALID_SID_TYPES
    );

    function Suggest(
      const Root: String;
      out Suggestions: TArray<String>
    ): TNtxStatus;
  end;

constructor TSidSuggestionProvider.Create;
begin
  inherited Create;
  Filter := SidTypeFilter;
  Names := LsaxSuggestSIDs([ssWellKnown, ssVirtualAccounts, ssCurrentToken,
    ssSamAccounts, ssLsaAccounts, ssLogonSessions, ssPerSession, ssLogonSID],
    Filter);
end;

function TSidSuggestionProvider.Suggest;
var
  FilteredNames: TArray<TTranslatedName>;
  ParentMoniker : String;
  Source: TSidSource;
begin
  Result := NtxSuccess;

  if Root = '' then
  begin
    // Include top-level accounts only
    Suggestions := TArray.Map<TTranslatedName, String>(Names,
      function (const Account: TTranslatedName): String
      begin
        Result := RtlxExtractRootPath(Account.FullName);
      end
    );

    // Make capabilities discoverable
    if RtlOsVersionAtLeast(OsWin10) then
      Suggestions := Suggestions + [APP_CAPABILITY_DOMAIN,
        GROUP_CAPABILITY_DOMAIN];

    // Make AppContainers and packages discoverable
    if RtlOsVersionAtLeast(OsWin8) then
      Suggestions := Suggestions + [APP_CONTAINER_DOMAIN,
        APP_PACKAGE_DOMAIN];
  end
  else
  begin
    if RtlxEqualStrings(SERVICE_SID_PREFIX, Root) then
      FilteredNames := LsaxSuggestSIDs([ssServices], Filter)
    else if RtlxEqualStrings(TASK_SID_PREFIX, Root) then
      FilteredNames := LsaxSuggestSIDs([ssTasks], Filter)
    else if RtlxEqualStrings(APP_CAPABILITY_PREFIX, Root) then
      FilteredNames := LsaxSuggestSIDs([ssAppCapability], Filter)
    else if RtlxEqualStrings(GROUP_CAPABILITY_PREFIX, Root) then
      FilteredNames := LsaxSuggestSIDs([ssGroupCapability], Filter)
    else if RtlxEqualStrings(APP_PACKAGE_PREFIX, Root) then
      FilteredNames := LsaxSuggestSIDs([ssAppPackageFamily], Filter)
    else if RtlxPrefixString(APP_CONTAINER_PREFIX, Root) and
      (SidTypeWellKnownGroup in Filter) then
    begin
      // Collect AppContainer children
      if Length(Root) > Length(APP_CONTAINER_PREFIX) then
      begin
        ParentMoniker := Copy(
          Root,
          Length(APP_CONTAINER_PREFIX) + 1,
          Length(Root) - Length(APP_CONTAINER_PREFIX) - 1
        );

        Source := ssAppContainerChild;
        RtlxCollectAllAppContainersAndPackages(ParentMoniker);
      end
      else
        Source := ssAppContainer;

      FilteredNames := LsaxSuggestSIDs([Source]);
    end
    else
      FilteredNames := Names;

    // Include names under the specified root
    Suggestions := TArray.Convert<TTranslatedName, String>(FilteredNames,
      function (const Entry: TTranslatedName; out Name: String): Boolean
      begin
        Name := Entry.FullName;
        Result := RtlxPrefixString(Root, Name);
      end
    );
  end;

  // Clean-up duplicates
  Suggestions := TArray.RemoveDuplicates<String>(Suggestions,
    function (const A, B: String): Boolean
    begin
      Result := RtlxEqualStrings(A, B);
    end
  );
end;

procedure TSidSuggestionProvider.Release;
begin
  inherited;
end;

function ShlxEnableSidSuggestions;
var
  Provider: ISuggestionProvider;
  Callback: TExpandProvider;
begin
  // Create a provider class and capture it inside IAutoReleasable's descendant
  Provider := TSidSuggestionProvider.Create;

  // Make an anonymous function that forwards the requests and captures the
  // provider class for prolonging its lifetime
  Callback := function (
      const Root: String;
      out Suggestions: TArray<String>
    ): TNtxStatus
    begin
      Result := Provider.Suggest(Root, Suggestions);
    end;

  // Attach auto completion callback
  Result := ShlxEnableDynamicSuggestions(EditControl, Callback, Options);
end;

end.
