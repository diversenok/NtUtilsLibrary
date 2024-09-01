unit NtUtils.Csr;

{
  This module provides functions for calling into CSRSS Win32 subsystem process.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntcsrapi, Ntapi.ntpsapi, Ntapi.actctx,
  Ntapi.ImageHlp, NtUtils, NtUtils.ActCtx, DelphiUtils.AutoObjects;

type
  ICsrCaptureHeader = IMemory<PCsrCaptureHeader>;

// Allocate a buffer for capturing pointers before sending them to CSRSS
function CsrxAllocateCaptureBuffer(
  out CaptureBuffer: ICsrCaptureHeader;
  TotalLength: Cardinal;
  PointerCount: Cardinal
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

// Register a process with SxS
function CsrxRegisterProcessManifest(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] const hxProcess: IHandle;
  const hxThread: IHandle;
  const ClientId: TClientId;
  const Handle: IHandle;
  HandleType: TBaseMsgHandleType;
  const Region: TMemory;
  const Path: String
): TNtxStatus;

// Register a process with SxS using an external manifest from a file
function CsrxRegisterProcessManifestFromFile(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] const hxProcess: IHandle;
  const hxThread: IHandle;
  const ClientId: TClientId;
  const FileName: String;
  const Path: String
): TNtxStatus;

// Register a process with SxS using an external manifest from a string
function CsrxRegisterProcessManifestFromString(
  [Access(PROCESS_QUERY_LIMITED_INFORMATION)] const hxProcess: IHandle;
  const hxThread: IHandle;
  const ClientId: TClientId;
  const ManifestString: UTF8String;
  const Path: String
): TNtxStatus;

// Create an activation context via a message to SxS
function CsrxCreateActivationContext(
  out hxActCtx: IActivationContext;
  const Handle: IHandle;
  HandleType: TBaseMsgHandleType;
  const Region: TMemory;
  const ManifestPath: String = '';
  AssemblyDirectory: String = '';
  ResourceId: PWideChar = CREATEPROCESS_MANIFEST_RESOURCE_ID;
  ProcessorArchitecture: TProcessorArchitecture16 = PROCESSOR_ARCHITECTURE_CURRENT
): TNtxStatus;

// Create an activation context using an external manifest from a file
function CsrxCreateActivationContextFromFile(
  out hxActCtx: IActivationContext;
  const FileName: String;
  const AssemblyDirectory: String = '';
  ResourceId: PWideChar = CREATEPROCESS_MANIFEST_RESOURCE_ID;
  ProcessorArchitecture: TProcessorArchitecture16 = PROCESSOR_ARCHITECTURE_CURRENT
): TNtxStatus;

