unit Winapi.WinUser;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Winapi.WinBase;

const
  user32 = 'user32.dll';

  // 371
  SW_HIDE = 0;
  SW_SHOWNORMAL = 1;
  SW_SHOWMINIMIZED = 2;
  SW_SHOWMAXIMIZED = 3;
  SW_SHOWNOACTIVATE = 4;

  // 1353
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

  DesktopAccessMapping: array [0..8] of TFlagName = (
    (Value: DESKTOP_READOBJECTS;     Name: 'Read objects'),
    (Value: DESKTOP_CREATEWINDOW;    Name: 'Create window'),
    (Value: DESKTOP_CREATEMENU;      Name: 'Create menu'),
    (Value: DESKTOP_HOOKCONTROL;     Name: 'Hook control'),
    (Value: DESKTOP_JOURNALRECORD;   Name: 'Journal record'),
    (Value: DESKTOP_JOURNALPLAYBACK; Name: 'Journal playback'),
    (Value: DESKTOP_ENUMERATE;       Name: 'Enumerate'),
    (Value: DESKTOP_WRITEOBJECTS;    Name: 'Write objects'),
    (Value: DESKTOP_SWITCHDESKTOP;   Name: 'Switch desktop')
  );

  DesktopAccessType: TAccessMaskType = (
    TypeName: 'desktop';
    FullAccess: DESKTOP_ALL_ACCESS;
    Count: Length(DesktopAccessMapping);
    Mapping: PFlagNameRefs(@DesktopAccessMapping);
  );

  // 1533
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

  WinStaAccessMapping: array [0..8] of TFlagName = (
    (Value: WINSTA_ENUMDESKTOPS;      Name: 'Enumerate desktops'),
    (Value: WINSTA_READATTRIBUTES;    Name: 'Read attributes'),
    (Value: WINSTA_ACCESSCLIPBOARD;   Name: 'Access clipboard'),
    (Value: WINSTA_CREATEDESKTOP;     Name: 'Create desktop'),
    (Value: WINSTA_WRITEATTRIBUTES;   Name: 'Write attributes'),
    (Value: WINSTA_ACCESSGLOBALATOMS; Name: 'Access global atoms'),
    (Value: WINSTA_EXITWINDOWS;       Name: 'Exit Windows'),
    (Value: WINSTA_ENUMERATE;         Name: 'Enumerate'),
    (Value: WINSTA_READSCREEN;        Name: 'Read screen')
  );

  WinStaAccessType: TAccessMaskType = (
    TypeName: 'window station';
    FullAccess: WINSTA_ALL_ACCESS;
    Count: Length(WinStaAccessMapping);
    Mapping: PFlagNameRefs(@WinStaAccessMapping);
  );

  // 8897
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

  // 10853
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

type
  HWND = NativeUInt;
  HICON = NativeUInt;
  HDESK = THandle;
  HWINSTA = THandle;

  WPARAM = NativeUInt;
  LPARAM = NativeInt;

  TStringEnumProcW = function (Name: PWideChar; var Context: TArray<String>):
    LongBool; stdcall;

  // 1669
  TUserObjectInfoClass = (
    UserObjectReserved = 0,
    UserObjectFlags = 1,    // q, s: TUserObjectFlags
    UserObjectName = 2,     // q: PWideChar
    UserObjectType = 3,     // q: PWideChar
    UserObjectUserSid = 4,  // q: PSid
    UserObjectHeapSize = 5, // q: Cardinal
    UserObjectIO = 6        // q: LongBool
  );

  // 1682
  TUserObjectFlags = record
    fInherit: LongBool;
    fReserved: LongBool;
    dwFlags: Cardinal;
  end;
  PUserObjectFlags = ^TUserObjectFlags;

// Desktops

// 1387
function CreateDesktopW(lpszDesktop: PWideChar; lpszDevice: PWideChar;
  pDevmode: Pointer; dwFlags: Cardinal; dwDesiredAccess: TAccessMask;
  lpsa: PSecurityAttributes): HDESK; stdcall; external user32;

// 1450
function OpenDesktopW(pszDesktop: PWideChar; dwFlags: Cardinal;
  fInherit: LongBool; DesiredAccess: TAccessMask): HDESK; stdcall;
  external user32;

// 1480
function EnumDesktopsW(hWinStation: HWINSTA; lpEnumFunc: TStringEnumProcW;
  var Context: TArray<String>): LongBool; stdcall; external user32;

// 1502
function SwitchDesktop(hDesktop: HDESK): LongBool; stdcall; external user32;

// rev
function SwitchDesktopWithFade(hDesktop: HDESK; dwFadeTime: Cardinal): LongBool;
  stdcall; external user32;

// 1509
function SetThreadDesktop(hDesktop: HDESK): LongBool; stdcall; external user32;

// 1515
function CloseDesktop(hDesktop: HDESK): LongBool; stdcall; external user32;

// 1521
function GetThreadDesktop(dwThreadId: Cardinal): HDESK; stdcall;
  external user32;

// Window Stations

// 1571
function CreateWindowStationW(lpwinsta: PWideChar; dwFlags: Cardinal;
  dwDesiredAccess: TAccessMask; lpsa: PSecurityAttributes): HWINSTA; stdcall;
  external user32;

// 1592
function OpenWindowStationW(pszWinSta: PWideChar; fInherit: LongBool;
  DesiredAccess: TAccessMask): HWINSTA; stdcall; external user32;

// 1611
function EnumWindowStationsW(lpEnumFunc: TStringEnumProcW; var Context:
  TArray<String>): LongBool; stdcall; external user32;

// 1623
function CloseWindowStation(hWinStation: HWINSTA): LongBool; stdcall;
  external user32;

// 1629
function SetProcessWindowStation(hWinSta: HWINSTA): LongBool; stdcall;
  external user32;

// 1635
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

// 1700
function GetUserObjectInformationW(hObj: THandle;
  InfoClass: TUserObjectInfoClass; pvInfo: Pointer; nLength: Cardinal;
  pnLengthNeeded: PCardinal): LongBool; stdcall; external user32;

// 1723
function SetUserObjectInformationW(hObj: THandle; InfoClass:
  TUserObjectInfoClass; pvInfo: Pointer; nLength: Cardinal): LongBool; stdcall;
  external user32;

// Other

// 4058
function WaitForInputIdle(hProcess: THandle; dwMilliseconds: Cardinal):
  Cardinal; stdcall; external user32;

// 10618
function DestroyIcon(Icon: HICON): LongBool stdcall; external user32;

implementation

end.
