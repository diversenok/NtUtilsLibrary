unit NtUtils.Files.Control;

interface

uses
  NtUtils;

// Send an FSCTL to a filesystem
function NtxFsControlFile(hFile: THandle; FsControlCode: Cardinal; InputBuffer:
  Pointer; InputBufferLength: Cardinal; OutputBuffer: Pointer;
  OutputBufferLength: Cardinal): TNtxStatus;

// Send a IOCTL to a device
function NtxDeviceIoControlFile(hFile: THandle; IoControlCode: Cardinal;
  InputBuffer: Pointer; InputBufferLength: Cardinal; OutputBuffer: Pointer;
  OutputBufferLength: Cardinal): TNtxStatus;

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
  Ntapi.ntioapi, Ntapi.ntstatus, NtUtils.Objects;

function NtxFsControlFile(hFile: THandle; FsControlCode: Cardinal; InputBuffer:
  Pointer; InputBufferLength: Cardinal; OutputBuffer: Pointer;
  OutputBufferLength: Cardinal): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtFsControlFile';
  Result.Status := NtFsControlFile(hFile, 0, nil, nil, IoStatusBlock,
    FsControlCode, InputBuffer, InputBufferLength, OutputBuffer,
    OutputBufferLength);

  // Wait for completion since IoStatusBlock is on our stack
  if Result.Status = STATUS_PENDING then
  begin
    Result := NtxWaitForSingleObject(hFile);

    if Result.IsSuccess then
      Result.Status := IoStatusBlock.Status;
  end;
end;

function NtxDeviceIoControlFile(hFile: THandle; IoControlCode: Cardinal;
  InputBuffer: Pointer; InputBufferLength: Cardinal; OutputBuffer: Pointer;
  OutputBufferLength: Cardinal): TNtxStatus;
var
  IoStatusBlock: TIoStatusBlock;
begin
  Result.Location := 'NtDeviceIoControlFile';
  Result.Status := NtDeviceIoControlFile(hFile, 0, nil, nil,
    IoStatusBlock, IoControlCode, InputBuffer, InputBufferLength, OutputBuffer,
    OutputBufferLength);

  // Wait for completion since IoStatusBlock is on our stack
  if Result.Status = STATUS_PENDING then
  begin
    Result := NtxWaitForSingleObject(hFile);

    if Result.IsSuccess then
      Result.Status := IoStatusBlock.Status;
  end;
end;

{ NtxFileControl }

class function NtxFileControl.FsControlIn<T>(hFile: THandle;
  FsControlCode: Cardinal; const Input: T): TNtxStatus;
begin
  Result := NtxFsControlFile(hFile, FsControlCode, @Input, SizeOf(Input),
    nil, 0);
end;

class function NtxFileControl.FsControlOut<T>(hFile: THandle;
  FsControlCode: Cardinal; out Output: T): TNtxStatus;
begin
  Result := NtxFsControlFile(hFile, FsControlCode, nil, 0,
    @Output, SizeOf(Output));
end;

class function NtxFileControl.IoControlIn<T>(hFile: THandle;
  IoControlCode: Cardinal; const Input: T): TNtxStatus;
begin
  Result := NtxDeviceIoControlFile(hFile, IoControlCode, @Input, SizeOf(Input),
    nil, 0);
end;

class function NtxFileControl.IoControlOut<T>(hFile: THandle;
  IoControlCode: Cardinal; out Output: T): TNtxStatus;
begin
  Result := NtxDeviceIoControlFile(hFile, IoControlCode, nil, 0,
    @Output, SizeOf(Output));
end;

end.
