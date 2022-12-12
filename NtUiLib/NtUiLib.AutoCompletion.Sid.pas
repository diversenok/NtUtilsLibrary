unit NtUiLib.AutoCompletion.Sid;

{
  This module provides suggestion and auto-completion logic for SIDs.
}

interface

uses
  Ntapi.WinNt, NtUtils.Lsa.Sid, Ntapi.WinUser, Ntapi.Shlwapi, NtUtils,
  NtUiLib.AutoCompletion;

type
  TSidSource = (
    ssWellKnown,         // Well-known SIDs from winnt
    ssCurrentToken,      // SIDs from the current token
    ssSamAccounts,       // SIDs of accounts in SAM domains
    ssLogonSessions,     // SIDs from logon session enumeration
    ssPerSession,        // Font Driver Host & Window Manager SIDs
    ssLogonSID,          // The SID from the window station/desktop
    ssServices,          // NT SERVICE SIDs
    ssTasks              // NT TASK SIDs
  );

  TSidSourceSet = set of TSidSource;
  TSidTypes = set of TSidNameUse;

const
  ALL_SID_SOURCES = [Low(TSidSource)..High(TSidSource)];

// Collect and SIDs from various sources
function LsaxSuggestSIDs(
  Sources: TSidSourceSet = ALL_SID_SOURCES;
  SidTypeFilter: TSidTypes = VALID_SID_TYPES
): TArray<TTranslatedName>;

// Add dynamic SID suggestion to an edit-derived control
function ShlxEnableSidSuggestions(
  EditControl: THwnd;
  Options: Cardinal = ACO_AUTOSUGGEST or ACO_UPDOWNKEYDROPSLIST
): TNtxStatus;

implementation

uses
  Ntapi.ntsam, Ntapi.ntseapi, Ntapi.WinSvc, Ntapi.ntrtl,
  Ntapi.ntioapi, Ntapi.ntpebteb, Ntapi.Versions, NtUtils.Security.Sid,
  NtUtils.Sam, NtUtils.Svc, NtUtils.WinUser, NtUtils.Tokens,
  NtUtils.Tokens.Info, NtUtils.SysUtils, NtUtils.Files, NtUtils.Files.Open,
  NtUtils.Files.Folders, NtUtils.WinStation, NtUtils.Security.Capabilities,
  DelphiUtils.Arrays, DelphiUtils.AutoObjects, NtUtils.Lsa.Logon;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxpSuggestWellKnownSIDs: TArray<ISid>;
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
    [SECURITY_NT_AUTHORITY, SECURITY_CRED_TYPE_BASE_RID, SECURITY_CRED_TYPE_THIS_ORG_CERT_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_NTLM_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_SCHANNEL_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_PACKAGE_BASE_RID, SECURITY_PACKAGE_DIGEST_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_SERVICE_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_SERVICE_ID_BASE_RID, SECURITY_SERVICE_ID_GROUP_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_VIRTUALSERVER_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_VIRTUALSERVER_ID_BASE_RID, SECURITY_VIRTUALSERVER_ID_GROUP_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_USERMODEDRIVERHOST_ID_BASE_RID, 0, 0, 0, 0, SECURITY_USERMODEDRIVERHOST_ID_GROUP_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_TASK_ID_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_WINDOW_MANAGER_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_WINDOW_MANAGER_BASE_RID, SECURITY_WINDOW_MANAGER_GROUP],
    [SECURITY_NT_AUTHORITY, SECURITY_UMFD_BASE_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_LOCAL_ACCOUNT_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_LOCAL_ACCOUNT_AND_ADMIN_RID],
    [SECURITY_NT_AUTHORITY, SECURITY_OTHER_ORGANIZATION_RID],
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
    SamxEnumerateUsers(hxDomain.Handle, Members).IsSuccess then
    AllMembers := AllMembers + Members;

  // Add groups
  if (SidTypeGroup in SidTypes) and
    SamxEnumerateGroups(hxDomain.Handle, Members).IsSuccess then
    AllMembers := AllMembers + Members;

  // Add aliases
  if (SidTypeAlias in SidTypes) and
    SamxEnumerateAliases(hxDomain.Handle, Members).IsSuccess then
    AllMembers := AllMembers + Members;

  if Length(AllMembers) = 0 then
    Exit;

  // Convers RIDs to SIDs
  SetLength(RIDs, Length(AllMembers));

  for i := 0 to High(AllMembers) do
    RIDs[i] := AllMembers[i].RelativeID;

  SamxRidsToSids(hxDomain.Handle, RIDs, Result);
end;

function RtlxpSuggestSamSIDs(
  SidTypes: TSidTypes
): TArray<ISid>;
var
  Status: TNtxStatus;
  hxServer, hxDomain: ISamHandle;
  DomainNames: TArray<String>;
  DomainSid: ISid;
  i: Integer;
begin
  Result := nil;

  if [SidTypeDomain, SidTypeUser, SidTypeGroup, SidTypeAlias] *
    SidTypes = [] then
    Exit;

  Status := SamxConnect(hxServer, SAM_SERVER_ENUMERATE_DOMAINS or
    SAM_SERVER_LOOKUP_DOMAIN);

  if not Status.IsSuccess then
    Exit;

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

      if not Status.IsSuccess then
        Continue;

      // Save nested accounts
      Result := Result + RtlxpCollectSamAccounts(hxDomain, SidTypes);
    end;
  end;
