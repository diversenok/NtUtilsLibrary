unit NtUtils.Files.Control;

interface

uses
  NtUtils;

// Send an FSCTL to a filesystem
function NtxFsControlFile(hFile: THandle; FsControlCode: Cardinal; InputBuffer:
  Pointer = nil; InputBufferLength: Cardinal = 0; OutputBuffer: Pointer = nil;
  OutputBufferLength: Cardinal = 0): TNtxStatus;

// Query a variable-size data via an FSCTL
function NtxFsControlFileEx(hFile: THandle; FsControlCode: Cardinal; out xMemory:
  IMemory; InitialBuffer: Cardinal = 0; GrowthMethod: TBufferGrowthMethod = nil;
  InputBuffer: Pointer = nil; InputBufferLength: Cardinal = 0): TNtxStatus;

// Send an IOCTL to a device
function NtxDeviceIoControlFile(hFile: THandle; IoControlCode: Cardinal;
  InputBuffer: Pointer = nil; InputBufferLength: Cardinal = 0; OutputBuffer:
  Pointer = nil; OutputBufferLength: Cardinal = 0): TNtxStatus;

// Query a variable-size data via an IOCTL
function NtxDeviceIoControlFileEx(hFile: THandle; IoControlCode: Cardinal;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil; InputBuffer: Pointer = nil; InputBufferLength:
  Cardinal = 0): TNtxStatus;

type
  NtxFileControl = class abstract
    // Send an FSCTL to a filesystem with constant-size input
    class function FsControlIn<T>(hFile: THandle; FsControlCode: Cardinal;
      const Input: T): TNtxStatus; static;

    // Send an FSCTL to a filesystem with constant-size output
    class function FsControlOut<T>(hFile: THandle; FsControlCode: Cardinal;
      out Output: T): TNtxStatus; static;

    // Send an IOCTL to a device with constant-size input
    class function IoControlIn<T>(hFile: THandle; IoControlCode: Cardinal;
      const Input: T): TNtxStatus; static;

    // Send an IOCTL to a device with constant-size output
    class function IoControlOut<T>(hFile: THandle; IoControlCode: Cardinal;
      out Output: T): TNtxStatus; static;
  end;

implementation

uses
  Ntapi.ntioapi, Ntapi.ntioapi.fsctl, NtUtils.Files;

procedure AttachFsControlInfo(var Result: TNtxStatus; FsControlCode: Cardinal);
begin
  case DEVICE_TYPE_FSCTL(FsControlCode) of
    TDeviceType.FILE_DEVICE_FILE_SYSTEM:
      Result.LastCall.AttachInfoClass(FUNCTION_FROM_FS_FSCTL(FsControlCode));

    TDeviceType.FILE_DEVICE_NAMED_PIPE:
      Result.LastCall.AttachInfoClass(FUNCTION_FROM_PIPE_FSCTL(FsControlCode));
  end;
end;

function NtxFsControlFile(hFile: THandle; FsControlCode: Cardinal; InputBuffer:
  Pointer; InputBufferLength: Cardinal; OutputBuffer: Pointer;
  OutputBufferLength: Cardinal): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtFsControlFile';
  AttachFsControlInfo(Result, FsControlCode);

  Result.Status := NtFsControlFile(hFile, 0, nil, nil, IoStatusBlock,
    FsControlCode, InputBuffer, InputBufferLength, OutputBuffer,
    OutputBufferLength);

  // Wait on asynchronous handles
  AwaitFileOperation(Result, hFile, IoStatusBlock);
end;

function GrowMethodDefault(Memory: IMemory; Required: NativeUInt): NativeUInt;
begin
  Result := Memory.Size shl 1 + 256; // x2 + 256 B
end;

function NtxFsControlFileEx(hFile: THandle; FsControlCode: Cardinal; out xMemory:
  IMemory; InitialBuffer: Cardinal; GrowthMethod: TBufferGrowthMethod;
  InputBuffer: Pointer; InputBufferLength: Cardinal): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  // NtFsControlFile does not return the required output size. We either need
  // to know how to grow the buffer, or we should guess.
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowMethodDefault;

  Result.Location := 'NtFsControlFile';
  AttachFsControlInfo(Result, FsControlCode);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    IoStatusBlock.Information := 0;

    Result.Status := NtFsControlFile(hFile, 0, nil, nil, IoStatusBlock,
      FsControlCode, InputBuffer, InputBufferLength, xMemory.Data,
      xMemory.Size);

    // Wait on asynchronous handles
    AwaitFileOperation(Result, hFile, IoStatusBlock);

  until not NtxExpandBufferEx(Result, xMemory, IoStatusBlock.Information,
    GrowthMethod);
end;

function NtxDeviceIoControlFile(hFile: THandle; IoControlCode: Cardinal;
  InputBuffer: Pointer; InputBufferLength: Cardinal; OutputBuffer:
  Pointer; OutputBufferLength: Cardinal): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtDeviceIoControlFile';
  Result.Status := NtDeviceIoControlFile(hFile, 0, nil, nil, IoStatusBlock,
    IoControlCode, InputBuffer, InputBufferLength, OutputBuffer,
    OutputBufferLength);

  // Wait on asynchronous handles
  AwaitFileOperation(Result, hFile, IoStatusBlock);
end;

function NtxDeviceIoControlFileEx(hFile: THandle; IoControlCode: Cardinal;
  out xMemory: IMemory; InitialBuffer: Cardinal = 0; GrowthMethod:
  TBufferGrowthMethod = nil; InputBuffer: Pointer = nil; InputBufferLength:
  Cardinal = 0): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  // NtDeviceIoControlFile does not return the required output size. We either
  // need to know how to grow the buffer, or we should guess.
  if not Assigned(GrowthMethod) then
    GrowthMethod := GrowMethodDefault;

  Result.Location := 'NtDeviceIoControlFile';

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    IoStatusBlock.Information := 0;

    Result.Status := NtDeviceIoControlFile(hFile, 0, nil, nil, IoStatusBlock,
      IoControlCode, InputBuffer, InputBufferLength, xMemory.Data,
      xMemory.Size);

    // Wait on asynchronous handles
    AwaitFileOperation(Result, hFile, IoStatusBlock);

  until not NtxExpandBufferEx(Result, xMemory, IoStatusBlock.Information,
    GrowthMethod);
end;

{ NtxFileControl }

class function NtxFileControl.FsControlIn<T>(hFile: THandle;
  FsControlCode: Cardinal; const Input: T): TNtxStatus;
begin
  Result := NtxFsControlFile(hFile, FsControlCode, @Input, SizeOf(Input));
end;

class function NtxFileControl.FsControlOut<T>(hFile: THandle;
  FsControlCode: Cardinal; out Output: T): TNtxStatus;
begin
  Result := NtxFsControlFile(hFile, FsControlCode, nil, 0, @Output,
    SizeOf(Output));
end;

class function NtxFileControl.IoControlIn<T>(hFile: THandle;
  IoControlCode: Cardinal; const Input: T): TNtxStatus;
begin
  Result := NtxDeviceIoControlFile(hFile, IoControlCode, @Input, SizeOf(Input));
end;

class function NtxFileControl.IoControlOut<T>(hFile: THandle;
  IoControlCode: Cardinal; out Output: T): TNtxStatus;
begin
  Result := NtxDeviceIoControlFile(hFile, IoControlCode, nil, 0, @Output,
    SizeOf(Output));
end;

end.