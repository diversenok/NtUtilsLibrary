unit NtUtils.Console;

{
  This module includes helper functions for low-level console support.
}

interface

uses
  Ntapi.WinNt, Ntapi.ConsoleApi, NtUtils, DelphiApi.Reflection, Ntapi.Versions;

const
  // An access mask for annotations
  PROCESS_ATTACH_CONSOLE_DIRECT = PROCESS_DUP_HANDLE or PROCESS_VM_READ or
    PROCESS_QUERY_LIMITED_INFORMATION;

type
  TRtlxConsoleOwnershipOperation = (coPreserve, coUse, coReset);

{ Helpers }
  
// Helpers for accessing PEB console handles
function RtlxConsoleConnection: IHandle;
function RtlxConsoleInput: IHandle;
function RtlxConsoleOutput: IHandle;
function RtlxConsoleError: IHandle;

// Get or open a reference handle to the console
[MinOSVersion(OsWin8)]
function RtlxGetConsoleReference(
  out hxReference: IHandle
): TNtxStatus;
  
{ Win32 function }
  
// Create a new console
function AdvxAllocConsole: TNtxStatus;

// Attach to an existing console
function AdvxAttachConsole(
  ProcessId: TProcessId
): TNtxStatus;

// Release the current console
function AdvxFreeConsole: TNtxStatus;

// Enumerate processes that are using the current console
function AdvxEnumerateConsoleProcesses(
  out ProcessIDs: TArray<TProcessId32>
): TNtxStatus;
  
{ Native functions }
  
// Query the process ID of the associated console host
[MinOSVersion(OsWin8)]
function RtlxQueryConhostPid(
  out ProcessId: TProcessId;
  const hxConnection: IHandle = nil
): TNtxStatus;

// Prepare parameters for creating a console
[MinOSVersion(OsWin8)]
function RtlxPrepareConsoleLaunchData(
  const ConsoleTitle: String;
  InheritFromPeb: Boolean = True
): TConsoleServerMsg;

// Create a new console
[MinOSVersion(OsWin8)]
function RtlxLaunchConsoleServer(
  const LaunchParameters: TConsoleServerMsg;
  out hxConnect: IHandle
): TNtxStatus;

// Attach to an existing console
[MinOSVersion(OsWin8)]
function RtlxAttachConsoleById(
  ProcessId: TProcessId;
  out hxConnect: IHandle
): TNtxStatus;

// Attach to an existing console by duplicating its connection handle
function RtlxAttachConsoleDirect(
  [Access(PROCESS_ATTACH_CONSOLE_DIRECT)] const hxProcess: IHandle;
  out hxConnect: IHandle
): TNtxStatus;

// Allows the console to terminate the current process
[MinOSVersion(OsWin8)]
function RtlxSelectConsoleAsOwner(
  [opt] const hxConnect: IHandle
): TNtxStatus;

// Create an console connection handle from an already launched console reference
[MinOSVersion(OsWin8)]
function RtlxDeriveConsoleConnect(
  const hxReference: IHandle;
  out hxConnect: IHandle
): TNtxStatus;

// Create an console reference handle from a connection
[MinOSVersion(OsWin8)]
function RtlxDeriveConsoleReference(
  const hxConnect: IHandle;
  out hxReference: IHandle
): TNtxStatus;

// Create an console input handle from a connection
[MinOSVersion(OsWin8)]
function RtlxDeriveConsoleInput(
  const hxConnect: IHandle;
  out hxInput: IHandle
): TNtxStatus;

// Create an console output handle from a connection
[MinOSVersion(OsWin8)]
function RtlxDeriveConsoleOutput(
  const hxConnect: IHandle;
  out hxOutput: IHandle
): TNtxStatus;

// Create I/O handles from a connection and set them as the current console
[MinOSVersion(OsWin8)]
function RtlxSelectDeriveConsole(
  [opt] const hxConnect: IHandle;
  Ownership: TRtlxConsoleOwnershipOperation = coUse
): TNtxStatus;

