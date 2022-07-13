unit NtUtils.System;

{
  The module provides support for querying information about the system.
}

interface

uses
  Ntapi.ntexapi, NtUtils, NtUtils.Ldr;

// Query variable-size system information
function NtxQuerySystem(
  InfoClass: TSystemInformationClass;
  out xMemory: IMemory;
  InitialBuffer: Cardinal = 0;
  [opt] GrowthMethod: TBufferGrowthMethod = nil
): TNtxStatus;

type
  NtxSystem = class abstract
    // Query fixed-size information
    class function Query<T>(
      InfoClass: TSystemInformationClass;
      var Buffer: T
    ): TNtxStatus; static;
  end;

// Enumerate kernel modules and drivers
function NtxEnumerateModulesSystem(
  out Modules: TArray<TModuleEntry>
): TNtxStatus;

implementation

uses
  Ntapi.ntrtl, NtUtils.Files, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxQuerySystem;
var
  Required: Cardinal;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  xMemory := Auto.AllocateDynamic(InitialBuffer);
  repeat
    Required := 0;
    Result.Status := NtQuerySystemInformation(InfoClass, xMemory.Data,
      xMemory.Size, @Required);
  until not NtxExpandBufferEx(Result, xMemory, Required, GrowthMethod);
end;

{ NtxSystem }

class function NtxSystem.Query<T>;
begin
  Result.Location := 'NtQuerySystemInformation';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  Result.Status := NtQuerySystemInformation(InfoClass, @Buffer, SizeOf(Buffer),
    nil);
end;

function NtxEnumerateModulesSystem;
var
  xMemory: IMemory<PRtlProcessModules>;
  Module: PRtlProcessModuleInformation;
  i: Integer;
begin
  Result := NtxQuerySystem(SystemModuleInformation, IMemory(xMemory),
    SizeOf(TRtlProcessModules));

  if not Result.IsSuccess then
    Exit;

  SetLength(Modules, xMemory.Data.NumberOfModules);

  for i := 0 to High(Modules) do
    with Modules[i] do
    begin
      Module := @xMemory.Data.Modules{$R-}[i]{$IFDEF R+}{$R+}{$ENDIF};
      DllBase := Module.ImageBase;
      SizeOfImage := Module.ImageSize;
      LoadCount := Module.LoadCount;
      FullDllName := String(UTF8String(PAnsiChar(@Module.FullPathName)));
      BaseDllName := String(UTF8String(PAnsiChar(@Module.FullPathName[
        Module.OffsetToFileName])));

      // Include the default drivers directory for names without a path
      if Module.OffsetToFileName = 0 then
        Insert('\SystemRoot\System32\drivers\', FullDllName, Low(String));

      // Converth paths to the Win32 format
      FullDllName := RtlxNativePathToDosPath(FullDllName);
    end;
end;

end.
