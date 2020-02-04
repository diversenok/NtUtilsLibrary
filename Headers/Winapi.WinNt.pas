unit Winapi.WinNt;

{$MINENUMSIZE 4}

interface

uses
  DelphiApi.Reflection;

// Note: line numbers are valid for SDK 10.0.18362

type
  // If range checks are enabled make sure to wrap all accesses to any-size
  // arrays inside a {$R-}/{$R+} block which temporarily disables them.
  ANYSIZE_ARRAY = 0..0;

  TFlagName = record
    Value: Cardinal;
    Name: String;
  end;

  TFlagNameRef = record
    Value: Cardinal;
    Name: PWideChar;
  end;

  TFlagNameRefs = array [ANYSIZE_ARRAY] of TFlagNameRef;
  PFlagNameRefs = ^TFlagNameRefs;

  // 8926
  [Hex] TAccessMask = type Cardinal;

  TAccessMaskType = record
    TypeName: PWideChar;
    FullAccess: TAccessMask;
    Count: Integer;
    Mapping: PFlagNameRefs;
  end;
  PAccessMaskType = ^TAccessMaskType;

const
  kernelbase = 'kernelbase.dll';
  kernel32 = 'kernel32.dll';
  advapi32 = 'advapi32.dll';

  MAX_HANDLE = $FFFFFF;

  NT_INFINITE = $8000000000000000; // maximum possible relative timeout
  MILLISEC = -10000; // 100ns in 1 ms in relative time

  // 7526
  CONTEXT_i386 = $00010000;

  CONTEXT_CONTROL = CONTEXT_i386 or $00000001;  // SS:SP, CS:IP, FLAGS, BP
  CONTEXT_INTEGER = CONTEXT_i386 or $00000002;  // AX, BX, CX, DX, SI, DI
  CONTEXT_SEGMENTS = CONTEXT_i386 or $00000004; // DS, ES, FS, GS
  CONTEXT_FLOATING_POINT = CONTEXT_i386 or $00000008;     // 387 state
  CONTEXT_DEBUG_REGISTERS = CONTEXT_i386 or $00000010;    // DB 0-3,6,7
  CONTEXT_EXTENDED_REGISTERS = CONTEXT_i386 or $00000020; // cpu specific extensions

  CONTEXT_FULL = CONTEXT_CONTROL or CONTEXT_INTEGER or CONTEXT_SEGMENTS;
  CONTEXT_ALL = CONTEXT_FULL or CONTEXT_FLOATING_POINT or
    CONTEXT_DEBUG_REGISTERS or CONTEXT_EXTENDED_REGISTERS;

  CONTEXT_XSTATE = CONTEXT_i386 or $00000040;

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

  // 8943
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

  NonSpecificAccessMapping: array [0..10] of TFlagName = (
    (Value: READ_CONTROL;           Name: 'Read permissions'),
    (Value: WRITE_DAC;              Name: 'Write permissions'),
    (Value: WRITE_OWNER;            Name: 'Write owner'),
    (Value: SYNCHRONIZE;            Name: 'Synchronize'),
    (Value: _DELETE;                Name: 'Delete'),
    (Value: ACCESS_SYSTEM_SECURITY; Name: 'System security'),
    (Value: MAXIMUM_ALLOWED;        Name: 'Maximum allowed'),
    (Value: GENERIC_READ;           Name: 'Generic read'),
    (Value: GENERIC_WRITE;          Name: 'Generic write'),
    (Value: GENERIC_EXECUTE;        Name: 'Generic execute'),
    (Value: GENERIC_ALL;            Name: 'Generic all')
  );

  NonSpecificAccessType: TAccessMaskType = (
    TypeName: 'object';
    FullAccess: $FFFFFFFF;
    Count: Length(NonSpecificAccessMapping);
    Mapping: PFlagNameRefs(@NonSpecificAccessMapping);
  );

  // 9069
  SID_MAX_SUB_AUTHORITIES = 15;
  SECURITY_MAX_SID_SIZE = 8 + SID_MAX_SUB_AUTHORITIES * SizeOf(Cardinal);
  SECURITY_MAX_SID_STRING_CHARACTERS = 2 + 4 + 15 +
    (11 * SID_MAX_SUB_AUTHORITIES) + 1;

  SECURITY_ANONYMOUS_LOGON_RID = $00000007;
  SECURITY_LOCAL_SYSTEM_RID    = $00000012;
  SECURITY_LOCAL_SERVICE_RID   = $00000013;
  SECURITY_NETWORK_SERVICE_RID = $00000014;

  // S-1-5-32-[+8 from hash]
  SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT = 9;

  // S-1-15-3-1024-[+8 from hash]
  SECURITY_INSTALLER_CAPABILITY_RID_COUNT = 10;

  SECURITY_APP_PACKAGE_RID_COUNT = 8;
  SECURITY_PARENT_PACKAGE_RID_COUNT = SECURITY_APP_PACKAGE_RID_COUNT;
  SECURITY_CHILD_PACKAGE_RID_COUNT = 12;

  // 9473
  SECURITY_MANDATORY_UNTRUSTED_RID = $0000;
  SECURITY_MANDATORY_LOW_RID = $1000;
  SECURITY_MANDATORY_MEDIUM_RID = $2000;
  SECURITY_MANDATORY_MEDIUM_PLUS_RID = SECURITY_MANDATORY_MEDIUM_RID + $0100;
  SECURITY_MANDATORY_HIGH_RID = $3000;
  SECURITY_MANDATORY_SYSTEM_RID = $4000;
  SECURITY_MANDATORY_PROTECTED_PROCESS_RID = $5000;

  // 9671
  SYSTEM_LUID = $3e7;
  ANONYMOUS_LOGON_LUID = $3e6;
  LOCALSERVICE_LUID = $3e5;
  NETWORKSERVICE_LUID = $3e4;

  // 9690
  SE_GROUP_MANDATORY = $00000001;
  SE_GROUP_ENABLED_BY_DEFAULT = $00000002;
  SE_GROUP_ENABLED = $00000004;
  SE_GROUP_OWNER = $00000008;
  SE_GROUP_USE_FOR_DENY_ONLY = $00000010;
  SE_GROUP_INTEGRITY = $00000020;
  SE_GROUP_INTEGRITY_ENABLED = $00000040;
  SE_GROUP_RESOURCE = $20000000;
  SE_GROUP_LOGON_ID = $C0000000;

  // 9749
  ACL_REVISION = 2;

  // rev
  MAX_ACL_SIZE = $FFFC;

  // 9846
  OBJECT_INHERIT_ACE = $1;
  CONTAINER_INHERIT_ACE = $2;
  NO_PROPAGATE_INHERIT_ACE = $4;
  INHERIT_ONLY_ACE = $8;
  INHERITED_ACE = $10;
  CRITICAL_ACE_FLAG = $20;               // for access allowed ace
  SUCCESSFUL_ACCESS_ACE_FLAG = $40;      // for audit and alarm aces
  FAILED_ACCESS_ACE_FLAG = $80;          // for audit and alarm aces
  TRUST_PROTECTED_FILTER_ACE_FLAG = $40; // for access filter ace

  // 9993
  SYSTEM_MANDATORY_LABEL_NO_WRITE_UP = $1;
  SYSTEM_MANDATORY_LABEL_NO_READ_UP = $2;
  SYSTEM_MANDATORY_LABEL_NO_EXECUTE_UP = $4;

  // 10174
  SECURITY_DESCRIPTOR_REVISION = 1;

  // 10398
  SE_PRIVILEGE_ENABLED_BY_DEFAULT = $00000001;
  SE_PRIVILEGE_ENABLED = $00000002;
  SE_PRIVILEGE_REMOVED = $00000004;
  SE_PRIVILEGE_USED_FOR_ACCESS = Cardinal($80000000);

  // 10887
  TOKEN_MANDATORY_POLICY_OFF = $0;
  TOKEN_MANDATORY_POLICY_NO_WRITE_UP = $1;
  TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN = $2;
  TOKEN_MANDATORY_POLICY_VALID_MASK = TOKEN_MANDATORY_POLICY_NO_WRITE_UP or
    TOKEN_MANDATORY_POLICY_NEW_PROCESS_MIN;

  // ntifs.15977
  TOKEN_WRITE_RESTRICTED = $0008;
  TOKEN_IS_RESTRICTED = $0010;
  TOKEN_SESSION_NOT_REFERENCED = $0020;
  TOKEN_SANDBOX_INERT = $0040;
  TOKEN_VIRTUALIZE_ALLOWED = $0200;
  TOKEN_VIRTUALIZE_ENABLED = $0400;
  TOKEN_IS_FILTERED = $0800;
  TOKEN_UIACCESS = $1000;
  TOKEN_NOT_LOW = $2000;
  TOKEN_LOWBOX = $4000;
  TOKEN_HAS_OWN_CLAIM_ATTRIBUTES = $8000;
  TOKEN_PRIVATE_NAMESPACE = $10000;
  TOKEN_DO_NOT_USE_GLOBAL_ATTRIBS_FOR_QUERY = $20000;
  TOKEN_NO_CHILD_PROCESS = $80000;
  TOKEN_NO_CHILD_PROCESS_UNLESS_SECURE = $100000;
  TOKEN_AUDIT_NO_CHILD_PROCESS = $200000;

  // 11004
  CLAIM_SECURITY_ATTRIBUTE_TYPE_INVALID = $00;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_INT64 = $01;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_UINT64 = $02;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_STRING = $03;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_FQBN = $04;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_SID = $05;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_BOOLEAN = $06;
  CLAIM_SECURITY_ATTRIBUTE_TYPE_OCTET_STRING = $10;

  // 11049
  CLAIM_SECURITY_ATTRIBUTE_NON_INHERITABLE = $0001;
  CLAIM_SECURITY_ATTRIBUTE_VALUE_CASE_SENSITIVE = $0002;
  CLAIM_SECURITY_ATTRIBUTE_USE_FOR_DENY_ONLY = $0004;
  CLAIM_SECURITY_ATTRIBUTE_DISABLED_BY_DEFAULT = $0008;
  CLAIM_SECURITY_ATTRIBUTE_DISABLED = $0010;
  CLAIM_SECURITY_ATTRIBUTE_MANDATORY = $0020;
  CLAIM_SECURITY_ATTRIBUTE_CUSTOM_FLAGS = $FFFF0000;

  // 11286
  OWNER_SECURITY_INFORMATION = $00000001; // q: RC; s: WO
  GROUP_SECURITY_INFORMATION = $00000002; // q: RC; s: WO
  DACL_SECURITY_INFORMATION = $00000004;  // q: RC; s: WD
  SACL_SECURITY_INFORMATION = $00000008;  // q, s: AS
  LABEL_SECURITY_INFORMATION = $00000010; // q: RC; s: WO
  ATTRIBUTE_SECURITY_INFORMATION = $00000020; // q: RC; s: WD
  SCOPE_SECURITY_INFORMATION = $00000040; // q: RC; s: AS
  PROCESS_TRUST_LABEL_SECURITY_INFORMATION = $00000080;
  ACCESS_FILTER_SECURITY_INFORMATION = $00000100;
  BACKUP_SECURITY_INFORMATION = $00010000; // q, s: RC | AS; s: WD | WO | AS

  PROTECTED_DACL_SECURITY_INFORMATION = $80000000;   // s: WD
  PROTECTED_SACL_SECURITY_INFORMATION = $40000000;   // s: AS
  UNPROTECTED_DACL_SECURITY_INFORMATION = $20000000; // s: WD
  UNPROTECTED_SACL_SECURITY_INFORMATION = $10000000; // s: AS

  // 16664
  IMAGE_DOS_SIGNATURE = $5A4D; // MZ

  // 16829
  IMAGE_FILE_MACHINE_I386 = $014c;
  IMAGE_FILE_MACHINE_AMD64 = $8664;

  // 16968
  IMAGE_NT_OPTIONAL_HDR32_MAGIC = $10b;
  IMAGE_NT_OPTIONAL_HDR64_MAGIC = $20b;

  // 17120
  IMAGE_SIZEOF_SHORT_NAME = 8;

  // 21273
  DLL_PROCESS_DETACH = 0;
  DLL_PROCESS_ATTACH = 1;
  DLL_THREAD_ATTACH = 2;
  DLL_THREAD_DETACH = 3;

