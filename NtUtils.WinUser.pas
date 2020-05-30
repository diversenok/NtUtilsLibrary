unit NtUtils.WinUser;

interface

uses
  Winapi.WinNt, Winapi.WinUser, NtUtils, NtUtils.Security.Sid, NtUtils.Objects;

type
  TGuiThreadInfo = Winapi.WinUser.TGuiThreadInfo;

{ Open }

// Open desktop
function UsrxOpenDesktop(out hxDesktop: IHandle; Name: String;
  DesiredAccess: TAccessMask; InheritHandle: Boolean = False): TNtxStatus;

// Open window station
function UsrxOpenWindowStation(out hxWinSta: IHandle; Name: String;
  DesiredAccess: TAccessMask; InheritHandle: Boolean = False): TNtxStatus;

{ Query information }

// Query any information
function UsrxQuery(hObj: THandle; InfoClass: TUserObjectInfoClass;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil): TNtxStatus;

// Quer user object name
function UsrxQueryName(hObj: THandle; out Name: String): TNtxStatus;

// Query user object SID
function UsrxQuerySid(hObj: THandle; out Sid: ISid): TNtxStatus;

type
  UsrxObject = class abstract
    // Query fixed-size information
    class function Query<T>(hObject: THandle;
      InfoClass: TUserObjectInfoClass; out Buffer: T): TNtxStatus; static;
  end;

// Query a name of a current desktop
function UsrxCurrentDesktopName: String;

{ Enumerations }

// Enumerate window stations of current session
function UsrxEnumWindowStations(out WinStations: TArray<String>): TNtxStatus;

// Enumerate desktops of a window station
function UsrxEnumDesktops(WinSta: HWINSTA; out Desktops: TArray<String>):
  TNtxStatus;

// Enumerate all accessable desktops from different window stations
function UsrxEnumAllDesktops: TArray<String>;

{ Actions }

// Switch to a desktop
function UsrxSwithToDesktop(hDesktop: THandle; FadeTime: Cardinal = 0)
  : TNtxStatus;

function UsrxSwithToDesktopByName(DesktopName: String; FadeTime: Cardinal = 0)
  : TNtxStatus;

{ Other }

// Check if a thread is owns any GUI objects
function UsrxIsGuiThread(TID: TThreadId): Boolean;

// Get GUI information for a thread
function UsrxGetGuiInfoThread(TID: TThreadId; out GuiInfo: TGuiThreadInfo):
  TNtxStatus;

implementation

uses
  Winapi.ProcessThreadsApi, Ntapi.ntpsapi, DelphiUtils.AutoObject;

function UsrxOpenDesktop(out hxDesktop: IHandle; Name: String;
  DesiredAccess: TAccessMask; InheritHandle: Boolean): TNtxStatus;
var
  hDesktop: THandle;
begin
  Result.Location := 'OpenDesktopW';
  Result.LastCall.AttachAccess<TDesktopAccessMask>(DesiredAccess);

  hDesktop := OpenDesktopW(PWideChar(Name), 0, InheritHandle, DesiredAccess);
  Result.Win32Result := (hDesktop <> 0);

  if Result.IsSuccess then
    hxDesktop := TAutoHandle.Capture(hDesktop);
end;

function UsrxOpenWindowStation(out hxWinSta: IHandle; Name: String;
  DesiredAccess: TAccessMask; InheritHandle: Boolean): TNtxStatus;
var
  hWinSta: THandle;
begin
  Result.Location := 'OpenWindowStationW';
  Result.LastCall.AttachAccess<TWinstaAccessMask>(DesiredAccess);

  hWinSta := OpenWindowStationW(PWideChar(Name), InheritHandle, DesiredAccess);
  Result.Win32Result := (hWinSta <> 0);

  if Result.IsSuccess then
    hxWinSta := TAutoHandle.Capture(hWinSta);
end;

