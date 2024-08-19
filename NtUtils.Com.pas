unit NtUtils.Com;

{
  This module allows working with variant types and IDispatch without
  relying on System.Variant.
}

interface

uses
  Ntapi.ObjBase, Ntapi.ObjIdl, Ntapi.winrt, DelphiApi.Reflection,
  Ntapi.Versions, NtUtils, DelphiUtils.AutoObjects;

type
  IRtlxComDll = interface (IAutoPointer)
    function GetLoadName: String;
    property LoadName: String read GetLoadName;
    function CanUnloadNow: Boolean;

    // Call DllGetClassObject
    function GetClassObject(
      const Clsid: TClsid;
      out ClassFactory: IClassFactory;
      [opt] const ClassNameHint: String = ''
    ): TNtxStatus;

    // Call DllGetClassObject followed by IClassFactory::CreateInstance
    function CreateInstance(
      const Clsid: TClsid;
      const Iid: TIid;
      out pv;
      [opt] const ClassNameHint: String = ''
    ): TNtxStatus;

    // Call DllGetActivationFactory
    function GetActivationFactory(
      const ActivatableClassId: String;
      out Factory: IActivationFactory
    ): TNtxStatus;

    // Call DllGetActivationFactory followed by IActivationFactory::ActivateInstance
    function ActivateInstance(
      const ActivatableClassId: String;
      out Instance: IInspectable
    ): TNtxStatus;
  end;

  IHString = IAutoPointer<THString>;

{ Manual COM / Manual WinRT }

// Manually load a COM-compatible DLL
function RtlxComLoadDll(
  const DllName: String;
  out Dll: IRtlxComDll
): TNtxStatus;

// Unload unused manually loaded COM DLLs
procedure RtlxComFreeUnusedLibraries;

// Manually create a COM class factory from a DLL
function RtlxComGetClassFactory(
  const DllName: String;
  const Clsid: TClsid;
  out ClassFactory: IClassFactory;
  [opt] const ClassNameHint: String = ''
): TNtxStatus;

// Manually create a COM object from a DLL
function RtlxComCreateInstance(
  const DllName: String;
  const Clsid: TClsid;
  const Iid: TIid;
  out pv;
  [opt] const ClassNameHint: String = ''
): TNtxStatus;

// Manually create a WinRT activation factory from a DLL
function RtlxComGetActivationFactory(
  const DllName: String;
  const ActivatableClassId: String;
  out Factory: IActivationFactory
): TNtxStatus;

// Manually create a WinRT object from a DLL
function RtlxComActivateInstance(
  const DllName: String;
  const ActivatableClassId: String;
  out Instance: IInspectable
): TNtxStatus;

{ COM Init }

// Allow COM initialization to proceed without lpacCom capability
function ComxSuppressCapabilityCheck(
): TNtxStatus;

// Initialize COM for the current process/thread
[Result: ReleaseWith('CoUninitialize')]
function ComxInitializeEx(
  PreferredMode: TCoInitMode = COINIT_APARTMENTTHREADED
): TNtxStatus;

// Initialize COM for the process/thread and uninitialize it later
function ComxInitializeExAuto(
  out Uninitializer: IAutoReleasable;
  PreferredMode: TCoInitMode = COINIT_APARTMENTTHREADED
): TNtxStatus;

// Determine the appartment type on the current thread
function ComxGetApartmentType(
  out ApartmentType: TAptType;
  out ApartmentQualifier: TAptTypeQualifier
): TNtxStatus;

// Check if COM has been initialized on the current thread
function ComxIsInitialized(
): Boolean;

// Initialize implicit MTA on the current thread if it has no apartment
[MinOSVersion(OsWin8)]
function ComxInitializeImplicit(
  [out, opt, ReleaseWith('ComxUninitializeImplicit')]
    Cookie: PCoMtaUsageCookie = nil
): TNtxStatus;

// Release a previous implicit MTA initialization
[MinOSVersion(OsWin8)]
function ComxUninitializeImplicit(
  Cookie: TCoMtaUsageCookie
): TNtxStatus;

// Initialize implicit MTA and release it later
[MinOSVersion(OsWin8)]
function ComxInitializeImplicitAuto(
  out Uninitializer: IAutoReleasable
): TNtxStatus;

// Initialize implicit MTA and release it on this module unload
[MinOSVersion(OsWin8)]
function ComxInitializeImplicitOnce(
): TNtxStatus;

// Make sure COM is initialized (with any apartment type) and add a reference
function ComxEnsureInitialized(
  out Uninitializer: IAutoReleasable
): TNtxStatus;

{ Base COM }

// Create a class factory from a CLSID
[RequiresCOM]
function ComxGetClassFactory(
  const Clsid: TClsid;
  out ClassFactory: IClassFactory;
  [opt] const ClassNameHint: String = '';
  ClsContext: TClsCtx = CLSCTX_ALL
): TNtxStatus;

