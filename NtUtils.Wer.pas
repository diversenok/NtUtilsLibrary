unit NtUtils.Wer;

{
  This unit provides wrappers for communicating with Windows Error Reporting.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.werscv, NtUtils;

const
  WER_DEFAULT_TIMEOUT = 10000 * MILLISEC;

// Signal WER to start, if necessary
function WerxEnsureWerStarted(
  const Timeout: TLargeInteger = 10000 * MILLISEC
): TNtxStatus;

// Wake WER up and connect to its ALPC port
function WerxConnect(
  out hxPort: IHandle;
  Timeout: TLargeInteger = WER_DEFAULT_TIMEOUT
): TNtxStatus;

// Send a WER message and wait for the reply
function WerxSendWaitReceive(
  const hxPort: IHandle;
  var Msg: TWerSvcMsg;
  SuccessReply: TWerSvcMessageId;
  ErrorReply: TWerSvcMessageId;
  const RequestNameHint: String = '';
  Timeout: TLargeInteger = WER_DEFAULT_TIMEOUT
): TNtxStatus;

// Report a silent process exit event to WER
function WerxReportSilentProcessExit(
  out hxCrashReportingProcess: IHandle;
  InitiatingThreadId: TThreadId32;
  InitiatingProcessId: TProcessId32;
  ExitingProcessId: TProcessId32;
  ExitStatus: NTSTATUS
): TNtxStatus;

// Ask WER to a execute an elevated WerFault command
function WerxElevatedCommand(
  out hxWerFaultProcess: IHandle;
  const WerFaultArguments: String;
  const HandlesToInherit: TArray<IHandle> = nil
): TNtxStatus;

// Ask WER to start an unelevated process via WerMgr
function WerxNonElevatedCommand(
  out hxWerMgrProcess: IHandle;
  LaunchType: TNonElevatedProcLaunchType;
  const ExePath: String;
  const CommandLine: String
): TNtxStatus;

implementation

uses
  Ntapi.ntlpcapi, Ntapi.ntwnf, Ntapi.ntstatus, Ntapi.ntpsapi,
  NtUtils.Synchronization, NtUtils.Wnf, NtUtils.Lpc, NtUtils.Objects,
  NtUtils.Sections, NtUtils.SysUtils, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function WerxEnsureWerStarted;
var
  hxEvent: IHandle;
begin
  Result := NtxOpenEvent(hxEvent, SYNCHRONIZE, WERSVC_EVENT_NAME);

  if not Result.IsSuccess then
    Exit;

  // Test if WER is running and ready
  Result := NtxWaitForSingleObject(hxEvent, 0);

  if Result.Status = STATUS_TIMEOUT then
  begin
    // Request WER to start
    Result := NtxUpdateWnfStateData(WNF_WER_SERVICE_START, nil, 0,
      'WNF_WER_SERVICE_START');

    if not Result.IsSuccess then
      Exit;

    Result := NtxWaitForSingleObject(hxEvent, Timeout);
  end;
end;

function WerxConnect;
var
  PortAttributes: TAlpcPortAttributes;
begin
  // Signal WER to start
  Result := WerxEnsureWerStarted(Timeout);

  if not Result.IsSuccess then
    Exit;

  PortAttributes := Default(TAlpcPortAttributes);
  PortAttributes.MaxMessageLength := SizeOf(TWerSvcMsg);

  // Connect to it
  Result := NtxAlpcConnectPort(hxPort, WERSVC_PORT_NAME,
    ALPC_MSGFLG_SYNC_REQUEST, nil, @PortAttributes, Timeout);
end;

function WerxSendWaitReceive;
begin
  // Send the requet
  Result := NtxAlpcSendWaitReceivePort(hxPort, @Msg.hdr, @Msg.hdr, nil,
    ALPC_MSGFLG_SYNC_REQUEST, Timeout);
  Result.LastCall.Parameter := RequestNameHint;

  if not Result.IsSuccess then
    Exit;

  // Process the reply
  if Msg.MsgId = ErrorReply then
  begin
    // Forward the error code
    Result.Location := RtlxStringOrDefault(RequestNameHint,
      'WER::DispatchPortRequestWorkItem');
    Result.HResult := Msg.Status;

    // Make sure the error is unsuccessful
    if Result.IsSuccess then
      Result.HResult := S_FALSE;
  end
  else if Msg.MsgId <> SuccessReply then
  begin
    // Unexpected reply code
    Result.Location := 'WerxSendWaitReceive';
    Result.LastCall.Parameter := RequestNameHint;
    Result.LastCall.UsesInfoClass(Msg.MsgId, icReturn);
    Result.Status := STATUS_UNSUCCESSFUL;
  end;
end;

function WerxReportSilentProcessExit;
var
  hxPort: IHandle;
  Msg: TWerSvcMsg;
begin
  Result := WerxConnect(hxPort);

  if not Result.IsSuccess then
    Exit;

  // Prepare the message
  Msg := Default(TWerSvcMsg);
  Msg.hdr.u1.TotalLength := SizeOf(TWerSvcMsg);
  Msg.hdr.u1.DataLength := SizeOf(TWerSvcMsg) - SizeOf(TPortMessage);
  Msg.MsgId := WERSVC_MSG_SILENT_PROCESS_EXIT_REQUEST;
  Msg.SilentProcessExitInfo.InitiatingThreadId := InitiatingThreadId;
  Msg.SilentProcessExitInfo.InitiatingProcessId := InitiatingProcessId;
  Msg.SilentProcessExitInfo.ExitingProcessId := ExitingProcessId;
  Msg.SilentProcessExitInfo.ExitStatus := ExitStatus;

  // Send it
  Result := WerxSendWaitReceive(hxPort, Msg,
    WERSVC_MSG_SILENT_PROCESS_EXIT_REPLY,
    WERSVC_MSG_SILENT_PROCESS_EXIT_ERROR,
    'WER::SilentProcessExitReport'
  );

  if not Result.IsSuccess then
    Exit;

  // The initiating process gets a SYNCHRONIZE handle to the crash-reporting
  // process
  if InitiatingProcessId = NtCurrentProcessId then
    hxCrashReportingProcess := Auto.CaptureHandle(
      THandle(Msg.hCrashReportingProcess))
  else
    hxCrashReportingProcess := Auto.RefHandle(
      THandle(Msg.hCrashReportingProcess));
end;

function WerxElevatedCommand;
var
  hxPort: IHandle;
  Msg: TWerSvcMsg;
  hxSection: IHandle;
  SharedMapping: IMemory;
  i: Integer;
begin
  if Length(HandlesToInherit) >= High(TWerSvcElevatedProcInfoHandles) then
  begin
    Result.Location := 'WerxNonElevatedCommand';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result := WerxConnect(hxPort);

  if not Result.IsSuccess then
    Exit;

  // Prepare a section for passing the arguments string
  Result := NtxCreateSection(hxSection, StringSizeZero(
    WerFaultArguments));

  if not Result.IsSuccess then
    Exit;

  // Map it for writing
  Result := NtxMapViewOfSection(hxSection, NtxCurrentProcess,
    SharedMapping, MappingParameters.UseProtection(PAGE_READWRITE));

  if not Result.IsSuccess then
    Exit;

  // Write the arguments string
  Move(PWideChar(WerFaultArguments)^, SharedMapping.Data^, StringSizeNoZero(
    WerFaultArguments));

  // Unmap
  SharedMapping := nil;

  // Prepare the message
  Msg := Default(TWerSvcMsg);
  Msg.hdr.u1.TotalLength := SizeOf(TWerSvcMsg);
  Msg.hdr.u1.DataLength := SizeOf(TWerSvcMsg) - SizeOf(TPortMessage);
  Msg.MsgId := WERSVC_MSG_ELEVATED_PROC_INFO_REQUEST;
  Msg.ElevatedProcInfo.ProcId := WERSVC_ELEVATED_PROC_INFO_START;
  Msg.ElevatedProcInfo.hSharedMem := hxSection.Handle;
  Msg.ElevatedProcInfo.dwHandlesToInherit := Length(HandlesToInherit);

  for i := 0 to High(HandlesToInherit) do
    Msg.ElevatedProcInfo.arrHandlesToInherit[i] := HandlesToInherit[i].Handle;

  // Send it
  Result := WerxSendWaitReceive(hxPort, Msg,
    WERSVC_MSG_ELEVATED_PROC_INFO_REPLY,
    WERSVC_MSG_ELEVATED_PROC_INFO_ERROR,
    'WER::ElevatedProcessStart'
  );

  if not Result.IsSuccess then
    Exit;

  // The caller gets a SYNCHRONIZE handle to the WerFault process
  hxWerFaultProcess := Auto.CaptureHandle(
    THandle(Msg.ElevatedProcInfo.hElevatedProcess));
end;

function WerxNonElevatedCommand;
var
  hxPort: IHandle;
  Msg: TWerSvcMsg;
  hxSection: IHandle;
  SharedData: IMemory<PNonElevatedProcData>;
begin
  if (High(ExePath) >= High(TMaxPathWideCharArray)) or
    (High(CommandLine) >= High(TNonElevatedProcDataCmd)) then
  begin
    Result.Location := 'WerxNonElevatedCommand';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  Result := WerxConnect(hxPort);

  if not Result.IsSuccess then
    Exit;

  // Prepare a section for passing the arguments string
  Result := NtxCreateSection(hxSection, SizeOf(TNonElevatedProcData));

  if not Result.IsSuccess then
    Exit;

  // Map it for writing
  Result := NtxMapViewOfSection(hxSection, NtxCurrentProcess,
    IMemory(SharedData), MappingParameters.UseProtection(PAGE_READWRITE));

  if not Result.IsSuccess then
    Exit;

  // Write the parameters
  SharedData.Data.Size := SizeOf(TNonElevatedProcData);
  SharedData.Data.LaunchType := LaunchType;
  Move(PWideChar(ExePath)^, SharedData.Data.ExePath, StringSizeZero(ExePath));
  Move(PWideChar(CommandLine)^, SharedData.Data.Cmd, StringSizeZero(CommandLine));

  // Unmap
  SharedData := nil;

  // Prepare the message
  Msg := Default(TWerSvcMsg);
  Msg.hdr.u1.TotalLength := SizeOf(TWerSvcMsg);
  Msg.hdr.u1.DataLength := SizeOf(TWerSvcMsg) - SizeOf(TPortMessage);
  Msg.MsgId := WERSVC_MSG_NONELEVATED_PROC_INFO_REQUEST;
  Msg.NonElevatedProcInfo.hSharedMem := hxSection.Handle;

  // Send it
  Result := WerxSendWaitReceive(hxPort, Msg,
    WERSVC_MSG_NONELEVATED_PROC_INFO_REPLY,
    WERSVC_MSG_NONELEVATED_PROC_INFO_ERROR,
    'WER::NonElevatedProcessStart'
  );

  if not Result.IsSuccess then
    Exit;

  // The caller gets a SYNCHRONIZE handle to the worker wermgr.exe process
  hxWerMgrProcess := Auto.CaptureHandle(
    THandle(Msg.NonElevatedProcInfo.hNonElevatedProcess));
end;

end.
