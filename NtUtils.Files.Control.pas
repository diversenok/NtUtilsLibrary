unit NtUtils.Files.Control;

{
  This module provides functions for issuing FSCTL and IOCTL requests.
}

interface

uses
  NtUtils, DelphiUtils.Async;

// Send an FSCTL to a filesystem
function NtxFsControlFile(
  hFile: THandle;
  FsControlCode: Cardinal;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [out, opt] OutputBuffer: Pointer = nil;
  OutputBufferLength: Cardinal = 0;
  [opt] const AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Query a variable-size data via an FSCTL
function NtxFsControlFileEx(
  hFile: THandle;
  FsControlCode: Cardinal;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [opt] const AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Send an IOCTL to a device
function NtxDeviceIoControlFile(
  hFile: THandle;
  IoControlCode: Cardinal;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [out, opt] OutputBuffer: Pointer = nil;
  OutputBufferLength: Cardinal = 0;
  [opt] const AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Query a variable-size data via an IOCTL
function NtxDeviceIoControlFileEx(
  hFile: THandle;
  IoControlCode: Cardinal;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [opt] const AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

type
  NtxFileControl = class abstract
    // Send an FSCTL to a filesystem with constant-size input
    class function FsControlIn<T>(
      hFile: THandle;
      FsControlCode: Cardinal;
      const Input: T
    ): TNtxStatus; static;

    // Send an FSCTL to a filesystem with constant-size output
    class function FsControlOut<T>(
      hFile: THandle;
      FsControlCode: Cardinal;
      out Output: T
    ): TNtxStatus; static;

    // Send an IOCTL to a device with constant-size input
    class function IoControlIn<T>(
      hFile: THandle;
      IoControlCode: Cardinal;
      const Input: T
    ): TNtxStatus; static;

    // Send an IOCTL to a device with constant-size output
    class function IoControlOut<T>(
      hFile: THandle;
      IoControlCode: Cardinal;
      out Output: T
    ): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntioapi, Ntapi.ntioapi.fsctl, NtUtils.Files.Operations,
  DelphiUtils.AutoObjects;

procedure AttachFsControlInfo(var Result: TNtxStatus; FsControlCode: Cardinal);
begin
  case DEVICE_TYPE_FSCTL(FsControlCode) of
    TDeviceType.FILE_DEVICE_FILE_SYSTEM:
      Result.LastCall.UsesInfoClass(FUNCTION_FROM_FS_FSCTL(FsControlCode),
        icControl);

    TDeviceType.FILE_DEVICE_NAMED_PIPE:
      Result.LastCall.UsesInfoClass(FUNCTION_FROM_PIPE_FSCTL(FsControlCode),
        icControl);
  end;
end;

function NtxFsControlFile;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtFsControlFile';
  AttachFsControlInfo(Result, FsControlCode);

  Result.Status := NtFsControlFile(hFile, 0, GetApcRoutine(AsyncCallback),
    Pointer(ApcContext), PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb),
    FsControlCode, InputBuffer, InputBufferLength, OutputBuffer,
    OutputBufferLength);

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
    AwaitFileOperation(Result, hFile, xIsb);
end;

function GrowMethodDefault(
  const Memory: IMemory;
  Required: NativeUInt
): NativeUInt;
begin
  Result := Memory.Size shl 1 + 256; // x2 + 256 B
end;

function NtxFsControlFileEx;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
  pIsb: PIoStatusBlock;
begin
  // NtFsControlFile does not return the required output size. We either need
  // to know how to grow the buffer, or we should guess.
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowMethodDefault;

  Result.Location := 'NtFsControlFile';
  AttachFsControlInfo(Result, FsControlCode);
  pIsb := PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    pIsb.Information := 0;

    Result.Status := NtFsControlFile(hFile, 0, GetApcRoutine(AsyncCallback),
      Pointer(ApcContext), pIsb, FsControlCode, InputBuffer, InputBufferLength,
      xMemory.Data, xMemory.Size);

    // Keep the context alive until the callback executes
    if Assigned(ApcContext) and Result.IsSuccess then
      ApcContext._AddRef;

    // Wait on asynchronous handles if no callback is available
    if not Assigned(AsyncCallback) then
      AwaitFileOperation(Result, hFile, xIsb);

  until not NtxExpandBufferEx(Result, xMemory, pIsb.Information, GrowthMethod);
end;

function NtxDeviceIoControlFile;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtDeviceIoControlFile';
  Result.Status := NtDeviceIoControlFile(hFile, 0, GetApcRoutine(AsyncCallback),
    Pointer(ApcContext), PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb),
    IoControlCode, InputBuffer, InputBufferLength, OutputBuffer,
    OutputBufferLength);

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
    AwaitFileOperation(Result, hFile, xIsb);
end;

function NtxDeviceIoControlFileEx;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
  pIsb: PIoStatusBlock;
begin
  // NtDeviceIoControlFile does not return the required output size. We either
  // need to know how to grow the buffer, or we should guess.
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowMethodDefault;

  Result.Location := 'NtDeviceIoControlFile';
  pIsb := PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    pIsb.Information := 0;

    Result.Status := NtDeviceIoControlFile(hFile, 0,
      GetApcRoutine(AsyncCallback), Pointer(ApcContext), pIsb,
      IoControlCode, InputBuffer, InputBufferLength, xMemory.Data,
      xMemory.Size);

    // Keep the context alive until the callback executes
    if Assigned(ApcContext) and Result.IsSuccess then
      ApcContext._AddRef;

    // Wait on asynchronous handles if no callback is available
    if not Assigned(AsyncCallback) then
      AwaitFileOperation(Result, hFile, xIsb);

  until not NtxExpandBufferEx(Result, xMemory, pIsb.Information, GrowthMethod);
end;

{ NtxFileControl }

class function NtxFileControl.FsControlIn<T>;
begin
  Result := NtxFsControlFile(hFile, FsControlCode, @Input, SizeOf(Input));
end;

class function NtxFileControl.FsControlOut<T>;
begin
  Result := NtxFsControlFile(hFile, FsControlCode, nil, 0, @Output,
    SizeOf(Output));
end;

class function NtxFileControl.IoControlIn<T>;
begin
  Result := NtxDeviceIoControlFile(hFile, IoControlCode, @Input, SizeOf(Input));
end;

class function NtxFileControl.IoControlOut<T>;
begin
  Result := NtxDeviceIoControlFile(hFile, IoControlCode, nil, 0, @Output,
    SizeOf(Output));
end;

end.
