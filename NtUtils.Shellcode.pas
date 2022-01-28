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
  [Access(THREAD_SYNCHRONIZE)] hThread: THandle;
  const StatusLocation: String;
  const Timeout: Int64 = NT_INFINITE;
  [opt] const MemoryToCapture: TArray<IMemory> = nil
): TNtxStatus;

// Check if a thread wait timed out
function RtlxThreadSyncTimedOut(
  const Status: TNtxStatus
): Boolean;

// Create a thread to execute the code and wait for its complition.
// - On success, forwards the status
// - On failure, prolongs lifetime of the remote memory
function RtlxRemoteExecute(
  [Access(PROCESS_REMOTE_EXECUTE)] hProcess: THandle;
  const StatusLocation: String;
  [in] Code: Pointer;
  CodeSize: NativeUInt;
  [in, opt] Context: Pointer;
  ThreadFlags: TThreadCreateFlags = 0;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT;
  [opt] const MemoryToCapture: TArray<IMemory> = nil
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
  Info: TThreadBasicInformation;
  i: Integer;
begin
  // Wait for the thread
  Result := NtxWaitForSingleObject(hThread, Timeout);

  // Make timeouts unsuccessful
  if Result.Status = STATUS_TIMEOUT then
  begin
    Result.Status := STATUS_WAIT_TIMEOUT;

    // The thread did't terminate in time. We can't release the memory it uses.
    for i := 0 to High(MemoryToCapture) do
      MemoryToCapture[i].AutoRelease := False;
  end;

  // Get exit status
  if Result.IsSuccess then
    Result := NtxThread.Query(hThread, ThreadBasicInformation, Info);

  // Forward it
  if Result.IsSuccess then
  begin
    Result.Location := StatusLocation;
    Result.Status := Info.ExitStatus;
  end;
end;

function RtlxThreadSyncTimedOut;
begin
  Result := Status.Matches(STATUS_WAIT_TIMEOUT, 'NtWaitForSingleObject')
end;

function RtlxRemoteExecute;
var
  hxThread: IHandle;
begin
  if CodeSize > 0 then
    // We modified the executable memory recently, invalidate the cache
    NtxFlushInstructionCache(hProcess, Code, CodeSize);

  // Create a thread to execute the code
  Result := NtxCreateThread(hxThread, hProcess, Code, Context);

  if not Result.IsSuccess then
    Exit;

  // Synchronize with the thread; prolong remote memory lifetime on timeout
  Result := RtlxSyncThread(hxThread.Handle, StatusLocation, Timeout,
    MemoryToCapture);
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
