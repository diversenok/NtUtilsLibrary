unit NtUtils.NtUser;

{
  This module provides functions for interacting with graphical subsystem
  (win32k.sys) though low-level system call interface exposed by win32u.dll
  starting from Windows 10 RS1.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntpsapi, Ntapi.ntuser, Ntapi.WinUser, Ntapi.Versions,
  NtUtils;

type
  IHook = IHandle;

  TNtxAtomUsage = record
    UsageCount: Word;
    Flags: TAtomFlags;
  end;

  TNtxPropSet = TPropSet;

{ Window Stations }

// Get a per-session directory where window stations reside
[MinOSVersion(OsWin10RS1)]
function RtlxWindowStationDirectory(
  SessionId: TSessionId = TSessionId(-1)
): String;

// Open a window station based on a name from the object manager's namespace
[MinOSVersion(OsWin10RS1)]
function NtxOpenWindowStation(
  out hxWinSta: IHandle;
  DesiredAccess: TWinstaAccessMask;
  const FullName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Enumerate window stations of the current session
[MinOSVersion(OsWin10RS1)]
function NtxEnumerateWindowStations(
  out Names: TArray<String>
): TNtxStatus;

{ Desktops }

// Enumerate desktops of a window station
[MinOSVersion(OsWin10RS1)]
function NtxEnumerateDesktops(
  [Access(WINSTA_ENUMDESKTOPS)] const hxWinSta: IHandle;
  out Names: TArray<String>
): TNtxStatus;

// Open a desktop based on a name from the object manager's namespace
[MinOSVersion(OsWin10RS1)]
function NtxOpenDesktop(
  out hxDesktop: IHandle;
  DesiredAccess: TDesktopAccessMask;
  const FullName: String;
  [opt] const ObjectAttributes: IObjectAttributes = nil
): TNtxStatus;

// Opens the desktop that receives user input
[MinOSVersion(OsWin10RS1)]
function NtxOpenInputDesktop(
  out hxDesktop: IHandle;
  DesiredAccess: TDesktopAccessMask;
  Flags: TDesktopOpenOptions = 0
): TNtxStatus;

// Opens the desktop used by a thread
[MinOSVersion(OsWin10RS1)]
function NtxOpenThreadDesktop(
  out hxDesktop: IHandle;
  ThreadId: TThreadId32;
  DesiredAccess: TDesktopAccessMask;
  Inherit: Boolean = False;
  Protect: Boolean = False
): TNtxStatus;

// Set the desktop of the current thread
[MinOSVersion(OsWin10RS1)]
function NtxSetThreadDesktop(
  const hxDesktop: IHandle
): TNtxStatus;

{ Windows }

// Enumerate windows by desktop/thread/parent
[MinOSVersion(OsWin10RS1)]
function NtxEnumerateWindows(
  out Windows: TArray<THwnd>;
  [opt, Access(DESKTOP_READOBJECTS)] const hxDesktop: IHandle = nil;
  [opt] ThreadId: TThreadId32 = 0;
  [opt] ParentWindow: THwnd = 0;
  SkipImmersive: Boolean = False
): TNtxStatus;

// Open a process by a HWND
[MinOSVersion(OsWin10RS4)]
function NtxOpenProcessByWindow(
  out hxProcess: IHandle;
  hWnd: THwnd;
  DesiredAccess: TProcessAccessMask
): TNtxStatus;

type
  NtxWindow = class abstract
    // Query fixed-size window information
    [MinOSVersion(OsWin10RS1)]
    class function Query<T>(
      hWnd: THwnd;
      InfoClass: TWindowInfoClass;
      out Buffer: T
    ): TNtxStatus; static;
  end;

{ Threads }

// Query information about a GUI thread
[MinOSVersion(OsWin10RS1)]
function NtxGetGuiInfoThread(
  ThreadId: TThreadId32;
  out Info: TGuiThreadInfo
): TNtxStatus;

// Determine if a thread has performed any GUI operations
[MinOSVersion(OsWin10RS1)]
function NtxIsGuiThread(
  ThreadId: TThreadId32
): Boolean;

{ Messages }

// Send a window message with a timeout
[MinOSVersion(OsWin10RS1)]
function NtxSendMessage(
  hwnd: THwnd;
  Msg: Cardinal;
  wParam: NativeUInt;
  lParam: NativeInt;
  Flags: TSendMessageOptions = SMTO_ABORTIFHUNG;
  Timeout: Cardinal = 0;
  [out] Outcome: PNativeInt = nil
): TNtxStatus;

// Post a window message
[MinOSVersion(OsWin10RS1)]
function NtxPostMessage(
  hwnd: THwnd;
  Msg: Cardinal;
  wParam: NativeUInt;
  lParam: NativeInt
): TNtxStatus;

// Register a named message and get a shared identifier for it
// (a UserAtomTableHandle atom)
[MinOSVersion(OsWin10RS1)]
function NtxRegisterWindowMessage(
  const MessageName: String;
  out MessageAtom: Cardinal
): TNtxStatus;

// Determine a string that corresponds to a UserAtomTableHandle atom
[MinOSVersion(OsWin10RS1)]
function NtxUserGetAtomName(
  Atom: Word;
  out AtomName: String
): TNtxStatus;

{ WinSta atoms & window props }

// Determine a string that corresponds to a WinSta->GlobalAtomTable atom
function NtxQueryNameAtom(
  Atom: Word;
  out AtomName: String
): TNtxStatus;

// Query the usage information for a WinSta->GlobalAtomTable atom
function NtxQueryUsageAtom(
  Atom: Word;
  out Usage: TNtxAtomUsage
): TNtxStatus;

// Enumerate valid atoms in WinSta->GlobalAtomTable
function NtxEnumerateAtoms(
  out Atoms: TArray<Word>
): TNtxStatus;

// Find a WinSta->GlobalAtomTable atom by a string
function NtxFindAtom(
  const AtomName: String;
  out Atom: Word
): TNtxStatus;

// Add an atom to WinSta->GlobalAtomTable
function NtxAddAtom(
  const AtomName: String;
  out Atom: Word
): TNtxStatus;

// Delete an atom from WinSta->GlobalAtomTable
function NtxDeleteAtom(
  Atom: Word
): TNtxStatus;

// Enumerate properties of a window
[MinOSVersion(OsWin10RS1)]
function NtxEnumerateProps(
  hwnd: THwnd;
  out Props: TArray<TNtxPropSet>
): TNtxStatus;

// Query a property of a window
[MinOSVersion(OsWin10RS1)]
function NtxGetProp(
  hwnd: THwnd;
  Atom: Word;
  out Value: NativeUInt
): TNtxStatus;

// Set a property of a window
[MinOSVersion(OsWin10RS1)]
function NtxSetProp(
  hwnd: THwnd;
  Atom: Word;
  Value: NativeUInt
): TNtxStatus;

// Remove a property of a window
[MinOSVersion(OsWin10RS1)]
function NtxRemoveProp(
  hwnd: THwnd;
  Atom: Word;
  [out, opt] OldValue: PNativeUInt = nil
): TNtxStatus;

{ Clipboard }

// Open a clipboard for access
[MinOSVersion(OsWin10RS1)]
function NtxOpenClipboard(
  out ClipboardRelease: IDiscardableResource;
  [opt] hwnd: THwnd = 0;
  [out, opt] EmptyClient: PLongBool = nil
): TNtxStatus;

// Capture the content of a clipboard buffer handle
[MinOSVersion(OsWin10RS1)]
function NtxCaptureMemHandle(
  hMem: TMemHandle;
  out Buffer: IMemory
): TNtxStatus;

// Get a clipboard buffer handle
[MinOSVersion(OsWin10RS1)]
function NtxGetClipboardDataHandle(
  Format: Cardinal;
  out Info: TGetClipbData;
  out hMem: TMemHandle
): TNtxStatus;

// Get clipboard content
[MinOSVersion(OsWin10RS1)]
function NtxGetClipboardData(
  Format: Cardinal;
  out Info: TGetClipbData;
  out Data: IMemory
): TNtxStatus;

{ Misc }

// Install a window hook
[MinOSVersion(OsWin10RS1)]
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
[MinOSVersion(OsWin10RS1)]
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

{ Legacy calls }

function NtxCallNoParam(
  Proc: TUserCallIndex;
  out Value: NativeUInt
): TNtxStatus;
begin
  // Our procedure index table does not support earlier versions
  if not RtlOsVersionAtLeast(OsWin1020H1) or not (Proc in SFI_NoParam) then
  begin
    Result.Location := 'NtxCallNoParam';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := LdrxCheckDelayedImport(delayed_NtUserCallNoParam);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserCallNoParam';
  Result.LastCall.UsesInfoClass(Proc, icExecute);

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Value := NtUserCallNoParam(Proc);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function NtxCallOneParam(
  Proc: TUserCallIndex;
  Param: NativeUInt;
  out Value: NativeUInt
): TNtxStatus;
begin
  // Our procedure index table does not support earlier versions
  if not RtlOsVersionAtLeast(OsWin1020H1) or not (Proc in SFI_OneParam) then
  begin
    Result.Location := 'NtxCallOneParam';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := LdrxCheckDelayedImport(delayed_NtUserCallOneParam);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserCallOneParam';
  Result.LastCall.UsesInfoClass(Proc, icExecute);

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Value := NtUserCallOneParam(Param, Proc);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function NtxCallHwnd(
  Proc: TUserCallIndex;
  Hwnd: THwnd;
  out Value: NativeUInt
): TNtxStatus;
begin
  // Our procedure index table does not support earlier versions
  if not RtlOsVersionAtLeast(OsWin1020H1) or not (Proc in SFI_Hwnd) then
  begin
    Result.Location := 'NtxCallHwnd';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := LdrxCheckDelayedImport(delayed_NtUserCallHwnd);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserCallHwnd';
  Result.LastCall.UsesInfoClass(Proc, icExecute);

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Value := NtUserCallHwnd(Hwnd, Proc);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function NtxCallHwndOpt(
  Proc: TUserCallIndex;
  Hwnd: THwnd;
  out Value: NativeUInt
): TNtxStatus;
begin
  // Our procedure index table does not support earlier versions
  if not RtlOsVersionAtLeast(OsWin1020H1) or not (Proc in SFI_HwndOpt) then
  begin
    Result.Location := 'NtxCallHwndOpt';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := LdrxCheckDelayedImport(delayed_NtUserCallHwndOpt);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserCallHwndOpt';
  Result.LastCall.UsesInfoClass(Proc, icExecute);

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Value := NtUserCallHwndOpt(Hwnd, Proc);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function NtxCallHwndParam(
  Proc: TUserCallIndex;
  Hwnd: THwnd;
  Param: NativeUInt;
  out Value: NativeUInt
): TNtxStatus;
begin
  // Our procedure index table does not support earlier versions
  if not RtlOsVersionAtLeast(OsWin1020H1) or not (Proc in SFI_HwndParam) then
  begin
    Result.Location := 'NtxCallHwndParam';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := LdrxCheckDelayedImport(delayed_NtUserCallHwndParam);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserCallHwndParam';
  Result.LastCall.UsesInfoClass(Proc, icExecute);

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Value := NtUserCallHwndParam(Hwnd, Param, Proc);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function NtxCallHwndLock(
  Proc: TUserCallIndex;
  Hwnd: THwnd;
  out Value: NativeUInt
): TNtxStatus;
begin
  // Our procedure index table does not support earlier versions
  if not RtlOsVersionAtLeast(OsWin1020H1) or not (Proc in SFI_HwndLock) then
  begin
    Result.Location := 'NtxCallHwndLock';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := LdrxCheckDelayedImport(delayed_NtUserCallHwndLock);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserCallHwndLock';
  Result.LastCall.UsesInfoClass(Proc, icExecute);

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Value := NtUserCallHwndLock(Hwnd, Proc);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function NtxCallHwndParamLock(
  Proc: TUserCallIndex;
  Hwnd: THwnd;
  Param: NativeUInt;
  out Value: NativeUInt
): TNtxStatus;
begin
  // Our procedure index table does not support earlier versions
  if not RtlOsVersionAtLeast(OsWin1020H1) or not (Proc in SFI_HwndParamLock) then
  begin
    Result.Location := 'NtxCallHwndParamLock';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := LdrxCheckDelayedImport(delayed_NtUserCallHwndParamLock);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserCallHwndParamLock';
  Result.LastCall.UsesInfoClass(Proc, icExecute);

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Value := NtUserCallHwndParamLock(Hwnd, Param, Proc);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function NtxCallTwoParam(
  Proc: TUserCallIndex;
  Param1: NativeUInt;
  Param2: NativeUInt;
  out Value: NativeUInt
): TNtxStatus;
begin
  // Our procedure index table does not support earlier versions
  if not RtlOsVersionAtLeast(OsWin1020H1) or not (Proc in SFI_TwoParam) then
  begin
    Result.Location := 'NtxCallTwoParam';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := LdrxCheckDelayedImport(delayed_NtUserCallTwoParam);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserCallTwoParam';
  Result.LastCall.UsesInfoClass(Proc, icExecute);

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Value := NtUserCallTwoParam(Param1, Param2, Proc);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

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

{ Messages }

function NtxSendMessage;
var
  xParam: TSndMsgTimeout;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserMessageCall);

  if not Result.IsSuccess then
    Exit;

  xParam.Flags := Flags;
  xParam.Timeout := Timeout;
  xParam.SMTOReturn := 0;
  xParam.SMTOResult := 0;

  Result.Location := 'NtUserMessageCall';
  Result.LastCall.UsesInfoClass<TMessageCallFunctionId>(FNID_SENDMESSAGEEX,
    icPerform);
  NtUserMessageCall(hwnd, Msg, wParam, lParam, NativeUInt(@xParam),
    FNID_SENDMESSAGEEX, False);
  Result.Win32Result := xParam.SMTOReturn <> 0;

  if Result.IsSuccess and Assigned(Outcome) then
    Outcome^ := xParam.SMTOResult
end;

function NtxPostMessage;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserPostMessage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserPostMessage';
  Result.Win32Result := NtUserPostMessage(hwnd,Msg, wParam, lParam);
end;

function NtxRegisterWindowMessage;
var
  MessageStr: TNtUnicodeString;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserRegisterWindowMessage);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(MessageStr, MessageName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserRegisterWindowMessage';
  MessageAtom := NtUserRegisterWindowMessage(MessageStr);
  Result.Win32Result := MessageAtom <> 0;
end;

function NtxUserGetAtomName;
const
  INITIAL_SIZE = 20 * SizeOf(WideChar);
var
  Buffer: IMemory;
  AtomNameStr: TNtUnicodeString;
  Returned: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserGetAtomName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserGetAtomName';
  Buffer := Auto.AllocateDynamic(INITIAL_SIZE);

  repeat
    AtomNameStr.Buffer := Buffer.Data;
    AtomNameStr.Length := Buffer.Size;
    AtomNameStr.MaximumLength := Buffer.Size;

    Returned := NtUserGetAtomName(Atom, AtomNameStr);
    Result.Win32Result := (Returned > 0) and
      (Returned < Word(AtomNameStr.Length div SizeOf(WideChar) - 1));

  until not NtxExpandBufferGuess(Result, Buffer, MAX_UNICODE_STRING *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  AtomNameStr.Length := Returned * SizeOf(WideChar);
  AtomName := AtomNameStr.ToString;
end;

{ WinSta atoms & window props }

function NtxQueryNameAtom;
const
  INITIAL_SIZE = SizeOf(TAtomBasicInformation) + 20 * SizeOf(WideChar);
var
  Buffer: IMemory<PAtomBasicInformation>;
begin
  Result.Location := 'NtQueryInformationAtom';
  Result.LastCall.UsesInfoClass(AtomBasicInformation, icQuery);

  IMemory(Buffer) := Auto.AllocateDynamic(INITIAL_SIZE);

  repeat
    Result.Status := NtQueryInformationAtom(Atom, AtomBasicInformation,
      Buffer.Data, Buffer.Size, nil);

    if Result.IsSuccess and (Buffer.Data.NameLength >=
      Buffer.Size - SizeOf(TAtomBasicInformation)) then
      Result.Status := STATUS_BUFFER_TOO_SMALL;

  until not NtxExpandBufferGuess(Result, IMemory(Buffer),
    SizeOf(TAtomBasicInformation) + MAX_WORD);

  if not Result.IsSuccess then
    Exit;

  SetString(AtomName, PWideChar(@Buffer.Data.Name[0]),
    Buffer.Data.NameLength div SizeOf(WideChar));
end;

function NtxQueryUsageAtom;
var
  Buffer: IMemory<PAtomBasicInformation>;
begin
  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TAtomBasicInformation) +
    SizeOf(WideChar));

  Result.Location := 'NtQueryInformationAtom';
  Result.LastCall.UsesInfoClass(AtomBasicInformation, icQuery);
  Result.Status := NtQueryInformationAtom(Atom, AtomBasicInformation,
    Buffer.Data, Buffer.Size, nil);

  if not Result.IsSuccess then
    Exit;

  Usage.UsageCount := Buffer.Data.UsageCount;
  Usage.Flags := Buffer.Data.Flags;
