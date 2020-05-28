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
    Flags: TLdrFlags;
    TimeDateStamp: Cardinal;
    ParentDllBase: Pointer;
    [Hex] OriginalBase: UIntPtr;
    LoadTime: TLargeInteger;
    [MinOSVersion(OsWin8)] LoadReason: TLdrDllLoadReason;
    // TODO: more fields
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
  Ntapi.ntdef, Ntapi.ntpebteb, Ntapi.ntdbg;

function LdrxCheckNtDelayedImport(Name: AnsiString): TNtxStatus;
var
  ProcName: ANSI_STRING;
  ProcAddr: Pointer;
begin
  ProcName.FromString(Name);

  Result.Location := 'LdrGetProcedureAddress("' + String(Name) + '")';
  Result.Status := LdrGetProcedureAddress(hNtdll, ProcName, 0, ProcAddr);
end;

function LdrxCheckModuleDelayedImport(ModuleName: String;
  ProcedureName: AnsiString): TNtxStatus;
var
  DllName: UNICODE_STRING;
  ProcName: ANSI_STRING;
  hDll: HMODULE;
  ProcAddr: Pointer;
begin
  DllName.FromString(ModuleName);

  Result.Location := 'LdrGetDllHandle';
  Result.Status := LdrGetDllHandle(nil, nil, DllName, hDll);

  if not NT_SUCCESS(Result.Status) then
  begin
    // Try to load it
    Result.Location := 'LdrLoadDll';
    Result.Status := LdrLoadDll(nil, nil, DllName, hDll);

    if not NT_SUCCESS(Result.Status) then
      Exit;
  end;

  ProcName.FromString(ProcedureName);

  Result.Location := 'LdrGetProcedureAddress';
  Result.Status := LdrGetProcedureAddress(hDll, ProcName, 0, ProcAddr);
end;

function LdrxGetDllHandle(DllName: String; out DllHandle: HMODULE): TNtxStatus;
var
  DllNameStr: UNICODE_STRING;
begin
  DllNameStr.FromString(DllName);

  Result.Location := 'LdrGetDllHandle("' + DllName + '")';
  Result.Status := LdrGetDllHandle(nil, nil, DllNameStr, DllHandle);
end;

function LdrxLoadDll(DllName: String; out DllHandle: HMODULE): TNtxStatus;
var
  DllNameStr: UNICODE_STRING;
begin
  DllNameStr.FromString(DllName);

  Result.Location := 'LdrLoadDll("' + DllName + '")';
  Result.Status := LdrLoadDll(nil, nil, DllNameStr, DllHandle)
end;

function LdrxGetProcedureAddress(DllHandle: HMODULE; ProcedureName: AnsiString;
  out Status: TNtxStatus): Pointer;
var
  ProcNameStr: ANSI_STRING;
begin
  ProcNameStr.FromString(ProcedureName);

  Status.Location := 'LdrGetProcedureAddress("' + String(ProcedureName) + '")';
  Status.Status := LdrGetProcedureAddress(DllHandle, ProcNameStr, 0, Result);
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

      if OsVersion >= OsWin8 then
        LoadReason := Current.LoadReason;
    end;

    // Go to the next one
    Current := PLdrDataTableEntry(Current.InLoadOrderLinks.Flink);
    Inc(i);
  end;
end;

var
  OldFailureHook: TDelayedLoadHook;

function NtxpDelayedLoadHook(dliNotify: dliNotification;
  pdli: PDelayLoadInfo): Pointer; stdcall;
var
  Status: NTSTATUS;
begin
  Status := RtlxGetLastNtStatus;
  DbgBreakOnFailure(Status);

  if Assigned(OldFailureHook) then
    OldFailureHook(dliNotify, pdli);

  Result := nil;
end;

initialization
  OldFailureHook := SetDliFailureHook2(NtxpDelayedLoadHook);
finalization

end.
