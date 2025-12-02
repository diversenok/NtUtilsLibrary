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

  // rev, thread desktop flags
  TDF_PROTECT_HANDLE = $00000001;

  // private - hook flags
  HF_ANSI = $0002;
  HF_EXTENDED_TIMEOUT = $0040; // rev // Win 10 21H1+

var
  delayed_win32u: TDelayedLoadDll = (DllName: win32u);

type
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

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
