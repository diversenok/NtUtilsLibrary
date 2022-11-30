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

{ Open }

// Get a handle to the current desktop/window station
function UsrxCurrentDesktop: THandle;
function UsrxCurrentWindowStation: THandle;

// Open desktop
function UsrxOpenDesktop(
  out hxDesktop: IHandle;
  const Name: String;
  DesiredAccess: TDesktopAccessMask;
  InheritHandle: Boolean = False
): TNtxStatus;

// Open window station
function UsrxOpenWindowStation(
  out hxWinSta: IHandle;
  const Name: String;
  DesiredAccess: TWinstaAccessMask;
  InheritHandle: Boolean = False
): TNtxStatus;

// Change the desktop of the current thread
function UsrxSetThreadDesktop(
  hDesktop: THandle
): TNtxStatus;

// Change the window station of the current process
function UsrxSetProcessWindowStation(
  hWinSta: THandle
): TNtxStatus;

{ Query information }

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

// Query a name of a current desktop
function UsrxCurrentDesktopName: String;

{ Enumerations }

// Enumerate window stations of current session
function UsrxEnumWindowStations(
  out WinStations: TArray<String>
): TNtxStatus;

// Enumerate desktops of a window station
function UsrxEnumDesktops(
  [Access(WINSTA_ENUMDESKTOPS)] WinSta: THandle;
  out Desktops: TArray<String>
): TNtxStatus;

// Enumerate all accessable desktops from different window stations
function UsrxEnumAllDesktops: TArray<String>;

{ Actions }

// Switch to a desktop
function UsrxSwithToDesktop(
  [Access(DESKTOP_SWITCHDESKTOP)] hDesktop: THandle
): TNtxStatus;

function UsrxSwithToDesktopByName(
  const DesktopName: String
): TNtxStatus;

{ Other }

// Check if a thread is owns any GUI objects
function UsrxIsGuiThread(
  TID: TThreadId32
): Boolean;

// Get GUI information for a thread
function UsrxGetGuiInfoThread(
  TID: TThreadId32;
  out GuiInfo: TGuiThreadInfo
): TNtxStatus;

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
  Ntapi.ntpsapi, Ntapi.ntstatus, Ntapi.ntpebteb;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function UsrxCurrentDesktop;
begin
  Result := GetThreadDesktop(NtCurrentThreadId);
end;

function UsrxCurrentWindowStation;
begin
  Result := GetProcessWindowStation;
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

function UsrxSetThreadDesktop;
begin
  Result.Location := 'SetThreadDesktop';
  Result.Win32Result := SetThreadDesktop(hDesktop);
end;

function UsrxSetProcessWindowStation;
begin
  Result.Location := 'SetProcessWindowStation';
  Result.Win32Result := SetProcessWindowStation(hWinSta);
end;

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

function EnumCallback(
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

function UsrxEnumWindowStations;
begin
  SetLength(WinStations, 0);
  Result.Location := 'EnumWindowStationsW';
  Result.Win32Result := EnumWindowStationsW(EnumCallback, WinStations);
end;

function UsrxEnumDesktops;
begin
  SetLength(Desktops, 0);
  Result.Location := 'EnumDesktopsW';
  Result.LastCall.Expects<TWinStaAccessMask>(WINSTA_ENUMDESKTOPS);
  Result.Win32Result := EnumDesktopsW(WinSta, EnumCallback, Desktops);
end;

function UsrxEnumAllDesktops;
var
  i, j: Integer;
  hxWinSta: IHandle;
  WinStations, Desktops: TArray<String>;
begin
  SetLength(Result, 0);

  // Enumerate accessible window stations
  if not UsrxEnumWindowStations(WinStations).IsSuccess then
    Exit;

  for i := 0 to High(WinStations) do
  begin
    // Open each window station
    if not UsrxOpenWindowStation(hxWinSta, WinStations[i],
      WINSTA_ENUMDESKTOPS).IsSuccess then
      Continue;

    // Enumerate desktops of this window station
    if UsrxEnumDesktops(hxWinSta.Handle, Desktops).IsSuccess then
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

function UsrxSendMessage;
begin
  Result.Location := 'SendMessageTimeoutW';
  Result.Win32Result := SendMessageTimeoutW(hWindow, Msg, wParam, lParam,
    Flags, Timeout, Outcome) <> 0;
end;

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
