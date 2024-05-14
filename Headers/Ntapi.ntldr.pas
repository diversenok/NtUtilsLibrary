unit Ntapi.ntldr;

{
  The module defines structures and functions of the image loader from ntdll.
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.ntdef, Ntapi.ImageHlp, Ntapi.actctx, Ntapi.ntregapi,
  Ntapi.Versions, DelphiApi.Reflection;

const
  // PHNT::ntldr.h - module flags
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

  // Flags inside pointers to mapped files
  LDR_MAPPED_AS_DATAFILE = $01;
  LDR_MAPPED_AS_IMAGEMAPPING = $02;

  // PHNT::ntldr.h - loader lock acquiring options
  LDR_LOCK_LOADER_LOCK_FLAG_RAISE_ON_ERRORS =  $00000001;
  LDR_LOCK_LOADER_LOCK_FLAG_TRY_ONLY = $00000002;

  // flags for TPsSystemDllInitBlock (from bit union)
  PS_SYSTEM_DLL_INIT_BLOCK_CFG_OVERRIDE = $0001;

type
  PDllBase = Ntapi.ImageHlp.PImageDosHeader;

  // SDK::ntdef.h
  PRtlBalancedNode = ^TRtlBalancedNode;
  [SDKName('RTL_BALANCED_NODE')]
  TRtlBalancedNode = record
    Left: PRtlBalancedNode;
    Right: PRtlBalancedNode;
    ParentValue: NativeUInt;
  end;

  // PHNT::ntldr.h
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

  // PHNT::ntldr.h
  PLdrServiceTagRecord = ^TLdrServiceTagRecord;
  [SDKName('LDR_SERVICE_TAG_RECORD')]
  TLdrServiceTagRecord = record
    Next: PLdrServiceTagRecord;
    ServiceTag: TServiceTag;
  end;

  // PHNT::ntldr.h
  [SDKName('LDR_DDAG_NODE')]
  TLdrDdagNode = record
    Modules: TListEntry;
    ServiceTagList: PLdrServiceTagRecord;
    LoadCount: Cardinal;
    LoadWhileUnloadingCount: Cardinal;
    // TODO: add more LDR DDAG fields
  end;
  PLdrDdagNode = ^TLdrDdagNode;

  // PHNT::ntldr.h
  [SDKName('LDR_DATA_TABLE_ENTRY')]
  TLdrDataTableEntry = record
    InLoadOrderLinks: TListEntry;
    InMemoryOrderLinks: TListEntry;
    InInitializationOrderLinks: TListEntry;
    DllBase: PDllBase;
    EntryPoint: Pointer;
    [Bytes] SizeOfImage: Cardinal;
    FullDllName: TNtUnicodeString;
    BaseDllName: TNtUnicodeString;
    Flags: TLdrFlags;
    ObsoleteLoadCount: Word;
    TlsIndex: Word;
    HashLinks: TListEntry;
    TimeDateStamp: TUnixTime;
    EntryPointActivationContext: PActivationContext;
    Lock: Pointer;
    DdagNode: PLdrDdagNode;
    NodeModuleLink: TListEntry;
    LoadContext: Pointer;
    ParentDllBase: PDllBase;
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

  [FlagName(LDR_LOCK_LOADER_LOCK_FLAG_RAISE_ON_ERRORS, 'Raise On Errors')]
  [FlagName(LDR_LOCK_LOADER_LOCK_FLAG_TRY_ONLY, 'Try Only')]
  TLdrLockFlags = type Cardinal;

  // PHNT::ntldr.h
  [NamingStyle(nsSnakeCase, 'LDR_LOCK_LOADER_LOCK_DISPOSITION'), Range(1)]
  TLdrLoaderLockDisposition = (
    [Reserved] LDR_LOCK_LOADER_LOCK_DISPOSITION_INVALID = 0,
    LDR_LOCK_LOADER_LOCK_DISPOSITION_LOCK_ACQUIRED = 1,
    LDR_LOCK_LOADER_LOCK_DISPOSITION_LOCK_NOT_ACQUIRED = 2
  );
  PLdrLoaderLockDisposition = ^TLdrLoaderLockDisposition;

  // PHNT::ntldr.h
  [SDKName('LDR_RESOURCE_INFO')]
  TLdrResourceInfo = record
    ResourceType: PWideChar;
    Name: PWideChar;
    Language: UIntPtr;
  end;

  // PHNT::ntldr.h
  [NamingStyle(nsSnakeCase, 'Resource', 'Level')]
  TResourceLevel = (
    RESOURCE_TYPE_LEVEL = 0,
    RESOURCE_NAME_LEVEL = 1,
    RESOURCE_LANGUAGE_LEVEL = 2,
    RESOURCE_DATA_LEVEL = 3
  );

  // MSDocs::win32/desktop-src/DevNotes/LdrDllNotification.md
  [NamingStyle(nsSnakeCase, 'LDR_DLL_NOTIFICATION_REASON'), Range(1)]
  TLdrDllNotificationReason = (
    [Reserved] LDR_DLL_NOTIFICATION_REASON_RESERVED = 0,
    LDR_DLL_NOTIFICATION_REASON_LOADED = 1,
    LDR_DLL_NOTIFICATION_REASON_UNLOADED = 2
  );

  // MSDocs::win32/desktop-src/DevNotes/LdrDllNotification.md
  [SDKName('LDR_DLL_LOADED_NOTIFICATION_DATA')]
  TLdrDllNotificationData = record
    [Hex] Flags: Cardinal;
    FullDllName: PNtUnicodeString;
    BaseDllName: PNtUnicodeString;
    DllBase: PDllBase;
    [Bytes] SizeOfImage: Cardinal;
  end;

  // MSDocs::win32/desktop-src/DevNotes/LdrDllNotification.md
  [SDKName('LdrDllNotification')]
  TLdrDllNotificationFunction = procedure(
    [in] NotificationReason: TLdrDllNotificationReason;
    [in] const NotificationData: TLdrDllNotificationData;
    [in, opt] Context: Pointer
  ); stdcall;

  // PHNT::ntldr.h
  [SDKName('PLDR_ENUM_CALLBACK')]
  TLdrEnumCallback = procedure(
    [in] ModuleInformation: PLdrDataTableEntry;
    [in, opt] Parameter: Pointer;
    [out] var Stop: Boolean
  ); stdcall;

  [SDKName('WOW64_SHARED_INFORMATION')]
  [NamingStyle(nsCamelCase, 'SharedNtdll32'), Range(0, 8)]
  TWow64SharedInformation = (
    SharedNtdll32LdrInitializeThunk = 0,
    SharedNtdll32KiUserExceptionDispatcher = 1,
    SharedNtdll32KiUserApcDispatcher = 2,
    SharedNtdll32KiUserCallbackDispatcher = 3,
    SharedNtdll32RtlUserThreadStart = 4,
    SharedNtdll32pQueryProcessDebugInformationRemote = 5,
    SharedNtdll32BaseAddress = 6,
    SharedNtdll32LdrSystemDllInitBlock = 7,
    SharedNtdll32RtlpFreezeTimeBias = 8,
    SharedNtdll32Reserved9, SharedNtdll32Reserved10, SharedNtdll32Reserved11,
    SharedNtdll32Reserved12, SharedNtdll32Reserved13, SharedNtdll32Reserved14,
    SharedNtdll32Reserved15
  );

  TWow64SharedInformationArray = array [TWow64SharedInformation] of Pointer;

  [FlagName(PS_SYSTEM_DLL_INIT_BLOCK_CFG_OVERRIDE, 'CFG Override')]
  TPsSystemDllInitBlockFlags = type Cardinal;

  // PHNT::ntldr.h
  [SDKName('PS_SYSTEM_DLL_INIT_BLOCK')]
  TPsSystemDllInitBlock = record
    [RecordSize] Size: Cardinal;
    SystemDllWowRelocation: Pointer;
    SystemDllNativeRelocation: Pointer;
    Wow64SharedInformation: TWow64SharedInformationArray;
    RngData: Cardinal;
    Flags: TPsSystemDllInitBlockFlags;
  end;
  PPsSystemDllInitBlock = ^TPsSystemDllInitBlock;

// PHNT::ntldr.h
function LdrLoadDll(
  [in, opt] DllPath: PWideChar;
  [in, opt] DllCharacteristics: PCardinal;
  [in] const DllName: TNtUnicodeString;
  [out] out DllBase: PDllBase
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrUnloadDll(
  [in] DllBase: PDllBase
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrGetDllHandle(
  [in, opt] DllPath: PWideChar;
  [in, opt] DllCharacteristics: PCardinal;
  [in] const DllName: TNtUnicodeString;
  [out] out DllBase: PDllBase
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrGetDllHandleByMapping(
  [in] BaseAddress: Pointer;
  [out] out DllBase: PDllBase
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrGetDllHandleByName(
  [in, opt] BaseDllName: PNtUnicodeString;
  [in, opt] FullDllName: PNtUnicodeString;
  [out] out DllBase: PDllBase
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrGetDllFullName(
  [in] DllBase: PDllBase;
  [out] out FullDllName: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrGetDllDirectory(
  [out] out DllDirectory: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrSetDllDirectory(
  [in] const DllDirectory: TNtUnicodeString
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrGetProcedureAddress(
  [in] DllBase: PDllBase;
  [in] const ProcedureName: TNtAnsiString;
  [in] ProcedureNumber: Cardinal;
  [out] out ProcedureAddress: Pointer
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrGetKnownDllSectionHandle(
  [in] DllName: PWideChar;
  [in] KnownDlls32: Boolean;
  [out, ReleaseWith('NtClose')] out Section: THandle
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrLockLoaderLock(
  [in] Flags: TLdrLockFlags;
  [out, opt] Disposition: PLdrLoaderLockDisposition;
  [out, ReleaseWith('LdrUnlockLoaderLock')] out Cookie: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrUnlockLoaderLock(
  [in] Flags: TLdrLockFlags;
  [in] Cookie: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrAddLoadAsDataTable(
  [in] Module: Pointer;
  [in] FilePath: PWideChar;
  [in] Size: NativeUInt;
  [in] Handle: THandle;
  [in, opt] ActCtx: PActivationContext
): NTSTATUS; stdcall external ntdll;

// PHNT::ntldr.h
function LdrRemoveLoadAsDataTable(
  [in] InitModule: Pointer;
  [out, opt] BaseModule: PPointer;
  [out, opt] Size: PNativeUInt;
  [in] Flags: Cardinal
): NTSTATUS; stdcall external ntdll;

// PHNT::ntldr.h
function LdrFindResource_U(
  [in] DllHandle: PDllBase;
  [in] const ResourceInfo: TLdrResourceInfo;
  [in] Level: TResourceLevel;
  [out] out ResourceDataEntry: PImageResourceDataEntry
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrAccessResource(
  [in] DllHandle: PDllBase;
  [in] ResourceDataEntry: PImageResourceDataEntry;
  [out, opt] ResourceBuffer: PPointer;
  [out, opt] ResourceLength: PCardinal
): NTSTATUS; stdcall; external ntdll;

// MSDocs::win32/desktop-src/DevNotes/LdrRegisterDllNotification.md
function LdrRegisterDllNotification(
  [Reserved] Flags: Cardinal;
  [in] NotificationFunction: TLdrDllNotificationFunction;
  [in, opt] Context: Pointer;
  [out, ReleaseWith('LdrUnregisterDllNotification')] out Cookie: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// MSDocs::win32/desktop-src/DevNotes/LdrUnregisterDllNotification.md
function LdrUnregisterDllNotification(
  [in] Cookie: NativeUInt
): NTSTATUS; stdcall; external ntdll;

// MSDocs::win32/desktop-src/DevNotes/LdrFastFailInLoaderCallout.md
procedure LdrFastFailInLoaderCallout(
); stdcall; external ntdll;

// PHNT::ntldr.h
function LdrFindEntryForAddress(
  [in] DllBase: PDllBase;
  [out] out Entry: PLdrDataTableEntry
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrEnumerateLoadedModules(
  [Reserved] Flags: Cardinal;
  [in] CallbackFunction: TLdrEnumCallback;
  [in, opt] Context: Pointer
): NTSTATUS; stdcall; external ntdll;

// PHNT::ntldr.h
function LdrQueryImageFileExecutionOptions(
  [in] const ImagePathName: TNtUnicodeString;
  [in] OptionName: PWideChar;
  [in] OptionType: TRegValueType;
  [out, WritesTo] Buffer: Pointer;
  [in, NumberOfBytes] BufferSize: Cardinal;
  [out, opt, NumberOfBytes] ResultSize: PCardinal
): NTSTATUS; stdcall; external ntdll;

{ Helper functions}

function hNtdll(
): PLdrDataTableEntry;

implementation

uses
  Ntapi.ntpebteb;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

var
  hNtdllCache: PLdrDataTableEntry = nil;

function hNtdll;
var
  Cookie: NativeUInt;
begin
  if Assigned(hNtdllCache) then
    Exit(hNtdllCache);

  LdrLockLoaderLock(0, nil, Cookie);

  // Get the first initialized module from the loader data in PEB.
  // Shift it using CONTAINING_RECORD.

  {$Q-}{$R-}
  Result := PLdrDataTableEntry(
    UIntPtr(NtCurrentTeb.ProcessEnvironmentBlock.Ldr.
      InInitializationOrderModuleList.Flink) -
    UIntPtr(@PLdrDataTableEntry(nil).InInitializationOrderLinks)
  );
  {$IFDEF R+}{$R+}{$ENDIF}{$IFDEF Q+}{$Q+}{$ENDIF}

  LdrUnlockLoaderLock(0, Cookie);
  hNtdllCache := Result;
end;

end.
