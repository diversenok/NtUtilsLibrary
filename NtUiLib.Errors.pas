unit NtUiLib.Errors;

{
  This module adds support for representing error codes as constant names,
  short summaries, and long descriptions.
}

interface

{$RESOURCE NtUiLib.Errors.res}

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
  Ntapi.WinNt, Ntapi.ntrtl, Ntapi.WinError, Ntapi.ntldr, NtUtils.Ldr,
  NtUtils.SysUtils, NtUtils.Errors, DelphiUiLib.Strings;

{$BOOLEVAL OFF}
{$IFOPT R+}{$DEFINE R+}{$ENDIF}
{$IFOPT Q+}{$DEFINE Q+}{$ENDIF}

function RemoveSummaryAndNewLines(const Source: String): String;
var
  StartIndex, EndIndex: Integer;
begin
  // Skip leading summary in curly brackets for messages that look like:
  //   {Summary}
  //   Message description.
  StartIndex := Low(Source);

  if (Length(Source) > 0) and (Source[Low(Source)] = '{') then
    StartIndex := Pos('}'#$D#$A, Source) + 3;

  // Remove trailing new lines
  EndIndex := High(Source);
  while (EndIndex >= Low(Source)) and (AnsiChar(Source[EndIndex]) in
    [#$D, #$A]) do
    Dec(EndIndex);

  Result := Copy(Source, StartIndex, EndIndex - StartIndex + 1);
end;

function RtlxNtStatusName;
begin
  // Use embedded resource to locate the constant name
  if RtlxFindMessage(Result, Pointer(@ImageBase),
    Status.Canonicalize).IsSuccess then
    Result := RemoveSummaryAndNewLines(Result)
  else
  begin
    // No name available. Prepare a numeric value.
    if Status.IsWin32Error then
      Result := RtlxUIntToStr(Status.ToWin32Error) + ' [Win32]'
    else if Status.IsHResult then
      Result := RtlxUIntToStr(Cardinal(Status.ToHResult), 16) + ' [HRESULT]'
    else
      Result :=  RtlxUIntToStr(Status, 16) + ' [NTSTATUS]';
  end;
end;

function RtlxNtStatusSummary;
const
  KnownPrefixes: array [0 .. 95] of String = ('STATUS_VOLMGR_',
    'STATUS_XMLLITE_', 'STATUS_LOG_', 'STATUS_DS_', 'STATUS_CTX_',
    'STATUS_SXS_', 'STATUS_VHD_', 'STATUS_CLOUD_FILE_', 'STATUS_SMARTCARD_',
    'STATUS_APPEXEC_', 'STATUS_SYSTEM_INTEGRITY_', 'STATUS_WX86_',
    'STATUS_WMI_', 'STATUS_DIF_', 'STATUS_FT_', 'STATUS_VRF_', 'STATUS_PNP_',
    'STATUS_THREADPOOL_', 'STATUS_VIRTDISK_', 'STATUS_RXACT_', 'STATUS_KDC_',
    'STATUS_CTLOG_', 'STATUS_CS_ENCRYPTION_', 'STATUS_TRANSACTIONMANAGER_',
    'STATUS_RWRAW_ENCRYPTED_', 'STATUS_BCD_', 'STATUS_', 'ERROR_VOLMGR_',
    'ERROR_SXS_XML_E_', 'ERROR_SXS_', 'ERROR_LOG_', 'ERROR_CTX_',
    'ERROR_INSTALL_', 'ERROR_EVT_', 'ERROR_VHD_', 'ERROR_CLOUD_FILE_',
    'ERROR_MRM_', 'ERROR_STATE_', 'ERROR_WMI_', 'ERROR_DBG_', 'ERROR_APPEXEC_',
    'ERROR_SYSTEM_INTEGRITY_', 'ERROR_PRI_MERGE_', 'ERROR_CAPAUTHZ_',
    'ERROR_FT_', 'ERROR_VIRTDISK_', 'ERROR_RXACT_', 'ERROR_CTLOG_',
    'ERROR_CS_ENCRYPTION_', 'ERROR_RWRAW_ENCRYPTED_', 'ERROR_WOF_',
    'ERROR_EDP_', 'ERROR_BCD_', 'ERROR_', 'CO_E_', 'RPC_NT_', 'RPC_S_',
    'SEC_E_', 'RPC_E_', 'STG_E_', 'SCHED_E_', 'E_', 'APPX_E_', 'RPC_X_',
    'OLE_E_', 'DISP_E_', 'MK_E_', 'EVENT_E_', 'DBG_', 'SEC_I_', 'RO_E_',
    'WER_S_', 'SCHED_S_', 'CS_E_', 'CONTEXT_E_', 'WER_E_', 'STG_S_', 'REGDB_E_',
    'APPMODEL_ERROR_', 'DWM_E_', 'MK_S_', 'CLIPBRD_E_', 'STORE_ERROR_', 'S_',
    'EPT_S_', 'EPT_NT_', 'OR_', 'OLEOBJ_S_', 'OLE_S_', 'MEM_E_', 'CLASS_E_',
    'OLEOBJ_E_', 'EVENT_S_', 'DWM_S_', 'CO_S_', 'CAT_E_');
var
  Prefix: String;
begin
  // Use embedded resource to locate the constant name
  if not RtlxFindMessage(Result, Pointer(@ImageBase),
    Status.Canonicalize).IsSuccess then
    Exit('System Error');

  Result := RemoveSummaryAndNewLines(Result);

  // Skip known constant prefixes
  for Prefix in KnownPrefixes do
    if StringStartsWith(Result, Prefix) then
    begin
      Result := Copy(Result, Succ(Length(Prefix)), Length(Result));
      Break;
    end;

  // Convert names from looking like "ACCESS_DENIED" to "Access Denied"
  Result := PrettifySnakeCase(Result);
end;

function RtlxNtStatusMessage;
var
  hKernel32: PDllBase;
begin
  // Messages for Win32 errors and HRESULT codes are located in kernel32
  if Status.IsWin32Error or Status.IsHResult then
  begin
    if not LdrxGetDllHandle(kernel32, hKernel32).IsSuccess or
      not RtlxFindMessage(Result, hKernel32, Status.ToWin32Error).IsSuccess then
      Result := '';
  end

  // For native NTSTATUS vaules, use ntdll
  else if not RtlxFindMessage(Result, hNtdll.DllBase, Status).IsSuccess then
    Result := '';

  Result := RemoveSummaryAndNewLines(Result);

  if Result = '' then
    Result := '<No description available>';
end;

procedure RtlxRaiseException;
var
  ExceptionRecord: TExceptionRecord;
begin
  ExceptionRecord := Default(TExceptionRecord);
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
