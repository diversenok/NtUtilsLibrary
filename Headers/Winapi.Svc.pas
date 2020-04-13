unit Winapi.Svc;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, DelphiApi.Reflection;

const
  // 88
  SERVICE_NO_CHANGE = Cardinal(-1);

  // 138
  SERVICE_ACCEPT_STOP = $00000001;
  SERVICE_ACCEPT_PAUSE_CONTINUE = $00000002;
  SERVICE_ACCEPT_SHUTDOWN = $00000004;
  SERVICE_ACCEPT_PARAMCHANGE = $00000008;
  SERVICE_ACCEPT_NETBINDCHANGE = $00000010;
  SERVICE_ACCEPT_HARDWAREPROFILECHANGE = $00000020;
  SERVICE_ACCEPT_POWEREVENT = $00000040;
  SERVICE_ACCEPT_SESSIONCHANGE = $00000080;
  SERVICE_ACCEPT_PRESHUTDOWN = $00000100;
  SERVICE_ACCEPT_TIMECHANGE = $00000200;
  SERVICE_ACCEPT_TRIGGEREVENT = $00000400;
  SERVICE_ACCEPT_USER_LOGOFF = $00000800;
  SERVICE_ACCEPT_LOWRESOURCES = $00002000;
  SERVICE_ACCEPT_SYSTEMLOWRESOURCES = $00004000;

  // 157
  SC_MANAGER_CONNECT = $0001;
  SC_MANAGER_CREATE_SERVICE = $0002;
  SC_MANAGER_ENUMERATE_SERVICE = $0004;
  SC_MANAGER_LOCK = $0008;
  SC_MANAGER_QUERY_LOCK_STATUS = $0010;
  SC_MANAGER_MODIFY_BOOT_CONFIG = $0020;

  SC_MANAGER_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $3F;

  ScmAccessMapping: array [0..5] of TFlagName = (
    (Value: SC_MANAGER_CONNECT;            Name: 'Connect'),
    (Value: SC_MANAGER_CREATE_SERVICE;     Name: 'Create service'),
    (Value: SC_MANAGER_ENUMERATE_SERVICE;  Name: 'Enumerate services'),
    (Value: SC_MANAGER_LOCK;               Name: 'Lock'),
    (Value: SC_MANAGER_QUERY_LOCK_STATUS;  Name: 'Query lock status'),
    (Value: SC_MANAGER_MODIFY_BOOT_CONFIG; Name: 'Modify boot config')
  );

  ScmAccessType: TAccessMaskType = (
    TypeName: 'SCM';
    FullAccess: SC_MANAGER_ALL_ACCESS;
    Count: Length(ScmAccessMapping);
    Mapping: PFlagNameRefs(@ScmAccessMapping);
  );

  // 177
  SERVICE_QUERY_CONFIG = $0001;
  SERVICE_CHANGE_CONFIG = $0002;
  SERVICE_QUERY_STATUS = $0004;
  SERVICE_ENUMERATE_DEPENDENTS = $0008;
  SERVICE_START = $0010;
  SERVICE_STOP = $0020;
  SERVICE_PAUSE_CONTINUE = $0040;
  SERVICE_INTERROGATE = $0080;
  SERVICE_USER_DEFINED_CONTROL = $0100;

  SERVICE_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1FF;

  ServiceAccessMapping: array [0..8] of TFlagName = (
    (Value: SERVICE_QUERY_CONFIG;         Name: 'Query config'),
    (Value: SERVICE_CHANGE_CONFIG;        Name: 'Change config'),
    (Value: SERVICE_QUERY_STATUS;         Name: 'Query status'),
    (Value: SERVICE_ENUMERATE_DEPENDENTS; Name: 'Enumerate dependents'),
    (Value: SERVICE_START;                Name: 'Start'),
    (Value: SERVICE_STOP;                 Name: 'Stop'),
    (Value: SERVICE_PAUSE_CONTINUE;       Name: 'Pause/continue'),
    (Value: SERVICE_INTERROGATE;          Name: 'Interrogate'),
    (Value: SERVICE_USER_DEFINED_CONTROL; Name: 'User-defined control')
  );

  ServiceAccessType: TAccessMaskType = (
    TypeName: 'service';
    FullAccess: SERVICE_ALL_ACCESS;
    Count: Length(ServiceAccessMapping);
    Mapping: PFlagNameRefs(@ServiceAccessMapping);
  );

  // 201
  SERVICE_RUNS_IN_SYSTEM_PROCESS = $0000001;

  // WinNt.21364
  SERVICE_KERNEL_DRIVER = $00000001;
  SERVICE_FILE_SYSTEM_DRIVER = $00000002;
  SERVICE_WIN32_OWN_PROCESS = $00000010;
  SERVICE_WIN32_SHARE_PROCESS = $00000020;
  SERVICE_USER_OWN_PROCESS = $00000050;
  SERVICE_USER_SHARE_PROCESS = $00000060;
  SERVICE_INTERACTIVE_PROCESS = $00000100;

