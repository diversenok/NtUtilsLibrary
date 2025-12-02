unit NtUtils.NtUser;

{
  This module provides functions for interacting with graphical subsystem
  (win32k.sys) though low-level system call interface exposed by win32u.dll
  starting from Windows 10 RS1.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntpsapi, Ntapi.ntuser, Ntapi.WinUser, NtUtils;

type
  IHook = IHandle;

{ Window Stations }

// Get a per-session directory where window stations reside
function RtlxWindowStationDirectory(
  SessionId: TSessionId = TSessionId(-1)
): String;

// Open a window station based on a name from the object manager's namespace
function NtxOpenWindowStation(
  out hxWinSta: IHandle;
  DesiredAccess: TWinstaAccessMask;
  const FullName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Enumerate window stations of the current session
function NtxEnumerateWindowStations(
  out Names: TArray<String>
): TNtxStatus;

{ Desktops }

// Enumerate desktops of a window station
function NtxEnumerateDesktops(
  [Access(WINSTA_ENUMDESKTOPS)] const hxWinSta: IHandle;
  out Names: TArray<String>
): TNtxStatus;

// Open a desktop based on a name from the object manager's namespace
function NtxOpenDesktop(
  out hxDesktop: IHandle;
  DesiredAccess: TDesktopAccessMask;
  const FullName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Opens the desktop that receives user input
function NtxOpenInputDesktop(
  out hxDesktop: IHandle;
  DesiredAccess: TDesktopAccessMask;
  Flags: TDesktopOpenOptions = 0
): TNtxStatus;

// Opens the desktop used by a thread
function NtxOpenThreadDesktop(
  out hxDesktop: IHandle;
  ThreadId: TThreadId32;
  DesiredAccess: TDesktopAccessMask;
  Inherit: Boolean = False;
  Protect: Boolean = False
): TNtxStatus;

// Set the desktop of the current thread
function NtxSetThreadDesktop(
  const hxDesktop: IHandle
): TNtxStatus;

{ Windows }

// Enumerate windows by desktop/thread/parent
function NtxEnumerateWindows(
  out Windows: TArray<THwnd>;
  [opt, Access(DESKTOP_READOBJECTS)] const hxDesktop: IHandle = nil;
  [opt] ThreadId: TThreadId32 = 0;
  [opt] ParentWindow: THwnd = 0;
  SkipImmersive: Boolean = False
): TNtxStatus;

// Open a process by a HWND
function NtxOpenProcessByWindow(
  out hxProcess: IHandle;
  hWnd: THwnd;
  DesiredAccess: TProcessAccessMask
): TNtxStatus;

type
  NtxWindow = class abstract
    // Query fixed-size window information
    class function Query<T>(
      hWnd: THwnd;
      InfoClass: TWindowInfoClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

{ Threads }

// Query information about a GUI thread
function NtxGetGuiInfoThread(
  ThreadId: TThreadId32;
  out Info: TGuiThreadInfo
): TNtxStatus;

// Determine if a thread has performed any GUI operations
function NtxIsGuiThread(
  ThreadId: TThreadId32
): Boolean;

{ Misc }

// Install a window hook
function NtxSetWindowsHookEx(
  out hxHook: IHook;
  FilterType: THookId;
  FilterProc: Pointer;
  const LibraryName: String;
  ModuleBase: Pointer;
  ThreadId: TThreadId32 = 0;
  Flags: THookFlags = 0
): TNtxStatus;

// Lock the workstation and switch to the logon screen
function NtxLockWorkstation(
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.WinError, Ntapi.ntpebteb, Ntapi.ntrtl,
  NtUtils.Objects, NtUtils.SysUtils, DelphiUtils.AutoObjects,
  DelphiUtils.Arrays, NtUtils.Ldr;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Common }

function NtuxEnumerateNames(
  hWinSta: THandle;
  out Names: TArray<String>
): TNtxStatus;
var
  Buffer: IMemory<PNameList>;
  Required: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserBuildNameList);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserBuildNameList';

  if hWinSta <> 0 then
    Result.LastCall.Expects<TWinstaAccessMask>(WINSTA_ENUMDESKTOPS);

  IMemory(Buffer) := Auto.AllocateDynamic(256);
  repeat
    // Query the list of names
    Result.Status := NtUserBuildNameList(hWinSta, Buffer.Size, Buffer.Data,
      Required);
  until not NtxExpandBufferEx(Result, IMemory(Buffer), Required, nil);

  if not Result.IsSuccess then
    Exit;

  // Names are separated by null character, extract them
  Names := RtlxParseWideMultiSz(PWideMultiSz(@Buffer.Data.Names),
    Buffer.Data.cb);

  // Truncate if necessary
  if Cardinal(Length(Names)) > Buffer.Data.Count then
    SetLength(Names, Buffer.Data.Count);
end;

{ Window Stations }

function RtlxWindowStationDirectory;
begin
  Result := '\Windows\WindowStations';

  if SessionId = TSessionId(-1) then
    SessionId := RtlGetCurrentPeb.SessionID;

  if SessionId <> 0 then
    Result := '\Sessions\' + RtlxIntToDec(SessionId) + Result;
end;

function NtxEnumerateWindowStations;
begin
  Result := NtuxEnumerateNames(0, Names);
end;

function NtxOpenWindowStation;
var
  ObjAttr: PObjectAttributes;
  hWinSta: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserOpenWindowStation);

  if not Result.IsSuccess then
    Exit;

  Result := AttributeBuilder(ObjectAttributes).UseName(FullName).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserOpenWindowStation';
  Result.LastCall.OpensForAccess(DesiredAccess);
  hWinSta := NtUserOpenWindowStation(ObjAttr^, DesiredAccess);
  Result.Win32Result := hWinSta <> 0;

  if Result.IsSuccess then
    hxWinSta := Auto.CaptureHandle(hWinSta);
end;

{ Desktops }

function NtxEnumerateDesktops;
begin
  Result := NtuxEnumerateNames(HandleOrDefault(hxWinSta), Names);
end;

function NtxOpenDesktop;
var
  ObjAttr: PObjectAttributes;
  hDesktop: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserOpenDesktop);

  if not Result.IsSuccess then
    Exit;

  Result := AttributeBuilder(ObjectAttributes).UseName(FullName).Build(ObjAttr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserOpenDesktop';
  Result.LastCall.OpensForAccess(DesiredAccess);
  hDesktop := NtUserOpenDesktop(ObjAttr^, 0, DesiredAccess);
  Result.Win32Result := hDesktop <> 0;

  if Result.IsSuccess then
    hxDesktop := Auto.CaptureHandle(hDesktop);
end;

function NtxOpenInputDesktop;
var
  hDesktop: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserOpenInputDesktop);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserOpenInputDesktop';
  Result.LastCall.OpensForAccess(DesiredAccess);
  hDesktop := NtUserOpenInputDesktop(Flags, False, DesiredAccess);
  Result.Win32Result := hDesktop <> 0;

  if Result.IsSuccess then
    hxDesktop := Auto.CaptureHandle(hDesktop);
end;

function NtxOpenThreadDesktop;
const
  FLAGAS: array [Boolean] of TThreadDesktopFlags = (0, TDF_PROTECT_HANDLE);
var
  hDesktop: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserOpenThreadDesktop);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserOpenThreadDesktop';
  Result.LastCall.OpensForAccess(DesiredAccess);
  hDesktop := NtUserOpenThreadDesktop(ThreadId, FLAGAS[Protect], Inherit,
    DesiredAccess);
  Result.Win32Result := hDesktop <> 0;

  if Result.IsSuccess then
    hxDesktop := Auto.CaptureHandle(hDesktop);
