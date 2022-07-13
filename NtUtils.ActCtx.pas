unit NtUtils.ActCtx;

{
  This modules provides functions for working with activation contexts.
}

interface

uses
  Ntapi.WinNt, Ntapi.actctx, Ntapi.ntrtl, Ntapi.ntpebteb, Ntapi.ImageHlp,
  DelphiApi.Reflection, NtUtils, DelphiUtils.AutoObjects;

type
  IActivationContext = IAutoPointer<PActivationContext>;

  TActxCtxDetailedInfo = record
    Flags: TActivationContextFlags;
    [Reserved(ACTIVATION_CONTEXT_DATA_FORMAT_WHISTLER)] FormatVersion: Cardinal;
    AssemblyCount: Cardinal;
    RootManifestPathType: TActivationContextPathType;
    RootManifestPath: String;
    RootConfigurationPathType: TActivationContextPathType;
    RootConfigurationPath: String;
    AppDirPathType: TActivationContextPathType;
    AppDirPath: String;
  end;

  TActxCtxAssembly = record
    [Hex] Flags: Cardinal;
    EncodedAssemblyIdentity: String;
    ManifestPathType: TActivationContextPathType;
    ManifestPath: String;
    ManifestLastWriteTime: TLargeInteger;
    PolicyPathType: TActivationContextPathType;
    PolicyPath: String;
    PolicyLastWriteTime: TLargeInteger;
    MetadataSatelliteRosterIndex: Cardinal;
    DirectoryName: String;
    FileCount: Cardinal;
  end;

// Locate the activation context
[Result: MayReturnNil]
function RtlxCurrentActivationContext(
): PActivationContext;

// Locate the activation context data
[Result: MayReturnNil]
function RtlxCurrentActivationContextData(
): PActivationContextData;

type
  ActCtx = class abstract
    // Query fixed-size activation context information
    class function Query<T>(
      InfoClass: TActivationContextInfoClass;
      out Buffer: T;
      Flags: TRtlQueryInfoActCtxFlags =
        RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_USE_ACTIVE_ACTIVATION_CONTEXT;
      [in] ActivationContext: PActivationContext = nil
    ): TNtxStatus; static;
  end;

// Query variable-size activation context information
function RtlxQueryActivationContext(
  out Buffer: IMemory;
  InfoClass: TActivationContextInfoClass;
  Flags: TRtlQueryInfoActCtxFlags =
    RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_USE_ACTIVE_ACTIVATION_CONTEXT;
  [in, opt] ActivationContext: PActivationContext = nil;
  [in] SubInstanceIndex: PActivationContextQueryIndex = nil;
  InitialLength: NativeUInt = 0
): TNtxStatus;

// Query detailed information about an activation context
function RtlxQueryDetailedInfoActivationContext(
  out Info: TActxCtxDetailedInfo;
  Flags: TRtlQueryInfoActCtxFlags =
    RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_USE_ACTIVE_ACTIVATION_CONTEXT;
  [in, opt] ActivationContext: PActivationContext = nil
): TNtxStatus;

// Retrieve information about all assemblies in an activation context
function RtlxEnumerateAssembliesActivationContext(
  out Assemblies: TArray<TActxCtxAssembly>;
  Flags: TRtlQueryInfoActCtxFlags =
    RTL_QUERY_INFORMATION_ACTIVATION_CONTEXT_FLAG_USE_ACTIVE_ACTIVATION_CONTEXT;
  [in, opt] ActivationContext: PActivationContext = nil
): TNtxStatus;

// Retrieve a string setting from an activation context
function RtlxQueryActivationContextSetting(
  [in] ActivationContext: PActivationContext;
  [opt] SettingsNameSpace: String;
  SettingName: String;
  out SettingValue: String
): TNtxStatus;

// Activate an activation context on a thread
function RtlxActivateActivationContext(
  out Deactivator: IAutoReleasable;
  [in, opt] ActivationContext: PActivationContext;
  [in, opt] Teb: PTeb = nil;
  Flags: TRtlActivateActCtxExFlags =
    RTL_ACTIVATE_ACTIVATION_CONTEXT_EX_FLAG_RELEASE_ON_STACK_DEALLOCATION
): TNtxStatus;

// Create an activation context from an activation context data
function RtlxCreateActivationContext(
  out hxActCtx: IActivationContext;
  [in] ActivationContextData: PActivationContextData;
  [opt] NotificationRoutine: TActivationContextNotifyRoutine = nil;
  [in, opt] NotificationContext: Pointer = nil;
  ExtraBytes: Cardinal = 0
): TNtxStatus;

// Create an activation context via CreateActCtxW
function AdvxCreateActivationContext(
  out hxActCtx: IActivationContext;
  Flags: TActCtxFlags;
  const Source: String;
  [in] Module: Pointer;
  [in] ResourceName: PWideChar = CREATEPROCESS_MANIFEST_RESOURCE_ID;
  const AssemblyDirectory: String = '';
  const ApplicationName: String = '';
  ProcessorArchitecture: TProcessorArchitecture = TProcessorArchitecture(0);
  LangId: Word = 0
): TNtxStatus;

