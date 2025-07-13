unit NtUtils.Svc;

{
  This module includes functions for interacting with Service Control Manager.
}

interface

uses
  Ntapi.WinNt, Ntapi.WinSvc, NtUtils, NtUtils.Objects;

type
  IScmHandle = NtUtils.IHandle;

  TScmDatabase = (
    scmDefaultDatabase,
    scmActiveDatabase,
    scmFailedDatabase
  );

  TServiceEntry = record
    ServiceName: String;
    DisplayName: String;
    Status: TServiceStatus;
  end;

  TServiceEntryEx = record
    ServiceName: String;
    DisplayName: String;
    Status: TServiceStatusProcess;
  end;

  TServiceConfig = record
    ServiceType: TServiceType;
    StartType: TServiceStartType;
    ErrorControl: TServiceErrorControl;
    TagID: TServiceTag;
    BinaryPathName: String;
    LoadOrderGroup: String;
    ServiceStartName: String;
    DisplayName: String;
  end;

  TServiceTagInfo = record
    Tag: TServiceTag;
    ServiceName: String;
    GroupName: String;
  end;

// Open a handle to SCM
function ScmxConnect(
  out hxScm: IScmHandle;
  DesiredAccess: TScmAccessMask;
  Database: TScmDatabase = scmDefaultDatabase;
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
  ServiceType: TServiceType = SERVICE_WIN32_OWN_PROCESS;
  StartType: TServiceStartType = SERVICE_DEMAND_START;
  ErrorControl: TServiceErrorControl = SERVICE_ERROR_NORMAL;
  [opt] Dependencies: TArray<String> = nil;
  [opt] LoadOrderGroup: String = '';
  [opt] Username: String = '';
  [opt] Password: String = '';
  [out, opt] pTagId: PCardinal = nil;
  [opt, Access(SC_MANAGER_CREATE_SERVICE)] hxScm: IScmHandle = nil
): TNtxStatus;

// Get all supported service types for the current OS version
function ScmxSupportedServiceTypes: TServiceType;

// Enumerate services and their statuses
function ScmxEnumerateServices(
  out Services: TArray<TServiceEntry>;
  ServiceType: TServiceType = SERVICE_TYPE_ALL;
  ServiceState: TServiceEnumState = SERVICE_STATE_ALL;
  [opt, Access(SC_MANAGER_ENUMERATE_SERVICE)] hxScm: IScmHandle = nil
): TNtxStatus;

// Enumerate services and their process statuses
function ScmxEnumerateServicesEx(
  out Services: TArray<TServiceEntryEx>;
  ServiceType: TServiceType = SERVICE_TYPE_ALL;
  ServiceState: TServiceEnumState = SERVICE_STATE_ALL;
  [opt] const GroupName: String = '';
  [opt, Access(SC_MANAGER_ENUMERATE_SERVICE)] hxScm: IScmHandle = nil
): TNtxStatus;

// Enumerate services that depend on a given service
function ScmxEnumerateDependentServices(
  [Access(SERVICE_ENUMERATE_DEPENDENTS)] const hxService: IScmHandle;
  out Services: TArray<TServiceEntry>;
  ServiceState: TServiceEnumState = SERVICE_STATE_ALL
): TNtxStatus;

// Start a service
function ScmxStartService(
  [Access(SERVICE_START)] const hxService: IScmHandle;
  [opt] const Parameters: TArray<String> = nil
): TNtxStatus;

// Send a control to a service
function ScmxControlService(
  [Access(SERVICE_CONTROL_ANY)] const hxService: IScmHandle;
  Control: TServiceControl;
  out ServiceStatus: TServiceStatus
): TNtxStatus;

// Send a control to a service specifying a reason
function ScmxControlServiceEx(
  [Access(SERVICE_CONTROL_ANY)] const hxService: IScmHandle;
  Control: TServiceControl;
  out ServiceStatus: TServiceStatusProcess;
  StopReason: TServiceStopReason = SERVICE_STOP_REASON_FLAG_CUSTOM;
  [opt] const Comment: String = ''
): TNtxStatus;

// Delete a service
function ScmxDeleteService(
  [Access(_DELETE)] const hxService: IScmHandle
): TNtxStatus;

