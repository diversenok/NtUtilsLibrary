unit DelphiUtils.AutoObject;

interface

type
  { Interfaces}

  IAutoReleasable = interface
    procedure SetAutoRelease(Value: Boolean);
    property AutoRelease: Boolean write SetAutoRelease;
  end;

  IHandle = interface(IAutoReleasable)
    function GetHandle: THandle;
    property Handle: THandle read GetHandle;
  end;

  IMemory<P> = interface(IAutoReleasable) // P should be a Pointer type
    ['{171B8E12-F2AE-480E-8095-78A5D8114993}']
    function GetAddress: P;
    function GetSize: NativeUInt;
    property Data: P read GetAddress;
    property Size: NativeUInt read GetSize;
  end;

  IMemory = IMemory<Pointer>;

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
    function GetHandle: THandle; virtual;
  end;

  TCustomAutoMemory<P> = class(TCustomAutoReleasable)
  protected
    FAddress: Pointer;
    FSize: NativeUInt;
  public
    constructor Capture(Address: Pointer; Size: NativeUInt);
    function GetAddress: P; virtual;
    function GetSize: NativeUInt; virtual;
  end;

  { Default implementations }

  // Auto-releases Delphi memory of a generic pointer type with FreeMem
  TAutoMemory<P> = class (TCustomAutoMemory<P>, IMemory<P>)
    constructor Allocate(Size: NativeUInt);
    constructor CaptureCopy(Buffer: Pointer; Size: NativeUInt);
    destructor Destroy; override;
  end;

  TAutoMemory = TAutoMemory<Pointer>;

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

function TCustomAutoHandle.GetHandle: THandle;
begin
  Result := FHandle;
end;

{ TCustomAutoMemory<P> }

constructor TCustomAutoMemory<P>.Capture(Address: Pointer; Size: NativeUInt);
begin
  Assert(SizeOf(P) = SizeOf(Pointer),
    'TCustomAutoMemory<P> requires a pointer type.');

  FAddress := Address;
  FSize := Size;
end;

function TCustomAutoMemory<P>.GetAddress: P;
var
  Memory: Pointer absolute Result;
begin
  Memory := FAddress;
end;

function TCustomAutoMemory<P>.GetSize: NativeUInt;
begin
  Result := FSize;
end;

{ TAutoMemory<P> }

constructor TAutoMemory<P>.Allocate(Size: NativeUInt);
begin
  Capture(AllocMem(Size), Size);
end;

constructor TAutoMemory<P>.CaptureCopy(Buffer: Pointer; Size: NativeUInt);
begin
  Allocate(Size);
  Move(Buffer^, FAddress^, Size);
end;

destructor TAutoMemory<P>.Destroy;
begin
  if FAutoRelease then
    FreeMem(FAddress);
  inherited;
end;

end.
