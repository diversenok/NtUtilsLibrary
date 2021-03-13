unit NtUtils.WinStation;

{
  The module provides access to the Window Station (aka Terminal Server) API.
}

interface

uses
  Winapi.WinNt, Winapi.winsta, Winapi.WinUser, NtUtils, NtUtils.Objects,
  DelphiUtils.AutoObject;

type
  TSessionIdW = Winapi.winsta.TSessionIdW;

  TWinStaHandle = Winapi.winsta.TWinStaHandle;
  IWinStaHandle = DelphiUtils.AutoObject.IHandle;

// Connect to a remote computer
function WsxOpenServer(
  out hxServer: IWinStaHandle;
  Name: String
): TNtxStatus;

// Enumerate all session on the server for which we have Query access
function WsxEnumerateSessions(
  out Sessions: TArray<TSessionIdW>;
  hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

type
  WsxWinStation = class abstract
    // Query fixed-size information
    class function Query<T>(
      SessionId: TSessionId;
      InfoClass: TWinStationInfoClass;
      out Buffer: T;
      hServer: TWinStaHandle = SERVER_CURRENT
    ): TNtxStatus; static;
  end;

// Query variable-size information
function WsxQuery(
  SessionId: TSessionId;
  InfoClass: TWinStationInfoClass;
  out xMemory: IMemory;
  hServer: TWinStaHandle = SERVER_CURRENT;
  InitialBuffer: Cardinal = 0;
  GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Format a name of a session, always succeeds with at least an ID
function WsxQueryName(
  SessionId: TSessionId;
  hServer: TWinStaHandle = SERVER_CURRENT
): String;

// Open session token
function WsxQueryToken(
  out hxToken: IHandle;
  SessionId: TSessionId;
  hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Send a message to a session
function WsxSendMessage(
  SessionId: TSessionId;
  Title: String;
  MessageStr: String;
  Style: TMessageStyle;
  Timeout: Cardinal;
  WaitForResponse: Boolean = False;
  pResponse: PMessageResponse = nil;
  ServerHandle: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Connect one session to another
function WsxConnect(
  SessionId: TSessionId;
  TargetSessionId: TSessionId = LOGONID_CURRENT;
  Password: PWideChar = nil;
  Wait: Boolean = True;
  hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Disconnect a session
function WsxDisconnect(
  SessionId: TSessionId;
  Wait: Boolean;
  hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Remote control (shadow) an active remote session
function WsxRemoteControl(
  TargetSessionId: TSessionId;
  HotKeyVk: Byte;
  HotkeyModifiers: Word;
  hServer: TWinStaHandle = SERVER_CURRENT;
  TargetServer: String = ''
): TNtxStatus;

// Stop controlling (shadowing) a session
function WsxRemoteControlStop(
  hServer: TWinStaHandle;
  SessionId: TSessionId;
  Wait: Boolean
): TNtxStatus;

implementation

uses
  NtUtils.SysUtils;

type
  TWinStaAutoHandle = class(TCustomAutoHandle, IWinStaHandle)
    procedure Release; override;
  end;

procedure TWinStaAutoHandle.Release;
begin
  WinStationCloseServer(FHandle);
  inherited;
end;

function WsxOpenServer;
var
  hServer: TWinStaHandle;
begin
  Result.Location := 'WinStationOpenServerW';
  hServer := WinStationOpenServerW(PWideChar(Name));
  Result.Win32Result := hServer <> 0;

  if Result.IsSuccess then
    hxServer := TAutoHandle.Capture(hServer);
end;

function WsxEnumerateSessions;
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

class function WsxWinStation.Query<T>;
var
  Returned: Cardinal;
begin
  Result.Location := 'WinStationQueryInformationW';
  Result.LastCall.AttachInfoClass(InfoClass);

  Result.Win32Result := WinStationQueryInformationW(hServer, SessionId,
    InfoClass, @Buffer, SizeOf(Buffer), Returned);
end;

function GrowWxsDefault(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  Result := Memory.Size + (Memory.Size shr 2) + 64; // + 25% + 64 B
end;

function WsxQuery;
var
  Required: Cardinal;
begin
  Result.Location := 'WinStationQueryInformationW';
  Result.LastCall.AttachInfoClass(InfoClass);

  // WinStationQueryInformationW might not return the required buffer size,
  // we need to guess it
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowWxsDefault;

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := WinStationQueryInformationW(hServer, SessionId,
      InfoClass, xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function WsxQueryName;
var
  Info: TWinStationInformation;
begin
  Result := RtlxIntToStr(SessionId);

  if WsxWinStation.Query(SessionId, WinStationInformation, Info,
    hServer).IsSuccess then
  begin
    if Info.WinStationName <> '' then
      Result := Result + ': ' + String(Info.WinStationName);

    Result := Result + ' (' + Info.FullUserName + ')';
  end;
end;

function WsxQueryToken;
var
  UserToken: TWinStationUserToken;
begin
  FillChar(UserToken, SizeOf(UserToken), 0);

  Result := WsxWinStation.Query(SessionId, WinStationUserToken, UserToken,
    hServer);

  if Result.IsSuccess then
    hxToken := TAutoHandle.Capture(UserToken.UserToken);
end;

function WsxSendMessage;
var
  Response: TMessageResponse;
begin
  Result.Location := 'WinStationSendMessageW';
  Result.Win32Result := WinStationSendMessageW(ServerHandle, SessionId,
    PWideChar(Title), Length(Title) * SizeOf(WideChar),
    PWideChar(MessageStr), Length(MessageStr) * SizeOf(WideChar),
    Style, Timeout, Response, WaitForResponse);

  if Result.IsSuccess and Assigned(pResponse) then
    pResponse^ := Response;
end;

function WsxConnect;
begin
  // It fails with null pointer
  if not Assigned(Password) then
    Password := '';

  Result.Location := 'WinStationConnectW';
  Result.Win32Result := WinStationConnectW(hServer, SessionId, TargetSessionId,
    Password, Wait);
end;

function WsxDisconnect;
begin
  Result.Location := 'WinStationDisconnect';
  Result.Win32Result := WinStationDisconnect(hServer, SessionId, Wait);
end;

function WsxRemoteControl;
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

function WsxRemoteControlStop;
begin
  Result.Location := 'WinStationShadowStop';
  Result.Win32Result := WinStationShadowStop(hServer, SessionId, Wait);
end;

end.
