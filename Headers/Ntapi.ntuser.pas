unit Ntapi.ntuser;

{
  This file provides definitions for Native User and GDI functions
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.WinUser, DelphiApi.Reflection,
  DelphiApi.DelayLoad, Ntapi.Versions;

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

const
  win32u = 'win32u.dll';

  // PHNT::ntrtl.h - atom flags
  RTL_ATOM_PINNED = $0001;
  RTL_ATOM_GLOBAL = $0002; // rev

  // rev - NtUserMessageCall function numbers
  FNID_SENDMESSAGE = $000002B1; // xParam: void
  FNID_SENDMESSAGEFF = $000002B2; // xParam: TSndMsgTimeout
  FNID_SENDMESSAGEEX = $000002B3; // xParam: TSndMsgTimeout

  // rev, thread desktop flags
  TDF_PROTECT_HANDLE = $00000001;

  // SDK::WinUser.h - clipboard formats
  CF_TEXT = 1;
  CF_OEMTEXT = 7;
  CF_UNICODETEXT = 13;

  // private - hook flags
  HF_ANSI = $0002;
  HF_EXTENDED_TIMEOUT = $0040; // rev // Win 10 21H1+

var
  delayed_win32u: TDelayedLoadDll = (DllName: win32u);

type
  TMemHandle = THandle;

  [SubEnum(MAX_UINT, FNID_SENDMESSAGEFF, 'FNID_SENDMESSAGEFF')]
  [SubEnum(MAX_UINT, FNID_SENDMESSAGEEX, 'FNID_SENDMESSAGEEX')]
  TMessageCallFunctionId = type Cardinal;

  // private
  [SDKName('SNDMSGTIMEOUT')]
  TSndMsgTimeout = record
    Flags: TSendMessageOptions;
    Timeout: Cardinal;
    SMTOReturn: NativeUInt;
    SMTOResult: NativeUInt;
  end;
  PSndMsgTimeout = ^TSndMsgTimeout;

  [FlagName(TDF_PROTECT_HANDLE, 'Protect')]
  TThreadDesktopFlags = type Cardinal;

  // private
  [SDKName('NAMELIST')]
  TNameList = record
    [RecordSize] cb: Cardinal;
    Count: Cardinal;
    Names: TAnysizeArray<WideChar>;
  end;
  PNameList = ^TNameList;

  // PHNT::ntexapi.h
  [SDKName('ATOM_INFORMATION_CLASS')]
  TAtomInformationClass = (
    AtomBasicInformation = 0, // q: TAtomBasicInformation
    AtomTableInformation = 1  // q: TAtomTableInformation
  );

  [NamingStyle(nsSnakeCase, 'RTL_ATOM')]
  [FlagName(RTL_ATOM_PINNED, 'RTL_ATOM_PINNED')]
  [FlagName(RTL_ATOM_GLOBAL, 'RTL_ATOM_GLOBAL')]
  TAtomFlags = type Word;

  [InheritsFrom(System.TypeInfo(TAtomFlags))]
  TAtomFlags32 = type Cardinal;

  // PHNT::ntexapi.h
  [SDKName('ATOM_BASIC_INFORMATION')]
  TAtomBasicInformation = record
    UsageCount: Word;
    Flags: TAtomFlags;
    [NumberOfBytes] NameLength: Word;
    Name: TAnysizeArray<WideChar>;
  end;
  PAtomBasicInformation = ^TAtomBasicInformation;

  // PHNT::ntexapi.h
  [SDKName('ATOM_TABLE_INFORMATION')]
  TAtomTableInformation = record
    NumberOfAtoms: Cardinal;
    Atoms: TAnysizeArray<Word>;
  end;
  PAtomTableInformation = ^TAtomTableInformation;

  // private
  [SDKName('PROPSET')]
  TPropSet = record
    Data: NativeUInt;
    Atom: Word;
  end;
  PPropSet = ^TPropSet;

  [SubEnum(MAX_UINT, CF_TEXT, 'CF_TEXT')]
  [SubEnum(MAX_UINT, CF_TEXT, 'CF_OEMTEXT')]
  [SubEnum(MAX_UINT, CF_TEXT, 'CF_UNICODETEXT')]
  TClipboardFormat = type Cardinal;

  // private
  [SDKName('GETCLIPBDATA')]
  TGetClipbData = record
    FmtRet: TClipboardFormat;
    GlobalHandle: LongBool;
    hLocale: NativeUInt;
  end;
  PGetClipbData = ^TGetClipbData;

  // private
  [SDKName('WINDOWINFOCLASS')]
  [NamingStyle(nsCamelCase, 'Window')]
  TWindowInfoClass = (
    WindowProcess = 0,            // q: TProcessId
    WindowRealProcess = 1,        // q: TProcessId
    WindowThread = 2,             // q: TThreadId
    WindowActiveWindow = 3,       // q: THwnd
    WindowFocusWindow = 4,        // q: THwnd
    WindowIsHung = 5,             // q: Boolean
    WindowClientBase = 6,
    WindowIsForegroundThread = 7, // q: Boolean
    WindowDefaultImeWindow = 8,   // q: THwnd
    WindowDefaultInputContext = 9
  );

  // private
  [SDKName('CONSOLECONTROL')]
  [NamingStyle(nsCamelCase, 'Console')]
  TConsoleControl = (
    ConsoleSetVDMCursorBounds = 0,
    ConsoleNotifyConsoleApplication = 1,
    ConsoleFullscreenSwitch = 2,
    ConsoleSetCaretInfo = 3,
    ConsoleSetReserveKeys = 4,
    ConsoleSetForeground = 5,
    ConsoleSetWindowOwner = 6, // in: TConsoleSetWindowOwner
    ConsoleEndTask = 7
  );

  // rev // indexes for 20H1+ only!
  [MinOSVersion(OsWin1020H1)]
  [NamingStyle(nsPreserveCase, 'SFI_')]
  TUserCallIndex = (
    SFI_NtUserCreateMenu = 0, // NoParam
    SFI_NtUserCreatePopupMenu = 1, // NoParam
    SFI_NtUserAllowForegroundActivation = 2, // NoParam
    SFI_NtUserCancelQueueEventCompletionPacket = 3, // NoParam
    SFI_NtUserClearWakeMask = 4, // NoParam
    SFI_NtUserCreateSystemThreads = 5, // NoParam
    SFI_NtUserDestroyCaret = 6, // NoParam
    SFI_NtUserDisableProcessWindowsGhosting = 7, // NoParam
    SFI_NtUserDrainThreadCoreMessagingCompletions = 8, // NoParam
    SFI_NtUserGetDeviceChangeInfo = 9, // NoParam
    SFI_NtUserGetIMEShowStatus = 10, // NoParam
    SFI_NtUserGetInputDesktop = 11, // NoParam
    SFI_NtUserGetMessagePos = 12, // NoParam
    SFI_NtUserGetQueueIocp = 13, // NoParam
    SFI_NtUserGetUnpredictedMessagePos = 14, // NoParam
    SFI_NtUserHandleSystemThreadCreationFailure = 15, // NoParam
    SFI_NtUserHideCursorNoCapture = 16, // NoParam
    SFI_NtUserIsQueueAttached = 17, // NoParam
    SFI_NtUserLoadCursorsAndIcons = 18, // NoParam
    SFI_NtUserLoadUserApiHook = 19, // NoParam
    SFI_NtUserPrepareForLogoff = 20, // NoParam
    SFI_NtUserReassociateQueueEventCompletionPacket = 21, // NoParam
    SFI_NtUserReleaseCapture = 22, // NoParam
    SFI_NtUserRemoveQueueCompletion = 23, // NoParam
    SFI_NtUserResetDblClk = 24, // NoParam
    SFI_NtUserZapActiveAndFocus = 25, // NoParam
    SFI_NtUserRemoteConsoleShadowStop = 26, // NoParam
    SFI_NtUserRemoteDisconnect = 27, // NoParam
    [Reserved] SFI_28 = 28, // NoParam
    [Reserved] SFI_29 = 29, // NoParam
    SFI_NtUserRemoteShadowSetup = 30, // NoParam
    SFI_NtUserRemoteShadowStop = 31, // NoParam
    SFI_NtUserRemotePassthruEnable = 32, // NoParam
    SFI_NtUserRemotePassthruDisable = 33, // NoParam
    SFI_NtUserRemoteConnectState = 34, // NoParam
    [Reserved] SFI_35 = 35, // NoParam
    SFI_NtUserUpdatePerUserImmEnabling = 36, // NoParam
    SFI_NtUserUserPowerCalloutWorker = 37, // NoParam
    SFI_NtUserWakeRITForShutdown = 38, // NoParam
    SFI_NtUserDoInitMessagePumpHook = 39, // NoParam
    SFI_NtUserDoUninitMessagePumpHook = 40, // NoParam
    SFI_NtUserEnableMouseInPointerForThread = 41, // NoParam
    SFI_NtUserDeferredDesktopRotation = 42, // NoParam
    SFI_NtUserEnablePerMonitorMenuScaling = 43, // NoParam
    SFI_NtUserBeginDeferWindowPos = 44, // OneParam
    SFI_NtUserGetSendMessageReceiver = 45, // OneParam
    SFI_NtUserAllowSetForegroundWindow = 46, // OneParam
    SFI_NtUserCsDdeUninitialize = 47, // OneParam
    [Reserved] SFI_48 = 48, // OneParam
    SFI_NtUserEnumClipboardFormats = 49, // OneParam
    SFI_NtUserGetInputEvent = 50, // OneParam
    SFI_NtUserGetKeyboardType = 51, // OneParam
    SFI_NtUserGetProcessDefaultLayout = 52, // OneParam
    SFI_NtUserGetWinStationInfo = 53, // OneParam
    SFI_NtUserLockSetForegroundWindow = 54, // OneParam
    SFI_NtUserLW_LoadFonts = 55, // OneParam
    SFI_NtUserMapDesktopObject = 56, // OneParam
    SFI_NtUserMessageBeep = 57, // OneParam
    SFI_NtUserPlayEventSound = 58, // OneParam
    SFI_NtUserPostQuitMessage = 59, // OneParam
    SFI_NtUserRealizePalette = 60, // OneParam
    SFI_NtUserRegisterLPK = 61, // OneParam
    SFI_NtUserRegisterSystemThread = 62, // OneParam
    SFI_NtUserRemoteReconnect = 63, // OneParam
    SFI_NtUserRemoteThinwireStats = 64, // OneParam
    SFI_NtUserRemoteNotify = 65, // OneParam
    SFI_NtUserReplyMessage = 66, // OneParam
    SFI_NtUserSetCaretBlinkTime = 67, // OneParam
    SFI_NtUserSetDoubleClickTime = 68, // OneParam
    SFI_NtUserSetMessageExtraInfo = 69, // OneParam
    SFI_NtUserSetProcessDefaultLayout = 70, // OneParam
    SFI_NtUserSetWatermarkStrings = 71, // OneParam
    SFI_NtUserShowStartGlass = 72, // OneParam
    SFI_NtUserSwapMouseButton = 73, // OneParam
    SFI_NtUserWOWModuleUnload = 74, // OneParam
    SFI_NtUserDwmLockScreenUpdates = 75, // OneParam
    SFI_NtUserEnableSessionForMMCSS = 76, // OneParam
    SFI_NtUserSetWaitForQueueAttach = 77, // OneParam
    SFI_NtUserThreadMessageQueueAttached = 78, // OneParam
    [Reserved] SFI_79 = 79, // OneParam
    SFI_NtUserEnsureDpiDepSysMetCacheForPlateau = 80, // OneParam
    SFI_NtUserForceEnableNumpadTranslation = 81, // OneParam
    SFI_NtUserSetTSFEventState = 82, // OneParam
    SFI_NtUserSetShellChangeNotifyHWND = 83, // OneParam
    SFI_NtUserDeregisterShellHookWindow = 84, // Hwnd
    SFI_NtUserDWP_GetEnabledPopupOffset = 85, // Hwnd
    SFI_NtUserGetModernAppWindow = 86, // Hwnd
    SFI_NtUserGetWindowContextHelpId = 87, // Hwnd
    SFI_NtUserRegisterShellHookWindow = 88, // Hwnd
    SFI_NtUserSetMsgBox = 89, // Hwnd
    SFI_NtUserInitThreadCoreMessagingIocp = 90, // Hwnd, HwndSafe
    SFI_NtUserScheduleDispatchNotification = 91, // Hwnd, HwndSafe
    SFI_NtUserSetProgmanWindow = 92, // HwndOpt
    SFI_NtUserSetTaskmanWindow = 93, // HwndOpt
    SFI_NtUserGetClassIcoCur = 94, // HwndParam
    SFI_NtUserClearWindowState = 95, // HwndParam
    SFI_NtUserKillSystemTimer = 96, // HwndParam
    SFI_NtUserNotifyOverlayWindow = 97, // HwndParam
    [Reserved] SFI_98 = 98, // HwndParam
    SFI_NtUserSetDialogPointer = 99, // HwndParam
    SFI_NtUserSetVisible = 100, // HwndParam
    SFI_NtUserSetWindowContextHelpId = 101, // HwndParam
    SFI_NtUserSetWindowState = 102, // HwndParam
    SFI_NtUserRegisterWindowArrangementCallout = 103, // HwndParam
    SFI_NtUserEnableModernAppWindowKeyboardIntercept = 104, // HwndParam
    SFI_NtUserArrangeIconicWindows = 105, // HwndLock
    SFI_NtUserDrawMenuBar = 106, // HwndLock
    SFI_NtUserCheckImeShowStatusInThread = 107, // HwndLock, HwndLockSafe
    SFI_NtUserGetSysMenuOffset = 108, // HwndLock
    SFI_NtUserRedrawFrame = 109, // HwndLock
    SFI_NtUserRedrawFrameAndHook = 110, // HwndLock
    SFI_NtUserSetDialogSystemMenu = 111, // HwndLock
    SFI_NtUserSetForegroundWindow = 112, // HwndLock
    SFI_NtUserSetSysMenu = 113, // HwndLock
    SFI_NtUserUpdateClientRect = 114, // HwndLock
    SFI_NtUserUpdateWindow = 115, // HwndLock
    SFI_NtUserSetCancelRotationDelayHintWindow = 116, // HwndLock
    SFI_NtUserGetWindowTrackInfoAsync = 117, // HwndLock
    SFI_NtUserBroadcastImeShowStatusChange = 118, // HwndParamLock
    SFI_NtUserSetModernAppWindow = 119, // HwndParamLock
    SFI_NtUserRedrawTitle = 120, // HwndParamLock
    SFI_NtUserShowOwnedPopups = 121, // HwndParamLock
    SFI_NtUserSwitchToThisWindow = 122, // HwndParamLock
    SFI_NtUserUpdateWindows = 123, // HwndParamLock
    SFI_NtUserValidateRgn = 124, // HwndParamLock
    SFI_NtUserEnableWindow = 125, // HwndParamLock, HwndParamLockSafe
    SFI_NtUserChangeWindowMessageFilter = 126, // TwoParam
    SFI_NtUserGetCursorPos = 127, // TwoParam
    SFI_NtUserInitAnsiOem = 128, // TwoParam
    SFI_NtUserNlsKbdSendIMENotification = 129, // TwoParam
    SFI_NtUserRegisterGhostWindow = 130, // TwoParam
    SFI_NtUserRegisterLogonProcess = 131, // TwoParam
    SFI_NtUserRegisterSiblingFrostWindow = 132, // TwoParam
    SFI_NtUserRegisterUserHungAppHandlers = 133, // TwoParam
    SFI_NtUserRemoteShadowCleanup = 134, // TwoParam
    SFI_NtUserRemoteShadowStart = 135, // TwoParam
    SFI_NtUserSetCaretPos = 136, // TwoParam
    SFI_NtUserSetThreadQueueMergeSetting = 137, // TwoParam
    SFI_NtUserUnhookWindowsHook = 138, // TwoParam
    SFI_NtUserEnableShellWindowManagementBehavior = 139, // TwoParam
    SFI_NtUserCitSetInfo = 140, // TwoParam
    SFI_NtUserScaleSystemMetricForDPIWithoutCache = 141 // TwoParam
  );

  // private
  [SDKName('CONSOLESETWINDOWOWNER')]
  TConsoleSetWindowOwner = record
    hwnd: THwnd;
    ProcessId: TProcessId32;
    ThreadId: TThreadId32;
  end;

  [NamingStyle(nsSnakeCase, 'HF')]
  [FlagName(HF_ANSI, 'HF_ANSI')]
  [FlagName(HF_EXTENDED_TIMEOUT, 'HF_EXTENDED_TIMEOUT')]
  THookFlags = type Cardinal;

const
  // rev
  SFI_NoParam = [SFI_NtUserCreateMenu..SFI_NtUserEnablePerMonitorMenuScaling];
  SFI_OneParam = [SFI_NtUserBeginDeferWindowPos..SFI_NtUserSetShellChangeNotifyHWND];
  SFI_Hwnd = [SFI_NtUserDeregisterShellHookWindow..SFI_NtUserScheduleDispatchNotification];
  SFI_HwndOpt = [SFI_NtUserSetProgmanWindow..SFI_NtUserSetTaskmanWindow];
  SFI_HwndParam = [SFI_NtUserGetClassIcoCur..SFI_NtUserEnableModernAppWindowKeyboardIntercept];
  SFI_HwndLock = [SFI_NtUserArrangeIconicWindows..SFI_NtUserGetWindowTrackInfoAsync];
  SFI_HwndParamLock = [SFI_NtUserBroadcastImeShowStatusChange..SFI_NtUserEnableWindow];
  SFI_TwoParam = [SFI_NtUserChangeWindowMessageFilter..SFI_NtUserScaleSystemMetricForDPIWithoutCache];

{ Window Stations }

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: ReleaseWith('NtClose')]
function NtUserOpenWindowStation(
  [in] const ObjectAttributes: TObjectAttributes;
  [in] DesiredAccess: TWinStaAccessMask
): THandle; stdcall; external win32u delayed;