end;

function NtxEnumerateAtoms;
const
  INITIAL_SIZE = SizeOf(TAtomTableInformation);
var
  Buffer: IMemory<PAtomTableInformation>;
begin
  IMemory(Buffer) := Auto.AllocateDynamic(INITIAL_SIZE);

  repeat
    Result.Status := NtQueryInformationAtom(0, AtomTableInformation,
      Buffer.Data, Buffer.Size, nil);

  until not NtxExpandBufferEx(Result, IMemory(Buffer),
    SizeOf(TAtomTableInformation) + Buffer.Data.NumberOfAtoms * SizeOf(Word));

  if not Result.IsSuccess then
    Exit;

  SetLength(Atoms, Buffer.Data.NumberOfAtoms);

  if Length(Atoms) > 0 then
    Move(Buffer.Data.Atoms, Atoms[0], Length(Atoms) * SizeOf(Word));
end;

function NtxFindAtom;
begin
  Result.Location := 'NtFindAtom';
  Result.Status := NtFindAtom(PWideChar(AtomName), StringSizeNoZero(AtomName),
    @Atom);
end;

function NtxAddAtom;
begin
  Result.Location := 'NtAddAtom';
  Result.Status := NtAddAtom(PWideChar(AtomName), StringSizeNoZero(AtomName),
    @Atom);
