unit NtUtils.Processes.Create.Remote;

{
  The module provides support for process creation via injecting shellcode
  that calls CreateProcess in the context of the parent.
}

interface

uses
   Ntapi.ntpsapi, NtUtils, NtUtils.Processes.Create, NtUtils.Shellcode;

const
  PROCESS_CREATE_PROCESS_REMOTE = PROCESS_REMOTE_EXECUTE or PROCESS_VM_READ or
    PROCESS_DUP_HANDLE;

// Call CreateProcess in a context of another process
function AdvxCreateProcessRemote(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntobapi, Ntapi.ntstatus, Winapi.WinBase,
  Winapi.ProcessThreadsApi, DelphiUtils.AutoObject, NtUtils.Processes.Query,
  NtUtils.Processes.Memory, NtUtils.Threads, NtUtils.Objects;

type
  TProcessInformation64 = record
    hProcess: THandle;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}
    hThread: THandle;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}
    ProcessId: TProcessId32;
    ThreadId: TThreadId32;
  end;

  // The context for the function we are going to inject
  TCreateProcessContext = record
    CreateProcessW: function (
      ApplicationName: PWideChar;
      CommandLine: PWideChar;
      ProcessAttributes: PSecurityAttributes;
      ThreadAttributes: PSecurityAttributes;
      InheritHandles: LongBool;
      CreationFlags: TProcessCreateFlags;
      Environment: PEnvironment;
      CurrentDirectory: PWideChar;
      const StartupInfo: TStartupInfoW;
      out ProcessInformation: TProcessInformation
    ): LongBool; stdcall;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}

    RtlGetLastWin32Error: function: TWin32Error; stdcall;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}

    memset: function (
      dest: Pointer;
      c: Cardinal;
      count: NativeUInt
    ): Pointer; cdecl;
    {$IFDEF Win32}WoW64Padding3: Cardinal;{$ENDIF}

    CreationFlags: TProcessCreateFlags;
    InheritHandles: LongBool;
    Info: TProcessInformation64;
    CommandLine: TAnysizeArray<WideChar>;
  end;
  PCreateProcessContext = ^TCreateProcessContext;

// The function we are going to inject; keep in sync with assembly below
function ProcessCreator(Context: PCreateProcessContext): NTSTATUS; stdcall;
var
  SI: TStartupInfoW;
  PI: TProcessInformation;
begin
  Context.memset(@SI, 0, SizeOf(SI));
  SI.cb := SizeOf(SI);

  if Context.CreateProcessW(nil, PWideChar(@Context.CommandLine), nil, nil,
    Context.InheritHandles, Context.CreationFlags, nil, nil, SI, PI) then
  begin
    Context.Info.hProcess := PI.hProcess;
    Context.Info.hThread := PI.hThread;
    Context.Info.ProcessId := PI.ProcessId;
    Context.Info.ThreadId := PI.ThreadId;
    Result := STATUS_SUCCESS;
  end
  else
    Result := NTSTATUS_FROM_WIN32(Context.RtlGetLastWin32Error);
end;

var
  // The raw assembly for injection; keep in sync with the code above
  {$IFDEF Win64}
  ProcessCreatorAsm64: array[0 .. 259] of Byte = (
    $55, $48, $81, $EC, $E0, $00, $00, $00, $48, $8B, $EC, $48, $89, $8D, $F0,
    $00, $00, $00, $48, $8D, $4D, $70, $33, $D2, $41, $B8, $68, $00, $00, $00,
    $48, $8B, $85, $F0, $00, $00, $00, $FF, $50, $10, $C7, $45, $70, $68, $00,
    $00, $00, $33, $C9, $48, $8B, $85, $F0, $00, $00, $00, $48, $8D, $50, $38,
    $4D, $33, $C0, $4D, $33, $C9, $48, $8B, $85, $F0, $00, $00, $00, $8B, $40,
    $1C, $89, $44, $24, $20, $48, $8B, $85, $F0, $00, $00, $00, $8B, $40, $18,
    $89, $44, $24, $28, $48, $C7, $44, $24, $30, $00, $00, $00, $00, $48, $C7,
    $44, $24, $38, $00, $00, $00, $00, $48, $8D, $45, $70, $48, $89, $44, $24,
    $40, $48, $8D, $45, $58, $48, $89, $44, $24, $48, $48, $8B, $85, $F0, $00,
    $00, $00, $FF, $10, $85, $C0, $74, $44, $48, $8B, $85, $F0, $00, $00, $00,
    $48, $8B, $4D, $58, $48, $89, $48, $20, $48, $8B, $85, $F0, $00, $00, $00,
    $48, $8B, $4D, $60, $48, $89, $48, $28, $48, $8B, $85, $F0, $00, $00, $00,
    $8B, $4D, $68, $89, $48, $30, $48, $8B, $85, $F0, $00, $00, $00, $8B, $4D,
    $6C, $89, $48, $34, $C7, $85, $DC, $00, $00, $00, $00, $00, $00, $00, $EB,
    $22, $48, $8B, $85, $F0, $00, $00, $00, $FF, $50, $08, $89, $45, $54, $8B,
    $45, $54, $81, $E0, $FF, $FF, $00, $00, $81, $C8, $00, $00, $07, $C0, $89,
    $85, $DC, $00, $00, $00, $8B, $85, $DC, $00, $00, $00, $48, $8D, $A5, $E0,
    $00, $00, $00, $5D, $C3
  );
  {$ENDIF}

  ProcessCreatorAsm32: array[0 .. 154] of Byte = (
    $55, $8B, $EC, $83, $C4, $A4, $6A, $44, $6A, $00, $8D, $45, $B4, $50, $8B,
    $45, $08, $FF, $50, $10, $83, $C4, $0C, $C7, $45, $B4, $44, $00, $00, $00,
    $8D, $45, $A4, $50, $8D, $45, $B4, $50, $6A, $00, $6A, $00, $8B, $45, $08,
    $8B, $40, $18, $50, $8B, $45, $08, $8B, $40, $1C, $50, $6A, $00, $6A, $00,
    $8B, $45, $08, $83, $C0, $38, $50, $6A, $00, $8B, $45, $08, $FF, $10, $85,
    $C0, $74, $2B, $8B, $45, $08, $8B, $55, $A4, $89, $50, $20, $8B, $45, $08,
    $8B, $55, $A8, $89, $50, $28, $8B, $45, $08, $8B, $55, $AC, $89, $50, $30,
    $8B, $45, $08, $8B, $55, $B0, $89, $50, $34, $33, $C0, $89, $45, $FC, $EB,
    $19, $8B, $45, $08, $FF, $50, $08, $89, $45, $F8, $8B, $45, $F8, $25, $FF,
    $FF, $00, $00, $0D, $00, $00, $07, $C0, $89, $45, $FC, $8B, $45, $FC, $8B,
    $E5, $5D, $C2, $04, $00
  );

