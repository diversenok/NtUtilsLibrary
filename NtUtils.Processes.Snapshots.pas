unit NtUtils.Processes.Snapshots;

interface

uses
  Winapi.WinNt, Ntapi.ntexapi, NtUtils.Exceptions, NtUtils.Security.Sid,
  DelphiUtils.Arrays, NtUtils.Version, DelphiApi.Reflection;

type
  // Process snapshotting mode
  TPsSnapshotMode = (
    psNormal,   // Basic info about processes & threads
    psSession,  // Same as normal, but only within one session
    psExtended, // Some additiona info about threads
    psFull      // Everything (requires Administrator or NT SERVICE\DPS)
  );

  TProcessFullExtension = record
    [Aggregate] DiskCounters: TProcessDiskCounters;
    ContextSwitches: UInt64;
    [Bitwise(TProcessExtFlagsProvider)] Flags: Cardinal;
    Classification: TSystemProcessClassification;
    User: ISid;

    [MinOSVersion(OsWin10RS2)] PackageFullName: String;
    [MinOSVersion(OsWin10RS2)] EnergyValues: TProcessEnergyValues;
    [MinOSVersion(OsWin10RS2)] AppID: String;
    [MinOSVersion(OsWin10RS2)] SharedCommitCharge: NativeUInt;
    [MinOSVersion(OsWin10RS2)] JobObjectID: Cardinal;
    [MinOSVersion(OsWin10RS2)] ProcessSequenceNumber: UInt64;
  end;

  TThreadEntry = record
    [Aggregate] Basic: TSystemThreadInformation;
    [Aggregate] Extended: TSystemThreadInformationExtension; // extended & full
  end;

  TProcessEntry = record
    ImageName: String; // including path in case of full mode
    Basic: TSystemProcessInformationFixed;
    Full: TProcessFullExtension; // full only
    Threads: TArray<TThreadEntry>; // see above
  end;
  PProcessEntry = ^TProcessEntry;

// Snapshot processes on the system
function NtxEnumerateProcesses(out Processes: TArray<TProcessEntry>; Mode:
  TPsSnapshotMode = psNormal; SessionId: Cardinal = Cardinal(-1)): TNtxStatus;

{ Helper function }

// Filter processes by image
function ByImage(ImageName: String): TFilterRoutine<TProcessEntry>;

// A parent checker to use with TArrayHelper.BuildTree<TProcessEntry>
function ParentProcessChecker(const Parent, Child: TProcessEntry): Boolean;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef;

function NtxpExtractProcesses(Buffer: Pointer): TArray<Pointer>;
var
  pProcess: PSystemProcessInformationFixed;
  Count, i: Integer;
begin
  // Count processes
  Count := 0;
  pProcess := Buffer;

  repeat
    Inc(Count);

    if pProcess.NextEntryOffset = 0 then
      Break
    else
      pProcess := Offset(pProcess, pProcess.NextEntryOffset);
  until False;

  SetLength(Result, Count);

  // Iterate
  i := 0;
  pProcess := Buffer;

  repeat
    // Save
    Result[i] := pProcess;

    // Find the next entry
    if pProcess.NextEntryOffset = 0 then
      Break
    else
      pProcess := Offset(pProcess, pProcess.NextEntryOffset);

    Inc(i);
  until False;
end;

function NtxpParseProcesses(Buffer: Pointer; Mode: TPsSnapshotMode):
  TArray<TProcessEntry>;
var
  Processes: TArray<Pointer>;
  pProcess: PSystemProcessInformation;
  pProcessExtended: PSystemExtendedProcessInformation;
  pFullInfo: PSystemProcessInformationExtension;
  HasWin10RS2: Boolean;
  i, j: Integer;
