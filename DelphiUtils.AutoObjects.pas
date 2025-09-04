unit DelphiUtils.AutoObjects;

{
  This module provides the core facilities for automatic lifetime management
  for resources that require cleanup. When interacting with such resources
  through interfaces, Delphi automatically emits code that counts outstanding
  references (even in face of exceptions) and immediately releases the
  underlying resource when this value drops to zero.

  The module defines the following hierarchy of interfaces:

  IAutoReleasable --> IDiscardableResource
   (IInterface)               |
        |                     |
        |                     +--> IHandle
        |                     |
        |                     +--> IObject<T: Class>
        |                     |
        |                     +--> IPointer<P: Pointer> --> IMemory<P: Pointer>
        |
        |                     +--> IWeak<I: Interface>
        |                     |
        +---------------------+--> IStrong<I: Interface>
                              |
                              +--> IDeferredOperation
}

interface

uses
  Ntapi.ntrtl, DelphiApi.Reflection;

const
  // A special IID for casting IUnknown to TObject // From System.pas
  ObjCastGUID: TGuid = '{CEDF24DE-80A4-447D-8C75-EB871DC121FD}';

var
  // A callback for handing exceptions that occur while executing callbacks or
  // delivering events. The result indicates whether the exception was handled.
  AutoExceptionHanlder: function (E: TObject): Boolean;

