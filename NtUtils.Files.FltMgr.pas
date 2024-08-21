unit NtUtils.Files.FltMgr;

{
  This module provides support for interacting with the Filter Manager (FltMgr).
}

interface

uses
  Ntapi.ntioapi.fsctl, Ntapi.ntseapi, Ntapi.Versions, NtUtils, NtUtils.Files,
  DelphiApi.Reflection;

type
  TFltxFilter = record
    FilterType: TFltFilterType;
    FrameID: Cardinal;
    NumberOfInstances: Cardinal;
    FilterName: String;
    Altitude: String;
  end;

  TFltxVolume = record
    Flags: TFilterVolumeFlags;
    FrameID: Cardinal;
    FileSystemType: TFltFilesystemType;
    VolumeName: String;
  end;

  TFltxInstance = record
    FilterType: TFltFilterType;
    VolumeFlags: TFilterVolumeFlags;
    FrameID: Cardinal;
    VolumeFileSystemType: TFltFilesystemType;
    InstanceName: String;
    Altitude: String;
    VolumeName: String;
    FilterName: String;
    [MinOSVersion(OsWin8)] SupportedFeatures: TSupportedFsFeatures;
  end;

{ Connection ports }

// Open to the specified filter connection port
function FltxConnect(
  out hxPort: IHandle;
  const PortParameters: IFileParameters;
  [opt] const Context: IMemory = nil
): TNtxStatus;

// Send a message to a filter
function FltxSendMessage(
  const hxPort: IHandle;
  [ReadsFrom] InputBuffer: Pointer;
  [NumberOfBytes] InputBufferSize: Cardinal;
  [WritesTo] OutputBuffer: Pointer;
  [NumberOfBytes] OutputBufferSize: Cardinal
): TNtxStatus;

// Get a message from a filter
function FltxGetMessage(
  const hxPort: IHandle;
  [WritesTo] OutputBuffer: Pointer;
  [NumberOfBytes] OutputBufferSize: Cardinal
): TNtxStatus;

// Reply to a message from a filter
function FltxReplyMessage(
  const hxPort: IHandle;
  [ReadsFrom] InputBuffer: Pointer = nil;
  [NumberOfBytes] InputBufferSize: Cardinal = 0
): TNtxStatus;

{ Operations }

// Open the filter manager device to perform load/unload/attach/detach
function FltxOpenFltMgrDevice(
  out hxFltMgr: IHandle
): TNtxStatus;

// Load a filter driver
[RequiredPrivilege(SE_LOAD_DRIVER_PRIVILEGE, rpAlways)]
function FltxLoadFilter(
  const hxFltMgr: IHandle;
  const FilterName: String
): TNtxStatus;

// Unload a filter driver
[RequiredPrivilege(SE_LOAD_DRIVER_PRIVILEGE, rpAlways)]
function FltxUnloadFilter(
  const hxFltMgr: IHandle;
  const FilterName: String
): TNtxStatus;

// Attach a filter to a volume
function FltxAttach(
  const hxFltMgr: IHandle;
  const FilterName: String;
  const VolumeName: String;
  [opt] const InstanceName: String = '';
  [opt] const Altitude: String = ''
): TNtxStatus;

// Detach a filter from a volume
function FltxDetach(
  const hxFltMgr: IHandle;
  const FilterName: String;
  const VolumeName: String;
  [opt] const InstanceName: String = ''
): TNtxStatus;

{ Filters }

// Open a filter manager
function FltxOpenFilterManager(
  out hxFilterManager: IHandle
): TNtxStatus;

// Find the first/next filter in a filter manager
function FltxFindFilter(
  const hxFilterManager: IHandle;
  out Info: TFltxFilter;
  RestartScan: Boolean = False;
  InfoClass: TFilterInformationClass = FilterAggregateStandardInformation
): TNtxStatus;

// Make a for-in iterator for enumerating filters in a filter manager
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function FltxIterateFilters(
  [out, opt] Status: PNtxStatus;
  const hxFilterManager: IHandle;
  InfoClass: TFilterInformationClass = FilterAggregateStandardInformation
): IEnumerable<TFltxFilter>;

// Open a filter by name
function FltxOpenFilter(
  out hxFilter: IHandle;
  const FilterName: String
): TNtxStatus;

// Query information about a filter
function FltxQueryFilter(
  const hxFilter: IHandle;
  out Info: TFltxFilter;
  InfoClass: TFilterInformationClass = FilterAggregateStandardInformation
): TNtxStatus;

{ Volumes }

// Open a filter volume manager
function FltxOpenVolumeManager(
  out hxVolumeManager: IHandle
): TNtxStatus;

