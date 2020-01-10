unit NtUtils.Processes.Snapshots;

interface

uses
  Ntapi.ntexapi, NtUtils.Exceptions, DelphiUtils.Arrays;

type
  TSystemThreadInformation = Ntapi.ntexapi.TSystemThreadInformation;

  TProcessEntry = record
    ImageName: String;
    Process: TSystemProcessInformationFixed;
    Threads: TArray<TSystemThreadInformation>;
  end;
  PProcessEntry = ^TProcessEntry;

// Snapshot active processes on the system
function NtxEnumerateProcesses(out Processes: TArray<TProcessEntry>):
  TNtxStatus;

procedure NtxFilterProcessessByImage(var Processes: TArray<TProcessEntry>;
  ImageName: String; Action: TFilterAction = ftKeep);

// Find a process in the snapshot by PID
function NtxFindProcessById(Processes: TArray<TProcessEntry>;
  PID: NativeUInt): PProcessEntry;

// A parent checker to use with TArrayHelper.BuildTree<TProcessEntry>
function IsParentProcess(const Parent, Child: TProcessEntry): Boolean;

// Enumerate processes and build a process tree
function NtxEnumerateProcessesEx(out ProcessTree:
  TArray<TTreeNode<TProcessEntry>>): TNtxStatus;

// TODO: NtxEnumerateProcessesOfSession

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef;

function NtxEnumerateProcesses(out Processes: TArray<TProcessEntry>):
  TNtxStatus;
var
  BufferSize, ReturnLength: Cardinal;
  Buffer, pProcess: PSystemProcessInformation;
  Count, i, j: Integer;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(SystemProcessInformation);
  Result.LastCall.InfoClassType := TypeInfo(TSystemInformationClass);

  //  - x86: 184 bytes per process + 64 bytes per thread + ImageName
  //  - x64: 256 bytes per process + 80 bytes per thread + ImageName
  //
  // On my system it's usually about 150 processes with 1.5k threads, so it's
  // about 200 KB of data.

  // We don't want to use a huge initial buffer since system spends
  // more time probing it rather than enumerating the processes.

  BufferSize := 384 * 1024;
  repeat
    Buffer := AllocMem(BufferSize);

    ReturnLength := 0;
    Result.Status := NtQuerySystemInformation(SystemProcessInformation,
      Buffer, BufferSize, @ReturnLength);

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, ReturnLength);

  if not Result.IsSuccess then
    Exit;

  // Count processes
  Count := 0;
  pProcess := Buffer;

  repeat
    Inc(Count);

    if pProcess.Process.NextEntryOffset = 0 then
      Break
    else
      pProcess := Offset(pProcess, pProcess.Process.NextEntryOffset);
  until False;

  SetLength(Processes, Count);

  // Iterate through processes
  j := 0;
  pProcess := Buffer;

  repeat
    // Save process information
    Processes[j].Process := pProcess.Process;
    Processes[j].ImageName := pProcess.Process.ImageName.ToString;
    Processes[j].Process.ImageName.Buffer := PWideChar(Processes[j].ImageName);

    if pProcess.Process.ProcessId = 0 then
      Processes[j].ImageName := 'System Idle Process';

    // Save each thread information
    SetLength(Processes[j].Threads, pProcess.Process.NumberOfThreads);

    for i := 0 to High(Processes[j].Threads) do
      Processes[j].Threads[i] := pProcess.Threads{$R-}[i]{$R+};

    // Proceed to the next process
    if pProcess.Process.NextEntryOffset = 0 then
      Break
    else
      pProcess := Offset(pProcess, pProcess.Process.NextEntryOffset);

    Inc(j);
  until False;

  FreeMem(Buffer);
end;

function FilterByImage(const ProcessEntry: TProcessEntry;
  Parameter: NativeUInt): Boolean;
begin
  Result := (ProcessEntry.ImageName = PWideChar(Parameter));
end;

procedure NtxFilterProcessessByImage(var Processes: TArray<TProcessEntry>;
  ImageName: String; Action: TFilterAction);
begin
  TArrayHelper.Filter<TProcessEntry>(Processes, FilterByImage,
    NativeUInt(PWideChar(ImageName)), Action);
end;

function NtxFindProcessById(Processes: TArray<TProcessEntry>;
  PID: NativeUInt): PProcessEntry;
var
  i: Integer;
begin
  for i := 0 to High(Processes) do
    if Processes[i].Process.ProcessId = PID then
      Exit(@Processes[i]);

  Result := nil;
end;

function IsParentProcess(const Parent, Child: TProcessEntry): Boolean;
begin
  // Note: since PIDs can be reused we need to ensure
  // that parents were created earlier than childer.

  Result := (Child.Process.InheritedFromProcessId = Parent.Process.ProcessId)
    and (Child.Process.CreateTime.QuadPart > Parent.Process.CreateTime.QuadPart)
end;

function NtxEnumerateProcessesEx(out ProcessTree:
  TArray<TTreeNode<TProcessEntry>>): TNtxStatus;
var
  Processes: TArray<TProcessEntry>;
begin
  Result := NtxEnumerateProcesses(Processes);

  if Result.IsSuccess then
    ProcessTree := TArrayHelper.BuildTree<TProcessEntry>(Processes,
      IsParentProcess);
end;

end.
