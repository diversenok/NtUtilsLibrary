unit NtUtils.AntiHooking;

{
  This module introduces user-mode unhooking of ntdll functions via IAT
  modification. It works for native 32 and 64 bits, as well as under WoW64.
  Note that not all functions support unhooking, but syscall stubs always do.
}

interface

uses
  NtUtils, NtUtils.Ldr;

type
  TUnhookableImport = record
    FunctionName: AnsiString;
    IATEntry: PPointer;
    TargetRVA: Cardinal; // inside ntdll
  end;

// Find all imports of a module that can be unhooked via IAT modification
function RtlxFindUnhookableImport(
  const Module: TModuleEntry;
  out Entries: TArray<TUnhookableImport>
): TNtxStatus;

// Unhook the specified functions
function RtlxEnforceAntiHooking(
  const Imports: TArray<TUnhookableImport>;
  Enable: Boolean = True
): TNtxStatus;

// Unhook functions imported using Delphi's "external" keyword
// Example usage: RtlxEnforceExternalImportAntiHooking([@NtCreateUserProcess]);
function RtlxEnforceExternalImportAntiHooking(
  const ExtenalImports: TArray<Pointer>;
  Enable: Boolean = True
): TNtxStatus;

// Unhook specific functions for a single module
function RtlxEnforceModuleAntiHooking(
  const Module: TModuleEntry;
  const Functions: TArray<AnsiString>;
  Enable: Boolean = True
): TNtxStatus;

// Unhook specific functions for all currently loaded modules
function RtlxEnforceGlobalAntiHooking(
  const Functions: TArray<AnsiString>;
  Enable: Boolean = True
): TNtxStatus;

