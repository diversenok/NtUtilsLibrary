unit Ntapi.WinSafer;

{
  This file defines Win Safer API functions for restricting access tokens.
  See SDK::winsafer.h for sources.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, DelphiApi.Reflection;

const
  SAFER_LEVEL_OPEN = 1;

  SAFER_TOKEN_NULL_IF_EQUAL = $00000001;
  SAFER_TOKEN_COMPARE_ONLY = $00000002;
  SAFER_TOKEN_MAKE_INERT = $00000004;
  SAFER_TOKEN_WANT_FLAGS = $00000008;

type
  TSaferHandle = NativeUInt;

  [NamingStyle(nsSnakeCase, 'SAFER_SCOPEID'), Range(1)]
  TSaferScopeId = (
    SAFER_SCOPEID_RESERVED = 0,
    SAFER_SCOPEID_MACHINE = 1,
    SAFER_SCOPEID_USER = 2
  );

  [NamingStyle(nsSnakeCase, 'SAFER_LEVELID')]
  TSaferLevelId = (
    SAFER_LEVELID_FULLYTRUSTED = $40000,
    SAFER_LEVELID_NORMALUSER = $20000,
    SAFER_LEVELID_CONSTRAINED = $10000,
    SAFER_LEVELID_UNTRUSTED = $01000,
    SAFER_LEVELID_DISALLOWED = $00000
  );

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

[SetsLastError]
function SaferCreateLevel(
  [in] ScopeId: TSaferScopeId;
  [in] LevelId: TSaferLevelId;
  [in] OpenFlags: TSaferCreateOptions;
  [out, ReleaseWith('SaferCloseLevel')] out LevelHandle: TSaferHandle;
  [Reserved] Reserved: Pointer = nil
): LongBool; stdcall; external advapi32;

function SaferCloseLevel(
  [in] hLevelHandle: TSaferHandle
): LongBool; stdcall; external advapi32;

[SetsLastError]
function SaferComputeTokenFromLevel(
  [in] LevelHandle: TSaferHandle;
  [in, opt] InAccessToken: THandle;
  [in, ReleaseWith('NtClose')] out OutAccessToken: THandle;
  [in] Flags: TSaferComputeOptions;
  [Reserved] Reserved: PCardinal = nil
): LongBool; stdcall; external advapi32;

[SetsLastError]
function SaferGetLevelInformation(
  [in] LevelHandle: TSaferHandle;
  [in] InfoType: TSaferObjectInfoClass;
  [out, WritesTo] QueryBuffer: Pointer;
  [in, NumberOfBytes] InBufferSize: Cardinal;
  [out, NumberOfBytes] out OutBufferSize: Cardinal
): LongBool; stdcall; external advapi32;

[SetsLastError]
function SaferSetLevelInformation(
  [in] LevelHandle: TSaferHandle;
  [in] InfoType: TSaferObjectInfoClass;
  [in, ReadsFrom] QueryBuffer: Pointer;
  [in, NumberOfBytes] InBufferSize: Cardinal
): LongBool; stdcall; external advapi32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
