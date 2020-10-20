unit Winapi.WinUser;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Winapi.WinBase, DelphiApi.Reflection;

const
  user32 = 'user32.dll';

  // 1375
  DESKTOP_READOBJECTS = $0001;
  DESKTOP_CREATEWINDOW = $0002;
  DESKTOP_CREATEMENU = $0004;
  DESKTOP_HOOKCONTROL = $0008;
  DESKTOP_JOURNALRECORD = $0010;
  DESKTOP_JOURNALPLAYBACK = $0020;
  DESKTOP_ENUMERATE = $0040;
  DESKTOP_WRITEOBJECTS = $0080;
  DESKTOP_SWITCHDESKTOP = $0100;

  DESKTOP_ALL_ACCESS = $01FF or STANDARD_RIGHTS_REQUIRED;

  // 1388
  DF_ALLOWOTHERACCOUNTHOOK = $1;

  // 1555
  WINSTA_ENUMDESKTOPS = $0001;
  WINSTA_READATTRIBUTES = $0002;
  WINSTA_ACCESSCLIPBOARD = $0004;
  WINSTA_CREATEDESKTOP = $0008;
  WINSTA_WRITEATTRIBUTES = $0010;
  WINSTA_ACCESSGLOBALATOMS = $0020;
  WINSTA_EXITWINDOWS = $0040;
  WINSTA_ENUMERATE = $0100;
  WINSTA_READSCREEN = $0200;

  WINSTA_ALL_ACCESS = $037F or STANDARD_RIGHTS_REQUIRED;

  // 1577
  WSF_VISIBLE = $01;

  // 2000
  WM_GETTEXT = $000D;
  WM_GETTEXTLENGTH = $000E;

  // 2608, flags for SendMessageTimeoutW
  SMTO_NORMAL = $0000;
  SMTO_BLOCK = $0001;
  SMTO_ABORTIFHUNG = $0002;
  SMTO_NOTIMEOUTIFNOTHUNG = $0008;
  SMTO_ERRORONEXIT = $0020;

  // 9074
  MB_OK = $00000000;
  MB_OKCANCEL = $00000001;
  MB_ABORTRETRYIGNORE = $00000002;
  MB_YESNOCANCEL = $00000003;
  MB_YESNO = $00000004;
  MB_RETRYCANCEL = $00000005;
  MB_CANCELTRYCONTINUE = $00000006;

  MB_ICONHAND = $00000010;
  MB_ICONQUESTION = $00000020;
  MB_ICONEXCLAMATION = $00000030;
  MB_ICONASTERISK = $00000040;

  MB_ICONWARNING = MB_ICONEXCLAMATION;
  MB_ICONERROR = MB_ICONHAND;
  MB_ICONINFORMATION = MB_ICONASTERISK;
  MB_ICONSTOP = MB_ICONHAND;

  // 11108
  IDOK = 1;
  IDCANCEL = 2;
  IDABORT = 3;
  IDRETRY = 4;
  IDIGNORE = 5;
  IDYES = 6;
  IDNO = 7;
  IDCLOSE = 8;
  IDHELP = 9;
  IDTRYAGAIN = 10;
  IDCONTINUE = 11;
  IDTIMEOUT = 32000;

  // 14297
  GUI_CARETBLINKING = $00000001;
  GUI_INMOVESIZE = $00000002;
  GUI_INMENUMODE = $00000004;
  GUI_SYSTEMMENUMODE = $00000008;
  GUI_POPUPMENUMODE = $00000010;
  GUI_16BITTASK = $00000020;

