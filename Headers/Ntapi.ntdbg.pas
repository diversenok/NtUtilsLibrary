unit Ntapi.ntdbg;

{
  This file includes definitions for debugging via Native API.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

const
  // PHNT::ntdbg.h - debug object access masks
  DEBUG_READ_EVENT = $0001;
  DEBUG_PROCESS_ASSIGN = $0002;
  DEBUG_SET_INFORMATION = $0004;
  DEBUG_QUERY_INFORMATION = $0008;
  DEBUG_ALL_ACCESS = STANDARD_RIGHTS_ALL or $000F;

  // PHNT::ntdbg.h - creation flag
  DEBUG_KILL_ON_CLOSE = $1;

type
  [FriendlyName('debug object'), ValidBits(DEBUG_ALL_ACCESS), IgnoreUnnamed]
  [FlagName(DEBUG_READ_EVENT, 'Read Events')]
  [FlagName(DEBUG_PROCESS_ASSIGN, 'Assign Process')]
  [FlagName(DEBUG_SET_INFORMATION, 'Set Information')]
  [FlagName(DEBUG_QUERY_INFORMATION, 'Query Information')]
  TDebugObjectAccessMask = type TAccessMask;

  [FlagName(DEBUG_KILL_ON_CLOSE, 'Kill-On-Close')]
  TDebugCreateFlags = type Cardinal;

  // PHNT::ntdbg.h
  [SDKName('DBGKM_EXCEPTION')]
  TDbgKmException = record
    ExceptionRecord: TExceptionRecord;
    FirstChance: LongBool;
  end;
  PDbgKmException = ^TDbgKmException;

  // PHNT::ntdbg.h
  [SDKName('DBGKM_CREATE_THREAD')]
  TDbgKmCreateThread = record
    SubsystemKey: Cardinal;
    StartAddress: Pointer;
  end;
  PDbgKmCreateThread = ^TDbgKmCreateThread;

  // PHNT::ntdbg.h
  [SDKName('DBGKM_CREATE_PROCESS')]
  TDbgKmCreateProcess = record
    SubsystemKey: Cardinal;
    FileHandle: THandle;
    BaseOfImage: Pointer;
    [Hex] DebugInfoFileOffset: Cardinal;
    [Bytes] DebugInfoSize: Cardinal;
    InitialThread: TDbgKmCreateThread;
  end;
  PDbgKmCreateProcess = ^TDbgKmCreateProcess;

  // PHNT::ntdbg.h
  [SDKName('DBGKM_LOAD_DLL')]
  TDbgKmLoadDll = record
    FileHandle: THandle;
    BaseOfDll: Pointer;
    [Hex] DebugInfoFileOffset: Cardinal;
    [Bytes] DebugInfoSize: Cardinal;
    NamePointer: Pointer;
  end;
  PDbgKmLoadDll = ^TDbgKmLoadDll;

  // PHNT::ntdbg.h
  [SDKName('DBG_STATE')]
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

  // PHNT::ntdbg.h
  [SDKName('DBGUI_CREATE_THREAD')]
  TDbgUiCreateThread = record
    HandleToThread: THandle;
    NewThread: TDbgKmCreateThread;
  end;
  PDbgUiCreateThread = ^TDbgUiCreateThread;

  // PHNT::ntdbg.h
  [SDKName('DBGUI_CREATE_PROCESS')]
  TDbgUiCreateProcess = record
    HandleToProcess: THandle;
    HandleToThread: THandle;
    NewProcess: TDbgKmCreateProcess;
  end;
  PDbgUiCreateProcess = ^TDbgUiCreateProcess;

  // PHNT::ntdbg.h
  [SDKName('DBGKM_EXIT_THREAD')]
  TDgbKmExitThread = record
    ExitStatus: NTSTATUS;
  end;
  PDgbKmExitThread = ^TDgbKmExitThread;
  TDgbKmExitProcess = TDgbKmExitThread;
  PDgbKmExitProcess = ^TDgbKmExitProcess;

  // PHNT::ntdbg.h
  [SDKName('DBGKM_UNLOAD_DLL')]
  TDbgKmUnloadDll = record
    BaseAddress: Pointer;
  end;
  PDbgKmUnloadDll = ^TDbgKmUnloadDll;

  // PHNT::ntdbg.h
  [SDKName('DBGUI_WAIT_STATE_CHANGE')]
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

  // PHNT::ntdbg.h
  [SDKName('DEBUGOBJECTINFOCLASS')]
  [NamingStyle(nsCamelCase, 'DebugObject'), Range(1)]
  TDebugObjectInfoClass = (
    DebugObjectUnusedInformation = 0,
    DebugObjectKillProcessOnExitInformation = 1 // s: LongBool
  );

// PHNT::ntdbg.h
function NtCreateDebugObject(
  [out, ReleaseWith('NtClose')] out DebugObjectHandle: THandle;
  [in] DesiredAccess: TDebugObjectAccessMask;
  [in, opt] ObjectAttributes: PObjectAttributes;
  [in] Flags: TDebugCreateFlags
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntdbg.h
function NtDebugActiveProcess(
  [in, Access(PROCESS_SUSPEND_RESUME)] ProcessHandle: THandle;
  [in, Access(DEBUG_PROCESS_ASSIGN)] DebugObjectHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntdbg.h
function NtDebugContinue(
  [in, Access(DEBUG_READ_EVENT)] DebugObjectHandle: THandle;
  [in] const ClientId: TClientId;
  [in] ContinueStatus: NTSTATUS
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntdbg.h
function NtRemoveProcessDebug(
  [in, Access(PROCESS_SUSPEND_RESUME)] ProcessHandle: THandle;
  [in, Access(DEBUG_PROCESS_ASSIGN)] DebugObjectHandle: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntdbg.h
function NtSetInformationDebugObject(
  [in, Access(DEBUG_SET_INFORMATION)] DebugObjectHandle: THandle;
  [in] DebugObjectInformationClass: TDebugObjectInfoClass;
  [in, ReadsFrom] DebugInformation: Pointer;
  [in, NumberOfBytes] DebugInformationLength: Cardinal;
  [out, opt] ReturnLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// Debug UI

// PHNT::ntdbg.h
function DbgUiConnectToDbg(
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntdbg.h
function NtWaitForDebugEvent(
  [in, Access(DEBUG_READ_EVENT)] DebugObjectHandle: THandle;
  [in] Alertable: Boolean;
  [in, opt] Timeout: PLargeInteger;
  [out] out WaitStateChange: TDbgUiWaitStateChange
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntdbg.h
function DbgUiGetThreadDebugObject(
): THandle; stdcall; external ntdll;

// PHNT::ntdbg.h
procedure DbgUiSetThreadDebugObject(
  [in] DebugObject: THandle
); stdcall; external ntdll;

// PHNT::ntdbg.h
function DbgUiDebugActiveProcess(
  [in, Access(PROCESS_SUSPEND_RESUME or PROCESS_CREATE_THREAD)] Process: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntdbg.h
procedure DbgUiRemoteBreakin(
  [in, opt] Context: Pointer
); stdcall; external ntdll;

// PHNT::ntdbg.h
function DbgUiIssueRemoteBreakin(
  [in, Access(PROCESS_CREATE_THREAD)] Process: THandle
): NTSTATUS; stdcall; external ntdll;

// Local debugging

// WDK::wdm.h
procedure DbgBreakPoint(
); stdcall; external ntdll;

// WDK::wdm.h
function DbgPrint(
  [in] Format: PAnsiChar
): NTSTATUS; cdecl; varargs; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
