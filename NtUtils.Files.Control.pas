unit NtUtils.Files.Control;

{
  This module provides functions for issuing FSCTL and IOCTL requests.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntioapi, Ntapi.ntioapi.fsctl, Ntapi.ntseapi,
  Ntapi.Versions, NtUtils, DelphiUtils.Async;

// Send an FSCTL to a filesystem
function NtxFsControlFile(
  const hxFile: IHandle;
  FsControlCode: Cardinal;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [out, opt] OutputBuffer: Pointer = nil;
  OutputBufferLength: Cardinal = 0;
  [opt] AsyncCallback: TAnonymousApcCallback = nil;
  [out, opt] BytesTransferred: PNativeUInt = nil
): TNtxStatus;

// Query a variable-size data via an FSCTL
function NtxFsControlFileEx(
  const hxFile: IHandle;
  FsControlCode: Cardinal;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [opt] AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Send an IOCTL to a device
function NtxDeviceIoControlFile(
  const hxFile: IHandle;
  IoControlCode: Cardinal;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [out, opt] OutputBuffer: Pointer = nil;
  OutputBufferLength: Cardinal = 0;
  [opt] AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

// Query a variable-size data via an IOCTL
function NtxDeviceIoControlFileEx(
  const hxFile: IHandle;
  IoControlCode: Cardinal;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil;
  [in, opt] InputBuffer: Pointer = nil;
  InputBufferLength: Cardinal = 0;
  [opt] AsyncCallback: TAnonymousApcCallback = nil
): TNtxStatus;

type
  NtxFileControl = class abstract
    // Send an FSCTL to a filesystem with constant-size input
    class function FsControlIn<T>(
      const hxFile: IHandle;
      FsControlCode: Cardinal;
      const Input: T
    ): TNtxStatus; static;

    // Send an FSCTL to a filesystem with constant-size output
    class function FsControlOut<T>(
      const hxFile: IHandle;
      FsControlCode: Cardinal;
      out Output: T
    ): TNtxStatus; static;

    // Send an IOCTL to a device with constant-size input
    class function IoControlIn<T>(
      const hxFile: IHandle;
      IoControlCode: Cardinal;
      const Input: T
    ): TNtxStatus; static;

    // Send an IOCTL to a device with constant-size output
    class function IoControlOut<T>(
      const hxFile: IHandle;
      IoControlCode: Cardinal;
      out Output: T
    ): TNtxStatus; static;
  end;

{ Reparse points }

// Get the content of a reparse point of a file
function NtxGetReparseDataFile(
  const hxFile: IHandle;
  out ReparseTag: TReparseTag;
  out ReparseData: IMemory
): TNtxStatus;

// Set the content of a reparse point on a file
function NtxSetReparseDataFile(
  const hxFile: IHandle;
  ReparseTag: TReparseTag;
  [in] ReparseData: Pointer;
  ReparseDataSize: NativeUInt
): TNtxStatus;

// Delete a reparse point on a file
function NtxDeleteReparseDataFile(
  const hxFile: IHandle;
  ReparseTag: TReparseTag
): TNtxStatus;

{ Pipes }

// Wait for an instance of a named pipe to become available for connections
function NtxWaitPipe(
  const PipeServer: String;
  const PipeName: String;
  const Timeout: Int64 = NT_INFINITE;
  TimeoutSpecified: Boolean = True
): TNtxStatus;

// Read a content of a pipe without removing it
function NtxPeekPipe(
  const hxPipe: IHandle;
  DataSize: NativeUInt;
  out Info: TFilePipePeekBuffer;
  out Data: IMemory
): TNtxStatus;

// Create a pipe symlink
[MinOSVersion(OsWin10RS3)]
[RequiredPrivilege(SE_TCB_PRIVILEGE, rpAlways)]
function NtxCreateSymlinkPipe(
  const Name: String;
  const SubstituteName: String;
  Flags: TFilePipeSymlinkFlags = 0;
  [opt] hxPipeDevice: IHandle = nil
): TNtxStatus;

// Delete a pipe symlink
[MinOSVersion(OsWin10RS3)]
function NtxDeleteSymlinkPipe(
  const Name: String;
  [opt] hxPipeDevice: IHandle = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUtils.Files.Operations, NtUtils.Files.Open,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

procedure AttachFsControlInfo(var Result: TNtxStatus; FsControlCode: Cardinal);
begin
  case DEVICE_TYPE_FSCTL(FsControlCode) of
    TDeviceType.FILE_DEVICE_FILE_SYSTEM:
      Result.LastCall.UsesInfoClass(FUNCTION_FROM_FS_FSCTL(FsControlCode),
        icControl);

    TDeviceType.FILE_DEVICE_NAMED_PIPE:
      Result.LastCall.UsesInfoClass(FUNCTION_FROM_PIPE_FSCTL(FsControlCode),
        icControl);

    TDeviceType.FILE_DEVICE_MULTI_UNC_PROVIDER:
      Result.LastCall.UsesInfoClass(FUNCTION_FROM_MUP_FSCTL(FsControlCode),
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

  Result.Status := NtFsControlFile(HandleOrDefault(hxFile), 0,
    GetApcRoutine(AsyncCallback), Pointer(ApcContext),
    PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb), FsControlCode,
    InputBuffer, InputBufferLength, OutputBuffer, OutputBufferLength);

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
    AwaitFileOperation(Result, hxFile, xIsb);

  if Assigned(BytesTransferred) then
    BytesTransferred^ := xIsb.Data.Information;
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

    Result.Status := NtFsControlFile(HandleOrDefault(hxFile), 0,
      GetApcRoutine(AsyncCallback), Pointer(ApcContext), pIsb, FsControlCode,
      InputBuffer, InputBufferLength, xMemory.Data, xMemory.Size);

    // Keep the context alive until the callback executes
    if Assigned(ApcContext) and Result.IsSuccess then
      ApcContext._AddRef;

    // Wait on asynchronous handles if no callback is available
    if not Assigned(AsyncCallback) then
      AwaitFileOperation(Result, hxFile, xIsb);

  until not NtxExpandBufferEx(Result, xMemory, pIsb.Information, GrowthMethod);
end;

function NtxDeviceIoControlFile;
var
  ApcContext: IAnonymousIoApcContext;
  xIsb: IMemory<PIoStatusBlock>;
begin
  Result.Location := 'NtDeviceIoControlFile';
  Result.Status := NtDeviceIoControlFile(HandleOrDefault(hxFile), 0,
    GetApcRoutine(AsyncCallback), Pointer(ApcContext),
    PrepareApcIsbEx(ApcContext, AsyncCallback, xIsb), IoControlCode,
    InputBuffer, InputBufferLength, OutputBuffer, OutputBufferLength);

  // Keep the context alive until the callback executes
  if Assigned(ApcContext) and Result.IsSuccess then
    ApcContext._AddRef;

  // Wait on asynchronous handles if no callback is available
  if not Assigned(AsyncCallback) then
    AwaitFileOperation(Result, hxFile, xIsb);
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

    Result.Status := NtDeviceIoControlFile(HandleOrDefault(hxFile), 0,
      GetApcRoutine(AsyncCallback), Pointer(ApcContext), pIsb,
      IoControlCode, InputBuffer, InputBufferLength, xMemory.Data,
      xMemory.Size);

    // Keep the context alive until the callback executes
    if Assigned(ApcContext) and Result.IsSuccess then
      ApcContext._AddRef;

    // Wait on asynchronous handles if no callback is available
    if not Assigned(AsyncCallback) then
      AwaitFileOperation(Result, hxFile, xIsb);

  until not NtxExpandBufferEx(Result, xMemory, pIsb.Information, GrowthMethod);
end;

{ NtxFileControl }

class function NtxFileControl.FsControlIn<T>;
begin
  Result := NtxFsControlFile(hxFile, FsControlCode, @Input, SizeOf(Input));
end;

class function NtxFileControl.FsControlOut<T>;
begin
  Result := NtxFsControlFile(hxFile, FsControlCode, nil, 0, @Output,
    SizeOf(Output));
end;

class function NtxFileControl.IoControlIn<T>;
begin
  Result := NtxDeviceIoControlFile(hxFile, IoControlCode, @Input, SizeOf(Input));
end;

class function NtxFileControl.IoControlOut<T>;
begin
  Result := NtxDeviceIoControlFile(hxFile, IoControlCode, nil, 0, @Output,
    SizeOf(Output));
end;

function NtxGetReparseDataFile;
var
  Buffer: IMemory<PReparseDataBuffer>;
begin
  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TReparseDataBuffer) +
    MAXIMUM_REPARSE_DATA_BUFFER_SIZE);

  Result := NtxFsControlFile(hxFile, FSCTL_GET_REPARSE_POINT, nil, 0,
    Buffer.Data, Buffer.Size);

  if not Result.IsSuccess then
    Exit;

  ReparseTag := Buffer.Data.ReparseTag;
  ReparseData := Auto.AllocateDynamic(Buffer.Data.ReparseDataLength);
  Move(Buffer.Data.DataBuffer, ReparseData.Data^, ReparseData.Size);
end;

function NtxSetReparseDataFile;
var
  Buffer: IMemory<PReparseDataBuffer>;
begin
  if ReparseDataSize > MAXIMUM_REPARSE_DATA_BUFFER_SIZE then
  begin
    Result.Location := 'NtxSetReparseDataFile';
    Result.Status := STATUS_BUFFER_OVERFLOW;
    Exit;
  end;

  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TReparseDataBuffer) +
    ReparseDataSize);

  Buffer.Data.ReparseTag := ReparseTag;
  Buffer.Data.ReparseDataLength := Word(ReparseDataSize);
  Move(ReparseData^, Buffer.Data.DataBuffer, ReparseDataSize);

  Result := NtxFsControlFile(hxFile, FSCTL_SET_REPARSE_POINT, Buffer.Data,
    Buffer.Size);
