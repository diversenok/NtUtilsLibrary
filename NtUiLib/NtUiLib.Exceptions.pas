unit NtUiLib.Exceptions;

interface

uses
  Winapi.Windows, System.SysUtils, NtUtils.Exceptions;

var
  BUG_TITLE: String = 'This is definitely a bug...';
  BUG_MESSAGE: String = 'If you known how to reproduce this error please ' +
    'help us by opening an issue on our project''s page.';

type
  // A callback function that might suggest solutions for specific problems
  TSuggestor = function (const NtxStatus: TNtxStatus): String;

// Register a suggestion callback
procedure RegisterSuggestions(Callback: TSuggestor);

// Show a modal error message to a user
procedure ShowNtxStatus(ParentWnd: HWND; const NtxStatus: TNtxStatus);
procedure ShowNtxException(ParentWnd: HWND; E: Exception);

implementation

uses
  Winapi.CommCtrl, Ntapi.ntdef, Ntapi.ntstatus, NtUtils.ErrorMsg,
  NtUtils.Exceptions.Report;

var
  Suggestors: array of TSuggestor;

procedure RegisterSuggestions(Callback: TSuggestor);
begin
  SetLength(Suggestors, Length(Suggestors) + 1);
  Suggestors[High(Suggestors)] := Callback;
end;

function CollectSuggestions(const NtxStatus: TNtxStatus): String;
var
  Suggestions: array of String;
  i: Integer;
begin
  for i := 0 to High(Suggestors) do
  begin
    Result := Suggestors[i](NtxStatus);

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

procedure InitDlg(var Dlg: TASKDIALOGCONFIG; Parent: HWND);
begin
  FillChar(Dlg, SizeOf(Dlg), 0);
  Dlg.cbSize := SizeOf(Dlg);
  Dlg.pszMainIcon := TD_ERROR_ICON;
  Dlg.dwFlags := TDF_ALLOW_DIALOG_CANCELLATION;
  Dlg.hwndParent := Parent;
  Dlg.pszWindowTitle := 'Error';
end;

procedure ShowDlg(const Dlg: TASKDIALOGCONFIG);
begin
  // Under some circumstances (low privileges; absence of a manifest, etc.)
  // TaskDialog might be unavailable, fall back to a MessageBox in this case.
  if not Succeeded(TaskDialogIndirect(Dlg, nil, nil, nil)) then
    MessageBoxW(Dlg.hwndParent, Dlg.pszContent, Dlg.pszWindowTitle,
      MB_OK or MB_ICONERROR);
end;

procedure ShowNtxStatus(ParentWnd: HWND; const NtxStatus: TNtxStatus);
var
  Dlg: TASKDIALOGCONFIG;
begin
  InitDlg(Dlg, ParentWnd);

  if not NT_ERROR(NtxStatus.Status) then
    Dlg.pszMainIcon := TD_WARNING_ICON;

  // Make a pretty header
  Dlg.pszMainInstruction := PWideChar(NtxStatusDescription(NtxStatus.Status));

  if Dlg.pszMainInstruction = '' then
    Dlg.pszMainInstruction := 'System error';

  // Use a verbose status report + suggestions
  Dlg.pszContent := PWideChar(NtxVerboseStatusMessage(NtxStatus) +
    CollectSuggestions(NtxStatus));

  ShowDlg(Dlg);
end;

procedure ShowNtxException(ParentWnd: HWND; E: Exception);
var
  Dlg: TASKDIALOGCONFIG;
begin
  if E is ENtError then
    // Extract a TNtxStatus from an exception
    ShowNtxStatus(ParentWnd, ENtError(E).ToNtxStarus)
  else
  begin
    InitDlg(Dlg, ParentWnd);

    if (E is EAccessViolation) or (E is EInvalidPointer) or
      (E is EAssertionFailed) or (E is EArgumentNilException) then
    begin
      Dlg.pszMainInstruction := PWideChar(BUG_TITLE);
      Dlg.pszContent := PWideChar(E.Message + #$D#$A#$D#$A + BUG_MESSAGE);
    end
    else if E is EConvertError then
    begin
      Dlg.pszMainInstruction := 'Conversion error';
      Dlg.pszContent := PWideChar(E.Message);
    end
    else
    begin
      Dlg.pszMainInstruction := PWideChar(E.ClassName);
      Dlg.pszContent := PWideChar(E.Message);
    end;

    ShowDlg(Dlg);
  end;
end;

end.
