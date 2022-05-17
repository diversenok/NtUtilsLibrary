unit NtUtils.Csr;

{
  This module provides functions for calling into CSRSS Win32 subsystem process.
}

interface

uses
  Ntapi.ntdef, Ntapi.ntcsrapi, DelphiApi.Reflection, NtUtils,
  DelphiUtils.AutoObjects;

type
  ICsrCaptureHeader = IMemory<PCsrCaptureHeader>;

// Allocate a buffer for capturing pointers before sending them to CSRSS
function CsrxAllocateCaptureBuffer(
  out CaptureBuffer: ICsrCaptureHeader;
  TotalLength: Cardinal;
  PoinerCount: Cardinal
): TNtxStatus;

// Prepare a region for storing data in a capture buffer
function CsrxAllocateMessagePointer(
  const CaptureBuffer: ICsrCaptureHeader;
  RequiredLength: Cardinal;
  out MessagePointer: Pointer
): TNtxStatus;

// Marshal a string into a capture buffer
procedure CsrxCaptureMessageString(
  const CaptureBuffer: ICsrCaptureHeader;
  const StringData: String;
  out CapturedString: TNtUnicodeString
);

// Capture multiple string pointers in a buffer without copying
function CsrxCaptureMessageMultiUnicodeStringsInPlace(
  out CaptureBuffer: ICsrCaptureHeader;
  const Strings: TArray<PNtUnicodeString>
): TNtxStatus;

// Send a message to CSRSS
function CsrxClientCallServer(
  var Msg: TCsrApiMsg;
  MsgSizeIncludingHeader: Cardinal;
  ApiNumber: TCsrApiNumber;
  [in, opt] CaptureBuffer: PCsrCaptureHeader = nil
): TNtxStatus;

{ BASESRV functions }

// Adjust shutdown order for the current process
function CsrxSetShutdownParameters(
  ShutdownLevel: Cardinal;
  ShutdownFlags: TShutdownParamFlags
): TNtxStatus;

// Determine shutdown order for the current process
function CsrxGetShutdownParameters(
  out ShutdownLevel: Cardinal;
  out ShutdownFlags: TShutdownParamFlags
): TNtxStatus;