type
  TScmHandle = NativeUInt;
  TServiceStatusHandle = NativeUInt;
  TScLock = NativeUInt;

  // WinNt.21392
  [NamingStyle(nsSnakeCase, 'SERVICE')]
  TServiceStartType = (
    SERVICE_BOOT_START = 0,
    SERVICE_SYSTEM_START = 1,
    SERVICE_AUTO_START = 2,
    SERVICE_DEMAND_START = 3,
    SERVICE_DISABLED = 4
  );

  // WinNt.21401
  [NamingStyle(nsSnakeCase, 'SERVICE_ERROR')]
  TServiceErrorControl = (
    SERVICE_ERROR_IGNORE = 0,
    SERVICE_ERROR_NORMAL = 1,
    SERVICE_ERROR_SEVERE = 2,
    SERVICE_ERROR_CRITICAL = 3
  );

  // 101
  [NamingStyle(nsSnakeCase, 'SERVICE_CONTROL'), Range(1)]
  TServiceControl = (
    SERVICE_CONTROL_RESERVED = 0,
    SERVICE_CONTROL_STOP = 1,
    SERVICE_CONTROL_PAUSE = 2,
    SERVICE_CONTROL_CONTINUE = 3,
    SERVICE_CONTROL_INTERROGATE = 4,
    SERVICE_CONTROL_SHUTDOWN = 5,
    SERVICE_CONTROL_PARAM_CHANGE = 6,
    SERVICE_CONTROL_NETBIND_ADD = 7,
    SERVICE_CONTROL_NETBIND_REMOVE = 8,
    SERVICE_CONTROL_NETBIND_ENABLE = 9,
    SERVICE_CONTROL_NETBIND_DISABLE = 10,
    SERVICE_CONTROL_DEVICE_EVENT = 11,
    SERVICE_CONTROL_HARDWARE_PROFILE_CHANGE = 12,
    SERVICE_CONTROL_POWER_EVENT = 13,
    SERVICE_CONTROL_SESSION_CHANGE = 14,
    SERVICE_CONTROL_PRESHUTDOWN = 15,
    SERVICE_CONTROL_TIME_CHANGE = 16,
    SERVICE_CONTROL_USER_LOGOFF = 17
  );

  // 127
  [NamingStyle(nsSnakeCase, 'SERVICE')]
  TServiceState = (
    SERVICE_STOPPED = 1,
    SERVICE_START_PENDING = 2,
    SERVICE_STOP_PENDING = 3,
    SERVICE_RUNNING = 4,
    SERVICE_CONTINUE_PENDING = 5,
    SERVICE_PAUSE_PENDING = 6,
    SERVICE_PAUSED = 7
  );

  // 206
  [NamingStyle(nsSnakeCase, 'SERVICE_CONFIG'), Range(1)]
  TServiceConfigLevel = (
    SERVICE_CONFIG_RESERVED = 0,
    SERVICE_CONFIG_DESCRIPTION = 1,              // q, s: TServiceDescription
    SERVICE_CONFIG_FAILURE_ACTIONS = 2,          // q, s: TServiceFailureActions
    SERVICE_CONFIG_DELAYED_AUTO_START_INFO = 3,  // q, s: LongBool
    SERVICE_CONFIG_FAILURE_ACTIONS_FLAG = 4,     // q, s: LongBool
    SERVICE_CONFIG_SERVICE_SID_INFO = 5,         // q, s: TServiceSidType
    SERVICE_CONFIG_REQUIRED_PRIVILEGES_INFO = 6, // q, s: TServiceRequiredPrivilegesInfo
    SERVICE_CONFIG_PRESHUTDOWN_INFO = 7,         // q, s: Cardinal (timeout in ms)
    SERVICE_CONFIG_TRIGGER_INFO = 8,             // q, s:
    SERVICE_CONFIG_PREFERRED_NODE = 9,           // q, s:
    SERVICE_CONFIG_RESERVED10 = 10,
    SERVICE_CONFIG_RESERVED11 = 11,
    SERVICE_CONFIG_LAUNCH_PROTECTED = 12         // q, s: TServiceLaunchProtected
  );

  // 306
  [NamingStyle(nsSnakeCase, 'SERVICE_CONTROL_STATUS'), Range(1)]
  TServiceContolLevel = (
    SERVICE_CONTROL_STATUS_RESERVED = 0,
    SERVICE_CONTROL_STATUS_REASON_INFO = 1 // TServiceControlStatusReasonParamsW
  );

  // 311
  [NamingStyle(nsSnakeCase, 'SERVICE_SID_TYPE')]
  TServiceSidType = (
    SERVICE_SID_TYPE_NONE = 0,
    SERVICE_SID_TYPE_UNRESTRICTED = 1,
    SERVICE_SID_TYPE_UNKNOWN = 2,
    SERVICE_SID_TYPE_RESTRICTED = 3
  );

  // 354, Win 8.1+
  [NamingStyle(nsSnakeCase, 'SERVICE_LAUNCH_PROTECTED')]
  TServiceLaunchProtected = (
    SERVICE_LAUNCH_PROTECTED_NONE = 0,
    SERVICE_LAUNCH_PROTECTED_WINDOWS = 1,
    SERVICE_LAUNCH_PROTECTED_WINDOWS_LIGHT = 2,
    SERVICE_LAUNCH_PROTECTED_ANTIMALWARE_LIGHT = 3
  );

  // 508
  TServiceDescription = record
    Description: PWideChar;
  end;
  PServiceDescription = ^TServiceDescription;

  // 522
  [NamingStyle(nsSnakeCase, 'SC_ACTION')]
  TScActionType = (
    SC_ACTION_NONE = 0,
    SC_ACTION_RESTART = 1,
    SC_ACTION_REBOOT = 2,
    SC_ACTION_RUN_COMMAND = 3,
    SC_ACTION_OWN_RESTART = 4
  );

  // 530
  TScAction = record
    ActionType: TScActionType;
    Delay: Cardinal;
  end;
  PScAction = ^TScAction;

  // 548
  TServiceFailureActions = record
    ResetPeriod: Cardinal;
    RebootMsg: PWideChar;
    Command: PWideChar;
    Actions: Cardinal;
    lpsaActions: PScAction;
  end;
  PServiceFailureActions = ^TServiceFailureActions;

  // 599
  TServiceRequiredPrivilegesInfo = record
    RequiredPrivileges: PWideChar; // multi-sz
  end;
  PServiceRequiredPrivilegesInfo = ^TServiceRequiredPrivilegesInfo;

  // 707
  [NamingStyle(nsSnakeCase, 'SC_STATUS')]
  TScStatusType = (
    SC_STATUS_PROCESS_INFO = 0 // TServiceStatusProcess
  );

  [FlagName(SERVICE_ACCEPT_STOP, 'Stop')]
  [FlagName(SERVICE_ACCEPT_PAUSE_CONTINUE, 'Pause/Continue')]
  [FlagName(SERVICE_ACCEPT_SHUTDOWN, 'Shutdown')]
  [FlagName(SERVICE_ACCEPT_PARAMCHANGE, 'Parameter Change')]
  [FlagName(SERVICE_ACCEPT_NETBINDCHANGE, 'Net Binding Change')]
  [FlagName(SERVICE_ACCEPT_HARDWAREPROFILECHANGE, 'Hardware Profile Change')]
  [FlagName(SERVICE_ACCEPT_POWEREVENT, 'Power Event')]
  [FlagName(SERVICE_ACCEPT_SESSIONCHANGE, 'Session Change')]
  [FlagName(SERVICE_ACCEPT_PRESHUTDOWN, 'Preshutdown')]
  [FlagName(SERVICE_ACCEPT_TIMECHANGE, 'Time Change')]
  [FlagName(SERVICE_ACCEPT_TRIGGEREVENT, 'Triggers')]
  [FlagName(SERVICE_ACCEPT_USER_LOGOFF, 'User Logoff')]
  [FlagName(SERVICE_ACCEPT_LOWRESOURCES, 'Low Resources')]
  [FlagName(SERVICE_ACCEPT_SYSTEMLOWRESOURCES, 'System Low Resources')]
  TServiceAcceptedControls = type Cardinal;

  // 723
  TServiceStatus = record
    ServiceType: Cardinal;
    CurrentState: TServiceState;
    ControlsAccepted: TServiceAcceptedControls;
    Win32ExitCode: TWin32Error;
    ServiceSpecificExitCode: Cardinal;
    CheckPoint: Cardinal;
    WaitHint: Cardinal;
  end;
  PServiceStatus = ^TServiceStatus;

  [FlagName(SERVICE_RUNS_IN_SYSTEM_PROCESS, 'Runs In System Process')]
  TServiceFlags = type Cardinal;

  // 733
  TServiceStatusProcess = record
    ServiceType: Cardinal;
    CurrentState: TServiceState;
    ControlsAccepted: TServiceAcceptedControls;
    Win32ExitCode: TWin32Error;
    ServiceSpecificExitCode: Cardinal;
    CheckPoint: Cardinal;
    WaitHint: Cardinal;
    ProcessID: TProcessId32;
    ServiceFlags: TServiceFlags;
  end;
  PServiceStatusProcess = ^TServiceStatusProcess;

  // 827
  TQueryServiceConfigW = record
    ServiceType: Cardinal;
    StartType: TServiceStartType;
    ErrorControl: TServiceErrorControl;
    BinaryPathName: PWideChar;
    LoadOrderGroup: PWideChar;
    TagID: Cardinal;
    Dependencies: PWideChar;
    ServiceStartName: PWideChar;
    DisplayName: PWideChar;
  end;
  PQueryServiceConfigW = ^TQueryServiceConfigW;

  TServiceArgsW = array [ANYSIZE_ARRAY] of PWideChar;
  PServiceArgsW = ^TServiceArgsW;

  // 868
  TServiceMainFunction = procedure (NumServicesArgs: Integer;
    ServiceArgVectors: PServiceArgsW) stdcall;

  // 893
  TServiceTableEntryW = record
    ServiceName: PWideChar;
    ServiceProc: TServiceMainFunction;
  end;
  PServiceTableEntryW = ^TServiceTableEntryW;

  // 924
  THandlerFunctionEx = function(Control: TServiceControl; EventType: Cardinal;
    EventData: Pointer; Context: Pointer): Cardinal; stdcall;

  // 991
  TServiceControlStatusReasonParamsW = record
    Reason: Cardinal;
    Comment: PWideChar;
    ServiceStatus: TServiceStatusProcess;
  end;
  PServiceControlStatusReasonParamsW = ^TServiceControlStatusReasonParamsW;

