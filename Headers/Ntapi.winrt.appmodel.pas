unit Ntapi.winrt.appmodel;

{
  This module provides definitions for application package support in
  Windows Runtime.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.winrt, DelphiApi.Reflection;

type
  // TBD
  IWwwFormUrlDecoderRuntimeClass = type IUnknown;
  IStorageFolder = type IUnknown;

  // SDK::windows.foundation.h
  [SDKName('Windows::Foundation::IUriRuntimeClass')]
  IUriRuntimeClass = interface (IInspectable)
    ['{9e365e57-48b2-4160-956f-c7385120bbfc}']

    function get_AbsoluteUri(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_DisplayUri(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Domain(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Extension(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Fragment(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Host(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Password(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Path(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Query(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_QueryParsed(
      [out] out WwwFormUrlDecoder: IWwwFormUrlDecoderRuntimeClass
    ): HResult; stdcall;

    function get_RawUri(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_SchemeName(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_UserName(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Port(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Suspicious(
      [out] out value: Boolean
    ): HResult; stdcall;

    function Equals(
      [in] const Uri: IUriRuntimeClass;
      [out] out value: Boolean
    ): HResult; stdcall;

    function CombineUri(
      [in] relativeUri: THString;
      [in] const instance: IUriRuntimeClass
    ): HResult; stdcall;
  end;

  // SDK::windows.applicationmodel.h
  [SDKName('Windows::ApplicationModel::PackageVersion')]
  TPackageVersionAbi = record
    Major: Word;
    Minor: Word;
    Build: Word;
    Revision: Word;
  end;

  // SDK::windows.applicationmodel.h
  [SDKName('Windows::ApplicationModel::IPackageId')]
  IPackageId = interface (IInspectable)
    ['{1adb665e-37c7-4790-9980-dd7ae74e8bb2}']

    function get_Name(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Version(
      [out] out value: TPackageVersionAbi
    ): HResult; stdcall;

    function get_Architecture(
      [out] out value: Cardinal // TProcessorArchitecture
    ): HResult; stdcall;

    function get_ResourceId(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Publisher(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_PublisherId(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_FullName(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_FamilyName(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;
  end;

  // SDK::windows.applicationmodel.h
  [SDKName('Windows::ApplicationModel::IPackage')]
  IPackage = interface (IInspectable)
    ['{163c792f-bd75-413c-bf23-b1fe7b95d825}']

    function Get_Id(
      [out] out value: IPackageId
    ): HResult; stdcall;

    function get_InstalledLocation(
      [out] out value: IStorageFolder
    ): HResult; stdcall;

    function get_IsFramework(
      [out] out value: Boolean
    ): HResult; stdcall;

    function get_Dependencies(
      [out] out value: IVectorView<IPackage>
    ): HResult; stdcall;
  end;

  // SDK::windows.applicationmodel.h
  [SDKName('Windows::ApplicationModel::IPackage')]
  IPackage2 = interface
    ['{a6612fb6-7688-4ace-95fb-359538e7aa01}']

    function get_DisplayName(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_PublisherDisplayName(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Description(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_Logo(
      [out] out value: IUriRuntimeClass
    ): HResult; stdcall;

    function get_IsResourcePackage(
      [out] out value: Boolean
    ): HResult; stdcall;

    function get_IsBundle(
      [out] out value: Boolean
    ): HResult; stdcall;

    function get_IsDevelopmentMode(
      [out] out value: Boolean
    ): HResult; stdcall;
  end;

  // SDK::windows.management.deployment.h
  [SDKName('Windows::Management::Deployment::PackageState')]
  [NamingStyle(nsCamelCase, 'PackageState_')]
  TPackageState = (
    PackageState_Normal = 0,
    PackageState_LicenseInvalid = 1,
    PackageState_Modified = 2,
    PackageState_Tampered = 3
  );

  // SDK::windows.management.deployment.h
  [SDKName('Windows::Management::Deployment::PackageInstallState')]
  [NamingStyle(nsCamelCase, 'PackageInstallState_')]
  TPackageInstallState = (
    PackageInstallState_NotInstalled = 0,
    PackageInstallState_Staged = 1,
    PackageInstallState_Installed = 2,
    PackageInstallState_Paused = 6
  );

  // SDK::windows.management.deployment.h
  [SDKName('Windows::Management::Deployment::IPackageUserInformation')]
  IPackageUserInformation = interface (IInspectable)
    ['{f6383423-fa09-4cbc-9055-15ca275e2e7e}']

    function get_UserSecurityId(
      [out, ReleaseWith('WindowsDeleteString')] out value: THString
    ): HResult; stdcall;

    function get_InstallState(
      [out] out value: TPackageInstallState
    ): HResult; stdcall;
  end;

  // SDK::windows.management.deployment.h
  [SDKName('Windows::Management::Deployment::IPackageManager')]
  IPackageManager = interface (IInspectable)
    ['{9a7d4b65-5e8f-4fc7-a2e5-7f6925cb8b53}']

    function AddPackageAsync(const tbd): HResult; stdcall;
    function UpdatePackageAsync(const tbd): HResult; stdcall;
    function RemovePackageAsync(const tbd): HResult; stdcall;
    function StagePackageAsync(const tbd): HResult; stdcall;
    function RegisterPackageAsync(const tbd): HResult; stdcall;

    function FindPackages(
      [out] out packageCollection: IIterable<IPackage>
    ): HResult; stdcall;

    function FindPackagesByUserSecurityId(
      [in, opt] userSecurityId: THString;
      [out] out packageCollection: IIterable<IPackage>
    ): HResult; stdcall;

    function FindPackagesByNamePublisher(
      [in] packageName: THString;
      [in] packagePublisher: THString;
      [out] out packageCollection: IIterable<IPackage>
    ): HResult; stdcall;

    function FindPackagesByUserSecurityIdNamePublisher(
      [in] userSecurityId: THString;
      [in] packageName: THString;
      [in] packagePublisher: THString;
      [out] out packageCollection: IIterable<IPackage>
    ): HResult; stdcall;

    function FindUsers(
      [in] packageFullName: THString;
      [out] out users: IIterable<IPackageUserInformation>
    ): HResult; stdcall;

    function SetPackageState(
      [in] packageFullName: THString;
      [in] packageState: TPackageState
    ): HResult; stdcall;

    function FindPackageByPackageFullName(
      [in] packageFullName: THString;
      [out] out packageInformation: IPackage
    ): HResult; stdcall;

    function CleanupPackageForUserAsync(const tbd): HResult; stdcall;

    function FindPackagesByPackageFamilyName(
      [in] packageFamilyName: THString;
      [out] out packageCollection: IIterable<IPackage>
    ): HResult; stdcall;

    function FindPackagesByUserSecurityIdPackageFamilyName(
      [in] userSecurityId: THString;
      [in] packageFamilyName: THString;
      [out] out packageCollection: IIterable<IPackage>
    ): HResult; stdcall;

    function FindPackageByUserSecurityIdPackageFullName(
      [in] userSecurityId: THString;
      [in] packageFullName: THString;
      [out] out packageInformation: IPackage
    ): HResult; stdcall;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