end;

function NtxSetThreadDesktop;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserSetThreadDesktop);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserSetThreadDesktop';
  Result.Win32Result := NtUserSetThreadDesktop(HandleOrDefault(hxDesktop));
end;

{ Windows }

function NtxEnumerateWindows;
var
  Count: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserBuildHwndList);

  if not Result.IsSuccess then
    Exit;

  Windows := nil;
  Result.Location := 'NtUserBuildHwndList';
  Result.LastCall.Expects<TDesktopAccessMask>(DESKTOP_READOBJECTS);

  Count := 64;
  repeat
    if Count <= Cardinal(Length(Windows)) then
      Break;

    SetLength(Windows, Count);

    // Acquire the list of HWNDs
    Result.Status := NtUserBuildHwndList(HandleOrDefault(hxDesktop),
      ParentWindow, ParentWindow <> 0, SkipImmersive, ThreadId, Count, Windows,
      Count);
  until Result.Status <> STATUS_BUFFER_TOO_SMALL;

  if not Result.IsSuccess then
    Windows := nil
  else
    // Truncate it if necessary
    if Count < Cardinal(Length(Windows)) then
      SetLength(Windows, Count);

  // For some reason, we get HWND = 1 at the end of the list, remove it.
  if (Length(Windows) > 0) and (Windows[High(Windows)] = 1) then
    Delete(Windows, High(Windows), 1);