// Query variable-size service information
function ScmxQueryService(
  [Access(SERVICE_QUERY_CONFIG)] const hxService: IScmHandle;
  InfoClass: TServiceConfigLevel;
  out Buffer: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

type
  NtxService = class abstract
    // Query fixed-size information
    class function Query<T>(
      [Access(SERVICE_QUERY_CONFIG)] const hxService: IScmHandle;
      InfoClass: TServiceConfigLevel;
      out Buffer: T
    ): TNtxStatus; static;
  end;

// Query service status
function ScmxQueryStatusService(
  [Access(SERVICE_QUERY_STATUS)] const hxService: IScmHandle;
  out Status: TServiceStatus
): TNtxStatus;

// Query service status and process information
function ScmxQueryProcessStatusService(
  [Access(SERVICE_QUERY_STATUS)] const hxService: IScmHandle;
  out Info: TServiceStatusProcess
): TNtxStatus;

// Query service configuration
function ScmxQueryConfigService(
  [Access(SERVICE_QUERY_CONFIG)] const hxService: IScmHandle;
  out Config: TServiceConfig
): TNtxStatus;

// Query service description
function ScmxQueryDescriptionService(
  [Access(SERVICE_QUERY_CONFIG)] const hxService: IScmHandle;
  out Description: String
): TNtxStatus;

// Query list of requires privileges for a service
function ScmxQueryRequiredPrivilegesService(
  [Access(SERVICE_QUERY_CONFIG)] const hxService: IScmHandle;
  out Privileges: TArray<String>
): TNtxStatus;

// Set service information
function ScmxSetService(
  [Access(SERVICE_CHANGE_CONFIG)] const hxService: IScmHandle;
  InfoClass: TServiceConfigLevel;
  [in] Buffer: Pointer
): TNtxStatus;

// Set service configuration
function ScmxConfigureService(
  [Access(SERVICE_CHANGE_CONFIG)] const hxService: IScmHandle;
  ServiceType: TServiceType = SERVICE_NO_CHANGE;
  StartType: TServiceStartType = TServiceStartType(SERVICE_NO_CHANGE);
  ErrorControl: TServiceErrorControl = TServiceErrorControl(SERVICE_NO_CHANGE);
  [in, opt] BinaryPathName: String = '';
  [in, opt] LoadOrderGroup: String = '';
  [in, opt] const Dependencies: TArray<String> = nil;
  [in, opt] ServiceStartName: String = '';
  [in, opt] Password: String = '';
  [in, opt] DisplayName: String = '';
  [out, opt] pTagId: PCardinal = nil
): TNtxStatus;

// Convert service display name to service (key) name
function ScmxLookupDisplayName(
  const DisplayName: String;
  out ServiceName: String;
  [opt, Access(SC_MANAGER_CONNECT)] hxSCManager: IScmHandle = nil
): TNtxStatus;

// Convert service name to service display name
function ScmxLookupServiceName(
  const ServiceName: String;
  out DisplayName: String;
  [opt, Access(SC_MANAGER_CONNECT)] hxSCManager: IScmHandle = nil
): TNtxStatus;

// Convert service tag to service name
[Access(SC_MANAGER_ENUMERATE_SERVICE)]
function ScmxLookupServiceTag(
  PID: TProcessId32;
  ServiceTag: TServiceTag;
  out ServiceName: String
): TNtxStatus;

// Enumerate service tags in a process
[Access(SC_MANAGER_ENUMERATE_SERVICE)]
function ScmxEnumerateServiceTags(
  PID: TProcessId32;
  out ServiceTags: TArray<TServiceTagInfo>
): TNtxStatus;

// Query security descriptor of a SCM object
function ScmxQuerySecurityObject(
  [Access(OBJECT_READ_SECURITY)] const ScmHandle: IScmHandle;
  Info: TSecurityInformation;
  out SD: ISecurityDescriptor
): TNtxStatus;

// Set security descriptor on a SCM object
function ScmxSetSecurityObject(
  [Access(OBJECT_WRITE_SECURITY)] const ScmHandle: IScmHandle;
  Info: TSecurityInformation;
  [in] SD: PSecurityDescriptor
): TNtxStatus;

// Lock SCM database
function ScmxLockDatabase(
  out Lock: IAutoReleasable;
  [opt, Access(SC_MANAGER_LOCK)] hxScm: IScmHandle = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.WinError, Ntapi.WinBase, Ntapi.Versions,
  NtUtils.SysUtils, DelphiUtils.Arrays, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TAutoScmHandle = class (TCustomAutoHandle)
    destructor Destroy; override;
  end;

destructor TAutoScmHandle.Destroy;
begin
  if (FHandle <> 0) and not FDiscardOwnership then
    CloseServiceHandle(FHandle);

  inherited;
end;

function ScmxConnect;
var
  hScm: TScmHandle;
  DatabaseStr: PWideChar;
begin
  case Database of
    scmActiveDatabase:
      DatabaseStr := SERVICES_ACTIVE_DATABASE;

    scmFailedDatabase:
      DatabaseStr := SERVICES_FAILED_DATABASE;
  else
    DatabaseStr := nil;
  end;

  Result.Location := 'OpenSCManagerW';

  // It seems that SCM always checks for SC_MANAGER_CONNECT
  Result.LastCall.OpensForAccess<TScmAccessMask>(DesiredAccess or
    SC_MANAGER_CONNECT);

  hScm := OpenSCManagerW(RefStrOrNil(ServerName), DatabaseStr, DesiredAccess);
  Result.Win32Result := (hScm <> 0);

  if Result.IsSuccess then
    hxScm := TAutoScmHandle.Capture(hScm);
end;

function ScmxpEnsureConnected(
  var hxScm: IScmHandle;
  DesiredAccess: TScmAccessMask
): TNtxStatus;
begin
  if not Assigned(hxScm) then
    Result := ScmxConnect(hxScm, DesiredAccess)
  else
    Result := NtxSuccess;
end;

function ScmxOpenService;
var
  hService: TScmHandle;
begin
  Result := ScmxpEnsureConnected(hxScm, SC_MANAGER_CONNECT);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'OpenServiceW';
  Result.LastCall.OpensForAccess(DesiredAccess);
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_CONNECT);

  hService := OpenServiceW(hxScm.Handle, PWideChar(ServiceName), DesiredAccess);
  Result.Win32Result := (hService <> 0);

  if Result.IsSuccess then
    hxSvc := TAutoScmHandle.Capture(hService);
end;

function ScmxCreateService;
var
  hService: TScmHandle;
begin
  Result := ScmxpEnsureConnected(hxScm, SC_MANAGER_CREATE_SERVICE);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'CreateServiceW';
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_CREATE_SERVICE);

  hService := CreateServiceW(
    hxScm.Handle,
    PWideChar(ServiceName),
    RefStrOrNil(DisplayName),
    SERVICE_ALL_ACCESS,
    ServiceType,
    StartType,
    ErrorControl,
    PWideChar(CommandLine),
    RefStrOrNil(LoadOrderGroup),
    pTagId,
    RtlxBuildWideMultiSz(Dependencies).Data,
    RefStrOrNil(Username),
    RefStrOrNil(Password)
  );
  Result.Win32Result := (hService <> 0);

  if Result.IsSuccess then
    hxSvc := TAutoScmHandle.Capture(hService);
