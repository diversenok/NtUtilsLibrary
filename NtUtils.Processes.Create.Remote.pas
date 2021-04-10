unit NtUtils.Processes.Create.Remote;

{
  The module provides support for process creation via injecting shellcode
  that calls CreateProcess in the context of the parent process.
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
    CommandLine: PWideChar;
    {$IFDEF Win32}WoW64Padding4: Cardinal;{$ENDIF}
    Desktop: PWideChar;
    {$IFDEF Win32}WoW64Padding5: Cardinal;{$ENDIF}
    CurrentDirectory: PWideChar;
    {$IFDEF Win32}WoW64Padding6: Cardinal;{$ENDIF}
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
  SI.Desktop := Context.Desktop;

  if Context.CreateProcessW(nil, Context.CommandLine, nil, nil,
    Context.InheritHandles, Context.CreationFlags, nil,
    Context.CurrentDirectory, SI, PI) then
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
  ProcessCreatorAsm64: array[0..169] of Byte = (
    $55, $53, $48, $81, $EC, $D8, $00, $00, $00, $48, $8B, $EC, $48, $89, $CB,
    $48, $8D, $4D, $68, $33, $D2, $41, $B8, $68, $00, $00, $00, $FF, $53, $10,
    $C7, $45, $68, $68, $00, $00, $00, $48, $8B, $43, $40, $48, $89, $45, $78,
    $33, $C9, $48, $8B, $53, $38, $4D, $33, $C0, $4D, $33, $C9, $8B, $43, $1C,
    $89, $44, $24, $20, $8B, $43, $18, $89, $44, $24, $28, $48, $C7, $44, $24,
    $30, $00, $00, $00, $00, $48, $8B, $43, $48, $48, $89, $44, $24, $38, $48,
    $8D, $45, $68, $48, $89, $44, $24, $40, $48, $8D, $45, $50, $48, $89, $44,
    $24, $48, $FF, $13, $85, $C0, $74, $20, $48, $8B, $45, $50, $48, $89, $43,
    $20, $48, $8B, $45, $58, $48, $89, $43, $28, $8B, $45, $60, $89, $43, $30,
    $8B, $45, $64, $89, $43, $34, $33, $C0, $EB, $0F, $FF, $53, $08, $81, $E0,
    $FF, $FF, $00, $00, $81, $C8, $00, $00, $07, $C0, $48, $8D, $A5, $D8, $00,
    $00, $00, $5B, $5D, $C3
  );
  {$ENDIF}

  ProcessCreatorAsm32: array[0 .. 122] of Byte = (
    $55, $8B, $EC, $83, $C4, $AC, $53, $8B, $5D, $08, $6A, $44, $6A, $00, $8D,
    $45, $BC, $50, $FF, $53, $10, $83, $C4, $0C, $C7, $45, $BC, $44, $00, $00,
    $00, $8B, $43, $40, $89, $45, $C4, $8D, $45, $AC, $50, $8D, $45, $BC, $50,
    $8B, $43, $48, $50, $6A, $00, $8B, $43, $18, $50, $8B, $43, $1C, $50, $6A,
    $00, $6A, $00, $8B, $43, $38, $50, $6A, $00, $FF, $13, $85, $C0, $74, $1C,
    $8B, $45, $AC, $89, $43, $20, $8B, $45, $B0, $89, $43, $28, $8B, $45, $B4,
    $89, $43, $30, $8B, $45, $B8, $89, $43, $34, $33, $C0, $EB, $0D, $FF, $53,
    $08, $25, $FF, $FF, $00, $00, $0D, $00, $00, $07, $C0, $5B, $8B, $E5, $5D,
    $C2, $04, $00
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
    Result.Location := 'AdvxCreateProcessRemote';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(Options.Attributes.hxParentProcess.Handle,
    IsWoW64);

  if not Result.IsSuccess then
    Exit;

  PrepareCommandLine(Application, CommandLine, Options);

  // Allocate the local context
  IMemory(LocalContext) := TAutoMemory.Allocate(
    SizeOf(TCreateProcessContext) +
    Succ(Length(CommandLine)) * SizeOf(WideChar) +
    Succ(Length(Options.Desktop)) * SizeOf(WideChar) +
    Succ(Length(Options.CurrentDirectory)) * SizeOf(WideChar)
  );

  LocalContext.Data.CreationFlags := GetCreationFlags(Options);
  LocalContext.Data.InheritHandles := poInheritHandles in Options.Flags;

  // Marshal command line
  Move(PWideChar(CommandLine)^, LocalContext.Offset(
      SizeOf(TCreateProcessContext)
    )^, Length(CommandLine) * SizeOf(WideChar));

  // Marshal desktop
  Move(PWideChar(Options.Desktop)^, LocalContext.Offset(
      SizeOf(TCreateProcessContext) +
      Succ(Length(CommandLine)) * SizeOf(WideChar)
    )^, Length(Options.Desktop) * SizeOf(WideChar)
  );

  // Marshal current directory
  Move(PWideChar(Options.CurrentDirectory)^, LocalContext.Offset(
      SizeOf(TCreateProcessContext) +
      Succ(Length(CommandLine)) * SizeOf(WideChar) +
      Succ(Length(Options.Desktop)) * SizeOf(WideChar)
    )^, Length(Options.CurrentDirectory) * SizeOf(WideChar)
  );

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

  // Allocate memory for the remote context
  Result := NtxAllocateMemoryProcess(Options.Attributes.hxParentProcess,
    LocalContext.Size, IMemory(RemoteContext), IsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Adjust the command-line pointer
  LocalContext.Data.CommandLine := RemoteContext.Offset(
    SizeOf(TCreateProcessContext)
  );

  // Adjust the desktop pointer
  if Options.Desktop <> '' then
    LocalContext.Data.Desktop := RemoteContext.Offset(
      SizeOf(TCreateProcessContext) +
      Succ(Length(CommandLine)) * SizeOf(WideChar)
    );

  // Adjust the current directory
  if Options.CurrentDirectory <> '' then
    LocalContext.Data.CurrentDirectory := RemoteContext.Offset(
      SizeOf(TCreateProcessContext) +
      Succ(Length(CommandLine)) * SizeOf(WideChar) +
      Succ(Length(Options.Desktop)) * SizeOf(WideChar)
    );

  // Write the context
  Result := NtxWriteMemoryProcess(Options.Attributes.hxParentProcess.Handle,
    RemoteContext.Data, LocalContext.Region);

  if not Result.IsSuccess then
    Exit;

  // Pick the correct version of the shellcode
  {$IFDEF Win64}
  if not IsWoW64 then
    LocalCode := TMemory.Reference(ProcessCreatorAsm64)
  else
  {$ENDIF}
    LocalCode := TMemory.Reference(ProcessCreatorAsm32);

  // Allocate and write shellcode
  Result := NtxAllocWriteExecMemoryProcess(Options.Attributes.hxParentProcess,
    LocalCode, RemoteCode, IsWoW64);

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
