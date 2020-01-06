unit NtUtils.Exceptions;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, System.SysUtils, System.TypInfo,
  DelphiUtils.Strings;

const
  BUFFER_LIMIT = 1024 * 1024 * 256; // 256 MB

type
  TLastCallType = (lcOtherCall, lcOpenCall, lcQuerySetCall);

  TExpectedAccess = record
    AccessMask: TAccessMask;
    AccessMaskType: PAccessMaskType;
  end;

  TLastCallInfo = record
    ExpectedPrivilege: TSeWellKnownPrivilege;
    ExpectedAccess: array of TExpectedAccess;
    procedure Expects(Mask: TAccessMask; MaskType: PAccessMaskType);
  case CallType: TLastCallType of
    lcOpenCall:
      (AccessMask: TAccessMask; AccessMaskType: PAccessMaskType);
    lcQuerySetCall:
      (InfoClass: Cardinal; InfoClassType: PTypeInfo);
  end;

  /// <summary>
  ///  An enhanced NTSTATUS that stores the location of the failure.
  /// </summary>
  TNtxStatus = record
  private
    FLocation: String;
    function GetWinError: Cardinal;
    procedure SetWinError(Value: Cardinal); inline;
    procedure FromLastWin32(RetValue: Boolean);
    procedure SetLocation(Value: String); inline;
    procedure SetHResult(const Value: HRESULT); inline;
  public
    Status: NTSTATUS;
    LastCall: TLastCallInfo;
    function IsSuccess: Boolean; inline;
    property WinError: Cardinal read GetWinError write SetWinError;
    property HResult: HRESULT write SetHResult;
    property Win32Result: Boolean write FromLastWin32;
    procedure RaiseOnError; inline;
    procedure ReportOnError;
  public
    property Location: String read FLocation write SetLocation;
    function Matches(Status: NTSTATUS; Location: String): Boolean; inline;
    function ToString: String;
    function MessageHint: String;
  end;

  ENtError = class(EOSError)
  public
    ErrorLocation: string;
    LastCall: TLastCallInfo;
    function Matches(Location: String; Code: Cardinal): Boolean;
    class procedure Report(Status: Cardinal; Location: String);
    function ToWinErrorCode: Cardinal;
    function ToNtxStarus: TNtxStatus;

    constructor Create(Status: NTSTATUS; Location: String); reintroduce;
    constructor CreateNtx(const Status: TNtxStatus);
    constructor CreateWin32(Win32Error: Cardinal; Location: String;
      Dummy: Integer = 0);
    constructor CreateLastWin32(Location: String);
  end;

  TNtxStatusWithValue<TValue> = record
    Value: TValue;
    Status: TNtxStatus;
    function GetValueOrRaise: TValue;
  end;

// RtlGetLastNtStatus with extra checks to ensure the result is correct
function RtlxGetLastNtStatus: NTSTATUS;

{ Runtime error-checking procedures that may raise exceptions}
procedure WinCheck(RetVal: LongBool; Where: String);
procedure NtxCheck(Status: NTSTATUS; Where: String);
procedure NtxAssert(Status: NTSTATUS; Where: String);

{ Buffer checking functions that do not raise exceptions}
function WinTryCheckBuffer(BufferSize: Cardinal): Boolean;
function NtxTryCheckBuffer(var Status: NTSTATUS; BufferSize: Cardinal): Boolean;

function NtxExpandStringBuffer(var Status: TNtxStatus;
  var Str: UNICODE_STRING; Required: Cardinal = 0): Boolean;

function NtxExpandBuffer(var Status: TNtxStatus; var BufferSize: Cardinal;
  Required: Cardinal; AddExtra: Boolean = False) : Boolean;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus, Winapi.WinBase, Winapi.WinError,
  NtUtils.ErrorMsg;

{ TLastCallInfo }

procedure TLastCallInfo.Expects(Mask: TAccessMask; MaskType: PAccessMaskType);
begin
  // Add new access mask
  SetLength(ExpectedAccess, Length(ExpectedAccess) + 1);
  ExpectedAccess[High(ExpectedAccess)].AccessMask := Mask;
  ExpectedAccess[High(ExpectedAccess)].AccessMaskType := MaskType;
end;

{ TNtxStatus }

