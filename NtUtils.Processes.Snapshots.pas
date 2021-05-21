unit NtUtils.Processes.Snapshots;

{
  This module provides several modes of process enumeration.
}

interface

uses
  Winapi.WinNt, Ntapi.ntexapi, Ntapi.ntdef, Ntapi.ntpsapi, NtUtils.Version,
  DelphiApi.Reflection, DelphiUtils.Arrays, NtUtils;

type
  TProcessOpenByNameOptions = set of (
    pnCurrentSessionOnly,
    pnAllowAmbiguousMatch,
    pnAllowShortNames,
    pnCaseSensitive
  );

  TProcessImageFilterOptions = set of (
    pfAllowShortNames,
    pfCaseSensitive
  );

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
    Flags: TProcessExtFlags;
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
function NtxEnumerateProcesses(
  out Processes: TArray<TProcessEntry>;
  Mode: TPsSnapshotMode = psNormal;
  SessionId: TSessionId = TSessionId(-1)
): TNtxStatus;

// Open a process by an image name
function NtxOpenProcessByName(
  out hxProcess: IHandle;
  const ImageName: String;
  DesiredAccess: TProcessAccessMask;
  Options: TProcessOpenByNameOptions = [];
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

{ Helper functions }

// Filter processes by image
function ByImage(
  const ImageName: String;
  Options: TProcessImageFilterOptions = []
): TCondition<TProcessEntry>;

// Filter processes by ID
function ByPid(
  PID: TProcessId
): TCondition<TProcessEntry>;

// Find a processs in the snapshot using a process ID
function NtxFindProcessById(
  const Processes: TArray<TProcessEntry>;
  PID: TProcessId
): PProcessEntry;

// Find a processs in the snapshot using a thread ID
function NtxFindProcessByThreadId(
  const Processes: TArray<TProcessEntry>;
  TID: TThreadId
): PProcessEntry;

// A parent checker to use with TArrayHelper.BuildTree<TProcessEntry>
function ParentProcessChecker(
  const Parent: TProcessEntry;
  const Child: TProcessEntry
): Boolean;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpebteb, NtUtils.Security.Sid, NtUtils.System,
  NtUtils.Processes, NtUtils.SysUtils;

function NtxpExtractProcesses([in] Buffer: Pointer): TArray<Pointer>;
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
      pProcess := Pointer(UIntPtr(pProcess) + pProcess.NextEntryOffset);
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
      pProcess := Pointer(UIntPtr(pProcess) + pProcess.NextEntryOffset);

    Inc(i);
  until False;
end;

function NtxpParseProcesses(
  [in] Buffer: Pointer;
  Mode: TPsSnapshotMode
): TArray<TProcessEntry>;
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
          RtlxCopySid(pFullInfo.UserSid, User);

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

function NtxEnumerateSessionProcesses(
  SessionId: TSessionId;
  out Processes: TArray<TProcessEntry>
): TNtxStatus;
var
  xMemory: IMemory;
  Required: Cardinal;
  Data: TSystemSessionProcessInformation;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.AttachInfoClass(SystemSessionProcessInformation);

  // Use provided session or fallback to the current one
  if SessionId = TSessionId(-1) then
    Data.SessionId := RtlGetCurrentPeb.SessionID
  else
    Data.SessionId := SessionId;

  xMemory := TAutoMemory.Allocate(Data.SizeOfBuf);
  repeat
    // Prepare the request that we pass as an input.
    // It describes the buffer to fill and contains the session ID.
    Data.SizeOfBuf := xMemory.Size;
    Data.Buffer := xMemory.Data;

    Required := 0;
    Result.Status := NtQuerySystemInformation(SystemSessionProcessInformation,
      @Data, SizeOf(Data), @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, Grow12Percent);

  if Result.IsSuccess then
    Processes := NtxpParseProcesses(xMemory.Data, psSession);
end;

function NtxEnumerateProcesses;
const
  // We don't want to use a huge initial buffer since system spends
  // more time probing it rather than enumerating processes.
  InitialBuffer: array [TPsSnapshotMode] of Cardinal = (
    384 * 1024, 192 * 1024, 576 * 1024, 640 * 1024);
var
  InfoClass: TSystemInformationClass;
  Memory: IMemory;
begin
  case Mode of
    psNormal:   InfoClass := SystemProcessInformation;
    psExtended: InfoClass := SystemExtendedProcessInformation;
    psFull:     InfoClass := SystemFullProcessInformation;
  else
    Result := NtxEnumerateSessionProcesses(SessionId, Processes);
    Exit;
  end;

  Result := NtxQuerySystem(InfoClass, Memory, InitialBuffer[Mode],
    Grow12Percent);

  if Result.IsSuccess then
    Processes := NtxpParseProcesses(Memory.Data, Mode);
end;

function NtxOpenProcessByName;
var
  Mode: TPsSnapshotMode;
  Processes: TArray<TProcessEntry>;
  FilterOptions: TProcessImageFilterOptions;
  i: Integer;
begin
  if pnCurrentSessionOnly in Options then
    Mode := psSession
  else
    Mode := psNormal;

  // Find all processes
  Result := NtxEnumerateProcesses(Processes, Mode);

  FilterOptions := [];

  if pnAllowShortNames in Options then
    Include(FilterOptions, pfAllowShortNames);

  if pnCaseSensitive in Options then
    Include(FilterOptions, pfCaseSensitive);

  // Keep only matching image names
  TArray.FilterInline<TProcessEntry>(Processes, ByImage(ImageName,
    FilterOptions));

  if Length(Processes) = 0 then
  begin
    Result.Location := 'NtxOpenProcessByName';
    Result.Status := STATUS_NOT_FOUND;
    Exit;
  end;

  if not (pnAllowAmbiguousMatch in Options) and (Length(Processes) > 1) then
  begin
    // Ambiguous match is not allowed
    Result.Location := 'NtxOpenProcessByName';
    Result.Status := STATUS_OBJECT_NAME_COLLISION;
    Exit;
  end;

  // Open the first one we can access
  for i := 0 to High(Processes) do
    if NtxOpenProcess(hxProcess, Processes[0].Basic.ProcessID, DesiredAccess,
      HandleAttributes).Save(Result) then
      Break;
end;

{ Helper functions }

function ByPid;
begin
  Result := function (const ProcessEntry: TProcessEntry): Boolean
    begin
      Result := ProcessEntry.Basic.ProcessID = PID;
    end;
end;

function ByImage;
begin
  Result := function (const ProcessEntry: TProcessEntry): Boolean
    begin
      Result := RtlxCompareStrings(ProcessEntry.ImageName, ImageName,
        pfCaseSensitive in Options) = 0;

      if not Result and (pfAllowShortNames in Options) then
        Result := RtlxCompareStrings(ProcessEntry.ImageName, ImageName + '.exe',
        pfCaseSensitive in Options) = 0;
    end;
end;

function NtxFindProcessById;
var
  i: Integer;
begin
  for i := 0 to High(Processes) do
    if Processes[i].Basic.ProcessId = PID then
      Exit(@Processes[i]);

  Result := nil;
end;

function NtxFindProcessByThreadId;
var
  i, j: Integer;
begin
  for i := 0 to High(Processes) do
    for j := 0 to High(Processes[i].Threads) do
      if Processes[i].Threads[j].Basic.ClientID.UniqueThread = TID then
        Exit(@Processes[i]);

  Result := nil;
end;

function ParentProcessChecker;
begin
  // Note: since PIDs can be reused we need to ensure
  // that parents were created earlier than childer.

  Result := (Child.Basic.InheritedFromProcessId = Parent.Basic.ProcessId)
    and (Child.Basic.CreateTime > Parent.Basic.CreateTime)
end;

end.