// Create an activation context using an external manifest from a string
function CsrxCreateActivationContextFromString(
  out hxActCtx: IActivationContext;
  const ManifestString: UTF8String;
  const FileName: String = '';
  const AssemblyDirectory: String = '';
  ResourceId: PWideChar = CREATEPROCESS_MANIFEST_RESOURCE_ID;
  ProcessorArchitecture: TProcessorArchitecture16 = PROCESSOR_ARCHITECTURE_CURRENT
): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, Ntapi.ntmmapi, Ntapi.ntrtl, Ntapi.ntioapi, Ntapi.ntpebteb,
  Ntapi.Versions, NtUtils.Processes, NtUtils.Processes.Info, NtUtils.Files.Open,
  NtUtils.Files.Operations, NtUtils.Sections, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TCsrAutoBuffer = class (TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

procedure TCsrAutoBuffer.Release;
begin
  if Assigned(FData) then
    CsrFreeCaptureBuffer(FData);

  FData := nil;
  inherited;
end;

function CsrxAllocateCaptureBuffer;
var
  Buffer: PCsrCaptureHeader;
begin
  Buffer := CsrAllocateCaptureBuffer(PointerCount, TotalLength);

  if not Assigned(Buffer) then
  begin
    Result.Location := 'CsrAllocateCaptureBuffer';
    Result.Status := STATUS_NO_MEMORY;
  end
  else
  begin
    IMemory(CaptureBuffer) := TCsrAutoBuffer.Capture(Buffer, TotalLength);
    Result := NtxSuccess;
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
    Result := NtxSuccess;
end;

procedure CsrxCaptureMessageString;
begin
  CsrCaptureMessageString(
    CaptureBuffer.Data,
    PWideChar(StringData),
    StringSizeNoZero(StringData),
    StringSizeZero(StringData),
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
    IMemory(CaptureBuffer) := TCsrAutoBuffer.Capture(Buffer, Buffer.Length);
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
  Result.LastCall.UsesInfoClass(BaseSrvApiNumber, icControl);
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
  Result := CsrxAllocateCaptureBuffer(CaptureBuffer, StringSizeZero(DeviceName)
    + StringSizeZero(TargetPath), 2);

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

procedure CsrxpAdjustCreateProcessMsgLayout(
  var Msg: IMemory<PBaseCreateProcessMsgV1>;
  out StringsToCapture: TArray<PNtUnicodeString>
);
var
  MsgWin7: IMemory<PBaseCreateProcessMsgV1Win7>;
begin
  if RtlOsVersion in [OsWin7, OsWin8, OsWin81, OsWin1019H1, OsWin1019H2] then
  begin
    // Older versions of the OS have a slightly different structure layout
    IMemory(MsgWin7) := Auto.AllocateDynamic(SizeOf(TBaseCreateProcessMsgV1Win7));

    // Copy all fields
    MsgWin7.Data.CsrMessage := Msg.Data.CsrMessage;
    MsgWin7.Data.ProcessHandle := Msg.Data.ProcessHandle;
    MsgWin7.Data.ThreadHandle := Msg.Data.ThreadHandle;
    MsgWin7.Data.ClientID := Msg.Data.ClientID;
    MsgWin7.Data.CreationFlags := Msg.Data.CreationFlags;
    MsgWin7.Data.VdmBinaryType := Msg.Data.VdmBinaryType;
    MsgWin7.Data.VdmTask := Msg.Data.VdmTask;
    MsgWin7.Data.hVDM := Msg.Data.hVDM;
    MsgWin7.Data.Sxs.Flags := Msg.Data.Sxs.Flags;
    MsgWin7.Data.Sxs.ProcessParameterFlags := Msg.Data.Sxs.ProcessParameterFlags;
    MsgWin7.Data.Sxs.Union := Msg.Data.Sxs.Union;
    MsgWin7.Data.Sxs.CultureFallbacks := Msg.Data.Sxs.CultureFallbacks;
    MsgWin7.Data.Sxs.RunLevel := Msg.Data.Sxs.RunLevel;
    MsgWin7.Data.Sxs.SupportedOsInfo := Msg.Data.Sxs.SupportedOsInfo;
    // <-- Here is the field that breaks the layout
    MsgWin7.Data.Sxs.AssemblyName := Msg.Data.Sxs.AssemblyName;
    MsgWin7.Data.PebAddressNative := Msg.Data.PebAddressNative;
    MsgWin7.Data.PebAddressWow64 := Msg.Data.PebAddressWow64;
    MsgWin7.Data.ProcessorArchitecture := Msg.Data.ProcessorArchitecture;

    // Capture the strings with adjusted layout
    StringsToCapture := [
      @MsgWin7.Data.Sxs.Union.Local.Manifest.Path,
      @MsgWin7.Data.Sxs.Union.Local.Policy.Path,
      @MsgWin7.Data.Sxs.Union.Local.AssemblyDirectory,
      @MsgWin7.Data.Sxs.CultureFallbacks,
      @MsgWin7.Data.Sxs.AssemblyName
    ];

    // Replace the buffer
    IMemory(Msg) := IMemory(MsgWin7);
  end
  else
  begin
    // Capture the strings with normal layout
    StringsToCapture := [
      @Msg.Data.Sxs.Union.Local.Manifest.Path,
      @Msg.Data.Sxs.Union.Local.Policy.Path,
      @Msg.Data.Sxs.Union.Local.AssemblyDirectory,
      @Msg.Data.Sxs.CultureFallbacks,
      @Msg.Data.Sxs.AssemblyName
    ];
  end;
end;

function CsrxRegisterProcessManifest;
var
  Msg: IMemory<PBaseCreateProcessMsgV1>;
  StringsToCapture: TArray<PNtUnicodeString>;
  CaptureBuffer: ICsrCaptureHeader;
  BasicInfo: TProcessBasicInformation;
  WoW64Peb: Pointer;
  ImageInfo: TSectionImageInformation;
  AssemblyDirectory: String;
begin
  // Determine native PEB location
  Result := NtxProcess.Query(hxProcess, ProcessBasicInformation,  BasicInfo);

  if not Result.IsSuccess then
    Exit;

  // Determine WoW64 PEB location
  Result := NtxProcess.Query(hxProcess, ProcessWow64Information, WoW64Peb);

  if not Result.IsSuccess then
    Exit;

  // Determine image architecture
  Result := NtxProcess.Query(hxProcess, ProcessImageInformation, ImageInfo);

  if not Result.IsSuccess then
    Exit;

  // Prepare a message to Csr/SxS
  IMemory(Msg) := Auto.AllocateDynamic(SizeOf(TBaseCreateProcessMsgV1));

  Result := RtlxInitUnicodeString(Msg.Data.Sxs.Union.Local.Manifest.Path,
    Path);

  if not Result.IsSuccess then
    Exit;

  AssemblyDirectory := RtlxExtractRootPath(Path);
  Result := RtlxInitUnicodeString(Msg.Data.Sxs.Union.Local.AssemblyDirectory,
    AssemblyDirectory);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(Msg.Data.Sxs.CultureFallbacks,
    DEFAULT_CULTURE_FALLBACKS);

  if not Result.IsSuccess then
    Exit;

  Msg.Data.ProcessHandle := HandleOrDefault(hxProcess);
  Msg.Data.ThreadHandle := HandleOrDefault(hxThread);
  Msg.Data.ClientID := ClientID;
  Msg.Data.Sxs.Flags := BASE_MSG_SXS_MANIFEST_PRESENT;
  Msg.Data.Sxs.ProcessParameterFlags := RTL_USER_PROC_APP_MANIFEST_PRESENT;
  Msg.Data.Sxs.Union.Local.Manifest.FileType := BASE_MSG_FILETYPE_XML;
  Msg.Data.Sxs.Union.Local.Manifest.PathType := BASE_MSG_PATHTYPE_FILE;
  Msg.Data.Sxs.Union.Local.Manifest.HandleType := HandleType;
  Msg.Data.Sxs.Union.Local.Manifest.Handle := HandleOrDefault(Handle);
  Msg.Data.Sxs.Union.Local.Manifest.Offset := UIntPtr(Region.Address);
  Msg.Data.Sxs.Union.Local.Manifest.Size := Region.Size;
  Msg.Data.PebAddressNative := UIntPtr(BasicInfo.PebBaseAddress);
  Msg.Data.PebAddressWow64 := UIntPtr(WoW64Peb);

  case ImageInfo.Machine of
    IMAGE_FILE_MACHINE_I386:
      Msg.Data.ProcessorArchitecture := PROCESSOR_ARCHITECTURE_INTEL;

    IMAGE_FILE_MACHINE_AMD64:
      Msg.Data.ProcessorArchitecture := PROCESSOR_ARCHITECTURE_AMD64;
  end;

  // Fix data layout for older OS versions
  CsrxpAdjustCreateProcessMsgLayout(Msg, StringsToCapture);

  // Capture string buffers
  Result := CsrxCaptureMessageMultiUnicodeStringsInPlace(CaptureBuffer,
    StringsToCapture);

  if not Result.IsSuccess then
    Exit;

  // Send the message to Csr
  Result := CsrxClientCallServerBaseSrv(Msg.Data.CsrMessage, Msg.Size,
    BasepCreateProcess, CaptureBuffer.Data);
end;

function CsrxRegisterProcessManifestFromFile;
var
  hxFile, hxSection: IHandle;
  FileInfo: TFileStandardInformation;
begin
  // Open the manifest file
  Result := NtxOpenFile(hxFile, FileParameters
    .UseFileName(FileName, fnWin32)
    .UseAccess(FILE_READ_DATA)
    .UseOptions(FILE_NON_DIRECTORY_FILE)
    .UseSyncMode(fsAsynchronous)
  );

  if not Result.IsSuccess then
    Exit;

  // Determine its size
  Result := NtxFile.Query(hxFile, FileStandardInformation, FileInfo);

  if not Result.IsSuccess then
    Exit;

  // Create a section from the manifest
  Result := NtxCreateFileSection(hxSection, hxFile, PAGE_READONLY, SEC_COMMIT);

  if not Result.IsSuccess then
    Exit;

  // Use the section object as the manifest source
  Result := CsrxRegisterProcessManifest(hxProcess, hxThread, ClientId,
    hxSection, BASE_MSG_HANDLETYPE_SECTION, TMemory.From(nil,
    FileInfo.EndOfFile), Path);
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
  Result := NtxMapViewOfSection(hxSection, NtxCurrentProcess, Mapping,
    MappingParameters.UseProtection(PAGE_READWRITE));

  if not Result.IsSuccess then
    Exit;

  // Copy the XML from the string
  Move(PUTF8Char(ManifestString)^, Mapping.Data^, ManifestSize);

  // Send the message to SxS
  Result := CsrxRegisterProcessManifest(hxProcess, hxThread, ClientId,
    hxSection, BASE_MSG_HANDLETYPE_SECTION, TMemory.From(nil,
    ManifestSize), Path);
end;

function CsrxCreateActivationContext;
var
  Msg: TBaseSxsCreateActivationContextMsg;
  ActivationContextData: PActivationContextData;
  CaptureBuffer: ICsrCaptureHeader;
begin
  if AssemblyDirectory = '' then
    AssemblyDirectory := USER_SHARED_DATA.NtSystemRoot + '\WinSxS';

  Result := RtlxInitUnicodeString(Msg.AssemblyDirectory, AssemblyDirectory);

  if not Result.IsSuccess then
    Exit;

  Result := RtlxInitUnicodeString(Msg.CultureFallbacks, DEFAULT_CULTURE_FALLBACKS);

  if not Result.IsSuccess then
    Exit;

  Msg := Default(TBaseSxsCreateActivationContextMsg);
  Msg.Flags := BASE_MSG_SXS_MANIFEST_PRESENT;
  Msg.ProcessorArchitecture := ProcessorArchitecture;
  Msg.Manifest.FileType := BASE_MSG_FILETYPE_XML;
  Msg.Manifest.HandleType := HandleType;
  Msg.Manifest.Handle := HandleOrDefault(Handle);
  Msg.Manifest.Offset := UIntPtr(Region.Address);
  Msg.Manifest.Size := Region.Size;
  Msg.ResourceName := ResourceId;
  Msg.ActivationContextData := @ActivationContextData;

  if ManifestPath <> '' then
  begin
    Msg.Manifest.PathType := BASE_MSG_PATHTYPE_FILE;

    Result := RtlxInitUnicodeString(Msg.Manifest.Path, ManifestPath);

    if not Result.IsSuccess then
      Exit;
  end;

  // Capture string buffers
  Result := CsrxCaptureMessageMultiUnicodeStringsInPlace(CaptureBuffer,
    [@Msg.CultureFallbacks, @Msg.Manifest.Path, @Msg.Policy.Path,
    @Msg.AssemblyDirectory, @Msg.TextualAssemblyIdentity, @Msg.AssemblyName]);

  if not Result.IsSuccess then
    Exit;

  // Send the message to Csr
  Result := CsrxClientCallServerBaseSrv(Msg.CsrMessage, SizeOf(Msg),
    BasepCreateActivationContext, CaptureBuffer.Data);

  if not Result.IsSuccess then
    Exit;

  // Convert the activation context data into an activation context
  Result := RtlxCreateActivationContext(hxActCtx, ActivationContextData);

  // Make sure to unmap the data if something goes wrong
  if not Result.IsSuccess then
    NtxUnmapViewOfSection(NtxCurrentProcess, ActivationContextData);
end;

function CsrxCreateActivationContextFromFile;
var
  hxFile, hxSection: IHandle;
  FileInfo: TFileStandardInformation;
begin
  // Open the manifest file
  Result := NtxOpenFile(hxFile, FileParameters
    .UseFileName(FileName, fnWin32)
    .UseAccess(FILE_READ_DATA)
    .UseOptions(FILE_NON_DIRECTORY_FILE)
    .UseSyncMode(fsAsynchronous)
  );

  if not Result.IsSuccess then
    Exit;

  // Determine its size
  Result := NtxFile.Query(hxFile, FileStandardInformation, FileInfo);

  if not Result.IsSuccess then
    Exit;

  // Create a section from the manifest
  Result := NtxCreateFileSection(hxSection, hxFile, PAGE_READONLY, SEC_COMMIT);

  if not Result.IsSuccess then
    Exit;

  // Use the section object as the manifest source
  Result := CsrxCreateActivationContext(hxActCtx, hxSection,
    BASE_MSG_HANDLETYPE_SECTION, TMemory.From(nil, FileInfo.EndOfFile),
    FileName, AssemblyDirectory, ResourceId, ProcessorArchitecture);
end;

function CsrxCreateActivationContextFromString;
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
  Result := NtxMapViewOfSection(hxSection, NtxCurrentProcess, Mapping,
    MappingParameters.UseProtection(PAGE_READWRITE));

  if not Result.IsSuccess then
    Exit;

  // Copy the XML from the string
  Move(PUTF8Char(ManifestString)^, Mapping.Data^, ManifestSize);

  // Send the message to SxS
  Result := CsrxCreateActivationContext(hxActCtx, hxSection,
    BASE_MSG_HANDLETYPE_SECTION, TMemory.From(nil, ManifestSize), FileName,
    AssemblyDirectory, ResourceId, ProcessorArchitecture);
end;

end.
