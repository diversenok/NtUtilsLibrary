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
    rkUnknown,
    rkFullyQualifiedResource, // @{PackageFullName?ms-resource://ResourcePath}
    rkRelativeResource        // ms-resource:ResourceName
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

// Determine the type of a resource reference
function PkgxMrmResourceReferenceType(
  const Reference: String
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
  Ntapi.appmodel, Ntapi.ntstatus, Ntapi.WinError, NtUtils.Ldr, NtUtils.Com,
  NtUtils.SysUtils, NtUtils.Packages, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function PkgxMrmResolveFullResourceString(
  const Reference: String;
  out ResolvedValue: String
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

  ResolvedValue := RtlxCaptureString(Buffer.Data,
    Buffer.Size div SizeOf(WideChar));
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

function PkgxMrmResolveRelativeResourceString(
  const PackageFullName: String;
  const Reference: String;
  out Value: String
): TNtxStatus;
var
  ResourceMap: IResourceMap;
  NamedResource: INamedResource;
  Candidate: IResourceCandidate;
  Buffer: PWideChar;
  BufferDeallocator: IAutoReleasable;
begin
  Result := PkgxMrmGetPackageResourceMap(PackageFullName, ResourceMap);

  if not Result.IsSuccess then
    Exit;

  // Try the direct string resolution first
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

function PkgxMrmResourceReferenceType;
begin
  if RtlxPrefixString('@{', Reference, True) and
    RtlxSuffixString('}', Reference, True) then
    Result := rkFullyQualifiedResource
  else if RtlxPrefixString('ms-resource:', Reference) then
    Result := rkRelativeResource
  else
    Result := rkUnknown;
end;

function PkgxMrmResolveString;
var
  HeadPackage: TArray<TPkgxPackageNameAndProperties>;
  i: Integer;
begin
  case PkgxMrmResourceReferenceType(Reference) of

    rkFullyQualifiedResource:
      Result := PkgxMrmResolveFullResourceString(Reference, Value);

    rkRelativeResource:
    begin
      // Relative resources must reference a package family
      if FamilyName = '' then
      begin
        Result.Location := 'PkgxMrmResolveString';
        Result.Status := STATUS_INVALID_PARAMETER;
        Exit;
      end;

      // We need the full package name; find the head package of the family
      Result := PkgxEnumeratePackagesInFamilyByNameEx(HeadPackage,
        FamilyName, PACKAGE_FILTER_HEAD);

      if not Result.IsSuccess then
        Exit;

      if Length(HeadPackage) <= 0 then
      begin
        Result.Location := 'PkgxMrmResolveString';
        Result.Win32Error := APPMODEL_ERROR_NO_PACKAGE;
        Exit;
      end;

      for i := 0 to High(HeadPackage) do
      begin
        Result := PkgxMrmResolveRelativeResourceString(HeadPackage[i].FullName,
          Reference, Value);

        if Result.IsSuccess then
          Break;
      end;
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
