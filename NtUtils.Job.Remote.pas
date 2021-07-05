unit NtUtils.Job.Remote;

{
  The module allows querying information about jobs from a context of another
  process when it's not possible to open a handle to the job.
}

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode;

const
  PROCESS_QUERY_JOB_INFO = PROCESS_REMOTE_EXECUTE;

// Query variable-size job information of a process' job
function NtxQueryJobRemote(
  const hxProcess: IHandle;
  InfoClass: TJobObjectInfoClass;
  out Buffer: IMemory;
  out TargetIsWoW64: Boolean;
  FixBufferSize: Cardinal = 0;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

// Enumerate list of processes in a job of a process
function NtxEnumerateProcessesInJobRemtote(
  const hxProcess: IHandle;
  out ProcessIds: TArray<TProcessId>;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

type
  NtxJobRemote = class abstract
    // Query fixed-size information
    class function Query<T>(
      const hxProcess: IHandle;
      InfoClass: TJobObjectInfoClass;
      out Buffer: T;
      const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
    ): TNtxStatus; static;

  {$IFDEF Win64}
    // Query fixed-size information that differs for Native and WoW64 processes
    class function QueryWoW64<T1, T2>(
      const hxProcess: IHandle;
      InfoClass: TJobObjectInfoClass;
      out BufferNative: T1;
      out BufferWoW64: T2;
      out TargetIsWoW64: Boolean;
      const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
    ): TNtxStatus; static;
  {$ENDIF}
  end;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntwow64, NtUtils.Processes.Query,
  DelphiUtils.AutoObjects;

type
  // A context for a thread that performs the query remotely
  TJobQueryContext = record
    NtQueryInformationJobObject: function (
      JobHandle: THandle;
      JobObjectInformationClass: TJobObjectInfoClass;
      JobObjectInformation: Pointer;
      JobObjectInformationLength: Cardinal;
      ReturnLength: PCardinal
    ): NTSTATUS; stdcall;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}

    InfoClass: TJobObjectInfoClass;
    BufferSize: Cardinal;

    Buffer: Pointer;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}
  end;
  PJobQueryContext = ^TJobQueryContext;

// The function we are going to execute in a remote process.
// Make sure to reflect changes here in in the raw assembly code below.
function JobQueryRemote(Context: PJobQueryContext): NTSTATUS; stdcall;
begin
  Result := Context.NtQueryInformationJobObject(0, Context.InfoClass,
    Context.Buffer, Context.BufferSize, @Context.BufferSize);
end;

const
  {$IFDEF Win64}
  // Keep in sync with the function above
  JobQueryAsm64: array [0..39] of Byte = (
    $48, $83, $EC, $28, $48, $89, $C8, $33, $C9, $8B, $50, $08, $4C, $8B, $40,
    $10, $44, $8B, $48, $0C, $4C, $8D, $50, $0C, $4C, $89, $54, $24, $20, $FF,
    $10, $48, $83, $C4, $28, $C3, $CC, $CC, $CC, $CC
  );
  {$ENDIF}

  // Keep in sync with the function above
  JobQueryAsm32: array[0..31] of Byte = (
    $55, $8B, $EC, $8B, $45, $08, $8D, $50, $0C, $52, $8B, $50, $0C, $52, $8B,
    $50, $10, $52, $8B, $50, $08, $52, $6A, $00, $FF, $10, $5D, $C2, $04, $00,
    $CC, $CC
  );

function NtxQueryJobRemote;
const
  MIN_BUFFER_SIZE = 256;
