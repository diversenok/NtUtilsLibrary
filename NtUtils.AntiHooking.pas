unit NtUtils.AntiHooking;

{
  This module provides facilities for automatically redirecting calls to
  functions from ntdll into local trampolines. It allows bypassing user-mode
  hooks on by issuing system calls directly.
}

interface

uses
  NtUtils;

type
  TAntiHookPolicyOverride = (
    AntiHookUseGlobal,
    AntiHookEnabled,
    AntiHookDisabled
  );

// NOTE: currently, anti-hooking works only for 64-bit images

// Unhook all syscall functions in ntdll
function RtlxEnforceAntiHookPolicy(
  EnableAntiHooking: Boolean;
  ClearOverrides: Boolean = False
): TNtxStatus;

// Enable/disable unhooking on a per-function basis
function RtlxOverrideAntiHookPolicy(
  [in] ExternalImport: Pointer;
  Policy: TAntiHookPolicyOverride
): TNtxStatus;
  
implementation

uses
  Ntapi.ntdef, Ntapi.ntpsapi, Ntapi.ntmmapi, Ntapi.ntstatus,
  NtUtils.ImageHlp, NtUtils.ImageHlp.Syscalls, NtUtils.Sections,
  NtUtils.Memory, NtUtils.AntiHooking.Trampoline, DelphiUtils.Arrays,
  DelphiUtils.ExternalImport;

type
  TAntiHookEntry = record
    Name: AnsiString;
    IAT: PPointer;
    PolicyOverride: TAntiHookPolicyOverride;
    Enabled: Boolean;
    AlternateTarget: Pointer;
  end;
  PAntiHookDescriptor = ^TAntiHookEntry;

var
  Initialized, GlobalEnabled: Boolean;
  AntiHooks: TArray<TAntiHookEntry>;

function IsNtDll(const Entry: TImportDllEntry): Boolean;
begin
  Result := (Entry.DllName = ntdll);
end;

function EnumerateOurNtdllImport(
  out Entries: TArray<TAntiHookEntry>
): TNtxStatus;
var
  RegionInfo: TMemoryRegionInformation;
  Import: TArray<TImportDllEntry>;
begin
  // Determine our image's size
  Result := NtxMemory.Query(NtCurrentProcess, @ImageBase,
    MemoryRegionInformation, RegionInfo);

  if not Result.IsSuccess then
    Exit;

  // Enumerate our normal and delayed import
  Result := RtlxEnumerateImportImage(Import, RegionInfo.AllocationBase,
    RegionInfo.RegionSize, True);

  if not Result.IsSuccess then
    Exit;

  // Leave ntdll only
  TArray.FilterInline<TImportDllEntry>(Import, IsNtdll);

  // Collect and convert all entries
  Entries := TArray.Flatten<TImportDllEntry, TAntiHookEntry>(Import,
    function (const Dll: TImportDllEntry): TArray<TAntiHookEntry>
    var
      pDll: ^TImportDllEntry;
    begin
      // Fix `E2555 Cannot capture symbol` in older versions of Delphi
      pDll := @Dll;

      // Collect all named functions
      Result := TArray.ConvertEx<TImportEntry, TAntiHookEntry>(Dll.Functions,
        function (
          const Index: Integer;
          const Func: TImportEntry;
          out AntiHook: TAntiHookEntry
        ): Boolean
        begin
          Result := Func.ImportByName;

          if Result then
          begin
            // Calculate IAT address for each function
            AntiHook.Name := Func.Name;
            AntiHook.IAT := Pointer(UIntPtr(@ImageBase) + pDll.IAT +
              Cardinal(Index) * SizeOf(Pointer));
          end;
        end
      );
    end
  );
end;

function InitializeAntiHooking: TNtxStatus;
var
  xMemory: IMemory;
  Syscalls: TArray<TSyscallEntry>;
begin
  // Map an unmodified ntdll directly from KnowDlls
  Result := RtlxMapKnownDll(xMemory, ntdll, False);

  if not Result.IsSuccess then
    Exit;

  // Find all syscalls in it
  Result := RtlxEnumerateSycallsDll(xMemory.Data, xMemory.Size, True, Syscalls);

  if not Result.IsSuccess then
    Exit;

  // Find candidates for unhooking
  Result := EnumerateOurNtdllImport(AntiHooks);

  AntiHooks := TArray.Convert<TAntiHookEntry, TAntiHookEntry>(AntiHooks,
    function (
      const Entry: TAntiHookEntry;
      out SyscalledEntry: TAntiHookEntry
    ): Boolean
    var
      Trampoline: Pointer;
      pEntry: ^TAntiHookEntry;
    begin
      // Fix `E2555 Cannot capture symbol` in older versions of Delphi
      pEntry := @Entry;

      // Find a syscal with the same name
      Trampoline := TArray.ConvertFirstOrDefault<TSyscallEntry, Pointer>(
        Syscalls,
        function (
          const Syscall: TSyscallEntry;
          out Target: Pointer
        ): Boolean
        begin
          Result := (Syscall.ExportEntry.Name = pEntry.Name);

          if Result then
          begin
            // Locate a trampoline for it
            Target := SyscallTrampoline(Syscall.SyscallNumber);
            Result := Assigned(Target);
          end;
        end,
        nil
      );

      Result := Assigned(Trampoline);

      if Result then
      begin
        SyscalledEntry := Entry;
        SyscalledEntry.AlternateTarget := Trampoline;
      end;
    end
  );
end;

procedure AdjustTarget(var AntiHook: TAntiHookEntry; Enable: Boolean);
begin
  if AntiHook.Enabled = Enable then
    Exit;

  AntiHook.Enabled := Enable;

  // TODO: store a backup copy of trampoline address in case someone modifes IAT

  // Swap the target (original vs trampoline)
  AntiHook.AlternateTarget := AtomicExchange(AntiHook.IAT^,
    AntiHook.AlternateTarget);
end;

{ Public }

function RtlxEnforceAntiHookPolicy;
var
  i: Integer;
begin
  if not Initialized then
  begin
    Result := InitializeAntiHooking;

    if not Result.IsSuccess then
      Exit;

    Initialized := True;
  end;

  // Process all existing entries
  for i := 0 to High(AntiHooks) do
  begin
    // Clear or skip overrides
    if ClearOverrides then
      AntiHooks[i].PolicyOverride := AntiHookUseGlobal
    else if AntiHooks[i].PolicyOverride <> AntiHookUseGlobal then
      Exit;

    AdjustTarget(AntiHooks[i], EnableAntiHooking);
  end;

  GlobalEnabled := EnableAntiHooking;
end;

function RtlxOverrideAntiHookPolicy;
var
  i: Integer;
  IAT: PPointer;
begin
  if not Initialized then
  begin
    Result := InitializeAntiHooking;

    if not Result.IsSuccess then
      Exit;

    Initialized := True;
  end;

  Result.Location := 'RtlxOverrideAntiHookPolicy';
  IAT := ExternalImportTarget(ExternalImport);

  if not Assigned(IAT) then
  begin
    // The compiler produced the code we do not expect
    Result.Status := STATUS_UNSUCCESSFUL;
    Exit;
  end;

  // Find the anti hook entry
  for i := 0 to High(AntiHooks) do
    if AntiHooks[i].IAT = IAT then
    begin
      AntiHooks[i].PolicyOverride := Policy;

      AdjustTarget(AntiHooks[i], (Policy = AntiHookEnabled) or
        (GlobalEnabled and (Policy = AntiHookUseGlobal)));

      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

  Result.Status := STATUS_ENTRYPOINT_NOT_FOUND;
end;

end.
