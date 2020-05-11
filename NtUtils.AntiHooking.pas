unit NtUtils.AntiHooking;

interface

uses
  NtUtils;

{$IFDEF Win64} // Syscall entrypoint unhooking is supported only on x64 systems
type
  TAntiHookPolicyOverride = (
    AntiHookUseGlobal,
    AntiHookEnabled,
    AntiHookDisabled
  );

// Dynamically generate unpatched code that issues syscalls.
function RtlxGenerateSyscallEntrypoints(hxProcess: IHandle; SyscallNumbers:
  TArray<Cardinal>; out Functions: TArray<Pointer>; out CodeRegion: IMemory)
  : TNtxStatus;

// Unhook all syscall functions in ntdll
function RtlxEnforceAntiHookPolicy(EnableAntiHooking: Boolean;
  ClearOverrides: Boolean = False): TNtxStatus;

// Enable/disable unhooking on a per-function basis
function RtlxOverrideAntiHookPolicy(ExternalImport: Pointer; Policy:
  TAntiHookPolicyOverride): TNtxStatus;
{$ENDIF}

implementation

{$IFDEF Win64}
uses
  Ntapi.ntdef, Winapi.WinNt, Ntapi.ntmmapi, Ntapi.ntpsapi, Ntapi.ntstatus,
  NtUtils.Sections, NtUtils.Processes.Memory, NtUtils.ImageHlp,
  NtUtils.ImageHlp.Syscalls, DelphiUtils.Arrays, DelphiUtils.ExternalImport;

const
  // Assembly x64 template
  MOV_R10_RCX_MOV_EAX = $B8D18B4C;
  SYSCALL_RET_INT3 = $CCC3050F;
  INT3_INT3_INT3_INT3 = $CCCCCCCC;

type
  // x64 template for dynamic code generation
  TSyscallTemplate64 = record
    Head: Cardinal;          {4C 8B D1 B8} // mov r10, rcx; mov eax, ...
    SyscallNumber: Cardinal; {xx xx xx xx}
    Tail: Cardinal;          {0F 05 C3 CC} // syscall; ret; int 3
    Padding: Cardinal;       {CC CC CC CC} // int 3 (x4)
  end;
  PSyscallTemplate64 = ^TSyscallTemplate64;

function RtlxGenerateSyscallEntrypoints(hxProcess: IHandle; SyscallNumbers:
  TArray<Cardinal>; out Functions: TArray<Pointer>; out CodeRegion: IMemory)
  : TNtxStatus;
var
  Template: TSyscallTemplate64;
  pEntry: PSyscallTemplate64;
  RemoteCode: IMemory;
  i: Integer;
begin
  if USER_SHARED_DATA.SystemCall = SYSTEM_CALL_INT_2E then
  begin
    // Our template is not good for systems that use int 2E instead of sycall.
    Result.Location := 'NtxGenerateSyscallEntrypoints';
    Result.Status := STATUS_ASSERTION_FAILURE;
    Exit;
  end;

  // Allocate local space for our runtime code generation
  Result := NtxAllocateMemoryProcess(NtxCurrentProcess,
    SizeOf(Template) * Length(SyscallNumbers), CodeRegion);

  if not Result.IsSuccess then
    Exit;

  Template.Head := MOV_R10_RCX_MOV_EAX;
  Template.Tail := SYSCALL_RET_INT3;
  Template.Padding := INT3_INT3_INT3_INT3;

  pEntry := CodeRegion.Data;
  SetLength(Functions, Length(SyscallNumbers));

  for i := 0 to High(SyscallNumbers) do
  begin
    // Fill it in with a template, substituting syscall numbers
    Template.SyscallNumber := SyscallNumbers[i];
    pEntry^ := Template;
    Functions[i] := pEntry;
    Inc(pEntry);
  end;

  // Non-local targets require more processing
  if hxProcess.Handle <> NtCurrentProcess then
  begin
    // Allocate some space in the remote process
    Result := NtxAllocateMemoryProcess(hxProcess, CodeRegion.Size, RemoteCode);

    // Undo code generation on failure
    if not Result.IsSuccess then
      Exit;

    pEntry := RemoteCode.Data;

    // Save remote function pointers instead of local
    for i := 0 to High(Functions) do
    begin
      Functions[i] := pEntry;
      Inc(pEntry);
    end;

    // Write the code to the target
    Result := NtxWriteMemoryProcess(hxProcess.Handle, RemoteCode.Data,
      CodeRegion.Data, CodeRegion.Size);

    // We don't need local buffer anymore
    CodeRegion := RemoteCode;

    if not Result.IsSuccess then
    begin
      CodeRegion := nil;
      Exit;
    end;
  end;

  // Make the memory executable
  Result := NtxProtectMemoryProcess(hxProcess.Handle, CodeRegion.Data,
    CodeRegion.Size, PAGE_EXECUTE_READ);

  // Flush the processor cache or undo allocation
  if Result.IsSuccess then
    NtxFlushInstructionCache(hxProcess.Handle, CodeRegion.Data, CodeRegion.Size)
  else
    CodeRegion := nil;
