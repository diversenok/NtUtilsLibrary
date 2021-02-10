unit NtUtils.Ldr;

interface

uses
  Winapi.WinNt, Ntapi.ntldr, NtUtils, NtUtils.Version, DelphiApi.Reflection;

const
  // Artificial limitation to prevent infinite loops
  MAX_MODULES = $800;

type
  TModuleEntry = record
    DllBase: Pointer;
    EntryPoint: Pointer;
    [Bytes] SizeOfImage: Cardinal;
    FullDllName: String;
    BaseDllName: String;
    LoadCount: Cardinal;
    Flags: TLdrFlags;
    TimeDateStamp: Cardinal;
    ParentDllBase: Pointer;
    [Hex] OriginalBase: UIntPtr;
    LoadTime: TLargeInteger;
    [MinOSVersion(OsWin8)] LoadReason: TLdrDllLoadReason;
    // TODO: more fields
    function IsInRange(Address: Pointer): Boolean;
  end;

{ Delayed import }

// Check if a function presents in ntdll
function LdrxCheckNtDelayedImport(Name: AnsiString): TNtxStatus;

// Check if a function presents in a dll. Loads the dll if necessary
function LdrxCheckModuleDelayedImport(ModuleName: String;
  ProcedureName: AnsiString): TNtxStatus;

{ Other }

// Get base address of a loaded dll
function LdrxGetDllHandle(DllName: String; out DllHandle: HMODULE): TNtxStatus;

// Load a dll
function LdrxLoadDll(DllName: String; out DllHandle: HMODULE): TNtxStatus;

// Get a function address
function LdrxGetProcedureAddress(DllHandle: HMODULE; ProcedureName: AnsiString;
  out Status: TNtxStatus): Pointer;

// Enumerate loaded modules
function LdrxEnumerateModules: TArray<TModuleEntry>;

implementation

uses
  Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntrtl;

function LdrxCheckNtDelayedImport(Name: AnsiString): TNtxStatus;
var
  ProcAddr: Pointer;
begin
  Result.Location := 'LdrGetProcedureAddress("' + String(Name) + '")';
  Result.Status := LdrGetProcedureAddress(hNtdll, TNtAnsiString.From(Name), 0,
    ProcAddr);
end;

function LdrxCheckModuleDelayedImport(ModuleName: String;
  ProcedureName: AnsiString): TNtxStatus;
var
  hDll: HMODULE;
  ProcAddr: Pointer;
begin
  Result.Location := 'LdrGetDllHandle';
  Result.Status := LdrGetDllHandle(nil, nil, TNtUnicodeString.From(ModuleName),
    hDll);

  if not NT_SUCCESS(Result.Status) then
  begin
    // Try to load it
    Result.Location := 'LdrLoadDll';
    Result.Status := LdrLoadDll(nil, nil, TNtUnicodeString.From(ModuleName),
      hDll);

    if not NT_SUCCESS(Result.Status) then
      Exit;
  end;

  Result.Location := 'LdrGetProcedureAddress';
  Result.Status := LdrGetProcedureAddress(hDll,
    TNtAnsiString.From(ProcedureName), 0, ProcAddr);
end;

function LdrxGetDllHandle(DllName: String; out DllHandle: HMODULE): TNtxStatus;
begin
  Result.Location := 'LdrGetDllHandle("' + DllName + '")';
  Result.Status := LdrGetDllHandle(nil, nil, TNtUnicodeString.From(DllName),
    DllHandle);
end;

function LdrxLoadDll(DllName: String; out DllHandle: HMODULE): TNtxStatus;
begin
  Result.Location := 'LdrLoadDll("' + DllName + '")';
  Result.Status := LdrLoadDll(nil, nil, TNtUnicodeString.From(DllName),
    DllHandle)
end;

function LdrxGetProcedureAddress(DllHandle: HMODULE; ProcedureName: AnsiString;
  out Status: TNtxStatus): Pointer;
begin
  Status.Location := 'LdrGetProcedureAddress("' + String(ProcedureName) + '")';
  Status.Status := LdrGetProcedureAddress(DllHandle,
    TNtAnsiString.From(ProcedureName), 0, Result);
end;

function LdrxEnumerateModules: TArray<TModuleEntry>;
var
  i: Integer;
  Start, Current: PLdrDataTableEntry;
  OsVersion: TKnownOsVersion;
begin
  // Traverse the list
  i := 0;
  Start := PLdrDataTableEntry(@RtlGetCurrentPeb.Ldr.InLoadOrderModuleList);
  Current := PLdrDataTableEntry(RtlGetCurrentPeb.Ldr.InLoadOrderModuleList.Flink);
  OsVersion := RtlOsVersion;
  SetLength(Result, 0);

  while (Start <> Current) and (i <= MAX_MODULES) do
  begin
    // Save it
    SetLength(Result, Length(Result) + 1);
    with Result[High(Result)] do
    begin
      DllBase := Current.DllBase;
      EntryPoint := Current.EntryPoint;
      SizeOfImage := Current.SizeOfImage;
      FullDllName := Current.FullDllName.ToString;
      BaseDllName := Current.BaseDllName.ToString;
      Flags := Current.Flags;
      TimeDateStamp := Current.TimeDateStamp;
      LoadTime := Current.LoadTime;
      ParentDllBase := Current.ParentDllBase;
      OriginalBase := Current.OriginalBase;
      LoadCount := Current.ObsoleteLoadCount;

      if OsVersion >= OsWin8 then
      begin
        LoadReason := Current.LoadReason;
        LoadCount := Current.DdagNode.LoadCount;
      end;
    end;

    // Go to the next one
    Current := PLdrDataTableEntry(Current.InLoadOrderLinks.Flink);
    Inc(i);
  end;
end;

function TModuleEntry.IsInRange(Address: Pointer): Boolean;
begin
  Result := (UIntPtr(DllBase) <= UIntPtr(Address)) and
    (UIntPtr(Address) <= UIntPtr(DllBase) + SizeOfImage);
end;

{$IFDEF Debug}
var
  OldFailureHook: TDelayedLoadHook;

function BreakOnFailure(dliNotify: dliNotification; pdli: PDelayLoadInfo):
  Pointer; stdcall;
begin
  if RtlGetCurrentPeb.BeingDebugged then
    DbgBreakPoint;

  if Assigned(OldFailureHook) then
    OldFailureHook(dliNotify, pdli);

  Result := nil;
end;
{$ENDIF}

initialization
  {$IFDEF Debug}OldFailureHook := SetDliFailureHook2(BreakOnFailure);{$ENDIF}
finalization

end.
