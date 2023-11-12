unit Ntapi.WinNt.DebugRegisters;

{
  The module extends TContext with properties that simplify usage of debug
  registers (hardware breakpoints).
}

interface

{$MINENUMSIZE 4}

uses
  Ntapi.WinNt;

type
  // There are four hardware breakpoints: Dr0, Dr1, Dr2, Dr3
  THwBpIndex = 0..3;

  THwBreakOn = (
    BreakOnExecution = 0, // X
    BreakOnWrite = 1,     // W
    BreakOnIO = 2,        // RWX (sometimes not supported)
    BreakOnReadWrite = 3  // RW
  );

  THwBreakpointWidth = (
    BreakpointWidthByte = 0,  // 1 byte (must be used for execute breakpoints)
    BreakpointWidthWord = 1,  // 2 bytes
    BreakpointWidthDWord = 3, // 4 bytes
    BreakpointWidthQWord = 2  // 8 bytes (sometimes not supported on 32-bit)
  );

  TDebugHelper = record helper for TContext
  private
    function EnabledMask(i: THwBpIndex): NativeUInt; inline;
    function TypeMask(i: THwBpIndex): NativeUInt; inline;
    function TypeShift(i: THwBpIndex): Cardinal; inline;
    function WidthMask(i: THwBpIndex): NativeUInt; inline;
    function WidthShift(i: THwBpIndex): Cardinal; inline;
  private
    function GetEnabled(i: THwBpIndex): Boolean; inline;
    procedure SetEnabled(i: THwBpIndex; Enable: Boolean); inline;
    function GetType(i: THwBpIndex): THwBreakOn; inline;
    procedure SetType(i: THwBpIndex; const Value: THwBreakOn); inline;
    function GetWidth(i: THwBpIndex): THwBreakpointWidth; inline;
    procedure SetWidth(i: THwBpIndex; const Value: THwBreakpointWidth); inline;
    function GetDetected(i: THwBpIndex): Boolean; inline;
    function GetAddress(i: THwBpIndex): Pointer; inline;
    procedure SetAddress(i: THwBpIndex; const Value: Pointer); inline;
  public
    // Addresses
    property Dr[i: THwBpIndex]: Pointer read GetAddress write SetAddress;

    // Control
    property BreakpointEnabled[i: THwBpIndex]: Boolean read GetEnabled write SetEnabled;
    property BreakpointType[i: THwBpIndex]: THwBreakOn read GetType write SetType;
    property BreakpointWidth[i: THwBpIndex]: THwBreakpointWidth read GetWidth write SetWidth;

    // Status
    property BreakpointDetected[i: THwBpIndex]: Boolean read GetDetected;
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ Bit masking and shifting }

function TDebugHelper.EnabledMask;
begin
  // Enabled flags are stored in bits 0, 2, 4, and 6 respectively
  Result := 1 shl (Cardinal(i) shl 1);
end;

function TDebugHelper.TypeMask;
begin
  // Each breakpoint has its type stored within two bits:
  //  Bits 16..17 for breakpoint 0
  //  Bits 20..21 for breakpoint 1
  //  Bits 24..25 for breakpoint 2
  //  Bits 28..29 for breakpoint 3

  Result := NativeUInt($30000) shl (Cardinal(i) shl 2);
end;

function TDebugHelper.TypeShift;
begin
  // See explanation for the type mask
  Result := (Cardinal(i) shl 2) or $10; // 16, 20, 24, 28
end;

function TDebugHelper.WidthMask;
begin
  // Each breakpoint has its width stored within two bits:
  //  Bits 18..19 for breakpoint 0
  //  Bits 22..23 for breakpoint 1
  //  Bits 26..27 for breakpoint 2
  //  Bits 30..31 for breakpoint 3

  Result := NativeUInt($C0000) shl (Cardinal(i) shl 2);
end;

function TDebugHelper.WidthShift;
begin
  // See explanation for the width mask
  Result := (Cardinal(i) shl 2) + 18; // 18, 22, 26, 30
end;

{ State inspection / modification }

function TDebugHelper.GetAddress;
begin
  case i of
    0: Result := Pointer(Dr0);
    1: Result := Pointer(Dr1);
    2: Result := Pointer(Dr2);
    3: Result := Pointer(Dr3);
  else
    Result := nil;
  end;
end;

function TDebugHelper.GetDetected;
begin
  // Bits 0..3 of the debug status register indicate which breakpoint was hit
  Result := (Dr6 and Byte(i)) <> 0;
end;

function TDebugHelper.GetEnabled;
begin
  // Check the bits in the control register
  Result := (Dr7 and EnabledMask(i)) <> 0;
end;

function TDebugHelper.GetType;
begin
  // Select two specific bits from Dr7 with a mask,
  // and then shift it to the lower bits.
  Result := THwBreakOn((Dr7 and TypeMask(i)) shr TypeShift(i));
end;

function TDebugHelper.GetWidth;
begin
  // Select two specific bits from Dr7 with a mask,
  // and then shift it to the lower bits.
  Result := THwBreakpointWidth((Dr7 and WidthMask(i)) shr WidthShift(i));
end;

procedure TDebugHelper.SetAddress;
begin
  case i of
    0: Dr0 := NativeUInt(Value);
    1: Dr1 := NativeUInt(Value);
    2: Dr2 := NativeUInt(Value);
    3: Dr3 := NativeUInt(Value);
  end;
end;

procedure TDebugHelper.SetEnabled;
begin
  if Enable then
    Dr7 := Dr7 or EnabledMask(i)
  else
    Dr7 := Dr7 and not EnabledMask(i);
end;

procedure TDebugHelper.SetType;
begin
  // Clear specific bits with a mask and then add them back shifting the input
  Dr7 := Dr7 and not TypeMask(i) or (Cardinal(Value) shl TypeShift(i));
end;

procedure TDebugHelper.SetWidth;
begin
  // Clear specific bits with a mask and then add them back shifting the input
  Dr7 := Dr7 and not WidthMask(i) or (Cardinal(Value) shl WidthShift(i));
end;

end.
