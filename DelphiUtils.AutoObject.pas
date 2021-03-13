unit DelphiUtils.AutoObject;

{
  This module provides the core facilities for automatic lifetime management
  for resources that require cleanup. When interactining with such resources
  through interfaces, Delphi automatically emits code that counts outstanding
  references and immediately releases the underlying resource when this value
  drops to zero. Here you can find the definitions for the interfaces, as
  well as their default implementations.
}

interface

type
  { Structures }

  TMemory = record
    Address: Pointer;
    Size: NativeUInt;
    class function From(Address: Pointer; Size: NativeUInt): TMemory; static;
    class function Reference<T>(const [ref] Buffer: T): TMemory; static;
  end;

  { Interfaces}

  //  Every resource that requires cleanup should implement this interface
  IAutoReleasable = interface
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean);
    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
  end;

  // A resource, defined by a THandle value
  IHandle = interface(IAutoReleasable)
    function GetHandle: THandle;
    property Handle: THandle read GetHandle;
  end;

  // A memory allocation with a custom undelying pointer type.
  // You can safely cast between IMemory<P1> and IMemory<P2> when necessary.
  IMemory<P> = interface(IAutoReleasable) // P must be a Pointer type
    ['{171B8E12-F2AE-480E-8095-78A5D8114993}']
    function GetAddress: P;
    function GetSize: NativeUInt;
    function GetRegion: TMemory;
    property Data: P read GetAddress;
    property Size: NativeUInt read GetSize;
    property Region: TMemory read GetRegion;
    function Offset(Bytes: NativeUInt): Pointer;

    // Inheriting a generic interface from a non-generic one confuses Delphi's
    // autocompletion. Reintroduce inherited entries here to fix it.
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean);
    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
  end;

  // An untyped automatic memory
  IMemory = IMemory<Pointer>;

  IMem = class abstract
    // Get the underlying memory or nil
    class function RefOrNil<P>(Memory: IMemory<P>): P; static;
  end;

  { Base classes }

  TCustomAutoReleasable = class abstract (TInterfacedObject)
  protected
    FAutoRelease: Boolean;
  public
    constructor Create;
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean); virtual;
    procedure Release; virtual; abstract;
    destructor Destroy; override;
  end;

  TCustomAutoHandle = class abstract (TCustomAutoReleasable)
  protected
    FHandle: THandle;
  public
    constructor Capture(hObject: THandle);
    function GetHandle: THandle; virtual;
  end;

  TCustomAutoMemory = class abstract (TCustomAutoReleasable)
  protected
    FAddress: Pointer;
    FSize: NativeUInt;
  public
    constructor Capture(Address: Pointer; Size: NativeUInt);
    function GetAddress: Pointer;
    function GetSize: NativeUInt;
    function GetRegion: TMemory;
    function Offset(Bytes: NativeUInt): Pointer;
  end;

  { Default implementations }

  // Auto-releases Delphi memory of a generic pointer type with FreeMem.
  // You can cast the result to an arbitrary IMemory<P> by using a left-side
  // cast to an untyped IMemory (aka IMemory<Pointer>):
  //
  //   var
  //     x: IMemory<PMyRecordType>;
  //   begin
  //     IMemory(x) := TAutoMemory.Allocate(SizeOf(TMyRecordType));
  //   end;
  //
  TAutoMemory = class (TCustomAutoMemory, IMemory)
    constructor Allocate(Size: NativeUInt);
    constructor CaptureCopy(Buffer: Pointer; Size: NativeUInt);
    procedure SwapWith(Instance: TAutoMemory);
    procedure Release; override;
  end;

  TOperation = reference to procedure;

  // Automatically performs an operation when the object goes out of scope
  TDelayedOperation = class (TCustomAutoReleasable, IAutoReleasable)
    FOperation: TOperation;
    constructor Create(Operation: TOperation);
    procedure Release; override;
  end;

implementation

{ TMemory }

class function TMemory.From;
begin
  Result.Address := Address;
  Result.Size := Size;
end;

class function TMemory.Reference<T>;
begin
  Result.Address := @Buffer;
  Result.Size := SizeOf(Buffer);
end;

{ IMem }

class function IMem.RefOrNil<P>;
var
  ResultAsPtr: Pointer absolute Result;
begin
  if Assigned(Memory) then
    Result := Memory.Data
  else
    ResultAsPtr := nil;
end;

{ TCustomAutoReleasable }

constructor TCustomAutoReleasable.Create;
begin
  FAutoRelease := True;
end;

destructor TCustomAutoReleasable.Destroy;
begin
  if FAutoRelease then
    Release;

  inherited;
end;

function TCustomAutoReleasable.GetAutoRelease;
begin
  Result := FAutoRelease;
end;

procedure TCustomAutoReleasable.SetAutoRelease;
begin
  FAutoRelease := Value;
end;

{ TCustomAutoHandle }

constructor TCustomAutoHandle.Capture;
begin
  inherited Create;
  FHandle := hObject;
end;

function TCustomAutoHandle.GetHandle: THandle;
begin
  Result := FHandle;
end;

{ TCustomAutoMemory }

constructor TCustomAutoMemory.Capture;
begin
  inherited Create;
  FAddress := Address;
  FSize := Size;
end;

function TCustomAutoMemory.GetAddress;
begin
  Result := FAddress;
end;

function TCustomAutoMemory.GetRegion;
begin
  Result.Address := FAddress;
  Result.Size := FSize;
end;

function TCustomAutoMemory.GetSize;
begin
  Result := FSize;
end;

function TCustomAutoMemory.Offset;
begin
  Result := PByte(FAddress) + Bytes;
end;

{ TAutoMemory }

constructor TAutoMemory.Allocate;
begin
  Capture(AllocMem(Size), Size);
end;

constructor TAutoMemory.CaptureCopy;
begin
  Allocate(Size);
  Move(Buffer^, FAddress^, Size);
end;

procedure TAutoMemory.Release;
begin
  FreeMem(FAddress);
  inherited;
end;

procedure TAutoMemory.SwapWith;
begin
  FAddress := AtomicExchange(Instance.FAddress, FAddress);
  FSize := AtomicExchange(Instance.FSize, FSize);
end;

{ TDelayedOperation }

constructor TDelayedOperation.Create;
begin
  inherited Create;
  FOperation := Operation;
end;

procedure TDelayedOperation.Release;
begin
  if Assigned(FOperation) then
    FOperation;

  inherited
end;

end.
