unit NtUtils.Files.Mup;

{
  This module provides support for querying Multiple UNC Provider information.
}

interface

uses
  Ntapi.ntioapi.fsctl, NtUtils, DelphiApi.Reflection;

type
  TMupxUncProviderEntry = record
    ReferenceCount: Integer;
    ProviderPriority: Cardinal;
    ProviderState: Cardinal;
    ProviderId: Cardinal;
    ProviderName: String;
  end;

  TMupxSurrogateProviderEntry = record
    ReferenceCount: Integer;
    SurrogateType: Cardinal;
    SurrogateState: Cardinal;
    SurrogatePriority: Cardinal;
    SurrogateName: String;
  end;

  TMupxUncCacheEntry = record
    UncName: String;
    ProviderName: String;
    SurrogateName: String;
    [Hex] Flags: Word;
    ProviderPriority: Cardinal;
    EntryTtl: Cardinal;
  end;

  TMupxUncCacheInfo = record
    MaxCacheSize: Cardinal;
    CurrentCacheSize: Cardinal;
    EntryTimeout: Cardinal;
    CacheEntries: TArray<TMupxUncCacheEntry>;
  end;

  TMupxHardeningPrefixTableEntry = record
    PrefixName: String;
    RequiredHardeningCapabilities: TMupHardeningCapabilities;
    OpenCount: UInt64;
  end;

// Enumerate registered UNC providers
function NtxEnumerateUncProviders(
  out Providers: TArray<TMupxUncProviderEntry>;
  [opt] hxMupDevice: IHandle = nil
): TNtxStatus;

// Enumerate registered surrogate providers
function NtxEnumerateSurrogateProviders(
  out Providers: TArray<TMupxSurrogateProviderEntry>;
  [opt] hxMupDevice: IHandle = nil
): TNtxStatus;

// Collect information about UNC cache
function NtxEnumerateUncCache(
  out CacheInfo: TMupxUncCacheInfo;
  [opt] hxMupDevice: IHandle = nil
): TNtxStatus;

// Enumerate UNC hardening configuration
function NtxEnumerateHardeningConfiguration(
  out PrefixTable: TArray<TMupxHardeningPrefixTableEntry>;
  [opt] hxMupDevice: IHandle = nil
): TNtxStatus;

// Enumerate UNC hardening configuration for a path
function NtxQueryHardeningConfigurationForPath(
  const UncPath: String;
  out RequiredHardeningCapabilities: TMupHardeningCapabilities;
  [opt] hxMupDevice: IHandle = nil
): TNtxStatus;

implementation

uses
  Ntapi.ntioapi, NtUtils.Files.Open, NtUtils.Files.Control,
  DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxEnsureMupDeviceOpened(
  var hxMupDevice: IHandle;
  Access: TFileAccessMask = 0
): TNtxStatus;
begin
  if not Assigned(hxMupDevice) then
    Result := NtxOpenFile(hxMupDevice, FileParameters
      .UseFileName('\Device\Mup').UseAccess(Access))
  else
    Result := NtxSuccess
end;

function NtxEnumerateUncProviders;
var
  Buffer: IMemory<PMupFsctlUncProviderInformation>;
  Cursor: PMupFsctlUncProviderEntry;
  i: Integer;
begin
  Result := NtxEnsureMupDeviceOpened(hxMupDevice);

  if not Result.IsSuccess then
    Exit;

  // Collect UNC providers
  Result := NtxFsControlFileEx(hxMupDevice, FSCTL_MUP_GET_UNC_PROVIDER_LIST,
    IMemory(Buffer), SizeOf(TMupFsctlUncProviderInformation));

  if not Result.IsSuccess then
    Exit;

  // Save them
  SetLength(Providers, Buffer.Data.TotalEntries);
  Cursor := Pointer(@Buffer.Data.ProviderEntry);

  for i := 0 to High(Providers) do
  begin
    Providers[i].ReferenceCount := Cursor.ReferenceCount;
    Providers[i].ProviderPriority := Cursor.ProviderPriority;
    Providers[i].ProviderState := Cursor.ProviderState;
    Providers[i].ProviderId := Cursor.ProviderId;
    SetString(Providers[i].ProviderName, PWideChar(@Cursor.ProviderName),
      Cursor.ProviderNameLength div SizeOf(WideChar));
    Inc(PByte(Cursor), Cursor.TotalLength);
  end;
end;

function NtxEnumerateSurrogateProviders;
var
  Buffer: IMemory<PMupFsctlSurrogateProviderInformation>;
  Cursor: PMupFsctlSurrogateProviderEntry;
  i: Integer;
begin
  Result := NtxEnsureMupDeviceOpened(hxMupDevice);

  if not Result.IsSuccess then
    Exit;

  // Collect UNC surrogates
  Result := NtxFsControlFileEx(hxMupDevice,
    FSCTL_MUP_GET_SURROGATE_PROVIDER_LIST, IMemory(Buffer),
    SizeOf(TMupFsctlSurrogateProviderInformation));

  if not Result.IsSuccess then
    Exit;

  // Save them
  SetLength(Providers, Buffer.Data.TotalEntries);
  Cursor := Pointer(@Buffer.Data.SurrogateEntry);

  for i := 0 to High(Providers) do
  begin
    Providers[i].ReferenceCount := Cursor.ReferenceCount;
    Providers[i].SurrogateType := Cursor.SurrogateType;
    Providers[i].SurrogateState := Cursor.SurrogateState;
    Providers[i].SurrogatePriority := Cursor.SurrogatePriority;
    SetString(Providers[i].SurrogateName, PWideChar(@Cursor.SurrogateName),
      Cursor.SurrogateNameLength div SizeOf(WideChar));
    Inc(PByte(Cursor), Cursor.TotalLength);
  end;
