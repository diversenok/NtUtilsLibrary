unit NtUtils.Transactions.Remote;

interface

uses
  NtUtils.Exceptions;

// Get a handle value of the current transaction on a remote thread
function RtlxGetTransactionThread(hProcess: THandle; hThread: THandle;
  out HandleValue: THandle): TNtxStatus;

// Set a handle value of the current transaction on a remote thread
function RtlxSetTransactionThread(hProcess: THandle; hThread: THandle;
  HandleValue: THandle): TNtxStatus;

implementation

uses
  Ntapi.ntpsapi, Ntapi.ntwow64, NtUtils.Threads, NtUtils.Processes,
  NtUtils.Processes.Memory;

function RtlxGetTransactionThread(hProcess: THandle; hThread: THandle;
  out HandleValue: THandle): TNtxStatus;
var
  ThreadInfo: TThreadBasicInformation;
  IsWow64Target: NativeUInt;
begin
  // Although under WoW64 we can still work with other WoW64 processes we
  // won't because we still need to update 64-bit TEB, and it is complicated.
  Result := NtxAssertNotWoW64;

  if not Result.IsSuccess then
    Exit;

  // Query TEB location for the thread
  Result := NtxThread.Query<TThreadBasicInformation>(hThread,
    ThreadBasicInformation, ThreadInfo);

  if not Result.IsSuccess then
    Exit;

  // Read the handle value from thread's TEB.
  // In case of a WoW64 target it has two TEBs, and both of them should
  // store the same handle value. However 64-bit TEB has precendence, so
  // the following code also works for WoW64 processes.

  Result := NtxReadMemoryProcess(hProcess,
    @ThreadInfo.TebBaseAddress.CurrentTransactionHandle,
    @HandleValue, SizeOf(HandleValue));
end;

function RtlxSetTransactionThread(hProcess: THandle; hThread: THandle;
  HandleValue: THandle): TNtxStatus;
var
  ThreadInfo: TThreadBasicInformation;
  {$IFDEF Win64}
  IsWow64Target: NativeUInt;
  Teb32Offset: Integer;
  Teb32: PTeb32;
  HandleValue32: Cardinal;
  {$ENDIF}
begin
  // Although under WoW64 we can still work with other WoW64 processes we
  // won't because we still need to update 64-bit TEB, and it is complicated.
  Result := NtxAssertNotWoW64;

  if not Result.IsSuccess then
    Exit;

  // Query TEB location for the thread
  Result := NtxThread.Query<TThreadBasicInformation>(hThread,
    ThreadBasicInformation, ThreadInfo);

  if not Result.IsSuccess then
    Exit;

  // Write the handle value to thread's TEB
  Result := NtxWriteMemoryProcess(hProcess,
    @ThreadInfo.TebBaseAddress.CurrentTransactionHandle,
    @HandleValue, SizeOf(HandleValue));

  if not Result.IsSuccess then
    Exit;

  // Threads in WoW64 processes have two TEBs, so we should update both of them.
  // However, this operation is optional since 64-bit TEB has precedence,
  // therefore we ignore errors in the following code.

  {$IFDEF Win64}
  if NtxProcess.Query<NativeUInt>(hProcess, ProcessWow64Information,
    IsWow64Target).IsSuccess and (IsWow64Target <> 0) then
  begin
    // 64-bit TEB stores an offset to a 32-bit TEB, read it
    if not NtxReadMemoryProcess(hProcess,
      @ThreadInfo.TebBaseAddress.WowTebOffset,
      @Teb32Offset, SizeOf(Teb32Offset)).IsSuccess then
      Exit;

    if Teb32Offset = 0 then
      Exit;

    HandleValue32 := Cardinal(HandleValue);
    Teb32 := PTeb32(NativeInt(ThreadInfo.TebBaseAddress) + Teb32Offset);

    // Write the handle to the 32-bit TEB
    NtxWriteMemoryProcess(hProcess, @Teb32.CurrentTransactionHandle,
      @HandleValue32, SizeOf(HandleValue32));
  end;
  {$ENDIF}
end;

end.
