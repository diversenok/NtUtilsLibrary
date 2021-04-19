unit Winapi.winsta;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Winapi.WinUser,DelphiApi.Reflection;

const
  winsta = 'winsta.dll';

  // 40
  USERNAME_LENGTH = 20;
  DOMAIN_LENGTH = 17;

  // 58
  WINSTATIONNAME_LENGTH = 32;

  // 805
  LOGONID_CURRENT = Cardinal(-1);
  SERVERNAME_CURRENT = nil;
  SERVER_CURRENT = 0;

type
  TWinStaHandle = NativeUInt;

  TWinStationName = array [0..WINSTATIONNAME_LENGTH] of WideChar;
  TDomainName = array [0..DOMAIN_LENGTH] of WideChar;
  TUserName = array [0..USERNAME_LENGTH] of WideChar;

  // 84
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

  // 98
  TSessionIdW = record
    SessionID: TSessionId;
    WinStationName: TWinStationName;
    State: TWinStationStateClass;
  end;

  TSessionIdArrayW = TAnysizeArray<TSessionIdW>;
  PSessionIdArrayW = ^TSessionIdArrayW;

  // 110
  [NamingStyle(nsCamelCase, 'WinStation')]
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
    WinStationUnused1 = 15,
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

  // 179
  [NamingStyle(nsCamelCase, 'Shadow_')]
  TShadowClass = (
    Shadow_Disable,
    Shadow_EnableInputNotify,
    Shadow_EnableInputNoNotify,
    Shadow_EnableNoInputNotify,
    Shadow_EnableNoInputNoNotify
  );

  // 460
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

  // 503
  TCaheStatistics = record
    ProtocolType: Word;
    [Bytes] Length: Word;
    [Unlisted] Reserved: array [0..19] of Cardinal;
  end;

  // 515
  TProtocolStatus = record
    Output: TProtocolCounters;
    Input: TProtocolCounters;
    Cache: TCaheStatistics;
    AsyncSignal: Cardinal;
    AsyncSignalMask: Cardinal;
  end;

  // 525
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

  // 541
  TWinStationUserToken = record
    ClientID: TClientID;
    UserToken: THandle;
  end;
  PWinStationUserToken = ^TWinStationUserToken;

  // 583
  [NamingStyle(nsCamelCase)]
  TLoadFactorType = (
    ErrorConstraint = 0,
    PagedPoolConstraint = 1,
    NonPagedPoolConstraint = 2,
    AvailablePagesConstraint = 3,
    SystemPtesConstraint = 4,
    CPUConstraint = 5
  );

  // 594
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

  // 606
  [NamingStyle(nsCamelCase, 'State_')]
  TShadowStateClass = (
    State_NoShadow,
    State_Shadowing,
    State_Shadowed
  );

  [NamingStyle(nsCamelCase, 'Protocol_')]
  TProtocolType = (
    Protocol_Console = 0,
    Protocol_Others = 1,
    Protocol_RDP = 2
  );

  // 614
  TWinStationShadow = record
    ShadowState: TShadowStateClass;
    ShadowClass: TShadowClass;
    SessionID: TSessionId;
    ProtocolType: TProtocolType;
  end;
  PWinStationShadow = ^TWinStationShadow;

  // [MS-TSTS]
  [NamingStyle(nsCamelCase)]
  TReconnectType = (
    NeverReconnected = 0,
    ManualReconnect = 1,
    AutoReconnect = 2
  );

// 811
function WinStationFreeMemory(
  [in] Buffer: Pointer
): Boolean; stdcall; external winsta;

// 818
function WinStationOpenServerW(
  [in] ServerName: PWideChar
): TWinStaHandle; stdcall; external winsta;

// 825
function WinStationCloseServer(
  hServer: TWinStaHandle
): Boolean; stdcall; external winsta;

// 881
function WinStationEnumerateW(
  [opt] ServerHandle: TWinStaHandle;
  [allocates] out SessionIds: PSessionIdArrayW;
  out Count: Integer
): Boolean; stdcall; external winsta;

// 891
function WinStationQueryInformationW(
  [opt] ServerHandle: TWinStaHandle;
  SessionId: TSessionId;
  WinStationInformationClass: TWinStationInfoClass;
  [out] WinStationInformation: Pointer;
  WinStationInformationLength: Cardinal;
  out ReturnLength: Cardinal
): Boolean; stdcall; external winsta;

// 903
function WinStationSetInformationW(
  [opt] ServerHandle: TWinStaHandle;
  SessionId: TSessionId;
  WinStationInformationClass: TWinStationInfoClass;
  [in] WinStationInformation: Pointer;
  WinStationInformationLength: Cardinal
): Boolean; stdcall; external winsta;

// 922
function WinStationSendMessageW(
  [opt] ServerHandle: TWinStaHandle;
  SessionId: TSessionId;
  [in] Title: PWideChar;
  TitleLength: Cardinal;
  [in] MessageStr: PWideChar;
  MessageLength: Cardinal;
  Style: TMessageStyle;
  Timeout: Cardinal;
  out Response: TMessageResponse;
  DoNotWait: Boolean
): Boolean; stdcall; external winsta;

// 937
function WinStationConnectW(
  [opt] ServerHandle: TWinStaHandle;
  SessionId: TSessionId;
  TargetSessionId: TSessionId;
  [in, opt] Password: PWideChar;
  Wait: Boolean
): Boolean; stdcall; external winsta;

// 947
function WinStationDisconnect(
  [opt] ServerHandle: TWinStaHandle;
  SessionId: TSessionId;
  Wait: Boolean
): Boolean; stdcall; external winsta;

// 965
function WinStationShadow(
  [opt] ServerHandle: TWinStaHandle;
  [in] TargetServerName: PWideChar;
  TargetSessionId: TSessionId;
  HotKeyVk: Byte;
  HotkeyModifiers: Word
): Boolean; stdcall; external winsta;

// 976
function WinStationShadowStop(
  [opt] ServerHandle: TWinStaHandle;
  SessionId: TSessionId;
  Wait: Boolean
): Boolean; stdcall; external winsta;

// 1037
function WinStationSwitchToServicesSession: Boolean; stdcall; external winsta;

// 1044
function WinStationRevertFromServicesSession: Boolean; stdcall; external winsta;

implementation

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
