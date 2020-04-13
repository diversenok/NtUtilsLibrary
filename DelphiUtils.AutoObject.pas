unit DelphiUtils.AutoObject;

interface

type
  { Interfaces}

  IAutoReleasable = interface
    procedure SetAutoRelease(Value: Boolean);
    property AutoRelease: Boolean write SetAutoRelease;
  end;

  IHandle = interface(IAutoReleasable)
    function Handle: THandle;
  end;

  IMemory = interface(IAutoReleasable)
    function Address: Pointer;
    function Size: NativeUInt;
  end;

  IMemory<P> = interface(IMemory) // P should be a Pointer type
    function Data: P;

    // Redefine all inherited functions here. Our code seems to confuse
    // Delphi's autocompletion features otherwise.
    function Address: Pointer;
    function Size: NativeUInt;
    procedure SetAutoRelease(Value: Boolean);
    property AutoRelease: Boolean write SetAutoRelease;
  end;

  { Structures }

  TMemory = record
    Address: Pointer;
    Size: NativeUInt;
  end;

  { Base classes }

  TCustomAutoReleasable = class(TInterfacedObject)
  protected
    FAutoRelease: Boolean;
  public
    constructor Create;
    procedure SetAutoRelease(Value: Boolean); virtual;
  end;

  TCustomAutoHandle = class(TCustomAutoReleasable)
  protected
    FHandle: THandle;
  public
    constructor Capture(hObject: THandle);
    function Handle: THandle; virtual;
  end;

  TCustomAutoMemory = class(TCustomAutoReleasable)
  protected
    FAddress: Pointer;
    FSize: NativeUInt;
  public
    constructor Capture(Address: Pointer; Size: NativeUInt); overload;
    constructor Capture(Region: TMemory); overload;
    function Address: Pointer; virtual;
    function Size: NativeUInt; virtual;
  end;

  TCustomAutoMemory<P> = class(TCustomAutoReleasable)
  protected
    FData: P;
    FSize: NativeUInt;
  public
    constructor Capture(Address: Pointer; Size: NativeUInt); overload;
    function Data: P; virtual;
    function Address: Pointer; virtual;
    function Size: NativeUInt; virtual;
  end;

  { Default implementations }

  // Auto-releases Delphi memory with FreeMem
  TAutoMemory = class (TCustomAutoMemory, IMemory)
    constructor Allocate(Size: NativeUInt);
    constructor CaptureCopy(Buffer: Pointer; Size: NativeUInt);
    destructor Destroy; override;
  end;

  // Auto-releases Delphi memory of a generic pointer type with FreeMem
  TAutoMemory<P> = class (TCustomAutoMemory<P>, IMemory<P>)
    constructor Allocate(Size: NativeUInt);
    constructor CaptureCopy(Buffer: Pointer; Size: NativeUInt);
    destructor Destroy; override;
  end;

  TAutoMemoryP = class abstract
    // Since using TAutoMemory<P>'s constructors in-place confuses Delphi's
    // autocompletion feature, here are the static methods that simply
    // forward the calls to TAutoMemory<P>.
    class function Allocate<P>(Size: NativeUInt): IMemory<P>;
    class function CaptureCopy<P>(Buffer: Pointer; Size: NativeUInt): IMemory<P>;
  end;

implementation

{ TCustomAutoReleasable }

constructor TCustomAutoReleasable.Create;
begin
  FAutoRelease := True;
end;

procedure TCustomAutoReleasable.SetAutoRelease(Value: Boolean);
begin
  FAutoRelease := Value;
end;

{ TCustomAutoHandle }

constructor TCustomAutoHandle.Capture(hObject: THandle);
begin
  inherited Create;
  FHandle := hObject;
end;

function TCustomAutoHandle.Handle: THandle;
begin
  Result := FHandle;
end;

{ TCustomAutoMemory }

function TCustomAutoMemory.Address: Pointer;
begin
  Result := FAddress;
end;

constructor TCustomAutoMemory.Capture(Address: Pointer; Size: NativeUInt);
begin
  inherited Create;
  FAddress := Address;
  FSize := Size;
end;

constructor TCustomAutoMemory.Capture(Region: TMemory);
begin
  Capture(Region.Address, Region.Size);
end;

function TCustomAutoMemory.Size: NativeUInt;
begin
  Result := FSize;
end;

{ TCustomAutoMemory<P> }

function TCustomAutoMemory<P>.Address: Pointer;
begin
  Result := PPointer(@FData)^;
end;

constructor TCustomAutoMemory<P>.Capture(Address: Pointer; Size: NativeUInt);
begin
  Assert(SizeOf(P) = SizeOf(Pointer),
    'TCustomAutoMemory<P> requires a pointer type.');

  PPointer(@FData)^ := Address;
  FSize := Size;
end;

function TCustomAutoMemory<P>.Data: P;
begin
  Result := FData;
end;

function TCustomAutoMemory<P>.Size: NativeUInt;
begin
  Result := FSize;
end;

{ TAutoMemory }

constructor TAutoMemory.Allocate(Size: NativeUInt);
begin
  Capture(AllocMem(Size), Size);
end;

constructor TAutoMemory.CaptureCopy(Buffer: Pointer; Size: NativeUInt);
begin
  Allocate(Size);
  Move(Buffer^, FAddress^, Size);
end;

destructor TAutoMemory.Destroy;
begin
  if FAutoRelease then
    FreeMem(FAddress);
  inherited;
end;

{ TAutoMemory<P> }

constructor TAutoMemory<P>.Allocate(Size: NativeUInt);
begin
  Capture(AllocMem(Size), Size);
end;

constructor TAutoMemory<P>.CaptureCopy(Buffer: Pointer; Size: NativeUInt);
begin
  Allocate(Size);
  Move(Buffer^, PPointer(@FData)^^, Size);
end;

destructor TAutoMemory<P>.Destroy;
begin
  if FAutoRelease then
    FreeMem(PPointer(@FData)^);
  inherited;
end;

{ TAutoMemoryP }

class function TAutoMemoryP.Allocate<P>(Size: NativeUInt): IMemory<P>;
begin
  Result := TAutoMemory<P>.Allocate(Size);
end;

class function TAutoMemoryP.CaptureCopy<P>(Buffer: Pointer;
  Size: NativeUInt): IMemory<P>;
begin
  Result := TAutoMemory<P>.CaptureCopy(Buffer, Size);
end;

end.