var delayed_NtUserOpenWindowStation: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserOpenWindowStation';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: ReleaseWith('NtClose')]
function NtUserGetProcessWindowStation(
): THandle; stdcall; external win32u delayed;

var delayed_NtUserGetProcessWindowStation: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetProcessWindowStation';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserSetProcessWindowStation(
  [in] hWinSta: THandle
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserSetProcessWindowStation: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserSetProcessWindowStation';
);

{ Common }

// PHNT::ntkepai.h
function NtCallbackReturn(
  [in, ReadsFrom] OutputBuffer: Pointer;
  [in, NumberOfBytes] OutputLength: Cardinal;
  [in] Status: NTSTATUS
): NTSTATUS; stdcall; external ntdll;

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetObjectInformation(
  [in] hObject: THandle;
  [in] nIndex: TUserObjectInfoClass;
  [out, WritesTo] Info: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [out, opt, NumberOfBytes] LengthNeeded: PCardinal
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserGetObjectInformation: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetObjectInformation';
);

// private
[MinOSVersion(OsWin10RS1)]
function NtUserBuildNameList(
  [opt, Access(WINSTA_ENUMDESKTOPS)] hWinSta: THandle;
  [in, NumberOfBytes] BufferSize: Cardinal;
  [out, WritesTo] Buffer: PNameList;
  [out, NumberOfBytes] out RequiredSize: Cardinal
): NTSTATUS; stdcall; external win32u delayed;

