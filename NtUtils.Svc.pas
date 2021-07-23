unit NtUtils.Svc;

{
  This module includes functions for interacting with Service Control Manager.
}

interface

uses
  Winapi.WinNt, NtUtils, NtUtils.Objects, Winapi.Svc;

type
  TScmHandle = Winapi.Svc.TScmHandle;
  IScmHandle = NtUtils.IHandle;

  TServiceConfig = record
    ServiceType: TServiceType;
    StartType: TServiceStartType;
    ErrorControl: TServiceErrorControl;
    TagID: Cardinal;
    BinaryPathName: String;
    LoadOrderGroup: String;
    ServiceStartName: String;
    DisplayName: String;
  end;

// Open a handle to SCM
function ScmxConnect(
  out hxScm: IScmHandle;
  DesiredAccess: TScmAccessMask;
  [opt] const ServerName: String = ''
): TNtxStatus;

// Open a service
function ScmxOpenService(
  out hxSvc: IScmHandle;
  const ServiceName: String;
  DesiredAccess: TServiceAccessMask;
  [opt, Access(SC_MANAGER_CONNECT)] hxScm: IScmHandle = nil
): TNtxStatus;

// Create a service
function ScmxCreateService(
  out hxSvc: IScmHandle;
  const CommandLine: String;
  const ServiceName: String;
  [opt] const DisplayName: String;
  StartType: TServiceStartType = SERVICE_DEMAND_START;
  [opt, Access(SC_MANAGER_CREATE_SERVICE)] hxScm: IScmHandle = nil
): TNtxStatus;

// Start a service
function ScmxStartService(
  [Access(SERVICE_START)] hSvc: TScmHandle;
  [opt] const Parameters: TArray<String> = nil
): TNtxStatus;

// Send a control to a service
function ScmxControlService(
  [Access(SERVICE_CONTROL_ANY)] hSvc: TScmHandle;
  Control: TServiceControl;
  out ServiceStatus: TServiceStatus
): TNtxStatus;

// Delete a service
function ScmxDeleteService(
  [Access(_DELETE)] hSvc: TScmHandle
): TNtxStatus;

// Query service config
function ScmxQueryConfigService(
  [Access(SERVICE_QUERY_CONFIG)] hSvc: TScmHandle;
  out Config: TServiceConfig
): TNtxStatus;

// Query service status and process information
function ScmxQueryProcessStatusService(
  [Access(SERVICE_QUERY_STATUS)] hSvc: TScmHandle;
  out Info: TServiceStatusProcess
): TNtxStatus;

type
  NtxService = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(SERVICE_QUERY_CONFIG)] hSvc: TScmHandle;
      InfoClass: TServiceConfigLevel;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Query variable-size service information
function ScmxQueryService(
  [Access(SERVICE_QUERY_CONFIG)] hSvc: TScmHandle;
  InfoClass: TServiceConfigLevel;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

// Set service information
function ScmxSetService(
  [Access(SERVICE_CHANGE_CONFIG)] hSvc: TScmHandle;
  InfoClass: TServiceConfigLevel;
  [in] Buffer: Pointer
): TNtxStatus;

// Query service description
function ScmxQueryDescriptionService(
  [Access(SERVICE_QUERY_CONFIG)] hSvc: TScmHandle;
  out Description: String
): TNtxStatus;

// Query list of requires privileges for a service
function ScmxQueryRequiredPrivilegesService(
  [Access(SERVICE_QUERY_CONFIG)] hSvc: TScmHandle;
  out Privileges: TArray<String>
): TNtxStatus;

// Query security descriptor of a SCM object
function ScmxQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] ScmHandle: TScmHandle;
  Info: TSecurityInformation;
  out SD: ISecDesc
): TNtxStatus;

// Set security descriptor on a SCM object
function ScmxSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] ScmHandle: TScmHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, DelphiUtils.Arrays, DelphiUtils.AutoObjects;

type
  TScmAutoHandle = class(TCustomAutoHandle, IScmHandle)
    procedure Release; override;
  end;

procedure TScmAutoHandle.Release;
begin
  CloseServiceHandle(FHandle);
  inherited;
end;

