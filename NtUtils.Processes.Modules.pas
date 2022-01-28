unit NtUtils.Processes.Modules;

{
  These functions allow listing modules that are loaded into other processes.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntpsapi, NtUtils, NtUtils.Ldr, Ntapi.ntrtl,
  DelphiApi.Reflection;

const
  PROCESS_ENUMERATE_MODULES = PROCESS_QUERY_LIMITED_INFORMATION or
    PROCESS_VM_READ;

type
  TModuleEntry = NtUtils.Ldr.TModuleEntry;

  TUnloadedModule = record
    Sequence: Cardinal;
    BaseAddress: Pointer;
    [Bytes] SizeOfImage: NativeUInt;
    TimeDateStamp: TUnixTime;
    [Hex] CheckSum: Cardinal;
    ImageName: String;
    Version: TRtlUnloadEventVersion;
  end;

// Enumerate modules loaded by a process
function NtxEnumerateModulesProcess(
  [Access(PROCESS_ENUMERATE_MODULES)] hProcess: THandle;
  out Modules: TArray<TModuleEntry>;
  [out, opt] IsWoW64: PBoolean = nil
): TNtxStatus;

// Enumerate native modules loaded by a process
function NtxEnumerateModulesProcessNative(
  [Access(PROCESS_ENUMERATE_MODULES)] hProcess: THandle;
  out Modules: TArray<TModuleEntry>
): TNtxStatus;

{$IFDEF Win64}
// Enumerate WoW64 modules loaded by a process
function NtxEnumerateModulesProcessWoW64(
  [Access(PROCESS_ENUMERATE_MODULES)] hProcess: THandle;
  out Modules: TArray<TModuleEntry>
): TNtxStatus;
{$ENDIF}

// A parent checker to use with TArrayHelper.BuildTree<TModuleEntry>
function IsParentModule(const Parent, Child: TModuleEntry): Boolean;

// Enumerate modules that were unloaded by a process
function NtxEnumerateUnloadedModulesProcess(
  [Access(PROCESS_ENUMERATE_MODULES)] hProcess: THandle;
  out UnloadedModules: TArray<TUnloadedModule>
): TNtxStatus;

// Enumerate native modules that were unloaded by a process
function NtxEnumerateUnloadedModulesProcessNative(
  [Access(PROCESS_VM_READ)] hProcess: THandle;
  out UnloadedModules: TArray<TUnloadedModule>
): TNtxStatus;

{$IFDEF Win64}
// Enumerate WoW64 modules that were unloaded by a process
function NtxEnumerateUnloadedModulesProcessWoW64(
  [Access(PROCESS_VM_READ)] hProcess: THandle;
  out UnloadedModules: TArray<TUnloadedModule>
): TNtxStatus;
{$ENDIF}

implementation

uses
  Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntldr, Ntapi.ntstatus, Ntapi.ntwow64,
  Ntapi.ntmmapi, Ntapi.Versions, NtUtils.Processes, NtUtils.Processes.Info,
  NtUtils.SysUtils, NtUtils.Memory, NtUtils.Sections, NtUtils.ImageHlp,
  DelphiUtils.AutoObjects;

function NtxEnumerateModulesProcess;
var
  IsTargetWoW64: Boolean;
begin
  Result := RtlxAssertWoW64Compatible(hProcess, IsTargetWoW64);

  if not Result.IsSuccess then
    Exit;

  if Assigned(IsWoW64) then
    IsWoW64^ := IsTargetWoW64;

{$IFDEF Win64}
  if IsTargetWoW64 then
    Result := NtxEnumerateModulesProcessWoW64(hProcess, Modules)
  else
{$ENDIF}
    Result := NtxEnumerateModulesProcessNative(hProcess, Modules);
end;

function NtxEnumerateModulesProcessNative;
var
  BasicInfo: TProcessBasicInformation;
  pLdr: PPebLdrData;
  Ldr: TPebLdrData;
  i: Integer;
  pStart, pCurrent: PListEntry;
  Current: TLdrDataTableEntry;
  OsVersion: TWindowsVersion;
  EntrySize: NativeUInt;
  xMemory: IMemory;
begin
  // Find the PEB
  Result := NtxProcess.Query(hProcess, ProcessBasicInformation, BasicInfo);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(BasicInfo.PebBaseAddress) then
  begin
    Result.Location := 'NtxEnumerateModulesProcess';
    Result.Status := STATUS_UNSUCCESSFUL;
    Exit;
  end;

  // Read a pointer to the loader data
  Result := NtxMemory.Read(hProcess, @BasicInfo.PebBaseAddress.Ldr, pLdr);

  if not Result.IsSuccess then
    Exit;

  // Read the loader data itself
  FillChar(Ldr, SizeOf(Ldr), 0);
  Result := NtxMemory.Read(hProcess, pLdr, Ldr);

  if Result.Matches(STATUS_PARTIAL_COPY, 'NtReadVirtualMemory') and
    not Ldr.Initialized then
  begin
    // The loader is not initialized yet, probably we work with
    // a newly created suspended process.
    SetLength(Modules, 0);

    // TODO: fallback to enumerating mapped images
    Result.Status := STATUS_MORE_ENTRIES;
    Exit;
  end;

  if not Result.IsSuccess then
    Exit;

  // Entry size depends on the OS version
  OsVersion := RtlOsVersion;

  // Calculate it using offsets
  if OsVersion >= OsWin10RS2 then
    EntrySize := SizeOf(TLdrDataTableEntry)
  else if OsVersion >= OsWin10TH1 then
    EntrySize := NativeUInt(@PLdrDataTableEntry(nil).SigningLevel)
  else if OsVersion >= OsWin8 then
    EntrySize := NativeUInt(@PLdrDataTableEntry(nil).ImplicitPathOptions)
  else
    EntrySize := NativeUInt(@PLdrDataTableEntry(nil).BaseNameHashValue);

  // Traverse the list
  i := 0;
  pStart := @pLdr.InLoadOrderModuleList;
  pCurrent := Ldr.InLoadOrderModuleList.Flink;
  SetLength(Modules, 0);

  // Allocate a buffer with enough space to hold any addressable UNICODE_STRING
  xMemory := Auto.AllocateDynamic(High(Word));

  while (pStart <> pCurrent) and (i <= MAX_MODULES) do
  begin
    // Read the entry
    Result := NtxReadMemory(hProcess, pCurrent, TMemory.From(@Current,
      EntrySize));

    if not Result.IsSuccess then
      Exit;

    // Save it
    SetLength(Modules, Length(Modules) + 1);
    with Modules[High(Modules)] do
    begin
      DllBase := Current.DllBase;
      EntryPoint := Current.EntryPoint;
      SizeOfImage := Current.SizeOfImage;

      // Retrieve full module name
      if NtxReadMemory(hProcess, Current.FullDllName.Buffer,
        TMemory.From(xMemory.Data, Current.FullDllName.Length)).IsSuccess then
      begin
        Current.FullDllName.Buffer := xMemory.Data;
        FullDllName := Current.FullDllName.ToString;
      end;

      // Retrieve short module name
      if NtxReadMemory(hProcess, Current.BaseDllName.Buffer,
        TMemory.From(xMemory.Data, Current.BaseDllName.Length)).IsSuccess then
      begin
        Current.BaseDllName.Buffer := xMemory.Data;
        BaseDllName := Current.BaseDllName.ToString;
      end;

      Flags := Current.Flags;
      TimeDateStamp := Current.TimeDateStamp;
      LoadTime := Current.LoadTime;
      ParentDllBase := Current.ParentDllBase;
      OriginalBase := Current.OriginalBase;

      if OsVersion >= OsWin8 then
        LoadReason := Current.LoadReason;
    end;

    // Go to the next one
    pCurrent := Current.InLoadOrderLinks.Flink;
    Inc(i);
  end;
end;

{$IFDEF Win64}
function NtxEnumerateModulesProcessWoW64;
var
  Peb32: PPeb32;
  pLdr: Wow64Pointer<PPebLdrData32>;
  Ldr: TPebLdrData32;
  i: Integer;
  pStart, pCurrent: PListEntry32;
  Current: TLdrDataTableEntry32;
  OsVersion: TWindowsVersion;
  EntrySize: NativeUInt;
  Str: TNtUnicodeString;
  xMemory: IMemory;
begin
  // Find the 32-bit PEB
  Result := NtxProcess.Query(hProcess, ProcessWow64Information, Peb32);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(Peb32) then
  begin
    Result.Location := 'NtxEnumerateModulesProcessWoW64';
    Result.Status := STATUS_UNSUCCESSFUL;
    Exit;
  end;

  // Read a pointer to the WoW64 loader data
  Result := NtxMemory.Read(hProcess, @Peb32.Ldr, pLdr);

  if not Result.IsSuccess then
    Exit;

  // Read the loader data itself
  FillChar(Ldr, SizeOf(Ldr), 0);
  Result := NtxMemory.Read(hProcess, pLdr, Ldr);

  if Result.Matches(STATUS_PARTIAL_COPY, 'NtReadVirtualMemory') and
    not Ldr.Initialized then
  begin
    // The loader is not initialized yet, probably we work with
    // a newly created suspended process.
    SetLength(Modules, 0);

    // TODO: fallback to enumerating mapped images
    Result.Status := STATUS_MORE_ENTRIES;
    Exit;
  end;

  if not Result.IsSuccess then
    Exit;

  // Entry size depends on the OS version
  OsVersion := RtlOsVersion;

  // Calculate it using offsets in 32-bit structure
  if OsVersion >= OsWin10RS2 then
    EntrySize := SizeOf(TLdrDataTableEntry32)
  else if OsVersion >= OsWin10TH1 then
    EntrySize := NativeUInt(@PLdrDataTableEntry32(nil).SigningLevel)
  else if OsVersion >= OsWin8 then
    EntrySize := NativeUInt(@PLdrDataTableEntry32(nil).ImplicitPathOptions)
  else
    EntrySize := NativeUInt(@PLdrDataTableEntry32(nil).BaseNameHashValue);

  // Traverse the list
  i := 0;
  pStart := @pLdr.Self.InLoadOrderModuleList;
  pCurrent := Pointer(Ldr.InLoadOrderModuleList.Flink);
  SetLength(Modules, 0);

  // Allocate a buffer with enough space to hold any addressable UNICODE_STRING
  xMemory := Auto.AllocateDynamic(High(Word));
  Str.Buffer := xMemory.Data;

  while (pStart <> pCurrent) and (i <= MAX_MODULES) do
  begin
    // Read the entry
    Result := NtxReadMemory(hProcess, pCurrent, TMemory.From(@Current,
      EntrySize));

    if not Result.IsSuccess then
      Exit;

    // Save it
    SetLength(Modules, Length(Modules) + 1);
    with Modules[High(Modules)] do
    begin
      DllBase := Pointer(Current.DllBase);
      EntryPoint := Pointer(Current.EntryPoint);
      SizeOfImage := Current.SizeOfImage;

      // Retrieve full module name
      if NtxReadMemory(hProcess, Pointer(Current.FullDllName.Buffer),
        TMemory.From(Str.Buffer, Current.FullDllName.Length)).IsSuccess then
      begin
        Str.Length := Current.FullDllName.Length;
        Str.MaximumLength := Current.FullDllName.MaximumLength;
        FullDllName := Str.ToString;
      end;

      // Retrieve short module name
      if NtxReadMemory(hProcess, Pointer(Current.BaseDllName.Buffer),
        TMemory.From(Str.Buffer, Current.BaseDllName.Length)).IsSuccess then
      begin
        Str.Length := Current.BaseDllName.Length;
        Str.MaximumLength := Current.BaseDllName.MaximumLength;
        BaseDllName := Str.ToString;
      end;

      Flags := Current.Flags;
      TimeDateStamp := Current.TimeDateStamp;
      LoadTime := Current.LoadTime;
      ParentDllBase := Pointer(Current.ParentDllBase);
      OriginalBase := Current.OriginalBase;

      if OsVersion >= OsWin8 then
        LoadReason := Current.LoadReason;
    end;

    // Go to the next one
    pCurrent := Pointer(Current.InLoadOrderLinks.Flink);
    Inc(i);
  end;
end;
{$ENDIF}

function IsParentModule;
begin
  Result := (Child.ParentDllBase = Parent.DllBase);
end;

{ Unloaded modules }

function NtxEnumerateUnloadedModulesProcess;
var
  IsTargetWoW64: Boolean;
begin
  Result := RtlxAssertWoW64Compatible(hProcess, IsTargetWoW64);

  if not Result.IsSuccess then
    Exit;

  {$IFDEF Win64}
  if IsTargetWoW64 then
    Result := NtxEnumerateUnloadedModulesProcessWoW64(hProcess, UnloadedModules)
  else
{$ENDIF}
    Result := NtxEnumerateUnloadedModulesProcessNative(hProcess,
      UnloadedModules);
end;

function NtxEnumerateUnloadedModulesProcessNative;
var
  RtlpUnloadEventTraceExSize: PCardinal;
  RtlpUnloadEventTraceExNumber: PCardinal;
  RtlpUnloadEventTraceEx: PPRtlUnloadEventTrace;
  Size: Cardinal;
  Count, ActualCount: Cardinal;
  TraceRef: PRtlUnloadEventTrace;
  Trace: IMemory<PRtlUnloadEventTrace>;
  TraceEntry: PRtlUnloadEventTrace;
  i: Integer;
begin
  // Get the pointer to the trace definitions from ntdll
  RtlGetUnloadEventTraceEx(RtlpUnloadEventTraceExSize,
    RtlpUnloadEventTraceExNumber, RtlpUnloadEventTraceEx);

  // Get the trace pointer
  Result := NtxMemory.Read(hProcess, RtlpUnloadEventTraceEx, TraceRef);

  if not Result.IsSuccess then
    Exit;

  if not Assigned(TraceRef) then
  begin
    // Nothing in the trace
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Get the element number
  Result := NtxMemory.Read(hProcess, RtlpUnloadEventTraceExNumber, Count);

  if not Result.IsSuccess then
    Exit;

  if Count = 0 then
  begin
    // Nothing in the trace
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Get the element size
  Result := NtxMemory.Read(hProcess, RtlpUnloadEventTraceExSize, Size);

  if not Result.IsSuccess then
    Exit;

  if (Size < SizeOf(TRtlUnloadEventTrace)) or
    (UInt64(Size) * Count > BUFFER_LIMIT) then
  begin
    Result.Location := 'NtxEnumerateUnloadedModulesProcessNative';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  // Read the trace
  Result := NtxReadMemoryAuto(hProcess, TraceRef, Size * Count, IMemory(Trace));

  if not Result.IsSuccess then
    Exit;

  // Compute the number of elements with valid data

  ActualCount := 0;
  TraceEntry := Trace.Data;

  for i := 0 to Pred(Count) do
  begin
    if Assigned(TraceEntry.BaseAddress) then
      Inc(ActualCount);
    Inc(PByte(TraceEntry), Size);
  end;

  // Save them
  SetLength(UnloadedModules, ActualCount);

  ActualCount := 0;
  TraceEntry := Trace.Data;

  for i := 0 to Pred(Count) do
  begin
    if Assigned(TraceEntry.BaseAddress) then
      with UnloadedModules[ActualCount] do
      begin
        Sequence := TraceEntry.Sequence;
        BaseAddress := TraceEntry.BaseAddress;
        SizeOfImage := TraceEntry.SizeOfImage;
        TimeDateStamp := TraceEntry.TimeDateStamp;
        CheckSum := TraceEntry.CheckSum;
        Version := TraceEntry.Version;
        ImageName := RtlxCaptureString(TraceEntry.ImageName, 32);
        Inc(ActualCount);
      end;

    Inc(PByte(TraceEntry), Size);
  end;
end;

{$IFDEF Win64}
type
  // The definition for 32-bit assembly of RtlGetUnloadEventTraceEx
  TRtlGetUnloadEventTraceExAsm32 = packed record
    // mov edi,edi; push ebp; mov ebp,esp; mov eax,[ebp+08]
    const PROLOG_VALUE = $08458BEC8B55FF8B;

    // mov [eax], XX
    const OP_MOV_VALUE = $00C7;
  public
    [Reserved(PROLOG_VALUE)] Prolog: UInt64;
    [Reserved(OP_MOV_VALUE)] OpMov1: Word;
    RtlpUnloadEventTraceExSize: Wow64Pointer<PCardinal>;
    Padding1: array [0..2] of Byte;
    [Reserved(OP_MOV_VALUE)] OpMov2: Word;
    RtlpUnloadEventTraceExNumber: Wow64Pointer<PCardinal>;
    Padding2: array [0..2] of Byte;
    [Reserved(OP_MOV_VALUE)] OpMov3: Word;
    RtlpUnloadEventTraceEx: Wow64Pointer<PRtlUnloadEventTrace32>;
  end;
  PRtlGetUnloadEventTraceExAsm32 = ^TRtlGetUnloadEventTraceExAsm32;

var
  // The cache for 32-bit RtlGetUnloadEventTraceEx values
  RtlpUnloadEventTraceEx32CacheInitialized: Boolean;
  RtlpUnloadEventTraceExSize32Cache: PCardinal;
  RtlpUnloadEventTraceExNumber32Cache: PCardinal;
  RtlpUnloadEventTraceEx32Cache: PPRtlUnloadEventTrace32;

function RtlxGetUnloadEventTraceEx32(
  out RtlpUnloadEventTraceExSize32: PCardinal;
  out RtlpUnloadEventTraceExNumber32: PCardinal;
  out RtlpUnloadEventTraceEx32: PPRtlUnloadEventTrace32
): TNtxStatus;
var
  hxSection: IHandle;
  xNtdll32: IMemory;
  ExportEntries: TArray<TExportEntry>;
  ExportEntry: PExportEntry;
  Code: PRtlGetUnloadEventTraceExAsm32;
begin
  if RtlpUnloadEventTraceEx32CacheInitialized then
  begin
    // Retrieve the cached definitions
    RtlpUnloadEventTraceExSize32 := RtlpUnloadEventTraceExSize32Cache;
    RtlpUnloadEventTraceExNumber32 := RtlpUnloadEventTraceExNumber32Cache;
    RtlpUnloadEventTraceEx32 := RtlpUnloadEventTraceEx32Cache;

    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  Result := NtxOpenSection(hxSection, SECTION_MAP_READ or SECTION_QUERY,
    '\KnownDlls32\ntdll.dll');

  if not Result.IsSuccess then
    Exit;

  // Map it
  Result := NtxMapViewOfSection(xNtdll32, hxSection.Handle,
    NtxCurrentProcess, PAGE_READONLY);

  if not Result.IsSuccess then
    Exit;

  // Parse the export table
  Result := RtlxEnumerateExportImage(ExportEntries, xNtdll32.Data,
    Cardinal(xNtdll32.Size), True);

  if not Result.IsSuccess then
    Exit;

  // Locate RtlGetUnloadEventTraceEx export
  ExportEntry := RtlxFindExportedName(ExportEntries,
    'RtlGetUnloadEventTraceEx');

  if not Assigned(ExportEntry) then
  begin
    Result.Location := 'NtxEnumerateUnloadedModulesProcessWoW64';
    Result.Status := STATUS_ENTRYPOINT_NOT_FOUND;
    Exit;
  end;

  // Locate the code for RtlGetUnloadEventTraceEx
  Code := xNtdll32.Offset(ExportEntry.VirtualAddress);

  // Make sure we are parsing the correct code
  if (Code.Prolog <> Code.PROLOG_VALUE) or
    (Code.OpMov1 <> Code.OP_MOV_VALUE) or
    (Code.OpMov2 <> Code.OP_MOV_VALUE) or
    (Code.OpMov3 <> Code.OP_MOV_VALUE) then
  begin
    Result.Location := 'NtxEnumerateUnloadedModulesProcessWoW64';
    Result.Status := STATUS_UNKNOWN_REVISION;
    Exit;
  end;

  // Locate system-wide WoW64 trace definitions
  RtlpUnloadEventTraceExSize32 := Code.RtlpUnloadEventTraceExSize;
  RtlpUnloadEventTraceExNumber32 := Code.RtlpUnloadEventTraceExNumber;
  RtlpUnloadEventTraceEx32 := Code.RtlpUnloadEventTraceEx;

  // Cache the result for future use
  RtlpUnloadEventTraceExSize32Cache := RtlpUnloadEventTraceExSize32;
  RtlpUnloadEventTraceExNumber32Cache := RtlpUnloadEventTraceExNumber32;
  RtlpUnloadEventTraceEx32Cache := RtlpUnloadEventTraceEx32;
  RtlpUnloadEventTraceEx32CacheInitialized := True;
end;

function NtxEnumerateUnloadedModulesProcessWoW64;
var
  RtlpUnloadEventTraceExSize32: PCardinal;
  RtlpUnloadEventTraceExNumber32: PCardinal;
  RtlpUnloadEventTraceEx32: PPRtlUnloadEventTrace32;
  Size: Cardinal;
  Count, ActualCount: Cardinal;
  TraceRef: Wow64Pointer<PRtlUnloadEventTrace32>;
  Trace: IMemory<PRtlUnloadEventTrace32>;
  TraceEntry: PRtlUnloadEventTrace32;
  i: Integer;
begin
  // Get the pointer to the trace definitions from WoW64 ntdll
  Result := RtlxGetUnloadEventTraceEx32(RtlpUnloadEventTraceExSize32,
    RtlpUnloadEventTraceExNumber32, RtlpUnloadEventTraceEx32);

  // Get the trace pointer
  Result := NtxMemory.Read(hProcess, RtlpUnloadEventTraceEx32, TraceRef);

  if not Result.IsSuccess then
    Exit;

  if TraceRef.Value = 0 then
  begin
    // Nothing in the trace
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Get the element number
  Result := NtxMemory.Read(hProcess, RtlpUnloadEventTraceExNumber32, Count);

  if not Result.IsSuccess then
    Exit;

  if Count = 0 then
  begin
    // Nothing in the trace
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Get the element size
  Result := NtxMemory.Read(hProcess, RtlpUnloadEventTraceExSize32, Size);

  if not Result.IsSuccess then
    Exit;

  if (Size < SizeOf(TRtlUnloadEventTrace32)) or
    (UInt64(Size) * Count > BUFFER_LIMIT) then
  begin
    Result.Location := 'NtxEnumerateUnloadedModulesProcessNative';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  // Read the trace
  Result := NtxReadMemoryAuto(hProcess, TraceRef.Self,
    Size * Count, IMemory(Trace));

  if not Result.IsSuccess then
    Exit;

  // Compute the number of elements with valid data
  ActualCount := 0;
  TraceEntry := Trace.Data;

  for i := 0 to Pred(Count) do
  begin
    if TraceEntry.BaseAddress.Value <> 0 then
      Inc(ActualCount);

    Inc(PByte(TraceEntry), Size);
  end;

  // Save them
  SetLength(UnloadedModules, ActualCount);

  ActualCount := 0;
  TraceEntry := Trace.Data;

  for i := 0 to Pred(Count) do
  begin
    if TraceEntry.BaseAddress.Value <> 0 then
      with UnloadedModules[ActualCount] do
      begin
        Sequence := TraceEntry.Sequence;
        BaseAddress := TraceEntry.BaseAddress.Self;
        SizeOfImage := TraceEntry.SizeOfImage;
        TimeDateStamp := TraceEntry.TimeDateStamp;
        CheckSum := TraceEntry.CheckSum;
        Version := TraceEntry.Version;
        ImageName := RtlxCaptureString(TraceEntry.ImageName, 32);
        Inc(ActualCount);
      end;

    Inc(PByte(TraceEntry), Size);
  end;
end;
{$ENDIF}

end.
