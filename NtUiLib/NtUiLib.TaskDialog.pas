unit NtUiLib.TaskDialog;

{
  This module provides support for showing Task Dialogs or Message Boxes.
  NOTE: some features require a manifest with enabled runtime themes.
}

interface

uses
  Ntapi.WinUser, DelphiApi.Reflection, NtUtils;

const
  IDNONE = TMessageResponse.IDNONE;
  IDOK = TMessageResponse.IDOK;
  IDCANCEL = TMessageResponse.IDCANCEL;
  IDABORT = TMessageResponse.IDABORT;
  IDRETRY = TMessageResponse.IDRETRY;
  IDIGNORE = TMessageResponse.IDIGNORE;
  IDYES = TMessageResponse.IDYES;
  IDNO = TMessageResponse.IDNO;
  IDTIMEOUT = TMessageResponse.IDTIMEOUT;

type
  [NamingStyle(nsCamelCase, 'di')]
  TDialogIcon = (
    diNone,
    diError,
    diWarning,
    diInfo,
    diShield,
    diConfirmation,
    diApplication
  );

  [NamingStyle(nsCamelCase, 'db')]
  TDialogButtons = (
    dbOk,
    dbOkCancel,
    dbYesNo,
    dbYesNoCancel,
    dbRetryCancel,
    dbAbortRetryIgnore,
    dbYesIgnore,
    dbYesAbortIgnore
  );

// Show a Task Dialog or fallback to a Message Box and check for errors
function UsrxShowTaskDialogWithStatus(
  out Response: TMessageResponse;
  [opt] OwnerWindow: THwnd;
  const Title: String;
  const MainInstruction: String;
  const Content: String;
  Icon: TDialogIcon = diInfo;
  Buttons: TDialogButtons = dbOk;
  DefaultButton: TMessageResponse = IDNONE
): TNtxStatus;

// Show a Task Dialog or fallback to a Message Box
function UsrxShowTaskDialog(
  [opt] OwnerWindow: THwnd;
  const Title: String;
  const MainInstruction: String;
  const Content: String;
  Icon: TDialogIcon = diInfo;
  Buttons: TDialogButtons = dbOk;
  DefaultButton: TMessageResponse = IDNONE
): TMessageResponse;

// Show a cross-session message to the interactive user and check for errors
function WsxShowMessageInteractiveWithStatus(
  out Response: TMessageResponse;
  const Title: String;
  const Content: String;
  Icon: TDialogIcon = diInfo;
  Buttons: TDialogButtons = dbOk;
  TimeoutSeconds: Cardinal = 0
): TNtxStatus;

// Show a cross-session message to the interactive user
function WsxShowMessageInteractive(
  const Title: String;
  const Content: String;
  Icon: TDialogIcon = diInfo;
  Buttons: TDialogButtons = dbOk;
  TimeoutSeconds: Cardinal = 0
): TMessageResponse;

// Show the best available dialog to the interactive user and check for errors
function UsrxShowMessageAlwaysInteractiveWithStatus(
  out Response: TMessageResponse;
  const Title: String;
  const MainInstruction: String;
  const Content: String;
  Icon: TDialogIcon = diInfo;
  Buttons: TDialogButtons = dbOk;
  DefaultButton: TMessageResponse = IDNONE;
  TimeoutSeconds: Cardinal = 0
): TNtxStatus;

// Show the best available dialog to the interactive user
function UsrxShowMessageAlwaysInteractive(
  const Title: String;
  const MainInstruction: String;
  const Content: String;
  Icon: TDialogIcon = diInfo;
  Buttons: TDialogButtons = dbOk;
  DefaultButton: TMessageResponse = IDNONE;
  TimeoutSeconds: Cardinal = 0
): TMessageResponse;

implementation