function ScmxConnect;
var
  hScm: TScmHandle;
  pServerName: PWideChar;
begin
  if ServerName <> '' then
    pServerName := PWideChar(ServerName)
  else
    pServerName := nil;

  Result.Location := 'OpenSCManagerW';
  Result.LastCall.OpensForAccess(DesiredAccess);

  hScm := OpenSCManagerW(pServerName, nil, DesiredAccess);
  Result.Win32Result := (hScm <> 0);

  if Result.IsSuccess then
    hxScm := TScmAutoHandle.Capture(hScm);
end;

function ScmxpEnsureConnected(
  var hxScm: IScmHandle;
  DesiredAccess: TScmAccessMask
): TNtxStatus;
begin
  if not Assigned(hxScm) then
    Result := ScmxConnect(hxScm, DesiredAccess)
  else
    Result.Status := STATUS_SUCCESS
end;

function ScmxOpenService;
var
  hSvc: TScmHandle;
begin
  Result := ScmxpEnsureConnected(hxScm, SC_MANAGER_CONNECT);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OpenServiceW';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_CONNECT);

  hSvc := OpenServiceW(hxScm.Handle, PWideChar(ServiceName), DesiredAccess);
  Result.Win32Result := (hSvc <> 0);

  if Result.IsSuccess then
    hxSvc := TScmAutoHandle.Capture(hSvc);
end;

function ScmxCreateService;
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

function ScmxStartService;
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

function ScmxControlService;
begin
  Result.Location := 'ControlService';
  Result.LastCall.UsesInfoClass(Control, icControl);
  Result.LastCall.Expects(ExpectedSvcControlAccess(Control));
  Result.Win32Result := ControlService(hSvc, Control, ServiceStatus);
end;

function ScmxDeleteService;
begin
  Result.Location := 'DeleteService';
  Result.LastCall.Expects<TServiceAccessMask>(_DELETE);
  Result.Win32Result := DeleteService(hSvc);
end;

function ScmxQueryConfigService;
var
  xMemory: IMemory<PQueryServiceConfigW>;
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfigW';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);

  IMemory(xMemory) := Auto.AllocateDynamic(0);
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

function ScmxQueryProcessStatusService;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceStatusEx';
  Result.LastCall.UsesInfoClass(SC_STATUS_PROCESS_INFO, icQuery);
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_STATUS);

  Result.Win32Result := QueryServiceStatusEx(hSvc, SC_STATUS_PROCESS_INFO,
    @Info, SizeOf(Info), Required);
end;

class function NtxService.Query<T>;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfig2W';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.Win32Result := QueryServiceConfig2W(hSvc, InfoClass, @Buffer,
    SizeOf(Buffer), Required);
end;

function ScmxQueryService;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfig2W';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Win32Result := QueryServiceConfig2W(hSvc, InfoClass, xMemory.Data,
      xMemory.Size, Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, nil);
end;

function ScmxSetService;
begin
  Result.Location := 'ChangeServiceConfig2W';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_CHANGE_CONFIG);
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.Win32Result := ChangeServiceConfig2W(hSvc, InfoClass, Buffer);
end;

function ScmxQueryDescriptionService;
var
  xMemory: IMemory<PServiceDescription>;
begin
  Result := ScmxQueryService(hSvc, SERVICE_CONFIG_DESCRIPTION,
    IMemory(xMemory));

  if Result.IsSuccess then
    Description := String(xMemory.Data.Description);
end;

function ScmxQueryRequiredPrivilegesService;
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

function ScmxQuerySecurityObject;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceObjectSecurity';
  Result.LastCall.Expects(SecurityReadAccess(Info));

  IMemory(SD) := Auto.AllocateDynamic(0);
  repeat
    Required := 0;
    Result.Win32Result := QueryServiceObjectSecurity(ScmHandle, Info, SD.Data,
      SD.Size, Required);
  until not NtxExpandBufferEx(Result, IMemory(SD), Required, nil);
end;

function ScmxSetSecurityObject;
begin
  Result.Location := 'SetServiceObjectSecurity';
  Result.LastCall.Expects(SecurityWriteAccess(Info));
  Result.Win32Result := SetServiceObjectSecurity(ScmHandle, Info, SD);
end;

end.
