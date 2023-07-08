unit DelphiUtils.AutoObjects;

{
  This module provides the core facilities for automatic lifetime management
  for resources that require cleanup. When interactining with such resources
  through interfaces, Delphi automatically emits code that counts outstanding
  references and immediately releases the underlying resource when this value
  drops to zero. Here you can find the definitions for the interfaces, as
  well as their default implementations.

  The module defines the following hierarchy of interfaces:

                     +---> IHandle
                     |
  IAutoReleasable ---+---> IAutoObject<T>
                     |
                     +---> IAutoPointer<P> ---> IMemory<P>
}

interface

type
  // A wrapper for resources that implement automatic cleanup.
  IAutoReleasable = interface (IInterface)
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean);
    function GetReferenceCount: Integer;

    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
    property ReferenceCount: Integer read GetReferenceCount;
  end;

  // An automatically releaseable resource defined by a THandle value.
  IHandle = interface (IAutoReleasable)
    function GetHandle: THandle;
    property Handle: THandle read GetHandle;
  end;

  // An wrapper that automatically releases a Delphi class.
  // You can safely cast between IAutoObject<TClassA> and IAutoObject<TClassB>
  // whenever TClassA and TClassB form a compatible hierarchy.
  IAutoObject<T: class> = interface (IAutoReleasable)
    function GetSelf: T;
    property Self: T read GetSelf;
  end;

  // An untyped wrapper automatically releasing Delphi classes.
  IAutoObject = IAutoObject<TObject>;

  // A wrapper that automatically releases a record pointer. You can safely
  // cast between IAutoPointer<P1> and IAutoPointer<P2> when necessary.
  IAutoPointer<P> = interface (IAutoReleasable) // P must be a Pointer type
    function GetData: P;
    property Data: P read GetData;
  end;

  // A automatic wrapper for an untyped pointer.
  IAutoPointer = IAutoPointer<Pointer>;

  TMemory = record
    Address: Pointer;
    Size: NativeUInt;
    function Offset(Bytes: NativeUInt): Pointer;
    class function From(Address: Pointer; Size: NativeUInt): TMemory; static;
    class function Reference<T>(const [ref] Buffer: T): TMemory; static;
  end;

  // An wapper that automatically releases a memory region.
  // You can safely cast between IMemory<P1> and IMemory<P2> when necessary.
  IMemory<P> = interface(IAutoPointer<P>) // P must be a Pointer type
    property Data: P read GetData;
    function GetSize: NativeUInt;
    property Size: NativeUInt read GetSize;
    function GetRegion: TMemory;
    property Region: TMemory read GetRegion;
    function Offset(Bytes: NativeUInt): Pointer;
  end;

  // An untyped automatic memory region
  IMemory = IMemory<Pointer>;

  // A type for storing a weak reference to an interface
  Weak<I: IInterface> = record
  private
    [Weak] FWeakRef: I;
  public
    class operator Implicit(const StrongRef: I): Weak<I>;
    function Upgrade(out StrongRef: I): Boolean;
  end;

  // A prototype for a delayed operation
  TOperation = reference to procedure;

  Auto = class abstract
    // Automatically destroy an object when the last reference goes out of scope
    class function From<T: class>(&Object: T): IAutoObject<T>; static;

    // Create an automatically freeing dynamic memory allocation
    class function AllocateDynamic(Size: NativeUInt): IMemory; static;
    class function CopyDynamic(Buffer: Pointer; Size: NativeUInt): IMemory; static;

    // Create a boxed Delphi record with automatic memory management. Note that
    // it can include managed fields like long strings and dynamic arrays that
    // will be released automatically. Less commonly, T can also be any other
    // managed type (i.e., an interface, a string, a dynamic array, or an
    // anonymous function).
    class function Allocate<T>: IMemory; static;
    class function Copy<T>(const Buffer: T): IMemory; static;

    // A helper function for getting the underlying memory address or nil
    class function RefOrNil<P>(const Memory: IAutoPointer<P>): P; static;

    // Perform an operation defined by the callback when the last reference to
    // the object goes out of scope.
    class function Delay(Operation: TOperation): IAutoReleasable; static;
  end;

  { Base classes (for custom implementations) }

  TCustomAutoReleasable = class abstract (TInterfacedObject)
  protected
    FAutoRelease: Boolean;
    procedure Release; virtual; abstract;
  public
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean); virtual;
    function GetReferenceCount: Integer;
    procedure AfterConstruction; override;
    destructor Destroy; override;
  end;

  TCustomAutoHandle = class abstract (TCustomAutoReleasable)
  protected
    FHandle: THandle;
  public
    constructor Capture(hObject: THandle);
    function GetHandle: THandle;
  end;

  TCustomAutoPointer = class abstract (TCustomAutoReleasable)
  protected
    FData: Pointer;
  public
    constructor Capture(Address: Pointer);
    function GetData: Pointer;
  end;

  TCustomAutoMemory = class abstract (TCustomAutoPointer)
  protected
    FSize: NativeUInt;
  public
    constructor Capture(Address: Pointer; Size: NativeUInt);
    function GetSize: NativeUInt;
    function GetRegion: TMemory;
    function Offset(Bytes: NativeUInt): Pointer;
  end;

  { Default implementations }

  // A wrapper that maintains ownership over an instance of a Delphi class
  // derived from TObject.
  TAutoObject = class (TCustomAutoReleasable, IAutoObject)
  protected
    FObject: TObject;
    procedure Release; override;
    constructor Capture(&Object: TObject);
  public
    function GetSelf: TObject;
  end;

  // A wrapper that maintains ownership over a pointer to Delphi memory
  // managed via AllocMem/FreeMem.
  TAutoMemory = class (TCustomAutoMemory, IMemory)
  protected
    procedure Release; override;
    constructor Allocate(Size: NativeUInt);
    constructor Copy(Source: Pointer; Size: NativeUInt);
  end;

  // A wrapper that automatically releases a boxed managed Delphi type. It is
  // designed primarily for records, but can also hold other managed types
  // (both directly and as part of managed records). These include interfaces,
  // strings, dynamic arrays, and anonymous functions. This wrapper is similar
  // to TAutoMemory, but adds type-specific calls to Initialize/Finalize.
  TAutoManagedType<T> = class (TAutoMemory, IMemory)
  protected
    procedure Release; override;
    constructor Create;
    constructor Copy(const Value: T);
  end;

  // Automatically performs an operation on destruction.
  TDelayedOperation = class (TCustomAutoReleasable, IAutoReleasable)
  protected
    FOperation: TOperation;
    procedure Release; override;
    constructor Create(Operation: TOperation);
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TMemory }

