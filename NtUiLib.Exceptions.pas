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

implementation

uses
  NtUiLib.Errors, NtUtils.Ldr, NtUtils.DbgHelp;

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
