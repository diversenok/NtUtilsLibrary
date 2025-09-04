unit NtUiLib.Exceptions.Dialog;

{
  This module shows a detailed error dialog for a given TNtxStatus error.
}

interface

uses
  Ntapi.WinUser, NtUtils, NtUiLib.Errors.Dialog;

var
  BUG_TITLE: String = 'This is definitely a bug...';
  BUG_MESSAGE: String = 'If you known how to reproduce this error, please ' +
    'help us by opening an issue on our project''s page.';

type
  // A callback function that might suggest solutions for specific problems
  TSuggester = function (const NtxStatus: TNtxStatus): String;

// Register a suggestion callback
procedure RegisterSuggestions(const Callback: TSuggester);

// Show a modal exception message to a user
function ShowNtxException(
  ParentWnd: THwnd;
  E: TObject
): TNtxStatus;

// Show an exception message dialog to the interactive user
function ShowNtxExceptionAlwaysInteractive(
  E: TObject;
  TimeoutSeconds: Cardinal = DEFAULT_CROSS_SESSION_MESSAGE_TIMEOUT
): TNtxStatus;

implementation

uses
  NtUiLib.TaskDialog, NtUiLib.Exceptions, System.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

procedure RtlxpPrepareExceptionMessage(
  E: TObject;
  out Summary: String;
  out Content: String
);
begin
  if E is Exception then
  begin
    Content := Exception(E).Message;

    // Include the stack trace when available
    if Assigned(Exception.GetStackInfoStringProc) and DisplayStackTraces then
      Content := Content + #$D#$A#$D#$A'Stack Trace:'#$D#$A +
        Exception(E).StackTrace;
  end
  else
    Content := E.ClassName + ' exception';

  if not (E is Exception) or (E is EAccessViolation) or (E is EInvalidPointer)
    or (E is EAssertionFailed) or (E is EArgumentNilException) then
  begin
    Content := Content + #$D#$A#$D#$A + BUG_MESSAGE;
    Summary := BUG_TITLE;
  end
  else if E is EConvertError then
    Summary := 'Conversion error'
  else
    Summary := E.ClassName;
end;

{ Showing }

function ShowNtxException;
var
  Summary, Content: String;
  Response: TMessageResponse;
begin
  // Extract and use TNtxStatus from the exception
  if E is ENtError then
    Exit(ShowNtxStatus(ParentWnd, ENtError(E).NtxStatus));

  RtlxpPrepareExceptionMessage(Exception(E), Summary, Content);
  Result := UsrxShowTaskDialogWithStatus(Response, ParentWnd, 'Exception',
    Summary, Content, diError, dbOk, IDOK);
end;

function ShowNtxExceptionAlwaysInteractive;
var
  Summary, Content: String;
  Response: TMessageResponse;
begin
  // Extract and use TNtxStatus from the exception
  if E is ENtError then
    Exit(ShowNtxStatusAlwaysInteractive(ENtError(E).NtxStatus,
      TimeoutSeconds));

  RtlxpPrepareExceptionMessage(E, Summary, Content);
  Result := UsrxShowMessageAlwaysInteractiveWithStatus(Response, 'Exception',
    Summary, Content, diError, dbOk, IDOK, TimeoutSeconds);
end;

end.
