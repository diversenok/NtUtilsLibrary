unit DelphiApi.DelayLoad;

{
  This header defines types for checking delay loaded imports in other modules.
}

interface

{$MINENUMSIZE 4}

type
  TDelayedLoadDll = record
    Initialized: UIntPtr; // inline TRtlRunOnce
    DllName: PWideChar;
    DllAddress: Pointer;
  end;
  PDelayedLoadDll = ^TDelayedLoadDll;

  TDelayedLoadFunction = record
    Initialized: UIntPtr; // inline TRtlRunOnce
    Dll: PDelayedLoadDll;
    FunctionName: PAnsiChar;
    FunctionAddress: Pointer;
    CheckStatus: Cardinal; // NTSTATUS
    function IsImportByOrdinal: Boolean;
    function Ordinal: Word;
  end;
  PDelayedLoadFunction = ^TDelayedLoadFunction;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TDelayedLoadFunction }

function TDelayedLoadFunction.IsImportByOrdinal;
begin
  Result := UIntPtr(FunctionName) <= High(Word);
end;

function TDelayedLoadFunction.Ordinal;
begin
  Result := Word(FunctionName);
end;

end.
