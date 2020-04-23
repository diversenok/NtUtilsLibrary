unit NtUtils.System;

interface

uses
  Ntapi.ntexapi, NtUtils;

// Query variable-size system information
function NtxQuerySystem(InfoClass: TSystemInformationClass; out xMemory:
  IMemory; InitialBuffer: Cardinal = 0; GrowthMethod: TBufferGrowthMethod = nil)
  : TNtxStatus;

type
  NtxSystem = class
    // Query fixed-size information
    class function Query<T>(InfoClass: TSystemInformationClass;
      var Buffer: T): TNtxStatus; static;
  end;

implementation

function NtxQuerySystem(InfoClass: TSystemInformationClass; out xMemory:
  IMemory; InitialBuffer: Cardinal; GrowthMethod: TBufferGrowthMethod)
  : TNtxStatus;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.AttachInfoClass(InfoClass);

  xMemory := TAutoMemory.Allocate(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQuerySystemInformation(InfoClass, xMemory.Data,
      xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

{ NtxSystem }

class function NtxSystem.Query<T>(InfoClass: TSystemInformationClass;
  var Buffer: T): TNtxStatus;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.AttachInfoClass(InfoClass);

  Result.Status := NtQuerySystemInformation(InfoClass, @Buffer, SizeOf(Buffer),
    nil);
end;

end.