end;

function NtxDeleteReparseDataFile;
var
  Buffer: TReparseDataBuffer;
begin
  Buffer := Default(TReparseDataBuffer);
  Buffer.ReparseTag := ReparseTag;

  Result := NtxFileControl.FsControlIn(hxFile, FSCTL_DELETE_REPARSE_POINT,
    Buffer);
end;

function NtxWaitPipe;
var
  hxPipeServer: IHandle;
  Buffer: IMemory<PFilePipeWaitForBuffer>;
begin
  Result := NtxOpenFile(hxPipeServer, FileParameters
    .UseFileName(PipeServer)
    .UseAccess(FILE_READ_ATTRIBUTES)
  );

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TFilePipeWaitForBuffer) +
    StringSizeNoZero(PipeName));

  Buffer.Data.Timeout := Timeout;
  Buffer.Data.NameLength := StringSizeNoZero(PipeName);
  Buffer.Data.TimeoutSpecified := TimeoutSpecified;
  Move(PWideChar(PipeName)^, Buffer.Data.Name, StringSizeNoZero(PipeName));

  Result := NtxFsControlFile(hxPipeServer, FSCTL_PIPE_WAIT, Buffer.Data,
    Buffer.Size);
end;

function NtxPeekPipe;
var
  Buffer: IMemory<PFilePipePeekBuffer>;
  ReturnedBytes: NativeUInt;
