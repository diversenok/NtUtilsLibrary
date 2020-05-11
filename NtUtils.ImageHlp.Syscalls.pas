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
function RtlxEnumerateSycallsDll(DllBase: Pointer; DllSize: Cardinal;
  MappedAsImage: Boolean; out SysCalls: TArray<TSyscall>): TNtxStatus;

implementation

uses
  Winapi.WinNt, DelphiUtils.Arrays;

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

function RtlxEnumerateSycallsDll(DllBase: Pointer; DllSize: Cardinal;
  MappedAsImage: Boolean; out SysCalls: TArray<TSyscall>): TNtxStatus;
var
  ExportEntries: TArray<TExportEntry>;
  NtHeaders: PImageNtHeaders;
begin
  // Find all exported functions
  Result := RtlxEnumerateExportImage(DllBase, DllSize, MappedAsImage,
    ExportEntries);

  if not Result.IsSuccess then
    Exit;

  // We might need to use the headers for images that are mapped as files
  if not MappedAsImage then
  begin
    Result := RtlxGetNtHeaderImage(DllBase, DllSize, NtHeaders);

    if not Result.IsSuccess then
      Exit;
  end
  else
    NtHeaders := nil;

  // Find all entries that match a function with a syscall and determine its
  // SyscallNumber

  SysCalls := TArray.Convert<TExportEntry, TSyscall>(ExportEntries,
    function (const Entry: TExportEntry; out SyscallEntry: TSyscall): Boolean
    var
      Body: PSyscallBody64;
      Status: TNtxStatus;
    begin
      // Locate the function's code
      Body := RtlxExpandVirtualAddress(DllBase, DllSize, NtHeaders,
        MappedAsImage, Entry.VirtualAddress, SizeOf(TSyscallBody64), Status);

      if not Status.IsSuccess then
        Exit(False);

      // Check if it matches the template of a function that issues a syscall
      Result := (Body.Head = MOV_R10_RCX_MOV_EAX) and
         ((Body.SyscallNoUserShared = SYSCALL) or
         (Body.SysCallUserShared = SYSCALL));

      // Save it
      if Result then
      begin
        SyscallEntry.ExportEntry := Entry;
        SyscallEntry.SyscallNumber := Body.SyscallNumber;
      end;
    end
  );
end;

end.