// Create a class factory via CoGetClassObject or fallback to manual COM use
function ComxGetClassFactoryWithFallback(
  const DllName: String;
  const Clsid: TClsid;
  out ClassFactory: IClassFactory;
  [opt] const ClassNameHint: String = '';
  ClsContext: TClsCtx = CLSCTX_ALL
): TNtxStatus;

// Create a COM object from a CLSID
[RequiresCOM]
function ComxCreateInstance(
  const Clsid: TClsid;
  const Iid: TIid;
  out pv;
  [opt] const ClassNameHint: String = '';
  ClsContext: TClsCtx = CLSCTX_ALL
): TNtxStatus;

// Create an in-process COM object via CoCreateInstance or fall back to loading
// it directly without using COM facilities
function ComxCreateInstanceWithFallback(
  const DllName: String;
  const Clsid: TClsid;
  const Iid: TIid;
  out pv;
  [opt] const ClassNameHint: String = '';
  ClsContext: TClsCtx = CLSCTX_ALL
): TNtxStatus;

{ Variants }

// Variant creation helpers
function VarEmpty: TVarData;
function VarFromWord(const Value: Word): TVarData;
function VarFromCardinal(const Value: Cardinal): TVarData;
function VarFromInteger(const Value: Integer): TVarData;
function VarFromIntegerRef(const [ref] Value: Integer): TVarData;
function VarFromWideString(const [ref] Value: WideString): TVarData;
function VarFromIDispatch(const Value: IDispatch): TVarData;

{ IDispatch helpers }

// Bind to a COM IDispatch object by name
function DispxBindToObject(
  const ObjectName: String;
  out Dispatch: IDispatch
): TNtxStatus;

// Lookup an ID of an IDispatch name
function DispxGetNameId(
  const Dispatch: IDispatch;
  const Name: String;
  out DispId: TDispID
): TNtxStatus;

// Invoke IDispatch
function DispxInvoke(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  const Flags: Word;
  var Params: TDispParams;
  [out, opt] VarResult: Pointer
): TNtxStatus;

// Invoke IDispatch using a string name
function DispxInvokeByName(
  const Dispatch: IDispatch;
  const Name: String;
  const Flags: Word;
  var Params: TDispParams;
  [out, opt] VarResult: Pointer
): TNtxStatus;

// Retrieve a property via an IDispatch by ID
function DispxGetProperty(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  out Value: TVarData
): TNtxStatus;

// Retrieve a property via an IDispatch by name
function DispxGetPropertyByName(
  const Dispatch: IDispatch;
  const Name: String;
  out Value: TVarData
): TNtxStatus;

// Assign a property via an IDispatch by ID
function DispxSetProperty(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  const Value: TVarData
): TNtxStatus;

// Assign a property via an IDispatch by name
function DispxSetPropertyByName(
  const Dispatch: IDispatch;
  const Name: String;
  const Value: TVarData
): TNtxStatus;

// Call a method via IDispatch by ID
function DispxCallMethod(
  const Dispatch: IDispatch;
  const DispId: TDispID;
  [opt] const Parameters: TArray<TVarData> = nil;
  [out, opt] VarResult: PVarData = nil
): TNtxStatus;

// Call a method via IDispatch by name
function DispxCallMethodByName(
  const Dispatch: IDispatch;
  const Name: String;
  [opt] const Parameters: TArray<TVarData> = nil;
  [out, opt] VarResult: PVarData = nil
): TNtxStatus;

{ WinRT strings }

// Capture ownership of a WinRT string
[MinOSVersion(OsWin8)]
function RoxCaptureString(
  [in, opt] Buffer: THString
): IHString;

// Create a WinRT string from a Delphi string
[MinOSVersion(OsWin8)]
function RoxCreateString(
  const Source: String;
  out Str: IHString
): TNtxStatus;

// Create a Delphi string from a WinRT string
[MinOSVersion(OsWin8)]
function RoxSaveString(
  [in, opt] Str: THString
): String;

{ WinRT }

// Uninitialize the Windows Runtime
[MinOSVersion(OsWin8)]
procedure RoxUninitialize;

// Initialize the Windows Runtime
[MinOSVersion(OsWin8)]
function RoxInitialize(
  InitType: TRoInitType = RO_INIT_MULTITHREADED
): TNtxStatus;

// Initialize the Windows Runtime and uninitialize it later
[MinOSVersion(OsWin8)]
function RoxInitializeAuto(
  out Uninitializer: IAutoReleasable;
  InitType: TRoInitType = RO_INIT_MULTITHREADED
): TNtxStatus;