type
  // A logical base for types that rely on automatic interface cleanup
  IAutoReleasable = IInterface;

  // Access to various debug information about an interface and its implementor
  IInterfaceDebug = interface
    ['{1CF1A532-FB59-4033-AEE7-484D8006905B}']
    function GetReferenceCount: Integer;
    function GetIsWeakReferenced: Boolean;
    function GetImplementingObject: TObject;

    property ReferenceCount: Integer read GetReferenceCount;
    property IsWeakReferenced: Boolean read GetIsWeakReferenced;
    property ImplementingObject: TObject read GetImplementingObject;
  end;

  // The default behavior for wrappers that own a resource is to release it
  // upon destruction. This interface allows overwritting this behavior.
  IDiscardableResource = interface (IAutoReleasable)
    ['{E00FCE36-2271-4F2B-883A-9CA8B64FE07F}']
    procedure DiscardOwnership;
  end;

  // An interface wrapper for a resource defined by a handle value
  IHandle = interface (IDiscardableResource)
    ['{A6FED903-46C9-4B1F-ADDA-E33FFB0E6FDA}']
    function GetHandle: THandle;
    property Handle: THandle read GetHandle;
  end;

  // An interface wrapper for a Delphi class instance
  IObject<T: class> = interface (IDiscardableResource)
    ['{DC7273C7-16D9-4F10-9452-81F156FE1361}']
    function GetSelf: T;
    property Self: T read GetSelf;
  end;
  IObject = IObject<TObject>;

  // An interface wrapper for a pointer
  IPointer<P {: Pointer}> = interface (IDiscardableResource)
    ['{ACD517CE-6A2C-4CDE-BDE6-A3BBA7A5C92E}']
    function GetData: P;
    property Data: P read GetData;
    function Offset(Bytes: NativeUInt): Pointer;
  end;
  IPointer = IPointer<Pointer>;

  // A helper record for storing information about a memory region
  TMemory = record
    Address: Pointer;
    Size: NativeUInt;
    function Offset(Bytes: NativeUInt): Pointer;
    class function From(Address: Pointer; Size: NativeUInt): TMemory; static;
    class function Reference<T>(const [ref] Buffer: T): TMemory; static;
  end;

  // An interface wrapper for a memory region (pointer + size)
  IMemory<P {: Pointer}> = interface (IPointer<P>)
    ['{CBCAA941-D8E4-46C6-B1C0-042238D13CD7}']
    property Data: P read GetData;
    function GetSize: NativeUInt;
    property Size: NativeUInt read GetSize;
    function GetRegion: TMemory;
    property Region: TMemory read GetRegion;
  end;
  IMemory = IMemory<Pointer>;

  TAutoInterfacedObject = class;

  // An interface wrapper for storing a weak reference to another interface
  // Upgrading is thread-safe for descendants of TAutoInterfacedObject
  [ThreadSafe]
  IWeak<I: IInterface> = interface (IAutoReleasable)
    ['{F13D07F6-3F42-44BF-AEF1-F13189D3ED40}']
    function Upgrade(out StrongRef: I): Boolean;
  end;
  IWeak = IWeak<IInterface>;

  // A record for storing a weak reference to an interface
  // Upgrading is thread-safe for descendants of TAutoInterfacedObject
  [ThreadSafe]
  Weak<I: IInterface> = record
  private
    FReference: IWeak<I>;
  public
    class operator Implicit(const StrongRef: I): Weak<I>;
    function Upgrade(out StrongRef: I): Boolean;
    property WeakReference: IWeak<I> read FReference;
  end;

  // An interface wrapper that holds a strong reference to another interface.
  // It can be useful for packing TInterfacedObject-derived objects (like
  // anonymous functions) into a weak-safe implementation.
  IStrong<I : IInterface> = interface (IAutoReleasable)
    ['{13EE797B-B466-4394-83A1-A2AB93DF879D}']
    function GetReference: I;
    property Reference: I read GetReference;
  end;
  IStrong = IStrong<IInterface>;

  // A prototype for a delayed operation
  TOperation = reference to procedure;

  // An interface that executes a callback upon destruction (unless disabled)
  IDeferredOperation = interface (IAutoReleasable)
    ['{FDEAD0C0-FF7D-4DD7-A6D1-6A22BCD09FFF}']
    procedure Cancel;
  end;

  // A prototype for anonymous for-in iterators
  TEnumeratorPrepare = reference to function: Boolean;
  TEnumeratorProvider<T> = reference to function (out Next: T): Boolean;

  Auto = class abstract
    // Capture ownership of a Delphi class object
    class function CaptureObject<T: class>(Instance: T): IObject<T>; static;

    // Create a non-owning reference to a Delphi class object
    class function RefObject<T: class>(Instance: T): IObject<T>; static;

    // Allocate a memory region
    class function AllocateDynamic(Size: NativeUInt): IMemory; static;
    class function CopyDynamic(Source: Pointer; Size: NativeUInt): IMemory; static;

    // Allocate a (boxed) Delphi record
    class function Allocate<T>: IMemory; static;
    class function Copy<T>(const Buffer: T): IMemory; static;

    // Create non-owning memory references
    class function RefAddress(Address: Pointer): IPointer; static;
    class function RefAddressRange(Address: Pointer; Size: NativeUInt): IMemory; static;
    class function RefBuffer<T: record>(const [ref] Buffer: T): IMemory; static;

    // Create a non-owning reference to a handle
    class function RefHandle(HandleValue: THandle): IHandle; static;

    // Capture a weak wrapper for an interface
    class function RefWeak<I: IInterface>(const StrongRef: I): IWeak<I>; static;

    // Create a wrapper for an interface
    class function RefStrong<I: IInterface>(const StrongRef: I): IStrong<I>; static;

    // Helper functions for getting the underlying memory address or nil
    class function DataOrNil(const Memory: IPointer): Pointer; overload; static;
    class function DataOrNil<P>(const Memory: IPointer<P>): P; overload; static;
    class function SizeOrZero(const Memory: IMemory): NativeUInt; static;

    // Invoke the callback when the interface destructs
    class function Defer(Operation: TOperation): IDeferredOperation; static;

    // Use an anonymous function as a for-in iterator
    class function Iterate<T>(Provider: TEnumeratorProvider<T>): IEnumerable<T>; static;
    class function IterateEx<T>(Prepare: TEnumeratorPrepare; Provider: TEnumeratorProvider<T>): IEnumerable<T>; static;
  end;

  { Base classes (for custom implementations) }

  // An analog for TInterfacedObject but with guaranteed thread-safety for
  // Weak<I> and IWeak<I>
  TAutoInterfacedObject = class (TObject, IInterface, IInterfaceDebug)
  private
    const objDestroyingFlag = Integer($80000000);
    class var FDestructorLock: TRtlResource;
    class var FFreeInstanceLock: TRtlResource;
    class constructor Create;
    class destructor Destroy;
    function GetReferenceCount: Integer;
    function GetIsDestroying: Boolean;
    function GetIsWeakReferenced: Boolean;
    function GetImplementingObject: TObject;
  protected
    [Volatile] FRefCount: Integer;
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    class var DebugCreate: procedure (Obj: TAutoInterfacedObject);
    class var DebugDestroy: procedure (Obj: TAutoInterfacedObject);
    class var DebugAddRef: procedure (Obj: TAutoInterfacedObject);
    class var DebugRelease: procedure (Obj: TAutoInterfacedObject);
    class procedure EnterDestructionLock; static;
    class procedure ExitDestructionLock; static;
    class procedure EnterFreeInstanceLock; static;
    class procedure ExitFreeInstanceLock; static;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
    property ReferenceCount: Integer read GetReferenceCount;
    property IsDestroying: Boolean read GetIsDestroying;
    property IsWeakReferenced: Boolean read GetIsWeakReferenced;
  end;

  TDiscardableResource = class abstract (TAutoInterfacedObject,
    IDiscardableResource)
  protected
    FDiscardOwnership: Boolean;
    procedure DiscardOwnership; virtual;
  end;

  // A base class for implementing IObject
  TCustomAutoObject = class (TDiscardableResource, IObject)
  protected
    FObject: TObject;
    function GetSelf: TObject; virtual;
  public
    constructor Capture(Instance: TObject);
    destructor Destroy; override;
  end;

  // A base class for implementing IHandle
  TCustomAutoHandle = class abstract (TDiscardableResource, IHandle)
  protected
    FHandle: THandle;
    function GetHandle: THandle; virtual;
  public
    constructor Capture(HandleValue: THandle);
    destructor Destroy; override;
  end;

  // A base class for implementing IPointer
  TCustomAutoPointer = class abstract (TDiscardableResource, IPointer)
  protected
    FData: Pointer;
    function GetData: Pointer; virtual;
    function Offset(Bytes: NativeUInt): Pointer; virtual;
  public
    constructor Capture(Address: Pointer);
    destructor Destroy; override;
  end;

  // A base class for implementing IMemory
  TCustomAutoMemory = class abstract (TCustomAutoPointer, IMemory)
  protected
    FSize: NativeUInt;
    function GetSize: NativeUInt; virtual;
    function GetRegion: TMemory; virtual;
  public
    constructor Capture(Address: Pointer; Size: NativeUInt);
    destructor Destroy; override;
  end;

  { Default implementations }

  // A wrapper that takes ownership over an instance of a Delphi class
  TAutoObject = class (TCustomAutoObject)
  public
    destructor Destroy; override;
  end;

  // A wrapper that takes ownership over memory managed via AllocMem/FreeMem.
  TAutoMemory = class (TCustomAutoMemory)
  public
    constructor Allocate(Size: NativeUInt);
    constructor Copy(Source: Pointer; Size: NativeUInt);
    destructor Destroy; override;
  end;

  // A wrapper that takes ownership over a type managed via Initialize/Finalize
  TAutoManagedType<T> = class (TAutoMemory)
  public
    constructor Create;
    constructor Copy(const Value: T);
    destructor Destroy; override;
  end;

  // Reference a Delphi class object without taking ownership
  TObjectReference = class (TCustomAutoObject)
  end;

  // Reference a handle without taking ownership
  THandleReference = class (TCustomAutoHandle)
  end;

  // Reference a memory address without taking ownership
  TPointerReference = class (TCustomAutoPointer)
  end;

  // Reference a memory region without taking ownership
  TMemoryReference = class (TCustomAutoMemory)
  end;

  // A wrapper that stores a weak interface reference
  TAutoWeakReference = class (TAutoInterfacedObject, IWeak)
  protected
    [Weak] FWeakObject: TAutoInterfacedObject;
    [Weak] FWeakIntf: IInterface;
    function Upgrade(out StrongRef: IInterface): Boolean; virtual;
  public
    constructor Create(const StrongRef: IInterface);
  end;

  // A wrapper that stores a strong interface reference
  TAutoStrongReference = class (TAutoInterfacedObject, IStrong)
  protected
    FReference: IInterface;
    function GetReference: IInterface; virtual;
  public
    constructor Create(const StrongRef: IInterface);
  end;

  // Automatically performs an operation on destruction.
  TDeferredOperation = class (TAutoInterfacedObject, IDeferredOperation)
  protected
    FCancelled: Boolean;
    FOperation: TOperation;
    procedure Cancel; virtual;
  public
    constructor Create(Operation: TOperation);
    destructor Destroy; override;
  end;

  // A wrapper for using anonymous functions as for-in loop providers
  TAnonymousEnumerator<T> = class (TAutoInterfacedObject, IEnumerator<T>,
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

{ Weak<I> }

class operator Weak<I>.Implicit(const StrongRef: I): Weak<I>;
begin
  if Assigned(StrongRef) then
    IWeak(Result.FReference) := TAutoWeakReference.Create(StrongRef)
  else
    Result.FReference := nil;
end;

function Weak<I>.Upgrade;
begin
  Result := Assigned(FReference) and FReference.Upgrade(StrongRef);
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

class function Auto.CaptureObject<T>;
begin
  IObject(Result) := TAutoObject.Capture(Instance);
end;

class function Auto.Copy<T>;
begin
  Result := TAutoManagedType<T>.Copy(Buffer);
end;

class function Auto.CopyDynamic;
begin
  Result := TAutoMemory.Copy(Source, Size);
end;

class function Auto.DataOrNil(const Memory: IPointer): Pointer;
begin
  if Assigned(Memory) then
    Result := Memory.Data
  else
    Result := nil;
end;

class function Auto.DataOrNil<P>(const Memory: IPointer<P>): P;
begin
  if Assigned(Memory) then
    Result := Memory.Data
  else
    Result := Default(P); // nil
end;

class function Auto.Defer;
begin
  Result := TDeferredOperation.Create(Operation);
end;

class function Auto.Iterate<T>;
begin
  Result := TAnonymousEnumerator<T>.Create(nil, Provider);
end;

class function Auto.IterateEx<T>;
begin
  Result := TAnonymousEnumerator<T>.Create(Prepare, Provider);
end;

class function Auto.RefAddress;
begin
  Result := TPointerReference.Capture(Address);
end;

class function Auto.RefAddressRange;
begin
  Result := TMemoryReference.Capture(Address, Size);
end;

class function Auto.RefBuffer<T>;
begin
  Result := TMemoryReference.Capture(@Buffer, SizeOf(Buffer));
end;

class function Auto.RefHandle;
begin
  Result := THandleReference.Capture(HandleValue);
end;

class function Auto.RefObject<T>;
begin
  IObject(Result) := TObjectReference.Capture(Instance);
end;

class function Auto.RefStrong<I>;
begin
  IStrong(Result) := TAutoStrongReference.Create(StrongRef);
end;

class function Auto.RefWeak<I>;
begin
  IWeak(Result) := TAutoWeakReference.Create(StrongRef);
end;

class function Auto.SizeOrZero;
begin
  if Assigned(Memory) then
    Result := Memory.Size
  else
    Result := 0;
end;

{ TAutoInterfacedObject }

procedure TAutoInterfacedObject.AfterConstruction;
begin
  inherited;

  if Assigned(DebugCreate) then
    DebugCreate(Self);

  // Release the implicit reference from NewInstance
  AtomicDecrement(FRefCount);
end;

procedure TAutoInterfacedObject.BeforeDestruction;
begin
  if Assigned(DebugDestroy) then
    DebugDestroy(Self);

  inherited;
end;

class constructor TAutoInterfacedObject.Create;
begin
  RtlInitializeResource(FDestructorLock);
  RtlInitializeResource(FFreeInstanceLock);
end;

class destructor TAutoInterfacedObject.Destroy;
begin
  RtlDeleteResource(@FDestructorLock);
  RtlDeleteResource(@FFreeInstanceLock);
end;

class procedure TAutoInterfacedObject.EnterDestructionLock;
begin
  // We use an exclusive lock here and a shared lock in Release to avoid
  // serializing reference counting (which is more common than weak reference
  // upgrading/copying).
  RtlAcquireResourceExclusive(@FDestructorLock, True);
end;

class procedure TAutoInterfacedObject.EnterFreeInstanceLock;
begin
  // We use an exclusive lock here and a shared lock in FreeInstance to avoid
  // serializing reference object freeing (which is more common than weak
  // reference upgrading/copying).
  RtlAcquireResourceExclusive(@FFreeInstanceLock, True);
end;

class procedure TAutoInterfacedObject.ExitDestructionLock;
begin
  RtlReleaseResource(@FDestructorLock);
end;

class procedure TAutoInterfacedObject.ExitFreeInstanceLock;
begin
  RtlReleaseResource(@FFreeInstanceLock);
end;

procedure TAutoInterfacedObject.FreeInstance;
begin
  // We want to synchronize with weak reference upgrading but don't want to
  // seralize all object freeing; thus, a shared lock. Note that due to Relase's
  // logic, we alread run under the shared destructor lock here.
  RtlAcquireResourceShared(@FFreeInstanceLock, True);
  try
    // Here the object is destroyed but weak references still exist
    inherited FreeInstance;
    // Here there are no weak references and the object is freed
  finally
    RtlReleaseResource(@FFreeInstanceLock);
  end;
end;

function TAutoInterfacedObject.GetImplementingObject;
begin
  Result := Self;
end;

function TAutoInterfacedObject.GetIsDestroying;
begin
  Result := LongBool(FRefCount and objDestroyingFlag);
end;

function TAutoInterfacedObject.GetIsWeakReferenced;
const
  monWeakReferencedFlag = $1;
begin
  Result := (PNativeUInt(PByte(Self) + InstanceSize - hfFieldSize +
    hfMonitorOffset)^ and monWeakReferencedFlag) <> 0;
end;

function TAutoInterfacedObject.GetReferenceCount;
begin
  Result := FRefCount and not objDestroyingFlag;
end;

class function TAutoInterfacedObject.NewInstance;
begin
  Result := inherited NewInstance;

  // Set an implicit reference so that interface usage in the constructor does
  // not destroy the object. This reference is released in AfterConstruction
  TAutoInterfacedObject(Result).FRefCount := 1;
end;

function TAutoInterfacedObject.QueryInterface;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TAutoInterfacedObject._AddRef;
begin
  Result := AtomicIncrement(FRefCount);

  if Assigned(DebugAddRef) then
    DebugAddRef(Self);
end;

function TAutoInterfacedObject._Release;
begin
  Result := AtomicDecrement(FRefCount);

  if Assigned(DebugRelease) then
    DebugRelease(Self);

  if (Result < 0) and (Result and objDestroyingFlag = 0) then
    Error(reInvalidPtr);

  if Result = 0 then
  begin
    // There might still be weak references that can concurrently become strong.
    // Block reference unpgrading until we are done. We use a shared lock here
    // to avoid serializing all destructors.
    RtlAcquireResourceShared(@FDestructorLock, True);
    try
      // We are now the only thread that can upgrade weak references, ensure
      // nobody has referenced the object before we blocked it
      if FRefCount = 0 then
      begin
        // We can commit to object destruction
        FRefCount := objDestroyingFlag;
        Destroy;
      end;
    finally
      RtlReleaseResource(@FDestructorLock);
    end;
  end;
end;

{ TDiscardableResource }

procedure TDiscardableResource.DiscardOwnership;
begin
  FDiscardOwnership := True;
end;

{ TCustomAutoObject }

constructor TCustomAutoObject.Capture;
begin
  inherited Create;
  FObject := Instance;
end;

destructor TCustomAutoObject.Destroy;
begin
  FObject := nil;
  inherited;
end;

function TCustomAutoObject.GetSelf;
begin
  Result := FObject;
end;

{ TCustomAutoHandle }

constructor TCustomAutoHandle.Capture;
begin
  inherited Create;
  FHandle := HandleValue;
end;

destructor TCustomAutoHandle.Destroy;
begin
  FHandle := 0;
  inherited;
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

destructor TCustomAutoPointer.Destroy;
begin
  FData := nil;
  inherited;
end;

function TCustomAutoPointer.GetData;
begin
  Result := FData;
end;

function TCustomAutoPointer.Offset;
begin
  Result := PByte(FData) + Bytes;
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

destructor TCustomAutoMemory.Destroy;
begin
  FSize := 0;
  inherited;
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

{ TAutoObject }

destructor TAutoObject.Destroy;
begin
  if not FDiscardOwnership then
    FObject.Free;

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

destructor TAutoMemory.Destroy;
begin
  if Assigned(FData) and not FDiscardOwnership then
    FreeMem(FData);

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

destructor TAutoManagedType<T>.Destroy;
begin
  if Assigned(FData) and not FDiscardOwnership then
    Finalize(T(FData^));

  inherited;
end;

{ TAutoWeakReference }

constructor TAutoWeakReference.Create;
var
  Instance: TObject;
begin
  inherited Create;

  // This is a write-only operation; no need to lock
  FWeakIntf := StrongRef;

  // Extract the underlying object instance
  if Assigned(StrongRef) and
    (StrongRef.QueryInterface(ObjCastGUID, Instance) = S_OK) and
    Instance.InheritsFrom(TAutoInterfacedObject) then
    FWeakObject := TAutoInterfacedObject(Instance)
  else
    FWeakObject := nil;
end;

function TAutoWeakReference.Upgrade;
begin
  // Is it already destroyed? Then we can skip locking
  if not Assigned(FWeakIntf) then
    Exit(False);

  // First, enter a less-contended FreeInstance lock and prevent weak
  // TAutoInterfacedObject instance references from disappearing. Note that
  // desturctors might still run but objects cannot be freed.
  TAutoInterfacedObject.EnterFreeInstanceLock;
  try
    if Assigned(FWeakObject) then
    begin
      // If the object is destroying, block upgrades
      if not FWeakObject.IsDestroying then
      begin
        // Use the thread-safe path and prevent destructors from running.
        TAutoInterfacedObject.EnterDestructionLock;
        try
          // Re-check the object for destruction, in case it started between the
          // last checking and locking.
          if not FWeakObject.IsDestroying then
          begin
            // Upgrade to strong
            StrongRef := FWeakIntf;
            Result := Assigned(StrongRef);
          end
          else
            Result := False;
        finally
          // Allows object destruction again
          TAutoInterfacedObject.ExitDestructionLock;
        end;
      end
      else
        Result := False;
    end
    else
    begin
      // The object is not aware of locking; fall back to thread-unsafe upgrade
      StrongRef := FWeakIntf;
      Result := Assigned(StrongRef);
    end;
  finally
    // Allow object deallocation
    TAutoInterfacedObject.ExitFreeInstanceLock;
  end;
end;

{ TAutoStrongReference }

constructor TAutoStrongReference.Create;
begin
  inherited Create;
  FReference := StrongRef;
end;

function TAutoStrongReference.GetReference;
begin
  Result := FReference;
end;

{ TDeferredOperation}

procedure TDeferredOperation.Cancel;
begin
  FCancelled := True;
end;

constructor TDeferredOperation.Create;
begin
  inherited Create;
  FCancelled := False;
  FOperation := Operation;
end;

destructor TDeferredOperation.Destroy;
begin
  if Assigned(FOperation) and not FCancelled then
    try
      FOperation;
    except
      on E: TObject do
        if not Assigned(AutoExceptionHanlder) or not
          AutoExceptionHanlder(E) then
          raise;
    end;

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

end.
