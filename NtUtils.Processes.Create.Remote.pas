unit NtUtils.Processes.Create.Remote;

{
  The module provides support for process creation via injecting shellcode
  that calls CreateProcess in the context of the parent process.
}

interface

uses
   Ntapi.ntpsapi, NtUtils, NtUtils.Processes.Create, NtUtils.Shellcode;

const
  // Required access on the parent
  PROCESS_CREATE_PROCESS_REMOTE = PROCESS_REMOTE_EXECUTE or PROCESS_DUP_HANDLE;

// Call CreateProcess in a context of another process
[SupportedOption(spoSuspended)]
[SupportedOption(spoInheritHandles)]
[SupportedOption(spoBreakawayFromJob)]
[SupportedOption(spoNewConsole)]
[SupportedOption(spoDesktop)]
[SupportedOption(spoParentProcess, omRequired)]
[SupportedOption(spoTimeout)]
function AdvxCreateProcessRemote(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntobapi, Ntapi.ntstatus, Ntapi.WinBase,
  Ntapi.ProcessThreadsApi, NtUtils.Processes.Info, NtUtils.Objects,
  DelphiUtils.AutoObjects;

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
  ProcessCreatorAsm64: array[0..175] of Byte = (
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
    $00, $00, $5B, $5D, $C3, $CC, $CC, $CC, $CC, $CC, $CC
  );
  {$ENDIF}

  ProcessCreatorAsm32: array[0 .. 127] of Byte = (
    $55, $8B, $EC, $83, $C4, $AC, $53, $8B, $5D, $08, $6A, $44, $6A, $00, $8D,
    $45, $BC, $50, $FF, $53, $10, $83, $C4, $0C, $C7, $45, $BC, $44, $00, $00,
    $00, $8B, $43, $40, $89, $45, $C4, $8D, $45, $AC, $50, $8D, $45, $BC, $50,
    $8B, $43, $48, $50, $6A, $00, $8B, $43, $18, $50, $8B, $43, $1C, $50, $6A,
    $00, $6A, $00, $8B, $43, $38, $50, $6A, $00, $FF, $13, $85, $C0, $74, $1C,
    $8B, $45, $AC, $89, $43, $20, $8B, $45, $B0, $89, $43, $28, $8B, $45, $B4,
    $89, $43, $30, $8B, $45, $B8, $89, $43, $34, $33, $C0, $EB, $0D, $FF, $53,
    $08, $25, $FF, $FF, $00, $00, $0D, $00, $00, $07, $C0, $5B, $8B, $E5, $5D,
    $C2, $04, $00, $CC, $CC, $CC, $CC, $CC
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

function StringSize(const Source: String): NativeUInt;
begin
  if Length(Source) > 0 then
    Result := Succ(Length(Source)) * SizeOf(WideChar)
  else
    Result := 0;
end;

function MarshalString(
  Source: String;
  var Target: Pointer;
  var RemoteTarget: Pointer
): Pointer;
var
  Size: NativeUInt;
begin
  Size := StringSize(Source);

  if Size > 0 then
  begin
    Result := RemoteTarget;
    Move(PWideChar(Source)^, Target^, Size);
    Inc(PByte(Target), Size);
    Inc(PByte(RemoteTarget), Size);
  end
  else
    Result := nil;
end;

function AdvxCreateProcessRemote;
var
  TargetIsWoW64: Boolean;
  CommandLine: String;
  ntdllFunctions: TArray<Pointer>;
  LocalMapping: IMemory<PCreateProcessContext>;
  RemoteMapping: IMemory;
  CodeRef: TMemory;
  DynamicPartLocal, DynamicPartRemote: Pointer;
  Timeout: Int64;
begin
  // We need a target for injection
  if not Assigned(Options.hxParentProcess) then
  begin
    Result.Location := 'AdvxCreateProcessRemote';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(Options.hxParentProcess.Handle,
    TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Select suitable shellcode
{$IFDEF Win64}
  if not TargetIsWoW64 then
    CodeRef := TMemory.Reference(ProcessCreatorAsm64)
  else
{$ENDIF}
    CodeRef := TMemory.Reference(ProcessCreatorAsm32);

  CommandLine := Options.CommandLine;

  // Map a shared region of memory
  Result := RtlxMapSharedMemory(
    Options.hxParentProcess,
    SizeOf(TCreateProcessContext) + CodeRef.Size + StringSize(CommandLine) +
      StringSize(Options.Desktop) + StringSize(Options.CurrentDirectory),
    IMemory(LocalMapping),
    RemoteMapping,
    [mmAllowWrite, mmAllowExecute]
  );

  if not Result.IsSuccess then
    Exit;

  // Resolve kernel32 dependency
  Result := RtlxFindKnownDllExport(kernel32, TargetIsWoW64, 'CreateProcessW',
    @LocalMapping.Data.CreateProcessW);

  if not Result.IsSuccess then
    Exit;

  // Resolve ntdll dependencies
  Result := RtlxFindKnownDllExports(ntdll, TargetIsWoW64,
    ['RtlGetLastWin32Error', 'memset'], ntdllFunctions);

  if not Result.IsSuccess then
    Exit;

  // Start filling up the parameters and code
  LocalMapping.Data.RtlGetLastWin32Error := ntdllFunctions[0];
  LocalMapping.Data.memset := ntdllFunctions[1];
  LocalMapping.Data.CreationFlags := GetCreationFlags(Options);
  LocalMapping.Data.InheritHandles := poInheritHandles in Options.Flags;

  Move(CodeRef.Address^, LocalMapping.Offset(SizeOf(TCreateProcessContext))^,
    CodeRef.Size);

  DynamicPartLocal := LocalMapping.Offset(SizeOf(TCreateProcessContext) +
    CodeRef.Size);
  DynamicPartRemote := RemoteMapping.Offset(SizeOf(TCreateProcessContext) +
    CodeRef.Size);

  LocalMapping.Data.CommandLine := MarshalString(CommandLine, DynamicPartLocal,
    DynamicPartRemote);
  LocalMapping.Data.Desktop := MarshalString(Options.Desktop, DynamicPartLocal,
    DynamicPartRemote);
  LocalMapping.Data.CurrentDirectory := MarshalString(Options.CurrentDirectory,
    DynamicPartLocal, DynamicPartRemote);

  if Options.Timeout <> 0 then
    Timeout := Options.Timeout
  else
    Timeout := DEFAULT_REMOTE_TIMEOUT;

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    Options.hxParentProcess,
    'Remote::CreateProcessW',
    RemoteMapping.Offset(SizeOf(TCreateProcessContext)),
    CodeRef.Size,
    RemoteMapping.Data,
    0,
    Timeout,
    [RemoteMapping]
  );

  if not Result.IsSuccess then
    Exit;

  // Copy the process information
  Info.ClientId.UniqueProcess := LocalMapping.Data.Info.ProcessId;
  Info.ClientId.UniqueThread := LocalMapping.Data.Info.ThreadId;

  // Move the process handle
  Result := NtxDuplicateHandleFrom(
    Options.hxParentProcess.Handle,
    LocalMapping.Data.Info.hProcess,
    Info.hxProcess,
    DUPLICATE_SAME_ACCESS or DUPLICATE_CLOSE_SOURCE
  );

  if not Result.IsSuccess then
    Exit;

  // Move the thread handle
  Result := NtxDuplicateHandleFrom(
    Options.hxParentProcess.Handle,
    LocalMapping.Data.Info.hThread,
    Info.hxThread,
    DUPLICATE_SAME_ACCESS or DUPLICATE_CLOSE_SOURCE
  );
end;

end.
