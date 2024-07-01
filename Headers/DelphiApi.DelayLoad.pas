unit DelphiApi.DelayLoad;

{
  This header defines types for checking delay loaded imports in other modules.
}

interface

{$MINENUMSIZE 4}

type
  TDelayedLoadDll = record
    DllName: PWideChar;
    DllAddress: Pointer;
  end;

  TDelayedLoadFunction = record
    DllName: PWideChar;
    FunctionName: PAnsiChar;
    FunctionAddress: Pointer;
    Checked: LongBool;
    CheckStatus: Cardinal; // NTSTATUS
  end;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
