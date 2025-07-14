unit NtUtils.Ldr;

{
  The function to interact with the module loader in ntdll.
}

interface

uses
  Ntapi.WinNt, Ntapi.ntldr, Ntapi.ntrtl, Ntapi.Versions, DelphiApi.Reflection,
  DelphiApi.DelayLoad, NtUtils;

const
  // Artificial limitation to prevent accidental infinite loops
  MAX_MODULES = $800;

type
  PDllBase = Ntapi.ntldr.PDllBase;
  PPDllBase = ^PDllBase;

  TLdrxModuleInfo = record
    DllBase: PDllBase;
    EntryPoint: Pointer;
    [Bytes] SizeOfImage: Cardinal;
    FullDllName: String;
    BaseDllName: String;
    LoadCount: Cardinal;
    Flags: TLdrFlags;
    TimeDateStamp: TUnixTime;
    ParentDllBase: PDllBase;
    [Hex] OriginalBase: UIntPtr;
    LoadTime: TLargeInteger;
    [MinOSVersion(OsWin8)] LoadReason: TLdrDllLoadReason;
    LdrEntry: PLdrDataTableEntry;
    function IsInRange(Address: Pointer): Boolean;
    function Region: TMemory;
  end;

  TDllNotification = reference to procedure(
    Reason: TLdrDllNotificationReason;
    const Data: TLdrDllNotificationData
  );

  TLdrxModuleInfoFinder = reference to function (
    const Module: TLdrxModuleInfo
  ): Boolean;

  TLdrxModuleEntryFinder = reference to function (
    LdrEntry: PLdrDataTableEntry
  ): Boolean;

{ Delayed Import Checks }

// Pre-load a DLL for delay loading
function LdrxCheckDelayedModule(
  var Module: TDelayedLoadDll
): TNtxStatus;

// Check if a function is present in a dll and load it if necessary
function LdrxCheckDelayedImport(
  var Routine: TDelayedLoadFunction
): TNtxStatus;

{ DLL Operations }

// Get base address of a loaded dll
function LdrxGetDllHandle(
  const DllName: String;
  out DllBase: PDllBase
): TNtxStatus;

// Unload a dll
function LdrxUnloadDll(
  [in] DllBase: PDllBase
): TNtxStatus;

// Load a dll
function LdrxLoadDll(
  const DllName: String;
  [out, opt] outDllBase: PPDllBase = nil
): TNtxStatus;

// Load a dll and unload it later
function LdrxLoadDllAuto(
  const DllName: String;
  out Module: IPointer
): TNtxStatus;

// Get a function address
function LdrxGetProcedureAddress(
  [in] DllBase: PDllBase;
  const ProcedureName: AnsiString;
  out Address: Pointer
): TNtxStatus;

{ Resources }

// Locate resource data in a DLL
function LdrxFindResourceData(
  [in] DllBase: PDllBase;
  ResourceName: PWideChar;
  ResourceType: PWideChar;
  ResourceLanguage: Cardinal;
  out Buffer: Pointer;
  out Size: Cardinal
): TNtxStatus;

// Retrieve a message from a DLL resource
function RtlxFindMessage(
  out MessageString: String;
  [in] DllBase: Pointer;
  MessageId: Cardinal;
  MessageLanguageId: Cardinal = LANG_NEUTRAL;
  MessageTableId: Cardinal = RT_MESSAGETABLE
): TNtxStatus;

// Load a string from a DLL resource
function RtlxLoadString(
  out ResourcesString: String;
  [in] DllBase: Pointer;
  StringId: Cardinal;
  [in, opt] StringLanguage: PWideChar = nil
): TNtxStatus;

{ Low-level Access }

// Subscribe for DLL loading and unloading events.
// NOTE: Be careful about what executing within the callback
function LdrxRegisterDllNotification(
  out Registration: IAutoReleasable;
  const Callback: TDllNotification
): TNtxStatus;

// Acquire the the loader lock and prevent race conditions
function LdrxAcquireLoaderLock(
  out Lock: IAutoReleasable
): TNtxStatus;

