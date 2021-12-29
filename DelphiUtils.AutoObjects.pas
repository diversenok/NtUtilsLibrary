unit DelphiUtils.AutoObjects;

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
    function GetReferenceCount: Integer;
    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
    property ReferenceCount: Integer read GetReferenceCount;
  end;

  // An automatically releaseable resource defined by a THandle value
  IHandle = interface(IAutoReleasable)
    function GetHandle: THandle;
    property Handle: THandle read GetHandle;
  end;

  // An automatically releaseable wrapper for any object in memory.
  // Typically, T should be a pointer type or a class type, but technically,
  // it can be anything.
  IAutoObject<T> = interface (IAutoReleasable)
    function GetData: T;
    property Data: T read GetData;

    // Inheriting a generic interface from a non-generic one confuses Delphi's
    // autocompletion. Reintroduce inherited entries here to fix it.
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean);
    function GetReferenceCount: Integer;
    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
    property ReferenceCount: Integer read GetReferenceCount;
  end;

  // An untyped automatic wrapper for Delphi classes.
  // You can safely cast between IAutoObject<TClassA> and IAutoObject<TClassB>
  // whenever TClassA and TClassB form a compatible hierarchy.
  IAutoObject = IAutoObject<TObject>;

  TMemory = record
    Address: Pointer;
    Size: NativeUInt;
    function Offset(Bytes: NativeUInt): Pointer;
    class function From(Address: Pointer; Size: NativeUInt): TMemory; static;
    class function Reference<T>(const [ref] Buffer: T): TMemory; static;
  end;

  // An automatically releaseable memory region accessed via a typed pointer.
  // You can safely cast between IMemory<P1> and IMemory<P2> when necessary.
  IMemory<P> = interface(IAutoObject<P>) // P must be a Pointer type
    property Data: P read GetData;
    function GetSize: NativeUInt;
    function GetRegion: TMemory;
    property Size: NativeUInt read GetSize;
    property Region: TMemory read GetRegion;
    function Offset(Bytes: NativeUInt): Pointer;

    // Inheriting a generic interface from a non-generic one confuses Delphi's
    // autocompletion. Reintroduce inherited entries here to fix it.
    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
    property ReferenceCount: Integer read GetReferenceCount;
  end;

  // An untyped automatic memory
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
    class function RefOrNil<P>(const Memory: IAutoObject<P>): P; static;

    // Perform an operation defined by the callback when the last reference to
    // the object goes out of scope.
    class function Delay(const Operation: TOperation): IAutoReleasable; static;
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

  TCustomAutoMemory = class abstract (TCustomAutoReleasable)
  protected
    FData: Pointer;
    FSize: NativeUInt;
  public
    constructor Capture(Address: Pointer; Size: NativeUInt);
    function GetData: Pointer;
    function GetSize: NativeUInt;
    function GetRegion: TMemory;
    function Offset(Bytes: NativeUInt): Pointer;
  end;

  { Default implementations }

  // A wrapper that maintains ownership over an instance of a Delphi class
  // derived from TObject.
  TAutoObject = class (TCustomAutoReleasable, IAutoObject)
  protected
    FData: TObject;
    procedure Release; override;
    constructor Capture(Data: TObject);
  public
    function GetData: TObject;
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
  // (both directly and as part of managed records). Those include interfaces,
  // strings, dynamic arrays, and anonymous functions. This wrapper is similar
  // to TAutoMemory, but adds type-specific calls to Initialize/Finalize.
  TAutoManagedType<T> = class sealed (TAutoMemory, IMemory)
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
    constructor Create(const Operation: TOperation);
  end;

// A function for swapping ownership of two memory regions; use carefully
procedure SwapAutoMemory(const A, B: TAutoMemory);

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

function TCustomAutoReleasable.GetReferenceCount: Integer;
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

function TCustomAutoHandle.GetHandle: THandle;
begin
  Result := FHandle;
end;

{ TCustomAutoMemory }

constructor TCustomAutoMemory.Capture;
begin
  inherited Create;
  FData := Address;
  FSize := Size;
end;

function TCustomAutoMemory.GetData: Pointer;
begin
  Result := FData;
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
  FData := Data;
end;

function TAutoObject.GetData;
begin
  Result := FData;
end;

procedure TAutoObject.Release;
begin
  FData.Free;
  FData := nil;
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
  FreeMem(FData);
  FData := nil;
  inherited;
end;

procedure SwapAutoMemory;
begin
  A.FData := AtomicExchange(B.FData, A.FData);
  A.FSize := AtomicExchange(B.FSize, A.FSize);
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

class function Auto.Delay(const Operation: TOperation): IAutoReleasable;
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