var delayed_NtUserBuildNameList: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserBuildNameList';
);

{ Desktops }

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetThreadDesktop(
  [in] ThreadId: TThreadId32
): THandle; stdcall; external win32u delayed;

var delayed_NtUserGetThreadDesktop: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetThreadDesktop';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserSetThreadDesktop(
  [in] hDesktop: THandle
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserSetThreadDesktop: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserSetThreadDesktop';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: ReleaseWith('NtClose')]
function NtUserOpenDesktop(
  [in] const ObjectAttributes: TObjectAttributes;
  [in] Flags: TDesktopOpenOptions;
  [in] DesiredAccess: TDesktopAccessMask
): THandle; stdcall; external win32u delayed;

var delayed_NtUserOpenDesktop: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserOpenDesktop';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: ReleaseWith('NtClose')]
function NtUserOpenInputDesktop(
  [in] Flags: TDesktopOpenOptions;
  [in] fInherit: LongBool;
  [in] DesiredAccess: TDesktopAccessMask
): THandle; stdcall; external win32u delayed;

var delayed_NtUserOpenInputDesktop: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserOpenInputDesktop';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: ReleaseWith('NtClose')]
function NtUserCreateDesktopEx(
  [in] const ObjectAttributes: TObjectAttributes;
  [Reserved] DeviceName: PNtUnicodeString;
  [Reserved] DevMode: Pointer;
  [in] Flags: TDesktopOpenOptions;
  [in] DesiredAccess: TDesktopAccessMask;
  [in] HeapSizeKB: Cardinal
): THandle; stdcall; external win32u delayed;

