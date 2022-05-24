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

// Register a process with SxS using an external manifest from a section
function CsrxRegisterProcessManifestFromSection(
  const hxProcess: IHandle;
  const ClientId: TClientId;
  const hxManifestSection: IHandle;
  ManifestSize: NativeUInt;
  const AssemblyDirectory: String
): TNtxStatus;

// Register a process with SxS using an external manifest from a file
function CsrxRegisterProcessManifestFromFile(
  const hxProcess: IHandle;
  const ClientId: TClientId;
  const FileName: String
): TNtxStatus;

// Register a process with SxS using an external manifest from a string
function CsrxRegisterProcessManifestFromString(
  const hxProcess: IHandle;
  const ClientId: TClientId;
  const ManifestString: UTF8String;
  const AssemblyDirectory: String
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntpsapi, Ntapi.ntmmapi, Ntapi.ntrtl, Ntapi.ImageHlp,
  Ntapi.ntpebteb, Ntapi.ntioapi, NtUtils.Processes.Info, NtUtils.Files.Open,
  NtUtils.Files.Operations, NtUtils.Sections, NtUtils.Processes,
  NtUtils.SysUtils;

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

function CsrxRegisterProcessManifestFromSection;
var
  Msg: TBaseCreateProcessMsg2;
  CaptureBuffer: ICsrCaptureHeader;
  BasicInfo: TProcessBasicInformation;
  WoW64Peb: Pointer;
  ImageInfo: TSectionImageInformation;
begin
  // Determine native PEB location
  Result := NtxProcess.Query(hxProcess.Handle, ProcessBasicInformation,
    BasicInfo);

  if not Result.IsSuccess then
    Exit;

  // Determine WoW64 PEB location
  Result := NtxProcess.Query(hxProcess.Handle, ProcessWow64Information,
    WoW64Peb);

  if not Result.IsSuccess then
    Exit;

  // Determine image architecture
  Result := NtxProcess.Query(hxProcess.Handle, ProcessImageInformation,
    ImageInfo);

  if not Result.IsSuccess then
    Exit;

  // Prepare a message to Csr/SxS
  Msg := Default(TBaseCreateProcessMsg2);
  Msg.ClientID := ClientID;
  Msg.Sxs.SxsFlags := BASE_MSG_SXS_MANIFEST_PRESENT;
  Msg.Sxs.CurrentParameterFlags := RTL_USER_PROC_APP_MANIFEST_PRESENT;
  Msg.Sxs.Manifest.FileType := BASE_MSG_FILETYPE_XML;
  Msg.Sxs.Manifest.HandleType := BASE_MSG_HANDLETYPE_SECTION;
  Msg.Sxs.Manifest.Handle := hxManifestSection.Handle;
  Msg.Sxs.Manifest.Size := ManifestSize;
  Msg.Sxs.AssemblyDirectory := TNtUnicodeString.From(AssemblyDirectory);
  Msg.Sxs.LanguageFallback := TNtUnicodeString.From(DEFAULT_LANGUAGE_FALLBACK);
  Msg.PebAddressNative := BasicInfo.PebBaseAddress;
  Msg.PebAddressWow64 := WoW64Peb;

  case ImageInfo.Machine of
    IMAGE_FILE_MACHINE_I386:
      Msg.ProcessorArchitecture := PROCESSOR_ARCHITECTURE_INTEL;

    IMAGE_FILE_MACHINE_AMD64:
      Msg.ProcessorArchitecture := PROCESSOR_ARCHITECTURE_AMD64;
  end;

  // Capture string buffers
  Result := CsrxCaptureMessageMultiUnicodeStringsInPlace(CaptureBuffer, [
    @Msg.Sxs.Manifest.Path,
    @Msg.Sxs.Policy.Path,
    @Msg.Sxs.AssemblyDirectory,
    @Msg.Sxs.LanguageFallback,
    @Msg.Sxs.InstallerDetectName
  ]);

  if not Result.IsSuccess then
    Exit;

  // Send the message to Csr
  Result := CsrxClientCallServerBaseSrv(Msg.CsrMessage,
    SizeOf(TBaseCreateProcessMsg2), BasepCreateProcess2, CaptureBuffer.Data);
end;

function CsrxRegisterProcessManifestFromFile;
var
  hxFile, hxSection: IHandle;
  FileInfo: TFileStandardInformation;
begin
  // Open the manifest file
  Result := NtxOpenFile(hxFile, FileOpenParameters
    .UseFileName(FileName, fnWin32)
    .UseAccess(FILE_READ_DATA)
  );

  if not Result.IsSuccess then
    Exit;

  // Determine its size
  Result := NtxFile.Query(hxFile.Handle, FileStandardInformation, FileInfo);

  if not Result.IsSuccess then
    Exit;

  // Create a section from the manifest
  Result := NtxCreateFileSection(hxSection, hxFIle.Handle, PAGE_READONLY,
    SEC_COMMIT);

  if not Result.IsSuccess then
    Exit;

  // Use the section object as the manifest source
  Result := CsrxRegisterProcessManifestFromSection(hxProcess, ClientId,
    hxSection, FileInfo.EndOfFile, RtlxExtractRootPath(FileName));
end;

function CsrxRegisterProcessManifestFromString;
var
  hxSection: IHandle;
  ManifestSize: NativeUInt;
  Mapping: IMemory;
begin
  ManifestSize := Length(ManifestString) * SizeOf(UTF8Char);

  // Create a section for sharing the manifest with SxS
  Result := NtxCreateSection(hxSection, ManifestSize, PAGE_READWRITE);

  if not Result.IsSuccess then
    Exit;

  // Map it locally to fill in the content
  Result := NtxMapViewOfSection(Mapping, hxSection.Handle, NtxCurrentProcess);

  if not Result.IsSuccess then
    Exit;

  // Copy the XML from the string
  Move(PUTF8Char(ManifestString)^, Mapping.Data^, ManifestSize);

  // Send the message to SxS
  Result := CsrxRegisterProcessManifestFromSection(hxProcess, ClientId,
    hxSection, ManifestSize, AssemblyDirectory);
end;

end.
