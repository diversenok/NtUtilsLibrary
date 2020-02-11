unit Ntapi.ntldr;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, DelphiApi.Reflection;

const
  LDRP_PACKAGED_BINARY = $00000001;
  LDRP_STATIC_LINK = $00000002;
  LDRP_IMAGE_DLL = $00000004;
  LDRP_LOAD_IN_PROGRESS = $00001000;
  LDRP_UNLOAD_IN_PROGRESS = $00002000;
  LDRP_ENTRY_PROCESSED = $00004000;
  LDRP_ENTRY_INSERTED = $00008000;
  LDRP_CURRENT_LOAD = $00010000;
  LDRP_FAILED_BUILTIN_LOAD = $00020000;
  LDRP_DONT_CALL_FOR_THREADS = $00040000;
  LDRP_PROCESS_ATTACH_CALLED = $00080000;
  LDRP_DEBUG_SYMBOLS_LOADED = $00100000;
  LDRP_IMAGE_NOT_AT_BASE = $00200000;
  LDRP_COR_IMAGE = $00400000;
  LDRP_DONT_RELOCATE = $00800000;
  LDRP_SYSTEM_MAPPED = $01000000;
  LDRP_IMAGE_VERIFYING = $02000000;
  LDRP_DRIVER_DEPENDENT_DLL = $04000000;
  LDRP_ENTRY_NATIVE = $08000000;
  LDRP_REDIRECTED = $10000000;
  LDRP_NON_PAGED_DEBUG_INFO = $20000000;
  LDRP_MM_LOADED = $40000000;
  LDRP_COMPAT_DATABASE_PROCESSED = $80000000;

  LdrEntryFlagNames: array [0..22] of TFlagName = (
    (Value: LDRP_PACKAGED_BINARY; Name: 'Packaged Binary'),
    (Value: LDRP_STATIC_LINK; Name: 'Static Link'),
    (Value: LDRP_IMAGE_DLL; Name: 'Image DLL'),
    (Value: LDRP_LOAD_IN_PROGRESS; Name: 'Load In Progress'),
    (Value: LDRP_UNLOAD_IN_PROGRESS; Name: 'Unload In Progress'),
    (Value: LDRP_ENTRY_PROCESSED; Name: 'Entry Processed'),
    (Value: LDRP_ENTRY_INSERTED; Name: 'Entry Inserted'),
    (Value: LDRP_CURRENT_LOAD; Name: 'Current Load'),
    (Value: LDRP_FAILED_BUILTIN_LOAD; Name: 'Failed Builtin Load'),
    (Value: LDRP_DONT_CALL_FOR_THREADS; Name: 'Don''t Call For Threads'),
    (Value: LDRP_PROCESS_ATTACH_CALLED; Name: 'Process Attach Called'),
    (Value: LDRP_DEBUG_SYMBOLS_LOADED; Name: 'Debug Symbold Loaded'),
    (Value: LDRP_IMAGE_NOT_AT_BASE; Name: 'Image Not At Base'),
    (Value: LDRP_COR_IMAGE; Name: 'COR Image'),
    (Value: LDRP_DONT_RELOCATE; Name: 'Don''t Relocate'),
    (Value: LDRP_SYSTEM_MAPPED; Name: 'System Mapped'),
    (Value: LDRP_IMAGE_VERIFYING; Name: 'Image Verifying'),
    (Value: LDRP_DRIVER_DEPENDENT_DLL; Name: 'Driver Dependent DLL'),
    (Value: LDRP_ENTRY_NATIVE; Name: 'Entry Native'),
    (Value: LDRP_REDIRECTED; Name: 'Redirected'),
    (Value: LDRP_NON_PAGED_DEBUG_INFO; Name: 'Non-paged Debug Info'),
    (Value: LDRP_MM_LOADED; Name: 'MM Loaded'),
    (Value: LDRP_COMPAT_DATABASE_PROCESSED; Name: 'Compat Database Processed')
  );

  LDR_LOCK_LOADER_LOCK_FLAG_RAISE_ON_ERRORS =  $00000001;
  LDR_LOCK_LOADER_LOCK_FLAG_TRY_ONLY = $00000002;

