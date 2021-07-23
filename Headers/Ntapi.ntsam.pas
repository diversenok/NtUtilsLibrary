unit Ntapi.ntsam;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

const
  samlib = 'samlib.dll';

  MAX_PREFERRED_LENGTH = MaxInt;

  // 158
  SAM_SERVER_CONNECT = $0001;
  SAM_SERVER_SHUTDOWN = $0002;
  SAM_SERVER_INITIALIZE = $0004;
  SAM_SERVER_CREATE_DOMAIN = $0008;
  SAM_SERVER_ENUMERATE_DOMAINS = $0010;
  SAM_SERVER_LOOKUP_DOMAIN = $0020;

  SAM_SERVER_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

  // 202
  DOMAIN_READ_PASSWORD_PARAMETERS = $0001;
  DOMAIN_WRITE_PASSWORD_PARAMS = $0002;
  DOMAIN_READ_OTHER_PARAMETERS = $0004;
  DOMAIN_WRITE_OTHER_PARAMETERS = $0008;
  DOMAIN_CREATE_USER = $0010;
  DOMAIN_CREATE_GROUP = $0020;
  DOMAIN_CREATE_ALIAS = $0040;
  DOMAIN_GET_ALIAS_MEMBERSHIP = $0080;
  DOMAIN_LIST_ACCOUNTS = $0100;
  DOMAIN_LOOKUP = $0200;
  DOMAIN_ADMINISTER_SERVER = $0400;

  DOMAIN_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $7FF;

  // 352, password properties
  DOMAIN_PASSWORD_COMPLEX = $00000001;
  DOMAIN_PASSWORD_NO_ANON_CHANGE = $00000002;
  DOMAIN_PASSWORD_NO_CLEAR_CHANGE = $00000004;
  DOMAIN_LOCKOUT_ADMINS = $00000008;
  DOMAIN_PASSWORD_STORE_CLEARTEXT = $00000010;
  DOMAIN_REFUSE_PASSWORD_CHANGE = $00000020;
  DOMAIN_NO_LM_OWF_CHANGE = $00000040;

  // 528
  GROUP_READ_INFORMATION = $0001;
  GROUP_WRITE_ACCOUNT = $0002;
  GROUP_ADD_MEMBER = $0004;
  GROUP_REMOVE_MEMBER = $0008;
  GROUP_LIST_MEMBERS = $0010;

  GROUP_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  // 604
  ALIAS_ADD_MEMBER = $0001;
  ALIAS_REMOVE_MEMBER = $0002;
  ALIAS_LIST_MEMBERS = $0004;
  ALIAS_READ_INFORMATION = $0008;
  ALIAS_WRITE_ACCOUNT = $0010;

  ALIAS_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  // 706
  USER_READ_GENERAL = $0001;
  USER_READ_PREFERENCES = $0002;
  USER_WRITE_PREFERENCES = $0004;
  USER_READ_LOGON = $0008;
  USER_READ_ACCOUNT = $0010;
  USER_WRITE_ACCOUNT = $0020;
  USER_CHANGE_PASSWORD = $0040;
  USER_FORCE_PASSWORD_CHANGE = $0080;
  USER_LIST_GROUPS = $0100;
  USER_READ_GROUP_INFORMATION = $0200;
  USER_WRITE_GROUP_INFORMATION = $0400;

  USER_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $7FF;

  // 761, user control flags
  USER_ACCOUNT_DISABLED = $00000001;
  USER_HOME_DIRECTORY_REQUIRED = $00000002;
  USER_PASSWORD_NOT_REQUIRED = $00000004;
  USER_TEMP_DUPLICATE_ACCOUNT = $00000008;
  USER_NORMAL_ACCOUNT = $00000010;
  USER_MNS_LOGON_ACCOUNT = $00000020;
  USER_INTERDOMAIN_TRUST_ACCOUNT = $00000040;
  USER_WORKSTATION_TRUST_ACCOUNT = $00000080;
  USER_SERVER_TRUST_ACCOUNT = $00000100;
  USER_DONT_EXPIRE_PASSWORD = $00000200;
  USER_ACCOUNT_AUTO_LOCKED = $00000400;
  USER_ENCRYPTED_TEXT_PASSWORD_ALLOWED = $00000800;
  USER_SMARTCARD_REQUIRED = $00001000;
  USER_TRUSTED_FOR_DELEGATION = $00002000;
  USER_NOT_DELEGATED = $00004000;
  USER_USE_DES_KEY_ONLY = $00008000;
  USER_DONT_REQUIRE_PREAUTH = $00010000;
  USER_PASSWORD_EXPIRED = $00020000;
  USER_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION = $00040000;
  USER_NO_AUTH_DATA_REQUIRED = $00080000;
  USER_PARTIAL_SECRETS_ACCOUNT = $00100000;
  USER_USE_AES_KEYS = $00200000;