// 1041
function ChangeServiceConfigW(hService: TScmHandle; ServiceType: Cardinal;
  StartType: TServiceStartType; ErrorControl: TServiceErrorControl;
  BinaryPathName: PWideChar; LoadOrderGroup: PWideChar; pTagId: PCardinal;
  Dependencies: PWideChar; ServiceStartName: PWideChar; Password: PWideChar;
  DisplayName: PWideChar): LongBool; stdcall; external advapi32;

// 1071
function ChangeServiceConfig2W(hService: TScmHandle;
  InfoLevel: TServiceConfigLevel; pInfo: Pointer): LongBool; stdcall;
  external advapi32;

// 1083
function CloseServiceHandle(hSCObject: TScmHandle): LongBool; stdcall;
  external advapi32;

// 1092
function ControlService(hService: TScmHandle; Control: TServiceControl;
  out ServiceStatus: TServiceStatus): LongBool; stdcall; external advapi32;

// 1121
function CreateServiceW(hSCManager: TScmHandle; ServiceName: PWideChar;
  DisplayName: PWideChar; DesiredAccess: TAccessMask; ServiceType: Cardinal;
  StartType: TServiceStartType; ErrorControl: TServiceErrorControl;
  BinaryPathName: PWideChar; LoadOrderGroup: PWideChar; pTagId: PCardinal;
  Dependencies: PWideChar; ServiceStartName: PWideChar; Password: PWideChar)
  : TScmHandle; stdcall; external advapi32;

