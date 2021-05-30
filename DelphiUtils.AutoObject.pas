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
  //  Every resource that requires cleanup should implement this interface
  IAutoReleasable = interface
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean);
    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
  end;

  // An automatic resource, defined by a THandle value
  IHandle = interface(IAutoReleasable)
    function GetHandle: THandle;
    property Handle: THandle read GetHandle;
  end;

  // Describes a memory region
  TMemory = record
    Address: Pointer;
    Size: NativeUInt;
    function Offset(Bytes: NativeUInt): Pointer;
    class function From(Address: Pointer; Size: NativeUInt): TMemory; static;
    class function Reference<T>(const [ref] Buffer: T): TMemory; static;
  end;

  // An automatic memory allocation with a custom undelying pointer type.
  // You can safely cast between IMemory<P1> and IMemory<P2> when necessary.
  IMemory<P> = interface(IAutoReleasable) // P must be a Pointer type
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
    class function RefOrNil<P>(const Memory: IMemory<P>): P; static;
  end;

  // An automatic wrapper that maintains ownership over a reference/value type
  // and frees the undelying object when the last reference goes out of scope.
  IAutoObject<T> = interface (IAutoReleasable)
    function GetSelf: T;
    procedure SetSelf(const Value: T);
    property Self: T read GetSelf write SetSelf;

    // Inheriting a generic interface from a non-generic one confuses Delphi's
    // autocompletion. Reintroduce inherited entries here to fix it.
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean);
    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
  end;

  // An untyped automatic object
  IAutoObject = IAutoObject<TObject>;

  // A type for storing a weak reference to an interface
  Weak<T: IInterface> = record
  private
    [Weak] FWeakRef: T;
  public
    class operator Implicit(const StrongRef: T): Weak<T>;
    function Upgrade(out StrongRef: T): Boolean;
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
  //  var
  //    x: IMemory<PMyRecordType>;
  //  begin
  //    IMemory(x) := TAutoMemory.Allocate(SizeOf(TMyRecordType));
  //  end;
  //
  TAutoMemory = class (TCustomAutoMemory, IMemory)
    constructor Allocate(Size: NativeUInt);
    constructor CaptureCopy(Buffer: Pointer; Size: NativeUInt);
    procedure Release; override;
    procedure SwapWith(Instance: TAutoMemory);
  end;

  // Automatically releases a delphi class.
  TAutoObject = class (TCustomAutoReleasable, IAutoObject)
  protected
    FObject: TObject;
  public
    constructor Capture(Obj: TObject);
    procedure Release; override;
    function GetSelf: TObject;

    // The caller must free the old value if necessary!
    procedure SetSelf(const Value: TObject);
  end;

  // Automatically releases a delphi record.
  TAutoValue<T: record> = class (TCustomAutoReleasable, IAutoObject<T>)
  protected
    FValue: T;
  public
    constructor Copy(const Value: T);
    function GetSelf: T;
    procedure SetSelf(const Value: T);
    procedure Release; override;
  end;

  // Auto helper offers simplified syntax for creating automatic objects:
  //
  //  var
  //    x: IAutoObject<TStringList>;
  //  begin
  //    x := Auto.FromRef(TStringList.Create);
  //    x.Self.Add('Hi there');
  //    x.Self.SaveToFile('test.txt');
  //  end;
  //
  Auto = class abstract
    class function FromRef<T : class>(Obj: T): IAutoObject<T>; static;
    class function FromValue<T : record>(const Value: T): IAutoObject<T>; static;
  end;

  TOperation = reference to procedure;

  // Automatically perform an operation when the object goes out of scope
  TDelayedOperation = class (TCustomAutoReleasable, IAutoReleasable)
  protected
    FOperation: TOperation;
    constructor Create(const Operation: TOperation);
  public
    procedure Release; override;
    class function Delay(const Operation: TOperation): IAutoReleasable; static;
  end;

implementation

{ TMemory }

class function TMemory.From;
begin
  Result.Address := Address;
  Result.Size := Size;
end;

function TMemory.Offset;
begin
  Result := PByte(Address) + Bytes;
end;

class function TMemory.Reference<T>;
begin
  Result.Address := @Buffer;
  Result.Size := SizeOf(Buffer);
end;

{ IMem }

class function IMem.RefOrNil<P>;
begin
  if Assigned(Memory) then
    Result := Memory.Data
  else
    Result := Default(P); // nil
end;

{ Weak<T> }

class operator Weak<T>.Implicit(const StrongRef: T): Weak<T>;
begin
  Result.FWeakRef := StrongRef;
end;

function Weak<T>.Upgrade;
begin
  StrongRef := FWeakRef;
  Result := Assigned(StrongRef);
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

{ TAutoObject }

constructor TAutoObject.Capture;
begin
  inherited Create;
  FObject := Obj;
end;

function TAutoObject.GetSelf;
begin
  Result := FObject;
end;

procedure TAutoObject.Release;
begin
  FObject.Free;
  inherited;
end;

procedure TAutoObject.SetSelf;
begin
  // Note: the caller is responsible for freeing the old value now!
  FObject := Value;
end;

{ TAutoValue<T> }

constructor TAutoValue<T>.Copy;
begin
  FValue := Value;
end;

function TAutoValue<T>.GetSelf;
begin
  Result := FValue;
end;

procedure TAutoValue<T>.Release;
begin
  inherited;
end;

procedure TAutoValue<T>.SetSelf;
begin
  FValue := Value;
end;

{ Auto }

class function Auto.FromRef<T>;
begin
  IAutoObject(Result) := TAutoObject.Capture(Obj);
end;

class function Auto.FromValue<T>;
begin
  Result := TAutoValue<T>.Copy(Value);
end;

{ TDelayedOperation }

constructor TDelayedOperation.Create;
begin
  inherited Create;
  FOperation := Operation;
end;

class function TDelayedOperation.Delay;
begin
  Result := TDelayedOperation.Create(Operation);
end;

procedure TDelayedOperation.Release;
begin
  if Assigned(FOperation) then
    FOperation;

  inherited
end;

end.