// Set console handles as the current
procedure RtlxSelectConsole(
  [opt] const hxConnect: IHandle;
  [opt] const hxInput: IHandle;
  [opt] const hxOutput: IHandle;
  [opt] const hxError: IHandle
);

implementation

uses
  Ntapi.ntpebteb, Ntapi.ntstatus, Ntapi.ntrtl, Ntapi.ntwow64, Ntapi.ntpsapi,
  Ntapi.ProcessThreadsApi, Ntapi.WinUser, NtUtils.Ldr, NtUtils.Files,
  NtUtils.Files.Open, NtUtils.Files.Control, NtUtils.Processes.Info,
  NtUtils.Processes.Create, NtUtils.Processes.Create.Native, NtUtils.Objects,
  NtUtils.Memory;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Helpers }
  
function RtlxConsoleConnection;
begin
  Result := Auto.RefHandle(RtlGetCurrentPeb.ProcessParameters.ConsoleHandle);
end;

function RtlxConsoleInput;
begin
  Result := Auto.RefHandle(RtlGetCurrentPeb.ProcessParameters.StandardInput);
end;

function RtlxConsoleOutput;
begin
  Result := Auto.RefHandle(RtlGetCurrentPeb.ProcessParameters.StandardOutput);
end;

function RtlxConsoleError;
begin
  Result := Auto.RefHandle(RtlGetCurrentPeb.ProcessParameters.StandardError);
end;

var
  // Cache for manual console creation handles, see RtlxSelectConsole below
  hxCurrentConnect, hxCurrentInput, hxCurrentOutput, hxCurrentError: IHandle;

function RtlxGetConsoleReference;
var
  hConnection: THandle;
begin
  // RS3+ exposes the handle and makes things easy. Although, only if the
  // console was created by kernelbase and not our custom code.
  if not Assigned(hxCurrentConnect) and 
    LdrxCheckDelayedImport(delayed_BaseGetConsoleReference).IsSuccess then
  begin
    hxReference := Auto.RefHandle(BaseGetConsoleReference);
    Result := NtxSuccess;
    Exit;
  end;

  // On earlier versions, we only have the connection handle from PEB
  hConnection := RtlGetCurrentPeb.ProcessParameters.ConsoleHandle;

  if (hConnection = 0) or (hConnection > MAX_HANDLE) then
  begin
    // No console
    hxReference := Auto.RefHandle(0);
    Result := NtxSuccess;
    Exit;
  end;

  // Open a new reference from the connection
  Result := NtxOpenFile(hxReference, FileParameters
    .UseFileName(CD_REFERENCE_NAME)
    .UseRoot(Auto.RefHandle(hConnection))
    .UseAccess(GENERIC_READ or GENERIC_WRITE)
  );
end;

{ Win32 }

function AdvxAllocConsole;
begin
  Result.Location := 'AllocConsole';
  Result.Win32Result := AllocConsole;
end;

function AdvxAttachConsole;
begin
  Result.Location := 'AttachConsole';
  Result.Win32Result := AttachConsole(TProcessId32(ProcessId));
end;

function AdvxFreeConsole;
begin
  Result.Location := 'FreeConsole';
  Result.Win32Result := FreeConsole;
end;

function AdvxEnumerateConsoleProcesses;
var
  Required: Integer;
begin
  Result.Location := 'GetConsoleProcessList';

  SetLength(ProcessIDs, 1);
  repeat
    Required := GetConsoleProcessList(@ProcessIDs[0], Length(ProcessIDs));
    Result.Win32Result := Required <> 0;

    if not Result.IsSuccess then
      Exit;

    if Required > Length(ProcessIDs) then
      SetLength(ProcessIDs, Required)
    else
      Break;
  until False;

  // Trim if necessary
  if Length(ProcessIDs) > Required then
    SetLength(ProcessIDs, Required);
end;

{ Native }

function RtlxQueryConhostPid;
var
  hConsole: THandle;
