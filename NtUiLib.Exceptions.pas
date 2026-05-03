unit NtUiLib.Exceptions;

{
  This module adds support for raising unsuccessful error codes as Delphi
  exceptions.
}

interface

uses
  NtUtils, System.SysUtils;

type
  // An exception type thrown by RaiseOnError method of TNtxStatus
  ENtError = class (EOSError)
  private
    FStatus: TNtxStatus;
  public
    constructor Create(const Status: TNtxStatus);
    property NtxStatus: TNtxStatus read FStatus;
  end;

// Make a TNtxStatus containing exception information
function CaptureExceptionToNtxStatus(E: Exception): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUiLib.Errors, NtUtils.Ldr, NtUtils.DbgHelp,
  DelphiUtils.AutoEvents;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ ENtError }

constructor ENtError.Create;
begin
  FStatus := Status;
  ErrorCode := Cardinal(Status.Win32Error);
  Message := Status.ToString;
end;

// A callback for raising NT exceptions via Status.RaiseOnError;
procedure NtxUiLibExceptionRaiser(const Status: TNtxStatus);
begin
  raise ENtError.Create(Status);
end;

{ Capturing }

function CaptureExceptionToNtxStatus;
begin
  if E is ENtError then
    Result := ENtError(E).NtxStatus
  else
  begin
    Result.Location := E.ClassName;
    Result.LastCall.Parameter := E.Message;

    if E is EOSError then
      Result.Win32Error := EOSError(E).ErrorCode
    else if E is EAccessViolation then
      Result.Status := STATUS_ACCESS_VIOLATION
    else if E is EOutOfMemory then
      Result.Status := STATUS_NO_MEMORY
    else if (E is EArgumentException) or (E is EArgumentOutOfRangeException) or
      (E is EArgumentNilException) then
      Result.Status := STATUS_INVALID_PARAMETER
    else if E is ENotSupportedException then
      Result.Status := STATUS_NOT_SUPPORTED
    else if E is ENotImplemented then
      Result.Status := STATUS_NOT_IMPLEMENTED
    else if (E is EAbort) or (E is EOperationCancelled) then
      Result.Status := STATUS_CANCELLED
    else if (E is EDirectoryNotFoundException) or (E is EFileNotFoundException)
      or (E is EPathNotFoundException) then
      Result.Status := STATUS_NOT_FOUND
    else if E is EPathTooLongException then
      Result.Status := STATUS_NAME_TOO_LONG
    else if (E is EDivByZero) or (E is EZeroDivide) then
      Result.Status := STATUS_FLOAT_DIVIDE_BY_ZERO
    else if E is ERangeError then
      Result.Status := STATUS_ARRAY_BOUNDS_EXCEEDED
    else if E is EIntOverflow then
      Result.Status := STATUS_INTEGER_OVERFLOW
    else
      Result.Status := STATUS_UNHANDLED_EXCEPTION;
  end;
end;

{ Stack Trace Support }

type
  IExceptionStackTrace = interface
    ['{69815025-B616-43AF-BB25-AC29146B1BD5}']
    function Format: String;
  end;

  TExceptionStackTrace = class (TInterfacedObject, IExceptionStackTrace)
  private
    FTrace: TArray<Pointer>;
  public
    function Format: String;
    constructor Create(ExceptionAddress: Pointer);
  end;

constructor TExceptionStackTrace.Create;
var
  i: Integer;
begin
  inherited Create;

  // Capture the backtrace
  FTrace := RtlxCaptureStackTrace;

  // Trim it by removing frames related to exception handling
  for i := 0 to High(FTrace) do
    if FTrace[i] = ExceptionAddress then
    begin
      Delete(FTrace, 0, i);
      Break;
    end;
end;

function TExceptionStackTrace.Format;
begin
  Result := SymxFormatStackTrace(FTrace);
end;

// A callback for capturing the stack trace when an exception occurs
function GetExceptionStackInfoProc(P: PExceptionRecord): Pointer;
var
  StackTrace: IExceptionStackTrace;
begin
  // Delphi has a bug (RSS-5367) where CleanUpStackInfoProc is not being called
  // on the original exception's StackInfo after re-raising it. Because of that,
  // we cannot return the stack trace as a pointer. Instead, we register it in
  // the interface table and return a cookie. The cookie still needs freeing,
  // but can be safely shared with the re-raised exception without causing
  // double-free problems once the bug gets fixed. Upon the re-raised
  // exception's destruction, it will revoke the cookie and free the stack
  // trace. Subsequent cookie revokations will do no harm. Additionally,
  // using the original stack trace for re-raised exception is better for
  // debugging anyway.

  if TObject(P.ExceptObject) is Exception then
  begin
    // Forward the original stack trace on re-raise
    Result := Exception(p.ExceptObject).StackInfo;

    if Assigned(Result) then
      Exit;
  end;

  // Capture a stack trace, register it, and return a cookie
  StackTrace := TExceptionStackTrace.Create(P.ExceptionAddress);
  Result := Pointer(TInterfaceTable.Add(StackTrace));
end;

// A callback for representing the stack trace
function GetStackInfoStringProc(Info: Pointer): string;
var
  StackTrace: IExceptionStackTrace;
begin
  if TInterfaceTable.Find(NativeUInt(Info), StackTrace) then
    Result := StackTrace.Format
  else
    Result := '';
end;

procedure CleanUpStackInfoProc(Info: Pointer);
begin
  TInterfaceTable.Remove(NativeUInt(Info));
end;

initialization
  TNtxStatus.NtxExceptionRaiser := NtxUiLibExceptionRaiser;

  // Add support for exception stack-tracing
  if not Assigned(@Exception.GetExceptionStackInfoProc) then
  begin
    Exception.GetExceptionStackInfoProc := GetExceptionStackInfoProc;
    Exception.GetStackInfoStringProc := GetStackInfoStringProc;
    Exception.CleanUpStackInfoProc := CleanUpStackInfoProc;
  end;
end.
