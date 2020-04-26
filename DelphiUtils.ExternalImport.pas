unit DelphiUtils.ExternalImport;

interface

// Returns a pointer to a location in the IAT that stores the target of the jump
// used by Delphi external import
function ExternalImportTarget(ExternalImport: Pointer): PPointer;

// Determines the target of a Delphi external import
function GetExternalImportTarget(ExternalImport: Pointer; out Target: Pointer)
  : Boolean;

// Overwrites IAT to set a target of a Delphi external import
function SetExternalImportTarget(ExternalImport: Pointer; Target: Pointer)
  : Boolean;

// Atomic exchange of the target of a Delphi external import
function ExchangeExternalImportTarget(ExternalImport: Pointer;
  NewTarget: Pointer; out OldTarget: Pointer): Boolean;

implementation

const
  JMP = $25FF;

type
  // Delphi's external import is a jmp instruction that uses a value from IAT
  // (Import Address Table). In case of a delayed import, it initially points to
  // an internal routine that resolves the import and adjusts the target address
  TExternalJump = packed record
    Opcode: Word; // FF 25
    Address: Integer;
  end;
  PExternalJump = ^TExternalJump;

function ExternalImportTarget(ExternalImport: Pointer): PPointer;
begin
  // Expecting a jump instruction
  if PExternalJump(ExternalImport).Opcode <> JMP then
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

function ExchangeExternalImportTarget(ExternalImport: Pointer;
  NewTarget: Pointer; out OldTarget: Pointer): Boolean;
var
  pTarget: PPointer;
begin
  pTarget := ExternalImportTarget(ExternalImport);
  Result := Assigned(pTarget);

  if Result then
    OldTarget := AtomicExchange(pTarget^, NewTarget);
end;

end.
