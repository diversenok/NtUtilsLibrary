unit NtUtils.WinStation;

{
  The module provides access to the Window Station (aka Terminal Server) API.
}

interface

uses
  Ntapi.WinNt, Ntapi.winsta, Ntapi.WinUser, NtUtils, NtUtils.Objects;

type
  TSessionIdW = Ntapi.winsta.TSessionIdW;
  TWinStationInformation = Ntapi.winsta.TWinStationInformation;
  TWinStaHandle = Ntapi.winsta.TWinStaHandle;
  IWinStaHandle = NtUtils.IHandle;

// Connect to a remote computer
function WsxOpenServer(
  out hxServer: IWinStaHandle;
  const Name: String
): TNtxStatus;

// Enumerate all session on the server for which we have Query access
function WsxEnumerateSessions(
  out Sessions: TArray<TSessionIdW>;
  [opt] hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Find the ID of the active session
function WsxFindActiveSessionId(
  out SessionId: TSessionId;
  [opt] hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

type
  WsxWinStation = class abstract
    // Query fixed-size information
    class function Query<T>(
      SessionId: TSessionId;
      InfoClass: TWinStationInfoClass;
      out Buffer: T;
      [opt] hServer: TWinStaHandle = SERVER_CURRENT
    ): TNtxStatus; static;
  end;

// Query variable-size information
function WsxQuery(
  SessionId: TSessionId;
  InfoClass: TWinStationInfoClass;
  out xMemory: IMemory;
  hServer: TWinStaHandle = SERVER_CURRENT;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Open session token
function WsxQueryToken(
  out hxToken: IHandle;
  SessionId: TSessionId;
  [opt] hServer: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Send a message to a session
function WsxSendMessage(
  SessionId: TSessionId;
  const Title: String;
  const MessageStr: String;
  Style: TMessageStyle;
  TimeoutSeconds: Cardinal = 0;
  WaitForResponse: Boolean = False;
  [out, opt] pResponse: PMessageResponse = nil;
  [opt] ServerHandle: TWinStaHandle = SERVER_CURRENT
): TNtxStatus;

// Connect one session to another
function WsxConnect(
  SessionId: TSessionId;
  TargetSessionId: TSessionId = LOGONID_CURRENT;
  [in, opt] Password: PWideChar = nil;
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
  [opt] const TargetServer: String = ''
): TNtxStatus;

// Stop controlling (shadowing) a session
function WsxRemoteControlStop(
  hServer: TWinStaHandle;
  SessionId: TSessionId;
  Wait: Boolean
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.SysUtils, DelphiUtils.AutoObjects, NtUtils.Ldr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TWinStaAutoHandle = class(TCustomAutoHandle, IWinStaHandle, IAutoReleasable)
    procedure Release; override;
  end;

procedure TWinStaAutoHandle.Release;
begin
  if (FHandle <> 0) and LdrxCheckDelayedImport(
    delayed_WinStationCloseServer).IsSuccess then
    WinStationCloseServer(FHandle);

  FHandle := 0;
  inherited;
end;

function WsxDelayFreeMemory(
  [in] Buffer: Pointer
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      if LdrxCheckDelayedImport(delayed_WinStationFreeMemory).IsSuccess then
        WinStationFreeMemory(Buffer);
    end
  );
end;

function WsxOpenServer;
var
  hServer: TWinStaHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationOpenServerW);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WinStationOpenServerW';
  hServer := WinStationOpenServerW(PWideChar(Name));
  Result.Win32Result := hServer <> 0;

  if Result.IsSuccess then
    hxServer := Auto.CaptureHandle(hServer);
end;

function WsxEnumerateSessions;
var
  Buffer: PSessionIdArrayW;
  BufferDeallocator: IAutoReleasable;
  Count, i: Integer;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationEnumerateW);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WinStationEnumerateW';
  Result.Win32Result := WinStationEnumerateW(hServer, Buffer, Count);

  if not Result.IsSuccess then
    Exit;

  BufferDeallocator := WsxDelayFreeMemory(Buffer);
  SetLength(Sessions, Count);

  for i := 0 to High(Sessions) do
    Sessions[i] := Buffer{$R-}[i]{$IFDEF R+}{$IFDEF R+}{$R+}{$ENDIF}{$ENDIF};
 end;

function WsxFindActiveSessionId;
var
  Sessions: TArray<TSessionIdW>;
  i: Integer;
begin
  Result := WsxEnumerateSessions(Sessions);

  if not Result.IsSuccess then
    Exit;

  for i := 0 to High(Sessions) do
    if Sessions[i].State = State_Active then
    begin
      SessionId := Sessions[i].SessionID;
      Exit;
    end;

  Result.Location := 'WsxFindActiveSessionId';
  Result.Status := STATUS_NOT_FOUND;
end;

class function WsxWinStation.Query<T>;
var
  Returned: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationQueryInformationW);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WinStationQueryInformationW';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  Result.Win32Result := WinStationQueryInformationW(hServer, SessionId,
    InfoClass, @Buffer, SizeOf(Buffer), Returned);
end;

function GrowWxsDefault(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := Memory.Size + (Memory.Size shr 2) + 64; // + 25% + 64 B
end;

function WsxQuery;
var
  Required: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationQueryInformationW);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WinStationQueryInformationW';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  // WinStationQueryInformationW might not return the required buffer size,
  // we need to guess it
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowWxsDefault;

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := WinStationQueryInformationW(hServer, SessionId,
      InfoClass, xMemory.Data, xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

function WsxQueryToken;
var
  UserToken: TWinStationUserToken;
begin
  UserToken := Default(TWinStationUserToken);

  Result := WsxWinStation.Query(SessionId, WinStationUserToken, UserToken,
    hServer);

  if Result.IsSuccess then
    hxToken := Auto.CaptureHandle(UserToken.UserToken);
end;

function WsxSendMessage;
var
  Response: TMessageResponse;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationSendMessageW);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WinStationSendMessageW';
  Result.Win32Result := WinStationSendMessageW(ServerHandle, SessionId,
    PWideChar(Title), StringSizeNoZero(Title), PWideChar(MessageStr),
    StringSizeNoZero(MessageStr), Style, TimeoutSeconds, Response,
    not WaitForResponse);

  if Result.IsSuccess and Assigned(pResponse) then
    pResponse^ := Response;
end;

function WsxConnect;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationConnectW);

  if not Result.IsSuccess then
    Exit;

  // It fails with null pointer
  if not Assigned(Password) then
    Password := '';

  Result.Location := 'WinStationConnectW';
  Result.Win32Result := WinStationConnectW(hServer, SessionId, TargetSessionId,
    Password, Wait);
end;

function WsxDisconnect;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationDisconnect);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WinStationDisconnect';
  Result.Win32Result := WinStationDisconnect(hServer, SessionId, Wait);
end;

function WsxRemoteControl;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationShadow);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WinStationShadow';
  Result.Win32Result := WinStationShadow(hServer, RefStrOrNil(TargetServer),
    TargetSessionId, HotKeyVk, HotkeyModifiers);
end;

function WsxRemoteControlStop;
begin
  Result := LdrxCheckDelayedImport(delayed_WinStationShadowStop);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WinStationShadowStop';
  Result.Win32Result := WinStationShadowStop(hServer, SessionId, Wait);
end;

end.
