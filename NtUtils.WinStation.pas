unit NtUtils.WinStation;

interface

uses
  Winapi.winsta, NtUtils, NtUtils.Objects, DelphiUtils.AutoObject;

type
  TSessionIdW = Winapi.winsta.TSessionIdW;

  TWinStaHandle = Winapi.winsta.TWinStaHandle;
  IWinStaHandle = DelphiUtils.AutoObject.IHandle;

  TWinStaAutoHandle = class(TCustomAutoHandle, IWinStaHandle)
    destructor Destroy; override;
  end;

// Connect to a remote computer
function WsxOpenServer(out hxServer: IWinStaHandle; Name: String): TNtxStatus;

// Enumerate all session on the server for which we have Query access
function WsxEnumerateSessions(out Sessions: TArray<TSessionIdW>;
  hServer: TWinStaHandle = SERVER_CURRENT): TNtxStatus;

type
  WsxWinStation = class
    // Query fixed-size information
    class function Query<T>(SessionId: Cardinal; InfoClass:
      TWinStationInfoClass; out Buffer: T; hServer: TWinStaHandle =
      SERVER_CURRENT): TNtxStatus; static;
  end;

// Query variable-size information
function WsxQuery(SessionId: Cardinal; InfoClass: TWinStationInfoClass;
  out xMemory: IMemory; hServer: TWinStaHandle = SERVER_CURRENT): TNtxStatus;

// Format a name of a session, always succeeds with at least an ID
function WsxQueryName(SessionId: Cardinal;
  hServer: TWinStaHandle = SERVER_CURRENT): String;

// Open session token
function WsxQueryToken(out hxToken: IHandle; SessionId: Cardinal;
  hServer: TWinStaHandle = SERVER_CURRENT): TNtxStatus;

// Send a message to a session
function WsxSendMessage(SessionId: Cardinal; Title, MessageStr: String;
  Style: Cardinal; Timeout: Cardinal; WaitForResponse: Boolean = False;
  pResponse: PCardinal = nil; ServerHandle: TWinStaHandle = SERVER_CURRENT):
  TNtxStatus;

// Connect one session to another
function WsxConnect(SessionId: Cardinal; TargetSessionId: Cardinal =
  LOGONID_CURRENT; Password: PWideChar = nil; Wait: Boolean = True;
  hServer: TWinStaHandle = SERVER_CURRENT): TNtxStatus;

// Disconnect a session
function WsxDisconnect(SessionId: Cardinal; Wait: Boolean; hServer:
  TWinStaHandle = SERVER_CURRENT): TNtxStatus;

// Remote control (shadow) an active remote session
function WsxRemoteControl(TargetSessionId: Cardinal; HotKeyVk: Byte;
  HotkeyModifiers: Word; hServer: TWinStaHandle = SERVER_CURRENT;
  TargetServer: String = ''): TNtxStatus;

// Stop controlling (shadowing) a session
function WsxRemoteControlStop(hServer: TWinStaHandle; SessionId: Cardinal;
  Wait: Boolean): TNtxStatus;

implementation

uses
  System.SysUtils;

destructor TWinStaAutoHandle.Destroy;
begin
  if FAutoRelease then
    WinStationCloseServer(FHandle);
  inherited;
end;

function WsxOpenServer(out hxServer: IWinStaHandle; Name: String): TNtxStatus;
var
  hServer: TWinStaHandle;
begin
  Result.Location := 'WinStationOpenServerW';
  hServer := WinStationOpenServerW(PWideChar(Name));
  Result.Win32Result := hServer <> 0;

  if Result.IsSuccess then
    hxServer := TAutoHandle.Capture(hServer);
end;

function WsxEnumerateSessions(out Sessions: TArray<TSessionIdW>;
  hServer: TWinStaHandle = SERVER_CURRENT): TNtxStatus;
var
  Buffer: PSessionIdArrayW;
  Count, i: Integer;
begin
  Result.Location := 'WinStationEnumerateW';
  Result.Win32Result := WinStationEnumerateW(hServer, Buffer, Count);

  if Result.IsSuccess then
  begin
    SetLength(Sessions, Count);

    for i := 0 to High(Sessions) do
      Sessions[i] := Buffer{$R-}[i]{$R+};

    WinStationFreeMemory(Buffer);
  end;
end;

class function WsxWinStation.Query<T>(SessionId: Cardinal; InfoClass:
  TWinStationInfoClass; out Buffer: T; hServer: TWinStaHandle): TNtxStatus;
var
  Returned: Cardinal;