end;

function NtxDeleteAtom;
begin
  Result.Location := 'NtDeleteAtom';
  Result.Status := NtDeleteAtom(Atom);
end;

function NtxEnumerateProps;
var
  RequiredCount: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserBuildPropList);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserBuildPropList';
  RequiredCount := 1;

  repeat
    Props := nil;
    Inc(RequiredCount);
    SetLength(Props, RequiredCount);

    Result.Status := NtUserBuildPropList(hwnd, RequiredCount, @Props[0],
      RequiredCount);
  until Result.Status <> STATUS_BUFFER_TOO_SMALL;

  if Result.IsSuccess then
    SetLength(Props, RequiredCount)
  else
    Props := nil;
end;

function NtxGetProp;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserGetProp);

  if not Result.IsSuccess then
    Exit;

  Value := 0;
  RtlSetLastWin32Error(ERROR_SUCCESS);
  Result.Location := 'NtUserGetProp';
  Value := NtUserGetProp(hwnd, Atom);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);
end;

function NtxSetProp;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserSetProp);

  if not Result.IsSuccess then
    Exit;

  Value := 0;
  RtlSetLastWin32Error(ERROR_INVALID_PARAMETER);
  Result.Location := 'NtUserSetProp';
  Result.Win32Result := NtUserSetProp(hwnd, Atom, Value);
