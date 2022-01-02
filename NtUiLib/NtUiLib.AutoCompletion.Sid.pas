unit NtUiLib.AutoCompletion.Sid;

{
  This module provides suggestion and auto-completion logic for SIDs.
}

interface

uses
  Ntapi.WinUser, Ntapi.Shlwapi, NtUtils, NtUiLib.AutoCompletion;

// Add dynamic SID suggestion to an edit-derived control
function ShlxEnableSidSuggestions(
  EditControl: THwnd;
  Options: Cardinal = ACO_AUTOSUGGEST or ACO_UPDOWNKEYDROPSLIST
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntsam, Ntapi.ntseapi, Ntapi.WinSvc, NtUtils.Security.Sid,
  NtUtils.Lsa.Sid, NtUtils.Sam, NtUtils.Svc, NtUtils.WinUser, NtUtils.Tokens,
  NtUtils.Tokens.Info, NtUtils.SysUtils, DelphiUtils.Arrays, Ntapi.Versions,
  DelphiUtils.AutoObjects;

// Prepare well-known SIDs from constants
function EnumerateKnownSIDs: TArray<ISid>;
var
  KnownDefinitions: TArray<TArray<Cardinal>>;
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
    [SECURITY_NT_AUTHORITY, SECURITY_SERVICE_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_LOCAL_ACCOUNT_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_LOCAL_ACCOUNT_AND_ADMIN_RID],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_APP_PACKAGE_BASE_RID, SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_APP_PACKAGE_BASE_RID, SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_INTERNET_CLIENT],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_INTERNET_CLIENT_SERVER],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_PRIVATE_NETWORK_CLIENT_SERVER],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_PICTURES_LIBRARY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_VIDEOS_LIBRARY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_MUSIC_LIBRARY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_DOCUMENTS_LIBRARY],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_ENTERPRISE_AUTHENTICATION],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_SHARED_USER_CERTIFICATES],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_REMOVABLE_STORAGE],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_APPOINTMENTS],
    [SECURITY_APP_PACKAGE_AUTHORITY, SECURITY_CAPABILITY_BASE_RID,SECURITY_CAPABILITY_CONTACTS],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_UNTRUSTED_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_LOW_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_MEDIUM_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_MEDIUM_PLUS_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_HIGH_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_SYSTEM_RID],
    [SECURITY_MANDATORY_LABEL_AUTHORITY, SECURITY_MANDATORY_PROTECTED_PROCESS_RID]
  ];

  Result := TArray.Convert<TArray<Cardinal>, ISid>(KnownDefinitions,
    function (const Authorities: TArray<Cardinal>; out Sid: ISid): Boolean
    begin
      if Length(Authorities) < 1 then
        Exit(False);

      Result := RtlxCreateSid(Sid, Authorities[0], Copy(Authorities, 1,
        Length(Authorities) - 1)).IsSuccess;
    end
  );
end;

// Enumerate SIDs related to the caller
function EnumerateRuntimeSIDs: TArray<ISid>;
var
  Sid: ISid;
  Groups: TArray<TGroup>;
begin
  Result := nil;

  // Current window station's/desktop's logon SID
  if UsrxQuerySid(GetProcessWindowStation, Sid).IsSuccess and Assigned(Sid) then
    Result := [Sid];

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

// Enumerate domains registered in SAM
function EnumerateKnownDomains: TArray<ISid>;
var
  Status: TNtxStatus;
  hxSamServer: ISamHandle;
  DomainNames: TArray<String>;
begin
  Status := SamxConnect(hxSamServer, SAM_SERVER_ENUMERATE_DOMAINS or
    SAM_SERVER_LOOKUP_DOMAIN);

  if not Status.IsSuccess then
    Exit(nil);

  Status := SamxEnumerateDomains(DomainNames, hxSamServer);

  if not Status.IsSuccess then
    Exit(nil);

  Result := TArray.Convert<String, ISid>(DomainNames,
    function (const Name: String; out Sid: ISid): Boolean
    begin
      Result := SamxLookupDomain(Name, Sid, hxSamServer).IsSuccess;
    end
  );
end;

