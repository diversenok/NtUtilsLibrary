unit NtUtils.DbgHelp;

interface

uses
  Winapi.DbgHelp, NtUtils, NtUtils.Ldr;

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
    Size: Cardinal;
    Flags: TSymbolFlags;
    Tag: TSymTagEnum;
    Name: String;
  end;

  TBestMatchSymbol = record
    Module: TModuleEntry;
    Symbol: TSymbolEntry;
    Offset: UInt64;
    function ToString: String;
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
function SymxEnumSymbolsFile(out Symbols: TArray<TSymbolEntry>; ImageName:
  String; LoadExternalSymbols: Boolean = True): TNtxStatus;

// Find the nearest symbol to the corresponding RVA
function SymxFindBestMatch(const Module: TModuleEntry; const Symbols:
  TArray<TSymbolEntry>; RVA: UInt64): TBestMatchSymbol;

implementation

uses
  Winapi.WinNt, DelphiUtils.AutoObject, NtUtils.Processes, NtUtils.SysUtils;

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

{ TBestMatchSymbol }

function TBestMatchSymbol.ToString: String;
begin
  Result := Module.BaseDllName;

  if Symbol.Name <> '' then
    Result := Result + '!' + Symbol.Name;

  if Offset <> 0 then
    Result := Result + '+' + RtlxIntToStr(Offset, 16);
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
    Size := SymInfo.Size;
    Flags := SymInfo.Flags;
    Tag := SymInfo.Tag;
    RtlxSetStringW(Name, PWideChar(@SymInfo.Name), SymInfo.NameLen);
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

function SymxEnumSymbolsFile(out Symbols: TArray<TSymbolEntry>; ImageName:
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

function SymxFindBestMatch(const Module: TModuleEntry; const Symbols:
  TArray<TSymbolEntry>; RVA: UInt64): TBestMatchSymbol;
var
  i: Integer;
  Distance: UInt64;
  BestMatch: Integer;
begin
  BestMatch := -1;
  Distance := UInt64(-1);

  for i := 0 to High(Symbols) do
    if (Symbols[i].RVA <> 0) and (Symbols[i].RVA <= RVA) and
      (RVA - Symbols[i].RVA < Distance) then
    begin
      Distance := RVA - Symbols[i].RVA;
      BestMatch := i;
    end;

  if BestMatch < 0 then
  begin
    // Make a pseudo-symbol for the whole module
    Result.Symbol.RVA := 0;
    Result.Symbol.Size := Module.SizeOfImage;
    Result.Symbol.Flags := SYMFLAG_VIRTUAL;
    Result.Symbol.Tag := TSymTagEnum.SymTagExe;
    Result.Symbol.Name := '';
  end
  else
    Result.Symbol := Symbols[BestMatch];

  Result.Module := Module;
  Result.Offset := RVA - Result.Symbol.RVA;
end;

end.
