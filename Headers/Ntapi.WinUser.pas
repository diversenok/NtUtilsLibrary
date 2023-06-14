unit Ntapi.WinUser;

{
  This file provides definitions for User and GDI functions.
  See SDK::WinUser.h for sources.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.WinBase, DelphiApi.Reflection, DelphiApi.DelayLoad,
  Ntapi.Versions;

type
  MAKEINTRESOURCE = PWideChar;

const
  user32 = 'user32.dll';

var
  delayed_user32: TDelayedLoadDll = (DllName: user32);

const
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

  // Special desktop window
  HWND_DESKTOP = 0;

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

  // Class styles
  CS_VREDRAW = $0001;
  CS_HREDRAW = $0002;
  CS_DBLCLKS = $0008;
  CS_OWNDC = $0020;
  CS_CLASSDC = $0040;
  CS_PARENTDC = $0080;
  CS_NOCLOSE = $0200;
  CS_SAVEBITS = $0800;
  CS_BYTEALIGNCLIENT = $1000;
  CS_BYTEALIGNWINDOW = $2000;
  CS_GLOBALCLASS = $4000;
  CS_IME = $00010000;
  CS_DROPSHADOW = $00020000;

  // Window styles
  WS_TABSTOP = $00010000;
  WS_MINIMIZEBOX = $00020000;
  WS_SIZEBOX = $00040000;
  WS_SYSMENU = $00080000;
  WS_HSCROLL = $00100000;
  WS_VSCROLL = $00200000;
  WS_DLGFRAME = $00400000;
  WS_BORDER = $00800000;
  WS_MAXIMIZE = $01000000;
  WS_CLIPCHILDREN = $02000000;
  WS_CLIPSIBLINGS = $04000000;
  WS_DISABLED = $08000000;
  WS_VISIBLE = $10000000;
  WS_MINIMIZE = $20000000;
  WS_CHILD = $40000000;
  WS_POPUP = $80000000;

  // Extended window styles
  WS_EX_DLGMODALFRAME = $00000001;
  WS_EX_NOPARENTNOTIFY = $00000004;
  WS_EX_TOPMOST = $00000008;
  WS_EX_ACCEPTFILES = $00000010;
  WS_EX_TRANSPARENT = $00000020;
  WS_EX_MDICHILD = $00000040;
  WS_EX_TOOLWINDOW = $00000080;
  WS_EX_WINDOWEDGE = $00000100;
  WS_EX_CLIENTEDGE = $00000200;
  WS_EX_CONTEXTHELP = $00000400;
  WS_EX_RIGHT = $00001000;
  WS_EX_RTLREADING = $00002000;
  WS_EX_LEFTSCROLLBAR = $00004000;
  WS_EX_CONTROLPARENT = $00010000;
  WS_EX_STATICEDGE = $00020000;
  WS_EX_APPWINDOW = $00040000;
  WS_EX_LAYERED = $00080000;
  WS_EX_NOINHERITLAYOUT = $00100000;
  WS_EX_NOREDIRECTIONBITMAP = $00200000;
  WS_EX_LAYOUTRTL = $00400000;
  WS_EX_COMPOSITED = $02000000;
  WS_EX_NOACTIVATE = $08000000;

  // SDK::dwmapi.h - cloaked attribute flags
  DWM_CLOAKED_APP = $00000001;
  DWM_CLOAKED_SHELL = $00000002;
  DWM_CLOAKED_INHERITED = $00000004;

type
  [SDKName('HWND')]
  [Hex] THwnd = type NativeUInt;

  THBitmap = type NativeUInt;

  [SDKName('HICON')]
  [Hex] THIcon = type NativeUInt;
  PHIcon = ^THIcon;

  WPARAM = NativeUInt;
  LPARAM = NativeInt;

  [FriendlyName('desktop'), ValidBits(DESKTOP_ALL_ACCESS)]
  [SubEnum(DESKTOP_ALL_ACCESS, DESKTOP_ALL_ACCESS, 'Full Access')]
  [FlagName(DESKTOP_READOBJECTS, 'Read Objects')]
  [FlagName(DESKTOP_CREATEWINDOW, 'Create Window')]
  [FlagName(DESKTOP_CREATEMENU, 'Create Menu')]
  [FlagName(DESKTOP_HOOKCONTROL, 'Hook Control')]
  [FlagName(DESKTOP_JOURNALRECORD, 'Journal Record')]
  [FlagName(DESKTOP_JOURNALPLAYBACK, 'Journal Playback')]
  [FlagName(DESKTOP_ENUMERATE, 'Enumerate')]
  [FlagName(DESKTOP_WRITEOBJECTS, 'Write Objects')]
  [FlagName(DESKTOP_SWITCHDESKTOP, 'Switch Desktop')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TDesktopAccessMask = type TAccessMask;

  [FlagName(DF_ALLOWOTHERACCOUNTHOOK, 'Allow Other Account Hooks')]
  TDesktopOpenOptions = type Cardinal;

  [FriendlyName('window station'), ValidBits(WINSTA_ALL_ACCESS)]
  [SubEnum(WINSTA_ALL_ACCESS, WINSTA_ALL_ACCESS, 'Full Access')]
  [FlagName(WINSTA_ENUMDESKTOPS, 'Enumerate Desktops')]
  [FlagName(WINSTA_READATTRIBUTES, 'Read Attributes')]
  [FlagName(WINSTA_ACCESSCLIPBOARD, 'Access Clipboard')]
  [FlagName(WINSTA_CREATEDESKTOP, 'Create Desktop')]
  [FlagName(WINSTA_WRITEATTRIBUTES, 'Write Attributes')]
  [FlagName(WINSTA_ACCESSGLOBALATOMS, 'Access Global Atoms')]
  [FlagName(WINSTA_EXITWINDOWS, 'Exit Windows')]
  [FlagName(WINSTA_ENUMERATE, 'Enumerate')]
  [FlagName(WINSTA_READSCREEN, 'Read Screen')]
  [InheritsFrom(System.TypeInfo(TAccessMask))]
  TWinstaAccessMask = type TAccessMask;

  {$MINENUMSIZE 2}
  {$SCOPEDENUMS ON}
  [NamingStyle(nsSnakeCase, 'SW')]
  TShowMode16 = (
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
  {$SCOPEDENUMS OFF}
  {$MINENUMSIZE 4}

  {$SCOPEDENUMS ON}
  [NamingStyle(nsSnakeCase, 'SW')]
  TShowMode32 = (
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
  {$SCOPEDENUMS OFF}

  [SDKName('DESKTOPENUMPROCW')]
  [SDKName('WINSTAENUMPROCW')]
  TStringEnumProcW = function (
    [in] Name: PWideChar;
    [in, opt] var Context
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

  [SDKName('WNDENUMPROC')]
  TWndEnumProc = function (
    [in] hwnd: THwnd;
    [in, opt] var Context
  ): LongBool; stdcall;

  // SDK::windef.h
  [SDKName('RECT')]
  TRect = record
    Left: Integer;
    Top: Integer;
    Right: Integer;
    Bottom: Integer;
  end;

  // SDK::WinUser.h
  [NamingStyle(nsSnakeCase, 'GW')]
  TGetWindowCmd = (
    GW_HWNDFIRST = 0,
    GW_HWNDLAST = 1,
    GW_HWNDNEXT = 2,
    GW_HWNDPREV = 3,
    GW_OWNER = 4,
    GW_CHILD = 5,
    GW_ENABLEDPOPUP = 6
  );

  // SDK::WinUser.h
  [NamingStyle(nsSnakeCase, 'GA'), Range(1)]
  TGetAncestorCmd = (
    [Reserved] GA_INVALID = 0,
    GA_PARENT = 1,
    GA_ROOT = 2,
    GA_ROOTOWNER = 3
  );

  // SDK::WinUser.h
  TClassLongIndex = (
    GCLP_MENUNAME = -8,       // q, s:
    GCLP_HBRBACKGROUND = -10, // q, s: HBRUSH
    GCLP_HCURSOR = -12,       // q, s: HCURSOR
    GCLP_HICON = -14,         // q, s: HICON
    GCLP_HMODULE = -16,       // q, s: HMODULE
    GCL_CBWNDEXTRA = -18,     // q, s: Cardinal
    GCL_CBCLSEXTRA = -20,     // q, s: Cardinal
    GCL_WNDPROC = -24,        // q, s: Pointer
    GCL_STYLE = -26,          // q, s: TClassStyle
    GCW_ATOM = -32,           // q: Word
    GCLP_HICONSM = -34        // q, s: HICON
  );

  // Class property -26
  [FlagName(CS_VREDRAW, 'Vertical Redraw')]
  [FlagName(CS_HREDRAW, 'Horizontal Redraw')]
  [FlagName(CS_DBLCLKS, 'Double-click')]
  [FlagName(CS_OWNDC, 'Own DC')]
  [FlagName(CS_CLASSDC, 'Class DC')]
  [FlagName(CS_PARENTDC, 'Parent DC')]
  [FlagName(CS_NOCLOSE, 'No Close')]
  [FlagName(CS_SAVEBITS, 'Save Bits')]
  [FlagName(CS_BYTEALIGNCLIENT, 'Byte-align Client')]
  [FlagName(CS_BYTEALIGNWINDOW, 'Byte-align Window')]
  [FlagName(CS_GLOBALCLASS, 'Global Class')]
  [FlagName(CS_IME, 'IME')]
  [FlagName(CS_DROPSHADOW, 'Drop Shadow')]
  TClassStyle = type Cardinal;

  // SDK::WinUser.h
  TWindowLongIndex = (
    GWLP_WNDPROC = -4,    // q, s: Pointer
    GWLP_HINSTANCE = -6,  // q, s: Pointer
    GWLP_HWNDPARENT = -8, // q: HWND
    GWL_STYLE = -16,      // q, s: TWindowStyle
    GWL_EXSTYLE = -20,    // q, s: TWindowExStyle
    GWLP_USERDATA = -21,  // q, s: Pointer
    GWLP_ID = -12         // q, s:
  );

  // Window property -16
  [FlagName(WS_TABSTOP, 'Tab Stop')]
  [FlagName(WS_MINIMIZEBOX, 'Minimize Box') ]
  [FlagName(WS_SIZEBOX, 'Size Box')]
  [FlagName(WS_SYSMENU, 'SysMenu')]
  [FlagName(WS_HSCROLL, 'Horizontal Scrollbar')]
  [FlagName(WS_VSCROLL, 'Vertical Scrollbar')]
  [FlagName(WS_DLGFRAME, 'Dialog Frame')]
  [FlagName(WS_BORDER, 'Border')]
  [FlagName(WS_MAXIMIZE, 'Maximized')]
  [FlagName(WS_CLIPCHILDREN, 'Clip Children')]
  [FlagName(WS_CLIPSIBLINGS, 'Clip Siblings')]
  [FlagName(WS_DISABLED, 'Disabled')]
  [FlagName(WS_VISIBLE, 'Visible')]
  [FlagName(WS_MINIMIZE, 'Minimized')]
  [FlagName(WS_CHILD, 'Child')]
  [FlagName(WS_POPUP, 'Popup')]
  TWindowStyle = type Cardinal;

  // Window property -20
  [FlagName(WS_EX_DLGMODALFRAME, 'Dialog Modal Frame')]
  [FlagName(WS_EX_NOPARENTNOTIFY, 'No Parent Notify')]
  [FlagName(WS_EX_TOPMOST, 'Topmost')]
  [FlagName(WS_EX_ACCEPTFILES, 'Accept Files')]
  [FlagName(WS_EX_TRANSPARENT, 'Transparent')]
  [FlagName(WS_EX_MDICHILD, 'MDI Child')]
  [FlagName(WS_EX_TOOLWINDOW, 'Tool Window')]
  [FlagName(WS_EX_WINDOWEDGE, 'Window Edge')]
  [FlagName(WS_EX_CLIENTEDGE, 'Client Edge')]
  [FlagName(WS_EX_CONTEXTHELP, 'Context Help')]
  [FlagName(WS_EX_RIGHT, 'Right-aligned')]
  [FlagName(WS_EX_RTLREADING, 'Right-to-left Reading')]
  [FlagName(WS_EX_LEFTSCROLLBAR, 'Left Scrollbar')]
  [FlagName(WS_EX_CONTROLPARENT, 'Control Parent')]
  [FlagName(WS_EX_STATICEDGE, 'Static Edge')]
  [FlagName(WS_EX_APPWINDOW, 'App Window')]
  [FlagName(WS_EX_LAYERED, 'Layered')]
  [FlagName(WS_EX_NOINHERITLAYOUT, 'No Inherit Layout')]
  [FlagName(WS_EX_NOREDIRECTIONBITMAP, 'No Redirection Bitmap')]
  [FlagName(WS_EX_LAYOUTRTL, 'Right-to-left Layout')]
  [FlagName(WS_EX_COMPOSITED, 'Composited')]
  [FlagName(WS_EX_NOACTIVATE, 'No Activate')]
  TWindowExStyle = type Cardinal;

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

  // private
  [MinOSVersion(OsWin8)]
  [SDKName('ZBID')]
  [NamingStyle(nsSnakeCase, 'ZBID')]
  TZBandId = (
    ZBID_DEFAULT = 0,
    ZBID_DESKTOP = 1,
    ZBID_UIACCESS = 2,
    ZBID_IMMERSIVE_IHM = 3,
    ZBID_IMMERSIVE_NOTIFICATION = 4,
    ZBID_IMMERSIVE_APPCHROME = 5,
    ZBID_IMMERSIVE_MOGO = 6,
    ZBID_IMMERSIVE_EDGY = 7,
    ZBID_IMMERSIVE_INACTIVEMOBODY = 8,
    ZBID_IMMERSIVE_INACTIVEDOCK = 9,
    ZBID_IMMERSIVE_ACTIVEMOBODY = 10,
    ZBID_IMMERSIVE_ACTIVEDOCK = 11,
    ZBID_IMMERSIVE_BACKGROUND = 12,
    ZBID_IMMERSIVE_SEARCH = 13,
    ZBID_GENUINE_WINDOWS = 14,
    ZBID_IMMERSIVE_RESTRICTED = 15,
    ZBID_SYSTEM_TOOLS = 16,
    ZBID_LOCK = 17,
    ZBID_ABOVELOCK_UX = 18
  );

  [FlagName(DWM_CLOAKED_APP, 'App')]
  [FlagName(DWM_CLOAKED_SHELL, 'Shell')]
  [FlagName(DWM_CLOAKED_INHERITED, 'Inherited')]
  TDwmCloakedAttribute = type Cardinal;

  // private
  [SDKName('NCRENDERINGPOLICY')]
  [NamingStyle(nsSnakeCase, 'NCRP')]
  TNcRenderingPolicy = (
    NCRP_USEWINDOWSTYLE = 0,
    NCRP_DISABLED = 1,
    NCRP_ENABLED = 2
  );

  // private
  [SDKName('CORNER_STYLE')]
  [NamingStyle(nsSnakeCase, 'CORNER_STYLE')]
  TCornerStyle = (
    CORNER_STYLE_DEFAULT = 0,
    CORNER_STYLE_DO_NOT_ROUND = 1,
    CORNER_STYLE_ROUND = 2,
    CORNER_STYLE_ROUND_SMALL = 3,
    CORNER_STYLE_MENU = 4
  );

  // private
  [SDKName('SYSTEMBACKDROP_TYPE')]
  [NamingStyle(nsSnakeCase, 'SYSTEMBACKDROP_TYPE')]
  TSystemBackdropType = (
    SYSTEMBACKDROP_TYPE_AUTO = 0,
    SYSTEMBACKDROP_TYPE_NONE = 1,
    SYSTEMBACKDROP_TYPE_MAINWINDOW = 2,
    SYSTEMBACKDROP_TYPE_TRANSIENTWINDOW = 3,
    SYSTEMBACKDROP_TYPE_TABBEDWINDOW = 4
  );

  // private
  [SDKName('WINDOWCOMPOSITIONATTRIB')]
  [NamingStyle(nsSnakeCase, 'WCA'), Range(1)]
  TWindowCompositionAttrib = (
    [Reserved] WCA_UNDEFINED = 0,
    WCA_NCRENDERING_ENABLED = 1,            // q: LongBool
    WCA_NCRENDERING_POLICY = 2,             // s: TNcRenderingPolicy
    WCA_TRANSITIONS_FORCEDISABLED = 3,      // s: LongBool
    WCA_ALLOW_NCPAINT = 4,                  // s: LongBool
    WCA_CAPTION_BUTTON_BOUNDS = 5,          // q: TRect
    WCA_NONCLIENT_RTL_LAYOUT = 6,           // s: LongBool
    WCA_FORCE_ICONIC_REPRESENTATION = 7,    // s: LongBool
    WCA_EXTENDED_FRAME_BOUNDS = 8,          // q: TRect
    WCA_HAS_ICONIC_BITMAP = 9,              // s: LongBool
    WCA_THEME_ATTRIBUTES = 10,              // s:
    WCA_NCRENDERING_EXILED = 11,            // s: LongBool
    WCA_NCADORNMENTINFO = 12,               // q:
    WCA_EXCLUDED_FROM_LIVEPREVIEW = 13,     // s: LongBool
    WCA_VIDEO_OVERLAY_ACTIVE = 14,
    WCA_FORCE_ACTIVEWINDOW_APPEARANCE = 15, // s: LongBool
    WCA_DISALLOW_PEEK = 16,                 // s: LongBool
    WCA_CLOAK = 17,                         // s: LongBool
    WCA_CLOAKED = 18,                       // q: TDwmCloakedAttribute
    WCA_ACCENT_POLICY = 19,                 // q, s:
    WCA_FREEZE_REPRESENTATION = 20,         // q, s: LongBool
    WCA_EVER_UNCLOAKED = 21,                // q: LongBool
    WCA_VISUAL_OWNER = 22,                  // s:
    WCA_HOLOGRAPHIC = 23,                   // q, s: LongBool
    WCA_EXCLUDED_FROM_DDA = 24,             // q, s: LongBool
    WCA_PASSIVEUPDATEMODE = 25,             // q, s: LongBool
    WCA_USEDARKMODECOLORS = 26,             // q, s: LongBool
    WCA_CORNER_STYLE = 27,                  // q, s: TCornerStyle
    WCA_PART_COLOR = 28,                    // s:
    WCA_DISABLE_MOVESIZE_FEEDBACK = 29,     // q, s: LongBool
    WCA_SYSTEMBACKDROP_TYPE = 30,           // q, s: TSystemBackdropType
    WCA_SET_TAGGED_WINDOW_RECT = 31,        // s:
    WCA_CLEAR_TAGGED_WINDOW_RECT = 32       // s:
  );

  // private
  [SDKName('WINDOWCOMPOSITIONATTRIBDATA')]
  TWindowCompositionAttribData = record
    Attrib: TWindowCompositionAttrib;
    [ReadsFrom, WritesTo] pvData: Pointer;
    [NumberOfBytes] cbData: Cardinal;
  end;
  PWindowCompositionAttribData = ^TWindowCompositionAttribData;

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

[SetsLastError]
[Result: ReleaseWith('CloseDesktop')]
function CreateDesktopW(
  [in] Desktop: PWideChar;
  [Reserved] Device: PWideChar;
  [Reserved] Devmode: Pointer;
  [in] Flags: TDesktopOpenOptions;
  [in] DesiredAccess: TDesktopAccessMask;
  [in, opt] SA: PSecurityAttributes
): THandle; stdcall; external user32;

[SetsLastError]
[Result: ReleaseWith('CloseDesktop')]
function OpenDesktopW(
  [in] Desktop: PWideChar;
  [in] Flags: TDesktopOpenOptions;
  [in] Inherit: LongBool;
  [in] DesiredAccess: TDesktopAccessMask
): THandle; stdcall; external user32;

[SetsLastError]
function EnumDesktopsW(
  [in, Access(WINSTA_ENUMDESKTOPS)] hWinStation: THandle;
  [in] EnumFunc: TStringEnumProcW;
  [in, opt] var Context
): LongBool; stdcall; external user32;

[SetsLastError]
function SwitchDesktop(
  [in, Access(DESKTOP_SWITCHDESKTOP)] hDesktop: THandle
): LongBool; stdcall; external user32;

[SetsLastError]
function SetThreadDesktop(
  [in] hDesktop: THandle
): LongBool; stdcall; external user32;

[SetsLastError]
function CloseDesktop(
  [in] hDesktop: THandle
): LongBool; stdcall; external user32;

[SetsLastError]
function GetThreadDesktop(
  [in] ThreadId: TThreadId32
): THandle; stdcall; external user32;

// Window Stations

[SetsLastError]
[Result: ReleaseWith('CloseWindowStation')]
function CreateWindowStationW(
  [in, opt] Winsta: PWideChar;
  [in] Flags: Cardinal;
  [in] DesiredAccess: TWinstaAccessMask;
  [in, opt] SA: PSecurityAttributes
): THandle; stdcall; external user32;

[SetsLastError]
[Result: ReleaseWith('CloseWindowStation')]
function OpenWindowStationW(
  [in] WinSta: PWideChar;
  [in] Inherit: LongBool;
  [in] DesiredAccess: TWinStaAccessMask
): THandle; stdcall; external user32;

[SetsLastError]
function EnumWindowStationsW(
  [in] EnumFunc: TStringEnumProcW;
  [in, opt] var Context
): LongBool; stdcall; external user32;

[SetsLastError]
function CloseWindowStation(
  [in] hWinStation: THandle
): LongBool; stdcall; external user32;

[SetsLastError]
function SetProcessWindowStation(
  [in] hWinStation: THandle
): LongBool; stdcall; external user32;

[SetsLastError]
function GetProcessWindowStation(
): THandle; stdcall; external user32;

// rev, usable only by winlogon
[SetsLastError]
function LockWindowStation(
  [in] hWinStation: THandle
): LongBool; stdcall; external user32;

// rev, usable only by winlogon
[SetsLastError]
function UnlockWindowStation(
  [in] hWinStation: THandle
): LongBool; stdcall; external user32;

// rev, usable only by winlogon
[SetsLastError]
function SetWindowStationUser(
  [in] hWinStation: THandle;
  [in] const [ref] Luid: TLuid;
  [in, ReadsFrom] Sid: PSid;
  [in, NumberOfBytes] SidLength: Cardinal
): LongBool; stdcall; external user32;

// User objects

[SetsLastError]
function GetUserObjectInformationW(
  [in] hObj: THandle;
  [in] InfoClass: TUserObjectInfoClass;
  [out, WritesTo] Info: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [out, opt, NumberOfBytes] LengthNeeded: PCardinal
): LongBool; stdcall; external user32;

[SetsLastError]
function SetUserObjectInformationW(
  [in] hObj: THandle;
  [in] InfoClass: TUserObjectInfoClass;
  [in, ReadsFrom] pvInfo: Pointer;
  [in, NumberOfBytes] Length: Cardinal
): LongBool; stdcall; external user32;

// Windows

[SetsLastError]
function GetDesktopWindow(
): THwnd; stdcall; external user32;

[SetsLastError]
function EnumWindows(
  [in] EnumFunc: TWndEnumProc;
  [in, opt] var Context
): LongBool; stdcall; external user32;

[SetsLastError]
function EnumDesktopWindows(
  [in, opt, Access(DESKTOP_READOBJECTS)] hDesktop: THandle;
  [in] EnumFunc: TWndEnumProc;
  [in, opt] var Context
): LongBool; stdcall; external user32;

[SetsLastError]
function EnumChildWindows(
  [in, opt] hWndParent: THwnd;
  [in] EnumFunc: TWndEnumProc;
  [in, opt] var Context
): LongBool; stdcall; external user32;

[SetsLastError]
function GetWindow(
  [in, opt] hWnd: THwnd;
  [in] Cmd: TGetWindowCmd
): THwnd; stdcall; external user32;

[SetsLastError]
function GetAncestor(
  [in] hWnd: THwnd;
  [in] Flags: TGetAncestorCmd
): THwnd; stdcall; external user32;

[SetsLastError]
function GetTopWindow(
  [in, opt] hWnd: THwnd
): THwnd; stdcall; external user32;

[SetsLastError]
function IsWindowVisible(
  [in] hWnd: THwnd
): LongBool; stdcall; external user32;

[SetsLastError]
[Result: NumberOfElements]
function GetClassNameW(
  [in] hWnd: THwnd;
  [out, WritesTo] ClassName: PWideChar;
  [in, NumberOfElements] nMaxCount: Cardinal
): Cardinal; stdcall; external user32;

[SetsLastError]
[Result: NumberOfElements]
function GetWindowTextLengthW(
  [in] hWnd: THwnd
): Cardinal; stdcall; external user32;

[SetsLastError]
[Result: NumberOfElements]
function GetWindowTextW(
  [in] hWnd: THwnd;
  [out, WritesTo] Text: PWideChar;
  [in, NumberOfElements] nMaxCount: Cardinal
): Cardinal; stdcall; external user32;

[SetsLastError]
function GetClassLongPtrW(
  [in] hWnd: THwnd;
  [in] Index: TClassLongIndex
): UIntPtr; stdcall; external user32;

[SetsLastError]
function SetClassLongPtrW(
  [in] hWnd: THwnd;
  [in] Index: TClassLongIndex;
  [in] NewLong: UIntPtr
): UIntPtr; stdcall; external user32;

[SetsLastError]
function GetWindowLongPtrW(
  [in] hWnd: THwnd;
  [in] Index: TWindowLongIndex
): UIntPtr; stdcall; external user32;

[SetsLastError]
function SetWindowLongPtrW(
  [in] hWnd: THwnd;
  [in] Index: TWindowLongIndex;
  [in] NewLong: UIntPtr
): UIntPtr; stdcall; external user32;

[SetsLastError]
[MinOSVersion(OsWin10RS1)]
function GetDpiForWindow(
  [in] hWnd: THwnd
): Cardinal; stdcall; external user32 delayed;

var delayed_GetDpiForWindow: TDelayedLoadFunction = (
  DllName: user32;
  FunctionName: 'GetDpiForWindow';
);

[SetsLastError]
function GetClientRect(
  [in] hWnd: THwnd;
  [out] out Rect: TRect
): LongBool; stdcall; external user32;

[SetsLastError]
function GetWindowRect(
  [in] hWnd: THwnd;
  [out] out Rect: TRect
): LongBool; stdcall; external user32;

[SetsLastError]
function SetWindowPos(
  [in] hWnd: THwnd;
  [in, opt] hWndInsertAfter: THwnd;
  [in] X: Integer;
  [in] Y: Integer;
  [in] CX: Integer;
  [in] CY: Integer;
  [in] Flags: TSetWindowPosFlags
): LongBool; stdcall; external user32;

[SetsLastError]
[MinOSVersion(OsWin8)]
function GetWindowBand(
  [in] hWnd: THwnd;
  [out] out Band: TZBandId
): LongBool; stdcall; external user32 delayed;

var delayed_GetWindowBand: TDelayedLoadFunction = (
  DllName: user32;
  FunctionName: 'GetWindowBand';
);

[SetsLastError]
function GetWindowCompositionAttribute(
  [in] hWnd: THwnd;
  [in, out] var cad: TWindowCompositionAttribData
): LongBool; stdcall; external user32;

[SetsLastError]
function SetWindowCompositionAttribute(
  [in] hWnd: THwnd;
  [in] const cad: TWindowCompositionAttribData
): LongBool; stdcall; external user32;

// Other

[SetsLastError]
function MessageBoxW(
  [in, opt] hWnd: THwnd;
  [in, opt] Text: PWideChar;
  [in, opt] Caption: PWideChar;
  [in] uType: TMessageStyle
): TMessageResponse; stdcall; external user32;

[SetsLastError]
function SendMessageTimeoutW(
  [in] hWnd: THwnd;
  [in] Msg: Cardinal;
  [in] wParam: NativeUInt;
  [in] lParam: NativeInt;
  [in] Flags: TSendMessageOptions;
  [in] Timeout: Cardinal;
  [out, opt] out dwResult: NativeInt
): NativeInt; stdcall; external user32;

[SetsLastError]
function WaitForInputIdle(
  [in] hProcess: THandle;
  [in] Milliseconds: Cardinal
): Cardinal; stdcall; external user32;

[SetsLastError]
function GetWindowDisplayAffinity(
  [in] hWnd: THwnd;
  [out] out Affinity: Cardinal
): LongBool; stdcall; external user32;

[SetsLastError]
function SetWindowDisplayAffinity(
  [in] hWnd: THwnd;
  [in] Affinity: Cardinal
): LongBool; stdcall; external user32;

[SetsLastError]
function GetWindowThreadProcessId(
  [in] hWnd: THwnd;
  [out, opt] out ProcessId: TProcessId32
): TThreadId32; stdcall; external user32;

function DestroyIcon(
  [in] Icon: THIcon
): LongBool stdcall; external user32;

[SetsLastError]
function GetGUIThreadInfo(
  [in] ThreadId: TThreadId32;
  [in, out] var Gui: TGuiThreadInfo
): LongBool; stdcall; external user32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