// Define/undefine a symbolic link in the DosDevices object namespace directory
function CsrxDefineDosDevice(
  const DeviceName: String;
  const TargetPath: String;
  Flags: TDefineDosDeviceFlags = 0
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus;

type
  TCsrAutoBuffer = class (TCustomAutoMemory, IMemory)
    procedure Release; override;
  end;

procedure TCsrAutoBuffer.Release;
begin
  CsrFreeCaptureBuffer(FData);
  inherited;
end;

function CsrxAllocateCaptureBuffer;
var
  Buffer: PCsrCaptureHeader;
begin
  Buffer := CsrAllocateCaptureBuffer(PoinerCount, TotalLength);

  if not Assigned(Buffer) then
  begin
    Result.Location := 'CsrAllocateCaptureBuffer';
    Result.Status := STATUS_NO_MEMORY;
  end
  else
  begin
    IMemory(CaptureBuffer) := TCsrAutoBuffer.Capture(Buffer, TotalLength);
    Result.Status := STATUS_SUCCESS;
  end
end;

function CsrxAllocateMessagePointer;
var
  AllocatedBytes: Cardinal;
begin
  AllocatedBytes := CsrAllocateMessagePointer(CaptureBuffer.Data,
    RequiredLength, MessagePointer);

  if AllocatedBytes < RequiredLength then
  begin
    Result.Location := 'CsrAllocateMessagePointer';
    Result.Status := STATUS_NO_MEMORY;
  end
  else
    Result.Status := STATUS_SUCCESS;
end;

procedure CsrxCaptureMessageString;
begin
  CsrCaptureMessageString(
    CaptureBuffer.Data,
    PWideChar(StringData),
    Length(StringData) * SizeOf(WideChar),
    Succ(Length(StringData)) * SizeOf(WideChar),
    CapturedString
  );
end;

function CsrxCaptureMessageMultiUnicodeStringsInPlace;
var
  Buffer: PCsrCaptureHeader;
begin
  Buffer := nil;

  Result.Location := 'CsrCaptureMessageMultiUnicodeStringsInPlace';
  Result.Status := CsrCaptureMessageMultiUnicodeStringsInPlace(Buffer,
    Length(Strings), Strings);

  if Result.IsSuccess then
    IMemory(CaptureBuffer) := TCsrAutoBuffer.Capture(Buffer, 0);
end;

function CsrxClientCallServer;
begin
  if MsgSizeIncludingHeader < SizeOf(TCsrApiMsg) then
  begin
    Result.Location := 'CsrxClientCallServer';
    Result.Status := STATUS_INVALID_BUFFER_SIZE;
    Exit;
  end;

  Result.Location := 'CsrClientCallServer';
  Result.Status := CsrClientCallServer(Msg, CaptureBuffer, ApiNumber,
    MsgSizeIncludingHeader - SizeOf(TCsrApiMsg));
end;

{ Base SRV }

function CsrxClientCallServerBaseSrv(
  var Msg: TCsrApiMsg;
  MsgSizeIncludingHeader: Cardinal;
  BaseSrvApiNumber: TBaseSrvApiNumber;
  [in, opt] CaptureBuffer: PCsrCaptureHeader = nil
): TNtxStatus;
begin
  Result := CsrxClientCallServer(Msg, MsgSizeIncludingHeader,
    CsrMakeApiNumber(BASESRV_SERVERDLL_INDEX, Word(BaseSrvApiNumber)),
    CaptureBuffer);
  Result.LastCall.UsesInfoClass(BasepDefineDosDevice, icControl);
end;

function CsrxSetShutdownParameters;
var
  Msg: TBaseShutdownParamMsg;
begin
  Msg := Default(TBaseShutdownParamMsg);
  Msg.ShutdownLevel := ShutdownLevel;
  Msg.ShutdownFlags := ShutdownFlags;

  Result := CsrxClientCallServerBaseSrv(Msg.CsrMessage,
    SizeOf(TBaseShutdownParamMsg), BasepSetProcessShutdownParam);
end;

function CsrxGetShutdownParameters;
var
  Msg: TBaseShutdownParamMsg;
begin
  Msg := Default(TBaseShutdownParamMsg);

  Result := CsrxClientCallServerBaseSrv(Msg.CsrMessage,
    SizeOf(TBaseShutdownParamMsg), BasepGetProcessShutdownParam);

  if Result.IsSuccess then
  begin
    ShutdownLevel := Msg.ShutdownLevel;
    ShutdownFlags := Msg.ShutdownFlags;
  end;
end;

function CsrxDefineDosDevice;
var
  CaptureBuffer: ICsrCaptureHeader;
  Msg: TBaseDefineDosDeviceMsg;
begin
  // Allocate a Csr buffer for capturing string pointers
  Result := CsrxAllocateCaptureBuffer(CaptureBuffer, Succ(Length(DeviceName)) *
    SizeOf(WideChar) + Succ(Length(TargetPath)) * SizeOf(WideChar), 2);

  if not Result.IsSuccess then
    Exit;

  // Prepare the message and capture the strings
  Msg := Default(TBaseDefineDosDeviceMsg);
  Msg.Flags := Flags;
  CsrxCaptureMessageString(CaptureBuffer, DeviceName, Msg.DeviceName);
  CsrxCaptureMessageString(CaptureBuffer, TargetPath, Msg.TargetPath);

  // Call CSRSS
  Result := CsrxClientCallServerBaseSrv(Msg.CsrMessage,
    SizeOf(TBaseDefineDosDeviceMsg), BasepDefineDosDevice, CaptureBuffer.Data);
end;

end.
