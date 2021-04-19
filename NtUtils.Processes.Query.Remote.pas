unit NtUtils.Processes.Query.Remote;

{
  This module provides support for querying/setting process's information that
  can only be done in the context of the target process.
}

interface

uses
  Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode;

const
  PROCESS_QUERY_SECTION = PROCESS_REMOTE_EXECUTE or PROCESS_DUP_HANDLE;

// Open image section for a process even if the file was deleted
function NtxQuerySectionProcess(
  out hxSection: IHandle;
  const hxProcess: IHandle;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntobapi, NtUtils.Processes.Query, NtUtils.Objects,
  DelphiUtils.AutoObject;

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
  QuerySectionAsm64: array[0..47] of Byte = (
    $48, $83, $EC, $28, $48, $89, $C8, $48, $83, $C9, $FF, $BA, $59, $00, $00,
    $00, $4C, $8D, $40, $08, $41, $B9, $08, $00, $00, $00, $48, $C7, $44, $24,
    $20, $00, $00, $00, $00, $FF, $10, $48, $83, $C4, $28, $C3, $CC, $CC, $CC,
    $CC, $CC, $CC
  );
  {$ENDIF}

  QuerySectionAsm32: array[0 .. 23] of Byte = (
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

end.
