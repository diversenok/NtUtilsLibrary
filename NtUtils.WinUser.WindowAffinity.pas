unit NtUtils.WinUser.WindowAffinity;

interface

uses
  Winapi.WinUser, NtUtils, NtUtils.Shellcode;

const
  WDA_NONE = Winapi.WinUser.WDA_NONE;
  WDA_MONITOR = Winapi.WinUser.WDA_MONITOR;
  WDA_EXCLUDEFROMCAPTURE = Winapi.WinUser.WDA_EXCLUDEFROMCAPTURE;

// Determine if a window is visible for screen capturing
function UsrxGetWindowAffinity(Wnd: HWND; out Affinity: Cardinal): TNtxStatus;

// Change whether a window is visible for screen capturing
function UsrxSetWindowAffinity(Wnd: HWND; Affinity: Cardinal; Timeout: Int64 =
  DEFAULT_REMOTE_TIMEOUT): TNtxStatus;

implementation

uses
  Winapi.WinNt, Ntapi.ntpebteb, Ntapi.ntdef, Ntapi.ntwow64,
  NtUtils.Processes, NtUtils.Processes.Query, NtUtils.Threads,
  DelphiUtils.AutoObject;

type
  TSetWindowDistplayAffinity = function (hWnd: UIntPtr; dwAffinity: Cardinal):
    LongBool; stdcall;
  TRtlGetLastWin32Error = function: TWin32Error; stdcall;

  // Injected thread requires some context
  TPalyloadContext = record
    SetWindowDisplayAffinity: TSetWindowDistplayAffinity;
    RtlGetLastWin32Error: TRtlGetLastWin32Error;
    Window: HWND;
    Affinity: Cardinal;
  end;
  PDisplayAffinityContext = ^TPalyloadContext;

{$IFDEF Win64}
  TDisplayAffinityContext32 = record
    SetWindowDisplayAffinity: WoW64Pointer;
    RtlGetLastWin32Error: WoW64Pointer;
    Window: WoW64Pointer;
    Affinity: Cardinal;
  end;
  PDisplayAffinityContext32 = ^TDisplayAffinityContext32;
{$ENDIF}

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
  // 32-bit assembly. Be consistent with the function definition above
  PayloadAssembly32: array [0 .. 69] of Byte = (
    $55, $8B, $EC, $83, $C4, $F8, $8B, $45, $08, $8B, $40, $0C, $50, $8B, $45,
    $08, $8B, $40, $08, $50, $8B, $45, $08, $FF, $10, $85, $C0, $74, $07, $33,
    $C0, $89, $45, $FC, $EB, $19, $8B, $45, $08, $FF, $50, $04, $89, $45, $F8,
    $8B, $45, $F8, $25, $FF, $FF, $00, $00, $0D, $00, $00, $07, $C0, $89, $45,
    $FC, $8B, $45, $FC, $59, $59, $5D, $C2, $04, $00
  );

{$IFDEF Win64}
  // 64-bit assembly. Be consistent with the function definition above
  PayloadAssembly64: array [0 .. 82] of Byte = (
    $55, $48, $83, $EC, $30, $48, $8B, $EC, $48, $89, $4D, $40, $48, $8B, $45,
    $40, $48, $8B, $48, $10, $48, $8B, $45, $40, $8B, $50, $18, $48, $8B, $45,
    $40, $FF, $10, $85, $C0, $74, $09, $C7, $45, $2C, $00, $00, $00, $00, $EB,
    $1C, $48, $8B, $45, $40, $FF, $50, $08, $89, $45, $28, $8B, $45, $28, $81,
    $E0, $FF, $FF, $00, $00, $81, $C8, $00, $00, $07, $C0, $89, $45, $2C, $8B,
    $45, $2C, $48, $8D, $65, $30, $5D, $C3
  );
{$ENDIF}

{$IFDEF Win64}
procedure TranslateContextToWoW64(var xMemory:
  IMemory<PDisplayAffinityContext>);
var
  Context32: IMemory<PDisplayAffinityContext32>;
begin
  IMemory(Context32) := TAutoMemory.Allocate(SizeOf(TDisplayAffinityContext32));

  // Copy and cast fields
  Context32.Data.SetWindowDisplayAffinity := Wow64Pointer(
    @xMemory.Data.SetWindowDisplayAffinity);
  Context32.Data.RtlGetLastWin32Error := Wow64Pointer(
    @xMemory.Data.RtlGetLastWin32Error);
  Context32.Data.Window := Wow64Pointer(xMemory.Data.Window);
  Context32.Data.Affinity := xMemory.Data.Affinity;

  // Swap the reference
  IMemory(xMemory) := IMemory(Context32);
end;
{$ENDIF}

function UsrxGetWindowAffinity(Wnd: HWND; out Affinity: Cardinal): TNtxStatus;
begin
  Result.Location := 'GetWindowDisplayAffinity';
  Result.Win32Result := GetWindowDisplayAffinity(Wnd, Affinity);
end;

function UsrxSetWindowAffinity(Wnd: HWND; Affinity: Cardinal; Timeout: Int64): TNtxStatus;
var
  TID: TThreadId32;
  PID: TProcessId32;
  hxProcess, hxThread: IHandle;
  TargetIsWoW64: Boolean;
  Addresses: TArray<Pointer>;
  Context: IMemory<PDisplayAffinityContext>;
  Code: TMemory;
  RemoteContext, RemoteCode: IMemory;
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

  // Start preparing the context for the thread
  IMemory(Context) := TAutoMemory.Allocate(SizeOf(TPalyloadContext));
  Context.Data.Window := Wnd;
  Context.Data.Affinity := Affinity;

  // Locate user32 import
  Result := RtlxFindKnownDllExports(user32, TargetIsWoW64,
    ['SetWindowDisplayAffinity'], Addresses);

  if not Result.IsSuccess then
    Exit;

  Context.Data.SetWindowDisplayAffinity := Addresses[0];

  // Locate ntdll import
  Result := RtlxFindKnownDllExports(ntdll, TargetIsWoW64,
    ['RtlGetLastWin32Error'], Addresses);

  if not Result.IsSuccess then
    Exit;

  Context.Data.RtlGetLastWin32Error := Addresses[0];

{$IFDEF Win64}
  // Handle targets that run under WoW64
  if TargetIsWoW64 then
    TranslateContextToWoW64(Context);
{$ENDIF}

  // Reference the correct assembly code
{$IFDEF Win64}
  if not TargetIsWoW64 then
    Code := TMemory.Reference(PayloadAssembly64)
  else
{$ENDIF}
    Code := TMemory.Reference(PayloadAssembly32);

  // Allocate and copy everything to the target
  Result := RtlxAllocWriteDataCodeProcess(hxProcess, Context.Region,
    RemoteContext, Code, RemoteCode, TargetIsWoW64);

  if not Result.IsSuccess then
    Exit;

  // Inject the thread
  Result := NtxCreateThread(hxThread, hxProcess.Handle, RemoteCode.Data,
    RemoteContext.Data);

  if not Result.IsSuccess then
    Exit;

  // Sychronize with it. Prolong remote buffer lifetime on timeout.
  Result := RtlxSyncThread(hxThread.Handle, 'Remote::SetWindowDisplayAffinity',
    Timeout, [RemoteCode, RemoteContext]);
end;

end.
