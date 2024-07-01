unit NtUiLib.Errors.Dialog;

interface

uses
  Ntapi.WinUser, NtUtils;

const
  DEFAULT_CROSS_SESSION_MESSAGE_TIMEOUT = 60; // sec

// Show a modal error message dialog
function ShowNtxStatus(
  ParentWnd: THwnd;
  const Status: TNtxStatus
): TNtxStatus;

// Show a error message dialog to the interactive user
function ShowNtxStatusAlwaysInteractive(
  const Status: TNtxStatus;
  TimeoutSeconds: Cardinal = DEFAULT_CROSS_SESSION_MESSAGE_TIMEOUT
): TNtxStatus;

// Format a status message (without using reflection)
function NtxVerboseStatusMessageNoReflection(
  const Status: TNtxStatus
): String;

var
  // A custom status formatter (provided by NtUiLib.Exceptions.Dialog)
  NtxVerboseStatusMessageFormatter: function (const Status: TNtxStatus): String;

implementation

uses
  Ntapi.ntdef, NtUtils.SysUtils, NtUiLib.Errors, NtUiLib.TaskDialog;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function NtxVerboseStatusMessageNoReflection;
begin
  // LastCall: <function name>
  Result := 'Last call: ' + RtlxStringOrDefault(Status.Location, '<unknown>');

  if Status.LastCall.Parameter <> '' then
    Result := Result +  #$D#$A'Parameter: ' + Status.LastCall.Parameter;

  // Result: <STATUS_*/ERROR_*>
  Result := Result + #$D#$A'Result: ' + Status.Name;

  // <textual description>
  Result := Result + #$D#$A#$D#$A + Status.Description;
end;

procedure RtlxpPrepareStatusMessage(
  const Status: TNtxStatus;
  out Icon: TDialogIcon;
  out Title: String;
  out Summary: String;
  out Content: String
);
begin
  if Status.IsHResult or NT_ERROR(Status.Status) then
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

  if Assigned(NtxVerboseStatusMessageFormatter) then
    Content := NtxVerboseStatusMessageFormatter(Status)
  else
    Content := NtxVerboseStatusMessageNoReflection(Status);
end;

function ShowNtxStatus;
var
  Icon: TDialogIcon;
  Title, Summary, Content: String;
  Response: TMessageResponse;
begin
  RtlxpPrepareStatusMessage(Status, Icon, Title, Summary, Content);
  Result := UsrxShowTaskDialogWithStatus(Response, ParentWnd, Title, Summary,
    Content, Icon, dbOk, IDOK);
end;

function ShowNtxStatusAlwaysInteractive;
var
  Icon: TDialogIcon;
  Title, Summary, Content: String;
  Response: TMessageResponse;
begin
  RtlxpPrepareStatusMessage(Status, Icon, Title, Summary, Content);
  Result := UsrxShowMessageAlwaysInteractiveWithStatus(Response, Title, Summary,
    Content, Icon, dbOk, IDOK, TimeoutSeconds);
end;

end.