end;

function NtxEnumerateUncCache;
var
  Buffer: IMemory<PMupFsctlUncCacheInformation>;
  Cursor: PMupFsctlUncCacheEntry;
  i: Integer;
begin
  Result := NtxEnsureMupDeviceOpened(hxMupDevice);

  if not Result.IsSuccess then
    Exit;

  // Collect UNC cache info
  Result := NtxFsControlFileEx(hxMupDevice, FSCTL_MUP_GET_UNC_CACHE_INFO,
    IMemory(Buffer), SizeOf(TMupFsctlUncCacheInformation));

  if not Result.IsSuccess then
    Exit;

  CacheInfo.MaxCacheSize := Buffer.Data.MaxCacheSize;
  CacheInfo.CurrentCacheSize := Buffer.Data.CurrentCacheSize;
  CacheInfo.EntryTimeout := Buffer.Data.EntryTimeout;
  CacheInfo.MaxCacheSize := Buffer.Data.MaxCacheSize;

  // Save cache entries
  SetLength(CacheInfo.CacheEntries, Buffer.Data.TotalEntries);
  Cursor := Pointer(@Buffer.Data.CacheEntry);

  for i := 0 to High(CacheInfo.CacheEntries) do
  begin
    CacheInfo.CacheEntries[i].Flags := Cursor.Flags;
    CacheInfo.CacheEntries[i].ProviderPriority := Cursor.ProviderPriority;
    CacheInfo.CacheEntries[i].EntryTtl := Cursor.EntryTtl;

    SetString(CacheInfo.CacheEntries[i].UncName, PWideChar(PByte(@Cursor.Strings) +
      Cursor.UncNameOffset), Cursor.UncNameLength div SizeOf(WideChar));

    SetString(CacheInfo.CacheEntries[i].ProviderName, PWideChar(
      PByte(@Cursor.Strings) + Cursor.ProviderNameOffset),
      Cursor.ProviderNameLength div SizeOf(WideChar));

    SetString(CacheInfo.CacheEntries[i].SurrogateName, PWideChar(
      PByte(@Cursor.Strings) + Cursor.SurrogateNameOffset),
      Cursor.SurrogateNameLength div SizeOf(WideChar));

    Inc(PByte(Cursor), Cursor.TotalLength);
  end;
end;

function NtxEnumerateHardeningConfiguration;
var
  Buffer: IMemory<PMupFsctlUncHardeningPrefixTableEntry>;
  Cursor: PMupFsctlUncHardeningPrefixTableEntry;
  Count: Integer;
begin
  Result := NtxEnsureMupDeviceOpened(hxMupDevice);

  if not Result.IsSuccess then
    Exit;

  // Collect prefix table entries
  Result := NtxFsControlFileEx(hxMupDevice,
    FSCTL_MUP_GET_UNC_HARDENING_CONFIGURATION, IMemory(Buffer),
    SizeOf(TMupFsctlUncHardeningPrefixTableEntry));

  if not Result.IsSuccess then
    Exit;

  // Count them
  Cursor := Buffer.Data;
  Count := 0;

  while Cursor.PrefixNameOffset <> 0 do
  begin
    Inc(Count);

    if Cursor.NextOffset <> 0 then
      Inc(PByte(Cursor), Cursor.NextOffset)
    else
      Break;
  end;

  // Save them
  SetLength(PrefixTable, Count);
  Cursor := Buffer.Data;
  Count := 0;

  while Cursor.PrefixNameOffset <> 0 do
  begin
    PrefixTable[Count].RequiredHardeningCapabilities :=
      Cursor.RequiredHardeningCapabilities;
    PrefixTable[Count].OpenCount := Cursor.OpenCount;

    SetString(PrefixTable[Count].PrefixName, PWideChar(PByte(Cursor) +
      Cursor.PrefixNameOffset), Cursor.PrefixNameCbLength div SizeOf(WideChar));

    Inc(Count);

    if Cursor.NextOffset <> 0 then
      Inc(PByte(Cursor), Cursor.NextOffset)
    else
      Break;
  end;
end;

function NtxQueryHardeningConfigurationForPath;
var
  InputBuffer: IMemory<PMupFsctlQueryUncHardeningConfigurationIn>;
  OutputBuffer: IMemory<PMupFsctlQueryUncHardeningConfigurationOut>;
begin
  Result := NtxEnsureMupDeviceOpened(hxMupDevice);

  if not Result.IsSuccess then
    Exit;

  // Prepare the input buffer with the path
  IMemory(InputBuffer) := Auto.AllocateDynamic(StringSizeZero(UncPath) +
    SizeOf(TMupFsctlQueryUncHardeningConfigurationIn));

  InputBuffer.Data.Size := InputBuffer.Size;
  InputBuffer.Data.UncPathOffset :=
    SizeOf(TMupFsctlQueryUncHardeningConfigurationIn);
  InputBuffer.Data.UncPathCbLength := StringSizeNoZero(UncPath);

  Move(PWideChar(UncPath)^, InputBuffer.Offset(InputBuffer.Data.UncPathOffset)^,
    InputBuffer.Data.UncPathCbLength);

  // Query the hardening configuration
  Result := NtxFsControlFileEx(hxMupDevice,
    FSCTL_MUP_GET_UNC_HARDENING_CONFIGURATION_FOR_PATH, IMemory(OutputBuffer),
    SizeOf(TMupFsctlUncHardeningPrefixTableEntry), nil, InputBuffer.Data,
    InputBuffer.Size);

  if not Result.IsSuccess then
    Exit;

  RequiredHardeningCapabilities :=
    OutputBuffer.Data.RequiredHardeningCapabilities;
end;

end.