// Enumerate LDR entries for all loaded modules
function LdrxEnumerateModuleEntries(
  out Entries: TArray<PLdrDataTableEntry>;
  MaximumCount: Integer = MAX_MODULES
): TNtxStatus;

// Enumerate and capture information about all loaded modules
function LdrxEnumerateModuleInfo(
  out Modules: TArray<TLdrxModuleInfo>;
  MaximumCount: Integer = MAX_MODULES
): TNtxStatus;

// Find a module that satisfies a condition
function LdrxFindModuleEntry(
  out LdrEntry: PLdrDataTableEntry;
  Condition: TLdrxModuleEntryFinder;
  MaximumCount: Integer = MAX_MODULES
): TNtxStatus;

// Find a module that satisfies a condition
function LdrxFindModuleInfo(
  out Module: TLdrxModuleInfo;
  Condition: TLdrxModuleInfoFinder;
  MaximumCount: Integer = MAX_MODULES
): TNtxStatus;

// Provides a finder for an LDR entry that starts at a specific address;
// Use @ImageBase to find the current module
function LdrxEntryStartsAt(
  [in] Address: Pointer
): TLdrxModuleEntryFinder;

// Provides a finder for a module that starts at a specific address;
// Use @ImageBase to find the current module
function LdrxModuleStartsAt(
  [in] Address: Pointer
): TLdrxModuleInfoFinder;

// Provides a finder for an LDR entry that contains a specific address;
// Use @ImageBase to find the current module
function LdrxEntryContains(
  [in] Address: Pointer
): TLdrxModuleEntryFinder;

// Provides a finder for a module that contains a specific address
function LdrxModuleContains(
  [in] Address: Pointer
): TLdrxModuleInfoFinder;

// Provides a finder for an LDR entry with a specific base name
function LdrxEntryBaseName(
  const DllName: String;
  CaseSensitive: Boolean = False
): TLdrxModuleEntryFinder;

// Provides a finder for a module with a specific base name
function LdrxModuleBaseName(
  const DllName: String;
  CaseSensitive: Boolean = False
): TLdrxModuleInfoFinder;

// Retrieves shared NTDLL information
function LdrSystemDllInitBlock: PPsSystemDllInitBlock;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntdbg, Ntapi.ntstatus, Ntapi.ImageHlp,
  NtUtils.SysUtils, DelphiUtils.AutoObjects, DelphiUtils.ExternalImport,
  NtUtils.Synchronization, DelphiUtils.AutoEvents;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Delayed Import Checks }

function LdrxCheckDelayedModule;
var
  DllStr: TNtUnicodeString;
  AcquiredInit: IAcquiredRunOnce;
begin
  if RtlxRunOnceBegin(PRtlRunOnce(@Module.Initialized), AcquiredInit) then
  begin
    // Even if we previously failed to load the DLL, retry anyway because we
    // might run with a different security or activation context
    DllStr.Length := Length(Module.DllName) * SizeOf(WideChar);
    DllStr.MaximumLength := DllStr.Length + SizeOf(WideChar);
    DllStr.Buffer := Module.DllName;

    Result.Location := 'LdrLoadDll';
    Result.LastCall.Parameter := String(Module.DllName);
    Result.Status := LdrLoadDll(nil, nil, DllStr, PDllBase(Module.DllAddress));

    if not Result.IsSuccess then
      Exit;

    // Complete only on success
    AcquiredInit.Complete;
  end
  else
    Result := NtxSuccess;
end;

function LdrxCheckDelayedImport;
var
  FunctionStr: TNtAnsiString;
  pFunctionStr: PNtAnsiString;
  FunctionNumber: Cardinal;
  AcquiredInit: IAcquiredRunOnce;
