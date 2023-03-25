unit Ntapi.WinNt;

{
  This file includes widely used type definitions for Win32 and Native API.
  For sources see SDK::winnt.h
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.Versions, DelphiApi.Reflection;

const
  kernelbase = 'kernelbase.dll';
  kernel32 = 'kernel32.dll';
  advapi32 = 'advapi32.dll';

  INVALID_HANDLE_VALUE = THandle(-1);
  MAX_HANDLE = $FFFFFF; // handle table maximum
  MAX_UINT = $FFFFFFFF;

  // SDK::minwindef.h
  MAX_PATH = 260;
  MAX_LONG_PATH = High(Word) div SizeOf(WideChar);

  MAXIMUM_WAIT_OBJECTS = 64;

  NT_INFINITE = $8000000000000000; // maximum possible relative timeout
  MILLISEC = -10000; // 100ns in 1 ms in relative time

  LANG_NEUTRAL = $00;
  LANG_INVARIANT = $7F;

  SUBLANG_NEUTRAL = $00;
  SUBLANG_DEFAULT = $01;
  SUBLANG_SYS_DEFAULT = $02;
  SUBLANG_CUSTOM_DEFAULT = $03;
  SUBLANG_CUSTOM_UNSPECIFIED = $04;
  SUBLANG_UI_CUSTOM_DEFAULT = $05;

  // Use MAKELANGID => (LANG_* or (SUBLANG_* shl SUBLANGID_SHIFT))
  PRIMARYLANGID_MASK = $3ff;
  SUBLANGID_SHIFT = 10;

  // Thread context geting/setting flags
  CONTEXT_i386 = $00010000;
  CONTEXT_AMD64 = $00100000;
  CONTEXT_NATIVE = {$IFDEF Win64}CONTEXT_AMD64{$ELSE}CONTEXT_i386{$ENDIF};

  CONTEXT_CONTROL = $00000001;  // SS:SP, CS:IP, FLAGS, BP
  CONTEXT_INTEGER = $00000002;  // AX, BX, CX, DX, SI, DI
  CONTEXT_SEGMENTS = $00000004; // DS, ES, FS, GS
  CONTEXT_FLOATING_POINT = $00000008;     // 387 state
  CONTEXT_DEBUG_REGISTERS = $00000010;    // DB 0-3,6,7
  CONTEXT_EXTENDED_REGISTERS = $00000020; // cpu specific extensions

  CONTEXT_FULL = CONTEXT_CONTROL or CONTEXT_INTEGER or CONTEXT_SEGMENTS;
  CONTEXT_ALL = CONTEXT_FULL or CONTEXT_FLOATING_POINT or
    CONTEXT_DEBUG_REGISTERS or CONTEXT_EXTENDED_REGISTERS;

  CONTEXT_XSTATE = $00000040;

  CONTEXT_EXCEPTION_ACTIVE = $08000000;
  CONTEXT_SERVICE_ACTIVE = $10000000;
  CONTEXT_EXCEPTION_REQUEST = $40000000;
  CONTEXT_EXCEPTION_REPORTING = $80000000;

  // EFLAGS register bits
  EFLAGS_CF = $0001; // Carry
  EFLAGS_PF = $0004; // Parity
  EFLAGS_AF = $0010; // Auxiliary Carry
  EFLAGS_ZF = $0040; // Zero
  EFLAGS_SF = $0080; // Sign
  EFLAGS_TF = $0100; // Trap
  EFLAGS_IF = $0200; // Interrupt
  EFLAGS_DF = $0400; // Direction
  EFLAGS_OF = $0800; // Overflow

  // Exception flags
  EXCEPTION_NONCONTINUABLE = $01;
  EXCEPTION_UNWINDING = $02;
  EXCEPTION_EXIT_UNWIND = $04;
  EXCEPTION_STACK_INVALID = $08;
  EXCEPTION_NESTED_CALL = $10;
  EXCEPTION_TARGET_UNWIND = $20;
  EXCEPTION_COLLIDED_UNWIND = $40;

  EXCEPTION_UNWIND = EXCEPTION_UNWINDING or EXCEPTION_EXIT_UNWIND or
    EXCEPTION_TARGET_UNWIND or EXCEPTION_COLLIDED_UNWIND;

  EXCEPTION_MAXIMUM_PARAMETERS = 15;

  // Access masks
  _DELETE = $00010000;      // SDDL: DE
  READ_CONTROL = $00020000; // SDDL: RC
  WRITE_DAC = $00040000;    // SDDL: WD
  WRITE_OWNER = $00080000;  // SDDL: WO
  SYNCHRONIZE = $00100000;  // SDDL: SY

  STANDARD_RIGHTS_REQUIRED = _DELETE or READ_CONTROL or WRITE_DAC or WRITE_OWNER;
  STANDARD_RIGHTS_READ = READ_CONTROL;
  STANDARD_RIGHTS_WRITE = READ_CONTROL;
  STANDARD_RIGHTS_EXECUTE = READ_CONTROL;
  STANDARD_RIGHTS_ALL = STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE;
  SPECIFIC_RIGHTS_ALL = $0000FFFF;

  ACCESS_SYSTEM_SECURITY = $01000000; // SDDL: AS
  MAXIMUM_ALLOWED = $02000000;        // SDDL: MA

  GENERIC_READ = Cardinal($80000000); // SDDL: GR
  GENERIC_WRITE = $40000000;          // SDDL: GW
  GENERIC_EXECUTE = $20000000;        // SDDL: GX
  GENERIC_ALL = $10000000;            // SDDL: GA
  GENERIC_RIGHTS_ALL = GENERIC_READ or GENERIC_WRITE or GENERIC_EXECUTE or
    GENERIC_ALL;

  // Masks for annotations
  OBJECT_READ_SECURITY = READ_CONTROL or ACCESS_SYSTEM_SECURITY;
  OBJECT_WRITE_SECURITY = WRITE_DAC or WRITE_OWNER or ACCESS_SYSTEM_SECURITY;

  // SID structure consts
  SID_REVISION = 1;
  SID_MAX_SUB_AUTHORITIES = 15;
  SECURITY_MAX_SID_SIZE = 8 + SID_MAX_SUB_AUTHORITIES * SizeOf(Cardinal);
  SECURITY_MAX_SID_STRING_CHARACTERS = 187;

  // Well-known SIDs

  SECURITY_NULL_SID_AUTHORITY = 0;       // S-1-0
  SECURITY_NULL_RID = $00000000;         // S-1-0-0 (NULL SID)

  SECURITY_WORLD_SID_AUTHORITY = 1;      // S-1-1
  SECURITY_WORLD_RID = $00000000;        // S-1-1-0 (Everyone)

  SECURITY_LOCAL_SID_AUTHORITY = 2;      // S-1-2
  SECURITY_LOCAL_RID = $00000000;        // S-1-2-0 (LOCAL)
  SECURITY_LOCAL_LOGON_RID  = $00000001; // S-1-2-1 (CONSOLE LOGON)

  SECURITY_CREATOR_SID_AUTHORITY = 3;            // S-1-3
  SECURITY_CREATOR_OWNER_RID = $00000000;        // S-1-3-0 (CREATOR OWNER)
  SECURITY_CREATOR_GROUP_RID = $00000001;        // S-1-3-1 (CREATOR GROUP)
  SECURITY_CREATOR_OWNER_SERVER_RID = $00000002; // S-1-3-2 (CREATOR OWNER SERVER)
  SECURITY_CREATOR_GROUP_SERVER_RID = $00000003; // S-1-3-3 (CREATOR GROUP SERVER)
  SECURITY_CREATOR_OWNER_RIGHTS_RID = $00000004; // S-1-3-4 (OWNER RIGHTS)

  SECURITY_NON_UNIQUE_AUTHORITY = 4; // S-1-4

  SECURITY_NT_AUTHORITY = 5;                   // S-1-5 (NT Pseudo Domain)
  SECURITY_DIALUP_RID = $00000001;             // S-1-5-1 (DIALUP)
  SECURITY_NETWORK_RID = $00000002;            // S-1-5-2 (NETWORK)
  SECURITY_BATCH_RID = $00000003;              // S-1-5-3 (BATCH)
  SECURITY_INTERACTIVE_RID = $00000004;        // S-1-5-4 (INTERACTIVE)
  SECURITY_LOGON_IDS_RID = $00000005;          // S-1-5-5
  SECURITY_LOGON_IDS_RID_COUNT = 3;            // S-1-5-5-X-Y (LogonSessionId_X_Y)
  SECURITY_SERVICE_RID = $00000006;            // S-1-5-6 (SERVICE)
  SECURITY_ANONYMOUS_LOGON_RID = $00000007;    // S-1-5-7 (ANONYMOUS LOGON)
  SECURITY_PROXY_RID = $00000008;              // S-1-5-8 (PROXY)
  SECURITY_ENTERPRISE_CONTROLLERS_RID = $00000009; // S-1-5-9 (ENTERPRISE DOMAIN CONTROLLERS)
  SECURITY_PRINCIPAL_SELF_RID = $0000000A;     // S-1-5-10 (SELF)
  SECURITY_AUTHENTICATED_USER_RID = $0000000B; // S-1-5-11 (Authenticated Users)
  SECURITY_RESTRICTED_CODE_RID = $0000000C;    // S-1-5-12 (RESTRICTED)
  SECURITY_TERMINAL_SERVER_RID = $0000000D;    // S-1-5-13 (TERMINAL SERVER USER)
  SECURITY_REMOTE_LOGON_RID = $0000000E;       // S-1-5-14 (REMOTE INTERACTIVE LOGON)
  SECURITY_THIS_ORGANIZATION_RID = $0000000F;  // S-1-5-15 (This Organization)
  SECURITY_IUSER_RID           = $00000011;    // S-1-5-17 (IUSR)
  SECURITY_LOCAL_SYSTEM_RID    = $00000012;    // S-1-5-18 (SYSTEM)
  SECURITY_LOCAL_SERVICE_RID   = $00000013;    // S-1-5-19 (LOCAL SERVICE)
  SECURITY_NETWORK_SERVICE_RID = $00000014;    // S-1-5-20 (NETWORK SERVICE)

  SECURITY_NT_NON_UNIQUE = $00000015;          // S-1-5-21
  SECURITY_NT_NON_UNIQUE_SUB_AUTH_COUNT = 3;   // S-1-5-21-X-X-X (NT Domain SIDs)

  DOMAIN_GROUP_RID_AUTHORIZATION_DATA_IS_COMPOUNDED = $000001F0;   // S-1-5-21-0-0-0-496 (Compound Identity Present)
  DOMAIN_GROUP_RID_AUTHORIZATION_DATA_CONTAINS_CLAIMS = $000001F1; // S-1-5-21-0-0-0-497 (Claims Valid)

  DOMAIN_USER_RID_ADMIN = $000001F4;  // S-1-5-21-X-X-X-500 (Administrator)
  DOMAIN_USER_RID_GUEST = $000001F5;  // S-1-5-21-X-X-X-501 (Guest)
  DOMAIN_USER_RID_DEFAULT_ACCOUNT = $000001F7; // S-1-5-21-X-X-X-503 (DefaultAccount)
  DOMAIN_USER_RID_WDAG_ACCOUNT = $000001F8;    // S-1-5-21-X-X-X-504 (WDAGUtilityAccount)

  SECURITY_ENTERPRISE_READONLY_CONTROLLERS_RID = $00000016; // S-1-5-22 (ENTERPRISE READ-ONLY DOMAIN CONTROLLERS BETA)

  SECURITY_BUILTIN_DOMAIN_RID = $00000020;                     // S-1-5-32 (BUILTIN)
  DOMAIN_ALIAS_RID_ADMINS = $00000220;                         // S-1-5-32-544 (Administrators)
  DOMAIN_ALIAS_RID_USERS = $00000221;                          // S-1-5-32-545 (Users)
  DOMAIN_ALIAS_RID_GUESTS = $00000222;                         // S-1-5-32-546 (Guests)
  DOMAIN_ALIAS_RID_POWER_USERS = $00000223;                    // S-1-5-32-547 (Power Users)
  DOMAIN_ALIAS_RID_ACCOUNT_OPS = $00000224;                    // S-1-5-32-548
  DOMAIN_ALIAS_RID_SYSTEM_OPS = $00000225;                     // S-1-5-32-549
  DOMAIN_ALIAS_RID_PRINT_OPS = $00000226;                      // S-1-5-32-550
  DOMAIN_ALIAS_RID_BACKUP_OPS = $00000227;                     // S-1-5-32-551 (Backup Operators)
  DOMAIN_ALIAS_RID_REPLICATOR = $00000228;                     // S-1-5-32-552 (Replicator)
  DOMAIN_ALIAS_RID_RAS_SERVERS = $00000229;                    // S-1-5-32-553
  DOMAIN_ALIAS_RID_PREW2KCOMPACCESS = $0000022A;               // S-1-5-32-554
  DOMAIN_ALIAS_RID_REMOTE_DESKTOP_USERS = $0000022B;           // S-1-5-32-555 (Remote Desktop Users)
  DOMAIN_ALIAS_RID_NETWORK_CONFIGURATION_OPS = $0000022C;      // S-1-5-32-556 (Network Configuration Operators)
  DOMAIN_ALIAS_RID_INCOMING_FOREST_TRUST_BUILDERS = $0000022D; // S-1-5-32-557
  DOMAIN_ALIAS_RID_MONITORING_USERS = $0000022E;               // S-1-5-32-558 (Performance Monitor Users)
  DOMAIN_ALIAS_RID_LOGGING_USERS = $0000022F;                  // S-1-5-32-559 (Performance Log Users)
  DOMAIN_ALIAS_RID_AUTHORIZATIONACCESS = $00000230;            // S-1-5-32-560
  DOMAIN_ALIAS_RID_TS_LICENSE_SERVERS = $00000231;             // S-1-5-32-561
  DOMAIN_ALIAS_RID_DCOM_USERS = $00000232;                     // S-1-5-32-562 (Distributed COM Users)
  DOMAIN_ALIAS_RID_IUSERS = $00000238;                         // S-1-5-32-568 (IIS_IUSRS)
  DOMAIN_ALIAS_RID_CRYPTO_OPERATORS = $00000239;               // S-1-5-32-569 (Cryptographic Operators)
  DOMAIN_ALIAS_RID_CACHEABLE_PRINCIPALS_GROUP = $0000023B;     // S-1-5-32-571
  DOMAIN_ALIAS_RID_NON_CACHEABLE_PRINCIPALS_GROUP = $0000023C; // S-1-5-32-572
  DOMAIN_ALIAS_RID_EVENT_LOG_READERS_GROUP = $0000023D;        // S-1-5-32-573 (Event Log Readers)
  DOMAIN_ALIAS_RID_CERTSVC_DCOM_ACCESS_GROUP = $0000023E;      // S-1-5-32-574
  DOMAIN_ALIAS_RID_RDS_REMOTE_ACCESS_SERVERS = $0000023F;      // S-1-5-32-575
  DOMAIN_ALIAS_RID_RDS_ENDPOINT_SERVERS = $00000240;           // S-1-5-32-576
  DOMAIN_ALIAS_RID_RDS_MANAGEMENT_SERVERS = $00000241;         // S-1-5-32-577
  DOMAIN_ALIAS_RID_HYPER_V_ADMINS = $00000242;                 // S-1-5-32-578 (Hyper-V Administrators)
  DOMAIN_ALIAS_RID_ACCESS_CONTROL_ASSISTANCE_OPS = $00000243;  // S-1-5-32-579 (Access Control Assistance Operators)
  DOMAIN_ALIAS_RID_REMOTE_MANAGEMENT_USERS = $00000244;        // S-1-5-32-580 (Remote Management Users)
  DOMAIN_ALIAS_RID_DEFAULT_ACCOUNT = $00000245;                // S-1-5-32-581 (System Managed Accounts Group)
  DOMAIN_ALIAS_RID_STORAGE_REPLICA_ADMINS = $00000246;         // S-1-5-32-582
  DOMAIN_ALIAS_RID_DEVICE_OWNERS = $00000247;                  // S-1-5-32-583 (Device Owners)

  SECURITY_INSTALLER_GROUP_CAPABILITY_BASE = $00000020; // S-1-5-32
  SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT = 9;    // S-1-5-32-[+8 from hash]

  SECURITY_WRITE_RESTRICTED_CODE_RID = $00000021; // S-1-5-33 (WRITE RESTRICTED)

  SECURITY_PACKAGE_BASE_RID = $00000040;     // S-1-5-64
  SECURITY_PACKAGE_RID_COUNT = 2;            // S-1-5-64-X
  SECURITY_PACKAGE_NTLM_RID = $0000000A;     // S-1-5-64-10 (NTLM Authentication)
  SECURITY_PACKAGE_SCHANNEL_RID = $0000000E; // S-1-5-64-14 (SChannel Authentication)
  SECURITY_PACKAGE_DIGEST_RID = $00000015;   // S-1-5-64-21 (Digest Authentication)

  SECURITY_CRED_TYPE_BASE_RID = $00000041;          // S-1-5-65
  SECURITY_CRED_TYPE_RID_COUNT = 2;                 // S-1-5-65-X
  SECURITY_CRED_TYPE_THIS_ORG_CERT_RID = $00000001; // S-1-5-65-1 (This Organization Certificate)

  SECURITY_SERVICE_ID_BASE_RID = $00000050; // S-1-5-80 (NT SERVICE)
  SECURITY_SERVICE_ID_GROUP_RID = 0;        // S-1-5-80-0 (ALL SERVICES)
  SECURITY_SERVICE_ID_RID_COUNT = 6;        // S-1-5-80-X-X-X-X-X

  SECURITY_VIRTUALSERVER_ID_BASE_RID = $00000053; // S-1-5-83 (NT VIRTUAL MACHINE)
  SECURITY_VIRTUALSERVER_ID_GROUP_RID = 0;        // S-1-5-83-0 (Virtual Machines)
  SECURITY_VIRTUALSERVER_ID_RID_COUNT = 6;        // S-1-5-83-X-X-X-X-X

  SECURITY_USERMODEDRIVERHOST_ID_BASE_RID = $00000054; // S-1-5-84
  SECURITY_USERMODEDRIVERHOST_ID_GROUP_RID = 0;        // S-1-5-84-0-0-0-0-0 (USER MODE DRIVERS)
  SECURITY_USERMODEDRIVERHOST_ID_RID_COUNT = 6;        // S-1-5-84-X-X-X-X-X

  SECURITY_TASK_ID_BASE_RID = $00000057; // S-1-5-87 (NT TASK)
  SECURITY_TASK_ID_RID_COUNT = 6;        // S-1-5-87-X-X-X-X-X

  SECURITY_WINDOW_MANAGER_BASE_RID = $0000005A; // S-1-5-90 (Window Manager)
  SECURITY_WINDOW_MANAGER_GROUP = 0;            // S-1-5-90-0 (Window Manager Group)
  SECURITY_WINDOW_MANAGER_RID_COUNT = 2;        // S-1-5-90-0-X (DWM-X)

  SECURITY_UMFD_BASE_RID = $00000060; // S-1-5-96 (Font Driver Host)
  SECURITY_UMFD_ID_RID_COUNT = 2;     // S-1-5-96-0-X (UMFD-X)

  SECURITY_VIRTUALACCOUNT_ID_RID_COUNT = 6; // S-1-5-X-X-X-X-X-X

  SECURITY_MIN_BASE_RID = $050; // S-1-5-80
  SECURITY_MAX_BASE_RID = $06F; // S-1-5-111

  SECURITY_LOCAL_ACCOUNT_RID = $00000071;           // S-1-5-113 (Local account)
  SECURITY_LOCAL_ACCOUNT_AND_ADMIN_RID = $00000072; // S-1-5-114 (Local account and member of Administrators group)

  SECURITY_OTHER_ORGANIZATION_RID = $000003E8; // S-1-5-1000 (Other Organization)

  SECURITY_APP_PACKAGE_AUTHORITY = 15;          // S-1-15 (APPLICATION PACKAGE AUTHORITY)

  SECURITY_APP_PACKAGE_BASE_RID = $00000002;    // S-1-15-2
  SECURITY_BUILTIN_APP_PACKAGE_RID_COUNT = 2;   // S-1-15-2-X
  SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE = $00000001;            // S-1-15-2-1 (ALL APPLICATION PACKAGES)
  SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE = $00000002; // S-1-15-2-2 (ALL RESTRICTED APPLICATION PACKAGES)

  SECURITY_APP_PACKAGE_RID_COUNT = 8;           // S-1-15-2-[+7 from hash]
  SECURITY_PARENT_PACKAGE_RID_COUNT = SECURITY_APP_PACKAGE_RID_COUNT;
  SECURITY_CHILD_PACKAGE_RID_COUNT = 12;        // S-1-15-2-[+7 from parent hash]-[+4 from child hash]

  SECURITY_CAPABILITY_BASE_RID = $00000003;     // S-1-15-3
  SECURITY_BUILTIN_CAPABILITY_RID_COUNT = 2;    // S-1-15-3-X

  SECURITY_CAPABILITY_INTERNET_CLIENT = $00000001;               // S-1-15-3-1 (Your Internet connection)
  SECURITY_CAPABILITY_INTERNET_CLIENT_SERVER = $00000002;        // S-1-15-3-2 (Your Internet connection, including incoming connections from the Internet)
  SECURITY_CAPABILITY_PRIVATE_NETWORK_CLIENT_SERVER = $00000003; // S-1-15-3-3 (Your home or work networks)
  SECURITY_CAPABILITY_PICTURES_LIBRARY = $00000004;              // S-1-15-3-4 (Your pictures library)
  SECURITY_CAPABILITY_VIDEOS_LIBRARY = $00000005;                // S-1-15-3-5 (Your videos library)
  SECURITY_CAPABILITY_MUSIC_LIBRARY = $00000006;                 // S-1-15-3-6 (Your music library)
  SECURITY_CAPABILITY_DOCUMENTS_LIBRARY = $00000007;             // S-1-15-3-7 (Your documents library)
  SECURITY_CAPABILITY_ENTERPRISE_AUTHENTICATION = $00000008;     // S-1-15-3-8 (Your Windows credentials)
  SECURITY_CAPABILITY_SHARED_USER_CERTIFICATES = $00000009;      // S-1-15-3-9 (Software and hardware certificates or a smart card)
  SECURITY_CAPABILITY_REMOVABLE_STORAGE = $0000000A;             // S-1-15-3-10 (Removable storage)
  SECURITY_CAPABILITY_APPOINTMENTS = $0000000B;                  // S-1-15-3-11 (Your Appointments)
  SECURITY_CAPABILITY_CONTACTS = $0000000C;                      // S-1-15-3-12 (Your Contacts)

  SECURITY_CAPABILITY_APP_RID = $00000400;      // S-1-15-3-1024
  SECURITY_INSTALLER_CAPABILITY_RID_COUNT = 10; // S-1-15-3-1024-[+8 from hash]

  SECURITY_MANDATORY_LABEL_AUTHORITY = 16;  // S-1-16 (Mandatory Label)

  SECURITY_MANDATORY_UNTRUSTED_RID = $0000; // S-1-16-0     (Untrusted Mandatory Level)
  SECURITY_MANDATORY_LOW_RID = $1000;       // S-1-16-4096  (Low Mandatory Level)
  SECURITY_MANDATORY_MEDIUM_RID = $2000;    // S-1-16-8192  (Medium Mandatory Level)
  SECURITY_MANDATORY_MEDIUM_PLUS_RID =
    SECURITY_MANDATORY_MEDIUM_RID + $0100;  // S-1-16-8448  (Medium Plus Mandatory Level)
  SECURITY_MANDATORY_HIGH_RID = $3000;      // S-1-16-12288 (High Mandatory Level)
  SECURITY_MANDATORY_SYSTEM_RID = $4000;    // S-1-16-16384 (System Mandatory Level)
  SECURITY_MANDATORY_PROTECTED_PROCESS_RID = $5000; // S-1-16-20480 (Protected Process Mandatory Level)

  SECURITY_AUTHENTICATION_AUTHORITY = 18;                           // S-1-18
  SECURITY_AUTHENTICATION_AUTHORITY_RID_COUNT = 1;                  // S-1-18-X
  SECURITY_AUTHENTICATION_AUTHORITY_ASSERTED_RID = $00000001;       // S-1-18-1 (Authentication authority asserted identity)
  SECURITY_AUTHENTICATION_SERVICE_ASSERTED_RID = $00000002;         // S-1-18-2 (Service asserted identity)
  SECURITY_AUTHENTICATION_FRESH_KEY_AUTH_RID = $00000003;           // S-1-18-3 (Fresh public key identity)
  SECURITY_AUTHENTICATION_KEY_TRUST_RID = $00000004;                // S-1-18-4 (Key trust identity)
  SECURITY_AUTHENTICATION_KEY_PROPERTY_MFA_RID = $00000005;         // S-1-18-5 (Key property multi-factor authentication)
  SECURITY_AUTHENTICATION_KEY_PROPERTY_ATTESTATION_RID = $00000006; // S-1-18-6 (Key property attestation)

  SECURITY_PROCESS_TRUST_AUTHORITY = 19;          // S-1-19
  SECURITY_PROCESS_TRUST_AUTHORITY_RID_COUNT = 2; // S-1-19-X-X

  SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID = $00000000; // S-1-19-0-X
  SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID = $00000200; // S-1-19-512-X
  SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID = $00000400; // S-1-19-1024-X

  SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID = $00000000;         // S-1-19-X-0
  SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID = $00000400; // S-1-19-X-1024
  SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID = $00000600;  // S-1-19-X-1536
  SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID = $00000800;          // S-1-19-X-2048
  SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID = $00001000;      // S-1-19-X-4096
  SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID = $00002000;       // S-1-19-X-8192

  // Well-known LUIDs
  SYSTEM_LUID = $3e7;
  ANONYMOUS_LOGON_LUID = $3e6;
  LOCALSERVICE_LUID = $3e5;
  NETWORKSERVICE_LUID = $3e4;
  IUSER_LUID = $3e3;

  // ACL
  ACL_REVISION = 2;
  ACL_REVISION3 = 3; // for comound ACEs
  ACL_REVISION_DS = 4; // for object ACEs
  MAX_ACL_SIZE = High(Word) and not (SizeOf(Cardinal) - 1);

  // ACE flags
  OBJECT_INHERIT_ACE = $1;
  CONTAINER_INHERIT_ACE = $2;
  NO_PROPAGATE_INHERIT_ACE = $4;
  INHERIT_ONLY_ACE = $8;
  INHERITED_ACE = $10;
  CRITICAL_ACE_FLAG = $20;               // for access allowed ace
  SUCCESSFUL_ACCESS_ACE_FLAG = $40;      // for audit and alarm aces
  FAILED_ACCESS_ACE_FLAG = $80;          // for audit and alarm aces
  TRUST_PROTECTED_FILTER_ACE_FLAG = $40; // for access filter ace

  // Object ACE flags
  ACE_OBJECT_TYPE_PRESENT = $1;
  ACE_INHERITED_OBJECT_TYPE_PRESENT = $2;

  // Mandatory policy flags
  SYSTEM_MANDATORY_LABEL_NO_WRITE_UP = $1;
  SYSTEM_MANDATORY_LABEL_NO_READ_UP = $2;
  SYSTEM_MANDATORY_LABEL_NO_EXECUTE_UP = $4;

  // SD version
  SECURITY_DESCRIPTOR_REVISION = 1;

  // SDK::winnt.h & WDK::ntifs.h - security descriptor control
  SE_OWNER_DEFAULTED = $0001;
  SE_GROUP_DEFAULTED = $0002;
  SE_DACL_PRESENT = $0004;
  SE_DACL_DEFAULTED = $0008;
  SE_SACL_PRESENT = $0010;
  SE_SACL_DEFAULTED = $0020;
  SE_DACL_UNTRUSTED = $0040;
  SE_SERVER_SECURITY = $0080;
  SE_DACL_AUTO_INHERIT_REQ = $0100;
  SE_SACL_AUTO_INHERIT_REQ = $0200;
  SE_DACL_AUTO_INHERITED = $0400;
  SE_SACL_AUTO_INHERITED = $0800;
  SE_DACL_PROTECTED = $1000;
  SE_SACL_PROTECTED = $2000;
  SE_RM_CONTROL_VALID = $4000;
  SE_SELF_RELATIVE = $8000;

  // Security information values
  OWNER_SECURITY_INFORMATION = $00000001; // q: RC; s: WO
  GROUP_SECURITY_INFORMATION = $00000002; // q: RC; s: WO
  DACL_SECURITY_INFORMATION = $00000004;  // q: RC; s: WD
  SACL_SECURITY_INFORMATION = $00000008;  // q, s: AS
  LABEL_SECURITY_INFORMATION = $00000010; // q: RC; s: WO
  ATTRIBUTE_SECURITY_INFORMATION = $00000020; // q: RC; s: WD; Win 8+
  SCOPE_SECURITY_INFORMATION = $00000040; // q: RC; s: AS; Win 8+
  PROCESS_TRUST_LABEL_SECURITY_INFORMATION = $00000080; // q: RC; s: WD; Win 8.1+
  ACCESS_FILTER_SECURITY_INFORMATION = $00000100; // Win 10 RS2+
  BACKUP_SECURITY_INFORMATION = $00010000; // q: RC | AS; s: WD | WO | AS; Win 8+

  PROTECTED_DACL_SECURITY_INFORMATION = $80000000;   // s: WD
  PROTECTED_SACL_SECURITY_INFORMATION = $40000000;   // s: AS
  UNPROTECTED_DACL_SECURITY_INFORMATION = $20000000; // s: WD
  UNPROTECTED_SACL_SECURITY_INFORMATION = $10000000; // s: AS

  // DLL reasons
  DLL_PROCESS_DETACH = 0;
  DLL_PROCESS_ATTACH = 1;
  DLL_THREAD_ATTACH = 2;
  DLL_THREAD_DETACH = 3;
  DLL_PROCESS_VERIFIER = 4;

  // process access masks
  PROCESS_TERMINATE = $0001;
  PROCESS_CREATE_THREAD = $0002;
  PROCESS_SET_SESSIONID = $0004;
  PROCESS_VM_OPERATION = $0008;
  PROCESS_VM_READ = $0010;
  PROCESS_VM_WRITE = $0020;
  PROCESS_DUP_HANDLE = $0040;
  PROCESS_CREATE_PROCESS = $0080;
  PROCESS_SET_QUOTA = $0100;
  PROCESS_SET_INFORMATION = $0200;
  PROCESS_QUERY_INFORMATION = $0400;
  PROCESS_SUSPEND_RESUME = $0800;
  PROCESS_QUERY_LIMITED_INFORMATION = $1000;
  PROCESS_SET_LIMITED_INFORMATION = $2000;

  PROCESS_ALL_ACCESS = STANDARD_RIGHTS_ALL or SPECIFIC_RIGHTS_ALL;

  // thread access mask
  THREAD_TERMINATE = $0001;
  THREAD_SUSPEND_RESUME = $0002;
  THREAD_ALERT = $0004;
  THREAD_GET_CONTEXT = $0008;
  THREAD_SET_CONTEXT = $0010;
  THREAD_SET_INFORMATION = $0020;
  THREAD_QUERY_INFORMATION = $0040;
  THREAD_SET_THREAD_TOKEN = $0080;
  THREAD_IMPERSONATE = $0100;
  THREAD_DIRECT_IMPERSONATION = $0200;
  THREAD_SET_LIMITED_INFORMATION = $0400;
  THREAD_QUERY_LIMITED_INFORMATION = $0800;
  THREAD_RESUME = $1000;

  THREAD_ALL_ACCESS = STANDARD_RIGHTS_ALL or SPECIFIC_RIGHTS_ALL;

type
  // NOTE: Indexing elements other then 0 in an any-size array when range checks
  // are enabled generates exceptions. Make sure to temporarily suppress range
  // checks by using {$R-} and then enable them back. Unfortunately, Delphi
  // doesn't seem to provide a macro for restoring them to the global-defined
  // state (which can also be disabled). Because of that, we use
  // {$IFOPT R+}{$DEFINE R+}{$ENDIF} in the beggining of the implementation
  // section of each unit to save the default state into an R+ conditional
  // symbol (don't confuse it with the $R+ switch). Then whenever we want to
  // restore range checks, we use {$IFDEF R+}{$R+}{$ENDIF} which enables them
  // back only if they are enabled globally.
  //
  // TLDR; use {$R-}[i]{$IFDEF R+}{$R+}{$ENDIF} to index any-size arrays and
  // don't forget to put {$IFOPT R+}{$DEFINE R+}{$ENDIF} in the beggining of
  // the unit.
  //
  ANYSIZE_ARRAY = 0..0;
  TAnysizeArray<T> = array [ANYSIZE_ARRAY] of T;

  MAX_PATH_ARRAY = 0..MAX_PATH - 1;
  MAX_LONG_PATH_ARRAY = 0..MAX_LONG_PATH - 1;

  // A zero-size placeholder
  TPlaceholder = record
  end;

  // A zero-size placeholder for a specific type
  TPlaceholder<T> = record
  private
    function GetContent: T;
  public
    property Content: T read GetContent;
  end;

  MAKEINTRESOURCE = PWideChar;

  PAnsiMultiSz = type PAnsiChar;
  PWideMultiSz = type PWideChar;

  TWin32Error = type Cardinal;

  // Absolute times
  [SDKName('LARGE_INTEGER')]
  TLargeInteger = type Int64;
  PLargeInteger = ^TLargeInteger;
  TUnixTime = type Cardinal;

  // Relative times
  [SDKName('ULARGE_INTEGER')]
  TULargeInteger = type UInt64;
  PULargeInteger = ^TULargeInteger;

  [SDKName('LUID')]
  [Hex] TLuid = type UInt64;
  PLuid = ^TLuid;

  THandle32 = type Cardinal;
  TProcessId = type NativeUInt;
  TThreadId = type NativeUInt;
  TProcessId32 = type Cardinal;
  TThreadId32 = type Cardinal;
  TServiceTag = type Cardinal;

  TLogonId = type TLuid;
  TSessionId = type Cardinal;

  PEnvironment = type PWideChar;

  PListEntry = ^TListEntry;
  [SDKName('LIST_ENTRY')]
  TListEntry = record
    Flink: PListEntry;
    Blink: PListEntry;
  end;

  [SDKName('M128A')]
  M128A = record
    Low: UInt64;
    High: Int64;
  end align 16;
  PM128A = ^M128A;

  [FlagName(EFLAGS_CF, 'Carry')]
  [FlagName(EFLAGS_PF, 'Parity')]
  [FlagName(EFLAGS_AF, 'Auxiliary Carry')]
  [FlagName(EFLAGS_ZF, 'Zero')]
  [FlagName(EFLAGS_SF, 'Sign')]
  [FlagName(EFLAGS_TF, 'Trap')]
  [FlagName(EFLAGS_IF, 'Interrupt')]
  [FlagName(EFLAGS_DF, 'Direction')]
  [FlagName(EFLAGS_OF, 'Overflow')]
  TEFlags = type Cardinal;

  [FlagName(CONTEXT_ALL, 'All')]
  [FlagName(CONTEXT_FULL, 'Full')]
  [FlagName(CONTEXT_CONTROL, 'Control')]
  [FlagName(CONTEXT_INTEGER, 'General-purpose')]
  [FlagName(CONTEXT_SEGMENTS, 'Segments ')]
  [FlagName(CONTEXT_FLOATING_POINT, 'Floating Point')]
  [FlagName(CONTEXT_DEBUG_REGISTERS, 'Debug Registers')]
  [FlagName(CONTEXT_EXTENDED_REGISTERS, 'Extended Registers')]
  [FlagName(CONTEXT_i386, 'i386')]
  [FlagName(CONTEXT_AMD64, 'AMD64')]
  TContextFlags = type Cardinal;

  {$ALIGN 16}
  [Hex]
  TContext64 = record
    PnHome: array [1..6] of UInt64;
    ContextFlags: TContextFlags;
    [Hex] MxCsr: Cardinal;
    [Hex] SegCs: Word;
    [Hex] SegDs: Word;
    [Hex] SegEs: Word;
    [Hex] SegFs: Word;
    [Hex] SegGs: Word;
    [Hex] SegSs: Word;
    EFlags: TEFlags;
    [Hex] Dr0: UInt64;
    [Hex] Dr1: UInt64;
    [Hex] Dr2: UInt64;
    [Hex] Dr3: UInt64;
    [Hex] Dr6: UInt64;
    [Hex] Dr7: UInt64;
    [Hex] Rax: UInt64;
    [Hex] Rcx: UInt64;
    [Hex] Rdx: UInt64;
    [Hex] Rbx: UInt64;
    [Hex] Rsp: UInt64;
    [Hex] Rbp: UInt64;
    [Hex] Rsi: UInt64;
    [Hex] Rdi: UInt64;
    [Hex] R8: UInt64;
    [Hex] R9: UInt64;
    [Hex] R10: UInt64;
    [Hex] R11: UInt64;
    [Hex] R12: UInt64;
    [Hex] R13: UInt64;
    [Hex] R14: UInt64;
    [Hex] R15: UInt64;
    [Hex] Rip: UInt64;
    FloatingPointState: array [0..31] of M128A;
    VectorRegister: array [0..25] of M128A;
    [Hex] VectorControl: UInt64;
    [Hex] DebugControl: UInt64;
    [Hex] LastBranchToRip: UInt64;
    [Hex] LastBranchFromRip: UInt64;
    [Hex] LastExceptionToRip: UInt64;
    [Hex] LastExceptionFromRip: UInt64;
    property Ax: UInt64 read Rax write Rax;
    property Cx: UInt64 read Rcx write Rcx;
    property Dx: UInt64 read Rdx write Rdx;
    property Bx: UInt64 read Rbx write Rbx;
    property Sp: UInt64 read Rsp write Rsp;
    property Bp: UInt64 read Rbp write Rbp;
    property Si: UInt64 read Rsi write Rsi;
    property Di: UInt64 read Rdi write Rdi;
    property Ip: UInt64 read Rip write Rip;
  end align 16;
  PContext64 = ^TContext64;
  {$ALIGN 8}

  [SDKName('FLOATING_SAVE_AREA')]
  TFloatingSaveArea = record
  const
    SIZE_OF_80387_REGISTERS = 80;
  var
    ControlWord: Cardinal;
    StatusWord: Cardinal;
    TagWord: Cardinal;
    ErrorOffset: Cardinal;
    ErrorSelector: Cardinal;
    DataOffset: Cardinal;
    DataSelector: Cardinal;
    RegisterArea: array [0 .. SIZE_OF_80387_REGISTERS - 1] of Byte;
    Cr0NpxState: Cardinal;
  end;

  [Hex]
  TContext32 = record
  const
    MAXIMUM_SUPPORTED_EXTENSION = 512;
  var
    ContextFlags: TContextFlags;
    [Hex] Dr0: Cardinal;
    [Hex] Dr1: Cardinal;
    [Hex] Dr2: Cardinal;
    [Hex] Dr3: Cardinal;
    [Hex] Dr6: Cardinal;
    [Hex] Dr7: Cardinal;
    FloatSave: TFloatingSaveArea;
    [Hex] SegGs: Cardinal;
    [Hex] SegFs: Cardinal;
    [Hex] SegEs: Cardinal;
    [Hex] SegDs: Cardinal;
    [Hex] Edi: Cardinal;
    [Hex] Esi: Cardinal;
    [Hex] Ebx: Cardinal;
    [Hex] Edx: Cardinal;
    [Hex] Ecx: Cardinal;
    [Hex] Eax: Cardinal;
    [Hex] Ebp: Cardinal;
    [Hex] Eip: Cardinal;
    [Hex] SegCs: Cardinal;
    EFlags: TEFlags;
    [Hex] Esp: Cardinal;
    [Hex] SegSs: Cardinal;
    ExtendedRegisters: array [0 .. MAXIMUM_SUPPORTED_EXTENSION - 1] of Byte;
    property Ax: Cardinal read Eax write Eax;
    property Cx: Cardinal read Ecx write Ecx;
    property Dx: Cardinal read Edx write Edx;
    property Bx: Cardinal read Ebx write Ebx;
    property Sp: Cardinal read Esp write Esp;
    property Bp: Cardinal read Ebp write Ebp;
    property Si: Cardinal read Esi write Esi;
    property Di: Cardinal read Edi write Edi;
    property Ip: Cardinal read Eip write Eip;
  end align 8;
  PContext32 = ^TContext32;

  {$IFDEF WIN64}
  TContext = TContext64;
  {$ELSE}
  TContext = TContext32;
  {$ENDIF}
  PContext = ^TContext;

  [FlagName(EXCEPTION_NONCONTINUABLE, 'Non-continuable')]
  [FlagName(EXCEPTION_UNWINDING, 'Unwinding')]
  [FlagName(EXCEPTION_EXIT_UNWIND, 'Exit Unwinding')]
  [FlagName(EXCEPTION_STACK_INVALID, 'Stack Invalid')]
  [FlagName(EXCEPTION_NESTED_CALL, 'Nested Exception Call')]
  [FlagName(EXCEPTION_TARGET_UNWIND, 'Target Unwinding')]
  [FlagName(EXCEPTION_COLLIDED_UNWIND, 'Collided Unwind')]
  TExceptionFlags = type Cardinal;

  PExceptionRecord = ^TExceptionRecord;
  [SDKName('EXCEPTION_RECORD')]
  TExceptionRecord = record
    [Hex] ExceptionCode: Cardinal;
    ExceptionFlags: TExceptionFlags;
    ExceptionRecord: PExceptionRecord;
    ExceptionAddress: Pointer;
    NumberParameters: Cardinal;
    ExceptionInformation: array [0 .. EXCEPTION_MAXIMUM_PARAMETERS - 1] of
      NativeUInt;
  end;

  [SDKName('EXCEPTION_POINTERS')]
  TExceptionPointers = record
    ExceptionRecord: PExceptionRecord;
    ContextRecord: PContext;
  end;
  PExceptionPointers = ^TExceptionPointers;

  [FriendlyName('object'), ValidBits($FFFFFFFF)]
  [FlagName(READ_CONTROL, 'Read Permissions')]
  [FlagName(WRITE_DAC, 'Write Permissions')]
  [FlagName(WRITE_OWNER, 'Write Owner')]
  [FlagName(SYNCHRONIZE, 'Synchronize')]
  [FlagName(_DELETE, 'Delete')]
  [FlagName(ACCESS_SYSTEM_SECURITY, 'System Security')]
  [FlagName(MAXIMUM_ALLOWED, 'Maximum Allowed')]
  [FlagName(GENERIC_READ, 'Generic Read')]
  [FlagName(GENERIC_WRITE, 'Generic Write')]
  [FlagName(GENERIC_EXECUTE, 'Generic Execute')]
  [FlagName(GENERIC_ALL, 'Generic All')]
  TAccessMask = type Cardinal;

  [SDKName('GENERIC_MAPPING')]
  TGenericMapping = record
    GenericRead: TAccessMask;
    GenericWrite: TAccessMask;
    GenericExecute: TAccessMask;
    GenericAll: TAccessMask;
  end;
  PGenericMapping = ^TGenericMapping;

  [SDKName('SID_IDENTIFIER_AUTHORITY')]
  TSidIdentifierAuthority = record
    Value: array [0..5] of Byte;
    class operator Implicit(const Source: UInt64): TSidIdentifierAuthority;
    class operator Implicit(const Source: TSidIdentifierAuthority): UInt64;
  end;
  PSidIdentifierAuthority = ^TSidIdentifierAuthority;

  [SDKName('SID')]
  TSid = record
   Revision: Byte;
   SubAuthorityCount: Byte;
   IdentifierAuthority: TSidIdentifierAuthority;
   SubAuthority: array [0 .. SID_MAX_SUB_AUTHORITIES - 1] of Cardinal;
  end;
  PSid = ^TSid;

  [SDKName('SID_NAME_USE')]
  [NamingStyle(nsCamelCase, 'SidType'), Range(1)]
  TSidNameUse = (
    SidTypeUndefined = 0,
    SidTypeUser = 1,
    SidTypeGroup = 2,
    SidTypeDomain = 3,
    SidTypeAlias = 4,
    SidTypeWellKnownGroup = 5,
    SidTypeDeletedAccount = 6,
    SidTypeInvalid = 7,
    SidTypeUnknown = 8,
    SidTypeComputer = 9,
    SidTypeLabel = 10,
    SidTypeLogonSession = 11
  );

  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_TYPE_NONE_RID, 'None')]
  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_TYPE_LITE_RID, 'Lite')]
  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_TYPE_FULL_RID, 'Full')]
  TSecurityTrustType = type Cardinal;

  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_LEVEL_NONE_RID, 'None')]
  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_LEVEL_AUTHENTICODE_RID, 'Authenticode')]
  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_LEVEL_ANTIMALWARE_RID, 'Antimalware')]
  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_LEVEL_APP_RID, 'Store App')]
  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_LEVEL_WINDOWS_RID, 'Windows')]
  [SubEnum(MAX_UINT, SECURITY_PROCESS_PROTECTION_LEVEL_WINTCB_RID, 'TCB')]
  TSecurityTrustLevel = type Cardinal;

  [SDKName('ACL')]
  TAcl = record
    AclRevision: Byte;
    Sbz1: Byte;
    AclSize: Word;
    AceCount: Word;
    Sbz2: Word;
  end;
  PAcl = ^TAcl;

  {$MINENUMSIZE 1}
  [NamingStyle(nsSnakeCase, 'SYSTEM', 'ACE_TYPE')]
  TAceType = (
    ACCESS_ALLOWED_ACE_TYPE = 0, // Non-object
    ACCESS_DENIED_ACE_TYPE = 1,  // Non-object
    SYSTEM_AUDIT_ACE_TYPE = 2,   // Non-object
    SYSTEM_ALARM_ACE_TYPE = 3,   // Non-object

    ACCESS_ALLOWED_COMPOUND_ACE_TYPE = 4, // Compound

    ACCESS_ALLOWED_OBJECT_ACE_TYPE = 5, // Object
    ACCESS_DENIED_OBJECT_ACE_TYPE = 6,  // Object
    SYSTEM_AUDIT_OBJECT_ACE_TYPE = 7,   // Object
    SYSTEM_ALARM_OBJECT_ACE_TYPE = 8,   // Object

    ACCESS_ALLOWED_CALLBACK_ACE_TYPE = 9, // Non-object with extra data
    ACCESS_DENIED_CALLBACK_ACE_TYPE = 10, // Non-object with extra data

    ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE = 11, // Object with extra data
    ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE = 12,  // Object with extra data

    SYSTEM_AUDIT_CALLBACK_ACE_TYPE = 13, // Non-object with extra data
    SYSTEM_ALARM_CALLBACK_ACE_TYPE = 14, // Non-object with extra data

    SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE = 15, // Object with extra data
    SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE = 16, // Object with extra data

    SYSTEM_MANDATORY_LABEL_ACE_TYPE = 17,     // Non-object, LABEL_SECURITY_INFORMATION
    SYSTEM_RESOURCE_ATTRIBUTE_ACE_TYPE = 18,  // Non-object with extra data, ATTRIBUTE_SECURITY_INFORMATION
    SYSTEM_SCOPED_POLICY_ID_ACE_TYPE = 19,    // Non-object, SCOPE_SECURITY_INFORMATION
    SYSTEM_PROCESS_TRUST_LABEL_ACE_TYPE = 20, // Non-object, PROCESS_TRUST_LABEL_SECURITY_INFORMATION
    SYSTEM_ACCESS_FILTER_ACE_TYPE = 21        // Non-object with extra data, ACCESS_FILTER_SECURITY_INFORMATION
  );
  {$MINENUMSIZE 4}

  TAceTypeSet = set of TAceType;

  [FlagName(OBJECT_INHERIT_ACE, 'Object Inherit')]
  [FlagName(CONTAINER_INHERIT_ACE, 'Container Inherit')]
  [FlagName(NO_PROPAGATE_INHERIT_ACE, 'No Propagate Inherit')]
  [FlagName(INHERIT_ONLY_ACE, 'Inherit-only')]
  [FlagName(INHERITED_ACE, 'Inherited')]
  [FlagName(CRITICAL_ACE_FLAG, 'Critical')]
  [FlagName(SUCCESSFUL_ACCESS_ACE_FLAG, 'Successful Access / Trust-protected Filter')]
  [FlagName(FAILED_ACCESS_ACE_FLAG, 'Falied Access')]
  TAceFlags = type Byte;

  [SDKName('ACE_HEADER')]
  TAceHeader = record
    AceType: TAceType;
    AceFlags: TAceFlags;
    [Bytes] AceSize: Word;
    function Revision: Cardinal;
  end;
  PAceHeader = ^TAceHeader;

  [SDKName('KNOWN_ACE')] // symbols
  [SDKName('ACCESS_ALLOWED_ACE')]
  [SDKName('ACCESS_DENIED_ACE')]
  [SDKName('SYSTEM_AUDIT_ACE')]
  [SDKName('SYSTEM_ALARM_ACE')]
  [SDKName('ACCESS_ALLOWED_CALLBACK_ACE')]
  [SDKName('ACCESS_DENIED_CALLBACK_ACE')]
  [SDKName('SYSTEM_AUDIT_CALLBACK_ACE')]
  [SDKName('SYSTEM_ALARM_CALLBACK_ACE')]
  [SDKName('SYSTEM_MANDATORY_LABEL_ACE')]
  [SDKName('SYSTEM_RESOURCE_ATTRIBUTE_ACE')]
  [SDKName('SYSTEM_SCOPED_POLICY_ID_ACE')]
  [SDKName('SYSTEM_PROCESS_TRUST_LABEL_ACE')]
  [SDKName('SYSTEM_ACCESS_FILTER_ACE')]
  TKnownAce = record
    Header: TAceHeader;
    Mask: TAccessMask;
  private
    SidStart: TPlaceholder;
  public
    function Sid: PSid;
    function ExtraData: Pointer;
    function ExtraDataSize: Word;
  end;
  PKnownAce = ^TKnownAce;

  [FlagName(SYSTEM_MANDATORY_LABEL_NO_WRITE_UP, 'No-Write-Up')]
  [FlagName(SYSTEM_MANDATORY_LABEL_NO_READ_UP, 'No-Read-Up')]
  [FlagName(SYSTEM_MANDATORY_LABEL_NO_EXECUTE_UP, 'No-Execute-Up')]
  TMandatoryLabelMask = type TAccessMask;

  // private
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'COMPOUND_ACE'), Range(1)]
  TCompundAceType = (
    [Reserved] COMPOUND_ACE_INVALID = 0,
    COMPOUND_ACE_IMPERSONATION = 1
  );
  {$MINENUMSIZE 4}

  // symbols
  [SDKName('KNOWN_COMPOUND_ACE')]
  [SDKName('COMPOUND_ACCESS_ALLOWED_ACE')]
  TKnownCompoundAce = record
    Header: TAceHeader;
    Mask: TAccessMask;
    CompoundAceType: TCompundAceType;
    [Reserved] Reserved: Word;
  private
    ServerSidStart: TPlaceholder;
    // Client SID follows
  public
    function ServerSid: PSid;
    function ClientSid: PSid;
    function ExtraData: Pointer;
    function ExtraDataSize: Word;
  end;
  PKnownCompoundAce = ^TKnownCompoundAce;

  [FlagName(ACE_OBJECT_TYPE_PRESENT, 'Object Type Present')]
  [FlagName(ACE_INHERITED_OBJECT_TYPE_PRESENT, 'Inherited Object Type Present')]
  TObjectAceFlags = type Cardinal;

  [SDKName('KNOWN_OBJECT_ACE')] // symbols
  [SDKName('ACCESS_ALLOWED_OBJECT_ACE')]
  [SDKName('ACCESS_DENIED_OBJECT_ACE')]
  [SDKName('SYSTEM_AUDIT_OBJECT_ACE')]
  [SDKName('SYSTEM_ALARM_OBJECT_ACE')]
  [SDKName('ACCESS_ALLOWED_CALLBACK_OBJECT_ACE')]
  [SDKName('ACCESS_DENIED_CALLBACK_OBJECT_ACE')]
  [SDKName('SYSTEM_AUDIT_CALLBACK_OBJECT_ACE')]
  [SDKName('SYSTEM_ALARM_CALLBACK_OBJECT_ACE')]
  TKnownObjectAce = record
    Header: TAceHeader;
    Mask: TAccessMask;
    Flags: TObjectAceFlags;
  private
    VariablePart: TPlaceholder;
    // ObjectType GUID
    // InheritedObjectType GUID
    // SID
  public
    function ObjectType: PGuid;
    function InheritedObjectType: PGuid;
    function Sid: PSid;
    function ExtraData: Pointer;
    function ExtraDataSize: Word;
  end;
  PKnownObjectAce = ^TKnownObjectAce;

  TAce_Internal = record
  case Integer of
    0: (Header: TAceHeader);
    1: (NonObjectAce: TKnownAce);
    2: (ObjectAce: TKnownObjectAce);
    3: (CompoundAce: TKnownCompoundAce);
  end;
  PAce = ^TAce_Internal;

  [SDKName('KNOWN_OBJECT_ACE')] // symbols
  [SDKName('ACL_INFORMATION_CLASS')]
  [NamingStyle(nsCamelCase, 'Acl'), Range(1)]
  TAclInformationClass = (
    AclReserved = 0,
    AclRevisionInformation = 1, // q: Cardinal (revision)
    AclSizeInformation = 2      // q: TAclSizeInformation
  );

  [SDKName('ACL_SIZE_INFORMATION')]
  TAclSizeInformation = record
    AceCount: Integer;
    [Bytes] AclBytesInUse: Cardinal;
    [Bytes] AclBytesFree: Cardinal;
    function AclBytesInUseByAces: Cardinal;
    function AclBytesTotal: Cardinal;
  end;
  PAclSizeInformation = ^TAclSizeInformation;

  [SDKName('SECURITY_DESCRIPTOR_CONTROL')]
  [FlagName(SE_OWNER_DEFAULTED, 'Owner Defaulted')]
  [FlagName(SE_GROUP_DEFAULTED, 'Group Defaulted')]
  [FlagName(SE_DACL_PRESENT, 'DACL Present')]
  [FlagName(SE_DACL_DEFAULTED, 'DACL Defaulted')]
  [FlagName(SE_SACL_PRESENT, 'SACL Present')]
  [FlagName(SE_SACL_DEFAULTED, 'SACL Defaulted')]
  [FlagName(SE_DACL_UNTRUSTED, 'DACL Untrusted')]
  [FlagName(SE_SERVER_SECURITY, 'Server Security')]
  [FlagName(SE_DACL_AUTO_INHERIT_REQ, 'DACL Auto-inherit Required')]
  [FlagName(SE_SACL_AUTO_INHERIT_REQ, 'SACL Auto-inherit Required')]
  [FlagName(SE_DACL_AUTO_INHERITED, 'DACL Auto-inherited')]
  [FlagName(SE_SACL_AUTO_INHERITED, 'SACL Auto-inherited')]
  [FlagName(SE_DACL_PROTECTED, 'DACL Protected')]
  [FlagName(SE_SACL_PROTECTED, 'SACL Protected')]
  [FlagName(SE_RM_CONTROL_VALID, 'RM Control Valid')]
  [FlagName(SE_SELF_RELATIVE, 'Self-relative')]
  TSecurityDescriptorControl = type Word;
  PSecurityDescriptorControl = ^TSecurityDescriptorControl;

  [SDKName('SECURITY_DESCRIPTOR')]
  TSecurityDescriptor = record
    Revision: Byte;
    Sbz1: Byte;
  case Control: TSecurityDescriptorControl of
    SE_SELF_RELATIVE: (
      OwnerOffset: Cardinal;
      GroupOffset: Cardinal;
      SaclOffset: Cardinal;
      DaclOffset: Cardinal
    );
    0: (
      Owner: PSid;
      Group: PSid;
      Sacl: PAcl;
      Dacl: PAcl
    );
  end;
  PSecurityDescriptor = ^TSecurityDescriptor;

  [SDKName('SECURITY_IMPERSONATION_LEVEL')]
  [NamingStyle(nsCamelCase, 'Security')]
  TSecurityImpersonationLevel = (
    SecurityAnonymous = 0,
    SecurityIdentification = 1,
    SecurityImpersonation = 2,
    SecurityDelegation = 3
  );

  [SDKName('SECURITY_QUALITY_OF_SERVICE')]
  TSecurityQualityOfService = record
    [Bytes, Unlisted] Length: Cardinal;
    ImpersonationLevel: TSecurityImpersonationLevel;
    ContextTrackingMode: Boolean;
    EffectiveOnly: Boolean;
  end;
  PSecurityQualityOfService = ^TSecurityQualityOfService;

  [SDKName('SECURITY_INFORMATION')]
  [FlagName(OWNER_SECURITY_INFORMATION, 'Owner')]
  [FlagName(GROUP_SECURITY_INFORMATION, 'Group')]
  [FlagName(DACL_SECURITY_INFORMATION, 'DACL')]
  [FlagName(SACL_SECURITY_INFORMATION, 'SACL')]
  [FlagName(LABEL_SECURITY_INFORMATION, 'Label')]
  [FlagName(ATTRIBUTE_SECURITY_INFORMATION, 'Attribute')]
  [FlagName(SCOPE_SECURITY_INFORMATION, 'Scope')]
  [FlagName(PROCESS_TRUST_LABEL_SECURITY_INFORMATION, 'Trust Label')]
  [FlagName(ACCESS_FILTER_SECURITY_INFORMATION, 'Filter')]
  [FlagName(BACKUP_SECURITY_INFORMATION, 'Backup')]
  [FlagName(PROTECTED_DACL_SECURITY_INFORMATION, 'Protected DACL')]
  [FlagName(PROTECTED_SACL_SECURITY_INFORMATION, 'Protected SACL')]
  [FlagName(UNPROTECTED_DACL_SECURITY_INFORMATION, 'Unprotected DACL')]
  [FlagName(UNPROTECTED_SACL_SECURITY_INFORMATION, 'Unprotected SACL')]
  TSecurityInformation = type Cardinal;

  {$MINENUMSIZE 1}
  [MinOSVersion(OsWin8)]
  [SDKName('SE_SIGNING_LEVEL')]
  [NamingStyle(nsSnakeCase, 'SE_SIGNING_LEVEL')]
  [ValidBits([0..4, 6..8, 11..12, 14])]
  TSeSigningLevel = (
    SE_SIGNING_LEVEL_UNCHECKED = 0,
    SE_SIGNING_LEVEL_UNSIGNED = 1,
    SE_SIGNING_LEVEL_ENTERPRISE = 2,
    SE_SIGNING_LEVEL_DEVELOPER = 3,
    SE_SIGNING_LEVEL_AUTHENTICODE = 4,
    [Reserved] SE_SIGNING_LEVEL_CUSTOM_2 = 5,
    SE_SIGNING_LEVEL_STORE = 6,
    SE_SIGNING_LEVEL_ANTIMALWARE = 7,
    SE_SIGNING_LEVEL_MICROSOFT = 8,
    [Reserved] SE_SIGNING_LEVEL_CUSTOM_4 = 9,
    [Reserved] SE_SIGNING_LEVEL_CUSTOM_5 = 10,
    SE_SIGNING_LEVEL_DYNAMIC_CODEGEN = 11,
    SE_SIGNING_LEVEL_WINDOWS = 12,
    [Reserved] SE_SIGNING_LEVEL_CUSTOM_7 = 13,
    SE_SIGNING_LEVEL_WINDOWS_TCB = 14,
    [Reserved] SE_SIGNING_LEVEL_CUSTOM_6 = 15
  );
  {$MINENUMSIZE 4}

  [SDKName('QUOTA_LIMITS')]
  TQuotaLimits = record
    [Bytes] PagedPoolLimit: NativeUInt;
    [Bytes] NonPagedPoolLimit: NativeUInt;
    [Bytes] MinimumWorkingSetSize: NativeUInt;
    [Bytes] MaximumWorkingSetSize: NativeUInt;
    [Bytes] PagefileLimit: NativeUInt;
    TimeLimit: TLargeInteger;
  end;
  PQuotaLimits = ^TQuotaLimits;

  [SDKName('IO_COUNTERS')]
  TIoCounters = record
    ReadOperationCount: UInt64;
    WriteOperationCount: UInt64;
    OtherOperationCount: UInt64;
    [Bytes] ReadTransferCount: UInt64;
    [Bytes] WriteTransferCount: UInt64;
    [Bytes] OtherTransferCount: UInt64;
  end;
  PIoCounters = ^TIoCounters;

  [SDKName('PRTL_CRITICAL_SECTION')]
  PRtlCriticalSection = type Pointer;

  [SubEnum(MAX_UINT, DLL_PROCESS_DETACH, 'Process Detach')]
  [SubEnum(MAX_UINT, DLL_PROCESS_ATTACH, 'Process Attach')]
  [SubEnum(MAX_UINT, DLL_THREAD_ATTACH, 'Thread Attach')]
  [SubEnum(MAX_UINT, DLL_THREAD_DETACH, 'Thread Detach')]
  [SubEnum(MAX_UINT, DLL_PROCESS_VERIFIER, 'Process Verifier')]
  TDllReason = type Cardinal;

  // SDK::winnt.h
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'PROCESSOR_ARCHITECTURE')]
  TProcessorArchitecture = (
    PROCESSOR_ARCHITECTURE_INTEL = 0,
    PROCESSOR_ARCHITECTURE_MIPS = 1,
    PROCESSOR_ARCHITECTURE_ALPHA = 2,
    PROCESSOR_ARCHITECTURE_PPC = 3,
    PROCESSOR_ARCHITECTURE_SHX = 4,
    PROCESSOR_ARCHITECTURE_ARM = 5,
    PROCESSOR_ARCHITECTURE_IA64 = 6,
    PROCESSOR_ARCHITECTURE_ALPHA64 = 7,
    PROCESSOR_ARCHITECTURE_MSIL = 8,
    PROCESSOR_ARCHITECTURE_AMD64 = 9,
    PROCESSOR_ARCHITECTURE_IA32_ON_WIN64 = 10,
    PROCESSOR_ARCHITECTURE_NEUTRAL = 11,
    PROCESSOR_ARCHITECTURE_ARM64 = 12,
    PROCESSOR_ARCHITECTURE_ARM32_ON_WIN64 = 13,
    PROCESSOR_ARCHITECTURE_IA32_ON_ARM64 = 14
  );
  {$MINENUMSIZE 4}

