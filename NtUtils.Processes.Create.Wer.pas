unit NtUtils.Processes.Create.Wer;

{
  This module provides process creation methods via Windows Error Reporting ALPC
  port communication.
}

interface

uses
  Ntapi.ntseapi, NtUtils, NtUtils.Processes.Create;

// Create a new process via WER::NonElevatedProcessStart
[SupportedOption(spoParameters)]
function WerxExecuteNonElevated(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

// Create a new process via a WER::SilentProcessExitReport trigger
[RequiresAdmin]
[SupportedOption(spoParameters)]
[SupportedOption(spoRequireElevation)]
function WerxExecuteSilentProcessExit(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntstatus, Ntapi.ntdef, Ntapi.werscv, Ntapi.ntregapi,
  Ntapi.ntpebteb, Ntapi.ntpsapi, NtUtils.Wer, NtUtils.Registry,
  NtUtils.SysUtils, NtUtils.Synchronization;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function WerxExecuteNonElevated;
var
  hxWerMgr: IHandle;
begin
  // We do get a handle for waiting on the worker WerMgr process, but not the
  // target process info.
  Info := Default(TProcessInfo);

  // Send a request to WER
  Result := WerxNonElevatedCommand(hxWerMgr, NonElevatedProcLaunchTypeOpen,
    Options.ApplicationWin32, Options.CommandLine);
end;

const
  WER_SILENT_PROCESS_EXIT_KEY = REG_PATH_MACHINE +
    '\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SilentProcessExit';
  WER_SILENT_PROCESS_EXIT_MONITOR_PROCESS = 'MonitorProcess';
  WER_SILENT_PROCESS_EXIT_REPORTING_MODE = 'ReportingMode';

  WER_IFEO_KEY = REG_PATH_MACHINE +
    '\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options';
  WER_IFEO_GLOBAL_FLAGS = 'GlobalFlag';

function WerxSetSilentProcessExitKey(
  const ImageName: String;
  const MonitorProcess: String;
  out Reverter: IDeferredOperation
): TNtxStatus;
var
  hxKey: IHandle;
  Disposition: TRegDisposition;
  RestoreMonitorProcess, RestoreReportingMode: Boolean;
  OldMonitorProcess, OldReportingMode: TNtxRegValue;
begin
  // Create or open the application's silent process exit key
  Result := NtxCreateKey(
    hxKey,
    RtlxCombinePaths(WER_SILENT_PROCESS_EXIT_KEY, ImageName),
    KEY_QUERY_VALUE or KEY_SET_VALUE or _DELETE,
    REG_OPTION_VOLATILE,
    nil,
    '',
    0,
    @Disposition
  );

  if not Result.IsSuccess then
    Exit;

  if Disposition = REG_OPENED_EXISTING_KEY then
  begin
    // Backup the previous monitor process value
    Result := NtxQueryValueKey(hxKey, WER_SILENT_PROCESS_EXIT_MONITOR_PROCESS,
      OldMonitorProcess);

    RestoreReportingMode := Result.IsSuccess;

    if Result.Status = STATUS_OBJECT_NAME_NOT_FOUND then
      Result := NtxSuccess
    else if not Result.IsSuccess then
      Exit;

    // Backup the previous reporting mode value
    Result := NtxQueryValueKey(hxKey, WER_SILENT_PROCESS_EXIT_REPORTING_MODE,
      OldReportingMode);

    RestoreMonitorProcess := Result.IsSuccess;

    if Result.Status = STATUS_OBJECT_NAME_NOT_FOUND then
      Result := NtxSuccess
    else if not Result.IsSuccess then
      Exit;
  end;

  // Set the reporting mode
  Result := NtxSetValueKeyUInt32(hxKey, WER_SILENT_PROCESS_EXIT_REPORTING_MODE,
    1);

  if not Result.IsSuccess then
    Exit;

  // Set the monitor process
  Result := NtxSetValueKeyString(hxKey, WER_SILENT_PROCESS_EXIT_MONITOR_PROCESS,
    MonitorProcess);

  if not Result.IsSuccess then
    Exit;

  // Prepare an undo operation
  Reverter := Auto.Defer(
    procedure
    begin
      case Disposition of
        REG_CREATED_NEW_KEY:
          // Undo creation
          NtxDeleteKey(hxKey);

        REG_OPENED_EXISTING_KEY:
        begin
          // Undo monitor process modification
          if RestoreMonitorProcess then
            NtxSetValueKey(hxKey, WER_SILENT_PROCESS_EXIT_MONITOR_PROCESS,
              OldMonitorProcess.ValueType,
              OldMonitorProcess.Data.Data,
              OldMonitorProcess.Data.Size
            )
          else
            NtxDeleteValueKey(hxKey, WER_SILENT_PROCESS_EXIT_MONITOR_PROCESS);

          // Undo reporting mode modification
          if RestoreReportingMode then
            NtxSetValueKey(hxKey, WER_SILENT_PROCESS_EXIT_REPORTING_MODE,
              OldReportingMode.ValueType,
              OldReportingMode.Data.Data,
              OldReportingMode.Data.Size
            )
          else
            NtxDeleteValueKey(hxKey, WER_SILENT_PROCESS_EXIT_REPORTING_MODE);
        end;
      end;
    end
  );
end;

function WerxSetIFEOGlobalFlags(
  const ImageName: String;
  Value: TNtGlobalFlags;
  out Reverter: IDeferredOperation
): TNtxStatus;
var
  hxKey: IHandle;
  Disposition: TRegDisposition;
  RestoreGlobalFlags: Boolean;
  OldGlobalFlags: TNtxRegValue;
begin
  // Create or open the application's IFEO key
  Result := NtxCreateKey(
    hxKey,
    RtlxCombinePaths(WER_IFEO_KEY, ImageName),
    KEY_QUERY_VALUE or KEY_SET_VALUE or _DELETE,
    REG_OPTION_VOLATILE,
    nil,
    '',
    0,
    @Disposition
  );

  if not Result.IsSuccess then
    Exit;

  if Disposition = REG_OPENED_EXISTING_KEY then
  begin
    // Backup the previous monitor process value
    Result := NtxQueryValueKey(hxKey, WER_IFEO_GLOBAL_FLAGS, OldGlobalFlags);

    RestoreGlobalFlags := Result.IsSuccess;

    if Result.Status = STATUS_OBJECT_NAME_NOT_FOUND then
      Result := NtxSuccess
    else if not Result.IsSuccess then
      Exit;
  end;

  // Set the global flags
  Result := NtxSetValueKeyUInt32(hxKey, WER_IFEO_GLOBAL_FLAGS, Value);

  if not Result.IsSuccess then
    Exit;

  // Prepare an undo operation
  Reverter := Auto.Defer(
    procedure
    begin
      case Disposition of
        REG_CREATED_NEW_KEY:
          // Undo creation
          NtxDeleteKey(hxKey);

        REG_OPENED_EXISTING_KEY:
        begin
          // Undo global flags modification
          if RestoreGlobalFlags then
            NtxSetValueKey(hxKey, WER_IFEO_GLOBAL_FLAGS,
              OldGlobalFlags.ValueType,
              OldGlobalFlags.Data.Data,
              OldGlobalFlags.Data.Size
            )
          else
            NtxDeleteValueKey(hxKey, WER_IFEO_GLOBAL_FLAGS);
        end;
      end;
    end
  );
end;

function WerxExecuteSilentProcessExit;
var
  ImageName: String;
  SilentProcessExitKeyReverter: IDeferredOperation;
  IFEOGlobalFlagsReverter: IDeferredOperation;
  hxCrashReportingProcess: IHandle;
begin
  // We do get a handle for waiting on the worker WerFault process, but not the
  // target process info.
  Info := Default(TProcessInfo);
  ImageName := RtlxExtractNamePath(ParamStr(0));

  // Set the target command line as the silent process exit monitor process on
  // our own executable
  Result := WerxSetSilentProcessExitKey(ImageName, Options.CommandLine,
    SilentProcessExitKeyReverter);

  if not Result.IsSuccess then
    Exit;

  // Set the global flag in our IFEO to enable silent process exit monitoring
  Result := WerxSetIFEOGlobalFlags(ImageName, FLG_MONITOR_SILENT_PROCESS_EXIT,
    IFEOGlobalFlagsReverter);

  if not Result.IsSuccess then
    Exit;

  // Send a message to WER reporting silent process exit of our process
  if not (poRequireElevation in Options.Flags) then
    // Either via the silent process exit ALPC message
    Result := WerxReportSilentProcessExit(hxCrashReportingProcess,
      NtCurrentThreadId, NtCurrentProcessId, NtCurrentProcessId, STATUS_SUCCESS)
  else
    // Or via the elevated command ALPC message
    Result := WerxElevatedCommand(hxCrashReportingProcess,
      RtlxFormatString('-s -t %u -i %u -e %u -c %u', [
        TThreadId32(NtCurrentThreadId), TProcessId32(NtCurrentProcessId),
        TProcessId32(NtCurrentProcessId), NTSTATUS(STATUS_SUCCESS)
      ]));

  if not Result.IsSuccess then
    Exit;

  // The crash reporting process waits on the monitor process, meaning it can
  // take long to complete. We cannot wait on it indefinitely (if we don't want
  // to hang) but, unfortunately, we do need to wait at least a bit since we
  // don't want to remove the silent process exit trigger from the registry
  // before WerFault has a chance to read it.
  Result := NtxWaitForSingleObject(hxCrashReportingProcess, 1500 * MILLISEC);

  // Undo registry modifications
  IFEOGlobalFlagsReverter := nil;
  SilentProcessExitKeyReverter := nil;
end;

end.
