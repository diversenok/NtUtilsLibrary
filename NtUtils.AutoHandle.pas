unit NtUtils.AutoHandle;

interface

type
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