begin
  if Assigned(hxConnection) then
    hConsole := hxConnection.Handle
  else
    hConsole := RtlGetCurrentPeb.ProcessParameters.ConsoleHandle;

  if hConsole = 0 then
  begin
    Result.Location := 'RtlxQueryConhostPid';
    Result.Status := STATUS_NOT_SUPPORTED;
    Exit;
  end;

  Result := NtxFileControl.IoControlOut(Auto.RefHandle(hConsole),
    IOCTL_CONDRV_GET_SERVER_PID, ProcessId);
end;

procedure MarshalConsoleString(
  [in, ReadsFrom] Source: PWideChar;
  [in, NumberOfBytes] SourceSize: NativeUInt;
  [out, WritesTo] Destination: Pointer;
  [in, NumberOfBytes] DestinationSize: Word;
  [out, NumberOfBytes] out WrittenSize: Word
);
begin
  if SourceSize > DestinationSize then
    WrittenSize := DestinationSize
  else
    WrittenSize := Word(SourceSize);

  Move(Source^, Destination^, SourceSize);
end;

function RtlxPrepareConsoleLaunchData;
var
  ProcessParameters: PRtlUserProcessParameters;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.WindowVisible := True;

  MarshalConsoleString(PWideChar(ConsoleTitle), StringSizeNoZero(ConsoleTitle),
    @Result.Title, SizeOf(Result.Title), Result.TitleLength);

  if InheritFromPeb then
  begin
    ProcessParameters := RtlGetCurrentPeb.ProcessParameters;
    Result.StartupFlags := ProcessParameters.WindowFlags;

    if BitTest(ProcessParameters.WindowFlags and STARTF_USEFILLATTRIBUTE) then
      Result.FillAttribute := Word(ProcessParameters.FillAttribute);

    if BitTest(ProcessParameters.WindowFlags and STARTF_USESHOWWINDOW) then
      Result.ShowWindow := TShowMode16(ProcessParameters.ShowWindowFlags);

    if BitTest(ProcessParameters.WindowFlags and STARTF_USECOUNTCHARS) then
    begin
      Result.ScreenBufferSize.X := Int16(ProcessParameters.CountCharsX);
      Result.ScreenBufferSize.Y := Int16(ProcessParameters.CountCharsY);
    end;

    if BitTest(ProcessParameters.WindowFlags and STARTF_USESIZE) then
    begin
      Result.WindowSize.X := Int16(ProcessParameters.CountX);
      Result.WindowSize.Y := Int16(ProcessParameters.CountY);
    end;

    if BitTest(ProcessParameters.WindowFlags and STARTF_USEPOSITION) then
    begin
      Result.WindowOrigin.X := Int16(ProcessParameters.StartingX);
      Result.WindowOrigin.Y := Int16(ProcessParameters.StartingY);
    end;

    if RtlOsVersionAtLeast(OsWin8) then
      Result.ProcessGroupId := ProcessParameters.ProcessGroupID;

    if Result.ProcessGroupId = 0 then
      Result.ProcessGroupId := Cardinal(NtCurrentTeb.ClientID.UniqueProcess);

    Result.WindowVisible := ProcessParameters.ConsoleHandle <> THandle(-3);

    MarshalConsoleString(ProcessParameters.ImagePathName.Buffer,
      ProcessParameters.ImagePathName.Length, @Result.ApplicationName,
      SizeOf(Result.ApplicationName), Result.ApplicationNameLength);

    MarshalConsoleString(ProcessParameters.CurrentDirectory.DosPath.Buffer,
      ProcessParameters.CurrentDirectory.DosPath.Length,
      @Result.CurrentDirectory, SizeOf(Result.CurrentDirectory),
      Result.CurrentDirectoryLength);
  end;
end;

function RtlxLaunchConsoleServer;
var
  Options: TCreateProcessOptions;
  ProcessParameters: IRtlUserProcessParameters;
  hxServer, hxReference: IHandle;
