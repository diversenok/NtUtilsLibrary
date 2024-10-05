unit NtUtils.Processes.Create.Csr;

{
  This module provides support for asking CSR to create processes on our behalf.
}

interface

uses
  NtUtils, NtUtils.Processes.Create;

// Connect to SbApiPort and ask CSRSS to create a process
[SupportedOption(spoCurrentDirectory)]
[SupportedOption(spoSessionId)]
function CsrxCreateProcess(
  const Options: TCreateProcessOptions;
  out Info: TProcessInfo
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntsmss, Ntapi.ntlpcapi, Ntapi.ntpebteb,
  NtUtils.Lpc, NtUtils.Files, NtUtils.SysUtils, NtUtils.Objects, NtUtils.Threads;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function CsrxCreateProcess;
var
  hxPort: IHandle;
  SessionId: TSessionId;
  PortName, ImageFileName, CommandLine, CurrentDirectory: String;
  ImageFileNameStr, CommandLineStr, CurrentDirectoryStr: TNtUnicodeString;
  Msg: TSbApiMsg;
begin
  // Prepare the image name
  ImageFileName := Options.ApplicationNative;
  Result := RtlxInitUnicodeString(ImageFileNameStr, ImageFileName);

  if not Result.IsSuccess then
    Exit;

  // Prepare the command line
  CommandLine := Options.CommandLine;
  Result := RtlxInitUnicodeString(CommandLineStr, CommandLine);

  if not Result.IsSuccess then
    Exit;

  // Prepare the current directory
  if Options.CurrentDirectory <> '' then
    CurrentDirectory := Options.CurrentDirectory
  else
    CurrentDirectory := RtlxGetCurrentDirectory;

  if CurrentDirectory = '' then
    CurrentDirectory := USER_SHARED_DATA.NtSystemRoot;

  Result := RtlxInitUnicodeString(CurrentDirectoryStr, CurrentDirectory);

  if not Result.IsSuccess then
    Exit;

  // Prepare the message
  Msg := Default(TSbApiMsg);
  Msg.h.u1.TotalLength := SizeOf(TSbApiMsg);
  Msg.h.u1.DataLength := SizeOf(TSbApiMsg) - SizeOf(TPortMessage);
  Msg.ApiNumber := SbCreateProcessApi;
  Msg.CreateProcessA.i.ImageFileName := @ImageFileNameStr;
  Msg.CreateProcessA.i.CommandLine := @CommandLineStr;
  Msg.CreateProcessA.i.CurrentDirectory := @CurrentDirectoryStr;
  Msg.CreateProcessA.i.Flags := SMP_DONT_START or SMP_ASYNC_FLAG;

  // Choose which CSRSS to connect to
  if poUseSessionId in Options.Flags then
    SessionId := Options.SessionId
  else
    SessionId := RtlGetCurrentPeb.SessionID;

  if SessionId <> 0 then
    PortName := RtlxFormatString('\Sessions\%d\Windows\SbApiPort', [SessionId])
  else
    PortName := '\Windows\SbApiPort';

  // Open the connection
  Result := NtxConnectPort(hxPort, PortName);

  if not Result.IsSuccess then
    Exit;

  // Send the request and wait
  Result := NtxRequestWaitReplyPort(hxPort, Msg.h);

  if not Result.IsSuccess then
    Exit;

  // Forward the operation status
  Result.Location := 'SbApiPort::SbCreateProcessApi';
  Result.Status := Msg.ReturnedStatus;

  if not Result.IsSuccess then
    Exit;

  // Capture available information
  Info.ValidFields := [piProcessID, piThreadID];
  Info.ClientId := Msg.CreateProcessA.o.ClientId;
  Info.ImageInformation.SubSystemType := Msg.CreateProcessA.o.SubSystemType;

  if Msg.CreateProcessA.o.Process <> 0 then
  begin
    Include(Info.ValidFields, piProcessHandle);
    Info.hxProcess := Auto.CaptureHandle(Msg.CreateProcessA.o.Process);
  end;

  if Msg.CreateProcessA.o.Thread <> 0 then
  begin
    Include(Info.ValidFields, piThreadHandle);
    Info.hxThread := Auto.CaptureHandle(Msg.CreateProcessA.o.Thread);

    // Resume if necessary
    if not (poSuspended in Options.Flags) then
      NtxResumeThread(Info.hxThread);
  end;
end;

end.