end;

function NtxRemoveProp;
var
  Value: NativeUInt;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserRemoveProp);

  if not Result.IsSuccess then
    Exit;

  RtlSetLastWin32Error(ERROR_SUCCESS);
  Result.Location := 'NtUserRemoveProp';
  Value := NtUserRemoveProp(hwnd, Atom);
  Result.Win32Result := (Value <> 0) or (RtlGetLastWin32Error = ERROR_SUCCESS);

  if Result.IsSuccess and Assigned(OldValue) then
    OldValue^ := Value;
end;

{ Clipboard }

type
  TAutoClipboard = class (TDiscardableResource)
    destructor Destroy; override;
  end;

destructor TAutoClipboard.Destroy;
begin
  if not FDiscardOwnership and
    LdrxCheckDelayedImport(delayed_NtUserCloseClipboard).IsSuccess then
    NtUserCloseClipboard;
end;

function NtxOpenClipboard;
var
  EmptyClientValue: LongBool;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserOpenClipboard);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserOpenClipboard';
  Result.Win32Result := NtUserOpenClipboard(hwnd, EmptyClientValue);

  if not Result.IsSuccess then
    Exit;

  ClipboardRelease := TAutoClipboard.Create;

  if Assigned(EmptyClient) then
    EmptyClient^ := EmptyClientValue;
end;

function NtxCaptureMemHandle;
var
  Needed: Cardinal;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserCreateLocalMemHandle);

  if not Result.IsSuccess then
    Exit;

  Buffer := nil;
  Result.Location := 'NtUserCreateLocalMemHandle';

  repeat
    Result.Status := NtUserCreateLocalMemHandle(hMem, Auto.DataOrNil(Buffer),
      Auto.SizeOrZero(Buffer), @Needed);
  until not NtxExpandBufferEx(Result, Buffer, Needed);
end;

function NtxGetClipboardDataHandle;
begin
  Result := LdrxCheckDelayedImport(delayed_NtUserGetClipboardData);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'NtUserGetClipboardData';
  hMem := NtUserGetClipboardData(Format, Info);
  Result.Win32Result := hMem <> 0;
end;

function NtxGetClipboardData;
var
  hMem: TMemHandle;
begin
  Result := NtxGetClipboardDataHandle(Format, Info, hMem);

  if not Result.IsSuccess then
    Exit;

  Result := NtxCaptureMemHandle(hMem, Data);
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
