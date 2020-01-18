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
    constructor Capture(Address: Pointer; Size: NativeUInt);
    function Address: Pointer;
    function Size: NativeUInt;
  end;

  { Default implementations }

  // Auto-releases Delphi memory with FreeMem
  TAutoMemory = class (TCustomAutoMemory, IMemory)
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

function TCustomAutoMemory.Size: NativeUInt;
begin
  Result := FSize;
end;

{ TAutoMemory }

destructor TAutoMemory.Destroy;
begin
  if FAutoRelease then
    FreeMem(FAddress);
  inherited;
end;

end.