var delayed_NtUserCreateDesktopEx: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCreateDesktopEx';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: ReleaseWith('NtClose')]
function NtUserOpenThreadDesktop(
  [in] ThreadId: TThreadId32;
  [in] Flags: TThreadDesktopFlags;
  [in] Inherit: LongBool;
  [in] DesiredAccess: TDesktopAccessMask
): THandle; stdcall; external win32u delayed;

var delayed_NtUserOpenThreadDesktop: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserOpenThreadDesktop';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserSwitchDesktop(
  [in, Access(DESKTOP_SWITCHDESKTOP)] hDesktop: THandle;
  [in, opt] Duration: Cardinal;
  [in, opt] TransitionType: Cardinal
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserSwitchDesktop: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserSwitchDesktop';
);

{ Windows }

// private
[MinOSVersion(OsWin10RS1)]
function NtUserBuildHwndList(
  [in, opt, Access(DESKTOP_READOBJECTS)] hDesktop: THandle;
  [in, opt] hwndNext: THwnd;
  [in] EnumChildren: LongBool;
  [in] CheckImmersiveWindowAccess: LongBool;
  [in, opt] ThreadId: TThreadId32;
  [in, NumberOfElements] cHwndMax: Cardinal;
  [out, WritesTo] hwndFirst: TArray<THwnd>;
  [out, NumberOfElements] out cHwndNeeded: Cardinal
): NTSTATUS; stdcall; external win32u delayed;

