unit NtUtils.Packages.WinRT;

{
  This module provides definitions for application package support in
  Windows Runtime.
}

interface

uses
  Ntapi.winrt.appmodel, Ntapi.winrt, Ntapi.Versions, NtUtils;

// Enumerate packages
[RequiresWinRT]
[MinOSVersion(OsWin8)]
function RoxEnumeratePackages(
  out Packages: TArray<IPackage>;
  AllUser: Boolean = False;
  [opt] const UserSid: ISid = nil
): TNtxStatus;

// Enumerate packages returning full names
[RequiresWinRT]
[MinOSVersion(OsWin8)]
function RoxEnumeratePackageNames(
  out FullNames: TArray<String>;
  AllUser: Boolean;
  [opt] const UserSid: ISid = nil
): TNtxStatus;

// Enumerate packages returning family names
[RequiresWinRT]
[MinOSVersion(OsWin8)]
function RoxEnumeratePackageFamilyNames(
  out FamilyNames: TArray<String>;
  AllUser: Boolean;
  [opt] const UserSid: ISid = nil
): TNtxStatus;

// Enumerate packages returning application user-mode IDs
[RequiresWinRT]
[MinOSVersion(OsWin81)]
function RoxEnumeratePackageApps(
  out AppUserModelIDs: TArray<String>;
  AllUser: Boolean = False;
  [opt] const UserSid: ISid = nil
): TNtxStatus;

implementation

uses
  NtUtils.WinRT, NtUtils.Security.Sid, NtUtils.Packages,
  DelphiUtils.Arrays;

function RoxEnumeratePackages;
var
  Inspectable: IInspectable;
  PackageManeger: IPackageManager;
  Iterable: IIterable<IPackage>;
  Iterator: IIterator<IPackage>;
  Package: IPackage;
  SidString: IHString;
  HasCurrent: Boolean;
begin
  Result := RoxActivateInstance('Windows.Management.Deployment.PackageManager',
    Inspectable);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IInspectable::QueryInterface';
  Result.LastCall.Parameter := 'IPackageManager';
  Result.HResult := Inspectable.QueryInterface(IPackageManager,
    PackageManeger);

  if not Result.IsSuccess then
    Exit;

  if AllUser then
  begin
    // Find all packages
    Result.Location := 'IPackageManager::FindPackages';
    Result.HResult := PackageManeger.FindPackages(Iterable);
  end
  else
  begin
    // Prepare the user SID
    if Assigned(UserSid) then
    begin
      Result := RoxCreateString(RtlxSidToString(UserSid), SidString);

      if not Result.IsSuccess then
        Exit;
    end
    else
      SidString := nil;

    // Find all user packages
    Result.Location := 'IPackageManager::FindPackagesByUserSecurityId';
    Result.HResult := PackageManeger.FindPackagesByUserSecurityId(
      Auto.RefOrNil<THString>(SidString), Iterable);
  end;

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IIterable<IPackage>::First';
  Result.HResult := Iterable.First(Iterator);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IIterator<IPackage>::get_HasCurrent';
  Result.HResult := Iterator.get_HasCurrent(HasCurrent);

  if not Result.IsSuccess then
    Exit;

  Packages := nil;

  while hasCurrent do
  begin
    Result.Location := 'IIterator<IPackage>::get_Current';
    Result.HResult := Iterator.get_Current(Package);

    if not Result.IsSuccess then
      Exit;

    SetLength(Packages, Length(Packages) + 1);
    Packages[High(Packages)] := Package;

    Result.Location := 'IIterator<IPackage>.MoveNext';
    Result.HResult := Iterator.MoveNext(HasCurrent);

    if not Result.IsSuccess then
      Exit;
  end;
end;

function RoxEnumeratePackageNames;
var
  Packages: TArray<IPackage>;
  PackageId: IPackageId;
  i: Integer;
  hString: THString;
  hStringDeallocator: IAutoReleasable;
begin
  Result := RoxEnumeratePackages(Packages, AllUser, UserSid);

  if not Result.IsSuccess then
    Exit;

  SetLength(FullNames, Length(Packages));

  for i := 0 to High(Packages) do
  begin
    Result.Location := 'IPackage::Get_Id';
    Result.HResult := Packages[i].Get_Id(PackageId);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'IPackageId::get_FullName';
    Result.HResult := PackageId.get_FullName(hString);

    if not Result.IsSuccess then
      Exit;

    hStringDeallocator := RoxCaptureString(hString);
    FullNames[i] := RoxDumpString(hString);
  end;
end;

function RoxEnumeratePackageFamilyNames;
var
  Packages: TArray<IPackage>;
  PackageId: IPackageId;
  i: Integer;
  hString: THString;
  hStringDeallocator: IAutoReleasable;
begin
  Result := RoxEnumeratePackages(Packages, AllUser, UserSid);

  if not Result.IsSuccess then
    Exit;

  SetLength(FamilyNames, Length(Packages));

  for i := 0 to High(Packages) do
  begin
    Result.Location := 'IPackage::Get_Id';
    Result.HResult := Packages[i].Get_Id(PackageId);

    if not Result.IsSuccess then
      Exit;

    Result.Location := 'IPackageId::get_FamilyName';
    Result.HResult := PackageId.get_FamilyName(hString);

    if not Result.IsSuccess then
      Exit;

    hStringDeallocator := RoxCaptureString(hString);
    FamilyNames[i] := RoxDumpString(hString);
  end;
end;

function RoxEnumeratePackageApps;
var
  FullNames: TArray<String>;
  IDs: TArray<TArray<String>>;
  InfoReference: IPackageInfoReference;
  i: Integer;
begin
  // Collect all packages
  Result := RoxEnumeratePackageNames(FullNames, AllUser, UserSid);

  if not Result.IsSuccess then
    Exit;

  SetLength(IDs, Length(FullNames));

  // Enumerate applications in each package
  for i := 0 to High(FullNames) do
  begin
    Result := PkgxOpenPackageInfo(InfoReference, FullNames[i]);

    if not Result.IsSuccess then
      Exit;

    Result := PkgxEnumerateAppUserModelIds(IDs[i], InfoReference);

    if not Result.IsSuccess then
      Exit;
  end;

  // Merge them
  AppUserModelIDs := TArray.Flatten<String>(IDs);
end;

end.
