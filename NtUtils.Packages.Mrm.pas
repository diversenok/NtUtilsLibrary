unit NtUtils.Packages.Mrm;

{
  This module provides support for interacting with Package Resource Index (PRI)
  files and resolving ms-resource: strings.
}

interface

uses
  Ntapi.appmodel.mrm, Ntapi.Versions, Ntapi.ObjBase, NtUtils,
  DelphiApi.Reflection;

type
  [NamingStyle(nsCamelCase, 'rk')]
  TPkgxMrmReferenceKind = (
    rkInvalid,
    rkFullyQualifiedResource, // @{PackageFullName?ms-resource://ResourcePath}
    rkRelativeResource        // ms-resource:ResourceName in a PackageFamily
  );

// Determine the location of a merged PRI file
[RequiresCom]
[MinOSVersion(OsWin8)]
function PkgxMrmGetMergedPri(
  const MainPriPath: String;
  out MergedPriPath: String
): TNtxStatus;

// Get a resource map for a package
[RequiresCom]
[MinOSVersion(OsWin8)]
function PkgxMrmGetPackageResourceMap(
  const PackageFullName: String;
  out ResourceMap: IResourceMap
): TNtxStatus;

// Get a resource map for a PRI file
[RequiresCom]
[MinOSVersion(OsWin8)]
function PkgxMrmGetFileResourceMap(
  const PriFilePath: String;
  out ResourceMap: IResourceMap
): TNtxStatus;

// Resolve a string resource in a resource map
[RequiresCom]
[MinOSVersion(OsWin8)]
function PkgxMrmResolveStringInResourceMap(
  const ResourceMap: IResourceMap;
  const Reference: String;
  out Value: String
): TNtxStatus;

// Determine the type of a resource reference
function PkgxMrmClassifyReference(
  const Reference: String;
  [out, opt] FullDelimiter: PInteger = nil
): TPkgxMrmReferenceKind;

// Resolve a resource reference string
[RequiresCom]
[MinOSVersion(OsWin8)]
function PkgxMrmResolveString(
  out Value: String;
  const Reference: String;
  [opt] const FamilyName: String = ''
): TNtxStatus;

// Resolve a resource reference string in-place
[RequiresCom]
[MinOSVersion(OsWin8)]
function PkgxMrmResolveStringVar(
  var Reference: String;
  [opt] const FamilyName: String = ''
): TNtxStatus;

implementation

uses
  Ntapi.appmodel, Ntapi.ntstatus, NtUtils.Ldr, NtUtils.Com, NtUtils.SysUtils,
  NtUtils.Packages, NtUtils.Packages.SRCache, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function PkgxMrmQueueGetString(
  out Value: String;
  const Reference: String
): TNtxStatus;
const
  INITIAL_SIZE = SizeOf(WideChar) * 200;
var
  Buffer: IMemory<PWideChar>;
  RequiredLength: NativeUInt;
begin
  Result := LdrxCheckDelayedImport(delayed_ResourceManagerQueueGetString);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(INITIAL_SIZE);
  Result.Location := 'ResourceManagerQueueGetString';

  repeat
    RequiredLength := 0;
    Result.HResult := ResourceManagerQueueGetString(
      PWideChar(Reference), nil, nil, Buffer.Data,
      Buffer.Size div SizeOf(WideChar), @RequiredLength);

  until not NtxExpandBufferEx(Result, IMemory(Buffer), RequiredLength *
    SizeOf(WideChar));

  if not Result.IsSuccess then
    Exit;

  Value := RtlxCaptureString(Buffer.Data, Buffer.Size div SizeOf(WideChar));
end;

function PkgxMrmGetMergedPri;
const
  INITIAL_SIZE = SizeOf(WideChar) * 55;
var
  Buffer: IMemory<PWideChar>;