begin
  Assert(Assigned(Routine.Dll), 'Invalid delay load module reference');

  // Check the module before checking the function
  Result := LdrxCheckDelayedModule(Routine.Dll^);

  if not Result.IsSuccess then
    Exit;

  if RtlxRunOnceBegin(PRtlRunOnce(@Routine.Initialized), AcquiredInit) then
  begin
    if Routine.IsImportByOrdinal then
    begin
      // Import by ordinal
      pFunctionStr := nil;
      FunctionNumber := Routine.Ordinal;
    end
    else
    begin
      // Import by name
      FunctionStr.Length := Length(Routine.FunctionName) * SizeOf(AnsiChar);
      FunctionStr.MaximumLength := FunctionStr.Length + SizeOf(AnsiChar);
      FunctionStr.Buffer := Routine.FunctionName;
      pFunctionStr := @FunctionStr;
      FunctionNumber := 0;
    end;

    Result.Location := 'LdrGetProcedureAddress';
    Result.Status := LdrGetProcedureAddress(Routine.Dll.DllAddress,
      pFunctionStr, FunctionNumber, Routine.FunctionAddress);

    // Always do the check just once
    Routine.CheckStatus := Result.Status;
    AcquiredInit.Complete;
  end
  else
  begin
    // Already checked
    Result.Location := 'LdrGetProcedureAddress';
    Result.Status := Routine.CheckStatus;
  end;

  // Attach details on failure
  if not Result.IsSuccess then
  begin
    if Routine.IsImportByOrdinal then
      Result.LastCall.Parameter := String(Routine.Dll.DllName) + '!#' +
        RtlxUIntToStr(Routine.Ordinal)
    else
      Result.LastCall.Parameter := String(Routine.Dll.DllName) + '!' +
        String(Routine.FunctionName);
  end;
end;

{ DLL Operations }

function LdrxGetDllHandle;
var
  DllNameStr: TNtUnicodeString;