end;

{ ----------------------------- ntdll endpoints ----------------------------- }

var
  ntdllSyscallsInitialized: Boolean;
  ntdllSyscallDefs: TArray<TSyscall>;
  ntdllSyscallTargets: TArray<Pointer>;
  ntdllSyscallArea: TMemory;

function InitializeNtdllSyscallArea: TNtxStatus;
var
  hxSection: IHandle;
  xMemory: IMemory;
  SyscallNumbers: TArray<Cardinal>;
  i: Integer;
begin
  // Init once
  if ntdllSyscallsInitialized then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Map an unmodified ntdll directly from KnowDlls
  Result := RtlxMapKnownDll(hxSection, ntdll, False, xMemory);

  if not Result.IsSuccess then
    Exit;

  // Find all syscalls in it
  Result := RtlxEnumerateSycallsDll(xMemory.Data, xMemory.Size, True,
    ntdllSyscallDefs);

  if not Result.IsSuccess then
    Exit;

  SetLength(SyscallNumbers, Length(ntdllSyscallDefs));

  for i := 0 to High(SyscallNumbers) do
    SyscallNumbers[i] := ntdllSyscallDefs[i].SyscallNumber;

  // Allocate our own collection of unpatched syscall entrypoints
  Result := RtlxGenerateSyscallEntrypoints(NtxCurrentProcess, SyscallNumbers,
    ntdllSyscallTargets, xMemory);

  if Result.IsSuccess then
  begin
    // We won't ever release code memory since it might be used at any point
    xMemory.AutoRelease := False;
    ntdllSyscallArea := xMemory.Region;
  end;

  ntdllSyscallsInitialized := Result.IsSuccess;
end;

{ ----------------------------- ntdll unhooking ----------------------------- }

type
  TImportEntryEx = record
    Name: AnsiString;
    PolicyOverride: TAntiHookPolicyOverride;
    Unhooked: Boolean;
    AntiHookIndex: Integer;
    OrignalTarget: Pointer;
  end;

  TIATSection = TAnysizeArray<Pointer>;
  PIATSection = ^TIATSection;

var
  ntdllAntiHookEnabled: Boolean; // Global anti-hooking policy
  ntdllImportInitialized: Boolean; // Init once

  // Beggining of IAT section for regular/delay imports
  ntdllIAT, ntdllDelayIAT: PIATSection;

  // Definitions of each imported function from ntdll
  ntdllImport, ntdllDelayImport: TArray<TImportEntryEx>;

procedure SaveNtdllImports(Entries: TArray<TImportDllEntry>;
  out IATSection: PIATSection; out EntriesEx: TArray<TImportEntryEx>);
var
  i: Integer;
begin
  // Find ntdll import
  i := TArray.IndexOf<TImportDllEntry>(Entries,
    function (const Entry: TImportDllEntry): Boolean
    begin
      Result := Entry.DllName = ntdll;
    end
  );

  if i = -1 then
    Exit;

  // Save import names and find corresponding dynamic etrypoints
  EntriesEx := TArray.Map<TImportEntry, TImportEntryEx>(
    Entries[i].Functions,
    function (const Import: TImportEntry): TImportEntryEx
    var
      pImport: ^TImportEntry;
    begin
      Result.Name := Import.Name;
      Result.OrignalTarget := nil;
      Result.Unhooked := False;
      Result.PolicyOverride := AntiHookUseGlobal;

      // Older versions of Delphi refuse to capute Import variable in a
      // nested anonymous function. Make a refernce here to avoid copying it.
      pImport := @Import;

      // Find our dynamically generated entrypoint
      Result.AntiHookIndex := TArray.IndexOf<TSyscall>(ntdllSyscallDefs,
        function (const Syscall: TSyscall): Boolean
        begin
          Result := Syscall.ExportEntry.Name = pImport.Name;
        end
      );
    end
  );

  if Length(EntriesEx) > 0 then
    IATSection := Pointer(UIntPtr(@ImageBase) + Entries[i].IAT);
end;

function PrepareNtdllUnhooking: TNtxStatus;
var
  ImageInfo: TMemoryImageInformation;
  Import, DelayedImport: TArray<TImportDllEntry>;
