unit NtUiLib.Errors.Dialog;

interface

uses
  Ntapi.WinUser, NtUtils;

const
  DEFAULT_CROSS_SESSION_MESSAGE_TIMEOUT = 60; // sec

var
  // Display stack traces in the error dialog, when available
  DisplayStackTraces: Boolean = False;

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
function UiLibVerboseStatusMessage(
  const Status: TNtxStatus
): String;

implementation

uses
  Ntapi.ntdef, NtUtils.SysUtils, NtUiLib.Errors, NtUiLib.TaskDialog,
  NtUtils.DbgHelp, DelphiApi.Reflection, DelphiUtils.LiteRTTI,
  DelphiUtils.LiteRTTI.Extension, DelphiUiLib.LiteReflection, Ntapi.ntstatus,
  Ntapi.WinError, Ntapi.ntseapi;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function UiLibVerboseStatusMessage;
type
  [NamingStyle(nsPreserveCase)]
  PreserveCase = type Pointer;
var
  i: Integer;
  AType: IRttixType;
begin
  // LastCall: <function name>
  Result := 'Last call: ' + RtlxStringOrDefault(Status.Location, '<unknown>');

  if Status.LastCall.Parameter <> '' then
    Result := Result +  #$D#$A'Parameter: ' + Status.LastCall.Parameter;

  case Status.LastCall.CallType of

    // Desired access: <mask>
    lcOpenCall:
      if Assigned(Status.LastCall.AccessMaskType) then
      begin
        AType := RttixTypeInfo(Status.LastCall.AccessMaskType);

        Result := Result + #$D#$A'Desired ' +
          RtlxStringOrDefault(AType.FriendlyName, 'object') + ' access: ' +
          RttixFormatText(AType, Status.LastCall.AccessMask);
      end;

    // Information class: <name>
    lcQuerySetCall:
      if Assigned(Status.LastCall.InfoClassType) then
      begin
        AType := RttixTypeInfo(Status.LastCall.InfoClassType,
          PLiteRttiTypeInfo(TypeInfo(PreserveCase)).Attributes);

        Result := Result + #$D#$A'Information class: ' + RttixFormatText(AType,
          Status.LastCall.InfoClass);
      end;
  end;

  // Expected <type> access: <mask>
  if (Status.Status = STATUS_ACCESS_DENIED) or (Status.IsWin32 and
    (Status.Win32Error = ERROR_ACCESS_DENIED)) then
    for i := 0 to High(Status.LastCall.ExpectedAccess) do
      if Assigned(Status.LastCall.ExpectedAccess[i].AccessMaskType) then
      begin
        AType := RttixTypeInfo(Status.LastCall.ExpectedAccess[i].AccessMaskType);

        Result := Result + #$D#$A'Expected ' + RtlxStringOrDefault(
          AType.FriendlyName, 'object') + ' access: ' +
          RttixFormatText(AType, Status.LastCall.ExpectedAccess[i].AccessMask);
      end;

  // Result: <STATUS_*/ERROR_*>
  Result := Result + #$D#$A'Result: ' + Status.Name;

  // <textual description>
  Result := Result + #$D#$A#$D#$A + Status.Description;

  // <privilege name>
  if (Status.Status = STATUS_PRIVILEGE_NOT_HELD) or
    (Status.IsWin32 and (Status.Win32Error = ERROR_PRIVILEGE_NOT_HELD)) then
    if (Status.LastCall.ExpectedPrivilege >= SE_CREATE_TOKEN_PRIVILEGE) and
      (Status.LastCall.ExpectedPrivilege <= High(TSeWellKnownPrivilege)) then
    begin
      AType := RttixTypeInfo(TypeInfo(TSeWellKnownPrivilege));
      RtlxSuffixStripString('.', Result, True);

      Result := Result + ': "' + RttixFormatText(AType,
        Status.LastCall.ExpectedPrivilege) + '"';
    end;

  // Stack trace
  if DisplayStackTraces and (Length(Status.LastCall.StackTrace) > 0) then
    Result := Result + #$D#$A#$D#$A'Stack Trace:'#$D#$A + SymxFormatStackTrace(
      Status.LastCall.StackTrace);
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

  Content := UiLibVerboseStatusMessage(Status);
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