implementation

uses
  Ntapi.ntmmapi, Ntapi.ntpsapi, NtUtils.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RtlxCurrentActivationContext;
var
  ActiveFrame: PRtlActivationContextStackFrame;
begin
  // Take the context from the active stack frame
  ActiveFrame := NtCurrentTeb.ActivationStack.ActiveFrame;

  if Assigned(ActiveFrame) then
    Result := ActiveFrame.ActivationContext
  else
    Result := ACTCTX_PROCESS_DEFAULT;
end;

function RtlxCurrentActivationContextData;
var
  ActiveContext: PActivationContext;
begin
  // Use the context from the current thread when available
  ActiveContext := RtlxCurrentActivationContext;

  if Assigned(ActiveContext) then
    Exit(ActiveContext.ActivationContextData);

  // Fall back to the process-wide context data
  Result := RtlGetCurrentPeb.ActivationContextData;

  // Fall back to the system=default context datat
  if not Assigned(Result) then
    Result := RtlGetCurrentPeb.SystemDefaultActivationContextData;
end;

class function ActCtx.Query<T>;
begin
  Result.Location := 'RtlQueryInformationActivationContext';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);
  Result.Status := RtlQueryInformationActivationContext(Flags,
    ActivationContext, nil, InfoClass, @Buffer, SizeOf(Buffer), nil);
end;

function RtlxQueryActivationContext;
var
  RequiredSize: NativeUInt;
begin
  Result.Location := 'RtlQueryInformationActivationContext';
  Result.LastCall.UsesInfoClass(InfoClass, icQuery);

  Buffer := Auto.AllocateDynamic(InitialLength);
  repeat
    RequiredSize := 0;
    Result.Status := RtlQueryInformationActivationContext(Flags,
      ActivationContext, SubInstanceIndex, InfoClass, Buffer.Data, Buffer.Size,
      @RequiredSize);
  until not NtxExpandBufferEx(Result, Buffer, RequiredSize, nil);

  if not Result.IsSuccess then
    Buffer := nil;
end;

function RtlxQueryDetailedInfoActivationContext;
var
  Buffer: IMemory<PActivationContextDetailedInformation>;
begin
  Result := RtlxQueryActivationContext(IMemory(Buffer),
    ActivationContextDetailedInformation, Flags, ActivationContext,
    nil, SizeOf(TActivationContextDetailedInformation));

  if not Result.IsSuccess then
    Exit;

  Info.Flags := Buffer.Data.Flags;
  Info.FormatVersion := Buffer.Data.FormatVersion;
  Info.AssemblyCount := Buffer.Data.AssemblyCount;
  Info.RootManifestPathType := Buffer.Data.RootManifestPathType;
  Info.RootConfigurationPathType := Buffer.Data.RootConfigurationPathType;
  Info.AppDirPathType := Buffer.Data.AppDirPathType;

  SetString(Info.RootManifestPath, Buffer.Data.RootManifestPath,
    Buffer.Data.RootManifestPathChars);

  SetString(Info.RootConfigurationPath, Buffer.Data.RootConfigurationPath,
    Buffer.Data.RootConfigurationPathChars);

  SetString(Info.AppDirPath, Buffer.Data.AppDirPath,
    Buffer.Data.AppDirPathChars);
end;

function RtlxEnumerateAssembliesActivationContext;
var
  Details: TActxCtxDetailedInfo;
  Buffer: IMemory<PActivationContextAssemblyDetailedInformation>;
  Index: TActivationContextQueryIndex;
  i: Integer;
begin
  // Query detailed info to determine the number of assemblies
  Result := RtlxQueryDetailedInfoActivationContext(Details, Flags,
    ActivationContext);

  if not Result.IsSuccess then
    Exit;

  SetLength(Assemblies, Details.AssemblyCount);

  for i := 0 to High(Assemblies) do
  begin
    // Assembly indexes are 1-based
    Index.AssemblyIndex := i + 1;

    // Query each assembly
    Result := RtlxQueryActivationContext(IMemory(Buffer),
      AssemblyDetailedInformationInActivationContext, Flags,
      ActivationContext, @Index);

    if not Result.IsSuccess then
      Exit;

    Assemblies[i].Flags := Buffer.Data.Flags;
    Assemblies[i].ManifestPathType := Buffer.Data.PolicyPathType;
    Assemblies[i].ManifestLastWriteTime := Buffer.Data.ManifestLastWriteTime;
    Assemblies[i].PolicyPathType := Buffer.Data.PolicyPathType;
    Assemblies[i].PolicyLastWriteTime := Buffer.Data.PolicyLastWriteTime;
    Assemblies[i].MetadataSatelliteRosterIndex :=
      Buffer.Data.MetadataSatelliteRosterIndex;
    Assemblies[i].FileCount := Buffer.Data.FileCount;

    SetString(Assemblies[i].EncodedAssemblyIdentity,
      Buffer.Data.AssemblyEncodedAssemblyIdentity,
      Buffer.Data.EncodedAssemblyIdentityLength div SizeOf(WideChar));

    SetString(Assemblies[i].ManifestPath,
      Buffer.Data.AssemblyManifestPath,
      Buffer.Data.ManifestPathLength div SizeOf(WideChar));

    SetString(Assemblies[i].PolicyPath,
      Buffer.Data.AssemblyPolicyPath,
      Buffer.Data.PolicyPathLength div SizeOf(WideChar));

    SetString(Assemblies[i].DirectoryName,
      Buffer.Data.AssemblyDirectoryName,
      Buffer.Data.AssemblyDirectoryNameLength div SizeOf(WideChar));
  end;
