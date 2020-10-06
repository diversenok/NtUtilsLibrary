unit NtUiLib.Exceptions.Messages;

interface

uses
  Winapi.WinNt, Ntapi.ntdef;

// Converts common error codes to strings, for example:
//      1314 => "ERROR_PRIVILEGE_NOT_HELD"
// $C00000BB =>     "STATUS_NOT_SUPPORTED"
// Returns empty string if the name is not found.

function NtxpWin32ErrorToString(Code: TWin32Error): String;
function NtxpStatusToString(Status: NTSTATUS): String;

// The same as above, but on unknown errors returns their decimal/hexadecimal
// representations.
function NtxWin32ErrorToString(Code: TWin32Error): String;
function NtxStatusToString(Status: NTSTATUS): String;

// Converts common error codes to their short descriptions, for example:
//      1314 => "Privilege not held"
// $C00000BB =>      "Not supported"
// Returns empty string if the name is not found.
function NtxWin32ErrorDescription(Code: TWin32Error): String;
function NtxStatusDescription(Status: NTSTATUS): String;

// Retrieves a full description of a native error.
function NtxFormatErrorMessage(Status: NTSTATUS): String;

implementation

uses
  Ntapi.ntldr, Winapi.WinBase, System.SysUtils, DelphiUiLib.Strings,
  Ntapi.ntstatus, Winapi.WinError;

{$R 'NtUiLib.Exceptions.Messages.res' 'NtUiLib.Exceptions.Messages.rc'}

const
  {
    The resource file contains the names of some common Win32 Errors and
    NTSTATUS values. To fit into the format of the .rc file each category
    (i.e. Win32, NT Success, NT Information, NT Warning, and NT Error) was
    shifted, so it starts from the values listed above. Each group of values
    can contain the maximum count of RC_STATUS_EACH_MAX - 1 items to make sure
    they don't overlap.
  }
  RC_STATUS_SIFT_WIN32 = $8000;
  RC_STATUS_SIFT_NT_SUCCESS = $9000;    // Success severity
  RC_STATUS_SIFT_NT_INFO = $A000;       // Informational severity
  RC_STATUS_SIFT_NT_WARNING = $B000;    // Warning severity
  RC_STATUS_SIFT_NT_ERROR = $C000;      // Error severity
  RC_STATUS_SIFT_NT_FACILITIES = $D000; // Error severity with non-zero facility
  RC_STATUS_EACH_MAX = $1000;

  RC_FACILITY_SHIFT_RPC_RUNTIME = $0;   // FACILITY_RPC_RUNTIME
  RC_FACILITY_SHIFT_RPC_STUBS = $100;   // FACILITY_RPC_STUBS
  RC_FACILITY_SHIFT_TRANSACTION = $200; // FACILITY_TRANSACTION
  RC_FACILITY_EACH_MAX = $100;

function NtxpWin32ErrorToString(Code: TWin32Error): String;
var
  Buf: PWideChar;
begin
  // Make sure the error is within the range
  if Code >= RC_STATUS_EACH_MAX then
    Exit('');

  // Shift it to obtain the resource index
  Code := Code or RC_STATUS_SIFT_WIN32;

  // Extract the string representation
  SetString(Result, Buf, LoadStringW(HInstance, Code, Buf));
end;

function NtxpStatusToString(Status: NTSTATUS): String;
var
  ResIndex: Cardinal;
  Buf: PWideChar;