end;

function RtlxpSuggestLogonOwnerSIDs: TArray<ISid>;
var
  LogonSessions: TArray<TLogonId>;
begin
  // Snapshot logon sessions
  if not LsaxEnumerateLogonSessions(LogonSessions).IsSuccess then
    Exit(nil);

  Result := Result + TArray.Convert<TLogonId, ISid>(LogonSessions,
    function (const LogonId: TLogonId; out Sid: ISid): Boolean
    var
      Info: ILogonSession;
     begin
      // Lookup ownwer of each logon session
      Result := LsaxQueryLogonSession(LogonId, Info).IsSuccess and
        Assigned(Info.Data.SID) and RtlxCopySid(Info.Data.SID, Sid).IsSuccess;
    end
  );
end;

function RtlxpSuggestPerSessionSIDs: TArray<ISid>;
var
  Sessions: TArray<TSessionIdW>;
begin
  // Add per-session SIDs
  if RtlOsVersionAtLeast(OsWin8) then
  begin
    // Lookup all sessions when possible
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
end;

function RtlxSuggestLogonSIDs: TArray<ISid>;
var
  Sid: ISid;
begin
  if UsrxQuerySid(GetProcessWindowStation, Sid).IsSuccess and Assigned(Sid) then
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

function RtlxpSuggestTaskSIDs: TArray<ISid>;
const
  TASK_ROOT = '\SystemRoot\system32\Tasks';
var
  Status: TNtxStatus;
  TaskPrefix: String;
  OpenParameters: IFileOpenParameters;
  Tasks: TArray<ISid>;
  hxTaskDirecty: IHandle;
begin
  Result := nil;
  TaskPrefix := '';
  OpenParameters := FileOpenParameters
    .UseAccess(FILE_DIRECTORY_FILE)
    .UseOpenOptions(FILE_DIRECTORY_FILE or FILE_SYNCHRONOUS_IO_NONALERT);

  // Try opening the root of all scheduled tasks
  Status := NtxOpenFile(hxTaskDirecty, OpenParameters.UseFileName(TASK_ROOT));

  if not Status.IsSuccess then
  begin
    TaskPrefix := 'Microsoft';

    // Retry with tasks that might not require admin rights to enumerate
    Status := NtxOpenFile(hxTaskDirecty, OpenParameters
      .UseFileName(TASK_ROOT + '\' + TaskPrefix));
  end;

  if not Status.IsSuccess then
    Exit;

  Tasks := nil;

  // Traverse the tasks and collect their names
  Status := NtxTraverseFolder(hxTaskDirecty, OpenParameters,
    function(
      const FileInfo: TFolderEntry;
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
    [ftInvokeOnFiles, ftIgnoreCallbackFailures,
      ftIgnoreTraverseFailures, ftSkipReparsePoints],
    8
  );

  if Status.IsSuccess then
    Result := Tasks;
end;

function LsaxSuggestSIDs;
var
  SIDs: TArray<ISid>;
begin
  // Collect the SIDs
  SIDs := nil;

  if ssWellKnown in Sources then
    SIDs := SIDs + RtlxpSuggestWellKnownSIDs;

  if ssCurrentToken in Sources then
    SIDs := SIDs + RtlxpSuggestCurrentTokenSIDs;

  if ssSamAccounts in Sources then
    SIDs := SIDs + RtlxpSuggestSamSIDs(SidTypeFilter);

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

  // Lookup them
  if not LsaxLookupSids(SIDs, Result).IsSuccess then
    Exit(nil);

  TArray.FilterInline<TTranslatedName>(Result,
    function (const Entry: TTranslatedName): Boolean
    begin
      // Filter by type
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
    procedure Release; override;
    constructor Create;

    function Suggest(
      const Root: String;
      out Suggestions: TArray<String>
    ): TNtxStatus;
  end;

constructor TSidSuggestionProvider.Create;
begin
  inherited Create;
  Names := LsaxSuggestSIDs(ALL_SID_SOURCES, VALID_SID_TYPES);
end;

function TSidSuggestionProvider.Suggest;
const
  APP_CAPABILITY_PREFIX = APP_CAPABILITY_DOMAIN + '\';
  GROUP_CAPABILITY_PREFIX = GROUP_CAPABILITY_DOMAIN + '\';
begin
  Result.Status := STATUS_SUCCESS;

  if Root = '' then
  begin
    // Include top-level accounts only
    Suggestions := TArray.Map<TTranslatedName, String>(Names,
      function (const Account: TTranslatedName): String
      begin
        Result := RtlxExtractRootPath(Account.FullName);
      end
    );
  end
  else
  begin
    // Include well-known names under the specified root
    Suggestions := TArray.Convert<TTranslatedName, String>(Names,
      function (const Entry: TTranslatedName; out Name: String): Boolean
      begin
        Name := Entry.FullName;
        Result := RtlxPrefixString(Root, Name);
      end
    );

    // Enumerate known app capabilities
    if RtlxEqualStrings(APP_CAPABILITY_PREFIX, Root) then
      Suggestions := Suggestions + RtlxEnumerateKnownCapabilities(
        APP_CAPABILITY_PREFIX);

    // Enumerate known group capabilities
    if RtlxEqualStrings(GROUP_CAPABILITY_PREFIX, Root) then
      Suggestions := Suggestions + RtlxEnumerateKnownCapabilities(
        GROUP_CAPABILITY_PREFIX);
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
