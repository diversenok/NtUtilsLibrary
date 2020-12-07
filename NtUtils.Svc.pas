unit NtUtils.Svc;

interface

uses
  Winapi.WinNt, NtUtils, NtUtils.Objects, Winapi.Svc,
  DelphiUtils.AutoObject;

type
  TScmHandle = Winapi.Svc.TScmHandle;
  IScmHandle = DelphiUtils.AutoObject.IHandle;

  TServiceConfig = record
    ServiceType: Cardinal;
    StartType: TServiceStartType;
    ErrorControl: TServiceErrorControl;
    TagID: Cardinal;
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
  DisplayName: String; StartType: TServiceStartType = SERVICE_DEMAND_START;
  hxScm: IScmHandle = nil): TNtxStatus;

// Start a service
function ScmxStartService(hSvc: TScmHandle; Parameters: TArray<String> = nil):
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

type
  NtxService = class
    // Query fixed-size information
    class function Query<T>(hSvc: TScmHandle;
      InfoClass: TServiceConfigLevel; out Buffer: T): TNtxStatus; static;
  end;

// Query variable-size service information
function ScmxQueryService(hSvc: TScmHandle; InfoClass: TServiceConfigLevel;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil): TNtxStatus;

// Set service information
function ScmxSetService(hSvc: TScmHandle; InfoClass: TServiceConfigLevel;
  Buffer: Pointer): TNtxStatus;

// Query service description
function ScmxQueryDescriptionService(hSvc: TScmHandle; out Description: String):
  TNtxStatus;

// Query list of requires privileges for a service
function ScmxQueryRequiredPrivilegesService(hSvc: TScmHandle; out Privileges:
  TArray<String>): TNtxStatus;

// Query security descriptor of a SCM object
function ScmxQuerySecurityObject(ScmHandle: TScmHandle; Info:
  TSecurityInformation; out SD: ISecDesc): TNtxStatus;

// Set security descriptor on a SCM object
function ScmxSetSecurityObject(ScmHandle: TScmHandle; Info:
  TSecurityInformation; SD: PSecurityDescriptor): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, DelphiUtils.Arrays;

type
  TScmAutoHandle = class(TCustomAutoHandle, IScmHandle)
    destructor Destroy; override;
  end;

destructor TScmAutoHandle.Destroy;
begin
  if FAutoRelease then
    CloseServiceHandle(FHandle);
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
  Result.LastCall.AttachAccess<TScmAccessMask>(DesiredAccess);

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
  Result.LastCall.AttachAccess<TServiceAccessMask>(DesiredAccess);
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_CONNECT);

  hSvc := OpenServiceW(hxScm.Handle, PWideChar(ServiceName), DesiredAccess);
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
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_CREATE_SERVICE);

  hSvc := CreateServiceW(hxScm.Handle, PWideChar(ServiceName),
    PWideChar(DisplayName), SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS,
    StartType, SERVICE_ERROR_NORMAL, PWideChar(CommandLine), nil, nil, nil, nil,
    nil);
  Result.Win32Result := (hSvc <> 0);

  if Result.IsSuccess then
    hxSvc := TScmAutoHandle.Capture(hSvc);
end;

function ScmxStartService(hSvc: TScmHandle; Parameters: TArray<String>):
  TNtxStatus;
var
  i: Integer;
  Params: TArray<PWideChar>;
begin
  SetLength(Params, Length(Parameters));

  for i := 0 to High(Params) do
    Params[i] := PWideChar(Parameters[i]);

  Result.Location := 'StartServiceW';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_START);

  Result.Win32Result := StartServiceW(hSvc, Length(Params), Params);
end;

function ScmxControlService(hSvc: TScmHandle; Control: TServiceControl;
  out ServiceStatus: TServiceStatus): TNtxStatus;
begin
  Result.Location := 'ControlService';
  Result.LastCall.AttachInfoClass(Control);
  Result.LastCall.Expects(ExpectedSvcControlAccess(Control));
  Result.Win32Result := ControlService(hSvc, Control, ServiceStatus);
end;

function ScmxDeleteService(hSvc: TScmHandle): TNtxStatus;
begin
  Result.Location := 'DeleteService';
  Result.LastCall.Expects<TServiceAccessMask>(_DELETE);
  Result.Win32Result := DeleteService(hSvc);
end;

function ScmxQueryConfigService(hSvc: TScmHandle; out Config: TServiceConfig)
  : TNtxStatus;