begin
  Result := '';

  // Clear bits that indicate severity and facility
  ResIndex := Status and $3000FFFF;

  if NT_FACILITY(Status) = FACILITY_NONE then
  begin
    // Make sure the substatus is within the range
    if ResIndex >= RC_STATUS_EACH_MAX then
      Exit;

    // Shift it to obtain a resource index
    case NT_SEVERITY(Status) of
      SEVERITY_SUCCESS:       ResIndex := ResIndex or RC_STATUS_SIFT_NT_SUCCESS;
      SEVERITY_INFORMATIONAL: ResIndex := ResIndex or RC_STATUS_SIFT_NT_INFO;
      SEVERITY_WARNING:       ResIndex := ResIndex or RC_STATUS_SIFT_NT_WARNING;
      SEVERITY_ERROR:         ResIndex := ResIndex or RC_STATUS_SIFT_NT_ERROR;
    end;
  end
  else if NT_SEVERITY(Status) = SEVERITY_ERROR then
  begin
    // Make sure the substatus is within the range
    if ResIndex >= RC_FACILITY_EACH_MAX then
      Exit;

    // Shift resource index to facilities section
    ResIndex := ResIndex or RC_STATUS_SIFT_NT_FACILITIES;

    // Shift resource index to each facility
    case NT_FACILITY(Status) of
      FACILITY_RPC_RUNTIME:
        ResIndex := ResIndex or RC_FACILITY_SHIFT_RPC_RUNTIME;

      FACILITY_RPC_STUBS:
        ResIndex := ResIndex or RC_FACILITY_SHIFT_RPC_STUBS;

      FACILITY_TRANSACTION:
        ResIndex := ResIndex or RC_FACILITY_SHIFT_TRANSACTION;
    else
      Exit;
    end;
  end
  else
    Exit;

  // Extract the string representation
  SetString(Result, Buf, LoadStringW(HInstance, ResIndex, Buf));
end;

function NtxWin32ErrorToString(Code: TWin32Error): String;
begin
  Result := NtxpWin32ErrorToString(Code);
  if Result = '' then
    Result := IntToStr(Code);
end;

function NtxStatusToString(Status: NTSTATUS): String;
begin
  // Check if it's a fake status based on a Win32 error.
  // In this case use "ERROR_SOMETHING_WENT_WRONG" messages.

  if NT_NTWIN32(Status) then
    Result := NtxpWin32ErrorToString(WIN32_FROM_NTSTATUS(Status))
  else
    Result := NtxpStatusToString(Status);

  if Result = '' then
    Result := IntToHexEx(Status, 8, False);
end;

function NtxWin32ErrorDescription(Code: TWin32Error): String;
begin
  // We query the code name which looks like "ERROR_SOMETHING_WENT_WRONG"
  // and prettify it so it appears like "Something went wrong"

  Result := NtxpWin32ErrorToString(Code);

  if Result = '' then
    Exit;

  Result := PrettifySnakeCase(Result, 'ERROR_');
end;

function NtxStatusDescription(Status: NTSTATUS): String;
begin
  if NT_NTWIN32(Status) then
  begin
    // This status was converted from a Win32 error.
    Result := NtxWin32ErrorDescription(WIN32_FROM_NTSTATUS(Status));
  end
  else
  begin
    // We query the status name which looks like "STATUS_SOMETHING_WENT_WRONG"
    // and prettify it so it appears like "Something went wrong"

    Result := NtxpStatusToString(Status);

    if Result = '' then
      Exit;

    Result := PrettifySnakeCase(Result, 'STATUS_');
  end;
end;

function NtxFormatErrorMessage(Status: NTSTATUS): String;
var
  StartFrom: Integer;
begin
  if NT_NTWIN32(Status) then
    // This status was converted from a Win32 errors.
    Result := SysErrorMessage(WIN32_FROM_NTSTATUS(Status))
  else if Status and FACILITY_NT_BIT <> 0 then
    // This status represents an HRESULT
    Result := SysErrorMessage(Status and not FACILITY_NT_BIT)
  else
  begin
    // Get error message from ntdll
    Result := SysErrorMessage(Status, hNtdll);

    // Fix those messages which are formatted like:
    //   {Asdf}
    //   Asdf asdf asdf...
    if (Length(Result) > 0) and (Result[Low(Result)] = '{') then
    begin
      StartFrom := Pos('}'#$D#$A, Result);
      if StartFrom >= Low(Result) then
        Delete(Result, Low(Result), StartFrom + 2);
    end;
  end;

  if Result = '' then
    Result := '<No description available>';
end;

end.
