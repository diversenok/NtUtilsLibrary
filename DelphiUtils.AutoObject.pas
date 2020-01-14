unit DelphiUtils.AutoObject;

interface

type
  { Memory }

  IMemory = interface
    function Address: Pointer;
    function Size: NativeUInt;
    procedure SetAutoClose(Value: Boolean);
    property AutoClose: Boolean write SetAutoClose;
  end;

  TCustomAutoMemory = class (TInterfacedObject, IMemory)
  protected
    FAutoClose: Boolean;
    FSize: NativeUInt;
    Buffer: Pointer;
  public
    constructor Capture(Address: Pointer; RegionSize: NativeUInt);
    procedure SetAutoClose(Value: Boolean);
    function Address: Pointer;
    function Size: NativeUInt;
  end;

  TAutoMemory = class (TCustomAutoMemory, IMemory)
    destructor Destroy; override;
  end;

  { Handles }

  IHandle = interface
    function Value: THandle;
    procedure SetAutoClose(Value: Boolean);
    property AutoClose: Boolean write SetAutoClose;
  end;

  TCustomAutoHandle = class(TInterfacedObject)
  protected
    FAutoClose: Boolean;
    Handle: THandle;
  public
    constructor Capture(hObject: THandle);
    procedure SetAutoClose(Value: Boolean);
    function Value: THandle;
  end;

implementation

{ TCustomAutoMemory }

function TCustomAutoMemory.Address: Pointer;
begin
  Result := Buffer;
end;

constructor TCustomAutoMemory.Capture(Address: Pointer; RegionSize: NativeUInt);
begin
  Buffer := Address;
  FSize := RegionSize;
  FAutoClose := True;
end;

procedure TCustomAutoMemory.SetAutoClose(Value: Boolean);
begin
  FAutoClose := Value;
end;

function TCustomAutoMemory.Size: NativeUInt;
begin
  Result := FSize;
end;

{ TAutoMemory }

destructor TAutoMemory.Destroy;
begin
  if FAutoClose then
    FreeMem(Buffer);
  inherited;
end;

{TCustomAutoHandle}

constructor TCustomAutoHandle.Capture(hObject: THandle);
begin
  Handle := hObject;
  FAutoClose := True;
end;

procedure TCustomAutoHandle.SetAutoClose(Value: Boolean);
begin
  FAutoClose := Value;
end;

function TCustomAutoHandle.Value: THandle;
begin
  Result := Handle;
end;

end.