uses
  Ntapi.WinNt, Ntapi.winsta, Ntapi.CommCtrls, NtUtils.Ldr,
  NtUtils.Errors, NtUtils.WinStation, NtUtils.WinUser;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function UsrxpMakeMessageStyle(
  Icon: TDialogIcon;
  Buttons: TDialogButtons
): TMessageStyle;
begin
  Result := MB_TASKMODAL;

  case Icon of
    diError:   Result := Result or MB_ICONERROR;
    diWarning: Result := Result or MB_ICONWARNING;
    diInfo:    Result := Result or MB_ICONINFORMATION;
    diConfirmation : Result := Result or MB_ICONINFORMATION;
  end;

  // Use the logically closest collection of buttons from the available options
  case Buttons of
    dbOk:               Result := Result or MB_OK;
    dbOkCancel:         Result := Result or MB_OKCANCEL;
    dbYesNo:            Result := Result or MB_YESNO;
    dbYesNoCancel:      Result := Result or MB_YESNOCANCEL;
    dbRetryCancel:      Result := Result or MB_RETRYCANCEL;
    dbAbortRetryIgnore: Result := Result or MB_ABORTRETRYIGNORE;
    dbYesIgnore:        Result := Result or MB_OKCANCEL;
    dbYesAbortIgnore:   Result := Result or MB_YESNOCANCEL;
  end;
end;

procedure UsrxpAdjustResponse(
  var Response: TMessageResponse;
  Buttons: TDialogButtons
);
begin
  case Buttons of
    dbYesIgnore:
      case Response of
        IDOK:     Response := IDYES;
        IDCANCEL: Response := IDIGNORE;
      end;

    dbYesAbortIgnore:
      case Response of
        IDNO:     Response := IDABORT;
        IDCANCEL: Response := IDIGNORE;
      end;
  end;
end;

function UsrxShowTaskDialogWithStatus;
var
  DlgConfig: TTaskDialogConfig;
  CustomButtons: array [0..2] of TTaskDialogButton;
begin
  // Task Dialog might not be available due to missing manifest or low level of
  // privileges. Use it when available; otherwise, fall back to a Message Box.

  if LdrxCheckDelayedImport(delayed_TaskDialogIndirect).IsSuccess then
  begin
    DlgConfig := Default(TTaskDialogConfig);
    DlgConfig.cbSize := SizeOf(DlgConfig);
    DlgConfig.Flags := TDF_ALLOW_DIALOG_CANCELLATION;
    DlgConfig.Owner := OwnerWindow;
    DlgConfig.WindowTitle := PWideChar(Title);
    DlgConfig.MainInstruction := PWideChar(MainInstruction);
    DlgConfig.Content := PWideChar(Content);
    DlgConfig.nDefaultButton := DefaultButton;
    DlgConfig.cButtons := 0;

    case Buttons of
      dbOk:
        DlgConfig.CommonButtons := TDCBF_OK_BUTTON;

      dbOkCancel:
        DlgConfig.CommonButtons := TDCBF_OK_BUTTON or TDCBF_CANCEL_BUTTON;

      dbYesNo:
        DlgConfig.CommonButtons := TDCBF_YES_BUTTON or TDCBF_NO_BUTTON;

      dbYesNoCancel:
        DlgConfig.CommonButtons := TDCBF_YES_BUTTON or TDCBF_NO_BUTTON or
          TDCBF_CANCEL_BUTTON;

      dbRetryCancel:
        DlgConfig.CommonButtons := TDCBF_RETRY_BUTTON or TDCBF_CANCEL_BUTTON;

      dbAbortRetryIgnore:
      begin
        CustomButtons[DlgConfig.cButtons].ButtonID := IDABORT;
        CustomButtons[DlgConfig.cButtons].ButtonText := '&Abort';
        Inc(DlgConfig.cButtons);

        CustomButtons[DlgConfig.cButtons].ButtonID := IDRETRY;
        CustomButtons[DlgConfig.cButtons].ButtonText := '&Retry';
        Inc(DlgConfig.cButtons);

        CustomButtons[DlgConfig.cButtons].ButtonID := IDIGNORE;
        CustomButtons[DlgConfig.cButtons].ButtonText := '&Ignore';
        Inc(DlgConfig.cButtons);
      end;

      dbYesIgnore:
      begin
        CustomButtons[DlgConfig.cButtons].ButtonID := IDYES;
        CustomButtons[DlgConfig.cButtons].ButtonText := '&Yes';
        Inc(DlgConfig.cButtons);

        CustomButtons[DlgConfig.cButtons].ButtonID := IDIGNORE;
        CustomButtons[DlgConfig.cButtons].ButtonText := '&Ignore';
        Inc(DlgConfig.cButtons);
      end;

      dbYesAbortIgnore:
      begin
        CustomButtons[DlgConfig.cButtons].ButtonID := IDYES;
        CustomButtons[DlgConfig.cButtons].ButtonText := '&Yes';
        Inc(DlgConfig.cButtons);

        CustomButtons[DlgConfig.cButtons].ButtonID := IDABORT;
        CustomButtons[DlgConfig.cButtons].ButtonText := '&Abort';
        Inc(DlgConfig.cButtons);

        CustomButtons[DlgConfig.cButtons].ButtonID := IDIGNORE;
        CustomButtons[DlgConfig.cButtons].ButtonText := '&Ignore';
        Inc(DlgConfig.cButtons);
      end;
    end;

    if DlgConfig.cButtons > 0 then
        DlgConfig.Buttons := Pointer(@CustomButtons[0]);

    case Icon of
      diError:   DlgConfig.MainIcon.pszIcon := TD_ERROR_ICON;
      diWarning: DlgConfig.MainIcon.pszIcon := TD_WARNING_ICON;
      diInfo:    DlgConfig.MainIcon.pszIcon := TD_INFORMATION_ICON;
      diShield:  DlgConfig.MainIcon.pszIcon := TD_SHIELD_ICON;
      diConfirmation: DlgConfig.MainIcon.pszIcon := IDI_QUESTION;
      diApplication:  DlgConfig.MainIcon.pszIcon := IDI_APPLICATION;
    end;

    // Show the task dialog
    if TaskDialogIndirect(DlgConfig, @Response, nil, nil).IsSuccess then
      Exit;
  end;

  // Cannot display the task dialog; load the message box
  Result := LdrxCheckDelayedImport(delayed_MessageBoxW);

  if not Result.IsSuccess then
    Exit;

  // Show the message box
  Result.Location := 'MessageBoxW';
  Response := MessageBoxW(OwnerWindow, PWideChar(MainInstruction + #$D#$A#$D#$A
    + Content), PWideChar(Title), UsrxpMakeMessageStyle(Icon, Buttons));
  Result.Win32Result := Response <> IDNONE;

  if not Result.IsSuccess then
    Exit;

  // Adjust the response for replaced buttons
  UsrxpAdjustResponse(Response, Buttons);
