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

// Show a modal exception message to a user
function UiLibShowNtxException(
  ParentWnd: THwnd;
  E: TObject
): TNtxStatus;

// Show an exception message dialog to the interactive user
function UiLibShowNtxExceptionAlwaysInteractive(
  E: TObject;
  TimeoutSeconds: Cardinal = DEFAULT_CROSS_SESSION_MESSAGE_TIMEOUT
): TNtxStatus;

implementation

uses
  NtUiLib.TaskDialog, NtUiLib.Exceptions, System.SysUtils;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

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

function UiLibShowNtxException;
var
  Summary, Content: String;
  Response: TMessageResponse;
begin
  // Extract and use TNtxStatus from the exception
  if E is ENtError then
    Exit(UiLibShowNtxStatus(ParentWnd, ENtError(E).NtxStatus));

  RtlxpPrepareExceptionMessage(Exception(E), Summary, Content);
  Result := UsrxShowTaskDialogWithStatus(Response, ParentWnd, 'Exception',
    Summary, Content, diError, dbOk, IDOK);
end;

function UiLibShowNtxExceptionAlwaysInteractive;
var
  Summary, Content: String;
  Response: TMessageResponse;
begin
  // Extract and use TNtxStatus from the exception
  if E is ENtError then
    Exit(UiLibShowNtxStatusAlwaysInteractive(ENtError(E).NtxStatus,
      TimeoutSeconds));

  RtlxpPrepareExceptionMessage(E, Summary, Content);
  Result := UsrxShowMessageAlwaysInteractiveWithStatus(Response, 'Exception',
    Summary, Content, diError, dbOk, IDOK, TimeoutSeconds);
end;

end.
