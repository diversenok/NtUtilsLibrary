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
    ContextToken: TUmgrContext;
    SessionId: TSessionId;
    [Unlisted] Reserved: Cardinal;
  end;
  PSessionUserContext = ^TSessionUserContext;

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

// private
[MinOSVersion(OsWin10TH1)]
procedure UMgrFreeSessionUsers(
  [in, ArrayParam] SessionUsers: PSessionUserContext
); stdcall; external usermgrcli delayed;

var delayed_UMgrFreeSessionUsers: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrFreeSessionUsers';
);

// private
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrEnumerateSessionUsers(
  [out, NumberOfElements] out Count: Cardinal;
  [out, ArrayParam, ReleaseWith('UMgrFreeSessionUsers')] out SessionUsers:
    PSessionUserContext
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrEnumerateSessionUsers: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrEnumerateSessionUsers';
);

// private
[MinOSVersion(OsWin10TH1)]
function UMgrQueryUserContext(
  [in, Access(TOKEN_QUERY)] hToken: THandle;
  [out] out UserContext: TUmgrContext
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserContext: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserContext';
);

// private
[MinOSVersion(OsWin10TH1)]
function UMgrQueryUserContextFromSid(
  [in] UserSid: PWideChar;
  [out] out UserContext: TUmgrContext
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserContextFromSid: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserContextFromSid';
);

// private
[MinOSVersion(OsWin10TH1)]
function UMgrQueryUserContextFromName(
  [in] UserName: PWideChar;
  [out] out UserContext: TUmgrContext
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserContextFromName: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserContextFromName';
);

{ Tokens }

// private
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrQueryDefaultAccountToken(
  [out, ReleaseWith('NtClose')] out hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryDefaultAccountToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryDefaultAccountToken';
);

// private
[MinOSVersion(OsWin10TH1)]
function UMgrQuerySessionUserToken(
  [in] SessionId: TSessionId;
  [out, ReleaseWith('NtClose')] out hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQuerySessionUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQuerySessionUserToken';
);

// private
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrQueryUserToken(
  [in] UserContext: TUmgrContext;
  [out, ReleaseWith('NtClose')] out hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserToken';
);

// private
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrQueryUserTokenFromSid(
  [in] UserSid: PWideChar;
  [out, ReleaseWith('NtClose')] out hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserTokenFromSid: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserTokenFromSid';
);

// private
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrQueryUserTokenFromName(
  [in] UserName: PWideChar;
  [out, ReleaseWith('NtClose')] out hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrQueryUserTokenFromName: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrQueryUserTokenFromName';
);

// private
[MinOSVersion(OsWin10TH1)]
function UMgrGetConstrainedUserToken(
  [in, opt] CallerToken: THandle;
  [in] UserContext: TUmgrContext;
  [in, opt] SecurityCapabilities: PSecurityCapabilities;
  [out, ReleaseWith('NtClose'), MayReturnNil] out hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrGetConstrainedUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrGetConstrainedUserToken';
);

// private
[MinOSVersion(OsWin10TH2)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrChangeSessionUserToken(
  [in] hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrChangeSessionUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrChangeSessionUserToken';
);

// private
[MinOSVersion(OsWin10TH2)]
[RequiredPrivilege(SE_IMPERSONATE_PRIVILEGE, rpAlways)]
function UMgrGetImpersonationTokenForContext(
  [in, Access(TOKEN_QUERY or TOKEN_IMPERSONATE)] CallerToken: THandle;
  [in] UserContext: TUmgrContext;
  [out, ReleaseWith('NtClose')] out hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrGetImpersonationTokenForContext: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrGetImpersonationTokenForContext';
);

// private
[MinOSVersion(OsWin10RS1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpForExtendedFunctionality)]
function UMgrGetSessionActiveShellUserToken(
  [in] SessionId: TSessionId;
  [out, ReleaseWith('NtClose')] out hToken: THandle
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrGetSessionActiveShellUserToken: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrGetSessionActiveShellUserToken';
);

{ Credentials }

// private
[MinOSVersion(OsWin10TH1)]
function UMgrFreeUserCredentials(
  [in] Credential: PCredProvCredential
): HResult; stdcall; external usermgrcli delayed;

var delayed_UMgrFreeUserCredentials: TDelayedLoadFunction = (
  Dll: @delayed_usermgrcli;
  FunctionName: 'UMgrFreeUserCredentials';
);

// private
[MinOSVersion(OsWin10TH1)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function UMgrGetCachedCredentials(
  [in] UserSid: PSid;
  [out, ReleaseWith('UMgrFreeUserCredentials')] out CredentialsCache:
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
