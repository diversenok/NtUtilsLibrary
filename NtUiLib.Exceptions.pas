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
  ENtError = class(EOSError)
  private
    xStatus: TNtxStatus;
  public
    constructor Create(const Status: TNtxStatus);
    property NtxStatus: TNtxStatus read xStatus;
  end;

// Make a TNtxStatus containing exception information
function CaptureExceptionToNtxStatus(E: Exception): TNtxStatus;

implementation

uses
  Ntapi.ntstatus, NtUiLib.Errors, NtUtils.Ldr, NtUtils.DbgHelp;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ ENtError }

constructor ENtError.Create;
begin
  xStatus := Status;
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

// A callback for capturing the stack trace when an exception occurs
function GetExceptionStackInfoProc(P: PExceptionRecord): Pointer;
var
  Trace: TArray<Pointer> absolute Result;
  i: Integer;
begin
  // Clean-up before assigning
  Result := nil;

  // Capture the backtrace
  Trace := RtlxCaptureStackTrace;

  // Trim it by removing exception-handling frames
  for i := 0 to High(Trace) do
    if Trace[i] = P.ExceptionAddress then
    begin
      Delete(Trace, 0, i);
      Break;
    end;
end;

{$IFDEF Win64}
// A callback for representing the stack trace
function GetStackInfoStringProc(Info: Pointer): string;
var
  Trace: TArray<Pointer> absolute Info;
  Modules: TArray<TModuleEntry>;
  Frames: TArray<String>;
  i: Integer;
begin
  Modules := LdrxEnumerateModules;
  SetLength(Frames, Length(Trace));

  for i := 0 to High(Trace) do
    Frames[i] := SymxFindBestMatch(Modules, Trace[i]).ToString;

  Result := String.Join(#$D#$A, Frames);
end;
{$ELSE}
function GetStackInfoStringProc(Info: Pointer): string;
begin
  // TODO: fix NtUtils's DbgHelp support on WoW64
  // TODO: fallback to export-based symbol enumeration
  Result := '(not supported under WoW64)';
end;
{$ENDIF}

procedure CleanUpStackInfoProc(Info: Pointer);
var
  Trace: TArray<Pointer> absolute Info;
begin
  Finalize(Trace);
end;

initialization
  NtxExceptionRaiser := NtxUiLibExceptionRaiser;

  if not Assigned(@Exception.GetExceptionStackInfoProc) then
  begin
    Exception.GetExceptionStackInfoProc := GetExceptionStackInfoProc;
    Exception.GetStackInfoStringProc := GetStackInfoStringProc;
    Exception.CleanUpStackInfoProc := CleanUpStackInfoProc;
  end;
end.