const
  {$IFDEF Win64}
    PROCESSOR_ARCHITECTURE_CURRENT = PROCESSOR_ARCHITECTURE_AMD64;
  {$ELSE}
    PROCESSOR_ARCHITECTURE_CURRENT = PROCESSOR_ARCHITECTURE_INTEL;
  {$ENDIF}

  VALID_SID_TYPES = [
    SidTypeUser..SidTypeDeletedAccount,
    SidTypeComputer..SidTypeLogonSession
  ];

  INVALID_SID_TYPES = [SidTypeUndefined, SidTypeInvalid, SidTypeUnknown];

  NonObjectAces: TAceTypeSet = [ACCESS_ALLOWED_ACE_TYPE..SYSTEM_ALARM_ACE_TYPE,
    ACCESS_ALLOWED_CALLBACK_ACE_TYPE..ACCESS_DENIED_CALLBACK_ACE_TYPE,
    SYSTEM_AUDIT_CALLBACK_ACE_TYPE..SYSTEM_ALARM_CALLBACK_ACE_TYPE,
    SYSTEM_MANDATORY_LABEL_ACE_TYPE..SYSTEM_ACCESS_FILTER_ACE_TYPE
  ];

  ObjectAces: TAceTypeSet = [ACCESS_ALLOWED_OBJECT_ACE_TYPE..
    SYSTEM_ALARM_OBJECT_ACE_TYPE, ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE..
    ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE,
    SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE..SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE
  ];

  AccessAllowedAces: TAceTypeSet = [ACCESS_ALLOWED_ACE_TYPE,
    ACCESS_ALLOWED_COMPOUND_ACE_TYPE, ACCESS_ALLOWED_OBJECT_ACE_TYPE,
    ACCESS_ALLOWED_CALLBACK_ACE_TYPE, ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE];

  AccessDeniedAces: TAceTypeSet = [ACCESS_DENIED_ACE_TYPE,
    ACCESS_DENIED_OBJECT_ACE_TYPE, ACCESS_DENIED_CALLBACK_ACE_TYPE,
    ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE];

  CallbackAces: TAceTypeSet = [ACCESS_ALLOWED_CALLBACK_ACE_TYPE..
    SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE, SYSTEM_ACCESS_FILTER_ACE_TYPE];

  INFINITE_FUTURE = TLargeInteger(-1);

