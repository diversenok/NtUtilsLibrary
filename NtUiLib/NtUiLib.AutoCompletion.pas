unit NtUiLib.AutoCompletion;

{
  The module provides functions for creating custom auto-completion lists
  similar to those created by SHAutoComplete.
}

interface

uses
  Winapi.WinUser, Winapi.Shlwapi, NtUtils;

type
  TExpandProvider = reference to function (
    const Root: String;
    out Suggestions: TArray<String>
  ): TNtxStatus;

// Add a static list of suggestions to an Edit-derived control.
function ShlxEnableStaticSuggestions(
  EditControl: HWND;
  const Strings: TArray<String>;
  Options: Cardinal = ACO_AUTOSUGGEST or ACO_UPDOWNKEYDROPSLIST
): TNtxStatus;

// Register dynamic (hierarchical) suggestions for an Edit-derived control.
function ShlxEnableDynamicSuggestions(
  EditControl: HWND;
  const Provider: TExpandProvider;
  Options: Cardinal = ACO_AUTOSUGGEST or ACO_UPDOWNKEYDROPSLIST
): TNtxStatus;

implementation

uses
  Winapi.WinNt, Winapi.ObjBase, Winapi.ObjIdl, NtUtils.WinUser;

type
  TStringEnumerator = class(TInterfacedObject, IEnumString, IACList)
  private
    function Next(
      Count: Integer;
      out Elements: TAnysizeArray<PWideChar>;
      Fetched: PInteger
    ): HResult; stdcall;
    function Skip(Count: Integer): HResult; stdcall;
    function Reset: HResult; stdcall;
    function Clone(out Enm: IEnumString): HResult; stdcall;
    function Expand(Root: PWideChar): HResult; stdcall;
  protected
    EditControl: HWND;
    Provider: TExpandProvider;
    Strings: TArray<String>;
    Index: Integer;
    constructor CreateCopy(Source: TStringEnumerator);
  public
    constructor CreateStatic(EditControl: HWND; Strings: TArray<String>);
    constructor CreateDynamic(EditControl: HWND; Provider: TExpandProvider);
  end;

{ TStringEnumerator }

function TStringEnumerator.Clone;
begin
  Enm := TStringEnumerator.CreateCopy(Self);
  Result := S_OK;
end;

constructor TStringEnumerator.CreateCopy;
begin
  inherited Create;
  EditControl := Source.EditControl;
  Provider := Source.Provider;
  Strings := Source.Strings;
  Index := Source.Index;
end;

constructor TStringEnumerator.CreateDynamic;
begin
  inherited Create;
  Self.EditControl := EditControl;
  Self.Provider := Provider;
end;

constructor TStringEnumerator.CreateStatic;
begin
  inherited Create;
  Self.EditControl := EditControl;
  Self.Strings := Strings;
end;

function TStringEnumerator.Expand;
begin
  // Use the callback to enumerate suggestions in a hierarchy
  if Assigned(Provider) then
    Result := Provider(String(Root), Strings).HResult
  else
    Result := S_FALSE;
end;

function TStringEnumerator.Next;
var
  i: Integer;
begin
  i := 0;

  // Return strings until we satisfy the count or have nothing left
  while (i < Count) and (Index <= High(Strings)) do
  begin
    // The caller is responsble for freeing each string
    Elements[i] := SysAllocString(PWideChar(Strings[Index]));
    Inc(i);
    Inc(Index);
  end;

  if Assigned(Fetched) then
    Fetched^ := i;

  if i = Count then
    Result := S_OK
  else
    Result := S_FALSE;
end;

function TStringEnumerator.Reset;
var
  CurrentText: String;
begin
  // For some reason, AutoComplete does not call Expand on the root; fix it.
  if UsrxGetWindowText(EditControl, CurrentText).IsSuccess and
    (Pos('\', CurrentText) <= 0) then
    Expand(nil);

  Index := 0;
  Result := S_OK;
end;

function TStringEnumerator.Skip;
begin
  Inc(Index, Count);

  if Index > High(Strings) then
    Result := S_FALSE
  else
    Result := S_OK;
end;

{ Functions }

function ShlxpEnableSuggestions(
  EditControl: HWND;
  const ACList: IUnknown;
  Options: Cardinal
): TNtxStatus;
var
  AutoComplete: IAutoComplete2;
begin
  // Create an instance of CLSID_AutoComplete (provided by the OS)
  Result.Location := 'CoCreateInstance(CLSID_AutoComplete)';
  Result.HResult := CoCreateInstance(CLSID_AutoComplete, nil,
    CLSCTX_INPROC_SERVER, IAutoComplete2, AutoComplete);

  if not Result.IsSuccess then
    Exit;

  // Adjust options
  Result.Location := 'IAutoComplete2::SetOptions';
  Result.HResult := AutoComplete.SetOptions(Options);

  if not Result.IsSuccess then
    Exit;

  // Register our suggestions
  Result.Location := 'IAutoComplete::Init';
  Result.HResult := AutoComplete.Init(EditControl, ACList, nil, nil);
end;

function ShlxEnableStaticSuggestions;
begin
  Result := ShlxpEnableSuggestions(EditControl, TStringEnumerator.CreateStatic(
    EditControl, Strings), Options);
end;

function ShlxEnableDynamicSuggestions;
begin
  Result := ShlxpEnableSuggestions(EditControl, TStringEnumerator.CreateDynamic(
    EditControl, Provider), Options);
end;

end.
