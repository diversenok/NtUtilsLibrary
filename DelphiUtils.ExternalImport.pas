unit DelphiUtils.ExternalImport;

interface

// Returns a pointer to a location that stores the target of the jump for
// external import
function ExternalImportTarget(ExternalImport: Pointer): PPointer;

// Gets the target of a Delphi external import
function GetExternalImportTarget(ExternalImport: Pointer; out Target: Pointer)
  : Boolean;

// Sets the target of a Delphi external import
function SetExternalImportTarget(ExternalImport: Pointer; Target: Pointer)
  : Boolean;

implementation

type
  // Delphi's external import is a jmp instruction. In case of a delayed import,
  // it initially points to an internal routine that resolves the import
  // and adjusts the target address.
  TExternalJump = packed record
    Opcode: Word;
    Address: Integer;
  end;
  PExternalJump = ^TExternalJump;

function ExternalImportTarget(ExternalImport: Pointer): PPointer;
begin
  // Expecting jmp instruction
  if PExternalJump(ExternalImport).Opcode <> $25FF then
    Exit(nil);

{$IFDEF Win64}
  // Relative address from the end of instruction on x64
  Result := PPointer(NativeInt(ExternalImport) +
    PExternalJump(ExternalImport).Address + SizeOf(TExternalJump));
{$ELSE}
  // Absolute address on x86
  Result := PPointer(PExternalJump(ExternalImport).Address);
{$ENDIF}
end;

function GetExternalImportTarget(ExternalImport: Pointer; out Target: Pointer)
  : Boolean;
var
  pTarget: PPointer;
begin
  pTarget := ExternalImportTarget(ExternalImport);
  Result := Assigned(pTarget);

  if Result then
    Target := pTarget^;
end;

function SetExternalImportTarget(ExternalImport: Pointer; Target: Pointer)
  : Boolean;
var
  pTarget: PPointer;
begin
  pTarget := ExternalImportTarget(ExternalImport);
  Result := Assigned(pTarget);

  if Result then
    AtomicExchange(pTarget^, Target);
end;

end.