begin
  Processes := NtxpExtractProcesses(Buffer);
  SetLength(Result, Length(Processes));

  // Some parts of the full information depend on the version
  HasWin10RS2 := (Mode = psFull) and RtlOsVersionAtLeast(OsWin10RS2);

  for i := 0 to High(Processes) do
  begin
    pProcess := Processes[i];
    pProcessExtended := Processes[i];

    // Save process (the structure is the same)
    Result[i].Basic := pProcess.Process;
    Result[i].ImageName := pProcess.Process.ImageName.ToString;
    Result[i].Basic.ImageName.Buffer := PWideChar(Result[i].ImageName);

    if pProcess.Process.ProcessId = 0 then
      Result[i].ImageName := 'System Idle Process';

    // Save threads
    SetLength(Result[i].Threads, pProcess.Process.NumberOfThreads);

    case Mode of
      psExtended, psFull:
        for j := 0 to High(Result[i].Threads) do
          with Result[i].Threads[j] do
          begin
            // Save both basic and extended
            Basic := pProcessExtended.Threads{$R-}[j]{$R+}.ThreadInfo;
            Extended := pProcessExtended.Threads{$R-}[j]{$R+}.Extension;
          end

    else
      // Basic only
      for j := 0 to High(Result[i].Threads) do
        Result[i].Threads[j].Basic := pProcess.Threads{$R-}[j]{$R+};
    end;

    if Mode = psFull then
    begin
      // Full information follows the threads
      pFullInfo := PSystemProcessInformationExtension(@pProcessExtended.
        Threads{$R-}[pProcessExtended.Process.NumberOfThreads]{$R+});

      // Capture it
      with Result[i].Full do
      begin
        DiskCounters := pFullInfo.DiskCounters;
        ContextSwitches := pFullInfo.ContextSwitches;
        Flags := pFullInfo.Flags and SYSTEM_PROCESS_VALID_MASK;
        Classification := pFullInfo.Classification;

        if pFullInfo.UserSidOffset <> 0 then
          RtlxCaptureCopySid(pFullInfo.UserSid, User);

        if HasWin10RS2 then
        begin
          PackageFullName := pFullInfo.PackageFullName;
          EnergyValues := pFullInfo.EnergyValues;
          AppId := pFullInfo.AppId;
          SharedCommitCharge := pFullInfo.SharedCommitCharge;
          JobObjectId := pFullInfo.JobObjectId;
          ProcessSequenceNumber := pFullInfo.ProcessSequenceNumber;
        end;
      end;
    end;
  end;
end;

function NtxEnumerateSessionProcesses(SessionId: Cardinal;
  out Processes: TArray<TProcessEntry>): TNtxStatus;
var
  ReturnLength: Cardinal;
  Data: TSystemSessionProcessInformation;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(SystemSessionProcessInformation);
  Result.LastCall.InfoClassType := TypeInfo(TSystemInformationClass);

  // Prepare the request that we pass as an input.
  // It describes the buffer to fill, and contains the session ID.
  Data.SessionId := SessionId;
  Data.SizeOfBuf := 192 * 1024;

  repeat
    Data.Buffer := AllocMem(Data.SizeOfBuf);

    ReturnLength := 0;
    Result.Status := NtQuerySystemInformation(SystemSessionProcessInformation,
      @Data, SizeOf(Data), @ReturnLength);

    if not Result.IsSuccess then
      FreeMem(Data.Buffer);

    // ReturnLength is the size of the required buffer for SizeOfBuf field
  until not NtxExpandBuffer(Result, Data.SizeOfBuf, ReturnLength);

  if not Result.IsSuccess then
    Exit;

  Processes := NtxpParseProcesses(Data.Buffer, psSession);
  FreeMem(Data.Buffer);
end;

function NtxEnumerateProcesses(out Processes: TArray<TProcessEntry>; Mode:
  TPsSnapshotMode = psNormal; SessionId: Cardinal = Cardinal(-1)): TNtxStatus;
const
  InitialBuffer: array [TPsSnapshotMode] of Cardinal = (
    384 * 1024, 192 * 1024, 576 * 1024, 640 * 1024);
var
  InfoClass: TSystemInformationClass;
  BufferSize, ReturnLength: Cardinal;
  Buffer: PSystemProcessInformation;
begin
  case Mode of
    psNormal:   InfoClass := SystemProcessInformation;
    psExtended: InfoClass := SystemExtendedProcessInformation;
    psFull:     InfoClass := SystemFullProcessInformation;
  else
    Result := NtxEnumerateSessionProcesses(SessionId, Processes);
    Exit;
  end;

  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TSystemInformationClass);

  // We don't want to use a huge initial buffer since system spends
  // more time probing it rather than enumerating the processes.

  BufferSize := InitialBuffer[Mode];
  repeat
    Buffer := AllocMem(BufferSize);

    ReturnLength := 0;
    Result.Status := NtQuerySystemInformation(InfoClass, Buffer, BufferSize,
      @ReturnLength);

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, ReturnLength);

  if not Result.IsSuccess then
    Exit;

  Processes := NtxpParseProcesses(Buffer, Mode);
  FreeMem(Buffer);
end;

{ Helper functions }

function ByImage(ImageName: String): TFilterRoutine<TProcessEntry>;
begin
  Result := function (const ProcessEntry: TProcessEntry): Boolean
    begin
      Result := ProcessEntry.ImageName = ImageName;
    end;
end;

function NtxFindProcessById(Processes: TArray<TProcessEntry>;
  PID: NativeUInt): PProcessEntry;
var
  i: Integer;
begin
  for i := 0 to High(Processes) do
    if Processes[i].Basic.ProcessId = PID then
      Exit(@Processes[i]);

  Result := nil;
end;

function ParentProcessChecker(const Parent, Child: TProcessEntry): Boolean;
begin
  // Note: since PIDs can be reused we need to ensure
  // that parents were created earlier than childer.

  Result := (Child.Basic.InheritedFromProcessId = Parent.Basic.ProcessId)
    and (Child.Basic.CreateTime > Parent.Basic.CreateTime)
end;

end.
