unit NtUtils.DbgHelp;

interface

uses
  NtUtils, Winapi.DbgHelp;

type
  ISymbolContext = interface (IAutoReleasable)
    function GetProcess: IHandle;
    property hxProcess: IHandle read GetProcess;
  end;

  ISymbolModule = interface (ISymbolContext)
    function GetBaseAddress: Pointer;
    property BaseAddress: Pointer read GetBaseAddress;
  end;

  TSymbolEntry = record
    RVA: UInt64;
    Tag: TSymTagEnum;
    Name: String;
  end;

// Initialize symbols for a process
function SymxIninialize(out SymContext: ISymbolContext; hxProcess: IHandle;
  Invade: Boolean): TNtxStatus;

// Load symbols for a module
function SymxLoadModule(out Module: ISymbolModule; Context: ISymbolContext;
  ImageName: String; hFile: THandle; Base: Pointer; Size: NativeUInt;
  LoadExternalSymbols: Boolean = True): TNtxStatus;

// Enumerate symbols in a module
function SymxEnumSymbols(out Symbols: TArray<TSymbolEntry>; Module:
  ISymbolModule; Mask: String = '*'): TNtxStatus;

// Enumerate symbols in a file
function SymxEnumSymboldFile(out Symbols: TArray<TSymbolEntry>; ImageName:
  String; LoadExternalSymbols: Boolean = True): TNtxStatus;

implementation

uses
  Winapi.WinNt, DelphiUtils.AutoObject, NtUtils.Processes;

type
  TAutoSymbolContext = class (TCustomAutoReleasable, ISymbolContext)
    hxProcess: IHandle;
    function GetProcess: IHandle;
    constructor Capture(Process: IHandle);
    destructor Destroy; override;
  end;

  TAutoSymbolModule = class (TCustomAutoMemory, ISymbolModule)
    hxProcess: IHandle;
    BaseAddress: Pointer;
    function GetProcess: IHandle;
    function GetBaseAddress: Pointer;
    constructor Capture(Process: IHandle; Address: Pointer);
    destructor Destroy; override;
  end;

{ TAutoSymbolContext }

constructor TAutoSymbolContext.Capture(Process: IHandle);
begin
  inherited Create;
  hxProcess := Process;
end;

destructor TAutoSymbolContext.Destroy;
begin
  if FAutoRelease then
    SymCleanup(hxProcess.Handle);

  inherited;
end;

function TAutoSymbolContext.GetProcess: IHandle;
begin
  Result := hxProcess;
end;

{ TAutoSymbolModule }

constructor TAutoSymbolModule.Capture(Process: IHandle; Address: Pointer);
begin
  inherited Create;
  hxProcess := Process;
  BaseAddress := Address;
end;

destructor TAutoSymbolModule.Destroy;
begin
  if FAutoRelease then
    SymUnloadModule64(hxProcess.Handle, BaseAddress);

  inherited;
end;

function TAutoSymbolModule.GetBaseAddress: Pointer;
begin
  Result := BaseAddress;
end;

function TAutoSymbolModule.GetProcess: IHandle;
begin
  Result := hxProcess;
end;

{ Functions }

function SymxIninialize(out SymContext: ISymbolContext; hxProcess: IHandle;
  Invade: Boolean): TNtxStatus;
begin
  Result.Location := 'SymInitializeW';
  Result.Win32Result := SymInitializeW(hxProcess.Handle, nil, Invade);

  if Result.IsSuccess then
    SymContext := TAutoSymbolContext.Capture(hxProcess);
end;

function SymxLoadModule(out Module: ISymbolModule; Context: ISymbolContext;
  ImageName: String; hFile: THandle; Base: Pointer; Size: NativeUInt;
  LoadExternalSymbols: Boolean): TNtxStatus;
var
  BaseAddress: Pointer;
  Flags: Cardinal;
begin
  // Should we search for DBG or PDB files that the module references?
  if LoadExternalSymbols then
    Flags := 0
  else
    Flags := SLMFLAG_NO_SYMBOLS;

  Result.Location := 'SymLoadModuleExW';
  BaseAddress := SymLoadModuleExW(Context.hxProcess.Handle, hFile,
    PWideChar(ImageName), nil, Base, Size, nil, Flags);
  Result.Win32Result := Assigned(BaseAddress);

  if Result.IsSuccess then
    Module := TAutoSymbolModule.Capture(Context.hxProcess, BaseAddress);
end;

function EnumCallback(const SymInfo: TSymbolInfoW; SymbolSize: Cardinal;
  var UserContext): LongBool; stdcall;
var
  Collection: TArray<TSymbolEntry> absolute UserContext;
begin
  SetLength(Collection, Length(Collection) + 1);

  with Collection[High(Collection)] do
  begin
    RVA := UIntPtr(SymInfo.Address) - UIntPtr(SymInfo.ModBase);
    Tag := SymInfo.Tag;
    SetString(Name, PWideChar(@SymInfo.Name), SymInfo.NameLen);
  end;

  Result := True;
end;

function SymxEnumSymbols(out Symbols: TArray<TSymbolEntry>; Module:
  ISymbolModule; Mask: String): TNtxStatus;
begin
  Symbols := nil;

  Result.Location := 'SymEnumSymbolsW';
  Result.Win32Result := SymEnumSymbolsW(Module.hxProcess.Handle,
    Module.BaseAddress, PWideChar(Mask), EnumCallback, Symbols);

  if not Result.IsSuccess then
    Symbols := nil;
end;

function SymxEnumSymboldFile(out Symbols: TArray<TSymbolEntry>; ImageName:
  String; LoadExternalSymbols: Boolean): TNtxStatus;
const
  DEFAULT_BASE = Pointer($1);
var
  hxProcess: IHandle;
  Context: ISymbolContext;
  Module: ISymbolModule;
begin
  // Create a unique handle to the current process to avoid collisions
  Result := NtxOpenCurrentProcess(hxProcess, MAXIMUM_ALLOWED);

  if not Result.IsSuccess then
    Exit;

  Result := SymxIninialize(Context, hxProcess, False);

  if not Result.IsSuccess then
    Exit;

  // When loading PDB or DBG files, we cannot supply null pointer as a base
  // address. However, since we are interested only in RVAs, we can use
  // any other value of our choice.

  Result := SymxLoadModule(Module, Context, ImageName, 0, DEFAULT_BASE, 0,
    LoadExternalSymbols);

  if not Result.IsSuccess then
    Exit;

  Result := SymxEnumSymbols(Symbols, Module);
end;

end.
