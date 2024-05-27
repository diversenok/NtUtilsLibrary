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

// Construct a verbose report about an error
function NtxVerboseFormatStatusMessage(const Status: TNtxStatus): String;

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
  Ntapi.ntseapi, Ntapi.ntstatus, Ntapi.WinError, DelphiApi.Reflection,
  NtUtils.SysUtils, NtUiLib.Errors, NtUiLib.TaskDialog, NtUiLib.Exceptions,
  DelphiUiLib.Reflection, DelphiUiLib.Reflection.Strings, System.SysUtils,
  System.TypInfo, System.Rtti;

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

{ Formatting }

function ProvidesPrivilege(const LastCall: TLastCallInfo): Boolean;
begin
  Result := (LastCall.ExpectedPrivilege >= SE_CREATE_TOKEN_PRIVILEGE) and
    (LastCall.ExpectedPrivilege <= High(TSeWellKnownPrivilege));
end;

function GetFriendlyName(AType: Pointer): String;
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  a: TCustomAttribute;
begin
  RttiContext := TRttiContext.Create;
  RttiType := RttiContext.GetType(AType);

  for a in RttiType.GetAttributes do
    if a is FriendlyNameAttribute then
      Exit(FriendlyNameAttribute(a).Name);

  Result := 'object';
end;

function NtxVerboseFormatStatusMessage;
var
  i: Integer;
begin
  // LastCall: <function name>
  Result := 'Last call: ' + RtlxStringOrDefault(Status.Location, '<unknown>');

  if Status.LastCall.Parameter <> '' then
    Result := Result +  #$D#$A'Parameter: ' + Status.LastCall.Parameter;

  case Status.LastCall.CallType of
    lcOpenCall:
      // Desired access: <mask>
      Result := Result + #$D#$A'Desired ' +
        GetFriendlyName(Status.LastCall.AccessMaskType) + ' access: ' +
        RepresentType(Status.LastCall.AccessMaskType,
        Status.LastCall.AccessMask).Text;

    lcQuerySetCall:
      // Information class: <name>
      Result := Result + #$D#$A'Information class: ' + GetEnumName(
        Status.LastCall.InfoClassType, Integer(Status.LastCall.InfoClass));
  end;

  // Expected <type> access: <mask>
  if Status.Status = STATUS_ACCESS_DENIED then
    for i := 0 to High(Status.LastCall.ExpectedAccess) do
      with Status.LastCall.ExpectedAccess[i] do
        Result := Result + #$D#$A'Expected ' +
          GetFriendlyName(AccessMaskType) + ' access: ' +
          RepresentType(AccessMaskType, AccessMask).Text;

  // Result: <STATUS_*/ERROR_*>
  Result := Result + #$D#$A'Result: ' + Status.Name;

  // <textual description>
  Result := Result + #$D#$A#$D#$A + Status.Description;

  // <privilege name>
  if ((Status.Status = STATUS_PRIVILEGE_NOT_HELD) or
    (Status.IsWin32 and (Status.Win32Error = ERROR_PRIVILEGE_NOT_HELD))) and
    ProvidesPrivilege(Status.LastCall) then
  begin
    RtlxSuffixStripString('.', Result, True);
    Result := Result + ': "' + PrettifySnakeCaseEnum(
      TypeInfo(TSeWellKnownPrivilege),
      Integer(Status.LastCall.ExpectedPrivilege), 'SE_') + '"';
  end;
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
    if Assigned(Exception.GetStackInfoStringProc) then
      Content := Content + #$D#$A#$D#$A + 'Stack Trace:'#$D#$A +
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

initialization
  NtxVerboseStatusMessageFormatter := NtxVerboseFormatStatusMessage;
end.
