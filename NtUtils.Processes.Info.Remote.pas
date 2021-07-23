unit NtUtils.Processes.Info.Remote;

{
  This module provides support for querying/setting process's information in the
  context of the target process.
}

interface

uses
  Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode;

const
  PROCESS_QUERY_SECTION = PROCESS_REMOTE_EXECUTE or PROCESS_DUP_HANDLE;
  PROCESS_SET_INSTRUMENTATION = PROCESS_REMOTE_EXECUTE or
    PROCESS_SET_INFORMATION;

// Open image section for a process even if the file was deleted
function NtxQuerySectionProcess(
  out hxSection: IHandle;
  [Access(PROCESS_QUERY_SECTION)] const hxProcess: IHandle;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

// Set an instrumentation callback to execute every time process's threads
// return to user mode. Does not require the Debug Privilege since we
// are setting it via shellcode. Use "jmp r10" to return from the callback.
function NtxSetInstrumentationProcess(
  [Access(PROCESS_SET_INSTRUMENTATION)] const hxProcess: IHandle;
  CallbackAddress: Pointer;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntobapi, NtUtils.Processes.Info,
  NtUtils.Objects, DelphiUtils.AutoObjects;

{ Image Section }

type
  TSectionQueryContext = record
    NtQueryInformationProcess: function (
      ProcessHandle: THandle;
      ProcessInformationClass: TProcessInfoClass;
      ProcessInformation: Pointer;
      ProcessInformationLength: Cardinal;
      ReturnLength: PCardinal
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}

    hSection: THandle;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}
  end;
  PSectionQueryContext = ^TSectionQueryContext;

// Function to execute remotely; keep in sync with assembly below
function QuerySectionRemote(Context: PSectionQueryContext): NTSTATUS; stdcall;
begin
  Result := Context.NtQueryInformationProcess(NtCurrentProcess,
    ProcessImageSection, @Context.hSection, SizeOf(Context.hSection), nil);
end;

const
  // Raw assembly for injection; keep in sync with function above
  {$IFDEF Win64}
  QuerySectionAsm64: array [0 .. 47] of Byte = (
    $48, $83, $EC, $28, $48, $89, $C8, $48, $83, $C9, $FF, $BA, $59, $00, $00,
    $00, $4C, $8D, $40, $08, $41, $B9, $08, $00, $00, $00, $48, $C7, $44, $24,
    $20, $00, $00, $00, $00, $FF, $10, $48, $83, $C4, $28, $C3, $CC, $CC, $CC,
    $CC, $CC, $CC
  );
  {$ENDIF}

  QuerySectionAsm32: array [0 .. 23] of Byte = (
    $55, $8B, $EC, $8B, $45, $08, $6A, $00, $6A, $04, $8D, $50, $08, $52, $6A,
    $59, $6A, $FF, $FF, $10, $5D, $C2, $04, $00
  );

function NtxQuerySectionProcess;
var
  TargetIsWoW64: Boolean;
  CodeRef: TMemory;
  LocalMapping: IMemory<PSectionQueryContext>;
  RemoteMemory: IMemory;
begin
  // Prevent WoW64 -> Native injection
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

{$IFDEF Win64}
  if not TargetIsWoW64 then
    CodeRef := TMemory.Reference(QuerySectionAsm64)
  else
{$ENDIF}
    CodeRef := TMemory.Reference(QuerySectionAsm32);

  // Map shared memory with the target
  Result := RtlxMapSharedMemory(hxProcess, SizeOf(TSectionQueryContext) +
    CodeRef.Size, IMemory(LocalMapping), RemoteMemory, [mmAllowWrite,
    mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  // Find dependencies
  Result := RtlxFindKnownDllExport(ntdll, TargetIsWoW64,
    'NtQueryInformationProcess', @LocalMapping.Data.NtQueryInformationProcess);

  if not Result.IsSuccess then
    Exit;

  Move(CodeRef.Address^, LocalMapping.Offset(SizeOf(TSectionQueryContext))^,
    CodeRef.Size);

  Result := RtlxRemoteExecute(
    hxProcess.Handle,
    'Remote::NtQueryInformationProcess',
    RemoteMemory.Offset(SizeOf(TSectionQueryContext)),
    CodeRef.Size,
    RemoteMemory.Data,
    THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH,
    Timeout,
    [RemoteMemory]
  );

  if not Result.IsSuccess then
    Exit;

  // Copy the handle back
  Result := NtxDuplicateHandleFrom(hxProcess.Handle, LocalMapping.Data.hSection,
    hxSection, DUPLICATE_SAME_ACCESS or DUPLICATE_CLOSE_SOURCE);
end;

{ Instrumentation Callback }

// We only support 64-bits for now
{$IFDEF Win64}

type
  TInstrumentationSetContext = record
    NtSetInformationProcess: function (
      ProcessHandle: THandle;
      ProcessInformationClass: TProcessInfoClass;
      [in] ProcessInformation: Pointer;
      ProcessInformationLength: Cardinal
    ): NTSTATUS; stdcall;

    Callback: Pointer;
  end;
  PInstrumentationSetContext = ^TInstrumentationSetContext;

// A function to execute the context of the target
function InstrumentationSetter(
  Context: PInstrumentationSetContext
): NTSTATUS; stdcall;
begin
  Result := Context.NtSetInformationProcess(
    NtCurrentProcess,
    ProcessInstrumentationCallback,
    @Context.Callback,
    SizeOf(Context.Callback)
  );
end;

const
  InstrumentationSetter64: array [0 .. 39] of Byte = (
    $48, $83, $EC, $28, $48, $89, $C8, $48, $83, $C9, $FF, $BA, $28, $00, $00,
    $00, $4C, $8D, $40, $08, $41, $B9, $08, $00, $00, $00, $FF, $10, $48, $83,
    $C4, $28, $C3, $CC, $CC, $CC, $CC, $CC, $CC, $CC
  );

function NtxSetInstrumentationProcess;
var
  TargetIsWoW64: Boolean;
  CodeRef: TMemory;
  LocalMapping: IMemory<PInstrumentationSetContext>;
  RemoteMemory: IMemory;
begin
  Result := NtxQueryIsWoW64Process(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  if TargetIsWoW64 then
  begin
    Result.Location := 'NtxSetInstrumentationProcess';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  // Try setting it directly (requires Debug Privilege)
  Result := NtxProcess.Set(hxProcess.Handle, ProcessInstrumentationCallback,
    CallbackAddress);

  if Result.IsSuccess then
    Exit;

  // It did not work; fallback to injecting a thread to do it on the target's
  // behalf

  CodeRef := TMemory.Reference(InstrumentationSetter64);

  // Map shared memory with the target
  Result := RtlxMapSharedMemory(hxProcess, SizeOf(TInstrumentationSetContext) +
    CodeRef.Size, IMemory(LocalMapping), RemoteMemory, [mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  // Find dependencies
  Result := RtlxFindKnownDllExport(ntdll, TargetIsWoW64,
    'NtSetInformationProcess', @LocalMapping.Data.NtSetInformationProcess);

  if not Result.IsSuccess then
    Exit;

  // Copy the data and the code
  LocalMapping.Data.Callback := CallbackAddress;
  Move(CodeRef.Address^, LocalMapping.Offset(
    SizeOf(TInstrumentationSetContext))^, CodeRef.Size);

  // Execute and wait
  Result := RtlxRemoteExecute(
    hxProcess.Handle,
    'Remote::NtSetInformationProcess',
    RemoteMemory.Offset(SizeOf(TInstrumentationSetContext)),
    CodeRef.Size,
    RemoteMemory.Data,
    THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH,
    Timeout,
    [RemoteMemory]
  );
end;

{$ELSE}

function NtxSetInstrumentationProcess;
begin
  // Maybe add 32-bit support later
  Result.Location := 'NtxSetInstrumentationProcess';
  Result.Status := STATUS_NOT_SUPPORTED;
end;

{$ENDIF}

end.
