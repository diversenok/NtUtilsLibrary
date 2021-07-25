unit NtUiLib.Errors;

{
  This module adds support for representing error codes as constant names,
  short summaries, and long descriptions.
}

interface

{$R NtUiLib.Errors.res}

uses
  Ntapi.ntdef, NtUtils;

type
  // A prototype for a custom callback for raising exceptions
  TNtxExceptionRaiser = procedure (const Status: TNtxStatus);

  TNtxStatusHelper = record helper for TNtxStatus
    // Raise an unsuccessful status as an exception. When using, consider
    // including NtUiLib.Exceptions for better integration with Delphi.
    procedure RaiseOnError;

    // Provide textual representation of the error
    function Name: String;
    function Description: String;
    function Summary: String;
    function ToString: String;
  end;

var
  // A custom callback for raising exceptions (provided by NtUiLib.Exceptions)
  NtxExceptionRaiser: TNtxExceptionRaiser;

// Extract a message description from resources of a module
function RtlxFindMessage(
  [in] ModuleBase: Pointer;
  MessageId: Cardinal;
  out Msg: String
): TNtxStatus;

// Find a constant name (like STATUS_ACCESS_DENIED) for an error
function RtlxNtStatusName(Status: NTSTATUS): String;

// Find a short failure description (like "Access Denied") for an error
function RtlxNtStatusSummary(Status: NTSTATUS): String;

// Find a description for an NTSTATUS, HRESULT, or Win32 error
function RtlxNtStatusMessage(Status: NTSTATUS): String;

// Raise an extenal exception (when System.SysUtils is not available)
procedure RtlxRaiseException(
  Status: NTSTATUS;
  [in, opt] Address: Pointer
);

implementation

uses
  Winapi.WinNt, Ntapi.ntrtl, Winapi.WinError, Ntapi.ntldr, NtUtils.Ldr,
  NtUtils.SysUtils, NtUtils.Errors, DelphiUiLib.Strings;

function RtlxFindMessage;
var
  MessageEntry: PMessageResourceEntry;
  StartIndex, EndIndex: Integer;
begin
  // Perhaps, we can later implement the same language selection logic as
  // FormatMessage, i.e:
  //  1. Neutral => MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL)
  //  2. Current => NtCurrentTeb.CurrentLocale
  //  3. User    => MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT)
  //  4. System  => MAKELANGID(LANG_NEUTRAL, SUBLANG_SYS_DEFAULT)
  //  5. English => MAKELANGID(LANG_ENGLISH, SUBLANG_DEFAULT)

  Result.Location := 'RtlFindMessage';
  Result.Status := RtlFindMessage(ModuleBase, RT_MESSAGETABLE, 0, MessageId,
    MessageEntry);

  if not Result.IsSuccess then
    Exit;

  if LongBool(MessageEntry.Flags and MESSAGE_RESOURCE_UNICODE) then
    Msg := String(PWideChar(@MessageEntry.Text))
  else if LongBool(MessageEntry.Flags and MESSAGE_RESOURCE_UTF8) then
    Msg := String(UTF8String(PAnsiChar(@MessageEntry.Text)))
  else
    Msg := String(PAnsiChar(@MessageEntry.Text));

  StartIndex := Low(Msg);

  // Skip leading summary in curly brackets for messages that look like:
  //   {Summary}
  //   Message description.
  if (Length(Msg) > 0) and (Msg[Low(Msg)] = '{') then
    StartIndex := Pos('}'#$D#$A, Msg) + 3;

  // Remove trailing new lines
  EndIndex := High(Msg);
  while (EndIndex >= Low(Msg)) and (AnsiChar(Msg[EndIndex]) in [#$D, #$A]) do
    Dec(EndIndex);

  Msg := Copy(Msg, StartIndex, EndIndex - StartIndex + 1);
end;

function RtlxNtStatusName;
begin
  // Use embedded resource to locate the constant name
  if not RtlxFindMessage(Pointer(@ImageBase), Status.Canonicalize,
    Result).IsSuccess then
  begin
    // No name available. Prepare a numeric value.
    if Status.IsWin32Error then
      Result := RtlxIntToStr(Status.ToWin32Error) + ' [Win32]'
    else if Status.IsHResult then
      Result := RtlxIntToStr(Cardinal(Status.ToHResult), 16) + ' [HRESULT]'
    else
      Result :=  RtlxIntToStr(Status, 16) + ' [NTSTATUS]';
  end;
end;

function RtlxNtStatusSummary;
const
  KnownPrefixes: array [0 .. 19] of String = ('ERROR_', 'STATUS_', 'CO_E_',
    'RPC_NT_', 'RPC_S_', 'RPC_E_', 'E_', 'RPC_X_', 'OLE_E_', 'DISP_E_', 'MK_E_',
    'DBG_', 'RO_E_', 'WER_E_', 'EPT_S_', 'EPT_NT_', 'OR_', 'MEM_E_', 'S_',
    'CONTEXT_E_');
var
  Prefix: String;
begin
  // Use embedded resource to locate the constant name
  if not RtlxFindMessage(Pointer(@ImageBase), Status.Canonicalize,
    Result).IsSuccess then
    Exit('System Error');

  // Skip known prefixes
  for Prefix in KnownPrefixes do
    if StringStartsWith(Result, Prefix) then
    begin
      Result := Copy(Result, Succ(Length(Prefix)), Length(Result));
      Break;
    end;

  // Convert names from "ACCESS_DENIED" to "Access Denied"
  Result := PrettifySnakeCase(Result);
end;

function RtlxNtStatusMessage;
var
  hKernel32: Pointer;
begin
  // Messages for Win32 errors and HRESULT codes are located in kernel32
  if Status.IsWin32Error or Status.IsHResult then
  begin
    if not LdrxGetDllHandle(kernel32, hKernel32).IsSuccess or
      not RtlxFindMessage(hKernel32, Status.ToWin32Error, Result).IsSuccess then
      Result := '';
  end

  // For native NTSTATUS vaules, use ntdll
  else if not RtlxFindMessage(hNtdll.DllBase, Status, Result).IsSuccess then
    Result := '';

  if Result = '' then
    Result := '<No description available>';
end;

procedure RtlxRaiseException;
var
  ExceptionRecord: TExceptionRecord;
begin
  FillChar(ExceptionRecord, SizeOf(ExceptionRecord), 0);
  ExceptionRecord.ExceptionCode := Status;
  ExceptionRecord.ExceptionFlags := EXCEPTION_NONCONTINUABLE;
  ExceptionRecord.ExceptionAddress := Address;

  RtlRaiseException(ExceptionRecord);
end;

{ TNtxStatusHelper }

function TNtxStatusHelper.Description;
begin
  Result := RtlxNtStatusMessage(Status);
end;

function TNtxStatusHelper.Name;
begin
  Result := RtlxNtStatusName(Status);
end;

procedure TNtxStatusHelper.RaiseOnError;
begin
  if IsSuccess then
    Exit;

  if Assigned(NtxExceptionRaiser) then
    NtxExceptionRaiser(Self)
  else
    RtlxRaiseException(Status, ReturnAddress);
end;

function TNtxStatusHelper.Summary;
begin
  Result := RtlxNtStatusSummary(Status);
end;

function TNtxStatusHelper.ToString;
begin
  Result := Location;

  if Result = '' then
    Result := 'Function';

  Result := Result + ' returned ' + Name;
end;

end.