// Enumerate accounts of a domain via SAM
function EnumerateDomainAccounts(
  const Name: String
): TArray<ISid>;
var
  Status: TNtxStatus;
  hxDomain: ISamHandle;
  Groups, Aliases, Users: TArray<TRidAndName>;
  RIDs: TArray<Cardinal>;
begin
  Status := SamxOpenDomainByName(hxDomain, Name, DOMAIN_LIST_ACCOUNTS);

  if not Status.IsSuccess then
    Exit(nil);

  SamxEnumerateGroups(hxDomain.Handle, Groups);
  SamxEnumerateAliases(hxDomain.Handle, Aliases);
  SamxEnumerateUsers(hxDomain.Handle, Users);

  RIDs := TArray.Map<TRidAndName, Cardinal>(Groups + Aliases + Users,
    function (const Entry: TRidAndName): Cardinal
    begin
      Result := Entry.RelativeID;
    end
  );

  SamxRidsToSids(hxDomain.Handle, RIDs, Result);
end;

// Enumerate service SIDs
function EnumerateKnownServices: TArray<ISid>;
var
  ServiceTypes: TServiceType;
  Status: TNtxStatus;
  Services: TArray<TServiceEntry>;
begin
  ServiceTypes := SERVICE_WIN32;

  if RtlOsVersionAtLeast(OsWin10) then
    ServiceTypes := ServiceTypes or SERVICE_USER_SERVICE;

  Status := ScmxEnumerateServices(Services, ServiceTypes);

  if not Status.IsSuccess then
    Exit(nil);

  Result := TArray.Convert<TServiceEntry, ISid>(Services,
    function (const Service: TServiceEntry; out Sid: ISid): Boolean
    begin
      Result := RtlxCreateServiceSid(Service.ServiceName, Sid).IsSuccess;
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
    Names: TArray<String>;
    SamDomains: TArray<String>;
    procedure Release; override;
    constructor Create;

    function PerformLookup(
      const SIDs: TArray<ISid>
    ): TArray<String>;

    function Suggest(
      const Root: String;
      out Suggestions: TArray<String>
    ): TNtxStatus;
  end;

constructor TSidSuggestionProvider.Create;
begin
  inherited Create;

  // Save SAM domains, well-known SIDs, and user-related SIDs
  SamDomains := PerformLookup(EnumerateKnownDomains);
  Names := SamDomains + PerformLookup(EnumerateKnownSIDs + EnumerateRuntimeSIDs)
end;

function TSidSuggestionProvider.Suggest;
var
  i: Integer;
begin
  Result.Status := STATUS_SUCCESS;

  if Root = '' then
  begin
    // Include top-level accounts only
    Suggestions := TArray.Map<String, String>(Names,
      function (const Account: String): String
      begin
        Result := RtlxExtractPath(Account);
      end
    );
  end
  else
  begin
    // Include well-known names under the specified root
    Suggestions := TArray.Filter<String>(Names,
      function (const Name: String): Boolean
      begin
        Result := RtlxPrefixString(Root, Name);
      end
    );

    // Include accounts from SAM domains
    for i := 0 to High(SamDomains) do
      if RtlxEqualStrings(SamDomains[i] + '\', Root) then
      begin
        Suggestions := Suggestions + PerformLookup(
          EnumerateDomainAccounts(SamDomains[i]));
        Break;
      end;

    // Include service accounts
    if RtlxEqualStrings('NT SERVICE\', Root) then
      Suggestions := Suggestions + PerformLookup(EnumerateKnownServices);
  end;

  // Clean-up duplicates
  Suggestions := TArray.RemoveDuplicates<String>(Suggestions,
    function (const A, B: String): Boolean
    begin
      Result := RtlxEqualStrings(A, B);
    end
  );
end;

function TSidSuggestionProvider.PerformLookup;
var
  TranslatedNames: TArray<TTranslatedName>;
begin
  if Length(SIDs) <= 0 then
    Exit(nil);

  if not LsaxLookupSids(SIDs, TranslatedNames).IsSuccess then
    Exit(nil);

  // Include only valid names
  Result := TArray.Convert<TTranslatedName, String>(TranslatedNames,
    function (const Lookup: TTranslatedName; out Suggestion: String): Boolean
    begin
      Result := Lookup.IsValid;

      if Result then
        Suggestion := Lookup.FullName;
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
  // Create a provider class and capture it inside IAutoReleasable's decendent
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