end;

function UsrxShowTaskDialog;
begin
  if not UsrxShowTaskDialogWithStatus(Result, OwnerWindow, Title,
    MainInstruction, Content, Icon, Buttons, DefaultButton).IsSuccess then
    Result := IDNONE;
end;

function WsxShowMessageInteractiveWithStatus;
var
  InteractiveSession: TSessionId;
begin
  Result := WsxFindActiveSessionId(InteractiveSession);

  if not Result.IsSuccess then
    Exit;

  Result := WsxSendMessage(InteractiveSession, Title, Content,
    UsrxpMakeMessageStyle(Icon, Buttons), TimeoutSeconds, True, @Response);

  if not Result.IsSuccess then
    Exit;

  UsrxpAdjustResponse(Response, Buttons);
end;

function WsxShowMessageInteractive;
begin
  if not WsxShowMessageInteractiveWithStatus(Result, Title, Content, Icon,
    Buttons, TimeoutSeconds).IsSuccess then
    Result := IDNONE;
end;

function UsrxShowMessageAlwaysInteractiveWithStatus;
var
  IsInteractive: LongBool;
  WindowModeReverter: IAutoReleasable;
begin
  if UsrxObject.Query(UsrxCurrentDesktop, UOI_IO, IsInteractive).IsSuccess and
    IsInteractive then
  begin
    // Make sure the window will be drawn as visible
    WindowModeReverter := UsrxOverridePebWindowMode(TShowMode32.SW_SHOW_NORMAL);

    // Show the message on the current desktop
    Result := UsrxShowTaskDialogWithStatus(Response, 0, Title, MainInstruction,
      Content, Icon, Buttons, DefaultButton)
  end
  else
    // Ask CSRSS to show the message in the interactive session
    Result := WsxShowMessageInteractiveWithStatus(Response, Title,
      MainInstruction + #$D#$A#$D#$A + Content, Icon, Buttons, TimeoutSeconds);
end;

function UsrxShowMessageAlwaysInteractive;
begin
  if not UsrxShowMessageAlwaysInteractiveWithStatus(Result, Title, MainInstruction,
    Content, Icon, Buttons, DefaultButton, TimeoutSeconds).IsSuccess then
    Result := IDNONE;
end;

end.
