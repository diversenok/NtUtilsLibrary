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
function RtlxGenerateSyscallEntrypoints(hProcess: THandle; SyscallNumbers:
  TArray<Cardinal>; out Functions: TArray<Pointer>; out CodeRegion: TMemory)
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

function RtlxGenerateSyscallEntrypoints(hProcess: THandle; SyscallNumbers:
  TArray<Cardinal>; out Functions: TArray<Pointer>; out CodeRegion: TMemory)
  : TNtxStatus;
var
  Template: TSyscallTemplate64;
  pEntry: PSyscallTemplate64;
  RemoteCode: TMemory;
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
  Result := NtxAllocateMemoryProcess(NtCurrentProcess,
    SizeOf(Template) * Length(SyscallNumbers), CodeRegion);

  if not Result.IsSuccess then
    Exit;

  Template.Head := MOV_R10_RCX_MOV_EAX;
  Template.Tail := SYSCALL_RET_INT3;
  Template.Padding := INT3_INT3_INT3_INT3;

  pEntry := CodeRegion.Address;
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
  if hProcess <> NtCurrentProcess then
  begin
    // Allocate some space in the remote process
    Result := NtxAllocateMemoryProcess(hProcess, CodeRegion.Size, RemoteCode);

    // Undo code generation on failure
    if not Result.IsSuccess then
    begin
      NtxFreeMemoryProcess(NtCurrentProcess, CodeRegion.Address,
        CodeRegion.Size);
      Exit;
    end;

    pEntry := RemoteCode.Address;

    // Save remote function pointers instead of local
    for i := 0 to High(Functions) do
    begin
      Functions[i] := pEntry;
      Inc(pEntry);
    end;

    // Write the code to the target
    Result := NtxWriteMemoryProcess(hProcess, RemoteCode.Address,
      CodeRegion.Address, CodeRegion.Size);

    // We don't need local buffer anymore
    NtxFreeMemoryProcess(NtCurrentProcess, CodeRegion.Address, CodeRegion.Size);
    CodeRegion := RemoteCode;

    // Undo remote allocation on failure
    if not Result.IsSuccess then
    begin
      NtxFreeMemoryProcess(NtCurrentProcess, RemoteCode.Address,
        RemoteCode.Size);
      Exit;
    end;
  end;

  // Make the memory executable
  Result := NtxProtectMemoryProcess(hProcess, CodeRegion, PAGE_EXECUTE_READ);

  // Flush the processor cache or undo allocation
  if Result.IsSuccess then
    NtxFlushInstructionCache(hProcess, CodeRegion.Address, CodeRegion.Size)
  else
    NtxFreeMemoryProcess(hProcess, CodeRegion.Address, CodeRegion.Size);
end;

{ ----------------------------- ntdll endpoints ----------------------------- }

var
  ntdllSyscallsInitialized: Boolean;
  ntdllSyscallDefs: TArray<TSyscall>;
  ntdllSyscallTargets: TArray<Pointer>;
  ntdllSyscallArea: TMemory;

function NtxInitializeNtdllSyscallArea: TNtxStatus;
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
  Result := RtlxGenerateSyscallEntrypoints(NtCurrentProcess, SyscallNumbers,
    ntdllSyscallTargets, ntdllSyscallArea);

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

var
  // Global anti-hooking policy
  ntdllAntiHookEnabled: Boolean;

  // Beggining of IAT section for ntdll
  ntdllIAT: ^TAnysizeArray<Pointer>;

  // Description of each IAT entry for ntdll
  ntdllImportInitialized: Boolean;
  ntdllImport: TArray<TImportEntryEx>;

function NtxPrepareNtdllUnhooking: TNtxStatus;
var
  ImageInfo: TMemoryImageInformation;
  Entries: TArray<TImportDllEntry>;
  i: Integer;
