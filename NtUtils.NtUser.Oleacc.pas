unit NtUtils.NtUser.Oleacc;

{
  This module provides support for OLE Accessibility Hooks.
}

interface

uses
  Ntapi.WinUser, Ntapi.Versions, NtUtils;

// Open a process handle via an OLE accessibility hook
// See GetProcessHandleFromHwnd docs on MSDN
[MinOSVersion(OsWin10RS1)]
function OleacxOpenProcessByWindow(
  out hxProcess: IHandle;
  hwnd: THwnd;
  TimeoutMs: Cardinal = 5000
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntseapi, Ntapi.ntmmapi, Ntapi.ntuser, Ntapi.ntpsapi,
  Ntapi.ObjIdl, DelphiUtils.AutoObjects, NtUtils.Ldr, NtUtils.NtUser,
  NtUtils.SysUtils, NtUtils.Tokens.Info, NtUtils.Security, NtUtils.Security.Acl,
  NtUtils.Sections, NtUtils.Objects, NtUtils.Objects.Namespace;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxMakeCurrentIntegritySecurityDescriptor(
  out SD: ISecurityDescriptor
): TNtxStatus;
var
  IntegritySid: ISid;
  SdData: TSecurityDescriptorData;
begin
  // Determine the current SID
  Result := NtxQuerySidToken(NtxCurrentProcessToken, TokenIntegrityLevel,
    IntegritySid);

  if not Result.IsSuccess then
    Exit;

  SdData := Default(TSecurityDescriptorData);
  SdData.Control := SE_SACL_PRESENT;

  // Prepare a SACL with the corresponding no-write-up label
  Result := RtlxBuildAcl(SdData.Sacl, [TAceData.New(
    SYSTEM_MANDATORY_LABEL_ACE_TYPE, 0, SYSTEM_MANDATORY_LABEL_NO_WRITE_UP,
    IntegritySid)]);

  if not Result.IsSuccess then
    Exit;

  // Capture it in self-relative security descriptor
  Result := RtlxAllocateSecurityDescriptor(SdData, SD);
end;

function OleacxOpenProcessByWindow;
var
  BnoPath: String;
  hxSection, hxHook: IHandle;
  SD: ISecurityDescriptor;
  Mapping: IMemory<POleaccRequestMessage>;
  MessageId: Cardinal;
  TargetThreadId: TThreadId;
  hProcess: THandle;
begin
  // The logic depends on the OLEACC hooking library being available
  Result := LdrxCheckDelayedImport(delayed_OleAccHook_CallWndProc);

  if not Result.IsSuccess then
    Exit;

  // Determine the window's owning thread
  Result := NtxWindow.Query(hwnd, WindowThread, TargetThreadId);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxGetNamedObjectPath(BnoPath);

  if not Result.IsSuccess then
    Exit;

  // Prepare a unique name for the shared section
  BnoPath := RtlxCombinePaths(BnoPath, RtlxFormatString(
    'OLEACC_HOOK_SHMEM_%d_%d', [NtCurrentProcessId, NtCurrentThreadId]));

  // Prepare a security descriptor to protect it from anybody below our
  // integrity (they will fail to send us the process handle anyway)
  Result := RtlxMakeCurrentIntegritySecurityDescriptor(SD);

  if not Result.IsSuccess then
    Exit;

  // Create a section for sharing data with the OLEACC hooks
  Result := NtxCreateSection(hxSection, SizeOf(TOleaccRequestMessage),
    PAGE_READWRITE, SEC_COMMIT, AttributeBuilder.UseName(BnoPath)
    .UseSecurity(SD));

  if not Result.IsSuccess then
    Exit;

  // Install the OLEACC hook in the target process
  Result := NtxSetWindowsHookEx(
    hxHook,
    WH_CALLWNDPROC,
    delayed_OleAccHook_CallWndProc.FunctionAddress,
    RtlxGetNtSystemRoot + '\system32\' + oleacchooks,
    delayed_OleAccHook_CallWndProc.Dll.DllAddress,
    TargetThreadId
  );

  if not Result.IsSuccess then
    Exit;

  // Identify the message ID to use with the hook
  Result := NtxRegisterWindowMessage('WM_OLEACC_HOOK', MessageId);

  if not Result.IsSuccess then
    Exit;

  // Send a message to trigger the hook. The hook will duplicate the taget's
  // process handle back to use and report its value via the shared section.
  Result := NtxSendMessage(hwnd, MessageId, NtCurrentProcessId,
    NativeInt(NtCurrentThreadId), SMTO_BLOCK or SMTO_ABORTIFHUNG or
    SMTO_ERRORONEXIT, TimeoutMs);

  if not Result.IsSuccess then
    Exit;

  // Prepare for using the section
  Result := NtxMapViewOfSection(hxSection, NtxCurrentProcess, IMemory(Mapping),
    MappingParameters.UseProtection(PAGE_READWRITE));

  if not Result.IsSuccess then
    Exit;

  // Capture ownership of the sent handle
  hProcess := AtomicExchange(Mapping.Data.ClientRelativeHandle, 0);
  Result := NtxCaptureHandle(hxProcess, hProcess);
end;

end.