type
  // 839
  TLargeInteger = type Int64;
  PLargeInteger = ^TLargeInteger;

  // 859
  TULargeInteger = UInt64;
  PULargeInteger = ^TULargeInteger;

  // 892
  [Hex] TLuid = type UInt64;
  PLuid = ^TLuid;

  TLuidArray = array [ANYSIZE_ARRAY] of TLuid;
  PLuidArray = ^TLuidArray;

  // 1138
  PListEntry = ^TListEntry;
  TListEntry = record
    Flink: PListEntry;
    Blink: PListEntry;
  end;

  // 2578
  {$ALIGN 16}
  M128A = record
    Low: UInt64;
    High: Int64;
  end;
  {$ALIGN 8}

  // 3886
  {$ALIGN 16}
  [Hex]
  TContext64 = record
    PnHome: array [1..6] of UInt64;
    ContextFlags: Cardinal; // CONTEXT_*
    MxCsr: Cardinal;
    SegCs: WORD;
    SegDs: WORD;
    SegEs: WORD;
    SegFs: WORD;
    SegGs: WORD;
    SegSs: WORD;
    EFlags: Cardinal;
    Dr0: UInt64;
    Dr1: UInt64;
    Dr2: UInt64;
    Dr3: UInt64;
    Dr6: UInt64;
    Dr7: UInt64;
    Rax: UInt64;
    Rcx: UInt64;
    Rdx: UInt64;
    Rbx: UInt64;
    Rsp: UInt64;
    Rbp: UInt64;
    Rsi: UInt64;
    Rdi: UInt64;
    R8: UInt64;
    R9: UInt64;
    R10: UInt64;
    R11: UInt64;
    R12: UInt64;
    R13: UInt64;
    R14: UInt64;
    R15: UInt64;
    Rip: UInt64;
    FloatingPointState: array [0..31] of M128A;
    VectorRegister: array [0..25] of M128A;
    VectorControl: UInt64;
    DebugControl: UInt64;
    LastBranchToRip: UInt64;
    LastBranchFromRip: UInt64;
    LastExceptionToRip: UInt64;
    LastExceptionFromRip: UInt64;
    property Ax: UInt64 read Rax write Rax;
    property Cx: UInt64 read Rcx write Rcx;
    property Dx: UInt64 read Rdx write Rdx;
    property Bx: UInt64 read Rbx write Rbx;
    property Sp: UInt64 read Rsp write Rsp;
    property Bp: UInt64 read Rbp write Rbp;
    property Si: UInt64 read Rsi write Rsi;
    property Di: UInt64 read Rdi write Rdi;
    property Ip: UInt64 read Rip write Rip;
  end;
  PContext64 = ^TContext64;
  {$ALIGN 8}

  // 7556
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

  // 7597
  [Hex]
  TContext32 = record
  const
    MAXIMUM_SUPPORTED_EXTENSION = 512;
  var
    ContextFlags: Cardinal; // CONTEXT_*
    Dr0: Cardinal;
    Dr1: Cardinal;
    Dr2: Cardinal;
    Dr3: Cardinal;
    Dr6: Cardinal;
    Dr7: Cardinal;
    FloatSave: TFloatingSaveArea;
    SegGs: Cardinal;
    SegFs: Cardinal;
    SegEs: Cardinal;
    SegDs: Cardinal;
    Edi: Cardinal;
    Esi: Cardinal;
    Ebx: Cardinal;
    Edx: Cardinal;
    Ecx: Cardinal;
    Eax: Cardinal;
    Ebp: Cardinal;
    Eip: Cardinal;
    SegCs: Cardinal;
    EFlags: Cardinal;
    Esp: Cardinal;
    SegSs: Cardinal;
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
  end;
  PContext32 = ^TContext32;

  {$IFDEF WIN64}
  TContext = TContext64;
  {$ELSE}
  TContext = TContext32;
  {$ENDIF}
  PContext = ^TContext;

  // 8824
  PExceptionRecord = ^TExceptionRecord;
  TExceptionRecord = record
  const
    EXCEPTION_MAXIMUM_PARAMETERS = 15;
  var
    [Hex] ExceptionCode: Cardinal;
    [Hex] ExceptionFlags: Cardinal;
    ExceptionRecord: PExceptionRecord;
    ExceptionAddress: Pointer;
    NumberParameters: Cardinal;
    ExceptionInformation: array [0 .. EXCEPTION_MAXIMUM_PARAMETERS - 1] of
      NativeUInt;
  end;

  // 8985
  TGenericMapping = record
    GenericRead: TAccessMask;
    GenericWrite: TAccessMask;
    GenericExecute: TAccessMask;
    GenericAll: TAccessMask;
  end;
  PGenericMapping = ^TGenericMapping;

  // 9006
  TLuidAndAttributes = packed record
    Luid: TLuid;
    [Hex] Attributes: Cardinal;
  end;
  PLuidAndAttributes = ^TLuidAndAttributes;

  TPrivilege = TLuidAndAttributes;
  PPrivilege = PLuidAndAttributes;

  // 9048
  TSidIdentifierAuthority = record
    Value: array [0..5] of Byte;
    function ToInt64: Int64;
    procedure FromInt64(IntValue: Int64);
  end;
  PSidIdentifierAuthority = ^TSidIdentifierAuthority;

  // 9056
  TSid_Internal = record
   Revision: Byte;
   SubAuthorityCount: Byte;
   IdentifierAuthority: TSidIdentifierAuthority;
   SubAuthority: array [0 .. SID_MAX_SUB_AUTHORITIES - 1] of Cardinal;
  end;
  PSid = ^TSid_Internal;

  TSidArray = array [ANYSIZE_ARRAY] of PSid;
  PSidArray = ^TSidArray;

  // 9104
  [NamingStyle(nsCamelCase, 'SidType'), MinValue(1)]
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

  // 9118
  TSidAndAttributes = record
    Sid: PSid;
    [Hex] Attributes: Cardinal;
  end;
  PSidAndAttributes = ^TSidAndAttributes;

  // 9133
  TSIDAndAttributesHash = record
    const SID_HASH_SIZE = 32;
  var
    SidCount: Cardinal;
    SidAttr: PSIDAndAttributes;
    Hash: array [0 .. SID_HASH_SIZE - 1] of NativeUInt;
  end;
  PSIDAndAttributesHash = ^TSIDAndAttributesHash;

  // 9762
  TAcl_Internal = record
    AclRevision: Byte;
    Sbz1: Byte;
    AclSize: Word;
    AceCount: Word;
    Sbz2: Word;
  end;
  PAcl = ^TAcl_Internal;

  // 9805
  {$MINENUMSIZE 1}
  [NamingStyle(nsSnakeCase, '', 'ACE_TYPE')]
  TAceType = (
    ACCESS_ALLOWED_ACE_TYPE = 0,
    ACCESS_DENIED_ACE_TYPE = 1,
    SYSTEM_AUDIT_ACE_TYPE = 2,
    SYSTEM_ALARM_ACE_TYPE = 3,

    ACCESS_ALLOWED_COMPOUND_ACE_TYPE = 4, // Unknown

    ACCESS_ALLOWED_OBJECT_ACE_TYPE = 5, // Object ace
    ACCESS_DENIED_OBJECT_ACE_TYPE = 6,  // Object ace
    SYSTEM_AUDIT_OBJECT_ACE_TYPE = 7,   // Object ace
    SYSTEM_ALARM_OBJECT_ACE_TYPE = 8,   // Object ace

    ACCESS_ALLOWED_CALLBACK_ACE_TYPE = 9,
    ACCESS_DENIED_CALLBACK_ACE_TYPE = 10,

    ACCESS_ALLOWED_CALLBACK_OBJECT_ACE_TYPE = 11, // Object ace
    ACCESS_DENIED_CALLBACK_OBJECT_ACE_TYPE = 12,  // Object ace

    SYSTEM_AUDIT_CALLBACK_ACE_TYPE = 13,
    SYSTEM_ALARM_CALLBACK_ACE_TYPE = 14,

    SYSTEM_AUDIT_CALLBACK_OBJECT_ACE_TYPE = 15, // Object ace
    SYSTEM_ALARM_CALLBACK_OBJECT_ACE_TYPE = 16, // Object ace

    SYSTEM_MANDATORY_LABEL_ACE_TYPE = 17,
    SYSTEM_RESOURCE_ATTRIBUTE_ACE_TYPE = 18,
    SYSTEM_SCOPED_POLICY_ID_ACE_TYPE = 19,
    SYSTEM_PROCESS_TRUST_LABEL_ACE_TYPE = 20,
    SYSTEM_ACCESS_FILTER_ACE_TYPE = 21
  );
  {$MINENUMSIZE 4}

  TAceTypeSet = set of TAceType;

  // 9792
  TAceHeader = record
    AceType: TAceType;
    [Hex] AceFlags: Byte;
    [Bytes] AceSize: Word;
  end;
  PAceHeader = ^TAceHeader;

  // This structure covers:
  //  ACCESS_ALLOWED_ACE & ACCESS_DENIED_ACE
  //  SYSTEM_AUDIT_ACE & SYSTEM_ALARM_ACE
  //  SYSTEM_RESOURCE_ATTRIBUTE_ACE
  //  SYSTEM_SCOPED_POLICY_ID_ACE
  //  SYSTEM_MANDATORY_LABEL_ACE
  //  SYSTEM_PROCESS_TRUST_LABEL_ACE
  //  SYSTEM_ACCESS_FILTER_ACE
  //  ACCESS_ALLOWED_CALLBACK_ACE & ACCESS_DENIED_CALLBACK_ACE
  //  SYSTEM_AUDIT_CALLBACK_ACE & SYSTEM_ALARM_CALLBACK_ACE
  // i.e. everything except OBJECT ACEs.
  TAce_Internal = record
    Header: TAceHeader;
    Mask: TAccessMask;
  private
    SidStart: Cardinal;
  public
    function Sid: PSid;
  end;
  PAce = ^TAce_Internal;

  // This structure covers:
  //  ACCESS_ALLOWED_OBJECT_ACE & ACCESS_DENIED_OBJECT_ACE
  //  SYSTEM_AUDIT_OBJECT_ACE & SYSTEM_ALARM_OBJECT_ACE
  //  ACCESS_ALLOWED_CALLBACK_OBJECT_ACE & ACCESS_DENIED_CALLBACK_OBJECT_ACE
  //  SYSTEM_AUDIT_CALLBACK_OBJECT_ACE & SYSTEM_ALARM_CALLBACK_OBJECT_ACE
  TObjectAce_Internal = record
    Header: TAceHeader;
    Mask: TAccessMask;
    [Hex] Flags: Cardinal;
    ObjectType: TGuid;
    InheritedObjectType: TGuid;
  private
    SidStart: Cardinal;
  public
    function Sid: PSid;
  end;
  PObjectAce = ^TObjectAce_Internal;

  // 10132
  [NamingStyle(nsCamelCase, 'Acl'), MinValue(1)]
  TAclInformationClass = (
    AclReserved = 0,
    AclRevisionInformation = 1,
    AclSizeInformation = 2
  );

  // 10142
  TAclRevisionInformation = record
    AclRevision: Cardinal;
  end;
  PAclRevisionInformation = ^TAclRevisionInformation;

  // 10151
  TAclSizeInformation = record
    AceCount: Integer;
    [Bytes] AclBytesInUse: Cardinal;
    [Bytes] AclBytesFree: Cardinal;
    function AclBytesTotal: Cardinal;
  end;
  PAclSizeInformation = ^TAclSizeInformation;

  // 10183
  TSecurityDescriptorControl = Word;
  PSecurityDescriptorControl = ^TSecurityDescriptorControl;

  // 10283
  TSecurityDescriptor = record
    Revision: Byte;
    Sbz1: Byte;
    [Hex] Control: TSecurityDescriptorControl;
    Owner: PSid;
    Group: PSid;
    Sacl: PAcl;
    Dacl: PAcl;
  end;
  PSecurityDescriptor = ^TSecurityDescriptor;

  // 10424
  TPrivilegeSet = record
    PrivilegeCount: Cardinal;
    [Hex] Control: Cardinal;
    Privilege: array [ANYSIZE_ARRAY] of TLuidAndAttributes;
  end;
  PPrivilegeSet = ^TPrivilegeSet;

  // 10637
  [NamingStyle(nsCamelCase, 'Security')]
  TSecurityImpersonationLevel = (
    SecurityAnonymous = 0,
    SecurityIdentification = 1,
    SecurityImpersonation = 2,
    SecurityDelegation = 3
  );

  // 10729
  [NamingStyle(nsCamelCase, 'Token'), MinValue(1)]
  TTokenType = (
    TokenInvalid,
    TokenPrimary,
    TokenImpersonation
  );

  // 10731
  [NamingStyle(nsCamelCase, 'TokenElevation'), MinValue(1)]
  TTokenElevationType = (
    TokenElevationInvalid = 0,
    TokenElevationTypeDefault = 1,
    TokenElevationTypeFull = 2,
    TokenElevationTypeLimited = 3
  );

  // 10822
  TTokenGroups = record
    GroupCount: Integer;
    Groups: array [ANYSIZE_ARRAY] of TSIDAndAttributes;
  end;
  PTokenGroups = ^TTokenGroups;

  // 10831
  TTokenPrivileges = record
    PrivilegeCount: Integer;
    Privileges: array [ANYSIZE_ARRAY] of TLUIDAndAttributes;
  end;
  PTokenPrivileges = ^TTokenPrivileges;

  // 10837
  TTokenOwner = record
    Owner: PSid;
  end;
  PTokenOwner = ^TTokenOwner;

  // 10846
  TTokenPrimaryGroup = record
    PrimaryGroup: PSid;
  end;
  PTokenPrimaryGroup = ^TTokenPrimaryGroup;

  // 10850
  TTokenDefaultDacl = record
    DefaultDacl: PAcl;
  end;
  PTokenDefaultDacl = ^TTokenDefaultDacl;

  // 10862
  TTokenGroupsAndPrivileges = record
    SidCount: Cardinal;
    [Bytes] SidLength: Cardinal;
    Sids: PSidAndAttributes;
    RestrictedSidCount: Cardinal;
    [Bytes] RestrictedSidLength: Cardinal;
    RestrictedSids: PSidAndAttributes;
    PrivilegeCount: Cardinal;
    [Bytes] PrivilegeLength: Cardinal;
    Privileges: PLuidAndAttributes;
    AuthenticationId: TLuid;
  end;
  PTokenGroupsAndPrivileges = ^TTokenGroupsAndPrivileges;

  // 10904
  TTokenAccessInformation = record
    SidHash: PSIDAndAttributesHash;
    RestrictedSidHash: PSIDAndAttributesHash;
    Privileges: PTokenPrivileges;
    AuthenticationId: TLuid;
    TokenType: TTokenType;
    ImpersonationLevel: TSecurityImpersonationLevel;
    [Hex] MandatoryPolicy: Cardinal;
    [Hex] Flags: Cardinal;
    AppContainerNumber: Cardinal;
    PackageSid: PSid;
    CapabilitiesHash: PSIDAndAttributesHash;
    TrustLevelSid: PSid;
    SecurityAttributes: Pointer;
  end;
  PTokenAccessInformation = ^TTokenAccessInformation;

  // 10926
  TTokenAuditPolicy = record
    // The actual length depends on the count of SubCategories of auditing.
    // Each half of a byte is a set of Winapi.NtSecApi.PER_USER_AUDIT_* flags.
    PerUserPolicy: array [ANYSIZE_ARRAY] of Byte;
  end;
  PTokenAuditPolicy = ^TTokenAuditPolicy;

  // 10932
  TTokenSource = record
    const TOKEN_SOURCE_LENGTH = 8;
  var
    sourcename: array[1 .. TOKEN_SOURCE_LENGTH] of AnsiChar;
    SourceIdentifier: TLuid;
    procedure FromString(Name: String);
    function ToString: String;
  end;
  PTokenSource = ^TTokenSource;

  // 10938
  TTokenStatistics = record
    TokenId: TLuid;
    AuthenticationId: TLuid;
    ExpirationTime: TLargeInteger;
    TokenType: TTokenType;
    ImpersonationLevel: TSecurityImpersonationLevel;
    [Bytes] DynamicCharged: Cardinal;
    [Bytes] DynamicAvailable: Cardinal;
    GroupCount: Cardinal;
    PrivilegeCount: Cardinal;
    ModifiedId: TLuid;
  end;
  PTokenStatistics = ^TTokenStatistics;

  // 10975
  TTokenAppContainer = record
    TokenAppContainer: PSid;
  end;
  PTokenAppContainer = ^TTokenAppContainer;

  // 11105
  TClaimSecurityAttributeV1 = record
    Name: PWideChar;
    ValueType: Word;
    Reserved: Word;
    [Hex] Flags: Cardinal;
    ValueCount: Integer;
    Values: Pointer;
  end;
  PClaimSecurityAttributeV1 = ^TClaimSecurityAttributeV1;

  // 11224
  TClaimSecurityAttributes = record
    Version: Word;
    Reserved: Word;
    AttributeCount: Cardinal;
    Attribute: PClaimSecurityAttributeV1;
  end;
  PClaimSecurityAttributes = ^TClaimSecurityAttributes;

  // 11260
  TSecurityQualityOfService = record
    [Bytes] Length: Cardinal;
    ImpersonationLevel: TSecurityImpersonationLevel;
    ContextTrackingMode: Boolean;
    EffectiveOnly: Boolean;
  end;
  PSecurityQualityOfService = ^TSecurityQualityOfService;

  // 11284
  TSecurityInformation = Cardinal;
  PSecurityInformation = ^TSecurityInformation;

  // 11535
  TQuotaLimits = record
    [Bytes] PagedPoolLimit: NativeUInt;
    [Bytes] NonPagedPoolLimit: NativeUInt;
    [Bytes] MinimumWorkingSetSize: NativeUInt;
    [Bytes] MaximumWorkingSetSize: NativeUInt;
    [Bytes] PagefileLimit: NativeUInt;
    TimeLimit: TLargeInteger;
  end;
  PQuotaLimits = ^TQuotaLimits;

  // 11573
  TIoCounters = record
    ReadOperationCount: UInt64;
    WriteOperationCount: UInt64;
    OtherOperationCount: UInt64;
    ReadTransferCount: UInt64;
    WriteTransferCount: UInt64;
    OtherTransferCount: UInt64;
  end;
  PIoCounters = ^TIoCounters;

  // 12576
  [NamingStyle(nsSnakeCase, 'PF')]
  TProcessorFeature = (
    PF_FLOATING_POINT_PRECISION_ERRATA = 0,
    PF_FLOATING_POINT_EMULATED = 1,
    PF_COMPARE_EXCHANGE_DOUBLE = 2,
    PF_MMX_INSTRUCTIONS_AVAILABLE = 3,
    PF_PPC_MOVEMEM_64BIT_OK = 4,
    PF_ALPHA_BYTE_INSTRUCTIONS = 5,
    PF_XMMI_INSTRUCTIONS_AVAILABLE = 6,
    PF_3DNOW_INSTRUCTIONS_AVAILABLE = 7,
    PF_RDTSC_INSTRUCTION_AVAILABLE = 8,
    PF_PAE_ENABLED = 9,
    PF_XMMI64_INSTRUCTIONS_AVAILABLE = 10,
    PF_SSE_DAZ_MODE_AVAILABLE = 11,
    PF_NX_ENABLED = 12,
    PF_SSE3_INSTRUCTIONS_AVAILABLE = 13,
    PF_COMPARE_EXCHANGE128 = 14,
    PF_COMPARE64_EXCHANGE128 = 15,
    PF_CHANNELS_ENABLED = 16,
    PF_XSAVE_ENABLED = 17,
    PF_ARM_VFP_32_REGISTERS_AVAILABLE = 18,
    PF_ARM_NEON_INSTRUCTIONS_AVAILABLE = 19,
    PF_SECOND_LEVEL_ADDRESS_TRANSLATION = 20,
    PF_VIRT_FIRMWARE_ENABLED = 21,
    PF_RDWRFSGSBASE_AVAILABLE = 22,
    PF_FASTFAIL_AVAILABLE = 23,
    PF_ARM_DIVIDE_INSTRUCTION_AVAILABLE = 24,
    PF_ARM_64BIT_LOADSTORE_ATOMIC = 25,
    PF_ARM_EXTERNAL_CACHE_AVAILABLE = 26,
    PF_ARM_FMAC_INSTRUCTIONS_AVAILABLE = 27,
    PF_RDRAND_INSTRUCTION_AVAILABLE = 28,
    PF_ARM_V8_INSTRUCTIONS_AVAILABLE = 29,
    PF_ARM_V8_CRYPTO_INSTRUCTIONS_AVAILABLE = 30,
    PF_ARM_V8_CRC32_INSTRUCTIONS_AVAILABLE = 31,
    PF_RDTSCP_INSTRUCTION_AVAILABLE = 32,
    PF_RDPID_INSTRUCTION_AVAILABLE = 33,
    PF_ARM_V81_ATOMIC_INSTRUCTIONS_AVAILABLE = 34,
    PF_MONITORX_INSTRUCTION_AVAILABLE = 35,
    PF_RESERVED36, PF_RESERVED37, PF_RESERVED38, PF_RESERVED39, PF_RESERVED40,
    PF_RESERVED41, PF_RESERVED42, PF_RESERVED43, PF_RESERVED44, PF_RESERVED45,
    PF_RESERVED46, PF_RESERVED47, PF_RESERVED48, PF_RESERVED49, PF_RESERVED50,
    PF_RESERVED51, PF_RESERVED52, PF_RESERVED53, PF_RESERVED54, PF_RESERVED55,
    PF_RESERVED56, PF_RESERVED57, PF_RESERVED58, PF_RESERVED59, PF_RESERVED60,
    PF_RESERVED61, PF_RESERVED62, PF_RESERVED63
  );

  // 16682
  TImageDosHeader = record        // DOS .EXE header
    e_magic: Word;                // Magic number
    e_cblp: Word;                 // Bytes on last page of file
    e_cp: Word;                   // Pages in file
    e_crlc: Word;                 // Relocations
    e_cparhdr: Word;              // Size of header in paragraphs
    e_minalloc: Word;             // Minimum extra paragraphs needed
    e_maxalloc: Word;             // Maximum extra paragraphs needed
    e_ss: Word;                   // Initial (relative) SS value
    e_sp: Word;                   // Initial SP value
    e_csum: Word;                 // Checksum
    e_ip: Word;                   // Initial IP value
    e_cs: Word;                   // Initial (relative) CS value
    e_lfarlc: Word;               // File address of relocation table
    e_ovno: Word;                 // Overlay number
    e_res: array [0..3] of Word;  // Reserved words
    e_oemid: Word;                // OEM identifier (for e_oeminfo)
    e_oeminfo: Word;              //  information: OEM; e_oemid specific
    e_res2: array [0..9] of Word; // Reserved words
    e_lfanew: Cardinal;           // File address of new exe header
  end;
  PImageDosHeader = ^TImageDosHeader;

  // 16799
  TImageFileHeader = record
    [Hex] Machine: Word;
    NumberOfSections: Word;
    TimeDateStamp: Cardinal;
    [Hex] PointerToSymbolTable: Cardinal;
    NumberOfSymbols: Cardinal;
    [Hex, Bytes] SizeOfOptionalHeader: Word;
    [Hex] Characteristics: Word;
  end;
  PImageFileHeader = ^TImageFileHeader;

  // 16865
  TImageDataDirectory = record
    [Hex] VirtualAddress: Cardinal;
    [Hex, Bytes] Size: Cardinal;
  end;
  PImageDataDirectory = ^TImageDataDirectory;

  // 17017
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'IMAGE_SUBSYSTEM')]
  TImageSubsystem = (
    IMAGE_SUBSYSTEM_UNKNOWN = 0,
    IMAGE_SUBSYSTEM_NATIVE = 1,
    IMAGE_SUBSYSTEM_WINDOWS_GUI = 2,
    IMAGE_SUBSYSTEM_WINDOWS_CUI = 3
  );
  {$MINENUMSIZE 4}

  // 17053
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'IMAGE_DIRECTORY_ENTRY')]
  TImageDirectoryEntry = (
    IMAGE_DIRECTORY_ENTRY_EXPORT = 0,
    IMAGE_DIRECTORY_ENTRY_IMPORT = 1,
    IMAGE_DIRECTORY_ENTRY_RESOURCE = 2,
    IMAGE_DIRECTORY_ENTRY_EXCEPTION = 3,
    IMAGE_DIRECTORY_ENTRY_SECURITY = 4,
    IMAGE_DIRECTORY_ENTRY_BASERELOC = 5,
    IMAGE_DIRECTORY_ENTRY_DEBUG = 6,
    IMAGE_DIRECTORY_ENTRY_ARCHITECTURE = 7,
    IMAGE_DIRECTORY_ENTRY_GLOBALPTR = 8,
    IMAGE_DIRECTORY_ENTRY_TLS = 9,
    IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG = 10,
    IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT = 11,
    IMAGE_DIRECTORY_ENTRY_IAT = 12,
    IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT = 13,
    IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR = 14,
    IMAGE_DIRECTORY_ENTRY_RESERVED = 15
  );
  {$MINENUMSIZE 4}

  // 16876
  TImageOptionalHeader32 = record
    [Hex] Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    [Hex, Bytes] SizeOfCode: Cardinal;
    [Hex, Bytes] SizeOfInitializedData: Cardinal;
    [Hex, Bytes] SizeOfUninitializedData: Cardinal;
    [Hex] AddressOfEntryPoint: Cardinal;
    [Hex] BaseOfCode: Cardinal;
    [Hex] BaseOfData: Cardinal;
    [Hex] ImageBase: Cardinal;
    SectionAlignment: Cardinal;
    FileAlignment: Cardinal;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: Cardinal;
    [Hex, Bytes] SizeOfImage: Cardinal;
    [Hex, Bytes] SizeOfHeaders: Cardinal;
    [Hex] CheckSum: Cardinal;
    Subsystem: TImageSubsystem;
    [Hex] DllCharacteristics: Word;
    [Hex, Bytes] SizeOfStackReserve: Cardinal;
    [Hex, Bytes] SizeOfStackCommit: Cardinal;
    [Hex, Bytes] SizeOfHeapReserve: Cardinal;
    [Hex, Bytes] SizeOfHeapCommit: Cardinal;
    [Hex] LoaderFlags: Cardinal;
    NumberOfRvaAndSizes: Cardinal;
    DataDirectory: array [TImageDirectoryEntry] of TImageDataDirectory;
  end;
  PImageOptionalHeader32 = ^TImageOptionalHeader32;

  // 16935
  TImageOptionalHeader64 = record
    [Hex] Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    [Hex, Bytes] SizeOfCode: Cardinal;
    [Hex, Bytes] SizeOfInitializedData: Cardinal;
    [Hex, Bytes] SizeOfUninitializedData: Cardinal;
    [Hex] AddressOfEntryPoint: Cardinal;
    [Hex] BaseOfCode: Cardinal;
    [Hex] ImageBase: UInt64;
    SectionAlignment: Cardinal;
    FileAlignment: Cardinal;
    MajorOperatingSystemVersion: Word;
    MinorOperatingSystemVersion: Word;
    MajorImageVersion: Word;
    MinorImageVersion: Word;
    MajorSubsystemVersion: Word;
    MinorSubsystemVersion: Word;
    Win32VersionValue: Cardinal;
    [Hex, Bytes] SizeOfImage: Cardinal;
    [Hex, Bytes] SizeOfHeaders: Cardinal;
    [Hex] CheckSum: Cardinal;
    Subsystem: TImageSubsystem;
    [Hex] DllCharacteristics: Word;
    [Hex, Bytes] SizeOfStackReserve: UInt64;
    [Hex, Bytes] SizeOfStackCommit: UInt64;
    [Hex, Bytes] SizeOfHeapReserve: UInt64;
    [Hex, Bytes] SizeOfHeapCommit: UInt64;
    [Hex] LoaderFlags: Cardinal;
    NumberOfRvaAndSizes: Cardinal;
    DataDirectory: array [TImageDirectoryEntry] of TImageDataDirectory;
  end;
  PImageOptionalHeader64 = ^TImageOptionalHeader64;

  // Common part of 32- abd 64-bit structures
  TImageOptionalHeader = record
    [Hex] Magic: Word;
    MajorLinkerVersion: Byte;
    MinorLinkerVersion: Byte;
    [Hex, Bytes] SizeOfCode: Cardinal;
    [Bytes] SizeOfInitializedData: Cardinal;
    [Bytes] SizeOfUninitializedData: Cardinal;
    [Hex] AddressOfEntryPoint: Cardinal;
    [Hex] BaseOfCode: Cardinal;
  end;

  // 16982
  TImageNtHeaders = record
    [Hex] Signature: Cardinal;
    FileHeader: TImageFileHeader;
  case Word of
    0: (OptionalHeader: TImageOptionalHeader);
    IMAGE_NT_OPTIONAL_HDR32_MAGIC: (OptionalHeader32: TImageOptionalHeader32);
    IMAGE_NT_OPTIONAL_HDR64_MAGIC: (OptionalHeader64: TImageOptionalHeader64);
  end;
  PImageNtHeaders = ^TImageNtHeaders;

  TImageSectionName = array [0 .. IMAGE_SIZEOF_SHORT_NAME - 1] of AnsiChar;

  // 17122
  TImageSectionHeader = record
    Name: TImageSectionName;
    Misc: Cardinal;
    [Hex] VirtualAddress: Cardinal;
    [Bytes] SizeOfRawData: Cardinal;
    [Hex] PointerToRawData: Cardinal;
    [Hex] PointerToRelocations: Cardinal;
    [Hex] PointerToLinenumbers: Cardinal;
    NumberOfRelocations: Word;
    NumberOfLineNumbers: Word;
    [Hex] Characteristics: Cardinal;
  end;
  PImageSectionHeader = ^TImageSectionHeader;
  PPImageSectionHeader = ^PImageSectionHeader;

  // 17982
  TImageExportDirectory = record
    [Hex] Characteristics: Cardinal;
    TimeDateStamp: Cardinal;
    MajorVersion: Word;
    MinorVersion: Word;
    Name: Cardinal;
    [Hex] Base: Cardinal;
    NumberOfFunctions: Integer;
    NumberOfNames: Integer;
    [Hex] AddressOfFunctions: Cardinal;     // RVA from base of image
    [Hex] AddressOfNames: Cardinal;         // RVA from base of image
    [Hex] AddressOfNameOrdinals: Cardinal;  // RVA from base of image
  end;
  PImageExportDirectory = ^TImageExportDirectory;

  // ntapi.ntdef
  KSystemType = packed record
  case Boolean of
    True: (
     QuadPart: TLargeInteger
    );
    False: (
      LowPart: Cardinal;
      High1Time: Integer;
      High2Time: Integer;
    );
  end;

  // ntapi.ntdef
  [NamingStyle(nsCamelCase, 'NtProduct'), MinValue(1)]
  TNtProductType = (
    NtProductUnknown = 0,
    NtProductWinNt = 1,
    NtProductLanManNt = 2,
    NtProductServer = 3
  );

  TNtSystemRoot = array [0..259] of WideChar;
  TProcessorFeatures = array [TProcessorFeature] of Boolean;

  // ntapi.ntexapi
  KUSER_SHARED_DATA = packed record
    TickCountLowDeprecated: Cardinal;
    TickCountMultiplier: Cardinal;
    [volatile] InterruptTime: KSystemType;
    [volatile] SystemTime: KSystemType;
    [volatile] TimeZoneBias: KSystemType;
    [Hex] ImageNumberLow: Word;
    [Hex] ImageNumberHigh: Word;
    NtSystemRoot: TNtSystemRoot;
    MaxStackTraceDepth: Cardinal;
    CryptoExponent: Cardinal;
    TimeZoneId: Cardinal;
    LargePageMinimum: Cardinal;
    AitSamplingValue: Cardinal;
    [Hex] AppCompatFlag: Cardinal;
    RNGSeedVersion: Int64;
    GlobalValidationRunlevel: Cardinal;
    TimeZoneBiasStamp: Integer;
    NtBuildNumber: Cardinal;
    NtProductType: TNtProductType;
    ProductTypeIsValid: Boolean;
    Reserved0: array [0..0] of Byte;
    [Hex] NativeProcessorArchitecture: Word;
    NtMajorVersion: Cardinal;
    NtMinorVersion: Cardinal;
    ProcessorFeatures: TProcessorFeatures;
    Reserved1: Cardinal;
    Reserved3: Cardinal;
    [volatile] TimeSlip: Cardinal;
    AlternativeArchitecture: Cardinal;
    BootId: Cardinal;
    SystemExpirationDate: TLargeInteger;
    [Hex] SuiteMask: Cardinal;
    KdDebuggerEnabled: Boolean;
    [Hex] MitigationPolicies: Byte;
    CyclesPerYield: Word;
    [volatile] ActiveConsoleId: Cardinal;
    [volatile] DismountCount: Cardinal;
    ComPlusPackage: Cardinal;
    LastSystemRITEventTickCount: Cardinal;
    NumberOfPhysicalPages: Cardinal;
    SafeBootMode: Boolean;
    [Hex] VirtualizationFlags: Byte;
    Reserved12: array [0..1] of Byte;
    [Hex] SharedDataFlags: Cardinal;
    DataFlagsPad: array [0..0] of Cardinal;
    TestRetInstruction: Int64;
    QpcFrequency: Int64;
    SystemCall: Cardinal;
    SystemCallPad0: Cardinal;
    SystemCallPad: array [0..1] of Int64;
    [volatile] TickCount: KSystemType;
    TickCountPad: array [0..0] of Cardinal;
    [Hex] Cookie: Cardinal;
    CookiePad: array [0..0] of Cardinal;
    [volatile] ConsoleSessionForegroundProcessId: Int64;
    TimeUpdateLock: Int64;
    BaselineSystemTimeQpc: Int64;
    BaselineInterruptTimeQpc: Int64;
    QpcSystemTimeIncrement: Int64;
    QpcInterruptTimeIncrement: Int64;
    QpcSystemTimeIncrementShift: Byte;
    QpcInterruptTimeIncrementShift: Byte;
    UnparkedProcessorCount: Word;
    EnclaveFeatureMask: array [0..3] of Cardinal;
    TelemetryCoverageRound: Cardinal;
    UserModeGlobalLogger: array [0..15] of Word;
    [Hex] ImageFileExecutionOptions: Cardinal;
    LangGenerationCount: Cardinal;
    Reserved4: Int64;
    [volatile] InterruptTimeBias: UInt64;
    [volatile] QpcBias: UInt64;
    ActiveProcessorCount: Cardinal;
    [volatile] ActiveGroupCount: Byte;
    Reserved9: Byte;
    QpcData: Word;
    TimeZoneBiasEffectiveStart: TLargeInteger;
    TimeZoneBiasEffectiveEnd: TLargeInteger;
  end;
  PKUSER_SHARED_DATA = ^KUSER_SHARED_DATA;

