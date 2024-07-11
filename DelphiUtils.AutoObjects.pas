unit DelphiUtils.AutoObjects;

{
  This module provides the core facilities for automatic lifetime management
  for resources that require cleanup. When interacting with such resources
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
    ['{46841558-AE45-4161-AF45-ED93AACC2868}']
    function GetAutoRelease: Boolean;
    procedure SetAutoRelease(Value: Boolean);
    function GetReferenceCount: Integer;

    property AutoRelease: Boolean read GetAutoRelease write SetAutoRelease;
    property ReferenceCount: Integer read GetReferenceCount;
  end;

  // An automatically releaseable resource defined by a THandle value.
  IHandle = interface (IAutoReleasable)
    ['{DFCAFCC6-4921-4CDF-A72A-C0211C45D1BF}']
    function GetHandle: THandle;
    property Handle: THandle read GetHandle;
  end;

  // An wrapper that automatically releases a Delphi class.
  // You can safely cast between IAutoObject<TClassA> and IAutoObject<TClassB>
  // whenever TClassA and TClassB form a compatible hierarchy.
  IAutoObject<T: class> = interface (IAutoReleasable)
    ['{D9B743C7-A7E4-4EF4-9056-851FC66F14C6}']
    function GetSelf: T;
    property Self: T read GetSelf;
  end;

  // An untyped wrapper automatically releasing Delphi classes.
  IAutoObject = IAutoObject<TObject>;

  // A wrapper that automatically releases a record pointer. You can safely
  // cast between IAutoPointer<P1> and IAutoPointer<P2> when necessary.
  IAutoPointer<P> = interface (IAutoReleasable) // P must be a Pointer type
    ['{70B707BE-5B84-4EC7-856F-DF7F70DF81F6}']
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

  // A wrapper that automatically releases a memory region.
  // You can safely cast between IMemory<P1> and IMemory<P2> when necessary.
  IMemory<P> = interface(IAutoPointer<P>) // P must be a Pointer type
    ['{7AE23663-B557-4398-A003-405CD4846BE8}']
    property Data: P read GetData;
    function GetSize: NativeUInt;
    property Size: NativeUInt read GetSize;
    function GetRegion: TMemory;
    property Region: TMemory read GetRegion;
    function Offset(Bytes: NativeUInt): Pointer;
  end;

  // An untyped automatic memory region
  IMemory = IMemory<Pointer>;

  // A record type for storing a weak reference to an interface
  Weak<I: IInterface> = record
  private
    [Weak] FWeakRef: I;
  public
    class operator Implicit(const StrongRef: I): Weak<I>;
    function Upgrade(out StrongRef: I): Boolean;
  end;

  // An interface type for storing a weak reference to an interface
  IWeak<I: IInterface> = interface (IAutoReleasable)
    ['{BD834CC2-C269-4D4B-8D07-8D4A9E7754F0}']
    procedure Assign(const StrongRef: I);
    function Upgrade(out StrongRef: I): Boolean;
  end;

  // A prototype for a delayed operation
  TOperation = reference to procedure;

  // A prototype for anonymous for-in iterators
  TEnumeratorPrepare = reference to function: Boolean;
  TEnumeratorProvider<T> = reference to function (out Next: T): Boolean;

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

    // Create a non-owning reference to a memory region
    class function Address<T>(const [ref] Buffer: T): IMemory; static;
    class function AddressRange(Start: Pointer; Size: NativeUInt): IMemory; static;

    // Helper functions for getting the underlying memory address or nil
    class function RefOrNil(const Memory: IAutoPointer): Pointer; overload; static;
    class function RefOrNil<P>(const Memory: IAutoPointer<P>): P; overload; static;
    class function SizeOrZero(const Memory: IMemory): NativeUInt; static;

    // Create a non-owning reference to a handle
    class function RefHandle(Handle: THandle): IHandle; static;

    // Create a non-owning weak reference to an interface
    class function RefWeak<I: IInterface>(const StrongRef: I): IWeak<I>;

    // Perform an operation defined by the callback when the last reference to
    // the object goes out of scope.
    class function Delay(Operation: TOperation): IAutoReleasable; static;

    // Use an anonymous function as a for-in iterator
    class function Iterate<T>(Provider: TEnumeratorProvider<T>): IEnumerable<T>; static;
    class function IterateEx<T>(Prepare: TEnumeratorPrepare; Provider: TEnumeratorProvider<T>): IEnumerable<T>; static;
  end;

  { Base classes (for custom implementations) }

  TCustomAutoReleasable = class abstract (TInterfacedObject)
  protected
    FAutoRelease: Boolean;
    procedure Release; virtual; abstract;
    function GetAutoRelease: Boolean; virtual;
    procedure SetAutoRelease(Value: Boolean); virtual;
    function GetReferenceCount: Integer; virtual;
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;
  end;

  TCustomAutoHandle = class abstract (TCustomAutoReleasable)
  protected
    FHandle: THandle;
    constructor Capture(hObject: THandle);
    function GetHandle: THandle; virtual;
  end;

  TCustomAutoPointer = class abstract (TCustomAutoReleasable)
  protected
    FData: Pointer;
    constructor Capture(Address: Pointer);
    function GetData: Pointer; virtual;
  end;

  TCustomAutoMemory = class abstract (TCustomAutoPointer)
  protected
    FSize: NativeUInt;
    constructor Capture(Address: Pointer; Size: NativeUInt);
    function GetSize: NativeUInt; virtual;
    function GetRegion: TMemory; virtual;
    function Offset(Bytes: NativeUInt): Pointer; virtual;
  end;

  { Default implementations }

  // Encapsulate a weak reference to an interface
  TWeakReference<I: IInterface> = class (TCustomAutoReleasable, IWeak<I>)
  protected
    [Weak] FWeakRef: I;
    procedure Assign(const StrongRef: I); virtual;
    function Upgrade(out StrongRef: I): Boolean; virtual;
    procedure Release; override;
    constructor Create(const StrongRef: I);
  end;

  // Reference a handle value without taking ownership
  THandleReference = class (TCustomAutoHandle, IHandle)
  protected
    procedure Release; override;
  end;

  // Maintains ownership over an instance of a Delphi class derived from TObject
  TAutoObject = class (TCustomAutoReleasable, IAutoObject, IAutoReleasable)
  protected
    FObject: TObject;
    procedure Release; override;
    constructor Capture(&Object: TObject);
    function GetSelf: TObject; virtual;
  end;

  // References a memory region without taking ownership
  TMemoryReference = class (TCustomAutoMemory, IMemory, IAutoPointer,
    IAutoReleasable)
  protected
    procedure Release; override;
  end;

  // Maintains ownership over a pointer to memory managed via AllocMem/FreeMem.
  TAutoMemory = class (TCustomAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
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
  TAutoManagedType<T> = class (TAutoMemory, IMemory, IAutoPointer, IAutoReleasable)
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

  // A wrapper for using anonymous functions as for-in loop providers
  TAnonymousEnumerator<T> = class (TInterfacedObject, IEnumerator<T>,
    IEnumerable<T>)
  protected
    FCurrent: T;
    FIsPrepared: Boolean;
    FPrepare: TEnumeratorPrepare;
    FProvider: TEnumeratorProvider<T>;
  private
    function GetCurrent: TObject; // legacy (untyped)
    function GetEnumerator: IEnumerator; // legacy (untyped)
  public
    constructor Create(
      const Prepare: TEnumeratorPrepare;
      const Provider: TEnumeratorProvider<T>
    );
    procedure Reset;
    function MoveNext: Boolean;
    function GetCurrentT: T;
    function GetEnumeratorT: IEnumerator<T>;
    function IEnumerator<T>.GetCurrent = GetCurrentT;
    function IEnumerable<T>.GetEnumerator = GetEnumeratorT;
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

{ TWeakReference<I> }

procedure TWeakReference<I>.Assign;
begin
  FWeakRef := StrongRef;
end;

constructor TWeakReference<I>.Create;
begin
  inherited Create;
  FWeakRef := StrongRef;
end;

procedure TWeakReference<I>.Release;
begin
  ; // Nothing as we ony store a weak reference
end;

function TWeakReference<I>.Upgrade;
begin
  StrongRef := FWeakRef;
  Result := Assigned(StrongRef);
end;

{ THandleReference }

procedure THandleReference.Release;
begin
  ; // Nothing as we don't own the handle
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

{ TMemoryReference }

procedure TMemoryReference.Release;
begin
  ; // Nothing as we don't own the memory region
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
  inherited;
end;

{ TAnonymousEnumerator<T> }

constructor TAnonymousEnumerator<T>.Create;
begin
  FPrepare := Prepare;
  FProvider := Provider;
end;

function TAnonymousEnumerator<T>.GetCurrent;
begin
  Assert(False, 'Legacy (untyped) IEnumerator.GetCurrent not supported');
  Result := nil;
end;

function TAnonymousEnumerator<T>.GetCurrentT;
begin
  Result := FCurrent;
end;

function TAnonymousEnumerator<T>.GetEnumerator;
begin
  Assert(False, 'Legacy (untyped) IEnumerable.GetEnumerator not supported');
  Result := nil;
end;

function TAnonymousEnumerator<T>.GetEnumeratorT;
begin
  Result := Self;
end;

function TAnonymousEnumerator<T>.MoveNext;
begin
  // Run one-time preparation
  if Assigned(FPrepare) and not FIsPrepared then
  begin
    Result := FPrepare;

    if not Result then
      Exit;

    FIsPrepared := True;
  end;

  Result := FProvider(FCurrent);
end;

procedure TAnonymousEnumerator<T>.Reset;
begin
  ; // not supported
end;

{ Auto }

class function Auto.Address<T>;
begin
  Result := TMemoryReference.Capture(@Buffer, SizeOf(Buffer));
end;

class function Auto.AddressRange;
begin
  Result := TMemoryReference.Capture(Start, Size);
end;

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

class function Auto.Iterate<T>;
begin
  Result := TAnonymousEnumerator<T>.Create(nil, Provider);
end;

class function Auto.IterateEx<T>;
begin
  Result := TAnonymousEnumerator<T>.Create(Prepare, Provider);
end;

class function Auto.RefHandle;
begin
  Result := THandleReference.Capture(Handle);
end;

class function Auto.RefOrNil(const Memory: IAutoPointer): Pointer;
begin
  if Assigned(Memory) then
    Result := Memory.Data
  else
    Result := nil;
end;

class function Auto.RefOrNil<P>(const Memory: IAutoPointer<P>): P;
begin
  if Assigned(Memory) then
    Result := Memory.Data
  else
    Result := Default(P); // nil
end;

class function Auto.RefWeak<I>;
begin
  Result := TWeakReference<I>.Create(StrongRef);
end;

class function Auto.SizeOrZero;
begin
  if Assigned(Memory) then
    Result := Memory.Size
  else
    Result := 0;
end;

end.
