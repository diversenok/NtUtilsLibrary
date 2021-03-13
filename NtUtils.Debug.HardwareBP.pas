unit NtUtils.Debug.HardwareBP;

{
  The module provides simplified interpretation for debug registeres
  (registers that define state of hardware breakpoints).
}

interface

uses
  Winapi.WinNt;

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

  TDebugRegisters = record
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
    procedure SetType(i: THwBpIndex; Value: THwBreakOn); inline;
    function GetWidth(i: THwBpIndex): THwBreakpointWidth; inline;
    procedure SetWidth(i: THwBpIndex; Value: THwBreakpointWidth); inline;
    function GetDetected(i: THwBpIndex): Boolean; inline;
  public
     /// <summary> Breakpoint addresses </summary>
     Dr: array [THwBpIndex] of Pointer;

     /// <summary>Debug status register</summary>
     Dr6: NativeUInt;
     /// <summary>Debug control register</summary>
     Dr7: NativeUInt;

     // Control
     property Enabled[i: THwBpIndex]: Boolean read GetEnabled write SetEnabled;
     property BreakOn[i: THwBpIndex]: THwBreakOn read GetType write SetType;
     property Width[i: THwBpIndex]: THwBreakpointWidth read GetWidth write SetWidth;

     // Status
     property Detected[i: THwBpIndex]: Boolean read GetDetected;

     // Integration with thread contxet
     procedure LoadContext(Context: PContext);
     procedure SaveContext(Context: PContext);
  end;

implementation

{ Bit masking and shifting }

function TDebugRegisters.EnabledMask;
begin
  // Enabled flags are stored in bits 0, 2, 4, and 6 respectively
  Result := 1 shl (Cardinal(i) shl 1);
end;

function TDebugRegisters.TypeMask;
begin
  // Each breakpoint has its type stored whithin two bits:
  //  Bits 16..17 for breakpoint 0
  //  Bits 20..21 for breakpoint 1
  //  Bits 24..25 for breakpoint 2
  //  Bits 28..29 for breakpoint 3

  Result := NativeUInt($30000) shl (Cardinal(i) shl 2);
end;

function TDebugRegisters.TypeShift;
begin
  // See explanation for the type mask
  Result := (Cardinal(i) shl 2) or $10; // 16, 20, 24, 28
end;

function TDebugRegisters.WidthMask;
begin
  // Each breakpoint has its width stored whithin two bits:
  //  Bits 18..19 for breakpoint 0
  //  Bits 22..23 for breakpoint 1
  //  Bits 26..27 for breakpoint 2
  //  Bits 30..31 for breakpoint 3

  Result := NativeUInt($C0000) shl (Cardinal(i) shl 2);
end;

function TDebugRegisters.WidthShift;
begin
  // See explanation for the width mask
  Result := (Cardinal(i) shl 2) + 18; // 18, 22, 26, 30
end;

{ State inspection / modification }

function TDebugRegisters.GetDetected;
begin
  // Bits 0..3 of the debug status register indicate which breakpoint was hit
  Result := (Dr6 and Byte(i)) <> 0;
end;

function TDebugRegisters.GetEnabled;
begin
  // Check the bits in the control register
  Result := (Dr7 and EnabledMask(i)) <> 0;
end;

function TDebugRegisters.GetType;
begin
  // Select two specific bits from Dr7 with a mask,
  // and then shift it to the lower bits.
  Result := THwBreakOn((Dr7 and TypeMask(i)) shr TypeShift(i));
end;

function TDebugRegisters.GetWidth;
begin
  // Select two specific bits from Dr7 with a mask,
  // and then shift it to the lower bits.
  Result := THwBreakpointWidth((Dr7 and WidthMask(i)) shr WidthShift(i));
end;

procedure TDebugRegisters.LoadContext;
begin
  Dr[0] := Pointer(Context.Dr0);
  Dr[1] := Pointer(Context.Dr1);
  Dr[2] := Pointer(Context.Dr2);
  Dr[3] := Pointer(Context.Dr3);
  Dr6 := Context.Dr6;
  Dr7 := Context.Dr7;
end;

procedure TDebugRegisters.SaveContext;
begin
  Context.Dr0 := NativeUInt(Dr[0]);
  Context.Dr1 := NativeUInt(Dr[1]);
  Context.Dr2 := NativeUInt(Dr[2]);
  Context.Dr3 := NativeUInt(Dr[3]);
  Context.Dr6 := Dr6;
  Context.Dr7 := Dr7;
end;

procedure TDebugRegisters.SetEnabled;
begin
  if Enable then
    Dr7 := Dr7 or EnabledMask(i)
  else
    Dr7 := Dr7 and not EnabledMask(i);
end;

procedure TDebugRegisters.SetType;
begin
  // Clear specific bits with a mask and then add them back shifting the input
  Dr7 := Dr7 and not TypeMask(i) or (Cardinal(Value) shl TypeShift(i));
end;

procedure TDebugRegisters.SetWidth;
begin
  // Clear specific bits with a mask and then add them back shifting the input
  Dr7 := Dr7 and not WidthMask(i) or (Cardinal(Value) shl WidthShift(i));
end;

end.
