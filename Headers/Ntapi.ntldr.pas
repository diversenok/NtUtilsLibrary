unit Ntapi.ntldr;

{$MINENUMSIZE 4}

interface

uses
  Winapi.WinNt, Ntapi.ntdef, NtUtils.Version, DelphiApi.Reflection;

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

  [FlagName(LDRP_PACKAGED_BINARY, 'Packaged Binary')]
  [FlagName(LDRP_STATIC_LINK, 'Static Link')]
  [FlagName(LDRP_IMAGE_DLL, 'Image DLL')]
  [FlagName(LDRP_LOAD_IN_PROGRESS, 'Load In Progress')]
  [FlagName(LDRP_UNLOAD_IN_PROGRESS, 'Unload In Progress')]
  [FlagName(LDRP_ENTRY_PROCESSED, 'Entry Processed')]
  [FlagName(LDRP_ENTRY_INSERTED, 'Entry Inserted')]
  [FlagName(LDRP_CURRENT_LOAD, 'Current Load')]
  [FlagName(LDRP_FAILED_BUILTIN_LOAD, 'Failed Builtin Load')]
  [FlagName(LDRP_DONT_CALL_FOR_THREADS, 'Don''t Call For Threads')]
  [FlagName(LDRP_PROCESS_ATTACH_CALLED, 'Process Attach Called')]
  [FlagName(LDRP_DEBUG_SYMBOLS_LOADED, 'Debug Symbols Loaded')]
  [FlagName(LDRP_IMAGE_NOT_AT_BASE, 'Image Not At Base')]
  [FlagName(LDRP_COR_IMAGE, 'COR Image')]
  [FlagName(LDRP_DONT_RELOCATE, 'Don''t Relocate')]
  [FlagName(LDRP_SYSTEM_MAPPED, 'System Mapped')]
  [FlagName(LDRP_IMAGE_VERIFYING, 'Image Verifying')]
  [FlagName(LDRP_DRIVER_DEPENDENT_DLL, 'Driver-dependent DLL')]
  [FlagName(LDRP_ENTRY_NATIVE, 'Native')]
  [FlagName(LDRP_REDIRECTED, 'Redirected')]
  [FlagName(LDRP_NON_PAGED_DEBUG_INFO, 'Non-paged Debug Info')]
  [FlagName(LDRP_MM_LOADED, 'MM Loaded')]
  [FlagName(LDRP_COMPAT_DATABASE_PROCESSED, 'Compact Database Processed')]
  TLdrFlags = type Cardinal;

  PLdrServiceTagRecord = ^TLdrServiceTagRecord;
  TLdrServiceTagRecord = record
    Next: PLdrServiceTagRecord;
    ServiceTag: Cardinal;
  end;

  TLdrDdagNode = record
    Modules: TListEntry;
    ServiceTagList: PLdrServiceTagRecord;
    LoadCount: Cardinal;
    LoadWhileUnloadingCount: Cardinal;
  end;
  PLdrDdagNode = ^TLdrDdagNode;

  TLdrDataTableEntry = record
    InLoadOrderLinks: TListEntry;
    InMemoryOrderLinks: TListEntry;
    InInitializationOrderLinks: TListEntry;
    DllBase: Pointer;
    EntryPoint: Pointer;
    [Bytes] SizeOfImage: Cardinal;
    FullDllName: TNtUnicodeString;
    BaseDllName: TNtUnicodeString;
    Flags: TLdrFlags;
    ObsoleteLoadCount: Word;
    TlsIndex: Word;
    HashLinks: TListEntry;
    TimeDateStamp: Cardinal;
    EntryPointActivationContext: Pointer;
    Lock: Pointer;
    DdagNode: PLdrDdagNode;
    NodeModuleLink: TListEntry;
    LoadContext: Pointer;
    ParentDllBase: Pointer;
    SwitchBackContext: Pointer;
    BaseAddressIndexNode: TRtlBalancedNode;
    MappingInfoIndexNode: TRtlBalancedNode;
    [Hex] OriginalBase: UIntPtr;
    LoadTime: TLargeInteger;
    [MinOSVersion(OsWin8)] BaseNameHashValue: Cardinal;
    [MinOSVersion(OsWin8)] LoadReason: TLdrDllLoadReason;
    [MinOSVersion(OsWin10), Hex] ImplicitPathOptions: Cardinal;
    [MinOSVersion(OsWin10)] ReferenceCount: Cardinal;
    [MinOSVersion(OsWin10), Hex] DependentLoadFlags: Cardinal;
    [MinOSVersion(OsWin10RS2)] SigningLevel: Byte;
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
    FullDllName: PNtUnicodeString;
    BaseDllName: PNtUnicodeString;
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
  const DllName: TNtUnicodeString; out DllHandle: HMODULE): NTSTATUS; stdcall;
  external ntdll;

function LdrUnloadDll(DllHandle: HMODULE): NTSTATUS; stdcall; external ntdll;

function LdrGetDllHandle(DllPath: PWideChar;
  DllCharacteristics: PCardinal; const DllName: TNtUnicodeString;
  out DllHandle: HMODULE): NTSTATUS; stdcall; external ntdll;

function LdrGetDllHandleByMapping(BaseAddress: Pointer; out DllHandle: HMODULE):
  NTSTATUS; stdcall; external ntdll;

function LdrGetDllHandleByName(BaseDllName: PNtUnicodeString;
  FullDllName: PNtUnicodeString; out DllHandle: HMODULE): NTSTATUS; stdcall;
  external ntdll;

function LdrGetDllFullName(DllHandle: Pointer; out FullDllName: TNtUnicodeString):
  NTSTATUS; stdcall; external ntdll;

function LdrGetDllDirectory(out DllDirectory: TNtUnicodeString): NTSTATUS;
  stdcall; external ntdll;

function LdrSetDllDirectory(const DllDirectory: TNtUnicodeString): NTSTATUS;
  stdcall; external ntdll;

function LdrGetProcedureAddress(DllHandle: HMODULE;
  const ProcedureName: TNtAnsiString; ProcedureNumber: Cardinal;
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

function LdrQueryImageFileExecutionOptions(const SubKey: TNtUnicodeString;
  ValueName: PWideChar; ValueSize: Cardinal; Buffer: Pointer;
  BufferSize: Cardinal; ReturnedLength: PCardinal): NTSTATUS; stdcall;
  external ntdll;

function hNtdll: HMODULE;

implementation

uses
  Ntapi.ntpebteb;

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