// Initialize the Windows Runtime and uninitialize at this module finalization
[MinOSVersion(OsWin8)]
function RoxInitializeOnce(
  InitType: TRoInitType = RO_INIT_MULTITHREADED
): TNtxStatus;

// Create a WinRT activation factory
[RequiresWinRT]
[MinOSVersion(OsWin8)]
function RoxGetActivationFactory(
  const ActivatableClassId: String;
  out Factory: IActivationFactory
): TNtxStatus;

// Create a WinRT activation factory via RoGetActivationFactory or fallback
// to manual WinRT
[MinOSVersion(OsWin8)]
function RoxGetActivationFactoryWithFallback(
  const DllName: String;
  const ActivatableClassId: String;
  out Factory: IActivationFactory
): TNtxStatus;

// Activate a WinRT class
[RequiresWinRT]
[MinOSVersion(OsWin8)]
function RoxActivateInstance(
  const ActivatableClassId: String;
  out Inspectable: IInspectable
): TNtxStatus;

// Activate a WinRT class via RoActivateInstance or fallback
// to manual WinRT
[MinOSVersion(OsWin8)]
function RoxActivateInstanceWithFallback(
  const DllName: String;
  const ActivatableClassId: String;
  out Inspectable: IInspectable
): TNtxStatus;

implementation

uses
  Ntapi.WinError, Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntstatus, Ntapi.ntpebteb,
  NtUtils.Errors, NtUtils.Ldr, NtUtils.AntiHooking, NtUtils.Tokens,
  NtUtils.Tokens.Info, NtUtils.Synchronization, NtUtils.SysUtils,
  DelphiUtils.Arrays;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

type
  TRtlxComDll = class (TCustomAutoPointer, IRtlxComDll)
  protected
    FName: String;
    FDllCanUnloadNow: TDllCanUnloadNow;
    FDllGetClassObject: TDllGetClassObject;
    FDllGetActivationFactory: TDllGetActivationFactory;
    procedure Release; override;
    constructor Create(
      const Name: String;
      DllBase: Pointer;
      ADllCanUnloadNow: TDllCanUnloadNow;
      ADllGetClassObject: TDllGetClassObject;
      ADllGetActivationFactory: TDllGetActivationFactory
    );
  public
    class var StorageLock: TRtlSRWLock;
    class var Storage: TArray<IRtlxComDll>;
  public
    function GetLoadName: String;
    function CanUnloadNow: Boolean;
    function GetClassObject(
      const clsid: TClsid;
      out pv: IClassFactory;
      const ClassNameHint: String
    ): TNtxStatus;
    function CreateInstance(
      const Clsid: TClsid;
      const Iid: TIid;
      out pv;
      const ClassNameHint: String
    ): TNtxStatus;
    function GetActivationFactory(
      const ActivatableClassId: String;
      out factory: IActivationFactory
    ): TNtxStatus;
    function ActivateInstance(
      const ActivatableClassId: String;
      out Instance: IInspectable
    ): TNtxStatus;
  end;

{ TRtlxComDll }

function TRtlxComDll.ActivateInstance;
var
  Factory: IActivationFactory;
begin
  Result := GetActivationFactory(ActivatableClassId, Factory);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IActivationFactory::ActivateInstance';
  Result.LastCall.Parameter := ActivatableClassId;
  Result.HResult := Factory.ActivateInstance(Instance);
end;

function TRtlxComDll.CanUnloadNow;
begin
  // If there is no DllCanUnloadNow, allow unloading only if there are no
  // other COM exports
  if not Assigned(FDllCanUnloadNow) and not Assigned(FDllGetClassObject) and
    not Assigned(FDllGetActivationFactory) then
    Exit(True);

  try
    Result := (FDllCanUnloadNow = S_OK);
  except
    // If the DLL throws an exception in the callback, don't touch it; it
    // doesn't like manual COM
    Result := False;
  end;
end;

constructor TRtlxComDll.Create;
begin
  inherited Capture(DllBase);
  FName := Name;
  FDllCanUnloadNow := ADllCanUnloadNow;
  FDllGetClassObject := ADllGetClassObject;
  FDllGetActivationFactory := ADllGetActivationFactory;
end;

function TRtlxComDll.CreateInstance;
var
  Factory: IClassFactory;
begin
  Result := GetClassObject(Clsid, Factory, ClassNameHint);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IClassFactory::CreateInstance';
  Result.LastCall.Parameter := ClassNameHint;
  Result.HResult := Factory.CreateInstance(nil, iid, pv);
end;

function TRtlxComDll.GetActivationFactory;
var
  ActivatableClassIdStr: IHString;
