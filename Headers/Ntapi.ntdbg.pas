unit Ntapi.ntdbg;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

const
  DEBUG_READ_EVENT = $0001;
  DEBUG_PROCESS_ASSIGN = $0002;
  DEBUG_SET_INFORMATION = $0004;
  DEBUG_QUERY_INFORMATION = $0008;
  DEBUG_ALL_ACCESS = STANDARD_RIGHTS_ALL or $000F;

  DebugObjAccessMapping: array [0..3] of TFlagNameRef = (
    (Value: DEBUG_READ_EVENT;        Name: 'Read event'),
    (Value: DEBUG_PROCESS_ASSIGN;    Name: 'Assign process'),
    (Value: DEBUG_SET_INFORMATION;   Name: 'Set information'),
    (Value: DEBUG_QUERY_INFORMATION; Name: 'Query information')
  );

  DebugObjAccessType: TAccessMaskType = (
    TypeName: 'debug object';
    FullAccess: DEBUG_ALL_ACCESS;
    Count: Length(DebugObjAccessMapping);
    Mapping: PFlagNameRefs(@DebugObjAccessMapping);
  );

  // Creation flag
  DEBUG_KILL_ON_CLOSE = $1;

type
  TDbgKmException = record
    ExceptionRecord: TExceptionRecord;
    FirstChance: LongBool;
  end;
  PDbgKmException = ^TDbgKmException;

  TDbgKmCreateThread = record
    SubsystemKey: Cardinal;
    StartAddress: Pointer;
  end;
  PDbgKmCreateThread = ^TDbgKmCreateThread;

  TDbgKmCreateProcess = record
    SubsystemKey: Cardinal;
    FileHandle: THandle;
    BaseOfImage: Pointer;
    [Hex] DebugInfoFileOffset: Cardinal;
    [Bytes] DebugInfoSize: Cardinal;
    InitialThread: TDbgKmCreateThread;
  end;
  PDbgKmCreateProcess = ^TDbgKmCreateProcess;

  TDbgKmLoadDll = record
    FileHandle: THandle;
    BaseOfDll: Pointer;
    [Hex] DebugInfoFileOffset: Cardinal;
    [Bytes] DebugInfoSize: Cardinal;
    NamePointer: Pointer;
  end;
  PDbgKmLoadDll = ^TDbgKmLoadDll;

  [NamingStyle(nsCamelCase, 'Dbg', 'StateChange')]
  TDbgState = (
    DbgIdle = 0,
    DbgReplyPending = 1,
    DbgCreateThreadStateChange = 2,
    DbgCreateProcessStateChange = 3,
    DbgExitThreadStateChange = 4,
    DbgExitProcessStateChange = 5,
    DbgExceptionStateChange = 6,
    DbgBreakpointStateChange = 7,
    DbgSingleStepStateChange = 8,
    DbgLoadDllStateChange = 9,
    DbgUnloadDllStateChange = 10
  );

  TDbgUiCreateThread = record
    HandleToThread: THandle;
    NewThread: TDbgKmCreateThread;
  end;
  PDbgUiCreateThread = ^TDbgUiCreateThread;

  TDbgUiCreateProcess = record
    HandleToProcess: THandle;
    HandleToThread: THandle;
    NewProcess: TDbgKmCreateProcess;
  end;
  PDbgUiCreateProcess = ^TDbgUiCreateProcess;

  TDgbKmExitThread = record
    ExitStatus: NTSTATUS;
  end;
  PDgbKmExitThread = ^TDgbKmExitThread;
  TDgbKmExitProcess = TDgbKmExitThread;
  PDgbKmExitProcess = ^TDgbKmExitProcess;

  TDbgKmUnloadDll = record
    BaseAddress: Pointer;
  end;
  PDbgKmUnloadDll = ^TDbgKmUnloadDll;

  TDbgUiWaitStateChange = record
    NewState: TDbgState;
    AppClientId: TClientId;
  case Integer of
    0: (Exception: TDbgKmException);
    1: (CreateThread: TDbgUiCreateThread);
    2: (CreateProcessInfo: TDbgUiCreateProcess);
    3: (ExitThread: TDgbKmExitThread);
    4: (ExitProcess: TDgbKmExitProcess);
    5: (LoadDll: TDbgKmLoadDll);
    6: (UnloadDll: TDbgKmUnloadDll);
  end;
  PDbgUiWaitStateChange = ^TDbgUiWaitStateChange;

  [NamingStyle(nsCamelCase, 'DebugObject'), Range(1)]
  TDebugObjectInfoClass = (
    DebugObjectUnusedInformation = 0,
    DebugObjectKillProcessOnExitInformation = 1
  );

function NtCreateDebugObject(out DebugObjectHandle: THandle;
  DesiredAccess: TAccessMask; const ObjectAttributes: TObjectAttributes;
  Flags: Cardinal): NTSTATUS; stdcall; external ntdll;

function NtDebugActiveProcess(ProcessHandle: THandle;
  DebugObjectHandle: THandle): NTSTATUS; stdcall; external ntdll;

function NtDebugContinue(DebugObjectHandle: THandle; const ClientId: TClientId;
  ContinueStatus: NTSTATUS): NTSTATUS; stdcall; external ntdll;

function NtRemoveProcessDebug(ProcessHandle: THandle;
  DebugObjectHandle: THandle): NTSTATUS; stdcall; external ntdll;

function NtSetInformationDebugObject(DebugObjectHandle: THandle;
  DebugObjectInformationClass: TDebugObjectInfoClass; DebugInformation: Pointer;
  DebugInformationLength: Cardinal; ReturnLength: PCardinal): NTSTATUS; stdcall;
  external ntdll;

// Debug UI

function DbgUiConnectToDbg: NTSTATUS; stdcall; external ntdll;

function NtWaitForDebugEvent(DebugObjectHandle: THandle; Alertable: Boolean;
  Timeout: PLargeInteger; out WaitStateChange: TDbgUiWaitStateChange): NTSTATUS;
  stdcall; external ntdll;

function DbgUiGetThreadDebugObject: THandle; stdcall; external ntdll;

procedure DbgUiSetThreadDebugObject(DebugObject: THandle); stdcall;
  external ntdll;

function DbgUiDebugActiveProcess(Process: THandle): NTSTATUS; stdcall;
  external ntdll;

procedure DbgUiRemoteBreakin(Context: Pointer); stdcall; external ntdll;

function DbgUiIssueRemoteBreakin(Process: THandle): NTSTATUS; stdcall;
  external ntdll;

// Local debugging

// wdm.21907
procedure DbgBreakPoint; stdcall; external ntdll;

// wdm.12963
function DbgPrint(Format: PAnsiChar): NTSTATUS; cdecl; varargs; external ntdll;

procedure DbgBreakOnFailure(Status: NTSTATUS);

implementation

uses
  Ntapi.ntpebteb;

procedure DbgBreakOnFailure(Status: NTSTATUS);
begin
  if not NT_SUCCESS(Status) and RtlGetCurrentPeb.BeingDebugged then
    DbgBreakPoint;
end;

end.