const
  USER_SHARED_DATA = PKUSER_SHARED_DATA($7ffe0000);

  // 9224
  SECURITY_NT_AUTHORITY_ID = 5;
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 5));

  SECURITY_LOGON_IDS_RID = 5;
  SECURITY_LOGON_IDS_RID_COUNT = 3;

  // 9431
  SECURITY_APP_PACKAGE_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 15));

  // 9473
  SECURITY_MANDATORY_LABEL_AUTHORITY_ID = 16;
  SECURITY_MANDATORY_LABEL_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 16));

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

  DAYS_FROM_1601 = 109205; // difference with Delphi's zero time in days
  DAY_TO_NATIVE_TIME = 864000000000; // 100ns in 1 day

function PrivilegesToLuids(Privileges: TArray<TPrivilege>): TArray<TLuid>;
function TimeoutToLargeInteger(var Timeout: Int64): PLargeInteger; inline;
function DateTimeToLargeInteger(DateTime: TDateTime): TLargeInteger;
function LargeIntegerToDateTime(QuadPart: TLargeInteger): TDateTime;

implementation

{ TSidIdentifierAuthority }

procedure TSidIdentifierAuthority.FromInt64(IntValue: Int64);
begin
  Value[0] := Byte(IntValue shr 40);
  Value[1] := Byte(IntValue shr 32);
  Value[2] := Byte(IntValue shr 24);
  Value[3] := Byte(IntValue shr 16);
  Value[4] := Byte(IntValue shr 8);
  Value[5] := Byte(IntValue shr 0);
