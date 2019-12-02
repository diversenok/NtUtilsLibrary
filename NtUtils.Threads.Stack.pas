unit NtUtils.Threads.Stack;

interface

uses
  NtUtils.Exceptions;

// Get current address (address of the next instruction to be executed)
function RtlxCurrentAddress: Pointer; register;

// Get return address (address of the caller of the current function)
function RtlxCallersAddress: Pointer; inline;

// Get address of the caller's caller
function RtlxCallersCallerAddress: Pointer; inline;

// Capture a stack trace of the current thread
function RtlxCaptureStackTrace(out BackTrace: TArray<Pointer>;
  FramesToCapture: Cardinal = 32; FramesToSkip: Cardinal = 0): Word; inline;

implementation

uses
  Ntapi.ntrtl;

function RtlxCurrentAddress: Pointer; register;
begin
  // Return address whitin a non-inline function is the address of the next
  // instruction after it returns
  Result := ReturnAddress;
end;

function RtlxCallersAddress: Pointer; inline;
begin
  // Inlined return address
  Result := ReturnAddress;
end;

function RtlxCallersCallerAddress: Pointer; inline;
var
  Dummy: Pointer;
begin
  // The first out param is the return address (use RtlxCallersAddress to
  // obtain it), the second out param is the second level return address.
  RtlGetCallersAddress(Dummy, Result);
end;

function RtlxCaptureStackTrace(out BackTrace: TArray<Pointer>;
  FramesToCapture: Cardinal; FramesToSkip: Cardinal): Word; inline;
begin
  // Alloc enough space for the requested stack trace
  SetLength(BackTrace, FramesToCapture);

  // Get the stack trace. Note that the function is inlined
  Result := RtlCaptureStackBackTrace(FramesToSkip, FramesToCapture,
    BackTrace, nil);

  // Truncare the result
  SetLength(BackTrace, Result);
end;

end.
