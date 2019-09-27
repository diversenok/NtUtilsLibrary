unit NtUtils.Processes.Snapshots;

interface

uses
  Ntapi.ntexapi, NtUtils.Exceptions;

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

  TProcessFilter = function (const ProcessEntry: TProcessEntry;
    Parameter: NativeUInt): Boolean;

  TFilterAction = (ftInclude, ftExclude);

// Snapshot active processes on the system
function NtxEnumerateProcesses(out Processes: TArray<TProcessEntry>):
  TNtxStatus;

// Filter specific processes from the snapshot
procedure NtxFilterProcessess(var Processes: TArray<TProcessEntry>;
  Filter: TProcessFilter; Parameter: NativeUInt; Action: TFilterAction);

procedure NtxFilterProcessessByImage(var Processes: TArray<TProcessEntry>;
  ImageName: String; Action: TFilterAction);

// Find a process in the snapshot by PID
function NtxFindProcessById(Processes: TArray<TProcessEntry>;
  PID: NativeUInt): PProcessEntry;

// Find all exiting parent-child relationships in the process list
function NtxBuildProcessTree(Processes: TArray<TProcessEntry>):
  TArray<TProcessTreeNode>;

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
  // On my notebook I usually have ~75 processes with ~850 threads, so it's
  // about 100 KB of data.

  // We don't want to use a huge initial buffer since system spends
  // more time probing it rather than enumerating the processes.

  BufferSize := 256 * 1024;
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

procedure NtxFilterProcessess(var Processes: TArray<TProcessEntry>;
  Filter: TProcessFilter; Parameter: NativeUInt; Action: TFilterAction);
var
  FilteredProcesses: TArray<TProcessEntry>;
  Count, i, j: Integer;
begin
  Assert(Assigned(Filter));

  Count := 0;
  for i := 0 to High(Processes) do
    if Filter(Processes[i], Parameter) xor (Action = ftExclude) then
      Inc(Count);

  SetLength(FilteredProcesses, Count);

  j := 0;
  for i := 0 to High(Processes) do
    if Filter(Processes[i], Parameter) xor (Action = ftExclude) then
    begin
      FilteredProcesses[j] := Processes[i];
      Inc(j);
    end;

  Processes := FilteredProcesses;
end;

function FilterByImage(const ProcessEntry: TProcessEntry;
  Parameter: NativeUInt): Boolean;
begin
  Result := (ProcessEntry.ImageName = String(PWideChar(Parameter)));
end;

procedure NtxFilterProcessessByImage(var Processes: TArray<TProcessEntry>;
  ImageName: String; Action: TFilterAction);
begin
  NtxFilterProcessess(Processes, FilterByImage,
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

end.