class function TMemory.From;
begin
  Result.Address := Address;
  Result.Size := Size;

  {$IFOPT Q+}
  // Emit overflow checking
  if UIntPtr(Address) + Size < UIntPtr(Address) then ;
  {$ENDIF}
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

{ Weak<T> }

class operator Weak<I>.Implicit(const StrongRef: I): Weak<I>;
begin
  Result.FWeakRef := StrongRef;
end;

function Weak<I>.Upgrade;
begin
  StrongRef := FWeakRef;
  Result := Assigned(StrongRef);
end;

{ TCustomAutoReleasable }

procedure TCustomAutoReleasable.AfterConstruction;
begin
  FAutoRelease := True;
  inherited;
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

function TCustomAutoReleasable.GetReferenceCount;
begin
  Result := FRefCount;
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

function TCustomAutoHandle.GetHandle;
begin
  Result := FHandle;
end;

{ TCustomAutoPointer }

constructor TCustomAutoPointer.Capture;
begin
  inherited Create;
  FData := Address;
end;

function TCustomAutoPointer.GetData;
begin
  Result := FData;
end;

{ TCustomAutoMemory }

constructor TCustomAutoMemory.Capture;
begin
  inherited Capture(Address);
  FSize := Size;

  {$IFOPT Q+}
  // Emit overflow checking
  if UIntPtr(Address) + Size < UIntPtr(Address) then ;
  {$ENDIF}
end;

function TCustomAutoMemory.GetRegion;
begin
  Result.Address := FData;
  Result.Size := FSize;
end;

function TCustomAutoMemory.GetSize;
begin
  Result := FSize;
end;

function TCustomAutoMemory.Offset;
begin
  Result := PByte(FData) + Bytes;
end;

{ TAutoObject }

constructor TAutoObject.Capture;
begin
  inherited Create;
  FObject := &Object;
end;

function TAutoObject.GetSelf;
begin
  Result := FObject;
end;

procedure TAutoObject.Release;
begin
  if Assigned(FObject) then
    FObject.Free;

  FObject := nil;
  inherited;
end;

{ TAutoMemory }

constructor TAutoMemory.Allocate;
begin
  inherited Capture(AllocMem(Size), Size)
end;

constructor TAutoMemory.Copy;
begin
  Allocate(Size);
  Move(Source^, FData^, Size);
end;

procedure TAutoMemory.Release;
begin
  if Assigned(FData) then
    FreeMem(FData);

  FData := nil;
  inherited;
end;

{ TAutoManagedType<T> }

constructor TAutoManagedType<T>.Copy;
begin
  Create;
  T(FData^) := Value;
end;

constructor TAutoManagedType<T>.Create;
begin
  inherited Allocate(SizeOf(T));
  Initialize(T(FData^));
end;

procedure TAutoManagedType<T>.Release;
begin
  if Assigned(FData) then
    Finalize(T(FData^));

  inherited;
end;

{ TDelayedOperation}

constructor TDelayedOperation.Create;
begin
  inherited Create;
  FOperation := Operation;
end;

procedure TDelayedOperation.Release;
begin
  if Assigned(FOperation) then
    FOperation;

  FOperation := nil;
  inherited
end;

{ Auto }

class function Auto.Allocate<T>;
begin
  Result := TAutoManagedType<T>.Create;
end;

class function Auto.AllocateDynamic;
begin
  Result := TAutoMemory.Allocate(Size);
end;

class function Auto.Copy<T>;
begin
  Result := TAutoManagedType<T>.Copy(Buffer);
end;

class function Auto.CopyDynamic;
begin
  Result := TAutoMemory.Copy(Buffer, Size);
end;

class function Auto.Delay;
begin
  Result := TDelayedOperation.Create(Operation);
end;

class function Auto.From<T>;
begin
  IAutoObject(Result) := TAutoObject.Capture(&Object);
end;

class function Auto.RefOrNil<P>;
begin
  if Assigned(Memory) then
    Result := Memory.Data
  else
    Result := Default(P); // nil
end;

end.
