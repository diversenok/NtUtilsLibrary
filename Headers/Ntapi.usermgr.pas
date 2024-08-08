unit Ntapi.usermgr;

{
  This module provides definitions for User Manager service API.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.ProcessThreadsApi, Ntapi.Versions,
  DelphiApi.DelayLoad, DelphiApi.Reflection;

const
  usermgrcli = 'usermgrcli.dll';

var
  delayed_usermgrcli: TDelayedLoadDll = (DllName: usermgrcli);

type
  // private
  [SDKName('SESSION_USER_CONTEXT')]
  TSessionUserContext = record
    ContextToken: TLuid;
    SessionId: Cardinal;
    [Unlisted] Reserved: Cardinal;
  end;
  PSessionUserContext = ^TSessionUserContext;

  TSessionUserContextArray = TAnysizeArray<TSessionUserContext>;
  PSessionUserContextArray = ^TSessionUserContextArray;

  // private
  [SDKName('CRED_PROV_CREDENTIAL')]
  TCredProvCredential = record
    [Hex] Flags: Cardinal;
    AuthenticationPackage: Cardinal;
    [Counter(ctBytes)] Size: Cardinal;
    Information: Pointer;
  end;
  PCredProvCredential = ^TCredProvCredential;

{ Contexts }

// rev
[MinOSVersion(OsWin10TH1)]
procedure UMgrFreeSessionUsers(
  [in] Buffer: PSessionUserContextArray
); stdcall; external usermgrcli delayed;

var delayed_UMgrFreeSessionUsers: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrFreeSessionUsers';
);

// rev
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrEnumerateSessionUsers(
  [out, NumberOfElements] out Count: Cardinal;
  [out, ReleaseWith('UMgrFreeSessionUsers')] out Contexts:
    PSessionUserContextArray
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrEnumerateSessionUsers: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrEnumerateSessionUsers';
);

// rev
[MinOSVersion(OsWin10TH1)]
function UMgrQueryUserContext(
  [in, Access(TOKEN_QUERY)] TokenHandle: THandle;
  [out] out ContextToken: TLuid
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserContext: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserContext';
);

// rev
[MinOSVersion(OsWin10TH1)]
function UMgrQueryUserContextFromSid(
  [in] SidString: PWideChar;
  [out] out ContextToken: TLuid
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserContextFromSid: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserContextFromSid';
);

// rev
[MinOSVersion(OsWin10TH1)]
function UMgrQueryUserContextFromName(
  [in] UserName: PWideChar;
  [out] out ContextToken: TLuid
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserContextFromName: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserContextFromName';
);

{ Tokens }

// rev
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrQueryDefaultAccountToken(
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryDefaultAccountToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryDefaultAccountToken';
);

// rev
[MinOSVersion(OsWin10TH1)]
function UMgrQuerySessionUserToken(
  [in] SessionId: TSessionId;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQuerySessionUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQuerySessionUserToken';
);

// rev
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrQueryUserToken(
  [in] Context: TLuid;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserToken';
);

// rev
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrQueryUserTokenFromSid(
  [in] SidString: PWideChar;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserTokenFromSid: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserTokenFromSid';
);

// rev
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrQueryUserTokenFromName(
  [in] UserName: PWideChar;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserTokenFromName: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserTokenFromName';
);

// rev
[MinOSVersion(OsWin10TH1)]
function UMgrGetConstrainedUserToken(
  [in, opt] InputTokenHandle: THandle;
  [in] Context: TLuid;
  [in, opt] Capabilities: PSecurityCapabilities;
  [out, ReleaseWith('NtClose'), MayReturnNil] out OutputTokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrGetConstrainedUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrGetConstrainedUserToken';
);

// rev
[MinOSVersion(OsWin10TH2)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrChangeSessionUserToken(
  [in] TokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrChangeSessionUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrChangeSessionUserToken';
);

// rev
[MinOSVersion(OsWin10TH2)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
function UMgrGetImpersonationTokenForContext(
  [in, Access(TOKEN_QUERY or TOKEN_IMPERSONATE)] InputTokenHandle: THandle;
  [in] Context: TLuid;
  [out, ReleaseWith('NtClose')] out OutputTokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrGetImpersonationTokenForContext: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrGetImpersonationTokenForContext';
);

// rev
[MinOSVersion(OsWin10RS1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrGetSessionActiveShellUserToken(
  [in] SessionId: TSessionId;
  [out, ReleaseWith('NtClose')] out TokenHandle: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrGetSessionActiveShellUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrGetSessionActiveShellUserToken';
);

{ Credentials }

// rev
[MinOSVersion(OsWin10TH1)]
function UMgrFreeUserCredentials(
  [in] Buffer: PCredProvCredential
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrFreeUserCredentials: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrFreeUserCredentials';
);

// rev
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrGetCachedCredentials(
  [in] Sid: PSid;
  [out, ReleaseWith('UMgrFreeUserCredentials')] out Credentials:
    PCredProvCredential
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrGetCachedCredentials: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrGetCachedCredentials';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