var
  xMemory: IMemory<PQueryServiceConfigW>;
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfigW';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);

  IMemory(xMemory) := TAutoMemory.Allocate(0);
  repeat
    Required := 0;
    Result.Win32Result := QueryServiceConfigW(hSvc, xMemory.Data, xMemory.Size,
      Required);
  until not NtxExpandBufferEx(Result, IMemory(xMemory), Required, nil);

  if not Result.IsSuccess then
    Exit;

  Config.ServiceType := xMemory.Data.ServiceType;
  Config.StartType := xMemory.Data.StartType;
  Config.ErrorControl := xMemory.Data.ErrorControl;
  Config.TagId := xMemory.Data.TagId;
  Config.BinaryPathName := String(xMemory.Data.BinaryPathName);
  Config.LoadOrderGroup := String(xMemory.Data.LoadOrderGroup);
  Config.ServiceStartName := String(xMemory.Data.ServiceStartName);
  Config.DisplayName := String(xMemory.Data.DisplayName);
end;

function ScmxQueryProcessStatusService(hSvc: TScmHandle;
  out Info: TServiceStatusProcess): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceStatusEx';
  Result.LastCall.AttachInfoClass(SC_STATUS_PROCESS_INFO);
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_STATUS);

  Result.Win32Result := QueryServiceStatusEx(hSvc, SC_STATUS_PROCESS_INFO,
    @Info, SizeOf(Info), Required);
end;

class function NtxService.Query<T>(hSvc: TScmHandle;
  InfoClass: TServiceConfigLevel; out Buffer: T): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfig2W';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := QueryServiceConfig2W(hSvc, InfoClass, @Buffer,
    SizeOf(Buffer), Required);
end;

function ScmxQueryService(hSvc: TScmHandle; InfoClass: TServiceConfigLevel;
  out xMemory: IMemory; InitialBuffer: Cardinal; GrowthMethod:
  TBufferGrowthMethod): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfig2W';
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := QueryServiceConfig2W(hSvc, InfoClass, xMemory.Data,
      xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, nil);
end;

function ScmxSetService(hSvc: TScmHandle; InfoClass: TServiceConfigLevel;
  Buffer: Pointer): TNtxStatus;
begin
  Result.Location := 'ChangeServiceConfig2W';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_CHANGE_CONFIG);
  Result.LastCall.AttachInfoClass(InfoClass);
  Result.Win32Result := ChangeServiceConfig2W(hSvc, InfoClass, Buffer);
end;

function ScmxQueryDescriptionService(hSvc: TScmHandle; out Description: String):
  TNtxStatus;
var
  xMemory: IMemory<PServiceDescription>;
begin
  Result := ScmxQueryService(hSvc, SERVICE_CONFIG_DESCRIPTION,
    IMemory(xMemory));

  if Result.IsSuccess then
    Description := String(xMemory.Data.Description);
end;

function ScmxQueryRequiredPrivilegesService(hSvc: TScmHandle; out Privileges:
  TArray<String>): TNtxStatus;
var
  xMemory: IMemory<PServiceRequiredPrivilegesInfo>;
begin
  Result := ScmxQueryService(hSvc, SERVICE_CONFIG_REQUIRED_PRIVILEGES_INFO,
    IMemory(xMemory), SizeOf(TServiceRequiredPrivilegesInfo));

  if Result.IsSuccess and Assigned(xMemory.Data.RequiredPrivileges) then
    Privileges := ParseMultiSz(xMemory.Data.RequiredPrivileges, (xMemory.Size -
      SizeOf(TServiceRequiredPrivilegesInfo)) div SizeOf(WideChar))
  else
    SetLength(Privileges, 0);
end;

function ScmxQuerySecurityObject(ScmHandle: TScmHandle; Info:
  TSecurityInformation; out SD: ISecDesc): TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceObjectSecurity';
  Result.LastCall.AttachAccess<TAccessMask>(SecurityReadAccess(Info));

  IMemory(SD) := TAutoMemory.Allocate(0);
  repeat
    Required := 0;
    Result.Win32Result := QueryServiceObjectSecurity(ScmHandle, Info, SD.Data,
      SD.Size, Required);
  until not NtxExpandBufferEx(Result, IMemory(SD), Required, nil);
end;

function ScmxSetSecurityObject(ScmHandle: TScmHandle; Info:
  TSecurityInformation; SD: PSecurityDescriptor): TNtxStatus;
begin
  Result.Location := 'SetServiceObjectSecurity';
  Result.LastCall.AttachAccess<TAccessMask>(SecurityWriteAccess(Info));
  Result.Win32Result := SetServiceObjectSecurity(ScmHandle, Info, SD);
end;

end.