// Find the first/next volume in a volume manager
function FltxFindVolume(
  const hxVolumeManager: IHandle;
  out Info: TFltxVolume;
  RestartScan: Boolean = False;
  InfoClass: TFilterVolumeInformationClass = FilterVolumeStandardInformation
): TNtxStatus;

// Make a for-in iterator for enumerating volumes in a volume manager
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function FltxIterateVolumes(
  [out, opt] Status: PNtxStatus;
  const hxVolumeManager: IHandle;
  InfoClass: TFilterVolumeInformationClass = FilterVolumeStandardInformation
): IEnumerable<TFltxVolume>;

// Open a volume by name
function FltxOpenVolume(
  out hxVolume: IHandle;
  const VolumeName: String
): TNtxStatus;

{ Instances }

// Find the first/next filter instance by filter or by volume
function FltxFindInstance(
  const hxFilterOrVolume: IHandle;
  out Info: TFltxInstance;
  RestartScan: Boolean = False;
  InfoClass: TInstanceInformationClass = InstanceAggregateStandardInformation
): TNtxStatus;

// Make a for-in iterator for enumerating filter instances by filter or by volume
// Note: when the Status parameter is not set, the function might raise
// exceptions during enumeration.
function FltxIterateInstances(
  [out, opt] Status: PNtxStatus;
  const hxFilterOrVolume: IHandle;
  InfoClass: TInstanceInformationClass = InstanceAggregateStandardInformation
): IEnumerable<TFltxInstance>;

// Open a filter instance by name
function FltxOpenInstance(
  out hxInstance: IHandle;
  const FilterName: String;
  const VolumeName: String;
  [opt] const InstanceName: String = ''
): TNtxStatus;

// Query information about a filter instance
function FltxQueryInstance(
  const hxInstance: IHandle;
  out Info: TFltxInstance;
  InfoClass: TInstanceInformationClass = InstanceAggregateStandardInformation
): TNtxStatus;

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntioapi, Ntapi.ntwow64, NtUtils.Files.Open,
  NtUtils.Files.Control, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Connection ports }

function FltxConnect;
var
  PortName: String;
  PortNameStr: TNtUnicodeString;
  PortNameStr64: TNtUnicodeString64;
  EAValue: IMemory<PFltConnectContext>;
begin
  // Prepare the port name for the EA
  PortName := PortParameters.FileName;
  Result := RtlxInitUnicodeString(PortNameStr, PortName);

  if not Result.IsSuccess then
    Exit;

  // Prepare the FLT EA value
  IMemory(EAValue) := Auto.AllocateDynamic(SizeOf(TFltConnectContext) +
    StringSizeZero(PortName) + Auto.SizeOrZero(Context));

  PortNameStr64.Length := PortNameStr.Length;
  PortNameStr64.MaximumLength := PortNameStr.MaximumLength;
  PortNameStr64.Buffer := UInt64(UIntPtr(PortNameStr.Buffer));
  EAValue.Data.PortName := @PortNameStr;
  EAValue.Data.PortName64 := @PortNameStr64;

  if Assigned(Context) then
  begin
    // Can we address that much context?
    if Context.Size >= High(Word) then
    begin
      Result.Location := 'FltxConnect';
      Result.Status := STATUS_BUFFER_OVERFLOW;
      Exit;
    end;

    EAValue.Data.SizeOfContext := Context.Size;
    Move(Context.Data^, EAValue.Data.Context, Context.Size);
  end;

  // Open the FltMgrMsg device passing the request
  Result := NtxCreateFile(hxPort, PortParameters
    .UseFileName(FLT_MSG_SYMLINK_NAME).UseFileId(0).UseRoot(nil)
    .UseEA([TNtxExtendedAttribute.From(FLT_PORT_EA_NAME, IMemory(EAValue))])
  );
end;

function FltxSendMessage;
begin
  Result := NtxDeviceIoControlFile(hxPort, FLT_CTL_SEND_MESSAGE, InputBuffer,
    InputBufferSize, OutputBuffer, OutputBufferSize);
  Result.LastCall.UsesInfoClass(TFltCtlFunction.FLT_CTL_SEND_MESSAGE, icPerform);
end;

function FltxGetMessage;
begin
  Result := NtxDeviceIoControlFile(hxPort, FLT_CTL_GET_MESSAGE, nil, 0,
    OutputBuffer, OutputBufferSize);
  Result.LastCall.UsesInfoClass(TFltCtlFunction.FLT_CTL_GET_MESSAGE, icPerform);
end;

function FltxReplyMessage;
begin
  Result := NtxDeviceIoControlFile(hxPort, FLT_CTL_REPLY_MESSAGE, InputBuffer,
    InputBufferSize);
  Result.LastCall.UsesInfoClass(TFltCtlFunction.FLT_CTL_REPLY_MESSAGE, icPerform);
