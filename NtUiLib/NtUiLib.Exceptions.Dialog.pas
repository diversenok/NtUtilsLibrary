unit NtUiLib.Exceptions.Dialog;

{
  This module shows a detailed error dialog for a given TNtxStatus error.
}

interface

uses
  Ntapi.WinUser, System.SysUtils, NtUtils;

var
  BUG_TITLE: String = 'This is definitely a bug...';
  BUG_MESSAGE: String = 'If you known how to reproduce this error, please ' +
    'help us by opening an issue on our project''s page.';

type
  // A callback function that might suggest solutions for specific problems
  TSuggester = function (const NtxStatus: TNtxStatus): String;

// Register a suggestion callback
procedure RegisterSuggestions(const Callback: TSuggester);

// Show a modal error message to a user
procedure ShowNtxStatus(ParentWnd: THwnd; const Status: TNtxStatus);
procedure ShowNtxException(ParentWnd: THwnd; E: Exception);

implementation

uses
  Ntapi.ntdef, Ntapi.ntstatus, NtUiLib.TaskDialog,
  NtUiLib.Errors, NtUiLib.Exceptions, NtUiLib.Reflection.Exceptions;

var
  Suggesters: TArray<TSuggester>;

procedure RegisterSuggestions;
begin
  SetLength(Suggesters, Length(Suggesters) + 1);
  Suggesters[High(Suggesters)] := Callback;
end;

function CollectSuggestions(const NtxStatus: TNtxStatus): String;
var
  Suggestions: TArray<String>;
  i: Integer;
begin
  for i := 0 to High(Suggesters) do
  begin
    Result := Suggesters[i](NtxStatus);

    if Result <> '' then    
    begin
      SetLength(Suggestions, Length(Suggestions) + 1);
      Suggestions[High(Suggestions)] := Result;
    end;
  end;

  if Length(Suggestions) > 0 then
    Result := #$D#$A#$D#$A'--- Suggestions ---'#$D#$A +
      String.Join(#$D#$A#$D#$A, Suggestions)
  else
    Result := '';
end;

{ Showing }

procedure ShowNtxStatus;
var
  Icon: TDialogIcon;
  Title, Summary: String;
begin
  if not Status.IsHResult and NT_ERROR(Status.Status) then
  begin
    Icon := diError;
    Title := 'Error';
  end
  else
  begin
    Icon := diWarning;
    Title := 'Warning';
  end;

  // Make a pretty header
  Summary := Status.Summary;

  if Summary = '' then
    Summary := 'System error';

  // TODO: include stack trace when available

  UsrxShowTaskDialog(ParentWnd, Title, Summary,
    NtxVerboseStatusMessage(Status) + CollectSuggestions(Status), Icon);
end;

procedure ShowNtxException;
var
  Summary, Text: String;
begin
  if E is ENtError then
    // Extract a TNtxStatus from an exception
    ShowNtxStatus(ParentWnd, ENtError(E).NtxStatus)
  else
  begin
    Text := E.Message;

    // Include the stack trace when available
    if Assigned(Exception.GetStackInfoStringProc) then
      Text := Text + #$D#$A#$D#$A + 'Stack Trace:'#$D#$A + E.StackTrace;

    if (E is EAccessViolation) or (E is EInvalidPointer) or
      (E is EAssertionFailed) or (E is EArgumentNilException) then
    begin
      Text := Text + #$D#$A#$D#$A + BUG_MESSAGE;
      Summary := BUG_TITLE;
    end
    else if E is EConvertError then
      Summary := 'Conversion error'
    else
      Summary := E.ClassName;

    UsrxShowTaskDialog(ParentWnd, 'Exception', Summary, Text, diError);
  end;
end;

end.
