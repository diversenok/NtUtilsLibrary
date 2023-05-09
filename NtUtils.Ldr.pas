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

  TModuleEntry = record
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

  TModuleFinder = reference to function (const Module: TModuleEntry): Boolean;

{ Delayed Import Checks }

// Pre-load a DLL for delay loading
function LdrxCheckDelayedModule(
  var Module: TDelayedLoadDll
): TNtxStatus;

// Check if a function is present in a dll and load it if necessary
function LdrxCheckDelayedImport(
  var Module: TDelayedLoadDll;
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
  out Unloader: IAutoReleasable;
  [out, opt] outDllBase: PPDllBase = nil
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
  out ResourseString: String;
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

// Enumerate all loaded modules
function LdrxEnumerateModules: TArray<TModuleEntry>;

// Find a module that satisfies a condition
function LdrxFindModule(
  out Module: TModuleEntry;
  const Condition: TModuleFinder
): TNtxStatus;

// Provides a finder for a module that contains a specific address;
// Use @ImageBase to find the current module
function ContainingAddress(
  [in] Address: Pointer
): TModuleFinder;

// Provides a finder for a module with a specific base name
function ByBaseName(
  const DllName: String;
  CaseSensitive: Boolean = False
): TModuleFinder;

// Retrieves shared NTDLL information
function LdrSystemDllInitBlock: PPsSystemDllInitBlock;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntdbg, Ntapi.ntstatus, Ntapi.ImageHlp,
  NtUtils.SysUtils, DelphiUtils.AutoObjects, DelphiUtils.ExternalImport;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Delayed Import Checks }

function LdrxCheckDelayedModule;
var
  DllStr: TNtUnicodeString;
begin
  if Assigned(Module.DllAddress) then
  begin
    // Already loaded
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  // Even if we previously failed to load the DLL, retry anyway because we
  // might run with a different security or activation context
  DllStr.Length := Length(Module.DllName) * SizeOf(WideChar);
  DllStr.MaximumLength := DllStr.Length + SizeOf(WideChar);
  DllStr.Buffer := Module.DllName;

  Result.Location := 'LdrLoadDll';
  Result.LastCall.Parameter := String(Module.DllName);
  Result.Status := LdrLoadDll(nil, nil, DllStr, PDllBase(Module.DllAddress));
end;

function LdrxCheckDelayedImport;
var
  FunctionStr: TNtAnsiString;
begin
  if Assigned(Routine.FunctionAddress) then
  begin
    // Function is available (either already checked or manually redirected)
    Result.Status := STATUS_SUCCESS;
    Exit;
  end;

  if Routine.Checked then
  begin
    // Function already checked and not available
    Result.Location := 'LdrGetProcedureAddress';
    Result.Status := Routine.CheckStatus;
  end
  else
  begin
    // Function not checked yet; check the module first
    Result := LdrxCheckDelayedModule(Module);

    if Assigned(Module.DllAddress) then
    begin
      // The module is available; locate the function
      FunctionStr.Length := Length(Routine.FunctionName) * SizeOf(AnsiChar);
      FunctionStr.MaximumLength := FunctionStr.Length + SizeOf(AnsiChar);
      FunctionStr.Buffer := Routine.FunctionName;

      Result.Location := 'LdrGetProcedureAddress';
      Result.Status := LdrGetProcedureAddress(Module.DllAddress, FunctionStr, 0,
        Routine.FunctionAddress);

      // Save the result
      Routine.CheckStatus := Result.Status;
      Routine.Checked := True;
    end;
  end;

  // Attach failure details
  if not Result.IsSuccess then
    Result.LastCall.Parameter := String(Module.DllName) + '!' +
      String(Routine.FunctionName);
end;

{ DLL Operations }

function LdrxGetDllHandle;
begin
  Result.Location := 'LdrGetDllHandle';
  Result.LastCall.Parameter := DllName;
  Result.Status := LdrGetDllHandle(nil, nil, TNtUnicodeString.From(DllName),
    DllBase);
end;

function LdrxUnloadDll;
begin
  Result.Location := 'LdrUnloadDll';
  Result.Status := LdrUnloadDll(DllBase);
end;

function LdrxLoadDll;
var
  DllBase: PDllBase;
begin
  Result.Location := 'LdrLoadDll';
  Result.LastCall.Parameter := DllName;
  Result.Status := LdrLoadDll(nil, nil, TNtUnicodeString.From(DllName),
    DllBase);

  if Result.IsSuccess and Assigned(outDllBase) then
    outDllBase^ := DllBase;
end;

function LdrxLoadDllAuto;
var
  DllBase: PDllBase;
begin
  Result := LdrxLoadDll(DllName, @DllBase);

  if not Result.IsSuccess then
    Exit;

  Unloader := Auto.Delay(
    procedure
    begin
      LdrUnloadDll(DllBase);
    end
  );

  if Assigned(outDllBase) then
    outDllBase^ := DllBase;
end;