end;

{ Common }

function FltxLinkHandle(
  out hxFltMgr: IHandle;
  LinkType: TFltLinkType;
  [opt] const Parameter: IMemory = nil
): TNtxStatus;
var
  Buffer: IMemory<PFltLink>;
begin
  // Open the filter manager device
  Result := NtxOpenFile(hxFltMgr, FileParameters
    .UseFileName(FLT_SYMLINK_NAME)
    .UseAccess(FILE_READ_DATA)
  );

  if not Result.IsSuccess then
    Exit;

  // Prepare the request buffer
  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TFltLink) +
    Auto.SizeOrZero(Parameter));
  Buffer.Data.LinkType := LinkType;

  if Assigned(Parameter) then
  begin
    // Copy the parameter buffer
    Buffer.Data.ParametersOffset := SizeOf(TFltLink);
    Move(Parameter.Data^, Buffer.Offset(SizeOf(TFltLink))^,
      Parameter.Size);
  end;

  // Link the handle
  Result := NtxDeviceIoControlFile(hxFltMgr, FLT_CTL_LINK_HANDLE, Buffer.Data,
    Buffer.Size);
  Result.LastCall.UsesInfoClass(TFltCtlFunction.FLT_CTL_LINK_HANDLE, icPerform);
end;

function FltxFind(
  const hxFltObject: IHandle;
  RestartScan: Boolean;
  InfoClass: Cardinal;
  out Buffer: IMemory
): TNtxStatus;
const
  INITIAL_SIZE = 200;
  CTL_CODE: array [Boolean] of Cardinal = (
    FLT_CTL_FIND_NEXT,
    FLT_CTL_FIND_FIRST
  );
  CTL_FUNCTION: array [Boolean] of TFltCtlFunction = (
    TFltCtlFunction.FLT_CTL_FIND_NEXT,
    TFltCtlFunction.FLT_CTL_FIND_FIRST
  );
begin
  // Request the first or the next entry
  Result := NtxDeviceIoControlFileEx(hxFltObject,
    CTL_CODE[RestartScan <> False], Buffer, INITIAL_SIZE, nil, @InfoClass,
    SizeOf(InfoClass));
  Result.LastCall.UsesInfoClass(CTL_FUNCTION[RestartScan <> False], icPerform);
end;

{ Operations }

function FltxOpenFltMgrDevice;
begin
  Result := NtxOpenFile(hxFltMgr, FileParameters
    .UseFileName(FLT_SYMLINK_NAME)
    .UseAccess(FILE_WRITE_DATA)
  );
end;

function FltxLoadUnloadFilter(
  const hxFltMgr: IHandle;
  const FilterName: String;
  Load: Boolean
): TNtxStatus;
const
  CTL_CODE: array [Boolean] of Cardinal = (
    FLT_CTL_UNLOAD,
    FLT_CTL_LOAD
  );
  CTL_FUNCTION: array [Boolean] of TFltCtlFunction = (
    TFltCtlFunction.FLT_CTL_UNLOAD,
    TFltCtlFunction.FLT_CTL_LOAD
  );
var
  Buffer: IMemory<PFltLoadParameters>;
begin
  // Check the name
  if Length(FilterName) > MAX_UNICODE_STRING then
  begin
    Result.Location := 'FltxLoadUnloadFilter';
    Result.Status := STATUS_NAME_TOO_LONG;
    Exit;
  end;

  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TFltLoadParameters) +
    StringSizeNoZero(FilterName));

  // Marshal parameters
  Buffer.Data.FilterNameSize := StringSizeNoZero(FilterName);
  Move(PWideChar(FilterName)^, Buffer.Data.FilterName,
    Buffer.Data.FilterNameSize);

  // Issue the request
  Result := NtxDeviceIoControlFile(hxFltMgr, CTL_CODE[Load <> False],
    Buffer.Data, Buffer.Size);
  Result.LastCall.UsesInfoClass(CTL_FUNCTION[Load <> False], icPerform);
  Result.LastCall.ExpectedPrivilege := SE_LOAD_DRIVER_PRIVILEGE;
end;

function FltxLoadFilter;
begin
  Result := FltxLoadUnloadFilter(hxFltMgr, FilterName, True);
end;

function FltxUnloadFilter;
begin
  Result := FltxLoadUnloadFilter(hxFltMgr, FilterName, False);
end;

function FltxAttach;
var
  Buffer: IMemory<PFltAttach>;
