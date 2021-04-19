unit Winapi.WinSafer;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

const
  // 62
  SAFER_LEVEL_OPEN = 1;

  // 77
  SAFER_TOKEN_NULL_IF_EQUAL = $00000001;
  SAFER_TOKEN_COMPARE_ONLY = $00000002;
  SAFER_TOKEN_MAKE_INERT = $00000004;
  SAFER_TOKEN_WANT_FLAGS = $00000008;

type
  TSaferHandle = NativeUInt;

  // 44
  [NamingStyle(nsSnakeCase, 'SAFER_SCOPEID'), Range(1)]
  TSaferScopeId = (
    SAFER_SCOPEID_RESERVED = 0,
    SAFER_SCOPEID_MACHINE = 1,
    SAFER_SCOPEID_USER = 2
  );

  // 52
  [NamingStyle(nsSnakeCase, 'SAFER_LEVELID')]
  TSaferLevelId = (
    SAFER_LEVELID_FULLYTRUSTED = $40000,
    SAFER_LEVELID_NORMALUSER = $20000,
    SAFER_LEVELID_CONSTRAINED = $10000,
    SAFER_LEVELID_UNTRUSTED = $01000,
    SAFER_LEVELID_DISALLOWED = $00000
  );

  // 390
  [NamingStyle(nsCamelCase, 'SaferObject'), Range(1)]
  TSaferObjectInfoClass = (
    SaferObjectReserved = 0,
    SaferObjectLevelID = 1,      // q: TSaferLevelId
    SaferObjectScopeID = 2,      // q: TSaferScopeId
    SaferObjectFriendlyName = 3, // q, s: PWideChar
    SaferObjectDescription = 4,  // q, s: PWideChar
    SaferObjectBuiltin = 5,      // q: LongBool

    SaferObjectDisallowed = 6,              // q: LongBool
    SaferObjectDisableMaxPrivilege = 7,     // q: LongBool
    SaferObjectInvertDeletedPrivileges = 8, // q: LongBool
    SaferObjectDeletedPrivileges = 9,       // q: TTokenPrivileges
    SaferObjectDefaultOwner = 10,           // q: TTokenOwner
    SaferObjectSidsToDisable = 11,          // q: TTokenGroups
    SaferObjectRestrictedSidsInverted = 12, // q: TTokenGroups
    SaferObjectRestrictedSidsAdded = 13,    // q: TTokenGroups

    SaferObjectAllIdentificationGuids = 14, // q:
    SaferObjectSingleIdentification = 15,   // q, s:

    SaferObjectExtendedError = 16           // q: TWin32Error
  );

  [FlagName(SAFER_LEVEL_OPEN, 'Open')]
  TSaferCreateOptions = type Cardinal;

  [FlagName(SAFER_TOKEN_NULL_IF_EQUAL, 'Null If Equal')]
  [FlagName(SAFER_TOKEN_COMPARE_ONLY, 'Compare Only')]
  [FlagName(SAFER_TOKEN_MAKE_INERT, 'Make Sandbox Inert')]
  [FlagName(SAFER_TOKEN_WANT_FLAGS, 'Want Flags')]
  TSaferComputeOptions = type Cardinal;

// 649
function SaferCreateLevel(
  ScopeId: TSaferScopeId;
  LevelId: TSaferLevelId;
  OpenFlags: TSaferCreateOptions;
  [allocates] out LevelHandle: TSaferHandle;
  [Reserved] Reserved: Pointer = nil
): LongBool; stdcall; external advapi32;

// 659
function SaferCloseLevel(
  hLevelHandle: TSaferHandle
): LongBool; stdcall; external advapi32;

// 674
function SaferComputeTokenFromLevel(
  LevelHandle: TSaferHandle;
  [opt] InAccessToken: THandle;
  out OutAccessToken: THandle;
  Flags: TSaferComputeOptions;
  [Reserved] Reserved: PCardinal = nil
): LongBool; stdcall; external advapi32;

// 684
function SaferGetLevelInformation(
  LevelHandle: TSaferHandle;
  InfoType: TSaferObjectInfoClass;
  [out, opt] QueryBuffer: Pointer;
  InBufferSize: Cardinal;
  out OutBufferSize: Cardinal
): LongBool; stdcall; external advapi32;

// 694
function SaferSetLevelInformation(
  LevelHandle: TSaferHandle;
  InfoType: TSaferObjectInfoClass;
  [in] QueryBuffer: Pointer;
  InBufferSize: Cardinal
): LongBool; stdcall; external advapi32;

implementation

end.