function TimeoutToLargeInteger(
  [in] const [ref] Timeout: Int64
): PLargeInteger; inline;

// Expected access masks when accessing security
function SecurityReadAccess(Info: TSecurityInformation): TAccessMask;
function SecurityWriteAccess(Info: TSecurityInformation): TAccessMask;

implementation

uses
  Ntapi.ntrtl;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TPlaceholder<T> }

function TPlaceholder<T>.GetContent;
begin
  Result := T(Pointer(@Self)^);
end;

{ TSidIdentifierAuthority }

class operator TSidIdentifierAuthority.Implicit(
  const Source: TSidIdentifierAuthority): UInt64;
begin
  Result := (UInt64(Source.Value[5]) shl  0) or
            (UInt64(Source.Value[4]) shl  8) or
            (UInt64(Source.Value[3]) shl 16) or
            (UInt64(Source.Value[2]) shl 24) or
            (UInt64(Source.Value[1]) shl 32) or
            (UInt64(Source.Value[0]) shl 40);
end;

class operator TSidIdentifierAuthority.Implicit(
  const Source: UInt64): TSidIdentifierAuthority;
begin
  Result.Value[0] := Byte(Source shr 40);
  Result.Value[1] := Byte(Source shr 32);
  Result.Value[2] := Byte(Source shr 24);
  Result.Value[3] := Byte(Source shr 16);
  Result.Value[4] := Byte(Source shr 8);
  Result.Value[5] := Byte(Source shr 0);
