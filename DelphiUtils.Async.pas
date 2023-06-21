unit DelphiUtils.Async;

{
  This module provides infrastructure for using anonymous functions as APC
  callbacks in asynchoronous operations.
}

interface

uses
  Ntapi.ntioapi, DelphiApi.Reflection, DelphiUtils.AutoObjects;

type
  // A prototype for an anonymous APC callback
  TAnonymousApcCallback = reference to procedure (
    const IoStatusBlock: TIoStatusBlock
  );

  { Interfaces }

  IAnonymousApcContext = interface (IAutoReleasable)
    function GetCallback: TAnonymousApcCallback;
    property Callback: TAnonymousApcCallback read GetCallback;
  end;

  // An APC context with a dedicated I/O Status Block
  IAnonymousIoApcContext = interface (IAnonymousApcContext)
    function IoStatusBlock: PIoStatusBlock;
  end;

  { Default Implementations }

  TAnonymousApcContext = class (TCustomAutoReleasable, IAnonymousApcContext)
  protected
    Payload: TAnonymousApcCallback;
    procedure Release; override;
  public
    function GetCallback: TAnonymousApcCallback;
    constructor Create(ApcCallback: TAnonymousApcCallback);
  end;

  TAnonymousIoApcContext = class (TAnonymousApcContext, IAnonymousIoApcContext)
  protected
    Iob: TIoStatusBlock;
  public
    function IoStatusBlock: PIoStatusBlock;
  end;

// Get an APC routine for an anonymous APC callback
function GetApcRoutine(
  [opt] AsyncCallback: TAnonymousApcCallback
): TIoApcRoutine;

// Prepare an APC context with an I/O status block for asyncronous operations
// or reference the I/O status block from the stack for synchronous calls
function PrepareApcIsb(
  out ApcContext: IAnonymousIoApcContext;
  [opt] AsyncCallback: TAnonymousApcCallback;
  const [ref] IoStatusBlock: TIoStatusBlock
): PIoStatusBlock;

// Prepare an APC context with an I/O status block for asyncronous operations
// or allocate one from the heap
function PrepareApcIsbEx(
  out ApcContext: IAnonymousIoApcContext;
  [opt] AsyncCallback: TAnonymousApcCallback;
  out xIoStatusBlock: IMemory<PIoStatusBlock>
): PIoStatusBlock;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TAnonymousApcContext }

constructor TAnonymousApcContext.Create;
var
  CallbackIntf: IInterface absolute ApcCallback;
begin
  inherited Create;
  Payload := ApcCallback;
  CallbackIntf._AddRef;
end;

function TAnonymousApcContext.GetCallback;
begin
  Result := Payload;
end;

procedure TAnonymousApcContext.Release;
var
  Callback: TAnonymousApcCallback;
  CallbackIntf: IInterface absolute Callback;
begin
  Callback := Payload;
  CallbackIntf._Release;
  inherited;
end;

{ TAnonymousIoApcContext }

function TAnonymousIoApcContext.IoStatusBlock;
begin
  Result := @Iob;
end;

{ Functions }

// An APC-compatibe wrapper for calling anonymous functions
procedure ApcCallbackForwarder(
  [in] ApcContext: Pointer;
  const IoStatusBlock: TIoStatusBlock;
  [Reserved] Reserved: Cardinal
); stdcall;
var
  ContextData: IAnonymousApcContext absolute ApcContext;
begin
  if Assigned(ContextData) then
    try
      ContextData.Callback(IoStatusBlock);
    finally
      // Clean-up the captured variables of a one-time callbacks
      if ContextData.AutoRelease then
        ContextData._Release;
    end;
end;

function GetApcRoutine;
begin
  // All anonymous functions go through a forwarder that manages their lifetime
  if Assigned(AsyncCallback) then
    Result := ApcCallbackForwarder
  else
    Result := nil;
end;

function PrepareApcIsb;
begin
  if Assigned(AsyncCallback) then
  begin
    // Allocate the contex and use its I/O status block
    ApcContext := TAnonymousIoApcContext.Create(AsyncCallback);
    Result := ApcContext.IoStatusBlock;
  end
  else
  begin
    // Use the I/O status block from the stack
    ApcContext := nil;
    Result := @IoStatusBlock;
  end;
end;

function PrepareApcIsbEx;
begin
  if Assigned(AsyncCallback) then
  begin
    // Allocate the contex and use its I/O status block
    ApcContext := TAnonymousIoApcContext.Create(AsyncCallback);
    Result := ApcContext.IoStatusBlock;
  end
  else
  begin
    // Allocate just the I/O status block
    ApcContext := nil;
    IMemory(xIoStatusBlock) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));
    Result := xIoStatusBlock.Data;
  end;
end;

end.