procedure TNtxStatus.FromLastWin32(RetValue: Boolean);
begin
  if RetValue then
    Status := STATUS_SUCCESS
  else
  begin
    Status := RtlxGetLastNtStatus;

    // Make sure that the code is not successful
    if IsSuccess then
      Status := STATUS_UNSUCCESSFUL;
  end;
end;

function TNtxStatus.GetWinError: Cardinal;
begin
  if NT_NTWIN32(Status) then
    Result := WIN32_FROM_NTSTATUS(Status)
  else
    Result := RtlNtStatusToDosErrorNoTeb(Status);
end;

function TNtxStatus.IsSuccess: Boolean;
begin
  Result := Integer(Status) >= 0; // inlined NT_SUCCESS from Ntapi.ntdef
end;

function TNtxStatus.Matches(Status: NTSTATUS; Location: String): Boolean;
begin
  Result := (Self.Status = Status) and (Self.Location = Location);
end;

function TNtxStatus.MessageHint: String;
begin
  Result := NtxFormatErrorMessage(Status);
end;

procedure TNtxStatus.RaiseOnError;
begin
  if not IsSuccess then
    raise ENtError.CreateNtx(Self);
end;

procedure TNtxStatus.ReportOnError;
begin
  if not IsSuccess then
    ENtError.Report(Status, Location);
end;

procedure TNtxStatus.SetHResult(const Value: HRESULT);
begin
  // Inlined Winapi.WinError.Succeeded
  if Value and $80000000 = 0 then
    Status := Cardinal(Value) and $7FFFFFFF
  else
    Status := Cardinal(SEVERITY_ERROR shl NT_SEVERITY_SHIFT) or Cardinal(Value);
end;

procedure TNtxStatus.SetLocation(Value: String);
begin
  FLocation := Value;
  LastCall.ExpectedAccess := nil; // Free the dynamic array
  FillChar(LastCall, SizeOf(LastCall), 0); // Zero all other fields
end;

procedure TNtxStatus.SetWinError(Value: Cardinal);
begin
  Status := NTSTATUS_FROM_WIN32(Value);
end;

function TNtxStatus.ToString: String;
begin
  Result := Location + ': ' + NtxStatusToString(Status);
end;

{ ENtError }

constructor ENtError.Create(Status: NTSTATUS; Location: String);
begin
  Message := Location + ' returned ' + NtxStatusToString(Status);
  ErrorLocation := Location;
  ErrorCode := Status;
end;

constructor ENtError.CreateLastWin32(Location: String);
begin
  Create(RtlxGetLastNtStatus, Location);
end;

constructor ENtError.CreateNtx(const Status: TNtxStatus);
begin
  Create(Status.Status, Status.Location);
  LastCall := Status.LastCall;
end;

constructor ENtError.CreateWin32(Win32Error: Cardinal; Location: String;
  Dummy: Integer = 0);
begin
  Create(NTSTATUS_FROM_WIN32(Win32Error), Location);
end;

function ENtError.Matches(Location: String; Code: Cardinal): Boolean;
begin
  Result := (ErrorCode = Code) and (ErrorLocation = Location);
end;

class procedure ENtError.Report(Status: Cardinal; Location: String);
begin
  OutputDebugStringW(PWideChar(Location + ': ' + NtxStatusToString(Status)));
end;

function ENtError.ToNtxStarus: TNtxStatus;
begin
  Result.Location := ErrorLocation;
  Result.Status := ErrorCode;
  Result.LastCall := LastCall;
end;

function ENtError.ToWinErrorCode: Cardinal;
begin
  if NT_NTWIN32(ErrorCode) then
    Result := WIN32_FROM_NTSTATUS(ErrorCode)
  else
    Result := RtlNtStatusToDosErrorNoTeb(ErrorCode);
end;

{ TNtxStatusWithValue<TValue> }

function TNtxStatusWithValue<TValue>.GetValueOrRaise: TValue;
begin
  Status.RaiseOnError;
  Result := Value;
end;

{ Functions }

procedure WinCheck(RetVal: LongBool; Where: String);
begin
  if not RetVal then
    raise ENtError.CreateLastWin32(Where);
end;

