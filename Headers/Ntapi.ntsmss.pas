unit Ntapi.ntsmss;

{
  This module defines types for interacting with SMSS and CSRSS session ports.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntlpcapi, Ntapi.ImageHlp,
  DelphiApi.Reflection;

{$MINENUMSIZE 4}

const
  // PHNT::ntsmss.h - SB process creation flags
  SMP_DEBUG_FLAG = $00000001;
  SMP_ASYNC_FLAG = $00000002;
  SMP_DONT_START = $00000004;

type
  // PHNT::ntsmss.h
  [SDKName('SMAPINUMBER')]
  [NamingStyle(nsCamelCase, 'Sm', 'Api'), ValidBits([1, 3..7])]
  TSmApiNumber = (
    [Reserved] SmNotImplementedApi = 0,
    SmSessionCompleteApi = 1,
    [Reserved] SmNotImplemented2Api = 2,
    SmExecPgmApi = 3,
    SmLoadDeferedSubsystemApi = 4,
    SmStartCsrApi = 5,
    SmStopCsrApi = 6,
    SmStartServerSiloApi = 7
  );

  // PHNT::ntsmss.h
  [SDKName('SMSESSIONCOMPLETE')]
  TSmSessionComplete = record
    [in] SessionId: TSessionId;
    [in] CompletionStatus: NTSTATUS;
  end;
  PSmSessionComplete = ^TSmSessionComplete;

  // PHNT::ntsmss.h
  [SDKName('SMEXECPGM')]
  TSmExecPgm = record
    [in] ProcessInformation: TRtlUserProcessInformation;
    [in] DebugFlag: Boolean;
  end;
  PSmExecPgm = ^TSmExecPgm;

  // PHNT::ntsmss.h
  [SDKName('SMLOADDEFERED')]
  TSmLoadDefered = record
    [in, NumberOfBytes] SubsystemNameLength: Cardinal;
    [in] SubsystemName: array [0..31] of WideChar;
  end;
  PSmLoadDefered = ^TSmLoadDefered;

  // PHNT::ntsmss.h
  [SDKName('SMSTARTCSR')]
  TSmStartCsr = record
    [in, out] MuSessionId: TSessionId;
    [in, NumberOfBytes] InitialCommandLength: Cardinal;
    [in] InitialCommand: array [0..127] of WideChar;
    [out] InitialCommandProcessId: TProcessId;
    [out] WindowsSubSysProcessId: TProcessId;
  end;
  PSmStartCsr = ^TSmStartCsr;

  // PHNT::ntsmss.h
  [SDKName('SMSTOPCSR')]
  TSmStopCsr = record
    [in] MuSessionId: TSessionId;
  end;
  PSmStopCsr = ^TSmStopCsr;

  // PHNT::ntsmss.h
  [SDKName('SMSTARTSERVERSILO')]
  TSmStartServerSilo = record
    [in] JobHandle: THandle;
    [in] CreateSuspended: Boolean;
  end;
  PSmStartServerSilo = ^TSmStartServerSilo;

  // PHNT::ntsmss.h
  [SDKName('SMAPIMSG')]
  TSmApiMsg = record
    [in] h: TPortMessage;
    [in] ApiNumber: TSmApiNumber;
    [out] ReturnedStatus: NTSTATUS;
  case TSmApiNumber of
    SmSessionCompleteApi: (SessionComplete: TSmSessionComplete);
    SmExecPgmApi: (ExecPgm: TSmExecPgm);
    SmLoadDeferedSubsystemApi: (LoadDefered: TSmLoadDefered);
    SmStartCsrApi: (StartCsr: TSmStartCsr);
    SmStopCsrApi: (StopCsr: TSmStopCsr);
    SmStartServerSiloApi: (StartServerSilo: TSmStartServerSilo);
  end;
  PSmApiMsg = ^TSmApiMsg;

  // PHNT::ntsmss.h
  [SDKName('SBAPINUMBER')]
  [NamingStyle(nsCamelCase, 'Sb', 'Api')]
  TSbApiNumber = (
    SbCreateSessionApi = 0,
    SbTerminateSessionApi = 1,
    SbForeignSessionCompleteApi = 2,
    SbCreateProcessApi = 3
  );

  // PHNT::ntsmss.h
  [SDKName('SBCREATESESSION')]
  TSbCreateSession = record
    [in] SessionId: TSessionId;
    [in] ProcessInformation: TRtlUserProcessInformation;
    [in, opt] UserProfile: Pointer;
    [in] DebugSession: LongBool;
    [in] DebugUiClientId: TClientId;
  end;
  PSbCreateSession = ^TSbCreateSession;

  [FlagName(SMP_DEBUG_FLAG, 'Debug')]
  [FlagName(SMP_ASYNC_FLAG, 'Async')]
  [FlagName(SMP_DONT_START, 'Don''t Start')]
  TSbCreateProcessInFlags = type Cardinal;

  // PHNT::ntsmss.h
  [SDKName('SBCREATEPROCESSIN')]
  TSbCreateProcessIn = record
    ImageFileName: PNtUnicodeString;
    CurrentDirectory: PNtUnicodeString;
    CommandLine: PNtUnicodeString;
    DefaultLibPath: PNtUnicodeString;
    Flags: TSbCreateProcessInFlags;
    DefaultDebugFlags: TRtlUserProcessParametersDebugFlags;
  end;

  // PHNT::ntsmss.h
  [SDKName('SBCREATEPROCESSOUT')]
  TSbCreateProcessOut = record
    Process: THandle;
    Thread: THandle;
    SubSystemType: TImageSubsystem;
    ClientId: TClientId;
  end;

  // PHNT::ntsmss.h
  [SDKName('SBCREATEPROCESS')]
  TSbCreateProcess = record
  case Integer of
    0: (i: TSbCreateProcessIn);
    1: (o: TSbCreateProcessOut)
  end;
  PSbCreateProcess = ^TSbCreateProcess;

  // PHNT::ntsmss.h
  [SDKName('SBAPIMSG')]
  TSbApiMsg = record
    h: TPortMessage;
    ApiNumber: TSbApiNumber;
    ReturnedStatus: NTSTATUS;
  case TSbApiNumber of
    SbCreateSessionApi: (CreateSession: TSbCreateSession);
    SbCreateProcessApi: (CreateProcessA: TSbCreateProcess);
  end;
  PSbApiMsg = ^TSbApiMsg;

// PHNT::ntsmss.h
function RtlConnectToSm(
  [in, opt] ApiPortName: PNtUnicodeString;
  [in, opt] ApiPortHandle: THandle;
  [in] ProcessImageType: Cardinal;
  [out, ReleaseWith('NtClose')] out SmssConnection: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntsmss.h
function RtlSendMsgToSm(
  [in] ApiPortHandle: THandle;
  [in] const MessageData: TPortMessage
): NTSTATUS; stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
