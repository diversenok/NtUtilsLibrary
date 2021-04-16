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
  hxProcess: IHandle;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntobapi, NtUtils.Processes.Query,
  NtUtils.Processes.Memory, NtUtils.Threads, NtUtils.Objects;

type
  TNtQueryInformationProcess = function (
    ProcessHandle: THandle;
    ProcessInformationClass: TProcessInfoClass;
    ProcessInformation: Pointer;
    ProcessInformationLength: Cardinal;
    ReturnLength: PCardinal
  ): NTSTATUS; stdcall;

function QuerySectionRemote(
  NtQueryInformationProcess: TNtQueryInformationProcess
): NTSTATUS; stdcall;
var
  hSection: THandle;
begin
  Result := NtQueryInformationProcess(NtCurrentProcess, ProcessImageSection,
    @hSection, SizeOf(hSection), nil);

  // Forward the handle value within a successful status code
  if NT_SUCCESS(Result) then
    Result := NTSTATUS(hSection);
end;

const
  // Raw assembly for the function above; keep it in sync
  {$IFDEF Win64}
  QuerySectionAsm64: array[0 .. 66] of Byte = (
    $55, $48, $83, $EC, $40, $48, $8B, $EC, $48, $89, $4D, $50, $48, $83, $C9,
    $FF, $BA, $59, $00, $00, $00, $4C, $8D, $45, $30, $41, $B9, $08, $00, $00,
    $00, $48, $C7, $44, $24, $20, $00, $00, $00, $00, $FF, $55, $50, $89, $45,
    $3C, $83, $7D, $3C, $00, $7C, $06, $8B, $45, $30, $89, $45, $3C, $8B, $45,
    $3C, $48, $8D, $65, $40, $5D, $C3
  );
  {$ENDIF}

  QuerySectionAsm32: array[0 .. 44] of Byte = (
    $55, $8B, $EC, $83, $C4, $F8, $6A, $00, $6A, $04, $8D, $45, $F8, $50, $6A,
    $59, $6A, $FF, $FF, $55, $08, $89, $45, $FC, $83, $7D, $FC, $00, $7C, $06,
    $8B, $45, $F8, $89, $45, $FC, $8B, $45, $FC, $59, $59, $5D, $C2, $04, $00
  );

function NtxQuerySectionProcess;
var
  IsWoW64: Boolean;
  LocalCode: TMemory;
  RemoteCode: IMemory;
  hxThread: IHandle;
  pNtQueryInformationProcess: Pointer;
begin
  // Prevent WoW64 -> Native injection
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, IsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Find the required function in the context of the target
  Result := RtlxFindKnownDllExport(ntdll, IsWoW64,
    'NtQueryInformationProcess', pNtQueryInformationProcess);

  if not Result.IsSuccess then
    Exit;

  {$IFDEF Win64}
  if not IsWoW64 then
    LocalCode := TMemory.Reference(QuerySectionAsm64)
  else
  {$ENDIF}
    LocalCode := TMemory.Reference(QuerySectionAsm32);

  // Write the shellcode
  Result := NtxAllocWriteExecMemoryProcess(hxProcess, LocalCode,
    RemoteCode, IsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Create a thread to query the section on the process's behalf
  Result := NtxCreateThread(hxThread, hxProcess.Handle, RemoteCode.Data,
    pNtQueryInformationProcess);

  if not Result.IsSuccess then
    Exit;

  // Wait for completion; prolong shellcode's lifetime on timeout
  Result := RtlxSyncThread(hxThread.Handle, 'Remote::NtQueryInformationProcess',
    Timeout, [RemoteCode]);

  if not Result.IsSuccess then
    Exit;

  // Copy the handle back; the function returned the value in a successful code
  Result := NtxDuplicateHandleFrom(hxProcess.Handle, THandle(Result.Status),
    hxSection, DUPLICATE_SAME_ACCESS or DUPLICATE_CLOSE_SOURCE);
end;

end.