//  Note:
// [Error]   STATUS_INFO_LENGTH_MISMATCH => ERROR_BAD_LENGTH
// [Error]   STATUS_BUFFER_TOO_SMALL     => ERROR_INSUFFICIENT_BUFFER
// [Warning] STATUS_BUFFER_OVERFLOW      => ERROR_MORE_DATA

function WinTryCheckBuffer(BufferSize: Cardinal): Boolean;
begin
  Result := (GetLastError = ERROR_INSUFFICIENT_BUFFER) and (BufferSize > 0) and
    (BufferSize <= BUFFER_LIMIT);

  if not Result and (BufferSize > BUFFER_LIMIT) then
    RtlSetLastWin32ErrorAndNtStatusFromNtStatus(STATUS_IMPLEMENTATION_LIMIT);
end;

procedure NtxCheck(Status: NTSTATUS; Where: String);
begin
  if not NT_SUCCESS(Status) then
    raise ENtError.Create(Status, Where);
end;

procedure NtxAssert(Status: NTSTATUS; Where: String);
begin
  // The same as NtxCheck but for function that are not supposed to fail due
  // to the program logic.
  if not NT_SUCCESS(Status) then
    raise ENtError.Create(Status, Where);
end;

function NtxTryCheckBuffer(var Status: NTSTATUS; BufferSize: Cardinal): Boolean;
begin
  Result := (Status = STATUS_INFO_LENGTH_MISMATCH) or
    (Status = STATUS_BUFFER_TOO_SMALL);

  if BufferSize > BUFFER_LIMIT then
  begin
    Result := False;
    Status := STATUS_IMPLEMENTATION_LIMIT;
  end;
end;

function NtxExpandStringBuffer(var Status: TNtxStatus;
  var Str: UNICODE_STRING; Required: Cardinal): Boolean;
begin
  // True means continue; False means break from the loop
  Result := False;

  case Status.Status of
    STATUS_INFO_LENGTH_MISMATCH, STATUS_BUFFER_TOO_SMALL,
    STATUS_BUFFER_OVERFLOW:
    begin
       // There are two types of UNICODE_STRING querying functions.
       // Both read buffer size from Str.MaximumLength, although some
       // return the required buffer size in a special parameter,
       // and some write it to Str.Length.

      if Required = 0 then
      begin
        // No special parameter

        if Str.Length <= Str.MaximumLength then
          Exit(False); // Always grow

        // Include terminating #0
        Str.MaximumLength := Str.Length + SizeOf(WideChar);
      end
      else
      begin
        if (Required <= Str.MaximumLength) or (Required > High(Word)) then
          Exit(False); // Always grow, but without owerflows

        Str.MaximumLength := Word(Required)
      end;
      Result := True;
    end;
  end;
end;

function NtxExpandBuffer(var Status: TNtxStatus; var BufferSize: Cardinal;
  Required: Cardinal; AddExtra: Boolean) : Boolean;
begin
  // True means continue; False means break from the loop
  Result := False;

  case Status.Status of
    STATUS_INFO_LENGTH_MISMATCH, STATUS_BUFFER_TOO_SMALL,
    STATUS_BUFFER_OVERFLOW:
    begin
      // The buffer should always grow with these error codes
      if Required <= BufferSize then
        Exit(False);

      BufferSize := Required;

      if AddExtra then
        Inc(BufferSize, BufferSize shr 3); // +12% capacity

      // Check for the limitation
      if BufferSize > BUFFER_LIMIT then
      begin
        Status.Location := 'NtxExpandBuffer';
        Status.Status := STATUS_IMPLEMENTATION_LIMIT;
        Exit(False);
      end;

      Result := True;
    end;
  end;
end;

function RtlxGetLastNtStatus: NTSTATUS;
begin
  // If the last Win32 error was set using RtlNtStatusToDosError call followed
  // by RtlSetLastWin32Error call (aka SetLastError), the LastStatusValue in TEB
  // should contain the correct NTSTATUS value. The way to check whether it is
  // correct is to convert it to Win32 error and compare with LastErrorValue
  // from TEB. If, for some reason, they don't match, return a fake NTSTATUS
  // with a Win32 facility.

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
    Result := NTSTATUS_FROM_WIN32(RtlGetLastWin32Error);
  end;
end;

end.
