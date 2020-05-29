unit DelphiUtils.AutoObject;

interface

type
  { Structures }

  TMemory = record
    Address: Pointer;
    Size: NativeUInt;
  end;

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
    function GetRegion: TMemory;
    property Data: P read GetAddress;
    property Size: NativeUInt read GetSize;
    property Region: TMemory read GetRegion;
    function Offset(Bytes: NativeUInt): Pointer;

    // Inheriting a generic interface from a non-generic one confuses Delphi's
    // autocompletion. Reintroduce inherited entries here to fix it.
    procedure SetAutoRelease(Value: Boolean);
    property AutoRelease: Boolean write SetAutoRelease;
  end;

  IMemory = IMemory<Pointer>;

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

  TCustomAutoMemory = class(TCustomAutoReleasable)
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

  // Auto-releases Delphi memory of a generic pointer type with FreeMem
  TAutoMemory = class (TCustomAutoMemory, IMemory)
    constructor Allocate(Size: NativeUInt);
    constructor CaptureCopy(Buffer: Pointer; Size: NativeUInt);
    destructor Destroy; override;
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

function TCustomAutoHandle.GetHandle: THandle;
begin
  Result := FHandle;
end;

{ TCustomAutoMemory }

constructor TCustomAutoMemory.Capture(Address: Pointer; Size: NativeUInt);
begin
  inherited Create;
  FAddress := Address;
  FSize := Size;
end;

function TCustomAutoMemory.GetAddress: Pointer;
begin
  Result := FAddress;
end;

function TCustomAutoMemory.GetRegion: TMemory;
begin
  Result.Address := FAddress;
  Result.Size := FSize;
end;

function TCustomAutoMemory.GetSize: NativeUInt;
begin
  Result := FSize;
end;

function TCustomAutoMemory.Offset(Bytes: NativeUInt): Pointer;
begin
  Result := PByte(FAddress) + Bytes;
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

end.
