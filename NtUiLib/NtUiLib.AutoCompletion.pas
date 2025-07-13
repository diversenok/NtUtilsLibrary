unit NtUiLib.AutoCompletion;

{
  The module provides functions for creating custom auto-completion lists
  similar to those created by SHAutoComplete.
}

interface

uses
  Ntapi.WinUser, Ntapi.Shlwapi, Ntapi.ObjBase, NtUtils;

type
  TAutoCompletionCallback = reference to function (
    const Root: String;
    out Suggestions: TArray<String>
  ): TNtxStatus;

  IAutoCompletionSuggestions = interface
    ['{049B6656-ACB8-46E1-B02B-E3C9A933B5A7}']
    function GetSuggestions: TArray<String>;
    function Expand(const Root: String): TNtxStatus;
  end;

// Prepare a static list of suggestions
function ShlxPrepareStatisSuggestions(
  const Strings: TArray<String>
): IAutoCompletionSuggestions;

// Prepare a dynamic (hierarchical) list of suggestions
function ShlxPrepareDynamicSuggestions(
  const Callback: TAutoCompletionCallback
): IAutoCompletionSuggestions;

// Add auto-completion suggestions to an Edit-derived control.
// Note: The caller is responsible for keeping the passed provider alive for as
// long as they want to see suggestions (such as up to control destruction).
// This is necessary because Windows 11 started leaking auto-completion list
// objects, and we don't want it to indefinitely retain our suggestion
// provider's resources. As a workaround, we use a proxy with a weak reference
// that will disconnect the provider upon its destruction and only leak a small
// proxy instead.
[RequiresCOM]
function ShlxEnableSuggestions(
  EditControl: THwnd;
  Provider: IAutoCompletionSuggestions;
  Options: Cardinal = ACO_AUTOSUGGEST or ACO_UPDOWNKEYDROPSLIST
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.ObjIdl, Ntapi.WinError, Ntapi.ShellApi, Ntapi.Versions,
  NtUtils.WinUser, DelphiApi.Reflection, NtUtils.Com, DelphiUtils.AutoObjects;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

{ TACListProxy }

type
  // Note: we want to implementation to be able to disconnect from the
  // enumerator since Windows 11 leaks the interface by not correctly managing
  // its lifetime.
  TACListProxy = class (TAutoInterfacedObject, IEnumString, IACList)
  private
    FEditControl: THwnd;
    FProvider: Weak<IAutoCompletionSuggestions>;
    FIndex: Integer;

    function Next(
      [in, NumberOfElements] Count: Integer;
      [out, WritesTo, ReleaseWith('CoTaskMemFree')] out Elements:
        TAnysizeArray<PWideChar>;
      [out, NumberOfElements] out Fetched: Integer
    ): HResult; stdcall;

    function Skip(
      [in,  NumberOfElements] Count: Integer
    ): HResult; stdcall;

    function Reset(
    ): HResult; stdcall;

    function Clone(
      [out] out Enm: IEnumString
    ): HResult; stdcall;

    function Expand(Root: PWideChar): HResult; stdcall;
    constructor Create(
      EditControl: THwnd;
      const Provider: IAutoCompletionSuggestions;
      Index: Integer = 0
    );
  end;

function TACListProxy.Clone;
var
  StrongRef: IAutoCompletionSuggestions;
begin
  if FProvider.Upgrade(StrongRef) then
  begin
    Enm := TACListProxy.Create(FEditControl, StrongRef, FIndex);
    Result := S_OK
  end
  else
    Result := RPC_E_DISCONNECTED;
end;

constructor TACListProxy.Create;
begin
  inherited Create;
  FEditControl := EditControl;
  FProvider := Provider;

  // Windows 11's implementation of IAutoComplete leaks our objects. We
  // cannot do much about it aside from using a weak reference to the suggestion
  // provider (so we don't keep it alive indefinitely) and registering this
  // object as an expected memor leak (to prevent ReportMemoryLeaksOnShutdown
  // from complaining).
  if RtlOsVersionAtLeast(OsWin11) then
    SysRegisterExpectedMemoryLeak(Self);
end;

function TACListProxy.Expand;
var
  StrongRef: IAutoCompletionSuggestions;
begin
  if FProvider.Upgrade(StrongRef) then
    Result := StrongRef.Expand(String(Root)).HResult
  else
    Result := RPC_E_DISCONNECTED;
end;

function TACListProxy.Next;
var
  StrongRef: IAutoCompletionSuggestions;
  Strings: TArray<String>;
  Buffer: PWideChar;
begin
  if not FProvider.Upgrade(StrongRef) then
    Exit(RPC_E_DISCONNECTED);

  // Collect suggestions from the provider
  Strings := StrongRef.GetSuggestions;
  Fetched := 0;

  // Return strings until we satisfy the count or have nothing left
  while (Fetched < Count) and (FIndex >= 0) and (FIndex <= High(Strings)) do
  begin
    // The caller is responsible for freeing each string
    Buffer := CoTaskMemAlloc(StringSizeZero(Strings[FIndex]));

    if not Assigned(Buffer) then
    begin
      // Undo previous allocations on failure mid-way
      Dec(Fetched);
      while Fetched >= 0 do
      begin
        CoTaskMemFree(Elements{$R-}[Fetched]{$IFDEF R+}{$R+}{$ENDIF});
        Elements{$R-}[Fetched]{$IFDEF R+}{$R+}{$ENDIF} := nil;
        Dec(Fetched);
        Dec(FIndex);
      end;

      Fetched := 0;
      Exit(E_OUTOFMEMORY);
    end;

    MarshalString(Strings[FIndex], Buffer);
    Elements{$R-}[Fetched]{$IFDEF R+}{$R+}{$ENDIF} := Buffer;
    Inc(Fetched);
    Inc(FIndex);
  end;

  if Fetched = Count then
    Result := S_OK
  else
    Result := S_FALSE;
end;

function TACListProxy.Reset;
var
  CurrentText: String;
begin
  // For some reason, AutoComplete does not call Expand on the root; fix it.
  if UsrxGetWindowText(FEditControl, CurrentText).IsSuccess and
    (Pos('\', CurrentText) <= 0) then
    Expand(nil);

  FIndex := 0;
  Result := S_OK;
end;

function TACListProxy.Skip;
begin
  Inc(FIndex, Count);
  Result := S_OK;
end;

{ TAutoCompletionSuggestions }

type
  TAutoCompletionSuggestions = class (TAutoInterfacedObject,
    IAutoCompletionSuggestions)
  private
    FStrings: TArray<String>;
    FCallback: TAutoCompletionCallback;
  public
    function GetSuggestions: TArray<String>;
    function Expand(const Root: String): TNtxStatus;
    constructor Create(
      const InitialStrings: TArray<String>;
      const Callback: TAutoCompletionCallback
    );
  end;

constructor TAutoCompletionSuggestions.Create;
begin
  inherited Create;
  FStrings := InitialStrings;
  FCallback := Callback;
end;

function TAutoCompletionSuggestions.Expand;
begin
  if Assigned(FCallback) then
    // Update the suggestions list
    Result := FCallback(Root, FStrings)
  else
    // Use the initial list
    Result := NtxSuccess;
end;

function TAutoCompletionSuggestions.GetSuggestions;
begin
  Result := FStrings;
end;

{ Functions }

function ShlxPrepareStatisSuggestions;
begin
  Result := TAutoCompletionSuggestions.Create(Strings, nil);
end;

function ShlxPrepareDynamicSuggestions;
begin
  Result := TAutoCompletionSuggestions.Create(nil, Callback);
end;

function ShlxEnableSuggestions;
var
  AutoComplete: IAutoComplete2;
  ACList: IACList;
begin
  // Create an instance of CLSID_AutoComplete (provided by the OS)
  Result := ComxCreateInstanceWithFallback(shell32, CLSID_AutoComplete,
    IAutoComplete2, AutoComplete, 'CLSID_AutoComplete');

  if not Result.IsSuccess then
    Exit;

  // Adjust options
  Result.Location := 'IAutoComplete2::SetOptions';
  Result.HResult := AutoComplete.SetOptions(Options);

  if not Result.IsSuccess then
    Exit;

  // Create our custom IACList that [weak-]references the suggestioon provider
  ACList := TACListProxy.Create(EditControl, Provider);

  // Register our suggestions
  Result.Location := 'IAutoComplete::Init';
  Result.HResult := AutoComplete.Init(EditControl, ACList, nil, nil);
end;

end.
