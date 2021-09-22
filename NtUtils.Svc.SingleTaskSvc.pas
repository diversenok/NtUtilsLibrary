unit NtUtils.Svc.SingleTaskSvc;

{
  This module provides a template for a simple service application that executes
  its payload and exits.
}

interface

uses
  NtUtils, NtUtils.Svc;

type
  TSvcxPayload = reference to procedure(const ScvParams: TArray<String>);

// Starts service control dispatcher.
function SvcxMain(
  const ServiceName: String;
  const Payload: TSvcxPayload
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.WinSvc, Ntapi.WinError, Ntapi.WinBase;

var
  SvcxName: String;
  SvcxPayload: TSvcxPayload = nil;

  SvcxStatusHandle: THandle;
  SvcxStatus: TServiceStatus = (
      ServiceType:             SERVICE_WIN32_OWN_PROCESS;
      CurrentState:            SERVICE_RUNNING;
      ControlsAccepted:        0;
      Win32ExitCode:           0;
      ServiceSpecificExitCode: 0;
      CheckPoint:              0;
      WaitHint:                5000
    );

function SvcxHandlerEx(
  Control: TServiceControl;
  EventType: Cardinal;
  EventData: Pointer;
  var Context
): TWin32Error; stdcall;
begin
  if Control = SERVICE_CONTROL_INTERROGATE then
    Result := ERROR_SUCCESS
  else
    Result := ERROR_CALL_NOT_IMPLEMENTED;
end;

procedure SvcxServiceMain(
  dwNumServicesArgs: Integer;
  const [ref] ServiceArgVectors: TAnysizeArray<PWideChar>
); stdcall;
var
  i: Integer;
  Parameters: TArray<String>;
begin
  // Register service control handler
  SvcxStatusHandle := RegisterServiceCtrlHandlerExW(PWideChar(SvcxName),
    SvcxHandlerEx, nil);

  // Report running status
  SetServiceStatus(SvcxStatusHandle, SvcxStatus);

  // Prepare passed parameters
  SetLength(Parameters, dwNumServicesArgs);

  for i := 0 to High(Parameters) do
    Parameters[i] := String(ServiceArgVectors{$R-}[i]{$R+});

  {$IFDEF DEBUG}
  OutputDebugStringW(PWideChar(ParamStr(0)));
  OutputDebugStringW('Service parameters: ');

  for i := 0 to dwNumServicesArgs - 1 do
    OutputDebugStringW(ServiceArgVectors{$R-}[i]{$R+});
  {$ENDIF}

  // Call the payload
  try
    if Assigned(SvcxPayload) then
      SvcxPayload(Parameters);
  except
    OutputDebugStringW('Exception in ServiceMain');
  end;

  // Report that we have finished
  SvcxStatus.CurrentState := SERVICE_STOPPED;
  SetServiceStatus(SvcxStatusHandle, SvcxStatus);
end;

function SvcxMain;
var
  ServiceTable: array [0 .. 1] of TServiceTableEntryW;
begin
  SvcxName := ServiceName;
  SvcxPayload := Payload;

  ServiceTable[0].ServiceName := PWideChar(SvcxName);
  ServiceTable[0].ServiceProc := SvcxServiceMain;
  ServiceTable[1].ServiceName := nil;
  ServiceTable[1].ServiceProc := nil;

  Result.Location := 'StartServiceCtrlDispatcherW';
  Result.Win32Result := StartServiceCtrlDispatcherW(PServiceTableEntryW(
    @ServiceTable));
end;

end.