begin
  if (Length(FilterName) > MAX_UNICODE_STRING) or
    (Length(VolumeName) > MAX_UNICODE_STRING) or
    (Length(InstanceName) > MAX_UNICODE_STRING) or
    (Length(Altitude) > MAX_UNICODE_STRING) then
  begin
    Result.Location := 'FltxAttach';
    Result.Status := STATUS_NAME_TOO_LONG;
    Exit;
  end;

  IMemory(Buffer) := Auto.AllocateDynamic(SizeOf(TFltAttach) +
    StringSizeZero(FilterName) + StringSizeZero(VolumeName) +
    StringSizeZero(InstanceName) + StringSizeZero(Altitude));

  // Marshal the filter name
  Buffer.Data.FilterNameSize := StringSizeNoZero(FilterName);
  Buffer.Data.FilterNameOffset := SizeOf(TFltAttach);
  Move(PWideChar(FilterName)^, Buffer.Offset(Buffer.Data.FilterNameOffset)^,
    Buffer.Data.FilterNameSize);

  // Marshal the volume name
  Buffer.Data.VolumeNameSize := StringSizeNoZero(VolumeName);
  Buffer.Data.VolumeNameOffset := Buffer.Data.FilterNameOffset +
    Buffer.Data.FilterNameSize;
  Move(PWideChar(VolumeName)^, Buffer.Offset(Buffer.Data.VolumeNameOffset)^,
    Buffer.Data.VolumeNameSize);

  // Marshal the instance name
  Buffer.Data.InstanceNameSize := StringSizeNoZero(InstanceName);
  Buffer.Data.InstanceNameOffset := Buffer.Data.VolumeNameOffset +
    Buffer.Data.VolumeNameSize;
  Move(PWideChar(InstanceName)^, Buffer.Offset(Buffer.Data.InstanceNameOffset)^,
    Buffer.Data.InstanceNameSize);

  if Altitude <> '' then
  begin
    // Marshal the altitude
    Buffer.Data.AttachType := AltitudeBased;
    Buffer.Data.AltitudeSize := StringSizeNoZero(Altitude);
    Buffer.Data.AltitudeOffset := Buffer.Data.InstanceNameOffset +
      Buffer.Data.InstanceNameSize;
    Move(PWideChar(Altitude)^, Buffer.Offset(Buffer.Data.AltitudeOffset)^,
      Buffer.Data.AltitudeSize);
  end
  else
    Buffer.Data.AttachType := InstanceNameBased;

  // Issue the request
  Result := NtxDeviceIoControlFile(hxFltMgr, FLT_CTL_ATTACH, Buffer.Data,
    Buffer.Size);
  Result.LastCall.UsesInfoClass(TFltCtlFunction.FLT_CTL_ATTACH, icPerform);
end;

function FltxDetach;
var
  Parameters: IMemory<PFltInstanceParameters>;
begin
  // Check the names
  if (Length(FilterName) > MAX_UNICODE_STRING) or
    (Length(VolumeName) > MAX_UNICODE_STRING) or
    (Length(InstanceName) > MAX_UNICODE_STRING) then
  begin
    Result.Location := 'FltxOpenInstance';
    Result.Status := STATUS_NAME_TOO_LONG;
    Exit;
  end;

  IMemory(Parameters) := Auto.AllocateDynamic(SizeOf(TFltInstanceParameters) +
    StringSizeZero(FilterName) + StringSizeZero(VolumeName) +
    StringSizeZero(InstanceName));

  // Marshal the filter name
  Parameters.Data.FilterNameSize := StringSizeNoZero(FilterName);
  Parameters.Data.FilterNameOffset := SizeOf(TFltInstanceParameters);
  Move(PWideChar(FilterName)^, Parameters.Offset(
    Parameters.Data.FilterNameOffset)^, Parameters.Data.FilterNameSize);

  // Marshal the volume name
  Parameters.Data.VolumeNameSize := StringSizeNoZero(VolumeName);
  Parameters.Data.VolumeNameOffset := Parameters.Data.FilterNameOffset +
    Parameters.Data.FilterNameSize;
  Move(PWideChar(VolumeName)^, Parameters.Offset(
    Parameters.Data.VolumeNameOffset)^, Parameters.Data.VolumeNameSize);

  // Marshal the instance name
  Parameters.Data.InstanceNameSize := StringSizeNoZero(InstanceName);
  Parameters.Data.InstanceNameOffset := Parameters.Data.VolumeNameOffset +
    Parameters.Data.VolumeNameSize;
  Move(PWideChar(InstanceName)^, Parameters.Offset(
    Parameters.Data.InstanceNameOffset)^, Parameters.Data.InstanceNameSize);

  // Issue the request
  Result := NtxDeviceIoControlFile(hxFltMgr, FLT_CTL_DETATCH, Parameters.Data,
    Parameters.Size);
  Result.LastCall.UsesInfoClass(TFltCtlFunction.FLT_CTL_DETATCH, icPerform);
end;

