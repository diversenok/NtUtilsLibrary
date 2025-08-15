unit Ntapi.winsta;

{
  This module allows interacting with Terminal Service.
  See the [MS-TSTS] specification and PHNT::winsta.h for definitions.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.WinUser, Ntapi.ntseapi, Ntapi.Versions,
  DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  winsta = 'winsta.dll';
  winlogonext = 'winlogonext.dll';

var
  delayed_winsta: TDelayedLoadDll = (DllName: winsta);
  delayed_winlogonext: TDelayedLoadDll = (DllName: winlogonext);

const
  USERNAME_LENGTH = 20;
  DOMAIN_LENGTH = 17;

  WINSTATIONNAME_LENGTH = 32;

  LOGONID_CURRENT = Cardinal(-1); // use caller's session
  SERVERNAME_CURRENT = nil;       // connect locally
  SERVER_CURRENT = 0;             // a pseudo-handle for the local server

type
  TWinStaHandle = type THandle;

  TWinStationName = array [0..WINSTATIONNAME_LENGTH] of WideChar;
  TDomainName = array [0..DOMAIN_LENGTH] of WideChar;
  TUserName = array [0..USERNAME_LENGTH] of WideChar;

  [SDKName('WINSTATIONSTATECLASS')]
  [NamingStyle(nsCamelCase, 'State_')]
  TWinStationStateClass = (
    State_Active = 0,
    State_Connected = 1,
    State_ConnectQuery = 2,
    State_Shadow = 3,
    State_Disconnected = 4,
    State_Idle = 5,
    State_Listen = 6,
    State_Reset = 7,
    State_Down = 8,
    State_Init = 9
  );

  [SDKName('SESSIONIDW')]
  TSessionIdW = record
    SessionID: TSessionId;
    WinStationName: TWinStationName;
    State: TWinStationStateClass;
  end;
  PSessionIdW = ^TSessionIdW;

  TSessionIdArrayW = TAnysizeArray<TSessionIdW>;
  PSessionIdArrayW = ^TSessionIdArrayW;

  [SDKName('WINSTATIONINFOCLASS')]
  [NamingStyle(nsCamelCase, 'WinStation'), ValidValues([0..14, 16..41])]
  TWinStationInfoClass = (
    WinStationCreateData = 0,                // q:
    WinStationConfiguration = 1,             // q, s:
    WinStationPDParams = 2,                  // q, s:
    WinStationWD = 3,                        // q:
    WinStationPD = 4,                        // q:
    WinStationPrinter = 5,                   // q:
    WinStationClient = 6,                    // q:
    WinStationModules = 7,                   // q:
    WinStationInformation = 8,               //+q: TWinStationInformation
    WinStationTrace = 9,                     // s:
    WinStationBeep = 10,                     //-s: Cardinal, see MessageBeep
    WinStationEncryptionOff = 11,            // s:
    WinStationEncryptionPerm = 12,           // s:
    WinStationNTSecurity = 13,               //.s: < anything >
    WinStationUserToken = 14,                //+q: TWinStationUserToken
    [Reserved] WinStationUnused1 = 15,
    WinStationVideoData = 16,                // q:
    WinStationInitialProgram = 17,           // s:
    WinStationCD = 18,                       // q:
    WinStationSystemTrace = 19,              // s:
    WinStationVirtualData = 20,              // q:
    WinStationClientData = 21,               // s:
    WinStationSecureDesktopEnter = 22,       // s:
    WinStationSecureDesktopExit = 23,        // s:
    WinStationLoadBalanceSessionTarget = 24, // q:
    WinStationLoadIndicator = 25,            //+q: TWinStationLoadIndicatorData
    WinStationShadowInfo = 26,               //+q, s: TWinStationShadow
    WinStationDigProductID = 27,             // q:
    WinStationLockedState = 28,              //+q, s: LongBool
    WinStationRemoteAddress = 29,            // q:
    WinStationIdleTime = 30,                 //-q: Cardinal (in sec)
    WinStationLastReconnectType = 31,        //-q: TReconnectType
    WinStationDisallowAutoReconnect = 32,    //-q, s: Boolean
    WinStationMPRNotifyInfo = 33,
    WinStationExecSrvSystemPipe = 34,
    WinStationSmartCardAutoLogon = 35,
    WinStationIsAdminLoggedOn = 36,
    WinStationReconnectedFromId = 37,        //+q: Cardinal
    WinStationEffectsPolicy = 38,            // q:
    WinStationType = 39,                     // q:
    WinStationInformationEx = 40,            // q:
    WinStationValidationInfo = 41
  );

  [SDKName('SHADOWCLASS')]
  [NamingStyle(nsCamelCase, 'Shadow_')]
  TShadowClass = (
    Shadow_Disable,
    Shadow_EnableInputNotify,
    Shadow_EnableInputNoNotify,
    Shadow_EnableNoInputNotify,
    Shadow_EnableNoInputNoNotify
  );

  [SDKName('PROTOCOLCOUNTERS')]
  TProtocolCounters = record
    [Bytes] WDBytes: Cardinal;
    WDFrames: Cardinal;
    WaitForOutBuf: Cardinal;
    Frames: Cardinal;
    [Bytes] Bytes: Cardinal;
    [Bytes] CompressedBytes: Cardinal;
    CompressFlushes: Cardinal;
    Errors: Cardinal;
    Timeouts: Cardinal;
    AsyncFramingError: Cardinal;
    AsyncOverrunError: Cardinal;
    AsyncOverflowError: Cardinal;
    AsyncParityError: Cardinal;
    TDErrors: Cardinal;
    ProtocolType: Word;
    [Bytes] Length: Word;
    [Unlisted] Reserved: array [0..99] of Cardinal;
  end;

  [SDKName('CACHE_STATISTICS')]
  TCacheStatistics = record
    ProtocolType: Word;
    [Bytes] Length: Word;
    [Unlisted] Reserved: array [0..19] of Cardinal;
  end;

  [SDKName('PROTOCOLSTATUS')]
  TProtocolStatus = record
    Output: TProtocolCounters;
    Input: TProtocolCounters;
    Cache: TCacheStatistics;
    AsyncSignal: Cardinal;
    AsyncSignalMask: Cardinal;
  end;

  [SDKName('WINSTATIONINFORMATION')]
  TWinStationInformation = record
    ConnectState: TWinStationStateClass;
    WinStationName: TWinStationName;
    LogonID: TSessionId;
    ConnectTime: TLargeInteger;
    DisconnectTime: TLargeInteger;
    LastInputTime: TLargeInteger;
    LogonTime: TLargeInteger;
    Status: TProtocolStatus;
    Domain: TDomainName;
    UserName: TUserName;
    CurrentTime: TLargeInteger;
    function FullUserName: String;
  end;
  PWinStationInformation = ^TWinStationInformation;

  [SDKName('WINSTATIONUSERTOKEN')]
  TWinStationUserToken = record
    ClientID: TClientID;
    UserToken: THandle;
  end;
  PWinStationUserToken = ^TWinStationUserToken;

  [SDKName('LOADFACTORTYPE')]
  [NamingStyle(nsCamelCase)]
  TLoadFactorType = (
    ErrorConstraint = 0,
    PagedPoolConstraint = 1,
    NonPagedPoolConstraint = 2,
    AvailablePagesConstraint = 3,
    SystemPtesConstraint = 4,
    CPUConstraint = 5
  );

  [SDKName('WINSTATIONLOADINDICATORDATA')]
  TWinStationLoadIndicatorData = record
    RemainingSessionCapacity: Cardinal;
    LoadFactor: TLoadFactorType;
    TotalSessions: Cardinal;
    DisconnectedSessions: Cardinal;
    IdleCPU: TLargeInteger;
    TotalCPU: TLargeInteger;
    RawSessionCapacity: Cardinal;
    [Unlisted] Reserved: array [0..8] of Cardinal;
  end;
  PWinStationLoadIndicatorData = ^TWinStationLoadIndicatorData;

  [SDKName('SHADOWSTATECLASS')]
  [NamingStyle(nsCamelCase, 'State_')]
  TShadowStateClass = (
    State_NoShadow,
    State_Shadowing,
    State_Shadowed
  );

  [NamingStyle(nsSnakeCase, 'PROTOCOL')]
  TProtocolType = (
    PROTOCOL_CONSOLE = 0,
    PROTOCOL_OTHERS = 1,
    PROTOCOL_RDP = 2
  );

  [SDKName('WINSTATIONSHADOW')]
  TWinStationShadow = record
    ShadowState: TShadowStateClass;
    ShadowClass: TShadowClass;
    SessionID: TSessionId;
    ProtocolType: TProtocolType;
  end;
  PWinStationShadow = ^TWinStationShadow;

  [SDKName('RECONNECT_TYPE')]
  [NamingStyle(nsCamelCase)]
  TReconnectType = (
    NeverReconnected = 0,
    ManualReconnect = 1,
    AutoReconnect = 2
  );

function WinStationFreeMemory(
  [in] Buffer: Pointer
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationFreeMemory: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationFreeMemory';
);

[SetsLastError]
[Result:  ReleaseWith('WinStationCloseServer')]
function WinStationOpenServerW(
  [in] ServerName: PWideChar
): TWinStaHandle; stdcall; external winsta delayed;

var delayed_WinStationOpenServerW: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationOpenServerW';
);