begin
  if ntdllImportInitialized then
  begin
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Prepare unhooking for ntdll
  Result := NtxInitializeNtdllSyscallArea;

  if not Result.IsSuccess then
    Exit;

  // Determine our image's size
  Result := NtxMemory.Query(NtCurrentProcess, @ImageBase,
    MemoryImageInformation, ImageInfo);

  if not Result.IsSuccess then
    Exit;

  // Enumerate our import
  Result := RtlxEnumerateImportImage(ImageInfo.ImageBase, ImageInfo.SizeOfImage,
    True, Entries);

  if not Result.IsSuccess then
    Exit;

  // Find ntdll import
  i := TArrayHelper.IndexOf<TImportDllEntry>(Entries,
    function (const Entry: TImportDllEntry): Boolean
    begin
      Result := Entry.DllName = ntdll;
    end
  );

  if i = -1 then
  begin
    Result.Location := 'NtxPrepareNtdllUnhooking';
    Result.Status := STATUS_DLL_NOT_FOUND;
    Exit;
  end;

  ntdllIAT := Pointer(UIntPtr(@ImageBase) + Entries[i].IAT);

  // Save import names and find corresponding dynamic etrypoints
  ntdllImport := TArrayHelper.Map<TImportEntry, TImportEntryEx>(
    Entries[i].Functions,
    function (const Import: TImportEntry): TImportEntryEx
    begin
      Result.Name := Import.Name;
      Result.OrignalTarget := nil;
      Result.Unhooked := False;
      Result.PolicyOverride := AntiHookUseGlobal;

      // Find our dynamically generated entrypoint
      Result.AntiHookIndex := TArrayHelper.IndexOf<TSyscall>(ntdllSyscallDefs,
        function (const Syscall: TSyscall): Boolean
        begin
          Result := Syscall.ExportEntry.Name = Import.Name;
        end
      );
    end
  );

  ntdllImportInitialized := True;
end;

function SwapIATTarget(Index: Integer; Unhook: Boolean): Boolean;
begin
  Result := ntdllImport[Index].AntiHookIndex >= 0;

  if not Result or (ntdllImport[Index].Unhooked = Unhook) then
    Exit;

  if Unhook then
  begin
    // Save original import and replace it with unhooked entrypoint
    ntdllImport[Index].OrignalTarget := AtomicExchange(
      ntdllIAT{$R-}[Index]{$R+}, ntdllSyscallTargets[
      ntdllImport[Index].AntiHookIndex]);

    ntdllImport[Index].Unhooked := True;
  end
  else if Assigned(ntdllImport[Index].OrignalTarget) then
  begin
    ntdllIAT{$R-}[Index]{$R+} := ntdllImport[Index].OrignalTarget;
    ntdllImport[Index].Unhooked := False;
  end;
end;

function RtlxEnforceAntiHookPolicy(EnableAntiHooking: Boolean;
  ClearOverrides: Boolean): TNtxStatus;
var
  i: Integer;
begin
  // Initialize unhooking
  Result := NtxPrepareNtdllUnhooking;

  if not Result.IsSuccess then
    Exit;

  ntdllAntiHookEnabled := EnableAntiHooking;

  // Enforce the policy where possible
  for i := 0 to High(ntdllImport) do
    if ClearOverrides or (ntdllImport[i].PolicyOverride = AntiHookUseGlobal) then
      SwapIATTarget(i, EnableAntiHooking);
end;

function RtlxOverrideAntiHookPolicy(ExternalImport: Pointer; Policy:
  TAntiHookPolicyOverride): TNtxStatus;
var
  IATEntry: PPointer;
  IATIndex: Cardinal;
  Enable: Boolean;
begin
  // Initizlize unhooking
  Result := NtxPrepareNtdllUnhooking;

  if not Result.IsSuccess then
    Exit;

  IATEntry := ExternalImportTarget(ExternalImport);

  // Check the target IAT entry
  if (UIntPtr(IATEntry) < UIntPtr(ntdllIAT)) or
    (UIntPtr(IATEntry) >= UIntPtr(ntdllIAT) +
    Cardinal(Length(ntdllImport)) * SizeOf(Pointer)) or
    (UIntPtr(IATEntry) and (SizeOf(Pointer) - 1) <> 0) then
  begin
    Result.Location := 'NtxOverrideAntiHookPolicy';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  IATIndex := (UIntPtr(IATEntry) - UIntPtr(ntdllIAT)) shr PTR_SHIFT;
  ntdllImport[IATIndex].PolicyOverride := Policy;

  if Policy = AntiHookUseGlobal then
    Enable := ntdllAntiHookEnabled
  else
    Enable := Policy = AntiHookEnabled;

  if SwapIATTarget(IATIndex, Enable) then
    Result.Status := STATUS_SUCCESS
  else
    Result.Status := STATUS_NOT_SUPPORTED;
end;
{$ENDIF}

end.