{ Filter }

function FltxCaptureFilterInfo(
  InfoClass: TFilterInformationClass;
  [in] Cursor: Pointer
): TFltxFilter;
var
  FullInfo: PFilterFullInformation absolute Cursor;
  BasicInfo: PFilterAggregateBasicInformation absolute Cursor;
  StandardInfo: PFilterAggregateStandardInformation absolute Cursor;
begin
  Result := Default(TFltxFilter);

  case InfoClass of
    // Capture full info
    FilterFullInformation:
    begin
      Result.FrameID := FullInfo.FrameID;
      Result.NumberOfInstances := FullInfo.NumberOfInstances;
      SetString(Result.FilterName, PWideChar(@FullInfo.FilterNameBuffer[0]),
        FullInfo.FilterNameLength div SizeOf(WideChar))
    end;

    // Capture aggregate basic info
    FilterAggregateBasicInformation:
    begin
      Result.FilterType := TFltFilterType(Cardinal(BasicInfo.Flags) and $3);

      case Result.FilterType of
        FLTFL_IS_MINIFILTER:
        begin
          Result.FrameID := BasicInfo.FrameID;
          Result.NumberOfInstances := BasicInfo.NumberOfInstances;

          SetString(Result.FilterName, PWideChar(UIntPtr(BasicInfo) +
            BasicInfo.FilterNameBufferOffset),
            BasicInfo.FilterNameLength div SizeOf(WideChar));

          SetString(Result.Altitude, PWideChar(UIntPtr(BasicInfo) +
            BasicInfo.FilterAltitudeBufferOffset ),
            BasicInfo.FilterAltitudeLength div SizeOf(WideChar));
        end;

        FLTFL_IS_LEGACY_FILTER:
          SetString(Result.FilterName, PWideChar(UIntPtr(BasicInfo) +
            BasicInfo.LegacyFilterNameBufferOffset),
            BasicInfo.LegacyFilterNameLength div SizeOf(WideChar));
      end;
    end;

    // Capture aggregate standard info
    FilterAggregateStandardInformation:
    begin
      Result.FilterType := TFltFilterType(Cardinal(StandardInfo.Flags) and $3);

      case Result.FilterType of
        FLTFL_IS_MINIFILTER:
        begin
          Result.FrameID := StandardInfo.FrameID;
          Result.NumberOfInstances := StandardInfo.NumberOfInstances;

          SetString(Result.FilterName, PWideChar(UIntPtr(StandardInfo) +
            StandardInfo.FilterNameBufferOffset),
            StandardInfo.FilterNameLength div SizeOf(WideChar));

          SetString(Result.Altitude, PWideChar(UIntPtr(StandardInfo) +
            StandardInfo.FilterAltitudeBufferOffset ),
            StandardInfo.FilterAltitudeLength div SizeOf(WideChar));
        end;

        FLTFL_IS_LEGACY_FILTER:
        begin
          SetString(Result.FilterName, PWideChar(UIntPtr(StandardInfo) +
            StandardInfo.LegacyFilterNameBufferOffset),
            StandardInfo.LegacyFilterNameLength div SizeOf(WideChar));

          SetString(Result.FilterName, PWideChar(UIntPtr(StandardInfo) +
            StandardInfo.LegacyFilterAltitudeBufferOffset),
            StandardInfo.LegacyFilterAltitudeLength div SizeOf(WideChar));
        end;
      end;
    end;
  end;
end;

function FltxOpenFilterManager;
begin
  Result := FltxLinkHandle(hxFilterManager, FILTER_MANAGER);
end;

function FltxFindFilter;
var
  Buffer: IMemory;
begin
  case InfoClass of
    FilterFullInformation, FilterAggregateBasicInformation,
    FilterAggregateStandardInformation:
      ; // pass through
  else
    Result.Location := 'FltxFindFilter';
    Result.Status := STATUS_INVALID_INFO_CLASS;
    Exit;
  end;

  // Issue the IOCTL
  Result := FltxFind(hxFilterManager, RestartScan, Cardinal(InfoClass), Buffer);

  if not Result.IsSuccess then
    Exit;

  // Parse the result
  Info := FltxCaptureFilterInfo(InfoClass, Buffer.Data);
end;

function FltxIterateFilters;
var
  RestartScan: Boolean;
begin
  RestartScan := True;

  Result := NtxAuto.Iterate<TFltxFilter>(Status,
    function (out Current: TFltxFilter): TNtxStatus
    begin
      // Retrieve the next filter
      Result := FltxFindFilter(hxFilterManager, Current, RestartScan, InfoClass);

      if Result.IsSuccess then
        RestartScan := False;
    end
  );
end;

function FltxOpenFilter;
var
  Parameters: IMemory<PFltFilterParameters>;
