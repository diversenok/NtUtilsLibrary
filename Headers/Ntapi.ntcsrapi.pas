unit Ntapi.ntcsrapi;

{
  This module includes definitions for sending messages to CSRSS from Native API
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ntlpcapi, DelphiApi.Reflection;

const
  BASESRV_SERVERDLL_INDEX = 1;

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
    MessagePointerOffsets: TAnysizeArray<NativeUInt>;
  end;

  [SDKName('CSR_API_MSG')]
  TCsrApiMsg = record
    h: TPortMessage;
    CaptureBuffer: PCsrCaptureHeader;
    ApiNumber: TCsrApiNumber;
    ReturnValue: NTSTATUS;
    [Reserved] Reserved: Cardinal;
    ApiMessageData: TPlaceholder;
  end;
  PCsrApiMsg = ^TCsrApiMsg;
  PPCsrApiMsg = ^PCsrApiMsg;

  [SDKName('BASESRV_API_NUMBER')]
  [NamingStyle(nsCamelCase, 'Basep'), ValidMask($7EFFFFE1)]
  TBaseSrvApiNumber = (
    BasepCreateProcess = $0,
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
    BasepCreateActivationContext = $17,
    [Reserved] BasepDeadEntry24 = $18,
    BasepRegisterThread = $19,
    BasepDeferredCreateProcess = $1A,
    BasepNlsGetUserInfo = $1B,
    BasepNlsUpdateCacheCount = $1C,
    BasepCreateProcess2 = $1D,           // at least Win 10+
    BasepCreateActivationContext2 = $1E  // at least Win 10+
  );

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

[SDKName('CSR_MAKE_API_NUMBER')]
function CsrMakeApiNumber(
  DllIndex: Word;
  ApiIndex: Word
): TCsrApiNumber;

function CsrGetProcessId(
): TProcessId; stdcall external ntdll;

[Result: Allocates('CsrFreeCaptureBuffer')]
function CsrAllocateCaptureBuffer(
  [in] CountMessagePointers: Cardinal;
  [in] Size: Cardinal
): PCsrCaptureHeader; stdcall external ntdll;

procedure CsrFreeCaptureBuffer(
  [in] CaptureBuffer: PCsrCaptureHeader
); stdcall external ntdll;

[Result: Counter(ctBytes)]
function CsrAllocateMessagePointer(
  [in, out] CaptureBuffer: PCsrCaptureHeader;
  [Counter(ctBytes)] Length: Cardinal;
  out MessagePointer: Pointer
): Cardinal; stdcall; external ntdll;

procedure CsrCaptureMessageBuffer(
  [in, out] CaptureBuffer: PCsrCaptureHeader;
  [in, opt] Buffer: Pointer;
  Length: Cardinal;
  out CapturedBuffer: Pointer
); stdcall; external ntdll;

procedure CsrCaptureMessageString(
  [in, out] CaptureBuffer: PCsrCaptureHeader;
  StringData: PWideChar;
  [Counter(ctBytes)] Length: Cardinal;
  [Counter(ctBytes)] MaximumLength: Cardinal;
  out CapturedString: TNtUnicodeString // Can also be TNtAnsiString
); stdcall; external ntdll;

function CsrCaptureMessageMultiUnicodeStringsInPlace(
  [Allocates('CsrFreeCaptureBuffer')] var CaptureBuffer: PCsrCaptureHeader;
  NumberOfStringsToCapture: Cardinal;
  const StringsToCapture: TArray<PNtUnicodeString>
): NTSTATUS; stdcall; external ntdll;

function CsrClientCallServer(
  var m: TCsrApiMsg;
  [in, out, opt] CaptureBuffer: PCsrCaptureHeader;
  ApiNumber: TCsrApiNumber;
  ArgLength: Cardinal
): NTSTATUS; stdcall; external ntdll;

function CsrClientConnectToServer(
  [in] ObjectDirectory: PWideChar;
  ServertDllIndex: Cardinal;
  [in, opt] ConnectionInformation: Pointer;
  ConnectionInformationLength: Cardinal;
  [out, opt] CalledFromServer: PBoolean
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntrtl.h
function RtlRegisterThreadWithCsrss(
): NTSTATUS; stdcall; external ntdll;

implementation

function CsrMakeApiNumber;
begin
  Result := (DllIndex shl 16) or ApiIndex;
end;

end.
