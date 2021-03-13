unit NtUtils.Job.Remote;

{
  The module allows querying information about jobs from a context of another
  process when it's not possible to open a handle to the job.
}

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils, NtUtils.Shellcode;

const
  PROCESS_QUERY_JOB_INFO = PROCESS_REMOTE_EXECUTE or PROCESS_VM_READ;

// Query variable-size job information of a process' job
function NtxQueryJobRemote(
  hxProcess: IHandle;
  InfoClass: TJobObjectInfoClass;
  out Buffer: IMemory;
  out TargetIsWoW64: Boolean;
  FixBufferSize: Cardinal = 0;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

// Enumerate list of processes in a job of a process
function NtxEnumerateProcessesInJobRemtote(
  hxProcess: IHandle;
  out ProcessIds: TArray<TProcessId>;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

type
  NtxJobRemote = class abstract
    // Query fixed-size information
    class function Query<T>(
      hxProcess: IHandle;
      InfoClass: TJobObjectInfoClass;
      out Buffer: T;
      Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
    ): TNtxStatus; static;

  {$IFDEF Win64}
    // Query fixed-size information that differs for Native and WoW64 processes
    class function QueryWoW64<T1, T2>(
      hxProcess: IHandle;
      InfoClass: TJobObjectInfoClass;
      out BufferNative: T1;
      out BufferWoW64: T2;
      out TargetIsWoW64: Boolean;
      Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
    ): TNtxStatus; static;
  {$ENDIF}
  end;

implementation

uses
  Ntapi.ntdef, Ntapi.ntwow64, NtUtils.Processes.Query, NtUtils.Processes.Memory,
  NtUtils.Threads, DelphiUtils.AutoObject;

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

    InfoClass: TJobObjectInfoClass;
    BufferSize: Cardinal;
  end;
  PJobQueryContext = ^TJobQueryContext;

  {$IFDEF Win64}
  TJobQueryContextWoW64 = record
    NtQueryInformationJobObject: Wow64Pointer;
    InfoClass: TJobObjectInfoClass;
    BufferSize: Cardinal;
  end;
  {$ENDIF}

// The function we are going to execute in a remote process.
// Make sure to reflect changes here in in the raw assembly code below.
function JobQueryRemote(Context: PJobQueryContext): NTSTATUS; stdcall;
begin
  // Query information about the current job saving it right after the context
  Result := Context.NtQueryInformationJobObject(0, Context.InfoClass,
    {$Q-}Pointer(UIntPtr(Context) + SizeOf(TJobQueryContext)){$Q+},
    Context.BufferSize, nil);
end;

const
  // Keep in sync with the function above
  {$IFDEF Win64}
  JobQueryAsm64: array [0..63] of Byte = (
    $55, $48, $83, $EC, $40, $48, $8B, $EC, $48, $89, $4D, $50, $33, $C9, $48,
    $8B, $45, $50, $8B, $50, $08, $48, $8B, $45, $50, $4C, $8D, $40, $10, $48,
    $8B, $45, $50, $44, $8B, $48, $0C, $48, $C7, $44, $24, $20, $00, $00, $00,
    $00, $48, $8B, $45, $50, $FF, $10, $89, $45, $3C, $8B, $45, $3C, $48, $8D,
    $65, $40, $5D, $C3
  );
  {$ENDIF}

  JobQueryAsm32: array[0..44] of Byte = (
    $55, $8B, $EC, $51, $6A, $00, $8B, $45, $08, $8B, $40, $08, $50, $8B, $45,
    $08, $83, $C0, $0C, $50, $8B, $45, $08, $8B, $40, $04, $50, $6A, $00, $8B,
    $45, $08, $FF, $10, $89, $45, $FC, $8B, $45, $FC, $59, $5D, $C2, $04, $00
  );

function NtxpPrepareContextJobQuery(
  hxProcess: IHandle;
  TargetIsWoW64: Boolean;
  InfoClass: TJobObjectInfoClass;
  FixBufferSize: Cardinal;
  out RemoteContext: IMemory
): TNtxStatus;
var
  Functions: TArray<Pointer>;
  Context: TJobQueryContext;
{$IFDEF Win64}
  ContextWoW64: TJobQueryContextWoW64;
{$ENDIF}
begin
  // Resolve dependencies
  Result := RtlxFindKnownDllExports(ntdll, TargetIsWoW64,
    ['NtQueryInformationJobObject'], Functions);

  if not Result.IsSuccess then
    Exit;

  // Allocate memory for remote context and buffer
  Result := NtxAllocateMemoryProcess(hxProcess, SizeOf(TJobQueryContext) +
    FixBufferSize, RemoteContext, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Prepare the context locally and write it to the remote
{$IFDEF Win64}
  if TargetIsWoW64 then
  begin
    ContextWoW64.NtQueryInformationJobObject := WoW64Pointer(Functions[0]);
    ContextWoW64.InfoClass := InfoClass;

    if FixBufferSize = 0 then
      ContextWoW64.BufferSize := Cardinal(RemoteContext.Size -
        SizeOf(TJobQueryContextWoW64))
    else
      ContextWoW64.BufferSize := FixBufferSize;

    // Write WoW64 context
    Result := NtxMemory.Write(hxProcess.Handle, RemoteContext.Data,
      ContextWoW64);
  end
  else
{$ENDIF}
  begin
    Context.NtQueryInformationJobObject := Functions[0];
    Context.InfoClass := InfoClass;

    if FixBufferSize = 0 then
      Context.BufferSize := Cardinal(RemoteContext.Size -
        SizeOf(TJobQueryContext))
    else
      Context.BufferSize := FixBufferSize;

    // Write native context
    Result := NtxMemory.Write(hxProcess.Handle, RemoteContext.Data, Context);
  end;
end;

function NtxQueryJobRemote;
var
  RemoteContext, RemoteCode: IMemory;
  PostQueryContext: IMemory;
  hxThread: IHandle;
begin
  // Prevent WoW64 -> Native
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Prepare and write a remote context
  Result := NtxpPrepareContextJobQuery(hxProcess, TargetIsWoW64,
    InfoClass, FixBufferSize, RemoteContext);

  if not Result.IsSuccess then
    Exit;

  // Write assembly code
  {$IFDEF Win64}
  if not TargetIsWoW64 then
    Result := NtxMemory.AllocWriteExec(hxProcess, JobQueryAsm64, RemoteCode,
      TargetIsWoW64)
  else
  {$ENDIF}
    Result := NtxMemory.AllocWriteExec(hxProcess, JobQueryAsm32, RemoteCode,
      TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Create a remote thread
  Result := NtxCreateThread(hxThread, hxProcess.Handle, RemoteCode.Data,
    RemoteContext.Data, THREAD_CREATE_FLAGS_SKIP_THREAD_ATTACH);

  if not Result.IsSuccess then
    Exit;

  // Sync with the thread. Prolong remote memory lifetime on timeout.
  Result := RtlxSyncThread(hxThread.Handle,
    'Remote::NtQueryInformationJobObject', Timeout, [RemoteCode,
    RemoteContext]);

  // Copy the buffer back on a successful query
  if Result.IsSuccess then
  begin
    // Retrieve the context
    PostQueryContext := TAutoMemory.Allocate(RemoteContext.Size);
    Result := NtxReadMemoryProcess(hxProcess.Handle, RemoteContext.Data,
      PostQueryContext.Region);

    // Extract the buffer
    if Result.IsSuccess then
    begin
      {$IFDEF Win64}
      if TargetIsWoW64 then
      begin
        Buffer := TAutoMemory.Allocate(PostQueryContext.Size -
          SizeOf(TJobQueryContextWoW64));

        Move(PostQueryContext.Offset(SizeOf(TJobQueryContextWoW64))^,
          Buffer.Data^, Buffer.Size);
      end
      else
      {$ENDIF}
      begin
        Buffer := TAutoMemory.Allocate(PostQueryContext.Size -
          SizeOf(TJobQueryContext));

        Move(PostQueryContext.Offset(SizeOf(TJobQueryContext))^,
          Buffer.Data^, Buffer.Size);
      end;
    end;
  end
  else if Result.Location = 'Remote::NtQueryInformationJobObject' then
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
