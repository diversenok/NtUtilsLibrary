unit NtUtils.Svc;

interface

uses
  Winapi.WinNt, NtUtils.Exceptions, NtUtils.Objects, Winapi.Svc,
  NtUtils.AutoHandle;

type
  TScmHandle = Winapi.Svc.TScmHandle;
  IScmHandle = IHandle;

  TScmAutoHandle = class(TCustomAutoHandle, IScmHandle)
    destructor Destroy; override;
  end;

  TServiceConfig = record
    ServiceType: Cardinal;
    StartType: TServiceStartType;
    ErrorControl: TServiceErrorControl;
    TagId: Cardinal;
    BinaryPathName: String;
    LoadOrderGroup: String;
    ServiceStartName: String;
    DisplayName: String;
  end;

// Open a handle to SCM
function ScmxConnect(out hxScm: IScmHandle; DesiredAccess: TAccessMask;
  ServerName: String = ''): TNtxStatus;

// Open a service
function ScmxOpenService(out hxSvc: IScmHandle; ServiceName: String;
  DesiredAccess: TAccessMask; hxScm: IScmHandle = nil): TNtxStatus;

// Create a service
function ScmxCreateService(out hxSvc: IScmHandle; CommandLine, ServiceName,
  DisplayName: String; StartType: TServiceStartType = ServiceDemandStart;
  hxScm: IScmHandle = nil): TNtxStatus;

// Start a service
function ScmxStartService(hSvc: TScmHandle): TNtxStatus;
function ScmxStartServiceEx(hSvc: TScmHandle; Parameters: TArray<String>):
  TNtxStatus;

// Send a control to a service
function ScmxControlService(hSvc: TScmHandle; Control: TServiceControl;
  out ServiceStatus: TServiceStatus): TNtxStatus;

// Delete a service
function ScmxDeleteService(hSvc: TScmHandle): TNtxStatus;

// Query service config
function ScmxQueryConfigService(hSvc: TScmHandle; out Config: TServiceConfig)
  : TNtxStatus;

// Query service status and process information
function ScmxQueryProcessStatusService(hSvc: TScmHandle;
  out Info: TServiceStatusProcess): TNtxStatus;

implementation

uses
  NtUtils.Access.Expected, Ntapi.ntstatus;

destructor TScmAutoHandle.Destroy;
begin
  if FAutoClose then
  begin
    CloseServiceHandle(Handle);
    Handle := 0;
  end;
  inherited;
end;

function ScmxConnect(out hxScm: IScmHandle; DesiredAccess: TAccessMask;
  ServerName: String): TNtxStatus;
var
  hScm: TScmHandle;
  pServerName: PWideChar;
begin
  if ServerName <> '' then
    pServerName := PWideChar(ServerName)
  else
    pServerName := nil;

  Result.Location := 'OpenSCManagerW';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @ScmAccessType;

  hScm := OpenSCManagerW(pServerName, nil, DesiredAccess);
  Result.Win32Result := (hScm <> 0);

  if Result.IsSuccess then
    hxScm := TScmAutoHandle.Capture(hScm);
end;

function ScmxpEnsureConnected(var hxScm: IScmHandle; DesiredAccess: TAccessMask)
  : TNtxStatus;
begin
  if not Assigned(hxScm) then
    Result := ScmxConnect(hxScm, DesiredAccess)
  else
    Result.Status := STATUS_SUCCESS
end;

function ScmxOpenService(out hxSvc: IScmHandle; ServiceName: String;
  DesiredAccess: TAccessMask; hxScm: IScmHandle): TNtxStatus;
var
  hSvc: TScmHandle;
begin
  Result := ScmxpEnsureConnected(hxScm, SC_MANAGER_CONNECT);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OpenServiceW';
  Result.LastCall.CallType := lcOpenCall;
  Result.LastCall.AccessMask := DesiredAccess;
  Result.LastCall.AccessMaskType := @ServiceAccessType;
  Result.LastCall.Expects(SC_MANAGER_CONNECT, @ScmAccessType);

  hSvc := OpenServiceW(hxScm.Value, PWideChar(ServiceName), DesiredAccess);
  Result.Win32Result := (hSvc <> 0);

  if Result.IsSuccess then
    hxSvc := TScmAutoHandle.Capture(hSvc);
