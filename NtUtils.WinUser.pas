unit NtUtils.WinUser;

{
  This module includes various functions for working with window stations,
  desktops, and other parts of graphical subsystem.
}

interface

uses
  Ntapi.WinNt, Ntapi.WinUser, NtUtils, NtUtils.Objects;

const
  DEFAULT_USER_TIMEOUT = 1000; // in ms

type
  TGuiThreadInfo = Ntapi.WinUser.TGuiThreadInfo;

{ Common: Desktop / Window Station }

// Query any information
function UsrxQuery(
  hObj: THandle;
  InfoClass: TUserObjectInfoClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Quer user object name
function UsrxQueryName(
  hObj: THandle;
  out Name: String
): TNtxStatus;

// Query user object SID.
// NOTE: The function might return NULL.
function UsrxQuerySid(
  hObj: THandle;
  out Sid: ISid
): TNtxStatus;

type
  UsrxObject = class abstract
    // Query fixed-size information
    class function Query<T>(
      hObject: THandle;
      InfoClass: TUserObjectInfoClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

{ Window stations }

// Get a handle to the current window station
function UsrxCurrentWindowStation: THandle;

// Change the window station of the current process
function UsrxSetProcessWindowStation(
  hWinSta: THandle
): TNtxStatus;

// Open window station
function UsrxOpenWindowStation(
  out hxWinSta: IHandle;
  const Name: String;
  DesiredAccess: TWinstaAccessMask;
  InheritHandle: Boolean = False
): TNtxStatus;

// Enumerate window stations of current session
function UsrxEnumerateWindowStations(
  out WinStations: TArray<String>
): TNtxStatus;

{ Desktops }

// Get a handle to the current desktop
function UsrxCurrentDesktop: THandle;

// Change the desktop of the current thread
function UsrxSetThreadDesktop(
  hDesktop: THandle
): TNtxStatus;

// Open desktop
function UsrxOpenDesktop(
  out hxDesktop: IHandle;
  const Name: String;
  DesiredAccess: TDesktopAccessMask;
  InheritHandle: Boolean = False
): TNtxStatus;

// Create a desktop
function UsrxCreateDesktop(
  out hxDesktop: IHandle;
  const Name: String;
  Flags: TDesktopOpenOptions = 0;
  const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Query a name of a current desktop
function UsrxCurrentDesktopName: String;

// Enumerate desktops of a window station
function UsrxEnumerateDesktops(
  [Access(WINSTA_ENUMDESKTOPS)] WinSta: THandle;
  out Desktops: TArray<String>
): TNtxStatus;

// Enumerate all accessable desktops from different window stations
function UsrxEnumerateAllDesktops(
): TArray<String>;

// Switch to a desktop
function UsrxSwithToDesktop(
  [Access(DESKTOP_SWITCHDESKTOP)] hDesktop: THandle
): TNtxStatus;

function UsrxSwithToDesktopByName(
  const DesktopName: String
): TNtxStatus;

{ Threads }

// Check if a thread is owns any GUI objects
function UsrxIsGuiThread(
  TID: TThreadId32
): Boolean;

// Get GUI information for a thread
function UsrxGetGuiInfoThread(
  TID: TThreadId32;
  out GuiInfo: TGuiThreadInfo
): TNtxStatus;

{ Windows }

// Get the root window on the current desktop
function UsrxGetDesktopWindow: THwnd;

// Enumerate top-level windows on a desktop
function UsrxEnumerateDesktopWindows(
  out Hwnds: TArray<THwnd>;
  [opt, Access(DESKTOP_READOBJECTS)] hDesktop: THandle = 0
): TNtxStatus;

// Enumerate child windows
function UsrxEnumerateChildWindows(
  out Hwnds: TArray<THwnd>;
  [opt] ParentWnd: THwnd = 0
): TNtxStatus;

// Query if a specific window is visible
function UsrxGetIsVisibleWindow(
  out IsVisible: LongBool;
  hWnd: THwnd
): TNtxStatus;

// Get process and thread IDs of the window creator
function UsrxGetProcessThreadIdWindow(
  out PID: TProcessId32;
  out TID: TThreadId32;
  hWnd: THwnd
): TNtxStatus;

// Query class name of a window
function UsrxGetClassNameWindow(
  out ClassName: String;
  hWnd: THwnd
): TNtxStatus;

// Query text of a window without sending messages
function UsrxGetTextWindow(
  out Text: String;
  hWnd: THwnd
): TNtxStatus;

{ Messages }

// Send a window message with a timeout
function UsrxSendMessage(
  out Outcome: NativeInt;
  hWindow: THwnd;
  Msg: Cardinal;
  wParam: NativeUInt;
  lParam: NativeInt;
  Flags: TSendMessageOptions = SMTO_ABORTIFHUNG;
  Timeout: Cardinal = DEFAULT_USER_TIMEOUT
): TNtxStatus;

// Get text of a window.
// The function ensures to retrieve a complete string despite race conditions.
function UsrxGetWindowText(
  Control: THwnd;
  out Text: String
): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntstatus, Ntapi.ntpebteb, Ntapi.ntrtl, Ntapi.WinBase,
  Ntapi.WinError, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Helpers }

function CollectNames(
  Name: PWideChar;
  var Context
): LongBool; stdcall;
var
  Names: TArray<String> absolute Context;
begin
  // Save the value and succeed
  SetLength(Names, Length(Names) + 1);
  Names[High(Names)] := String(Name);
  Result := True;
end;

function CollectWnds(
  hwnd: THwnd;
  var Context
): LongBool; stdcall;
var
  Windows: TArray<THwnd> absolute Context;
begin
  // Save the value and succeed
  SetLength(Windows, Length(Windows) + 1);
  Windows[High(Windows)] := hwnd;
  Result := True;
end;

{ Common }

function UsrxQuery;
var
  Required: Cardinal;
begin
  Result.Location := 'GetUserObjectInformationW';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := GetUserObjectInformationW(hObj, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function UsrxQueryName;
var
  xMemory: IWideChar;
begin
  Result := UsrxQuery(hObj, UOI_NAME, IMemory(xMemory));

  if Result.IsSuccess then
    Name := String(xMemory.Data);
end;

function UsrxQuerySid;
begin
  Result := UsrxQuery(hObj, UOI_USER_SID, IMemory(Sid));

  if not Assigned(Sid.Data) then
    Sid := nil;
end;

class function UsrxObject.Query<T>;
begin
  Result.Location := 'GetUserObjectInformationW';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  Result.Win32Result := GetUserObjectInformationW(hObject, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

{ Window Stations}

function UsrxCurrentWindowStation;
begin
  Result := GetProcessWindowStation;
end;

function UsrxSetProcessWindowStation;
begin
  Result.Location := 'SetProcessWindowStation';
  Result.Win32Result := SetProcessWindowStation(hWinSta);
end;

function UsrxOpenWindowStation;
var
  hWinSta: THandle;
begin
  Result.Location := 'OpenWindowStationW';
  Result.LastCall.OpensForAccess(DesiredAccess);

  hWinSta := OpenWindowStationW(PWideChar(Name), InheritHandle, DesiredAccess);
  Result.Win32Result := (hWinSta <> 0);

  if Result.IsSuccess then
    hxWinSta := Auto.CaptureHandle(hWinSta);
end;

function UsrxEnumerateWindowStations;
begin
  SetLength(WinStations, 0);
  Result.Location := 'EnumWindowStationsW';
  Result.Win32Result := EnumWindowStationsW(CollectNames, WinStations);
end;

{ Desktops }

function UsrxCurrentDesktop;
begin
  Result := GetThreadDesktop(NtCurrentThreadId);
end;

function UsrxSetThreadDesktop;
begin
  Result.Location := 'SetThreadDesktop';
  Result.Win32Result := SetThreadDesktop(hDesktop);
end;

function UsrxOpenDesktop;
var
  hDesktop: THandle;
begin
  Result.Location := 'OpenDesktopW';
  Result.LastCall.OpensForAccess(DesiredAccess);

  hDesktop := OpenDesktopW(PWideChar(Name), 0, InheritHandle, DesiredAccess);
  Result.Win32Result := (hDesktop <> 0);

  if Result.IsSuccess then
    hxDesktop := Auto.CaptureHandle(hDesktop);
end;

function UsrxCreateDesktop;
var
  hDesktop: THandle;
  DesiredAccess: TDesktopAccessMask;
  SA: TSecurityAttributes;
begin
  DesiredAccess := AccessMaskOverride(MAXIMUM_ALLOWED, ObjectAttributes);

  Result.Location := 'CreateDesktopW';
  Result.LastCall.OpensForAccess(DesiredAccess);

  hDesktop := CreateDesktopW(PWideChar(Name), nil, nil, Flags, DesiredAccess,
    ReferenceSecurityAttributes(SA, ObjectAttributes));

  Result.Win32Result := hDesktop <> 0;

  if Result.IsSuccess then
    hxDesktop := Auto.CaptureHandle(hDesktop);
end;

function UsrxCurrentDesktopName;
var
  DesktopName, WinStaName: String;
begin
  // Note: we assume the current desktop belongs to the current window station,
  // which might not be correct if somebody changed it

  // Try to query the name
  if UsrxQueryName(UsrxCurrentDesktop, DesktopName).IsSuccess and
    UsrxQueryName(UsrxCurrentWindowStation, WinStaName).IsSuccess then
      Result := WinStaName + '\' + DesktopName
  else
    // Fallback to reading the startup info
    Result := RtlGetCurrentPeb.ProcessParameters.DesktopInfo.ToString;
end;

function UsrxEnumerateDesktops;
begin
  SetLength(Desktops, 0);
  Result.Location := 'EnumDesktopsW';
  Result.LastCall.Expects<TWinStaAccessMask>(WINSTA_ENUMDESKTOPS);
  Result.Win32Result := EnumDesktopsW(WinSta, CollectNames, Desktops);
end;

function UsrxEnumerateAllDesktops;
var
  i, j: Integer;
  hxWinSta: IHandle;
  WinStations, Desktops: TArray<String>;
begin
  SetLength(Result, 0);

  // Enumerate accessible window stations
  if not UsrxEnumerateWindowStations(WinStations).IsSuccess then
    Exit;

  for i := 0 to High(WinStations) do
  begin
    // Open each window station
    if not UsrxOpenWindowStation(hxWinSta, WinStations[i],
      WINSTA_ENUMDESKTOPS).IsSuccess then
      Continue;

    // Enumerate desktops of this window station
    if UsrxEnumerateDesktops(hxWinSta.Handle, Desktops).IsSuccess then
    begin
      // Expand each name
      for j := 0 to High(Desktops) do
        Desktops[j] := WinStations[i] + '\' + Desktops[j];

      Insert(Desktops, Result, Length(Result));
    end;
  end;
end;

function UsrxSwithToDesktop;
begin
  Result.Location := 'SwitchDesktop';
  Result.LastCall.Expects<TDesktopAccessMask>(DESKTOP_SWITCHDESKTOP);
  Result.Win32Result := SwitchDesktop(hDesktop);
end;

function UsrxSwithToDesktopByName;
var
  hxDesktop: IHandle;
begin
  Result := UsrxOpenDesktop(hxDesktop, DesktopName, DESKTOP_SWITCHDESKTOP);

  if Result.IsSuccess then
    Result := UsrxSwithToDesktop(hxDesktop.Handle);
end;

{ Threads }

function UsrxIsGuiThread;
var
  GuiInfo: TGuiThreadInfo;
begin
  GuiInfo := Default(TGuiThreadInfo);
  GuiInfo.Size := SizeOf(GuiInfo);
  Result := GetGUIThreadInfo(TID, GuiInfo);
end;

function UsrxGetGuiInfoThread;
begin
  GuiInfo := Default(TGuiThreadInfo);
  GuiInfo.Size := SizeOf(GuiInfo);

  Result.Location := 'GetGUIThreadInfo';
  Result.Win32Result := GetGUIThreadInfo(TID, GuiInfo);
end;

{ Windows }

function UsrxGetDesktopWindow;
begin
  Result := GetDesktopWindow;
end;

function UsrxEnumerateDesktopWindows;
begin
  Result.Location := 'EnumDesktopWindows';
  Result.Win32Result := EnumDesktopWindows(hDesktop, CollectWnds, Hwnds);
end;

function UsrxEnumerateChildWindows;
begin
  Result.Location := 'EnumChildWindows';
  Result.Win32Result := EnumChildWindows(ParentWnd, CollectWnds, Hwnds);
end;

function UsrxGetIsVisibleWindow;
begin
  Result.Location := 'IsWindowVisible';
  RtlSetLastWin32ErrorAndNtStatusFromNtStatus(STATUS_SUCCESS);
  IsVisible := IsWindowVisible(hWnd);
  Result.Win32Result := IsVisible or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function UsrxGetProcessThreadIdWindow;
begin
  Result.Location := 'GetWindowThreadProcessId';
  TID := GetWindowThreadProcessId(Hwnd, PID);
  Result.Win32Result := TID <> 0;
end;

function UsrxGetClassNameWindow;
const
  MAX_CLASS_NAME = 256;
var
  Buffer: array [0..MAX_CLASS_NAME - 1] of WideChar;
  ReturnedLength: Cardinal;
begin
  Result.Location := 'GetClassNameW';
  ReturnedLength := GetClassNameW(hWnd, Buffer, MAX_CLASS_NAME);
  Result.Win32Result := (ReturnedLength > 0) and
    (ReturnedLength <= MAX_CLASS_NAME);

  if Result.IsSuccess then
    ClassName := RtlxCaptureString(Buffer, ReturnedLength);
end;

function UsrxGetTextWindow;
var
  Buffer: IMemory;
  BufferLength, ReturnedLength: Cardinal;
begin
  Result.Location := 'GetWindowTextW';

  Buffer := Auto.AllocateDynamic((GetWindowTextLengthW(hWnd) + 2) *
    SizeOf(WideChar));
  repeat
    BufferLength := Buffer.Size div SizeOf(WideChar);
    ReturnedLength := GetWindowTextW(hWnd, Buffer.Data, BufferLength);

    if ReturnedLength = 0 then
      Result.Win32Result := False
    else if ReturnedLength = Pred(BufferLength) then
      Result.Status := STATUS_BUFFER_TOO_SMALL
    else
      Result.Status := STATUS_SUCCESS;

  until not NtxExpandBufferEx(Result, Buffer, Buffer.Size * 2, nil);

  if Result.IsSuccess then
    Text := RtlxCaptureString(Buffer.Data, ReturnedLength);
end;

{ Messages }

function UsrxSendMessage;
begin
  Result.Location := 'SendMessageTimeoutW';
  Result.Win32Result := SendMessageTimeoutW(hWindow, Msg, wParam, lParam,
    Flags, Timeout, Outcome) <> 0;
end;

function UsrxGetWindowText;
var
  xMemory: IMemory;
  BufferLength, CopiedLength: NativeInt;
begin
  CopiedLength := 0;

  repeat
    // Get the required buffer length
    Result := UsrxSendMessage(BufferLength, Control, WM_GETTEXTLENGTH, 0, 0,
      SMTO_ABORTIFHUNG, DEFAULT_USER_TIMEOUT);

    if not Result.IsSuccess then
      Exit;

    if BufferLength >= High(Word) then
    begin
      // The text claims to be suspiciously long
      Result.Location := 'UsrxGetWindowText';
      Result.Status := STATUS_IMPLEMENTATION_LIMIT;
      Exit;
    end;

    // Include room for a zero terminator + some more to help us gracefully
    // handle race conditions
    Inc(BufferLength, 2);

    xMemory := Auto.AllocateDynamic(BufferLength * SizeOf(WideChar));

    // Get the text
    Result := UsrxSendMessage(CopiedLength, Control, WM_GETTEXT, BufferLength,
      IntPtr(xMemory.Data), SMTO_ABORTIFHUNG, DEFAULT_USER_TIMEOUT);

    if not Result.IsSuccess then
      Exit;

    // Because WM_GETTEXT tries to copy as much data as fits into the buffer,
    // we allocated slightly more space than required. If there was a race
    // condition and the text changed, so it does not fit into the buffer
    // anymore, SendMessageW will use up the reserved space. That's how we know
    // something went wrong and we need to retry.
  until CopiedLength < Pred(BufferLength);

  SetString(Text, PWideChar(xMemory.Data), CopiedLength);
end;

end.
