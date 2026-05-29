unit NtUtils.Processes.Snapshots;

{
  This module provides several modes of process enumeration.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntexapi, Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntseapi,
  Ntapi.Versions, DelphiApi.Reflection, DelphiUtils.Arrays, NtUtils;

type
  TNtxProcessOpenByNameOptions = set of (
    pnAllowAmbiguousMatch,
    pnAllowTerminated,
    pnAllowShortNames,
    pnAllowPIDs,
    pnCaseSensitive
  );

  TNtxProcessImageFilterOptions = set of (
    pfAllowShortNames,
    pfCaseSensitive
  );

  TNtxProcessFullExtension = record
    ImagePath: String;
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

  TNtxThreadEntry = record
    hxThread: IHandle;
    [Aggregate] Basic: TSystemThreadInformation;
    [Aggregate] Extended: TSystemThreadInformationExtension; // extended & full
  end;

  TNtxProcessEntry = record
    hxProcess: IHandle;
    IsTerminated: Boolean; // heuristics-based
    ImageName: String;
    Basic: TSystemProcessInformationFixed;
    Full: TNtxProcessFullExtension;
    Threads: TArray<TNtxThreadEntry>;
  end;
  PNtxProcessEntry = ^TNtxProcessEntry;

  TNtxProcessEnumerationMethod = function (
    out Processes: TArray<TNtxProcessEntry>
  ): TNtxStatus;

// Enumerate processes on the system via SystemProcessInformation
function NtxEnumerateProcesses(
  out Processes: TArray<TNtxProcessEntry>
): TNtxStatus;

// Enumerate processes on the system via SystemExtendedProcessInformation
function NtxEnumerateProcessesEx(
  out Processes: TArray<TNtxProcessEntry>
): TNtxStatus;

// Enumerate processes on the system via SystemFullProcessInformation
[RequiresAdmin]
function NtxEnumerateProcessesFull(
  out Processes: TArray<TNtxProcessEntry>
): TNtxStatus;

// Enumerate processes in a specific session via SystemSessionProcessInformation
function NtxEnumerateProcessesSession(
  out Processes: TArray<TNtxProcessEntry>;
  SessionId: TSessionId = TSessionId(-1)
): TNtxStatus;

// Enumerate processes in the current session via SystemSessionProcessInformation
function NtxEnumerateProcessesCurrentSession(
  out Processes: TArray<TNtxProcessEntry>
): TNtxStatus;

// Enumerate accessible processes via NtGetNextProcess
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxEnumerateProcessesGetNext(
  out Processes: TArray<TNtxProcessEntry>
): TNtxStatus;

// Enumerate processes on the system via FileProcessIdsUsingFileInformation
function NtxEnumerateProcessesByNtdll(
  out Processes: TArray<TNtxProcessEntry>
): TNtxStatus;

// Enumerate processes on the system via SystemProcessIdInformation
function NtxEnumerateProcessesBruteforce(
  out Processes: TArray<TNtxProcessEntry>
): TNtxStatus;

// Enumerate threads of a process on-demand via NtGetNextThread
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxEnumerateThreadsGetNext(
  var Process: TNtxProcessEntry
): TNtxStatus;

// Enumerate threads of a process on-demand via NtOpenThread
function NtxEnumerateThreadsBruteforce(
  var Process: TNtxProcessEntry
): TNtxStatus;

// Open a process by an image name
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function NtxOpenProcessByName(
  out hxProcess: IHandle;
  EnumerationMethod: TNtxProcessEnumerationMethod;
  const ImageName: String;
  DesiredAccess: TProcessAccessMask;
  Options: TNtxProcessOpenByNameOptions = [pnAllowShortNames, pnAllowPIDs];
  HandleAttributes: TObjectAttributesFlags = 0
): TNtxStatus;

{ Helper functions }

// Filter processes by image
function ByImage(
  const ImageName: String;
  Options: TNtxProcessImageFilterOptions = []
): TCondition<TNtxProcessEntry>;

// Filter processes by ID
function ByPid(
  PID: TProcessId
): TCondition<TNtxProcessEntry>;

// Find a process in the snapshot using a process ID
function NtxFindProcessById(
  const Processes: TArray<TNtxProcessEntry>;
  PID: TProcessId
): PNtxProcessEntry;

// Find a process in the snapshot using a thread ID
function NtxFindProcessByThreadId(
  const Processes: TArray<TNtxProcessEntry>;
  TID: TThreadId
): PNtxProcessEntry;

// An equality check to use with IHysteresisTree<TNtxProcessEntry>
function RtlxIsSameProcess(
  const A, B: TNtxProcessEntry
): Boolean;

// An equality check to use with IHysteresisTree<TNtxThreadEntry>
function RtlxIsSameThread(
  const A, B: TNtxThreadEntry
): Boolean;

// A parent check to use with TArray.BuildTree<TNtxProcessEntry> and
// IHysteresisTree<TNtxProcessEntry>
function RtlxIsParentProcess(
  const Parent: TNtxProcessEntry;
  ParentIndex: Integer;
  const Child: TNtxProcessEntry;
  ChildIndex: Integer
): Boolean;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpebteb, Ntapi.ntmmapi, Ntapi.ntobapi, NtUtils.System,
  NtUtils.Security.Sid, NtUtils.Processes, NtUtils.SysUtils, NtUtils.Threads,
  NtUtils.Files.Operations, NtUtils.Processes.Info, NtUtils.Objects.Snapshots;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxpExtractProcesses(
  [in] Buffer: PSystemProcessInformationFixed
): TArray<Pointer>;
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

procedure NtxpParseProcessExtension(
  out Extension: TNtxProcessFullExtension;
  Buffer: PSystemProcessInformationExtension
);
begin
  Extension.DiskCounters := Buffer.DiskCounters;
  Extension.ContextSwitches := Buffer.ContextSwitches;
  Extension.Flags := Buffer.Flags and SYSTEM_PROCESS_VALID_MASK;
  Extension.Classification := Buffer.Classification;

  if Buffer.UserSidOffset <> 0 then
    RtlxCopySid(Buffer.UserSid, Extension.User);

  if RtlOsVersionAtLeast(OsWin10RS2) then
  begin
    Extension.PackageFullName := Buffer.PackageFullName;
    Extension.EnergyValues := Buffer.EnergyValues;
    Extension.AppId := Buffer.AppId;
    Extension.SharedCommitCharge := Buffer.SharedCommitCharge;
    Extension.JobObjectId := Buffer.JobObjectId;
    Extension.ProcessSequenceNumber := Buffer.ProcessSequenceNumber;
  end;
end;

function NtxpParseProcesses(
  [in] Buffer: PSystemProcessInformationFixed;
  InfoClass: TSystemInformationClass
): TArray<TNtxProcessEntry>;
var
  Processes: TArray<Pointer>;
  pProcess: PSystemProcessInformation;
  pProcessExtended: PSystemExtendedProcessInformation;
  pThreadExtended: PSystemExtendedThreadInformation;
  i, j: Integer;
begin
  Processes := NtxpExtractProcesses(Buffer);
  SetLength(Result, Length(Processes));

  for i := 0 to High(Processes) do
  begin
    pProcess := Processes[i];
    pProcessExtended := Processes[i];

    // Save process (the structure is the same)
    Result[i].Basic := pProcess.Process;
    Result[i].ImageName := pProcess.Process.ImageName.ToString;

    if (pProcess.Process.ProcessId = 0) and (Result[i].ImageName = '') then
      Result[i].ImageName := 'System Idle Process';

    if InfoClass = SystemFullProcessInformation then
    begin
      // The full snapshot returns the full image path; extract the name
      // consistency but keep the full path in the full sub-structure
      Result[i].Full.ImagePath := Result[i].ImageName;
      Result[i].ImageName := RtlxExtractNamePath(Result[i].ImageName);
    end;

    Result[i].Basic.ImageName.Buffer := PWideChar(Result[i].ImageName);

    // Save threads
    SetLength(Result[i].Threads, pProcess.Process.NumberOfThreads);

    case InfoClass of
      SystemProcessInformation, SystemSessionProcessInformation:
        for j := 0 to High(Result[i].Threads) do
          // Basic only
          Result[i].Threads[j].Basic := pProcess
            .Threads{$R-}[j]{$IFDEF R+}{$R+}{$ENDIF};

      SystemExtendedProcessInformation, SystemFullProcessInformation:
      begin
        pThreadExtended := @pProcessExtended.Threads[0];

        for j := 0 to High(Result[i].Threads) do
        begin
          // Save both basic and extended
          Result[i].Threads[j].Basic := pThreadExtended.ThreadInfo;
          Result[i].Threads[j].Extended := pThreadExtended.Extension;
          Inc(pThreadExtended);
        end;

        // Full information follows the threads
        if InfoClass = SystemFullProcessInformation then
          NtxpParseProcessExtension(Result[i].Full, Pointer(pThreadExtended));
      end;
    end;
  end;
end;

function NtxEnumerateProcessesWorker(
  out Processes: TArray<TNtxProcessEntry>;
  InfoClass: TSystemInformationClass
): TNtxStatus;
const
  INITIAL_SIZE_NORMAL = 384 * 1024;
  INITIAL_SIZE_EXTENDED = 576 * 1024;
  INITIAL_SIZE_FULL = 640 * 1024;
var
  Memory: IMemory;
  InitialBuffer: Cardinal;
begin
  case InfoClass of
    SystemProcessInformation:         InitialBuffer := INITIAL_SIZE_NORMAL;
    SystemExtendedProcessInformation: InitialBuffer := INITIAL_SIZE_EXTENDED;
    SystemFullProcessInformation:     InitialBuffer := INITIAL_SIZE_FULL;
  else
    Error(reAssertionFailed);
    Exit;
  end;

  Result := NtxQuerySystem(InfoClass, Memory, InitialBuffer, Grow12Percent);

  if Result.IsSuccess then
    Processes := NtxpParseProcesses(Memory.Data, InfoClass);
end;

function NtxEnumerateProcesses;
begin
  Result := NtxEnumerateProcessesWorker(Processes, SystemProcessInformation);
end;

function NtxEnumerateProcessesEx;
begin
  Result := NtxEnumerateProcessesWorker(Processes,
    SystemExtendedProcessInformation);
end;

function NtxEnumerateProcessesFull;
begin
  Result := NtxEnumerateProcessesWorker(Processes,
    SystemFullProcessInformation);
end;

function NtxEnumerateProcessesSession;
const
  INITIAL_SIZE_SESSION = 192 * 1024;
var
  xMemory: IMemory;
  Required: Cardinal;
  Data: TSystemSessionProcessInformation;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.UsesInfoClass(SystemSessionProcessInformation, icQuery);

  // Use provided session or fallback to the current one
  if SessionId = TSessionId(-1) then
    Data.SessionId := RtlGetCurrentPeb.SessionID
  else
    Data.SessionId := SessionId;

  xMemory := Auto.AllocateDynamic(INITIAL_SIZE_SESSION);
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
    Processes := NtxpParseProcesses(xMemory.Data,
      SystemSessionProcessInformation);
end;

function NtxEnumerateProcessesCurrentSession;
begin
  Result := NtxEnumerateProcessesSession(Processes);
end;

function NtxEnumerateProcessesGetNext;
var
  hxProcess: IHandle;
  Entry: TNtxProcessEntry;
  Basic: TProcessBasicInformation;
begin
  for hxProcess in NtxIterateGetNextProcess(@Result,
    PROCESS_QUERY_LIMITED_INFORMATION) do
    if NtxProcess.Query(hxProcess, ProcessBasicInformation, Basic).IsSuccess then
    begin
      Entry := Default(TNtxProcessEntry);
      Entry.hxProcess := hxProcess;
      Entry.Basic.ProcessID := Basic.UniqueProcessID;
      Entry.Basic.InheritedFromProcessId := Basic.InheritedFromUniqueProcessID;

      // Technically not correct, but close enough for a heuristic
      Entry.IsTerminated := Basic.ExitStatus <> STATUS_PENDING;

      // Determine the image name
      NtxQueryImageNameProcessId(Basic.UniqueProcessID, Entry.Full.ImagePath);
      Entry.ImageName := RtlxExtractNamePath(Entry.Full.ImagePath);

      if (Basic.UniqueProcessID = SYSTEM_PID) and (Entry.ImageName = '') then
        Entry.ImageName := 'System';

      // Save
      SetLength(Processes, Succ(Length(Processes)));
      Processes[High(Processes)] := Entry;
    end;
end;

function NtxEnumerateProcessesByNtdll;
var
  PIDs: TArray<TProcessId>;
  i: Integer;
begin
  Result := NtxEnumerateUsingProcessesNtdll(PIDs);

  if not Result.IsSuccess then
    Exit;

  Processes := nil;
  SetLength(Processes, Length(PIDs));

  for i := 0 to High(PIDs) do
  begin
    Processes[i].Basic.ProcessID := PIDs[i];
    NtxQueryImageNameProcessId(PIDs[i], Processes[i].Full.ImagePath);
    Processes[i].ImageName := RtlxExtractNamePath(Processes[i].Full.ImagePath);

    if (PIDs[i] = SYSTEM_PID) and (Processes[i].ImageName = '') then
      Processes[i].ImageName := 'System';
  end;
end;

function RtlxQueryProcessThreadStats(
  out ProcessType: TNtxObjectTypeInfo;
  out ThreadType: TNtxObjectTypeInfo
): TNtxStatus;
var
  Types: TArray<TNtxObjectTypeInfo>;
  ProcessIndex, ThreadIndex, i: Integer;
begin
  // Collect types
  Result := NtxEnumerateKernelTypes(Types);

  if not Result.IsSuccess then
    Exit;

  // Locate the associated entries
  ProcessIndex := -1;
  ThreadIndex := -1;

  for i := 0 to High(Types) do
  begin
    if (ProcessIndex < 0) and (Types[i].TypeName = 'Process') then
      ProcessIndex := i
    else if (ThreadIndex < 0) and (Types[i].TypeName = 'Thread') then
      ThreadIndex := i;

    if (ProcessIndex >= 0) and (ThreadIndex >= 0) then
      Break;
  end;

  if (ProcessIndex < 0) or (ThreadIndex < 0) then
  begin
    Result.Location := 'RtlxQueryProcessThreadStats';
    Result.Status := STATUS_NOT_FOUND;
    Exit;
  end;

  ProcessType := Types[ProcessIndex];
  ThreadType := Types[ThreadIndex];
end;

const
  HANDLES_PER_PAGE: array [Boolean] of Cardinal = (
    PAGE_SIZE div (SizeOf(Pointer) * 2), // Native: 256 or 512 (32- or 64-bit OS)
    PAGE_SIZE div (SizeOf(UInt64) * 2)   // WoW64:  512 (64-bit OS)
  );
  LEAP_HANDLE_MASK: array [Boolean] of Cardinal = (
    4 * PAGE_SIZE div (SizeOf(Pointer) * 2) - 1, // Native: $3FF or $7FF (32- or 64-bit OS)
    4 * PAGE_SIZE div (SizeOf(UInt64) * 2) - 1   // WoW64:  $3FF (64-bit OS)
  );

function NtxEnumerateProcessesBruteforce;
var
  ProcessType, ThreadType: TNtxObjectTypeInfo;
  ActivePIDs: TArray<TProcessId>;
  i, j, RemainingGuesses: Integer;
  PID: TProcessId;
  ImageName: String;
begin
  // Collect process and thread numbers and high watermarks
  Result := RtlxQueryProcessThreadStats(ProcessType, ThreadType);

  if not Result.IsSuccess then
    Exit;

  // Our bruteforcing will find terminated processes as well. When we can,
  // tell them apart from the active ones using the ntdll usage heuristics.
  if not NtxEnumerateUsingProcessesNtdll(ActivePIDs).IsSuccess then
    ActivePIDs := nil;

  // We should be able to find IDs for all processes within the range up
  // to the high watermark sum for PIDs and TIDs (as they share the namespace)
  Processes := nil;
  SetLength(Processes, ProcessType.Native.TotalNumberOfObjects);
  RemainingGuesses := AlignUp(ProcessType.Native.HighWaterNumberOfObjects +
    ThreadType.Native.HighWaterNumberOfObjects, HANDLES_PER_PAGE[RtlIsWoW64]);

  PID := 4;
  i := 0;

  while (i <= High(Processes)) and (RemainingGuesses > 0) do
  begin
    if NtxQueryImageNameProcessId(PID, ImageName).IsSuccess then
    begin
      // A successful guess; save the process
      Processes[i].Basic.ProcessID := PID;
      Processes[i].Full.ImagePath := ImageName;
      Processes[i].ImageName := RtlxExtractNamePath(ImageName);

      if (PID = SYSTEM_PID) and (ImageName = '') then
        ImageName := 'System';

      // Only mark terminated processes when we can actually tell them apart
      // (ntdll usage enumeration worked) and they are not minimal processes
      if Length(ActivePIDs) > 0 then
      begin
        Processes[i].IsTerminated := RtlxSuffixString('.exe', ImageName);

        // Ntdll usage means still active
        if Processes[i].IsTerminated then
          for j := 0 to High(ActivePIDs) do
            if ActivePIDs[j] = PID then
            begin
              Processes[i].IsTerminated := False;
              Break;
            end;
      end;

      Inc(i);
    end;

    // Advance to the next
    Inc(PID, 4);

    // Skip the last entry per low-level handle page since it's an invalid PID
    if (PID and LEAP_HANDLE_MASK[RtlIsWoW64]) = 0 then
      Inc(PID, 4);

    Dec(RemainingGuesses);
  end;

  // Trim if necessary
  SetLength(Processes, i);
end;

function NtxEnumerateThreadsGetNext;
var
  hxProcess, hxThread: IHandle;
  Basic: TThreadBasicInformation;
  Entry: TNtxThreadEntry;
begin
  Result := NtxOpenProcess(hxProcess, Process.Basic.ProcessID,
    PROCESS_QUERY_INFORMATION);

  if not Result.IsSuccess then
    Exit;

  Process.Threads := nil;

  for hxThread in NtxIterateGetNextThread(@Result, hxProcess,
    THREAD_QUERY_LIMITED_INFORMATION) do
    if NtxThread.Query(hxThread, ThreadBasicInformation, Basic).IsSuccess then
    begin
      Entry := Default(TNtxThreadEntry);
      Entry.hxThread := hxThread;
      Entry.Basic.ClientID := Basic.ClientId;
      Entry.Basic.Priority := Basic.Priority;
      Entry.Basic.BasePriority := Basic.BasePriority;
      SetLength(Process.Threads, Succ(Length(Process.Threads)));
      Process.Threads[High(Process.Threads)] := Entry;
    end;
end;

function NtxEnumerateThreadsBruteforce;
var
  ProcessType, ThreadType: TNtxObjectTypeInfo;
  ObjectAttributes: TObjectAttributes;
  ClientId: TClientId;
  hThread: THandle;
  RemainingGuesses: Integer;
  Status: NTSTATUS;
begin
  // Collect process and thread numbers and high watermarks
  Result := RtlxQueryProcessThreadStats(ProcessType, ThreadType);

  if not Result.IsSuccess then
    Exit;

  // We should be able to find IDs for all processes within the range up
  // to the high watermark sum for PIDs and TIDs (as they share the namespace)
  Process.Threads := nil;
  RemainingGuesses := AlignUp(ProcessType.Native.HighWaterNumberOfObjects +
    ThreadType.Native.HighWaterNumberOfObjects, HANDLES_PER_PAGE[RtlIsWoW64]);

  ClientId.UniqueProcess := Process.Basic.ProcessID;
  ClientId.UniqueThread := 8;
  InitializeObjectAttributes(ObjectAttributes);

  while RemainingGuesses > 0 do
  begin
    // Try the PID:TID pair
    Status := NtOpenThread(hThread, 0, ObjectAttributes, ClientId);

    // The call should not succeed due to the zero desired access, but still
    if NT_SUCCESS(Status) then
      NtClose(hThread);

    if Status <> STATUS_INVALID_CID then
    begin
      // A successful guess; save the TID
      SetLength(Process.Threads, Succ(Length(Process.Threads)));
      Process.Threads[High(Process.Threads)].Basic.ClientID := ClientId;
    end;

    // Advance to the next
    Inc(ClientId.UniqueThread, 4);

    // Skip the last entry per low-level handle page since it's invalid
    if (ClientId.UniqueThread and LEAP_HANDLE_MASK[RtlIsWoW64]) = 0 then
      Inc(ClientId.UniqueThread, 4);

    Dec(RemainingGuesses);
  end;
end;

function IsNotTerminated(
  const Entry: TNtxProcessEntry
): Boolean;
begin
  Result := not Entry.IsTerminated;
end;

function NtxOpenProcessByName;
var
  Processes: TArray<TNtxProcessEntry>;
  FilterOptions: TNtxProcessImageFilterOptions;
  i: Integer;
  PID: TProcessId;
begin
  if (pnAllowPIDs in Options) and RtlxStrToUIntPtr(ImageName, UIntPtr(PID)) then
  begin
    Result := NtxOpenProcess(hxProcess, PID, DesiredAccess, HandleAttributes);
    Exit;
  end;

  // Collect processes
  Result := EnumerationMethod(Processes);

  FilterOptions := [];

  if pnAllowShortNames in Options then
    Include(FilterOptions, pfAllowShortNames);

  if pnCaseSensitive in Options then
    Include(FilterOptions, pfCaseSensitive);

  // Keep only matching image names
  TArray.FilterInline<TNtxProcessEntry>(Processes, ByImage(ImageName,
    FilterOptions));

  // Remove terminated processes (if even included by the enumeration API)
  if not (pnAllowTerminated in Options) then
    TArray.FilterInline<TNtxProcessEntry>(Processes, IsNotTerminated);

  if Length(Processes) <= 0 then
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
  begin
    Result := NtxOpenProcess(hxProcess, Processes[i].Basic.ProcessID,
      DesiredAccess, HandleAttributes);

    if Result.IsSuccess then
      Break;
  end
end;

{ Helper functions }

function ByPid;
begin
  Result := function (const ProcessEntry: TNtxProcessEntry): Boolean
    begin
      Result := ProcessEntry.Basic.ProcessID = PID;
    end;
end;

function ByImage;
begin
  Result := function (const ProcessEntry: TNtxProcessEntry): Boolean
    begin
      Result := RtlxCompareStrings(ProcessEntry.ImageName, ImageName,
        pfCaseSensitive in Options) = 0;

      // Try appending .exe as a fallback when short names are enabled
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

function RtlxIsSameProcess;
begin
  Result := (A.Basic.ProcessID = B.Basic.ProcessID) and
    (A.Basic.CreateTime = B.Basic.CreateTime);
end;

function RtlxIsSameThread;
begin
  Result := A.Basic.ClientID = B.Basic.ClientID;
end;

function RtlxIsParentProcess;
begin
  // Note: process enumeration APIs order processes by creation time, even when
  // the system time has changed. Use that to detect PID reuse.
  Result := (ParentIndex < ChildIndex) and
    (Child.Basic.InheritedFromProcessId = Parent.Basic.ProcessId);
end;

end.
