unit Ntapi.ntpoapi;

{
  This file includes definitions for the system power management API.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.Versions, DelphiApi.Reflection;

const
  // WDK::ntpoapi.h - counted reason version
  DIAGNOSTIC_REASON_VERSION = 0;

  // WDK::ntpoapi.h - counted reason flags
  DIAGNOSTIC_REASON_SIMPLE_STRING = $00000001;
  DIAGNOSTIC_REASON_DETAILED_STRING = $00000002;
  DIAGNOSTIC_REASON_NOT_SPECIFIED = $80000000;

type
  // WDK::ntpoapi.h & PHNT::ntpoapi.h
  [SDKName('POWER_INFORMATION_LEVEL')]
  [NamingStyle(nsCamelCase)]
  TPowerInformationLevel = (
    SystemPowerPolicyAc = 0,
    SystemPowerPolicyDc = 1,
    VerifySystemPolicyAc = 2,
    VerifySystemPolicyDc = 3,
    SystemPowerCapabilities = 4,
    SystemBatteryState = 5,
    SystemPowerStateHandler = 6,
    ProcessorStateHandler = 7,
    SystemPowerPolicyCurrent = 8,
    AdministratorPowerPolicy = 9,
    SystemReserveHiberFile = 10,
    ProcessorInformation = 11,    // out: TProcessorPowerInformationArray (for the number of processors)
    SystemPowerInformation = 12,
    ProcessorStateHandler2 = 13,
    LastWakeTime = 14,
    LastSleepTime = 15,
    SystemExecutionState = 16,
    SystemPowerStateNotifyHandler = 17,
    ProcessorPowerPolicyAc = 18,
    ProcessorPowerPolicyDc = 19,
    VerifyProcessorPowerPolicyAc = 20,
    VerifyProcessorPowerPolicyDc = 21,
    ProcessorPowerPolicyCurrent = 22,
    SystemPowerStateLogging = 23,
    SystemPowerLoggingEntry = 24,
    SetPowerSettingValue = 25,
    NotifyUserPowerSetting = 26,
    PowerInformationLevelUnused0 = 27,
    SystemMonitorHiberBootPowerOff = 28,
    SystemVideoState = 29,
    TraceApplicationPowerMessage = 30,
    TraceApplicationPowerMessageEnd = 31,
    ProcessorPerfStates = 32,
    ProcessorIdleStates = 33,
    ProcessorCap = 34,
    SystemWakeSource = 35,
    SystemHiberFileInformation = 36,
    TraceServicePowerMessage = 37,
    ProcessorLoad = 38,
    PowerShutdownNotification = 39,
    MonitorCapabilities = 40,
    SessionPowerInit = 41,
    SessionDisplayState = 42,
    PowerRequestCreate = 43,  // in: TCountedReasonContext; out: THandle
    PowerRequestAction = 44,  // in: TPowerRequestAction
    GetPowerRequestList = 45,
    ProcessorInformationEx = 46,
    NotifyUserModeLegacyPowerEvent = 47,
    GroupPark = 48,
    ProcessorIdleDomains = 49,
    WakeTimerList = 50,
    SystemHiberFileSize = 51,
    ProcessorIdleStatesHv = 52,
    ProcessorPerfStatesHv = 53,
    ProcessorPerfCapHv = 54,
    ProcessorSetIdle = 55,
    LogicalProcessorIdling = 56,
    UserPresence = 57,
    PowerSettingNotificationName = 58,
    GetPowerSettingValue = 59,
    IdleResiliency = 60,
    SessionRITState = 61,
    SessionConnectNotification = 62,
    SessionPowerCleanup = 63,
    SessionLockState = 64,
    SystemHiberbootState = 65,
    PlatformInformation = 66,
    PdcInvocation = 67,
    MonitorInvocation = 68,
    FirmwareTableInformationRegistered = 69,
    SetShutdownSelectedTime = 70,
    SuspendResumeInvocation = 71,
    PlmPowerRequestCreate = 72,   // in: TCountedReasonContext; out: THandle, Windows 8+
    ScreenOff = 73,
    CsDeviceNotification = 74,
    PlatformRole = 75,
    LastResumePerformance = 76,
    DisplayBurst = 77,
    ExitLatencySamplingPercentage = 78,
    RegisterSpmPowerSettings = 79,
    PlatformIdleStates = 80,
    ProcessorIdleVeto = 81,
    PlatformIdleVeto = 82,
    SystemBatteryStatePrecise = 83,
    ThermalEvent = 84 ,
    PowerRequestActionInternal = 85,
    BatteryDeviceState = 86,
    PowerInformationInternal = 87,
    ThermalStandby = 88,
    SystemHiberFileType = 89,
    PhysicalPowerButtonPress = 90,
    QueryPotentialDripsConstraint = 91,
    EnergyTrackerCreate = 92,
    EnergyTrackerQuery = 93,
    UpdateBlackBoxRecorder = 94,
    SessionAllowExternalDmaDevices = 95,
    SendSuspendResumeNotification = 96,
    BlackBoxRecorderDirectAccessBuffer = 97
  );

  // WDK::ntpoapi.h - info class 11
  [SDKName('PROCESSOR_POWER_INFORMATION')]
  TProcessorPowerInformation = record
    Number: Cardinal;
    MaxMhz: Cardinal;
    CurrentMhz: Cardinal;
    MhzLimit: Cardinal;
    MaxIdleState: Cardinal;
    CurrentIdleState: Cardinal;
  end;
  PProcessorPowerInformation = ^TProcessorPowerInformation;
  TProcessorPowerInformationArray = TAnysizeArray<TProcessorPowerInformation>;
  PProcessorPowerInformationArray = ^TProcessorPowerInformationArray;

  [FlagName(DIAGNOSTIC_REASON_SIMPLE_STRING, 'Simple String')]
  [FlagName(DIAGNOSTIC_REASON_DETAILED_STRING, 'Detailed String')]
  [FlagName(DIAGNOSTIC_REASON_NOT_SPECIFIED, 'Not Specified')]
  TCountedReasonContextFlags = type Cardinal;

  // WDK::ntpoapi.h - info class 43
  [SDKName('COUNTED_REASON_CONTEXT')]
  TCountedReasonContext = record
    [Reserved(DIAGNOSTIC_REASON_VERSION)] Version: Cardinal;
  case Flags: TCountedReasonContextFlags of
    DIAGNOSTIC_REASON_SIMPLE_STRING: (
      SimpleString: TNtUnicodeString
    );

    DIAGNOSTIC_REASON_DETAILED_STRING: (
      ResourceFileName: TNtUnicodeString;
      ResourceReasonId: Word;
      [NumberOfElements] StringCount: Cardinal;
      ReasonStrings: PNtUnicodeStringArray;
    );
  end;
  PCountedReasonContext = ^TCountedReasonContext;

  // PHNT::ntpoapi.h
  [SDKName('POWER_REQUEST_TYPE_INTERNAL')]
  [NamingStyle(nsCamelCase, 'PowerRequest', 'Internal'), ValidBits([0..5, 8])]
  TPowerRequestTypeInternal = (
    PowerRequestDisplayRequiredInternal = 0,
    PowerRequestSystemRequiredInternal = 1,
    PowerRequestAwayModeRequiredInternal = 2,
    PowerRequestExecutionRequiredInternal = 3,    // Windows 8+
    PowerRequestPerfBoostRequiredInternal = 4,    // Windows 8+
    PowerRequestActiveLockScreenInternal = 5,     // Windows 10 RS1+ (reserved on Windows 8)
    PowerRequestReserved6, PowerRequestReserved7, // Windows 8 only
    PowerRequestFullScreenVideoRequired = 8       // Windows 8 only
  );

  // PHNT::ntpoapi.h - info class 44
  [SDKName('POWER_REQUEST_ACTION')]
  TPowerRequestAction = record
    PowerRequestHandle: THandle;
    RequestType: TPowerRequestTypeInternal;
    SetAction: Boolean;
    [MinOSVersion(OsWin8), Access(PROCESS_SET_LIMITED_INFORMATION)]
      ProcessHandle: THandle; // Windows 8+ and only for requests created via PlmPowerRequestCreate
  end;

// WDK::ntpoapi.h
function NtPowerInformation(
  [in] InformationLevel: TPowerInformationLevel;
  [in, ReadsFrom] InputBuffer: Pointer;
  [in, NumberOfBytes] InputBufferLength: Cardinal;
  [out, WritesTo] OutputBuffer: Pointer;
  [in, NumberOfBytes] OutputBufferLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
