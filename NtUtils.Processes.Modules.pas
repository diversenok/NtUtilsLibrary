unit NtUtils.Processes.Modules;

interface

uses
  Ntapi.ntpsapi, NtUtils.Exceptions, NtUtils.Ldr;

const
  PROCESS_ENUMERATE_MODULES = PROCESS_QUERY_LIMITED_INFORMATION or
    PROCESS_VM_READ;

type
  TModuleEntry = NtUtils.Ldr.TModuleEntry;

// Enumerate modules loaded by a process
function NtxEnumerateModulesProcess(hProcess: THandle; out Modules:
  TArray<TModuleEntry>; IsWoW64: PBoolean = nil): TNtxStatus;

// Enumerate native modules loaded by a process
function NtxEnumerateModulesProcessNative(hProcess: THandle; out Modules:
  TArray<TModuleEntry>): TNtxStatus;

{$IFDEF Win64}
// Enumerate WoW64 modules loaded by a process
function NtxEnumerateModulesProcessWoW64(hProcess: THandle; out Modules:
  TArray<TModuleEntry>): TNtxStatus;
{$ENDIF}

// A parent checker to use with TArrayHelper.BuildTree<TModuleEntry>
function IsParentModule(const Parent, Child: TModuleEntry): Boolean;

implementation

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntldr, Ntapi.ntstatus,
  Ntapi.ntwow64, NtUtils.Version, NtUtils.Processes, NtUtils.Processes.Memory;

function NtxEnumerateModulesProcess(hProcess: THandle; out Modules:
  TArray<TModuleEntry>; IsWoW64: PBoolean): TNtxStatus;
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

function NtxEnumerateModulesProcessNative(hProcess: THandle; out Modules:
  TArray<TModuleEntry>): TNtxStatus;
var
  BasicInfo: TProcessBasicInformation;
  pLdr: PPebLdrData;
  Ldr: TPebLdrData;
  i: Integer;
  pStart, pCurrent: PListEntry;
  Current: TLdrDataTableEntry;
  OsVersion: TKnownOsVersion;
  EntrySize: NativeUInt;
  StringBuffer: PWideChar;
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

    // TODO: Try to figure out how to get modules in this case like PH does
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

  StringBuffer := AllocMem(MAX_UNICODE_STRING_SIZE);

  while (pStart <> pCurrent) and (i <= MAX_MODULES) do
  begin
    // Read the entry
    Result := NtxReadMemoryProcess(hProcess, pCurrent, @Current, EntrySize);

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
      if NtxReadMemoryProcess(hProcess, Current.FullDllName.Buffer,
        StringBuffer, Current.FullDllName.Length).IsSuccess then
      begin
        Current.FullDllName.Buffer := StringBuffer;
        FullDllName := Current.FullDllName.ToString;
      end;

      // Retrieve short module name
      if NtxReadMemoryProcess(hProcess, Current.BaseDllName.Buffer,
        StringBuffer, Current.BaseDllName.Length).IsSuccess then
      begin
        Current.BaseDllName.Buffer := StringBuffer;
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

  FreeMem(StringBuffer);
end;

{$IFDEF Win64}
function NtxEnumerateModulesProcessWoW64(hProcess: THandle; out Modules:
  TArray<TModuleEntry>): TNtxStatus;
var
  Peb32: PPeb32;
  pLdr: Wow64Pointer;
  Ldr: TPebLdrData32;
  i: Integer;
  pStart, pCurrent: PListEntry32;
  Current: TLdrDataTableEntry32;
  OsVersion: TKnownOsVersion;
  EntrySize: NativeUInt;
  Str: UNICODE_STRING;
  StringBuffer: PWideChar;
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
  Result := NtxMemory.Read(hProcess, Pointer(pLdr), Ldr);

  if Result.Matches(STATUS_PARTIAL_COPY, 'NtReadVirtualMemory') and
    not Ldr.Initialized then
  begin
    // The loader is not initialized yet, probably we work with
    // a newly created suspended process.
    SetLength(Modules, 0);

    // TODO: Try to figure out how to get WoW64 modules in this case.
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
  pStart := @PPebLdrData32(pLdr).InLoadOrderModuleList;
  pCurrent := Pointer(Ldr.InLoadOrderModuleList.Flink);
  SetLength(Modules, 0);

  StringBuffer := AllocMem(MAX_UNICODE_STRING_SIZE);
  Str.Buffer := StringBuffer;

  while (pStart <> pCurrent) and (i <= MAX_MODULES) do
  begin
    // Read the entry
    Result := NtxReadMemoryProcess(hProcess, pCurrent, @Current, EntrySize);

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
      if NtxReadMemoryProcess(hProcess, Pointer(Current.FullDllName.Buffer),
        StringBuffer, Current.FullDllName.Length).IsSuccess then
      begin
        Str.Length := Current.FullDllName.Length;
        Str.MaximumLength := Current.FullDllName.MaximumLength;
        FullDllName := Str.ToString;
      end;

      // Retrieve short module name
      if NtxReadMemoryProcess(hProcess, Pointer(Current.BaseDllName.Buffer),
        StringBuffer, Current.BaseDllName.Length).IsSuccess then
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

  FreeMem(StringBuffer);
end;
{$ENDIF}

function IsParentModule(const Parent, Child: TModuleEntry): Boolean;
begin
  Result := (Child.ParentDllBase = Parent.DllBase);
end;

end.