end;

function RtlxQueryActivationContextSetting;
var
  Buffer: IMemory<PWideChar>;
  RequiredChars: NativeUInt;
begin
  Result.Location := 'RtlQueryActivationContextApplicationSettings';
  // TODO: LastCall string info

  IMemory(Buffer) := Auto.AllocateDynamic(64);
  repeat
    Result.Status := RtlQueryActivationContextApplicationSettings(0,
      ActivationContext, RefStrOrNil(SettingsNameSpace), PWideChar(SettingName),
      Buffer.Data, Buffer.Size div SizeOf(WideChar), @RequiredChars);
  until not NtxExpandBufferEx(Result, IMemory(Buffer), RequiredChars *
    SizeOf(WideChar), nil);

  // Capture the result
  if Result.IsSuccess then
    SettingValue := RtlxCaptureString(Buffer.Data,
      Buffer.Size div SizeOf(WideChar));
end;

function RtlxDelayedDeactivateActivationContext(
  Cookie: NativeUInt
): IAutoReleasable;
begin
  Result := Auto.Delay(
    procedure
    begin
      RtlDeactivateActivationContext(0, Cookie);
    end
  );
end;

function RtlxActivateActivationContext;
var
  Cookie: NativeUInt;
begin
  if not Assigned(Teb) then
    Teb := NtCurrentTeb;

  Result.Location := 'RtlActivateActivationContextEx';
  Result.Status := RtlActivateActivationContextEx(Flags, Teb, ActivationContext,
    Cookie);

  if Result.IsSuccess then
    Deactivator := RtlxDelayedDeactivateActivationContext(Cookie);
end;

type
  TAutoActivationContext = class (TCustomAutoPointer, IAutoPointer)
    procedure Release; override;
  end;

procedure TAutoActivationContext.Release;
begin
  if Assigned(FData) then
    RtlReleaseActivationContext(FData);

  FData := nil;
  inherited;
end;

procedure RtlxDefaultActivationContextNotification(
  NotificationType: TActivationContextNotification;
  [in] ActivationContext: PActivationContext;
  [in] ActivationContextData: PActivationContextData;
  [in] NotificationContext: Pointer;
  [in] NotificationData: Pointer;
  var DisableThisNotification: Boolean
); stdcall;
begin
  // Reproduce behavior of kernel32.BasepSxsActivationContextNotification
  if NotificationType = ACTIVATION_CONTEXT_NOTIFICATION_DESTROY then
    NtUnmapViewOfSection(NtCurrentProcess, ActivationContextData)
  else
    DisableThisNotification := True;
end;

function RtlxCreateActivationContext;
var
  hActCtx: PActivationContext;
begin
  if not Assigned(NotificationRoutine) then
    NotificationRoutine := RtlxDefaultActivationContextNotification;

  Result.Location := 'RtlCreateActivationContext';
  Result.Status := RtlCreateActivationContext(0, ActivationContextData,
    ExtraBytes, NotificationRoutine, NotificationContext, hActCtx);

  if Result.IsSuccess then
    IAutoPointer(hxActCtx) := TAutoActivationContext.Capture(hActCtx);
end;

function AdvxCreateActivationContext;
var
  ActCtx: TActCtxW;
  hActCtx: PActivationContext;
begin
  ActCtx := Default(TActCtxW);
  ActCtx.Size := SizeOf(ActCtx);
  ActCtx.Flags := Flags;
  ActCtx.Source := RefStrOrNil(Source);
  ActCtx.ProcessorArchitecture := ProcessorArchitecture;
  ActCtx.LangId := LangId;
  ActCtx.AssemblyDirectory := RefStrOrNil(AssemblyDirectory);
  ActCtx.ResourceName := ResourceName;
  ActCtx.ApplicationName := RefStrOrNil(ApplicationName);
  ActCtx.hModule := HModule(Module);

  Result.Location := 'CreateActCtxW';
  hActCtx := CreateActCtxW(ActCtx);
  Result.Win32Result := hActCtx <> INVALID_ACTIVATION_CONTEXT;

  if Result.IsSuccess then
    IAutoPointer(hxActCtx) := TAutoActivationContext.Capture(hActCtx);
end;

end.