var delayed_NtUserBuildHwndList: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserBuildHwndList';
);

// rev
[MinOSVersion(OsWin10RS4)]
function NtUserGetWindowProcessHandle(
  hWnd: THwnd;
  DesiredAccess: TProcessAccessMask
): THandle; stdcall; external win32u delayed;

var delayed_NtUserGetWindowProcessHandle: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetWindowProcessHandle';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserQueryWindow(
  [in] hWnd: THwnd;
  [in] WindowInfo: TWindowInfoClass
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserQueryWindow: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserQueryWindow';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserConsoleControl(
  [in] ConsoleCommand: TConsoleControl;
  [in, out, ReadsFrom, WritesTo] ConsoleInformation: Pointer;
  [in] ConsoleInformationLength: Cardinal
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserConsoleControl: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserConsoleControl';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetTopLevelWindow(
  [in] hWnd: THwnd
): THwnd; stdcall; external win32u delayed;

var delayed_NtUserGetTopLevelWindow: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetTopLevelWindow';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserIsTopLevelWindow(
  [in] hWnd: THwnd
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserIsTopLevelWindow: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserIsTopLevelWindow';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserWindowFromPoint(
  [in] Point: TPoint
): THwnd; stdcall; external win32u delayed;

var delayed_NtUserWindowFromPoint: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserWindowFromPoint';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserChildWindowFromPointEx(
  [in] hwndParent: THwnd;
  [in] Point: TPoint;
  [in] Flags: TChildWindowFromPointFlags
): THwnd; stdcall; external win32u delayed;