begin
  Options := Default(TCreateProcessOptions);
  Options.Application := CD_SERVER_LAUNCH_APPLICATION;
  Options.Parameters := CD_SERVER_LAUNCH_ARGUMENTS;

  // Allocate process parameters for the conhost process
  Result := RtlxCreateProcessParameters(Options, ProcessParameters);

  if not Result.IsSuccess then
    Exit;

  // Create a ConDrv server handle
  Result := NtxCreateFile(hxServer, FileParameters
    .UseFileName(CD_DEVICE_PATH + CD_SERVER_NAME)
    .UseSyncMode(fsAsynchronous)
    .UseAccess(GENERIC_ALL)
  );

  if not Result.IsSuccess then
    Exit;

  // Start conhost
  Result := NtxDeviceIoControlFile(hxServer, IOCTL_CONDRV_LAUNCH_SERVER,
    ProcessParameters.Data, ProcessParameters.Size);

  if not Result.IsSuccess then
    Exit;

  // Create a reference handle
  Result := NtxCreateFile(hxReference, FileParameters
    .UseFileName(CD_REFERENCE_NAME)
    .UseRoot(hxServer)
    .UseAccess(GENERIC_READ or GENERIC_WRITE)
  );

  if not Result.IsSuccess then
    Exit;

  // Connect to conhost and make it create the console window
  Result := NtxCreateFile(hxConnect, FileParameters
    .UseFileName(CD_CONNECT_NAME)
    .UseRoot(hxReference)
    .UseEAs(RtlxAllocateEA(CD_SERVER_EA_NAME,
      Auto.RefBuffer(LaunchParameters)))
    .UseAccess(GENERIC_READ or GENERIC_WRITE)
  );
end;

function RtlxAttachConsoleById;
begin
  Result := NtxCreateFile(hxConnect, FileParameters
    .UseFileName(CD_DEVICE_PATH + CD_CONNECT_NAME)
    .UseEAs(RtlxAllocateEA(CD_ATTACH_EA_NAME, Auto.RefBuffer(ProcessId)))
    .UseAccess(GENERIC_READ or GENERIC_WRITE)
  );
end;

function RtlxAttachConsoleDirect;
var
  BasicInfo: TProcessBasicInformation;
  Wow64Peb: PPeb32;
  RemoteParameters32: Wow64Pointer<PRtlUserProcessParameters32>;
  ConsoleHandle32: Wow64Handle;
  RemoteParameters: PRtlUserProcessParameters;
  ConsoleHandle: THandle;
  hxConnectionCopy, hxReference: IHandle;
begin
  // Determine target's bitness and prevent WoW64 -> Native access
  Result := RtlxAssertWoW64CompatiblePeb(hxProcess, Wow64Peb);

  if not Result.IsSuccess then
    Exit;

  if Assigned(Wow64Peb) then
  begin
    // Read the WoW64 process parameters base
    Result := NtxMemory.Read(hxProcess, @Wow64Peb.ProcessParameters,
      RemoteParameters32);

    if not Result.IsSuccess then
      Exit;

    // Read the console handle value
    Result := NtxMemory.Read(hxProcess, @RemoteParameters32.Self.ConsoleHandle,
     ConsoleHandle32);

    if not Result.IsSuccess then
      Exit;

    ConsoleHandle := ConsoleHandle32;
  end
  else
  begin
    // Locate the native PEB
    Result := NtxProcess.Query(hxProcess, ProcessBasicInformation, BasicInfo);

    if not Result.IsSuccess then
      Exit;

    // Read the process parameters base
    Result := NtxMemory.Read(hxProcess,
      @BasicInfo.PebBaseAddress.ProcessParameters, RemoteParameters);

    if not Result.IsSuccess then
      Exit;

    // Read the console handle value
    Result := NtxMemory.Read(hxProcess, @RemoteParameters.ConsoleHandle,
     ConsoleHandle);

    if not Result.IsSuccess then
      Exit;
  end;

  if (ConsoleHandle = 0) or (ConsoleHandle > MAX_HANDLE) then
  begin
    Result.Location := 'RtlxAttachConsoleViaDuplication';
    Result.Status := STATUS_NOT_FOUND;
    Exit;
  end;

  // Duplicate the connection handle. Note that the handle is still tied to
  // another process, so we cannot use it directly.
  Result := NtxDuplicateHandleFrom(hxProcess, ConsoleHandle, hxConnectionCopy);

  if not Result.IsSuccess then
    Exit;

  // We can, however, convert it to a reference
  Result := RtlxDeriveConsoleReference(hxConnectionCopy, hxReference);

  if not Result.IsSuccess then
    Exit;

  // And then convert back to a connection, this time, relative to our process
  Result := RtlxDeriveConsoleConnect(hxReference, hxConnect);
