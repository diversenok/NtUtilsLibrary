unit Ntapi.ntsam;

{
  This file defines functions for accessing Security Account Manager database.
  For sources and explanations, see specification MS-SAMR and PHNT::ntsam.h
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, DelphiApi.Reflection;

const
  samlib = 'samlib.dll';

  // server access masks
  SAM_SERVER_CONNECT = $0001;
  SAM_SERVER_SHUTDOWN = $0002;
  SAM_SERVER_INITIALIZE = $0004;
  SAM_SERVER_CREATE_DOMAIN = $0008;
  SAM_SERVER_ENUMERATE_DOMAINS = $0010;
  SAM_SERVER_LOOKUP_DOMAIN = $0020;

  SAM_SERVER_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

  // domain access masks
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

  // password properties
  DOMAIN_PASSWORD_COMPLEX = $00000001;
  DOMAIN_PASSWORD_NO_ANON_CHANGE = $00000002;
  DOMAIN_PASSWORD_NO_CLEAR_CHANGE = $00000004;
  DOMAIN_LOCKOUT_ADMINS = $00000008;
  DOMAIN_PASSWORD_STORE_CLEARTEXT = $00000010;
  DOMAIN_REFUSE_PASSWORD_CHANGE = $00000020;
  DOMAIN_NO_LM_OWF_CHANGE = $00000040;

  // group access masks
  GROUP_READ_INFORMATION = $0001;
  GROUP_WRITE_ACCOUNT = $0002;
  GROUP_ADD_MEMBER = $0004;
  GROUP_REMOVE_MEMBER = $0008;
  GROUP_LIST_MEMBERS = $0010;

  GROUP_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  // alias access masks
  ALIAS_ADD_MEMBER = $0001;
  ALIAS_REMOVE_MEMBER = $0002;
  ALIAS_LIST_MEMBERS = $0004;
  ALIAS_READ_INFORMATION = $0008;
  ALIAS_WRITE_ACCOUNT = $0010;

  ALIAS_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1F;

  // user access masks
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

  // user control flags
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

  // user all information
  USER_ALL_USERNAME = $00000001;
  USER_ALL_FULLNAME = $00000002;
  USER_ALL_USERID = $00000004;
  USER_ALL_PRIMARYGROUPID = $00000008;
  USER_ALL_ADMINCOMMENT = $00000010;
  USER_ALL_USERCOMMENT = $00000020;
  USER_ALL_HOMEDIRECTORY = $00000040;
  USER_ALL_HOMEDIRECTORYDRIVE = $00000080;
  USER_ALL_SCRIPTPATH = $00000100;
  USER_ALL_PROFILEPATH = $00000200;
  USER_ALL_WORKSTATIONS = $00000400;
  USER_ALL_LASTLOGON = $00000800;
  USER_ALL_LASTLOGOFF = $00001000;
  USER_ALL_LOGONHOURS = $00002000;
  USER_ALL_BADPASSWORDCOUNT = $00004000;
  USER_ALL_LOGONCOUNT = $00008000;
  USER_ALL_PASSWORDCANCHANGE = $00010000;
  USER_ALL_PASSWORDMUSTCHANGE = $00020000;
  USER_ALL_PASSWORDLASTSET = $00040000;
  USER_ALL_ACCOUNTEXPIRES = $00080000;
  USER_ALL_USERACCOUNTCONTROL = $00100000;
  USER_ALL_PARAMETERS = $00200000;
  USER_ALL_COUNTRYCODE = $00400000;
  USER_ALL_CODEPAGE = $00800000;
  USER_ALL_NTPASSWORDPRESENT = $01000000;
  USER_ALL_LMPASSWORDPRESENT = $02000000;
  USER_ALL_PRIVATEDATA = $04000000;
  USER_ALL_PASSWORDEXPIRED = $08000000;
  USER_ALL_SECURITYDESCRIPTOR = $10000000;
  USER_ALL_OWFPASSWORD = $20000000;

type
  TSamHandle = NativeUInt;
  TSamEnumerationHandle = Cardinal;

  TSidArray = TAnysizeArray<PSid>;
  PSidArray = ^TSidArray;

  TCardinalArray = TAnysizeArray<Cardinal>;
  PCardinalArray = ^TCardinalArray;

  TNameUseArray = TAnysizeArray<TSidNameUse>;
  PNameUseArray = ^TNameUseArray;

  TNtUnicodeStringArray = TAnysizeArray<TNtUnicodeString>;
  PNtUnicodeStringArray = ^TNtUnicodeStringArray;

  [FriendlyName('SAM server'), ValidMask(SAM_SERVER_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SAM_SERVER_CONNECT, 'Connect')]
  [FlagName(SAM_SERVER_SHUTDOWN, 'Shutdown')]
  [FlagName(SAM_SERVER_INITIALIZE, 'Initialize')]
  [FlagName(SAM_SERVER_CREATE_DOMAIN, 'Create Domain')]
  [FlagName(SAM_SERVER_ENUMERATE_DOMAINS, 'Enumerate Domains')]
  [FlagName(SAM_SERVER_LOOKUP_DOMAIN, 'Lookup Domain')]
  TSamAccessMask = type TAccessMask;

  [FlagName(USER_ACCOUNT_DISABLED, 'Account Disabled')]
  [FlagName(USER_HOME_DIRECTORY_REQUIRED, 'Home Directory Required')]
  [FlagName(USER_PASSWORD_NOT_REQUIRED, 'Password Not Required')]
  [FlagName(USER_TEMP_DUPLICATE_ACCOUNT, 'Temp Duplicate Account')]
  [FlagName(USER_NORMAL_ACCOUNT, 'Normal Account')]
  [FlagName(USER_MNS_LOGON_ACCOUNT, 'MNS Logon Account')]
  [FlagName(USER_INTERDOMAIN_TRUST_ACCOUNT, 'Inter-domain Trust Account')]
  [FlagName(USER_WORKSTATION_TRUST_ACCOUNT, 'User Workstation Trust Account')]
  [FlagName(USER_SERVER_TRUST_ACCOUNT, 'User Server Trust Account')]
  [FlagName(USER_DONT_EXPIRE_PASSWORD, 'Password Does Not Expire')]
  [FlagName(USER_ACCOUNT_AUTO_LOCKED, 'Auto Locked')]
  [FlagName(USER_ENCRYPTED_TEXT_PASSWORD_ALLOWED, 'Encrypted Text Password Allowed')]
  [FlagName(USER_SMARTCARD_REQUIRED, 'Smartcard Required')]
  [FlagName(USER_TRUSTED_FOR_DELEGATION, 'Trusted For Delegation')]
  [FlagName(USER_NOT_DELEGATED, 'Not Delegated')]
  [FlagName(USER_USE_DES_KEY_ONLY, 'Use DES Key Only')]
  [FlagName(USER_DONT_REQUIRE_PREAUTH, 'Preauth Not Required')]
  [FlagName(USER_PASSWORD_EXPIRED, 'Password Expired')]
  [FlagName(USER_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION, 'Trusted To Authenticate For Delegation')]
  [FlagName(USER_NO_AUTH_DATA_REQUIRED, 'No Auth Data Required')]
  [FlagName(USER_PARTIAL_SECRETS_ACCOUNT, 'Partial Secrets Account')]
  [FlagName(USER_USE_AES_KEYS, 'Use AES Keys')]
  TUserAccountFlags = type Cardinal;

  [SDKName('SAM_RID_ENUMERATION')]
  TSamRidEnumeration = record
    RelativeId: Cardinal;
    Name: TNtUnicodeString;
  end;
  PSamRidEnumeration = ^TSamRidEnumeration;

  TSamRidEnumerationArray = TAnysizeArray<TSamRidEnumeration>;
  PSamRidEnumerationArray = ^TSamRidEnumerationArray;

  [SDKName('SAM_SID_ENUMERATION')]
  TSamSidEnumeration = record
    Sid: PSid;
    Name: TNtUnicodeString;
  end;
  PSamSidEnumeration = ^TSamSidEnumeration;

  [SDKName('SECURITY_DB_OBJECT_TYPE')]
  [NamingStyle(nsCamelCase, 'SecurityDbObject'), Range(1)]
  TSecurityDbObjectType = (
    SecurityDbObjectReserved = 0,
    SecurityDbObjectSamDomain = 1,
    SecurityDbObjectSamUser = 2,
    SecurityDbObjectSamGroup = 3,
    SecurityDbObjectSamAlias = 4,
    SecurityDbObjectLsaPolicy = 5,
    SecurityDbObjectLsaTDomain = 6,
    SecurityDbObjectLsaAccount = 7,
    SecurityDbObjectLsaSecret = 8
  );

  // Domain Info

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

  [SDKName('DOMAIN_INFORMATION_CLASS')]
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
    DomainGeneralInformation2 = 11,   // q: TDomainGeneralInformation2
    DomainLockoutInformation = 12,    // q, s: TDomainLockoutInformation
    DomainModifiedInformation2 = 13   // q: TDomainModifiedInformation2
  );

  [SDKName('DOMAIN_SERVER_ENABLE_STATE')]
  [NamingStyle(nsCamelCase, 'DomainServer'), Range(1)]
  TDomainServerEnableState = (
    DomainServerInvalid = 0,
    DomainServerEnabled = 1,
    DomainServerDisabled = 2
  );

  [SDKName('DOMAIN_SERVER_ROLE')]
  [NamingStyle(nsCamelCase, 'DomainServerRole'), Range(2)]
  TDomainServerRole = (
    DomainServerRoleInvalid = 0,
    DomainServerRoleReserved = 1,
    DomainServerRoleBackup = 2,
    DomainServerRolePrimary = 3
  );

  [FlagName(DOMAIN_PASSWORD_COMPLEX, 'Complex')]
  [FlagName(DOMAIN_PASSWORD_NO_ANON_CHANGE, 'No Anonymous Change')]
  [FlagName(DOMAIN_PASSWORD_NO_CLEAR_CHANGE, 'No Clear Change')]
  [FlagName(DOMAIN_LOCKOUT_ADMINS, 'Lockout Admins')]
  [FlagName(DOMAIN_PASSWORD_STORE_CLEARTEXT, 'Store Cleartext')]
  [FlagName(DOMAIN_REFUSE_PASSWORD_CHANGE, 'Refuse Password Change')]
  [FlagName(DOMAIN_NO_LM_OWF_CHANGE, 'No LM OWF Change')]
  TPasswordProperties = type Cardinal;

  // info class 1
  [SDKName('DOMAIN_PASSWORD_INFORMATION')]
  TDomainPasswordInformation = record
    MinPasswordLength: Word;
    PasswordHistoryLength: Word;
    PasswordProperties: TPasswordProperties;
    MaxPasswordAge: TLargeInteger;
    MinPasswordAge: TLargeInteger;
  end;
  PDomainPasswordInformation = TDomainPasswordInformation;

  // info class 2
  [SDKName('DOMAIN_GENERAL_INFORMATION')]
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

  // info class 8
  [SDKName('DOMAIN_MODIFIED_INFORMATION')]
  TDomainModifiedInformation = record
    DomainModifiedCount: Int64;
    CreationTime: TLargeInteger;
  end;
  PDomainModifiedInformation = ^TDomainModifiedInformation;

  // info class 12
  [SDKName('DOMAIN_LOCKOUT_INFORMATION')]
  TDomainLockoutInformation = record
    LockoutDuration: TLargeInteger;
    LockoutObservationWindow: TLargeInteger;
    LockoutThreshold: Word;
  end;
  PDomainLockoutInformation = ^TDomainLockoutInformation;

  // info class 11
  [SDKName('DOMAIN_GENERAL_INFORMATION2')]
  TDomainGeneralInformation2 = record
    [Aggregate] General: TDomainGeneralInformation;
    [Aggregate] Lockout: TDomainLockoutInformation;
  end;
  PDomainGeneralInformation2 = ^TDomainGeneralInformation2;

  // info class 13
  [SDKName('DOMAIN_MODIFIED_INFORMATION2')]
  TDomainModifiedInformation2 = record
    DomainModifiedCount: Int64;
    CreationTime: TLargeInteger;
    ModifiedCountAtLastPromotion: Int64;
  end;
  PDomainModifiedInformation2 = ^TDomainModifiedInformation2;

  // Domain Display Info

  [SDKName('DOMAIN_DISPLAY_INFORMATION')]
  [NamingStyle(nsCamelCase, 'DomainDisplay'), Range(1)]
  TDomainDisplayInformation = (
    DomainDisplayReserved = 0,
    DomainDisplayUser = 1,    // q: TDomainDisplayUser
    DomainDisplayMachine = 2, // q: TDomainDisplayMachine
    DomainDisplayGroup = 3,   // q: TDomainDisplayGroup
    DomainDisplayOEMUser = 4, // q: TDomainDisplayOemUser
    DomainDisplayOEMGroup = 5 // q: TDomainDisplayOemGroup
  );

  // info class 1
  [SDKName('DOMAIN_DISPLAY_USER')]
  TDomainDisplayUser = record
    Index: Cardinal;
    Rid: Cardinal;
    AccountControl: TUserAccountFlags;
    LogonName: TNtUnicodeString;
    AdminComment: TNtUnicodeString;
    FullName: TNtUnicodeString;
  end;
  PDomainDisplayUser = ^TDomainDisplayUser;

  // info class 2
  [SDKName('DOMAIN_DISPLAY_MACHINE')]
  TDomainDisplayMachine = record
    Index: Cardinal;
    Rid: Cardinal;
    AccountControl: TUserAccountFlags;
    Machine: TNtUnicodeString;
    Comment: TNtUnicodeString;
  end;
  PDomainDisplayMachine = ^TDomainDisplayMachine;

  // info class 3
  [SDKName('DOMAIN_DISPLAY_GROUP')]
  TDomainDisplayGroup = record
    Index: Cardinal;
    Rid: Cardinal;
    Attributes: TGroupAttributes;
    Group: TNtUnicodeString;
    Comment: TNtUnicodeString;
  end;
  PDomainDisplayGroup = ^TDomainDisplayGroup;

  // info class 4
  [SDKName('DOMAIN_DISPLAY_OEM_USER')]
  TDomainDisplayOemUser = record
    Index: Cardinal;
    User: TNtAnsiString;
  end;
  PDomainDisplayOemUser = ^TDomainDisplayOemUser;

  // info class 5
  [SDKName('DOMAIN_DISPLAY_OEM_GROUP')]
  TDomainDisplayOemGroup = record
    Index: Cardinal;
    Group: TNtAnsiString;
  end;
  PDomainDisplayOemGroup = ^TDomainDisplayOemGroup;

  // Domain Localization

  [SDKName('DOMAIN_LOCALIZABLE_ACCOUNTS_INFORMATION')]
  [NamingStyle(nsCamelCase, 'DomainLocalizableAccounts'), Range(1)]
  TDomainLocalizableAccountsInformation = (
    DomainLocalizableAccountsReserved = 0,
    DomainLocalizableAccountsBasic = 1 // q: TDomainLocalizableAccounts
  );

  [SDKName('DOMAIN_LOCALIZABLE_ACCOUNT_ENTRY')]
  TDomainLocalizableAccountsEntry = record
    Rid: Cardinal;
    NameUse: TSidNameUse;
    Name: TNtUnicodeString;
    AdminComment: TNtUnicodeString;
  end;
  PDomainLocalizableAccountsEntry = ^TDomainLocalizableAccountsEntry;

  // info class 1
  [SDKName('DOMAIN_LOCALIZABLE_ACCOUNTS_BASIC')]
  TDomainLocalizableAccounts = record
    [Counter(ctElements)] Count: Cardinal;
    Entries: ^TAnysizeArray<TDomainLocalizableAccountsEntry>;
  end;
  PDomainLocalizableAccounts = ^TDomainLocalizableAccounts;

  // Group

  [FriendlyName('group'), ValidMask(GROUP_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(GROUP_READ_INFORMATION, 'Read Information')]
  [FlagName(GROUP_WRITE_ACCOUNT, 'Write Account')]
  [FlagName(GROUP_ADD_MEMBER, 'Add Member')]
  [FlagName(GROUP_REMOVE_MEMBER, 'Remove Member')]
  [FlagName(GROUP_LIST_MEMBERS, 'List Members')]
  TGroupAccessMask = type TAccessMask;

  [SDKName('GROUP_MEMBERSHIP')]
  TGroupMembership = record
    RelativeId: Cardinal;
    Attributes: TGroupAttributes;
  end;
  PGroupMembership = ^TGroupMembership;
  TGroupMembershipArray = TAnysizeArray<TGroupMembership>;
  PGroupMembershipArray = ^TGroupMembershipArray;

  [SDKName('GROUP_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Group'), Range(1)]
  TGroupInformationClass = (
    GroupReserved = 0,
    GroupGeneralInformation = 1,     // q: TGroupGeneralInformation
    GroupNameInformation = 2,        // q, s: TNtUnicodeString;
    GroupAttributeInformation = 3,   // q, s: TGroupAttributes
    GroupAdminCommentInformation = 4 // q, s: TNtUnicodeString;
  );

  // info class 1
  [SDKName('GROUP_GENERAL_INFORMATION')]
  TGroupGeneralInformation = record
    Name: TNtUnicodeString;
    Attributes: TGroupAttributes;
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

  [SDKName('ALIAS_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Alias'), Range(1)]
  TAliasInformationClass = (
    AliasReserved = 0,
    AliasGeneralInformation = 1,      // q: TAliasGeneralInformation
    AliasNameInformation = 2,         // q, s: TNtUnicodeString
    AliasAdminCommentInformation = 3, // q, s: TNtUnicodeString
    AliasReplicationInformation = 4,  // q: TNtUnicodeString
    AliasExtendedInformation = 5      // q, s:
  );

  // info class 1
  [SDKName('ALIAS_GENERAL_INFORMATION')]
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
  PUserAccessMask = ^TUserAccessMask;

  [SDKName('LOGON_HOURS')]
  TLogonHours = record
    UnitsPerWeek: Word;
    LogonHours: ^TAnysizeArray<Byte>;
  end;

  [SDKName('USER_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'User'), Range(1)]
  TUserInformationClass = (
    UserReserved = 0,
    UserGeneralInformation = 1,       // q: TUserGeneralInformation
    UserPreferencesInformation = 2,   // q, s: TUserPreferencesInformation
    UserLogonInformation = 3,         // q: TUserLogonInformation
    UserLogonHoursInformation = 4,    // q, s: TLogonHours
    UserAccountInformation = 5,       // q: TUserAccountInformation
    UserNameInformation = 6,          // q, s: TUserNameInformation
    UserAccountNameInformation = 7,   // q, s: TNtUnicodeString
    UserFullNameInformation = 8,      // q, s: TNtUnicodeString
    UserPrimaryGroupInformation = 9,  // q, s: Cardinal
    UserHomeInformation = 10,         // q, s: TUserHomeInformation
    UserScriptInformation = 11,       // q, s: TNtUnicodeString
    UserProfileInformation = 12,      // q, s: TNtUnicodeString
    UserAdminCommentInformation = 13, // q, s: TNtUnicodeString
    UserWorkStationsInformation = 14, // q, s: TNtUnicodeString
    UserSetPasswordInformation = 15,  // s: TUserSetPasswordInformation
    UserControlInformation = 16,      // q, s: TUserAccountFlags
    UserExpiresInformation = 17,      // q, s: TLargeInteger
    UserInternal1Information = 18,    // q, s:
    UserInternal2Information = 19,    // q, s:
    UserParametersInformation = 20,   // q, s: TNtUnicodeString
    UserAllInformation = 21,          // q, s: TUserAllInformation
    UserInternal3Information = 22,    // q, s:
    UserInternal4Information = 23,    // s:
    UserInternal5Information = 24,    // s:
    UserInternal4InformationNew = 25, // s:
    UserInternal5InformationNew = 26, // s:
    UserInternal6Information = 27,    // q, s:
    UserExtendedInformation = 28,     // q, s:
    UserLogonUIInformation = 29       // q: TUserLogonUiInformation
  );

  // info class 1
  [SDKName('USER_GENERAL_INFORMATION')]
  TUserGeneralInformation = record
    UserName: TNtUnicodeString;
    FullName: TNtUnicodeString;
    PrimaryGroupId: Cardinal;
    AdminComment: TNtUnicodeString;
    UserComment: TNtUnicodeString;
  end;
  PUserGeneralInformation = ^TUserGeneralInformation;

  // info class 2
  [SDKName('USER_PREFERENCES_INFORMATION')]
  TUserPreferencesInformation = record
    UserComment: TNtUnicodeString;
    Reserved1: TNtUnicodeString;
    CountryCode: Word;
    CodePage: Word;
  end;
  PUserPreferencesInformation = ^TUserPreferencesInformation;

  // info class 3
  [SDKName('USER_LOGON_INFORMATION')]
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
    UserAccountControl: TUserAccountFlags;
  end;
  PUserLogonInformation = ^TUserLogonInformation;

  // info class 5
  [SDKName('USER_ACCOUNT_INFORMATION')]
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
    UserAccountControl: TUserAccountFlags;
  end;
  PUserAccountInformation = ^TUserAccountInformation;

  // info class 6
  [SDKName('USER_NAME_INFORMATION')]
  TUserNameInformation = record
    UserName: TNtUnicodeString;
    FullName: TNtUnicodeString;
  end;
  PUserNameInformation = ^TUserNameInformation;

  // info class 10
  [SDKName('USER_HOME_INFORMATION')]
  TUserHomeInformation = record
    HomeDirectory: TNtUnicodeString;
    HomeDirectoryDrive: TNtUnicodeString;
  end;
  PUserHomeInformation = ^TUserHomeInformation;

  // info class 15
  [SDKName('USER_SET_PASSWORD_INFORMATION')]
  TUserSetPasswordInformation = record
    Password: TNtUnicodeString;
    PasswordExpired: Boolean;
  end;
  PUserSetPasswordInformation = ^TUserSetPasswordInformation;

  [FlagName(USER_ALL_USERNAME, 'Username')]
  [FlagName(USER_ALL_FULLNAME, 'Full Name')]
  [FlagName(USER_ALL_USERID, 'User ID')]
  [FlagName(USER_ALL_PRIMARYGROUPID, 'Primary Group ID')]
  [FlagName(USER_ALL_ADMINCOMMENT, 'Admin Comment')]
  [FlagName(USER_ALL_USERCOMMENT, 'User Comment')]
  [FlagName(USER_ALL_HOMEDIRECTORY, 'Home Directory')]
  [FlagName(USER_ALL_HOMEDIRECTORYDRIVE, 'Home Directory Drive')]
  [FlagName(USER_ALL_SCRIPTPATH, 'Script Path')]
  [FlagName(USER_ALL_PROFILEPATH, 'Profile Path')]
  [FlagName(USER_ALL_WORKSTATIONS, 'Workstations')]
  [FlagName(USER_ALL_LASTLOGON, 'Last Logon')]
  [FlagName(USER_ALL_LASTLOGOFF, 'Last Logoff')]
  [FlagName(USER_ALL_LOGONHOURS, 'Logon Hours')]
  [FlagName(USER_ALL_BADPASSWORDCOUNT, 'Bas Password Count')]
  [FlagName(USER_ALL_LOGONCOUNT, 'Logon Count')]
  [FlagName(USER_ALL_PASSWORDCANCHANGE, 'Password Can Change')]
  [FlagName(USER_ALL_PASSWORDMUSTCHANGE, 'Password Must Change')]
  [FlagName(USER_ALL_PASSWORDLASTSET, 'Password Last Set')]
  [FlagName(USER_ALL_ACCOUNTEXPIRES, 'Account Expires')]
  [FlagName(USER_ALL_USERACCOUNTCONTROL, 'User Account Control')]
  [FlagName(USER_ALL_PARAMETERS, 'Parameters')]
  [FlagName(USER_ALL_COUNTRYCODE, 'Country Ñode')]
  [FlagName(USER_ALL_CODEPAGE, 'Codepage')]
  [FlagName(USER_ALL_NTPASSWORDPRESENT, 'NT Password Present')]
  [FlagName(USER_ALL_LMPASSWORDPRESENT, 'LM Password Present')]
  [FlagName(USER_ALL_PRIVATEDATA, 'Private Data')]
  [FlagName(USER_ALL_PASSWORDEXPIRED, 'Password Expired')]
  [FlagName(USER_ALL_SECURITYDESCRIPTOR, 'Security Descriptor')]
  [FlagName(USER_ALL_OWFPASSWORD, 'OWF Password')]
  TUserAllInformationFields = type Cardinal;

  [SDKName('SR_SECURITY_DESCRIPTOR')]
  TSrSecurityDescriptor = record
    [Counter(ctBytes)] Length: Cardinal;
    SecurityDescriptor: Pointer;
  end;

  // info class 21
  [SDKName('USER_ALL_INFORMATION')]
  TUserAllInformation = record
    LastLogon: TLargeInteger;
    LastLogoff: TLargeInteger;
    PasswordLastSet: TLargeInteger;
    AccountExpires: TLargeInteger;
    PasswordCanChange: TLargeInteger;
    PasswordMustChange: TLargeInteger;
    UserName: TNtUnicodeString;
    FullName: TNtUnicodeString;
    HomeDirectory: TNtUnicodeString;
    HomeDirectoryDrive: TNtUnicodeString;
    ScriptPath: TNtUnicodeString;
    ProfilePath: TNtUnicodeString;
    AdminComment: TNtUnicodeString;
    WorkStations: TNtUnicodeString;
    UserComment: TNtUnicodeString;
    Parameters: TNtUnicodeString;
    LmPassword: TNtUnicodeString;
    NtPassword: TNtUnicodeString;
    PrivateData: TNtUnicodeString;
    SecurityDescriptor: TSrSecurityDescriptor;
    UserId: Cardinal;
    PrimaryGroupId: Cardinal;
    UserAccountControl: TUserAccountFlags;
    WhichFields: TUserAllInformationFields;
    LogonHours: TLogonHours;
    BadPasswordCount: Word;
    LogonCount: Word;
    CountryCode: Word;
    CodePage: Word;
    LmPasswordPresent: Boolean;
    NtPasswordPresent: Boolean;
    PasswordExpired: Boolean;
    PrivateDataSensitive: Boolean;
  end;
  PUserAllInformation = ^TUserAllInformation;

  // info class 29
  [SDKName('USER_LOGON_UI_INFORMATION')]
  TUserLogonUiInformation = record
    PasswordIsBlank: Boolean;
    AccountIsDisabled: Boolean;
  end;
  PUserLogonUiInformation = ^TUserLogonUiInformation;

{ Common }

function SamFreeMemory(
  [in] Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamCloseHandle(
  [in] SamHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

function SamRidToSid(
  [in] ObjectHandle: TSamHandle;
  [in] Rid: Cardinal;
  [out, ReleaseWith('SamFreeMemory')] out Sid: PSid
): NTSTATUS; stdcall; external samlib;

function SamQuerySecurityObject(
  [in, Access(OBJECT_READ_SECURITY)] ObjectHandle: TSamHandle;
  [in] SecurityInformation: TSamHandle;
  [out, ReleaseWith('SamFreeMemory')] out SecurityDescriptor:
    PSecurityDescriptor
): NTSTATUS; stdcall; external samlib;

function SamSetSecurityObject(
  [in, Access(OBJECT_WRITE_SECURITY)] ObjectHandle: TSamHandle;
  [in] SecurityInformation: TSecurityInformation;
  [in] SecurityDescriptor: PSecurityDescriptor
): NTSTATUS; stdcall; external samlib;

[Result: ReleaseWith('SamUnregisterObjectChangeNotification')]
function SamRegisterObjectChangeNotification(
  [in] ObjectType: TSecurityDbObjectType;
  [in] NotificationEventHandle: THandle
): NTSTATUS; stdcall; external samlib;

function SamUnregisterObjectChangeNotification(
  [in] ObjectType: TSecurityDbObjectType;
  [in] NotificationEventHandle: THandle
): NTSTATUS; stdcall; external samlib;

{ Server }

function SamConnect(
  [in, opt] ServerName: PNtUnicodeString;
  [out, ReleaseWith('SamCloseHandle')] out ServerHandle: TSamHandle;
  [in] DesiredAccess: TSamAccessMask;
  [in] const ObjectAttributes: TObjectAttributes
): NTSTATUS; stdcall; external samlib;

function SamShutdownSamServer(
  [in, Access(SAM_SERVER_SHUTDOWN)] ServerHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

{ Domain }

function SamEnumerateDomainsInSamServer(
  [in, Access(SAM_SERVER_ENUMERATE_DOMAINS)] ServerHandle: TSamHandle;
  [in, out] var EnumerationContext: TSamEnumerationHandle;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: PSamRidEnumerationArray;
  [in, NumberOfBytes] PreferedMaximumLength: Cardinal;
  [out, NumberOfElements] out CountReturned: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamLookupDomainInSamServer(
  [Access(SAM_SERVER_LOOKUP_DOMAIN)] ServerHandle: TSamHandle;
  [in] const Name: TNtUnicodeString;
  [out, ReleaseWith('SamFreeMemory')] out DomainId: PSid
): NTSTATUS; stdcall; external samlib;

function SamOpenDomain(
  [in, Access(SAM_SERVER_LOOKUP_DOMAIN)] ServerHandle: TSamHandle;
  [in] DesiredAccess: TDomainAccessMask;
  [in] DomainId: PSid;
  [out, ReleaseWith('SamCloseHandle')] out DomainHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

function SamQueryInformationDomain(
  [in, Access(DOMAIN_READ_OTHER_PARAMETERS or
    DOMAIN_READ_PASSWORD_PARAMETERS)] DomainHandle: TSamHandle;
  [in] DomainInformationClass: TDomainInformationClass;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamSetInformationDomain(
  [in, Access(DOMAIN_WRITE_PASSWORD_PARAMS or
    DOMAIN_WRITE_OTHER_PARAMETERS)] DomainHandle: TSamHandle;
  [in] DomainInformationClass: TDomainInformationClass;
  [in, ReadsFrom] DomainInformation: Pointer
): NTSTATUS; stdcall; external samlib;

function SamQueryDisplayInformation(
  [in, Access(DOMAIN_LIST_ACCOUNTS)] DomainHandle: TSamHandle;
  [in] DisplayInformation: TDomainDisplayInformation;
  [in] Index: Cardinal;
  [in, NumberOfElements] EntryCount: Cardinal;
  [in, NumberOfBytes] PreferredMaximumLength: Cardinal;
  [out, NumberOfBytes] out TotalAvailable: Cardinal;
  [out, NumberOfBytes] out TotalReturned: Cardinal;
  [out, NumberOfElements] out ReturnedEntryCount: Cardinal;
  [out, ReleaseWith('SamFreeMemory')] out SortedBuffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamGetDisplayEnumerationIndex(
  [in, Access(DOMAIN_LIST_ACCOUNTS)] DomainHandle: TSamHandle;
  [in] DisplayInformation: TDomainDisplayInformation;
  [in] const Prefix: TNtUnicodeString;
  [out] out Index: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamQueryLocalizableAccountsInDomain(
  [in, Access(DOMAIN_READ_OTHER_PARAMETERS)] DomainHandle: TSamHandle;
  [Reserved] Flags: Cardinal;
  [in] LanguageId: Cardinal;
  [in] InfoClass: TDomainLocalizableAccountsInformation;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamLookupNamesInDomain(
  [in, Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  [in, NumberOfElements] Count: Cardinal;
  [in, ReadsFrom] const Names: TArray<TNtUnicodeString>;
  [out, ReleaseWith('SamFreeMemory')] out RelativeIds: PCardinalArray;
  [out, ReleaseWith('SamFreeMemory')] out NameUse: PNameUseArray
): NTSTATUS; stdcall; external samlib;

function SamLookupNamesInDomain2(
  [in, Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  [in, NumberOfElements] Count: Cardinal;
  [in, ReadsFrom] const Names: TArray<TNtUnicodeString>;
  [out, ReleaseWith('SamFreeMemory')] out Sids: PSidArray;
  [out, ReleaseWith('SamFreeMemory')] out NameUse: PNameUseArray
): NTSTATUS; stdcall; external samlib;

function SamLookupIdsInDomain(
  [in, Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  [in, NumberOfElements] Count: Cardinal;
  [in, ReadsFrom] const RelativeIds: TArray<Cardinal>;
  [out, ReleaseWith('SamFreeMemory')] out Names: PNtUnicodeStringArray;
  [out, ReleaseWith('SamFreeMemory')] out NameUse: PNameUseArray
): NTSTATUS; stdcall; external samlib;

function SamGetAliasMembership(
  [in, Access(DOMAIN_GET_ALIAS_MEMBERSHIP)] DomainHandle: TSamHandle;
  [in, NumberOfElements] PassedCount: Cardinal;
  [in, ReadsFrom] const Sids: TArray<PSid>;
  [out] out MembershipCount: Cardinal;
  [out, ReleaseWith('SamFreeMemory')] out Aliases: PCardinalArray
): NTSTATUS; stdcall; external samlib;

function SamRemoveMemberFromForeignDomain(
  [in, Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  [in] MemberId: PSid
): NTSTATUS; stdcall; external samlib;

{ Group }

function SamEnumerateGroupsInDomain(
  [in, Access(DOMAIN_LIST_ACCOUNTS)] DomainHandle: TSamHandle;
  [in, out] var EnumerationContext: TSamEnumerationHandle;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: PSamRidEnumerationArray;
  [in, NumberOfBytes] PreferedMaximumLength: Cardinal;
  [out, NumberOfElements] out CountReturned: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamCreateGroupInDomain(
  [in, Access(DOMAIN_CREATE_GROUP)] DomainHandle: TSamHandle;
  [in] const AccountName: TNtUnicodeString;
  [in] DesiredAccess: TGroupAccessMask;
  [out, ReleaseWith('SamCloseHandle')] out GroupHandle: TSamHandle;
  [out] out RelativeId: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamOpenGroup(
  [in, Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  [in] DesiredAccess: TGroupAccessMask;
  [in] GroupId: Cardinal;
  [out, ReleaseWith('SamCloseHandle')] out GroupHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

function SamQueryInformationGroup(
  [in, Access(GROUP_READ_INFORMATION)] GroupHandle: TSamHandle;
  [in] GroupInformationClass: TGroupInformationClass;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamSetInformationGroup(
  [in, Access(GROUP_WRITE_ACCOUNT)] GroupHandle: TSamHandle;
  [in] GroupInformationClass: TGroupInformationClass;
  [in, ReadsFrom] Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamGetMembersInGroup(
  [in, Access(GROUP_LIST_MEMBERS)] GroupHandle: TSamHandle;
  [out, ReleaseWith('SamFreeMemory')] out MemberIds: PCardinalArray;
  [out, ReleaseWith('SamFreeMemory')] out Attributes: PCardinalArray;
  [out] out MemberCount: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamAddMemberToGroup(
  [in, Access(GROUP_ADD_MEMBER)] GroupHandle: TSamHandle;
  [in] MemberId: Cardinal;
  [in] Attributes: TGroupAttributes
): NTSTATUS; stdcall; external samlib;

function SamRemoveMemberFromGroup(
  [in, Access(GROUP_REMOVE_MEMBER)] GroupHandle: TSamHandle;
  [in] MemberId: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamSetMemberAttributesOfGroup(
  [in, Access(GROUP_ADD_MEMBER)] GroupHandle: TSamHandle;
  [in] MemberId: Cardinal;
  [in] Attributes: TGroupAttributes
): NTSTATUS; stdcall; external samlib;

function SamDeleteGroup(
  [in, Access(_DELETE)] GroupHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

{ Alias }

function SamEnumerateAliasesInDomain(
  [in, Access(DOMAIN_LIST_ACCOUNTS)] DomainHandle: TSamHandle;
  [in, out] var EnumerationContext: TSamEnumerationHandle;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: PSamRidEnumerationArray;
  [in, NumberOfBytes] PreferedMaximumLength: Cardinal;
  [out, NumberOfElements] out CountReturned: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamCreateAliasInDomain(
  [in, Access(DOMAIN_CREATE_ALIAS)] DomainHandle: TSamHandle;
  [in] const AccountName: TNtUnicodeString;
  [in] DesiredAccess: TAliasAccessMask;
  [out, ReleaseWith('SamCloseHandle')] out AliasHandle: TSamHandle;
  [out] out RelativeId: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamOpenAlias(
  [in, Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  [in] DesiredAccess: TAliasAccessMask;
  [in] AliasId: Cardinal;
  [out, ReleaseWith('SamCloseHandle')] out AliasHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

function SamQueryInformationAlias(
  [in, Access(ALIAS_READ_INFORMATION)] AliasHandle: TSamHandle;
  [in] AliasInformationClass: TAliasInformationClass;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamSetInformationAlias(
  [in, Access(ALIAS_WRITE_ACCOUNT)] AliasHandle: TSamHandle;
  [in] AliasInformationClass: TAliasInformationClass;
  [in, ReadsFrom] Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamGetMembersInAlias(
  [in, Access(ALIAS_LIST_MEMBERS)] AliasHandle: TSamHandle;
  [out, ReleaseWith('SamFreeMemory')] out MemberIds: PSidArray;
  [out] out MemberCount: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamAddMemberToAlias(
  [in, Access(ALIAS_ADD_MEMBER)] AliasHandle: TSamHandle;
  [in] MemberId: PSid
): NTSTATUS; stdcall; external samlib;

function SamAddMultipleMembersToAlias(
  [in, Access(ALIAS_ADD_MEMBER)] AliasHandle: TSamHandle;
  [in, ReadsFrom] const MemberIds: TArray<PSid>;
  [in, NumberOfElements] MemberCount: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamRemoveMemberFromAlias(
  [in, Access(ALIAS_REMOVE_MEMBER)] AliasHandle: TSamHandle;
  [in] MemberId: PSid
): NTSTATUS; stdcall; external samlib;

function SamRemoveMultipleMembersFromAlias(
  [in, Access(ALIAS_REMOVE_MEMBER)] AliasHandle: TSamHandle;
  [in, ReadsFrom] const MemberIds: TArray<PSid>;
  [in, NumberOfElements] MemberCount: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamDeleteAlias(
  [in, Access(_DELETE)] AliasHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

{ User }

function SamEnumerateUsersInDomain(
  [in, Access(DOMAIN_LIST_ACCOUNTS)] DomainHandle: TSamHandle;
  [in, out] var EnumerationContext: TSamEnumerationHandle;
  [in] UserAccountControl: TUserAccountFlags;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: PSamRidEnumerationArray;
  [in, NumberOfBytes] PreferedMaximumLength: Cardinal;
  [out, NumberOfElements] out CountReturned: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamCreateUser2InDomain(
  [in, Access(DOMAIN_CREATE_USER)] DomainHandle: TSamHandle;
  [in] const AccountName: TNtUnicodeString;
  [in] AccountType: TUserAccountFlags;
  [in] DesiredAccess: TUserAccessMask;
  [out, ReleaseWith('SamCloseHandle')] out UserHandle: TSamHandle;
  [out] out GrantedAccess: TUserAccessMask;
  [out] out RelativeId: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamOpenUser(
  [in, Access(DOMAIN_LOOKUP)] DomainHandle: TSamHandle;
  [in] DesiredAccess: TUserAccessMask;
  [in] UserId: Cardinal;
  [out, ReleaseWith('SamCloseHandle')] out UserHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

function SamQueryInformationUser(
  [in, Access(USER_READ_GENERAL or USER_READ_PREFERENCES or
    USER_READ_LOGON or USER_READ_ACCOUNT)] UserHandle: TSamHandle;
  [in] UserInformationClass: TUserInformationClass;
  [out, ReleaseWith('SamFreeMemory')] out Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamSetInformationUser(
  [in, Access(USER_WRITE_ACCOUNT)] UserHandle: TSamHandle;
  [in] UserInformationClass: TUserInformationClass;
  [in, ReadsFrom] Buffer: Pointer
): NTSTATUS; stdcall; external samlib;

function SamChangePasswordUser(
  [in, Access(0)] UserHandle: TSamHandle;
  [in] const OldPassword: TNtUnicodeString;
  [in] const NewPassword: TNtUnicodeString
): NTSTATUS; stdcall; external samlib;

function SamChangePasswordUser2(
  [in] const ServerName: TNtUnicodeString;
  [in] const UserName: TNtUnicodeString;
  [in] const OldPassword: TNtUnicodeString;
  [in] const NewPassword: TNtUnicodeString
): NTSTATUS; stdcall; external samlib;

function SamGetGroupsForUser(
  [in, Access(USER_LIST_GROUPS)] UserHandle: TSamHandle;
  [out, ReleaseWith('SamFreeMemory')] out Groups: PGroupMembershipArray;
  [out] out MembershipCount: Cardinal
): NTSTATUS; stdcall; external samlib;

function SamDeleteUser(
  [in, Access(_DELETE)] UserHandle: TSamHandle
): NTSTATUS; stdcall; external samlib;

{ Expected Access Masks }

function ExpectedDomainQueryAccess(
  [in] InfoClass: TDomainInformationClass
): TDomainAccessMask;

function ExpectedDomainSetAccess(
  [in] InfoClass: TDomainInformationClass
): TDomainAccessMask;

function ExpectedUserQueryAccess(
  [in] InfoClass: TUserInformationClass
): TUserAccessMask;

function ExpectedUserSetAccess(
  [in] InfoClass: TUserInformationClass
): TUserAccessMask;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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
