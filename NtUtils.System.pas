unit NtUtils.System;

interface

uses
  Ntapi.ntexapi, NtUtils.Exceptions;

// Query variable-size system information
function NtxQuerySystem(InfoClass: TSystemInformationClass; out Memory: IMemory;
  InitialSize: Cardinal = 0; GrowthMethod: TBufferGrowthMethod = nil;
  AddExtra: Boolean = False): TNtxStatus;

type
  NtxSystem = class
    // Query fixed-size information
    class function Query<T>(InfoClass: TSystemInformationClass;
      var Buffer: T): TNtxStatus; static;
  end;

implementation

function NtxQuerySystem(InfoClass: TSystemInformationClass; out Memory: IMemory;
  InitialSize: Cardinal; GrowthMethod: TBufferGrowthMethod; AddExtra: Boolean
  ): TNtxStatus;
var
  Buffer: Pointer;
  BufferSize, Required: Cardinal;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TSystemInformationClass);

  BufferSize := InitialSize;
  repeat
    Buffer := AllocMem(BufferSize);

    Required := 0;
    Result.Status := NtQuerySystemInformation(InfoClass, Buffer, BufferSize,
      @Required);

    if Assigned(GrowthMethod) then
      Required := GrowthMethod(Buffer, BufferSize, Required);

    if not Result.IsSuccess then
      FreeMem(Buffer);

  until not NtxExpandBuffer(Result, BufferSize, Required, AddExtra);

  if Result.IsSuccess then
    Memory := TAutoMemory.Capture(Buffer, BufferSize);
end;

{ NtxSystem }

class function NtxSystem.Query<T>(InfoClass: TSystemInformationClass;
  var Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.CallType := lcQuerySetCall;
  Result.LastCall.InfoClass := Cardinal(InfoClass);
  Result.LastCall.InfoClassType := TypeInfo(TSystemInformationClass);

  Result.Status := NtQuerySystemInformation(InfoClass, @Buffer, SizeOf(Buffer),
    nil);
end;

end.
