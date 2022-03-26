unit Ntapi.WinUser;

{
  This file provides definitions for User and GDI functions.
  See SDK::WinUser.h for sources.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.WinBase, DelphiApi.Reflection;

type
  MAKEINTRESOURCE = PWideChar;

const
  user32 = 'user32.dll';

  // Desktop access masks
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

  // Desktop open options
  DF_ALLOWOTHERACCOUNTHOOK = $1;

  // Window station access masks
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

  // Window station flags
  WSF_VISIBLE = $01;

  // Window message values
  WM_GETTEXT = $000D;
  WM_GETTEXTLENGTH = $000E;

  // Flags for SendMessageTimeoutW
  SMTO_NORMAL = $0000;
  SMTO_BLOCK = $0001;
  SMTO_ABORTIFHUNG = $0002;
  SMTO_NOTIMEOUTIFNOTHUNG = $0008;
  SMTO_ERRORONEXIT = $0020;

  // Window display affinity values
  WDA_NONE = $00;
  WDA_MONITOR = $01;
  WDA_EXCLUDEFROMCAPTURE = $11; // Win10 20H1+

  // Message box flags
  MB_OK                = $00000000;
  MB_OKCANCEL          = $00000001;
  MB_ABORTRETRYIGNORE  = $00000002;
  MB_YESNOCANCEL       = $00000003;
  MB_YESNO             = $00000004;
  MB_RETRYCANCEL       = $00000005;
  MB_CANCELTRYCONTINUE = $00000006;

  MB_ICONERROR       = $00000010;
  MB_ICONQUESTION    = $00000020;
  MB_ICONWARNING     = $00000030;
  MB_ICONINFORMATION = $00000040;
  MB_USERICON        = $00000080;

  MB_DEFBUTTON1 = $00000000;
  MB_DEFBUTTON2 = $00000100;
  MB_DEFBUTTON3 = $00000200;
  MB_DEFBUTTON4 = $00000300;

  MB_APPLMODAL   = $00000000;
  MB_SYSTEMMODAL = $00001000;
  MB_TASKMODAL   = $00002000;

  MB_HELP    = $00004000;
  MB_NOFOCUS = $00008000;

  MB_SETFOREGROUND = $00010000;
  MB_DEFAULT_DESKTOP_ONLY = $00020000;

  MB_TYPEMASK = $0000000F;
  MB_ICONMASK = $000000F0;
  MB_DEFMASK  = $00000F00;
  MB_MODEMASK = $00003000;
  MB_MISCMASK = $0000C000;

  // GUI thread flags
  GUI_CARETBLINKING = $00000001;
  GUI_INMOVESIZE = $00000002;
  GUI_INMENUMODE = $00000004;
  GUI_SYSTEMMENUMODE = $00000008;
  GUI_POPUPMENUMODE = $00000010;
  GUI_16BITTASK = $00000020;

  // Insert after HWNDs
  HWND_TOP = 0;
  HWND_BOTTOM = 1;
  HWND_TOPMOST = -1;
  HWND_NOTOPMOST = -2;

  // Built-in icons
  IDI_APPLICATION = MAKEINTRESOURCE(32512);
  IDI_ERROR = MAKEINTRESOURCE(32513);
  IDI_QUESTION = MAKEINTRESOURCE(32514);
  IDI_WARNING = MAKEINTRESOURCE(32515);
  IDI_INFORMATION = MAKEINTRESOURCE(32516);
  IDI_WINLOGO = MAKEINTRESOURCE(32517);
  IDI_SHIELD = MAKEINTRESOURCE(32518);

  // SetWindowPos flags
  SWP_NOSIZE = $0001;
  SWP_NOMOVE = $0002;
  SWP_NOZORDER = $0004;
  SWP_NOREDRAW = $0008;
  SWP_NOACTIVATE = $0010;
  SWP_FRAMECHANGED = $0020;
  SWP_SHOWWINDOW = $0040;
  SWP_HIDEWINDOW = $0080;
  SWP_NOCOPYBITS = $0100;
  SWP_NOOWNERZORDER = $0200;
  SWP_NOSENDCHANGING = $0400;
  SWP_DEFERERASE = $2000;
  SWP_ASYNCWINDOWPOS = $4000;

type
  [SDKName('HWND')]
  [Hex] THwnd = type NativeUInt;

  [SDKName('HICON')]
  [Hex] THIcon = type NativeUInt;
  PHIcon = ^THIcon;

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

  [FlagName(DF_ALLOWOTHERACCOUNTHOOK, 'Allow Other Account Hooks')]
  TDesktopOpenOptions = type Cardinal;

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

  [SDKName('DESKTOPENUMPROCW')]
  [SDKName('WINSTAENUMPROCW')]
  TStringEnumProcW = function (
    Name: PWideChar;
    var Context
  ): LongBool; stdcall;

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

  [SDKName('USEROBJECTFLAGS')]
  TUserObjectFlags = record
    Inherit: LongBool;
    Reserved: LongBool;
    [Hex] Flags: Cardinal; // WSF_* or DF_*
  end;
  PUserObjectFlags = ^TUserObjectFlags;

  // SDK::windef.h
  [SDKName('RECT')]
  TRect = record
    Left: Integer;
    Top: Integer;
    Right: Integer;
    Bottom: Integer;
  end;

  [FlagName(SWP_NOSIZE, 'No Size')]
  [FlagName(SWP_NOMOVE, 'No Move')]
  [FlagName(SWP_NOZORDER, 'No Z-order')]
  [FlagName(SWP_NOREDRAW, 'No Redraw')]
  [FlagName(SWP_NOACTIVATE, 'No Activate')]
  [FlagName(SWP_FRAMECHANGED, 'Frame Changed')]
  [FlagName(SWP_SHOWWINDOW, 'Show Window')]
  [FlagName(SWP_HIDEWINDOW, 'Hide Window')]
  [FlagName(SWP_NOCOPYBITS, 'No Copy Bits')]
  [FlagName(SWP_NOOWNERZORDER, 'No Owner Z-Order')]
  [FlagName(SWP_NOSENDCHANGING, 'No Sender Changing')]
  [FlagName(SWP_DEFERERASE, 'Defer Erase')]
  [FlagName(SWP_ASYNCWINDOWPOS, 'Async Window Pos')]
  TSetWindowPosFlags = type Cardinal;

  [SubEnum(MB_TYPEMASK, MB_OK, 'OK')]
  [SubEnum(MB_TYPEMASK, MB_OKCANCEL, 'OK & Cancel')]
  [SubEnum(MB_TYPEMASK, MB_ABORTRETRYIGNORE, 'Abort & Retry & Ignore')]
  [SubEnum(MB_TYPEMASK, MB_YESNOCANCEL, 'Yes & No & Cancel')]
  [SubEnum(MB_TYPEMASK, MB_YESNO, 'Yes & No')]
  [SubEnum(MB_TYPEMASK, MB_RETRYCANCEL, 'Retry & Cancel')]
  [SubEnum(MB_TYPEMASK, MB_CANCELTRYCONTINUE, 'Cancel & Retry & Continue')]
  [SubEnum(MB_ICONMASK, MB_ICONERROR, 'Error')]
  [SubEnum(MB_ICONMASK, MB_ICONQUESTION, 'Question')]
  [SubEnum(MB_ICONMASK, MB_ICONWARNING, 'Warning')]
  [SubEnum(MB_ICONMASK, MB_ICONINFORMATION, 'Information')]
  [SubEnum(MB_ICONMASK, MB_USERICON, 'User Icon')]
  [SubEnum(MB_DEFMASK, MB_DEFBUTTON1, 'Default Button 1')]
  [SubEnum(MB_DEFMASK, MB_DEFBUTTON2, 'Default Button 2')]
  [SubEnum(MB_DEFMASK, MB_DEFBUTTON3, 'Default Button 3')]
  [SubEnum(MB_DEFMASK, MB_DEFBUTTON4, 'Default Button 4')]
  [SubEnum(MB_MODEMASK, MB_APPLMODAL, 'App Modal')]
  [SubEnum(MB_MODEMASK, MB_SYSTEMMODAL, 'System Modal')]
  [SubEnum(MB_MODEMASK, MB_TASKMODAL, 'Task Modal')]
  [SubEnum(MB_MISCMASK, MB_HELP, 'Help')]
  [SubEnum(MB_MISCMASK, MB_NOFOCUS, 'No Focus')]
  [FlagName(MB_SETFOREGROUND, 'Set Foreground')]
  [FlagName(MB_DEFAULT_DESKTOP_ONLY, 'Default Desktop Only')]
  TMessageStyle = type Cardinal;

  [NamingStyle(nsSnakeCase, 'ID'), Range(1, 11)]
  TMessageResponse = (
    IDNONE = 0,
    IDOK = 1,
    IDCANCEL = 2,
    IDABORT = 3,
    IDRETRY = 4,
    IDIGNORE = 5,
    IDYES = 6,
    IDNO = 7,
    IDCLOSE = 8,
    IDHELP = 9,
    IDTRYAGAIN = 10,
    IDCONTINUE = 11,
    IDTIMEOUT = 32000
  );
  PMessageResponse = ^TMessageResponse;

  [FlagName(SMTO_NORMAL, 'SMTO_NORMAL')]
  [FlagName(SMTO_BLOCK, 'SMTO_BLOCK')]
  [FlagName(SMTO_ABORTIFHUNG, 'SMTO_ABORTIFHUNG')]
  [FlagName(SMTO_NOTIMEOUTIFNOTHUNG, 'SMTO_NOTIMEOUTIFNOTHUNG')]
  [FlagName(SMTO_ERRORONEXIT, 'SMTO_ERRORONEXIT')]
  TSendMessageOptions = type Cardinal;

  [FlagName(GUI_CARETBLINKING, 'Caret Blinking')]
  [FlagName(GUI_INMOVESIZE, 'In Move/Size')]
  [FlagName(GUI_INMENUMODE, 'In Menu Mode')]
  [FlagName(GUI_SYSTEMMENUMODE, 'System Menu Mode')]
  [FlagName(GUI_POPUPMENUMODE, 'PopupMenuMode')]
  [FlagName(GUI_16BITTASK, '16-bit Task')]
  TGuiThreadFlags = type Cardinal;

  [SDKName('GUITHREADINFO')]
  TGuiThreadInfo = record
    [Hex, Unlisted] Size: Cardinal;
    Flags: TGuiThreadFlags;
    Active: THwnd;
    Focus: THwnd;
    Capture: THwnd;
    MenuOwner: THwnd;
    MoveSize: THwnd;
    Caret: THwnd;
    RectCaret: TRect;
  end;

// Desktops

function CreateDesktopW(
  [in] Desktop: PWideChar;
  [Reserved] Device: PWideChar;
  [Reserved] Devmode: Pointer;
  Flags: TDesktopOpenOptions;
  DesiredAccess: TDesktopAccessMask;
  [in, opt] SA: PSecurityAttributes
): THandle; stdcall; external user32;

function OpenDesktopW(
  [in] Desktop: PWideChar;
  Flags: TDesktopOpenOptions;
  Inherit: LongBool;
  DesiredAccess: TDesktopAccessMask
): THandle; stdcall; external user32;

function EnumDesktopsW(
  [Access(WINSTA_ENUMDESKTOPS)] hWinStation: THandle;
  EnumFunc: TStringEnumProcW;
  [opt] var Context
): LongBool; stdcall; external user32;

function SwitchDesktop(
  [Access(DESKTOP_SWITCHDESKTOP)] hDesktop: THandle
): LongBool; stdcall; external user32;

// rev
function SwitchDesktopWithFade(
  [Access(DESKTOP_SWITCHDESKTOP)] hDesktop: THandle;
  FadeDuration: Cardinal
): LongBool; stdcall; external user32;

function SetThreadDesktop(
  hDesktop: THandle
): LongBool; stdcall; external user32;

function CloseDesktop(
  hDesktop: THandle
): LongBool; stdcall; external user32;

function GetThreadDesktop(
  ThreadId: TThreadId32
): THandle; stdcall; external user32;

// Window Stations

function CreateWindowStationW(
  [in, opt] Winsta: PWideChar;
  Flags: Cardinal;
  DesiredAccess: TWinstaAccessMask;
  [in, opt] SA: PSecurityAttributes
): THandle; stdcall; external user32;

function OpenWindowStationW(
  [in] WinSta: PWideChar;
  Inherit: LongBool;
  DesiredAccess: TWinStaAccessMask
): THandle; stdcall; external user32;

function EnumWindowStationsW(
  EnumFunc: TStringEnumProcW;
  [opt] var Context
): LongBool; stdcall; external user32;

function CloseWindowStation(
  hWinStation: THandle
): LongBool; stdcall; external user32;

function SetProcessWindowStation(
  hWinStation: THandle
): LongBool; stdcall; external user32;

function GetProcessWindowStation: THandle; stdcall; external user32;

// rev, usable only by winlogon
function LockWindowStation(
  hWinStation: THandle
): LongBool; stdcall; external user32;

// rev, usable only by winlogon
function UnlockWindowStation(
  hWinStation: THandle
): LongBool; stdcall; external user32;

// rev, usable only by winlogon
function SetWindowStationUser(
  hWinStation: THandle;
  const [ref] Luid: TLuid;
  [in] Sid: PSid;
  SidLength: Cardinal
): LongBool; stdcall; external user32;

// User objects

function GetUserObjectInformationW(
  hObj: THandle;
  InfoClass: TUserObjectInfoClass;
  [out, opt] Info: Pointer;
  Length: Cardinal;
  LengthNeeded: PCardinal
): LongBool; stdcall; external user32;

function SetUserObjectInformationW(
  hObj: THandle;
  InfoClass: TUserObjectInfoClass;
  [in] pvInfo: Pointer;
  nLength: Cardinal
): LongBool; stdcall; external user32;

// Windows

function SetWindowPos(
  hWnd: THwnd;
  [opt] hWndInsertAfter: THwnd;
  X: Integer;
  Y: Integer;
  CX: Integer;
  CY: Integer;
  Flags: TSetWindowPosFlags
): LongBool; stdcall; external user32;

// Other

function MessageBoxW(
  [opt] hWnd: THwnd;
  [in, opt] Text: PWideChar;
  [in, opt] Caption: PWideChar;
  uType: TMessageStyle
): TMessageResponse; stdcall; external user32;

function SendMessageTimeoutW(
  hWnd: THwnd;
  Msg: Cardinal;
  wParam: NativeUInt;
  lParam: NativeInt;
  Flags: TSendMessageOptions;
  Timeout: Cardinal;
  [opt] out dwResult: NativeInt
): NativeInt; stdcall; external user32;

function WaitForInputIdle(
  hProcess: THandle;
  Milliseconds: Cardinal
): Cardinal; stdcall; external user32;

function GetWindowDisplayAffinity(
  hWnd: THwnd;
  out Affinity: Cardinal
): LongBool; stdcall; external user32;

function SetWindowDisplayAffinity(
  hWnd: THwnd;
  Affinity: Cardinal
): LongBool; stdcall; external user32;

function GetWindowThreadProcessId(
  hWnd: THwnd;
  [opt] out dwProcessId: TProcessId32
): TThreadId32; stdcall; external user32;

function DestroyIcon(
  Icon: THIcon
): LongBool stdcall; external user32;

function GetGUIThreadInfo(
  ThreadId: TThreadId32;
  var Gui: TGuiThreadInfo
): LongBool; stdcall; external user32;

implementation

end.