end;

function ScmxSupportedServiceTypes;
var
  OsVersion: TWindowsVersion;
begin
  Result := SERVICE_TYPE_ALL;
  OsVersion := RtlOsVersion;

  if OsVersion < OsWin10RS1 then
    Result := Result and not SERVICE_PKG_SERVICE;

  if OsVersion < OsWin10TH1 then
    Result := Result and not SERVICE_USER_SERVICE and
      not SERVICE_USERSERVICE_INSTANCE;
end;

function ScmxEnumerateServices;
var
  Buffer: IMemory<PEnumServiceStatusArray>;
  RequiredSize: Cardinal;
  Count: Cardinal;
  i: Integer;
begin
  Result := ScmxpEnsureConnected(hxScm, SC_MANAGER_ENUMERATE_SERVICE);

  if not Result.IsSuccess then
    Exit;

  // Restrict service types to supported-only
  if ServiceType = SERVICE_TYPE_ALL then
    ServiceType := ScmxSupportedServiceTypes;

  Result.Location := 'EnumServicesStatusW';
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_ENUMERATE_SERVICE);

  IMemory(Buffer) := Auto.AllocateDynamic(0);

  repeat
    Result.Win32Result := EnumServicesStatusW(
      hxScm.Handle,
      ServiceType,
      ServiceState,
      Buffer.Data,
      Buffer.Size,
      RequiredSize,
      Count,
      nil
    );
  until not NtxExpandBufferEx(Result, IMemory(Buffer), RequiredSize,
    Grow12Percent);

  if not Result.IsSuccess then
    Exit;

  SetLength(Services, Count);

  for i := 0 to High(Services) do
    with Buffer.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF} do
    begin
      Services[i].ServiceName := String(ServiceName);
      Services[i].DisplayName := String(DisplayName);
      Services[i].Status := ServiceStatus;
    end;