begin
  Result.Location := 'WinStationQueryInformationW';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TWinStationInfoClass);

  Result.Win32Result := WinStationQueryInformationW(hServer, SessionId,
    InfoClass, @Buffer, SizeOf(Buffer), Returned);
end;

function WsxQuery(SessionId: Cardinal; InfoClass: TWinStationInfoClass;
  out xMemory: IMemory; hServer: TWinStaHandle = SERVER_CURRENT): TNtxStatus;
var
  Buffer: Pointer;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'WinStationQueryInformationW';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TWinStationInfoClass);

  BufferSize := 72;
  repeat
    Buffer := AllocMem(BufferSize);

    // This call does not return the required buffer size, we need to guess it
    Result.Win32Result := WinStationQueryInformationW(hServer, SessionId,
      InfoClass, Buffer, BufferSize, Required);

    Required := BufferSize + (BufferSize shr 2) + 64;

    if not Result.IsSuccess then
    begin
      FreeMem(Buffer);
      Buffer := nil;
    end;

  until not NtxExpandBuffer(Result, BufferSize, Required);

  if Result.IsSuccess then
    xMemory := TAutoMemory.Capture(Buffer, BufferSize);
end;

function WsxQueryName(SessionId: Cardinal; hServer: TWinStaHandle): String;
var
  Info: TWinStationInformation;
begin
  Result := IntToStr(SessionId);

  if WsxWinStation.Query(SessionId, WinStationInformation, Info,
    hServer).IsSuccess then
  begin
    if Info.WinStationName <> '' then
      Result := Result + ': ' + String(Info.WinStationName);

    Result := Result + ' (' + Info.FullUserName + ')';
  end;
end;

function WsxQueryToken(out hxToken: IHandle; SessionId: Cardinal; hServer:
  TWinStaHandle): TNtxStatus;
var
  UserToken: TWinStationUserToken;
begin
  FillChar(UserToken, SizeOf(UserToken), 0);

  // TODO: fall back to WTS Api to workaround a bug with Sandboxie where this
  // call inserts a handle to SbieSvc.exe's handle table and not into ours

  Result := WsxWinStation.Query(SessionId, WinStationUserToken, UserToken,
    hServer);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(UserToken.UserToken);
end;

function WsxSendMessage(SessionId: Cardinal; Title, MessageStr: String;
  Style: Cardinal; Timeout: Cardinal; WaitForResponse: Boolean;
  pResponse: PCardinal; ServerHandle: TWinStaHandle): TNtxStatus;
var
  Response: Cardinal;
begin
  Result.Location := 'WinStationSendMessageW';
  Result.Win32Result := WinStationSendMessageW(ServerHandle, SessionId,
    PWideChar(Title), Length(Title) * SizeOf(WideChar),
    PWideChar(MessageStr), Length(MessageStr) * SizeOf(WideChar),
    Style, Timeout, Response, WaitForResponse);

  if Result.IsSuccess and Assigned(pResponse) then
    pResponse^ := Response;
end;

function WsxConnect(SessionId: Cardinal; TargetSessionId: Cardinal;
  Password: PWideChar; Wait: Boolean; hServer: TWinStaHandle): TNtxStatus;
begin
  // It fails with null pointer
  if not Assigned(Password) then
    Password := '';

  Result.Location := 'WinStationConnectW';
  Result.Win32Result := WinStationConnectW(hServer, SessionId, TargetSessionId,
    Password, Wait);
end;

function WsxDisconnect(SessionId: Cardinal; Wait: Boolean; hServer:
  TWinStaHandle): TNtxStatus;
begin
  Result.Location := 'WinStationDisconnect';
  Result.Win32Result := WinStationDisconnect(hServer, SessionId, Wait);
end;

function WsxRemoteControl(TargetSessionId: Cardinal; HotKeyVk: Byte;
  HotkeyModifiers: Word; hServer: TWinStaHandle; TargetServer: String):
  TNtxStatus;
var
  pTargetServer: PWideChar;
begin
  if TargetServer = '' then
    pTargetServer := nil
  else
    pTargetServer := PWideChar(TargetServer);

  Result.Location := 'WinStationShadow';
  Result.Win32Result := WinStationShadow(hServer, pTargetServer,
    TargetSessionId, HotKeyVk, HotkeyModifiers);
end;

function WsxRemoteControlStop(hServer: TWinStaHandle; SessionId: Cardinal;
  Wait: Boolean): TNtxStatus;
begin
  Result.Location := 'WinStationShadowStop';
  Result.Win32Result := WinStationShadowStop(hServer, SessionId, Wait);
end;

end.