var delayed_NtUserChildWindowFromPointEx: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserChildWindowFromPointEx';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetForegroundWindow(
): THwnd; stdcall; external win32u delayed;

var delayed_NtUserGetForegroundWindow: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetForegroundWindow';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserSetChildWindowNoActivate(
  [in] hwnd: THwnd
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserSetChildWindowNoActivate: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserSetChildWindowNoActivate';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserInternalGetWindowIcon(
  [in] hwnd: THwnd;
  [in] iconType: TIconType
): THIcon; stdcall; external win32u delayed;

var delayed_NtUserInternalGetWindowIcon: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserInternalGetWindowIcon';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: NumberOfElements]
function NtUserInternalGetWindowText(
  [in] hwnd: THwnd;
  [out, WritesTo] lpString: PWideChar;
  [in, NumberOfElements] MaxCount: Cardinal
): Cardinal; stdcall; external win32u delayed;

var delayed_NtUserInternalGetWindowText: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserInternalGetWindowText';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGhostWindowFromHungWindow(
  [in] hwnd: THwnd
): THwnd; stdcall; external win32u delayed;

var delayed_NtUserGhostWindowFromHungWindow: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGhostWindowFromHungWindow';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserHungWindowFromGhostWindow(
  [in] hwndGhost: THwnd
): THwnd; stdcall; external win32u delayed;

var delayed_NtUserHungWindowFromGhostWindow: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserHungWindowFromGhostWindow';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserAlterWindowStyle(
  [in] hwnd: THwnd;
  [in] mask: TWindowStyle;
  [in] flags: TWindowStyle
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserAlterWindowStyle: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserAlterWindowStyle';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: NumberOfElements]
function NtUserGetClassName(
  [in] hwnd: THwnd;
  [in] bReal: LongBool;
  [in, out] var pstrClassName: TNtUnicodeString
): Cardinal; stdcall; external win32u delayed;

var delayed_NtUserGetClassName: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetClassName';
);

// private // UserAtomTableHandle
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserRegisterWindowMessage(
  [in] const strMessage: TNtUnicodeString
): Cardinal; stdcall; external win32u delayed;

var delayed_NtUserRegisterWindowMessage: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserRegisterWindowMessage';
);

// private // UserAtomTableHandle
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: NumberOfElements]
function NtUserGetAtomName(
  [in] Atom: Word;
  [in, out] var AtomName: TNtUnicodeString
): Cardinal; stdcall; external win32u delayed;

