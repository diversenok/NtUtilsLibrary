unit NtUtils.ImageHlp.Syscalls;

interface

uses
  NtUtils, NtUtils.ImageHlp;

type
  TSyscall = record
    ExportEntry: TExportEntry;
    SyscallNumber: Cardinal;
  end;

// Extract syscall numbers from DLLs like ntdll.dll or win32u.dll
function NtxEnumerateSycallsDll(DllBase: Pointer; DllSize: Cardinal;
  out SysCalls: TArray<TSyscall>): TNtxStatus;

implementation

uses
  DelphiUtils.Arrays;

const
  // For parsing x64
  MOV_R10_RCX_MOV_EAX = Cardinal($B8D18B4C);
  SYSCALL = Word($050F);
  JNE_3 = Word($0375);
  RET_INT2E_RET = Cardinal($C32ECDC3);

type
  // Expected format of a syscall function on x64 systems
  TSyscallBody64 = record
    Head: Cardinal; {4C 8B D1 B8} // mov r10, rcx; mov eax, ...
    SyscallNumber: Cardinal; {xx xx xx xx}
  case Integer of
    7: (SyscallNoUserShared: Word; {0F 05} );
    10:
    (
      UserSharedTest: UInt64;  {F6 04 25 08 03 FE 7F 01}
                                // test USER_SHARED_DATA.SystemCall, 1
      Jne3: Word;              {75 03} // jne 3
      SysCallUserShared: Word; {0F 05} // syscall
      Int2EPath: Cardinal;     {C3 CD 2E C3 } // ret; int 2E; ret
    );
  end;
  PSyscallBody64 = ^TSyscallBody64;

function NtxEnumerateSycallsDll(DllBase: Pointer; DllSize: Cardinal;
  out SysCalls: TArray<TSyscall>): TNtxStatus;
var
  ExportEntries: TArray<TExportEntry>;
begin
  // Find all exported functions
  Result := RtlxEnumerateExportImage(DllBase, DllSize, True, ExportEntries);

  if not Result.IsSuccess then
    Exit;

  // Find all entries that match a function with a syscall and determine its
  // SyscallNumber

  SysCalls := TArrayHelper.Convert<TExportEntry, TSyscall>(ExportEntries,
    function (const Entry: TExportEntry; out SyscallEntry: TSyscall): Boolean
    var
      Body: PSyscallBody64;
    begin
      // Range checks
      if Entry.VirtualAddress + SizeOf(TSyscallBody64) > DllSize then
        Exit(False);

      Body := Pointer(UIntPtr(DllBase) + Entry.VirtualAddress);

      Result := (Body.Head = MOV_R10_RCX_MOV_EAX) and
         ((Body.SyscallNoUserShared = SYSCALL) or
         (Body.SysCallUserShared = SYSCALL));

      if Result then
      begin
        SyscallEntry.ExportEntry := Entry;
        SyscallEntry.SyscallNumber := Body.SyscallNumber;
      end;
    end
  );
end;

end.
