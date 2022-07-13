unit Ntapi.CommCtrls;

interface

{$WARN SYMBOL_PLATFORM OFF}
{$MINENUMSIZE 4}

uses
  Ntapi.WinNt, Ntapi.WinUser, DelphiApi.Reflection;

const
  comctl32 = 'comctl32.dll';

  // SDK::Commctrl.h - task dialog flags
  TDF_ENABLE_HYPERLINKS = $0001;
  TDF_USE_HICON_MAIN = $0002;
  TDF_USE_HICON_FOOTER = $0004;
  TDF_ALLOW_DIALOG_CANCELLATION = $0008;
  TDF_USE_COMMAND_LINKS = $0010;
  TDF_USE_COMMAND_LINKS_NO_ICON = $0020;
  TDF_EXPAND_FOOTER_AREA = $0040;
  TDF_EXPANDED_BY_DEFAULT = $0080;
  TDF_VERIFICATION_FLAG_CHECKED = $0100;
  TDF_SHOW_PROGRESS_BAR = $0200;
  TDF_SHOW_MARQUEE_PROGRESS_BAR = $0400;
  TDF_CALLBACK_TIMER = $0800;
  TDF_POSITION_RELATIVE_TO_WINDOW = $1000;
  TDF_RTL_LAYOUT = $2000;
  TDF_NO_DEFAULT_RADIO_BUTTON = $4000;
  TDF_CAN_BE_MINIMIZED = $8000;
  TDF_NO_SET_FOREGROUND = $00010000; // Win 8+
  TDF_SIZE_TO_CONTENT = $01000000;

  // SDK::Commctrl.h - known icons
  TD_WARNING_ICON = MAKEINTRESOURCE(Word(-1));
  TD_ERROR_ICON = MAKEINTRESOURCE(Word(-2));
  TD_INFORMATION_ICON = MAKEINTRESOURCE(Word(-3));
  TD_SHIELD_ICON = MAKEINTRESOURCE(Word(-4));

  // SDK::Commctrl.h - common button flags
  TDCBF_OK_BUTTON = $0001;
  TDCBF_YES_BUTTON = $0002;
  TDCBF_NO_BUTTON = $0004;
  TDCBF_CANCEL_BUTTON = $0008;
  TDCBF_RETRY_BUTTON = $0010;
  TDCBF_CLOSE_BUTTON = $0020;

type
  [SDKName('TASKDIALOG_FLAGS')]
  [FlagName(TDF_ENABLE_HYPERLINKS, 'Enable Hyperlinks')]
  [FlagName(TDF_USE_HICON_MAIN, 'Use HICON Main')]
  [FlagName(TDF_USE_HICON_FOOTER, 'Use HICON Footer')]
  [FlagName(TDF_ALLOW_DIALOG_CANCELLATION, 'Allow Dialog Cancellation')]
  [FlagName(TDF_USE_COMMAND_LINKS, 'Use Command Links')]
  [FlagName(TDF_USE_COMMAND_LINKS_NO_ICON, 'Use Command Links No Icon')]
  [FlagName(TDF_EXPAND_FOOTER_AREA, 'Expand Footer Area')]
  [FlagName(TDF_EXPANDED_BY_DEFAULT, 'Expanded By Default')]
  [FlagName(TDF_VERIFICATION_FLAG_CHECKED, 'Verification Flag Checked')]
  [FlagName(TDF_SHOW_PROGRESS_BAR, 'Show Progress Bar')]
  [FlagName(TDF_SHOW_MARQUEE_PROGRESS_BAR, 'Show Marquee Progress Bar')]
  [FlagName(TDF_CALLBACK_TIMER, 'Callback Timer')]
  [FlagName(TDF_POSITION_RELATIVE_TO_WINDOW, 'Position Relative To Window')]
  [FlagName(TDF_RTL_LAYOUT, 'RTL Layout')]
  [FlagName(TDF_NO_DEFAULT_RADIO_BUTTON, 'No Default Radio Button')]
  [FlagName(TDF_CAN_BE_MINIMIZED, 'Can Be Minimized')]
  [FlagName(TDF_NO_SET_FOREGROUND, 'No Set Forground')]
  [FlagName(TDF_SIZE_TO_CONTENT, 'Size To Content')]
  TTaskDialogFlags = type Cardinal;

  [SDKName('TASKDIALOG_COMMON_BUTTON_FLAGS')]
  [FlagName(TDCBF_OK_BUTTON, 'OK')]
  [FlagName(TDCBF_YES_BUTTON, 'Yes')]
  [FlagName(TDCBF_NO_BUTTON, 'No')]
  [FlagName(TDCBF_CANCEL_BUTTON, 'Cancel')]
  [FlagName(TDCBF_RETRY_BUTTON, 'Retry')]
  [FlagName(TDCBF_CLOSE_BUTTON, 'Close')]
  TTaskDialogCommonButtonFlags = type Cardinal;

  HICON = type THwnd;

  // (extracted union)
  TTaskDialogIcon = record
  case Boolean of
    False: (hIcon: HICON);
    True: (pszIcon: PWideChar)
  end;

  // SDK::Commctrl.h
  [SDKName('TASKDIALOG_BUTTON')]
  TTaskDialogButton = packed record
    ButtonID: TMessageResponse;
    ButtonText: PWideChar;
  end;

  // SDK::Commctrl.h
  [SDKName('PFTASKDIALOGCALLBACK')]
  TTaskDialogCallback = function (
    [in] hwnd: THwnd;
    [in] msg: Cardinal;
    [in] wParam: WPARAM;
    [in] lParam: LPARAM;
    [in, opt] lpRefData: UIntPtr
  ): HResult; stdcall;

  // SDK::Commctrl.h
  [SDKName('TASKDIALOGCONFIG')]
  TTaskDialogConfig = packed record
    [Bytes, Unlisted] cbSize: Cardinal;
    Owner: THwnd;
    hInstance: HINST;
    Flags: TTaskDialogFlags;
    CommonButtons: TTaskDialogCommonButtonFlags;
    WindowTitle: PWideChar;
    MainIcon: TTaskDialogIcon; // Can be TD_*
    MainInstruction: PWideChar;
    Content: PWideChar;
    [Counter(ctElements)] cButtons: Cardinal;
    Buttons: ^TAnysizeArray<TTaskDialogButton>;
    nDefaultButton: TMessageResponse;
    [Counter(ctElements)] cRadioButtons: Cardinal;
    RadioButtons: ^TAnysizeArray<TTaskDialogButton>;
    nDefaultRadioButton: TMessageResponse;
    VerificationText: PWideChar;
    ExpandedInformation: PWideChar;
    ExpandedControlText: PWideChar;
    CollapsedControlText: PWideChar;
    FooterIcon: TTaskDialogIcon;
    Footer: PWideChar;
    Callback: TTaskDialogCallback;
    CallbackData: UIntPtr;
    Width: Cardinal;
  end;
  PTaskDialogConfig = ^TTaskDialogConfig;

// SDK::Commctrl.h
function TaskDialogIndirect(
  [in] const TaskConfig: TTaskDialogConfig;
  [out, opt] pnButton: PMessageResponse;
  [out, opt] pnRadioButton: PMessageResponse;
  [out, opt] pfVerificationFlagChecked: PLongBool
): HRESULT; stdcall; external comctl32 delayed;

implementation

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

end.