begin
  if not Assigned(FDllGetActivationFactory) then
  begin
    Result.Location := 'LdrGetProcedureAddress';
    Result.LastCall.Parameter := RtlxExtractNamePath(FName) +
      '!DllGetActivationFactory';
    Result.Status := STATUS_ENTRYPOINT_NOT_FOUND;
    Exit;
  end;

  Result := RoxCreateString(ActivatableClassId, ActivatableClassIdStr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'DllGetActivationFactory';
  Result.LastCall.Parameter := ActivatableClassId;
  Result.HResult := FDllGetActivationFactory(ActivatableClassIdStr.Data,
    factory);
end;

function TRtlxComDll.GetClassObject;
begin
  if not Assigned(FDllGetClassObject) then
  begin
    Result.Location := 'LdrGetProcedureAddress';
    Result.LastCall.Parameter := RtlxExtractNamePath(FName) +
      '!DllGetClassObject';
    Result.Status := STATUS_ENTRYPOINT_NOT_FOUND;
    Exit;
  end;

  Result.Location := 'DllGetClassObject';
  Result.LastCall.Parameter := ClassNameHint;
  Result.HResult := FDllGetClassObject(clsid, IClassFactory, pv);
end;


function TRtlxComDll.GetLoadName;
begin
  Result := FName;
end;

procedure TRtlxComDll.Release;
begin
  // Allow the DLL to prevent its unloading. Note that we are supposed to reach
  // this code when either the DLL is okay with being unloaded or it's the last
  // call (i.e., this module unload) since the storage should always keep the
  // last reference to the object.
  if Assigned(FData) and CanUnloadNow then
    LdrxUnloadDll(FData);

  FData := nil;
  inherited;
end;

{ Manual COM }

function RtlxComLoadDll;
var
  Lock: IAutoReleasable;
  Index: Integer;
  Module: IAutoPointer;
  ADllCanUnloadNow, ADllGetClassObject, ADllGetActivationFactory: Pointer;
begin
  // Synchronize access to the storage
  Lock := RtlxAcquireSRWLockExclusive(@TRtlxComDll.StorageLock);

  // Check if we already have en entry for the DLL
  Index := TArray.BinarySearchEx<IRtlxComDll>(TRtlxComDll.Storage,
    function (const Entry: IRtlxComDll): Integer
    begin
      Result := RtlxCompareStrings(Entry.LoadName, DllName);
    end
  );

  if Index >= 0 then
  begin
    // Found an existing entry
    Dll := TRtlxComDll.Storage[Index];
    Result := NtxSuccess;
    Exit;
  end;

  // Load the DLL
  Result := LdrxLoadDllAuto(DllName, Module);

  if not Result.IsSuccess then
    Exit;

  // Locate the unload checker export
  if not LdrxGetProcedureAddress(Module.Data, 'DllCanUnloadNow',
    ADllCanUnloadNow).IsSuccess then
    ADllCanUnloadNow := nil;

  // Locate the class factory export
  if not LdrxGetProcedureAddress(Module.Data, 'DllGetClassObject',
    ADllGetClassObject).IsSuccess then
    ADllGetClassObject := nil;

  // Locate the activation factory export
  if not LdrxGetProcedureAddress(Module.Data, 'DllGetActivationFactory',
    ADllGetActivationFactory).IsSuccess then
    ADllGetActivationFactory := nil;

  // Transfer DLL ownership to the wrapper
  Dll := TRtlxComDll.Create(DllName, Module.Data, ADllGetClassObject,
    ADllCanUnloadNow, ADllGetActivationFactory);
  Module.AutoRelease := False;

  // Register it in the storage
  Insert(Dll, TRtlxComDll.Storage, -(Index + 1));
end;

procedure RtlxComFreeUnusedLibraries;
var
  Lock: IAutoReleasable;
  i, Count: Integer;
  WeakRef: Weak<IRtlxComDll>;
begin
  // Synchronize access to the storage
  Lock := RtlxAcquireSRWLockExclusive(@TRtlxComDll.StorageLock);

  Count := 0;
  for i := 0 to High(TRtlxComDll.Storage) do
    if TRtlxComDll.Storage[i].CanUnloadNow then
    begin
      // The DLL reports that it's not in use.
      // Capture a weak reference and release the strong one
      WeakRef := TRtlxComDll.Storage[i];
      TRtlxComDll.Storage[i] := nil;

      // If we can upgrade the weak reference back, there are other strong
      // references, so we keep the object
      if WeakRef.Upgrade(TRtlxComDll.Storage[i]) then
        Inc(Count);
    end
    else
    begin
      // The DLL is not ready to unload; keep the object
      Inc(Count);
    end;

  // Truncate if necessary
  if Length(TRtlxComDll.Storage) <> Count then
    SetLength(TRtlxComDll.Storage, Count);
end;

function RtlxComGetClassFactory;
var
  Dll: IRtlxComDll;
begin
  Result := RtlxComLoadDll(DllName, Dll);

  if not Result.IsSuccess then
    Exit;

  Result := Dll.GetClassObject(Clsid, ClassFactory, ClassNameHint);
end;

function RtlxComCreateInstance;
var
  Dll: IRtlxComDll;
begin
  Result := RtlxComLoadDll(DllName, Dll);

  if not Result.IsSuccess then
    Exit;

  Result := Dll.CreateInstance(Clsid, Iid, pv, ClassNameHint);
end;

function RtlxComGetActivationFactory;
var
  Dll: IRtlxComDll;
begin
  Result := RtlxComLoadDll(DllName, Dll);

  if not Result.IsSuccess then
    Exit;

  Result := Dll.GetActivationFactory(ActivatableClassId, Factory);
end;

function RtlxComActivateInstance;
var
  Dll: IRtlxComDll;
begin
  Result := RtlxComLoadDll(DllName, Dll);

  if not Result.IsSuccess then
    Exit;

  Result := Dll.ActivateInstance(ActivatableClassId, Instance);
end;

{ Base COM }

var
  // We want to undo hooking on module unload
  CapabilitySuppressionInitialized: TRtlRunOnce;
  CapabilitySuppressionReverter: IAutoReleasable;

function ComxpConfirmCapability(
  [in, opt] TokenHandle: THandle;
  [in] CapabilitySidToCheck: PSid;
  [out] out HasCapability: Boolean
): NTSTATUS; stdcall;
begin
  try
    HasCapability := True;
    Result := STATUS_SUCCESS;
  except
    Result := STATUS_ACCESS_VIOLATION;
  end;
end;

function ComxSuppressCapabilityCheck;
var
  Init: IAcquiredRunOnce;
  IsLpac: Boolean;
begin
  // Already called?
  if not RtlxRunOnceBegin(@CapabilitySuppressionInitialized, Init) then
    Exit(NtxSuccess);

  // No capability checks before RS2
  if not RtlOsVersionAtLeast(OsWin10RS2) then
  begin
    Init.Complete;
    Exit(NtxSuccess);
  end;

  // No capability checks for non-LPAC tokens
  if NtxQueryLpacToken(NtxCurrentProcessToken, IsLpac).IsSuccess and
    not IsLpac then
  begin
    Init.Complete;
    Exit(NtxSuccess);
  end;

  // Redirect the capability checking function
  Result := RtlxInstallIATHook(CapabilitySuppressionReverter, combase, ntdll,
    'RtlCheckTokenCapability', @ComxpConfirmCapability);

  if Result.IsSuccess then
    Init.Complete;
end;

function ComxInitializeEx;
begin
  Result.Location := 'CoInitializeEx';
  Result.HResultAllowFalse := CoInitializeEx(nil, PreferredMode);

  // S_FALSE indicates that COM is already initialized; RPC_E_CHANGED_MODE means
  // that someone already initialized COM using a different mode. Use it, since
  // we still need to add a reference.

  if Result.HResult = RPC_E_CHANGED_MODE then
    Result.HResultAllowFalse := CoInitializeEx(nil, PreferredMode xor
      COINIT_APARTMENTTHREADED);
end;

function ComxInitializeExAuto;
var
  CallingThread: TThreadId;
begin
  Result := ComxInitializeEx(PreferredMode);

  if not Result.IsSuccess then
    Exit;

  // Record the calling thread since COM init is thread-specific
  CallingThread := NtCurrentTeb.ClientID.UniqueThread;

  Uninitializer := Auto.Delay(
    procedure
    begin
      // Make sure uninitialization runs on the same thread
      if CallingThread = NtCurrentTeb.ClientID.UniqueThread then
        CoUninitialize;
    end
  );
end;

function ComxGetApartmentType;
begin
  Result.Location := 'CoGetApartmentType';
  Result.HResult := CoGetApartmentType(ApartmentType, ApartmentQualifier);
end;

function ComxIsInitialized;
var
  ApartmentType: TAptType;
  ApartmentQualifier: TAptTypeQualifier;
begin
  Result := ComxGetApartmentType(ApartmentType, ApartmentQualifier).IsSuccess;
end;

function ComxInitializeImplicit;
var
  CookieValue: TCoMtaUsageCookie;
begin
  Result := LdrxCheckDelayedImport(delayed_CoIncrementMTAUsage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'CoIncrementMTAUsage';
  Result.HResult := CoIncrementMTAUsage(CookieValue);

  if Result.IsSuccess and Assigned(Cookie) then
    Cookie^ := CookieValue;
end;

function ComxUninitializeImplicit;
begin
  Result := LdrxCheckDelayedImport(delayed_CoDecrementMTAUsage);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'CoDecrementMTAUsage';
  Result.HResult := CoDecrementMTAUsage(Cookie);
end;

function ComxInitializeImplicitAuto;
var
  Cookie: TCoMtaUsageCookie;
begin
  Result := ComxInitializeImplicit(@Cookie);

  if Result.IsSuccess then
    Uninitializer := Auto.Delay(
      procedure
      begin
        ComxUninitializeImplicit(Cookie);
      end
    );
end;

var
  // We want to release implicit MTA reference on module unload
  ImplicitMTAInitialized: TRtlRunOnce;
  ImplicitMTAUninitializer: IAutoReleasable;

function ComxInitializeImplicitOnce;
var
  Init: IAcquiredRunOnce;
begin
  // Already called?
  if not RtlxRunOnceBegin(@ImplicitMTAInitialized, Init) then
    Exit(NtxSuccess);

  // Initialize
  Result := ComxInitializeImplicitAuto(ImplicitMTAUninitializer);

  if Result.IsSuccess then
    Init.Complete;
end;

function ComxEnsureInitialized;
var
  ApartmentType: TAptType;
  ApartmentQualifier: TAptTypeQualifier;
  PreferredMode: TCoInitMode;
begin
  // Prefer an implicit MTA reference which is compatible with existing/future
  // aparatments
  Result := ComxInitializeImplicitAuto(Uninitializer);

  if Result.IsSuccess then
    Exit;

  // Determine if we are already in an apartment
  Result := ComxGetApartmentType(ApartmentType, ApartmentQualifier);

  // Choose the mode to align with the existing one or fallback to MTA
  PreferredMode := COINIT_MULTITHREADED;

  if Result.IsSuccess then
    case ApartmentType of
      APTTYPE_MAINSTA, APTTYPE_STA:
        PreferredMode := COINIT_APARTMENTTHREADED;

      APTTYPE_MTA:
        PreferredMode := COINIT_MULTITHREADED;

      APTTYPE_NA:
        case ApartmentQualifier of
          APTTYPEQUALIFIER_NA_ON_MAINSTA, APTTYPEQUALIFIER_NA_ON_STA,
          APTTYPEQUALIFIER_APPLICATION_STA:
            PreferredMode := COINIT_APARTMENTTHREADED;

          APTTYPEQUALIFIER_NA_ON_MTA, APTTYPEQUALIFIER_NA_ON_IMPLICIT_MTA:
            PreferredMode := COINIT_MULTITHREADED;
        end;
    end;

  // Use a regular initialization reference
  Result := ComxInitializeExAuto(Uninitializer, PreferredMode);
end;

{ Base COM }

function ComxGetClassFactory;
begin
  Result.Location := 'CoGetClassObject';
  Result.LastCall.Parameter := ClassNameHint;
  Result.HResult := CoGetClassObject(Clsid, ClsContext, nil, IClassFactory,
    ClassFactory);
end;

function ComxGetClassFactoryWithFallback;
begin
  Result := ComxGetClassFactory(Clsid, ClassFactory, ClassNameHint,
    ClsContext);

  if not Result.IsSuccess then
    Result := RtlxComGetClassFactory(DllName, Clsid, ClassFactory,
      ClassNameHint);
end;

function ComxCreateInstance;
begin
  Result.Location := 'CoCreateInstance';
  Result.LastCall.Parameter := ClassNameHint;
  Result.HResult := CoCreateInstance(clsid, nil, ClsContext, iid, pv);
end;

function ComxCreateInstanceWithFallback;
begin
  Result := ComxCreateInstance(Clsid, Iid, pv, ClassNameHint, ClsContext);

  if not Result.IsSuccess then
    Result := RtlxComCreateInstance(DllName, Clsid, Iid, pv, ClassNameHint);
end;

{ Variant helpers }

function VarEmpty;
begin
  VariantInit(Result);
end;

function VarFromWord;
begin
  VariantInit(Result);
  Result.VType := varWord;
  Result.VWord := Value;
end;

function VarFromCardinal;
begin
  VariantInit(Result);
{$IF CompilerVersion >= 32}
  Result.VType := varUInt32;
  Result.VUInt32 := Value;
{$ELSE}
  Result.VType := varLongWord;
  Result.VLongWord := Value;
{$ENDIF}
end;

function VarFromInteger;
begin
  VariantInit(Result);
  Result.VType := varInteger;
  Result.VInteger := Value;
end;

function VarFromIntegerRef;
begin
  VariantInit(Result);
  Result.VType := varInteger or varByRef;
  Result.VPointer := @Value;
end;

function VarFromWideString;
begin
  VariantInit(Result);
  if Value <> '' then
  begin
    Result.VType := varOleStr;
    Result.VOleStr := PWideChar(Value);
  end;
end;

function VarFromIDispatch;
begin
  VariantInit(Result);
  Result.VType := varDispatch;
  Result.VDispatch := Pointer(Value);
end;

{ Binding helpers }

function DispxBindToObject;
var
  BindCtx: IBindCtx;
  Moniker: IMoniker;
  chEaten: Cardinal;
begin
  Result.Location := 'CreateBindCtx';
  Result.HResult := CreateBindCtx(0, BindCtx);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'MkParseDisplayName';
  Result.LastCall.Parameter := ObjectName;
  Result.HResult := MkParseDisplayName(BindCtx, StringToOleStr(ObjectName),
    chEaten, Moniker);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'IMoniker::BindToObject';
  Result.LastCall.Parameter := ObjectName;
  Result.HResult := Moniker.BindToObject(BindCtx, nil, IDispatch, Dispatch);
end;

{ IDispatch invocation helpers }

function DispxGetNameId;
var
  WideName: WideString;
begin
  WideName := Name;

  Result.Location := 'IDispatch::GetIDsOfNames';
  Result.LastCall.Parameter := Name;
  Result.HResult := Dispatch.GetIDsOfNames(GUID_NULL, @WideName, 1, 0, @DispID);
end;

function DispxInvoke;
var
  ExceptInfo: TExcepInfo;
  ArgErr: Cardinal;
begin
  Result.Location := 'IDispatch::Invoke';
  Result.HResult := Dispatch.Invoke(DispID, GUID_NULL, 0, Flags, Params,
    VarResult, @ExceptInfo, @ArgErr);

  if Result.HResult = DISP_E_EXCEPTION then
  begin
    // Execute deferred exception fill-in if necessary
    if not Assigned(ExceptInfo.pfnDeferredFillIn) or
      ExceptInfo.pfnDeferredFillIn(@ExceptInfo).IsSuccess then
      Result.LastCall.Parameter := ExceptInfo.bstrSource;

    // Prefer more specific error codes
    if not ExceptInfo.scode.IsSuccess then
      Result.HResult := ExceptInfo.scode
    else if ExceptInfo.wCode <> ERROR_SUCCESS then
      Result.Win32Error := ExceptInfo.wCode;
  end;
end;

function DispxInvokeByName;
var
  DispID: TDispID;
begin
  Result := DispxGetNameId(Dispatch, Name, DispID);

  if not Result.IsSuccess then
    Exit;

  Result := DispxInvoke(Dispatch, DispID, Flags, Params, VarResult);

  if Result.HResult <> DISP_E_EXCEPTION then
    Result.LastCall.Parameter := Name;
end;

function DispxGetProperty;
var
  Params: TDispParams;
begin
  Params := Default(TDispParams);
  VariantInit(Value);

  Result := DispxInvoke(Dispatch, DispId, DISPATCH_METHOD or
    DISPATCH_PROPERTYGET, Params, @Value);
end;

function DispxGetPropertyByName;
var
  Params: TDispParams;
begin
  Params := Default(TDispParams);
  VariantInit(Value);

  Result := DispxInvokeByName(Dispatch, Name, DISPATCH_METHOD or
    DISPATCH_PROPERTYGET, Params, @Value);
end;

function DispxSetProperty;
var
  Action: TDispID;
  Params: TDispParams;
begin
  Action := DISPID_PROPERTYPUT;

  // Prepare the parameters
  Params.rgvarg := Pointer(@Value);
  Params.rgdispidNamedArgs := Pointer(@Action);
  Params.cArgs := 1;
  Params.cNamedArgs := 1;

  Result := DispxInvoke(Dispatch, DispId, DISPATCH_PROPERTYPUT, Params, nil);
end;

function DispxSetPropertyByName;
var
  Action: TDispID;
  Params: TDispParams;
begin
  Action := DISPID_PROPERTYPUT;

  // Prepare the parameters
  Params.rgvarg := Pointer(@Value);
  Params.rgdispidNamedArgs := Pointer(@Action);
  Params.cArgs := 1;
  Params.cNamedArgs := 1;

  Result := DispxInvokeByName(Dispatch, Name, DISPATCH_PROPERTYPUT, Params, nil);
end;

function DispxCallMethod;
var
  Params: TDispParams;
begin
  // IDispatch expects method parameters to go from right to left
  Params.cArgs := Length(Parameters);
  Params.rgvarg := Pointer(TArray.Reverse<TVarData>(Parameters));
  Params.cNamedArgs := 0;
  Params.rgdispidNamedArgs := nil;

  if Assigned(VarResult) then
    VariantInit(VarResult^);

  Result := DispxInvoke(Dispatch, DispId, DISPATCH_METHOD, Params, VarResult);
end;

function DispxCallMethodByName;
var
  Params: TDispParams;
begin
  // IDispatch expects method parameters to go from right to left
  Params.cArgs := Length(Parameters);
  Params.rgvarg := Pointer(TArray.Reverse<TVarData>(Parameters));
  Params.cNamedArgs := 0;
  Params.rgdispidNamedArgs := nil;

  if Assigned(VarResult) then
    VariantInit(VarResult^);

  Result := DispxInvokeByName(Dispatch, Name, DISPATCH_METHOD, Params,
    VarResult);
end;

{ WinRT strings }

type
  TRoxAutoString = class(TCustomAutoPointer, IAutoPointer, IAutoReleasable)
    procedure Release; override;
  end;

procedure TRoxAutoString.Release;
begin
  if Assigned(FData) and LdrxCheckDelayedImport(
    delayed_WindowsDeleteString).IsSuccess then
    WindowsDeleteString(FData);

  FData := nil;
  inherited;
end;

function RoxCaptureString;
begin
  IAutoPointer(Result) := TRoxAutoString.Capture(Buffer);
end;

function RoxCreateString;
var
  Buffer: THString;
begin
  Result := LdrxCheckDelayedImport(delayed_WindowsCreateString);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'WindowsCreateString';
  Result.HResult := WindowsCreateString(PWideChar(Source),
    Length(Source), Buffer);

  if Result.IsSuccess then
    Str := RoxCaptureString(Buffer);
end;

function RoxSaveString;
var
  SourceLength: Cardinal;
begin
  if not LdrxCheckDelayedImport(delayed_WindowsGetStringRawBuffer).IsSuccess then
    Exit('');

  SetString(Result, WindowsGetStringRawBuffer(Str, @SourceLength),
    Integer(SourceLength));
end;

{ WinRT }

procedure RoxUninitialize;
begin
  if LdrxCheckDelayedImport(delayed_RoUninitialize).IsSuccess then
    RoUninitialize;
end;

function RoxInitialize;
begin
  Result := LdrxCheckDelayedImport(delayed_RoInitialize);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RoInitialize';
  Result.HResultAllowFalse := RoInitialize(InitType);

  // S_FALSE indicates that COM is already initialized; RPC_E_CHANGED_MODE means
  // that someone already initialized COM using a different mode. Use it, since
  // we still need to add a reference.

  if Result.HResult = RPC_E_CHANGED_MODE then
    Result.HResultAllowFalse := RoInitialize(TRoInitType(Cardinal(InitType) xor
      Cardinal(RO_INIT_MULTITHREADED)));
end;

function RoxInitializeAuto;
var
  CallingThread: TThreadId;
begin
  Result := RoxInitialize(InitType);

  if not Result.IsSuccess then
    Exit;

  // Record the calling thread since WinRT init is thread-specific
  CallingThread := NtCurrentTeb.ClientID.UniqueThread;

  Uninitializer := Auto.Delay(
    procedure
    begin
      // Make sure uninitialization runs on the same thread
      if CallingThread = NtCurrentTeb.ClientID.UniqueThread then
        RoxUninitialize;
    end
  );
end;

var
  // We want to release the reference on module unload
  RoxpInitialized: TRtlRunOnce;
  RoxpUninitializer: IAutoReleasable;

function RoxInitializeOnce;
var
  Init: IAcquiredRunOnce;
begin
  if not RtlxRunOnceBegin(@RoxpInitialized, Init) then
    Exit(NtxSuccess);

  Result := RoxInitializeAuto(RoxpUninitializer);

  if Result.IsSuccess then
    Init.Complete;
end;

function RoxGetActivationFactory;
var
  ActivatableClassIdStr: IHString;
begin
  Result := LdrxCheckDelayedImport(delayed_RoGetActivationFactory);

  if not Result.IsSuccess then
    Exit;

  Result := RoxCreateString(ActivatableClassId, ActivatableClassIdStr);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RoGetActivationFactory';
  Result.HResult := RoGetActivationFactory(ActivatableClassIdStr.Data,
    IActivationFactory, Factory);
end;

function RoxGetActivationFactoryWithFallback;
begin
  Result := RoxGetActivationFactory(ActivatableClassId, Factory);

  if not Result.IsSuccess then
    Result := RtlxComGetActivationFactory(DllName, ActivatableClassId, Factory);
end;

function RoxActivateInstance;
var
  ClassIdString: IHString;
begin
  Result := LdrxCheckDelayedImport(delayed_RoActivateInstance);

  if not Result.IsSuccess then
    Exit;

  Result := RoxCreateString(ActivatableClassId, ClassIdString);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'RoActivateInstance';
  Result.LastCall.Parameter := ActivatableClassId;
  Result.HResult := RoActivateInstance(ClassIdString.Data, Inspectable);
end;

function RoxActivateInstanceWithFallback;
begin
  Result := RoxActivateInstance(ActivatableClassId, Inspectable);

  if not Result.IsSuccess then
    Result := RtlxComActivateInstance(DllName, ActivatableClassId, Inspectable);
end;

end.
