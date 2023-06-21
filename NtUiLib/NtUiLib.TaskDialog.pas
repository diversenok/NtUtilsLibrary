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

// Show a Task Dialog of fallback to a Message Box
function UsrxShowTaskDialog(
  [opt] OwnerWindow: THwnd;
  const Title: String;
  const MainInstruction: String;
  const Content: String;
  Icon: TDialogIcon = diInfo;
  Buttons: TDialogButtons = dbOk;
  DefaultButton: TMessageResponse = IDNONE
): TMessageResponse;

// Show a message to the interactive user
function WsxInteractiveShowMessageBox(
  out Response: TMessageResponse;
  const Title: String;
  const Content: String;
  Icon: TDialogIcon = diInfo;
  Buttons: TDialogButtons = dbOk;
  TimeoutSeconds: Cardinal = 0
): TNtxStatus;

implementation

uses
  Ntapi.WinNt, Ntapi.winsta, Ntapi.CommCtrls, NtUtils.Ldr,
  NtUtils.Errors, NtUtils.WinStation;

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

procedure UsrxpAdjustResonce(
  var Responce: TMessageResponse;
  Buttons: TDialogButtons
);
begin
  case Buttons of
    dbYesIgnore:
      case Responce of
        IDOK:     Responce := IDYES;
        IDCANCEL: Responce := IDIGNORE;
      end;

    dbYesAbortIgnore:
      case Responce of
        IDNO:     Responce := IDABORT;
        IDCANCEL: Responce := IDIGNORE;
      end;
  end;
end;

function UsrxShowTaskDialog;
var
  DlgConfig: TTaskDialogConfig;
  CustomButtons: array [0..2] of TTaskDialogButton;
begin
  // Task Dialog might not be available due to missing manifest or low level of
  // privileges. Use it when available; otherwise, fall back to a Message Box.

  if LdrxCheckDelayedImport(delayed_comctl32,
    delayed_TaskDialogIndirect).IsSuccess then
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

    // Show the dialog
    if TaskDialogIndirect(DlgConfig, @Result, nil, nil).IsSuccess then
      Exit;
  end;

  // Show the message
  Result := MessageBoxW(OwnerWindow, PWideChar(MainInstruction + #$D#$A#$D#$A +
    Content), PWideChar(Title), UsrxpMakeMessageStyle(Icon, Buttons));

  // Adjust the response for replaced buttons
  UsrxpAdjustResonce(Result, Buttons);
end;

function WsxInteractiveShowMessageBox;
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

  UsrxpAdjustResonce(Response, Buttons);
end;

end.
