unit NtUtils.Threads.Stack;

interface

uses
  NtUtils;

// Get current address (address of the next instruction to be executed)
function CurrentAddress: Pointer;

// To get the address of the caller, use System.ReturnAddress

// Get address of the caller's caller
function RtlxCallersCallerAddress: Pointer; inline;

// Capture a stack trace of the current thread
function RtlxCaptureStackTrace(FramesToCapture: Cardinal = 32;
  FramesToSkip: Cardinal = 0): TArray<Pointer>;

implementation

uses
  Ntapi.ntrtl;

function CurrentAddress: Pointer;
begin
  // Return address whitin a non-inline function is the address of the next
  // instruction after it returns
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

function RtlxCaptureStackTrace(FramesToCapture: Cardinal;
  FramesToSkip: Cardinal): TArray<Pointer>;
var
  Count: Cardinal;
begin
  // Alloc enough space for the requested stack trace
  SetLength(Result, FramesToCapture);

  // Get the stack trace. Note that the function is inlined
  Count := RtlCaptureStackBackTrace(FramesToSkip, FramesToCapture,
    Result, nil);

  // Truncare the result
  SetLength(Result, Count);
end;

end.
