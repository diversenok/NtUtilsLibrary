unit NtUtils.Shellcode;

interface

uses
  Winapi.WinNt, Ntapi.ntpsapi, NtUtils;

const
  PROCESS_REMOTE_EXECUTE = PROCESS_QUERY_LIMITED_INFORMATION or
    PROCESS_CREATE_THREAD or PROCESS_VM_OPERATION or PROCESS_VM_WRITE;

  DEFAULT_REMOTE_TIMEOUT = 5000 * MILLISEC;

// Copy data & code into the process
function RtlxAllocWriteDataCodeProcess(hxProcess: IHandle; const Data: TMemory;
  out RemoteData: IMemory; const Code: TMemory; out RemoteCode: IMemory;
  EnsureWoW64Accessible: Boolean = False): TNtxStatus;

// Wait for a thread & forward it exit status. If the wait times out, prevent
// the memory from automatic deallocation (the thread might still use it).
function RtlxSyncThread(hThread: THandle; StatusLocation: String; Timeout:
  Int64 = NT_INFINITE; MemoryToCapture: TArray<IMemory> = nil): TNtxStatus;

// Check if a thread wait timed out
function RtlxThreadSyncTimedOut(const Status: TNtxStatus): Boolean;

// Copy the code into the target, execute it, and wait for completion
function RtlxRemoteExecute(hxProcess: IHandle; const Code, Context: TMemory;
  StatusLocation: String; TargetIsWow64: Boolean = False; Timeout: Int64 =
  DEFAULT_REMOTE_TIMEOUT): TNtxStatus;

{ Export location }

// Locate export in a known native dll
function RtlxFindKnownDllExportsNative(DllName: String;
  Names: TArray<AnsiString>; out Addresses: TArray<Pointer>): TNtxStatus;

{$IFDEF Win64}
// Locate export in known WoW64 dll
function RtlxFindKnownDllExportsWoW64(DllName: String;
  Names: TArray<AnsiString>; out Addresses: TArray<Pointer>): TNtxStatus;
{$ENDIF}

// Locate export in a known dll
function RtlxFindKnownDllExports(DllName: String; TargetIsWoW64: Boolean;
  Names: TArray<AnsiString>; out Addresses: TArray<Pointer>): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, NtUtils.Processes.Memory, NtUtils.Threads,
  NtUtils.Ldr, NtUtils.ImageHlp, NtUtils.Sections, NtUtils.Objects;

function RtlxAllocWriteDataCodeProcess(hxProcess: IHandle; const Data: TMemory;
  out RemoteData: IMemory; const Code: TMemory; out RemoteCode: IMemory;
  EnsureWoW64Accessible: Boolean): TNtxStatus;
begin
  // Copy RemoteData into the process
  Result := NtxAllocWriteMemoryProcess(hxProcess, Data, RemoteData,
    EnsureWoW64Accessible);

  // Copy RemoteCode into the process
  if Result.IsSuccess then
    Result := NtxAllocWriteExecMemoryProcess(hxProcess, Code, RemoteCode,
      EnsureWoW64Accessible);

  // Undo allocations on failure
  if not Result.IsSuccess then
  begin
    RemoteData := nil;
    RemoteCode := nil;
  end;
end;

function RtlxSyncThread(hThread: THandle; StatusLocation: String; Timeout:
  Int64; MemoryToCapture: TArray<IMemory>): TNtxStatus;
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

function RtlxThreadSyncTimedOut(const Status: TNtxStatus): Boolean;
begin
  Result := Status.Matches(STATUS_WAIT_TIMEOUT, 'NtWaitForSingleObject')
end;

function RtlxRemoteExecute(hxProcess: IHandle; const Code, Context: TMemory;
  StatusLocation: String; TargetIsWow64: Boolean; Timeout: Int64): TNtxStatus;
var
  RemoteCode, RemoteContext: IMemory;
  hxThread: IHandle;
begin
  // Allocate and copy everything to the target
  Result := RtlxAllocWriteDataCodeProcess(hxProcess, Context, RemoteContext,
    Code, RemoteCode, TargetIsWow64);

  if not Result.IsSuccess then
    Exit;

  // Create a thread to execute the code
  Result := NtxCreateThread(hxThread, hxProcess.Handle, RemoteCode.Data,
    RemoteContext.Data);

  if not Result.IsSuccess then
    Exit;

  // Synchronize with the thread
  Result := RtlxSyncThread(hxThread.Handle, StatusLocation, Timeout);
end;

function RtlxFindKnownDllExportsNative(DllName: String;
  Names: TArray<AnsiString>; out Addresses: TArray<Pointer>): TNtxStatus;
var
  i: Integer;
  DllHandle: HMODULE;
begin
  Result := LdrxGetDllHandle(DllName, DllHandle);

  if not Result.IsSuccess then
    Exit;

  SetLength(Addresses, Length(Names));

  for i := 0 to High(Names) do
  begin
    Addresses[i] := LdrxGetProcedureAddress(DllHandle, Names[i], Result);

    if not Result.IsSuccess then
      Exit;
  end;
end;

{$IFDEF Win64}
function RtlxFindKnownDllExportsWoW64(DllName: String;
  Names: TArray<AnsiString>; out Addresses: TArray<Pointer>): TNtxStatus;
var
  hxSection: IHandle;
  MappedMemory: IMemory;
  AllEntries: TArray<TExportEntry>;
  pEntry: PExportEntry;
  i: Integer;
begin
  // Map 32-bit dll
  Result := RtlxMapKnownDll(hxSection, DllName, True, MappedMemory);

  if not Result.IsSuccess then
    Exit;

  // Parse its export table
  Result := RtlxEnumerateExportImage(MappedMemory.Data,
    Cardinal(MappedMemory.Size), True, AllEntries);

  if not Result.IsSuccess then
    Exit;

  SetLength(Addresses, Length(Names));

  for i := 0 to High(Names) do
  begin
    pEntry := RtlxFindExportedName(AllEntries, Names[i]);

    if not Assigned(pEntry) or pEntry.Forwards then
    begin
      Result.Location := 'RtlxpFindKnownDll32Export';
      Result.Status := STATUS_PROCEDURE_NOT_FOUND;
      Exit;
    end;

    Addresses[i] := PByte(MappedMemory.Data) + pEntry.VirtualAddress;
  end;
end;
{$ENDIF}

function RtlxFindKnownDllExports(DllName: String; TargetIsWoW64: Boolean;
  Names: TArray<AnsiString>; out Addresses: TArray<Pointer>): TNtxStatus;
begin
{$IFDEF Win64}
  if TargetIsWoW64 then
  begin
    // Native -> WoW64
    Result := RtlxFindKnownDllExportsWoW64(DllName, Names, Addresses);
    Exit;
  end;
{$ENDIF}

  // Native -> Native / WoW64 -> WoW64
  Result := RtlxFindKnownDllExportsNative(DllName, Names, Addresses);
end;

end.
