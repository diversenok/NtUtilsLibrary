unit Ntapi.werscv;

{
  This unit provides definitions for communicating with the Windows Error
  Reporting service.
}

interface

uses
   Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntlpcapi, DelphiApi.Reflection;

{$MINENUMSIZE 4}

const
  // rev
  WERSVC_EVENT_NAME = '\KernelObjects\SystemErrorPortReady';
  WERSVC_PORT_NAME = '\WindowsErrorReportingServicePort';

  // rev - WER ALPC message IDs
  WERSVC_MSG_SILENT_PROCESS_EXIT_REQUEST = $30000000;
  WERSVC_MSG_SILENT_PROCESS_EXIT_REPLY = $30000001;
  WERSVC_MSG_SILENT_PROCESS_EXIT_ERROR = $30000002;
  WERSVC_MSG_ELEVATED_PROC_INFO_REQUEST = $50000000;
  WERSVC_MSG_ELEVATED_PROC_INFO_REPLY = $50000001;
  WERSVC_MSG_ELEVATED_PROC_INFO_ERROR = $50000002;
  WERSVC_MSG_NONELEVATED_PROC_INFO_REQUEST = $90000000;
  WERSVC_MSG_NONELEVATED_PROC_INFO_REPLY = $90000001;
  WERSVC_MSG_NONELEVATED_PROC_INFO_ERROR = $90000002;

  // rev - WER elevated process info command
  WERSVC_ELEVATED_PROC_INFO_START = 1;

type
  [SubEnum(MAX_UINT, WERSVC_MSG_SILENT_PROCESS_EXIT_REQUEST, 'Silent Process Exit')]
  [SubEnum(MAX_UINT, WERSVC_MSG_SILENT_PROCESS_EXIT_REPLY, 'Silent Process Exit Reply')]
  [SubEnum(MAX_UINT, WERSVC_MSG_SILENT_PROCESS_EXIT_ERROR, 'Silent Process Exit Error')]
  [SubEnum(MAX_UINT, WERSVC_MSG_ELEVATED_PROC_INFO_REQUEST, 'Elevated Proc Info Request')]
  [SubEnum(MAX_UINT, WERSVC_MSG_ELEVATED_PROC_INFO_REPLY, 'Elevated Proc Info Reply')]
  [SubEnum(MAX_UINT, WERSVC_MSG_ELEVATED_PROC_INFO_ERROR, 'Elevated Proc Info Error')]
  [SubEnum(MAX_UINT, WERSVC_MSG_NONELEVATED_PROC_INFO_REQUEST, 'Non-elevated Proc Info Request')]
  [SubEnum(MAX_UINT, WERSVC_MSG_NONELEVATED_PROC_INFO_REPLY, 'Non-elevated Proc Info Reply')]
  [SubEnum(MAX_UINT, WERSVC_MSG_NONELEVATED_PROC_INFO_ERROR, 'Non-elevated Proc Info Error')]
  TWerSvcMessageId = type Cardinal;

  // private
  [SDKName('NON_ELEVATED_PROC_LAUNCHTYPE')]
  TNonElevatedProcLaunchType = (
    NonElevatedProcLaunchTypeCreateProcess = 0,
    NonElevatedProcLaunchTypeOpen = 1,
    NonElevatedProcLaunchTypeExplore = 2,
    NonElevatedProcLaunchTypeHelpTopic = 3
  );

  TNonElevatedProcDataCmd = array [0..519] of WideChar;

  // private
  [SDKName('NON_ELEVATED_PROC_DATA')]
  TNonElevatedProcData = record
    [RecordSize] Size: Cardinal;
    LaunchType: TNonElevatedProcLaunchType;
    ExePath: TMaxPathWideCharArray;
    Cmd: TNonElevatedProcDataCmd
  end;
  PNonElevatedProcData = ^TNonElevatedProcData;

  // Extracted from TWerSvcMsg
  TWerSvcSilentProcessExitInfo = record
    InitiatingThreadId: TThreadId32;
    InitiatingProcessId: TProcessId32;
    ExitingProcessId: TProcessId32;
    ExitStatus: NTSTATUS;
  end;

  // Extracted from TWerSvcMsg
  TWerSvcNonElevatedProcInfo = record
    hSharedMem: UInt64; // THandle
    hNonElevatedProcess: UInt64; // THandle
  end;

  TWerSvcElevatedProcInfoHandles = array [0..15] of UInt64; // of THandle

  // Extracted from TWerSvcMsg
  TWerSvcElevatedProcInfo = record
    [Reserved(WERSVC_ELEVATED_PROC_INFO_START)] ProcId: Cardinal;
    hSharedMem: UInt64;
    arrHandlesToInherit: TWerSvcElevatedProcInfoHandles;
    [NumberOfElements] dwHandlesToInherit: Cardinal;
    [out] hElevatedProcess: UInt64; // THandle
  end;

  // private
  [SDKName('WERSVC_MSG')]
  TWerSvcMsg = record
    hdr: TPortMessage;
    MsgId: TWerSvcMessageId;
    Status: HResult;
  case TWerSvcMessageId of
    WERSVC_MSG_SILENT_PROCESS_EXIT_REQUEST: (
      SilentProcessExitInfo: TWerSvcSilentProcessExitInfo;
    );

    WERSVC_MSG_SILENT_PROCESS_EXIT_REPLY: (
      hCrashReportingProcess: UInt64; // THandle
    );

    WERSVC_MSG_ELEVATED_PROC_INFO_REQUEST,
    WERSVC_MSG_ELEVATED_PROC_INFO_REPLY: (
      ElevatedProcInfo: TWerSvcElevatedProcInfo;
    );

    $9 {WERSVC_MSG_NONELEVATED_PROC_INFO_REQUEST}: (
      NonElevatedProcInfo: TWerSvcNonElevatedProcInfo;
    );

    0: (
      Reserved: array [0..336] of Cardinal;
    );
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