// Apply a custom IAT hook to a specific module
function RtlxInstallIATHook(
  out Reverter: IAutoReleasable;
  const ModuleName: String;
  const ImportModuleName: AnsiString;
  const ImportFunction: AnsiString;
  [in] Hook: Pointer;
  [out, opt] OriginalTarget: PPointer = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntldr, Ntapi.ntmmapi, Ntapi.ntpebteb, Ntapi.ntstatus,
  DelphiUtils.ExternalImport, NtUtils.Sections, NtUtils.ImageHlp,
  NtUtils.SysUtils, NtUtils.Memory, NtUtils.Processes, DelphiUtils.Arrays,
  DelphiApi.Reflection;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

var
  AlternateNtdllInitialized: Boolean;
  AlternateNtdll: IMemory;
  AlternateTargets: TArray<TExportEntry>;

// Note: we suppress range checking in these functions because hooked modules
// might have atypical layout (such as an import table outside of the image)

function RtlxInitializeAlternateNtdll: TNtxStatus;
begin
  if AlternateNtdllInitialized then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Map a second instance of ntdll from KnownDlls
  Result := RtlxMapKnownDll(AlternateNtdll, ntdll, RtlIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Parse its export and save all functions as available for redirection
  Result := RtlxEnumerateExportImage(AlternateTargets, AlternateNtdll.Region,
    True, False);

  if not Result.IsSuccess then
  begin
    AlternateNtdll := nil;
    Exit;
  end;

  AlternateNtdll.AutoRelease := False;
  AlternateNtdllInitialized := True;
end;

function UnhookableImportCapturer(
  [in] IAT: Pointer
): TConvertRoutineEx<TImportEntry, TUnhookableImport>;
begin
  Result := function (
    const Index: Integer;
    const Import: TImportEntry;
    out UnhookableImport: TUnhookableImport
  ): Boolean
  var
    i: Integer;
  begin
    // Find the export that corresponds to the function. Use fast binary search
    // when importing by name (which are sorted by default) or slow linear
    // search when importing by ordinal.

    if Import.ImportByName then
      i := TArray.BinarySearchEx<TExportEntry>(AlternateTargets,
        function (const Target: TExportEntry): Integer
        begin
          Result := RtlxCompareAnsiStrings(Target.Name, Import.Name, True)
        end
      )
    else
      i := TArray.IndexOfMatch<TExportEntry>(AlternateTargets,
        function (const Target: TExportEntry): Boolean
        begin
          Result := (Target.Ordinal = Import.Ordinal);
        end
      );

    if i < 0 then
      Exit(False);

    // Save the name, IAT entry address, and ntdll function RVA
    UnhookableImport.FunctionName := Import.Name;
    UnhookableImport.IATEntry := PPointer(PByte(IAT) +
      Cardinal(Index) * SizeOf(Pointer));
     UnhookableImport.TargetRVA := AlternateTargets[i].VirtualAddress;

    Result := True;
  end;
end;

function UnhookableImportFinder(
  [in] Base: Pointer
): TMapRoutine<TImportDllEntry, TArray<TUnhookableImport>>;
begin
  // Find and capture all functions that are imported from ntdll

  Result := function (const Dll: TImportDllEntry): TArray<TUnhookableImport>
  begin
    if RtlxEqualAnsiStrings(Dll.DllName, ntdll) then
      Result := TArray.ConvertEx<TImportEntry, TUnhookableImport>(Dll.Functions,
        UnhookableImportCapturer(PByte(Base) + Dll.IAT))
    else
      Result := nil;
  end
end;

function RtlxFindUnhookableImport;
var
  AllImport: TArray<TImportDllEntry>;
begin
  Result := RtlxInitializeAlternateNtdll;

  if not Result.IsSuccess then
    Exit;

  // Determine which functions a module imports
  Result := RtlxEnumerateImportImage(AllImport, Module.Region, True,
    [itNormal, itDelayed], False);

  if not Result.IsSuccess then
    Exit;

  // Intersect them with what we can unhook
  Entries := TArray.FlattenEx<TImportDllEntry, TUnhookableImport>(AllImport,
    UnhookableImportFinder(Module.DllBase));
end;

function RtlxEnforceAntiHooking;
var
  ImportGroups: TArray<TArrayGroup<Pointer, TUnhookableImport>>;
  ProtectionReverter: IAutoReleasable;
  TargetModule: Pointer;
  i, j: Integer;
begin
  Result := RtlxInitializeAlternateNtdll;

  if not Result.IsSuccess then
    Exit;

  // Choose where to redirect the functions
  if Enable then
    TargetModule := AlternateNtdll.Data
  else
    TargetModule := hNtdll.DllBase;

  // Combine entries that reside on the same page so we can change memory
  // protection more efficiently
  ImportGroups := TArray.GroupBy<TUnhookableImport, Pointer>(Imports,
    function (const Element: TUnhookableImport): Pointer
    begin
      Result := Pointer(UIntPtr(Element.IATEntry) and not (PAGE_SIZE - 1));
    end
  );

  for i := 0 to High(ImportGroups) do
  begin
    // Make sure the pages with IAT entries are writable
    Result := NtxProtectMemoryAuto(NtxCurrentProcess, ImportGroups[i].Key,
      PAGE_SIZE, PAGE_READWRITE, ProtectionReverter);

    if not Result.IsSuccess then
      Exit;

    // Redirect the import
    for j := 0 to High(ImportGroups[i].Values) do
      ImportGroups[i].Values[j].IATEntry^ := PByte(TargetModule) +
        ImportGroups[i].Values[j].TargetRVA;
  end;
end;

function RtlxEnforceExternalImportAntiHooking;
var
  CurrentModule: TModuleEntry;
  UnhookableImport: TArray<TUnhookableImport>;
  IATEntries: TArray<PPointer>;
  i: Integer;
begin
  Result := LdrxFindModule(CurrentModule, ContainingAddress(@ImageBase));

  if not Result.IsSuccess then
    Exit;

  // Find all imports from the current module that we can unhook
  Result := RtlxFindUnhookableImport(CurrentModule, UnhookableImport);

  if not Result.IsSuccess then
    Exit;

  // Determine IAT entry locations of the specified imports
  SetLength(IATEntries, Length(ExtenalImports));

  for i := 0 to High(IATEntries) do
    IATEntries[i] := ExternalImportTarget(ExtenalImports[i]);

  // Leave only the function we were asked to unhook
  TArray.FilterInline<TUnhookableImport>(UnhookableImport,
    function (const Import: TUnhookableImport): Boolean
    begin
      Result := TArray.Contains<PPointer>(IATEntries, Import.IATEntry);
    end
  );

  if Length(UnhookableImport) <> Length(ExtenalImports) then
  begin
    // Should not happen as long as the specified functions are imported via the
    // "extern" keyword.
    Result.Location := 'RtlxEnforceExternalImportAntiHooking';
    Result.Status := STATUS_ENTRYPOINT_NOT_FOUND;
    Exit;
  end;

  // Adjust IAT targets
  Result := RtlxEnforceAntiHooking(UnhookableImport, Enable);
end;

function RtlxEnforceModuleAntiHooking;
var
  UnhookableImport: TArray<TUnhookableImport>;
begin
  // Find what we can unhook
  Result := RtlxFindUnhookableImport(Module, UnhookableImport);

  if not Result.IsSuccess then
    Exit;

  // Include only the specified names
  TArray.FilterInline<TUnhookableImport>(UnhookableImport,
    function (const Import: TUnhookableImport): Boolean
    begin
      Result := TArray.Contains<AnsiString>(Functions, Import.FunctionName);
    end
  );

  // Adjust IAT targets
  if Length(UnhookableImport) > 0 then
    Result := RtlxEnforceAntiHooking(UnhookableImport, Enable)
  else
  begin
    Result.Location := 'RtlxEnforceModuleAntiHookingByName';
    Result.Status := STATUS_ALREADY_COMPLETE;
  end;
end;

function RtlxEnforceGlobalAntiHooking;
var
  Module: TModuleEntry;
begin
  for Module in LdrxEnumerateModules do
  begin
    Result := RtlxEnforceModuleAntiHooking(Module, Functions, Enable);

    if not Result.IsSuccess then
      Exit;
  end;
end;

function RtlxApplyPatch(
  [in, out, WritesTo] Address: PPointer;
  [in] Value: Pointer;
  [out, opt] OldValue: PPointer = nil
): TNtxStatus;
var
  ProtectionReverter: IAutoReleasable;
  Old: Pointer;
begin
  // Make address writable
  Result := NtxProtectMemoryAuto(NtxCurrentProcess, Address,
    SizeOf(Pointer), PAGE_READWRITE, ProtectionReverter);

  if not Result.IsSuccess then
    Exit;

  try
    Old := AtomicExchange(Address^, Value);

    if Assigned(OldValue) then
      OldValue^ := Old;
  except
    Result.Location := 'RtlxApplyIATPatch';
    Result.Status := STATUS_ACCESS_VIOLATION;
  end;
end;

function RtlxInstallIATHook;
var
  Module: TModuleEntry;
  ModuleRef: IAutoPointer;
  Imports: TArray<TImportDllEntry>;
  Address: PPointer;
  OldTarget: Pointer;
  i, j: Integer;
begin
  Result := LdrxLoadDllAuto(ModuleName, ModuleRef);

  if not Result.IsSuccess then
    Exit;

  Result := LdrxFindModule(Module, ContainingAddress(ModuleRef.Data));

  if not Result.IsSuccess then
    Exit;

  Result := RtlxEnumerateImportImage(Imports, Module.Region, True,
    [itNormal, itDelayed], False);

  if not Result.IsSuccess then
    Exit;

  for i := 0 to High(Imports) do
    if RtlxEqualAnsiStrings(Imports[i].DllName, ImportModuleName) then
    begin
      for j := 0 to High(Imports[i].Functions) do
        if Imports[i].Functions[j].ImportByName and
          (Imports[i].Functions[j].Name = ImportFunction) then
        begin
          Pointer(Address) := PByte(Module.DllBase) + Imports[i].IAT +
            SizeOf(Pointer) * j;

          // Patch the IAT entry
          Result := RtlxApplyPatch(Address, Hook, @OldTarget);

          if not Result.IsSuccess then
            Exit;

          Reverter := Auto.Delay(
            procedure
            begin
              // Restore the original target
              RtlxApplyPatch(Address, OldTarget);

              // Capture the module lifetime and release after unpatching
              ModuleRef := nil;
            end
          );

          if Assigned(OriginalTarget) then
            OriginalTarget^ := OldTarget;

          Exit;
        end;
      Break;
    end;

  Result.Location := 'RtlxSetHook';
  Result.Status := STATUS_ENTRYPOINT_NOT_FOUND;
end;

end.