end;

function ScmxEnumerateServicesEx;
var
  Buffer: IMemory<PEnumServiceStatusProcessArray>;
  RequiredSize: Cardinal;
  Count: Cardinal;
  i: Integer;
begin
  Result := ScmxpEnsureConnected(hxScm, SC_MANAGER_ENUMERATE_SERVICE);

  if not Result.IsSuccess then
    Exit;

  // Restrict service types to supported-only
  if ServiceType = SERVICE_TYPE_ALL then
    ServiceType := ScmxSupportedServiceTypes;

  Result.Location := 'EnumServicesStatusExW';
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_ENUMERATE_SERVICE);

  IMemory(Buffer) := Auto.AllocateDynamic(0);

  repeat
    Result.Win32Result := EnumServicesStatusExW(
      hxScm.Handle,
      SC_ENUM_PROCESS_INFO,
      ServiceType,
      ServiceState,
      Buffer.Data,
      Buffer.Size,
      RequiredSize,
      Count,
      nil,
      RefStrOrNil(GroupName)
    );
  until not NtxExpandBufferEx(Result, IMemory(Buffer), RequiredSize,
    Grow12Percent);

  if not Result.IsSuccess then
    Exit;

  SetLength(Services, Count);

  for i := 0 to High(Services) do
    with Buffer.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF} do
    begin
      Services[i].ServiceName := String(ServiceName);
      Services[i].DisplayName := String(DisplayName);
      Services[i].Status := ServiceStatusProcess;
    end;
end;

function ScmxEnumerateDependentServices;
var
  Buffer: IMemory<PEnumServiceStatusArray>;
  RequiredSize: Cardinal;
  Count: Cardinal;
  i: Integer;
begin
  Result.Location := 'EnumDependentServicesW';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_ENUMERATE_DEPENDENTS);

  IMemory(Buffer) := Auto.AllocateDynamic(0);

  repeat
    Result.Win32Result := EnumDependentServicesW(
      HandleOrDefault(hxService),
      ServiceState,
      Buffer.Data,
      Buffer.Size,
      RequiredSize,
      Count
    );
  until not NtxExpandBufferEx(Result, IMemory(Buffer), RequiredSize,
    Grow12Percent);

  if not Result.IsSuccess then
    Exit;

  SetLength(Services, Count);

  for i := 0 to High(Services) do
    with Buffer.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF} do
    begin
      Services[i].ServiceName := String(ServiceName);
      Services[i].DisplayName := String(DisplayName);
      Services[i].Status := ServiceStatus;
    end;
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

  Result.Win32Result := StartServiceW(HandleOrDefault(hxService),
    Length(Params), Params);
end;

function ScmxControlService;
begin
  Result.Location := 'ControlService';
  Result.LastCall.UsesInfoClass(Control, icControl);
  Result.LastCall.Expects(ExpectedSvcControlAccess(Control));
  Result.Win32Result := ControlService(HandleOrDefault(hxService), Control,
    ServiceStatus);
end;

function ScmxControlServiceEx;
var
  Info: TServiceControlStatusReasonParams;
begin
  Info := Default(TServiceControlStatusReasonParams);
  Info.Reason := StopReason;
  Info.Comment := RefStrOrNil(Comment);

  Result.Location := 'ControlServiceExW';
  Result.LastCall.UsesInfoClass(Control, icControl);
  Result.LastCall.Expects(ExpectedSvcControlAccess(Control));
  Result.Win32Result := ControlServiceExW(HandleOrDefault(hxService), Control,
    SERVICE_CONTROL_STATUS_REASON_INFO, @Info);

  // The function might fill in the output on failure
  ServiceStatus := Info.ServiceStatus;
end;

function ScmxDeleteService;
begin
  Result.Location := 'DeleteService';
  Result.LastCall.Expects<TServiceAccessMask>(_DELETE);
  Result.Win32Result := DeleteService(HandleOrDefault(hxService));
end;

function ScmxQueryService;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfig2W';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);

  Buffer := Auto.AllocateDynamic(InitialBuffer);

  repeat
    Required := 0;
    Result.Win32Result := QueryServiceConfig2W(
      HandleOrDefault(hxService),
      InfoClass,
      Buffer.Data,
      Buffer.Size,
      Required
    );
  until not NtxExpandBufferEx(Result, Buffer, Required, nil);
end;

class function NtxService.Query<T>;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfig2W';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.Win32Result := QueryServiceConfig2W(HandleOrDefault(hxService),
    InfoClass, @Buffer, SizeOf(Buffer), Required);
