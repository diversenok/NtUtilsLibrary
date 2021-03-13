unit Winapi.WinNt;

{$MINENUMSIZE 4}

interface

uses
  DelphiApi.Reflection;

// Note: line numbers are valid for SDK 10.0.18362

const
  kernelbase = 'kernelbase.dll';
  kernel32 = 'kernel32.dll';
  advapi32 = 'advapi32.dll';

  MAX_HANDLE = $FFFFFF;
  MAX_UINT = $FFFFFFFF;

  NT_INFINITE = $8000000000000000; // maximum possible relative timeout
  MILLISEC = -10000; // 100ns in 1 ms in relative time

  // 1 shl PTR_SHIFT = SizeOf(Pointer)
  PTR_SHIFT = {$IFDEF Win64}3{$ELSE}2{$ENDIF};

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
  GENERIC_RIGHTS_ALL = GENERIC_READ or GENERIC_WRITE or GENERIC_EXECUTE or
    GENERIC_ALL;

  // 9069
  SID_MAX_SUB_AUTHORITIES = 15;
  SECURITY_MAX_SID_SIZE = 8 + SID_MAX_SUB_AUTHORITIES * SizeOf(Cardinal);
  SECURITY_MAX_SID_STRING_CHARACTERS = 2 + 4 + 15 +
    (11 * SID_MAX_SUB_AUTHORITIES) + 1;

  // 9749
  ACL_REVISION = 2;

  MAX_ACL_SIZE = High(Word) and not (SizeOf(Cardinal) - 1);

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

  // 10185 + ntifs.858
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
  // If range checks are enabled, make sure to wrap all accesses to any-size
  // arrays into a {$R-}/{$R+} block which temporarily disables them.
  ANYSIZE_ARRAY = 0..0;
  TAnysizeArray<T> = array [ANYSIZE_ARRAY] of T;

  TWin32Error = type Cardinal;

  // 839, for absolute times
  TLargeInteger = type Int64;
  PLargeInteger = ^TLargeInteger;
  TUnixTime = type Cardinal;

  // 859, for relative times
  TULargeInteger = type UInt64;
  PULargeInteger = ^TULargeInteger;

  // 892
  [Hex] TLuid = type UInt64;
  PLuid = ^TLuid;

  TProcessId = type NativeUInt;
  TThreadId = type NativeUInt;
  TProcessId32 = type Cardinal;
  TThreadId32 = type Cardinal;

  TLogonId = type TLuid;
  TSessionId = type Cardinal;

  PEnvironment = type PWideChar;

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
  TContextFlags = type Cardinal;

  // 3886
  {$ALIGN 16}
  [Hex]
  TContext64 = record
    PnHome: array [1..6] of UInt64;
    ContextFlags: TContextFlags;
    MxCsr: Cardinal;
    SegCs: WORD;
    SegDs: WORD;
    SegEs: WORD;
    SegFs: WORD;
    SegGs: WORD;
    SegSs: WORD;
    EFlags: TEFlags;
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
    ContextFlags: TContextFlags;
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
    EFlags: TEFlags;
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

  // 8926
  [FriendlyName('object'), ValidMask($FFFFFFFF)]
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

  // 8985
  TGenericMapping = record
    GenericRead: TAccessMask;
    GenericWrite: TAccessMask;
    GenericExecute: TAccessMask;
    GenericAll: TAccessMask;
  end;
  PGenericMapping = ^TGenericMapping;

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

  // 9104
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

  [FlagName(OBJECT_INHERIT_ACE, 'Object Inherit')]
  [FlagName(CONTAINER_INHERIT_ACE, 'Container Inherit')]
  [FlagName(NO_PROPAGATE_INHERIT_ACE, 'No Propagate Inherit')]
  [FlagName(INHERIT_ONLY_ACE, 'Inherit-only')]
  [FlagName(INHERITED_ACE, 'Inherited')]
  [FlagName(CRITICAL_ACE_FLAG, 'Critical')]
  [FlagName(SUCCESSFUL_ACCESS_ACE_FLAG, 'Successful Access / Trust-protected Filter')]
  [FlagName(FAILED_ACCESS_ACE_FLAG, 'Falied Access')]
  TAceFlags = type Byte;

  // 9792
  TAceHeader = record
    AceType: TAceType;
    AceFlags: TAceFlags;
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
  [NamingStyle(nsCamelCase, 'Acl'), Range(1)]
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

  // 10283
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

  // 10637
  [NamingStyle(nsCamelCase, 'Security')]
  TSecurityImpersonationLevel = (
    SecurityAnonymous = 0,
    SecurityIdentification = 1,
    SecurityImpersonation = 2,
    SecurityDelegation = 3
  );

  // 11260
  TSecurityQualityOfService = record
    [Bytes, Unlisted] Length: Cardinal;
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
    [Bytes] ReadTransferCount: UInt64;
    [Bytes] WriteTransferCount: UInt64;
    [Bytes] OtherTransferCount: UInt64;
  end;
  PIoCounters = ^TIoCounters;

  // 12576
  [NamingStyle(nsSnakeCase, 'PF'), Range(0, 35)]
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
    TimeDateStamp: TUnixTime;
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
  [NamingStyle(nsSnakeCase, 'IMAGE_DIRECTORY_ENTRY'), Range(0, 14)]
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
    TimeDateStamp: TUnixTime;
    MajorVersion: Word;
    MinorVersion: Word;
    Name: Cardinal;
    [Hex] Base: Cardinal;
    NumberOfFunctions: Cardinal;
    NumberOfNames: Cardinal;
    [Hex] AddressOfFunctions: Cardinal;     // RVA from base of image
    [Hex] AddressOfNames: Cardinal;         // RVA from base of image
    [Hex] AddressOfNameOrdinals: Cardinal;  // RVA from base of image
  end;
  PImageExportDirectory = ^TImageExportDirectory;

  // 18001
  TImageImportByName = record
    Hint: Word;
    Name: TAnysizeArray<AnsiChar>;
  end;
  PImageImportByName = ^TImageImportByName;

  // 18104
  TImageImportDescriptor = record
    [Hex] OriginalFirstThunk: Cardinal;
    TimeDateStamp: TUnixTime;
    [Hex] ForwarderChain: Cardinal;
    [Hex] Name: Cardinal;
    [Hex] FirstThunk: Cardinal;
  end;
  PImageImportDescriptor = ^TImageImportDescriptor;

  // 18137
  TImageDelayLoadDescriptor = record
    [Hex] Attributes: Cardinal;
    [Hex] DllNameRVA: Cardinal;
    [Hex] ModuleHandleRVA: Cardinal;
    [Hex] ImportAddressTableRVA: Cardinal;
    [Hex] ImportNameTableRVA: Cardinal;
    [Hex] BoundImportAddressTableRVA: Cardinal;
    [Hex] UnloadInformationTableRVA: Cardinal;
    TimeDateStamp: TUnixTime;
  end;
  PImageDelayLoadDescriptor = ^TImageDelayLoadDescriptor;

  // ntapi.ntdef
  KSystemTime = packed record
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
  [NamingStyle(nsCamelCase, 'NtProduct'), Range(1)]
  TNtProductType = (
    NtProductUnknown = 0,
    NtProductWinNT = 1,
    NtProductLanManNT = 2,
    NtProductServer = 3
  );

  // ntddk.8222
  [NamingStyle(nsSnakeCase, 'SYSTEM_CALL')]
  TSystemCall = (
    SYSTEM_CALL_SYSCALL = 0,
    SYSTEM_CALL_INT_2E = 1
  );

  TNtSystemRoot = array [0..259] of WideChar;
  TProcessorFeatures = array [TProcessorFeature] of Boolean;

  // ntddk.8264
  KUSER_SHARED_DATA = packed record
    TickCountLowDeprecated: Cardinal;
    [Hex] TickCountMultiplier: Cardinal;
    [volatile] InterruptTime: KSystemTime;
    [volatile] SystemTime: KSystemTime;
    [volatile] TimeZoneBias: KSystemTime;
    [Hex] ImageNumberLow: Word;
    [Hex] ImageNumberHigh: Word;
    NtSystemRoot: TNtSystemRoot;
    MaxStackTraceDepth: Cardinal;
    CryptoExponent: Cardinal;
    TimeZoneID: Cardinal;
    [Bytes] LargePageMinimum: Cardinal;
    AitSamplingValue: Cardinal;
    [Hex] AppCompatFlag: Cardinal;
    RNGSeedVersion: Int64;
    GlobalValidationRunlevel: Cardinal;
    TimeZoneBiasStamp: Integer;
    NtBuildNumber: Cardinal;
    NtProductType: TNtProductType;
    ProductTypeIsValid: Boolean;
    [Unlisted] Reserved0: array [0..0] of Byte;
    [Hex] NativeProcessorArchitecture: Word;
    NtMajorVersion: Cardinal;
    NtMinorVersion: Cardinal;
    ProcessorFeatures: TProcessorFeatures;
    [Unlisted] Reserved1: Cardinal;
    [Unlisted] Reserved3: Cardinal;
    [volatile] TimeSlip: Cardinal;
    AlternativeArchitecture: Cardinal;
    BootID: Cardinal;
    SystemExpirationDate: TLargeInteger;
    [Hex] SuiteMask: Cardinal;
    KdDebuggerEnabled: Boolean;
    [Hex] MitigationPolicies: Byte;
    CyclesPerYield: Word;
    [volatile] ActiveConsoleId: TSessionId;
    [volatile] DismountCount: Cardinal;
    [BooleanKind(bkEnabledDisabled)] ComPlusPackage: LongBool;
    LastSystemRITEventTickCount: Cardinal;
    NumberOfPhysicalPages: Cardinal;
    [BooleanKind(bkYesNo)] SafeBootMode: Boolean;
    [Hex] VirtualizationFlags: Byte;
    [Unlisted] Reserved12: array [0..1] of Byte;
    [Hex] SharedDataFlags: Cardinal; // SHARED_GLOBAL_FLAGS_*
    [Unlisted] DataFlagsPad: array [0..0] of Cardinal;
    TestRetInstruction: Int64;
    QpcFrequency: Int64;
    SystemCall: TSystemCall;
    [Unlisted] SystemCallPad0: Cardinal;
    [Unlisted] SystemCallPad: array [0..1] of Int64;
    [volatile] TickCount: KSystemTime;
    [Unlisted] TickCountPad: array [0..0] of Cardinal;
    [Hex] Cookie: Cardinal;
    [Unlisted] CookiePad: array [0..0] of Cardinal;
    [volatile] ConsoleSessionForegroundProcessID: TProcessId;
    {$IFDEF Win32}[Unlisted] Padding: Cardinal;{$ENDIF}
    TimeUpdateLock: Int64;
    [volatile] BaselineSystemTimeQpc: TULargeInteger;
    [volatile] BaselineInterruptTimeQpc: TULargeInteger;
    [Hex] QpcSystemTimeIncrement: UInt64;
    [Hex] QpcInterruptTimeIncrement: UInt64;
    QpcSystemTimeIncrementShift: Byte;
    QpcInterruptTimeIncrementShift: Byte;
    UnparkedProcessorCount: Word;
    EnclaveFeatureMask: array [0..3] of Cardinal;
    TelemetryCoverageRound: Cardinal;
    UserModeGlobalLogger: array [0..15] of Word;
    [Hex] ImageFileExecutionOptions: Cardinal;
    LangGenerationCount: Cardinal;
    [Unlisted] Reserved4: Int64;
    [volatile] InterruptTimeBias: TULargeInteger;
    [volatile] QpcBias: TULargeInteger;
    ActiveProcessorCount: Cardinal;
    [volatile] ActiveGroupCount: Byte;
    [Unlisted] Reserved9: Byte;
    QpcData: Word;
    TimeZoneBiasEffectiveStart: TLargeInteger;
    TimeZoneBiasEffectiveEnd: TLargeInteger;
  end;
  PKUSER_SHARED_DATA = ^KUSER_SHARED_DATA;

