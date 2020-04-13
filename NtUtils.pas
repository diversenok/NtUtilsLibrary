unit NtUtils;

interface

uses
  Winapi.WinNt, Ntapi.ntdef, Ntapi.ntseapi, DelphiUtils.AutoObject;

const
  BUFFER_LIMIT = 1024 * 1024 * 256; // 256 MB

type
  TMemory = DelphiUtils.AutoObject.TMemory;
  IMemory = DelphiUtils.AutoObject.IMemory;
  TAutoMemory = DelphiUtils.AutoObject.TAutoMemory;
  IHandle = DelphiUtils.AutoObject.IHandle;

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
      (InfoClass: Cardinal; InfoClassType: Pointer);
  end;

  /// <summary>
  ///  An enhanced NTSTATUS that stores the location of the failure.
  /// </summary>
  TNtxStatus = record
  private
    FLocation: String;
    function GetWinError: TWin32Error;
    procedure SetWinError(Value: TWin32Error); inline;
    procedure FromLastWin32(RetValue: Boolean);
    procedure SetLocation(Value: String); inline;
    procedure SetHResult(const Value: HRESULT);
  public
    Status: NTSTATUS;
    LastCall: TLastCallInfo;
    function IsSuccess: Boolean; inline;
    property WinError: TWin32Error read GetWinError write SetWinError;
    property HResult: HRESULT write SetHResult;
    property Win32Result: Boolean write FromLastWin32;
    property Location: String read FLocation write SetLocation;
    function Matches(Status: NTSTATUS; Location: String): Boolean; inline;
  end;

  TBufferGrowthMethod = function (Buffer: Pointer; Size, Required: Cardinal):
    Cardinal;

// RtlGetLastNtStatus with extra checks to ensure the result is correct
function RtlxGetLastNtStatus: NTSTATUS;

procedure NtxAssert(Status: NTSTATUS; Location: String); overload;
procedure NtxAssert(const Status: TNtxStatus); overload;

function WinTryCheckBuffer(BufferSize: Cardinal): Boolean;
function NtxTryCheckBuffer(var Status: NTSTATUS; BufferSize: Cardinal): Boolean;

function NtxExpandStringBuffer(var Status: TNtxStatus;
  var Str: UNICODE_STRING; Required: Cardinal = 0): Boolean;

function NtxExpandBuffer(var Status: TNtxStatus; var BufferSize: Cardinal;
  Required: Cardinal; AddExtra: Boolean = False) : Boolean;

implementation

uses
  Ntapi.ntrtl, Ntapi.ntstatus, Winapi.WinError;

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

function TNtxStatus.GetWinError: TWin32Error;
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

procedure TNtxStatus.SetWinError(Value: TWin32Error);
begin
  Status := NTSTATUS_FROM_WIN32(Value);
end;

{ Functions }

procedure NtxAssert(Status: NTSTATUS; Location: String);
begin
  Assert(NT_SUCCESS(Status), Location);
end;

procedure NtxAssert(const Status: TNtxStatus);
begin
  Assert(Status.IsSuccess, Status.Location);
end;

function WinTryCheckBuffer(BufferSize: Cardinal): Boolean;
begin
  Result := (GetLastError = ERROR_INSUFFICIENT_BUFFER) and (BufferSize > 0) and
    (BufferSize <= BUFFER_LIMIT);

  if not Result and (BufferSize > BUFFER_LIMIT) then
    RtlSetLastWin32ErrorAndNtStatusFromNtStatus(STATUS_IMPLEMENTATION_LIMIT);
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
