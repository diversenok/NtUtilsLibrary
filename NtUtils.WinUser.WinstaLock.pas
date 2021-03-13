unit NtUtils.WinUser.WinstaLock;

{
  This module allows locking and unlocking window stations.
}

interface

uses
  Winapi.WinNt, NtUtils, NtUtils.Shellcode;

// Lock/unlock current session's window station
function UsrxLockWindowStation(
  Lock: Boolean;
  Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntdef, Winapi.WinUser, Ntapi.ntldr, Ntapi.ntpebteb,
  NtUtils.Ldr, NtUtils.Processes.Snapshots, NtUtils.Processes, NtUtils.Objects,
  NtUtils.Threads, NtUtils.Processes.Memory, NtUtils.Processes.Query,
  DelphiUtils.Arrays;

// User32.dll has a pair of functions called LockWindowStation and
// UnlockWindowStation. Although any application can call them, only calls
// issued by a registered instance of winlogon.exe will succeed.
// So, we inject a thread to winlogon to execute this call in its context.

type
  TUsrxLockerParam = record
    GetProcessWindowStation: function: THandle; stdcall;
    LockWindowStation: function (hWinStation: THandle): LongBool; stdcall;
    RtlGetLastWin32Error: function: TWin32Error; stdcall;
  end;
  PWinStaPayload = ^TUsrxLockerParam;

// We are going to execute the following function inside winlogon, so make sure
// to use only functions and variables referenced through the Data parameter.
// Note: be consistent with the raw assembly below (the one we actually use).
function UsrxLockerPayload(Data: PWinStaPayload): NTSTATUS; stdcall;
begin
  if Data.LockWindowStation(Data.GetProcessWindowStation) then
    Result := STATUS_SUCCESS
  else
    Result := NTSTATUS_FROM_WIN32(Data.RtlGetLastWin32Error);
end;

const
  // Be consistent with function code above
  {$IFDEF WIN64}
  UsrxLockerAsm: array [0..77] of Byte = ($55, $48, $83, $EC, $30, $48, $8B,
    $EC, $48, $89, $4D, $40, $48, $8B, $45, $40, $FF, $10, $48, $89, $C1, $48,
    $8B, $45, $40, $FF, $50, $08, $85, $C0, $74, $09, $C7, $45, $2C, $00, $00,
    $00, $00, $EB, $1C, $48, $8B, $45, $40, $FF, $50, $10, $89, $45, $28, $8B,
    $45, $28, $81, $E0, $FF, $FF, $00, $00, $81, $C8, $00, $00, $07, $C0, $89,
    $45, $2C, $8B, $45, $2C, $48, $8D, $65, $30, $5D, $C3);
  {$ENDIF}
  {$IFDEF WIN32}
  UsrxLockerAsm: array [0..62] of Byte = ($55, $8B, $EC, $83, $C4, $F8, $8B,
    $45, $08, $FF, $10, $50, $8B, $45, $08, $FF, $50, $04, $85, $C0, $74, $07,
    $33, $C0, $89, $45, $FC, $EB, $19, $8B, $45, $08, $FF, $50, $08, $89, $45,
    $F8, $8B, $45, $F8, $25, $FF, $FF, $00, $00, $0D, $00, $00, $07, $C0, $89,
    $45, $FC, $8B, $45, $FC, $59, $59, $5D, $C2, $04, $00);
  {$ENDIF}

function GetLockerFunctionName(Lock: Boolean): String;
begin
  if Lock then
    Result := 'LockWindowStation'
  else
    Result := 'UnlockWindowStation';
end;

function UsrxLockerPrepare(
  var Data: TUsrxLockerParam;
  Lock: Boolean
): TNtxStatus;
var
  hUser32: HMODULE;
begin
  // Winlogon always loads user32.dll, so we don't need to check it
  Result := LdrxGetDllHandle(user32, hUser32);

  if not Result.IsSuccess then
    Exit;

  Data.GetProcessWindowStation := LdrxGetProcedureAddress(hUser32,
    'GetProcessWindowStation', Result);

  if not Result.IsSuccess then
    Exit;

  Data.LockWindowStation := LdrxGetProcedureAddress(hUser32,
    AnsiString(GetLockerFunctionName(Lock)), Result);

  if not Result.IsSuccess then
    Exit;

  Data.RtlGetLastWin32Error := LdrxGetProcedureAddress(hNtdll,
    'RtlGetLastWin32Error', Result);
end;

function UsrxLockWindowStation;
var
  Param: TUsrxLockerParam;
  Processes: TArray<TProcessEntry>;
  hxProcess, hxThread: IHandle;
  RemoteCode, RemoteContext: IMemory;
begin
{$IFDEF Win32}
  // Winlogon always has the same bitness as the OS. So should we.
  if RtlxAssertNotWoW64(Result) then
    Exit;
{$ENDIF}

  // Prepare the thread parameter
  Result := UsrxLockerPrepare(Param, Lock);

  if not Result.IsSuccess then
    Exit;

  // Snapshot processes to look for winlogon
  Result := NtxEnumerateProcesses(Processes);

  if not Result.IsSuccess then
    Exit;

  // We need to find the current session's winlogon
  TArray.FilterInline<TProcessEntry>(Processes,
    function (const Process: TProcessEntry): Boolean
    begin
      Result := (Process.Basic.SessionId = RtlGetCurrentPeb.SessionId) and
        (Process.ImageName = 'winlogon.exe');
    end
  );

  if Length(Processes) = 0 then
  begin
    Result.Location := '[Searching for winlogon.exe]';
    Result.Status := STATUS_NOT_FOUND;
    Exit;
  end;

  // Open it
  Result := NtxOpenProcess(hxProcess, Processes[0].Basic.ProcessId,
    PROCESS_REMOTE_EXECUTE);

  if not Result.IsSuccess then
    Exit;

  // Write the assembly and its context into winlogon's memory
  Result := RtlxAllocWriteDataCodeProcess(hxProcess, TMemory.Reference(Param),
    RemoteContext, TMemory.Reference(UsrxLockerAsm), RemoteCode);

  if not Result.IsSuccess then
    Exit;

  // Create a thread
  Result := RtlxCreateThread(hxThread, hxProcess.Handle, RemoteCode.Data,
    RemoteContext.Data);

  if not Result.IsSuccess then
    Exit;

  // Sychronize with it. Prolong remote memory lifetime on timeout.
  Result := RtlxSyncThread(hxThread.Handle, 'Winlogon::' +
    GetLockerFunctionName(Lock), Timeout, [RemoteCode, RemoteContext]);
end;

end.