[SetsLastError]
function WinStationCloseServer(
  [in] hServer: TWinStaHandle
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationCloseServer: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationCloseServer';
);

[SetsLastError]
function WinStationEnumerateW(
  [in, opt] ServerHandle: TWinStaHandle;
  [out, ReleaseWith('WinStationFreeMemory')] out SessionIds: PSessionIdArrayW;
  [out, NumberOfElements] out Count: Integer
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationEnumerateW: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationEnumerateW';
);

[SetsLastError]
function WinStationQueryInformationW(
  [in, opt] ServerHandle: TWinStaHandle;
  [in] SessionId: TSessionId;
  [in] WinStationInformationClass: TWinStationInfoClass;
  [out, WritesTo] WinStationInformation: Pointer;
  [in, NumberOfBytes] WinStationInformationLength: Cardinal;
  [out, NumberOfBytes] out ReturnLength: Cardinal
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationQueryInformationW: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationQueryInformationW';
);

[SetsLastError]
function WinStationSetInformationW(
  [in, opt] ServerHandle: TWinStaHandle;
  [in] SessionId: TSessionId;
  [in] WinStationInformationClass: TWinStationInfoClass;
  [in, ReadsFrom] WinStationInformation: Pointer;
  [in, NumberOfBytes] WinStationInformationLength: Cardinal
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationSetInformationW: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationSetInformationW';
);