end;

function TSidIdentifierAuthority.ToInt64: Int64;
begin
  Result := (Int64(Value[5]) shl  0) or
            (Int64(Value[4]) shl  8) or
            (Int64(Value[3]) shl 16) or
            (Int64(Value[2]) shl 24) or
            (Int64(Value[1]) shl 32) or
            (Int64(Value[0]) shl 40);
end;

{ TAce_Internal }

function TAce_Internal.Sid: PSid;
begin
  Result := PSid(@Self.SidStart);
end;

{ TObjectAce_Internal }

function TObjectAce_Internal.Sid: PSid;
begin
  Result := PSid(@Self.SidStart);
end;

{ TAclSizeInformation }

function TAclSizeInformation.AclBytesTotal: Cardinal;
begin
  Result := AclBytesInUse + AclBytesFree;
end;

{ TTokenSource }

procedure TTokenSource.FromString(Name: String);
var
  i, Count: integer;
begin
  FillChar(sourcename, SizeOf(sourcename), 0);

  Count := Length(Name);
  if Count > 8 then
    Count := 8;

  for i := 1 to Count do
    sourcename[i] := AnsiChar(Name[Low(String) + i - 1]);
end;

function TTokenSource.ToString: String;
begin
  // sourcename field may or may not contain a zero-termination byte
  Result := String(PAnsiChar(AnsiString(sourcename)));
end;

{ Conversion functions }

function PrivilegesToLuids(Privileges: TArray<TPrivilege>): TArray<TLuid>;
var
  i: Integer;
begin
  SetLength(Result, Length(Privileges));

  for i := 0 to High(Privileges) do
    Result[i] := Privileges[i].Luid;
end;

function TimeoutToLargeInteger(var Timeout: Int64): PLargeInteger;
begin
  if Timeout = NT_INFINITE then
    Result := nil
  else
    Result := PLargeInteger(@Timeout);
end;

function DateTimeToLargeInteger(DateTime: TDateTime): TLargeInteger;
begin
  Result := Trunc(DAY_TO_NATIVE_TIME * (DAYS_FROM_1601 + DateTime))
    + USER_SHARED_DATA.TimeZoneBias.QuadPart;
end;

function LargeIntegerToDateTime(QuadPart: TLargeInteger): TDateTime;
begin
  Result := (QuadPart - USER_SHARED_DATA.TimeZoneBias.QuadPart) /
    DAY_TO_NATIVE_TIME - DAYS_FROM_1601;
end;

end.