begin
  Info := Default(TFilePipePeekBuffer);
  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TFilePipePeekBuffer) +
    DataSize);

  Result := NtxFsControlFile(hxPipe, FSCTL_PIPE_PEEK, nil, 0, Buffer.Data,
    Buffer.Size, nil, @ReturnedBytes);

  if Result.Status = STATUS_BUFFER_OVERFLOW then
    Result.Status := STATUS_MORE_ENTRIES
  else if not Result.IsSuccess then
    Exit;

  if ReturnedBytes < SizeOf(TFilePipePeekBuffer) then
  begin
    Result.Location := 'NtxPeekPipe';
    Result.Status := STATUS_BUFFER_OVERFLOW;
    Exit;
  end;

  Info := Buffer.Data^;
  Data := Auto.AllocateDynamic(ReturnedBytes - SizeOf(TFilePipePeekBuffer));
  Move(Buffer.Data.Data, Data.Data^, Data.Size);
end;

function NtxCreateSymlinkPipe;
var
  Buffer: IMemory<PFilePipeCreateSymlinkInput>;
  Offset: Cardinal;
begin
  if not Assigned(hxPipeDevice) then
  begin
    // Open the pipe device
    Result := NtxOpenFile(hxPipeDevice, FileParameters
      .UseFileName(DEVICE_NAMED_PIPE));

    if not Result.IsSuccess then
      Exit;
  end;

  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TFilePipeCreateSymlinkInput) +
    StringSizeNoZero(Name) + StringSizeNoZero(SubstituteName));

  // Prepare the buffer
  Buffer.Data.NameLength := StringSizeNoZero(Name);
  Buffer.Data.SubstituteNameLength := StringSizeNoZero(SubstituteName);
  Buffer.Data.Flags := Flags;

  Offset := SizeOf(TFilePipeCreateSymlinkInput);
  Buffer.Data.NameOffset := Offset;
  Move(PWideChar(Name)^, Buffer.Offset(Offset)^, StringSizeNoZero(Name));

  Inc(Offset, StringSizeNoZero(Name));
  Buffer.Data.SubstituteNameOffset := Offset;
  Move(PWideChar(SubstituteName)^, Buffer.Offset(Offset)^,
    StringSizeNoZero(SubstituteName));

  // Issue the request
  Result := NtxFsControlFile(hxPipeDevice, FSCTL_PIPE_CREATE_SYMLINK,
    Buffer.Data, Buffer.Size);
  Result.LastCall.ExpectedPrivilege := SE_TCB_PRIVILEGE;
end;

function NtxDeleteSymlinkPipe;
var
  Buffer: IMemory<PFilePipeDeleteSymlinkInput>;
begin
  if not Assigned(hxPipeDevice) then
  begin
    // Open the pipe device
    Result := NtxOpenFile(hxPipeDevice, FileParameters
      .UseFileName(DEVICE_NAMED_PIPE));

    if not Result.IsSuccess then
      Exit;
  end;

  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TFilePipeDeleteSymlinkInput) +
    StringSizeNoZero(Name));

  // Prepare the buffer
  Buffer.Data.NameOffset := SizeOf(TFilePipeDeleteSymlinkInput);
  Buffer.Data.NameLength := StringSizeNoZero(Name);
  Move(PWideChar(Name)^, Buffer.Offset(SizeOf(TFilePipeDeleteSymlinkInput))^,
    StringSizeNoZero(Name));

  // Issue the request
  Result := NtxFsControlFile(hxPipeDevice, FSCTL_PIPE_DELETE_SYMLINK,
    Buffer.Data, Buffer.Size);
end;

end.