[SetsLastError]
function WinStationSendMessageW(
  [in, opt] ServerHandle: TWinStaHandle;
  [in] SessionId: TSessionId;
  [in, ReadsFrom] Title: PWideChar;
  [in, NumberOfBytes] TitleLength: Cardinal;
  [in, ReadsFrom] MessageStr: PWideChar;
  [in, NumberOfBytes] MessageLength: Cardinal;
  [in] Style: TMessageStyle;
  [in] Timeout: Cardinal;
  [out] out Response: TMessageResponse;
  [in] DoNotWait: Boolean
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationSendMessageW: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationSendMessageW';
);

[SetsLastError]
function WinStationConnectW(
  [in, opt] ServerHandle: TWinStaHandle;
  [in] SessionId: TSessionId;
  [in] TargetSessionId: TSessionId;
  [in, opt] Password: PWideChar;
  [in] Wait: Boolean
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationConnectW: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationConnectW';
);

[SetsLastError]
function WinStationDisconnect(
  [in, opt] ServerHandle: TWinStaHandle;
  [in] SessionId: TSessionId;
  [in] Wait: Boolean
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationDisconnect: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationDisconnect';
);

[SetsLastError]
function WinStationShadow(
  [in, opt] ServerHandle: TWinStaHandle;
  [in] TargetServerName: PWideChar;
  [in] TargetSessionId: TSessionId;
  [in] HotKeyVk: Byte;
  [in] HotkeyModifiers: Word
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationShadow: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationShadow';
);

[SetsLastError]
function WinStationShadowStop(
  [in, opt] ServerHandle: TWinStaHandle;
  [in] SessionId: TSessionId;
  [in] Wait: Boolean
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationShadowStop: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationShadowStop';
);

// Windows 7 only
[SetsLastError]
function WinStationSwitchToServicesSession(
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationSwitchToServicesSession: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationSwitchToServicesSession';
);

// Windows 7 only
[SetsLastError]
function WinStationRevertFromServicesSession(
): Boolean; stdcall; external winsta delayed;

var delayed_WinStationRevertFromServicesSession: TDelayedLoadFunction = (
  Dll: @delayed_winsta;
  FunctionName: 'WinStationRevertFromServicesSession';
);

{ AppInfo }

// rev
[MinOSVersion(OsWin81)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function EnableDisableElevationForSessionWorker(
  [in] SessionId: TSessionId;
  [in] Enable: LongBool
): TWin32Error; stdcall; external winlogonext delayed;

var delayed_EnableDisableElevationForSessionWorker: TDelayedLoadFunction = (
  Dll: @delayed_winlogonext;
  FunctionName: 'EnableDisableElevationForSessionWorker';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TWinStationInformation }

function TWinStationInformation.FullUserName;
begin
  if (Domain = '') and (UserName = '') then
    Result := 'No user'
  else if Domain = '' then
    Result := UserName
  else if UserName = '' then
    Result := Domain
  else
    Result := String(Domain) + '\' + String(UserName);
end;

end.
