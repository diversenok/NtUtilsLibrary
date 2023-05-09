unit Ntapi.WinSvc;

{
  This module provides functions for accessing Service Control Manager.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.Versions, DelphiApi.Reflection, DelphiApi.DelayLoad;

const
  // SDK::winsvc.h - database names for OpenSCManagerW
  SERVICES_ACTIVE_DATABASE = 'ServicesActive';
  SERVICES_FAILED_DATABASE = 'ServicesFailed';

  // SDK::winsvc.h - skips a field in ChangeServiceConfigW
  SERVICE_NO_CHANGE = Cardinal(-1);

  // SDK::winsvc.h - accepted operations
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

  // SDK::winsvc.h - SCM access masks
  SC_MANAGER_CONNECT = $0001;
  SC_MANAGER_CREATE_SERVICE = $0002;
  SC_MANAGER_ENUMERATE_SERVICE = $0004;
  SC_MANAGER_LOCK = $0008;
  SC_MANAGER_QUERY_LOCK_STATUS = $0010;
  SC_MANAGER_MODIFY_BOOT_CONFIG = $0020;

  SC_MANAGER_READ = STANDARD_RIGHTS_READ or $0014;
  SC_MANAGER_WRITE = STANDARD_RIGHTS_WRITE or $0022;
  SC_MANAGER_EXECUTE = STANDARD_RIGHTS_EXECUTE or $0009;
  SC_MANAGER_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $003F;

  // SDK::winsvc.h - service access masks
  SERVICE_QUERY_CONFIG = $0001;
  SERVICE_CHANGE_CONFIG = $0002;
  SERVICE_QUERY_STATUS = $0004;
  SERVICE_ENUMERATE_DEPENDENTS = $0008;
  SERVICE_START = $0010;
  SERVICE_STOP = $0020;
  SERVICE_PAUSE_CONTINUE = $0040;
  SERVICE_INTERROGATE = $0080;
  SERVICE_USER_DEFINED_CONTROL = $0100;

  SERVICE_READ = STANDARD_RIGHTS_READ or $008D;
  SERVICE_WRITE = STANDARD_RIGHTS_WRITE or $0002;
  SERVICE_EXECUTE = STANDARD_RIGHTS_EXECUTE or $0170;
  SERVICE_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED or $1FF;

  // For annotations
  SERVICE_CONTROL_ANY = SERVICE_PAUSE_CONTINUE or SERVICE_STOP or
    SERVICE_INTERROGATE or SERVICE_USER_DEFINED_CONTROL;

  // SDK::winsvc.h - service flags for QueryServiceStatusEx
  SERVICE_RUNS_IN_SYSTEM_PROCESS = $0000001;

  // SDK::winsvc.h - stop reason flags
  SERVICE_STOP_REASON_MINOR_OTHER = $00000001;
  SERVICE_STOP_REASON_MINOR_MAINTENANCE = $00000002;
  SERVICE_STOP_REASON_MINOR_INSTALLATION = $00000003;
  SERVICE_STOP_REASON_MINOR_UPGRADE = $00000004;
  SERVICE_STOP_REASON_MINOR_RECONFIG = $00000005;
  SERVICE_STOP_REASON_MINOR_HUNG = $00000006;
  SERVICE_STOP_REASON_MINOR_UNSTABLE = $00000007;
  SERVICE_STOP_REASON_MINOR_DISK = $00000008;
  SERVICE_STOP_REASON_MINOR_NETWORKCARD = $00000009;
  SERVICE_STOP_REASON_MINOR_ENVIRONMENT = $0000000a;
  SERVICE_STOP_REASON_MINOR_HARDWARE_DRIVER = $0000000b;
  SERVICE_STOP_REASON_MINOR_OTHERDRIVER = $0000000c;
  SERVICE_STOP_REASON_MINOR_SERVICEPACK = $0000000d;
  SERVICE_STOP_REASON_MINOR_SOFTWARE_UPDATE = $0000000e;
  SERVICE_STOP_REASON_MINOR_SECURITYFIX = $0000000f;
  SERVICE_STOP_REASON_MINOR_SECURITY = $00000010;
  SERVICE_STOP_REASON_MINOR_NETWORK_CONNECTIVITY = $00000011;
  SERVICE_STOP_REASON_MINOR_WMI = $00000012;
  SERVICE_STOP_REASON_MINOR_SERVICEPACK_UNINSTALL = $00000013;
  SERVICE_STOP_REASON_MINOR_SOFTWARE_UPDATE_UNINSTALL = $00000014;
  SERVICE_STOP_REASON_MINOR_SECURITYFIX_UNINSTALL = $00000015;
  SERVICE_STOP_REASON_MINOR_MMC = $00000016;
  SERVICE_STOP_REASON_MINOR_NONE = $00000017;
  SERVICE_STOP_REASON_MINOR_MEMOTYLIMIT = $00000018;
  SERVICE_STOP_REASON_MAJOR_OTHER = $00010000;
  SERVICE_STOP_REASON_MAJOR_HARDWARE = $00020000;
  SERVICE_STOP_REASON_MAJOR_OPERATINGSYSTEM = $00030000;
  SERVICE_STOP_REASON_MAJOR_SOFTWARE = $00040000;
  SERVICE_STOP_REASON_MAJOR_APPLICATION = $00050000;
  SERVICE_STOP_REASON_MAJOR_NONE = $00060000;
  SERVICE_STOP_REASON_FLAG_UNPLANNED = $10000000;
  SERVICE_STOP_REASON_FLAG_CUSTOM = $20000000;
  SERVICE_STOP_REASON_FLAG_PLANNED = $40000000;

  // SDK::winnt.h
  SERVICE_KERNEL_DRIVER = $00000001;
  SERVICE_FILE_SYSTEM_DRIVER = $00000002;
  SERVICE_ADAPTER = $00000004;
  SERVICE_RECOGNIZER_DRIVER = $00000008;
  SERVICE_WIN32_OWN_PROCESS = $00000010;
  SERVICE_WIN32_SHARE_PROCESS = $00000020;
  SERVICE_USER_SERVICE = $00000040;
  SERVICE_USERSERVICE_INSTANCE = $00000080;
  SERVICE_INTERACTIVE_PROCESS = $00000100;
  SERVICE_PKG_SERVICE = $00000200;

  SERVICE_DRIVER = SERVICE_KERNEL_DRIVER or SERVICE_FILE_SYSTEM_DRIVER or
    SERVICE_RECOGNIZER_DRIVER;
  SERVICE_WIN32 = SERVICE_WIN32_OWN_PROCESS or SERVICE_WIN32_SHARE_PROCESS;
  SERVICE_USER_OWN_PROCESS = SERVICE_USER_SERVICE or SERVICE_WIN32_OWN_PROCESS;
  SERVICE_USER_SHARE_PROCESS = SERVICE_USER_SERVICE or SERVICE_WIN32_SHARE_PROCESS;

  SERVICE_TYPE_ALL = $000003FF;

  // SDK::winsvc.h - notify masks
  SERVICE_NOTIFY_STOPPED = $00000001;
  SERVICE_NOTIFY_START_PENDING = $00000002;
  SERVICE_NOTIFY_STOP_PENDING = $00000004;
  SERVICE_NOTIFY_RUNNING = $00000008;
  SERVICE_NOTIFY_CONTINUE_PENDING = $00000010;
  SERVICE_NOTIFY_PAUSE_PENDING = $00000020;
  SERVICE_NOTIFY_PAUSED = $00000040;
  SERVICE_NOTIFY_CREATED = $00000080;
  SERVICE_NOTIFY_DELETED = $00000100;
  SERVICE_NOTIFY_DELETE_PENDING = $00000200;

  // SDK::winsvc.h - notify version
  SERVICE_NOTIFY_STATUS_CHANGE = 2;

  // SDK::winsvc.h - start reason
  SERVICE_START_REASON_DEMAND = $00000001;
  SERVICE_START_REASON_AUTO = $00000002;
  SERVICE_START_REASON_TRIGGER = $00000004;
  SERVICE_START_REASON_RESTART_ON_FAILURE = $00000008;
  SERVICE_START_REASON_DELAYEDAUTO = $00000010;

type
  TScmHandle = NativeUInt;
  TServiceStatusHandle = NativeUInt;
  TScLock = NativeUInt;
  PScEnumerationHandle = PCardinal;

  [FriendlyName('SCM'), ValidBits(SC_MANAGER_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SC_MANAGER_CONNECT, 'Connect')]
  [FlagName(SC_MANAGER_CREATE_SERVICE, 'Create Service')]
  [FlagName(SC_MANAGER_ENUMERATE_SERVICE, 'Enumerate Services')]
  [FlagName(SC_MANAGER_LOCK, 'Lock')]
  [FlagName(SC_MANAGER_QUERY_LOCK_STATUS, 'Query Lock Status')]
  [FlagName(SC_MANAGER_MODIFY_BOOT_CONFIG, 'Modify Boot Config')]
  TScmAccessMask = type TAccessMask;

  [FriendlyName('service'), ValidBits(SERVICE_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(SERVICE_QUERY_CONFIG, 'Query Config')]
  [FlagName(SERVICE_CHANGE_CONFIG, 'Change Config')]
  [FlagName(SERVICE_QUERY_STATUS, 'Query Status')]
  [FlagName(SERVICE_ENUMERATE_DEPENDENTS, 'Enumerate Dependents')]
  [FlagName(SERVICE_START, 'Start')]
  [FlagName(SERVICE_STOP, 'Stop')]
  [FlagName(SERVICE_PAUSE_CONTINUE, 'Pause/Continue')]
  [FlagName(SERVICE_INTERROGATE, 'Interrogate')]
  [FlagName(SERVICE_USER_DEFINED_CONTROL, 'User-defined Control')]
  TServiceAccessMask = type TAccessMask;

  [FlagName(SERVICE_KERNEL_DRIVER, 'Kernel Driver')]
  [FlagName(SERVICE_FILE_SYSTEM_DRIVER, 'File System Driver')]
  [FlagName(SERVICE_ADAPTER, 'Adapter')]
  [FlagName(SERVICE_RECOGNIZER_DRIVER, 'Recognizer Driver')]
  [FlagName(SERVICE_WIN32_OWN_PROCESS, 'Win32 Own Process')]
  [FlagName(SERVICE_WIN32_SHARE_PROCESS, 'Win32 Share Process')]
  [FlagName(SERVICE_USER_SERVICE, 'User Service')]
  [FlagName(SERVICE_USERSERVICE_INSTANCE, 'User Serice Instance')]
  [FlagName(SERVICE_INTERACTIVE_PROCESS, 'Interactive Process')]
  [FlagName(SERVICE_PKG_SERVICE, 'Package Service')]
  TServiceType = type Cardinal;

  // SDK::winnt.h
  [NamingStyle(nsSnakeCase, 'SERVICE')]
  TServiceStartType = (
    SERVICE_BOOT_START = 0,
    SERVICE_SYSTEM_START = 1,
    SERVICE_AUTO_START = 2,
    SERVICE_DEMAND_START = 3,
    SERVICE_DISABLED = 4
  );

  // SDK::winnt.h
  [NamingStyle(nsSnakeCase, 'SERVICE_ERROR')]
  TServiceErrorControl = (
    SERVICE_ERROR_IGNORE = 0,
    SERVICE_ERROR_NORMAL = 1,
    SERVICE_ERROR_SEVERE = 2,
    SERVICE_ERROR_CRITICAL = 3
  );

  // SDK::winsvc.h
  [NamingStyle(nsSnakeCase, 'SERVICE')]
  TServiceEnumState = (
    SERVICE_ACTIVE = 1,
    SERVICE_INACTIVE = 2,
    SERVICE_STATE_ALL = 3
  );

  // SDK::winsvc.h
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

  // SDK::winsvc.h
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

  // SDK::winsvc.h
  [NamingStyle(nsSnakeCase, 'SERVICE_CONFIG'), Range(1)]
  TServiceConfigLevel = (
    SERVICE_CONFIG_RESERVED = 0,
    SERVICE_CONFIG_DESCRIPTION = 1,              // q, s: PWideChar
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
    SERVICE_CONFIG_LAUNCH_PROTECTED = 12         // q, s: TServiceLaunchProtected, Win 8.1+
  );

  // SDK::winsvc.h
  [NamingStyle(nsSnakeCase, 'SERVICE_CONTROL_STATUS'), Range(1)]
  TServiceContolLevel = (
    SERVICE_CONTROL_STATUS_RESERVED = 0,
    SERVICE_CONTROL_STATUS_REASON_INFO = 1 // s: TServiceControlStatusReasonParams
  );

  // SDK::winsvc.h
  [NamingStyle(nsSnakeCase, 'SERVICE_SID_TYPE')]
  TServiceSidType = (
    SERVICE_SID_TYPE_NONE = 0,
    SERVICE_SID_TYPE_UNRESTRICTED = 1,
    SERVICE_SID_TYPE_UNKNOWN = 2,
    SERVICE_SID_TYPE_RESTRICTED = 3
  );

  // SDK::winsvc.h
  [MinOSVersion(OsWin81)]
  [NamingStyle(nsSnakeCase, 'SERVICE_LAUNCH_PROTECTED')]
  TServiceLaunchProtected = (
    SERVICE_LAUNCH_PROTECTED_NONE = 0,
    SERVICE_LAUNCH_PROTECTED_WINDOWS = 1,
    SERVICE_LAUNCH_PROTECTED_WINDOWS_LIGHT = 2,
    SERVICE_LAUNCH_PROTECTED_ANTIMALWARE_LIGHT = 3
  );

  // SDK::winsvc.h
  [SDKName('SC_ACTION_TYPE')]
  [NamingStyle(nsSnakeCase, 'SC_ACTION')]
  TScActionType = (
    SC_ACTION_NONE = 0,
    SC_ACTION_RESTART = 1,
    SC_ACTION_REBOOT = 2,
    SC_ACTION_RUN_COMMAND = 3,
    SC_ACTION_OWN_RESTART = 4
  );

  // SDK::winsvc.h
  [SDKName('SC_ACTION')]
  TScAction = record
    ActionType: TScActionType;
    Delay: Cardinal;
  end;
  PScAction = ^TScAction;

  // SDK::winsvc.h
  [SDKName('SERVICE_FAILURE_ACTIONS')]
  TServiceFailureActions = record
    ResetPeriod: Cardinal;
    RebootMsg: PWideChar;
    Command: PWideChar;
    [Counter] ActionsCount: Cardinal;
    pActions: ^TAnysizeArray<TScAction>;
  end;
  PServiceFailureActions = ^TServiceFailureActions;

  // SDK::winsvc.h
  [SDKName('SERVICE_REQUIRED_PRIVILEGES_INFO')]
  TServiceRequiredPrivilegesInfo = record
    RequiredPrivileges: PWideMultiSz;
  end;
  PServiceRequiredPrivilegesInfo = ^TServiceRequiredPrivilegesInfo;

  // SDK::winsvc.h
  [SDKName('SC_STATUS_TYPE')]
  [NamingStyle(nsSnakeCase, 'SC_STATUS')]
  TScStatusType = (
    SC_STATUS_PROCESS_INFO = 0 // q: TServiceStatusProcess
  );

  // SDK::winsvc.h
  [SDKName('SC_ENUM_TYPE')]
  [NamingStyle(nsSnakeCase, 'SC_ENUM')]
  TScEnumType = (
    SC_ENUM_PROCESS_INFO = 0 // q: TAnysizeArray<TEnumServiceStatusProcess>
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

  // SDK::winsvc.h
  [SDKName('SERVICE_STATUS')]
  TServiceStatus = record
    ServiceType: TServiceType;
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

  // SDK::winsvc.h
  [SDKName('SERVICE_STATUS_PROCESS')]
  TServiceStatusProcess = record
    ServiceType: TServiceType;
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

  // SDK::winsvc.h
  [SDKName('ENUM_SERVICE_STATUS')]
  TEnumServiceStatus = record
    ServiceName: PWideChar;
    DisplayName: PWideChar;
    ServiceStatus: TServiceStatus;
  end;
  PEnumServiceStatus = ^TEnumServiceStatus;
  TEnumServiceStatusArray = TAnysizeArray<TEnumServiceStatus>;
  PEnumServiceStatusArray = ^TEnumServiceStatusArray;

  // SDK::winsvc.h
  [SDKName('ENUM_SERVICE_STATUS_PROCESS')]
  TEnumServiceStatusProcess = record
    ServiceName: PWideChar;
    DisplayName: PWideChar;
    ServiceStatusProcess: TServiceStatusProcess;
  end;
  PEnumServiceStatusProcess = ^TEnumServiceStatusProcess;
  TEnumServiceStatusProcessArray = TAnysizeArray<TEnumServiceStatusProcess>;
  PEnumServiceStatusProcessArray = ^TEnumServiceStatusProcessArray;

  // SDK::winsvc.h
  [SDKName('QUERY_SERVICE_LOCK_STATUS')]
  TQueryServiceLockStatus = record
    IsLocked: LongBool;
    LockOwner: PWideChar;
    LockDuration: Cardinal;
  end;
  PQueryServiceLockStatus = ^TQueryServiceLockStatus;

  // SDK::winsvc.h
  [SDKName('QUERY_SERVICE_CONFIG')]
  TQueryServiceConfig = record
    ServiceType: TServiceType;
    StartType: TServiceStartType;
    ErrorControl: TServiceErrorControl;
    BinaryPathName: PWideChar;
    LoadOrderGroup: PWideChar;
    TagID: TServiceTag;
    Dependencies: PWideChar;
    ServiceStartName: PWideChar;
    DisplayName: PWideChar;
  end;
  PQueryServiceConfig = ^TQueryServiceConfig;

  // SDK::winsvc.h
  [SDKName('SERVICE_MAIN_FUNCTION')]
  TServiceMainFunction = procedure (
    [in] NumServicesArgs: Integer;
    [in, opt] const [ref] ServiceArgVectors: TAnysizeArray<PWideChar>
  ) stdcall;

  // SDK::winsvc.h
  [SDKName('SERVICE_TABLE_ENTRY')]
  TServiceTableEntry = record
    ServiceName: PWideChar;
    ServiceProc: TServiceMainFunction;
  end;
  PServiceTableEntry = ^TServiceTableEntry;

  // SDK::winsvc.h
  [SDKName('HANDLER_FUNCTION_EX')]
  THandlerFunctionEx = function(
    [in] Control: TServiceControl;
    [in] EventType: Cardinal;
    [in] EventData: Pointer;
    [in, opt] var Context
  ): TWin32Error; stdcall;

  [FlagName(SERVICE_STOP_REASON_MINOR_OTHER, 'Other Minor Reason')]
  [FlagName(SERVICE_STOP_REASON_MINOR_MAINTENANCE, 'Maintenance')]
  [FlagName(SERVICE_STOP_REASON_MINOR_INSTALLATION, 'Installation')]
  [FlagName(SERVICE_STOP_REASON_MINOR_UPGRADE, 'Upgrade')]
  [FlagName(SERVICE_STOP_REASON_MINOR_RECONFIG, 'Reconfiguration')]
  [FlagName(SERVICE_STOP_REASON_MINOR_HUNG, 'Hung')]
  [FlagName(SERVICE_STOP_REASON_MINOR_UNSTABLE, 'Unstable')]
  [FlagName(SERVICE_STOP_REASON_MINOR_DISK, 'Disk')]
  [FlagName(SERVICE_STOP_REASON_MINOR_NETWORKCARD, 'Network Card')]
  [FlagName(SERVICE_STOP_REASON_MINOR_ENVIRONMENT, 'Environment')]
  [FlagName(SERVICE_STOP_REASON_MINOR_HARDWARE_DRIVER, 'Hardware Driver')]
  [FlagName(SERVICE_STOP_REASON_MINOR_OTHERDRIVER, 'Other Driver')]
  [FlagName(SERVICE_STOP_REASON_MINOR_SERVICEPACK, 'Service Pack')]
  [FlagName(SERVICE_STOP_REASON_MINOR_SOFTWARE_UPDATE, 'Software Update')]
  [FlagName(SERVICE_STOP_REASON_MINOR_SECURITYFIX, 'Security Fix')]
  [FlagName(SERVICE_STOP_REASON_MINOR_SECURITY, 'Security')]
  [FlagName(SERVICE_STOP_REASON_MINOR_NETWORK_CONNECTIVITY, 'Network Connectivity')]
  [FlagName(SERVICE_STOP_REASON_MINOR_WMI, 'WMI')]
  [FlagName(SERVICE_STOP_REASON_MINOR_SERVICEPACK_UNINSTALL, 'Service Pack Uninstall')]
  [FlagName(SERVICE_STOP_REASON_MINOR_SOFTWARE_UPDATE_UNINSTALL, 'Update Uninstall')]
  [FlagName(SERVICE_STOP_REASON_MINOR_SECURITYFIX_UNINSTALL, 'Security Fix Uninstall')]
  [FlagName(SERVICE_STOP_REASON_MINOR_MMC, 'MMC')]
  [FlagName(SERVICE_STOP_REASON_MINOR_NONE, 'No Minor Reason')]
  [FlagName(SERVICE_STOP_REASON_MINOR_MEMOTYLIMIT, 'Memory Limit')]
  [FlagName(SERVICE_STOP_REASON_MAJOR_OTHER, 'Other Major Reason')]
  [FlagName(SERVICE_STOP_REASON_MAJOR_HARDWARE, 'Hardware Major Reason')]
  [FlagName(SERVICE_STOP_REASON_MAJOR_OPERATINGSYSTEM, 'OS Major Reason')]
  [FlagName(SERVICE_STOP_REASON_MAJOR_SOFTWARE, 'Software Major Reason')]
  [FlagName(SERVICE_STOP_REASON_MAJOR_APPLICATION, 'Application Major Reason')]
  [FlagName(SERVICE_STOP_REASON_MAJOR_NONE, 'No Major Reason')]
  [FlagName(SERVICE_STOP_REASON_FLAG_UNPLANNED, 'Unplanned')]
  [FlagName(SERVICE_STOP_REASON_FLAG_CUSTOM, 'Custom')]
  [FlagName(SERVICE_STOP_REASON_FLAG_PLANNED, 'Planned')]
  TServiceStopReason = type Cardinal;

  // SDK::winsvc.h
  [SDKName('SERVICE_CONTROL_STATUS_REASON_PARAMS')]
  TServiceControlStatusReasonParams = record
    [in] Reason: TServiceStopReason;
    [in, opt] Comment: PWideChar;
    [out] ServiceStatus: TServiceStatusProcess;
  end;
  PServiceControlStatusReasonParams = ^TServiceControlStatusReasonParams;

  [FlagName(SERVICE_NOTIFY_STOPPED, 'Stopped')]
  [FlagName(SERVICE_NOTIFY_START_PENDING, 'Start Pending')]
  [FlagName(SERVICE_NOTIFY_STOP_PENDING, 'Stop Pending')]
  [FlagName(SERVICE_NOTIFY_RUNNING, 'Running')]
  [FlagName(SERVICE_NOTIFY_CONTINUE_PENDING, 'Continue Pending')]
  [FlagName(SERVICE_NOTIFY_PAUSE_PENDING, 'Pause Pending')]
  [FlagName(SERVICE_NOTIFY_PAUSED, 'Paused')]
  [FlagName(SERVICE_NOTIFY_CREATED, 'Created')]
  [FlagName(SERVICE_NOTIFY_DELETED, 'Deleted')]
  [FlagName(SERVICE_NOTIFY_DELETE_PENDING, 'Delete Pending')]
  TServiceNotifyMask = type Cardinal;

  PServiceNotify = ^TServiceNotify; // see below

  // SDK::winsvc.h
  [SDKName('PFN_SC_NOTIFY_CALLBACK')]
  TFnScNotifyCallback = procedure (
    [in] Parameter: PServiceNotify
  ); stdcall;

  // SDK::winsvc.h
  [SDKName('SERVICE_NOTIFY')]
  TServiceNotify = record
    [in, Reserved(SERVICE_NOTIFY_STATUS_CHANGE)] Version: Cardinal;
    [in] NotifyCallback: TFnScNotifyCallback;
    [in, opt] Context: Pointer;
    [out] NotificationStatus: TWin32Error;
    [out] ServiceStatus: TServiceStatusProcess;
    [out] NotificationTriggered: TServiceNotifyMask;
    [out, ReleaseWith('LocalFree')] ServiceNames: PWideMultiSz;
  end;

  [SDKName('SERVICE_START_REASON')]
  [FlagName(SERVICE_START_REASON_DEMAND, 'Demand')]
  [FlagName(SERVICE_START_REASON_AUTO, 'Auto')]
  [FlagName(SERVICE_START_REASON_TRIGGER, 'Trigger')]
  [FlagName(SERVICE_START_REASON_RESTART_ON_FAILURE, 'Restart On Failure')]
  [FlagName(SERVICE_START_REASON_DELAYEDAUTO, 'Delayed Auto')]
  TServiceStartReason = type Cardinal;
  PServiceStartReason = ^TServiceStartReason;

  // SDK::winsvc.h
  [NamingStyle(nsSnakeCase, 'SERVICE_DYNAMIC_INFORMATION_LEVEL')]
  TServiceDynamicInfoLevel = (
    SERVICE_DYNAMIC_INFORMATION_LEVEL_START_REASON = 1 // q: TServiceStartReason
  );

  // PHNT::subprocesstag.h
  [SDKName('TAG_INFO_LEVEL')]
  [NamingStyle(nsCamelCase, 'eTagInfoLevel'), Range(1)]
  TTagInfoLevel = (
    eTagInfoLevelReserved = 0,
    eTagInfoLevelNameFromTag = 1,            // q: TTagInfoNameFromTag
    eTagInfoLevelNamesReferencingModule = 2, // q: TTagInfoNamesReferencingModule
    eTagInfoLevelNameTagMapping = 3          // q: TTagInfoNameTagMapping
  );

  // PHNT::subprocesstag.h
  [SDKName('TAG_TYPE')]
  [NamingStyle(nsCamelCase, 'eTagType'), Range(1)]
  TTagType = (
    eTagTypeReserved = 0,
    eTagTypeService = 1
  );

  // PHNT::subprocesstag.h
  [SDKName('TAG_INFO_NAME_FROM_TAG')]
  TTagInfoNameFromTag = record
    [in] Pid: TProcessId32;
    [in] Tag: TServiceTag;
    [out] TagType: TTagType;
    [out, ReleaseWith('LocalFree')] Name: PWideChar;
  end;
  PTagInfoNameFromTag = ^TTagInfoNameFromTag;

  // PHNT::subprocesstag.h
  [SDKName('TAG_INFO_NAMES_REFERENCING_MODULE')]
  TTagInfoNamesReferencingModule = record
    [in] Pid: TProcessId32;
    [in] Module: PWideChar;
    [out] TagType: TTagType;
    [out] Names: PWideMultiSz;
  end;
  PTagInfoNamesReferencingModule = ^TTagInfoNamesReferencingModule;

  [SDKName('TAG_INFO_NAME_TAG_MAPPING_ELEMENT')]
  TTagInfoNameTagMappingElement = record
    TagType: TTagType;
    Tag: TServiceTag;
    Name: PWideChar;
    GroupName: PWideChar;
  end;
  PTagInfoNameTagMappingElement = ^TTagInfoNameTagMappingElement;

  [SDKName('TAG_INFO_NAME_TAG_MAPPING_OUT_PARAMS')]
  TTagInfoNameTagMappingOutParams = record
    Elements: Cardinal;
    NameTagMappingElements: ^TAnysizeArray<TTagInfoNameTagMappingElement>;
  end;
  PTagInfoNameTagMappingOutParams = ^TTagInfoNameTagMappingOutParams;

  // PHNT::subprocesstag.h
  [SDKName('TAG_INFO_NAME_TAG_MAPPING')]
  TTagInfoNameTagMapping = record
    [in] Pid: TProcessId32;
    [out, ReleaseWith('LocalFree')] OutParams: PTagInfoNameTagMappingOutParams;
  end;
  PTagInfoNameTagMapping = ^TTagInfoNameTagMapping;

// SDK::winsvc.h
[SetsLastError]
function ChangeServiceConfigW(
  [in, Access(SERVICE_CHANGE_CONFIG)] hService: TScmHandle;
  [in] ServiceType: TServiceType;
  [in] StartType: TServiceStartType;
  [in] ErrorControl: TServiceErrorControl;
  [in, opt] BinaryPathName: PWideChar;
  [in, opt] LoadOrderGroup: PWideChar;
  [out, opt] pTagId: PCardinal;
  [in, opt] Dependencies: PWideMultiSz;
  [in, opt] ServiceStartName: PWideChar;
  [in, opt] Password: PWideChar;
  [in, opt] DisplayName: PWideChar
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function ChangeServiceConfig2W(
  [in, Access(SERVICE_CHANGE_CONFIG)] hService: TScmHandle;
  [in] InfoLevel: TServiceConfigLevel;
  [in, opt] pInfo: Pointer
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
function CloseServiceHandle(
  [in] hScObject: TScmHandle
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function ControlService(
  [in, Access(SERVICE_CONTROL_ANY)] hService: TScmHandle;
  [in] Control: TServiceControl;
  [out] out ServiceStatus: TServiceStatus
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
[Result: ReleaseWith('CloseServiceHandle')]
function CreateServiceW(
  [in, Access(SC_MANAGER_CREATE_SERVICE)] hSCManager: TScmHandle;
  [in] ServiceName: PWideChar;
  [in, opt] DisplayName: PWideChar;
  [in] DesiredAccess: TServiceAccessMask;
  [in] ServiceType: TServiceType;
  [in] StartType: TServiceStartType;
  [in] ErrorControl: TServiceErrorControl;
  [in, opt] BinaryPathName: PWideChar;
  [in, opt] LoadOrderGroup: PWideChar;
  [out, opt] pTagId: PCardinal;
  [in, opt] Dependencies: PWideMultiSz;
  [in, opt] ServiceStartName: PWideChar;
  [in, opt] Password: PWideChar
): TScmHandle; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function DeleteService(
  [in, Access(_DELETE)] hService: TScmHandle
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function EnumDependentServicesW(
  [in, Access(SERVICE_ENUMERATE_DEPENDENTS)] hService: TScmHandle;
  [in] ServiceState: TServiceEnumState;
  [out, WritesTo] Services: PEnumServiceStatusArray;
  [in, NumberOfBytes] BufSize: Cardinal;
  [out, NumberOfBytes] out BytesNeeded: Cardinal;
  [out, NumberOfElements] out ServicesReturned: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function EnumServicesStatusW(
  [in, Access(SC_MANAGER_ENUMERATE_SERVICE)] hSCManager: TScmHandle;
  [in] ServiceType: TServiceType;
  [in] ServiceState: TServiceEnumState;
  [out, WritesTo] Services: PEnumServiceStatusArray;
  [in, NumberOfBytes] BufSize: Cardinal;
  [out, NumberOfBytes] out BytesNeeded: Cardinal;
  [out, NumberOfElements] out ServicesReturned: Cardinal;
  [in, out, opt] ResumeHandle: PScEnumerationHandle
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function EnumServicesStatusExW(
  [in, Access(SC_MANAGER_ENUMERATE_SERVICE)] hSCManager: TScmHandle;
  [in] InfoLevel: TScEnumType;
  [in] ServiceType: TServiceType;
  [in] ServiceState: TServiceEnumState;
  [out, WritesTo] Services: Pointer;
  [in, NumberOfBytes] BufSize: Cardinal;
  [out, NumberOfBytes] out BytesNeeded: Cardinal;
  [out, NumberOfElements] out ServicesReturned: Cardinal;
  [in, out, opt] ResumeHandle: PScEnumerationHandle;
  [in, opt] GroupName: PWideChar
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function GetServiceKeyNameW(
  [in, Access(SC_MANAGER_CONNECT)] hSCManager: TScmHandle;
  [in] DisplayName: PWideChar;
  [out, WritesTo] ServiceName: PWideChar;
  [in, NumberOfElements] var chBuffer: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function GetServiceDisplayNameW(
  [in, Access(SC_MANAGER_CONNECT)] hSCManager: TScmHandle;
  [in] ServiceName: PWideChar;
  [out, WritesTo] DisplayName: PWideChar;
  [in, out, NumberOfElements] var cchBuffer: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
[Result: ReleaseWith('UnlockServiceDatabase')]
function LockServiceDatabase(
  [in, Access(SC_MANAGER_LOCK)] hScManager: TScmHandle
): TScLock; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
[Access(SC_MANAGER_MODIFY_BOOT_CONFIG)]
function NotifyBootConfigStatus(
  [in] BootAcceptable: LongBool
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
[Result: ReleaseWith('CloseServiceHandle')]
function OpenSCManagerW(
  [in, opt] MachineName: PWideChar;
  [in, opt] DatabaseName: PWideChar;
  [in] DesiredAccess: TScmAccessMask
): TScmHandle; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
[Result: ReleaseWith('CloseServiceHandle')]
function OpenServiceW(
  [in, Access(SC_MANAGER_CONNECT)] hSCManager: TScmHandle;
  [in] ServiceName: PWideChar;
  [in] DesiredAccess: TServiceAccessMask
): TScmHandle; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function QueryServiceConfigW(
  [in, Access(SERVICE_QUERY_CONFIG)] hService: TScmHandle;
  [out, WritesTo] ServiceConfig: PQueryServiceConfig;
  [in, NumberOfBytes] BufSize: Cardinal;
  [out, NumberOfBytes] out BytesNeeded: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function QueryServiceConfig2W(
  [in, Access(SERVICE_QUERY_CONFIG)] hService: TScmHandle;
  [in] InfoLevel: TServiceConfigLevel;
  [out, WritesTo] Buffer: Pointer;
  [in, NumberOfBytes] BufSize: Cardinal;
  [out, NumberOfBytes] out BytesNeeded: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function QueryServiceLockStatusW(
  [in, Access(SC_MANAGER_QUERY_LOCK_STATUS)] hSCManager: TScmHandle;
  [out, WritesTo] LockStatus: PQueryServiceLockStatus;
  [in, NumberOfBytes] BufSize: Cardinal;
  [out, NumberOfBytes] out BytesNeeded: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function QueryServiceObjectSecurity(
  [in, Access(OBJECT_READ_SECURITY)] hService: TScmHandle;
  [in] SecurityInformation: TSecurityInformation;
  [out, WritesTo] SecurityDescriptor: PSecurityDescriptor;
  [in, NumberOfBytes] BufSize: Cardinal;
  [out, NumberOfBytes] out BytesNeeded: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function QueryServiceStatus(
  [in, Access(SERVICE_QUERY_STATUS)] hService: TScmHandle;
  [out] out ServiceStatus: TServiceStatus
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function QueryServiceStatusEx(
  [in, Access(SERVICE_QUERY_STATUS)] hService: TScmHandle;
  [in] InfoLevel: TScStatusType;
  [out, WritesTo] Buffer: Pointer;
  [in, NumberOfBytes] BufSize: Cardinal;
  [out, NumberOfBytes] out BytesNeeded: Cardinal
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function RegisterServiceCtrlHandlerExW(
  [in] ServiceName: PWideChar;
  [in] HandlerProc: THandlerFunctionEx;
  [in, opt] Context: Pointer
): TServiceStatusHandle; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function SetServiceObjectSecurity(
  [in, Access(OBJECT_WRITE_SECURITY)] hService: TScmHandle;
  [in] SecurityInformation: TSecurityInformation;
  [in] SecurityDescriptor: PSecurityDescriptor
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function SetServiceStatus(
  [in] hServiceStatus: TServiceStatusHandle;
  [in] const ServiceStatus: TServiceStatus
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function StartServiceCtrlDispatcherW(
  [in] ServiceStartTable: PServiceTableEntry
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function StartServiceW(
  [in, Access(SERVICE_START)] hService: TScmHandle;
  [in, opt, NumberOfElements] NumServiceArgs: Cardinal;
  [in, opt, ReadsFrom] const ServiceArgVectors: TArray<PWideChar>
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function UnlockServiceDatabase(
  [in] ScLock: TScLock
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function NotifyServiceStatusChangeW(
  [in, Access(SC_MANAGER_ENUMERATE_SERVICE),
    Access(SERVICE_QUERY_STATUS)] hService: TScmHandle;
  [in] NotifyMask: TServiceNotifyMask;
  [in] NotifyBuffer: PServiceNotify
): TWin32Error; external advapi32;

// SDK::winsvc.h
[SetsLastError]
function ControlServiceExW(
  [in, Access(SERVICE_PAUSE_CONTINUE or SERVICE_STOP or SERVICE_INTERROGATE or
    SERVICE_USER_DEFINED_CONTROL)] hService: TScmHandle;
  [in] Control: TServiceControl;
  [in] InfoLevel: TServiceContolLevel;
  [in, out] ControlParams: Pointer
): LongBool; stdcall; external advapi32;

// SDK::winsvc.h
[SetsLastError]
[MinOSVersion(OsWin8)]
function QueryServiceDynamicInformation(
  [in] hServiceStatus: TServiceStatusHandle;
  [in] InfoLevel: TServiceDynamicInfoLevel;
  [out, ReleaseWith('LocalFree')] out DynamicInfo: Pointer
): LongBool; stdcall; external advapi32 delayed;

var delayed_QueryServiceDynamicInformation: TDelayedLoadFunction = (
  DllName: advapi32;
  FunctionName: 'QueryServiceDynamicInformation';
);

// PHNT::subprocesstag.h
[SetsLastError]
[Access(SC_MANAGER_ENUMERATE_SERVICE)]
function I_QueryTagInformation(
  [Reserved] MachineName: PWideChar;
  [in] InfoLevel: TTagInfoLevel;
  [in, out] TagInfo: Pointer
): TWin32Error; stdcall; external advapi32;

{ Expected Access Masks }

function ExpectedSvcControlAccess(
  [in] Control: TServiceControl
): TServiceAccessMask;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function ExpectedSvcControlAccess;
begin
  // MSDN
  case Control of
    SERVICE_CONTROL_PAUSE, SERVICE_CONTROL_CONTINUE,
    SERVICE_CONTROL_PARAM_CHANGE,
    SERVICE_CONTROL_NETBIND_ADD..SERVICE_CONTROL_NETBIND_DISABLE:
      Result := SERVICE_PAUSE_CONTINUE;

    SERVICE_CONTROL_STOP:
      Result := SERVICE_STOP;

    SERVICE_CONTROL_INTERROGATE:
      Result := SERVICE_INTERROGATE;
  else
    if (Cardinal(Control) >= 128) and (Cardinal(Control) < 255) then
      Result := SERVICE_USER_DEFINED_CONTROL
    else
      Result := 0;
  end;
end;

end.
