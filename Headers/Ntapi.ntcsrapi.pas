unit Ntapi.ntcsrapi;

{
  This module includes definitions for sending messages to CSRSS from Native API
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntlpcapi, Ntapi.ntrtl, Ntapi.ntpebteb,
  Ntapi.actctx, Ntapi.Versions, DelphiApi.Reflection;

const
  // private
  BASESRV_SERVERDLL_INDEX = 1;

  // rev - bits in process & thread handles for process creation events
  BASE_CREATE_PROCESS_MSG_PROCESS_FLAG_FEEDBACK_ON = $1;
  BASE_CREATE_PROCESS_MSG_PROCESS_FLAG_GUI_WAIT = $2;
  BASE_CREATE_PROCESS_MSG_THREAD_FLAG_CROSS_SESSION = $1;
  BASE_CREATE_PROCESS_MSG_THREAD_FLAG_PROTECTED_PROCESS = $2;

  // private - VDM binary types
  BINARY_TYPE_DOS = $10;
  BINARY_TYPE_WIN16 = $20;
  BINARY_TYPE_SEPWOW = $40;
  BINARY_SUBTYPE_MASK = $0F;
  BINARY_TYPE_DOS_EXE = $01;
  BINARY_TYPE_DOS_COM = $02;
  BINARY_TYPE_DOS_PIF = $03;

  // private - CreateProcess SxS message flags
  BASE_MSG_SXS_MANIFEST_PRESENT = $0001;
  BASE_MSG_SXS_POLICY_PRESENT = $0002;
  BASE_MSG_SXS_SYSTEM_DEFAULT_TEXTUAL_ASSEMBLY_IDENTITY_PRESENT = $0004;
  BASE_MSG_SXS_TEXTUAL_ASSEMBLY_IDENTITY_PRESENT = $0008;
  BASE_MSG_SXS_NO_ISOLATION = $0020; // rev
  BASE_MSG_SXS_REMOTE = $0040; // rev
  BASE_MSG_SXS_DEV_OVERRIDE_PRESENT = $0080; // rev
  BASE_MSG_SXS_MANIFEST_OVERRIDE_PRESENT = $0100; // rev
  BASE_MSG_SXS_PACKAGE_IDENTITY_PRESENT = $0400; // rev
  BASE_MSG_SXS_FULL_TRUST_INTEGRITY_PRESENT = $0800; // rev

  // rev
  DEFAULT_CULTURE_FALLBACKS: String = 'en-US'#0#0#0#0#0;

  // SDK::WinBase.h - shutdown parameters flags
  SHUTDOWN_NORETRY = $00000001;

  // SDK::WinBase.h - DOS device flags
  DDD_RAW_TARGET_PATH = $00000001;
  DDD_REMOVE_DEFINITION = $00000002;
  DDD_EXACT_MATCH_ON_REMOVE = $00000004;
  DDD_NO_BROADCAST_SYSTEM = $00000008;
  DDD_LUID_BROADCAST_DRIVE = $00000010;

type
  [SDKName('CSR_API_NUMBER')]
  TCsrApiNumber = type Cardinal;

  PCsrCaptureHeader = ^TCsrCaptureHeader;

  [SDKName('CSR_CAPTURE_HEADER')]
  TCsrCaptureHeader = record
    Length: Cardinal;
    RelatedCaptureBuffer: PCsrCaptureHeader;
    CountMessagePointers: Cardinal;
    FreeSpace: Pointer;
    [Offset] MessagePointerOffsets: TAnysizeArray<NativeUInt>;
  end;

  [SDKName('CSR_API_MSG')]
  TCsrApiMsg = record
    h: TPortMessage;
    CaptureBuffer: PCsrCaptureHeader;
    ApiNumber: TCsrApiNumber;
    ReturnValue: NTSTATUS;
    [Unlisted] Reserved: Cardinal;
    ApiMessageData: TPlaceholder;
  end;
  PCsrApiMsg = ^TCsrApiMsg;
  PPCsrApiMsg = ^PCsrApiMsg;

  [SDKName('BASESRV_API_NUMBER')]
  [NamingStyle(nsCamelCase, 'Basep'), ValidBits([0, 5..23, 25..30])]
  TBaseSrvApiNumber = (
    BasepCreateProcess = $0,             // in: TBaseCreateProcessMsgV1
    [Reserved] BasepDeadEntry1 = $1,
    [Reserved] BasepDeadEntry2 = $2,
    [Reserved] BasepDeadEntry3 = $3,
    [Reserved] BasepDeadEntry4 = $4,
    BasepCheckVDM = $5,
    BasepUpdateVDMEntry = $6,
    BasepGetNextVDMCommand = $7,
    BasepExitVDM = $8,
    BasepIsFirstVDM = $9,
    BasepGetVDMExitCode = $A,
    BasepSetReenterCount = $B,
    BasepSetProcessShutdownParam = $C,   // in: TBaseShutdownParamMsg
    BasepGetProcessShutdownParam = $D,   // out: TBaseShutdownParamMsg
    BasepSetVDMCurDirs = $E,
    BasepGetVDMCurDirs = $F,
    BasepBatNotification = $10,
    BasepRegisterWowExec = $11,
    BasepSoundSentryNotification = $12,
    BasepRefreshIniFileMapping = $13,
    BasepDefineDosDevice = $14,          // in: TBaseDefineDosDeviceMsg
    BasepSetTermsrvAppInstallMode = $15,
    BasepSetTermsrvClientTimeZone = $16,
    BasepCreateActivationContext = $17,  // in/out: TBaseSxsCreateActivationContextMsg
    [Reserved] BasepDeadEntry24 = $18,
    BasepRegisterThread = $19,
    BasepDeferredCreateProcess = $1A,
    BasepNlsGetUserInfo = $1B,
    BasepNlsUpdateCacheCount = $1C,
    BasepCreateProcess2 = $1D,           // in: TBaseCreateProcessMsgV2, Win 10 20H1+
    BasepCreateActivationContext2 = $1E  // in/out: TBaseSxsCreateActivationContextMsgV2, Win 10 20H1+
  );

  { Common }

  [FlagName(BINARY_TYPE_DOS, 'DOS')]
  [FlagName(BINARY_TYPE_WIN16, 'Win16')]
  [FlagName(BINARY_TYPE_SEPWOW, 'Separate WoW')]
  [SubEnum(BINARY_SUBTYPE_MASK, BINARY_TYPE_DOS_EXE, 'DOS EXE')]
  [SubEnum(BINARY_SUBTYPE_MASK, BINARY_TYPE_DOS_COM, 'DOS COM')]
  [SubEnum(BINARY_SUBTYPE_MASK, BINARY_TYPE_DOS_PIF, 'DOS PIF')]
  TBaseVdmBinaryType = type Cardinal;

  [FlagName(BASE_MSG_SXS_MANIFEST_PRESENT, 'Manifest Present')]
  [FlagName(BASE_MSG_SXS_POLICY_PRESENT, 'Policy Present')]
  [FlagName(BASE_MSG_SXS_SYSTEM_DEFAULT_TEXTUAL_ASSEMBLY_IDENTITY_PRESENT, 'System Default Textual Assembly Identity Present')]
  [FlagName(BASE_MSG_SXS_TEXTUAL_ASSEMBLY_IDENTITY_PRESENT, 'Textual Assembly Identity Present')]
  [FlagName(BASE_MSG_SXS_NO_ISOLATION, 'No Isolation')]
  [FlagName(BASE_MSG_SXS_REMOTE, 'Remotes')]
  [FlagName(BASE_MSG_SXS_DEV_OVERRIDE_PRESENT, 'Dev Override Present')]
  [FlagName(BASE_MSG_SXS_MANIFEST_OVERRIDE_PRESENT, 'Manifest Override Present')]
  [FlagName(BASE_MSG_SXS_PACKAGE_IDENTITY_PRESENT, 'Package Identity Present')]
  [FlagName(BASE_MSG_SXS_FULL_TRUST_INTEGRITY_PRESENT, 'Full Trust Integrity Present')]
  TBaseMsgSxsFlags = type Cardinal;

  {$MINENUMSIZE 1}
  [NamingStyle(nsSnakeCase, 'BASE_MSG_FILETYPE')]
  TBaseMsgFileType = (
    BASE_MSG_FILETYPE_NONE = 0,
    BASE_MSG_FILETYPE_XML = 1,
    BASE_MSG_FILETYPE_PRECOMPILED_XML = 2
  );
  {$MINENUMSIZE 4}

  {$MINENUMSIZE 1}
  [NamingStyle(nsSnakeCase, 'BASE_MSG_PATHTYPE')]
  TBaseMsgPathType = (
    BASE_MSG_PATHTYPE_NONE = 0,
    BASE_MSG_PATHTYPE_FILE = 1,
    BASE_MSG_PATHTYPE_URL = 2,
    BASE_MSG_PATHTYPE_OVERRIDE = 3
  );
  {$MINENUMSIZE 4}

  {$MINENUMSIZE 1}
  [NamingStyle(nsSnakeCase, 'BASE_MSG_HANDLETYPE')]
  TBaseMsgHandleType = (
    BASE_MSG_HANDLETYPE_NONE = 0,
    BASE_MSG_HANDLETYPE_PROCESS = 1,
    BASE_MSG_HANDLETYPE_CLIENT_PROCESS = 2,
    BASE_MSG_HANDLETYPE_SECTION = 3
  );
  {$MINENUMSIZE 4}

  // private
  [SDKName('BASE_MSG_SXS_STREAM')]
  TBaseMsgSxsStream = record
    FileType: TBaseMsgFileType;
    PathType: TBaseMsgPathType;
    HandleType: TBaseMsgHandleType;
    Path: TNtUnicodeString;
    FileHandle: THandle;
    Handle: THandle;
    [Offset] Offset: UInt64;
    [Bytes] Size: NativeUInt;
  end;
  PBaseMsgSxsStream = ^TBaseMsgSxsStream;

  { API number 0x00 }

  // private & rev
  [SDKName('BASE_SXS_CREATEPROCESS_MSG_REMOTE')]
  TBaseSxsCreateProcessMsgRemote = record
    Manifest: TBaseMsgSxsStream;
    Policy: TBaseMsgSxsStream;
    AssemblyDirectory: TNtUnicodeString;
  end;
  PBaseSxsCreateProcessMsgRemote = ^TBaseSxsCreateProcessMsgRemote;

  // private
  [SDKName('BASE_SXS_CREATEPROCESS_MSG_LOCAL_DISK')]
  TBaseSxsCreateProcessMsgAlt = record
    FileHandle: THandle;
    SxsWin32ExePath: TNtUnicodeString;
    SxsNtExePath: TNtUnicodeString;
    [Offset] OverrideManifestOffset: UInt64;
    [Bytes] OverrideManifestSize: NativeUInt;
    [Offset] OverridePolicyOffset: UInt64;
    [Bytes] OverridePolicySize: NativeUInt;
    [Hex] PEManifestAddress: UInt64;
    [Bytes] PEManifestSize: Cardinal;
  end;
  PBaseSxsCreateProcessMsgAlt = ^TBaseSxsCreateProcessMsgAlt;

  // private
  TBaseSxsCreateProcessMsgUnion = record
  case Cardinal of
    $FFBF: (Local: TBaseSxsCreateProcessMsgRemote); // Flags NOT containing 0x40
    $0040: (Remote: TBaseSxsCreateProcessMsgAlt); // Flags containing 0x40
  end;
  PBaseSxsCreateProcessMsgUnion = ^TBaseSxsCreateProcessMsgUnion;

  // private
  [SDKName('SUPPORTED_OS_INFO')]
  TSupportedOsInfo = record
    MajorVersion: Word;
    MinorVersion: Word;
  end;
  PSupportedOsInfo = ^TSupportedOsInfo;

  // private & rev - version for Win 7, 8, 8.1, 10 19H1, and 10 19H2
  [SDKName('BASE_SXS_CREATEPROCESS_MSG')]
  TBaseSxsCreateProcessMsgWin7 = record
    Flags: TBaseMsgSxsFlags;
    ProcessParameterFlags: TRtlUserProcessFlags;
    Union: TBaseSxsCreateProcessMsgUnion;
    CultureFallbacks: TNtUnicodeString;
    RunLevel: TActivationContextRunLevelInformation;
    SupportedOsInfo: TSupportedOsInfo;
    Padding: UInt64; // <-- the field that breaks layout
    AssemblyName: TNtUnicodeString;
  end;
  PBaseSxsCreateProcessMsgWin7 = ^TBaseSxsCreateProcessMsgWin7;

  // private - version for Win 10 (except 19H1 & 19H2), Win 11
  [SDKName('BASE_SXS_CREATEPROCESS_MSG')]
  TBaseSxsCreateProcessMsg = record
    Flags: TBaseMsgSxsFlags;
    ProcessParameterFlags: TRtlUserProcessFlags;
    Union: TBaseSxsCreateProcessMsgUnion;
    CultureFallbacks: TNtUnicodeString;
    RunLevel: TActivationContextRunLevelInformation;
    SupportedOsInfo: TSupportedOsInfo;
    AssemblyName: TNtUnicodeString;
  end;
  PBaseSxsCreateProcessMsg = ^TBaseSxsCreateProcessMsg;

  // private & rev - version for Win 7, 8, 8.1, 10 19H1, and 10 19H2
  [SDKName('BASE_CREATEPROCESS_MSG')]
  TBaseCreateProcessMsgV1Win7 = record
    CsrMessage: TCsrApiMsg; // Embedded for convenience
    ProcessHandle: THandle; // mixed with BASE_CREATE_PROCESS_MSG_PROCESS_*
    ThreadHandle: THandle;  // mixed with BASE_CREATE_PROCESS_MSG_THREAD_*
    ClientID: TClientId;
    CreationFlags: Cardinal;
    VdmBinaryType: TBaseVdmBinaryType;
    VdmTask: Cardinal;
    hVDM: TProcessId;
    Sxs: TBaseSxsCreateProcessMsgWin7;
    PebAddressNative: UInt64;
    PebAddressWow64: UIntPtr;
    ProcessorArchitecture: TProcessorArchitecture16;
  end;
  PBaseCreateProcessMsgV1Win7 = ^TBaseCreateProcessMsgV1Win7;

  // private - version for Win 10 (except 19H1 & 19H2), Win 11
  [SDKName('BASE_CREATEPROCESS_MSG')]
  TBaseCreateProcessMsgV1 = record
    CsrMessage: TCsrApiMsg; // Embedded for convenience
    ProcessHandle: THandle; // mixed with BASE_CREATE_PROCESS_MSG_PROCESS_*
    ThreadHandle: THandle;  // mixed with BASE_CREATE_PROCESS_MSG_THREAD_*
    ClientID: TClientId;
    CreationFlags: Cardinal;
    VdmBinaryType: TBaseVdmBinaryType;
    VdmTask: Cardinal;
    hVDM: TProcessId;
    Sxs: TBaseSxsCreateProcessMsg;
    PebAddressNative: UInt64;
    PebAddressWow64: UIntPtr;
    ProcessorArchitecture: TProcessorArchitecture16;
  end;
  PBaseCreateProcessMsgV1 = ^TBaseCreateProcessMsgV1;

  { API numbers 0x0C & 0x0D }

  [FlagName(SHUTDOWN_NORETRY, 'No Retry')]
  TShutdownParamFlags = type Cardinal;

  // API number 0xC & 0xD
  [SDKName('BASE_SHUTDOWNPARAM_MSG')]
  TBaseShutdownParamMsg = record
    CsrMessage: TCsrApiMsg; // Embedded for convenience
    ShutdownLevel: Cardinal;
    ShutdownFlags: TShutdownParamFlags;
  end;
  PBaseShutdownParamMsg = ^TBaseShutdownParamMsg;

  {  API number 0x14 }

  [FlagName(DDD_RAW_TARGET_PATH, 'Raw Target Path')]
  [FlagName(DDD_REMOVE_DEFINITION, 'Remove Definition')]
  [FlagName(DDD_EXACT_MATCH_ON_REMOVE, 'Exact Match On Remove')]
  [FlagName(DDD_NO_BROADCAST_SYSTEM, 'No Broadcast System')]
  [FlagName(DDD_LUID_BROADCAST_DRIVE, 'LUID Broadcast Drive')]
  TDefineDosDeviceFlags = type Cardinal;

  // API number 0x14
  [SDKName('BASE_DEFINEDOSDEVICE_MSG')]
  TBaseDefineDosDeviceMsg = record
    CsrMessage: TCsrApiMsg; // Embedded for convenience
    Flags: TDefineDosDeviceFlags;
    DeviceName: TNtUnicodeString;
    TargetPath: TNtUnicodeString;
  end;
  PBaseDefineDosDeviceMsg = ^TBaseDefineDosDeviceMsg;

  // private - API number 0x17
  [SDKName('BASE_SXS_CREATE_ACTIVATION_CONTEXT_MSG')]
  TBaseSxsCreateActivationContextMsg = record
    CsrMessage: TCsrApiMsg; // Embedded for convenience
    Flags: TBaseMsgSxsFlags;
    ProcessorArchitecture: TProcessorArchitecture16;
    CultureFallbacks: TNtUnicodeString;
    Manifest: TBaseMsgSxsStream;
    Policy: TBaseMsgSxsStream;
    AssemblyDirectory: TNtUnicodeString;
    TextualAssemblyIdentity: TNtUnicodeString;
    FileTime: TLargeInteger;
    ResourceName: PWideChar;
    ActivationContextData: PPActivationContextData;
    RunLevel: TActivationContextRunLevelInformation;
    SupportedOsInfo: TSupportedOsInfo;
    AssemblyName: TNtUnicodeString;
  end;
  PBaseSxsCreateActivationContextMsg = ^TBaseSxsCreateActivationContextMsg;

  { API number 0x1D }

  // rev - API number 0x1D
  [MinOSVersion(OsWin1020H1)]
  TBaseCreateProcessMsgV2 = record
    CsrMessage: TCsrApiMsg; // Embedded for convenience
    ProcessHandle: THandle; // mixed with BASE_CREATE_PROCESS_MSG_PROCESS_*
    ThreadHandle: THandle;  // mixed with BASE_CREATE_PROCESS_MSG_THREAD_*
    ClientID: TClientId;
    CreationFlags: Cardinal;
    VdmBinaryType: TBaseVdmBinaryType;
    VdmTask: Cardinal;
    hVDM: TProcessId;
    Sxs: TBaseSxsCreateProcessMsg;
    SxsExtension: array [0..66] of Cardinal;
    PebAddressNative: UInt64;
    PebAddressWow64: UIntPtr;
    ProcessorArchitecture: TProcessorArchitecture16;
  end;
  PBaseCreateProcessMsgV2 = ^TBaseCreateProcessMsgV2;

  { API Number 0x1E }

  // rev - API number 0x1E
  TBaseSxsCreateActivationContextMsgV2 = record
    V1: TBaseSxsCreateActivationContextMsg;
    Extension: array [0..66] of Cardinal;
  end;
  PBaseSxsCreateActivationContextMsgV2 = ^TBaseSxsCreateActivationContextMsgV2;

[SDKName('CSR_MAKE_API_NUMBER')]
function CsrMakeApiNumber(
  [in] DllIndex: Word;
  [in] ApiIndex: Word
): TCsrApiNumber;

function CsrGetProcessId(
): TProcessId; stdcall external ntdll;

[Result: ReleaseWith('CsrFreeCaptureBuffer')]
function CsrAllocateCaptureBuffer(
  [in, NumberOfElements] CountMessagePointers: Cardinal;
  [in, NumberOfBytes] Size: Cardinal
): PCsrCaptureHeader; stdcall external ntdll;

procedure CsrFreeCaptureBuffer(
  [in] CaptureBuffer: PCsrCaptureHeader
); stdcall external ntdll;

[Result: NumberOfBytes]
function CsrAllocateMessagePointer(
  [in, out] CaptureBuffer: PCsrCaptureHeader;
  [in, NumberOfBytes] Length: Cardinal;
  [out] out MessagePointer: Pointer
): Cardinal; stdcall; external ntdll;

procedure CsrCaptureMessageBuffer(
  [in, out] CaptureBuffer: PCsrCaptureHeader;
  [in, opt, ReadsFrom] Buffer: Pointer;
  [in, NumberOfBytes] Length: Cardinal;
  [out] out CapturedBuffer: Pointer
); stdcall; external ntdll;

procedure CsrCaptureMessageString(
  [in, out] CaptureBuffer: PCsrCaptureHeader;
  [in, ReadsFrom] StringData: PWideChar;
  [in, NumberOfBytes] Length: Cardinal;
  [in, NumberOfBytes] MaximumLength: Cardinal;
  [out] out CapturedString: TNtUnicodeString // Can also be TNtAnsiString
); stdcall; external ntdll;

function CsrCaptureMessageMultiUnicodeStringsInPlace(
  [in, out, ReleaseWith('CsrFreeCaptureBuffer')]
    var CaptureBuffer: PCsrCaptureHeader;
  [in, NumberOfElements] NumberOfStringsToCapture: Cardinal;
  [in, ReadsFrom] const StringsToCapture: TArray<PNtUnicodeString>
): NTSTATUS; stdcall; external ntdll;

function CsrClientCallServer(
  [in, out, ReadsFrom, WritesTo] var m: TCsrApiMsg;
  [in, out, opt] CaptureBuffer: PCsrCaptureHeader;
  [in] ApiNumber: TCsrApiNumber;
  [in, NumberOfBytes] ArgLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function CsrClientConnectToServer(
  [in] ObjectDirectory: PWideChar;
  [in] ServerDllIndex: Cardinal;
  [in, opt, ReadsFrom] ConnectionInformation: Pointer;
  [in, NumberOfBytes] ConnectionInformationLength: Cardinal;
  [out, opt] CalledFromServer: PBoolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlRegisterThreadWithCsrss(
): NTSTATUS; stdcall; external ntdll;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function CsrMakeApiNumber;
begin
  Result := (DllIndex shl 16) or ApiIndex;
end;

end.