// 1145
function DeleteService(hService: TScmHandle): LongBool; stdcall;
  external advapi32;

// 1312
function GetServiceDisplayNameW(hSCManager: TScmHandle; ServiceName: PWideChar;
  DisplayName: PWideChar; var cchBuffer: Cardinal): LongBool; stdcall;
  external advapi32;

// 1334
function LockServiceDatabase(hSCManager: TScmHandle): TScLock; stdcall;
  external advapi32;

// 1364
function OpenSCManagerW(MachineName: PWideChar; DatabaseName: PWideChar;
  DesiredAccess: TAccessMask): TScmHandle; stdcall; external advapi32;

// 1388
function OpenServiceW(hSCManager: TScmHandle; ServiceName: PWideChar;
  DesiredAccess: Cardinal): TScmHandle; stdcall; external advapi32;

// 1414
function QueryServiceConfigW(hService: TScmHandle; ServiceConfig:
  PQueryServiceConfigW; BufSize: Cardinal; out BytesNeeded: Cardinal): LongBool;
  stdcall; external advapi32;

// 1457
function QueryServiceConfig2W(hService: TScmHandle;
  InfoLevel: TServiceConfigLevel; Buffer: Pointer; BufSize: Cardinal;
  out BytesNeeded: Cardinal): LongBool; stdcall; external advapi32;