type
  TSamHandle = NativeUInt;
  TSamEnumerationHandle = Cardinal;

  TSidArray = TAnysizeArray<PSid>;
  PSidArray = ^TSidArray;

  // SAM server

  [FriendlyName('SAM server'), ValidMask(SAM_SERVER_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SAM_SERVER_CONNECT, 'Connect')]
  [FlagName(SAM_SERVER_SHUTDOWN, 'Shutdown')]
  [FlagName(SAM_SERVER_INITIALIZE, 'Initialize')]
  [FlagName(SAM_SERVER_CREATE_DOMAIN, 'Create Domain')]
  [FlagName(SAM_SERVER_ENUMERATE_DOMAINS, 'Enumerate Domains')]
  [FlagName(SAM_SERVER_LOOKUP_DOMAIN, 'Lookup Domain')]
  TSamAccessMask = type TAccessMask;

  // 77
  TSamRidEnumeration = record
    RelativeId: Cardinal;
    Name: TNtUnicodeString;
  end;
  PSamRidEnumeration = ^TSamRidEnumeration;

  TSamRidEnumerationArray = TAnysizeArray<TSamRidEnumeration>;
  PSamRidEnumerationArray = ^TSamRidEnumerationArray;

  // 82
  TSamSidEnumeration = record
    Sid: PSid;
    Name: TNtUnicodeString;
  end;
  PSamSidEnumeration = ^TSamSidEnumeration;

  TCardinalArray = TAnysizeArray<Cardinal>;
  PCardinalArray = ^TCardinalArray;

  // Domain

  [FriendlyName('domain'), ValidMask(DOMAIN_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(DOMAIN_READ_PASSWORD_PARAMETERS, 'Read Password Parameters')]
  [FlagName(DOMAIN_WRITE_PASSWORD_PARAMS, 'Write Password Parameters')]
  [FlagName(DOMAIN_READ_OTHER_PARAMETERS, 'Read Other Parameters')]
  [FlagName(DOMAIN_WRITE_OTHER_PARAMETERS, 'Write Other Parameters')]
  [FlagName(DOMAIN_CREATE_USER, 'Create User')]
  [FlagName(DOMAIN_CREATE_GROUP, 'Create Group')]
  [FlagName(DOMAIN_CREATE_ALIAS, 'Create Alias')]
  [FlagName(DOMAIN_GET_ALIAS_MEMBERSHIP, 'Get Alias Membership')]
  [FlagName(DOMAIN_LIST_ACCOUNTS, 'List Accounts')]
  [FlagName(DOMAIN_LOOKUP, 'Lookup')]
  [FlagName(DOMAIN_ADMINISTER_SERVER, 'Administer Server')]
  TDomainAccessMask = type TAccessMask;

  // 263
  [NamingStyle(nsCamelCase, 'Domain'), Range(1)]
  TDomainInformationClass = (
    DomainReserved = 0,
    DomainPasswordInformation = 1,    // q, s: TDomainPasswordInformation
    DomainGeneralInformation = 2,     // q: TDomainGeneralInformation
    DomainLogoffInformation = 3,      // q, s: TLargeInteger
    DomainOemInformation = 4,         // q, s: TNtUnicodeString
    DomainNameInformation = 5,        // q: TNtUnicodeString
    DomainReplicationInformation = 6, // q, s: TNtUnicodeString
    DomainServerRoleInformation = 7,  // q, s: TDomainServerRole
    DomainModifiedInformation = 8,    // q: TDomainModifiedInformation
    DomainStateInformation = 9,       // q, s: TDomainServerEnableState
    DomainUasInformation = 10,        // q, s: Boolean
    DomainGeneralInformation2 = 11,   // q:
    DomainLockoutInformation = 12,    // q, s:
    DomainModifiedInformation2 = 13   // q:
  );

  // 279
  [NamingStyle(nsCamelCase, 'DomainServer'), Range(1)]
  TDomainServerEnableState = (
    DomainServerInvalid = 0,
    DomainServerEnabled = 1,
    DomainServerDisabled = 2
  );

  // 284
  [NamingStyle(nsCamelCase, 'DomainServerRole'), Range(2)]
  TDomainServerRole = (
    DomainServerRoleInvalid = 0,
    DomainServerRoleReserved = 1,
    DomainServerRoleBackup = 2,
    DomainServerRolePrimary = 3
  );

  // 290
  TDomainGeneralInformation = record
    ForceLogoff: TLargeInteger;
    OemInformation: TNtUnicodeString;
    DomainName: TNtUnicodeString;
    ReplicaSourceNodeName: TNtUnicodeString;
    DomainModifiedCount: Int64;
    DomainServerState: TDomainServerEnableState;
    DomainServerRole: TDomainServerRole;
    UasCompatibilityRequired: Boolean;
    UserCount: Cardinal;
    GroupCount: Cardinal;
    AliasCount: Cardinal;
  end;
  PDomainGeneralInformation = ^TDomainGeneralInformation;

  // 333
  TDomainPasswordInformation = record
    MinPasswordLength: Word;
    PasswordHistoryLength: Word;
    PasswordProperties: Cardinal;
    MaxPasswordAge: TLargeInteger;
    MinPasswordAge: TLargeInteger;
  end;
  PDomainPasswordInformation = TDomainPasswordInformation;

  // 394
  TDomainModifiedInformation = record
    DomainModifiedCount: Int64;
    CreationTime: TLargeInteger;
  end;
  PDomainModifiedInformation = ^TDomainModifiedInformation;

  // Group

  [FriendlyName('group'), ValidMask(GROUP_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(GROUP_READ_INFORMATION, 'Read Information')]
  [FlagName(GROUP_WRITE_ACCOUNT, 'Write Account')]
  [FlagName(GROUP_ADD_MEMBER, 'Add Member')]
  [FlagName(GROUP_REMOVE_MEMBER, 'Remove Member')]
  [FlagName(GROUP_LIST_MEMBERS, 'List Members')]
  TGroupAccessMask = type TAccessMask;

  // 559
  TGroupMembership = record
    RelativeId: Cardinal;
    [Hex] Attributes: Cardinal;
  end;
  PGroupMembership = ^TGroupMembership;

  PGroupMembershipArray = TAnysizeArray<PGroupMembership>;

  // 565
  [NamingStyle(nsCamelCase, 'Group'), Range(1)]
  TGroupInformationClass = (
    GroupReserved = 0,
    GroupGeneralInformation = 1,     // q: TGroupGeneralInformation
    GroupNameInformation = 2,        // q, s: TNtUnicodeString;
    GroupAttributeInformation = 3,   // q, s: Cardinal
    GroupAdminCommentInformation = 4 // q, s: TNtUnicodeString;
  );

  // 573
  TGroupGeneralInformation = record
    Name: TNtUnicodeString;
    [Hex] Attributes: Cardinal;
    MemberCount: Cardinal;
    AdminComment: TNtUnicodeString;
  end;
  PGroupGeneralInformation = ^TGroupGeneralInformation;

  // Alias

  [FriendlyName('alias'), ValidMask(ALIAS_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(ALIAS_ADD_MEMBER, 'Add Member')]
  [FlagName(ALIAS_REMOVE_MEMBER, 'Remove Member')]
  [FlagName(ALIAS_LIST_MEMBERS, 'List Members')]
  [FlagName(ALIAS_READ_INFORMATION, 'Read Information')]
  [FlagName(ALIAS_WRITE_ACCOUNT, 'Write Account')]
  TAliasAccessMask = type TAccessMask;

  // 634
  [NamingStyle(nsCamelCase, 'Alias'), Range(1)]
  TAliasInformationClass = (
    AliasReserved = 0,
    AliasGeneralInformation = 1,      // q: TAliasGeneralInformation
    AliasNameInformation = 2,         // q, s: TNtUnicodeString
    AliasAdminCommentInformation = 3, // q, s: TNtUnicodeString
    AliasReplicationInformation = 4,  // q: TNtUnicodeString
    AliasExtendedInformation = 5      // q, s:
  );

  // 642
  TAliasGeneralInformation = record
    Name: TNtUnicodeString;
    MemberCount: Cardinal;
    AdminComment: TNtUnicodeString;
  end;
  PAliasGeneralInformation = ^TAliasGeneralInformation;

  // User

  [FriendlyName('user'), ValidMask(USER_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(USER_READ_GENERAL, 'Read General')]
  [FlagName(USER_READ_PREFERENCES, 'Read Preferences')]
  [FlagName(USER_WRITE_PREFERENCES, 'Write Preferences')]
  [FlagName(USER_READ_LOGON, 'Read Logon')]
  [FlagName(USER_READ_ACCOUNT, 'Read Account')]
  [FlagName(USER_WRITE_ACCOUNT, 'Write Account')]
  [FlagName(USER_CHANGE_PASSWORD, 'Change Password')]
  [FlagName(USER_FORCE_PASSWORD_CHANGE, 'Force Password Change')]
  [FlagName(USER_LIST_GROUPS, 'List Groups')]
  [FlagName(USER_READ_GROUP_INFORMATION, 'Read Group Information')]
  [FlagName(USER_WRITE_GROUP_INFORMATION, 'Write Group Information')]
  TUserAccessMask = type TAccessMask;

  // 829
  TLogonHours = record
    UnitsPerWeek: Word;
    LogonHours: PByte;
  end;

  // 860
  [NamingStyle(nsCamelCase, 'User'), Range(1)]
  TUserInformationClass = (
    UserReserved = 0,
    UserGeneralInformation = 1,       // q: TUserGeneralInformation
    UserPreferencesInformation = 2,   // q, s: TUserPreferencesInformation
    UserLogonInformation = 3,         // q: TUserLogonInformation
    UserLogonHoursInformation = 4,    // q, s: TLogonHours
    UserAccountInformation = 5,       // q: TUserAccountInformation
    UserNameInformation = 6,          // q, s: {Name + Full name}
    UserAccountNameInformation = 7,   // q, s: TNtUnicodeString
    UserFullNameInformation = 8,      // q, s: TNtUnicodeString
    UserPrimaryGroupInformation = 9,  // q, s: Cardinal
    UserHomeInformation = 10,         // q, s: TUserHomeInformation
    UserScriptInformation = 11,       // q, s: TNtUnicodeString
    UserProfileInformation = 12,      // q, s: TNtUnicodeString
    UserAdminCommentInformation = 13, // q, s: TNtUnicodeString
    UserWorkStationsInformation = 14, // q, s: TNtUnicodeString
    UserSetPasswordInformation = 15,  // s: TUserSetPasswordInformation
    UserControlInformation = 16,      // q, s: Cardinal
    UserExpiresInformation = 17,      // q, s: TLargeInteger
    UserInternal1Information = 18,    // q, s:
    UserInternal2Information = 19,    // q, s:
    UserParametersInformation = 20,   // q, s: TNtUnicodeString
    UserAllInformation = 21,          // q, s:
    UserInternal3Information = 22,    // q, s:
    UserInternal4Information = 23,    // s:
    UserInternal5Information = 24,    // s:
    UserInternal4InformationNew = 25, // s:
    UserInternal5InformationNew = 26, // s:
    UserInternal6Information = 27,    // q, s:
    UserExtendedInformation = 28,     // q, s:
    UserLogonUIInformation = 29       // q: TUserLogonUiInformation
  );

  // 1105
  TUserGeneralInformation = record
    UserName: TNtUnicodeString;
    FullName: TNtUnicodeString;
    PrimaryGroupId: Cardinal;
    AdminComment: TNtUnicodeString;
    UserComment: TNtUnicodeString;
  end;
  PUserGeneralInformation = ^TUserGeneralInformation;

  // 1113
  TUserPreferencesInformation = record
    UserComment: TNtUnicodeString;
    Reserved1: TNtUnicodeString;
    CountryCode: Word;
    CodePage: Word;
  end;
  PUserPreferencesInformation = ^TUserPreferencesInformation;

  // 1125
  TUserLogonInformation = packed record
    UserName: TNtUnicodeString;
    FullName: TNtUnicodeString;
    UserId: Cardinal;
    PrimaryGroupId: Cardinal;
    HomeDirectory: TNtUnicodeString;
    HomeDirectoryDrive: TNtUnicodeString;
    ScriptPath: TNtUnicodeString;
    ProfilePath: TNtUnicodeString;
    WorkStations: TNtUnicodeString;
    LastLogon: TLargeInteger;
    LastLogoff: TLargeInteger;
    PasswordLastSet: TLargeInteger;
    PasswordCanChange: TLargeInteger;
    PasswordMustChange: TLargeInteger;
    LogonHours: TLogonHours;
    BadPasswordCount: Word;
    LogonCount: Word;
    UserAccountControl: Cardinal;
  end;
  PUserLogonInformation = ^TUserLogonInformation;

  // 1148
  TUserAccountInformation = packed record
    UserName: TNtUnicodeString;
    FullName: TNtUnicodeString;
    UserId: Cardinal;
    PrimaryGroupId: Cardinal;
    HomeDirectory: TNtUnicodeString;
    HomeDirectoryDrive: TNtUnicodeString;
    ScriptPath: TNtUnicodeString;
    ProfilePath: TNtUnicodeString;
    AdminComment: TNtUnicodeString;
    WorkStations: TNtUnicodeString;
    LastLogon: TLargeInteger;
    LastLogoff: TLargeInteger;
    LogonHours: TLogonHours;
    BadPasswordCount: Word;
    LogonCount: Word;
    PasswordLastSet: TLargeInteger;
    AccountExpires: TLargeInteger;
    UserAccountControl: Cardinal;
  end;
  PUserAccountInformation = ^TUserAccountInformation;

  // 1187
  TUserHomeInformation = record
    HomeDirectory: TNtUnicodeString;
    HomeDirectoryDrive: TNtUnicodeString;
  end;
  PUserHomeInformation = ^TUserHomeInformation;

  // 1208
  TUserSetPasswordInformation = record
    Password: TNtUnicodeString;
    PasswordExpired: Boolean;
  end;
  PUserSetPasswordInformation = ^TUserSetPasswordInformation;

  // 1249
  TUserLogonUiInformation = record
    PasswordIsBlank: Boolean;
    AccountIsDisabled: Boolean;
  end;
  PUserLogonUiInformation = ^TUserLogonUiInformation;

{ Common }

// 1777
function SamFreeMemory(
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

// 1784
function SamSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] ObjectHandle: TSamHandle;
  SecurityInformation: TSecurityInformation;
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external samlib;

// 1792
function SamQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] ObjectHandle: TSamHandle;
  SecurityInformation: TSamHandle;
  out SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external samlib;

// 1799
function SamCloseHandle(
  SamHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

{  SAM Server }

// 1805
function SamConnect(
  [in, opt] ServerName: PNtUnicodeString;
  out ServerHandle: TSamHandle;
  DesiredAccess: TSamAccessMask;
  const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external samlib;

// 1814
function SamShutdownSamServer(
  [Access(SAM_SERVER_SHUTDOWN)] ServerHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

{ Domain }

// 1820
function SamLookupDomainInSamServer(
  [Access(SAM_SERVER_LOOKUP_DOMAIN)] ServerHandle: TSamHandle;
  const Name: TNtUnicodeString;
  [allocates] out DomainId: PSid
): NTSTATUS; stdcall; external samlib;

// 1828
function SamEnumerateDomainsInSamServer(
  [Access(SAM_SERVER_ENUMERATE_DOMAINS)] ServerHandle: TSamHandle;
  var EnumerationContext: TSamEnumerationHandle;
  [allocates] out Buffer: PSamRidEnumerationArray;
  PreferedMaximumLength: Integer;
  out CountReturned: Integer
): NTSTATUS; stdcall; external samlib;

// 1838
function SamOpenDomain(
  [Access(SAM_SERVER_LOOKUP_DOMAIN)] ServerHandle: TSamHandle;
  DesiredAccess: TDomainAccessMask;
  [in] DomainId: PSid;
  out DomainHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

// 1847
function SamQueryInformationDomain(
  [Access(DOMAIN_READ_OTHER_PARAMETERS or
    DOMAIN_READ_PASSWORD_PARAMETERS)] DomainHandle: TSamHandle;
  DomainInformationClass: TDomainInformationClass;
  [allocates] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

// 1855
function SamSetInformationDomain(
  [Access(DOMAIN_WRITE_PASSWORD_PARAMS or
    DOMAIN_WRITE_OTHER_PARAMETERS)] DomainHandle: TSamHandle;
  DomainInformationClass: TDomainInformationClass;
  [in] DomainInformation: Pointer
): NTSTATUS; stdcall; external samlib;

// 1863
function SamCreateGroupInDomain(
  [Access(DOMAIN_CREATE_GROUP)] DomainHandle: TSamHandle;
  const AccountName: TNtUnicodeString;
  DesiredAccess: TGroupAccessMask;
  out GroupHandle: TSamHandle;
  out RelativeId: Cardinal
): NTSTATUS; stdcall; external samlib;

// 1874
function SamEnumerateGroupsInDomain(
  [Access(DOMAIN_LIST_ACCOUNTS)] DomainHandle: TSamHandle;
  var EnumerationContext: TSamEnumerationHandle;
  [allocates] out Buffer: PSamRidEnumerationArray;
  PreferedMaximumLength: Integer;
  out CountReturned: Integer
): NTSTATUS; stdcall; external samlib;

// 1884
function SamCreateUser2InDomain(
   [Access(DOMAIN_CREATE_USER)] DomainHandle: TSamHandle;
  const AccountName: TNtUnicodeString;
  AccountType: Cardinal;
  DesiredAccess: TUserAccessMask;
  out UserHandle: TSamHandle;
  out GrantedAccess: TUserAccessMask;
  out RelativeId: Cardinal
): NTSTATUS; stdcall; external samlib;

// 1906
function SamEnumerateUsersInDomain(
  [Access(DOMAIN_LIST_ACCOUNTS)] DomainHandle: TSamHandle;
  var EnumerationContext: TSamEnumerationHandle;
  UserAccountControl: Cardinal;
  [allocates] out Buffer: PSamRidEnumerationArray;
  PreferedMaximumLength: Integer;
  out CountReturned: Integer
): NTSTATUS; stdcall; external samlib;

// 1917
function SamCreateAliasInDomain(
  [Access(DOMAIN_CREATE_ALIAS)] DomainHandle: TSamHandle;
  const AccountName: TNtUnicodeString;
  DesiredAccess: TAliasAccessMask;
  out AliasHandle: TSamHandle;
  out RelativeId: Cardinal
): NTSTATUS; stdcall; external samlib;

// 1927
function SamEnumerateAliasesInDomain(
  [Access(DOMAIN_LIST_ACCOUNTS)] DomainHandle: TSamHandle;
  var EnumerationContext: TSamEnumerationHandle;
  [allocates] out Buffer: PSamRidEnumerationArray;
  PreferedMaximumLength: Integer;
  out CountReturned: Integer
): NTSTATUS; stdcall; external samlib;

{ Group }

// 1967
function SamOpenGroup(
  [Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  DesiredAccess: TGroupAccessMask;
  GroupId: Cardinal;
  out GroupHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

// 1976
function SamQueryInformationGroup(
  [Access(GROUP_READ_INFORMATION)] GroupHandle: TSamHandle;
  GroupInformationClass: TGroupInformationClass;
  [allocates] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

// 1984
function SamSetInformationGroup(
  [Access(GROUP_WRITE_ACCOUNT)] GroupHandle: TSamHandle;
  GroupInformationClass: TGroupInformationClass;
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

// 1992
function SamAddMemberToGroup(
  [Access(GROUP_ADD_MEMBER)] GroupHandle: TSamHandle;
  MemberId: Cardinal;
  Attributes: Cardinal
): NTSTATUS; stdcall; external samlib;

// 2000
function SamDeleteGroup(
  [Access(_DELETE)] GroupHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

// 2006
function SamRemoveMemberFromGroup(
  [Access(GROUP_REMOVE_MEMBER)] GroupHandle: TSamHandle;
  MemberId: Cardinal
): NTSTATUS; stdcall; external samlib;

// 2013
function SamGetMembersInGroup(
  [Access(GROUP_LIST_MEMBERS)] GroupHandle: TSamHandle;
  [allocates] out MemberIds: PCardinalArray;
  [allocates] out Attributes: PCardinalArray;
  out MemberCount: Integer
): NTSTATUS; stdcall; external samlib;

// 2022
function SamSetMemberAttributesOfGroup(
  [Access(GROUP_ADD_MEMBER)] GroupHandle: TSamHandle;
  MemberId: Cardinal;
  Attributes: Cardinal
): NTSTATUS; stdcall; external samlib;

{ Alias }

// 2030
function SamOpenAlias(
  [Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  DesiredAccess: TAliasAccessMask;
  AliasId: Cardinal;
  out AliasHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

// 2039
function SamQueryInformationAlias(
  [Access(ALIAS_READ_INFORMATION)] AliasHandle: TSamHandle;
  AliasInformationClass: TAliasInformationClass;
  [allocates] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

// 2047
function SamSetInformationAlias(
  [Access(ALIAS_WRITE_ACCOUNT)] AliasHandle: TSamHandle;
  AliasInformationClass: TAliasInformationClass;
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

// 2055
function SamDeleteAlias(
  [Access(_DELETE)] AliasHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

// 2061
function SamAddMemberToAlias(
  [Access(ALIAS_ADD_MEMBER)] AliasHandle: TSamHandle;
  [in] MemberId: PSid
): NTSTATUS; stdcall; external samlib;

// 2068
function SamAddMultipleMembersToAlias(
  [Access(ALIAS_ADD_MEMBER)] AliasHandle: TSamHandle;
  [in] MemberIds: TArray<PSid>;
  MemberCount: Cardinal
): NTSTATUS; stdcall; external samlib;

// 2076
function SamRemoveMemberFromAlias(
  [Access(ALIAS_REMOVE_MEMBER)] AliasHandle: TSamHandle;
  [in] MemberId: PSid
): NTSTATUS; stdcall; external samlib;

// 2083
function SamRemoveMultipleMembersFromAlias(
  [Access(ALIAS_REMOVE_MEMBER)] AliasHandle: TSamHandle;
  [in] MemberIds: TArray<PSid>;
  MemberCount: Cardinal
): NTSTATUS; stdcall; external samlib;

// 2098
function SamGetMembersInAlias(
  [Access(ALIAS_LIST_MEMBERS)] AliasHandle: TSamHandle;
  [allocates] out MemberIds: PSidArray;
  out MemberCount: Integer
): NTSTATUS; stdcall; external samlib;

{ User }

// 2106
function SamOpenUser(
  [Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  DesiredAccess: TUserAccessMask;
  UserId: Cardinal;
  out UserHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

// 2115
function SamDeleteUser(
  [Access(_DELETE)] UserHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

// 2121
function SamQueryInformationUser(
  [Access(USER_READ_GENERAL or USER_READ_PREFERENCES or
    USER_READ_LOGON or USER_READ_ACCOUNT)] UserHandle: TSamHandle;
  UserInformationClass: TUserInformationClass;
  [allocates] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

// 2129
function SamSetInformationUser(
  [Access(USER_WRITE_ACCOUNT)] UserHandle: TSamHandle;
  UserInformationClass: TUserInformationClass;
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

// 2137
function SamChangePasswordUser(
  [Access(USER_CHANGE_PASSWORD)] UserHandle: TSamHandle;
  const OldPassword: TNtUnicodeString;
  const NewPassword: TNtUnicodeString
): NTSTATUS; stdcall; external samlib;

// 2167
function SamGetGroupsForUser(
  [Access(USER_LIST_GROUPS)] UserHandle: TSamHandle;
  [allocates] out Groups: PGroupMembershipArray;
  out MembershipCount: Integer
): NTSTATUS; stdcall; external samlib;

// 2198
function SamRidToSid(
  ObjectHandle: TSamHandle;
  Rid: Cardinal;
  [allocates] out Sid: PSid
): NTSTATUS; stdcall; external samlib;

{ Expected Access Masks }

function ExpectedDomainQueryAccess(
  InfoClass: TDomainInformationClass
): TDomainAccessMask;

function ExpectedDomainSetAccess(
  InfoClass: TDomainInformationClass
): TDomainAccessMask;

function ExpectedUserQueryAccess(
  InfoClass: TUserInformationClass
): TUserAccessMask;

function ExpectedUserSetAccess(
  InfoClass: TUserInformationClass
): TUserAccessMask;

implementation

function ExpectedDomainQueryAccess;
begin
  // See [MS-SAMR]
  case InfoClass of
    DomainGeneralInformation, DomainLogoffInformation, DomainOemInformation,
    DomainNameInformation, DomainReplicationInformation,
    DomainServerRoleInformation, DomainModifiedInformation,
    DomainStateInformation, DomainUasInformation, DomainModifiedInformation2:
      Result := DOMAIN_READ_OTHER_PARAMETERS;

    DomainPasswordInformation, DomainLockoutInformation:
      Result := DOMAIN_READ_PASSWORD_PARAMETERS;

    DomainGeneralInformation2:
      Result := DOMAIN_READ_PASSWORD_PARAMETERS or DOMAIN_READ_OTHER_PARAMETERS;
  else
    Result := 0;
  end;
end;

function ExpectedDomainSetAccess;
begin
  // See [MS-SAMR]
  case InfoClass of
    DomainPasswordInformation, DomainLockoutInformation:
      Result := DOMAIN_WRITE_PASSWORD_PARAMS;

    DomainLogoffInformation, DomainOemInformation, DomainUasInformation:
      Result := DOMAIN_WRITE_OTHER_PARAMETERS;

    DomainReplicationInformation, DomainServerRoleInformation,
    DomainStateInformation:
      Result := DOMAIN_ADMINISTER_SERVER;
  else
    Result := 0;
  end;
end;

function ExpectedUserQueryAccess;
begin
  // See [MS-SAMR]
  case InfoClass of
    UserGeneralInformation, UserNameInformation, UserAccountNameInformation,
    UserFullNameInformation, UserPrimaryGroupInformation,
    UserAdminCommentInformation:
      Result := USER_READ_GENERAL;

    UserLogonHoursInformation, UserHomeInformation, UserScriptInformation,
    UserProfileInformation, UserWorkStationsInformation:
      Result := USER_READ_LOGON;

    UserControlInformation, UserExpiresInformation, UserInternal1Information,
    UserParametersInformation:
      Result := USER_READ_ACCOUNT;

    UserPreferencesInformation:
      Result := USER_READ_PREFERENCES or USER_READ_GENERAL;

    UserLogonInformation, UserAccountInformation:
      Result := USER_READ_GENERAL or USER_READ_PREFERENCES or USER_READ_LOGON
        or USER_READ_ACCOUNT;
  else
    Result := 0;
  end;
end;

function ExpectedUserSetAccess;
begin
  // See [MS-SAMR]
  case InfoClass of
    UserLogonHoursInformation, UserNameInformation, UserAccountNameInformation,
    UserFullNameInformation, UserPrimaryGroupInformation, UserHomeInformation,
    UserScriptInformation, UserProfileInformation, UserAdminCommentInformation,
    UserWorkStationsInformation, UserControlInformation, UserExpiresInformation,
    UserParametersInformation:
      Result := USER_WRITE_ACCOUNT;

    UserPreferencesInformation:
      Result := USER_WRITE_PREFERENCES;

    UserSetPasswordInformation:
      Result := USER_FORCE_PASSWORD_CHANGE;
  else
    Result := 0;
  end;
end;

end.
