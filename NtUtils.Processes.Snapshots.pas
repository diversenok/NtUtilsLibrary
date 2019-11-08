unit NtUtils.Processes.Snapshots;

interface

uses
  Ntapi.ntexapi, NtUtils.Exceptions, DelphiUtils.Arrays;

type
  TProcessEntry = record
    ImageName: String;
    Process: TSystemProcessInformationFixed;
    Threads: array of TSystemThreadInformation;
  end;
  PProcessEntry = ^TProcessEntry;

  PProcessTreeNode = ^TProcessTreeNode;
  TProcessTreeNode = record
    Entry: TProcessEntry;
    Parent: PProcessTreeNode;
    Children: array of PProcessTreeNode;
  end;

// Snapshot active processes on the system
function NtxEnumerateProcesses(out Processes: TArray<TProcessEntry>):
  TNtxStatus;

procedure NtxFilterProcessessByImage(var Processes: TArray<TProcessEntry>;
  ImageName: String; Action: TFilterAction = ftKeep);

// Find a process in the snapshot by PID
function NtxFindProcessById(Processes: TArray<TProcessEntry>;
  PID: NativeUInt): PProcessEntry;

// Find all exiting parent-child relationships in the process list
function NtxBuildProcessTree(Processes: TArray<TProcessEntry>):
  TArray<TProcessTreeNode>;

// Enumerate processes and build a process tree
function NtxEnumerateProcessesEx(out ProcessTree: TArray<TProcessTreeNode>):
  TNtxStatus;

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
  TArrayFilter.Filter<TProcessEntry>(Processes, FilterByImage,
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

function NtxpIsParentProcess(const Parent, Child: TProcessEntry): Boolean;
begin
  // Note: since PIDs can be reused we need to ensure
  // that parents were created earlier than childer.

  Result := (Child.Process.InheritedFromProcessId = Parent.Process.ProcessId)
    and (Child.Process.CreateTime.QuadPart > Parent.Process.CreateTime.QuadPart)
end;

function NtxBuildProcessTree(Processes: TArray<TProcessEntry>):
  TArray<TProcessTreeNode>;
var
  i, j, k, Count: Integer;
begin
  SetLength(Result, Length(Processes));

  // Copy process entries
  for i := 0 to High(Processes) do
    Result[i].Entry := Processes[i];

  // Fill parents as references to array elements
  for i := 0 to High(Processes) do
    for j := 0 to High(Processes) do
      if NtxpIsParentProcess(Processes[j], Processes[i]) then
      begin
        Result[i].Parent := @Result[j];
        Break;
      end;

  // Fill children, also as references
  for i := 0 to High(Processes) do
  begin
    Count := 0;
    for j := 0 to High(Processes) do
      if Result[j].Parent = @Result[i] then
        Inc(Count);

    SetLength(Result[i].Children, Count);

    k := 0;
    for j := 0 to High(Processes) do
      if Result[j].Parent = @Result[i] then
      begin
        Result[i].Children[k] := @Result[j];
        Inc(k);
      end;
  end;
end;

function NtxEnumerateProcessesEx(out ProcessTree: TArray<TProcessTreeNode>):
  TNtxStatus;
var
  Processes: TArray<TProcessEntry>;
begin
  Result := NtxEnumerateProcesses(Processes);

  if Result.IsSuccess then
    ProcessTree := NtxBuildProcessTree(Processes);
end;

end.