end;

function ScmxCreateService(out hxSvc: IScmHandle; CommandLine, ServiceName,
  DisplayName: String; StartType: TServiceStartType; hxScm: IScmHandle)
  : TNtxStatus;
var
  hSvc: TScmHandle;
begin
  Result := ScmxpEnsureConnected(hxScm, SC_MANAGER_CREATE_SERVICE);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'CreateServiceW';
  Result.LastCall.Expects(SC_MANAGER_CREATE_SERVICE, @ScmAccessType);

  hSvc := CreateServiceW(hxScm.Value, PWideChar(ServiceName),
    PWideChar(DisplayName), SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS,
    StartType, ServiceErrorNormal, PWideChar(CommandLine), nil, nil, nil, nil,
    nil);
  Result.Win32Result := (hSvc <> 0);

  if Result.IsSuccess then
    hxSvc := TScmAutoHandle.Capture(hSvc);
end;

function ScmxStartService(hSvc: TScmHandle): TNtxStatus;
var
  Parameters: TArray<String>;
begin
  SetLength(Parameters, 0);
  Result := ScmxStartServiceEx(hSvc, Parameters);
end;

function ScmxStartServiceEx(hSvc: TScmHandle; Parameters: TArray<String>):
  TNtxStatus;
var
  i: Integer;
  Params: TArray<PWideChar>;
begin
  SetLength(Params, Length(Parameters));

  for i := 0 to High(Params) do
    Params[i] := PWideChar(Parameters[i]);

  Result.Location := 'StartServiceW';
  Result.LastCall.Expects(SERVICE_START, @ServiceAccessType);

  Result.Win32Result := StartServiceW(hSvc, Length(Params), Params);
end;

function ScmxControlService(hSvc: TScmHandle; Control: TServiceControl;
  out ServiceStatus: TServiceStatus): TNtxStatus;
begin
  Result.Location := 'ControlService';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(Control);
  Result.LastCall.InfoClassType := TypeInfo(TServiceControl);
  RtlxComputeServiceControlAccess(Result.LastCall, Control);

  Result.Win32Result := ControlService(hSvc, Control, ServiceStatus);
end;

function ScmxDeleteService(hSvc: TScmHandle): TNtxStatus;
begin
  Result.Location := 'DeleteService';
  Result.LastCall.Expects(_DELETE, @ServiceAccessType);
  Result.Win32Result := DeleteService(hSvc);
end;

function ScmxQueryConfigService(hSvc: TScmHandle; out Config: TServiceConfig)
  : TNtxStatus;
var
  Buffer: PQueryServiceConfigW;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfigW';
  Result.LastCall.Expects(SERVICE_QUERY_CONFIG, @ServiceAccessType);

  BufferSize := 0;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Win32Result := QueryServiceConfigW(hSvc, Buffer, BufferSize,
      Required);

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, Required);

  if not Result.IsSuccess then
    Exit;

  Config.ServiceType := Buffer.ServiceType;
  Config.StartType := Buffer.StartType;
  Config.ErrorControl := Buffer.ErrorControl;
  Config.TagId := Buffer.TagId;
  Config.BinaryPathName := String(Buffer.BinaryPathName);
  Config.LoadOrderGroup := String(Buffer.LoadOrderGroup);
  Config.ServiceStartName := String(Buffer.ServiceStartName);
  Config.DisplayName := String(Buffer.DisplayName);

  FreeMem(Buffer);
end;

function ScmxQueryProcessStatusService(hSvc: TScmHandle;
  out Info: TServiceStatusProcess): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceStatusEx';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(ScStatusProcessInfo);
  Result.LastCall.InfoClassType := TypeInfo(TScStatusType);
  Result.LastCall.Expects(SERVICE_QUERY_STATUS, @ServiceAccessType);

  Result.Win32Result := QueryServiceStatusEx(hSvc, ScStatusProcessInfo,
    @Info, SizeOf(Info), Required);
end;

end.