var delayed_NtUserGetAtomName: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetAtomName';
);

// PHNT::ntexapi.h // WinSta->GlobalAtomTable
function NtAddAtom(
  [in, ReadsFrom] AtomName: PWideChar;
  [in, NumberOfBytes] Length: Cardinal;
  [out, opt] Atom: PWord
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h // WinSta->GlobalAtomTable
[MinOSVersion(OsWin8)]
function NtAddAtomEx(
  [in, ReadsFrom] AtomName: PWideChar;
  [in, NumberOfBytes] Length: Cardinal;
  [out, opt] Atom: PWord;
  [in] Flags: TAtomFlags32
): NTSTATUS; stdcall; external ntdll delayed;

var delayed_NtAddAtomEx: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtAddAtomEx';
);

// PHNT::ntexapi.h // WinSta->GlobalAtomTable
function NtFindAtom(
  [in, ReadsFrom] AtomName: PWideChar;
  [in, NumberOfBytes] Length: Cardinal;
  [out, opt] Atom: PWord
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h // WinSta->GlobalAtomTable
function NtDeleteAtom(
  [in] Atom: Word
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntexapi.h // WinSta->GlobalAtomTable
function NtQueryInformationAtom(
  [in] Atom: Word;
  [in] AtomInformationClass: TAtomInformationClass;
  [out, WritesTo] AtomInformation: Pointer;
  [in] AtomInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// private // WinSta->GlobalAtomTable
[MinOSVersion(OsWin10RS1)]
function NtUserBuildPropList(
  [in] hwnd: THwnd;
  [in, NumberOfElements] PropMax: Cardinal;
  [out, WritesTo] PropSet: PPropSet;
  [out, NumberOfElements] out PropNeeded: Cardinal
): NTSTATUS; stdcall; external win32u delayed;

var delayed_NtUserBuildPropList: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserBuildPropList';
);

// private // WinSta->GlobalAtomTable
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetProp(
  [in] hwnd: THwnd;
  [in] Atom: Word
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserGetProp: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetProp';
);

// private // WinSta->GlobalAtomTable
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserSetProp(
  [in] hwnd: THwnd;
  [in] Prop: Cardinal;
  [in] Data: NativeUInt
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserSetProp: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserSetProp';
);

// private // WinSta->GlobalAtomTable
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserRemoveProp(
  [in] hwnd: THwnd;
  [in] Prop: Cardinal
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserRemoveProp: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserRemoveProp';
);

{ Clipboard }

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCloseClipboard(
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserCloseClipboard: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCloseClipboard';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: ReleaseWith('NtUserCloseClipboard')]
function NtUserOpenClipboard(
  [in] hwnd: THwnd;
  [out] out EmptyClient: LongBool
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserOpenClipboard: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserOpenClipboard';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetClipboardData(
  [in] fmt: TClipboardFormat;
  [out] out gcd: TGetClipbData
): TMemHandle; stdcall; external win32u delayed;

var delayed_NtUserGetClipboardData: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetClipboardData';
);

// private
[MinOSVersion(OsWin10RS1)]
function NtUserCreateLocalMemHandle(
  [in] hMem: TMemHandle;
  [out, WritesTo] Data: Pointer;
  [in, NumberOfBytes] cbData: Cardinal;
  [out, opt] Needed: PCardinal
): NTSTATUS; stdcall; external win32u delayed;

var delayed_NtUserCreateLocalMemHandle: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCreateLocalMemHandle';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCheckProcessForClipboardAccess(
  [in] ProcessId: TProcessId32;
  [out] out Access: LongBool
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserCheckProcessForClipboardAccess: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCheckProcessForClipboardAccess';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetClipboardSequenceNumber(
): Cardinal; stdcall; external win32u delayed;

var delayed_NtUserGetClipboardSequenceNumber: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetClipboardSequenceNumber';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetClipboardViewer(
): THwnd; stdcall; external win32u delayed;

var delayed_NtUserGetClipboardViewer: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetClipboardViewer';
);

{ Messages }

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserMessageCall(
  [in] hwnd: THwnd;
  [in] msg: Cardinal;
  [in, opt] wParam: WPARAM;
  [in, opt] lParam: LPARAM;
  [in, opt] xParam: NativeUInt;
  [in] xpfnProc: TMessageCallFunctionId;
  [in] bAnsi: LongBool
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserMessageCall: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserMessageCall';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserPostMessage(
  [in] hwnd: THwnd;
  [in] msg: Cardinal;
  [in, opt] wParam: WPARAM;
  [in, opt] lParam: LPARAM
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserPostMessage: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserPostMessage';
);