begin
  Result := RtlxInitUnicodeString(DllNameStr, DllName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LdrGetDllHandle';
  Result.LastCall.Parameter := DllName;
  Result.Status := LdrGetDllHandle(nil, nil, DllNameStr, DllBase);
end;

function LdrxUnloadDll;
begin
  Result.Location := 'LdrUnloadDll';
  Result.Status := LdrUnloadDll(DllBase);
end;

type
  TAutoDll = class (TCustomAutoPointer)
    destructor Destroy; override;
  end;

destructor TAutoDll.Destroy;
begin
  if Assigned(FData) and not FDiscardOwnership then
    LdrxUnloadDll(FData);

  inherited;
end;

function LdrxLoadDll;
var
  DllNameStr: TNtUnicodeString;
  DllBase: PDllBase;
begin
  Result := RtlxInitUnicodeString(DllNameStr, DllName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LdrLoadDll';
  Result.LastCall.Parameter := DllName;
  Result.Status := LdrLoadDll(nil, nil, DllNameStr, DllBase);

  if Result.IsSuccess and Assigned(outDllBase) then
    outDllBase^ := DllBase;
end;

function LdrxLoadDllAuto;
var
  DllBase: PDllBase;
begin
  Result := LdrxLoadDll(DllName, @DllBase);

  if Result.IsSuccess then
    Module := TAutoDll.Capture(DllBase);
end;

function LdrxGetProcedureAddress;
var
  ProcedureNameStr: TNtAnsiString;
begin
  Result := RtlxInitAnsiString(ProcedureNameStr, ProcedureName);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LdrGetProcedureAddress';
  Result.LastCall.Parameter := String(ProcedureName);
  Result.Status := LdrGetProcedureAddress(DllBase, @ProcedureNameStr, 0, Address);
end;

{ Resources }

function LdrxFindResourceData;
var
  Info: TLdrResourceInfo;
  Data: PImageResourceDataEntry;
begin
  Info.ResourceType := ResourceType;
  Info.Name := ResourceName;
  Info.Language := ResourceLanguage;

  Result.Location := 'LdrFindResource_U';

  if UIntPtr(ResourceName) < High(Word) then
    Result.LastCall.Parameter := '#' + RtlxUIntPtrToStr(UIntPtr(ResourceName))
  else
    Result.LastCall.Parameter := String(ResourceName);

  Result.Status := LdrFindResource_U(DllBase, Info, RESOURCE_DATA_LEVEL, Data);

  if not Result.IsSuccess then
    Exit;

  Result.Location := 'LdrAccessResource';
  Result.Status := LdrAccessResource(DllBase, Data, @Buffer, @Size);
end;

function RtlxFindMessage;
var
  MessageEntry: PMessageResourceEntry;
begin
  // Perhaps, we can later implement the same language selection logic as
  // FormatMessage, i.e:
  //  1. Neutral => MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL)
  //  2. Current => NtCurrentTeb.CurrentLocale
  //  3. User    => MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT)
  //  4. System  => MAKELANGID(LANG_NEUTRAL, SUBLANG_SYS_DEFAULT)
  //  5. English => MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT)

  Result.Location := 'RtlFindMessage';
  Result.Status := RtlFindMessage(DllBase, MessageTableId, MessageLanguageId,
    MessageId, MessageEntry);

  if not Result.IsSuccess then
    Exit;

  if BitTest(MessageEntry.Flags and MESSAGE_RESOURCE_UNICODE) then
    MessageString := String(PWideChar(@MessageEntry.Text))
  else if BitTest(MessageEntry.Flags and MESSAGE_RESOURCE_UTF8) then
    MessageString := String(UTF8String(PAnsiChar(@MessageEntry.Text)))
  else
    MessageString := String(PAnsiChar(@MessageEntry.Text));
end;

function RtlxLoadString;
var
  Buffer: PWideChar;
  BufferLength: Word;
begin
  Result.Location := 'RtlLoadString';
  Result.Status := RtlLoadString(DllBase, StringId, StringLanguage, 0, Buffer,
    BufferLength, nil, nil);

  if Result.IsSuccess then
    SetString(ResourcesString, Buffer, BufferLength);
end;

{ Low-level Access }

type
  TAutoDllCallbackRegistration = class (TAutoInterfacedObject)
    FLdrCookie: NativeUInt;
    FCallbackCookie: NativeUInt;
    destructor Destroy; override;
    constructor Create(
      LdrCookie: NativeUInt;
      CallbackCookie: NativeUInt
    );
  end;

constructor TAutoDllCallbackRegistration.Create;
begin
  inherited Create;
  FLdrCookie := LdrCookie;
  FCallbackCookie := CallbackCookie;
end;

destructor TAutoDllCallbackRegistration.Destroy;
begin
  if FLdrCookie <> 0 then
    LdrUnregisterDllNotification(FLdrCookie);

  if FCallbackCookie <> 0 then
    TInterfaceTable.Remove(FCallbackCookie);

  FLdrCookie := 0;
  FCallbackCookie := 0;
  inherited;
end;

procedure LdrxNotificationDispatcher(
  NotificationReason: TLdrDllNotificationReason;
  const NotificationData: TLdrDllNotificationData;
  [in, opt] Context: Pointer
); stdcall;
var
  CallbackCookie: NativeUInt absolute Context;
  Callback: TDllNotification;
begin
  if TInterfaceTable.Find(CallbackCookie, Callback) then
  try
    Callback(NotificationReason, NotificationData);
  except
    on E: TObject do
      if not Assigned(AutoExceptionHanlder) or not AutoExceptionHanlder(E) then
        raise;
  end;
end;

function LdrxRegisterDllNotification;
var
  LdrCookie, CallbackCookie: NativeUInt;
  CallbackIntf: IInterface absolute Callback;
begin
  // Register the callback in the interface table
  CallbackCookie := TInterfaceTable.Add(CallbackIntf);

  // Regiser the callback with LDR using the table cookie as a context
  Result.Location := 'LdrRegisterDllNotification';
  Result.Status := LdrRegisterDllNotification(0, LdrxNotificationDispatcher,
    Pointer(CallbackCookie), LdrCookie);

  if Result.IsSuccess then
    // Transfer registration ownership
    Registration := TAutoDllCallbackRegistration.Create(LdrCookie,
      CallbackCookie)
  else
    // Undo table registration on failure
    TInterfaceTable.Remove(CallbackCookie);
end;

type
  TAutoLoaderLock = class (TCustomAutoHandle)
    destructor Destroy; override;
  end;

destructor TAutoLoaderLock.Destroy;
begin
  if (FHandle <> 0) and not FDiscardOwnership then
    LdrUnlockLoaderLock(0, FHandle);

  inherited;
end;

function LdrxAcquireLoaderLock;
var
  Cookie: NativeUInt;
begin
  Result.Location := 'LdrLockLoaderLock';
  Result.Status := LdrLockLoaderLock(0, nil, Cookie);

  if Result.IsSuccess then
    Lock := TAutoLoaderLock.Capture(Cookie);
end;

function LdrxpSaveEntry([in] pTableEntry: PLdrDataTableEntry): TLdrxModuleInfo;
begin
  Result.DllBase := pTableEntry.DllBase;
  Result.EntryPoint := pTableEntry.EntryPoint;
  Result.SizeOfImage := pTableEntry.SizeOfImage;
  Result.FullDllName := pTableEntry.FullDllName.ToString;
  Result.BaseDllName := pTableEntry.BaseDllName.ToString;
  Result.Flags := pTableEntry.Flags;
  Result.TimeDateStamp := pTableEntry.TimeDateStamp;
  Result.LoadTime := pTableEntry.LoadTime;
  Result.ParentDllBase := pTableEntry.ParentDllBase;
  Result.OriginalBase := pTableEntry.OriginalBase;
  Result.LoadCount := pTableEntry.ObsoleteLoadCount;
  Result.LdrEntry := pTableEntry;

  if RtlOsVersionAtLeast(OsWin8) then
  begin
    Result.LoadReason := pTableEntry.LoadReason;
    Result.LoadCount := pTableEntry.DdagNode.LoadCount;
  end;
end;

function LdrxEnumerateModuleEntries;
var
  Count: Integer;
  Start, Current: PLdrDataTableEntry;
  Lock: IAutoReleasable;
begin
  Result := LdrxAcquireLoaderLock(Lock);

  if not Result.IsSuccess then
    Exit;

  Start := PLdrDataTableEntry(@RtlGetCurrentPeb.Ldr.InLoadOrderModuleList);

  // Count the number of modules
  Count := 0;
  Current := PLdrDataTableEntry(
    RtlGetCurrentPeb.Ldr.InLoadOrderModuleList.Flink);

  while (Start <> Current) and (Count <= MaximumCount) do
  begin
    Current := PLdrDataTableEntry(Current.InLoadOrderLinks.Flink);
    Inc(Count);
  end;

  SetLength(Entries, Count);

  // Save them
  Count := 0;
  Current := PLdrDataTableEntry(
    RtlGetCurrentPeb.Ldr.InLoadOrderModuleList.Flink);

  while (Start <> Current) and (Count <= MaximumCount) do
  begin
    Entries[Count] := Current;
    Current := PLdrDataTableEntry(Current.InLoadOrderLinks.Flink);
    Inc(Count);
  end;
end;

function LdrxEnumerateModuleInfo;
var
  Entries: TArray<PLdrDataTableEntry>;
  Lock: IAutoReleasable;
  i: Integer;
begin
  Result := LdrxAcquireLoaderLock(Lock);

  if not Result.IsSuccess then
    Exit;

  Result := LdrxEnumerateModuleEntries(Entries, MaximumCount);

  if not Result.IsSuccess then
    Exit;

  SetLength(Modules, Length(Entries));

  for i := 0 to High(Entries) do
    Modules[i] := LdrxpSaveEntry(Entries[i]);
end;

function LdrxFindModuleEntry;
var
  Count: Integer;
  Start: PLdrDataTableEntry;
  Lock: IAutoReleasable;
begin
  Result := LdrxAcquireLoaderLock(Lock);

  if not Result.IsSuccess then
    Exit;

  Start := PLdrDataTableEntry(@RtlGetCurrentPeb.Ldr.InLoadOrderModuleList);

  Count := 0;
  LdrEntry := PLdrDataTableEntry(
    RtlGetCurrentPeb.Ldr.InLoadOrderModuleList.Flink);

  // Iterate through modules, searching for the match
  while (Start <> LdrEntry) and (Count <= MaximumCount) do
  begin
    if Condition(LdrEntry) then
      Exit;

    LdrEntry := PLdrDataTableEntry(LdrEntry.InLoadOrderLinks.Flink);
    Inc(Count);
  end;

  Result.Location := 'LdrxFindModuleEntry';
  Result.Status := STATUS_NOT_FOUND;
end;

function LdrxFindModuleInfo;
var
  Count: Integer;
  Start, Current: PLdrDataTableEntry;
  Lock: IAutoReleasable;
begin
  Result := LdrxAcquireLoaderLock(Lock);

  if not Result.IsSuccess then
    Exit;

  Start := PLdrDataTableEntry(@RtlGetCurrentPeb.Ldr.InLoadOrderModuleList);

  Count := 0;
  Current := PLdrDataTableEntry(
    RtlGetCurrentPeb.Ldr.InLoadOrderModuleList.Flink);

  // Iterate through modules, searching for the match
  while (Start <> Current) and (Count <= MaximumCount) do
  begin
    Module := LdrxpSaveEntry(Current);

    if Condition(Module) then
      Exit;

    Current := PLdrDataTableEntry(Current.InLoadOrderLinks.Flink);
    Inc(Count);
  end;

  Result.Location := 'LdrxFindModuleInfo';
  Result.Status := STATUS_NOT_FOUND;
end;

function LdrxEntryStartsAt;
begin
  Result := function (Entry: PLdrDataTableEntry): Boolean
    begin
      Result := (Entry.DllBase = Address)
    end;
end;

function LdrxModuleStartsAt;
begin
  Result := function (const Module: TLdrxModuleInfo): Boolean
    begin
      Result :=(Module.DllBase = Address);
    end;
end;

function LdrxEntryContains;
begin
  Result := function (Entry: PLdrDataTableEntry): Boolean
    begin
      Result := (UIntPtr(Address) >= UIntPtr(Entry.DllBase)) and
        (UIntPtr(Address) - UIntPtr(Entry.DllBase) < Entry.SizeOfImage);
    end;
end;

function LdrxModuleContains;
begin
  Result := function (const Module: TLdrxModuleInfo): Boolean
    begin
      Result := Module.IsInRange(Address);
    end;
end;

function LdrxEntryBaseName;
begin
  Result := function (Entry: PLdrDataTableEntry): Boolean
    begin
      Result := RtlxEqualStrings(Entry.BaseDllName.ToString, DllName,
        CaseSensitive);
    end;
end;

function LdrxModuleBaseName;
begin
  Result := function (const Module: TLdrxModuleInfo): Boolean
    begin
      Result := RtlxEqualStrings(Module.BaseDllName, DllName,
        CaseSensitive);
    end;
end;

// Delphi doesn't support using the *external* keyword for importing variables;
// As a workaround, import LdrSystemDllInitBlock as a procedure and then convert
// its start address to a pointer in runtime.
procedure LdrSystemDllInitBlockPlaceholder; external ntdll
  name 'LdrSystemDllInitBlock';

function LdrSystemDllInitBlock: PPsSystemDllInitBlock;
var
  Import: PPointer;
begin
  // Extract a pointer to LdrSystemDllInitBlock from the jump table
  Import := ExternalImportTarget(@LdrSystemDllInitBlockPlaceholder);

  if Assigned(Import) then
    Result := Import^
  else
    Result := nil;
end;

{ TModuleEntry }

function TLdrxModuleInfo.IsInRange;
begin
  Result := (UIntPtr(DllBase) <= UIntPtr(Address)) and
    (UIntPtr(Address) <= UIntPtr(DllBase) + SizeOfImage);
end;

{ Debug Hooks }

{$IFDEF Debug}
var
  OldFailureHook: TDelayedLoadHook;

function BreakOnFailure(
  dliNotify: dliNotification;
  [in] pdli: PDelayLoadInfo
): Pointer; stdcall;
begin
  if RtlGetCurrentPeb.BeingDebugged then
    DbgBreakPoint;

  if Assigned(OldFailureHook) then
    OldFailureHook(dliNotify, pdli);

  Result := nil;
end;
{$ENDIF}

function TLdrxModuleInfo.Region;
begin
  Result.Address := DllBase;
  Result.Size := SizeOfImage;
end;

initialization
  {$IFDEF Debug}OldFailureHook := SetDliFailureHook2(BreakOnFailure);{$ENDIF}
end.
