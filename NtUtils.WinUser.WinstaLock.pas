unit NtUtils.WinUser.WinstaLock;

{
  This module allows locking and unlocking window stations.
}

interface

uses
  Ntapi.ntseapi, NtUtils, NtUtils.Shellcode;

// Lock/unlock the current session's window station
[RequiredPrivilege(SE_DEBUG_PRIVILEGE, rpForBypassingChecks)]
function UsrxLockWindowStation(
  Lock: Boolean;
  const Timeout: Int64 = DEFAULT_REMOTE_TIMEOUT
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntldr, Ntapi.WinUser,
  NtUtils.Ldr, NtUtils.Processes.Snapshots, NtUtils.Processes.Info;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

// User32.dll has a pair of functions called LockWindowStation and
// UnlockWindowStation. Although any application can call them, only calls
// issued by a registered instance of winlogon.exe will succeed.
// So, we inject a thread to winlogon to execute this call in its context.

type
  TLockerContext = record
    GetProcessWindowStation: function: THandle; stdcall;
    LockWindowStation: function (hWinStation: THandle): LongBool; stdcall;
    RtlGetLastWin32Error: function: TWin32Error; stdcall;
  end;
  PLockerContext = ^TLockerContext;

// We are going to execute the following function inside winlogon, so make sure
// to use only functions and variables referenced through the Data parameter.
// Note: be consistent with the raw assembly below (the one we actually use).
function UsrxLockerPayload(Data: PLockerContext): NTSTATUS; stdcall;
begin
  if Data.LockWindowStation(Data.GetProcessWindowStation) then
    Result := STATUS_SUCCESS
  else
    Result := NTSTATUS_FROM_WIN32(Data.RtlGetLastWin32Error);
end;

const
  // Be consistent with function code above
  {$IFDEF WIN64}
  UsrxLockerAsm: array [0..47] of Byte = (
    $53, $48, $83, $EC, $20, $48, $89, $CB, $FF, $13, $48, $89, $C1, $FF, $53,
    $08, $85, $C0, $74, $04, $33, $C0, $EB, $0F, $FF, $53, $10, $81, $E0, $FF,
    $FF, $00, $00, $81, $C8, $00, $00, $07, $C0, $48, $83, $C4, $20, $5B, $C3,
    $CC, $CC, $CC
  );
  {$ENDIF}
  {$IFDEF WIN32}
  UsrxLockerAsm: array [0..39] of Byte = (
    $55, $8B, $EC, $53, $8B, $5D, $08, $FF, $13, $50, $FF, $53, $04, $85, $C0,
    $74, $04, $33, $C0, $EB, $0D, $FF, $53, $08, $25, $FF, $FF, $00, $00, $0D,
    $00, $00, $07, $C0, $5B, $5D, $C2, $04, $00, $CC
  );
  {$ENDIF}

function GetLockerFunctionName(Lock: Boolean): String;
begin
  if Lock then
    Result := 'LockWindowStation'
  else
    Result := 'UnlockWindowStation';
end;

function UsrxLockerPrepare(
  var Data: TLockerContext;
  Lock: Boolean
): TNtxStatus;
var
  hUser32: PDllBase;
begin
  // Winlogon always loads user32.dll, so we don't need to check it
  Result := LdrxGetDllHandle(user32, hUser32);

  if not Result.IsSuccess then
    Exit;

  Result := LdrxGetProcedureAddress(hUser32, 'GetProcessWindowStation',
    Pointer(@Data.GetProcessWindowStation));

  if not Result.IsSuccess then
    Exit;

  Result := LdrxGetProcedureAddress(hUser32,
    AnsiString(GetLockerFunctionName(Lock)), Pointer(@Data.LockWindowStation));

  if not Result.IsSuccess then
    Exit;

  Result := LdrxCheckDelayedModule(delayed_ntdll);

  if not Result.IsSuccess then
    Exit;

  Result := LdrxGetProcedureAddress(delayed_ntdll.DllAddress,
    'RtlGetLastWin32Error', Pointer(@Data.RtlGetLastWin32Error));
end;

function UsrxLockWindowStation;
var
  hxProcess: IHandle;
  LocalMapping: IMemory;
  RemoteMapping: IMemory;
begin
{$IFDEF Win32}
  // Winlogon always has the same bitness as the OS. So should we.
  if RtlxAssertNotWoW64(Result) then
    Exit;
{$ENDIF}

  // Find Winlogon and open it for code injection
  Result := NtxOpenProcessByName(hxProcess, 'winlogon.exe',
    PROCESS_REMOTE_EXECUTE, [pnCurrentSessionOnly]);

  if not Result.IsSuccess then
    Exit;

  // Map shared memory region
  Result := RtlxMapSharedMemory(hxProcess, SizeOf(TLockerContext) +
    SizeOf(UsrxLockerAsm), LocalMapping, RemoteMapping, [mmAllowExecute]);

  if not Result.IsSuccess then
    Exit;

  // Prepare the thread parameter
  Result := UsrxLockerPrepare(PLockerContext(LocalMapping.Data)^, Lock);

  if not Result.IsSuccess then
    Exit;

  Move(UsrxLockerAsm, LocalMapping.Offset(SizeOf(TLockerContext))^,
    SizeOf(UsrxLockerAsm));

  // Create a thread to execute the code and sync with it
  Result := RtlxRemoteExecute(
    hxProcess,
    'Remote::' + GetLockerFunctionName(Lock),
    RemoteMapping.Offset(SizeOf(TLockerContext)),
    SizeOf(UsrxLockerAsm),
    RemoteMapping.Data,
    0,
    Timeout,
    [RemoteMapping]
  );
end;

end.