var
  CodeRef: TMemory;
  LocalMapping: IMemory<PJobQueryContext>;
  RemoteMapping: IMemory;
  BufferSize: Cardinal;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Select mathcing shellcode
{$IFDEF Win64}
  if not TargetIsWoW64 then
    CodeRef := TMemory.Reference(JobQueryAsm64)
  else
{$ENDIF}
    CodeRef := TMemory.Reference(JobQueryAsm32);

  // Make sure we reserve some space for the buffer
  if FixBufferSize <> 0 then
    BufferSize := FixBufferSize
  else
    BufferSize := MIN_BUFFER_SIZE;

  // Map a shared memory region
  Result := RtlxMapSharedMemory(hxProcess,
    CodeRef.Size + SizeOf(TJobQueryContext) + BufferSize,
    IMemory(LocalMapping), RemoteMapping, [mmAllowWrite, mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  // We usually get way more space because of page granularity; use it
  if FixBufferSize = 0 then
    BufferSize := Cardinal(RemoteMapping.Size -
      SizeOf(TJobQueryContext) - CodeRef.Size);

  // Resolve dependencies
  Result := RtlxFindKnownDllExport(
    ntdll,
    TargetIsWoW64,
    'NtQueryInformationJobObject',
    @LocalMapping.Data.NtQueryInformationJobObject
  );

  if not Result.IsSuccess then
    Exit;

  // Prepare parameters
  LocalMapping.Data.InfoClass := InfoClass;
  LocalMapping.Data.BufferSize := BufferSize;
  LocalMapping.Data.Buffer := RemoteMapping.Offset(SizeOf(TJobQueryContext) +
    CodeRef.Size);

  Move(CodeRef.Address^, LocalMapping.Offset(SizeOf(TJobQueryContext))^,
    CodeRef.Size);

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    hxProcess.Handle,
    'Remote::NtQueryInformationJobObject',
    RemoteMapping.Offset(SizeOf(TJobQueryContext)),
    CodeRef.Size,
    RemoteMapping.Data,
    THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH,
    Timeout,
    [RemoteMapping]
  );

  if not Result.IsSuccess then
    Exit;

  // Check the buffer size
  FixBufferSize := LocalMapping.Data.BufferSize;

  if FixBufferSize > BufferSize then
  begin
    Result.Location := 'NtxQueryJobRemote';
    Result.Status := STATUS_BUFFER_TOO_SMALL;
    Result.LastCall.AttachInfoClass(InfoClass);
    Exit;
  end;

  // Copy the result
  Buffer := Auto.CopyDynamic(LocalMapping.Offset(SizeOf(TJobQueryContext) +
    CodeRef.Size), FixBufferSize);

  Result.LastCall.AttachInfoClass(InfoClass);
end;

function NtxEnumerateProcessesInJobRemtote;
var
  xMemory: IMemory<PJobObjectBasicProcessIdList>;
{$IFDEF Win64}
  xMemory32: IMemory<PJobObjectBasicProcessIdList32> absolute xMemory;
{$ENDIF}
  TargetIsWoW64: Boolean;
  i: Integer;
begin
  Result := NtxQueryJobRemote(hxProcess, JobObjectBasicProcessIdList,
    IMemory(xMemory), TargetIsWoW64, 0, Timeout);

  if not Result.IsSuccess then
    Exit;

{$IFDEF Win64}
  if TargetIsWoW64 then
  begin
    // WoW64
    SetLength(ProcessIds, xMemory32.Data.NumberOfProcessIdsInList);

    for i := 0 to High(ProcessIds) do
      ProcessIds[i] := xMemory.Data.ProcessIdList{$R-}[i]{$R+};
  end
  else
{$ENDIF}
  begin
    // Native
    SetLength(ProcessIds, xMemory.Data.NumberOfProcessIdsInList);

    for i := 0 to High(ProcessIds) do
      ProcessIds[i] := xMemory.Data.ProcessIdList{$R-}[i]{$R+};
  end;
end;

class function NtxJobRemote.Query<T>;
var
  xMemory: IMemory;
  TargetIsWoW64: Boolean;
begin
  Result := NtxQueryJobRemote(hxProcess, InfoClass, xMemory, TargetIsWoW64,
    SizeOf(Buffer), Timeout);

  if Result.IsSuccess then
    Move(xMemory.Data^, Buffer, SizeOf(Buffer));
end;

{$IFDEF Win64}
class function NtxJobRemote.QueryWoW64<T1, T2>;
var
  xMemory: IMemory;
begin
  // Query using the biggest buffer size, which is native
  Result := NtxQueryJobRemote(hxProcess, InfoClass, xMemory, TargetIsWoW64,
    SizeOf(BufferNative), Timeout);

  if Result.IsSuccess then
  begin
    if TargetIsWoW64 then
      Move(xMemory.Data^, BufferWoW64, SizeOf(BufferWoW64))
    else
      Move(xMemory.Data^, BufferNative, SizeOf(BufferNative));
  end;
end;
{$ENDIF}

end.