end;

function ScmxQueryStatusService;
begin
  Result.Location := 'QueryServiceStatus';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_STATUS);
  Result.Win32Result := QueryServiceStatus(HandleOrDefault(hxService), Status);
end;

function ScmxQueryProcessStatusService;
var
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceStatusEx';
  Result.LastCall.UsesInfoClass(SC_STATUS_PROCESS_INFO, icQuery);
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_STATUS);

  Result.Win32Result := QueryServiceStatusEx(HandleOrDefault(hxService),
    SC_STATUS_PROCESS_INFO, @Info, SizeOf(Info), Required);
end;

function ScmxQueryConfigService;
var
  Buffer: IMemory<PQueryServiceConfig>;
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceConfig';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_QUERY_CONFIG);

  IMemory(Buffer) := Auto.AllocateDynamic(0);

  repeat
    Required := 0;
    Result.Win32Result := QueryServiceConfigW(
      HandleOrDefault(hxService),
      Buffer.Data,
      Buffer.Size,
      Required
    );
  until not NtxExpandBufferEx(Result, IMemory(Buffer), Required, nil);

  if not Result.IsSuccess then
    Exit;

  Config.ServiceType := Buffer.Data.ServiceType;
  Config.StartType := Buffer.Data.StartType;
  Config.ErrorControl := Buffer.Data.ErrorControl;
  Config.TagId := Buffer.Data.TagId;
  Config.BinaryPathName := String(Buffer.Data.BinaryPathName);
  Config.LoadOrderGroup := String(Buffer.Data.LoadOrderGroup);
  Config.ServiceStartName := String(Buffer.Data.ServiceStartName);
  Config.DisplayName := String(Buffer.Data.DisplayName);
end;

function ScmxQueryDescriptionService;
var
  Buffer: IMemory<PWideChar>;
begin
  Result := ScmxQueryService(hxService, SERVICE_CONFIG_DESCRIPTION,
    IMemory(Buffer));

  if Result.IsSuccess then
    Description := String(Buffer.Data);
end;

function ScmxQueryRequiredPrivilegesService;
var
  Buffer: IMemory<PServiceRequiredPrivilegesInfo>;
begin
  Result := ScmxQueryService(hxService, SERVICE_CONFIG_REQUIRED_PRIVILEGES_INFO,
    IMemory(Buffer), SizeOf(TServiceRequiredPrivilegesInfo));

  if Result.IsSuccess and Assigned(Buffer.Data.RequiredPrivileges) then
    Privileges := RtlxParseWideMultiSz(Buffer.Data.RequiredPrivileges,
      (Buffer.Size - SizeOf(TServiceRequiredPrivilegesInfo)) div
      SizeOf(WideChar))
  else
    SetLength(Privileges, 0);
end;

function ScmxSetService;
begin
  Result.Location := 'ChangeServiceConfig2W';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_CHANGE_CONFIG);
  Result.LastCall.UsesInfoClass(InfoClass, icSet);
  Result.Win32Result := ChangeServiceConfig2W(HandleOrDefault(hxService),
    InfoClass, Buffer);
end;

function ScmxConfigureService;
begin
  Result.Location := 'ChangeServiceConfigW';
  Result.LastCall.Expects<TServiceAccessMask>(SERVICE_CHANGE_CONFIG);
  Result.Win32Result := ChangeServiceConfigW(
    HandleOrDefault(hxService),
    ServiceType,
    StartType,
    ErrorControl,
    RefStrOrNil(BinaryPathName),
    RefStrOrNil(LoadOrderGroup),
    pTagId,
    RtlxBuildWideMultiSz(Dependencies).Data,
    RefStrOrNil(ServiceStartName),
    RefStrOrNil(Password),
    RefStrOrNil(DisplayName)
  );
end;

function ScmxLookupDisplayName;
var
  Buffer: IMemory<PWideChar>;
  RequiredLength: Cardinal;
begin
  Result := ScmxpEnsureConnected(hxSCManager, 0);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetServiceKeyNameW';
  IMemory(Buffer) := Auto.AllocateDynamic(64);

  repeat
    RequiredLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32Result := GetServiceKeyNameW(
      hxSCManager.Handle,
      RefStrOrNil(DisplayName),
      Buffer.Data,
      RequiredLength
    );
  until not NtxExpandBufferEx(Result, IMemory(Buffer),
    Succ(RequiredLength) * SizeOf(WideChar), nil);

  if Result.IsSuccess then
    ServiceName := String(Buffer.Data);
