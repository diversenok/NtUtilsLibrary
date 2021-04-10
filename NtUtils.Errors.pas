unit NtUtils.Errors;

{
  This module provides support for manipulating and converting error codes
  between NTSTATUS, HRESULT, and Win32 Error formats.
}

interface

uses
  Winapi.WinNt, Ntapi.ntdef;

// RtlGetLastNtStatus with extra checks to ensure the result is correct
function RtlxGetLastNtStatus(EnsureUnsuccessful: Boolean = False): NTSTATUS;

type
  TNtStatusHelper = record helper for NTSTATUS
    // Checks
    function IsSuccess: Boolean;
    function IsWin32Error: Boolean;
    function IsHResult: Boolean;

    // Conversion
    function ToHResult: HResult;
    function ToWin32Error: TWin32Error;
    function Canonicalize: NTSTATUS;
  end;

  THResultHelper = record helper for HResult
    // Checks
    function IsSuccess: Boolean;
    function IsWin32Error: Boolean;
    function IsNtStatus: Boolean;

    // Conversion
    function ToNtStatus: NTSTATUS;
    function Canonicalize: HResult;
  end;

  TWin32ErrorHelper = record helper for TWin32Error
    // Conversions
    function ToHResult: HResult;
    function ToNtStatus: NTSTATUS;
  end;

implementation

uses
  Ntapi.ntrtl, Winapi.WinError, Ntapi.ntstatus;

const
  // For NTSTATUS, indicates that the underlying error comes from an HRESULT;
  // For HRESULT, indicates that the underlying error comes from an NTSTATUS.
  FACILITY_SWAP_BIT = Winapi.WinError.FACILITY_NT_BIT;

function RtlxGetLastNtStatus;
begin
  // If the last Win32 error was set using RtlNtStatusToDosError followed by
  // RtlSetLastWin32Error (aka SetLastError), the LastStatusValue in TEB should
  // contain the correct NTSTATUS value. The way to check the correctness is to
  // convert the status to a Win32 error and compare with LastErrorValue from
  // TEB. If, for some reason, they don't match, return a fake NTSTATUS with a
  // Win32 facility.

  if RtlNtStatusToDosErrorNoTeb(RtlGetLastNtStatus) = RtlGetLastWin32Error then
    Result := RtlGetLastNtStatus
  else
  case RtlGetLastWin32Error of

    // Explicitly convert buffer-related errors
    ERROR_INSUFFICIENT_BUFFER: Result := STATUS_BUFFER_TOO_SMALL;
    ERROR_MORE_DATA:           Result := STATUS_BUFFER_OVERFLOW;
    ERROR_BAD_LENGTH:          Result := STATUS_INFO_LENGTH_MISMATCH;

    // After converting, ERROR_SUCCESS becomes unsuccessful, fix it
    ERROR_SUCCESS:             Result := STATUS_SUCCESS;

    // Common errors which we might want to compare
    ERROR_ACCESS_DENIED:       Result := STATUS_ACCESS_DENIED;
    ERROR_PRIVILEGE_NOT_HELD:  Result := STATUS_PRIVILEGE_NOT_HELD;
  else
    Result := RtlGetLastWin32Error.ToNtStatus;
  end;

  // Sometimes WinApi functions can fail with ERROR_SUCCESS. If necessary,
  // make sure that failures always result in an unsuccessful status.
  if EnsureUnsuccessful and Result.IsSuccess then
    Result := RtlGetLastWin32Error.ToNtStatus;
end;

{ TNtStatusHelper }

function TNtStatusHelper.Canonicalize;
begin
  // The only ambiguity we have is with Win32 Errors. They can appear within
  // either an HRESULT or an NTSTATUS. We call NTSTATUS being canonical when
  // Win32 Errors appear in it directly (without the facility swap bit).
  // NTSTATUS_FROM_WIN32 yields this result (in form of 0xC007xxxx); inline it.

  if IsWin32Error then
    Result := WIN32_NTSTATUS_BITS or (Self and WIN32_CODE_MASK)
  else
    Result := Self;
end;

function TNtStatusHelper.IsHResult;
begin
  // Just like HRESULTs can store NTSTATUSes using the NT Facility bit, we make
  // NTSTATUSes store HRESULTs using the same bit. We call it a Swap bit.

  Result := Self and FACILITY_SWAP_BIT <> 0;
end;

function TNtStatusHelper.IsSuccess;
begin
  // Inline NT_SUCCESS / Succeeded

  Result := Integer(Self) >= 0;
end;

function TNtStatusHelper.IsWin32Error;
begin
  // Regardles of whether the value is a native NTSTATUS or a converted HRESULT,
  // the Win32 Facility indicates that the error originally comes from Win32.

  Result := Self and FACILITY_MASK = FACILITY_WIN32_BITS;