end;

function RtlxSelectConsoleAsOwner;
var
  ConhostPID: TProcessId;
begin
  // Determine the connected conhost PID
  if Assigned(hxConnect) then
  begin
    Result := RtlxQueryConhostPid(ConhostPID, hxConnect);

    if not Result.IsSuccess then
      Exit;
  end
  else
    ConhostPID := 0;

  // Adjust the lower bits to indicate console rather than creator ownership
  ConhostPID := (ConhostPID and not 3) or 1;

  // Set it the current process owner
  Result := NtxProcess.Set(NtxCurrentProcess, ProcessConsoleHostProcess,
    ConhostPID);
end;

function RtlxDeriveConsoleConnect;
begin
  Result := NtxCreateFile(hxConnect, FileParameters
    .UseFileName(CD_CONNECT_NAME)
    .UseRoot(hxReference)
    .UseAccess(GENERIC_READ or GENERIC_WRITE)
  );
end;

function RtlxDeriveConsoleReference;
begin
  Result := NtxOpenFile(hxReference, FileParameters
    .UseFileName(CD_REFERENCE_NAME)
    .UseRoot(hxConnect)
    .UseAccess(GENERIC_READ or GENERIC_WRITE)
  );
end;

function RtlxDeriveConsoleInput;
begin
  Result := NtxCreateFile(hxInput, FileParameters
    .UseFileName(CD_INPUT_NAME)
    .UseRoot(hxConnect)
    .UseAccess(GENERIC_READ or GENERIC_WRITE)
  );
end;

function RtlxDeriveConsoleOutput;
begin
  Result := NtxCreateFile(hxOutput, FileParameters
    .UseFileName(CD_OUTPUT_NAME)
    .UseRoot(hxConnect)
    .UseAccess(GENERIC_READ or GENERIC_WRITE)
  );
end;

function RtlxSelectDeriveConsole;
var
  hxInput, hxOutput: IHandle;
begin
  if not Assigned(hxConnect) then
  begin
    RtlxSelectConsole(nil, nil, nil, nil);

    // Reset process ownership, if necassary, but don't fail on error
    if Ownership in [coUse, coReset] then
      RtlxSelectConsoleAsOwner(nil);
    
    Result := NtxSuccess;
    Exit;
  end;

  // Make standard input
  Result := RtlxDeriveConsoleInput(hxConnect, hxInput);

  if not Result.IsSuccess then
    Exit;

  // Make standard output & error
  Result := RtlxDeriveConsoleOutput(hxConnect, hxOutput);

  if not Result.IsSuccess then
    Exit;

  // Adjust process ownership, if necessary
  case Ownership of
    coUse:   Result := RtlxSelectConsoleAsOwner(hxConnect);
    coReset: Result := RtlxSelectConsoleAsOwner(nil);
  end;

  if not Result.IsSuccess then
    Exit;
    
  RtlxSelectConsole(hxConnect, hxInput, hxOutput, hxOutput);
end;

procedure RtlxSelectConsole;
var
  ProcessParameters: PRtlUserProcessParameters;
begin
  ProcessParameters := RtlGetCurrentPeb.ProcessParameters;
  ProcessParameters.ConsoleHandle := HandleOrDefault(hxConnect);
  ProcessParameters.StandardInput := HandleOrDefault(hxInput);
  ProcessParameters.StandardOutput := HandleOrDefault(hxOutput);
  ProcessParameters.StandardError := HandleOrDefault(hxError);
  hxCurrentConnect := hxConnect;
  hxCurrentInput := hxInput;
  hxCurrentOutput := hxOutput;
  hxCurrentError := hxError;
end;

end.