type
  // ntdef
  PRtlBalancedNode = ^TRtlBalancedNode;
  TRtlBalancedNode = record
    Left: PRtlBalancedNode;
    Right: PRtlBalancedNode;
    ParentValue: NativeUInt;
  end;

  [NamingStyle(nsCamelCase, 'LoadReason')]
  TLdrDllLoadReason = (
    LoadReasonStaticDependency,
    LoadReasonStaticForwarderDependency,
    LoadReasonDynamicForwarderDependency,
    LoadReasonDelayedLoadDependency,
    LoadReasonDynamicLoad,
    LoadReasonAsImageLoad,
    LoadReasonAsDataLoad,
    LoadReasonEnclavePrimary,
    LoadReasonEnclaveDependency
  );

  TLdrEntryFlagProvider = class(TCustomFlagProvider)
    class function Flags: TFlagNames; override;
  end;

  TLdrDataTableEntry = record
    InLoadOrderLinks: TListEntry;
    InMemoryOrderLinks: TListEntry;
    InInitializationOrderLinks: TListEntry;
    DllBase: Pointer;
    EntryPoint: Pointer;
    [Bytes] SizeOfImage: Cardinal;
    FullDllName: UNICODE_STRING;
    BaseDllName: UNICODE_STRING;
    [Bitwise(TLdrEntryFlagProvider)] Flags: Cardinal;
    ObsoleteLoadCount: Word;
    TlsIndex: Word;
    HashLinks: TListEntry;
    TimeDateStamp: Cardinal;
    EntryPointActivationContext: Pointer;
    Lock: Pointer;
    DdagNode: Pointer; // PLDR_DDAG_NODE
    NodeModuleLink: TListEntry;
    LoadContext: Pointer;
    ParentDllBase: Pointer;
    SwitchBackContext: Pointer;
    BaseAddressIndexNode: TRtlBalancedNode;
    MappingInfoIndexNode: TRtlBalancedNode;
    [Hex] OriginalBase: UIntPtr;
    LoadTime: TLargeInteger;

    // Win 8+ fields
    BaseNameHashValue: Cardinal;
    LoadReason: TLdrDllLoadReason;

    // Win 10+ fields
    [Hex] ImplicitPathOptions: Cardinal;
    ReferenceCount: Cardinal;
    [Hex] DependentLoadFlags: Cardinal;
    SigningLevel: Byte; // RS2+
  end;
  PLdrDataTableEntry = ^TLdrDataTableEntry;

  [NamingStyle(nsSnakeCase, 'LDR_LOCK_LOADER_LOCK_DISPOSITION')]
  TLdrLoaderLockDisposition = (
    LDR_LOCK_LOADER_LOCK_DISPOSITION_INVALID = 0,
    LDR_LOCK_LOADER_LOCK_DISPOSITION_LOCK_ACQUIRED = 1,
    LDR_LOCK_LOADER_LOCK_DISPOSITION_LOCK_NOT_ACQUIRED = 2
  );
  PLdrLoaderLockDisposition = ^TLdrLoaderLockDisposition;

  [NamingStyle(nsSnakeCase, 'LDR_DLL_NOTIFICATION_REASON'), Range(1)]
  TLdrDllNotificationReason = (
    LDR_DLL_NOTIFICATION_REASON_RESERVED = 0,
    LDR_DLL_NOTIFICATION_REASON_LOADED = 1,
    LDR_DLL_NOTIFICATION_REASON_UNLOADED = 2
  );

  TLdrDllNotificationData = record
    [Hex] Flags: Cardinal;
    FullDllName: PUNICODE_STRING;
    BaseDllName: PUNICODE_STRING;
    DllBase: Pointer;
    [Bytes] SizeOfImage: Cardinal;
  end;
  PLdrDllNotificationData = ^TLdrDllNotificationData;

  TLdrDllNotificationFunction = procedure(NotificationReason:
    TLdrDllNotificationReason; NotificationData: PLdrDllNotificationData;
    Context: Pointer); stdcall;

  TLdrEnumCallback = procedure(ModuleInformation: PLdrDataTableEntry;
    Parameter: Pointer; out Stop: Boolean); stdcall;