end;

{ TAceHeader }

function TAceHeader.Revision;
begin
  if AceType in ObjectAces then
    Result := ACL_REVISION_DS
  else if AceType = ACCESS_ALLOWED_COMPOUND_ACE_TYPE then
    Result := ACL_REVISION3
  else
    Result := ACL_REVISION;
end;

{ TKnownAce }

function TKnownAce.ExtraData;
begin
  Pointer(Result) := PByte(@Self.SidStart) + RtlLengthSid(Sid);
end;

function TKnownAce.ExtraDataSize;
begin
  Result := Cardinal(Header.AceSize) - SizeOf(TKnownAce) - RtlLengthSid(Sid);
end;

function TKnownAce.Sid;
begin
  Pointer(Result) := @Self.SidStart;
end;

{ TKnownCompoundAce }

function TKnownCompoundAce.ClientSid;
begin
  Pointer(Result) := PByte(@Self.ServerSidStart) + RtlLengthSid(ServerSid);
end;

function TKnownCompoundAce.ExtraData;
begin
  Result := PByte(ClientSid) + RtlLengthSid(ClientSid);
end;

function TKnownCompoundAce.ExtraDataSize: Word;
begin
  Result := Word(UIntPtr(@Self) + Header.AceSize - UIntPtr(ExtraData));
