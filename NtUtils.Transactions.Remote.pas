unit NtUtils.Transactions.Remote;

{
  This module allows querying and setting current transaction for threads in
  other processes.
}

interface

uses
  Ntapi.ntpsapi, NtUtils;

const
  PROCESS_GET_THREAD_TRANSACTION = PROCESS_VM_READ;
  PROCESS_SET_THREAD_TRANSACTION = PROCESS_VM_WRITE
    {$IFDEF Win64}or PROCESS_VM_READ{$ENDIF};

  PROCESS_SET_PROCESS_TRANSACTION = PROCESS_QUERY_INFORMATION or
    PROCESS_SUSPEND_RESUME or PROCESS_SET_THREAD_TRANSACTION;

  THREAD_GET_TRANSACTION = THREAD_QUERY_LIMITED_INFORMATION;
  THREAD_SET_TRANSACTION = THREAD_QUERY_LIMITED_INFORMATION;

// Get a handle value of the current transaction on a remote thread
function RtlxGetTransactionThread(
  hProcess: THandle;
  hThread: THandle;
  out HandleValue: THandle
): TNtxStatus;

// Set a handle value of the current transaction on a remote thread
function RtlxSetTransactionThread(
  hProcess: THandle;
  hThread: THandle;
  [opt] HandleValue: THandle
): TNtxStatus;

// Set a handle value as a current transaction on all threads in a process
function RtlxSetTransactionProcess(
  const hxProcess: IHandle;
  [opt] HandleValue: THandle
): TNtxStatus;

implementation

uses
  Ntapi.ntwow64, Ntapi.ntstatus, NtUtils.Threads, NtUtils.Processes,
  NtUtils.Processes.Memory, NtUtils.Processes.Query;

function RtlxGetTransactionThread;
var
  ThreadInfo: TThreadBasicInformation;
begin
{$IFDEF Win32}
  // Although under WoW64 we can work with other WoW64 processes we won't
  // since we still need to update 64-bit TEB, so it gets complicated.
  if RtlxAssertNotWoW64(Result) then
    Exit;
{$ENDIF}

  // Query TEB location for the thread
  Result := NtxThread.Query(hThread, ThreadBasicInformation, ThreadInfo);

  if not Result.IsSuccess then
    Exit;

  // Make sure the thread is alive
  if not Assigned(ThreadInfo.TebBaseAddress) then
  begin
    Result.Location := 'RtlxGetTransactionThread';
    Result.Status := STATUS_THREAD_IS_TERMINATING;
    Exit;
  end;

  // Read the handle value from thread's TEB.
  // In case of a WoW64 target it has two TEBs, and both of them should
  // store the same handle value. However, 64-bit TEB has precendence, so
  // the following code also works for WoW64 processes.

  Result := NtxReadMemoryProcess(hProcess,
    @ThreadInfo.TebBaseAddress.CurrentTransactionHandle,
      TMemory.Reference(HandleValue));
end;

function RtlxSetTransactionThread;
var
  ThreadInfo: TThreadBasicInformation;
  {$IFDEF Win64}
  IsWow64Target: Boolean;
  Teb32Offset: Integer;
  Teb32: PTeb32;
  HandleValue32: Cardinal;
  {$ENDIF}
begin
{$IFDEF Win32}
  // Although under WoW64 we can work with other WoW64 processes we won't
  // since we still need to update 64-bit TEB, so it gets complicated.
  if RtlxAssertNotWoW64(Result) then
    Exit;
{$ENDIF}

  if not Result.IsSuccess then
    Exit;

  // Query TEB location for the thread
  Result := NtxThread.Query(hThread, ThreadBasicInformation, ThreadInfo);

  if not Result.IsSuccess then
    Exit;

  // Make sure the thread is alive
  if not Assigned(ThreadInfo.TebBaseAddress) then
  begin
    Result.Location := 'RtlxGetTransactionThread';
    Result.Status := STATUS_THREAD_IS_TERMINATING;
    Exit;
  end;

  // Write the handle value to thread's TEB
  Result := NtxWriteMemoryProcess(hProcess,
    @ThreadInfo.TebBaseAddress.CurrentTransactionHandle,
    TMemory.Reference(HandleValue));

  if not Result.IsSuccess then
    Exit;

  // Threads in WoW64 processes have two TEBs, so we should update both of them.
  // However, this operation is optional since 64-bit TEB has precedence,
  // therefore we ignore errors in the following code.

  {$IFDEF Win64}
  if NtxQueryIsWoW64Process(hProcess, IsWow64Target).IsSuccess and
    IsWow64Target then
  begin
    // 64-bit TEB stores an offset to a 32-bit TEB, read it
    if not NtxReadMemoryProcess(hProcess,
      @ThreadInfo.TebBaseAddress.WowTebOffset,
      TMemory.Reference(Teb32Offset)).IsSuccess then
      Exit;

    if Teb32Offset = 0 then
      Exit;

    HandleValue32 := Cardinal(HandleValue);
    Teb32 := PTeb32(NativeInt(ThreadInfo.TebBaseAddress) + Teb32Offset);

    // Write the handle to the 32-bit TEB
    NtxWriteMemoryProcess(hProcess, @Teb32.CurrentTransactionHandle,
      TMemory.Reference(HandleValue32));
  end;
  {$ENDIF}
end;

function RtlxSetTransactionProcess;
var
  hxThread: IHandle;
  IsTerminated: LongBool;
begin
  // Suspend the process to avoid race conditions
  Result := NtxSuspendProcess(hxProcess.Handle);

  if not Result.IsSuccess then
    Exit;

  // Resume automatically when we are done
  NtxDelayedResumeProcess(hxProcess);

  hxThread := nil;

  while NtxGetNextThread(hxProcess.Handle, hxThread,
    THREAD_QUERY_LIMITED_INFORMATION).Save(Result) do
  begin
    // Skip terminated threads
    Result := NtxThread.Query(hxThread.Handle, ThreadIsTerminated,
      IsTerminated);

    // Update current transaction
    if Result.IsSuccess and not IsTerminated then
      Result := RtlxSetTransactionThread(hxProcess.Handle, hxThread.Handle,
        HandleValue);

    if not Result.IsSuccess then
      Exit;
  end;
end;

end.
