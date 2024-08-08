unit NtUtils.WinRT;

interface

uses
  Ntapi.winrt, Ntapi.Versions, NtUtils, DelphiUtils.AutoObjects;

type
  IHString = IAutoPointer<THString>;

// Capture a WinRT string into an automatic buffer
[MinOSVersion(OsWin8)]
function RoxCaptureString(
  [in, opt] Buffer: THString
): IHString;

// Create a WinRT string from a Delphi string
[MinOSVersion(OsWin8)]
function RoxCreateString(
  const Source: String;
  out Str: IHString
): TNtxStatus;

// Create a Delphi string from a WinRT string
[MinOSVersion(OsWin8)]
function RoxDumpString(
  [in, opt] Str: THString
): String;

// Uninitialize the Windows Runtime
[MinOSVersion(OsWin8)]
procedure RoxUninitialize;

// Initialize the Windows Runtime
[MinOSVersion(OsWin8)]
function RoxInitialize(
  InitType: TRoInitType = RO_INIT_MULTITHREADED
): TNtxStatus;

// Initialize the Windows Runtime and uninitialize it later
[MinOSVersion(OsWin8)]
function RoxInitializeAuto(
  out Uninitializer: IAutoReleasable;
  InitType: TRoInitType = RO_INIT_MULTITHREADED
): TNtxStatus;

// Initialize the Windows Runtime and uninitialize it this module finalization
[MinOSVersion(OsWin8)]
function RoxInitializeOnce(
  InitType: TRoInitType = RO_INIT_MULTITHREADED
): TNtxStatus;

// Activate a WinRT class
[RequiresWinRT]
[MinOSVersion(OsWin8)]
function RoxActivateInstance(
  const ActivatableClassId: String;
  out Inspectable: IInspectable
): TNtxStatus;

implementation

uses
  Ntapi.ObjBase, Ntapi.WinError, Ntapi.ntpebteb, NtUtils.Ldr,
  NtUtils.Synchronization;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TRoxAutoString = class(TCustomAutoPointer, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

procedure TRoxAutoString.Release;
begin
  if Assigned(FData) and LdrxCheckDelayedImport(
    delayed_WindowsDeleteString).IsSuccess then
    WindowsDeleteString(FData);

  FData := nil;
  inherited;
end;

function RoxCaptureString;
begin
  IAutoPointer(Result) := TRoxAutoString.Capture(Buffer);
end;

function RoxCreateString;
var
  Buffer: THString;
begin
  Result := LdrxCheckDelayedImport(delayed_WindowsCreateString);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WindowsCreateString';
  Result.HResult := WindowsCreateString(PWideChar(Source),
    Length(Source), Buffer);

  if Result.IsSuccess then
    Str := RoxCaptureString(Buffer);
end;

function RoxDumpString;
var
  SourceLength: Cardinal;
begin
  if not LdrxCheckDelayedImport(delayed_WindowsGetStringRawBuffer).IsSuccess then
    Exit('');

  SetString(Result, WindowsGetStringRawBuffer(Str, @SourceLength),
    Integer(SourceLength));
end;

procedure RoxUninitialize;
begin
  if LdrxCheckDelayedImport(delayed_RoUninitialize).IsSuccess then
    RoUninitialize;
end;

function RoxInitialize;
begin
  Result := LdrxCheckDelayedImport(delayed_RoInitialize);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RoInitialize';
  Result.HResultAllowFalse := RoInitialize(InitType);

  // S_FALSE indicates that COM is already initialized; RPC_E_CHANGED_MODE means
  // that someone already initialized COM using a different mode. Use it, since
  // we still need to add a reference.

  if Result.HResult = RPC_E_CHANGED_MODE then
    Result.HResultAllowFalse := RoInitialize(TRoInitType(Cardinal(InitType) xor
      Cardinal(RO_INIT_MULTITHREADED)));
end;

function RoxInitializeAuto;
var
  CallingThread: TThreadId;
begin
  Result := RoxInitialize(InitType);

  if not Result.IsSuccess then
    Exit;

  // Record the calling thread since WinRT init is thread-specific
  CallingThread := NtCurrentTeb.ClientID.UniqueThread;

  Uninitializer := Auto.Delay(
    procedure
    begin
      // Make sure uninitialization runs on the same thread
      if CallingThread = NtCurrentTeb.ClientID.UniqueThread then
        RoxUninitialize;
    end
  );
end;

var
  // We want to release the reference on module unload
  RoxpInitialized: TRtlRunOnce;
  RoxpUninitializer: IAutoReleasable;

function RoxInitializeOnce;
var
  Init: IAcquiredRunOnce;
begin
  if not RtlxRunOnceBegin(@RoxpInitialized, Init) then
    Exit(NtxSuccess);

  Result := RoxInitializeAuto(RoxpUninitializer);

  if Result.IsSuccess then
    Init.Complete;
end;

function RoxActivateInstance;
var
  ClassIdString: IHString;
begin
  Result := LdrxCheckDelayedImport(delayed_RoActivateInstance);

  if not Result.IsSuccess then
    Exit;

  Result := RoxCreateString(ActivatableClassId, ClassIdString);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RoActivateInstance';
  Result.LastCall.Parameter := ActivatableClassId;
  Result.HResult := RoActivateInstance(ClassIdString.Data, Inspectable);
end;

end.
