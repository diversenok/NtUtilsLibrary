unit NtUiLib.Exceptions;

interface

uses
  Ntapi.ntdef, NtUtils.Exceptions, System.SysUtils;

type
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

  TNtxStatusHelper = record helper for TNtxStatus
    procedure RaiseOnError;
    procedure ReportOnError;
    function ToString: String;
    function MessageHint: String;
  end;

{ Runtime error-checking procedures that may raise exceptions}
procedure WinCheck(RetVal: LongBool; Where: String);
procedure NtxCheck(Status: NTSTATUS; Where: String);

implementation

uses
  Winapi.WinNt, ntapi.ntrtl, ntapi.ntstatus, Winapi.WinError, Winapi.WinBase,
  NtUiLib.Exceptions.Messages;

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

{ TNtxStatusHelper }

function TNtxStatusHelper.MessageHint: String;
begin
  Result := NtxFormatErrorMessage(Status);
end;

procedure TNtxStatusHelper.RaiseOnError;
begin
  if not IsSuccess then
    raise ENtError.CreateNtx(Self);
end;

procedure TNtxStatusHelper.ReportOnError;
begin
  if not IsSuccess then
    ENtError.Report(Status, Location);
end;

function TNtxStatusHelper.ToString: String;
begin
  Result := Location + ': ' + NtxStatusToString(Status);
end;

{ Functions }

procedure WinCheck(RetVal: LongBool; Where: String);
begin
  if not RetVal then
    raise ENtError.CreateLastWin32(Where);
end;

procedure NtxCheck(Status: NTSTATUS; Where: String);
begin
  if not NT_SUCCESS(Status) then
    raise ENtError.Create(Status, Where);
end;

end.
