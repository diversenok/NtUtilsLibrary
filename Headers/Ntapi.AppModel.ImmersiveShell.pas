unit Ntapi.AppModel.ImmersiveShell;

{
  This module contains definitions for the immersive shell interfaces.
}

interface

uses
  Ntapi.WinNt, Ntapi.WinUser, Ntapi.ObjIdl, Ntapi.appmodel, Ntapi.Versions,
  DelphiApi.Reflection;

const
  // private, Win 8.1+
  CLSID_ImmersiveShell: TGuid = '{C2F03A33-21F5-47FA-B4BB-156362A2F239}';

  // private - immersive app behavior flags
  IABF_INVALID_AUTOGLOM_DESTINATION = $00000001;
  IABF_AVOID_VIEW_FOR_SWITCH = $00000002;
  IABF_EXEMPT_FROM_BACKSTACK_TRIM = $00000004;
  IABF_FORCE_TERMINATE_ON_CLOSE = $80000000;

type
  // private
  [MinOSVersion(OsWin10TH1)]
  IImmersiveApplicationWindow = interface (IUnknown)
    ['{C6636EC2-EBA1-4E6D-A995-8FA14B8B2891}']
    function GetBandId(
      [out] out BandId: TZBandId
    ): HResult; stdcall;

    function GetNativeWindow(
      [out] out Hwnd: THwnd
    ): HResult; stdcall;

    function GetApplicationId(
      [out] out AppId: PWideChar
    ): HResult; stdcall;

    function GetProcessId(
      [out] out ProcessId: TProcessId32
    ): HResult; stdcall;

    function GetThreadId(
      [out] out ThreadId: TThreadId32
    ): HResult; stdcall;
  end;

  IImmersiveMonitor = IUnknown;

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('IMMERSIVE_APPLICATION_GET_WINDOWS_FILTER')]
  [NamingStyle(nsSnakeCase, 'IAGWF')]
  TImmersiveApplicationGetWindowsFilter = (
    IAGWF_ANY = 0,
    IAGWF_STRONGLY_NAMED = 1,
    IAGWF_PREFER_PENDING_PRESENTED = 2, // Win 8.1+
    IAGWF_ONLY_PENDING_PRESENTED = 3,   // Win 8.1+
    IAGWF_PRESENTATION = 4,             // Win 10 TH1+
    IAGWF_FRAME = 5                     // Win 10 TH1+
  );

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('IMMAPPTIMESTAMPS')]
  TImmAppTimeStamps = record
    Creation: TLargeInteger;
    Closed: TLargeInteger;
    Activation: TLargeInteger;
    Inactive: TLargeInteger;
    Visible: TLargeInteger;
    Hidden: TLargeInteger;
  end;
  PImmAppTimeStamps = ^TImmAppTimeStamps;

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('IMMERSIVE_APPLICATION_QUERY_SERVICE_OPTION')]
  [NamingStyle(nsSnakeCase, 'IAQSO')]
  TImmersiveApplicationQueryServiceOption = (
    IAQSO_DEFAULT = 0,
    IAQSO_FIRST_PACKAGED = 1,
    IAQSO_ANY_PACKAGED = 2
  );

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('SPLASHSCREEN_ORIENTATION_PREFERENCE')]
  [NamingStyle(nsSnakeCase, 'SSOP')]
  TSplashscreenOrientationPreference = (
    SSOP_NONE = 0,
    SSOP_LANDSCAPE = 1,
    SSOP_PORTRAIT = 2,
    SSOP_LANDSCAPE_FLIPPED = 4,
    SSOP_PORTRAIT_FLIPPED = 8
  );

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('NOTIFY_IMMERSIVE_APPLICATION_WINDOWS_OPTION')]
  [NamingStyle(nsSnakeCase, 'NIAWO')]
  TNotifyImmersiveApplicationWindowsOption = (
    NIAWO_ALL = 0,
    NIAWO_SKIP_SYSTEM_WINDOWS = 1,
    NIAWO_CURRENT_WINDOW_ONLY = 2,
    NIAWO_CURRENT_WINDOW_ONLY_IFF_APP = 3
  );

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('NOTIFY_IMMERSIVE_APPLICATION_WINDOWS_DELIVERY_TYPE')]
  [NamingStyle(nsSnakeCase, 'NIAWDT')]
  TNotifyImmersiveApplicationWindowsDeliveryType = (
    NIAWDT_POST = 0,
    NIAWDT_SENDNOTIFY = 1
  );

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('IMMAPP_SETTHUMBNAIL_PREVIEW_STATE')]
  [NamingStyle(nsSnakeCase, 'IMMSPS')]
  TImmAppSetThumbnailPreviewState = (
    IMMSPS_VISIBLE = 0,
    IMMSPS_HIDDEN = 1
  );

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('MONITOR_CHANGE_FLAGS')]
  [NamingStyle(nsSnakeCase, 'MCF')]
  TMonitorChangeFlags = (
    MCF_FORCE = 0,
    MCF_IF_NOT_VISIBLE = 1
  );

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('GHOST_VISUAL_STYLE')]
  [NamingStyle(nsSnakeCase, '')]
  TGhostVisualStyle = (
    GVS_NORMAL = 0,
    GVS_USE_SPLASHSCREEN_VISUAL = 1,
    GVS_USE_SPLASHSCREEN_VISUAL_ONCE = 2
  );

  // private
  [SDKName('IMM_APP_BEHAVIOR_FLAGS')]
  [FlagName(IABF_INVALID_AUTOGLOM_DESTINATION, 'Invalid Autoglom Destination')]
  [FlagName(IABF_AVOID_VIEW_FOR_SWITCH, 'Avoid View For Switch')]
  [FlagName(IABF_EXEMPT_FROM_BACKSTACK_TRIM, 'Exempt From Backstack Trim')]
  [FlagName(IABF_FORCE_TERMINATE_ON_CLOSE, 'Force Terminate On Close')]
  TImmAppBehaviorFlags = type Cardinal;

  // private
  [MinOSVersion(OsWin10TH1)]
  IImmersiveApplication = interface (IUnknown)
    ['{8B14E88B-5663-4CAF-B196-C31479262831}']
    function GetWindows(
      [in] Filter: TImmersiveApplicationGetWindowsFilter;
      [in] const Iid: TIid;
      [out] out Windows
    ): HResult; stdcall;

    function GetApplicationId(
      [out] out AppId: PWideChar
    ): HResult; stdcall;

    function GetUniqueId(
      [out] out UniqueId: PWideChar
    ): HResult; stdcall;

    function OpenPropertyStore(
      [Reserved] OpenFlags: Cardinal; // IMMAPPPROPERTYSTOREFLAGS
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function IsRunning(
      [out] out Running: LongBool
    ): HResult; stdcall;

    function IsVisible(
      [out] out Visible: LongBool
    ): HResult; stdcall;

    function IsForeground(
      [out] out Foreground: LongBool
    ): HResult; stdcall;

    function GetTimestamps(
      [out] out TimeStamps: TImmAppTimeStamps
    ): HResult; stdcall;

    function IsEqualByAppId(
      [in] AppId: PWideChar;
      [out] out Equal: LongBool
    ): HResult; stdcall;

    function IsEqualByHwnd(
      [in] Hwnd: THwnd;
      [out] out Equal: LongBool
    ): HResult; stdcall;

    function IsEqualByApp(
      [in] const App: IImmersiveApplication;
      [out] out Equal: LongBool
    ): HResult; stdcall;

    function IsViewForSameApp(
      [in] const App: IImmersiveApplication;
      [out] out Equal: LongBool
    ): HResult; stdcall;

    function GetPackageId(
      [in] ReportIfTombstoned: LongBool;
      [out, ReleaseWith('CoTaskMemFree')] out PackageFullName: PWideChar
    ): HResult; stdcall;

    function BelongsToPackage(
      [in] PackageFullName: PWideChar;
      [out] out Belongs: LongBool
    ): HResult; stdcall;

    function QueryService(
      [in] Option: TImmersiveApplicationQueryServiceOption;
      [in] Timeout: Cardinal;
      [in] const ServiceId: TGuid;
      [in] const InterfaceId: TIid;
      [out] out pvObject
    ): HResult; stdcall;

    function IsServiceAvailable(
      [in] Option: TImmersiveApplicationQueryServiceOption;
      [in] const ServiceId: TGuid;
      [out] out ServiceAvailable: LongBool
    ): HResult; stdcall;

    function IsApplicationWindowStronglyNamed(
      [out] out StronglyNamed: LongBool
    ): HResult; stdcall;

    function ContainsStronglyNamedWindow(
      [out] out ContainsStronglyNamedWindow: LongBool
    ): HResult; stdcall;

    function IsInteractive(
      [out] out Interactive: LongBool
    ): HResult; stdcall;

    function GetManifestedOrientationPreference(
    ): TSplashscreenOrientationPreference; stdcall;

    function NotifyApplicationWindows(
      [in] uMessage: Cardinal;
      [in] wParam: NativeUInt;
      [in] lParam: NativeInt;
      [in] Options: TNotifyImmersiveApplicationWindowsOption;
      [in] DeliveryType: TNotifyImmersiveApplicationWindowsDeliveryType
    ): HResult; stdcall;

    function GetDestinationInformation(
      [out] out ApplicationWindow: IImmersiveApplicationWindow;
      [out] out DestinationPosition: TRect
    ): HResult; stdcall;

    function GetRect(
      [out] out Rect: TRect
    ): HResult; stdcall;

    function SetThumbnailPreviewState(
      [in] State: TImmAppSetThumbnailPreviewState
    ): HResult; stdcall;

    function GetViewData(
      [out] ImmApplicationViewData: Pointer // IMMAPP_APPLICATION_VIEW_DATA
    ): HResult; stdcall;

    function SetMonitor(
      [in] const Monitor: IImmersiveMonitor;
      [in] Flags: TMonitorChangeFlags
    ): HResult; stdcall;

    function GetMonitor(
      [out] out Monitor: IImmersiveMonitor
    ): HResult; stdcall;

    function SetGhostVisualStyle(
      [in] GhostVisualStyle: TGhostVisualStyle
    ): HResult; stdcall;

    function GetTitle(
      [out, ReleaseWith('CoTaskMemFree')] out Title: PWideChar
    ): HResult; stdcall;

    function GetBehaviorFlags(
      [out] out Flags: TImmAppBehaviorFlags
    ): HResult; stdcall;

    function AddBehaviorFlags(
      [in] Flags: TImmAppBehaviorFlags
    ): HResult; stdcall;

    function RemoveBehaviorFlags(
      [in] Flags: TImmAppBehaviorFlags
    ): HResult; stdcall;

    // More methods follow
  end;

  // private
  [MinOSVersion(OsWin81)]
  IImmersiveApplicationArray = interface (IObjectArray)
    ['{C6ED6DAC-8FAC-4598-A74C-69020137149C}']
    function GetApplication(
      [in] AppID: PWideChar;
      [out] out Application: IImmersiveApplication
    ): HResult; stdcall;

    function GetAllApplicationsByAppID(
      [in] AppID: PWideChar;
      [out] out ObjectArray: IObjectArray
    ): HResult; stdcall;

    function Contains(
      [in] const Application: IImmersiveApplication;
      [out] out Contains: LongBool
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin81)]
  IImmersiveApplicationArrayService = interface (IUnknown)
    ['{A3C23AB7-6BE2-4778-8EB0-1ADB7977F76A}']
    function GetImmersiveApplicationArray(
      [out] out AppArray: IImmersiveApplicationArray
    ): HResult; stdcall;

    function GetApplication(
      [in] AppId: PWideChar;
      [out] out Application: IImmersiveApplication
    ): HResult; stdcall;

    function GetAllApplicationsByAppID(
      [in] AppId: PWideChar;
      [out] out Applications: IObjectArray
    ): HResult; stdcall;

    function GetApplicationByWindow(
      [in] Hwnd: THwnd;
      [out] out Application: IImmersiveApplication
    ): HResult; stdcall;

    function GetRunningApplicationsFromPackageId(
      [in] PackageId: PWideChar;
      [out] out Applications: IImmersiveApplicationArray
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('ACTIVATION_MONITOR_PREFERENCE')]
  [NamingStyle(nsSnakeCase, 'AMP')]
  TActivationMonitorPreference = (
    AMP_NONE = 0,
    AMP_SOURCE_MONITOR = 1
  );

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('PLACE_MODE_OPTION')]
  [NamingStyle(nsSnakeCase, 'PMO')]
  TPlaceModeOption = (
    PMO_NONE = 0,
    PMO_ALLOW = 1,
    PMO_FORCE = 2,
    PMO_ALLOW_IF_REPLACE_MULTI = 3 // Win 10 TH1+
  );

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('REVERT_LAYOUT_OPTION')]
  [NamingStyle(nsSnakeCase, 'RLO')]
  TRevertLayoutOption = (
    RLO_DEFAULT = 0,
    RLO_TRYREVERT = 1
  );

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('SWITCH_APP_FLAGS')]
  [FlagName(SAF_NOACTIVATEDESKTOPAPP, 'No Activate Desktop App')]
  [FlagName(SAF_NOMOVEFOREGROUND, 'No Move Foreground')]
  [FlagName(SAF_NOANIMATE, 'No Animate')]
  [FlagName(SAF_DEFAULTSWITCHANIMATION, 'Default Switch Animation')]
  [FlagName(SAF_CROSSFADEANIMATION, 'Cross-fade Animation')]
  [FlagName(SAF_NORELAUNCH, 'No Relaunch')]
  [FlagName(SAF_SWITCHTOSEARCHRESULTS, 'Switch Search Results')]
  [FlagName(SAF_LAUNCHFROMSEARCHRESULTS, 'Launch From Search Results')]
  [FlagName(SAF_FORCECREATESCREEN, 'Force Create Screen')]
  [FlagName(SAF_INSERTIFFULLSCREEN, 'Insert If Fullscreen')]
  [FlagName(SAF_MAXIMIZEANIMATION, 'Maximize Animation')]
  [FlagName(SAF_REQUIREHIGHCONFIDENCE, 'Require High Confidence')]
  [FlagName(SAF_DESKTOPSTYLEANIMATION, 'Desktop Style Animation')]
  TSwitchAppFlags = type Cardinal;

  // private
  [MinOSVersion(OsWin81)]
  [SDKName('SWITCH_TO_APP_OPTIONS')]
  TSwitchToAppOption = record
    DefaultMonitor: IImmersiveMonitor;
    MonitorPreference: TActivationMonitorPreference;
    ActivateOptions: TActivateOptionsInternal;
    PlaceModeOption: TPlaceModeOption;
    RevertOption: TRevertLayoutOption;
    SwitchFlags: TSwitchAppFlags;
    HwndSource: THwnd;
    [MinOSVersion(OsWin10RS4)] ActivationContextSite: IUnknown;
    [Reserved] Padding: array [0..1] of NativeInt;
  end;
  PSwitchToAppOption = ^TSwitchToAppOption;

  // private
  [MinOSVersion(OsWin81)]
  ISwitchController = interface (IUnknown)
    ['{B9DAB75C-0932-4DBA-A5D1-8322C67511D0}']
    function SwitchToAppByIdWithArguments(
      [in] AppUserModelId: PWideChar;
      [in, opt] Arguments: PWideChar;
      [in] NotificationTargetId: PWideChar;
      [in] const Options: TSwitchToAppOption
    ): HResult; stdcall;

    // More methods follow
  end;

  [MinOSVersion(OsWin10TH1)]
  ISwitchControllerV2 = interface (ISwitchController)
    ['{15328F88-3846-45BE-AC4B-E083DCA20EC2}']
  end;

  [MinOSVersion(OsWin10RS3)]
  ISwitchControllerV3 = interface (ISwitchController)
    ['{29272895-960A-4854-9ACE-1B836680EE80}']
  end;

  [MinOSVersion(OsWin10RS4)]
  ISwitchControllerV4 = interface (ISwitchControllerV3)
    ['{53B23E1B-25E2-4886-9FB6-744B8F15571C}']
  end;

const
  // rev, Win 8.1+, for IImmersiveApplicationArrayService
  SID_ImmersiveApplicationArrayService = IImmersiveApplicationArrayService;

  // private, Win 8.1+, for ISwitchController
  SID_SwitchController: TGuid = '{9C33C4AB-BC91-4A79-BF47-7C90CEBC3AA3}';

implementation

end.