end;

function ScmxLookupServiceName;
var
  Buffer: IMemory<PWideChar>;
  RequiredLength: Cardinal;
begin
  Result := ScmxpEnsureConnected(hxSCManager, 0);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'GetServiceDisplayNameW';
  IMemory(Buffer) := Auto.AllocateDynamic(64);

  repeat
    RequiredLength := Buffer.Size div SizeOf(WideChar);
    Result.Win32Result := GetServiceDisplayNameW(
      hxSCManager.Handle,
      RefStrOrNil(ServiceName),
      Buffer.Data,
      RequiredLength
    );
  until not NtxExpandBufferEx(Result, IMemory(Buffer),
    Succ(RequiredLength) * SizeOf(WideChar), nil);

  if Result.IsSuccess then
    DisplayName := String(Buffer.Data);
end;

function ScmxLookupServiceTag;
var
  Info: TTagInfoNameFromTag;
  InfoDeallocator: IDeferredOperation;
begin
  Info := Default(TTagInfoNameFromTag);
  Info.Pid := PID;
  Info.Tag := ServiceTag;

  Result.Location := 'I_QueryTagInformation';
  Result.LastCall.UsesInfoClass(eTagInfoLevelNameFromTag, icQuery);
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_ENUMERATE_SERVICE);

  Result.Win32ErrorOrSuccess := I_QueryTagInformation(nil,
    eTagInfoLevelNameFromTag, @Info);

  if not Result.IsSuccess then
    Exit;

  InfoDeallocator := DeferLocalFree(Info.Name);
  ServiceName := String(Info.Name);
end;

function ScmxEnumerateServiceTags;
var
  Info: TTagInfoNameTagMapping;
  InfoDeallocator: IDeferredOperation;
  i: Integer;
begin
  Info := Default(TTagInfoNameTagMapping);
  Info.Pid := PID;

  Result.Location := 'I_QueryTagInformation';
  Result.LastCall.UsesInfoClass(eTagInfoLevelNameTagMapping, icQuery);
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_ENUMERATE_SERVICE);

  Result.Win32ErrorOrSuccess := I_QueryTagInformation(nil,
    eTagInfoLevelNameTagMapping, @Info);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(Info.OutParams) then
  begin
    ServiceTags := nil;
    Exit;
  end;

  InfoDeallocator := DeferLocalFree(Info.OutParams);
  SetLength(ServiceTags, Info.OutParams.Elements);

  for i := 0 to High(ServiceTags) do
    with Info.OutParams.NameTagMappingElements{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF} do
    begin
      ServiceTags[i].Tag := Tag;
      ServiceTags[i].ServiceName := String(Name);
      ServiceTags[i].GroupName := String(GroupName);
    end;
end;

function ScmxQuerySecurityObject;
var
  Buffer: IMemory absolute SD;
  Required: Cardinal;
begin
  Result.Location := 'QueryServiceObjectSecurity';
  Result.LastCall.Expects(SecurityReadAccess(Info));

  Buffer := Auto.AllocateDynamic(0);
  repeat
    Required := 0;
    Result.Win32Result := QueryServiceObjectSecurity(HandleOrDefault(ScmHandle),
      Info, Buffer.Data, Buffer.Size, Required);
  until not NtxExpandBufferEx(Result, Buffer, Required, nil);
end;

function ScmxSetSecurityObject;
begin
  Result.Location := 'SetServiceObjectSecurity';
  Result.LastCall.Expects(SecurityWriteAccess(Info));
  Result.Win32Result := SetServiceObjectSecurity(HandleOrDefault(ScmHandle),
    Info, SD);
end;

type
  TAutoScmLock = class (TCustomAutoHandle)
    destructor Destroy; override;
  end;

destructor TAutoScmLock.Destroy;
begin
  if (FHandle <> 0) and not FDiscardOwnership then
    UnlockServiceDatabase(FHandle);

  inherited;
end;

function ScmxLockDatabase;
var
  Cookie: TScLock;
begin
  Result := ScmxpEnsureConnected(hxScm, SC_MANAGER_LOCK);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LockServiceDatabase';
  Result.LastCall.Expects<TScmAccessMask>(SC_MANAGER_LOCK);
  Cookie := LockServiceDatabase(hxScm.Handle);
  Result.Win32Result := Cookie <> 0;

  if Result.IsSuccess then
    Lock := TAutoScmLock.Capture(Cookie);
end;

end.