// 1515
function QueryServiceObjectSecurity(hService: TScmHandle; SecurityInformation:
  TSecurityInformation; SecurityDescriptor: PSecurityDescriptor;
  BufSize: Cardinal; out BytesNeeded: Cardinal): LongBool; stdcall;
  external advapi32;

// 1528
function QueryServiceStatus(hService: TScmHandle;
  out ServiceStatus: TServiceStatus): LongBool; stdcall; external advapi32;

// 1537
function QueryServiceStatusEx(hService: TScmHandle; InfoLevel: TScStatusType;
  Buffer: Pointer; BufSize: Cardinal; out BytesNeeded: Cardinal): LongBool;
  stdcall; external advapi32;

// 1584
function RegisterServiceCtrlHandlerExW(ServiceName: PWideChar; HandlerProc:
  THandlerFunctionEx; Context: Pointer): TServiceStatusHandle; stdcall;
  external advapi32;

// 1599
function SetServiceObjectSecurity(hService: TScmHandle;
  SecurityInformation: TSecurityInformation; const SecurityDescriptor:
  TSecurityDescriptor): LongBool; stdcall; external advapi32;

// 1608
function SetServiceStatus(hServiceStatus: TServiceStatusHandle;
  const ServiceStatus: TServiceStatus): LongBool; stdcall; external advapi32;

// 1622
function StartServiceCtrlDispatcherW(ServiceStartTable: PServiceTableEntryW):
  LongBool; stdcall; external advapi32;

// 1644
function StartServiceW(hService: TScmHandle; NumServiceArgs: Cardinal;
  ServiceArgVectors: TArray<PWideChar>): LongBool; stdcall; external advapi32;

// 1665
function UnlockServiceDatabase(ScLock: TScLock): LongBool; stdcall;
  external advapi32;

// 1711
function ControlServiceExW(hService: TScmHandle; Control: TServiceControl;
  InfoLevel: TServiceContolLevel; ControlParams: Pointer): LongBool; stdcall;
  external advapi32;

implementation

end.