end;

function NtxOpenProcessByWindow;
var
  hProcess: THandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserGetWindowProcessHandle);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserGetWindowProcessHandle';
  Result.LastCall.OpensForAccess(DesiredAccess);
  hProcess := NtUserGetWindowProcessHandle(hWnd, DesiredAccess);
  Result.Win32Result := hProcess <> 0;

  if Result.IsSuccess then
    hxProcess := Auto.CaptureHandle(hProcess);
end;

class function NtxWindow.Query<T>;
var
  BufferData: NativeUInt absolute Buffer;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserQueryWindow);

  if not Result.IsSuccess then
    Exit;

  if SizeOf(T) = SizeOf(NativeUInt) then
  begin
    Result.Location := 'NtUserQueryWindow';
    Result.LastCall.UsesInfoClass(InfoClass, icQuery);

    RtlSetLastWin32Error(ERROR_SUCCESS);
    BufferData := NtUserQueryWindow(hWnd, InfoClass);
    Result.Win32Result := (RtlGetLastWin32Error = ERROR_SUCCESS);
  end
  else
  begin
    Result.Location := 'NtxWindow.Query<T>';
    Result.Status := STATUS_INFO_LENGTH_MISMATCH;
    Exit;
  end;
end;

{ Threads }

function NtxGetGuiInfoThread;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserGetGUIThreadInfo);

  if not Result.IsSuccess then
    Exit;

  Info.Size := SizeOf(TGuiThreadInfo);
  Result.Location := 'NtUserGetGUIThreadInfo';
  Result.Win32Result := NtUserGetGUIThreadInfo(ThreadId, Info);
end;

function NtxIsGuiThread;
var
  Info: TGuiThreadInfo;
begin
  Result := NtxGetGuiInfoThread(ThreadId, Info).IsSuccess;
end;

{ Misc }

type
  TNtxAutoWindowHook = class (TCustomAutoHandle)
    destructor Destroy; override;
  end;

destructor TNtxAutoWindowHook.Destroy;
begin
  if (FHandle <> 0) and LdrxCheckDelayedImport(
    delayed_NtUserUnhookWindowsHookEx).IsSuccess then
    NtUserUnhookWindowsHookEx(FHandle);
end;

function NtxSetWindowsHookEx;
var
  LibStr: TNtUnicodeString;
  hHook: THHook;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserSetWindowsHookEx);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(LibStr, LibraryName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserSetWindowsHookEx';
  Result.LastCall.UsesInfoClass(FilterType, icPerform);
  hHook := NtUserSetWindowsHookEx(ModuleBase, LibStr, ThreadId, FilterType,
    FilterProc, Flags);
  Result.Win32Result := hHook <> 0;

  if Result.IsSuccess then
    hxHook := TNtxAutoWindowHook.Capture(hHook);
end;

function NtxLockWorkstation;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserLockWorkStation);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserLockWorkStation';
  Result.Win32Result := NtUserLockWorkStation;
end;

end.