begin
  Result := LdrxCheckDelayedImport(delayed_GetMergedSystemPri);

  if not Result.IsSuccess then
    Exit;

  IMemory(Buffer) := Auto.AllocateDynamic(INITIAL_SIZE);
  Result.Location := 'GetMergedSystemPri';

  repeat
    Result.HResult := GetMergedSystemPri(PWideChar(MainPriPath),
      Buffer.Size div SizeOf(WideChar), Buffer.Data, nil);

  until not NtxExpandBufferGuess(Result, IMemory(Buffer));

  if not Result.IsSuccess then
    Exit;

  MergedPriPath := RtlxCaptureString(Buffer.Data,
    Buffer.Size div SizeOf(WideChar));
end;

function PkgxMrmGetPackageResourceMap;
var
  ResourceManager: IMrtResourceManager;
begin
  Result := ComxCreateInstanceWithFallback(MrmCoreR, CLSID_MrtResourceManager,
    IMrtResourceManager, ResourceManager, 'CLSID_MrtResourceManager');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IMrtResourceManager::InitializeForPackage';
  Result.HResult := ResourceManager.InitializeForPackage(
    PWideChar(PackageFullName));

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IMrtResourceManager::GetMainResourceMap';
  Result.HResult := ResourceManager.GetMainResourceMap(IResourceMap,
    ResourceMap);
end;

function PkgxMrmGetFileResourceMap;
var
  ResourceManager: IMrtResourceManager;
begin
  Result := ComxCreateInstanceWithFallback(MrmCoreR, CLSID_MrtResourceManager,
    IMrtResourceManager, ResourceManager, 'CLSID_MrtResourceManager');

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IMrtResourceManager::InitializeForFile';
  Result.HResult := ResourceManager.InitializeForFile(
    PWideChar(PriFilePath));

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IMrtResourceManager::GetMainResourceMap';
  Result.HResult := ResourceManager.GetMainResourceMap(IResourceMap,
    ResourceMap);
end;

function PkgxMrmResolveStringInResourceMap;
var
  NamedResource: INamedResource;
  Candidate: IResourceCandidate;
  Buffer: PWideChar;
  BufferDeallocator: IAutoReleasable;
begin
  // Try direct string resolution first
  Result.Location := 'IResourceMap::GetString';
  Result.HResult := ResourceMap.GetString(PWideChar(Reference), Buffer);

  // If failed, retry using a method with sligtly different parsing rules
  if not Result.IsSuccess then
  begin
    Result.Location := 'IResourceMap::GetNamedResource';
    Result.HResult := ResourceMap.GetNamedResource(PWideChar(Reference),
      INamedResource, NamedResource);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'INamedResource::Resolve';
    Result.HResult := NamedResource.Resolve(Candidate);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'IResourceCandidate::ToString';
    Result.HResult := Candidate.ToString(Buffer);
  end;

  if Result.IsSuccess then
  begin
    BufferDeallocator := DeferCoTaskMemFree(Buffer);
    Value := String(Buffer);
  end;
end;

function PkgxMrmResolveStringForPackageSRCacheKey(
  out Value: String;
  const Reference: String;
  const hxPackageKey: IHandle
): TNtxStatus;
var
  ResourcesLocation, MergedPri: String;
  ResourceMap: IResourceMap;
begin
  // Locate the package files
  Result := PkgxSRCacheQueryPackageLocation(hxPackageKey, ResourcesLocation);

  if not Result.IsSuccess then
    Exit;

  // Locate the main resources file
  ResourcesLocation := RtlxCombinePaths(ResourcesLocation, 'resources.pri');

  // Prefer a merged PRI when available
  if not PkgxMrmGetMergedPri(ResourcesLocation, MergedPri).IsSuccess then
    MergedPri := ResourcesLocation;

  // Load it
  Result := PkgxMrmGetFileResourceMap(MergedPri, ResourceMap);

  if not Result.IsSuccess then
    Exit;

  // Try resolving
  Result := PkgxMrmResolveStringInResourceMap(ResourceMap, Reference, Value);
end;

function PkgxMrmResolveStringForFamily(
  out Value: String;
  const Reference: String;
  const FamilyName: String
): TNtxStatus;
var
  FamilyId: TSRCachePackageFamilyId;
  hxPackageKey: IHandle;
