unit NtUtils.WinUser.WindowAffinity;

{
  The module allows managing window affinity (i.e., visitibility for
  screen capture) for windows that belong to other processes.
}

interface

uses
  Winapi.WinUser, NtUtils, NtUtils.Shellcode;

const
  WDA_NONE = Winapi.WinUser.WDA_NONE;
  WDA_MONITOR = Winapi.WinUser.WDA_MONITOR;
  WDA_EXCLUDEFROMCAPTURE = Winapi.WinUser.WDA_EXCLUDEFROMCAPTURE;

// Determine if a window is visible for screen capturing
function UsrxGetWindowAffinity(
  Wnd: HWND;
  out Affinity: Cardinal
): TNtxStatus;

// Change whether a window is visible for screen capturing
function UsrxSetWindowAffinity(
  Wnd: HWND;
  Affinity: Cardinal;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntpebteb, Ntapi.ntdef, NtUtils.Processes.Info,
  NtUtils.Processes, DelphiUtils.AutoObjects;

type
  // Injected thread requires some context
  TPalyloadContext = record
    SetWindowDisplayAffinity: function (
      hWnd: UIntPtr;
      Affinity: Cardinal
    ): LongBool; stdcall;
    {$IFDEF Win32}WoW64Padding1: Cardinal;{$ENDIF}

    RtlGetLastWin32Error: function: TWin32Error; stdcall;
    {$IFDEF Win32}WoW64Padding2: Cardinal;{$ENDIF}

    Window: HWND;
    {$IFDEF Win32}WoW64Padding3: Cardinal;{$ENDIF}

    Affinity: Cardinal;
    Reserved: Cardinal;
  end;
  PDisplayAffinityContext = ^TPalyloadContext;

// This is the function we are going to inject as a thread. Be consistent with
// the raw assembly listing below.
function AffinitySetter(Context: PDisplayAffinityContext): NTSTATUS; stdcall;
begin
  if Context.SetWindowDisplayAffinity(Context.Window, Context.Affinity) then
    Result := STATUS_SUCCESS
  else
    Result := NTSTATUS_FROM_WIN32(Context.RtlGetLastWin32Error);
end;

var
  {$IFDEF Win64}
  // 64-bit assembly. Be consistent with the function definition above
  PayloadAssembly64: array [0..47] of Byte = (
    $53, $48, $83, $EC, $20, $48, $89, $CB, $48, $8B, $4B, $10, $8B, $53, $18,
    $FF, $13, $85, $C0, $74, $04, $33, $C0, $EB, $0F, $FF, $53, $08, $81, $E0,
    $FF, $FF, $00, $00, $81, $C8, $00, $00, $07, $C0, $48, $83, $C4, $20, $5B,
    $C3, $CC, $CC
  );
  {$ENDIF}

  // 32-bit assembly. Be consistent with the function definition above
  PayloadAssembly32: array [0..47] of Byte = (
    $55, $8B, $EC, $53, $8B, $5D, $08, $8B, $43, $18, $50, $8B, $43, $10, $50,
    $FF, $13, $85, $C0, $74, $04, $33, $C0, $EB, $0D, $FF, $53, $08, $25, $FF,
    $FF, $00, $00, $0D, $00, $00, $07, $C0, $5B, $5D, $C2, $04, $00, $CC, $CC,
    $CC, $CC, $CC
  );

function UsrxGetWindowAffinity;
begin
  Result.Location := 'GetWindowDisplayAffinity';
  Result.Win32Result := GetWindowDisplayAffinity(Wnd, Affinity);
end;

function UsrxSetWindowAffinity;
var
  TID: TThreadId32;
  PID: TProcessId32;
  hxProcess: IHandle;
  TargetIsWoW64: Boolean;
  LocalMapping: IMemory<PDisplayAffinityContext>;
  RemoteMapping: IMemory;
  CodeRef: TMemory;
begin
  // Determine the creator of the window
  Result.Location := 'GetWindowThreadProcessId';
  TID := GetWindowThreadProcessId(Wnd, PID);
  Result.Win32Result := TID <> 0;

  if not Result.IsSuccess then
    Exit;

  if PID = NtCurrentTeb.ClientID.UniqueProcess then
  begin
    // The thread belongs to our process, we can access it directly
    Result.Location := 'SetWindowDisplayAffinity';
    Result.Win32Result := SetWindowDisplayAffinity(Wnd, Affinity);
    Exit;
  end;

  // Open the process for code injection
  Result := NtxOpenProcess(hxProcess, PID, PROCESS_REMOTE_EXECUTE);

  if not Result.IsSuccess then
    Exit;

  // Prevent WoW64 -> Native access
  Result := RtlxAssertWoW64Compatible(hxProcess.Handle, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

{$IFDEF Win64}
  if not TargetIsWoW64 then
    CodeRef := TMemory.Reference(PayloadAssembly64)
  else
{$ENDIF}
    CodeRef := TMemory.Reference(PayloadAssembly32);

  // Map a shared memory region with the target
  Result := RtlxMapSharedMemory(hxProcess, SizeOf(TPalyloadContext) +
    CodeRef.Size, IMemory(LocalMapping), RemoteMapping, [mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  LocalMapping.Data.Window := Wnd;
  LocalMapping.Data.Affinity := Affinity;
  Move(CodeRef.Address^, LocalMapping.Offset(SizeOf(TPalyloadContext))^,
    CodeRef.Size);

  // Locate user32 import
  Result := RtlxFindKnownDllExport(user32, TargetIsWoW64,
    'SetWindowDisplayAffinity', @LocalMapping.Data.SetWindowDisplayAffinity);

  if not Result.IsSuccess then
    Exit;

  // Locate ntdll import
  Result := RtlxFindKnownDllExport(ntdll, TargetIsWoW64,
    'RtlGetLastWin32Error', @LocalMapping.Data.RtlGetLastWin32Error);

  if not Result.IsSuccess then
    Exit;

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    hxProcess.Handle,
    'Remote::SetWindowDisplayAffinity',
    RemoteMapping.Offset(SizeOf(TPalyloadContext)),
    CodeRef.Size,
    RemoteMapping.Data,
    0,
    Timeout,
    [RemoteMapping]
  );
end;

end.
