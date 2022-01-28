unit NtUtils.MiniDumps;

{
  This module provides support for capturing and parsing minidump files.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntpsapi, Ntapi.ntioapi, Ntapi.ntdef, Ntapi.minidump,
  Ntapi.ntmmapi, NtUtils, DelphiApi.Reflection, DelphiUtils.AutoObjects;

type
  IMiniDump = IMemory<PMiniDumpHeader>;

  TDmpxThread = record
    ThreadId: TThreadId32;
    SuspendCount: Cardinal;
    PriorityClass: Cardinal;
    Priority: Cardinal;
    [Hex] Teb: UInt64;      // VA in target's address space
    [Hex] Stack: UInt64;    // VA in target's address space
    StackData: TMemory;     // Raw data saved in the minidump
    ThreadContext: TMemory; // Raw data saved in the minidump
  end;

  TDmpxModule = record
    [Hex] BaseOfImage: UInt64;
    [Bytes] SizeOfImage: Cardinal;
    [Hex] CheckSum: Cardinal;
    TimeDateStamp: TUnixTime;
    ModuleName: String;
  end;

  TDmpxFullMemory = record
    [Hex] StartOfMemoryRange: UInt64; // VA in target's address space
    [Bytes] DataSize: UInt64;
    Content: Pointer;                 // Raw data saved in the minidump
  end;

  TDmpxHandle = record
    Handle: UInt64;
    TypeName: String;
    ObjectName: String;
    Attributes: TObjectAttributesFlags;
    GrantedAccess: TAccessMask;
    HandleCount: Cardinal;
    PointerCount: Cardinal;
  end;

  TDmpxMemoryInfo = record
    [Hex] BaseAddress: UInt64;
    [Hex] AllocationBase: UInt64;
    AllocationProtect: TMemoryProtection;
    [Bytes] RegionSize: UInt64;
    State: TAllocationType;
    Protect: TMemoryProtection;
    MemoryType: TMemoryType;
  end;

  TDmpxThreadInfo = TMiniDumpThreadInfo;

  TDmpxThreadName = record
    ThreadId: TThreadId32;
    ThreadName: String;
  end;

// Write process's minidump into a file
function DmpxWriteMiniDump(
  [Access(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ)] hProcess: THandle;
  [Access(FILE_WRITE_DATA)] hFile: THandle;
  DumpType: TMiniDumpType
): TNtxStatus;

// Find a specific stream directory in a minidump file
function DmpxFindStream(
  const MiniDump: IMiniDump;
  Stream: TMiniDumpStreamType;
  out Directory: PMiniDumpDirectory
): TNtxStatus;

// Enumerate all streams in a minidump file
function DmpxEnumerateStreams(
  const MiniDump: IMiniDump;
  out Directories: TArray<PMiniDumpDirectory>
): TNtxStatus;

{ Stream content parsing }

// Retrieve thread information from a minidump file
function DmpxParseThreadStream(
  const MiniDump: IMiniDump;
  out Threads: TArray<TDmpxThread>;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

// Retrieve module information from a minidump file
function DmpxParseModuleStream(
  const MiniDump: IMiniDump;
  out Modules: TArray<TDmpxModule>;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

// Retrieve full memory information from a minidump file
function DmpxParseFullMemoryStream(
  const MiniDump: IMiniDump;
  out Regions: TArray<TDmpxFullMemory>;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

// Retrieve wide command from a minidump file
function DmpxParseCommentWStream(
  const MiniDump: IMiniDump;
  out Comment: String;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

// Retrieve wide command from a minidump file
function DmpxParseHandleStream(
  const MiniDump: IMiniDump;
  out Handles: TArray<TDmpxHandle>;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

// Retrieve the list of unloaded modules from a minidump file
function DmpxParseUnloadedModulesStream(
  const MiniDump: IMiniDump;
  out UnloadedModules: TArray<TDmpxModule>;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

// Retrieve information about memory regions from a minidump file
function DmpxParseMemoryInfoStream(
  const MiniDump: IMiniDump;
  out Regions: TArray<TDmpxMemoryInfo>;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

// Retrieve information about threads from a minidump file
function DmpxParseThreadInfoStream(
  const MiniDump: IMiniDump;
  out Threads: TArray<TDmpxThreadInfo>;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

// Retrieve information about thread names from a minidump file
function DmpxParseThreadNamesStream(
  const MiniDump: IMiniDump;
  out ThreadNames: TArray<TDmpxThreadName>;
  [in, opt] Stream: PMiniDumpDirectory = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.SysUtils;

function DmpxWriteMiniDump;
begin
  Result.Location := 'MiniDumpWriteDump';
  Result.Win32Result := MiniDumpWriteDump(hProcess, 0, hFile, DumpType,
    nil, nil, nil);
end;

function LocationInRange(
  const MiniDump: IMiniDump;
  const Location: TMiniDumpLocationDescriptor;
  SkipCheckForZeroRva: Boolean = False
): Boolean;
begin
  Result := (SkipCheckForZeroRva and (Location.Rva = 0)) or
    (UInt64(Location.Rva) + Location.DataSize < MiniDump.Size);
end;

function DmpxValidateStreams(
  const MiniDump: IMiniDump
): TNtxStatus;
var
  Directories: ^TAnysizeArray<TMiniDumpDirectory>;
  i: Integer;
begin
  Result.Location := 'DmpxFindStream';

  // Make sure the header fits
  if MiniDump.Size < SizeOf(TMiniDumpHeader) then
  begin
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  // Make sure we are parsing a mini-dump file
  if (MiniDump.Data.Signature <> MINIDUMP_SIGNATURE) or
    (MiniDump.Data.Version <> MINIDUMP_VERSION) then
  begin
    Result.Status := STATUS_UNKNOWN_REVISION;
    Exit;
  end;

  // Validate overall stream directory size
  if UInt64(MiniDump.Data.NumberOfStreams) * SizeOf(TMiniDumpDirectory) +
    MiniDump.Data.StreamDirectoryRva >= MiniDump.Size then
  begin
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  Directories := MiniDump.Offset(MiniDump.Data.StreamDirectoryRva);

  // Validate each stream directory
  for i := 0 to Integer(MiniDump.Data.NumberOfStreams) - 1 do
    if not LocationInRange(MiniDump, Directories{$R-}[i]{$R+}.Location) then
    begin
      Result.Status := STATUS_INVALID_BUFFER_SIZE;
      Exit;
    end;

  Result.Status := STATUS_SUCCESS;
end;

function DmpxFindStream;
var
  Directories: ^TAnysizeArray<TMiniDumpDirectory>;
  i: Integer;
begin
  Result := DmpxValidateStreams(MiniDump);

  if not Result.IsSuccess then
    Exit;

  Directories := MiniDump.Offset(MiniDump.Data.StreamDirectoryRva);

  for i := 0 to Integer(MiniDump.Data.NumberOfStreams) - 1 do
    if Directories{$R-}[i]{$R+}.StreamType = Stream then
    begin
      Directory := @Directories{$R-}[i]{$R+};
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

  Result.Location := 'DmpxFindStream';
  Result.LastCall.UsesInfoClass(Stream, icRead);
  Result.Status := STATUS_NOT_FOUND;
end;

function DmpxEnumerateStreams;
var
  pDirectories: ^TAnysizeArray<TMiniDumpDirectory>;
  i: Integer;
begin
  Result := DmpxValidateStreams(MiniDump);

  if not Result.IsSuccess then
    Exit;

  pDirectories := MiniDump.Offset(MiniDump.Data.StreamDirectoryRva);
  SetLength(Directories, MiniDump.Data.NumberOfStreams);

  for i := 0 to Integer(MiniDump.Data.NumberOfStreams) - 1 do
    Directories[i] := @pDirectories{$R-}[i]{$R+};
end;

function DmpxFindOrCheckTypeStream(
  const MiniDump: IMiniDump;
  var Stream: PMiniDumpDirectory;
  ExpectedType: TMiniDumpStreamType
): TNtxStatus;
begin
  // Find the stream on demand
  if not Assigned(Stream) then
  begin
    Result := DmpxFindStream(MiniDump, ExpectedType, Stream);

    if not Result.IsSuccess then
      Exit;
  end

  // Check the type of the supplied stream
  else if Stream.StreamType <> ExpectedType then
  begin
    Result.Location := 'DmpxFindOrVerifyStream';
    Result.LastCall.UsesInfoClass(ExpectedType, icRead);
    Result.Status := STATUS_OBJECT_TYPE_MISMATCH;
    Exit;
  end;

  Result.Status := STATUS_SUCCESS;
end;

function GetString(
  const MiniDump: IMiniDump;
  const Rva: UInt64
): String;
var
  StringData: PMiniDumpString;
  MaxLength: Cardinal;
begin
  if (Rva = 0) or (Rva + SizeOf(Cardinal) >= MiniDump.Size) then
    Exit('');

  MaxLength := MiniDump.Size - Rva;
  StringData := MiniDump.Offset(Rva);

  if StringData.Length < MaxLength then
    MaxLength := StringData.Length;

  Result := RtlxCaptureString(StringData.Buffer,
    MaxLength div SizeOf(WideChar));
end;

{ Stream Parsing }

function DmpxParseThreadStream;
var
  ThreadList: PMiniDumpThreadList;
  ThreadInfo: PMiniDumpThread;
  i: Integer;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.ThreadListStream);

  if not Result.IsSuccess then
    Exit;

  ThreadList := MiniDump.Offset(Stream.Location.Rva);

  if (SizeOf(TMiniDumpThreadList) > Stream.Location.DataSize) or
    (UInt64(ThreadList.NumberOfThreads) * SizeOf(TMiniDumpThread) +
    SizeOf(TMiniDumpThreadList) - SizeOf(TMiniDumpThread) >
    Stream.Location.DataSize) then
  begin
    Result.Location := 'DmpxParseThreadStream';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  ThreadInfo := @ThreadList.Threads[0];
  SetLength(Threads, ThreadList.NumberOfThreads);

  for i := 0 to High(Threads) do
  begin
    if not LocationInRange(MiniDump, ThreadInfo.Stack.Memory, True) or
      not LocationInRange(MiniDump, ThreadInfo.ThreadContext, True) then
    begin
      Result.Location := 'DmpxParseThreadStream';
      Result.Status := STATUS_INVALID_BUFFER_SIZE;
      Exit;
    end;

    Threads[i].ThreadId := ThreadInfo.ThreadId;
    Threads[i].SuspendCount := ThreadInfo.SuspendCount;
    Threads[i].PriorityClass := ThreadInfo.PriorityClass;
    Threads[i].Priority := ThreadInfo.Priority;
    Threads[i].Teb := ThreadInfo.Teb;
    Threads[i].Stack := ThreadInfo.Stack.StartOfMemoryRange;
    Threads[i].StackData.Size := ThreadInfo.Stack.Memory.DataSize;
    Threads[i].ThreadContext.Size := ThreadInfo.ThreadContext.DataSize;

    if ThreadInfo.Stack.Memory.Rva <> 0 then
      Threads[i].StackData.Address := MiniDump.Offset(
        ThreadInfo.Stack.Memory.Rva);

    if ThreadInfo.ThreadContext.Rva <> 0 then
      Threads[i].ThreadContext.Address := MiniDump.Offset(
        ThreadInfo.ThreadContext.Rva);

    Inc(ThreadInfo);
  end;
end;

function DmpxParseModuleStream;
var
  ModuleList: PMiniDumpModuleList;
  ModuleInfo: PMiniDumpModule;
  i: Integer;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.ModuleListStream);

  if not Result.IsSuccess then
    Exit;

  ModuleList := MiniDump.Offset(Stream.Location.Rva);

  if (SizeOf(TMiniDumpModuleList) > Stream.Location.DataSize) or
    (UInt64(ModuleList.NumberOfModules) * SizeOf(TMiniDumpModule) +
    SizeOf(TMiniDumpModuleList) - SizeOf(TMiniDumpModule) >
    Stream.Location.DataSize) then
  begin
    Result.Location := 'DmpxParseModuleStream';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  ModuleInfo := @ModuleList.Modules[0];
  SetLength(Modules, ModuleList.NumberOfModules);

  for i := 0 to High(Modules) do
  begin
    Modules[i].BaseOfImage := ModuleInfo.BaseOfImage;
    Modules[i].SizeOfImage := ModuleInfo.SizeOfImage;
    Modules[i].CheckSum := ModuleInfo.CheckSum;
    Modules[i].TimeDateStamp := ModuleInfo.TimeDateStamp;
    Modules[i].ModuleName := GetString(MiniDump,
      ModuleInfo.ModuleNameRva);

    Inc(ModuleInfo);
  end;
end;

function DmpxParseFullMemoryStream;
var
  Memory64List: PMiniDumpMemory64List;
  Memory64: PMiniDumpMemoryDescriptor64;
  i: Integer;
  OffsetToRawData: UInt64;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.Memory64ListStream);

  if not Result.IsSuccess then
    Exit;

  Memory64List := MiniDump.Offset(Stream.Location.Rva);

  if (SizeOf(TMiniDumpMemory64List) > Stream.Location.DataSize) or
    (UInt64(Memory64List.NumberOfMemoryRanges) *
    SizeOf(TMiniDumpMemoryDescriptor64) +
    SizeOf(TMiniDumpMemory64List) - SizeOf(TMiniDumpMemoryDescriptor64) >
    Stream.Location.DataSize) then
  begin
    Result.Location := 'DmpxParseFullMemoryStream';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  SetLength(Regions, Memory64List.NumberOfMemoryRanges);
  OffsetToRawData := Memory64List.BaseRva;

  for i := 0 to High(Regions) do
  begin
    Memory64 := @Memory64List.MemoryRanges{$R-}[i]{$R+};
    Regions[i].StartOfMemoryRange := Memory64.StartOfMemoryRange;
    Regions[i].DataSize := Memory64.DataSize;

    if OffsetToRawData + Memory64.DataSize > MiniDump.Size then
    begin
      Result.Location := 'DmpxParseFullMemoryStream';
      Result.Status := STATUS_INVALID_BUFFER_SIZE;
      Exit;
    end;

    Regions[i].Content := MiniDump.Offset(OffsetToRawData);
    Inc(OffsetToRawData, Memory64.DataSize);
  end;
end;

function DmpxParseCommentWStream;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.CommentStreamW);

  if Result.IsSuccess then
    Comment := RtlxCaptureString(MiniDump.Offset(Stream.Location.Rva),
      Stream.Location.DataSize div SizeOf(WideChar));
end;

function DmpxParseHandleStream;
var
  HandleList: PMiniDumpHandleDataStream;
  HandleInfo: PMiniDumpHandleDescriptor2;
  i: Integer;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.HandleDataStream);

  if not Result.IsSuccess then
    Exit;

  HandleList := MiniDump.Offset(Stream.Location.Rva);

  if (SizeOf(TMiniDumpHandleDataStream) > Stream.Location.DataSize) or
    (HandleList.SizeOfHeader < SizeOf(TMiniDumpHandleDataStream)) or
    (HandleList.SizeOfDescriptor < SizeOf(TMiniDumpHandleDescriptor)) or
    (UInt64(HandleList.NumberOfDescriptors) * HandleList.SizeOfDescriptor +
    HandleList.SizeOfHeader > Stream.Location.DataSize) then
  begin
    Result.Location := 'DmpxParseHandleStream';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  PByte(HandleInfo) := PByte(HandleList) + HandleList.SizeOfHeader;
  SetLength(Handles, HandleList.NumberOfDescriptors);

  for i := 0 to High(Handles) do
  begin
    Handles[i].Handle := HandleInfo.V1.Handle;
    Handles[i].TypeName := GetString(MiniDump, HandleInfo.V1.TypeNameRva);
    Handles[i].ObjectName := GetString(MiniDump, HandleInfo.V1.ObjectNameRva);
    Handles[i].Attributes := HandleInfo.V1.Attributes;
    Handles[i].GrantedAccess := HandleInfo.V1.GrantedAccess;
    Handles[i].HandleCount := HandleInfo.V1.HandleCount;
    Handles[i].PointerCount := HandleInfo.V1.PointerCount;
    Inc(PByte(HandleInfo), HandleList.SizeOfDescriptor);
  end;
end;

function DmpxParseUnloadedModulesStream;
var
  ModuleList: PMiniDumpUnloadedModuleList;
  ModuleInfo: PMiniDumpUnloadedModule;
  i: Integer;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.UnloadedModuleListStream);

  if not Result.IsSuccess then
    Exit;

  ModuleList := MiniDump.Offset(Stream.Location.Rva);

  if (SizeOf(TMiniDumpUnloadedModuleList) > Stream.Location.DataSize) or
    (ModuleList.SizeOfHeader < SizeOf(TMiniDumpUnloadedModuleList)) or
    (ModuleList.SizeOfEntry < SizeOf(TMiniDumpUnloadedModule)) or
    (UInt64(ModuleList.NumberOfEntries) * ModuleList.SizeOfEntry +
    ModuleList.SizeOfHeader > Stream.Location.DataSize) then
  begin
    Result.Location := 'DmpxParseUnloadedModulesStream';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  PByte(ModuleInfo) := PByte(ModuleList) + ModuleList.SizeOfHeader;
  SetLength(UnloadedModules, ModuleList.NumberOfEntries);

  for i := 0 to High(UnloadedModules) do
  begin
    UnloadedModules[i].BaseOfImage := ModuleInfo.BaseOfImage;
    UnloadedModules[i].SizeOfImage := ModuleInfo.SizeOfImage;
    UnloadedModules[i].CheckSum := ModuleInfo.CheckSum;
    UnloadedModules[i].TimeDateStamp := ModuleInfo.TimeDateStamp;
    UnloadedModules[i].ModuleName := GetString(MiniDump,
      ModuleInfo.ModuleNameRva);

    Inc(PByte(ModuleInfo), ModuleList.SizeOfEntry);
  end;
end;

function DmpxParseMemoryInfoStream;
var
  MemoryList: PMiniDumpMemoryInfoList;
  MemoryInfo: PMiniDumpMemoryInfo;
  i: Integer;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.MemoryInfoListStream);

  if not Result.IsSuccess then
    Exit;

  MemoryList := MiniDump.Offset(Stream.Location.Rva);

  if (SizeOf(TMiniDumpMemoryInfoList) > Stream.Location.DataSize) or
    (MemoryList.SizeOfHeader < SizeOf(TMiniDumpMemoryInfoList)) or
    (MemoryList.SizeOfEntry < SizeOf(TMiniDumpMemoryInfo)) or
    (UInt64(MemoryList.NumberOfEntries) * MemoryList.SizeOfEntry +
    MemoryList.SizeOfHeader > Stream.Location.DataSize) then
  begin
    Result.Location := 'DmpxParseMemoryInfoStream';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  PByte(MemoryInfo) := PByte(MemoryList) + MemoryList.SizeOfHeader;
  SetLength(Regions, MemoryList.NumberOfEntries);

  for i := 0 to High(Regions) do
  begin
    Regions[i].BaseAddress := MemoryInfo.BaseAddress;
    Regions[i].AllocationBase := MemoryInfo.AllocationBase;
    Regions[i].AllocationProtect := MemoryInfo.AllocationProtect;
    Regions[i].RegionSize := MemoryInfo.RegionSize;
    Regions[i].State := MemoryInfo.State;
    Regions[i].Protect := MemoryInfo.Protect;
    Regions[i].MemoryType := MemoryInfo.MemoryType;

    Inc(PByte(MemoryInfo), MemoryList.SizeOfEntry);
  end;
end;

function DmpxParseThreadInfoStream;
var
  ThreadList: PMiniDumpThreadInfoList;
  ThreadInfo: PMiniDumpThreadInfo;
  i: Integer;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.ThreadInfoListStream);

  if not Result.IsSuccess then
    Exit;

  ThreadList := MiniDump.Offset(Stream.Location.Rva);

  if (SizeOf(TMiniDumpThreadInfoList) > Stream.Location.DataSize) or
    (ThreadList.SizeOfHeader < SizeOf(TMiniDumpThreadInfoList)) or
    (ThreadList.SizeOfEntry < SizeOf(TMiniDumpThreadInfo)) or
    (UInt64(ThreadList.NumberOfEntries) * ThreadList.SizeOfEntry +
    ThreadList.SizeOfHeader > Stream.Location.DataSize) then
  begin
    Result.Location := 'DmpxParseThreadInfoStream';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  PByte(ThreadInfo) := PByte(ThreadList) + ThreadList.SizeOfHeader;
  SetLength(Threads, ThreadList.NumberOfEntries);

  for i := 0 to High(Threads) do
  begin
    Threads[i] := ThreadInfo^;
    Inc(PByte(ThreadInfo), ThreadList.SizeOfEntry);
  end;
end;

function DmpxParseThreadNamesStream;
var
  ThreadList: PMiniDumpThreadNameList;
  ThreadInfo: PMiniDumpThreadName;
  i: Integer;
begin
  Result := DmpxFindOrCheckTypeStream(MiniDump, Stream,
    TMiniDumpStreamType.ThreadNamesStream);

  if not Result.IsSuccess then
    Exit;

  ThreadList := MiniDump.Offset(Stream.Location.Rva);

  if (SizeOf(TMiniDumpThreadNameList) > Stream.Location.DataSize) or
    (UInt64(ThreadList.NumberOfThreadNames) * SizeOf(TMiniDumpThreadName) +
    SizeOf(TMiniDumpThreadNameList) - SizeOf(TMiniDumpThreadName) >
    Stream.Location.DataSize) then
  begin
    Result.Location := 'DmpxParseThreadNamesStream';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  ThreadInfo := @ThreadList.ThreadNames[0];
  SetLength(ThreadNames, ThreadList.NumberOfThreadNames);

  for i := 0 to High(ThreadNames) do
  begin
    ThreadNames[i].ThreadId := ThreadInfo.ThreadId;
    ThreadNames[i].ThreadName := GetString(MiniDump,
      ThreadInfo.RvaOfThreadName);

    Inc(ThreadInfo);
  end;
end;

end.