function LdrLoadDll(DllPath: PWideChar; DllCharacteristics: PCardinal;
  const DllName: UNICODE_STRING; out DllHandle: HMODULE): NTSTATUS; stdcall;
  external ntdll;

function LdrUnloadDll(DllHandle: HMODULE): NTSTATUS; stdcall; external ntdll;

function LdrGetDllHandle(DllPath: PWideChar;
  DllCharacteristics: PCardinal; const DllName: UNICODE_STRING;
  out DllHandle: HMODULE): NTSTATUS; stdcall; external ntdll;

function LdrGetDllHandleByMapping(BaseAddress: Pointer; out DllHandle: HMODULE):
  NTSTATUS; stdcall; external ntdll;

function LdrGetDllHandleByName(BaseDllName: PUNICODE_STRING;
  FullDllName: PUNICODE_STRING; out DllHandle: HMODULE): NTSTATUS; stdcall;
  external ntdll;

function LdrGetDllFullName(DllHandle: Pointer; out FullDllName: UNICODE_STRING):
  NTSTATUS; stdcall; external ntdll;

function LdrGetDllDirectory(out DllDirectory: UNICODE_STRING): NTSTATUS;
  stdcall; external ntdll;

function LdrSetDllDirectory(const DllDirectory: UNICODE_STRING): NTSTATUS;
  stdcall; external ntdll;

function LdrGetProcedureAddress(DllHandle: HMODULE;
  const ProcedureName: ANSI_STRING; ProcedureNumber: Cardinal;
  out ProcedureAddress: Pointer): NTSTATUS; stdcall; external ntdll;

function LdrGetKnownDllSectionHandle(DllName: PWideChar; KnownDlls32: Boolean;
  out Section: THandle): NTSTATUS; stdcall; external ntdll;

function LdrLockLoaderLock(Flags: Cardinal; Disposition:
  PLdrLoaderLockDisposition; out Cookie: NativeUInt): NTSTATUS; stdcall;
  external ntdll;

function LdrUnlockLoaderLock(Flags: Cardinal; Cookie: NativeUInt):
  NTSTATUS; stdcall; external ntdll;

function LdrRegisterDllNotification(Flags: Cardinal; NotificationFunction:
  TLdrDllNotificationFunction; Context: Pointer; out Cookie: NativeUInt):
  NTSTATUS; stdcall; external ntdll;

function LdrUnregisterDllNotification(Cookie: NativeUInt): NTSTATUS; stdcall;
  external ntdll;

function LdrFindEntryForAddress(DllHandle: HMODULE; Entry:
  PLdrDataTableEntry): NTSTATUS; stdcall; external ntdll;

function LdrEnumerateLoadedModules(ReservedFlag: Boolean;
  EnumProc: TLdrEnumCallback; Context: Pointer): NTSTATUS;
  stdcall; external ntdll;

function LdrQueryImageFileExecutionOptions(const SubKey: UNICODE_STRING;
  ValueName: PWideChar; ValueSize: Cardinal; Buffer: Pointer;
  BufferSize: Cardinal; ReturnedLength: PCardinal): NTSTATUS; stdcall;
  external ntdll;

function hNtdll: HMODULE;

implementation

uses
  Ntapi.ntpebteb;

class function TLdrEntryFlagProvider.Flags: TFlagNames;
begin
  Result := Capture(LdrEntryFlagNames);
end;

var
  hNtdllCache: HMODULE = 0;

function hNtdll: HMODULE;
var
  Cookie: NativeUInt;
begin
  if hNtdllCache <> 0 then
    Exit(hNtdllCache);

  LdrLockLoaderLock(0, nil, Cookie);

  // Get the first initialized module from the loader data in PEB.
  // Shift it using CONTAINING_RECORD and access the DllBase.

  {$Q-}
  Result := HMODULE(PLdrDataTableEntry(NativeInt(NtCurrentTeb.
    ProcessEnvironmentBlock.Ldr.InInitializationOrderModuleList.Flink) -
    NativeInt(@PLdrDataTableEntry(nil).InInitializationOrderLinks)).DllBase);
  {$Q+}

  LdrUnlockLoaderLock(0, Cookie);
  hNtdllCache := Result;
end;

end.
