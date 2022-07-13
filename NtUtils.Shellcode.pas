unit NtUtils.Shellcode;

{
  This module includes various helper functions for injecting code into other
  processes and finding exports from known DLLs.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntpsapi, Ntapi.ImageHlp, NtUtils;

const
  PROCESS_REMOTE_EXECUTE = PROCESS_QUERY_LIMITED_INFORMATION or
    PROCESS_CREATE_THREAD or PROCESS_VM_OPERATION;

  THREAD_SYNCHRONIZE = SYNCHRONIZE or THREAD_QUERY_LIMITED_INFORMATION;

  DEFAULT_REMOTE_TIMEOUT = 5000 * MILLISEC;

type
  TMappingMode = set of (mmAllowWrite, mmAllowExecute);

  // A custom callback for waiting on a thread.
  // Return STATUS_TIMEOUT or STATUS_WAIT_TIMEOUT to prevent automatic
  // memory deallocation.
  TCustomWaitRoutine = reference to function (
    const hxProcess: IHandle;
    const hxThread: IHandle;
    const Timeout: Int64
  ): TNtxStatus;

// Map a shared region of memory between the caller and the target
function RtlxMapSharedMemory(
  [Access(PROCESS_VM_OPERATION)] const hxProcess: IHandle;
  Size: NativeUInt;
  out LocalMemory: IMemory;
  out RemoteMemory: IMemory;
  Mode: TMappingMode
): TNtxStatus;

// Wait for a thread & forward it exit status. If the wait times out, prevent
// the memory from automatic deallocation (the thread might still use it).
function RtlxSyncThread(
  const hxProcess: IHandle;
  [Access(THREAD_SYNCHRONIZE)] const hxThread: IHandle;
  Timeout: Int64 = NT_INFINITE;
  [opt] const MemoryToCapture: TArray<IMemory> = nil;
  [opt] const CustomWait: TCustomWaitRoutine = nil
): TNtxStatus;

// Construct a TNtxStatus from thread's error code
function RtlxForwardExitStatusThread(
  [Access(THREAD_QUERY_LIMITED_INFORMATION)] const hxThread: IHandle;
  const StatusLocation: String
): TNtxStatus;

// Create a thread to execute the code and wait for its complition.
// - On success, forwards the status
// - On failure, prolongs lifetime of the remote memory
function RtlxRemoteExecute(
  [Access(PROCESS_REMOTE_EXECUTE)] const hxProcess: IHandle;
  const StatusLocation: String;
  [in] Code: Pointer;
  CodeSize: NativeUInt;
  [in, opt] Context: Pointer;
  ThreadFlags: TThreadCreateFlags = 0;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT;
  [opt] const MemoryToCapture: TArray<IMemory> = nil;
  [opt] const CustomWait: TCustomWaitRoutine = nil
): TNtxStatus;

// Locate multiple exports in a known dll
function RtlxFindKnownDllExports(
  DllName: String;
  TargetIsWoW64: Boolean;
  const Names: TArray<AnsiString>;
  out Addresses: TArray<Pointer>
): TNtxStatus;

// Locate a single export in a known dll
function RtlxFindKnownDllExport(
  const DllName: String;
  TargetIsWoW64: Boolean;
  const Name: AnsiString;
  out Address: Pointer
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntmmapi, NtUtils.Memory, NtUtils.Threads,
  NtUtils.ImageHlp, NtUtils.Sections, NtUtils.Synchronization,
  NtUtils.Processes;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxMapSharedMemory;
var
  hxSection: IHandle;
  Protection: TMemoryProtection;
begin
  if mmAllowExecute in Mode then
    Protection := PAGE_EXECUTE_READWRITE
  else
    Protection := PAGE_READWRITE;

  // Create a section backed by paging file
  Result := NtxCreateSection(hxSection, Size, Protection);

  if not Result.IsSuccess then
    Exit;

  // Map it locally always allowing write access
  Result := NtxMapViewOfSection(LocalMemory, hxSection.Handle,
    NtxCurrentProcess, PAGE_READWRITE);

  if not Result.IsSuccess then
    Exit;

  if [mmAllowWrite, mmAllowExecute] = Mode then
    Protection := PAGE_EXECUTE_READWRITE
  else if mmAllowExecute in Mode then
    Protection := PAGE_EXECUTE_READ
  else if mmAllowWrite in Mode then
    Protection := PAGE_READWRITE
  else
    Protection := PAGE_READONLY;

  // Map it remotely
  Result := NtxMapViewOfSection(RemoteMemory, hxSection.Handle,
    hxProcess, Protection);
end;

function RtlxSyncThread;
var
  CustomWaitResult: TNtxStatus;
  i: Integer;
begin
  if Assigned(CustomWait) then
  begin
    // Invoke custom waiting callback
    CustomWaitResult := CustomWait(hxProcess, hxThread, Timeout);

    // Only verify termination without further waiting
    Timeout := 0;
  end;

  Result := NtxWaitForSingleObject(hxThread.Handle, Timeout);

  // Make timeouts unsuccessful
  if Result.Status = STATUS_TIMEOUT then
    Result.Status := STATUS_WAIT_TIMEOUT;

  // The thread did't terminate in time or we cannot determine what happended
  // due to an error. Don't release the remote memory since the thread might
  // still use it.
  if not Result.IsSuccess then
    for i := 0 to High(MemoryToCapture) do
      MemoryToCapture[i].AutoRelease := False;

  // Callback-based waiting failed
  if Assigned(CustomWait) and not CustomWaitResult.IsSuccess then
    Exit(CustomWaitResult);
end;

function RtlxForwardExitStatusThread;
var
  IsTerminated: LongBool;
  Info: TThreadBasicInformation;
begin
  // Make sure the thread has terminated
  Result := NtxThread.Query(hxThread.Handle, ThreadIsTerminated, IsTerminated);

  if not Result.IsSuccess then
    Exit;

  if not IsTerminated then
  begin
    Result.Location := 'RtlxForwardExitStatusThread';
    Result.Status := STATUS_INVALID_PARAMETER;
    Exit;
  end;

  // Get the exit status
  Result := NtxThread.Query(hxThread.Handle, ThreadBasicInformation, Info);

  // Forward it
  if Result.IsSuccess then
  begin
    Result.Location := StatusLocation;
    Result.Status := Info.ExitStatus;
  end;
end;

function RtlxRemoteExecute;
var
  hxThread: IHandle;
begin
  if CodeSize > 0 then
    // We modified the executable memory recently, invalidate the cache
    NtxFlushInstructionCache(hxProcess.Handle, Code, CodeSize);

  // Create a thread to execute the code
  Result := NtxCreateThread(hxThread, hxProcess.Handle, Code, Context);

  if not Result.IsSuccess then
    Exit;

  // Synchronize with the thread; prolong remote memory lifetime on timeout
  Result := RtlxSyncThread(hxProcess, hxThread, Timeout, MemoryToCapture,
    CustomWait);

  if not Result.IsSuccess then
    Exit;

  // Forward exit status
  Result := RtlxForwardExitStatusThread(hxThread, StatusLocation);
end;

function RtlxFindKnownDllExports;
var
  hxSection: IHandle;
  MappedMemory: IMemory;
  BaseAddress: Pointer;
  AllEntries: TArray<TExportEntry>;
  pEntry: PExportEntry;
  i: Integer;
begin
  if TargetIsWoW64 then
    DllName := '\KnownDlls32\' + DllName
  else
    DllName := '\KnownDlls\' + DllName;

  // Open a known dll
  Result := NtxOpenSection(hxSection, SECTION_MAP_READ or SECTION_QUERY,
    DllName);

  if not Result.IsSuccess then
    Exit;

  // Map it
  Result := NtxMapViewOfSection(MappedMemory, hxSection.Handle,
    NtxCurrentProcess, PAGE_READONLY);

  if not Result.IsSuccess then
    Exit;

  // Infer the base address of the DLL that other processes will use
  Result := RtlxQueryOriginalBaseImage(hxSection.Handle,
    MappedMemory.Region, BaseAddress);

  if not Result.IsSuccess then
    Exit;

  // Parse the export table
  Result := RtlxEnumerateExportImage(AllEntries, MappedMemory.Data,
    Cardinal(MappedMemory.Size), True);

  if not Result.IsSuccess then
    Exit;

  SetLength(Addresses, Length(Names));

  for i := 0 to High(Names) do
  begin
    pEntry := RtlxFindExportedName(AllEntries, Names[i]);

    if not Assigned(pEntry) or pEntry.Forwards then
    begin
      Result.Location := 'RtlxFindKnownDllExports';
      Result.Status := STATUS_PROCEDURE_NOT_FOUND;
      Exit;
    end;

    Addresses[i] := PByte(BaseAddress) + pEntry.VirtualAddress;
  end;
end;

function RtlxFindKnownDllExport;
var
  Addresses: TArray<Pointer>;
begin
  Result := RtlxFindKnownDllExports(DllName, TargetIsWoW64, [Name], Addresses);

  if Result.IsSuccess then
    Address := Addresses[0];
end;

end.