begin
  // Check the name
  if Length(FilterName) > MAX_UNICODE_STRING then
  begin
    Result.Location := 'FltxOpenFilter';
    Result.Status := STATUS_NAME_TOO_LONG;
    Exit;
  end;

  IMemory(Parameters) := Auto.AllocateDynamic(SizeOf(TFltFilterParameters) +
    StringSizeZero(FilterName));

  // Marshal the filter name
  Parameters.Data.FilterNameSize := StringSizeNoZero(FilterName);
  Parameters.Data.FilterNameOffset := SizeOf(TFltFilterParameters);
  Move(PWideChar(FilterName)^, Parameters.Offset(
    Parameters.Data.FilterNameOffset)^, Parameters.Data.FilterNameSize);

  // Open and link a handle
  Result := FltxLinkHandle(hxFilter, FILTER, IMemory(Parameters));
end;

function FltxQueryFilter;
const
  INITIAL_SIZE = 200;
var
  Buffer: IMemory;
begin
  case InfoClass of
    FilterFullInformation, FilterAggregateBasicInformation,
    FilterAggregateStandardInformation:
      ; // pass through
  else
    Result.Location := 'FltxQueryFilter';
    Result.Status := STATUS_INVALID_INFO_CLASS;
    Exit;
  end;

  // Issue the IOCTL
  Result := NtxDeviceIoControlFileEx(hxFilter, FLT_CTL_GET_INFORMATION,
    Buffer, INITIAL_SIZE, nil, @InfoClass, SizeOf(InfoClass));
  Result.LastCall.UsesInfoClass(TFltCtlFunction.FLT_CTL_GET_INFORMATION,
    icPerform);

  if not Result.IsSuccess then
    Exit;

  // Parse the result
  Info := FltxCaptureFilterInfo(InfoClass, Buffer.Data);
end;

{ Volume }

function FltxCaptureVolumeInfo(
  InfoClass: TFilterVolumeInformationClass;
  [in] Cursor: Pointer
): TFltxVolume;
var
  BasicInfo: PFilterVolumeBasicInformation absolute Cursor;
  StandardInfo: PFilterVolumeStandardInformation absolute Cursor;
begin
  Result := Default(TFltxVolume);

  case InfoClass of
    // Parse the basic info
    FilterVolumeBasicInformation:
      SetString(Result.VolumeName, PWideChar(@BasicInfo.FilterVolumeName[0]),
        BasicInfo.FilterVolumeNameLength div SizeOf(WideChar));

    // Parse the standard info
    FilterVolumeStandardInformation:
    begin
      Result.Flags := StandardInfo.Flags;
      Result.FrameID := StandardInfo.FrameID;
      Result.FileSystemType := StandardInfo.FileSystemType;

      SetString(Result.VolumeName, PWideChar(@StandardInfo.FilterVolumeName[0]),
        StandardInfo.FilterVolumeNameLength div SizeOf(WideChar));
    end;
  end;
end;

function FltxOpenVolumeManager;
begin
  Result := FltxLinkHandle(hxVolumeManager, FILTER_MANAGER_VOLUME);
end;

function FltxFindVolume;
var
  Buffer: IMemory;
begin
  case InfoClass of
    FilterVolumeBasicInformation, FilterVolumeStandardInformation:
      ; // pass through
  else
    Result.Location := 'FltxFindVolume';
    Result.Status := STATUS_INVALID_INFO_CLASS;
    Exit;
  end;

  // Issue the IOCTL
  Result := FltxFind(hxVolumeManager, RestartScan, Cardinal(InfoClass), Buffer);

  if not Result.IsSuccess then
    Exit;

  // Parse the result
  Info := FltxCaptureVolumeInfo(InfoClass, Buffer.Data);
end;

function FltxIterateVolumes;
var
  RestartScan: Boolean;
begin
  RestartScan := True;

  Result := NtxAuto.Iterate<TFltxVolume>(Status,
    function (out Current: TFltxVolume): TNtxStatus
    begin
      // Retrieve the next volume
      Result := FltxFindVolume(hxVolumeManager, Current, RestartScan, InfoClass);

      if Result.IsSuccess then
        RestartScan := False;
    end
  );
end;

function FltxOpenVolume;
var
  Parameters: IMemory<PFltVolumeParameters>;