function LdrxGetProcedureAddress;
begin
  Result.Location := 'LdrGetProcedureAddress';
  Result.LastCall.Parameter := String(ProcedureName);
  Result.Status := LdrGetProcedureAddress(DllBase,
    TNtAnsiString.From(ProcedureName), 0, Address);
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
    SetString(ResourseString, Buffer, BufferLength);
end;

{ Low-level Access }

type
  TAutoDllCallback = class (TCustomAutoReleasable, IAutoReleasable)
    FCookie: NativeUInt;
    FCallback: TDllNotification;
    procedure Release; override;
    constructor Create(
      Cookie: NativeUInt;
      const Callback: TDllNotification
    );
  end;

constructor TAutoDllCallback.Create;
var
  CallbackIntf: IInterface absolute Callback;
begin
  inherited Create;
  FCookie := Cookie;
  FCallback := Callback;
  CallbackIntf._AddRef;
end;

procedure TAutoDllCallback.Release;
var
  Callback: TDllNotification;
  CallbackIntf: IInterface absolute Callback;
begin
  LdrUnregisterDllNotification(FCookie);
  Callback := FCallback;
  CallbackIntf._Release;
  inherited;
end;

procedure LdrxNotificationDispatcher(
  NotificationReason: TLdrDllNotificationReason;
  const NotificationData: TLdrDllNotificationData;
  [in, opt] Context: Pointer
); stdcall;
var
  Callback: TDllNotification absolute Context;
begin
  if Assigned(Callback) then
    Callback(NotificationReason, NotificationData);
end;

function LdrxRegisterDllNotification;
var
  Cookie: NativeUInt;
  Context: Pointer absolute Callback;
begin
  Result.Location := 'LdrRegisterDllNotification';
  Result.Status := LdrRegisterDllNotification(0, LdrxNotificationDispatcher,
    Context, Cookie);

  if Result.IsSuccess then
    Registration := TAutoDllCallback.Create(Cookie, Callback);
end;

type
  TAutoLoaderLock = class (TCustomAutoReleasable, IAutoReleasable)
    FCookie: NativeUInt;
    constructor Create(Cookie: NativeUInt);
    procedure Release; override;
  end;

constructor TAutoLoaderLock.Create;
begin
  inherited Create;
  FCookie := Cookie;
end;

procedure TAutoLoaderLock.Release;
begin
  LdrUnlockLoaderLock(0, FCookie);
  inherited;
end;

function LdrxAcquireLoaderLock;
var
  Cookie: NativeUInt;
begin
  Result.Location := 'LdrLockLoaderLock';
  Result.Status := LdrLockLoaderLock(0, nil, Cookie);

  if Result.IsSuccess then
    Lock := TAutoLoaderLock.Create(Cookie);
end;

function LdrxpSaveEntry([in] pTableEntry: PLdrDataTableEntry): TModuleEntry;
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

function LdrxEnumerateModules;
var
  Count: Integer;
  Start, Current: PLdrDataTableEntry;
  Lock: IAutoReleasable;
begin
  if not LdrxAcquireLoaderLock(Lock).IsSuccess then
    Exit(nil);

  Start := PLdrDataTableEntry(@RtlGetCurrentPeb.Ldr.InLoadOrderModuleList);

  // Count the number of modules
  Count := 0;
  Current := PLdrDataTableEntry(
    RtlGetCurrentPeb.Ldr.InLoadOrderModuleList.Flink);

  while (Start <> Current) and (Count <= MAX_MODULES) do
  begin
    Current := PLdrDataTableEntry(Current.InLoadOrderLinks.Flink);
    Inc(Count);
  end;

  SetLength(Result, Count);

  // Save them
  Count := 0;
  Current := PLdrDataTableEntry(
    RtlGetCurrentPeb.Ldr.InLoadOrderModuleList.Flink);

  while (Start <> Current) and (Count <= MAX_MODULES) do
  begin
    Result[Count] := LdrxpSaveEntry(Current);
    Current := PLdrDataTableEntry(Current.InLoadOrderLinks.Flink);
    Inc(Count);
  end;
end;

function LdrxFindModule;
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
  while (Start <> Current) and (Count <= MAX_MODULES) do
  begin
    Module := LdrxpSaveEntry(Current);

    if Condition(Module) then
    begin
      Result.Status := STATUS_SUCCESS;
      Exit;
    end;

    Current := PLdrDataTableEntry(Current.InLoadOrderLinks.Flink);
    Inc(Count);
  end;

  Result.Location := 'LdrxFindModule';
  Result.Status := STATUS_NOT_FOUND;
end;

function ContainingAddress;
begin
  Result := function (const Module: TModuleEntry): Boolean
    begin
      Result := Module.IsInRange(Address);
    end;
end;

function ByBaseName;
begin
  Result := function (const Module: TModuleEntry): Boolean
    begin
      Result := RtlxCompareStrings(Module.BaseDllName, DllName,
        CaseSensitive) = 0;
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

function TModuleEntry.IsInRange;
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

function TModuleEntry.Region;
begin
  Result.Address := DllBase;
  Result.Size := SizeOfImage;
end;

initialization
  {$IFDEF Debug}OldFailureHook := SetDliFailureHook2(BreakOnFailure);{$ENDIF}
end.
