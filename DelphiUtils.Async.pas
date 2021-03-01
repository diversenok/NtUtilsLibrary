unit DelphiUtils.Async;

interface

uses
  Ntapi.ntioapi, DelphiUtils.AutoObject;

type
  // A prototype for anonymous APC callback
  TAnonymousApcCallback = reference to procedure (const IoStatusBlock:
    TIoStatusBlock);

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
    Payload: TAnonymousApcCallback;
    function GetCallback: TAnonymousApcCallback;
    constructor Create(ApcCallback: TAnonymousApcCallback);
  end;

  TAnonymousIoApcContext = class (TAnonymousApcContext, IAnonymousIoApcContext)
    Iob: TIoStatusBlock;
    function IoStatusBlock: PIoStatusBlock;
  end;

// An APC-compatibe wrapper for calling an anonymous function
// passed via the context parameter
procedure ApcCallbackForwarder(ApcContext: Pointer; const IoStatusBlock:
  TIoStatusBlock; Reserved: Cardinal); stdcall;

implementation

{ TAnonymousApcContext }

constructor TAnonymousApcContext.Create(ApcCallback: TAnonymousApcCallback);
begin
  inherited Create;
  Payload := ApcCallback;
end;

function TAnonymousApcContext.GetCallback: TAnonymousApcCallback;
begin
  Result := Payload;
end;

{ TAnonymousIoApcContext }

function TAnonymousIoApcContext.IoStatusBlock: PIoStatusBlock;
begin
  Result := @Iob;
end;

{ Functions }

procedure ApcCallbackForwarder(ApcContext: Pointer; const IoStatusBlock:
  TIoStatusBlock; Reserved: Cardinal); stdcall;
var
  ContextData: IAnonymousApcContext absolute ApcContext;
begin
  try
    // Execute the payload
    ContextData.Callback(IoStatusBlock);

  finally
    // Clean-up the captured variables and other resources
    if ContextData.AutoRelease then
      ContextData._Release;
  end;
end;

end.