begin
  // Check the name
  if Length(VolumeName) > MAX_UNICODE_STRING then
  begin
    Result.Location := 'FltxOpenVolume';
    Result.Status := STATUS_NAME_TOO_LONG;
    Exit;
  end;

  IMemory(Parameters) := Auto.AllocateDynamic(SizeOf(TFltVolumeParameters) +
    StringSizeZero(VolumeName));

  // Marshal the volume name
  Parameters.Data.VolumeNameSize := StringSizeNoZero(VolumeName);
  Parameters.Data.VolumeNameOffset := SizeOf(TFltVolumeParameters);
  Move(PWideChar(VolumeName)^, Parameters.Offset(
    Parameters.Data.VolumeNameOffset)^, Parameters.Data.VolumeNameSize);

  // Open and link a handle
  Result := FltxLinkHandle(hxVolume, FILTER_VOLUME, IMemory(Parameters));
end;

{ Instance }

function FltxCaptureInstanceInfo(
  InfoClass: TInstanceInformationClass;
  [in] Cursor: Pointer
): TFltxInstance;
var
  BasicInfo: PInstanceBasicInformation absolute Cursor;
  PartialInfo: PInstancePartialInformation absolute Cursor;
  FullInfo: PInstanceFullInformation absolute Cursor;
  AgrInfo: PInstanceAggregateStandardInformation absolute Cursor;
begin
  Result := Default(TFltxInstance);

  case InfoClass of
    // Parse the basic info
    InstanceBasicInformation:
      SetString(Result.InstanceName, PWideChar(UIntPtr(BasicInfo) +
        BasicInfo.InstanceNameBufferOffset),
        BasicInfo.InstanceNameLength div SizeOf(WideChar));

    // Parse the partial info
    InstancePartialInformation:
    begin
      SetString(Result.InstanceName, PWideChar(UIntPtr(PartialInfo) +
        PartialInfo.InstanceNameBufferOffset),
        PartialInfo.InstanceNameLength div SizeOf(WideChar));

      SetString(Result.Altitude, PWideChar(UIntPtr(PartialInfo) +
        PartialInfo.AltitudeBufferOffset),
        PartialInfo.AltitudeLength div SizeOf(WideChar));
    end;

    // Parse the partial info
    InstanceFullInformation:
    begin
      SetString(Result.InstanceName, PWideChar(UIntPtr(FullInfo) +
        FullInfo.InstanceNameBufferOffset),
        FullInfo.InstanceNameLength div SizeOf(WideChar));

      SetString(Result.Altitude, PWideChar(UIntPtr(FullInfo) +
        FullInfo.AltitudeBufferOffset),
        FullInfo.AltitudeLength div SizeOf(WideChar));

      SetString(Result.VolumeName, PWideChar(UIntPtr(FullInfo) +
        FullInfo.VolumeNameBufferOffset),
        FullInfo.VolumeNameLength div SizeOf(WideChar));

      SetString(Result.FilterName, PWideChar(UIntPtr(FullInfo) +
        FullInfo.FilterNameBufferOffset),
        FullInfo.FilterNameLength div SizeOf(WideChar));
    end;

    // Parse the aggregate standard info
    InstanceAggregateStandardInformation:
    begin
      Result.FilterType := TFltFilterType(Cardinal(AgrInfo.Flags) and $3);

      case Result.FilterType of
        FLTFL_IS_MINIFILTER:
        begin
          Result.VolumeFlags := AgrInfo.VolumeFlags;
          Result.FrameID := AgrInfo.FrameID;
          Result.VolumeFileSystemType := AgrInfo.VolumeFileSystemType;

          SetString(Result.InstanceName, PWideChar(UIntPtr(AgrInfo) +
            AgrInfo.InstanceNameBufferOffset),
            AgrInfo.InstanceNameLength div SizeOf(WideChar));

          SetString(Result.Altitude, PWideChar(UIntPtr(AgrInfo) +
            AgrInfo.AltitudeBufferOffset),
            AgrInfo.AltitudeLength div SizeOf(WideChar));

          SetString(Result.VolumeName, PWideChar(UIntPtr(AgrInfo) +
            AgrInfo.VolumeNameBufferOffset),
            AgrInfo.VolumeNameLength div SizeOf(WideChar));

          SetString(Result.FilterName, PWideChar(UIntPtr(AgrInfo) +
            AgrInfo.FilterNameBufferOffset),
            AgrInfo.FilterNameLength div SizeOf(WideChar));

          if RtlOsVersionAtLeast(OsWin8) then
            Result.SupportedFeatures := AgrInfo.SupportedFeatures;
        end;

        FLTFL_IS_LEGACY_FILTER:
        begin
          Result.VolumeFlags := AgrInfo.LegacyVolumeFlags;

          SetString(Result.Altitude, PWideChar(UIntPtr(AgrInfo) +
            AgrInfo.LegacyAltitudeBufferOffset),
            AgrInfo.LegacyAltitudeLength div SizeOf(WideChar));

          SetString(Result.VolumeName, PWideChar(UIntPtr(AgrInfo) +
            AgrInfo.LegacyVolumeNameBufferOffset),
            AgrInfo.LegacyVolumeNameLength div SizeOf(WideChar));

          SetString(Result.FilterName, PWideChar(UIntPtr(AgrInfo) +
            AgrInfo.LegacyFilterNameBufferOffset),
            AgrInfo.LegacyFilterNameLength div SizeOf(WideChar));

          if RtlOsVersionAtLeast(OsWin8) then
            Result.SupportedFeatures := AgrInfo.LegacySupportedFeatures;
        end;
      end;
    end;
  end;