end;

function TNtStatusHelper.ToHResult;
begin
  // If the status has the Win32 Facility, then it was derived from a Win32
  // error. The HRESULT should be 0x8007xxxx in this case.

  // Statuses with a FACILITY_SWAP_BIT were derived from HRESULTs.
  // To get the original HRESULT back, remove this bit.

  // Statuses without the FACILITY_SWAP_BIT are native NTSTATUS codes.
  // Setting this bit (which, in case of HRESULTs, is called the NT Facility
  // bit) yeilds a valid HRESULT derived from an NTSTATUS.

  if IsWin32Error then
    Cardinal(Result) := WIN32_HRESULT_BITS or (Self and WIN32_CODE_MASK)
  else
    Cardinal(Result) := Self xor FACILITY_SWAP_BIT;
end;

function TNtStatusHelper.ToWin32Error;
begin
  // If the status comes from a Win32 error, reconstruct it
  if IsWin32Error then
    Result := Self and WIN32_CODE_MASK

  // If the status is a native NTSTATUS, ask ntdll to map it to Win32
  else if not IsHResult then
    Result := RtlNtStatusToDosErrorNoTeb(Self)

  // Is it a successful code ntdll does not know about?
  else if IsSuccess then
    Result := ERROR_SUCCESS

  // The original code comes from an HRESULT; even though it's not a Win32
  // error, they are reasonably compatible, so we can use them interchangeably
  // when formatting error messages.
  else
    Result := TWin32Error(Self xor FACILITY_SWAP_BIT);
end;

{ THResultHelper }

function THResultHelper.Canonicalize: HResult;
begin
  // The only ambiguity we have is with Win32 Errors. They can appear within
  // either an HRESULT or an NTSTATUS. We call HRESULT being canonical when
  // Win32 Errors appear in it directly (without the NT Facility bit) i.e,
  // in form of 0x8007xxxx.

  if IsWin32Error then
    Cardinal(Result) := WIN32_HRESULT_BITS or
      (Cardinal(Self) and WIN32_CODE_MASK)
  else
    Result := Self;
end;

function THResultHelper.IsNtStatus: Boolean;
begin
  // HRESULTs can store NTSTATUSes using the NT Facility bit

  Result := Self and FACILITY_NT_BIT <> 0;
end;

function THResultHelper.IsSuccess: Boolean;
begin
  // Inline Succeeded / NT_SUCCESS

  Result := Integer(Self) >= 0;
end;

function THResultHelper.IsWin32Error: Boolean;
begin
  // Regardles of whether the value is a native HRESULT or a converted NTSTATUS,
  // the Win32 Facility indicates that the error originally comes from Win32.

  Result := Self and FACILITY_MASK = FACILITY_WIN32_BITS;
end;

function THResultHelper.ToNtStatus: NTSTATUS;
begin
  // If the value has the Win32 Facility, then it was derived from a Win32
  // error. A canonical NTSTATUS should be 0xC007xxxx in this case.

  // Values with a FACILITY_NT_BIT were derived from NTSTATUSes.
  // To get the original NTSTATUS back, remove this bit.

  // Values without the FACILITY_NT_BIT are native HRESULTs codes.
  // Setting this bit (which, in case of NTSTATUSes, we cal the Facility Swap
  // bit) yeilds a valid NTSATUS derived from an HRESULT.

  if IsWin32Error then
    Cardinal(Result) := WIN32_NTSTATUS_BITS or
      (Cardinal(Self) and WIN32_CODE_MASK)
  else
    Cardinal(Result) := Cardinal(Self) xor FACILITY_NT_BIT;
end;

{ TWin32ErrorHelper }

function TWin32ErrorHelper.ToHResult;
begin
  // Win32 Errors are supposed to be positive 16-bit integers. A negative value
  // indicates that someone used an HRESULT in place of a Win32 Error. But since
  // they are reasonably compatible (when formatting error messages), it is Ok.

  // For regular Win32 Errors, prepare a canonical HRESULT (0x8007xxxx).

  if Integer(Self) < 0 then
    Result := HResult(Self)
  else
    Result := HResult(WIN32_HRESULT_BITS or (Self and WIN32_CODE_MASK));
end;

function TWin32ErrorHelper.ToNtStatus: NTSTATUS;
begin
  // Negative values indicate usage of HRESULTs in place of true Win32 Erorors.
  // Toggle the Facility Swap bit to convert one to NTSTATUS.

  // Otherwise, construct a canonical NTSTATUS (0xC007xxxx)

  if Integer(Self) < 0 then
    Result := Self xor FACILITY_SWAP_BIT
  else
    Result := WIN32_NTSTATUS_BITS or (Self and WIN32_CODE_MASK);
end;

end.
