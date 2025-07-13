unit NtUtils.Files.Async;

{
  This module provides infrastructure for using anonymous functions as APC
  callbacks in asynchronous I/O operations.
}

interface

uses
  Ntapi.ntioapi, Ntapi.ntpsapi, DelphiApi.Reflection, DelphiUtils.AutoObjects,
  NtUtils;

type
  // A prototype for an I/O APC callback
  TNtxIoApcCallback = reference to procedure (
    const IoStatusBlock: TIoStatusBlock
  );

  // An I/O APC registration object
  INtxIoApc = interface
    ['{1C8DAF59-7902-4E4F-B232-53ECED64C4B9}']
    function GetCookie: NativeUInt;
    function GetIoStatusBlock: PIoStatusBlock;
    procedure Invoke;
    procedure Revoke;
    property Cookie: NativeUInt read GetCookie;
    property IoStatusBlock: PIoStatusBlock read GetIoStatusBlock;
  end;

  TNtxIoContext = record
  private
    FEvent: IHandle;
    FApcObject: INtxIoApc;
    FSynchronousIsb: IMemory<PIoStatusBlock>;
    function GetApcRoutine: TIoApcRoutine;
    function GetApcContext: Pointer;
    function GetIoStatusBlock: PIoStatusBlock;
    function GetEventHandle: THandle;
  public
    property ApcRoutine: TIoApcRoutine read GetApcRoutine;
    property ApcContext: Pointer read GetApcContext;
    property IoStatusBlock: PIoStatusBlock read GetIoStatusBlock;
    property EventHandle: THandle read GetEventHandle;

    // Prepare parameters for potentially asynchronous I/O
    class function Prepare(
      out Context: TNtxIoContext;
      [opt] AsyncCallback: TNtxIoApcCallback
      ): TNtxStatus; static;

    // Synchronize on operation completion, if necessary
    procedure Await(var Result: TNtxStatus);
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

uses
  Ntapi.ntstatus, DelphiUtils.AutoEvents, NtUtils.Synchronization;

{ Dispatchers }

procedure NtUtilsIoApcForwarder(
  [in] ApcContext: Pointer;
  const IoStatusBlock: TIoStatusBlock;
  [Reserved] Reserved: Cardinal
); stdcall;
var
  Cookie: NativeUInt absolute ApcContext;
  AnonymousContext: INtxIoApc;
begin
  // Locate (and remove) a callback-owning interface in the interface table
  // using the context as a cookie
  if TInterfaceTable.Find(Cookie, INtxIoApc, AnonymousContext, True) then
    AnonymousContext.Invoke;
end;

{ Interface implementations }

type
  TAnonymousIoApc = class (TAutoInterfacedObject, INtxIoApc)
  protected
    FInterfaceTableCookie: NativeUInt;
    FCallback: TNtxIoApcCallback;
    FIsb: TIoStatusBlock;
  public
    function GetCookie: NativeUInt;
    function GetIoStatusBlock: PIoStatusBlock;
    procedure Invoke;
    procedure Revoke;
    constructor Create(const Callback: TNtxIoApcCallback);
  end;

constructor TAnonymousIoApc.Create;
begin
  inherited Create;
  FCallback := Callback;
  FInterfaceTableCookie := TInterfaceTable.Add(Self);
end;

function TAnonymousIoApc.GetCookie;
begin
  Result := FInterfaceTableCookie;
end;

function TAnonymousIoApc.GetIoStatusBlock;
begin
  Result := @FIsb;
end;

procedure TAnonymousIoApc.Invoke;
begin
  if Assigned(FCallback) then
  try
    FCallback(FIsb);
  except
    on E: TObject do
      if not Assigned(AutoExceptionHanlder) or not AutoExceptionHanlder(E) then
        raise;
  end;
end;

procedure TAnonymousIoApc.Revoke;
begin
  TInterfaceTable.Remove(FInterfaceTableCookie);
end;

{ TNtxIoContext }

procedure TNtxIoContext.Await;
begin
  if Assigned(FApcObject) then
  case Result.Status of
    STATUS_PENDING:
      ; // The system promised an APC; no need to do anything until then
    NT_FAILURE_MIN..NT_FAILURE_MAX:
      // The operation failed; unregister the callback
      FApcObject.Revoke;
  else
    // The operation completed synchronously; we can invoke the callback without
    // waiting for an APC (which might not even come under some fast I/O cases)
    FApcObject.Invoke;
    FApcObject.Revoke;
  end
  else if Result.Status = STATUS_PENDING then
  begin
    // We wanted synchronous I/O but got asynchronous, so need to wait
    Result := NtxWaitForSingleObject(FEvent);

    // On success, extract the status. On failure, the only option we
    // have is to prolong the lifetime of the I/O status block indefinitely
    // because we never know when the system will write to its memory.
    if Result.IsSuccess then
      Result.Status := FSynchronousIsb.Data.Status
    else
      FSynchronousIsb.DiscardOwnership;
  end;
end;

function TNtxIoContext.GetApcContext;
begin
  // The forwarder recognizes a revokable cookie as a key for our APC object
  if Assigned(FApcObject) then
    Result := Pointer(FApcObject.Cookie)
  else
    Result := nil;
end;

function TNtxIoContext.GetApcRoutine;
begin
  // Use a TIoApcRoutine-compatible routine which will look up and invoke our
  // APC object's callback
  if Assigned(FApcObject) then
    Result := NtUtilsIoApcForwarder
  else
    Result := nil;
end;

function TNtxIoContext.GetEventHandle;
begin
  Result := HandleOrDefault(FEvent);
end;

function TNtxIoContext.GetIoStatusBlock;
begin
  if Assigned(FApcObject) then
  begin
    // The APC object owns its I/O status block
    Result := FApcObject.IoStatusBlock;
    Exit;
  end;

  // Delay-initialize a local I/O status block for synchronous I/O
  if not Assigned(FSynchronousIsb) then
    IMemory(FSynchronousIsb) := Auto.AllocateDynamic(SizeOf(TIoStatusBlock));

  Result := FSynchronousIsb.Data;
end;

class function TNtxIoContext.Prepare;
begin
  if Assigned(AsyncCallback) then
  begin
    // We cannot use file handles for waiting since they might not grant
    // SYNCHRONIZE access.
    Result := RtlxAcquireReusableEvent(Context.FEvent);

    if not Result.IsSuccess then
      Exit;

    // Create and register an APC object with its own I/O status block
    Context.FApcObject := TAnonymousIoApc.Create(AsyncCallback);
  end
  else
  begin
    Result := NtxSuccess;
    Context := Default(TNtxIoContext);
  end;
end;

end.