function GetCreationFlags(
  const Options: TCreateProcessOptions
): TProcessCreateFlags;
begin
  Result := 0;

  // Suspended state
  if poSuspended in Options.Flags then
    Result := Result or CREATE_SUSPENDED;

  // Job escaping
  if poBreakawayFromJob in Options.Flags then
    Result := Result or CREATE_BREAKAWAY_FROM_JOB;

  // Console
  if poNewConsole in Options.Flags then
    Result := Result or CREATE_NEW_CONSOLE;
end;

function AdvxCreateProcessRemote;
var
  IsWoW64: Boolean;
  Application, CommandLine: String;
  ntdllFunctions: TArray<Pointer>;
  LocalContext, RemoteContext: IMemory<PCreateProcessContext>;
  LocalCode: TMemory;
  RemoteCode: IMemory;
  hxThread: IHandle;
  ProcessInfo: TProcessInformation64;
begin
  // We need a target for injection
  if not Assigned(Options.Attributes.hxParentProcess) then
  begin
    Result.Location := 'AdvxRemoteCreateProcess';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(Options.Attributes.hxParentProcess.Handle,
    IsWoW64);

  if not Result.IsSuccess then
    Exit;

  PrepareCommandLine(Application, CommandLine, Options);

  // Prepare the local context
  IMemory(LocalContext) := TAutoMemory.Allocate(SizeOf(TCreateProcessContext) +
    Length(CommandLine) * SizeOf(WideChar));

  LocalContext.Data.CreationFlags := GetCreationFlags(Options);
  LocalContext.Data.InheritHandles := poInheritHandles in Options.Flags;

  Move(PWideChar(CommandLine)^, LocalContext.Data.CommandLine,
    Length(CommandLine) * SizeOf(WideChar));

  // Resolve kernel32 import for the shellcode
  Result := RtlxFindKnownDllExport(kernel32, IsWoW64, 'CreateProcessW',
    @LocalContext.Data.CreateProcessW);

  if not Result.IsSuccess then
    Exit;

  // Resolve ntdll import for the shellcode
  Result := RtlxFindKnownDllExports(ntdll, IsWoW64,
    ['RtlGetLastWin32Error', 'memset'], ntdllFunctions);

  if not Result.IsSuccess then
    Exit;

  LocalContext.Data.RtlGetLastWin32Error := ntdllFunctions[0];
  LocalContext.Data.memset := ntdllFunctions[1];

  // Prepare the correct version of the shellcode
  {$IFDEF Win64}
  if not IsWoW64 then
    LocalCode := TMemory.Reference(ProcessCreatorAsm64)
  else
  {$ENDIF}
    LocalCode := TMemory.Reference(ProcessCreatorAsm32);

  // Write the shellcode and its context
  Result := RtlxAllocWriteDataCodeProcess(Options.Attributes.hxParentProcess,
    LocalContext.Region, IMemory(RemoteContext), LocalCode, RemoteCode,
    IsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Create a thread to execute it
  Result := NtxCreateThread(hxThread, Options.Attributes.hxParentProcess.Handle,
    RemoteCode.Data, RemoteContext.Data);

  if not Result.IsSuccess then
    Exit;

  // Wait for completion
  Result := RtlxSyncThread(hxThread.Handle, 'Remote::CreateProcessW',
    DEFAULT_REMOTE_TIMEOUT, [RemoteCode, IMemory(RemoteContext)]);

  if not Result.IsSuccess then
    Exit;

  // Read the information about the new process
  Result := NtxMemory.Read(Options.Attributes.hxParentProcess.Handle,
    @RemoteContext.Data.Info, ProcessInfo);

  if not Result.IsSuccess then
    Exit;

  // Copy the process information
  Info.ClientId.UniqueProcess := ProcessInfo.ProcessId;
  Info.ClientId.UniqueThread := ProcessInfo.ThreadId;

  // Move the process handle
  Result := NtxDuplicateHandleFrom(Options.Attributes.hxParentProcess.Handle,
    ProcessInfo.hProcess, Info.hxProcess, DUPLICATE_SAME_ACCESS or
    DUPLICATE_CLOSE_SOURCE);

  if not Result.IsSuccess then
    Exit;

  // Move the thread handle
  Result := NtxDuplicateHandleFrom(Options.Attributes.hxParentProcess.Handle,
    ProcessInfo.hThread, Info.hxThread, DUPLICATE_SAME_ACCESS or
    DUPLICATE_CLOSE_SOURCE);
end;

end.