const
  USER_SHARED_DATA = PKUSER_SHARED_DATA($7ffe0000);

  // 9156
  SECURITY_NULL_SID_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 0));
  SECURITY_WORLD_SID_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 1));
  SECURITY_LOCAL_SID_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 2));
  SECURITY_CREATOR_SID_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 3));
  SECURITY_NON_UNIQUE_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 4));

  // 9164
  SECURITY_NULL_RID = $00000000;         // NULL SID      S-1-0-0
  SECURITY_WORLD_RID = $00000000;        // Everyone      S-1-1-0
  SECURITY_LOCAL_RID = $00000000;        // LOCAL         S-1-2-0
  SECURITY_LOCAL_LOGON_RID  = $00000001; // CONSOLE LOGON S-1-2-1

  // 9175
  SECURITY_CREATOR_OWNER_RID = $00000000;        // CREATOR OWNER        S-1-3-0
  SECURITY_CREATOR_GROUP_RID = $00000001;        // CREATOR GROUP        S-1-3-1
  SECURITY_CREATOR_OWNER_SERVER_RID = $00000002; // CREATOR OWNER SERVER S-1-3-2
  SECURITY_CREATOR_GROUP_SERVER_RID = $00000003; // CREATOR GROUP SERVER S-1-3-3
  SECURITY_CREATOR_OWNER_RIGHTS_RID = $00000004; // OWNER RIGHTS         S-1-3-4

  // 9224
  SECURITY_NT_AUTHORITY_ID = 5;
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 5));

  // 9226
  SECURITY_LOGON_IDS_RID = $00000005;       // S-1-5-5-X-X
  SECURITY_LOGON_IDS_RID_COUNT = 3;
  SECURITY_ANONYMOUS_LOGON_RID = $00000007; // S-1-5-7
  SECURITY_RESTRICTED_CODE_RID = $0000000C; // S-1-5-12
  SECURITY_IUSER_RID           = $00000011; // S-1-5-17
  SECURITY_LOCAL_SYSTEM_RID    = $00000012; // S-1-5-18
  SECURITY_LOCAL_SERVICE_RID   = $00000013; // S-1-5-19
  SECURITY_NETWORK_SERVICE_RID = $00000014; // S-1-5-20
  SECURITY_NT_NON_UNIQUE = $00000015;       // S-1-5-21-X-X-X
  SECURITY_NT_NON_UNIQUE_SUB_AUTH_COUNT = 3;
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;  // S-1-5-32
  SECURITY_WRITE_RESTRICTED_CODE_RID = $00000021; // S-1-5-33

  // 9267
  SECURITY_MIN_BASE_RID = $050; // S-1-5-80
  SECURITY_MAX_BASE_RID = $06F; // S-1-5-111

  // 9331
  SECURITY_INSTALLER_GROUP_CAPABILITY_BASE = $00000020; // Same as BUILTIN
  SECURITY_INSTALLER_GROUP_CAPABILITY_RID_COUNT = 9; // S-1-5-32-[+8 from hash]

  // 9360
  DOMAIN_USER_RID_ADMIN = $000001F4;
  DOMAIN_USER_RID_GUEST = $000001F5;
  DOMAIN_USER_RID_KRBTGT = $000001F6;
  DOMAIN_USER_RID_DEFAULT_ACCOUNT = $000001F7;
  DOMAIN_USER_RID_WDAG_ACCOUNT = $000001F8;

  DOMAIN_GROUP_RID_ADMINS = $00000200;
  DOMAIN_GROUP_RID_USERS = $00000201;
  DOMAIN_GROUP_RID_GUESTS = $00000202;

  DOMAIN_ALIAS_RID_ADMINS = $00000220;
  DOMAIN_ALIAS_RID_USERS = $00000221;
  DOMAIN_ALIAS_RID_GUESTS = $00000222;
  DOMAIN_ALIAS_RID_POWER_USERS = $00000223;

  // 9431
  SECURITY_APP_PACKAGE_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 15));

  SECURITY_CAPABILITY_BASE_RID = $00000003;
  SECURITY_CAPABILITY_APP_RID = $00000400;
  SECURITY_INSTALLER_CAPABILITY_RID_COUNT = 10; // S-1-15-3-1024-[+8 from hash]

  SECURITY_APP_PACKAGE_BASE_RID = $00000002;
  SECURITY_BUILTIN_APP_PACKAGE_RID_COUNT = 2;

  SECURITY_APP_PACKAGE_RID_COUNT = 8;
  SECURITY_PARENT_PACKAGE_RID_COUNT = SECURITY_APP_PACKAGE_RID_COUNT;
  SECURITY_CHILD_PACKAGE_RID_COUNT = 12;

  SECURITY_BUILTIN_PACKAGE_ANY_PACKAGE = $00000001;            // S-1-15-2-1
  SECURITY_BUILTIN_PACKAGE_ANY_RESTRICTED_PACKAGE = $00000002; // S-1-15-2-2

  // 9473
  SECURITY_MANDATORY_LABEL_AUTHORITY_ID = 16;
  SECURITY_MANDATORY_LABEL_AUTHORITY: TSIDIdentifierAuthority =
    (Value: (0, 0, 0, 0, 0, 16));

  // 9473, S-1-16-X
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
  IUSER_LUID = $3e3;

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

  MILLISEC_PER_DAY = 86400000;

  DAYS_FROM_1601 = 109205; // difference with Delphi's zero time in days
  NATIVE_TIME_DAY = 864000000000; // 100ns in 1 day
  NATIVE_TIME_HOUR = 36000000000; // 100ns in 1 hour
  NATIVE_TIME_MINUTE = 600000000; // 100ns in 1 minute
  NATIVE_TIME_SECOND =  10000000; // 100ns in 1 sec
  NATIVE_TIME_MILLISEC =   10000; // 100ns in 1 millisec

  INFINITE_FUTURE = TLargeInteger(-1);

