unit NtUtils.Shellcode;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntrtl, Ntapi.ntpsapi, NtUtils.Exceptions,
  NtUtils.Objects;

const
  PROCESS_INJECT_ACCESS = PROCESS_CREATE_THREAD or PROCESS_VM_OPERATION or
    PROCESS_VM_WRITE;

// Copy data to a process and invoke a function on a remote thread
function RtlxInvokeFunctionProcess(out hxThread: IHandle; hProcess: THandle;
  Routine: TUserThreadStartRoutine; ParamBuffer: Pointer; ParamBufferSize:
  NativeUInt; Timeout: Int64 = NT_INFINITE): TNtxStatus;

// Copy assembly code and data and invoke it in a remote thread
function RtlxInvokeAssemblyProcess(out hxThread: IHandle; hProcess: THandle;
  AssemblyBuffer: Pointer; AssemblyBufferSize: NativeUInt; ParamBuffer: Pointer;
  ParamBufferSize: NativeUInt; Timeout: Int64 = NT_INFINITE): TNtxStatus;

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

function RtlxInvokeFunctionProcess(out hxThread: IHandle; hProcess: THandle;
  Routine: TUserThreadStartRoutine; ParamBuffer: Pointer; ParamBufferSize:
  NativeUInt; Timeout: Int64): TNtxStatus;
var
  Memory: TMemory;
begin
  Memory.Address := nil;

  // Write data
  if Assigned(ParamBuffer) and (ParamBufferSize <> 0) then
  begin
    Result := NtxAllocWriteMemoryProcess(hProcess, ParamBuffer,
      ParamBufferSize, Memory);

    if not Result.IsSuccess then
      Exit;
  end;

  // Create remote thread
  Result := RtlxCreateThread(hxThread, hProcess, Routine, Memory.Address);

  if not Result.IsSuccess then
  begin
    // Free allocation on failure
    if Assigned(Memory.Address) then
      NtxFreeMemoryProcess(hProcess, Memory.Address, Memory.Size);

    Exit;
  end;

  if Timeout <> 0 then
  begin
    Result := NtxWaitForSingleObject(hxThread.Handle, Timeout);

    // If the thread terminated we can clean up the memory
    if Assigned(Memory.Address) and (Result.Status = STATUS_WAIT_0) then
      NtxFreeMemoryProcess(hProcess, Memory.Address, ParamBufferSize);
  end;
end;

function RtlxInvokeAssemblyProcess(out hxThread: IHandle; hProcess: THandle;
  AssemblyBuffer: Pointer; AssemblyBufferSize: NativeUInt; ParamBuffer: Pointer;
  ParamBufferSize: NativeUInt; Timeout: Int64 = NT_INFINITE): TNtxStatus;
var
  Code: TMemory;
begin
  // Write assembly code
  Result := NtxAllocWriteExecMemoryProcess(hProcess, AssemblyBuffer,
    AssemblyBufferSize, Code);

  if not Result.IsSuccess then
    Exit;

  // Invoke this code passing the parameter buffer
  Result := RtlxInvokeFunctionProcess(hxThread, hProcess, Code.Address,
    ParamBuffer, ParamBufferSize, Timeout);

  // Free the assembly allocation if the thread exited or anything else happen
  if Result.Matches(STATUS_WAIT_0, 'NtWaitForSingleObject')
    or not Result.IsSuccess then
    NtxFreeMemoryProcess(hProcess, Code.Address, Code.Size);
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
    AssemblyBufferSize, ParamBuffer, ParamBufferSize, NT_INFINITE);

  if Result.IsSuccess then
    Result := NtxQueryExitStatusThread(hxThread.Handle, ResultCode);

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