function UsrxQuery(hObj: THandle; InfoClass: TUserObjectInfoClass;
  out xMemory: IMemory; InitialBuffer: Cardinal; GrowthMethod:
  TBufferGrowthMethod): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'GetUserObjectInformationW';
  Result.LastCall.AttachInfoClass(InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := GetUserObjectInformationW(hObj, InfoClass,
      xMemory.Data, xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function UsrxQueryName(hObj: THandle; out Name: String): TNtxStatus;
var
  xMemory: IMemory<PWideChar>;
begin
  Result := UsrxQuery(hObj, UOI_NAME, IMemory(xMemory));

  if Result.IsSuccess then
    Name := String(xMemory.Data);
end;

function UsrxQuerySid(hObj: THandle; out Sid: ISid): TNtxStatus;
begin
  Result := UsrxQuery(hObj, UOI_USER_SID, IMemory(Sid));
end;

class function UsrxObject.Query<T>(hObject: THandle;
  InfoClass: TUserObjectInfoClass; out Buffer: T): TNtxStatus;
begin
  Result.Location := 'GetUserObjectInformationW';
  Result.LastCall.AttachInfoClass(InfoClass);

  Result.Win32Result := GetUserObjectInformationW(hObject, InfoClass,
    @Buffer, SizeOf(Buffer), nil);
end;

function UsrxCurrentDesktopName: String;
var
  WinStaName: String;
  StartupInfo: TStartupInfoW;
begin
  // Read our thread's desktop and query its name
  if UsrxQueryName(GetThreadDesktop(NtCurrentThreadId), Result).IsSuccess
    then
  begin
    if UsrxQueryName(GetProcessWindowStation, WinStaName).IsSuccess then
      Result := WinStaName + '\' + Result;
  end
  else
  begin
    // This is very unlikely to happen. Fall back to using the value
    // from the startupinfo structure.
    GetStartupInfoW(StartupInfo);
    Result := String(StartupInfo.Desktop);
  end;
end;

function EnumCallback(Name: PWideChar; var Context: TArray<String>): LongBool;
  stdcall;
begin
  // Save the value and succeed
  SetLength(Context, Length(Context) + 1);
  Context[High(Context)] := String(Name);
  Result := True;
end;

function UsrxEnumWindowStations(out WinStations: TArray<String>): TNtxStatus;
begin
  SetLength(WinStations, 0);
  Result.Location := 'EnumWindowStationsW';
  Result.Win32Result := EnumWindowStationsW(EnumCallback, WinStations);
end;

function UsrxEnumDesktops(WinSta: HWINSTA; out Desktops: TArray<String>):
  TNtxStatus;
begin
  SetLength(Desktops, 0);
  Result.Location := 'EnumDesktopsW';
  Result.Win32Result := EnumDesktopsW(WinSta, EnumCallback, Desktops);
end;

function UsrxEnumAllDesktops: TArray<String>;
var
  i, j: Integer;
  hWinStation: HWINSTA;
  WinStations, Desktops: TArray<String>;
begin
  SetLength(Result, 0);

  // Enumerate accessable window stations
  if not UsrxEnumWindowStations(WinStations).IsSuccess then
    Exit;

  for i := 0 to High(WinStations) do
  begin
    // Open each window station
    hWinStation := OpenWindowStationW(PWideChar(WinStations[i]), False,
      WINSTA_ENUMDESKTOPS);

    if hWinStation = 0 then
      Continue;

    // Enumerate desktops of this window station
    if UsrxEnumDesktops(hWinStation, Desktops).IsSuccess then
    begin
      // Expand each name
      for j := 0 to High(Desktops) do
        Desktops[j] := WinStations[i] + '\' + Desktops[j];

      Insert(Desktops, Result, Length(Result));
    end;

   CloseWindowStation(hWinStation);
  end;
end;

function UsrxSwithToDesktop(hDesktop: THandle; FadeTime: Cardinal): TNtxStatus;
begin
  if FadeTime = 0 then
  begin
    Result.Location := 'SwitchDesktop';
    Result.LastCall.Expects<TDesktopAccessMask>(DESKTOP_SWITCHDESKTOP);
    Result.Win32Result := SwitchDesktop(hDesktop);
  end
  else
  begin
    Result.Location := 'SwitchDesktopWithFade';
    Result.LastCall.Expects<TDesktopAccessMask>(DESKTOP_SWITCHDESKTOP);
    Result.Win32Result := SwitchDesktopWithFade(hDesktop, FadeTime);
  end;
end;

function UsrxSwithToDesktopByName(DesktopName: String; FadeTime: Cardinal)
  : TNtxStatus;
var
  hxDesktop: IHandle;
begin
  Result := UsrxOpenDesktop(hxDesktop, DesktopName, DESKTOP_SWITCHDESKTOP);

  if Result.IsSuccess then
    Result := UsrxSwithToDesktop(hxDesktop.Handle, FadeTime);
end;

function UsrxIsGuiThread(TID: TThreadId): Boolean;
var
  GuiInfo: TGuiThreadInfo;
begin
  FillChar(GuiInfo, SizeOf(GuiInfo), 0);
  GuiInfo.Size := SizeOf(GuiInfo);
  Result := GetGUIThreadInfo(Cardinal(TID), GuiInfo);
end;

function UsrxGetGuiInfoThread(TID: TThreadId; out GuiInfo: TGuiThreadInfo):
  TNtxStatus;
begin
  FillChar(GuiInfo, SizeOf(GuiInfo), 0);
  GuiInfo.Size := SizeOf(GuiInfo);

  Result.Location := 'GetGUIThreadInfo';
  Result.Win32Result := GetGUIThreadInfo(Cardinal(TID), GuiInfo);
end;

end.