{ Threads }

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserGetGUIThreadInfo(
  [in] ThreadId: TThreadId32;
  [in, out] var Gui: TGuiThreadInfo
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserGetGUIThreadInfo: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserGetGUIThreadInfo';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserAttachThreadInput(
  [in] idAttach: TThreadId32;
  [in] idAttachTo: TThreadId32;
  [in] fAttach: LongBool
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserAttachThreadInput: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserAttachThreadInput';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCheckWindowThreadDesktop(
  [in] hwnd: THwnd;
  [in] ThreadId: TThreadId32
): Boolean; stdcall; external win32u delayed;

var delayed_NtUserCheckWindowThreadDesktop: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCheckWindowThreadDesktop';
);

{ Misc }

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserUnhookWindowsHookEx(
  [in] hhk: THHook
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserUnhookWindowsHookEx: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserUnhookWindowsHookEx';
);

// private
[MayReturnNil]
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
[Result: ReleaseWith('NtUserUnhookWindowsHookEx')]
function NtUserSetWindowsHookEx(
  [in] hmod: Pointer;
  [in] const Lib: TNtUnicodeString;
  [in, opt] Thread: TThreadId32;
  [in] FilterType: THookId;
  [in] FilterProc: Pointer;
  [in] Flags: THookFlags
): THHook; stdcall; external win32u delayed;

var delayed_NtUserSetWindowsHookEx: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserSetWindowsHookEx';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCheckAccessForIntegrityLevel(
  [in] ProcessFrom: TProcessId32;
  [in] ProcessTo: TProcessId32;
  [out] out Access: LongBool
): NTSTATUS; stdcall; external win32u delayed;

var delayed_NtUserCheckAccessForIntegrityLevel: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCheckAccessForIntegrityLevel';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserLockWorkStation(
): LongBool; stdcall; external win32u delayed;

var delayed_NtUserLockWorkStation: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserLockWorkStation';
);

// private
[MinOSVersion(OsWin10RS1)]
function NtUserTestForInteractiveUser(
  const [ref] Caller: TLuid
): NTSTATUS; stdcall; external win32u delayed;

var delayed_NtUserTestForInteractiveUser: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserTestForInteractiveUser';
);

{ Legacy calls }

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCallNoParam(
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallNoParam: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallNoParam';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCallOneParam(
  [in] Param: NativeUInt;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallOneParam: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallOneParam';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCallHwnd(
  [in] hwnd: THwnd;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallHwnd: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallHwnd';
);

// rev
[SetsLastError]
[MinOSVersion(OsWin10RS5)]
function NtUserCallHwndSafe(
  [in] hwnd: THwnd;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallHwndSafe: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallHwndSafe';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCallHwndOpt(
  [in, opt] hwnd: THwnd;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallHwndOpt: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallHwndOpt';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCallHwndParam(
  [in] hwnd: THwnd;
  [in] Param: NativeUInt;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallHwndParam: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallHwndParam';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCallHwndLock(
  [in] hwnd: THwnd;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallHwndLock: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallHwndLock';
);

// rev
[SetsLastError]
[MinOSVersion(OsWin10RS5)]
function NtUserCallHwndLockSafe(
  [in] hwnd: THwnd;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallHwndLockSafe: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallHwndLockSafe';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCallHwndParamLock(
  [in] hwnd: THwnd;
  [in] Param: NativeUInt;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallHwndParamLock: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallHwndParamLock';
);

// rev
[SetsLastError]
[MinOSVersion(OsWin10RS5)]
function NtUserCallHwndParamLockSafe(
  [in] hwnd: THwnd;
  [in] Param: NativeUInt;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallHwndParamLockSafe: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallHwndParamLockSafe';
);

// private
[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function NtUserCallTwoParam(
  [in] Param1: NativeUInt;
  [in] Param2: NativeUInt;
  [in] xpfnProc: TUserCallIndex
): NativeUInt; stdcall; external win32u delayed;

var delayed_NtUserCallTwoParam: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserCallTwoParam';
);

// private
[Result: MayReturnNil]
[MinOSVersion(OsWin11)]
function NtUserMapDesktopObject(
  [in] h: THandle
): Pointer; stdcall; external win32u delayed;

var delayed_NtUserMapDesktopObject: TDelayedLoadFunction = (
  Dll: @delayed_win32u;
  FunctionName: 'NtUserMapDesktopObject';
);

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
