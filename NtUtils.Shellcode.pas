unit NtUtils.Shellcode;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntpsapi, NtUtils.Exceptions,
  NtUtils.Objects;

const
  PROCESS_INJECT_ACCESS = PROCESS_CREATE_THREAD or PROCESS_VM_OPERATION or
    PROCESS_VM_WRITE;

// Write a portion of data to a process' memory
function NtxWriteDataProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Status: TNtxStatus): Pointer;

// Write executable assembly code to a process
function NtxWriteAssemblyProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Status: TNtxStatus): Pointer;

// Copy data to a process and invoke a function on a remote thread
function RtlxInvokeFunctionProcess(out hxThread: IHandle; hProcess: THandle;
  Routine: TUserThreadStartRoutine; ParamBuffer: Pointer; ParamBufferSize:
  NativeUInt; Timeout: Int64 = INFINITE): TNtxStatus;

// Copy assembly code and data and invoke it in a remote thread
function RtlxInvokeAssemblyProcess(out hxThread: IHandle; hProcess: THandle;
  AssemblyBuffer: Pointer; AssemblyBufferSize: NativeUInt; ParamBuffer: Pointer;
  ParamBufferSize: NativeUInt; Timeout: Int64 = INFINITE): TNtxStatus;

// Synchronously invoke assembly code in a remote thread
function RtlxInvokeAssemblySyncProcess(hProcess: THandle; AssemblyBuffer:
  Pointer; AssemblyBufferSize: NativeUInt; ParamBuffer: Pointer;
  ParamBufferSize: NativeUInt; StatusComment: String): TNtxStatus;

// Inject a dll into a process
function RtlxInjectDllProcess(out hxThread: IHandle; hProcess: THandle;
  DllName: String; Timeout: Int64): TNtxStatus;

implementation

uses
  Ntapi.ntmmapi, Ntapi.ntstatus, NtUtils.Processes.Memory, NtUtils.Threads,
  NtUtils.Ldr;

function NtxWriteDataProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Status: TNtxStatus): Pointer;
begin
  // Allocate writable memory
  Status := NtxAllocateMemoryProcess(hProcess, BufferSize, Result);

  if not Status.IsSuccess then
    Exit;

  Status := NtxWriteMemoryProcess(hProcess, Result, Buffer, BufferSize);

  // Undo allocation on failure
  if not Status.IsSuccess then
    NtxFreeMemoryProcess(hProcess, Result, BufferSize);
end;

function NtxWriteAssemblyProcess(hProcess: THandle; Buffer: Pointer;
  BufferSize: NativeUInt; out Status: TNtxStatus): Pointer;
begin
  // Allocate and write the code to memory
  Result := NtxWriteDataProcess(hProcess, Buffer, BufferSize, Status);

  if not Status.IsSuccess then
    Exit;

  // Make the memory executable
  Status := NtxProtectMemoryProcess(hProcess, Result, BufferSize,
    PAGE_EXECUTE_READ);

  // Flush instruction cache to make sure the processor executes the code
  // from memory, not from its cache
  if Status.IsSuccess then
    Status := NtxFlushInstructionCache(hProcess, Result, BufferSize);

  // Undo everything on error
  if not Status.IsSuccess then
    NtxFreeMemoryProcess(hProcess, Result, BufferSize);
end;

function RtlxInvokeFunctionProcess(out hxThread: IHandle; hProcess: THandle;
  Routine: TUserThreadStartRoutine; ParamBuffer: Pointer; ParamBufferSize:
  NativeUInt; Timeout: Int64): TNtxStatus;
var
  Parameter: Pointer;
begin
  // Write data
  if Assigned(ParamBuffer) and (ParamBufferSize <> 0) then
  begin
    Parameter := NtxWriteDataProcess(hProcess, ParamBuffer, ParamBufferSize,
      Result);

    if not Result.IsSuccess then
      Exit;
  end
  else
    Parameter := nil;

  // Create remote thread
  Result := RtlxCreateThread(hxThread, hProcess, Routine, Parameter);

  if not Result.IsSuccess then
  begin
    // Free allocation on failure
    if Assigned(Parameter) then
      NtxFreeMemoryProcess(hProcess, Parameter, ParamBufferSize);

    Exit;
  end;

  if Timeout <> 0 then
  begin
    Result := NtxWaitForSingleObject(hxThread.Value, False, Timeout);

    // If the thread terminated we can clean up the memory
    if Assigned(Parameter) and (Result.Status = STATUS_WAIT_0) then
      NtxFreeMemoryProcess(hProcess, Parameter, ParamBufferSize);
  end;
end;

function RtlxInvokeAssemblyProcess(out hxThread: IHandle; hProcess: THandle;
  AssemblyBuffer: Pointer; AssemblyBufferSize: NativeUInt; ParamBuffer: Pointer;
  ParamBufferSize: NativeUInt; Timeout: Int64 = INFINITE): TNtxStatus;
var
  pCode: Pointer;
begin
  // Write assembly code
  pCode := NtxWriteAssemblyProcess(hProcess, AssemblyBuffer, AssemblyBufferSize,
    Result);

  if not Result.IsSuccess then
    Exit;

  // Invoke this code passing the parameter buffer
  Result := RtlxInvokeFunctionProcess(hxThread, hProcess, pCode, ParamBuffer,
    ParamBufferSize, Timeout);

  // Free the assembly allocation if the thread exited or anything else happen
  if Result.Matches(STATUS_WAIT_0, 'NtWaitForSingleObject')
    or not Result.IsSuccess then
    NtxFreeMemoryProcess(hProcess, pCode, AssemblyBufferSize);
end;

function RtlxInvokeAssemblySyncProcess(hProcess: THandle; AssemblyBuffer:
  Pointer; AssemblyBufferSize: NativeUInt; ParamBuffer: Pointer;
  ParamBufferSize: NativeUInt; StatusComment: String): TNtxStatus;
var
  ResultCode: NTSTATUS;
  hxThread: IHandle;
begin
  // Invoke the assembly code and wait for the result
  Result := RtlxInvokeAssemblyProcess(hxThread, hProcess, AssemblyBuffer,
    AssemblyBufferSize, ParamBuffer, ParamBufferSize, INFINITE);

  if Result.IsSuccess then
    Result := NtxQueryExitStatusThread(hxThread.Value, ResultCode);

  if Result.IsSuccess then
  begin
    // Pass the result of assembly code execution to the caller
    Result.Location := StatusComment;
    Result.Status := ResultCode;
  end;
end;

function RtlxInjectDllProcess(out hxThread: IHandle; hProcess: THandle;
  DllName: String; Timeout: Int64): TNtxStatus;
var
  hKernel32: HMODULE;
  pLoadLibrary: TUserThreadStartRoutine;
begin
  // TODO: WoW64 support
  Result := LdrxGetDllHandle(kernel32, hKernel32);

  if not Result.IsSuccess then
    Exit;

  pLoadLibrary := LdrxGetProcedureAddress(hKernel32, 'LoadLibraryW', Result);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInvokeFunctionProcess(hxThread, hProcess, pLoadLibrary,
    PWideChar(DllName), (Length(DllName) + 1) * SizeOf(WideChar), Timeout);
end;

end.