begin
  // Determine the state repository cache ID for the package family
  Result := PkgxSRCacheLookupPackageFamilyId(FamilyName, FamilyId);

  if not Result.IsSuccess then
    Exit;

  // Find the main or at least a framework or optional package in the family
  Result := PkgxSRCacheFindPackageInFamilyByType(hxPackageKey, FamilyId,
    PackageType_Main or PackageType_Framework or PackageType_Optional);

  if not Result.IsSuccess then
    Exit;

  // Resolve
  Result := PkgxMrmResolveStringForPackageSRCacheKey(Value, Reference,
    hxPackageKey);
end;

function PkgxMrmResolveStringForFullName(
  out Value: String;
  const Reference: String;
  const FullPackageName: String
): TNtxStatus;
var
  FamilyName: String;
  hxPackageKey: IHandle;
  PackageId: TSRCachePackageId;
begin
  // Lookup the package in the state repository cache (for any user)
  Result := PkgxSRCacheLookupPackageId(FullPackageName, PackageId);

  // Sometimes fully qualified resource names reference stale package
  // versions. Fall back to per-family resolution in this case.
  if (Result.Status = STATUS_OBJECT_NAME_NOT_FOUND) and
    PkgxDeriveFamilyNameFromFullName(FamilyName, FullPackageName).IsSuccess and
    PkgxMrmResolveStringForFamily(Value, Reference, FamilyName).IsSuccess then
    Exit(NtxSuccess);

  if not Result.IsSuccess then
    Exit;

  Result := PkgxSRCacheOpenPackage(PackageId, hxPackageKey);

  if not Result.IsSuccess then
    Exit;

  // Open package resources and load from there
  Result := PkgxMrmResolveStringForPackageSRCacheKey(Value, Reference,
    hxPackageKey);
end;

function PkgxMrmClassifyReference;
var
  Delimiter: Integer;
begin
  Delimiter := 0;

  // Check for @{PackageFullName?ms-resource://ResourcePath}
  if RtlxPrefixString('@{', Reference, True) and
    RtlxSuffixString('}', Reference, True) then
  begin
    // Split into package and resource
    Delimiter := System.Pos('?', Reference);

    if Delimiter > 0 then
      Result := rkFullyQualifiedResource
    else
      Result := rkInvalid;
  end
  // Check for ms-resource:ResourceName
  else if RtlxPrefixString('ms-resource:', Reference) then
    Result := rkRelativeResource
  else
    Result := rkInvalid;

  if Assigned(FullDelimiter) then
    FullDelimiter^ := Delimiter;
end;

function PkgxMrmResolveString;
var
  FullName, RelativeReference: String;
  Delimiter: Integer;
begin
  case PkgxMrmClassifyReference(Reference, @Delimiter) of

    rkFullyQualifiedResource:
    begin
      // Extract the package and the resourcce path
      FullName := Copy(Reference, 3, Delimiter - 3);
      RelativeReference := Copy(Reference, Delimiter + 1,
        Length(Reference) - Delimiter - 1);

      Result := PkgxMrmResolveStringForFullName(Value, RelativeReference,
        FullName);
    end;

    rkRelativeResource:
    begin
      // Relative resources must reference a package family
      if FamilyName = '' then
      begin
        Result.Location := 'PkgxMrmResolveString';
        Result.Status := STATUS_INVALID_PARAMETER;
        Exit;
      end;

      Result := PkgxMrmResolveStringForFamily(Value, Reference, FamilyName);
    end
  else
    Result.Location := 'PkgxMrmResolveString';
    Result.Status := STATUS_UNKNOWN_REVISION;
  end;
end;

function PkgxMrmResolveStringVar;
var
  ResolvedValue: String;
begin
  Result := PkgxMrmResolveString(ResolvedValue, Reference, FamilyName);

  if Result.IsSuccess then
    Reference := ResolvedValue;
end;

end.
