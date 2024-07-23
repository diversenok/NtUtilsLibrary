unit NtUtils.Power;

{
  This module provides support to power management-related APIs.
}

interface

uses
  Ntapi.ntpoapi, Ntapi.WinNt, NtUtils, DelphiApi.Reflection;

// Issue a power information query/set request
function NtxPowerInformation(
  InfoClass: TPowerInformationLevel;
  [in, ReadsFrom] InputBuffer: Pointer;
  [in, NumberOfBytes] InputBufferLength: Cardinal;
  [out, WritesTo] OutputBuffer: Pointer;
  [in, NumberOfBytes] OutputBufferLength: Cardinal
): TNtxStatus;

// Query the processsor power information
function NtxQueryProcessorPower(
  out Info: TArray<TProcessorPowerInformation>
): TNtxStatus;

// Create a regular/PLM power request object
function NtxCreatePowerRequest(
  out hxPowerRequest: IHandle;
  UsePLM: Boolean = False;
  [opt] const Reason: String = ''
): TNtxStatus;

// Enable/disable a power request
//  - Regular requests don't use the process handle parameter
//  - PLM requests require a process handle and an execution request type
function NtxActivatePowerRequest(
  const hxPowerRequest: IHandle;
  RequestType: TPowerRequestTypeInternal;
  [opt, Access(PROCESS_SET_LIMITED_INFORMATION)] const hxProcess: IHandle = nil;
  Enable: Boolean = True
): TNtxStatus;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

uses
  Ntapi.ntexapi, Ntapi.ntstatus, NtUtils.System, NtUtils.Objects,
  DelphiUtils.AutoObjects;

function NtxPowerInformation;
begin
  Result.Location := 'NtPowerInformation';
  Result.LastCall.UsesInfoClass(InfoClass, icPerform);
  Result.Status := NtPowerInformation(InfoClass, InputBuffer, InputBufferLength,
    OutputBuffer, OutputBufferLength);
end;

function NtxQueryProcessorPower;
var
  SystemInfo: TSystemBasicInformation;
  Buffer: IMemory<PProcessorPowerInformationArray>;
  i: Integer;
begin
  // We need to know the number of processors
  Result := NtxSystem.Query(SystemBasicInformation, SystemInfo);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(SystemInfo.NumberOfProcessors *
    SizeOf(TProcessorPowerInformation));

  // Issue the reuqest
  Result := NtxPowerInformation(ProcessorInformation, nil, 0, Buffer.Data,
    Buffer.Size);

  if not Result.IsSuccess then
    Exit;

  // Capture the result
  SetLength(Info, SystemInfo.NumberOfProcessors);

  for i := 0 to High(Info) do
    Info[i] := Buffer.Data{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
end;

function NtxCreatePowerRequest;
var
  InfoClass: TPowerInformationLevel;
  Input: TCountedReasonContext;
  hPowerRequest: THandle;
begin
  if UsePLM then
    InfoClass := PlmPowerRequestCreate
  else
    InfoClass := PowerRequestCreate;

  // Prepare the reason structure
  Input := Default(TCountedReasonContext);
  Input.Version := DIAGNOSTIC_REASON_VERSION;

  if Reason <> '' then
  begin
    Input.Flags := DIAGNOSTIC_REASON_SIMPLE_STRING;

    Result := RtlxInitUnicodeString(Input.SimpleString, Reason);

    if not Result.IsSuccess then
      Exit;
  end
  else
    Input.Flags := DIAGNOSTIC_REASON_NOT_SPECIFIED;

  // Issue the request
  Result := NtxPowerInformation(InfoClass, @Input, SizeOf(Input),
    @hPowerRequest, SizeOf(hPowerRequest));

  if Result.IsSuccess then
    hxPowerRequest := Auto.CaptureHandle(hPowerRequest);
end;

function NtxActivatePowerRequest;
var
  Input: TPowerRequestAction;
begin
  Input := Default(TPowerRequestAction);
  Input.PowerRequestHandle := HandleOrDefault(hxPowerRequest);
  Input.RequestType := RequestType;
  Input.SetAction := Enable;
  Input.ProcessHandle := HandleOrDefault(hxProcess);

  Result := NtxPowerInformation(PowerRequestAction, @Input, SizeOf(Input),
    nil, 0);
end;

end.