begin
  if ntdllImportInitialized then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Prepare unhooking for ntdll
  Result := InitializeNtdllSyscallArea;

  if not Result.IsSuccess then
    Exit;

  // Determine our image's size
  Result := NtxMemory.Query(NtCurrentProcess, @ImageBase,
    MemoryImageInformation, ImageInfo);

  if not Result.IsSuccess then
    Exit;

  // Enumerate our import
  Result := RtlxEnumerateImportImage(ImageInfo.ImageBase, ImageInfo.SizeOfImage,
    True, Import);

  if not Result.IsSuccess then
    Exit;

  // Enumerate our delayed import
  Result := RtlxEnumerateDelayImportImage(ImageInfo.ImageBase,
    ImageInfo.SizeOfImage, True, DelayedImport);

  if not Result.IsSuccess then
    Exit;

  // Save IAT locations and import definitions
  SaveNtdllImports(Import, ntdllIAT, ntdllImport);
  SaveNtdllImports(DelayedImport, ntdllDelayIAT, ntdllDelayImport);

  ntdllImportInitialized := True;
end;

function SwapIATTarget(IATSeciont: PIATSection; IATDescription:
  TArray<TImportEntryEx>; Index: Integer; Unhook: Boolean): Boolean;
begin
  Result := IATDescription[Index].AntiHookIndex >= 0;

  if not Result or (IATDescription[Index].Unhooked = Unhook) then
    Exit;

  if Unhook then
  begin
    // Save original import and replace it with unhooked entrypoint
    IATDescription[Index].OrignalTarget := AtomicExchange(
      IATSeciont{$R-}[Index]{$R+}, ntdllSyscallTargets[
      IATDescription[Index].AntiHookIndex]);

    IATDescription[Index].Unhooked := True;
  end
  else if Assigned(IATDescription[Index].OrignalTarget) then
  begin
    IATSeciont{$R-}[Index]{$R+} := IATDescription[Index].OrignalTarget;
    IATDescription[Index].Unhooked := False;
  end;
end;

function RtlxEnforceAntiHookPolicy(EnableAntiHooking: Boolean;
  ClearOverrides: Boolean): TNtxStatus;
var
  i: Integer;
begin
  // Initialize unhooking
  Result := PrepareNtdllUnhooking;

  if not Result.IsSuccess then
    Exit;

  ntdllAntiHookEnabled := EnableAntiHooking;

  // Enforce the policy on regular import
  for i := 0 to High(ntdllImport) do
    if ClearOverrides or (ntdllImport[i].PolicyOverride =
      AntiHookUseGlobal) then
      SwapIATTarget(ntdllIAT, ntdllImport, i, EnableAntiHooking);

  // Enforce the policy on delayeds import
  for i := 0 to High(ntdllDelayImport) do
    if ClearOverrides or (ntdllDelayImport[i].PolicyOverride =
      AntiHookUseGlobal) then
      SwapIATTarget(ntdllDelayIAT, ntdllDelayImport, i, EnableAntiHooking);
end;

function FindIATSectionByEntry(Section: PIATSection; Count: Cardinal;
  IATEntry: PPointer; out Index: Cardinal): Boolean;
begin
  Result := Assigned(Section) and
    (UIntPtr(IATEntry) and (SizeOf(Pointer) - 1) = 0) and
    (UIntPtr(IATEntry) >= UIntPtr(Section)) and
    (UIntPtr(IATEntry) < UIntPtr(Section) + Count * SizeOf(Pointer));

  if Result then
    Index := (UIntPtr(IATEntry) - UIntPtr(Section)) shr PTR_SHIFT;
end;

function RtlxOverrideAntiHookPolicy(ExternalImport: Pointer; Policy:
  TAntiHookPolicyOverride): TNtxStatus;
var
  IATEntry: PPointer;
  Index: Cardinal;
  Enable: Boolean;
  Section: PIATSection;
  Definition: TArray<TImportEntryEx>;
begin
  // Initizlize unhooking
  Result := PrepareNtdllUnhooking;

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RtlxOverrideAntiHookPolicy';
  IATEntry := ExternalImportTarget(ExternalImport);

  // Check regular import
  if FindIATSectionByEntry(ntdllIAT, Length(ntdllImport), IATEntry, Index)
    then
  begin
    Section := ntdllIAT;
    Definition := ntdllImport;
  end
  // Check delayed import
  else if FindIATSectionByEntry(ntdllDelayIAT, Length(ntdllDelayImport),
    IATEntry, Index) then
  begin
    Section := ntdllDelayIAT;
    Definition := ntdllDelayImport;
  end
  else
  begin
    Result.Status := STATUS_NOT_FOUND;
    Exit;
  end;

  // Save new policy state
  Definition[Index].PolicyOverride := Policy;

  if Policy = AntiHookUseGlobal then
    Enable := ntdllAntiHookEnabled
  else
    Enable := Policy = AntiHookEnabled;

  // Update IAT target
  if SwapIATTarget(Section, Definition, Index, Enable) then
    Result.Status := STATUS_SUCCESS
  else
    Result.Status := STATUS_NOT_SUPPORTED;
end;
{$ENDIF}

end.