end;

function TKnownCompoundAce.ServerSid;
begin
  Pointer(Result) := @Self.ServerSidStart;
end;

{ TKnownObjectAce }

function TKnownObjectAce.ExtraData;
begin
  Pointer(Result) := PByte(Sid) + RtlLengthSid(Sid);
end;

function TKnownObjectAce.ExtraDataSize;
begin
  Result := Word(UIntPtr(@Self) + Header.AceSize - UIntPtr(ExtraData));
end;

function TKnownObjectAce.InheritedObjectType;
begin
  if Flags and ACE_INHERITED_OBJECT_TYPE_PRESENT <> 0 then
    if Flags and ACE_OBJECT_TYPE_PRESENT <> 0 then
      Pointer(Result) := PByte(@VariablePart) + SizeOf(TGuid)
    else
      Result := Pointer(@VariablePart)
  else
    Result := nil;
end;

function TKnownObjectAce.ObjectType;
begin
  if Flags and ACE_OBJECT_TYPE_PRESENT <> 0 then
    Result := Pointer(@VariablePart)
  else
    Result := nil;
end;

function TKnownObjectAce.Sid;
var
  Offset: Cardinal;
begin
  Offset := 0;

  if Flags and ACE_OBJECT_TYPE_PRESENT <> 0 then
    Inc(Offset, SizeOf(TGuid));

  if Flags and ACE_INHERITED_OBJECT_TYPE_PRESENT <> 0 then
    Inc(Offset, SizeOf(TGuid));

  Pointer(Result) := PByte(@VariablePart) + Offset;