type
  [Hex] HWND = type NativeUInt;

  [Hex] HICON = type NativeUInt;
  PHICON = ^HICON;

  HDESK = THandle;
  HWINSTA = THandle;

  WPARAM = NativeUInt;
  LPARAM = NativeInt;

  [FriendlyName('desktop'), ValidMask(DESKTOP_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(DESKTOP_READOBJECTS, 'Read Objects')]
  [FlagName(DESKTOP_CREATEWINDOW, 'Create Window')]
  [FlagName(DESKTOP_CREATEMENU, 'Create Menu')]
  [FlagName(DESKTOP_HOOKCONTROL, 'Hook Control')]
  [FlagName(DESKTOP_JOURNALRECORD, 'Journal Record')]
  [FlagName(DESKTOP_JOURNALPLAYBACK, 'Journal Playback')]
  [FlagName(DESKTOP_ENUMERATE, 'Enumerate')]
  [FlagName(DESKTOP_WRITEOBJECTS, 'Write Objects')]
  [FlagName(DESKTOP_SWITCHDESKTOP, 'Switch Desktop')]
  TDesktopAccessMask = type TAccessMask;

  [FriendlyName('window station'), ValidMask(WINSTA_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(WINSTA_ENUMDESKTOPS, 'Enumerate Desktops')]
  [FlagName(WINSTA_READATTRIBUTES, 'Read Attributes')]
  [FlagName(WINSTA_ACCESSCLIPBOARD, 'Access Clipboard')]
  [FlagName(WINSTA_CREATEDESKTOP, 'Create Desktop')]
  [FlagName(WINSTA_WRITEATTRIBUTES, 'Write Attributes')]
  [FlagName(WINSTA_ACCESSGLOBALATOMS, 'Access Global Atoms')]
  [FlagName(WINSTA_EXITWINDOWS, 'Exit Windows')]
  [FlagName(WINSTA_ENUMERATE, 'Enumerate')]
  [FlagName(WINSTA_READSCREEN, 'Read Screen')]
  TWinstaAccessMask = type TAccessMask;

  // 393
  {$MINENUMSIZE 2}
  [NamingStyle(nsSnakeCase, 'SW')]
  TShowMode = (
    SW_HIDE = 0,
    SW_SHOW_NORMAL = 1,
    SW_SHOW_MINIMIZED = 2,
    SW_SHOW_MAXIMIZED = 3,
    SW_SHOW_NO_ACTIVATE = 4,
    SW_SHOW = 5,
    SW_MINIMIZE = 6,
    SW_SHOW_MIN_NO_ACTIVE = 7,
    SW_SHOW_NA = 8,
    SW_RESTORE = 9,
    SW_SHOW_DEFAULT = 10,
    SW_FORCE_MINIMIZE = 11
  );
  {$MINENUMSIZE 4}

  TStringEnumProcW = function (Name: PWideChar; var Context: TArray<String>):
    LongBool; stdcall;

  // 1691
  [NamingStyle(nsSnakeCase, 'UOI'), Range(1)]
  TUserObjectInfoClass = (
    UOI_RESERVED = 0,
    UOI_FLAGS = 1,     // q, s: TUserObjectFlags
    UOI_NAME = 2,      // q: PWideChar
    UOI_TYPE = 3,      // q: PWideChar
    UOI_USER_SID = 4,  // q: PSid
    UOI_HEAP_SIZE = 5, // q: Cardinal
    UOI_IO = 6,        // q: LongBool
    UOI_TIMER_PROC_EXCEPTION_SUPPRESSION = 7
  );

  // 1704
  TUserObjectFlags = record
    Inherit: LongBool;
    Reserved: LongBool;
    [Hex] Flags: Cardinal; // WSF_* or DF_*
  end;
  PUserObjectFlags = ^TUserObjectFlags;

  // windef.154
  TRect = record
    Left: Integer;
    Top: Integer;
    Right: Integer;
    Bottom: Integer;
  end;

  [FlagName(GUI_CARETBLINKING, 'Caret Blinking')]
  [FlagName(GUI_INMOVESIZE, 'In Move/Size')]
  [FlagName(GUI_INMENUMODE, 'In Menu Mode')]
  [FlagName(GUI_SYSTEMMENUMODE, 'System Menu Mode')]
  [FlagName(GUI_POPUPMENUMODE, 'PopupMenuMode')]
  [FlagName(GUI_16BITTASK, '16-bit Task')]
  TGuiThreadFlags = type Cardinal;

  // 14281
  TGuiThreadInfo = record
    [Hex, Unlisted] Size: Cardinal;
    Flags: TGuiThreadFlags;
    Active: HWND;
    Focus: HWND;
    Capture: HWND;
    MenuOwner: HWND;
    MoveSize: HWND;
    Caret: HWND;
    RectCaret: TRect;
  end;

// Desktops

// 1409
function CreateDesktopW(Desktop: PWideChar; Device: PWideChar; Devmode: Pointer;
  Flags: Cardinal; DesiredAccess: TAccessMask; SA: PSecurityAttributes): HDESK;
  stdcall; external user32;

// 1472
function OpenDesktopW(Desktop: PWideChar; Flags: Cardinal; Inherit: LongBool;
  DesiredAccess: TAccessMask): HDESK; stdcall; external user32;

// 1502
function EnumDesktopsW(hWinStation: HWINSTA; EnumFunc: TStringEnumProcW;
  var Context: TArray<String>): LongBool; stdcall; external user32;

// 1524
function SwitchDesktop(hDesktop: HDESK): LongBool; stdcall; external user32;

// rev
function SwitchDesktopWithFade(hDesktop: HDESK; FadeDuration: Cardinal):
  LongBool; stdcall; external user32;

// 1531
function SetThreadDesktop(hDesktop: HDESK): LongBool; stdcall; external user32;

// 1537
function CloseDesktop(hDesktop: HDESK): LongBool; stdcall; external user32;

// 1543
function GetThreadDesktop(ThreadId: TThreadId32): HDESK; stdcall;
  external user32;

// Window Stations

// 1593
function CreateWindowStationW(Winsta: PWideChar; Flags: Cardinal; DesiredAccess:
  TAccessMask; SA: PSecurityAttributes): HWINSTA; stdcall; external user32;

// 1614
function OpenWindowStationW(WinSta: PWideChar; Inherit: LongBool; DesiredAccess:
  TAccessMask): HWINSTA; stdcall; external user32;

// 1633
function EnumWindowStationsW(EnumFunc: TStringEnumProcW; var Context:
  TArray<String>): LongBool; stdcall; external user32;

// 1645
function CloseWindowStation(hWinStation: HWINSTA): LongBool; stdcall;
  external user32;

// 1651
function SetProcessWindowStation(hWinSta: HWINSTA): LongBool; stdcall;
  external user32;

// 1657
function GetProcessWindowStation: HWINSTA; stdcall; external user32;

// rev
function LockWindowStation(hWinStation: HWINSTA): LongBool; stdcall;
  external user32;

// rev
function UnlockWindowStation(hWinStation: HWINSTA): LongBool; stdcall;
  external user32;

// rev
function SetWindowStationUser(hWinStation: HWINSTA; var Luid: TLuid;
  Sid: PSid; SidLength: Cardinal): LongBool; stdcall; external user32;

// User objects

// 1722
function GetUserObjectInformationW(hObj: THandle; InfoClass:
  TUserObjectInfoClass; Info: Pointer; Length: Cardinal; LengthNeeded:
  PCardinal): LongBool; stdcall; external user32;

// 1775
function SetUserObjectInformationW(hObj: THandle; InfoClass:
  TUserObjectInfoClass; pvInfo: Pointer; nLength: Cardinal): LongBool; stdcall;
  external user32;

// Other

// 3760
function SendMessageTimeoutW(hWnd: HWND; Msg: Cardinal; wParam: NativeUInt;
  lParam: NativeInt; fuFlags: Cardinal; uTimeout: Cardinal; out lpdwResult:
  NativeInt): NativeInt; stdcall; external user32;

// 4122
function WaitForInputIdle(hProcess: THandle; Milliseconds: Cardinal):
  Cardinal; stdcall; external user32;

// 10719
function DestroyIcon(Icon: HICON): LongBool stdcall; external user32;

// 14316
function GetGUIThreadInfo(ThreadId: TThreadId32; var Gui: TGuiThreadInfo):
  LongBool; stdcall; external user32;

implementation

end.