end;

function FltxFindInstance;
var
  Buffer: IMemory;
begin
  case InfoClass of
    InstanceBasicInformation, InstancePartialInformation,
    InstanceFullInformation, InstanceAggregateStandardInformation:
      ; // pass through
  else
    Result.Location := 'FltxFindInstance';
    Result.Status := STATUS_INVALID_INFO_CLASS;
    Exit;
  end;

  // Issue the IOCTL
  Result := FltxFind(hxFilterOrVolume, RestartScan, Cardinal(InfoClass), Buffer);

  if not Result.IsSuccess then
    Exit;

  // Parse the result
  Info := FltxCaptureInstanceInfo(InfoClass, Buffer.Data);
end;

function FltxIterateInstances;
var
  RestartScan: Boolean;
begin
  RestartScan := True;

  Result := NtxAuto.Iterate<TFltxInstance>(Status,
    function (out Current: TFltxInstance): TNtxStatus
    begin
      // Retrieve the next instance
      Result := FltxFindInstance(hxFilterOrVolume, Current, RestartScan,
        InfoClass);

      if Result.IsSuccess then
        RestartScan := False;
    end
  );
end;

function FltxOpenInstance;
var
  Parameters: IMemory<PFltInstanceParameters>;
begin
  // Check the names
  if (Length(FilterName) > MAX_UNICODE_STRING) or
    (Length(VolumeName) > MAX_UNICODE_STRING) or
    (Length(InstanceName) > MAX_UNICODE_STRING) then
  begin
    Result.Location := 'FltxOpenInstance';
    Result.Status := STATUS_NAME_TOO_LONG;
    Exit;
  end;

  IMemory(Parameters) := Auto.AllocateDynamic(SizeOf(TFltInstanceParameters) +
    StringSizeZero(FilterName) + StringSizeZero(VolumeName) +
    StringSizeZero(InstanceName));

  // Marshal the filter name
  Parameters.Data.FilterNameSize := StringSizeNoZero(FilterName);
  Parameters.Data.FilterNameOffset := SizeOf(TFltInstanceParameters);
  Move(PWideChar(FilterName)^, Parameters.Offset(
    Parameters.Data.FilterNameOffset)^, Parameters.Data.FilterNameSize);

  // Marshal the volume name
  Parameters.Data.VolumeNameSize := StringSizeNoZero(VolumeName);
  Parameters.Data.VolumeNameOffset := Parameters.Data.FilterNameOffset +
    Parameters.Data.FilterNameSize;
  Move(PWideChar(VolumeName)^, Parameters.Offset(
    Parameters.Data.VolumeNameOffset)^, Parameters.Data.VolumeNameSize);

  // Marshal the instance name
  Parameters.Data.InstanceNameSize := StringSizeNoZero(InstanceName);
  Parameters.Data.InstanceNameOffset := Parameters.Data.VolumeNameOffset +
    Parameters.Data.VolumeNameSize;
  Move(PWideChar(InstanceName)^, Parameters.Offset(
    Parameters.Data.InstanceNameOffset)^, Parameters.Data.InstanceNameSize);

  // Open and link a handle
  Result := FltxLinkHandle(hxInstance, FILTER_INSTANCE, IMemory(Parameters));
end;

function FltxQueryInstance;
const
  INITIAL_SIZE = 200;
var
  Buffer: IMemory;
begin
  case InfoClass of
    InstanceBasicInformation, InstancePartialInformation,
    InstanceFullInformation, InstanceAggregateStandardInformation:
      ; // pass through
  else
    Result.Location := 'FltxQueryInstance';
    Result.Status := STATUS_INVALID_INFO_CLASS;
    Exit;
  end;

  // Issue the IOCTL
  Result := NtxDeviceIoControlFileEx(hxInstance, FLT_CTL_GET_INFORMATION,
    Buffer, INITIAL_SIZE, nil, @InfoClass, SizeOf(InfoClass));
  Result.LastCall.UsesInfoClass(TFltCtlFunction.FLT_CTL_GET_INFORMATION,
    icPerform);

  if not Result.IsSuccess then
    Exit;

  // Parse the result
  Info := FltxCaptureInstanceInfo(InfoClass, Buffer.Data);
end;

end.