end;

{ TAclSizeInformation }

function TAclSizeInformation.AclBytesInUseByAces;
begin
  if AclBytesInUse < SizeOf(TAcl) then
    Result := 0
  else
  {$Q-}
    Result := AclBytesInUse - SizeOf(TAcl);
  {$IFDEF Q+}{$Q+}{$ENDIF}
end;

function TAclSizeInformation.AclBytesTotal;
begin
  Result := AclBytesInUse + AclBytesFree;
end;

{ Conversion functions }

function TimeoutToLargeInteger;
begin
  if Timeout = NT_INFINITE then
    Result := nil
  else
    Result := PLargeInteger(@Timeout);
end;

function SecurityReadAccess;
const
  REQUIRE_READ_CONTROL = OWNER_SECURITY_INFORMATION or
    GROUP_SECURITY_INFORMATION or DACL_SECURITY_INFORMATION or
    LABEL_SECURITY_INFORMATION or ATTRIBUTE_SECURITY_INFORMATION or
    SCOPE_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION;

  REQUIRE_SYSTEM_SECURITY = SACL_SECURITY_INFORMATION or
    BACKUP_SECURITY_INFORMATION;
begin
  Result := 0;

  if Info and REQUIRE_READ_CONTROL <> 0 then
    Result := Result or READ_CONTROL;

  if Info and REQUIRE_SYSTEM_SECURITY <> 0 then
    Result := Result or ACCESS_SYSTEM_SECURITY;
end;

function SecurityWriteAccess;
const
  REQUIRE_WRITE_DAC = DACL_SECURITY_INFORMATION or
    ATTRIBUTE_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION or
    PROTECTED_DACL_SECURITY_INFORMATION or UNPROTECTED_DACL_SECURITY_INFORMATION;

  REQUIRE_WRITE_OWNER = OWNER_SECURITY_INFORMATION or GROUP_SECURITY_INFORMATION
    or LABEL_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION;

  REQUIRE_SYSTEM_SECURITY = SACL_SECURITY_INFORMATION or
    SCOPE_SECURITY_INFORMATION or BACKUP_SECURITY_INFORMATION or
    PROTECTED_SACL_SECURITY_INFORMATION or UNPROTECTED_SACL_SECURITY_INFORMATION;
begin
  Result := 0;

  if Info and REQUIRE_WRITE_DAC <> 0 then
    Result := Result or WRITE_DAC;

  if Info and REQUIRE_WRITE_OWNER <> 0 then
    Result := Result or WRITE_OWNER;

  if Info and REQUIRE_SYSTEM_SECURITY <> 0 then
    Result := Result or ACCESS_SYSTEM_SECURITY;
end;

end.
