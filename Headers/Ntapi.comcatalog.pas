unit Ntapi.comcatalog;

{
  This module provides definitions for querying the COM/WinRT component catalog.
}

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ObjBase, Ntapi.winrt, DelphiApi.Reflection, Ntapi.Versions;

type
  // private
  IComCatalog = interface(IUnknown)
    ['{000001E0-0000-0000-C000-000000000046}']

    function GetClassInfoW(
      [in] const ConfiguredClsid: TClsid;
      [in] const Iid: TIid;
      [out] out pv // IComClassInfo, IClassClassicInfo[2/3], ICacheRefresh, IRegistration
    ): HResult; stdcall;

    function GetApplicationInfo(
      [in] const AppId: TGuid;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function GetProcessInfo(
      [in] const Process: TGuid;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    [Reserved]
    function GetServerGroupInfo(
      [in] const ServerGroup: TGuid;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    [Reserved]
    function GetRetQueueInfo(
      [in] FormatName: PWideChar;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    [Reserved]
    function GetApplicationInfoForExe(
      [in] ExeName: PWideChar;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    [Reserved]
    function GetTypeLibrary(
      [in] const TypeLib: TGuid;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function GetInterfaceInfo(
      [in] const iidInterface: TIid;
      [in] const Iid: TIid;
      [out] out pv // IInterfaceInfo
    ): HResult; stdcall;

    function FlushCache(
    ): HResult; stdcall;

    function GetClassInfoFromProgId(
      [in] ProgID: PWideChar;
      [in] const Iid: TIid;
      [out] out pv // IComClassInfo, IClassClassicInfo[2/3], ICacheRefresh, IRegistration
    ): HResult; stdcall;
  end;

  IUserToken = IUnknown;

  // private
  IComCatalogSCM = interface(IUnknown)

    function GetClassInfoW(
      [in] Flags: Cardinal;
      [in, opt] const UserToken: IUserToken;
      [in] const ConfiguredClsid: TClsid;
      [in] const Iid: TIid;
      [out] out pv // IComClassInfo, IClassClassicInfo[2/3], ICacheRefresh, IRegistration
    ): HResult; stdcall;

    function GetApplicationInfo(
      [in, opt] const UserToken: IUserToken;
      [in] const AppId: TGuid;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function GetProcessInfo(
      [in] Flags: Cardinal;
      [in, opt] const UserToken: IUserToken;
      [in] const Process: TGuid;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    [Reserved]
    function GetServerGroupInfo(
      [in, opt] const UserToken: IUserToken;
      [in] const ServerGroup: TGuid;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    [Reserved]
    function GetRetQueueInfo(
      [in, opt] const UserToken: IUserToken;
      [in] FormatName: PWideChar;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    [Reserved]
    function GetApplicationInfoForExe(
      [in, opt] const UserToken: IUserToken;
      [in] ExeName: PWideChar;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function GetTypeLibrary(
      [in, opt] const UserToken: IUserToken;
      [in] const TypeLib: TGuid;
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function GetInterfaceInfo(
      [in, opt] const UserToken: IUserToken;
      [in] const iidInterface: TIid;
      [in] const Iid: TIid;
      [out] out pv // IInterfaceInfo
    ): HResult; stdcall;

    function FlushCache(
    ): HResult; stdcall;

    function GetClassInfoFromProgId(
      [in, opt] const UserToken: IUserToken;
      [in] ProgID: PWideChar;
      [in] const Iid: TIid;
      [out] out pv // IComClassInfo, IClassClassicInfo[2/3], ICacheRefresh, IRegistration
    ): HResult; stdcall;

    function FlushIdleEntries(
    ): HResult; stdcall;
  end;

  // private
  [MinOSVersion(OsWin8)]
  IWinRTCatalogInternal = interface (IUnknown)
    ['{22DE7513-3849-4767-847D-C66AEBC88040}']

    function GetRuntimeClassInfo(
      [in] Flags: Cardinal;
      [in, opt] const UserToken: IUserToken;
      [in] ActivatableClassId: PWideChar;
      [in, opt] PackageMoniker: PWideChar;
      [in, opt] KnownClsidAndScope: Pointer; // aka AllowPrivate: LongBool on RS5+
      [in] const Iid: TIid;
      [out] out pv; // IWinRTRuntimeClassInfo
      [in, opt] const ComCatalogCallback: IComCatalogSCM
    ): HResult; stdcall;

    function GetServerInfo(
      [in] Flags: Cardinal;
      [in, opt] const UserToken: IUserToken;
      [in] ServerName: PWideChar;
      [in, opt] PackageMoniker: PWideChar;
      [in] const Iid: TIid;
      [out] out pv; // IWinRTServerInfo
      [in, opt] const ComCatalogCallback: IComCatalogSCM
    ): HResult; stdcall;

    function GetProxyStubCLSIDForInterface(
      [in] Flags: Cardinal;
      [in] const Iid: TIid;
      [in, opt] PackageMoniker: PWideChar;
      [out] out Clsid: TClsid
    ): HResult; stdcall;
  end;

  // private
  [SDKName('ACTIVATION_STAGE')]
  TActivationStage = (
    CLIENT_CONTEXT_STAGE = 1,
    CLIENT_MACHINE_STAGE = 2,
    SERVER_MACHINE_STAGE = 3,
    SERVER_PROCESS_STAGE = 4,
    SERVER_CONTEXT_STAGE = 5
  );

  ISystemActivator = IUnknown;
  PISystemActivator = ^ISystemActivator;

  // private
  IComClassInfo = interface(IUnknown)
    ['{000001E1-0000-0000-C000-000000000046}']

    function GetConfiguredClsid(
      [out] out Clsid: PClsid
    ): HResult; stdcall;

    function GetProgId(
      [out] out Progid: PWideChar
    ): HResult; stdcall;

    function GetClassNameW(
      [out] out ClassName: PWideChar
    ): HResult; stdcall;

    function GetApplication(
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function GetClassContext(
      [in] Filter: TClsctx;
      [out] out ClsCtx: TClsCtx
    ): HResult; stdcall;

    function GetCustomActivatorCount(
      [in] ActivationStage: TActivationStage;
      [out] out Count: Cardinal
    ): HResult; stdcall;

    function GetCustomActivatorClsids(
      [in] ActivationStage: TActivationStage;
      [out] out Clsid: PGuid
    ): HResult; stdcall;

    function GetCustomActivators(
      [in] ActivationStage: TActivationStage;
      [out] out Activator: PISystemActivator
    ): HResult; stdcall;

    function GetTypeInfo(
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function IsComPlusConfiguredClass(
      [out] out ComPlusConfiguredClass: LongBool
    ): HResult; stdcall;

    function MustRunInClientContext(
      [out] out MustRunInClientContext: LongBool
    ): HResult; stdcall;

    function GetVersionNumber(
      [out] out VersionMS: Cardinal;
      [out] out VersionLS: Cardinal
    ): HResult; stdcall;

    function Lock(
    ): HResult; stdcall;

    function Unlock(
    ): HResult; stdcall;
  end;

  // private
  [SDKName('ThreadingModel')]
  TThreadingModel = (
    ApartmentThreaded = 0,
    FreeThreaded = 1,
    SingleThreaded = 2,
    BothThreaded = 3,
    NeutralThreaded = 4
  );

  // private
  [SDKName('LocalServerType')]
  TLocalServerType = (
    LocalServerType16 = 0,
    LocalServerType32 = 1
  );

  // private
  IClassClassicInfo = interface(IUnknown)
    ['{000001E2-0000-0000-C000-000000000046}']

    function GetThreadingModel(
      [out] out ThreadModel: TThreadingModel
    ): HResult; stdcall;

    function GetModulePath(
      [in] ClsCtx: TClsCtx;
      [out] out DllName: PWideChar
    ): HResult; stdcall;

    function GetImplementedClsid(
      [out] out Clsid: PClsid
    ): HResult; stdcall;

    function GetProcess(
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function GetRemoteServerName(
      [out] out MachineName: PWideChar
    ): HResult; stdcall;

    function GetLocalServerType(
      [out] out ServerType: TLocalServerType
    ): HResult; stdcall;

    function GetSurrogateCommandLine(
      [out] out SurrogateCommandLine: PWideChar
    ): HResult; stdcall;
  end;

  // private
  IClassClassicInfo2 = interface(IUnknown)
    ['{000001DF-0000-0000-C000-000000000046}']

    function GetServerExecutable(
      [out] out ServerExecutable: PWideChar
    ): HResult; stdcall;
  end;

  // private
  IClassClassicInfo3 = interface(IUnknown)
    ['{0318B242-D086-4DE9-B10C-2824A6CA1019}']

    function GetPreferredServerBitness(
      [out] out Bitness: Cardinal
    ): HResult; stdcall;

    function GetOutofprocServerBinaryArchitecture(
      [out] out Architecture: Cardinal
    ): HResult; stdcall;

    function GetUserSettings(
      [out] out Settings: LongBool
    ): HResult; stdcall;

    function GetLUAEnabledSetting(
      [out] out LUAEnabled: LongBool
    ): HResult; stdcall;

    function GetDisplayName(
      [out] out DisplayName: PWideChar
    ): HResult; stdcall;

    function GetIconReference(
      [out] out IconReference: PWideChar
    ): HResult; stdcall;

    function GetBinaryName(
      [out] out BinaryName: PWideChar
    ): HResult; stdcall;

    [MinOSVersion(OsWin10RS1)]
    function GetExecutionPackageName(
      [out] out PackageName: THString
    ): HResult; stdcall;

    [MinOSVersion(OsWin10RS5)]
    function GetActivateOnHostFlags(
      [out] out Flags: Cardinal
    ): HResult; stdcall;
  end;

  // private
  IInterfaceInfo = interface(IUnknown)
    ['{000001F7-0000-0000-C000-000000000046}']

    function GetProxyStubCLSID(
      [out] out Clsid: PGuid;
      [out] out Is16BitPS: LongBool
    ): HResult; stdcall;

    function GetTypeLibrary(
      [out] out LibID: PGuid;
      [out] out VersionMajor: Word;
      [out] out VersionMinor: Word
    ): HResult; stdcall;

    function GetSyncIID(
      [out] out SyncIid: PGuid
    ): HResult; stdcall;

    function GetAsyncIID(
      [out] out AsyncIid: PGuid
    ): HResult; stdcall;

    function GetTypeInfo(
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;
  end;

  IWinRTServerInfo = IUnknown;

  // private
  [SDKName('Windows::Foundation::ActivationType')]
  [NamingStyle(nsCamelCase, 'ActivationType')]
  TRoActivationType = (
    ActivationType_InProcess = 0,
    ActivationType_OutOfProcess = 1,
    ActivationType_RemoteProcess = 2
  );

  // private
  [SDKName('Windows::Foundation::ThreadingType')]
  [NamingStyle(nsCamelCase, 'ThreadingType')]
  TRoThreadingType = (
    ThreadingType_BOTH = 0,
    ThreadingType_STA = 1,
    ThreadingType_MTA = 2
  );

  // private
  [SDKName('Windows::Foundation::ActivateAsUser')]
  [NamingStyle(nsCamelCase, 'ActivateAsUser')]
  TRoActivateAsUser = (
    ActivateAsUser_NotSupported = 0,
    ActivateAsUser_Supported = 1
  );

  // private
  [SDKName('Windows::Foundation::RegistrationScope')]
  [NamingStyle(nsCamelCase, 'RegistrationScope')]
  TRoRegistrationScope = (
    RegistrationScope_PerMachine = 0,
    RegistrationScope_PerUser = 1,
    RegistrationScope_InboxApp = 2
  );

  // private
  [MinOSVersion(OsWin1019H1)]
  IWinRTRuntimeClassInfo = interface (IUnknown)
    ['{3CA31250-4CD0-42EF-A711-2F5686E69E07}']

    function GetActivatableClassId(
      [out] out ActivatableClassId: THString
    ): HResult; stdcall;

    function GetActivationType(
      [out] out ActivationType: TRoActivationType
    ): HResult; stdcall;

    function GetDllPath(
      [out] out DllPath: PWideChar
    ): HResult; stdcall;

    function GetServerName(
      [out] out ServerName: PWideChar
    ): HResult; stdcall;

    function GetThreadingModel(
      [out] out ThreadingModel: TRoThreadingType
    ): HResult; stdcall;

    function GetTrustLevel(
      [out] out TrustLevel: TRoTrustLevel
    ): HResult; stdcall;

    function GetRegistrationScope(
      [out] out RegistrationScope: TRoRegistrationScope
    ): HResult; stdcall;

    function GetExecutionPackageName(
      [out] out PackageName: THString
    ): HResult; stdcall;

    function GetServerInfo(
      [out] out ServerInfo: IWinRTServerInfo
    ): HResult; stdcall;

    function GetActivateAsUser(
      [out] out ActivateAsUser: TRoActivateAsUser
    ): HResult; stdcall;

    function GetActivateInSharedBroker(
      [out] out ActivateInSharedBroker: LongBool
    ): HResult; stdcall;

    function GetActivateInBrokerForMediumILContainer(
      [out] out ActivateInBrokerForMediumILContainer: LongBool
    ): HResult; stdcall;

    function GetAttributes(
      [in] const Iid: TIid;
      [out] out pv
    ): HResult; stdcall;

    function GetPermissions(
      [out] out SecurityDescriptor: PSecurityDescriptor
    ): HResult; stdcall;
  end;

// private
function CoGetComCatalog(
  [in] const Iid: TIid;
  [out] out pv // IComCatalog*, IWinRTCatalogInternal
): HResult; stdcall external ole32;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