function TimeoutToLargeInteger(var Timeout: Int64): PLargeInteger; inline;
function DateTimeToLargeInteger(DateTime: TDateTime): TLargeInteger;
function LargeIntegerToDateTime(QuadPart: TLargeInteger): TDateTime;

// Expected access masks when accessing security
function SecurityReadAccess(Info: TSecurityInformation): TAccessMask;
function SecurityWriteAccess(Info: TSecurityInformation): TAccessMask;

implementation

{ TSidIdentifierAuthority }

procedure TSidIdentifierAuthority.FromInt64;
begin
  Value[0] := Byte(IntValue shr 40);
  Value[1] := Byte(IntValue shr 32);
  Value[2] := Byte(IntValue shr 24);
  Value[3] := Byte(IntValue shr 16);
  Value[4] := Byte(IntValue shr 8);
  Value[5] := Byte(IntValue shr 0);
end;

function TSidIdentifierAuthority.ToInt64;
begin
  Result := (Int64(Value[5]) shl  0) or
            (Int64(Value[4]) shl  8) or
            (Int64(Value[3]) shl 16) or
            (Int64(Value[2]) shl 24) or
            (Int64(Value[1]) shl 32) or
            (Int64(Value[0]) shl 40);
end;

{ TAce_Internal }

function TAce_Internal.Sid;
begin
  Result := PSid(@Self.SidStart);
end;

{ TObjectAce_Internal }

function TObjectAce_Internal.Sid;
begin
  Result := PSid(@Self.SidStart);
end;

{ TAclSizeInformation }

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

function DateTimeToLargeInteger;
begin
  Result := Trunc(NATIVE_TIME_DAY * (DAYS_FROM_1601 + DateTime))
    + USER_SHARED_DATA.TimeZoneBias.QuadPart;
end;

function LargeIntegerToDateTime;
begin
  {$Q-}Result := (QuadPart - USER_SHARED_DATA.TimeZoneBias.QuadPart) /
    NATIVE_TIME_DAY - DAYS_FROM_1601;{$Q+}
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
